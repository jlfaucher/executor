/*
Keep this script compatible with ooRexx5!
The file 'method.output.reference.txt' is generated with ooRexx5.
*/

say "----------"
say "method.rex"
say "----------"
say


.local~expression = ".myClass"
say .local~expression

    signal on syntax name privateClassMethodError
    say .myClass~privateMethod
    after_privateClassMethodError:

    signal on syntax name packageClassMethodError
    say .myClass~packageMethod
    after_packageClassMethodError:

    say .myClass~publicMethod

say


.local~expression = ".myClass~new"
say .local~expression

    myInstance = .myClass~new

    signal on syntax name privateInstanceMethodError
    say myInstance~privateMethod
    after_privateInstanceMethodError:

    signal on syntax name packageInstanceMethodError
    say myInstance~packageMethod
    after_packageInstanceMethodError:

    say myInstance~publicMethod

exit 0


privateClassMethodError:
    say "privateClassMethodError"
    call sayCondition condition("O")
    signal after_privateClassMethodError

packageClassMethodError:
    say "packageClassMethodError"
    call sayCondition condition("O")
    signal after_packageClassMethodError

privateInstanceMethodError:
    say "privateInstanceMethodError"
    call sayCondition condition("O")
    signal after_privateInstanceMethodError

packageInstanceMethodError:
    say "packageInstanceMethodError"
    call sayCondition condition("O")
    signal after_packageInstanceMethodError


::requires "method.cls"