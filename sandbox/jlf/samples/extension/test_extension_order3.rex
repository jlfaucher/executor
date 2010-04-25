say
say "========== elaborating test_extension_order3 =========="
say

call routine_test_extension_order3


::routine routine_test_extension_order3 public
say "----- routine_test_extension_order3 -----"
.object~new~do
.object~new~do3
.myPublicClass~new~m1
--.myPublicClass~new~m2

::routine routine_test_myPublicClass3 public
say "----- routine_test_myPublicClass3 -----"
.myPublicClass~new~m1
--.myPublicClass~new~m2

::extension object
::method do
    say "do from test_extension_order3"
::method do3
    say "do3 from test_extension_order3"

::class myPublicClass public
::method m1
    say "m1 from test_extension_order3"
    
::class myPrivateClass


