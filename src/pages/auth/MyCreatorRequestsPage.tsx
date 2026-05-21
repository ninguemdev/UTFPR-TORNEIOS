import { useCallback, useEffect, useState } from 'react'
import { CreatorRequestCard } from '../../components/auth/CreatorRequestCard'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import { useAuth } from '../../context/auth'
import type { TournamentCreatorRequest } from '../../lib/supabase/types'
import {
  cancelCreatorRequest,
  fetchMyCreatorRequests,
} from '../../services/tournamentCreatorRequests'

export function MyCreatorRequestsPage() {
  const { user, refreshCreatorPermission } = useAuth()
  const [requests, setRequests] = useState<TournamentCreatorRequest[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [busyRequestId, setBusyRequestId] = useState('')
  const [error, setError] = useState('')

  const loadRequests = useCallback(async () => {
    if (!user) return

    setIsLoading(true)
    setError('')

    try {
      setRequests(await fetchMyCreatorRequests(user.id))
      await refreshCreatorPermission()
    } catch (loadError) {
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Não foi possível carregar seus pedidos.',
      )
    } finally {
      setIsLoading(false)
    }
  }, [refreshCreatorPermission, user])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadRequests()
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadRequests])

  async function handleCancel(requestId: string) {
    setBusyRequestId(requestId)
    setError('')

    try {
      await cancelCreatorRequest(requestId)
      await refreshCreatorPermission()
      await loadRequests()
    } catch (cancelError) {
      setError(
        cancelError instanceof Error
          ? cancelError.message
          : 'Não foi possível cancelar o pedido.',
      )
    } finally {
      setBusyRequestId('')
    }
  }

  return (
    <AuthenticatedShell subtitle="Meus pedidos">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="my-requests-title">
          <div>
            <span className="eyebrow">Organização</span>
            <h1 id="my-requests-title">Meus pedidos</h1>
            <p>
              Acompanhe o status das suas solicitações de permissão para criar
              torneios.
            </p>
          </div>
          <div className="page-header-action">
            <a className="button button-primary" href="#/solicitar-criacao-torneio">
              Novo pedido
            </a>
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
        ) : requests.length === 0 ? (
          <section className="empty-state">
            <span className="empty-state-mark" aria-hidden="true">0</span>
            <h2>Nenhum pedido enviado</h2>
            <p>Solicite permissão para organizar torneios acadêmicos.</p>
            <a className="button button-primary" href="#/solicitar-criacao-torneio">
              Solicitar permissão
            </a>
          </section>
        ) : (
          <section className="request-list" aria-label="Meus pedidos de criação">
            {requests.map((request) => (
              <CreatorRequestCard
                key={request.id}
                request={request}
                mode="user"
                isBusy={busyRequestId === request.id}
                onCancel={handleCancel}
              />
            ))}
          </section>
        )}
      </div>
    </AuthenticatedShell>
  )
}
