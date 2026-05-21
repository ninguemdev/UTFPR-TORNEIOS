import type { ReactNode } from 'react'
import { useAuth } from '../../context/auth'
import { AccessDeniedPage } from '../../pages/auth/AccessDeniedPage'
import { ProtectedRoute } from './ProtectedRoute'

export function AdminRoute({ children }: { children: ReactNode }) {
  const { isLoading, isAdmin } = useAuth()

  return (
    <ProtectedRoute>
      {isLoading || isAdmin ? (
        children
      ) : (
        <AccessDeniedPage
          title="Acesso negado"
          description="Esta área é exclusiva para administradores globais do sistema."
          actionHref="#/minha-conta"
          actionLabel="Voltar para minha conta"
        />
      )}
    </ProtectedRoute>
  )
}
