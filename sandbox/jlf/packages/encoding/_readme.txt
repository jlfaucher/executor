main package: stringEncoding.cls


================================================================================
Dependencies consolidated (all levels for the 1st occurence)
================================================================================

stringEncoding.cls                  <-- main package to require
    ibm-437_encoding.cls
        byte_encoding.cls
            byte_common.cls
            stringIndexer.cls
                string.cls
                cachedStrings.cls
            encoding.cls
                stringIndexer.cls
            string.cls -- for ppHexNumber
        encoding.cls
    ibm-1252_encoding.cls
        byte_encoding.cls
        encoding.cls
    windows-1252_encoding.cls
        byte_encoding.cls
        encoding.cls
    iso-8859-1_encoding.cls
        byte_encoding.cls
        encoding.cls
    unicode.cls
        stringIndexer.cls
        unicode8_encoding.cls
            encoding.cls
            unicodeN_encoding.cls
                encoding.cls
            unicode_common.cls
                stringIndexer.cls
                encoding.cls
            stringIndexer.cls
            byte_common.cls -- for atBytePosition
        unicode16_encoding.cls
            encoding.cls
            unicodeN_encoding.cls
            unicode_common.cls
            stringIndexer.cls
            byte_common.cls -- for atBytePosition
        unicode32_encoding.cls
            encoding.cls
            unicodeN_encoding.cls
            unicode_common.cls
            stringIndexer.cls
            byte_common.cls -- for atBytePosition
        utf8_encoding.cls
            encoding.cls
            byte_common.cls -- for atBytePosition, Byte_CommonServices
            utf8_common.cls
                string.cls
                cachedStrings.cls
            unicode_common.cls
            stringIndexer.cls
        utf16_encoding.cls
            encoding.cls
            utf16_common.cls
                unicode_common.cls
                byte_common.cls -- for atBytePosition
                stringIndexer.cls -- for ppCodepoint
            unicode_common.cls
            stringIndexer.cls
        utf32_encoding.cls
            encoding.cls
            unicode_common.cls
            stringIndexer.cls
            byte_common.cls -- for atBytePosition
        wtf8_encoding.cls
            encoding.cls
            byte_common.cls -- for atBytePosition, Byte_CommonServices
            utf8_common.cls
            unicode_common.cls
            stringIndexer.cls
        wtf16_encoding.cls
            encoding.cls
            utf16_common.cls
            unicode_common.cls
            stringIndexer.cls
            byte_common.cls -- for atBytePosition
    stringInterface.cls
        encoding.cls
        stringIndexer.cls


================================================================================
Dependencies (1st level only)
================================================================================

byte_common.cls


byte_encoding.cls
    byte_common.cls
    stringIndexer.cls
    encoding.cls
    string.cls


cachedStrings.cls


encoding.cls
    stringIndexer.cls


ibm-437_encoding.cls
    byte_encoding.cls
    encoding.cls


ibm-1252_encoding.cls
    byte_encoding.cls
    encoding.cls


iso-8859-1_encoding.cls
    byte_encoding.cls
    encoding.cls


stringEncoding.cls                  <-- main package to require
    --- optional
    ibm-437_encoding.cls
    ibm-1252_encoding.cls
    iso-8859-1_encoding.cls
    windows-1252_encoding.cls
    ---
    unicode.cls
    stringInterface.cls


stringIndexer.cls
    string.cls
    cachedStrings.cls


stringInterface.cls
    encoding.cls


unicode.cls
    stringIndexer.cls
    unicode8_encoding.cls
    unicode16_encoding.cls
    unicode32_encoding.cls
    utf8_encoding.cls
    utf16_encoding.cls
    utf32_encoding.cls
    wtf8_encoding.cls
    wtf16_encoding.cls


unicode_common.cls
    stringIndexer.cls
    encoding.cls


unicode8_encoding.cls
    encoding.cls
    unicodeN_encoding.cls
    unicode_common.cls
    stringIndexer.cls
    byte_common.cls -- for atBytePosition


unicode16_encoding.cls
    encoding.cls
    unicodeN_encoding.cls
    unicode_common.cls
    stringIndexer.cls
    byte_common.cls -- for atBytePosition


unicode32_encoding.cls
    encoding.cls
    unicodeN_encoding.cls
    unicode_common.cls
    stringIndexer.cls
    byte_common.cls -- for atBytePosition


unicodeN_encoding.cls
    encoding.cls


utf8_common.cls
    string.cls
    cachedStrings.cls


utf8_encoding.cls
    encoding.cls
    byte_common.cls
    utf8_common.cls
    unicode_common.cls
    stringIndexer.cls


utf16_common.cls
    unicode_common.cls
    byte_common.cls -- for atBytePosition
    stringIndexer.cls -- for ppCodepoint

utf16_encoding.cls
    encoding.cls
    utf16_common.cls
    unicode_common.cls
    stringIndexer.cls


utf32_encoding.cls
    encoding.cls
    unicode_common.cls
    stringIndexer.cls
    byte_common.cls -- for atBytePosition


windows-1252_encoding.cls
    byte_encoding.cls
    encoding.cls


wtf8_encoding.cls
    encoding.cls
    byte_common.cls
    utf8_common.cls
    unicode_common.cls
    stringIndexer.cls


wtf16_encoding.cls
    encoding.cls
    utf16_common.cls
    unicode_common.cls
    stringIndexer.cls
    byte_common.cls -- for atBytePosition
