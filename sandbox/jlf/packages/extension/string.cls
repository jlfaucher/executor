/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

-- Compatibility with ooRexx5
.string~define("append", .string~method("||"))

-- Compatibility with ooRexx5
.MutableBuffer~define("appendNative", .MutableBuffer~method("append"))
.MutableBuffer~define("append", "do i=1 to arg(); self~appendNative(arg(i)); end; return self")

-- Compatibility with ooRexx5
.globalRoutines["XRANGE"] = .routines~xrange

::extension String                          inherit StringPrettyPrinter
::extension String                          inherit StringCompatibilityWithOORexx5
::extension String                          inherit StringHelpers

::extension MutableBuffer                   inherit MutableBufferPrettyPrinter
::extension MutableBuffer                   inherit MutableBufferCompatibilityWithOORexx5
::extension MutableBuffer                   inherit MutableBufferHelpers

--::options trace i

::requires "extension/stringChunk.cls"
::requires "extension/stringChunkExtended.cls"


/******************************************************************************/
-- Should find a better name...
::class "StringHelpers" mixinclass Object public

::method quoted
    use strict arg quote='"'
    return quote || self~changeStr(quote, quote||quote)  || quote


::method unquoted
    use strict arg quote='"'
    if self~left(1) == quote & self~right(1) == quote then
        return self~substr(2, self~length - 2)~changeStr(quote||quote, quote)
    else
        return self


/*
Similar to ~makeArray(separator), with these differences:
- Can be caseless (makeArray is always case sensitive).
- If the string ends with a separator, an empty string item is added (makeArray does not).
  This is consistent with the size of the array literals :
      1,,2,3,               -- array of size 5, 3 items (sparse array)
      "1,,2,3,"~split(",")  -- array of size 5, 5 items
- If the separator is an empty string then the result is an array containing the whole string
  (makeArray returns an array containing each character of the string).
- When no separator is provided, the default value is the *current* platform end-of-line
  (makeArray is splitting on *any supported* platform end-of-line).
*/
::method split
    /*
    ""~split(";")                                   -- ['']
    ";"~split(";")                                  -- ['','']
    ";;"~split(";")                                 -- ['','','']
    "my first path;my second path"~split(";")       -- ['my first path','my second path']
    "my first path;my second path;"~split(";")      -- ['my first path','my second path','']
    "I go to school to learn english"~split("to")   -- ['I go ',' school ',' learn english']
    */
    use strict arg separator=.endofline, caseless=.false
    collectedSubstrings = .Array~new
    if self == "" then return collectedSubstrings
    rest = self || separator -- because I want an empty string when the last separator is followed by nothing
    do while rest <> ""
       if caseless then parse caseless value rest with first (separator) rest
       else             parse          value rest with first (separator) rest
       collectedSubstrings~append(first)
    end
    return collectedSubstrings


::method caselessSplit
    /*
    "I go TO school to learn english"~split("to")   -- ['I go ',' school ',' learn english']
    */
    use strict arg separator
    return self~split(separator, .true)


::method chunk
    use strict arg -- none
    return stringChunks(self, /*withInfos*/ .true, /*breakTokens*/ "", /*splitLevel*/ 0)[1] -- always 1 item because splitLevel == 0


::method chunks
    use strict arg -- none
    use strict named arg withInfos(1)=.true, breakTokens(1)="", splitLevel(1)=1, escapeCharacters(1)=""
    return stringChunks(self, withInfos, breakTokens, splitLevel, escapeCharacters)


::method matcher
    forward to (self~chunk)


::method join
    -- Positional arguments : zero to N objects or arrays of objects (recursively).
    -- If appender is nil then the string value (~string) of each object is joined, with self used as separator.
    -- If appender is not nil then the appender appends what he wants for each object, with self used as a separator.
    -- The appender can raise an error if the object is not supported.
    use strict named arg buffer(1)=.nil, appender(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    buffer~join(arg(1, "a"), separator: self, a: appender)
    if returnBuffer then return buffer
                    else return buffer~string


::method singularPlural
    -- Precondition: self is a number
    use strict arg singularText="", pluralText="s"
    if abs(self) <= 1 then return singularText
    return pluralText


::method singularPluralCount
    -- Precondition: self is a number
    forward message "singularPlural" continue
    return self result


::method posixClassCharacters
    -- If self is a character class name then return the corresponding character sequence
    -- otherwise return "".
    use strict arg -- none
    characterClassNames = "alnum alpha blank cntrl digit graph lower print punct space upper xdigit"
    if self~words == 1, characterClassNames~wordpos(self~lower) <> 0 then return .string~send(self)
    return ""


::method characters
    -- To be aligned with RexxText
    return self~makearray("")


/******************************************************************************/
::class "MutableBufferHelpers"  mixinclass Object public

::method chunk
    use strict arg -- none
    return stringChunks(self~string, /*withInfos*/ .true, /*breakTokens*/ "", /*splitLevel*/ 0)[1] -- always 1 item because splitLevel == 0


::method chunks
    use strict arg -- none
    use strict named arg withInfos(1)=.true, breakTokens(1)="", splitLevel(1)=1, escapeCharacters(1)=""
    return stringChunks(self~string, withInfos, breakTokens, splitLevel, escapeCharacters)


::method matcher
    forward to (self~chunk)


::method join
    use strict arg ... -- zero to N objects or arrays of objects (recursively).
    use strict named arg separator(1)="", appender(1)=.nil
    -- If appender is nil then the string value (~string) of each object is joined, with self used as separator.
    -- If appender is not nil then the appender appends what he wants for each object, with self used as a separator.
    -- The appender can raise an error if the object is not supported.
    i = 1 -- first object: no separator
    call appendArray arg(1, "a")
    return self

    appendArray: procedure expose self separator appender i
        use strict arg array
        do item over array
            if item~isA(.array) then call appendArray item
            else call appendObject item -- pass item as-is, don't convert it to string (too early)
        end
        return

    appendObject: procedure expose self separator appender i
        use strict arg object
        if i > 1 & object~string~length > 0 then call append separator
        call append object
        i += 1 -- no longer the 1st object
        return

    append: procedure expose self appender
        use strict arg object
        if .nil == appender then self~append(object~string)
                            else appender~append(object, buffer: self)
        return


::method characters
    -- To be aligned with RexxText
    return self~makearray("")


/******************************************************************************/
-- Functions compatibility with ooRexx5

-- A global routine with the same name as a builtin function overrides this function.
::routine xrange public
    if arg() == 0 then return "XRANGE"()
    buffer = .MutableBuffer~new
    i = 1
    do while i <= arg()
        if arg(i, "e") then arg1 = arg(i)
                       else arg1 = "00"x
        if arg1~length == 1 then do
            i += 1
            if arg(i, "e") then arg2 = arg(i)
                           else arg2 = "FF"x
            if arg2~length <> 1 then raise syntax 40.23 array("XRANGE", "Positional", i, arg2)
            buffer~append("XRANGE"(arg1, arg2))
        end
        else do
            characterSequence = arg1~posixClassCharacters
            if characterSequence \== "" then buffer~append(characterSequence) -- Don't test with <> because the sequence for "blank" is considered empty!
            else raise syntax 40.28 array("XRANGE", "Positional", i, arg1)
        end
        i += 1
    end
    return buffer~string


/******************************************************************************/
::class "StringCompatibilityWithOORexx5" mixinclass Object public

::method alnum class
    use strict arg -- none
    return "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"


::method alpha class
    use strict arg -- none
    return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"


::method blank class
    use strict arg -- none
    return "09 20"x


::method cntrl class
    use strict arg -- none
    return "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 7F"x


::method digit class
    use strict arg -- none
    return "0123456789"


::method graph class
    use strict arg -- none
    -- !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_` abcdefghijklmnopqrstuvwxyz{|}
    return "21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F 40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F 60 20 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F 70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D"x


::method lower class
    use strict arg -- none
    return "abcdefghijklmnopqrstuvwxyz"


::method print class
    use strict arg -- none
    -- <space>!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_` abcdefghijklmnopqrstuvwxyz{|}~
    return "20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F 40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F 60 20 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F 70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D"x


::method punct class
    use strict arg -- none
    -- !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~
    return "21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 3A 3B 3C 3D 3E 3F 40 5B 5C 5D 5E 5F 60 7B 7C 7D 7E"x


::method space class
    use strict arg -- none
    return "09 0A 0B 0C 0D 20"x


::method upper class
    use strict arg -- none
    return "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


::method xdigit class
    use strict arg -- none
    return "0123456789ABCDEFabcdef"


::method contains
    -- regex.cls uses the method .String~contains which is available only from ooRexx v5.
    forward message "pos" continue
    return result <> 0


::method caselessContains
    -- ooRexx v5
    forward message "caselessPos" continue
    return result <> 0


::method startsWith
    -- ooRexx v5
    forward message "pos" continue
    return result == 1


::method caselessStartsWith
    -- ooRexx v5
    forward message "caselessPos" continue
    return result == 1


::method endsWith
    -- ooRexx v5
    use strict arg substr
    start = self~length - substr~length + 1
    if start < 1 then return .false
    return self~pos(substr, start) == start


::method caselessEndsWith
    -- ooRexx v5
    use strict arg substr
    start = self~length - substr~length + 1
    if start < 1 then return .false
    return self~caselessPos(substr, start) == start


::method "[]"
    -- ooRexx v5
    use strict arg n, length=1
    maxLength = self~length - n + 1 -- don't care about n<=0, will be caught by substr
    if maxLength <= 0 then return ""
    return self~substr(n, min(length, maxLength))


/******************************************************************************/
::class "StringPrettyPrinter" mixinclass Object public

::method ppString
    use arg surroundByQuotes=.true -- keep it for the moment, still needed from rgf_util2
    use named arg ppOptions. = (.Stem~new), ppOptions.surroundByQuotes = (surroundByQuotes)
    -- strings are surrounded by quotes, except string numbers.
    if self~dataType("N") then do
        if self < 0 then return self -- the first character is the minus sign
        if self~matchChar(1, " +") then return self -- the first character is already a space or a plus
        return " "self               -- the first character is a space (could also display a plus sign)
    end
    pp = self
    if ppOptions.surroundByQuotes then pp = pp~quoted("'")
    return escape3(pp) -- Use 0xXX notation for escaped characters


/******************************************************************************/
::class "MutableBufferCompatibilityWithOORexx5" mixinclass Object public

::method "[]"
    -- ooRexx v5
    use strict arg n, length=1
    maxLength = self~length - n + 1 -- don't care about n<=0, will be caught by substr
    if maxLength <= 0 then return ""
    return self~substr(n, min(length, maxLength))


/******************************************************************************/
::class "MutableBufferPrettyPrinter" mixinclass Object public

::method ppString
    use arg surroundByQuotes=.true -- keep it for the moment, still needed from rgf_util2
    -- Mutable buffers are prefixed with "M"
    pp = "M'"self~string"'"
    -- Use 0xXX notation for escaped character
    return escape3(pp)


/******************************************************************************/
::routine ppHexNumber public
    -- Helper to display an hexadecimal value: 0 --> 00x, 255 --> FFx
    -- The value can be negative: -1 --> -01x
    use strict arg number
    if \datatype(number, "W") then return "not a whole number"
    sign = ""
    if sign(number) < 0 then sign = "-"
    number = abs(number)
    if number < 256 then size = 2
    else if number < 65536 then size = 4
    else if number < 16777216 then size = 6
    else size = 8
    return sign || number~d2x(size) || "x"


/******************************************************************************/
-- Copied from rgf_util2
-- Escape non-printable chars by printing them between square brackets [].
::routine escape3 public
  parse arg a1

  --non_printable=xrange("00"x,"1F"x)||"FF"x
  non_printable="00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F FF"x
  res=""

  do while a1\==""
     pos1=verify(a1, non_printable, "M")
     if pos1>0 then
     do
        pos2=verify(a1, non_printable, "N" , pos1)

        if pos2=0 then
           pos2=length(a1)+1

        if pos1=1 then
        do
           parse var a1 char +(pos2-pos1) a1
           bef=""
        end
        else
           parse var a1 bef +(pos1-1) char +(pos2-pos1) a1

        if res=="" then
        do
           if bef \=="" then res=bef -- res=enquote2(bef) '|| '
        end
        else
        do
           res=res||bef -- res=res '||' enquote2(bef) '|| '
        end

        res=res || '['char~c2x']'
     end
     else
     do
        if res<>""  then
           res=res||a1 -- res=res '||' enquote2(a1)
        else
           res=a1

        a1=""
     end
  end
  return res
