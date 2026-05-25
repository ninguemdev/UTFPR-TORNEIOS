import { type FormEvent, useCallback, useEffect, useMemo, useState } from 'react'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import { SupabaseTournamentStatusBadge } from '../../components/tournament/TournamentStatusBadge'
import { useAuth } from '../../context/auth'
import type {
  BracketMatch,
  BracketSeedingMethod,
  MatchResult,
  MatchResultHistory,
  TournamentRegistration,
} from '../../lib/supabase/types'
import {
  validateContestReason,
  validateMatchResult,
} from '../../lib/tournaments/matchResults'
import {
  bracketMatchStatusLabels,
  bracketSeedingMethodLabels,
  completeBracketMatch,
  contestMatchResult,
  fetchBracketParticipants,
  fetchMatchResultHistory,
  fetchTournamentBracket,
  generateTournamentBracket,
  matchResultStatusLabels,
  resolveMatchDispute,
  type TournamentBracketWithMatches,
} from '../../services/brackets'
import {
  canManageTournament,
  fetchTournament,
  type TournamentWithCount,
} from '../../services/tournaments'

type ResultForm = {
  scoreA: string
  scoreB: string
  notes: string
  changeReason: string
  contestReason: string
  resolutionNotes: string
}

type ResultFormByMatch = Record<string, ResultForm>

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value))
}

function getRoundTitle(roundNumber: number, roundsCount: number) {
  if (roundNumber === roundsCount) return 'Final'
  if (roundNumber === roundsCount - 1) return 'Semifinais'
  if (roundNumber === roundsCount - 2) return 'Quartas de final'
  if (roundNumber === roundsCount - 3) return 'Oitavas de final'
  return `Rodada ${roundNumber}`
}

function getParticipantName(
  participantId: string | null,
  participantsById: Record<string, TournamentRegistration>,
  fallback: string,
) {
  if (!participantId) return fallback
  return participantsById[participantId]?.display_name ?? 'Participante removido'
}

function getEmptyResultForm(): ResultForm {
  return {
    scoreA: '',
    scoreB: '',
    notes: '',
    changeReason: '',
    contestReason: '',
    resolutionNotes: '',
  }
}

function isUserParticipantInMatch(
  match: BracketMatch,
  participantsById: Record<string, TournamentRegistration>,
  userId: string | undefined,
) {
  if (!userId) return false

  return [match.participant_a_registration_id, match.participant_b_registration_id]
    .filter(Boolean)
    .some((participantId) => {
      const participant = participantsById[participantId!]
      return participant?.user_id === userId || participant?.captain_user_id === userId
    })
}

export function TournamentBracketPage({ tournamentId }: { tournamentId: string }) {
  const { user, isAdmin, canCreateTournaments } = useAuth()
  const [tournament, setTournament] = useState<TournamentWithCount | null>(null)
  const [bracketData, setBracketData] = useState<TournamentBracketWithMatches | null>(null)
  const [eligibleCount, setEligibleCount] = useState(0)
  const [seedingMethod, setSeedingMethod] = useState<BracketSeedingMethod>('draw')
  const [resultFormsByMatch, setResultFormsByMatch] = useState<ResultFormByMatch>({})
  const [historyByMatch, setHistoryByMatch] = useState<Record<string, MatchResultHistory[]>>({})
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const canManage = tournament
    ? canManageTournament(tournament, user?.id, isAdmin, canCreateTournaments)
    : false

  const matchesByRound = useMemo(() => {
    return (bracketData?.matches ?? []).reduce<Record<number, BracketMatch[]>>(
      (rounds, match) => {
        rounds[match.round_number] = rounds[match.round_number] ?? []
        rounds[match.round_number].push(match)
        return rounds
      },
      {},
    )
  }, [bracketData])

  const disputedMatches = useMemo(
    () => (bracketData?.matches ?? []).filter((match) => match.status === 'disputed'),
    [bracketData],
  )

  const loadBracket = useCallback(async () => {
    setIsLoading(true)
    setError('')

    try {
      const nextTournament = await fetchTournament(tournamentId)
      const [nextBracket, participants] = await Promise.all([
        fetchTournamentBracket(nextTournament.id),
        fetchBracketParticipants(nextTournament),
      ])
      setTournament(nextTournament)
      setBracketData(nextBracket)
      setEligibleCount(participants.length)
      setSeedingMethod(nextBracket?.bracket.seeding_method ?? 'draw')
    } catch (loadError) {
      setTournament(null)
      setBracketData(null)
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Nao foi possivel carregar a chave.',
      )
    } finally {
      setIsLoading(false)
    }
  }, [tournamentId])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadBracket()
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadBracket])

  function updateMatchForm(matchId: string, field: keyof ResultForm, value: string) {
    setResultFormsByMatch((current) => ({
      ...current,
      [matchId]: {
        ...(current[matchId] ?? getEmptyResultForm()),
        [field]: value,
      },
    }))
  }

  async function handleGenerateBracket(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!tournament || !user) return

    const forceRegenerate = Boolean(bracketData)

    if (
      forceRegenerate &&
      !window.confirm(
        'Regerar a chave remove a estrutura atual e altera avancos/resultados ja lancados. Deseja continuar?',
      )
    ) {
      return
    }

    setIsSubmitting('generate')
    setError('')
    setSuccess('')

    try {
      const nextBracket = await generateTournamentBracket({
        tournament,
        userId: user.id,
        seedingMethod,
        forceRegenerate,
      })
      setBracketData(nextBracket)
      await loadBracket()
      setSuccess(forceRegenerate ? 'Chave regerada.' : 'Chave gerada.')
    } catch (generateError) {
      setError(
        generateError instanceof Error
          ? generateError.message
          : 'Nao foi possivel gerar a chave.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  async function handleCompleteMatch(match: BracketMatch) {
    const form = resultFormsByMatch[match.id] ?? getEmptyResultForm()
    const scoreA = form.scoreA.trim() === '' ? null : Number(form.scoreA)
    const scoreB = form.scoreB.trim() === '' ? null : Number(form.scoreB)
    const validation = validateMatchResult({
      format: tournament?.format ?? 'single_elimination',
      status: match.status,
      isBye: match.is_bye,
      participantAId: match.participant_a_registration_id,
      participantBId: match.participant_b_registration_id,
      scoreA,
      scoreB,
      isCorrection: ['completed', 'disputed'].includes(match.status),
      changeReason: form.changeReason,
    })

    if (!validation.valid || scoreA === null || scoreB === null || !validation.winnerRegistrationId) {
      setError(validation.errors[0] ?? 'Resultado invalido.')
      return
    }

    setIsSubmitting(match.id)
    setError('')
    setSuccess('')

    try {
      await completeBracketMatch({
        matchId: match.id,
        winnerRegistrationId: validation.winnerRegistrationId,
        scoreA,
        scoreB,
        notes: form.notes.trim() || null,
        changeReason: form.changeReason.trim() || null,
      })
      await loadBracket()
      setSuccess('Resultado confirmado e vencedor avancado.')
    } catch (completeError) {
      setError(
        completeError instanceof Error
          ? completeError.message
          : 'Nao foi possivel confirmar o resultado.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  async function handleContestMatch(match: BracketMatch) {
    const form = resultFormsByMatch[match.id] ?? getEmptyResultForm()
    const reasonError = validateContestReason(form.contestReason)

    if (reasonError) {
      setError(reasonError)
      return
    }

    setIsSubmitting(`${match.id}:contest`)
    setError('')
    setSuccess('')

    try {
      await contestMatchResult(match.id, form.contestReason.trim())
      await loadBracket()
      setSuccess('Resultado contestado. A organizacao precisa resolver a pendencia.')
    } catch (contestError) {
      setError(
        contestError instanceof Error
          ? contestError.message
          : 'Nao foi possivel contestar o resultado.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  async function handleResolveDispute(match: BracketMatch, action: 'confirm' | 'cancel') {
    const form = resultFormsByMatch[match.id] ?? getEmptyResultForm()

    if (form.resolutionNotes.trim().length < 3) {
      setError('Informe uma observacao para resolver a contestacao.')
      return
    }

    setIsSubmitting(`${match.id}:resolve:${action}`)
    setError('')
    setSuccess('')

    try {
      await resolveMatchDispute({
        matchId: match.id,
        action,
        notes: form.resolutionNotes.trim(),
      })
      await loadBracket()
      setSuccess(action === 'confirm' ? 'Contestacao resolvida.' : 'Resultado cancelado para novo lancamento.')
    } catch (resolveError) {
      setError(
        resolveError instanceof Error
          ? resolveError.message
          : 'Nao foi possivel resolver a contestacao.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  async function handleLoadHistory(matchId: string) {
    if (historyByMatch[matchId]) {
      setHistoryByMatch((current) => {
        const next = { ...current }
        delete next[matchId]
        return next
      })
      return
    }

    setIsSubmitting(`${matchId}:history`)
    setError('')

    try {
      const history = await fetchMatchResultHistory(matchId)
      setHistoryByMatch((current) => ({
        ...current,
        [matchId]: history,
      }))
    } catch (historyError) {
      setError(
        historyError instanceof Error
          ? historyError.message
          : 'Nao foi possivel carregar o historico.',
      )
    } finally {
      setIsSubmitting('')
    }
  }

  if (isLoading) {
    return (
      <AuthenticatedShell subtitle="Chave">
        <div className="loading-state" role="status" aria-live="polite">
          <span className="spinner" aria-hidden="true" />
          <span>Carregando chave...</span>
        </div>
      </AuthenticatedShell>
    )
  }

  if (!tournament) {
    return (
      <AuthenticatedShell subtitle="Chave">
        <section className="empty-state">
          <span className="empty-state-mark" aria-hidden="true">?</span>
          <h1>Torneio nao encontrado</h1>
          <p>{error || 'O torneio nao existe ou voce nao tem permissao para ver esta chave.'}</p>
          <a className="button button-primary" href="#/torneios">
            Ver torneios
          </a>
        </section>
      </AuthenticatedShell>
    )
  }

  return (
    <AuthenticatedShell subtitle="Chave">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="bracket-title">
          <div>
            <span className="eyebrow">Mata-mata simples</span>
            <h1 id="bracket-title">Chave</h1>
            <p>
              Gere e acompanhe rodadas, byes, status de partidas, resultados,
              contestacoes e historico para {tournament.name}.
            </p>
          </div>
          <div className="page-header-action">
            <SupabaseTournamentStatusBadge status={tournament.status} />
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

        <section className="surface-panel">
          <div className="section-heading">
            <h2>Configuracao</h2>
            <p>
              {eligibleCount} participante(s) confirmado(s) entram na geracao.
              O sorteio e salvo no banco apenas no momento da geracao.
            </p>
          </div>

          {canManage ? (
            <form className="toolbar" onSubmit={handleGenerateBracket}>
              <label className="field" htmlFor="bracket-seeding-method">
                <span>Metodo</span>
                <select
                  id="bracket-seeding-method"
                  value={seedingMethod}
                  onChange={(event) =>
                    setSeedingMethod(event.target.value as BracketSeedingMethod)
                  }
                >
                  <option value="draw">Sorteio aleatorio</option>
                  <option value="seeded">Seeding</option>
                </select>
              </label>
              <button
                className="button button-primary"
                type="submit"
                disabled={isSubmitting !== ''}
              >
                {isSubmitting === 'generate'
                  ? 'Gerando...'
                  : bracketData
                    ? 'Regerar chave'
                    : 'Gerar chave'}
              </button>
            </form>
          ) : (
            <p>Somente admin ou organizador autorizado pode gerar ou alterar a chave.</p>
          )}
        </section>

        {!bracketData ? (
          <section className="empty-state">
            <span className="empty-state-mark" aria-hidden="true">0</span>
            <h2>Chave ainda nao gerada</h2>
            <p>
              A chave aparecera aqui depois que a organizacao escolher sorteio
              ou seeding e gerar a estrutura.
            </p>
          </section>
        ) : (
          <>
            <section className="surface-panel">
              <div className="section-heading">
                <h2>Resumo da chave</h2>
                <p>
                  Metodo: {bracketSeedingMethodLabels[bracketData.bracket.seeding_method]}.
                  Tamanho: {bracketData.bracket.size}. Rodadas: {bracketData.bracket.rounds_count}.
                  Gerada em {formatDateTime(bracketData.bracket.generated_at)}.
                </p>
              </div>
              {bracketData.bracket.winner_registration_id && (
                <div className="form-message form-message-success" role="status">
                  Campeao: {getParticipantName(
                    bracketData.bracket.winner_registration_id,
                    bracketData.participantsById,
                    'Campeao definido',
                  )}
                </div>
              )}
            </section>

            {canManage && disputedMatches.length > 0 && (
              <section className="surface-panel">
                <div className="section-heading">
                  <h2>Resultados contestados</h2>
                  <p>{disputedMatches.length} partida(s) exigem resolucao administrativa.</p>
                </div>
                <ul className="compact-list">
                  {disputedMatches.map((match) => (
                    <li key={match.id}>
                      Rodada {match.round_number}, partida {match.match_number}
                    </li>
                  ))}
                </ul>
              </section>
            )}

            <section className="bracket" aria-label="Chave mata-mata">
              {Object.entries(matchesByRound).map(([roundNumber, matches]) => (
                <section
                  className="bracket-round"
                  aria-labelledby={`round-${roundNumber}-title`}
                  key={roundNumber}
                >
                  <h2 id={`round-${roundNumber}-title`}>
                    {getRoundTitle(Number(roundNumber), bracketData.bracket.rounds_count)}
                  </h2>
                  <div className="bracket-round-stack">
                    {matches.map((match) => (
                      <BracketMatchCard
                        key={match.id}
                        match={match}
                        result={bracketData.resultsByMatchId[match.id]}
                        history={historyByMatch[match.id] ?? null}
                        participantsById={bracketData.participantsById}
                        canManage={canManage}
                        canContest={isUserParticipantInMatch(
                          match,
                          bracketData.participantsById,
                          user?.id,
                        )}
                        isSubmitting={isSubmitting === match.id}
                        isContestSubmitting={isSubmitting === `${match.id}:contest`}
                        isHistoryLoading={isSubmitting === `${match.id}:history`}
                        isResolving={isSubmitting.startsWith(`${match.id}:resolve`)}
                        form={resultFormsByMatch[match.id] ?? getEmptyResultForm()}
                        onFormChange={(field, value) => updateMatchForm(match.id, field, value)}
                        onComplete={() => void handleCompleteMatch(match)}
                        onContest={() => void handleContestMatch(match)}
                        onResolve={(action) => void handleResolveDispute(match, action)}
                        onToggleHistory={() => void handleLoadHistory(match.id)}
                      />
                    ))}
                  </div>
                </section>
              ))}
            </section>
          </>
        )}
      </div>
    </AuthenticatedShell>
  )
}

function BracketMatchCard({
  match,
  result,
  history,
  participantsById,
  canManage,
  canContest,
  isSubmitting,
  isContestSubmitting,
  isHistoryLoading,
  isResolving,
  form,
  onFormChange,
  onComplete,
  onContest,
  onResolve,
  onToggleHistory,
}: {
  match: BracketMatch
  result: MatchResult | undefined
  history: MatchResultHistory[] | null
  participantsById: Record<string, TournamentRegistration>
  canManage: boolean
  canContest: boolean
  isSubmitting: boolean
  isContestSubmitting: boolean
  isHistoryLoading: boolean
  isResolving: boolean
  form: ResultForm
  onFormChange: (field: keyof ResultForm, value: string) => void
  onComplete: () => void
  onContest: () => void
  onResolve: (action: 'confirm' | 'cancel') => void
  onToggleHistory: () => void
}) {
  const participantAName = getParticipantName(
    match.participant_a_registration_id,
    participantsById,
    'Aguardando vencedor',
  )
  const participantBName = getParticipantName(
    match.participant_b_registration_id,
    participantsById,
    match.is_bye ? 'BYE' : 'Aguardando vencedor',
  )
  const canComplete =
    canManage &&
    ['ready', 'live', 'completed', 'disputed'].includes(match.status) &&
    Boolean(match.participant_a_registration_id && match.participant_b_registration_id)
  const isCorrection = ['completed', 'disputed'].includes(match.status)
  const showContest = canContest && !canManage && match.status === 'completed' && Boolean(result)
  const showHistoryAction = canManage || canContest

  return (
    <article className="bracket-match">
      <div className="card-topline">
        <span>Partida {match.match_number}</span>
        <span className={`badge badge-match-${match.status}`}>
          {bracketMatchStatusLabels[match.status]}
        </span>
      </div>
      <div className="bracket-slots">
        <BracketSlot
          name={participantAName}
          score={match.score_a}
          isWinner={match.winner_registration_id === match.participant_a_registration_id}
        />
        <BracketSlot
          name={participantBName}
          score={match.score_b}
          isWinner={match.winner_registration_id === match.participant_b_registration_id}
          isBye={match.is_bye && !match.participant_b_registration_id}
        />
      </div>
      {match.is_bye && (
        <p className="subtle-note">Bye registrado. O participante avancou automaticamente.</p>
      )}
      {result && (
        <div className="result-summary">
          <span className={`badge badge-result-${result.status}`}>
            {matchResultStatusLabels[result.status]}
          </span>
          <p>
            Resultado registrado em {formatDateTime(result.submitted_at)}
            {result.notes ? `: ${result.notes}` : '.'}
          </p>
          {result.status === 'disputed' && result.dispute_reason && (
            <p>Contestacao: {result.dispute_reason}</p>
          )}
          {result.resolution_notes && (
            <p>Resolucao: {result.resolution_notes}</p>
          )}
        </div>
      )}
      {canComplete && (
        <form
          className="score-form-grid compact-score-form"
          onSubmit={(event) => {
            event.preventDefault()
            onComplete()
          }}
        >
          <label className="field" htmlFor={`score-a-${match.id}`}>
            <span>Placar A</span>
            <input
              id={`score-a-${match.id}`}
              type="number"
              min="0"
              value={form.scoreA}
              onChange={(event) => onFormChange('scoreA', event.target.value)}
            />
          </label>
          <label className="field" htmlFor={`score-b-${match.id}`}>
            <span>Placar B</span>
            <input
              id={`score-b-${match.id}`}
              type="number"
              min="0"
              value={form.scoreB}
              onChange={(event) => onFormChange('scoreB', event.target.value)}
            />
          </label>
          <label className="field" htmlFor={`result-notes-${match.id}`}>
            <span>Observacoes</span>
            <textarea
              id={`result-notes-${match.id}`}
              rows={2}
              value={form.notes}
              onChange={(event) => onFormChange('notes', event.target.value)}
            />
          </label>
          {isCorrection && (
            <label className="field" htmlFor={`change-reason-${match.id}`}>
              <span>Justificativa da correcao</span>
              <textarea
                id={`change-reason-${match.id}`}
                rows={2}
                value={form.changeReason}
                onChange={(event) => onFormChange('changeReason', event.target.value)}
                required
              />
            </label>
          )}
          <button className="button button-secondary" type="submit" disabled={isSubmitting}>
            {isSubmitting ? 'Confirmando...' : isCorrection ? 'Corrigir resultado' : 'Confirmar vencedor'}
          </button>
        </form>
      )}
      {showContest && (
        <form
          className="contest-form"
          onSubmit={(event) => {
            event.preventDefault()
            onContest()
          }}
        >
          <label className="field" htmlFor={`contest-reason-${match.id}`}>
            <span>Motivo da contestacao</span>
            <textarea
              id={`contest-reason-${match.id}`}
              rows={2}
              value={form.contestReason}
              onChange={(event) => onFormChange('contestReason', event.target.value)}
              required
            />
          </label>
          <button className="button button-ghost" type="submit" disabled={isContestSubmitting}>
            {isContestSubmitting ? 'Contestando...' : 'Contestar resultado'}
          </button>
        </form>
      )}
      {canManage && match.status === 'disputed' && (
        <div className="contest-form">
          <label className="field" htmlFor={`resolution-notes-${match.id}`}>
            <span>Observacao da resolucao</span>
            <textarea
              id={`resolution-notes-${match.id}`}
              rows={2}
              value={form.resolutionNotes}
              onChange={(event) => onFormChange('resolutionNotes', event.target.value)}
            />
          </label>
          <div className="button-row">
            <button
              className="button button-secondary"
              type="button"
              disabled={isResolving}
              onClick={() => onResolve('confirm')}
            >
              {isResolving ? 'Resolvendo...' : 'Manter resultado'}
            </button>
            <button
              className="button button-ghost"
              type="button"
              disabled={isResolving}
              onClick={() => onResolve('cancel')}
            >
              Cancelar resultado
            </button>
          </div>
        </div>
      )}
      {showHistoryAction && (
        <div className="history-panel">
          <button className="button button-ghost" type="button" onClick={onToggleHistory}>
            {isHistoryLoading ? 'Carregando...' : history ? 'Ocultar historico' : 'Ver historico'}
          </button>
          {history && (
            history.length === 0 ? (
              <p className="subtle-note">Nenhuma alteracao registrada.</p>
            ) : (
              <ol className="compact-list">
                {history.map((entry) => (
                  <li key={entry.id}>
                    {formatDateTime(entry.created_at)} - {entry.previous_status ?? 'novo'} para {entry.new_status ?? 'sem status'}
                    {entry.change_reason ? ` - ${entry.change_reason}` : ''}
                  </li>
                ))}
              </ol>
            )
          )}
        </div>
      )}
    </article>
  )
}

function BracketSlot({
  name,
  score,
  isWinner,
  isBye = false,
}: {
  name: string
  score: number | null
  isWinner: boolean
  isBye?: boolean
}) {
  return (
    <div className={isWinner ? 'bracket-slot is-winner' : 'bracket-slot'}>
      <span>{name}</span>
      <strong>{isBye ? 'BYE' : score ?? '-'}</strong>
    </div>
  )
}
