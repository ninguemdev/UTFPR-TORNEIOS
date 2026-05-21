import { useAuth } from '../../context/auth'
import { getAvatarOption } from './avatarOptions'
import { LogoutButton } from './LogoutButton'

export function UserMenu() {
  const { isLoading, profile, session, isAdmin } = useAuth()

  if (isLoading) {
    return (
      <div className="user-menu user-menu-muted" aria-live="polite">
        Verificando sessão
      </div>
    )
  }

  if (!session || !profile) {
    return (
      <div className="user-menu">
        <a className="button button-ghost" href="#/login">
          Entrar
        </a>
        <a className="button button-secondary" href="#/cadastro">
          Criar conta
        </a>
      </div>
    )
  }

  const avatar = getAvatarOption(profile.avatar_key)

  return (
    <div className="user-menu">
      <a className="user-chip" href="#/minha-conta" aria-label="Abrir minha conta">
        <span className={`profile-avatar avatar-tone-${avatar.tone}`} aria-hidden="true">
          {avatar.initials}
        </span>
        <span>
          <strong>{profile.display_name}</strong>
          <small>{isAdmin ? 'Admin' : 'User'}</small>
        </span>
      </a>
      {isAdmin && (
        <a className="button button-secondary" href="#/admin">
          Admin
        </a>
      )}
      <LogoutButton />
    </div>
  )
}
