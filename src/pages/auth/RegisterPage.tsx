import { AuthLayout } from '../../components/auth/AuthLayout'
import { RegisterForm } from '../../components/auth/RegisterForm'

export function RegisterPage() {
  return (
    <AuthLayout
      eyebrow="Criar conta"
      title="Criar conta"
      description="Cadastre email, senha e avatar. A matricula pode ser informada depois em Minha conta."
    >
      <RegisterForm />
    </AuthLayout>
  )
}
