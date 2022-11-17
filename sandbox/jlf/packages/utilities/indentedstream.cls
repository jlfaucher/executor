/*
Stream helper to manage indentation.
The methods "charout", "lineout", and "say" takes care of the indentation and
then forwards to the stream. Other methods are directly forwarded to the stream.

Example :
s = .IndentedStream~new(.stdout)
s~lineout("<book>")
s~indent
s~lineout("<chapter>")
s~lineout("</chapter>")
s~dedent
s~lineout("</book>")

Output :
<book>
    <chapter>
    </chapter>
</book>
*/

::class "IndentedStream" public
::constant indentSize 4
::attribute indentLevel get
::attribute stream get


::method init
    expose stream indentLevel mustIndent spaces
    use strict arg stream, indentSize = (self~indentSize)
    indentLevel = 0
    mustIndent = .true
    spaces = " "~copies(indentSize)


::method indent
    expose indentLevel
    use strict arg -- none
    indentLevel +=1
    return self


::method dedent
    expose indentLevel
    use strict arg -- none
    if indentLevel == 0 then return
    indentLevel -=1
    return self


::method indentIfNeeded private
    expose stream indentLevel mustIndent spaces
    use strict arg -- none
    if mustIndent then do
        loop indentLevel
            stream~charout(spaces)
        end
        mustIndent = .false
    end


::method charout
    expose stream
    self~indentIfNeeded
    forward to (stream)


::method lineout
    expose stream mustIndent
    self~indentIfNeeded
    mustIndent = .true
    forward to (stream)


::method say
    expose stream mustIndent
    self~indentIfNeeded
    mustIndent = .true
    forward to (stream)


::method unknown
    expose stream
    use strict arg msg, args
    forward to (stream) message (msg) arguments (args)

