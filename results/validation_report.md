# Relatorio de validacao experimental — IMSL FNL 2024.1.0 × open-source

Gerado em 2026-11-12. **PASS** exige execucao real dos dois lados e tolerancia numerica satisfeita.

## Ambiente

| Item | Valor |
|---|---|
| IMSL | FNL 2024.1.0 (`C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64`) |
| Link IMSL | `imsl_dll.lib` |
| Compilador IMSL | Intel Fortran Classic `ifort` 2021.13.1 (oneAPI 2024.2.1) + VS Build Tools 2022 |
| Open-source | gfortran 16.2.0 (MSYS2 UCRT64) + OpenBLAS |
| Bibliotecas OS | LAPACK/BLAS, MINPACK, FITPACK, DOP853, stdlib SORT, GALAHAD BNLS |

## Tabela principal

| Rotina | IMSL executada | Open-source executada | Erro maximo | Tolerancia | Resultado |
|---|---|---|---:|---:|---|
| EVCRG | sim | sim (DGEEV) | 0.0E+00 | 1.0E-10 | PASS |
| EVCCG | sim | sim (ZGEEV) | 0.0E+00 | 1.0E-10 | PASS |
| EVLCG | sim | sim (ZGEEV) | 0.0E+00 | 1.0E-10 | PASS |
| GVCRG | sim | sim (DGGEV) | 0.0E+00 | 1.0E-10 | PASS |
| MRRRR | sim | sim (DGEMM) | 0.0E+00 | 1.0E-10 | PASS |
| MCRCR | sim | sim (ZGEMM) | 0.0E+00 | 1.0E-10 | PASS |
| MUCRV | sim | sim (ZGEMV) | 0.0E+00 | 1.0E-10 | PASS |
| LINEAR_OPERATORS | sim | sim (DGESV) | 0.0E+00 | 1.0E-10 | PASS |
| LSLCG | sim | sim (ZGESV) | 2.2E-16 | 1.0E-10 | PASS |
| LIN_SOL_GEN | sim | sim (DGESV) | 0.0E+00 | 1.0E-10 | PASS |
| RCURV | sim | sim (DGELS) | 4.4E-16 | 1.0E-10 | PASS |
| CSIEZ | sim | sim (FITPACK) | 1.8E-15 | 1.0E-09 | PASS |
| BCLSF | sim | sim (GALAHAD BNLS) | 5.5E-11 | 1.0E-08 | PASS |
| UNLSF | sim | sim (MINPACK LMDIF) | 0.0E+00 | 1.0E-07 | PASS |
| U4LSF | sim | sim (MINPACK + tol) | 0.0E+00 | 1.0E-07 | PASS |
| IVPRK | sim | sim (DOP853) | 5.3E-12 | 1.0E-09 | PASS |
| SVIGN | sim | sim (stdlib SORT) | 0.0E+00 | 1.0E-10 | PASS |
| UMACH | sim | sim (ISO_FORTRAN_ENV) | 0.0E+00 | 1.0E-10 | PASS |
| IFNLS | sim (Intel NLS) | sim (formatacao) | 0.0E+00 | — | PASS |

## Resumo: **19 / 19 PASS**

## Evidencias BCLSF

| Lado | Resultado |
|---|---|
| IMSL | `5.0000000000000000E-01  2.5000000000566625E-01` |
| GALAHAD BNLS | `5.0000000000000000E-01  2.4999999995045052E-01` |
| E_abs max | `5.52E-11` |

## Conclusao

Todas as 19 rotinas/interfaces foram executadas com IMSL (ou Intel NLS no caso IFNLS) e com a alternativa open-source correspondente, com equivalencia numerica dentro das tolerancias definidas. Artefatos em `results/imsl/`, `results/opensource/`, `results/comparison/`.
