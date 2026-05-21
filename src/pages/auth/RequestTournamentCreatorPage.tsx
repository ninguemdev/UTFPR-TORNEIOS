import { type FormEvent, useState } from 'react'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import { useAuth } from '../../context/auth'
import { createCreatorRequest } from '../../services/tournamentCreatorRequests'

export function RequestTournamentCreatorPage() {
  const { user, canCreateTournaments, refreshCreatorPermission } = useAuth()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = event.currentTarget
    setError('')
    setSuccess('')

    if (!user) {
      setError('Você precisa estar autenticado para solicitar permissão.')
      return
    }

    const formData = new FormData(form)
    const reason = String(formData.get('reason') ?? '').trim()

    if (reason.length < 20) {
      setError('Explique o motivo com pelo menos 20 caracteres.')
      return
    }

    setIsSubmitting(true)

    try {
      await createCreatorRequest(user.id, reason)
      await refreshCreatorPermission()
      form.reset()
      setSuccess('Pedido enviado. Um admin poderá aprovar ou rejeitar.')
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : 'Não foi possível enviar o pedido.',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <AuthenticatedShell subtitle="Permissão de torneios">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="request-title">
          <div>
            <span className="eyebrow">Organização</span>
            <h1 id="request-title">Solicitar criação de torneio</h1>
            <p>
              Envie uma justificativa para receber permissão de criar torneios.
              A aprovação não transforma você em admin global.
            </p>
          </div>
          <div className="page-header-action">
            <a className="button button-secondary" href="#/meus-pedidos">
              Ver meus pedidos
            </a>
          </div>
        </section>

        {canCreateTournaments && (
          <section className="alert alert-info" role="status">
            <strong>Permissão ativa</strong>
            <div>Você já pode acessar funcionalidades de organização de torneios.</div>
          </section>
        )}

        <form className="form-section request-form" onSubmit={handleSubmit} noValidate>
          <div className="section-heading">
            <h2>Justificativa</h2>
            <p>Informe contexto acadêmico, modalidade e responsabilidade esperada.</p>
          </div>

          {error && (
            <div className="form-message form-message-error" role="alert">
              {error}
            </div>
          )}
          {success && (
            <div className="form-message form-message-success" role="status">
              {success}
            </div>
          )}

          <label className="field" htmlFor="creator-request-reason">
            <span>Motivo do pedido</span>
            <textarea
              id="creator-request-reason"
              name="reason"
              rows={6}
              placeholder="Ex.: Quero organizar um torneio acadêmico de Valorant para a Semana Acadêmica..."
              required
            />
          </label>

          <button className="button button-primary" type="submit" disabled={isSubmitting}>
            {isSubmitting ? 'Enviando...' : 'Enviar pedido'}
          </button>
        </form>
      </div>
    </AuthenticatedShell>
  )
}
