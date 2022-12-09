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
-- many aliases

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
    expose tableTranscodingToUnicode
    use strict arg -- none
    specificTranscoding =,
        , --        00      01      02      03      04      05      06      07      08      09      0A      0B      0C      0D      0E      0F
        "00:",      "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",,
        "10:",      "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",,
        "7F:",                                                                                                                              "",,
        "80:",      "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",,
        "90:",      "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     ""
    tableTranscodingToUnicode = createCharacterTranscodingTable(256, specificTranscoding)
