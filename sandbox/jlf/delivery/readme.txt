ooRexx sandbox/jlf for experimental work.
http://oorexx.svn.sourceforge.net/viewvc/oorexx/sandbox/jlf/


=====================================================================================
ooRexxShell
=====================================================================================

Command history (up-down arrows), filename completion (tab).

Warning : ctrl-c not working as expected.

Load all the packages/libraries delivered in the snapshot.
bsf.cls and uno.cls are not part of the snapshot, but are loaded anyway, assuming you
have installed them. It's not a problem is bsf.cls or uno.cls fail to load, nothing in
ooRexxshell depends on them. You just won't have access to their functionalities.

This shell supports several interpreters :
- ooRexx itself
- the system address (cmd under Windows, bash under Linux)
- any other external environment (you need to modify this script, search for hostemu for an example).
The prompt indicates which interpreter is active.
By default the shell is in ooRexx mode.
When not in ooRexx mode, you enter raw commands that are passed directly to the external environment.
When in ooRexx mode, you have a shell identical to rexxtry.
You switch from an interpreter to an other one by entering its name alone.

Example (Windows) :
ooRexx[CMD] 'dir oorexx | find ".dll"'              you need to surround by quotes
ooRexx[CMD] cmd dir oorexx | find ".dll"            unless you temporarily select cmd
ooRexx[CMD] say 1+2                                 3
ooRexx[CMD] cmd                                     switch to the cmd interpreter
CMD> dir | find ".dll"                              raw command, no need of surrounding quotes
CMD> cd c:\program files
CMD> say 1+2                                        error, the ooRexx interpreter is not active here
CMD> oorexx say 1+2                                 you can temporarily select the ooRexx interpreter
CMD> oorexx                                         switch to the ooRexx interpreter
ooRexx[CMD] address myHandler                       selection of the "myHandler" subcommand handler (hypothetic, just an example)
ooRexx[MYHANDLER] 'myCommand myArg'                 an hypothetic command, must be surrounded by quotes because we are in ooRexx mode.
ooRexx[MYHANDLER] myhandler                         switch to the MYHANDLER interpreter
MYHANDLER> myCommand myArg                          an hypothetic command, no need of quotes
MYHANDLER> exit                                     the exit command is supported whatever the interpreter


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


If an ooRexx command line ends with "=" then the command line is transformed
to display the result :
'1+2=' becomes 'options "NOCOMMANDS";1+2;call dumpResult'
'=' alone displays the current value of the variable RESULT.


Command 'exit'.
To leave the ooRexxShell.


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
::extension String inherit StringDoer StringReducer StringMapper StringRepeater StringIterator
::extension MutableBuffer inherit MutableBufferReducer MutableBufferMapper MutableBufferIterator
::extension Routine inherit RoutineDoer
::extension Method inherit MethodDoer
::extension Coactivity inherit CoactivityDoer CoactivityReducer CoactivityIterator
::extension RexxBlock inherit RexxBlockDoer
::extension Collection inherit CollectionReducer CollectionMapper CollectionIterator
::extension Supplier inherit SupplierReducer SupplierIterator
::extension Array inherit ArrayInitializer


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

With implicit return, such an expression is quite common when filtering : value==1
    .array~of(1,2,1)~pipe(.select {value==1} | .console)
but the parser raises an error to protect the user against a potential typo error,
assuming the user wanted to enter : value=1.
I deactivated this control, now the expression above is ok.
Yes, it remains a problem (no syntax error, but it's an assignment, not a test) : 
    .array~of(1,2,1)~pipe(.select {value=1} | .console)
good point, the lack of returned value is detected, must surround by parentheses
to make it a real expression.
    .array~of(1,2,1)~pipe(.select {(value=1)} | .console)
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
Blocks (source literals) & doers
=====================================================================================

A RexxBlock is a piece of source code surrounded by curly brackets.


A Doer is an object who knows how to execute itself (understands "do")
This is an abstraction of routine, method, message, coactivity, closure.


A DoerFactory is an object who knows how to create a doer.
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


Big picture :
    a RexxSourceLiteral is an internal rexx object, created by the parser, not accessible from ooRexx scripts.
    a RexxSourceLiteral holds the following properties, shared among all the RexxBlock instances created from it :
      |  source : the text between the curly brackets {...} as an array of lines, including the tag :xxx if any.
      |  package : the package which contain the source literal.
      |  kind : kind of source, derived from the source's tag.
      |  rawExecutable : routine or method created at load-time (immediate parsing).
      |
      +--> a RexxBlock is created each time the RexxSourceLiteral is evaluated, and is accessible from ooRexx scripts.
      |    a RexxBlock contains informations that depends on the evaluation context.
      |    In particular, when a RexxBlock is a closure's source, it will hold a snapshot of the context's variables :
      |        ~source : source of the RexxSourceLiteral, never changed even if ~functionDoer or ~actionDoer called.
      |        ~variables : snapshot of the context's variables (a directory), created only if the source starts with "::cl".
      |        ~rawExecutable : the raw executable of the RexxSourceLiteral, created at load-time (routine or method).
      |        ~executable : cached executable, managed by doers.cls.
      |        ~executable= : routine or method or coactivity or closure. ~executable~source can be different from ~source. 
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


When used as a doer, a string is a message.
This abstraction is useful with the ~reduce method.
Ex :
say "length"~("John") -- 4 ("John"~"length")


Closure by value.
Minimal abbreviation is ::cl
Ex : See section closure.


Coactive closure
Minimal abbreviation is ::cl.c
Ex : See section closure.


=====================================================================================
Coactivity
=====================================================================================

Emulation of coroutine, named "coactivity" to follow the ooRexx vocabulary.
This is not a "real" coroutine implementation, because it's based on ooRexx threads and synchronization.
But at least you have all the functionalities of a stackful asymmetric coroutine (resume + yield).

block = {::coactivity
         say "hello" arg(1) || arg(2)
         arg = .yield[]
         say "good bye" arg[1] || arg[2]
        }
block~("John", ", how are you ?") -- hello John, how are you ?
block~("Kathie", ", see you soon.") -- good bye Kathie, see you soon.
block~("Keith") -- <nothing done, the coactivity is ended>


block = {::method.coactive
         say self 'says "hello' arg(1) || arg(2)'"'
         arg = .yield[]
         say self 'says "good bye' arg[1] || arg[2]'"'
        }
doer = block~doer("The boss")
doer~("John", ", how are you ?") -- The boss says "hello John, how are you ?"
doer~("Kathie", ", see you soon.") -- The boss says "good bye Kathie, see you soon."
doer~("Keith") -- <nothing done, the coactivity is ended>


=====================================================================================
Closures by value.
=====================================================================================

Closure by value means : Updating a variable from the closure will have no impact on the
original context.
Note : If the variable contains a mutable value then updating the mutable value from the
closure will have an impact on the original context (if still active).


A closure is an object whose exposed variables are created from a directory of variables.
This directory of variables can be passed explicitely, or taken from a RexxBlock.
The behavior of the closure is a user-defined method which expose the needed variables.
This method is added to the closure, with the name "do". Ex :
    v = 1 ; closure = .Closure~new(.context~variables){::m expose v ; say v} ; closure~do -- display 1
    v = 1 ; closure = .Closure~new{::m expose v ; say v} ; closure~do -- display 1
Both lines are equivalent, but in the second example, the directory of variables is taken
from the RexxBlock, created when evaluating the source literal.


Tags :
    ::cl[osure]
    ::cl[osure].c[oactive]

The example above can be rewritten :
    v = 1 ; {::closure expose v ; say v}~doer~do -- display 1


Closure :
    range = { use arg min, max ; return { ::closure expose min max ; use arg num ; return min <= num & num <= max }}
    from5to8 = range~(5, 8)
    from20to30 = range~(20, 30)
    say from5to8~(6) -- 1
    say from5to8~(9) -- 0       
    say from20to30~(6) -- 0
    say from20to30~(25) -- 1


Coactive closure :
    v = 1
    w = 2
    closure = {::cl.c expose v w ; .yield[v] ; .yield[w]}~doer
    say closure~do -- 1
    say closure~do -- 2


The context of a closure can be a method :
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
        return {::cl expose self a1 local ; say self~class ; say a1 ; say local}
    ::requires "extension/extensions.cls"
Output :
    The RexxBlock class
    ::cl expose self a1 local ; say self~class ; say a1 ; say local
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
        return {::cl
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
    sub10 = "-"~partial(, 10)
    say sub10~(1) -- -9

Ex :
    myArguments = .context~package~findRoutine("myArguments")
    p1 = myArguments~partial(1,,3,,5)
    p1~()                               1:1 3:3 5:5
    p1~(2,,6)                           1:1 2:2 3:3 5:5 6:6
    p1~(2,4,6,,8)                       1:1 2:2 3:3 4:4 5:5 6:6 8:8
    p2 = myArguments~partial(,,3,4)
    p2~()                               3:3 4:4
    p2~(2,,6)                           1:2 3:3 4:4 5:6
    p2~(2,4,6,,8)                       1:2 2:4 3:3 4:4 5:6 7:8
    ::routine myArguments
        arg(1, "a")~each{call charout, index":"value" "}
        say
    ::requires "extension/extensions.cls"


=====================================================================================
Higher-order functions
=====================================================================================

                reduce   reduceC   reduceW   map   mapC   mapW   mapR   mapCR   mapWR   each    eachC    eachW
                                                                                        eachI   eachCI   eachWI
.String         ............X.........X..............X......X......................................X........X...
.MutableBuffer  ............X.........X..............X......X.............X.......X................X........X...
.Array          ...X..........................X....................X......................X.....................
.Bag            ...X..........................X....................X......................X.....................
.CircularQueue  ...X..........................X....................X......................X.....................
.Directory      ...X..........................X....................X......................X.....................
.List           ...X..........................X....................X......................X.....................
.Properties     ...X..........................X....................X......................X.....................
.Queue          ...X..........................X....................X......................X.....................
.Relation       ...X..........................X....................X......................X.....................
.Set            ...X..........................X....................X......................X.....................
.Stem           ...X..........................X....................X......................X.....................
.Table          ...X..........................X....................X......................X.....................
.IdentityTable  ...X..........................X....................X......................X.....................
.Supplier       ...X......................................................................X.....................
.Coactivity     ...X......................................................................X.....................


-- Reduce
-- http://en.wikipedia.org/wiki/Fold_(higher-order_function)
123~reduceC("+") -- initial value is the first char (default), reduce by char, returns 6
123~reduceC(100, "+") -- initial value is 100, reduce by char, returns 106
-- BEWARE ! the ~reduce method is available on all the collections, but only ordered collections can be reduced using non-commutative operations.
-- Ex : "+" can be used on any collection, but "-" should be used only on ordered collections.
.array~of(10, 20, 30)~reduce("+") -- initial value is the first item (default), returns 60
{::c .yield[10]; .yield[20]; .yield[30]}~doer~reduce("+") -- initial value is the first item (default), returns 60


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
.set~of(1,2,3)~supplier~each{2*value}
"abcdef"~eachC{value}
{::c do i=1 to 3; .yield[i]; end}~doer~each{2*value}


-- Repeat self times the given action (self is a number).
-- An array of results is returned (can be empty).
3~times{say arg(1)} -- returns an empty array because no result returned during the iteration
3~times{1} -- returns .array~of(1,1,1)
3~times{arg(1)} -- returns .array~of(1,2,3)


-- Lazy repeater : returns a coactivity.
-- Repeat self times the given action (self is a number).
-- When the action returns a result during the loop, this result is yielded.
-- The next result will be calculated only when requested.
c = 1000000~times.yield
say c~resume -- 1
say c~resume -- 2
...


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


The chain of connected pipeStages is a pipe.
Any object can be a source of pipe :
- When the object does not support the method ~supplier then it's injected as-is.
  The index is 1.
- A collection can be a source of pipe : each item of the collection is injected in the pipe.
  The indexes are those of the collection.
- A coactivty can be a source of pipe : each yielded value is injected in the pipe (lazily).
  The indexes are those returned by the coactivity supplier.


Most sub classes need only override the process() method to implement a pipeStage.  
The transformed results are passed down the pipeStage chain by calling the write method.


Careful to >> 
    "hello"~pipe(.left[2] >> .upper | .console)
Here, the result is not what you expect. You want "LLO", you get "he"...
This is because .console is the primary follower of .left, not the primary
follower of .upper.
Why ? because the pipestage returned by .left[2] >> .upper is .left,
and .console is attached to the pipestage found by starting from .left
and walking through the 'next' references until a pipestage with no 'next'
is found. So .upper is not walked though, because it's a secondary follower.


You need additional parentheses to get the expected behavior.
Here, .console is the primary follower of .upper.
    "hello"~pipe(.left[2] >> ( .upper | .console ) )


Note : by default, the connection is always made with follower's I1.
See .secondaryConnector to learn how to connect to follower's I2.


-- Any object can be a source of pipe.
-- When the object does not support the method ~supplier then it's injected as-is.
-- Its associated index is always 1.
"hello"~pipe(.console)


-- A collection can be a source of pipe : each item of the collection is injected in the pipe.
-- The indexes are those of the collection.
.array~of(10,20,30)~pipe(.console)


-- A coactivty can be a source of pipe : each yielded value is injected in the pipe (lazy).
-- Example :
-- This coactivity yields two results.
-- The hello outputs are not in the pipeline flow (not displayed by the .console).
{::c echo hello ; .yield["a"] ; say hello ; .yield["b"] }~doer~pipe(.console)


-- A collection can be sorted by value (default)
.array~of(b, a, c)~pipe(.sort byValue | .console)


-- ...or by index
.array~of(b, a, c)~pipe(.sort byIndex | .console)


-- ...ascending (default)
-- The order of options is important : a byValue option is impacted only by the preceding options
-- This is because several byValue options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort ascending byValue | .console)


-- ...descending
.array~of(b, a, c)~pipe(.sort descending byValue | .console)


-- ...by index descending
-- The order of options is important : a byIndex option is impacted only by the preceding options.
-- This is because several byIndex options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort descending byIndex | .console)


-- Do something for each item (no returned value, so no value passed to .console).
.array~of(1, , 2, , 3)~pipe(.do {say 'value='value 'index='index} | .console)


-- Do something for each item (the returned result replaces the item's value).
-- Note : the index created by .do is a pair (value, resultIndex) where
--     value is the processed value.
--     resultIndex is the index of the current result calculated with value.
-- Here, only one result is calculated for a value, so resultIndex is always 1.
.array~of(1, , 2, , 3)~pipe(.do {return 2*value} mem | .console)


-- Each injected value can be used as input to inject a new value, recursively.
-- The default order is depth-first.
-- If the recursion is infinite, must specify a limit (here 0, 1 and 2).
-- The options 'before' and 'after' are not used, so the initial value is discarded.
-- Use the default index.
.array~of(1, , 2, , 3)~pipe(.inject {value*10} recursive.0 | .console)
.array~of(1, , 2, , 3)~pipe(.inject {value*20} recursive.1 | .console)
.array~of(1, , 2, , 3)~pipe(.inject {value*30} recursive.2 | .console)


-- Methods (not inherited) of all the classes whose id starts with "R".
.environment~pipe(,
    .select {value~isA(.class)} |,
    .select {value~id~caselessAbbrev('R') <> 0} |,
    .inject {value~methods(value)} after memorize |,
    .sort byIndex |,
    .console,
    )


-- Display the 4 first sorted items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.sort | .take 4 | .console)


-- Sort the 4 first items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.take 4 | .sort | .console)


-- Drop the first value
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop | .console)


-- Drop the first value of each partition
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop {value} | .console)


-- Drop the last value
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop last | .console)


-- Drop the last value of each partition
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop last {value} | .console)

