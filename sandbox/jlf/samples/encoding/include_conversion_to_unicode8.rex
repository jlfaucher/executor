/*
Depends on:
t
*/

--------------------------------------------------------------------------------
-- to unicode8
--------------------------------------------------------------------------------

unicode8 = t~unicode8(mem:)
unicode8~c2x=
t~unicode8~"==":.object(unicode8)=              -- 1

< include_conversion_mutablebuffers.rex

t~unicode8(b: mb_utf8)
mb_utf8~encoding=                               -- utf8

t~unicode8(b: mb_wtf8)
mb_wtf8~encoding=                               -- wtf8

t~unicode8(b: mb_utf16be)                       -- error (ok)
mb_utf16be~encoding=                            -- utf16be

t~unicode8(b: mb_utf16le)                       -- error (ok)
mb_utf16le~encoding=                            -- utf16le

t~unicode8(b: mb_wtf16be)                       -- error (ok)
mb_wtf16be~encoding=                            -- wtf16be

t~unicode8(b: mb_wtf16le)                       -- error (ok)
mb_wtf16le~encoding=                            -- wtf16le

t~unicode8(b: mb_utf32be)                       -- error (ok)
mb_utf32be~encoding=                            -- utf32be

t~unicode8(b: mb_utf32le)                       -- error (ok)
mb_utf32le~encoding=                            -- utf32le

t~unicode8(b: mb_unicode8)
mb_unicode8~encoding=                           -- unicode8

t~unicode8(b: mb_unicode16)                     -- error (ok)
mb_unicode16~encoding=                          -- unicode16

t~unicode8(b: mb_unicode32)                     -- error (ok)
mb_unicode32~encoding=                          -- unicode32