ooRexxShell, derived from rexxtry.

This shell supports several interpreters :
- ooRexx itself
- the system address (cmd under Windows, bash under Linux)
- any other external environment (you need to modify this script, search for hostemu for an example).
The prompt indicates which interpreter is active.
By default the shell is in current address mode.
When not in ooRexx mode, you enter raw commands that are passed directly to the external environment.
When in ooRexx mode, you have a shell identical to rexxtry.
You switch from an interpreter to an other one by entering its name alone.


Something interesting (for me) :
Thanks to the ooRexx implementation of address (some commands are intercepted and executed in the
ooRexx process), you can change the current directory as if you were in a "real" shell.


Example (Windows) :
CMD> dir | find ".dll"                              raw command, no need of surrounding quotes
CMD> cd c:\program files
CMD> say 1+2                                        error, the ooRexx interpreter is not active here
CMD> oorexx say 1+2                                 you can temporarily select an interpreter
CMD> oorexx                                         switch to the ooRexx interpreter
ooRexx[CMD] 'dir oorexx | find ".dll"'              here you need to surround by quotes
ooRexx[CMD] cmd dir oorexx | find ".dll"            unless you temporarily select cmd 
ooRexx[CMD] say 1+2                                 3
ooRexx[CMD] address myHandler                       selection of the "myHandler" subcommand handler (hypothetic, just an example)
ooRexx[MYHANDLER] 'myCommand myArg'                 an hypothetic command, must be surrounded by quotes because we are in ooRexx mode.
ooRexx[MYHANDLER] myhandler                         switch to the MYHANDLER interpreter
MYHANDLER> myCommand myArg                          an hypothetic command, no need of quotes
MYHANDLER> exit                                     the exit command is supported whatever the interpreter


Current problems :
- Under Windows, if you want the colors then you must put ctext.exe in your PATH
  You can get ctext here : http://dennisbareis.com/freew32.htm
- Under Windows, if you launch oorexx from a .bat file, then you need to prepend cmd /c
  to have the doskey history working correctly.
      cmd /c ""my path to\rexx" "my path to\ooRexxShell""
- Under Windows, the default console code page is the OEMCP, which does not match the
  default ANSI code page (ACP). That bring troubles when you execute a command which
  contains letters with accent. I could bypass this problem by converting OEMCP to ACP
  in the securiy manager, but there is a more general workaround that can be used :
  Change the default code page of the console to ACP. For example, european users could
  enter this command : chcp 1252
  You must also change the font of the console, because a raster font can't display letters
  with accent. Try Lucida Console, for example.
  See:
  http://blogs.msdn.com/michkap/archive/2005/02/08/369197.aspx
  http://en.wikipedia.org/wiki/Windows-1252
- Under Windows, if you launch a GUI application then the ooRexxShell will wait until the end
  of the execution (which is not the case when launched from the command prompt).
- All platforms, when the first word of the command is an interpreter name, then it is assumed
  you want to temporarily select this interpreter. The first word is removed from the command
  passed to the subcommand handler. Ex : if you enter cmd /? then only /? will be executed.
  If you want to execute this interpreter instead of selecting it, then you can enter :
  "cmd" /?
  cmd cmd /?


See demo/hostemu_from_THE.png
for an example of shell with 4 interpreters.
Not sure it's very useful to run HostEmu from THE, but... you see the idea :-)
