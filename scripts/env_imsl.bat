@echo off
rem Configure Intel oneAPI + IMSL FNL for this machine.
set "VS2022INSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat" intel64 vs2022
if errorlevel 1 exit /b %errorlevel%
call "C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\bin\fnlsetup.bat"
if errorlevel 1 exit /b %errorlevel%
rem Pin Classic runtime libs: compiler\latest\lib is incomplete here.
set "LIB=C:\Program Files (x86)\Intel\oneAPI\compiler\2024.2\lib;%LIB%"
set "IMSL_ROOT=C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64"
set "IMSL_INCLUDE=%IMSL_ROOT%\include\dll"
set "IMSL_LIB=%IMSL_ROOT%\lib"
set "PATH=%IMSL_LIB%;%PATH%"
rem Prefer IMSL-internal BLAS/LAPACK DLL (no MKL .2 runtime required).
set "LINK_FNL=%LINK_FNL_IMSL%"
