# Testes e validação

## Objetivo

Garantir que regras de torneio, ranking, geração de partidas, permissões e interfaces funcionem de forma previsível e auditável.

## Testes unitários para algoritmos

- Geração de chave mata-mata.
- Aplicação de seeding.
- Sorteio com registro de método.
- Avanço de vencedores.
- Geração de round robin.
- Cálculo de ranking.
- Aplicação de desempates.
- Validação de resultado.
- Detecção de conflito de agenda.

## Testes de ranking

- Vitória, empate e derrota com pontuação padrão.
- Pontuação customizada.
- Saldo de pontos/gols/rounds.
- Pontos marcados.
- Confronto direto.
- Empate não resolvido.
- W.O. com penalidade.

## Testes de desempate

- Dois participantes empatados em pontos.
- Três participantes empatados em pontos.
- Confronto direto aplicável.
- Confronto direto não aplicável.
- Critério final ainda empatado.
- Ordem de critérios configurável.

## Testes de geração de chave

- 3 participantes com bye.
- 4 participantes sem bye.
- 5 participantes com byes.
- 8 participantes com chave completa.
- 16 participantes com chave completa.
- Seeding distribuindo favoritos.
- Sorteio sem duplicar participantes.
- Terceiro lugar habilitado.
- Melhor de 3, 5 e 7.

## Testes de round robin

- 3 participantes com folga.
- 4 participantes com 3 rodadas.
- 5 participantes com folga em cada rodada.
- Turno único.
- Turno e returno.
- Nenhum confronto duplicado no turno único.

## Testes de permissões

- Visitante não cria torneio.
- Usuário comum cria conta, faz login e edita apenas o próprio perfil.
- Usuário comum escolhe apenas `avatar_key` permitido.
- Usuário comum informa RA sem expor esse dado publicamente.
- Usuário comum não altera dados de outro usuário.
- Usuário comum não altera `role`, `can_create_tournaments` ou configurações globais.
- Usuário comum solicita permissão para criar torneios.
- Admin aprova ou rejeita pedido de criação de torneio.
- Aprovar pedido cria permissão `active` em `tournament_creator_permissions`.
- Usuário com permissão ativa cria torneio.
- Admin revoga permissão ativa e o usuário deixa de criar torneios.
- Usuário revogado não consegue reativar permissão por chamada direta.
- Usuário não aprovado não cria torneio mesmo tentando chamada direta.
- Participante não corrige resultado confirmado sem permissão.
- Capitão envia resultado da própria equipe.
- Usuário autorizado gerencia torneio próprio.
- Admin acessa auditoria.
- Admin altera torneio em andamento ou encerrado com justificativa.
- Admin resolve disputa e edita resultado com auditoria.

## Testes de autenticação e segurança

- Cadastro com e-mail e senha via Supabase Auth.
- Login com credenciais válidas.
- Login recusado com senha inválida.
- Logout encerra sessão.
- Recuperação de senha usa fluxo do provedor.
- Nenhuma tabela própria contém senha ou hash de senha.
- Nenhuma chave privada aparece no front-end, bundle, `.env` público ou código versionado.
- Apenas URL pública e chave anon do Supabase podem ser usadas no cliente.

## Testes de RLS e banco

Quando Supabase for implementado, criar testes ou validações manuais com usuários diferentes:

- RLS habilitado em `profiles`, `tournaments`, `registrations`, `teams`, `matches`, `match_results`, `disputes`, `audit_logs`, `global_settings`, `tournament_creator_requests` e `tournament_creator_permissions`.
- Usuário A não lê dados privados do usuário B.
- Usuário A não atualiza perfil do usuário B.
- Usuário comum não altera `profiles.role`.
- Usuário comum não atualiza `global_settings`.
- Usuário comum não edita torneio sem autorização.
- Usuário comum lê apenas a própria situação em `tournament_creator_permissions`.
- Usuário comum não cria, edita, revoga nem reativa permissões.
- `public.can_create_tournament()` retorna falso para usuário revogado e verdadeiro para admin.
- Admin consegue ler dados administrativos.
- Admin consegue alterar torneio em andamento/encerrado com auditoria.
- Escrita direta no banco sem permissão é negada por policy, mesmo que a interface esconda o botão.
- RPCs sensíveis registram `AuditLog` na mesma transação.

## Testes de formulário

- Campos obrigatórios.
- Datas inválidas.
- Limites mínimo e máximo.
- Nome de equipe vazio.
- Membros duplicados.
- Mensagens de erro acessíveis.

## Testes de responsividade

Validar larguras:

- 320px.
- 375px.
- 768px.
- 1024px.
- 1440px.

Verificar:

- Sem overflow horizontal indevido.
- Botões clicáveis.
- Tabelas legíveis.
- Chaves navegáveis.
- Cards sem texto cortado.

## Testes de acessibilidade

- Apenas um `h1` por página.
- Labels em inputs.
- Foco visível.
- Navegação por teclado.
- Contraste de texto.
- Texto alternativo em imagens relevantes.
- `aria-label` em botões só com ícone.

## Testes de fluxo completo

- Organizador cria torneio.
- Abre inscrições.
- Participantes se inscrevem.
- Organizador fecha inscrições.
- Gera chave.
- Registra resultado.
- Confirma resultado.
- Ranking/chave atualiza.
- Torneio é finalizado.

## Testes de fluxo completo com autenticação

- Usuário cria conta.
- Usuário edita perfil com RA e avatar pré-definido.
- Usuário solicita permissão para criar torneios.
- Admin aprova o pedido.
- Usuário cria torneio.
- Usuário abre inscrições.
- Participante se inscreve.
- Admin resolve disputa e confirma auditoria.

## Casos específicos obrigatórios

### 3 participantes

- Mata-mata deve criar bye.
- Round robin deve criar uma folga por rodada.

### 4 participantes

- Mata-mata deve gerar semifinais e final.
- Round robin deve gerar 6 partidas em turno único.

### 5 participantes

- Mata-mata deve gerar byes.
- Round robin deve gerar 10 partidas em turno único.

### 8 participantes

- Mata-mata deve gerar quartas, semifinais e final.
- Seeding deve separar 1 e 2 em lados opostos.

### 16 participantes

- Chave completa sem bye.
- Rodadas: oitavas, quartas, semifinais e final.

### Número ímpar com bye

- Participante com bye avança sem resultado manual.
- Bye deve aparecer claramente como avanço automático.

### Empate em ranking

- Critérios devem ser aplicados em ordem.
- Empate não resolvido deve ser sinalizado.

### Resultado contestado

- Partida muda para em disputa.
- Ranking derivado deve ser marcado como provisório quando aplicável.

### Participante desistente

- Não deve receber novas partidas.
- Partidas já existentes exigem decisão do organizador.

### W.O.

- Deve aplicar placar padrão.
- Deve registrar justificativa.
- Deve permitir contestação quando dentro da regra.
## Atualização: testes de inscrições

- Usuário deslogado abre torneio com inscrições abertas e vê estado "login necessário"; tentativa de insert direto deve falhar por ausência de sessão.
- Usuário logado cria inscrição e recebe status `pending`.
- Usuário logado não consegue criar segunda inscrição ativa no mesmo torneio.
- Usuário logado não consegue se inscrever em torneio `registrations_closed`, `ongoing`, `finished` ou `cancelled`.
- Usuário vê suas inscrições em `/minhas-inscricoes`.
- Usuário cancela inscrição `pending` ou `confirmed` antes do início do torneio; registro muda para `cancelled` e preserva timestamps.
- Usuário não consegue cancelar inscrição de outro usuário.
- Visitante público só vê participantes `confirmed` ou `checked_in`.
- Admin confirma, rejeita e cancela inscrições em qualquer torneio permitido pelo status.
- Organizador autorizado confirma, rejeita e cancela inscrições apenas nos torneios que criou.
- Organizador com permissão revogada não consegue gerenciar inscrições nem criar novos torneios.
- Torneio por equipe registra `registration_type = team` e `captain_user_id`, sem exigir cadastro completo de membros nesta etapa.
- Testar limite de capacidade com inscrições `pending`, `confirmed` e `checked_in`.
- Testar migração de inscrições legadas `registered` para `confirmed`.

## Atualização: testes de equipes

- Torneio individual não exibe criação de equipe e mantém inscrição direta.
- Torneio por equipe com `registrations_open` permite criar equipe.
- Torneio por equipe fechado, cancelado, em andamento ou finalizado bloqueia criação de equipe no front-end e no banco.
- Criador da equipe vira capitão automaticamente.
- Usuário não consegue criar segunda equipe ativa no mesmo torneio.
- Nome vazio ou com menos de dois caracteres é rejeitado.
- Nome duplicado ativo no mesmo torneio é rejeitado.
- Capitão adiciona membro existente por email exato.
- Capitão adiciona membro existente por RA exato.
- Usuário inexistente por email/RA retorna erro claro.
- Mesmo usuário não pode ser membro ativo de duas equipes no mesmo torneio.
- Equipe com menos que `team_min_size` não pode ser enviada quando `require_full_team_before_registration` estiver ativo.
- Equipe acima de `team_max_size` é bloqueada por trigger.
- Membro comum vê a equipe, mas não consegue editar nome, adicionar ou remover membros.
- Capitão não consegue remover a si mesmo no MVP.
- Capitão consegue excluir equipe em rascunho e os vínculos de membros são removidos por cascade.
- Capitão não consegue excluir equipe já enviada, confirmada, rejeitada ou cancelada.
- Admin gerencia qualquer equipe.
- Organizador autorizado gerencia equipes apenas dos torneios que administra.
- Organizador com permissão revogada não consegue criar novos torneios nem gerir equipes de torneios sem autorização.
- Aprovar inscrição de equipe muda `tournament_registrations.status` para `confirmed` e `teams.status` para `confirmed`.
- Rejeitar ou cancelar inscrição de equipe sincroniza `teams.status` para `rejected` ou `cancelled` sem apagar histórico.
## Atualização: testes manuais do mata-mata simples

O projeto ainda não possui runner de testes unitários. Os algoritmos foram isolados em `src/lib/tournaments/singleElimination.ts` para permitir testes futuros com Vitest/Jest sem depender da UI.

Casos mínimos para validar manualmente pela tela `/torneios/:id/chave`:

- 3 participantes confirmados: chave de 4, 1 bye e final pendente/pronta conforme avanço.
- 4 participantes confirmados: chave de 4, sem bye, semifinais e final.
- 5 participantes confirmados: chave de 8, 3 byes avançando automaticamente.
- 8 participantes confirmados: chave de 8 sem bye.
- 9 participantes confirmados: chave de 16, 7 byes.
- 16 participantes confirmados: chave completa sem bye.
- Sorteio: gerar chave e recarregar página; participantes permanecem nas mesmas posições salvas.
- Seeding: preencher seeds em participantes, gerar por `seeded` e verificar que participantes não duplicam.
- Bye: verificar partida com `status = bye`, `is_bye = true` e vencedor alimentando rodada seguinte.
- Vencedor: registrar placar sem empate em partida pronta; vencedor avança para `next_match_id`.

Permissões:

- Admin consegue gerar, regerar e avançar vencedor.
- Organizador autorizado consegue agir apenas em torneio que administra.
- Usuário comum e visitante só visualizam chave pública.
- Chamada direta para alterar vencedor/placar em `bracket_matches` sem RPC deve falhar pelo trigger `protect_bracket_match_update`.

## Atualizacao: testes manuais de resultados

O projeto ainda nao possui runner de testes unitarios. A validacao de resultado foi isolada em `src/lib/tournaments/matchResults.ts`.

Casos obrigatorios:

- Placar valido: partida `ready` com dois participantes, placar 2 x 1, vencedor avanca.
- Placar negativo: front e RPC recusam.
- Empate em mata-mata: front e RPC recusam.
- Partida sem participantes: resultado bloqueado.
- Partida com bye: resultado manual bloqueado.
- Usuario comum tentando alterar resultado: chamada direta deve falhar por RLS/RPC.
- Admin alterando resultado: permitido com justificativa quando finalizado.
- Contestacao: participante muda partida para `disputed`.
- Historico: cada registro, correcao, contestacao e resolucao cria linha em `match_result_history`.
- Vencedor avancando: `next_match_id` recebe vencedor no slot correto.

## Atualizacao: testes de ranking

O ranking foi isolado em `src/lib/tournaments/ranking.ts` para permitir cobertura futura por Vitest/Jest.

Casos minimos:

- Vitoria simples: A 2 x 0 B gera 3 pontos para A, vitoria para A e derrota para B.
- Empate: A 1 x 1 B gera 1 ponto e um empate para cada.
- Derrota: lado perdedor recebe 0 ponto e uma derrota.
- Saldo: `score_diff` deve ser `score_for - score_against`.
- Ordenacao por pontos: maior pontuacao aparece antes.
- Ordenacao por vitorias: empate em pontos usa vitorias.
- Ordenacao por saldo: empate em pontos/vitorias usa saldo.
- Ordenacao por score pro: empate nos criterios anteriores usa `score_for`.
- Empate tecnico: criterios principais e confronto direto iguais marcam `isTechnicalTie`.
- Partida pendente ignorada: status diferente de `completed` nao altera estatisticas.
- Partida contestada ignorada: `resultStatus = disputed` nao altera estatisticas.
- Resultado alterado: recalcular com nova lista de partidas atualiza pontos, saldo e posicoes.

Validacao manual pela UI:

- Abrir `/torneios/:id/ranking`.
- Conferir estado vazio quando nao ha partidas finalizadas.
- Conferir aviso para mata-mata simples.
- Como admin/organizador, usar "Recalcular ranking" e confirmar que a tela recarrega dados derivados.
- Como usuario comum/visitante, confirmar que nao aparece acao administrativa.
