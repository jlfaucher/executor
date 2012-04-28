@echo off
:: Put oddialog wide-char temporarily in fromt of PATH
:: and execute the command passed as argument.
:: Ex : wchar rexx oorexxtry.rex

setlocal

set PATH=%OOREXX_HOME%\bin\wchar;%PATH%
%*

endlocal