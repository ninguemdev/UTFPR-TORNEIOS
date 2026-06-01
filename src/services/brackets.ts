import { supabase } from '../lib/supabase/client'
import type {
  BracketMatch,
  BracketSeedingMethod,
  MatchResult,
  MatchResultHistory,
  Tournament,
  TournamentBracket,
  TournamentRegistration,
} from '../lib/supabase/types'
import {
  generateSingleEliminationBracket,
  validateCanGenerateBracket,
  type BracketParticipant,
} from '../lib/tournaments/singleElimination'
import { publicParticipantStatuses } from './tournaments'

export type TournamentBracketWithMatches = {
  bracket: TournamentBracket
  matches: BracketMatch[]
  resultsByMatchId: Record<string, MatchResult>
  participantsById: Record<string, TournamentRegistration>
}

export const bracketSeedingMethodLabels: Record<BracketSeedingMethod, string> = {
  draw: 'Sorteio',
  seeded: 'Seeding',
}

export const bracketMatchStatusLabels: Record<BracketMatch['status'], string> = {
  pending: 'Pendente',
  ready: 'Pronta',
  bye: 'Bye',
  live: 'Ao vivo',
  completed: 'Finalizada',
  disputed: 'Em disputa',
  cancelled: 'Cancelada',
}

export const matchResultStatusLabels: Record<MatchResult['status'], string> = {
  confirmed: 'Confirmado',
  disputed: 'Contestado',
  resolved: 'Resolvido',
  cancelled: 'Cancelado',
}

export const matchResultTypeLabels: Record<MatchResult['result_type'], string> = {
  score: 'Placar',
  walkover: 'W.O.',
}

function getBracketError(message: string) {
  const normalized = message.toLowerCase()

  if (normalized.includes('duplicate') || normalized.includes('unique')) {
    return 'Já existe uma chave gerada para este torneio.'
  }

  if (normalized.includes('permission') || normalized.includes('rls')) {
    return 'Permissão negada pelo banco.'
  }

  if (normalized.includes('seguro corrigir') || normalized.includes('proxima partida')) {
    return 'Nao e seguro corrigir este resultado porque a chave ja avancou. Cancele ou resolva as partidas dependentes antes.'
  }

  if (
    normalized.includes('check-in') ||
    normalized.includes('w.o') ||
    normalized.includes('walkover') ||
    normalized.includes('desclass') ||
    normalized.includes('bloqueada')
  ) {
    return message
  }

  return message
}

export async function fetchBracketParticipants(
  tournament: Pick<Tournament, 'id' | 'registration_type' | 'requires_check_in'>,
) {
  const { data, error } = await supabase
    .from('tournament_registrations')
    .select('*')
    .eq('tournament_id', tournament.id)
    .in('status', publicParticipantStatuses)
    .order('seed', { ascending: true, nullsFirst: false })
    .order('created_at', { ascending: true })

  if (error) throw new Error(getBracketError(error.message))

  return data.filter((registration) => {
    if (registration.disqualified_at || registration.no_show_at) return false

    if (
      tournament.requires_check_in &&
      !registration.checked_in_at &&
      registration.status !== 'checked_in'
    ) {
      return false
    }

    if (tournament.registration_type === 'team') {
      return registration.registration_type === 'team' && registration.team_id !== null
    }

    return registration.registration_type === 'individual'
  })
}

export async function fetchTournamentBracket(tournamentId: string) {
  const { data: bracket, error: bracketError } = await supabase
    .from('tournament_brackets')
    .select('*')
    .eq('tournament_id', tournamentId)
    .maybeSingle()

  if (bracketError) throw new Error(getBracketError(bracketError.message))
  if (!bracket) return null

  const { data: matches, error: matchesError } = await supabase
    .from('bracket_matches')
    .select('*')
    .eq('bracket_id', bracket.id)
    .order('round_number', { ascending: true })
    .order('match_number', { ascending: true })

  if (matchesError) throw new Error(getBracketError(matchesError.message))

  const { data: results, error: resultsError } = await supabase
    .from('match_results')
    .select('*')
    .eq('bracket_id', bracket.id)

  if (resultsError) throw new Error(getBracketError(resultsError.message))

  const { data: participants, error: participantsError } = await supabase
    .from('tournament_registrations')
    .select('*')
    .eq('tournament_id', tournamentId)
    .in('status', publicParticipantStatuses)

  if (participantsError) throw new Error(getBracketError(participantsError.message))

  const participantsById = participants.reduce<Record<string, TournamentRegistration>>(
    (map, participant) => {
      map[participant.id] = participant
      return map
    },
    {},
  )

  return {
    bracket,
    matches,
    resultsByMatchId: results.reduce<Record<string, MatchResult>>((map, result) => {
      map[result.match_id] = result
      return map
    }, {}),
    participantsById,
  } satisfies TournamentBracketWithMatches
}

export async function generateTournamentBracket(params: {
  tournament: Tournament
  userId: string
  seedingMethod: BracketSeedingMethod
  forceRegenerate: boolean
}) {
  const [existing, registrations] = await Promise.all([
    fetchTournamentBracket(params.tournament.id),
    fetchBracketParticipants(params.tournament),
  ])
  const validationError = validateCanGenerateBracket({
    format: params.tournament.format,
    status: params.tournament.status,
    participantCount: registrations.length,
    existingBracket: Boolean(existing),
    forceRegenerate: params.forceRegenerate,
  })

  if (validationError) throw new Error(validationError)

  if (existing && params.forceRegenerate) {
    const { error } = await supabase
      .from('tournament_brackets')
      .delete()
      .eq('id', existing.bracket.id)

    if (error) throw new Error(getBracketError(error.message))
  }

  const participants: BracketParticipant[] = registrations.map((registration) => ({
    id: registration.id,
    displayName: registration.display_name,
    seed: registration.seed,
  }))
  const generated = generateSingleEliminationBracket({
    participants,
    seedingMethod: params.seedingMethod,
  })

  const { data: bracket, error: bracketError } = await supabase
    .from('tournament_brackets')
    .insert({
      tournament_id: params.tournament.id,
      format: 'single_elimination',
      seeding_method: params.seedingMethod,
      size: generated.size,
      rounds_count: generated.roundsCount,
      generated_by: params.userId,
    })
    .select('*')
    .single()

  if (bracketError) throw new Error(getBracketError(bracketError.message))

  const { data: insertedMatches, error: matchesError } = await supabase
    .from('bracket_matches')
    .insert(
      generated.matches.map((match) => ({
        bracket_id: bracket.id,
        tournament_id: params.tournament.id,
        round_number: match.roundNumber,
        match_number: match.matchNumber,
        status: match.status,
        participant_a_registration_id: match.participantAId,
        participant_b_registration_id: match.participantBId,
        winner_registration_id: match.winnerParticipantId,
        is_bye: match.isBye,
      })),
    )
    .select('*')

  if (matchesError) throw new Error(getBracketError(matchesError.message))

  const insertedByKey = insertedMatches.reduce<Record<string, BracketMatch>>((map, match) => {
    map[`${match.round_number}:${match.match_number}`] = match
    return map
  }, {})

  await Promise.all(
    generated.matches
      .filter((match) => match.nextMatchKey && match.nextMatchSlot)
      .map(async (match) => {
        const inserted = insertedByKey[match.temporaryId]
        const nextMatch = insertedByKey[match.nextMatchKey!]

        if (!inserted || !nextMatch) return

        const { error } = await supabase
          .from('bracket_matches')
          .update({
            next_match_id: nextMatch.id,
            next_match_slot: match.nextMatchSlot,
          })
          .eq('id', inserted.id)

        if (error) throw new Error(getBracketError(error.message))
      }),
  )

  return fetchTournamentBracket(params.tournament.id)
}

export async function completeBracketMatch(params: {
  matchId: string
  winnerRegistrationId: string
  scoreA: number
  scoreB: number
  notes: string | null
  changeReason: string | null
}) {
  const { error } = await supabase.rpc('record_bracket_match_result', {
    target_match_id: params.matchId,
    target_winner_registration_id: params.winnerRegistrationId,
    target_score_a: params.scoreA,
    target_score_b: params.scoreB,
    target_notes: params.notes,
    target_change_reason: params.changeReason,
  })

  if (error) throw new Error(getBracketError(error.message))
}

export async function completeBracketMatchByWalkover(params: {
  matchId: string
  winnerRegistrationId: string
  reason: string
}) {
  const { error } = await supabase.rpc('record_bracket_match_walkover', {
    target_match_id: params.matchId,
    target_winner_registration_id: params.winnerRegistrationId,
    target_reason: params.reason,
  })

  if (error) throw new Error(getBracketError(error.message))
}

export async function contestMatchResult(matchId: string, reason: string) {
  const { error } = await supabase.rpc('contest_match_result', {
    target_match_id: matchId,
    target_reason: reason,
  })

  if (error) throw new Error(getBracketError(error.message))
}

export async function resolveMatchDispute(params: {
  matchId: string
  action: 'confirm' | 'cancel'
  notes: string
}) {
  const { error } = await supabase.rpc('resolve_match_dispute', {
    target_match_id: params.matchId,
    target_resolution_action: params.action,
    target_resolution_notes: params.notes,
  })

  if (error) throw new Error(getBracketError(error.message))
}

export async function fetchMatchResultHistory(matchId: string) {
  const { data, error } = await supabase
    .from('match_result_history')
    .select('*')
    .eq('match_id', matchId)
    .order('created_at', { ascending: false })

  if (error) throw new Error(getBracketError(error.message))

  return data satisfies MatchResultHistory[]
}
