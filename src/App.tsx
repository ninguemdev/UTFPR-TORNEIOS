import {
  type FormEvent,
  type KeyboardEvent,
  type ReactNode,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import './App.css'
import {
  bracketRounds,
  formats,
  groups,
  matches,
  ranking,
  teams,
  tieBreakers,
  tournaments,
  type BracketMatch as BracketMatchData,
  type BracketRound as BracketRoundData,
  type GroupTable,
  type Match,
  type MatchStatus,
  type RankingRow,
  type Team,
  type Tournament,
  type TournamentStatus,
} from './data/mockData'
import { AdminRoute } from './components/auth/AdminRoute'
import { ProtectedRoute } from './components/auth/ProtectedRoute'
import { PageBackButton } from './components/layout/PageBackButton'
import { SiteHeader } from './components/layout/SiteHeader'
import { AuthProvider } from './context/AuthContext'
import { useAuth } from './context/auth'
import { AccessDeniedPage } from './pages/auth/AccessDeniedPage'
import { AdminCreatorRequestsPage } from './pages/auth/AdminCreatorRequestsPage'
import { AdminHomePage } from './pages/auth/AdminHomePage'
import { LoginPage } from './pages/auth/LoginPage'
import { MyCreatorRequestsPage } from './pages/auth/MyCreatorRequestsPage'
import { MyAccountPage } from './pages/auth/MyAccountPage'
import { PasswordRecoveryPage } from './pages/auth/PasswordRecoveryPage'
import { RequestTournamentCreatorPage } from './pages/auth/RequestTournamentCreatorPage'
import { RegisterPage } from './pages/auth/RegisterPage'
import { CreateTournamentPage as SupabaseCreateTournamentPage } from './pages/tournaments/CreateTournamentPage'
import { EditTournamentPage as SupabaseEditTournamentPage } from './pages/tournaments/EditTournamentPage'
import { MyRegistrationsPage as SupabaseMyRegistrationsPage } from './pages/tournaments/MyRegistrationsPage'
import { PublicTournamentPage as SupabasePublicTournamentPage } from './pages/tournaments/PublicTournamentPage'
import { TeamDetailsPage as SupabaseTeamDetailsPage } from './pages/tournaments/TeamDetailsPage'
import { TournamentBracketPage as SupabaseTournamentBracketPage } from './pages/tournaments/TournamentBracketPage'
import { TournamentParticipantsPage as SupabaseTournamentParticipantsPage } from './pages/tournaments/TournamentParticipantsPage'
import { TournamentRankingPage as SupabaseTournamentRankingPage } from './pages/tournaments/TournamentRankingPage'
import { TournamentTeamsPage as SupabaseTournamentTeamsPage } from './pages/tournaments/TournamentTeamsPage'
import { TournamentsPage as SupabaseTournamentsPage } from './pages/tournaments/TournamentsPage'

type PageId =
  | 'home'
  | 'dashboard'
  | 'tournaments'
  | 'create'
  | 'public'
  | 'bracket'
  | 'groups'
  | 'matches'
  | 'result'
  | 'empty'

type TournamentView = 'cards' | 'table'
type PublicTab = 'overview' | 'participants' | 'rules'
type GroupTab = 'group-a' | 'group-b'

const demoPages = new Set<PageId>([
  'home',
  'dashboard',
  'create',
  'public',
  'bracket',
  'groups',
  'matches',
  'result',
  'empty',
])

function getDemoPageFromRoute(route: string): PageId {
  const cleanedRoute = route.replace(/^\//, '') as PageId
  return demoPages.has(cleanedRoute) ? cleanedRoute : 'home'
}

const tournamentStatusText: Record<TournamentStatus, string> = {
  registration_open: 'Inscrição aberta',
  running: 'Em andamento',
  finished: 'Encerrado',
}

const matchStatusText: Record<MatchStatus, string> = {
  pending: 'Partida pendente',
  live: 'Ao vivo',
  finished: 'Finalizada',
  contested: 'Contestada',
}

function App() {
  return (
    <AuthProvider>
      <AppRouter />
    </AuthProvider>
  )
}

function AppRouter() {
  const [route, setRoute] = useState(() => window.location.hash.replace(/^#/, '') || 'home')
  const normalizedRoute = route.startsWith('/') ? route : `/${route}`

  useEffect(() => {
    const handleHashChange = () => {
      setRoute(window.location.hash.replace(/^#/, '') || 'home')
    }

    window.addEventListener('hashchange', handleHashChange)
    return () => window.removeEventListener('hashchange', handleHashChange)
  }, [])

  if (normalizedRoute === '/torneios') {
    return <SupabaseTournamentsPage />
  }

  if (normalizedRoute === '/torneios/novo') {
    return (
      <ProtectedRoute>
        <SupabaseCreateTournamentPage />
      </ProtectedRoute>
    )
  }

  const editTournamentMatch = normalizedRoute.match(/^\/torneios\/([^/]+)\/editar$/)
  if (editTournamentMatch) {
    return (
      <ProtectedRoute>
        <SupabaseEditTournamentPage tournamentId={decodeURIComponent(editTournamentMatch[1])} />
      </ProtectedRoute>
    )
  }

  const participantsTournamentMatch = normalizedRoute.match(/^\/torneios\/([^/]+)\/participantes$/)
  if (participantsTournamentMatch) {
    return (
      <SupabaseTournamentParticipantsPage
        tournamentId={decodeURIComponent(participantsTournamentMatch[1])}
      />
    )
  }

  const bracketTournamentMatch = normalizedRoute.match(/^\/torneios\/([^/]+)\/chave$/)
  if (bracketTournamentMatch) {
    return (
      <SupabaseTournamentBracketPage
        tournamentId={decodeURIComponent(bracketTournamentMatch[1])}
      />
    )
  }

  const rankingTournamentMatch = normalizedRoute.match(/^\/torneios\/([^/]+)\/ranking$/)
  if (rankingTournamentMatch) {
    return (
      <SupabaseTournamentRankingPage
        tournamentId={decodeURIComponent(rankingTournamentMatch[1])}
      />
    )
  }

  const teamDetailsMatch = normalizedRoute.match(/^\/torneios\/([^/]+)\/equipes\/([^/]+)$/)
  if (teamDetailsMatch) {
    return (
      <ProtectedRoute>
        <SupabaseTeamDetailsPage
          tournamentId={decodeURIComponent(teamDetailsMatch[1])}
          teamId={decodeURIComponent(teamDetailsMatch[2])}
        />
      </ProtectedRoute>
    )
  }

  const teamsTournamentMatch = normalizedRoute.match(/^\/torneios\/([^/]+)\/equipes$/)
  if (teamsTournamentMatch) {
    return (
      <SupabaseTournamentTeamsPage
        tournamentId={decodeURIComponent(teamsTournamentMatch[1])}
      />
    )
  }

  const publicTournamentMatch = normalizedRoute.match(/^\/torneios\/([^/]+)$/)
  if (publicTournamentMatch) {
    return (
      <SupabasePublicTournamentPage
        tournamentId={decodeURIComponent(publicTournamentMatch[1])}
      />
    )
  }

  switch (normalizedRoute) {
    case '/login':
      return <LoginPage />
    case '/cadastro':
      return <RegisterPage />
    case '/recuperar-senha':
      return <PasswordRecoveryPage />
    case '/perfil':
    case '/minha-conta':
      return (
        <ProtectedRoute>
          <MyAccountPage />
        </ProtectedRoute>
      )
    case '/admin':
      return (
        <AdminRoute>
          <AdminHomePage />
        </AdminRoute>
      )
    case '/admin/pedidos':
      return (
        <AdminRoute>
          <AdminCreatorRequestsPage />
        </AdminRoute>
      )
    case '/solicitar-criacao-torneio':
      return (
        <ProtectedRoute>
          <RequestTournamentCreatorPage />
        </ProtectedRoute>
      )
    case '/meus-pedidos':
      return (
        <ProtectedRoute>
          <MyCreatorRequestsPage />
        </ProtectedRoute>
      )
    case '/minhas-inscricoes':
      return (
        <ProtectedRoute>
          <SupabaseMyRegistrationsPage />
        </ProtectedRoute>
      )
    case '/acesso-negado':
      return <AccessDeniedPage />
    default:
      return <TournamentDemoApp key={normalizedRoute} route={normalizedRoute} />
  }
}

function TournamentDemoApp({ route }: { route: string }) {
  const { session, canCreateTournaments } = useAuth()
  const [activePage, setActivePage] = useState<PageId>(() => getDemoPageFromRoute(route))
  const [query, setQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState<TournamentStatus | 'all'>('all')
  const [tournamentView, setTournamentView] = useState<TournamentView>('cards')
  const [publicTab, setPublicTab] = useState<PublicTab>('overview')
  const [groupTab, setGroupTab] = useState<GroupTab>('group-a')
  const [selectedFormat, setSelectedFormat] = useState(formats[3])
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [toast, setToast] = useState('')
  const [createErrors, setCreateErrors] = useState<string[]>([])
  const [resultError, setResultError] = useState('')

  const filteredTournaments = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase()

    return tournaments.filter((tournament) => {
      const matchesQuery =
        tournament.name.toLowerCase().includes(normalizedQuery) ||
        tournament.modality.toLowerCase().includes(normalizedQuery) ||
        tournament.campus.toLowerCase().includes(normalizedQuery)
      const matchesStatus =
        statusFilter === 'all' || tournament.status === statusFilter

      return matchesQuery && matchesStatus
    })
  }, [query, statusFilter])

  useEffect(() => {
    if (!toast) return

    const timer = window.setTimeout(() => setToast(''), 3600)
    return () => window.clearTimeout(timer)
  }, [toast])

  useEffect(() => {
    const handleKeyDown = (event: globalThis.KeyboardEvent) => {
      if (event.key === 'Escape') setIsModalOpen(false)
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  function navigateTo(page: PageId) {
    if (page === 'tournaments') {
      window.location.hash = '#/torneios'
      return
    }

    if (page === 'create' && !canCreateTournaments) {
      window.location.hash = session ? '#/solicitar-criacao-torneio' : '#/login'
      return
    }

    if (page === 'create') {
      window.location.hash = '#/torneios/novo'
      return
    }

    if (page === 'public') {
      window.location.hash = '#/torneios'
      return
    }

    window.location.hash = `#${page}`
    setActivePage(page)
  }

  function handleCreateSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const formData = new FormData(event.currentTarget)
    const name = String(formData.get('tournamentName') ?? '').trim()
    const modality = String(formData.get('modality') ?? '').trim()
    const startDate = String(formData.get('startDate') ?? '').trim()
    const errors: string[] = []

    if (name.length < 4) errors.push('Informe um nome com pelo menos 4 caracteres.')
    if (modality.length < 2) errors.push('Informe a modalidade do torneio.')
    if (!startDate) errors.push('Informe a data inicial.')

    setCreateErrors(errors)

    if (errors.length === 0) {
      setToast('Rascunho validado. O torneio está pronto para revisão.')
      event.currentTarget.reset()
    }
  }

  function handleResultSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const formData = new FormData(event.currentTarget)
    const scoreA = Number(formData.get('scoreA'))
    const scoreB = Number(formData.get('scoreB'))

    if (!Number.isInteger(scoreA) || !Number.isInteger(scoreB) || scoreA < 0 || scoreB < 0) {
      setResultError('Informe placares inteiros e não negativos.')
      return
    }

    if (scoreA === scoreB) {
      setResultError('Este mata-mata não permite empate. Informe o vencedor da série.')
      return
    }

    setResultError('')
    setIsModalOpen(true)
  }

  function renderPage() {
    switch (activePage) {
      case 'home':
        return <HomePage onNavigate={navigateTo} />
      case 'dashboard':
        return <DashboardPage onNavigate={navigateTo} />
      case 'tournaments':
        return (
          <TournamentListPage
            tournaments={filteredTournaments}
            query={query}
            statusFilter={statusFilter}
            view={tournamentView}
            onQueryChange={setQuery}
            onStatusFilterChange={setStatusFilter}
            onViewChange={setTournamentView}
          />
        )
      case 'create':
        return (
          <CreateTournamentPage
            errors={createErrors}
            selectedFormat={selectedFormat}
            onFormatChange={setSelectedFormat}
            onSubmit={handleCreateSubmit}
          />
        )
      case 'public':
        return (
          <PublicTournamentPage
            activeTab={publicTab}
            onTabChange={setPublicTab}
          />
        )
      case 'bracket':
        return <BracketPage onPublish={() => setIsModalOpen(true)} />
      case 'groups':
        return <GroupsPage activeTab={groupTab} onTabChange={setGroupTab} />
      case 'matches':
        return <MatchesPage />
      case 'result':
        return (
          <ResultPage
            error={resultError}
            onSubmit={handleResultSubmit}
            onCancel={() => setResultError('')}
          />
        )
      case 'empty':
        return <EmptyTournamentsPage onNavigate={navigateTo} />
    }
  }

  return (
    <div className="app-shell">
      <SiteHeader />
      <main className="app-main">
        {activePage !== 'home' && <PageBackButton fallbackHref="#home" />}
        {renderPage()}
      </main>

      <Toast message={toast} />

      <Modal
        isOpen={isModalOpen}
        title="Confirmar ação administrativa"
        onClose={() => setIsModalOpen(false)}
      >
        <p>
          Esta ação cria um registro de auditoria e pode atualizar chave,
          ranking ou página pública do torneio.
        </p>
        <div className="modal-actions">
          <button className="button button-secondary" type="button" onClick={() => setIsModalOpen(false)}>
            Revisar depois
          </button>
          <button
            className="button button-primary"
            type="button"
            onClick={() => {
              setIsModalOpen(false)
              setToast('Ação confirmada e registrada para auditoria.')
            }}
          >
            Confirmar ação
          </button>
        </div>
      </Modal>
    </div>
  )
}

function HomePage({ onNavigate }: { onNavigate: (page: PageId) => void }) {
  return (
    <div className="page-stack">
      <section className="hero-section" aria-labelledby="home-title">
        <div className="hero-content">
          <span className="eyebrow">Sistema acadêmico da UTFPR</span>
          <h1 id="home-title">UTFPR Torneios</h1>
          <p className="hero-copy">
            Uma base visual para organizar inscrições, equipes, chaves,
            partidas, resultados, rankings e disputas em torneios acadêmicos e
            e-sports.
          </p>
          <div className="hero-actions">
            <button className="button button-primary" type="button" onClick={() => onNavigate('dashboard')}>
              Abrir dashboard
            </button>
            <button className="button button-secondary" type="button" onClick={() => onNavigate('tournaments')}>
              Ver torneios
            </button>
          </div>
        </div>

        <aside className="hero-panel" aria-label="Resumo do torneio em destaque">
          <div className="panel-header">
            <TournamentStatusBadge status="registration_open" />
            <span>Grupos + playoffs</span>
          </div>
          <h2>Copa UTFPR Valorant</h2>
          <p>8 equipes, check-in obrigatório e ranking com critérios explícitos.</p>
          <div className="metric-grid compact">
            <MetricCard label="Inscritos" value="6/8" detail="2 vagas abertas" />
            <MetricCard label="Próxima etapa" value="26 mai" detail="Sorteio auditado" />
          </div>
        </aside>
      </section>

      <section className="content-grid three-columns" aria-label="Pilares do sistema">
        <RuleSummaryCard
          title="Justiça competitiva"
          description="Seeding, sorteio e desempates documentados para evitar ambiguidade."
        />
        <RuleSummaryCard
          title="Operação clara"
          description="Partidas com fase, rodada, horário, local, status e histórico de resultado."
        />
        <RuleSummaryCard
          title="Página pública"
          description="Chaves, grupos e rankings publicados com indicação de dados provisórios."
        />
      </section>
    </div>
  )
}

function DashboardPage({ onNavigate }: { onNavigate: (page: PageId) => void }) {
  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="Painel do organizador"
        title="Dashboard"
        description="Acompanhe inscrições, partidas, disputas e próximas ações dos torneios sob sua responsabilidade."
        action={
          <button className="button button-primary" type="button" onClick={() => onNavigate('create')}>
            Criar torneio
          </button>
        }
      />

      <section className="metric-grid" aria-label="Indicadores principais">
        <MetricCard label="Torneios ativos" value="3" detail="1 com inscrição aberta" />
        <MetricCard label="Equipes cadastradas" value="8" detail="6 com check-in" />
        <MetricCard label="Partidas hoje" value="4" detail="1 ao vivo" />
        <MetricCard label="Disputas abertas" value="1" detail="Requer decisão" tone="danger" />
      </section>

      <section className="dashboard-grid">
        <article className="surface-panel">
          <div className="section-heading">
            <h2>Ações pendentes</h2>
            <p>Fluxo operacional do próximo ciclo.</p>
          </div>
          <div className="action-list">
            <ScheduleItem title="Validar resultado contestado" meta="Semifinal - Gamma UTF x Omega Campus" status="contested" />
            <ScheduleItem title="Publicar chave provisória" meta="Copa UTFPR Valorant - playoffs" status="pending" />
            <ScheduleItem title="Confirmar check-in" meta="2 equipes ainda pendentes" status="live" />
          </div>
        </article>

        <article className="surface-panel">
          <div className="section-heading">
            <h2>Estados do sistema</h2>
            <p>Componentes base para feedback consistente.</p>
          </div>
          <div className="state-list">
            <LoadingState label="Sincronizando partidas..." />
            <ErrorState message="Uma disputa impede a publicação automática do ranking." />
          </div>
        </article>
      </section>
    </div>
  )
}

function TournamentListPage({
  tournaments: filtered,
  query,
  statusFilter,
  view,
  onQueryChange,
  onStatusFilterChange,
  onViewChange,
}: {
  tournaments: Tournament[]
  query: string
  statusFilter: TournamentStatus | 'all'
  view: TournamentView
  onQueryChange: (value: string) => void
  onStatusFilterChange: (value: TournamentStatus | 'all') => void
  onViewChange: (value: TournamentView) => void
}) {
  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="Catálogo"
        title="Lista de torneios"
        description="Busque torneios por nome, modalidade ou campus e alterne entre cards e tabela."
      />

      <section className="toolbar" aria-label="Filtros de torneios">
        <Field label="Busca local" htmlFor="tournament-search">
          <input
            id="tournament-search"
            type="search"
            value={query}
            onChange={(event) => onQueryChange(event.target.value)}
            placeholder="Ex.: Valorant, Xadrez, Curitiba"
          />
        </Field>

        <Field label="Status" htmlFor="status-filter">
          <select
            id="status-filter"
            value={statusFilter}
            onChange={(event) => onStatusFilterChange(event.target.value as TournamentStatus | 'all')}
          >
            <option value="all">Todos os status</option>
            <option value="registration_open">Inscrição aberta</option>
            <option value="running">Em andamento</option>
            <option value="finished">Encerrado</option>
          </select>
        </Field>

        <div className="segmented-control" aria-label="Alternar visualização">
          <button
            type="button"
            aria-pressed={view === 'cards'}
            onClick={() => onViewChange('cards')}
          >
            Cards
          </button>
          <button
            type="button"
            aria-pressed={view === 'table'}
            onClick={() => onViewChange('table')}
          >
            Tabela
          </button>
        </div>
      </section>

      {filtered.length === 0 ? (
        <EmptyState
          title="Nenhum torneio encontrado"
          description="Ajuste os filtros ou crie um novo torneio para iniciar a organização."
        />
      ) : view === 'cards' ? (
        <section className="content-grid tournament-grid" aria-label="Torneios encontrados">
          {filtered.map((tournament) => (
            <TournamentCard key={tournament.id} tournament={tournament} />
          ))}
        </section>
      ) : (
        <TournamentTable tournaments={filtered} />
      )}
    </div>
  )
}

function CreateTournamentPage({
  errors,
  selectedFormat,
  onFormatChange,
  onSubmit,
}: {
  errors: string[]
  selectedFormat: string
  onFormatChange: (value: string) => void
  onSubmit: (event: FormEvent<HTMLFormElement>) => void
}) {
  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="Novo torneio"
        title="Criar torneio"
        description="Configure a base do torneio com campos obrigatórios, formato competitivo e critérios de desempate."
      />

      {errors.length > 0 && (
        <Alert tone="danger" title="Revise os campos">
          <ul className="compact-list">
            {errors.map((error) => (
              <li key={error}>{error}</li>
            ))}
          </ul>
        </Alert>
      )}

      <form className="form-layout" onSubmit={onSubmit} noValidate>
        <section className="form-section" aria-labelledby="basic-data-title">
          <div className="section-heading">
            <h2 id="basic-data-title">Dados principais</h2>
            <p>Informações exibidas no painel e na página pública.</p>
          </div>
          <div className="form-grid">
            <Field label="Nome do torneio" htmlFor="tournament-name">
              <input id="tournament-name" name="tournamentName" type="text" placeholder="Copa UTFPR Valorant" />
            </Field>
            <Field label="Modalidade" htmlFor="modality">
              <input id="modality" name="modality" type="text" placeholder="Valorant, Xadrez, Futsal" />
            </Field>
            <Field label="Data inicial" htmlFor="start-date">
              <input id="start-date" name="startDate" type="date" />
            </Field>
            <Field label="Campus" htmlFor="campus">
              <select id="campus" name="campus" defaultValue="curitiba">
                <option value="curitiba">Curitiba</option>
                <option value="pato-branco">Pato Branco</option>
                <option value="campo-mourao">Campo Mourão</option>
              </select>
            </Field>
          </div>
          <Field label="Descrição pública" htmlFor="description">
            <textarea id="description" name="description" rows={4} placeholder="Explique regras gerais, público e contexto do torneio." />
          </Field>
        </section>

        <section className="form-section" aria-labelledby="format-title">
          <div className="section-heading">
            <h2 id="format-title">Formato e critérios</h2>
            <p>O MVP prioriza mata-mata, pontos corridos e grupos + playoffs.</p>
          </div>
          <FormatSelector value={selectedFormat} onChange={onFormatChange} />
          <TieBreakerList items={tieBreakers} />
        </section>

        <div className="form-actions">
          <button className="button button-secondary" type="reset">
            Limpar formulário
          </button>
          <button className="button button-primary" type="submit">
            Validar rascunho
          </button>
        </div>
      </form>
    </div>
  )
}

function PublicTournamentPage({
  activeTab,
  onTabChange,
}: {
  activeTab: PublicTab
  onTabChange: (tab: PublicTab) => void
}) {
  const tabs: Array<{ id: PublicTab; label: string }> = [
    { id: 'overview', label: 'Visão geral' },
    { id: 'participants', label: 'Participantes' },
    { id: 'rules', label: 'Regras' },
  ]

  return (
    <div className="page-stack">
      <section className="public-cover" aria-labelledby="public-title">
        <TournamentStatusBadge status="registration_open" />
        <h1 id="public-title">Copa UTFPR Valorant</h1>
        <p>
          Página pública com status de inscrições, agenda, participantes,
          formato, critérios de classificação e alertas de dados provisórios.
        </p>
      </section>

      <Tabs<PublicTab>
        tabs={tabs}
        activeTab={activeTab}
        onChange={onTabChange}
        ariaLabel="Seções públicas do torneio"
      />

      {activeTab === 'overview' && (
        <section className="content-grid two-columns">
          <RuleSummaryCard title="Formato" description="Fase de grupos seguida de semifinais e final melhor de 3." />
          <RuleSummaryCard title="Check-in" description="Equipes devem confirmar presença até 30 minutos antes da primeira partida." />
          <RuleSummaryCard title="Ranking" description="Pontos, vitórias, saldo de rounds, confronto direto e rounds marcados." />
          <RuleSummaryCard title="Integridade" description="Resultados podem ser contestados e correções ficam registradas." />
        </section>
      )}

      {activeTab === 'participants' && (
        <section className="content-grid tournament-grid" aria-label="Equipes participantes">
          {teams.map((team) => (
            <TeamCard key={team.id} team={team} />
          ))}
        </section>
      )}

      {activeTab === 'rules' && (
        <section className="surface-panel">
          <h2>Resumo do regulamento</h2>
          <ul className="rule-list">
            <li>Chave marcada como provisória até confirmação de check-in.</li>
            <li>W.O. exige justificativa e pode ser contestado dentro do prazo.</li>
            <li>Empate não resolvido deve ser exibido antes de decisão manual.</li>
            <li>Correções de resultado geram auditoria.</li>
          </ul>
        </section>
      )}
    </div>
  )
}

function BracketPage({ onPublish }: { onPublish: () => void }) {
  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="Mata-mata"
        title="Visualização de chave"
        description="Chave responsiva com status, placar, vencedor e indicação de dados provisórios."
        action={
          <button className="button button-primary" type="button" onClick={onPublish}>
            Publicar chave
          </button>
        }
      />
      <Alert tone="info" title="Chave provisória">
        A partida final depende da confirmação da segunda semifinal. Alterações posteriores serão registradas.
      </Alert>
      <section className="bracket" aria-label="Chave mata-mata">
        {bracketRounds.map((round) => (
          <BracketRound key={round.id} round={round} />
        ))}
      </section>
    </div>
  )
}

function GroupsPage({
  activeTab,
  onTabChange,
}: {
  activeTab: GroupTab
  onTabChange: (tab: GroupTab) => void
}) {
  const tabs: Array<{ id: GroupTab; label: string }> = groups.map((group) => ({
    id: group.id as GroupTab,
    label: group.name,
  }))
  const activeGroup = groups.find((group) => group.id === activeTab) ?? groups[0]

  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="Grupos e ranking"
        title="Classificação por grupos"
        description="Tabela limpa com critérios explícitos e indicação de desempate aplicado."
      />
      <Tabs<GroupTab>
        tabs={tabs}
        activeTab={activeTab}
        onChange={onTabChange}
        ariaLabel="Selecionar grupo"
      />
      <GroupPanel group={activeGroup} />
      <RankingTable title="Ranking geral provisório" rows={ranking} />
    </div>
  )
}

function MatchesPage() {
  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="Agenda"
        title="Lista de partidas"
        description="Partidas com fase, rodada, horário, local/servidor e status operacional."
      />
      <section className="content-grid two-columns" aria-label="Partidas do torneio">
        {matches.map((match) => (
          <MatchCard key={match.id} match={match} />
        ))}
      </section>
    </div>
  )
}

function ResultPage({
  error,
  onSubmit,
  onCancel,
}: {
  error: string
  onSubmit: (event: FormEvent<HTMLFormElement>) => void
  onCancel: () => void
}) {
  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="Resultado"
        title="Registrar resultado"
        description="Validação básica impede placares negativos e empate em mata-mata."
      />
      <section className="result-layout">
        <MatchCard match={matches[0]} />
        <form className="form-section" onSubmit={onSubmit} noValidate>
          <div className="section-heading">
            <h2>Placar final</h2>
            <p>Informe o placar agregado após a série.</p>
          </div>
          {error && (
            <Alert tone="danger" title="Resultado inválido">
              {error}
            </Alert>
          )}
          <div className="score-form-grid">
            <Field label="Placar Aurora Tech" htmlFor="score-a">
              <input id="score-a" name="scoreA" type="number" min="0" defaultValue="13" />
            </Field>
            <Field label="Placar Vector Sul" htmlFor="score-b">
              <input id="score-b" name="scoreB" type="number" min="0" defaultValue="8" />
            </Field>
          </div>
          <Field label="Observações do resultado" htmlFor="result-note">
            <textarea id="result-note" name="note" rows={4} placeholder="Inclua evidências, links ou observações para auditoria." />
          </Field>
          <div className="form-actions">
            <button className="button button-ghost" type="button" onClick={onCancel}>
              Limpar alerta
            </button>
            <button className="button button-primary" type="submit">
              Enviar para confirmação
            </button>
          </div>
        </form>
      </section>
    </div>
  )
}

function EmptyTournamentsPage({ onNavigate }: { onNavigate: (page: PageId) => void }) {
  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="Estado vazio"
        title="Nenhum torneio cadastrado"
        description="Modelo para quando o organizador ainda não criou torneios no sistema."
      />
      <EmptyState
        title="Comece pelo primeiro torneio"
        description="Crie um rascunho com formato, inscrições e critérios de desempate antes de publicar."
        action={
          <button className="button button-primary" type="button" onClick={() => onNavigate('create')}>
            Criar primeiro torneio
          </button>
        }
      />
    </div>
  )
}

function PageHeader({
  eyebrow,
  title,
  description,
  action,
}: {
  eyebrow: string
  title: string
  description: string
  action?: ReactNode
}) {
  return (
    <section className="page-header" aria-labelledby={`${title.toLowerCase().replaceAll(' ', '-')}-title`}>
      <div>
        <span className="eyebrow">{eyebrow}</span>
        <h1 id={`${title.toLowerCase().replaceAll(' ', '-')}-title`}>{title}</h1>
        <p>{description}</p>
      </div>
      {action && <div className="page-header-action">{action}</div>}
    </section>
  )
}

function MetricCard({
  label,
  value,
  detail,
  tone = 'default',
}: {
  label: string
  value: string
  detail: string
  tone?: 'default' | 'danger'
}) {
  return (
    <article className={`metric-card tone-${tone}`}>
      <span>{label}</span>
      <strong>{value}</strong>
      <p>{detail}</p>
    </article>
  )
}

function Field({
  label,
  htmlFor,
  children,
}: {
  label: string
  htmlFor: string
  children: ReactNode
}) {
  return (
    <label className="field" htmlFor={htmlFor}>
      <span>{label}</span>
      {children}
    </label>
  )
}

function TournamentCard({ tournament }: { tournament: Tournament }) {
  return (
    <article className="tournament-card">
      <div className="card-topline">
        <TournamentStatusBadge status={tournament.status} />
        <span>{tournament.campus}</span>
      </div>
      <h2>{tournament.name}</h2>
      <p>{tournament.description}</p>
      <dl className="definition-grid">
        <div>
          <dt>Modalidade</dt>
          <dd>{tournament.modality}</dd>
        </div>
        <div>
          <dt>Formato</dt>
          <dd>{tournament.format}</dd>
        </div>
        <div>
          <dt>Equipes</dt>
          <dd>{tournament.registrations}/{tournament.teams}</dd>
        </div>
        <div>
          <dt>Início</dt>
          <dd>{tournament.startsAt}</dd>
        </div>
      </dl>
      <div className="card-actions">
        <button className="button button-secondary" type="button">
          Ver detalhes
        </button>
        <button className="button button-ghost" type="button">
          Gerenciar
        </button>
      </div>
    </article>
  )
}

function TournamentStatusBadge({ status }: { status: TournamentStatus }) {
  return <Badge tone={status}>{tournamentStatusText[status]}</Badge>
}

function MatchCard({ match }: { match: Match }) {
  return (
    <article className="match-card">
      <div className="card-topline">
        <Badge tone={match.status}>{matchStatusText[match.status]}</Badge>
        <span>{match.phase} · {match.round}</span>
      </div>
      <MatchScore match={match} />
      <dl className="match-meta">
        <div>
          <dt>Horário</dt>
          <dd>{match.scheduledAt}</dd>
        </div>
        <div>
          <dt>Local/servidor</dt>
          <dd>{match.venue}</dd>
        </div>
      </dl>
    </article>
  )
}

function MatchScore({ match }: { match: Pick<Match, 'teamA' | 'teamB' | 'scoreA' | 'scoreB'> }) {
  return (
    <div className="match-score" aria-label={`${match.teamA} contra ${match.teamB}`}>
      <span>{match.teamA}</span>
      <strong>{match.scoreA ?? '-'}</strong>
      <span className="score-divider">x</span>
      <strong>{match.scoreB ?? '-'}</strong>
      <span>{match.teamB}</span>
    </div>
  )
}

function BracketRound({ round }: { round: BracketRoundData }) {
  return (
    <section className="bracket-round" aria-labelledby={`${round.id}-title`}>
      <h2 id={`${round.id}-title`}>{round.title}</h2>
      <div className="bracket-round-stack">
        {round.matches.map((match) => (
          <BracketMatch key={match.id} match={match} />
        ))}
      </div>
    </section>
  )
}

function BracketMatch({ match }: { match: BracketMatchData }) {
  return (
    <article className="bracket-match">
      <div className="card-topline">
        <span>{match.label}</span>
        <Badge tone={match.status}>{matchStatusText[match.status]}</Badge>
      </div>
      <div className="bracket-slots">
        <BracketSlot team={match.teamA} score={match.scoreA} winner={match.winner === match.teamA} />
        <BracketSlot team={match.teamB} score={match.scoreB} winner={match.winner === match.teamB} />
      </div>
    </article>
  )
}

function BracketSlot({
  team,
  score,
  winner,
}: {
  team: string
  score?: number
  winner: boolean
}) {
  return (
    <div className={winner ? 'bracket-slot is-winner' : 'bracket-slot'}>
      <span>{team}</span>
      <strong>{score ?? '-'}</strong>
    </div>
  )
}

function RankingTable({ title, rows }: { title: string; rows: RankingRow[] }) {
  return (
    <section className="surface-panel">
      <div className="section-heading">
        <h2>{title}</h2>
        <p>Critérios: pontos, vitórias, saldo, confronto direto e pontos marcados.</p>
      </div>
      <div className="table-scroll">
        <table>
          <thead>
            <tr>
              <th scope="col">Pos.</th>
              <th scope="col">Equipe</th>
              <th scope="col">Pts</th>
              <th scope="col">V</th>
              <th scope="col">E</th>
              <th scope="col">D</th>
              <th scope="col">Saldo</th>
              <th scope="col">Marcados</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={`${row.position}-${row.team}`}>
                <td>{row.position}</td>
                <th scope="row">{row.team}{row.note ? <span className="row-note">{row.note}</span> : null}</th>
                <td>{row.points}</td>
                <td>{row.wins}</td>
                <td>{row.draws}</td>
                <td>{row.losses}</td>
                <td>{row.scoreDiff}</td>
                <td>{row.scoreFor}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}

function ParticipantCard({ name, meta }: { name: string; meta: string }) {
  return (
    <article className="participant-card">
      <span className="avatar" aria-hidden="true">{name.slice(0, 2).toUpperCase()}</span>
      <div>
        <h3>{name}</h3>
        <p>{meta}</p>
      </div>
    </article>
  )
}

function TeamCard({ team }: { team: Team }) {
  return (
    <article className="team-card">
      <div className="card-topline">
        <span>Seed #{team.seed}</span>
        <Badge tone={team.checkedIn ? 'success' : 'pending'}>
          {team.checkedIn ? 'Check-in confirmado' : 'Check-in pendente'}
        </Badge>
      </div>
      <h2>{team.name}</h2>
      <ParticipantCard name={team.captain} meta={`Capitão · ${team.members} membros`} />
    </article>
  )
}

function ScheduleItem({
  title,
  meta,
  status,
}: {
  title: string
  meta: string
  status: MatchStatus
}) {
  return (
    <article className="schedule-item">
      <Badge tone={status}>{matchStatusText[status]}</Badge>
      <div>
        <h3>{title}</h3>
        <p>{meta}</p>
      </div>
    </article>
  )
}

function RuleSummaryCard({ title, description }: { title: string; description: string }) {
  return (
    <article className="rule-card">
      <span className="rule-marker" aria-hidden="true" />
      <h2>{title}</h2>
      <p>{description}</p>
    </article>
  )
}

function FormatSelector({
  value,
  onChange,
}: {
  value: string
  onChange: (value: string) => void
}) {
  return (
    <fieldset className="format-selector">
      <legend>Formato competitivo</legend>
      {formats.map((format) => (
        <label key={format} className="format-option">
          <input
            type="radio"
            name="format"
            value={format}
            checked={value === format}
            onChange={(event) => onChange(event.target.value)}
          />
          <span>{format}</span>
        </label>
      ))}
    </fieldset>
  )
}

function TieBreakerList({ items }: { items: string[] }) {
  return (
    <section className="tie-breakers" aria-labelledby="tie-breakers-title">
      <h3 id="tie-breakers-title">Critérios de desempate</h3>
      <ol>
        {items.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ol>
    </section>
  )
}

function TournamentTable({ tournaments: tableRows }: { tournaments: Tournament[] }) {
  return (
    <section className="surface-panel">
      <div className="table-scroll">
        <table>
          <thead>
            <tr>
              <th scope="col">Torneio</th>
              <th scope="col">Modalidade</th>
              <th scope="col">Status</th>
              <th scope="col">Formato</th>
              <th scope="col">Inscrições</th>
            </tr>
          </thead>
          <tbody>
            {tableRows.map((tournament) => (
              <tr key={tournament.id}>
                <th scope="row">{tournament.name}</th>
                <td>{tournament.modality}</td>
                <td><TournamentStatusBadge status={tournament.status} /></td>
                <td>{tournament.format}</td>
                <td>{tournament.registrations}/{tournament.teams}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}

function GroupPanel({ group }: { group: GroupTable }) {
  return <RankingTable title={group.name} rows={group.rows} />
}

function Tabs<T extends string>({
  tabs,
  activeTab,
  onChange,
  ariaLabel,
}: {
  tabs: Array<{ id: T; label: string }>
  activeTab: T
  onChange: (tab: T) => void
  ariaLabel: string
}) {
  function handleKeyDown(event: KeyboardEvent<HTMLDivElement>) {
    const currentIndex = tabs.findIndex((tab) => tab.id === activeTab)
    const lastIndex = tabs.length - 1

    if (event.key === 'ArrowRight') {
      event.preventDefault()
      onChange(tabs[currentIndex === lastIndex ? 0 : currentIndex + 1].id)
    }

    if (event.key === 'ArrowLeft') {
      event.preventDefault()
      onChange(tabs[currentIndex === 0 ? lastIndex : currentIndex - 1].id)
    }
  }

  return (
    <div className="tabs" role="tablist" aria-label={ariaLabel} onKeyDown={handleKeyDown}>
      {tabs.map((tab) => (
        <button
          key={tab.id}
          type="button"
          role="tab"
          aria-selected={activeTab === tab.id}
          tabIndex={activeTab === tab.id ? 0 : -1}
          onClick={() => onChange(tab.id)}
        >
          {tab.label}
        </button>
      ))}
    </div>
  )
}

function Badge({
  tone,
  children,
}: {
  tone: TournamentStatus | MatchStatus | 'success'
  children: ReactNode
}) {
  return <span className={`badge badge-${tone}`}>{children}</span>
}

function Alert({
  title,
  tone,
  children,
}: {
  title: string
  tone: 'info' | 'danger'
  children: ReactNode
}) {
  return (
    <section className={`alert alert-${tone}`} role={tone === 'danger' ? 'alert' : 'status'}>
      <strong>{title}</strong>
      <div>{children}</div>
    </section>
  )
}

function EmptyState({
  title,
  description,
  action,
}: {
  title: string
  description: string
  action?: ReactNode
}) {
  return (
    <section className="empty-state">
      <span className="empty-state-mark" aria-hidden="true">0</span>
      <h2>{title}</h2>
      <p>{description}</p>
      {action}
    </section>
  )
}

function LoadingState({ label }: { label: string }) {
  return (
    <div className="loading-state" role="status" aria-live="polite">
      <span className="spinner" aria-hidden="true" />
      <span>{label}</span>
    </div>
  )
}

function ErrorState({ message }: { message: string }) {
  return (
    <div className="error-state" role="alert">
      <strong>Atenção</strong>
      <span>{message}</span>
    </div>
  )
}

function Toast({ message }: { message: string }) {
  return (
    <div className={message ? 'toast is-visible' : 'toast'} role="status" aria-live="polite">
      {message}
    </div>
  )
}

function Modal({
  isOpen,
  title,
  children,
  onClose,
}: {
  isOpen: boolean
  title: string
  children: ReactNode
  onClose: () => void
}) {
  const closeButtonRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    if (isOpen) closeButtonRef.current?.focus()
  }, [isOpen])

  if (!isOpen) return null

  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={(event) => {
      if (event.target === event.currentTarget) onClose()
    }}>
      <section className="modal-panel" role="dialog" aria-modal="true" aria-labelledby="modal-title">
        <button ref={closeButtonRef} className="button button-ghost modal-close" type="button" onClick={onClose}>
          Fechar
        </button>
        <h2 id="modal-title">{title}</h2>
        {children}
      </section>
    </div>
  )
}

export default App
