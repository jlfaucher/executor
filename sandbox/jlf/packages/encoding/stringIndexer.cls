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
                        inherit CachedStrings TransformHelpers

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

::constant isCompatibleWithASCII 0


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
        checkCodepoint == 0  if the error is about codepoint
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
If end of string, then nextCodepointIndexB == startB.

if errorInfo \== .nil then in case of error: nextCodepointIndexB is negative and always greater than startB.
                                             errorInfo[1] == error description.
if errorInfo  == .nil  then no need to test if nextCodepointIndexB is negative. In case of error, a condition is raised.
*/
::method nextCodepointIndexB class abstract
    -- use strict arg string /* or buffer */, startB
    -- use strict named arg errorInfo=.nil


/*
If startB is the start of string then nextCodepointIndexB is equal to startB.

If startB is beyond the end of string +1 byte then nextCodepointIndexB is equal to startB.
Which means "no previous codepoint".
Not trying to walk back until a valid codepoint is found, whatever the distance.
Reason: if no error then startB - previousCodepointIndexB is the length in bytes of the previous codepoint.

if errorInfo \== .nil then in case of error: nextCodepointIndexB is negative and always lesser than startB.
                                             errorInfo[1] == error description.
if errorInfo  == .nil  then no need to test if nextCodepointIndexB is negative. In case of error, a condition is raised.

startB is the index of the first byte of the current codepoint
  cp1        |cp2              |cp3...
  byte1|byte2|byte3|byte4|byte5|byte6...
  1    |2    |3    |4    |5    |6...
For example, if startB==6 then previousCodepointIndexB==3
*/
::method previousCodepointIndexB class abstract
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
    use strict named arg short=.false, technical=.false -- same as the instance method, not used (for the moment)
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
    use strict named arg buffer=.nil
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
    use strict named arg buffer
    buffer~append(string)


-- If you modify this method then see if compatibleEncoding must be modified as well
::method asEncodingFor class
    use strict arg buffer   -- left part
    use strict named arg demotionIsAllowed=.false, errorInfo=.nil

    targetEncoding = self   -- right part
    if \buffer~hasEncoding then return targetEncoding -- when no encoding then any encoding is compatible

    bufferEncoding = buffer~encoding

    if bufferEncoding == targetEncoding then return bufferEncoding

    if bufferEncoding~isUTF8, targetEncoding~isWTF8 then return .WTF8_Encoding
    if bufferEncoding~isWTF8, targetEncoding~isUTF8 then return .WTF8_Encoding
    if bufferEncoding~isUTF16BE, targetEncoding~isWTF16BE then return .WTF16BE_Encoding
    if bufferEncoding~isWTF16BE, targetEncoding~isUTF16BE then return .WTF16BE_Encoding
    if bufferEncoding~isUTF16LE, targetEncoding~isWTF16LE then return .WTF16LE_Encoding
    if bufferEncoding~isWTF16LE, targetEncoding~isUTF16LE then return .WTF16LE_Encoding

    -- Keep the following tests after the previous tests, to keep the priority for WTF8/WTF16
    -- no 'right' string, assume it's always ASCII
    targetIsDemotion = (bufferEncoding~isUnicode & \targetEncoding~isUnicode)
    bufferIsDemotion = (targetEncoding~isUnicode & \bufferEncoding~isUnicode)
    if bufferEncoding~isCompatibleWithASCII, targetEncoding~isCompatibleWithASCII then do
        if buffer~isCompatibleWithASCII, 1 /* right~isCompatibleWithASCII */ then do
            if bufferEncoding~isUnicode then return bufferEncoding      -- Unicode          -- R1
            if targetEncoding~isUnicode then return targetEncoding      -- Unicode          -- R2
            return bufferEncoding                                       -- Byte             -- R3
        end
        if buffer~isCompatibleWithASCII, (demotionIsAllowed | \targetIsDemotion) then return targetEncoding   -- Unicode or Byte  -- R4
        if 1 /* right~isCompatibleWithASCII **/, (demotionIsAllowed | \bufferIsDemotion) then return bufferEncoding   -- Unicode or Byte  -- R5
    end

    -- Consider that Unicode32 is never compatible with UTF-32BE or UTF-32LE
    -- even if it can be compatible in function of the CPU endianness.
    -- It's to ensure that if a program works on a little-endian CPU then it works on a big-endian CPU, and vice-versa.

    return error("Encoding: cannot append" targetEncoding~description "to" buffer~descriptionForError)

    error:
        use strict arg errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return .nil
        end
        raise syntax 23.900 array (errorMessage)


/********************/
/* Instance methods */
/********************/

::attribute string get
::attribute string set private
::attribute maximumCodepoint get -- -1 if not calculated (Byte_Encoding doesn't calculate it)
::attribute codepointIndexes get private -- will be removed, no need of direct access to a codepoint
::attribute codepointCount get
::attribute characterIndexes get private
::attribute characterCount get
::attribute errors get
::attribute case get -- 1 lowercase, 2 uppercase


::method init
    expose string -
           maximumCodepoint codepointIndexes codepointCount -
           characterIndexes characterCount case errors
    use strict arg string, maximumCodepoint, codepointIndexes, codepointCount, characterIndexes, characterCount, case, errors
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
    "noël👩‍👨‍👩‍👧🎅"~text~description(short:1)           -- 'UTF-8 not-ASCII'
    "noël👩‍👨‍👩‍👧🎅"~text~description                    -- 'UTF-8 not-ASCII (6 characters, 12 codepoints, 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~description(technical:1)       -- 'UTF-8 not-ASCII (6 characters (3 indexes from index 4), 12 codepoints (9 indexes from index 4), 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~utf16~description(technical:1) -- 'UTF-16BE (6 characters (1 index from index 6), 12 codepoints (7 indexes from index 6), 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~utf32~description(technical:1) -- 'UTF-32BE (6 characters (1 index from index 6), 12 codepoints (0 index), 48 bytes, 0 error)'
    */
    use strict arg -- none
    use strict named arg short=.false, technical=.false
    if .nil == self~errors then errorCount = 0
                           else errorCount = self~errors~size
    techInfoCodepoints = ""
    techInfoCharacters = ""
    if technical then do
        if .nil == self~codepointIndexes,
            then techInfoCodepoints = " (0 index)"
            else techInfoCodepoints = " ("self~codepointIndexes~items~singularPluralCount("index", "indexes")" from index "self~codepointIndexes~first")"
        if .nil == self~characterIndexes,
            then techInfoCharacters = " (0 index)"
            else techInfoCharacters = " ("self~characterIndexes~items~singularPluralCount("index", "indexes")" from index "self~characterIndexes~first")"
    end
    sizesDescription = ""
    if \short then sizesDescription = "(" ||,
                                      self~characters~count~singularPluralCount("character", "characters")techInfoCharacters",",
                                      self~codepoints~count~singularPluralCount("codepoint", "codepoints")techInfoCodepoints",",
                                      self~string~length~singularPluralCount("byte", "bytes")",",
                                      errorCount~singularPluralCount("error", "errors"),
                                      || ")"
    return " "~join(self~encoding~description(self~string~isASCII), sizesDescription)


::method descriptionForError
    -- Display the <length> first characters
    use strict arg length=10
    use strict named arg short=.true, technical=.false -- minimal description
    text = self~string~text
    if text~length > length then text = text~left(length - 3)"..."
    -- escape3 is needed to have a proper display for this:
    -- say "41"~text~utf16~string  -- 41
    -- say escape3("41"~text~utf16~string)  -- [00]4[00]1
    return self~description(:short, :technical) "'"escape3(text~string)"'"


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


::method c2u abstract
    -- use strict arg -- none


::method c2g
    use strict arg -- none
    use strict named arg buffer=.nil
    characters = self~characters
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    first = .true
    do while characters~available
        if \first then buffer~append(" ")
        first = .false
        buffer~append(characters~item~string~c2x)
        characters~next
    end
    if returnBuffer then return buffer
                    else return buffer~string


::method codepointIndexB
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    array = self~codepointIndexes
    if .nil == array then return self~codeUnitSizeInBytes * (indexC - 1) + 1
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return self~codeUnitSizeInBytes * (indexC - 1) + 1 -- sparse array: the value can be derived from the index


::method codepoints
    use strict arg -- none
    return .CodePointSupplier~new(self)


::method codepoint abstract
    -- use strict arg indexC, decode=.true


::method maximumUnicodeCodepoint abstract
    -- use strict arg -- none


::method UnicodeCharacters abstract
    -- use strict arg -- none


::method characters
    use strict arg -- none
    return .CharacterSupplier~new(self)


::method characterIndexB
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid character index:" indexC)
    if indexC > self~characterCount then return self~string~length + 1
    array = self~characterIndexes
    if .nil == array then return self~codeUnitSizeInBytes * (indexC - 1) + 1
    indexB = array[indexC]
    if .nil <> indexB then return indexB
    return self~codeUnitSizeInBytes * (indexC - 1) + 1 -- sparse array: the value is equal to the index


::method characterIndexC
    -- binary search
    -- negative when not aligned with the character index
    use strict arg indexB, index1=1, index2=(self~length)
    if indexB < 1 then raise syntax 23.900 array (self~description "invalid character index:" indexB)
    if indexB > self~string~length then return self~characterCount + 1
    array = self~characterIndexes
    codeUnitSizeInBytes = self~codeUnitSizeInBytes
    if .nil == array then return indexC(indexB)
    do forever
        if index1 > index2 then return -index2 -- -- negative when not aligned with the character index
        indexC = (index1 + index2) % 2
        item = array[indexC]
        if .nil == item then item = indexB(indexC) -- sparse array: the value can be derived from the index
                        else item = abs(item) -- the stored index can be negative to indicate an invalid character
        if item == indexB then return indexC
        if item > indexB then index2 = indexC - 1
                         else index1 = indexC + 1
    end
    return -- should never reach here

    indexB:
        return codeUnitSizeInBytes * (indexC - 1) + 1

    indexC:
        /*
        For example UTF-16, Unicode16:
        indexB = 2 * (indexC - 1) + 1
        indexB - 1 = 2 * (indexC - 1)
        (indexB - 1) / 2 = indexC - 1
        1 + (indexB - 1) / 2 = indexC
        */
        indexC = 1 + (indexB - 1) / codeUnitSizeInBytes
        if indexC~dataType("W") then return indexC
        return -(indexC~floor) -- negative when not aligned with the character index


::method character abstract
    -- use strict arg indexC
    -- use strict named arg buffer=.nil


::method isLower
    expose case
    return case == 1


::method isUpper
    expose case
    return case == 2


::method transcodeTo abstract
    -- use strict arg targetEncoding
    -- use strict named arg strict=.false, memorize = (.Unicode~memorizeConversions), buffer=.nil, replacementCharacter=.nil, errorInfo=.nil


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
    \U{Unicode name}    same as \u
    \u{X..X}            Unicode character denoted by 1-8 hex digits. The first character must be a digit 0..9 ('u' lowercase)
    \U{X..X}            same as \u
    \uXXXX              Unicode character denoted by 4 hex digits ('u' lowercase)
    \UXXXXXXXX          Unicode character denoted by 8 hex digits ('U' uppercase)
    \xXX                1 byte denoted by 2 hex digits ('x' lowercase)
    \XXXXX              2 bytes denoted by 4 hex digits ('X' uppercase)

How other languages are supporting escape characters for Unicode:
    \N{Unicode name}    Character name in the Unicode database (Python, Julia)
    \u{Unicode name}
    \U{Unicode name}
    \u{nnnn ...}        Unicode character(s), where each nnnn is 1-6 hexadecimal digits (Ruby)
    \u{X..X}            Unicode character denoted by a 1–8 hex digits (Swift)
    \u{XXXXXX}          hexadecimal Unicode code point UTF-8 encoded (1 or more digits) (zig)
    \uXXXX              Unicode character denoted by 4 hex digits (Go, Java, JSON, Julia, Netrexx, Python, Ruby)
    \UXXXXXXXX          Unicode character denoted by 8 hex digits (Go, Julia, Python)
    \xXX                1 byte denoted by 2 hex digits (Go, Netrexx, Python, Ruby)
    \XXX                Unicode character denoted by 3 octal digits (Go)

    https://javajee.com/unicode-escapes-in-java
    The compiler translates Unicode escapes into the characters they represent
    before it parses a program into tokens. It also does so before discarding
    comments and white space.
    System.out.println("a\u0022.length() + \u0022b".length()); // print 2
    is same as
    System.out.println("a".length() + "b".length());
*/
::method unescape abstract


-- See the comments on the class "CachedStrings" in cachedStrings.cls
-- See the method "transform" in utf8_common.cls
-- bit      9       8       7              6         5     4        3    2    1   0
-- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
::constant FLAG_NFC 0
::constant FLAG_NFD 1
::constant FLAG_NFKC 2
::constant FLAG_NFKD 3
::constant FLAG_CASEFOLD 4
::constant FLAG_LUMP 5
::constant FLAG_STRIP_MARK 6
::constant FLAG_STRIP_IGNORABLE 7
::constant FLAG_STRIP_CC 8
::constant FLAG_STRIP_NA 9


::method transform abstract


::method flags
    -- for debug
    flags = ,
    "FLAG_NFC",,
    "FLAG_NFD",,
    "FLAG_NFKC",,
    "FLAG_NFKD",,
    "FLAG_CASEFOLD",,
    "FLAG_LUMP",,
    "FLAG_STRIP_MARK",,
    "FLAG_STRIP_IGNORABLE",,
    "FLAG_STRIP_CC",,
    "FLAG_STRIP_NA"
    values = .directory~new
    do flag over flags
        bitPos = self~send(flag)
        value = self~bitFlag(bitPos)
        values~put(value, flag)
    end

    return values


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
    if self~maximumUnicodeCodepoint \== -1, self~maximumUnicodeCodepoint <= 255 then do
        self~setBitFlag(self~FLAG_NFC)
        return .true
    end

    return -1   -- unknown


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


::attribute isCasefold get
    return self~bitFlag(self~FLAG_CASEFOLD)


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
::class "TransformHelpers" mixinclass Object public -- package

::method transformer
    use strict arg startC=1, lengthC=(max(0, self~length - startC + 1)), pad=(self~encoding~spaceCharacter)
    return .RexxTextTransformer~new(self~string~text, startC, lengthC, pad)


::method NFC
    namedArgs = .context~namedArgs
    normalization = namedArgs~entry("normalization")
    if .nil \== normalization, .Unicode~NFC \== normalization then signal invalid_normalization_argument
    namedArgs~~setEntry("normalization", .Unicode~NFC)
    forward message "transform" namedArguments (namedArgs)

    invalid_normalization_argument: raise syntax 23.900 array ("The named argument 'normalization' can be only .Unicode~NFC (".Unicode~NFC")")


::method NFD
    namedArgs = .context~namedArgs
    normalization = namedArgs~entry("normalization")
    if .nil \== normalization, .Unicode~NFD \== normalization then signal invalid_normalization_argument
    namedArgs~~setEntry("normalization", .Unicode~NFD)
    forward message "transform" namedArguments (namedArgs)

    invalid_normalization_argument: raise syntax 23.900 array ("The named argument 'normalization' can be only .Unicode~NFD (".Unicode~NFD")")


::method NFKC
    namedArgs = .context~namedArgs
    normalization = namedArgs~entry("normalization")
    if .nil \== normalization, .Unicode~NFKC \== normalization then signal invalid_normalization_argument
    namedArgs~~setEntry("normalization", .Unicode~NFKC)
    forward message "transform" namedArguments (namedArgs)

    invalid_normalization_argument: raise syntax 23.900 array ("The named argument 'normalization' can be only .Unicode~NFKC (".Unicode~NFKC")")


::method NFKD
    namedArgs = .context~namedArgs
    normalization = namedArgs~entry("normalization")
    if .nil \== normalization, .Unicode~NFKD \== normalization then signal invalid_normalization_argument
    namedArgs~~setEntry("normalization", .Unicode~NFKD)
    forward message "transform" namedArguments (namedArgs)

    invalid_normalization_argument: raise syntax 23.900 array ("The named argument 'normalization' can be only .Unicode~NFKD (".Unicode~NFKD")")


::method casefold
    -- casefold does not normalize, except if explicitely requested by the caller, or if the caller specified stripMark:.true.
    -- utf8proc note: The option UTF8PROC_STRIPMARK works only with UTF8PROC_COMPOSE or UTF8PROC_DECOMPOSE.
    -- Rules:
    -- if the named argument normalization is not set then
    --     if the named argument stripMark is .true then
    --         don't force the normalization to 0.
    --     otherwise
    --         force the normalization to 0, to avoid using the default normalization
    --         because casefold can be applied without normalizing the string.
    namedArgs = .context~namedArgs
    if namedArgs~entry("stripMark") \== .true then do -- can be .nil (not specified by the caller), .false (not requested), .true (requested)
        -- The caller did not request to strip the accent marks, so the utf8proc note doesn't apply.
        if .nil == namedArgs~entry("normalization") then do
            -- The caller did not specify a normalization, so the default one would be applied.
            -- Force the normalization to 0 (no normalization).
            namedArgs~setEntry("normalization", 0)
        end
    end
    namedArgs~setEntry("casefold", .true) -- the purpose of this method
    forward message "transform" namedArguments (namedArgs)


/******************************************************************************/
::class "RexxTextTransformer" public -
                              inherit TransformHelpers

/*
full text        = original text (untransformed)
external subtext = part of the full text to transform
internal subtext = transformed part of the full text

fulltext = "éßﬄ#éßﬄ#…"~text
transformer = fulltext~transformer(4, 5)~NFD(casefold:)

                         --                          Transformed part of the full text
                         --                       +-------------------------------------+               -- GLOBAL INDEXES (offsetC=3, offsetB=7)
                         --  01   | 02   | 03     | 04 | 05     | 06    | 07       | 08 | 09            -- (external grapheme indexes) <---------+
                         --  1 2  | 3 4  | 5 6 7  | 8  | 9 0    | 1 2   | 3 4 5    | 6  | 7 8 9         -- (external byte indexes)               |
"éßﬄ#éßﬄ#…"~text~c2g   --  C3A9 | C39F | EFAC84 | 23 | C3A9   | C39F  | EFAC84   | 23 | E280A6        -- (external bytes)                      |
                         --  é    | ß    | ﬄ     | #  | é      | ß     | ﬄ       | #  | …             -- (full text)                           ^
                         --  1 2  | 3 4  | 5 6 7  | 8  | 9 0 1  | 2  3  | 4  5  6  | 7  | 8 9 0         -- (internal byte indexes, offset=7)     |
                         --  C3A9 | C39F | EFAC84 | 23 | 65CC81 | 73 73 | 66 66 6C | 23 | E280A6        -- (internal bytes)                      |
                                                  +-------------------------------------+                                                        |
                                                                                                        -- RELATIVE INDEXES                      |
                                                --  01 | 02     | 03    | 04       | 05                 -- (external grapheme indexes) <---------+
                                                --  1  | 2 3    | 4 5   | 6 7 8    | 9                  -- (external byte indexes)               |
"#éßﬄ#"~text~c2g=                              --  23 | C3A9   | C39F  | EFAC84   | 23                 -- (external bytes)                      |
                                                --  #  | é      | ß     | ﬄ       | #                  -- (external subtext)                    ^
                                                                                                                                                 |
                                                                                                        -- RELATIVE INDEXES                      |
                                                --  01 | 02     | 03 04 | 05 06 07 | 08                 -- (internal grapheme indexes)           |
                                                --  1  | 2 3 4  | 5  6  | 7  8  9  | 0                  -- (internal byte indexes) ------>-------+
"#éßﬄ#"~text~NFD(casefold:)~c2g=               --  23 | 65CC81 | 73 73 | 66 66 6C | 23                 -- (internal bytes)
                                                --  #  | é      | s  s  | f  f  l  | #                  -- (internal subtext)

Method ib2xc:
Converts an internal byte (ib) position in the internal subtext (iSubtext)
to an external character (xc) position in the external full text (fulltext).

For that, we have two cursors:
    - an external cursor in the external untransformed subtext
    - an internal cursor in the internal transformed subtext)

Each cursor has a byte position and a character (grapheme) position.
    - External cursor:
            (xSubtextPosB)  todo: remove
            xSubtextPosC
    - Internal cursor:
            iSubtextPosB
            (iSubtextPosC)  todo: remove

We increment the external cursor until we reach or exceed the internal
byte position posB passed as argument.
If posB is exactly reached then we have an aligned position (returns a
positive position).
If posB is exceeded then we have a not-aligned position (returns a
negative position).

If aligned=.false then return a number +/-posC.posB where posB is the
internal position of the byte in the transformed text, and posC is
the external position of the corresponding grapheme in the untransformed
text.

A number is negative if the byte position is not aligned with the
corresponding character position.
*/

::attribute fulltext            -- full text from which xSubtext is extracted
::attribute startB get          -- byte start position of xSubtext in fulltext
::attribute startC get          -- character start position of xSubtext in fulltext
::attribute xSubtext get        -- part of fulltext to transform (external text)
-- ::attribute xSubtextPosB get    -- current external byte position in xSubtext
::attribute xSubtextPosC get    -- current external character position in xSubtext
::attribute iSubtext get        -- transformed part of fulltext (internal subtext)
::attribute iSubtextPosB get    -- current internal byte position in iSubtext
-- ::attribute iSubtextPosC get    -- current internal character position in iSubtext

::method init
    expose fulltext startB startC -
           xSubtext -
           iSubtext -
           backupCount transformed

    -- transforms fulltext~substr(startC, lengthC, pad)
    use strict arg fulltext, startC=1, lengthC=(max(0, fulltext~length - startC + 1)), pad=(fulltext~encoding~spaceCharacter)
    use strict named arg -- none

    self~resetPos
    startB = fulltext~indexer~characterIndexB(startC)
    if startC == 1, lengthC == fulltext~length then xSubtext = fulltext
    else xSubtext = fulltext~substr(startC, lengthC, pad)
    iSubtext = .nil -- default value, until a transformation is applied
    backupCount = 0
    transformed = .false


::method transform
    expose xSubtext iSubtext -
           normalization casefold lump stripIgnorable stripMark stripCC stripNA -
           transformed
    use strict named arg normalization = 1, casefold = .false, lump= .false, stripMark = .false, stripIgnorable= .false, stripCC = .false, stripNA = .false, memorize = (.Unicode~memorizeTransformations)

    if transformed then raise syntax 93.900 array(self~class~id || ": A transformation has already been applied")
    iSubtext = xSubtext~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :memorize) -- Remember: can't use returnString:.true, the result MUST be a RexxText
    transformed = .true
    self~resetPos
    return self -- yes, self, not iSubtext


::method resetPos
    expose /*xSubtextPosB*/  xSubtextPosC  iSubtextPosB  /*iSubtextPosC*/  previousPosB
    use strict arg -- none
    -- xSubtextPosB = 1
    xSubtextPosC = 1
    iSubtextPosB = 1
    -- iSubtextPosC = 1
    previousPosB = 0


::method backupPos
    -- one backup at most, I don't need a stack
    expose /*xSubtextPosB*/  xSubtextPosC  iSubtextPosB  /*iSubtextPosC*/  previousPosB  -
           /*xSubtextPosB_*/ xSubtextPosC_ iSubtextPosB_ /*iSubtextPosC_*/ previousPosB_ -
           backupCount
    use strict arg -- none
    if backupCount == 1 then raise syntax 93.900 array(self~class~id || ": the backup stack is full")
    xSubtextPosC_ = xSubtextPosC
    -- xSubtextPosB_ = xSubtextPosB
    -- iSubtextPosC_ = iSubtextPosC
    iSubtextPosB_ = iSubtextPosB
    previousPosB_ = previousPosB
    backupCount += 1


::method restorePos
    expose /*xSubtextPosB*/  xSubtextPosC  iSubtextPosB  /*iSubtextPosC*/  previousPosB  -
           /*xSubtextPosB_*/ xSubtextPosC_ iSubtextPosB_ /*iSubtextPosC_*/ previousPosB_ -
           backupCount previousPosB
    use strict arg -- none
    if backupCount == 0 then raise syntax 93.900 array(self~class~id || ": the backup stack is empty")
    xSubtextPosC = xSubtextPosC_
    -- xSubtextPosB = xSubtextPosB_
    -- iSubtextPosC = iSubtextPosC_
    iSubtextPosB = iSubtextPosB_
    previousPosB = previousPosB_
    backupCount -= 1


::method ib2xc
    expose,
        startB startC -
        xSubtext /*xSubtextPosB*/ xSubtextPosC -
        iSubtext iSubtextPosB /*iSubtextPosC*/ -
        normalization casefold lump stripIgnorable stripMark stripCC stripNA -
        previousPosB transformed

    use strict arg posB
    use strict named arg aligned=.true, debug=.false
if debug then do
    say "--- Enter ib2xc ----"
    say "arg posB=" posB
end

    if \transformed then raise syntax 93.900 array(self~class~id || ": You must apply a transformation before using the 'ib2xc' method")
    if posB < previousPosB then raise syntax 93.900 array(self~class~id || ": You specified a byte position ("posB") lower than the previous one ("previousPosB")")
    previousPosB = posB

    posC = iSubtext~indexer~characterIndexC(posB) -- posC can be negative if posB is not aligned with a character position
    absposC = abs(posC)
if debug then do
    say "posC in iSubtext =" posC
end

    do while xSubtextPosC <= xSubtext~length
        if iSubtextPosB == posB then do
if debug then do
            say "exactly reached"
end
            leave
        end
        c = xSubtext~character(xSubtextPosC)
        cTransformed = c~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, memorize:.false, returnString:.true) -- yes, don't memorize, it's just a character
if debug then do
        call charout , xSubtextPosC
        -- call charout , "    " xSubtextPosB
        call charout , "    c =" c~string~quoted
        call charout , "    cTransformed =" cTransformed~string~quoted
        -- call charout , "    iSubtextPosC =" iSubtextPosC
        call charout , "    iSubtextPosB =" iSubtextPosB
        say
end
        -- iSubtextPosC += cTransformed~length
        iSubtextPosB += cTransformed~string~length
        xSubtextPosC += 1
        -- xSubtextPosB += c~string~length
if debug then do
        call charout , "xSubtextPosC =" xSubtextPosC
        -- call charout , "    xSubtextPosB =" xSubtextPosB
        -- call charout , "    iSubtextPosC =" iSubtextPosC
        call charout , "    iSubtextPosB =" iSubtextPosB
        say
end

        if 0 /*iSubtextPosC > absposC*/,
           |,
           iSubtextPosB > posB,
        then do
            /*
            Case where the start or end of the matching does not cover all
            the bytes of the transformed grapheme.
            Ex:
            - "ß"~text~caselessPos("s") --> 0, not 1 because 1 would match
              only the first byte of "ß"-->"ss"
            - "sß"~text~caselessPos("ss") --> 2, not 1 because 1 would match
              only the first byte of "ß"-->"ss"
            */

            -- force posC to be negative, to indicate that the matching is not
            -- aligned.
            posC = -absPosC

            -- undo the last progression
            -- iSubtextPosC -= cTransformed~length
            iSubtextPosB -= cTransformed~string~length
            xSubtextPosC -= 1
            -- xSubtextPosB -= c~string~length
if debug then do
            say "force posC to be negative =" posC
end
            leave
        end
    end -- of do while
if debug then do
    say "xSubtextPosC =" xSubtextPosC
    -- say "xSubtextPosB =" xSubtextPosB
    -- say "iSubtextPosC =" iSubtextPosC
    say "iSubtextPosB =" iSubtextPosB
end

    -- so far, we have relative positions, calculate the global positions
    posB = startB - 1 + posB
    posC = sign(posC) * (startC - 1 + xSubtextPosC)
    absposC = abs(posC)
if debug then do
    say "startC =" startC
    say "startB =" startB
    say "external global posC =" posC
    say "internal global posB =" posB
end

    if aligned then do
        if posC < 0 then do
            -- aligned match requested, but byte position not aligned with
            -- character ==> no match
            posC = .nil
        end
    end
    else do
        if posC < 0 then do
            -- "-"(character index)".'(byte index)
            posC = "-"absposC"."posB
        end
        else do
            -- "+"(character index)".'(byte index)
            posC = "+"absposC"."posB
        end
    end
if debug then do
say "--- Leave ib2xc ----"
end
    return posC


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
::class "CharacterSupplier" public subclass Supplier

::method init
    expose indexer indexC
    use strict arg indexer
    empty = .array~new(0) -- No need to create a copy, the string is immutable
    self~init:super(empty, empty)
    indexC = 1
    -- self~init:super -- Don't forward, would raise error "argument 1 is required"


::method count
    expose indexer
    use strict arg -- none
    return indexer~characterCount


::method available
    expose indexer indexC
    use strict arg -- none
    return indexC <= indexer~characterCount


::method index
    expose indexC
    use strict arg -- none
    if self~available then return indexC


::method item
    expose indexer indexC
    use strict arg -- none
    if self~available then return indexer~character(indexC)


::method next
    expose indexC
    use strict arg -- none
    indexC += 1


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
    use strict named arg buffer=.nil
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


::routine replacementCodepoint public
    use strict arg replacementCharacter, targetEncoding
    -- replacementCharacter: text made of 1 codepoint max or .nil or "".
    -- A replacementCharacter of type UnicodeCharacter is supported.
    -- if .nil then will raise an error if a character can't be converted
    -- otherwise if not "" then will be used in replacement of a character that can't be converted
    -- otherwise any character that can't be converted will be ignored
    -- Note:
    -- There is no attempt to support a replacementCharacter of type whole number or hexadecimal.
    replacementCodepoint = replacementCharacter
    if .nil \== replacementCharacter, "" \== replacementCharacter then do
        if replacementCharacter~isA(.UnicodeCharacter) then transcodedReplacementCharacter = replacementCharacter~transcodeTo(targetEncoding)
        else do
            replacementCharacterText = replacementCharacter~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
            if .nil == replacementCharacterText then signal invalid_replacement_character
            targetEncoding = .encoding~factory(targetEncoding, replacementCharacterText~string)
            errorInfo = .array~new -- simulate a variable by reference
            transcodedReplacementCharacter = replacementCharacterText~transcodeTo(targetEncoding, :errorInfo)
            if .nil == transcodedReplacementCharacter then signal cannot_transcode_replacement_character
        end
        codepoints = transcodedReplacementCharacter~codepoints
        if codepoints~count > 1 then signal invalid_transcoded_replacement_character -- one codepoint max
        replacementCodepoint = codepoints~item -- first codepoint
    end
    return replacementCodepoint

    invalid_replacement_character:              raise syntax 93.900 array("The replacement character must be a text or string or UnicodeCharacter")
    cannot_transcode_replacement_character:     raise syntax 93.900 array("The replacement character" replacementCharacter~descriptionForError "cannot be transcoded to" targetEncoding~name)
    invalid_transcoded_replacement_character:   raise syntax 23.900 array("The transcoded replacement character must have at most one codepoint, got" transcodedReplacementCharacter~descriptionForError(short: .false))
