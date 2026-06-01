# Roadmap MVP

## Fase 0 - Documentação e base

- **Objetivo:** criar base compreensível para avaliadores e desenvolvedores.
- **Tarefas:** documentação principal; README; regras de torneio; arquitetura; contratos; regras de autenticação, permissões, Supabase, RLS e segurança.
- **Critérios de aceite:** docs criados e linkados; próximos passos claros; regras de admin/user documentadas.
- **Riscos:** documentos anexados ausentes podem exigir revisão posterior.

## Fase 1 - Layout e navegação

- **Objetivo:** substituir template inicial por estrutura real do sistema.
- **Tarefas:** layout base; navegação; landing; dashboard mockado; tokens CSS.
- **Critérios de aceite:** interface responsiva, acessível e coerente com identidade UTFPR.
- **Riscos:** excesso de telas sem domínio pode gerar retrabalho.

## Fase 2 - Autenticação, perfis e Supabase

- **Objetivo:** integrar Supabase Auth e criar base segura de usuário.
- **Tarefas:** configurar Supabase; criar `profiles`; login; cadastro; logout; recuperação de senha; edição de perfil; `avatar_key`; RA; RLS de perfil.
- **Critérios de aceite:** usuário cria conta, faz login, edita apenas o próprio perfil e não consegue alterar role/permissões.
- **Riscos:** expor chave privada no front-end; tratar senha fora do Supabase Auth; policies permissivas demais.

## Fase 3 - Permissões, admin e pedidos

- **Objetivo:** controlar criação de torneios e ações administrativas.
- **Tarefas:** roles `admin` e `user`; pedido para criar torneios; tabela revogável de permissões; aprovação/rejeição por admin; revogação de permissão ativa; bloqueio/desbloqueio de ações; auditoria geral inicial; configurações globais.
- **Critérios de aceite:** usuário comum só cria torneio com permissão `active`; admin consegue decidir pedidos, revogar permissões, criar bloqueios e consultar auditoria; RLS bloqueia operações indevidas.
- **Riscos:** confiar apenas na interface; esquecer auditoria em decisões administrativas; configurações globais ainda precisam de tabela própria.

## Fase 4 - CRUD de torneios

- **Objetivo:** permitir criação e edição de torneios com persistência.
- **Tarefas:** tabela `tournaments`; formulários; validações; RLS; listagem pública e administrativa.
- **Critérios de aceite:** admin ou usuário com permissão ativa cria, lista, edita e visualiza torneio; usuário sem permissão ativa é bloqueado pelo banco.
- **Riscos:** regras de edição por status ficarem ambíguas.

## Fase 5 - Participantes e inscrições

- **Objetivo:** gerenciar inscritos individuais e equipes.
- **Tarefas:** participantes; equipes; capitão; status de inscrição; limites; RLS para dados próprios e administrativos.
- **Critérios de aceite:** inscrições válidas aparecem no painel e na página pública; dados privados não vazam.
- **Riscos:** regras de equipes podem variar por modalidade.

## Fase 6 - Mata-mata simples

- **Objetivo:** implementar primeiro formato competitivo.
- **Tarefas:** gerar chave; byes; seeding; sorteio; avanço de vencedores.
- **Critérios de aceite:** chaves de 3, 4, 5, 8 e 16 participantes funcionam.
- **Riscos:** alteração de resultado pode afetar partidas futuras.

## Fase 7 - Resultados e ranking básico

- **Objetivo:** registrar resultados e calcular classificação simples.
- **Tarefas:** formulário de placar; validação; ranking básico; histórico; RLS para envio, confirmação e correção.
- **Critérios de aceite:** resultado confirmado atualiza chave ou tabela; correção sensível exige permissão e auditoria.
- **Riscos:** ranking ambíguo sem critério explícito.

## Fase 8 - Round robin

- **Objetivo:** suportar pontos corridos.
- **Tarefas:** gerar tabela de jogos; folgas; pontuação; desempates.
- **Critérios de aceite:** todos enfrentam todos uma vez, com ranking correto.
- **Riscos:** número de partidas cresce rapidamente.

## Fase 9 - Grupos + playoffs

- **Objetivo:** combinar fase de grupos com chave final.
- **Tarefas:** divisão de grupos; ranking por grupo; classificados; geração de playoff.
- **Critérios de aceite:** classificados alimentam chave final corretamente.
- **Riscos:** regras de cruzamento precisam ser muito explícitas.

## Fase 10 - Disputas e auditoria

- **Objetivo:** aumentar integridade do sistema.
- **Tarefas:** abrir disputa; resolver disputa; registrar correções; audit log; RPCs transacionais para ações críticas.
- **Critérios de aceite:** resultado contestado fica rastreável até resolução; admin consegue resolver disputa com justificativa.
- **Riscos:** correções podem exigir recalcular fases dependentes.

## Fase 11 - Polimento visual

- **Objetivo:** elevar qualidade visual, responsividade e acessibilidade.
- **Tarefas:** revisar componentes; estados vazios; loading; erro; mobile; contraste.
- **Critérios de aceite:** telas passam no checklist de UI, responsividade e acessibilidade.
- **Riscos:** ajustes visuais tardios podem exigir refatorar CSS.

## Fase 12 - Sistema suíço / recursos avançados

- **Objetivo:** adicionar formatos avançados.
- **Tarefas:** pareamento suíço; Buchholz; evitar repetição; exportação; notificações.
- **Critérios de aceite:** pareamentos auditáveis e ranking explicado.
- **Riscos:** algoritmo suíço é mais complexo e deve ser amplamente testado.
## Atualização do roadmap: inscrições e participantes

### Fase 3.1 — Inscrições com status e histórico

- **Objetivo:** finalizar fluxo de inscrição individual e preparar o modelo para equipes.
- **Tarefas:** criar status `pending`, `confirmed`, `cancelled`, `rejected`, `checked_in`; impedir duplicidade ativa; listar "Minhas inscrições"; permitir cancelamento seguro.
- **Critérios de aceite:** RLS bloqueia usuário comum de alterar inscrição alheia; cancelamento preserva histórico; página pública não mostra pendentes.
- **Riscos:** migração de enum no Supabase pode exigir executar o bloco de novos valores antes do restante em bancos já existentes.

### Fase 3.2 — Gestão de inscritos

- **Objetivo:** permitir que admin e organizador autorizado façam triagem de inscrições.
- **Tarefas:** painel de participantes com confirmar, rejeitar, cancelar e observação administrativa; função `can_manage_tournament()`.
- **Critérios de aceite:** admin gerencia qualquer torneio; organizador gerencia apenas torneios próprios enquanto tiver permissão ativa; usuário revogado perde acesso.
- **Riscos:** decisões de inscrição ainda não geram tabela dedicada de auditoria, apenas campos de decisão no registro.

### Fase 3.3 — Equipes completas

- **Objetivo:** transformar inscrições por equipe em equipes reais com membros e capitão.
- **Tarefas:** criar `teams` e `team_members`; validar tamanho mínimo/máximo; permitir criação de equipe; adicionar/remover membros existentes por email/RA; enviar equipe para inscrição.
- **Critérios de aceite:** equipe completa gera inscrição `pending`; membros não podem estar duplicados no mesmo torneio; RLS bloqueia edição de equipe alheia.
- **Riscos:** convite com aceite, substitutos e transferência de capitania ficam para versões futuras para não atrasar o MVP.

### Fase futura — Convites e substitutos

- **Objetivo:** ampliar colaboração em equipes.
- **Tarefas:** convite por email, aceite do membro, transferência de capitania, substitutos e histórico detalhado de escalação.
- **Critérios de aceite:** nenhum usuário entra em equipe sem consentimento quando o fluxo de convite for ativado.
- **Riscos:** aumenta complexidade de notificações, prazos e auditoria.
## Atualização: Fase 6 implementada parcialmente

Entregue nesta etapa:

- Algoritmo testável para próxima potência de 2, byes, sorteio, seeding, criação de rodadas e avanço.
- Persistência em `tournament_brackets` e `bracket_matches`.
- RLS para leitura pública e escrita apenas por admin/organizador.
- RPC `complete_bracket_match` para validar placar e avançar vencedor.
- UI `/torneios/:id/chave` com geração, regeração, byes, rodadas e confirmação de vencedor.

Limitações mantidas para fases futuras:

- Sem ranking.
- Sem double elimination.
- Sem round robin.
- Sem grupos/playoffs.
- Sem melhor de N estruturado em jogos internos.
- Sem auditoria dedicada além dos campos `generated_by`, `generated_at`, vencedor e timestamps.
- Correção de resultado já finalizado ainda deve ser tratada em fase de disputas/auditoria.

## Atualizacao: Fase 7 parcial

Entregue nesta etapa:

- Formulario de resultado na chave mata-mata.
- Validacao separada em TypeScript para placar e vencedor.
- RPC transacional para registrar/corrigir resultado e avancar vencedor.
- Contestacao por participante da partida.
- Resolucao administrativa de contestacao.
- Tabelas `match_results` e `match_result_history` com RLS.

Limites mantidos:

- Ranking basico ja possui algoritmo e tela preparada, mas ainda nao ha gerador proprio de pontos corridos/grupos.
- Sem melhor de N estruturado.
- W.O. manual implementado por `result_type = walkover`; W.O. automatico por agenda/atraso segue futuro.
- Correcoes de vencedor sao bloqueadas quando partidas dependentes ja possuem resultado ou estao em andamento.

## Atualizacao: Fase 8 parcial - ranking basico

Entregue nesta etapa:

- Algoritmo puro em TypeScript para ranking por pontos.
- Pontuacao padrao 3/1/0 preparada para configuracao futura.
- Criterios explicitos: pontos, vitorias, saldo, score pro, confronto direto quando aplicavel e fallback por seed/nome.
- Tela `/torneios/:id/ranking` com estados de loading, erro, vazio, aviso provisorio e tabela responsiva.
- Estrutura SQL `tournament_standings` e `standing_entries` com RLS para snapshots futuros.

Limites mantidos:

- Ainda nao ha geracao real de calendario round robin ou grupos.
- O ranking de mata-mata simples nao foi transformado em classificacao completa.
- Snapshots SQL estao preparados, mas a tela atual recalcula em tempo de leitura a partir dos dados disponiveis.
- Elo, sistema suico, estatisticas avancadas e W.O. automatico por regras de agenda continuam fora do MVP desta etapa.

## Atualizacao: base de infraestrutura Supabase

Entregue nesta etapa:

- `.env.example` sem segredos reais com `VITE_SUPABASE_URL` e
  `VITE_SUPABASE_ANON_KEY`.
- `.gitignore` cobrindo `.env`, `.env.local` e `.env.*.local`.
- `supabase/README.md` documentando bootstrap por `schema.sql`, primeiro admin,
  regras de seguranca e teste manual de RLS.
- `supabase/migrations/README.md` criando a estrutura para migrations
  incrementais futuras.

Decisao:

- `supabase/schema.sql` continua como bootstrap consolidado do estado atual.
- Nenhuma migration inicial gigante foi duplicada antes da Supabase CLI estar
  inicializada, para evitar duas fontes extensas divergentes.

Limites mantidos:

- Ainda nao ha `supabase/config.toml`.
- Tipos em `src/lib/supabase/types.ts` continuam manuais ate a geracao por CLI
  ser adotada.

## Atualizacao: auditoria geral e bloqueios administrativos

Entregue nesta etapa:

- Migration `20260526090000_add_audit_logs_action_locks.sql`.
- Tabelas `audit_logs` e `action_locks` com RLS.
- Funcoes `write_audit_log`, `is_action_locked` e `assert_action_unlocked`.
- Auditoria para permissoes de criador, pedidos, role, torneios, inscricoes, chave, resultados e bloqueios.
- Bloqueios no banco para criacao/edicao/exclusao de torneio, inscricoes, equipes, geracao de chave, resultado, contestacao e snapshots de ranking.
- Painel admin com listagem/filtro de auditoria e CRUD operacional de bloqueios.

Limites mantidos:

- `ip_address` e `user_agent` permanecem nulos ate existir camada server/Edge Function que capture metadados de requisicao.
- `global_settings` ainda nao foi implementado.
- Auditoria de agenda e grupos fica para quando esses modulos existirem; W.O. manual ja entra em `match_results`, `match_result_history` e `audit_logs`.
