-- Check-in formal, W.O. e desclassificacao.
-- Depende da base de auditoria e action_locks criada em 20260526090000.

alter table public.tournaments
  add column if not exists requires_check_in boolean not null default false;

alter table public.tournaments
  add column if not exists check_in_opens_at timestamptz;

alter table public.tournaments
  add column if not exists check_in_closes_at timestamptz;

comment on column public.tournaments.requires_check_in is
  'Quando true, a geracao de chave usa apenas inscricoes com check-in confirmado.';
comment on column public.tournaments.check_in_opens_at is
  'Inicio opcional da janela formal de check-in.';
comment on column public.tournaments.check_in_closes_at is
  'Fim opcional da janela formal de check-in.';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'tournaments_check_in_window_order'
      and conrelid = 'public.tournaments'::regclass
  ) then
    alter table public.tournaments
      add constraint tournaments_check_in_window_order check (
        check_in_closes_at is null
        or check_in_opens_at is null
        or check_in_closes_at > check_in_opens_at
      );
  end if;
end
$$;

alter table public.tournament_registrations
  add column if not exists checked_in_at timestamptz;

alter table public.tournament_registrations
  add column if not exists checked_in_by uuid references public.profiles(id) on delete set null;

alter table public.tournament_registrations
  add column if not exists check_in_notes text;

alter table public.tournament_registrations
  add column if not exists check_in_revoked_by uuid references public.profiles(id) on delete set null;

alter table public.tournament_registrations
  add column if not exists check_in_revoked_at timestamptz;

alter table public.tournament_registrations
  add column if not exists disqualified_at timestamptz;

alter table public.tournament_registrations
  add column if not exists disqualified_by uuid references public.profiles(id) on delete set null;

alter table public.tournament_registrations
  add column if not exists disqualification_reason text;

alter table public.tournament_registrations
  add column if not exists no_show_at timestamptz;

alter table public.tournament_registrations
  add column if not exists no_show_by uuid references public.profiles(id) on delete set null;

alter table public.tournament_registrations
  add column if not exists no_show_reason text;

comment on column public.tournament_registrations.checked_in_at is
  'Momento em que a presenca foi confirmada pelo participante ou pela organizacao.';
comment on column public.tournament_registrations.checked_in_by is
  'Usuario que confirmou o check-in. Pode ser o proprio inscrito, admin ou organizador.';
comment on column public.tournament_registrations.check_in_notes is
  'Observacao operacional do check-in ou justificativa ao desfazer check-in.';
comment on column public.tournament_registrations.disqualified_at is
  'Momento da desclassificacao administrativa. Campo nulo significa participante elegivel.';
comment on column public.tournament_registrations.disqualification_reason is
  'Justificativa administrativa obrigatoria para desclassificacao.';
comment on column public.tournament_registrations.no_show_at is
  'Momento em que o participante/equipe recebeu W.O. por ausencia ou regra equivalente.';
comment on column public.tournament_registrations.no_show_reason is
  'Justificativa do W.O. associada ao participante/equipe que nao avancou.';

update public.tournament_registrations
set checked_in_at = coalesce(checked_in_at, decided_at, updated_at, now()),
    checked_in_by = coalesce(checked_in_by, decided_by, user_id),
    check_in_notes = coalesce(check_in_notes, admin_notes, 'Backfill de check-in legado')
where status = 'checked_in'::public.tournament_registration_status
  and (
    checked_in_at is null
    or checked_in_by is null
  );

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'tournament_registrations_check_in_consistency'
      and conrelid = 'public.tournament_registrations'::regclass
  ) then
    alter table public.tournament_registrations
      add constraint tournament_registrations_check_in_consistency check (
        (
          checked_in_at is null
          and checked_in_by is null
        )
        or (
          checked_in_at is not null
          and checked_in_by is not null
        )
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'tournament_registrations_disqualification_consistency'
      and conrelid = 'public.tournament_registrations'::regclass
  ) then
    alter table public.tournament_registrations
      add constraint tournament_registrations_disqualification_consistency check (
        (
          disqualified_at is null
          and disqualified_by is null
          and disqualification_reason is null
        )
        or (
          disqualified_at is not null
          and disqualified_by is not null
          and length(btrim(coalesce(disqualification_reason, ''))) >= 5
        )
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'tournament_registrations_no_show_consistency'
      and conrelid = 'public.tournament_registrations'::regclass
  ) then
    alter table public.tournament_registrations
      add constraint tournament_registrations_no_show_consistency check (
        (
          no_show_at is null
          and no_show_by is null
          and no_show_reason is null
        )
        or (
          no_show_at is not null
          and no_show_by is not null
          and length(btrim(coalesce(no_show_reason, ''))) >= 5
        )
      );
  end if;
end
$$;

create index if not exists tournament_registrations_check_in_idx
  on public.tournament_registrations (tournament_id, checked_in_at)
  where checked_in_at is not null;

create index if not exists tournament_registrations_disqualified_idx
  on public.tournament_registrations (tournament_id, disqualified_at)
  where disqualified_at is not null;

alter table public.match_results
  add column if not exists result_type text not null default 'score';

alter table public.match_results
  add column if not exists walkover_reason text;

alter table public.match_results
  add column if not exists walkover_by uuid references public.profiles(id) on delete set null;

alter table public.match_results
  add column if not exists walkover_at timestamptz;

comment on column public.match_results.result_type is
  'Tipo do resultado: score para placar comum, walkover para W.O. sem placar esportivo.';
comment on column public.match_results.walkover_reason is
  'Justificativa administrativa obrigatoria quando result_type = walkover.';

alter table public.bracket_matches
  add column if not exists result_type text not null default 'score';

alter table public.bracket_matches
  add column if not exists walkover_reason text;

alter table public.bracket_matches
  add column if not exists walkover_by uuid references public.profiles(id) on delete set null;

alter table public.bracket_matches
  add column if not exists walkover_at timestamptz;

comment on column public.bracket_matches.result_type is
  'Espelho operacional do tipo de resultado para renderizacao rapida da chave.';
comment on column public.bracket_matches.walkover_reason is
  'Justificativa do W.O. exibida para gestores e participantes envolvidos.';

alter table public.match_result_history
  add column if not exists previous_result_type text;

alter table public.match_result_history
  add column if not exists new_result_type text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'match_results_result_type_allowed'
      and conrelid = 'public.match_results'::regclass
  ) then
    alter table public.match_results
      add constraint match_results_result_type_allowed check (
        result_type in ('score', 'walkover')
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'match_results_walkover_consistency'
      and conrelid = 'public.match_results'::regclass
  ) then
    alter table public.match_results
      add constraint match_results_walkover_consistency check (
        result_type <> 'walkover'
        or (
          walkover_by is not null
          and walkover_at is not null
          and length(btrim(coalesce(walkover_reason, ''))) >= 5
        )
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'bracket_matches_result_type_allowed'
      and conrelid = 'public.bracket_matches'::regclass
  ) then
    alter table public.bracket_matches
      add constraint bracket_matches_result_type_allowed check (
        result_type in ('score', 'walkover')
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'bracket_matches_walkover_consistency'
      and conrelid = 'public.bracket_matches'::regclass
  ) then
    alter table public.bracket_matches
      add constraint bracket_matches_walkover_consistency check (
        result_type <> 'walkover'
        or (
          walkover_by is not null
          and walkover_at is not null
          and length(btrim(coalesce(walkover_reason, ''))) >= 5
        )
      );
  end if;
end
$$;

create or replace function public.is_tournament_check_in_open(target_tournament_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tournaments tournament
    where tournament.id = target_tournament_id
      and tournament.check_in_opens_at is not null
      and tournament.check_in_opens_at <= now()
      and (
        tournament.check_in_closes_at is null
        or tournament.check_in_closes_at > now()
      )
  );
$$;

revoke all on function public.is_tournament_check_in_open(uuid) from public;
grant execute on function public.is_tournament_check_in_open(uuid) to anon, authenticated;

create or replace function public.open_tournament_check_in(
  target_tournament_id uuid,
  target_opens_at timestamptz default now(),
  target_closes_at timestamptz default null,
  target_requires_check_in boolean default true
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_tournament public.tournaments%rowtype;
begin
  select *
  into target_tournament
  from public.tournaments
  where id = target_tournament_id;

  if target_tournament.id is null then
    raise exception 'Torneio nao encontrado.';
  end if;

  if not public.can_manage_tournament(target_tournament.id) then
    raise exception 'Usuario nao pode gerenciar check-in deste torneio.'
      using errcode = '42501';
  end if;

  perform public.assert_action_unlocked(
    'manage_registration',
    'tournament'::public.action_lock_scope,
    target_tournament.id::text
  );

  if target_opens_at is null then
    target_opens_at := now();
  end if;

  if target_closes_at is not null and target_closes_at <= target_opens_at then
    raise exception 'Fechamento do check-in deve ser posterior a abertura.';
  end if;

  update public.tournaments
  set check_in_opens_at = target_opens_at,
      check_in_closes_at = target_closes_at,
      requires_check_in = target_requires_check_in,
      updated_at = now()
  where id = target_tournament.id;
end;
$$;

revoke all on function public.open_tournament_check_in(uuid, timestamptz, timestamptz, boolean) from public;
grant execute on function public.open_tournament_check_in(uuid, timestamptz, timestamptz, boolean) to authenticated;

create or replace function public.close_tournament_check_in(target_tournament_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_tournament public.tournaments%rowtype;
begin
  select *
  into target_tournament
  from public.tournaments
  where id = target_tournament_id;

  if target_tournament.id is null then
    raise exception 'Torneio nao encontrado.';
  end if;

  if not public.can_manage_tournament(target_tournament.id) then
    raise exception 'Usuario nao pode gerenciar check-in deste torneio.'
      using errcode = '42501';
  end if;

  perform public.assert_action_unlocked(
    'manage_registration',
    'tournament'::public.action_lock_scope,
    target_tournament.id::text
  );

  update public.tournaments
  set check_in_closes_at = now(),
      updated_at = now()
  where id = target_tournament.id;
end;
$$;

revoke all on function public.close_tournament_check_in(uuid) from public;
grant execute on function public.close_tournament_check_in(uuid) to authenticated;

create or replace function public.validate_tournament_registration_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  current_tournament_status public.tournament_status;
  current_max_participants integer;
  current_registration_type public.registration_type;
  current_registration_count integer;
  target_team public.teams%rowtype;
begin
  select status, max_participants, registration_type
  into current_tournament_status, current_max_participants, current_registration_type
  from public.tournaments
  where id = new.tournament_id;

  if current_tournament_status is null then
    raise exception 'Torneio da inscricao nao encontrado.';
  end if;

  if new.registration_type <> current_registration_type then
    raise exception 'Tipo de inscricao incompativel com o torneio.';
  end if;

  if new.registration_type = 'team'::public.registration_type then
    if new.team_id is null then
      raise exception 'Inscricao por equipe precisa apontar para uma equipe.';
    end if;

    select *
    into target_team
    from public.teams
    where id = new.team_id;

    if target_team.id is null
      or target_team.tournament_id <> new.tournament_id
      or target_team.captain_id <> new.user_id
    then
      raise exception 'Equipe invalida para esta inscricao.';
    end if;

    new.captain_user_id := coalesce(new.captain_user_id, new.user_id);
  else
    if new.team_id is not null then
      raise exception 'Inscricao individual nao pode apontar para equipe.';
    end if;

    new.captain_user_id := null;
  end if;

  if current_setting('app.registration_check_in', true) = 'on'
    or current_setting('app.registration_disqualification', true) = 'on'
    or current_setting('app.registration_no_show', true) = 'on'
  then
    return new;
  end if;

  if TG_OP = 'INSERT' then
    if new.status <> 'pending'::public.tournament_registration_status then
      raise exception 'Novas inscricoes devem iniciar como pendentes.';
    end if;

    if current_tournament_status <> 'registrations_open'::public.tournament_status then
      raise exception 'Inscricoes so sao permitidas quando o torneio esta com inscricoes abertas.';
    end if;
  end if;

  if TG_OP = 'UPDATE' then
    if new.id is distinct from old.id then
      raise exception 'O id da inscricao nao pode ser alterado.';
    end if;

    if new.tournament_id is distinct from old.tournament_id then
      raise exception 'O torneio da inscricao nao pode ser alterado.';
    end if;

    if new.user_id is distinct from old.user_id then
      raise exception 'O usuario da inscricao nao pode ser alterado.';
    end if;

    if new.registration_type is distinct from old.registration_type then
      raise exception 'O tipo da inscricao nao pode ser alterado.';
    end if;

    if new.status = 'registered'::public.tournament_registration_status then
      raise exception 'registered e status legado. Use pending, confirmed, rejected, checked_in ou cancelled.';
    end if;

    if old.status in (
      'cancelled'::public.tournament_registration_status,
      'rejected'::public.tournament_registration_status
    )
      and new.status is distinct from old.status
    then
      raise exception 'Inscricoes canceladas ou rejeitadas nao devem ser reativadas. Crie uma nova inscricao.';
    end if;

    if not public.can_manage_tournament(new.tournament_id) then
      if old.user_id <> auth.uid() then
        raise exception 'Usuario comum so pode alterar a propria inscricao.';
      end if;

      if old.status not in (
        'pending'::public.tournament_registration_status,
        'confirmed'::public.tournament_registration_status
      )
        or new.status <> 'cancelled'::public.tournament_registration_status
      then
        raise exception 'Usuario comum so pode cancelar inscricao pendente ou confirmada.';
      end if;

      if current_tournament_status not in (
        'registrations_open'::public.tournament_status,
        'registrations_closed'::public.tournament_status
      ) then
        raise exception 'A inscricao nao pode ser cancelada neste status do torneio.';
      end if;

      if new.display_name is distinct from old.display_name
        or new.admin_notes is distinct from old.admin_notes
        or new.decided_by is distinct from old.decided_by
        or new.decided_at is distinct from old.decided_at
        or new.created_at is distinct from old.created_at
        or new.checked_in_at is distinct from old.checked_in_at
        or new.checked_in_by is distinct from old.checked_in_by
        or new.check_in_notes is distinct from old.check_in_notes
        or new.check_in_revoked_by is distinct from old.check_in_revoked_by
        or new.check_in_revoked_at is distinct from old.check_in_revoked_at
        or new.disqualified_at is distinct from old.disqualified_at
        or new.disqualified_by is distinct from old.disqualified_by
        or new.disqualification_reason is distinct from old.disqualification_reason
        or new.no_show_at is distinct from old.no_show_at
        or new.no_show_by is distinct from old.no_show_by
        or new.no_show_reason is distinct from old.no_show_reason
      then
        raise exception 'Usuario comum nao pode alterar campos administrativos da inscricao.';
      end if;
    end if;

    if public.can_manage_tournament(new.tournament_id)
      and new.status is distinct from old.status
    then
      if new.status in (
        'confirmed'::public.tournament_registration_status,
        'rejected'::public.tournament_registration_status,
        'cancelled'::public.tournament_registration_status
      )
        and current_tournament_status not in (
          'registrations_open'::public.tournament_status,
          'registrations_closed'::public.tournament_status
        )
      then
        raise exception 'Inscricoes so podem ser confirmadas, rejeitadas ou canceladas antes do torneio comecar.';
      end if;

      if new.status = 'checked_in'::public.tournament_registration_status
        and current_tournament_status not in (
          'registrations_closed'::public.tournament_status,
          'ongoing'::public.tournament_status
        )
      then
        raise exception 'Check-in so e permitido apos o fechamento das inscricoes ou durante o torneio.';
      end if;
    end if;
  end if;

  if new.status in (
    'confirmed'::public.tournament_registration_status,
    'rejected'::public.tournament_registration_status,
    'checked_in'::public.tournament_registration_status
  ) then
    new.decided_by := coalesce(new.decided_by, auth.uid());
    new.decided_at := coalesce(new.decided_at, now());
  end if;

  if new.status = 'checked_in'::public.tournament_registration_status then
    new.checked_in_by := coalesce(new.checked_in_by, auth.uid());
    new.checked_in_at := coalesce(new.checked_in_at, now());
  end if;

  if new.status = 'cancelled'::public.tournament_registration_status then
    new.cancelled_by := coalesce(new.cancelled_by, auth.uid(), new.user_id);
    new.cancelled_at := coalesce(new.cancelled_at, now());
  end if;

  if new.team_id is not null and new.status in (
    'confirmed'::public.tournament_registration_status,
    'rejected'::public.tournament_registration_status,
    'cancelled'::public.tournament_registration_status
  ) then
    update public.teams
    set status = case new.status
      when 'confirmed'::public.tournament_registration_status then 'confirmed'::public.team_status
      when 'rejected'::public.tournament_registration_status then 'rejected'::public.team_status
      else 'cancelled'::public.team_status
    end,
        decided_by = case
          when new.status in (
            'confirmed'::public.tournament_registration_status,
            'rejected'::public.tournament_registration_status
          )
          then new.decided_by
          else decided_by
        end,
        decided_at = case
          when new.status in (
            'confirmed'::public.tournament_registration_status,
            'rejected'::public.tournament_registration_status
          )
          then new.decided_at
          else decided_at
        end,
        cancelled_by = case
          when new.status = 'cancelled'::public.tournament_registration_status then new.cancelled_by
          else cancelled_by
        end,
        cancelled_at = case
          when new.status = 'cancelled'::public.tournament_registration_status then new.cancelled_at
          else cancelled_at
        end,
        admin_notes = coalesce(new.admin_notes, admin_notes),
        updated_at = now()
    where id = new.team_id;
  end if;

  if new.status in (
    'pending'::public.tournament_registration_status,
    'confirmed'::public.tournament_registration_status,
    'checked_in'::public.tournament_registration_status
  ) then
    select count(*)
    into current_registration_count
    from public.tournament_registrations
    where tournament_id = new.tournament_id
      and status in (
        'pending'::public.tournament_registration_status,
        'confirmed'::public.tournament_registration_status,
        'checked_in'::public.tournament_registration_status
      )
      and disqualified_at is null
      and (
        TG_OP = 'INSERT'
        or id <> new.id
      );

    if current_registration_count >= current_max_participants then
      raise exception 'O torneio atingiu o limite de participantes.';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.confirm_registration_check_in(target_registration_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_registration public.tournament_registrations%rowtype;
  target_tournament public.tournaments%rowtype;
begin
  select *
  into target_registration
  from public.tournament_registrations
  where id = target_registration_id;

  if target_registration.id is null then
    raise exception 'Inscricao nao encontrada.';
  end if;

  if target_registration.user_id <> auth.uid()
    and target_registration.captain_user_id is distinct from auth.uid()
  then
    raise exception 'Usuario so pode fazer check-in da propria inscricao.'
      using errcode = '42501';
  end if;

  if target_registration.disqualified_at is not null then
    raise exception 'Inscricao desclassificada nao pode fazer check-in.';
  end if;

  if target_registration.status not in (
    'confirmed'::public.tournament_registration_status,
    'checked_in'::public.tournament_registration_status
  ) then
    raise exception 'Check-in exige inscricao confirmada.';
  end if;

  select *
  into target_tournament
  from public.tournaments
  where id = target_registration.tournament_id;

  if target_tournament.id is null then
    raise exception 'Torneio nao encontrado.';
  end if;

  perform public.assert_action_unlocked(
    'check_in',
    'tournament'::public.action_lock_scope,
    target_tournament.id::text
  );

  if not public.is_tournament_check_in_open(target_tournament.id) then
    raise exception 'Check-in fora da janela permitida.';
  end if;

  if target_registration.checked_in_at is not null then
    return;
  end if;

  perform set_config('app.registration_check_in', 'on', true);

  update public.tournament_registrations
  set status = 'checked_in'::public.tournament_registration_status,
      checked_in_at = now(),
      checked_in_by = auth.uid(),
      check_in_notes = coalesce(check_in_notes, 'Check-in confirmado pelo participante'),
      check_in_revoked_by = null,
      check_in_revoked_at = null,
      updated_at = now()
  where id = target_registration.id;

  perform set_config('app.registration_check_in', 'off', true);
end;
$$;

revoke all on function public.confirm_registration_check_in(uuid) from public;
grant execute on function public.confirm_registration_check_in(uuid) to authenticated;

create or replace function public.set_registration_check_in(
  target_registration_id uuid,
  target_is_checked_in boolean,
  target_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_registration public.tournament_registrations%rowtype;
begin
  select *
  into target_registration
  from public.tournament_registrations
  where id = target_registration_id;

  if target_registration.id is null then
    raise exception 'Inscricao nao encontrada.';
  end if;

  if not public.can_manage_tournament(target_registration.tournament_id) then
    raise exception 'Usuario nao pode gerenciar check-in desta inscricao.'
      using errcode = '42501';
  end if;

  perform public.assert_action_unlocked(
    'manage_registration',
    'tournament'::public.action_lock_scope,
    target_registration.tournament_id::text
  );

  if target_registration.disqualified_at is not null then
    raise exception 'Inscricao desclassificada nao pode receber check-in.';
  end if;

  perform set_config('app.registration_check_in', 'on', true);

  if target_is_checked_in then
    update public.tournament_registrations
    set status = 'checked_in'::public.tournament_registration_status,
        checked_in_at = now(),
        checked_in_by = auth.uid(),
        check_in_notes = coalesce(nullif(btrim(coalesce(target_notes, '')), ''), check_in_notes, 'Check-in manual'),
        check_in_revoked_by = null,
        check_in_revoked_at = null,
        decided_by = coalesce(decided_by, auth.uid()),
        decided_at = coalesce(decided_at, now()),
        updated_at = now()
    where id = target_registration.id;
  else
    if length(btrim(coalesce(target_notes, ''))) < 3 then
      raise exception 'Desfazer check-in exige justificativa.';
    end if;

    update public.tournament_registrations
    set status = case
          when status = 'checked_in'::public.tournament_registration_status
          then 'confirmed'::public.tournament_registration_status
          else status
        end,
        checked_in_at = null,
        checked_in_by = null,
        check_in_notes = btrim(target_notes),
        check_in_revoked_by = auth.uid(),
        check_in_revoked_at = now(),
        updated_at = now()
    where id = target_registration.id;
  end if;

  perform set_config('app.registration_check_in', 'off', true);
end;
$$;

revoke all on function public.set_registration_check_in(uuid, boolean, text) from public;
grant execute on function public.set_registration_check_in(uuid, boolean, text) to authenticated;

create or replace function public.disqualify_registration(
  target_registration_id uuid,
  target_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_registration public.tournament_registrations%rowtype;
begin
  select *
  into target_registration
  from public.tournament_registrations
  where id = target_registration_id;

  if target_registration.id is null then
    raise exception 'Inscricao nao encontrada.';
  end if;

  if not public.can_manage_tournament(target_registration.tournament_id) then
    raise exception 'Usuario nao pode desclassificar esta inscricao.'
      using errcode = '42501';
  end if;

  perform public.assert_action_unlocked(
    'manage_registration',
    'tournament'::public.action_lock_scope,
    target_registration.tournament_id::text
  );

  if length(btrim(coalesce(target_reason, ''))) < 5 then
    raise exception 'Desclassificacao exige justificativa com pelo menos 5 caracteres.';
  end if;

  if target_registration.disqualified_at is not null then
    return;
  end if;

  perform set_config('app.registration_disqualification', 'on', true);

  update public.tournament_registrations
  set disqualified_at = now(),
      disqualified_by = auth.uid(),
      disqualification_reason = btrim(target_reason),
      admin_notes = btrim(target_reason),
      updated_at = now()
  where id = target_registration.id;

  perform set_config('app.registration_disqualification', 'off', true);
end;
$$;

revoke all on function public.disqualify_registration(uuid, text) from public;
grant execute on function public.disqualify_registration(uuid, text) to authenticated;

create or replace function public.is_registration_bracket_eligible(
  target_registration_id uuid,
  target_tournament_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tournament_registrations registration
    join public.tournaments tournament
      on tournament.id = registration.tournament_id
    where registration.id = target_registration_id
      and registration.tournament_id = target_tournament_id
      and registration.status in (
        'confirmed'::public.tournament_registration_status,
        'checked_in'::public.tournament_registration_status,
        'registered'::public.tournament_registration_status
      )
      and registration.disqualified_at is null
      and registration.no_show_at is null
      and (
        not tournament.requires_check_in
        or registration.checked_in_at is not null
        or registration.status = 'checked_in'::public.tournament_registration_status
      )
  );
$$;

revoke all on function public.is_registration_bracket_eligible(uuid, uuid) from public;

create or replace function public.validate_bracket_match_participants()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'DELETE' then
    return old;
  end if;

  if current_setting('app.bracket_completion', true) = 'on'
    or current_setting('app.match_result_write', true) = 'on'
  then
    return new;
  end if;

  if new.participant_a_registration_id is not null
    and not public.is_registration_bracket_eligible(
      new.participant_a_registration_id,
      new.tournament_id
    )
  then
    raise exception 'Participante A nao esta elegivel para a chave.';
  end if;

  if new.participant_b_registration_id is not null
    and not public.is_registration_bracket_eligible(
      new.participant_b_registration_id,
      new.tournament_id
    )
  then
    raise exception 'Participante B nao esta elegivel para a chave.';
  end if;

  return new;
end;
$$;

drop trigger if exists bracket_matches_validate_participants
  on public.bracket_matches;
create trigger bracket_matches_validate_participants
  before insert or update on public.bracket_matches
  for each row
  execute function public.validate_bracket_match_participants();

create or replace function public.protect_bracket_match_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('app.bracket_completion', true) = 'on'
    or current_setting('app.match_result_write', true) = 'on'
  then
    return new;
  end if;

  if new.participant_a_registration_id is distinct from old.participant_a_registration_id
    or new.participant_b_registration_id is distinct from old.participant_b_registration_id
    or new.winner_registration_id is distinct from old.winner_registration_id
    or new.score_a is distinct from old.score_a
    or new.score_b is distinct from old.score_b
    or new.status is distinct from old.status
    or new.is_bye is distinct from old.is_bye
    or new.result_notes is distinct from old.result_notes
    or new.submitted_by is distinct from old.submitted_by
    or new.submitted_at is distinct from old.submitted_at
    or new.confirmed_by is distinct from old.confirmed_by
    or new.confirmed_at is distinct from old.confirmed_at
    or new.result_type is distinct from old.result_type
    or new.walkover_reason is distinct from old.walkover_reason
    or new.walkover_by is distinct from old.walkover_by
    or new.walkover_at is distinct from old.walkover_at
  then
    raise exception 'Alteracoes de resultado e avanco da chave devem usar RPC protegida.';
  end if;

  return new;
end;
$$;

create or replace function public.record_bracket_match_result(
  target_match_id uuid,
  target_winner_registration_id uuid,
  target_score_a integer,
  target_score_b integer,
  target_notes text default null,
  target_change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_match public.bracket_matches%rowtype;
  target_result public.match_results%rowtype;
  next_match public.bracket_matches%rowtype;
  is_correction boolean;
  stored_result_id uuid;
  previous_walkover_loser_id uuid;
begin
  select *
  into target_match
  from public.bracket_matches
  where id = target_match_id;

  if target_match.id is null then
    raise exception 'Partida da chave nao encontrada.';
  end if;

  if not public.can_manage_tournament(target_match.tournament_id) then
    raise exception 'Usuario nao pode registrar resultado desta chave.';
  end if;

  if target_match.is_bye or target_match.status = 'bye'::public.bracket_match_status then
    raise exception 'Partida com bye nao recebe resultado manual.';
  end if;

  if target_match.participant_a_registration_id is null
    or target_match.participant_b_registration_id is null
  then
    raise exception 'Partida ainda nao possui dois participantes.';
  end if;

  select *
  into target_result
  from public.match_results
  where match_id = target_match.id;

  is_correction := target_match.status in (
    'completed'::public.bracket_match_status,
    'disputed'::public.bracket_match_status
  )
    or target_result.id is not null;

  if not is_correction
    and target_match.status not in (
      'ready'::public.bracket_match_status,
      'live'::public.bracket_match_status
    )
  then
    raise exception 'Somente partidas prontas ou ao vivo podem receber resultado.';
  end if;

  if is_correction
    and length(btrim(coalesce(target_change_reason, ''))) < 3
  then
    raise exception 'Correcoes de resultado finalizado exigem justificativa.';
  end if;

  if target_winner_registration_id not in (
    target_match.participant_a_registration_id,
    target_match.participant_b_registration_id
  ) then
    raise exception 'Vencedor nao pertence a esta partida.';
  end if;

  if not public.is_registration_bracket_eligible(
    target_winner_registration_id,
    target_match.tournament_id
  ) then
    raise exception 'Vencedor nao esta elegivel para avancar na chave.';
  end if;

  if target_score_a is null
    or target_score_b is null
    or target_score_a < 0
    or target_score_b < 0
    or target_score_a = target_score_b
  then
    raise exception 'Placar invalido para mata-mata simples.';
  end if;

  if target_winner_registration_id = target_match.participant_a_registration_id
    and target_score_a <= target_score_b
  then
    raise exception 'Placar nao confirma o vencedor informado.';
  end if;

  if target_winner_registration_id = target_match.participant_b_registration_id
    and target_score_b <= target_score_a
  then
    raise exception 'Placar nao confirma o vencedor informado.';
  end if;

  if is_correction
    and target_match.winner_registration_id is not null
    and target_match.winner_registration_id is distinct from target_winner_registration_id
    and target_match.next_match_id is not null
  then
    select *
    into next_match
    from public.bracket_matches
    where id = target_match.next_match_id;

    if next_match.status in (
      'completed'::public.bracket_match_status,
      'live'::public.bracket_match_status,
      'disputed'::public.bracket_match_status
    )
      or next_match.winner_registration_id is not null
    then
      raise exception 'Nao e seguro corrigir vencedor porque a proxima partida ja possui resultado ou esta em andamento.';
    end if;
  end if;

  if target_result.result_type = 'walkover' then
    previous_walkover_loser_id := case
      when target_result.winner_registration_id = target_match.participant_a_registration_id
      then target_match.participant_b_registration_id
      else target_match.participant_a_registration_id
    end;

    perform set_config('app.registration_no_show', 'on', true);

    update public.tournament_registrations
    set no_show_at = null,
        no_show_by = null,
        no_show_reason = null,
        updated_at = now()
    where id = previous_walkover_loser_id;

    perform set_config('app.registration_no_show', 'off', true);
  end if;

  perform set_config('app.match_result_write', 'on', true);
  perform set_config('app.bracket_completion', 'on', true);

  insert into public.match_result_history (
    match_id,
    result_id,
    previous_score_a,
    previous_score_b,
    new_score_a,
    new_score_b,
    previous_winner_registration_id,
    new_winner_registration_id,
    previous_status,
    new_status,
    previous_result_type,
    new_result_type,
    changed_by,
    change_reason
  )
  values (
    target_match.id,
    target_result.id,
    target_match.score_a,
    target_match.score_b,
    target_score_a,
    target_score_b,
    target_match.winner_registration_id,
    target_winner_registration_id,
    target_match.status,
    'completed'::public.bracket_match_status,
    target_match.result_type,
    'score',
    auth.uid(),
    coalesce(nullif(target_change_reason, ''), nullif(target_notes, ''), 'Resultado registrado')
  );

  insert into public.match_results (
    match_id,
    bracket_id,
    tournament_id,
    score_a,
    score_b,
    winner_registration_id,
    status,
    result_type,
    notes,
    submitted_by,
    submitted_at,
    confirmed_by,
    confirmed_at,
    disputed_by,
    disputed_at,
    dispute_reason,
    resolved_by,
    resolved_at,
    resolution_notes,
    walkover_reason,
    walkover_by,
    walkover_at
  )
  values (
    target_match.id,
    target_match.bracket_id,
    target_match.tournament_id,
    target_score_a,
    target_score_b,
    target_winner_registration_id,
    'confirmed'::public.match_result_status,
    'score',
    nullif(target_notes, ''),
    auth.uid(),
    now(),
    auth.uid(),
    now(),
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null
  )
  on conflict (match_id) do update
    set score_a = excluded.score_a,
        score_b = excluded.score_b,
        winner_registration_id = excluded.winner_registration_id,
        status = excluded.status,
        result_type = excluded.result_type,
        notes = excluded.notes,
        submitted_by = excluded.submitted_by,
        submitted_at = excluded.submitted_at,
        confirmed_by = excluded.confirmed_by,
        confirmed_at = excluded.confirmed_at,
        disputed_by = null,
        disputed_at = null,
        dispute_reason = null,
        resolved_by = null,
        resolved_at = null,
        resolution_notes = null,
        walkover_reason = null,
        walkover_by = null,
        walkover_at = null,
        updated_at = now()
  returning id into stored_result_id;

  update public.match_result_history
  set result_id = stored_result_id
  where match_id = target_match.id
    and result_id is null
    and changed_by is not distinct from auth.uid()
    and created_at = (
      select max(created_at)
      from public.match_result_history
      where match_id = target_match.id
    );

  update public.bracket_matches
  set status = 'completed'::public.bracket_match_status,
      score_a = target_score_a,
      score_b = target_score_b,
      winner_registration_id = target_winner_registration_id,
      result_type = 'score',
      result_notes = nullif(target_notes, ''),
      submitted_by = auth.uid(),
      submitted_at = now(),
      confirmed_by = auth.uid(),
      confirmed_at = now(),
      walkover_reason = null,
      walkover_by = null,
      walkover_at = null,
      updated_at = now()
  where id = target_match.id;

  if target_match.next_match_id is null then
    update public.tournament_brackets
    set winner_registration_id = target_winner_registration_id,
        updated_at = now()
    where id = target_match.bracket_id;
  elsif target_match.next_match_slot = 'a' then
    update public.bracket_matches
    set participant_a_registration_id = target_winner_registration_id,
        status = case
          when participant_b_registration_id is not null then 'ready'::public.bracket_match_status
          else status
        end,
        updated_at = now()
    where id = target_match.next_match_id;
  elsif target_match.next_match_slot = 'b' then
    update public.bracket_matches
    set participant_b_registration_id = target_winner_registration_id,
        status = case
          when participant_a_registration_id is not null then 'ready'::public.bracket_match_status
          else status
        end,
        updated_at = now()
    where id = target_match.next_match_id;
  else
    raise exception 'Destino do vencedor invalido.';
  end if;

  perform set_config('app.bracket_completion', 'off', true);
  perform set_config('app.match_result_write', 'off', true);
end;
$$;

create or replace function public.record_bracket_match_walkover(
  target_match_id uuid,
  target_winner_registration_id uuid,
  target_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_match public.bracket_matches%rowtype;
  target_result public.match_results%rowtype;
  next_match public.bracket_matches%rowtype;
  is_correction boolean;
  stored_result_id uuid;
  loser_registration_id uuid;
  previous_walkover_loser_id uuid;
begin
  select *
  into target_match
  from public.bracket_matches
  where id = target_match_id;

  if target_match.id is null then
    raise exception 'Partida da chave nao encontrada.';
  end if;

  if not public.can_manage_tournament(target_match.tournament_id) then
    raise exception 'Usuario nao pode registrar W.O. nesta chave.'
      using errcode = '42501';
  end if;

  if length(btrim(coalesce(target_reason, ''))) < 5 then
    raise exception 'W.O. exige justificativa administrativa com pelo menos 5 caracteres.';
  end if;

  if target_match.is_bye or target_match.status = 'bye'::public.bracket_match_status then
    raise exception 'Partida com bye nao recebe W.O.';
  end if;

  if target_match.participant_a_registration_id is null
    or target_match.participant_b_registration_id is null
  then
    raise exception 'Partida ainda nao possui dois participantes.';
  end if;

  if target_winner_registration_id not in (
    target_match.participant_a_registration_id,
    target_match.participant_b_registration_id
  ) then
    raise exception 'Vencedor do W.O. precisa pertencer a esta partida.';
  end if;

  if not public.is_registration_bracket_eligible(
    target_winner_registration_id,
    target_match.tournament_id
  ) then
    raise exception 'Vencedor do W.O. nao esta elegivel para avancar.';
  end if;

  loser_registration_id := case
    when target_winner_registration_id = target_match.participant_a_registration_id
    then target_match.participant_b_registration_id
    else target_match.participant_a_registration_id
  end;

  select *
  into target_result
  from public.match_results
  where match_id = target_match.id;

  is_correction := target_match.status in (
    'completed'::public.bracket_match_status,
    'disputed'::public.bracket_match_status
  )
    or target_result.id is not null;

  if not is_correction
    and target_match.status not in (
      'ready'::public.bracket_match_status,
      'live'::public.bracket_match_status
    )
  then
    raise exception 'Somente partidas prontas ou ao vivo podem receber W.O.';
  end if;

  if is_correction
    and target_match.winner_registration_id is not null
    and target_match.winner_registration_id is distinct from target_winner_registration_id
    and target_match.next_match_id is not null
  then
    select *
    into next_match
    from public.bracket_matches
    where id = target_match.next_match_id;

    if next_match.status in (
      'completed'::public.bracket_match_status,
      'live'::public.bracket_match_status,
      'disputed'::public.bracket_match_status
    )
      or next_match.winner_registration_id is not null
    then
      raise exception 'Nao e seguro corrigir vencedor porque a proxima partida ja possui resultado ou esta em andamento.';
    end if;
  end if;

  if target_result.result_type = 'walkover' then
    previous_walkover_loser_id := case
      when target_result.winner_registration_id = target_match.participant_a_registration_id
      then target_match.participant_b_registration_id
      else target_match.participant_a_registration_id
    end;

    perform set_config('app.registration_no_show', 'on', true);

    update public.tournament_registrations
    set no_show_at = null,
        no_show_by = null,
        no_show_reason = null,
        updated_at = now()
    where id = previous_walkover_loser_id;

    perform set_config('app.registration_no_show', 'off', true);
  end if;

  perform set_config('app.registration_no_show', 'on', true);

  update public.tournament_registrations
  set no_show_at = now(),
      no_show_by = auth.uid(),
      no_show_reason = btrim(target_reason),
      admin_notes = coalesce(admin_notes, btrim(target_reason)),
      updated_at = now()
  where id = loser_registration_id;

  perform set_config('app.registration_no_show', 'off', true);

  perform set_config('app.match_result_write', 'on', true);
  perform set_config('app.bracket_completion', 'on', true);

  insert into public.match_result_history (
    match_id,
    result_id,
    previous_score_a,
    previous_score_b,
    new_score_a,
    new_score_b,
    previous_winner_registration_id,
    new_winner_registration_id,
    previous_status,
    new_status,
    previous_result_type,
    new_result_type,
    changed_by,
    change_reason
  )
  values (
    target_match.id,
    target_result.id,
    target_match.score_a,
    target_match.score_b,
    null,
    null,
    target_match.winner_registration_id,
    target_winner_registration_id,
    target_match.status,
    'completed'::public.bracket_match_status,
    target_match.result_type,
    'walkover',
    auth.uid(),
    btrim(target_reason)
  );

  insert into public.match_results (
    match_id,
    bracket_id,
    tournament_id,
    score_a,
    score_b,
    winner_registration_id,
    status,
    result_type,
    notes,
    submitted_by,
    submitted_at,
    confirmed_by,
    confirmed_at,
    disputed_by,
    disputed_at,
    dispute_reason,
    resolved_by,
    resolved_at,
    resolution_notes,
    walkover_reason,
    walkover_by,
    walkover_at
  )
  values (
    target_match.id,
    target_match.bracket_id,
    target_match.tournament_id,
    0,
    0,
    target_winner_registration_id,
    'confirmed'::public.match_result_status,
    'walkover',
    btrim(target_reason),
    auth.uid(),
    now(),
    auth.uid(),
    now(),
    null,
    null,
    null,
    null,
    null,
    null,
    btrim(target_reason),
    auth.uid(),
    now()
  )
  on conflict (match_id) do update
    set score_a = 0,
        score_b = 0,
        winner_registration_id = excluded.winner_registration_id,
        status = excluded.status,
        result_type = excluded.result_type,
        notes = excluded.notes,
        submitted_by = excluded.submitted_by,
        submitted_at = excluded.submitted_at,
        confirmed_by = excluded.confirmed_by,
        confirmed_at = excluded.confirmed_at,
        disputed_by = null,
        disputed_at = null,
        dispute_reason = null,
        resolved_by = null,
        resolved_at = null,
        resolution_notes = null,
        walkover_reason = excluded.walkover_reason,
        walkover_by = excluded.walkover_by,
        walkover_at = excluded.walkover_at,
        updated_at = now()
  returning id into stored_result_id;

  update public.match_result_history
  set result_id = stored_result_id
  where match_id = target_match.id
    and result_id is null
    and changed_by is not distinct from auth.uid()
    and created_at = (
      select max(created_at)
      from public.match_result_history
      where match_id = target_match.id
    );

  update public.bracket_matches
  set status = 'completed'::public.bracket_match_status,
      score_a = null,
      score_b = null,
      winner_registration_id = target_winner_registration_id,
      result_type = 'walkover',
      result_notes = btrim(target_reason),
      submitted_by = auth.uid(),
      submitted_at = now(),
      confirmed_by = auth.uid(),
      confirmed_at = now(),
      walkover_reason = btrim(target_reason),
      walkover_by = auth.uid(),
      walkover_at = now(),
      updated_at = now()
  where id = target_match.id;

  if target_match.next_match_id is null then
    update public.tournament_brackets
    set winner_registration_id = target_winner_registration_id,
        updated_at = now()
    where id = target_match.bracket_id;
  elsif target_match.next_match_slot = 'a' then
    update public.bracket_matches
    set participant_a_registration_id = target_winner_registration_id,
        status = case
          when participant_b_registration_id is not null then 'ready'::public.bracket_match_status
          else status
        end,
        updated_at = now()
    where id = target_match.next_match_id;
  elsif target_match.next_match_slot = 'b' then
    update public.bracket_matches
    set participant_b_registration_id = target_winner_registration_id,
        status = case
          when participant_a_registration_id is not null then 'ready'::public.bracket_match_status
          else status
        end,
        updated_at = now()
    where id = target_match.next_match_id;
  else
    raise exception 'Destino do vencedor invalido.';
  end if;

  perform set_config('app.bracket_completion', 'off', true);
  perform set_config('app.match_result_write', 'off', true);
end;
$$;

comment on function public.record_bracket_match_walkover(uuid, uuid, text) is
  'Registra W.O. com justificativa, marca no-show do perdedor, audita via match_results e avanca vencedor.';

revoke all on function public.record_bracket_match_walkover(uuid, uuid, text) from public;
grant execute on function public.record_bracket_match_walkover(uuid, uuid, text) to authenticated;

create or replace function public.contest_match_result(
  target_match_id uuid,
  target_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_match public.bracket_matches%rowtype;
  target_result public.match_results%rowtype;
begin
  select *
  into target_match
  from public.bracket_matches
  where id = target_match_id;

  if target_match.id is null then
    raise exception 'Partida da chave nao encontrada.';
  end if;

  if not public.is_match_participant(target_match.id) then
    raise exception 'Somente participante da partida pode contestar o resultado.';
  end if;

  if target_match.status <> 'completed'::public.bracket_match_status then
    raise exception 'Somente resultado finalizado pode ser contestado.';
  end if;

  if length(btrim(coalesce(target_reason, ''))) < 5 then
    raise exception 'Informe motivo da contestacao com pelo menos 5 caracteres.';
  end if;

  select *
  into target_result
  from public.match_results
  where match_id = target_match.id;

  if target_result.id is null then
    raise exception 'Resultado da partida nao encontrado.';
  end if;

  perform set_config('app.match_result_write', 'on', true);
  perform set_config('app.bracket_completion', 'on', true);

  update public.match_results
  set status = 'disputed'::public.match_result_status,
      disputed_by = auth.uid(),
      disputed_at = now(),
      dispute_reason = btrim(target_reason),
      updated_at = now()
  where id = target_result.id;

  insert into public.match_result_history (
    match_id,
    result_id,
    previous_score_a,
    previous_score_b,
    new_score_a,
    new_score_b,
    previous_winner_registration_id,
    new_winner_registration_id,
    previous_status,
    new_status,
    previous_result_type,
    new_result_type,
    changed_by,
    change_reason
  )
  values (
    target_match.id,
    target_result.id,
    target_match.score_a,
    target_match.score_b,
    target_match.score_a,
    target_match.score_b,
    target_match.winner_registration_id,
    target_match.winner_registration_id,
    target_match.status,
    'disputed'::public.bracket_match_status,
    target_match.result_type,
    target_match.result_type,
    auth.uid(),
    btrim(target_reason)
  );

  update public.bracket_matches
  set status = 'disputed'::public.bracket_match_status,
      updated_at = now()
  where id = target_match.id;

  perform set_config('app.bracket_completion', 'off', true);
  perform set_config('app.match_result_write', 'off', true);
end;
$$;

revoke all on function public.contest_match_result(uuid, text) from public;
grant execute on function public.contest_match_result(uuid, text) to authenticated;

create or replace function public.resolve_match_dispute(
  target_match_id uuid,
  target_resolution_action text default 'confirm',
  target_resolution_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_match public.bracket_matches%rowtype;
  target_result public.match_results%rowtype;
  next_match public.bracket_matches%rowtype;
  walkover_loser_id uuid;
begin
  select *
  into target_match
  from public.bracket_matches
  where id = target_match_id;

  if target_match.id is null then
    raise exception 'Partida da chave nao encontrada.';
  end if;

  if not public.can_manage_tournament(target_match.tournament_id) then
    raise exception 'Usuario nao pode resolver contestacao desta chave.';
  end if;

  select *
  into target_result
  from public.match_results
  where match_id = target_match.id;

  if target_result.id is null
    or target_result.status <> 'disputed'::public.match_result_status
  then
    raise exception 'Nao ha contestacao aberta para esta partida.';
  end if;

  if target_resolution_action not in ('confirm', 'cancel') then
    raise exception 'Acao de resolucao invalida. Use confirm ou cancel.';
  end if;

  if length(btrim(coalesce(target_resolution_notes, ''))) < 3 then
    raise exception 'Resolucao de contestacao exige observacao.';
  end if;

  if target_resolution_action = 'cancel'
    and target_match.next_match_id is not null
  then
    select *
    into next_match
    from public.bracket_matches
    where id = target_match.next_match_id;

    if next_match.status in (
      'completed'::public.bracket_match_status,
      'live'::public.bracket_match_status,
      'disputed'::public.bracket_match_status
    )
      or next_match.winner_registration_id is not null
    then
      raise exception 'Nao e seguro cancelar resultado porque a proxima partida ja possui resultado ou esta em andamento.';
    end if;
  end if;

  perform set_config('app.match_result_write', 'on', true);
  perform set_config('app.bracket_completion', 'on', true);

  if target_resolution_action = 'confirm' then
    update public.match_results
    set status = 'resolved'::public.match_result_status,
        resolved_by = auth.uid(),
        resolved_at = now(),
        resolution_notes = btrim(target_resolution_notes),
        updated_at = now()
    where id = target_result.id;

    insert into public.match_result_history (
      match_id,
      result_id,
      previous_score_a,
      previous_score_b,
      new_score_a,
      new_score_b,
      previous_winner_registration_id,
      new_winner_registration_id,
      previous_status,
      new_status,
      previous_result_type,
      new_result_type,
      changed_by,
      change_reason
    )
    values (
      target_match.id,
      target_result.id,
      target_match.score_a,
      target_match.score_b,
      target_match.score_a,
      target_match.score_b,
      target_match.winner_registration_id,
      target_match.winner_registration_id,
      target_match.status,
      'completed'::public.bracket_match_status,
      target_match.result_type,
      target_match.result_type,
      auth.uid(),
      btrim(target_resolution_notes)
    );

    update public.bracket_matches
    set status = 'completed'::public.bracket_match_status,
        updated_at = now()
    where id = target_match.id;
  else
    update public.match_results
    set status = 'cancelled'::public.match_result_status,
        resolved_by = auth.uid(),
        resolved_at = now(),
        resolution_notes = btrim(target_resolution_notes),
        updated_at = now()
    where id = target_result.id;

    insert into public.match_result_history (
      match_id,
      result_id,
      previous_score_a,
      previous_score_b,
      new_score_a,
      new_score_b,
      previous_winner_registration_id,
      new_winner_registration_id,
      previous_status,
      new_status,
      previous_result_type,
      new_result_type,
      changed_by,
      change_reason
    )
    values (
      target_match.id,
      target_result.id,
      target_match.score_a,
      target_match.score_b,
      null,
      null,
      target_match.winner_registration_id,
      null,
      target_match.status,
      'ready'::public.bracket_match_status,
      target_match.result_type,
      'score',
      auth.uid(),
      btrim(target_resolution_notes)
    );

    if target_result.result_type = 'walkover' then
      walkover_loser_id := case
        when target_result.winner_registration_id = target_match.participant_a_registration_id
        then target_match.participant_b_registration_id
        else target_match.participant_a_registration_id
      end;

      perform set_config('app.registration_no_show', 'on', true);

      update public.tournament_registrations
      set no_show_at = null,
          no_show_by = null,
          no_show_reason = null,
          updated_at = now()
      where id = walkover_loser_id;

      perform set_config('app.registration_no_show', 'off', true);
    end if;

    if target_match.next_match_id is not null and target_match.next_match_slot = 'a' then
      update public.bracket_matches
      set participant_a_registration_id = null,
          status = case
            when participant_b_registration_id is null then 'pending'::public.bracket_match_status
            else status
          end,
          updated_at = now()
      where id = target_match.next_match_id;
    elsif target_match.next_match_id is not null and target_match.next_match_slot = 'b' then
      update public.bracket_matches
      set participant_b_registration_id = null,
          status = case
            when participant_a_registration_id is null then 'pending'::public.bracket_match_status
            else status
          end,
          updated_at = now()
      where id = target_match.next_match_id;
    end if;

    update public.bracket_matches
    set status = 'ready'::public.bracket_match_status,
        score_a = null,
        score_b = null,
        winner_registration_id = null,
        result_type = 'score',
        result_notes = null,
        submitted_by = null,
        submitted_at = null,
        confirmed_by = null,
        confirmed_at = null,
        walkover_reason = null,
        walkover_by = null,
        walkover_at = null,
        updated_at = now()
    where id = target_match.id;
  end if;

  perform set_config('app.bracket_completion', 'off', true);
  perform set_config('app.match_result_write', 'off', true);
end;
$$;

revoke all on function public.resolve_match_dispute(uuid, text, text) from public;
grant execute on function public.resolve_match_dispute(uuid, text, text) to authenticated;

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

  if new.checked_in_at is distinct from old.checked_in_at
    or new.checked_in_by is distinct from old.checked_in_by
  then
    perform public.write_audit_log(
      case
        when new.checked_in_at is null then 'registration_check_in_revoked'
        else 'registration_checked_in'
      end,
      'tournament_registration',
      new.id::text,
      new.tournament_id,
      jsonb_build_object(
        'status', old.status,
        'checked_in_at', old.checked_in_at,
        'checked_in_by', old.checked_in_by
      ),
      jsonb_build_object(
        'status', new.status,
        'checked_in_at', new.checked_in_at,
        'checked_in_by', new.checked_in_by
      ),
      new.check_in_notes
    );
  end if;

  if new.disqualified_at is distinct from old.disqualified_at then
    perform public.write_audit_log(
      'registration_disqualified',
      'tournament_registration',
      new.id::text,
      new.tournament_id,
      to_jsonb(old),
      to_jsonb(new),
      new.disqualification_reason
    );
  end if;

  if new.no_show_at is distinct from old.no_show_at then
    perform public.write_audit_log(
      case
        when new.no_show_at is null then 'registration_no_show_cleared'
        else 'registration_no_show_marked'
      end,
      'tournament_registration',
      new.id::text,
      new.tournament_id,
      jsonb_build_object(
        'no_show_at', old.no_show_at,
        'no_show_by', old.no_show_by,
        'no_show_reason', old.no_show_reason
      ),
      jsonb_build_object(
        'no_show_at', new.no_show_at,
        'no_show_by', new.no_show_by,
        'no_show_reason', new.no_show_reason
      ),
      coalesce(new.no_show_reason, old.no_show_reason)
    );
  end if;

  if new.status is distinct from old.status
    and not (
      new.status = 'checked_in'::public.tournament_registration_status
      or old.status = 'checked_in'::public.tournament_registration_status
    )
  then
    audit_action := case new.status
      when 'confirmed' then 'registration_confirmed'
      when 'rejected' then 'registration_rejected'
      when 'cancelled' then 'registration_cancelled'
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

