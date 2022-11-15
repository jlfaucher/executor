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

.IndentedStream~stdout = .IndentedStream~new(.stdout)
.IndentedStream~stderr = .IndentedStream~new(.stderr)


::class "IndentedStream" public
::constant indentSize 4
::attribute stdout class
::attribute stderr class
::attribute indentLevel
::attribute mustIndent
::attribute spaces
::attribute stream


::method init
    use strict arg stream, indentSize = (self~indentSize)
    self~indentLevel = 0
    self~mustIndent = .true
    self~spaces = " "~copies(indentSize)
    self~stream = stream
    
    
::method indent
    use strict arg -- none
    self~indentLevel +=1
    return self

    
::method dedent
    use strict arg -- none
    self~indentLevel -=1
    return self

    
::method indentIfNeeded private
    use strict arg -- none
    if self~mustIndent then do
        loop self~indentLevel
            self~stream~charout(self~spaces)
        end
        self~mustIndent = .false
    end
    
    
::method charout
    self~indentIfNeeded
    forward to (self~stream)
    
    
::method lineout
    self~indentIfNeeded
    self~mustIndent = .true
    forward to (self~stream)
    
    
::method say
    self~indentIfNeeded
    self~mustIndent = .true
    forward to (self~stream)
    
    
::method unknown
    use strict arg msg, args
    forward to (self~stream) message (msg) arguments (args)

