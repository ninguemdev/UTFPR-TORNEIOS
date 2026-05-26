# Modelo de dados

Este modelo é uma proposta inicial para orientar TypeScript, Supabase/PostgreSQL, Row Level Security e contratos de API.

## Decisões de autenticação e banco

- Supabase é a solução recomendada para autenticação, PostgreSQL, Row Level Security e controle de acesso.
- A autenticação com email e senha deve usar Supabase Auth.
- Senhas não devem ser armazenadas manualmente em tabelas próprias.
- O identificador do usuário autenticado deve ser `auth.users.id`.
- Tabelas da aplicação devem referenciar o usuário por `uuid` e `references auth.users(id)` quando implementadas no Supabase.
- Chaves privadas, service role keys e segredos não podem ir para o front-end.
- Todas as tabelas importantes devem ter RLS habilitado.
- Permissões precisam ser validadas por policies, funções SQL/RPC seguras ou constraints no banco, não apenas por componentes React.

## Entidades

### User

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | uuid | Sim | Profile, AuditLog | Corresponde a `auth.users.id` do Supabase Auth. |
| email | string | Sim | Profile | Gerenciado pelo Supabase Auth; não duplicar como fonte de verdade quando desnecessário. |
| createdAt | timestamptz | Sim | - | Data de criação do usuário no provedor de autenticação. |

Observação: a tabela `auth.users` é gerenciada pelo Supabase. O projeto não deve criar campo `passwordHash` nem armazenar senha em tabela própria.

### Profile

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | uuid | Sim | User | Mesmo valor de `auth.users.id` ou identificador próprio com FK para `auth.users`. |
| userId | uuid | Sim | User | Dono do perfil; deve ser único. |
| displayName | string | Sim | Participant, AuditLog | Nome público. |
| role | enum | Sim | - | `admin` ou `user`. Usuários comuns não podem alterar este campo. |
| ra | string | Opcional | - | Registro acadêmico informado pelo usuário. Não deve ser exposto publicamente por padrão. |
| avatar_key | string | Sim | - | Chave de avatar pré-definido. Upload de foto não faz parte do MVP. |
| can_create_tournaments | boolean derivado | Não persistido | Tournament | Permissão calculada por `public.can_create_tournament()`: admin global ou usuário com permissão `active` em `tournament_creator_permissions`. |
| createdAt | timestamptz | Sim | - | Data de criação do perfil. |
| updatedAt | timestamptz | Sim | - | Data da última atualização. |

### TournamentCreatorRequest

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | uuid | Sim | Profile | Pedido de permissão. |
| requesterId | uuid | Sim | Profile | Usuário comum que pediu autorização para criar torneios. |
| status | enum | Sim | AuditLog | pending, approved, rejected, cancelled. |
| reason | text | Opcional | - | Justificativa do pedido. |
| decidedBy | uuid | Opcional | Profile | Admin que aprovou ou rejeitou. |
| decisionReason | text | Opcional | - | Justificativa administrativa. |
| createdAt | timestamptz | Sim | - | Data do pedido. |
| decidedAt | timestamptz | Opcional | - | Data da decisão. |

### TournamentCreatorPermission

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | uuid | Sim | - | Permissão efetiva para criar torneios. |
| userId | uuid | Sim | Profile | Usuário autorizado ou revogado. |
| status | enum | Sim | - | active, revoked. Apenas `active` permite criar torneios. |
| grantedBy | uuid | Sim | Profile | Admin que concedeu a permissão. |
| grantedAt | timestamptz | Sim | - | Data da concessão. |
| revokedBy | uuid | Opcional | Profile | Admin que revogou. |
| revokedAt | timestamptz | Opcional | - | Data da revogação. |
| grantReason | text | Opcional | TournamentCreatorRequest | Motivo administrativo ou motivo do pedido aprovado. |
| revokeReason | text | Opcional | AuditLog | Motivo informado pelo admin ao revogar. |
| createdAt | timestamptz | Sim | - | Data de criação do registro. |
| updatedAt | timestamptz | Sim | - | Data da última atualização. |

O pedido é histórico e não deve ser apagado. A permissão é a fonte de autorização revogável. Para preservar histórico, reativar um usuário deve criar uma nova permissão `active`, mantendo registros `revoked`.

### GlobalSettings

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | AuditLog | Chave da configuração global. |
| value | jsonb | Sim | - | Valor estruturado. |
| updatedBy | uuid | Sim | Profile | Apenas admin pode alterar. |
| updatedAt | timestamptz | Sim | - | Data da alteração. |

### ActionLock

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | uuid | Sim | Tournament, AuditLog | Bloqueio administrativo. |
| scope | enum | Sim | - | global, tournament, match, registration. |
| tournamentId | uuid | Opcional | Tournament | Torneio afetado quando aplicável. |
| action | string | Sim | - | Ação bloqueada, como `edit_results`. |
| locked | boolean | Sim | - | Indica se o bloqueio está ativo. |
| reason | text | Sim | - | Justificativa obrigatória. |
| createdBy | uuid | Sim | Profile | Admin responsável. |
| createdAt | timestamptz | Sim | - | Data de criação. |

### Tournament

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | TournamentSettings, TournamentStage | Identificador. |
| name | string | Sim | - | Nome público. |
| slug | string | Sim | - | URL amigável. |
| description | string | Opcional | - | Descrição curta. |
| organizerId | uuid | Sim | Profile | Responsável autorizado. |
| status | enum | Sim | - | draft, registrations_open, registrations_closed, ongoing, finished, cancelled. |
| startsAt | datetime | Opcional | Match | Início previsto. |
| endsAt | datetime | Opcional | - | Fim previsto. |
| createdBy | uuid | Sim | Profile | Usuário que criou o torneio. |

### TournamentSettings

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Tournament | Identificador. |
| tournamentId | string | Sim | Tournament | Torneio. |
| minParticipants | number | Sim | Registration | Limite mínimo. |
| maxParticipants | number | Sim | Registration | Limite máximo. |
| teamBased | boolean | Sim | Team | Define individual/equipe. |
| checkInRequired | boolean | Sim | CheckIn | Exige presença. |
| allowDraw | boolean | Sim | Seed | Sorteio permitido. |
| allowSeeding | boolean | Sim | Seed | Seeds permitidos. |

### TournamentFormat

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | TournamentStage | Identificador. |
| type | enum | Sim | - | single_elimination, round_robin, groups_playoffs, swiss. |
| bestOf | number | Opcional | MatchGame | 1, 3, 5 ou 7. |
| thirdPlaceMatch | boolean | Opcional | Match | Apenas mata-mata. |
| scoringConfig | object | Opcional | Standing | Pontuação customizada. |

### TournamentStage

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Tournament | Identificador. |
| tournamentId | string | Sim | Tournament | Torneio. |
| name | string | Sim | Group, Match | Ex.: grupos, semifinal. |
| order | number | Sim | - | Ordem de execução. |
| formatId | string | Sim | TournamentFormat | Formato da fase. |
| status | enum | Sim | - | draft, provisional, published, running, completed. |

### Group

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | TournamentStage | Identificador. |
| stageId | string | Sim | TournamentStage | Fase. |
| name | string | Sim | Participant | Ex.: Grupo A. |
| order | number | Sim | - | Ordenação. |

### Participant

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Registration, Match | Identificador competitivo. |
| tournamentId | string | Sim | Tournament | Escopo do torneio. |
| profileId | string | Opcional | Profile | Participante individual. |
| teamId | string | Opcional | Team | Participante por equipe. |
| displayName | string | Sim | Standing | Nome exibido. |
| status | enum | Sim | - | pending, approved, checked_in, withdrawn, disqualified. |

### Team

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | TeamMember, Participant | Identificador. |
| name | string | Sim | Participant | Nome da equipe. |
| captainProfileId | string | Sim | Profile | Capitão. |
| status | enum | Sim | - | active, incomplete, disqualified. |

### TeamMember

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Team | Identificador. |
| teamId | string | Sim | Team | Equipe. |
| profileId | string | Sim | Profile | Jogador. |
| role | enum | Sim | - | captain, player, substitute. |

### Registration

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Tournament, Participant | Identificador. |
| tournamentId | string | Sim | Tournament | Torneio. |
| participantId | string | Sim | Participant | Inscrito. |
| status | enum | Sim | - | pending, approved, rejected, cancelled. |
| submittedAt | datetime | Sim | - | Data de envio. |

### CheckIn

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Participant | Identificador. |
| tournamentId | string | Sim | Tournament | Torneio. |
| participantId | string | Sim | Participant | Presença. |
| status | enum | Sim | - | pending, confirmed, missed, late. |
| checkedAt | datetime | Opcional | - | Momento do check-in. |

### Seed

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Participant | Identificador. |
| tournamentId | string | Sim | Tournament | Torneio. |
| participantId | string | Sim | Participant | Participante. |
| seedNumber | number | Sim | BracketNode | Ordem da semente. |
| source | enum | Sim | AuditLog | manual, ranking, draw. |

### Match

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | MatchGame, MatchResult | Identificador. |
| tournamentId | string | Sim | Tournament | Torneio. |
| stageId | string | Sim | TournamentStage | Fase. |
| groupId | string | Opcional | Group | Grupo quando aplicável. |
| round | number | Sim | - | Rodada. |
| participantAId | string | Opcional | Participant | Pode ficar vazio antes de avanço. |
| participantBId | string | Opcional | Participant | Pode ser BYE. |
| scheduledAt | datetime | Opcional | Venue/Server | Data e hora. |
| status | enum | Sim | - | pending, scheduled, live, finished, cancelled, disputed. |

### MatchGame

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Match | Jogo dentro de série. |
| matchId | string | Sim | Match | Partida mãe. |
| order | number | Sim | - | Número do jogo. |
| scoreA | number | Opcional | MatchResult | Placar. |
| scoreB | number | Opcional | MatchResult | Placar. |
| winnerId | string | Opcional | Participant | Vencedor do jogo. |

### MatchResult

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Match | Identificador. |
| matchId | string | Sim | Match | Partida. |
| winnerId | string | Opcional | Participant | Pode ser nulo em empate. |
| scoreA | number | Sim | - | Placar agregado. |
| scoreB | number | Sim | - | Placar agregado. |
| status | enum | Sim | Dispute | submitted, confirmed, contested, corrected. |
| submittedBy | string | Sim | Profile | Autor do envio. |
| confirmedBy | string | Opcional | Profile | Responsável pela confirmação. |
| correctedBy | uuid | Opcional | Profile | Admin ou usuário autorizado que corrigiu. |
| correctionReason | text | Opcional | AuditLog | Obrigatório para correções após confirmação. |

### Standing

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | TournamentStage | Identificador. |
| stageId | string | Sim | TournamentStage | Fase. |
| participantId | string | Sim | Participant | Participante. |
| points | number | Sim | - | Pontuação. |
| wins | number | Sim | - | Vitórias. |
| draws | number | Sim | - | Empates. |
| losses | number | Sim | - | Derrotas. |
| scoreFor | number | Sim | - | Pontos pró. |
| scoreAgainst | number | Sim | - | Pontos contra. |
| unresolvedTie | boolean | Sim | TieBreakerRule | Empate não resolvido. |

### TieBreakerRule

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | TournamentFormat | Identificador. |
| tournamentId | string | Sim | Tournament | Torneio. |
| type | enum | Sim | Standing | points, wins, score_diff, head_to_head, score_for, buchholz. |
| order | number | Sim | - | Ordem de aplicação. |
| direction | enum | Sim | - | asc ou desc. |

### BracketNode

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Match | Nó da chave. |
| tournamentId | string | Sim | Tournament | Torneio. |
| stageId | string | Sim | TournamentStage | Fase. |
| matchId | string | Opcional | Match | Partida associada. |
| nextNodeId | string | Opcional | BracketNode | Avanço do vencedor. |
| slot | string | Sim | - | Posição na chave. |

### Venue ou Server

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | Match | Identificador. |
| name | string | Sim | Match | Sala, quadra, laboratório ou servidor. |
| type | enum | Sim | - | physical, online. |
| capacity | number | Opcional | - | Capacidade quando aplicável. |
| url | string | Opcional | - | Link de servidor ou transmissão. |

### Notification

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | User/Profile | Identificador. |
| recipientId | string | Sim | Profile | Destinatário. |
| type | enum | Sim | - | match_update, result, dispute, registration. |
| message | string | Sim | - | Texto curto. |
| readAt | datetime | Opcional | - | Controle de leitura. |

### Dispute

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | MatchResult | Identificador. |
| matchId | string | Sim | Match | Partida. |
| openedBy | string | Sim | Profile | Autor. |
| reason | string | Sim | - | Motivo. |
| status | enum | Sim | - | open, under_review, accepted, rejected, resolved. |
| resolution | string | Opcional | AuditLog | Decisão. |

### AuditLog

| Campo | Tipo sugerido | Obrigatório | Relações | Observações |
| --- | --- | --- | --- | --- |
| id | string | Sim | User/Profile | Identificador. |
| actorId | string | Sim | Profile | Quem executou. |
| entityType | string | Sim | - | Ex.: MatchResult. |
| entityId | string | Sim | - | Entidade afetada. |
| action | string | Sim | - | Ex.: result_corrected. |
| before | object | Opcional | - | Estado anterior. |
| after | object | Opcional | - | Estado novo. |
| reason | text | Opcional | - | Justificativa administrativa quando aplicável. |
| createdAt | datetime | Sim | - | Data da ação. |

## Regras de integridade

- Participante deve pertencer a apenas um torneio.
- Equipe não pode ter membros duplicados.
- Resultado confirmado deve pertencer a partida existente.
- Ranking deve ser derivado de resultados confirmados.
- Alteração de resultado confirmado deve gerar `AuditLog`.
- Partida não pode ter o mesmo participante nos dois lados.
- Chave publicada não deve ser regenerada sem registrar auditoria.
- `profiles.role` só pode ser alterado por admin ou processo seguro de seed/migração.
- `profiles.avatar_key` deve aceitar apenas chaves cadastradas na lista de avatares permitidos.
- Usuário comum só pode atualizar o próprio perfil e não pode mudar `role` nem conceder a si mesmo permissão de organizador.
- Criação de torneio exige `role = admin` ou permissão `active` em `tournament_creator_permissions`.
- Usuário aprovado para criar torneios não vira admin global; a decisão deve ser consultada por função segura como `public.can_create_tournament()`.
- Usuário comum não pode criar, atualizar, reativar nem revogar `tournament_creator_permissions`.
- Alteração de torneio em andamento/encerrado exige admin ou regra explícita registrada.
- Correção de resultado confirmado exige auditoria e permissão validada no banco.

## Índices úteis

- `Tournament.slug`.
- `Tournament.organizerId`.
- `Profile.userId`.
- `Profile.role`.
- `TournamentCreatorRequest.requesterId + status`.
- `TournamentCreatorPermission.userId + status`.
- Índice único parcial para permitir no máximo uma permissão `active` por usuário.
- `Participant.tournamentId`.
- `Registration.tournamentId + participantId`.
- `Match.tournamentId + stageId + round`.
- `Match.scheduledAt`.
- `Standing.stageId + participantId`.
- `AuditLog.entityType + entityId`.

## Status possíveis

- Torneio: draft, registrations_open, registrations_closed, ongoing, finished, cancelled.
- Pedido de criação de torneio: pending, approved, rejected, cancelled.
- Permissão de criação de torneio: active, revoked.
- Participante: pending, approved, checked_in, withdrawn, disqualified.
- Inscrição: pending, approved, rejected, cancelled.
- Partida: pending, scheduled, live, finished, cancelled, disputed.
- Resultado: submitted, confirmed, contested, corrected.
- Disputa: open, under_review, accepted, rejected, resolved.

## Enumerações

- `TournamentFormatType`: single_elimination, round_robin, groups_playoffs, swiss, hybrid.
- `Role`: admin, user.
- `TeamMemberRole`: captain, player, substitute.
- `VenueType`: physical, online.
- `SeedSource`: manual, ranking, draw.
- `TieBreakerType`: points, wins, draws, losses, score_diff, score_for, head_to_head, buchholz, wo_count.
- `CreatorRequestStatus`: pending, approved, rejected, cancelled.
- `CreatorPermissionStatus`: active, revoked.
- `ActionLockScope`: global, tournament, match, registration.

## RLS e policies mínimas

Todas as tabelas importantes devem ter RLS habilitado. Policies iniciais recomendadas:

- `profiles`: usuário autenticado lê perfis públicos necessários; atualiza apenas o próprio perfil; apenas admin altera `role`.
- `tournament_creator_requests`: usuário cria e lê os próprios pedidos; admin lê todos e decide.
- `tournament_creator_permissions`: usuário lê apenas a própria situação; admin lê todas, concede e revoga; nenhuma policy permite escrita por usuário comum.
- `global_settings`: leitura conforme necessidade pública; escrita apenas para admin.
- `tournaments`: visitantes leem torneios publicados; usuário autorizado cria/edita seus torneios em estados permitidos; admin lê e altera todos.
- `registrations`: usuário cria/lê as próprias inscrições; usuários autorizados do torneio e admins administram inscrições.
- `teams` e `team_members`: capitão administra equipe dentro das regras; admin e usuário autorizado do torneio podem revisar.
- `matches`, `match_results`, `disputes`: leitura pública quando publicada; escrita restrita a participantes envolvidos, usuários autorizados ou admins conforme ação.
- `audit_logs`: escrita por funções seguras; leitura restrita a admin e usuários autorizados quando necessário.

Permissões de escrita sensível devem preferir funções RPC com `security definer` bem revisadas quando a regra for complexa.

## Cuidados com LGPD

- Coletar apenas dados necessários.
- Evitar expor e-mail, RA ou contato em página pública.
- Permitir remoção ou anonimização quando aplicável.
- Restringir acesso a dados sensíveis por permissão.
- Registrar auditoria sem vazar informações desnecessárias.
- Tratar `ra` como dado pessoal e exibi-lo apenas para o próprio usuário, admin ou contexto administrativo justificado.
- Usar `avatar_key` em vez de upload de foto no MVP para reduzir risco de armazenamento indevido de imagem pessoal.

## Atualização: inscrições e participantes

No MVP, `tournament_registrations` é a entidade operacional de inscrição e também a base para listar participantes. Não há tabela separada de `tournament_participants` nesta etapa: participantes públicos são derivados de inscrições `confirmed` ou `checked_in`.

### Tournament

Campos adicionados:

- `registration_type`: enum `individual | team`, obrigatório, padrão `individual`.
- `team_min_size`: inteiro obrigatório, padrão `1`.
- `team_max_size`: inteiro obrigatório, padrão `1`.

Regras:

- `team_min_size` deve ser maior que zero.
- `team_max_size` deve ser maior ou igual a `team_min_size`.
- Torneios individuais devem usar equipe mínima e máxima igual a `1` no front-end.

### TournamentRegistration

Campos principais:

- `id`: uuid, obrigatório.
- `tournament_id`: uuid, FK para `tournaments`.
- `user_id`: uuid, FK para `profiles`.
- `display_name`: texto exibido na inscrição.
- `status`: enum `pending | confirmed | cancelled | rejected | checked_in`.
- `registration_type`: enum `individual | team`.
- `captain_user_id`: uuid opcional, preparado para torneios por equipe.
- `admin_notes`: texto opcional para observação administrativa.
- `decided_by` e `decided_at`: auditoria de confirmação, rejeição ou check-in.
- `cancelled_by` e `cancelled_at`: auditoria de cancelamento.
- `created_at` e `updated_at`: timestamps.

Regras:

- Nova inscrição começa como `pending`.
- Apenas inscrições `pending`, `confirmed` e `checked_in` contam como ativas.
- Índice parcial impede duplicidade ativa por `tournament_id + user_id`.
- Cancelamento preserva histórico; não há exclusão física no fluxo normal.
- Usuário comum só pode criar e cancelar a própria inscrição.
- Admin ou organizador autorizado do torneio pode confirmar, rejeitar e cancelar inscrições do torneio.
- Página pública só deve exibir inscrições `confirmed` ou `checked_in`.

## Atualização: equipes reais

### Decisão de modelagem

Torneio individual continua usando `tournament_registrations.user_id` como participante. Torneio por equipe usa `teams` e `team_members`; quando o capitão envia a equipe, o sistema cria uma inscrição em `tournament_registrations` com `registration_type = team`, `team_id` e `captain_user_id`. Assim a triagem administrativa continua centralizada em inscrições, mas os membros ficam normalizados em tabelas próprias.

### Tournament

Campos de equipe:

- `registration_type`: `individual | team`.
- `team_min_size`: tamanho mínimo de membros ativos.
- `team_max_size`: tamanho máximo de membros ativos.
- `allow_free_agents`: reserva para fluxo futuro de jogadores sem equipe.
- `require_full_team_before_registration`: quando verdadeiro, bloqueia envio de equipe incompleta.
- `team_registration_deadline`: prazo opcional específico para equipes.

### Team

- `id`: uuid, obrigatório.
- `tournament_id`: uuid, FK para `tournaments`.
- `name`: texto obrigatório, mínimo de dois caracteres.
- `status`: `draft | pending | confirmed | cancelled | rejected`.
- `captain_id`: uuid, FK para `profiles`.
- `created_by`: uuid, FK para `profiles`.
- `registration_id`: uuid opcional, FK lógica para inscrição criada.
- `admin_notes`: texto opcional.
- `decided_by`, `decided_at`: decisão administrativa.
- `cancelled_by`, `cancelled_at`: cancelamento.
- `created_at`, `updated_at`: timestamps.

Regras:

- Nome ativo não pode duplicar outro nome ativo no mesmo torneio.
- Capitão não pode ter mais de uma equipe ativa no mesmo torneio.
- Equipe só pode ser criada em torneio `team` com `registrations_open`.
- Equipe `confirmed`, `rejected` ou `cancelled` preserva histórico.

### TeamMember

- `id`: uuid, obrigatório.
- `tournament_id`: uuid, redundância controlada para índice/RLS.
- `team_id`: uuid, FK para `teams`.
- `user_id`: uuid, FK para `profiles`.
- `role`: `captain | member`.
- `status`: `active | removed`.
- `added_by`: uuid, quem adicionou.
- `removed_by`, `removed_at`: auditoria de remoção.
- `created_at`, `updated_at`: timestamps.

Regras:

- Exatamente um capitão ativo por equipe.
- Um usuário não pode estar ativo em duas equipes do mesmo torneio.
- Capitão não pode ser removido no MVP; transferência de capitania fica para versão futura.
- Capitão, admin ou organizador autorizado gerencia membros enquanto as inscrições permitirem.
## Atualização: chave mata-mata simples persistida

### TournamentRegistration

Campo adicionado:

- `seed`: inteiro opcional, positivo, usado pelo método `seeded`. Seeds duplicados no mesmo torneio são bloqueados por índice parcial para inscrições ativas.

### TournamentBracket

- `id`: uuid.
- `tournament_id`: FK para `tournaments`.
- `format`: `single_elimination`.
- `seeding_method`: `draw | seeded`.
- `size`: tamanho da chave, sempre potência de 2.
- `rounds_count`: quantidade de rodadas.
- `status`: `generated | published | archived`.
- `winner_registration_id`: inscrição campeã quando a final é concluída.
- `generated_by` e `generated_at`: auditoria de geração.
- `created_at` e `updated_at`: timestamps.

Regra: há no máximo uma chave ativa por torneio no MVP. Regerar remove a chave anterior e suas partidas por cascade.

### BracketMatch

- `id`: uuid.
- `bracket_id` e `tournament_id`: escopo da chave.
- `round_number`: rodada.
- `match_number`: posição na rodada.
- `status`: `pending | ready | bye | live | completed | disputed | cancelled`.
- `participant_a_registration_id` e `participant_b_registration_id`: slots da partida.
- `winner_registration_id`: vencedor definido.
- `score_a` e `score_b`: placar agregado simples.
- `next_match_id` e `next_match_slot`: destino do vencedor.
- `is_bye`: indica avanço automático sem confronto jogável.

RLS:

- Visitante e usuário autenticado leem chaves de torneios publicados.
- Admin e organizador autorizado leem, geram, regeram e gerenciam chave do torneio.
- Usuário comum não escreve em `tournament_brackets` nem `bracket_matches`.
- Avanço sensível passa pela RPC `complete_bracket_match`, que valida placar e permissão no banco.

## Atualizacao: resultados e auditoria

Novas estruturas do modulo de resultados:

- `match_results`: resultado atual da partida, com placar, vencedor, status, observacoes, usuario que registrou/confirmou, contestacao e resolucao.
- `match_result_history`: historico imutavel com placar anterior/novo, vencedor anterior/novo, status anterior/novo, usuario responsavel e motivo.
- `bracket_matches`: mantem placar e vencedor atuais para leitura rapida da chave, alem de `result_notes`, `submitted_by`, `submitted_at`, `confirmed_by` e `confirmed_at`.
- `match_result_status`: `confirmed`, `disputed`, `resolved`, `cancelled`.

Escritas sensiveis passam por RPCs. `match_results` e `match_result_history` nao recebem permissao direta de insert/update/delete para usuarios autenticados.

## Atualizacao: standings/ranking

Foram adicionadas estruturas de snapshot para rankings de pontos corridos e grupos:

### TournamentStanding

- `id`: uuid.
- `tournament_id`: FK para `tournaments`.
- `group_id`: texto opcional para grupos futuros.
- `scope`: escopo logico, por padrao `overall`.
- `status`: `provisional | official | archived`.
- `win_points`, `draw_points`, `loss_points`: configuracao de pontuacao usada no snapshot.
- `tie_breakers`: ordem explicita de desempate.
- `calculated_by` e `calculated_at`: auditoria de recalculo.
- `created_at` e `updated_at`.

### StandingEntry

- `standing_id`, `tournament_id`, `group_id`.
- `participant_registration_id` e `team_id` opcional.
- `display_name`.
- `played`, `wins`, `draws`, `losses`.
- `score_for`, `score_against`, `score_diff`.
- `points`, `position`.
- `tie_breaker_summary` e `is_technical_tie`.

RLS:

- Visitantes e autenticados leem standings de torneios publicados.
- Admin e organizador autorizado podem criar, atualizar e apagar snapshots do torneio que gerenciam.
- Usuario comum nao manipula ranking manualmente.

No MVP, a tela calcula a classificacao em TypeScript a partir de partidas finalizadas/confirmadas disponiveis. As tabelas de snapshot preparam persistencia e auditoria de rankings oficiais quando pontos corridos/grupos tiverem gerador proprio.
