#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/config/properties.sh"
cd "$HOMEDIR"
if [ $# -eq 1 ]; then
  tail -f ${1}1/data/logs/k$1d.out
else
  tail -f ${1}${2}/data/logs/k$1d.out
fi