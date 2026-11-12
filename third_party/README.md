# Vendored Fortran validation libraries

These are unmodified upstream source snapshots downloaded on 2026-11-12 with
`git clone --depth 1`. Their upstream license files are retained in each
directory. No replacement solver implementations are included here.

## Sources and pinned revisions

| Directory | Upstream | Revision | Intended validation use |
| --- | --- | --- | --- |
| `minpack/` | https://github.com/fortran-lang/minpack | `c0b5aea9fcd2b83865af921a7a7e881904f8d3c2` | `lmdif`/`lmdif1` for UNLSF and U4LSF |
| `fitpack/` | https://github.com/perazz/fitpack | `1907c7bad9f5c4557970e906bdd4909eb52b2d4c` | Dierckx `curfit` and `splev` (including cubic splines) for CSIEZ |
| `dop853/` | https://github.com/jacobwilliams/dop853 | tag `1.3.2`, commit `1e9d0dbf4dcbc692ca557c0467629112dd1f0ce6` | DOP853 Runge--Kutta integration for IVPRK |
| `galahad/` | https://github.com/ralna/GALAHAD | `5c81c334d58d68ad1f54ea4c8e19c616c179f464` | GALAHAD BNLS source and examples |
| `stdlib_sort/` | https://github.com/fortran-lang/stdlib | `3cef616b496e6522ace02a73f3822de026630aaf` | `stdlib_sorting` integer sorting for SVIGN |

The FITPACK snapshot is a modern Fortran translation of Paul Dierckx's
FITPACK, based on the double-precision source. The complete stdlib snapshot is
kept because `stdlib_sorting` is generated from Fypp templates and depends on
other stdlib modules; extracting one source file would not produce a
standalone, buildable module.

## Building with gfortran

Run these commands from the corresponding library directory. PowerShell syntax
is shown.

### MINPACK

MINPACK's library is a single free-form Fortran source file:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
gfortran -O2 -std=f2008 -J build -I build -c src/minpack.f90 -o build/minpack.o
ar rcs build/libminpack.a build/minpack.o
```

Alternatively, with Fortran Package Manager:

```powershell
fpm build --compiler gfortran --profile release
fpm test --compiler gfortran --profile release
```

### FITPACK

FPM determines the module compilation order:

```powershell
fpm build --compiler gfortran --profile release
fpm test --compiler gfortran --profile release
```

The low-level `curfit` and `splev` procedures are public from
`src/fitpack_core.F90`; the object-oriented curve wrapper also exposes spline
interpolation and evaluation.

### DOP853

The source uses C-preprocessor conditionals and defaults to double precision:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
gfortran -cpp -O2 -std=f2008 -J build -I build -c src/dop853_module.F90 -o build/dop853_module.o
ar rcs build/libdop853.a build/dop853_module.o
```

Or use FPM:

```powershell
fpm build --compiler gfortran --profile release
fpm test --compiler gfortran --profile release
```

### GALAHAD / BNLS

GALAHAD's supported build builds its library (including BNLS) through Meson.
For a double-precision static build without C interfaces, examples, or the
test suite:

```powershell
$env:FC = 'gfortran'
$env:CC = 'gcc'
meson setup build-gfortran --buildtype=release -Ddefault_library=static -Dsingle=false -Ddouble=true -Dquadruple=false -Dciface=false -Dpythoniface=false -Dexamples=false -Dtests=false -Dbinaries=false
meson compile -C build-gfortran
```

For the upstream BNLS test, configure with `-Dtests=true`, compile, then run:

```powershell
meson test -C build-gfortran --suite bnls
```

GALAHAD is not a one-file BNLS library: `src/bnls/bnls.F90` uses a substantial
set of internal GALAHAD packages and BLAS/LAPACK plus a sparse linear solver.
The full upstream snapshot is therefore retained. Meson can use system
OpenBLAS/HSL when available and otherwise contains fallbacks for parts of the
dependency stack; see `doc/README.meson`.

### Fortran stdlib sorting

The supported build needs CMake, Ninja (or another CMake backend), Fypp, and
gfortran:

```powershell
$env:FC = 'gfortran'
cmake -S . -B build -G Ninja -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

Client code can then use `stdlib_sorting` and call its generic `sort` routine
for integer arrays. This is the upstream routine, not a local replacement.

## Current validation blockers

The source downloads completed, but this Windows environment currently has no
`gfortran`, `fpm`, `cmake`, or `meson` executable on `PATH`, so compilation
could not be run here. GALAHAD additionally needs a C compiler and a usable
BLAS/LAPACK/sparse-solver configuration. Stdlib requires Fypp during source
generation. No Python numerical implementation is used by any validation
library; Python may only be used by upstream build tooling for Fypp/Meson.
