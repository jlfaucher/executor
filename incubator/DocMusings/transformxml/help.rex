::routine Help public
    -- The help text is taken from the comment at the begining of the source file.
    use strict arg source
    sourcename = filespec("name", source)
    display = .false
    signal on notready
    do forever
        sourceline = linein(source)
        if sourceline~pos("****/") <> 0 then leave
        sourceline = sourceline~changeStr("$sourcename", sourcename)
        if display then say sourceline
        if sourceline~pos("/****") <> 0 then display = .true
    end
    notready:
    return

