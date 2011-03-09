/*

This file illustrates the problems I meet with current interpreter.

In RexxObject::run, there is this test :  
    if (!isOfClass(Method, methobj))
and the instance of MyMethod is not recognized as a method...

The fallback is
        methobj = RexxMethod::newMethodObject(OREF_RUN, (RexxObject *)methobj, IntegerOne, OREF_NULL);
i.e. create a method "run", trying to convert methobj to an array or to a string.

Same problem with enhanced methods.

*/

--------------------------------------------------------------------------

say
say "case 1"
say '-- here, my instance is converted (again) to an array.' 
say '-- You can see that with a debugger.'
do v over .MyArray~of(1,2,3)
    say v
end

--------------------------------------------------------------------------

say
say "case 2"
m = .MyMethod~new("", 'say "hello" self')
say '-- Next line works because I added a method makeArray to MyMethod,'
say '-- which will return the source, which will be parsed again.' 
say '-- But this is a poor fallback when you have already a Method in your hand !'
.MyString~new("john")~run(m) 

--------------------------------------------------------------------------

say
say "case 3"
methods=.StringDoer~methods(.nil)
say '-- List the methods of the mixin :' 
say '-- I wanted to verify that I can pass them to .Method~enhance'
say '-- Answer : yes, I can pass them, BUT the resulting enhanced instance'
say '-- will be rejected by the interpreter.'
do while methods~available
    say methods~index
    methods~next
end

--------------------------------------------------------------------------

say
say "case 4"
r = .ExtendedRoutine~new("", "say hello arg(1)")
say r
doer = r~doer
say doer
doer~do("John")

--------------------------------------------------------------------------

say
say "case 5"
m = .ExtendedMethod~new("", 'say "hello" self')
say m
s = .ExtendedString~new("john")
say s
say s~class
say "-- s~run(m) -- private !"

--------------------------------------------------------------------------

say
say "case 6"
doer = m~doer
say doer
say doer~class
say "-- doer~do(s) -- not accepted by interpreter because doer is an ExtendedMethod..."

--------------------------------------------------------------------------

say
say "case 7"
s = .ExtendedString~new('::method say "hello" self')
doer = s~doer
say doer
say doer~class
say '-- doer~do("john") -- Object "a Method" does not understand message "DO"'

--------------------------------------------------------------------------

say
say "case 8"
-- An enhanced method is not accepted by the interpreter !
m = .Method~enhanced(.MethodDoer~methods, "", 'say "hello" self')
say m
say m~class
say '-- m~do("john") -- not accepted by interpreter because doer is an enhanced Method...'
say '-- Error 93.961:  Method argument 1 must have a string value or an array value'

--------------------------------------------------------------------------
--------------------------------------------------------------------------

::class MyArray subclass Array

::class MyString subclass String
::method run -- Object~run is private, so must use a public method...
    forward class (super) continue

::class MyMethod subclass Method
::method makeArray -- Mandatory to let my instance be accepted by the interpreter
    return self~source -- but this is a poor solution ! the source, already parsed, will be parsed again.
    
--------------------------------------------------------------------------
--------------------------------------------------------------------------

::class ExtendedRoutine subclass Routine inherit RoutineDoer

::class ExtendedMethod subclass Method inherit MethodDoer

::class ExtendedString subclass String inherit StringDoer


::requires "extension/doers.cls"

