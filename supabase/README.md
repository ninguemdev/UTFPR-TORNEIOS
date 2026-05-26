# Supabase

Este diretorio concentra o bootstrap atual do banco e a estrutura para evolucao
por migrations versionadas.

## Arquivos

- `schema.sql`: bootstrap atual do banco. Cria enums, tabelas, indices,
  triggers, grants, RLS, policies e RPCs.
- `migrations/`: pasta reservada para migrations incrementais daqui para
  frente.

## Variaveis de ambiente

O front-end usa somente variaveis publicas do Vite:

```text
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

Use `.env.example` como modelo e crie `.env.local` apenas na sua maquina.
Nunca coloque chave real em `.env.example`.

Nunca exponha no front-end:

- `service_role`;
- JWT secret;
- senha de banco;
- token pessoal;
- qualquer segredo administrativo.

## Como aplicar `schema.sql`

Para um projeto Supabase novo ou ambiente de desenvolvimento vazio:

1. Abra o projeto no painel do Supabase.
2. Acesse SQL Editor.
3. Execute o conteudo completo de `supabase/schema.sql`.
4. Crie um usuario pelo app ou pelo Supabase Auth.
5. Promova o primeiro admin com a funcao de bootstrap.

Exemplo:

```sql
select public.bootstrap_first_admin('UUID_DO_PROFILE_AQUI');
```

Essa funcao nao recebe grant para `anon` ou `authenticated`; ela deve ser usada
manualmente por alguem com acesso administrativo ao SQL Editor.

## Migrations daqui para frente

O `schema.sql` permanece como bootstrap consolidado do estado atual. Mudancas
novas de banco devem entrar em `supabase/migrations/` como arquivos
incrementais, sem apagar o bootstrap.

Fluxo recomendado:

1. Criar uma migration nova em `supabase/migrations/`.
2. Incluir schema, RLS, grants, policies, triggers e comentarios SQL afetados.
3. Atualizar `supabase/schema.sql` para manter o bootstrap consolidado.
4. Atualizar `src/lib/supabase/types.ts` ou gerar tipos pela Supabase CLI.
5. Atualizar services e documentacao afetados.
6. Validar RLS com usuarios anonimo, usuario comum, organizador e admin.

Quando a Supabase CLI estiver inicializada, o fluxo esperado passa a ser:

```bash
supabase migration new nome_da_mudanca
supabase db reset
supabase db push
```

Use `db reset` apenas em ambiente local ou descartavel. Em staging/producao,
revise a migration antes de aplicar e mantenha backup.

## Teste manual de RLS

Valide pelo painel Supabase, SQL Editor e pela aplicacao com contas diferentes:

1. Usuario anonimo ve apenas dados publicos.
2. Usuario comum edita apenas o proprio profile.
3. Usuario comum nao altera `profiles.role`.
4. Usuario comum nao cria torneio sem permissao ativa.
5. Organizador autorizado gerencia apenas torneios proprios.
6. Permissao revogada bloqueia novas criacoes/gestao indevida.
7. Admin revisa pedidos, revoga permissoes e gerencia qualquer torneio.
8. Escrita direta em tabelas sensiveis falha quando deveria passar apenas por RPC.
9. RPCs sensiveis validam permissao no banco, nao apenas na interface.

## Regras de seguranca

- Toda tabela de negocio deve ter RLS habilitado.
- Toda policy deve considerar `auth.uid()`, `public.is_admin()` ou helpers
  especificos como `public.can_manage_tournament()`.
- Toda RPC `security definer` deve fixar `search_path`.
- Mudanca destrutiva exige plano de migracao em fases.
- Nunca versionar dumps com dados reais, tokens, emails sensiveis ou secrets.
