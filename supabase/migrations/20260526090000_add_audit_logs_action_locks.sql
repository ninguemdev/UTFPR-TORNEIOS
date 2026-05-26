-- Auditoria geral e bloqueios administrativos.
-- Esta migration adiciona:
-- - audit_logs: trilha generica para acoes sensiveis;
-- - action_locks: bloqueios administrativos por escopo;
-- - triggers de auditoria em modulos sensiveis;
-- - validacao de bloqueios em triggers/RPCs existentes.

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'action_lock_scope'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.action_lock_scope as enum (
      'global',
      'tournament',
      'registration',
      'team',
      'match',
      'ranking'
    );
  end if;
end
$$;

create table if not exists public.audit_logs (
  id uuid primary key default extensions.gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text not null,
  tournament_id uuid,
  before_data jsonb,
  after_data jsonb,
  reason text,
  ip_address inet,
  user_agent text,
  created_at timestamptz not null default now(),
  constraint audit_logs_action_not_blank check (length(btrim(action)) > 0),
  constraint audit_logs_entity_type_not_blank check (length(btrim(entity_type)) > 0),
  constraint audit_logs_entity_id_not_blank check (length(btrim(entity_id)) > 0),
  constraint audit_logs_reason_not_blank check (
    reason is null
    or length(btrim(reason)) > 0
  )
);

comment on table public.audit_logs is
  'Trilha generica de auditoria para acoes administrativas sensiveis. Leitura restrita a admins por RLS.';
comment on column public.audit_logs.actor_id is
  'Usuario autenticado que disparou a acao, quando disponivel.';
comment on column public.audit_logs.tournament_id is
  'UUID do torneio relacionado. Nao usa FK para preservar logs mesmo apos exclusao do torneio.';
comment on column public.audit_logs.ip_address is
  'Reservado para captura futura via Edge Function/API server. Triggers SQL nao recebem IP confiavel do cliente.';
comment on column public.audit_logs.user_agent is
  'Reservado para captura futura via Edge Function/API server. Triggers SQL nao recebem user-agent confiavel do cliente.';

create index if not exists audit_logs_created_at_idx
  on public.audit_logs (created_at desc);

create index if not exists audit_logs_actor_created_at_idx
  on public.audit_logs (actor_id, created_at desc);

create index if not exists audit_logs_entity_idx
  on public.audit_logs (entity_type, entity_id);

create index if not exists audit_logs_tournament_created_at_idx
  on public.audit_logs (tournament_id, created_at desc);

create table if not exists public.action_locks (
  id uuid primary key default extensions.gen_random_uuid(),
  scope public.action_lock_scope not null,
  scope_id text,
  action text not null,
  is_locked boolean not null default true,
  reason text not null,
  created_by uuid not null default auth.uid() references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_by uuid default auth.uid() references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  expires_at timestamptz,
  constraint action_locks_action_not_blank check (length(btrim(action)) > 0),
  constraint action_locks_reason_not_blank check (length(btrim(reason)) > 0),
  constraint action_locks_scope_id_consistency check (
    (
      scope = 'global'::public.action_lock_scope
      and scope_id is null
    )
    or (
      scope <> 'global'::public.action_lock_scope
      and length(btrim(coalesce(scope_id, ''))) > 0
    )
  )
);

comment on table public.action_locks is
  'Bloqueios administrativos por acao e escopo. Admins escrevem; usuarios podem ler bloqueios ativos para entender indisponibilidade.';
comment on column public.action_locks.scope is
  'Escopo do bloqueio: global, tournament, registration, team, match ou ranking.';
comment on column public.action_locks.scope_id is
  'Identificador do escopo quando nao for global. Armazenado como texto para aceitar IDs de entidades futuras.';
comment on column public.action_locks.action is
  'Acao bloqueada, por exemplo create_tournament, register, generate_bracket ou record_result.';

create unique index if not exists action_locks_unique_scope_action
  on public.action_locks (scope, coalesce(scope_id, ''), action);

create index if not exists action_locks_lookup_idx
  on public.action_locks (action, scope, scope_id, is_locked);

create index if not exists action_locks_created_at_idx
  on public.action_locks (created_at desc);

create or replace function public.write_audit_log(
  target_action text,
  target_entity_type text,
  target_entity_id text,
  target_tournament_id uuid default null,
  target_before_data jsonb default null,
  target_after_data jsonb default null,
  target_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_id uuid;
  current_actor_id uuid;
begin
  current_actor_id := auth.uid();

  if current_actor_id is not null
    and not exists (
      select 1
      from public.profiles
      where id = current_actor_id
    )
  then
    current_actor_id := null;
  end if;

  insert into public.audit_logs (
    actor_id,
    action,
    entity_type,
    entity_id,
    tournament_id,
    before_data,
    after_data,
    reason
  )
  values (
    current_actor_id,
    btrim(target_action),
    btrim(target_entity_type),
    btrim(target_entity_id),
    target_tournament_id,
    target_before_data,
    target_after_data,
    nullif(btrim(coalesce(target_reason, '')), '')
  )
  returning id into inserted_id;

  return inserted_id;
end;
$$;

comment on function public.write_audit_log(text, text, text, uuid, jsonb, jsonb, text) is
  'Funcao interna para escrever audit_logs. Sem grant para anon/authenticated; chamada por triggers/RPCs SECURITY DEFINER.';

revoke all on function public.write_audit_log(text, text, text, uuid, jsonb, jsonb, text) from public;

create or replace function public.is_action_locked(
  target_action text,
  target_scope public.action_lock_scope default 'global',
  target_scope_id text default null
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.action_locks action_lock
    where action_lock.action = target_action
      and action_lock.is_locked
      and (
        action_lock.expires_at is null
        or action_lock.expires_at > now()
      )
      and (
        action_lock.scope = 'global'::public.action_lock_scope
        or (
          action_lock.scope = target_scope
          and action_lock.scope_id is not distinct from target_scope_id
        )
      )
  );
$$;

comment on function public.is_action_locked(text, public.action_lock_scope, text) is
  'Consulta bloqueio ativo por acao. Bloqueio global da mesma acao tambem vale para escopos especificos.';

revoke all on function public.is_action_locked(text, public.action_lock_scope, text) from public;
grant execute on function public.is_action_locked(text, public.action_lock_scope, text) to anon, authenticated;

create or replace function public.assert_action_unlocked(
  target_action text,
  target_scope public.action_lock_scope default 'global',
  target_scope_id text default null
)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  lock_reason text;
begin
  if public.is_admin() then
    return;
  end if;

  select action_lock.reason
  into lock_reason
  from public.action_locks action_lock
  where action_lock.action = target_action
    and action_lock.is_locked
    and (
      action_lock.expires_at is null
      or action_lock.expires_at > now()
    )
    and (
      action_lock.scope = 'global'::public.action_lock_scope
      or (
        action_lock.scope = target_scope
        and action_lock.scope_id is not distinct from target_scope_id
      )
    )
  order by
    case when action_lock.scope = 'global'::public.action_lock_scope then 0 else 1 end,
    action_lock.updated_at desc
  limit 1;

  if lock_reason is not null then
    raise exception 'Acao % bloqueada por administracao: %', target_action, lock_reason
      using errcode = '42501';
  end if;
end;
$$;

comment on function public.assert_action_unlocked(text, public.action_lock_scope, text) is
  'Valida bloqueios no banco. Admin global pode operar para remover ou contornar bloqueios administrativos.';

revoke all on function public.assert_action_unlocked(text, public.action_lock_scope, text) from public;

create or replace function public.can_create_tournament(target_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_admin()
    or (
      target_user_id = auth.uid()
      and not public.is_action_locked(
        'create_tournament',
        'global'::public.action_lock_scope,
        null
      )
      and exists (
        select 1
        from public.tournament_creator_permissions
        where user_id = target_user_id
          and status = 'active'::public.creator_permission_status
      )
    );
$$;

comment on function public.can_create_tournament(uuid) is
  'Retorna true para admin ou usuario com permissao active, desde que create_tournament nao esteja bloqueado para usuarios comuns.';

revoke all on function public.can_create_tournament(uuid) from public;
grant execute on function public.can_create_tournament(uuid) to authenticated;

create or replace function public.can_create_tournaments(target_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.can_create_tournament(target_user_id);
$$;

revoke all on function public.can_create_tournaments(uuid) from public;
grant execute on function public.can_create_tournaments(uuid) to authenticated;

create or replace function public.validate_action_lock_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Apenas admins podem alterar bloqueios administrativos.'
      using errcode = '42501';
  end if;

  if TG_OP = 'INSERT' then
    new.created_by := coalesce(new.created_by, auth.uid());
    new.updated_by := coalesce(new.updated_by, auth.uid());
    new.updated_at := coalesce(new.updated_at, now());

    if new.created_by is null then
      raise exception 'created_by e obrigatorio para bloqueio administrativo.';
    end if;
  elsif TG_OP = 'UPDATE' then
    if new.id is distinct from old.id
      or new.scope is distinct from old.scope
      or new.scope_id is distinct from old.scope_id
      or new.action is distinct from old.action
      or new.created_by is distinct from old.created_by
      or new.created_at is distinct from old.created_at
    then
      raise exception 'Escopo, acao e autoria original do bloqueio nao podem ser alterados.';
    end if;

    new.updated_by := coalesce(auth.uid(), new.updated_by);
    new.updated_at := now();
  end if;

  return new;
end;
$$;

create or replace function public.audit_action_lock_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    perform public.write_audit_log(
      'action_lock_created',
      'action_lock',
      new.id::text,
      null,
      null,
      to_jsonb(new),
      new.reason
    );
    return new;
  elsif TG_OP = 'UPDATE' then
    perform public.write_audit_log(
      'action_lock_updated',
      'action_lock',
      new.id::text,
      null,
      to_jsonb(old),
      to_jsonb(new),
      new.reason
    );
    return new;
  else
    perform public.write_audit_log(
      'action_lock_deleted',
      'action_lock',
      old.id::text,
      null,
      to_jsonb(old),
      null,
      old.reason
    );
    return old;
  end if;
end;
$$;

drop trigger if exists action_locks_validate_write on public.action_locks;
create trigger action_locks_validate_write
  before insert or update on public.action_locks
  for each row
  execute function public.validate_action_lock_write();

drop trigger if exists action_locks_audit_write on public.action_locks;
create trigger action_locks_audit_write
  after insert or update or delete on public.action_locks
  for each row
  execute function public.audit_action_lock_write();

create or replace function public.audit_profile_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role then
    perform public.write_audit_log(
      'profile_role_changed',
      'profile',
      new.id::text,
      null,
      jsonb_build_object('role', old.role),
      jsonb_build_object('role', new.role),
      null
    );
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_audit_role_change on public.profiles;
create trigger profiles_audit_role_change
  after update on public.profiles
  for each row
  execute function public.audit_profile_role_change();

create or replace function public.audit_creator_request_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  audit_action text;
begin
  if new.status is distinct from old.status
    and new.status in ('approved', 'rejected', 'cancelled')
  then
    audit_action := case new.status
      when 'approved' then 'creator_request_approved'
      when 'rejected' then 'creator_request_rejected'
      else 'creator_request_cancelled'
    end;

    perform public.write_audit_log(
      audit_action,
      'tournament_creator_request',
      new.id::text,
      null,
      jsonb_build_object(
        'status', old.status,
        'reviewed_by', old.reviewed_by,
        'reviewed_at', old.reviewed_at
      ),
      jsonb_build_object(
        'status', new.status,
        'user_id', new.user_id,
        'reviewed_by', new.reviewed_by,
        'reviewed_at', new.reviewed_at
      ),
      new.admin_notes
    );
  end if;

  return new;
end;
$$;

drop trigger if exists tournament_creator_requests_audit_decision
  on public.tournament_creator_requests;
create trigger tournament_creator_requests_audit_decision
  after update on public.tournament_creator_requests
  for each row
  execute function public.audit_creator_request_decision();

create or replace function public.audit_creator_permission_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  audit_action text;
begin
  if TG_OP = 'INSERT' then
    audit_action := 'creator_permission_granted';
    perform public.write_audit_log(
      audit_action,
      'tournament_creator_permission',
      new.id::text,
      null,
      null,
      to_jsonb(new),
      new.grant_reason
    );
    return new;
  end if;

  if new.status = 'revoked'::public.creator_permission_status
    and old.status is distinct from new.status
  then
    audit_action := 'creator_permission_revoked';
  else
    audit_action := 'creator_permission_updated';
  end if;

  perform public.write_audit_log(
    audit_action,
    'tournament_creator_permission',
    new.id::text,
    null,
    to_jsonb(old),
    to_jsonb(new),
    coalesce(new.revoke_reason, new.grant_reason)
  );

  return new;
end;
$$;

drop trigger if exists tournament_creator_permissions_audit_write
  on public.tournament_creator_permissions;
create trigger tournament_creator_permissions_audit_write
  after insert or update on public.tournament_creator_permissions
  for each row
  execute function public.audit_creator_permission_write();

create or replace function public.assert_tournament_action_unlocked()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    perform public.assert_action_unlocked(
      'create_tournament',
      'global'::public.action_lock_scope,
      null
    );
    return new;
  elsif TG_OP = 'UPDATE' then
    perform public.assert_action_unlocked(
      'edit_tournament',
      'tournament'::public.action_lock_scope,
      new.id::text
    );
    return new;
  else
    perform public.assert_action_unlocked(
      'delete_tournament',
      'tournament'::public.action_lock_scope,
      old.id::text
    );
    return old;
  end if;
end;
$$;

drop trigger if exists tournaments_action_lock on public.tournaments;
create trigger tournaments_action_lock
  before insert or update or delete on public.tournaments
  for each row
  execute function public.assert_tournament_action_unlocked();

create or replace function public.audit_tournament_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  audit_action text;
begin
  if TG_OP = 'INSERT' then
    perform public.write_audit_log(
      'tournament_created',
      'tournament',
      new.id::text,
      new.id,
      null,
      to_jsonb(new),
      null
    );
    return new;
  elsif TG_OP = 'UPDATE' then
    audit_action := case
      when new.status is distinct from old.status then 'tournament_status_changed'
      else 'tournament_updated'
    end;

    perform public.write_audit_log(
      audit_action,
      'tournament',
      new.id::text,
      new.id,
      to_jsonb(old),
      to_jsonb(new),
      null
    );
    return new;
  else
    perform public.write_audit_log(
      'tournament_deleted',
      'tournament',
      old.id::text,
      old.id,
      to_jsonb(old),
      null,
      null
    );
    return old;
  end if;
end;
$$;

drop trigger if exists tournaments_audit_write on public.tournaments;
create trigger tournaments_audit_write
  after insert or update or delete on public.tournaments
  for each row
  execute function public.audit_tournament_write();

create or replace function public.assert_registration_action_unlocked()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    perform public.assert_action_unlocked(
      'register',
      'tournament'::public.action_lock_scope,
      new.tournament_id::text
    );
    return new;
  end if;

  if new.status is distinct from old.status then
    if new.status = 'cancelled'::public.tournament_registration_status then
      perform public.assert_action_unlocked(
        'cancel_registration',
        'tournament'::public.action_lock_scope,
        new.tournament_id::text
      );
      perform public.assert_action_unlocked(
        'cancel_registration',
        'registration'::public.action_lock_scope,
        new.id::text
      );
    elsif new.status in (
      'confirmed'::public.tournament_registration_status,
      'rejected'::public.tournament_registration_status,
      'checked_in'::public.tournament_registration_status
    ) then
      perform public.assert_action_unlocked(
        'manage_registration',
        'tournament'::public.action_lock_scope,
        new.tournament_id::text
      );
      perform public.assert_action_unlocked(
        'manage_registration',
        'registration'::public.action_lock_scope,
        new.id::text
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists tournament_registrations_action_lock
  on public.tournament_registrations;
create trigger tournament_registrations_action_lock
  before insert or update on public.tournament_registrations
  for each row
  execute function public.assert_registration_action_unlocked();

create or replace function public.audit_registration_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  audit_action text;
begin
  if TG_OP = 'INSERT' then
    perform public.write_audit_log(
      'registration_created',
      'tournament_registration',
      new.id::text,
      new.tournament_id,
      null,
      to_jsonb(new),
      null
    );
    return new;
  end if;

  if new.seed is distinct from old.seed then
    perform public.write_audit_log(
      'registration_seed_changed',
      'tournament_registration',
      new.id::text,
      new.tournament_id,
      jsonb_build_object('seed', old.seed),
      jsonb_build_object('seed', new.seed),
      new.admin_notes
    );
  end if;

  if new.status is distinct from old.status then
    audit_action := case new.status
      when 'confirmed' then 'registration_confirmed'
      when 'rejected' then 'registration_rejected'
      when 'cancelled' then 'registration_cancelled'
      when 'checked_in' then 'registration_checked_in'
      else 'registration_status_changed'
    end;

    perform public.write_audit_log(
      audit_action,
      'tournament_registration',
      new.id::text,
      new.tournament_id,
      jsonb_build_object(
        'status', old.status,
        'decided_by', old.decided_by,
        'decided_at', old.decided_at,
        'cancelled_by', old.cancelled_by,
        'cancelled_at', old.cancelled_at
      ),
      jsonb_build_object(
        'status', new.status,
        'decided_by', new.decided_by,
        'decided_at', new.decided_at,
        'cancelled_by', new.cancelled_by,
        'cancelled_at', new.cancelled_at
      ),
      new.admin_notes
    );
  end if;

  return new;
end;
$$;

drop trigger if exists tournament_registrations_audit_write
  on public.tournament_registrations;
create trigger tournament_registrations_audit_write
  after insert or update on public.tournament_registrations
  for each row
  execute function public.audit_registration_write();

create or replace function public.assert_team_action_unlocked()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_tournament_id uuid;
  target_team_id uuid;
begin
  target_tournament_id := case when TG_OP = 'DELETE' then old.tournament_id else new.tournament_id end;
  target_team_id := case when TG_OP = 'DELETE' then old.id else new.id end;

  perform public.assert_action_unlocked(
    'manage_teams',
    'tournament'::public.action_lock_scope,
    target_tournament_id::text
  );

  if target_team_id is not null then
    perform public.assert_action_unlocked(
      'manage_teams',
      'team'::public.action_lock_scope,
      target_team_id::text
    );
  end if;

  if TG_OP = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists teams_action_lock on public.teams;
create trigger teams_action_lock
  before insert or update or delete on public.teams
  for each row
  execute function public.assert_team_action_unlocked();

create or replace function public.assert_team_member_action_unlocked()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_tournament_id uuid;
  target_team_id uuid;
begin
  target_tournament_id := case when TG_OP = 'DELETE' then old.tournament_id else new.tournament_id end;
  target_team_id := case when TG_OP = 'DELETE' then old.team_id else new.team_id end;

  if target_tournament_id is null and target_team_id is not null then
    select team.tournament_id
    into target_tournament_id
    from public.teams team
    where team.id = target_team_id;
  end if;

  perform public.assert_action_unlocked(
    'manage_teams',
    'tournament'::public.action_lock_scope,
    target_tournament_id::text
  );

  perform public.assert_action_unlocked(
    'manage_teams',
    'team'::public.action_lock_scope,
    target_team_id::text
  );

  if TG_OP = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists team_members_action_lock on public.team_members;
create trigger team_members_action_lock
  before insert or update or delete on public.team_members
  for each row
  execute function public.assert_team_member_action_unlocked();

create or replace function public.assert_bracket_action_unlocked()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_tournament_id uuid;
begin
  if current_setting('app.bracket_completion', true) = 'on'
    or current_setting('app.match_result_write', true) = 'on'
  then
    if TG_OP = 'DELETE' then
      return old;
    end if;

    return new;
  end if;

  target_tournament_id := case when TG_OP = 'DELETE' then old.tournament_id else new.tournament_id end;

  perform public.assert_action_unlocked(
    'generate_bracket',
    'tournament'::public.action_lock_scope,
    target_tournament_id::text
  );

  if TG_OP = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists tournament_brackets_action_lock on public.tournament_brackets;
create trigger tournament_brackets_action_lock
  before insert or update or delete on public.tournament_brackets
  for each row
  execute function public.assert_bracket_action_unlocked();

create or replace function public.audit_bracket_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    perform public.write_audit_log(
      'bracket_generated',
      'tournament_bracket',
      new.id::text,
      new.tournament_id,
      null,
      to_jsonb(new),
      new.seeding_method::text
    );
    return new;
  elsif TG_OP = 'DELETE' then
    perform public.write_audit_log(
      'bracket_deleted',
      'tournament_bracket',
      old.id::text,
      old.tournament_id,
      to_jsonb(old),
      null,
      'Remocao de chave'
    );
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists tournament_brackets_audit_write on public.tournament_brackets;
create trigger tournament_brackets_audit_write
  after insert or delete on public.tournament_brackets
  for each row
  execute function public.audit_bracket_write();

create or replace function public.assert_match_result_action_unlocked()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_action text;
begin
  target_action := 'record_result';

  if TG_OP = 'UPDATE'
    and new.status = 'disputed'::public.match_result_status
    and old.status is distinct from new.status
  then
    target_action := 'contest_result';
  end if;

  perform public.assert_action_unlocked(
    target_action,
    'tournament'::public.action_lock_scope,
    new.tournament_id::text
  );

  perform public.assert_action_unlocked(
    target_action,
    'match'::public.action_lock_scope,
    new.match_id::text
  );

  return new;
end;
$$;

drop trigger if exists match_results_action_lock on public.match_results;
create trigger match_results_action_lock
  before insert or update on public.match_results
  for each row
  execute function public.assert_match_result_action_unlocked();

create or replace function public.audit_match_result_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  audit_action text;
begin
  if TG_OP = 'INSERT' then
    perform public.write_audit_log(
      'match_result_recorded',
      'match_result',
      new.id::text,
      new.tournament_id,
      null,
      to_jsonb(new),
      new.notes
    );
    return new;
  end if;

  audit_action := case
    when new.status = 'disputed'::public.match_result_status
      and old.status is distinct from new.status
      then 'match_result_disputed'
    when new.status in (
      'resolved'::public.match_result_status,
      'cancelled'::public.match_result_status
    )
      and old.status is distinct from new.status
      then 'match_dispute_resolved'
    when new.score_a is distinct from old.score_a
      or new.score_b is distinct from old.score_b
      or new.winner_registration_id is distinct from old.winner_registration_id
      then 'match_result_corrected'
    else 'match_result_updated'
  end;

  perform public.write_audit_log(
    audit_action,
    'match_result',
    new.id::text,
    new.tournament_id,
    to_jsonb(old),
    to_jsonb(new),
    coalesce(new.resolution_notes, new.dispute_reason, new.notes)
  );

  return new;
end;
$$;

drop trigger if exists match_results_audit_write on public.match_results;
create trigger match_results_audit_write
  after insert or update on public.match_results
  for each row
  execute function public.audit_match_result_write();

create or replace function public.assert_standing_action_unlocked()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_tournament_id uuid;
  target_scope_id text;
begin
  target_tournament_id := case when TG_OP = 'DELETE' then old.tournament_id else new.tournament_id end;
  target_scope_id := case
    when TG_TABLE_NAME = 'standing_entries' and TG_OP = 'DELETE' then old.standing_id::text
    when TG_TABLE_NAME = 'standing_entries' then new.standing_id::text
    when TG_OP = 'DELETE' then old.id::text
    else new.id::text
  end;

  perform public.assert_action_unlocked(
    'recalculate_ranking',
    'tournament'::public.action_lock_scope,
    target_tournament_id::text
  );

  perform public.assert_action_unlocked(
    'recalculate_ranking',
    'ranking'::public.action_lock_scope,
    target_scope_id
  );

  if TG_OP = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists tournament_standings_action_lock on public.tournament_standings;
create trigger tournament_standings_action_lock
  before insert or update or delete on public.tournament_standings
  for each row
  execute function public.assert_standing_action_unlocked();

drop trigger if exists standing_entries_action_lock on public.standing_entries;
create trigger standing_entries_action_lock
  before insert or update or delete on public.standing_entries
  for each row
  execute function public.assert_standing_action_unlocked();

alter table public.audit_logs enable row level security;
alter table public.action_locks enable row level security;

grant select on public.audit_logs to authenticated;
revoke insert, update, delete on public.audit_logs from anon, authenticated;

grant select on public.action_locks to anon, authenticated;
grant insert, update, delete on public.action_locks to authenticated;

drop policy if exists "audit_logs_select_admin" on public.audit_logs;
drop policy if exists "action_locks_select_active" on public.action_locks;
drop policy if exists "action_locks_select_admin" on public.action_locks;
drop policy if exists "action_locks_insert_admin" on public.action_locks;
drop policy if exists "action_locks_update_admin" on public.action_locks;
drop policy if exists "action_locks_delete_admin" on public.action_locks;

create policy "audit_logs_select_admin"
  on public.audit_logs
  for select
  to authenticated
  using (public.is_admin());

create policy "action_locks_select_active"
  on public.action_locks
  for select
  to anon, authenticated
  using (
    is_locked
    and (
      expires_at is null
      or expires_at > now()
    )
  );

create policy "action_locks_select_admin"
  on public.action_locks
  for select
  to authenticated
  using (public.is_admin());

create policy "action_locks_insert_admin"
  on public.action_locks
  for insert
  to authenticated
  with check (public.is_admin());

create policy "action_locks_update_admin"
  on public.action_locks
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "action_locks_delete_admin"
  on public.action_locks
  for delete
  to authenticated
  using (public.is_admin());
