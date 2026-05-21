import { useState } from 'react'
import type { TournamentCreatorRequest } from '../../lib/supabase/types'
import type { CreatorRequestWithProfile } from '../../services/tournamentCreatorRequests'
import { CreatorRequestStatusBadge } from './CreatorRequestStatusBadge'

type CreatorRequestCardProps = {
  request: CreatorRequestWithProfile | TournamentCreatorRequest
  mode: 'user' | 'admin'
  isBusy?: boolean
  onCancel?: (requestId: string) => void
  onReview?: (requestId: string, decision: 'approved' | 'rejected', adminNotes: string) => void
}

function formatDate(value: string | null) {
  if (!value) return 'Não informado'

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value))
}

export function CreatorRequestCard({
  request,
  mode,
  isBusy = false,
  onCancel,
  onReview,
}: CreatorRequestCardProps) {
  const [adminNotes, setAdminNotes] = useState(request.admin_notes ?? '')
  const requester = 'requester' in request ? request.requester : undefined
  const isPending = request.status === 'pending'

  function handleReview(decision: 'approved' | 'rejected') {
    onReview?.(request.id, decision, adminNotes)
  }

  return (
    <article className="request-card">
      <div className="card-topline">
        <CreatorRequestStatusBadge status={request.status} />
        <span>Criado em {formatDate(request.created_at)}</span>
      </div>

      {mode === 'admin' && requester && (
        <div className="requester-summary">
          <strong>{requester.display_name}</strong>
          <span>{requester.email ?? 'Email não disponível'}</span>
          <span>RA: {requester.ra || 'Não informado'}</span>
        </div>
      )}

      <div className="request-reason">
        <h2>Motivo</h2>
        <p>{request.reason}</p>
      </div>

      <dl className="definition-grid">
        <div>
          <dt>Status</dt>
          <dd>{request.status}</dd>
        </div>
        <div>
          <dt>Revisado em</dt>
          <dd>{formatDate(request.reviewed_at)}</dd>
        </div>
      </dl>

      {request.admin_notes && (
        <div className="admin-notes">
          <strong>Observações do admin</strong>
          <p>{request.admin_notes}</p>
        </div>
      )}

      {mode === 'user' && isPending && (
        <button
          className="button button-secondary"
          type="button"
          disabled={isBusy}
          onClick={() => onCancel?.(request.id)}
        >
          {isBusy ? 'Cancelando...' : 'Cancelar pedido'}
        </button>
      )}

      {mode === 'admin' && isPending && (
        <div className="review-form">
          <label className="field" htmlFor={`admin-notes-${request.id}`}>
            <span>Observações administrativas</span>
            <textarea
              id={`admin-notes-${request.id}`}
              value={adminNotes}
              rows={3}
              onChange={(event) => setAdminNotes(event.target.value)}
              placeholder="Explique a decisão ou registre uma orientação."
            />
          </label>
          <div className="form-actions">
            <button
              className="button button-secondary"
              type="button"
              disabled={isBusy}
              onClick={() => handleReview('rejected')}
            >
              {isBusy ? 'Salvando...' : 'Rejeitar'}
            </button>
            <button
              className="button button-primary"
              type="button"
              disabled={isBusy}
              onClick={() => handleReview('approved')}
            >
              {isBusy ? 'Salvando...' : 'Aprovar'}
            </button>
          </div>
        </div>
      )}
    </article>
  )
}
