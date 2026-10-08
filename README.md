# Simulação Freechains — Fórum Estilo StackOverflow

Simulação de 90 dias de um **fórum de perguntas e respostas sobre
programação** — um StackOverflow descentralizado — rodando sobre a rede
**Freechains**.

Repositório de referência: <https://github.com/Freechains/freechains.vcs>

---

## a. O problema e a intenção

Um fórum aberto sem moderador central enfrenta quatro ameaças clássicas:

1. **Sybil** — identidades falsas gratuitas inundando o fórum;
2. **Spam** — conteúdo malicioso ou promocional;
3. **Conluio** — grupos coordenados que se promovem mutuamente e derrubam adversários;
4. **Censura oportunista** — quem tem poder de moderar, abusa dele.


### 6 atores

| Ator | Papel | Descrição |
|---|---|---|
| `marina` | honesta — pioneer | cria a cadeia, escreve as regras, é a moderadora principal |
| `rafael` | honesto | membro fundador (like author de 10000), participa do fork de consenso do dia 28 |
| `juliana` | honesta | membro fundadora (12000), aprovada por *beg*, vaza uma chave no dia 36 (auto-revogação) e é vítima do ataque do dia 70 |
| `thiago` | honesto | entra **por begging** (dia 1, 0 reputação — demonstra o mecanismo de admissão) |
| `renan` | **malicioso — líder do conluio** | entra dia 5 com resposta copiada + like de 8000 da Juliana; financia o cúmplice; revoga a resposta alheia; termina com reputação **negativa** |
| `gustavo` | **malicioso — cúmplice** | sybil bloqueado (dia 2), sobrevive de beg-spam e do repasse do Renan; fica tão pobre que não consegue pagar o próprio ataque |

---

## b. Natureza das mensagens postadas

Todas as mensagens do fórum giram em torno de **programação** — perguntas e
respostas técnicas curtas, no formato `[Q#N]` (pergunta) e `[A→xxxxxxx]`
(resposta à pergunta cujo id começa com `xxxxxxx`).

### Honestos

| Tipo de mensagem | Exemplos | Propósito na simulação |
|---|---|---|
| `[Regras]` | post único da Marina (dia 0): "Perguntas claras, sem spam..." | texto legível por todos via `get payload` |
| `[Q#N]` | "Como inverter uma lista em Python?", "Diferença entre `==` e `===` em JavaScript?", "Como desfazer o último commit no git?" | alimentam o fórum; custam 500 e rendem mint ao consolidar |
| `[A→xxxxxxx]` | respostas técnicas corretas de uma linha (`lista.reverse()`, `git reset --soft HEAD~1`, prepared statements...) | acumulam likes; distribuem reputação para bons contribuidores |
| `[Mod]` | mensagem da Marina ao retornar das férias (dia 66) | exercita recuperação de *hard fork* |

### Maliciosos

| Tipo de mensagem | Exemplos | Efeito observado |
|---|---|---|
| Resposta **copiada** (sleeper) | Renan copia a resposta da pergunta 1 no dia 5 | **engana**: recebe like de 8000 da Juliana e vira o post **mais valioso da cadeia** (4050 reps) até o dia 70 |
| **Spam** | "COMPRE SEGUIDORES", "chmod 777 /", "curl \| sudo bash", "IDE crackeada" | moderado: dislike 1000 + revoke 1000; ao consolidar, o saldo **negativo do post (~−900) é cobrado do autor** |
| **Beg-spam** | spam postado com `--beg` (autor sem reputação) | fica **pendente** na fila de begs para sempre — sem like de um membro, nunca entra na cadeia |
| Spam da **célula** (partição) | posts durante os dias 40-46 | sincronizados só via daemon do Renan; ao fim da partição o ramo honesto precede o deles na ordem de consenso |

---

## c. Reações: (dis)likes e (un)revokes

### Likes

| Ação | Dia | Efeito |
|---|---|---|
| Marina dá likes author (10000/12000) a Rafael e Juliana | 0 | admite os fundadores; Marina paga o valor cheio, eles recebem 90% |
| Juliana dá like de **8000** na resposta copiada do Renan | 5 | o conluio nasce com patrocínio involuntário dos honestos |
| Renan transfere 1500 (like author) para Gustavo | 8 | financia o cúmplice; 10% queimado em imposto |
| Upvotes honestos de 500 em respostas boas | contínuo | distribuição normal de reputação |
| Ring likes do conluio (500 cruzados) | contínuo | **rendem menos do que parecem**: cada transferência queima 10% — o anel só empobrece |

### Dislikes

| Ação | Dia | Efeito |
|---|---|---|
| Marina modera S1/S2 (dislike 1000 + revoke 1000 em cada spam) | 26 | início da moderação; payload some de todos os nós |
| 3ª reincidência: dislike de **500 no autor** (Renan) | 39 | punição escalonada atinge o autor, não só o post |
| Conluio ataca Juliana (dislike author) | 70 | Renan paga 2000; **Gustavo é recusado** (`insufficient reputation`) e ataca com apenas 500, o spam revogado empobreceu o atacante |
| Comunidade reage: Marina e Rafael dão **3000 cada no Renan** | 72 | o líder do conluio despenca para **−4950** |

### Revokes e unrevokes

| Ação | Dia | Custo | Leitura |
|---|---|---|---|
| Marina **revoga** S1/S2 | 26 | 1000 cada | o protocolo cobra o mod da moderação |
| Renan **revoga a resposta boa do Rafael** (A1) | 33 | 1000 | quem tem 1000 pode censurar conteúdo alheio |
| Marina **desfaz** a revogação (unrevoke 3000) | 34 | 3000 | correção comunitária do abuso; o payload volta |
| Juliana **revoga o próprio post** (vazamento) | 36 | **grátis** | direito ao esquecimento |
| Marina recupera-se de *hard fork* (abandon + repost) | 66 | — | ramo de 11 dias recusado/anexado; repost reconverge a cadeia |

---

## d. Conclusão


1. **Conteúdo**: todo spam foi revogado (os 5 piores IDs do relatório são os
   spams, com ~−900 cada); o beg-spam nunca entrou na cadeia (1 beg pendente
   ao fim de 90 dias); a chave vazada foi apagada em um dia.

2. **Atores**: o conluio prosperou *temporariamente*, a resposta copiada do
   Renan foi o post mais valioso da cadeia (4050) e o sleeper rendeu ~2800 de
   reputação ao líder. Mas o balanço final foi devastador: **Renan terminou
   com −4950**, e Gustavo, sem nunca ter contribuído
   positivamente, mal conseguiu pagar 500 no ataque conjunto. O imposto de 10%
   garante que o conluio seja um sumidouro, não uma fonte.

3. **Moderação**:a Marina
   saiu de 28000 para 13775 reputação, tendo gasto ~14.000 para moderar,
   desfazer o abuso do dia 33 e punir o conluio. A pergunta que a simulação
   deixa em aberto é se a comunidade consegue financiar a moderação
   indefinidamente, no dia 72, quem puniu o Renan foram exatamente os membros
   mais ricos.

4. **Consenso**: partição de rede com
   célula conspirativa (dias 40-46), nó offline por 11 dias
   (dias 55-66) e onda de revogações, **o hash de `list order` é idêntico nos
   7 nós ao dia 90**. A cadeia não só sobreviveu a todos os ataques e
   acidentes do roteiro como convergiu para um único histórico aceito por
   honestos e maliciosos.
