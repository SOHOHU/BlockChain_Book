#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/config/properties.sh"

if [ $# -eq 2 ]; then
  echo "${1} ${2}"
  "$SCRIPT_DIR/2-1.deletedata.sh" "${1}" "${2}"
  "$SCRIPT_DIR/2-2.initnodes.sh" "${1}" "${2}"
  exit
fi

"$SCRIPT_DIR/2-1.deletedata.sh"
"$SCRIPT_DIR/2-2.initnodes.sh"
