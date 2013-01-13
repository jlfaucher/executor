/*
Helper routine to simulate a busy application.
*/

::routine busy public
    use strict arg char
    call charout , "busy: "
    do i= 1 to random(5, 15)
        call charout , char
        call syssleep 0.05
    end
    say