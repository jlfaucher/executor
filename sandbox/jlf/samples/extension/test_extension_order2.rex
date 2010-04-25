say
say "========== elaborating test_extension_order2 =========="
say

call routine_test_extension_order2
call routine_test_extension_order3

::routine routine_test_extension_order2 public
say "----- routine_test_extension_order2 -----"
.object~new~do
.object~new~do2
.object~new~do3
.myPublicClass~new~m1
--.myPublicClass~new~m2

::routine routine_test_myPublicClass2 public
say "----- routine_test_myPublicClass2 -----"
.myPublicClass~new~m1
.myPublicClass~new~m2

::extension object
::method do
    say "do from test_extension_order2"
::method do2
    say "do2 from test_extension_order2"
    
::class myPublicClass public
::method m1
    say "m1 from test_extension_order2"
    
::class myPrivateClass

::requires "test_extension_order3.rex"

