import { createClient } from '@supabase/supabase-js'
import type { Database } from './types'

type SupabaseEnvName = 'VITE_SUPABASE_URL' | 'VITE_SUPABASE_ANON_KEY'

function readRequiredEnv(name: SupabaseEnvName) {
  const value = import.meta.env[name]

  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(
      `Variável de ambiente ${name} não configurada. Crie um arquivo .env.local com ${name}=... usando .env.example como referência.`,
    )
  }

  return value.trim()
}

export function getSupabaseConfig() {
  return {
    url: readRequiredEnv('VITE_SUPABASE_URL'),
    anonKey: readRequiredEnv('VITE_SUPABASE_ANON_KEY'),
  }
}

const { url, anonKey } = getSupabaseConfig()

export const supabase = createClient<Database>(url, anonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
})
