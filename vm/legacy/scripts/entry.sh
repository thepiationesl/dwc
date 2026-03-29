#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"
. "$SCRIPT_DIR/config.sh"

# Forward arguments to vm-start
exec "$SCRIPT_DIR/vm-start" "$@"