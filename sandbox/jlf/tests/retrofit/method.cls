/*
Keep this script compatible with ooRexx5!
The file 'method.output.reference.txt' is generated with ooRexx5.
*/

say "----------"
say "method.cls"
say "----------"
say


---------
-- Object
---------

.local~expression = ".Object"

    call sayMethodProperties "class method",    "new",         .object~instanceMethod("new")
    call sayMethodProperties "instance method", "superclass",  .object~instanceMethod("superclass")
    call sayMethodProperties "instance method", "objectName=", .object~instanceMethod("objectName=")
    call sayMethodProperties "instance method", "objectName",  .object~instanceMethod("objectName")

.local~expression = ".Object~new"

    anObject = .Object~new
    call sayMethodProperties "instance method", "isInstanceOf", anObject~instanceMethod("isInstanceOf")
    call sayMethodProperties "instance method", "objectName=",  anObject~instanceMethod("objectName=")
    call sayMethodProperties "instance method", "objectName",   anObject~instanceMethod("objectName")


---------
-- Stream
---------

.local~expression = ".Stream"

    call sayMethodProperties "class method",    "new",         .stream~instanceMethod("new")

.local~expression = ".Stream~new('stream')"

    aStream = .stream~new("stream")
    call sayMethodProperties "instance method", "position",  aStream~instanceMethod("position") -- defined in StreamClasses.orx: EXTERNAL 'LIBRARY REXX stream_position'
    call sayMethodProperties "instance method", "command",  aStream~instanceMethod("command") -- defined in StreamClasses.orx


---------------------------------
-- User class -  Class attributes
---------------------------------

.local~expression = ".myClass"
say .local~expression

    signal on syntax name privateClassAttributeError
    say .myClass~privateAttribute
    after_privateClassAttributeError:

    say .myClass~packageAttribute

    say .myClass~publicAttribute

    say
    .myClass~sayAttributeProperties("abstractAttribute")
    .myClass~sayAttributeProperties("privateAttribute")
    .myClass~sayAttributeProperties("packageAttribute")
    .myClass~sayAttributeProperties("publicAttribute")


-----------------------------
-- User class - Class methods
-----------------------------

.local~expression = ".myClass"
say .local~expression

    signal on syntax name privateClassMethodError
    say .myClass~privateMethod
    after_privateClassMethodError:

    say .myClass~packageMethod

    say .myClass~publicMethod

    say
    .myClass~sayMethodProperties("constant")
    .myClass~sayMethodProperties("abstractMethod")
    .myClass~sayMethodProperties("privateMethod")
    .myClass~sayMethodProperties("packageMethod")
    .myClass~sayMethodProperties("publicMethod")


-----------------------------------
-- User class - Instance attributes
-----------------------------------

.local~expression = ".myClass~new"
say .local~expression

    myInstance = .myClass~new

    signal on syntax name privateInstanceAttributeError
    say myInstance~privateAttribute
    after_privateInstanceAttributeError:

    say myInstance~packageAttribute

    say myInstance~publicAttribute

    say
    myInstance~sayAttributeProperties("abstractAttribute")
    myInstance~sayAttributeProperties("privateAttribute")
    myInstance~sayAttributeProperties("packageAttribute")
    myInstance~sayAttributeProperties("publicAttribute")

--------------------------------
-- User class - Instance methods
--------------------------------

.local~expression = ".myClass~new"
say .local~expression

    myInstance = .myClass~new

    signal on syntax name privateInstanceMethodError
    say myInstance~privateMethod
    after_privateInstanceMethodError:

    say myInstance~packageMethod

    say myInstance~publicMethod

    say
    myInstance~sayMethodProperties("constant")
    myInstance~sayMethodProperties("abstractMethod")
    myInstance~sayMethodProperties("privateMethod")
    myInstance~sayMethodProperties("packageMethod")
    myInstance~sayMethodProperties("publicMethod")


say
return


--------------
-- Trap errors
--------------

privateClassAttributeError:
    say "privateClassAttributeError"
    call sayCondition condition("O")
    signal after_privateClassAttributeError

privateClassMethodError:
    say "privateClassMethodError"
    call sayCondition condition("O")
    signal after_privateClassMethodError

privateInstanceAttributeError:
    say "privateInstanceAttributeError"
    call sayCondition condition("O")
    signal after_privateInstanceAttributeError

privateInstanceMethodError:
    say "privateInstanceMethodError"
    call sayCondition condition("O")
    signal after_privateInstanceMethodError


--------------------------------------------------------------------------------
::class myClass public
--------------------------------------------------------------------------------

::constant constant "constant"


-------------------
-- Class attributes
-------------------

::attribute abstractAttribute abstract class
::attribute privateAttribute private class
::attribute packageAttribute package class
::attribute publicAttribute public class

----------------
-- Class methods
----------------

::method init class
    self~privateAttribute = "private class attribute"
    self~packageAttribute = "package class attribute"
    self~publicAttribute =  "public class attribute"

::method abstractMethod abstract class

::method privateMethod private class
    return "private class method"

::method packageMethod package class
    return "package class method"

::method publicMethod public class
    return "public class method"

::method sayAttributeProperties public class
    use strict arg attributeName
    self~sayMethodProperties(attributeName"=")
    self~sayMethodProperties(attributeName)

::method sayMethodProperties public class
    use strict arg methodName
    method = self~instanceMethod(methodName)
    call sayMethodProperties "class method", methodName, method


----------------------
-- Instance attributes
----------------------

::attribute abstractAttribute abstract
::attribute privateAttribute private
::attribute packageAttribute package
::attribute publicAttribute public

-------------------
-- Instance methods
-------------------

::method init
    self~privateAttribute = "private instance attribute"
    self~packageAttribute = "package instance attribute"
    self~publicAttribute =  "public instance attribute"

::method abstractMethod abstract

::method privateMethod private
    return "private instance method"

::method packageMethod package
    return "package instance method"

::method publicMethod public
    return "public instance method"

::method sayAttributeProperties public
    use strict arg attributeName
    self~sayMethodProperties(attributeName"=")
    self~sayMethodProperties(attributeName)

::method sayMethodProperties public
    use strict arg methodName
    method = self~instanceMethod(methodName)
    call sayMethodProperties "instance method", methodName, method


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

::routine quoted
    return "'" || arg(1) || "'"


::routine sayMethodProperties public
    use strict arg level, methodName, method
    say .local~expression
    say level quoted(methodName) "~isAbstract ="   method~isAbstract
    say level quoted(methodName) "~isAttribute ="  method~isAttribute
    say level quoted(methodName) "~isConstant ="   method~isConstant
    say level quoted(methodName) "~isGuarded ="    method~isGuarded
    say level quoted(methodName) "~isPackage ="    method~isPackage
    say level quoted(methodName) "~isPrivate ="    method~isPrivate
    say level quoted(methodName) "~isProtected ="  method~isProtected
 -- say level quoted(methodName) "~isPublic ="     method~isPublic
    package = method~package
    if package~isNil then packageName = "<no package>"
                     else packageName = package~name
    packageName = .file~new(packageName)~name
    say level quoted(methodName) "~package ="      packageName
    say level quoted(methodName) "~scope ="        method~scope~id
    say level quoted(methodName) "~source ="       method~source~items "source lines"
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
