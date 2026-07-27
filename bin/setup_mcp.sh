#!/bin/bash
#
# Registers user-scoped MCP servers from other/mcp-servers.local.json
# (canonical `mcpServers` JSON shape, machine-local) via `claude mcp add`.
# Idempotent — servers that already exist are skipped. OAuth is per-machine:
# run /mcp in a claude session afterward to authenticate each server.
#
# Refresh the JSON from a configured machine with:
#   jq '.mcpServers' ~/.claude.json > other/mcp-servers.local.json

set -euo pipefail

DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SERVERS="$DOTFILES/other/mcp-servers.local.json"

if [[ ! -f "$SERVERS" ]]; then
    echo "no $SERVERS — nothing to do (see other/mcp-setup.local.md)"
    exit 0
fi
command -v claude >/dev/null 2>&1 || { echo "error: claude not on PATH" >&2; exit 1; }

jq -r 'to_entries[] | [.key, (.value.type // "http"), (.value.url // "")] | @tsv' "$SERVERS" |
while IFS=$'\t' read -r name type url; do
    if claude mcp get "$name" >/dev/null 2>&1; then
        echo "  exists: $name"
        continue
    fi
    case "$type" in
        http|sse)
            claude mcp add --scope user --transport "$type" "$name" "$url"
            ;;
        *)
            echo "  SKIP $name: type '$type' not handled — add manually" >&2
            ;;
    esac
done

echo "done — run /mcp in a claude session to authenticate each server"
