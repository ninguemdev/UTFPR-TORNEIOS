import { supabase } from '../lib/supabase/client'
import type { ActionLock, ActionLockScope, AuditLog } from '../lib/supabase/types'

export type AuditLogFilters = {
  action?: string
  entityType?: string
  tournamentId?: string
  limit?: number
}

export type ActionLockInput = {
  scope: ActionLockScope
  scopeId: string | null
  action: string
  reason: string
  isLocked: boolean
  expiresAt: string | null
}

export const actionLockScopeLabels: Record<ActionLockScope, string> = {
  global: 'Global',
  tournament: 'Torneio',
  registration: 'Inscricao',
  team: 'Equipe',
  match: 'Partida',
  ranking: 'Ranking',
}

export const actionLockActionOptions = [
  'create_tournament',
  'edit_tournament',
  'delete_tournament',
  'register',
  'cancel_registration',
  'manage_registration',
  'manage_teams',
  'generate_bracket',
  'record_result',
  'contest_result',
  'recalculate_ranking',
] as const

function getAdminError(message: string) {
  const normalized = message.toLowerCase()

  if (normalized.includes('permission') || normalized.includes('rls')) {
    return 'Permissao negada pelo banco.'
  }

  if (normalized.includes('bloqueio') || normalized.includes('bloqueada')) {
    return message
  }

  if (normalized.includes('duplicate') || normalized.includes('unique')) {
    return 'Ja existe um bloqueio para este escopo e acao.'
  }

  return message
}

function normalizeScopeId(scope: ActionLockScope, scopeId: string | null) {
  const normalized = scopeId?.trim() ?? ''

  if (scope === 'global') return null
  if (!normalized) throw new Error('Informe o ID do escopo para bloqueios nao globais.')

  return normalized
}

export async function fetchAuditLogs(filters: AuditLogFilters = {}) {
  let query = supabase
    .from('audit_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(filters.limit ?? 100)

  if (filters.action?.trim()) {
    query = query.eq('action', filters.action.trim())
  }

  if (filters.entityType?.trim()) {
    query = query.eq('entity_type', filters.entityType.trim())
  }

  if (filters.tournamentId?.trim()) {
    query = query.eq('tournament_id', filters.tournamentId.trim())
  }

  const { data, error } = await query

  if (error) throw new Error(getAdminError(error.message))

  return data satisfies AuditLog[]
}

export async function fetchActionLocks() {
  const { data, error } = await supabase
    .from('action_locks')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) throw new Error(getAdminError(error.message))

  return data satisfies ActionLock[]
}

export async function createActionLock(input: ActionLockInput) {
  const { data, error } = await supabase
    .from('action_locks')
    .insert({
      scope: input.scope,
      scope_id: normalizeScopeId(input.scope, input.scopeId),
      action: input.action.trim(),
      reason: input.reason.trim(),
      is_locked: input.isLocked,
      expires_at: input.expiresAt,
    })
    .select('*')
    .single()

  if (error) throw new Error(getAdminError(error.message))

  return data
}

export async function updateActionLock(
  lockId: string,
  values: Partial<Pick<ActionLock, 'is_locked' | 'reason' | 'expires_at'>>,
) {
  const payload: Partial<Pick<ActionLock, 'is_locked' | 'reason' | 'expires_at'>> = {}

  if (values.is_locked !== undefined) {
    payload.is_locked = values.is_locked
  }

  if (values.reason !== undefined) {
    payload.reason = values.reason.trim()
  }

  if (values.expires_at !== undefined) {
    payload.expires_at = values.expires_at
  }

  const { data, error } = await supabase
    .from('action_locks')
    .update(payload)
    .eq('id', lockId)
    .select('*')
    .single()

  if (error) throw new Error(getAdminError(error.message))

  return data
}

export async function deleteActionLock(lockId: string) {
  const { error } = await supabase
    .from('action_locks')
    .delete()
    .eq('id', lockId)

  if (error) throw new Error(getAdminError(error.message))
}
