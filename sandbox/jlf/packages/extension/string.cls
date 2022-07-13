/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

-- Compatibility with ooRexx5
.string~define("append", .string~method("||"))

-- Compatibility with ooRexx5
.MutableBuffer~define("appendLegacy", .MutableBuffer~method("append"))
.MutableBuffer~define("append", "do i=1 to arg(); self~appendLegacy(arg(i)); end")

.Unicode~initialize


::extension String                          inherit StringPrettyPrinter
::extension String                          inherit StringCompatibilityWithOORexx5
::extension String                          inherit StringHelpers
::extension String                          inherit EncodedString

::extension RexxText                        inherit RexxTextInitializer
::extension RexxText                        inherit RexxTextPrettyPrinter
::extension RexxText                        inherit RexxTextContents
::extension RexxText                        inherit RexxTextOperators
::extension RexxText                        inherit RexxTextStringInterface

::extension MutableBuffer                   inherit MutableBufferPrettyPrinter
::extension MutableBuffer                   inherit MutableBufferCompatibilityWithOORexx5
::extension MutableBuffer                   inherit MutableBufferHelpers
::extension MutableBuffer                   inherit EncodedMutableBuffer

--::options trace i

::requires "extension/stringChunk.cls"
::requires "extension/stringChunkExtended.cls"


/******************************************************************************/
/*
TODOs

Unicode8 16 32 : should I create common methods in Unicode_Encoding?

Test if the cache optimization of the methods isXXX is useful
Testing 'if var("XXX")' has a cost.

Remove the index for codepoints (codepointIndexes).
There is no need of direct access to a codepoint.

Grapheme indexes : see if it's possible to replace .Array by a class being really a sparse array.
This class should be ultra specialized for the management of string indexes.
For example, could manage a flexible storage in function of the size of the index.
Maybe a multi-stage table ?
Interface:
    indexTable~new(stringSizeInBytes)
    indexTable~size
    indexTable~items
    indexTable~[integer]
    indexTable~[integer]=bytePosition
    indexTable~first     --  index of the first item in the table

*/
/******************************************************************************/
/*
WON'T DOs

Will not support arithmetic with digits encoded in UTF-16 or UTF-32
"41"~text~utf16~c2u=    -- 'U+0034 U+0031'
"41"~text~utf16 + 0=    -- error UTF-16BE '[00]4[00]1' is not compatible with a Rexx numeric value.

Will not support x2b, x2c, x2d with hexadecimal digits encoded in UTF-16 or UTF-32
"41"~text~utf16~x2b=    -- error UTF-16BE '[00]4[00]1' is not compatible with a Rexx hexadecimal value.

b2x, c2x, d2x will always return a String, not a RexxText.
So "41"~text~utf16~c2x will not return an UTF-16 representation of the hexadecimal digits.

*/
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
::class "EncodedString" mixinclass Object private

/*
    aString
     ▲  text --------⮸ aRexxText
     │                     indexer (anEncoding)
     │                          codepoints (sequential access)
     │                          graphemes  (direct access)
     +-----------------------⮷- string
*/


/*
::attribute myText get


::attribute text get
    expose myText -- attribute added on the String instance
    use strict arg encoding="default"
    myText = .RexxText~new(self, encoding) -- store the RexxText counterpart created from itself with specified encoding
    -- Remember! Adding an instance method on the string instance changes its behaviour object.
    -- Because of that, it's no longer considered as a primitive object.
    -- And the message "==" is sent to the String instance with NO argument (see RexxString::hash)
    -- An error is raised by RexxString::primitiveIsEqual because the argument 'other' is required.
    self~setMethod("text", self~instanceMethod("myText"), "Object")
    return myText


::attribute text set -- private
    -- Can't declare this method private, because it's used by RexxText
    -- But the assignment is secured:
    -- If not yet linked to a RexxText then only a RexxText linked to this string can be assigned
    -- If already linked to a RexxText then only this RexxText is accepted
    expose myText -- attribute added on the String instance
    use strict arg aText
    if \var("myText") then do -- no stored counterpart
        if aText~isA(.RexxText), aText~string~identityHash == self~identityHash then do
            myText = aText -- store the RexxText counterpart passed by argument
        end
        else raise syntax 23.900 array("EncodedString: the counterpart must be a RexxText linked to this String")
    end
    else do
        -- A RexxText counterpart is already assigned.
        -- Raise an error if different from the current one
        if aText~identityHash <> myText~identityHash then do
            -- Must test identityHash because operator "<>" overloaded to test the Unicode characters
            raise syntax 23.900 array("EncodedString: a RexxText counterpart is already assigned")
        end
    end
*/


::attribute text get
    expose myText -- attribute added on the String instance
    use strict arg encoding="default"
    if \var("myText") then do -- no stored counterpart
        myText = .RexxText~new(self, encoding) -- store the RexxText counterpart created from itself with specified encoding
    end
    else if arg(1, "e") then do
        -- If the encoding was explicitely specified then change the encoding
        encoding = .Encoding~factory(encoding, self)
        if myText~encoding <> encoding then myText~encoding = encoding
    end
    return myText


::attribute text set -- private
    -- Can't declare this method private, because it's used by RexxText
    -- But the assignment is secured:
    -- If not yet linked to a RexxText then only a RexxText linked to this string can be assigned
    -- If already linked to a RexxText then only this RexxText is accepted
    expose myText -- attribute added on the String instance
    use strict arg aText
    if \var("myText") then do -- no stored counterpart
        if aText~isA(.RexxText), aText~string~identityHash == self~identityHash then do
            myText = aText -- store the RexxText counterpart passed by argument
        end
        else raise syntax 23.900 array("EncodedString: the counterpart must be a RexxText linked to this String")
    end
    else do
        -- A RexxText counterpart is already assigned.
        -- Raise an error if different from the current one
        if aText~identityHash <> myText~identityHash then do
            -- Must test identityHash because operator "<>" overloaded to test the Unicode characters
            raise syntax 23.900 array("EncodedString: a RexxText counterpart is already assigned")
        end
    end


::method hasText
    expose myText
    return var("myText")


::method makeRexxText
    use strict arg -- none
    return self~text


::method copy
    -- If the string is linked to a RexxText then the RexxText must also be cloned.
    expose myText
    use strict arg -- none
    if \var("myText") then return self~copy:super
    textCopy = myText~copy
    return textCopy~string


/******************************************************************************/
::class "EncodedMutableBuffer" mixinclass Object private

/*
    Nothing sophisticated here...
    Just manage the attribute 'encoding', to know what is the current encoding of the MutableBuffer.
    By "current", I mean that this encoding may change during the life of the MutableBuffer,
    especially when doing concatenations. For example, an UTF-8 buffer will become a WTF-8 buffer
    when appending a WTF-8 string.
    There is no analysis of contents, no indexer.
    The analysis is done when a RexxText instance is created from the buffer's string.
*/

::attribute encoding get
    expose encoding
    if var("encoding") then return encoding
    encoding = .Encoding~defaultEncoding
    return encoding


::attribute encoding set
    expose encoding
    use strict arg newEncoding
    encoding = .Encoding~factory(newEncoding, self~string)


/******************************************************************************/
::class "RexxTextInitializer" mixinclass Object private

::method init
    -- The RexxText is not referencing directly the String, it's the indexer
    expose indexer /* rest is optim */ string text encoding
    use strict arg argString, argEncoding="default"
    .validate~classtype("1", argString, .string)
    -- Some strings are interned by the interpreter, and the same instance can be returned
    -- at different occasions.This is the case for the empty string (null string singleton
    -- OREF_NULLSTRING. If the string is already linked to a RexxText then a new instance
    -- must be created (don't make a copy, that would copy the link to the RexxText).
    if argString~hasText then argString = .String~new(argString)
    argEncoding = .Encoding~factory(argEncoding, argString)
    indexer = argEncoding~analyze(argString)

    -- Optimization by redundance (pure attributes are 3 to 4 times faster than methods just exposing and returning the value)
    string = indexer~string
    text = self
    encoding = indexer~class

    -- store itself as counterpart of string
    string~text = self



/*
Don't activate this one.
I need to get the control when concatenating strings
[later]
In fact, this method is NEVER called, even if activated.
It's because RexxText is a base class, so the C++ method primitiveMakeString is
called by the interpreter. This method returns .nil.
No message sent, so no way to return something.
[later]
For experimentation,
I added the C++ methods primitiveMakeString and makeString to RexxText which
always send the message request("string"), ignoring the fact that RexxText is a
base class...
*/
::method makestring
    expose indexer
    if self~isCompatibleWithString then return indexer~string
    raise syntax 23.900 array(self~descriptionForError "cannot be converted to a String instance")


::attribute string get
/*
::attribute string get
    expose indexer
    use strict arg -- none
    return indexer~string
*/


::attribute string set private


::attribute text get
/*
    use strict arg -- none
    return self
*/


::attribute text set private


::attribute encoding get
/*
    expose indexer
    use strict arg -- none
    return indexer~class
*/

::attribute encoding set
    expose indexer /* rest is optim */ string text encoding
    use strict arg newEncoding
    newEncoding = .Encoding~factory(newEncoding, indexer~string)
    if indexer~class <> newEncoding then do
        indexer = newEncoding~analyze(indexer~string)
        -- Optimization by redundance (pure attributes are 3 to 4 times faster than methods just exposing and returning the value)
        string = indexer~string
        text = self
        encoding = indexer~class
    end


-- Must use an attribute to return the indexer, because the indexer is not visible from the other mixinclasses
::attribute indexer private


::method copy
    use strict arg -- none
    selfCopy = self~copy:super -- for the moment, the copy has the same indexer as self
    indexerCopy = selfCopy~indexer~copy -- creates a copy of the indexer and also a copy of the indexed string
    selfCopy~indexer = indexerCopy -- from now, the copy has its own indexer, which has its own indexed string

    -- Optimization by redundance (pure attributes are 3 to 4 times faster than methods just exposing and returning the value)
    selfCopy~string = indexerCopy~string
    selfCopy~text = selfCopy
    selfCopy~encoding = indexerCopy~class

    stringCopy = indexerCopy~string -- this string copy is not yet linked to the RexxText copy
    stringCopy~text = selfCopy -- from now, the string copy is linked to its RexxText counterpart
    return selfCopy


/******************************************************************************/
::class "RexxTextPrettyPrinter" mixinclass Object private

::method ppString
    -- Should honor surroundByQuotes
    -- Should return a RexxText, but then how to display it ?

    use arg surroundByQuotes=.true -- keep it for the moment, still needed from rgf_util2
    -- Texts are prefixed with "T"
    pp = "T'"self~string"'"
    -- Use 0xXX notation for escaped character
    return escape3(pp)


/******************************************************************************/
::class "RexxTextContents" mixinclass Object private

-- Remember: don't use expose indexer, because it's not visible. Must use self~indexer.

::method description
    forward to (self~indexer)


::method descriptionForError
    forward to (self~indexer)


::method errors
    forward to (self~indexer)


::method isByte
    expose isByte
    if var("isByte") then return isByte
    forward to (self~indexer~class) continue
    isByte = result
    return result


::method isUnicode
    expose isUnicode
    if var("isUnicode") then return isUnicode
    forward to (self~indexer~class) continue
    isUnicode = result
    return result


::method isUTF8
    expose isUTF8
    if var("isUTF8") then return isUTF8
    forward to (self~indexer~class) continue
    isUTF8 = result
    return result


::method isWTF8
    expose isWTF8
    if var("isWTF8") then return isWTF8
    forward to (self~indexer~class) continue
    isWTF8 = result
    return result


::method isUTF16 -- true if UTF-16BE or UTF-16LE
    expose isUTF16
    if var("isUTF16") then return isUTF16
    forward to (self~indexer~class) continue
    isUTF16 = result
    return result


::method isUTF16BE
    expose isUTF16BE
    if var("isUTF16BE") then return isUTF16BE
    forward to (self~indexer~class) continue
    isUTF16BE = result
    return result


::method isUTF16LE
    expose isUTF16LE
    if var("isUTF16LE") then return isUTF16LE
    forward to (self~indexer~class) continue
    isUTF16LE = result
    return result


::method isWTF16 -- true is WTF-16BE or WTF-16LE
    expose isWTF16
    if var("isWTF16") then return isWTF16
    forward to (self~indexer~class) continue
    isWTF16 = result
    return result


::method isWTF16BE
    expose isWTF16BE
    if var("isWTF16BE") then return isWTF16BE
    forward to (self~indexer~class) continue
    isWTF16BE = result
    return result


::method isWTF16LE
    expose isWTF16LE
    if var("isWTF16LE") then return isWTF16LE
    forward to (self~indexer~class) continue
    isWTF16LE = result
    return result


::method isUTF32
    expose isUTF32
    if var("isUTF32") then return isUTF32
    forward to (self~indexer~class) continue
    isUTF32 = result
    return result


::method isUTF32BE
    expose isUTF32BE
    if var("isUTF32BE") then return isUTF32BE
    forward to (self~indexer~class) continue
    isUTF32BE = result
    return result


::method isUTF32LE
    expose isUTF32LE
    if var("isUTF32LE") then return isUTF32LE
    forward to (self~indexer~class) continue
    isUTF32LE = result
    return result


-- The corresponding encoding name is "Unicode" but I can't name this method "isUnicode"
-- because collision with isUnicode already defined, which returns .true for a RexxText with Unicode encoding.
-- I could rename the other method "isUnicodeEncoding" but I prefer to stay like that.
::method isUnicodeN
    expose isUnicodeN
    if var("isUnicodeN") then return isUnicodeN
    forward to (self~indexer~class) continue
    isUnicodeN = result
    return result


::method isUnicode8
    expose isUnicode8
    if var("isUnicode8") then return isUnicode8
    forward to (self~indexer~class) continue
    isUnicode8 = result
    return result


::method isUnicode16
    expose isUnicode16
    if var("isUnicode16") then return isUnicode16
    forward to (self~indexer~class) continue
    isUnicode16 = result
    return result


::method isUnicode32
    expose isUnicode32
    if var("isUnicode32") then return isUnicode32
    forward to (self~indexer~class) continue
    isUnicode32 = result
    return result


::method isASCII
    expose isASCII
    if var("isASCII") then return isASCII
    isASCII = (self~isByte | self~isUTF8 | self~isWTF8) & self~string~isASCII
    return isASCII


::method isUpper
    expose isUpper
    if var("isUpper") then return isUpper
    forward to (self~indexer) continue
    isUpper = result
    return result


::method isLower
    expose isLower
    if var("isLower") then return isLower
    forward to (self~indexer) continue
    isLower = result
    return result


::method isCompatibleWithString
    expose isCompatibleWithString
    -- true if the String methods are applicable
    if var("isCompatibleWithString") then return isCompatibleWithString
    if self~isByte then result = .true
    else result = (self~isUTF8 | self~isWTF8) & self~string~isASCII
    isCompatibleWithString = result
    return result


::method codepoints
    forward to (self~indexer)


::method maximumCodepoint
    forward to (self~indexer)

/*
-- No direct access to codepoint, not needed.
::method codepoint
    forward to (self~indexer)
*/


::method characters
    forward to (self~indexer)


::method graphemes
    forward to (self~indexer)


::method grapheme
    forward to (self~indexer)


-- UTF-8 representation
::method UTF8
    forward to (self~indexer)


-- WTF-8 representation
::method WTF8
    forward to (self~indexer)


-- UTF-16BE or UTF-16LE representation
::method UTF16
    forward to (self~indexer)


-- UTF-16BE representation
::method UTF16BE
    forward to (self~indexer)


-- UTF-16LE representation
::method UTF16LE
    forward to (self~indexer)


-- WTF-16BE or WTF-16LE representation
::method WTF16
    forward to (self~indexer)


-- WTF-16BE representation
::method WTF16BE
    forward to (self~indexer)


-- WTF-16LE representation
::method WTF16LE
    forward to (self~indexer)


-- UTF-32BE or UTF-32LE representation
::method UTF32
    forward to (self~indexer)


-- UTF-32BE representation
::method UTF32BE
    forward to (self~indexer)


-- UTF-32LE representation
::method UTF32LE
    forward to (self~indexer)


-- Unicode representation (Unicode8, Unicode16 or Unicode32)
::method Unicode
    forward to (self~indexer)


-- Unicode representation limited to codepoints < 256
::method Unicode8
    forward to (self~indexer)


-- Unicode representation limited to codepoints < 65536
::method Unicode16
    forward to (self~indexer)


-- Unicode representation limited to codepoints <= .Unicode~maxCodepoint
::method Unicode32
    forward to (self~indexer)


::method c2u
    forward to (self~indexer)


::method c2g
    forward to (self~indexer)


::method checkHexadecimalValueCompatibility
    -- The purpose is not to check that the text is an hexadecimal value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    -- Could test ~isCompatibleWithString, but ~isASCII is faster and sufficient here
    use strict arg -- none
    if \self~isASCII then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx hexadecimal value")


::method checkNumericValueCompatibility
    -- The purpose is not to check that the text is a numeric value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    -- Could test ~isCompatibleWithString, but ~isASCII is faster and sufficient here
    use strict arg -- none
    if \self~isASCII then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx numeric value")


::method checkLogicalValueCompatibility
    -- The purpose is not to check that the text is a logical value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    -- Could test ~isCompatibleWithString, but ~isASCII is faster and sufficient here
    use strict arg -- none
    if \self~isASCII then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx logical value")


::method unescape
    forward to (self~indexer)


/******************************************************************************/
::class "RexxTextStringInterface" mixinclass Object private

/*
Class methods
=============
alnum                           (new 5)
alpha                           (new 5)
blank                           (new 5)
cntrl                           (new 5)
cr                              (new 5)
digit                           (new 5)
graph                           (new 5)
lower                           (new 5)
nl                              (new 5)
null                            (new 5)
print                           (new 5)
punct                           (new 5)
space                           (new 5)
tab                             (new 5)
upper                           (new 5)
xdigit                          (new 5)

Instance methods
================
[]                              (new 5) full
?                               (new 5) full
abbrev
abs
append                          (new 5) full
b2x
bitAnd
bitOr
bitXor
c2d                             full
c2x                             full
caselessAbbrev
caselessChangeStr
caselessCompare
caselessCompareTo               temporary wrong fallback
caselessContains                (new 5)
caselessContainsWord            (new 5)
caselessCountStr
caselessEndsWith                (new 5)
caselessEquals
caselessLastPos
caselessMatch
caselessMatchChar
caselessPos
caselessStartsWith              (new 5)
caselessWordPos
center
centre
changeStr
contains                        (new 5) partial
containsWord                    (new 5)
compare
compareTo
copies                          full
countStr
d2c
d2x
dataType
decodeBase64
delStr
delWord
encodeBase64
endsWith                        (new 5)
equals
format
hashCode                        full
insert
join                            (extension) full
lastPos
left                            full
length                          full
lower                           full except cases in SpecialCasing.txt
makeArray
makeString                      full (raise an error if not compatible with String)
match                           partial
matchChar                       partial
max
min
modulo                          (new 5)
overlay
pos                             partial
replaceAt
reverse                         full
right                           full
round
sign
space
startsWith                      (new 5)
strip
subChar                         full
substr
subWord
subWords
translate
trunc
upper                           full except cases in SpecialCasing.txt
verify
word
wordIndex
wordLength
wordPos
words
x2b                             full (raise an error if not compatible with String)
x2c                             full (raise an error if not compatible with String)
x2d                             full (raise an error if not compatible with String
*/

::method "[]"
    -- ooRexx v5
    use strict arg n, length=1
    maxLength = self~length - n + 1 -- don't care about n<=0, will be caught by substr
    if maxLength <= 0 then return self~encoding~emptyString
    return self~substr(n, min(length, maxLength))


::method ?
    -- ooRexx v5
    self~checkLogicalValueCompatibility
    forward to (self~string)


::method append
    forward to (self~indexer)


::method c2d
    forward to (self~string)


::method c2x
    forward to (self~indexer)


::method caselessCompareTo
    use strict arg text, n=1, length=(self~length)
    -- Wrong fallback implementation
    return self~string~caselessCompareTo(text~string, n, length)


::method contains
    -- regex.cls uses the method .String~contains which is available only from ooRexx v5.
    use arg other -- not strict, just need to check this one
    otherIsCompatibleWithString = .true
    if other~isA(.RexxText), \other~isCompatibleWithString then otherIsCompatibleWithString = .false
    if self~isCompatibleWithString, otherIsCompatibleWithString then do
        forward message "pos" to (self~string) continue
        return result <> 0
    end
    raise syntax 23.900 array("Method 'contains' not yet implemented for Unicode")


::method copies
    use strict named arg buffer(1)=.nil
    forward to (self~string) continue
    if .nil <> buffer then return buffer~~append(result)
                      else return .RexxText~new(result, self~encoding)


::method hashCode
    forward to (self~string)


::method join
    -- Positional arguments : zero to N text/string or arrays of text/string (recursively).
    -- The text value of each argument is joined, with self used as separator
    -- If the encoding of an argument is not compatible for concatenation with self then an error is raised
    use strict named arg buffer(1)=.nil, appender(1)=(self~encoding)
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    buffer~join(arg(1, "a"), separator: self, a: appender)
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~encoding)


::method left
    use strict arg _length, _pad="" -- not used, it's just to check that we get at least the length, and that we don't get more than 2 arguments
    -- equivalent to substr(1, length, pad)
    forward message "substr" arguments (arg(1, "a")~prepend(1))


::method length -- number of graphemes
    use strict arg -- none
    return self~indexer~graphemeCount


::method lower
    use strict named arg buffer(1)=.nil
    if self~isCompatibleWithString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method match
    use arg _start, other, ... -- not strict, just need to check 'other'
    otherIsCompatibleWithString = .true
    if other~isA(.RexxText), \other~isCompatibleWithString then otherIsCompatibleWithString = .false
    if self~isCompatibleWithString, otherIsCompatibleWithString then forward to (self~string)
    raise syntax 23.900 array("Method 'match' not yet implemented for Unicode")


::method matchChar
    use arg n, chars -- not strict, just need to check 'other'
    charsIsCompatibleWithString = .true
    if chars~isA(.RexxText), \chars~isCompatibleWithString then charsIsCompatibleWithString = .false
    if self~isCompatibleWithString, charsIsCompatibleWithString then forward to (self~string)
    raise syntax 23.900 array("Method 'matchChar' not yet implemented for Unicode")


::method pos
    use arg needle, ... -- not strict, just need to check 'needle'
    needleIsCompatibleWithString = .true
    if needle~isA(.RexxText), \needle~isCompatibleWithString then needleIsCompatibleWithString = .false
    if self~isCompatibleWithString, needleIsCompatibleWithString then forward to (self~string)
    use strict arg needle, start=1, length=(self~length)
    raise syntax 23.900 array("Method 'pos' not yet implemented for Unicode")


::method reverse
    use strict named arg buffer(1)=.nil
    if self~isCompatibleWithString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method right
    -- can't delegate to substr because here the padding is on the left
    use arg _length, pad -- not strict, just need to check 'pad'
    use strict named arg buffer(1)=.nil
    padIsCompatibleWithString = .true
    if arg(2, "e") then do
        if pad~isA(.RexxText), \pad~isCompatibleWithString then padIsCompatibleWithString = .false
        else if pad~length > 1 then padIsCompatibleWithString = .false -- maybe its length will be 1 when converted to default encoding
    end
    if self~isCompatibleWithString, padIsCompatibleWithString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method subchar
    forward message "grapheme"


::method substr
    use arg _startB, _length, pad -- not strict, just need to check 'pad'
    use strict named arg buffer(1)=.nil
    padIsCompatibleWithString = .true
    if arg(3, "e") then do
        if pad~isA(.RexxText), \pad~isCompatibleWithString then padIsCompatibleWithString = .false
        else if pad~length > 1 then padIsCompatibleWithString = .false -- maybe its length will be 1 when converted to default encoding
    end
    if self~isCompatibleWithString, padIsCompatibleWithString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method upper
    use strict named arg buffer(1)=.nil
    if self~isCompatibleWithString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method x2b
    self~checkHexadecimalValueCompatibility
    forward to (self~string)


::method x2c
    use strict named arg buffer(1)=.nil
    self~checkHexadecimalValueCompatibility
    forward to (self~string) continue
    if .nil <> buffer then return buffer~~append(result)
                      else return .RexxText~new(result, self~encoding)


::method x2d
    self~checkHexadecimalValueCompatibility
    forward to (self~string)


/******************************************************************************/
::class "IndexerStringInterface" mixinclass Object private

::method append class
    -- Positional arguments : zero to N text or string.
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    previousText = .nil
    do i=1 to arg()
        text = arg(i)~request("RexxText")
        if .nil == text then signal must_have_a_text_or_string_value
        if .nil == previousText then encoding = .Encoding~forConcatenation(self, text) -- could raise an unjustified error because buffer's asciiness is not provided
                                else encoding = .Encoding~forConcatenation(previousText, text) -- raise an error if not compatible
        -- [To rework, next comment is no longer true, I added ~encoding on MutableBuffer]
        -- Remember: I test next equality because, unlike RexxText concatenation, I can't return either left encoding or right encoding.
        -- In the end, I return the buffer's string  whose encoding is self.
        -- So yes, appending to a buffer is more restrictive than appending to a RexxText
        if encoding <> self then signal incompatible_encoding -- for example when the buffer is utf8 and the appended text is wtf8
        encoding~concatenate(text, b: buffer)
        previousText = text
    end
    if returnBuffer then return buffer
    else return .RexxText~new(buffer~string, self)

    must_have_a_text_or_string_value: raise syntax 93.900 array("Method argument "i" must have a text or string value") -- 93.938 array(i)
    incompatible_encoding:            raise syntax 23.900 array("Encoding: cannot append" text~descriptionForError "to" self~description "text")


::method append
    use strict arg text -- text or string
    use strict named arg buffer(1)=.nil
    text = text~request("RexxText")
    if .nil == text then signal must_have_a_text_or_string_value
    encoding = .Encoding~forConcatenation(self~string~text, text) -- raise an error if not compatible
    return encoding~concatenate(self~string~text, text, b: buffer)

    must_have_a_text_or_string_value: raise syntax 93.900 array("Method argument 1 must have a text or string value") -- 93.938 array(1)


::method length -- number of graphemes
    use strict arg -- none
    return self~graphemeCount


::method lower
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer(1)=.nil

    if datatype(startC, "w"), startC > 0 then nop
    else signal incorrect_position

    if datatype(length, "w"), length >= 0 then nop
    else signal invalid_length

    if startC > self~length then return self~string~text
    if length == 0 then return self~string~text

    endC = min(startC + length - 1, self~length)
    startB = self~graphemeIndex(startC)
    endB = self~graphemeIndex(endC+1)

    string = self~string
    encoding = self~class
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(string~left(startB - 1))
                      else buffer~append(string~left(startB - 1))
    codepointIndexB = startB
    do while codepointIndexB < endB
        nextCodepointIndexB = encoding~nextCodepointIndex(string, codepointIndexB, raiseError: .false)
        if nextCodepointIndexB > 0 then do -- if no error
            codepointSizeB = nextCodepointIndexB - codepointIndexB
            codepoint = encoding~decode(string, codepointIndexB, codepointSizeB)
            codepoint = encoding~codepointToLower(codepoint)
            encoding~encode(codepoint, b: buffer)
        end
        codepointIndexB = abs(nextCodepointIndexB)
    end
    buffer~append(string~right(string~length - endB + 1))
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, encoding)

    invalid_length:             raise syntax 93.923 array(length)
    incorrect_position:         raise syntax 93.924 array(startC)


::method reverse
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    do indexG = self~graphemeCount to 1 by -1
        self~grapheme(indexG, b: buffer)
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~class)


::method right
    use strict arg length, pad=(self~class~spaceCharacter)
    use strict named arg buffer(1)=.nil

    if datatype(length, "w"), length >= 0 then nop
    else signal invalid_length

    pad = pad~request("RexxText")
    if .nil == pad then signal must_have_a_text_or_string_value
    if pad~length <> 1 then signal incorrect_pad

    encoding = .Encoding~forConcatenation(self~string~text, pad) -- raise an error if not compatible

    lengthPad = max(0, length - self~length)
    length = length - lengthPad

    endC = self~length + 1
    endB = self~graphemeIndex(endC)
    startC = endC - length
    startB = self~graphemeIndex(startC)
    right = self~string~right(endB - startB)
    if lengthPad == 0 then do
        if .nil <> buffer then return buffer~~append(right)
                          else return .RexxText~new(right, self~class)
    end
    if .nil <> buffer then do
        -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
        -- consequence: will not detect WTF8 special concatenation, if any.
        pad~copies(lengthPad, b: buffer)
        encoding~concatenate(right, b: buffer)
        return buffer
    end
    return encoding~concatenate(pad~copies(lengthPad), right, b: buffer)

    incorrect_pad:                    raise syntax 93.922 array(pad~descriptionForError)
    invalid_length:                   raise syntax 93.923 array(length)
    must_have_a_text_or_string_value: raise syntax 93.900 array("Method argument 3 must have a text or string value") -- 93.938 array(3)


::method substr
    use strict arg startC, length=(max(0, self~length - startC + 1)), pad=(self~class~spaceCharacter)
    use strict named arg buffer(1)=.nil

    if datatype(startC, "w"), startC > 0 then nop
    else signal incorrect_position

    if datatype(length, "w"), length >= 0 then nop
    else signal invalid_length

    pad = pad~request("RexxText")
    if .nil == pad then signal must_have_a_text_or_string_value
    if pad~length <> 1 then signal incorrect_pad

    encoding = .Encoding~forConcatenation(self~string~text, pad) -- raise an error if not compatible

    if startC > self~length then return pad~copies(length, b: buffer)
    remainingLength = self~length - startC + 1 -- always >= 0
    lengthPad = max(0, length - remainingLength)
    endC = min(startC + length - 1, self~length)

    startB = self~graphemeIndex(startC)
    endB = self~graphemeIndex(endC+1)
    substr = self~string~substr(startB, endB - startB)
    if lengthPad == 0 then do
        if .nil <> buffer then return buffer~~append(substr)
                          else return .RexxText~new(substr, self~class)
    end
    if .nil <> buffer then do
        encoding~concatenate(substr, b: buffer)
        -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
        -- consequence: will not detect WTF8 special concatenation, if any.
        pad~copies(lengthPad, b: buffer)
        return buffer
    end
    return encoding~concatenate(substr, pad~copies(lengthPad), b: buffer)

    incorrect_pad:                    raise syntax 93.922 array(pad~descriptionForError)
    invalid_length:                   raise syntax 93.923 array(length)
    incorrect_position:               raise syntax 93.924 array(startC)
    must_have_a_text_or_string_value: raise syntax 93.900 array("Method argument 3 must have a text or string value") -- 93.938 array(3)


::method upper
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer(1)=.nil

    if datatype(startC, "w"), startC > 0 then nop
    else signal incorrect_position

    if datatype(length, "w"), length >= 0 then nop
    else signal invalid_length

    if startC > self~length then return self~string~text
    if length == 0 then return self~string~text

    endC = min(startC + length - 1, self~length)
    startB = self~graphemeIndex(startC)
    endB = self~graphemeIndex(endC+1)

    string = self~string
    encoding = self~class
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(string~left(startB - 1))
                      else buffer~append(string~left(startB - 1))
    codepointIndexB = startB
    do while codepointIndexB < endB
        nextCodepointIndexB = encoding~nextCodepointIndex(string, codepointIndexB, raiseError: .false)
        if nextCodepointIndexB > 0 then do -- if no error
            codepointSizeB = nextCodepointIndexB - codepointIndexB
            codepoint = encoding~decode(string, codepointIndexB, codepointSizeB)
            codepoint = encoding~codepointToUpper(codepoint)
            encoding~encode(codepoint, b: buffer)
        end
        codepointIndexB = abs(nextCodepointIndexB)
    end
    buffer~append(string~right(string~length - endB + 1))
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, encoding)

    invalid_length:             raise syntax 93.923 array(length)
    incorrect_position:         raise syntax 93.924 array(startC)


/******************************************************************************/
::class "RexxTextOperators" mixinclass Object private

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
    /*
    ooRexx doc about string comparison methods:
    Both must be string objects. If argument is not a string object, it is
    converted to its string representation for the comparison. The one exception
    is when argument is .nil for the ==, \==, =, \=, ><, and <> operators.
    A string object will never compare equal to .nil, even when the string
    matches the string value of .nil ("The NIL object").
    As a result, == will always return .false when compared to .nil and \== will
    always return .true. All of the relational comparisons (for example, <, >,
    <=, etc.) will always return .false when compared to .nil.
    */
    if .nil == right then forward message (message) to (self~string) array(right)
    right = right~request("RexxText")
    if .nil == right then return
    if .Encoding~comparisonMode(self, right) == "b" then do
        forward message (message) to (self~string) array (right~string)
    end
    -- Unicode comparison
    forward message (message) to (self~string) array (right~string) -- fallback
    raise syntax 23.900 array("Unicode comparison not yet implemented")


::method compareLeftSelf
    use strict arg left, message
    left = left~request("RexxText")
    if .nil == left then return
    if .Encoding~comparisonMode(left, self) == "b" then do
        forward message (message) to (left~string) array (self~string)
    end
    -- Unicode comparison
    forward message (message) to (left~string) array (self~string) -- fallback
    raise syntax 23.900 array("Unicode comparison not yet implemented")


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

/* Native methods
RexxString *version();
RexxInteger *systemIsLittleEndian();
RexxInteger *graphemeBreak(RexxArray *);
RexxInteger *codepointCategory(RexxObject *rexxCodepoint);
RexxInteger *codepointCombiningClass(RexxObject *rexxCodepoint); // https://unicode.org/reports/tr15/#Detecting_Normalization_Forms
RexxInteger *codepointBidiClass(RexxObject *rexxCodepoint);
RexxInteger *codepointBidiMirrored(RexxObject *rexxCodepoint);
RexxInteger *codepointDecompositionType(RexxObject *rexxCodepoint);
RexxInteger *codepointIgnorable(RexxObject *rexxCodepoint);
RexxInteger *codepointControlBoundary(RexxObject *rexxCodepoint);
RexxInteger *codepointCharWidth(RexxObject *rexxCodepoint);
RexxInteger *codepointBoundClass(RexxObject *rexxCodepoint);
RexxInteger *codepointToLower(RexxObject *rexxCodepoint);
RexxInteger *codepointToUpper(RexxObject *rexxCodepoint);
RexxInteger *codepointToTitle(RexxObject *rexxCodepoint);
RexxInteger *codepointIsLower(RexxObject *rexxCodepoint);
RexxInteger *codepointIsUpper(RexxObject *rexxCodepoint);
*/


::constant maxCodepoint 1114111

::attribute dataDirectory get class
::attribute totalCharactersLoaded get class
::attribute totalIntervalCharacters get class
::attribute totalIntervalCharactersNotExpanded get class
::attribute totalCharacterNameAliases get class
::attribute codepointCategoryNames get class
::attribute codepointBidiClassNames get class
::attribute codepointDecompositionTypeNames get class
::attribute codepointBoundClassNames get class


::method initialize class
    expose dataDirectory characters characterNames -
                         characterIntervals characterIntervalNames -
                         totalCharactersLoaded -
                         totalIntervalCharacters -
                         totalIntervalCharactersNotExpanded -
                         totalCharacterNameAliases
    use strict arg -- none
    packageDirectory = .file~new(.context~package~name)~parent
    dataDirectory = .file~new("Unicode-".Unicode~version, packageDirectory)
    self~declareConstantNames
    characters = .array~new
    characterNames = .directory~new
    characterIntervals = .array~new
    characterIntervalNames = .relation~new -- different intervals have the same name, can't use a directory
    totalCharactersLoaded = 0
    totalIntervalCharacters = 0
    totalIntervalCharactersNotExpanded = -1
    totalCharacterNameAliases = 0
    self~declareCharacters


::method informations class
    messages = ,
    "characters",
    "characterIntervals",
    "dataDirectory",
    "maxCodepoint",
    "systemIsLittleEndian",
    "totalCharactersLoaded",
    "totalCharacterNameAliases",
    "totalIntervalCharacters",
    "totalIntervalCharactersNotExpanded",
    "version"
    informations = .directory~new
    do message over messages~subwords
        value = self~send(message)
        informations~put(value, message)
    end

    return informations


::method checkCodepoint class
    use strict arg codepoint, name=.nil
    if codepoint < -1 | codepoint > .Unicode~maxCodepoint then signal error_range
    return .true

    error_range:
    -- To be consistent with other checks, say the the lower limit is 0, even if -1 is a valid value
    if .nil <> name then raise syntax 23.900 array ("Character '"name"': invalid codepoint" codepoint "("ppCodepoint(codepoint)"). Allowed range is 0..".Unicode~maxCodepoint)
                    else raise syntax 23.900 array ("Invalid codepoint" codepoint "("ppCodepoint(codepoint)"). Allowed range is 0..".Unicode~maxCodepoint)

::method declareConstantNames class
    expose codepointCategoryNames codepointBidiClassNames codepointDecompositionTypeNames codepointBoundClassNames
    codepointCategoryNames = .array~new
    codepointBidiClassNames = .array~new
    codepointDecompositionTypeNames = .array~new
    codepointBoundClassNames = .array~new
    methods = self~methods
    do while methods~available
        methodName = methods~index
        if methodName~startsWith("CATEGORY_") then codepointCategoryNames[1 + self~send(methodName)] = methodName~substr("CATEGORY_"~length + 1)~lower(2)
        if methodName~startsWith("BIDI_CLASS_") then codepointBidiClassNames[self~send(methodName)] = methodName~substr("BIDI_CLASS_"~length + 1)
        if methodName~startsWith("DECOMPOSITION_TYPE_") then codepointDecompositionTypeNames[1 + self~send(methodName)] = methodName~substr("DECOMPOSITION_TYPE_"~length + 1)~lower(2)
        if methodName~startsWith("BOUNDCLASS_") then codepointBoundClassNames[1 + self~send(methodName)] = methodName~substr("BOUNDCLASS_"~length + 1)
        methods~next
    end


::method declareCharacters class
    -- Declare explictely the characters used internally or in demos.
    -- They are available even if the Unicode datas can't be loaded
    self~declareCharacter(  "20"~x2d, "SPACE")
    self~declareCharacter("0301"~x2d, "COMBINING ACUTE ACCENT")
    self~declareCharacter("FFFD"~x2d, "REPLACEMENT CHARACTER")
    self~declareCharacter(-1, "<UNKNOWN CHARACTER>") -- this is not part of the Unicode standard


::method declareCharacterInterval class
    expose characterIntervals characterIntervalNames
    use strict arg codepointFrom, codepointTo, name
    self~checkCodepoint(codepointFrom, name)
    self~checkCodepoint(codepointTo, name)
    characterInterval = .UnicodeCharacterInterval~new(codepointFrom, codepointTo, name)
    index = characterIntervals~append(characterInterval)
    looseMatchingIndex = UAX44_LM2(name)
    characterIntervalNames[looseMatchingIndex] = index


::method characterIntervals class
    expose characterIntervals
    return .UnicodeCharacterIntervalSupplier~new(characterIntervals)


::method expandCharacterIntervals class
    expose characterIntervals totalIntervalCharacters totalIntervalCharactersNotExpanded
    use strict arg showProgress=.false
    if totalIntervalCharactersNotExpanded <= 0 then return ""
    do interval over characterIntervals
        interval~expand(showProgress)
    end
    return "Total interval characters:" totalIntervalCharacters


::method characterIntervalByCodepoint class
    expose characterIntervals
    use strict arg codepoint
    -- characterIntervals is sorted ascending, can do a dichotomic search
    i1 = 1
    i2 = characterIntervals~size
    if i2 == 0 then return .nil
    do while i2 >= i1
        i = i1 + (i2 - i1) % 2
        interval = characterIntervals[i]
        if codepoint < interval~codepointFrom then i2 = i - 1
        else if codepoint > interval~codepointTo then i1 = i + 1
        else return interval
    end
    return .nil


::method declareCharacter class
    expose characterNames
    use strict arg codepoint, name=""
    character = self~characterByCodepoint(codepoint)
    if arg(2, "e") then do -- if name provided
        character~setName(name)
        looseMatchingIndex = UAX44_LM2(name)
        characterNames[looseMatchingIndex] = codepoint
    end
    return character


::method declareIntervalCharacter class
    expose totalIntervalCharactersNotExpanded
    use strict arg codepoint, name="", showProgress=.false
    self~declareCharacter(codepoint, name)
    totalIntervalCharactersNotExpanded -= 1
    if showProgress, totalIntervalCharactersNotExpanded // 2500 == 0 then call charout , "."


::method declareCharacterAlias class
    expose characterNames
    use strict arg codepoint, alias, type
    characterAlias = .UnicodeCharacterAlias~new(alias, type)
    character = self~characterByCodepoint(codepoint)
    character~aliases~append(characterAlias)
    looseMatchingIndex = UAX44_LM2(alias)
    characterNames[looseMatchingIndex] = codepoint
    return characterAlias


::method characters class
    expose characters
    use strict arg -- none
    return .UnicodeCharacterSupplier~new(characters) -- This supplier returns index-2


::method "[]" class
    forward message "character"


::method character class
    expose characters characterNames
    use strict arg name
    use named arg hexadecimal(1)=.false -- can't be guessed: 100 in hexadecimal is different from 100 in decimal

    -- is name an hexadecimal codepoint ?
    if hexadecimal then do
        call remove_leading_zeros
        if name~length <= 8, datatype(name, "X") then do
            numeric digits 10 -- to support FFFFFFFF, even if way too big for a codepoint (will be checked by characterByCodepoint)
            return self~characterByCodepoint(name~x2d)
        end
        signal invalid_hexadecimal_codepoint
    end

    -- is name a decimal codepoint ?
    if datatype(name, "W") then do
        call remove_leading_zeros
        if name~length <= 7 then return self~characterByCodepoint(name)
        signal invalid_decimal_codepoint
    end

    -- is name a U+ codepoint ?
    if name~caselessStartsWith("U+") then do
        prefix = name~left(2)
        name = name~substr(3)
        if name~length >= 4, name~length <= 6, datatype(name, "X") then do
            return self~characterByCodepoint(name~x2d)
        end
        signal invalid_u_plus
    end

    -- is name a character name?
    looseMatchingIndex = UAX44_LM2(name)
    codepoint = characterNames[looseMatchingIndex]
    if .nil <> codepoint then return characters[2 + codepoint] -- +2 because -1 and 0 must be supported
    signal name_not_found

    remove_leading_zeros:
        firstNonZero = name~verify("0")
        if firstNonZero == 0 then name = "0" -- 0[..0] replaced by 0
        else if firstNonZero > 1 then name = name~substr(firstNonZero) -- remove all the leading zeros
        return

    invalid_hexadecimal_codepoint: raise syntax 93.900 array("an hexadecimal codepoint is 1..8 hex digits, got '"name"'")
    invalid_decimal_codepoint:     raise syntax 93.900 array("a decimal codepoint is 1..7 digits, got '"name"'")
    invalid_u_plus:                raise syntax 93.900 array(prefix "is followed by 4..6 hex digits, got '"name"'")
    name_not_found:                raise syntax 93.900 array("Name '"name"' not found")


::method characterByCodepoint class
    expose characters
    use strict arg codepoint
    self~checkCodepoint(codepoint)
    character = characters[2 + codepoint] -- +2 because -1 and 0 must be supported
    if .nil == character  then do
        character = .UnicodeCharacter~new(codepoint)
        characters[2 + codepoint] = character
    end
    return character


::method spaceCharacter class
    expose spaceCharacter
    use strict arg -- none
    if \var("spaceCharacter") then spaceCharacter = self~character("SPACE")
    return spaceCharacter


::method replacementCharacter class
    expose replacementCharacter
    use strict arg -- none
    if \var("replacementCharacter") then replacementCharacter = self~character("REPLACEMENT CHARACTER")
    return replacementCharacter


::method unknownCharacter class
    expose unknownCharacter
    use strict arg -- none
    if \var("unknownCharacter") then unknownCharacter = self~character("<UNKNOWN CHARACTER>")
    return unknownCharacter


::method loadDerivedName class
    -- Optional: load all the Unicode character names
    -- action : "check", "getFile", "load"
    expose characterIntervals totalCharactersLoaded totalIntervalCharacters totalIntervalCharactersNotExpanded
    use strict arg action="check", showProgress=.false -- by default, checks if the Unicode data file exists
    derivedNameFile = .file~new("DerivedName.txt", self~dataDirectory)
    if "getFile"~caselessAbbrev(action, 1) then return derivedNameFile~string
    streamIn = .stream~new(derivedNameFile)
    status = streamIn~open("READ")
    if status <> "READY:" then do
        streamIn~close
        parse var status "ERROR:" error
        return SysGetErrorText(error)
    end
    if "check"~caselessAbbrev(action, 1) then do
        streamIn~close -- mandatory under Windows, otherwise the next call of loadDerivedName will raise "error 13 invalid data" because the file is locked by another process (!?)
        return "" -- means 'no error'
    end
    if totalCharactersLoaded == 0 then do -- if not yet loaded
        do while streamIn~state="READY"
            line=streamIn~linein
            if streamIn~state="NOTREADY", line == "" then leave
            /*
            # comment
            1FBF9         ; SEGMENTED DIGIT NINE
            20000..2A6DD  ; CJK UNIFIED IDEOGRAPH-*
            */
            if line~length == 0 then iterate
            if line~startsWith("#") then iterate -- ignore the comments
            parse var line codepoint . name
            if codepoint~contains("..") then do
                -- Remember: when expanding the ranges, that makes 100869 codepoints in Unicode 13
                parse var codepoint codepointFrom ".." codepointTo
                codepointFrom = codepointFrom~x2d
                codepointTo = codepointTo~x2d
                self~declareCharacterInterval(codepointFrom, codepointTo, name)
                intervalCount = 1 + codepointTo - codepointFrom
                totalCharactersLoaded += intervalCount
                totalIntervalCharacters += intervalCount
            end
            else do
                self~declareCharacter(codepoint~x2d, name)
                totalCharactersLoaded += 1
            end
            if showProgress, totalCharactersLoaded // 1000 == 0 then call charout , "."
        end
    end
    streamIn~close
    characterIntervals~sort
    totalIntervalCharactersNotExpanded = totalIntervalCharacters
    return "Total loaded character names:" totalCharactersLoaded


::method loadNameAliases class
    -- Optional: load the Unicode character name aliases
    -- action : "check", "getFile", "load"
    expose totalCharacterNameAliases
    use strict arg action="check", showProgress=.false -- by default, checks if the Unicode data file exists
    nameAliasesFile = .file~new("NameAliases.txt", self~dataDirectory)
    if "getFile"~caselessAbbrev(action, 1) then return nameAliasesFile~string
    streamIn = .stream~new(nameAliasesFile)
    status = streamIn~open("READ")
    if status <> "READY:" then do
        streamIn~close
        parse var status "ERROR:" error
        return SysGetErrorText(error)
    end
    if "check"~caselessAbbrev(action, 1) then do
        streamIn~close -- mandatory under Windows, otherwise the next call of loadDerivedName will raise "error 13 invalid data" because the file is locked by another process (!?)
        return "" -- means 'no error'
    end
    if totalCharacterNameAliases == 0 then do -- if not yet loaded
        do while streamIn~state="READY"
            line=streamIn~linein
            if streamIn~state="NOTREADY", line == "" then leave
            /*
            # comment
            000A;NEW LINE;control
            */
            if line~length == 0 then iterate
            if line~startsWith("#") then iterate -- ignore the comments
            parse var line codepoint ";" alias ";" type
            self~declareCharacterAlias(codepoint~x2d, alias, type)
            totalCharacterNameAliases += 1
            if showProgress, totalCharacterNameAliases // 10 == 0 then call charout , "."
        end
    end
    streamIn~close
    nameAliasesLoaded = .true
    return "Total character name aliases:" totalCharacterNameAliases


::method codepointCategoryName class
    expose codepointCategoryNames
    use strict arg codepoint
    category = self~codepointCategory(codepoint)
    return codepointCategoryNames[1+category]


-- Values returned by .Unicode~codepointCategory(codepoint)
-- Unicode Standard 4.5 General Category
-- Table 4-4. General Category
-- Also:
-- https://unicode.org/reports/tr44/#GC_Values_Table
::constant CATEGORY_CN  0 /**< Other, not assigned */
::constant CATEGORY_LU  1 /**< Letter, uppercase */
::constant CATEGORY_LL  2 /**< Letter, lowercase */
::constant CATEGORY_LT  3 /**< Letter, titlecase */
::constant CATEGORY_LM  4 /**< Letter, modifier */
::constant CATEGORY_LO  5 /**< Letter, other */
::constant CATEGORY_MN  6 /**< Mark, nonspacing */
::constant CATEGORY_MC  7 /**< Mark, spacing combining */
::constant CATEGORY_ME  8 /**< Mark, enclosing */
::constant CATEGORY_ND  9 /**< Number, decimal digit */
::constant CATEGORY_NL 10 /**< Number, letter */
::constant CATEGORY_NO 11 /**< Number, other */
::constant CATEGORY_PC 12 /**< Punctuation, connector */
::constant CATEGORY_PD 13 /**< Punctuation, dash */
::constant CATEGORY_PS 14 /**< Punctuation, open */
::constant CATEGORY_PE 15 /**< Punctuation, close */
::constant CATEGORY_PI 16 /**< Punctuation, initial quote */
::constant CATEGORY_PF 17 /**< Punctuation, final quote */
::constant CATEGORY_PO 18 /**< Punctuation, other */
::constant CATEGORY_SM 19 /**< Symbol, math */
::constant CATEGORY_SC 20 /**< Symbol, currency */
::constant CATEGORY_SK 21 /**< Symbol, modifier */
::constant CATEGORY_SO 22 /**< Symbol, other */
::constant CATEGORY_ZS 23 /**< Separator, space */
::constant CATEGORY_ZL 24 /**< Separator, line */
::constant CATEGORY_ZP 25 /**< Separator, paragraph */
::constant CATEGORY_CC 26 /**< Other, control */
::constant CATEGORY_CF 27 /**< Other, format */
::constant CATEGORY_CS 28 /**< Other, surrogate */
::constant CATEGORY_CO 29 /**< Other, private use */


::method codepointBidiClassName class
    expose codepointBidiClassNames
    use strict arg codepoint
    bidiClass = self~codepointBidiClass(codepoint)
    return codepointBidiClassNames[bidiClass]


-- Values returned by .Unicode~codepointBidiClass(codepoint)
-- http://unicode.org/reports/tr9/tr9-11.html
-- Table 3-7. Bidirectional Character Types
::constant BIDI_CLASS_L     1 /**< Left-to-Right */
::constant BIDI_CLASS_LRE   2 /**< Left-to-Right Embedding */
::constant BIDI_CLASS_LRO   3 /**< Left-to-Right Override */
::constant BIDI_CLASS_R     4 /**< Right-to-Left */
::constant BIDI_CLASS_AL    5 /**< Right-to-Left Arabic */
::constant BIDI_CLASS_RLE   6 /**< Right-to-Left Embedding */
::constant BIDI_CLASS_RLO   7 /**< Right-to-Left Override */
::constant BIDI_CLASS_PDF   8 /**< Pop Directional Format */
::constant BIDI_CLASS_EN    9 /**< European Number */
::constant BIDI_CLASS_ES   10 /**< European Separator */
::constant BIDI_CLASS_ET   11 /**< European Number Terminator */
::constant BIDI_CLASS_AN   12 /**< Arabic Number */
::constant BIDI_CLASS_CS   13 /**< Common Number Separator */
::constant BIDI_CLASS_NSM  14 /**< Nonspacing Mark */
::constant BIDI_CLASS_BN   15 /**< Boundary Neutral */
::constant BIDI_CLASS_B    16 /**< Paragraph Separator */
::constant BIDI_CLASS_S    17 /**< Segment Separator */
::constant BIDI_CLASS_WS   18 /**< Whitespace */
::constant BIDI_CLASS_ON   19 /**< Other Neutrals */
::constant BIDI_CLASS_LRI  20 /**< Left-to-Right Isolate */
::constant BIDI_CLASS_RLI  21 /**< Right-to-Left Isolate */
::constant BIDI_CLASS_FSI  22 /**< First Strong Isolate */
::constant BIDI_CLASS_PDI  23 /**< Pop Directional Isolate */


::method codepointDecompositionTypeName class
    expose codepointDecompositionTypeNames
    use strict arg codepoint
    decompositionType = self~codepointDecompositionType(codepoint)
    return codepointDecompositionTypeNames[1 + decompositionType]


-- Values returned by .Unicode~codepointDecompositionType(codepoint)
-- https://unicode.org/reports/tr44/#Formatting_Tags_Table
-- Table 14. Compatibility Formatting Tags
::constant DECOMPOSITION_TYPE_NONE      0 -- not in utf8proc, added because can be zero
::constant DECOMPOSITION_TYPE_FONT      1 /**< Font */
::constant DECOMPOSITION_TYPE_NOBREAK   2 /**< Nobreak */
::constant DECOMPOSITION_TYPE_INITIAL   3 /**< Initial */
::constant DECOMPOSITION_TYPE_MEDIAL    4 /**< Medial */
::constant DECOMPOSITION_TYPE_FINAL     5 /**< Final */
::constant DECOMPOSITION_TYPE_ISOLATED  6 /**< Isolated */
::constant DECOMPOSITION_TYPE_CIRCLE    7 /**< Circle */
::constant DECOMPOSITION_TYPE_SUPER     8 /**< Super */
::constant DECOMPOSITION_TYPE_SUB       9 /**< Sub */
::constant DECOMPOSITION_TYPE_VERTICAL 10 /**< Vertical */
::constant DECOMPOSITION_TYPE_WIDE     11 /**< Wide */
::constant DECOMPOSITION_TYPE_NARROW   12 /**< Narrow */
::constant DECOMPOSITION_TYPE_SMALL    13 /**< Small */
::constant DECOMPOSITION_TYPE_SQUARE   14 /**< Square */
::constant DECOMPOSITION_TYPE_FRACTION 15 /**< Fraction */
::constant DECOMPOSITION_TYPE_COMPAT   16 /**< Compat */


::method codepointBoundClassName class
    expose codepointBoundClassNames
    use strict arg codepoint
    boundClass = self~codepointBoundClass(codepoint)
    return codepointBoundClassNames[1+boundClass]


-- Grapheme_Cluster_Break (GCB)
-- Values returned by .Unicode~codepointBoundClass(codepoint)
::constant BOUNDCLASS_START               0 /**< Start */       -- not in standard
::constant BOUNDCLASS_XX                  1 /**< Other */
::constant BOUNDCLASS_CR                  2 /**< CR */
::constant BOUNDCLASS_LF                  3 /**< LF */
::constant BOUNDCLASS_CN                  4 /**< Control */
::constant BOUNDCLASS_EX                  5 /**< Extend */
::constant BOUNDCLASS_L                   6 /**< L */
::constant BOUNDCLASS_V                   7 /**< V */
::constant BOUNDCLASS_T                   8 /**< T */
::constant BOUNDCLASS_LV                  9 /**< LV */
::constant BOUNDCLASS_LVT                10 /**< LVT */
::constant BOUNDCLASS_RI                 11 /**< Regional_Indicator */
::constant BOUNDCLASS_SM                 12 /**< SpacingMark */
::constant BOUNDCLASS_PP                 13 /**< Prepend */
::constant BOUNDCLASS_ZWJ                14 /**< ZWJ (Zero Width Joiner) */

/* the following are no longer used in Unicode 11 */
::constant BOUNDCLASS_EB                 15 /**< E_Base (Emoji Base) */
::constant BOUNDCLASS_EM                 16 /**< E_Modifier (Emoji Modifier) */
::constant BOUNDCLASS_GAZ                17 /**< Glue_After_Zwj */
::constant BOUNDCLASS_EBG                18 /**< E_Base_GAZ (E_BASE + GLUE_AFTER_ZJW) */

/* the Extended_Pictographic property is used in the Unicode 11
   grapheme-boundary rules, so we store it in the boundclass field */
::constant BOUNDCLASS_EXTENDED_PICTOGRAPHIC 19
::constant BOUNDCLASS_E_ZWG 20 /* BOUNDCLASS_EXTENDED_PICTOGRAPHIC + ZWJ */


/*
UAX44-LM2.
https://unicode.org/reports/tr44/#UAX44-LM2
*/
::routine UAX44_LM2 public -- private
    use strict arg string
    buffer = .MutableBuffer~new(string)
    /*
    1. remove all medial hyphens (except the medial hyphen in the name for U+1180
    HANGUL JUNGSEONG O-E).
    In this rule "medial hyphen" is to be construed as a hyphen occurring immediately
    between two letters in the normative Unicode character name, as published in
    the Unicode names list, and not to any hyphen that may transiently occur medially
    as a result of removing whitespace before removing hyphens in a particular
    implementation of matching.
    Thus the hyphen in the name U+10089 LINEAR B IDEOGRAM B107M HE-GOAT is medial,
    and should be ignored in loose matching,
    but the hyphen in the name U+0F39 TIBETAN MARK TSA -PHRU is not medial, and
    should not be ignored in loose matching.
    */
    buffer~space
    pos = 2 -- yes, 2, not 1
    do forever
        pos = buffer~verify("-", "M", pos)
        if pos == 0 then leave
        if buffer~subchar(pos-1)~verify(.string~alpha) == 0, buffer~subchar(pos+1)~verify(.string~alpha) == 0 then do
            if buffer~subchar(pos+2) == "", buffer~string~caselessEquals("HANGUL JUNGSEONG O-E") then leave
            buffer~replaceAt(" ", pos, 1)
        end
        else pos += 1 -- keep the hyphen. Ex: "TIBETAN MARK GTER YIG MGO -UM RNAM BCAD MA"
    end

    /*
    2. remove all whitespace and underscore characters
    */
    buffer~translate("", "_")
    buffer~space(0)

    /*
    3.apply toLowercase() to both strings
    */
    buffer~lower

    return buffer~string


/*
UAX44-LM3
https://unicode.org/reports/tr44/#UAX44-LM3
*/
::routine UAX44_LM3 public -- private
    use strict arg string
    buffer = .MutableBuffer~new(string)
    /*
    Ignore case, whitespace, underscore ('_'), hyphens, and any initial prefix string "is".

    "linebreak" is equivalent to "Line_Break" or "Line-break"
    "lb=BA" is equivalent to "lb=ba" or "LB=BA"
    "Script=Greek" is equivalent to "Script=isGreek" or "Script=Is_Greek"
    */
    buffer~translate("", "_-")
    buffer~space(0)
    buffer~lower
    if buffer~pos("is", 1, 2) == 1 then buffer~delete(1, 2)
    return buffer~string


/******************************************************************************/
::class "UnicodeCharacter" public

::attribute codepoint get
::attribute name get
::attribute aliases get

::method init
    expose codepoint name aliases
    use strict arg codepoint, name="", aliases=(.array~new)


::method string
    expose codepoint name aliases
    use strict arg encoding=(.Encoding~defaultOutputEncoding)
    encoding = .Encoding~factory(encoding)
    if codepoint < 32 then string = "" -- the control characters are not displayed
                      else string = encoding~encode(codepoint)~string
    string = '"'string'"' " "~copies(3 - self~charWidth)
    string ||= ppCodepoint(codepoint) self~categoryName self~charWidth name~quoted
    string = ", "~join(string, aliases~each{item~string~quoted})
    return " "string" "


::method text
    expose codepoint
    use strict arg encoding="default"
    use strict named arg buffer(1)=.nil
    encoding = .Encoding~factory(encoding)
    return encoding~encode(codepoint, b: buffer)


::method makeRexxText
    use strict arg -- none
    return self~text


::method setName -- should be scope package
    expose name
    use strict arg name


::method UTF8
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .UTF8_Encoding~encode(codepoint, b: buffer)


::method WTF8
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .WTF8_Encoding~encode(codepoint, b: buffer)


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .UTF16BE_Encoding~encode(codepoint, b:buffer)


::method UTF16LE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .UTF16LE_Encoding~encode(codepoint, b: buffer)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .WTF16BE_Encoding~encode(codepoint, b: buffer)


::method WTF16LE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .WTF16LE_Encoding~encode(codepoint, b: buffer)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .UTF32BE_Encoding~encode(codepoint, b: buffer)


::method UTF32LE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .UTF32LE_Encoding~encode(codepoint, b: buffer)


::method Unicode
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    targetEncoding = .Unicode_Encoding~toSupport(codepoint)
    return targetEncoding~encode(codepoint, b: buffer)


::method Unicode8
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .Unicode8_Encoding~encode(codepoint, b: buffer)


::method Unicode16
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .Unicode16_Encoding~encode(codepoint, b: buffer)


::method Unicode32
    expose codepoint
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return .Unicode32_Encoding~encode(codepoint, b: buffer)


::method category
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointCategory(codepoint)


::method categoryName
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointCategoryName(codepoint)


::method combiningClass
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointCombiningClass(codepoint)


::method bidiClass
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointBidiClass(codepoint)


::method bidiClassName
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointBidiClassName(codepoint)


::method bidiMirrored
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointBidiMirrored(codepoint)


::method decompositionType
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointDecompositionType(codepoint)


::method decompositionTypeName
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointDecompositionTypeName(codepoint)


::method ignorable
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointIgnorable(codepoint)


::method controlBoundary
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointControlBoundary(codepoint)


::method charWidth
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointCharWidth(codepoint)


::method boundClass
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointBoundClass(codepoint)


::method boundClassName
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointBoundClassName(codepoint)


::method toLower
    expose codepoint
    use strict arg -- none
    return .Unicode~character(.Unicode~codepointToLower(codepoint))


::method toUpper
    expose codepoint
    use strict arg -- none
    return .Unicode~character(.Unicode~codepointToUpper(codepoint))


::method toTitle
    expose codepoint
    use strict arg -- none
    return .Unicode~character(.Unicode~codepointToTitle(codepoint))


::method isLower
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointIsLower(codepoint)


::method isUpper
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointIsUpper(codepoint)


/******************************************************************************/
::class "UnicodeCharacterAlias" public

/*
# Type Labels:
#
# 1. correction
#      Corrections for serious problems in the character names
# 2. control
#      ISO 6429 names for C0 and C1 control functions, and other
#      commonly occurring names for control codes
# 3. alternate
#      A few widely used alternate names for format characters
# 4. figment
#      Several documented labels for C1 control code points which
#      were never actually approved in any standard
# 5. abbreviation
#      Commonly occurring abbreviations (or acronyms) for control codes,
#      format characters, spaces, and variation selectors
*/

::attribute alias get
::attribute type get

::method init
    expose alias type
    use strict arg alias, type


::method string
    expose alias
    return alias


/******************************************************************************/
::class "UnicodeCharacterInterval" public inherit Comparable

::attribute codepointFrom get
::attribute codepointTo get
::attribute name get
::attribute isExpanded get

::method init
    expose codepointFrom codepointTo name isExpanded
    use strict arg codepointFrom, codepointTo, name
    isExpanded = .false


::method string
    expose codepointFrom codepointTo name isExpanded
    string = ppCodepoint(codepointFrom)".."ppCodepoint(codepointTo) name~quoted
    string = string (codepointTo - codepointFrom) "characters"
    if isExpanded then string = string "expanded"
    return string


::method compareTo
    expose codepointFrom
    use arg other
    -- Numeric comparison
    return sign(codepointFrom - other~codepointFrom)


::method expand
    expose codepointFrom codepointTo name isExpanded
    use strict arg showProgress
    if isExpanded then return .false -- already expanded
    parse var name baseName "*" -- remove the final *
    unicode = .Unicode -- optim
    loop codepoint = codepointFrom to codepointTo
        unicode~declareIntervalCharacter(codepoint, baseName || codepoint~d2x, showProgress)
    end
    isExpanded = .true
    return .true


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

    ~c2d is always big-endian, whatever the endianness of the CPU:
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

    encodings["UTF8"] = .UTF8_Encoding
    encodings["WTF8"] = .WTF8_Encoding

    encodings["UTF16"] = .UTF16BE_Encoding
    encodings["UTF16BE"] = .UTF16BE_Encoding
    encodings["UTF16LE"] = .UTF16LE_Encoding
    encodings["WTF16"] = .WTF16BE_Encoding
    encodings["WTF16BE"] = .WTF16BE_Encoding
    encodings["WTF16LE"] = .WTF16LE_Encoding

    encodings["UTF32"] = .UTF32BE_Encoding
    encodings["UTF32BE"] = .UTF32BE_Encoding
    encodings["UTF32LE"] = .UTF32LE_Encoding

    -- "UNICODE" can't be used to create a RexxText.
    -- But can be used in conversion, to get the shortest possible representation
    -- encodings["UNICODE"] = .Unicode_Encoding

    encodings["UNICODE8"] = .Unicode8_Encoding
    encodings["UNICODE16"] = .Unicode16_Encoding
    encodings["UNICODE32"] = .Unicode32_Encoding

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
    raise syntax 23.900 array("Encoding: '"encoding"' is not supported")


::method forConcatenation class
    use strict arg left, right -- encoding (no asciiness) or text

    leftEncoding = left
    leftIsAscii = .false
    if left~isA(.RexxText) then do
        leftEncoding = left~encoding
        leftIsASCII = left~isASCII
    end

    rightEncoding = right
    rightIsASCII = .false
    if right~isA(.RexxText) then do
        rightEncoding = right~encoding
        rightIsASCII = right~isASCII
    end

    if leftEncoding == rightEncoding then return leftEncoding

    if leftEncoding~isUTF8, rightEncoding~isWTF8 then return .WTF8_Encoding
    if leftEncoding~isWTF8, rightEncoding~isUTF8 then return .WTF8_Encoding
    -- Keep the following tests after the previous tests, to keep the priority for WTF8
    if leftIsASCII, (rightEncoding~isUTF8 | rightEncoding~isWTF8) then return rightEncoding
    if (leftEncoding~isUTF8 | leftEncoding~isWTF8), rightIsASCII then return leftEncoding

    if leftEncoding~isUTF16BE, rightEncoding~isWTF16BE then return .WTF16BE_Encoding
    if leftEncoding~isWTF16BE, rightEncoding~isUTF16BE then return .WTF16BE_Encoding
    if leftEncoding~isUTF16LE, rightEncoding~isWTF16LE then return .WTF16LE_Encoding
    if leftEncoding~isWTF16LE, rightEncoding~isUTF16LE then return .WTF16LE_Encoding

    raise syntax 23.900 array("Encoding: cannot concatenate" left~descriptionForError "with" right~descriptionForError)


::method comparisonMode class
    -- if a byte comparison is possible then return "b"
    -- if a unicode comparision is possible then return "u"
    -- otherwise raise an error
    use strict arg leftText, rightText
    if leftText~isByte, rightText~isByte, leftText~encoding == rightText~encoding then return "b"
    if leftText~isASCII, rightText~isASCII then return "b"
    if leftText~isASCII, (rightText~isUTF8 | rightText~isWTF8) then return "u"
    if (leftText~isUTF8 | leftText~isWTF8), rightText~isASCII then return "u"
    if leftText~isUnicode & rightText~isUnicode then return "u"
    raise syntax 23.900 array("Encoding: cannot compare" leftText~descriptionForError "with" rightText~descriptionForError)


/******************************************************************************/
::class "StringIndexer" mixinclass Object private -- abstract

::method name class abstract


::constant isByte 0
::constant isUnicode 0
::constant isUTF8 0
::constant isWTF8 0
::constant isUTF16 0
::constant isUTF16BE 0
::constant isUTF16LE 0
::constant isWTF16 0
::constant isWTF16BE 0
::constant isWTF16LE 0
::constant isUTF32 0
::constant isUTF32BE 0
::constant isUTF32LE 0
::constant isWTF32 0
::constant isWTF32BE 0
::constant isWTF32LE 0
::constant isUnicodeN 0
::constant isUnicode8 0
::constant isUnicode16 0
::constant isUnicode32 0


::method codeUnitSizeInBytes class abstract -- 1 2 or 4


::method codepointMaxBytes class abstract -- used for buffer allocation


::method analyze class abstract


::method checkCodepoint class abstract


::method decode class abstract


::method byteSequenceSize class abstract


::method nextCodepointIndex class abstract


::method encode class abstract


::method codepointSizeInBytes class abstract -- how many bytes to encode this codepoint


::method codepointToLower class abstract


::method codepointToUpper class abstract


::method description class
    -- 'UTF-8 not-ASCII'
    use arg isASCII -- optional
    use strict named arg short(1)=.false, technical(1)=.false -- same as the instance method, not used (for the moment)
    if arg(1, "o") then return self~name
    if self~codeUnitSizeInBytes > 1 then return self~name -- doesn't make sense to include asciiness
    if isASCII then asciiness = "ASCII"
               else asciiness = "not-ASCII"
    return self~name asciiness


::method descriptionForError class
    forward message "description"


::method concatenate class
    -- Positional arguments : zero to N text or string.
    -- This method must be called from a subclass of StringIndexer
    -- Precondition: the encodings are compatible with self (you have checked that with .Encoding~forConcatenation)
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    do i = 1 to arg()
        -- Only WTF-8 has a specific implementation of appendToBuffer.
        -- When concatenating WTF-8 with UTF-8 or ASCII, the target encoding is WTF-8.
        -- So self is WTF-8.
        -- [later]
        -- Finally, it appears that the initial implementation was correct.
        -- The special concatenation rules for WTF-8 must be applied only if arg(i) is WTF-8.
        -- So arg(i)~encoding~appendToBuffer is better than self~appendToBuffer.
        if arg(i)~isA(.String) then .Encoding~defaultEncoding~appendToBuffer(arg(i), b:buffer) -- no encoding, use default encoding
        else arg(i)~encoding~appendToBuffer(arg(i)~string, b: buffer) -- "old" implementation is the good one
        -- self~appendToBuffer(arg(i)~string, b:buffer) -- "new" implementation is a bad idea.
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method emptyString class
    expose emptyString
    use strict arg -- none
    if \var("emptyString") then emptyString = .RexxText~new("", self)
    return emptyString


::method spaceCharacter class
    expose spaceCharacter
    use strict arg -- none
    if \var("spaceCharacter") then spaceCharacter = self~encode(.Unicode~spaceCharacter~codepoint)
    return spaceCharacter


::method appendToBuffer class
    -- WTF-8 overrides this method
    use strict arg string
    use strict named arg buffer(1)
    buffer~append(string)


/********************/
/* Instance methods */
/********************/

::attribute string get
::attribute string set private
::attribute maximumCodepoint get -- -1 if not calculated (Byte_Encoding doesn't calculate it)
::attribute codepointIndexes get private -- will be removed, no need of direct access to a codepoint
::attribute codepointCount get
::attribute graphemeIndexes get private
::attribute graphemeCount get
::attribute errors get
::attribute case get -- 1 lowercase, 2 uppercase


::method init
    expose string maximumCodepoint codepointIndexes codepointCount  graphemeIndexes graphemeCount case errors
    use strict arg string, maximumCodepoint, codepointIndexes, codepointCount, graphemeIndexes, graphemeCount, case, errors


::method copy
    -- No need to re-analyze the string, it's immutable:
    -- all the indexes are still applicable, just change the string referenced by the indexer.
    use strict arg -- none
    clone = self~copy:super
    clone~string = .string~new(clone~string) -- don't use ~copy (stack overflow)
    return clone


::method description
    /*
    "noël👩‍👨‍👩‍👧🎅"~text~description(s:1)          -- 'UTF-8 not-ASCII'
    "noël👩‍👨‍👩‍👧🎅"~text~description               -- 'UTF-8 not-ASCII (6 graphemes, 12 codepoints, 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~description(t:1)          -- 'UTF-8 not-ASCII (6 graphemes (3 indexes from index 4), 12 codepoints (9 indexes from index 4), 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~utf16~description(t:1)    -- 'UTF-16BE not-ASCII (6 graphemes (1 index from index 6), 12 codepoints (7 indexes from index 6), 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~utf32~description(t:1)    -- 'UTF-32BE not-ASCII (6 graphemes (1 index from index 6), 12 codepoints (0 index), 48 bytes, 0 error)'
    */
    use strict arg -- none
    use strict named arg short(1)=.false, technical(1)=.false
    if .nil == self~errors then errorCount = 0
                           else errorCount = self~errors~size
    techInfoCodepoints = ""
    techInfoGraphemes = ""
    if technical then do
        if .nil == self~codepointIndexes,
            then techInfoCodepoints = " (0 index)"
            else techInfoCodepoints = " ("self~codepointIndexes~items~singularPluralCount("index", "indexes")" from index "self~codepointIndexes~first")"
        if .nil == self~graphemeIndexes,
            then techInfoGraphemes = " (0 index)"
            else techInfoGraphemes = " ("self~graphemeIndexes~items~singularPluralCount("index", "indexes")" from index "self~graphemeIndexes~first")"
    end
    sizesDescription = ""
    if \short then sizesDescription = "(" ||,
                                      self~graphemes~count~singularPluralCount("grapheme", "graphemes")techInfoGraphemes",",
                                      self~codepoints~count~singularPluralCount("codepoint", "codepoints")techInfoCodepoints",",
                                      self~string~length~singularPluralCount("byte", "bytes")",",
                                      errorCount~singularPluralCount("error", "errors"),
                                      || ")"
    return " "~join(self~class~description(self~string~isASCII), sizesDescription)


::method DescriptionForError
    -- Display the <length> first characters
    use strict arg length=10
    text = self~string~text
    if text~length > length then text = text~left(length - 3)"..."
    -- escape3 is needed to have a proper display for this:
    -- say "41"~text~utf16~string  -- 41
    -- say escape3("41"~text~utf16~string)  -- [00]4[00]1
    return self~description(s:1) "'"escape3(text~string)"'"


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
    use strict named arg buffer(1)=.nil
    codepoints = self~codepoints
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    first = .true
    do while codepoints~available
        if \first then buffer~append(" ")
        first = .false
        call ppCodepoint codepoints~item, b: buffer
        codepoints~next
    end
    if returnBuffer then return buffer
                    else return buffer~string


::method c2g
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    graphemes = self~graphemes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    first = .true
    do while graphemes~available
        if \first then buffer~append(" ")
        first = .false
        buffer~append(graphemes~item~string~c2x)
        graphemes~next
    end
    if returnBuffer then return buffer
                    else return buffer~string


::method codepoints
    use strict arg -- none
    return .CodePointSupplier~new(self)


::method codepoint abstract


::method characters
    use strict arg -- none
    return self~codepoints~each{.unicode~character(item)}


::method graphemes
    use strict arg -- none
    return .GraphemeSupplier~new(self)


::method grapheme abstract


::method isLower
    expose case
    return case == 1


::method isUpper
    expose case
    return case == 2


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


::method Unicode abstract


::method Unicode8 abstract


::method Unicode16 abstract


::method Unicode32 abstract


::method unescape abstract
    /*
    Executor supports
        \u{Unicode name}    Character name in the Unicode database
        \U{Unicode name}
        \u{X..X}            Unicode character denoted by 1-8 hex digits. The first character must be a digit 0..9.
        \U{X..X}
        \uXXXX              Unicode character denoted by 4 hex digits ('u' lowercase)
        \UXXXXXXXX          Unicode character denoted by 8 hex digits ('U' uppercase)

    How other languages are supporting escape characters for Unicode:
        \N{Unicode name}    Character name in the Unicode database (Python, Julia)
        \u{Unicode name}
        \U{Unicode name}
        \u{X..X}            Unicode character denoted by a 1–8 hex digits (Swift)
        \u{XXXXXX}          hexadecimal Unicode code point UTF-8 encoded (1 or more digits) (zig)
        \uXXXX              Unicode character denoted by four hex digits (Python, Julia, Netrexx, Java, JSON)
        \UXXXXXXXX          Unicode character denoted by eight hex digits (Python, Julia)

        https://javajee.com/unicode-escapes-in-java
        The compiler translates Unicode escapes into the characters they represent
        before it parses a program into tokens. It also does so before discarding
        comments and white space.
        System.out.println("a\u0022.length() + \u0022b".length()); // print 2
        is same as
        System.out.println("a".length() + "b".length());
    */


/******************************************************************************/
::class "Byte_CommonServices" mixinclass Object private
-- Services for byte-oriented strings (byte, utf-8, wtf-8)

::method unescape
    -- The escape characters are used in literal strings, they should be managed
    -- at parse-time. Here, this method is used at run-time.
    -- This method could work for utf-16, wtf-16, utf-32 if it was rewritten
    -- to use RexxText API instead of String API. But would be way slower...
    -- Would it make sense ? Nobody is editing literal strings encoded in 16-bit
    -- or 32-bit.
    use strict named arg buffer(1)=.nil
    string = self~string
    pos = string~pos("\")
    if pos == 0 then do
        -- optim: don't create intermediate buffer if nothing to unescape
        if .nil == buffer then return self~string~text
        return buffer~~append(string)
    end
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, string~length)
    from = 1
    do until pos == 0
        buffer~append(string~substr(from, pos - from))
        pos += 1
        character = string~subchar(pos)
        pos += 1
        select
            when character == "\" then buffer~append("\")   -- escaped \
            when character == "a" then buffer~append("07"x) -- audible bell (BEL)
            when character == "b" then buffer~append("08"x) -- backspace (BS)
            when character == "f" then buffer~append("0C"x) -- form feed (FF)
            when character == "n" then buffer~append("0A"x) -- linefeed (LF)
            when character == "r" then buffer~append("0D"x) -- carriage return (CR)
            when character == "t" then buffer~append("09"x) -- horizontal tab (HT)
            when character == "v" then buffer~append("0B"x) -- vertical tab (VT)

            when character == "u" | character == "U" then do
                if \self~isUnicode then signal unicode_character_not_supported

                -- \u{Unicode name}    Character name in the Unicode database
                -- \u{X..X}            Unicode character denoted by 1-8 hex digits
                if string~subchar(pos) == "{" then do
                    pos += 1 -- skip {
                    first = pos
                    pos = string~pos("}", pos)
                    if pos == 0 then signal expecting_name_or_sequence_of_hexadecimal_digits
                    length = pos - first
                    if length == 0 then signal expecting_name_or_sequence_of_hexadecimal_digits
                    pos += 1 -- skip }
                    idntfr = string~substr(first, length)
                    startWithDigit = idntfr~left(1)~datatype("9")
                    character = .Unicode~character(idntfr, hexadecimal: startWithDigit)
                    character~text(self~class, b:buffer)
                end

                else if character == "u" then do
                    -- \uXXXX
                    length = min(4, string~length - pos + 1)
                    codepoint = string~substr(pos, length)
                    if codepoint~length < 4 then signal expecting_4_hexadecimal_digits
                    if \codepoint~datatype("X") then signal expecting_4_hexadecimal_digits
                    character = .Unicode~character(codepoint, hexadecimal: .true)
                    character~text(self~class, b:buffer)
                    pos += 4
                end

                else if character == "U" then do
                    -- \uXXXXXXXX
                    length = min(8, string~length - pos + 1)
                    codepoint = string~substr(pos, length)
                    if codepoint~length < 8 then signal expecting_8_hexadecimal_digits
                    if \codepoint~datatype("X") then signal expecting_8_hexadecimal_digits
                    character = .Unicode~character(codepoint, hexadecimal: .true)
                    character~text(self~class, b:buffer)
                    pos += 8
                end

            end

            when character == "x" then do
                -- \x{X..X} sequence of 1..n hexadecimal digits
                if string~subchar(pos) \== "{" then signal expecting_sequence_of_hexadecimal_digits
                pos += 1 -- skip {
                first = pos
                pos = string~pos("}", pos)
                if pos == 0 then signal expecting_sequence_of_hexadecimal_digits
                length = pos - first
                if length == 0 then signal expecting_sequence_of_hexadecimal_digits
                pos += 1 -- skip }
                hexadecimalDigits = string~substr(first, length)
                characters = hexadecimalDigits~x2c -- 1..n bytes
                buffer~append(characters)
            end

            otherwise signal unsupported_escape_character
        end
        from = pos
        pos = string~pos("\", from)
    end
    buffer~append(string~substr(from))

    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~class)

    unicode_character_not_supported:                  raise syntax 23.900 array(self~class~name "encoding: \"character" not supported")
    expecting_name_or_sequence_of_hexadecimal_digits: raise syntax 23.900 array(self~class~name "encoding: expecting a character name {name} or 1..8 hexadecimal digits {X..X} after \u")
    expecting_4_hexadecimal_digits:                   raise syntax 23.900 array(self~class~name "encoding: expecting 4 hexadecimal digits after \u, got '"codepoint"'")
    expecting_8_hexadecimal_digits:                   raise syntax 23.900 array(self~class~name "encoding: expecting 8 hexadecimal digits after \U, got '"codepoint"'")
    expecting_sequence_of_hexadecimal_digits:         raise syntax 23.900 array(self~class~name "encoding: expecting 1..n hexadecimal digits {X..X} after \x")
    unsupported_escape_character:                     raise syntax 23.900 array(self~class~name "encoding: escape character '"character"' not supported")


/******************************************************************************/
::class "Byte_Encoding" public inherit Byte_CommonServices IndexerStringInterface StringIndexer

::constant name "Byte"
::constant isByte 1
::constant codeUnitSizeInBytes 1
::constant codepointMaxBytes 1


::method analyze class
    use strict arg string /* or buffer */
    sizeB = string~length -- size in bytes
    case = 0
    if string~datatype("L") then case = 1
    if case == 0,  string~datatype("U") then case = 2
    -- Bytes, codepoints and graphemes are identical
    -- The string holds all the needed informations, no need to calculate indexes
    -- The maximum codepoint is not calculated: -1
    return self~new(string, -1, .nil, sizeB, .nil, sizeB, case, .nil)


::method checkCodepoint class
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange /*no impact here*/, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > 255 then signal error_range
    end
    return 1 -- a positive value means "no error"

    -- Don't use ppCodepoint here, it's not Unicode.
    error_range: return error(0, self~name "encoding: invalid codepoint" codepoint "("ppHexNumber(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..255")

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return .nil
    if sizeB == 1 then return string~subchar(startB)~c2d
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     encoding~decode(string, startB, encoding~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB=1
    if startB > string~length then return 0
    return 1


::method nextCodepointIndex class
    use strict arg string /* or buffer */, indexB
    if indexB > string~length then return indexB
    return indexB + 1


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    self~checkCodepoint(codepoint, checkOnlyRange:.true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(codepoint~d2c)
                      else return .RexxText~new(codepoint~d2c, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange:.true)
    return 1


::method codepointToLower class
    use strict arg codepoint
    if 65 <= codepoint, codepoint <= 90 then return codepoint + 32
    return codepoint


::method codepointToUpper class
    use strict arg codepoint
    if 97 <= codepoint, codepoint <= 122 then return codepoint - 32
    return codepoint


::method tableTranscodingToUnicode class
    use strict arg -- none
    return .nil


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then indexC = self~codepointCount + 1
    return indexC


::method codepoint
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if decode then return self~string~subchar(startB)~c2d
              else return self~string~subchar(startB)


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then indexG = self~string~length + 1
    return indexG


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil <> buffer then return buffer~~append(self~string~subchar(startB))
                      else return .RexxText~new(self~string~subchar(startB), self~class)


::method maximumUnicodeCodepoint private
    -- Needed when converting to Unicode_Encoding (1st pass: get the maxium codepoint)
    -- Don't do any check, will be done by convertByteToUnicode (2nd pass)
    expose maximumUnicodeCodepoint -- cached
    use strict arg -- none
    if var("maximumUnicodeCodepoint") then return maximumUnicodeCodepoint
    maximumUnicodeCodepoint = 0
    tableTranscodingToUnicode = self~class~tableTranscodingToUnicode
    if .nil <> tableTranscodingToUnicode then do
        sizeC = self~codepointCount -- size in codepoints
        do i=1 to sizeC
            charcode = self~codepoint(i)
            codepoint = tableTranscodingToUnicode[charcode+1] -- bof bof... 1-based array
            -- An empty string means no mapping
            -- A negative codepoint means unused character with fallback mapping
            if codepoint <> "" then maximumUnicodeCodepoint = max(maximumUnicodeCodepoint, abs(codepoint))
        end
    end
    return maximumUnicodeCodepoint


::method convertByteToUnicode private
    use strict arg targetEncoding
    use strict named arg strict=.true, buffer(1)=.nil
    tableTranscodingToUnicode = self~class~tableTranscodingToUnicode
    if .nil <> tableTranscodingToUnicode then do
        sizeC = self~codepointCount -- size in codepoints
        returnBuffer = .nil <> buffer
        if .nil == buffer then buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
        do i=1 to sizeC
            charcode = self~codepoint(i)
            codepoint = tableTranscodingToUnicode[charcode+1] -- bof bof... 1-based array
            -- An empty string means no mapping
            -- A negative codepoint means unused character with fallback mapping
            if codepoint == "" | (codepoint < 0 & strict) then raise syntax 23.900 array(self~name "encoding: cannot convert" self~description(short:.true) "character" charcode "("charcode~d2x") at byte-position" i "to" targetEncoding~name)
            targetEncoding~encode(abs(codepoint), b: buffer)
        end
        if returnBuffer then return buffer
                        else return .RexxText~new(buffer~string, targetEncoding)
    end
    raise syntax 23.900 array(self~class~name "encoding: cannot convert" self~description(short:.true) "to" targetEncoding~name)


::method UTF8
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then do
        if .nil <> buffer then return buffer~~append(self~string)
        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        return .RexxText~new(.String~new(self~string), .UTF8_Encoding)
    end
    else do
        return self~convertByteToUnicode(.UTF8_Encoding, strict: strict, b: buffer)
    end


::method WTF8
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then do
        if .nil <> buffer then return buffer~~append(self~string)
        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        return .RexxText~new(.String~new(self~string), .WTF8_Encoding)
    end
    else do
        return self~convertByteToUnicode(.WTF8_Encoding, strict: strict, b: buffer)
    end


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then return .UTF16BE_Encoding~encodeASCIIstring(self~string, b: buffer)
                           else return self~convertByteToUnicode(.UTF16BE_Encoding, strict: strict, b: buffer)


::method UTF16LE
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then return .UTF16LE_Encoding~encodeASCIIstring(self~string, b: buffer)
                           else return self~convertByteToUnicode(.UTF16LE_Encoding, strict: strict, b: buffer)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then return .WTF16BE_Encoding~encodeASCIIstring(self~string, b: buffer)
                           else return self~convertByteToUnicode(.WTF16BE_Encoding, strict: strict, b: buffer)


::method WTF16LE
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then return .WTF16LE_Encoding~encodeASCIIstring(self~string, b:buffer)
                           else return self~convertByteToUnicode(.WTF16LE_Encoding, strict: strict, b: buffer)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then return .UTF32BE_Encoding~encodeASCIIstring(self~string, b: buffer)
                           else return self~convertByteToUnicode(.UTF32BE_Encoding, strict: strict, b: buffer)


::method UTF32LE
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then return .UTF32LE_Encoding~encodeASCIIstring(self~string, b: buffer)
                           else return self~convertByteToUnicode(.UTF32LE_Encoding, strict: strict, b: buffer)


::method Unicode
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then do
        if .nil <> buffer then return buffer~~append(self~string)
        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        return .RexxText~new(.String~new(self~string), .Unicode8_Encoding)
    end
    else do
        targetEncoding = .Unicode_Encoding~toSupport(self~maximumUnicodeCodepoint)
        return self~convertByteToUnicode(targetEncoding, strict: strict, b: buffer)
    end


::method Unicode8
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then do
        if .nil <> buffer then return buffer~~append(self~string)
        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        return .RexxText~new(.String~new(self~string), .Unicode8_Encoding)
    end
    else return self~convertByteToUnicode(.Unicode8_Encoding, strict: strict, b: buffer)


::method Unicode16
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then return .Unicode16_Encoding~encodeASCIIstring(self~string, b: buffer)
                           else return self~convertByteToUnicode(.Unicode16_Encoding, strict: strict, b: buffer)


::method Unicode32
    use strict named arg strict=.true, buffer(1)=.nil
    if self~string~isASCII then return .Unicode32_Encoding~encodeASCIIstring(self~string, b: buffer)
                           else return self~convertByteToUnicode(.Unicode32_Encoding, strict: strict, b: buffer)


/******************************************************************************/
::class "CP1252_Encoding" subclass Byte_Encoding public
-- alias Window-1252

::constant name "CP1252"


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

::constant isUnicode 1


::method analyze class
    forward message "createIndexer"


::method createIndexer class
    use strict arg string
    maximumCodepoint = 0
    codepointIndexes = .array~new -- sparse array: only the string indexes different from the array index are stored
    graphemeIndexes = .array~new -- idem
    codepointCount = 0
    graphemeCount = 0
    errors = .nil
    indexB = 1
    previousCodepoint = .nil
    previousCodepointIndexB = .nil
    graphemeBreakArgs = (.nil, .nil, 0) -- codepoint1, codepoint2, state. Will use the same array at each iteration.
    case = 3 -- bitor(2,1) both isUpper isLower

    encoding = self
    errorInfo = .array~new(1) -- simulate a variable reference: errorInfo[1] = errorMessage
    forever:
        codepoint = .nil
        nextB = encoding~nextCodepointIndex(string, indexB, errorInfo: errorInfo)
        if nextB < 0 then signal error
        codepoint = encoding~decode(string, indexB, nextB - indexB) -- codepoint can be .nil if nextB == indexB

        -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
        checkResult = encoding~checkCodepoint(codepoint, indexB, previousCodepoint, previousCodepointIndexB, errorInfo: errorInfo)
        if checkResult == -1 then do
            -- The byte-sequence starting at previousCodepointIndexB is invalid,
            -- undo the last index
            -- currently, that can happen only for WTF-8 in case of high-surrogate followed by a low-surrogate
            codepointCount -= 1
            graphemeCount -= 1
            indexB = previousCodepointIndexB
            nextB = indexB + self~codeUnitSizeInBytes -- add 1 or 2 or 4
            signal error
        end
        else if checkResult == 0 then do
            -- The byte-sequence starting at indexB is invalid,
            nextB = indexB + self~codeUnitSizeInBytes -- add 1 or 2 or 4
            signal error
        end

        -- From here, we know that the current codepoint is valid
        if .nil == codepoint then signal leave -- End of string
        call indexCodepoint
        if .nil == previousCodepoint then call indexGrapheme -- First codepoint
        else if previousCodepoint < 0 then call indexGrapheme -- Error recovery
        else do
            graphemeBreakArgs[1] = previousCodepoint
            graphemeBreakArgs[2] = codepoint
            if .Unicode~graphemeBreak(graphemeBreakArgs) then call indexGrapheme
        end
        call checkCase
        previousCodepoint = codepoint
        previousCodepointIndexB = indexB
        indexB = nextB
    signal forever
    leave:

    -- Optimization if no need of indexes (when direct access is possible)
    if codepointIndexes~size == 0 then codepointIndexes = .nil
    if graphemeIndexes~size == 0 then graphemeIndexes = .nil
    return encoding~new(string, maximumCodepoint, codepointIndexes, codepointCount, graphemeIndexes, graphemeCount, case, errors)

    /*
        No need to store the string indexes which can be calculated from the array index.
        All the string indexes below can be calculated:
        index   UTF-8   UTF-16  UTF-32
          1       1       1       1
          2       2       3       5
          3       3       5       9
          ...
    */
    indexCodepoint:
        codepointCount += 1
        if indexB <> self~codeUnitSizeInBytes * (codepointCount -1) + 1 then do
            codepointIndexes[codepointCount] = indexB
        end
        maximumCodepoint = max(maximumCodepoint, codepoint)
        return

    indexGrapheme:
        graphemeCount += 1
        if indexB <> self~codeUnitSizeInBytes * (graphemeCount -1) + 1 then do
            graphemeIndexes[graphemeCount] = indexB
        end
        return

    checkCase:
        if case <> 0 then do
            if case == 1, \.Unicode~codepointIsLower(codepoint) then case = 0
            else if case == 2, \.Unicode~codepointIsUpper(codepoint) then case = 0
            else do -- case == 3
                if .Unicode~codepointIsLower(codepoint) then case = 1 -- can no longer be upper
                else if .Unicode~codepointIsUpper(codepoint) then case = 2 -- can no longer be lower
                else case = 0 -- can no longer be lower or upper
            end
        end
        return

    error:
        if .nil == errors then errors = .array~new
        errors~append(errorInfo[1])
        -- follow the recommendation of W3C : U+FFFD Substitution of Maximal Subparts
        nextB = abs(nextB)
        codepointCount += 1
        codepointIndexes[codepointCount] = -indexB -- a negative index means "error", a replacement character will be returned
        maximumCodepoint = max(maximumCodepoint, .Unicode~replacementCharacter~codepoint)
        graphemeCount += 1
        graphemeIndexes[graphemeCount] = -indexB -- idem
        graphemeBreakArgs[3] = 0 -- reset the extended grapheme state
        previousCodepoint = codepoint
        if .nil <> codepoint then previousCodepoint = -codepoint -- Negative codepoint allows to get the original value, if needed, while knowing it's invalid
        previousCodepointIndexB = indexB
        indexB = nextB -- resume at the next valid code unit
        signal forever


::method codepointToLower class
    use strict arg codepoint
    return .Unicode~codepointToLower(codepoint)


::method codepointToUpper class
    use strict arg codepoint
    return .Unicode~codepointToUpper(codepoint)


/********************/
/* Instance methods */
/********************/

::method convertUnicodeToUnicode
    /*
    D93 Encoding form conversion:
    A conversion defined directly between the code unit sequences of one Unicode
    encoding form and the code unit sequences of another Unicode encoding form.
    - In implementations of the Unicode Standard, a typical API will logically
      convert the input code unit sequence into Unicode scalar values (code points)
      and then convert those Unicode scalar values into the output code unit sequence.
      Proper analysis of the encoding forms makes it possible to convert the code units
      directly, thereby obtaining the same results but with a more efficient process.
    - A conformant encoding form conversion will treat any ill-formed code unit
      sequence as an error condition. (See conformance clause C10.) This guarantees
      that it will neither interpret nor emit an ill-formed code unit sequence.
      Any implementation of encoding form conversion must take this requirement
      into account, because an encoding form conversion implicitly involves a
      verification that the Unicode strings being converted do, in fact, contain
      well-formed code unit sequences.
    */
    use strict arg targetEncoding
    use strict named arg buffer(1)=.nil
    if self~class == targetEncoding then do
        if .nil <> buffer then return buffer~~append(self~string)
                          else return self~string~text
    end
    sizeC = self~codepointCount -- size in codepoints
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        targetEncoding~encode(codepoint, b: buffer)
    end
    if returnBuffer then return buffer
                      else return .RexxText~new(buffer~string, targetEncoding)


::method UTF8
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF8_Encoding, b: buffer)


::method WTF8
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return self~convertUnicodeToUnicode(.WTF8_Encoding, b: buffer)


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF16BE_Encoding, b: buffer)


::method UTF16LE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF16LE_Encoding, b: buffer)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return self~convertUnicodeToUnicode(.WTF16BE_Encoding, b: buffer)


::method WTF16LE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return self~convertUnicodeToUnicode(.WTF16LE_Encoding, b: buffer)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF32BE_Encoding, b: buffer)


::method UTF32LE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF32LE_Encoding, b: buffer)


::method Unicode
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    targetEncoding = .Unicode_Encoding~toSupport(self~maximumCodepoint)
    return self~convertUnicodeToUnicode(targetEncoding, b: buffer)


::method Unicode8
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    .Unicode8_Encoding~checkCodepoint(self~maximumCodepoint, checkingMaximumCodepoint:.true)
    return self~convertUnicodeToUnicode(.Unicode8_Encoding, b: buffer)


::method Unicode16
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    .Unicode16_Encoding~checkCodepoint(self~maximumCodepoint, checkingMaximumCodepoint:.true)
    return self~convertUnicodeToUnicode(.Unicode16_Encoding, b: buffer)


::method Unicode32
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    .Unicode32_Encoding~checkCodepoint(self~maximumCodepoint, checkingMaximumCodepoint:.true)
    return self~convertUnicodeToUnicode(.Unicode32_Encoding, b: buffer)


/******************************************************************************/
::class "XTF8_CommonServices" mixinclass Object private
-- where X stands for U or W

::constant codeUnitSizeInBytes 1
::constant codepointMaxBytes 4 -- In UTF-8, a codepoint can be from 1 to 4 bytes


/*
::method analyze class
    use strict arg string
    -- Bad idea! Must always analyze because CR+LF is a grapheme.
    -- sizeB = string~length -- size in bytes
    -- if string~isASCII then return self~new(string, .nil, sizeB, .nil, sizeB) -- no indexation needed
    return self~createIndexer(string)
*/


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    -- numeric digits 10 -- not needed, the greatest possible value is .utf8_encoding~decode("FF FF FF FF"x, 1, 4) = 2 097 151 (7 digits)
    if sizeB == 0 then return .nil -- end of string
    if sizeB == 1 then return decodeByte(0, "7F"x)
    if sizeB == 2 then return decodeByte(0, "1F"x)  *     64 + decodeByte(1, "3F"x)
    if sizeB == 3 then return decodeByte(0, "0F"x)  *   4096 + decodeByte(1, "3F"x) *   64 +  + decodeByte(2, "3F"x)
    if sizeB == 4 then return decodeByte(0, "07"x)  * 262144 + decodeByte(1, "3F"x) * 4096 +  + decodeByte(2, "3F"x) * 64 + decodeByte(3, "3F"x)
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")

    decodeByte: procedure expose string startB
        use strict arg offset, mask
        return string~subchar(startB + offset)~bitand(mask)~c2d


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     encoding~decode(string, startB, encoding~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    -- CAREFUL! The returned size can be different from the size that would be derived from nextCodepointIndex
    use strict arg string /* or buffer */, startB=1
    startByte = string~subchar(startB)
    if startByte == "" then return 0
    if startByte < "80"x then return 1                     -- 1-byte sequence 0xxxxxxx
    else if startByte~bitand("E0"x) == "C0"x then return 2 -- 2-byte sequence 110xxxxx (C0..DF but only C2..DF is valid)
    else if startByte~bitand("F0"x) == "E0"x then return 3 -- 3-byte sequence 1110xxxx
    else if startByte~bitand("F8"x) == "F0"x then return 4 -- 4-byte sequence 11110xxx
    return -1


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

        Also, every byte of a sequence that would correspond to a surrogate code
        point,or of a truncated version thereof, is replaced with one U+FFFD, as
        shown in Table 3-9. (The interpretation of such byte sequences has been
        forbidden since Unicode 3.2.)
            Table 3-9. U+FFFD for Ill-Formed Sequences for Surrogates
            Bytes  ED   A0   80   ED   BF   BF   ED   AF   41
            Output FFFD FFFD FFFD FFFD FFFD FFFD FFFD FFFD 0041

        Finally, every byte of a sequence that would correspond to a code point
        beyond U+10FFFF, and any other byte that does not contribute to a valid
        sequence, is also replaced with one U+FFFD, as shown in Table 3-10
            Table 3-10. U+FFFD for Other Ill-Formed Sequences
            Bytes  F4   91   92   93   FF   41   80   BF   42
            Output FFFD FFFD FFFD FFFD FFFD 0041 FFFD FFFD 0042

        Only when a sequence of two or three bytes is a truncated version of a
        sequence which is otherwise well-formed to that point, is more than one
        byte replaced with a single U+FFFD, as shown in Table 3-11.
            Table 3-11. U+FFFD for Truncated Sequences
            Bytes  E1   80   E2   F0   91 92 F1 BF 41
            Output FFFD      FFFD FFFD       FFFD  0041
    */
    use strict arg string /* or buffer */, startB
    use strict named arg errorInfo=.nil, raiseError=.true
    indexB = startB
    startByte = string~subchar(indexB)
    if startByte == "" then return indexB
    if startByte < "80"x then byteCount = 1                     -- 1-byte sequence 0xxxxxxx
    else if startByte < "C2"x then signal start_non_shortest_form
    else if startByte > "F4"x then signal start_error_range
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

    invalid_start_byte:
        nextCodepointIndex = startB + 1
        if raiseError then call error "UTF-8 sequence at byte-position" startB "has an invalid start byte" startByte~c2d "("ppHexNumber(startByte~c2d)")"
        return -nextCodepointIndex -- negative value means error

    start_non_shortest_form:
        nextCodepointIndex = startB + 1
        if raiseError then call error "UTF-8 sequence at byte-position" startB "has an invalid start byte" startByte~c2d "("ppHexNumber(startByte~c2d)") (non-shortest form)"
        return -nextCodepointIndex -- negative value means error

    start_error_range:
        nextCodepointIndex = startB + 1
        if raiseError then call error "UTF-8 sequence at byte-position" startB "has an invalid start byte" startByte~c2d "("ppHexNumber(startByte~c2d)") (codepoint > U+".Unicode~maxCodepoint~d2x")"
        return -nextCodepointIndex -- negative value means error

    invalid_continuation_byte:
        nextCodepointIndex = indexB
        if raiseError then call error "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB
        return -nextCodepointIndex -- negative value means error

    non_shortest_form:
        nextCodepointIndex = indexB
        if raiseError then call error "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(non-shortest form)"
        return -nextCodepointIndex -- negative value means error

    high_surrogate:
        nextCodepointIndex = indexB
        if raiseError then call error "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(high surrogate)"
        return -nextCodepointIndex -- negative value means error

    low_surrogate:
        nextCodepointIndex = indexB
        if raiseError then call error "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(low surrogate)"
        return -nextCodepointIndex -- negative value means error

    error_range:
        nextCodepointIndex = indexB
        if raiseError then call error "UTF-8 sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(codepoint > U+".Unicode~maxCodepoint~d2x")"
        return -nextCodepointIndex -- negative value means error

    truncated:
        nextCodepointIndex = indexB
        if raiseError then call error "UTF-8 sequence at byte-position" startB "is truncated, expected" byteCount "bytes"
        return -nextCodepointIndex -- negative value means error

    error:
        use strict arg errorMessage
        if .nil <> errorInfo then errorInfo[1] = errorMessage"."
                             else raise syntax 23.900 array (errorMessage)
        return

-- utf8proc_ssize_t utf8proc_encode_char(utf8proc_int32_t codepoint, utf8proc_uint8_t *dst);
::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, self~codepointMaxBytes)
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
    else if codepoint <= .Unicode~maxCodepoint then do             -- } else if (uc < 0x110000) {
        buffer~append((240 + codepoint % 262144)~d2c)               -- dst[0] = (utf8proc_uint8_t)(0xF0 + (uc >> 18));
        buffer~append((128 + (codepoint % 4096) // 64)~d2c)         -- dst[1] = (utf8proc_uint8_t)(0x80 + ((uc >> 12) & 0x3F));
        buffer~append((128 + (codepoint % 64) // 64)~d2c)           -- dst[2] = (utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
        buffer~append((128 + codepoint // 64)~d2c)                  -- dst[3] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    end                                                             -- return 4;
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange:.true)
    if codepoint < 128 then return 1
    if codepoint < 2048 then return 2
    if codepoint < 65536 then return 3
    return 4


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return indexC
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return indexC -- sparse array: the value is equal to the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes, self~codepointCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last codepoint can be more than one byte.
        if decode then return self~string~subchar(startB)~c2d
                  else return self~string~subchar(startB)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return indexG
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return indexG -- sparse array: the value is equal to the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint.
        if .nil <> buffer then return buffer~~append(self~string~subchar(indexG))
                          else return .RexxText~new(self~string~subchar(indexG), self~class)
    end
    startB = self~graphemeIndex(indexG)
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


::method UTF8
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if self~class~isUTF8 then do
        if .nil <> buffer then return buffer~~append(self~string)
                          else return self~string~text
    end
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if .nil <> buffer then return buffer~~append(self~string) -- TODO is it correct? there is no check here. WTF8 converted to UTF8 could raise errors.
                      else return .RexxText~new(.String~new(self~string), .UTF8_Encoding)


::method WTF8
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if self~class~isWTF8 then do
        if .nil <> buffer then return buffer~~append(self~string)
                          else return self~string~text
    end
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if .nil <> buffer then return buffer~~append(self~string) -- TODO is it correct?
                      else return .RexxText~new(.String~new(self~string), .WTF8_Encoding)


::method Unicode
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if self~class~isUnicodeN then do
        if .nil <> buffer then return buffer~~append(self~string)
                          else return self~string~text
    end
    if self~string~isASCII then do
        if .nil <> buffer then return buffer~~append(self~string)
        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        return .RexxText~new(.String~new(self~string), .Unicode8_Encoding)
    end
    forward class (super)


/******************************************************************************/
::class "UTF8_Encoding" public inherit Byte_CommonServices XTF8_CommonServices Unicode_CommonServices IndexerStringInterface StringIndexer

::constant name "UTF-8"
::constant isUTF8 1
::constant BOM "EF BB BF"x


::method checkCodepoint class
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
        if checkOnlyRange then return 1 -- a positive value means "no error"
        if codepoint >= 55296 & codepoint < 56320 then signal error_high_surrogate -- U+D800 to U+DBFF high surrogates
        if codepoint >= 56320 & codepoint < 57344 then signal error_low_surrogate  -- U+DC00 to U+DFFF low surrogates
    end
    return 1 -- a positive value means "no error"

    -- Every byte of the byte-sequence must be considered as invalid,
    -- and must not be consumed, except the first byte.
    -- The 2nd byte will be a new start byte.
    error_range:          return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
    error_high_surrogate: return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". High surrogate is not allowed")
    error_low_surrogate:  return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Low surrogate is not allowed")

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


/******************************************************************************/
::class "WTF8_Encoding" public inherit Byte_CommonServices XTF8_CommonServices Unicode_CommonServices IndexerStringInterface StringIndexer
/*
https://simonsapin.github.io/wtf-8/#16-bit-code-unit
WTF-8 (Wobbly Transformation Format − 8-bit) is a superset of UTF-8 that encodes
surrogate code points if they are not in a pair.
It represents, in a way compatible with UTF-8, text from systems such as
JavaScript and Windows that use UTF-16 internally but don’t enforce the
well-formedness invariant that surrogates must be paired.

To convert lossily from WTF-8 to UTF-8, replace any surrogate byte sequence with
the sequence of three bytes <0xEF, 0xBF, 0xBD>, the UTF-8 encoding of the
replacement character.
Note: Since surrogate byte sequences are also three bytes long, this conversion
can be done in place.
Note: This conversion never fails but is lossy.

To convert strictly from WTF-8 to UTF-8, run these steps:
If the input contains a surrogate byte sequence, return failure.
Otherwise, return the input unchanged.

Concatenating WTF-8 strings requires extra care to preserve well-formedness.
*/

::constant name "WTF-8"
--::constant isUTF8 1 -- WTF8 is not UTF8
::constant isWTF8 1
::constant BOM "EF BB BF"x


::method checkCodepoint class
    /*
    http://simonsapin.github.io/wtf-8/
    If the input contains a surrogate code point pair, the conversion will be
    incorrect and the resulting sequence will not represent the original code points.
    This situation should be considered an error, but this specification does not
    define how to handle it. Possibilities include aborting the conversion, or
    replacing one of the surrogate code points of the pair with a replacement character.
    */
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil
    -- say "WTF-8 checkCodepoint: codepoint="codepoint", previousCodepoint="previousCodepoint -- todo: remove
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
        if checkOnlyRange then return 1 -- a positive value means "no error"
        if .nil <> previousCodepoint then do
            previousCodePointIsInvalid = (previousCodepoint < 0)
            previousCodepoint = abs(previousCodepoint)
            previousCodepointIsHighSurrogate = (previousCodepoint >= 55296 & previousCodepoint < 56320) -- U+D800 to U+DBFF high surrogates
            codepointIsLowSurrogate = (codepoint >= 56320 & codepoint < 57344)                          -- U+DC00 to U+DFFF low surrogates
            if previousCodepointIsHighSurrogate & codepointIsLowSurrogate then do
                if previousCodePointIsInvalid then signal error_low_surrogate_preceded_by_high_surrogate
                                              else signal error_high_surrogate_followed_by_low_surrogate
            end
        end
    end
    return 1 -- a positive value means "no error"

    error_range:                                    return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
    error_high_surrogate_followed_by_low_surrogate: return error(-1, self~name "encoding: high surrogate" previousCodepoint "("ppCodepoint(previousCodepoint)")" || atBytePosition(previousCodepointIndexB) || " followed by low surrogate" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || " is not allowed")
    error_low_surrogate_preceded_by_high_surrogate: return error(0, self~name "encoding: low surrogate" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || " preceded by high surrogate" previousCodepoint "("ppCodepoint(previousCodepoint)")" || atBytePosition(previousCodepointIndexB) || " is not allowed")

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


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
    use strict arg string
    use strict named arg buffer(1)
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
                self~encode(surrogate, b: buffer)
                return
            end
        end
    end
    buffer~append(string)


/******************************************************************************/
::class "XTF16_CommonServices" mixinclass Object private
-- where X stands for U or W

::constant codeUnitSizeInBytes 2
::constant codepointMaxBytes 4  -- In UTF-16, a codepoint can be 2 or 4 bytes


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    -- numeric digits 10 not needed, the greatest possible value is .utf16be_encoding~decode("FF FF FF FF"x, 1, 4) = 10 559 487 (8 digits)
    if sizeB == 0 then return .nil
    if sizeB == 2 then return self~decodeCodepoint(string~substr(startB, 2))
    if sizeB == 4 then do
        high_surrogate = self~decodeCodepoint(string~substr(startB, 2))
        low_surrogate = self~decodeCodepoint(string~substr(startB + 2, 2))
        h = (high_surrogate - 55296) * 1024 -- Take the high surrogate and subtract 0xD800, then multiply by 0x400
        l = low_surrogate - 56320 -- Take the low surrogate and subtract 0xDC00
        return h + l + 65536 -- Add these two results together, and finally add 0x10000
    end
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a size to ~decode, the checks are disabled, and that allows to get a codepoint even when ill-formed.
    use strict arg string /* or buffer */, startB=1
    wobbly = self~isWTF16
    indexB = startB
    lengthB = string~length
    if indexB > lengthB then return 0 -- end of string
    if lengthB - indexB < 1 then return -1 -- truncated
    codeUnit = self~codeUnitBE(string~substr(indexB, 2)) -- yes! always codeUnitBE, works for BE and LE
    indexB += 2
    if codeUnit >= "D800"x & codeUnit <= "DBFF"x then do
        -- got high surrogate, get low surrogate
        if indexB > lengthB then do -- end of string
            if wobbly then return 2
                      else return -1
        end
        if lengthB - indexB < 1 then return -1 -- truncated
        codeUnit = self~codeUnitBE(string~substr(indexB, 2)) -- yes! always codeUnitBE, works for BE and LE
        if codeUnit >= "DC00"x & codeUnit <= "DFFF"x then return 4 -- this is a valid low surrogate
        else do
            -- no valid low surrogate but it's acceptable to consider the high
            -- surrogate as a standalone codepoint, when wobbly mode
            if wobbly then return 2
                      else return -1
        end
    end
    return 2


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use strict named arg errorInfo=.nil, raiseError=.true
    wobbly = self~isWTF16
    indexB = startB
    lengthB = string~length
    if indexB > lengthB then return indexB -- end of string
    if lengthB - indexB < 1 then signal truncated2
    -- yes! always codeUnitBE, works for BE and LE
    codeUnit = self~codeUnitBE(string~substr(indexB, 2)) -- Remember: don't optimize too much, I display this codepoint in case of error
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
        codeUnit = self~codeUnitBE(string~substr(indexB, 2)) -- yes! always codeUnitBE, works for BE and LE
        if codeUnit >= "DC00"x & codeUnit <= "DFFF"x then indexB += 2 -- this is a valid low surrogate
        else do
            -- no valid low surrogate but it's acceptable to consider the high
            -- surrogate as a standalone codepoint, when wobbly mode
            if wobbly then return indexB
                      else signal invalid_low_surrogate
        end
    end
    else if \wobbly, codeUnit >= "DC00"x & codeUnit <= "DFFF"x then signal unpaired_low_surrogate
    -- todo: add more checks ? could test the range (currently checked later by checkCodepoint)
    return indexB

    unpaired_high_surrogate:
        nextCodepointIndex = indexB
        if raiseError then call error self~name "encoding: unpaired high surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" startB
        return -nextCodepointIndex -- negative value means error

    unpaired_low_surrogate:
        nextCodepointIndex = indexB
        if raiseError then call error self~name "encoding: unpaired low surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" startB
        return -nextCodepointIndex -- negative value means error

   invalid_low_surrogate:
        nextCodepointIndex = indexB
        if raiseError then call error self~name "encoding: invalid low surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" indexB
        return -nextCodepointIndex -- negative value means error

    truncated2:
        nextCodepointIndex = indexB + 2
        if raiseError then call error self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 2 bytes"
        return -nextCodepointIndex -- negative value means error

    truncated4:
        nextCodepointIndex = indexB
        if raiseError then call error self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 4 bytes"
        return -nextCodepointIndex -- negative value means error

    error:
        use strict arg errorMessage
        if .nil <> errorInfo then errorInfo[1] = errorMessage"."
                             else raise syntax 23.900 array (errorMessage)
        return


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, self~codepointMaxBytes)
    self~checkCodepoint(codepoint, checkOnlyRange:.true) -- check only range, the other errors will be detected during analysis
    if codepoint < 55296 then do -- U+0000 to U+D7FF
        buffer~append(self~encodeCodepoint(codepoint))
    end
    else if codepoint < 65536 then do -- U+E000 to U+FFFF
        buffer~append(self~encodeCodepoint(codepoint))
    end
    else if codepoint <= .Unicode~maxCodepoint then do -- U+010000 to U+10FFFF
        buffer~append(self~encodeCodepoint(55296 + (codepoint - 65536) % 1024))     -- high surrogate: Subtract 0x10000, shift right by 10 (divide by 0x400), then add 0xD800
        buffer~append(self~encodeCodepoint(56320 + (codepoint - 65536) // 1024))    -- low surrogate: Subtract 0x10000, take the low 10 bits (remainder of dividing by 0x400), then add 0xDC0
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange:.true)
    if codepoint < 65536 then return 2
    return 4


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return 2 * (indexC - 1) + 1
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return 2 * (indexC - 1) + 1 -- sparse array: the value can be derived from the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes, self~codepointCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last codepoint can be 4 bytes.
        if decode then return self~class~decode(self~string, startB, 2)
                  else return self~string~substr(startB, 2)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return 2 * (indexG - 1) + 1
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return 2 * (indexG - 1) + 1 -- sparse array: the value can be derived from the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 2))
                          else return .RexxText~new(self~string~substr(startB, 2), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "XTF16BE_CommonServices" mixinclass Object private
-- where X stands for U or W

::method codeUnitBE class
    -- Ex : "B0FE"x --> "B0FE"x
    use strict arg codeUnit
    return codeUnit


::method decodeCodepoint class private
    use strict arg stringBytes
    -- numeric digits 10 -- not needed, the code unit is 2 bytes, never 4 bytes
    return stringBytes~c2d


::method encodeCodepoint class private
    use strict arg codepoint
    return codepoint~d2c(2)


::method encodeASCIIstring class
    use strict arg string
    use strict named arg buffer(1)=.nil
    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 2) -- yes, always 2, no need to use codepointMaxBytes
    do i=1 to sizeB
        buffer~append("00"x) -- big endian
        buffer~append(string~subchar(i))
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method UTF16BE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if self~class~isUTF16BE then do
        if .nil <> buffer then return buffer~~append(self~string)
        return self~string~text
    end
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if .nil <> buffer then return buffer~~append(self~string)
                      else return .RexxText~new(.String~new(self~string), .UTF16BE_Encoding)


::method WTF16BE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if self~class~isWTF16BE then do
        if .nil <> buffer then return buffer~~append(self~string)
        return self~string~text
    end
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if .nil <> buffer then return buffer~~append(self~string)
                      else return .RexxText~new(.String~new(self~string), .WTF16BE_Encoding)


/*
::method Unicode16
    -- todo: is there an optim possible here ?
*/


/******************************************************************************/
::class "XTF16LE_CommonServices" mixinclass Object private
-- where X stands for U or W

::method codeUnitBE class
    -- Ex : "FEB0"x --> "B0FE"x
    use strict arg codeUnit
    return codeUnit~reverse


::method decodeCodepoint class private
    use strict arg stringBytes
    -- numeric digits 10 -- not needed, the code unit is 2 bytes, never 4 bytes
    return stringBytes~reverse~c2d


::method encodeCodepoint class private
    use strict arg codepoint
    return codepoint~d2c(2)~reverse


::method encodeASCIIstring class
    use strict arg string
    use strict named arg buffer(1)=.nil
    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 2) -- yes, always 2, no need to use codepointMaxBytes
    do i=1 to sizeB
        buffer~append(string~subchar(i))
        buffer~append("00"x) -- little endian
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method UTF16LE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if self~class~isUTF16LE then do
        if .nil <> buffer then return buffer~~append(self~string)
                          else return self~string~text
    end
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if .nil <> buffer then return buffer~~append(self~string)
                      else return .RexxText~new(.String~new(self~string), .UTF16LE_Encoding)


::method WTF16LE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if self~class~isWTF16LE then do
        if .nil <> buffer then return buffer~~append(self~string)
                          else return self~string~text
    end
    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    if .nil <> buffer then return buffer~~append(self~string)
                      else return .RexxText~new(.String~new(self~string), .WTF16LE_Encoding)


/*
::method Unicode16
    -- todo: is there an optim possible here ?
*/


/******************************************************************************/
::class "UTF16_CommonServices" mixinclass Object private

::method checkCodepoint class
    /*
    Because surrogate code points are not Unicode scalar values, isolated UTF-16
    code units in the range D80016..DFFF16 are ill-formed.
    (this is also checked in nextCodepointIndex, only when not wobbly)
    */
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
        if checkOnlyRange then return 1 -- a positive value means "no error"
        if .nil <> previousCodepoint then do
               previousCodepointIsHighSurrogate = (previousCodepoint >= 55296 & previousCodepoint < 56320) -- U+D800 to U+DBFF high surrogates
               codepointIsLowSurrogate = (codepoint >= 56320 & codepoint < 57344)                          -- U+DC00 to U+DFFF low surrogates
               if previousCodepointIsHighSurrogate, \codepointIsLowSurrogate then signal unpaired_high_surrogate
               if \previousCodepointIsHighSurrogate, codepointIsLowSurrogate then signal unpaired_low_surrogate
        end
    end
    else do
        -- End of string
        if .nil <> previousCodepoint,,
           previousCodepoint >= 55296 & previousCodepoint < 56320,  -- U+D800 to U+DBFF high surrogates
        then signal unpaired_high_surrogate
    end
    return 1 -- a positive value means "no error"

    -- Every code unit of the byte-sequence must be considered as invalid,
    -- and must not be consumed, except the first code unit.
    -- The 2nd code unit will be the next code unit to analyze.
    error_range: return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
    unpaired_high_surrogate: return error(-1, self~name "encoding: unpaired high surrogate" previousCodepoint "("ppCodepoint(previousCodepoint)") at byte-position" previousCodepointIndexB)
    unpaired_low_surrogate:  return error(0, self~name "encoding: unpaired low surrogate" codepoint "("ppCodepoint(codepoint)") at byte-position" codepointIndexB)

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


/******************************************************************************/
::class "UTF16BE_Encoding" public inherit UTF16_CommonServices XTF16BE_CommonServices XTF16_CommonServices Unicode_CommonServices IndexerStringInterface StringIndexer

::constant name "UTF-16BE"
::constant isUTF16 1
::constant isUTF16BE 1
::constant BOM "FE FF"x


/******************************************************************************/
::class "UTF16LE_Encoding" public inherit UTF16_CommonServices XTF16LE_CommonServices XTF16_CommonServices Unicode_CommonServices IndexerStringInterface StringIndexer

::constant name "UTF-16LE"
::constant isUTF16 1
::constant isUTF16LE 1
::constant BOM "FF FE"x


/******************************************************************************/
::class "WTF16_CommonServices" mixinclass Object private

::method checkCodepoint class
    -- Isolated surrogates are ok, nothing to check regarding the surrogates
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false /*no impact here*/, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
    end
    return 1 -- a positive value means "no error"

    -- Every code unit of the byte-sequence must be considered as invalid,
    -- and must not be consumed, except the first code unit.
    -- The 2nd code unit will be the next code unit to analyze.
    error_range: return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


/******************************************************************************/
::class "WTF16BE_Encoding" public inherit WTF16_CommonServices XTF16BE_CommonServices XTF16_CommonServices Unicode_CommonServices IndexerStringInterface StringIndexer
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

::constant name "WTF-16BE"
--::constant isUTF16 1 -- WTF-16 is not UTF-16
--::constant isUTF16BE 1 -- WTF16-BE is not UTF-16BE
::constant isWTF16 1
::constant isWTF16BE 1
::constant BOM "FE FF"x


/******************************************************************************/
::class "WTF16LE_Encoding" public inherit WTF16_CommonServices XTF16LE_CommonServices XTF16_CommonServices Unicode_CommonServices IndexerStringInterface StringIndexer

::constant name "WTF-16LE"
--::constant isUTF16 1 -- WTF16 is not UTF16
--::constant isUTF16LE 1 -- WTF-16LE is not UTF-16LE
::constant isWTF16 1
::constant isWTF16LE 1
::constant BOM "FF FE"x


/******************************************************************************/
::class "UTF32_CommonServices" mixinclass Object private

::constant codeUnitSizeInBytes 4
::constant codepointMaxBytes 4 -- In UTF-32, a codepoint is 4 bytes


::method checkCodepoint class
    /*
    - Because surrogate code points are not included in the set of Unicode scalar values,
      UTF-32 code units in the range 0000D80016..0000DFFF16 are ill-formed.
    - Any UTF-32 code unit greater than 0010FFFF is ill-formed.
    */
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
        if checkOnlyRange then return 1 -- a positive value means "no error"
        if codepoint >= 55296 & codepoint < 56320 then signal error_high_surrogate -- U+D800 to U+DBFF high surrogates
        if codepoint >= 56320 & codepoint < 57344 then signal error_low_surrogate  -- U+DC00 to U+DFFF low surrogates
    end
    return 1 -- a positive value means "no error"

    error_range:          return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
    error_high_surrogate: return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". High surrogate is not allowed")
    error_low_surrogate:  return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Low surrogate is not allowed")

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    -- numeric digits 10 -- not needed here, managed by decodeCodepoint
    if sizeB == 0 then return .nil
    if sizeB == 4 then return self~decodeCodepoint(string~substr(startB, 4))
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB
    lengthB = string~length
    if startB > lengthB then return 0 -- end of string
    if lengthB - startB < 3 then return -1 -- truncated
    return 4


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use named arg errorInfo=.nil, raiseError=.true
    indexB = startB
    lengthB = string~length
    if indexB > lengthB then return indexB -- end of string
    if lengthB - indexB < 3 then signal truncated
    -- todo: add more checks ? could test the surrogates and the range (currently checked later by checkCodepoint)
    indexB += 4
    return indexB

    truncated:
        nextCodepointIndex = indexB + 4
        if raiseError then call error self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 4 bytes"
        return -nextCodepointIndex -- negative value means error

    error:
        use strict arg errorMessage
        if .nil <> errorInfo then errorInfo[1] = errorMessage"."
                             else raise syntax 23.900 array (errorMessage)
        return


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, 4) -- yes, always 4, no need to use codepointMaxBytes
    self~checkCodepoint(codepoint, checkOnlyRange:.true) -- check only range, the other errors will be detected during analysis
    buffer~append(self~encodeCodepoint(codepoint))
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange:.true)
    return 4


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return 4 * (indexC - 1) + 1
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return 4 * (indexC - 1) + 1 -- sparse array: the value can be derived from the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes then do
        -- This optimization is possible despite I no longer store the last index+1: the last codepoint is always 4 bytes.
        if decode then return self~class~decode(self~string, startB, 4)
                  else return self~string~substr(startB, 4)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return 4 * (indexG - 1) + 1
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return 4 * (indexG - 1) + 1 -- sparse array: the value can be derived from the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 4))
                          else return .RexxText~new(self~string~substr(startB, 4), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "UTF32BE_Encoding" public inherit UTF32_CommonServices Unicode_CommonServices IndexerStringInterface StringIndexer

::constant name "UTF-32BE"
::constant isUTF32 1
::constant isUTF32BE 1
::constant BOM "00 00 FE FF"x


::method decodeCodepoint class private
    use strict arg stringBytes
    -- precondition: stringBytes~length <= 4
    -- needed, the code unit is 4 bytes.
    -- "3B9A C9FF"x~c2d = 999 999 999. The next value raises an error when 9 digits.
    -- The maximum value is "FFFF FFFF"x~c2d = 4 294 967 295 (10 digits)
    numeric digits 10
    return stringBytes~c2d


::method encodeCodepoint class private
    use strict arg codepoint
    return codepoint~d2c(4)


::method encodeASCIIstring class
    use strict arg string
    use strict named arg buffer(1)=.nil
    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 4) -- yes, always 4, no need to use codepointMaxBytes
    do i=1 to sizeB
        buffer~append("000000"x) -- big endian
        buffer~append(string~subchar(i))
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method UTF32BE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if .nil <> buffer then return buffer~~append(self~string)
                      else return self~string~text


/*
::method Unicode32
    -- is there an optim possible here ?
*/


/******************************************************************************/
::class "UTF32LE_Encoding" public inherit UTF32_CommonServices Unicode_CommonServices IndexerStringInterface StringIndexer

::constant name "UTF-32LE"
::constant isUTF32 1
::constant isUTF32LE 1
::constant BOM "FF FE 00 00"x


::method decodeCodepoint class private
    use strict arg stringBytes
    -- precondition: stringBytes~length <= 4
    -- needed, the code unit is 4 bytes.
    -- "3B9A C9FF"x~c2d = 999 999 999. The next value raises an error when 9 digits.
    -- The maximum value is "FFFF FFFF"x~c2d = 4 294 967 295 (10 digits)
    numeric digits 10
    return stringBytes~reverse~c2d


::method encodeCodepoint class private
    use strict arg codepoint
    return codepoint~d2c(4)~reverse


::method encodeASCIIstring class
    use strict arg string
    use strict named arg buffer(1)=.nil
    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 4) -- yes, always 4, no need to use codepointMaxBytes
    do i=1 to sizeB
        buffer~append(string~subchar(i))
        buffer~append("000000"x) -- little endian
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method UTF32LE
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if .nil <> buffer then return buffer~~append(self~string)
                      else return self~string~text


/*
::method Unicode32
    -- todo: is there an optim possible here ?
*/


/******************************************************************************/
/*
Strings of codepoints encoded as native integers.
Support 3 representations, depending on the character with the largest Unicode codepoint (1, 2, or 4 bytes).
Unlike the flexible representation of Python, the 3 representions are first-class, not internal.
No BOM, the endiannes is the CPU one. This is for internal use only.
Unicode32_Encoding can be used with utf8proc for theses functions taking a 32-bit buffer:

    Decompose a codepoint into an array of codepoints.
    UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_decompose_char(
      utf8proc_int32_t codepoint, utf8proc_int32_t *dst, utf8proc_ssize_t bufsize,
      utf8proc_option_t options, int *last_boundclass
    );

    The same as @ref utf8proc_decompose_char, but acts on a whole UTF-8
    string and orders the decomposed sequences correctly.
    UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_decompose(
      const utf8proc_uint8_t *str, utf8proc_ssize_t strlen,
      utf8proc_int32_t *buffer, utf8proc_ssize_t bufsize, utf8proc_option_t options
    );

    Normalizes the sequence of `length` codepoints pointed to by `buffer`
    in-place (i.e., the result is also stored in `buffer`).
    UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_normalize_utf32(
      utf8proc_int32_t *buffer, utf8proc_ssize_t length, utf8proc_option_t options);

    Reencodes the sequence of `length` codepoints pointed to by `buffer`
    UTF-8 data in-place (i.e., the result is also stored in `buffer`).
    Can optionally normalize the UTF-32 sequence prior to UTF-8 conversion.
    UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_reencode(
      utf8proc_int32_t *buffer, utf8proc_ssize_t length, utf8proc_option_t options);
*/
::class "Unicode_Encoding" mixinclass Object private

::method activate class
    expose isLittleEndian
    isLittleEndian = .Unicode~systemIsLittleEndian -- cache the value for faster access


::method isUnicodeN class
    use strict arg -- none
    return .true


::method toSupport class
    use strict arg codepoint
    if codepoint < 256 then return .Unicode8_Encoding
    if codepoint < 65536 then return .Unicode16_Encoding
    return .Unicode32_Encoding


::method decodeCodepoint class private
    expose isLittleEndian
    -- Will reach this method only once.
    -- After the first call, the message "decodeCodepoint" will be sent directly to the method specialized for this endianness
    if isLittleEndian then self~setMethod("decodeCodepoint", self~instanceMethod("decodeCodepointLE"), "Object")
                      else self~setMethod("decodeCodepoint", self~instanceMethod("decodeCodepointBE"), "Object")
    forward message "decodeCodepoint"


::method decodeCodepointBE class private
    use strict arg stringBytes
    -- precondition: stringBytes~length <= 4
    -- needed, the code unit is from 1 to 4 bytes.
    -- "3B9A C9FF"x~c2d = 999 999 999. The next value raises an error when 9 digits.
    -- The maximum value is "FFFF FFFF"x~c2d = 4 294 967 295 (10 digits)
    numeric digits 10
    return stringBytes~c2d


::method decodeCodepointLE class private
    use strict arg stringBytes
    -- precondition: stringBytes~length <= 4
    -- needed, the code unit is from 1 to 4 bytes.
    -- "3B9A C9FF"x~c2d = 999 999 999. The next value raises an error when 9 digits.
    -- The maximum value is "FFFF FFFF"x~c2d = 4 294 967 295 (10 digits)
    numeric digits 10
    return stringBytes~reverse~c2d


::method encodeCodepoint class private
    expose isLittleEndian
    -- Will reach this method only once.
    -- After the first call, the message "encodeCodepoint" will be sent directly to the method specialized for this endianness
    if isLittleEndian then self~setMethod("encodeCodepoint", self~instanceMethod("encodeCodepointLE"), "Object")
                      else self~setMethod("encodeCodepoint", self~instanceMethod("encodeCodepointBE"), "Object")
    forward message "encodeCodepoint"


::method encodeCodepointBE class private
    use strict arg codepoint
    return codepoint~d2c(self~codeUnitSizeInBytes)


::method encodeCodepointLE class private
    use strict arg codepoint
    return codepoint~d2c(self~codeUnitSizeInBytes)~reverse


/********************/
/* Instance methods */
/********************/

::method Unicode
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    if .nil <> buffer then return buffer~~append(self~string)
                      else return self~string~text


/******************************************************************************/
::class "Unicode8_Encoding" public inherit Unicode_Encoding Unicode_CommonServices IndexerStringInterface StringIndexer

::constant name "Unicode8"
::constant isUnicode8 1
::constant codeUnitSizeInBytes 1
::constant codepointMaxBytes 1


::method checkCodepoint class
    -- All the codepoints in the range 0..255 are ok
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false /*no impact here*/, errorInfo=.nil, checkingMaximumCodepoint=.false
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > 255 then signal error_range
    end
    return 1 -- a positive value means "no error"

    error_range: if checkingMaximumCodepoint then return error(0, self~name "encoding: invalid maximum codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..255")
                                             else return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..255")

    error:
        use strict arg whichCodepoint, errorMessage
        -- Ignore the argument errorInfo. If the codepoint is out of range then raise immediatly an error.
        -- I don't want to have thousands of errors recorded because someone try to get a Unicode8 string from a string containing thousands codepoint > 255.
        if .false then do -- .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return .nil
    if sizeB == 1 then return string~subchar(startB)~c2d
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB
    lengthB = string~length
    if startB > lengthB then return 0 -- end of string
    return 1


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    lengthB = string~length
    if startB > lengthB then return startB -- end of string
    return startB + 1


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    self~checkCodepoint(codepoint, checkOnlyRange:.true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(codepoint~d2c)
                      else return .RexxText~new(codepoint~d2c, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange:.true)
    return 1


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then indexC = self~codepointCount + 1
    return indexC


::method codepoint
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if decode then return self~string~subchar(startB)~c2d
              else return self~string~subchar(startB)


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return indexG
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return indexG -- sparse array: the value is equal to the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint.
        if .nil <> buffer then return buffer~~append(self~string~subchar(indexG))
                          else return .RexxText~new(self~string~subchar(indexG), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "Unicode16_Encoding" public inherit Unicode_Encoding Unicode_CommonServices IndexerStringInterface StringIndexer

::constant name "Unicode16"
::constant isUnicode16 1
::constant codeUnitSizeInBytes 2
::constant codepointMaxBytes 2


::method checkCodepoint class
    -- Isolated surrogates are ok, nothing to check regarding the surrogates
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false /*no impact here*/, errorInfo=.nil, checkingMaximumCodepoint=.false
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > 65535 then signal error_range
    end
    return 1 -- a positive value means "no error"

    error_range: if checkingMaximumCodepoint then return error(0, self~name "encoding: invalid maximum codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..65535")
                                             else return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..65535")

    error:
        use strict arg whichCodepoint, errorMessage
        -- Ignore the argument errorInfo. If the codepoint is out of range then raise immediatly an error.
        -- I don't want to have thousands of errors recorded because someone try to get a Unicode8 string from a string containing thousands codepoint > 255.
        if .false then do -- .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    if sizeB == 0 then return .nil
    if sizeB == 2 then return self~decodeCodepoint(string~substr(startB, 2))
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB
    lengthB = string~length
    if startB > lengthB then return 0 -- end of string
    if lengthB - startB < 1 then return -1 -- truncated
    return 2


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use named arg errorInfo=.nil, raiseError=.true
    indexB = startB
    lengthB = string~length
    if indexB > lengthB then return indexB -- end of string
    if lengthB - indexB < 1 then signal truncated
    return indexB + 2

    truncated:
        nextCodepointIndex = indexB + 2
        if raiseError then call error self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 2 bytes"
        return -nextCodepointIndex -- negative value means error

    error:
        use strict arg errorMessage
        if .nil <> errorInfo then errorInfo[1] = errorMessage"."
                             else raise syntax 23.900 array (errorMessage)
        return


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    self~checkCodepoint(codepoint, checkOnlyRange:.true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(self~encodeCodepoint(codepoint))
                      else return .RexxText~new(self~encodeCodepoint(codepoint), self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange:.true)
    return 2


::method encodeASCIIstring class
    expose isLittleEndian
    use strict arg string
    use strict named arg buffer(1)=.nil
    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 2)
    if isLittleEndian then do
        loop i=1 to sizeB
            buffer~append(string~subchar(i))
            buffer~append("00"x) -- little endian
        end
    end
    else do
        loop i=1 to sizeB
            buffer~append("00"x) -- big endian
            buffer~append(string~subchar(i))
        end
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return 2 * (indexC - 1) + 1
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return 2 * (indexC - 1) + 1 -- sparse array: the value can be derived from the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes, self~codepointCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last codepoint can be 4 bytes.
        if decode then return self~class~decode(self~string, startB, 2)
                  else return self~string~substr(startB, 2)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return 2 * (indexG - 1) + 1
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return 2 * (indexG - 1) + 1 -- sparse array: the value can be derived from the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 2))
                          else return .RexxText~new(self~string~substr(startB, 2), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "Unicode32_Encoding" public inherit Unicode_Encoding Unicode_CommonServices IndexerStringInterface StringIndexer

::constant name "Unicode32"
::constant isUnicode32 1
::constant codeUnitSizeInBytes 4
::constant codepointMaxBytes 4


::method checkCodepoint class
    -- Surrogates are ok, nothing to check regarding the surrogates
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil, checkingMaximumCodepoint=.false
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
    end
    return 1 -- a positive value means "no error"

    error_range: if checkingMaximumCodepoint then return error(0, self~name "encoding: invalid maximum codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
                                             else return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)

    error:
        use strict arg whichCodepoint, errorMessage
        -- Ignore the argument errorInfo. If the codepoint is out of range then raise immediatly an error.
        -- I don't want to have thousands of errors recorded because someone try to get a Unicode8 string from a string containing thousands codepoint > 255.
        if .false then do -- .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB)
        sizeB = nextB - startB
    end
    -- numeric digits 10 -- not needed, managed by decodeCodepoint
    if sizeB == 0 then return .nil
    if sizeB == 4 then return self~decodeCodepoint(string~substr(startB, 4))
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB
    lengthB = string~length
    if startB > lengthB then return 0 -- end of string
    if lengthB - startB < 3 then return -1 -- truncated
    return 4


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use named arg errorInfo=.nil, raiseError=.true
    indexB = startB
    lengthB = string~length
    if indexB > lengthB then return indexB -- end of string
    if lengthB - indexB < 3 then signal truncated
    return indexB + 4

    truncated:
        nextCodepointIndex = indexB + 4
        if raiseError then call error self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 4 bytes"
        return -nextCodepointIndex -- negative value means error

    error:
        use strict arg errorMessage
        if .nil <> errorInfo then errorInfo[1] = errorMessage"."
                             else raise syntax 23.900 array (errorMessage)
        return


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    self~checkCodepoint(codepoint, checkOnlyRange:.true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(self~encodeCodepoint(codepoint))
                      else return .RexxText~new(self~encodeCodepoint(codepoint), self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange:.true)
    return 4


::method encodeASCIIstring class
    expose isLittleEndian
    use strict arg string
    use strict named arg buffer(1)=.nil
    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 4)
    if isLittleEndian then do
        loop i=1 to sizeB
            buffer~append(string~subchar(i))
            buffer~append("000000"x) -- little endian
        end
    end
    else do
        loop i=1 to sizeB
            buffer~append("000000"x) -- big endian
            buffer~append(string~subchar(i))
        end
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return 4 * (indexC - 1) + 1
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return 4 * (indexC - 1) + 1 -- sparse array: the value can be derived from the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes then do
        -- This optimization is possible despite I no longer store the last index+1: the last codepoint is always 4 bytes.
        if decode then return self~class~decode(self~string, startB, 4)
                  else return self~string~substr(startB, 4)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return 4 * (indexG - 1) + 1
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return 4 * (indexG - 1) + 1 -- sparse array: the value can be derived from the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 4))
                          else return .RexxText~new(self~string~substr(startB, 4), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "UnicodeCharacterSupplier" public subclass Supplier

::method init
    expose characters index
    use strict arg characters
    empty = .array~new(0) -- No need to create a copy, the array of UnicodeCharacter can grow but not shrink
    self~init:super(empty, empty)
    index = characters~first


::method string
    expose characters
    return self~string:super "count="characters~items "size="characters~size

::method count
    expose characters
    use strict arg -- none
    return characters~items -- not ~size because it's a sparse array


::method available
    expose index
    use strict arg -- none
    return .nil <> index


::method index
    expose index
    use strict arg -- none
    if self~available then return index - 2 -- yes, to support -1 and 0, all the indexes are +2


::method item
    expose characters index
    use strict arg -- none
    if self~available then return characters[index]


::method next
    expose characters index
    use strict arg -- none
    if .nil <> index then index = characters~next(index)


::method last
    expose characters
    last = characters~last
    if .nil == last then return .nil
    return characters[last]


/******************************************************************************/
::class "UnicodeCharacterIntervalSupplier" public subclass Supplier

::method init
    expose characterIntervals totalIntervalsNotExpanded
    use strict arg characterIntervals
    self~init:super(characterIntervals~allItems, characterIntervals~allIndexes)
    totalIntervalsNotExpanded = characterIntervals~select{\item~isExpanded}~items


::method string
    expose characterIntervals totalIntervalsNotExpanded
    return self~string:super "count="characterIntervals~items "notExpanded:"totalIntervalsNotExpanded~singularPluralCount("interval", "intervals")", ".Unicode~totalIntervalCharactersNotExpanded~singularPluralCount("character", "characters")


::method count
    expose characterIntervals
    use strict arg -- none
    return characterIntervals~items


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
::routine ppCodepoint public
    /*
    Appendix A - Notational conventions
    In running text, an individual Unicode code point is expressed as U+n, where n is four to
    six hexadecimal digits, using the digits 0–9 and uppercase letters A–F (for 10 through 15,
    respectively). Leading zeros are omitted, unless the code point would have fewer than four
    hexadecimal digits—for example, U+0001, U+0012, U+0123, U+1234, U+12345, U+102345
    */
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    if \datatype(codepoint, "W") then return "not a whole number"
    if codepoint < 0 then return codepoint
    if .nil == buffer then do
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
    if .nil == byteIndex then return ""
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
