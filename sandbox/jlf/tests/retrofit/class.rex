/*
Keep this script compatible with ooRexx5!
The file 'class.output.reference.txt' is generated with ooRexx5.
*/

if interpreter_extended() then do
    .context~package~loadPackage("extension/rexxinfo.cls")
end


/*
Known problem:
With Executor, The REXX Package has no class after RESTORINGIMAGE.
Before SAVINGIMAGE, it has 59 classes.
*/
say "Classes of The REXX Package:"
call sayCollection .rexxinfo~package~classes, /*indexWidth*/ 30, /*sort*/ .true
say


-----------------
-- Abstract class
-----------------

-- Native classes
call sayClassProperties .object
call sayClassProperties .class

-- Rexx classes included in rexx.img
call sayClassProperties .collection
call sayClassProperties .monitor
call sayClassProperties .stream

-- User defined classes
call sayClassProperties .abstractClass
call sayClassProperties .concreteClass
call sayClassProperties .mixinclass


-----------------
-- Abstract class
-----------------

say .abstractClass~publicAttribute
say .abstractClass~publicMethod

signal on syntax name abstractClassNewError
myInstance = .abstractClass~new
after_abstractClassNewError:


-----------------
-- Concrete class
-----------------

say .concreteClass~publicAttribute
say .concreteClass~publicMethod

myInstance = .concreteClass~new
say myInstance~publicAttribute
say myInstance~publicMethod

say
return


--------------
-- Trap errors
--------------

abstractClassNewError:
    say "abstractClassNewError"
    call sayCondition condition("O")
    signal after_abstractClassNewError


--------------------------------------------------------------------------------
::class "abstractClass" abstract -- ooRexx5 new option abstract
--------------------------------------------------------------------------------

::attribute publicAttribute public class

::method init class
    self~publicAttribute =  "public class attribute"

::method publicMethod public class
    return "public class method"

::attribute publicAttribute public

::method init
    self~publicAttribute =  "public instance attribute"

::method publicMethod public
    return "public instance method"


--------------------------------------------------------------------------------
::class "concreteClass" subclass "abstractClass"
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
::class "mixinclass" mixinclass Object
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

::routine sayClassProperties
    use strict arg class
    package = class~package
    if package~isNil then packageName = "<no package>"
                     else packageName = package~name
    packageName = .file~new(packageName)~name
    say class~id "~package =" packageName
    say class~id "~baseClass =" class~baseClass~id
    say class~id "~metaClass =" class~metaClass~id
    say class~id "~isAbstract =" class~isAbstract
    say class~id "~isMetaClass =" class~isMetaClass
    say class~id "~queryMixinClass =" class~queryMixinClass
    say


::routine sayCondition public
    use strict arg condition
    if condition~isNil then return

    -- just the package name and extension, not the full path
    package = condition~package
    if package~isNil then packageName = "<no package>"
                     else packageName = .file~new(condition~package~name)~name
    .error~say("    Error" condition~rc "running" packageName "line" condition~position":" condition~errortext)
    .error~say("    Error" condition~code":" condition~message)


-- Don't use rgf_util2 because the display in Executor is different from that in ooRexx5
::routine sayCollection
    use strict arg collection, indexWidth, sort
    indexes = collection~allIndexes
    if sort then indexes = indexes~sort

    -- Don't display collection~defaultName because of "a Directory" versus "a StringTable"
    -- say collection~defaultName "("collection~items "items)"
    say collection~items "items"

    do index over indexes
        say index~left(indexWidth) ":" collection~at(index)
    end


::routine interpreter_extended public
    -- In Executor
    --     The tokenizer has been modified to split a symbol of the form <number><after number> in two distinct tokens.
    --     0a is the number 0 followed by the symbol a. If a=0 then 0a is (0 "" 0) = "00"
    -- In Official ooRexx, 0a is parsed as "0A" and is not impacted by the value of the variable a.
    a = 0
    return 0a == "00"
