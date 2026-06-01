export type RankingScoringConfig = {
  winPoints: number
  drawPoints: number
  lossPoints: number
}

export type RankingParticipant = {
  id: string
  displayName: string
  seed?: number | null
}

export type RankingMatch = {
  id: string
  participantAId: string | null
  participantBId: string | null
  scoreA: number | null
  scoreB: number | null
  status: string
  resultStatus?: string | null
  resultType?: string | null
  winnerRegistrationId?: string | null
  groupId?: string | null
}

export type RankingEntry = {
  position: number
  participantId: string
  displayName: string
  seed: number | null
  played: number
  wins: number
  draws: number
  losses: number
  scoreFor: number
  scoreAgainst: number
  scoreDiff: number
  points: number
  tieBreakerSummary: string
  isTechnicalTie: boolean
}

export type RankingResult = {
  entries: RankingEntry[]
  scoring: RankingScoringConfig
  criteria: string[]
  criteriaSummary: string
  countedMatchesCount: number
  ignoredMatchesCount: number
  hasTechnicalTies: boolean
}

export const DEFAULT_RANKING_SCORING: RankingScoringConfig = {
  winPoints: 3,
  drawPoints: 1,
  lossPoints: 0,
}

export const DEFAULT_RANKING_CRITERIA = [
  'Pontos',
  'Vitorias',
  'Saldo de score',
  'Score pro',
  'Confronto direto quando ha exatamente dois empatados',
  'Seed e nome como fallback estavel',
]

const DEFAULT_TIE_BREAKER_SUMMARY =
  'Criterios: pontos, vitorias, saldo, score pro, confronto direto quando aplicavel e fallback por seed/nome. W.O. conta como vitoria/derrota sem saldo de score.'

type MutableRankingStats = Omit<
  RankingEntry,
  'position' | 'tieBreakerSummary' | 'isTechnicalTie'
>

export function isRankingMatchCountable(match: RankingMatch) {
  if (match.status !== 'completed') return false
  if (match.resultStatus && ['disputed', 'cancelled'].includes(match.resultStatus)) {
    return false
  }
  if (!match.participantAId || !match.participantBId) return false
  if (match.resultType === 'walkover') {
    return (
      match.winnerRegistrationId === match.participantAId ||
      match.winnerRegistrationId === match.participantBId
    )
  }
  if (match.scoreA === null || match.scoreB === null) return false
  if (!Number.isFinite(match.scoreA) || !Number.isFinite(match.scoreB)) return false
  if (match.scoreA < 0 || match.scoreB < 0) return false

  return true
}

export function calculateRanking(params: {
  participants: RankingParticipant[]
  matches: RankingMatch[]
  scoring?: Partial<RankingScoringConfig>
  groupId?: string | null
}): RankingResult {
  const scoring = {
    ...DEFAULT_RANKING_SCORING,
    ...params.scoring,
  }
  const participantsById = new Map(params.participants.map((participant) => [participant.id, participant]))
  const statsByParticipant = new Map<string, MutableRankingStats>()

  for (const participant of params.participants) {
    statsByParticipant.set(participant.id, {
      participantId: participant.id,
      displayName: participant.displayName,
      seed: participant.seed ?? null,
      played: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      scoreFor: 0,
      scoreAgainst: 0,
      scoreDiff: 0,
      points: 0,
    })
  }

  const scopedMatches = params.groupId
    ? params.matches.filter((match) => match.groupId === params.groupId)
    : params.matches
  const countedMatches = scopedMatches.filter(isRankingMatchCountable)

  for (const match of countedMatches) {
    const participantA = statsByParticipant.get(match.participantAId!)
    const participantB = statsByParticipant.get(match.participantBId!)

    if (!participantA || !participantB) {
      continue
    }

    if (match.resultType === 'walkover') {
      applyWalkoverStats(
        participantA,
        participantB,
        match.winnerRegistrationId,
        match.participantAId!,
        match.participantBId!,
        scoring,
      )
      continue
    }

    if (match.scoreA === null || match.scoreB === null) {
      continue
    }

    applyMatchStats(participantA, match.scoreA, match.scoreB, scoring)
    applyMatchStats(participantB, match.scoreB, match.scoreA, scoring)
  }

  const entries = Array.from(statsByParticipant.values()).map((entry) => ({
    ...entry,
    scoreDiff: entry.scoreFor - entry.scoreAgainst,
    position: 0,
    tieBreakerSummary: DEFAULT_TIE_BREAKER_SUMMARY,
    isTechnicalTie: false,
  }))

  const sorted = entries.sort((a, b) =>
    compareRankingEntries(a, b, countedMatches, participantsById),
  )
  const withTies = markPositionsAndTechnicalTies(sorted, countedMatches)

  return {
    entries: withTies,
    scoring,
    criteria: DEFAULT_RANKING_CRITERIA,
    criteriaSummary: DEFAULT_TIE_BREAKER_SUMMARY,
    countedMatchesCount: countedMatches.length,
    ignoredMatchesCount: scopedMatches.length - countedMatches.length,
    hasTechnicalTies: withTies.some((entry) => entry.isTechnicalTie),
  }
}

export function compareRankingEntries(
  first: RankingEntry,
  second: RankingEntry,
  matches: RankingMatch[] = [],
  participantsById: Map<string, RankingParticipant> = new Map(),
) {
  const byMainCriteria = compareMainCriteria(first, second)
  if (byMainCriteria !== 0) return byMainCriteria

  const headToHead = compareHeadToHead(first.participantId, second.participantId, matches)
  if (headToHead !== 0) return headToHead

  const seedComparison = compareSeeds(first.seed, second.seed)
  if (seedComparison !== 0) return seedComparison

  const firstName = participantsById.get(first.participantId)?.displayName ?? first.displayName
  const secondName = participantsById.get(second.participantId)?.displayName ?? second.displayName
  const byName = firstName.localeCompare(secondName, 'pt-BR', { sensitivity: 'base' })
  if (byName !== 0) return byName

  return first.participantId.localeCompare(second.participantId)
}

function applyMatchStats(
  entry: MutableRankingStats,
  ownScore: number,
  opponentScore: number,
  scoring: RankingScoringConfig,
) {
  entry.played += 1
  entry.scoreFor += ownScore
  entry.scoreAgainst += opponentScore

  if (ownScore > opponentScore) {
    entry.wins += 1
    entry.points += scoring.winPoints
    return
  }

  if (ownScore < opponentScore) {
    entry.losses += 1
    entry.points += scoring.lossPoints
    return
  }

  entry.draws += 1
  entry.points += scoring.drawPoints
}

function applyWalkoverStats(
  participantA: MutableRankingStats,
  participantB: MutableRankingStats,
  winnerRegistrationId: string | null | undefined,
  participantAId: string,
  participantBId: string,
  scoring: RankingScoringConfig,
) {
  participantA.played += 1
  participantB.played += 1

  if (winnerRegistrationId === participantAId) {
    participantA.wins += 1
    participantA.points += scoring.winPoints
    participantB.losses += 1
    participantB.points += scoring.lossPoints
    return
  }

  if (winnerRegistrationId === participantBId) {
    participantB.wins += 1
    participantB.points += scoring.winPoints
    participantA.losses += 1
    participantA.points += scoring.lossPoints
  }
}

function compareMainCriteria(first: RankingEntry, second: RankingEntry) {
  return (
    second.points - first.points ||
    second.wins - first.wins ||
    second.scoreDiff - first.scoreDiff ||
    second.scoreFor - first.scoreFor
  )
}

function compareHeadToHead(firstId: string, secondId: string, matches: RankingMatch[]) {
  const directMatches = matches.filter((match) => {
    const ids = [match.participantAId, match.participantBId]
    return ids.includes(firstId) && ids.includes(secondId)
  })

  if (directMatches.length === 0) return 0

  const first: MutableRankingStats = createEmptyStats(firstId)
  const second: MutableRankingStats = createEmptyStats(secondId)

  for (const match of directMatches) {
    if (!isRankingMatchCountable(match)) {
      continue
    }

    if (match.resultType === 'walkover') {
      applyWalkoverStats(
        first,
        second,
        match.winnerRegistrationId,
        firstId,
        secondId,
        DEFAULT_RANKING_SCORING,
      )
    } else if (match.scoreA !== null && match.scoreB !== null && match.participantAId === firstId) {
      applyMatchStats(first, match.scoreA, match.scoreB, DEFAULT_RANKING_SCORING)
      applyMatchStats(second, match.scoreB, match.scoreA, DEFAULT_RANKING_SCORING)
    } else if (match.scoreA !== null && match.scoreB !== null) {
      applyMatchStats(first, match.scoreB, match.scoreA, DEFAULT_RANKING_SCORING)
      applyMatchStats(second, match.scoreA, match.scoreB, DEFAULT_RANKING_SCORING)
    }
  }

  first.scoreDiff = first.scoreFor - first.scoreAgainst
  second.scoreDiff = second.scoreFor - second.scoreAgainst

  return (
    second.points - first.points ||
    second.scoreDiff - first.scoreDiff ||
    second.scoreFor - first.scoreFor
  )
}

function createEmptyStats(participantId: string): MutableRankingStats {
  return {
    participantId,
    displayName: participantId,
    seed: null,
    played: 0,
    wins: 0,
    draws: 0,
    losses: 0,
    scoreFor: 0,
    scoreAgainst: 0,
    scoreDiff: 0,
    points: 0,
  }
}

function compareSeeds(firstSeed: number | null, secondSeed: number | null) {
  if (firstSeed === null && secondSeed === null) return 0
  if (firstSeed === null) return 1
  if (secondSeed === null) return -1
  return firstSeed - secondSeed
}

function markPositionsAndTechnicalTies(
  entries: RankingEntry[],
  matches: RankingMatch[],
) {
  const positioned: RankingEntry[] = []

  entries.forEach((entry, index, allEntries) => {
    const previous = positioned[index - 1]
    const next = allEntries[index + 1]
    const tiedWithPrevious = previous ? isTechnicalTie(entry, previous, matches) : false
    const tiedWithNext = next ? isTechnicalTie(entry, next, matches) : false
    const isTied = tiedWithPrevious || tiedWithNext

    positioned.push({
      ...entry,
      position: tiedWithPrevious ? previous.position : index + 1,
      isTechnicalTie: isTied,
      tieBreakerSummary: isTied
        ? 'Empate tecnico nos criterios principais; seed/nome aparece apenas como fallback visual estavel.'
        : DEFAULT_TIE_BREAKER_SUMMARY,
    })
  })

  return positioned
}

function isTechnicalTie(first: RankingEntry, second: RankingEntry, matches: RankingMatch[]) {
  return (
    compareMainCriteria(first, second) === 0 &&
    compareHeadToHead(first.participantId, second.participantId, matches) === 0
  )
}
