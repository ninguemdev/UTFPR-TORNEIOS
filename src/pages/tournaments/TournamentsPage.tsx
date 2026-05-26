import { useCallback, useEffect, useMemo, useState } from 'react'
import { SupabaseTournamentStatusBadge } from '../../components/tournament/TournamentStatusBadge'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import { useAuth } from '../../context/auth'
import type { TournamentStatus } from '../../lib/supabase/types'
import {
  canDeleteTournament,
  canManageTournament,
  deleteTournament,
  fetchTournaments,
  tournamentFormatLabels,
  tournamentStatusLabels,
  type TournamentWithCount,
} from '../../services/tournaments'

type StatusFilter = TournamentStatus | 'all'

export function TournamentsPage() {
  const { user, isAdmin, canCreateTournaments } = useAuth()
  const [tournaments, setTournaments] = useState<TournamentWithCount[]>([])
  const [query, setQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')

  const loadTournaments = useCallback(async () => {
    setIsLoading(true)
    setError('')

    try {
      setTournaments(await fetchTournaments())
    } catch (loadError) {
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Não foi possível carregar torneios.',
      )
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadTournaments()
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadTournaments])

  const filteredTournaments = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase()

    return tournaments.filter((tournament) => {
      const matchesQuery =
        tournament.name.toLowerCase().includes(normalizedQuery) ||
        tournament.modality.toLowerCase().includes(normalizedQuery) ||
        (tournament.campus ?? '').toLowerCase().includes(normalizedQuery)
      const matchesStatus =
        statusFilter === 'all' || tournament.status === statusFilter

      return matchesQuery && matchesStatus
    })
  }, [query, statusFilter, tournaments])

  async function handleDelete(tournament: TournamentWithCount) {
    if (!window.confirm(`Excluir o torneio "${tournament.name}"?`)) return

    setError('')

    try {
      await deleteTournament(tournament.id)
      await loadTournaments()
    } catch (deleteError) {
      setError(
        deleteError instanceof Error
          ? deleteError.message
          : 'Não foi possível excluir o torneio.',
      )
    }
  }

  return (
    <AuthenticatedShell subtitle="Torneios">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="tournaments-title">
          <div>
            <span className="eyebrow">Supabase</span>
            <h1 id="tournaments-title">Torneios</h1>
            <p>
              Lista real de torneios com RLS: drafts ficam visíveis apenas para
              admin ou criador, e torneios públicos aparecem para todos.
            </p>
          </div>
          <div className="page-header-action">
            {canCreateTournaments ? (
              <a className="button button-primary" href="#/torneios/novo">
                Criar torneio
              </a>
            ) : (
              <a className="button button-secondary" href={user ? '#/solicitar-criacao-torneio' : '#/login'}>
                Solicitar criação
              </a>
            )}
          </div>
        </section>

        <section className="toolbar" aria-label="Filtros de torneios">
          <label className="field" htmlFor="real-tournament-search">
            <span>Busca</span>
            <input
              id="real-tournament-search"
              type="search"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Nome, modalidade ou campus"
            />
          </label>

          <label className="field" htmlFor="real-tournament-status">
            <span>Status</span>
            <select
              id="real-tournament-status"
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value as StatusFilter)}
            >
              <option value="all">Todos</option>
              {Object.entries(tournamentStatusLabels).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </label>
        </section>

        {error && (
          <div className="form-message form-message-error" role="alert">
            {error}
          </div>
        )}

        {isLoading ? (
          <div className="loading-state" role="status" aria-live="polite">
            <span className="spinner" aria-hidden="true" />
            <span>Carregando torneios...</span>
          </div>
        ) : filteredTournaments.length === 0 ? (
          <section className="empty-state">
            <span className="empty-state-mark" aria-hidden="true">0</span>
            <h2>Nenhum torneio encontrado</h2>
            <p>Crie um torneio ou ajuste os filtros da lista.</p>
          </section>
        ) : (
          <section className="content-grid tournament-grid" aria-label="Torneios cadastrados">
            {filteredTournaments.map((tournament) => {
              const canManage = canManageTournament(
                tournament,
                user?.id,
                isAdmin,
                canCreateTournaments,
              )
              const canDelete = canDeleteTournament(isAdmin)

              return (
                <article className="tournament-card" key={tournament.id}>
                  <div className="card-topline">
                    <SupabaseTournamentStatusBadge status={tournament.status} />
                    <span>{tournament.campus || 'Campus não informado'}</span>
                  </div>
                  <h2>{tournament.name}</h2>
                  <p>{tournament.description || 'Sem descrição pública.'}</p>
                  <dl className="definition-grid">
                    <div>
                      <dt>Modalidade</dt>
                      <dd>{tournament.modality}</dd>
                    </div>
                    <div>
                      <dt>Formato</dt>
                      <dd>{tournamentFormatLabels[tournament.format] ?? tournament.format}</dd>
                    </div>
                    <div>
                      <dt>Inscritos</dt>
                      <dd>{tournament.registrationCount}/{tournament.max_participants}</dd>
                    </div>
                    <div>
                      <dt>Início</dt>
                      <dd>{tournament.starts_at || 'A definir'}</dd>
                    </div>
                  </dl>
                  <div className="card-actions">
                    <a className="button button-secondary" href={`#/torneios/${tournament.id}`}>
                      Página pública
                    </a>
                    <a className="button button-ghost" href={`#/torneios/${tournament.id}/participantes`}>
                      Participantes
                    </a>
                    <a className="button button-ghost" href={`#/torneios/${tournament.id}/chave`}>
                      Chave
                    </a>
                    <a className="button button-ghost" href={`#/torneios/${tournament.id}/ranking`}>
                      Ranking
                    </a>
                    {tournament.registration_type === 'team' && (
                      <a className="button button-ghost" href={`#/torneios/${tournament.id}/equipes`}>
                        Equipes
                      </a>
                    )}
                    {canManage && (
                      <a className="button button-ghost" href={`#/torneios/${tournament.id}/editar`}>
                        Editar
                      </a>
                    )}
                    {canDelete && (
                      <button
                        className="button button-ghost"
                        type="button"
                        onClick={() => void handleDelete(tournament)}
                      >
                        Excluir
                      </button>
                    )}
                  </div>
                </article>
              )
            })}
          </section>
        )}
      </div>
    </AuthenticatedShell>
  )
}
