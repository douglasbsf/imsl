@echo off
setlocal EnableExtensions
rem Requires gfortran with LAPACK + BLAS, e.g. MSYS2 UCRT64 + OpenBLAS.
rem This does NOT link against IMSL or Intel MKL.
set "ROOT=%~dp0.."
pushd "%ROOT%"
if not exist results mkdir results
if "%FC%"=="" set "FC=gfortran"
if "%LAPACK_LIBS%"=="" set "LAPACK_LIBS=-lopenblas"
%FC% -O0 -Wall -Wextra -fcheck=all opensource\extra_cases.f90 opensource\lapack_cases.f90 %LAPACK_LIBS% -o results\opensource.exe
if errorlevel 1 goto :failed
%FC% -O0 -Wall -Wextra -fcheck=all tools\compare.f90 -o results\compare.exe
if errorlevel 1 goto :failed
results\opensource.exe > results\opensource.txt
if errorlevel 1 goto :failed
results\compare.exe
if errorlevel 1 goto :failed
popd
exit /b 0
:failed
echo ERROR: Native Fortran build/test failed.
popd
exit /b 1
