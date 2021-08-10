.demo~new~exec(1)
.demo~new~exec(2)

::options trace i

::class demo
::method exec
    use arg id
    reply
    do 2
       say "TASK" id
       call syssleep 1
    end

