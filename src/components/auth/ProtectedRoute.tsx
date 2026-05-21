import type { ReactNode } from 'react'
import { useAuth } from '../../context/auth'
import { AccessDeniedPage } from '../../pages/auth/AccessDeniedPage'

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { isLoading, session } = useAuth()

  if (isLoading) {
    return (
      <main className="app-main">
        <div className="loading-state" role="status" aria-live="polite">
          <span className="spinner" aria-hidden="true" />
          <span>Verificando sessão...</span>
        </div>
      </main>
    )
  }

  if (!session) {
    return (
      <AccessDeniedPage
        title="Login necessário"
        description="Entre com email e senha para acessar esta área."
        actionHref="#/login"
        actionLabel="Ir para login"
      />
    )
  }

  return children
}
