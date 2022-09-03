::extension String inherit LogicalExtension

--::options trace i
::requires "extension/doers.cls"

/*
When passing a Doer, the evaluation is delayed
num=0; if(num==0, "INF", {expose num; 100/num})=        -- 'INF'
num=0; (num==0)~ifTrue("INF", {expose num; 100/num})=   -- 'INF'

When not passing a Doer, the evaluation is immediate
num=0; if(num==0, "INF", 100/num)=          -- Arithmetic overflow; divisor must not be zero
num=0; (num==0)~ifTrue("INF", 100/num)=     -- Arithmetic overflow; divisor must not be zero

Note : I would like a more concise expression, like :
num=0; if(num==0, "INF", {100/num})=                              -- 'INF'
-->
This implies :
- a block without ::<tag> is a closure (implicit closure).
- all the captured variables are implicitely exposed, no need to expose them.
  but, if you expose explicitely some variables, then your decision is respected : no implicit exposition.

If you don't need to return a value, this alternative notation is possible
num=0; (num==0)~~ifTrue{say "zero"}~ifFalse{say "not zero"}
*/

-- Should find a better name...
::class "LogicalExtension" mixinclass Object public

-- Compatibility with ooRexx 5
::method "?"
    forward message "ifTrue"

::method "ifTrue" unguarded
    use arg whenTrue, whenFalse
    if \ self~dataType("O") then raise syntax 34.901 array(self)
    if arg() > 2 then raise syntax 93.902 array(2)
    whenTrueSpecified = arg(1, "e") -- whenTrue explicitely passed ?
    whenFalseSpecified = arg(2, "e") -- whenFalse explicitely passed ?
    if self then call eval whenTrue, whenTrueSpecified
            else call eval whenFalse, whenFalseSpecified
    if var("result") then return result

::method "ifFalse" unguarded
    use arg whenFalse, whenTrue
    if \ self~dataType("O") then raise syntax 34.901 array(self)
    if arg() > 2 then raise syntax 93.902 array(2)
    whenFalseSpecified = arg(1, "e") -- whenFalse explicitely passed ?
    whenTrueSpecified = arg(2, "e") -- whenTrue explicitely passed ?
    if self then call eval whenTrue, whenTrueSpecified
            else call eval whenFalse, whenFalseSpecified
    if var("result") then return result

::routine eval
    use arg expression, expressionSpecified
    if \ expressionSpecified then return
    -- The test \ expression~needsObject lets eliminate the StringDoers and the MethodDoers
    if expression~isA(.doer), \ expression~needsObject then do
        doer = expression~doer
        doer~()
        if var("result") then return result
    end
    else return expression

::routine if public
    use strict arg logical, whenTrue, whenFalse
    logical~ifTrue(whenTrue, whenFalse)
    if var("result") then return result
