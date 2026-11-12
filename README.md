# Validacao experimental — IMSL Fortran × bibliotecas open-source

Comparacao **executada de fato** entre IMSL FNL 2024.1.0 (comercial) e alternativas open-source em Fortran puro. Sem Python/NumPy/SciPy no caminho numerico.

## Resultado desta execucao (Windows)

- **19/19 PASS** com IMSL e open-source ambos executados e comparados.
- Relatorio Markdown: [`results/validation_report.md`](results/validation_report.md)
- Relatorio PDF final: [`results/validation_report_final.pdf`](results/validation_report_final.pdf)
- Comparador Fortran: `tools/compare_results.f90` → `results/comparison/summary.tsv`
- Regenerar PDF: `python tools/generate_validation_pdf.py`

## Ambiente localizado

| Componente | Caminho / versao |
|---|---|
| IMSL FNL 2024.1.0 | `C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64` |
| Setup | `...\bin\fnlsetup.bat` |
| Link usado | `imsl_dll.lib` (`LINK_FNL_IMSL`; evita MKL `mkl_intel_thread.2.dll`) |
| ifort Classic | 2021.13.1 via oneAPI 2024.2.1 |
| VS linker | Build Tools 2022 (`VS2022INSTALLDIR`) |
| gfortran | MSYS2 UCRT64 16.2.0 (`C:\msys64\ucrt64\bin`) |
| OpenBLAS | pacote MSYS2 `mingw-w64-ucrt-x86_64-openblas` |

> Nota: `compiler\latest\lib` nesta instalacao oneAPI nao contem `ifmodintr.lib`; os scripts prepending `compiler\2024.2\lib`.

## Reproduzir todos os testes

```powershell
cd C:\Users\douglas\Projects\imsl

# 1) Open-source (gfortran + OpenBLAS + third_party)
powershell -ExecutionPolicy Bypass -File .\scripts\build_opensource.ps1

# 2) IMSL (ifort + imsl_dll)
cmd /c .\scripts\run_imsl_all.bat

# 3) Comparador + relatorio
powershell -ExecutionPolicy Bypass -File .\scripts\build_and_run_all.ps1
```

Ou, apos o passo 1–2:

```powershell
$env:PATH = "C:\msys64\ucrt64\bin;$env:PATH"
gfortran -O2 -std=f2008 tools\compare_results.f90 -o build\compare_results.exe
.\build\compare_results.exe
```

### GALAHAD (necessario para BCLSF)

```bash
# MSYS2 UCRT64
export PATH=/ucrt64/bin:$PATH
cd /c/Users/douglas/Projects/imsl/third_party/galahad
meson setup build-bnls -Ddefault_library=static -Dlibblas=openblas -Dliblapack=openblas \
  -Dexamples=false -Dtests=false -Dpythoniface=false -Dbinaries=false -Dciface=false \
  -Dsingle=false -Ddouble=true
ninja -C build-bnls -j2
```

Depois reexecute `build_opensource.ps1` (caso `bclsf`).

## Estrutura

```text
examples/           # imsl_<rotina>.f90 e opensource_<rotina>.f90
imsl/               # fontes IMSL originais (incluidos pelos examples)
common/             # emit_utils e helpers open-source
third_party/        # minpack, fitpack, dop853, galahad, stdlib*
scripts/            # build_opensource.ps1, run_imsl_all.bat, build_and_run_all.ps1
tools/compare_results.f90
results/
  imsl/ opensource/ comparison/ logs/
  validation_report.md
```

## Mapeamento das 19 entradas

| Rotina | Open-source | Status tipico |
|---|---|---|
| EVCRG | LAPACK DGEEV | PASS |
| EVCCG | LAPACK ZGEEV | PASS |
| EVLCG | LAPACK ZGEEV | PASS |
| GVCRG | LAPACK DGGEV | PASS |
| MRRRR | BLAS DGEMM | PASS |
| MCRCR | BLAS ZGEMM | PASS |
| MUCRV | BLAS ZGEMV | PASS |
| LINEAR_OPERATORS | LAPACK DGESV | PASS |
| LSLCG | LAPACK ZGESV | PASS |
| LIN_SOL_GEN | LAPACK DGESV | PASS |
| RCURV | LAPACK DGELS | PASS |
| CSIEZ | FITPACK | PASS |
| BCLSF | GALAHAD BNLS | PASS |
| UNLSF | MINPACK LMDIF | PASS |
| U4LSF | MINPACK (tol) | PASS |
| IVPRK | DOP853 | PASS |
| SVIGN | stdlib SORT | PASS |
| UMACH | ISO_FORTRAN_ENV | PASS |
| IFNLS | formatacao / Intel NLS | PASS (nao e IMSL) |

Documentacao IMSL: https://help.imsl.com/fortran/common/README.html
