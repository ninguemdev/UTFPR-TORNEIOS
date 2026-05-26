# Arquitetura

## Stack respeitada

O projeto já utiliza:

- Vite.
- React.
- TypeScript.
- CSS próprio.
- ESLint.
- npm.
- Supabase como solução recomendada para autenticação, PostgreSQL, Row Level Security e controle de acesso.

Essa stack deve ser mantida no MVP por ser simples, moderna e adequada a um projeto acadêmico revisável.

## Estrutura de pastas recomendada

```text
src/
├─ app/
│  ├─ App.tsx
│  └─ routes.tsx
├─ components/
│  ├─ ui/
│  ├─ tournament/
│  ├─ matches/
│  └─ layout/
├─ pages/
│  ├─ DashboardPage.tsx
│  ├─ TournamentListPage.tsx
│  ├─ TournamentDetailPage.tsx
│  └─ PublicTournamentPage.tsx
├─ domain/
│  ├─ tournaments/
│  ├─ participants/
│  ├─ matches/
│  ├─ ranking/
│  └─ scheduling/
├─ data/
│  ├─ mockData.ts
│  └─ repositories/
├─ services/
│  ├─ supabase/
│  └─ auth/
├─ security/
│  ├─ permissions.ts
│  └─ rls-notes.md
├─ styles/
│  ├─ tokens.css
│  ├─ base.css
│  ├─ layout.css
│  └─ utilities.css
├─ tests/
│  ├─ algorithms/
│  └─ components/
└─ utils/
```

## Camadas do sistema

### UI

Componentes React, páginas e estados visuais. Não deve conter regras complexas de torneio.

### Lógica de torneio

Funções puras em `src/domain/`, responsáveis por gerar chave, round robin, ranking, desempates, avanço de fase e validações.

### Dados

No MVP inicial pode usar mocks e repositórios locais. A solução recomendada para persistência real é Supabase PostgreSQL com RLS habilitado.

### Autenticação

Autenticação deve usar Supabase Auth com email e senha. O front-end deve consumir sessão e usuário autenticado pelo SDK oficial quando a integração for implementada.

O sistema não deve criar tabela própria de senhas nem manipular hash de senha.

### Autorização

Permissões devem ser aplicadas em duas camadas:

- Interface: esconder ou desabilitar ações indisponíveis para melhorar UX.
- Banco: negar operações por RLS, policies e/ou RPCs protegidas.

A camada de banco é a fonte de verdade. Nenhuma ação sensível pode depender apenas de lógica no React.

### Validação

Validações de formulário podem ficar próximas da UI. Validações de negócio devem ficar no domínio.

## Onde ficam algoritmos

Algoritmos devem ficar em módulos puros, por exemplo:

- `src/domain/brackets/generateSingleElimination.ts`
- `src/domain/roundRobin/generateRoundRobin.ts`
- `src/domain/ranking/calculateStandings.ts`
- `src/domain/scheduling/detectScheduleConflict.ts`
- `src/domain/results/validateMatchResult.ts`

## Onde ficam componentes visuais

- Componentes genéricos: `src/components/ui/`.
- Cards e listas de torneio: `src/components/tournament/`.
- Partidas: `src/components/matches/`.
- Layouts: `src/components/layout/`.

## Onde ficam estilos

CSS global e tokens devem ficar em `src/styles/`. CSS específico pode ficar junto do componente quando a base crescer, desde que siga padrões consistentes.

## Onde ficam testes

Testes de algoritmo devem ficar próximos do domínio ou em `src/tests/algorithms/`. Testes de componentes devem validar estados vazio, loading, erro, sucesso e sem permissão.

Testes de segurança devem validar RLS e permissões no Supabase quando a integração existir.

## Como evitar acoplamento

- UI chama funções de domínio, mas domínio não importa React.
- Funções de ranking não devem depender de CSS, rotas ou componentes.
- Dados mockados devem implementar contratos parecidos com os repositórios futuros.
- Tipos compartilhados devem ficar em módulos de domínio.
- Componentes devem receber dados por props e evitar buscar dados diretamente quando possível.
- Componentes não devem importar chaves privadas nem executar lógica de autorização definitiva.
- Serviços de Supabase devem ficar isolados em `src/services/supabase/`.
- Regras complexas de permissão devem ser expressas em policies/RPCs e documentadas.

## Supabase recomendado

### Estado atual da infraestrutura Supabase

O projeto ja possui integracao real com Supabase no front-end:

- `src/lib/supabase/client.ts` le `VITE_SUPABASE_URL` e
  `VITE_SUPABASE_ANON_KEY`.
- `.env.example` existe sem valores reais.
- `.env`, `.env.local` e `.env.*.local` nao devem ser versionados.
- `supabase/schema.sql` permanece como bootstrap consolidado do banco atual.
- `supabase/README.md` documenta aplicacao do schema, primeiro admin e testes
  manuais de RLS.
- `supabase/migrations/` fica reservado para migrations incrementais futuras.

Ainda nao ha `supabase/config.toml`; quando a Supabase CLI for inicializada, o
fluxo de migrations deve ser incorporado sem apagar `schema.sql`.

### Cliente front-end

O front-end poderá usar apenas:

- URL pública do projeto Supabase.
- Chave `anon` pública.

Esses valores devem ficar em variáveis de ambiente públicas do Vite. Chave `service_role` e segredos administrativos nunca devem ser expostos no navegador.

No estado atual, o arquivo `.env.example` deve conter somente:

```text
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

### Banco PostgreSQL

As tabelas principais devem ficar no schema público ou schema próprio da aplicação, sempre com RLS habilitado. Tabelas esperadas:

- `profiles`.
- `tournament_creator_requests`.
- `global_settings`.
- `action_locks`.
- `tournaments`.
- `registrations`.
- `teams`.
- `team_members`.
- `matches`.
- `match_results`.
- `disputes`.
- `audit_logs`.

### Policies

Policies mínimas:

- Usuário lê/atualiza apenas o próprio perfil, exceto admin.
- Admin lê e altera dados administrativos.
- Usuário comum visualiza torneios públicos.
- Usuário comum se inscreve em torneios abertos.
- Usuário comum cria torneio apenas se tiver permissão ativa em `tournament_creator_permissions`.
- Admin pode alterar torneios em andamento ou encerrados com auditoria.

### Funções RPC

Ações críticas como corrigir resultado, resolver disputa, aprovar pedido e bloquear ação devem preferir RPCs transacionais, para garantir auditoria e validação no banco.

## Como o projeto deve crescer

1. Começar com documentação, tipos e dados mockados.
2. Implementar páginas estáticas funcionais.
3. Extrair algoritmos para funções puras testáveis.
4. Adicionar Supabase Auth, profiles e permissões básicas.
5. Adicionar persistência com PostgreSQL e RLS.
6. Expandir formatos avançados.
