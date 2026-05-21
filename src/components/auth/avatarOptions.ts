import type { AvatarKey } from '../../lib/supabase/types'

export type AvatarOption = {
  key: AvatarKey
  label: string
  initials: string
  tone: 'blue' | 'green' | 'gold' | 'purple' | 'gray'
}

export const avatarOptions: AvatarOption[] = [
  {
    key: 'avatar_utfpr_blue',
    label: 'UTFPR azul',
    initials: 'UT',
    tone: 'blue',
  },
  {
    key: 'avatar_utfpr_green',
    label: 'UTFPR verde',
    initials: 'PR',
    tone: 'green',
  },
  {
    key: 'avatar_utfpr_gold',
    label: 'Destaque acadêmico',
    initials: 'DA',
    tone: 'gold',
  },
  {
    key: 'avatar_competition',
    label: 'Competição',
    initials: 'VS',
    tone: 'purple',
  },
  {
    key: 'avatar_academic',
    label: 'Acadêmico',
    initials: 'AC',
    tone: 'gray',
  },
]

export function getAvatarOption(avatarKey?: AvatarKey | null) {
  return (
    avatarOptions.find((option) => option.key === avatarKey) ??
    avatarOptions[0]
  )
}
