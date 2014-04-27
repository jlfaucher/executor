-- Coactivities in ooRexx
-- This script needs a modified ooRexx interpreter which allows to extend predefined ooRexx classes.

-- In case of error, must kill any running coactivity, otherwise the program doesn't terminate
signal on any name error
signal on syntax name error

call demo
call terminate
return

error:
condition = condition("o")
say condition~instruction condition~condition "for" condition~additional
if .nil <> condition~message then say condition~message
terminate:
say
say "Ended coactivities:" .Coactivity~endAll
return

--::options trace i
::requires "extension/extensions.cls"
::requires "concurrency/busy.cls"
::requires "concurrency/multiplier.cls"
::requires "concurrency/binary_tree.cls"

-----------------------------------------------------------------------
::routine demo

say
say "A coactivity implemented by a one-liner routine"
c = .Coactivity~new({say "running coactivity" ; return 1}, .false)
c~start -- optional, the first ~resume automatically starts the coactivity, if needed
say c~resume
signal on syntax name trap_syntax1
say c~resume -- Error 91.999:  Message "RESUME" did not return a result
trap_syntax1:


say
say "A coactivity implemented by a one-liner routine, used as a generator"
c = .Coactivity~new{do i = 1 to 10 ; .yield[i] ; end}
c~resume
do while var("result")
    say result
    c~resume
end


say
say "Iteration with a supplier"
c = .Coactivity~new{do i = 1 to 10 ; .yield[i] ; end}
supplier = c~supplier
do while supplier~available
    say supplier~index ":" supplier~item
    supplier~next
end


say
say "do over a finite coactivity"
c = .Coactivity~new{do i = 1 to 10 ; .yield[i] ; end}
do v over c
    say v
end


say
say "do over an infinite coactivty : needs a limit"
say "Local limit setting"
c = .Coactivity~new{i = 1 ; do forever ; .yield[i] ; i += 1 ; end}
do v over c~makeArray(15)
    say v
end


say
say "A coactivity implemented by a routine"
multiplier = .context~package~findRoutine("multiplier")
c = .Coactivity~new(multiplier)
call busy "a"
say c~resume(10) -- all values will be multiplied by 10
call busy "b"
say c~resume("first call", 1)
call busy "c"
say c~resume("second call", 2)
call busy "d"
say c~resume("third call", 3)


say
say "A coactivity implemented by a subclass of .Coactivity whose entry point is main (default)"
c = .Multiplier~new(10)
call busy "a"
say c~resume("first call", 1)
call busy "b"
say c~resume("second call", 2)
call busy "c"
say c~resume("third call", 3)


say
say "A coactivity whose entry point is a method of .BinaryTree (which is not subclass of .Coactivity)"
say "Ascending order"
btree = .BinaryTree~of(4, 6, 2, 7, 5, 3, 1)
c = btree~ascendingItems
c~resume
do while var("result")
    say result
    c~resume
end
say "Descending order"
c = btree~descendingItems
c~resume
do while var("result")
    say result
    c~resume
end


say
say ".BinaryTree2 (a variation of .BinaryTree) using blocks"
say "Ascending order"
btree = .BinaryTree2~of(4, 6, 2, 7, 5, 3, 1)
c = btree~ascendingItems
c~resume
do while var("result")
    say result
    c~resume
end
say "Descending order"
c = btree~descendingItems
c~resume
do while var("result")
    say result
    c~resume
end

