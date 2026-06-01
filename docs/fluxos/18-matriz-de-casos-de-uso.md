# Matriz de casos de uso

Status permitidos nesta matriz: Implementado, Parcial, Pendente, Futuro, Inconsistente, Precisa revisao.

| ID | Caso de uso | Ator principal | Status | Evidencia | Observacoes |
| --- | --- | --- | --- | --- | --- |
| AUTH-001 | Criar conta com email/senha | Visitante | Implementado | `RegisterForm`, Supabase Auth, trigger `handle_new_auth_user` | Depende de configuracao Supabase. |
| AUTH-002 | Login | Visitante | Implementado | `LoginForm`, `AuthProvider` | Carrega profile e permissao. |
| AUTH-003 | Logout | Usuario autenticado | Implementado | `LogoutButton`, `signOut` | Redireciona usuario. |
| AUTH-004 | Recuperar senha | Visitante | Parcial | `PasswordRecoveryForm` | Falta tela clara de nova senha. |
| AUTH-005 | Rota protegida sem login | Visitante | Implementado | `ProtectedRoute` | RLS continua sendo fronteira real. |
| PROFILE-001 | Editar nome/RA/avatar | Usuario autenticado | Implementado | `ProfileForm`, `protect_profile_update` | Email/role bloqueados. |
| PROFILE-002 | Admin altera profile | Admin global | Implementado | Policies admin em `profiles` | Precisa cuidado operacional. |
| PERM-001 | Solicitar permissao de criador | Usuario comum | Implementado | `createCreatorRequest` | Motivo minimo no front-end. |
| PERM-002 | Ver pedidos proprios | Usuario comum | Implementado | `MyCreatorRequestsPage` | RLS propria. |
| PERM-003 | Cancelar pedido pendente | Usuario comum | Implementado | `cancelCreatorRequest` | Apenas proprio pending. |
| PERM-004 | Aprovar pedido | Admin global | Implementado | `decideCreatorRequest`, trigger cria permission | Auditado. |
| PERM-005 | Rejeitar pedido | Admin global | Implementado | `decideCreatorRequest` | Auditado. |
| PERM-006 | Revogar permissao | Admin global | Implementado | `revokeCreatorPermission` | Motivo opcional. |
| PERM-007 | Criador revogado tenta criar | Criador revogado | Implementado | `can_create_tournament` | Regra de gestao antiga precisa revisao. |
| TOURN-001 | Listar torneios publicados | Visitante | Implementado | `fetchTournaments`, RLS public | Draft oculto. |
| TOURN-002 | Criar torneio | Criador autorizado | Implementado | `CreateTournamentPage`, `createTournament` | Exige permissao ativa. |
| TOURN-003 | Editar torneio proprio | Organizador | Implementado | `EditTournamentPage`, RLS owner | Bloqueado se permissao revogada. |
| TOURN-004 | Admin edita qualquer torneio | Admin global | Implementado | Policies admin | Falta motivo para status critico. |
| TOURN-005 | Publicar/abrir inscricoes | Organizador | Parcial | Status em `TournamentForm` | Nao ha wizard dedicado. |
| TOURN-006 | Excluir torneio | Admin global | Implementado | Delete admin | Alto impacto, precisa confirmacao forte. |
| REG-001 | Inscricao individual | Usuario autenticado | Implementado | `createTournamentRegistration` | Status inicial pending. |
| REG-002 | Cancelar propria inscricao | Usuario autenticado | Implementado | `cancelOwnRegistration` | Restrito por status do torneio. |
| REG-003 | Gestor confirma/rejeita | Organizador | Implementado | `updateRegistrationStatus` | Auditado. |
| REG-004 | Lista publica de participantes | Visitante | Implementado | `fetchPublicTournament` | Revisar no-show. |
| REG-005 | Seed para chave | Organizador | Implementado | `updateRegistrationSeed` | Usado no seeded. |
| TEAM-001 | Criar equipe | Capitao | Implementado | `createTeam` | Apenas torneio por equipe aberto. |
| TEAM-002 | Adicionar membro por email/RA | Capitao | Implementado | `findProfileForTeamMember`, `addTeamMember` | Busca exata. |
| TEAM-003 | Remover membro | Capitao | Implementado | `removeTeamMember` | Capitao nao removivel. |
| TEAM-004 | Enviar equipe para inscricao | Capitao | Implementado | `submitTeamRegistration` | Cria inscricao pending. |
| TEAM-005 | Agentes livres | Usuario comum | Pendente | Campo `allow_free_agents` | Sem fluxo. |
| TEAM-006 | Transferir capitania | Capitao | Futuro | Triggers bloqueiam remover capitao | Precisa regra nova. |
| CHECKIN-001 | Abrir check-in | Organizador | Implementado | `openTournamentCheckIn` | Via participantes. |
| CHECKIN-002 | Usuario confirma check-in | Usuario autenticado | Implementado | `confirmRegistrationCheckIn` | Janela obrigatoria. |
| CHECKIN-003 | Check-in manual | Organizador | Implementado | `setRegistrationCheckIn` | Desfazer exige motivo. |
| CHECKIN-004 | Desclassificar inscricao | Organizador | Implementado | `disqualifyRegistration` | Reversao pendente. |
| BRACKET-001 | Gerar mata-mata | Organizador | Implementado | `generateTournamentBracket` | Single elimination. |
| BRACKET-002 | Gerar com byes | Sistema | Implementado | `singleElimination.ts` | Precisa testes. |
| BRACKET-003 | Regerar chave | Organizador | Precisa revisao | `forceRegenerate` | Risco de apagar resultados. |
| RESULT-001 | Registrar placar | Organizador | Implementado | `recordBracketMatchResult` | RPC protegida. |
| RESULT-002 | Contestacao | Participante | Parcial | `contestMatchResult` | UI precisa alinhar membros de equipe. |
| RESULT-003 | Resolver disputa | Organizador | Implementado | `resolveMatchDispute` | Exige observacao. |
| RESULT-004 | Registrar W.O. | Organizador | Implementado | `recordBracketMatchWalkover` | Reversao pendente. |
| RANK-001 | Calcular ranking | Sistema/front-end | Parcial | `calculateTournamentRanking` | Sem snapshot oficial na UI. |
| RANK-002 | Publicar ranking oficial | Organizador | Pendente | Tabelas existem | Falta fluxo. |
| RR-001 | Pontos corridos | Organizador | Pendente | Formato previsto | Sem gerador persistido. |
| GROUP-001 | Grupos | Organizador | Pendente | Docs/formatos previstos | Sem modelo completo. |
| GROUP-002 | Grupos + playoffs | Organizador | Pendente | Chave existe, classificacao nao | Falta fluxo de classificados. |
| SCHEDULE-001 | Agendar partida | Organizador | Pendente | Rotas/docs planejadas | Sem tabela/servico. |
| SCHEDULE-002 | Remarcar partida | Organizador | Futuro | Nao implementado | Exigiria auditoria. |
| ADMIN-001 | Acessar admin | Admin global | Implementado | `AdminRoute`, `AdminDashboardPage` | RLS reforca. |
| ADMIN-002 | Gerenciar bloqueios | Admin global | Implementado | `action_locks`, `admin.ts` | UX preventiva parcial. |
| ADMIN-003 | Painel do organizador | Organizador | Parcial | Telas por torneio | Sem dashboard unico. |
| AUDIT-001 | Gravar logs sensiveis | Sistema | Implementado | Triggers `audit_*` | IP/user-agent nulos. |
| AUDIT-002 | Consultar auditoria | Admin global | Implementado | `fetchAuditLogs` | Restrito por RLS. |
| SECURITY-001 | Bloquear burla por front-end | Sistema/RLS | Implementado | RLS, triggers, RPCs | Precisa testes automatizados. |
| SECURITY-002 | Bloquear action lock | Sistema/RLS | Implementado | `assert_action_unlocked` | Melhorar aviso previo. |
| SECURITY-003 | Service role fora do front-end | Sistema | Implementado | `.env.example`, docs | Manter revisao. |

