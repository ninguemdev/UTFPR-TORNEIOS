# Casos de erro e falhas de fluxo

Este documento lista falhas, inconsistencias e riscos encontrados ao cruzar documentacao, `supabase/schema.sql`, rotas, services e telas. Status inicial: aberto para triagem.

## FLOW-ISSUE-001 - Ranking de formatos de tabela sem gerador persistido completo

- Gravidade: Alta
- Area: Ranking, pontos corridos, grupos
- Fluxo afetado: RANK, RR, GROUP
- Descricao: A tela de ranking aceita formatos de tabela e o algoritmo calcula pontos, mas o projeto ainda nao possui gerador persistido completo para rodadas de pontos corridos/grupos.
- Como reproduzir: Criar torneio `round_robin` ou `groups`, confirmar participantes e abrir `#/torneios/:id/ranking`.
- Impacto: Usuario pode entender que pontos corridos/grupos estao completos quando apenas o calculo sobre partidas existentes esta parcial.
- Causa provavel: O ranking foi implementado antes do modelo de partidas de fase/grupos.
- Correcao recomendada: Criar schema/RPC/service para grupos, rodadas e partidas de fase ou marcar formatos como planejados na UI.
- Arquivos provaveis: `src/services/rankings.ts`, `src/lib/tournaments/ranking.ts`, `src/pages/tournaments/TournamentRankingPage.tsx`, `supabase/schema.sql`.
- Precisa de mudanca no banco?: Sim, para fluxo completo.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-002 - Rotas/documentos de grupos e partidas ainda nao existem como modulo real

- Gravidade: Alta
- Area: Rotas, grupos, agenda
- Fluxo afetado: GROUP, SCHEDULE
- Descricao: Documentos antigos citam rotas como `/torneios/:id/grupos`, `/torneios/:id/partidas` e `/partidas/:id/resultado`, mas o roteador real usa hash routes e nao possui essas telas persistidas.
- Como reproduzir: Procurar as rotas no `src/App.tsx` e tentar acessar os caminhos planejados.
- Impacto: Confusao de produto e testes apontando para rotas inexistentes.
- Causa provavel: Planejamento de rotas antes da implementacao incremental.
- Correcao recomendada: Atualizar a tabela de rotas reais versus planejadas e implementar rotas quando os modulos existirem.
- Arquivos provaveis: `src/App.tsx`, `docs/07-rotas-e-telas.md`, `docs/fluxos/13-agendamento-de-partidas.md`.
- Precisa de mudanca no banco?: Nao para documentar; sim para modulo completo.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-003 - Regeracao de chave pode apagar resultados e historico por cascade

- Gravidade: Critica
- Area: Chave, resultados, auditoria
- Fluxo afetado: BRACKET, RESULT, AUDIT
- Descricao: `forceRegenerate` remove a chave existente; partidas e resultados relacionados podem cair por cascade ou perder contexto operacional.
- Como reproduzir: Gerar chave, registrar resultado, acionar regeracao forçada.
- Impacto: Perda de historico competitivo ou alteracao irreversivel de chave ja usada.
- Causa provavel: Regeracao implementada como delete/recreate para simplificar MVP.
- Correcao recomendada: Bloquear regeracao quando houver resultados, salvo fluxo admin com justificativa, snapshot/arquivo e confirmacao forte.
- Arquivos provaveis: `src/services/brackets.ts`, `src/pages/tournaments/TournamentBracketPage.tsx`, `supabase/schema.sql`.
- Precisa de mudanca no banco?: Possivelmente.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-004 - Participante membro de equipe pode contestar no banco mas a UI pode esconder acao

- Gravidade: Alta
- Area: Resultados, equipes
- Fluxo afetado: RESULT, TEAM
- Descricao: A funcao SQL `is_match_participant()` considera membros ativos de equipe, mas a UI tende a verificar inscrito/capitao e pode ocultar contestacao para membro.
- Como reproduzir: Criar equipe com membro nao capitao, gerar partida e verificar botao de contestacao para esse membro.
- Impacto: Permissao real do banco nao aparece para usuario autorizado.
- Causa provavel: Regra de participacao duplicada no front-end.
- Correcao recomendada: Expor helper/service que reflita `is_match_participant()` ou carregar membros da equipe para a decisao da UI.
- Arquivos provaveis: `src/pages/tournaments/TournamentBracketPage.tsx`, `src/services/brackets.ts`, `supabase/schema.sql`.
- Precisa de mudanca no banco?: Nao.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-005 - Lista publica de participantes nao exclui no-show explicitamente

- Gravidade: Media
- Area: Inscricoes, W.O.
- Fluxo afetado: REG, CHECKIN, RESULT
- Descricao: O service publico exclui desclassificados, mas precisa revisar se participantes com `no_show_at` devem continuar visiveis como ativos.
- Como reproduzir: Registrar W.O. e consultar lista publica de participantes do torneio.
- Impacto: Participante ausente pode parecer elegivel/ativo dependendo da tela.
- Causa provavel: No-show foi adicionado depois do filtro publico inicial.
- Correcao recomendada: Definir regra de produto e ajustar `isPublicParticipant()`.
- Arquivos provaveis: `src/services/tournaments.ts`, `src/pages/tournaments/TournamentParticipantsPage.tsx`.
- Precisa de mudanca no banco?: Nao.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-006 - Microcopy do formulario de torneio chama modulos implementados de futuros

- Gravidade: Baixa
- Area: UX, torneios
- Fluxo afetado: TOURN, TEAM, BRACKET, RANK
- Descricao: Textos do `TournamentForm` ainda indicam que membros, chave e ranking sao etapas futuras, embora existam equipes, mata-mata e ranking parcial.
- Como reproduzir: Abrir `#/torneios/novo` ou editar torneio.
- Impacto: Usuario nao confia no estado real da funcionalidade.
- Causa provavel: Texto criado antes das implementacoes seguintes.
- Correcao recomendada: Atualizar microcopy para distinguir implementado, parcial e planejado.
- Arquivos provaveis: `src/components/tournaments/TournamentForm.tsx`.
- Precisa de mudanca no banco?: Nao.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Nao obrigatorio.
- Status: Aberto.

## FLOW-ISSUE-007 - Agentes livres existem como campo, mas nao ha fluxo

- Gravidade: Media
- Area: Equipes
- Fluxo afetado: TEAM
- Descricao: `allow_free_agents` existe em torneios, mas nao ha cadastro, lista, aceite, convite ou gestao de agentes livres.
- Como reproduzir: Ativar a opcao no torneio e procurar fluxo de agente livre.
- Impacto: Configuracao pode prometer funcionalidade inexistente.
- Causa provavel: Preparacao de schema antes do modulo.
- Correcao recomendada: Marcar como planejado na UI ou implementar modulo completo.
- Arquivos provaveis: `src/components/tournaments/TournamentForm.tsx`, `src/services/teams.ts`, `supabase/schema.sql`.
- Precisa de mudanca no banco?: Sim para fluxo completo.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-008 - Mudanca critica de status do torneio nao exige justificativa no front-end

- Gravidade: Alta
- Area: Torneios, auditoria
- Fluxo afetado: TOURN, AUDIT
- Descricao: Admin/organizador pode alterar status como `ongoing`, `finished` ou `cancelled`; auditoria existe, mas a UI nao coleta motivo especifico.
- Como reproduzir: Editar torneio e mudar status para cancelado/finalizado.
- Impacto: Mudancas administrativas sensiveis ficam com auditoria tecnica, mas sem contexto decisorio.
- Causa provavel: Formulario generico de torneio.
- Correcao recomendada: Criar modal de transicao com motivo obrigatorio para status criticos.
- Arquivos provaveis: `src/pages/tournaments/EditTournamentPage.tsx`, `src/components/tournaments/TournamentForm.tsx`, `supabase/schema.sql`.
- Precisa de mudanca no banco?: Talvez, para armazenar motivo de status.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-009 - Bloqueios administrativos nem sempre sao exibidos antes da acao

- Gravidade: Media
- Area: Admin, seguranca, UX
- Fluxo afetado: ADMIN, SECURITY
- Descricao: `action_locks` bloqueiam no banco, mas algumas telas podem mostrar a acao como disponivel ate o submit falhar.
- Como reproduzir: Criar bloqueio `register` ou `generate_bracket` e abrir a tela correspondente.
- Impacto: Usuario recebe erro tardio e pode perder preenchimento.
- Causa provavel: Falta de consulta preventiva de locks por contexto.
- Correcao recomendada: Criar hook/service de bloqueios ativos por acao e escopo.
- Arquivos provaveis: `src/services/admin.ts`, telas de torneio, participantes, equipes, chave e ranking.
- Precisa de mudanca no banco?: Nao.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-010 - Auditoria nao captura IP e user-agent

- Gravidade: Media
- Area: Auditoria
- Fluxo afetado: AUDIT
- Descricao: Campos `ip_address` e `user_agent` existem, mas triggers SQL nao recebem esses dados de forma confiavel.
- Como reproduzir: Executar acoes auditadas e consultar `audit_logs`.
- Impacto: Auditoria operacional fica incompleta para investigacao.
- Causa provavel: Arquitetura client-only sem Edge Function/backend para enriquecer logs.
- Correcao recomendada: Capturar dados via Edge Function/API server para acoes criticas.
- Arquivos provaveis: `supabase/schema.sql`, futuro backend/Edge Function.
- Precisa de mudanca no banco?: Nao necessariamente.
- Precisa de mudanca no front-end?: Possivelmente.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-011 - `global_settings` consta em contratos antigos, mas nao existe no schema

- Gravidade: Media
- Area: API, admin
- Fluxo afetado: ADMIN, SECURITY
- Descricao: Documentacao de contratos cita `updateGlobalSettings`, mas nao ha tabela/fluxo real de configuracoes globais.
- Como reproduzir: Procurar `global_settings` no schema e services.
- Impacto: Contrato documentado nao implementado.
- Causa provavel: Roadmap anterior ao schema real.
- Correcao recomendada: Remover do escopo atual ou implementar tabela/policies/service.
- Arquivos provaveis: `docs/08-api-e-contratos.md`, `supabase/schema.sql`, `src/services/admin.ts`.
- Precisa de mudanca no banco?: Sim se for implementar.
- Precisa de mudanca no front-end?: Sim se for implementar.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-012 - Falta suite automatizada para RLS e fluxos criticos

- Gravidade: Alta
- Area: Testes, seguranca
- Fluxo afetado: Todos
- Descricao: Nao ha evidencia de testes automatizados cobrindo RLS, RPCs, triggers e fluxos de UI.
- Como reproduzir: Executar `npm run lint` e `npm run build`; nao ha comando de testes de fluxo/RLS.
- Impacto: Regressao de permissao pode passar sem deteccao.
- Causa provavel: MVP evoluiu com validacao manual.
- Correcao recomendada: Criar testes SQL/RLS, unitarios de algoritmos e E2E dos fluxos principais.
- Arquivos provaveis: `package.json`, `supabase/README.md`, `docs/11-testes-e-validacao.md`.
- Precisa de mudanca no banco?: Nao.
- Precisa de mudanca no front-end?: Nao obrigatorio.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-013 - Reversao de W.O. e desclassificacao nao esta definida como fluxo completo

- Gravidade: Alta
- Area: Check-in, W.O., resultados
- Fluxo afetado: CHECKIN, RESULT
- Descricao: Existem funcoes para registrar W.O. e desclassificar, mas o fluxo de desfazer ou corrigir essas acoes nao esta claramente completo.
- Como reproduzir: Desclassificar inscricao ou registrar W.O. e tentar voltar ao estado anterior via UI.
- Impacto: Erro operacional pode exigir correcao manual arriscada.
- Causa provavel: Acoes foram modeladas como administrativas fortes.
- Correcao recomendada: Definir se sao irreversiveis ou criar RPCs de reversao auditada.
- Arquivos provaveis: `supabase/schema.sql`, `src/services/tournaments.ts`, `src/services/brackets.ts`.
- Precisa de mudanca no banco?: Sim para reversao segura.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-014 - Rotas demo antigas podem confundir o produto real

- Gravidade: Media
- Area: Rotas, UX
- Fluxo afetado: TOURN, GROUP, SCHEDULE
- Descricao: `src/App.tsx` ainda contem rotas demo como `home`, `dashboard`, `groups`, `matches`, `result`, alem das rotas reais Supabase.
- Como reproduzir: Acessar hashes legados e comparar com fluxo real.
- Impacto: Usuario/testador pode avaliar telas que nao usam dados reais.
- Causa provavel: Protótipo mantido durante evolucao.
- Correcao recomendada: Isolar demos atras de flag ou remover quando MVP real estiver completo.
- Arquivos provaveis: `src/App.tsx`.
- Precisa de mudanca no banco?: Nao.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-015 - Regra de criador revogado precisa decisao de produto

- Gravidade: Media
- Area: Permissoes, torneios
- Fluxo afetado: PERM, TOURN, ADMIN
- Descricao: Pela regra atual, `can_manage_tournament()` exige que o criador ainda possa criar torneios; logo, revogacao pode bloquear gestao de torneios antigos.
- Como reproduzir: Criar torneio como criador, revogar permissao e tentar editar/gerenciar.
- Impacto: Pode ser desejado por seguranca ou indesejado por continuidade operacional.
- Causa provavel: `can_manage_tournament()` reutiliza `can_create_tournament()`.
- Correcao recomendada: Confirmar regra de produto e ajustar docs/UI/funcoes se necessario.
- Arquivos provaveis: `supabase/schema.sql`, `src/context/AuthContext.tsx`, `docs/fluxos/01-atores-e-permissoes.md`.
- Precisa de mudanca no banco?: Talvez.
- Precisa de mudanca no front-end?: Talvez.
- Precisa de teste?: Sim.
- Status: Aberto.

## FLOW-ISSUE-016 - Recuperacao de senha nao tem tela explicita para nova senha

- Gravidade: Media
- Area: Auth
- Fluxo afetado: AUTH
- Descricao: O fluxo solicita reset por email, mas nao ha tela documentada/implementada claramente para definir nova senha apos retorno.
- Como reproduzir: Usar `#/recuperar-senha` e seguir link de email em ambiente configurado.
- Impacto: Usuario pode ficar sem concluir recuperacao.
- Causa provavel: Dependencia da configuracao padrao do Supabase Auth.
- Correcao recomendada: Implementar rota/tela de update password e documentar redirect.
- Arquivos provaveis: `src/pages/auth/PasswordRecoveryPage.tsx`, `src/components/auth/PasswordRecoveryForm.tsx`, `src/App.tsx`.
- Precisa de mudanca no banco?: Nao.
- Precisa de mudanca no front-end?: Sim.
- Precisa de teste?: Sim.
- Status: Aberto.
