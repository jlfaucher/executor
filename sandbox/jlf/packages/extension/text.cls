::extension RexxText        inherit RexxTextInitializer
::extension RexxText        inherit RexxTextPrettyPrinter
::extension RexxText        inherit RexxTextContents
::extension RexxText        inherit RexxTextOperators
::extension RexxText        inherit RexxTextStringInterface

::extension String          inherit EncodedString
::extension MutableBuffer   inherit EncodedMutableBuffer

::requires "extension/string.cls"
::requires "encoding/stringEncoding.cls"

--::options trace r

/******************************************************************************/
/*
TODOs

Test if the cache optimization of the methods isXXX is useful
Testing 'if var("XXX")' has a cost.

07/08/2022
I tested
    t = "hello"~text
    do 1000000; t~isUnicode; end
If I don't cache the value on the RexxText then it's +1 sec
But even if it's a little bit faster, I think I should not pollute my code with such optimizations everywhere.
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
::extension Object

/*
By default, an object is compatible with String (can be converted to a string).
See also this same method on RexxText and String.
*/
::method isCompatibleWithByteString class
    return .true

::method isCompatibleWithByteString
    return .true


/*
Should find a better name (like requestEncodedStringable) but I find the current name crystal clear.
At the moment of writing this comment, the result can be a RexxText or a MutableBuffer or a String.

The purpose of this method is to avoid to create systematically a RexxText when
needing an object supporting the Trait "EncodedStringable".
::Trait "EncodedStringable"
::method ~encoding
::method ~isCompatibleWithASCII

A RexxText is returned as-is.
A MutableBuffer is returned as-is (avoid to request a String from it)
A String is returned as a RexxText if already associated to a RexxText, otherwise returned as-is.
For any other object, a String is requested.

Here, we are in the case any other object.
See also this same method on RexxText and MutableBuffer and String.
*/
::method requestTextOrBufferOrString class
    string = self~request("STRING")
    if .nil <> string then return string
    return self~string

::method requestTextOrBufferOrString
    string = self~request("STRING")
    if .nil <> string then return string
    return self~string


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isTextOrBufferOrString class
    return .false

::method isTextOrBufferOrString
    return .false


/******************************************************************************/
::class "EncodedString" mixinclass Object private

/*
    aString
     ▲  text --------> aRexxText
     │                     indexer (anEncoding)
     │                          codepoints (sequential access)
     │                          graphemes  (direct access)
     +-<---------------------<- string
*/


::attribute text get
    expose encoding myText -- attribute added on the String instance
    -- Don't use the exposed encoding as default value because can be unassigned.
    -- Use the attribute encoding which returns the default encoding if unassigned.
    use strict arg textEncoding=(self~encoding)
    if \var("myText") then do -- no stored counterpart
        myText = .RexxText~new(self, textEncoding) -- store the RexxText counterpart created from itself with specified encoding
    end
    else if arg(1, "e") then do
        -- If the encoding was explicitely specified then change the encoding
        textEncoding = .Encoding~factory(textEncoding, self)
        if myText~encoding <> textEncoding then myText~encoding = textEncoding
    end
    encoding = myText~encoding -- align string & text encoding.
    return myText


::attribute text set -- private
    -- Can't declare this method private, because it's used by RexxText
    -- But the assignment is secured:
    -- If not yet linked to a RexxText then only a RexxText linked to this string can be assigned
    -- If already linked to a RexxText then only this RexxText is accepted
    expose encoding myText -- attribute added on the String instance
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
    encoding = myText~encoding -- align string & text encoding.


::attribute encoding get
    expose encoding myText
    use strict arg -- none
    if var("myText") then return myText~encoding
    if var("encoding") then return encoding
    return .Encoding~defaultEncoding


::attribute encoding set
    expose encoding myText
    use strict arg newEncoding
    encoding = .Encoding~factory(newEncoding, self)
    if var("myText") then myText~encoding = newEncoding


::method hasEncoding
    expose encoding
    use strict arg -- none
    return var("encoding")


::method hasText
    expose myText
    use strict arg -- none
    return var("myText")


::method makeRexxText
    use strict arg -- none
    return self~text


::method makeRexxTextOrString
    use strict arg returnString=.false
    if returnString then return self
    return self~text


/*
Depending on its encoding, an encoded string may be not compatible with ASCII.
*/
::method isCompatibleWithASCII
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if (self~encoding~isByte | self~encoding~isUTF8 | self~encoding~isWTF8 | self~encoding~isUnicode8), self~isASCII then return .true
    return .false


/*
Depending on its encoding, an encoded string may be not compatible with
the String methods (byte-oriented).
*/
::method isCompatibleWithByteString
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if self~encoding~isByte then return .true
    if (self~encoding~isUTF8 | self~encoding~isWTF8 | self~encoding~isUnicode8), self~isASCII then return .true
    return .false


/*
Allows to use a String or a RexxText indistinctly.
Return a text only if already created.
Otherwise return the string.
*/
::method requestTextOrBufferOrString
    expose myText
    use strict arg -- none
    if var("myText") then return myText
    return self


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isTextOrBufferOrString
    use strict arg -- none
    return .true


::method copy
    -- If the string is linked to a RexxText then the RexxText must also be cloned.
    expose myText
    use strict arg -- none
    if \var("myText") then return self~copy:super
    textCopy = myText~copy
    return textCopy~string


::method description
    /*
    "noël👩‍👨‍👩‍👧🎅"~description(s:1)          -- 'UTF-8 not-ASCII'
    "noël👩‍👨‍👩‍👧🎅"~description               -- 'UTF-8 not-ASCII (34 bytes)'
    */
    if self~hasText then forward to (self~text)
    use strict arg -- none
    use strict named arg short(1)=.false, technical(1)=.false /* not used */
    sizesDescription = ""
    if \short then sizesDescription = "(" ||,
                                      self~length~singularPluralCount("byte", "bytes"),
                                      || ")"
    return " "~join(self~encoding~description(self~isASCII), sizesDescription)


::method descriptionForError
    if self~hasText then forward to (self~text)
    -- Display the <length> first characters
    use strict arg length=10
    string = self
    if string~length > length then string = string~left(length - 3)"..."
    -- escape3 is needed to have a proper display like this: [00]4[00]1
    return self~description(s:1) "'"escape3(string)"'"


/******************************************************************************/
::class "EncodedMutableBuffer" mixinclass Object private

/*
    Nothing sophisticated here...
    Just manage the attribute 'encoding', to know what is the current encoding of the MutableBuffer.
    By "current", I mean that this encoding may change during the life of the MutableBuffer,
    especially when doing concatenations. For example, an UTF-8 buffer will become a WTF-8 buffer
    when appending a WTF-8 string.
    There is no analysis of contents, no indexer, no associated text.
    The analysis is done when a RexxText instance is created from the buffer's string.
*/

::attribute encoding get
    expose encoding
    use strict arg -- none
    if var("encoding") then return encoding
    return .Encoding~defaultEncoding


::attribute encoding set
    expose encoding
    use strict arg newEncoding
    encoding = .Encoding~factory(newEncoding, self~string)


-- TODO: make it native
-- Remember: needed to fix RexxMutableBufferClass::newRexx to pass all the new's arguments to init
::method init_extended
    expose encoding
    -- if the optional argument 'string' is provided then memorize its encoding
    if arg(1, "e") then encoding = arg(1)~encoding
    -- forward class (super) -- don't forward, that would raise an unknown method


::method hasEncoding
    expose encoding
    use strict arg -- none
    return var("encoding")


/*
Allows to use a MutableBuffer or a RexxText indistinctly,
without requesting a string from the buffer
*/
::method requestTextOrBufferOrString
    use strict arg -- none
    return self


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isTextOrBufferOrString
    use strict arg -- none
    return .true


::method description
    /*
    .MutableBuffer~new("noël👩‍👨‍👩‍👧🎅")~description(s:1)          -- 'UTF-8 not-ASCII'
    .MutableBuffer~new("noël👩‍👨‍👩‍👧🎅")~description               -- 'UTF-8 not-ASCII (34 bytes)'
    */
    use strict arg -- none
    use strict named arg short(1)=.false, technical(1)=.false /* not used */
    sizesDescription = ""
    if \short then sizesDescription = "(" ||,
                                      self~length~singularPluralCount("byte", "bytes"),
                                      || ")"
    return " "~join(self~encoding~description(self~isASCII), sizesDescription)


::method descriptionForError
    -- Display the <length> first characters
    use strict arg length=10
    string = self~substr(1, min(length, self~length)) -- Remember: ~left not supported
    if self~length > length then string = string~left(length - 3)"..."
    -- escape3 is needed to have a proper display like this: [00]4[00]1
    return self~description(s:1) "'"escape3(string)"'"


::method isCompatibleWithASCII
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if (self~encoding~isByte | self~encoding~isUTF8 | self~encoding~isWTF8 | self~encoding~isUnicode8), self~isASCII then return .true
    return .false


/******************************************************************************/
::class "RexxTextInitializer" mixinclass Object private

::method init
    -- The RexxText is not referencing directly the String, it's the indexer
    expose indexer /* rest is optim */ string text encoding
    use strict arg argString, argEncoding=(argString~encoding)
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
    use strict arg -- none
    if self~isCompatibleWithByteString then return indexer~string
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


/*
Allows to use a String or a RexxText indistinctly
*/
::method requestTextOrBufferOrString
    use strict arg -- none
    return self


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isTextOrBufferOrString
    use strict arg -- none
    return .true


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

-- Should honor .Encoding~defaultOutputEncoding
::method ppString
    use arg surroundByQuotes=.true -- keep it for the moment, still needed from rgf_util2
    use named arg ppOptions. = (.Stem~new), ppOptions.surroundByQuotes = (surroundByQuotes)

    pp = self~string
    if ppOptions.surroundByQuotes then pp = pp~quoted("'")

    -- Texts are prefixed with "T"
    pp = "T"pp
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


::method isASCII
    forward to (self~string)


::method isCompatibleWithASCII
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if (self~encoding~isByte | self~encoding~isUTF8 | self~encoding~isWTF8 | self~encoding~isUnicode8), self~string~isASCII then return .true
    return .false


::method isCompatibleWithByteString
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if self~encoding~isByte then return .true
    if (self~encoding~isUTF8 | self~encoding~isWTF8 | self~encoding~isUnicode8), self~string~isASCII then return .true
    return .false


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
    use strict arg -- none
    if \self~isCompatibleWithByteString then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx hexadecimal value")


::method checkNumericValueCompatibility
    -- The purpose is not to check that the text is a numeric value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    use strict arg -- none
    if \self~isCompatibleWithByteString then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx numeric value")


::method checkLogicalValueCompatibility
    -- The purpose is not to check that the text is a logical value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    use strict arg -- none
    if \self~isCompatibleWithByteString then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx logical value")


::method unescape
    forward to (self~indexer)


::method title
    forward to (self~indexer)


::method isNFC
    forward to (self~indexer)


::method NFC
    forward to (self~indexer)


::method isNFD
    forward to (self~indexer)


::method NFD
    forward to (self~indexer)


::method isNFKC
    forward to (self~indexer)


::method NFKC
    forward to (self~indexer)


::method isNFKD
    forward to (self~indexer)


::method NFKD
    forward to (self~indexer)


::method isCasefold
    forward to (self~indexer)


::method casefold
    forward to (self~indexer)


::method isMarkStripped
    forward to (self~indexer)


-- no standalone method Markless
-- works only with normalization.


::method isIgnorableStripped
    forward to (self~indexer)


::method isCCStripped
    forward to (self~indexer)


::method isNAStripped
    forward to (self~indexer)


/******************************************************************************/
::class "RexxTextStringInterface" mixinclass Object private

/*
Class methods
=============
alnum                           (new 5) alpha + digit
alpha                           (new 5) Lowercase + Uppercase + Lt + Lm + Lo + Nl + Other_Alphabetic
blank                           (new 5) "horizontal" whitespace: space separators plus U+0009 tab.
cntrl                           (new 5) Cc
cr                              (new 5)
digit                           (new 5) Nd
graph                           (new 5)
lower                           (new 5) Ll + Other_Lowercase
nl                              (new 5)
null                            (new 5)
print                           (new 5)
punct                           (new 5)
space                           (new 5)
tab                             (new 5)
upper                           (new 5) Lu + Other_Uppercase
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
caselessCompareTo               full UTF-8 (expansion like "ß" --> "ss" will invalidate the user's positions)
caselessContains                (new 5)
caselessContainsWord            (new 5)
caselessCountStr
caselessEndsWith                (new 5)
caselessEquals
caselessLastPos
caselessMatch                   full UTF-8
caselessMatchChar
caselessPos
caselessStartsWith              (new 5)
caselessWordPos
center                          full
centre                          full
changeStr
contains                        (new 5)
containsWord                    (new 5)
compare
compareTo                       full UTF-8
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
match                           full UTF-8
matchChar
max
min
modulo                          (new 5)
overlay
pos
replaceAt
reverse                         full
right                           full
round
sign
space
startsWith                      (new 5)
strip
subChar                         full
substr                          full
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

Other methods/routines
======================
stringChunks
    parse (only for breakTokens)
    pos (only for escapeCharacters)
    caselessWordPos (only for breakTokens)
    .LengthComparator~new("d") (only for breakTokens)

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
    use strict arg text, n=1, length=.nil
    use strict named arg casefold=.true, lump= .false, stripIgnorable= .false, stripmark = .false
    text = text~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == length then do
        selfLength = self~length
        textLength = text~length
    end
    else do
        if \datatype(length, "w") then signal invalid_length
        if length < 0 then signal invalid_length -- 0 accepted
        selfLength = min(length, self~length)
        textLength = min(length, text~length)
    end
    selfNormalized = self~substr(n, selfLength)~NFC(:casefold, :lump, :stripIgnorable, :stripmark)
    textNormalized = text~substr(n, textLength)~NFC(:casefold, :lump, :stripIgnorable, :stripmark)
    return selfNormalized~string~CompareTo(textNormalized~string)

    invalid_length: raise syntax 93.923 array(length)


::method caselessContains
    use arg other -- not strict, just need to check this one
    if self~isCompatibleWithByteString, other~isCompatibleWithByteString then do
        forward message "caselessPos" to (self~string) continue
        return result <> 0
    end
    forward message "caselessPos" to (self~indexer) continue
    return result <> 0


::method caselessEndsWith
    use arg other -- not strict, just need to check this one
    if self~isCompatibleWithByteString, other~isCompatibleWithByteString then do
        forward message "caselessEndsWith" to (self~string) continue
        return result <> 0
    end
    forward message "caselessEndsWith" to (self~indexer)


::method caselessMatch
    use arg _start, other, ... -- not strict, just need to check 'other'
    if self~isCompatibleWithByteString, other~isCompatibleWithByteString then forward to (self~string)
    forward to (self~indexer)


::method caselessMatchChar
    use arg _n, chars -- not strict, just need to check 'chars'
    if self~isCompatibleWithByteString, chars~isCompatibleWithByteString then forward to (self~string)
    forward to (self~indexer)


::method caselessPos
    use arg needle, ... -- not strict, just need to check 'other'
    if self~isCompatibleWithByteString, other~isCompatibleWithByteString then forward to (self~string)
    forward to (self~indexer)


::method caselessStartsWith
    use arg other -- not strict, just need to check this one
    if self~isCompatibleWithByteString, other~isCompatibleWithByteString then do
        forward message "caselessPos" to (self~string) continue
        return result == 1
    end
    forward message "caselessPos" to (self~indexer) continue
    return result == 1


::method center
    use arg _length, pad -- not strict, just need to check 'pad'
    use strict named arg buffer(1)=.nil
    padIsCompatibleWithByteString = .true
    if arg(2, "e") then do
        if \pad~isCompatibleWithByteString then padIsCompatibleWithByteString = .false
        else if pad~length > 1 then padIsCompatibleWithByteString = .false -- maybe its length will be 1 when converted to text
    end
    if self~isCompatibleWithByteString, padIsCompatibleWithByteString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method centre
    forward message "center"


::method compareTo
    use strict arg text, n=1, length=.nil
    use strict named arg lump= .false, stripIgnorable= .false, stripmark=.false
    return self~caselessCompareTo(text, n, length, casefold: .false, :lump, :stripIgnorable, :stripmark)


::method contains
    -- regex.cls uses the method .String~contains which is available only from ooRexx v5.
    use arg other -- not strict, just need to check this one
    if self~isCompatibleWithByteString, other~isCompatibleWithByteString then do
        forward message "pos" to (self~string) continue
        return result \== 0
    end
    forward message "pos" to (self~indexer) continue
    return result \== 0


::method copies
    use strict named arg buffer(1)=.nil
    forward to (self~string) continue
    if .nil <> buffer then return buffer~~append(result)
                      else return .RexxText~new(result, self~encoding)


::method endsWith
    use arg other -- not strict, just need to check this one
    if self~isCompatibleWithByteString, other~isCompatibleWithByteString then do
        forward message "endsWith" to (self~string) continue
        return result <> 0
    end
    forward message "endsWith" to (self~indexer)


::method hashCode
    forward to (self~string)


::method join -- extension
    -- Positional arguments : zero to N text/string or arrays of text/string (recursively).
    -- The text value of each argument is joined, with self used as separator
    -- If the encoding of an argument is not compatible for concatenation with self then an error is raised
    use strict named arg buffer(1)=.nil, appender(1)=(self~encoding)
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    if \buffer~hasEncoding then buffer~encoding = self~encoding
    buffer~join(arg(1, "a"), separator: self, a: appender)
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~encoding)


::method left
    use strict arg _length, _pad="" -- not used, it's just to check that we get at least the length, and that we don't get more than 2 arguments
    -- equivalent to substr(1, length, pad)
    forward message "substr" arguments (arg(1, "a")~~insert(1, .nil))


::method length -- number of graphemes
    use strict arg -- none
    return self~indexer~graphemeCount


::method lower
    use strict named arg buffer(1)=.nil
    if self~isCompatibleWithByteString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method match
    use arg _start, other, ... -- not strict, just need to check 'other'
    if self~isCompatibleWithByteString, other~isCompatibleWithByteString then forward to (self~string)
    forward to (self~indexer)


::method matchChar
    use arg _n, chars -- not strict, just need to check 'chars'
    if self~isCompatibleWithByteString, chars~isCompatibleWithByteString then forward to (self~string)
    forward to (self~indexer)


::method pos
    use arg needle, ... -- not strict, just need to check 'needle'
    if self~isCompatibleWithByteString, needle~isCompatibleWithByteString then forward to (self~string)
    forward to (self~indexer)


::method reverse
    use strict named arg buffer(1)=.nil
    if self~isCompatibleWithByteString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method right
    -- can't delegate to substr because here the padding is on the left
    use arg _length, pad -- not strict, just need to check 'pad'
    use strict named arg buffer(1)=.nil
    padIsCompatibleWithByteString = .true
    if arg(2, "e") then do
        if \pad~isCompatibleWithByteString then padIsCompatibleWithByteString = .false
        else if pad~length > 1 then padIsCompatibleWithByteString = .false -- maybe its length will be 1 when converted to default encoding
    end
    if self~isCompatibleWithByteString, padIsCompatibleWithByteString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method startsWith
    use arg other -- not strict, just need to check this one
    if self~isCompatibleWithByteString, other~isCompatibleWithByteString then do
        forward message "pos" to (self~string) continue
        return result == 1
    end
    forward message "pos" to (self~indexer) continue
    return result == 1


::method subchar
    forward message "grapheme"


::method substr
    use arg _startB, _length, pad -- not strict, just need to check 'pad'
    use strict named arg buffer(1)=.nil
    padIsCompatibleWithByteString = .true
    if arg(3, "e") then do
        if \pad~isCompatibleWithByteString then padIsCompatibleWithByteString = .false
        else if pad~length > 1 then padIsCompatibleWithByteString = .false -- maybe its length will be 1 when converted to default encoding
    end
    if self~isCompatibleWithByteString, padIsCompatibleWithByteString then do
        forward to (self~string) continue
        if .nil <> buffer then return buffer~~append(result)
                          else return .RexxText~new(result, self~encoding)
    end
    forward to (self~indexer)


::method upper
    use strict named arg buffer(1)=.nil
    if self~isCompatibleWithByteString then do
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
    use strict named arg strict
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
    if .nil == right then forward message (message) to (self~string) array(right) -- delegate to String for the management of .nil
    -- Give chance to an alternative operator before requesting a text or buffer or string
    messageOpRight = message"op:right"
    if \right~isTextOrBufferOrString, right~hasMethod(messageOpRight) then do
        right~send(messageOpRight, self)
        if var("result") then return result
    end
    right = right~requestTextOrBufferOrString
    if .nil == right then return
    if .Encoding~comparisonMode(self, right) == "b" then do
        forward message (message) to (self~string) array (right~string)
    end
    -- Unicode comparison
    right = right~request("RexxText")
    if .nil == right then return
    selfNormalized = self~NFC(lump: \strict, stripIgnorable: \strict)
    rightNormalized = right~NFC(lump: \strict, stripIgnorable: \strict)
    forward message (message) to (selfNormalized~string) array (rightNormalized~string)


::method compareLeftSelf
    use strict arg left, message
    use strict named arg strict
    left = left~requestTextOrBufferOrString
    if .nil == left then return
    if .Encoding~comparisonMode(left, self) == "b" then do
        forward message (message) to (left~string) array (self~string)
    end
    -- Unicode comparison
    left = left~request("RexxText")
    if .nil == left then return
    leftNormalized = left~NFC(lump: \strict, stripIgnorable: \strict)
    selfNormalized = self~NFC(lump: \strict, stripIgnorable: \strict)
    forward message (message) to (leftNormalized~string) array (selfNormalized~string)


::method '<'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<', strict: .false)

::method '<op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<', strict: .false)

::method '<<'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<<', strict: .true)

::method '<<op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<<', strict: .true)

::method '<<='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<<=', strict: .true)

::method '<<=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<<', strict: .true)

::method '<='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<=', strict: .true)

::method '<=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<=', strict: .false)

::method '<>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<>', strict: .false)

::method '<>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<>', strict: .false)

::method '='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '=', strict: .false)

::method '=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '=', strict: .false)

::method '=='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '==', strict: .true)

::method '==op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '==', strict: .true)

::method '>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>', strict: .false)

::method '>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>', strict: .false)

::method '><'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '><', strict: .false)

::method '><op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '><', strict: .false)

::method '>='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>=', strict: .false)

::method '>=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>=', strict: .false)

::method '>>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>>', strict: .true)

::method '>>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>>', strict: .true)

::method '>>='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>>=', strict: .true)

::method '>>=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>>=', strict: .true)

::method '\<'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\<', strict: .false)

::method '\<op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\<', strict: .false)

::method '\='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\=', strict: .false)

::method '\=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\=', strict: .false)

::method '\=='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\==', strict: .true)

::method '\==op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\==', strict: .true)

::method '\>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\>', strict: .false)

::method '\>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>', strict: .false)

::method '\>>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\>>', strict: .true)

::method '\>>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\>>', strict: .true)


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
    -- Give chance to an alternative operator before requesting a text or buffer or string
    if \right~isTextOrBufferOrString, right~hasMethod(" op:right") then do
        right~" op:right"(self)
        if var("result") then return result
    end
    right = right~requestTextOrBufferOrString
    if .nil == right then return
    encoding = .Encoding~ForConcatenation(self, right)
    return encoding~concatenate(self, encoding~spaceCharacter, right)


::method " op:right"
    use strict arg left
    left = left~requestTextOrBufferOrString
    if .nil == left then return
    encoding = .Encoding~ForConcatenation(left, self)
    return encoding~concatenate(left, encoding~spaceCharacter, self)


::method "||"
    use strict arg right
    -- Give chance to an alternative operator before requesting a text or buffer or string
    if \right~isTextOrBufferOrString, right~hasMethod("||op:right") then do
        right~"||op:right"(self)
        if var("result") then return result
    end
    right = right~requestTextOrBufferOrString
    if .nil == right then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "||op:right"
    use strict arg left
    left = left~requestTextOrBufferOrString
    if .nil == left then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(left, self)
    return encoding~concatenate(left, self)


::method "" -- abuttal
    use strict arg right
    -- Give chance to an alternative operator before requesting a text or buffer or string
    if \right~isTextOrBufferOrString, right~hasMethod("op:right") then do
        right~"op:right"(self)
        if var("result") then return result
    end
    right = right~requestTextOrBufferOrString
    if .nil == right then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "op:right" -- abuttal
    use strict arg left
    left = left~requestTextOrBufferOrString
    if .nil == left then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(left, self)
    return encoding~concatenate(left, self)
