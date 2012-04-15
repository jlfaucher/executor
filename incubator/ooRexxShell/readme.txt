ooRexxShell, derived from rexxtry.

This shell supports several interpreters :
- ooRexx itself
- the system address (cmd under Windows, bash under Linux)
- any other external environment (you need to modify this script, search for hostemu for an example).
The prompt indicates which interpreter is active.
By default the shell is in ooRexx mode.
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


Known problems under Windows :

- If you want the colors then you must put gci.dll in your PATH.
  You can get gci here : http://rexx-gci.sourceforge.net
  
- If you launch ooRexxShell from a .bat file, then you need to prepend cmd /c to have the
  doskey history working correctly.
      cmd /c ""my path to\rexx" "my path to\ooRexxShell""
      
- The default console code page is the OEMCP, which does not match the default ANSI
  code page (ACP). That bring troubles when you execute a command which contains
  letters with accent. This problem could be bypassed by converting OEMCP to ACP in the
  securiy manager, but there is a more general workaround that can be used :
  Change the default code page of the console to ACP. For example, european users could
  enter this command : chcp 1252
  You must also change the font of the console, because a raster font can't display letters
  with accent. Try Lucida Console, for example.
  See:
  http://blogs.msdn.com/michkap/archive/2005/02/08/369197.aspx
  http://en.wikipedia.org/wiki/Windows-1252
  
- Assuming you defined this doskey macro : ll=ls -lap $*
  you will see a difference of behavior between
  CMD> ll
  and
  CMD> cmd ll
  and
  ooRexx[CMD]> 'll'
  and
  ooRexx[CMD]> ll
  - In the first case, the macro works as expected.
  - In the second and third case, the macro is not expanded. This is because the macro expansion 
    is done by readline (not when evaluating the command) and only the first word of the command
    line is expanded by doskey (here "cmd" or 'll' is the first word).
  - In the last case, the macro is expanded, but you don't what that...
        ls -lap
        Nonnumeric value ("LS") used in arithmetic operation
        RC= 41.1  
  [Note : these problems do not occur under Linux with Bash because the aliases are expanded
  only when the interpreter is Bash and the command is evaluated.]
 
Known problems under all platforms :

- When the first word of the command is an interpreter name, then it is assumed you want to
  temporarily select this interpreter. The first word is removed from the command passed to
  the subcommand handler. Ex : if you enter cmd /? then only /? will be executed.
  If you want to execute this interpreter instead of selecting it, then you can enter :
  "cmd" /?
  cmd cmd /?
  "bash" --help
  bash bash --help


See demo/hostemu_from_THE.png
for an example of shell with 4 interpreters.
Not sure it's very useful to run HostEmu from THE, but... you see the idea :-)


-----------------------------------------------
2012 apr 04

With extended ooRexx, the '=' shortcut is managed at the end of each clause.
Now, it's possible to write that :
    dir;rc=;unknown;rc=
The transformed command is :
    dir;
    options "NOCOMMANDS";
    rc ;
    if var("result") then call dumpResult(result); 
    options "COMMANDS";
    unknown;
    options "NOCOMMANDS";
    rc ;
    if var("result") then call dumpResult(result); 
    options "COMMANDS"

With standard ooRexx :
The '=' shortcut is managed at the end of line only (no change, was like that before).
Coactivities are no longer available, so no longer display the number of coactivities.


-----------------------------------------------
2012 jan 22

New command "tb", to display the trace back after an error.

Arrays are pretty printed in condensed form.
Ex : 
.array~of("a", 1, .array~of("b", 2), "c")= -- ['a',1,['b',2],'c']


-----------------------------------------------
2011 nov 09

No longer display error traceback.
The trace back is stored in .ooRexxShell~errorTraceback, and can be inspected later.


-----------------------------------------------
2011 oct 23

After each command interpretation, display the elapsed duration and the number
of coactivities.


-----------------------------------------------
2011 oct 13

If an ooRexx command line ends with "=" then the command line is transformed
to display the result :
Standard ooRexx : '1+2=' becomes 'call dumpResult 1+2'
Extended ooRexx : '1+2=' becomes 'options "NOCOMMANDS";1+2;call dumpResult'
The 1st transformation works only with expressions. Not intended to be used in other cases.
The 2nd transformation works with any command (expression or not).
In both case, '=' alone displays the current value of the variable RESULT.

If you need to clear the result, then do :
call clearResult


-----------------------------------------------
2011 aug 08

New command 'reload'.
Often, I modify some packages that are loaded by ooRexxShell at startup.
To benefit from the changes, I have to reload the components.
Can't do that without leaving the interpreter (to my knowledge).
When entering 'reload', the exit value 200 (arbitrary value) is returned to the
system, and tested from the script that launched rexx.
Ex (Windows) :
    :run
    cmd /c "rexx.exe "%incubator_dir%\ooRexxShell\oorexxshell.rex""
    if errorlevel 200 goto run
Good point : the history of commands is kept.
