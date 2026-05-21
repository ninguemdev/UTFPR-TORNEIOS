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
  user_id: string
  display_name: string
  role: UserRole
  ra: string | null
  avatar_key: AvatarKey
  can_create_tournaments: boolean
  created_at: string
  updated_at: string
}

export type TournamentCreatorRequest = {
  id: string
  requester_id: string
  status: TournamentCreatorRequestStatus
  reason: string | null
  decided_by: string | null
  decision_reason: string | null
  created_at: string
  decided_at: string | null
}

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: Profile
        Insert: Omit<Profile, 'created_at' | 'updated_at'>
        Update: Partial<Omit<Profile, 'id' | 'user_id' | 'created_at'>>
      }
      tournament_creator_requests: {
        Row: TournamentCreatorRequest
        Insert: Omit<TournamentCreatorRequest, 'id' | 'created_at' | 'decided_at'>
        Update: Partial<
          Pick<
            TournamentCreatorRequest,
            'status' | 'decided_by' | 'decision_reason' | 'decided_at'
          >
        >
      }
    }
  }
}
