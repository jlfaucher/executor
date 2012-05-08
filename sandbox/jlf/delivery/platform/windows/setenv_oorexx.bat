@echo off
if defined echo echo %echo%

set oorexx_version=ooRexx sandbox-jlf
echo Setting environment for running %oorexx_version%

title %oorexx_version%

set OOREXX_HOME=%~dp0
set OOREXX_HOME=%OOREXX_HOME:~0,-1%

set PATH=%OOREXX_HOME%\bin;%PATH%
set PATH=%OOREXX_HOME%\bin\bchar;%PATH%
set PATH=%OOREXX_HOME%\packages;%PATH%

set INCLUDE=%OOREXX_HOME%\include

set LIB=%OOREXX_HOME%\lib

call "%OOREXX_HOME%\bsf4oorexx\install\setEnvironment4BSF.cmd"
