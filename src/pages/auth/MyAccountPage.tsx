import { ProfileForm } from '../../components/auth/ProfileForm'
import { useAuth } from '../../context/auth'
import { getAvatarOption } from '../../components/auth/avatarOptions'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'

export function MyAccountPage() {
  const { profile, profileError, isAdmin } = useAuth()

  if (!profile) {
    return (
      <main className="app-main">
        <div className="error-state" role="alert">
          <strong>Perfil indisponível</strong>
          <span>{profileError || 'Não foi possível carregar seu profile.'}</span>
        </div>
      </main>
    )
  }

  const avatar = getAvatarOption(profile.avatar_key)

  return (
    <AuthenticatedShell subtitle="Minha conta">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="account-title">
          <div>
            <span className="eyebrow">Conta e perfil</span>
            <h1 id="account-title">Minha conta</h1>
            <p>
              Edite seus dados de perfil. Email e papel global são protegidos
              pelo banco e não podem ser alterados por usuário comum.
            </p>
          </div>
        </section>

        <section className="account-grid">
          <article className="surface-panel profile-summary">
            <span className={`profile-avatar profile-avatar-large avatar-tone-${avatar.tone}`} aria-hidden="true">
              {avatar.initials}
            </span>
            <div>
              <h2>{profile.display_name}</h2>
              <p>{profile.email}</p>
            </div>
            <dl className="definition-grid">
              <div>
                <dt>RA</dt>
                <dd>{profile.ra || 'Não informado'}</dd>
              </div>
              <div>
                <dt>Papel</dt>
                <dd>{isAdmin ? 'Admin' : 'User'}</dd>
              </div>
            </dl>
          </article>

          <ProfileForm key={profile.updated_at} profile={profile} />
        </section>
      </div>
    </AuthenticatedShell>
  )
}
