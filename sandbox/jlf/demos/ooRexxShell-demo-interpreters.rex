prompt off directory
demo on

--------------
-- ooRexxShell
--------------

/*
ooRexxShell, derived from rexxtry.
*/
sleep no prompt

/*
This shell supports several interpreters:
- ooRexx itself
- the system address (cmd under Windows, sh or bash under Linux and MacOs)
- PowerShell core (pwsh)
- any other external environment (you need to modify ooRexxShell, search for hostemu for an example).
*/
sleep no prompt

/*
The prompt indicates which interpreter is active.
By default the shell is in ooRexx mode: ooRexx[bash]>
When the interpreter is ooRexx, the value of address() is displayed between [].
*/
sleep
say "hello"
sleep
say 1+2
sleep

/*
If an ooRexx clause ends with "=" then the clause is transformed to display the result :
'1+2=' becomes 'options "NOCOMMANDS"; 1+2 ; call dumpResult; options "COMMANDS"'
'=' alone displays the current value of the variable RESULT.
*/
sleep
1+2=
sleep
(1,2)=          -- When "=" then the arrays are displayed in condensed form
sleep
(1,2)==         -- When "==" then the arrays are displayed one item per line
sleep

/*
You have access to Java.
*/
sleep
jsystem = bsf.loadClass('java.lang.System')
sleep
properties = jsystem~getProperties
sleep
enum = properties~propertyNames
sleep
do while enum~hasMoreElements; key=enum~nextElement; say "key:" left("["key"]",30) "value: ["properties~getProperty(key)"]"; end
sleep 10

/*
A shell command can be used in ooRexx mode, surrounded with quotes.
*/
sleep
'ls -lap *demo*.txt'
sleep 5

/*
When not in ooRexx mode, you enter raw commands that are passed directly to the external environment.
You switch from an interpreter to an other one by entering its name alone.
To get the list of all interpreter names, enter this command:
?i[nterpreters]
Under Linux & MacOs, this list includes the shells in /etc/shells.
*/
sleep
?interpreters
sleep 7

/*
'cmd' 'command' and "system" are aliases to select the system interpreter.
*/
sleep
system
sleep

/*
Now the default interpreter is the system shell.
No need to surround the commands with quotes.
*/
sleep
ls -lap *demo*.cast
sleep

/*
HostEmu is a subcommand environment that partially emulates a TSO/CMS environment.
*/
sleep
hostemu
sleep

/*
Now the default interpreteur is HostEmu.
No need to surround the commands with quotes.
*/
sleep

/*
EXECIO is an I/O mechanism.
The following command will read the 10 first lines from the file "_readme-demos.txt".
They are stored in the stem named "lines.".
*/
sleep
execio 10 diskr "_readme-demos.txt" (finis stem lines.
sleep

/*
When in HostEmu mode, the ooRexx expressions are not recognized
*/
sleep
lines.=
sleep

/*
You can switch temporarily to ooRexx to display the result.
For that, start your command line with "oorexx".
*/
sleep
oorexx lines.=
sleep

/*
Switch to PowerShell core.
pwsh
*/
sleep
pwsh
sleep

/*
Now the default interpreter is pwsh.
No need to surround the commands with quotes.
*/
sleep no prompt

goto get-command

/*
Display the name and last write time of the 4 last files of the current directory:
*/
sleep
Get-ChildItem | Select-Object -Property Name, LastWriteTime -Last 4
sleep

/*
List the files of ooRexxShell, sorted from the largest file to the smallest file:
*/
sleep
Get-ChildItem -Path ../../../incubator/ooRexxShell -File | Sort-Object -Property Length -Descending
sleep

get-command:
/*
Find the commands containing "rexx":
*/
sleep
get-command *rexx* | select -property name, source
sleep

/*
Same command, send the output to the rexx queue without the table headers.
The empty lines are still in the output, they will be filtered on ooRexx side.
*/
sleep
get-command *rexx* | select -property name, source | format-table -HideTableHeaders | rxqueue
sleep

/*
Collect the lines of the rexx queue in an array, and then parse the lines to create an ooRexx directory.
*/
sleep
oorexx .rexxqueue~new~makearray~select{item <> ""}~reduce(.directory~new){parse value item~space with name source; accu[name]=source}=
sleep

/*
Back to the ooRexx interpreter, by entering "oorexx" alone.
*/
sleep
oorexx
sleep
say "The default interpreter is now ooRexx"
sleep

/*
End of demonstration.
*/
demo off
