ooRexxShell, derived from rexxtry.

This shell supports several interpreters:
- ooRexx itself
- the system address (cmd under Windows, bash under Linux)
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


Help
====

?: display help.
?c[lasses] c1 c2... : display classes.
?c[lasses].m[ethods] c1 c2... : display local methods per classes (cm).
?c[lasses].m[ethods].i[nherited] c1 c2... : local & inherited methods (cmi).
?d[ocumentation]: invoke ooRexx documentation.
?f[lags]: describe the flags displayed for classes & methods.
?h[elp] c1 c2 ... : local description of classes.
?h[elp].i[nherited] c1 c2 ... : local & inherited description of classes (hi).
?i[nterpreters]: interpreters that can be selected.
?m[ethods] method1 method2 ... : display methods.
?p[ackages]: display the loaded packages.
?r[outines] routine1 routine2... : display routines.
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
==      strict equal : line selected if at least one pattern matches the lines.
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
cmd: to activate the cmd interpreter (if available).
bash: to activate the bash interpreter (if available).
hostemu: to activate the HostEmu interpreter (if available).
oorexx: to activate the ooRexx interpreter.


Commands
========

To be recognized, these commands must be the first word of the input line.

bt: display the backtrace of the last error (same as tb).
coloroff: deactivate the colors.
coloron : activate the colors.
debugoff: deactivate the full trace of the internals of ooRexxShell.
debugon : activate the full trace of the internals of ooRexxShell.
exit: exit ooRexxShell.
readlineoff: use the raw parse pull for the input.
readlineon : delegate to the system readline (history, tab completion).
reload: exit the current session and reload all the packages/librairies.
securityoff: deactivate the security manager. No transformation of commands.
securityon : activate the security manager. Transformation of commands.
tb: display the traceback of the last error (same as bt).
traceoff [d[ispatch]] [f[ilter]] [r[eadline]] [s[ecurity]]: deactivate the trace.
traceon  [d[ispatch]] [f[ilter]] [r[eadline]] [s[ecurity]]: activate the trace.
trapoff [l[ostdigits]] [s[yntax]]: deactivate the conditions traps.
trapon  [l[ostdigits]] [s[yntax]]: activate the conditions traps.


Known problems under Windows
============================

- If you want the colors then you must put gci.dll in your PATH.
  You can get gci here: http://rexx-gci.sourceforge.net

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
