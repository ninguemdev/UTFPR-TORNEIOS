import { type FormEvent, useCallback, useEffect, useMemo, useState } from 'react'
import { TournamentRegistrationStatusBadge } from '../../components/tournament/TournamentRegistrationStatusBadge'
import { SupabaseTournamentStatusBadge } from '../../components/tournament/TournamentStatusBadge'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import { useAuth } from '../../context/auth'
import type { TournamentRegistration } from '../../lib/supabase/types'
import {
  canManageTournament,
  canUserCancelRegistration,
  cancelTournamentRegistration,
  confirmRegistrationCheckIn,
  fetchTournament,
  fetchTournamentRegistrations,
  findActiveRegistration,
  getRegistrationDisplayStatus,
  isRegistrationOperationallyActive,
  isPublicTournamentStatus,
  isPublicParticipant,
  isTournamentCheckInOpen,
  registerForTournament,
  registrationTypeLabels,
  tournamentFormatLabels,
  tournamentStatusLabels,
  type TournamentWithCount,
} from '../../services/tournaments'

function formatDate(value: string | null) {
  if (!value) return 'A definir'

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'medium',
  }).format(new Date(`${value}T00:00:00`))
}

function formatDateTime(value: string | null) {
  if (!value) return 'Nao definido'

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value))
}

export function PublicTournamentPage({ tournamentId }: { tournamentId: string }) {
  const { user, profile, isAdmin, canCreateTournaments } = useAuth()
  const [tournament, setTournament] = useState<TournamentWithCount | null>(null)
  const [registrations, setRegistrations] = useState<TournamentRegistration[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const activeRegistrations = useMemo(
    () => registrations.filter(isRegistrationOperationallyActive),
    [registrations],
  )
  const publicParticipants = useMemo(
    () => registrations.filter(isPublicParticipant),
    [registrations],
  )

  const activeRegistration = findActiveRegistration(registrations, user?.id)
  const canRegister =
    tournament?.status === 'registrations_open' &&
    tournament.registration_type === 'individual' &&
    Boolean(user) &&
    !activeRegistration &&
    activeRegistrations.length < (tournament?.max_participants ?? 0)
  const canManage = tournament
    ? canManageTournament(tournament, user?.id, isAdmin, canCreateTournaments)
    : false
  const canCancelActiveRegistration =
    Boolean(tournament && activeRegistration) &&
    !activeRegistration?.disqualified_at &&
    canUserCancelRegistration(tournament!, activeRegistration!)
  const canConfirmCheckIn =
    Boolean(tournament && activeRegistration) &&
    activeRegistration?.status === 'confirmed' &&
    !activeRegistration.checked_in_at &&
    !activeRegistration.disqualified_at &&
    isTournamentCheckInOpen(tournament!)

  const loadTournament = useCallback(async () => {
    setIsLoading(true)
    setError('')

    try {
      const nextTournament = await fetchTournament(tournamentId)
      const nextRegistrations = await fetchTournamentRegistrations(nextTournament.id)
      setTournament(nextTournament)
      setRegistrations(nextRegistrations)
    } catch (loadError) {
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Não foi possível carregar o torneio.',
      )
      setTournament(null)
      setRegistrations([])
    } finally {
      setIsLoading(false)
    }
  }, [tournamentId])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadTournament()
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadTournament])

  async function handleRegister(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError('')
    setSuccess('')

    if (!tournament) return

    if (!user) {
      window.location.hash = '#/login'
      return
    }

    const formData = new FormData(event.currentTarget)
    const displayName = String(formData.get('display_name') ?? '').trim()

    if (displayName.length < 2) {
      setError('Informe um nome de inscrição com pelo menos 2 caracteres.')
      return
    }

    setIsSubmitting(true)

    try {
      await registerForTournament(
        tournament.id,
        user.id,
        displayName,
        tournament.registration_type,
      )
      await loadTournament()
      setSuccess('Pedido de inscrição enviado. Aguarde confirmação da organização.')
    } catch (registrationError) {
      setError(
        registrationError instanceof Error
          ? registrationError.message
          : 'Não foi possível realizar inscrição.',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleCancelRegistration() {
    if (!activeRegistration) return

    setIsSubmitting(true)
    setError('')
    setSuccess('')

    try {
      await cancelTournamentRegistration(activeRegistration.id)
      await loadTournament()
      setSuccess('Inscrição cancelada.')
    } catch (cancelError) {
      setError(
        cancelError instanceof Error
          ? cancelError.message
          : 'Não foi possível cancelar inscrição.',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleConfirmCheckIn() {
    if (!activeRegistration) return

    setIsSubmitting(true)
    setError('')
    setSuccess('')

    try {
      await confirmRegistrationCheckIn(activeRegistration.id)
      await loadTournament()
      setSuccess('Check-in confirmado.')
    } catch (checkInError) {
      setError(
        checkInError instanceof Error
          ? checkInError.message
          : 'Nao foi possivel confirmar check-in.',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  if (isLoading) {
    return (
      <AuthenticatedShell subtitle="Torneio público">
        <div className="loading-state" role="status" aria-live="polite">
          <span className="spinner" aria-hidden="true" />
          <span>Carregando torneio...</span>
        </div>
      </AuthenticatedShell>
    )
  }

  if (!tournament) {
    return (
      <AuthenticatedShell subtitle="Torneio público">
        <section className="empty-state">
          <span className="empty-state-mark" aria-hidden="true">?</span>
          <h1>Torneio não encontrado</h1>
          <p>{error || 'O torneio não existe ou ainda não está público.'}</p>
          <a className="button button-primary" href="#/torneios">
            Ver torneios
          </a>
        </section>
      </AuthenticatedShell>
    )
  }

  return (
    <AuthenticatedShell subtitle="Torneio público">
      <div className="page-stack">
        <section className="public-cover" aria-labelledby="public-tournament-title">
          <SupabaseTournamentStatusBadge status={tournament.status} />
          <h1 id="public-tournament-title">{tournament.name}</h1>
          <p>{tournament.description || 'Torneio cadastrado na Chaveia.'}</p>
          {!isPublicTournamentStatus(tournament.status) && (
            <p className="subtle-note">Este torneio ainda está em rascunho e não aparece publicamente.</p>
          )}
        </section>

        <section className="content-grid two-columns">
          <article className="surface-panel">
            <div className="section-heading">
              <h2>Informações</h2>
              <p>Dados principais do torneio.</p>
            </div>
            <dl className="definition-grid">
              <div>
                <dt>Modalidade</dt>
                <dd>{tournament.modality}</dd>
              </div>
              <div>
                <dt>Formato</dt>
                <dd>{tournamentFormatLabels[tournament.format] ?? tournament.format}</dd>
              </div>
              <div>
                <dt>Campus</dt>
                <dd>{tournament.campus || 'Não informado'}</dd>
              </div>
              <div>
                <dt>Status</dt>
                <dd>{tournamentStatusLabels[tournament.status]}</dd>
              </div>
              <div>
                <dt>Início</dt>
                <dd>{formatDate(tournament.starts_at)}</dd>
              </div>
              <div>
                <dt>Fim</dt>
                <dd>{formatDate(tournament.ends_at)}</dd>
              </div>
              <div>
                <dt>Inscritos</dt>
                <dd>{activeRegistrations.length}/{tournament.max_participants}</dd>
              </div>
              <div>
                <dt>Tipo</dt>
                <dd>{registrationTypeLabels[tournament.registration_type]}</dd>
              </div>
              <div>
                <dt>Check-in</dt>
                <dd>{tournament.requires_check_in ? 'Obrigatorio' : 'Opcional'}</dd>
              </div>
              <div>
                <dt>Janela</dt>
                <dd>
                  {tournament.check_in_opens_at
                    ? `${formatDateTime(tournament.check_in_opens_at)} ate ${formatDateTime(tournament.check_in_closes_at)}`
                    : 'Nao aberta'}
                </dd>
              </div>
              {tournament.registration_type === 'team' && (
                <div>
                  <dt>Equipe</dt>
                  <dd>
                    {tournament.team_min_size} a {tournament.team_max_size} integrantes
                  </dd>
                </div>
              )}
            </dl>
            <div className="card-actions">
              <a className="button button-secondary" href={`#/torneios/${tournament.id}/participantes`}>
                Ver participantes
              </a>
              <a className="button button-secondary" href={`#/torneios/${tournament.id}/chave`}>
                Ver chave
              </a>
              <a className="button button-secondary" href={`#/torneios/${tournament.id}/ranking`}>
                Ver ranking
              </a>
              {tournament.registration_type === 'team' && (
                <a className="button button-secondary" href={`#/torneios/${tournament.id}/equipes`}>
                  Ver equipes
                </a>
              )}
              {canManage && (
                <a className="button button-ghost" href={`#/torneios/${tournament.id}/editar`}>
                  Editar torneio
                </a>
              )}
            </div>
          </article>

          <article className="surface-panel">
            <div className="section-heading">
              <h2>Inscrição</h2>
              <p>Inscrições são aceitas somente no status inscrições abertas.</p>
            </div>

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

            {activeRegistration ? (
              <div className="registration-state">
                <strong>Sua inscrição está registrada.</strong>
                <TournamentRegistrationStatusBadge
                  status={getRegistrationDisplayStatus(activeRegistration)}
                />
                <p>Nome na inscrição: {activeRegistration.display_name}</p>
                <p>
                  Check-in:{' '}
                  {activeRegistration.checked_in_at
                    ? `confirmado em ${formatDateTime(activeRegistration.checked_in_at)}`
                    : isTournamentCheckInOpen(tournament)
                      ? 'janela aberta'
                      : 'janela fechada'}
                </p>
                {activeRegistration.disqualification_reason && (
                  <p>Desclassificacao: {activeRegistration.disqualification_reason}</p>
                )}
                {activeRegistration.no_show_reason && (
                  <p>W.O.: {activeRegistration.no_show_reason}</p>
                )}
                {activeRegistration.admin_notes && (
                  <p>Observação da organização: {activeRegistration.admin_notes}</p>
                )}
                <button
                  className="button button-primary"
                  type="button"
                  disabled={isSubmitting || !canConfirmCheckIn}
                  onClick={() => void handleConfirmCheckIn()}
                >
                  {isSubmitting ? 'Confirmando...' : 'Confirmar check-in'}
                </button>
                {!canConfirmCheckIn && !activeRegistration.checked_in_at && (
                  <p>Check-in disponivel apenas para inscricao confirmada durante a janela.</p>
                )}
                <button
                  className="button button-secondary"
                  type="button"
                  disabled={isSubmitting || !canCancelActiveRegistration}
                  onClick={() => void handleCancelRegistration()}
                >
                  {isSubmitting ? 'Cancelando...' : 'Cancelar inscrição'}
                </button>
                {!canCancelActiveRegistration && (
                  <p>A inscrição não pode ser cancelada neste status do torneio.</p>
                )}
              </div>
            ) : canRegister ? (
              <form className="auth-form" onSubmit={handleRegister} noValidate>
                <label className="field" htmlFor="registration-display-name">
                  <span>
                    {tournament.registration_type === 'team'
                      ? 'Nome da equipe'
                      : 'Nome para inscrição'}
                  </span>
                  <input
                    id="registration-display-name"
                    name="display_name"
                    type="text"
                    defaultValue={profile?.display_name ?? ''}
                    required
                  />
                </label>
                <div className="registration-state">
                  <strong>{registrationTypeLabels[tournament.registration_type]}</strong>
                  <p>
                    {tournament.registration_type === 'team'
                      ? 'Nesta etapa, você será registrado como capitão. Cadastro completo de membros virá no módulo de equipes.'
                      : 'Inscrição individual vinculada à sua conta.'}
                  </p>
                </div>
                <button className="button button-primary" type="submit" disabled={isSubmitting}>
                  {isSubmitting ? 'Enviando...' : 'Enviar inscrição'}
                </button>
              </form>
            ) : (
              <div className="registration-state">
                {tournament.registration_type === 'team' && user ? (
                  <>
                    <strong>Inscrição por equipe</strong>
                    <p>Crie ou gerencie sua equipe antes de enviar a inscrição do torneio.</p>
                    <a className="button button-primary" href={`#/torneios/${tournament.id}/equipes`}>
                      Abrir equipes
                    </a>
                  </>
                ) : !user ? (
                  <>
                    <strong>Login necessário</strong>
                    <p>Entre com sua conta para solicitar inscrição neste torneio.</p>
                  </>
                ) : (
                  <>
                    <strong>Inscrição indisponível</strong>
                    <p>
                      O torneio precisa estar com inscrições abertas e ter vagas
                      disponíveis.
                    </p>
                  </>
                )}
                {!user ? (
                  <a className="button button-secondary" href="#/login">
                    Entrar
                  </a>
                ) : null}
              </div>
            )}
          </article>
        </section>

        <section className="surface-panel">
          <div className="section-heading">
            <h2>Participantes confirmados</h2>
            <p>{publicParticipants.length} participante(s) visíveis publicamente.</p>
          </div>
          {publicParticipants.length === 0 ? (
            <div className="empty-state compact-empty">
              <span className="empty-state-mark" aria-hidden="true">0</span>
              <h3>Nenhum participante confirmado</h3>
              <p>Inscrições pendentes aparecem somente para o inscrito e para a organização.</p>
            </div>
          ) : (
            <div className="content-grid two-columns">
              {publicParticipants.map((registration) => (
                <article className="participant-card" key={registration.id}>
                  <span className="avatar" aria-hidden="true">
                    {registration.display_name.slice(0, 2).toUpperCase()}
                  </span>
                  <div>
                    <h3>{registration.display_name}</h3>
                    <p>{registrationTypeLabels[registration.registration_type]}</p>
                  </div>
                  <TournamentRegistrationStatusBadge
                    status={getRegistrationDisplayStatus(registration)}
                  />
                </article>
              ))}
            </div>
          )}
        </section>
      </div>
    </AuthenticatedShell>
  )
}
