# Checklist de code review

O arquivo `code_review.md` ainda não está presente no repositório. Este checklist usa as regras de `AGENTS.md` e deve ser revisado quando o documento original for adicionado.

## HTML

- Há apenas um `h1` por página.
- A ordem de títulos é lógica.
- Inputs têm `label`.
- Botões de ação usam `button`.
- Navegação usa `a` ou componente semanticamente equivalente.
- Imagens informativas têm texto alternativo.
- Estados vazios, erro e loading são representados no markup.

## CSS

- Usa variáveis CSS para tokens.
- Usa `gap` para espaçamento entre elementos.
- Evita `!important`.
- Não usa largura fixa que quebre no mobile.
- Usa Grid para estrutura principal quando adequado.
- Usa Flexbox para alinhamento interno.
- Estados hover, focus, active e disabled estão definidos.
- `prefers-reduced-motion` é respeitado.

## JavaScript/TypeScript

- Tipos representam o domínio corretamente.
- Funções de negócio são puras quando possível.
- Não há lógica complexa escondida dentro de componente visual.
- Erros são tratados explicitamente.
- Não há duplicação desnecessária.
- Nomes são claros e consistentes.
- Código compila com `npm run build`.
- Lint passa com `npm run lint`.

## Responsividade

- Layout funciona em 320px.
- Não há overflow horizontal indevido.
- Cards, tabelas e chaves continuam legíveis.
- Textos não sobrepõem componentes.
- Botões têm área de toque adequada.
- Grids usam `minmax()`, `auto-fit` ou alternativas fluidas quando necessário.

## Acessibilidade

- Foco visível funciona.
- Navegação por teclado é possível.
- Modais e menus não prendem usuário sem saída.
- Contraste é suficiente.
- Cor não é o único indicador de estado.
- Mensagens de erro são claras.
- Botões apenas com ícone têm `aria-label`.

## Design

- Visual é acadêmico, limpo e profissional.
- Paleta não fica dominada por uma única cor.
- Componentes seguem tokens de espaçamento, raio e sombra.
- Cards não são aninhados sem necessidade.
- Hierarquia visual ajuda a escanear informações.
- Estados provisórios de chave/ranking são claros.

## Algoritmos de torneio

- Formato está separado de seeding, sorteio, agenda e ranking.
- Byes são tratados explicitamente.
- Seeding não favorece manualmente participante sem justificativa.
- Sorteio é reproduzível ou auditável quando possível.
- Avanço de fase é consistente.
- Alterações em resultados recalculam dependências.

## Ranking

- Critérios de pontuação são configuráveis.
- Critérios de desempate são explícitos.
- Empates não resolvidos são sinalizados.
- Confronto direto é aplicado apenas quando válido.
- W.O. afeta ranking conforme regra documentada.

## Segurança básica

- Usuário sem permissão não executa ação restrita.
- Permissões sensíveis são validadas no banco por RLS, policies ou RPCs, não apenas na interface.
- Supabase Auth gerencia senhas; o projeto não cria campo próprio de senha ou hash.
- Nenhuma chave privada, service role key ou segredo aparece no front-end.
- Apenas variáveis públicas adequadas são usadas no cliente.
- Tabelas importantes têm RLS habilitado.
- Usuário comum não consegue alterar `role`, `can_create_tournaments` ou dados de outros usuários.
- Admin consegue executar ações globais apenas com auditoria e justificativa quando necessário.
- Dados sensíveis não aparecem em página pública.
- RA, e-mail e dados administrativos são protegidos por permissão.
- Inputs são validados.
- Ações destrutivas pedem confirmação.
- Correções críticas geram auditoria.

## Performance

- Listas grandes têm renderização razoável.
- Componentes evitam recomputar algoritmos caros sem necessidade.
- Imagens são otimizadas.
- CSS não cria layout instável.
- Build final não inclui arquivos desnecessários.

## Manutenibilidade

- Arquivos têm responsabilidade clara.
- Componentes são reaproveitáveis sem abstração excessiva.
- Funções de domínio têm testes.
- Documentação é atualizada junto da mudança.
- Mudanças grandes são divididas em etapas revisáveis.
## Atualizacao: navegacao

- Paginas principais usam `AuthenticatedShell`/`SiteHeader`, sem header duplicado por tela.
- Paginas internas exibem botao "Voltar"; home nao exibe.
- Paginas de login/cadastro mantem caminho claro para home.

## Atualizacao: identidade visual UTFPR

- Tokens globais de `src/index.css` usam grafite/preto e amarelo UTFPR como base.
- `button-primary` usa amarelo com texto grafite e deve aparecer apenas para CTA principal.
- Header, hero, auth e public cover carregam a identidade institucional sem deixar a UI escura demais.
- Cards usam superficie clara, borda neutra, sombra leve e detalhe amarelo sutil.
- Badges usam texto explicito e ponto visual; status nao depende apenas de cor.
- Tabelas usam `.table-scroll`, cabecalho claro, zebra sutil e siglas explicadas.
- Chave mata-mata funciona como lista em mobile e colunas em desktop; vencedor, bye, W.O. e contestacao precisam de texto.
- Formularios mantem labels visiveis, foco acessivel e area minima de toque.
- Nao ha `!important`, Tailwind, styled-components ou biblioteca visual adicionada.
- Conferir visualmente 320px, 480px, 768px, 1024px e desktop amplo antes de aprovar mudancas de UI.
