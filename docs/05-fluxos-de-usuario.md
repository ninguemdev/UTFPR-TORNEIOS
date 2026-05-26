# Fluxos de usuário

## Usuário cria conta

- **Ator:** usuário comum.
- **Pré-condições:** usuário não autenticado.
- **Passos:** acessar cadastro; informar nome, e-mail e senha; confirmar envio; Supabase Auth cria usuário; sistema cria perfil com `role = user`, `avatar_key` padrão e RA vazio/opcional.
- **Erros possíveis:** e-mail inválido; e-mail já cadastrado; senha fraca; falha na criação do perfil.
- **Estado final:** usuário autenticado ou aguardando confirmação, com perfil vinculado a `auth.users.id`.

## Usuário faz login

- **Ator:** usuário comum ou admin.
- **Pré-condições:** conta existente.
- **Passos:** informar e-mail e senha; Supabase Auth valida credenciais; aplicação carrega perfil e permissões.
- **Erros possíveis:** credenciais inválidas; conta não confirmada; perfil ausente; sessão expirada.
- **Estado final:** sessão ativa com permissões derivadas do banco.

## Usuário edita perfil

- **Ator:** usuário autenticado.
- **Pré-condições:** sessão ativa e perfil existente.
- **Passos:** acessar perfil; editar nome exibido, RA e `avatar_key`; salvar.
- **Erros possíveis:** avatar inexistente; RA em formato inválido; tentativa de alterar `role`; falha por RLS.
- **Estado final:** perfil próprio atualizado; dados de outros usuários permanecem protegidos.

## Usuário solicita permissão para criar torneios

- **Ator:** usuário comum.
- **Pré-condições:** sessão ativa.
- **Passos:** acessar pedido de permissão; informar justificativa; enviar solicitação.
- **Erros possíveis:** pedido pendente já existente; justificativa ausente; usuário bloqueado.
- **Estado final:** solicitação criada com status `pending`.

## Admin aprova ou rejeita pedido

- **Ator:** admin.
- **Pré-condições:** pedido pendente.
- **Passos:** abrir painel administrativo; revisar usuário e justificativa; aprovar ou rejeitar; registrar justificativa da decisão; se aprovar, criar permissão `active` em `tournament_creator_permissions`.
- **Erros possíveis:** pedido já decidido; admin sem sessão válida; erro de policy/RLS.
- **Estado final:** pedido fica `approved` ou `rejected`; em aprovação, o pedido permanece histórico e uma permissão ativa revogável passa a autorizar criação de torneios.

## Admin revoga permissão de criar torneios

- **Ator:** admin.
- **Pré-condições:** usuário possui permissão `active` para criar torneios.
- **Passos:** abrir painel administrativo; acessar permissões ativas; informar motivo opcional de revogação; confirmar revogação.
- **Erros possíveis:** permissão inexistente; permissão já revogada; admin sem sessão válida; falha de RLS.
- **Estado final:** permissão muda para `revoked`, o histórico fica preservado e o usuário não consegue criar novos torneios.

## Organizador cria torneio

- **Ator:** admin ou usuário com permissão ativa para criar torneios.
- **Pré-condições:** usuário autenticado; `role = admin` ou `can_create_tournament() = true`.
- **Passos:** acessar dashboard; clicar em criar torneio; preencher nome, modalidade, datas e descrição; salvar rascunho.
- **Erros possíveis:** campos obrigatórios ausentes; datas inválidas; nome duplicado no mesmo contexto; usuário sem permissão; operação bloqueada por RLS.
- **Estado final:** torneio criado como rascunho.

## Organizador define formato

- **Ator:** admin ou usuário autorizado no torneio.
- **Pré-condições:** torneio em rascunho ou configuração aberta; permissão validada no banco.
- **Passos:** abrir configurações; escolher formato; definir melhor de N, terceiro lugar, pontuação e desempates; salvar.
- **Erros possíveis:** formato incompatível com número de participantes; configuração incompleta.
- **Estado final:** torneio possui formato validável.

## Organizador abre inscrições

- **Ator:** admin ou usuário autorizado no torneio.
- **Pré-condições:** torneio configurado com limites e período de inscrição; permissão validada no banco.
- **Passos:** revisar regras; definir janela; publicar inscrições.
- **Erros possíveis:** datas inválidas; limite máximo menor que mínimo; torneio sem modalidade.
- **Estado final:** status `registration_open`.

## Participante se inscreve

- **Ator:** participante.
- **Pré-condições:** inscrições abertas; usuário autenticado quando o torneio exigir vínculo de perfil.
- **Passos:** acessar página pública; preencher dados; aceitar regras; enviar inscrição.
- **Erros possíveis:** inscrições fechadas; participante duplicado; dados obrigatórios ausentes.
- **Estado final:** inscrição pendente ou aprovada.

## Capitão cria equipe

- **Ator:** capitão.
- **Pré-condições:** torneio por equipes com inscrições abertas.
- **Passos:** informar nome da equipe; adicionar membros; confirmar inscrição.
- **Erros possíveis:** equipe sem membros mínimos; membro duplicado; limite de equipe excedido.
- **Estado final:** equipe criada e vinculada à inscrição.

## Organizador fecha inscrições

- **Ator:** admin ou usuário autorizado no torneio.
- **Pré-condições:** inscrições abertas; permissão validada no banco.
- **Passos:** revisar inscritos; aprovar ou recusar pendências; fechar inscrições.
- **Erros possíveis:** participantes abaixo do mínimo; inscrições pendentes sem decisão.
- **Estado final:** status `registration_closed`.

## Organizador gera chave/tabela

- **Ator:** admin ou usuário autorizado no torneio.
- **Pré-condições:** inscrições fechadas, participantes aprovados e permissão validada no banco.
- **Passos:** escolher seeding ou sorteio; gerar estrutura; revisar; publicar ou manter provisória.
- **Erros possíveis:** participantes insuficientes; seeds duplicados; conflito de configuração.
- **Estado final:** chave, grupos ou tabela criada.

## Jogador faz check-in

- **Ator:** jogador ou capitão.
- **Pré-condições:** check-in aberto.
- **Passos:** acessar torneio; confirmar presença; receber confirmação.
- **Erros possíveis:** janela fechada; participante não aprovado; equipe incompleta.
- **Estado final:** participante marcado como confirmado.

## Partida acontece

- **Ator:** participantes e organizador.
- **Pré-condições:** partida agendada e participantes aptos.
- **Passos:** participantes entram no local/servidor; partida muda para ao vivo; jogo é disputado.
- **Erros possíveis:** atraso; ausência; problema técnico; participante irregular.
- **Estado final:** partida pronta para receber resultado, W.O. ou contestação.

## Resultado é enviado

- **Ator:** capitão, jogador ou organizador.
- **Pré-condições:** partida permite envio de resultado.
- **Passos:** informar placar; anexar observação quando necessário; enviar.
- **Erros possíveis:** placar inválido; empate não permitido; série incompleta.
- **Estado final:** resultado submetido.

## Resultado é confirmado

- **Ator:** admin ou usuário autorizado no torneio, conforme regra de confirmação.
- **Pré-condições:** resultado submetido; permissão validada no banco.
- **Passos:** revisar placar; confirmar; atualizar chave/ranking.
- **Erros possíveis:** resultado inconsistente; contestação aberta.
- **Estado final:** resultado confirmado e efeitos aplicados.

## Resultado é contestado

- **Ator:** participante, capitão ou organizador.
- **Pré-condições:** resultado submetido ou confirmado dentro do prazo de contestação.
- **Passos:** abrir contestação; informar motivo; enviar.
- **Erros possíveis:** prazo encerrado; usuário sem vínculo com partida; motivo vazio.
- **Estado final:** partida marcada como em disputa.

## Organizador resolve disputa

- **Ator:** admin ou usuário autorizado a resolver disputas.
- **Pré-condições:** disputa aberta; permissão validada no banco.
- **Passos:** analisar motivo; decidir manter, corrigir ou anular resultado; registrar justificativa.
- **Erros possíveis:** decisão sem justificativa; impacto em partidas dependentes.
- **Estado final:** disputa resolvida e auditoria registrada.

## Ranking é atualizado

- **Ator:** sistema.
- **Pré-condições:** resultado confirmado ou corrigido.
- **Passos:** recalcular tabela; aplicar desempates; marcar empates não resolvidos; atualizar exibição.
- **Erros possíveis:** critério de desempate inválido; dados incompletos.
- **Estado final:** ranking atualizado e critérios visíveis.

## Torneio é finalizado

- **Ator:** admin ou usuário autorizado no torneio.
- **Pré-condições:** partidas decisivas finalizadas ou decisão administrativa registrada.
- **Passos:** revisar campeão/classificação; publicar resultado final; finalizar torneio.
- **Erros possíveis:** partidas pendentes; disputas abertas; ranking ambíguo sem decisão.
- **Estado final:** status `finished`.

## Usuário se inscreve em torneio

- **Ator:** usuário autenticado.
- **Pré-condições:** torneio público com status `registrations_open`; usuário sem inscrição ativa no mesmo torneio.
- **Passos:** abrir página pública; informar nome de inscrição ou nome da equipe; enviar; sistema cria inscrição `pending`.
- **Erros possíveis:** usuário deslogado; torneio fechado; limite atingido; inscrição ativa duplicada; policy RLS negando operação.
- **Estado final:** inscrição pendente visível em "Minhas inscrições" e no painel do gestor.

## Usuário cancela própria inscrição

- **Ator:** usuário autenticado inscrito.
- **Pré-condições:** inscrição `pending` ou `confirmed`; torneio ainda em `registrations_open` ou `registrations_closed`.
- **Passos:** abrir "Minhas inscrições" ou página do torneio; acionar cancelamento; confirmar ação.
- **Erros possíveis:** torneio em andamento/finalizado/cancelado; inscrição já rejeitada/cancelada; tentativa de alterar dados administrativos.
- **Estado final:** inscrição fica `cancelled`, com `cancelled_by` e `cancelled_at`.

## Organizador gerencia inscrições

- **Ator:** admin global ou organizador autorizado do torneio.
- **Pré-condições:** gestor autenticado; torneio sob sua administração; inscrições existentes.
- **Passos:** abrir participantes; revisar pedidos; adicionar observação; confirmar, rejeitar ou cancelar inscrição.
- **Erros possíveis:** organizador com permissão revogada; tentativa de gerenciar torneio de outro usuário; status do torneio não permite ação.
- **Estado final:** inscrição atualizada com status e auditoria de decisão.

## Preparação para equipes

- **Ator:** organizador e futuro capitão.
- **Pré-condições:** torneio configurado com `registration_type = team`.
- **Passos:** organizador define tamanho mínimo/máximo; usuário informa nome da equipe; sistema registra `captain_user_id`.
- **Erros possíveis:** tamanho de equipe inválido; tentativa de inscrição de tipo incompatível com o torneio.
- **Estado final:** inscrição por equipe fica pronta para receber membros quando o módulo de equipes for implementado.

## Admin altera torneio em andamento ou encerrado

- **Ator:** admin.
- **Pré-condições:** sessão ativa; torneio existente; justificativa administrativa.
- **Passos:** acessar painel administrativo; abrir torneio; alterar configuração, resultado, inscrição ou bloqueio; informar justificativa; confirmar.
- **Erros possíveis:** ausência de justificativa; impacto em partidas dependentes; falha de policy; tentativa de alteração sem auditoria.
- **Estado final:** alteração aplicada, auditoria criada e dados derivados marcados para recálculo quando necessário.

## Atualização: fluxos de equipes reais

### Capitão cria equipe

- **Ator:** usuário autenticado.
- **Pré-condições:** torneio público por equipe, com status `registrations_open`; usuário ainda não é capitão de equipe ativa no torneio.
- **Passos:** abrir página de equipes; informar nome; enviar; sistema cria `teams` em `draft` e adiciona o criador como membro `captain`.
- **Erros possíveis:** torneio individual; inscrições fechadas; nome inválido; nome duplicado; usuário já possui equipe ativa.
- **Estado final:** equipe em rascunho, visível para capitão, organizador e admin.

### Capitão adiciona membro

- **Ator:** capitão da equipe.
- **Pré-condições:** equipe em torneio com inscrições abertas; membro existe em `profiles`.
- **Passos:** informar email ou RA exato; sistema localiza profile; adicionar como membro `active`.
- **Erros possíveis:** usuário não encontrado; usuário já está em equipe ativa do torneio; equipe atingiu `team_max_size`; ator não é capitão/gestor.
- **Estado final:** membro ativo aparece na lista da equipe.

### Capitão envia equipe para inscrição

- **Ator:** capitão da equipe.
- **Pré-condições:** equipe em `draft`; torneio por equipe aberto; equipe atinge `team_min_size` quando exigido.
- **Passos:** revisar membros; acionar envio; RPC cria inscrição `pending` com `team_id`; equipe muda para `pending`.
- **Erros possíveis:** equipe incompleta; inscrição duplicada ativa; prazo encerrado; torneio fechado.
- **Estado final:** inscrição pendente aparece no painel de participantes e a equipe aguarda decisão.

### Capitão exclui equipe em rascunho

- **Ator:** capitão da equipe, admin ou organizador autorizado.
- **Pré-condições:** equipe existente em `draft`; ator pode gerenciar a equipe.
- **Passos:** abrir detalhes; confirmar exclusão; sistema executa `delete` em `teams`.
- **Erros possíveis:** equipe já enviada/confirmada; ator sem permissão; policy RLS negando exclusão.
- **Estado final:** equipe e vínculos de membros são removidos fisicamente por cascade.

### Gestor decide inscrição de equipe

- **Ator:** admin global ou organizador autorizado do torneio.
- **Pré-condições:** inscrição por equipe em `pending`.
- **Passos:** abrir participantes; revisar equipe e membros; confirmar, rejeitar ou cancelar com observação.
- **Erros possíveis:** ator sem permissão; status inválido; torneio bloqueado.
- **Estado final:** inscrição muda para `confirmed`, `rejected` ou `cancelled`; equipe sincroniza status correspondente.

### Membro consulta equipe

- **Ator:** membro ativo.
- **Pré-condições:** usuário pertence à equipe.
- **Passos:** abrir detalhes da equipe; visualizar membros, capitão e status.
- **Erros possíveis:** usuário removido; equipe não encontrada; RLS nega leitura.
- **Estado final:** membro visualiza a equipe, mas não consegue editar se não for capitão/gestor.
## Atualização: geração e avanço de chave

### Organizador gera chave mata-mata

- **Ator:** admin ou organizador autorizado.
- **Pré-condições:** torneio `single_elimination`, ao menos duas inscrições confirmadas ou com check-in, permissão validada por `can_manage_tournament`.
- **Passos:** abrir `/torneios/:id/chave`; escolher sorteio ou seeding; confirmar geração; sistema salva `tournament_brackets` e `bracket_matches`.
- **Erros possíveis:** participantes insuficientes; torneio em status inválido; chave já existente sem confirmação de regeração; RLS negando permissão.
- **Estado final:** chave persistida com método, byes e destinos de avanço.

### Participante visualiza chave

- **Ator:** visitante ou usuário autenticado.
- **Pré-condições:** torneio publicado.
- **Passos:** abrir página pública ou rota de chave; consultar rodadas, partidas, byes e status.
- **Erros possíveis:** torneio em rascunho; chave ainda não gerada.
- **Estado final:** usuário visualiza apenas dados públicos da chave.

### Organizador confirma vencedor

- **Ator:** admin ou organizador autorizado.
- **Pré-condições:** partida com dois participantes e `status = ready` ou `live`.
- **Passos:** informar placar; sistema valida que não há empate; determina vencedor coerente com o placar; RPC avança vencedor para `next_match_id`.
- **Erros possíveis:** placar inválido; vencedor fora da partida; partida pendente ou bye; ator sem permissão.
- **Estado final:** partida fica `completed`; próxima partida recebe participante; final define campeão da chave.

## Atualizacao: fluxo de resultado

Fluxo escolhido para o MVP:

1. Admin ou organizador autorizado registra placar na tela da chave.
2. O resultado e confirmado imediatamente e o vencedor avanca na chave.
3. Participante autenticado da partida pode contestar informando motivo.
4. A partida fica com status `disputed`.
5. Admin ou organizador resolve a contestacao mantendo o resultado ou cancelando-o para novo lancamento.
6. Correcoes de resultado finalizado exigem justificativa e entram no historico.

Participante comum nao confirma resultado administrativamente e nao altera partida alheia.

## Atualizacao: fluxo de ranking

### Visitante consulta ranking

- **Ator:** visitante ou usuario autenticado.
- **Pre-condicoes:** torneio publicado.
- **Passos:** abrir `/torneios/:id/ranking`; sistema carrega participantes elegiveis e partidas finalizadas/confirmadas; tela mostra criterios e tabela.
- **Erros possiveis:** torneio em rascunho, sem permissao de leitura, formato ainda sem ranking completo.
- **Estado final:** visitante entende pontuacao, desempates e se o ranking esta vazio/provisorio.

### Organizador recalcula ranking

- **Ator:** admin ou organizador autorizado.
- **Pre-condicoes:** permissao validada por `can_manage_tournament`.
- **Passos:** abrir ranking; acionar recalculo; sistema refaz o calculo a partir dos resultados confirmados.
- **Erros possiveis:** RLS negando leitura, partidas contestadas ignoradas, formato sem gerador de tabela.
- **Estado final:** classificacao exibida reflete o estado atual dos resultados confiaveis.

## Atualizacao: auditoria e bloqueios administrativos

### Admin cria bloqueio administrativo

- **Ator:** admin global.
- **Pre-condicoes:** login admin e motivo definido.
- **Passos:** abrir `/admin`; preencher escopo, ID do escopo quando necessario, acao, motivo e expiracao opcional; salvar.
- **Erros possiveis:** escopo sem ID quando nao e global; acao duplicada para o mesmo escopo; RLS negando escrita por usuario nao admin.
- **Estado final:** `action_locks` registra o bloqueio, `audit_logs` registra `action_lock_created` e a acao passa a ser validada no banco.

### Usuario comum tenta acao bloqueada

- **Ator:** usuario comum ou organizador nao admin.
- **Pre-condicoes:** bloqueio ativo global ou do escopo da acao.
- **Passos:** tentar criar torneio, inscrever-se, cancelar inscricao, editar torneio, gerar chave, registrar/contestar resultado, gerenciar equipes ou recalcular ranking.
- **Erros possiveis:** erro do banco `Acao ... bloqueada por administracao`.
- **Estado final:** a escrita e negada por trigger/RPC; a UI pode exibir o motivo lendo bloqueios ativos.

### Admin consulta auditoria geral

- **Ator:** admin global.
- **Pre-condicoes:** eventos sensiveis ja registrados.
- **Passos:** abrir `/admin`; filtrar por acao, entidade ou torneio.
- **Erros possiveis:** nenhum evento encontrado; RLS nega leitura para usuario comum.
- **Estado final:** admin visualiza data, ator, entidade, torneio e motivo sem expor logs ao publico.

### Admin altera bloqueio

- **Ator:** admin global.
- **Pre-condicoes:** bloqueio existente.
- **Passos:** editar motivo, ativar/desativar ou remover bloqueio.
- **Erros possiveis:** RLS negando escrita; tentativa de alterar escopo/acao original; motivo vazio.
- **Estado final:** bloqueio atualizado/removido e auditoria registra `action_lock_updated` ou `action_lock_deleted`.
