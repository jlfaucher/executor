/*
Depends on:
t
*/

--------------------------------------------------------------------------------
-- to unicode32
--------------------------------------------------------------------------------

unicode32 = t~unicode32(mem:)
unicode32~c2x=
t~unicode32~"==":.object(unicode32)=            -- 1

< include_conversion_mutablebuffers.rex

t~unicode32(b: mb_utf8)                         -- error (ok)
mb_utf8~encoding=                               -- utf8

t~unicode32(b: mb_wtf8)                         -- error (ok)
mb_wtf8~encoding=                               -- wtf8

t~unicode32(b: mb_utf16be)                      -- error (ok)
mb_utf16be~encoding=                            -- utf16be

t~unicode32(b: mb_utf16le)                      -- error (ok)
mb_utf16le~encoding=                            -- utf16le

t~unicode32(b: mb_wtf16be)                      -- error (ok)
mb_wtf16be~encoding=                            -- wtf16be

t~unicode32(b: mb_wtf16le)                      -- error (ok)
mb_wtf16le~encoding=                            -- wtf16le

t~unicode32(b: mb_utf32be)                      -- error (ok)
mb_utf32be~encoding=                            -- utf32be

t~unicode32(b: mb_utf32le)                      -- error (ok)
mb_utf32le~encoding=                            -- utf32le

t~unicode32(b: mb_unicode8)                     -- error (ok)
mb_unicode8~encoding=                           -- unicode8

t~unicode32(b: mb_unicode16)                    -- error (ok)
mb_unicode16~encoding=                          -- unicode16

t~unicode32(b: mb_unicode32)
mb_unicode32~encoding=                          -- unicode32
