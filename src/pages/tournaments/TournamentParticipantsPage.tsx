import { useCallback, useEffect, useMemo, useState } from 'react'
import { TournamentRegistrationStatusBadge } from '../../components/tournament/TournamentRegistrationStatusBadge'
import { SupabaseTournamentStatusBadge } from '../../components/tournament/TournamentStatusBadge'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import { useAuth } from '../../context/auth'
import type { TournamentRegistration, TournamentRegistrationStatus } from '../../lib/supabase/types'
import {
  canManageTournament,
  closeTournamentCheckIn,
  disqualifyTournamentRegistration,
  fetchTournament,
  fetchTournamentRegistrations,
  getRegistrationDisplayStatus,
  isPublicParticipant,
  isTournamentCheckInOpen,
  openTournamentCheckIn,
  registrationTypeLabels,
  setRegistrationCheckIn,
  tournamentRegistrationStatusLabels,
  updateTournamentRegistrationSeed,
  updateTournamentRegistrationStatus,
  type TournamentWithCount,
} from '../../services/tournaments'

function formatDateTime(value: string | null) {
  if (!value) return 'Não registrado'

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value))
}

function toIsoOrNull(value: string) {
  const normalized = value.trim()
  return normalized ? new Date(normalized).toISOString() : null
}

type ManageAction = Extract<
  TournamentRegistrationStatus,
  'confirmed' | 'rejected' | 'cancelled' | 'checked_in'
>

function canApplyManageAction(
  registration: TournamentRegistration,
  action: ManageAction,
) {
  if (['cancelled', 'rejected'].includes(registration.status)) return false
  if (action === 'confirmed') return registration.status === 'pending'
  if (action === 'rejected') return registration.status === 'pending'
  if (action === 'cancelled') return ['pending', 'confirmed'].includes(registration.status)
  if (action === 'checked_in') return registration.status === 'confirmed'
  return false
}

export function TournamentParticipantsPage({
  tournamentId,
}: {
  tournamentId: string
}) {
  const { user, isAdmin, canCreateTournaments } = useAuth()
  const [tournament, setTournament] = useState<TournamentWithCount | null>(null)
  const [registrations, setRegistrations] = useState<TournamentRegistration[]>([])
  const [notesByRegistration, setNotesByRegistration] = useState<Record<string, string>>({})
  const [seedsByRegistration, setSeedsByRegistration] = useState<Record<string, string>>({})
  const [checkInWindow, setCheckInWindow] = useState({
    opensAt: '',
    closesAt: '',
    requiresCheckIn: false,
  })
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const loadParticipants = useCallback(async () => {
    setIsLoading(true)
    setError('')

    try {
      const nextTournament = await fetchTournament(tournamentId)
      const nextRegistrations = await fetchTournamentRegistrations(nextTournament.id)
      setTournament(nextTournament)
      setRegistrations(nextRegistrations)
      setCheckInWindow({
        opensAt: nextTournament.check_in_opens_at?.slice(0, 16) ?? '',
        closesAt: nextTournament.check_in_closes_at?.slice(0, 16) ?? '',
        requiresCheckIn: nextTournament.requires_check_in,
      })
      setNotesByRegistration(
        nextRegistrations.reduce<Record<string, string>>((notes, registration) => {
          notes[registration.id] = registration.admin_notes ?? ''
          return notes
        }, {}),
      )
      setSeedsByRegistration(
        nextRegistrations.reduce<Record<string, string>>((seeds, registration) => {
          seeds[registration.id] = registration.seed?.toString() ?? ''
          return seeds
        }, {}),
      )
    } catch (loadError) {
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Não foi possível carregar participantes.',
      )
    } finally {
      setIsLoading(false)
    }
  }, [tournamentId])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadParticipants()
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadParticipants])

  const canManage = tournament
    ? canManageTournament(tournament, user?.id, isAdmin, canCreateTournaments)
    : false
  const visibleRegistrations = useMemo(
    () =>
      canManage
        ? registrations
        : registrations.filter(isPublicParticipant),
    [canManage, registrations],
  )

  async function handleRegistrationAction(
    registration: TournamentRegistration,
    status: ManageAction,
  ) {
    setIsSubmitting(`${registration.id}:${status}`)
    setError('')
    setSuccess('')

    try {
      await updateTournamentRegistrationStatus(
        registration.id,
        status,
        notesByRegistration[registration.id]?.trim() || null,
      )
      await loadParticipants()
      setSuccess(`Inscrição marcada como ${tournamentRegistrationStatusLabels[status].toLowerCase()}.`)
    } catch (actionError) {
      setError(
        actionError instanceof Error
          ? actionError.message
          : 'Não foi possível atualizar a inscrição.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  async function handleSeedSave(registration: TournamentRegistration) {
    const rawSeed = seedsByRegistration[registration.id]?.trim() ?? ''
    const nextSeed = rawSeed === '' ? null : Number(rawSeed)

    if (nextSeed !== null && (!Number.isInteger(nextSeed) || nextSeed < 1)) {
      setError('Seed deve ser um número inteiro positivo.')
      return
    }

    setIsSubmitting(`${registration.id}:seed`)
    setError('')
    setSuccess('')

    try {
      await updateTournamentRegistrationSeed(registration.id, nextSeed)
      await loadParticipants()
      setSuccess('Seed atualizado para geração de chave.')
    } catch (seedError) {
      setError(
        seedError instanceof Error
          ? seedError.message
          : 'Não foi possível atualizar o seed.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  async function handleSaveCheckInWindow() {
    if (!tournament) return

    setIsSubmitting('check-in-window')
    setError('')
    setSuccess('')

    try {
      await openTournamentCheckIn({
        tournamentId: tournament.id,
        opensAt: toIsoOrNull(checkInWindow.opensAt),
        closesAt: toIsoOrNull(checkInWindow.closesAt),
        requiresCheckIn: checkInWindow.requiresCheckIn,
      })
      await loadParticipants()
      setSuccess('Janela de check-in atualizada.')
    } catch (checkInError) {
      setError(
        checkInError instanceof Error
          ? checkInError.message
          : 'Nao foi possivel atualizar o check-in.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  async function handleCloseCheckInWindow() {
    if (!tournament) return
    if (!window.confirm('Fechar a janela de check-in agora?')) return

    setIsSubmitting('check-in-close')
    setError('')
    setSuccess('')

    try {
      await closeTournamentCheckIn(tournament.id)
      await loadParticipants()
      setSuccess('Janela de check-in fechada.')
    } catch (checkInError) {
      setError(
        checkInError instanceof Error
          ? checkInError.message
          : 'Nao foi possivel fechar o check-in.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  async function handleManualCheckIn(
    registration: TournamentRegistration,
    isCheckedIn: boolean,
  ) {
    const notes = notesByRegistration[registration.id]?.trim() || null

    if (!isCheckedIn && (!notes || notes.length < 3)) {
      setError('Informe uma justificativa na observacao administrativa para desfazer check-in.')
      return
    }

    if (
      !isCheckedIn &&
      !window.confirm(`Desfazer check-in de ${registration.display_name}?`)
    ) {
      return
    }

    setIsSubmitting(`${registration.id}:check-in:${isCheckedIn ? 'on' : 'off'}`)
    setError('')
    setSuccess('')

    try {
      await setRegistrationCheckIn({
        registrationId: registration.id,
        isCheckedIn,
        notes,
      })
      await loadParticipants()
      setSuccess(isCheckedIn ? 'Check-in marcado.' : 'Check-in desfeito.')
    } catch (checkInError) {
      setError(
        checkInError instanceof Error
          ? checkInError.message
          : 'Nao foi possivel atualizar check-in.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  async function handleDisqualify(registration: TournamentRegistration) {
    const reason = notesByRegistration[registration.id]?.trim() ?? ''

    if (reason.length < 5) {
      setError('Informe uma justificativa administrativa com pelo menos 5 caracteres.')
      return
    }

    if (!window.confirm(`Desclassificar ${registration.display_name}?`)) return

    setIsSubmitting(`${registration.id}:disqualify`)
    setError('')
    setSuccess('')

    try {
      await disqualifyTournamentRegistration(registration.id, reason)
      await loadParticipants()
      setSuccess('Participante desclassificado.')
    } catch (disqualifyError) {
      setError(
        disqualifyError instanceof Error
          ? disqualifyError.message
          : 'Nao foi possivel desclassificar participante.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  return (
    <AuthenticatedShell subtitle="Participantes">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="participants-title">
          <div>
            <span className="eyebrow">Inscrições</span>
            <h1 id="participants-title">Participantes</h1>
            <p>
              Lista de inscritos com histórico de status. Participantes públicos
              mostram apenas inscrições confirmadas; gestores veem o fluxo completo.
            </p>
          </div>
          {tournament && (
            <div className="page-header-action">
              <SupabaseTournamentStatusBadge status={tournament.status} />
            </div>
          )}
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

        {tournament && canManage && (
          <section className="surface-panel" aria-labelledby="check-in-panel-title">
            <div className="section-heading">
              <h2 id="check-in-panel-title">Check-in</h2>
              <p>
                {isTournamentCheckInOpen(tournament)
                  ? 'Janela aberta para participantes confirmarem presenca.'
                  : 'Janela fechada ou ainda nao aberta.'}
                {' '}
                {tournament.requires_check_in
                  ? 'A chave exige check-in.'
                  : 'A chave nao exige check-in.'}
              </p>
            </div>
            <div className="form-grid">
              <label className="field" htmlFor="check-in-opens-at">
                <span>Abertura</span>
                <input
                  id="check-in-opens-at"
                  type="datetime-local"
                  value={checkInWindow.opensAt}
                  onChange={(event) =>
                    setCheckInWindow((current) => ({
                      ...current,
                      opensAt: event.target.value,
                    }))
                  }
                />
              </label>
              <label className="field" htmlFor="check-in-closes-at">
                <span>Fechamento</span>
                <input
                  id="check-in-closes-at"
                  type="datetime-local"
                  value={checkInWindow.closesAt}
                  onChange={(event) =>
                    setCheckInWindow((current) => ({
                      ...current,
                      closesAt: event.target.value,
                    }))
                  }
                />
              </label>
              <label className="field checkbox-field" htmlFor="requires-check-in">
                <input
                  id="requires-check-in"
                  type="checkbox"
                  checked={checkInWindow.requiresCheckIn}
                  onChange={(event) =>
                    setCheckInWindow((current) => ({
                      ...current,
                      requiresCheckIn: event.target.checked,
                    }))
                  }
                />
                <span>Exigir check-in para gerar chave</span>
              </label>
            </div>
            <div className="button-row">
              <button
                className="button button-secondary"
                type="button"
                disabled={isSubmitting !== ''}
                onClick={() => void handleSaveCheckInWindow()}
              >
                {isSubmitting === 'check-in-window' ? 'Salvando...' : 'Salvar janela'}
              </button>
              <button
                className="button button-ghost"
                type="button"
                disabled={isSubmitting !== '' || !tournament.check_in_opens_at}
                onClick={() => void handleCloseCheckInWindow()}
              >
                {isSubmitting === 'check-in-close' ? 'Fechando...' : 'Fechar agora'}
              </button>
            </div>
          </section>
        )}

        {isLoading ? (
          <div className="loading-state" role="status" aria-live="polite">
            <span className="spinner" aria-hidden="true" />
            <span>Carregando participantes...</span>
          </div>
        ) : !tournament ? (
          <section className="empty-state">
            <span className="empty-state-mark" aria-hidden="true">?</span>
            <h2>Torneio não encontrado</h2>
            <p>O torneio não existe ou você não tem permissão para ver inscrições.</p>
            <a className="button button-primary" href="#/torneios">
              Ver torneios
            </a>
          </section>
        ) : visibleRegistrations.length === 0 ? (
          <section className="empty-state">
            <span className="empty-state-mark" aria-hidden="true">0</span>
            <h2>Nenhum participante visível</h2>
            <p>
              Inscrições pendentes aparecem aqui para admin ou organizador do
              torneio. A página pública só mostra confirmados.
            </p>
            <a className="button button-primary" href={`#/torneios/${tournament.id}`}>
              Voltar ao torneio
            </a>
          </section>
        ) : (
          <section className="surface-panel">
            <div className="section-heading">
              <h2>{tournament.name}</h2>
              <p>
                {visibleRegistrations.length} inscrição(ões)
                {canManage ? ' no painel de gestão.' : ' confirmada(s).'}
              </p>
            </div>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th scope="col">Participante</th>
                    <th scope="col">Tipo</th>
                    <th scope="col">Status</th>
                    <th scope="col">Check-in</th>
                    {canManage && <th scope="col">Seed</th>}
                    <th scope="col">Inscrito em</th>
                    {canManage && <th scope="col">Gestão</th>}
                  </tr>
                </thead>
                <tbody>
                  {visibleRegistrations.map((registration) => (
                    <tr key={registration.id}>
                      <th scope="row">
                        <span className="table-title">{registration.display_name}</span>
                        <span className="row-note">{registration.user_id}</span>
                      </th>
                      <td>{registrationTypeLabels[registration.registration_type]}</td>
                      <td>
                        <TournamentRegistrationStatusBadge
                          status={getRegistrationDisplayStatus(registration)}
                        />
                        {registration.disqualification_reason && (
                          <span className="row-note">{registration.disqualification_reason}</span>
                        )}
                        {registration.no_show_reason && (
                          <span className="row-note">{registration.no_show_reason}</span>
                        )}
                      </td>
                      <td>
                        <span className="table-title">
                          {registration.checked_in_at ? 'Confirmado' : 'Pendente'}
                        </span>
                        <span className="row-note">
                          {registration.checked_in_at
                            ? formatDateTime(registration.checked_in_at)
                            : 'Sem presenca confirmada'}
                        </span>
                      </td>
                      {canManage && (
                        <td>
                          <div className="inline-field-action">
                            <label className="field compact-field" htmlFor={`seed-${registration.id}`}>
                              <span>Seed</span>
                              <input
                                id={`seed-${registration.id}`}
                                type="number"
                                min="1"
                                value={seedsByRegistration[registration.id] ?? ''}
                                onChange={(event) =>
                                  setSeedsByRegistration((current) => ({
                                    ...current,
                                    [registration.id]: event.target.value,
                                  }))
                                }
                              />
                            </label>
                            <button
                              className="button button-ghost"
                              type="button"
                              disabled={isSubmitting !== ''}
                              onClick={() => void handleSeedSave(registration)}
                            >
                              {isSubmitting === `${registration.id}:seed`
                                ? 'Salvando...'
                                : 'Salvar'}
                            </button>
                          </div>
                        </td>
                      )}
                      <td>{formatDateTime(registration.created_at)}</td>
                      {canManage && (
                        <td>
                          <div className="registration-admin-actions">
                            <label className="field" htmlFor={`admin-note-${registration.id}`}>
                              <span>Observação administrativa</span>
                              <textarea
                                id={`admin-note-${registration.id}`}
                                rows={2}
                                value={notesByRegistration[registration.id] ?? ''}
                                onChange={(event) =>
                                  setNotesByRegistration((current) => ({
                                    ...current,
                                    [registration.id]: event.target.value,
                                  }))
                                }
                              />
                            </label>
                            <div className="button-row">
                              <button
                                className="button button-secondary"
                                type="button"
                                disabled={
                                  isSubmitting !== '' ||
                                  !canApplyManageAction(registration, 'confirmed')
                                }
                                onClick={() => void handleRegistrationAction(registration, 'confirmed')}
                              >
                                {isSubmitting === `${registration.id}:confirmed`
                                  ? 'Confirmando...'
                                  : 'Confirmar'}
                              </button>
                              <button
                                className="button button-ghost"
                                type="button"
                                disabled={
                                  isSubmitting !== '' ||
                                  !canApplyManageAction(registration, 'rejected')
                                }
                                onClick={() => void handleRegistrationAction(registration, 'rejected')}
                              >
                                {isSubmitting === `${registration.id}:rejected`
                                  ? 'Rejeitando...'
                                  : 'Rejeitar'}
                              </button>
                              <button
                                className="button button-ghost"
                                type="button"
                                disabled={
                                  isSubmitting !== '' ||
                                  !canApplyManageAction(registration, 'cancelled')
                                }
                                onClick={() => void handleRegistrationAction(registration, 'cancelled')}
                              >
                                {isSubmitting === `${registration.id}:cancelled`
                                  ? 'Cancelando...'
                                  : 'Cancelar'}
                              </button>
                            </div>
                            <div className="button-row">
                              <button
                                className="button button-secondary"
                                type="button"
                                disabled={
                                  isSubmitting !== '' ||
                                  Boolean(registration.checked_in_at) ||
                                  Boolean(registration.disqualified_at) ||
                                  !['confirmed', 'checked_in'].includes(registration.status)
                                }
                                onClick={() => void handleManualCheckIn(registration, true)}
                              >
                                {isSubmitting === `${registration.id}:check-in:on`
                                  ? 'Marcando...'
                                  : 'Marcar check-in'}
                              </button>
                              <button
                                className="button button-ghost"
                                type="button"
                                disabled={
                                  isSubmitting !== '' ||
                                  !registration.checked_in_at ||
                                  Boolean(registration.disqualified_at)
                                }
                                onClick={() => void handleManualCheckIn(registration, false)}
                              >
                                {isSubmitting === `${registration.id}:check-in:off`
                                  ? 'Desfazendo...'
                                  : 'Desfazer check-in'}
                              </button>
                              <button
                                className="button button-ghost"
                                type="button"
                                disabled={
                                  isSubmitting !== '' ||
                                  Boolean(registration.disqualified_at) ||
                                  ['cancelled', 'rejected'].includes(registration.status)
                                }
                                onClick={() => void handleDisqualify(registration)}
                              >
                                {isSubmitting === `${registration.id}:disqualify`
                                  ? 'Desclassificando...'
                                  : 'Desclassificar'}
                              </button>
                            </div>
                          </div>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        )}
      </div>
    </AuthenticatedShell>
  )
}
