import { UserMenu } from '../../components/auth/UserMenu'
import { useAuth } from '../../context/auth'

export function AdminHomePage() {
  const { profile } = useAuth()

  return (
    <div className="app-shell">
      <header className="app-header">
        <a className="brand" href="#home">
          <span className="brand-mark" aria-hidden="true">
            UT
          </span>
          <span>
            <span className="brand-title">UTFPR Torneios</span>
            <span className="brand-subtitle">Administração</span>
          </span>
        </a>
        <UserMenu />
      </header>

      <main className="app-main">
        <div className="page-stack">
          <section className="page-header" aria-labelledby="admin-title">
            <div>
              <span className="eyebrow">Área restrita</span>
              <h1 id="admin-title">Admin</h1>
              <p>
                Base inicial para dados administrativos. Acesso visível apenas
                para profiles com role admin.
              </p>
            </div>
          </section>

          <section className="content-grid three-columns" aria-label="Ações administrativas planejadas">
            <article className="rule-card">
              <span className="rule-marker" aria-hidden="true" />
              <h2>Pedidos pendentes</h2>
              <p>Aprovar ou rejeitar permissão para criação de torneios.</p>
            </article>
            <article className="rule-card">
              <span className="rule-marker" aria-hidden="true" />
              <h2>Disputas</h2>
              <p>Resolver contestações e registrar justificativas.</p>
            </article>
            <article className="rule-card">
              <span className="rule-marker" aria-hidden="true" />
              <h2>Perfil atual</h2>
              <p>{profile?.display_name} possui permissões globais de admin.</p>
            </article>
          </section>
        </div>
      </main>
    </div>
  )
}
