/*
Depends on:
t
*/

--------------------------------------------------------------------------------
-- to utf32le
--------------------------------------------------------------------------------

utf32le = t~utf32le(mem:)
utf32le~c2x=
t~utf32le~"==":.object(utf32le)=                -- 1

< include_conversion_mutablebuffers.rex

t~utf32le(b: mb_utf8)                           -- error (ok)
mb_utf8~encoding=                               -- utf8

t~utf32le(b: mb_wtf8)                           -- error (ok)
mb_wtf8~encoding=                               -- wtf8

t~utf32le(b: mb_utf16be)                        -- error (ok)
mb_utf16be~encoding=                            -- utf16be

t~utf32le(b: mb_utf16le)                        -- error (ok)
mb_utf16le~encoding=                            -- utf16le

t~utf32le(b: mb_wtf16be)                        -- error (ok)
mb_wtf16be~encoding=                            -- wtf16be

t~utf32le(b: mb_wtf16le)                        -- error (ok)
mb_wtf16le~encoding=                            -- wtf16le

t~utf32le(b: mb_utf32be)                        -- error (ok)
mb_utf32be~encoding=                            -- utf32be

t~utf32le(b: mb_utf32le)
mb_utf32le~encoding=                            -- utf32le

t~utf32le(b: mb_unicode8)                       -- error (ok)
mb_unicode8~encoding=                           -- unicode8

t~utf32le(b: mb_unicode16)                      -- error (ok)
mb_unicode16~encoding=                          -- unicode16

t~utf32le(b: mb_unicode32)                      -- error (ok) even if same endianness
mb_unicode32~encoding=                          -- unicode32
