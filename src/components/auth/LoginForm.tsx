import { type FormEvent, useState } from 'react'
import { supabase } from '../../lib/supabase/client'
import { useAuth } from '../../context/auth'

function getLoginError(message: string) {
  const normalized = message.toLowerCase()

  if (normalized.includes('invalid login credentials')) {
    return 'Email ou senha inválidos.'
  }

  if (normalized.includes('email not confirmed')) {
    return 'Confirme seu email antes de entrar.'
  }

  return 'Não foi possível entrar. Revise os dados e tente novamente.'
}

export function LoginForm() {
  const { refreshProfile } = useAuth()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError('')
    setIsSubmitting(true)

    const formData = new FormData(event.currentTarget)
    const email = String(formData.get('email') ?? '').trim()
    const password = String(formData.get('password') ?? '')

    if (!email || !password) {
      setError('Informe email e senha.')
      setIsSubmitting(false)
      return
    }

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (signInError) {
      setError(getLoginError(signInError.message))
      setIsSubmitting(false)
      return
    }

    await refreshProfile()
    setIsSubmitting(false)
    window.location.hash = '#/minha-conta'
  }

  return (
    <form className="auth-form" onSubmit={handleSubmit} noValidate>
      {error && (
        <div className="form-message form-message-error" role="alert">
          {error}
        </div>
      )}

      <label className="field" htmlFor="login-email">
        <span>Email</span>
        <input
          id="login-email"
          name="email"
          type="email"
          autoComplete="email"
          required
        />
      </label>

      <label className="field" htmlFor="login-password">
        <span>Senha</span>
        <input
          id="login-password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
        />
      </label>

      <button className="button button-primary" type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Entrando...' : 'Entrar'}
      </button>

      <div className="auth-links">
        <a href="#/cadastro">Criar conta</a>
        <a href="#/recuperar-senha">Esqueci minha senha</a>
      </div>
    </form>
  )
}
