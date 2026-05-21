import { useCallback, useEffect, useMemo, useState } from 'react'
import { CreatorRequestCard } from '../../components/auth/CreatorRequestCard'
import { CreatorRequestStatusBadge } from '../../components/auth/CreatorRequestStatusBadge'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import type { TournamentCreatorRequestStatus } from '../../lib/supabase/types'
import {
  type CreatorRequestWithProfile,
  fetchAllCreatorRequests,
  reviewCreatorRequest,
} from '../../services/tournamentCreatorRequests'

type AdminFilter = TournamentCreatorRequestStatus | 'all'

export function AdminCreatorRequestsPage() {
  const [requests, setRequests] = useState<CreatorRequestWithProfile[]>([])
  const [filter, setFilter] = useState<AdminFilter>('pending')
  const [isLoading, setIsLoading] = useState(true)
  const [busyRequestId, setBusyRequestId] = useState('')
  const [error, setError] = useState('')

  const filteredRequests = useMemo(() => {
    if (filter === 'all') return requests
    return requests.filter((request) => request.status === filter)
  }, [filter, requests])

  const pendingCount = requests.filter((request) => request.status === 'pending').length

  const loadRequests = useCallback(async () => {
    setIsLoading(true)
    setError('')

    try {
      setRequests(await fetchAllCreatorRequests())
    } catch (loadError) {
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Não foi possível carregar pedidos administrativos.',
      )
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadRequests()
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadRequests])

  async function handleReview(
    requestId: string,
    decision: 'approved' | 'rejected',
    adminNotes: string,
  ) {
    setBusyRequestId(requestId)
    setError('')

    try {
      await reviewCreatorRequest(requestId, decision, adminNotes)
      await loadRequests()
    } catch (reviewError) {
      setError(
        reviewError instanceof Error
          ? reviewError.message
          : 'Não foi possível revisar o pedido.',
      )
    } finally {
      setBusyRequestId('')
    }
  }

  return (
    <AuthenticatedShell subtitle="Administração">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="admin-requests-title">
          <div>
            <span className="eyebrow">Permissões</span>
            <h1 id="admin-requests-title">Pedidos de criação de torneio</h1>
            <p>
              Admins globais revisam pedidos sem transformar usuários aprovados
              em administradores do site.
            </p>
          </div>
          <div className="page-header-action">
            <span className="metric-pill">
              {pendingCount} pendente{pendingCount === 1 ? '' : 's'}
            </span>
          </div>
        </section>

        <section className="toolbar" aria-label="Filtro de pedidos">
          <label className="field" htmlFor="request-status-filter">
            <span>Status</span>
            <select
              id="request-status-filter"
              value={filter}
              onChange={(event) => setFilter(event.target.value as AdminFilter)}
            >
              <option value="pending">Pendentes</option>
              <option value="approved">Aprovados</option>
              <option value="rejected">Rejeitados</option>
              <option value="cancelled">Cancelados</option>
              <option value="all">Todos</option>
            </select>
          </label>
          <div className="status-preview" aria-label="Status disponíveis">
            <CreatorRequestStatusBadge status="pending" />
            <CreatorRequestStatusBadge status="approved" />
            <CreatorRequestStatusBadge status="rejected" />
          </div>
        </section>

        {error && (
          <div className="form-message form-message-error" role="alert">
            {error}
          </div>
        )}

        {isLoading ? (
          <div className="loading-state" role="status" aria-live="polite">
            <span className="spinner" aria-hidden="true" />
            <span>Carregando pedidos...</span>
          </div>
        ) : filteredRequests.length === 0 ? (
          <section className="empty-state">
            <span className="empty-state-mark" aria-hidden="true">0</span>
            <h2>Nenhum pedido neste filtro</h2>
            <p>Quando usuários solicitarem permissão, os pedidos aparecerão aqui.</p>
          </section>
        ) : (
          <section className="request-list" aria-label="Pedidos administrativos">
            {filteredRequests.map((request) => (
              <CreatorRequestCard
                key={request.id}
                request={request}
                mode="admin"
                isBusy={busyRequestId === request.id}
                onReview={handleReview}
              />
            ))}
          </section>
        )}
      </div>
    </AuthenticatedShell>
  )
}
