import { useCallback, useEffect, useState } from 'react'
import { AuthenticatedShell } from '../../components/layout/AuthenticatedShell'
import { SupabaseTournamentStatusBadge } from '../../components/tournament/TournamentStatusBadge'
import { useAuth } from '../../context/auth'
import type { RankingEntry } from '../../lib/tournaments/ranking'
import {
  canManageTournament,
  tournamentFormatLabels,
} from '../../services/tournaments'
import {
  fetchTournamentRanking,
  type TournamentRankingData,
} from '../../services/rankings'

export function TournamentRankingPage({ tournamentId }: { tournamentId: string }) {
  const { user, isAdmin, canCreateTournaments } = useAuth()
  const [rankingData, setRankingData] = useState<TournamentRankingData | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isRecalculating, setIsRecalculating] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const loadRanking = useCallback(async () => {
    setError('')

    try {
      setRankingData(await fetchTournamentRanking(tournamentId))
    } catch (loadError) {
      setRankingData(null)
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Nao foi possivel carregar o ranking.',
      )
    }
  }, [tournamentId])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setIsLoading(true)
      void loadRanking().finally(() => setIsLoading(false))
    }, 0)

    return () => window.clearTimeout(timer)
  }, [loadRanking])

  const canManage = rankingData
    ? canManageTournament(
        rankingData.tournament,
        user?.id,
        isAdmin,
        canCreateTournaments,
      )
    : false

  async function handleRecalculate() {
    setIsRecalculating(true)
    setSuccess('')

    try {
      await loadRanking()
      setSuccess('Ranking recalculado a partir dos resultados confirmados.')
    } finally {
      setIsRecalculating(false)
    }
  }

  return (
    <AuthenticatedShell subtitle="Ranking">
      <div className="page-stack">
        <section className="page-header" aria-labelledby="ranking-title">
          <div>
            <span className="eyebrow">Classificacao</span>
            <h1 id="ranking-title">Ranking</h1>
            <p>
              Pontuacao e desempates calculados a partir de partidas
              finalizadas e resultados nao contestados.
            </p>
          </div>
          {rankingData && (
            <div className="page-header-action">
              <SupabaseTournamentStatusBadge status={rankingData.tournament.status} />
            </div>
          )}
        </section>

        {error && (
          <div className="form-message form-message-error" role="alert">
            {error}
          </div>
        )}
        {success && (
          <div className="form-message form-message-success" role="status">
            {success}
          </div>
        )}

        {isLoading ? (
          <div className="loading-state" role="status" aria-live="polite">
            <span className="spinner" aria-hidden="true" />
            <span>Carregando ranking...</span>
          </div>
        ) : !rankingData ? (
          <section className="empty-state">
            <span className="empty-state-mark" aria-hidden="true">?</span>
            <h2>Ranking indisponivel</h2>
            <p>O torneio nao existe ou voce nao tem permissao para ver a classificacao.</p>
            <a className="button button-primary" href="#/torneios">
              Ver torneios
            </a>
          </section>
        ) : (
          <>
            <section className="surface-panel">
              <div className="section-heading">
                <h2>{rankingData.tournament.name}</h2>
                <p>
                  Formato: {tournamentFormatLabels[rankingData.tournament.format] ?? rankingData.tournament.format}.
                  Pontos: vitoria {rankingData.ranking.scoring.winPoints}, empate {rankingData.ranking.scoring.drawPoints},
                  derrota {rankingData.ranking.scoring.lossPoints}.
                </p>
              </div>
              <div className="ranking-meta-grid">
                <div>
                  <strong>{rankingData.participants.length}</strong>
                  <span>participantes elegiveis</span>
                </div>
                <div>
                  <strong>{rankingData.ranking.countedMatchesCount}</strong>
                  <span>partidas contabilizadas</span>
                </div>
                <div>
                  <strong>{rankingData.ranking.ignoredMatchesCount}</strong>
                  <span>partidas ignoradas</span>
                </div>
              </div>
              {canManage && (
                <div className="form-actions">
                  <button
                    className="button button-secondary"
                    type="button"
                    disabled={isRecalculating}
                    onClick={() => void handleRecalculate()}
                  >
                    {isRecalculating ? 'Recalculando...' : 'Recalcular ranking'}
                  </button>
                </div>
              )}
            </section>

            <section className="surface-panel">
              <div className="section-heading">
                <h2>Criterios de desempate</h2>
                <p>{rankingData.ranking.criteriaSummary}</p>
              </div>
              <ol className="criteria-list">
                {rankingData.ranking.criteria.map((criterion) => (
                  <li key={criterion}>{criterion}</li>
                ))}
              </ol>
              <p className="subtle-note">
                Partidas pendentes, canceladas, com bye ou contestadas nao entram no calculo.
              </p>
            </section>

            {!rankingData.isSupportedFormat && rankingData.unsupportedReason && (
              <div className="form-message form-message-info" role="status">
                {rankingData.unsupportedReason}
              </div>
            )}

            {rankingData.ranking.hasTechnicalTies && (
              <div className="form-message form-message-info" role="status">
                Ha empate tecnico apos os criterios principais. Seed/nome so estabiliza a exibicao.
              </div>
            )}

            {rankingData.ranking.entries.length === 0 || rankingData.ranking.countedMatchesCount === 0 ? (
              <section className="empty-state">
                <span className="empty-state-mark" aria-hidden="true">0</span>
                <h2>Sem partidas finalizadas para ranking</h2>
                <p>
                  Quando houver partidas de tabela finalizadas e sem contestacao,
                  a classificacao aparecera aqui.
                </p>
              </section>
            ) : (
              <RankingTable entries={rankingData.ranking.entries} />
            )}
          </>
        )}
      </div>
    </AuthenticatedShell>
  )
}

function RankingTable({ entries }: { entries: RankingEntry[] }) {
  return (
    <section className="surface-panel" aria-labelledby="ranking-table-title">
      <div className="section-heading">
        <h2 id="ranking-table-title">Tabela de classificacao</h2>
        <p>
          Legenda: Pts pontos, J jogos, V vitorias, E empates, D derrotas,
          Pro score a favor, Contra score sofrido, SG saldo de score.
        </p>
      </div>
      <div className="table-scroll ranking-table-scroll">
        <table>
          <thead>
            <tr>
              <th scope="col">Pos.</th>
              <th scope="col">Participante</th>
              <th scope="col">Pts</th>
              <th scope="col">J</th>
              <th scope="col">V</th>
              <th scope="col">E</th>
              <th scope="col">D</th>
              <th scope="col">Pro</th>
              <th scope="col">Contra</th>
              <th scope="col">SG</th>
              <th scope="col">Desempate</th>
            </tr>
          </thead>
          <tbody>
            {entries.map((entry) => (
              <tr key={entry.participantId}>
                <td>{entry.position}</td>
                <th scope="row">
                  <span className="table-title">{entry.displayName}</span>
                  {entry.isTechnicalTie && (
                    <span className="row-note">Empate tecnico</span>
                  )}
                </th>
                <td>{entry.points}</td>
                <td>{entry.played}</td>
                <td>{entry.wins}</td>
                <td>{entry.draws}</td>
                <td>{entry.losses}</td>
                <td>{entry.scoreFor}</td>
                <td>{entry.scoreAgainst}</td>
                <td>{entry.scoreDiff}</td>
                <td>{entry.tieBreakerSummary}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}
