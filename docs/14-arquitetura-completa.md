# UTFPR Torneios - arquitetura completa do projeto

Este documento descreve a estrutura real do projeto no estado atual do
repositorio. Ele complementa os documentos existentes em `docs/` e registra
como os modulos estao conectados: React, Supabase, RLS, paginas, servicos,
algoritmos de torneio, resultados, ranking, permissao e design.

Tambem registra a arquitetura-alvo do MVP e separa claramente o que ja esta
implementado, o que esta parcialmente implementado e o que ainda precisa ser
construido. Sempre que houver diferenca entre uma regra desejada e o codigo
atual, este documento deve deixar essa diferenca explicita.

## 1. Visao geral

O projeto e um sistema web academico da UTFPR para criacao, gestao e
publicacao de torneios. A aplicacao combina:

- Front-end em Vite, React e TypeScript.
- CSS proprio com tokens globais e componentes responsivos.
- Supabase Auth como origem de usuarios.
- Supabase PostgreSQL como banco principal.
- Row Level Security como barreira real de autorizacao.
- Funcoes SQL/RPC para acoes sensiveis.
- Funcoes TypeScript puras para algoritmos de torneio.
- Hash routing manual em `src/App.tsx`.
- Dados mockados ainda mantidos para telas demonstrativas antigas.

O fluxo principal e:

```text
index.html
  -> src/main.tsx
    -> src/App.tsx
      -> AuthProvider
        -> AppRouter por hash
          -> paginas React
            -> services/*
              -> supabase client
                -> PostgreSQL + RLS + triggers + RPCs
```

O front-end melhora a experiencia do usuario, mas a decisao final de
permissao fica no banco. Usuario comum nao deve conseguir manipular role,
permissoes, rankings, resultados, inscricoes de terceiros ou torneios sem
autorizacao.

Marcadores usados neste documento:

- `Implementado`: existe codigo, schema ou UI funcional no repositorio.
- `Parcial`: existe base tecnica, mas o fluxo ainda nao esta completo.
- `Pendente`: faz parte da arquitetura desejada, mas ainda nao foi implementado.
- `Futuro`: recurso planejado fora do MVP imediato.

## 2. Stack e comandos

Arquivos de configuracao principais:

```text
package.json
package-lock.json
vite.config.ts
tsconfig.json
tsconfig.app.json
tsconfig.node.json
eslint.config.js
index.html
```

Stack instalada:

- `vite`
- `react`
- `react-dom`
- `typescript`
- `@supabase/supabase-js`
- `eslint`
- `@vitejs/plugin-react`

Scripts em `package.json`:

```bash
npm run dev
npm run build
npm run lint
npm run preview
```

Variaveis esperadas pelo cliente Supabase:

```text
VITE_SUPABASE_URL
VITE_SUPABASE_ANON_KEY
```

Chave `service_role` nunca deve entrar no front-end.

O arquivo `.env.example` existe apenas como modelo e nao deve conter valores
reais.

## 3. Mapa completo de arquivos

Estrutura atual do repositorio:

```text
.
|-- AGENTS.md
|-- .env.example
|-- README.md
|-- eslint.config.js
|-- index.html
|-- package-lock.json
|-- package.json
|-- tsconfig.app.json
|-- tsconfig.json
|-- tsconfig.node.json
|-- vite.config.ts
|-- public/
|   |-- favicon.svg
|   `-- icons.svg
|-- supabase/
|   |-- README.md
|   |-- schema.sql
|   `-- migrations/
|       `-- README.md
|-- src/
|   |-- App.css
|   |-- App.tsx
|   |-- index.css
|   |-- main.tsx
|   |-- assets/
|   |   |-- hero.png
|   |   |-- react.svg
|   |   `-- vite.svg
|   |-- components/
|   |   |-- auth/
|   |   |   |-- AdminRoute.tsx
|   |   |   |-- AuthLayout.tsx
|   |   |   |-- AvatarPicker.tsx
|   |   |   |-- CreatorPermissionCard.tsx
|   |   |   |-- CreatorPermissionStatusBadge.tsx
|   |   |   |-- CreatorRequestCard.tsx
|   |   |   |-- CreatorRequestStatusBadge.tsx
|   |   |   |-- LoginForm.tsx
|   |   |   |-- LogoutButton.tsx
|   |   |   |-- PasswordRecoveryForm.tsx
|   |   |   |-- ProfileForm.tsx
|   |   |   |-- ProtectedRoute.tsx
|   |   |   |-- RegisterForm.tsx
|   |   |   |-- UserMenu.tsx
|   |   |   `-- avatarOptions.ts
|   |   |-- layout/
|   |   |   |-- AuthenticatedShell.tsx
|   |   |   |-- PageBackButton.tsx
|   |   |   |-- PageLayout.tsx
|   |   |   `-- SiteHeader.tsx
|   |   `-- tournament/
|   |       |-- TeamStatusBadge.tsx
|   |       |-- TournamentForm.tsx
|   |       |-- TournamentRegistrationStatusBadge.tsx
|   |       `-- TournamentStatusBadge.tsx
|   |-- context/
|   |   |-- AuthContext.tsx
|   |   `-- auth.ts
|   |-- data/
|   |   `-- mockData.ts
|   |-- lib/
|   |   |-- supabase/
|   |   |   |-- client.ts
|   |   |   `-- types.ts
|   |   `-- tournaments/
|   |       |-- matchResults.ts
|   |       |-- ranking.ts
|   |       `-- singleElimination.ts
|   |-- pages/
|   |   |-- auth/
|   |   |   |-- AccessDeniedPage.tsx
|   |   |   |-- AdminCreatorRequestsPage.tsx
|   |   |   |-- AdminHomePage.tsx
|   |   |   |-- LoginPage.tsx
|   |   |   |-- MyAccountPage.tsx
|   |   |   |-- MyCreatorRequestsPage.tsx
|   |   |   |-- PasswordRecoveryPage.tsx
|   |   |   |-- RegisterPage.tsx
|   |   |   `-- RequestTournamentCreatorPage.tsx
|   |   `-- tournaments/
|   |       |-- CreateTournamentPage.tsx
|   |       |-- EditTournamentPage.tsx
|   |       |-- MyRegistrationsPage.tsx
|   |       |-- PublicTournamentPage.tsx
|   |       |-- TeamDetailsPage.tsx
|   |       |-- TournamentBracketPage.tsx
|   |       |-- TournamentParticipantsPage.tsx
|   |       |-- TournamentRankingPage.tsx
|   |       |-- TournamentTeamsPage.tsx
|   |       `-- TournamentsPage.tsx
|   `-- services/
|       |-- admin.ts
|       |-- brackets.ts
|       |-- rankings.ts
|       |-- teams.ts
|       |-- tournamentCreatorRequests.ts
|       `-- tournaments.ts
`-- docs/
    |-- 00-visao-geral.md
    |-- 01-requisitos-funcionais.md
    |-- 02-regras-de-torneios.md
    |-- 03-formatos-e-algoritmos.md
    |-- 04-modelo-de-dados.md
    |-- 05-fluxos-de-usuario.md
    |-- 06-arquitetura.md
    |-- 07-rotas-e-telas.md
    |-- 08-api-e-contratos.md
    |-- 09-ui-ux-design-system.md
    |-- 10-css-responsividade-acessibilidade.md
    |-- 11-testes-e-validacao.md
    |-- 12-roadmap-mvp.md
    |-- 13-checklist-code-review.md
    `-- 14-arquitetura-completa.md
```

## 4. Documentos do projeto

Documentos existentes:

- `AGENTS.md`: regras de trabalho, stack, seguranca, visual e qualidade.
- `README.md`: resumo do projeto, instalacao, Supabase e ordem sugerida de
  leitura.
- `docs/00-visao-geral.md`: contexto do produto.
- `docs/01-requisitos-funcionais.md`: requisitos funcionais.
- `docs/02-regras-de-torneios.md`: regras de negocio para competicoes.
- `docs/03-formatos-e-algoritmos.md`: formatos e algoritmos planejados.
- `docs/04-modelo-de-dados.md`: modelo de dados.
- `docs/05-fluxos-de-usuario.md`: jornadas de usuarios.
- `docs/06-arquitetura.md`: arquitetura recomendada originalmente.
- `docs/07-rotas-e-telas.md`: rotas e telas.
- `docs/08-api-e-contratos.md`: contratos de dados e API.
- `docs/09-ui-ux-design-system.md`: identidade visual e componentes.
- `docs/10-css-responsividade-acessibilidade.md`: regras de CSS e acessibilidade.
- `docs/11-testes-e-validacao.md`: validacao e testes.
- `docs/12-roadmap-mvp.md`: roadmap.
- `docs/13-checklist-code-review.md`: checklist consolidado de revisao de
  codigo, responsividade, acessibilidade, design e regras de torneio.

Observacao: o README cita documentos externos como `Funcionamento de
torneios.pdf`, `checklist-responsividade-design.md`, `code_review.md` e
`frontend-boas-praticas.md`. Eles nao aparecem na listagem atual do repositorio.
As regras equivalentes estao parcialmente consolidadas em `AGENTS.md`,
`docs/10-css-responsividade-acessibilidade.md` e
`docs/13-checklist-code-review.md`. Quando os arquivos originais forem
adicionados, este documento deve ser revisado contra eles.

## 5. Entrada da aplicacao

### `index.html`

Arquivo HTML raiz usado pelo Vite. Contem o elemento onde o React monta a
aplicacao.

### `src/main.tsx`

Responsavel por:

- importar `index.css`;
- criar a raiz React com `createRoot`;
- renderizar `<App />` dentro de `<StrictMode>`.

### `src/App.tsx`

Responsavel por:

- envolver a aplicacao em `AuthProvider`;
- manter o roteamento manual por `window.location.hash`;
- mapear rotas reais do Supabase para paginas modernas;
- manter uma aplicacao demo antiga via `TournamentDemoApp`;
- renderizar paginas demo com `mockData.ts` quando a rota nao e uma das rotas
  reais reconhecidas.

Nao ha React Router. A navegacao usa links por hash, principalmente
`href="#/..."`, alem de rotas demo legadas como `#home` e alteracoes manuais de
`window.location.hash`.

## 6. Rotas reais

Rotas principais reconhecidas em `AppRouter`:

```text
#/torneios
#/torneios/novo
#/torneios/:id
#/torneios/:id/editar
#/torneios/:id/participantes
#/torneios/:id/chave
#/torneios/:id/ranking
#/torneios/:id/equipes
#/torneios/:id/equipes/:teamId
#/login
#/cadastro
#/recuperar-senha
#/perfil
#/minha-conta
#/admin
#/admin/pedidos
#/solicitar-criacao-torneio
#/meus-pedidos
#/minhas-inscricoes
#/acesso-negado
```

Rotas protegidas por login:

- `#/torneios/novo`
- `#/torneios/:id/editar`
- `#/torneios/:id/equipes/:teamId`
- `#/perfil`
- `#/minha-conta`
- `#/solicitar-criacao-torneio`
- `#/meus-pedidos`
- `#/minhas-inscricoes`

Rotas protegidas por admin:

- `#/admin`
- `#/admin/pedidos`

Rotas publicas com dados regulados por RLS:

- `#/torneios`
- `#/torneios/:id`
- `#/torneios/:id/participantes`
- `#/torneios/:id/chave`
- `#/torneios/:id/ranking`
- `#/torneios/:id/equipes`

As rotas demo antigas aceitam nomes como `home`, `dashboard`, `tournaments`,
`create`, `public`, `bracket`, `groups`, `matches`, `result` e `empty`. Elas
continuam sendo renderizadas por `TournamentDemoApp`.

## 7. Camadas da aplicacao

### UI

Fica em:

```text
src/pages/
src/components/
src/App.tsx
src/App.css
src/index.css
```

Responsabilidades:

- renderizar telas;
- manter estados de loading, erro, sucesso e vazio;
- coletar inputs;
- chamar servicos;
- exibir ou esconder acoes conforme contexto de usuario;
- manter responsividade e acessibilidade.

### Contexto de autenticacao

Fica em:

```text
src/context/AuthContext.tsx
src/context/auth.ts
```

Responsabilidades:

- obter sessao atual do Supabase;
- observar mudancas de autenticacao;
- carregar `profiles`;
- carregar permissao ativa de criador;
- expor `session`, `user`, `profile`, `isAdmin` e `canCreateTournaments`;
- oferecer `refreshProfile`, `refreshCreatorPermission` e `signOut`.

### Servicos de dados

Ficam em:

```text
src/services/tournaments.ts
src/services/tournamentCreatorRequests.ts
src/services/teams.ts
src/services/brackets.ts
src/services/rankings.ts
```

Responsabilidades:

- isolar chamadas ao Supabase;
- traduzir mensagens de erro tecnicas para mensagens de UI;
- aplicar pequenas regras de visualizacao no cliente;
- chamar RPCs do banco para acoes sensiveis.

### Algoritmos puros

Ficam em:

```text
src/lib/tournaments/singleElimination.ts
src/lib/tournaments/matchResults.ts
src/lib/tournaments/ranking.ts
```

Responsabilidades:

- gerar chave mata-mata simples;
- validar resultado de partida;
- calcular ranking de pontos corridos/grupos;
- manter logica testavel sem React e sem Supabase.

### Cliente Supabase e tipos

Ficam em:

```text
src/lib/supabase/client.ts
src/lib/supabase/types.ts
```

Responsabilidades:

- ler variaveis `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`;
- criar client tipado `createClient<Database>`;
- centralizar tipos de tabelas, enums e RPCs.

### Banco e seguranca

Fica em:

```text
supabase/schema.sql
```

Responsabilidades:

- criar enums, tabelas, indices e comentarios;
- ativar RLS;
- conceder grants minimos;
- definir policies;
- definir triggers e funcoes;
- validar regras de negocio no banco;
- oferecer RPCs transacionais.

## 8. Autenticacao e contexto

### `AuthProvider`

`AuthProvider` executa:

1. `supabase.auth.getSession()`.
2. Atualizacao local de `session`.
3. Busca do profile em `public.profiles`.
4. Busca de permissao ativa em `public.tournament_creator_permissions`.
5. Registro de listener `supabase.auth.onAuthStateChange`.

Estados derivados:

- `isAdmin`: `profile.role === 'admin'`.
- `canCreateTournaments`: admin ou permissao ativa em
  `tournament_creator_permissions`.

Ao sair:

1. chama `supabase.auth.signOut()`;
2. limpa sessao/profile/permissao;
3. navega para `#/login`.

### Tabela `profiles`

`profiles.id` referencia `auth.users(id)`. O banco nao armazena senha. Senha e
sempre responsabilidade do Supabase Auth.

Campos importantes:

- `id`
- `email`
- `display_name`
- `ra`
- `avatar_key`
- `role`
- `created_at`
- `updated_at`

`handle_new_auth_user()` cria ou atualiza profile quando um usuario e criado no
Supabase Auth.

`protect_profile_update()` impede usuario comum de alterar `role`, `email`,
`id` e `created_at`.

## 9. Permissoes e papeis

Papeis globais:

- `admin`: administrador global.
- `user`: usuario comum.

Permissao de organizador:

- nao altera `role`;
- fica em `tournament_creator_permissions`;
- e concedida por admin;
- pode ser revogada;
- e validada por `can_create_tournament()` e `can_manage_tournament()`.

Conceitos separados:

- `tournament_creator_requests`: historico de pedidos.
- `tournament_creator_permissions`: permissao efetiva ativa ou revogada.

Fluxo de permissao:

```text
usuario autenticado
  -> cria pedido em tournament_creator_requests
  -> admin aprova ou rejeita
  -> trigger validate_tournament_creator_request_update()
    -> se aprovado, cria permission active
  -> AuthProvider detecta permissao ativa
  -> usuario passa a poder criar torneios proprios
```

Funcoes SQL centrais:

- `is_admin()`
- `can_create_tournament(target_user_id default auth.uid())`
- `can_create_tournaments(...)`
- `can_manage_tournament(target_tournament_id)`
- `can_manage_team(target_team_id)`
- `is_team_member(target_team_id)`
- `is_match_participant(target_match_id)`

## 10. Banco de dados

O banco esta consolidado em `supabase/schema.sql`. Todas as tabelas importantes
possuem RLS habilitado.

### Enums

Enums criados ou usados:

- `user_role`: `admin`, `user`
- `registration_type`: `individual`, `team`
- `request_status`: `pending`, `approved`, `rejected`, `cancelled`
- `creator_permission_status`: `active`, `revoked`
- `team_status`: `draft`, `pending`, `confirmed`, `cancelled`, `rejected`
- `team_member_role`: `captain`, `member`
- `team_member_status`: `active`, `removed`
- `tournament_status`: `draft`, `registrations_open`, `registrations_closed`, `ongoing`, `finished`, `cancelled`
- `tournament_registration_status`: `pending`, `confirmed`, `cancelled`, `rejected`, `checked_in`, `registered`
- `bracket_seeding_method`: `draw`, `seeded`
- `bracket_match_status`: `pending`, `ready`, `bye`, `live`, `completed`, `disputed`, `cancelled`
- `match_result_status`: `confirmed`, `disputed`, `resolved`, `cancelled`

### Tabelas

#### `profiles`

Perfil do usuario vinculado a `auth.users`.

Interage com:

- Supabase Auth;
- `AuthProvider`;
- paginas de perfil;
- pedidos de permissao;
- torneios criados;
- auditoria de resultados.

#### `tournament_creator_requests`

Pedidos para receber permissao de criador de torneios.

Regras:

- usuario cria apenas pedido proprio;
- apenas um pedido pendente por usuario;
- usuario comum pode cancelar pedido pendente;
- admin aprova/rejeita;
- aprovacao cria permissao ativa por trigger.

#### `tournament_creator_permissions`

Permissoes efetivas para criar torneios.

Regras:

- apenas admin escreve;
- usuario comum pode ler as proprias permissoes;
- admin le todas;
- somente uma permissao ativa por usuario;
- reativacao deve criar nova linha, nao sobrescrever historico revogado.

#### `tournaments`

Tabela principal de torneios.

Campos relevantes:

- dados publicos: `name`, `slug`, `modality`, `description`, `campus`;
- formato/status: `format`, `status`;
- limite: `max_participants`;
- equipe: `registration_type`, `team_min_size`, `team_max_size`,
  `allow_free_agents`, `require_full_team_before_registration`,
  `team_registration_deadline`;
- datas: `starts_at`, `ends_at`;
- autoria: `created_by`.

Regras:

- draft nao e publico;
- criador com permissao ativa edita apenas torneios proprios;
- admin edita qualquer torneio;
- delete restrito a admin.

#### `tournament_registrations`

Inscricoes em torneios.

Campos relevantes:

- `tournament_id`
- `user_id`
- `team_id`
- `display_name`
- `status`
- `registration_type`
- `captain_user_id`
- `seed`
- `admin_notes`
- campos de decisao e cancelamento

Regras:

- novas inscricoes iniciam como `pending`;
- usuario comum cria apenas inscricao propria;
- usuario comum cancela apenas propria inscricao pendente ou confirmada antes
  do torneio iniciar;
- gestores confirmam, rejeitam, cancelam e fazem check-in;
- status legado `registered` e migrado para `confirmed`;
- participantes publicos sao `confirmed` ou `checked_in`.

#### `teams`

Equipes de torneios por equipe.

Campos relevantes:

- `tournament_id`
- `name`
- `status`
- `captain_id`
- `created_by`
- `registration_id`
- campos administrativos/de decisao/cancelamento

Regras:

- equipe so existe em torneio com `registration_type = team`;
- criador inicial deve ser capitao;
- novas equipes iniciam como `draft`;
- capitao, admin ou organizador autorizado podem gerenciar conforme status e
  prazo;
- equipe confirmada acompanha status da inscricao.

#### `team_members`

Membros de equipes.

Campos relevantes:

- `tournament_id`
- `team_id`
- `user_id`
- `role`
- `status`
- `added_by`
- `removed_by`
- `removed_at`

Regras:

- capitao e criado automaticamente por `handle_new_team()`;
- membro e localizado por email ou RA via RPC;
- usuario nao pode entrar em mais de uma equipe ativa no mesmo torneio;
- capitao nao pode ser removido no MVP;
- remocao e logica (`status = removed`).

#### `tournament_brackets`

Snapshot da chave mata-mata simples.

Campos relevantes:

- `tournament_id`
- `format`
- `seeding_method`
- `size`
- `rounds_count`
- `status`
- `winner_registration_id`
- `generated_by`
- `generated_at`

Regras:

- uma chave por torneio;
- formato atual da tabela e `single_elimination`;
- leitura publica para torneios nao draft;
- escrita por admin/organizador.

#### `bracket_matches`

Partidas/nos da chave.

Campos relevantes:

- rodada e posicao: `round_number`, `match_number`;
- participantes: `participant_a_registration_id`,
  `participant_b_registration_id`;
- placar: `score_a`, `score_b`;
- resultado: `winner_registration_id`;
- encadeamento: `next_match_id`, `next_match_slot`;
- estado: `status`, `is_bye`;
- auditoria de resultado: `submitted_by`, `submitted_at`, `confirmed_by`,
  `confirmed_at`, `result_notes`.

Regras:

- alteracoes de resultado e avanco devem usar RPC protegida;
- trigger `protect_bracket_match_update()` bloqueia escrita manual direta.

#### `match_results`

Resultado confirmado, contestado, resolvido ou cancelado.

Campos relevantes:

- `match_id`
- `bracket_id`
- `tournament_id`
- `score_a`
- `score_b`
- `winner_registration_id`
- `status`
- `notes`
- campos de envio, confirmacao, contestacao e resolucao

Regras:

- usuarios comuns nao inserem/alteram/deletam diretamente;
- registro/correcao usa `record_bracket_match_result()`;
- contestacao usa `contest_match_result()`;
- resolucao usa `resolve_match_dispute()`.

#### `match_result_history`

Historico imutavel de mudancas de resultado.

Registra:

- placar anterior/novo;
- vencedor anterior/novo;
- status anterior/novo;
- usuario que alterou;
- motivo;
- data.

Leitura:

- gestores do torneio;
- participantes da partida.

#### `tournament_standings`

Snapshot de ranking/classificacao por torneio ou grupo.

Campos relevantes:

- `tournament_id`
- `group_id`
- `scope`
- `status`
- `win_points`
- `draw_points`
- `loss_points`
- `tie_breakers`
- `calculated_by`
- `calculated_at`

Regras:

- leitura publica em torneios nao draft;
- escrita por admin/organizador autorizado;
- usuario comum nao manipula ranking manualmente.

#### `standing_entries`

Linhas do ranking salvo.

Campos relevantes:

- `standing_id`
- `tournament_id`
- `group_id`
- `participant_registration_id`
- `team_id`
- `display_name`
- `played`
- `wins`
- `draws`
- `losses`
- `score_for`
- `score_against`
- `score_diff`
- `points`
- `position`
- `tie_breaker_summary`
- `is_technical_tie`

Regras:

- estatisticas devem ser derivadas de resultados confirmados;
- leitura publica em torneios nao draft;
- escrita por gestor do torneio.

## 11. RLS e seguranca

Padroes de RLS:

- `anon` pode ler torneios publicados e dados publicos associados.
- `authenticated` pode ler dados proprios e publicos.
- `admin` pode auditar e administrar o sistema.
- organizador autorizado gerencia torneios que criou, enquanto mantiver
  permissao ativa.
- usuario comum nao altera ranking, resultados, permissoes, roles nem dados
  administrativos.

Policies importantes:

- `profiles_select_own`
- `profiles_select_admin`
- `profiles_update_own_without_role`
- `profiles_update_admin`
- `requests_insert_own`
- `requests_select_own`
- `requests_select_admin`
- `requests_cancel_own_pending`
- `requests_review_admin`
- `creator_permissions_select_own`
- `creator_permissions_select_admin`
- `creator_permissions_insert_admin`
- `creator_permissions_update_admin`
- `tournaments_select_public`
- `tournaments_select_owner`
- `tournaments_select_admin`
- `tournaments_insert_creator`
- `tournaments_update_owner`
- `tournaments_update_admin`
- `tournaments_delete_admin`
- `registrations_select_public_confirmed`
- `registrations_select_own`
- `registrations_select_manager`
- `registrations_insert_open_tournament`
- `registrations_cancel_own`
- `registrations_manage_tournament`
- `teams_select_public_confirmed`
- `teams_select_own`
- `teams_select_manager`
- `teams_insert_captain`
- `teams_update_manager_or_captain`
- `teams_delete_draft_manager_or_captain`
- `team_members_select_public_confirmed`
- `team_members_select_own_team`
- `team_members_select_manager`
- `team_members_insert_manager_or_captain`
- `team_members_update_manager_or_captain`
- `brackets_select_public`
- `brackets_select_manager`
- `brackets_insert_manager`
- `brackets_update_manager`
- `brackets_delete_manager`
- `bracket_matches_select_public`
- `bracket_matches_select_manager`
- `bracket_matches_insert_manager`
- `bracket_matches_update_manager`
- `bracket_matches_delete_manager`
- `match_results_select_public`
- `match_results_select_manager`
- `match_results_select_participant`
- `match_result_history_select_manager`
- `match_result_history_select_participant`
- `standings_select_public`
- `standings_select_manager`
- `standings_write_manager`
- `standing_entries_select_public`
- `standing_entries_select_manager`
- `standing_entries_write_manager`

## 12. Funcoes SQL e triggers importantes

### Funcoes de base

- `set_updated_at()`: atualiza `updated_at`.
- `is_admin()`: verifica se `auth.uid()` e admin.
- `can_create_tournament()`: valida admin ou permissao ativa.
- `can_create_tournaments()`: alias de compatibilidade.
- `bootstrap_first_admin(target_user_id)`: promove o primeiro admin via SQL
  Editor, sem grant para front-end.

### Profiles e permissoes

- `handle_new_auth_user()`: cria profile apos insert em `auth.users`.
- `protect_profile_update()`: protege campos sensiveis.
- `validate_tournament_creator_request_update()`: controla aprovacao,
  rejeicao e cancelamento de pedido.
- `validate_tournament_creator_permission_write()`: restringe escrita em
  permissoes efetivas.

### Torneios, inscricoes e equipes

- `can_manage_tournament(target_tournament_id)`: admin ou criador autorizado.
- `can_manage_team(target_team_id)`: admin, organizador ou capitao.
- `is_team_member(target_team_id)`: verifica membro ativo.
- `find_profile_for_team_member(identifier)`: busca exata por email ou RA.
- `get_team_members_with_profiles(target_team_id)`: lista membros com dados
  publicos minimos.
- `validate_team_write()`: valida criacao/edicao de equipe.
- `handle_new_team()`: insere capitao como membro.
- `validate_team_member_write()`: valida adicao/remocao de membros.
- `submit_team_registration(target_team_id)`: cria inscricao de equipe.
- `cancel_team(target_team_id, reason)`: cancela equipe e remove membros.
- `protect_tournament_update()`: protege autoria e criacao do torneio.
- `validate_tournament_registration_write()`: valida inscricoes.

### Chave e resultados

- `protect_bracket_match_update()`: bloqueia edicao direta de resultado.
- `complete_bracket_match(...)`: compatibilidade, chama registro de resultado.
- `record_bracket_match_result(...)`: registra/corrige resultado, audita e
  avanca vencedor.
- `contest_match_result(target_match_id, target_reason)`: participante contesta
  resultado finalizado.
- `resolve_match_dispute(...)`: gestor confirma ou cancela contestacao.
- `is_match_participant(target_match_id)`: verifica participacao direta,
  capitao ou membro ativo.

## 13. Servicos TypeScript

### `src/services/tournaments.ts`

Responsavel por torneios e inscricoes individuais.

Exporta:

- labels de status, formato e tipo de inscricao;
- listas de status ativos e publicos;
- `fetchTournaments()`;
- `fetchTournament()`;
- `createTournament()`;
- `updateTournament()`;
- `deleteTournament()`;
- `fetchTournamentRegistrations()`;
- `fetchMyTournamentRegistrations()`;
- `findActiveRegistration()`;
- `canUserCancelRegistration()`;
- `registerForTournament()`;
- `updateTournamentRegistrationStatus()`;
- `updateTournamentRegistrationSeed()`;
- `cancelTournamentRegistration()`;
- helpers `canManageTournament()`, `canDeleteTournament()`,
  `slugifyTournamentName()`.

Conexao:

```text
paginas de torneio
  -> tournaments.ts
    -> supabase.from('tournaments')
    -> supabase.from('tournament_registrations')
    -> RLS + triggers
```

### `src/services/tournamentCreatorRequests.ts`

Responsavel por pedidos e permissoes de criador.

Exporta:

- `fetchMyCreatorRequests()`;
- `fetchAllCreatorRequests()`;
- `fetchMyCreatorPermissions()`;
- `fetchAllCreatorPermissions()`;
- `createCreatorRequest()`;
- `cancelCreatorRequest()`;
- `reviewCreatorRequest()`;
- `revokeCreatorPermission()`.

Conexao:

```text
paginas de conta/admin
  -> tournamentCreatorRequests.ts
    -> tournament_creator_requests
    -> tournament_creator_permissions
    -> triggers de permissao
```

### `src/services/teams.ts`

Responsavel por equipes e membros.

Exporta:

- `fetchTeamMembers()`;
- `fetchTeamsForTournament()`;
- `fetchTeam()`;
- `createTeam()`;
- `updateTeamName()`;
- `findProfileForTeamMember()`;
- `addTeamMember()`;
- `removeTeamMember()`;
- `submitTeamRegistration()`;
- `deleteTeam()`;
- helpers `canEditTeam()` e `isTeamComplete()`.

Conexao:

```text
TournamentTeamsPage / TeamDetailsPage
  -> teams.ts
    -> teams
    -> team_members
    -> RPC get_team_members_with_profiles
    -> RPC find_profile_for_team_member
    -> RPC submit_team_registration
```

### `src/services/brackets.ts`

Responsavel por chave mata-mata e resultados.

Exporta:

- labels de seeding, status de partida e status de resultado;
- `fetchBracketParticipants()`;
- `fetchTournamentBracket()`;
- `generateTournamentBracket()`;
- `completeBracketMatch()`;
- `contestMatchResult()`;
- `resolveMatchDispute()`;
- `fetchMatchResultHistory()`.

Conexao:

```text
TournamentBracketPage
  -> brackets.ts
    -> singleElimination.ts para gerar estrutura local
    -> tournament_brackets / bracket_matches para persistir
    -> RPC record_bracket_match_result
    -> RPC contest_match_result
    -> RPC resolve_match_dispute
```

### `src/services/rankings.ts`

Responsavel por buscar dados e calcular ranking.

Exporta:

- `rankingSupportedFormats`;
- `isRankingFormatSupported()`;
- `getRankingUnsupportedReason()`;
- `fetchTournamentRanking()`.

Fluxo atual:

```text
TournamentRankingPage
  -> fetchTournamentRanking()
    -> fetchTournament()
    -> fetchBracketParticipants()
    -> fetchRankingMatches()
    -> calculateRanking()
```

Formatos suportados para ranking:

- `round_robin`
- `groups`
- `groups_playoffs`

Limite importante: ainda nao existe gerador real de pontos corridos/grupos. O
ranking atual calcula a partir das partidas existentes em `bracket_matches` e
`match_results`, quando o formato e suportado.

## 14. Algoritmos de torneio

### `singleElimination.ts`

Funcoes principais:

- `calculateNextPowerOfTwo(value)`;
- `calculateByeCount(participantCount)`;
- `generateSeedPositions(size)`;
- `applyDraw(participants, size, random)`;
- `applySeeding(participants, size, random)`;
- `generateFirstRoundMatches(slots)`;
- `generateNextRounds(size)`;
- `advanceParticipantWithBye(matches, match)`;
- `advanceWinner(matches, matchKeyToAdvance, winnerParticipantId)`;
- `validateCanGenerateBracket(params)`;
- `generateSingleEliminationBracket(params)`.

Regras:

- chave precisa de potencia de 2;
- byes sao preenchidos automaticamente;
- sorteio usa shuffle;
- seeding usa posicoes de seed e preenche restante por sorteio;
- partida com bye avanca vencedor automaticamente;
- geracao valida formato, status, quantidade de participantes e existencia de
  chave anterior.

### `matchResults.ts`

Funcoes principais:

- `isDrawAllowed(format)`;
- `canMatchReceiveResult(params)`;
- `determineWinner(params)`;
- `validateMatchResult(input)`;
- `validateContestReason(reason)`.

Regras:

- mata-mata simples e series melhor de N nao aceitam empate;
- pontos corridos e grupos podem aceitar empate no modelo TypeScript;
- partida com bye nao recebe resultado manual;
- partida precisa de dois participantes;
- resultado novo exige status `ready` ou `live`;
- correcao exige status `completed` ou `disputed` e justificativa minima.

### `ranking.ts`

Funcoes principais:

- `isRankingMatchCountable(match)`;
- `calculateRanking(params)`;
- `compareRankingEntries(first, second, matches, participantsById)`.

Configuracao padrao:

```text
vitoria = 3 pontos
empate = 1 ponto
derrota = 0 pontos
```

Estatisticas calculadas:

- posicao;
- participante;
- jogos;
- vitorias;
- empates;
- derrotas;
- score pro;
- score contra;
- saldo;
- pontos;
- resumo de desempate;
- indicador de empate tecnico.

Partidas ignoradas:

- status diferente de `completed`;
- resultado `disputed`;
- resultado `cancelled`;
- participante ausente;
- placar ausente;
- placar invalido ou negativo.

Criterios de desempate:

1. pontos;
2. vitorias;
3. saldo de score;
4. score pro;
5. confronto direto quando ha exatamente dois participantes comparados;
6. seed;
7. nome;
8. id como ultimo fallback estavel.

O sistema nao usa ordenacao aleatoria no ranking.

## 15. Paginas principais

### Autenticacao

`LoginPage`, `RegisterPage` e `PasswordRecoveryPage` usam `AuthLayout` e
formularios especificos.

Componentes:

- `LoginForm`: login com email/senha.
- `RegisterForm`: cadastro com email/senha, nome, RA e avatar.
- `PasswordRecoveryForm`: recuperacao por email.
- `LogoutButton`: encerra sessao pelo contexto.
- `UserMenu`: mostra login/cadastro ou dados do usuario autenticado.
- `AvatarPicker`: escolhe `avatar_key`.

### Conta

`MyAccountPage` mostra dados do profile, permissoes e formulario de edicao.

`ProfileForm` permite editar:

- `display_name`;
- `ra`;
- `avatar_key`.

Role e email sao bloqueados para usuario comum pelo banco.

### Pedidos de criador

`RequestTournamentCreatorPage` cria pedido de permissao.

`MyCreatorRequestsPage` lista pedidos e permissoes proprias.

`AdminCreatorRequestsPage` permite admin:

- ver todos os pedidos;
- aprovar/rejeitar;
- ver permissoes;
- revogar permissao ativa.

`AdminHomePage` serve como entrada administrativa.

### Lista de torneios

`TournamentsPage`:

- lista torneios retornados por RLS;
- filtra por texto e status;
- mostra cards com status, campus, modalidade, formato, inscritos e data;
- mostra acoes de pagina publica, participantes, chave, ranking, equipes;
- mostra editar para gestor;
- mostra excluir para admin.

### Criar e editar torneio

`CreateTournamentPage`:

- exige login;
- exige `canCreateTournaments`;
- usa `TournamentForm`;
- cria slug unico com parte de UUID.

`EditTournamentPage`:

- carrega torneio;
- valida permissao via helper e RLS;
- usa `TournamentForm`;
- mostra zona de risco para admin excluir.

`TournamentForm` coleta:

- nome;
- modalidade;
- campus;
- tipo de inscricao;
- limite de participantes;
- descricao;
- min/max de equipe;
- agentes livres futuro;
- exigencia de equipe minima;
- prazo para equipe;
- formato;
- status;
- datas.

### Pagina publica do torneio

`PublicTournamentPage`:

- mostra capa do torneio;
- exibe informacoes gerais;
- mostra links para participantes, chave, ranking e equipes;
- permite inscricao individual quando aberto;
- para torneio por equipe, direciona para tela de equipes;
- permite cancelamento da propria inscricao quando permitido;
- mostra participantes confirmados publicamente.

### Participantes

`TournamentParticipantsPage`:

- lista inscricoes;
- publico ve apenas confirmados/check-in;
- gestor ve fluxo completo;
- gestor pode confirmar, rejeitar, cancelar e marcar check-in;
- gestor pode salvar seed de participante;
- usa tabela responsiva com scroll controlado.

### Equipes

`TournamentTeamsPage`:

- funciona apenas para torneio por equipe;
- cria equipe quando usuario esta logado, torneio aceita equipe e inscricoes
  estao abertas;
- mostra cards de equipe;
- indica completa/incompleta.

`TeamDetailsPage`:

- mostra resumo de equipe;
- renomeia equipe;
- adiciona membro por email ou RA;
- remove membro nao capitao;
- envia equipe para inscricao;
- exclui equipe em rascunho.

### Chave

`TournamentBracketPage`:

- carrega torneio, chave, partidas, resultados e participantes;
- permite gestor gerar/regerar chave;
- permite escolher `draw` ou `seeded`;
- exibe rodadas por coluna/card;
- permite gestor registrar resultado;
- permite correcao com justificativa;
- permite participante contestar resultado;
- permite gestor resolver contestacao;
- permite visualizar historico de alteracoes.

### Ranking

`TournamentRankingPage`:

- carrega ranking calculado;
- exibe pontuacao configurada;
- exibe quantidade de participantes, partidas contabilizadas e ignoradas;
- exibe criterios de desempate;
- mostra aviso de formato nao suportado;
- mostra aviso de empate tecnico;
- mostra estado vazio sem partidas finalizadas;
- mostra botao de recalcular para gestor.

O botao de recalcular hoje recarrega e recalcula no front-end. Ele nao grava
snapshot em `tournament_standings`/`standing_entries`.

## 16. Layout e design

### Layout global

`AuthenticatedShell` monta:

```text
div.app-shell
  -> SiteHeader
  -> main.app-main
    -> PageLayout
      -> PageBackButton opcional
      -> children
```

`AuthLayout` e usado nas paginas de login/cadastro/recuperacao, com layout
proprio e link de retorno para home.

### `SiteHeader`

Responsavel por:

- marca "UTFPR Torneios";
- subtitulo contextual;
- navegacao principal;
- menu mobile;
- destaque de rota atual por `aria-current`;
- fechamento do menu ao navegar ou pressionar Escape;
- links condicionais por sessao/admin;
- CTA "Novo torneio", que direciona para criar torneio, pedir permissao ou
  login.

### `PageBackButton`

Responsavel por:

- botao "Voltar";
- usar `window.history.back()` quando possivel;
- usar fallback seguro quando nao ha historico.

### CSS

`src/index.css` define:

- tokens de cor;
- tokens de espacamento;
- raios;
- sombras;
- z-index;
- largura maxima;
- duracoes;
- reset basico;
- foco visivel;
- `prefers-reduced-motion`.

`src/App.css` define:

- header;
- navegacao;
- botoes;
- cards;
- formularios;
- tabelas;
- badges;
- estados de loading/erro/vazio/sucesso;
- bracket;
- ranking;
- auth pages;
- perfil;
- pedidos;
- equipes;
- responsividade.

Principios aplicados:

- mobile-first;
- HTML semantico;
- um `h1` por tela principal;
- labels em inputs;
- botoes reais para acoes;
- links reais para navegacao;
- foco visivel;
- tabelas com scroll controlado;
- badges com texto, nao apenas cor;
- estados de loading, vazio, erro e sucesso.

## 17. Dados mockados e demo legado

`src/data/mockData.ts` mantem dados estaticos de demonstracao:

- torneios;
- equipes;
- partidas;
- ranking;
- chaves;
- grupos;
- criterios de desempate;
- formatos.

Esses dados alimentam `TournamentDemoApp` dentro de `src/App.tsx`. A demo
permanece util como prototipo visual, mas nao e a fonte real de dados.

Fonte real:

```text
Supabase -> services -> paginas reais
```

Fonte demo:

```text
mockData.ts -> TournamentDemoApp -> paginas demo em App.tsx
```

## 18. Fluxos principais

### Login

```text
LoginForm
  -> supabase.auth.signInWithPassword
  -> AuthProvider detecta sessao
  -> busca profiles
  -> busca permissao ativa
  -> UI libera rotas/acoes conforme contexto
```

### Cadastro

```text
RegisterForm
  -> supabase.auth.signUp
  -> trigger on_auth_user_created
  -> handle_new_auth_user()
  -> cria public.profiles
```

### Primeiro admin

```text
SQL Editor Supabase
  -> select public.bootstrap_first_admin('<uuid-do-profile>');
  -> atualiza profiles.role para admin
```

Essa funcao nao deve ser chamada pelo front-end.

### Pedido para criar torneio

```text
RequestTournamentCreatorPage
  -> createCreatorRequest()
  -> tournament_creator_requests
  -> AdminCreatorRequestsPage
  -> reviewCreatorRequest(approved)
  -> validate_tournament_creator_request_update()
  -> tournament_creator_permissions active
  -> AuthProvider passa canCreateTournaments = true
```

### Criacao de torneio

```text
CreateTournamentPage
  -> TournamentForm
  -> createTournament()
  -> tournaments insert
  -> RLS tournaments_insert_creator
  -> can_create_tournament()
  -> protect_tournament_update() em updates futuros
```

### Inscricao individual

```text
PublicTournamentPage
  -> registerForTournament()
  -> tournament_registrations insert pending
  -> validate_tournament_registration_write()
  -> gestor confirma/rejeita/cancela em TournamentParticipantsPage
```

### Equipe

```text
TournamentTeamsPage
  -> createTeam()
  -> teams insert draft
  -> handle_new_team()
  -> team_members insert capitao
  -> TeamDetailsPage
    -> addTeamMember()
    -> submitTeamRegistration()
      -> tournament_registrations insert pending
      -> teams.status = pending
  -> gestor confirma inscricao
    -> teams.status = confirmed
```

### Chave mata-mata

```text
TournamentBracketPage
  -> fetchBracketParticipants()
  -> generateSingleEliminationBracket()
  -> tournament_brackets insert
  -> bracket_matches insert
  -> update next_match_id / next_match_slot
```

### Resultado

```text
TournamentBracketPage
  -> validateMatchResult()
  -> completeBracketMatch()
  -> RPC record_bracket_match_result()
    -> valida gestor
    -> valida placar
    -> cria/atualiza match_results
    -> cria match_result_history
    -> atualiza bracket_matches
    -> avanca vencedor
```

### Contestacao

```text
participante da partida
  -> contestMatchResult()
  -> RPC contest_match_result()
    -> match_results.status = disputed
    -> bracket_matches.status = disputed
    -> match_result_history

gestor
  -> resolveMatchDispute(confirm | cancel)
  -> RPC resolve_match_dispute()
    -> confirma resultado ou cancela para novo lancamento
```

### Ranking

```text
TournamentRankingPage
  -> fetchTournamentRanking()
  -> fetchTournament()
  -> fetchBracketParticipants()
  -> fetchRankingMatches()
  -> calculateRanking()
  -> tabela de classificacao
```

Partidas contestadas e canceladas nao entram no calculo.

## 19. Como os sistemas se conectam

### Autenticacao conecta com permissao

`AuthProvider` le `profiles` e `tournament_creator_permissions`. Isso alimenta:

- `SiteHeader`;
- `ProtectedRoute`;
- `AdminRoute`;
- paginas de criacao/edicao;
- botoes administrativos;
- helpers `canManageTournament`.

### Torneio conecta com inscricao

`tournaments.id` e chave estrangeira em:

- `tournament_registrations`;
- `teams`;
- `team_members`;
- `tournament_brackets`;
- `bracket_matches`;
- `match_results`;
- `tournament_standings`;
- `standing_entries`.

Excluir torneio causa cascade em dados dependentes configurados com `on delete
cascade`, exceto referencias protegidas/restritas conforme tabela.

### Inscricao conecta com chave e ranking

`tournament_registrations.id` identifica participante individual ou equipe.
Esse id e usado em:

- `bracket_matches.participant_a_registration_id`;
- `bracket_matches.participant_b_registration_id`;
- `bracket_matches.winner_registration_id`;
- `match_results.winner_registration_id`;
- `standing_entries.participant_registration_id`.

### Equipe conecta com inscricao

`teams.id` aparece em:

- `tournament_registrations.team_id`;
- `team_members.team_id`;
- `standing_entries.team_id`.

No MVP, a inscricao por equipe e representada por uma linha em
`tournament_registrations` ligada ao capitao e a `team_id`.

### Resultado conecta com historico

`match_results.match_id` e unico. Cada partida tem no maximo um resultado
corrente. Alteracoes sao registradas em `match_result_history`.

### Ranking conecta com resultados

O ranking visual atual e calculado em TypeScript a partir de:

- participantes confirmados/check-in;
- `bracket_matches`;
- `match_results`.

As tabelas `tournament_standings` e `standing_entries` preparam snapshots de
ranking persistido, mas ainda nao ha servico gravando snapshots no front-end.

## 20. Tipos TypeScript

`src/lib/supabase/types.ts` espelha o schema manualmente.

Tipos principais:

- `Profile`
- `TournamentCreatorRequest`
- `TournamentCreatorPermission`
- `Tournament`
- `TournamentRegistration`
- `Team`
- `TeamMember`
- `TeamMemberWithProfile`
- `TournamentBracket`
- `BracketMatch`
- `MatchResult`
- `MatchResultHistory`
- `TournamentStanding`
- `StandingEntry`
- `Database`

O client Supabase usa:

```ts
createClient<Database>(url, anonKey, ...)
```

Isso ajuda a tipar `from(...)`, inserts, updates e RPCs.

## 21. Componentes de UI

### Componentes de autenticacao

- `AdminRoute`: exige login e admin.
- `ProtectedRoute`: exige login.
- `AuthLayout`: layout das telas de auth.
- `AvatarPicker`: escolha de avatar predefinido.
- `CreatorPermissionCard`: card de permissao ativa/revogada.
- `CreatorPermissionStatusBadge`: badge de permissao.
- `CreatorRequestCard`: card de pedido.
- `CreatorRequestStatusBadge`: badge de pedido.
- `LoginForm`: formulario de login.
- `LogoutButton`: logout.
- `PasswordRecoveryForm`: recuperacao.
- `ProfileForm`: edicao de perfil.
- `RegisterForm`: cadastro.
- `UserMenu`: menu de usuario no header.

### Componentes de layout

- `AuthenticatedShell`: shell principal autenticado/publico com header.
- `PageBackButton`: retorno.
- `PageLayout`: cabecalho padrao de pagina e retorno.
- `SiteHeader`: navegacao global.

### Componentes de torneio

- `TournamentForm`: formulario de criacao/edicao.
- `TournamentStatusBadge`: status de torneio.
- `TournamentRegistrationStatusBadge`: status de inscricao.
- `TeamStatusBadge`: status de equipe.

## 22. Design system real

Tokens reais em `index.css`:

- cores principais: azul institucional (`--color-primary`) e verde
  competitivo (`--color-accent`);
- superficies claras;
- estados danger, warning, info e success/accent;
- raio padrao 8px;
- cards com borda e sombra leve;
- max page de 1180px;
- foco com outline verde;
- respeito a `prefers-reduced-motion`.

Padrao visual:

- academico;
- limpo;
- dashboard;
- focado em tabelas, cards e gestao;
- sem dependencia de biblioteca de componentes.

Componentes visuais recorrentes:

- `.app-header`
- `.primary-nav`
- `.button`
- `.surface-panel`
- `.tournament-card`
- `.team-card`
- `.participant-card`
- `.bracket-match`
- `.badge`
- `.field`
- `.table-scroll`
- `.empty-state`
- `.loading-state`
- `.form-message`

## 23. Status de implementacao por modulo

Esta matriz evita ambiguidade entre arquitetura desejada e codigo existente.
Ela deve ser atualizada sempre que uma funcionalidade sair de `Parcial` ou
`Pendente`.

| Area | Status | Fonte atual | Observacoes |
| --- | --- | --- | --- |
| Autenticacao email/senha | Implementado | Supabase Auth, `AuthProvider`, telas de login/cadastro/recuperacao | Senha fica no Supabase Auth; nao ha tabela propria de senha. |
| Perfis de usuario | Implementado | `profiles`, `ProfileForm`, `AvatarPicker` | Usuario comum edita apenas campos permitidos; role e email sao protegidos no banco. |
| Papel admin/user | Implementado | enum `user_role`, `is_admin()`, `AdminRoute` | Primeiro admin exige bootstrap manual por SQL. |
| Pedido de permissao para criar torneios | Implementado | `tournament_creator_requests`, paginas de pedido/admin | Pedido e historico separado da permissao ativa. |
| Permissao ativa de criador | Implementado | `tournament_creator_permissions`, `can_create_tournament()` | Permissao pode ser revogada; usuario aprovado nao vira admin. |
| CRUD de torneios | Implementado | `tournaments`, `TournamentForm`, services | Admin pode excluir; criador autorizado gerencia apenas seus torneios. |
| Listagem publica de torneios | Implementado | `TournamentsPage`, RLS de torneios publicados | Draft nao deve aparecer publicamente. |
| Inscricao individual | Implementado | `tournament_registrations`, pagina publica e participantes | Nova inscricao inicia `pending`; gestor confirma/rejeita/check-in. |
| Check-in | Implementado | `requires_check_in`, janela em `tournaments`, RPCs e paginas publica/participantes | Janela formal, auto check-in, check-in manual e filtro de chave implementados. |
| Equipes | Implementado | `teams`, `team_members`, paginas de equipes | Inclui capitao automatico, membros por email/RA e envio para inscricao. |
| Agentes livres | Pendente | campos em `tournaments` | `allow_free_agents` esta preparado, mas fluxo nao existe. |
| Mata-mata simples | Implementado | `singleElimination.ts`, `tournament_brackets`, `bracket_matches` | Gera chave, byes, seeded/draw e avanco de vencedor. |
| Series melhor de N | Pendente | docs e tipos de resultado | Nao ha tabela `match_games` nem fluxo de serie. |
| Pontos corridos | Parcial | ranking TypeScript e tabelas de snapshot | Falta gerador de partidas round robin e persistencia oficial do ranking. |
| Fase de grupos | Parcial | ranking TypeScript e `group_id` em standings | Falta gerador de grupos, vinculo formal grupo-participante e tabela de partidas de grupo. |
| Grupos + playoffs | Parcial | formato aceito no ranking | Falta pipeline completo grupo -> classificados -> chave playoff. |
| Sistema suico | Futuro | docs | Nao ha modelo de rodadas, pareamento ou criterios Buchholz persistidos. |
| Scheduling | Pendente | campos basicos em `bracket_matches` nao existem para agenda real | Faltam data, hora, local/servidor, deteccao de conflito e tempo minimo entre partidas. |
| Registro de resultado | Implementado | `record_bracket_match_result()`, UI de chave | Fluxo atual cobre mata-mata simples sem empate. |
| W.O. | Implementado | `result_type = walkover`, `record_bracket_match_walkover()`, historico e UI de chave | Exige vencedor/justificativa, marca no-show, permite contestacao e afeta ranking sem saldo. |
| Desclassificacao | Implementado | campos derivados em `tournament_registrations`, RPC e tela de participantes | Exige justificativa, audita e remove de novas chaves. |
| Contestacao e resolucao | Implementado | `contest_match_result()`, `resolve_match_dispute()` | Participante contesta; gestor resolve com observacao. |
| Historico de resultados | Implementado | `match_result_history` | Historico e restrito a gestor ou participante autenticado. |
| Ranking basico | Implementado | `ranking.ts`, `TournamentRankingPage` | Calcula no cliente a partir de partidas disponiveis. |
| Snapshot oficial de ranking | Parcial | `tournament_standings`, `standing_entries` | Schema e RLS existem; falta servico/RPC para gravar snapshot. |
| Painel do organizador | Parcial | edicao, participantes, chave, equipes | Nao existe dashboard dedicado com metricas e alertas. |
| Painel admin | Parcial | `AdminHomePage`, `AdminCreatorRequestsPage` | Cobre pedidos/permissoes, auditoria geral e bloqueios; falta configuracao global completa. |
| Pagina publica do torneio | Implementado | `PublicTournamentPage` | Mostra dados, participantes e acoes de inscricao conforme tipo. |
| Auditoria geral | Parcial | `audit_logs`, triggers e historico de resultados | Base generica implementada; faltam IP/user-agent e cobertura de modulos futuros. |
| Bloqueios administrativos | Parcial | `action_locks`, RLS, painel admin e triggers | Bloqueia acoes principais; faltam configuracoes globais e integracao visual em todas as telas publicas. |
| Notificacoes | Futuro | docs | Nao ha modelo nem UI. |
| Responsividade/acessibilidade | Parcial | CSS global, componentes, checklist | Ha padrao aplicado, mas precisa validacao periodica em 320px, teclado e leitor de tela. |
| Testes automatizados | Pendente | scripts `lint` e `build` apenas | Nao ha runner de testes unitarios/componentes/RLS configurado. |

## 24. Arquitetura-alvo do MVP

A arquitetura-alvo do MVP deve preservar o formato atual de aplicacao React
monolitica, mas fechar lacunas de dominio e operacao sem introduzir
complexidade desnecessaria.

### Fronteiras de responsabilidade

| Camada | Responsabilidade | Nao deve fazer |
| --- | --- | --- |
| Paginas React | Orquestrar tela, estado visual e chamadas de servico | Guardar regra sensivel de permissao como unica barreira |
| Componentes | Renderizar controles, formularios, badges, cards e tabelas | Buscar dados administrativos sem passar por servico |
| Contexto de auth | Expor sessao, profile e permissoes derivadas | Decidir seguranca final de escrita |
| Services | Isolar Supabase, traduzir erros e chamar RPCs | Reimplementar policies do banco como fonte definitiva |
| Algoritmos puros | Gerar chave, validar resultado, calcular ranking | Importar React, CSS ou Supabase |
| Supabase/PostgreSQL | Persistir estado, validar RLS, executar RPCs sensiveis | Expor segredo ou depender de logica do navegador |
| Docs | Registrar decisoes, contratos e status real | Esconder diferencas entre implementado e planejado |

### Fluxo desejado por recurso

Qualquer recurso novo deve seguir este fluxo:

```text
docs/regras e contratos
  -> schema.sql ou migration com RLS
  -> tipos em src/lib/supabase/types.ts
  -> funcao pura se houver regra de dominio
  -> service Supabase
  -> pagina/componente React
  -> estados loading/erro/vazio/sucesso
  -> lint/build/testes aplicaveis
```

Quando a acao mudar estado sensivel, a decisao final deve estar no banco por
policy, trigger ou RPC. A UI pode bloquear botoes para melhorar experiencia,
mas nao deve ser a barreira de seguranca.

### Modulos que fecham o MVP

Para considerar a arquitetura completa no MVP, ainda faltam estes fechamentos:

- criar gerador de partidas de pontos corridos;
- criar gerador de grupos e classificados para playoffs;
- persistir snapshots de ranking oficial/provisorio;
- modelar agenda real de partidas;
- definir auditoria generica para acoes administrativas;
- configurar testes automatizados de algoritmos e RLS;
- inicializar Supabase CLI quando o fluxo local for adotado;
- criar migrations incrementais para novas mudancas de schema.

## 25. Decisoes arquiteturais

### ADR-001: Supabase como backend principal

Decisao: usar Supabase Auth, PostgreSQL, RLS e RPCs para persistencia,
autenticacao e autorizacao.

Motivo: reduz infraestrutura propria, oferece Auth seguro, integra bem com
TypeScript e permite validar permissao no banco.

Consequencia: o cliente usa apenas `VITE_SUPABASE_URL` e
`VITE_SUPABASE_ANON_KEY`; qualquer chave `service_role` fica fora do front-end.

### ADR-002: RLS como barreira real de autorizacao

Decisao: a UI pode ocultar acoes, mas a autorizacao final vive no banco.

Motivo: usuario pode manipular requests no navegador; RLS, triggers e RPCs
protegem o dado mesmo quando a interface falha.

Consequencia: toda tabela importante precisa de RLS habilitado e policies
coerentes com `auth.uid()`, `is_admin()` e `can_manage_tournament()`.

### ADR-003: Permissao de criador separada de role global

Decisao: `admin` e permissao de criar torneios sao conceitos diferentes.

Motivo: usuario pode organizar torneios sem ter acesso administrativo global.

Consequencia: pedidos ficam em `tournament_creator_requests`; autorizacao ativa
fica em `tournament_creator_permissions`; revogacao nao apaga historico.

### ADR-004: Algoritmos de torneio fora da UI

Decisao: regras de chave, resultado e ranking ficam em `src/lib/tournaments`.

Motivo: facilita teste, manutencao e evolucao para novos formatos.

Consequencia: componentes React chamam funcoes puras ou services; algoritmo nao
importa React, CSS nem Supabase.

### ADR-005: Roteamento manual por hash no estado atual

Decisao atual: manter roteamento em `src/App.tsx` com `window.location.hash`.

Motivo: o projeto ja funciona assim e a troca para React Router seria refactor
transversal.

Consequencia: novas rotas devem ser registradas em `AppRouter` e testadas com
links `#/...`. Migrar para React Router so deve ocorrer quando houver ganho
claro de manutencao.

### ADR-006: CSS proprio com tokens globais

Decisao: manter CSS proprio em `src/index.css` e `src/App.css`.

Motivo: evita dependencia de biblioteca visual e preserva controle sobre
identidade academica/profissional.

Consequencia: qualquer componente novo deve usar tokens, `gap`, foco visivel,
responsividade mobile-first e estados hover/focus/active/disabled.

### ADR-007: Documento de arquitetura como fonte de alinhamento

Decisao: este arquivo registra a implementacao real e a arquitetura-alvo.

Motivo: o projeto tem docs planejados e codigo real evoluindo; sem matriz de
status, fica facil confundir desejo com entrega.

Consequencia: mudancas relevantes em schema, rotas, services, regras de
torneio ou seguranca devem atualizar este documento ou os docs especializados.

## 26. Ambientes, configuracao e deploy

### Ambientes recomendados

| Ambiente | Objetivo | Banco Supabase | Observacoes |
| --- | --- | --- | --- |
| Local | Desenvolvimento individual | Projeto Supabase local ou remoto de dev | Nunca usar dados reais sensiveis. |
| Staging | Validacao antes de producao | Projeto separado de producao | Deve receber migrations e build antes de producao. |
| Producao | Uso real | Projeto Supabase isolado | RLS, backups e chaves revisadas. |

### Variaveis de ambiente

Obrigatorias no front-end:

```text
VITE_SUPABASE_URL
VITE_SUPABASE_ANON_KEY
```

Regras:

- criar `.env.local` apenas no ambiente do desenvolvedor;
- nunca commitar `.env`, `.env.local`, `.env.*.local`, chaves privadas ou
  `service_role`;
- manter `.env.example` sem valores reais, apenas com os nomes das variaveis;
- revisar o build para garantir que nenhuma chave privada aparece em assets
  gerados.

### Deploy recomendado

O deploy do front-end pode ser feito em qualquer host compativel com Vite,
como Vercel, Netlify, Cloudflare Pages ou GitHub Pages com configuracao de
SPA/hash routing.

Fluxo minimo antes de publicar:

```bash
npm install
npm run lint
npm run build
```

Para Supabase:

- aplicar schema/migrations no ambiente correto;
- validar RLS antes de apontar o front-end para producao;
- promover primeiro admin via SQL seguro;
- testar usuario anonimo, usuario comum, criador autorizado e admin.

## 27. Banco, migrations e evolucao de schema

### Estado atual

O schema principal continua concentrado em `supabase/schema.sql`. Ele cria
enums, tabelas, indices, triggers, policies, grants e RPCs.

Esse arquivo e o bootstrap consolidado para ambientes novos. A pasta
`supabase/migrations/` existe para mudancas incrementais futuras e contem um
README de orientacao. Nenhuma migration inicial gigante foi duplicada nesta
etapa para evitar duas fontes extensas divergentes antes da Supabase CLI estar
inicializada.

Ainda nao ha `supabase/config.toml`.

### Processo recomendado

1. Criar ou alterar tabela/enum/funcoes em migration versionada dentro de
   `supabase/migrations/`.
2. Atualizar RLS e grants na mesma mudanca.
3. Atualizar comentarios SQL quando a regra mudar.
4. Atualizar `supabase/schema.sql` para manter o bootstrap consolidado.
5. Atualizar `src/lib/supabase/types.ts` ou gerar tipos pela Supabase CLI.
6. Atualizar services afetados.
7. Atualizar docs de modelo, API e arquitetura.
8. Testar com perfis `anon`, `authenticated user`, criador autorizado e admin.

### Regras para migrations futuras

- Nunca depender de `drop table cascade` em producao sem plano de migracao.
- Manter dados historicos de permissoes, inscricoes, resultados e disputas.
- Preferir colunas novas nullable ou com default quando houver dados
  existentes.
- Para mudancas destrutivas, criar migration em fases: adicionar, backfill,
  migrar leitura/escrita, remover depois.
- Toda tabela nova com dado de negocio deve sair com RLS habilitado.
- Toda RPC `security definer` deve fixar `search_path` e receber grants
  explicitos.

### Tipos TypeScript

`src/lib/supabase/types.ts` hoje espelha o schema manualmente. Em uma etapa
futura, o projeto pode gerar tipos pelo Supabase CLI para reduzir divergencia,
mas os tipos gerados devem ser revisados antes de substituir os manuais.

## 28. Estrategia de testes e qualidade

### Estado atual

Comandos disponiveis:

```bash
npm run lint
npm run build
```

Nao ha runner de testes unitarios, de componente, E2E ou RLS configurado no
`package.json`.

### Piramide recomendada

| Tipo | Ferramenta sugerida | Escopo |
| --- | --- | --- |
| Unitario de dominio | Vitest | `singleElimination.ts`, `matchResults.ts`, `ranking.ts` |
| Componente | React Testing Library | formularios, badges, tabelas, estados vazio/erro/loading |
| E2E | Playwright | cadastro/login, pedido de permissao, inscricao, chave, resultado |
| Banco/RLS | Supabase local + SQL tests | policies, triggers, RPCs e grants |
| Acessibilidade | axe/Playwright + revisao manual | foco, labels, contraste, navegacao por teclado |

### Casos minimos de dominio

- mata-mata com 2, 3, 4, 5, 8 e 16 participantes;
- byes avancando corretamente;
- seed evitando confronto precoce entre favoritos;
- resultado invalido com empate em mata-mata;
- correcao de resultado exigindo justificativa;
- ranking com pontos, vitorias, saldo, confronto direto e empate tecnico;
- partidas contestadas/canceladas ignoradas no ranking.

### Casos minimos de seguranca

- anonimo ve apenas torneios publicados;
- usuario comum nao altera role, permissao, ranking nem resultado;
- usuario comum cancela apenas propria inscricao permitida;
- criador autorizado cria torneio e gerencia apenas torneios proprios;
- permissao revogada bloqueia novas criacoes/gerencia conforme regra;
- admin aprova/rejeita pedidos, revoga permissoes e resolve disputas.

### Criterio de pronto

Uma mudanca so deve ser considerada pronta quando:

- lint e build passam;
- estado vazio, loading, erro e sucesso foram tratados;
- telas funcionam de 320px ate desktop;
- foco visivel e labels foram preservados;
- regra sensivel esta no banco quando envolve autorizacao;
- docs afetados foram atualizados.

## 29. Observabilidade, auditoria e LGPD

### Auditoria existente

O sistema registra historico especifico para resultados em
`match_result_history` e possui auditoria geral em `audit_logs`.

`audit_logs` registra `actor_id`, `action`, `entity_type`, `entity_id`,
`tournament_id`, `before_data`, `after_data`, `reason` e `created_at`.
`ip_address` e `user_agent` existem como campos opcionais, mas permanecem
nulos ate existir camada server/Edge Function capaz de capturar metadados de
requisicao com confianca.

Eventos cobertos nesta etapa:

- alteracao de role;
- decisao de pedidos de criador;
- concessao e revogacao de permissoes;
- criacao, edicao e exclusao de torneios;
- decisao/cancelamento/check-in de inscricoes e alteracao manual de seed;
- geracao/remocao de chave;
- registro, correcao, contestacao e resolucao de resultado;
- criacao, alteracao e remocao de bloqueios administrativos.

### Auditoria pendente

Ainda falta cobrir modulos que nao existem ou continuam parciais:

- configuracoes globais;
- agenda real;
- grupos e round robin persistidos;
- W.O. e desclassificacao formal;
- snapshots oficiais de ranking via RPC;
- IP e user-agent por camada server.

### Logs operacionais

No front-end, erros devem ser tratados para o usuario sem vazar detalhes
internos. Em producao, pode ser adicionado provedor de monitoramento, desde que
nao capture senha, token, RA, email ou dados pessoais sem necessidade.

### LGPD e dados pessoais

Dados como email e RA devem ser tratados como pessoais. A arquitetura deve
seguir estes principios:

- coletar apenas o necessario;
- nao exibir RA/email em paginas publicas;
- limitar busca de usuario por email/RA a fluxos autenticados e exatos;
- restringir dados administrativos por RLS;
- evitar upload de avatar pessoal no MVP;
- preservar auditoria com minimo dado necessario;
- planejar anonimimizacao/retencao antes de uso real em producao.

## 30. Contratos de evolucao por dominio

### Scheduling

Arquitetura pendente:

- adicionar campos ou tabela de agenda com `scheduled_at`, `location`,
  `server_url`, `stage`, `duration_minutes` e `status`;
- detectar conflito por participante/equipe;
- respeitar intervalo minimo entre partidas;
- permitir remarcacao com auditoria;
- expor calendario por torneio e por participante.

### Pontos corridos

Arquitetura pendente:

- criar gerador round robin simples e duplo;
- persistir partidas geradas em estrutura compativel com resultados/ranking;
- permitir empate quando formato aceitar;
- recalcular ranking a partir de resultados confirmados;
- gravar snapshot oficial quando organizador publicar classificacao.

### Grupos + playoffs

Arquitetura pendente:

- modelar grupos e participantes por grupo;
- gerar confrontos dentro do grupo;
- configurar quantidade de classificados;
- registrar desempates e empates tecnicos;
- gerar chave playoff a partir dos classificados;
- manter rastro de origem do classificado no playoff.

### Melhor de N

Arquitetura pendente:

- modelar jogos individuais dentro da partida;
- validar quantidade impar de jogos;
- calcular vencedor da serie;
- permitir placar agregado e placares por jogo;
- impedir resultado final incoerente com jogos vencidos.

### Sistema suico

Arquitetura futura:

- modelar rodadas suicas;
- parear participantes com pontuacao semelhante;
- evitar repeticao de confronto quando possivel;
- calcular Buchholz ou criterio equivalente;
- registrar pareamentos e justificativas.

### W.O. e desclassificacao

Estado implementado:

- W.O. usa `match_results.result_type = walkover` e RPC `record_bracket_match_walkover`;
- vencedor e justificativa administrativa sao obrigatorios;
- perdedor recebe `no_show_at` e o vencedor avanca na chave;
- historico registra `previous_result_type` e `new_result_type`;
- ranking conta W.O. como vitoria/derrota sem saldo de score;
- desclassificacao usa `disqualified_at`, `disqualified_by` e `disqualification_reason`;
- participantes desclassificados ou com no-show ficam fora de novas chaves.

Pendente:

- parametrizar pontuacao/penalidade de W.O. por modalidade;
- fluxo de reversao de desclassificacao com dupla aprovacao;
- politica automatica para W.O. recorrente.

### Configuracoes globais e bloqueios

Estado atual:

- `action_locks` existe com escopos `global`, `tournament`, `registration`,
  `team`, `match` e `ranking`;
- triggers e helpers `is_action_locked()`/`assert_action_unlocked()` validam
  bloqueios no banco para acoes principais;
- painel admin permite listar, criar, editar motivo, ativar/desativar e remover
  bloqueios com auditoria.

Pendente:

- criar `global_settings` para parametros administrativos;
- integrar leitura de bloqueios em todas as telas para mensagens preventivas;
- criar politicas especificas para configuracoes globais quando a tabela existir.

## 31. Limites atuais

Pontos importantes do estado atual:

- O roteamento e manual por hash, nao usa React Router.
- Ainda existem paginas demo dentro de `src/App.tsx`.
- `mockData.ts` ainda alimenta a experiencia demo.
- A arquitetura recomendada em `docs/06-arquitetura.md` cita pastas
  `domain/`, `styles/` e `components/ui/`, mas a implementacao real atual usa
  `src/lib/tournaments`, `src/services` e CSS global.
- Mata-mata simples esta implementado; round robin e grupos ainda nao possuem
  gerador de partidas real.
- Ranking basico existe como calculo TypeScript e tela, mas snapshot SQL ainda
  nao e gravado pela UI.
- `matchResults.ts` prepara empate para formatos de tabela, mas a RPC SQL de
  resultado atual ainda valida placar sem empate para o fluxo de mata-mata.
- Sistema suico, Elo, estatisticas avancadas, W.O. completo e scheduling real
  ainda nao estao implementados.

## 32. Checklist de manutencao

Ao alterar uma funcionalidade:

1. Criar migration incremental quando alterar o banco.
2. Atualizar tipos em `src/lib/supabase/types.ts` quando alterar o schema.
3. Atualizar `supabase/schema.sql` com RLS, grants e policies.
4. Garantir que regra sensivel esteja no banco, nao so no React.
5. Manter funcoes puras em `src/lib/tournaments` quando a logica puder ser
   testada fora da UI.
6. Manter chamadas ao Supabase isoladas em `src/services`.
7. Preservar estados de loading, erro, sucesso e vazio.
8. Verificar responsividade de 320px a desktop.
9. Usar labels, botoes reais, links reais e foco visivel.
10. Rodar `npm run lint`.
11. Rodar `npm run build`.
12. Atualizar docs relacionados em `docs/`.

## 33. Como aplicar o schema no Supabase

Para um projeto novo ou ambiente atualizado:

1. Abrir o SQL Editor do Supabase.
2. Executar o conteudo de `supabase/schema.sql`.
3. Criar um usuario via app ou Supabase Auth.
4. Pegar o UUID do usuario em `auth.users`/`profiles`.
5. Promover o primeiro admin manualmente:

```sql
select public.bootstrap_first_admin('UUID_DO_PROFILE_AQUI');
```

Depois disso:

- admin consegue aprovar permissoes;
- usuario comum consegue pedir permissao;
- criador autorizado consegue criar torneios proprios;
- RLS continua controlando leitura/escrita.

O guia operacional completo fica em `supabase/README.md`.

## 34. Onde testar cada area

Autenticacao:

- `#/cadastro`
- `#/login`
- `#/minha-conta`

Permissoes:

- `#/solicitar-criacao-torneio`
- `#/meus-pedidos`
- `#/admin/pedidos`

Torneios:

- `#/torneios`
- `#/torneios/novo`
- `#/torneios/:id`
- `#/torneios/:id/editar`

Inscricoes:

- `#/torneios/:id`
- `#/torneios/:id/participantes`
- `#/minhas-inscricoes`

Equipes:

- `#/torneios/:id/equipes`
- `#/torneios/:id/equipes/:teamId`

Chave e resultados:

- `#/torneios/:id/chave`

Ranking:

- `#/torneios/:id/ranking`

## 35. Resumo arquitetural

O projeto esta organizado como uma aplicacao React monolitica com camadas bem
definidas:

```text
UI React
  -> Contexto de auth
  -> Services Supabase
  -> Algoritmos puros quando aplicavel
  -> Supabase client tipado
  -> PostgreSQL com RLS e RPCs
```

O banco e a fonte de verdade para seguranca e estado persistente. O front-end
controla experiencia, validacoes iniciais e visualizacao. Algoritmos de
torneio ficam fora da UI para permitir teste e evolucao.

## Atualizacao operacional: check-in, W.O. e desclassificacao

### Check-in formal

O check-in deixa de ser apenas um status manual e passa a ter janela formal no torneio:

- `tournaments.requires_check_in` define se a chave exige presenca confirmada.
- `check_in_opens_at` e `check_in_closes_at` definem a janela.
- Usuario confirmado usa `confirm_registration_check_in` dentro da janela.
- Admin/organizador usa `set_registration_check_in` para marcar ou desfazer check-in, com justificativa no desfazer.

A geracao de chave filtra inscritos sem `checked_in_at` quando `requires_check_in = true`, e o banco valida participantes de `bracket_matches` por `is_registration_bracket_eligible`.

### W.O.

W.O. e representado por `match_results.result_type = walkover`, nao por placar comum. O placar fisico do resultado permanece tecnico para compatibilidade, mas a UI e ranking usam `result_type`.

Regras implementadas:

- vencedor obrigatorio;
- justificativa obrigatoria;
- historico em `match_result_history`;
- perdedor recebe `no_show_at`/`no_show_reason`;
- vencedor avanca no mata-mata;
- participante pode contestar, admin/organizador resolve.

No ranking, W.O. conta como vitoria/derrota e nao altera saldo de score.

### Desclassificacao

Desclassificacao fica na inscricao por campos derivados:

- `disqualified_at`;
- `disqualified_by`;
- `disqualification_reason`.

Usuario comum nao executa desclassificacao. Admin/organizador deve informar justificativa. Novas chaves ignoram participantes desclassificados. Se a chave ja existir, a resolucao recomendada e registrar W.O. do adversario ou usar `action_locks` para bloquear a operacao ate decisao manual.

## Atualizacao visual: design system UTFPR

### Escopo da mudanca

A camada visual foi consolidada em `src/index.css` e `src/App.css` sem alterar
RLS, schema Supabase, services, algoritmos ou regras de negocio.

`src/index.css` concentra tokens e base global:

- paleta institucional UTFPR com `--color-brand-black`, `--color-brand-black-2`,
  `--color-brand-yellow`, `--color-brand-yellow-2` e
  `--color-brand-yellow-soft`;
- neutros de fundo, superficie, texto e borda;
- cores funcionais para sucesso, erro, aviso e informacao;
- escala de espacos, raios, sombras, containers, z-index e duracoes;
- reset global, foco visivel, selecao de texto e `prefers-reduced-motion`.

`src/App.css` concentra a implementacao visual:

- layout global, header, navegacao e botao de voltar;
- botoes, formularios, cards, paineis, badges, tabelas e estados;
- componentes de torneio: cards, participantes, equipes, chave, ranking e agenda;
- componentes administrativos: pedidos, bloqueios, auditoria e estados de gestao;
- auth, perfil, avatar picker, user menu, modal e toast;
- responsividade mobile-first para 320px ate desktop amplo.

### Regras de identidade

- Amarelo UTFPR e usado para CTA principal, foco, destaque de vencedor, detalhe de card e sinais de marca.
- Preto/grafite e usado para marca, contraste institucional, texto forte e placares destacados.
- Fundos permanecem claros/off-white para leitura.
- Verde, vermelho, azul e aviso ficam restritos a estados funcionais.
- Cards e paineis usam bordas sutis, sombras leves e raio curto.
- O padrao tecnico aparece em grids discretos de fundo, sem gradientes pesados.

### Componentes visuais

- `button-primary`: CTA amarelo com texto grafite.
- `button-secondary`: acao secundaria em superficie clara.
- `button-ghost`: acao auxiliar.
- `badge-*`: status com texto explicito e ponto visual.
- `.table-scroll`: wrapper obrigatorio para tabelas largas.
- `.bracket`: lista vertical em mobile e colunas por rodada no desktop.
- `.bracket-slot.is-winner`: vencedor destacado por borda, fundo e contraste no placar.
- `.form-message-*`, `.loading-state`, `.empty-state` e `.error-state`: estados globais consistentes.

### Acessibilidade e responsividade

O CSS preserva as estruturas ja existentes no React:

- labels em formularios;
- `aria-current` na navegacao;
- `aria-expanded` no menu mobile;
- `role="status"` e `role="alert"` em mensagens;
- tabs com `role="tablist"` e `aria-selected`;
- botao mobile que fecha com Escape via `SiteHeader`.

As tabelas continuam com overflow horizontal controlado. A chave mata-mata evita
rolagem agressiva em mobile ao empilhar rodadas e usa colunas apenas em desktop.

### Arquivos alterados nesta etapa visual

- `src/index.css`
- `src/App.css`
- `docs/09-ui-ux-design-system.md`
- `docs/10-css-responsividade-acessibilidade.md`
- `docs/13-checklist-code-review.md`
- `docs/14-arquitetura-completa.md`

## Atualizacao: arquitetura de fluxos

A arquitetura operacional agora esta detalhada em `docs/fluxos/`.

Principais conclusoes:

- O nucleo implementado cobre Auth, profiles, pedidos/permissoes de criador, torneios, inscricoes, equipes, check-in, W.O., desclassificacao, mata-mata simples, resultados, contestacoes, historico, auditoria e bloqueios.
- O nucleo parcial cobre ranking, snapshots de classificacao, formatos de tabela, grupos, grupos + playoffs, agentes livres e comunicacao preventiva de bloqueios.
- O nucleo pendente cobre agenda real de partidas, geradores persistidos de pontos corridos/grupos, notificacoes, `global_settings` e testes automatizados de RLS.

Referencias principais:

- `docs/fluxos/00-indice-fluxos.md`
- `docs/fluxos/01-atores-e-permissoes.md`
- `docs/fluxos/02-mapa-geral-do-sistema.md`
- `docs/fluxos/17-casos-de-erro-e-falhas-de-fluxo.md`
- `docs/fluxos/18-matriz-de-casos-de-uso.md`
- `docs/fluxos/20-pendencias-e-recomendacoes.md`
