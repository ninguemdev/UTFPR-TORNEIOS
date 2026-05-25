# Rotas e telas

As rotas abaixo são proposta inicial. A implementação pode começar sem roteador externo, mas deve manter esta estrutura como referência.

| Rota | Tela | Objetivo | Usuário principal | Componentes | Estados obrigatórios |
| --- | --- | --- | --- | --- | --- |
| `/` | Landing page | Apresentar o sistema e torneios em destaque. | Visitante | Hero, lista de torneios, CTA. | vazio, carregando, erro, sucesso |
| `/login` | Login/cadastro | Entrar ou criar conta. | Organizador, participante | Form, input, button, alert. | vazio, carregando, erro, sucesso |
| `/dashboard` | Dashboard | Resumir torneios e pendências. | Organizador | Cards, tabela, ações rápidas. | vazio, carregando, erro, sucesso, sem permissão |
| `/torneios` | Lista de torneios | Listar torneios públicos ou do usuário. | Visitante, organizador | TournamentCard, filtros, busca. | vazio, carregando, erro, sucesso |
| `/torneios/novo` | Criar torneio | Criar rascunho. | Organizador | Form, steps, validation summary. | vazio, carregando, erro, sucesso, sem permissão |
| `/torneios/:id/editar` | Editar torneio | Ajustar dados e regras. | Organizador | Form, tabs, settings panel. | carregando, erro, sucesso, sem permissão |
| `/t/:slug` | Página pública do torneio | Exibir informações públicas. | Visitante | Header, tabs, bracket, ranking, matches. | vazio, carregando, erro, sucesso |
| `/t/:slug/inscricao` | Inscrição | Inscrever participante/equipe. | Participante, capitão | Form, team builder, terms. | vazio, carregando, erro, sucesso |
| `/torneios/:id/participantes` | Participantes | Gerenciar inscritos. | Organizador | Table, filters, status badge. | vazio, carregando, erro, sucesso, sem permissão |
| `/torneios/:id/equipes` | Equipes | Gerenciar equipes e membros. | Organizador, capitão | TeamCard, member list, form. | vazio, carregando, erro, sucesso, sem permissão |
| `/torneios/:id/chave` | Chave | Visualizar e gerenciar mata-mata. | Organizador, visitante | Bracket, MatchCard, status banner. | vazio, carregando, erro, sucesso |
| `/torneios/:id/grupos` | Grupos | Visualizar grupos e classificação. | Organizador, visitante | GroupTabs, RankingTable, MatchList. | vazio, carregando, erro, sucesso |
| `/torneios/:id/partidas` | Partidas | Listar agenda e status. | Organizador, participante | MatchCard, filters, calendar list. | vazio, carregando, erro, sucesso |
| `/partidas/:id/resultado` | Resultado da partida | Enviar ou revisar resultado. | Capitão, jogador, organizador | ScoreForm, MatchSummary, dispute action. | carregando, erro, sucesso, sem permissão |
| `/torneios/:id/ranking` | Ranking | Exibir classificação e critérios. | Todos | RankingTable, criteria list, alerts. | vazio, carregando, erro, sucesso |
| `/torneios/:id/configuracoes` | Configurações | Ajustar formato, pontuação e regras. | Organizador | Tabs, settings forms. | carregando, erro, sucesso, sem permissão |
| `/torneios/:id/disputas` | Disputas | Gerenciar contestações. | Organizador | DisputeList, decision modal. | vazio, carregando, erro, sucesso, sem permissão |
| `/admin` | Admin | Administrar usuários, torneios e auditoria. | Administrador | Tables, audit log, filters. | vazio, carregando, erro, sucesso, sem permissão |

## Regras gerais de tela

- Cada página deve ter apenas um `h1`.
- Títulos devem seguir hierarquia correta.
- Ações primárias devem ser `button`.
- Navegação deve usar `a` ou componente equivalente sem quebrar semântica.
- Todos os formulários devem ter labels.
- Estados de erro devem explicar o problema e sugerir ação.
- Estados vazios devem indicar o próximo passo.
- Estados sem permissão não devem esconder completamente o motivo.
## Atualização: inscrições

### `/minhas-inscricoes`

- **Objetivo:** permitir que usuário acompanhe e cancele as próprias inscrições.
- **Usuário principal:** usuário autenticado.
- **Componentes:** cards de inscrição, badge de status, link para torneio, botão de cancelamento.
- **Estados:** vazio, carregando, erro, sucesso, ação bloqueada.

### `/torneios/:id`

- **Objetivo adicional:** exibir estado de inscrição do usuário no torneio.
- **Usuário principal:** visitante e usuário autenticado.
- **Componentes adicionais:** formulário de inscrição, estado "login necessário", estado "já inscrito", estado "inscrições fechadas", lista pública de confirmados.
- **Estados:** sem login, pendente, confirmada, rejeitada, cancelada, lotado, fechado.

### `/torneios/:id/participantes`

- **Objetivo adicional:** servir como lista pública e painel de gestão de inscritos.
- **Usuário principal:** público para confirmados; admin/organizador para gestão completa.
- **Componentes adicionais:** tabela de inscritos, observação administrativa, ações confirmar/rejeitar/cancelar.
- **Estados:** sem participantes confirmados, pendências internas, erro de permissão, ação inválida por status.

## Atualização: telas de equipes

### `/torneios/:id/equipes`

- **Objetivo:** listar equipes do torneio e permitir criação de equipe pelo capitão quando o torneio for por equipe.
- **Usuário principal:** capitão, organizador e admin.
- **Componentes:** TeamCard, TeamStatusBadge, contador mínimo/máximo, formulário de criação de equipe, empty state.
- **Estados:** torneio individual, login necessário, inscrições fechadas, equipe já criada, carregando, erro, vazio e sucesso.

### `/torneios/:id/equipes/:teamId`

- **Objetivo:** exibir detalhes da equipe, membros e ações de gestão.
- **Usuário principal:** capitão; organizador/admin para revisão.
- **Componentes:** formulário de nome da equipe, lista de membros, badge de capitão, busca por email/RA, ações de remover membro e enviar inscrição.
- **Estados:** equipe incompleta, equipe completa, pendente, confirmada, rejeitada, cancelada, carregando, erro e sem permissão.

### Integração com `/torneios/:id`

- Torneios individuais exibem botão de inscrição direta.
- Torneios por equipe exibem chamada para criar ou acessar equipes.
- Participantes públicos continuam derivados de inscrições `confirmed` ou `checked_in`.
## Atualização: tela real de chave

### `/torneios/:id/chave`

- **Objetivo:** visualizar e gerenciar a chave `single_elimination`.
- **Usuário principal:** visitante para leitura pública; admin/organizador para geração e avanço.
- **Componentes:** formulário de método (`draw` ou `seeded`), resumo da chave, rodadas, partidas, badges de status, formulário de placar para gestores.
- **Estados:** carregando, erro, chave inexistente, chave gerada, bye, partida pendente, partida pronta, partida finalizada, campeão definido.
- **Acessibilidade:** botões reais, labels nos placares, mensagem de erro em `role="alert"`, foco visível herdado do tema e layout em lista por rodada no mobile.

Integrações:

- `/torneios` exibe ação "Chave" em cada card.
- `/torneios/:id` exibe ação "Ver chave".
- `/torneios/:id/participantes` permite gestor preencher seed básico por inscrição.

## Atualizacao: tela de chave e resultados

`/torneios/:id/chave` passa a concentrar:

- visualizacao de rodadas, partidas, byes, placar e vencedor;
- formulario administrativo de resultado;
- campo de observacoes do resultado;
- justificativa obrigatoria para correcao;
- botao de contestacao para participante autenticado;
- resolucao administrativa de contestacao;
- painel simples de resultados contestados;
- historico por partida carregado sob demanda.

A tela continua mobile-first: a chave aparece como lista por rodada em telas pequenas e sem rolagem horizontal obrigatoria.
