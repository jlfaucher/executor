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
ooRexx[CMD]> address jdor                           -- select JDOR as command handler
ooRexx[JDOR]> newImage 300 500                      -- create new bitmap
ooRexx[JDOR]> winShow                               -- show frame
ooRexx[JDOR]> moveTo (300-50)/2 (500-50)/2          -- mix JDOR command and ooRexx expressions
ooRexx[JDOR]> drawRect 50 50
ooRexx[CMD]> cmd                                    -- switch to the cmd interpreter
CMD> dir | find ".dll"                              -- raw command, no need of surrounding quotes
CMD> cd c:\program files
CMD> say 1+2                                        -- error, the ooRexx interpreter is not active here
CMD> oorexx say 1+2                                 -- you can temporarily select an interpreter
CMD> hostemu                                        -- switch to the hostemu interpreter
HostEmu> execio * diskr "install.txt" (finis stem in.  -- store the contents of the file in the stem in.
HostEmu> oorexx in.=                                -- temporarily switch to ooRexx to display the stem
HostEmu> exit                                       -- the exit command is supported whatever the interpreter


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
By design, parse pull reads first the input queue and then the standard input.
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
Solution 1
    < my_commands.txt
Solution 2
    Copy the input queue name (displayed before the first prompt, also available in .ooRexxShell~queueName).
    From another command prompt, execute:
    CMD>  type my_commands.txt | rxqueue <queuename>
    BASH> cat  my_commands.txt | rxqueue <queuename>
    Back in ooRexxShell.
    Press <enter>.
    If you typed a command in ooRexxShell, it will be executed first.
    Then each command read from the input queue will be executed.


Queries
=======

Most queries depend on extensions only available with Executor.

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
ooRexx[sh]> bash
bash>                                You are still in ooRexxShell
bash> oorexx
ooRexx[sh]>  bash                    Under MacOs, run BASH (/bin/bash)
/local/rexx/oorexx$                  You are no longer in ooRexxShell (see the prompt)
/local/rexx/oorexx$ exit 0           Return to ooRexxShell
ooRexx[sh]>

Commands
========

To be recognized, these commands must be the first word of the input line.
If the input line starts with a space then these commands are not recognized.

/* alone: Used in a demo to start a multiline comment. Ended by */ alone.
< filename: read the file and put each line in the queue.
color off|on: deactivate|activate the colors.
color codes off|on: deactivate|activate the display of the color codes.
debug off|on: deactivate|activate the full trace of the internals of ooRexxShell.
demo off|on|fast: deactivate|activate the demonstration mode.
exit: exit ooRexxShell.
goto <label>: used in a demo script to skip lines, until <label>: (note colon) is reached.
indent+ | indent-: used by the command < to show the level of inclusion.
infos off|on|next: deactivate|activate the display of informations after each execution.
prompt off|on [a[ddress]] [d[irectoy]] [i[nterpret]]: deactivate|activate the display of the prompt components.
readline off: use the raw parse pull for the input.
readline on: delegate to the system readline (history, tab completion).
reload: exit the current session and reload all the packages/libraries.
security off: deactivate the security manager. No transformation of commands.
security on : activate the security manager. Transformation of commands.
sleep [n] [no prompt]: used in demo mode to pause during n seconds (default 2 sec).
test regression: activate the regression testing mode.
trace off|on [d[ispatch]] [f[ilter]] [r[eadline]] [s[ecurity][.verbose]]: deactivate|activate the trace.
trap off|on [l[ostdigits]] [nom[ethod]] [nos[tring]] [nov[alue]] [s[yntax]]: deactivate|activate the conditions traps.


Customization
=============
The customization files are searched first in the portable directory (if applicable),
then in the user's home directory. It's possible to define customization files in
both locations.
- The optional file ".oorexxshell_customization.rex" is loaded before any
  preloaded package. Typically used for color settings.
- A second optional file ".oorexxshell_customization2.rex" is loaded after all
  preloaded packages.
Example of customization:
    -- Better to limit the customization to the interactive mode
    if .ooRexxShell~isInteractive then do
        -- bypass the Windows bug "any byte >= 128 is replaced by \0"
        .ooRexxShell~readline = .true -- .false by default under Windows because history often broken

        -- color settings for white background
        .color~background = "white"
        .ooRexxShell~infoColor = "green"
        .ooRexxShell~promptColor = "yellow"

        -- a color can be defined with an ANSI Escape Sequence
        .color~background = d2c(27)"[1;32m" -- bgreen

        -- a color can be defined with several styles
        .ooRexxShell~errorColor = "underline blinking bred"

        -- disable the colors
        .ooRexxShell~showColor = .false

        -- Prompt setting
        .ooRexxShell~promptDirectory = .false -- Don't display the current directory
        .ooRexxShell~promptInterpreter = .false -- Don't display the current interpreter name
        .ooRexxShell~promptAddress = .false -- Don't display the current system address
        .ooRexxShell~showInfos = .false -- Don't show duration and number of coactivities

        -- Error management
        .ooRexxShell~trapLostDigits = .false
        .ooRexxShell~trapNoMethod = .true
        .ooRexxShell~trapNoString = .true
        .ooRexxShell~trapNoValue = .true -- raise an error when using an uninitialized variable
        .ooRexxShell~trapSyntax = .false -- ooRexxShell will be interrupted at the first syntax error

        -- Select the UTF-8 code page (Windows only)
        "chcp 65001"

        -- Load a package
        -- if silentLoaded is false then a message is displayed when the package has been loaded successfully.
        -- if silentNotLoaded is false then a message is displayed when the package can't be loaded.
        -- if reportError is true then the loading error is displayed.
        hasLoadedMyPackage = loadPackage("full path or relative path of MyPackage.cls", /*silentLoaded*/ .false, /*silentNotLoaded*/ .false, /*reportError*/ .false)

        -- Load a native library
        hasLoadedMyLibrary = loadLibrary("full path or relative path of MyLibrary"
    end


Known problems under Windows
============================

- The colors are now handled with ANSI escape sequences.
  Prequisite: at least Windows 10.
  If the colors are no supported under Windows 10 then see
  https://ss64.com/nt/syntax-ansi.html
  to modify the registry (VirtualTerminalLevel).

- If you launch ooRexxShell from a .bat file, then you need to prepend cmd /c to have the
  doskey history working correctly.
      cmd /c ""my path to\rexx" "my path to\ooRexxShell""

- The doskey history is fragile. It's not rare to lose the history.
  That's why readline is off by default under Windows.
  Readline off ==> We lose doskey macros and autocompletion of file names.

- The default console code page is the OEMCP, which does not match the default ANSI code page (ACP).
  For example:
      437 OEM United States
      850 OEM Multilingual Latin 1; Western European (DOS).
  That brings troubles when you execute a script created with a Window application (like Notepad)
  which contains letters with accent.
  Change the default code page of the console to ACP.
  For example, european users could enter this command:
    chcp 1252
  which changes the default code page of the console to 1252 ANSI Latin 1; Western European (Windows).
  You must also change the font of the console, because a raster font can't display letters with accent.
  Try Lucida Console, for example.
  See:
  http://archives.miloush.net/michkap/archive/2005/02/08/369197.html
  http://en.wikipedia.org/wiki/Windows-1252

- Assuming you defined this doskey macro: ll=ls -lap $*
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
        Code= 41.1
  [Note: these problems do not occur under Linux with Bash because the aliases are expanded
  only when the command is evaluated by Bash.]


Known problems under all platforms
==================================

- Ctrl-C kills ooRexxShell, despite a call on halt.
  RexxTry is much more robust in this regard.

- In mode raw command, the quotes and the escape characters are sometimes not well supported.

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
2024 may 30

Add support for a portable configuration.
When ooRexxShell is executed using a portable version of ooRexx then
- the .ini file is stored in the portable directory.
- the customization files are searched first in the portable directory, then
  in the user's home directory. It's possible to define customization files in
  both locations.

Note: for the moment, the history file is not stored in the portable directory
because it breaks the history when using rlwrap.


-----------------------------------------------
2024 may 20

Pretty print the BSF objects.
The Java arrays are displayed like the ooRexx arrays (condensed or not).


-----------------------------------------------
2024 may 19

The variable RC is no longer reset on each line interpretation.
Reason: The JDOR command handler may return Java objects with which one can
interact, if needed.

The initialization of JDOR is more robust: ooRexxShell no longer breaks in case
of error.


-----------------------------------------------
2024 may 18

Preload the JDOR component of Rony.
JDOR is not an interpreter like, say, Hostemu.
So there is no entry for JDOR in the interpreters list.
Instead, JDOR is activated with: address jdor.
That allows to mix JDOR commands with ooRexx expressions.

Settings: trapNoValue is now false by default.
That's better for using JDOR (no need to surround the commands by quotes).

Prompt: Fix the display of the 'address' part.
Now the display is ooRexx[JDOR] instead of ooRexx[cmd] after issuing the command
'address jdor'.

Prompt: No longer display [ooRexx] when the interpreter is different from ooRexx.
Reason: there is no address handler when the interpreter is not ooRexx.


-----------------------------------------------
2024 may 7

Modify the output of ?settings to display the full attribute expression and to
indicate if the attribute can be customized. You should not customize the
attrbutes listed [info].
Example:
?s
a Directory (45 items)
'[custom] .color~background'                            : ''
'[custom] .ooRexxShell~debug'                           :  0
'[custom] .ooRexxShell~defaultSleepDelay'               :  2
...
'[info]   .ooRexxShell~RC'                              :  0
'[info]   .ooRexxShell~commandInterpreter'              : 'sh'
'[info]   .ooRexxShell~customizationFile'               : '/Users/username/.oorexxshell_customization.rex'
...


Better implementation of quoted and unquoted (support of double quotes).


-----------------------------------------------
2024 may 4

New commands to debug the color display:
- color codes off   don't display the color codes
- color codes on    display the color codes

Add support for styles by name:
bold, dim, italic, underline, blinking, inverse, hidden, strikethrough.

Replace ~defaultColor by ~resetColor which resets not only the color but also
the styles.

Let combine several style names with a color name when defining an ooRexxShell color.
Example:
    .ooRexxShell~errorColor = "underline blinking bred"


-----------------------------------------------
2024 may 1

Customization by end user:
The extension is now .rex, instead of .cls.
Rework the error management. In case of error other than file not found, the
error message is displayed even in silent mode.


Customization by end user:
The optional file ".oorexxshell_customization.rex" is now loaded before any
preloaded package. Typically used for color settings.
A second optional file ".oorexxshell_customization2.rex" is loaded after all
preloaded packages.


Colors
"purple" renamed "magenta"
Add support for a background color.
A color can be specified by name, or directly by an ANSI Escape Sequence.


-----------------------------------------------
2024 apr 28

No longer show the unsupported queries when using the "?" command.


Color management:
No longer support .color~defaultBackground and .color~defaultForeground.
These attributes were used under Windows with GCI.
GCI has been replaced by ANSI color sequences.


When loading rgf_util2.rexx, try in this order:
- with relative path "rgf_util2/rgf_util2.rex" (executor version)
- without relative path "rgf_util2.rex" (bsf4oorexx version)


[Update 2024 May 1] the file extension is ".rex" instead of ".cls".
Allow customization by end user:
Load the optional file ".oorexxshell_customization.rex", from the HOME directory.
[Update 2024 May 1] This file is loaded first, before any preloaded package.


Better support of clauses ending with "=" or "==", when using ooRexx 5.
The Clauser used by Executor is delivered with ooRexxShell and loaded if found.
Now, several clauses are supported.
Example:
    say "1+1="; 1+1=; say; 1,2,3=; say; result==
Output (compact when the package "ppString.cls" has been loaded):
    1+1=
     2

    [ 1, 2, 3]

    an Array (3 items)
     1 :  1
     2 :  2
     3 :  3


-----------------------------------------------
2024 apr 23

Under Windows, GCI no longer needed for the colors.
From Gil: with Windows 10/11, ANSI color sequences are supported so it should be
possible to use the same "colorizing" as is used on non-Windows.


-----------------------------------------------
2023 sep 01

New command "test regression":
- activate the mode "demo fast"
- set .ooRexxShell~testRegression to .true
Example:
    cat script.rex | oorexxshell test regression

New property .ooRexxShell~testRegression set to .false by default. It can be set
to true when running [non-]regression tests, to deactivate the outputs that
could be different at each execution.
When .ooRexxShell~testRegression is .true then the command "infos next" is
deactivated (because it displays the duration and the count of active
coactivities).
A script can have conditional sections based on this property.


The commands '<' and 'goto' support an optional 'when condition'.
First need: use some demos for non-regression.
Some parts of the demos must be deactivated because their results change at each
execution (duration, concurrent trace).

Example for Executor:
    goto label          -- always executed
    goto label when 1   -- always executed
    goto label when 0   -- never executed
    < file s/x/10/ s/y/20/ when \.ooRexxShell~testRegression

Example for official ooRexx:
(must use 'return' or set the variable 'result')
    goto label                  -- always executed
    goto label when return 1    -- always executed
    goto label when result=1    -- always executed
    goto label when return 0    -- never executed
    goto label when result=0    -- never executed


-----------------------------------------------
2023 feb 05

The file ~/.oorexxshell_history is now updated only when ooRexxShell is in
interactive mode.


New option --showStackFrames
By default, when ooRexxShell traps an error, only a short description of the
error is displayed. The user can display more informations using one of these
queries: ?bt ?tb ?sf.
Using this option, a stack frame will be display for each trapped error.
First need:
Analyzing unexpected errors during a demo or during non regression tests.


-----------------------------------------------
2022 dec 09

The public classes and routines of the packages that are pre-loaded by ooRexxShell
are no longer automatically made available to the scripts called by ooRexxShell.
This default behavior has been changed to let detect missing dependencies when
doing non-regression tests.

New option --declareAll
When using the option --declareAll, the scripts called by ooRexxShell can be
executed without adding any ::requires directive for the pre-loaded packages.

Add a detection of circular ::requires
Will be removed when/if I retrofit this functionality from ooRexx5.


-----------------------------------------------
2022 nov 30

Rework the syntax of the command "prompt":
old: prompt directory off|on
new: prompt off|on [a[ddress]] [d[irectoy]] [i[nterpret]]

The need is to not display the address when doing non-regression tests.
That way, the referenve output will be similar for all platforms.

Examples:

prompt off
>

prompt on address directory
/local/rexx
[sh]>

prompt off address directory on interpreter
ooRexx>


-----------------------------------------------
2022 nov 28

The command "< filename" allows to declare text substitutions which are applied
to each line of the included file.

    < filename s/text1/newText1/ s/text2/newText2/ ...

The separator / can be replaced by any character, as long as the same separator
is used in a substitution rule.
The substitutions are applied from left to right using caselessReplace:
- all the occurences of text1 are replaced by newText1
- then all the occurences of text2 are replaced by newText2
- and so on
Just plain text matching, no metacharacter (. * ^$), no regular expression.

Typical usage : emulate macro arguments

    < "my file" s/$(1)/55/ s|il dit|He says|

These substitutions applied to
    say "Il dit ""I am $(1) years old"""
give
    say "He says ""I am 55 years old"""


-----------------------------------------------
2022 nov 17

New command "< filename" to include the file's lines in the input queue.
The file is searched using the method ~findProgram:
- searched in the same directory as the program invoking this command,
- searched in the current system directory
- searched in any REXX_PATH or PATH directory.
If filename is without extension then .rex is tried.

New commands "indent+" and "indent-" to indent the output in ooRexxShell.
Used by the command "< filename" to show the level of inclusion.

Modification of the prompt:
- no line break before the prompt.
- display systemAddress() instead of address()

Use a specific color for the command line (visible in demo only).


-----------------------------------------------
2022 jul 09

Make oorexxshell.rex a self contained script
by reducing the dependency on other packages:
- no longer requires "stringChunks.cls".
  A basic 'subwords' is used if this package can't be loaded.
- raw display of the collections if rgf_util2 can't be loaded.
  no sort, no alignment.
and by reducing the need to set environment variables:
- change the current directory AFTER loading the optional components,
  to increase the chance to load these components even if the PATH is not set.
  Typical test case : you execute
       ./rexx <path to>/oorexxshell.rex
   from the directory containing the rexx executable

Depending on the optional packages that can be loaded, more or less
functionalities are supported. The script should remain operational
even if no package at all can be loaded.

Tested by opening a fresh new console, going into the folder containing the rexx
executable, and launching
    ./rexx <path to>/oorexxshell.rex
This test is done without setting PATH or any other environment variable.
The script is successfully executed, with several packages not loaded because
they are not in this folder.
The readline is failing because the rxqueue executable is not found after changing
the current folder to the last folder used by oorexxshell.

    loadPackage KO for extension/stringChunk.cls
    loadPackage KO for extension/std/extensions-std.cls
    loadLibrary OK for rxunixsys
    loadPackage OK for ncurses.cls
    loadPackage OK for csvStream.cls
    loadLibrary OK for hostemu
    loadPackage OK for json.cls
    loadPackage OK for mime.cls
    loadPackage OK for rxftp.cls
    loadLibrary OK for rxmath
    loadPackage OK for rxregexp.cls
    loadPackage KO for regex/regex.cls
    loadPackage OK for smtp.cls
    loadPackage OK for socket.cls
    loadPackage OK for streamsocket.cls
    loadPackage KO for pipeline/pipe.cls
    loadPackage KO for rgf_util2/rgf_util2.rex
    loadPackage KO for BSF.CLS
    /bin/bash: rxqueue: command not found
       509 *-*       "echo $BASH_VERSION | rxqueue "quoted(.ooRexxShell~queueName)" /lifo"
           >>>         "echo $BASH_VERSION | rxqueue "S15a2Q7fcce8501390" /lifo"
           +++         "RC(127)"
    [readline] ooRexx bug detected, fallback to raw input (no more history, no more globbing)

Despite the KO and the failed readline, the script is operational.
Of course, the normal situation is to have the PATH correctly set.


-----------------------------------------------
2021 oct 15
?cmi now display the superclass from which a method is inherited.

?cmi string
P. P.G.    '?'                    : 'String' 'LogicalExtension' (logical.cls)
P. P.G.    'ABBREV'               : 'String' 'String' (REXX)
P. P.G.    'ABBREV2'              : 'String' 'String' (rgf_util2_wrappers.rex)
P. P.G.    'ABS'                  : 'String' 'String' (REXX)
P. PCG.    'ALNUM'                : 'String' 'StringCompatibilityWithOORexx5' (string.cls)
P. PCG.    'ALPHA'                : 'String' 'StringCompatibilityWithOORexx5' (string.cls)
P. P.G.    'APPEND'               : 'String' 'String' (REXX)
P. P...    'ARITY'                : 'String' 'Doer' (doers.cls)


-----------------------------------------------
2021 aug 07

When a value is a supplier, it's possible to see it as a table when ending the
line with "==".
No data is consumed because the display is made using a copy of the supplier.
There is no sort, the order is the supplier's order.
To get a sorted output, you can convert the supplier to a table (the datas of the supplier are consumed).
In case of supplier for a coactivity, you must explicitely convert it to a table
because even a copy will consume the datas of the coactivity.
.object~methods=                        -- display "(a Supplier)"
.object~methods==                       -- display the indexes/items as an unsorted table (no data consumed)
.object~methods~table==                 -- display the indexes/items as a sorted table (the datas are consumed)
1~generate.upto(10)~supplier==          -- display "(a CoactivitySupplierForGeneration)"
1~generate.upto(10)~supplier~table==    -- display the indexes/items as a table (the datas are consumed)


-----------------------------------------------
2021 may 30

rlwrap is the default input mode, if available,
when ooRexxShell is interactive.

(MacOs & Linux)


-----------------------------------------------
2021 may 13

New command "demo fast" to disable the sleep commands.

Typical usage:
Execute a demo at full speed when recording the output in a text file.
cat executor-demo-text.txt | oorexxshell demo fast > out.txt 2>&1


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

Known problem with rlwrap:
After leaving oorexxShell, the terminal is in bracketed paste mode
https://stackoverflow.com/questions/42212099/how-do-i-disable-the-weird-characters-from-bracketed-paste-mode-on-the-mac-os
When you paste SOMETHING, you have 00~SOMETHING~01.
Running then command printf '\e[?2004l' in the terminal clears the bracketed paste mode.

Known problem with rlwrap:
Sometimes, the code 200 returned by ooRexxShell when using the command 'reload'
is lost by rlwrap which returns 0. Consequence: ooRexxShell is not reloaded.

Demo mode:
If the command "*/" is immediatly followed by a command sleep then the duration is
proportional to the number of characters in the comment (before, was proportional
to the number of lines).


-----------------------------------------------
2020 dec 14

Add support for PowerShell core (pwsh).
    ooRexx[bash]> pwsh
    pwsh>

    Since pwsh is not (yet) supported natively as an address environment by ooRexx,
    the execution is delegated to the system interpreter:
    - cmd /c pwsh -command <raw command>
    - sh -c pwsh -command '<raw command>'

    As for the other shells, pwsh is a one-liner interpreter in ooRexxShell:
    pwsh> $i=1; echo $i                     # display 1
    If you split the previous command in 2 lines, it doesn't work:
    pwsh> $i=1
    pwsh> echo $i                           # display nothing because the variable i has no value

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
[2022 Nov 17] and we lose the support of UTF-8 when using chcp 65001: the characters >= 80x are replaced by 00x.

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
