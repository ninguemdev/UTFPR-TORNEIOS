import { supabase } from '../lib/supabase/client'
import type {
  RegistrationType,
  Tournament,
  TournamentRegistration,
  TournamentRegistrationStatus,
  TournamentStatus,
} from '../lib/supabase/types'

export type TournamentWithCount = Tournament & {
  registrationCount: number
}

export type TournamentFormValues = {
  name: string
  modality: string
  description: string | null
  campus: string | null
  format: string
  status: TournamentStatus
  max_participants: number
  registration_type: RegistrationType
  team_min_size: number
  team_max_size: number
  allow_free_agents: boolean
  require_full_team_before_registration: boolean
  team_registration_deadline: string | null
  requires_check_in: boolean
  check_in_opens_at: string | null
  check_in_closes_at: string | null
  starts_at: string | null
  ends_at: string | null
}

export type MyTournamentRegistration = TournamentRegistration & {
  tournament: Tournament | null
}

export const tournamentStatusLabels: Record<TournamentStatus, string> = {
  draft: 'Rascunho',
  registrations_open: 'Inscrições abertas',
  registrations_closed: 'Inscrições encerradas',
  ongoing: 'Em andamento',
  finished: 'Finalizado',
  cancelled: 'Cancelado',
}

export const tournamentFormatLabels: Record<string, string> = {
  single_elimination: 'Mata-mata simples',
  round_robin: 'Pontos corridos',
  groups_playoffs: 'Grupos + playoffs',
  swiss: 'Sistema suíço',
}

export const registrationTypeLabels: Record<RegistrationType, string> = {
  individual: 'Individual',
  team: 'Equipe',
}

export const tournamentRegistrationStatusLabels: Record<
  TournamentRegistrationStatus,
  string
> = {
  pending: 'Pendente',
  confirmed: 'Confirmada',
  cancelled: 'Cancelada',
  rejected: 'Rejeitada',
  checked_in: 'Check-in feito',
  registered: 'Confirmada',
}

export type TournamentRegistrationDisplayStatus =
  | TournamentRegistrationStatus
  | 'no_show'
  | 'disqualified'

export const tournamentRegistrationDisplayStatusLabels: Record<
  TournamentRegistrationDisplayStatus,
  string
> = {
  ...tournamentRegistrationStatusLabels,
  no_show: 'W.O.',
  disqualified: 'Desclassificada',
}

export const activeRegistrationStatuses: TournamentRegistrationStatus[] = [
  'pending',
  'confirmed',
  'checked_in',
  'registered',
]

export const publicParticipantStatuses: TournamentRegistrationStatus[] = [
  'confirmed',
  'checked_in',
  'registered',
]

export function getRegistrationDisplayStatus(
  registration: Pick<
    TournamentRegistration,
    'status' | 'no_show_at' | 'disqualified_at'
  >,
): TournamentRegistrationDisplayStatus {
  if (registration.disqualified_at) return 'disqualified'
  if (registration.no_show_at) return 'no_show'
  return registration.status
}

export function isRegistrationOperationallyActive(
  registration: Pick<
    TournamentRegistration,
    'status' | 'no_show_at' | 'disqualified_at'
  >,
) {
  return (
    activeRegistrationStatuses.includes(registration.status) &&
    !registration.disqualified_at &&
    !registration.no_show_at
  )
}

export function isPublicParticipant(
  registration: Pick<
    TournamentRegistration,
    'status' | 'no_show_at' | 'disqualified_at'
  >,
) {
  return (
    publicParticipantStatuses.includes(registration.status) &&
    !registration.disqualified_at
  )
}

export function isTournamentCheckInOpen(
  tournament: Pick<Tournament, 'check_in_opens_at' | 'check_in_closes_at'>,
  now = new Date(),
) {
  if (!tournament.check_in_opens_at) return false

  const opensAt = new Date(tournament.check_in_opens_at)
  const closesAt = tournament.check_in_closes_at
    ? new Date(tournament.check_in_closes_at)
    : null

  return opensAt <= now && (!closesAt || closesAt > now)
}

function getTournamentError(message: string) {
  const normalized = message.toLowerCase()

  if (normalized.includes('duplicate') || normalized.includes('unique')) {
    return 'Já existe um registro parecido. Revise os dados e tente novamente.'
  }

  if (normalized.includes('registrations_open') || normalized.includes('inscrições')) {
    return 'Inscrições só são permitidas quando o torneio está com inscrições abertas.'
  }

  if (normalized.includes('limite') || normalized.includes('participantes')) {
    return 'O torneio atingiu o limite de participantes.'
  }

  if (
    normalized.includes('check-in') ||
    normalized.includes('bloqueada') ||
    normalized.includes('desclass') ||
    normalized.includes('w.o')
  ) {
    return message
  }

  if (normalized.includes('permission') || normalized.includes('rls')) {
    return 'Permissão negada pelo banco.'
  }

  return message
}

export function isPublicTournamentStatus(status: TournamentStatus) {
  return status !== 'draft'
}

export function canManageTournament(
  tournament: Pick<Tournament, 'created_by'>,
  userId: string | undefined,
  isAdmin: boolean,
  canCreateTournaments = false,
) {
  return isAdmin || Boolean(canCreateTournaments && userId && tournament.created_by === userId)
}

export function canDeleteTournament(isAdmin: boolean) {
  return isAdmin
}

export function slugifyTournamentName(name: string) {
  const normalized = name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')

  return normalized || 'torneio'
}

function buildTournamentSlug(name: string) {
  return `${slugifyTournamentName(name)}-${crypto.randomUUID().slice(0, 8)}`
}

async function countRegistrations(tournaments: Tournament[]) {
  const ids = tournaments.map((tournament) => tournament.id)

  if (ids.length === 0) return new Map<string, number>()

  const { data, error } = await supabase
    .from('tournament_registrations')
    .select('tournament_id, status, no_show_at, disqualified_at')
    .in('tournament_id', ids)
    .in('status', activeRegistrationStatuses)

  if (error) throw new Error(getTournamentError(error.message))

  return data.reduce((counts, registration) => {
    if (!isRegistrationOperationallyActive(registration)) return counts

    counts.set(
      registration.tournament_id,
      (counts.get(registration.tournament_id) ?? 0) + 1,
    )
    return counts
  }, new Map<string, number>())
}

export async function fetchTournaments() {
  const { data, error } = await supabase
    .from('tournaments')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) throw new Error(getTournamentError(error.message))

  const counts = await countRegistrations(data)

  return data.map<TournamentWithCount>((tournament) => ({
    ...tournament,
    registrationCount: counts.get(tournament.id) ?? 0,
  }))
}

export async function fetchTournament(tournamentId: string) {
  const { data, error } = await supabase
    .from('tournaments')
    .select('*')
    .eq('id', tournamentId)
    .single()

  if (error) throw new Error(getTournamentError(error.message))

  const counts = await countRegistrations([data])

  return {
    ...data,
    registrationCount: counts.get(data.id) ?? 0,
  } satisfies TournamentWithCount
}

export async function createTournament(
  values: TournamentFormValues,
  userId: string,
) {
  const { data, error } = await supabase
    .from('tournaments')
    .insert({
      ...values,
      slug: buildTournamentSlug(values.name),
      created_by: userId,
    })
    .select('*')
    .single()

  if (error) throw new Error(getTournamentError(error.message))

  return data
}

export async function updateTournament(
  tournamentId: string,
  values: TournamentFormValues,
) {
  const { data, error } = await supabase
    .from('tournaments')
    .update(values)
    .eq('id', tournamentId)
    .select('*')
    .single()

  if (error) throw new Error(getTournamentError(error.message))

  return data
}

export async function deleteTournament(tournamentId: string) {
  const { error } = await supabase
    .from('tournaments')
    .delete()
    .eq('id', tournamentId)

  if (error) throw new Error(getTournamentError(error.message))
}

export async function fetchTournamentRegistrations(tournamentId: string) {
  const { data, error } = await supabase
    .from('tournament_registrations')
    .select('*')
    .eq('tournament_id', tournamentId)
    .order('created_at', { ascending: true })

  if (error) throw new Error(getTournamentError(error.message))

  return data
}

export async function fetchMyTournamentRegistrations(userId: string) {
  const { data, error } = await supabase
    .from('tournament_registrations')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })

  if (error) throw new Error(getTournamentError(error.message))

  const tournamentIds = [...new Set(data.map((registration) => registration.tournament_id))]

  if (tournamentIds.length === 0) return []

  const { data: tournaments, error: tournamentsError } = await supabase
    .from('tournaments')
    .select('*')
    .in('id', tournamentIds)

  if (tournamentsError) throw new Error(getTournamentError(tournamentsError.message))

  const tournamentsById = new Map(
    tournaments.map((tournament) => [tournament.id, tournament]),
  )

  return data.map<MyTournamentRegistration>((registration) => ({
    ...registration,
    tournament: tournamentsById.get(registration.tournament_id) ?? null,
  }))
}

export function findActiveRegistration(
  registrations: TournamentRegistration[],
  userId: string | undefined,
) {
  return registrations.find(
    (registration) =>
      registration.user_id === userId &&
      activeRegistrationStatuses.includes(registration.status),
  )
}

export function canUserCancelRegistration(
  tournament: Pick<Tournament, 'status'>,
  registration: Pick<
    TournamentRegistration,
    'status' | 'disqualified_at' | 'no_show_at'
  >,
) {
  return (
    !registration.disqualified_at &&
    !registration.no_show_at &&
    ['registrations_open', 'registrations_closed'].includes(tournament.status) &&
    ['pending', 'confirmed', 'registered'].includes(registration.status)
  )
}

export async function registerForTournament(
  tournamentId: string,
  userId: string,
  displayName: string,
  registrationType: RegistrationType,
) {
  const { data, error } = await supabase
    .from('tournament_registrations')
    .insert({
      tournament_id: tournamentId,
      user_id: userId,
      display_name: displayName,
      status: 'pending',
      registration_type: registrationType,
      captain_user_id: null,
      team_id: null,
    })
    .select('*')
    .single()

  if (error) throw new Error(getTournamentError(error.message))

  return data
}

export async function updateTournamentRegistrationStatus(
  registrationId: string,
  status: Extract<
    TournamentRegistrationStatus,
    'confirmed' | 'rejected' | 'cancelled' | 'checked_in'
  >,
  adminNotes: string | null,
) {
  const { data, error } = await supabase
    .from('tournament_registrations')
    .update({
      status,
      admin_notes: adminNotes,
    })
    .eq('id', registrationId)
    .select('*')
    .single()

  if (error) throw new Error(getTournamentError(error.message))

  return data
}

export async function updateTournamentRegistrationSeed(
  registrationId: string,
  seed: number | null,
) {
  const { data, error } = await supabase
    .from('tournament_registrations')
    .update({ seed })
    .eq('id', registrationId)
    .select('*')
    .single()

  if (error) throw new Error(getTournamentError(error.message))

  return data
}

export async function cancelTournamentRegistration(registrationId: string) {
  const { data, error } = await supabase
    .from('tournament_registrations')
    .update({ status: 'cancelled' })
    .eq('id', registrationId)
    .select('*')
    .single()

  if (error) throw new Error(getTournamentError(error.message))

  return data
}

export async function openTournamentCheckIn(params: {
  tournamentId: string
  opensAt: string | null
  closesAt: string | null
  requiresCheckIn: boolean
}) {
  const { error } = await supabase.rpc('open_tournament_check_in', {
    target_tournament_id: params.tournamentId,
    target_opens_at: params.opensAt,
    target_closes_at: params.closesAt,
    target_requires_check_in: params.requiresCheckIn,
  })

  if (error) throw new Error(getTournamentError(error.message))
}

export async function closeTournamentCheckIn(tournamentId: string) {
  const { error } = await supabase.rpc('close_tournament_check_in', {
    target_tournament_id: tournamentId,
  })

  if (error) throw new Error(getTournamentError(error.message))
}

export async function confirmRegistrationCheckIn(registrationId: string) {
  const { error } = await supabase.rpc('confirm_registration_check_in', {
    target_registration_id: registrationId,
  })

  if (error) throw new Error(getTournamentError(error.message))
}

export async function setRegistrationCheckIn(params: {
  registrationId: string
  isCheckedIn: boolean
  notes: string | null
}) {
  const { error } = await supabase.rpc('set_registration_check_in', {
    target_registration_id: params.registrationId,
    target_is_checked_in: params.isCheckedIn,
    target_notes: params.notes,
  })

  if (error) throw new Error(getTournamentError(error.message))
}

export async function disqualifyTournamentRegistration(
  registrationId: string,
  reason: string,
) {
  const { error } = await supabase.rpc('disqualify_registration', {
    target_registration_id: registrationId,
    target_reason: reason,
  })

  if (error) throw new Error(getTournamentError(error.message))
}
