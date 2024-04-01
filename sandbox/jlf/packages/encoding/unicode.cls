.Unicode~initialize

/*
The Unicode class is native, so available everywhere, without requiring "unicode.cls".
The UnicodeCharacter class is not native, so .UnicodeCharacter is defined only when requiring "unicode.cls".
Because of circular dependencies, it's not always possible to require "unicode.cls".
That's why I put the UnicodeCharacter class in the global environment.
First need: byte_encoding.cls needs to test if the replacement character is a .UnicodeCharacter.
*/
.environment["UNICODECHARACTER"] = .UnicodeCharacter


::requires "encoding/stringIndexer.cls"
::requires "encoding/unicode8_encoding.cls"
::requires "encoding/unicode16_encoding.cls"
::requires "encoding/unicode32_encoding.cls"
::requires "encoding/utf8_encoding.cls"
::requires "encoding/utf16_encoding.cls"
::requires "encoding/utf32_encoding.cls"
::requires "encoding/wtf8_encoding.cls"
::requires "encoding/wtf16_encoding.cls"

-- ::options trace i

/*
Depends on
.UNICODE16_ENCODING
.UNICODE32_ENCODING
.UNICODE8_ENCODING
.UNICODEN_ENCODING
.UTF16BE_ENCODING
.UTF16LE_ENCODING
.UTF32BE_ENCODING
.UTF32LE_ENCODING
.UTF8_ENCODING
.WTF16BE_ENCODING
.WTF16LE_ENCODING
.WTF8_ENCODING
*/


/******************************************************************************/
::extension "Unicode"

/* Native methods
    RexxString *utf8proc_version();
    RexxInteger *utf8proc_graphemeBreak(RexxArray *);
    RexxInteger *utf8proc_codepointCategory(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointCombiningClass(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointBidiClass(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointBidiMirrored(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointDecompositionType(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointIgnorable(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointControlBoundary(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointCharWidth(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointBoundClass(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointToLowerSimple(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointToUpperSimple(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointToTitleSimple(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointIsLower(RexxObject *rexxCodepoint);
    RexxInteger *utf8proc_codepointIsUpper(RexxObject *rexxCodepoint);
    RexxObject *utf8proc_transform(RexxString *str, RexxObject **named_arglist, size_t named_argcount);

    RexxString *unialgo_version();
*/


::constant maxCodepoint 1114111
::constant characterIndexOffset 1 -- +1 because index 0 must be supported.

-- Code to pass to utf8proc_transform with the named argument normalization:
::constant NFC 1
::constant NFD 2
::constant NFKC 3
::constant NFKD 4

::method normalizationName class
    expose normalizationNames
    use strict arg normalization
    -- wonder why I do that instead of a simple test of the 4 possible values here?
    -- just because I think it's better to have the same approach as the other xxxName methods.
    return normalizationNames[normalization]

::method defaultNormalization class
    use named arg strict=.true
    if strict then return .Unicode~NFC
    -- not strict
    -- for experimentation, no idea if this is the right choice
    return .Unicode~NFKD


::attribute dataDirectory get class
::attribute totalCharactersLoaded get class
::attribute totalIntervalCharacters get class
::attribute totalIntervalCharactersNotExpanded get class
::attribute totalCharacterNameAliases get class
::attribute normalizationNames get class
::attribute codepointCategoryNames get class
::attribute codepointBidiClassNames get class
::attribute codepointDecompositionTypeNames get class
::attribute codepointBoundClassNames get class
::attribute memorizeTranscodings class -- global flag to control if the results of ~transcodeTo are memorized on the text
::attribute memorizeTransformations class -- global flag to control if the NFC, NFD, ... transformtions are memorized on the text
::attribute unckeckedConversionToString class

::method initialize class
    expose dataDirectory characters characterNames -
                         characterIntervals characterIntervalNames -
                         totalCharactersLoaded -
                         totalIntervalCharacters -
                         totalIntervalCharactersNotExpanded -
                         totalCharacterNameAliases -
                         memorizeTranscodings -
                         memorizeTransformations -
                         unckeckedConversionToString
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
    memorizeTranscodings = .false
    memorizeTransformations = .false
    unckeckedConversionToString = .true


::method version class
    return .Unicode~utf8proc_version


::method informations class
    messages = ,
    "characters",,
    "characterIntervals",,
    "dataDirectory",,
    "maxCodepoint",,
    "memorizeTranscodings",,
    "memorizeTransformations",,
    "systemIsLittleEndian",,
    "totalCharactersLoaded",,
    "totalCharacterNameAliases",,
    "totalIntervalCharacters",,
    "totalIntervalCharactersNotExpanded",,
    "unckeckedConversionToString",,
    "version"
    informations = .directory~new
    do message over messages
        value = self~send(message)
        informations~put(value, message)
    end

    return informations


::method checkCodepoint class
    use strict arg codepoint, name=.nil
    if codepoint < -1 | codepoint > .Unicode~maxCodepoint then signal error_range
    return .true

    error_range:
    -- To be consistent with other checks, say the lower limit is 0, even if -1 is a valid value
    if .nil <> name then raise syntax 23.900 array ("Character '"name"': invalid codepoint" codepoint "("ppCodepoint(codepoint)"). Allowed range is 0..".Unicode~maxCodepoint)
                    else raise syntax 23.900 array ("Invalid codepoint" codepoint "("ppCodepoint(codepoint)"). Allowed range is 0..".Unicode~maxCodepoint)

::method declareConstantNames class
    expose normalizationNames codepointCategoryNames codepointBidiClassNames codepointDecompositionTypeNames codepointBoundClassNames
    normalizationNames = .array~new
    codepointCategoryNames = .array~new
    codepointBidiClassNames = .array~new
    codepointDecompositionTypeNames = .array~new
    codepointBoundClassNames = .array~new
    methods = self~methods
    do while methods~available
        methodName = methods~index
        if methodName == "NFC" then normalizationNames[self~NFC] = "NFC"
        if methodName == "NFD" then normalizationNames[self~NFD] = "NFD"
        if methodName == "NFKC" then normalizationNames[self~NFKC] = "NFKC"
        if methodName == "NFKD" then normalizationNames[self~NFKD] = "NFKD"
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
    expose characters characterNames
    use strict arg filter=.nil
    if .nil <> filter then do
        -- questionable: what's the best way to pass options to ~matcher?
        -- here, I pass ALL the named arguments
        -- I must explicitly pass NO positional argument.
        forward message "matcher" arguments (.array~new(0)) to (UAX44_LM2(filter)) continue
        looseMatcher = result
        return characterNames~each{ expose looseMatcher; if looseMatcher~(index) then .Unicode~character(item) }
    end
    return .UnicodeCharacterSupplier~new(characters) -- This supplier returns index-1


::method "[]" class
    forward message "character"


::method character class
    expose characters characterNames
    use strict arg name
    use named arg by="DFHLNU", hexadecimal=.false -- can't be guessed: 100 in hexadecimal is different from 100 in decimal

    name = name~strip

    -- is name an hexadecimal codepoint ?
    if by~caselessContains("H"), hexadecimal then do
        call remove_leading_zeros
        if name~length <= 8, datatype(name, "X") then do
            numeric digits 10 -- to support FFFFFFFF, even if way too big for a codepoint (will be checked by characterByCodepoint)
            return self~characterByCodepoint(name~x2d)
        end
        signal invalid_hexadecimal_codepoint
    end

    -- is name a decimal codepoint ?
    if by~caselessContains("D"), datatype(name, "W") then do
        call remove_leading_zeros
        if name~length <= 7 then return self~characterByCodepoint(name)
        signal invalid_decimal_codepoint
    end

    -- is name a U+ codepoint ?
    if by~caselessContains("U"), name~caselessStartsWith("U+") then do
        name = name~substr(3)
        if name~length >= 4, name~length <= 6, datatype(name, "X") then do
            return self~characterByCodepoint(name~x2d)
        end
        signal invalid_u_plus
    end

    -- is name a character name?
    if by~caselessContains("N") then do
        looseMatchingIndex = UAX44_LM2(name)
        codepoint = characterNames[looseMatchingIndex]
        if .nil <> codepoint then return characters[self~characterIndexOffset + codepoint]
    end

    -- is name a code point label?
    /*
    code point labels are constructed by using a lowercase prefix derived from the code point type,
    followed by a hyphen-minus and then a 4- to 6-digit hexadecimal representation of the code point.
        Control         control-NNNN
        Reserved        reserved-NNNN
        Noncharacter    noncharacter-NNNN
        Private-Use     private-use-NNNN
        Surrogate       surrogate-NNNN
    U+0008 label is <control-0008>
    */
    if by~caselessContains("L"), name~left(1) == "<", name~right(1) == ">", name~pos(" ") == 0 then do
        hyphenPos = name~lastPos("-")
        if hyphenPos \== 0 then do
            parse var name "<" type =(hyphenPos) "-" hex ">"
            if "control reserved noncharacter private-use surrogate"~wordPos(type) \== 0,,
               hex~length >= 4, hex~length <= 6,,
               hex~datatype("X"),
            then do
                return self~characterByCodepoint(hex~x2d)
            end
        end
    end

    -- fallback: if the name is made of just one codepoint then search this codepoint
    if by~caselessContains("F") then do
        codepoints = name~text~codepoints
        if codepoints~count == 1 then return self~characterByCodepoint(codepoints~item)
        if name~text~length == 1 then signal character_made_of_several_codepoints
    end

    signal name_not_found

    remove_leading_zeros:
        firstNonZero = name~verify("0")
        if firstNonZero == 0 then name = "0" -- 0[..0] replaced by 0
        else if firstNonZero > 1 then name = name~substr(firstNonZero) -- remove all the leading zeros
        return

    invalid_hexadecimal_codepoint:          raise syntax 93.900 array("an hexadecimal codepoint is 1..8 hex digits, got '"name"'")
    invalid_decimal_codepoint:              raise syntax 93.900 array("a decimal codepoint is 1..7 digits, got '"name"'")
    invalid_u_plus:                         raise syntax 93.900 array("Expected U+ or u+ followed by 4..6 hex digits, got '"name"'")
    character_made_of_several_codepoints:   raise syntax 93.900 array("The character '"name"' is made of several codepoints:" name~text~c2u)
    name_not_found:                         raise syntax 93.900 array("Name '"name"' not found")


::method characterByCodepoint class
    expose characters
    use strict arg codepoint
    self~checkCodepoint(codepoint)
    character = characters[self~characterIndexOffset + codepoint]
    if .nil == character  then do
        character = .UnicodeCharacter~new(codepoint)
        if character~category \== .Unicode~CATEGORY_CN then characters[self~characterIndexOffset + codepoint] = character
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
    category = self~utf8proc_codepointCategory(codepoint)
    return codepointCategoryNames[1+category]


-- Values returned by .Unicode~utf8proc_codepointCategory(codepoint)
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
    bidiClass = self~utf8proc_codepointBidiClass(codepoint)
    return codepointBidiClassNames[bidiClass]


-- Values returned by .Unicode~utf8proc_codepointBidiClass(codepoint)
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


-- https://unicode.org/reports/tr15/
::method codepointDecompositionTypeName class
    expose codepointDecompositionTypeNames
    use strict arg codepoint
    decompositionType = self~utf8proc_codepointDecompositionType(codepoint)
    return codepointDecompositionTypeNames[1 + decompositionType]


-- Values returned by .Unicode~utf8proc_codepointDecompositionType(codepoint)
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


-- https://unicode.org/reports/tr29/
::method codepointBoundClassName class
    expose codepointBoundClassNames
    use strict arg codepoint
    boundClass = self~utf8proc_codepointBoundClass(codepoint)
    return codepointBoundClassNames[1+boundClass]


-- Grapheme_Cluster_Break (GCB)
-- Values returned by .Unicode~utf8proc_codepointBoundClass(codepoint)
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


-- return 1..n codepoints in decimal, or .nil
::method codepointToLowerFull class
    use strict arg codepoint
    return .nil -- todo


-- return 1..n codepoints in decimal, or .nil
::method codepointToUpperFull class
    use strict arg codepoint
    return .nil -- todo


-- return 1..n codepoints in decimal, or .nil
::method codepointToTitleFull class
    use strict arg codepoint
    return .nil -- todo


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
    encoding = .Encoding~factory(encoding, maximumUnicodeCodepoint: codepoint)
    if codepoint < 32 then string = "" -- the control characters are not displayed
                      else string = encoding~encode(codepoint)~string
    string = '"'string'"' " "~copies(3 - self~charWidth)
    string ||= ppCodepoint(codepoint) self~categoryName self~charWidth name~quoted
    string = ", "~join(string, aliases~each{item~string~quoted})
    return " "string" " -- TODO: can't remember why I add spaces like that... To remove?


::method setName -- should be package-scope
    expose name
    use strict arg name


::method transcodeTo
    use strict arg targetEncoding
    -- no need to declare the named arguments, they are forwarded
    forward message "transcodeTo" to (self~UnicodeN) arguments ( .array~of(targetEncoding) )


::method UTF8
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .UTF8_Encoding~encode(codepoint, :buffer)


::method WTF8
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .WTF8_Encoding~encode(codepoint, :buffer)


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .UTF16BE_Encoding~encode(codepoint, :buffer)


::method UTF16LE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .UTF16LE_Encoding~encode(codepoint, :buffer)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .WTF16BE_Encoding~encode(codepoint, :buffer)


::method WTF16LE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .WTF16LE_Encoding~encode(codepoint, :buffer)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .UTF32BE_Encoding~encode(codepoint, :buffer)


::method UTF32LE
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .UTF32LE_Encoding~encode(codepoint, :buffer)


::method Unicode
    forward message "UnicodeN"


::method UnicodeN
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    targetEncoding = .UnicodeN_Encoding~toSupport(codepoint)
    return targetEncoding~encode(codepoint, :buffer)


::method Unicode8
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .Unicode8_Encoding~encode(codepoint, :buffer)


::method Unicode16
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .Unicode16_Encoding~encode(codepoint, :buffer)


::method Unicode32
    expose codepoint
    use strict arg -- none
    use strict named arg buffer=.nil
    return .Unicode32_Encoding~encode(codepoint, :buffer)


-- http://www.unicode.org/reports/tr44/#General_Category_Values
::method category
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointCategory(codepoint)


-- http://www.unicode.org/reports/tr44/#General_Category_Values
::method categoryName
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointCategoryName(codepoint)


-- http://www.unicode.org/reports/tr44/#Canonical_Combining_Class_Values
::method combiningClass
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointCombiningClass(codepoint)


-- http://www.unicode.org/reports/tr44/#Bidi_Class_Values
::method bidiClass
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointBidiClass(codepoint)


-- http://www.unicode.org/reports/tr44/#Bidi_Class_Values
::method bidiClassName
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointBidiClassName(codepoint)


-- https://unicode.org/reports/tr9/
::method bidiMirrored
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointBidiMirrored(codepoint)


-- https://unicode.org/reports/tr15/
::method decompositionType
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointDecompositionType(codepoint)


-- https://unicode.org/reports/tr15/
::method decompositionTypeName
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointDecompositionTypeName(codepoint)


-- http://www.unicode.org/review/pr-5.html
-- http://unicode.org/L2/L2002/02368-default-ignorable.html
::method ignorable
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointIgnorable(codepoint)


-- http://unicode.org/reports/tr29/tr29-6.html
::method controlBoundary
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointControlBoundary(codepoint)


::method charWidth
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointCharWidth(codepoint)


-- https://unicode.org/reports/tr29/
::method boundClass
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointBoundClass(codepoint)


-- https://unicode.org/reports/tr29/
::method boundClassName
    expose codepoint
    use strict arg -- none
    return .Unicode~codepointBoundClassName(codepoint)


-- Simple case mappings in UnicodeData.txt, returns a single codepoint
::method toLowerSimple
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointToLowerSimple(codepoint)


-- Full case mappings in SpecialCasing.txt, returns 1..n codepoints
::method toLowerFull
    expose codepoint
    use strict arg -- none
    lowerFull = .Unicode~codepointToLowerFull(codepoint)
    if .nil \== lowerFull then return lowerFull
    return .Unicode~utf8proc_codepointToLowerSimple(codepoint)


-- Simple case mappings in UnicodeData.txt, returns a single codepoint
::method toUpperSimple
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointToUpperSimple(codepoint)


-- Full case mappings in SpecialCasing.txt, returns 1..n codepoints
::method toUpperFull
    expose codepoint
    use strict arg -- none
    upperFull = .Unicode~codepointToUpperFull(codepoint)
    if .nil \== upperFull then return upperFull
    return .Unicode~utf8proc_codepointToUpperSimple(codepoint)


-- Simple case mappings in UnicodeData.txt, returns a single codepoint
::method toTitleSimple
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointToTitleSimple(codepoint)


-- Full case mappings in SpecialCasing.txt, returns 1..n codepoints
::method toTitleFull
    expose codepoint
    use strict arg -- none
    titleFull = .Unicode~codepointToTitleFull(codepoint)
    if .nil \== titleFull then return titleFull
    return .Unicode~utf8proc_codepointToTitleSimple(codepoint)


::method isLower
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointIsLower(codepoint)


::method isUpper
    expose codepoint
    use strict arg -- none
    return .Unicode~utf8proc_codepointIsUpper(codepoint)


::method properties class
    -- TODO: align with UCD PropertyAliases.txt
    expose properties
    if \ var("properties") then properties =,
        "aliases",,
        "bidiClass",,
        "bidiClassName",,
        "bidiMirrored",,
        "boundClass",,
        "boundClassName",,
        "category",,
        "categoryName",,
        "charWidth",,
        "codepoint",,
        "combiningClass",,
        "controlBoundary",,
        "decompositionTypeName",,
        "decompositionType",,
        "ignorable",,
        "isLower",,
        "isUpper",,
        "name",,
        "toLowerFull",,
        "toLowerSimple",,
        "toTitleFull",,
        "toTitleSimple",,
        "toUpperFull",,
        "toUpperSimple",,
        "Unicode",,
        "UTF16BE",,
        "UTF16LE",,
        "UTF32BE",,
        "UTF32LE",,
        "UTF8"
    return properties


::method propertiesSpecialDisplay class
    expose specialDisplay
    if \ var("specialDisplay") then specialDisplay = .Directory~of(,
        "codepoint",       {arg(1)~Unicode~c2u},,
        "toLowerFull",     {.unicode[arg(1)~toLowerFull]~unicode~c2u},,
        "toLowerSimple",   {.unicode[arg(1)~toLowerSimple]~unicode~c2u},,
        "toTitleFull",     {.unicode[arg(1)~toTitleFull]~unicode~c2u},,
        "toTitleSimple",   {.unicode[arg(1)~toTitleSimple]~unicode~c2u},,
        "toUpperFull",     {.unicode[arg(1)~toUpperFull]~unicode~c2u},,
        "toUpperSimple",   {.unicode[arg(1)~toUpperSimple]~unicode~c2u},,
        "Unicode",         {"0x"arg(1)~Unicode~c2x},,
        "UTF16BE",         {"0x"arg(1)~UTF16BE~c2x},,
        "UTF16LE",         {"0x"arg(1)~UTF16LE~c2x},,
        "UTF32BE",         {"0x"arg(1)~UTF32BE~c2x},,
        "UTF32LE",         {"0x"arg(1)~UTF32LE~c2x},,
        "UTF8",            {"0x"arg(1)~UTF8~c2x},,
        )
    return specialDisplay


::method properties
    properties = .directory~new
    do property over self~class~properties
        specialDisplay = self~class~propertiesSpecialDisplay[property]
        if .nil \== specialDisplay then value = specialDisplay~(self)
        else value = property~(self)
        properties~put(value, property)
    end
    return properties


::method "[]" class
    forward message "character" to (.Unicode)


::routine .UnicodeCharacter public
    -- For convenience: equivalent to .Unicode~character
    return .Unicode~sendWith("character", .context~args, namedArguments: .context~namedArgs)


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
    -- The goal is to have index == codepoint
    if self~available then return index - .Unicode~characterIndexOffset -- yes, to support 0, all the indexes are +1.


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
    use strict arg -- none
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
