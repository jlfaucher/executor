/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

-- Compatibility with ooRexx5
.string~define("append", .string~method("||"))

-- Compatibility with ooRexx5
.MutableBuffer~define("appendLegacy", .MutableBuffer~method("append"))
.MutableBuffer~define("append", "do i=1 to arg(); self~appendLegacy(arg(i)); end")

/*
Initialization of the Unicode characters.
Not possible to use a method 'activate' or 'init'

       *-* Compiled method INIT with scope "Object"
       *-* Compiled method NEW with scope "RexxText"
   955 *-* return .RexxText~new(buffer~string, self)
   658 *-* utf8 = .UTF8_Encoding~encode(codepoint)
       *-* Compiled method NEW with scope "Object"
   631 *-* character = .UnicodeCharacter~new(codepoint, name)
   624 *-* self~declareCharacter("0301", "combining acute accent")
  1117 *-* ::class "GraphemeSupplier" public subclass Supplier
REX0093E: Error 93 running /local/rexx/oorexx/executor/sandbox/jlf/samples/extension/string.cls line 955:  Incorrect call to method
REX0432E: Error 93.902:  Too many positional arguments in invocation of method; 0 expected

*/
.Unicode~initialize


/*
These declarations must be in this source file, not in extensions.cls.
Otherwise same error as above.
*/
::extension String                          inherit EncodedString
::extension RexxText                        inherit RexxTextInitializer RexxTextPrettyPrinter RexxTextContents RexxTextOperators RexxTextStringInterface

--::options trace i

/******************************************************************************/
-- Functions compatibility with ooRexx5

-- A global routine with the same name as a builtin function overrides this function.
::routine xrange public
    if arg() == 0 then return "XRANGE"()
    buffer = .mutableBuffer~new
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


::method concatenateSeparated
    -- Arguments : zero to N strings.
    -- self is the separator
    bufferSize = 0
    do i = 1 to arg()
        currentLength = arg(i)~length
        if i > 1 & currentLength > 0 then bufferSize += self~length
        bufferSize += currentLength
    end
    buffer = .mutableBuffer~new(, bufferSize)
    do i = 1 to arg()
        currentLength = arg(i)~length
        if i > 1 & currentLength > 0 then buffer~append(self)
        buffer~append(arg(i))
    end
    return buffer~string


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
::class "EncodedString" mixinclass Object public

/*
    aString
     ▲  text --------⮸ aRexxText
     │                     indexer (anEncoding)
     │                          codepoints (sequential access)
     │                          graphemes  (direct access)
     +-----------------------⮷- string
*/

::attribute text get
    expose text -- attribute added on the String instance
    use strict arg encoding="default"
    if \var("text") then do -- no stored counterpart
        text = .RexxText~new(self, encoding) -- store the RexxText counterpart created from itself with specified encoding
    end
    else if arg(1, "e") then do
        -- If the encoding was explicitely specified then change the encoding
        encoding = .Encoding~factory(encoding, self)
        if text~encoding <> encoding then text~encoding=encoding
    end
    return text


::attribute text set -- private
    -- Can't declare this method private, because it's used by RexxText
    -- But the assignment is secured:
    -- If not yet linked to a RexxText then only a RexxText linked to this string can be assigned
    -- If already linked to a RexxText then only this RexxText is accepted
    expose text -- attribute added on the String instance
    use strict arg aText
    if \var("text") then do -- no stored counterpart
        if aText~isA(.RexxText), aText~string~identityHash == self~identityHash then do
            text = aText -- store the RexxText counterpart passed by argument
        end
        else raise syntax 93.900 array("EncodedString: the counterpart must be a RexxText linked to this String")
    end
    else do
        -- A RexxText counterpart is already assigned.
        -- Raise an error if different from the current one
        if aText~identityHash <> text~identityHash then do
            -- Must test identityHash because operator "<>" overloaded to test the Unicode characters
            raise syntax 93.900 array("EncodedString: a RexxText counterpart is already assigned")
        end
    end


::method makeRexxText
    use strict arg -- none
    return self~text


::method copy
    -- If the string is linked to a RexxText then the RexxText must also be cloned.
    expose text
    use strict arg -- none
    if \var("text") then return self~copy:super
    textCopy = text~copy
    return textCopy~string


/******************************************************************************/
::class "RexxTextInitializer" mixinclass Object public

::method init
    expose indexer -- The RexxText is not referencing directly the String, it's the indexer
    use strict arg string, encoding="default"
    .validate~classtype("1", string, .string)
    encoding = .Encoding~factory(encoding, string)
    indexer = encoding~analyze(string)
    -- if we reach this point, it means the analyze is ok, otherwise an error was raised.
    string~text = self -- store itself as counterpart of string


/*
Don't activate this one.
I need to get the control when concatenating strings
[later]
In fact, this method is NEVER called, even if activated.
It's because RexxText is a base class, so the C++ method primitiveMakeString is
called by the interpreter. This method returns .nil.
No message sent, so no way to return something.

::method makestring
    expose string
    return string
*/


::attribute string get
    expose indexer
    use strict arg -- none
    return indexer~string


::attribute text get
    use strict arg -- none
    return self


::attribute encoding get
    expose indexer
    use strict arg -- none
    return indexer~class


::attribute encoding set
    expose indexer
    use strict arg newEncoding
    newEncoding = .Encoding~factory(newEncoding, indexer~string)
    if indexer~class <> newEncoding then do
        indexer = newEncoding~analyze(indexer~string)
    end


-- Must use an attribute to return the indexer, because the indexer is not visible from the other mixinclasses
::attribute indexer private


::method copy
    use strict arg -- none
    selfCopy = self~copy:super -- for the moment, the copy has the same indexer as self
    indexerCopy = selfCopy~indexer~copy -- creates a copy of the indexer and also a copy of the indexed string
    selfCopy~indexer = indexerCopy -- from now, the copy has its own indexer, which has its own indexed string
    stringCopy = indexerCopy~string -- this string copy is not yet linked to the RexxText copy
    stringCopy~text = selfCopy -- from now, the string copy is linked to its RexxText counterpart
    return selfCopy


/******************************************************************************/
::class "RexxTextPrettyPrinter" mixinclass Object public

::method ppString
    -- Should honor surroundByQuotes
    -- Should return a RexxText, but then how to display it ?

    use arg surroundByQuotes=.true -- keep it for the moment, still needed from rgf_util2
    -- Texts are prefixed with "T"
    pp = "T'"self~string"'"
    -- Use 0xXX notation for escaped character
    return escape3(pp)


/******************************************************************************/
::class "RexxTextContents" mixinclass Object public

-- Remember: don't use expose indexer, because it's not visible. Must use self~indexer.

::method description
    forward to (self~indexer)


::method errors
    forward to (self~indexer)


::method isByte
    forward to (self~indexer~class)


::method isUnicode
    forward to (self~indexer~class)


::method isUTF8
    forward to (self~indexer~class)


::method isWTF8
    forward to (self~indexer~class)


::method isUTF16 -- true if UTF-16BE or UTF-16LE
    forward to (self~indexer~class)


::method isUTF16BE
    forward to (self~indexer~class)


::method isUTF16LE
    forward to (self~indexer~class)


::method isWTF16 -- true is WTF-16BE or WTF-16LE
    forward to (self~indexer~class)


::method isWTF16BE
    forward to (self~indexer~class)


::method isWTF16LE
    forward to (self~indexer~class)


::method isUTF32
    forward to (self~indexer~class)


::method isUTF32BE
    forward to (self~indexer~class)


::method isUTF32LE
    forward to (self~indexer~class)


::method codepoints
    forward to (self~indexer)


/*
-- No direct access to codepoint, not needed.
::method codepoint
    forward to (self~indexer)
*/


::method length -- number of graphemes
    use strict arg -- none
    return self~indexer~graphemeCount


::method graphemes
    forward to (self~indexer)


::method grapheme
    forward to (self~indexer)


-- UTF-8 representation
::method UTF8
    use strict arg -- none
    if self~isUTF8 then return self
    forward to (self~indexer) -- always new String and new RexxText


-- WTF-8 representation
::method WTF8
    use strict arg -- none
    if self~isWTF8 then return self
    forward to (self~indexer) -- always new String and new RexxText


-- UTF-16BE or UTF-16LE representation
::method UTF16
    use strict arg -- none
    if self~isUTF16 then return self
    forward to (self~indexer) -- always new String and new RexxText


-- UTF-16BE representation
::method UTF16BE
    use strict arg -- none
    if self~isUTF16BE then return self
    forward to (self~indexer) -- always new String and new RexxText


-- UTF-16LE representation
::method UTF16LE
    use strict arg -- none
    if self~isUTF16LE then return self
    forward to (self~indexer) -- always new String and new RexxText


-- WTF-16BE or WTF-16LE representation
::method WTF16
    use strict arg -- none
    if self~isWTF16 then return self
    forward to (self~indexer) -- always new String and new RexxText


-- WTF-16BE representation
::method WTF16BE
    use strict arg -- none
    if self~isWTF16BE then return self
    forward to (self~indexer) -- always new String and new RexxText


-- WTF-16LE representation
::method WTF16LE
    use strict arg -- none
    if self~isWTF16LE then return self
    forward to (self~indexer) -- always new String and new RexxText


-- UTF-32BE or UTF-32LE representation
::method UTF32
    use strict arg -- none
    if self~isUTF32 then return self
    forward to (self~indexer) -- always new String and new RexxText


-- UTF-32BE representation
::method UTF32BE
    use strict arg -- none
    if self~isUTF32BE then return self
    forward to (self~indexer) -- always new String and new RexxText


-- UTF-32LE representation
::method UTF32LE
    use strict arg -- none
    if self~isUTF32LE then return self
    forward to (self~indexer) -- always new String and new RexxText


::method c2x
    forward to (self~indexer)


::method c2u
    forward to (self~indexer)


::method c2g
    forward to (self~indexer)


::method isASCII
    use strict arg -- none
    return (self~isByte | self~isUTF8 | self~isWTF8) & self~string~isASCII


::method checkNumericValueCompatibility
    -- The purpose is not to check that the text is a numeric value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    use strict arg -- none
    if \self~isASCII then raise syntax 93.900 array("The" self~description(short:.true) "text is not compatible with a Rexx numeric value")


::method checkLogicalValueCompatibility
    -- The purpose is not to check that the text is a logical value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    use strict arg -- none
    if \self~isASCII then raise syntax 93.900 array("The" self~description(short:.true) "text is not compatible with a Rexx logical value")


/******************************************************************************/
::class "RexxTextStringInterface" mixinclass Object public

::method caselessCompareTo
    use strict arg text, n=1, length=(self~length)
    -- Wrong fallback implementation
    return self~string~caselessCompareTo(text~string)


/******************************************************************************/
::class "RexxTextOperators" mixinclass Object public

/**************/
/* Arithmetic */
/**************/

::method '*'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '*op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "*" to (left) array (self~string)

::method '**'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '**op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "**" to (left) array (self~string)

::method '+'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '+op:right'
    -- here, necessarily 2 args
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "+" to (left) array (self~string)

::method '-'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '-op:right'
    -- here, necessarily 2 args
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "-" to (left) array (self~string)

::method '/'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '/op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "/" to (left) array (self~string)

::method '//'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '//op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "//" to (left) array (self~string)

::method '%'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '%op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "%" to (left) array (self~string)


/**************/
/* Comparison */
/**************/

::method compareSelfRight
    use strict arg right, message
    right = right~request("RexxText")
    if .nil == right then return
    if .Encoding~comparisonMode(self, right) == "b" then do
        forward message (message) to (self~string) array (right~string)
    end
    -- Unicode comparison
    raise syntax 93.900 array("Unicode comparison not yet implemented")


::method compareLeftSelf
    use strict arg left, message
    left = left~request("RexxText")
    if .nil == left then return
    if .Encoding~comparisonMode(left, self) == "u" then do
        forward message (message) to (left~string) array (self~string)
    end
    -- Unicode comparison
    raise syntax 93.900 array("Unicode comparison not yet implemented")


::method '<'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<')

::method '<op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<')

::method '<<'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<<')

::method '<<op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<<')

::method '<<='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<<=')

::method '<<=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<<')

::method '<='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<=')

::method '<=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<=')

::method '<>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<>')

::method '<>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<>')

::method '='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '=')

::method '=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '=')

::method '=='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '==')

::method '==op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '==')

::method '>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>')

::method '>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>')

::method '><'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '><')

::method '><op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '><')

::method '>='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>=')

::method '>=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>=')

::method '>>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>>')

::method '>>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>>')

::method '>>='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>>=')

::method '>>=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>>=')

::method '\<'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\<')

::method '\<op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\<')

::method '\='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\=')

::method '\=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\=')

::method '\=='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\==')

::method '\==op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\==')

::method '\>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\>')

::method '\>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>')

::method '\>>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\>>')

::method '\>>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\>>')


/***********/
/* Logical */
/***********/

::method '&&'
    self~checkLogicalValueCompatibility
    forward to (self~string)

::method '&&op:right'
    use strict arg left
    self~checkLogicalValueCompatibility
    forward message "&&" to (left) array (self~string)

::method '&'
    self~checkLogicalValueCompatibility
    forward to (self~string)

::method '&op:right'
    use strict arg left
    self~checkLogicalValueCompatibility
    forward message "&" to (left) array (self~string)

::method '\' -- unary only
    self~checkLogicalValueCompatibility
    forward to (self~string)

::method '|'
    self~checkLogicalValueCompatibility
    forward to (self~string)

::method '|op:right'
    use strict arg left
    self~checkLogicalValueCompatibility
    left~checkLogicalValueCompatibility
    forward message "|" to (left) array (self~string)


/*****************/
/* Concatenation */
/*****************/

::method " "
    use strict arg right
    right = right~request("RexxText")
    if .nil == right then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(self, right)
    return encoding~concatenate(self, encoding~spaceCharacter, right)


::method " op:right"
    use strict arg left
    left = left~request("RexxText")
    if .nil == left then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(left, self)
    return encoding~concatenate(left, encoding~spaceCharacter, self)


::method "||"
    use strict arg right
    right = right~request("RexxText")
    if .nil == right then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "||op:right"
    use strict arg left
    left = left~request("RexxText")
    if .nil == left then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(left, self)
    return encoding~concatenate(left, self)


::method "" -- abuttal
    use strict arg right
    right = right~request("RexxText")
    if .nil == right then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "op:right" -- abuttal
    use strict arg left
    left = left~request("RexxText")
    if .nil == left then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(left, self)
    return encoding~concatenate(left, self)


/******************************************************************************/
::extension "Unicode"

::method initialize class
    expose characters
    use strict arg -- none
    characters = .directory~new
    self~declareCharacter(  "20"~x2d, "space")
    self~declareCharacter("0301"~x2d, "combining acute accent")
    self~declareCharacter("FFFD"~x2d, "replacement character")

::method declareCharacter class
    expose characters
    use strict arg codepoint, name
    character = .UnicodeCharacter~new(codepoint, name)
    characters~setEntry(name, character)


::method character class
    expose characters
    use strict arg name
    return characters~entry(name)


::method spaceCharacter class
    expose spaceCharacter
    use strict arg -- none
    if \var("spaceCharacter") then spaceCharacter = self~character("space")
    return spaceCharacter


::method replacementCharacter class
    expose replacementCharacter
    use strict arg -- none
    if \var("replacementCharacter") then replacementCharacter = self~character("replacement character")
    return replacementCharacter


/******************************************************************************/
::class "UnicodeCharacter" public

::attribute codepoint get
::attribute name get

::method init
    expose codepoint name
    use strict arg codepoint, name

::method UTF8
    expose codepoint
    use strict arg -- none
    return .UTF8_Encoding~encode(codepoint)

::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    expose codepoint
    use strict arg -- none
    return .UTF16BE_Encoding~encode(codepoint)


::method UTF16LE
    expose codepoint
    use strict arg -- none
    return .UTF16LE_Encoding~encode(codepoint)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    expose codepoint
    use strict arg -- none
    return .UTF32BE_Encoding~encode(codepoint)


::method UTF32LE
    expose codepoint
    use strict arg -- none
    return .UTF32LE_Encoding~encode(codepoint)


/******************************************************************************/
::class "Encoding" public

/*
big-endian, little-endian
    0x44332211
         0  1  2  3
    BE  44 33 22 11
    LE  11 22 33 44

    ~c2x is neutral regarding big-endian vs little-endian:
    "44332211"x~c2x -- 44332211
    "11223344"x~c2x -- 11223344

    ~c2d is always big-endian, whatever the endianess of the CPU:
    "00000001"x~c2d -- 1
    "10000000"x~c2d -- 268435456


The character at code point U+FEFF is defined as the byte order mark
Its byte-reversed counterpart, U+FFFE is a noncharacter (U+FFFE) in UTF-16 ,
or outside the code space (0xFFFE0000) for UTF-32

    UTF-8 BOM: 0xEF 0xBB 0xBF

    UTF-16 BOM: 0xFEFF
    BE: FE FF
    LE: FF FE

    UTF-32 BOM: 0x0000FEFF
    BE: 0x00 0x00 0xFE 0xFF
    LE: 0xFF 0xFE 0x00 0x00


http://www.herongyang.com/Unicode//UTF-32-UTF-32BE-UTF-32LE-Encoding.html
    - Output byte streams of UTF-32 encoding may have 3 valid formats:
      Big-Endian without BOM, Big-Endian with BOM, and Little-Endian with BOM.
    - UTF-32BE encoding is identical to the Big-Endian without BOM format of UTF-32 encoding.
    - UTF-32LE encoding is identical to the Little-Endian with BOM format of UTF-32 encoding without using BOM.

https://www.unicode.org/reports/tr17/
    UNICODE CHARACTER ENCODING MODEL

https://www.ietf.org/rfc/rfc2781.txt
    UTF-16, an encoding of ISO 10646
    This document contains the registration for three MIME charset parameter values:
    UTF-16BE (big-endian), UTF-16LE (little-endian), and UTF-16.

    UTF-16BE
        Text labelled "UTF-16BE" can always be interpreted as being big-endian.
        The detection of an initial BOM does not affect de-serialization of text labelled as UTF-16BE.
        Finding 0xFF followed by 0xFE is an error since there is no Unicode character 0xFFFE. (jlf: an error ? no: 0xFFFE is a noncharacter, Unicode says it's not an error)

    UTF-16LE
        Text labelled "UTF-16LE" can always be interpreted as being little-endian.
        The detection of an initial BOM does not affect de-serialization of text labelled as UTF-16LE.
        Finding 0xFE followed by 0xFF is an error since there is no Unicode character 0xFFFE, which would be the interpretation of those octets under little-endian order. (jlf: an error ? no: 0xFFFE is a noncharacter, Unicode says it's not an error)

    UTF-16
        If the first two octets of the text is 0xFE followed by 0xFF, then the text can be interpreted as being big-endian.
        If the first two octets of the text is 0xFF followed by 0xFE, then the text can be interpreted as being little-endian.
        If the first two octets of the text is not 0xFE followed by 0xFF, and is not 0xFF followed by 0xFE, then the text SHOULD be interpreted as being big-endian.

http://www.unicode.org/reports/tr19/tr19-9.html
    UTF-32
    The code units for UTF-32 correspond exactly to Unicode code points.
    3 encoding schemes: UTF-32 (possibly using BOM), UTF-32BE, and UTF-32LE.

    UTF-32BE
        (a) UTF-32BE is the Unicode Transformation Format that serializes a Unicode code point as a sequence of four bytes, in big-endian format.
            An initial sequence corresponding to U+FEFF is interpreted as a zero width no-break space.
        (b) An illegal UTF-32BE code unit sequence is any byte sequence that would correspond to a numeric value outside of the range 0 to 10FFFF.
        (c) An irregular UTF-32BE code unit sequence is an eight-byte sequence where the first four bytes correspond to a high surrogate, and the next four bytes correspond to a low surrogate.
            As a consequence of C12, these irregular UTF-32BE sequences shall not be generated by a conformant process.
        In UTF-32BE, <U+004D, U+0061, U+10000> is serialized as <00 00 00 4D 00 00 00 61 00 01 00 00>

    UTF-32LE
        (a) UTF-32LE is the Unicode Transformation Format that serializes a Unicode code point as a sequence of four bytes, in little-endian format.
            An initial sequence corresponding to U+FEFF is interpreted as a zero width no-break space.
        (b) An illegal UTF-32LE code unit sequence is any byte sequence that would correspond to a numeric value outside of the range 0 to 10FFFF.
        (c) An irregular UTF-32LE code unit sequence is an eight-byte sequence where the first four bytes correspond to a high surrogate, and the next four bytes correspond to a low surrogate.
            As a consequence of C12, these irregular UTF-32LE sequences shall not be generated by a conformant process.
        In UTF-32LE, <U+004D, U+0061, U+10000> is serialized as <4D 00 00 00 61 00 00 00 00 00 01 00>

    UTF-32
        (a) UTF-32 is the Unicode Transformation Format that serializes a Unicode code point as a sequence of four bytes, in either big-endian or little-endian format.
            An initial sequence corresponding to U+FEFF is interpreted as a byte order mark: it is used to distinguish between the two byte orders.
            The byte order mark is not considered part of the content of the text.
            A serialization of Unicode code points into UTF-32 may or may not begin with a byte order mark.
        (b) An illegal UTF-32 code unit sequence is any byte sequence that would correspond to a numeric value outside of the range 0 to 10FFFF.
        (c) An irregular UTF-32 code unit sequence is an eight-byte sequence where the first four bytes correspond to a high surrogate, and the next four bytes correspond to a low surrogate.
            As a consequence of C12, these irregular UTF-32 sequences shall not be generated by a conformant process.
        In UTF-32, <U+004D, U+0061, U+10000> is serialized as any of:
            <00 00 FE FF 00 00 00 4D 00 00 00 61 00 01 00 00>
            <FF FE 00 00 4D 00 00 00 61 00 00 00 00 00 01 00>
            <00 00 00 4D 00 00 00 61 00 01 00 00>


https://www.iana.org/assignments/character-sets/character-sets.xhtml
    Character Sets
    These are the official names for character sets that may be used in
     the Internet and may be referred to in Internet documentation.

*/

::attribute defaultEncoding class get
    expose defaultEncoding
    use strict arg -- none
    if \var("defaultEncoding") then defaultEncoding = .UTF8_Encoding
    return defaultEncoding


::attribute defaultEncoding class set
    expose defaultEncoding
    use strict arg encodingName
    defaultEncoding = self~factory(encodingName)


::attribute defaultInputEncoding class get
    expose defaultInputEncoding
    use strict arg -- none
    if \var("defaultInputEncoding") then defaultInputEncoding = self~defaultEncoding
    return defaultInputEncoding


::attribute defaultInputEncoding class set
    expose defaultInputEncoding
    use strict arg encodingName
    defaultInputEncoding = self~factory(encodingName)


::attribute defaultOutputEncoding class get
    expose defaultOutputEncoding
    use strict arg -- none
    if \var("defaultOutputEncoding") then defaultOutputEncoding = self~defaultEncoding
    return defaultOutputEncoding


::attribute defaultOutputEncoding class set
    expose defaultOutputEncoding
    use strict arg encodingName
    defaultOutputEncoding = self~factory(encodingName)


::method activate class
    expose encodings
    use strict arg -- none
    encodings = .directory~new

    encodings["BYTE"] = .Byte_Encoding
    encodings["BYTES"] = .Byte_Encoding

    encodings["CP65001"] = .UTF8_Encoding -- Python
    encodings["U8"] = .UTF8_Encoding -- Python
    encodings["UTF"] = .UTF8_Encoding -- Python
    encodings["UTF8"] = .UTF8_Encoding
    encodings["W8"] = .WTF8_Encoding -- jlf: only me ?
    encodings["WTF"] = .WTF8_Encoding -- jlf: only me ?
    encodings["WTF8"] = .WTF8_Encoding

    encodings["U16"] = .UTF16BE_Encoding -- Python
    encodings["UTF16"] = .UTF16BE_Encoding
    encodings["UTF16BE"] = .UTF16BE_Encoding
    encodings["UTF16LE"] = .UTF16LE_Encoding
    encodings["W16"] = .WTF16BE_Encoding -- jlf: only me ?
    encodings["WTF16"] = .WTF16BE_Encoding
    encodings["WTF16BE"] = .WTF16BE_Encoding
    encodings["WTF16LE"] = .WTF16LE_Encoding

    encodings["U32"] = .UTF32BE_Encoding -- Python
    encodings["UTF32"] = .UTF32BE_Encoding
    encodings["UTF32BE"] = .UTF32BE_Encoding
    encodings["UTF32LE"] = .UTF32LE_Encoding

    -- windows-1250 (Central and Eastern Europe)
    -- encodings["CP1250"] = .CP1250_Encoding
    -- encodings["WINDOWS1250"] = .CP1250_Encoding

    -- windows-1251 (Bulgarian, Byelorussian, Macedonian, Russian, Serbian)
    -- encodings["CP1251"] = .CP1251_Encoding
    -- encodings["WINDOWS1251"] = .CP1251_Encoding

    -- windows-1252 (Western Europe)
    encodings["CP1252"] = .CP1252_Encoding
    encodings["WINDOWS1252"] = .CP1252_Encoding

    -- windows-1253 (Greek)
    -- encodings["CP1253"] = .CP1253_Encoding
    -- encodings["WINDOWS1253"] = .CP1253_Encoding

    -- windows-1254 (Turkish)
    -- encodings["CP1254"] = .CP1254_Encoding
    -- encodings["WINDOWS1254"] = .CP1254_Encoding

    -- windows-1255 (Hebrew)
    -- encodings["CP1255"] = .CP1255_Encoding
    -- encodings["WINDOWS1255"] = .CP1255_Encoding

    -- windows-1256 (Arabic)
    -- encodings["CP1256"] = .CP1256_Encoding
    -- encodings["WINDOWS1256"] = .CP1256_Encoding

    -- windows-1257 (Baltic languages)
    -- encodings["CP1257"] = .CP1257_Encoding
    -- encodings["WINDOWS1257"] = .CP1257_Encoding

    -- windows-1258 (Vietnamese)
    -- encodings["CP1258"] = .CP1258_Encoding
    -- encodings["WINDOWS1258"] = .CP1258_Encoding

    -- ISO-8859-1 (Western Europe)
    -- https://en.wikipedia.org/wiki/ISO/IEC_8859-1
    --  iso-ir-100, csISOLatin1, latin1, l1, IBM819. Code page 28591 a.k.a. Windows-28591 is used for it in Windows.[9] IBM calls it code page 819 or CP819 (CCSID 819).[10][11][12][13] Oracle calls it WE8ISO8859P1.[14]
    -- https://docs.python.org/3/library/codecs.html#standard-encodings
    --  iso-8859-1, iso8859-1, 8859, cp819, latin, latin1, L1
    -- encodings["819"] = .ISO88591_Encoding
    -- encodings["8859"] = .ISO88591_Encoding
    -- encodings["28591"] = .ISO88591_Encoding
    -- encodings["CP819"] = .ISO88591_Encoding
    -- encodings["CSISOLATIN1"] = .ISO88591_Encoding
    -- encodings["IBM819"] = .ISO88591_Encoding
    -- encodings["ISO88591"] = .ISO88591_Encoding
    -- encodings["ISOIR100"] = .ISO88591_Encoding
    -- encodings["L1"] = .ISO88591_Encoding
    -- encodings["LATIN"] = .ISO88591_Encoding
    -- encodings["LATIN1"] = .ISO88591_Encoding
    -- encodings["CP819"] = .ISO88591_Encoding
    -- encodings["WE8ISO8859P1"] = .ISO88591_Encoding
    -- encodings["WINDOWS28591"] = .ISO88591_Encoding

    -- ISO-8859-2 (Central and Eastern Europe)
    -- encodings["ISO88592"] = .ISO88592_Encoding
    -- encodings["L2"] = .ISO88592_Encoding
    -- encodings["LATIN2"] = .ISO88592_Encoding

    -- ISO-8859-3 (Esperanto, Maltese)
    -- encodings["ISO88593"] = .ISO88593_Encoding
    -- encodings["L3"] = .ISO88593_Encoding
    -- encodings["LATIN3"] = .ISO88593_Encoding

    -- ISO-8859-4 (Baltic languages)
    -- encodings["ISO88594"] = .ISO88594_Encoding
    -- encodings["L4"] = .ISO88594_Encoding
    -- encodings["LATIN4"] = .ISO88594_Encoding

    -- ISO-8859-5 (Bulgarian, Byelorussian, Macedonian, Russian, Serbian)
    -- encodings["ISO88595"] = .ISO88595_Encoding
    -- encodings["CYRILLIC"] = .ISO88595_Encoding

    -- ISO-8859-6 (Arabic)
    -- encodings["ISO88596"] = .ISO88596_Encoding
    -- encodings["ARABIC"] = .ISO88596_Encoding

    -- ISO-8859-7 (Greek)
    -- encodings["ISO88597"] = .ISO88597_Encoding
    -- encodings["GREEK"] = .ISO88597_Encoding
    -- encodings["GREEK8"] = .ISO88597_Encoding

    -- ISO-8859-8 (Hebrew)
    -- encodings["ISO88598"] = .ISO88598_Encoding
    -- encodings["HEBREW"] = .ISO88598_Encoding

    -- ISO-8859-9 (Turkish)
    -- encodings["ISO88599"] = .ISO88599_Encoding
    -- encodings["L5"] = .ISO88599_Encoding
    -- encodings["LATIN5"] = .ISO88599_Encoding

    -- ISO-8859-10 (Nordic languages)
    -- encodings["ISO885910"] = .ISO885910_Encoding
    -- encodings["L6"] = .ISO885910_Encoding
    -- encodings["LATIN6"] = .ISO885910_Encoding

    -- ISO-8859-11 (Thai languages)
    -- encodings["ISO885911"] = .ISO885911_Encoding
    -- encodings["THAI"] = .ISO885910_Encoding

    -- ISO-8859-13 (Baltic languages)
    -- encodings["ISO885913"] = .ISO885913_Encoding
    -- encodings["L7"] = .ISO885913_Encoding
    -- encodings["LATIN7"] = .ISO885913_Encoding

    -- ISO-8859-14 (Celtic languages)
    -- encodings["ISO885914"] = .ISO885914_Encoding
    -- encodings["L8"] = .ISO885914_Encoding
    -- encodings["LATIN8"] = .ISO885914_Encoding

    -- ISO-8859-15 (Western Europe)
    -- encodings["ISO885915"] = .ISO885915_Encoding
    -- encodings["L9"] = .ISO885915_Encoding
    -- encodings["LATIN9"] = .ISO885915_Encoding

    -- ISO-8859-16 (South-Eastern Europe)
    -- encodings["ISO885916"] = .ISO885916_Encoding
    -- encodings["L10"] = .ISO885916_Encoding
    -- encodings["LATIN10"] = .ISO885916_Encoding

    -- Mac Roman (Western Europe)
    -- encodings["MACINTOSH"] = .MACROMAN_Encoding
    -- encodings["MACROMAN"] = .MACROMAN_Encoding


::method supported class
    expose encodings
    use strict arg -- none
    return encodings~supplier


::method factory class
    expose encodings
    use strict arg encoding, string=""
    if encoding~isA(.Class), encoding~isSubClassOf(.StringIndexer) then return encoding
    encoding = encoding~string
    -- Remove all dash, underscore and spaces: "UTF8", "UTF_8", "UTF-8", "UTF 8" are all a valid encoding name
    encodingName = encoding~translate(, "_- "," ")~space(0)~upper
    if encodingName == "DEFAULT" then return .Encoding~defaultEncoding
    if encodingName == "UTF16" then do
        if string~startsWith(.UTF16BE_Encoding~BOM) then return .UTF16BE_Encoding
        if string~startsWith(.UTF16LE_Encoding~BOM) then return .UTF16LE_Encoding
        return .UTF16BE_Encoding -- The Unicode norm specifies that the default UTF-16 is big endian
    end
    if encodingName == "WTF16" then do
        if string~startsWith(.WTF16BE_Encoding~BOM) then return .WTF16BE_Encoding
        if string~startsWith(.WTF16LE_Encoding~BOM) then return .WTF16LE_Encoding
        return .WTF16BE_Encoding -- Same logic of default as UTF-16
    end
    if encodingName == "UTF32" then do
        if string~startsWith(.UTF32BE_Encoding~BOM) then return .UTF32BE_Encoding
        if string~startsWith(.UTF32LE_Encoding~BOM) then return .UTF32LE_Encoding
        return .UTF32BE_Encoding -- The Unicode norm specifies that the default UTF-32 is big endian
    end
    if encodings~hasEntry(encodingName) then return encodings[encodingName]
    raise syntax 93.900 array("Encoding: '"encoding"' is not supported")


::method forConcatenation class
    use strict arg left, right
    leftEncoding = left~encoding
    rightEncoding = right~encoding

    if leftEncoding == rightEncoding then return leftEncoding

    if leftEncoding~isUTF8, rightEncoding~isWTF8 then return .WTF8_Encoding
    if leftEncoding~isWTF8, rightEncoding~isUTF8 then return .WTF8_Encoding
    -- Keep the following tests after the previous tests, to keep the priority for WTF8
    if left~isASCII, (rightEncoding~isUTF8 | rightEncoding~isWTF8) then return rightEncoding
    if (leftEncoding~isUTF8 | leftEncoding~isWTF8), right~isASCII then return leftEncoding

    if leftEncoding~isUTF16BE, rightEncoding~isWTF16BE then return .WTF16BE_Encoding
    if leftEncoding~isWTF16BE, rightEncoding~isUTF16BE then return .WTF16BE_Encoding
    if leftEncoding~isUTF16LE, rightEncoding~isWTF16LE then return .WTF16LE_Encoding
    if leftEncoding~isWTF16LE, rightEncoding~isUTF16LE then return .WTF16LE_Encoding

    raise syntax 93.900 array("Encoding: cannot concatenate" left~description(short:.true) "text with" right~description(short:.true) "text")


::method comparisonMode class
    -- if a byte comparison is possible then return "b"
    -- if a unicode comparision is possible then return "u"
    -- otherwise raise an error
    use strict arg left, right
    if left~isByte, right~isByte, left~encoding == right~encoding then return "b"
    if left~isASCII, right~isASCII then return "b"
    if left~isASCII, (right~isUTF8 | right~isWTF8) then return "u"
    if (left~isUTF8 | left~isWTF8), right~isASCII then return "u"
    if left~isUnicode & right~isUnicode then return "u"
    raise syntax 93.900 array("Encoding: cannot compare" left~description(short:.true) "text with" right~description(short:.true) "text")


/******************************************************************************/
::class "StringIndexer" mixinclass Object private -- abstract

::method name class abstract


::method isByte class
    use strict arg -- none
    return .false


::method isUnicode class
    use strict arg -- none
    return .false


::method isUTF8 class
    use strict arg -- none
    return .false


::method isWTF8 class
    use strict arg -- none
    return .false


::method isUTF16 class
    use strict arg -- none
    return .false


::method isUTF16BE class
    use strict arg -- none
    return .false


::method isUTF16LE class
    use strict arg -- none
    return .false


::method isWTF16 class
    use strict arg -- none
    return .false


::method isWTF16BE class
    use strict arg -- none
    return .false


::method isWTF16LE class
    use strict arg -- none
    return .false


::method isUTF32 class
    use strict arg -- none
    return .false


::method isUTF32BE class
    use strict arg -- none
    return .false


::method isUTF32LE class
    use strict arg -- none
    return .false


::method isWTF32 class
    use strict arg -- none
    return .false


::method isWTF32BE class
    use strict arg -- none
    return .false


::method isWTF32LE class
    use strict arg -- none
    return .false


::method codepointMaxBytes class abstract -- used for buffer allocation


::method analyze class abstract


::method checkCodepoint class abstract


::method decode class abstract


::method nextCodepointIndex class


::method skipInvalidByteSequence class


::method encode class abstract


::method concatenate class
    -- Arguments : zero to N text.
    -- This method must be called from a subclass of StringIndexer
    -- Precondition: the encodings are compatible with self (you have checked that with .Encoding~forConcatenation)
    bufferSize = 0
    do i = 1 to arg()
        bufferSize += arg(i)~string~length
    end
    buffer = .mutableBuffer~new(, bufferSize)
    do i = 1 to arg()
        arg(i)~encoding~appendToBuffer(buffer, arg(i)~string)
    end
    return .RexxText~new(buffer~string, self)


::method spaceCharacter class
    expose spaceCharacter
    use strict arg -- none
    if \var("spaceCharacter") then spaceCharacter = self~encode(.Unicode~spaceCharacter~codepoint)
    return spaceCharacter


/********************/
/* Instance methods */
/********************/

::attribute string get
::attribute string set private
::attribute codepointIndexes get private -- will be removed, no need of direct access to a codepoint
::attribute codepointCount get
::attribute graphemeIndexes get private
::attribute graphemeCount get
::attribute errors get


::method init
    expose string codepointIndexes codepointCount  graphemeIndexes graphemeCount errors
    use strict arg string, codepointIndexes, codepointCount, graphemeIndexes, graphemeCount, errors


::method copy
    -- No need to re-analyze the string, it's immutable:
    -- all the indexes are still applicable, just change the string referenced by the indexer.
    use strict arg -- none
    clone = self~copy:super
    clone~string = .string~new(clone~string) -- don't use ~copy (stack overflow)
    return clone


::method description
    use strict arg -- none
    use strict named arg short=.false
    if self~string~isASCII then asciiness = "ASCII"
                           else asciiness = "not-ASCII"
    if self~errors == .nil then errorCount = 0
                           else errorCount = self~errors~size
    sizesDescription = ""
    if \short then sizesDescription = "(" ||,
                                      self~graphemes~count~singularPluralCount("grapheme", "graphemes")",",
                                      self~codepoints~count~singularPluralCount("codepoint", "codepoints")",",
                                      self~string~length~singularPluralCount("byte", "bytes")",",
                                      errorCount~singularPluralCount("error", "errors"),
                                      || ")"
    return " "~concatenateSeparated(self~class~name, asciiness, sizesDescription)


::method c2x
    use strict arg -- none
    codepoints = self~codepoints
    buffer = .MutableBuffer~new
    first = .true
    do while codepoints~available
        if \first then buffer~append(" ")
        first = .false
        codepoint = codepoints~item(.false) -- false: don't decode
        buffer~append(codepoint~c2x)
        codepoints~next
    end
    return buffer~string


::method c2u
    use strict arg -- none
    codepoints = self~codepoints
    buffer = .MutableBuffer~new
    first = .true
    do while codepoints~available
        if \first then buffer~append(" ")
        first = .false
        call ppCodepoint codepoints~item, buffer
        codepoints~next
    end
    return buffer~string


::method c2g
    use strict arg -- none
    graphemes = self~graphemes
    buffer = .MutableBuffer~new
    first = .true
    do while graphemes~available
        if \first then buffer~append(" ")
        first = .false
        buffer~append(graphemes~item~string~c2x)
        graphemes~next
    end
    return buffer~string


::method codepoints
    use strict arg -- none
    return .CodePointSupplier~new(self)


::method codepoint abstract


::method graphemes
    use strict arg -- none
    return .GraphemeSupplier~new(self)


::method grapheme abstract


::method UTF8 abstract


::method WTF8 abstract


::method UTF16 abstract


::method UTF16BE abstract


::method UTF16LE abstract


::method WTF16 abstract


::method WTF16BE abstract


::method WTF16LE abstract


::method UTF32 abstract


::method UTF32BE abstract


::method UTF32LE abstract


::method appendToBuffer class
    -- WTF-8 overrides this method
    use strict arg buffer, string
    buffer~append(string)


/******************************************************************************/
::class "Byte_Encoding" public inherit StringIndexer

::method name class
    use strict arg -- none
    return "Byte"


::method isByte class
    use strict arg -- none
    return .true


::method codepointMaxBytes class
    use strict arg -- none
    return 1


::method analyze class
    use strict arg string /* or buffer */
    sizeB = string~length -- size in bytes
    -- Bytes, codepoints and graphemes are identical
    -- The string holds all the needed informations, no need to calculate indexes
    return self~new(string, .nil, sizeB, .nil, sizeB, .nil)


::method checkCodepoint class
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange -- no impact here
    if codepoint < 0 | codepoint > 255 then signal error_range
    return .true
    -- Don't use ppCodepoint here, it's not Unicode.
    error_range: raise syntax 93.900 array (self~name "encoding: invalid codepoint" codepoint "("ppHexNumber(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..255")


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return -1
    if sizeB == 1 then return string~subchar(startB)~c2d
    raise syntax 93.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method nextCodepointIndex class
    use strict arg string /* or buffer */, indexB
    c = string~subchar(indexB)
    if c == "" then return indexB
    return indexB + 1


::method skipInvalidByteSequence class
    -- The sequence starting at indexB is invalid.
    -- Here, a byte sequence is always one byte.
    use strict arg string /* or buffer */, indexB
    return indexB + 1


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint, buffer=.nil
    self~checkCodepoint(codepoint, checkOnlyRange:.true) -- check only range, the other errors will be detected during analysis
    if buffer <> .nil then return buffer~~append(codepoint~d2c)
                      else return .RexxText~new(codepoint~d2c, self)


::method tableTranscodingToUnicode class
    use strict arg -- none
    return .nil


/********************/
/* Instance methods */
/********************/

::method codepoint
    use strict arg indexC, decode=.true
    if indexC < 1 | indexC > self~codepointCount then raise syntax 93.900 array (self~description "invalid codepoint index:" indexC)
    if decode then return self~string~subchar(indexC)~c2d
              else return self~string~subchar(indexC)


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeCount then raise syntax 93.900 array (self~description "invalid grapheme index:" indexG)
    return .RexxText~new(self~string~subchar(indexG), self~class)


::method convertByteToUnicode private
    use strict arg targetEncoding
    use strict named arg strict=.true
    tableTranscodingToUnicode = self~class~tableTranscodingToUnicode
    if tableTranscodingToUnicode <> .nil then do
        sizeC = self~codepointCount -- size in codepoints
        buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
        do i=1 to sizeC
            charcode = self~codepoint(i)
            codepoint = tableTranscodingToUnicode[charcode+1] -- bof bof... 1-based array
            -- An empty string means no mapping
            -- A negative codepoint means unused character with fallback mapping
            if codepoint == "" | (codepoint < 0 & strict) then raise syntax 93.900 array(self~name "encoding: cannot convert" self~description(short:.true) "character" charcode "("charcode~d2x") at byte-position" i "to" targetEncoding~name)
            targetEncoding~encode(abs(codepoint), buffer)
        end
        return .RexxText~new(buffer~string, targetEncoding)
    end
    raise syntax 93.900 array(self~class~name "encoding: cannot convert" self~description(short:.true) "to" targetEncoding~name)


::method UTF8
    use strict named arg strict=.true
    -- yes, always a new string. The original string is still associated to the Byte_Encoding.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if self~string~isASCII then return .RexxText~new(.String~new(self~string), .UTF8_Encoding)
    return self~convertByteToUnicode(.UTF8_Encoding, strict: strict)


::method WTF8
    use strict named arg strict=.true
    -- yes, always a new string. The original string is still associated to the Byte_Encoding.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if self~string~isASCII then return .RexxText~new(.String~new(self~string), .WTF8_Encoding)
    return self~convertByteToUnicode(.WTF8_Encoding, strict: strict)


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict named arg strict=.true
    if self~string~isASCII then return .UTF16BE_Encoding~encodeASCIIstring(self~string)
    return self~convertByteToUnicode(.UTF16BE_Encoding, strict: strict)


::method UTF16LE
    use strict named arg strict=.true
    if self~string~isASCII then return .UTF16LE_Encoding~encodeASCIIstring(self~string)
    return self~convertByteToUnicode(.UTF16LE_Encoding, strict: strict)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict named arg strict=.true
    if self~string~isASCII then return .WTF16BE_Encoding~encodeASCIIstring(self~string)
    return self~convertByteToUnicode(.WTF16BE_Encoding, strict: strict)


::method WTF16LE
    use strict named arg strict=.true
    if self~string~isASCII then return .WTF16LE_Encoding~encodeASCIIstring(self~string)
    return self~convertByteToUnicode(.WTF16LE_Encoding, strict: strict)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict named arg strict=.true
    if self~string~isASCII then return .UTF32BE_Encoding~encodeASCIIstring(self~string)
    return self~convertByteToUnicode(.UTF32BE_Encoding, strict: strict)


::method UTF32LE
    use strict named arg strict=.true
    if self~string~isASCII then return .UTF32LE_Encoding~encodeASCIIstring(self~string)
    return self~convertByteToUnicode(.UTF32LE_Encoding, strict: strict)


/******************************************************************************/
::class "CP1252_Encoding" subclass Byte_Encoding public
-- alias Window-1252

::method name class
    use strict arg -- none
    return "CP1252"


::attribute tableTranscodingToUnicode class get


::method activate class
    -- https://en.wikipedia.org/wiki/Windows-1252#Code_page_layout
    -- According to the information on Microsoft's and the Unicode Consortium's websites,
    -- positions 81, 8D, 8F, 90, and 9D are unused;
    -- however, the Windows API MultiByteToWideChar maps these to the corresponding C1 control codes.
    expose tableTranscodingToUnicode
    use strict arg -- none
    specificTranscoding =,
        , --       00      01      02      03      04      05      06      07      08      09      0A      0B      0C      0D      0E      0F
        "80:",  "20AC",  "-81", "201A", "0192", "201E", "2026", "2020", "2021", "02C6", "2030", "0160", "2039", "0152",  "-8D", "017D",  "-8F",,
        "90:",   "-90", "2018", "2019", "201C", "201D", "2022", "2013", "2014", "02DC", "2122", "0161", "203A", "0153",  "-9D", "017E", "0178"
    tableTranscodingToUnicode = createCharacterTranscodingTable(256, specificTranscoding)


/******************************************************************************/
::class "Unicode_CommonServices" mixinclass Object private

::method isUnicode class
    use strict arg -- none
    return .true


::method createIndexer class
    use strict arg string, codepointIndexes, graphemeIndexes
    errors = .nil
    indexB = 1
    previousCodepoint = .nil
    previousCodepointIndexB = .nil
    graphemeBreakArgs = (-1, -1, 0) -- codepoint1, codepoint2, state. Will use the same array at each iteration.

    encoding = self
    forever:
        signal on syntax -- catch any encoding error
        nextB = encoding~nextCodepointIndex(string, indexB)
        codepoint = encoding~decode(string, indexB, nextB - indexB) -- can be -1 if nextB == indexB
        if codepoint <> -1 then encoding~checkCodepoint(codepoint, indexB, previousCodepoint, previousCodepointIndexB)

        -- From here, we know that the current codepoint is valid
        codepointIndexes~append(indexB) -- will be removed
        if codepoint == -1 then do
            -- End of string
            graphemeIndexes~append(indexB)
            signal leave
        end
        if previousCodepoint == .nil then do
            -- First codepoint
            graphemeIndexes~append(indexB)
        end
        else do
            graphemeBreakArgs[1] = previousCodepoint
            graphemeBreakArgs[2] = codepoint
            if .Unicode~GraphemeBreak(graphemeBreakArgs) then do
                graphemeIndexes~append(indexB)
            end
        end
        previousCodepoint = codepoint
        previousCodepointIndexB = indexB
        indexB = nextB
    signal forever
    leave:

    -- Return compacted arrays (their size can be lesser than string's length)
    codepointIndexes = codepointIndexes~makeArray -- will be removed
    graphemeIndexes = graphemeIndexes~makeArray
    if errors == .nil, graphemeIndexes~size-1 == string~length then do
        -- Optimization: no need of indexes, direct access is possible
        return encoding~new(string, .nil, string~length, .nil, string~length, errors)
    end
    else do
        return encoding~new(string, codepointIndexes, codepointIndexes~size-1, graphemeIndexes, graphemeIndexes~size-1, errors)
    end

    syntax:
        codepointIndexes~append(-indexB) -- negative value to indicate a serious error
        graphemeIndexes~append(-indexB) -- idem
        if errors = .nil then errors = .array~new
        condition = condition("O")
        errors~append(condition["MESSAGE"])
        previousCodepoint = .Unicode~replacementCharacter~codepoint
        previousCodepointIndexB = indexB
        graphemeBreakArgs[3] = 0 -- reset the extended grapheme state
        indexB = encoding~skipInvalidByteSequence(string, indexB)
        signal forever


::method convertUnicodeToUnicode
    use strict arg targetEncoding
    sizeC = self~codepointCount -- size in codepoints
    buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        targetEncoding~encode(codepoint, buffer)
    end
    return .RexxText~new(buffer~string, targetEncoding)


::method UTF8
    use strict arg -- none
    return self~convertUnicodeToUnicode(.UTF8_Encoding)


::method WTF8
    use strict arg -- none
    return self~convertUnicodeToUnicode(.WTF8_Encoding)


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict arg -- none
    return self~convertUnicodeToUnicode(.UTF16BE_Encoding)


::method UTF16LE
    use strict arg -- none
    return self~convertUnicodeToUnicode(.UTF16LE_Encoding)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict arg -- none
    return self~convertUnicodeToUnicode(.WTF16BE_Encoding)


::method WTF16LE
    use strict arg -- none
    return self~convertUnicodeToUnicode(.WTF16LE_Encoding)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict arg -- none
    return self~convertUnicodeToUnicode(.UTF32BE_Encoding)


::method UTF32LE
    use strict arg -- none
    return self~convertUnicodeToUnicode(.UTF32LE_Encoding)


/******************************************************************************/
::class "XTF8_CommonServices" mixinclass Object private
-- where X stands for U or W

::method codepointMaxBytes class
    use strict arg -- none
    return 4 -- In UTF-8, a codepoint can be from 1 to 4 bytes


::method analyze class
    use strict arg string
    sizeB = string~length -- size in bytes
    -- Bad idea! Must always analyze because CR+LF is a grapheme.
    -- if string~isASCII then return self~new(string, .nil, sizeB, .nil, sizeB) -- no indexation needed
    codepointIndexes = .array~new(sizeB) -- will be removed
    graphemeIndexes = .array~new(sizeB)
    return self~createIndexer(string, codepointIndexes, graphemeIndexes)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return -1 -- end of string
    if sizeB == 1 then return decodeByte(0, "7F"x)
    if sizeB == 2 then return decodeByte(0, "1F"x)  *     64 + decodeByte(1, "3F"x)
    if sizeB == 3 then return decodeByte(0, "0F"x)  *   4096 + decodeByte(1, "3F"x) *   64 +  + decodeByte(2, "3F"x)
    if sizeB == 4 then return decodeByte(0, "07"x)  * 262144 + decodeByte(1, "3F"x) * 4096 +  + decodeByte(2, "3F"x) * 64 + decodeByte(3, "3F"x)
    raise syntax 93.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")

    decodeByte: procedure expose string startB
        use strict arg offset, mask
        return string~subchar(startB + offset)~bitand(mask)~c2d


::method byteSequenceSize class
    -- Helper method for analysis.
    -- Plenty of checks are missing, see nextCodepointIndex for a full check.
    -- Typical usage:
    --     .UTF8_Encoding~decode(string, startB, .UTF8_Encoding~byteSequenceSize(string, startB))
    -- By passing a size to ~decode, the checks are disabled, and that allows to get a codepoint even when ill-formed.
    use strict arg string /* or buffer */, startB=1
    startByte = string~subchar(startB)
    if startByte == "" then 0
    if startByte < "80"x then return    1                  -- 1-byte sequence 0xxxxxxx
    else if startByte~bitand("E0"x) == "C0"x then return 2 -- 2-byte sequence 110xxxxx (C0..DF but only C2..DF is valid)
    else if startByte~bitand("F0"x) == "E0"x then return 3 -- 3-byte sequence 1110xxxx
    else if startByte~bitand("F8"x) == "F0"x then return 4 -- 4-byte sequence 11110xxx
    return 0


::method nextCodepointIndex class
    /*
        Table 3-7. Well-Formed UTF-8 Byte Sequences
            Code Points         First Byte  Second Byte     Third Byte      Fourth Byte
            U+0000..U+007F      00..7F
            U+0080..U+07FF      C2..DF      80..BF                                  CAREFUL! 1st byte C0 and C1 are invalid (non-shortest form)
            U+0800..U+0FFF      E0          A0..BF          80..BF                  CAREFUL! 2nd byte 80..9F are invalid
            U+1000..U+CFFF      E1..EC      80..BF          80..BF
            U+D000..U+D7FF      ED          80..9F          80..BF                  CAREFUL! 2nd byte A0..BF are invalid (high/low surrogate)
            U+E000..U+FFFF      EE..EF      80..BF          80..BF
            U+10000..U+3FFFF    F0          90..BF          80..BF          80..BF  CAREFUL! 2nd byte 80..8F are invalid (non-shortest form)
            U+40000..U+FFFFF    F1..F3      80..BF          80..BF          80..BF
            U+100000..U+10FFFF  F4          80..8F          80..BF          80..BF  CAREFUL! 2nd byte 90..BF are invalid (codepoint > U+10FFFF)
        As a consequence of the well-formedness conditions specified in Table 3-7,
        the following byte values are disallowed in UTF-8:
        C0–C1, F5–FF.
    */
    use strict arg string /* or buffer */, startB
    use strict named arg decodeStatus=.nil
    indexB = startB
    startByte = string~subchar(indexB)
    if startByte == "" then return indexB
    if startByte < "80"x then byteCount = 1                     -- 1-byte sequence 0xxxxxxx
    else if startByte < "C2"x | startByte > "F4"x then signal start_non_shortest_form
    else if startByte~bitand("E0"x) == "C0"x then byteCount = 2 -- 2-byte sequence 110xxxxx (C0..DF but only C2..DF is valid)
    else if startByte~bitand("F0"x) == "E0"x then byteCount = 3 -- 3-byte sequence 1110xxxx
    else if startByte~bitand("F8"x) == "F0"x then byteCount = 4 -- 4-byte sequence 11110xxx
    else signal invalid_start_byte
    indexB += 1
    do i=2 to byteCount
        continuationByte = string~subchar(indexB)
        if continuationByte == "" then signal truncated
        if i == 2 then do
            if startByte == "E0"x, continuationByte < "A0"x then signal non_shortest_form
            if \self~isWTF8, startByte == "ED"x then do
                -- high/low surrogates are not an error if WTF-8 (wobbly)
                if continuationByte >= "A0"x, continuationByte <= "AF"x then signal high_surrogate
                if continuationByte >= "B0"x, continuationByte <= "BF"x then signal low_surrogate
            end
            if startByte == "F0"x, continuationByte < "90"x then signal non_shortest_form
            if startByte == "F4"x, continuationByte >= "90"x then signal error_range
        end
        if continuationByte~bitand("C0"x) <> "80"x then signal invalid_continuation_byte -- Must be 10xxxxxx
        indexB += 1
    end
    return indexB

    invalid_start_byte:        return error(1, startB + 1, "UTF-8 sequence at byte-position" startB "has an invalid start byte" startByte~c2d "("ppHexNumber(startByte~c2d)")")
    start_non_shortest_form:   return error(1, startB + 1, "UTF-8 sequence at byte-position" startB "has an invalid start byte" startByte~c2d "("ppHexNumber(startByte~c2d)") (non-shortest form)")
    invalid_continuation_byte: return error(1, indexB + 1, "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB)
    non_shortest_form:         return error(indexB - startB + 1, indexB + 1, "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(non-shortest form)")
    high_surrogate:            return error(indexB - startB + 1, indexB + 1, "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(high surrogate)")
    low_surrogate:             return error(indexB - startB + 1, indexB + 1, "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(low surrogate)")
    error_range:               return error(indexB - startB + 1, indexB + 1, "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(codepoint > U+10FFFF)")
    truncated:                 return error(1, indexB, "UTF-8 sequence at byte-position" startB "is truncated, expected" byteCount "bytes")

    error:
        use strict arg replacementCount, nextCodepointIndex, errorMessage
        if decodeStatus <> .nil then do
            decodeStatus[1] = errorMessage
            decodeStatus[2] = replacementCount
            return -nextCodepointIndex  -- negative value means error
        end
        raise syntax 93.900 array (errorMessage)


::method skipInvalidByteSequence class
    -- The sequence starting at indexB is invalid.
    -- Go to the next start byte.
    -- This implementation is conform with:
    /*
        If the converter encounters an ill-formed UTF-8 code unit sequence which
        starts with a valid first byte, but which does not continue with valid
        successor bytes (see Table 3-7), it must not consume the successor bytes
        as part of the ill-formed subsequence whenever those successor bytes
        themselves constitute part of a well-formed UTF-8 code unit subsequence.
        For example, with the input UTF-8 code unit sequence <C2 41 42>, such a
        UTF-8 conversion process must not return <U+FFFD> or <U+FFFD, U+0042>,
        because either of those outputs would be the result of misinterpreting a
        well-formed subsequence as being part of the ill-formed subsequence. The
        expected return value for such a process would instead be <U+FFFD, U+0041, U+0042>.

        Although a UTF-8 conversion process is required to never consume well-
        formed subsequences as part of its error handling for ill-formed
        subsequences, such a process is not otherwise constrained in how it
        deals with any ill-formed subsequence itself. An ill-formed subsequence
        consisting of more than one code unit could be treated as a single error
        or as multiple errors.
        For example, in processing the UTF-8 code unit sequence <F0 80 80 41>,
        the only formal requirement mandated by Unicode conformance for a
        converter is that the <41> be processed and correctly interpreted as
        <U+0041>. The converter could return <U+FFFD, U+0041>, handling <F0 80 80>
        as a single error, or <U+FFFD, U+FFFD, U+FFFD, U+0041>, handling each
        byte of <F0 80 80> as a separate error, or could take other approaches
        to signalling <F0 80 80> as an ill-formed code unit subsequence.
    */

    -- This implementation ("Implem") is not conform with:
    /*
        U+FFFD Substitution of Maximal Subparts

        An increasing number of implementations are adopting the handling of
        ill-formed subsequences as specified in the W3C standard for encoding to
        achieve consistent U+FFFD replacements. See:
            http://www.w3.org/TR/encoding/
        The Unicode Standard does not require this practice for conformance. The
        following text describes this practice and gives detailed examples.

        ------------------------------------------------------------------------
        Je pige que dalle aux définitions suivantes...
        ------------------------------------------------------------------------
        D93a Unconvertible offset: An offset in a code unit sequence for which
             no code unit subsequence starting at that offset is well-formed.
        D93b Maximal subpart of an ill-formed subsequence: The longest code unit
        subsequence starting at an unconvertible offset that is either:
            a. the initial subsequence of a well-formed code unit sequence, or
            b. a subsequence of length one.

        This practice can be stated simply as:
        Whenever an unconvertible offset is reached during conversion of a code
        unit sequence:
            1. The maximal subpart at that offset is replaced by a single U+FFFD.
            2. The conversion proceeds at the offset immediately after the maximal
                subpart.
        ------------------------------------------------------------------------
        This practice replaces almost every byte of an ill-formed UTF-8 sequence
        with one U+FFFD. For example:

        Every byte of a “non-shortest form” sequence (see Definition D92),
        or of a truncated version thereof, is replaced, as shown in Table 3-8.
        (The interpretation of “non-shortest form” sequences has been forbidden
        since the publication of Corrigendum #1.)
            Table 3-8. U+FFFD for Non-Shortest Form Sequences
            Bytes  C0   AF   E0   80   BF   F0   81   82   41
            Output FFFD FFFD FFFD FFFD FFFD FFFD FFFD FFFD 0041
            Implem U+002F U+003F U+FFFD U+0041

        Also, every byte of a sequence that would correspond to a surrogate code
        point,or of a truncated version thereof, is replaced with one U+FFFD, as
        shown in Table 3-9. (The interpretation of such byte sequences has been
        forbidden since Unicode 3.2.)
            Table 3-9. U+FFFD for Ill-Formed Sequences for Surrogates
            Bytes  ED   A0   80   ED   BF   BF   ED   AF   41
            Output FFFD FFFD FFFD FFFD FFFD FFFD FFFD FFFD 0041
            Implem U+FFFD U+FFFD U+FFFD U+0041

        Finally, every byte of a sequence that would correspond to a code point
        beyond U+10FFFF, and any other byte that does not contribute to a valid
        sequence, is also replaced with one U+FFFD, as shown in Table 3-10
            Table 3-10. U+FFFD for Other Ill-Formed Sequences
            Bytes  F4   91   92   93   FF   41   80   BF   42
            Output FFFD FFFD FFFD FFFD FFFD 0041 FFFD FFFD 0042
            Implem U+000E45D3 U+FFFD U+0041 U+FFFD U+0042
    */

    -- This implementation ("Implem") is conform with:
    /*
        Only when a sequence of two or three bytes is a truncated version of a
        sequence which is otherwise well-formed to that point, is more than one
        byte replaced with a single U+FFFD, as shown in Table 3-11.
            Table 3-11. U+FFFD for Truncated Sequences
            Bytes  E1   80   E2   F0   91 92 F1 BF 41
            Output FFFD      FFFD FFFD       FFFD  0041
            Implem U+FFFD U+FFFD U+FFFD U+FFFD U+0041
    */
    use strict arg string /* or buffer */, indexB
    do forever
        indexB += 1
        byte = string~subchar(indexB)
        if byte == "" then return indexB
        if byte < "80"x then return indexB                     -- 1-byte sequence 0xxxxxxx
        else if byte~bitand("E0"x) == "C0"x then return indexB -- 2-byte sequence 110xxxxx
        else if byte~bitand("F0"x) == "E0"x then return indexB -- 3-byte sequence 1110xxxx
        else if byte~bitand("F8"x) == "F0"x then return indexB -- 4-byte sequence 11110xxx
    end


-- utf8proc_ssize_t utf8proc_encode_char(utf8proc_int32_t codepoint, utf8proc_uint8_t *dst);
::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint, buffer=.nil
    returnBuffer = buffer <> .nil
    if buffer == .nil then buffer = .MutableBuffer~new(, self~codepointMaxBytes)
    self~checkCodepoint(codepoint, checkOnlyRange:.true)            -- check only range, the other errors will be detected during analysis
    if codepoint < 128 then do                                      -- if (uc < 0x80) {
        buffer~append(codepoint~d2c)                                -- dst[0] = (utf8proc_uint8_t) uc;
    end                                                             -- return 1;
    else if codepoint < 2048 then do                                -- } else if (uc < 0x800) {
        buffer~append((192 + codepoint % 64)~d2c)                   -- dst[0] = (utf8proc_uint8_t)(0xC0 + (uc >> 6))
        buffer~append((128 + codepoint // 64)~d2c)                  -- dst[1] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    end                                                             -- return 2;
    else if codepoint < 65536 then do
        buffer~append((224 + codepoint % 4096)~d2c)                 -- dst[0] = (utf8proc_uint8_t)(0xE0 + (uc >> 12));
        buffer~append((128 + (codepoint % 64) // 64)~d2c)           -- dst[1] = (utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
        buffer~append((128 + codepoint // 64)~d2c)                  -- dst[2] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    end                                                             -- return 3;
    else if codepoint <= 1114111 then do                            -- } else if (uc < 0x110000) {
        buffer~append((240 + codepoint % 262144)~d2c)               -- dst[0] = (utf8proc_uint8_t)(0xF0 + (uc >> 18));
        buffer~append((128 + (codepoint % 4096) // 64)~d2c)         -- dst[1] = (utf8proc_uint8_t)(0x80 + ((uc >> 12) & 0x3F));
        buffer~append((128 + (codepoint % 64) // 64)~d2c)           -- dst[2] = (utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
        buffer~append((128 + codepoint // 64)~d2c)                  -- dst[3] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    end                                                             -- return 4;
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


/********************/
/* Instance methods */
/********************/

::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    if indexC < 1 | indexC > self~codepointCount then raise syntax 93.900 array (self~description "invalid codepoint index:" indexC)
    if self~codepointIndexes == .nil then do
        if decode then return self~string~subchar(indexC)~c2d
                  else return self~string~subchar(indexC)
    end
    startB = self~codepointIndexes[indexC]
    nextB = self~codepointIndexes[indexC+1]
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB)


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeCount then raise syntax 93.900 array (self~description "invalid grapheme index:" indexG)
    if self~graphemeIndexes == .nil then return .RexxText~new(self~string~subchar(indexG), self~class)
    startB = self~graphemeIndexes[indexG]
    nextB = self~graphemeIndexes[indexG+1]
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class)


::method UTF8
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg -- none
    return .RexxText~new(.String~new(self~string), .UTF8_Encoding)


::method WTF8
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg -- none
    return .RexxText~new(.String~new(self~string), .WTF8_Encoding)


/******************************************************************************/
::class "UTF8_Encoding" public inherit XTF8_CommonServices Unicode_CommonServices StringIndexer

::method name class
    use strict arg -- none
    return "UTF-8"


::method isUTF8 class
    use strict arg -- none
    return .true


::method BOM class
    return "EF BB BF"x


::method checkCodepoint class
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, decodeStatus=.nil
    if codepoint < 0 | codepoint > 1114111 then signal error_range
    if checkOnlyRange then return .true
    if codepoint >= 55296 & codepoint < 56320 then signal error_high_surrogate -- U+D800 to U+DBFF high surrogates
    if codepoint >= 56320 & codepoint < 57344 then signal error_low_surrogate  -- U+DC00 to U+DFFF low surrogates
    return .true

    error_range:          return error(4, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..1114111")
    error_high_surrogate: return error(3, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". High surrogate is not allowed")
    error_low_surrogate:  return error(3, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Low surrogate is not allowed")

    error:
        use strict arg replacementCount, errorMessage
        if decodeStatus <> .nil then do
            decodeStatus[1] = errorMessage
            decodeStatus[2] = replacementCount
            return false
        end
        raise syntax 93.900 array (errorMessage)


/******************************************************************************/
::class "WTF8_Encoding" public inherit XTF8_CommonServices Unicode_CommonServices StringIndexer
/*
https://simonsapin.github.io/wtf-8/#16-bit-code-unit
WTF-8 (Wobbly Transformation Format − 8-bit) is a superset of UTF-8 that encodes
surrogate code points if they are not in a pair.
It represents, in a way compatible with UTF-8, text from systems such as
JavaScript and Windows that use UTF-16 internally but don’t enforce the
well-formedness invariant that surrogates must be paired.

Concatenating WTF-8 strings requires extra care to preserve well-formedness.
*/

::method name class
    use strict arg -- none
    return "WTF-8" --


--::method isUTF8 class
-- WTF8 is not UTF8


::method isWTF8 class
    use strict arg -- none
    return .true


::method BOM class
    return "EF BB BF"x


::method checkCodepoint class
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, decodeStatus=.nil
    if codepoint < 0 | codepoint > 1114111 then signal error_range
    if checkOnlyRange then return .true
    if previousCodepoint <> .nil,,
       previousCodepoint >= 55296 & previousCodepoint < 56320,, -- U+D800 to U+DBFF high surrogates
       codepoint >= 56320 & codepoint < 57344,                  -- U+DC00 to U+DFFF low surrogates
    then signal error_high_low_surrogate
    return .true

    error_range:              return error(4, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..1114111")
    error_high_low_surrogate: return error(6, self~name "encoding: a high surrogate" previousCodepoint "("ppCodepoint(previousCodepoint)")" || atBytePosition(previousCodepointIndexB) || " followed by a low surrogate" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || " is not allowed")

    error:
        use strict arg replacementCount, errorMessage
        if decodeStatus <> .nil then do
            decodeStatus[1] = errorMessage
            decodeStatus[2] = replacementCount
            return false
        end
        raise syntax 93.900 array (errorMessage)


/*
https://simonsapin.github.io/wtf-8/#concatenating
1. If the left input string ends with a lead surrogate byte sequence and the
   right input string starts with a trail surrogate byte sequence, run these substeps:
    1. Let lead and trail be two code points, the respective results of decoding
       from WTF-8 these two surrogate byte sequences.
    2. Let supplementary be the encoding to WTF-8 of a single code point of value
       0x10000 + ((lead - 0xD800) << 10) + (trail - 0xDC00)
    3. Let left be substring of the left input string that removes the three final bytes.
    4. Let right be substring of the right input string that removes the three initial bytes.
    5. Return the concatenation of left, supplementary, and right.
2. Otherwise, return the concatenation of the two input byte sequences

Note: This is equivalent to converting both strings to potentially ill-formed
UTF-16, concatenating the resulting 16-bit code unit sequences, then converting
the concatenation back to WTF-8.
*/
::method appendToBuffer class
    use strict arg buffer, string
    if buffer~length >= 3, string~length >= 3 then do
        bufferIndexB = buffer~length - 2
        if buffer~subchar(bufferIndexB)~bitand("F0"x) == "E0"x,, -- 3-byte sequence on left
           string~subchar(1)~bitand("F0"x) == "E0"x,             -- 3-byte sequence on right
        then do
            -- buffer can be UTF-8 or WTF-8, we can decode it as WTF-8
            cp1 = self~decode(buffer, bufferIndexB, 3)
            cp2 = self~decode(string, 1, 3)
            if cp1 >= 55296 & cp1 < 56320,,   -- U+D800 to U+DBFF high surrogates
               cp2 >= 56320 & cp2 < 57344,    -- U+DC00 to U+DFFF low surrogates
            then do
                h = (cp1 - 55296) * 1024 -- Take the high surrogate and subtract 0xD800, then multiply by 0x400
                l = cp2 - 56320 -- Take the low surrogate and subtract 0xDC00
                surrogate = h + l + 65536 -- Add these two results together, and finally add 0x10000
                buffer~delete(bufferIndexB)
                self~encode(surrogate, buffer)
                return
            end
        end
    end
    buffer~append(string)


/******************************************************************************/
::class "XTF16_CommonServices" mixinclass Object private
-- where X stands for U or W

::method codepointMaxBytes class
    use strict arg -- none
    return 4  -- In UTF-16, a codepoint can be 2 or 4 bytes


::method analyze class
    use strict arg string
    size = 1 + string~length % 2 -- The final size will be <=
    codepointIndexes = .array~new(size) -- will be removed
    graphemeIndexes = .array~new(size)
    return self~createIndexer(string, codepointIndexes, graphemeIndexes)


::method checkCodepoint class
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false /*no impact here*/, decodeStatus=.nil
    if codepoint < 0 | codepoint > 1114111 then signal error_range
    return .true

    error_range: return error(2, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..1114111")

    error:
        use strict arg replacementCount, errorMessage
        if decodeStatus <> .nil then do
            decodeStatus[1] = errorMessage
            decodeStatus[2] = replacementCount
            return false
        end
        raise syntax 93.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return -1
    if sizeB == 2 then return self~decodeCodepoint(string~substr(startB, 2))
    if sizeB == 4 then do
        high_surrogate = self~decodeCodepoint(string~substr(startB, 2))
        low_surrogate = self~decodeCodepoint(string~substr(startB + 2, 2))
        h = (high_surrogate - 55296) * 1024 -- Take the high surrogate and subtract 0xD800, then multiply by 0x400
        l = low_surrogate - 56320 -- Take the low surrogate and subtract 0xDC00
        return h + l + 65536 -- Add these two results together, and finally add 0x10000
    end
    raise syntax 93.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use strict named arg decodeStatus=.nil
    wobbly = self~isWTF16
    indexB = startB
    lengthB = string~length
    if indexB > lengthB then return indexB -- end of string
    if lengthB - indexB < 1 then signal truncated2
    codeUnit = self~codeUnit(string~substr(indexB, 2))
    indexB += 2
    if codeUnit >= "D800"x & codeUnit <= "DBFF"x then do
        -- got high surrogate, get low surrogate
        if indexB > lengthB then do
            -- end of string, no low surrogate but it's acceptable to consider
            -- the high surrogate as a standalone codepoint, when wobbly mode
            if wobbly then return indexB
                      else signal unpaired_high_surrogate
        end
        if lengthB - indexB < 1 then signal truncated4
        codeUnit = self~codeUnit(string~substr(indexB, 2))
        if codeUnit >= "DC00"x & codeUnit <= "DFFF"x then indexB += 2 -- this is a valid low surrogate
        else do
            -- no valid low surrogate but it's acceptable to consider the high
            -- surrogate as a standalone codepoint, when wobbly mode
            if wobbly then return indexB
                      else signal invalid_low_surrogate
        end
    end
    else if \wobbly, codeUnit >= "DC00"x & codeUnit <= "DFFF"x then signal unpaired_low_surrogate
    return indexB

    unpaired_high_surrogate: return error(1, indexB, self~name "encoding: unpaired high surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" startB)
    unpaired_low_surrogate:  return error(1, indexB, self~name "encoding: unpaired low surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" startB)
    invalid_low_surrogate:   return error(1, indexB, self~name "encoding: invalid low surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" indexB)
    truncated2:              return error(1, indexB + 2, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 2 bytes")
    truncated4:              return error(2, indexB + 2, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 4 bytes")

    error:
        use strict arg replacementCount, nextCodepointIndex, errorMessage
        if decodeStatus <> .nil then do
            decodeStatus[1] = errorMessage
            decodeStatus[2] = replacementCount
            return -nextCodepointIndex  -- negative value means error
        end
        raise syntax 93.900 array (errorMessage)


::method skipInvalidByteSequence class
    -- The sequence starting at indexB is invalid.
    -- Go to the next code unit.
    use strict arg string /* or buffer */, indexB
    lengthB = string~length
    indexB += 2
    if indexB > lengthB then return lengthB + 1 -- end of string
    return indexB


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint, buffer=.nil
    returnBuffer = buffer <> .nil
    if buffer == .nil then buffer = .MutableBuffer~new(, self~codepointMaxBytes)
    self~checkCodepoint(codepoint, checkOnlyRange:.true) -- check only range, the other errors will be detected during analysis
    if codepoint < 55296 then do -- U+0000 to U+D7FF
        buffer~append(self~encodeCodepoint(codepoint))
    end
    else if codepoint < 65536 then do -- U+E000 to U+FFFF
        buffer~append(self~encodeCodepoint(codepoint))
    end
    else if codepoint <= 1114111 then do -- U+010000 to U+10FFFF
        buffer~append(self~encodeCodepoint(55296 + (codepoint - 65536) % 1024))     -- high surrogate: Subtract 0x10000, shift right by 10 (divide by 0x400), then add 0xD800
        buffer~append(self~encodeCodepoint(56320 + (codepoint - 65536) // 1024))    -- low surrogate: Subtract 0x10000, take the low 10 bits (remainder of dividing by 0x400), then add 0xDC0
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


/********************/
/* Instance methods */
/********************/

::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    if indexC < 1 | indexC > self~codepointCount then raise syntax 93.900 array (self~description "invalid codepoint index:" indexC)
    startB = self~codepointIndexes[indexC]
    nextB = self~codepointIndexes[indexC+1]
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB)


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeCount then raise syntax 93.900 array (self~description "invalid grapheme index:" indexG)
    startB = self~graphemeIndexes[indexG]
    nextB = self~graphemeIndexes[indexG+1]
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class)


/******************************************************************************/
::class "XTF16BE_CommonServices" mixinclass Object private
-- where X stands for U or W

::method codeUnit class
    -- Ex : B0FE --> B0FE
    use strict arg codeUnit
    return codeUnit


::method decodeCodepoint class
    use strict arg codepoint
    return codepoint~c2d


::method encodeCodepoint class
    use strict arg codepoint
    return codepoint~d2c(2)


::method encodeASCIIstring class
    use strict arg string
    sizeB = string~length -- size in bytes
    buffer = .MutableBuffer~new(, sizeB * 2) -- yes, always 2, no need to use codepointMaxBytes
    do i=1 to sizeB
        buffer~append("00"x) -- big endian
        buffer~append(string~subchar(i))
    end
    return .RexxText~new(buffer~string, self)


::method UTF16BE
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg -- none
    return .RexxText~new(.String~new(self~string), .UTF16BE_Encoding)


::method WTF16BE
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg -- none
    return .RexxText~new(.String~new(self~string), .WTF16BE_Encoding)


/******************************************************************************/
::class "XTF16LE_CommonServices" mixinclass Object private
-- where X stands for U or W

::method codeUnit class
    -- Ex : FEB0 --> B0FE
    use strict arg codeUnit
    return codeUnit~reverse


::method decodeCodepoint class
    use strict arg codepoint
    return codepoint~reverse~c2d


::method encodeCodepoint class
    use strict arg codepoint
    return codepoint~d2c(2)~reverse


::method encodeASCIIstring class
    use strict arg string
    sizeB = string~length -- size in bytes
    buffer = .MutableBuffer~new(, sizeB * 2) -- yes, always 2, no need to use codepointMaxBytes
    do i=1 to sizeB
        buffer~append(string~subchar(i))
        buffer~append("00"x) -- little endian
    end
    return .RexxText~new(buffer~string, self)


::method UTF16LE
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg -- none
    return .RexxText~new(.String~new(self~string), .UTF16LE_Encoding)


::method WTF16LE
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg -- none
    return .RexxText~new(.String~new(self~string), .WTF16LE_Encoding)


/******************************************************************************/
::class "UTF16BE_Encoding" public inherit XTF16BE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer

::method name class
    use strict arg -- none
    return "UTF-16BE"


::method isUTF16 class
    use strict arg -- none
    return .true


::method isUTF16BE class
    use strict arg -- none
    return .true


::method BOM class
    return "FE FF"x


/******************************************************************************/
::class "UTF16LE_Encoding" public inherit XTF16LE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer

::method name class
    use strict arg -- none
    return "UTF-16LE"


::method isUTF16 class
    use strict arg -- none
    return .true


::method isUTF16LE class
    use strict arg -- none
    return .true


::method BOM class
    return "FF FE"x


/******************************************************************************/
::class "WTF16BE_Encoding" public inherit XTF16BE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer
/*
https://simonsapin.github.io/wtf-8/#16-bit-code-unit
WTF-16 is sometimes used as a shorter name for potentially ill-formed UTF-16,
especially in the context of systems were originally designed for UCS-2 and
later upgraded to UTF-16 but never enforced well-formedness, either by neglect
or because of backward-compatibility constraints.

A sequence of 16-bit code units is potentially ill-formed UTF-16 if it is
intended to be interpreted as UTF-16, but is not necessarily well-formed in
UTF-16. It effectively encodes a sequence of code points that do not contain any
surrogate code point pair.

Concatenating WTF-16 strings is easy: no extra care, just concatenate the bytes.
*/

::method name class
    use strict arg -- none
    return "WTF-16BE"


--::method isUTF16 class
-- WTF-16 is not UTF-16


--::method isUTF16BE class
-- WTF16-BE is not UTF-16BE


::method isWTF16 class
    use strict arg -- none
    return .true


::method isWTF16BE class
    use strict arg -- none
    return .true


::method BOM class
    return "FE FF"x


/******************************************************************************/
::class "WTF16LE_Encoding" public inherit XTF16LE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer

::method name class
    use strict arg -- none
    return "WTF-16LE"


--::method isUTF16 class
-- WTF16 is not UTF16


--::method isUTF16LE class
-- WTF-16LE is not UTF-16LE


::method isWTF16 class
    use strict arg -- none
    return .true


::method isWTF16LE class
    use strict arg -- none
    return .true


::method BOM class
    return "FF FE"x


/******************************************************************************/
::class "UTF32_CommonServices" mixinclass Object private

::method codepointMaxBytes class
    use strict arg -- none
    return 4  -- In UTF-32, a codepoint is 4 bytes


::method analyze class
    use strict arg string
    size = 1 + string~length % 4 -- The final size will be <=
    codepointIndexes = .array~new(size) -- will be removed
    graphemeIndexes = .array~new(size)
    return self~createIndexer(string, codepointIndexes, graphemeIndexes)


::method checkCodepoint class
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false /*no impact here*/, decodeStatus=.nil
    if codepoint < 0 | codepoint > 1114111 then signal error_range
    return .true

    error_range: return error(1, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..1114111")

    error:
        use strict arg replacementCount, errorMessage
        if decodeStatus <> .nil then do
            decodeStatus[1] = errorMessage
            decodeStatus[2] = replacementCount
            return false
        end
        raise syntax 93.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB, sizeB=(-1)
    /*
        "07 FF FF FF"x~c2d=     134217727
        "80 FF FF FF"x~c2d=     C2D result is not a valid whole number with NUMERIC DIGITS 9
    */
    numeric digits 10
    /*
        "80 FF FF FF"x~c2d=     2164260863
        "FF FF FF FF"x~c2d=     4294967295
    */
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return -1
    if sizeB == 4 then return self~decodeCodepoint(string~substr(startB, 4))
    raise syntax 93.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use named arg decodeStatus=.nil
    indexB = startB
    lengthB = string~length
    if indexB > lengthB then return indexB -- end of string
    if lengthB - indexB < 3 then signal truncated
    codeUnit = string~substr(indexB, 4)
    indexB += 4
    return indexB

    truncated: return error(1, indexB + 4, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 4 bytes")

    error:
        use strict arg replacementCount, nextCodepointIndex, errorMessage
        if decodeStatus <> .nil then do
            decodeStatus[1] = errorMessage
            decodeStatus[2] = replacementCount
            return -nextCodepointIndex  -- negative value means error
        end
        raise syntax 93.900 array (errorMessage)


::method skipInvalidByteSequence class
    -- The sequence starting at indexB is invalid.
    -- Go to the next code unit.
    use strict arg string /* or buffer */, indexB
    lengthB = string~length
    indexB += 4
    if indexB > lengthB then return lengthB + 1 -- end of string
    return indexB


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint, buffer=.nil
    returnBuffer = buffer <> .nil
    if buffer == .nil then buffer = .MutableBuffer~new(, self~codepointMaxBytes)
    self~checkCodepoint(codepoint, checkOnlyRange:.true) -- check only range, the other errors will be detected during analysis
    buffer~append(self~encodeCodepoint(codepoint))
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


/********************/
/* Instance methods */
/********************/

::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    if indexC < 1 | indexC > self~codepointCount then raise syntax 93.900 array (self~description "invalid codepoint index:" indexC)
    startB = self~codepointIndexes[indexC]
    nextB = self~codepointIndexes[indexC+1]
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB)


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeCount then raise syntax 93.900 array (self~description "invalid grapheme index:" indexG)
    startB = self~graphemeIndexes[indexG]
    nextB = self~graphemeIndexes[indexG+1]
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class)


/******************************************************************************/
::class "UTF32BE_Encoding" public inherit UTF32_CommonServices Unicode_CommonServices StringIndexer

::method name class
    use strict arg -- none
    return "UTF-32BE"


::method isUTF32 class
    use strict arg -- none
    return .true


::method isUTF32BE class
    use strict arg -- none
    return .true


::method BOM class
    return "00 00 FE FF"x


::method decodeCodepoint class
    use strict arg codepoint
    return codepoint~c2d


::method encodeCodepoint class
    use strict arg codepoint
    return codepoint~d2c(4)


::method encodeASCIIstring class
    use strict arg string
    sizeB = string~length -- size in bytes
    buffer = .MutableBuffer~new(, sizeB * 2) -- yes, always 2, no need to use codepointMaxBytes
    do i=1 to sizeB
        buffer~append("000000"x) -- big endian
        buffer~append(string~subchar(i))
    end
    return .RexxText~new(buffer~string, self)


::method UTF32BE
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg -- none
    return .RexxText~new(.String~new(self~string), .UTF32BE_Encoding)


/******************************************************************************/
::class "UTF32LE_Encoding" public inherit UTF32_CommonServices Unicode_CommonServices StringIndexer

::method name class
    use strict arg -- none
    return "UTF-32LE"


::method isUTF32 class
    use strict arg -- none
    return .true


::method isUTF32LE class
    use strict arg -- none
    return .true


::method BOM class
    return "FF FE 00 00"x


::method decodeCodepoint class
    use strict arg codepoint
    return codepoint~reverse~c2d


::method encodeCodepoint class
    use strict arg codepoint
    return codepoint~d2c(4)~reverse


::method encodeASCIIstring class
    use strict arg string
    sizeB = string~length -- size in bytes
    buffer = .MutableBuffer~new(, sizeB * 2) -- yes, always 2, no need to use codepointMaxBytes
    do i=1 to sizeB
        buffer~append(string~subchar(i))
        buffer~append("000000"x) -- little endian
    end
    return .RexxText~new(buffer~string, self)


::method UTF32LE
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg -- none
    return .RexxText~new(.String~new(self~string), .UTF32LE_Encoding)


/******************************************************************************/
::class "CodePointSupplier" public subclass Supplier

::method init
    expose indexer indexC
    use strict arg indexer
    empty = .array~new(0) -- No need to create a copy, the string is immutable
    self~init:super(empty, empty)
    indexC = 1
    -- will add a byte index


::method count
    expose indexer
    use strict arg -- none
    return indexer~codepointCount


::method available
    expose indexer indexC
    use strict arg -- none
    return indexC <= indexer~codepointCount


::method index
    expose indexC
    use strict arg -- none
    if self~available then return indexC


::method item
    expose indexer indexC
    use strict arg decode=.true
    if self~available then return indexer~codepoint(indexC, decode)


::method next
    expose indexC
    use strict arg -- none
    indexC += 1
    -- will also manage a byte index


/******************************************************************************/
::class "GraphemeSupplier" public subclass Supplier

::method init
    expose indexer indexG
    use strict arg indexer
    empty = .array~new(0) -- No need to create a copy, the string is immutable
    self~init:super(empty, empty)
    indexG = 1


::method count
    expose indexer
    use strict arg -- none
    return indexer~graphemeCount


::method available
    expose indexer indexG
    use strict arg -- none
    return indexG <= indexer~graphemeCount


::method index
    expose indexG
    use strict arg -- none
    if self~available then return indexG


::method item
    expose indexer indexG
    use strict arg -- none
    if self~available then return indexer~grapheme(indexG)


::method next
    expose indexG
    use strict arg -- none
    indexG += 1


/******************************************************************************/
-- Helper to create a table of transcoded characters, from codepoint 0 to size-1.
-- By default, a transcoded character is equal to itself.
-- The specific transcoding table lets define specific values for some characters.
::routine createCharacterTranscodingTable private
    use strict arg size, specificTranscoding
    tableTranscodingToUnicode = .array~new(size)
    do i = 0 to size-1
        tableTranscodingToUnicode[i+1] = i -- bof bof... 1-based
    end
    nextSpecificIndex = 0
    do i=1 to specificTranscoding~items
        item = specificTranscoding[i]
        if item~right(1) == ":" then do -- Ends with colon, this is an index. For example: "80:"
            nextSpecificIndex = item~left(item~length - 1)~x2d
        end
        else do
            if item == "" then codepoint = "" -- no transcoding
            else if item~left(1) == "-" then codepoint = -(item~substr(2)~x2d) -- unused character with fallback transcoding. For example: "-81" --> -129
            else codepoint = item~x2d
            tableTranscodingToUnicode[nextSpecificIndex+1] = codepoint -- bof bof... 1-based array
            nextSpecificIndex += 1
        end
    end
    return tableTranscodingToUnicode


/******************************************************************************/
::routine ppHexNumber public
    -- Helper to display an hexadecimal value: 0 --> 00x, 255 --> FFx
    -- The value can be negative: -1 --> -01x
    use strict arg number
    if \datatype(number, "W") then return "??"
    sign = ""
    if sign(number) < 0 then sign = "-"
    number = abs(number)
    if number < 256 then size = 2
    else if number < 65536 then size = 4
    else if number < 16777216 then size = 6
    else size = 8
    return sign || number~d2x(size) || "x"


/******************************************************************************/
::routine ppCodepoint public
    /*
    Appendix A - Notational conventions
    In running text, an individual Unicode code point is expressed as U+n, where n is four to
    six hexadecimal digits, using the digits 0–9 and uppercase letters A–F (for 10 through 15,
    respectively). Leading zeros are omitted, unless the code point would have fewer than four
    hexadecimal digits—for example, U+0001, U+0012, U+0123, U+1234, U+12345, U+102345
    */
    -- precondition: codepoint >= 0
    use strict arg codepoint, buffer=.nil
    if \datatype(codepoint, "W") then return "??"
    if buffer == .nil then do
        if codepoint < 65536 then return "U+" || codepoint~d2x(4)
        return "U+" || codepoint~d2x
    end
    else do
        buffer~append("U+")
        if codepoint < 65536 then buffer~append(codepoint~d2x(4))
        else buffer~append(codepoint~d2x)
        return buffer
    end


/******************************************************************************/
-- Helper to build error messages.
-- Sometimes, the byte index is not available.
::routine atBytePosition
    use strict arg byteIndex
    if byteIndex == .nil then return ""
    return " at byte-position" byteIndex -- Keep the space at the begining!


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
