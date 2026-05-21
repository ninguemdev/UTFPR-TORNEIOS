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
            <span className="brand-mark" aria-hidden="true">
              UT
            </span>
            <span>
              <span className="brand-title">UTFPR Torneios</span>
              <span className="brand-subtitle">Organização acadêmica</span>
            </span>
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
