@echo off
setlocal EnableExtensions
set "VS2022INSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat" intel64 vs2022
echo AFTER_SETVARS
echo LIB=%LIB%
where /r "C:\Program Files (x86)\Intel\oneAPI" ifmodintr.lib
call "C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\bin\fnlsetup.bat"
echo AFTER_FNL
echo LIB=%LIB%
echo LINK_FNL=%LINK_FNL%
echo LINK_FNL_IMSL=%LINK_FNL_IMSL%
echo F90FLAGS=%F90FLAGS%
echo MPI_DIR=%MPI_DIR%
if not exist "C:\Users\douglas\Projects\imsl\build\imsl" mkdir "C:\Users\douglas\Projects\imsl\build\imsl"
cd /d "C:\Users\douglas\Projects\imsl\build\imsl"
echo --- compile with LINK_FNL_IMSL ---
%F90% %F90FLAGS% /Qdiag-disable:10448 "C:\Users\douglas\Projects\imsl\examples\imsl_evcrg.f90" /exe:evcrg.exe %LINK_FNL_IMSL%
echo COMPILE_IMSL=%ERRORLEVEL%
if exist evcrg.exe (
  evcrg.exe
  echo RUN=%ERRORLEVEL%
)
echo --- compile with LINK_FNL default ---
%F90% %F90FLAGS% /Qdiag-disable:10448 "C:\Users\douglas\Projects\imsl\examples\imsl_evcrg.f90" /exe:evcrg_mkl.exe %LINK_FNL%
echo COMPILE_MKL=%ERRORLEVEL%
if exist evcrg_mkl.exe (
  evcrg_mkl.exe
  echo RUN_MKL=%ERRORLEVEL%
)
endlocal
