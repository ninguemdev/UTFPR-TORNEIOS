import { type FormEvent, useState } from 'react'
import { supabase } from '../../lib/supabase/client'

export function PasswordRecoveryForm() {
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError('')
    setSuccess('')
    setIsSubmitting(true)

    const formData = new FormData(event.currentTarget)
    const email = String(formData.get('email') ?? '').trim()

    if (!email) {
      setError('Informe o email da conta.')
      setIsSubmitting(false)
      return
    }

    const { error: recoveryError } = await supabase.auth.resetPasswordForEmail(
      email,
      {
        redirectTo: `${window.location.origin}${window.location.pathname}#/minha-conta`,
      },
    )

    if (recoveryError) {
      setError('Não foi possível enviar o email de recuperação.')
      setIsSubmitting(false)
      return
    }

    setSuccess('Se o email existir, o Supabase enviará instruções de recuperação.')
    setIsSubmitting(false)
  }

  return (
    <form className="auth-form" onSubmit={handleSubmit} noValidate>
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

      <label className="field" htmlFor="recovery-email">
        <span>Email</span>
        <input
          id="recovery-email"
          name="email"
          type="email"
          autoComplete="email"
          required
        />
      </label>

      <button className="button button-primary" type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Enviando...' : 'Enviar recuperação'}
      </button>

      <div className="auth-links">
        <a href="#/login">Voltar para login</a>
      </div>
    </form>
  )
}
