import { type FormEvent, useState } from 'react'
import { useAuth } from '../../context/auth'
import { supabase } from '../../lib/supabase/client'
import type { AvatarKey, Profile } from '../../lib/supabase/types'
import { AvatarPicker } from './AvatarPicker'

type ProfileFormProps = {
  profile: Profile
}

function getProfileError(message: string) {
  const normalized = message.toLowerCase()

  if (normalized.includes('role')) {
    return 'Você não pode alterar seu papel de acesso.'
  }

  if (normalized.includes('permission') || normalized.includes('rls')) {
    return 'Permissão negada pelo banco. Confira se você está editando seu próprio perfil.'
  }

  return 'Não foi possível atualizar o perfil.'
}

export function ProfileForm({ profile }: ProfileFormProps) {
  const { refreshProfile } = useAuth()
  const [displayName, setDisplayName] = useState(profile.display_name)
  const [ra, setRa] = useState(profile.ra ?? '')
  const [avatarKey, setAvatarKey] = useState<AvatarKey>(profile.avatar_key)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError('')
    setSuccess('')
    setIsSubmitting(true)

    if (displayName.trim().length < 2) {
      setError('Informe um nome exibido com pelo menos 2 caracteres.')
      setIsSubmitting(false)
      return
    }

    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        display_name: displayName.trim(),
        ra: ra.trim() || null,
        avatar_key: avatarKey,
      })
      .eq('id', profile.id)

    if (updateError) {
      setError(getProfileError(updateError.message))
      setIsSubmitting(false)
      return
    }

    await refreshProfile()
    setSuccess('Perfil atualizado com segurança.')
    setIsSubmitting(false)
  }

  return (
    <form className="form-section profile-form" onSubmit={handleSubmit} noValidate>
      <div className="section-heading">
        <h2>Dados editáveis</h2>
        <p>Usuários comuns editam apenas nome exibido, RA e avatar.</p>
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

      <label className="field" htmlFor="profile-display-name">
        <span>Nome exibido</span>
        <input
          id="profile-display-name"
          type="text"
          value={displayName}
          onChange={(event) => setDisplayName(event.target.value)}
          required
        />
      </label>

      <label className="field" htmlFor="profile-ra">
        <span>RA</span>
        <input
          id="profile-ra"
          type="text"
          inputMode="numeric"
          value={ra}
          onChange={(event) => setRa(event.target.value)}
        />
      </label>

      <AvatarPicker
        value={avatarKey}
        disabled={isSubmitting}
        onChange={setAvatarKey}
      />

      <div className="locked-fields" aria-label="Campos protegidos">
        <label className="field" htmlFor="profile-email">
          <span>Email protegido</span>
          <input id="profile-email" type="email" value={profile.email ?? ''} disabled />
        </label>
        <label className="field" htmlFor="profile-role">
          <span>Papel protegido</span>
          <input id="profile-role" type="text" value={profile.role} disabled />
        </label>
      </div>

      <button className="button button-primary" type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Salvando...' : 'Salvar perfil'}
      </button>
    </form>
  )
}
