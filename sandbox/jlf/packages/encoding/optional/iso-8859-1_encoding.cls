-- ISO-8859-1 (Western Europe)
-- https://en.wikipedia.org/wiki/ISO/IEC_8859-1
--  iso-ir-100, csISOLatin1, latin1, l1, IBM819. Code page 28591 a.k.a. Windows-28591 is used for it in Windows.[9] IBM calls it code page 819 or CP819 (CCSID 819).[10][11][12][13] Oracle calls it WE8ISO8859P1.[14]
-- https://docs.python.org/3/library/codecs.html#standard-encodings
--  iso-8859-1, iso8859-1, 8859, cp819, latin, latin1, L1
.encoding~register("819", .ISO88591_Encoding)
.encoding~register("8859", .ISO88591_Encoding)
.encoding~register("28591", .ISO88591_Encoding)
.encoding~register("CP819", .ISO88591_Encoding)
.encoding~register("CSISOLATIN1", .ISO88591_Encoding)
.encoding~register("IBM819", .ISO88591_Encoding)
.encoding~register("ISO88591", .ISO88591_Encoding)
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


::attribute tableTranscodingToUnicode class get


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
        Given the comments found in ICU, I decide to consider that any character
        of a string encoded as iso-8859-1 is converted directly to Unicode by
        using Unicode codepoint = character code.
        So replacing "" by "=" everywhere in the table below, using a variable in case I need to rollback.
    */
    expose tableTranscodingToUnicode
    use strict arg -- none
    undef = "="     -- supported, equal to itself
    -- undef = ""   -- not supported
    specificTranscoding =,
        , --    00      01      02      03      04      05      06      07      08      09      0A      0B      0C      0D      0E      0F
        "00:",  "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",,
        "10:",  "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",,
        "7F:",                                                                                                                          "=",,
        "80:",  "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",,
        "90:",  "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "=",    "="
    tableTranscodingToUnicode = createCharacterTranscodingTable(256, specificTranscoding)

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

