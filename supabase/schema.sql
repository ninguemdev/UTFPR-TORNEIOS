-- UTFPR Torneios - schema inicial Supabase
-- Objetivo:
-- - Usar Supabase Auth como origem dos usuários.
-- - Não criar tabela de senhas.
-- - Criar perfis, papéis e pedidos de permissão para criação de torneios.
-- - Habilitar Row Level Security em todas as tabelas deste schema inicial.
-- - Validar permissões no banco, não apenas na interface.
--
-- Importante:
-- - Nunca use service_role no front-end.
-- - Use apenas VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY no cliente.
-- - O primeiro admin deve ser promovido com cuidado pelo SQL Editor, conforme README/final da tarefa.

create extension if not exists pgcrypto with schema extensions;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'user_role'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.user_role as enum ('admin', 'user');
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'registration_type'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.registration_type as enum (
      'individual',
      'team'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'request_status'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.request_status as enum (
      'pending',
      'approved',
      'rejected',
      'cancelled'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'creator_permission_status'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.creator_permission_status as enum (
      'active',
      'revoked'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'team_status'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.team_status as enum (
      'draft',
      'pending',
      'confirmed',
      'cancelled',
      'rejected'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'team_member_role'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.team_member_role as enum (
      'captain',
      'member'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'team_member_status'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.team_member_status as enum (
      'active',
      'removed'
    );
  end if;
end
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text not null default 'Usuário UTFPR',
  ra text,
  avatar_key text not null default 'avatar_utfpr_blue',
  role public.user_role not null default 'user',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_not_blank check (length(btrim(display_name)) > 0),
  constraint profiles_avatar_key_allowed check (
    avatar_key in (
      'avatar_utfpr_blue',
      'avatar_utfpr_green',
      'avatar_utfpr_gold',
      'avatar_competition',
      'avatar_academic'
    )
  )
);

comment on table public.profiles is
  'Perfil público/administrativo vinculado a auth.users. Não armazena senha.';
comment on column public.profiles.id is
  'Mesmo UUID do usuário em auth.users.';
comment on column public.profiles.email is
  'Cópia auxiliar do email do auth.users para exibição administrativa; proteger por RLS.';
comment on column public.profiles.ra is
  'Registro acadêmico. Dado pessoal, não deve ser exposto publicamente sem necessidade.';
comment on column public.profiles.avatar_key is
  'Avatar pré-definido do MVP. Upload de foto não faz parte do escopo inicial.';
comment on column public.profiles.role is
  'Papel global. Usuário comum nunca pode promover a si mesmo para admin.';

create table if not exists public.tournament_creator_requests (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  status public.request_status not null default 'pending',
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tournament_creator_requests_reason_not_blank check (length(btrim(reason)) > 0),
  constraint tournament_creator_requests_review_consistency check (
    (
      status in ('approved', 'rejected')
      and reviewed_by is not null
      and reviewed_at is not null
    )
    or (
      status in ('pending', 'cancelled')
      and reviewed_at is null
    )
  )
);

comment on table public.tournament_creator_requests is
  'Pedidos de usuários comuns para receber permissão de criar torneios.';
comment on column public.tournament_creator_requests.user_id is
  'Usuário que pediu autorização para criar torneios.';
comment on column public.tournament_creator_requests.status is
  'Fluxo do pedido: pending, approved, rejected ou cancelled.';
comment on column public.tournament_creator_requests.reviewed_by is
  'Admin que aprovou ou rejeitou o pedido.';
comment on column public.tournament_creator_requests.admin_notes is
  'Observações administrativas visíveis apenas para admins por RLS.';

create unique index if not exists tournament_creator_requests_one_pending_per_user
  on public.tournament_creator_requests (user_id)
  where status = 'pending';

create index if not exists profiles_role_idx
  on public.profiles (role);

create index if not exists tournament_creator_requests_user_status_idx
  on public.tournament_creator_requests (user_id, status);

create table if not exists public.tournament_creator_permissions (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status public.creator_permission_status not null default 'active',
  granted_by uuid not null references public.profiles(id) on delete restrict,
  granted_at timestamptz not null default now(),
  revoked_by uuid references public.profiles(id) on delete set null,
  revoked_at timestamptz,
  grant_reason text,
  revoke_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tournament_creator_permissions_status_consistency check (
    (
      status = 'active'::public.creator_permission_status
      and revoked_by is null
      and revoked_at is null
    )
    or (
      status = 'revoked'::public.creator_permission_status
      and revoked_by is not null
      and revoked_at is not null
    )
  )
);

comment on table public.tournament_creator_permissions is
  'Permissoes efetivas para criar torneios. Pedidos ficam como historico; esta tabela controla autorizacao ativa ou revogada.';
comment on column public.tournament_creator_permissions.user_id is
  'Usuario que recebeu permissao de criador de torneios.';
comment on column public.tournament_creator_permissions.status is
  'active permite criar torneios; revoked bloqueia novas criacoes sem apagar historico.';
comment on column public.tournament_creator_permissions.granted_by is
  'Admin que concedeu a permissao.';
comment on column public.tournament_creator_permissions.revoked_by is
  'Admin que revogou a permissao.';

create unique index if not exists tournament_creator_permissions_one_active_per_user
  on public.tournament_creator_permissions (user_id)
  where status = 'active';

create index if not exists tournament_creator_permissions_user_status_idx
  on public.tournament_creator_permissions (user_id, status);

-- Migra pedidos ja aprovados para permissoes ativas sem apagar historico.
-- Se o schema for executado mais de uma vez, a condicao evita duplicar permissao ativa.
select set_config('app.permission_backfill', 'on', true);

insert into public.tournament_creator_permissions (
  user_id,
  status,
  granted_by,
  granted_at,
  grant_reason,
  created_at,
  updated_at
)
select
  request.user_id,
  'active'::public.creator_permission_status,
  request.reviewed_by,
  coalesce(request.reviewed_at, request.updated_at, request.created_at, now()),
  coalesce(request.admin_notes, request.reason),
  now(),
  now()
from public.tournament_creator_requests request
where request.status = 'approved'::public.request_status
  and request.reviewed_by is not null
  and not exists (
    select 1
    from public.tournament_creator_permissions permission
    where permission.user_id = request.user_id
      and permission.status = 'active'::public.creator_permission_status
  );

select set_config('app.permission_backfill', 'off', true);

-- Função auxiliar para updated_at.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Verifica se o usuário autenticado atual é admin.
-- Esta função é SECURITY DEFINER para evitar recursão em RLS:
-- as policies chamam is_admin(), e is_admin() consulta profiles sem cair
-- novamente nas próprias policies de profiles.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'::public.user_role
  );
$$;

comment on function public.is_admin() is
  'Retorna true quando auth.uid() pertence a um profile admin. SECURITY DEFINER evita recursão de RLS.';

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- Verifica se o usuário pode criar torneios.
-- Decisão de modelagem: no MVP a permissão de organizador é derivada de
-- permissão ativa em tournament_creator_permissions. Isso evita confundir
-- organizador aprovado com admin global e permite revogar acesso sem apagar
-- o histórico de pedidos e permissões.
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
      and exists (
        select 1
        from public.tournament_creator_permissions
        where user_id = target_user_id
          and status = 'active'::public.creator_permission_status
      )
    );
$$;

comment on function public.can_create_tournament(uuid) is
  'Retorna true para admin global ou usuário com permissão active. Não altera role.';

revoke all on function public.can_create_tournament(uuid) from public;
grant execute on function public.can_create_tournament(uuid) to authenticated;

-- Alias temporario para compatibilidade com codigo/policies antigos.
create or replace function public.can_create_tournaments(target_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.can_create_tournament(target_user_id);
$$;

comment on function public.can_create_tournaments(uuid) is
  'Alias de compatibilidade. Use public.can_create_tournament(uuid).';

revoke all on function public.can_create_tournaments(uuid) from public;
grant execute on function public.can_create_tournaments(uuid) to authenticated;

-- Protege campos sensíveis do profile.
-- Usuários comuns podem atualizar dados próprios de perfil, mas não role nem email.
-- Admins podem alterar profiles, inclusive role, desde que passem pelas policies.
create or replace function public.protect_profile_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('app.bootstrap_first_admin', true) = 'on' then
    return new;
  end if;

  if new.id is distinct from old.id then
    raise exception 'O id do profile não pode ser alterado.';
  end if;

  if not public.is_admin() then
    if new.role is distinct from old.role then
      raise exception 'Usuário comum não pode alterar role.';
    end if;

    if new.email is distinct from old.email then
      raise exception 'Usuário comum não pode alterar email pelo profile.';
    end if;

    if new.created_at is distinct from old.created_at then
      raise exception 'created_at não pode ser alterado.';
    end if;
  end if;

  return new;
end;
$$;

-- Cria profile automaticamente quando Supabase Auth cria um usuário.
-- A origem do usuário continua sendo auth.users; esta tabela só guarda dados
-- de perfil e autorização da aplicação.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_avatar text;
begin
  requested_avatar := new.raw_user_meta_data ->> 'avatar_key';

  insert into public.profiles (
    id,
    email,
    display_name,
    ra,
    avatar_key,
    role
  )
  values (
    new.id,
    new.email,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      nullif(split_part(new.email, '@', 1), ''),
      'Usuário UTFPR'
    ),
    nullif(new.raw_user_meta_data ->> 'ra', ''),
    case
      when requested_avatar in (
        'avatar_utfpr_blue',
        'avatar_utfpr_green',
        'avatar_utfpr_gold',
        'avatar_competition',
        'avatar_academic'
      )
      then requested_avatar
      else 'avatar_utfpr_blue'
    end,
    'user'
  )
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();

  return new;
end;
$$;

-- Valida transições dos pedidos.
-- Usuário comum só pode cancelar seu próprio pedido pendente.
-- Admin pode aprovar/rejeitar pedido pendente e precisa ficar registrado.
create or replace function public.validate_tournament_creator_request_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_admin() then
    if old.status <> 'pending' and new.status is distinct from old.status then
      raise exception 'Somente pedidos pendentes podem mudar de status.';
    end if;

    if new.status in ('approved', 'rejected') then
      new.reviewed_by := coalesce(new.reviewed_by, auth.uid());
      new.reviewed_at := coalesce(new.reviewed_at, now());
    end if;

    if new.status = 'approved'::public.request_status
      and old.status <> 'approved'::public.request_status
    then
      insert into public.tournament_creator_permissions (
        user_id,
        status,
        granted_by,
        granted_at,
        grant_reason
      )
      select
        new.user_id,
        'active'::public.creator_permission_status,
        auth.uid(),
        now(),
        coalesce(nullif(new.admin_notes, ''), new.reason)
      where not exists (
        select 1
        from public.tournament_creator_permissions permission
        where permission.user_id = new.user_id
          and permission.status = 'active'::public.creator_permission_status
      );
    end if;

    return new;
  end if;

  if old.user_id <> auth.uid() then
    raise exception 'Usuário comum só pode alterar o próprio pedido.';
  end if;

  if old.status <> 'pending' or new.status <> 'cancelled' then
    raise exception 'Usuário comum só pode cancelar pedido pendente.';
  end if;

  if new.user_id is distinct from old.user_id
    or new.reason is distinct from old.reason
    or new.reviewed_by is distinct from old.reviewed_by
    or new.reviewed_at is distinct from old.reviewed_at
    or new.admin_notes is distinct from old.admin_notes
  then
    raise exception 'Usuário comum não pode alterar campos administrativos do pedido.';
  end if;

  return new;
end;
$$;

-- Valida escrita em permissoes efetivas.
-- Usuario comum nao consegue criar, revogar, reativar nem editar permissao.
-- Reativacao preservando historico deve criar nova permissao ativa, nao
-- sobrescrever uma linha revogada.
create or replace function public.validate_tournament_creator_permission_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('app.permission_backfill', true) = 'on' then
    return new;
  end if;

  if not public.is_admin() then
    raise exception 'Apenas admins podem alterar permissoes de criador de torneios.';
  end if;

  if TG_OP = 'UPDATE' then
    if new.id is distinct from old.id
      or new.user_id is distinct from old.user_id
      or new.granted_by is distinct from old.granted_by
      or new.granted_at is distinct from old.granted_at
      or new.grant_reason is distinct from old.grant_reason
      or new.created_at is distinct from old.created_at
    then
      raise exception 'Campos historicos da permissao nao podem ser alterados.';
    end if;

    if old.status = 'revoked'::public.creator_permission_status
      and new.status = 'active'::public.creator_permission_status
    then
      raise exception 'Para reativar, crie uma nova permissao ativa e mantenha a permissao revogada como historico.';
    end if;
  end if;

  if new.status = 'active'::public.creator_permission_status then
    new.revoked_by := null;
    new.revoked_at := null;
    new.revoke_reason := null;
  end if;

  if new.status = 'revoked'::public.creator_permission_status then
    new.revoked_by := coalesce(new.revoked_by, auth.uid());
    new.revoked_at := coalesce(new.revoked_at, now());
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

drop trigger if exists profiles_protect_update on public.profiles;
create trigger profiles_protect_update
  before update on public.profiles
  for each row
  execute function public.protect_profile_update();

drop trigger if exists tournament_creator_requests_set_updated_at
  on public.tournament_creator_requests;
create trigger tournament_creator_requests_set_updated_at
  before update on public.tournament_creator_requests
  for each row
  execute function public.set_updated_at();

drop trigger if exists tournament_creator_requests_validate_update
  on public.tournament_creator_requests;
create trigger tournament_creator_requests_validate_update
  before update on public.tournament_creator_requests
  for each row
  execute function public.validate_tournament_creator_request_update();

drop trigger if exists tournament_creator_permissions_set_updated_at
  on public.tournament_creator_permissions;
create trigger tournament_creator_permissions_set_updated_at
  before update on public.tournament_creator_permissions
  for each row
  execute function public.set_updated_at();

drop trigger if exists tournament_creator_permissions_validate_write
  on public.tournament_creator_permissions;
create trigger tournament_creator_permissions_validate_write
  before insert or update on public.tournament_creator_permissions
  for each row
  execute function public.validate_tournament_creator_permission_write();

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_auth_user();

-- Função de bootstrap do primeiro admin.
-- Não recebe grant para anon/authenticated: deve ser executada manualmente no
-- SQL Editor por alguém com acesso administrativo ao projeto Supabase.
create or replace function public.bootstrap_first_admin(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target_user_id is null then
    raise exception 'target_user_id é obrigatório.';
  end if;

  if exists (
    select 1
    from public.profiles
    where role = 'admin'::public.user_role
  ) then
    raise exception 'Já existe ao menos um admin. Use uma conta admin para promover outros usuários.';
  end if;

  perform set_config('app.bootstrap_first_admin', 'on', true);

  update public.profiles
  set role = 'admin',
      updated_at = now()
  where id = target_user_id;

  if not found then
    raise exception 'Profile % não encontrado.', target_user_id;
  end if;

  perform set_config('app.bootstrap_first_admin', 'off', true);
end;
$$;

comment on function public.bootstrap_first_admin(uuid) is
  'Promove exatamente o primeiro admin. Executar manualmente no SQL Editor; não expor ao front-end.';

revoke all on function public.bootstrap_first_admin(uuid) from public;

alter table public.profiles enable row level security;
alter table public.tournament_creator_requests enable row level security;
alter table public.tournament_creator_permissions enable row level security;

-- Grants mínimos para uso via Supabase client.
-- RLS continua sendo a barreira real de segurança.
grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update on public.tournament_creator_requests to authenticated;
grant select, insert, update on public.tournament_creator_permissions to authenticated;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_select_admin" on public.profiles;
drop policy if exists "profiles_update_own_without_role" on public.profiles;
drop policy if exists "profiles_update_admin" on public.profiles;

-- Usuários autenticados podem ler apenas o próprio profile.
create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid());

comment on policy "profiles_select_own" on public.profiles is
  'Permite ao usuário autenticado ler apenas o próprio profile.';

-- Admins podem ler todos os profiles.
-- Usa is_admin() SECURITY DEFINER para evitar recursão em RLS.
create policy "profiles_select_admin"
  on public.profiles
  for select
  to authenticated
  using (public.is_admin());

comment on policy "profiles_select_admin" on public.profiles is
  'Permite que admins leiam todos os profiles. is_admin() evita recursão em RLS.';

-- Usuários podem atualizar apenas o próprio profile.
-- O trigger protect_profile_update impede alteração de role/email por usuário comum.
create policy "profiles_update_own_without_role"
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

comment on policy "profiles_update_own_without_role" on public.profiles is
  'Permite atualizar o próprio profile; trigger bloqueia role/email para usuário comum.';

-- Admins podem atualizar profiles.
create policy "profiles_update_admin"
  on public.profiles
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

comment on policy "profiles_update_admin" on public.profiles is
  'Permite que admins atualizem profiles, inclusive role, sem permitir autopromoção de usuários comuns.';

drop policy if exists "requests_insert_own" on public.tournament_creator_requests;
drop policy if exists "requests_select_own" on public.tournament_creator_requests;
drop policy if exists "requests_select_admin" on public.tournament_creator_requests;
drop policy if exists "requests_cancel_own_pending" on public.tournament_creator_requests;
drop policy if exists "requests_review_admin" on public.tournament_creator_requests;

-- Usuários podem criar o próprio pedido de permissão.
create policy "requests_insert_own"
  on public.tournament_creator_requests
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and status = 'pending'::public.request_status
    and reviewed_by is null
    and reviewed_at is null
    and admin_notes is null
  );

comment on policy "requests_insert_own" on public.tournament_creator_requests is
  'Permite que usuário autenticado crie apenas pedido próprio e pendente.';

-- Usuários podem ver os próprios pedidos.
create policy "requests_select_own"
  on public.tournament_creator_requests
  for select
  to authenticated
  using (user_id = auth.uid());

comment on policy "requests_select_own" on public.tournament_creator_requests is
  'Permite que usuário veja o histórico dos próprios pedidos.';

-- Admins podem ver todos os pedidos.
create policy "requests_select_admin"
  on public.tournament_creator_requests
  for select
  to authenticated
  using (public.is_admin());

comment on policy "requests_select_admin" on public.tournament_creator_requests is
  'Permite que admins acompanhem todos os pedidos de permissão.';

-- Usuários podem cancelar apenas os próprios pedidos pendentes.
-- O trigger validate_tournament_creator_request_update impede alteração de campos administrativos.
create policy "requests_cancel_own_pending"
  on public.tournament_creator_requests
  for update
  to authenticated
  using (
    user_id = auth.uid()
    and status = 'pending'::public.request_status
  )
  with check (
    user_id = auth.uid()
    and status = 'cancelled'::public.request_status
  );

comment on policy "requests_cancel_own_pending" on public.tournament_creator_requests is
  'Permite ao usuário cancelar somente pedido próprio em pending.';

-- Admins podem aprovar ou rejeitar pedidos.
-- O trigger registra reviewed_by/reviewed_at quando necessário.
create policy "requests_review_admin"
  on public.tournament_creator_requests
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

comment on policy "requests_review_admin" on public.tournament_creator_requests is
  'Permite que admins aprovem/rejeitem pedidos. Usuários comuns não conseguem virar admin por esta tabela.';

drop policy if exists "creator_permissions_select_own" on public.tournament_creator_permissions;
drop policy if exists "creator_permissions_select_admin" on public.tournament_creator_permissions;
drop policy if exists "creator_permissions_insert_admin" on public.tournament_creator_permissions;
drop policy if exists "creator_permissions_update_admin" on public.tournament_creator_permissions;

-- Usuarios autenticados podem ver apenas a propria situacao de permissao.
create policy "creator_permissions_select_own"
  on public.tournament_creator_permissions
  for select
  to authenticated
  using (user_id = auth.uid());

comment on policy "creator_permissions_select_own" on public.tournament_creator_permissions is
  'Permite que usuario veja apenas permissoes proprias, inclusive revoked.';

-- Admins podem auditar todas as permissoes.
create policy "creator_permissions_select_admin"
  on public.tournament_creator_permissions
  for select
  to authenticated
  using (public.is_admin());

comment on policy "creator_permissions_select_admin" on public.tournament_creator_permissions is
  'Permite que admins vejam permissoes ativas e revogadas de todos os usuarios.';

-- Apenas admins podem conceder permissao ativa.
create policy "creator_permissions_insert_admin"
  on public.tournament_creator_permissions
  for insert
  to authenticated
  with check (
    public.is_admin()
    and status = 'active'::public.creator_permission_status
    and granted_by = auth.uid()
    and revoked_by is null
    and revoked_at is null
  );

comment on policy "creator_permissions_insert_admin" on public.tournament_creator_permissions is
  'Bloqueia criacao de permissao por usuario comum e exige admin como concedente.';

-- Apenas admins podem revogar. A trigger impede sobrescrever historico revogado.
create policy "creator_permissions_update_admin"
  on public.tournament_creator_permissions
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

comment on policy "creator_permissions_update_admin" on public.tournament_creator_permissions is
  'Permite revogacao por admin; usuarios comuns nao alteram status da permissao.';

-- ---------------------------------------------------------------------------
-- Módulo inicial de torneios e inscrições
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'tournament_status'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.tournament_status as enum (
      'draft',
      'registrations_open',
      'registrations_closed',
      'ongoing',
      'finished',
      'cancelled'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'tournament_registration_status'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.tournament_registration_status as enum (
      'pending',
      'confirmed',
      'cancelled',
      'rejected',
      'checked_in',
      'registered'
    );
  end if;
end
$$;

alter type public.tournament_registration_status add value if not exists 'pending';
alter type public.tournament_registration_status add value if not exists 'confirmed';
alter type public.tournament_registration_status add value if not exists 'rejected';
alter type public.tournament_registration_status add value if not exists 'checked_in';

create table if not exists public.tournaments (
  id uuid primary key default extensions.gen_random_uuid(),
  name text not null,
  slug text not null unique,
  modality text not null,
  description text,
  campus text,
  format text not null default 'single_elimination',
  status public.tournament_status not null default 'draft',
  max_participants integer not null default 16,
  registration_type public.registration_type not null default 'individual',
  team_min_size integer not null default 1,
  team_max_size integer not null default 1,
  allow_free_agents boolean not null default false,
  require_full_team_before_registration boolean not null default true,
  team_registration_deadline timestamptz,
  starts_at date,
  ends_at date,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tournaments_name_not_blank check (length(btrim(name)) > 0),
  constraint tournaments_slug_not_blank check (length(btrim(slug)) > 0),
  constraint tournaments_modality_not_blank check (length(btrim(modality)) > 0),
  constraint tournaments_max_participants_positive check (max_participants > 0),
  constraint tournaments_team_size_positive check (
    team_min_size > 0
    and team_max_size >= team_min_size
  ),
  constraint tournaments_dates_order check (
    ends_at is null
    or starts_at is null
    or ends_at >= starts_at
  )
);

comment on table public.tournaments is
  'Torneios do sistema. Drafts são privados para admin/criador; demais status podem ser visualizados publicamente.';
comment on column public.tournaments.created_by is
  'Profile que criou o torneio. Usuário aprovado só pode editar torneios criados por ele.';
comment on column public.tournaments.status is
  'Status operacional do torneio: draft, registrations_open, registrations_closed, ongoing, finished ou cancelled.';

alter table public.tournaments
  add column if not exists registration_type public.registration_type not null default 'individual';

alter table public.tournaments
  add column if not exists team_min_size integer not null default 1;

alter table public.tournaments
  add column if not exists team_max_size integer not null default 1;

alter table public.tournaments
  add column if not exists allow_free_agents boolean not null default false;

alter table public.tournaments
  add column if not exists require_full_team_before_registration boolean not null default true;

alter table public.tournaments
  add column if not exists team_registration_deadline timestamptz;

comment on column public.tournaments.registration_type is
  'Tipo de inscrição do torneio: individual no MVP ou team para preparação do módulo de equipes.';
comment on column public.tournaments.team_min_size is
  'Tamanho mínimo de equipe para torneios por equipe. Em torneios individuais permanece 1.';
comment on column public.tournaments.team_max_size is
  'Tamanho máximo de equipe para torneios por equipe. Em torneios individuais permanece 1.';
comment on column public.tournaments.allow_free_agents is
  'Permite jogadores sem equipe entrarem em lista futura de agentes livres. Não implementado no MVP.';
comment on column public.tournaments.require_full_team_before_registration is
  'Quando true, equipe precisa atingir team_min_size antes de enviar inscrição.';
comment on column public.tournaments.team_registration_deadline is
  'Prazo opcional para criação/ajuste de equipes, além do status do torneio.';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'tournaments_team_size_positive'
      and conrelid = 'public.tournaments'::regclass
  ) then
    alter table public.tournaments
      add constraint tournaments_team_size_positive check (
        team_min_size > 0
        and team_max_size >= team_min_size
      );
  end if;
end
$$;

create table if not exists public.tournament_registrations (
  id uuid primary key default extensions.gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  team_id uuid,
  display_name text not null,
  status public.tournament_registration_status not null default 'pending',
  registration_type public.registration_type not null default 'individual',
  captain_user_id uuid references public.profiles(id) on delete set null,
  admin_notes text,
  decided_by uuid references public.profiles(id) on delete set null,
  decided_at timestamptz,
  cancelled_by uuid references public.profiles(id) on delete set null,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tournament_registrations_display_name_not_blank check (length(btrim(display_name)) > 0),
  constraint tournament_registrations_decision_consistency check (
    (
      status in ('confirmed', 'rejected', 'checked_in')
      and decided_by is not null
      and decided_at is not null
    )
    or status in ('pending', 'cancelled', 'registered')
  ),
  constraint tournament_registrations_cancel_consistency check (
    (
      status = 'cancelled'
      and cancelled_by is not null
      and cancelled_at is not null
    )
    or status <> 'cancelled'
  )
);

comment on table public.tournament_registrations is
  'Inscrições de usuários em torneios. O MVP usa display_name e não expõe RA/e-mail na lista pública. Status preserva histórico.';
comment on column public.tournament_registrations.status is
  'Fluxo da inscrição: pending, confirmed, cancelled, rejected, checked_in. registered é legado migrado para confirmed.';

alter table public.tournament_registrations
  add column if not exists registration_type public.registration_type not null default 'individual';

alter table public.tournament_registrations
  add column if not exists team_id uuid;

alter table public.tournament_registrations
  add column if not exists captain_user_id uuid references public.profiles(id) on delete set null;

alter table public.tournament_registrations
  add column if not exists admin_notes text;

alter table public.tournament_registrations
  add column if not exists decided_by uuid references public.profiles(id) on delete set null;

alter table public.tournament_registrations
  add column if not exists decided_at timestamptz;

alter table public.tournament_registrations
  add column if not exists cancelled_by uuid references public.profiles(id) on delete set null;

alter table public.tournament_registrations
  add column if not exists cancelled_at timestamptz;

comment on column public.tournament_registrations.registration_type is
  'Tipo de inscrição usado nesta linha. Permite preparar inscrições por equipe sem implementar membros ainda.';
comment on column public.tournament_registrations.captain_user_id is
  'Futuro capitão da equipe. Em inscrição individual fica nulo; em equipe aponta para o usuário que iniciou a inscrição.';
comment on column public.tournament_registrations.admin_notes is
  'Observação de gestão visível para admin/organizador do torneio por RLS.';

alter table public.tournament_registrations
  alter column status set default 'pending'::public.tournament_registration_status;

update public.tournament_registrations registration
set status = 'confirmed'::public.tournament_registration_status,
    decided_by = coalesce(registration.decided_by, tournament.created_by),
    decided_at = coalesce(
      registration.decided_at,
      registration.updated_at,
      registration.created_at,
      now()
    )
from public.tournaments tournament
where registration.tournament_id = tournament.id
  and registration.status = 'registered'::public.tournament_registration_status;

update public.tournament_registrations
set cancelled_by = coalesce(cancelled_by, user_id),
    cancelled_at = coalesce(cancelled_at, updated_at, now())
where status = 'cancelled'::public.tournament_registration_status
  and (
    cancelled_by is null
    or cancelled_at is null
  );

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'tournament_registrations_decision_consistency'
      and conrelid = 'public.tournament_registrations'::regclass
  ) then
    alter table public.tournament_registrations
      add constraint tournament_registrations_decision_consistency check (
        (
          status in ('confirmed', 'rejected', 'checked_in')
          and decided_by is not null
          and decided_at is not null
        )
        or status in ('pending', 'cancelled', 'registered')
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'tournament_registrations_cancel_consistency'
      and conrelid = 'public.tournament_registrations'::regclass
  ) then
    alter table public.tournament_registrations
      add constraint tournament_registrations_cancel_consistency check (
        (
          status = 'cancelled'
          and cancelled_by is not null
          and cancelled_at is not null
        )
        or status <> 'cancelled'
      );
  end if;
end
$$;

drop index if exists public.tournament_registrations_one_active_per_user;

create unique index if not exists tournament_registrations_one_active_per_user
  on public.tournament_registrations (tournament_id, user_id)
  where status in (
    'pending'::public.tournament_registration_status,
    'confirmed'::public.tournament_registration_status,
    'checked_in'::public.tournament_registration_status
  );

create index if not exists tournaments_status_idx
  on public.tournaments (status);

create index if not exists tournaments_created_by_idx
  on public.tournaments (created_by);

create index if not exists tournament_registrations_tournament_idx
  on public.tournament_registrations (tournament_id, status);

create table if not exists public.teams (
  id uuid primary key default extensions.gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  name text not null,
  status public.team_status not null default 'draft',
  captain_id uuid not null references public.profiles(id) on delete restrict,
  created_by uuid not null references public.profiles(id) on delete restrict,
  registration_id uuid references public.tournament_registrations(id) on delete set null,
  admin_notes text,
  decided_by uuid references public.profiles(id) on delete set null,
  decided_at timestamptz,
  cancelled_by uuid references public.profiles(id) on delete set null,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint teams_name_not_blank check (length(btrim(name)) >= 2),
  constraint teams_decision_consistency check (
    (
      status in ('confirmed', 'rejected')
      and decided_by is not null
      and decided_at is not null
    )
    or status in ('draft', 'pending', 'cancelled')
  ),
  constraint teams_cancel_consistency check (
    (
      status = 'cancelled'
      and cancelled_by is not null
      and cancelled_at is not null
    )
    or status <> 'cancelled'
  )
);

comment on table public.teams is
  'Equipes de torneios por equipe. A inscrição pública/administrativa aponta para a equipe por tournament_registrations.team_id.';
comment on column public.teams.captain_id is
  'Capitão atual da equipe. Transferência de capitania fica para etapa futura.';
comment on column public.teams.registration_id is
  'Inscrição criada quando a equipe é enviada para avaliação.';

create table if not exists public.team_members (
  id uuid primary key default extensions.gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.team_member_role not null default 'member',
  status public.team_member_status not null default 'active',
  added_by uuid references public.profiles(id) on delete set null,
  removed_by uuid references public.profiles(id) on delete set null,
  removed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint team_members_removed_consistency check (
    (
      status = 'removed'
      and removed_by is not null
      and removed_at is not null
    )
    or status = 'active'
  )
);

comment on table public.team_members is
  'Membros de equipes. No MVP, membros são adicionados por usuário existente localizado por email ou RA.';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'tournament_registrations_team_id_fkey'
      and conrelid = 'public.tournament_registrations'::regclass
  ) then
    alter table public.tournament_registrations
      add constraint tournament_registrations_team_id_fkey
      foreign key (team_id) references public.teams(id) on delete set null;
  end if;
end
$$;

create unique index if not exists teams_one_active_captain_per_tournament
  on public.teams (tournament_id, captain_id)
  where status in (
    'draft'::public.team_status,
    'pending'::public.team_status,
    'confirmed'::public.team_status
  );

create unique index if not exists teams_unique_active_name_per_tournament
  on public.teams (tournament_id, lower(name))
  where status in (
    'draft'::public.team_status,
    'pending'::public.team_status,
    'confirmed'::public.team_status
  );

create unique index if not exists team_members_one_active_per_team
  on public.team_members (team_id, user_id)
  where status = 'active'::public.team_member_status;

create unique index if not exists team_members_one_active_team_per_tournament
  on public.team_members (tournament_id, user_id)
  where status = 'active'::public.team_member_status;

create unique index if not exists team_members_one_active_captain_per_team
  on public.team_members (team_id)
  where status = 'active'::public.team_member_status
    and role = 'captain'::public.team_member_role;

create index if not exists teams_tournament_status_idx
  on public.teams (tournament_id, status);

create index if not exists team_members_team_status_idx
  on public.team_members (team_id, status);

-- Verifica se o usuário autenticado pode administrar inscrições de um torneio.
-- Admin global pode gerenciar qualquer torneio. Organizador aprovado só pode
-- gerenciar torneios criados por ele e enquanto mantiver permissão ativa.
create or replace function public.can_manage_tournament(target_tournament_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_admin()
    or exists (
      select 1
      from public.tournaments tournament
      where tournament.id = target_tournament_id
        and tournament.created_by = auth.uid()
        and public.can_create_tournament()
    );
$$;

comment on function public.can_manage_tournament(uuid) is
  'Retorna true para admin ou criador do torneio com permissão ativa de organizador.';

revoke all on function public.can_manage_tournament(uuid) from public;
grant execute on function public.can_manage_tournament(uuid) to authenticated;

create or replace function public.can_manage_team(target_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_admin()
    or exists (
      select 1
      from public.teams team
      where team.id = target_team_id
        and (
          public.can_manage_tournament(team.tournament_id)
          or team.captain_id = auth.uid()
        )
    );
$$;

comment on function public.can_manage_team(uuid) is
  'Retorna true para admin, organizador do torneio ou capitão da equipe.';

revoke all on function public.can_manage_team(uuid) from public;
grant execute on function public.can_manage_team(uuid) to authenticated;

create or replace function public.is_team_member(target_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.team_members member
    where member.team_id = target_team_id
      and member.user_id = auth.uid()
      and member.status = 'active'::public.team_member_status
  );
$$;

comment on function public.is_team_member(uuid) is
  'Retorna true quando auth.uid() é membro ativo da equipe. SECURITY DEFINER evita recursão de RLS.';

revoke all on function public.is_team_member(uuid) from public;
grant execute on function public.is_team_member(uuid) to authenticated;

create or replace function public.find_profile_for_team_member(identifier text)
returns table (
  id uuid,
  display_name text,
  email text,
  ra text,
  avatar_key text
)
language sql
stable
security definer
set search_path = public
as $$
  select profile.id,
         profile.display_name,
         profile.email,
         profile.ra,
         profile.avatar_key
  from public.profiles profile
  where auth.uid() is not null
    and (
      lower(profile.email) = lower(btrim(identifier))
      or lower(coalesce(profile.ra, '')) = lower(btrim(identifier))
    )
  limit 1;
$$;

comment on function public.find_profile_for_team_member(text) is
  'Busca exata por email ou RA para adicionar usuário existente a uma equipe. Não lista usuários.';

revoke all on function public.find_profile_for_team_member(text) from public;
grant execute on function public.find_profile_for_team_member(text) to authenticated;

create or replace function public.get_team_members_with_profiles(target_team_id uuid)
returns table (
  id uuid,
  tournament_id uuid,
  team_id uuid,
  user_id uuid,
  display_name text,
  avatar_key text,
  role public.team_member_role,
  status public.team_member_status,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  is_public_team boolean;
begin
  select exists (
    select 1
    from public.teams team
    join public.tournaments tournament on tournament.id = team.tournament_id
    where team.id = target_team_id
      and team.status = 'confirmed'::public.team_status
      and tournament.status <> 'draft'::public.tournament_status
  )
  into is_public_team;

  if not is_public_team
    and not public.can_manage_team(target_team_id)
    and not public.is_team_member(target_team_id)
  then
    raise exception 'Usuário não pode ver membros desta equipe.';
  end if;

  return query
    select member.id,
           member.tournament_id,
           member.team_id,
           member.user_id,
           profile.display_name,
           profile.avatar_key,
           member.role,
           member.status,
           member.created_at,
           member.updated_at
    from public.team_members member
    join public.profiles profile on profile.id = member.user_id
    where member.team_id = target_team_id
      and member.status = 'active'::public.team_member_status
    order by
      case when member.role = 'captain'::public.team_member_role then 0 else 1 end,
      profile.display_name;
end;
$$;

comment on function public.get_team_members_with_profiles(uuid) is
  'Lista membros ativos com dados públicos mínimos de perfil, respeitando equipe pública, membro, capitão ou gestor.';

revoke all on function public.get_team_members_with_profiles(uuid) from public;
grant execute on function public.get_team_members_with_profiles(uuid) to anon, authenticated;

create or replace function public.validate_team_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_tournament public.tournaments%rowtype;
  member_count integer;
begin
  select *
  into target_tournament
  from public.tournaments
  where id = new.tournament_id;

  if target_tournament.id is null then
    raise exception 'Torneio da equipe não encontrado.';
  end if;

  if target_tournament.registration_type <> 'team'::public.registration_type then
    raise exception 'Equipes só podem ser criadas em torneios por equipe.';
  end if;

  if target_tournament.status <> 'registrations_open'::public.tournament_status
    and not public.can_manage_tournament(new.tournament_id)
  then
    raise exception 'Equipes só podem ser alteradas enquanto inscrições estão abertas.';
  end if;

  if target_tournament.team_registration_deadline is not null
    and now() > target_tournament.team_registration_deadline
    and not public.can_manage_tournament(new.tournament_id)
  then
    raise exception 'O prazo para alterar equipes foi encerrado.';
  end if;

  if TG_OP = 'INSERT' then
    if new.created_by <> auth.uid() or new.captain_id <> auth.uid() then
      raise exception 'O criador da equipe deve ser o capitão inicial.';
    end if;

    if new.status <> 'draft'::public.team_status then
      raise exception 'Novas equipes devem iniciar como rascunho.';
    end if;
  end if;

  if TG_OP = 'UPDATE' then
    if new.id is distinct from old.id
      or new.tournament_id is distinct from old.tournament_id
      or new.created_by is distinct from old.created_by
      or new.captain_id is distinct from old.captain_id
      or new.created_at is distinct from old.created_at
    then
      raise exception 'Campos estruturais da equipe não podem ser alterados.';
    end if;

    if not public.can_manage_team(new.id) then
      raise exception 'Usuário não pode alterar esta equipe.';
    end if;

    if old.status in ('cancelled', 'rejected') and new.status is distinct from old.status then
      raise exception 'Equipe cancelada ou rejeitada não deve ser reativada.';
    end if;
  end if;

  if new.status in ('pending', 'confirmed') then
    select count(*)
    into member_count
    from public.team_members
    where team_id = new.id
      and status = 'active'::public.team_member_status;

    if member_count < target_tournament.team_min_size then
      raise exception 'Equipe precisa atingir o tamanho mínimo antes de ser enviada ou confirmada.';
    end if;
  end if;

  if new.status in ('confirmed', 'rejected') then
    new.decided_by := coalesce(new.decided_by, auth.uid());
    new.decided_at := coalesce(new.decided_at, now());
  end if;

  if new.status = 'cancelled'::public.team_status then
    new.cancelled_by := coalesce(new.cancelled_by, auth.uid(), new.captain_id);
    new.cancelled_at := coalesce(new.cancelled_at, now());
  end if;

  return new;
end;
$$;

create or replace function public.handle_new_team()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.team_members (
    tournament_id,
    team_id,
    user_id,
    role,
    status,
    added_by
  )
  values (
    new.tournament_id,
    new.id,
    new.captain_id,
    'captain'::public.team_member_role,
    'active'::public.team_member_status,
    new.created_by
  )
  on conflict do nothing;

  return new;
end;
$$;

create or replace function public.validate_team_member_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_team public.teams%rowtype;
  target_tournament public.tournaments%rowtype;
  active_count integer;
begin
  select *
  into target_team
  from public.teams
  where id = new.team_id;

  if target_team.id is null then
    raise exception 'Equipe não encontrada.';
  end if;

  select *
  into target_tournament
  from public.tournaments
  where id = target_team.tournament_id;

  new.tournament_id := target_team.tournament_id;

  if current_setting('app.team_cancellation', true) = 'on' then
    if TG_OP = 'UPDATE' and new.status = 'removed'::public.team_member_status then
      new.removed_by := coalesce(new.removed_by, auth.uid());
      new.removed_at := coalesce(new.removed_at, now());
    end if;

    return new;
  end if;

  if target_tournament.status <> 'registrations_open'::public.tournament_status
    and not public.can_manage_tournament(target_team.tournament_id)
  then
    raise exception 'Membros só podem ser alterados enquanto inscrições estão abertas.';
  end if;

  if target_tournament.team_registration_deadline is not null
    and now() > target_tournament.team_registration_deadline
    and not public.can_manage_tournament(target_team.tournament_id)
  then
    raise exception 'O prazo para alterar membros foi encerrado.';
  end if;

  if not public.can_manage_team(new.team_id) then
    raise exception 'Usuário não pode alterar membros desta equipe.';
  end if;

  if TG_OP = 'INSERT' then
    new.added_by := coalesce(new.added_by, auth.uid());
    new.status := coalesce(new.status, 'active'::public.team_member_status);
  end if;

  if TG_OP = 'UPDATE' then
    if new.id is distinct from old.id
      or new.tournament_id is distinct from old.tournament_id
      or new.team_id is distinct from old.team_id
      or new.user_id is distinct from old.user_id
      or new.created_at is distinct from old.created_at
    then
      raise exception 'Campos estruturais do membro não podem ser alterados.';
    end if;

    if old.role = 'captain'::public.team_member_role
      and new.status = 'removed'::public.team_member_status
    then
      raise exception 'Capitão não pode ser removido no MVP. Transfira capitania em etapa futura.';
    end if;
  end if;

  if new.role = 'captain'::public.team_member_role
    and new.user_id <> target_team.captain_id
  then
    raise exception 'Somente o captain_id da equipe pode ter papel de capitão.';
  end if;

  if new.user_id = target_team.captain_id then
    new.role := 'captain'::public.team_member_role;
  end if;

  if new.status = 'removed'::public.team_member_status then
    new.removed_by := coalesce(new.removed_by, auth.uid());
    new.removed_at := coalesce(new.removed_at, now());
  end if;

  if new.status = 'active'::public.team_member_status then
    select count(*)
    into active_count
    from public.team_members
    where team_id = new.team_id
      and status = 'active'::public.team_member_status
      and (
        TG_OP = 'INSERT'
        or id <> new.id
      );

    if active_count >= target_tournament.team_max_size then
      raise exception 'A equipe atingiu o tamanho máximo.';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.submit_team_registration(target_team_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_team public.teams%rowtype;
  target_tournament public.tournaments%rowtype;
  active_count integer;
  created_registration_id uuid;
begin
  select *
  into target_team
  from public.teams
  where id = target_team_id;

  if target_team.id is null then
    raise exception 'Equipe não encontrada.';
  end if;

  if not public.can_manage_team(target_team.id) then
    raise exception 'Usuário não pode enviar esta equipe para inscrição.';
  end if;

  select *
  into target_tournament
  from public.tournaments
  where id = target_team.tournament_id;

  if target_tournament.status <> 'registrations_open'::public.tournament_status then
    raise exception 'Inscrições de equipe só são permitidas com inscrições abertas.';
  end if;

  if target_tournament.registration_type <> 'team'::public.registration_type then
    raise exception 'Este torneio não é por equipe.';
  end if;

  select count(*)
  into active_count
  from public.team_members
  where team_id = target_team.id
    and status = 'active'::public.team_member_status;

  if target_tournament.require_full_team_before_registration
    and active_count < target_tournament.team_min_size
  then
    raise exception 'Equipe incompleta. Adicione membros até atingir o mínimo.';
  end if;

  select id
  into created_registration_id
  from public.tournament_registrations
  where tournament_id = target_team.tournament_id
    and user_id = target_team.captain_id
    and status in (
      'pending'::public.tournament_registration_status,
      'confirmed'::public.tournament_registration_status,
      'checked_in'::public.tournament_registration_status
    )
  limit 1;

  if created_registration_id is not null then
    raise exception 'Este capitão já possui inscrição ativa neste torneio.';
  end if;

  insert into public.tournament_registrations (
    tournament_id,
    user_id,
    team_id,
    display_name,
    status,
    registration_type,
    captain_user_id
  )
  values (
    target_team.tournament_id,
    target_team.captain_id,
    target_team.id,
    target_team.name,
    'pending'::public.tournament_registration_status,
    'team'::public.registration_type,
    target_team.captain_id
  )
  returning id into created_registration_id;

  update public.teams
  set status = 'pending'::public.team_status,
      registration_id = created_registration_id,
      updated_at = now()
  where id = target_team.id;

  return created_registration_id;
end;
$$;

revoke all on function public.submit_team_registration(uuid) from public;
grant execute on function public.submit_team_registration(uuid) to authenticated;

create or replace function public.cancel_team(target_team_id uuid, reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_team public.teams%rowtype;
begin
  select *
  into target_team
  from public.teams
  where id = target_team_id;

  if target_team.id is null then
    raise exception 'Equipe não encontrada.';
  end if;

  if not public.can_manage_team(target_team.id) then
    raise exception 'Usuário não pode cancelar esta equipe.';
  end if;

  if target_team.status = 'cancelled'::public.team_status then
    return;
  end if;

  if target_team.status = 'confirmed'::public.team_status
    and not public.can_manage_tournament(target_team.tournament_id)
  then
    raise exception 'Equipe confirmada só pode ser cancelada por admin ou organizador.';
  end if;

  perform set_config('app.team_cancellation', 'on', true);

  update public.team_members
  set status = 'removed'::public.team_member_status,
      removed_by = coalesce(auth.uid(), target_team.captain_id),
      removed_at = now(),
      updated_at = now()
  where team_id = target_team.id
    and status = 'active'::public.team_member_status;

  update public.teams
  set status = 'cancelled'::public.team_status,
      cancelled_by = coalesce(auth.uid(), target_team.captain_id),
      cancelled_at = now(),
      admin_notes = coalesce(nullif(reason, ''), admin_notes),
      updated_at = now()
  where id = target_team.id;

  perform set_config('app.team_cancellation', 'off', true);
end;
$$;

comment on function public.cancel_team(uuid, text) is
  'Cancela equipe por exclusão lógica, remove vínculos ativos de membros e preserva histórico.';

revoke all on function public.cancel_team(uuid, text) from public;
grant execute on function public.cancel_team(uuid, text) to authenticated;

-- Protege campos de autoria do torneio. Admins podem editar qualquer torneio,
-- mas mesmo admins não devem trocar id/created_at em update comum.
create or replace function public.protect_tournament_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.id is distinct from old.id then
    raise exception 'O id do torneio não pode ser alterado.';
  end if;

  if new.created_at is distinct from old.created_at then
    raise exception 'created_at do torneio não pode ser alterado.';
  end if;

  if new.created_by is distinct from old.created_by then
    raise exception 'created_by do torneio não pode ser alterado.';
  end if;

  return new;
end;
$$;

-- Garante que inscrições ativas só sejam criadas quando o torneio estiver
-- com inscrições abertas. A regra fica no banco, não apenas no React.
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
    raise exception 'Torneio da inscrição não encontrado.';
  end if;

  if new.registration_type <> current_registration_type then
    raise exception 'Tipo de inscrição incompatível com o torneio.';
  end if;

  if new.registration_type = 'team'::public.registration_type then
    if new.team_id is null then
      raise exception 'Inscrição por equipe precisa apontar para uma equipe.';
    end if;

    select *
    into target_team
    from public.teams
    where id = new.team_id;

    if target_team.id is null
      or target_team.tournament_id <> new.tournament_id
      or target_team.captain_id <> new.user_id
    then
      raise exception 'Equipe inválida para esta inscrição.';
    end if;

    new.captain_user_id := coalesce(new.captain_user_id, new.user_id);
  else
    if new.team_id is not null then
      raise exception 'Inscrição individual não pode apontar para equipe.';
    end if;

    new.captain_user_id := null;
  end if;

  if TG_OP = 'INSERT' then
    if new.status <> 'pending'::public.tournament_registration_status then
      raise exception 'Novas inscrições devem iniciar como pendentes.';
    end if;

    if current_tournament_status <> 'registrations_open'::public.tournament_status then
      raise exception 'Inscrições só são permitidas quando o torneio está com inscrições abertas.';
    end if;
  end if;

  if TG_OP = 'UPDATE' then
    if new.id is distinct from old.id then
      raise exception 'O id da inscrição não pode ser alterado.';
    end if;

    if new.tournament_id is distinct from old.tournament_id then
      raise exception 'O torneio da inscrição não pode ser alterado.';
    end if;

    if new.user_id is distinct from old.user_id then
      raise exception 'O usuário da inscrição não pode ser alterado.';
    end if;

    if new.registration_type is distinct from old.registration_type then
      raise exception 'O tipo da inscrição não pode ser alterado.';
    end if;

    if new.status = 'registered'::public.tournament_registration_status then
      raise exception 'registered é status legado. Use pending, confirmed, rejected, checked_in ou cancelled.';
    end if;

    if old.status in (
      'cancelled'::public.tournament_registration_status,
      'rejected'::public.tournament_registration_status
    )
      and new.status is distinct from old.status
    then
      raise exception 'Inscrições canceladas ou rejeitadas não devem ser reativadas. Crie uma nova inscrição.';
    end if;

    if not public.can_manage_tournament(new.tournament_id) then
      if old.user_id <> auth.uid() then
        raise exception 'Usuário comum só pode alterar a própria inscrição.';
      end if;

      if old.status not in (
        'pending'::public.tournament_registration_status,
        'confirmed'::public.tournament_registration_status
      )
        or new.status <> 'cancelled'::public.tournament_registration_status
      then
        raise exception 'Usuário comum só pode cancelar inscrição pendente ou confirmada.';
      end if;

      if current_tournament_status not in (
        'registrations_open'::public.tournament_status,
        'registrations_closed'::public.tournament_status
      ) then
        raise exception 'A inscrição não pode ser cancelada neste status do torneio.';
      end if;

      if new.display_name is distinct from old.display_name
        or new.admin_notes is distinct from old.admin_notes
        or new.decided_by is distinct from old.decided_by
        or new.decided_at is distinct from old.decided_at
        or new.created_at is distinct from old.created_at
      then
        raise exception 'Usuário comum não pode alterar campos administrativos da inscrição.';
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
        raise exception 'Inscrições só podem ser confirmadas, rejeitadas ou canceladas antes do torneio começar.';
      end if;

      if new.status = 'checked_in'::public.tournament_registration_status
        and current_tournament_status not in (
          'registrations_closed'::public.tournament_status,
          'ongoing'::public.tournament_status
        )
      then
        raise exception 'Check-in só é permitido após o fechamento das inscrições ou durante o torneio.';
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

drop trigger if exists tournaments_set_updated_at on public.tournaments;
create trigger tournaments_set_updated_at
  before update on public.tournaments
  for each row
  execute function public.set_updated_at();

drop trigger if exists tournaments_protect_update on public.tournaments;
create trigger tournaments_protect_update
  before update on public.tournaments
  for each row
  execute function public.protect_tournament_update();

drop trigger if exists tournament_registrations_set_updated_at
  on public.tournament_registrations;
create trigger tournament_registrations_set_updated_at
  before update on public.tournament_registrations
  for each row
  execute function public.set_updated_at();

drop trigger if exists tournament_registrations_validate_insert
  on public.tournament_registrations;
create trigger tournament_registrations_validate_insert
  before insert on public.tournament_registrations
  for each row
  execute function public.validate_tournament_registration_write();

drop trigger if exists tournament_registrations_validate_update
  on public.tournament_registrations;
create trigger tournament_registrations_validate_update
  before update on public.tournament_registrations
  for each row
  execute function public.validate_tournament_registration_write();

drop trigger if exists teams_set_updated_at on public.teams;
create trigger teams_set_updated_at
  before update on public.teams
  for each row
  execute function public.set_updated_at();

drop trigger if exists teams_validate_write on public.teams;
create trigger teams_validate_write
  before insert or update on public.teams
  for each row
  execute function public.validate_team_write();

drop trigger if exists teams_handle_new_team on public.teams;
create trigger teams_handle_new_team
  after insert on public.teams
  for each row
  execute function public.handle_new_team();

drop trigger if exists team_members_set_updated_at on public.team_members;
create trigger team_members_set_updated_at
  before update on public.team_members
  for each row
  execute function public.set_updated_at();

drop trigger if exists team_members_validate_write on public.team_members;
create trigger team_members_validate_write
  before insert or update on public.team_members
  for each row
  execute function public.validate_team_member_write();

alter table public.tournaments enable row level security;
alter table public.tournament_registrations enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;

grant usage on schema public to anon;
grant select on public.tournaments to anon;
grant select on public.tournament_registrations to anon;
grant select on public.teams to anon;
grant select on public.team_members to anon;
grant select, insert, update, delete on public.tournaments to authenticated;
grant select, insert, update on public.tournament_registrations to authenticated;
grant select, insert, update, delete on public.teams to authenticated;
grant select, insert, update on public.team_members to authenticated;
revoke delete on public.tournament_registrations from authenticated;

drop policy if exists "tournaments_select_public" on public.tournaments;
drop policy if exists "tournaments_select_owner" on public.tournaments;
drop policy if exists "tournaments_select_admin" on public.tournaments;
drop policy if exists "tournaments_insert_creator" on public.tournaments;
drop policy if exists "tournaments_update_owner" on public.tournaments;
drop policy if exists "tournaments_update_admin" on public.tournaments;
drop policy if exists "tournaments_delete_admin" on public.tournaments;

-- Qualquer visitante pode ler torneios publicados, isto é, fora de draft.
create policy "tournaments_select_public"
  on public.tournaments
  for select
  to anon, authenticated
  using (status <> 'draft'::public.tournament_status);

comment on policy "tournaments_select_public" on public.tournaments is
  'Permite leitura pública de torneios que não estão em draft.';

-- Criador autenticado pode ler seus próprios torneios, inclusive draft.
create policy "tournaments_select_owner"
  on public.tournaments
  for select
  to authenticated
  using (created_by = auth.uid());

comment on policy "tournaments_select_owner" on public.tournaments is
  'Permite ao criador ver os próprios torneios.';

-- Admin vê todos os torneios.
create policy "tournaments_select_admin"
  on public.tournaments
  for select
  to authenticated
  using (public.is_admin());

comment on policy "tournaments_select_admin" on public.tournaments is
  'Permite que admin global visualize todos os torneios.';

-- Admin ou usuario com permissao ativa pode criar torneio.
create policy "tournaments_insert_creator"
  on public.tournaments
  for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and public.can_create_tournament()
  );

comment on policy "tournaments_insert_creator" on public.tournaments is
  'Permite criar torneio para admin ou usuario com permissao active; usuario autorizado nao vira admin.';

-- Usuario com permissao ativa so edita torneios criados por ele.
create policy "tournaments_update_owner"
  on public.tournaments
  for update
  to authenticated
  using (
    created_by = auth.uid()
    and public.can_create_tournament()
  )
  with check (
    created_by = auth.uid()
    and public.can_create_tournament()
  );

comment on policy "tournaments_update_owner" on public.tournaments is
  'Usuário aprovado pode editar apenas torneios próprios.';

-- Admin pode alterar qualquer torneio, inclusive em andamento.
create policy "tournaments_update_admin"
  on public.tournaments
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

comment on policy "tournaments_update_admin" on public.tournaments is
  'Admin global pode editar qualquer torneio em qualquer status.';

-- Excluir torneio fica restrito ao admin global no MVP.
create policy "tournaments_delete_admin"
  on public.tournaments
  for delete
  to authenticated
  using (public.is_admin());

comment on policy "tournaments_delete_admin" on public.tournaments is
  'Permite exclusão de torneio apenas para admin global.';

drop policy if exists "registrations_select_public" on public.tournament_registrations;
drop policy if exists "registrations_select_public_confirmed" on public.tournament_registrations;
drop policy if exists "registrations_select_own" on public.tournament_registrations;
drop policy if exists "registrations_select_owner_tournament_admin" on public.tournament_registrations;
drop policy if exists "registrations_select_manager" on public.tournament_registrations;
drop policy if exists "registrations_insert_open_tournament" on public.tournament_registrations;
drop policy if exists "registrations_cancel_own" on public.tournament_registrations;
drop policy if exists "registrations_update_admin" on public.tournament_registrations;
drop policy if exists "registrations_manage_tournament" on public.tournament_registrations;
drop policy if exists "registrations_delete_admin" on public.tournament_registrations;

-- Lista pública mostra apenas participantes confirmados ou com check-in em torneios publicados.
-- Pedidos pendentes, rejeitados e cancelados ficam visíveis somente ao próprio usuário ou gestores.
create policy "registrations_select_public_confirmed"
  on public.tournament_registrations
  for select
  to anon, authenticated
  using (
    status in (
      'confirmed'::public.tournament_registration_status,
      'checked_in'::public.tournament_registration_status
    )
    and
    exists (
      select 1
      from public.tournaments t
      where t.id = tournament_id
        and t.status <> 'draft'::public.tournament_status
    )
  );

comment on policy "registrations_select_public_confirmed" on public.tournament_registrations is
  'Permite visualizar participantes confirmados de torneios públicos sem expor pedidos pendentes.';

-- Usuário autenticado vê seu próprio histórico de inscrições.
create policy "registrations_select_own"
  on public.tournament_registrations
  for select
  to authenticated
  using (user_id = auth.uid());

comment on policy "registrations_select_own" on public.tournament_registrations is
  'Permite que usuário veja as próprias inscrições, inclusive pendentes, canceladas e rejeitadas.';

-- Admin e organizador autorizado do torneio veem todas as inscrições daquele torneio.
create policy "registrations_select_manager"
  on public.tournament_registrations
  for select
  to authenticated
  using (public.can_manage_tournament(tournament_id));

comment on policy "registrations_select_manager" on public.tournament_registrations is
  'Permite ao admin e ao organizador autorizado ver todas as inscrições do torneio que gerencia.';

-- Usuário autenticado pode criar apenas a própria inscrição pendente em torneio aberto.
create policy "registrations_insert_open_tournament"
  on public.tournament_registrations
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and status = 'pending'::public.tournament_registration_status
    and admin_notes is null
    and decided_by is null
    and decided_at is null
    and cancelled_by is null
    and cancelled_at is null
    and exists (
      select 1
      from public.tournaments t
      where t.id = tournament_id
        and t.status = 'registrations_open'::public.tournament_status
        and t.registration_type = registration_type
    )
    and (
      (
        registration_type = 'individual'::public.registration_type
        and team_id is null
      )
      or (
        registration_type = 'team'::public.registration_type
        and team_id is not null
      )
    )
  );

comment on policy "registrations_insert_open_tournament" on public.tournament_registrations is
  'Bloqueia inscrição fora do status registrations_open e inicia o fluxo como pending.';

-- Usuário pode cancelar a própria inscrição pendente ou confirmada antes do início do torneio.
-- O trigger impede alteração de campos administrativos.
create policy "registrations_cancel_own"
  on public.tournament_registrations
  for update
  to authenticated
  using (
    user_id = auth.uid()
    and status in (
      'pending'::public.tournament_registration_status,
      'confirmed'::public.tournament_registration_status
    )
    and exists (
      select 1
      from public.tournaments t
      where t.id = tournament_id
        and t.status in (
          'registrations_open'::public.tournament_status,
          'registrations_closed'::public.tournament_status
        )
    )
  )
  with check (
    user_id = auth.uid()
    and status = 'cancelled'::public.tournament_registration_status
  );

comment on policy "registrations_cancel_own" on public.tournament_registrations is
  'Permite cancelar apenas a própria inscrição pendente ou confirmada, preservando histórico.';

create policy "registrations_manage_tournament"
  on public.tournament_registrations
  for update
  to authenticated
  using (public.can_manage_tournament(tournament_id))
  with check (public.can_manage_tournament(tournament_id));

comment on policy "registrations_manage_tournament" on public.tournament_registrations is
  'Permite confirmar, rejeitar ou cancelar inscrições para admin global e organizador autorizado do torneio.';

drop policy if exists "teams_select_public_confirmed" on public.teams;
drop policy if exists "teams_select_own" on public.teams;
drop policy if exists "teams_select_manager" on public.teams;
drop policy if exists "teams_insert_captain" on public.teams;
drop policy if exists "teams_update_manager_or_captain" on public.teams;
drop policy if exists "teams_delete_draft_manager_or_captain" on public.teams;

create policy "teams_select_public_confirmed"
  on public.teams
  for select
  to anon, authenticated
  using (
    status = 'confirmed'::public.team_status
    and exists (
      select 1
      from public.tournaments tournament
      where tournament.id = tournament_id
        and tournament.status <> 'draft'::public.tournament_status
    )
  );

comment on policy "teams_select_public_confirmed" on public.teams is
  'Permite leitura pública apenas de equipes confirmadas em torneios publicados.';

create policy "teams_select_own"
  on public.teams
  for select
  to authenticated
  using (
    captain_id = auth.uid()
    or public.is_team_member(id)
  );

comment on policy "teams_select_own" on public.teams is
  'Permite que capitão e membros vejam a própria equipe.';

create policy "teams_select_manager"
  on public.teams
  for select
  to authenticated
  using (public.can_manage_tournament(tournament_id));

comment on policy "teams_select_manager" on public.teams is
  'Permite que admin e organizador autorizado vejam todas as equipes do torneio.';

create policy "teams_insert_captain"
  on public.teams
  for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and captain_id = auth.uid()
    and status = 'draft'::public.team_status
    and exists (
      select 1
      from public.tournaments tournament
      where tournament.id = tournament_id
        and tournament.registration_type = 'team'::public.registration_type
        and tournament.status = 'registrations_open'::public.tournament_status
    )
  );

comment on policy "teams_insert_captain" on public.teams is
  'Usuário autenticado cria equipe própria em torneio por equipe com inscrições abertas.';

create policy "teams_update_manager_or_captain"
  on public.teams
  for update
  to authenticated
  using (public.can_manage_team(id))
  with check (public.can_manage_team(id));

comment on policy "teams_update_manager_or_captain" on public.teams is
  'Capitão edita a própria equipe; admin e organizador autorizado gerenciam equipes do torneio.';

create policy "teams_delete_draft_manager_or_captain"
  on public.teams
  for delete
  to authenticated
  using (
    status = 'draft'::public.team_status
    and public.can_manage_team(id)
  );

comment on policy "teams_delete_draft_manager_or_captain" on public.teams is
  'Permite excluir fisicamente apenas equipes em rascunho. Membros são removidos por cascade.';

drop policy if exists "team_members_select_public_confirmed" on public.team_members;
drop policy if exists "team_members_select_own_team" on public.team_members;
drop policy if exists "team_members_select_manager" on public.team_members;
drop policy if exists "team_members_insert_manager_or_captain" on public.team_members;
drop policy if exists "team_members_update_manager_or_captain" on public.team_members;

create policy "team_members_select_public_confirmed"
  on public.team_members
  for select
  to anon, authenticated
  using (
    status = 'active'::public.team_member_status
    and exists (
      select 1
      from public.teams team
      join public.tournaments tournament on tournament.id = team.tournament_id
      where team.id = team_id
        and team.status = 'confirmed'::public.team_status
        and tournament.status <> 'draft'::public.tournament_status
    )
  );

comment on policy "team_members_select_public_confirmed" on public.team_members is
  'Permite leitura pública dos membros ativos de equipes confirmadas.';

create policy "team_members_select_own_team"
  on public.team_members
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.can_manage_team(team_id)
  );

comment on policy "team_members_select_own_team" on public.team_members is
  'Permite que membro veja seu vínculo e capitão veja a lista da própria equipe.';

create policy "team_members_select_manager"
  on public.team_members
  for select
  to authenticated
  using (public.can_manage_tournament(tournament_id));

comment on policy "team_members_select_manager" on public.team_members is
  'Permite que admin e organizador autorizado vejam membros das equipes do torneio.';

create policy "team_members_insert_manager_or_captain"
  on public.team_members
  for insert
  to authenticated
  with check (public.can_manage_team(team_id));

comment on policy "team_members_insert_manager_or_captain" on public.team_members is
  'Capitão, admin ou organizador autorizado adiciona membros respeitando triggers de tamanho e duplicidade.';

create policy "team_members_update_manager_or_captain"
  on public.team_members
  for update
  to authenticated
  using (public.can_manage_team(team_id))
  with check (public.can_manage_team(team_id));

comment on policy "team_members_update_manager_or_captain" on public.team_members is
  'Capitão, admin ou organizador autorizado remove membros por status removed, preservando histórico.';

-- ---------------------------------------------------------------------------
-- Chave mata-mata simples
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'bracket_seeding_method'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.bracket_seeding_method as enum (
      'draw',
      'seeded'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'bracket_match_status'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.bracket_match_status as enum (
      'pending',
      'ready',
      'bye',
      'live',
      'completed',
      'disputed',
      'cancelled'
    );
  end if;
end
$$;

alter table public.tournament_registrations
  add column if not exists seed integer;

comment on column public.tournament_registrations.seed is
  'Semente opcional usada na geracao de chave mata-mata. Nulo entra no preenchimento restante.';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'tournament_registrations_seed_positive'
      and conrelid = 'public.tournament_registrations'::regclass
  ) then
    alter table public.tournament_registrations
      add constraint tournament_registrations_seed_positive check (
        seed is null
        or seed > 0
      );
  end if;
end
$$;

create unique index if not exists tournament_registrations_one_seed_per_tournament
  on public.tournament_registrations (tournament_id, seed)
  where seed is not null
    and status in (
      'pending'::public.tournament_registration_status,
      'confirmed'::public.tournament_registration_status,
      'checked_in'::public.tournament_registration_status
    );

create table if not exists public.tournament_brackets (
  id uuid primary key default extensions.gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  format text not null default 'single_elimination',
  seeding_method public.bracket_seeding_method not null,
  size integer not null,
  rounds_count integer not null,
  status text not null default 'generated',
  winner_registration_id uuid references public.tournament_registrations(id) on delete set null,
  generated_by uuid references public.profiles(id) on delete set null,
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tournament_brackets_format_single_elimination check (format = 'single_elimination'),
  constraint tournament_brackets_size_power check (
    size >= 2
    and (size & (size - 1)) = 0
  ),
  constraint tournament_brackets_rounds_positive check (rounds_count > 0),
  constraint tournament_brackets_status_allowed check (
    status in ('generated', 'published', 'archived')
  )
);

comment on table public.tournament_brackets is
  'Chave gerada de mata-mata simples. O sorteio/seeding fica persistido no banco.';
comment on column public.tournament_brackets.seeding_method is
  'Metodo usado na geracao: draw para sorteio salvo uma vez, seeded para distribuicao por seed.';
comment on column public.tournament_brackets.winner_registration_id is
  'Campeao definido quando a final e concluida.';

create unique index if not exists tournament_brackets_one_per_tournament
  on public.tournament_brackets (tournament_id);

create index if not exists tournament_brackets_tournament_idx
  on public.tournament_brackets (tournament_id);

create table if not exists public.bracket_matches (
  id uuid primary key default extensions.gen_random_uuid(),
  bracket_id uuid not null references public.tournament_brackets(id) on delete cascade,
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  round_number integer not null,
  match_number integer not null,
  status public.bracket_match_status not null default 'pending',
  participant_a_registration_id uuid references public.tournament_registrations(id) on delete set null,
  participant_b_registration_id uuid references public.tournament_registrations(id) on delete set null,
  winner_registration_id uuid references public.tournament_registrations(id) on delete set null,
  score_a integer,
  score_b integer,
  next_match_id uuid references public.bracket_matches(id) on delete set null,
  next_match_slot text,
  is_bye boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bracket_matches_round_positive check (round_number > 0),
  constraint bracket_matches_match_positive check (match_number > 0),
  constraint bracket_matches_next_slot_allowed check (
    next_match_slot is null
    or next_match_slot in ('a', 'b')
  ),
  constraint bracket_matches_scores_non_negative check (
    (score_a is null or score_a >= 0)
    and (score_b is null or score_b >= 0)
  ),
  constraint bracket_matches_bye_consistency check (
    not is_bye
    or status = 'bye'::public.bracket_match_status
  )
);

comment on table public.bracket_matches is
  'Partidas/nos da chave mata-mata. Cada partida sabe rodada, posicao e destino do vencedor.';
comment on column public.bracket_matches.next_match_id is
  'Proxima partida que recebe o vencedor desta partida.';
comment on column public.bracket_matches.next_match_slot is
  'Slot a ou b da proxima partida.';
comment on column public.bracket_matches.is_bye is
  'Indica partida estrutural de bye; nao representa confronto jogavel contra vazio.';

create unique index if not exists bracket_matches_unique_round_position
  on public.bracket_matches (bracket_id, round_number, match_number);

create index if not exists bracket_matches_tournament_round_idx
  on public.bracket_matches (tournament_id, round_number, match_number);

create or replace function public.protect_bracket_match_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('app.bracket_completion', true) = 'on' then
    return new;
  end if;

  if new.participant_a_registration_id is distinct from old.participant_a_registration_id
    or new.participant_b_registration_id is distinct from old.participant_b_registration_id
    or new.winner_registration_id is distinct from old.winner_registration_id
    or new.score_a is distinct from old.score_a
    or new.score_b is distinct from old.score_b
    or new.status is distinct from old.status
    or new.is_bye is distinct from old.is_bye
  then
    raise exception 'Alteracoes de resultado e avanco da chave devem usar a RPC complete_bracket_match.';
  end if;

  return new;
end;
$$;

create or replace function public.complete_bracket_match(
  target_match_id uuid,
  target_winner_registration_id uuid,
  target_score_a integer,
  target_score_b integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_match public.bracket_matches%rowtype;
begin
  select *
  into target_match
  from public.bracket_matches
  where id = target_match_id;

  if target_match.id is null then
    raise exception 'Partida da chave nao encontrada.';
  end if;

  if not public.can_manage_tournament(target_match.tournament_id) then
    raise exception 'Usuario nao pode alterar esta chave.';
  end if;

  if target_match.status not in (
    'ready'::public.bracket_match_status,
    'live'::public.bracket_match_status
  ) then
    raise exception 'Somente partidas prontas ou ao vivo podem receber vencedor.';
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
    raise exception 'Vencedor nao pertence a esta partida.';
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

  perform set_config('app.bracket_completion', 'on', true);

  update public.bracket_matches
  set status = 'completed'::public.bracket_match_status,
      score_a = target_score_a,
      score_b = target_score_b,
      winner_registration_id = target_winner_registration_id,
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
end;
$$;

comment on function public.complete_bracket_match(uuid, uuid, integer, integer) is
  'Confirma resultado de partida mata-mata, valida placar e avanca o vencedor para a proxima partida.';

revoke all on function public.complete_bracket_match(uuid, uuid, integer, integer) from public;
grant execute on function public.complete_bracket_match(uuid, uuid, integer, integer) to authenticated;

drop trigger if exists tournament_brackets_set_updated_at on public.tournament_brackets;
create trigger tournament_brackets_set_updated_at
  before update on public.tournament_brackets
  for each row
  execute function public.set_updated_at();

drop trigger if exists bracket_matches_set_updated_at on public.bracket_matches;
create trigger bracket_matches_set_updated_at
  before update on public.bracket_matches
  for each row
  execute function public.set_updated_at();

drop trigger if exists bracket_matches_protect_update on public.bracket_matches;
create trigger bracket_matches_protect_update
  before update on public.bracket_matches
  for each row
  execute function public.protect_bracket_match_update();

alter table public.tournament_brackets enable row level security;
alter table public.bracket_matches enable row level security;

grant select on public.tournament_brackets to anon;
grant select on public.bracket_matches to anon;
grant select, insert, update, delete on public.tournament_brackets to authenticated;
grant select, insert, update, delete on public.bracket_matches to authenticated;

drop policy if exists "brackets_select_public" on public.tournament_brackets;
drop policy if exists "brackets_select_manager" on public.tournament_brackets;
drop policy if exists "brackets_insert_manager" on public.tournament_brackets;
drop policy if exists "brackets_update_manager" on public.tournament_brackets;
drop policy if exists "brackets_delete_manager" on public.tournament_brackets;

create policy "brackets_select_public"
  on public.tournament_brackets
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tournaments tournament
      where tournament.id = tournament_id
        and tournament.status <> 'draft'::public.tournament_status
    )
  );

comment on policy "brackets_select_public" on public.tournament_brackets is
  'Permite leitura publica da chave de torneios publicados.';

create policy "brackets_select_manager"
  on public.tournament_brackets
  for select
  to authenticated
  using (public.can_manage_tournament(tournament_id));

create policy "brackets_insert_manager"
  on public.tournament_brackets
  for insert
  to authenticated
  with check (
    public.can_manage_tournament(tournament_id)
    and generated_by = auth.uid()
  );

create policy "brackets_update_manager"
  on public.tournament_brackets
  for update
  to authenticated
  using (public.can_manage_tournament(tournament_id))
  with check (public.can_manage_tournament(tournament_id));

create policy "brackets_delete_manager"
  on public.tournament_brackets
  for delete
  to authenticated
  using (public.can_manage_tournament(tournament_id));

drop policy if exists "bracket_matches_select_public" on public.bracket_matches;
drop policy if exists "bracket_matches_select_manager" on public.bracket_matches;
drop policy if exists "bracket_matches_insert_manager" on public.bracket_matches;
drop policy if exists "bracket_matches_update_manager" on public.bracket_matches;
drop policy if exists "bracket_matches_delete_manager" on public.bracket_matches;

create policy "bracket_matches_select_public"
  on public.bracket_matches
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tournaments tournament
      where tournament.id = tournament_id
        and tournament.status <> 'draft'::public.tournament_status
    )
  );

comment on policy "bracket_matches_select_public" on public.bracket_matches is
  'Permite leitura publica das partidas da chave de torneios publicados.';

create policy "bracket_matches_select_manager"
  on public.bracket_matches
  for select
  to authenticated
  using (public.can_manage_tournament(tournament_id));

create policy "bracket_matches_insert_manager"
  on public.bracket_matches
  for insert
  to authenticated
  with check (public.can_manage_tournament(tournament_id));

create policy "bracket_matches_update_manager"
  on public.bracket_matches
  for update
  to authenticated
  using (public.can_manage_tournament(tournament_id))
  with check (public.can_manage_tournament(tournament_id));

create policy "bracket_matches_delete_manager"
  on public.bracket_matches
  for delete
  to authenticated
  using (public.can_manage_tournament(tournament_id));

-- ---------------------------------------------------------------------------
-- Resultados, contestacoes e historico da chave
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'match_result_status'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.match_result_status as enum (
      'confirmed',
      'disputed',
      'resolved',
      'cancelled'
    );
  end if;
end
$$;

alter table public.bracket_matches
  add column if not exists result_notes text;

alter table public.bracket_matches
  add column if not exists submitted_by uuid references public.profiles(id) on delete set null;

alter table public.bracket_matches
  add column if not exists submitted_at timestamptz;

alter table public.bracket_matches
  add column if not exists confirmed_by uuid references public.profiles(id) on delete set null;

alter table public.bracket_matches
  add column if not exists confirmed_at timestamptz;

comment on column public.bracket_matches.result_notes is
  'Observacoes administrativas do resultado confirmado ou corrigido.';
comment on column public.bracket_matches.submitted_by is
  'Usuario que registrou o resultado pela RPC protegida.';
comment on column public.bracket_matches.confirmed_by is
  'Admin ou organizador que confirmou o resultado.';

create table if not exists public.match_results (
  id uuid primary key default extensions.gen_random_uuid(),
  match_id uuid not null unique references public.bracket_matches(id) on delete cascade,
  bracket_id uuid not null references public.tournament_brackets(id) on delete cascade,
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  score_a integer not null,
  score_b integer not null,
  winner_registration_id uuid not null references public.tournament_registrations(id) on delete restrict,
  status public.match_result_status not null default 'confirmed',
  notes text,
  submitted_by uuid references public.profiles(id) on delete set null,
  submitted_at timestamptz not null default now(),
  confirmed_by uuid references public.profiles(id) on delete set null,
  confirmed_at timestamptz,
  disputed_by uuid references public.profiles(id) on delete set null,
  disputed_at timestamptz,
  dispute_reason text,
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  resolution_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint match_results_scores_non_negative check (score_a >= 0 and score_b >= 0),
  constraint match_results_dispute_consistency check (
    (
      status = 'disputed'::public.match_result_status
      and disputed_by is not null
      and disputed_at is not null
      and length(btrim(coalesce(dispute_reason, ''))) > 0
    )
    or status <> 'disputed'::public.match_result_status
  ),
  constraint match_results_resolution_consistency check (
    (
      status in (
        'resolved'::public.match_result_status,
        'cancelled'::public.match_result_status
      )
      and resolved_by is not null
      and resolved_at is not null
    )
    or status not in (
      'resolved'::public.match_result_status,
      'cancelled'::public.match_result_status
    )
  )
);

comment on table public.match_results is
  'Resultado confirmado, contestado ou resolvido de uma partida da chave.';
comment on column public.match_results.status is
  'confirmed e o fluxo direto do MVP; disputed indica contestacao; resolved/cancelled encerram a contestacao.';

create index if not exists match_results_tournament_status_idx
  on public.match_results (tournament_id, status);

create table if not exists public.match_result_history (
  id uuid primary key default extensions.gen_random_uuid(),
  match_id uuid not null references public.bracket_matches(id) on delete cascade,
  result_id uuid references public.match_results(id) on delete set null,
  previous_score_a integer,
  previous_score_b integer,
  new_score_a integer,
  new_score_b integer,
  previous_winner_registration_id uuid references public.tournament_registrations(id) on delete set null,
  new_winner_registration_id uuid references public.tournament_registrations(id) on delete set null,
  previous_status public.bracket_match_status,
  new_status public.bracket_match_status,
  changed_by uuid references public.profiles(id) on delete set null,
  change_reason text,
  created_at timestamptz not null default now()
);

comment on table public.match_result_history is
  'Historico imutavel de registros, correcoes, contestacoes e resolucoes de resultado.';

create index if not exists match_result_history_match_idx
  on public.match_result_history (match_id, created_at desc);

create or replace function public.is_match_participant(target_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.bracket_matches bracket_match
    join public.tournament_registrations registration
      on registration.id in (
        bracket_match.participant_a_registration_id,
        bracket_match.participant_b_registration_id
      )
    where bracket_match.id = target_match_id
      and (
        registration.user_id = auth.uid()
        or registration.captain_user_id = auth.uid()
        or exists (
          select 1
          from public.team_members member
          where member.team_id = registration.team_id
            and member.user_id = auth.uid()
            and member.status = 'active'::public.team_member_status
        )
      )
  );
$$;

comment on function public.is_match_participant(uuid) is
  'Retorna true quando auth.uid() participa da partida como inscrito individual, capitao ou membro ativo da equipe.';

revoke all on function public.is_match_participant(uuid) from public;
grant execute on function public.is_match_participant(uuid) to authenticated;

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
    resolution_notes
  )
  values (
    target_match.id,
    target_match.bracket_id,
    target_match.tournament_id,
    target_score_a,
    target_score_b,
    target_winner_registration_id,
    'confirmed'::public.match_result_status,
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
    null
  )
  on conflict (match_id) do update
    set score_a = excluded.score_a,
        score_b = excluded.score_b,
        winner_registration_id = excluded.winner_registration_id,
        status = excluded.status,
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
      result_notes = nullif(target_notes, ''),
      submitted_by = auth.uid(),
      submitted_at = now(),
      confirmed_by = auth.uid(),
      confirmed_at = now(),
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

comment on function public.record_bracket_match_result(uuid, uuid, integer, integer, text, text) is
  'Registra ou corrige resultado com auditoria, valida placar de mata-mata e avanca vencedor de forma transacional.';

revoke all on function public.record_bracket_match_result(uuid, uuid, integer, integer, text, text) from public;
grant execute on function public.record_bracket_match_result(uuid, uuid, integer, integer, text, text) to authenticated;

create or replace function public.complete_bracket_match(
  target_match_id uuid,
  target_winner_registration_id uuid,
  target_score_a integer,
  target_score_b integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.record_bracket_match_result(
    target_match_id,
    target_winner_registration_id,
    target_score_a,
    target_score_b,
    null,
    null
  );
end;
$$;

comment on function public.complete_bracket_match(uuid, uuid, integer, integer) is
  'Compatibilidade: registra resultado simples chamando record_bracket_match_result.';

revoke all on function public.complete_bracket_match(uuid, uuid, integer, integer) from public;
grant execute on function public.complete_bracket_match(uuid, uuid, integer, integer) to authenticated;

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

comment on function public.contest_match_result(uuid, text) is
  'Permite que participante da partida conteste resultado finalizado; gestor resolve depois.';

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
      auth.uid(),
      btrim(target_resolution_notes)
    );

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
        result_notes = null,
        submitted_by = null,
        submitted_at = null,
        confirmed_by = null,
        confirmed_at = null,
        updated_at = now()
    where id = target_match.id;
  end if;

  perform set_config('app.bracket_completion', 'off', true);
  perform set_config('app.match_result_write', 'off', true);
end;
$$;

comment on function public.resolve_match_dispute(uuid, text, text) is
  'Admin ou organizador resolve contestacao confirmando o resultado ou cancelando para novo lancamento.';

revoke all on function public.resolve_match_dispute(uuid, text, text) from public;
grant execute on function public.resolve_match_dispute(uuid, text, text) to authenticated;

drop trigger if exists match_results_set_updated_at on public.match_results;
create trigger match_results_set_updated_at
  before update on public.match_results
  for each row
  execute function public.set_updated_at();

alter table public.match_results enable row level security;
alter table public.match_result_history enable row level security;

grant select on public.match_results to anon;
grant select on public.match_results to authenticated;
grant select on public.match_result_history to authenticated;
revoke insert, update, delete on public.match_results from anon, authenticated;
revoke insert, update, delete on public.match_result_history from anon, authenticated;

drop policy if exists "match_results_select_public" on public.match_results;
drop policy if exists "match_results_select_manager" on public.match_results;
drop policy if exists "match_results_select_participant" on public.match_results;

create policy "match_results_select_public"
  on public.match_results
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tournaments tournament
      where tournament.id = tournament_id
        and tournament.status <> 'draft'::public.tournament_status
    )
  );

create policy "match_results_select_manager"
  on public.match_results
  for select
  to authenticated
  using (public.can_manage_tournament(tournament_id));

create policy "match_results_select_participant"
  on public.match_results
  for select
  to authenticated
  using (public.is_match_participant(match_id));

drop policy if exists "match_result_history_select_manager" on public.match_result_history;
drop policy if exists "match_result_history_select_participant" on public.match_result_history;

create policy "match_result_history_select_manager"
  on public.match_result_history
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.bracket_matches bracket_match
      where bracket_match.id = match_result_history.match_id
        and public.can_manage_tournament(bracket_match.tournament_id)
    )
  );

create policy "match_result_history_select_participant"
  on public.match_result_history
  for select
  to authenticated
  using (public.is_match_participant(match_id));

-- ---------------------------------------------------------------------------
-- Rankings e classificacoes por pontos
-- ---------------------------------------------------------------------------

create table if not exists public.tournament_standings (
  id uuid primary key default extensions.gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  group_id text,
  scope text not null default 'overall',
  status text not null default 'provisional',
  win_points integer not null default 3,
  draw_points integer not null default 1,
  loss_points integer not null default 0,
  tie_breakers text[] not null default array[
    'points',
    'wins',
    'score_diff',
    'score_for',
    'head_to_head',
    'seed_or_name'
  ],
  calculated_by uuid references public.profiles(id) on delete set null,
  calculated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tournament_standings_scope_not_blank check (length(btrim(scope)) > 0),
  constraint tournament_standings_status_allowed check (
    status in ('provisional', 'official', 'archived')
  ),
  constraint tournament_standings_points_non_negative check (
    win_points >= 0
    and draw_points >= 0
    and loss_points >= 0
  )
);

comment on table public.tournament_standings is
  'Snapshot de ranking por torneio ou grupo. O calculo deve vir de resultados confirmados, nao de edicao manual de usuario comum.';
comment on column public.tournament_standings.tie_breakers is
  'Ordem explicita de desempate: points, wins, score_diff, score_for, head_to_head e fallback estavel por seed_or_name.';

create table if not exists public.standing_entries (
  id uuid primary key default extensions.gen_random_uuid(),
  standing_id uuid not null references public.tournament_standings(id) on delete cascade,
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  group_id text,
  participant_registration_id uuid not null references public.tournament_registrations(id) on delete cascade,
  team_id uuid references public.teams(id) on delete set null,
  display_name text not null,
  played integer not null default 0,
  wins integer not null default 0,
  draws integer not null default 0,
  losses integer not null default 0,
  score_for integer not null default 0,
  score_against integer not null default 0,
  score_diff integer not null default 0,
  points integer not null default 0,
  position integer not null,
  tie_breaker_summary text not null,
  is_technical_tie boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint standing_entries_display_name_not_blank check (length(btrim(display_name)) > 0),
  constraint standing_entries_position_positive check (position > 0),
  constraint standing_entries_stats_non_negative check (
    played >= 0
    and wins >= 0
    and draws >= 0
    and losses >= 0
    and score_for >= 0
    and score_against >= 0
    and points >= 0
  ),
  constraint standing_entries_played_consistency check (
    played = wins + draws + losses
  ),
  constraint standing_entries_score_diff_consistency check (
    score_diff = score_for - score_against
  )
);

comment on table public.standing_entries is
  'Linhas do snapshot de ranking com estatisticas basicas e resumo do criterio de desempate aplicado.';
comment on column public.standing_entries.score_for is
  'Score, gols, rounds ou pontos feitos pelo participante/equipe.';
comment on column public.standing_entries.score_against is
  'Score, gols, rounds ou pontos sofridos pelo participante/equipe.';
comment on column public.standing_entries.score_diff is
  'Saldo calculado como score_for - score_against.';

create unique index if not exists tournament_standings_unique_scope
  on public.tournament_standings (tournament_id, scope, coalesce(group_id, ''));

create unique index if not exists standing_entries_unique_participant
  on public.standing_entries (standing_id, participant_registration_id);

create index if not exists tournament_standings_tournament_idx
  on public.tournament_standings (tournament_id);

create index if not exists standing_entries_tournament_position_idx
  on public.standing_entries (tournament_id, group_id, position);

drop trigger if exists tournament_standings_set_updated_at on public.tournament_standings;
create trigger tournament_standings_set_updated_at
  before update on public.tournament_standings
  for each row
  execute function public.set_updated_at();

drop trigger if exists standing_entries_set_updated_at on public.standing_entries;
create trigger standing_entries_set_updated_at
  before update on public.standing_entries
  for each row
  execute function public.set_updated_at();

alter table public.tournament_standings enable row level security;
alter table public.standing_entries enable row level security;

grant select on public.tournament_standings to anon, authenticated;
grant select on public.standing_entries to anon, authenticated;
grant insert, update, delete on public.tournament_standings to authenticated;
grant insert, update, delete on public.standing_entries to authenticated;

drop policy if exists "standings_select_public" on public.tournament_standings;
drop policy if exists "standings_select_manager" on public.tournament_standings;
drop policy if exists "standings_write_manager" on public.tournament_standings;
drop policy if exists "standing_entries_select_public" on public.standing_entries;
drop policy if exists "standing_entries_select_manager" on public.standing_entries;
drop policy if exists "standing_entries_write_manager" on public.standing_entries;

create policy "standings_select_public"
  on public.tournament_standings
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tournaments tournament
      where tournament.id = tournament_id
        and tournament.status <> 'draft'::public.tournament_status
    )
  );

create policy "standings_select_manager"
  on public.tournament_standings
  for select
  to authenticated
  using (public.can_manage_tournament(tournament_id));

create policy "standings_write_manager"
  on public.tournament_standings
  for all
  to authenticated
  using (public.can_manage_tournament(tournament_id))
  with check (public.can_manage_tournament(tournament_id));

create policy "standing_entries_select_public"
  on public.standing_entries
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tournaments tournament
      where tournament.id = tournament_id
        and tournament.status <> 'draft'::public.tournament_status
    )
  );

create policy "standing_entries_select_manager"
  on public.standing_entries
  for select
  to authenticated
  using (public.can_manage_tournament(tournament_id));

create policy "standing_entries_write_manager"
  on public.standing_entries
  for all
  to authenticated
  using (public.can_manage_tournament(tournament_id))
  with check (public.can_manage_tournament(tournament_id));

-- ---------------------------------------------------------------------------
-- Auditoria geral e bloqueios administrativos
-- ---------------------------------------------------------------------------

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

-- ---------------------------------------------------------------------------
-- Check-in formal, W.O. e desclassificacao
-- ---------------------------------------------------------------------------

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


