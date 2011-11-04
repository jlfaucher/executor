routine = .context~package~findRoutine("myRoutine")

say "Deadlock because using user-defined methods"
say "calling myMethod"
.myClass~new~myMethod(routine)
say "back from myMethod"
say "you don't see the package, until you leave myRoutine by pressing enter"
say routine~myPackage -- this user-defined method is declared guarded

::routine myRoutine
say "myRoutine : press enter"
pull -- myRoutine will stay active until you press enter


---------------
::class myClass
---------------

::method myMethod unguarded
use arg routine
reply
routine~myCall -- this user-defined method is declared guarded


-------------------
::extension Routine
-------------------

::method myCall
self~callWith(arg(1,"a"))

::method myPackage
return self~package
