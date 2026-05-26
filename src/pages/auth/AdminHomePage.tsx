import { type FormEvent, useCallback, useEffect, useMemo, useState } from 'react'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import { useAuth } from '../../context/auth'
import type { ActionLock, ActionLockScope, AuditLog } from '../../lib/supabase/types'
import {
  actionLockActionOptions,
  actionLockScopeLabels,
  createActionLock,
  deleteActionLock,
  fetchActionLocks,
  fetchAuditLogs,
  updateActionLock,
  type AuditLogFilters,
} from '../../services/admin'

type AuditFilterState = Required<Pick<AuditLogFilters, 'action' | 'entityType' | 'tournamentId'>>

type LockFormState = {
  scope: ActionLockScope
  scopeId: string
  action: string
  reason: string
  isLocked: boolean
  expiresAt: string
}

const emptyAuditFilters: AuditFilterState = {
  action: '',
  entityType: '',
  tournamentId: '',
}

const emptyLockForm: LockFormState = {
  scope: 'global',
  scopeId: '',
  action: 'create_tournament',
  reason: '',
  isLocked: true,
  expiresAt: '',
}

const dateTimeFormatter = new Intl.DateTimeFormat('pt-BR', {
  dateStyle: 'short',
  timeStyle: 'short',
})

function formatDateTime(value: string | null) {
  if (!value) return 'Sem prazo'

  const date = new Date(value)

  if (Number.isNaN(date.getTime())) return value

  return dateTimeFormatter.format(date)
}

function toIsoDateTime(value: string) {
  if (!value) return null

  const date = new Date(value)

  if (Number.isNaN(date.getTime())) {
    throw new Error('Data de expiracao invalida.')
  }

  return date.toISOString()
}

function formatEntity(log: AuditLog) {
  return `${log.entity_type} / ${log.entity_id.slice(0, 8)}`
}

export function AdminHomePage() {
  const { profile } = useAuth()

  return (
    <AuthenticatedShell subtitle="Administracao">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="admin-title">
          <div>
            <span className="eyebrow">Area restrita</span>
            <h1 id="admin-title">Admin</h1>
            <p>
              Auditoria geral e bloqueios operacionais para acoes sensiveis do MVP.
            </p>
          </div>
          <div className="page-header-action">
            <a className="button button-primary" href="#/admin/pedidos">
              Revisar pedidos
            </a>
          </div>
        </section>

        <section className="content-grid three-columns" aria-label="Resumo administrativo">
          <article className="rule-card">
            <span className="rule-marker" aria-hidden="true" />
            <h2>Pedidos pendentes</h2>
            <p>Aprovar, rejeitar e revogar permissoes de criacao de torneios.</p>
          </article>
          <article className="rule-card">
            <span className="rule-marker" aria-hidden="true" />
            <h2>Bloqueios</h2>
            <p>Congelar acoes por escopo sem depender apenas da interface.</p>
          </article>
          <article className="rule-card">
            <span className="rule-marker" aria-hidden="true" />
            <h2>Perfil atual</h2>
            <p>{profile?.display_name} possui permissoes globais de admin.</p>
          </article>
        </section>

        <AdminActionLocksPanel />
        <AdminAuditPanel />
      </div>
    </AuthenticatedShell>
  )
}

function AdminAuditPanel() {
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [draftFilters, setDraftFilters] = useState<AuditFilterState>(emptyAuditFilters)
  const [filters, setFilters] = useState<AuditFilterState>(emptyAuditFilters)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')

  const loadLogs = useCallback(async () => {
    setIsLoading(true)
    setError('')

    try {
      const nextLogs = await fetchAuditLogs({
        action: filters.action,
        entityType: filters.entityType,
        tournamentId: filters.tournamentId,
        limit: 100,
      })
      setLogs(nextLogs)
    } catch (loadError) {
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Nao foi possivel carregar auditoria.',
      )
    } finally {
      setIsLoading(false)
    }
  }, [filters])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadLogs()
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadLogs])

  function handleFilterSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setFilters(draftFilters)
  }

  function handleClearFilters() {
    setDraftFilters(emptyAuditFilters)
    setFilters(emptyAuditFilters)
  }

  return (
    <section className="surface-panel" aria-labelledby="audit-title">
      <div className="panel-header">
        <div>
          <span className="eyebrow">Auditoria</span>
          <h2 id="audit-title">Eventos auditados</h2>
        </div>
        <span className="metric-pill">{logs.length} evento{logs.length === 1 ? '' : 's'}</span>
      </div>

      <form className="form-grid" onSubmit={handleFilterSubmit}>
        <label className="field" htmlFor="audit-action-filter">
          <span>Acao</span>
          <input
            id="audit-action-filter"
            value={draftFilters.action}
            onChange={(event) =>
              setDraftFilters((current) => ({ ...current, action: event.target.value }))
            }
            placeholder="match_result_recorded"
          />
        </label>
        <label className="field" htmlFor="audit-entity-filter">
          <span>Entidade</span>
          <input
            id="audit-entity-filter"
            value={draftFilters.entityType}
            onChange={(event) =>
              setDraftFilters((current) => ({ ...current, entityType: event.target.value }))
            }
            placeholder="tournament"
          />
        </label>
        <label className="field" htmlFor="audit-tournament-filter">
          <span>ID do torneio</span>
          <input
            id="audit-tournament-filter"
            value={draftFilters.tournamentId}
            onChange={(event) =>
              setDraftFilters((current) => ({ ...current, tournamentId: event.target.value }))
            }
            placeholder="uuid"
          />
        </label>
        <div className="form-actions">
          <button className="button button-secondary" type="submit">
            Filtrar
          </button>
          <button className="button button-ghost" type="button" onClick={handleClearFilters}>
            Limpar
          </button>
        </div>
      </form>

      {error && (
        <div className="form-message form-message-error" role="alert">
          {error}
        </div>
      )}

      {isLoading ? (
        <div className="loading-state" role="status" aria-live="polite">
          <span className="spinner" aria-hidden="true" />
          <span>Carregando auditoria...</span>
        </div>
      ) : logs.length === 0 ? (
        <section className="empty-state compact-empty">
          <span className="empty-state-mark" aria-hidden="true">0</span>
          <h3>Nenhum evento encontrado</h3>
          <p>Eventos aparecerao aqui quando triggers e RPCs registrarem acoes.</p>
        </section>
      ) : (
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Data</th>
                <th>Acao</th>
                <th>Entidade</th>
                <th>Torneio</th>
                <th>Ator</th>
                <th>Motivo</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => (
                <tr key={log.id}>
                  <td>{formatDateTime(log.created_at)}</td>
                  <td>{log.action}</td>
                  <td>
                    <span className="table-title">{formatEntity(log)}</span>
                  </td>
                  <td>{log.tournament_id?.slice(0, 8) ?? 'N/A'}</td>
                  <td>{log.actor_id?.slice(0, 8) ?? 'Sistema'}</td>
                  <td>{log.reason ?? 'Sem motivo informado'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  )
}

function AdminActionLocksPanel() {
  const [locks, setLocks] = useState<ActionLock[]>([])
  const [form, setForm] = useState<LockFormState>(emptyLockForm)
  const [reasonDrafts, setReasonDrafts] = useState<Record<string, string>>({})
  const [isLoading, setIsLoading] = useState(true)
  const [busyLockId, setBusyLockId] = useState('')
  const [isCreating, setIsCreating] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const activeLocks = useMemo(
    () => locks.filter((lock) => lock.is_locked).length,
    [locks],
  )

  const loadLocks = useCallback(async () => {
    setIsLoading(true)
    setError('')

    try {
      const nextLocks = await fetchActionLocks()
      setLocks(nextLocks)
      setReasonDrafts(
        nextLocks.reduce<Record<string, string>>((drafts, lock) => {
          drafts[lock.id] = lock.reason
          return drafts
        }, {}),
      )
    } catch (loadError) {
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Nao foi possivel carregar bloqueios.',
      )
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadLocks()
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadLocks])

  async function handleCreateLock(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setIsCreating(true)
    setError('')
    setSuccess('')

    try {
      await createActionLock({
        scope: form.scope,
        scopeId: form.scopeId,
        action: form.action,
        reason: form.reason,
        isLocked: form.isLocked,
        expiresAt: toIsoDateTime(form.expiresAt),
      })
      setForm(emptyLockForm)
      setSuccess('Bloqueio criado.')
      await loadLocks()
    } catch (createError) {
      setError(
        createError instanceof Error
          ? createError.message
          : 'Nao foi possivel criar o bloqueio.',
      )
    } finally {
      setIsCreating(false)
    }
  }

  async function handleToggleLock(lock: ActionLock) {
    setBusyLockId(lock.id)
    setError('')
    setSuccess('')

    try {
      await updateActionLock(lock.id, { is_locked: !lock.is_locked })
      setSuccess(lock.is_locked ? 'Bloqueio desativado.' : 'Bloqueio ativado.')
      await loadLocks()
    } catch (toggleError) {
      setError(
        toggleError instanceof Error
          ? toggleError.message
          : 'Nao foi possivel alterar o bloqueio.',
      )
    } finally {
      setBusyLockId('')
    }
  }

  async function handleSaveReason(lock: ActionLock) {
    setBusyLockId(lock.id)
    setError('')
    setSuccess('')

    try {
      await updateActionLock(lock.id, { reason: reasonDrafts[lock.id] ?? lock.reason })
      setSuccess('Motivo atualizado.')
      await loadLocks()
    } catch (saveError) {
      setError(
        saveError instanceof Error
          ? saveError.message
          : 'Nao foi possivel atualizar o motivo.',
      )
    } finally {
      setBusyLockId('')
    }
  }

  async function handleDeleteLock(lock: ActionLock) {
    setBusyLockId(lock.id)
    setError('')
    setSuccess('')

    try {
      await deleteActionLock(lock.id)
      setSuccess('Bloqueio removido.')
      await loadLocks()
    } catch (deleteError) {
      setError(
        deleteError instanceof Error
          ? deleteError.message
          : 'Nao foi possivel remover o bloqueio.',
      )
    } finally {
      setBusyLockId('')
    }
  }

  return (
    <section className="surface-panel" aria-labelledby="locks-title">
      <div className="panel-header">
        <div>
          <span className="eyebrow">Bloqueios</span>
          <h2 id="locks-title">Bloqueios administrativos</h2>
        </div>
        <span className="metric-pill">{activeLocks} ativo{activeLocks === 1 ? '' : 's'}</span>
      </div>

      <form className="form-grid" onSubmit={handleCreateLock}>
        <label className="field" htmlFor="lock-scope">
          <span>Escopo</span>
          <select
            id="lock-scope"
            value={form.scope}
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                scope: event.target.value as ActionLockScope,
                scopeId: event.target.value === 'global' ? '' : current.scopeId,
              }))
            }
          >
            {Object.entries(actionLockScopeLabels).map(([scope, label]) => (
              <option key={scope} value={scope}>
                {label}
              </option>
            ))}
          </select>
        </label>
        <label className="field" htmlFor="lock-scope-id">
          <span>ID do escopo</span>
          <input
            id="lock-scope-id"
            value={form.scopeId}
            disabled={form.scope === 'global'}
            onChange={(event) =>
              setForm((current) => ({ ...current, scopeId: event.target.value }))
            }
            placeholder={form.scope === 'global' ? 'Nao usado' : 'uuid ou identificador'}
          />
        </label>
        <label className="field" htmlFor="lock-action">
          <span>Acao</span>
          <select
            id="lock-action"
            value={form.action}
            onChange={(event) =>
              setForm((current) => ({ ...current, action: event.target.value }))
            }
          >
            {actionLockActionOptions.map((action) => (
              <option key={action} value={action}>
                {action}
              </option>
            ))}
          </select>
        </label>
        <label className="field" htmlFor="lock-expires-at">
          <span>Expira em</span>
          <input
            id="lock-expires-at"
            type="datetime-local"
            value={form.expiresAt}
            onChange={(event) =>
              setForm((current) => ({ ...current, expiresAt: event.target.value }))
            }
          />
        </label>
        <label className="field" htmlFor="lock-reason">
          <span>Motivo</span>
          <textarea
            id="lock-reason"
            value={form.reason}
            onChange={(event) =>
              setForm((current) => ({ ...current, reason: event.target.value }))
            }
            required
          />
        </label>
        <label className="checkbox-field" htmlFor="lock-is-active">
          <input
            id="lock-is-active"
            type="checkbox"
            checked={form.isLocked}
            onChange={(event) =>
              setForm((current) => ({ ...current, isLocked: event.target.checked }))
            }
          />
          <span>Criar como bloqueio ativo</span>
        </label>
        <div className="form-actions">
          <button className="button button-secondary" type="submit" disabled={isCreating}>
            {isCreating ? 'Criando...' : 'Criar bloqueio'}
          </button>
        </div>
      </form>

      {error && (
        <div className="form-message form-message-error" role="alert">
          {error}
        </div>
      )}

      {success && (
        <div className="form-message form-message-success" role="status">
          {success}
        </div>
      )}

      {isLoading ? (
        <div className="loading-state" role="status" aria-live="polite">
          <span className="spinner" aria-hidden="true" />
          <span>Carregando bloqueios...</span>
        </div>
      ) : locks.length === 0 ? (
        <section className="empty-state compact-empty">
          <span className="empty-state-mark" aria-hidden="true">0</span>
          <h3>Nenhum bloqueio criado</h3>
          <p>Bloqueios criados por admins aparecerao nesta lista.</p>
        </section>
      ) : (
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Status</th>
                <th>Escopo</th>
                <th>Acao</th>
                <th>Motivo</th>
                <th>Expira</th>
                <th>Acoes</th>
              </tr>
            </thead>
            <tbody>
              {locks.map((lock) => (
                <tr key={lock.id}>
                  <td>
                    <span className={`badge ${lock.is_locked ? 'badge-danger' : 'badge-finished'}`}>
                      {lock.is_locked ? 'Ativo' : 'Inativo'}
                    </span>
                  </td>
                  <td>
                    <span className="table-title">{actionLockScopeLabels[lock.scope]}</span>
                    <span className="row-note">{lock.scope_id ?? 'global'}</span>
                  </td>
                  <td>{lock.action}</td>
                  <td>
                    <label className="field" htmlFor={`lock-reason-${lock.id}`}>
                      <span>Motivo</span>
                      <textarea
                        id={`lock-reason-${lock.id}`}
                        value={reasonDrafts[lock.id] ?? lock.reason}
                        onChange={(event) =>
                          setReasonDrafts((current) => ({
                            ...current,
                            [lock.id]: event.target.value,
                          }))
                        }
                      />
                    </label>
                  </td>
                  <td>{formatDateTime(lock.expires_at)}</td>
                  <td>
                    <div className="form-actions">
                      <button
                        className="button button-secondary"
                        type="button"
                        disabled={busyLockId === lock.id}
                        onClick={() => void handleSaveReason(lock)}
                      >
                        Salvar
                      </button>
                      <button
                        className="button button-ghost"
                        type="button"
                        disabled={busyLockId === lock.id}
                        onClick={() => void handleToggleLock(lock)}
                      >
                        {lock.is_locked ? 'Desativar' : 'Ativar'}
                      </button>
                      <button
                        className="button button-ghost"
                        type="button"
                        disabled={busyLockId === lock.id}
                        onClick={() => void handleDeleteLock(lock)}
                      >
                        Remover
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  )
}
