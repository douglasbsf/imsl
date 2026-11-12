#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p results
: "${FC:=gfortran}"
: "${FFLAGS:=-O0 -g -Wall -Wextra -fcheck=all}"

# On macOS: brew install gcc openblas
# On Debian: apt install gfortran liblapack-dev libblas-dev
if [[ -n "${LAPACK_LIBS:-}" ]]; then
  read -r -a libflags <<< "$LAPACK_LIBS"
elif command -v brew >/dev/null 2>&1 && brew --prefix openblas >/dev/null 2>&1; then
  prefix="$(brew --prefix openblas)"
  libflags=("-L${prefix}/lib" "-Wl,-rpath,${prefix}/lib" -lopenblas)
else
  libflags=(-llapack -lblas)
fi

$FC $FFLAGS opensource/extra_cases.f90 opensource/lapack_cases.f90 "${libflags[@]}" -o results/opensource.exe
$FC $FFLAGS tools/compare.f90 -o results/compare.exe
./results/opensource.exe > results/opensource.txt
./results/compare.exe "$@"
