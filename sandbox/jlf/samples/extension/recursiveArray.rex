/*
Recursive arrays
*/
    a = .array~of("string1","string2")
    b = .array~of("string2")
    b~append(a)
    a~append(b)
    a~append(a)
    
    -- display the first two levels
    s1 = a~supplier
    do while s1~available
        call charout , s1~index ":" s1~item
        if s1~item~isA(.array) then call charout , " "s1~item~ppRepresentation
        say
        if s1~item~isA(.array) then do
            s2 = s1~item~supplier
            do while s2~available
                call charout , "    "s2~index ":" s2~item
                if s2~item~isA(.array) then call charout , " "s2~item~ppRepresentation
                say
                s2~next
            end
        end
        s1~next
    end
    say "-----"
    
    say a~ppRepresentation
    say "-----"
    
    a~pipe(.console dataflow)
    say "-----"
    
    a~pipe(.inject iterateBefore {item} recursive.0.memorize | .console dataflow)
    say "-----"

    
    d = .array~of("d")
    c = .array~of("c", d)
    b = .array~of("b", c)
    a = .array~of("a", b)
    d~append(a)
    say a~ppRepresentation
    say "-----"

::requires "extension/extensions.cls"
::requires "pipeline/pipe_extension.cls"

