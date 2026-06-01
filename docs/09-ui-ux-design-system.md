# UI, UX e design system

## Personalidade visual

O produto deve parecer institucional, tecnologico, moderno, confiavel e adequado para organizacao academica de torneios. A identidade visual parte da UTFPR: grafite/preto como base institucional e amarelo como destaque de acao, sem transformar a interface em um tema escuro nem em uma pagina toda amarela.

O visual deve apoiar torneios, e-sports e gestao academica com superficies claras, bordas sutis, sombras leves, dados bem escaneaveis e elementos tecnicos discretos, como linhas e grid de fundo.

Evitar visual generico de dashboard, excesso de gradientes, paleta monocromatica, efeitos decorativos sem funcao, cards aninhados e elementos que dificultem leitura em 320px.

## Paleta final

Tokens globais ficam em `src/index.css`.

```css
:root {
  --color-brand-black: #231f20;
  --color-brand-black-2: #141112;
  --color-brand-yellow: #ffc400;
  --color-brand-yellow-2: #f2b900;
  --color-brand-yellow-soft: #fff4bf;

  --color-bg: #f7f5ef;
  --color-bg-strong: #ebe7dc;
  --color-surface: #ffffff;
  --color-surface-2: #fffbeb;
  --color-surface-muted: #f2eee4;

  --color-text: #1f1b1c;
  --color-heading: #141112;
  --color-muted: #6f686a;
  --color-border: #ded8cc;

  --color-success: #167a4a;
  --color-danger: #b42318;
  --color-warning: #9f6514;
  --color-info: #2457a6;
}
```

## Uso de cor

- Amarelo UTFPR: CTA principal, foco, destaques de chave, vencedores, detalhes de marca e indicadores importantes.
- Preto/grafite: marca, texto principal, header de identidade, contraste em placares e areas institucionais.
- Fundo: claro e levemente quente para reduzir dureza visual.
- Superficies: branco/off-white com borda neutra e sombra leve.
- Verde, vermelho, azul e aviso: apenas para status funcionais.
- Status nunca deve depender apenas de cor; badge sempre precisa de texto.

## Tokens estruturais

`src/index.css` centraliza:

- cores de marca, fundo, superficie, texto, borda e status;
- escala de espaco `--space-1` a `--space-16`;
- raios `--radius-sm`, `--radius-md`, `--radius-lg`, `--radius-xl`, `--radius-pill`;
- sombras `--shadow-soft`, `--shadow-card`, `--shadow-elevated`;
- containers `--container-page` e `--container-narrow`;
- z-index para header, modal e toast;
- duracoes `--duration-fast`, `--duration-base`, `--duration-slow`;
- tamanhos fluidos de texto com `clamp()`.

## Tipografia

- Fonte principal: `system-ui`, `Segoe UI`, `Roboto`, `Arial`, sans-serif.
- Titulos: peso alto e contraste forte.
- Corpo: peso regular, boa altura de linha.
- Dados tabulares: fonte principal; mono apenas quando necessario.
- Nao usar fonte escalada diretamente por `vw`.
- `letter-spacing` deve permanecer `0`.

## Layout

- Mobile-first.
- Conteudo principal usa `width: min(100%, var(--container-page))`.
- Grids usam `repeat(auto-fit, minmax(min(100%, ...), 1fr))`.
- Header global usa `SiteHeader` e menu mobile com `aria-expanded`.
- Paginas internas usam `AuthenticatedShell`, `PageLayout` e `PageBackButton`.
- Evitar largura fixa e overflow horizontal fora de wrappers controlados.

## Botoes

Variantes:

- `button-primary`: amarelo UTFPR com texto grafite. Usar para acao principal.
- `button-secondary`: superficie clara com borda grafite sutil. Usar para acao importante secundaria.
- `button-ghost`: baixo peso visual. Usar para acoes auxiliares.
- `button-danger`: vermelho funcional. Usar para acao destrutiva quando houver classe especifica.

Regras:

- Altura minima de toque: 44px.
- Estados hover, focus-visible, active e disabled obrigatorios.
- Botoes de loading mantem largura/estrutura e mudam texto.
- `button` real para acao; `a` para navegacao.

## Cards e paineis

- Cards representam itens repetidos: torneios, equipes, participantes, partidas, pedidos.
- Paineis (`surface-panel`, `form-section`) estruturam secoes completas.
- Cards usam borda sutil, raio de ate 8px, sombra leve e detalhe amarelo discreto.
- Nao colocar card dentro de card sem necessidade clara.
- Conteudo deve quebrar palavras longas com seguranca.

## Badges

- Badge sempre tem texto explicito e ponto visual.
- Verde: confirmado, resolvido, sucesso.
- Amarelo/aviso: pendente, aberto, live, em disputa.
- Azul: informativo, finalizado ou W.O. quando for status informativo.
- Vermelho: cancelado, rejeitado, desclassificado, erro.
- Badges longos devem quebrar sem estourar a tela.

## Formularios

- Todo input, select e textarea precisa de label.
- Placeholder nao substitui label.
- Mensagens persistentes usam `form-message-*`.
- Estado disabled deve ser visualmente claro.
- Checkboxes usam label clicavel e area de toque confortavel.
- Formularios de torneio, equipe, perfil, login, resultado e admin devem funcionar em 320px.

## Tabelas

- Usar `.table-scroll` para controlar overflow horizontal.
- Cabecalho claro, bordas sutis e zebra discreta.
- Linhas usam hover suave.
- Siglas e criterios devem ser explicados em texto proximo.
- Em mobile, rolagem horizontal e aceitavel apenas dentro do wrapper da tabela.

## Chave mata-mata

- Desktop: rodadas em colunas quando houver largura; cada rodada fica em painel proprio.
- Mobile: rodadas viram lista vertical por ordem de leitura.
- Vencedor recebe destaque amarelo e contraste no placar.
- Bye, W.O. e partida contestada usam texto no badge/descricao, nao apenas cor.
- Conectores visuais em desktop sao sutis e nao devem prejudicar leitura.

## Estados

- Loading: spinner e texto com `role="status"`.
- Erro: mensagem clara com `role="alert"`.
- Sucesso: mensagem persistente quando afeta fluxo.
- Empty state: explica o que falta e oferece proxima acao.
- Toast: feedback breve, sem substituir erro persistente.

## Microinteracoes

- Transicoes entre 120ms e 260ms.
- Hover indica clicabilidade sem deslocar layout.
- `prefers-reduced-motion` reduz animacoes.
- Foco visivel usa amarelo UTFPR com contraste perceptivel.

## Componentes especificos

- `tournament-card`: nome, status, modalidade, formato, inscritos e acoes.
- `team-card`: status, completude e membros.
- `participant-card`: avatar textual, nome, tipo/status.
- `match-card`: status, placar, fase, rodada e local.
- `bracket-match`: slots, placar, vencedor, bye, W.O. e historico.
- `ranking-table`: posicao, participante, pontos, jogos, vitorias, empates, derrotas e desempate.
- `admin-panel`/`organizer-panel`: usar para areas densas de gestao.
- `timeline`/`schedule-item`: usar para eventos de agenda e historico operacional.
