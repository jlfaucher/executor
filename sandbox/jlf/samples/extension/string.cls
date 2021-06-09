/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

-- Compatibility with ooRexx5
.string~define("append", .string~method("||"))

-- Copied from rgf_util2, needed for routine escape3
.local~rgf.non.printable=xrange("00"x,"1F"x)||"FF"x

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


::method "[]"
    -- ooRexx v5
    use strict arg n, length=1
    maxLength = self~length - n + 1 -- don't care about n<=0, will be caught by substr
    if maxLength <= 0 then return ""
    return self~substr(n, min(length, maxLength))


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
    return self~pos(substr, start) == start


::method caselessEndsWith
    -- ooRexx v5
    use strict arg substr
    start = self~length - substr~length + 1
    return self~caselessPos(substr, start) == start


::method concatenate
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
    use strict arg singularText, pluralText
    if abs(self) <= 1 then return self singularText
    return self pluralText


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
::class "MutableBufferPrettyPrinter" mixinclass Object public

::method ppString
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
    return self~text


::method copy
    -- If the string is linked to a RexxText then the RexxText must also be cloned.
    expose text
    if \var("text") then return self~copy:super
    textCopy = text~copy
    return textCopy~string


/******************************************************************************/
::class "RexxTextInitializer" mixinclass Object public

::method init
    expose indexer -- The RexxText is not referencing directly the String, it's the indexer
    use strict arg string, encoding="default"
    if \string~isA(.String) then raise syntax 93.900 array("Text:" string "is not a String")
    encoding = .Encoding~factory(encoding)
    indexer = encoding~analyze(string)
    -- if we reach this point, it means the analyze is ok, otherwise an error was raised.
    string~text = self -- store itself as counterpart of string


/*
Don't activate this one.
I need to get the control when concatenating strings
[later]
In fact, this method is NEVER called, even if activated.
It's because RexxText is a base class, so primitiveMakeString is called by the interpreter.

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

    -- Texts are prefixed with "T"
    pp = "T'"self~string"'"
    -- Use 0xXX notation for escaped character
    return escape3(pp)


/******************************************************************************/
::class "RexxTextContents" mixinclass Object public

-- Remember: don't use expose indexer, because it's not visible. Must use self~indexer.

::method description
    forward to (self~indexer)


::method isByte
    forward to (self~indexer~class)


::method isUnicode
    forward to (self~indexer~class)


::method isUTF8
    forward to (self~indexer~class)


::method isUTF16
    forward to (self~indexer~class)


::method codepoints
    forward to (self~indexer)


/*
-- No direct access to codepoint, not needed.
::method codepoint
    forward to (self~indexer)
*/


::method length -- number of graphemes
    return self~indexer~graphemeIndexesSize


::method graphemes
    forward to (self~indexer)


::method grapheme
    forward to (self~indexer)


-- UTF-8 representation (always new String and new RexxText)
::method utf8
    forward to (self~indexer)


-- UTF-16BE representation (always new String and new RexxText)
::method utf16
    forward to (self~indexer)


::method c2x
    return self~string~c2x


::method isASCII
    return (self~isByte | self~isUTF8) & self~string~isASCII


::method checkNumericValueCompatibility
    -- The purpose is not to check that the text is a numeric value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    if \self~isASCII then raise syntax 93.900 array("The" self~description(short:.true) "text is not compatible with a Rexx numeric value")


::method checkLogicalValueCompatibility
    -- The purpose is not to check that the text is a logical value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
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
::extension "Unicode" -- abstract

::method initialize class
    expose characters
    characters = .directory~new
    self~declareCharacter("0301"~x2d, "combining acute accent")
    self~declareCharacter(  "20"~x2d, "space")


::method declareCharacter class
    expose characters
    use strict arg codepoint, name
    character = .UnicodeCharacter~new(codepoint, name)
    characters~setEntry(name, character)


::method character class
    expose characters
    use strict arg name
    return characters~entry(name)


::method analyze class
    use strict arg string, indexer, codepointIndexes, graphemeIndexes
    indexB = 1
    previousCodepoint = .nil
    graphemeBreakArgs = (-1, -1, 0) -- codepoint1, codepoint2, state. Will use the same array at each iteration.
    do forever
        nextB = indexer~nextCodepointIndex(string, indexB)
        codepointIndexes~append(indexB) -- will be removed
        codepoint = indexer~decode(string, indexB, nextB - indexB) -- can be -1 if nextB == indexB
        if previousCodepoint == .nil then do
            -- First codepoint
            graphemeIndexes~append(indexB)
            previousCodepoint = codepoint
        end
        else if codepoint == -1 then do
            -- End of string
            graphemeIndexes~append(indexB)
        end
        else do
            graphemeBreakArgs[1] = previousCodepoint
            graphemeBreakArgs[2] = codepoint
            if self~GraphemeBreak(graphemeBreakArgs) then do
                graphemeIndexes~append(indexB)
            end
            previousCodepoint = codepoint
        end
        if nextB == indexB then leave
        indexB = nextB
    end
    -- Return compacted arrays (their size can be lesser than string's length)
    codepointIndexes = codepointIndexes~makeArray -- will be removed
    graphemeIndexes = graphemeIndexes~makeArray
    if graphemeIndexes~size-1 == string~length then do
        -- Optimization: no need of indexes, direct access is possible
        return indexer~new(string, .nil, string~length, .nil, string~length)
    end
    else do
        return indexer~new(string, codepointIndexes, codepointIndexes~size-1, graphemeIndexes, graphemeIndexes~size-1)
    end


/******************************************************************************/
::class "UnicodeCharacter" public

::attribute codepoint get
::attribute name get

::method init
    expose codepoint name
    use strict arg codepoint, name

::method utf8
    expose codepoint
    return .UTF8_Encoding~encode(codepoint)

::method utf16
    expose codepoint
    return .UTF16BE_Encoding~encode(codepoint)


/******************************************************************************/
::class "Encoding" public -- abstract

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
    encodings = .directory~new
    encodings["DEFAULT"] = "DEFAULT" -- calculated
    encodings["BYTES"] = .Byte_Encoding
    encodings["CP1252"] = .CP1252_Encoding
    encodings["WINDOWS1252"] = .CP1252_Encoding
    -- encodings["ISO88591"] = .ISO88591_Encoding
    -- encodings["LATIN1"] = .ISO88591_Encoding
    -- encodings["ISO885915"] = .ISO885915_Encoding
    -- encodings["LATIN9"] = .ISO885915_Encoding
    encodings["UTF8"] = .UTF8_Encoding
    encodings["UTF16BE"] = .UTF16BE_Encoding
    -- encodings["UTF16LE"] = .UTF16LE_Encoding
    encodings["UTF16"] = .UTF16BE_Encoding -- The Unicode norm specifies that the default UTF-16 is big endian


::method supported class
    expose encodings
    return encodings~supplier


::method factory class
    expose encodings
    use strict arg encoding
    if encoding~isA(.Class), encoding~isSubClassOf(.StringIndexer) then return encoding
    -- Remove all dash, underscore and spaces: "UTF8", "UTF_8", "UTF-8", "UTF 8" are all a valid encoding name
    encoding = encoding~translate(, "_- "," ")~space(0)~upper
    if encoding == "DEFAULT" then return .Encoding~defaultEncoding
    if encodings~hasEntry(encoding) then return encodings[encoding]
    raise syntax 93.900 array("Encoding: '"encoding"' is not supported")


::method forConcatenation class
    use strict arg left, right
    leftEncoding = left~encoding
    rightEncoding = right~encoding
    if leftEncoding == rightEncoding then return leftEncoding
    if left~isASCII & right~isUTF8 then return .UTF8_Encoding
    if left~isUTF8 & right~isASCII then return .UTF8_Encoding
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
    return .false


::method isUnicode class
    return .false


::method isUTF8 class
    return .false


::method isUTF16 class
    return .false


::method analyze class abstract


::method decode class abstract


::method nextCodepointIndex class


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
        buffer~append(arg(i)~string)
    end
    return .RexxText~new(buffer~string, self)


::method SpaceCharacter class
    expose spaceCharacter
    if \var("spaceCharacter") then spaceCharacter = self~encode(.Unicode~character("space")~codepoint)
    return spaceCharacter


/********************/
/* Instance methods */
/********************/

::attribute string get
::attribute string set private
::attribute codepointIndexes get private -- will be removed, no need of direct access to a codepoint
::attribute codepointIndexesSize get
::attribute graphemeIndexes get private
::attribute graphemeIndexesSize get


::method init
    expose string codepointIndexes codepointIndexesSize  graphemeIndexes graphemeIndexesSize
    use strict arg string, codepointIndexes, codepointIndexesSize, graphemeIndexes, graphemeIndexesSize


::method copy
    -- No need to re-analyze the string, it's immutable:
    -- all the indexes are still applicable, just change the string referenced by the indexer.
    clone = self~copy:super
    clone~string = .string~new(clone~string) -- don't use ~copy (stack overflow)
    return clone


::method description
    use strict named arg short=.false
    if self~string~isASCII then asciiness = "ASCII"
                           else asciiness = "not-ASCII"
    sizesDescription = ""
    if \short then sizesDescription = "(",
                                      self~graphemes~size~singularPlural("grapheme", "graphemes")",",
                                      self~codepoints~size~singularPlural("codepoint", "codepoints")",",
                                      self~string~length~singularPlural("byte", "bytes"),
                                      ")"
    return " "~concatenate(self~class~name, asciiness, sizesDescription)


::method codepoints
    return .CodePointSupplier~new(self)


::method codepoint abstract


::method graphemes
    return .GraphemeSupplier~new(self)


::method grapheme abstract


::method utf8 abstract


::method utf16 abstract


/******************************************************************************/
::class "Byte_Encoding" subclass StringIndexer public

::method name class
    return "Byte"


::method isByte class
    return .true


::method analyze class
    use strict arg string
    sizeB = string~length -- size in bytes
    -- Bytes, codepoints and graphemes are identical
    -- The string holds all the needed informations, no need to calculate indexes
    return self~new(string, .nil, sizeB, .nil, sizeB)


::method decode class
    use strict arg string, startB=1, sizeB=1 -- here, the size of a codepoint is always 1
    if sizeB == 0 then return -1
    if sizeB == 1 then return string~subchar(startB)~c2d
    raise syntax 93.900 array ("Invalid encoded codepoint size")


::method nextCodepointIndex class
    use strict arg string, indexB
    c = string~subchar(indexB)
    if c == "" then return indexB
    return indexB + 1


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint, buffer=.nil
    if codepoint < 0 | codepoint > 255 then raise syntax 93.900 array ("Invalid codepoint")
    if buffer <> .nil then return buffer~~append(codepoint~d2c)
                      else return .RexxText~new(codepoint~d2c, self)


::method mappingToUnicode class
    return .nil


/********************/
/* Instance methods */
/********************/

::method codepoint
    use strict arg indexC
    if indexC < 1 | indexC > self~codepointIndexesSize then raise syntax 93.900 array ("Invalid codepoint index:" indexC)
    return self~string~subchar(indexC)~c2d


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeIndexesSize then raise syntax 93.900 array ("Invalid grapheme index:" indexG)
    return .RexxText~new(self~string~subchar(indexG), self~class)


::method utf8
    -- yes, always a new string. The original string is still associated to the Byte_Encoding.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if self~string~isASCII then return .RexxText~new(.String~new(self~string), .UTF8_Encoding)
    if self~class~mappingToUnicode <> .nil then do
        sizeC = self~codepointIndexesSize -- size in codepoints
        buffer = .MutableBuffer~new(, 4 * sizeC) -- In UTF-8, a codepoint can be from 1 to 4 bytes
        utf8 = .UTF8_Encoding
        do i=1 to sizeC
            charcode = self~codepoint(i)
            codepoint = self~class~mappingToUnicode(charcode)
            if codepoint == -1 then raise syntax 93.900 array("Encoding: cannot convert" self~description(short:.true) "character" charcode~d2x "to UTF-8")
            utf8~encode(codepoint, buffer)
        end
        return .RexxText~new(buffer~string, utf8)
    end
    raise syntax 93.900 array("Encoding: cannot convert" self~description(short:.true) "to UTF-8")


::method utf16
    if self~string~isASCII then do
        string = self~string
        sizeB = string~length -- size in bytes
        buffer = .MutableBuffer~new(, 2 * sizeB)
        do i=1 to sizeB
            buffer~append("0"x)
            buffer~append(string~subchar(i))
        end
        return .RexxText~new(buffer~string, .UTF16BE_Encoding)
    end
    if self~class~mappingToUnicode <> .nil then do
        sizeC = self~codepointIndexesSize -- size in codepoints
        buffer = .MutableBuffer~new(, 4 * sizeC) -- In UTF-16, a codepoint can be 2 or 4 bytes
        utf16 = .UTF16BE_Encoding
        do i=1 to sizeC
            charcode = self~codepoint(i)
            codepoint = self~class~mappingToUnicode(charcode)
            if codepoint == -1 then raise syntax 93.900 array("Encoding: cannot convert" self~description(short:.true) "character" charcode~d2x "to UTF-8")
            utf16~encode(codepoint, buffer)
        end
        return .RexxText~new(buffer~string, utf16)
    end
    raise syntax 93.900 array("Encoding: cannot convert" self~description(short:.true) "to UTF-16")


/******************************************************************************/
::class "CP1252_Encoding" subclass Byte_Encoding public
-- alias Window-1252

::method name class
    return "CP1252"


::method mappingToUnicode class
    expose mappingToUnicode
    use strict arg charcode=(-1)
    if \var("mappingToUnicode") then mappingToUnicode = CP1252_to_Unicode()
    if charcode == -1 then return mappingToUnicode
                      else return mappingToUnicode[charcode+1] -- bof bof... 1-based array


::routine CP1252_to_Unicode
    -- https://en.wikipedia.org/wiki/Windows-1252#Code_page_layout
    specific =,
        128, "20AC",,
        129, -1,,        -- invalid
        130, "201A",,
        131, "0192",,
        132, "201E",,
        133, "2026",,
        134, "2020",,
        135, "2021",,
        136, "02C6",,
        137, "2030",,
        138, "0160",,
        139, "2039",,
        140, "0152",,
        141, -1,,        -- invalid
        142, "017D",,
        143, -1,,        -- invalid
        144, -1,,        -- invalid
        145, "2018",,
        146, "2019",,
        147, "201C",,
        148, "201D",,
        149, "2022",,
        150, "2013",,
        151, "2014",,
        152, "02DC",,
        153, "2122",,
        154, "0161",,
        155, "203A",,
        156, "0153",,
        157, -1,,        -- invalid
        158, "017E",,
        159, "0178"
    mapping = .array~new(255)
    do i = 0 to 255
        mapping[i+1] = i -- bof bof... 1-based
    end
    do i=1 to specific~items by 2
        charcode = specific[i]
        codepoint = specific[i+1]
        if codepoint <> -1 then codepoint = codepoint~x2d
        mapping[charcode+1] = codepoint -- bof bof... 1-based array
    end
    return mapping


/******************************************************************************/
::class "UTF8_Encoding" subclass StringIndexer public

::method name class
    return "UTF-8"


::method isUnicode class
    return .true


::method isUTF8 class
    return .true


::method analyze class
    use strict arg string
    sizeB = string~length -- size in bytes
    -- Bad idea! Must always analyze because CR+LF is a grapheme.
    -- if string~isASCII then return self~new(string, .nil, sizeB, .nil, sizeB) -- no indexation needed
    codepointIndexes = .array~new(sizeB) -- will be removed
    graphemeIndexes = .array~new(sizeB)
    return .Unicode~analyze(string, self, codepointIndexes, graphemeIndexes)


::method decode class
    use strict arg string, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return -1
    if sizeB == 1 then return bitand_c2d(string, startB, "7F"x)
    if sizeB == 2 then return bitand_c2d(string, startB, "1F"x)  *     64 + bitand_c2d(string, startB+1, "3F"x)
    if sizeB == 3 then return bitand_c2d(string, startB, "0F"x)  *   4096 + bitand_c2d(string, startB+1, "3F"x) *   64 +  + bitand_c2d(string, startB+2, "3F"x)
    if sizeB == 4 then return bitand_c2d(string, startB, "07"x)  * 216144 + bitand_c2d(string, startB+1, "3F"x) * 4096 +  + bitand_c2d(string, startB+2, "3F"x) * 64 + bitand_c2d(string, startB+3, "3F"x)
    raise syntax 93.900 array ("Invalid encoded codepoint size")


::method nextCodepointIndex class
    use strict arg string, indexB
    c = string~subchar(indexB)
    if c == "" then return indexB
    indexB += 1
    if c < "80"x then return indexB             -- 1-byte sequence 0xxxxxxx
    if c~bitand("E0"x) == "C0"x then b = 2      -- 2-byte sequence 110xxxxx
    else if c~bitand("F0"x) == "E0"x then b = 3 -- 3-byte sequence 1110xxxx
    else if c~bitand("F8"x) == "F0"x then b = 4 -- 4-byte sequence 11110xxx
    else signal error
    do b-1
        c = string~subchar(indexB)
        if c == "" then signal error
        if c~bitand("C0"x) <> "80"x then signal error -- Must be 10xxxxxx
        indexB += 1
    end
    return indexB
    error:
    raise syntax 93.900 array ("Invalid UTF-8")


-- utf8proc_ssize_t utf8proc_encode_char(utf8proc_int32_t codepoint, utf8proc_uint8_t *dst);
::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint, buffer=.nil
    returnBuffer = buffer <> .nil
    if buffer == .nil then buffer = .MutableBuffer~new(, 4)
    if codepoint < 0 then do                                        -- if (uc < 0x00) {
        signal error                                                -- return 0;
    end
    else if codepoint < 128 then do                                 -- } else if (uc < 0x80) {
        buffer~append(codepoint~d2c)                                -- dst[0] = (utf8proc_uint8_t) uc;
    end                                                             -- return 1;
    else if codepoint < 2048 then do                                -- } else if (uc < 0x800) {
        buffer~append((192 + codepoint % 64)~d2c)                   -- dst[0] = (utf8proc_uint8_t)(0xC0 + (uc >> 6))
        buffer~append((128 + codepoint // 64)~d2c)                  -- dst[1] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    end                                                             -- return 2;
    -- Note: we allow encoding 0xd800-0xdfff here,
    -- however, these are actually invalid in UTF-8.
    else if codepoint < 65536 then do
        buffer~append((224 + codepoint % 4096)~d2c)                 -- dst[0] = (utf8proc_uint8_t)(0xE0 + (uc >> 12));
        buffer~append((128 + (codepoint % 64) // 64)~d2c)           -- dst[1] = (utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
        buffer~append((128 + codepoint // 64)~d2c)                  -- dst[2] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    end                                                             -- return 3;
    else if codepoint < 1114112 then do                             -- } else if (uc < 0x110000) {
        buffer~append((240 + codepoint % 262144)~d2c)               -- dst[0] = (utf8proc_uint8_t)(0xF0 + (uc >> 18));
        buffer~append((128 + (codepoint % 4096) // 64)~d2c)         -- dst[1] = (utf8proc_uint8_t)(0x80 + ((uc >> 12) & 0x3F));
        buffer~append((128 + (codepoint % 64) // 64)~d2c)           -- dst[2] = (utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
        buffer~append((128 + codepoint // 64)~d2c)                  -- dst[3] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    end                                                             -- return 4;
    else signal error                                               -- } else return 0;
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)
    error:
    raise syntax 93.900 array ("Invalid codepoint")


/********************/
/* Instance methods */
/********************/

::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC
    if indexC < 1 | indexC > self~codepointIndexesSize then raise syntax 93.900 array ("Invalid codepoint index:" indexC)
    if self~codepointIndexes == .nil then return self~string~subchar(indexC)~c2d
    startB = self~codepointIndexes[indexC]
    nextB = self~codepointIndexes[indexC+1]
    return self~class~decode(self~string, startB, nextB-startB)


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeIndexesSize then raise syntax 93.900 array ("Invalid grapheme index:" indexG)
    if self~graphemeIndexes == .nil then return .RexxText~new(self~string~subchar(indexG), self~class)
    startB = self~graphemeIndexes[indexG]
    nextB = self~graphemeIndexes[indexG+1]
    return .RexxText~new(self~string~substr(startB, nextB-startB), self~class)


::method utf8
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    return .RexxText~new(.String~new(self~string), self~class)


::method utf16
    sizeC = self~codepointIndexesSize -- size in codepoints
    buffer = .MutableBuffer~new(, 4 * sizeC) -- In UTF-16, a codepoint can be 2 or 4 bytes
    utf16 = .UTF16BE_Encoding
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        utf16~encode(codepoint, buffer)
    end
    return .RexxText~new(buffer~string, utf16)


/******************************************************************************/
::class "UTF16BE_Encoding" subclass StringIndexer public

::method name class
    return "UTF-16BE"


::method isUnicode class
    return .true


::method isUTF16 class
    return .true


::method analyze class
    use strict arg string
    size = 1 + string~length % 2 -- The final size will be <=
    codepointIndexes = .array~new(size) -- will be removed
    graphemeIndexes = .array~new(size)
    return .Unicode~analyze(string, self, codepointIndexes, graphemeIndexes)


::method decode class
    use strict arg string, startB, sizeB=(-1)
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
    raise syntax 93.900 array ("Invalid encoded codepoint size")


::method nextCodepointIndex class
    use strict arg string, indexB
    lengthB = string~length
    if indexB > lengthB then return indexB
    if lengthB - indexB < 1 then signal error
    c = string~substr(indexB, 2)
    indexB += 2
    if c >= "D800"x & c <= "DBFF"x then do
        -- got high surrogate, get low surrogate
        if lengthB - indexB < 1 then signal error
        c = string~substr(indexB, 2)
        if \(c >= "DC00"x & c <= "DFFF"x) then signal error
        indexB += 2
    end
    return indexB
    error:
    raise syntax 93.900 array ("Invalid UTF-16BE")


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint, buffer=.nil
    returnBuffer = buffer <> .nil
    if buffer == .nil then buffer = .MutableBuffer~new(, 4)
    if codepoint < 0 then do
        signal error
    end
    else if codepoint < 55296 then do -- U+0000 to U+D7FF
        buffer~append(codepoint~d2c(2))
    end
    else if codepoint < 57344 then do -- U+D800 to U+DFFF high and low surrogates
        signal error
    end
    else if codepoint < 65536 then do -- U+E000 to U+FFFF
        buffer~append(codepoint~d2c(2))
    end
    else if codepoint < 1114112 then do -- U+010000 to U+10FFFF
        buffer~append((55296 + (codepoint - 65536) % 1024)~d2c(2))     -- high surrogate: Subtract 0x10000, shift right by 10 (divide by 0x400), then add 0xD800
        buffer~append((56320 + (codepoint - 65536) // 1024)~d2c(2))    -- low surrogate: Subtract 0x10000, take the low 10 bits (remainder of dividing by 0x400), then add 0xDC0
    end
    else signal error
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)
    error:
    raise syntax 93.900 array ("Invalid codepoint")


/********************/
/* Instance methods */
/********************/

::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC
    if indexC < 1 | indexC > self~codepointIndexesSize then raise syntax 93.900 array ("Invalid codepoint index:" indexC)
    startB = self~codepointIndexes[indexC]
    nextB = self~codepointIndexes[indexC+1]
    return self~class~decode(self~string, startB, nextB-startB)


::method grapheme
    use strict arg indexG
    if indexG < 1 | indexG > self~graphemeIndexesSize then raise syntax 93.900 array ("Invalid grapheme index:" indexG)
    startB = self~graphemeIndexes[indexG]
    nextB = self~graphemeIndexes[indexG+1]
    return .RexxText~new(self~string~substr(startB, nextB-startB), self~class)


::method utf8
    sizeC = self~codepointIndexesSize -- size in codepoints
    buffer = .MutableBuffer~new(, 4 * sizeC) -- In UTF-8, a codepoint can be from 1 to 4 bytes
    utf8 = .UTF8_Encoding
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        utf8~encode(codepoint, buffer)
    end
    return .RexxText~new(buffer~string, utf8)


::method utf16
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    return .RexxText~new(.String~new(self~string), self~class)


/******************************************************************************/
::class "CodePointSupplier" public subclass Supplier

::method init
    expose indexer indexC
    use strict arg indexer
    empty = .array~new(0) -- No need to create a copy, the string is immutable
    self~init:super(empty, empty)
    indexC = 1
    -- will add a byte index


::method size
    expose indexer
    return indexer~codepointIndexesSize


::method available
    expose indexer indexC
    return indexC <= indexer~codepointIndexesSize


::method index
    expose indexC
    if self~available then return indexC


::method item
    expose indexer indexC
    if self~available then return indexer~codepoint(indexC)


::method next
    expose indexC
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


::method size
    expose indexer
    return indexer~graphemeIndexesSize


::method available
    expose indexer indexG
    return indexG <= indexer~graphemeIndexesSize


::method index
    expose indexG
    if self~available then return indexG


::method item
    expose indexer indexG
    if self~available then return indexer~grapheme(indexG)


::method next
    expose indexG
    indexG += 1


/******************************************************************************/
::routine bitand_c2d private
    use strict arg string, index, mask
    return string~subchar(index)~bitand(mask)~c2d


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
