@echo off
if defined echo echo %echo%

set oorexx_version=ooRexx sandbox-jlf
echo Setting environment for running %oorexx_version%

set oorexx_delivery=%~dp0
set oorexx_delivery=%oorexx_delivery:~0,-1%

title %oorexx_version%

set PATH=%oorexx_delivery%\bin;%PATH%
set PATH=%oorexx_delivery%\packages;%PATH%
set INCLUDE=%oorexx_delivery%\include
set LIB=%oorexx_delivery%\lib
