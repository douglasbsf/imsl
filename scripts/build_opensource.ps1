param([switch]$KeepBuild)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$fc = 'C:\msys64\ucrt64\bin\gfortran.exe'
$bin = 'C:\msys64\ucrt64\bin'
$lib = 'C:\msys64\ucrt64\lib'
$env:PATH = "$bin;$env:PATH"
$build = Join-Path $root 'build\opensource'
$results = Join-Path $root 'results\opensource'
$logs = Join-Path $root 'results\logs'
$cases = @('evcrg','evccg','evlcg','gvcrg','mrrrr','mcrcr','mucrv',
 'linear_operators','lslcg','lin_sol_gen','rcurv','csiez','bclsf',
 'unlsf','u4lsf','ivprk','svign','umach','ifnls')
New-Item -ItemType Directory -Force $build,$results,$logs | Out-Null
if (-not $KeepBuild) { Get-ChildItem $build -File -ErrorAction SilentlyContinue | Remove-Item -Force }

function Invoke-Compile([string]$Name,[string[]]$Arguments) {
  $log = Join-Path $logs "opensource_$Name.build.log"
  $oldPreference=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  & $fc @Arguments *> $log
  $exitCode=$LASTEXITCODE
  $ErrorActionPreference=$oldPreference
  if ($exitCode -ne 0) { throw "Falha ao compilar $Name; consulte $log" }
}
function Set-Status([string]$Case,[string]$Status,[string]$Reason) {
  "# STATUS $Status`r`n# $Reason" | Set-Content -Encoding ascii (Join-Path $results "$Case.txt")
}

if (-not (Test-Path $fc)) { throw "gfortran não encontrado em $fc" }
Push-Location $root
try {
  $common = @('-O2','-std=f2018','-Wall','-Wextra','-J',"$build",'-I',"$build")
  Invoke-Compile 'minpack' ($common + @('-c','third_party\minpack\src\minpack.f90','-o',"$build\minpack.o"))
  Invoke-Compile 'fitpack' ($common + @('-cpp','-I','third_party\fitpack\src','-c',
    'third_party\fitpack\src\fitpack_core.F90','-o',"$build\fitpack_core.o"))
  Invoke-Compile 'dop853' ($common + @('-cpp','-c','third_party\dop853\src\dop853_module.F90',
    '-o',"$build\dop853_module.o"))
  Invoke-Compile 'emit_utils' ($common + @('-c','common\emit_utils.f90','-o',"$build\emit_utils.o"))
  Invoke-Compile 'opensource_cases' ($common + @('-c','common\opensource_cases.f90',
    '-o',"$build\opensource_cases.o"))

  $objects = @("$build\opensource_cases.o","$build\emit_utils.o","$build\minpack.o",
    "$build\fitpack_core.o","$build\dop853_module.o")
  foreach ($case in $cases) {
    if ($case -eq 'svign') {
      Invoke-Compile 'stdlib_sorting_int32' ($common + @('-c',
        'third_party\stdlib_sort_generated\stdlib_sorting_int32.f90',
        '-o',"$build\stdlib_sorting_int32.o"))
      $args=$common+@('examples\opensource_svign.f90',"$build\stdlib_sorting_int32.o",
        "$build\emit_utils.o",'-o',"$build\$case.exe")
    } elseif ($case -eq 'bclsf') {
      $galahadLib = Join-Path $root 'third_party\galahad\build-bnls\libgalahad_double.a'
      $galahadMod = Join-Path $root 'third_party\galahad\build-bnls'
      if (-not (Test-Path $galahadLib)) {
        Set-Status $case 'BLOCKED' 'GALAHAD BNLS ainda nao foi construido (meson/ninja).'
        continue
      }
      $modDirs = Get-ChildItem $galahadMod -Recurse -Filter 'galahad_bnls_double.mod' |
        Select-Object -First 1 -ExpandProperty DirectoryName
      if (-not $modDirs) {
        Set-Status $case 'BLOCKED' 'Modulo GALAHAD_BNLS_double nao encontrado apos o build.'
        continue
      }
      $args=$common+@('-fopenmp','-I',"$modDirs",'examples\opensource_bclsf.f90',"$galahadLib",
        '-L',"$lib",'-lopenblas','-fopenmp','-o',"$build\$case.exe")
      $env:OMP_CANCELLATION='TRUE'
      $env:OMP_PROC_BIND='TRUE'
    } else {
      $args=$common+@("examples\opensource_$case.f90")+$objects+@('-L',"$lib",
        '-lopenblas','-o',"$build\$case.exe")
    }
    try { Invoke-Compile $case $args }
    catch { Set-Status $case 'COMPILATION_ERROR' $_.Exception.Message; continue }
    $runLog=Join-Path $logs "opensource_$case.run.log"
    $outFile=Join-Path $results "$case.txt"
    $oldPreference=$ErrorActionPreference;$ErrorActionPreference='Continue'
    $output = & "$build\$case.exe" 2> $runLog
    $exitCode=$LASTEXITCODE
    $ErrorActionPreference=$oldPreference
    if ($exitCode -ne 0) {
      Set-Status $case 'RUNTIME_ERROR' "Execução falhou; consulte $runLog"
    } else {
      ($output -join "`n") + "`n" | Set-Content -Encoding ascii $outFile
    }
  }
} finally { Pop-Location }
