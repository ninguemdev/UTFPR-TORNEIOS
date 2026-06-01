# Indice de fluxos

Esta pasta detalha fluxos de uso, casos de uso, falhas, seguranca e pendencias do sistema UTFPR Torneios. A analise foi feita a partir de `AGENTS.md`, `README.md`, `docs/`, `supabase/schema.sql`, `src/App.tsx`, `src/services/`, `src/pages/` e `src/components/`.

## Status geral

- Implementado: Supabase Auth no front-end, profiles, pedidos de criador, permissao ativa/revogada, CRUD de torneios, inscricoes individuais, equipes, check-in, W.O. manual, desclassificacao, mata-mata simples, resultados, contestacoes, historico, auditoria e bloqueios.
- Parcial: ranking por pontos, snapshots de ranking, formatos de tabela, grupos, grupos + playoffs, agentes livres, notificacoes preventivas de bloqueios e mensagens de erro por acao.
- Pendente: agenda real de partidas, geradores de pontos corridos/grupos, notificacoes, global_settings, testes automatizados e fluxo completo de agentes livres.
- Futuro: sistema suico, melhor de N estruturado, convites com aceite, substitutos, transferir capitania, exportacao e monitoramento.

## Documentos

| Arquivo | Conteudo | Status |
| --- | --- | --- |
| `01-atores-e-permissoes.md` | Atores, permissoes e limites por papel. | Implementado/parcial |
| `02-mapa-geral-do-sistema.md` | Mapa de rotas, services, dados e decisoes de estado. | Implementado/parcial |
| `03-auth-conta-e-perfil.md` | Cadastro, login, logout, recuperacao, perfil e profile automatico. | Implementado |
| `04-permissao-criador-torneios.md` | Pedidos, aprovacao, rejeicao, revogacao e burla direta. | Implementado |
| `05-torneios-crud-e-publicacao.md` | Lista publica, criacao, edicao, status, exclusao e inexistencia. | Implementado/parcial |
| `06-inscricoes-e-participantes.md` | Inscricao, cancelamento, confirmacao, seed e visibilidade publica. | Implementado |
| `07-equipes-capitao-e-membros.md` | Equipes, capitao, membros, envio, cancelamento e agentes livres. | Implementado/parcial |
| `08-check-in-wo-e-desclassificacao.md` | Janela de check-in, check-in manual, W.O. e desclassificacao. | Implementado/parcial |
| `09-chave-mata-mata.md` | Geracao, sorteio, seeding, bye, regeracao e campeao. | Implementado |
| `10-resultados-contestacoes-e-historico.md` | Resultado, correcao, contestacao, historico e W.O. | Implementado |
| `11-ranking-e-classificacao.md` | Ranking calculado, criterios, empates tecnicos e snapshots. | Parcial |
| `12-pontos-corridos-e-grupos.md` | Pontos corridos, grupos e grupos + playoffs. | Pendente/parcial |
| `13-agendamento-de-partidas.md` | Agenda de partidas, conflitos e proximas partidas. | Pendente |
| `14-painel-admin-e-organizador.md` | Dashboards, pedidos, auditoria, bloqueios e organizador. | Implementado/parcial |
| `15-auditoria-bloqueios-e-seguranca.md` | Audit logs, action locks, RLS, RPC e triggers. | Implementado/parcial |
| `16-notificacoes-e-comunicacao.md` | Notificacoes planejadas e comunicacao operacional. | Pendente |
| `17-casos-de-erro-e-falhas-de-fluxo.md` | Falhas de fluxo encontradas com severidade e arquivos provaveis. | Analise |
| `18-matriz-de-casos-de-uso.md` | Matriz de casos de uso com IDs padronizados. | Analise |
| `19-checklist-de-validacao-de-fluxos.md` | Checklist por papel e area. | Analise |
| `20-pendencias-e-recomendacoes.md` | Pendencias por prioridade. | Analise |

## Leitura recomendada

1. Comece por `01-atores-e-permissoes.md` e `02-mapa-geral-do-sistema.md`.
2. Use `18-matriz-de-casos-de-uso.md` para transformar cada caso em prompt de implementacao/teste.
3. Use `17-casos-de-erro-e-falhas-de-fluxo.md` e `20-pendencias-e-recomendacoes.md` para priorizar correcoes.
4. Antes de implementar, confirme se a mudanca exige schema/RLS. Esta tarefa nao alterou SQL.

