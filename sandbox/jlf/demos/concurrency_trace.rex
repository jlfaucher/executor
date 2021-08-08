.demo~new~exec(id:1)
.demo~new~exec(id:2)

::options trace i

::class demo
::method exec
    use named arg id
    reply
    do 2
       say "TASK" id
       call syssleep 1
    end

::requires "extension/extensions.cls"

