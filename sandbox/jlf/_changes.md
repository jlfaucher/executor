# Changes applied to ooRexx 4.2


<!-- ======================================================================= -->
## 1.   New native classes
<!-- ======================================================================= -->

Exported classes

```
    RexxBlock
    RexxText
    Unicode
```

Internal classes

```
    ExtensionDirective
    SourceLiteral
    UpperInstruction
```


<!-- ======================================================================= -->
## 2.   Extensions
<!-- ======================================================================= -->

See [Extension - Expression problem.txt](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/internals/notes/Extension%20-%20Expression%20problem.txt)
for the critics of Rick regarding these extensions (2011).

Two types of extensions are possible:
- Standard extensions, usable in production (not implemented in Executor).
- Unlocked extensions, that should not be used in production.

Two forms of extensions are possible:
- Direct extensions (using `.class~define`)
- Inherited extensions (using `.class~inherit`)

Overview:

```
                       +-------------------------------------------------------------------------------------+
                       |           Standard extensions            |           Unlocked extensions            |
                       |          (not yet implemented)           |        (implemented in Executor)         |
+----------------------|------------------------------------------|----------------------------------------- |
|                      | ::extension myClass                      | ::extension myClass                      |
|                      | ::method myMethod                        | ::method myMethod                        |
|                      |                                          |                                          |
|                      | or                                       |                                          |
|                      |                                          |                                          |
|                      | ::Method myClass:myMethod                |                                          |
|  Direct extensions   |                                          |                                          |
|                      | or                                       |                                          |
|                      |                                          |                                          |
|                      | ::Method myMethod Extends myClass        |                                          |
|                      |                                          |                                          |
|                      | or                                       |                                          |
|                      | ...                                      |                                          |
|----------------------|------------------------------------------|------------------------------------------|
|                      | ::extension myClass inherit myMixinClass | ::extension myClass inherit myMixinClass |
|                      |                                          |                                          |
| Inherited extensions | or                                       |                                          |
|                      |                                          |                                          |
|                      | ...                                      |                                          |
+------------------------------------------------------------------------------------------------------------+
```



<!-- ------------------------------- -->
### 2.1.   Standard extensions
<!-- ------------------------------- -->

Standard extensions are useful for modularizing class design.  

__First need expressed by Josep Maria (JMB)__    
[Syntax sugar for adding new methods to an existing class: a proposal](https://groups.io/g/rexxla-arb/topic/115749344)  
*Assume that C is a class (a non-predefined one: these cannot be altered), defined somewhere*.  
*We want to add a new method "newM" to C, without altering the package that defined C.*  
*This can currently be done in several ways, using pure ooRexx primitives.*  
*It would be nice if the language offered some syntax sugar to add methods to existing (non-predefined) classes.*  
*A syntax which could be acceptable and doesn't break anything could be:*
```REXX
    ::Method Class:Method
```
*This would add the method "Method" to class "Class".*

__[Alternative syntax proposed by Gil:](https://groups.io/g/rexxla-arb/message/1156)__  
*As an alternative syntax, I'd suggest adding a new sub-keyword to the ::Method directive.*  
*Perhaps Extends <classname> ?*   
```REXX
    ::Method Foo <other sub-keywords> Extends MyArray
```
*where MyArray is a class defined in another package.*

__Another alternative syntax__  
The `::extension` directive described later can be used as is.  
This would also enable support for inherited extensions.


<!-- ------------------------------- -->
### 2.2.   Unlocked extensions
<!-- ------------------------------- -->

Unlocked extensions are extensions applicable to the predefined classes.  
They are useful for creating prototypes and proofs of concept (no need to be an ooRexx developer).  
They are not designed for production use; therefore, they should not be enabled by default.  

If a prototype becomes candidate for official delivery then it should be re-implemented without unlocked extensions.  
This may involve some changes to the interpreter, either natively or in rexx.img (ooRexx developer profile).


<!-- ------------------------------- -->
### 2.2.1.   Unleash the potential
<!-- ------------------------------- -->

ooRexx supports natively the extension of predefined classes during the image building.  
  
Executor does not limit such extensions to the image building:
- Unlock the `define` method.  
- Unlock the `inherit` method.
  
Modifications are allowed on predefined classes and are propagated to existing instances.

```REXX
    s = '"he said ""hello"" "'
    say s                           -- "he said ""hello"" "
    
    -- Direct extension
    say s~hasMethod("quoted")       -- 0
    .string~define("quoted", "use strict arg quote='""'; return quote || self~changeStr(quote, quote||quote) || quote")
    say s~hasMethod("quoted")       -- 1 (the new method has been propagated to the old instances)
    say s~quoted                    -- """he said """"hello"""" """

    -- Inherited extension
    say s~hasMethod("unquoted")     -- 0
    .string~inherit(.StringHelpers)
    say s~hasMethod("unquoted")     -- 1 (the new inherited methods have been propagated to the old instances)
    say s~unquoted                  -- he said "hello"

    ::class "StringHelpers" mixinclass Object public

    ::method unquoted
        use strict arg quote='"'
        if self~left(1) == quote & self~right(1) == quote then
            return self~substr(2, self~length - 2)~changeStr(quote||quote, quote)
        else
            return self
```

<!-- ------------------------------- -->
### 2.3.   ::extension directive
<!-- ------------------------------- -->

```
>>-::EXTENSION--classname----+-------------------+-----------------><
                             +-INHERIT--iclasses-+
```

This directive delegates to the `.class~define` and `.class~inherit` methods.  
  
Two forms of extension are possible:
- Direct extension (using `.class~define`)
- Inherited extension (using `.class~inherit`)

When the extensions of a package are installed, the `extension` methods and the `inherit` declarations of each `::extension` are processed in the order of declaration.  
Each package is installed separately, this is the standard behaviour.  
  
The visibility rules for classes are also standard, nothing special for extensions.  
Each package has its own visibility on classes.

Implementation (copy-paste of the ::class directive, with adaptations):  
[ExtensionDirective.hpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/instructions/ExtensionDirective.hpp)  
[ExtensionDirective.cpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/instructions/ExtensionDirective.cpp)

@JMB  
The equivalent of your
[Load.Parser.Module.rex](https://rexx.epbcn.com/rexx-parser/bin/modules/Load.Parser.Module.rex)
is
[ExtensionDirective::install](https://github.com/jlfaucher/executor/blob/b6c255eabab3f75068c5956f7803ec6aeda66ce0/sandbox/jlf/trunk/interpreter/instructions/ExtensionDirective.cpp#L175-L183).


<!-- ------------------------------- -->
#### 2.3.1.   Direct extension
<!-- ------------------------------- -->

```REXX
    ::extension myClass
    ::method myMethod
```

The following rules describe the current implementation in Executor (no collision detection).  
They probably need to be modified to meet the JMB's requirement for collisions:  
*For every such method "C::newM", it picks the class object corresponding to C, checks if C already has a method "newM", complains if this is the case, and uses the define method of the C class to add newM to C.*  
In [rare cases](https://github.com/jlfaucher/executor/blob/b6c255eabab3f75068c5956f7803ec6aeda66ce0/sandbox/jlf/packages/extension/string.cls#L8-L10),
nevertheless, the collision is not an error (method override). Can still be done using ~define.  
Collision detection would not generate any errors with current Executor packages, so it could be enabled unconditionally.

__Executor rules__

If the same method appears multiple times in a given ::extension directive, it's an error (because that's how it is with ::class).

```REXX
    ::class myClass
    ::extension myClass
    ::method myMethod
    ::method myMethod   -- Error 99.902:  Duplicate ::METHOD directive instruction.
```

If the same method appears in multiple `::extension` directives in the same package, there is no error.  
The newer one replaces the older one (because `define` works like that).

```REXX
    .myclass~new~myMethod   -- 2
    ::class myClass
    ::extension myClass
    ::method myMethod; say 1
    ::extension myClass
    ::method myMethod; say 2
```

If the same method appears in multiple `::extension` directives in different packages, there is no error.  
The "last" extension wins.  
The definition of "last" depends on the resolution order of `::requires`.  
See [test_extension_order.rex](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/tests/extension/test_extension_order.rex)  
See [test_extension_order.output.reference.txt](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/tests/extension/test_extension_order.output.reference.txt)


<!-- ------------------------------- -->
#### 2.3.2.   Inherited extension
<!-- ------------------------------- -->

```REXX
    ::extension myClass inherit myExtension
```

It's possible to extend a class multiple times in the same package.  

```REXX
SourceFile.cls
    ::class myExtension1 mixinclass Object
    ::extension myClass inherit myExtension1

    ::class myExtension2 mixinclass Object
    ::extension myClass inherit myExtension2
```

It's possible to extend a class in different packages.  

```REXX
    main.rex
        .myClass~new

        ::requires "SourceFile1.cls"
        ::requires "SourceFile2.cls"

    SourceFile1.cls
        ::class myExtension mixinclass Object
        ::method init
            say "init myExtension from SourceFile1"
            forward class (super)
    
        ::requires "myClass.cls"
        ::extension myClass inherit myExtension

    SourceFile2.cls
        ::class myExtension mixinclass Object
        ::method init
            say "init myExtension from SourceFile2"
            forward class (super)

        ::requires "myClass.cls"
        ::extension myClass inherit myExtension

    myClass.cls
        ::class myClass public

        ::method init
            say "init myClass"
            forward class (super)
```

display  

```
    init myClass
    init myExtension from SourceFile1
    init myExtension from SourceFile2
```


<!-- ------------------------------- -->
##### 2.3.2.1.   The class 'Object' cannot inherit from itself"
<!-- ------------------------------- -->

I would like to write
```REXX
    ::extension Object inherit ObjectUserData ObjectPrettyPrinter
```
instead of 
[that](https://github.com/jlfaucher/executor/blob/b6c255eabab3f75068c5956f7803ec6aeda66ce0/sandbox/jlf/packages/extension/object.cls#L2),
but the `Object` class cannot inherit from a mixin class.  
Error "Class 'Object' cannot inherit from itself".

For the classes other than `Object`, Executor uses only inherited extensions.  
Example:  
[String](https://github.com/jlfaucher/executor/blob/b6c255eabab3f75068c5956f7803ec6aeda66ce0/sandbox/jlf/packages/extension/string.cls#L15-L17) in `string.cls`  
[String](https://github.com/jlfaucher/executor/blob/b6c255eabab3f75068c5956f7803ec6aeda66ce0/sandbox/jlf/packages/extension/text.cls#L11-L12) in `text.cls`  


<!-- ------------------------------- -->
### 2.4.   Extensions capabilities
<!-- ------------------------------- -->

Extensions belong to the extended classes.  
They have access to encapsulated datas and private methods.


<!-- ------------------------------- -->
#### 2.4.1   Access to encapsulated datas
<!-- ------------------------------- -->

The main variables pool is accessible from a direct extension method.  
The inherited extension methods have their own variables pool.  
This is a standard feature.

```REXX
    o = .myClass~new
    say o~myVar                         -- 0
    o~update                            -- direct extension
    say o~myVar                         -- 1 (main pool updated)
    o~update:.myExtension               -- inherited extension
    say o~myVar                         -- 1 (main pool unchanged)
    say o~myVar:.myExtension            -- 2

    ::class myClass
    ::method init
        expose myVar
        myVar = 0
    ::attribute myVar get

    -- Direct extension
    ::extension myClass
    ::method update
        -- direct access to the main pool
        expose myVar
        myVar = 1

    -- Inherited extension
    ::class myExtension mixinclass Object
    ::method update
        -- the variable pool is specific to this mixin class
        expose myVar
        myVar = 2
    ::attribute myVar get

    ::extension myClass inherit myExtension
```

<!-- ------------------------------- -->
#### 2.4.2.   Access to private methods
<!-- ------------------------------- -->

Private methods are accessible from a method added by extension.  
This is a standard feature.

```REXX
    main.rex
        o = .myClass~new
        o~publicMethod
        -- o~packageMethod                  -- not accessible
        -- o~privateMethod                  -- not accessible
        o~extendedMethod

        ::extension myClass
        ::method extendedMethod
            say "execute extendedMethod"
            -- self~packageMethod           -- not accessible
            self~privateMethod

        ::requires "SourceFile.cls"

    SourceFile.cls
        ::class myClass public

        ::method publicMethod public
            say "execute publicMethod"

        ::method packageMethod package
            say "execute packageMethod"

        ::method privateMethod private
            say "execute privateMethod"
```

display

```
    execute publicMethod
    execute extendedMethod
    execute privateMethod
```

__Private methods of predefined classes__

When using an unlocked extension method, the private methods of a predefined class are
[accessible](https://github.com/jlfaucher/executor/blob/b6c255eabab3f75068c5956f7803ec6aeda66ce0/sandbox/jlf/packages/extension/doers.cls#L421-L424).

__Package-scope methods__

Package-scope methods are not accessible when the extension is made from a different package.  
This is a standard feature but surprising when the extension method and the package-scope method are in the same class...  
A method defined in a C class should have access to all methods in the C class.  
Reproductible without extensions:

```
    main.rex
        .myClass~define("extendedMethod", .methods["EXTENDEDMETHOD"])
        o = .myClass~new
        o~extendedMethod

        ::method extendedMethod
            say "execute extendedMethod"
            -- self~packageMethod           -- not accessible
            self~privateMethod
```


<!-- ======================================================================= -->
## 3.   Tokenizer
<!-- ======================================================================= -->

Support this notation:

```REXX
1+2i
```
where `i` is an instance of `the Complex class`.


The tokenizer has been modified to split a symbol of the form `<number><after number>` in two distinct tokens.  
Ex: `2a` is the number 2 followed by the symbol `a`.  
Ex: `2a2b` is the number 2 followed by the symbol `a2b`.  
Ex: `2e1a2b` is the number 2e1 followed by the symbol `a2b`.

The rule is to stop immediatly after a VALID number, where a VALID number is such as `datatype(number) = "NUM"`.

1.  `2e` is scanned as number `2` followed by symbol `E` because `datatype(2e)` is `CHAR`, not `NUM`. So only `2` is a VALID number.  
    In official ooRexx, this is scanned as symbol `2E`.
2.  `2e+` is scanned as number `2` followed by symbol `E` followed by operator `+`.  
    In official ooRexx, this is scanned as symbol `2E` followed by operator `+`.
3.  `2e1` is scanned as number `2E1`, same as official ooRexx.
4.  `2e+1` is scanned as number `2E+1`, same as official ooRexx

An abuttal operator is inserted to re-concatenate `<number>` with `<after number>`.  
In this context, the precedence of this abuttal operator is very high, to ensure both tokens are always linked together.

The end-user can provide his own implementation for abuttal, using the alternative operator's message `"OP:RIGHT"`.  
This is how `2i` can become `2 * .Complex~i` when `complex.cls` is loaded.  
Thanks to the high precedence in this context, `1+2i` is parsed as `1+(2i)` instead of `(1+2)i`.

Legacy programs are impacted when
1.  `<after number>` is a valid variable symbol and the `NOVALUE` condition is enabled.
2.  A label starts with a number:

```REXX
    raise 2a                    -- Data must not follow the SIGNAL label name; found ""
    2a:                         -- Incorrect expression detected at ":"
    do i=1 to 5; say i; end 2a  -- Data must not follow the END control variable name; found ""
```


<!-- ======================================================================= -->
## 4.   Parser
<!-- ======================================================================= -->

<!-- ------------------------------- -->
### 4.1.   Refinement of tokens 'subclass' attribute
<!-- ------------------------------- -->

The scanner splits a source file in clauses, and decompose each clause in tokens.  
Then the parser creates an AST from the tokens.  
The tokens were not annotated by the parser to attach semantic information found during parsing.  
After a discussion with Rony about syntax coloring, I decided to see which informations could be added to the tokens.  
I found that the attribute 'subclass' of the tokens could hold informations like that:

```
IS_KEYWORD
IS_SUBKEY
IS_DIRECTIVE
IS_SUBDIRECTIVE
IS_CONDITION
IS_BUILTIN
```

For the moment, there is no access to the clauses/tokens from an ooRexx script.  
If the environment variable `RXTRACE_PARSING=ON` then the clauses and tokens are dumped to the debug output (Windows) or the log (Unix) using `dbgprintf`.  
Works only with a debug version of ooRexx.


<!-- ------------------------------- -->
### 4.2.   `arg(...)`
<!-- ------------------------------- -->

For good or bad reason, `arg(1)` at the begining of a clause is recognized as an instruction, because arg is a keyword instruction.

I often use source literals like `{arg(1)...}` where I want `arg(1)` to be interpreted as a function call.  
So I decided to change the behavior of the parser to interpret as a function call any symbol followed immediatly by a left paren, even if the symbol is a keyword instruction.

```
    Illustration from ooRexxShell:

        executor:
        arg()       -- bash: 0: command not found

        oorexx:
        arg()       -- Missing expression following "(" of parse template.

    Not just arg! ALL the keywords are impacted.

        executor:
        drop()      -- Could not find routine "DROP"

        oorexx:
        drop()      -- Symbol expected after "(" of a variable reference.
```

<!-- ------------------------------- -->
### 4.3.   `=` `==`
<!-- ------------------------------- -->

With implicit return, such an expression is quite common when filtering: `item==1`

```REXX
    .array~of(1,2,1)~pipe(.select {item==1} | .console)
```

but the parser raises an error to protect the user against a potential typo error, assuming the user wanted to enter `item=1`.

I deactivated this control, now the expression above is ok.  
Modified [SourceFile.cpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/parser/SourceFile.cpp), `RexxSource::instruction`


Yes, it remains a problem (no syntax error, but it's an assignment, not a test):

```REXX
    .array~of(1,2,1)~pipe(.select {item=1} | .console)
```

good point, the lack of returned value is detected, must surround by parentheses to make it a real expression.

```REXX
    .array~of(1,2,1)~pipe(.select {(item=1)} | .console)
(an Array),1 : 1
(an Array),3 : 1
```


<!-- ------------------------------- -->
### 4.4.   Message term
<!-- ------------------------------- -->

Tilde-call message `"~()"`.
The message name can be omitted, but the list of parameters is mandatory (can be empty).

```REXX
    target~()
    target~(arg1, arg2, ...)
    target~~()
    target~~(arg1, arg2, ...)
```

When the expression is evaluated, the target receives the message `"~()"`.


```
>>-receiver-+- ~ --+----+---------+----(--+----------------+--)--><
            +- ~~ -+    +-:symbol-+       | +-,----------+ |
                                          | V            | |
                                          +---expression-+-+
```


<!-- ======================================================================= -->
## 5.   Clauser
<!-- ======================================================================= -->

<!-- ------------------------------- -->
### 5.1.   Description
<!-- ------------------------------- -->

The Clauser class is implemented in [RexxClasses/Parser.orx](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/RexxClasses/Parser.orx).  
Used internally by the interpreter when parsing a RexxSourceLiteral.  
Used by ooRexxShell to transform the command line when a clause ends with `'='`.

The Clauser works directly on the source array passed at creation.  
It returns only non-empty clauses (unless you modify a clause, see below).  
You can modify the source array by replacing the current clause by a new one:

```REXX
    myClauser~clause = mySourceFragment
```
The new clause is inserted as-is and not iterated over by the clauser.  
Of course, you can create a new clauser using the modified source, and then you will iterate over your modified clauses.  
While you don't call `~nextClause`, `~clause` will return the last assigned value, which can be anything, like an empty string or a string containing several clauses.

Exemple:

```REXX
    csource = {
        clause1

        clause2 ; clause3
        clause4 ; ;
        clause5a, -- comment
        clause5b /* multiline
        comment */ clause5c ; clause6
    }
    sourceArray = csource~source -- Each time you call this method, you get a copy of the original source literal

    say "Iterate over the original source:"
    i = 1
    do sourceLine over sourceArray
        say i '"'sourceLine'"'
        i +=1
    end

    say
    say "Iterate over the clauses, surround clause2, remove clause3, shrink clause5:"
    clauser = .Clauser~new(sourceArray) -- The clauser works directly on this source array, no copy
    i = 1
    do while clauser~clauseAvailable
        clause = clauser~clause
        if clause~match(1, "clause2") then clauser~clause = "clause2 before ; "clause" ; clause2 after"
        if clause~match(1, "clause3") then clauser~clause = ""
        if clause~match(1, "clause5") then clauser~clause = "clause5"
        say i '"'clause'" --> "'clauser~clause'"'
        clauser~nextClause
        i += 1
    end

    say
    say "Iterate over the modified source:"
    i = 1
    do sourceLine over sourceArray
        say i '"'sourceLine'"'
        i += 1
    end

    say
    say "Iterate over the clauses of the modified source:"
    clauser = .Clauser~new(sourceArray)
    i = 1
    do while clauser~clauseAvailable
        clause = clauser~clause
        say i '"'clause'"'
        clauser~nextClause
        i += 1
    end
```

Output:

```REXX
    Iterate over the original source:
    1 ""
    2 "    clause1"
    3 ""
    4 "    clause2 ; clause3"
    5 "    clause4 ; ;"
    6 "    clause5a, -- comment"
    7 "    clause5b /* multiline"
    8 "    comment */ clause5c ; clause6"

    Iterate over the clauses, surround clause2, remove clause3, shrink clause5:
    1 "clause1" --> "clause1"
    2 "clause2" --> "clause2 before ; clause2 ; clause2 after"
    3 "clause3" --> ""
    4 "clause4" --> "clause4"
    5 "clause5a     clause5b  clause5c" --> "clause5"
    6 "clause6" --> "clause6"

    Iterate over the modified source:
    1 ""
    2 "    clause1"
    3 ""
    4 "clause2 before ; clause2 ; clause2 after;"
    5 "    clause4 ; ;"
    6 "clause5"
    7 ""
    8 "; clause6"

    Iterate over the clauses of the modified source:
    1 "clause1"
    2 "clause2 before"
    3 "clause2"
    4 "clause2 after"
    5 "clause4"
    6 "clause5"
    7 "clause6"
```


<!-- ------------------------------- -->
### 5.2.   Helper for immediate parsing
<!-- ------------------------------- -->

```REXX
::method rawExecutable class unguarded
```
For each RexxSourceLiteral created during the parsing, the interpreter will call this method to get the executable to store on the RexxSourceLiteral.


<!-- ------------------------------- -->
### 5.3.   Replace the current clause
<!-- ------------------------------- -->

```REXX
::method "clause="
```

Replace the current clause by the new source fragment (black box, can be several clauses, won't be scanned).  
The new source fragment is always monoline.  
The new source fragment is always inserted in the first line of the current clause.  
If the current clause is multiline, then the remaining lines are made empty.


<!-- ------------------------------- -->
### 5.4.   Re-implementation in ooRexx of `RexxSource::comment` 
<!-- ------------------------------- -->

```REXX
::method skipComment private
```

Re-implementation in ooRexx of the native method `RexxSource::comment` which is implemented in [interpreter/parser/scanner.cpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/parser/Scanner.cpp)


<!-- ------------------------------- -->
### 5.5.   Re-implementation in ooRexx of `RexxSource::locateToken`
<!-- ------------------------------- -->

```REXX
::method locateToken private
```

Re-implementation in ooRexx of the native method `RexxSource::locateToken` which is implemented in [interpreter/parser/scanner.cpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/parser/Scanner.cpp)


<!-- ------------------------------- -->
### 5.6.   Re-implementation in ooRexx of `RexxSource::nextSpecial`
<!-- ------------------------------- -->

```REXX
::method nextSpecial private
```

Re-implementation in ooRexx of the native method `RexxSource::nextSpecial` which is implemented in [interpreter/parser/scanner.cpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/parser/Scanner.cpp)


<!-- ------------------------------- -->
### 5.7.   Re-implementation in ooRexx of a subset of `RexxSource::sourceNextToken`
<!-- ------------------------------- -->

```REXX
::method sourceNextToken
```

Re-implementation in ooRexx of a subset of the native method `RexxSource::sourceNextToken` which is implemented in [interpreter/parser/scanner.cpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/parser/Scanner.cpp)  
I don't need to get ALL the tokens, I just need to skip them correctly (in particular strings and source literal).  
The comments and continuation characters are also properly supported.  
Possible result: `.nil` (end of source), `TOKEN_EOC` (end of clause), `TOKEN_OTHER`.  
The clause is built incrementally, accumulating all the characters, except comments.  
The line continuations are removed, replaced by a blank.  
So a clause is always monoline, even if it's distributed on several lines in the source.


<!-- ------------------------------- -->
### 5.8.   Helper for immediate parsing.  
<!-- ------------------------------- -->

```REXX
::method kind
```

For each `RexxSourceLiteral` created during the parsing, the interpreter will call this method to get the kind of executable to store on the RexxSourceLiteral.

If the first word is `::co[activity]` then remove this word and remember it's a coactive routine: "r.co".  
If the first clause is an expose clause then it's a coactive closure: "cl.co".

If the first word is `::r[outine]` then remove this word and remember it's a routine: "r".  
If the first clause is an expose clause then it's a closure: "cl".

If the first word is `::[xxx]` then raise an error (unknown tag)


<!-- ------------------------------- -->
### 5.9.   Helper to transform a source.  
<!-- ------------------------------- -->

```REXX
::method transformSource
    use strict arg clauseBefore="", clauseAfter=""
```

Possible transformations:  
- Insert a clause at the begining (takes care of the expose instruction, keep it always as first instruction).
- Insert a clause at the end.


<!-- ======================================================================= -->
## 6.   numeric digits propagate
<!-- ======================================================================= -->

The problem I wanted to fix:  
numeric digits has no effect on the called routines/methods.  
Setting the precision at package level with `::option digits` is not helping when you want to test several settings interactively.  
With one-liners, you can hardcode the precision where you do a calculation, but the code becomes polluted by these declarations.  
If you don't want to hardcode the precision, the code is still more polluted with the use of arguments. See [Sandbox diary](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/_diary.txt) 2020 nov 16.

```REXX
    numeric digits 30
    1~10000~reduce("*")=                               -- 2.84625960E+35659, the precision is the default one
    1~10000~reduce{numeric digits 30; accu * item}=    -- 2.84625968091705451890641321250E+35659
```

How to fix:  
Propagate the numeric settings of the current activation to its child activations, recursively.  
Of course, that must be under control of the programmer.  
By default, the behavior is to not propagate.

Implemented solution:  

- add the option `PROPAGATE` to `NUMERIC DIGITS`
- add the method `.RexxContext~digitsPropagate`

The option is available only with `NUMERIC DIGITS` but it controls the propagation of all the numeric settings.

```REXX
    numeric digits              -- default precision, local
    numeric digits propagate    -- default precision, digits form and fuzz are propagated
    numeric digits 30           -- precision is 30, local
    1~10000~reduce("*")=        -- 2.84625960E+35659, the precision for this calculation is 9, it has not been propagated
    numeric digits propagate 30 -- precision is 30, digits form and fuzz are propagated
    1~10000~reduce("*")=        -- 2.84625968091705451890641321250E+35659, the precision has been propagated
```


<!-- ======================================================================= -->
## 7.   Blocks (source literals)
<!-- ======================================================================= -->

A RexxBlock is a piece of source code surrounded by curly brackets.


<!-- ------------------------------- -->
### 7.1.   Big picture
<!-- ------------------------------- -->

a RexxSourceLiteral is an internal rexx object, created by the parser, not accessible from ooRexx scripts.

a RexxSourceLiteral holds the following properties, shared among all the RexxBlock instances created from it:
- source: the text between the curly brackets `{...}` as an array of lines, including the tag `::xxx` if any.
- package: the package which contain the source literal.
- kind: kind of source, derived from the source's tag.
- rawExecutable: routine or method created at load-time (immediate parsing).

a RexxBlock is created each time the RexxSourceLiteral is evaluated, and is accessible from ooRexx scripts.

a RexxBlock contains informations that depends on the evaluation context.  
In particular, when a RexxBlock is a closure's source, it will hold a snapshot of the context's variables:
- `~source`: source of the `RexxSourceLiteral`.
- `~variables`: snapshot of the context's variables (a directory), created only if the source starts with `expose`.
- `~rawExecutable`: the raw executable of the `RexxSourceLiteral`, created at load-time (routine or method).
- `~executable`: cached executable, managed by `doers.cls`. `~executable~source` can be different from `~source`.


<!-- ------------------------------- -->
### 7.2.   Kind of source
<!-- ------------------------------- -->

By default (no tag) the executable is a routine.  
Ex:
```REXX
    {use strict arg name, greetings; say "hello" name || greetings}~("John", ", how are you ?") -- hello John, how are you ?
```
If the source starts with "expose" then the doer is a closure.


`::routine` is an optional tag to indicate that the doer is a routine.  
Minimal abbreviation is `::r`.  
If the source after the tag starts with `expose` then the doer is a closure.


`::coactivity` is a tag to indicate that the doer is a coactivity.  
Minimal abbreviation is `::co`.  
If the source after the tag starts with `expose` then the doer is a coactive closure.


<!-- ======================================================================= -->
## 8.   .ThreadLocal
<!-- ======================================================================= -->

Implements the [feature request 378](https://sourceforge.net/p/oorexx/feature-requests/378/).  
Done by adding support for the variable `.threadLocal` in `RexxActivation::rexxVariable`.

Note 1:  
I did not modify `RexxDotVariable` to search in `.threadLocal`.  
Maybe should be done, but I find that the search made by `RexxDotVariable` is already slow enough.

Note 2:  
Seems faster to do that:  
```REXX
    do i=1 to 100000; v=.threadlocal["MY.VAR"] ; end
        5 runs: 0.078 0.109 0.109 0.046 0.046
```
rather than that:
```REXX
    do i=1 to 100000; v=.threadlocal~my.var ; end
        5 runs: 0.140 0.141 0.156 0.140 0.141
```

<!-- ======================================================================= -->
## 9.   Coactivity
<!-- ======================================================================= -->

<!-- ------------------------------- -->
### 9.1.   Dependency on native extensions
<!-- ------------------------------- -->

Implemented by [concurrency/coactivity.cls](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/packages/concurrency/coactivity.cls)  
with a dependency on these native extensions:
- `.context~parentContext`: let retrieve the context of the yield's caller.
- `.context~setargs(<array>, <directory>)`: let store the arguments passed to resume
- `.threadLocal`


<!-- ------------------------------- -->
### 9.2.   Description
<!-- ------------------------------- -->

A coactivity is an emulation of coroutine, named "coactivity" to follow the ooRexx vocabulary.  
This is not a "real" coroutine implementation, because it's based on ooRexx threads and synchronization.

A coactivity remembers its internal state.  
It can be called several times, the execution is resumed after the last executed `.yield[]`.  

Example:
```REXX
    block = {::coactivity
             say "hello" arg(1) || arg(2)
             .yield[]
             say "good bye" arg(1) || arg(2)
            }
    block~("John", ", how are you ?") -- hello John, how are you ?
    block~("Kathie", ", see you soon.") -- good bye Kathie, see you soon.
    block~("Keith", ", bye") -- <nothing done, the coactivity is ended>
```

<!-- ------------------------------- -->
 Producer / consumer
<!-- ------------------------------- -->

Producer/consumer problems can often be implemented elegantly with coactivities:
- The consumer can pass arguments: `producerResult = aCoactivity~resume(args...)`.  
- The producer (aCoactivity) returns a result to the consumer: `.yield[result]`.

`.context~setargs` is used to transfer to a coactivity the arguments passed with `resume`.  
A coactivity can be suspended, and can receive a new set of arguments after each resume.

```
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
``` 

<!-- ------------------------------- -->
### 9.3.   Stackful coroutine
<!-- ------------------------------- -->

A stackful coroutine is a coroutine able to suspend its execution from within nested calls.  
`.threadLocal` is needed to retrieve the coactivity instance from any invocation and send it the message yield  
(this instance is at the origin of the invocations stack, but is not passed as a parameter to the invocations).

```
myCoactivity~start  <--------------+
    invocation                     |
        invocation                 |
            ...                    |
                invocation: .Coactivity~yield()
```


<!-- ------------------------------- -->
### 9.4.   yield implementation
<!-- ------------------------------- -->

```REXX
::method yield
    ...
    -- yieldItem will be returned to the Coactivity's client by 'resume'
    use strict arg yieldItem
    ...
    status = .CoactivityObj~suspended                   -- the producer is suspended
    guard off                                           -- the client is active
    guard on when status <> .CoactivityObj~suspended    -- the client is suspended, the producer is active
    ...
    -- The client made a resume(arguments, :namedArguments)
    -- Update the arguments of the caller's context
    -- Must unwind until we reach a context whose package is not the current package.
    context = .context
    currentPackage = context~package
    do while .nil <> context, context~package == currentPackage -- search for the first context outside this package
        context = context~parentContext -- .nil if native or top-level activation.
    end
    if .nil == context then raise syntax 93.900 array ("Can't update the arguments, yield's context not found")
    context~setargs(arguments, :namedArguments) -- assigns the positional and named arguments that the coactivity's client passed to 'resume'
```


<!-- ======================================================================= -->
## 10.   Closures
<!-- ======================================================================= -->

A closure is an object created from a block whose source first word after the optional tag is `expose`.  
A closure remembers the values of the variables defined in the outer environment of the block.  


<!-- ------------------------------- -->
### 10.1.   Closure by value
<!-- ------------------------------- -->

The behaviour of the closure is a method generated from the block, which is attached to the closure under the name `"do"`.  
The values of the captured variables are accessible from this method `"do"` using expose.  
Updating a variable from the closure will have no impact on the original context (hence the name "closure by value").  
A closure can be passed as argument, or returned as result.


Examples:

```REXX
    v = 1
    closure = {expose v; say v; v += 10}    -- capture the value of v: 1
    v = 2
    closure~()                              -- display 1
    closure~()                              -- display 11
    closure~()                              -- display 21
    say v                                   -- v not impacted by the closure: 2

    range = { use arg min, max ; return { expose min max ; use arg num ; return min <= num & num <= max }}
    from5to8 = range~(5, 8)
    from20to30 = range~(20, 30)
    say from5to8~(6) -- 1
    say from5to8~(9) -- 0
    say from20to30~(6) -- 0
    say from20to30~(25) -- 1
```

A coactive closure is both a closure and a coactivity:
- as a closure, it remembers its outer environment.
- as a coactivity, it remembers its internal state.
It can be called several times, the execution is resumed after the last `.yield[]`.

Examples:
```REXX
    v = 1
    w = 2
    closure = {::coactivity expose v w ; .yield[v] ; .yield[w]}
    say closure~() -- 1
    say closure~() -- 2
```

Implementation note:  
Currently, the instance of closure is created by user code in [doers.cls](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/packages/extension/doers.cls).  
See the `sourceDoer` method of `RexxBlockDoer`.  
See the `init` method of `Closure`.  
This is a very inefficient implementation, to replace by a native (C++) implementation.


<!-- ------------------------------- -->
### 10.2.   Closure settings
<!-- ------------------------------- -->

<!-- -------------------- -->
#### 10.2.1.   Standard ooRexx behavior
<!-- -------------------- -->

When a routine or method is created, a new `RexxSource` (i.e. a package) is created.  
All the settings defined on the package level (i.e. `RexxSource`) have the default values.  
It's possible to pass a context from which a `RexxSource` is taken (called `parentSource`) which allows the created routine/method to inherit class and routine lookup scope from another source.  
Nothing else is inherited.

[inherited from context]
```
    routines
    merged_public_routines
    installed_classes
    merged_public_classes
```
[not inherited from context]
```
    digits
    fuzz
    form
    trace
    enableCommands (sandbox only)
    enableMacrospace (sandbox only)
    the security manager
```

<!-- ------------------------- -->
#### 10.2.2.   Q1 (answered and implemented)
<!-- ------------------------- -->

The raw executable created from a `RexxBlock` is a routine or a method.  
Given the rule explained above, this raw executable has its own `RexxSource` (i.e. package):

```REXX
    say .context~package~identityHash ; {say .context~package~identityHash}~() -- the hashes are different
```

Should a `RexxBlock` inherit the settings of the package in which it's defined ? answer: yes.  
If yes, all kinds of `RexxBlock` or just a closure ? answer: all kinds of `RexxBlock`.  
Currently, the visibility on routines/classes is inherited, but none of the following options are inherited:

```REXX
    ::options digits
    ::options form
    ::options fuzz
    ::options trace
    ::options commands (sandbox only)
    ::options nocommands (sandbox only)
    ::options macrospace (sandbox only)
    ::options nomacrospace (sandbox only)
    the security manager
```

Illustration:

```REXX
    say 1/3
    {say 1/3}~()
    ::options trace i
    ::options digits 20
```

Output:

```REXX
     1 *-* say 1/3
       >L>   "1"
       >L>   "3"
       >O>   "/" => "0.33333333333333333333"
       >>>   "0.33333333333333333333"
0.33333333333333333333
     2 *-* {say 1/3}~()
       >L>   "a RexxBlock"
0.333333333
```

[2014 jan 06] Q1 has been adressed:  
Inherit the toplevel source options settings, when creating a method or routine for a block.  
A new optional parameter `isBlock` can be passed when creating a method or routine:

```REXX
    .Method~new("do", sourceArray, context, isBlock)
    .Routine~new("", sourceArray, context, isBlock)
```

This indicator is used to activate specific behaviour, like inheritance of toplevel source options.


<!-- ----------------- -->
#### 10.2.3.   Q2 (not yet answered)
<!-- ----------------- -->

Same question for the settings of the `RexxActivation` in which the `RexxBlock` is evaluated.  
Here, only a closure  is supposed to capture its environment.  
Should a closure remember the following settings of its defining `RexxActivation`?  
The goal being to reuse automatically these settings at each execution (so from a different `RexxActivation`).  
Currently, none of the following settings are captured:

```REXX
    numeric digits
    numeric form
    numeric fuzz
    trace
    options "commands" (sandbox only)
    options "nocommands" (sandbox only)
    options "macrospace" (sandbox only)
    options "nomacrospace" (sandbox only)
```

Illustration:
```REXX
    trace i
    numeric digits 20
    say 1/3
    {expose something; say 1/3}~()
```

Output:

```REXX
     2 *-* numeric digits 20
       >L>   "20"
       >>>   "20"
     3 *-* say 1/3
       >L>   "1"
       >L>   "3"
       >O>   "/" => "0.33333333333333333333"
       >>>   "0.33333333333333333333"
0.33333333333333333333
     4 *-* {expose something; say 1/3}~()
       >L>   "a RexxBlock"
0.333333333
```


<!-- ======================================================================= -->
## 11.   New option NOCOMMANDS
<!-- ======================================================================= -->

Added an option to control execution of commands:

```REXX
    ::options COMMANDS
    ::options NOCOMMANDS
    options "COMMANDS"
    options "NOCOMMANDS"
```

By default, a clause consisting of an expression only is interpreted as a command string.  
When using the option `NOCOMMANDS`, the value of the expression is stored in the `RESULT` variable, and not interpreted as a command string.


<!-- ======================================================================= -->
## 12.   No value
<!-- ======================================================================= -->

This is not an extension, it's a standard functionality, but undocumented:  
When a variable has no value, the interpreter sends the message `"NOVALUE"` to the object `.local["NOVALUE"]`.

I use this functionality to manage special variable like `i`, `infinity`, `indeterminate`.
```REXX
    i=              -- (0+1i)
    infinity=       -- (The positive infinity)
    indeterminate=  -- (The indeterminate value)
```

Example:
```REXX
    signal on novalue name novalue_continue
    say foo

    continue:
    signal on novalue name novalue_exit

    .local["NOVALUE"] = .novalue

    say infinity
    say indeterminate
    say foo

    return

    novalue_continue:
    say "novalue condition!" condition("description")
    signal continue

    novalue_exit:
    say "novalue condition!"

    ::class novalue

    ::method novalue class
        use strict arg name
        call charout , "Intercepting no value for" name": "
        forward message (name)

    ::method infinity class
        return "default value for infinity"

    ::method unknown class
        use strict arg msg, args
        if msg~caselessEquals("indeterminate") then return "default value for indeterminate"
```

Output:
```
    novalue condition! FOO
    Intercepting no value for INFINITY: default value for infinity
    Intercepting no value for INDETERMINATE: default value for indeterminate
    Intercepting no value for FOO: novalue condition!
```

<!-- ======================================================================= -->
## 13.   Order of argument checking for Boolean operators
<!-- ======================================================================= -->

Changed the order of argument checking for Boolean operators.  
In case of wrong value on both sides, the error about the right side was raised first.

It's more clear to report an error about the left side when both sides are wrong, otherwise you have the wrong impression that only the right side is wrong (the evaluation is from left to right).

Before:
```REXX
    "not a boolean value" | .console    -- Logical value must be exactly "0" or "1"; found "The console class"
```

Now:
```REXX
    "not a boolean value" | .console    -- Logical value must be exactly "0" or "1"; found "not a boolean value"
```

<!-- ======================================================================= -->
## 14.   Symmetric implementation of operator
<!-- ======================================================================= -->

<!-- ------------------------------- -->
### 14.1.   Rationale
<!-- ------------------------------- -->

The standard ooRexx doesn't allow to define symmetric overriding of operators.  
You can define a user operator on `.array` which supports `.array~of(1,2) + 10`.  
But you can't define a user operator whcih supports `10 + .array~of(1,2)`.

The extended ooRexx has been modified to automatically try `b~"op:right"(a)`when `a~"op"(b)` raises an exception.

If an alternate implementation exists then use it, otherwise raise the exception.  
That must be done in each implementation of operator.  
The two methods `Object::messageSend` have been modified to let pass an additional parameter `processUnknown` which is true by default (legacy behavior).  
When this parameter is false, and no method is found for the message, then `Object::messageSend` returns false to indicate that no implementation exists.  
There is no processing of the unknown message.

This is an efficient way to test if an alternate implementation exists and use it.  
When the alternate implementation returns nothing, then don't complain about that.  
Behave as if the alternate implementation did not exist, and raise the exception related to the left argument.

Example of symmetric operator:

```REXX
    ::extension Array inherit ArrayOperators
    ::class "ArrayOperators" mixinclass Object public

    ::method "+"
        if arg() == 0 then return self~map("+")
        use strict arg right
        if right~isA(.array) then do
            if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
            return self~map{expose right ; item + right[index]}
        end
        return self~map{expose right ; item + right}

    ::method "+op:right"
        use strict arg left
        if left~isA(.array) then do
            if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
            return self~map{expose left ; left[index] + item}
        end
        return self~map{expose left ; left + item}
```

Now you can write:

```REXX
    .array~of(1,2) + 10=                -- [11,12]
    10 + .array~of(1,2)=                -- [11,12]
    .array~of(1,2) + .array~of(3,4)=    -- [4,6]
```


<!-- ------------------------------- -->
### 14.2.   Design decisions
<!-- ------------------------------- -->

Modification of the following methods to give a chance for an alternative operator before forcing the second argument to a string:

```
    RexxInteger::concatBlank
    RexxInteger::concat
    RexxNumberString::concatBlank
    RexxNumberString::concat
    RexxString::concatRexx
    RexxString::concatBlank
```

If the second argument is not a string, then try the alternative operator before `REQUEST_STRING`.

```REXX
    a = .array~of(10,20,30)
    100 a=                  -- ['100 10','100 20','100 30'] instead of '100 an Array'
    a 100=                  -- ['10 100','20 100','30 100']
    100 || a =              -- [10010,10020,10030]          instead of '100an Array'
    a || 100 =              -- [10100,20100,30100]
```

Modification of the following methods in [CoreClasses.orx](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/RexxClasses/CoreClasses.orx) to give a chance for an alternative operator:

```REXX
    .DateTime~"-"
    .DateTime~"+"
    .TimeSpan~"-"
    .TimeSpan~"+"
```

Illustration:

```REXX
    ts1day = .TimeSpan~fromDays(1)                  -- (1.00:00:00.000000)
    ts1hour = .TimeSpan~fromHours(1)                -- (01:00:00.000000)
    date = .datetime~new(2013,1,10, 12, 30, 10)     -- (2013-01-10T12:30:10.000000)
    date + .array~of(ts1hour, ts1day)=              -- [(2013-01-10T13:30:10.000000),(2013-01-11T12:30:10.000000)]
```

Got a crash because I don't always return a value from an operator.  
In my approach of operator overriding, not returning a value is the way to indicate that the current implementation doesn't know how to support the current arguments.  
The lack of result is managed in the new implementation of the operators, but is not managed in the rest of the interpreter.  
The crash was here:

```C++
    bool RexxObject::isEqual(RexxObject *other)
    {
        ...
        else
        {
            ProtectedObject result;
            this->sendMessage(OREF_STRICT_EQUAL, other, result);
            return ((RexxObject *)result)->truthValue(Error_Logical_value_method);
        }
    }
```

result is `NULL` when the user code doesn't return a result, must be tested.  
Review of all the `sendMessage` used internally by the interpreter, which need a test:

```
    RexxClass::isEqual
    RexxInteger::isEqual
    RexxNumberString::isEqual
    RexxObject::isEqual
    RexxString::hash
    RexxString::isEqual
```

Made a review of all my ooRexx scripts to swap the position of `.nil` in the tests, to make it the first argument.  
Since I defined the array operators, I can have an array as result for operators "=", "==", "<>", etc... when the first argument is an array.  
Had to swap `.nil` in [StreamClasses.orx](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/RexxClasses/StreamClasses.orx).

This technique of putting `.nil` as first argument is already used in several places of the interpreter.  
The reason is explained in rexxref (section Required string values):  
When comparing a string object with `the Nil object`, if the `NOSTRING` condition is being trapped, then
```REXX
    if string = .nil
```
will raise the `NOSTRING` condition, whereas
```REXX
    if .nil = string
```
will not as `the Nil object`’s "=" method does not expect a string as an argument.

Previous work about swaping the position of .nil is not enough to avoid errors.  
I have this case in [pipe_extension_test.rex](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/samples/pipeline/pipe_extension_test.rex):

```REXX
    datas = .directory~new
    datas["key1"] = .array~of("header", 1, 2, "footer")
    datas["key2"] = .array~of("header", 5, 3, -9, 12, "footer")
    datas["key3"] = .array~of("header", 4, 6, 5, "footer")
    -- The datas without the headers and footers
    datas~pipe(.inject {item} iterateBefore memorize | .drop first {dataflow["source"]~item } | .drop last {dataflow["source"]~item } | .console)
```

where the source of the pipe is a directory of arrays.  
The code in charge of the partitioning do this test:
```REXX
    if previousPartitionItem <> partitionItem then do
```
and an error is raised because the two arguments are arrays, and the result is an array.  
Here, the goal is to test if the two arguments are the same object.

Conclusion:  
The operators for array programming should be:

- either activated only when needed, under control of the programmer.
- or deactivated by the interpreter when the context is a scalar context (ex: when calling truthValue).
- or not defined at all when conflicting with the interpreter semantics.

I select the third option: no longer override the operators "=", "\=", "><", "<>", "==", "\==".  
I provide the methods ~mapEqual, ~mapNotEqual, ~mapStrictEqual, ~mapStrictNotEqual.

Remember:  
When operators for array programming are activated, the only way to use the scalar semantic is to refer explicitly to the `.Object`'s operators.

```REXX
    a = .array~of(1,2,3)
    a == a=              -- [1,1,1]
    a~"=="(a)=           -- [1,1,1]
    a~"==":.object(a)=   -- 1
```

I have no problem with `.array~ppRepresentation`, whereas there is a test of equality to detect if a recursive array is printed.  
Normally should raise an error because of `"=="` returning an array.  
But it seems that `level = stack~index(val)` is not impacted by the array operator `"=="`.  
Verification in the implementation:

```C++
    RexxObject *RexxQueue::index(RexxObject *target)
        uses: if (target->equalValue(element->value))

    class RexxObject : public RexxInternalObject {
         bool inline equalValue(RexxObject *other)
         {
             // test first for direct equality, followed by value equality.
             return (this == other) || this->isEqual(other);
         }

    bool RexxObject::isEqual( RexxObject *other )
    {
        if (this->isBaseClass()) return ((RexxObject *)this) == other;
        else  /* return truth value of a compare   */
        {
            ProtectedObject result;
            this->sendMessage(OREF_STRICT_EQUAL, other, result);
            if ((RexxObject *)result == OREF_NULL) reportException(Error_No_result_object_message, OREF_STRICT_EQUAL);
            return ((RexxObject *)result)->truthValue(Error_Logical_value_method);
        }
    }
```

So we have three cases for this test of equality:

1. If arg1 and arg2 are the same instance, then the equality is true
2. If arg1 is a base class (i.e. not a subclass instance or an enhanced one-off), then return true when arg1 and arg2 are the same instance.
3. return `arg1~"=="(arg2)`

Only 1) and 2) happen because my test is done with instances of `.Array` (so a base class).  
That explains why I don't have an error...


<!-- ------------------------------- -->
### 14.3.   Shared implementation to rework
<!-- ------------------------------- -->

Some alternative messages are never sent by the interpreter, because there is a shared implementation for some operators.  
For example: `""` and `"||"` are implemented by the same method `concat`.  
The alternative message `"||op:right"` can be send, but the message `"op:right"` will NEVER be sent.

```
OP    RexxObject                          RexxInteger           RexxNumberString      RexxString            Comment
"+"   operator_plus                       plus                  plus                  plus
"-"   operator_minus                      minus                 minus                 minus
"*"   operator_multiply                   multiply              multiply              multiply
"/"   operator_divide                     divide                divide                divide
"%"   operator_integerDivide              integerDivide         integerDivide         integerDivide
"//"  operator_remainder                  remainder             remainder             remainder
"**"  operator_power                      power                 power                 power
""    operator_abuttal                    concat                concat                concatRexx            should be ::abuttal everywhere
"||"  operator_concat                     concat                concat                concatRexx
" "   operator_concatBlank                concatBlank           concatBlank           concatBlank
"="   operator_equal                      equal                 equal                 equal
"\="  operator_notEqual                   notEqual              notEqual              notEqual
">"   operator_isGreaterThan              isGreaterThan         isGreaterThan         isGreaterThan
"\>"  operator_isBackslashGreaterThan     isLessOrEqual         isLessOrEqual         isLessOrEqual         should be ::isBackslashGreaterThan everywhere
"<"   operator_isLessThan                 isLessThan            isLessThan            isLessThan
"\<"  operator_isBackslashLessThan        isGreaterOrEqual      isGreaterOrEqual      isGreaterOrEqual      should be ::isBackslashLessThan everywhere
">="  operator_isGreaterOrEqual           isGreaterOrEqual      isGreaterOrEqual      isGreaterOrEqual
"<="  operator_isLessOrEqual              isLessOrEqual         isLessOrEqual         isLessOrEqual
"=="  operator_strictEqual                strictEqual           strictEqual           strictEqual
"\==" operator_strictNotEqual             strictNotEqual        strictNotEqual        strictNotEqual
">>"  operator_strictGreaterThan          strictGreaterThan     strictGreaterThan     strictGreaterThan
"\>>" operator_strictBackslashGreaterThan strictLessOrEqual     strictLessOrEqual     strictLessOrEqual     should be ::strictBackslashGreaterThan everywhere
"<<"  operator_strictLessThan             strictLessThan        strictLessThan        strictLessThan
"\<<" operator_strictBackslashLessThan    strictGreaterOrEqual  strictGreaterOrEqual  strictGreaterOrEqual  should be ::strictBackslashLessThan everywhere
">>=" operator_strictGreaterOrEqual       strictGreaterOrEqual  strictGreaterOrEqual  strictGreaterOrEqual
"<<=" operator_strictLessOrEqual          strictLessOrEqual     strictLessOrEqual     strictLessOrEqual
"<>"  operator_lessThanGreaterThan        notEqual              notEqual              notEqual              should be ::lessThanGreaterThan everywhere
"><"  operator_greaterThanLessThan        notEqual              notEqual              notEqual              should be ::greaterThanLessThan everywhere
"&"   operator_and                        andOp                 andOp                 andOp
"|"   operator_or                         orOp                  orOp                  orOp
"&&"  operator_xor                        xorOp                 xorOp                 xorOp
"\"   operator_not                        operatorNot           operatorNot           operatorNot
```


<!-- ======================================================================= -->
## 15.   Positional arguments
<!-- ======================================================================= -->

The correspondence between a caller's argument and a callee's argument is done using the argument's position.


<!-- ------------------------------- -->
### 15.1.   Argument list
<!-- ------------------------------- -->

Keep the trailing omitted arguments.

```REXX
    .array~of(10,20,30,,)~dimensions= -- [5] instead of [3]
```

This is consistent with the array literals:

```REXX
    v(1,2,) is the same as 1,2,
```


[03/04/2021]  
I just discovered that rexxref.pdf acknowledges this inconsistency:  
"If the array term has trailing commas, the returned array has a bigger size than what `.Array~of(…)` would have returned:".  
So for official ooRexx, that's normal to have this inconsistency.


[01/05/2018]  
The change above has an unexpected effect on the regression tests:

```
    base/bif: [SYNTAX 40.5] raised unexpectedly
    40.5 "Missing argument in invocation of XXX; argument 2 is required"
```

is raised instead of

```
    40.3 "Not enough arguments in invocation of XXX; minimum expected is 2."
```

--> [BuiltinFunctions.cpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/expression/BuiltinFunctions.cpp): function `expandArgs` updated to raise 40.3


<!-- ------------------------------- -->
### 15.2.   Array literals
<!-- ------------------------------- -->

Retrofit from ooRexx5 the parsing of an expression where the expression can be treated as a comma-separated list of subexpressions.  
For an empty vector, or a vector of one element, the routine v is still needed:

```REXX
    ()=     -- Syntax error: Incorrect expression detected at "("
    v()=    -- []
    (1)=    -- 1
    v(1)    -- [1]
```

Align implementation of forward arguments to keep the trailing omitted arguments

- official: `forward message "m" arguments ( (1,2,,) )`     -- pass (1,2)
- executor: `forward message "m" arguments ( (1,2,,) )`     -- pass (1,2,,)


<!-- ------------------------------- -->
### 15.3.   Trailing blocks
<!-- ------------------------------- -->

Added support for trailing blocks (similar to Groovy & Swift syntax for closures):

- `f{...}` is equivalent to `f({...})`
- `f(a1,a2,...){...}` is equivalent to `f(a1,a2,...,{...})`

Example:

```REXX
    10~times{call charout , arg(1)}  -- 12345678910
    4~upto(7){call charout , arg(1)} -- 4567
```


<!-- ======================================================================= -->
## 16.   Named arguments
<!-- ======================================================================= -->

The correspondence between a caller's argument and a callee's argument is done using the argument's name.


<!-- ------------------------------- -->
### 16.1.   Description
<!-- ------------------------------- -->

[Specification](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/docs/NamedArguments/NamedArguments-Spec.md)

Implemented.


The count of named arguments is passed with an additional C++ parameter.  

```
count=3, named_count=2
              +----+----+----+----+----+----+----+
              | P1 | P2 | P3 | N1 | V1 | N2 | V2 |
              +----+----+----+----+----+----+----+
```

`CPPCode::run` has only two cases to support: with or without named arguments.  
The named arguments are passed as an array: ptr and count.  
    `native_cpp_method(P1, P2, P3, array_ptr, array_count)`

```C++
void CPPCode::run(RexxActivity *activity, RexxMethod *method, RexxObject *receiver, RexxString *messageName,
    RexxObject **argPtr, size_t count, size_t named_count, ProtectedObject &result)
{
        RexxObject **named_argPtr = argPtr + count;
        ...
              // positional only
              case 2:
                result = (receiver->*((PCPPM2)methodEntry))(argPtr[0], argPtr[1]);
        ...
              // positional and named arguments
              case 2:
                result = (receiver->*((PCPPM2N)methodEntry))(argPtr[0], argPtr[1],
                                                            named_argPtr, named_count);
        ...
```


The callee can use the helper `NamedArguments.match` to collect the named arguments in a useful order.  
Example:

```C++
defineKernelMethod("UTF8PROC_TRANSFORM", TheUnicodeClassBehaviour, CPPM(Unicode::utf8proc_transform), 1, true);  // true ==> support named arguments


RexxObject *Unicode::utf8proc_transform(RexxString *string, RexxObject **named_arglist, size_t named_argcount)
{
    string = stringArgument(string, OREF_positional, ARG_ONE);

    // use strict named arg casefold = .false, lump= .false, nlf = 0, normalization = 0, stripCC = .false, stripIgnorable= .false, stripMark = .false, stripNA = .false
    NamedArguments expectedNamedArguments(8); // 8 named arguments
    expectedNamedArguments[0] = NamedArgument("CASEFOLD",      TheFalseObject); // default value = .false
    expectedNamedArguments[1] = NamedArgument("LUMP",          TheFalseObject); // default value = .false
    ...
    expectedNamedArguments.match(named_arglist, named_argcount, /*strict*/ true, /*extraAllowed*/ false);
    ssize_t casefold =      integerRange(expectedNamedArguments[0].value, 0, 1, Error_Logical_value_user_defined, "Transform: value of named argument \"casefold\" must be 0 or 1");
    ssize_t lump =          integerRange(expectedNamedArguments[1].value, 0, 1, Error_Logical_value_user_defined, "Transform: value of named argument \"lump\" must be 0 or 1");
    ...
```


All the native methods `A_COUNT` support named arguments.

Native methods not `A_COUNT` which support named arguments:
```
    TheObjectBehaviour        RexxObject::startWith
    TheObjectBehaviour        RexxObject::sendWith
    TheRoutineBehaviour       RoutineClass::callWithRexx
    TheRexxContextBehaviour   RexxContext::setArgs
    TheDirectoryBehaviour     RexxObject::unknownRexx
    TheStemBehaviour          RexxObject::unknownRexx
    TheIntegerBehaviour       RexxObject::unknownRexx
    TheNumberStringBehaviour  RexxObject::unknownRexx
```

<!-- ------------------------------- -->
### 16.2.   Remaining todo
<!-- ------------------------------- -->

`Message~new`  
add support for the named argument `NAMEDARGUMENTS`  
whose value `exprd` is a RexxDirectory.

```
>>-new(-target-,-messagename-+-------------------------------------------------------+-)--><
                             +-,-"Individual"--| Arguments |-------------------------+
                             +--+-------------------+--+--------------------------+--+
                                +-,-"Array"-,-expra-+  +-,-NAMEDARGUMENTS-:-exprd-+
```

`Message~namedArguments`  
to implement

Changes in ooRexx5 that I don't need to support until retrofitting:

```
    Message~send allows to pass arguments
    Message~sendWith: new method
    Message~start allows to pass arguments
    Message~startWith: new method
```

`StackFrame~namedArguments`  
to implement

Security manager `CALL`  
Add `NAMEDARGUMENTS`: a directory of the function named arguments to the information directory.

Security manager `METHOD`  
Add `NAMEDARGUMENTS`: a directory of the method named arguments to the information directory.

`RexxNativeActivation::callNativeRoutine`  
The named arguments are not passed to the native routine.


And of course the C++ API of ooRexx...


<!-- ======================================================================= -->
## 17.   Dynamic target when sending a message
<!-- ======================================================================= -->

<!-- ------------------------------- -->
### 17.1.   Description
<!-- ------------------------------- -->

Add support for dynamic target when sending messages.  
The target is calculated based on the initial target and the arguments values/types of the message.  
It's still a single-dispatch.  
The `~~` form of message is not impacted: it returns the object that received the message (the initial target), not the calculated target.


The forward instruction does not depend on the dynamic target calculation.  
If you need to forward using the dynamic target then do:

```REXX
    forward message "DYNAMICTARGET" continue
    forward to (result)
```


New method `.Object~dynamicTarget` which returns the target in function of the arguments:

```C++
    RexxObject *RexxObject::dynamicTargetRexx(RexxObject **arguments, size_t argCount, size_t named_argCount)
    {
        return this->dynamicTarget(arguments, argCount, named_argCount);
    }
```


<!-- ------------------------------- -->
### 17.2.   Default dynamic target
<!-- ------------------------------- -->

By default, the dynamic target is the receiver object.  
Native classes can override the virtual method dynamicTarget.  
For the moment, it's not possible to override this method with an ooRexx method.

Examples:

```REXX
    (1,2)~dynamicTarget=                       -- initial target: [ 1, 2]
    (1,2)~dynamicTarget("string")=             -- initial target: [ 1, 2]
    (1,2)~dynamicTarget("string", "teẌt")=     -- initial target: [ 1, 2]
```


<!-- ------------------------------- -->
### 17.3.   String dynamic target
<!-- ------------------------------- -->

The `RexxString` class overrides the virtual method `dynamicTarget`:

```C++
    RexxObject *RexxString::dynamicTarget(RexxObject **arguments, size_t count, size_t named_count)
    {
        if (hasRexxTextArguments(arguments, count, named_count))
        {
            RexxText *text = this->requestText();
            return text;
        }
        return this;
    }
```

Examples:

```REXX
    "Noel"~dynamicTarget=                       -- initial target: 'Noel'
    "Noel"~dynamicTarget("string")=             -- initial target: 'Noel'
    "Noel"~dynamicTarget("string", "teẌt")=     -- text counterpart of the initial target: T'Noel'  because "teẌt" is a RexxText
```


<!-- ======================================================================= -->
## 18.   Method search order
<!-- ======================================================================= -->

(ooRexx5 has been modified to support that)

Allow to modify the method search order from anywhere.  
Before, was possible only from methods of the target object.

```REXX
    .c1~new~m
    .c1~new~m:.c2 -- Now it's ok, interpreter modified to no longer raise:
                  -- Message search overrides can be used only from methods of the target object

    ::class c1 inherit c2
    ::method m
    say "c1::m"
    self~m:.c2

    ::class c2 mixinclass object
    ::method m
    say "c2::m"
```


<!-- ======================================================================= -->
## 19.   Routines search order
<!-- ======================================================================= -->

New entry `GLOBALROUTINES` in `.environment`, which gives access to `TheFunctionsDirectory`.

```C++
  kernel_public("GLOBALROUTINES", TheFunctionsDirectory, TheEnvironment); // give direct access to TheFunctionsDirectory
```

This is a directory of global routines that are made available everywhere, like the builtin functions.  
No need of ::requires directive to use them.

`TheFunctionsDirectory` is no longer supported in ooRexx5 (deprecated).


A global routine with the same name as a builtin function overrides this function.  
This is done by searching in TheFunctionsDirectory from

```C++
    RexxExpressionFunction::evaluate
    RexxInstructionCall::execute
    RexxInstructionCall::trap
```

when the target is a builtin function.  
If the call or function invocation uses a string literal, then the search in `TheFunctionsDirectory` is bypassed.

This new functionality is used to override the builtin function `XRANGE`, and make if compatible with ooRexx5.


Example of builtin function override:

```REXX
    call internal   -- override with internal routine
    call external   -- no override because the routine date is not global
    call global     -- override with global routine

    ::routine internal
        say date()                                    -- Internal date is 2 Jul 2021
        say "DATE"()                                  -- 2 Jul 2021
        return
        date: return "Internal date is " || "DATE"()

    ::routine external
        say date()                                    -- 2 Jul 2021
        say "DATE"()                                  -- 2 Jul 2021

    ::routine global
        .globalRoutines["DATE"] = .routines["DATE"]
        say date()                                    -- Global date is 2 Jul 2021
        say "DATE"()                                  -- 2 Jul 2021

    ::routine date
        return "Global date is " || "DATE"()
```

<!-- ======================================================================= -->
## 20.   Encoded strings
<!-- ======================================================================= -->

<!-- ------------------------------- -->
### 20.1.   Native integration
<!-- ------------------------------- -->

The support of the encoded strings is implemented in [trunk/interpreter/classes/TextClass.cpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/classes/TextClass.cpp).
    
Libraries:
- [trunk/interpreter/classes/support/m17n/uni-algo](https://github.com/jlfaucher/executor/tree/master/sandbox/jlf/trunk/interpreter/classes/support/m17n/uni-algo)
- [trunk/interpreter/classes/support/m17n/utf8proc](https://github.com/jlfaucher/executor/tree/master/sandbox/jlf/trunk/interpreter/classes/support/m17n/utf8proc)


99% of the integration is currently implemented by extension of these native ooRexx classes:

```
    String
    Text
    MutableBuffer
    Package
    Unicode (expose the services provided by the libraries)
````

New native methods:

```REXX
    .String~!setEncoding
    .String~!setText
    .MutableBuffer~!setEncoding
    .Package~!setEncoding
```

to store natively these informations.  
Currently I have a dual storage (managed by extension, and managed by these methods).  
In the end, only the native storage will remain.


```C++
class RexxString:
   // new attributes
   RexxObject *text;                   // The text counterpart or OREF_NULL
   RexxObject *encoding;               // The encoding or OREF_NULL.


class RexxMutableBufferClass:
   // new attribute
   RexxObject *encoding;               // The encoding or OREF_NULL.


class PackageClass:
   // new attribute
   RexxObject *encoding;               // The encoding or OREF_NULL.
```

Start native integration of RexxText in the interpreter.

```C++
   // methods
    RexxText *RexxInternalObject::textValue()
    RexxText *RexxObject::textValue()
    RexxText *RexxInternalObject::makeText()
    RexxText *RexxInternalObject::primitiveMakeText()
    RexxText *RexxObject::makeText()
    RexxText *RexxObject::requestText()

    // static methods
    static RexxText *nullText;
    static RexxText *newText(RexxString *s);
    static RexxText *newText(const char *s, size_t l);

    // functions
    inline RexxText *new_text(RexxString *s)
    inline RexxText *new_text(const char *s, size_t l)
    inline RexxText *new_text(const char *s)

    Metaclass RexxTextClass to mark the static field RexxText::nullText.
```


<!-- ------------------------------- -->
### 20.2.   `isASCII`
<!-- ------------------------------- -->

Add method `String~isASCII`

Add method `MutableBuffer~isASCII`  
Implementation more complex than for `String`, because mutable.  
Try to avoid to rescan the whole buffer, when possible.  
The native methods that modify the buffer are never scanning the buffer, they are just setting the boolean indicators `is_ASCII_checked` and `is_ASCII`.  
It's only the Rexx method `~isASCII` which scans the whole buffer, if needed.  
Impacted methods:

```C++
    append
    caselessChangeStr
    changeStr
    delete
    delWord
    insert
    overlay
    replaceAt
    setBufferSize
    space
    translate
```


<!-- ------------------------------- -->
### 20.3.   Encoded string evaluation
<!-- ------------------------------- -->

Automatic conversion of `String` literals to `RexxText` instances.  
This is managed in `RexxString::evaluate`.  
Rules:

```REXX
    if string~isASCII then value = string                               -- R1 don't convert to RexxText if the string literal is ASCII (here, NO test of encoding, just testing the bytes)
    else if .context~package~encoding~isByte then value = string        -- R2 don't convert to RexxText if the encoding of its definition package is the Byte_Encoding or a subclass of it (legacy package).
    -- else if string~isCompatibleWithByteString then value = string    -- R3 (no longer applied) don't convert to RexxText if the string literal is compatible with a Byte string.
    else value = string~text                                            -- R4 convert to RexxText
```

The string BIFs become polymorphic on `RexxString`/`RexxText`.  
If at least one positional argument is a `RexxText` then the string BIFs forwards to `RexxText`,  
otherwise the string BIFs forward to `RexxString`.


The `String` messages become polymorphic on `RexxString`/`RexxText`.  
If at least one positional argument is a `RexxText`   
then the String message is sent to the `RexxText` counterpart of the `String` instance,  
otherwise the `String` message is sent to the String instance.  
This is implemented with a dynamic target.


<!-- ======================================================================= -->
## 21.   Collection
<!-- ======================================================================= -->

Retrofit the method MapCollection~of from ooRexx5:

```REXX
    aMapCollection~of( (key1, value1), (key2, value2), ...)
```

while keeping my own implementation that was available for .Directory:

```REXX
    aMapCollection~of(key1, value1, key2, value2, ..., n1:v1, n2:v2, ...)
```

The key-value where the key is compatible with a named  argument can be passed as named argument.  
The key-value where the key is not compatible with a named argument can be passed as a pair of positional arguments.

ooRexx5 wants each key-value to be an array (key, value).  
I prefer to pass each key-value as 2 positional arguments, or as one named argument.

I make my implementation compatible with ooRexx5:  
If the first argument is an array then assume it's the ooRexx5 way, otherwise it's mine.

Examples:

```REXX
    .stem~of("un", 1, "deux", 2, trois:3, quatre:4)=
        a Stem (4 items)
        'deux'   :  2
        'QUATRE' :  4
        'TROIS'  :  3
        'un'     :  1

    .relation~of("UN", 10, "DEUX", 20, un:100, deux:200, quatre:400)=
        a Relation (5 items)
        'DEUX'   : [ 20, 200]
        'QUATRE' :  400
        'UN'     : [ 10, 100]
```


<!-- ======================================================================= -->
## 22.   Performance
<!-- ======================================================================= -->

<!-- ------------------------------- -->
### 22.1.   New option `NOMACROSPACE`
<!-- ------------------------------- -->

Each call to an external function (like `SysXxx` functions) triggers a communication with the `rxapi` server through a socket (`QUERY_MACRO`, to test is the function is defined in the macrospace).  
This has a major impact on performance !  
Example with `.yield[]` which calls `SysGetTid()` or `SysQueryProcess("TID")` at each call:

```REXX
    10000 calls to .yield[] with macrospace enabled  : 2.1312
    10000 calls to .yield[] with macrospace disabled : 0.4531
```

(JLF 2012 mar 23: `.yield[]` no longer depends on `SysXXX` functions, now depends on `.threadLocal` --> faster)  
([samples/benchmark/doers-benchmark-output.txt](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/samples/benchmark/doers-benchmark.output.txt))

The following options control the use of macrospace:

```REXX
    ::options MACROSPACE
    ::options NOMACROSPACE
    options "MACROSPACE"
    options "NOMACROSPACE"
```

By default, the macrospace is queried, according to the rules described in rexxref section "7.2.1 Search order".  
When using the option `NOMACROSPACE`, the macrospace is not queried.


<!-- ------------------------------- -->
### 22.2.   Optimization of `.context`
<!-- ------------------------------- -->

Changed the search order in `RexxDotVariable::evaluate`:  
Try first `context->rexxVariable`: `.methods`, `.routines`, `.rs`, `.line`, `.context`  
then try `context->resolveDotVariable`:  `getSourceObject()->findClass(name)`

```C++
    findInstalledClass(internalName)
    findPublicClass(internalName)
    ActivityManager::getLocalEnvironment(internalName) controlled by security manager
    TheEnvironment->at(internalName)                   controlled by security manager
```

The use of `.context` becomes prominent with coactivities, the goal of this change is to find the value of `.context` as fast as possible.

Tested from ooRexxShell where more than 700 classes are loaded:

```REXX
    do i=1 to 100000; v=.context ; end
        5 runs: 0.032 0.047 0.078 0.063 0.078

    .environment~my.var=1
    do i=1 to 100000; v=.my.var ; end
        5 runs: 0.703 0.625 0.593 0.594 0.672
```


<!-- ------------------------------- -->
### 22.3.   Optimization of `SysActivity::yield`
<!-- ------------------------------- -->

[interpreter\platform\windows\SysActivity.hpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/platform/windows/SysActivity.hpp)  
[interpreter\platform\unix\SysActivity.hpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/platform/unix/SysActivity.hpp)

Moved `SysActivity::yield` to the .cpp file to reduce the amount of recompilation when experimenting various settings.  
For the moment, `sleep(0)` under Windows works fine for me, and is quit faster than sleep(1) used in standard ooRexx.

```REXX
    sleep(0): rexx coactivity-stress.rex 100 --> global duration=1.671, duration per consumer=0.01671
    sleep(1): rexx coactivity-stress.rex 100 --> global duration=24.625, duration per consumer=0.24625
```


<!-- ------------------------------- -->
### 22.4.   Performance notes
<!-- ------------------------------- -->

Apply fix for SVN bug #1402  
There is a subtle interaction between native and rexx activations when  
native calls make calls to APIs that in turn invoke Rexx code.  When conditions  
occur and the stack is being unwound, the ApiContext destructors will release  
the kernel access, which can leave us with no active Activity.

While retrofiting this bug fix, I discover that the interpreter is client of his external API:

[StreamNative.cpp](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp)

```C++
    RexxMethod3(int, stream_lineout, CSELF, streamPtr, OPTIONAL_RexxStringObject, string, OPTIONAL_int64_t, position)
    int StreamInfo::lineout(RexxStringObject data, bool _setPosition, int64_t position)
    ...
        const char *stringData = context->StringData(data);
        size_t length = context->StringLength(data);
    ...
```

These calls seems rather costly in term of performance.  
Any API entry starts with

```C++
    ApiContext context(c);
    which calls:
        activity->enterCurrentThread();
            requestAccess();
```

On return from the API entry, the destructors calls:

```C++
    activity->exitCurrentThread();
        releaseAccess()
```


<!-- ======================================================================= -->
## 23.   Monitoring
<!-- ======================================================================= -->

Added counters for monitoring interpreter activities:

- `.yieldCounter`:              how many times `SysActivity::yield` has been called since the begining
- `.addWaitingActivityCounter`: how many times `ActivityManager::addWaitingActivity` has been called since the begining
- `.relinquishCounter`:         how many times `ActivityManager::relinquish` has been called since the begining
- `.requestAccessCounter`:      how many times `RexxActivity::requestAccess` has been called since the begining
- `.getAPIManagerCounter`:      how many times `LocalAPIContext::getAPIManager` has been called since the begining

See [samples/concurrency/coactivity-stress.rex](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/samples/concurrency/coactivity-stress.rex)  
See [samples/concurrency/factorials_generators.rex](https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/samples/concurrency/factorials_generators.rex)


<!-- ======================================================================= -->
## 24.   Security manager: optimization
<!-- ======================================================================= -->

<!-- ------------------------------- -->
### 24.1.   Optional methods
<!-- ------------------------------- -->

It's no longer mandatory to implement all the methods of a security manager.  
When a check is not needed, just don't provide the corresponding method.  
That can reduce drastically the number of security checkpoint messages sent by the interpreter.


<!-- ------------------------------- -->
### 24.2.   Method unknownDisabled
<!-- ------------------------------- -->

This is an optimization available only with Executor.  
If the method `unknownDisabled` exists, then the method `unknown` of the security manager is disabled (never called).

When a security manager is registered, the official ooRexx interpreter raises an error if the following messages are not understood:  
`call`, `command`, `environment`, `local`, `method`, `requires`, `stream`.  
So no choice with official ooRexx, either the corresponding method or the method `unknown` must be defined.

Optimizations with Executor:  
When the security manager is registered, the methods `call`, `command`, `environment`, `local`, `method`, `requires`, `stream` are searched on the security manager.  
If not found, and `unknown` is not defined or `unknownDisabled` is defined then the corresponding messages are flagged to be never sent.  
The test of existence is done only when the security manager is registered, not at each checkpoint.


<!-- ------------------------------- -->
### 24.3.   Two messages for each check
<!-- ------------------------------- -->

Each access to the global `.environment` will raise two messages sent to the security manager:  
`local` and then `environment`.

Messages sent for nothing, since I return 0 to indicate that the program is authorized to perform the action.  
if `unknownDisabled` is defined:

```REXX
    do 1000000;x=.stdout;end   -- 0.86 sec with ooRexx5, 0.08 sec with Executor (10x faster)
    do 1000000;x=.context;end  -- 1.64 sec with ooRexx5, 0.06 sec with Executor (27x faster, special optimization)
    do 1000000;x=1;end         -- 0.03 sec (here, the security manager is not used)
```

if `unknownDisabled` is not defined:

```REXX
    do 1000000;x=.stdout;end   -- 0.86 sec with ooRexx5, 0.75 sec with Executor (equivalent)
    do 1000000;x=.context;end  -- 1.66 sec with ooRexx5, 0.07 sec with Executor (23x faster, special optimization)
    do 1000000;x=1;end         -- 0.03 sec (here, the security manager is not used)
```


<!-- ======================================================================= -->
## 25.   Compatibility with classic rexx
<!-- ======================================================================= -->

Add support for variables `#` `@` `$` `¢`.

Add support for assignment `V=`   -- assign ""

Add support for instruction `UPPER`:
- same syntax as instruction `DROP`
- translate to upper case the value of each variable

The Roseta Code script "`Check-that-file-exists/check-that-file-exists-2.rexx`" uses `~` as a negator character.  
Regina supports the following characters as negators:

```
    \ Backslash (ANSI Standard)
    ^ Caret
    ~ Tilde
    ¬ Logical Not
```

Add support for `^` and `¬`.  
Not possible to use `~` as a negator character.

```REXX
^0=     -- 1
^1=     -- 0
¬0=     -- 1
¬1=     -- 0
^¬^0=   -- 1
^¬^¬0=  -- 0
```

The operators `/=` and `/==` are supported in TSO/E REXX as alternatives to `\=` and `\==`, respectively.  
The Roseta Code script "`Determine-if-a-string-is-numeric/determine-if-a-string-is-numeric.rexx`" uses `/==`.  
Add support for `/=` and `/==`

```
"a" /= " a " =      -- 0
"a" /== " a " =     -- 1
"a" /== "a" =       -- 0
```


<!-- ======================================================================= -->
## 26.   oodialog
<!-- ======================================================================= -->

This is a very old version of ooDialog.

Added support for wide-chars in oodialog.  
Currently, the `"A"` Windows API is called, and the conversion occurs there, inside Windows, based on the current locale.  
When compiling ooDialog with wide chars UTF-16, the `"W"` API is called directly, making the dialogs Unicode-enabled.  

GTK+ uses UTF-8 internally.  
Most of  the Unix-style operating systems use UTF-8 internally.  
So it's natural to use multi-byte chars in ooRexx instead of wide chars, and to provide string services which supports UTF-8.  

But the case of ooDialog is different:  
This is a Windows-only subsystem, and for better integration with Windows, it must use UTF-16 chars internally.  
The conversion to UTF-16 is under the responsability of ooDialog, which lets support code pages that are different from the system's default code page.  
Typically, we can pass UTF-8 string to ooDialog which convert them to UTF-16 strings before calling the Windows `"W"` API.


<!-- ======================================================================= -->
## 27.   Thoughts about lazy evaluation of arguments
<!-- ======================================================================= -->

Not yet implemented.


Some articles:  
[https://dlang.org/articles/lazy-evaluation.html](https://dlang.org/articles/lazy-evaluation.html)  
[https://colinfay.me/lazyeval/](https://colinfay.me/lazyeval/)

Goal:

```REXX
    x=5; say (x<>0)~?(1/x, "infinity")      -- 0.2
    x=0; say (x<>0)~?(1/x, "infinity")      -- "infinity", instead of the error "divisor must not be zero"
    a=1; b=2; call swap a, b; say a b       -- 2 1
```

When calling a routine, the target is evaluated and found.  
The target indicates if the arguments must be evaluated or not.  
This is independant from any instruction 'use arg' on the target side.  
If the arguments must be evaluated then it's the current implementation: pass an array of evaluated expressions.  
Otherwise pass an array of not-evaluated expressions.  
Probably an array of `LazyRexxExpression` which is a wrapper holding the expression and the context for the evaluation (a `RexxActivation`).

Signature for evaluation:

```C++
    virtual RexxObject  *evaluate(RexxActivation *, RexxExpressionStack *)
```

Concrete implementations (Executor):

```C++
    RexxNumberString::evaluate          stack->push(this); return this;
    RexxInteger::evaluate               stack->push(this); return this;
    RexxUnaryOperator::evaluate         stack->prefixResult(result); return result;
    RexxBinaryOperator::evaluate        stack->operatorResult(result); return result;
    RexxExpressionMessage::evaluate     loop { this->arguments[i+1]->evaluate(context, stack); } stack->send(this->messageName, argcount, namedArgcount, result); return result;
    RexxStemVariable::evaluate          value = context->getLocalStem(this->stem, this->index); stack->push(value); return value;
    RexxCompoundVariable::evaluate      value = context->evaluateLocalCompoundVariable(stemName, index, &tails[0], tailCount);stack->push(value); return value;
    RexxParseVariable::evaluate         variable = context->getLocalVariable(variableName, index); value = variable->getVariableValue(); stack->push(value); return value;
    RexxString::evaluate                stack->push(this); return this;
    RexxInternalObject::evaluate        return OREF_NULL
    RexxSourceLiteral::evaluate         value = new RexxBlock(this, rexxContext); stack->push(value); return value;
    RexxExpressionList::evaluate        result = new_array(expressionCount); loop { expr = expressions[i]; value = expr->evaluate(context, stack); result->put(value, i + 1); } stack->push(result); return result;
    RexxExpressionFunction::evaluate    loop { this->arguments[i]->evaluate(context, stack); call internal or builtin or external...; stack->push(result); return result;
    RexxDotVariable::evaluate           result = context->rexxVariable(this->variableName); stack->push(result); return result;
    RexxExpressionLogical::evaluate     loop { value = expressions[i]->evaluate(context, stack); return true or false }
```

Example of lazy evaluation:

```REXX
    -- context = theRexxActivation1
    a=1                 -- theRexxParseVariable1(variableName="A", index=6)
                        --     when evaluated in the context theRexxActivation1, it's theRexxVariable1(variable_name="A", variableValue=1, creator=theRexxActivation1)
    b=2                 -- theRexxParseVariable2(variableName="B", index=7)
                        --     when evaluated in the context theRexxActivation1, it's theRexxVariable2(variable_name="B", variableValue=2, creator=theRexxActivation1)
    call swap a, -      -- pass LazyRexxExpression~new(theRexxActivation1, theRexxParseVariable1)
              b         -- pass LazyRexxExpression~new(theRexxActivation1, theRexxParseVariable2)
    say a               -- 2
    say b               -- 1


    ::routine swap lazyargs             -- The LAZYARGS option indicates that the arguments must not be evaluated on call
        -- context = RexxActivation2    -- The callee's context is different from the caller's context
        use strict arg x, y             -- x = theLazyRexxExpression1(theRexxActivation1, theRexxParseVariable1)
                                        -- y = theLazyRexxExpression2(theRexxActivation1, theRexxParseVariable2)
                                        -- If an argument is a LazyRexxExpression whose expression is a subclass of RexxVariableBase supporting assignment
                                        -- (RexxStemVariable, RexxCompoundVariable, RexxParseVariable, but not RexxDotVariable)
                                        -- then create an alias variable.
                                        -- [2021 Jul 7] Better to declare explictly that a special retriever must be used.
                                        --              The syntax would be the same as variable reference, but on callee side only.
                                        --              use strict arg >x, >y
        tmp = x                         -- First evaluation of x, the value 1 is cached on theLazyRexxExpression1
        x = y                           -- First evaluation of y, the value 2 is cached on theLazyRexxExpression2
                                        -- The assignment 'x =' is delegated to theRexxParseVariable1
        y = x                           -- Retrieve the cached value 2 stored on theLazyRexxExpression1
                                        -- The assignment 'y =' is delegated to theRexxParseVariable1
```


To investigate:
- `expose var`  
  `use arg >var`  
  Will it work with `LazyRexxExpression` ?  
  ooRexx5 raises `Error 98.995:  Unable to reference variable "VAR"; it must be an uninitialized local variable`.  
  
- `use arg >var`  
  `drop var`  
  Will it work with LazyRexxExpression ?  
  ooRexx5 drops the value of the referenced variable.  
  
- The reference operator supports stems but doesn't support compound symbols.  
  Will compound symbols be supported with `LazyRexxExpression` ?


<!-- ======================================================================= -->
## 28.   Thoughts about tail recursion
<!-- ======================================================================= -->

Not yet implemented.

See if it's possible to modify the implementation of FORWARD to reduce the
comsumption of stack frames.  
Should be possible when the option CONTINUE is not used.  
Could be used to emulate tail recursion.
  
Under MacOs, last value before stack overflow when calculating the factorial:


<!-- ------------------------------- -->
### 28.1.   Internal procedure
<!-- ------------------------------- -->

```REXX
x86_64  Executor: 1056      ooRexx5: 17441 (yes! and then segmentation fault)
arm64   Executor: 3568      ooRexx5: 20073 and then seg fault
    use arg n
    say factorial(n)
    return
    factorial:
    use arg n
    if n==0 then return 1
    else return n * factorial(n-1)
``` 


<!-- ------------------------------- -->
### 28.2.   Routine, recursion by name
<!-- ------------------------------- -->

```REXX
x86_64  Executor:  736      ooRexx5: 793
arm64   Executor: 3568      ooRexx5: 15230
    use arg n
    say factorial(n)
    return
    ::routine factorial
    use arg n
    if n==0 then return 1
    else return n * factorial(n-1)
```


<!-- ------------------------------- -->
### 28.3.   Routine, recursion by calling the executable
<!-- ------------------------------- -->

```REXX
x86_64  Executor:  487      ooRexx5: 511
arm64   Executor: 2214      ooRexx5: 10153
    use arg n
    say factorial(n)
    return
    ::routine factorial
    use arg n
    if n==0 then return 1
    else return n * .context~executable~call(n-1)
```


<!-- ------------------------------- -->
### 28.4.   Block, recursion by calling the executable with ~call
<!-- ------------------------------- -->

```REXX
x86_64   484
arm64   2211
    {use arg n; if n==0 then return 1; else return n * .context~executable~call(n-1) }~call(484)=
```


<!-- ------------------------------- -->
### 28.5.   Block, recursion by calling the executable with ~()
<!-- ------------------------------- -->

```REXX
x86_64  197
arm64   832
    {use arg n; if n==0 then return 1; else return n * .context~executable~(n-1) }~(197)=
```

I would like to support the same limit 484 when using the doer method ~().

```REXX
    ::class "Doer" mixinclass Object public inherit DoerFactory
    ::method "~()" unguarded
        forward message "do"
    ::class "RoutineDoer" mixinclass Object public inherit Doer
    ::method do unguarded
        forward message "call"
```
