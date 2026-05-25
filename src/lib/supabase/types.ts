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

export type CreatorPermissionStatus = 'active' | 'revoked'

export type TournamentStatus =
  | 'draft'
  | 'registrations_open'
  | 'registrations_closed'
  | 'ongoing'
  | 'finished'
  | 'cancelled'

export type RegistrationType = 'individual' | 'team'

export type TeamStatus =
  | 'draft'
  | 'pending'
  | 'confirmed'
  | 'cancelled'
  | 'rejected'

export type TeamMemberRole = 'captain' | 'member'

export type TeamMemberStatus = 'active' | 'removed'

export type TournamentRegistrationStatus =
  | 'pending'
  | 'confirmed'
  | 'cancelled'
  | 'rejected'
  | 'checked_in'
  | 'registered'

export type BracketSeedingMethod = 'draw' | 'seeded'

export type BracketMatchStatus =
  | 'pending'
  | 'ready'
  | 'bye'
  | 'live'
  | 'completed'
  | 'disputed'
  | 'cancelled'

export type MatchResultStatus =
  | 'confirmed'
  | 'disputed'
  | 'resolved'
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

export type TournamentCreatorPermission = {
  id: string
  user_id: string
  status: CreatorPermissionStatus
  granted_by: string
  granted_at: string
  revoked_by: string | null
  revoked_at: string | null
  grant_reason: string | null
  revoke_reason: string | null
  created_at: string
  updated_at: string
}

export type Tournament = {
  id: string
  name: string
  slug: string
  modality: string
  description: string | null
  campus: string | null
  format: string
  status: TournamentStatus
  max_participants: number
  registration_type: RegistrationType
  team_min_size: number
  team_max_size: number
  allow_free_agents: boolean
  require_full_team_before_registration: boolean
  team_registration_deadline: string | null
  starts_at: string | null
  ends_at: string | null
  created_by: string
  created_at: string
  updated_at: string
}

export type TournamentRegistration = {
  id: string
  tournament_id: string
  user_id: string
  team_id: string | null
  display_name: string
  status: TournamentRegistrationStatus
  registration_type: RegistrationType
  seed: number | null
  captain_user_id: string | null
  admin_notes: string | null
  decided_by: string | null
  decided_at: string | null
  cancelled_by: string | null
  cancelled_at: string | null
  created_at: string
  updated_at: string
}

export type TournamentBracket = {
  id: string
  tournament_id: string
  format: string
  seeding_method: BracketSeedingMethod
  size: number
  rounds_count: number
  status: string
  winner_registration_id: string | null
  generated_by: string | null
  generated_at: string
  created_at: string
  updated_at: string
}

export type BracketMatch = {
  id: string
  bracket_id: string
  tournament_id: string
  round_number: number
  match_number: number
  status: BracketMatchStatus
  participant_a_registration_id: string | null
  participant_b_registration_id: string | null
  winner_registration_id: string | null
  score_a: number | null
  score_b: number | null
  next_match_id: string | null
  next_match_slot: 'a' | 'b' | null
  is_bye: boolean
  result_notes: string | null
  submitted_by: string | null
  submitted_at: string | null
  confirmed_by: string | null
  confirmed_at: string | null
  created_at: string
  updated_at: string
}

export type MatchResult = {
  id: string
  match_id: string
  bracket_id: string
  tournament_id: string
  score_a: number
  score_b: number
  winner_registration_id: string
  status: MatchResultStatus
  notes: string | null
  submitted_by: string | null
  submitted_at: string
  confirmed_by: string | null
  confirmed_at: string | null
  disputed_by: string | null
  disputed_at: string | null
  dispute_reason: string | null
  resolved_by: string | null
  resolved_at: string | null
  resolution_notes: string | null
  created_at: string
  updated_at: string
}

export type MatchResultHistory = {
  id: string
  match_id: string
  result_id: string | null
  previous_score_a: number | null
  previous_score_b: number | null
  new_score_a: number | null
  new_score_b: number | null
  previous_winner_registration_id: string | null
  new_winner_registration_id: string | null
  previous_status: BracketMatchStatus | null
  new_status: BracketMatchStatus | null
  changed_by: string | null
  change_reason: string | null
  created_at: string
}

export type Team = {
  id: string
  tournament_id: string
  name: string
  status: TeamStatus
  captain_id: string
  created_by: string
  registration_id: string | null
  admin_notes: string | null
  decided_by: string | null
  decided_at: string | null
  cancelled_by: string | null
  cancelled_at: string | null
  created_at: string
  updated_at: string
}

export type TeamMember = {
  id: string
  tournament_id: string
  team_id: string
  user_id: string
  role: TeamMemberRole
  status: TeamMemberStatus
  added_by: string | null
  removed_by: string | null
  removed_at: string | null
  created_at: string
  updated_at: string
}

export type ProfileLookupResult = {
  id: string
  display_name: string
  email: string | null
  ra: string | null
  avatar_key: AvatarKey
}

export type TeamMemberWithProfile = {
  id: string
  tournament_id: string
  team_id: string
  user_id: string
  display_name: string
  avatar_key: AvatarKey
  role: TeamMemberRole
  status: TeamMemberStatus
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
      tournament_creator_permissions: {
        Row: TournamentCreatorPermission
        Insert: Pick<
          TournamentCreatorPermission,
          'user_id' | 'status' | 'granted_by'
        > &
          Partial<
            Pick<
              TournamentCreatorPermission,
              | 'granted_at'
              | 'revoked_by'
              | 'revoked_at'
              | 'grant_reason'
              | 'revoke_reason'
            >
          >
        Update: Partial<
          Pick<
            TournamentCreatorPermission,
            'status' | 'revoked_by' | 'revoked_at' | 'revoke_reason'
          >
        >
        Relationships: []
      }
      tournaments: {
        Row: Tournament
        Insert: Pick<
          Tournament,
          'name' | 'slug' | 'modality' | 'format' | 'status' | 'created_by'
        > &
          Partial<
            Pick<
              Tournament,
              | 'description'
              | 'campus'
              | 'max_participants'
              | 'registration_type'
              | 'team_min_size'
              | 'team_max_size'
              | 'allow_free_agents'
              | 'require_full_team_before_registration'
              | 'team_registration_deadline'
              | 'starts_at'
              | 'ends_at'
            >
          >
        Update: Partial<
          Pick<
            Tournament,
            | 'name'
            | 'slug'
            | 'modality'
            | 'description'
            | 'campus'
            | 'format'
            | 'status'
            | 'max_participants'
            | 'registration_type'
            | 'team_min_size'
            | 'team_max_size'
            | 'allow_free_agents'
            | 'require_full_team_before_registration'
            | 'team_registration_deadline'
            | 'starts_at'
            | 'ends_at'
          >
        >
        Relationships: []
      }
      tournament_registrations: {
        Row: TournamentRegistration
        Insert: Pick<
          TournamentRegistration,
          'tournament_id' | 'user_id' | 'display_name'
        > &
          Partial<
            Pick<
              TournamentRegistration,
              'status' | 'registration_type' | 'captain_user_id' | 'team_id' | 'seed'
            >
          >
        Update: Partial<
          Pick<
            TournamentRegistration,
            | 'display_name'
            | 'status'
            | 'admin_notes'
            | 'decided_by'
            | 'decided_at'
            | 'cancelled_by'
            | 'cancelled_at'
            | 'seed'
          >
        >
        Relationships: []
      }
      tournament_brackets: {
        Row: TournamentBracket
        Insert: Pick<
          TournamentBracket,
          | 'tournament_id'
          | 'format'
          | 'seeding_method'
          | 'size'
          | 'rounds_count'
          | 'generated_by'
        > &
          Partial<
            Pick<
              TournamentBracket,
              'status' | 'winner_registration_id' | 'generated_at'
            >
          >
        Update: Partial<
          Pick<
            TournamentBracket,
            | 'status'
            | 'winner_registration_id'
            | 'generated_by'
            | 'generated_at'
          >
        >
        Relationships: []
      }
      bracket_matches: {
        Row: BracketMatch
        Insert: Pick<
          BracketMatch,
          'bracket_id' | 'tournament_id' | 'round_number' | 'match_number'
        > &
          Partial<
            Pick<
              BracketMatch,
              | 'status'
              | 'participant_a_registration_id'
              | 'participant_b_registration_id'
              | 'winner_registration_id'
              | 'score_a'
              | 'score_b'
              | 'next_match_id'
              | 'next_match_slot'
              | 'is_bye'
              | 'result_notes'
              | 'submitted_by'
              | 'submitted_at'
              | 'confirmed_by'
              | 'confirmed_at'
            >
          >
        Update: Partial<
          Pick<
            BracketMatch,
            | 'status'
            | 'participant_a_registration_id'
            | 'participant_b_registration_id'
            | 'winner_registration_id'
            | 'score_a'
            | 'score_b'
            | 'next_match_id'
            | 'next_match_slot'
            | 'is_bye'
            | 'result_notes'
            | 'submitted_by'
            | 'submitted_at'
            | 'confirmed_by'
            | 'confirmed_at'
          >
        >
        Relationships: []
      }
      match_results: {
        Row: MatchResult
        Insert: Pick<
          MatchResult,
          | 'match_id'
          | 'bracket_id'
          | 'tournament_id'
          | 'score_a'
          | 'score_b'
          | 'winner_registration_id'
        > &
          Partial<
            Pick<
              MatchResult,
              | 'status'
              | 'notes'
              | 'submitted_by'
              | 'submitted_at'
              | 'confirmed_by'
              | 'confirmed_at'
              | 'disputed_by'
              | 'disputed_at'
              | 'dispute_reason'
              | 'resolved_by'
              | 'resolved_at'
              | 'resolution_notes'
            >
          >
        Update: Partial<
          Pick<
            MatchResult,
            | 'score_a'
            | 'score_b'
            | 'winner_registration_id'
            | 'status'
            | 'notes'
            | 'submitted_by'
            | 'submitted_at'
            | 'confirmed_by'
            | 'confirmed_at'
            | 'disputed_by'
            | 'disputed_at'
            | 'dispute_reason'
            | 'resolved_by'
            | 'resolved_at'
            | 'resolution_notes'
          >
        >
        Relationships: []
      }
      match_result_history: {
        Row: MatchResultHistory
        Insert: Pick<MatchResultHistory, 'match_id'> &
          Partial<
            Pick<
              MatchResultHistory,
              | 'result_id'
              | 'previous_score_a'
              | 'previous_score_b'
              | 'new_score_a'
              | 'new_score_b'
              | 'previous_winner_registration_id'
              | 'new_winner_registration_id'
              | 'previous_status'
              | 'new_status'
              | 'changed_by'
              | 'change_reason'
            >
          >
        Update: never
        Relationships: []
      }
      teams: {
        Row: Team
        Insert: Pick<Team, 'tournament_id' | 'name' | 'captain_id' | 'created_by'> &
          Partial<Pick<Team, 'status' | 'registration_id' | 'admin_notes'>>
        Update: Partial<
          Pick<
            Team,
            | 'name'
            | 'status'
            | 'registration_id'
            | 'admin_notes'
            | 'decided_by'
            | 'decided_at'
            | 'cancelled_by'
            | 'cancelled_at'
          >
        >
        Relationships: []
      }
      team_members: {
        Row: TeamMember
        Insert: Pick<TeamMember, 'team_id' | 'user_id'> &
          Partial<Pick<TeamMember, 'tournament_id' | 'role' | 'status' | 'added_by'>>
        Update: Partial<
          Pick<TeamMember, 'role' | 'status' | 'removed_by' | 'removed_at'>
        >
        Relationships: []
      }
    }
    Views: Record<string, never>
    Functions: {
      can_create_tournament: {
        Args: {
          target_user_id?: string
        }
        Returns: boolean
      }
      can_create_tournaments: {
        Args: {
          target_user_id?: string
        }
        Returns: boolean
      }
      can_manage_tournament: {
        Args: {
          target_tournament_id: string
        }
        Returns: boolean
      }
      find_profile_for_team_member: {
        Args: {
          identifier: string
        }
        Returns: ProfileLookupResult[]
      }
      get_team_members_with_profiles: {
        Args: {
          target_team_id: string
        }
        Returns: TeamMemberWithProfile[]
      }
      complete_bracket_match: {
        Args: {
          target_match_id: string
          target_winner_registration_id: string
          target_score_a: number
          target_score_b: number
        }
        Returns: void
      }
      contest_match_result: {
        Args: {
          target_match_id: string
          target_reason: string
        }
        Returns: void
      }
      is_admin: {
        Args: Record<string, never>
        Returns: boolean
      }
      is_match_participant: {
        Args: {
          target_match_id: string
        }
        Returns: boolean
      }
      record_bracket_match_result: {
        Args: {
          target_match_id: string
          target_winner_registration_id: string
          target_score_a: number
          target_score_b: number
          target_notes?: string | null
          target_change_reason?: string | null
        }
        Returns: void
      }
      resolve_match_dispute: {
        Args: {
          target_match_id: string
          target_resolution_action?: 'confirm' | 'cancel'
          target_resolution_notes?: string | null
        }
        Returns: void
      }
      submit_team_registration: {
        Args: {
          target_team_id: string
        }
        Returns: string
      }
    }
    Enums: {
      user_role: UserRole
      request_status: TournamentCreatorRequestStatus
      creator_permission_status: CreatorPermissionStatus
      tournament_status: TournamentStatus
      tournament_registration_status: TournamentRegistrationStatus
      registration_type: RegistrationType
      bracket_seeding_method: BracketSeedingMethod
      bracket_match_status: BracketMatchStatus
      match_result_status: MatchResultStatus
      team_status: TeamStatus
      team_member_role: TeamMemberRole
      team_member_status: TeamMemberStatus
    }
    CompositeTypes: Record<string, never>
  }
}
