#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
bash -n scripts/process.sh
bash -n scripts/deploy.sh
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
expect_failure() {
  expected=$1
  shift
  actual=0
  "$@" >"$tmp/stdout" 2>"$tmp/stderr" || actual=$?
  [[ $actual -eq $expected ]] || {
    printf 'Oczekiwano kodu %s, otrzymano %s\n' "$expected" "$actual" >&2
    return 1
  }
}
bash scripts/process.sh dane.txt "$tmp/out.txt"
grep -Fxq 'Liczba_wierszy=4' "$tmp/out.txt"
cp "$tmp/out.txt" "$tmp/first.txt"
bash scripts/process.sh dane.txt "$tmp/out.txt"
cmp "$tmp/first.txt" "$tmp/out.txt"
printf 'alfa\nbeta' >"$tmp/no-lf.txt"
bash scripts/process.sh "$tmp/no-lf.txt" "$tmp/no-lf-out.txt"
grep -Fxq 'Liczba_wierszy=2' "$tmp/no-lf-out.txt"
expect_failure 3 bash scripts/process.sh "$tmp/missing.txt" "$tmp/error-out.txt"
[[ ! -e "$tmp/error-out.txt" ]]
cp dane.txt "$tmp/input.txt"
expect_failure 2 bash scripts/process.sh "$tmp/input.txt" "$tmp/input.txt"
cmp dane.txt "$tmp/input.txt"
ln -s "$tmp/input.txt" "$tmp/alias.txt"
expect_failure 2 bash scripts/process.sh "$tmp/input.txt" "$tmp/alias.txt"
cmp dane.txt "$tmp/input.txt"
ln "$tmp/input.txt" "$tmp/hardlink.txt"
expect_failure 2 bash scripts/process.sh "$tmp/input.txt" "$tmp/hardlink.txt"
cmp dane.txt "$tmp/input.txt"
: >"$tmp/empty.txt"

expect_failure 4 bash scripts/process.sh "$tmp/empty.txt" "$tmp/empty-out.txt"

[[ ! -e "$tmp/empty-out.txt" ]]

grep -Fq 'Pusty plik' "$tmp/stderr"

printf 'PASS: kontrola lokalna\n'
