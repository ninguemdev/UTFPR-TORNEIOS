# CSS, responsividade e acessibilidade

Este documento consolida as regras de front-end do projeto. O CSS atual fica em `src/index.css` para tokens/base e `src/App.css` para layout e componentes.

## Organizacao do CSS

Os arquivos devem seguir estes blocos conceituais:

1. Reset/base.
2. Tokens.
3. Layout global.
4. Tipografia.
5. Botoes.
6. Formularios.
7. Cards e paineis.
8. Badges e status.
9. Tabelas.
10. Navegacao/header.
11. Componentes de torneio.
12. Componentes admin.
13. Estados: loading, erro, vazio, sucesso.
14. Utilitarios.
15. Media queries.

Nao usar Tailwind, styled-components, biblioteca visual ou IDs para estilizar.

## Regras de CSS

- Usar variaveis CSS para cores, fontes, espacos, sombras, raios, larguras e transicoes.
- Usar `gap` para espacamento entre elementos.
- Evitar `!important`; se surgir, justificar no comentario do codigo.
- Evitar largura fixa.
- Preferir `rem`, `%`, `svh`, `clamp()`, `min()`, `max()` e `minmax()`.
- Nao escalar fonte diretamente com viewport width.
- Manter `letter-spacing: 0`.
- Garantir `box-sizing: border-box`.
- Imagens e SVGs devem ser fluidos.
- Links e botoes devem ter estilo consistente.

## Tokens obrigatorios

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
  --color-text: #1f1b1c;
  --color-muted: #6f686a;
  --color-border: #ded8cc;

  --color-success: #167a4a;
  --color-danger: #b42318;
  --color-warning: #9f6514;
  --color-info: #2457a6;

  --font-sans: system-ui, "Segoe UI", Roboto, Arial, sans-serif;

  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;

  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 10px;
  --radius-xl: 14px;
  --radius-pill: 999px;

  --shadow-soft: 0 1px 2px rgb(20 17 18 / 0.07);
  --shadow-card: 0 12px 30px rgb(20 17 18 / 0.10);
  --shadow-elevated: 0 22px 60px rgb(20 17 18 / 0.16);

  --container-page: 1180px;
  --duration-fast: 120ms;
  --duration-base: 180ms;
}
```

## Breakpoints

Mobile-first:

```css
@media (max-width: 28rem) { /* 320px a 448px */ }
@media (min-width: 40rem) { /* tablets */ }
@media (min-width: 64rem) { /* desktops */ }
@media (min-width: 80rem) { /* telas amplas */ }
```

Faixas obrigatorias de verificacao:

- 320px a 480px.
- 481px a 768px.
- 769px a 1024px.
- 1025px ou mais.

## Estrategia mobile-first

- Comecar por uma coluna e expandir com media queries.
- Header mobile deve caber com marca, menu e acoes de usuario.
- Cards empilham em 320px.
- Formularios usam largura total em mobile.
- Botao principal deve ter area de toque minima de 44px.
- Tabelas usam `.table-scroll`; overflow horizontal fora desse wrapper e bug.
- Chave mata-mata vira lista por rodada em mobile e colunas no desktop.

## Grid e Flexbox

- CSS Grid para estrutura principal.
- Flexbox para botoes, badges, nav e acoes.
- Usar `minmax(min(100%, X), 1fr)` para grids fluidos:

```css
.content-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 17rem), 1fr));
  gap: var(--space-4);
}
```

## Uso de clamp()

Usar `clamp()` em titulos e textos de maior destaque:

```css
--text-2xl: clamp(1.8rem, 1.46rem + 1.2vw, 2.6rem);
```

Nao usar `font-size: 5vw` ou equivalente sem limites.

## Foco visivel

Todo elemento interativo deve mostrar foco:

```css
:focus-visible {
  outline: 3px solid var(--color-brand-yellow);
  outline-offset: 3px;
  box-shadow: 0 0 0 6px rgb(35 31 32 / 0.12);
}
```

## prefers-reduced-motion

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms;
    animation-iteration-count: 1;
    scroll-behavior: auto;
    transition-duration: 0.01ms;
  }
}
```

## Acessibilidade

- Texto normal deve ter contraste suficiente.
- Amarelo deve vir com texto grafite/preto quando usado como fundo.
- Badge nunca deve depender apenas de cor.
- Todo input precisa de `label`.
- Placeholder nao substitui label.
- Mensagens de erro persistentes usam `role="alert"`.
- Mensagens de sucesso/loading usam `role="status"` quando fizer sentido.
- Navegacao principal usa `aria-current`.
- Menu mobile usa `aria-expanded`.
- Abas usam `role="tablist"` e `aria-selected`.
- Botoes icon-only exigem `aria-label`.

## Regras por componente

### Botoes

- `button-primary`: CTA principal, amarelo UTFPR.
- `button-secondary`: acao secundaria, superficie clara.
- `button-ghost`: acao auxiliar.
- `button-danger`: acao destrutiva.
- Estados obrigatorios: hover, focus-visible, active, disabled.

### Formularios

- Campos obrigatorios devem ter label claro.
- Erros devem explicar como corrigir.
- Campos disabled devem ser visualmente diferentes.
- Formulario deve funcionar em 320px sem sobreposicao.

### Tabelas

- Sempre envolver em `.table-scroll`.
- Cabecalho claro.
- Separacao visual por bordas ou zebra.
- Siglas devem ser explicadas antes ou no proprio painel.

### Chave

- Desktop: rodadas em colunas quando houver espaco.
- Mobile: lista vertical por rodada.
- Vencedor destacado por borda, texto e contraste, nao apenas cor.
- Bye e W.O. precisam de texto visivel.

### Estados

- Loading: spinner e texto curto.
- Empty: explica ausencia de dados e proxima acao.
- Error: indica problema e caminho de retorno/retry.
- Success: confirma acao relevante.

## Checklist antes de finalizar uma tela

- Existe apenas um `h1`.
- Titulos seguem ordem logica.
- Todos os inputs tem label.
- Botoes sao `button`; links sao `a`.
- Estados hover, focus, active e disabled existem.
- Layout funciona em 320px.
- Nao ha overflow horizontal fora de tabela/chave controlada.
- Cards, formularios e acoes empilham corretamente.
- Tabelas sao legiveis no mobile.
- Chave preserva leitura em mobile.
- Textos nao se sobrepoem.
- `prefers-reduced-motion` e respeitado.
- Nao ha `!important` sem justificativa.
- A identidade visual usa amarelo/preto da UTFPR sem excesso.

## Atualizacao: navegacao global

- Header global visivel nas paginas principais.
- Menu mobile do header operavel por mouse e teclado.
- Botao "Voltar" antes do `h1` nas paginas internas, exceto home.
- Paginas de autenticacao com layout simplificado mantem link para home.
- O botao "Voltar" tenta usar historico do navegador e cai em rota segura quando necessario.
