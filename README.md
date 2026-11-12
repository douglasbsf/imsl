# RotorTest — IMSL vs open-source (100% Fortran)

**Objetivo:** reproduzir um caso determinístico para cada uma das **19 entradas** da arquitetura RotorTest, executar o exemplo IMSL (quando o fornecedor estiver instalado) e sua implementação de referência **100% em Fortran**, e comparar os resultados automaticamente usando **um validador Fortran**.

**Nenhum código Python, NumPy, SciPy, Babel, pip ou runtime Python integra este projeto.** Os scripts `.sh` e `.bat` servem apenas para compilar e executar programas Fortran.

## Resultado efetivamente obtido

- **19/19 exemplos open-source em Fortran compilados e executados** neste ambiente Linux, com GNU Fortran e bibliotecas LAPACK/BLAS, em 12/11/2026.
- **19/19 verificações contra resultados analíticos/referências independentes** aprovadas pelo validador Fortran (`tools/compare.f90`).
- **0/19 comparações IMSL ↔ Fortran executadas**: não há IMSL, sua licença, nem Intel Fortran disponível no ambiente de geração. As 19 versões IMSL/Intel são fornecidas como fontes para compilação no ambiente Windows licenciado. O resultado IMSL não foi inventado.
- **Importante:** a aprovação contra um exemplo analítico não constitui equivalência completa do solver real, especialmente na otimização com limites e no integrador ODE.

Arquivos de evidência: `results/opensource.txt` e `results/comparison.tsv`. Campos `NOT_RUN` indicam ausência de execução IMSL, não sucesso.

## Estrutura

```text
imsl/
  *.f90                        # IMSL: 18 entradas + IFNLS: Intel Fortran (não IMSL)
opensource/
  lapack_cases.f90             # 12 casos em Fortran chamando BLAS/LAPACK
  extra_cases.f90              # 7 casos adicionais em Fortran
                                # (BCLSF, UNLSF, U4LSF, IVPRK, SVIGN, UMACH, IFNLS)
tools/
  compare.f90                  # Verificação analítica + comparação IMSL ↔ Fortran
scripts/
  run_opensource.sh            # Build Linux/macOS (gfortran, LAPACK/BLAS)
  build_opensource_windows.bat # Build Windows (gfortran + OpenBLAS)
  build_and_run_imsl.bat       # Build IMSL com Intel Fortran/licença
results/
  opensource.txt               # Saída real dos 19 casos Fortran
  comparison.tsv               # Resultado real do validador Fortran
  imsl/                        # Saídas IMSL geradas no ambiente licenciado
docs/
  coverage.csv                 # Mapeamento das 19 entradas
```

## Compilação no macOS

A pasta solicitada é `/Users/douglasfigueiredo/Projects/imsl`. A entrega é um ZIP: extraia o conteúdo nessa pasta; o ambiente de geração **não acessa diretamente seu Mac**.

```bash
mkdir -p /Users/douglasfigueiredo/Projects/imsl
unzip imsl-comparison-fortran.zip -d /Users/douglasfigueiredo/Projects/imsl
cd /Users/douglasfigueiredo/Projects/imsl
brew install gcc openblas
bash scripts/run_opensource.sh
```

Use `FC=gfortran-15` (ou a versão instalada) se o Homebrew não disponibilizar o atalho `gfortran`. O script detecta o `openblas` do Homebrew automaticamente. Em Linux Debian/Ubuntu, instale `gfortran liblapack-dev libblas-dev` e execute o mesmo script.

Para compilar manualmente no Linux:

```bash
gfortran -O0 -g -Wall -Wextra -fcheck=all \
  opensource/extra_cases.f90 opensource/lapack_cases.f90 \
  -llapack -lblas -o results/opensource.exe

gfortran -O0 -g -Wall -Wextra -fcheck=all \
  tools/compare.f90 -o results/compare.exe

./results/opensource.exe > results/opensource.txt
./results/compare.exe
```

## Compilação no Windows — open-source em Fortran

Instale GNU Fortran e OpenBLAS via MSYS2 UCRT64 ou equivalente. Abra o prompt correspondente e execute:

```bat
scripts\build_opensource_windows.bat
```

Se sua distribuição fornecer LAPACK/BLAS separados em vez de OpenBLAS, ajuste `LAPACK_LIBS` para `-llapack -lblas`. Esse build **não depende da IMSL nem da Intel oneMKL**.

## Compilação no Windows — IMSL em Fortran

1. Instale o IMSL FNL correspondente ao compilador Intel Fortran, configure a licença e o ambiente conforme [README oficial](https://help.imsl.com/fortran/common/README.html).
2. Use um Intel Fortran Command Prompt, rode o `fnlsetup.bat` **da instalação IMSL** para definir `F90`, `F90FLAGS` e `LINK_FNL`.
3. Execute o build open-source acima (para criar `results/opensource.txt` e o validador Fortran).
4. Execute:

```bat
scripts\build_and_run_imsl.bat
```

O script compila/executa os exemplos IMSL, escreve `results\imsl\<case>.txt` e executa `results\compare.exe --strict-imsl`. A opção `--strict-imsl` reprova a execução caso falte qualquer saída requerida. Para comparação não estrita: `results\compare.exe --imsl`.

**Atenção:** os exemplos IMSL foram elaborados com interfaces documentadas, mas ainda **não compilados** contra a versão exata do pacote RotorTest; variações de interfaces e convenções de precisão devem ser verificadas com o compilador e as bibliotecas instalados. Não incluímos binaries, runtime, arquivos de licença ou código proprietário da IMSL.

## Metodologia e limites

| Rotinas | Implementação de referência em Fortran | O que foi efetivamente testado |
|---|---|---|
| EVCRG, EVCCG, EVLCG, GVCRG | LAPACK `DGEEV`, `ZGEEV`, `DGGEV` | Autovalores e resíduos de autovetores em matrizes pequenas |
| MRRRR, MCRCR, MUCRV | BLAS `DGEMM`, `ZGEMM`, `ZGEMV` | Produtos matriciais e matriz-vetor |
| linear_operators, LSLCG, LIN_SOL_GEN | LAPACK `DGESV`, `ZGESV` | Soluções lineares específicas |
| RCURV | LAPACK `DGELS` | Ajuste de polinômio quadrático |
| CSIEZ | Fortran + LAPACK `DGESV` | Interpolação cúbica *not-a-knot* |
| BCLSF | Exemplo de Levenberg–Marquardt projetado + LAPACK `DGESV` | Solução com limite superior ativo; **não é substituição genérica de BCLSF** |
| UNLSF, U4LSF | Exemplo Levenberg–Marquardt simplificado + LAPACK `DGESV` | Rosenbrock sem limites, com duas configurações de tolerância |
| IVPRK | Integrador RK4 escrito em Fortran | `y'=-y`; **método diferente do IMSL RK-Verner 5/6** |
| SVIGN | Ordenação por inserção em Fortran | Cinco inteiros |
| UMACH | `ISO_FORTRAN_ENV` | Unidade de saída funcional |
| IFNLS | Formatação específica por Fortran | String `1.234,50` apenas para o teste; **IFNLS é do Intel Fortran, não IMSL** |

As 12 primeiras entradas usam bibliotecas LAPACK/BLAS de fato. As outras 7 são **implementações didáticas open-source inteiramente Fortran**, não simulações de SciPy. Para migração de produção de `UNLSF`, avaliar diretamente [MINPACK em Fortran](https://github.com/fortran-lang/minpack); de `BCLSF`, avaliar [GALAHAD BNLS](https://github.com/ralna/GALAHAD); de `IVPRK`, avaliar [DOP853 em Fortran](https://github.com/jacobwilliams/dop853). Essas bibliotecas adicionais **não foram integradas/validadas neste protótipo**.

O validador compara entradas/saídas com tolerâncias por caso (numéricas absolutas): `1e-8` em geral, `1e-6` para `UNLSF/U4LSF`, `1e-5` para `BCLSF/IVPRK`. Autovetores não são comparados componente a componente porque sua orientação/fase é arbitrária; os exemplos verificam resíduos de autovetores. `IFNLS` usa comparação de string específica do exemplo, que pode depender do locale configurado no Windows.

**Não conclua equivalência em produção a partir desses casos pequenos.** A próxima fase é testar valores reais do RotorTest, tolerâncias exigidas pelo produto, limites ativos, condicionamento das matrizes, convergência e desempenho.

## Documentação

- IMSL FNL: https://help.imsl.com/fortran/common/README.html
- IMSL BCLSF: https://help.imsl.com/fortran/2025.1/html/fnlmath/current/BCLSF.htm
- IMSL RCURV: https://help.imsl.com/fortran/2025.1/html/fnlstat/current/RCURV.htm
- LAPACK: https://www.netlib.org/lapack/
- BLAS/OpenBLAS: https://github.com/OpenMathLib/OpenBLAS
