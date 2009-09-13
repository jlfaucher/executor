::requires "rxregexp.cls"
::requires "indentedstream.cls"
::requires "trace.cls"


-------------------------------------------------------------------------------
/*
The text of the syntax diagram is stored in a 2 dimensions array which contains
symbols of one character.

A symbol has a position in the array (line, col) and holds 4 strings,
all starting with the symbol's character :
- left to right string (l2r)
- right to left string (r2l)
- top to bottom string (t2b)
- bottom to top string (b2t)
During analysis, a symbol is associated to a token which, most of the time,
covers several symbols.

A token has a text and is chained in the four directions :
- right token
- left token
- lower token
- upper token

Several syntax diagrams can be extracted from a single textual syntax diagram,
depending on the number of begining of statements, or in case of fragments.
*/

::class "SyntaxDiagramTokenizer" public
::constant lineDigits 3 -- number of digits when displaying the line number
::attribute continuationCount -- counter of ContinuedOnNextLine already resolved 
::attribute continuationEntries -- array of ContinuedFromPreviousLine, direct access by index 1..n
::attribute dereferenceContinuations -- when true, the continuations are automatically dereferenced (not visible from the parser when walking through the tokens)
::attribute errorCount
::attribute mainEntries -- list of BeginingOfStatement or BeginingOfFragment
::attribute messages -- list of strings
::attribute name -- syntax diagram name, not needed by the tokenizer, but it's a way to bring this info between the various steps
::attribute symbols -- array[line,col] of Symbol
::attribute text -- the text of the syntax diagram to tokenize (contains eol characters)
::attribute tokenizationIsComplete
::attribute tokens -- table of all tokens created during analysis, used to check the completness of analysis
::attribute visitIsComplete


::method tokenize class
    use strict arg text, endofline
    tokenizer = self~new(text, endofline)
    if tokenizer~findEntries == .false then return .nil
    -- From here,we assume that the text contains one or several syntax diagrams
    if tokenizer~checkFirstLineVersusOtherLines == .false then return tokenizer
    do entry over tokenizer~mainEntries
        if entry~isA(.Comment) then iterate
        tokenizer~l2rTokenize(entry, entry~nextSymbol) -- left to right
    end
    if tokenizer~checkTokenizationCompletness == .false then tokenizer~addError("[error] Some symbols have not been tokenized")
    tokenizer~clearVisitMarks
    do entry over tokenizer~mainEntries
        entry~visit
    end
    if tokenizer~checkVisitCompletness == .false then tokenizer~addError("[error] Some tokens have not been visited")
    return tokenizer
    

::method init
    use strict arg text, endofline
    self~continuationCount = 0
    self~continuationEntries = .Array~new
    self~dereferenceContinuations = .false
    self~errorCount = 0
    self~mainEntries = .List~new
    self~messages = .List~new
    self~name = ""
    self~text = text
    self~tokenizationIsComplete = .false
    self~tokens = .IdentityTable~new
    self~visitIsComplete = .false
    self~objectName = self~class~id
    
    lineDimension = 0
    colDimension = 0
    i = 1
    do while i <= text~length
        lineDimension += 1
        eolpos = text~pos(endofline, i)
        if eolpos == 0 then lastCol = text~length
        else lastCol = eolpos - 1
        colCount = lastCol - i + 1
        if colCount > colDimension then colDimension = colCount
        i = lastCol + 1 + endofline~length
    end
    
    self~symbols = .Array~new(lineDimension, colDimension)

    line = 0
    i = 1
    do while i <= text~length
        line += 1
        eolpos = text~pos(endofline, i)
        if eolpos == 0 then lastCol = text~length
        else lastCol = eolpos - 1
        col = 0
        do j = i to lastCol
            col += 1
            self~symbols[line, col] = .Symbol~new(text~subchar(j), self, line, col)
        end
        i = lastCol + 1 + endofline~length
    end

    
::method "[]"
    use strict arg line, col
    if line < 1 | line > self~lineDimension then return .nil
    if col < 1 | col > self~colDimension then return .nil
    symbol = self~symbols[line, col]
    -- create a space symbol on the fly if needed (inside the limits, any unitialized cell is a space) 
    if symbol == .nil then self~symbols[line, col] = .Symbol~new(" ", self, line, col, .true)
    return self~symbols[line, col]
    
    
::method "[]="
    use strict arg value, line, col
    if line < 1 | line > self~lineDimension then raise syntax 93.900 array ("line must be in range 1.."self~lineDimension", got "line)
    if col < 1 | col > self~colDimension then raise syntax 93.919 array ("col must be in range 1.."self~colDimension", got "col)
    self~symbols[line, col] = value

    
::method lineDimension
    use strict arg -- none
    return self~symbols~dimension(1)
    
    
::method colDimension
    use strict arg -- none
    return self~symbols~dimension(2)
    
    
::method addMessage
    use strict arg message
    self~messages~append(message)
    
    
::method addError
    use strict arg message
    self~addMessage(message)
    self~errorCount += 1
    
    
::method findEntries private
    use strict arg -- none
    lastLabel = "" -- A comment whose last character is ":" is considered as a label (will be assigned to the next syntax diagram or fragment)
    /*             1
    entry#1        2 >>-open(-+---------------+-,subkey-+--------------+-)----------><     
                   3          +-parent_handle-+         +-,-| access |-+                   
                   4                                                                       
    entry#2        5 access:                                                               
                   6                                                                       
                   7    +-ALL-+                                                            
    entry#3        8 |--+-----+------------------------------------------------------>
    ...            9 ...
    */
    containsSyntaxDiagram = .false
    do line = 1 to self~lineDimension
        symbol = self[line, 1]
        if symbol == .nil then iterate
        BOL = symbol~l2rText~verify(" ") -- position of first non-space character
        if BOL == 0 then iterate -- blank line
        symbol = self[line, BOL]
        select
            when .BeginingOfStatement~match(symbol) then do
                token = .BeginingOfStatement~tokenize(symbol)
                if token <> .nil then do
                    if lastLabel <> "" then token~label = lastLabel
                    self~mainEntries~append(token)
                    containsSyntaxDiagram = .true
                end
                lastLabel = ""
            end
            when .BeginingOfFragment~match(symbol) then do
                token = .BeginingOfFragment~tokenize(symbol)
                if token <> .nil then do
                    if lastLabel <> "" then token~label = lastLabel
                    self~mainEntries~append(token)
                    containsSyntaxDiagram = .true
                end
                lastLabel = ""
            end
            when .ContinuedFromPreviousLine~match(symbol) then do
                token = .ContinuedFromPreviousLine~tokenize(symbol)
                if token <> .nil then self~continuationEntries~append(token)
                lastLabel = ""
            end
            when .Comment~match(symbol) then do
                token = .Comment~tokenize(symbol)
                if token <> .nil then do
                    self~mainEntries~append(token)
                    if token~text~right(1) == ":" then lastLabel = token~text
                end
            end
            otherwise nop
        end
    end
    return containsSyntaxDiagram


::method checkFirstLineVersusOtherLines private
    /*
    Not sure I need to check that, but...
    If the first line is not empty, then all other lines must be empty.
    Why ? because the first line is on the same line as <![CDATA[, so does not start on the same column as next lines.
    <![CDATA[>>-myfunc(-->
    >--)--><]]>
    A multi-line diagram which includes the first line could be a mess...
    */
    use strict arg -- none
    if self[1,1]~l2rText~strip <> "" then do
        do line = 2 to self~lineDimension
            if self[line, 1]~l2rText~strip <> "" then do
                self~addError("[error] The first line is not empty : all other lines must be empty")
                return .false
            end
        end
    end
    return .true


::method l2rTokenize -- left to right
    use strict arg previousToken, symbol
    stop = .false
    loop  until stop
        token = .nil
        select
            when symbol == .nil then stop = .true
            when symbol~isDummy then stop = .true
            when symbol~token <> .nil then do
                -- already tokenized
                select
                    when symbol~token~isA(.ContinuedFromPreviousLine) then token = symbol~token -- Don't stop if ContinuedFromPreviousLine (to let chain all the tokens)
                    when symbol~token~isA(.t2bCrossroads) | symbol~token~isA(.b2tCrossroads) then do
                        -- this is a fix for the problem described in dumpTextWithPointers
                        token = symbol~token
                        stop = .true
                    end
                    otherwise stop = .true
                end
            end
            when .EndOfStatement~match(symbol) then token = .EndOfStatement~tokenize(symbol)
            when .EndOfFragment~match(symbol) then token = .EndOfFragment~tokenize(symbol)
            when .BeginingOfFragmentReference~match(symbol) then token = .BeginingOfFragmentReference~tokenize(symbol)
            when .EndOfFragmentReference~match(symbol) then token = .EndOfFragmentReference~tokenize(symbol)
            when .ContinuedOnNextLine~match(symbol) then token = .ContinuedOnNextLine~tokenize(symbol)
            when .l2rCrossroads~match(symbol) then token = .l2rCrossroads~tokenize(symbol)
            when .l2rPath~match(symbol) then token = .l2rPath~tokenize(symbol)
            when .Identifier~match(symbol) then token = .Identifier~tokenize(symbol)

            /*when symbol~char = " " then return -- stop horizontal path*/ -- bad idea ! we have some cases like "+--, precision, --+"
            
            when symbol~char = "+" then stop = .true -- not an l2rCrossroads, stop horizontal path (will be processed by b2tTokenize or t2bTokenize)

            when .l2rCorner~match(symbol) then do
                token = .l2rCorner~tokenize(symbol)
                stop = .true
            end
            
            -- keep it after l2rpath : "-2-" is Number 2, not -2. But "- -2-" is -2.
            -- keep it after "+" : "-+2-" is end of path followed by 2 (illegal), not Number +2. But "- +2-" is +2.
            when .Number~match(symbol) then token = .Number~tokenize(symbol)

            when .EscapedCharacter~match(symbol) then token = .EscapedCharacter~tokenize(symbol)
            otherwise token = .Character~tokenize(symbol)
        end
        .Token~l2rChain(previousToken, token)
        if token == .nil then stop = .true
        else do
            previousToken = token
            symbol = token~nextSymbol
        end
    end
    

::method b2tTokenize -- bottom to top
    use strict arg previousToken, symbol
    stop = .false
    loop until stop
        token = .nil
        select
            when symbol == .nil then stop = .true
            when symbol~isDummy then stop = .true
            when symbol~token <> .nil then do
                -- already tokenized
                if symbol~token~isA(.l2rCorner) then do
                    -- needed for chain correctly
                    token = symbol~token
                end
                stop = .true 
            end
            when .b2tPath~match(symbol) then token = .b2tPath~tokenize(symbol)
            when .b2tCrossroads~match(symbol) then token = .b2tCrossroads~tokenize(symbol)
            when .b2tCorner~match(symbol) then do
                token = .b2tCorner~tokenize(symbol)
                stop = .true
            end
            otherwise stop = .true
        end
        .Token~b2tChain(previousToken, token)
        if token == .nil then stop = .true
        else do
            previousToken = token
            symbol = token~nextSymbol
        end
    end
    
    
::method t2bTokenize -- top to bottom
    use strict arg previousToken, symbol
    stop = .false
    loop until stop
        token = .nil
        select
            when symbol == .nil then stop = .true
            when symbol~isDummy then stop = .true
            when symbol~token <> .nil then do
                -- already tokenized
                if symbol~token~isA(.l2rCorner) then do
                    -- needed for chain correctly
                    token = symbol~token
                end
                stop = .true 
            end
            when .t2bPath~match(symbol) then token = .t2bPath~tokenize(symbol)
            when .t2bCrossroads~match(symbol) then token = .t2bCrossroads~tokenize(symbol)
            when .t2bCorner~match(symbol) then do
                token = .t2bCorner~tokenize(symbol)
                stop = .true
            end
            otherwise stop = .true
        end
        .Token~t2bChain(previousToken, token)
        if token == .nil then stop = .true
        else do
            previousToken = token
            symbol = token~nextSymbol
        end
    end
    

::method checkTokenizationCompletness private
    use strict arg -- none
    self~tokenizationIsComplete = .false
    do line = 1 to self~lineDimension
        do col = 1 to self~colDimension
            symbol = self~symbols[line, col]
            if symbol == .nil then iterate
            if symbol~char == " " then iterate
            if symbol~token == .nil then return .false
        end
    end
    self~tokenizationIsComplete = .true
    return .true
    

::method checkVisitCompletness
    use strict arg -- none
    self~visitIsComplete = .false
    do token over self~tokens
        if \ token~alreadyVisited then return .false
    end
    self~visitIsComplete = .true
    return .true
    

::method clearVisitMarks
    use strict arg -- none
    do token over self~tokens
        token~clearVisitMark
    end
    

::method dumpColumnRuler private
    use strict arg stream = (.IndentedStream~stdout), showPointers = .false
    pointerSpace = ""
    if showPointers then pointerSpace = " "
    -- column ruler, 1st line : one digit each ten
    stream~charout(" "~copies(self~lineDigits + 1))
    do col = 1 to self~colDimension
        if col // 10 == 0 then stream~charout(col // 100 % 10 || pointerSpace)
        else stream~charout(" "pointerSpace)
    end
    stream~lineout("")
    -- column ruler, 2nd line : digits 1..9
    stream~charout(" "~copies(self~lineDigits + 1))
    do col = 1 to self~colDimension
        stream~charout(col // 10 || pointerSpace)
    end
    stream~lineout("")
    
    
::method dumpText
    /*
                     1         2         3         4         5         6     
            12345678901234567890123456789012345678901234567890123456789012345
          1                                                                  
          2 >>-STATEMENT--+---------------+--------------------------------><
          3               +-optional_item-+                                  
    */
    use strict arg stream = (.IndentedStream~stdout)
    self~dumpColumnRuler(stream)
    do line = 1 to self~lineDimension
        stream~charout(line~format(self~lineDigits)" ")
        stream~lineout(self[line,1]~l2rText)
    end
    
    
::method dumpNotTokenizedSymbols
    use strict arg stream = (.IndentedStream~stdout)
    self~dumpColumnRuler(stream)
    -- lines of the syntax diagram
    do line = 1 to self~lineDimension
        stream~charout(line~format(self~lineDigits)" ")
        do col = 1 to self~colDimension
            symbol = self~symbols[line, col]
            select
                when symbol == .nil then stream~charout(" ")
                when symbol~token == .nil then stream~charout(symbol~char)
                otherwise stream~charout(".")
            end
        end
        stream~lineout("")
    end
    
    
::method dumpTokenizedSymbols
    use strict arg stream = (.IndentedStream~stdout), inspectTokens = .false
    if inspectTokens then inspectedTokens = .IdentityTable~new
    do line = 1 to self~lineDimension
        do col = 1 to self~colDimension
            symbol = self~symbols[line, col]
            select
                when symbol == .nil then nop
                when symbol~token == .nil then nop
                otherwise do
                    stream~charout(symbol~string)
                    stream~charout(", tokenized as ")
                    if \ symbol~token~isA(.l2rPath), inspectTokens, inspectedTokens[symbol~token] == .nil then do
                        -- to reduce the size of the dump, I don't inspect l2Path
                        -- the first occurrence of other tokens is inspected
                        stream~lineout("")
                        stream~indent
                        symbol~token~inspect(stream)
                        stream~dedent
                        inspectedTokens[symbol~token] = .true -- mark inspected
                    end
                    else do
                        -- next occurrences are just shortly described
                        stream~charout(symbol~token~string)
                        stream~lineout("")
                    end
                end
            end
        end
    end
    
    
::method dumpNotVisitedTokens
    use strict arg stream = (.IndentedStream~stdout)
    self~dumpColumnRuler(stream)
    -- lines of the syntax diagram
    do line = 1 to self~lineDimension
        stream~charout(line~format(self~lineDigits)" ")
        do col = 1 to self~colDimension
            symbol = self~symbols[line, col]
            char = symbol~char
            if char == " " then char = "#" -- to see something
            select
                when symbol == .nil then stream~charout(" ")
                when symbol~token == .nil then stream~charout(" ")
                when symbol~token~alreadyVisited == .false then stream~charout(char)
                otherwise stream~charout(".")
            end
        end
        stream~lineout("")
    end
    
    
::method dumpTextWithPointers
    /*
    Same as dumpText, with an additional information : if the token is linked with a
    neighboring token, then a dot is displayed between the boundary character of the
    current token and the boundary character of the neighboring token, otherwise a space
    is displayed. That way, you can visually check if a path is broken somewhere.
    This applies in the four directions. Since the chaining is bidirectional, we need
    only to show the rightToken and lowerToken pointers.
    Ex :
                              1                   2                   3     
            1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 
          1                                                                 
                                                                            
          2 >_>.-.S_T_A_T_E_M_E_N_T.-.-.+.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.+.- 
                                        .                               .   
          3                             +.-.o_p_t_i_o_n_a_l___i_t_e_m.- +

    In this example, we can see that the path is broken after optional_item (now fixed)
    */
    use strict arg stream = (.IndentedStream~stdout)
    self~dumpColumnRuler(stream, .true)
    -- lines of the syntax diagram
    do line = 1 to self~lineDimension
        -- horizontal pointers
        stream~charout(line~format(self~lineDigits)" ")
        do col = 1 to self~colDimension
            symbol = self~symbols[line, col]
            select
                when symbol == .nil then stream~charout("  ")
                when symbol~token == .nil then stream~charout(symbol~char" ")
                otherwise do
                    stream~charout(symbol~char)
                    if symbol~isLastHorizontalSymbolOfToken then do
                        if symbol~token~rightToken == .nil then stream~charout(" ")
                        else stream~charout(".")
                    end
                    else stream~charout("_") -- glue between the characters of the token
                end
            end
        end
        stream~lineout("")
        -- vertical pointers, below the symbol
        stream~charout(" "~copies(self~lineDigits+1))
        do col = 1 to self~colDimension
            symbol = self~symbols[line, col]
            select
                when symbol == .nil then stream~charout("  ")
                when symbol~token == .nil then stream~charout("  ")
                otherwise do
                    if symbol~isLastVerticalSymbolOfToken then do
                        if symbol~token~lowerToken == .nil then stream~charout("  ")
                        else stream~charout(". ")
                    end
                    else stream~charout("|") -- glue between the characters of the token
                end
            end
        end
        stream~lineout("")
    end
    
    
::method dump
    use strict arg stream = (.IndentedStream~stdout)
    self~dumpText(stream)
    stream~lineout("")
    -- main entries
    stream~lineout("Main entries :")
    do entry over self~mainEntries
        stream~lineout(entry~string)
    end
    stream~lineout("")
    -- continuation entries
    stream~lineout("Continuation entries :")
    do entry over self~continuationEntries
        stream~lineout(entry~string)
    end
    stream~lineout("")
    -- diagnostic
    if self~errorCount == 0 then stream~lineout("Tokenization : OK")
    else stream~lineout("Tokenization : KO")
    do m over self~messages 
        stream~lineout(m)
    end
    stream~lineout("")
    -- symbols not tokenized
    if self~tokenizationIsComplete == .false then do
        stream~lineout("Symbols not tokenized :")
        self~dumpNotTokenizedSymbols(stream)
        stream~lineout("")
    end
    -- symbols tokenized
    stream~lineout("Symbols tokenized :")
    self~dumpTokenizedSymbols(stream, .true)
    stream~lineout("")
    -- tokens not visited
    if self~visitIsComplete == .false then do
        stream~lineout("Tokens not visited :")
        self~dumpNotVisitedTokens(stream)
        stream~lineout("")
    end


::method inspect -- for debug
    use strict arg stream = (.IndentedStream~stdout)
    stream~lineout(self~string" :")
    stream~lineout("")
    self~dump(stream)

    
-------------------------------------------------------------------------------
::class "Symbol"
::attribute char
::attribute col
::attribute isDummy -- true if created on the fly
::attribute line
::attribute tokenizer
::attribute token

-- Text in the four directions

::attribute l2rText get -- left to right
    expose l2rText
    if var(l2rText) then return l2rText
    l2rText = .MutableBuffer~new
    symbol = self
    do while symbol <> .nil
        l2rText~append(symbol~char)
        symbol = symbol~rightSymbol
    end
    l2rText = l2rText~string
    return l2rText

    
::attribute r2lText get -- right to left
    expose r2lText
    if var(r2lText) then return r2lText
    r2lText = .MutableBuffer~new
    symbol = self
    do while symbol <> .nil
        r2lText~append(symbol~char)
        symbol = symbol~leftSymbol
    end
    r2lText = r2lText~string
    return r2lText


::attribute b2tText get -- bottom to top
    expose b2tText
    if var(b2tText) then return b2tText
    b2tText = .MutableBuffer~new
    symbol = self
    do while symbol <> .nil
        b2tText~append(symbol~char)
        symbol = symbol~upperSymbol
    end
    b2tText = b2tText~string
    return b2tText


::attribute t2bText get -- top to bottom
    expose t2bText
    if var(t2bText) then return t2bText
    t2bText = .MutableBuffer~new
    symbol = self
    do while symbol <> .nil
        t2bText~append(symbol~char)
        symbol = symbol~lowerSymbol
    end
    t2bText = t2bText~string
    return t2bText


::method init
    use strict arg char, tokenizer, line, col, isDummy=.false
    self~char = char
    self~col = col
    self~isDummy = isDummy
    self~token = .nil
    self~line = line
    self~tokenizer = tokenizer
    self~objectName = "The '"self~char"' "self~class~id" at ["self~line","self~col"]"

    
::method leftSymbol
    use strict arg -- none
    return self~tokenizer[self~line, self~col - 1]

    
::method rightSymbol
    use strict arg -- none
    return self~tokenizer[self~line, self~col + 1]
    
    
::method upperSymbol
    use strict arg -- none
    return self~tokenizer[self~line - 1, self~col]

    
::method lowerSymbol
    use strict arg -- none
    return self~tokenizer[self~line + 1, self~col]
    

::method setToken
    use strict arg token
    if self~token == token then return .true
    if self~token <> .nil then do
        -- Should never happen, but...
        self~tokenizer~addError(  "[error] Trying to assign two different tokens to "self" :")
        self~tokenizer~addMessage("        current : "self~token)
        self~tokenizer~addMessage("        new     : "token)
        return .false
    end
    self~token = token
    return .true


::method isLastHorizontalSymbolOfToken
    use strict arg -- none
    token = self~token
    if token == .nil then return .false
    text = textWithoutMetaChar(token~text) -- todo : should find a way to not call textWithoutMetaChar, because may bring troubles for Comments
    select
        when token~isA(.l2rToken) then do
            if self~col == (token~firstSymbol~col + text~length - 1) then return .true
        end
        when token~isA(.r2lToken) then do
            if self~col == (token~firstSymbol~col - text~length + 1) then return .true
        end
        when token~isA(.t2bToken) then return .true
        when token~isA(.b2tToken) then return .true
        otherwise nop -- should never reach here
    end
    return .false
    
    
::method isLastVerticalSymbolOfToken
    use strict arg -- none
    token = self~token
    if token == .nil then return .false
    select
        when token~isA(.l2rToken) then return .true
        when token~isA(.r2lToken) then return .true
        when token~isA(.t2bToken) then do
            if self~line == (token~firstSymbol~line + token~text~length - 1) then return .true
        end
        when token~isA(.b2tToken) then do
            if self~line == (token~firstSymbol~line - token~text~length + 1) then return .true
        end
        otherwise nop -- should never reach here
    end
    return .false
    
    
::method inspect -- for debug
    use strict arg stream = (.IndentedStream~stdout)
    stream~lineout(self~string)
    stream~indent
        self~inspectProperties(stream)
    stream~dedent
    
    
::method inspectProperties
    use strict arg stream = (.IndentedStream~stdout)
    stream~lineout("l2rText = '"self~l2rText"'")
    stream~lineout("r2lText = '"self~r2lText"'")
    stream~lineout("b2tText = '"self~b2tText"'")
    stream~lineout("t2bText = '"self~t2bText"'")
    

-------------------------------------------------------------------------------
::class "Token"
::attribute annotation -- used by the parser, to associate parsing information
::attribute firstSymbol
::attribute nextSymbol -- The next symbol to analyze, in the main direction of the token 
::attribute text -- The text of the token, either defined (overriden) by a constant, or calculated
::attribute text class -- The text to match in order to recognize the token, either defined (overriden) by a constant, or not used
::attribute tokenizer

-- For navigation in the network of tokens
::attribute leftToken get
    expose leftToken
    if self~tokenizer~dereferenceContinuations &,
       leftToken~isA(.ContinuedFromPreviousLine) then return leftToken~leftToken~leftToken -- dereference the continuation
    return leftToken
::attribute leftToken set
::attribute lowerToken
::attribute rightToken get
    expose rightToken
    if self~tokenizer~dereferenceContinuations &,
       rightToken~isA(.ContinuedOnNextLine) then return rightToken~rightToken~rightToken -- dereference the continuation
    return rightToken
::attribute rightToken set
::attribute upperToken


::method init class
    self~text = ""
    
    
::method init
    use strict arg symbol
    self~annotation = .nil
    self~firstSymbol = symbol
    self~leftToken = .nil
    self~lowerToken = .nil
    self~nextSymbol = .nil
    self~rightToken = .nil
    self~text = ""
    self~tokenizer = symbol~tokenizer
    self~upperToken = .nil
    self~updateObjectName
    self~clearVisitMark  -- will create an entry in the table of tokens
    
    
::method updateObjectName
    -- Some subclasses assign a value to self~text only when tokenizing.
    -- In this case, this method must be reexecuted after the assignment.
    self~objectName = "The '"self~text"' "self~class~id" at ["self~firstSymbol~line","self~firstSymbol~col"]"


::method value -- some subclasses will redefine this method. Sometimes, the matched text must be stripped.
    use strict arg -- none
    return self~text
    
    
::method l2rChain class
    use strict arg from, to
    if from == .nil | to == .nil then return .false
    error = .false
    if from == to then do
        -- Should never happen, but...
        tokenizer = from~tokenizer
        tokenizer~addError(  "[error] Trying to chain "from" to itself")
        error = .true
    end
    if from~rightToken <> .nil & from~rightToken <> to then do
        -- Should never happen, but...
        tokenizer = from~tokenizer
        tokenizer~addError(  "[error] Trying to assign two different right tokens to "from" :")
        tokenizer~addMessage("        current : "from~rightToken)
        tokenizer~addMessage("        new     : "to)
        error = .true
    end
    if to~leftToken <> .nil & to~leftToken <> from then do
        -- Should never happen, but...
        tokenizer = to~tokenizer
        tokenizer~addError(  "[error] Trying to assign two different left tokens to "to" :")
        tokenizer~addMessage("        current : "to~leftToken)
        tokenizer~addMessage("        new     : "from)
        error = .true
    end
    if error then return .false
    from~rightToken = to
    to~leftToken = from
    return .true

    
::method b2tChain class
    use strict arg from, to
    if from == .nil | to == .nil then return .false
    error = .false
    if from~upperToken <> .nil & from~upperToken <> to then do
        -- Should never happen, but...
        tokenizer = from~tokenizer
        tokenizer~addError(  "[error] Trying to assign two different upper tokens to "from" :")
        tokenizer~addMessage("        current : "from~upperToken)
        tokenizer~addMessage("        new     : "to)
        error = .true
    end
    if to~lowerToken <> .nil & to~lowerToken <> from then do
        -- Should never happen, but...
        tokenizer = to~tokenizer
        tokenizer~addError(  "[error] Trying to assign two different lower tokens to "to" :")
        tokenizer~addMessage("        current : "to~lowerToken)
        tokenizer~addMessage("        new     : "from)
        error = .true
    end
    if error then return .false
    from~upperToken = to
    to~lowerToken = from
    return .true
    
    
::method t2bChain class
    use strict arg from, to
    if from == .nil | to == .nil then return .false
    error = .false
    if from~lowerToken <> .nil & from~lowerToken <> to then do
        -- Should never happen, but...
        tokenizer = from~tokenizer
        tokenizer~addError(  "[error] Trying to assign two different lower tokens to "from" :")
        tokenizer~addMessage("        current : "from~lowerToken)
        tokenizer~addMessage("        new     : "to)
        error = .true
    end
    if to~upperToken <> .nil & to~upperToken <> from then do
        -- Should never happen, but...
        tokenizer = to~tokenizer
        tokenizer~addError(  "[error] Trying to assign two different upper tokens to "to" :")
        tokenizer~addMessage("        current : "to~upperToken)
        tokenizer~addMessage("        new     : "from)
        error = .true
    end
    if error then return .false
    from~lowerToken = to
    to~upperToken = from
    return .true


::method visit
    use strict arg -- none
    if \ self~alreadyVisited then do
        self~setVisitMark
        -- leftToken is not visited because not needed to ensure completness
        if self~rightToken <> .nil then self~rightToken~visit
        if self~upperToken <> .nil then self~upperToken~visit
        if self~lowerToken <> .nil then self~lowerToken~visit
    end
    

::method setVisitMark
    use strict arg -- none
    self~tokenizer~tokens[self] = .true
    
    
::method clearVisitMark
    use strict arg -- none
    self~tokenizer~tokens[self] = .nil
    
    
::method alreadyVisited
    use strict arg -- none
    return self~tokenizer~tokens[self] <> .nil
    
    
::method inspect -- for debug
    use strict arg stream = (.IndentedStream~stdout)
    stream~lineout(self~string)
    stream~indent
        self~inspectProperties(stream)
    stream~dedent
    
    
::method inspectProperties
    use strict arg stream = (.IndentedStream~stdout)
    stream~lineout("firstSymbol = "self~firstSymbol)
    stream~lineout("nextSymbol = "self~nextSymbol)
    stream~lineout("text = '"self~text"'")
    -- stream~lineout("tokenizer = "self~tokenizer)
    stream~lineout("leftToken = "self~leftToken)
    stream~lineout("lowerToken = "self~lowerToken)
    stream~lineout("rightToken = "self~rightToken)
    stream~lineout("upperToken = "self~upperToken)

    
-------------------------------------------------------------------------------
-- Left to right token
::class "l2rToken" mixinclass "Token"


::method match class
    use strict arg symbol
    if symbol == .nil then return .false
    if symbol~token~isA(self) then return .true
    if textHasBOL(self~text) then do
        if symbol~leftSymbol <> .nil, symbol~leftSymbol~r2lText~strip <> "" then return .false
    end
    if textHasEOL(self~text) then do
        if symbol~l2rText~substr(textWithoutMetaChar(self~text)~length + 1)~strip <> "" then return .false 
    end
    if symbol~l2rText~pos(textWithoutMetaChar(self~text)) == 1 then return .true
    return .false


::method tokenize class
    use strict arg symbol
    if self~match(symbol) then do
        if symbol~token <> .nil then token = symbol~token -- already tokenized
        else token = self~new(symbol)
        -- Mark each symbol of the token (ensure consistency if already tokenized)
        do i = 1 to textWithoutMetaChar(self~text)~length
            if symbol~setToken(token) == .false then return .nil
            symbol = symbol~rightSymbol
        end
        token~nextSymbol = symbol
        return token
    end
    return .nil
    

::routine textHasBOL
    use strict arg text
    return text~left(5) == "[BOL]"
    

::routine textHasEOL
    use strict arg text
    return text~right(5) == "[EOL]"
    
    
::routine textWithoutMetaChar
    use strict arg text
    start = 1
    if textHasBOL(text) then start = 6
    length = text~length - start + 1
    if textHasEOL(text) then length -= 5
    return text~substr(start, length)
    
    
-------------------------------------------------------------------------------
-- Bottom to top token
::class "b2tToken" mixinclass "Token"


::method match class
    use strict arg symbol
    if symbol == .nil then return .false
    if symbol~token~isA(self) then return .true
    if symbol~b2tText~pos(self~text) == 1 then return .true
    return .false


::method tokenize class
    use strict arg symbol
    if self~match(symbol) then do
        if symbol~token <> .nil then token = symbol~token -- already tokenized
        else token = self~new(symbol)
        -- Mark each symbol of the token (ensure consistency if already tokenized)
        do i = 1 to self~text~length
            if symbol~setToken(token) == .false then return .nil
            symbol = symbol~upperSymbol
        end
        token~nextSymbol = symbol
        return token
    end
    return .nil
    
    
-------------------------------------------------------------------------------
-- Top to bottom token
::class "t2bToken" mixinclass "Token"


::method match class
    use strict arg symbol
    if symbol == .nil then return .false
    if symbol~token~isA(self) then return .true
    if symbol~t2bText~pos(self~text) == 1 then return .true
    return .false


::method tokenize class
    use strict arg symbol
    if self~match(symbol) then do
        if symbol~token <> .nil then token = symbol~token -- already tokenized
        else token = self~new(symbol)
        -- Mark each symbol of the token (ensure consistency if already tokenized)
        do i = 1 to self~text~length
            if symbol~setToken(token) == .false then return .nil
            symbol = symbol~lowerSymbol
        end
        token~nextSymbol = symbol
        return token
    end
    return .nil
    
    
-------------------------------------------------------------------------------
::class "BeginingOfStatement" subclass "Token" inherit "l2rToken"
::constant text "[BOL]>>"
::attribute label


::method init
    forward class (super) continue
    self~label = ""


::method inspectProperties
    use strict arg stream = (.IndentedStream~stdout)
    self~inspectProperties:super(stream)
    stream~lineout("label = '"self~label"'")
    
    
-------------------------------------------------------------------------------
::class "EndOfStatement" subclass "Token" inherit "l2rToken"
::constant text "><[EOL]"


-------------------------------------------------------------------------------
::class "BeginingOfFragment" subclass "Token" inherit "l2rToken"
::constant text "[BOL]|-"
::attribute label


::method init
    forward class (super) continue
    self~label = ""
    
    
::method inspectProperties
    use strict arg stream = (.IndentedStream~stdout)
    self~inspectProperties:super(stream)
    stream~lineout("label = '"self~label"'")
    
    
-------------------------------------------------------------------------------
::class "EndOfFragment" subclass "Token" inherit "l2rToken"
::constant text "-|[EOL]"


-------------------------------------------------------------------------------
::class "ContinuedOnNextLine" subclass "Token" inherit "l2rToken"
::constant text "->[EOL]"


::method tokenize class
    use strict arg symbol
    token = self~tokenize:super(symbol)
    if token <> .nil then do
        tokenizer = token~tokenizer
        tokenizer~continuationCount += 1
        nextToken = tokenizer~continuationEntries[tokenizer~continuationCount]
        if nextToken == .nil then do
            tokenizer~addError("[error] No continuation found for "token)
        end
        else do
            token~nextSymbol = nextToken~firstSymbol -- nextToken already tokenized by findEntries, but l2rTokenize is aware of that and will not stop...
        end
    end
    return token
    
    
::method alreadyVisited
    use strict arg -- none
    if self~tokenizer~dereferenceContinuations then return .true -- yes, assume always visited when dereferencing
    return self~alreadyVisited:super
    
    
-------------------------------------------------------------------------------
::class "ContinuedFromPreviousLine" subclass "Token" inherit "l2rToken"
::constant text "[BOL]>-"


::method alreadyVisited
    use strict arg -- none
    if self~tokenizer~dereferenceContinuations then return .true -- yes, assume always visited when dereferencing
    return self~alreadyVisited:super
    
    
-------------------------------------------------------------------------------
::class "l2rPath" subclass "Token" inherit "l2rToken"
::constant text "-"


::method tokenize class
    use strict arg symbol
    token = self~tokenize:super(symbol)
    if token <> .nil then do
        upperSymbol = token~firstSymbol~upperSymbol
        if .RepeatArrow~match(upperSymbol) then do
            if upperSymbol~token == .nil then do -- if not already tokenized
                repeatArrow = .RepeatArrow~tokenize(upperSymbol)
                if repeatArrow <> .nil then .Token~b2tChain(token, repeatArrow)
            end
        end
    end
    return token
    
    
-------------------------------------------------------------------------------
::class "b2tPath" subclass "Token" inherit "b2tToken"
::constant text "|"


-------------------------------------------------------------------------------
::class "t2bPath" subclass "Token" inherit "t2bToken"
::constant text "|"


-------------------------------------------------------------------------------
/*
For begining of choice and end of choice.
For iteration.
In both cases, the "+" is reached from the left and the path continues to the right.
Must have a '+' or '|' above and/or below. Thanks to this constraint, --+-- will be
tokenized as Character("+") instead of l2rCrossroads("+")

The [+] in the picture below are l2rCrossroads.
The main l2r path is 4A--4W.

     ABCDEFGHIJKLMNOPQRSTUVW
1          +---------+
2       +-[+]-------[+]-+                     +----------------+                      +-,--------+
3       |  +---------+  |                     V                |                      V          |  
4    --[+]-------------[+]--                ------------------[+]--                --[+]--------[+]--
5       +---------------+                                                             +-,-string-+
6       +---------------+

*/
::class "l2rCrossroads" subclass "Token" inherit "l2rToken"
::constant text "+"


::method match class
    use strict arg symbol
    if self~match:super(symbol) == .false then return .false
    -- Additional constraint : a vertical path is leaving from it
    hasVerticalPath = .false 
    if symbol~upperSymbol <> .nil, symbol~upperSymbol~char~matchChar(1, "+|") then hasVerticalPath = .true
    if symbol~lowerSymbol <> .nil, symbol~lowerSymbol~char~matchChar(1, "+|") then hasVerticalPath = .true
    if hasVerticalPath == .false then return .false
    -- Additional constraint : the path continues to the right
    rightSymbol = symbol~rightSymbol
    if rightSymbol == .nil then return .false
    if rightSymbol~char == " " then return .false
    if rightSymbol~char == "|" then return .false
    return .true -- must support that, see the ')' after the '+' :
    /*
       >>-push(item-+------------+)---><
                    +--,option---+                                        
    */

    
::method tokenize class
    use strict arg symbol
    token = self~tokenize:super(symbol)
    if token <> .nil then do
        tokenizer = token~tokenizer
        upperSymbol = token~firstSymbol~upperSymbol
        -- Tokenize upper first, then main, then lower. 
        -- This is to ensure that we process the continuations in the right order (when reaching the EOL).
        if .RepeatArrow~match(upperSymbol) then do
            if upperSymbol~token == .nil then do -- if not already tokenized
                repeatArrow = .RepeatArrow~tokenize(upperSymbol)
                if repeatArrow <> .nil then .Token~b2tChain(token, repeatArrow)
            end
        end
        else tokenizer~b2tTokenize(token, upperSymbol)
        tokenizer~l2rTokenize(token, token~nextSymbol)
        tokenizer~t2bTokenize(token, token~firstSymbol~lowerSymbol)
    end
    return token
    
    
::method countHorizontalPathsAbove
    if .t~istraced("countHorizontalPathsAbove") then call trace .t~traceoption("countHorizontalPathsAbove")
    use strict arg -- none
    r2lCount = 0
    l2rCount = 0
    token = self~upperToken
    do while token <> .nil
        if token~leftToken <> .nil then r2lCount +=1
        if token~rightToken <> .nil then l2rCount +=1
        token = token~upperToken
    end
    return r2lCount l2rCount

    
::method countHorizontalPathsBelow
    if .t~istraced("countHorizontalPathsBelow") then call trace .t~traceoption("countHorizontalPathsBelow")
    use strict arg -- none
    r2lCount = 0
    l2rCount = 0
    token = self~lowerToken
    do while token <> .nil
        if token~leftToken <> .nil then r2lCount +=1
        if token~rightToken <> .nil then l2rCount +=1
        token = token~lowerToken
    end
    return r2lCount l2rCount

    
::attribute isl2rDispatcher get
    -- true if at least one L2R and no R2L paths are leaving from this token (except the main path)
    expose isl2rDispatcher
    if .t~istraced("isl2rDispatcher") then call trace .t~traceoption("isl2rDispatcher")
    if var(isl2rDispatcher) then return isl2rDispatcher
    parse value self~countHorizontalPathsAbove with r2lCountAbove l2rCountAbove
    parse value self~countHorizontalPathsBelow with r2lCountBelow l2rCountBelow
    l2rCount = l2rCountAbove + l2rCountBelow
    r2lCount = r2lCountAbove + r2lCountBelow
    isl2rDispatcher = l2rCount >= 1 & r2lCount == 0
    return isl2rDispatcher

    
::attribute isr2lDispatcher get
    -- true if at least one R2L and no L2R paths are leaving from this token (except the main path)
    expose isr2lDispatcher
    if .t~istraced("isr2lDispatcher") then call trace .t~traceoption("isr2lDispatcher")
    if var(isr2lDispatcher) then return isr2lDispatcher
    parse value self~countHorizontalPathsAbove with r2lCountAbove l2rCountAbove
    parse value self~countHorizontalPathsBelow with r2lCountBelow l2rCountBelow
    l2rCount = l2rCountAbove + l2rCountBelow
    r2lCount = r2lCountAbove + r2lCountBelow
    isr2lDispatcher = r2lCount >= 1 & l2rCount == 0
    return isr2lDispatcher

    
::method inspectProperties
    use strict arg stream = (.IndentedStream~stdout)
    self~inspectProperties:super(stream)
    stream~lineout("isl2rDispatcher = "self~isl2rDispatcher)
    stream~lineout("isr2lDispatcher = "self~isr2lDispatcher)
    
    
-------------------------------------------------------------------------------
/*
For begining of choice and end of choice.
For iteration.

The [+] in the picture below are b2tCrossroads.
The main l2r path is 4A--4W.

     ABCDEFGHIJKLMNOPQRSTUVW
1         [+]-------[+]
2      [+]-+---------+--+                         [+]--------------[+]
3       |  +---------+  |                          V                |
4    ---+---------------+---                     -------------------+---
5       +---------------+
6       +---------------+

*/
::class "b2tCrossroads" subclass "Token" inherit "b2tToken"
::constant text "+"


::method tokenize class
    use strict arg symbol
    token = self~tokenize:super(symbol)
    if token <> .nil then do
        tokenizer = token~tokenizer
        -- b2t
        tokenizer~b2tTokenize(token, token~firstSymbol~upperSymbol)
        -- l2r
        rightSymbol = token~firstSymbol~rightSymbol
        if rightSymbol <> .nil, \ rightSymbol~char~matchChar(1, "| ") then tokenizer~l2rTokenize(token, rightSymbol)
        -- r2l
        -- Some paths are not fully chained (see the comment of dumpTextWithPointers for an example)
        -- Must finalize the chaining here
        leftSymbol = token~firstSymbol~leftSymbol
        if leftSymbol <> .nil, \ leftSymbol~char~matchChar(1, "+| "), leftSymbol~token <> .nil then .Token~l2rChain(leftSymbol~token, token)
    end
    return token
    
    
-------------------------------------------------------------------------------
/*
For begining of choice and end of choice.
Iteration not concerned.

The [+] in the picture below are t2bCrossroads.
The main l2r path is 4A--4W.

     ABCDEFGHIJKLMNOPQRSTUVW
1          +---------+
2       +--+---------+--+
3       | [+]-------[+] |
4    ---+---------------+---
5      [+]-------------[+]
6      [+]-------------[+]

*/
::class "t2bCrossroads" subclass "Token" inherit "t2bToken"
::constant text "+"


::method match class
    use strict arg symbol
    if self~match:super(symbol) == .false then return .false
    /*
    Additional constraint : must be mono-directional.
    Without this constraint, the [+] below were tokenized as t2bCrossroads, instead of l2rCrossroads.
    Why ? because the upper paths are tokenized before the main path, so the [+] are not yet tokenized
    when reaching them t2b.
    
          +-NORMAL----+--------+--+
          |           +--FAST--+  |
        --+-DEFAULT--[+]------[+]--+--
          |           +--FAST--+  |
          +-HIDE-----[+]------[+]-+
          |           +--FAST--+  |
          +-INACTIVE--------------+
    */
    hasLeftPath = .false
    leftSymbol = Symbol~leftSymbol
    if leftSymbol <> .nil, leftSymbol~char == "-" then hasLeftPath = .true
    hasRightPath = .false
    rightSymbol = symbol~rightSymbol
    if rightSymbol <> .nil, rightSymbol~char == "-" then hasRightPath = .true
    if hasLeftPath & hasRightPath then return .false
    return .true

    
::method tokenize class
    use strict arg symbol
    token = self~tokenize:super(symbol)
    if token <> .nil then do
        tokenizer = token~tokenizer
        -- l2r
        rightSymbol = token~firstSymbol~rightSymbol
        if rightSymbol <> .nil, rightSymbol~char <> " ", rightSymbol~char <> "|" then tokenizer~l2rTokenize(token, rightSymbol)
        -- r2l
        -- Some paths are not fully chained (see the comment of dumpTextWithPointers for an example)
        -- Must finalize the chaining here
        -- [later]
        -- The condition below will never be true because the leftSymbol has not been yet tokenized
        -- This is due to the order of the path tokenization : upper path first, then main path, then lower path
        -- Solution : must do the chaining in l2rTokenize
        leftSymbol = token~firstSymbol~leftSymbol
        if leftSymbol <> .nil, \ leftSymbol~char~matchChar(1, "+| "), leftSymbol~token <> .nil then .Token~l2rChain(leftSymbol~token, token)
        -- t2b
        tokenizer~t2bTokenize(token, token~firstSymbol~lowerSymbol)
    end
    return token
    
    
-------------------------------------------------------------------------------
/*
For end of choice.
For iteration.
In rare cases, the corner is a "." instead of a "+"

The [.] in the picture below are l2rCorner.
                          
                                .---------------[.]      
  .-SUBCLASS--Object--[.]       V                |                            
--+--------------------+--    -------------------+--
  +-MIXINCLASS--mclass-+  
  .-SUBCLASS--sclass--[.]  

*/
::class "l2rCorner" subclass "Token" inherit "l2rToken"
::constant text "."


::method match class
    use strict arg symbol
    if self~match:super(symbol) == .false then return .false
    -- Additional constraints
    rightSymbol = symbol~rightSymbol
    if rightSymbol == .nil then return .true
    if rightSymbol~char == " " then return .true
    if rightSymbol~char == "|" then return .true
    return .false
    
    
-------------------------------------------------------------------------------
/*
For begining of choice.
For Iteration.
In rare cases, the corner is a "." instead of a "+"

The [.] in the picture below are b2tCorner.

                                   [.]---------------. 
 [.]SUBCLASS--Object---.            V                |  
--+--------------------+--        -------------------+--
  +-MIXINCLASS--mclass-+  
  .-SUBCLASS--sclass---.  

*/
::class "b2tCorner" subclass "Token" inherit "b2tToken"
::constant text "."


::method tokenize class
    use strict arg symbol
    token = self~tokenize:super(symbol)
    if token <> .nil then do
        tokenizer = token~tokenizer
        rightSymbol = token~firstSymbol~rightSymbol
        if rightSymbol <> .nil, rightSymbol~char <> " ", rightSymbol~char <> "|" then tokenizer~l2rTokenize(token, rightSymbol)
    end
    return token
    
    
-------------------------------------------------------------------------------
/*
For begining of choice.
Iteration not concerned.
In rare cases, the corner is a "." instead of a "+"

The [.] in the picture below are t2bCorner.
                          
  .-SUBCLASS--Object---.                              
--+--------------------+--
  +-MIXINCLASS--mclass-+  
 [.]SUBCLASS--sclass---.  

*/
::class "t2bCorner" subclass "Token" inherit "b2tToken"
::constant text "."


::method tokenize class
    use strict arg symbol
    token = self~tokenize:super(symbol)
    if token <> .nil then do
        tokenizer = token~tokenizer
        rightSymbol = token~firstSymbol~rightSymbol
        if rightSymbol <> .nil, rightSymbol~char <> " ", rightSymbol~char <> "|" then tokenizer~l2rTokenize(token, rightSymbol)
    end
    return token
    
    
-------------------------------------------------------------------------------
/*
The repeat arrow can have an arbitrary length.
The corner is either a "+" or a ".".
If the corner is a "+" then several additional repetitions can arrive on this arrow.
The horizontal line of the repeat is tokenized from left to right.

The main l2r path is 4A--4V.
 
     ABCDEFGHIJKLMNOPQRSTUV    ABCDEFGHIJKLMNOPQRSTUV    ABCDEFGHIJKLMNOPQRSTUV    ABCDEFGHIJKLMNOP
1                                +----------------+                          
2      +----------------+        |                |        .----------------.        +-,--------+
3      V                |        V                |        V                |        V          |                      
4    -------------------+--    -------------------+--    -------------------+--    --+----------+--
                                                                                     +-,-string-+

     RepeatArrow is 3C--2C     RepeatArrow is 3C--1C     RepeatArrow is 3C--2C     RepeatArrow is 3C--2C
                                                                                   Note the + under V here...
*/
::class "RepeatArrow" subclass "Token" inherit "b2tToken" -- yes, bottom to top because matched upside down
::constant text "V"


::method match class
    use strict arg symbol
    if symbol == .nil then return .false
    if symbol~token~isA(self) then return .true
    return .RegularExpression~new("V\|*(\+|.)")~~match(symbol~b2tText)~position >= 2


::method tokenize class
    use strict arg symbol
    token = self~tokenize:super(symbol)
    if token <> .nil then do
        tokenizer = token~tokenizer
        tokenizer~b2tTokenize(token, token~nextSymbol)
    end
    return token
    
    
-------------------------------------------------------------------------------
::class "BeginingOfFragmentReference" subclass "Token" inherit "l2rToken"
::constant text "| "


-------------------------------------------------------------------------------
::class "EndOfFragmentReference" subclass "Token" inherit "l2rToken"
::constant text " |"


-------------------------------------------------------------------------------
::class "Identifier" subclass "Token" inherit "l2rToken"
::attribute hasLowerCase
::attribute hasUpperCase


::method init
    forward class (super) continue
    self~hasLowerCase = .false
    self~hasUpperCase = .false
    
    
::method match class
    use strict arg symbol
    return self~matchEndPosition(symbol) <> 0


::method matchEndPosition class
    use strict arg symbol
    if symbol == .nil then return 0
    if symbol~token~isA(self) then return symbol~token~text~length
    -- I include the characters supported in rexx symbols : ? ! and _ (but not . because also used as corner)
    return .RegularExpression~new("([:ALPHA:]|[!\?_])([:ALNUM:]|[!\?_])*")~~match(symbol~l2rText)~position


::method tokenize class
    use strict arg symbol
    endpos = self~matchEndPosition(symbol)
    if endpos <> 0 then do
        identifier = symbol~l2rText~left(endpos)
        if symbol~token <> .nil then do -- if already tokenized
            token = symbol~token
            if token~text <> identifier then do
                -- Should never happen, but...
                tokenizer = symbol~tokenizer
                tokenizer~addError(  "[error] Trying to assign two different identifiers to "token" :")
                tokenizer~addMessage("        current : '"token~text"'")
                tokenizer~addMessage("        new     : '"identifier"'")
                return .nil
            end
        end
        else do
            token = self~new(symbol)
            token~text = identifier
            token~updateObjectName
            token~hasLowerCase =  .RegularExpression~new("[:LOWER:]")~pos(identifier) <> 0
            token~hasUpperCase = .RegularExpression~new("[:UPPER:]")~pos(identifier) <> 0
        end
        -- Mark each symbol of the token (ensure consistency if already tokenized)
        do i = 1 to token~text~length
            if symbol~setToken(token) == .false then return .nil
            symbol = symbol~rightSymbol
        end
        token~nextSymbol = symbol
        return token
    end
    return .nil
    

::method inspectProperties
    use strict arg stream = (.IndentedStream~stdout)
    self~inspectProperties:super(stream)
    stream~lineout("hasLowerCase = "self~hasLowerCase)
    stream~lineout("hasUpperCase = "self~hasUpperCase)
    
    
-------------------------------------------------------------------------------
::class "Number" subclass "Token" inherit "l2rToken"


::method match class
    use strict arg symbol
    return self~matchEndPosition(symbol) <> 0


::method matchEndPosition class
    use strict arg symbol
    if symbol == .nil then return 0
    if symbol~token~isA(self) then return symbol~token~text~length
    /*
    MUST use ( \+) to recognize the "+", otherwise would be tokenized as " " followed by l2rCrossroads.
    MUST use ( -) to recognize the "-", otherwise would be tokenized as l2rPath followed by Number (positive).
    {0,1} not supported... To specify that " +" or " -" can occur 0 or 1 time, I must use a rather convoluted pattern.
    Bug ? match(" +0") returns false with position=3... should return true. No need of workaround, I test position.
    Examples :
        --2  is tokenized : l2rPath"-" l2rPath"-" Number"2"
        - -2 is tokenized : l2rPath"-" Number" -2"
        -+2  is tokenized : l2rPath"-" l2rCrossroads"+" Number"2"
        - +2 is tokenized : l2rPath"-" Number" +2"
    */
    endPosition = .RegularExpression~new("(( \+[:DIGIT:])|( -[:DIGIT:])|[:DIGIT:])[:DIGIT:]*")~~match(symbol~l2rText)~position
    if endPosition == 0 then return 0
    -- We have 1 for " ", 2 for " +", 2 for " -". In these cases, we must return 0 because this is not a number. 
    if symbol~l2rText~matchChar(endPosition, "0123456789") then return endPosition -- good, we have at least one digit
    return 0


::method tokenize class
    use strict arg symbol
    endpos = self~matchEndPosition(symbol)
    if endpos <> 0 then do
        number = symbol~l2rText~left(endpos)
        if symbol~token <> .nil then do -- if already tokenized
            token = symbol~token
            if token~text <> number then do
                -- Should never happen, but...
                tokenizer = symbol~tokenizer
                tokenizer~addError(  "[error] Trying to assign two different numbers to "token" :")
                tokenizer~addMessage("        current : '"token~text"'")
                tokenizer~addMessage("        new     : '"number"'")
                return .nil
            end
        end
        else do
            token = self~new(symbol)
            token~text = number
            token~updateObjectName
        end
        -- Mark each symbol of the token (ensure consistency if already tokenized)
        do i = 1 to token~text~length
            if symbol~setToken(token) == .false then return .nil
            symbol = symbol~rightSymbol
        end
        token~nextSymbol = symbol
        return token
    end
    return .nil


::method value
    use strict arg -- none
    return self~text~strip
    
    
-------------------------------------------------------------------------------
/*
Special characters can be escaped by surrounding them with a space before and after.
Only '+' and '-' need to be escaped but this class will escape any [:PUNCT:] character.

                   +- = -+                
    -+-SEEK-----+--+-----+-offset--       
     +-POSITION-+  +- < -+                
                   +- + -+                
                   +- ; -+

In the picture above, the escaped characters are tokenized as :
EscapedCharacter"="
EscapedCharacter"<"
EscapedCharacter"+"
EscapedCharacter";"

-- A -- 
The diagram above does not contain escaped characters and will be tokenized
l2rPath"-" l2rPath"-" Character" " Character"A" Character" "

Note : 
Only one [:PUNCT:] character is matched.
When using [:PUNCT:]+ there are some diagrams incorrectly tokenized :
rexxref\instrc.sgml : >>-CALL--+-+-name- -+--
rexxref\rexutil.sgml : >>-SysQueryProcess(" -+-TID---+- ")--
So, -- -- -- is NOT tokenized as EscapedCharacter"--"
Use -- -  - - which is tokenized as EscapedCharacter"-" EscapedCharacter"-" (careful : two spaces in the middle)
*/
::class "EscapedCharacter" subclass "Token" inherit "l2rToken"


::method match class
    use strict arg symbol
    return self~matchEndPosition(symbol) >= 3


::method matchEndPosition class
    use strict arg symbol
    if symbol == .nil then return 0
    if symbol~token~isA(self) then return symbol~token~text~length
    return .RegularExpression~new(" [:PUNCT:] ")~~match(symbol~l2rText)~position


::method tokenize class
    use strict arg symbol
    endpos = self~matchEndPosition(symbol)
    if endpos >= 3 then do
        escapedCharacter = symbol~l2rText~left(endpos)
        if symbol~token <> .nil then do -- if already tokenized
            token = symbol~token
            if token~text <> escapedCharacter then do
                -- Should never happen, but...
                tokenizer = symbol~tokenizer
                tokenizer~addError(  "[error] Trying to assign two different escaped characters to "token" :")
                tokenizer~addMessage("        current : '"token~text"'")
                tokenizer~addMessage("        new     : '"escapedCharacter"'")
                return .nil
            end
        end
        else do
            token = self~new(symbol)
            token~text = escapedCharacter
            token~updateObjectName
        end
        -- Mark each symbol of the token (ensure consistency if already tokenized)
        do i = 1 to token~text~length
            if symbol~setToken(token) == .false then return .nil
            symbol = symbol~rightSymbol
        end
        token~nextSymbol = symbol
        return token
    end
    return .nil
    
    
::method value
    use strict arg -- none
    return self~text~strip
    
    
-------------------------------------------------------------------------------
::class "Character" subclass "Token" inherit "l2rToken"


::method match class
    use strict arg symbol
    if symbol == .nil then return .false
    if symbol~token~isA(self) then return .true
    return .true -- catch all


::method tokenize class
    use strict arg symbol
    if self~match(symbol) then do
        character = symbol~char
        if symbol~token <> .nil then do -- if already tokenized
            token = symbol~token
            if token~text <> character then do
                -- Should never happen, but...
                tokenizer = symbol~tokenizer
                tokenizer~addError("[error] Trying to assign the character '"character"' to "token)
                return .nil
            end
        end
        else do
            token = self~new(symbol)
            token~text = symbol~char
            token~updateObjectName
        end
        -- Mark the unique symbol of the token (ensure consistency if already tokenized)
        if symbol~setToken(token) == .false then return .nil
        token~nextSymbol = symbol~rightSymbol
        return token
    end
    return .nil
    
    
-------------------------------------------------------------------------------
::class "Comment" subclass "Token" inherit "l2rToken"
    
    
::method match class
    use strict arg symbol
    -- Any string whose first char is at BOL and is not in " >|+." is a comment
    if symbol == .nil then return .false
    if symbol~leftSymbol <> .nil, symbol~leftSymbol~r2lText~strip <> "" then return .false -- not at BOL
    if symbol~char~verify(" >|+.", "M") <> 0 then return .false
    if symbol~char == "V" & .RepeatArrow~match(symbol) then return .false -- The "V" of the repeat arrow is NOT a comment
    return .true


::method tokenize class
    use strict arg symbol
    if self~match(symbol) then do
        comment = symbol~l2rText~strip
        if symbol~token <> .nil then do -- if already tokenized
            token = symbol~token
            if token~text <> comment then do
                -- Should never happen, but...
                tokenizer~addError(  "[error] Trying to assign two different comments to "token" :")
                tokenizer~addMessage("        current : '"token~text"'")
                tokenizer~addMessage("        new     : '"comment"'")
                return .nil
            end
        end
        else do
            token = self~new(symbol)
            token~text = comment
            token~updateObjectName
        end
        -- Mark each symbol of the token (ensure consistency if already tokenized)
        do i = 1 to token~text~length
            if symbol~setToken(token) == .false then return .nil
            symbol = symbol~rightSymbol
        end
        token~nextSymbol = symbol
        return token
    end
    return .nil

    
-------------------------------------------------------------------------------
::class sdtokenizer public -- ako namespace


::method unknown class
    -- Collisions are possible with parser classes (ex : Comment).
    -- This method forwards everything to the directory of classes of the package (ako namespace).
    -- Usage : .sdtokenizer~MyClass
    forward to (.Context~package~classes)

