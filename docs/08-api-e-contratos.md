# API e contratos

Os contratos abaixo podem ser implementados como actions locais no MVP e virar endpoints HTTP/RPC no futuro. Entradas e saídas usam nomes em inglês para facilitar tipos TypeScript.

Na integracao Supabase atual e nas proximas evolucoes:

- autenticação deve usar Supabase Auth;
- senhas não devem ser armazenadas em tabela própria;
- permissões devem ser validadas por RLS, policies e/ou RPCs protegidas;
- chaves privadas não podem ser usadas no front-end.

## Infraestrutura Supabase

Contratos operacionais atuais:

- O cliente Supabase fica em `src/lib/supabase/client.ts`.
- O cliente exige `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`.
- `.env.example` lista apenas variaveis publicas e sem valores reais.
- `.env`, `.env.local` e `.env.*.local` nao devem ser versionados.
- `service_role`, JWT secret e senhas de banco nunca entram no front-end.
- `supabase/schema.sql` e o bootstrap consolidado para ambiente novo.
- `supabase/migrations/` recebe mudancas incrementais versionadas, incluindo
  `20260526090000_add_audit_logs_action_locks.sql`.
- Depois de alterar schema, atualizar tipos em `src/lib/supabase/types.ts` ou
  gerar tipos pela Supabase CLI quando ela estiver configurada.

Fluxo de aplicacao em ambiente novo:

1. Aplicar `supabase/schema.sql` pelo SQL Editor.
2. Criar usuario pelo app ou Supabase Auth.
3. Executar `select public.bootstrap_first_admin('UUID_DO_PROFILE_AQUI');`.
4. Validar RLS com anonimo, usuario comum, organizador autorizado e admin.

## Criar conta

- **Ação:** `signUpWithEmail`
- **Entrada:** `{ email, password, displayName, ra?, avatar_key? }`
- **Saída:** `{ user, profile }`
- **Validações:** e-mail válido; senha aceita pelo provedor; `avatar_key` pertence à lista permitida.
- **Erros possíveis:** `EMAIL_ALREADY_EXISTS`, `WEAK_PASSWORD`, `INVALID_AVATAR`, `PROFILE_CREATION_FAILED`.
- **Permissões:** público não autenticado.
- **Observação de segurança:** senha é enviada ao Supabase Auth; não persistir senha no banco da aplicação.

## Login

- **Ação:** `signInWithEmail`
- **Entrada:** `{ email, password }`
- **Saída:** `{ session, user, profile }`
- **Validações:** credenciais válidas; perfil existente.
- **Erros possíveis:** `INVALID_CREDENTIALS`, `EMAIL_NOT_CONFIRMED`, `PROFILE_NOT_FOUND`.
- **Permissões:** público não autenticado.

## Logout

- **Ação:** `signOut`
- **Entrada:** `{}`
- **Saída:** `{ success: true }`
- **Validações:** sessão ativa quando existir.
- **Erros possíveis:** `SESSION_ERROR`.
- **Permissões:** usuário autenticado.

## Atualizar perfil

- **Ação:** `updateOwnProfile`
- **Entrada:** `{ displayName?, ra?, avatar_key? }`
- **Saída:** `{ profile }`
- **Validações:** usuário autenticado; `avatar_key` válido; usuário não altera `role` nem permissões.
- **Erros possíveis:** `PERMISSION_DENIED`, `INVALID_AVATAR`, `VALIDATION_ERROR`.
- **Permissões:** usuário autenticado editando o próprio perfil; RLS deve bloquear alteração de outros perfis.

## Solicitar permissão para criar torneios

- **Ação:** `requestTournamentCreatorPermission`
- **Entrada:** `{ reason }`
- **Saída:** `{ request }`
- **Validações:** usuário autenticado; justificativa presente; não há pedido pendente duplicado.
- **Erros possíveis:** `DUPLICATED_PENDING_REQUEST`, `VALIDATION_ERROR`, `PERMISSION_DENIED`.
- **Permissões:** usuário comum autenticado.
- **Decisão de autorização:** o pedido é histórico. A permissão efetiva vem de `tournament_creator_permissions.status = active` ou de `role = admin`. Isso deve ser validado no banco por função segura como `public.can_create_tournament()`, sem transformar o usuário aprovado em admin global.

## Decidir pedido de permissão

- **Ação:** `decideTournamentCreatorRequest`
- **Entrada:** `{ requestId, decision: "approved" | "rejected", adminNotes }`
- **Saída:** `{ request, permission?, profile, auditLog }`
- **Validações:** pedido pendente; justificativa da decisão; admin autenticado; aprovação cria permissão ativa revogável.
- **Erros possíveis:** `NOT_FOUND`, `REQUEST_ALREADY_DECIDED`, `PERMISSION_DENIED`.
- **Permissões:** admin.

## Revogar permissão de criação de torneios

- **Ação:** `revokeTournamentCreatorPermission`
- **Entrada:** `{ permissionId, revokeReason? }`
- **Saída:** `{ permission }`
- **Validações:** admin autenticado; permissão existe; permissão está `active`; motivo opcional registrado quando informado.
- **Erros possíveis:** `NOT_FOUND`, `ALREADY_REVOKED`, `PERMISSION_DENIED`.
- **Permissões:** admin. Usuário comum não pode alterar status da própria permissão.

## Atualizar configurações globais

- **Ação:** `updateGlobalSettings`
- **Entrada:** `{ key, value, reason }`
- **Saída:** `{ setting, auditLog }`
- **Validações:** chave conhecida; valor válido; justificativa.
- **Erros possíveis:** `INVALID_SETTING`, `PERMISSION_DENIED`.
- **Permissões:** admin.

## Criar torneio

- **Ação:** `createTournament`
- **Entrada:** `{ name, modality, description, campus, format, status, maxParticipants, startsAt, endsAt }`
- **Saída:** `{ tournament }`
- **Validações:** nome obrigatório; datas coerentes; limite de participantes válido; `created_by = auth.uid()`.
- **Erros possíveis:** `VALIDATION_ERROR`, `PERMISSION_DENIED`.
- **Permissões:** admin ou usuário com permissão ativa para criar torneios; RLS valida com `public.can_create_tournament()`.

## Atualizar torneio

- **Ação:** `updateTournament`
- **Entrada:** `{ tournamentId, patch }`
- **Saída:** `{ tournament }`
- **Validações:** torneio existente; campos permitidos por status.
- **Erros possíveis:** `NOT_FOUND`, `VALIDATION_ERROR`, `TOURNAMENT_LOCKED`.
- **Permissões:** criador com permissão ativa pode editar apenas torneios que criou; admin pode editar qualquer torneio, inclusive em andamento.

## Inscrever participante

- **Ação:** `registerParticipant`
- **Entrada:** `{ tournamentId, profileId, displayName }`
- **Saída:** `{ registration, participant }`
- **Validações:** torneio com status `registrations_open`; limite não excedido; usuário não possui inscrição ativa duplicada.
- **Erros possíveis:** `REGISTRATION_CLOSED`, `DUPLICATED_PARTICIPANT`, `LIMIT_REACHED`, `PERMISSION_DENIED`.
- **Permissões:** usuário autenticado pode inscrever a si mesmo; lista pública não expõe RA nem email.

## Criar equipe

- **Ação:** `createTeam`
- **Entrada:** `{ tournamentId, name, captainProfileId, members }`
- **Saída:** `{ team }`
- **Validações:** nome obrigatório; capitão presente; tamanho válido.
- **Erros possíveis:** `INVALID_TEAM_SIZE`, `DUPLICATED_MEMBER`.
- **Permissões:** capitão, usuário autorizado no torneio ou admin.

## Confirmar check-in

- **Ação:** `confirmCheckIn`
- **Entrada:** `{ tournamentId, participantId }`
- **Saída:** `{ checkIn }`
- **Validações:** participante aprovado; janela aberta quando configurada.
- **Erros possíveis:** `CHECKIN_CLOSED`, `PARTICIPANT_NOT_APPROVED`.
- **Permissões:** participante, capitão, usuário autorizado no torneio ou admin.

## Gerar chave

- **Ação:** `generateBracket`
- **Entrada:** `{ tournamentId, stageId, method: "seed" | "draw" | "manual" }`
- **Saída:** `{ bracketNodes, matches, auditLog }`
- **Validações:** participantes suficientes; inscrições fechadas; seeds válidos.
- **Erros possíveis:** `NOT_ENOUGH_PARTICIPANTS`, `INVALID_SEEDS`, `STAGE_LOCKED`.
- **Permissões:** usuário autorizado no torneio ou admin.

## Gerar grupos

- **Ação:** `generateGroups`
- **Entrada:** `{ tournamentId, stageId, groupCount, method }`
- **Saída:** `{ groups, groupParticipants, auditLog }`
- **Validações:** quantidade de grupos válida; participantes suficientes.
- **Erros possíveis:** `INVALID_GROUP_COUNT`, `NOT_ENOUGH_PARTICIPANTS`.
- **Permissões:** usuário autorizado no torneio ou admin.

## Gerar tabela round robin

- **Ação:** `generateRoundRobinSchedule`
- **Entrada:** `{ tournamentId, stageId, participants, doubleRound? }`
- **Saída:** `{ rounds, matches }`
- **Validações:** pelo menos 2 participantes; fase em status editável.
- **Erros possíveis:** `NOT_ENOUGH_PARTICIPANTS`, `STAGE_LOCKED`.
- **Permissões:** usuário autorizado no torneio ou admin.

## Registrar resultado

- **Ação:** `submitMatchResult`
- **Entrada:** `{ matchId, scoreA, scoreB, games?, winnerId?, note? }`
- **Saída:** `{ result, match }`
- **Validações:** status permite resultado; placar não negativo; vencedor coerente.
- **Erros possíveis:** `INVALID_SCORE`, `INVALID_WINNER`, `MATCH_LOCKED`.
- **Permissões:** participante vinculado, capitão, usuário autorizado no torneio ou admin.

## Confirmar resultado

- **Ação:** `confirmMatchResult`
- **Entrada:** `{ matchId, resultId }`
- **Saída:** `{ result, match, standingUpdates?, bracketUpdates? }`
- **Validações:** resultado submetido; sem disputa aberta.
- **Erros possíveis:** `RESULT_NOT_FOUND`, `DISPUTE_OPEN`.
- **Permissões:** usuário autorizado no torneio ou admin; opcionalmente ambos participantes conforme regra.

## Contestar resultado

- **Ação:** `contestMatchResult`
- **Entrada:** `{ matchId, resultId, reason }`
- **Saída:** `{ dispute, match }`
- **Validações:** motivo obrigatório; prazo válido; usuário vinculado.
- **Erros possíveis:** `DISPUTE_WINDOW_CLOSED`, `PERMISSION_DENIED`.
- **Permissões:** participante vinculado, capitão, usuário autorizado no torneio ou admin.

## Calcular ranking

- **Ação:** `calculateRanking`
- **Entrada:** `{ tournamentId, stageId, tieBreakers }`
- **Saída:** `{ standings, unresolvedTies }`
- **Validações:** critérios conhecidos; resultados confirmados.
- **Erros possíveis:** `INVALID_TIEBREAKER`, `INSUFFICIENT_DATA`.
- **Permissões:** leitura pública quando fase publicada; cálculo administrativo para usuário autorizado ou admin.

## Finalizar torneio

- **Ação:** `finishTournament`
- **Entrada:** `{ tournamentId, summary? }`
- **Saída:** `{ tournament, finalStandings, auditLog }`
- **Validações:** sem partidas pendentes críticas; sem disputas abertas; classificação final definida.
- **Erros possíveis:** `PENDING_MATCHES`, `OPEN_DISPUTES`, `UNRESOLVED_RANKING`.
- **Permissões:** usuário autorizado no torneio ou admin.

## Bloquear ou desbloquear ação

- **Ação:** `setActionLock`
- **Entrada:** `{ scope, scopeId?, action, isLocked, reason, expiresAt? }`
- **Saída:** `{ actionLock, auditLog }`
- **Validações:** escopo válido; `scopeId` obrigatório quando o escopo não é `global`; justificativa obrigatória; admin autenticado.
- **Erros possíveis:** `INVALID_SCOPE`, `PERMISSION_DENIED`, `VALIDATION_ERROR`.
- **Permissões:** admin.

## Resolver disputa como admin

- **Ação:** `adminResolveDispute`
- **Entrada:** `{ disputeId, resolution, resultPatch?, reason }`
- **Saída:** `{ dispute, result?, auditLog }`
- **Validações:** disputa aberta; justificativa; impacto em ranking/chave calculável.
- **Erros possíveis:** `NOT_FOUND`, `DISPUTE_ALREADY_RESOLVED`, `PERMISSION_DENIED`, `DEPENDENT_MATCH_WARNING`.
- **Permissões:** admin.
## Atualização: contratos de inscrições

### Criar inscrição

- **Entrada:** `tournament_id`, `user_id`, `display_name`, `registration_type`.
- **Saída:** inscrição criada com status `pending`.
- **Validações:** usuário autenticado; torneio em `registrations_open`; tipo de inscrição compatível; limite não atingido; sem inscrição ativa duplicada.
- **Erros possíveis:** `not_authenticated`, `registration_closed`, `duplicate_registration`, `capacity_reached`, `rls_denied`.
- **Permissões:** usuário cria apenas a própria inscrição; RLS e trigger validam no banco.

### Cancelar própria inscrição

- **Entrada:** `registration_id`.
- **Saída:** inscrição com status `cancelled`, `cancelled_by` e `cancelled_at`.
- **Validações:** inscrição pertence ao usuário; status `pending` ou `confirmed`; torneio ainda não começou.
- **Erros possíveis:** `not_owner`, `invalid_status`, `tournament_not_cancellable`.
- **Permissões:** usuário comum só cancela a própria inscrição.

### Listar minhas inscrições

- **Entrada:** sessão autenticada.
- **Saída:** inscrições do usuário com resumo do torneio.
- **Validações:** sessão válida.
- **Erros possíveis:** `not_authenticated`, `rls_denied`.
- **Permissões:** usuário lê apenas inscrições próprias; admin não usa este contrato para auditoria global.

### Gerenciar inscrição

- **Entrada:** `registration_id`, novo `status` (`confirmed`, `rejected`, `cancelled`), `admin_notes` opcional.
- **Saída:** inscrição atualizada com auditoria de decisão/cancelamento.
- **Validações:** ator é admin ou organizador autorizado do torneio; status do torneio permite ação; inscrição cancelada/rejeitada não é reativada.
- **Erros possíveis:** `not_manager`, `invalid_status_transition`, `tournament_status_blocked`.
- **Permissões:** `public.can_manage_tournament(tournament_id)` controla RLS.

### Listar participantes públicos

- **Entrada:** `tournament_id`.
- **Saída:** inscrições `confirmed` ou `checked_in`.
- **Validações:** torneio publicado.
- **Erros possíveis:** `not_found`, `draft_not_public`.
- **Permissões:** público pode ler apenas participantes confirmados/check-in; pendentes ficam protegidos.

## Atualização: contratos de equipes

### Criar equipe

- **Entrada:** `tournament_id`, `name`, `captain_id`, `created_by`.
- **Saída:** equipe `draft` e membro capitão criado automaticamente.
- **Validações:** usuário autenticado; torneio por equipe; status `registrations_open`; nome válido; sem equipe ativa duplicada para o capitão.
- **Erros possíveis:** `not_authenticated`, `not_team_tournament`, `registration_closed`, `duplicate_team`, `duplicate_name`, `rls_denied`.
- **Permissões:** usuário cria apenas equipe própria; admin/organizador também podem gerir depois.

### Buscar usuário para membro

- **Entrada:** `identifier` com email ou RA exato.
- **Saída:** profile mínimo `{ id, display_name, email, ra, avatar_key }`.
- **Validações:** sessão autenticada; busca exata.
- **Erros possíveis:** `not_found`, `not_authenticated`.
- **Permissões:** RPC evita listagem ampla de usuários e deve ser usada apenas no fluxo de equipe.

### Adicionar membro

- **Entrada:** `team_id`, `user_id`.
- **Saída:** membro ativo.
- **Validações:** equipe existe; ator pode gerenciar; torneio aberto; limite máximo não excedido; usuário não está em outra equipe ativa do torneio.
- **Erros possíveis:** `not_manager`, `capacity_reached`, `duplicate_member`, `user_already_in_tournament_team`.
- **Permissões:** capitão, admin ou organizador autorizado.

### Remover membro

- **Entrada:** `team_member_id`.
- **Saída:** membro com `status = removed`, `removed_by` e `removed_at`.
- **Validações:** ator pode gerenciar; membro não é capitão; equipe ainda permite alteração.
- **Erros possíveis:** `not_manager`, `cannot_remove_captain`, `invalid_status`.
- **Permissões:** capitão, admin ou organizador autorizado.

### Excluir equipe em rascunho

- **Entrada:** `team_id`.
- **Saída:** sem payload; equipe é removida.
- **Validações:** equipe existe; status `draft`; ator pode gerenciar.
- **Erros possíveis:** `not_manager`, `team_not_found`, `not_draft`, `rls_denied`.
- **Permissões:** policy `teams_delete_draft_manager_or_captain` permite exclusão física apenas de equipe em rascunho por capitão, admin ou organizador.

### Enviar equipe para inscrição

- **Entrada:** `team_id`.
- **Saída:** `registration_id`.
- **Validações:** equipe em torneio por equipe; inscrições abertas; equipe completa quando exigido; capitão sem inscrição ativa duplicada.
- **Erros possíveis:** `team_incomplete`, `duplicate_registration`, `registration_closed`, `not_manager`.
- **Permissões:** capitão, admin ou organizador autorizado via RPC `submit_team_registration`.

### Listar membros da equipe

- **Entrada:** `team_id`.
- **Saída:** membros ativos com dados mínimos de perfil.
- **Validações:** equipe pública confirmada, usuário membro ou gestor.
- **Erros possíveis:** `not_found`, `permission_denied`.
- **Permissões:** público vê equipes confirmadas; membros, capitão, organizador e admin veem equipe própria/gerenciada.
## Atualização: contratos reais de chave

### Listar participantes elegíveis da chave

- **Ação:** `fetchBracketParticipants`.
- **Entrada:** `{ tournament }`.
- **Saída:** inscrições confirmadas/check-in compatíveis com `registration_type`.
- **Validações:** torneio individual usa inscrições individuais; torneio por equipe exige `team_id`.
- **Permissões:** leitura segue RLS de inscrições públicas/gestão.

### Gerar chave

- **Ação:** `generateTournamentBracket`.
- **Entrada:** `{ tournament, userId, seedingMethod: "draw" | "seeded", forceRegenerate }`.
- **Saída:** `TournamentBracketWithMatches`.
- **Validações:** formato `single_elimination`; ao menos dois participantes; status não pode ser `draft`, `finished` ou `cancelled`; chave existente exige `forceRegenerate`.
- **Permissões:** RLS em `tournament_brackets` e `bracket_matches` exige `public.can_manage_tournament(tournament_id)`.

### Confirmar resultado e avançar vencedor

- **Ação/RPC:** `complete_bracket_match`.
- **Entrada:** `{ target_match_id, target_winner_registration_id, target_score_a, target_score_b }`.
- **Saída:** sem payload; atualiza partida, próxima partida e campeão quando for final.
- **Validações:** gestor autorizado; partida `ready` ou `live`; dois participantes; vencedor pertence à partida; placares inteiros, não negativos e sem empate.
- **Permissões:** apenas `authenticated` com `public.can_manage_tournament`; usuário comum é bloqueado pelo banco.

### Regerar chave

- **Ação:** `generateTournamentBracket` com `forceRegenerate = true`.
- **Efeito:** remove `tournament_brackets` existente; `bracket_matches` cai por cascade; nova estrutura é salva.
- **UX obrigatória:** confirmação clara antes da chamada, avisando perda/alteração de dados.

## Atualizacao: contratos de resultados

RPCs novas ou atualizadas:

- `record_bracket_match_result(match_id, winner_registration_id, score_a, score_b, notes, change_reason)`: registra ou corrige resultado, cria historico e avanca vencedor.
- `complete_bracket_match(...)`: alias de compatibilidade para resultado simples sem observacao.
- `contest_match_result(match_id, reason)`: participante da partida abre contestacao.
- `resolve_match_dispute(match_id, action, notes)`: admin/organizador confirma ou cancela resultado contestado.
- `is_match_participant(match_id)`: helper de permissao para RLS e contestacao.

Consultas:

- `match_results` pode ser lido publicamente em torneios publicados.
- `match_result_history` e restrito a gestor ou participante autenticado da partida.

## Atualizacao: contratos de ranking

### Calcular ranking no front-end

- **Modulo:** `src/lib/tournaments/ranking.ts`.
- **Entrada:** participantes, partidas finalizadas, status de resultado e configuracao de pontos.
- **Saida:** entradas ordenadas, resumo de criterios, partidas contabilizadas/ignoradas e indicador de empate tecnico.
- **Regra:** a funcao ignora partidas que nao estejam `completed` ou que tenham resultado `disputed`/`cancelled`.

### Buscar ranking do torneio

- **Acao:** `fetchTournamentRanking(tournamentId)`.
- **Saida:** torneio, participantes elegiveis, partidas mapeadas e resultado calculado.
- **Permissoes:** leitura segue RLS de torneios, inscricoes, partidas e resultados.
- **Limitacao:** no MVP, formatos `round_robin`, `groups` e `groups_playoffs` estao preparados para ranking; a geracao propria dessas partidas ainda nao foi implementada.

### Snapshots SQL

- **Tabelas:** `tournament_standings` e `standing_entries`.
- **Leitura:** publica para torneios publicados.
- **Escrita:** apenas admin ou organizador autorizado por `public.can_manage_tournament(tournament_id)`.
- **Uso esperado:** persistir ranking oficial/provisorio quando houver gerador de pontos corridos ou grupos.

## Atualizacao: contratos de auditoria e bloqueios

### Listar auditoria geral

- **Acao:** `fetchAuditLogs`
- **Entrada:** `{ action?, entityType?, tournamentId?, limit? }`
- **Saida:** lista de `audit_logs` ordenada por `created_at desc`.
- **Validacoes:** filtros opcionais exatos por acao, entidade e torneio.
- **Erros possiveis:** `PERMISSION_DENIED`, `RLS_DENIED`.
- **Permissoes:** apenas admin le por RLS. Usuario comum nao recebe logs.

### Listar bloqueios administrativos

- **Acao:** `fetchActionLocks`
- **Entrada:** `{}`
- **Saida:** lista de `action_locks`.
- **Validacoes:** RLS separa leitura publica de bloqueios ativos e leitura completa de admin.
- **Permissoes:** anonimo/autenticado pode ler bloqueios ativos e nao expirados; admin le todos.

### Criar bloqueio administrativo

- **Acao:** `createActionLock`
- **Entrada:** `{ scope, scopeId?, action, reason, isLocked, expiresAt? }`
- **Saida:** `actionLock`.
- **Validacoes:** admin autenticado; motivo obrigatorio; `scopeId` obrigatorio para escopos nao globais; unico por `scope + scopeId + action`.
- **Permissoes:** `action_locks_insert_admin` e trigger `validate_action_lock_write`.

### Atualizar bloqueio administrativo

- **Acao:** `updateActionLock`
- **Entrada:** `{ id, reason?, isLocked?, expiresAt? }`
- **Saida:** `actionLock`.
- **Validacoes:** admin autenticado; escopo, acao e autoria original nao podem mudar.
- **Permissoes:** `action_locks_update_admin` e trigger `validate_action_lock_write`.

### Remover bloqueio administrativo

- **Acao:** `deleteActionLock`
- **Entrada:** `{ id }`
- **Saida:** sem payload.
- **Validacoes:** admin autenticado.
- **Permissoes:** `action_locks_delete_admin`.

### Validacao de bloqueios no banco

- `public.is_action_locked(action, scope, scope_id)` retorna bloqueio ativo considerando tambem bloqueio global da mesma acao.
- `public.assert_action_unlocked(action, scope, scope_id)` interrompe a operacao com erro quando usuario comum ou organizador tenta acao bloqueada.
- Admin global pode operar apesar do bloqueio para conseguir corrigir ou remover a trava.

Acoes cobertas por triggers/RPCs nesta etapa: `create_tournament`, `edit_tournament`, `delete_tournament`, `register`, `cancel_registration`, `manage_registration`, `manage_teams`, `generate_bracket`, `record_result`, `contest_result` e `recalculate_ranking`.
