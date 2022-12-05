::routine dump_collection public
    use arg coll, maxlevel, level=1, indent=""

    say indent"["coll~class~id":"
    s=coll~supplier
    do while s~available
        .output~charout(indent layout(s~index)~right(7)" : ")
        if s~item~isA(.Collection) then do
            if level >= maxlevel then say "..."
            else do
                say
                call dump_collection s~item, maxlevel, level+1, "           "indent
            end
        end
        else say layout(s~item)
        s~next
    end
    say indent"]"


::routine layout private
    use strict arg obj
    if obj~isA(.array), obj~dimension <= 1, obj~hasMethod("ppRepresentation") then return obj~ppRepresentation(100)
    if \obj~isA(.String) then return obj~string
    if \obj~dataType("N") then return obj
    if obj < 0 then return obj
    return " "obj
