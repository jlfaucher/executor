routine = .context~package~findRoutine("myRoutine")

say "No deadlock because using only predefined methods (even if they are guarded)"
say "calling myMethod"
.myClass~new~myMethod(routine)
say "back from myMethod"
say "you see the package immediatly, even if myRoutine is still running"
say routine~package -- this predefined method is declared guarded
say "(press enter, myRoutine is waiting for you)"

::routine myRoutine
say "myRoutine : press enter"
pull -- myRoutine will stay active until you press enter

---------------
::class myClass
---------------

::method myMethod unguarded
use arg routine
reply
routine~call -- this predefined method is declared guarded

