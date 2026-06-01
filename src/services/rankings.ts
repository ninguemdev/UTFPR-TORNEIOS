import { supabase } from '../lib/supabase/client'
import type {
  BracketMatch,
  MatchResult,
  Tournament,
  TournamentRegistration,
} from '../lib/supabase/types'
import {
  calculateRanking,
  DEFAULT_RANKING_SCORING,
  type RankingMatch,
  type RankingResult,
} from '../lib/tournaments/ranking'
import { fetchBracketParticipants } from './brackets'
import { fetchTournament } from './tournaments'

export type TournamentRankingData = {
  tournament: Tournament & { registrationCount: number }
  participants: TournamentRegistration[]
  matches: RankingMatch[]
  ranking: RankingResult
  isSupportedFormat: boolean
  unsupportedReason: string | null
}

export const rankingSupportedFormats = new Set([
  'round_robin',
  'groups',
  'groups_playoffs',
])

function getRankingError(message: string) {
  const normalized = message.toLowerCase()

  if (normalized.includes('permission') || normalized.includes('rls')) {
    return 'Permissao negada pelo banco.'
  }

  return message
}

export function isRankingFormatSupported(format: string) {
  return rankingSupportedFormats.has(format)
}

export function getRankingUnsupportedReason(tournament: Pick<Tournament, 'format'>) {
  if (isRankingFormatSupported(tournament.format)) return null

  if (tournament.format === 'single_elimination') {
    return 'Mata-mata simples nao possui ranking completo no MVP. Campeao e finalistas serao tratados em etapa propria.'
  }

  return 'Este formato ainda nao possui partidas de tabela para calculo de ranking no MVP.'
}

export async function fetchTournamentRanking(tournamentId: string) {
  const tournament = await fetchTournament(tournamentId)
  const participants = await fetchBracketParticipants(tournament)
  const isSupportedFormat = isRankingFormatSupported(tournament.format)
  const matches = isSupportedFormat
    ? await fetchRankingMatches(tournament.id)
    : []

  const ranking = calculateRanking({
    participants: participants.map((participant) => ({
      id: participant.id,
      displayName: participant.display_name,
      seed: participant.seed,
    })),
    matches,
    scoring: DEFAULT_RANKING_SCORING,
  })

  return {
    tournament,
    participants,
    matches,
    ranking,
    isSupportedFormat,
    unsupportedReason: getRankingUnsupportedReason(tournament),
  } satisfies TournamentRankingData
}

async function fetchRankingMatches(tournamentId: string) {
  const { data: matches, error: matchesError } = await supabase
    .from('bracket_matches')
    .select('*')
    .eq('tournament_id', tournamentId)
    .order('round_number', { ascending: true })
    .order('match_number', { ascending: true })

  if (matchesError) throw new Error(getRankingError(matchesError.message))

  if (matches.length === 0) return []

  const { data: results, error: resultsError } = await supabase
    .from('match_results')
    .select('*')
    .eq('tournament_id', tournamentId)

  if (resultsError) throw new Error(getRankingError(resultsError.message))

  return mapRankingMatches(matches, results)
}

function mapRankingMatches(matches: BracketMatch[], results: MatchResult[]) {
  const resultsByMatchId = new Map(results.map((result) => [result.match_id, result]))

  return matches.map<RankingMatch>((match) => {
    const result = resultsByMatchId.get(match.id)

    return {
      id: match.id,
      participantAId: match.participant_a_registration_id,
      participantBId: match.participant_b_registration_id,
      scoreA: match.score_a,
      scoreB: match.score_b,
      status: match.status,
      resultStatus: result?.status ?? null,
      resultType: result?.result_type ?? match.result_type ?? 'score',
      winnerRegistrationId: result?.winner_registration_id ?? match.winner_registration_id,
      groupId: null,
    }
  })
}
