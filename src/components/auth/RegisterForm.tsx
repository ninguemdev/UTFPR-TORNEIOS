import { type FormEvent, useState } from 'react'
import { supabase } from '../../lib/supabase/client'
import type { AvatarKey } from '../../lib/supabase/types'
import { AvatarPicker } from './AvatarPicker'

function getRegisterError(message: string) {
  const normalized = message.toLowerCase()

  if (normalized.includes('already registered') || normalized.includes('already exists')) {
    return 'Já existe uma conta com este email.'
  }

  if (normalized.includes('password')) {
    return 'A senha não atende aos requisitos do Supabase.'
  }

  return 'Não foi possível criar a conta. Revise os dados e tente novamente.'
}

export function RegisterForm() {
  const [avatarKey, setAvatarKey] = useState<AvatarKey>('avatar_utfpr_blue')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = event.currentTarget
    setError('')
    setSuccess('')
    setIsSubmitting(true)

    const formData = new FormData(form)
    const email = String(formData.get('email') ?? '').trim()
    const password = String(formData.get('password') ?? '')
    const displayName = String(formData.get('display_name') ?? '').trim()

    if (!displayName || !email || !password) {
      setError('Informe nome, email e senha.')
      setIsSubmitting(false)
      return
    }

    if (password.length < 6) {
      setError('Use uma senha com pelo menos 6 caracteres.')
      setIsSubmitting(false)
      return
    }

    const { data, error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          display_name: displayName,
          avatar_key: avatarKey,
        },
      },
    })

    if (signUpError) {
      setError(getRegisterError(signUpError.message))
      setIsSubmitting(false)
      return
    }

    form.reset()
    setAvatarKey('avatar_utfpr_blue')
    setSuccess(
      data.session
        ? 'Conta criada. Você já pode acessar Minha conta.'
        : 'Conta criada. Verifique seu email se a confirmação estiver ativada no Supabase.',
    )
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

      <label className="field" htmlFor="register-display-name">
        <span>Nome exibido</span>
        <input
          id="register-display-name"
          name="display_name"
          type="text"
          autoComplete="name"
          required
        />
      </label>

      <label className="field" htmlFor="register-email">
        <span>Email</span>
        <input
          id="register-email"
          name="email"
          type="email"
          autoComplete="email"
          required
        />
      </label>

      <label className="field" htmlFor="register-password">
        <span>Senha</span>
        <input
          id="register-password"
          name="password"
          type="password"
          autoComplete="new-password"
          required
        />
      </label>

      <AvatarPicker
        value={avatarKey}
        disabled={isSubmitting}
        onChange={setAvatarKey}
      />

      <button className="button button-primary" type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Criando conta...' : 'Criar conta'}
      </button>

      <div className="auth-links">
        <a href="#/login">Já tenho conta</a>
      </div>
    </form>
  )
}
