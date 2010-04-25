say
say "========== elaborating test_extension_order1 =========="
say

call routine_test_extension_order1
call routine_test_extension_order3

::routine routine_test_extension_order1 public
say "----- routine_test_extension_order1 -----"
.object~new~do
.object~new~do1
.object~new~do3
.myPublicClass~new~m1
--.myPublicClass~new~m2

::routine routine_test_myPublicClass1 public
say "----- routine_test_myPublicClass1 -----"
.myPublicClass~new~m1
--.myPublicClass~new~m2

::extension object
::method do
    say "do from test_extension_order1"
::method do1
    say "do1 from test_extension_order1"
    
::class myPublicClass public
::method m1
    say "m1 from test_extension_order1"
    
::class myPrivateClass

::requires "test_extension_order3.rex"
