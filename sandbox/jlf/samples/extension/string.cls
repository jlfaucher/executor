/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i

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


::method contains
    -- regex.cls uses the method .String~contains which is available only from ooRexx v5.
    forward message "pos" continue
    return result <> 0


::method caselessContains
    -- ooRexx v5
    forward message "caselessPos" continue
    return result <> 0


/******************************************************************************/
::class "StringPrettyPrinter" mixinclass Object public

::method ppString
    use strict arg surroundByQuotes=.true
    -- strings are surrounded by quotes, except string numbers.
    if self~dataType("N") then return self
    pp = self
    if surroundByQuotes then pp = pp~quoted("'")
    return escape3(pp) -- JLF : Use 0xXX notation for escaped characters


/******************************************************************************/
::class "EncodedString" mixinclass Object public

::attribute text get
    expose text -- attribute added on the String instance
    use strict arg -- none
    if \var("text") then do -- no stored counterpart
        text = .RexxText~new(self) -- store the Text counterpart created from itself with default encoding
    end
    return text

::attribute text set
    expose text -- attribute added on the String instance
    use strict arg aText
    if \var("text") then do -- no stored counterpart
        if \aText~isA(.RexxText) then raise syntax 93.900 array("EncodeString: the counterpart must be a Text")
        text = aText -- store the Text counterpart passed by argument
    end
    else do
        -- A Text counterpart is already assigned.
        -- Raise an error if different from the current one
        if aText <> text then raise syntax 93.900 array("EncodedString: a Text counterpart is already assigned")
    end


::method makeRexxText
    return self~text


/******************************************************************************/
::class "RexxTextInitializer" mixinclass Object public

::method init
    expose string encoding analyzed
    use strict arg string, encoding="default"
    if \string~isA(.String) then raise syntax 93.900 array("Text:" string "is not a String")
    encoding = .Encoding~factory(encoding)
    analyzed = .false
    string~text = self -- store itself as counterpart of string


/*
Don't activate this one.
I need to get the control when concatenating strings
::method makestring
    expose string
    return string
*/


::attribute string get
    expose string
    use strict arg -- none
    return string


::attribute encoding get
    expose encoding
    use strict arg -- none
    return encoding


::attribute encoding set
    expose string encoding
    use strict arg newEncoding
    newEncoding = .Encoding~factory(newEncoding)
    if encoding <> newEncoding then do
        encoding = newEncoding
        analyzed = .false
        -- todo : check the conformity of string
        -- todo: graphemes count & indexes
    end


/******************************************************************************/
::class "RexxTextPrettyPrinter" mixinclass Object public

::method ppString
    -- Texts are prefixed with "T"
    pp = "T'"self~string"'"
    -- Use 0xXX notation for escaped character
    return escape3(pp)


/******************************************************************************/
::class "RexxTextOperators" mixinclass Object public

::method " "
    use strict arg right
    right = right~request("rexxtext")
    if .nil == right then return -- no result: try the alternative message
    encoding = EncodingForConcatenation(self, right)
    return encoding~concatenate(self, encoding~spaceCharacter, right)


::method " op:right"
    use strict arg left
    left = left~request("rexxtext")
    if .nil == left then return -- no result: try the alternative message
    encoding = EncodingForConcatenation(left, self)
    return encoding~concatenate(left, encoding~spaceCharacter, self)


::method "||"
    use strict arg right
    right = right~request("rexxtext")
    if .nil == right then return -- no result: try the alternative message
    encoding =EncodingForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "||op:right"
    use strict arg left
    left = left~request("rexxtext")
    if .nil == left then return -- no result: try the alternative message
    encoding =EncodingForConcatenation(left, self)
    return encoding~concatenate(left, self)


::method "" -- abuttal
    use strict arg right
    right = right~request("rexxtext")
    if .nil == right then return -- no result: try the alternative message
    encoding =EncodingForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "op:right" -- abuttal
    use strict arg left
    left = left~request("rexxtext")
    if .nil == left then return -- no result: try the alternative message
    encoding = EncodingForConcatenation(left, self)
    return encoding~concatenate(left, self)


::routine EncodingForConcatenation
    use strict arg leftText, rightText
    return .Encoding~forConcatenation(leftText~encoding, leftText~string~isASCII, rightText~encoding, rightText~string~isASCII)


/******************************************************************************/
::class "Encoding" public

::attribute default class get
    expose default
    use strict arg -- none
    if \var("default") then default = .ByteEncoding
    return default


::attribute default class set
    expose default
    use strict arg encodingName
    default = self~factory(encodingName)


::method factory class
    use strict arg encoding
    if encoding~isA(.Class), encoding~isSubClassOf(self) then return encoding
    if "default"~caselessEquals(encoding) then return .Encoding~default
    if "byte"~caselessEquals(encoding) then return .ByteEncoding
    if "utf-8"~caselessEquals(encoding) then return .UTF8Encoding
    if "utf8"~caselessEquals(encoding) then return .UTF8Encoding
    if "utf-16"~caselessEquals(encoding) then return .UTF16Encoding
    if "utf16"~caselessEquals(encoding) then return .UTF16Encoding
    raise syntax 93.900 array("Encoding: '"encoding"' is not supported")


::method forConcatenation class
    use strict arg leftEncoding, leftIsASCII, rightEncoding, rightIsASCII
    if leftEncoding == rightEncoding then return leftEncoding
    if leftIsASCII, leftEncoding == .ByteEncoding, rightEncoding == .UTF8Encoding then return rightEncoding
    if rightIsASCII, rightEncoding == .ByteEncoding, leftEncoding == .UTF8Encoding then return leftEncoding
    raise syntax 93.900 array("Encoding: cannot concatenate" leftEncoding "with" rightEncoding)


::method concatenate class
    -- Arguments : zero to N text.
    s = ""
    do i = 1 to arg()
        s ||= arg(i)~string
    end
    return .RexxText~new(s, self)


/******************************************************************************/
::class "ByteEncoding" subclass Encoding public

::attribute SpaceCharacter class get
    expose spaceCharacter
    -- The Strings constants are made unique by the interpreter (only one occurence).
    -- Must memorize the Text with a copy of the string constant, otherwise error "a Text counterpart is already assigned"
    if \var("spaceCharacter") then spaceCharacter = .RexxText~new(.String~new(" "), self)
    return spaceCharacter


/******************************************************************************/
::class "UTF8Encoding" subclass Encoding public


::method SpaceCharacter class
    expose spaceCharacter
    -- The Strings constants are made unique by the interpreter (only one occurence).
    -- Must memorize the Text with a copy of the string constant , otherwise error "a Text counterpart is already assigned"
    if \var("spaceCharacter") then spaceCharacter = .RexxText~new(.String~new(" "), self)
    return spaceCharacter


/******************************************************************************/
::class "UTF16Encoding" subclass Encoding public

::method SpaceCharacter class
    expose spaceCharacter
    -- The Strings constants are made unique by the interpreter (only one occurence).
    -- Must memorize the Text with a copy of the string constant , otherwise error "a Text counterpart is already assigned"
    if \var("spaceCharacter") then spaceCharacter = .RexxText~new(.String~new("0020"x), self)
    return spaceCharacter


/******************************************************************************/
-- Copied from rgf_util2
-- Escape non-printable chars by printing them between square brackets [].
::routine escape3 public
  parse arg a1

  res=""

  do while a1\==""
     pos1=verify(a1, .rgf.non.printable, "M")
     if pos1>0 then
     do
        pos2=verify(a1, .rgf.non.printable, "N" , pos1)

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
