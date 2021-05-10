ooRexxShell, derived from rexxtry.

This shell supports several interpreters:
- ooRexx itself
- the system address (cmd under Windows, sh under Linux & MacOs)
- bash, zsh
- PowerShell core (pwsh)
- any other external environment (you need to modify this script, search for hostemu for an example).
The prompt indicates which interpreter is active.
By default the shell is in ooRexx mode.
When not in ooRexx mode, you enter raw commands that are passed directly to the external environment.
When in ooRexx mode, you have a shell identical to rexxtry.
You switch from an interpreter to an other one by entering its name alone.


Something interesting (for me):
Thanks to the ooRexx implementation of address (some commands are intercepted and executed in the
ooRexx process), you can change the current directory as if you were in a "real" shell.
[JLF jul 04, 2015]
Unfortunately, that doesn't work when you use an alias to change of directory.
Now getting the current directory of the child process after each execution of a command,
and change the  current directory of the parent (ooRexxShell) accordingly.
[JLF sept 17, 2015]
Same technique under Windows.
Don't use $T in the doskey macros, use instead ^&.
Reason: $T generates 2 lines, only the first line is injected in the input queue.
Example:
doskey cdoorexx=%builder_shared_drv% ^& cd %builder_shared_dir%
works correctly in ooRexxShell, whereas
doskey cdoorexx=%builder_shared_drv% $T cd %builder_shared_dir%
does not work (only C: is injected in the input queue).


Interactive mode
================
Launch ooRexxShell without argument: You enter in the Read-Eval-Print Loop (REPL).

Example (Windows):
ooRexx[CMD]> 'dir oorexx | find ".dll"'             -- here you need to surround by quotes
ooRexx[CMD]> cmd dir oorexx | find ".dll"           -- unless you temporarily select cmd
ooRexx[CMD]> say 1+2                                -- 3
ooRexx[CMD]> cmd                                    -- switch to the cmd interpreter
CMD[ooRexx]> dir | find ".dll"                      -- raw command, no need of surrounding quotes
CMD[ooRexx]> cd c:\program files
CMD[ooRexx]> say 1+2                                -- error, the ooRexx interpreter is not active here
CMD[ooRexx]> oorexx say 1+2                         -- you can temporarily select an interpreter
CMD[ooRexx]> hostemu                                -- switch to the hostemu interpreter
HostEmu[ooRexx]> execio * diskr "install.txt" (finis stem in.  -- store the contents of the file in the stem in.
HostEmu[ooRexx]> oorexx in.=                        -- temporarily switch to ooRexx to display the stem
HostEmu[ooRexx]> exit                               -- the exit command is supported whatever the interpreter


Non-interactive mode
====================

ooRexxShell uses "parse pull" to get the next command to execute from its input queue.
When arguments are passed from the command line, they are pushed as-is to the input queue (all in one line).
You may need to protect the special characters like | ; & from the shell interpretation, using quotes or backslahes.

Example
Here no quotes needed:
CMD> oorexxshell say hello
CMD> oorexxshell 1+1=

Example
Here quotes needed to protect the '&':
CMD> oorexxshell ".true & .false ="

Example
Get all the file path included with xi:include, search in all the xml files of the current directory.
Extract the file path from href="<file path>" then test if the file "<file path>" exists.
If not found then display its path on the console.
CMD> oorexxshell '"grep xi:include *.xml"~pipe(.system | .inject {quote = 34~d2c; parse var item . "href="(quote) file (quote) . ; file } | .sort | .take 1 {item} | .select {\ SysFileExists(item)} | .console)'

Example
With as input a text file where each line is a file path: Count the number of files per extension
CMD> oorexxshell '"/Volumes/testCpp1/files.txt"~pipe(.fileLines | .inject {suffix = item~substr(item~lastpos(".")); if suffix~pos(".") == 1 & suffix~pos("/") == 0 then suffix~lower} | .sort  | .lineCount {item} | .console)' > files_analysis.txt

Example
By design, parse pull reads first the queue and then the standard input.
In the next example, "say hello2" has been pushed to the input queue of ooRexxShell,
and "say hello1" comes from the standard input.
CMD> echo say hello1 | oorexxshell say hello2
HELLO2
HELLO1

Example
To execute a set of commands using a non-interactive ooRexxShell:
CMD>  type my_commands.txt | oorexxshell <optional first command>
BASH> cat  my_commands.txt | oorexxshell <optional first command>

In the previous example, each line is interpreted one by one,
with the restrictions of the INTERPRET instruction:
- Constructions such as DO...END and SELECT...END must be complete.
- Labels within the interpreted string are not permanent and are, therefore, an error
- You cannot use a directive within an INTERPRET instruction
To execute a Rexx script, use this command:
CMD> oorexxshell call "my script path"

To replay a set of commands from an interactive ooRexxShell:
First, launch ooRexxShell.
Copy its queue name (displayed before the first prompt, also available in .ooRexxShell~queueName).
From another command prompt, execute:
CMD>  type my_commands.txt | rxqueue <queuename>
BASH> cat  my_commands.txt | rxqueue <queuename>
Back in ooRexxShell.
Press <enter>.
If you typed a command in ooRexxShell, it will be executed first.
Then each command read from the queue will be executed.


Queries
=======

?: display help.
?bt: display the backtrace of the last error (same as ?tb).
?c[lasses] c1 c2... : display classes.
?c[lasses].m[ethods] c1 c2... : display local methods per classes (cm).
?c[lasses].m[ethods].i[nherited] c1 c2... : local & inherited methods (cmi).
?d[ocumentation]: invoke ooRexx documentation.
?f[lags]: describe the flags displayed for classes & methods & routines.
?h[elp] c1 c2 ... : local description of classes.
?h[elp].i[nherited] c1 c2 ... : local & inherited description of classes (hi).
?i[nterpreters]: interpreters that can be selected.
?m[ethods] method1 method2 ... : display methods.
?p[ackages]: display the loaded packages.
?path v1 v2 ... : display value of system variable, splitted by path separator.
?r[outines] routine1 routine2... : display routines.
?s[ettings]: display ooRexxShell's settings.
?sf: display the stack frames of the last error.
?tb: display the traceback of the last error (same as ?bt).
?v[ariables]: display the defined variables.
To display the source of methods, packages or routines: add the option .s[ource].
    Short: ?cms, ?cmis, ?ms, ?ps, ?rs.

Format of an output line:
?c[lasses]:  flags class package
?m[ethods]:  flags method class package
?p[ackages:  package (full path)
?r[outines]: flags routine package

Class flags
    col 1: P=Public
    col 2: M=Mixin
Method flags
    col 3: space separator
    col 4: P=Public
    col 5: C=Class
    col 6: G=Guarded
    col 7: P=Protected
Routine flags
    col 1: P=Public

A first level of filtering is done when specifying class names or method names
or routine names. This is a filtering at object level.
Several names can be specified, the interpretation is: name1 or name2 or ...
If the package regex.cls is available, then the names starting with "/" are
regular expressions which are compiled into a pattern. The matching with this
pattern is then tested for each object's name (string):
    pattern~matches(string)
Otherwise the names are just string patterns. The character "*" has a special
meaning when first or last character, and not quoted:
    * or **        : matches everything
    "*" or "**"    : matches exactly "*" or "**", see case stringPattern
    ***            : matches all names containing "*", see case *stringPattern*
    *"*"*          : matches all names containing "*", see case *stringPattern*
    *"**"*         : matches all names containing "**", see case *stringPattern*
    *stringPattern : string~right(stringPattern~length)~caselessEquals(stringPattern)
    stringPattern* : string~left(stringPattern~length)~caselessEquals(stringPattern)
    *stringPattern*: string~caselessPos(stringPattern) <> 0
    stringPattern  : string~caselessEquals(stringPattern)

Examples:
?c bsf                          display the classes whose id is "bsf" (caseless)
?c *bsf*                        display the classes whose id contains "bsf" (caseless)
?c /.*bsf.*                     display the classes whose id contains "bsf" (caseless) (regular expression)
?m left                         display the methods whose name is "left" (caseless)
?m *left*                       display the methods whose name contains "left" (caseless)
?m /.*left.*                    display the methods whose name contains "left" (caseless) (regular expression)

A second level of filtering is done at line level.
The output of the help can be filtered line by line using these operators:
\==     strict different: line selected if none of the patterns matches the line.
==      strict equal : line selected if at least one pattern matches the line.
<>      caseless different: same as \== except caseless.
=       caseless equal: same as == except caseless.

Several operators can be specified in the query.
For a given operator, several operands can be specified.
The interpretation of
    = v1 v2 <> v3 = v4 <> v5 v6
is
    (=v1 OR =v2 OR =v4) AND <>v3 AND <>v5 AND <>v6
If the package regex.cls is available, then the operands starting with "/" are
regular expressions which are compiled into a pattern. The matching with this
pattern is then tested for each line (string):
    pattern~find(string)~matched}
Otherwise the patterns are just string patterns.
The character "*" when first or last character, and not quoted, is ignored.
    string~caselessPos(stringPattern) <> 0
    or
    string~pos(stringPattern) <> 0

Examples:
?c =string                      display the classes for which the word "string" is displayed.
?c =rgf bsf java                display the classes for which at least one of these words is displayed.
?c == /^.M                      display the mixin classes : all lines where 2nd character is "M".
?cm bsf = java                  display the methods of the class "BSF" for which the string "java" is displayed.
?cmi string \== (REXX)          display the extension methods of the class "String".
                                The package of the predefined methods is displayed (REXX).
                                By filtering out the lines which contains "(REXX)", we have the extension methods.
?m =/^...----                   Display the hidden methods: all lines containing "----" from 4th character.
?m \== /^.....G == (REXX)       Display the methods not guarded whose package is REXX:
                                all lines where 6th char <> "G" and which contains "(REXX)".


Interpreters
============

This list depends on the platform.
The shells declared in /etc/shells are automatically included.

bash:          to activate the bash interpreter.
cmd:     alias to activate the system address interpreter.
csh:           to activate the csh interpreter.
command: alias to activate the system address interpreter.
hostemu:       to activate the HostEmu interpreter.
ksh:           to activate the ksh interpreter.
oorexx:        to activate the ooRexx interpreter.
pwsh:          to activate the pwsh interpreter.
sh:            to activate the sh interpreter.
system:  alias to activate the system address interpreter.
tcsh:          to activate the tcsh interpreter.
zsh:           to activate the zsh interpreter.

If the line starts with a space, then these words are not recognized as an interpreter name.
Instead, the line is interpreted by oorexx, which maybe triggers an external command.
ooRexx[bash]> bash
bash[ooRexx]>                        You are still in ooRexxShell
bash[ooRexx]> oorexx
ooRexx[bash]>  bash                  Under MacOs, run BASH (/bin/bash)
/local/rexx/oorexx$                  You are no longer in ooRexxShell (see the prompt)
/local/rexx/oorexx$ exit 0
ooRexx[bash]>

Commands
========

To be recognized, these commands must be the first word of the input line.
If the input line starts with a space then these commands are not recognized.

color off|on: deactivate|activate the colors.
demo off|on: deactivate|activate the demonstration mode.
debug off|on: deactivate|activate the full trace of the internals of ooRexxShell.
exit: exit ooRexxShell.
infos off|on: deactivate|activate the display of informations after each execution.
prompt directory off|on: deactivate|activate the display of the directory before the prompt.
readline off: use the raw parse pull for the input.
readline on: delegate to the system readline (history, tab completion).
reload: exit the current session and reload all the packages/libraries.
security off: deactivate the security manager. No transformation of commands.
security on : activate the security manager. Transformation of commands.
trace off|on [d[ispatch]] [f[ilter]] [r[eadline]] [s[ecurity][.verbose]]: deactivate|activate the trace.
trap off|on [l[ostdigits]] [s[yntax]]: deactivate|activate the conditions traps.


Known problems under Windows
============================

- If you want the colors then you must put gci.dll in your PATH.
  You can get gci here: http://rexx-gci.sourceforge.net
  For 64-bit support and new type aliases, see https://github.com/jlfaucher/builder/tree/master/adaptations

- If you launch ooRexxShell from a .bat file, then you need to prepend cmd /c to have the
  doskey history working correctly.
      cmd /c ""my path to\rexx" "my path to\ooRexxShell""

- The doskey history is fragile. It's not rare to loose the history.

- The default console code page is the OEMCP, which does not match the default ANSI
  code page (ACP). That bring troubles when you execute a command which contains
  letters with accent. This problem could be bypassed by converting OEMCP to ACP in the
  securiy manager, but there is a more general workaround that can be used:
  Change the default code page of the console to ACP. For example, european users could
  enter this command: chcp 1252
  You must also change the font of the console, because a raster font can't display letters
  with accent. Try Lucida Console, for example.
  See:
  http://blogs.msdn.com/michkap/archive/2005/02/08/369197.aspx
  http://archives.miloush.net/michkap/archive/2005/02/08/369197.html
  http://en.wikipedia.org/wiki/Windows-1252

- Assuming you defined this doskey macro: ll=ls -lap $*
  you will see a difference of behavior between
  CMD[ooRexx]> ll
  and
  CMD[ooRexx]> cmd ll
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
        Code= 41.1
  [Note: these problems do not occur under Linux with Bash because the aliases are expanded
  only when the command is evaluated by Bash.]


Known problems under all platforms
==================================

- When the first word of the command is an interpreter name, then it is assumed you want to
  temporarily select this interpreter. The first word is removed from the command passed to
  the subcommand handler. Ex : if you enter cmd /? then only /? will be executed.
  If you want to execute this interpreter instead of selecting it, then you can enter :
  "cmd" /?
  cmd cmd /?
  "bash" --help
  bash bash --help


Demo
====

See demo/hostemu_from_THE.png
for an example of shell with 4 interpreters.
Not sure it's very useful to run HostEmu from THE, but... you see the idea :-)


History of changes
==================

-----------------------------------------------
2021 may 08

Linux, MacOs:
If the environment variable OOREXXSHELL_RLWRAP is defined then ooRexxShell
starts in mode readline off, because the history and filename completion is
managed by rlwrap. This variable is set in the script oorexxshell.
Otherwise, ooRexxShell starts in mode readline on, where the input is delegated
to bash (default behavior so far).

The history is now correctly updated when several lines are pasted.
Before, only the first line was stored in the history.

Known problem with rlwrap:
When switching from readline off (rlwrap mode) to readline on (bash readline),
the history shows the inputs entered with rlwrap because the history file is
read before each input (good).
When switching back from readline on (bash readline) to readline off (rlwrap mode),
the history doesn't show the inputs entered with bash readline, because rlwrap
reads the history file only when launching ooRexxShell, or when using the
command 'reload'. Only the inputs entered with rlwrap are visible. The history
file itself is ok, it contains the inputs entered in both modes.

Demo mode:
If the command "*/" is immediatly followed by a command sleep then the duration is
proportional to the number of characters in the comment (before, was proportional
to the number of lines).


-----------------------------------------------
2020 dec 14

Add support for PowerShell core (pwsh).
    ooRexx[bash]> pwsh
    pwsh[ooRexx]>

    Since pwsh is not (yet) supported natively as an address environment by ooRexx,
    the execution is delegated to the system interpreter:
    - cmd /c pwsh -command <raw command>
    - sh -c pwsh -command '<raw command>'

    As for the other shells, pwsh is a one-liner interpreter in ooRexxShell:
    pwsh[ooRexx]> $i=1; echo $i             # display 1
    If you split the previous command in 2 lines, it doesn't work:
    pwsh[ooRexx]> $i=1
    pwsh[ooRexx]> echo $i                   # display nothing because the variable i has no value

systemAddress has been aligned with ooRexx 5: default is "sh" for Linux/MacOs.
But note the default address() for executor and ooRexx 4 is still bash.

No longer use systemAddress for readline, because it returns "sh" which is not supported.
Now use readlineAddress which returns "bash", even if systemAddress is "sh".

Linux & MacOs: the list of interpreters includes the shells listed in /etc/shells.

"command" is a generic name to select the system interpreter.


-----------------------------------------------
2020 dec 09

If the input line starts with a space then no command recognition.

New command "goto":
    goto label
    ...
    label:
This commands allows to skip lines in a demo script.
The label is case insensitive.
The label can't be a drive letter (A:, B:, ..., Z:).

The count of coactivities is displayed only when <> 0.

Readline for bash: keep the spaces as entered by the user.

Trace of the security manager: add an option ".verbose".
By default, the trace is displayed only when the security manager is enabled.
In verbose mode, the trace is displayed each time the security manager is called.


-----------------------------------------------
2020 dec 05

"cmd" and "system" are generic names to select the system interpreter.

The readline mode is deactivated for Windows because I never succeded to have a good history management.
Now we have a robust history management, but we lose the doskey macros and the filename expansion with 'tab'.

The history filename is .oorexxshell_history (was .history_oorexxshell).
Bypass a known problem with old versions of bash: the history file must not be empty.
The history is now updated incrementally (history -a, instead of history -w).

New command "demo":
demo on|off: activate|deactivate the demonstration mode.
When the demo mode is activated, the commands are displayed slowly (only when the readline mode is deactivated).
Some commands are not displayed: demo, sleep, /*, */.

New command "infos":
infos on|off: activate|deactivate the display of the duration and coactivity count.

New command "sleep":
sleep [delay]
The default delay is .ooRexxShell~defaultSleepDelay.

New command "--" to enter a monoline comment in a demo script.

New commands "/*" and "*/" to enter multilines comments in a demo script.
If the command "*/" is immediatly followed by a command sleep then the duration is
proportional to the number of lines in the comment.

For better readability, the command names are separated from their argument:
coloroff        --> color off
coloron         --> color on
debugoff        --> debug off
debugon         --> debug on
readlineoff     --> readline off
readlineon      --> readline on
securityoff     --> security off
securityon      --> security on
traceoff        --> trace off
traceon         --> trace on
trapoff         --> trap off
trapon          --> trap on

The following commands becomes queries, it's possible to filter their output, as for any query:
sf --> ?sf
tb --> ?tb
bt --> ?bt

New query "?settings":
Display the main settings of ooRexxShell.


-----------------------------------------------
2017 sep 25

Add query ?path v1 v2 ...
Display the value of the specified system variables, splitted by path separator.
The default variable name is PATH.
The output can be filtered, as any help output.
Example (under Windows):
?path
    PATH 'C:\jlf\local\rexx\oorexx\build\executor.master\sandbox\jlf\trunk\win\cl\release\64\build'
    PATH 'C:\jlf\local\rexx\bsf4oorexx\svn\trunk\bsf4oorexx.dev\source_cc\build\win\cl\release\64'
    PATH 'C:\jlf\local\rexx\bsf4oorexx\svn\trunk\bsf4oorexx.dev\bin'
    PATH 'C:\jlf\local\nsis\Nsis_longStrings'
    PATH 'C:\jlf\local\rexx\GCI\gci-source.1.1\build\win\cl\release\64'
    ... <cut>
    PATH length: 2618
?path include lib = rexx "length: "
    include 'C:\jlf\local\rexx\oorexx\build\executor.master\sandbox\jlf\trunk\win\cl\release\64\build\api'
    include 'C:\jlf\local\rexx\oorexx\build\executor.master\sandbox\jlf\trunk\win\cl\release\64\delivery\api'
    include length: 645

    lib 'C:\jlf\local\rexx\oorexx\build\executor.master\sandbox\jlf\trunk\win\cl\release\64\build\api'
    lib 'C:\jlf\local\rexx\oorexx\build\executor.master\sandbox\jlf\trunk\win\cl\release\64\delivery\api'
    lib length: 516


-----------------------------------------------
2017 sep 24

If an ooRexx clause ends with "==" then the command line is transformed
to display the result **not condensed**.
Standard ooRexx : '1+2==' becomes 'result = 1+2; call dumpResult .true, result, 2'
Extended ooRexx : '1+2==' becomes 'options "NOCOMMANDS";1+2;call dumpResult var("result"), result, 2; options COMMANDS'
The 3rd argument '2' indicates that the output is not condensed.
The condensed output is available with extended ooRexx only.
1,2,3=
    [1,2,3]
1,2,3==
    an Array (shape [3], 3 items)
    1 : 1
    2 : 2
    3 : 3


-----------------------------------------------
2017 sep 19

Add command "sf" to display the stack frames of the last error.

dumpResult modified to support 1,2,3= with ooRexx5.
before : call dumpResult .true,1,2,3 --> raised "too many arguments"
now : result = 1,2,3; call dumpResult .true, result


-----------------------------------------------
2017 mar 06

Add query ?v[ariables]
This is for convenience, equivalent to .context~variables=


-----------------------------------------------
2017 mar 01

Light restructuration.
The internal routines that don't need to stay internal are declared ::routine. They are moved after the routine SHELL


-----------------------------------------------
2016 aug 23

Attach a security manager to the package pipe.
Not enough to avoid loosing history (under Windows)


-----------------------------------------------
2016 aug 23

Queries: add option to display the source of methods/routines/packages.


-----------------------------------------------
2016 aug 21

history more robust under Windows (no problem under Linux & MacOs).
a) To avoid a loss of history, the command "set var" is no longer passed as-is to the interpreter. Now transformed to prepend "cmd /c".
b) After empirical trials, it seems that the history is no longer lost after command error when adding the command "doskey" after the main command.Don't ask me why...

[later]
History still lost under Windows :-(


-----------------------------------------------
2016 may 22

Queries & filters.


-----------------------------------------------
2015 oct 6

Since BSF4OORexx 4.5.0, it's no longer needed to call BsfAttachToTID and BsfDetach.
Removed the useless code.


-----------------------------------------------
2015 sep 25

UNO.CLS is now loaded only if the environment variable UNO_INSTALLED is set.

Access to help sligthly reworked: go to the ooRexx web site if REXX_HOME not defined.


-----------------------------------------------
2015 Sep 1

More work on the non-interactive mode.

New commands :
readlineoff : use the raw parse pull for the input.
readlineon : delegate to the system readline (better support for history, tab completion).
securityoff : deactivate the security manager. The system commands are passed as-is to the system.
securityon : activate the security manager. The system commands are transformed before passing them to the system.


-----------------------------------------------
2015 Jul 5

Minor adaptations to let use ooRexxShell in non-interactive mode :
On startup, the current directory is not changed to the directory of the previous session.
The color's control characters are sent to the right stream (before : was always sent to stdout).


-----------------------------------------------
2012 May 31

Preload ooSQLite.


-----------------------------------------------
2012 apr 18

To properly support BSF4ooRexx, the coactivities must call BsfAttachToTID and BsfDetach.
Same adaptation as ooRexxTry.rxj : Methods 'onStart' and 'onTerminate' are dynamically
defined on the .Coactivity class by ooRexxShell.

Now, this mono-line script works correctly under ooRexxShell :
    c= {::coactivity properties=.bsf4rexx ~System.class ~getProperties; enum=properties~propertyNames;do while enum~hasMoreElements;key=enum~nextElement;value = properties~getProperty(key); .yield[.array~of(key, value)]; end}
    c~do=   -- ['java.runtime.name','Java(TM) SE Runtime Environment']
    c~do=   -- ['sun.boot.library.path','C:\Program Files\Java\jre6\bin']
    etc...

For convenience, here is the mult-lines version of the script above :
    c= {::coactivity
        properties=.bsf4rexx ~System.class ~getProperties  -- get the System properties
        enum=properties~propertyNames    -- get an enumeration of the property names

        do while enum~hasMoreElements    -- loop over enumeration
            key=enum~nextElement          -- get next element
            value = properties~getProperty(key)
        .yield[.array~of(key, value)]
        end
       }
    c~do=   -- ['java.runtime.name','Java(TM) SE Runtime Environment']
    c~do=   -- ['sun.boot.library.path','C:\Program Files\Java\jre6\bin']
You can run this script as-is from sandbox/jlf/samples/ooRexxTry/ooRexxTry.rxj


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
