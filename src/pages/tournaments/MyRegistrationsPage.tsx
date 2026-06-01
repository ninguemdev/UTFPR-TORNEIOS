import { useCallback, useEffect, useState } from 'react'
import { TournamentRegistrationStatusBadge } from '../../components/tournament/TournamentRegistrationStatusBadge'
import { SupabaseTournamentStatusBadge } from '../../components/tournament/TournamentStatusBadge'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import { useAuth } from '../../context/auth'
import {
  canUserCancelRegistration,
  cancelTournamentRegistration,
  fetchMyTournamentRegistrations,
  getRegistrationDisplayStatus,
  registrationTypeLabels,
  type MyTournamentRegistration,
} from '../../services/tournaments'

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value))
}

export function MyRegistrationsPage() {
  const { user } = useAuth()
  const [registrations, setRegistrations] = useState<MyTournamentRegistration[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const loadRegistrations = useCallback(async () => {
    if (!user) return

    setIsLoading(true)
    setError('')

    try {
      setRegistrations(await fetchMyTournamentRegistrations(user.id))
    } catch (loadError) {
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Não foi possível carregar suas inscrições.',
      )
    } finally {
      setIsLoading(false)
    }
  }, [user])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadRegistrations()
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadRegistrations])

  async function handleCancelRegistration(registration: MyTournamentRegistration) {
    setIsSubmitting(registration.id)
    setError('')
    setSuccess('')

    try {
      await cancelTournamentRegistration(registration.id)
      await loadRegistrations()
      setSuccess('Inscrição cancelada.')
    } catch (cancelError) {
      setError(
        cancelError instanceof Error
          ? cancelError.message
          : 'Não foi possível cancelar a inscrição.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  return (
    <AuthenticatedShell subtitle="Minhas inscrições">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="my-registrations-title">
          <div>
            <span className="eyebrow">Conta</span>
            <h1 id="my-registrations-title">Minhas inscrições</h1>
            <p>Acompanhe pedidos pendentes, confirmações, rejeições e cancelamentos.</p>
          </div>
          <div className="page-header-action">
            <a className="button button-primary" href="#/torneios">
              Ver torneios
            </a>
          </div>
        </section>

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
            <span>Carregando inscrições...</span>
          </div>
        ) : registrations.length === 0 ? (
          <section className="empty-state">
            <span className="empty-state-mark" aria-hidden="true">0</span>
            <h2>Nenhuma inscrição</h2>
            <p>Quando você se inscrever em um torneio, o histórico aparecerá aqui.</p>
            <a className="button button-primary" href="#/torneios">
              Encontrar torneios
            </a>
          </section>
        ) : (
          <section className="request-list" aria-label="Minhas inscrições em torneios">
            {registrations.map((registration) => {
              const tournament = registration.tournament
              const canCancel = tournament
                ? canUserCancelRegistration(tournament, registration)
                : false

              return (
                <article className="request-card surface-panel" key={registration.id}>
                  <div className="card-topline">
                    <TournamentRegistrationStatusBadge
                      status={getRegistrationDisplayStatus(registration)}
                    />
                    <span>{formatDateTime(registration.created_at)}</span>
                  </div>
                  <div className="request-reason">
                    <h2>{tournament?.name ?? 'Torneio indisponível'}</h2>
                    <p>{registration.display_name}</p>
                  </div>
                  <dl className="definition-grid">
                    <div>
                      <dt>Tipo</dt>
                      <dd>{registrationTypeLabels[registration.registration_type]}</dd>
                    </div>
                    <div>
                      <dt>Status do torneio</dt>
                      <dd>
                        {tournament ? (
                          <SupabaseTournamentStatusBadge status={tournament.status} />
                        ) : (
                          'Não disponível'
                        )}
                      </dd>
                    </div>
                    <div>
                      <dt>Atualizada em</dt>
                      <dd>{formatDateTime(registration.updated_at)}</dd>
                    </div>
                  </dl>
                  {registration.admin_notes && (
                    <div className="admin-notes">
                      <strong>Observação da organização</strong>
                      <p>{registration.admin_notes}</p>
                    </div>
                  )}
                  <div className="card-actions">
                    {tournament && (
                      <a className="button button-secondary" href={`#/torneios/${tournament.id}`}>
                        Ver torneio
                      </a>
                    )}
                    <button
                      className="button button-ghost"
                      type="button"
                      disabled={!canCancel || isSubmitting !== ''}
                      onClick={() => void handleCancelRegistration(registration)}
                    >
                      {isSubmitting === registration.id ? 'Cancelando...' : 'Cancelar inscrição'}
                    </button>
                  </div>
                </article>
              )
            })}
          </section>
        )}
      </div>
    </AuthenticatedShell>
  )
}
