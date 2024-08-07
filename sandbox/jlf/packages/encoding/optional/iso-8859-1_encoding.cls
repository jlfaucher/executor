-- ISO-8859-1 (Western Europe)
-- https://en.wikipedia.org/wiki/ISO/IEC_8859-1
--  iso-ir-100, csISOLatin1, latin1, l1, IBM819. Code page 28591 a.k.a. Windows-28591 is used for it in Windows.[9] IBM calls it code page 819 or CP819 (CCSID 819).[10][11][12][13] Oracle calls it WE8ISO8859P1.[14]
-- https://docs.python.org/3/library/codecs.html#standard-encodings
--  iso-8859-1, iso8859-1, 8859, cp819, latin, latin1, L1
-- chcp 28591
.encoding~register("819", .ISO88591_Encoding)
.encoding~register("8859", .ISO88591_Encoding)
.encoding~register("88591", .ISO88591_Encoding)             -- alias defined in Java (8859_1)
.encoding~register("28591", .ISO88591_Encoding)
.encoding~register("CP819", .ISO88591_Encoding)
.encoding~register("CSISOLATIN1", .ISO88591_Encoding)
.encoding~register("IBM819", .ISO88591_Encoding)
.encoding~register("ISO88591", .ISO88591_Encoding)
.encoding~register("ISO885911987", .ISO88591_Encoding)      -- alias defined in Java (ISO_8859-1:1987)
.encoding~register("ISOIR100", .ISO88591_Encoding)
.encoding~register("L1", .ISO88591_Encoding)
.encoding~register("LATIN", .ISO88591_Encoding)
.encoding~register("LATIN1", .ISO88591_Encoding)
.encoding~register("WE8ISO8859P1", .ISO88591_Encoding)
.encoding~register("WINDOWS28591", .ISO88591_Encoding)

::requires "encoding/byte_encoding.cls"
::requires "encoding/encoding.cls"

/******************************************************************************/
::class "ISO88591_Encoding" subclass Byte_Encoding public

::constant name "ISO-8859-1"


-- keep these declarations! inheritance from Byte_Encoding is not enough
::attribute tableTranscodingToUnicode class get
::attribute tableTranscodingFromUnicode class get


::method activate class
    -- https://en.wikipedia.org/wiki/ISO/IEC_8859-1#Code_page_layout
    -- TODO: It's not clear to me if I should follow the rule below, i.e. returning the CP1252 characters 128 to 159.
    /*
        https://www.w3schools.com/charsets/
            When a browser detects ISO-8859-1 it normally defaults to Windows-1252, because
            Windows-1252 has 32 more international characters.
        https://www.w3schools.com/charsets/ref_html_8859.asp
            ISO-8859-1 is very similar to Windows-1252.
            In ISO-8859-1, the characters from 128 to 159 are not defined.
            In Windows-1252, the characters from 128 to 159 are used for some useful symbols.
            Since many web sites declare ISO-8859-1 and use the values from 128 to 159 as if
            they were using Windows-1252, most browsers will display these characters from
            the Windows-1252 character set instead of nothing.
    */
    /*
        2023.06.28
        https://unicode-org.github.io/icu/userguide/conversion/ (search ISO-8859-1)
        Given the comments found in ICU, I decide to consider that any character
        of a string encoded as iso-8859-1 is converted directly to Unicode by
        using Unicode codepoint = character code.
        So replacing "" by "=" everywhere in the table below, using a variable in case I need to rollback.
    */
    /*
        2023.07.14
        The previous decision looks good when reading that:
        https://en.wikipedia.org/wiki/ISO/IEC_8859-1
        In 1992, the IANA registered the character map ISO_8859-1:1987, more
        commonly known by its preferred MIME name of ISO-8859-1 (note the extra
        hyphen over ISO 8859-1), a superset of ISO 8859-1, for use on the Internet.
        This map assigns the C0 and C1 control codes to the unassigned code values
        thus provides for 256 characters via every possible 8-bit value.
    */
    /*
        2023.08.20
        Hum... https://encoding.spec.whatwg.org/ defines iso-8859-1 as an alias of windows-1252
        So there is a BIG disagreement between IANA and encoding.spec.whatwg.org
        Confirmed by this sentence in the preface of https://encoding.spec.whatwg.org/:
        "User agents have also significantly deviated from the labels listed in
        the IANA Character Sets registry. To stop spreading legacy encodings
        further, this specification is exhaustive about the aforementioned
        details and therefore has no need for the registry."
        I decide to stick with ICU.
    */
    expose tableTranscodingToUnicode tableTranscodingFromUnicode
    use strict arg -- none
    code = "="     -- supported, equal to itself
    -- code = ""   -- not supported
    specificTranscoding =,
        , --    00      01      02      03      04      05      06      07      08      09      0A      0B      0C      0D      0E      0F
        "00:",  code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,,
        "10:",  code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,,
        "7F:",                                                                                                                          code,,
        "80:",  code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,,
        "90:",  code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code,   code
    tables = createCharacterTranscodingTable(256, specificTranscoding)
    tableTranscodingToUnicode = tables[1]
    tableTranscodingFromUnicode = tables[2]


::method stripMark class private
    use strict arg string
    buffer = .MutableBuffer~new(string)
    buffer~translate("AAAAAACEEEEIIII", "C0 C1 C2 C3 C4 C5 C7 C8 C9 CA CB CC CD CE CF"x)
    buffer~translate("NOOOOOOUUUUY", "D1 D2 D3 D4 D5 D6 D8 D9 DA DB DC DD"x)
    buffer~translate("aaaaaaceeeeiiii", "E0 E1 E2 E3 E4 E5 E7 E8 E9 EA EB EC ED EE EF"x)
    buffer~translate("noooooouuuuyy", "F1 F2 F3 F4 F5 F6 F8 F9 FA FB FC FD FF"x)
    return buffer~string


/*
https://github.com/unicode-org/icu/blob/main/icu4c/source/data/mappings/convrtrs.txt

    # Standard iso-8859-1, which does not have the Euro update.
    # See iso-8859-15 (latin9) for the Euro update
    ISO-8859-1 { MIME* IANA JAVA* }
        ibm-819 { IBM* JAVA }    # This is not truely ibm-819 because it's missing the fallbacks.
        IBM819 { IANA }
        cp819 { IANA JAVA }
        latin1 { IANA JAVA }
        8859_1 { JAVA }
        csISOLatin1 { IANA JAVA }
        iso-ir-100 { IANA JAVA }
        ISO_8859-1:1987 { IANA* JAVA }
        l1 { IANA JAVA }
        819 { JAVA }
        # windows-28591 { WINDOWS* } # This has odd behavior because it has the Euro update, which isn't correct.
        # LATIN_1     # Old ICU name
        # ANSI_X3.110-1983  # This is for a different IANA alias.  This isn't iso-8859-1.
*/

/*
https://github.com/unicode-org/icu/blob/main/icu4c/source/data/mappings/ucmcore.mk

    # Note: A number of encodings are handled with purely algorithmic converters,
    # without any mapping tables:
    # US-ASCII, ISO 8859-1, UTF-7/8/16/32, SCSU
    */

    /*
    https://github.com/unicode-org/icu/blob/main/icu4c/source/common/ucnv2022.cpp

    * Rules for ISO-2022-jp encoding
    <cut>
    *  source : RFC-1554
    *
    <cut>
    *          ISO-8859-1 : Algorithmic implemented as LATIN1 case
*/

/*
https://github.com/unicode-org/icu/blob/main/icu4c/source/common/ucnvlat1.cpp

    _Latin1ToUnicodeWithOffsets(UConverterToUnicodeArgs *pArgs,
                                UErrorCode *pErrorCode) {
    <cut>
        // conversion loop
        while(targetCapacity>0) {
            *target++=*source++;
            --targetCapacity;
        }
    <cut>

*/

