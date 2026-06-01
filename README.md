# UTFPR Torneios

Sistema web acadêmico da UTFPR para organização de torneios, e-sports e competições gerais.

O objetivo é oferecer uma plataforma clara, responsiva e acessível para organizadores criarem torneios, gerenciarem inscrições, participantes, equipes, partidas, resultados, rankings, chaves e disputas.

## Stack

- Vite
- React
- TypeScript
- CSS próprio
- Supabase recomendado para autenticação, PostgreSQL e Row Level Security
- ESLint
- npm

## Comandos

Instalar dependências:

```bash
npm install
```

Rodar em desenvolvimento:

```bash
npm run dev
```

Validar lint:

```bash
npm run lint
```

Gerar build:

```bash
npm run build
```

## Configuracao local

Crie um `.env.local` a partir de `.env.example`:

```text
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

Use apenas a URL publica do projeto Supabase e a chave `anon` publica no
front-end. Nunca coloque `service_role`, JWT secret, senha de banco ou token
administrativo no repositorio.

Arquivos `.env`, `.env.local` e `.env.*.local` ficam ignorados pelo Git.

## Supabase e migrations

O bootstrap atual do banco esta em `supabase/schema.sql`. Para ambientes novos,
aplique esse arquivo pelo SQL Editor do Supabase e depois promova o primeiro
admin com:

```sql
select public.bootstrap_first_admin('UUID_DO_PROFILE_AQUI');
```

A pasta `supabase/migrations/` esta reservada para migrations incrementais
daqui em diante. Veja `supabase/README.md` para o fluxo de schema, migrations,
seguranca e testes manuais de RLS.

Migration incremental atual:

- `20260526090000_add_audit_logs_action_locks.sql`: cria `audit_logs`,
  `action_locks`, triggers de auditoria e validacoes de bloqueio no banco.

## Documentação

- [00 - Visão geral](docs/00-visao-geral.md)
- [01 - Requisitos funcionais](docs/01-requisitos-funcionais.md)
- [02 - Regras de torneios](docs/02-regras-de-torneios.md)
- [03 - Formatos e algoritmos](docs/03-formatos-e-algoritmos.md)
- [04 - Modelo de dados](docs/04-modelo-de-dados.md)
- [05 - Fluxos de usuário](docs/05-fluxos-de-usuario.md)
- [06 - Arquitetura](docs/06-arquitetura.md)
- [07 - Rotas e telas](docs/07-rotas-e-telas.md)
- [08 - API e contratos](docs/08-api-e-contratos.md)
- [09 - UI/UX e design system](docs/09-ui-ux-design-system.md)
- [10 - CSS, responsividade e acessibilidade](docs/10-css-responsividade-acessibilidade.md)
- [11 - Testes e validação](docs/11-testes-e-validacao.md)
- [12 - Roadmap MVP](docs/12-roadmap-mvp.md)
- [13 - Checklist de code review](docs/13-checklist-code-review.md)
- [14 - Arquitetura completa](docs/14-arquitetura-completa.md)
- [Fluxos completos e casos de uso](docs/fluxos/00-indice-fluxos.md)

## Documentacao de fluxos e casos de uso

A pasta [`docs/fluxos`](docs/fluxos/00-indice-fluxos.md) contem o mapa completo dos fluxos operacionais do sistema: atores, permissoes, pre-condicoes, caminhos felizes, fluxos alternativos, erros, regras de seguranca, dados lidos/escritos, telas, services, componentes, fluxogramas Mermaid, matriz de casos de uso, falhas conhecidas, checklist de validacao e pendencias por prioridade.

Use esses documentos antes de abrir novas tarefas de implementacao: eles indicam o que esta implementado, parcial, pendente, futuro, inconsistente ou precisa revisao.

## Escopo inicial

O MVP deve priorizar:

- Documentação e arquitetura clara.
- Autenticação com email e senha via Supabase Auth.
- Perfis `admin` e `user`.
- Perfil com RA e avatar pré-definido por `avatar_key`.
- Permissões validadas no banco com Row Level Security.
- Layout responsivo e acessível.
- CRUD inicial de torneios.
- Participantes, equipes e inscrições.
- Mata-mata simples.
- Resultados e ranking básico.
- Auditoria geral e bloqueios administrativos.
- Pontos corridos.
- Grupos + playoffs.
- Disputas e auditoria.

## Observação sobre documentos de referência

O projeto cita como referências obrigatórias:

- `Funcionamento de torneios.pdf`
- `AGENTS.md`
- `checklist-responsividade-design.md`
- `code_review.md`
- `frontend-boas-praticas.md`

No estado atual do repositório, apenas `AGENTS.md` foi localizado. A documentação em `docs/` foi criada com base no `AGENTS.md` e no escopo informado para o projeto, e deve ser revisada quando os demais arquivos forem adicionados.

## Segurança e autenticação

O sistema deve usar Supabase como solução recomendada para autenticação, banco PostgreSQL e Row Level Security.

- Não armazenar senha em tabela própria.
- Não expor chaves privadas no front-end.
- Usar RLS nas tabelas importantes.
- Validar permissões no banco, não apenas na interface.
- Admins são administradores globais.
- Usuários comuns podem editar apenas o próprio perfil, inscrever-se em torneios e solicitar permissão para criar torneios.
