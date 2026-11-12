@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "ROOT=%~dp0.."
set "VS2022INSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat" intel64 vs2022
if errorlevel 1 (
  echo ERROR: oneAPI setvars failed
  exit /b 1
)
call "C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\bin\fnlsetup.bat"
if errorlevel 1 (
  echo ERROR: fnlsetup failed
  exit /b 1
)
rem oneAPI "compiler\latest\lib" is incomplete on this install; pin Classic runtime libs.
set "IFORT_LIB=C:\Program Files (x86)\Intel\oneAPI\compiler\2024.2\lib"
set "LIB=%IFORT_LIB%;%LIB%"
set "IMSL_LIB=C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\lib"
set "IMSL_INC=C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\include\dll"
set "PATH=%IMSL_LIB%;%PATH%"
if not exist "%ROOT%\results\imsl" mkdir "%ROOT%\results\imsl"
if not exist "%ROOT%\results\logs" mkdir "%ROOT%\results\logs"
if not exist "%ROOT%\build\imsl" mkdir "%ROOT%\build\imsl"
set "FAILED=0"
for %%C in (evcrg evccg evlcg gvcrg mrrrr mcrcr mucrv linear_operators lslcg lin_sol_gen rcurv csiez bclsf unlsf u4lsf ivprk svign umach ifnls) do (
  echo ==== IMSL %%C ====
  rem Prefer original sources under imsl\ (examples\* currently include those files).
  set "SRC=%ROOT%\imsl\%%C.f90"
  if not exist "!SRC!" set "SRC=%ROOT%\examples\imsl_%%C.f90"
  set "EXE=%ROOT%\build\imsl\%%C.exe"
  set "OUT=%ROOT%\results\imsl\%%C.txt"
  set "BLOG=%ROOT%\results\logs\imsl_%%C.build.log"
  set "RLOG=%ROOT%\results\logs\imsl_%%C.run.log"
  if /I "%%C"=="ifnls" (
    ifort /nologo /O2 /fpe:3 /Qdiag-disable:10448 "!SRC!" /exe:"!EXE!" > "!BLOG!" 2>&1
  ) else (
    ifort /nologo /F60000000 /fpe:3 /Qopenmp /w /Qdiag-disable:10448 /I:"%IMSL_INC%" "!SRC!" /exe:"!EXE!" imsl_dll.lib /libs:dll > "!BLOG!" 2>&1
  )
  if errorlevel 1 (
    echo # STATUS COMPILATION_ERROR> "!OUT!"
    echo # see !BLOG!>> "!OUT!"
    type "!BLOG!"
    set "FAILED=1"
  ) else (
    "!EXE!" > "!OUT!" 2> "!RLOG!"
    if errorlevel 1 (
      echo # STATUS RUNTIME_ERROR> "!OUT!"
      echo # see !RLOG!>> "!OUT!"
      type "!RLOG!"
      set "FAILED=1"
    ) else (
      type "!OUT!"
    )
  )
)
endlocal & exit /b %FAILED%
