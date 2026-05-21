import { AuthLayout } from '../../components/auth/AuthLayout'
import { PasswordRecoveryForm } from '../../components/auth/PasswordRecoveryForm'

export function PasswordRecoveryPage() {
  return (
    <AuthLayout
      eyebrow="Recuperação"
      title="Recuperar senha"
      description="O Supabase envia o email de recuperação quando o provedor e o template estiverem configurados no painel."
    >
      <PasswordRecoveryForm />
    </AuthLayout>
  )
}
