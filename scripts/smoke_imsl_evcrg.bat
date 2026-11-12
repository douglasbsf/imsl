@echo off
setlocal EnableExtensions
set "VS2022INSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat" intel64 vs2022
if errorlevel 1 (
  echo ERROR: setvars failed
  exit /b 1
)
where link
where ifort
call "C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\bin\fnlsetup.bat"
if errorlevel 1 (
  echo ERROR: fnlsetup failed
  exit /b 1
)
echo F90=%F90%
echo F90FLAGS=%F90FLAGS%
echo LINK_FNL=%LINK_FNL%
echo FNL_VERSION=%FNL_VERSION%
set "ROOT=%~dp0.."
if not exist "%ROOT%\results\imsl" mkdir "%ROOT%\results\imsl"
pushd "%ROOT%\results\imsl"
%F90% %F90FLAGS% /Qdiag-disable:10448 "%ROOT%\imsl\evcrg.f90" /exe:evcrg.exe %LINK_FNL% > evcrg.build.log 2>&1
echo COMPILE_EXIT=%ERRORLEVEL%
type evcrg.build.log
if not exist evcrg.exe (
  echo NO EXE
  popd
  exit /b 2
)
evcrg.exe > evcrg.txt 2> evcrg.err.log
echo RUN_EXIT=%ERRORLEVEL%
echo ---- stdout ----
type evcrg.txt
echo ---- stderr ----
type evcrg.err.log
popd
endlocal
