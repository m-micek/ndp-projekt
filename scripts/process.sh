#!/usr/bin/env bash
set -euo pipefail

if (($# != 2)); then
    printf 'Użycie: bash process.sh WEJŚCIE WYJŚCIE\n' >&2
    exit 2
fi

input=$1
output=$2

if [[ ! -f "$input" ]]; then
    printf 'Brak pliku wejściowego: %s\n' "$input" >&2
    exit 3
fi

# Nie podążaj za dowiązaniami symbolicznymi wskazującymi na dowolny plik.
if [[ -L "$output" ]]; then
    printf 'Ścieżka wyjściowa nie może być dowiązaniem symbolicznym: %s\n' "$output" >&2
    exit 2
fi

if [[ "$input" -ef "$output" ]]; then
    printf 'Plik wyjściowy nie może być plikiem wejściowym: %s\n' "$output" >&2
    exit 2
fi

# wc -l liczy znaki nowej linii, nie ostatni wiersz bez końcowego LF.
count=$(awk 'END { print NR }' "$input")

# Zapis tymczasowy w katalogu docelowym chroni przed podmianą wyjścia na
# dowiązanie symboliczne między sprawdzeniem a otwarciem pliku.
output_dir=$(dirname -- "$output")
tmp=$(mktemp "$output_dir/.process.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
printf 'Liczba_wierszy=%s\n' "$count" > "$tmp"

# Ponowna kontrola i atomowa podmiana bez podążania za dowiązaniem symbolicznym.
if [[ -L "$output" || "$input" -ef "$output" ]]; then
    printf 'Niebezpieczna ścieżka wyjściowa: %s\n' "$output" >&2
    exit 2
fi
mv -fT -- "$tmp" "$output"

[[ -s "$input" ]] || {

  printf 'Pusty plik\n' >&2

  exit 4

}
