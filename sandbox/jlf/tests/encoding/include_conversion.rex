/*
Depends on:
t
*/

< include_conversion_to_utf8
< include_conversion_to_wtf8
< include_conversion_to_utf16be
< include_conversion_to_utf16le
< include_conversion_to_wtf16be
< include_conversion_to_wtf16le
< include_conversion_to_utf32be
< include_conversion_to_utf32le
< include_conversion_to_unicode
< include_conversion_to_unicode8
< include_conversion_to_unicode16
< include_conversion_to_unicode32


--------------------------------------------------------------------------------
-- some transformations to have a mixed cache
--------------------------------------------------------------------------------

t~nfc(mem:)=
t~nfd(mem:)=
t~nfkc(mem:)=
t~nfkd(mem:)=
t~casefold(mem:)=
