export type TournamentStatus = 'registration_open' | 'running' | 'finished'

export type MatchStatus = 'pending' | 'live' | 'finished' | 'contested'

export type Tournament = {
  id: string
  name: string
  modality: string
  campus: string
  status: TournamentStatus
  format: string
  teams: number
  registrations: number
  startsAt: string
  organizer: string
  description: string
}

export type Team = {
  id: string
  name: string
  captain: string
  members: number
  seed: number
  checkedIn: boolean
}

export type Match = {
  id: string
  phase: string
  round: string
  teamA: string
  teamB: string
  scoreA?: number
  scoreB?: number
  status: MatchStatus
  scheduledAt: string
  venue: string
}

export type RankingRow = {
  position: number
  team: string
  points: number
  wins: number
  draws: number
  losses: number
  scoreDiff: number
  scoreFor: number
  note?: string
}

export type BracketMatch = {
  id: string
  label: string
  teamA: string
  teamB: string
  scoreA?: number
  scoreB?: number
  status: MatchStatus
  winner?: string
}

export type BracketRound = {
  id: string
  title: string
  matches: BracketMatch[]
}

export type GroupTable = {
  id: string
  name: string
  rows: RankingRow[]
}

export const tournaments: Tournament[] = [
  {
    id: 'copa-pixel-valorant-2026',
    name: 'Copa Pixel Valorant',
    modality: 'Valorant',
    campus: 'Curitiba',
    status: 'registration_open',
    format: 'Grupos + playoffs',
    teams: 8,
    registrations: 6,
    startsAt: '26 maio 2026',
    organizer: 'DAINF',
    description:
      'Torneio acadêmico com fase de grupos, playoffs e confirmação dupla de resultados.',
  },
  {
    id: 'xadrez-rapido-2026',
    name: 'Circuito de Xadrez Rápido',
    modality: 'Xadrez',
    campus: 'Pato Branco',
    status: 'running',
    format: 'Pontos corridos',
    teams: 16,
    registrations: 16,
    startsAt: '18 maio 2026',
    organizer: 'Centro Acadêmico',
    description:
      'Rodadas rápidas com tabela de classificação e desempate por confronto direto.',
  },
  {
    id: 'futsal-integracao-2026',
    name: 'Futsal Integração',
    modality: 'Futsal',
    campus: 'Campo Mourão',
    status: 'finished',
    format: 'Mata-mata simples',
    teams: 8,
    registrations: 8,
    startsAt: '10 abril 2026',
    organizer: 'Atlética Campus',
    description:
      'Competição encerrada com final publicada, disputa de terceiro lugar e auditoria de W.O.',
  },
]

export const teams: Team[] = [
  { id: 'aurora', name: 'Aurora Tech', captain: 'Larissa N.', members: 5, seed: 1, checkedIn: true },
  { id: 'byte', name: 'Byte Builders', captain: 'Rafael M.', members: 5, seed: 2, checkedIn: true },
  { id: 'delta', name: 'Delta Labs', captain: 'Camila P.', members: 5, seed: 3, checkedIn: true },
  { id: 'gamma', name: 'Pixel Punks', captain: 'Joao V.', members: 4, seed: 4, checkedIn: false },
  { id: 'nexus', name: 'Nexus Arena', captain: 'Bianca S.', members: 5, seed: 5, checkedIn: true },
  { id: 'omega', name: 'Lag Lords', captain: 'Heitor C.', members: 5, seed: 6, checkedIn: false },
  { id: 'quantum', name: 'Quantum Five', captain: 'Marina A.', members: 5, seed: 7, checkedIn: true },
  { id: 'vector', name: 'Vector Sul', captain: 'Igor T.', members: 5, seed: 8, checkedIn: true },
]

export const matches: Match[] = [
  {
    id: 'm1',
    phase: 'Grupo A',
    round: 'Rodada 1',
    teamA: 'Aurora Tech',
    teamB: 'Vector Sul',
    scoreA: 13,
    scoreB: 8,
    status: 'finished',
    scheduledAt: 'Hoje, 18:30',
    venue: 'Servidor 01',
  },
  {
    id: 'm2',
    phase: 'Grupo B',
    round: 'Rodada 1',
    teamA: 'Byte Builders',
    teamB: 'Quantum Five',
    status: 'live',
    scheduledAt: 'Agora',
    venue: 'Servidor 02',
  },
  {
    id: 'm3',
    phase: 'Grupo A',
    round: 'Rodada 2',
    teamA: 'Delta Labs',
    teamB: 'Nexus Arena',
    status: 'pending',
    scheduledAt: 'Amanha, 19:00',
    venue: 'Laboratorio B-204',
  },
  {
    id: 'm4',
    phase: 'Semifinal',
    round: 'Playoffs',
    teamA: 'Pixel Punks',
    teamB: 'Lag Lords',
    scoreA: 12,
    scoreB: 12,
    status: 'contested',
    scheduledAt: '22 maio, 20:00',
    venue: 'Servidor 03',
  },
]

export const ranking: RankingRow[] = [
  { position: 1, team: 'Aurora Tech', points: 9, wins: 3, draws: 0, losses: 0, scoreDiff: 18, scoreFor: 39 },
  { position: 2, team: 'Byte Builders', points: 7, wins: 2, draws: 1, losses: 0, scoreDiff: 11, scoreFor: 35 },
  { position: 3, team: 'Delta Labs', points: 6, wins: 2, draws: 0, losses: 1, scoreDiff: 7, scoreFor: 31 },
  { position: 4, team: 'Nexus Arena', points: 4, wins: 1, draws: 1, losses: 1, scoreDiff: 1, scoreFor: 26, note: 'Confronto direto aplicado' },
]

export const bracketRounds: BracketRound[] = [
  {
    id: 'semi',
    title: 'Semifinais',
    matches: [
      {
        id: 'b1',
        label: 'SF 1',
        teamA: 'Aurora Tech',
        teamB: 'Nexus Arena',
        scoreA: 2,
        scoreB: 0,
        status: 'finished',
        winner: 'Aurora Tech',
      },
      {
        id: 'b2',
        label: 'SF 2',
        teamA: 'Byte Builders',
        teamB: 'Delta Labs',
        status: 'pending',
      },
    ],
  },
  {
    id: 'final',
    title: 'Final',
    matches: [
      {
        id: 'b3',
        label: 'Final',
        teamA: 'Aurora Tech',
        teamB: 'A definir',
        status: 'pending',
      },
    ],
  },
]

export const groups: GroupTable[] = [
  {
    id: 'group-a',
    name: 'Grupo A',
    rows: [
      { position: 1, team: 'Aurora Tech', points: 6, wins: 2, draws: 0, losses: 0, scoreDiff: 10, scoreFor: 26 },
      { position: 2, team: 'Nexus Arena', points: 3, wins: 1, draws: 0, losses: 1, scoreDiff: 1, scoreFor: 21 },
      { position: 3, team: 'Vector Sul', points: 0, wins: 0, draws: 0, losses: 2, scoreDiff: -11, scoreFor: 15 },
    ],
  },
  {
    id: 'group-b',
    name: 'Grupo B',
    rows: [
      { position: 1, team: 'Byte Builders', points: 4, wins: 1, draws: 1, losses: 0, scoreDiff: 6, scoreFor: 24 },
      { position: 2, team: 'Delta Labs', points: 4, wins: 1, draws: 1, losses: 0, scoreDiff: 4, scoreFor: 22 },
      { position: 3, team: 'Quantum Five', points: 0, wins: 0, draws: 0, losses: 2, scoreDiff: -10, scoreFor: 13 },
    ],
  },
]

export const tieBreakers = [
  'Pontos',
  'Vitorias',
  'Saldo de rounds',
  'Confronto direto',
  'Rounds marcados',
  'Menos W.O.',
]

export const formats = [
  'Mata-mata simples',
  'Mata-mata melhor de 3',
  'Pontos corridos',
  'Grupos + playoffs',
  'Sistema suico planejado',
]
