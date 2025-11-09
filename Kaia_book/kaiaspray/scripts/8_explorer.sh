#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EXPLORER_DIR="$PROJECT_ROOT/explorer"

pushd "$PROJECT_ROOT" >/dev/null
trap 'popd >/dev/null' EXIT

docker_compose() {
  local compose_file="$EXPLORER_DIR/docker-compose.yml"
  if [ ! -f "$compose_file" ]; then
    echo "未找到 $compose_file，无法启动区块浏览器。"
    exit 1
  fi

  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$compose_file" "$@"
  else
    docker-compose -f "$compose_file" "$@"
  fi
}

start_explorer() {
    set -e
    RPC_PORT=$(sed -n 's/^RPC_PORT=\([0-9]*\)$/\1/p' ${1}${2}/conf/k${1}d.conf)
    RPC_URL=http://host.docker.internal:$RPC_PORT
    WS_PORT=$(sed -n 's/^WS_PORT=\([0-9]*\)$/\1/p' ${1}${2}/conf/k${1}d.conf)
    WS_URL=ws://host.docker.internal:$WS_PORT
    CHAIN_ID=$(sed -n 's/^NETWORK_ID=\([0-9]*\)$/\1/p' ${1}${2}/conf/k${1}d.conf)
    HOST_DOMAIN=${3:-localhost}
    echo "Leeching from ${1}${2}: RPC_URL=$RPC_URL WS_URL=$WS_URL CHIAN_ID=$CHAIN_ID"
    echo "Listening to: http://$HOST_DOMAIN"

    RPC_URL=$RPC_URL WS_URL=$WS_URL CHAIN_ID=$CHAIN_ID HOST_DOMAIN=$HOST_DOMAIN docker_compose up -d
    set +e
}

case "$1" in
    start)
        shift
        start_explorer "$@"
        ;;
    stop)
        docker_compose down
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        echo
        echo "  $0 start <rpc> <listen domain>"
        echo "  $0 start en 1  mydomain.com"
        echo "  $0 start en 1"
        echo
        echo "  $0 stop"
        exit 1
        ;;
esac

