import type { BracketMatchStatus } from '../supabase/types'

export type MatchResultFormat =
  | 'single_elimination'
  | 'best_of_3'
  | 'best_of_5'
  | 'best_of_7'
  | 'round_robin'
  | 'groups'

export type ResultParticipantSide = 'a' | 'b'

export type MatchResultInput = {
  format: MatchResultFormat | string
  status: BracketMatchStatus
  isBye: boolean
  participantAId: string | null
  participantBId: string | null
  scoreA: number | null
  scoreB: number | null
  winnerRegistrationId?: string | null
  isCorrection?: boolean
  changeReason?: string
}

export type MatchResultValidation = {
  valid: boolean
  winnerRegistrationId: string | null
  errors: string[]
}

export function isDrawAllowed(format: MatchResultFormat | string) {
  return !['single_elimination', 'best_of_3', 'best_of_5', 'best_of_7'].includes(format)
}

export function canMatchReceiveResult(params: {
  status: BracketMatchStatus
  isBye: boolean
  participantAId: string | null
  participantBId: string | null
  isCorrection?: boolean
}) {
  if (params.isBye || params.status === 'bye') {
    return 'Partida com bye nao recebe resultado manual.'
  }

  if (!params.participantAId || !params.participantBId) {
    return 'A partida ainda nao possui dois participantes.'
  }

  if (params.isCorrection) {
    if (!['completed', 'disputed'].includes(params.status)) {
      return 'Somente resultado finalizado ou contestado pode ser corrigido.'
    }

    return null
  }

  if (!['ready', 'live'].includes(params.status)) {
    return 'Somente partidas prontas ou ao vivo podem receber resultado.'
  }

  return null
}

export function determineWinner(params: {
  format: MatchResultFormat | string
  participantAId: string | null
  participantBId: string | null
  scoreA: number
  scoreB: number
}) {
  if (params.scoreA === params.scoreB) {
    return null
  }

  return params.scoreA > params.scoreB ? params.participantAId : params.participantBId
}

export function validateMatchResult(input: MatchResultInput): MatchResultValidation {
  const errors: string[] = []
  const receiveError = canMatchReceiveResult({
    status: input.status,
    isBye: input.isBye,
    participantAId: input.participantAId,
    participantBId: input.participantBId,
    isCorrection: input.isCorrection,
  })

  if (receiveError) errors.push(receiveError)

  if (
    input.scoreA === null ||
    input.scoreB === null ||
    !Number.isInteger(input.scoreA) ||
    !Number.isInteger(input.scoreB)
  ) {
    errors.push('Informe placares inteiros.')
  }

  if (
    typeof input.scoreA === 'number' &&
    typeof input.scoreB === 'number' &&
    (input.scoreA < 0 || input.scoreB < 0)
  ) {
    errors.push('Placar nao pode ser negativo.')
  }

  if (
    typeof input.scoreA === 'number' &&
    typeof input.scoreB === 'number' &&
    input.scoreA === input.scoreB &&
    !isDrawAllowed(input.format)
  ) {
    errors.push('Mata-mata simples nao permite empate.')
  }

  const winnerRegistrationId =
    typeof input.scoreA === 'number' && typeof input.scoreB === 'number'
      ? determineWinner({
          format: input.format,
          participantAId: input.participantAId,
          participantBId: input.participantBId,
          scoreA: input.scoreA,
          scoreB: input.scoreB,
        })
      : null

  const selectedWinner = input.winnerRegistrationId ?? winnerRegistrationId

  if (
    selectedWinner &&
    selectedWinner !== input.participantAId &&
    selectedWinner !== input.participantBId
  ) {
    errors.push('Vencedor precisa ser um dos participantes da partida.')
  }

  if (!selectedWinner && !isDrawAllowed(input.format)) {
    errors.push('Resultado de mata-mata precisa ter vencedor.')
  }

  if (
    input.isCorrection &&
    (!input.changeReason || input.changeReason.trim().length < 3)
  ) {
    errors.push('Informe uma justificativa para corrigir resultado finalizado.')
  }

  return {
    valid: errors.length === 0,
    winnerRegistrationId: selectedWinner,
    errors,
  }
}

export function validateContestReason(reason: string) {
  const normalized = reason.trim()

  if (normalized.length < 5) {
    return 'Explique a contestacao com pelo menos 5 caracteres.'
  }

  return null
}
