# API e contratos

Os contratos abaixo podem ser implementados como actions locais no MVP e virar endpoints HTTP/RPC no futuro. Entradas e saídas usam nomes em inglês para facilitar tipos TypeScript.

Quando Supabase for implementado:

- autenticação deve usar Supabase Auth;
- senhas não devem ser armazenadas em tabela própria;
- permissões devem ser validadas por RLS, policies e/ou RPCs protegidas;
- chaves privadas não podem ser usadas no front-end.

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
- **Decisão de autorização:** a permissão de criar torneios é derivada de pedido `approved` em `tournament_creator_requests` ou de `role = admin`. Isso deve ser validado no banco por função segura como `public.can_create_tournaments()`, sem transformar o usuário aprovado em admin global.

## Decidir pedido de permissão

- **Ação:** `decideTournamentCreatorRequest`
- **Entrada:** `{ requestId, decision: "approved" | "rejected", adminNotes }`
- **Saída:** `{ request, profile, auditLog }`
- **Validações:** pedido pendente; justificativa da decisão; admin autenticado.
- **Erros possíveis:** `NOT_FOUND`, `REQUEST_ALREADY_DECIDED`, `PERMISSION_DENIED`.
- **Permissões:** admin.

## Atualizar configurações globais

- **Ação:** `updateGlobalSettings`
- **Entrada:** `{ key, value, reason }`
- **Saída:** `{ setting, auditLog }`
- **Validações:** chave conhecida; valor válido; justificativa.
- **Erros possíveis:** `INVALID_SETTING`, `PERMISSION_DENIED`.
- **Permissões:** admin.

## Criar torneio

- **Ação:** `createTournament`
- **Entrada:** `{ name, modality, description, startsAt, endsAt, settings }`
- **Saída:** `{ tournament }`
- **Validações:** nome obrigatório; datas coerentes; limites válidos.
- **Erros possíveis:** `VALIDATION_ERROR`, `PERMISSION_DENIED`.
- **Permissões:** admin ou usuário com permissão aprovada para criar torneios; RLS deve validar.

## Atualizar torneio

- **Ação:** `updateTournament`
- **Entrada:** `{ tournamentId, patch }`
- **Saída:** `{ tournament }`
- **Validações:** torneio existente; campos permitidos por status.
- **Erros possíveis:** `NOT_FOUND`, `VALIDATION_ERROR`, `TOURNAMENT_LOCKED`.
- **Permissões:** usuário autorizado no torneio ou admin. Admin pode editar torneios em andamento/encerrados com justificativa e auditoria.

## Inscrever participante

- **Ação:** `registerParticipant`
- **Entrada:** `{ tournamentId, profileId, teamId?, displayName }`
- **Saída:** `{ registration, participant }`
- **Validações:** inscrições abertas; limite não excedido; participante não duplicado.
- **Erros possíveis:** `REGISTRATION_CLOSED`, `DUPLICATED_PARTICIPANT`, `LIMIT_REACHED`.
- **Permissões:** usuário autenticado elegível, capitão, usuário autorizado no torneio ou admin.

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
- **Entrada:** `{ scope, tournamentId?, action, locked, reason }`
- **Saída:** `{ actionLock, auditLog }`
- **Validações:** escopo válido; justificativa obrigatória; admin autenticado.
- **Erros possíveis:** `INVALID_SCOPE`, `PERMISSION_DENIED`, `VALIDATION_ERROR`.
- **Permissões:** admin.

## Resolver disputa como admin

- **Ação:** `adminResolveDispute`
- **Entrada:** `{ disputeId, resolution, resultPatch?, reason }`
- **Saída:** `{ dispute, result?, auditLog }`
- **Validações:** disputa aberta; justificativa; impacto em ranking/chave calculável.
- **Erros possíveis:** `NOT_FOUND`, `DISPUTE_ALREADY_RESOLVED`, `PERMISSION_DENIED`, `DEPENDENT_MATCH_WARNING`.
- **Permissões:** admin.
