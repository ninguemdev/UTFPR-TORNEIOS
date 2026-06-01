# Formatos e algoritmos

## Mata-mata simples

### Quando usar

Usar quando há pouco tempo, número moderado de participantes e necessidade de eliminação rápida. É simples de entender, mas menos tolerante a partidas ruins isoladas.

### Como gerar chave

1. Validar participantes elegíveis e confirmados.
2. Definir tamanho da chave como próxima potência de 2.
3. Distribuir participantes em posições.
4. Criar byes quando houver vagas vazias.
5. Gerar partidas da primeira rodada.
6. Criar nós futuros da chave sem participantes definidos.

### Número ímpar e byes

Quando o total não fecha potência de 2, alguns participantes avançam automaticamente. Byes devem ser distribuídos de forma justa. Com seeding, cabeças de chave recebem byes antes dos demais. Com sorteio puro, byes são sorteados e registrados.

### Seeding

O seeding distribui os melhores participantes em lados opostos da chave. Para 8 participantes, uma ordem comum de sementes é:

```text
1 vs 8
4 vs 5
3 vs 6
2 vs 7
```

### Avanço de vencedores

Ao confirmar resultado, o vencedor é inserido no próximo nó da chave. O perdedor é eliminado, salvo se houver disputa de terceiro lugar ou outro formato híbrido.

### Terceiro lugar

Se habilitado, os perdedores das semifinais geram uma partida adicional. Essa partida não afeta campeão e vice, mas define terceira colocação.

### Melhor de N

Em série melhor de 3, 5 ou 7, a partida contém jogos internos (`MatchGame`). Vence quem atinge:

- Melhor de 3: 2 vitórias.
- Melhor de 5: 3 vitórias.
- Melhor de 7: 4 vitórias.

## Pontos corridos / Round robin

### Quando usar

Usar quando o objetivo é aumentar justiça e eficácia, permitindo que todos enfrentem todos. Exige mais partidas.

### Como gerar partidas

- Cada participante enfrenta todos os outros uma vez.
- Em turno e returno, cada par gera duas partidas.
- Com número ímpar, adicionar uma folga por rodada.

### Como calcular tabela

A tabela deve somar resultados confirmados:

- Pontos.
- Jogos.
- Vitórias.
- Empates.
- Derrotas.
- Pontos/gols/rounds pró.
- Pontos/gols/rounds contra.
- Saldo.

### Critérios de desempate

Ordem padrão recomendada:

1. Pontos.
2. Vitórias.
3. Saldo.
4. Pontos marcados.
5. Confronto direto.
6. Menos W.O.
7. Sorteio ou decisão manual registrada.

### Pontuação padrão

- Vitória: 3 pontos.
- Empate: 1 ponto.
- Derrota: 0 ponto.
- W.O.: configurável por modalidade.

### Pontuação customizada

O organizador pode configurar pontuação por vitória, empate, derrota, bônus, penalidades e W.O. O ranking deve exibir a configuração usada.

## Grupos + playoffs

### Divisão de grupos

Participantes são distribuídos em grupos de tamanho semelhante. Com seeding, cabeças de chave devem ir para grupos diferentes antes do preenchimento restante.

### Classificação para playoffs

O organizador define quantos avançam por grupo. Exemplo: os dois melhores de cada grupo avançam para quartas de final.

### Evitar desequilíbrio

- Distribuir sementes em grupos diferentes.
- Evitar concentração de participantes do mesmo ranking, curso ou equipe base quando essa regra existir.
- Registrar método de distribuição.

### Chave final

Classificados alimentam uma chave eliminatória. Uma regra comum é cruzar primeiro de um grupo contra segundo de outro, evitando revanche imediata quando possível.

## Sistema suíço

Sistema suíço é recurso futuro ou avançado.

### Características

- Número fixo de rodadas.
- Pareamento entre participantes com pontuação semelhante.
- Evita repetir confrontos.
- Não elimina participantes após derrota.
- Classificação final depende de pontuação e desempates.

### Critérios como Buchholz

Buchholz mede a força dos oponentes enfrentados, somando a pontuação desses oponentes. É útil quando participantes não enfrentam todos.

### Limitações para o MVP

- Pareamento suíço exige cuidado para evitar repetição e viés.
- Buchholz precisa de resultados estáveis e regras claras para W.O.
- Deve ser implementado apenas depois de mata-mata, round robin e grupos estarem testados.

## Algoritmos

### Gerar chave mata-mata

```text
func gerarChave(participantes, configuracao):
  elegiveis = filtrarParticipantesConfirmados(participantes)
  tamanhoChave = proximaPotenciaDeDois(total(elegiveis))
  posicoes = criarListaComVagas(tamanhoChave)

  se configuracao.usarSeeding:
    ordenados = ordenarPorSeed(elegiveis)
    posicoes = aplicarSeeding(ordenados, tamanhoChave)
  senao se configuracao.usarSorteio:
    posicoes = sortearParticipantes(elegiveis, tamanhoChave)
  senao:
    posicoes = preencherNaOrdem(elegiveis, tamanhoChave)

  partidas = criarPrimeiraRodada(posicoes)
  avancarByesAutomaticamente(partidas)
  criarRodadasFuturas(tamanhoChave)
  retornar chave
```

### Aplicar seeding

```text
func aplicarSeeding(participantesOrdenados, tamanhoChave):
  mapa = gerarMapaDeSeeds(tamanhoChave)
  posicoes = listaVazia(tamanhoChave)

  para cada participante em participantesOrdenados:
    seed = participante.seed
    posicao = mapa[seed]
    posicoes[posicao] = participante

  retornar posicoes
```

### Aplicar sorteio

```text
func sortearParticipantes(participantes, tamanhoChave):
  embaralhados = shuffle(participantes)
  posicoes = listaVazia(tamanhoChave)

  para indice de 0 ate total(embaralhados) - 1:
    posicoes[indice] = embaralhados[indice]

  registrarAuditoria("draw", embaralhados)
  retornar posicoes
```

### Gerar pontos corridos

```text
func gerarRoundRobin(participantes):
  lista = copiar(participantes)
  se total(lista) for impar:
    adicionar BYE na lista

  rodadas = []
  para rodada de 1 ate total(lista) - 1:
    partidas = []
    para i de 0 ate total(lista) / 2 - 1:
      mandante = lista[i]
      visitante = lista[total(lista) - 1 - i]
      se mandante != BYE e visitante != BYE:
        partidas.adicionar(criarPartida(mandante, visitante, rodada))
    rodadas.adicionar(partidas)
    lista = rotacionarMantendoPrimeiro(lista)

  retornar rodadas
```

### Calcular ranking

```text
func calcularRanking(participantes, partidas, regras):
  standings = inicializarTabela(participantes)

  para cada partida confirmada:
    aplicarResultadoNaTabela(standings, partida, regras.pontuacao)

  ordenar standings por regras.criteriosDeDesempate
  marcarEmpatesNaoResolvidos(standings)
  retornar standings
```

### Aplicar critérios de desempate

```text
func comparar(a, b, criterios):
  para cada criterio em criterios:
    valorA = calcularCriterio(a, criterio)
    valorB = calcularCriterio(b, criterio)
    se valorA > valorB: retornar -1
    se valorA < valorB: retornar 1

  retornar 0
```

### Detectar empate não resolvido

```text
func marcarEmpatesNaoResolvidos(tabela):
  para cada grupoDeMesmoRanking em agruparPorComparacaoZero(tabela):
    se total(grupoDeMesmoRanking) > 1:
      marcarComoEmpateNaoResolvido(grupoDeMesmoRanking)
```

### Avançar participantes de fase

```text
func avancarDeFase(faseAtual, regraClassificacao):
  classificados = selecionarPorRanking(faseAtual.standings, regraClassificacao)
  proximaFase = obterProximaFase(faseAtual)
  distribuirClassificados(proximaFase, classificados, regraClassificacao.metodo)
  retornar proximaFase
```

### Validar resultado

```text
func validarResultado(partida, resultado):
  se partida.status nao permite resultado:
    retornar erro("Status invalido")
  se placares forem negativos:
    retornar erro("Placar invalido")
  se formato nao permite empate e placar empatado:
    retornar erro("Empate nao permitido")
  se melhorDeN e nenhum participante atingiu vitoriasNecessarias:
    retornar erro("Serie incompleta")
  retornar sucesso
```

### Detectar conflito de agenda

```text
func detectarConflito(novaPartida, partidasExistentes, intervaloMinimo):
  envolvidos = participantesDaPartida(novaPartida)

  para cada partida em partidasExistentes:
    se partida.status em ["cancelada", "finalizada"]:
      continuar
    se nao compartilhaParticipante(envolvidos, partida):
      continuar
    se horariosSobrepostos(novaPartida, partida, intervaloMinimo):
      retornar conflito(partida)

  retornar semConflito
```
## Implementação MVP: `single_elimination`

A geração real de mata-mata simples fica em `src/lib/tournaments/singleElimination.ts`, separada da UI. O fluxo implementado é:

1. Filtrar participantes confirmados.
2. Calcular a próxima potência de 2.
3. Calcular byes.
4. Distribuir posições por sorteio salvo ou por seeding.
5. Criar partidas da primeira rodada.
6. Criar rodadas futuras pendentes.
7. Avançar automaticamente participantes com bye.
8. Persistir chave e partidas no Supabase.

Para seeding, a ordem base usa distribuição recursiva de sementes para separar favoritos. Para 8 posições, as sementes formam os confrontos `1 x 8`, `4 x 5`, `2 x 7` e `3 x 6` conforme a árvore gerada. Participantes sem seed ocupam posições restantes por sorteio no momento da geração.

O sorteio puro embaralha participantes uma única vez no serviço de geração e salva as posições em `bracket_matches`; a chave não é recalculada em renderização.

Byes são salvos como partidas com `status = bye` e `is_bye = true`. O vencedor dessa partida estrutural já é gravado em `winner_registration_id` e alimenta o próximo slot.

O avanço de vencedor é feito pela RPC `complete_bracket_match`, que exige placar válido, vencedor pertencente à partida e permissão de admin/organizador.

## Atualizacao: validacao de resultados

O MVP implementa validacao de resultado para `single_elimination` em camada separada da UI:

- `validateMatchResult` verifica participantes, status, bye, placar vazio, placar negativo, empate e justificativa de correcao.
- `determineWinner` calcula o vencedor pelo placar.
- `isDrawAllowed` prepara expansao futura para formatos que aceitam empate.
- O banco repete as validacoes sensiveis nas RPCs `record_bracket_match_result`, `contest_match_result` e `resolve_match_dispute`.

Formatos como melhor de 3/5/7, pontos corridos e grupos completos permanecem fora do escopo desta etapa. W.O. ja existe como `result_type = walkover`, separado do placar comum.

## Atualizacao: algoritmo de ranking

O ranking basico fica em `src/lib/tournaments/ranking.ts` como funcao pura testavel. Entrada minima:

- participantes com `id`, nome exibido e seed opcional;
- partidas com participantes A/B, placares, status da partida e status do resultado;
- configuracao de pontos (`winPoints`, `drawPoints`, `lossPoints`).

Fluxo:

```text
func calcularRanking(participantes, partidas, pontuacao):
  criar estatisticas zeradas por participante
  para cada partida:
    se status nao for completed, ignorar
    se resultado estiver disputed ou cancelled, ignorar
    se faltar participante ou placar, ignorar
    somar jogos, vitorias, empates, derrotas, score_for e score_against
    aplicar pontos: vitoria 3, empate 1, derrota 0 por padrao
  calcular score_diff
  ordenar por pontos, vitorias, score_diff, score_for, confronto direto, seed e nome
  marcar empate tecnico quando criterios principais e confronto direto continuarem iguais
  retornar entradas ordenadas e resumo de criterios
```

Confronto direto e aplicado apenas quando a comparacao envolve exatamente dois participantes empatados. Em empate multiplo, o MVP mantem empate tecnico e usa seed/nome somente como fallback visual estavel, sem declarar vantagem esportiva.

## Atualizacao: check-in e W.O.

A geracao de mata-mata agora filtra participantes elegiveis:

```text
func filtrarElegiveis(torneio, inscricoes):
  confirmados = status em [confirmed, checked_in, registered]
  semPunicao = disqualified_at nulo e no_show_at nulo
  se torneio.requires_check_in:
    retornar confirmados com checked_in_at preenchido e semPunicao
  retornar confirmados semPunicao
```

W.O. e tratado como tipo de resultado:

```text
func registrarWO(partida, vencedor, justificativa):
  validar vencedor pertence a partida
  validar justificativa obrigatoria
  marcar resultado como result_type = walkover
  marcar perdedor como no_show
  avancar vencedor na chave
  registrar historico/auditoria
```

No ranking, W.O. soma jogo, vitoria e derrota conforme a pontuacao padrao. Nao soma `score_for`, `score_against` nem `score_diff`, porque nao representa placar esportivo.
