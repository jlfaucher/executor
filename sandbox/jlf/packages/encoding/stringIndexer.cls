::requires "extension/string.cls"   -- for escape3
::requires "encoding/cachedStrings.cls"

-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText

/*
Depends on
.WTF16BE_ENCODING
.WTF16LE_ENCODING
.WTF8_ENCODING
*/


/******************************************************************************/
::class "StringIndexer" mixinclass Object public - -- private - -- abstract
                        inherit CachedStrings

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


::method codeUnitSizeInBytes class abstract -- constant 1 2 or 4


::method codepointMaxBytes class abstract -- constant used for buffer allocation


/*
Analyze all the bytes of the string, create an indexer.

Return value:
    a RexxText

In case of errors, an array attached to the RexxText provides all the errors
detected during the analysis.
*/
::method analyze class abstract
    -- use strict arg string


/*
Arguments:
    previousCodepoint can be .nil (first codepoint) or <0 (error recovery).
    when <0 abs(previousCodepoint) is the invalid value.

    errorInfo is either an array or .nil
    when array, in case of error, the error description is returned in errorInfo[1]

Return value:
    A positive value means "no error"
    A negative or null value means "error"

if no error then checkCodepoint == 1.
if error then
    if errorInfo == .nil then a condition is raised
    otherwise
        errorInfo[1] = error description
        checkCodepoint == -1 if the error is about previousCodepoint
        checkCodepoint == 0  if the error is abour codepoint
*/
::method checkCodepoint class abstract
    -- use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    -- use strict named arg checkOnlyRange /*no impact here*/, errorInfo=.nil
    -- Unicode8_Encoding, Unicode16_Encoding and Unicode32_Encoding accept an additional named argument: checkingMaximumCodepoint=.false


/*
sizeB == -1 ==> this method will check the validity of the encoding
sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
if sizeB == 0 then return .nil otherwise return a string made of one codepoint
*/
::method decode class abstract
    -- use strict arg string /* or buffer */, startB=1, sizeB=(-1)


::method byteSequenceSize class abstract


/*
If end of string, then nextCodepointIndex == startB.

if errorInfo \== .nil then in case of error: nextCodepointIndex is negative and always greater than startB.
                                             errorInfo[1] == error description.
if errorInfo  == .nil  then no need to test if nextCodepointIndex is negative. In case of error, a condition is raised.
*/
::method nextCodepointIndex class abstract
    -- use strict arg string /* or buffer */, startB
    -- use strict named arg errorInfo=.nil


/*
If startB is the start of string then nextCodepointIndex is equal to startB.

If startB is beyond the end of string +1 byte then nextCodepointIndex is equal to startB.
Which means "no previous codepoint".
Not trying to walk back until a valid codepoint is found, whatever the distance.
Reason: if no error then startB - previousCodepointIndex is the length in bytes of the previous codepoint.

if errorInfo \== .nil then in case of error: nextCodepointIndex is negative and always lesser than startB.
                                             errorInfo[1] == error description.
if errorInfo  == .nil  then no need to test if nextCodepointIndex is negative. In case of error, a condition is raised.

startB is the index of the first byte of the current codepoint
  cp1        |cp2              |cp3...
  byte1|byte2|byte3|byte4|byte5|byte6...
  1    |2    |3    |4    |5    |6...
For example, if startB==6 then previousCodepointIndex==3
*/
::method previousCodepointIndex class abstract
    -- use strict arg string /* or buffer */, startB
    -- use strict named arg errorInfo=.nil


::method encode class abstract


::method codepointSizeInBytes class abstract -- how many bytes to encode this codepoint


::method codepointToLowerSimple class abstract  -- return 1 codepoint
::method codepointToLowerFull class abstract    -- return 1..n codepoints


::method codepointToUpperSimple class abstract  -- return 1 codepoint
::method codepointToUpperFull class abstract    -- return 1..n codepoints


::method codepointToTitleSimple class abstract  -- return 1 codepoint
::method codepointToTitleFull class abstract    -- return 1..n codepoints


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
    -- Remember: This method does not change the encoding of the buffer.
    --           Use .StringIndexer~append (inherited from .IndexerHelpers) to have the buffer's encoding updated.
    use arg ...
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    -- This method does not change the encoding of the buffer
    -- if \buffer~hasEncoding then buffer~encoding = self
    do i = 1 to arg()
        -- Only WTF-8 has a specific implementation of appendToBuffer.
        -- When concatenating WTF-8 with UTF-8 or ASCII, the target encoding (self) is WTF-8.
        arg(i)~encoding~appendToBuffer(arg(i)~string, :buffer)
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


-- If you modify this method then see if forConcatenation must be modified as well
::method asEncodingFor class
    use strict arg buffer
    targetEncoding = self
    if \buffer~hasEncoding then return targetEncoding -- when no encoding then any encoding is compatible

    bufferEncoding = buffer~encoding
    bufferIsCompatibleWithASCII = buffer~isCompatibleWithASCII

    if bufferEncoding == targetEncoding then return bufferEncoding

    if bufferEncoding~isUTF8, targetEncoding~isWTF8 then return .WTF8_Encoding
    if bufferEncoding~isWTF8, targetEncoding~isUTF8 then return .WTF8_Encoding
    -- Keep the following tests after the previous tests, to keep the priority for WTF8
    -- Give priority to unicode over byte-encoding
    -- When unicode on both sides then give priority to the left encoding
    if bufferIsCompatibleWithASCII, (targetEncoding~isUTF8 | targetEncoding~isWTF8 | targetEncoding~isUnicode8) then do
        if bufferEncoding~isUnicode then return bufferEncoding
        return targetEncoding
    end
    -- I'm not sure if the next test is good...
    -- The good test is to test if the right part (here target) isCompatibleWithASCII
    -- but we have only the target encoding, not a real string to test.
    -- The implementation of isCompatibleWithASCII tests 2 things:
    --   - the encoding: (self~encoding~isByte | self~encoding~isUTF8 | self~encoding~isWTF8 | self~encoding~isUnicode8)
    --   - the asciiness of the string: self~string~isASCII
    -- Here, I test only the encoding. The asciiness will be tested elsewhere (for example in StringIndexer~append)
    if   (bufferEncoding~isUTF8 | bufferEncoding~isWTF8 | bufferEncoding~isUnicode8) -
       , (targetEncoding~isUTF8 | targetEncoding~isWTF8 | targetEncoding~isUnicode8) -
       -- , target~isASCII -
    then return bufferEncoding

    if bufferEncoding~isUTF16BE, targetEncoding~isWTF16BE then return .WTF16BE_Encoding
    if bufferEncoding~isWTF16BE, targetEncoding~isUTF16BE then return .WTF16BE_Encoding
    if bufferEncoding~isUTF16LE, targetEncoding~isWTF16LE then return .WTF16LE_Encoding
    if bufferEncoding~isWTF16LE, targetEncoding~isUTF16LE then return .WTF16LE_Encoding

    -- Consider that Unicode32 is never compatible with UTF-32BE or UTF-32LE
    -- even if it can be compatible in function of the CPU endianness.
    -- It's to ensure that if a program works on a little-endian CPU then it works on a big-endian CPU, and vice-versa.

    raise syntax 23.900 array("Encoding: cannot append" targetEncoding~description "to" buffer~descriptionForError)


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
    expose string -
           maximumCodepoint codepointIndexes codepointCount -
           graphemeIndexes graphemeCount case errors
    use strict arg string, maximumCodepoint, codepointIndexes, codepointCount, graphemeIndexes, graphemeCount, case, errors
    self~init:super


::method copy
    -- No need to re-analyze the string, it's immutable:
    -- all the indexes are still applicable, just change the string referenced by the indexer.
    use strict arg -- none
    clone = self~copy:super
    clone~string = .string~new(clone~string) -- don't use ~copy (stack overflow)
    return clone


::method encoding
    return self~class


::method description
    /*
    "noël👩‍👨‍👩‍👧🎅"~text~description(s:1)          -- 'UTF-8 not-ASCII'
    "noël👩‍👨‍👩‍👧🎅"~text~description               -- 'UTF-8 not-ASCII (6 graphemes, 12 codepoints, 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~description(t:1)          -- 'UTF-8 not-ASCII (6 graphemes (3 indexes from index 4), 12 codepoints (9 indexes from index 4), 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~utf16~description(t:1)    -- 'UTF-16BE (6 graphemes (1 index from index 6), 12 codepoints (7 indexes from index 6), 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~utf32~description(t:1)    -- 'UTF-32BE (6 graphemes (1 index from index 6), 12 codepoints (0 index), 48 bytes, 0 error)'
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
    return " "~join(self~encoding~description(self~string~isASCII), sizesDescription)


::method descriptionForError
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
        call ppCodepoint codepoints~item, :buffer
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
    -- use strict arg indexC, decode=.true


::method UnicodeCharacters
    use strict arg -- none
    if self~isUnicode then return self~codepoints~each{.unicode~character(item)}
    -- no result if not Unicode encoding


::method characters
    forward message "graphemes"


::method graphemes
    use strict arg -- none
    return .GraphemeSupplier~new(self)


::method graphemeIndex abstract
    -- use strict arg indexG


::method grapheme abstract
    -- use strict arg indexG
    -- use strict named arg buffer(1)=.nil


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


/*
Executor supports
    \u{Unicode name}    Character name in the Unicode database
    \U{Unicode name}
    \u{X..X}            Unicode character denoted by 1-8 hex digits. The first character must be a digit 0..9 ('u' lowercase)
    \U{X..X}            Unicode character denoted by 1-8 hex digits. The first character must be a digit 0..9 ('U' uppercase)
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
::method unescape abstract


::attribute isNFC get
    bitFlag = self~bitFlag(self~FLAG_NFC)
    if bitFlag \== -1 then return bitFlag

    /*
    http://www.unicode.org/reports/tr15/#Implementation_Notes
    Text exclusively containing Latin-1 characters (U+0000..U+00FF) is left unaffected by NFC.
    This is effectively the same as saying that all Latin-1 text is already normalized to NFC
    ---
    Careful! The sentence above is NOT talking about ISO-8859-1 (alias Latin-1 )
    */
    if self~maximumCodepoint \== -1, self~maximumCodepoint <= 255 then do
        self~setBitFlag(self~FLAG_NFC)
        return .true
    end

    return -1   -- unknown


::method NFC abstract


::attribute isNFD get
    bitFlag = self~bitFlag(self~FLAG_NFD)
    if bitFlag \== -1 then return bitFlag

    -- http://www.unicode.org/reports/tr15/#Implementation_Notes
    -- Text exclusively containing ASCII characters (U+0000..U+007F) is left unaffected by all of the Normalization Forms
    if self~string~isCompatibleWithASCII then do
        self~setBitFlag(self~FLAG_NFD)
        return .true
    end

    return -1   -- unknown


::method NFD abstract


::attribute isNFKC get
    bitFlag = self~bitFlag(self~FLAG_NFKC)
    if bitFlag \== -1 then return bitFlag

    -- http://www.unicode.org/reports/tr15/#Implementation_Notes
    -- Text exclusively containing ASCII characters (U+0000..U+007F) is left unaffected by all of the Normalization Forms
    if self~string~isCompatibleWithASCII then do
        self~setBitFlag(self~FLAG_NFKC)
        return .true
    end

    return -1   -- unknown


::method NFKC abstract


::attribute isNFKD get
    bitFlag = self~bitFlag(self~FLAG_NFKD)
    if bitFlag \== -1 then return bitFlag

    -- http://www.unicode.org/reports/tr15/#Implementation_Notes
    -- Text exclusively containing ASCII characters (U+0000..U+007F) is left unaffected by all of the Normalization Forms
    if self~string~isCompatibleWithASCII then do
        self~setBitFlag(self~FLAG_NFKD)
        return .true
    end

    return -1   -- unknown


::method NFKD abstract


::attribute isCasefold get
    return self~bitFlag(self~FLAG_CASEFOLD)


::method casefold abstract


::attribute isLumped get
    return self~bitFlag(self~FLAG_LUMP)


::attribute isMarkStripped get
    return self~bitFlag(self~FLAG_STRIP_MARK)


::attribute isIgnorableStripped get
    return self~bitFlag(self~FLAG_STRIP_IGNORABLE)


::attribute isCCStripped get
    return self~bitFlag(self~FLAG_STRIP_CC)


::attribute isNAStripped get
    return self~bitFlag(self~FLAG_STRIP_NA)


/******************************************************************************/
::class "CodePointSupplier" public subclass Supplier

::method init
    expose indexer indexC
    use strict arg indexer
    empty = .array~new(0) -- No need to create a copy, the string is immutable
    self~init:super(empty, empty)
    indexC = 1
    -- will add a byte index
    -- self~init:super -- Don't forward, would raise error "argument 1 is required"


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
    -- self~init:super -- Don't forward, would raise error "argument 1 is required"


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
    if codepoint < 0 then return "-" || ppCodepoint(-codepoint)
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
