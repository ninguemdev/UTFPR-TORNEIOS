import {
  tournamentRegistrationDisplayStatusLabels,
  type TournamentRegistrationDisplayStatus,
} from '../../services/tournaments'

const statusTone: Record<TournamentRegistrationDisplayStatus, string> = {
  pending: 'pending',
  confirmed: 'success',
  cancelled: 'cancelled',
  rejected: 'danger',
  checked_in: 'live',
  registered: 'success',
  no_show: 'warning',
  disqualified: 'danger',
}

export function TournamentRegistrationStatusBadge({
  status,
}: {
  status: TournamentRegistrationDisplayStatus
}) {
  return (
    <span className={`badge badge-${statusTone[status]}`}>
      {tournamentRegistrationDisplayStatusLabels[status]}
    </span>
  )
}
