::routine String2Args public
    -- Converts a string to an array of arguments.
    -- Arguments are separated by whitespaces (anything < 32) and can be quoted.
    -- This routine tries to follow the behavior of cmd.exe, which lets write such things :
    --                                                  %1                      %2              %3
    --     myscript c:\dir1\my dir\dir 2                c:\dir1\my              dir\dir         2
    --     myscript "c:\dir1\my dir\dir 2"              "c:\dir1\my dir\dir 2"
    --     myscript c:\dir1\"my dir"\dir 2              c:\dir1\"my dir"\dir    2
    --     myscript c:\dir1\my dir\dir" 2"              c:\dir1\my              dir\dir" 2"
    --     myscript he says "I told you "hello"!"       he                      says            "I told you "hello"!"
    --     myscript he says "I told you ""hello""!"     he                      says            "I told you ""hello""!"
    --
    -- Unlike cmd, this routine does an additional processing : 
    -- Quotes are removed from the value, except when they are doubled inside a quoted string.
    --     cmd parameter                value in args
    --     c:\dir1\my                   'c:\dir1\my'
    --     "c:\dir1\my dir\dir 2"       'c:\dir1\my dir\dir 2'
    --     c:\dir1\"my dir"\dir         'c:\dir1\my dir\dir'
    --     "I told you "hello"!"        'I told you hello!'
    --     "I told you ""hello""!"      'I told you "hello"!'
    use strict arg string

    args = .Array~new
    i = 1

    loop label arguments
        -- Skip whitespaces
        loop
            if i > string~length then return args
            if string~subchar(i) > " " then leave
            i += 1
        end
    
        -- Process current argument : can be made of several chunks, all chunks are concatenated
        -- Example                  chunk1          chunk2          chunk3      value
        -- one                      one                                        'one'
        -- "one two"                "one two"                                   'one two'
        -- one" two "three          one             " two "         three       'one two three'
        -- one" ""two"" "three      one             " ""two"" "     three       'one "two" three'
        current = .MutableBuffer~new
        loop label current_argument
            if string~subchar(i) == '"' then do
                -- Chunk surrounded by quotes : whitespaces are kept, double occurrence of quotes are replaced by a single embedded quote  
                loop label quoted_chunk
                    i += 1
                    if i > string~length then return args~~append(current~string)
                    select
                        when string~subchar(i) == '"' & string~subchar(i+1) == '"' then do
                            current~append('"')
                            i += 1
                        end
                        when string~subchar(i) == '"' then do
                            i += 1
                            leave quoted_chunk
                        end
                        otherwise current~append(string~subchar(i)) 
                    end
                end quoted_chunk
            end
            if string~subchar(i) <= " " then do
                args~append(current~string)
                leave current_argument
            end
            -- Chunk not surrounded by quotes : ends when a whitespace or quote is reached 
            loop
                if i > string~length then return args~~append(current~string)
                if string~subchar(i) <= " " | string~subchar(i) == '"' then leave
                current~append(string~subchar(i))
                i += 1
            end
        end current_argument
    end arguments
    return args

