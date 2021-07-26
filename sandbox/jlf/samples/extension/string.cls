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
        encoding = .Encoding~factory(encoding)
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
    encoding = .Encoding~factory(encoding)
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
    newEncoding = .Encoding~factory(newEncoding)
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


::method isUTF16
    forward to (self~indexer~class)


::method isWTF16
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
    if self~isUTF8, \self~isWTF8 then return self
    forward to (self~indexer) -- always new String and new RexxText


-- WTF-8 representation
::method WTF8
    use strict arg -- none
    if self~isWTF8 then return self
    forward to (self~indexer) -- always new String and new RexxText


-- UTF-16BE representation
::method UTF16
    use strict arg -- none
    if self~isUTF16, \self~isWTF16 then return self
    forward to (self~indexer) -- always new String and new RexxText


-- WTF-16BE representation
::method WTF16
    use strict arg -- none
    if self~isWTF16 then return self
    forward to (self~indexer) -- always new String and new RexxText


::method c2x
    forward to (self~indexer)


::method c2u
    forward to (self~indexer)


::method isASCII
    use strict arg -- none
    return (self~isByte | self~isUTF8) & self~string~isASCII


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


::method analyze class
    use strict arg string, encoding, codepointIndexes, graphemeIndexes
    errors = .nil
    indexB = 1
    previousCodepoint = .nil
    graphemeBreakArgs = (-1, -1, 0) -- codepoint1, codepoint2, state. Will use the same array at each iteration.

    forever:
        signal on syntax -- catch any encoding error
        nextB = encoding~nextCodepointIndex(string, indexB)
        codepoint = encoding~decode(string, indexB, nextB - indexB) -- can be -1 if nextB == indexB
        if codepoint <> -1 then encoding~checkCodepoint(codepoint, previousCodepoint)

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
            if self~GraphemeBreak(graphemeBreakArgs) then do
                graphemeIndexes~append(indexB)
            end
        end
        previousCodepoint = codepoint
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
        if errors = .nil then errors = .array~new
        condition = condition("O")
        errors~append(condition["MESSAGE"])
        codepointIndexes~append(-indexB) -- negative value to indicate error
        graphemeIndexes~append(-indexB) -- idem
        previousCodepoint = .Unicode~replacementCharacter~codepoint
        graphemeBreakArgs[3] = 0 -- reset the extended grapheme state
        indexB = encoding~skipInvalidByteSequence(string, indexB)
        signal forever


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
    expose codepoint
    use strict arg -- none
    return .UTF16BE_Encoding~encode(codepoint)


/******************************************************************************/
::class "Encoding" public

/*
big-endian, little-endian
0x44332211
     0  1  2  3
BE  44 33 22 11
LE  11 22 33 44

~c2x is compatible with big-endian:
"44332211"x~c2x -- 44332211

UTF-8 BOM: 0xEF 0xBB 0xBF

UTF-16 BOM: 0xFEFF
BE: FE FF
LE: FF FE

UTF-32 BOM: 0x0000FEFF
LE: 0xFF 0xFE 0x00 0x00
BE: 0x00 0x00 0xFE 0xFF

https://www.ietf.org/rfc/rfc2781.txt
    UTF-16, an encoding of ISO 10646
    This document describes the UTF-16 encoding of Unicode/ISO-10646,
    addresses the issues of serializing UTF-16 as an octet stream for
    transmission over the Internet, discusses MIME charset naming as
    described in [CHARSET-REG], and contains the registration for three
    MIME charset parameter values: UTF-16BE (big-endian), UTF-16LE
    (little-endian), and UTF-16.
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
    encodings["CP1252"] = .CP1252_Encoding
    encodings["WINDOWS1252"] = .CP1252_Encoding
    -- encodings["ISO88591"] = .ISO88591_Encoding
    -- encodings["LATIN1"] = .ISO88591_Encoding
    -- encodings["ISO885915"] = .ISO885915_Encoding
    -- encodings["LATIN9"] = .ISO885915_Encoding
    encodings["UTF8"] = .UTF8_Encoding
    encodings["WTF8"] = .WTF8_Encoding
    encodings["UTF16BE"] = .UTF16BE_Encoding
    encodings["WTF16BE"] = .WTF16BE_Encoding
    -- encodings["UTF16LE"] = .UTF16LE_Encoding
    encodings["UTF16"] = .UTF16BE_Encoding -- The Unicode norm specifies that the default UTF-16 is big endian
    encodings["WTF16"] = .WTF16BE_Encoding


::method supported class
    expose encodings
    use strict arg -- none
    return encodings~supplier


::method factory class
    expose encodings
    use strict arg encoding
    if encoding~isA(.Class), encoding~isSubClassOf(.StringIndexer) then return encoding
    encoding = encoding~string
    -- Remove all dash, underscore and spaces: "UTF8", "UTF_8", "UTF-8", "UTF 8" are all a valid encoding name
    encodingName = encoding~translate(, "_- "," ")~space(0)~upper
    if encodingName == "DEFAULT" then return .Encoding~defaultEncoding
    if encodings~hasEntry(encodingName) then return encodings[encodingName]
    raise syntax 93.900 array("Encoding: '"encoding"' is not supported")


::method forConcatenation class
    use strict arg left, right
    leftEncoding = left~encoding
    rightEncoding = right~encoding
    if leftEncoding == rightEncoding then return leftEncoding
    if leftEncoding~isUTF8, rightEncoding~isUTF8 then return .WTF8_Encoding -- at least one encoding is WTF-8
    if left~isASCII, rightEncoding~isUTF8 then return rightEncoding -- can be UTF-8 or WTF-8
    if leftEncoding~isUTF8, right~isASCII then return leftEncoding  -- can be UTF-8 or WTF-8
    if leftEncoding~isUTF16, rightEncoding~isUTF16 then return .WTF16BE_Encoding -- at least one encoding is WTF-16
    raise syntax 93.900 array("Encoding: cannot concatenate" left~description(short:.true) "text with" right~description(short:.true) "text")


::method comparisonMode class
    -- if a byte comparison is possible then return "b"
    -- if a unicode comparision is possible then return "u"
    -- otherwise raise an error
    use strict arg left, right
    if left~isByte & right~isByte then return "b"
    if left~isASCII & right~isASCII then return "b"
    if left~isASCII & right~isUTF8 then return "u"
    if left~isUTF8 & right~isASCII then return "u"
    if left~isUnicode & right~isUnicode then return "u"
    raise syntax 93.900 array("Encoding: cannot compare" left~description(short:.true) "text with" right~description(short:.true) "text")


/******************************************************************************/
::class "StringIndexer" public -- abstract

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


::method isWTF16 class
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


::method c2u
    use strict arg -- none
    codepoints = self~codepoints
    buffer = .MutableBuffer~new
    first = .true
    do while codepoints~available
        if \first then buffer~append(" ")
        first = .false
        buffer~append("U+")
        codepoint = codepoints~item
        if codepoint < 65536 then size = 4
                             else size = 8
        buffer~append(codepoint~d2x(size))
        codepoints~next
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


::method WTF16 abstract


::method appendToBuffer class
    -- WTF-8 overrides this method
    use strict arg buffer, string
    buffer~append(string)


/******************************************************************************/
::class "Byte_Encoding" subclass StringIndexer public

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
    use strict arg codepoint, previousCodepoint=.nil
    use strict named arg checkOnlyRange -- no impact here
    if codepoint < 0 | codepoint > 255 then signal error_range
    return .true
    error_range: raise syntax 93.900 array (self~name "encoding: invalid codepoint" codepoint "("ppHexNumber(codepoint)"). Allowed range is 0..255")


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
    raise syntax 93.900 array (self~name "encoding:" sizeB "is an invalid codepoint size")


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
    use strict arg indexC
    if indexC < 1 | indexC > self~codepointCount then raise syntax 93.900 array (self~description "invalid codepoint index:" indexC)
    return self~string~subchar(indexC)~c2d


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeCount then raise syntax 93.900 array (self~description "invalid grapheme index:" indexG)
    return .RexxText~new(self~string~subchar(indexG), self~class)


::method convertToUnicode private
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
    raise syntax 93.900 array(self~name "encoding: cannot convert" self~description(short:.true) "to" targetEncoding~name)


::method UTF8
    use strict arg targetEncoding=.UTF8_Encoding
    use strict named arg strict=.true
    -- yes, always a new string. The original string is still associated to the Byte_Encoding.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if self~string~isASCII then return .RexxText~new(.String~new(self~string), targetEncoding)
    return self~convertToUnicode(targetEncoding, strict: strict)


::method WTF8
    use strict named arg strict=.true
    return self~UTF8(.WTF8_Encoding, strict: strict)


::method UTF16
    use strict arg targetEncoding=.UTF16BE_Encoding
    use strict named arg strict=.true
    if self~string~isASCII then do
        string = self~string
        sizeB = string~length -- size in bytes
        buffer = .MutableBuffer~new(, sizeB * 2) -- yes, always 2, no need to use codepointMaxBytes
        do i=1 to sizeB
            buffer~append("0"x)
            buffer~append(string~subchar(i))
        end
        return .RexxText~new(buffer~string, targetEncoding)
    end
    return self~convertToUnicode(targetEncoding, strict: strict)


::method WTF16
    use strict named arg strict=.true
    return self~UTF16(.WTF16_Encoding, strict: strict)


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
::class "UTF8_Encoding" subclass StringIndexer public

::method name class
    use strict arg -- none
    return "UTF-8"


::method isUnicode class
    use strict arg -- none
    return .true


::method isUTF8 class
    use strict arg -- none
    return .true


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
    return .Unicode~analyze(string, self, codepointIndexes, graphemeIndexes)


::method checkCodepoint class
    use strict arg codepoint, previousCodepoint=.nil
    use strict named arg checkOnlyRange=.false
    if codepoint < 0 | codepoint > 1114111 then signal error_range
    if checkOnlyRange then return .true
    if codepoint >= 55296 & codepoint < 56320 then signal error_high_surrogate -- U+D800 to U+DBFF high surrogates
    if codepoint >= 56320 & codepoint < 57344 then signal error_low_surrogate  -- U+DC00 to U+DFFF low surrogates
    return .true
    error_range:          raise syntax 93.900 array (self~name "encoding: invalid codepoint" codepoint "("ppHexNumber(codepoint)"). Allowed range is 0..1114111")
    error_high_surrogate: raise syntax 93.900 array (self~name "encoding: invalid codepoint" codepoint "("ppHexNumber(codepoint)"). High surrogate is not allowed")
    error_low_surrogate:  raise syntax 93.900 array (self~name "encoding: invalid codepoint" codepoint "("ppHexNumber(codepoint)"). Low surrogate is not allowed")


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return -1
    if sizeB == 1 then return decodeByte(0, "7F"x)
    if sizeB == 2 then return decodeByte(0, "1F"x)  *     64 + decodeByte(1, "3F"x)
    if sizeB == 3 then return decodeByte(0, "0F"x)  *   4096 + decodeByte(1, "3F"x) *   64 +  + decodeByte(2, "3F"x)
    if sizeB == 4 then return decodeByte(0, "07"x)  * 216144 + decodeByte(1, "3F"x) * 4096 +  + decodeByte(2, "3F"x) * 64 + decodeByte(3, "3F"x)
    raise syntax 93.900 array (self~name "encoding:" sizeB "is an invalid codepoint size")

    decodeByte: procedure expose string startB
        use strict arg offset, mask
        return string~subchar(startB + offset)~bitand(mask)~c2d


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    indexB = startB
    startByte = string~subchar(indexB)
    if startByte == "" then return indexB
    if startByte < "80"x then byteCount = 1                     -- 1-byte sequence 0xxxxxxx
    else if startByte~bitand("E0"x) == "C0"x then byteCount = 2 -- 2-byte sequence 110xxxxx
    else if startByte~bitand("F0"x) == "E0"x then byteCount = 3 -- 3-byte sequence 1110xxxx
    else if startByte~bitand("F8"x) == "F0"x then byteCount = 4 -- 4-byte sequence 11110xxx
    else signal invalid_start_byte
    indexB += 1
    do byteCount - 1
        continuationByte = string~subchar(indexB)
        if continuationByte == "" then signal truncated
        if continuationByte~bitand("C0"x) <> "80"x then signal invalid_continuation_byte -- Must be 10xxxxxx
        indexB += 1
    end
    return indexB

    invalid_start_byte:         raise syntax 93.900 array ("UTF-8 sequence at byte-position" startB "has an invalid start byte" startByte~c2d "("ppHexNumber(startByte~c2d)")")
    invalid_continuation_byte:  raise syntax 93.900 array ("UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB)
    truncated:                  raise syntax 93.900 array ("UTF-8 sequence at byte-position" startB "is truncated, expected" byteCount "bytes")
    surrogate:                  raise syntax 93.900 array ("UTF-8 sequence at byte-position" startB "is a surrogate codepoint")


::method skipInvalidByteSequence class
    -- The sequence starting at indexB is invalid.
    -- Go to the next start byte.
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
    use strict arg indexC
    if indexC < 1 | indexC > self~codepointCount then raise syntax 93.900 array (self~description "invalid codepoint index:" indexC)
    if self~codepointIndexes == .nil then return self~string~subchar(indexC)~c2d
    startB = self~codepointIndexes[indexC]
    nextB = self~codepointIndexes[indexC+1]
    if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
    nextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    return self~class~decode(self~string, startB, nextB-startB)


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeCount then raise syntax 93.900 array (self~description "invalid grapheme index:" indexG)
    if self~graphemeIndexes == .nil then return .RexxText~new(self~string~subchar(indexG), self~class)
    startB = self~graphemeIndexes[indexG]
    nextB = self~graphemeIndexes[indexG+1]
    startB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    nextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    return .RexxText~new(self~string~substr(startB, nextB-startB), self~class)


::method UTF8
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg targetEncoding=.UTF8_Encoding
    return .RexxText~new(.String~new(self~string), targetEncoding)


::method WTF8
    use strict arg -- none
    return self~UTF8(.WTF8_Encoding)


::method UTF16
    use strict arg targetEncoding=.UTF16BE_Encoding
    sizeC = self~codepointCount -- size in codepoints
    buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        targetEncoding~encode(codepoint, buffer)
    end
    return .RexxText~new(buffer~string, targetEncoding)


::method WTF16
    use strict arg -- none
    return self~UTF16(.WTF16_Encoding)


/******************************************************************************/
::class "WTF8_Encoding" subclass UTF8_Encoding public
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


::method isWTF8 class
    use strict arg -- none
    return .true


::method checkCodepoint class
    use strict arg codepoint, previousCodepoint=.nil
    use strict named arg checkOnlyRange=.false
    if codepoint < 0 | codepoint > 1114111 then signal error_range
    if checkOnlyRange then return .true
    if previousCodepoint <> .nil,,
       previousCodepoint >= 55296 & previousCodepoint < 56320,, -- U+D800 to U+DBFF high surrogates
       codepoint >= 56320 & codepoint < 57344,                  -- U+DC00 to U+DFFF low surrogates
    then signal error_high_low_surrogate
    return .true
    error_range:              raise syntax 93.900 array (self~name "encoding: invalid codepoint" codepoint "("ppHexNumber(codepoint)"). Allowed range is 0..1114111")
    error_high_low_surrogate: raise syntax 93.900 array (self~name "encoding: a high surrogate" previousCodepoint "("ppHexNumber(previousCodepoint)") followed by a low surrogate" codepoint "("ppHexNumber(codepoint)") is not allowed")


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
::class "UTF16BE_Encoding" subclass StringIndexer public

::method name class
    use strict arg -- none
    return "UTF-16BE"


::method isUnicode class
    use strict arg -- none
    return .true


::method isUTF16 class
    use strict arg -- none
    return .true


::method codepointMaxBytes class
    use strict arg -- none
    return 4  -- In UTF-16, a codepoint can be 2 or 4 bytes


::method analyze class
    use strict arg string
    size = 1 + string~length % 2 -- The final size will be <=
    codepointIndexes = .array~new(size) -- will be removed
    graphemeIndexes = .array~new(size)
    return .Unicode~analyze(string, self, codepointIndexes, graphemeIndexes)


::method checkCodepoint class
    use strict arg codepoint, previousCodepoint=.nil
    use strict named arg checkOnlyRange=.false -- no impact here
    if codepoint < 0 | codepoint > 1114111 then signal error_range
    return .true
    error_range: raise syntax 93.900 array (self~name "encoding: invalid codepoint" codepoint "("ppHexNumber(codepoint)"). Allowed range is 0..1114111")


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return -1
    if sizeB == 2 then return string~substr(startB, 2)~c2d
    if sizeB == 4 then do
        high_surrogate = string~substr(startB, 2)~c2d
        low_surrogate = string~substr(startB + 2, 2)~c2d
        h = (high_surrogate - 55296) * 1024 -- Take the high surrogate and subtract 0xD800, then multiply by 0x400
        l = low_surrogate - 56320 -- Take the low surrogate and subtract 0xDC00
        return h + l + 65536 -- Add these two results together, and finally add 0x10000
    end
    raise syntax 93.900 array (self~name "encoding:" sizeB "is an invalid codepoint size")


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    wobbly = self~isWTF16
    indexB = startB
    lengthB = string~length
    if indexB > lengthB then return indexB -- end of string
    if lengthB - indexB < 1 then signal truncated
    codeUnit = string~substr(indexB, 2)
    indexB += 2
    if codeUnit >= "D800"x & codeUnit <= "DBFF"x then do
        -- got high surrogate, get low surrogate
        if indexB > lengthB then do
            -- end of string, no low surrogate but it's acceptable to consider
            -- the high surrogate as a standalone codepoint, when wobbly mode
            if wobbly then return indexB
                      else signal unpaired_high_surrogate
        end
        if lengthB - indexB < 1 then signal truncated
        codeUnit = string~substr(indexB, 2)
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

    unpaired_high_surrogate: raise syntax 93.900 array (self~name "encoding: unpaired high surrogate" codeUnit~c2d "("ppHexNumber(codeUnit~c2d)") at byte-position" startB)
    unpaired_low_surrogate:  raise syntax 93.900 array (self~name "encoding: unpaired low surrogate" codeUnit~c2d "("ppHexNumber(codeUnit~c2d)") at byte-position" startB)
    invalid_low_surrogate:   raise syntax 93.900 array (self~name "encoding: invalid low surrogate" codeUnit~c2d "("ppHexNumber(codeUnit~c2d)") at byte-position" indexB)
    truncated:               raise syntax 93.900 array (self~name "encoding: character is truncated at byte-position" indexB", expected 2 bytes")


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
        buffer~append(codepoint~d2c(2))
    end
    else if codepoint < 65536 then do -- U+E000 to U+FFFF
        buffer~append(codepoint~d2c(2))
    end
    else if codepoint <= 1114111 then do -- U+010000 to U+10FFFF
        buffer~append((55296 + (codepoint - 65536) % 1024)~d2c(2))     -- high surrogate: Subtract 0x10000, shift right by 10 (divide by 0x400), then add 0xD800
        buffer~append((56320 + (codepoint - 65536) // 1024)~d2c(2))    -- low surrogate: Subtract 0x10000, take the low 10 bits (remainder of dividing by 0x400), then add 0xDC0
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


/********************/
/* Instance methods */
/********************/

::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC
    if indexC < 1 | indexC > self~codepointCount then raise syntax 93.900 array (self~description "invalid codepoint index:" indexC)
    startB = self~codepointIndexes[indexC]
    nextB = self~codepointIndexes[indexC+1]
    if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
    nextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    return self~class~decode(self~string, startB, nextB-startB)


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeCount then raise syntax 93.900 array (self~description "invalid grapheme index:" indexG)
    startB = self~graphemeIndexes[indexG]
    nextB = self~graphemeIndexes[indexG+1]
    startB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    nextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    return .RexxText~new(self~string~substr(startB, nextB-startB), self~class)


::method UTF8
    use strict arg targetEncoding=.UTF8_Encoding
    sizeC = self~codepointCount -- size in codepoints
    buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        targetEncoding~encode(codepoint, buffer)
    end
    return .RexxText~new(buffer~string, targetEncoding)


::method WTF8
    use strict arg -- none
    return self~UTF8(.WTF8_Encoding)


::method UTF16
    -- Always a new RexxText. The optimization "return self" is managed at RexxText level.
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    use strict arg targetEncoding=.UTF16BE_Encoding
    return .RexxText~new(.String~new(self~string), targetEncoding)


::method WTF16
    use strict arg -- none
    return self~UTF16(.WTF16_Encoding)


/******************************************************************************/
::class "WTF16BE_Encoding" subclass UTF16BE_Encoding public
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


::method isWTF16 class
    use strict arg -- none
    return .true


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
    use strict arg -- none
    if self~available then return indexer~codepoint(indexC)


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
    -- Helper to display an hexadecimal value. 0 --> 00x, 255 --> FFx, -1 --> -01x
    use strict arg number, size=(-1)
    if \datatype(number, "W") then return "??"
    sign = ""
    if sign(number) < 0 then sign = "-"
    number = abs(number)
    if size == -1 then do
        if number < 256 then size = 2
        else if number < 65536 then size = 4
        else size = 8
    end
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
