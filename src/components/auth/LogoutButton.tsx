import { useState } from 'react'
import { useAuth } from '../../context/auth'

export function LogoutButton({ className = 'button button-ghost' }: { className?: string }) {
  const { signOut } = useAuth()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')

  async function handleLogout() {
    setError('')
    setIsSubmitting(true)

    try {
      await signOut()
    } catch (logoutError) {
      setError(
        logoutError instanceof Error
          ? logoutError.message
          : 'Não foi possível sair da conta.',
      )
      setIsSubmitting(false)
    }
  }

  return (
    <span className="logout-inline">
      <button
        className={className}
        type="button"
        disabled={isSubmitting}
        onClick={handleLogout}
      >
        {isSubmitting ? 'Saindo...' : 'Sair'}
      </button>
      {error && (
        <span className="inline-error" role="alert">
          {error}
        </span>
      )}
    </span>
  )
}
