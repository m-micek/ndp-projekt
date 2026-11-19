#!/usr/bin/env bash
set -euo pipefail

# Uzupełnij oznaczone miejsca samodzielnie.
# SSH_USER, SSH_HOST i SSH_PORT ustaw przed uruchomieniem:
: "${SSH_USER:?Ustaw SSH_USER w terminalu}"
: "${SSH_HOST:?Ustaw SSH_HOST w terminalu}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/ndp_lab_ed25519}"
REMOTE_DIR="ndp-project"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$SSH_KEY" || ! -r "$SSH_KEY" ]]; then
    printf 'Nie znaleziono klucza: %s\n' "$SSH_KEY" >&2
    exit 2
fi

SSH_OPTS=(-i "$SSH_KEY" -p "$SSH_PORT" -o IdentitiesOnly=yes -o BatchMode=yes)
SCP_OPTS=(-i "$SSH_KEY" -P "$SSH_PORT" -o IdentitiesOnly=yes -o BatchMode=yes)

ssh "${SSH_OPTS[@]}" "$SSH_USER@$SSH_HOST" 'umask 077; mkdir -p ~/ndp-project/scripts; chmod 700 ~/ndp-project'

scp "${SCP_OPTS[@]}" "$ROOT/dane.txt" "$SSH_USER@$SSH_HOST:$REMOTE_DIR/dane.txt"

scp "${SCP_OPTS[@]}" "$ROOT/scripts/process.sh" "$SSH_USER@$SSH_HOST:$REMOTE_DIR/scripts/process.sh"

ssh "${SSH_OPTS[@]}" "$SSH_USER@$SSH_HOST" 'cd ~/ndp-project && bash scripts/process.sh dane.txt result.txt'
tmp_result=$(mktemp "$ROOT/.ndp-result.XXXXXXXX")
trap 'rm -f -- "$tmp_result"' EXIT
scp "${SCP_OPTS[@]}" "$SSH_USER@$SSH_HOST:$REMOTE_DIR/result.txt" "$tmp_result"
grep -Fxq 'Liczba_wierszy=4' "$tmp_result"
cmp "$ROOT/result.txt" "$tmp_result"
mv -f -- "$tmp_result" "$ROOT/remote-result.txt"
printf 'Wdrożenie i kontrola: PASS\n'
