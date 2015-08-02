:: Helper to redirect the messages to stdout instead of the log file.
:: Typically used from Visual C++ to get the error messages in the output window.
:: Example :
:: Change the configuration type to Makefile, and enter this build command line
:: to build the wide-char version of oodialog :
:: %src_drv%%src_dir%\makeorx_verbose.bat DEBUG oodialogW

@echo off
set NO_BUILD_LOG=1
%src_drv%
cd %src_drv%%src_dir%
call makeorx %*
