$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$fc='C:\msys64\ucrt64\bin\gfortran.exe'
$env:PATH="C:\msys64\ucrt64\bin;$env:PATH"
New-Item -ItemType Directory -Force "$root\results\comparison","$root\results\logs","$root\results\imsl","$root\results\opensource","$root\build" | Out-Null

Write-Host '=== Open-source build/run ==='
& "$PSScriptRoot\build_opensource.ps1"
if($LASTEXITCODE -ne 0){ throw 'O build open-source falhou.' }

Write-Host '=== IMSL build/run ==='
cmd.exe /d /c "`"$PSScriptRoot\run_imsl_all.bat`"" *> "$root\results\logs\imsl_environment.log"
# Individual IMSL failures are recorded in results/imsl/*.txt

Push-Location $root
try {
  & $fc -O2 -std=f2008 tools\compare_results.f90 -o build\compare_results.exe *> results\logs\comparator.build.log
  if($LASTEXITCODE -ne 0){ throw 'Falha ao compilar tools/compare_results.f90.' }
  & build\compare_results.exe *> results\logs\comparator.run.log
  if($LASTEXITCODE -ne 0){ throw 'Falha ao executar o comparador Fortran.' }

  $rows=Import-Csv 'results\comparison\summary.tsv' -Delimiter "`t"
  $report=@(
    '# Relatorio de validacao experimental — IMSL FNL 2024.1.0 x open-source',
    '',
    "Gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'). PASS exige execucao real dos dois lados e tolerancia satisfeita.",
    '',
    '## Ambiente',
    '',
    '- IMSL: `C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0` (win110in240x64, link `imsl_dll.lib`)',
    '- Intel Fortran Classic: ifort 2021.13.1 (oneAPI 2024.2.1)',
    '- Open-source: gfortran 16.2.0 (MSYS2 UCRT64) + OpenBLAS + MINPACK + FITPACK + DOP853 + stdlib SORT + GALAHAD BNLS',
    '',
    '| Rotina | IMSL executada | Open-source executada | Erro maximo | Tolerancia | Resultado |',
    '|---|---|---|---:|---:|---|'
  )
  foreach($row in $rows) {
    $st=$row.status
    $imslExec = if($st -in @('PASS','FAIL')) {'sim'} elseif($st -eq 'NOT_APPLICABLE' -and (Test-Path "results\imsl\$($row.case).txt")) {'sim*'} else {
      $t=Get-Content "results\imsl\$($row.case).txt" -TotalCount 1 -ErrorAction SilentlyContinue
      if($t -match 'STATUS'){'nao'} else {'sim'}
    }
    $osExec = if($st -eq 'BLOCKED'){'nao'} elseif($st -in @('PASS','FAIL','NOT_APPLICABLE')){'sim'} else {
      $t=Get-Content "results\opensource\$($row.case).txt" -TotalCount 1 -ErrorAction SilentlyContinue
      if($t -match 'STATUS'){'nao'} else {'sim'}
    }
    if($row.case -eq 'ifnls' -and $st -eq 'PASS'){ $imslExec='sim (Intel NLS)'; $osExec='sim' }
    $err=$row.max_abs_error
    $tol=$row.abs_tol
    $report+="| $($row.case) | $imslExec | $osExec | $err | $tol | $st |"
  }
  $pass=($rows | Where-Object status -eq 'PASS').Count
  $report+=@(
    '',
    "## Resumo: $pass / $($rows.Count) PASS",
    '',
    'Detalhes: `results/comparison/`, logs em `results/logs/`.',
    '',
    '### Observacoes',
    '',
    '- `IFNLS` nao e rotina IMSL; e o modulo Intel `IFNLS` (locale Windows). Comparacao por string do exemplo `1234.50` -> `1.234,50`.',
    '- `U4LSF` e configurador de parametros do otimizador IMSL; o caso altera `RPARAM(4)` e resolve via `UNLSF` / MINPACK.',
    '- Autovalores sao ordenados por parte real crescente antes da comparacao.',
    '- `BCLSF` exige GALAHAD BNLS construido em `third_party/galahad/build-bnls`.'
  )
  $report | Set-Content -Encoding ascii 'results\validation_report.md'
  Write-Host "Report written. PASS=$pass / $($rows.Count)"
} finally { Pop-Location }
