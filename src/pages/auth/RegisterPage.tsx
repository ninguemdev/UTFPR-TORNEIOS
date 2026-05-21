import { AuthLayout } from '../../components/auth/AuthLayout'
import { RegisterForm } from '../../components/auth/RegisterForm'

export function RegisterPage() {
  return (
    <AuthLayout
      eyebrow="Cadastro UTFPR"
      title="Criar conta"
      description="Cadastre email, senha e avatar pré-definido. O RA pode ser informado depois em Minha conta."
    >
      <RegisterForm />
    </AuthLayout>
  )
}
