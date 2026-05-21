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
| can_create_tournaments | boolean derivado | Não persistido | Tournament | Permissão calculada por `public.can_create_tournaments()`: admin global ou usuário com pedido `approved`. |
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
| status | enum | Sim | - | draft, published, registration_open, running, finished, cancelled. |
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
- Criação de torneio exige `role = admin` ou permissão derivada de pedido `approved` em `tournament_creator_requests`.
- Usuário aprovado para criar torneios não vira admin global; a decisão deve ser consultada por função segura como `public.can_create_tournaments()`.
- Alteração de torneio em andamento/encerrado exige admin ou regra explícita registrada.
- Correção de resultado confirmado exige auditoria e permissão validada no banco.

## Índices úteis

- `Tournament.slug`.
- `Tournament.organizerId`.
- `Profile.userId`.
- `Profile.role`.
- `TournamentCreatorRequest.requesterId + status`.
- `Participant.tournamentId`.
- `Registration.tournamentId + participantId`.
- `Match.tournamentId + stageId + round`.
- `Match.scheduledAt`.
- `Standing.stageId + participantId`.
- `AuditLog.entityType + entityId`.

## Status possíveis

- Torneio: draft, published, registration_open, registration_closed, running, finished, cancelled.
- Pedido de criação de torneio: pending, approved, rejected, cancelled.
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
- `ActionLockScope`: global, tournament, match, registration.

## RLS e policies mínimas

Todas as tabelas importantes devem ter RLS habilitado. Policies iniciais recomendadas:

- `profiles`: usuário autenticado lê perfis públicos necessários; atualiza apenas o próprio perfil; apenas admin altera `role`.
- `tournament_creator_requests`: usuário cria e lê os próprios pedidos; admin lê todos e decide.
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
