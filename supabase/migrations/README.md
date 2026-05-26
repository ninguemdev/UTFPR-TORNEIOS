# Migrations

Esta pasta esta reservada para migrations versionadas do Supabase.

## Estado atual

O banco atual ainda usa `../schema.sql` como bootstrap consolidado. Mudancas
incrementais novas tambem devem ser registradas aqui.

Migrations existentes:

- `20260526090000_add_audit_logs_action_locks.sql`: auditoria geral e bloqueios
  administrativos.

## Proxima migration

Para uma mudanca nova de banco, crie um arquivo com timestamp e nome descritivo:

```text
YYYYMMDDHHMMSS_nome_da_mudanca.sql
```

Exemplo:

```text
20260526090100_nome_da_mudanca.sql
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
