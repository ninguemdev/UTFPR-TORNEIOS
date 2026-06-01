# Pendencias e recomendacoes

## Critical

### PEND-CRIT-001 - Regeracao de chave com resultados

- Area: Chave/resultados
- Problema: Regerar chave pode apagar ou invalidar resultados existentes.
- Impacto: Perda de historico competitivo e risco de disputa.
- Recomendacao: Bloquear regeracao quando houver resultados, salvo fluxo admin com justificativa, confirmacao forte e snapshot.
- Arquivos provaveis: `src/services/brackets.ts`, `src/pages/tournaments/TournamentBracketPage.tsx`, `supabase/schema.sql`.
- Status: Aberto.

### PEND-CRIT-002 - Testes automatizados de RLS e RPCs

- Area: Seguranca/testes
- Problema: Fluxos sensiveis dependem de RLS, triggers e RPCs sem suite automatizada dedicada.
- Impacto: Regressao de permissao pode passar despercebida.
- Recomendacao: Criar testes SQL/RLS por papel e E2E para fluxos criticos.
- Arquivos provaveis: `supabase/README.md`, `package.json`, nova pasta de testes.
- Status: Aberto.

## High

### PEND-HIGH-001 - Pontos corridos, grupos e grupos + playoffs reais

- Area: Formatos de torneio
- Problema: Formatos aparecem no produto, mas geracao persistida de rodadas/grupos nao esta completa.
- Impacto: Ranking e agenda ficam parciais.
- Recomendacao: Modelar tabelas/RPCs para grupos, membros de grupo, rodadas e partidas de fase.
- Arquivos provaveis: `supabase/schema.sql`, `src/services/rankings.ts`, novas telas/services.
- Status: Aberto.

### PEND-HIGH-002 - Agenda de partidas

- Area: Partidas
- Problema: Nao ha modelo persistido de horario/local/remarcacao.
- Impacto: Participantes nao conseguem consultar agenda oficial.
- Recomendacao: Criar modulo de agendamento antes de notificacoes de partida.
- Arquivos provaveis: nova migration, novo service, novas paginas.
- Status: Aberto.

### PEND-HIGH-003 - Reversao auditada de W.O. e desclassificacao

- Area: Check-in/resultados
- Problema: Fluxo de reversao nao esta definido.
- Impacto: Erros administrativos exigem correcao manual.
- Recomendacao: Definir se acoes sao irreversiveis ou criar RPCs de reversao com justificativa.
- Arquivos provaveis: `supabase/schema.sql`, `src/services/brackets.ts`, `src/services/tournaments.ts`.
- Status: Aberto.

### PEND-HIGH-004 - Alinhar contestacao de membros de equipe

- Area: Resultados/equipes
- Problema: Banco reconhece membro como participante; UI pode nao mostrar contestacao.
- Impacto: Usuario autorizado fica sem acao visivel.
- Recomendacao: Usar helper de permissao alinhado com `is_match_participant()`.
- Arquivos provaveis: `src/pages/tournaments/TournamentBracketPage.tsx`, `src/services/brackets.ts`.
- Status: Aberto.

### PEND-HIGH-005 - Justificativa obrigatoria para acoes criticas

- Area: Auditoria
- Problema: Algumas acoes fortes nao coletam motivo estruturado.
- Impacto: Auditoria fica sem contexto de decisao.
- Recomendacao: Exigir motivo para cancelar/finalizar torneio, delete, regerar chave e correcoes sensiveis.
- Arquivos provaveis: `TournamentForm`, paginas de gestao, schema/RPCs conforme decisao.
- Status: Aberto.

## Medium

### PEND-MED-001 - Action locks preventivos na UI

- Area: UX/seguranca
- Problema: Bloqueio pode aparecer apenas apos submit.
- Impacto: Experiencia ruim e perda de tempo.
- Recomendacao: Criar hook para consultar bloqueios ativos por acao/escopo antes de habilitar botoes.
- Arquivos provaveis: `src/services/admin.ts`, telas de acoes sensiveis.
- Status: Aberto.

### PEND-MED-002 - Agentes livres

- Area: Equipes
- Problema: Campo existe, fluxo nao.
- Impacto: Opcao pode confundir organizador.
- Recomendacao: Rotular como planejado ou implementar cadastro/lista/convite/aceite.
- Arquivos provaveis: `TournamentForm`, `teams.ts`, schema futuro.
- Status: Aberto.

### PEND-MED-003 - Recuperacao de senha completa

- Area: Auth
- Problema: Solicita reset, mas tela de nova senha nao esta clara.
- Impacto: Usuario pode nao concluir recuperacao.
- Recomendacao: Implementar rota hash para atualizar senha apos link do Supabase.
- Arquivos provaveis: `src/App.tsx`, `src/pages/auth`, `src/components/auth`.
- Status: Aberto.

### PEND-MED-004 - Rotas demo legadas

- Area: Rotas
- Problema: Demos antigas coexistem com rotas reais.
- Impacto: Confusao em testes e avaliacao.
- Recomendacao: Isolar por flag ou remover quando substituidas.
- Arquivos provaveis: `src/App.tsx`.
- Status: Aberto.

### PEND-MED-005 - Snapshot oficial de ranking

- Area: Ranking
- Problema: Tabelas existem, mas UI nao publica snapshot oficial.
- Impacto: Classificacao pode ser recalculada sem marco oficial.
- Recomendacao: Criar acao "publicar ranking oficial" usando `tournament_standings`.
- Arquivos provaveis: `src/services/rankings.ts`, `TournamentRankingPage`, schema/RPC se necessario.
- Status: Aberto.

### PEND-MED-006 - Captura de IP e user-agent na auditoria

- Area: Auditoria
- Problema: Campos existem, mas ficam nulos em triggers SQL.
- Impacto: Investigacao administrativa limitada.
- Recomendacao: Usar Edge Function/API para acoes criticas.
- Arquivos provaveis: Edge Functions futuras, `supabase/schema.sql`.
- Status: Aberto.

## Low

### PEND-LOW-001 - Microcopy de funcionalidades ja implementadas

- Area: UX
- Problema: Textos dizem que alguns modulos sao futuros.
- Impacto: Confusao pequena, mas visivel.
- Recomendacao: Atualizar textos para "implementado", "parcial" ou "planejado".
- Arquivos provaveis: `src/components/tournaments/TournamentForm.tsx`.
- Status: Aberto.

### PEND-LOW-002 - Documentacao de rotas reais versus planejadas

- Area: Documentacao
- Problema: Documentos historicos misturam rotas planejadas e reais.
- Impacto: QA pode seguir caminho errado.
- Recomendacao: Manter `docs/07-rotas-e-telas.md` sincronizado com `src/App.tsx`.
- Arquivos provaveis: `docs/07-rotas-e-telas.md`, `src/App.tsx`.
- Status: Aberto.

### PEND-LOW-003 - Guia de mensagens de erro

- Area: UX/dev
- Problema: Erros de banco/RLS podem aparecer genericos.
- Impacto: Usuario nao entende a acao corretiva.
- Recomendacao: Criar mapa de erros por fluxo e codigo.
- Arquivos provaveis: services, paginas, docs de fluxos.
- Status: Aberto.

### PEND-LOW-004 - Central de notificacoes

- Area: Comunicacao
- Problema: Notificacoes nao existem.
- Impacto: Usuarios precisam visitar telas para saber novidades.
- Recomendacao: Implementar notificacoes in-app simples antes de email/push.
- Arquivos provaveis: schema futuro, service futuro, header.
- Status: Aberto.

