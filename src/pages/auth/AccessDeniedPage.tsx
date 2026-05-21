type AccessDeniedPageProps = {
  title?: string
  description?: string
  actionHref?: string
  actionLabel?: string
}

export function AccessDeniedPage({
  title = 'Acesso negado',
  description = 'Você não tem permissão para acessar esta área.',
  actionHref = '#home',
  actionLabel = 'Voltar ao início',
}: AccessDeniedPageProps) {
  return (
    <main className="app-main">
      <section className="empty-state access-denied" aria-labelledby="access-denied-title">
        <span className="empty-state-mark" aria-hidden="true">
          !
        </span>
        <h1 id="access-denied-title">{title}</h1>
        <p>{description}</p>
        <a className="button button-primary" href={actionHref}>
          {actionLabel}
        </a>
      </section>
    </main>
  )
}
