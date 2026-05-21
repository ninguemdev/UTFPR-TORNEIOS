import { AuthLayout } from '../../components/auth/AuthLayout'
import { LoginForm } from '../../components/auth/LoginForm'

export function LoginPage() {
  return (
    <AuthLayout
      eyebrow="Acesso seguro"
      title="Entrar no sistema"
      description="Use email e senha do Supabase Auth. O front-end só mantém a sessão; permissões reais continuam protegidas por RLS."
    >
      <LoginForm />
    </AuthLayout>
  )
}
