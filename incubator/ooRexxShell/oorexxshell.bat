:: May be a little bit tricky to get the history of commands working good.
::
:: When this file is launched from a cmd shell (which defines the right paths),
:: then the history is ok.
::
:: When this file is launched by double-clic from the file explorer, then the
:: history does not work correctly.
::
:: I get something which works when I call this script from another script s.bat :
::     cmd /c "call oorexxshell"
:: and double-click on s.bat from the file explorer.

@echo off

:run
set errorlevel=
rexx.exe oorexxshell.rex %*
set status=%errorlevel%
if "%status%" == "200" goto run
exit /b %status%
