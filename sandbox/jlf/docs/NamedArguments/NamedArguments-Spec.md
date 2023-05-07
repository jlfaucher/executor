<!-- 

Remember: when you create/update a syntax diagram, you must copy it in the file
NamedArguments-SD.xml

with constants.xml
    <scalar name="diagram_scale">0.1</scalar>
    <string name="diagram_unit">in</string>
and syntaxdiagram.css
        font-family: Times-New-Roman;
the png have these sizes:
    sd_Arguments                3462 × 980      3462/150=23.08%     *2=46.16
    sd_Context_setArgs          4766 × 514      4766/150=31.77%     *2=63.54
    sd_Function                 2461 × 301      2461/150=16.41%     *2=32.82
    sd_Instruction_CALL         3004 × 532      3004/150=20.03%     *2=40.06
    sd_Instruction_FORWARD      12234 × 774     12234/150=81.56%    *2=163.12
    sd_Instruction_USE          8620 × 1119     8620/150=57.47%     *2=114.94
    sd_Message_new              8309 × 927      8309/150=55.39%     *2=110.78
    sd_Message_term_brackets    2031 × 299      2031/150=13.54%     *2=27.08
    sd_Message_term             5629 × 512      5629/150=37.53%     *2=75.06
    sd_Named_arguments          2206 × 980      2206/150=14.71%     *2=29.42
    sd_Object_run               7127 × 927      7127/150=47.51%     *2=95.02
    sd_Object_sendWith          6411 × 514      6411/150=42.74%     *2=85.48
    sd_Object_startWith         6418 × 514      6418/150=42.79%     *2=85.58
    sd_Positional_arguments     1805 × 788      1805/150=12.03%     *2=24.06
    sd_Routine_callWith         4830 × 514      4830/150=32.2%      *2=64.4

Must multiply the width by 2 because the github rendering is too small compared
to a local rendering.
-->

Named arguments - Specification
===============================

A positional argument list is a serie of optional expressions, separated by commas.

    caller: put("one", 1)
    callee: use arg item, index -- order is important

The position of each argument within the argument list identifies the corresponding
parameter in the parameter list of the routine/method being invoked.

This is in contrast to named argument lists, where the correspondence between
argument and parameter is done using the parameter's name.

    caller: put(index:1, item:"one")
    callee: use named arg item, index -- order is not important

Caller side
-----------

Positional and named arguments can be used in the same call.  
Named arguments are after the last positional argument.

    caller: "one two three one"~reduce("put", by:"word", initial:.set~new)

The syntax for trailing block (when last positional argument) is still available:

    f(a1,a2,n1:v1,n2:v2){...}

is equivalent to

    f(a1,a2,{...},n1:v1,n2:v2)


Arguments:

    |----+----------------------------------------------------+----|
         +--| Positional arguments |--------------------------+
         +-------------------------------| Named arguments |--+
         +--| Positional arguments |--,--| Named arguments |--+

<img src="SyntaxDiagram/sd_Arguments.png" width="46.16%">


Positional arguments:

        +-,--------------+
        V                |
    |-----+------------+-+----|
          |            |
          +-expression-+

<img src="SyntaxDiagram/sd_Positional_arguments.png" width="24.06%">


Named arguments:

        +-,------------------+
        V                    |
    |-----+-name-:-expr----+-+----|
          |                |
          +-name-:---------+
          |                |
          +------:-varname-+

<img src="SyntaxDiagram/sd_Named_arguments.png" width="29.42%">



Shorthand syntax

    name:           -- without expr, pass .true
    :varname        -- without name, pass varname:varname


Called side
-----------

    use strict arg doer
    use strict named arg by, initial
    
The named arguments are declared separately from the positional arguments.


    use strict            arg doer                      -- Positional arguments (not impacted by the named arguments)

    use             named arg by, initial=.nil          -- If 'by' is not passed by the caller then the variable 'by' is dropped.
                                                        -- If 'initial' is not passed by the caller then the variable 'initial' is set to .nil.
                                                        -- The named arguments passed by the caller and not explicitely declared by the callee are not available as variables.
                                                        -- They are available in .Context~namedArgs.

    use strict      named arg by, initial=.nil          -- 'by' is mandatory.
                                                        -- 'initial' is optional, default value is .nil.
                                                        -- Only 'by' and 'initial' are accepted.

    use strict      named arg by, initial=.nil, ...     -- 'by' is mandatory.
                                                        -- 'initial' is optional, default value is .nil.
                                                        -- Any named argument is accepted.
                                                        -- The named arguments passed by the caller and not explicitely declared by the callee are not available as variables.
                                                        -- They are available in .Context~namedArgs.

    use auto        named arg                           -- Automatic retrieval or creation of variable for each named argument passed by the caller.

    use auto        named arg by, initial=.nil          -- If 'by' is not passed by the caller then the variable 'by' is dropped.
                                                        -- If 'initial' is not passed by the caller then the variable 'initial' is set to .nil.
                                                        -- The named arguments passed by the caller are available as variables.
                                                        -- They are also available in .Context~namedArgs.

    use strict auto named arg                           -- Error 99.900: STRICT AUTO requires the "..." argument marker at the end of the argument list
                                                        -- This error is raised during the parsing of the Rexx program.
                                                        -- Without an ellipsis, the keyword 'auto' is useless in strict mode.

    use strict auto named arg by, initial=.nil, ...     -- 'by' is mandatory.
                                                        -- 'initial' is optional, default value is .nil.
                                                        -- Any named argument is accepted.
                                                        -- The named arguments passed by the caller are available as variables.
                                                        -- They are also available in .Context~namedArgs.


------------
Message term
------------

    >>-receiver-+- ~ --+-messagename--+----------+--+---------------------+---><
                +- ~~ -+              +-:-symbol-+  +-(--| Arguments |--)-+

<img src="SyntaxDiagram/sd_Message_term.png" width="75.06%">

    >>-receiver[--| Arguments |--]----------------------------><

<img src="SyntaxDiagram/sd_Message_term_brackets.png" width="27.08%">


---------------
Instruction ARG
---------------

    ARG template_list

Not impacted, no access to named arguments.


---------------------
Instruction PARSE ARG
---------------------

    PARSE ARG template_list

Not impacted, no access to named arguments.


----------------
Instruction CALL
----------------

    >>-CALL----+-name-----+----| Arguments |--------------------><
               +-(-expr-)-+

<img src="SyntaxDiagram/sd_Instruction_CALL.png" width="40.06%">


--------
Function
--------

    >>-function_name(----| Arguments |----)-------------------><

<img src="SyntaxDiagram/sd_Function.png" width="32.82%">


-------------------
Instruction FORWARD
-------------------

Inconsistency with `Message~new` and `Object~run`.  
Here, `ARRAY` is followed by a list of arguments.  
There, `"Array"` is followed by a mandatory array. `"Individual"` is followed by a list of arguments.

`exprd` is a directory of named arguments.

    >>-FORWARD--+------------+--+---+--------------------+--+-------------------------+---+--+------------------+--+----------------+--+-------------+----><
                +--CONTINUE--+  |   +--ARGUMENTS--expra--+  +--NAMEDARGUMENTS--exprd--+   |  +--MESSAGE--exprm--+  +--CLASS--exprs--+  +--TO--exprt--+
                                +--------------ARRAY----(--| Arguments |--)---------------+

<img src="SyntaxDiagram/sd_Instruction_FORWARD.png" width="163.12%">


---------------
Instruction USE
---------------

                                                           +-,----------------------------------+
                                                           V                                    |
    >>-USE--+----------+--+--------+-----NAMED-----ARG--+------name-+-------+---+----------+----+--+----------+----+--><
            +--STRICT--+  +--AUTO--+                    |           +-(-n-)-+   +-=--expr--+       +--,--...--+    |
                                                        +--+-------+-----------------------------------------------+
                                                           +--...--+

<img src="SyntaxDiagram/sd_Instruction_USE.png" width="114.94%">

When the option `NAMED` is specified:

- name is a simple symbol, a stem or a compound symbol.
- Message term are not supported.
- Omitted names are not allowed.

When the option 'AUTO' is specified then a variable is retrieved or created for each named argument passed by the caller and not explicitely declared by the callee.  
If this variable has already a value then it's not overriden.  
Otherwise the value of the named argument is assigned to the variable.

There is no evaluation of the default value 'expr' when a value has been provided by the caller.  
The order of evaluation is the order of declaration in `USE NAMED ARG` (left-to-right).  
The automatic variables are already created and can be used during the evaluation of the default value.

An optional minimum length can be specified after the name, allowing abbreviation.  
- rule 1: The minimum length of an abbreviatable name must be a whole number > 0 and <= name's length.
- rule 2: The optional part of an abbreviatable name cannot contain a period.
- rule 3: A compound name cannot be abbreviated to a stem name.

For example: 
- `namedArgument(1)` will allow to pass `n:` or `na` or `nam` etc...
- `namedArgument(0)` is not allowed (rule 1).
- `namedArgument(100)` is not allowed (rule 1).
- `stem.key1(4)` and shorter is not allowed (rule 2).
- `stem.key1(5)` is not allowed (rule 3).
- `stem.key1(6)` will allow to pass `stem.k` or `stem.ke` or `stem.key` or `stem.key1`.
- `stem.key1.key2(9)` and shorter is not allowed (rule 2).
- `stem.key1.key2(10)` will allow to pass `stem.key1.` or `stem.key1.k` or `stem.key1.ke` etc...

No named parameter name must start with the name of another named parameter.  
Exception: a stem name can be used as prefix in several compound names.

For example:
- `use named arg stem., stem.key1` is allowed because `stem.` is a stem name.
- `use named arg stem, stem.key1` is not allowed because `stem` is not a stem name (no final period).
- `use named arg stem.key1., stem.key1.key2` is not allowed because `stem.key1.`is not a stem name (several periods).

--------------
UNKNOWN method
--------------

    ::method unknown
        expose target -- assuming this target will receive all of the unknown messages
        use arg name, arguments
        use named arg namedArguments -- not passed as 3rd positional argument to avoid impacts
        -- send along the message with the original args and named args
        forward to (target) message (name) arguments (arguments) namedArguments (namedArguments)


-------------
Message~new
-------------

Inconsistency with the instruction `FORWARD`.  
Here, `"Array"` is followed by a mandatory array.  
There, `ARRAY` is followed by a list of arguments. `ARGUMENTS` is followed by a mandatory array.

    >>-new(-target-,-messagename-+-------------------------------------------------------+-)--><
                                 +-,-"Individual"--| Arguments |-------------------------+
                                 +--+-------------------+--+--------------------------+--+
                                    +-,-"Array"-,-expra-+  +-,-NAMEDARGUMENTS-:-exprd-+

<img src="SyntaxDiagram/sd_Message_new.png" width="110.78%">

`NAMEDARGUMENTS:` can be abbreviated to 1 letter (`n:`).  


-------------
Message~namedArguments
-------------

Returns a directory of named arguments used to invoke the message.


----------
Object~run
----------

Inconsistency with the instruction `FORWARD`.  
Here, `"Array"` is followed by a mandatory array.  
There, `ARRAY` is followed by a list of arguments. `ARGUMENTS` is followed by a mandatory array.

    >>-run(-method-+-------------------------------------------------------+-)--><
                   +-,-"Individual"---| Arguments |------------------------+
                   +--+-------------------+--+--------------------------+--+
                      +-,-"Array"-,-expra-+  +-,-NAMEDARGUMENTS-:-exprd-+

<img src="SyntaxDiagram/sd_Object_run.png" width="95.02%">

`NAMEDARGUMENTS:` can be abbreviated to 1 letter (`n:`).  


---------------
Object~sendWith
---------------

    >>-sendWith(-messagename-,-arguments-+--------------------------+--)---><
                                         +-,-NAMEDARGUMENTS-:-exprd-+

<img src="SyntaxDiagram/sd_Object_sendWith.png" width="85.48%">

`NAMEDARGUMENTS:` can be abbreviated to 1 letter (`n:`).  


----------------
Object~startWith
----------------

    >>-startWith(-messagename-,-arguments-+--------------------------+-)---><
                                          +-,-NAMEDARGUMENTS-:-exprd-+

<img src="SyntaxDiagram/sd_Object_startWith.png" width="85.58%">

`NAMEDARGUMENTS:` can be abbreviated to 1 letter (`n:`).  


----------------
Routine~callWith
----------------

    >>-callWith(-array-+--------------------------+-)---><
                       +-,-NAMEDARGUMENTS-:-exprd-+

<img src="SyntaxDiagram/sd_Routine_callWith.png" width="64.4%">

`NAMEDARGUMENTS`: can be abbreviated to 1 letter (`n:`).  


-----------------
Context~namedArgs
-----------------

Why not `~namedArguments` ?  
Because I follow the naming convention used for the method `Args`.

Returns a directory of named arguments used to invoke the current context.  
There is no equivalent as built-in function.  
The `ARG` built-in function doesn't give access to the named arguments.


------------------
Context~setArgs
-----------------

    >>-setArgs(-array-+--------------------------+-)---><
                      +-,-NAMEDARGUMENTS-:-exprd-+

<img src="SyntaxDiagram/sd_Context_setArgs.png" width="63.54%">

`NAMEDARGUMENTS:` can be abbreviated to 1 letter (`n:`).  

Used to transfer to a coactivity the arguments passed with `resume`.  
A coactivity can be suspended, and can receive a new set of arguments after each resume.

    client (thread1)                            coactivity (thread2)
    ================                            ====================
                                                <SUSPENDED>
    Result = resume(<Arguments>) ------------>  <ACTIVE>
    <SUSPENDED>                                 use arg ...; use named arg ...
                                                ...
                                                call yield value
    <ACTIVE>                     <---result---  <SUSPENDED>
    ...                                                     
    Result = resume(<Arguments>) ------------>  <ACTIVE>
                                                use arg ...; use named arg ...
                                                ...
                                                call yield value
    <ACTIVE>                     <---result---  <SUSPENDED>
    etc...
    

------------------------
StackFrame~namedArguments
------------------------

Returns a directory of named arguments used to invoke the execution frame represented by the StackFrame instance.


------------
Function ARG
------------

Not impacted by named arguments.  
Can't be used to retrieved named arguments.


---------------------
Security manager CALL
---------------------

The information directory contains:  
`NAMEDARGUMENTS`: a directory of the function's named arguments


-----------------------
Security manager METHOD
-----------------------

The information directory contains:  
`NAMEDARGUMENTS`: a directory of the method's named arguments
