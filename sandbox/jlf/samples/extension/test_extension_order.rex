/*
Question1 : Is the order of extension resolution a "natural" order ?
Question2 : The predefined classes are visible from every package (unless overriden by a local definition, I think)
            The user classes can be public or private.
            Is the current extension behavior compatible with that ? Seems good
*/

say
say "========== elaborating test_extension_order =========="
say

call routine_test_extension_order
call routine_test_extension_order1
call routine_test_extension_order2
call routine_test_extension_order3
call routine_test_myPublicClass1
call routine_test_myPublicClass2
call routine_test_myPublicClass3

::routine routine_test_extension_order public
say "----- routine_test_extension_order -----"
.object~new~do
.object~new~do1
.object~new~do2
.object~new~do3
.myPublicClass~new~m1
.myPublicClass~new~m2

::extension object
::method do
    say "do from test_extension_order"

-- The extended class depends on the order of the ::requires (i.e. which "myPublicClass" is visible from here)
::extension myPublicClass
::method m2
    say "m2 from test_extension_order"

-- Error 98.909:  Class "MYPRIVATECLASS" not found
--::extension myPrivateClass

::requires "test_extension_order1.rex"
::requires "test_extension_order2.rex"
