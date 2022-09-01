::requires "stringChunk.cls"

::extension stringChunk

::method matcher public
    /*
    Pattern matching by equality (whole) or by inclusion (not whole), caseless or not.
    If the package regex.cls is loaded, then the pattern (a StringChunk) can be a regular expression prefixed by "/".
    When whole, and the pattern is not a regular expression, then the charecter "*" is recognized as a generic character when first or last character.
    When not whole, and the pattern is not a regular expression, then the character "^" is recognized as the metacharacter 'begining of string' when first character.
    When not whole, and the pattern is not a regular expression, then the character "$" is recognized as the metacharacter 'end of string' when last character.
    The returned result is a closure (matcher) which implements the pattern matching, or .nil if error.
    The pattern matching is tested when the closure is evaluated with a string passed as argument.

    Examples:

        -- caseless equality
        matcher = "object"~matcher
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- false

        -- caseless equality with generic character
        matcher = "*object"~matcher
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- true

        -- caseless inclusion
        matcher = "object"~matcher(wholeString:.false)
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- true

        -- caseless inclusion, regular expression: "object" at the begining or at the end.
        matcher = "/^object|object$"~matcher(wholeString:.false)
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- true
        say matcher~("my ObjeCts") -- false
    */

    stringChunkPattern = self -- stringChunkPattern is a StringChunk
    stringPattern = stringChunkPattern~string

    use strict arg -- none
    use strict named arg wholeString(1)=.true, caseless(1)=.true, trace(1)=.false, displayer(1)=.traceOutput, prefix(1)=""
    matcher = .nil

    firstCharIsQuoted = stringChunkPattern~quotedFlags~left(1) == "1"
    lastCharIsQuoted = stringChunkPattern~quotedFlags~right(1) == "1"

    -- Build a description of the matcher, will be displayed when tracing the filters.
    -- Remember: ALWAYS build this description, even if trace==.false.
    -- It's because the trace can be done later, by calling directly the routine traceMatcher.
    description = .array~new
    description~append("description:" "stringChunkPattern="stringPattern~quoted "wholeString="wholeString "caseless="caseless)

    regularExpression = \firstCharIsQuoted & stringPattern~left(1) == "/"
    if regularExpression then do
        if .Pattern~isa(.class), .Pattern~hasMethod("compile") then do
            -- Good, the package regex.cls is loaded
            stringPattern = stringPattern~substr(2) -- remove the "/"
        end
        else raise syntax 93.900 array("Regular expression" stringPattern~quoted "not supported: The package regex.cls is not loaded")
    end

    if regularExpression then do
        -- Remember: ALWAYS build this description, even if trace==.false.
        description~append("stringPattern="stringPattern~quoted)
        if caseless then description~append("pattern = .Pattern~compile(stringPattern, .RegexCompiler~new(.RegexCompiler~caseless))")
        else             description~append("pattern = .Pattern~compile(stringPattern)")

        signal on syntax name patternCompileError
        if caseless then pattern = .Pattern~compile(stringPattern, .RegexCompiler~new(.RegexCompiler~caseless))
        else             pattern = .Pattern~compile(stringPattern)

        if wholeString then matcher = {expose description pattern; use strict arg string; return pattern~matches(string)}
        else                matcher = {expose description pattern; use strict arg string; return pattern~find(string)~matched}
    end
    else do
        -- the pattern remains a string
        leftStar = \firstCharIsQuoted & stringPattern~left(1) == "*"
        rightStar = \lastCharIsQuoted & stringPattern~right(1) == "*"
        leftCaret = \firstCharIsQuoted & stringPattern~left(1) == "^"
        rightDollar = \lastCharIsQuoted & stringPattern~right(1) == "$"
        if (leftStar & rightStar) | (leftCaret & rightDollar) then do
            if stringPattern~length <= 2 then stringPattern = "" -- "*" or "**" or "^" or "$" or "^$"--> ""
            else stringPattern = stringPattern~substr(2, stringPattern~length - 2) -- "*...*" or "^...$" --> "..."
        end
        else if leftStar | leftCaret then stringPattern = stringPattern~substr(2)
        else if rightStar | rightDollar then stringPattern = stringPattern~left(stringPattern~length - 1)

        description~append("stringPattern="stringPattern~quoted)
        if stringPattern == "" then matcher = {expose description stringPattern; return .true}
        else if wholeString then do
            -- leftCaret and rightDollar have no impact
            if \leftStar & \rightStar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~equals(stringPattern)}
            end
            else if \leftStar & rightStar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~equals(stringPattern)}
            end
            else if leftStar & \rightStar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~equals(stringPattern)}
            end
            else do -- leftStar & rightStar
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessPos(stringPattern) <> 0}
                else             matcher = {expose description stringPattern; use strict arg string; return string~pos(stringPattern) <> 0}
            end
        end
        else do -- \wholeString
            -- leftStar and rightStar have no impact
            if \leftCaret & \rightDollar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessPos(stringPattern) <> 0}
                else             matcher = {expose description stringPattern; use strict arg string; return string~pos(stringPattern) <> 0}
            end
            else if \leftCaret & rightDollar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~equals(stringPattern)}
            end
            else if leftCaret & \rightDollar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~equals(stringPattern)}
            end
            else do -- leftCarret & rightDollar
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~equals(stringPattern)}
            end
        end
    end
    if trace, .nil <> displayer then call traceMatcher matcher, displayer, prefix
    return matcher~doer

    patternCompileError:
        raise syntax 93.900 array("Regular expression" stringPattern~quoted ":" condition("O")~message)


::routine traceMatcher public
    use strict arg matcher, displayer, prefix

    -- The displayer must support either ~sayTrace or ~say.
    display = "sayTrace"
    if \displayer~hasMethod(display) then display = "say"

    -- matcher is a closure created by .StringChunk~matcher.
    -- The variables of .StringChunk~matcher have been captured, and can be retrieved, in particular the description.
    do line over matcher~variables["DESCRIPTION"]
        displayer~send(display, prefix || line)
    end
    do line over matcher~source
        displayer~send(display, prefix || "matcher:" line)
    end
