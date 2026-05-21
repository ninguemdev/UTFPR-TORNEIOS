import type { ReactNode } from 'react'
import { UserMenu } from '../auth/UserMenu'

type AuthenticatedShellProps = {
  subtitle: string
  children: ReactNode
}

export function AuthenticatedShell({
  subtitle,
  children,
}: AuthenticatedShellProps) {
  return (
    <div className="app-shell">
      <header className="app-header">
        <a className="brand" href="#home">
          <span className="brand-mark" aria-hidden="true">
            UT
          </span>
          <span>
            <span className="brand-title">UTFPR Torneios</span>
            <span className="brand-subtitle">{subtitle}</span>
          </span>
        </a>
        <UserMenu />
      </header>
      <main className="app-main">{children}</main>
    </div>
  )
}
