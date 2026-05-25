# Regras de torneios

Este documento transforma o funcionamento esperado de torneios em regras práticas para implementação. O arquivo `Funcionamento de torneios.pdf` ainda não está presente no repositório; portanto, as regras abaixo usam as premissas declaradas em `AGENTS.md` e no escopo do projeto.

## Como um torneio é definido

Um torneio é definido por:

- Nome, modalidade e descrição.
- Organizador responsável.
- Usuários autorizados a administrar o torneio.
- Janela de inscrições.
- Participantes ou equipes elegíveis.
- Formato competitivo.
- Critérios de seeding ou sorteio.
- Calendário de partidas.
- Regras de resultado.
- Critérios de ranking e desempate.
- Premiação, classificação ou objetivo final.
- Regras de W.O., atraso, contestação e correção.
- Status de publicação das tabelas, chaves e rankings.
- Regras de permissão para criação, edição, correção e ações administrativas.

## Decisões do organizador

Antes de publicar um torneio, o organizador deve decidir:

- Quem pode participar.
- Se a competição é individual ou por equipes.
- Quantidade mínima e máxima de participantes.
- Formato: mata-mata, pontos corridos, grupos + playoffs ou outro.
- Se haverá séries melhor de N.
- Se haverá disputa de terceiro lugar.
- Se haverá cabeças de chave.
- Se haverá sorteio aleatório.
- Como serão marcados horários e locais/servidores.
- Como resultados serão enviados e confirmados.
- Quais critérios de desempate serão aplicados.
- Como disputas serão resolvidas.
- Quais ações exigem aprovação de admin.
- Quais dados ficarão públicos e quais ficarão restritos a usuários autenticados.

## Regras de autenticação e autorização

- O sistema deve ter autenticação com email e senha via Supabase Auth.
- Senhas não devem ser armazenadas manualmente em tabelas próprias.
- Existem dois tipos principais de usuário: `admin` e `user`.
- `admin` é administrador global do site e pode agir sobre configurações globais, torneios em andamento ou encerrados, pedidos, resultados, disputas e dados administrativos.
- `user` é usuário comum autenticado e pode editar apenas o próprio perfil, informar RA, escolher `avatar_key`, visualizar torneios públicos, inscrever-se e solicitar permissão para criar torneios.
- Usuários comuns não podem alterar dados de outros usuários, configurações globais ou torneios sem autorização explícita.
- A permissão para criar torneios deve ser solicitada pelo usuário e aprovada ou rejeitada por admin.
- A interface pode ocultar ações sem permissão, mas a regra definitiva deve estar no banco por Row Level Security, policies ou funções RPC protegidas.
- Toda ação administrativa sensível deve registrar usuário, data, entidade afetada, valor anterior quando aplicável, valor novo e justificativa.

## Formato, seeding, draw, scheduling e ranking

**Formato** define a estrutura competitiva: mata-mata, pontos corridos, grupos, playoffs ou suíço.

**Seeding** define distribuição baseada em força, ranking, histórico ou semente manual justificada.

**Draw/sorteio** define alocação aleatória de participantes em posições, grupos ou confrontos.

**Scheduling** define data, hora, local/servidor, rodada, fase, ordem e status das partidas.

**Ranking** define como participantes são classificados a partir de resultados e desempates.

Esses conceitos devem ser modelados separadamente. Um torneio pode usar mata-mata com seeding, mata-mata com sorteio, grupos com seeding parcial ou pontos corridos sem sorteio.

## Critérios de qualidade

### Eficácia

O formato deve aumentar a chance de revelar os melhores participantes. Exemplo: pontos corridos tende a ser mais eficaz que mata-mata único, mas exige mais partidas.

### Justiça

Participantes equivalentes devem receber tratamento equilibrado. Seeding deve ser explícito e justificável. Sorteio deve ser auditável quando usado.

### Atratividade

O torneio precisa ser fácil de acompanhar. Chaves, grupos e rankings devem indicar fase, rodada, status, classificados e critérios usados.

### Incentivos e strategy-proofness

As regras devem reduzir incentivos para perder de propósito, manipular saldo ou escolher adversários. Critérios de desempate devem ser conhecidos antes do início.

## Regras para participantes

- Cada participante deve ter identificador único no torneio.
- Um participante não pode estar duplicado na mesma competição.
- Participante individual deve ter nome exibível e contato ou vínculo com perfil.
- Participantes podem ter status: pendente, aprovado, recusado, confirmado, desistente ou desclassificado.
- Participantes desistentes não devem receber novos agendamentos.
- Participantes autenticados só podem alterar dados próprios ou dados de equipe quando forem capitães/autorizados.
- RA e dados de contato não devem aparecer em páginas públicas sem necessidade explícita.

## Regras para equipes

- Cada equipe deve ter nome, capitão e lista de membros.
- O capitão representa a equipe em inscrições, check-in e envio de resultados.
- O número de membros deve respeitar limites do torneio.
- Alterações de escalação devem ser bloqueadas após prazo definido ou registradas em auditoria.
- Uma equipe pode ser desclassificada por W.O. repetido, irregularidade ou decisão administrativa justificada.
- Admins podem corrigir equipe ou escalação excepcionalmente, inclusive em torneios em andamento ou encerrados, desde que registrem justificativa.

## Regras para partidas

- Toda partida deve pertencer a um torneio e, quando aplicável, a uma fase e rodada.
- Toda partida deve ter status claro.
- Status mínimos: pendente, agendada, ao vivo, finalizada, cancelada e em disputa.
- Partida agendada deve ter data, hora e local/servidor quando o torneio exigir.
- Resultado só pode ser registrado se a partida estiver em estado apropriado.
- Partida finalizada deve guardar placar, vencedor e histórico de confirmação.

## Regras para W.O.

- W.O. acontece quando participante ou equipe não comparece, atrasa além da tolerância ou descumpre regra objetiva de presença.
- O placar padrão de W.O. deve ser configurado por modalidade.
- W.O. deve ter justificativa e responsável pelo registro.
- W.O. pode ser contestado dentro de prazo definido.
- W.O. recorrente pode causar desclassificação se o regulamento prever.

## Regras para atraso

- O torneio deve definir tolerância de atraso.
- Atrasos devem ser registrados quando impactarem resultado ou agenda.
- O organizador pode remarcar partida, aplicar W.O. ou colocar em disputa.
- A decisão deve ser registrada com justificativa.

## Regras para confirmação de resultado

- Resultado enviado deve ser validado contra o formato da partida.
- Resultado pode ser confirmado automaticamente ou por organizador.
- Em partidas entre participantes, pode haver confirmação por ambos os lados.
- Resultado confirmado atualiza ranking, chave ou classificação.
- Resultado confirmado não deve ser alterado sem auditoria.

## Regras para contestação

- Participante, capitão ou organizador pode abrir contestação quando permitido.
- Contestação deve conter motivo e, no futuro, evidências.
- Partida contestada fica com status "em disputa".
- Ranking e chave derivados devem indicar que existem dados provisórios.
- Organizador resolve a disputa com decisão registrada.

## Regras para troca/correção de resultado

- Correções exigem permissão de usuário autorizado no torneio ou admin.
- Admins podem corrigir resultados em torneios em andamento ou encerrados quando houver justificativa administrativa.
- Toda correção deve registrar valor anterior, valor novo, usuário, data e justificativa.
- Correção pode recalcular ranking, avanço de fase e partidas dependentes.
- Se a correção afetar partidas futuras já realizadas, o sistema deve alertar o organizador.

## Regras para publicação de chave e ranking

- Chave ou ranking podem ser rascunho, provisórios ou publicados.
- Informações provisórias devem ser sinalizadas na interface.
- Publicação deve registrar data e responsável.
- Alterações após publicação devem gerar auditoria.
- Ranking nunca deve esconder empate não resolvido.

## Regras de banco e segurança

- Supabase é a solução recomendada para autenticação, banco PostgreSQL, RLS e controle de acesso.
- Todas as tabelas importantes devem ter Row Level Security habilitado.
- Policies devem garantir que usuários comuns leiam apenas dados públicos, próprios ou vinculados às equipes/torneios em que participam.
- Policies devem garantir que somente admins ou usuários autorizados alterem torneios, partidas, resultados e disputas.
- Chaves privadas e service role keys nunca devem ser usadas no front-end.
- Validações de permissão devem ser testadas com chamadas diretas ao banco/API, não apenas pela interface.

## Atualização: equipes reais no MVP

- Torneio individual (`registration_type = individual`) usa inscrição direta em `tournament_registrations`.
- Torneio por equipe (`registration_type = team`) exige criação de `teams` e membros em `team_members`.
- O criador da equipe vira capitão automaticamente.
- Cada equipe deve ter exatamente um capitão ativo.
- O capitão pode editar nome, adicionar membros e remover membros não capitães enquanto as inscrições estiverem abertas.
- Admin global e organizador autorizado do torneio podem gerenciar qualquer equipe daquele torneio.
- Usuário comum não pode editar equipe de outro capitão.
- Um usuário só pode participar de uma equipe ativa por torneio.
- Um capitão só pode ter uma equipe ativa por torneio.
- O nome da equipe deve ter pelo menos dois caracteres e não pode duplicar outro nome ativo no mesmo torneio.
- Equipe com menos membros que `team_min_size` não pode ser enviada para inscrição quando `require_full_team_before_registration` estiver ativo.
- Equipe com mais membros que `team_max_size` é bloqueada por trigger no banco.
- O envio da equipe cria uma inscrição `pending` com `registration_type = team` e `team_id`.
- A aprovação, rejeição ou cancelamento da inscrição atualiza o status da equipe, preservando histórico.
- Convite por email com aceite do convidado fica planejado para versão futura; no MVP o capitão adiciona usuários existentes por email ou RA exato.
## Atualização: mata-mata simples no MVP

- O formato competitivo implementado nesta etapa é `single_elimination`.
- A chave usa apenas inscrições confirmadas ou com check-in (`confirmed` e `checked_in`; `registered` permanece como compatibilidade legada).
- Em torneio individual, cada inscrição confirmada representa um participante.
- Em torneio por equipe, cada inscrição confirmada com `team_id` representa uma equipe válida.
- Admin global pode gerar, regerar e gerenciar qualquer chave.
- Organizador autorizado pode gerar, regerar e gerenciar apenas torneios que administra.
- Usuário comum pode visualizar chave de torneio público, mas não pode gerar chave nem avançar vencedor.
- A chave não pode ser gerada com menos de dois participantes.
- Se já existir chave, a interface exige confirmação clara antes de regerar, pois resultados e avanços podem ser perdidos.
- O sorteio ocorre somente no momento da geração e fica salvo no banco.
- Byes são partidas estruturais com `status = bye`; não há confronto jogável contra participante vazio.
- Participante com bye avança automaticamente para a próxima rodada.
- Resultado de partida pronta exige placar inteiro, não negativo, sem empate e vencedor coerente com o placar.
- A final concluída define `winner_registration_id` na chave.

## Atualizacao: resultados em mata-mata simples

- Resultado so pode ser registrado em partida `ready` ou `live`; correcao usa partida `completed` ou `disputed` com justificativa.
- Partida com bye nao recebe placar manual.
- Empate nao e permitido no `single_elimination`.
- O vencedor e derivado do placar e precisa ser um dos dois participantes.
- Ao confirmar, o vencedor alimenta a proxima partida pelo par `next_match_id` e `next_match_slot`.
- Se uma correcao troca o vencedor e a proxima partida ja tem resultado, esta etapa bloqueia a correcao para evitar chave inconsistente.
- Participantes podem contestar resultado finalizado; admin ou organizador resolve mantendo ou cancelando o resultado.
