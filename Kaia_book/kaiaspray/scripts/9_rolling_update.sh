#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/config/properties.sh"
cd "$HOMEDIR"

# Assuming cn1 is the governing node.
# Assuming removing 1 CN from council still allows the consensus network to continue.
# Assuming block numbers will increase in normally functioning node.

retry=60

exec_console() {
  bin=${1}${2}/bin/k${1}
  ipc=${1}${2}/data/klay.ipc
  cmd=${3}
  ${bin} attach --exec "${cmd}" $ipc
}

node_address() {
  exec_console $1 $2 kaia.nodeAddress | sed "s/\"//g"
}

health_check() {
  if ! exec_console $1 $2 42 >/dev/null; then
    return 1
  fi
  num1=$(exec_console $1 $2 eth.blockNumber)
  sleep 2
  num2=$(exec_console $1 $2 eth.blockNumber)
  if [ $num1 -eq $num2 ]; then
    echo "Reading blockNumber $num1...$num2...stuck"
    return 1
  fi
  echo "Reading blockNumber $num1...$num2...advancing"
}

must_wait_up() {
  echo "[+] Waiting up $1$2"
  for i in $(seq 1 $retry); do
    if health_check $1 $2; then
      return 0
    fi
    sleep 1
  done
  echo "Failed to wait up $1$2"
  exit 10
}

must_kick_out_from_council() {
  nodeAddr=$1
  echo "[+] Kicking out $nodeAddr from council"
  exec_console cn 1 "governance.vote('governance.removevalidator', '$nodeAddr')"
  for i in $(seq 1 $retry); do
    council=$(exec_console cn 1 "console.log(eth.blockNumber, kaia.getCouncil())" | head -1)
    echo "$council"
    if ! echo "$council" | grep -q "$nodeAddr"; then
      echo "Kicked out $nodeAddr"
      return 0
    fi
    sleep 1
  done
  echo "Failed to kick out $nodeAddr from council"
  exit 11
}

must_invite_to_council() {
  nodeAddr=$1
  echo "[+] Inviting $nodeAddr to council"
  exec_console cn 1 "governance.vote('governance.addvalidator', '$nodeAddr')"
  for i in $(seq 1 $retry); do
    council=$(exec_console cn 1 "console.log(eth.blockNumber, kaia.getCouncil())" | head -1)
    echo "$council"
    if echo "$council" | grep -q "$nodeAddr"; then
      echo "Invited $nodeAddr"
      return 0
    fi
    sleep 1
  done
  echo "Failed to invite $nodeAddr to council"
  exit 12
}

must_copy_binary() {
  echo "[+] Copying binary of $1$2"
  src=$KAIACODE/build/bin/k${1}
  dst=${1}${2}/bin/k${1}

  for i in $(seq 1 $retry); do
    if cp $src $dst; then
      return 0
    fi
    sleep 1
  done
  echo "Failed to copy binary $src to $dst"
  exit 13
}

must_update_node() {
  must_wait_up $1 $2
  echo "[+] Stopping $1$2"
  "$SCRIPT_DIR/4_ccstop.sh" $1 $2
  must_copy_binary $1 $2
  echo "[+] Starting $1$2"
  "$SCRIPT_DIR/3_ccstart.sh" $1 $2
  must_wait_up $1 $2
}

update_enpn() {
  echo ">>> Updating $1$2"
  must_update_node $1 $2
  echo "<<< Updated $1$2"
}

update_governing_cn() {
  echo ">>> Updating $1$2"
  must_update_node $1 $2
  echo "<<< Updated $1$2"
}

update_non_governing_cn() {
  echo ">>> Updating $1$2"
  must_wait_up $1 $2
  nodeAddr=$(node_address $1 $2)
  must_kick_out_from_council $nodeAddr
  must_update_node $1 $2
  must_invite_to_council $nodeAddr
  echo "<<< Updated $1$2"
}

update_auto() {
  if [ $1 == "cn" ] && [ $2 -eq 1 ]; then
    update_governing_cn $1 $2
  elif [ $1 == "cn" ]; then
    update_non_governing_cn $1 $2
  else
    update_enpn $1 $2
  fi
}

if [ $# -eq 2 ]; then
  update_auto $1 $2
  exit
fi

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'cn*' | wc -l`; num++))
do
  update_auto cn $num
done

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'pn*' | wc -l`; num++))
do
  update_auto pn $num
done

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'en*' | wc -l`; num++))
do
  update_auto en $num
done
