export type UserRole = 'admin' | 'user'

export type AvatarKey =
  | 'avatar_utfpr_blue'
  | 'avatar_utfpr_green'
  | 'avatar_utfpr_gold'
  | 'avatar_competition'
  | 'avatar_academic'

export type TournamentCreatorRequestStatus =
  | 'pending'
  | 'approved'
  | 'rejected'
  | 'cancelled'

export type Profile = {
  id: string
  email: string | null
  display_name: string
  ra: string | null
  avatar_key: AvatarKey
  role: UserRole
  created_at: string
  updated_at: string
}

export type TournamentCreatorRequest = {
  id: string
  user_id: string
  reason: string
  status: TournamentCreatorRequestStatus
  reviewed_by: string | null
  reviewed_at: string | null
  admin_notes: string | null
  created_at: string
  updated_at: string
}

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: Profile
        Insert: Partial<Omit<Profile, 'created_at' | 'updated_at'>> &
          Pick<Profile, 'id'>
        Update: Partial<
          Pick<Profile, 'display_name' | 'ra' | 'avatar_key' | 'role' | 'email'>
        >
        Relationships: []
      }
      tournament_creator_requests: {
        Row: TournamentCreatorRequest
        Insert: Pick<TournamentCreatorRequest, 'user_id' | 'reason'> &
          Partial<
            Pick<
              TournamentCreatorRequest,
              'status' | 'reviewed_by' | 'reviewed_at' | 'admin_notes'
            >
          >
        Update: Partial<
          Pick<
            TournamentCreatorRequest,
            'status' | 'reviewed_by' | 'reviewed_at' | 'admin_notes'
          >
        >
        Relationships: []
      }
    }
    Views: Record<string, never>
    Functions: {
      can_create_tournaments: {
        Args: {
          target_user_id?: string
        }
        Returns: boolean
      }
      is_admin: {
        Args: Record<string, never>
        Returns: boolean
      }
    }
    Enums: {
      user_role: UserRole
      request_status: TournamentCreatorRequestStatus
    }
    CompositeTypes: Record<string, never>
  }
}
