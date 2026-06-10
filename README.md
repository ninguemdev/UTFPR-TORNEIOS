# UTFPR Torneios

Sistema web para organização de torneios, e-sports e competições acadêmicas no contexto da UTFPR.

---

## O problema que este projeto resolve

Competições universitárias costumam depender de planilhas Excel compartilhadas, grupos de WhatsApp e controles manuais para inscrições, sorteios, chaves, resultados e ranking. O resultado é previsível: erros de atualização, auditoria impossível, comunicação fragmentada e falta de transparência para os participantes.

O UTFPR Torneios centraliza todo esse processo em uma plataforma única — com regras explícitas, segurança garantida no banco, auditoria de cada ação sensível e página pública para que qualquer um acompanhe o torneio em tempo real.

---

## Stack

| Camada | Tecnologia |
|---|---|
| Front-end | React 19 + TypeScript + Vite |
| Estilização | CSS próprio com variáveis e tokens |
| Banco de dados | PostgreSQL via Supabase |
| Autenticação | Supabase Auth (email e senha) |
| Segurança | Row Level Security (RLS) + RPCs transacionais |
| Qualidade | ESLint |

Vale destacar a distribuição real do código: **49,5% TypeScript, 44,5% PL/pgSQL**. Isso não é acidente — uma parte significativa da lógica de negócio, segurança e auditoria vive diretamente no banco, garantindo que nenhuma operação sensível possa ser contornada via front-end.

---

## O que está implementado

### Infraestrutura e segurança

- Integração real com Supabase: cliente configurado via variáveis de ambiente, sem segredos expostos no navegador.
- Schema PostgreSQL completo (`supabase/schema.sql`) com todas as tabelas e RLS habilitado.
- Sistema de auditoria: tabela `audit_logs` registra automaticamente permissões, torneios, inscrições, chaves, resultados, contestações e bloqueios via triggers.
- Sistema de bloqueios administrativos: tabela `action_locks` com funções `is_action_locked()` e `assert_action_unlocked()` que impedem operações em áreas bloqueadas pelo admin — validado no banco, não na interface.
- Migrations incrementais em `supabase/migrations/` para evolução controlada do schema.

### Autenticação e permissões

- Dois perfis distintos: `admin` (administrador global) e `user` (usuário comum).
- Usuários comuns não podem criar torneios por padrão — precisam solicitar permissão e aguardar aprovação do admin.
- Permissão de criação é revogável: admin pode ativar e desativar a qualquer momento, com registro em auditoria.
- RLS em todas as tabelas sensíveis: políticas no banco bloqueiam operações indevidas independente do que a interface permita.

### Torneios e participantes

- CRUD completo de torneios com validação de status (não é possível, por exemplo, editar uma chave com resultados já registrados).
- Inscrições com estados: `pending`, `confirmed`, `cancelled`, `rejected`, `checked_in`.
- Equipes com capitão, membros e validação de tamanho mínimo/máximo.
- Função `can_manage_tournament()` para verificar permissão de organizador no banco.

### Formato de competição: mata-mata simples

- Algoritmo puro em TypeScript que calcula a próxima potência de 2, distribui byes automaticamente e gera os confrontos com suporte a seeding e sorteio.
- Persistência em `tournament_brackets` e `bracket_matches` com RLS.
- RPC transacional `complete_bracket_match` que valida placar, registra resultado e avança o vencedor — tudo em uma operação atômica no banco.
- Suporte a chaves de 3 a 16+ participantes.
- Interface `/torneios/:id/chave` com geração, regeneração controlada, visualização de rodadas e confirmação de resultado.

### Resultados e contestações

- Formulário de resultado com validação separada em TypeScript para placar e vencedor.
- RPC transacional para registrar, confirmar e corrigir resultado com auditoria.
- Contestação por participante da partida com resolução administrativa.
- Histórico completo em `match_results` e `match_result_history`.
- Correções de vencedor são bloqueadas quando partidas dependentes já possuem resultado.

### Ranking

- Algoritmo puro em TypeScript para ranking por pontos (padrão 3/1/0, configurável).
- Critérios de desempate explícitos e em cascata: pontos → vitórias → saldo de partidas → score pró → confronto direto → seed/nome.
- Tela `/torneios/:id/ranking` com estados de loading, vazio, erro e aviso de ranking provisório.
- Estrutura SQL `tournament_standings` e `standing_entries` com RLS para snapshots futuros.

### Painel administrativo

- Listagem e filtro de auditoria com todos os eventos do sistema.
- CRUD operacional de bloqueios (criar, ativar, desativar por contexto e recurso).

---

## Arquitetura

O projeto é organizado em camadas com separação clara de responsabilidades:

```
src/
├─ app/              # Roteamento e entrada da aplicação
├─ components/       # Componentes React (ui/, tournament/, matches/, layout/)
├─ pages/            # Páginas da aplicação
├─ domain/           # Funções puras de lógica de torneio (sem React, sem CSS)
│  ├─ brackets/      # Geração de mata-mata, byes, seeding
│  ├─ ranking/       # Cálculo de classificação e desempates
│  ├─ results/       # Validação de placares
│  └─ scheduling/    # Detecção de conflitos de agenda
├─ services/
│  └─ supabase/      # Isolamento do cliente e queries do Supabase
├─ styles/           # Tokens CSS, base, layout e utilitários
└─ tests/
   └─ algorithms/    # Testes das funções de domínio
```

**Decisão central:** a camada de domínio (`src/domain/`) não importa React, CSS, rotas ou o SDK do Supabase. São funções TypeScript puras, testáveis isoladamente. Isso garante que a lógica de torneio possa ser testada sem precisar montar interface ou simular banco.

**Segurança em duas camadas:** a interface esconde ou desabilita ações indisponíveis para melhorar a UX. Mas o banco é a fonte de verdade — nenhuma operação sensível passa sem validação por RLS, policy ou RPC.

---

## Rodando localmente

**Pré-requisitos:** Node.js 18+, npm, conta no Supabase.

```bash
# Clonar o repositório
git clone https://github.com/ninguemdev/UTFPR-TORNEIOS.git
cd UTFPR-TORNEIOS

# Instalar dependências
npm install

# Configurar variáveis de ambiente
cp .env.example .env.local
# Edite .env.local com sua URL e chave anon do Supabase:
# VITE_SUPABASE_URL=https://seu-projeto.supabase.co
# VITE_SUPABASE_ANON_KEY=sua-chave-anon-publica

# Rodar em desenvolvimento
npm run dev
```

**Configurar o banco:**

1. No Supabase, abra o SQL Editor e execute o conteúdo de `supabase/schema.sql`.
2. Promova o primeiro admin com o UUID do perfil criado:
   ```sql
   select public.bootstrap_first_admin('UUID_DO_PROFILE_AQUI');
   ```
3. Para migrations incrementais aplicadas após o schema base, execute os arquivos em `supabase/migrations/` na ordem cronológica.

Consulte `supabase/README.md` para o fluxo completo de schema, testes manuais de RLS e boas práticas de segurança.

---

## Comandos

| Comando | O que faz |
|---|---|
| `npm run dev` | Inicia servidor de desenvolvimento |
| `npm run build` | Gera build de produção |
| `npm run preview` | Visualiza o build localmente |
| `npm run lint` | Valida o código com ESLint |

---

## Documentação técnica

A pasta `docs/` contém a documentação completa do projeto, organizada por tema:

| Arquivo | Conteúdo |
|---|---|
| `00-visao-geral.md` | Problema, público-alvo, objetivos e glossário |
| `01-requisitos-funcionais.md` | Requisitos por módulo |
| `02-regras-de-torneios.md` | Regras de negócio dos formatos competitivos |
| `03-formatos-e-algoritmos.md` | Mata-mata, round robin, suíço e variantes |
| `04-modelo-de-dados.md` | Diagrama e descrição de todas as tabelas |
| `05-fluxos-de-usuario.md` | Jornadas por perfil de usuário |
| `06-arquitetura.md` | Estrutura de pastas, camadas e decisões técnicas |
| `07-rotas-e-telas.md` | Mapa de rotas e responsabilidades de cada tela |
| `08-api-e-contratos.md` | Contratos de RPCs e queries principais |
| `09-ui-ux-design-system.md` | Tokens CSS, componentes e padrões visuais |
| `10-css-responsividade-acessibilidade.md` | Guia de CSS, breakpoints e WCAG |
| `11-testes-e-validacao.md` | Estratégia de testes e checklist |
| `12-roadmap-mvp.md` | Fases de desenvolvimento e status atual |
| `13-checklist-code-review.md` | Critérios de revisão de código |
| `14-arquitetura-completa.md` | Visão expandida da arquitetura |
| `docs/fluxos/` | Fluxos operacionais detalhados com diagramas Mermaid |

---

## O que vem a seguir

O roadmap completo está em `docs/12-roadmap-mvp.md`. As prioridades imediatas antes de novas funcionalidades são:

- Proteger regeneração de chave quando já existirem resultados registrados.
- Testes automatizados de RLS, RPCs e triggers.
- Implementar ou deixar claramente desabilitado os formatos pontos corridos e grupos + playoffs.
- Agenda de partidas com modelo persistido.
- Avisos preventivos de bloqueios administrativos na interface.

Funcionalidades planejadas para versões futuras: notificações, exportação de dados, sistema suíço, integração com calendário, convites para membros de equipe e captura de metadados de requisição nos logs de auditoria.

---

## Segurança

- Senhas gerenciadas exclusivamente pelo Supabase Auth. Nenhuma tabela própria de senha.
- Apenas `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` são expostas no cliente. Chave `service_role`, JWT secret e segredos administrativos nunca aparecem no front-end.
- RLS habilitado em todas as tabelas sensíveis.
- Ações críticas (corrigir resultado, resolver contestação, aprovar pedido) usam RPCs transacionais que validam permissão e registram auditoria no banco.
- Arquivos `.env`, `.env.local` e `.env.*.local` estão no `.gitignore`.
