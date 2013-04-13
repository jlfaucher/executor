ooRexx sandbox/jlf for experimental work.
http://oorexx.svn.sourceforge.net/viewvc/oorexx/sandbox/jlf/

Note :
This file is encoded in UTF-8, because it contains strings in Greek, Russian,
Hebrew and Japanese in the ooRexxTry.rex section.


=====================================================================================
ooRexxShell (all platforms)
=====================================================================================

Command history (up-down arrows), filename completion (tab).

Warning : ctrl-c not working as expected.

Load all the packages/libraries delivered in the snapshot.
uno.cls is not part of the snapshot, but is loaded anyway, assuming you have installed it.
It's not a problem if uno.cls fails to load, nothing in ooRexxshell depends on it.
You just won't have access to its functionalities.

This shell supports several interpreters :
- ooRexx itself
- the system address (cmd under Windows, bash under Linux)
- hostemu
- any other external environment (you need to modify this script, search for hostemu for an example).
The prompt indicates which interpreter is active.
By default the shell is in ooRexx mode.
When not in ooRexx mode, you enter raw commands that are passed directly to the external environment.
When in ooRexx mode, you have a shell identical to rexxtry.
You switch from an interpreter to an other one by entering its name alone.

Example (Windows) :
ooRexx[CMD]> 'dir bin | find ".dll"'                   you need to surround by quotes
ooRexx[CMD]> cmd dir bin | find ".dll"                 unless you temporarily select cmd
ooRexx[CMD]> say 1+2                                   3
ooRexx[CMD]> cmd                                       switch to the cmd interpreter
CMD> dir bin | find ".dll"                             raw command, no need of surrounding quotes
CMD> say 1+2                                           error, the ooRexx interpreter is not active here
CMD> oorexx say 1+2                                    you can temporarily select the ooRexx interpreter
CMD> hostemu                                           switch to the hostemu interpreter
HostEmu> execio * diskr "install.txt" (finis stem in.  store the contents of the file "install.txt" in the stem in.
HostEmu> oorexx in.=                                   temporarily switch to ooRexx to display the stem
HostEmu> exit                                          the exit command is supported whatever the interpreter


Command 'reload'.
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


If an ooRexx clause ends with "=" then the clause is transformed to display the result :
'1+2=' becomes 'options "NOCOMMANDS"; 1+2 ; call dumpResult; options "COMMANDS"'
'=' alone displays the current value of the variable RESULT.


You have access to Java from ooRexxShell.
Ex :
    props = .bsf4rexx~System.class~getProperties
    enum=props~propertyNames
    do while enum~hasMoreElements; key=enum~nextElement; value = props~getProperty(key); say enquote2(key) "=" enquote2(value); end
Under MacOSX, if you want to use awt or swing classes then you must launch ooRexxShell like that :
    rexxj2.sh $OOREXX_HOME/packages/oorexxshell.rex
otherwise you will have a java.awt.HeadlessException raised. 
Example of code which depends on awt :
    call bsf.importClass "java.awt.Toolkit"
    toolkit = .java.awt.Toolkit~getDefaultToolkit
    dimension = toolkit~getScreenSize
    dimension~width=
    dimension~height=


Command 'exit'.
To leave the ooRexxShell.


=====================================================================================
ooRexxTry.rex (Windows only)
=====================================================================================

Adaptation of ooRexxTry.rex delivered with ooRexx.
Load all the packages/libraries delivered in the snapshot.
If an ooRexx clause ends with "=" then the clause is transformed to display the result.

Unlike ooRexxShell, ooRexxTry lets enter multiline code.
Example taken from GetJavaSystemProperties.rxj in the BSF4ooRexx distribution :
Get the Java System Properties from java.lang.System using the services set up by BSF.CLS.
    properties=.bsf4rexx ~System.class ~getProperties  -- get the System properties
    enum=properties~propertyNames    -- get an enumeration of the property names
    do while enum~hasMoreElements    -- loop over enumeration
        key=enum~nextElement          -- get next element
        value = properties~getProperty(key)
        say enquote2(key) "=" enquote2(value)
    end

A wide-char version of ooDialog is delivered in the snapshot.
Warning : this wide-char version is derived from an older version of ooDialog (april 2010)
and is no longer in sync with ooDialog 4.2.0 (the byte-char version).
Internally, the strings are UTF-16. At the boundary of ooDialog, the strings coming from /
going to the interpreter are converted from / to the code page specified by the routine
setCodePage. ooRexxTry is configured to use UTF-8 (call setCodePage 65001).
You can use the wide-char version by starting the command line with wchar (the path is
temporarily updated to put the wide-char files in front of the path).
Ex :
wchar rexx ooRexxTry

You can copy-paste the following lines (UTF-8 encoding) to the Code area of ooRexxTry,
and see the difference between byte-char and wide-char versions of ooDialog (you can run
both at the same time, just use two different consoles).
---------------
say "# Greek (monotonic): ξεσκεπάζω την ψυχοφθόρα βδελυγμία"
say "# Russian: Съешь же ещё этих мягких французских булок да выпей чаю."
say "# Hebrew: זה כיף סתם לשמוע איך תנצח קרפד עץ טוב בגן."
say "# Japanese (Hiragana): あさきゆめみじ　ゑひもせず"
say "あさきゆめみじ　ゑひもせず"~mapC{return arg(1)~c2x" "}
-- utf8 not (yet) supported by the String class:
-- returns 9 bytes, not 9 characters, and this is displayed as 3 graphemes
return "あさきゆめみじ　ゑひもせず"~left(9) -- E3 81 82 E3 81 95 E3 81 8D
---------------

If the text is not displayed properly, then select the font "Arial Unicode MS" in
Settings/FontName (if available).

Some notes about Unicode and m17n :
http://oorexx.svn.sourceforge.net/viewvc/oorexx/sandbox/jlf/unicode/_readme.odt?view=log


=====================================================================================
ooRexxTry.rxj (all platforms)
=====================================================================================

Under MacOSX : rexxj2.sh $OOREXX_HOME/packages/ooRexxTry.rxj
Other platforms : rexx ooRexxTry.rxj

Adaptation of ooRexxTry.rxj (http://sourceforge.net/projects/bsf4oorexx) :
Load all the packages/libraries delivered in the snapshot.
If an ooRexx clause ends with "=" then the command line is transformed to display the result.

In this snapshot, java is configured to use UTF-8 as default encoding for external strings,
using this declaration in bsf4oorexx/install/setEnvironment4BSF.cmd :
    set BSF4Rexx_JavaStartupOptions=-Dsun.jnu.encoding=UTF-8 -Dfile.encoding=UTF-8

You can copy-paste the Greek/Russian/Hebrew/Japanese lines from the ooRexxTry.rex section
and see what happens. If the text is not displayed properly, then select the font
"Arial Unicode MS" in Settings/FontName (if available).


=====================================================================================
Extension of predefined classes.
=====================================================================================

Citation :
The addition of closures to the Java language in JDK 7 (JLF : now scheduled for JDK 8)
place additional stress on the aging Collection interfaces; one of the most significant
benefits of closures is that it enables the development of more powerful libraries.
It would be disappointing to add a language feature that enables better libraries while
at the same time not extending the core libraries to take advantage of that feature. 
http://cr.openjdk.java.net/~briangoetz/lambda/Defender%20Methods%20v3.pdf


Same need for ooRexx... Hence the ::extension directive

>>-::EXTENSION--classname----+-------------------+-----------------><
                             +-INHERIT--iclasses-+


Extensions in current delivery :
::extension Routine                         inherit RoutineDoer
::extension Method                          inherit MethodDoer
::extension RexxBlock                       inherit RexxBlockDoer
::extension Coactivity                      inherit CoactivityDoer CoactivityFilter                      CoactivityIterator                      CoactivityReducer    CoactivityGenerator
::extension String                          inherit StringDoer     StringFilter                          StringIterator                          StringReducer        StringGenerator        StringMapper        StringHelpers RepeaterCollector RepeaterGenerator 
::extension MutableBuffer                   inherit                MutableBufferFilter                   MutableBufferIterator                   MutableBufferReducer MutableBufferGenerator MutableBufferMapper StringHelpers
::extension Collection                      inherit                CollectionFilter                      CollectionIterator                      CollectionReducer    CollectionGenerator    CollectionMapper
::extension OrderedCollection               inherit                OrderedCollectionFilter
::extension Supplier                        inherit                SupplierFilter                        SupplierIterator                        SupplierReducer      SupplierGenerator
::extension CoactivitySupplierForGeneration inherit                CoactivitySupplierForGenerationFilter CoactivitySupplierForGenerationIterator
::extension Array                           inherit ArrayInitializer ArrayPrettyPrinter
::extension File                            inherit FileExtension


Implementation notes :

This directive delegates to the methods .class~define and .class~inherit.
The changes are allowed on predefined classes, and are propagated to existing instances.

If the same method appears several times in a given::extension directive, this is an error (because it's like that with ::class).
It's possible to extend a class several times in a same package.
It's possible to extend a class in different packages.
If the same method appears in several ::extension directives, there is no error : the most recent replaces the older (because 'define' works like that).

When the extensions of a package are installed, the extension methods and the inherit declarations of each ::extension are processed in the order of declaration.
Each package is installed separately, this is the standard behaviour. 
The visibility rules for classes are also standard, nothing special for extensions. Each package has its own visibility on classes.


=====================================================================================
Concurrency trace
=====================================================================================

The interpreter has been modified to add thread id, activation id, variable's dictionnary id,
lock counter and lock flag in the lines printed by trace.
Concurrency trace is displayed only when env variable RXTRACE_CONCURRENCY=ON

Informations that are displayed.
RexxActivity::traceOutput(RexxActivation *activation, ...
T1       SysCurrentThreadId(),
A2       (unsigned int)activation,
V1       (activation) ? activation->getVariableDictionary() : NULL,         // settings.object_variables
1        (activation) ? activation->getReserveCount() : 0,                  // settings.object_variables->getReserveCount()
*        (activation && activation->isObjectScopeLocked()) ? '*' : ' ');    // object_scope == SCOPE_RESERVED

Raw trace, generated by rexx :
00004fec 7efc0fb0 7efc10f0 00001*     79 *-* if start 
00004fec 7efc0fb0 7efc10f0 00001*        >V>   START => "1"
00004fec 7efc0fb0 7efc10f0 00001*        >>>   "1"
00004fec 7efc0fb0 7efc10f0 00001*     79 *-*   then
00004fec 7efc0fb0 7efc10f0 00001*     79 *-*     self~start
00004fec 7efc0fb0 7efc10f0 00001*        >V>       SELF => "a Coactivity"
00004fec 7efc9918 7efc10f0 00002*        >I> Method START with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
...
00004fec 7efc9918 7efc10f0 00002*     93 *-* reply self
00004fec 7efc9918 7efc10f0 00002*        >V>   SELF => "a Coactivity"
00004fec 7efc9918 7efc10f0 00002*        >>>   "a Coactivity"
00004fec 7efc0fb0 7efc10f0 00001*        >>>       "a Coactivity"
00004fec 7eee9be8 00000000 00000         >M>   "NEW" => "a Coactivity"
0000478c 7efc9918 7efc10f0 00001*        >I> Method START with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
00004fec 7eee9be8 00000000 00000         >>>   "a Coactivity"
0000478c 7efc9918 7efc10f0 00001*     94 *-* .Activity~local~empty

The thread id and activation id are pointers written in hexadecimal, which is not very easy to read.
The script trace/tracer.rex lets :
- replace hexadecimal values by more human-readable values like T1, A1.
- generate a CSV file, for further analysis with your favorite tool.
Can be used as a pipe filter (reads from stdin) :
    rexx my_traced_script.rex 2>&1 | rexx trace/tracer
or can read from a file :
    rexx trace/tracer -csv my_trace_file.txt

Human readable trace, generated by rexx trace/tracer using raw trace as input :
T1   A4     V2      1*     79 *-* if start 
T1   A4     V2      1*        >V>   START => "1"
T1   A4     V2      1*        >>>   "1"
T1   A4     V2      1*     79 *-*   then
T1   A4     V2      1*     79 *-*     self~start
T1   A4     V2      1*        >V>       SELF => "a Coactivity"
T1   A5     V2      2*        >I> Method START with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
...
T1   A5     V2      2*     93 *-* reply self
T1   A5     V2      2*        >V>   SELF => "a Coactivity"
T1   A5     V2      2*        >>>   "a Coactivity"
T1   A4     V2      1*        >>>       "a Coactivity"
T1   A3                       >M>   "NEW" => "a Coactivity"
T2   A5     V2      1*        >I> Method START with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A3                       >>>   "a Coactivity"
T2   A5     V2      1*     94 *-* .Activity~local~empty


=====================================================================================
Performance : new option NOMACROSPACE
=====================================================================================

Each call to an external function (like SysXxx functions) triggers a communication 
with the rxapi server through a socket (QUERY_MACRO, to test is the function is
defined in the macrospace).
This has a major impact on performance !
Example with .yield[] which calls SysGetTid() or SysQueryProcess("TID") at each call :
    10000 calls to .yield[] with macrospace enabled  : 2.1312
    10000 calls to .yield[] with macrospace disabled : 0.4531
(JLF 2012 mar 23 : .yield[] no longer depends on SysXXX functions, now depends on 
.threadLocal --> faster)
(samples/benchmark/doers-benchmark-output.txt)
The following options control the use of macrospace :
    ::options MACROSPACE
    ::options NOMACROSPACE
    options "MACROSPACE"
    options "NOMACROSPACE"
By default, the macrospace is queried, according to the rules described in rexxref
section "7.2.1 Search order".
When using the option NOMACROSPACE, the macrospace is not queried.


=====================================================================================
Evaluation of expression : new option NOCOMMANDS
=====================================================================================

Added an option to control execution of commands :
    ::options COMMANDS
    ::options NOCOMMANDS
    options "COMMANDS"
    options "NOCOMMANDS"
By default, a clause consisting of an expression only is interpreted as a command string.
When using the option NOCOMMANDS, the value of the expression is stored in the
variable RESULT, and not interpreted as a command string.


=====================================================================================
Parser : Refinement of tokens 'subclass' attribute
=====================================================================================

The scanner splits a source file in clauses, and decompose each clause in tokens.
Then the parser creates an AST from the tokens. 
The tokens were not annotated by the parser to attach semantic information found
during parsing. After a discussion with Rony about syntax coloring, I decided to
see which informations could be added to the tokens. I found that the attribute
'subclass' of the tokens could hold informations like that :
IS_KEYWORD
IS_SUBKEY
IS_DIRECTIVE
IS_SUBDIRECTIVE
IS_CONDITION
IS_BUILTIN

For the moment, there is no access to the clauses/tokens from an ooRexx script.
If the environment variable RXTRACE_PARSING=ON then the clauses and tokens are
dumped to the debug output (Windows) or the log (Unix) using dbgprintf.
Works only with a debug version of ooRexx.


=====================================================================================
Parser : arg(...)
=====================================================================================

For good or bad reason, arg(1) at the begining of a clause is recognized as an
instruction, because arg is a keyword instruction.
I often use source literals like {arg(1)...} where I want arg(1) to be interpreted
as a function call. So I decided to change the behavior of the parser to interpret
as a function call any symbol followed immediatly by a left paren, even if the
symbol is a keyword instruction.


=====================================================================================
Parser : = ==
=====================================================================================

With implicit return, such an expression is quite common when filtering : item==1
    .array~of(1,2,1)~pipe(.select {item==1} | .console)
but the parser raises an error to protect the user against a potential typo error,
assuming the user wanted to enter : item=1.
I deactivated this control, now the expression above is ok.

Yes, it remains a problem (no syntax error, but it's an assignment, not a test) : 
    .array~of(1,2,1)~pipe(.select {item=1} | .console)
good point, the lack of returned value is detected, must surround by parentheses
to make it a real expression.
    .array~of(1,2,1)~pipe(.select {(item=1)} | .console)
(an Array),1 : 1
(an Array),3 : 1


=====================================================================================
Parser : Message term
=====================================================================================

Tilde-call message "~()".
The message name can be omitted, but the list of parameters is mandatory (can be empty).
    target~()
    target~(arg1, arg2, ...)
    target~~()
    target~~(arg1, arg2, ...)
When the expression is evaluated, the target receives the message "~()".


>>-receiver-+- ~ --+----+---------+----(--+----------------+--)--><
            +- ~~ -+    +-:symbol-+       | +-,----------+ |
                                          | V            | |
                                          +---expression-+-+


=====================================================================================
Doers
=====================================================================================

A Doer is an object which knows how to execute itself (understands "do")
This is an abstraction of routine, method, message, coactivity, closure.

When used as a doer, a string is a message.
This abstraction is useful with the higher-order methods.
Ex :
say "length"~("John") -- 4 ("John"~"length")
say "length of each word"~mapW("length") -- A string "6 2 4 4"
say "length of each word"~eachW("length") -- An array [6,2,4,4]

Each doer has its own "do" method, and knows what to do with the arguments.
routine : forward message "call"
method : use strict arg object, ... ; forward to (object) message "run" array (self, "a", arg(2,"a"))
message : use strict arg object, ... ; forward to (object) message ("sendWith") array (self, arg(2,"a"))
coactivity : forward message ("resume")
closure : user-defined method
block : forward to (self~doer)

A DoerFactory is an object which knows how to create a doer.
A doer can be created from :
- a RexxBlock :
  Can be costly since the interpreter must parse the source and create an AST.
  But you do it only once... After, you get an executable in your hands, which you can use
  as a target for the 'do' message.
- an executable (Routine or Method) :
  No cost, this is for convenience, the doer is the executable itself.
- a wrapper of executable (Coactivity, Closure) :
  No cost, this is for convenience, the doer is the wrapper itself.
Most of the time, you don't need to create explicitely a doer, this is done automatically.
Exception : the doer of a coactive method must be created explicitely, because the self
object must be passed as argument.


=====================================================================================
Blocks (source literals)
=====================================================================================

A RexxBlock is a piece of source code surrounded by curly brackets.


Big picture :
    a RexxSourceLiteral is an internal rexx object, created by the parser, not accessible from ooRexx scripts.
    a RexxSourceLiteral holds the following properties, shared among all the RexxBlock instances created from it :
      |  source : the text between the curly brackets {...} as an array of lines, including the tag ::xxx if any.
      |  package : the package which contain the source literal.
      |  kind : kind of source, derived from the source's tag.
      |  rawExecutable : routine or method created at load-time (immediate parsing).
      |
      +--> a RexxBlock is created each time the RexxSourceLiteral is evaluated, and is accessible from ooRexx scripts.
      |    a RexxBlock contains informations that depends on the evaluation context.
      |    In particular, when a RexxBlock is a closure's source, it will hold a snapshot of the context's variables :
      |        ~source : source of the RexxSourceLiteral, never changed even if ~functionDoer or ~actionDoer called.
      |        ~variables : snapshot of the context's variables (a directory), created only if the source starts with "::closure".
      |        ~rawExecutable : the raw executable of the RexxSourceLiteral, created at load-time (routine or method).
      |        ~executable : cached executable, managed by doers.cls. ~executable~source can be different from ~source.
      |
      +--> a RexxBlock
      |
      +--> etc... (a new instance is created at each evaluation of the RexxSourceLiteral)


By default (no tag) the executable is a routine.
Ex :
{use strict arg name, greetings; say "hello" name || greetings}~("John", ", how are you ?") -- hello John, how are you ?


::method is a tag to indicate that the executable must be a method.
The first argument passed with ~do is the object, available in self.
The rest of the ~do's arguments are passed to the method as arg(1), arg(2), ...
Minimal abbreviation is ::m
Ex :
{::method use strict arg greetings; say "hello" self || greetings}~doer~do("John", ", how are you ?") -- hello John, how are you ?


::coactivity is a tag to indicate that the doer must be a coactivity (whose executable is a routine by default).
Minimal abbreviation is ::c
Ex : See section coactivity.


::routine.coactive (coactive routine) is equivalent to ::coactivity.
Minimal abbreviation is ::r.c
Ex : See section coactivity.


::method.coactive is a tag to indicate that the doer must be a coactivity whose executable is a method.
The object on which the method is run is passed using the ~doer method.
Minimal abbreviation is ::m.c
Ex : See section coactivity.


::closure (closure by value)
Minimal abbreviation is ::cl
Ex : See section closure.


::closure.coactive (coactive closure)
Minimal abbreviation is ::cl.c
Ex : See section closure.


=====================================================================================
Coactivity
=====================================================================================

Emulation of coroutine, named "coactivity" to follow the ooRexx vocabulary.
This is not a "real" coroutine implementation, because it's based on ooRexx threads and synchronization.
But at least you have all the functionalities of a stackful asymmetric coroutine (resume + yield).

A stackful coroutine is a coroutine able to suspend its execution from within nested calls.
That's why .threadLocal is needed. 
The goal is to retrieve the coactivity instance from any invocation and send it the message yield
(this instance is at the origin of the invocations stack, but is not passed as a parameter to the invocations).
myCoactivity~start  <--------------+
    invocation                     |
        invocation                 |
            ...                    |
                invocation : .Coactivity~yield()

A coactivity remembers its internal state. It can be called several times, the execution is resumed after
the last executed .yield[].

Producer/consumer problems can often be implemented elegantly with coactivities.
The consumer can pass arguments : producerResult = aCoactivity~resume(args...)
.yield[result] lets the producer (aCoactivity) return an optional result to the consumer.
Coactivities also provide an easy way to inverse recursive algorithms into iterative ones.

A coactivity supports the method ~supplier, so it can be seen as a collection. 
Unlike a collection's supplier which builds a snapshot of the collection, a coactivity's supplier does not
create a snapshot of the values generated by the coactivity. It's a lazy supplier, which resumes the
coactivity only when needed (i.e. when aSupplier~next is called).
When no result returned by the coactivity then the supplier returns item=.nil and index=.nil.


block = {::coactivity
         say "hello" arg(1) || arg(2)
         .yield[]
         say "good bye" arg(1) || arg(2)
        }
block~("John", ", how are you ?") -- hello John, how are you ?
block~("Kathie", ", see you soon.") -- good bye Kathie, see you soon.
block~("Keith", ", bye") -- <nothing done, the coactivity is ended>


block = {::method.coactive
         say self 'says "hello' arg(1) || arg(2)'"'
         .yield[]
         say self 'says "good bye' arg(1) || arg(2)'"'
        }
doer = block~doer("The boss")
doer~("John", ", how are you ?") -- The boss says "hello John, how are you ?"
doer~("Kathie", ", see you soon.") -- The boss says "good bye Kathie, see you soon."
doer~("Keith", ", bye") -- <nothing done, the coactivity is ended>


/*
Coactivities are implemented using threads.
So we have the problem of thread termination...

Automatic termination of gc'ed coactivities :
When a coactivity is garbage-collected, then its uninit method is called, which ends the coactivity.
You can see by yourself the automatic ending of coactivities.
In the following example, a non-terminating coactivity is created at each iteration and we take one value.
Since no variable keeps a reference to the coactivity, it will be gc'ed and automatically ended.
*/
do 100
    {::coactivity do forever ; .yield[1] ; end}~take(1)~()
    say .Coactivity~count -- number of started-not-(ended-killed) coactivities
end
/*
The automatic termination works only if the coactivity can be gc'ed.
We can have coactivities still running when reaching the end of a script, not candidate to GC.
To ensure that a script will terminate, then
    .Coactivity~endAll
must be called at the end of the script.
*/


=====================================================================================
Closures by value.
=====================================================================================

A closure is an object, created from a block with one of these tags
    ::closure
    ::closure.coactive

A closure remembers the values of the variables defined in the outer environment of the block.
The behaviour of the closure is a method generated from the block, which is attached to
the closure under the name "do". The values of the captured variables are accessible from
this method "do" using expose. Updating a variable from the closure will have no impact on
the original context (hence the name "closure by value").
A closure can be passed as argument, or returned as result.


Examples :
    v = 1                                -- captured, belongs to the outer environment of the following blocks
    {::closure expose v ; say v}~doer~do -- display 1
    {::closure expose v ; say v}~do      -- display 1 (implicit call to ~doer)
    {::closure expose v ; say v}~()      -- display 1 (alternative notation, more functional)


    range = { use arg min, max ; return { ::closure expose min max ; use arg num ; return min <= num & num <= max }}
    from5to8 = range~(5, 8)
    from20to30 = range~(20, 30)
    say from5to8~(6) -- 1
    say from5to8~(9) -- 0       
    say from20to30~(6) -- 0
    say from20to30~(25) -- 1

    /*
    The first block can be rewritten as a routine, no more nested blocks, but the code is less compact,
    and the order less natural (you discover the definition of the routine after the place from where it's called).
    The inner block is an object (RexxBlock) returned by the routine.
    */
    from5to8 = range(5, 8) -- function call, here no tilde
    say from5to8~(6) -- from5to8 is a RexxBlock to which the message "~()" is sent
    ::routine range
    use arg min, max
    return { ::closure expose min max ; use arg num ; return min <= num & num <= max }


A coactive closure is both a closure and a coactivity :
- as a closure, it remembers its outer environment.
- as a coactivity, it remembers its internal state. 
It can be called several times, the execution is resumed after the last .yield[]

Examples :
    v = 1
    w = 2
    closure = {::closure.coactive expose v w ; .yield[v] ; .yield[w]}~doer
    say closure~do -- 1
    say closure~do -- 2


The context of a closure can be a method. In this case, the outer environment contains
the variables exposed by the method, as well as the SELF and SUPER variables. If the
closure needs access to the SELF variable, it must expose it, as any other variable.
    myInstance = .myClass~new("myAttributeValue")
    myContextualSource = myInstance~myMethod
    say myContextualSource~class
    say myContextualSource~source~toString
    do v over myContextualSource~variables
        say v
    end
    doer = myContextualSource~doer
    say doer~class
    doer~do
    ::class myClass
    ::method init
        expose a1
        use strict arg a1
    ::method myMethod
        expose a1
        local = "myLocal"
        return {::closure expose self a1 local ; say self~class ; say a1 ; say local}
    ::requires "extension/extensions.cls"
Output :
    The RexxBlock class
    ::closure expose self a1 local ; say self~class ; say a1 ; say local
    SELF
    LOCAL
    A1
    SUPER
    The Closure class
    The MYCLASS class
    myAttributeValue
    myLocal


=====================================================================================
Trampoline
=====================================================================================

http://en.wikipedia.org/wiki/Tail_call#Through_trampolining
A trampoline is a technique to transform recursive calls into a sequence of calls
to doers. Instead of returning the result, the doer returns a doer which returns
the result. While the result returned by the doer is a doer, the result is called.
The loop is ended when the result is not a doer.

Ex :
    say {say "one" ; return {say "two" ; return "three"}}~trampoline -- one two three

Ex :
    factorial = {
        use strict arg n, accu=1
        if n <= 1 then return accu
        executable = .context~executable
        return {::closure
            expose n accu executable
            return executable~(n-1, n*accu)
        }
    }
    say factorial~trampoline(1000000) -- 8.26394406E+5565708


=====================================================================================
Partial arguments
=====================================================================================

http://en.wikipedia.org/wiki/Partial_application
Returns a closure which remembers the arguments passed to ~partial.
When this closure is called with the remaining arguments, a whole argument array is
built from both argument lists (partial and remaining) and passed to the target of
~partial.

Ex :
    add10 = "+"~partial(10)
    say add10~(1) -- 11

Ex :
    /*
    The ~partial method takes care of the omitted arguments.
    In this example, "-"~partial(, 10), a partial array is created, which keeps the first arg omitted :
    +---+----+
    |   | 10 |
    +---+----+
    When you do sub10~(1) then 1 goes into the first free cell :
    +---+----+
    | 1 | 10 |
    +---+----+
    */

    sub10 = "-"~partial(, 10)
    say sub10~(1) -- -9
    
    /*
    That's the same principle with more omitted arguments :
    - any omitted argument when calling ~partial will create an empty cell.
    - any omitted argument when calling a partial closure (returned by ~partial) will remain an omitted argument :
      the first free cell remains empty and the next empty cell becomes the first free cell.
    - a non empty cell is always skipped.
    */
        block = {do a over arg(1, "a") ; .output~charout(a" ") ; end; say}
        partial1 = block~partial( , , 3, , , 6, , , 9)
        -- +---+---+---+---+---+---+---+---+---+
        -- |   |   | 3 |   |   | 6 |   |   | 9 |
        -- +---+---+---+---+---+---+---+---+---+
        partial1~() -- 3 6 9
        partial2 = partial1~partial( , 2, , 5, , 8, , 11)
        -- +---+---+---+---+---+---+---+---+---+----+----+
        -- |   | 2 | 3 |   | 5 | 6 |   | 8 | 9 |    | 11 |
        -- +---+---+---+---+---+---+---+---+---+----+----+
        partial2~() -- 2 3 5 6 8 9 11
        partial2~(1, 4, 7, 10, 12) -- 1 2 3 4 5 6 7 8 9 10 11 12
        -- +---+---+---+---+---+---+---+---+---+----+----+----+
        -- | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
        -- +---+---+---+---+---+---+---+---+---+----+----+----+

Ex :
    myArguments = .context~package~findRoutine("myArguments")
    p1 = myArguments~partial(1,,3,,5)
    p1~()                               -- 1:1 3:3 5:5
    p1~(2,,6)                           -- 1:1 2:2 3:3 5:5 6:6
    p1~(2,4,6,,8)                       -- 1:1 2:2 3:3 4:4 5:5 6:6 8:8
    p2 = myArguments~partial(,,3,4)
    p2~()                               -- 3:3 4:4
    p2~(2,,6)                           -- 1:2 3:3 4:4 5:6
    p2~(2,4,6,,8)                       -- 1:2 2:4 3:3 4:4 5:6 7:8
    ::routine myArguments
        arg(1, "a")~each{call charout, index":"item" "}
        say
    ::requires "extension/extensions.cls"


=====================================================================================
Higher-order methods
=====================================================================================

-- Reduce
-- http://en.wikipedia.org/wiki/Fold_(higher-order_function)
123~reduceC("+") -- initial value is the first char (default), reduce by char, returns 6
123~reduceC(100, "+") -- initial value is 100, reduce by char, returns 106
-- BEWARE ! the ~reduce method is available on all the collections, but only ordered collections can be reduced using non-commutative operations.
-- Ex : "+" can be used on any collection, but "-" should be used only on ordered collections.
.array~of(10, 20, 30)~reduce("+") -- initial value is the first item (default), returns 60
{::coactivity .yield[10]; .yield[20]; .yield[30]}~doer~reduce("+") -- initial value is the first item (default), returns 60


-- Map
-- http://en.wikipedia.org/wiki/Map_(higher-order_function)
-- The result returned by ~map method is of the same type as the self object.
-- A String or MutableBuffer can be filtered (when no result returned by the given action).
-- A Collection can't be filtered : If the given action doesn't return a result, then the current value is unchanged.
-- If you need to filter the values of a Collection, then use the ~each method.
"abcdefghijklmnopqrstuvwxyz"~mapC{arg(1)~verify('aeiouy')} -- returns "01110111011111011111011101"
"abcdefghijk"~mapC{arg(2)":"arg(1)" "} -- returns "1:a 2:b 3:c 4:d 5:e 6:f 7:g 8:h 9:i 10:j 11:k "
"one two three"~mapW{if arg(1)~length > 3 then arg(1)} -- returns "three"
.array~of(1,2,3)~map{2*arg(1)} -- returns .array~of(2,4,6)


-- Iterator, collector, filter.
-- Whatever the object being iterated over, the ~each method returns an array.
-- If you need a result object which is of the same type as the iterated object then use ~map.
.set~of(1,2,3)~supplier~each{2*item}
"abcdef"~eachC{item}
{::coactivity do i=1 to 3; .yield[i]; end}~doer~iterator~each{2*item}


-- Filter on any sequence
reject(predicate)
select(predicate)

-- Filter on ordered sequences
drop(count=1)
dropLast(count=1)
dropUntil(predicate)
dropWhile(predicate)
take(count=1)
takeLast(count=1)
until(predicate)
while(predicate)

-- Repeat self times the given action (self is a number).
-- An array of results is returned (can be empty).
3~times{say arg(1)} -- returns an empty array because no result returned during the iteration
3~times{1} -- returns .array~of(1,1,1)
3~times{arg(1)} -- returns .array~of(1,2,3)
3~times -- returns .array~of(1,2,3) because the default action is {arg(1)}


=====================================================================================
Generators
=====================================================================================

Generators are methods which return a coactivity.
So generators can produce a sequence of results instead of a single value...
But this is not mandatory. The main goal of generators is to decompose an iterative
execution into a sequence of steps, separated by .yield[]. A step does not necessarily
return a result. When a step is achieved, the next one will be started only on demand.


When you pass an action to a generator, your action should not use .yield[] because the
sequencing is taken in charge by the generator itself. Your action can return an optional
result, which will be yielded by the generator.


When applied to a coactivity, the higher-order methods return a new coactivity instead
of an array or items. The items are returned one by one.
Sometimes, you want to iterate over all the items produced by a coactivity. In this case,
use the method ~iterator which returns a supplier specialized for iteration, where all items
are consumed in one loop.
Example :
    {::coactivity do i=1 to 10; .yield[i]; end}~each{say item}= -- return a Coactivity, nothing displayed
    {::coactivity do i=1 to 10; .yield[i]; end}~iterator~each{say item}= -- display 1 2 3 4 5 6 7 8 9 10 and return an empty array


The .Generator class is a Coactivity which applies an action to a source (any object)
and yields the results one by one. 
    generator = .Generator~new(source)~option1~option2...
    r1 = generator~do
    r2 = generator~do
    ...
The following options can be specified :
~action(action) :
    The action to execute on each item. The default action is {arg(1)} where arg(1) is the item.
    An action of type message (string) is supported. For convenience, the message is sent only
    if the receiver understands it (i.e. ~hasMethod returns .true). In case of recursive execution,
    the recursion is automatically stopped if the current item does not understand the message.
    Ex : the method .File~listFiles returns .nil if the item is not a directory. Since .nil does
    not understand ~listFiles, the recursion is stopped.
    This method returns the generator (self), to let chaining other methods.
~allowCommands :
    To allow execution of system commands from a RexxBlock.
    By default, the message ~functionDoer is sent to the RexxBlock. The source is transformed to
    support implicit return, which implies the NOCOMMANDS option.
    When this option is specified, the message ~actionDoer is sent to the RexxBlock. There is no
    implicit return, and the NOCOMMANDS option is not injected in the source.
    This method returns the generator (self), to let chaining other methods.
~iterateBefore :
    If the current item has the method "supplier", then apply the doer on each item returned by the supplier.
    This method returns the generator (self), to let chaining other methods.
~iterateAfter :
    If the current result has the method "supplier", then yield each item returned by the supplier.
    In case of recursive execution, each item is used as input value for the next recursive call.
    This method returns the generator (self), to let chaining other methods.
~once : 
    To remember all the processed items from the start, and process an item only once.
    This option encompasses the option ~recursive("cycles") which is limited to the call stack.
    This method returns the generator (self), to let chaining other methods.
~recursive(options="") :
    To execute the action recursively on the returned values.
    The default algorithm is depthFirst.
    Options can be ([limit|depthFirst|breadthFirst|cycles][.])*
    Ex :
    ~recursive(0) : limit=0, execute the action on each item, no recursive call
    ~recursive(1) : limit=1, execute the action on each item and reexecute the action on each resulting item (1 level of recursion)
    ~recursive("depthFirst") : http://en.wikipedia.org/wiki/Depth-first_search
    ~recursive("breadthFirst") : http://en.wikipedia.org/wiki/Breadth-first_search
    ~recursive("cycles") : detect cycles, to not reprocess an item already processed in the call stack.
    ~recursive("10.breadthFirst.cycles") : combination of several options.
    This method returns the generator (self), to let chaining other methods.
~returnIndex :
    To yield .array~of(item, index).
    If the generation is recursive then yield .array~of(item, index, depth) where depth is the number of nested calls.
    This method returns the generator (self), to let chaining other methods.
~trace :
    To activate internal trace.
    This method returns the generator (self), to let chaining other methods.


Convenience methods :
    .Object~generate(action) : returns .Generator~new(self)~action(action)
    .Object~generateI(action) : returns .Generator~new(self)~action(action)~returnIndex
    .String~generateC(action) : returns .Generator~new(self~makeArray(""))~action(action)
    .String~generateCI(action) : returns .Generator~new(self~makeArray(""))~action(action)~returnIndex
    .String~generateW(action) : returns .Generator~new(self~subwords)~action(action)
    .String~generateWI(action) : returns .Generator~new(self~subwords)~action(action)~returnIndex
    .MutableBuffer~generateC(action) : returns .Generator~new(self~makeArray(""))~action(action)
    .MutableBuffer~generateCI(action) : returns .Generator~new(self~makeArray(""))~action(action)~returnIndex
    .MutableBuffer~generateW(action) : returns .Generator~new(self~subwords)~action(action)
    .MutableBuffer~generateWI(action) : returns .Generator~new(self~subwords)~action(action)~returnIndex
    .Collection~generate(action) : returns .Generator~new(self)~iterateBefore~action(action)
    .Collection~generateI(action) : returns .Generator~new(self)~iterateBefore~action(action)~returnIndex
    .Supplier~generate(action) : returns .Generator~new(self)~iterateBefore~action(action)
    .Supplier~generateI(action) : returns .Generator~new(self)~iterateBefore~action(action)~returnIndex
    .Coactivity~generate(action) : returns .Generator~new(self)~iterateBefore~action(action)
    .Coactivity~generateI(action) : returns .Generator~new(self)~iterateBefore~action(action)~returnIndex


Examples :
-- All items in .environment
    g=.environment~generate
    g~do= -- [The OLEObject class id#_268012703]
    g~do= -- [The InvertingComparator class id#_268059180]
    -- ...

-- All pairs of index,item in .environment
    g=.environment~generateI
    g~do= -- [(The OLEObject class),'OLEOBJECT']
    g~do= -- [(The InvertingComparator class),'INVERTINGCOMPARATOR']
    -- ...

-- Illustration of depthFirst (default) vs breadthFirst
   "one two three"~generateW{if depth == 0 then item; else if item <> "" then item~substr(2)}~recursive~makeArray=
        -- ['one','ne','e','','two','wo','o','','three','hree','ree','ee','e','']
   "one two three"~generateW{if depth == 0 then item; else if item <> "" then item~substr(2)}~recursive("breadthFirst")~makeArray=
        -- ['one','two','three','ne','wo','hree','e','o','ree','','','ee','e','']

-- Generation of all natural numbers : 1 2 3 ...
    g=0~generate{item+1}~recursive

-- Lazy repeater : returns a coactivity.
-- Repeat self times the given action (self is a number).
-- When the action returns a result during the loop, this result is yielded.
-- The next result will be calculated only when requested.
    c = 1000000~times.generate
    say c~resume -- 1
    say c~resume -- 2
    -- ...

-- Careful :
    1000000~times~generate{2*item} -- Collect all items in an array and then generate each array's item one by one (you don't get the first item immediatly)
    1000000~times.generate{2*item} -- Generate directly each item one by one (you get the first item immediatly)


=====================================================================================
Pipeline
=====================================================================================

By default, a pipeStage has two inputs I1 & I2, and two ouputs O1 & O2.
process : I1
processSecondary : I2
write : O1 (linked by default to follower's I1)
writeSecondary : 02 (linked by default to follower's I1)


Connectors
'|'  connect leftPipeStage's O1 with rightPipeStage's I1 (primary follower) : 01 --> I1
'>'  same as '|', but careful, the '>' operator has a higher precedence than '|'
'>>' connect leftPipeStage's O2 with rightPipeStage's I1 (secondary follower) : O2 --> I1


Note : by default, the connection is always made with follower's I1.
See .secondaryConnector to learn how to connect to follower's I2.


Careful to >> 
    "hello"~pipe(.left[2] >> .upper | .console)
Here, the result is not what you expect. You want "LLO", you get "he"...
This is because .console is the primary follower of .left, not the primary
follower of .upper.
You need additional parentheses to get the expected behavior.
Here, .console is the primary follower of .upper.
    "hello"~pipe(.left[2] >> ( .upper | .console ) )


The chain of connected pipeStages is a pipe.


A pipeStage receives a triplet (item, index, dataflow). It applies transformations or filters
on this triplet. When a pipeStage forwards an item to a following pipeStage, it forwards the
received dataflow unchanged, unless the option "memorize" has been used. In this case, a new
datapacket is added to the dataflow, which memorizes the produced item and index.

A datapacket is an array :
  array[1] : link to previous datapacket (received from previous pipeStage).
  array[2] : tag (generally the id of the pipeStage class, or "source" for the initial datapacket).
  array[3] : index of produced item.
  array[4] : produced item.

          1          2     3       4
        +----------+-----+-------+------+
        | previous | tag | index | item |
        +----------+-----+-------+------+
           ^
           |  +----------+-----+-------+------+
           +--| previous | tag | index | item |
              +----------+-----+-------+------+
                 ^
                 |
                 +-- etc...


-- Any object can be a source of pipe.
-- When the object does not support the method ~supplier then it's injected as-is.
-- Its associated index is always 1.
"hello"~pipe(.console)


-- A collection can be a source of pipe : each item of the collection is injected in the pipe.
-- The indexes are those of the collection.
.array~of(10,20,30)~pipe(.console)


-- A coactivty can be a source of pipe : each yielded value is injected in the pipe.
-- Example :
{::coactivity .yield["a"] ; .yield["b"] }~doer~pipe(.console)


-- A collection can be sorted by item (default)
.array~of(b, a, c)~pipe(.sort byItem | .console)


-- ...or by index
.array~of(b, a, c)~pipe(.sort byIndex | .console)


-- ...ascending (default)
-- The order of options is important : a byItem option is impacted only by the preceding options
-- This is because several byItem options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort ascending byItem | .console)


-- ...descending
.array~of(b, a, c)~pipe(.sort descending byItem | .console)


-- ...by index descending
-- The order of options is important : a byIndex option is impacted only by the preceding options.
-- This is because several byIndex options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort descending byIndex | .console)


-- Do something for each item (no returned value, so no value passed to .console).
.array~of(1, , 2, , 3)~pipe(.do {say 'item='item 'index='index} | .console)


-- Do something for each item (the returned result replaces the item's value).
-- Here, only one result is calculated for an item, so resultIndex is always 1.
.array~of(1, , 2, , 3)~pipe(.do {return 2*item} | .console)


-- Each injected value can be used as input to inject a new value, recursively.
-- The default order is depth-first.
-- If the recursion is infinite, must specify a limit (here 0, 1 and 2).
-- The options 'before' and 'after' are not used, so the initial item is discarded.
-- Use the default index.
.array~of(1, , 2, , 3)~pipe(.inject {item*10} recursive.0 | .console)
.array~of(1, , 2, , 3)~pipe(.inject {item*20} recursive.1 | .console)
.array~of(1, , 2, , 3)~pipe(.inject {item*30} recursive.2 | .console)


-- Display the 4 first sorted items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.sort | .take 4 | .console)


-- Sort the 4 first items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.take 4 | .sort | .console)


-- Drop the first item
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop | .console)


-- Drop the first item of each partition
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop {item} | .console)


-- Drop the last item
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop last | .console)


-- Drop the last item of each partition
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop last {item} | .console)


-- convenience method ~coactivePipe to let yield the values produced by the pipe, one by one :
g = .object~coactivePipe(.subClasses recursive once | .do {.yield[item]})
g~do=
g~do=
-- ...


-- The 50 first files and directories in the /tmp directory
"/tmp"~pipe(.fileTree recursive.memorize | .take 50 | .console dataflow)


-- Methods (not inherited) of all the classes whose id starts with "R".
.environment~pipe(,
    .select {item~isA(.class)} memorize.class |,
    .select {item~id~caselessAbbrev('R') <> 0} |,
    .inject {item~methods(item)} iterateAfter |,
    .sort {index} {dataflow["class"]~item~id} |,
    .console {dataflow["class"]~item~id} {index},
    )


-- Public classes by package
.context~package~pipe(,
    .importedPackages recursive once after memorize.package |,
    .inject {item~publicClasses} iterateAfter |,
    .sort {item~id} {dataflow["package"]~item~name} |,
    .console {.file~new(dataflow["package"]~item~name)~name} ":" item,
    )


/*
Generators, like pipe stages of a pipeline, can be combined to form a chain of loose-coupled "processors".
In a chain of pipe stages (a pipeline), the control flow is driven by the producers.
    p1 --write--> p2 --write--> p3 ...
In a chain of generators, the control flow is driven by the consumers.
    g1 <--resume-- g2 <--resume-- g3 ...
It's possible to mix both techniques, using a coactive pipeline.
A coactive pipeline is an ordinary pipeline running in the flow of control of a coactivity.
By yielding values, a coactive pipe can produce values which go "outside" the pipe.
*/
.environment~coactivePipe(.console)~()
.environment~coactivePipe(.do {.yield[item]} | .console)~()=
.environment~coactivePipe(.do {.yield[item]; return item} | .console)~()=
.environment~coactivePipe(.do {.yield[item]; return item} | .console)~take(2)~iterator~each=
.environment~coactivePipe(.console | .do {.yield[item]; return item})~take(2)~iterator~each=

co_pipe = .array~of(10,20)~coactivePipe(,
    .inject {10*item} |,
    .do {.yield[item] ; return item} |,  -- the item is yielded "outside" the pipe, and then returned to be forwarded to the next pipe stage
    .inject {10+item} |,
    .do {.yield[item] ; return item} |,
    .console)
-- the pipe has not yet started
say co_pipe~()    -- 100
say co_pipe~()    -- 110
say co_pipe~()    -- The pipe displays 1 : 110 and yields the next value : 200
say co_pipe~()    -- 210
co_pipe~resume    -- another resume is needed to let the pipe display 2 : 210


=====================================================================================
Summary of extension methods
=====================================================================================


                                 -|--------|-----------|-----------|------------|--------|-------|-------|--------------|-----------
                                  |     reduce         |        reduceC      reduceW     |       |       |              |           
                                 -|--------|-----------|-----------|------------|--------|-------|-------|--------------|-----------
                                 map       |           |        mapC         mapW        |       |       |              |              
                                 mapR      |           |           |            |      mapCR   mapWR     |              |           
                                 -|--------|-----------|-----------|------------|--------|-------|-------|--------------|-----------
                                  |     each           |        eachC        eachW       |       |       |              |           
                                  |     eachI          |        eachCI       eachWI      |       |       |              |           
                                 -|--------|-----------|-----------|------------|--------|-------|-------|--------------|-----------
                                  |     reject         |        rejectC      rejectW     |       |       |              |           
                                  |     rejectI        |        rejectCI     rejectWI    |       |       |              |           
                                  |     select         |        selectC      selectW     |       |       |              |           
                                  |     selectI        |        selectCI     selectWI    |       |       |              |           
                                 -|--------|-----------|-----------|------------|--------|-------|-------|--------------|-----------
                                  |        |        drop        dropC        dropW       |       |       |              |           
                                  |        |        dropI       dropCI       dropWI      |       |       |              |           
                                  |        |        dropLast    dropLastC    dropLastW   |       |       |              |           
                                  |        |        dropLastI   dropLastCI   dropLastWI  |       |       |              |           
                                  |        |        dropUntil   dropUntilC   dropUntilW  |       |       |              |           
                                  |        |        dropUntilI  dropUntilCI  dropUntilWI |       |       |              |           
                                  |        |        dropWhile   dropWhileC   dropWhileW  |       |       |              |           
                                  |        |        dropWhileI  dropWhileCI  dropWhileWI |       |       |              |           
                                  |        |        take        takeC        takeW       |       |       |              |           
                                  |        |        takeI       takeCI       takeWI      |       |       |              |           
                                  |        |        takeLast    takeLastC    takeLastW   |       |       |              |           
                                  |        |        takeLastI   takeLastCI   takeLastWI  |       |       |              |           
                                  |        |        until       untilC       untilW      |       |       |              |           
                                  |        |        untilI      untilCI      untilWI     |       |       |              |           
                                  |        |        while       whileC       whileW      |       |       |              |           
                                  |        |        whileI      whileCI      whileWI     |       |       |              |           
                                 -|--------|-----------|-----------|------------|--------|-------|-------|--------------|-----------
                                  |        |           |        generateC    generateW   |       |    generate          |           
                                 -|--------|-----------|-----------|------------|--------|-------|-------|--------------|-----------
                                  |        |           |           |            |        |       |    pipe              |           
                                  |        |           |           |            |        |       |    coactivePipe      |           
                                 -|--------|-----------|-----------|------------|--------|-------|-------|--------------|-----------
                                  |        |           |           |            |        |       |       |           times          
                                  |        |           |           |            |        |       |       |           times.generate 
                                  |        |           |           |            |        |       |       |           upto           
                                  |        |           |           |            |        |       |       |           generate.upto  
                                  |        |           |           |            |        |       |       |           downto         
                                  |        |           |           |            |        |       |       |           generate.downto
----------------------------------|--------|-----------|-----------|------------|--------|-------|-------|--------------|-----------
.Object .................................................................................................X..........................
.String ...........................................................X............X........................X..............X...........
.MutableBuffer ....................................................X............X........X.......X.......X..........................
.Collection.......................X........X.............................................................X..........................
.OrderedCollection................X........X...........X.................................................X..........................
.Supplier .................................X...........X.................................................X..........................
.Coactivity ...............................X...........X.................................................X..........................
.CoactivitySupplierForGeneration ..........X...........X.................................................X..........................
.CoactivitySupplierForIteration ...........X...........X.................................................X..........................
