/*
This is an adaptation of stringChunkExtended.cls to ensure compatibility
with ooRexx 4.2, ooRexx 5 and Executor5-bulk.
Only objects understanding the "call" message are supported as doers;
Routines are such objects.

Keep it compatible with official ooRexx 4.2.
Unfortunately, regex.cls is not supported by ooRexx 4.2.
It depends on string~contains which is not available with ooRexx 4.2.
*/

-- Compatibility with ooRexx5: regex.cls depends on StringTable
if \ .stringtable~isa(.class) then .environment["STRINGTABLE"] = .directory
-- Optional: load the package regex.cls
call loadPackage "regex/regex.cls"

::requires "extension/stringChunk.cls"

-------------------------------------------------------------------------------
::class "StringChunkMatcher" public
-------------------------------------------------------------------------------

::attribute description get
::attribute stringPattern get
::attribute source get


::method matcher class
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
        matcher = matcher("object")
        say matcher~match("ObjeCt") -- true
        say matcher~match("my ObjeCt") -- false

        -- caseless equality with generic character
        matcher = matcher("*object")
        say matcher~match("ObjeCt") -- true
        say matcher~match("my ObjeCt") -- true

        -- caseless inclusion
        matcher = matcher("object", /*wholeString:*/.false)
        say matcher~match("ObjeCt") -- true
        say matcher~match("my ObjeCt") -- true

        -- caseless inclusion, regular expression: "object" at the begining or at the end.
        matcher = matcher("/^object|object$", /*wholeString:*/.false)
        say matcher~match("ObjeCt") -- true
        say matcher~match("my ObjeCt") -- true
        say matcher~match("my ObjeCts") -- false
    */

    expose description stringPattern pattern -- for buildMatcher
    use strict arg stringChunkPattern, - -- stringChunkPattern can be a String or a StringChunk
    /*use strict named arg*/ wholeString=.true, caseless=.true, trace=.false, displayer=.traceOutput, prefix=""

    if stringChunkPattern~isa(.String) then do
        stringChunkPattern = stringChunks(stringChunkPattern, /*withInfos*/ .true, /*breakTokens*/ "", /*splitLevel*/ 0)[1] -- always 1 item because splitLevel == 0
    end
    else if \ stringChunkPattern~isa(.StringChunk) then do
        raise syntax 88.900 array("The first argument must be a String or a StringChunk; found" quoted(stringChunkPattern))
    end

    matcher = .nil
    stringPattern = stringChunkPattern~string
    pattern = .nil

    firstCharIsQuoted = stringChunkPattern~quotedFlags~left(1) == "1"
    lastCharIsQuoted = stringChunkPattern~quotedFlags~right(1) == "1"

    -- Build a description of the matcher, will be displayed when tracing the filters.
    -- Remember: ALWAYS build this description, even if trace==.false.
    -- It's because the trace can be done later, by calling directly the routine traceMatcher.
    description = .array~new
    description~append("description:" "stringChunkPattern="quoted(stringPattern) "wholeString="wholeString "caseless="caseless)

    regularExpression = \firstCharIsQuoted & stringPattern~left(1) == "/"
    if regularExpression then do
        if .Pattern~isa(.class), .Pattern~hasMethod("compile") then do
            -- Good, the package regex.cls is loaded
            stringPattern = stringPattern~substr(2) -- remove the "/"
        end
        else raise syntax 93.900 array("Regular expression" quoted(stringPattern) "not supported: The package regex.cls is not loaded")
    end

    if regularExpression then do
        -- Remember: ALWAYS build this description, even if trace==.false.
        description~append("stringPattern="quoted(stringPattern))
        if caseless then description~append("pattern = .Pattern~compile(stringPattern, .RegexCompiler~new(.RegexCompiler~caseless))")
        else             description~append("pattern = .Pattern~compile(stringPattern)")

        signal on syntax name patternCompileError
        if caseless then pattern = .Pattern~compile(stringPattern, .RegexCompiler~new(.RegexCompiler~caseless))
        else             pattern = .Pattern~compile(stringPattern)

        if wholeString then matcher = self~buildMatcher("expose description pattern; use strict arg string; return pattern~matches(string)")
        else                matcher = self~buildMatcher("expose description pattern; use strict arg string; return pattern~find(string)~matched")
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

        description~append("stringPattern="quoted(stringPattern))
        if stringPattern == "" then matcher = self~buildMatcher("expose description stringPattern; return .true")
        else if wholeString then do
            -- leftCaret and rightDollar have no impact
            if \leftStar & \rightStar then do
                if caseless then matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~caselessEquals(stringPattern)")
                else             matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~equals(stringPattern)")
            end
            else if \leftStar & rightStar then do
                if caseless then matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~caselessEquals(stringPattern)")
                else             matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~equals(stringPattern)")
            end
            else if leftStar & \rightStar then do
                if caseless then matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~caselessEquals(stringPattern)")
                else             matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~equals(stringPattern)")
            end
            else do -- leftStar & rightStar
                if caseless then matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~caselessPos(stringPattern) <> 0")
                else             matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~pos(stringPattern) <> 0")
            end
        end
        else do -- \wholeString
            -- leftStar and rightStar have no impact
            if \leftCaret & \rightDollar then do
                if caseless then matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~caselessPos(stringPattern) <> 0")
                else             matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~pos(stringPattern) <> 0")
            end
            else if \leftCaret & rightDollar then do
                if caseless then matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~caselessEquals(stringPattern)")
                else             matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~equals(stringPattern)")
            end
            else if leftCaret & \rightDollar then do
                if caseless then matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~caselessEquals(stringPattern)")
                else             matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~equals(stringPattern)")
            end
            else do -- leftCarret & rightDollar
                if caseless then matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~caselessEquals(stringPattern)")
                else             matcher = self~buildMatcher("expose description stringPattern; use strict arg string; return string~equals(stringPattern)")
            end
        end
    end
    if trace, .nil <> displayer then call traceMatcher matcher, displayer, prefix
    return matcher

    patternCompileError:
        raise syntax 93.900 array("Regular expression" quoted(stringPattern) ":" condition("O")~message)


::method buildMatcher class
    expose description stringPattern pattern
    use strict arg source
    -- Pfff... A method added with ~enhanced has NO ACCESS to the main variable pool.
    -- return self~enhanced(.directory~of(("MATCH", source)), description, stringPattern, pattern, source)
    matcher = self~new(description, stringPattern, pattern, source)
    matcher~setMethod("MATCH", source, "OBJECT")
    return matcher


::method init
    expose description stringPattern pattern source
    use strict arg description, stringPattern, pattern, source

    if \ source~isa(.Array) then source = .array~of(source)


-------------------------------------------------------------------------------
-- Routines
-------------------------------------------------------------------------------

::routine matcher public
    arguments = arg(1, "array")
    return .StringChunkMatcher~sendWith("matcher", arguments)


::routine traceMatcher public
    use strict arg matcher, displayer, prefix

    -- The displayer must support either ~sayTrace or ~say.
    display = "sayTrace"
    if \displayer~hasMethod(display) then display = "say"

    -- matcher is a StringChunkMatcher created by the "matcher" routine.
    -- The description is an array of strings.
    do line over matcher~description
        displayer~send(display, prefix || line)
    end
    -- The source is an array of strings.
    do line over matcher~source
        displayer~send(display, prefix || "matcher:" line)
    end


::routine quoted public
    use strict arg string, quote='"'
    return quote || string~changestr(quote, quote~copies(2)) || quote


::routine loadPackage
    use strict arg filename
    signal on syntax name loadPackageError
    .context~package~loadPackage(filename)
    return .true
    loadPackageError:
    return .false
