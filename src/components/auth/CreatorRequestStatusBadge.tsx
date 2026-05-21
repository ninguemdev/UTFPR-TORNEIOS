import type { TournamentCreatorRequestStatus } from '../../lib/supabase/types'

const statusLabels: Record<TournamentCreatorRequestStatus, string> = {
  pending: 'Pendente',
  approved: 'Aprovado',
  rejected: 'Rejeitado',
  cancelled: 'Cancelado',
}

export function CreatorRequestStatusBadge({
  status,
}: {
  status: TournamentCreatorRequestStatus
}) {
  return <span className={`badge badge-request-${status}`}>{statusLabels[status]}</span>
}
