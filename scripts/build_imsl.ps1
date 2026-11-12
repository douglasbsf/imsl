$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$build=Join-Path $root 'build\imsl'
$results=Join-Path $root 'results\imsl'
$logs=Join-Path $root 'results\logs'
$cases=@('evcrg','evccg','evlcg','gvcrg','mrrrr','mcrcr','mucrv',
 'linear_operators','lslcg','lin_sol_gen','rcurv','csiez','bclsf',
 'unlsf','u4lsf','ivprk','svign','umach','ifnls')
New-Item -ItemType Directory -Force $build,$results,$logs | Out-Null
function Set-Status($case,$status,$reason) {
  "# STATUS $status`r`n# $reason" | Set-Content -Encoding ascii (Join-Path $results "$case.txt")
}
$ifort=Get-Command ifort.exe -ErrorAction SilentlyContinue
if(-not $ifort) {
  foreach($case in $cases){Set-Status $case 'COMPILATION_ERROR' 'ifort Classic não está no PATH.'}
  exit 0
}
if(-not $env:IMSL_INCLUDE -or -not $env:IMSL_LIB) {
  foreach($case in $cases){Set-Status $case 'COMPILATION_ERROR' 'Execute scripts\env_imsl.bat primeiro.'}
  exit 0
}
Push-Location $root
try {
  foreach($case in $cases) {
    $source="examples\imsl_$case.f90"
    $exe="$build\$case.exe"
    $buildLog=Join-Path $logs "imsl_$case.build.log"
    $args=@('/nologo','/O2','/standard-semantics',"/I$($env:IMSL_INCLUDE)",
      "/I$root\examples","/I$root",$source,"/exe:$exe")
    if($case -ne 'ifnls') {
      # LINK_FNL_IMSL designa exatamente esta combinação, sem imslmkl_dll.lib.
      $args+=@('/link',"/libpath:$($env:IMSL_LIB)",'imsl_dll.lib')
    }
    $oldPreference=$ErrorActionPreference;$ErrorActionPreference='Continue'
    & $ifort.Source @args *> $buildLog
    $exitCode=$LASTEXITCODE;$ErrorActionPreference=$oldPreference
    if($exitCode -ne 0) {
      Set-Status $case 'COMPILATION_ERROR' "Falha de compilação; consulte $buildLog"
      continue
    }
    $runLog=Join-Path $logs "imsl_$case.run.log"
    $oldPreference=$ErrorActionPreference;$ErrorActionPreference='Continue'
    & $exe > (Join-Path $results "$case.txt") 2> $runLog
    $exitCode=$LASTEXITCODE;$ErrorActionPreference=$oldPreference
    if($exitCode -ne 0) {
      Set-Status $case 'RUNTIME_ERROR' "Execução falhou; consulte $runLog"
    }
  }
} finally { Pop-Location }
