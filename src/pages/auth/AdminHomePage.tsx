import { useAuth } from '../../context/auth'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'

export function AdminHomePage() {
  const { profile } = useAuth()

  return (
    <AuthenticatedShell subtitle="Administração">
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
          <div className="page-header-action">
            <a className="button button-primary" href="#/admin/pedidos">
              Revisar pedidos
            </a>
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
    </AuthenticatedShell>
  )
}
