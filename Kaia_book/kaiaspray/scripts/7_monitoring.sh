#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONITORING_DIR="$PROJECT_ROOT/monitoring"

source "$PROJECT_ROOT/config/properties.sh"

pushd "$PROJECT_ROOT" >/dev/null
trap 'popd >/dev/null' EXIT

mkdir -p "$MONITORING_DIR/prometheus"
mkdir -p "$MONITORING_DIR/grafana/provisioning/datasources"
mkdir -p "$MONITORING_DIR/grafana/provisioning/dashboards"

docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$MONITORING_DIR/docker-compose.yml" "$@"
  else
    docker-compose -f "$MONITORING_DIR/docker-compose.yml" "$@"
  fi
}

setup_grafana_dashboards() {
  local dashboards_dir="$PROJECT_ROOT/roles/monitor-init/files/grafana/dashboards"
  if [ -d "$dashboards_dir" ]; then
    cp "$dashboards_dir"/*.json "$MONITORING_DIR/grafana/provisioning/dashboards/" 2>/dev/null || true
    if [ -f "$dashboards_dir/kaia-dashboard.yml" ]; then
      cp "$dashboards_dir/kaia-dashboard.yml" "$MONITORING_DIR/grafana/provisioning/dashboards/"
    fi
  fi

  cat > "$MONITORING_DIR/grafana/provisioning/dashboards/klaytn-dashboard.yml" <<'EOF'
apiVersion: 1
providers:
  - name: 'klaytn'
    folder: ''
    options:
      path: /etc/grafana/provisioning/dashboards
EOF
}

generate_prometheus_config() {
  local config_path="$MONITORING_DIR/prometheus/prometheus.yml"
  printf "%s\n" \
    "global:" \
    "  evaluation_interval: 5s" \
    "  scrape_interval: 5s" \
    "" \
    "scrape_configs:" \
    "  - job_name: 'kaia'" \
    "    static_configs:" > "$config_path"

  local index=0

  for ((i = 0; i < NUMOFCN; i++)); do
    printf "    - targets:\n" >> "$config_path"
    printf "      - \"host.docker.internal:%d\"\n" $((61001 + index)) >> "$config_path"
    printf "    labels:\n" >> "$config_path"
    printf "      node_type: \"cn\"\n" >> "$config_path"
    printf "      name: \"cn%d\"\n" $((i + 1)) >> "$config_path"
    printf "      instance: \"cn%d\"\n" $((i + 1)) >> "$config_path"
    index=$((index + 1))
  done

  for ((i = 0; i < NUMOFPN; i++)); do
    printf "    - targets:\n" >> "$config_path"
    printf "      - \"host.docker.internal:%d\"\n" $((61001 + index)) >> "$config_path"
    printf "    labels:\n" >> "$config_path"
    printf "      node_type: \"pn\"\n" >> "$config_path"
    printf "      name: \"pn%d\"\n" $((i + 1)) >> "$config_path"
    printf "      instance: \"pn%d\"\n" $((i + 1)) >> "$config_path"
    index=$((index + 1))
  done

  for ((i = 0; i < NUMOFEN; i++)); do
    printf "    - targets:\n" >> "$config_path"
    printf "      - \"host.docker.internal:%d\"\n" $((61001 + index)) >> "$config_path"
    printf "    labels:\n" >> "$config_path"
    printf "      node_type: \"en\"\n" >> "$config_path"
    printf "      name: \"en%d\"\n" $((i + 1)) >> "$config_path"
    printf "      instance: \"en%d\"\n" $((i + 1)) >> "$config_path"
    index=$((index + 1))
  done

  echo "Generated Prometheus config with ${NUMOFCN} CN, ${NUMOFPN} PN, and ${NUMOFEN} EN nodes"
}

generate_grafana_config() {
  cat > "$MONITORING_DIR/grafana/provisioning/datasources/prometheus.yml" <<'EOF'
apiVersion: 1
datasources:
  - name: klaytn
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF
}

case "$1" in
  start)
    echo "Starting monitoring tools..."
    generate_prometheus_config
    generate_grafana_config
    setup_grafana_dashboards
    docker_compose up -d
    echo "Prometheus: http://localhost:9090"
    echo "Grafana:    http://localhost:3000 (admin/admin)"
    ;;
  stop)
    echo "Stopping monitoring tools..."
    docker_compose down
    echo "Monitoring tools stopped"
    ;;
  url)
    echo "prometheus:http://localhost:9090"
    echo "grafana:http://localhost:3000"
    ;;
  *)
    echo "Usage: $0 {start|stop|url}"
    exit 1
    ;;
esac
