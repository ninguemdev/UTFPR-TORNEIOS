# Checklist de validacao de fluxos

Use este checklist para revisao manual, QA, implementacao de testes automatizados e validacao de RLS.

## Por papel

### Visitante

- [ ] Ve apenas torneios fora de `draft`.
- [ ] Ve apenas participantes publicos confirmados/check-in conforme regra.
- [ ] Ve chave, resultados e ranking de torneio publicado.
- [ ] Nao consegue criar inscricao sem login.
- [ ] Nao ve dados pessoais como email e RA.
- [ ] Nao acessa auditoria, pedidos ou permissoes.

### Usuario comum

- [ ] Cria conta e profile automatico e criado.
- [ ] Login carrega profile e permissao.
- [ ] Edita apenas nome, RA e avatar proprios.
- [ ] Nao altera `role`, email, id ou profile alheio.
- [ ] Solicita permissao de criador.
- [ ] Cancela apenas pedido proprio pendente.
- [ ] Inscreve-se em torneio aberto.
- [ ] Cancela apenas inscricao propria permitida.
- [ ] Contesta apenas resultado de partida em que participa.

### Criador autorizado / organizador

- [ ] Cria torneio quando permissao esta ativa.
- [ ] Nao cria torneio quando `create_tournament` esta bloqueado.
- [ ] Edita apenas torneios proprios.
- [ ] Gerencia inscricoes do proprio torneio.
- [ ] Gerencia equipes do proprio torneio.
- [ ] Gera chave do proprio torneio.
- [ ] Registra e corrige resultados do proprio torneio.
- [ ] Recalcula ranking do proprio torneio.
- [ ] Nao acessa painel admin global.

### Criador revogado

- [ ] Nao consegue criar novo torneio.
- [ ] Recebe mensagem clara sobre revogacao.
- [ ] Regra de gestao de torneios antigos foi validada conforme decisao de produto.
- [ ] Pode consultar historico permitido.

### Capitao

- [ ] Cria equipe em torneio por equipe aberto.
- [ ] Vira membro capitao automaticamente.
- [ ] Adiciona membro por email/RA exato.
- [ ] Nao excede `team_max_size`.
- [ ] Nao adiciona usuario que ja esta em equipe ativa do torneio.
- [ ] Nao remove o capitao.
- [ ] Envia equipe apenas quando atinge minimo exigido.
- [ ] Faz check-in da inscricao de equipe quando regra permitir.

### Membro de equipe

- [ ] Ve equipe propria.
- [ ] Nao edita equipe sem ser capitao/gestor.
- [ ] Participa da regra de contestacao quando aplicavel.
- [ ] Nao ve dados de equipes privadas alheias.

### Admin global

- [ ] Acessa `#/admin` e `#/admin/pedidos`.
- [ ] Aprova/rejeita pedidos.
- [ ] Revoga permissoes.
- [ ] Consulta auditoria.
- [ ] Cria, atualiza e remove action locks.
- [ ] Edita qualquer torneio.
- [ ] Exclui torneio apenas com confirmacao adequada.
- [ ] Nao depende de `service_role` no front-end.

## Por area

### Auth e perfil

- [ ] Cadastro cria `auth.users` e `profiles`.
- [ ] Login trata email nao confirmado e credenciais invalidas.
- [ ] Recuperacao de senha completa precisa ser validada em ambiente Supabase.
- [ ] Profile ausente tem tratamento.

### Permissoes

- [ ] Pedido duplicado `pending` e bloqueado.
- [ ] Aprovacao cria permissao `active`.
- [ ] Rejeicao nao cria permissao.
- [ ] Revogacao preserva historico.
- [ ] Usuario comum nao escreve `tournament_creator_permissions`.

### Torneios

- [ ] `draft` nao aparece publicamente.
- [ ] Alteracao de status respeita impacto operacional.
- [ ] Criador nao troca `created_by`.
- [ ] Admin delete audita e confirma impacto.

### Inscricoes

- [ ] Inscricao fora de `registrations_open` e bloqueada.
- [ ] Duplicidade ativa e bloqueada.
- [ ] Limite de participantes e aplicado.
- [ ] Cancelamento proprio obedece status.
- [ ] Gestor nao reativa cancelada/rejeitada por update comum.

### Equipes

- [ ] Equipe so em torneio por equipe.
- [ ] Prazo de equipe e respeitado.
- [ ] Membro duplicado e bloqueado.
- [ ] Capitao nao removivel.
- [ ] Envio cria inscricao por equipe.

### Check-in, W.O. e desclassificacao

- [ ] Check-in fora da janela e bloqueado.
- [ ] Desfazer check-in exige motivo.
- [ ] Desclassificacao exige motivo.
- [ ] Participante desclassificado nao entra em chave.
- [ ] W.O. exige motivo e marca perdedor.
- [ ] Reversao ou irreversibilidade esta definida.

### Chave e resultados

- [ ] Geracao exige participantes suficientes.
- [ ] `seeded` respeita seed.
- [ ] Byes avancam corretamente.
- [ ] Regeracao com resultado e bloqueada ou exige confirmacao forte.
- [ ] Resultado invalido e bloqueado.
- [ ] Contestacao e resolucao funcionam.
- [ ] Historico registra correcao.

### Ranking, grupos e agenda

- [ ] Ranking ignora disputas abertas/canceladas.
- [ ] Empates tecnicos aparecem como tais.
- [ ] Formatos incompletos estao marcados como parciais/pendentes.
- [ ] Pontos corridos/grupos nao sao anunciados como completos antes do gerador real.
- [ ] Agenda nao e prometida sem tabela/service.

### Auditoria e seguranca

- [ ] RLS habilitado em todas as tabelas do modulo.
- [ ] Functions SECURITY DEFINER usam `search_path`.
- [ ] Action locks bloqueiam acoes esperadas.
- [ ] Audit logs sao restritos a admin.
- [ ] Testes de RLS cobrem anon, usuario, organizador e admin.

