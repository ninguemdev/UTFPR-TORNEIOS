import { supabase } from '../lib/supabase/client'
import type {
  Profile,
  TournamentCreatorRequest,
  TournamentCreatorRequestStatus,
} from '../lib/supabase/types'

export type CreatorRequestWithProfile = TournamentCreatorRequest & {
  requester?: Pick<Profile, 'id' | 'display_name' | 'email' | 'ra' | 'avatar_key'>
}

function getRequestError(message: string) {
  const normalized = message.toLowerCase()

  if (normalized.includes('duplicate') || normalized.includes('one_pending')) {
    return 'Você já possui um pedido pendente.'
  }

  if (normalized.includes('permission') || normalized.includes('rls')) {
    return 'Permissão negada pelo banco.'
  }

  if (normalized.includes('pending')) {
    return 'Apenas pedidos pendentes podem ser alterados.'
  }

  return message
}

export async function fetchMyCreatorRequests(userId: string) {
  const { data, error } = await supabase
    .from('tournament_creator_requests')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })

  if (error) throw new Error(getRequestError(error.message))

  return data
}

export async function fetchAllCreatorRequests() {
  const { data: requests, error: requestsError } = await supabase
    .from('tournament_creator_requests')
    .select('*')
    .order('created_at', { ascending: false })

  if (requestsError) throw new Error(getRequestError(requestsError.message))

  const userIds = Array.from(new Set(requests.map((request) => request.user_id)))

  if (userIds.length === 0) return []

  const { data: profiles, error: profilesError } = await supabase
    .from('profiles')
    .select('id, display_name, email, ra, avatar_key')
    .in('id', userIds)

  if (profilesError) throw new Error(getRequestError(profilesError.message))

  const profilesById = new Map(profiles.map((profile) => [profile.id, profile]))

  return requests.map<CreatorRequestWithProfile>((request) => ({
    ...request,
    requester: profilesById.get(request.user_id),
  }))
}

export async function createCreatorRequest(userId: string, reason: string) {
  const { data, error } = await supabase
    .from('tournament_creator_requests')
    .insert({
      user_id: userId,
      reason,
    })
    .select('*')
    .single()

  if (error) throw new Error(getRequestError(error.message))

  return data
}

export async function cancelCreatorRequest(requestId: string) {
  const { data, error } = await supabase
    .from('tournament_creator_requests')
    .update({ status: 'cancelled' })
    .eq('id', requestId)
    .select('*')
    .single()

  if (error) throw new Error(getRequestError(error.message))

  return data
}

export async function reviewCreatorRequest(
  requestId: string,
  status: Extract<TournamentCreatorRequestStatus, 'approved' | 'rejected'>,
  adminNotes: string,
) {
  const { data, error } = await supabase
    .from('tournament_creator_requests')
    .update({
      status,
      admin_notes: adminNotes.trim() || null,
    })
    .eq('id', requestId)
    .select('*')
    .single()

  if (error) throw new Error(getRequestError(error.message))

  return data
}
