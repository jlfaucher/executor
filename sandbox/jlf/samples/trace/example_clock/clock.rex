myclock1 = .clock~new ; myclock1~go
myclock2 = .clock~new ; myclock2~go

::options trace i

::class clock
::method go
    reply
    do 2
        say left(time(),8)
        call syssleep(1)
    end
