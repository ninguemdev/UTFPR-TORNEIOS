# Migrations

Esta pasta esta reservada para migrations versionadas do Supabase.

## Estado atual

O banco atual ainda usa `../schema.sql` como bootstrap consolidado. Nenhuma
migration inicial foi duplicada aqui nesta etapa para evitar manter duas fontes
grandes e divergentes antes da Supabase CLI estar inicializada no projeto.

## Proxima migration

Para uma mudanca nova de banco, crie um arquivo com timestamp e nome descritivo:

```text
YYYYMMDDHHMMSS_nome_da_mudanca.sql
```

Exemplo:

```text
20260526090000_create_action_locks.sql
```

A migration deve incluir, quando aplicavel:

- alteracoes de tabela, enum, indice e constraints;
- RLS;
- grants;
- policies;
- triggers;
- RPCs;
- comentarios SQL;
- backfill seguro.

Depois de validar a migration, atualize tambem `../schema.sql` para manter o
bootstrap completo de ambientes novos.
