import type { ReactNode } from 'react'

type AuthLayoutProps = {
  eyebrow: string
  title: string
  description: string
  children: ReactNode
}

export function AuthLayout({
  eyebrow,
  title,
  description,
  children,
}: AuthLayoutProps) {
  return (
    <main className="auth-page">
      <section className="auth-shell" aria-labelledby="auth-title">
        <div className="auth-hero">
          <a className="brand" href="#home">
            <span>
              <span className="brand-title">CHAVEIA</span>
              <span className="brand-subtitle">torneios e e-sports</span>
            </span>
          </a>
          <a className="auth-home-link" href="#home">
            Voltar para a home
          </a>
          <div className="auth-copy">
            <span className="eyebrow">{eyebrow}</span>
            <h1 id="auth-title">{title}</h1>
            <p>{description}</p>
          </div>
        </div>
        <div className="auth-card">{children}</div>
      </section>
    </main>
  )
}
