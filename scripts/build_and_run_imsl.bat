@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Run from an Intel Fortran Command Prompt AFTER calling IMSL fnlsetup.bat.
rem See https://help.imsl.com/fortran/common/README.html
set "ROOT=%~dp0.."
if "%F90%"=="" (
  echo ERROR: F90 environment variable not set. Run IMSL fnlsetup.bat first.
  exit /b 2
)
if "%LINK_FNL%"=="" (
  echo ERROR: LINK_FNL environment variable not set. Run IMSL fnlsetup.bat first.
  exit /b 2
)
if not exist "%ROOT%\results\imsl" mkdir "%ROOT%\results\imsl"
pushd "%ROOT%\results\imsl"
set "FAILED=0"
for %%F in ("%ROOT%\imsl\*.f90") do (
  if /I not "%%~nF"=="ifnls" (
    echo Compiling IMSL case: %%~nF
    %F90% %F90FLAGS% "%%~fF" /exe:"%%~nF.exe" %LINK_FNL% > "%%~nF.build.log" 2>&1
    if errorlevel 1 (
      echo ERROR: IMSL compile failed: %%~nF. See %%~nF.build.log
      set "FAILED=1"
    ) else (
      "%%~nF.exe" > "%%~nF.txt" 2> "%%~nF.err.log"
      if errorlevel 1 (
        echo ERROR: IMSL execution failed: %%~nF. See %%~nF.err.log
        set "FAILED=1"
      )
    )
  )
)
rem IFNLS belongs to Intel compiler Windows runtime, not IMSL.
for %%F in ("%ROOT%\imsl\ifnls.f90") do (
  echo Compiling Intel IFNLS case: %%~nF
  %F90% %F90FLAGS% "%%~fF" /exe:"%%~nF.exe" > "%%~nF.build.log" 2>&1
  if errorlevel 1 (
    echo ERROR: IFNLS compile failed. See ifnls.build.log
    set "FAILED=1"
  ) else (
    "%%~nF.exe" > "%%~nF.txt" 2> "%%~nF.err.log"
    if errorlevel 1 (
      echo ERROR: IFNLS execution failed. See ifnls.err.log
      set "FAILED=1"
    )
  )
)
popd
if "%FAILED%"=="1" exit /b 1
if not exist "%ROOT%\results\compare.exe" (
  echo ERROR: Compile the Fortran validator first with scripts\build_opensource_windows.bat.
  exit /b 2
)
if not exist "%ROOT%\results\opensource.txt" (
  echo ERROR: Run the open-source Fortran examples first.
  exit /b 2
)
pushd "%ROOT%"
results\compare.exe --strict-imsl
set "COMPARE_RESULT=%ERRORLEVEL%"
popd
if not "%COMPARE_RESULT%"=="0" exit /b %COMPARE_RESULT%
endlocal
