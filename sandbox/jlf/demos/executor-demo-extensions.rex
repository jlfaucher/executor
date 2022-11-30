prompt off directory
demo on

----------------------
-- Executor extensions
----------------------

/*
The directive ::EXTENSION delegates to the methods .class~define and .class~inherit.
The changes are allowed on predefined classes, and are propagated to existing instances.

>>-::EXTENSION--classname----+-------------------+-----------------><
                             +-INHERIT--iclasses-+

Examples of extensions:

::extension Array       inherit ArrayInitializer ArrayPrettyPrinter

::extension Object
::method isNil
    return self == .nil
*/
sleep 10 no prompt

-- Query listing all the methods added by extension on the class String
?cmi string <> (rexx)
sleep no prompt

/*
Blocks
A RexxBlock is a piece of source code surrounded by curly brackets.
{say "Hello"}

Optional tags after "{":
::routine       (abbreviation ::r, this is the default tag)
::coactivity    (abbreviation ::co)

Big picture :
A RexxSourceLiteral is an internal rexx object, created by the parser, not accessible from ooRexx scripts.
A RexxSourceLiteral holds the following properties, shared among all the RexxBlock instances created from it :
- source: the text between the curly brackets {...} as an array of lines, including the tag ::xxx if any.
- package: the package which contain the source literal.
- kind: kind of source, derived from the source's tag.
- rawExecutable: routine or method created at load-time (immediate parsing).
- executable: cached executable.
A RexxBlock is created each time the RexxSourceLiteral is evaluated, and is accessible from ooRexx scripts.
When a RexxBlock is a closure's source, it will hold a snapshot of the context's variables.
*/
sleep 10
?cm RexxBlock
sleep
block = {say "Hello"}
sleep
block~rawExecutable=
sleep
block~executable=               -- not yet executed, the cache is empty
sleep
block~do
sleep
block~executable=               -- now the cache has a value: a Routine
sleep no prompt

/*
Tilde-call message "~()".
The message name can be omitted, but the list of parameters is mandatory (can be empty).
    target~()
    target~(arg1, arg2, ...)
    target~~()
    target~~(arg1, arg2, ...)
When the expression is evaluated, the target receives the message "~()" which
forwards the message "do".
*/
sleep
{say "hello"}~()
sleep
?m do                           -- classes supporting the message "do"
sleep no prompt

/*
Trailing block argument (similar to Groovy & Swift syntax for closures) :
    f{...} is equivalent to f({...})
    f(a1,a2,...){...} is equivalent to f(a1,a2,...,{...})
*/
sleep
10~times{2 * arg(1)}=
sleep no prompt

/*
Named arguments
They have been added because they allow to get rid of the transformation of the
block's sources at run-time (to declare positional arguments like item, index).
More precisely, this instruction:
    use auto named args
lets the caller inject named variables in the scope of the callee.
*/
sleep
{use auto named arg; say n1 n2 n3; .context~namedArgs}~(n1:1, n2:2, n3:3)=

-- An auto named argument never overwrites a variable already assigned
-- Here, n1 is not overwritten with 1
{n1=10; use auto named arg; say n1 n2 n3; .context~namedArgs}~(n1:1, n2:2, n3:3)=
sleep no prompt

/*
At parse-time, the source is transformed to accept auto named arguments, and to
return implicitely the result of the last evaluated expression.
*/
sleep
block = {say "Hello"}
sleep
block~source=
sleep
block~rawExecutable~source==
sleep no prompt

/*
By convention, the higher-order functions are passing the named parameters
"item" and "index". Their values are also passed as positional arguments.
The callee has the choice: using the auto named arguments, or using the positional
arguments. The callee has a total control over which arguments he accepts.
If its constraints on positional and/or named arguments are incompatible with
the expectations of the higher-order function then an error will be raised.
*/
sleep

10~times{use strict arg v; 2 * v}=  -- Not compatible, an error is raised
sleep
10~times{use arg v; 2 * v}=         -- Compatible
sleep
10~times{2 * item}=                 -- No need to declare "item"
sleep no prompt

/*
The arity is -1 (unknown) for all the doers, except for the blocks for which
the arity is 9999 (unlimited).
The arity is used by the higher-order functions, to decide which parameters
can be passed. For the operators, only 2 positional parameters must be passed.

For example, the implementation of ~reduce:
do while self~available
    if arity >=3 then doer~do(      accu,       self~item,        self~index,-
                              accu: accu, item: self~item, index: self~index)
                 else doer~do(      accu,       self~item,-
                              accu: accu, item: self~item)
    if var("result") then accu = result
    self~next
end
*/
sleep 10
(10,20,30)~reduce("+")=                                 -- case arity < 3
sleep
(10,20,30)~reduce(initial:0){accu + item ** index}=     -- case arity >= 3
sleep no prompt

/*
Closure
A closure is an object, created from a block whose source first word after the
optional tag is "expose".

A closure remembers the values of the variables defined in the outer environment
of the block. The behaviour of the closure is a method generated from the block,
which is attached to the closure under the name "do". The values of the captured
variables are accessible from this method "do" using expose. Updating a variable
from the closure will have no impact on the original context (hence the name
"closure by value").
*/
sleep 10
newCounter={use arg n=0; {expose n; use arg i=0; n+=i; n}}
sleep
counter1 = newCounter~()        -- start at 0 (default)
sleep
counter2 = newCounter~(20)      -- start at 20
sleep
counter1~() counter2~()=        -- 0 20
sleep
do 5; counter1~(+1); counter2~(-2); end
sleep
counter1~() counter2~()=        -- 5 10
sleep no prompt

/*
Coactivity
Emulation of coroutine, named "coactivity" to follow the ooRexx vocabulary.
This is not a "real" coroutine implementation, because it's based on ooRexx
threads and synchronization. But at least you have all the functionalities of a
stackful asymmetric coroutine (resume + yield).

A stackful coroutine is a coroutine able to suspend its execution from within
nested calls. The variable .threadLocal is used to retrieve the coactivity
instance from any invocation and send it the message yield (this instance is at
the origin of the invocations stack, but is not passed as a parameter to the
invocations).
myCoactivity~start  <--------------+
    invocation                     |
        invocation                 |
            ...                    |
                invocation: .Coactivity~yield()

A coactivity remembers its internal state. It can be called several times, the
execution is resumed after the last executed ".yield[]" or "call yield".
*/
sleep 10
generator = {::coactivity i=0; do forever; call yield i; i+=1; end}
sleep
generator~()=
sleep
generator~makeArray(10)=
sleep
generator~()=
sleep no prompt

/*
Concurrency trace
The interpreter has been modified to add thread id, activation id, variable's dictionnary id,
lock counter and lock flag in the lines printed by trace.
Concurrency trace is displayed only when env variable RXTRACE_CONCURRENCY=ON

Informations that are displayed.
RexxActivity::traceOutput(RexxActivation *activation, ...
T1       SysCurrentThreadId(),
A2       (unsigned int)activation,
V1       (activation) ? activation->getVariableDictionary() : NULL      // settings.object_variables
1        (activation) ? activation->getReserveCount() : 0               // settings.object_variables->getReserveCount()
*        (activation && activation->isObjectScopeLocked()) ? '*' : ' ') // object_scope == SCOPE_RESERVED
*/
sleep 10
-- Raw output, not easy to read
system RXTRACE_CONCURRENCY=ON rexx concurrency_trace.rex
sleep 5
-- Human-readable output, generated by piping the output through tracer.rex
system RXTRACE_CONCURRENCY=ON rexx concurrency_trace.rex 2>&1 | rexx trace/tracer.rex
sleep 10 no prompt

/*
Symmetric implementation of operator
Official ooRexx doesn't allow to define symmetric overriding of operators.
You can define a user operator on .array which supports .array~of(1,2) + 10.
But you can't define a user operator which supports 10 + .array~of(1,2).

Executor has been extended to automatically try b~"op:right"(a) when a~"op"(b)
is about to raise an exception.
If an alternate implementation exists then call it otherwise raise the exception.
The two methods Object::messageSend have been modified to let pass an additional
parameter 'processUnknown' which is true by default (legacy behavior). When this
parameter is false, and no method is found for the message, then
Object::messageSend returns false to indicate that no implementation exists.
There is no processing of the unknown message.
This is an efficient way to test if an alternate implementation exists and call it.
When the alternate implementation returns nothing, then don't complain about that.
Behave as if the alternate implementation did not exist, and raise the exception
related to the left argument.
*/
sleep 10
1 + (10, 20)=                           -- array programming
sleep
"hello"~text~utf16 "John"~text~utf16=   -- encoded strings
sleep
2*(3-2i)=                               -- complex numbers
sleep
a = (1, 2); a~append(a); a=             -- self-referencing array, its depth is infinite
sleep
1 + a~depth=                            -- arithmetic with infinity
sleep
5 * (a~depth - a~depth)=                -- arithmetic with indeterminate
sleep no prompt

/*
Global variable
When a variable has no value, the interpreter sends the message "NOVALUE" to
the object registered in .LOCAL under the name "NOVALUE" (un-documented feature,
see RexxActivation::novalueHandler).
The class GlobalVariables is used to manage global variables like i, infinity, indeterminate.
*/
sleep
.local~novalue=
sleep
?cm globalvariables
sleep
.globalvariables~values=
sleep no prompt

-- -----------------------------------------------------------
--
-- Some examples of functionalities which depend on extensions
--
-- -----------------------------------------------------------

sleep no prompt

/*
Range iterator
*/
sleep
1~9=
sleep no prompt

/*
The collection is displayed one item per line when the line ends with ==
*/
sleep
1~9==
sleep no prompt

/*
The precision of the range iterator is automatically adjusted
*/
sleep
1~9(by:1e-100, for:10)==
sleep no prompt

/*
To get the last 10 values of the range, pass for:-10
*/
sleep
1~9(by:1e-100, for:-10)==
sleep no prompt

/*
Y combinator:
The Y combinator allows recursion to be defined as a set of rewrite rules.
It takes a single argument, which is a function that isn't recursive (here, no argument, use self which is a Doer).
It returns a version of the function which is recursive.
*/
sleep no prompt

/*
Inspired by http://mvanier.livejournal.com/2897.html
Y = λf.(λx.f (λv.((x x) v))) (λx.f (λv.((x x) v)))

(define Y
  (lambda (f)
    ( (lambda (a) (a a))
      (lambda (x) (f (lambda (v) ((x x) v)))))))
*/
sleep no prompt

/*
Implementation of the Y combinator with memoization:
*/
sleep
?ms YM
sleep 10 no prompt

/*
Application to Fibonacci:
*/
sleep
almost_fib = { use arg fib; {expose fib ; use arg n; if n==0 then return 0; if n==1 then return 1; if n<0 then return fib~(n+2) - fib~(n+1); return fib~(n-2) + fib~(n-1)}}
sleep no prompt

/*
The not-memoizing version needs around 15 sec.
*/
sleep
fib_Y = almost_fib~Y
infos next
fib_Y~(23)=
sleep no prompt

/*
The memoizing version calculates almost instantly.
*/
sleep
fib_YM = almost_fib~YM
infos next
fib_YM~(23)=
sleep no prompt

/*
fib_Y and fib_YM are closures.
*/
sleep
fib_YM~executable=
sleep
fib_YM~executable~variables=
sleep
fib_YM~executable~variables["FIB"]~executable=
sleep
fib_YM~executable~variables["FIB"]~executable~variables=
sleep no prompt

/*
TABLE is the table of values memoized by fib_YM for the calculation of fib_YM~(23).
*/
sleep
fib_YM~executable~variables["FIB"]~executable~variables["TABLE"]=
sleep no prompt

/*
Both fib_Y and fib_YM are subject to stack overflow.
But fib_YM can be used by steps, to calculate very big fibonacci numbers, thanks to the memoization.
*/
sleep
numeric digits propagate 100
infos next
do i=1 to 500; r = fib_YM~(i*50); if i//50=0 then say "fib_YM~("i*50")="r; end
sleep no prompt

/*
End of demonstration.
*/
demo off
