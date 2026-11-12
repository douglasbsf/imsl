@echo off
setlocal EnableExtensions
set "VS2022INSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat" intel64 vs2022
echo === ifmodintr ===
dir "C:\Program Files (x86)\Intel\oneAPI\compiler\latest\lib\ifmodintr.lib"
dir "C:\Program Files (x86)\Intel\oneAPI\compiler\2024.2\lib\ifmodintr.lib"
cd /d "C:\Users\douglas\Projects\imsl\build\imsl"
echo program hi>hi.f90
echo print *,'hi'>>hi.f90
echo end program>>hi.f90
ifort /nologo hi.f90 /exe:hi.exe
echo HELLO_COMPILE=%ERRORLEVEL%
if exist hi.exe hi.exe
call "C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\bin\fnlsetup.bat"
echo === prepend compiler lib explicitly ===
set "LIB=C:\Program Files (x86)\Intel\oneAPI\compiler\2024.2\lib;%LIB%"
echo LIB=%LIB%
ifort /nologo /F60000000 /fpe:3 /Qopenmp /w /Qdiag-disable:10448 /I:"C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\include\dll" "C:\Users\douglas\Projects\imsl\imsl\evcrg.f90" /exe:evcrg.exe imsl_dll.lib /libs:dll
echo EVCRG=%ERRORLEVEL%
if exist evcrg.exe (
  set "PATH=C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\lib;%PATH%"
  evcrg.exe
  echo RUN=%ERRORLEVEL%
) else (
  echo NO EXE - trying without /libs:dll
  ifort /nologo /F60000000 /fpe:3 /Qopenmp /w /Qdiag-disable:10448 /I:"C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\include\dll" "C:\Users\douglas\Projects\imsl\imsl\evcrg.f90" /exe:evcrg2.exe imsl_dll.lib
  echo EVCRG2=%ERRORLEVEL%
  if exist evcrg2.exe (
    set "PATH=C:\Program Files (x86)\RogueWave\imsl\fnl-2024.1.0\win110in240x64\lib;%PATH%"
    evcrg2.exe
    echo RUN2=%ERRORLEVEL%
  )
)
endlocal
