/*
Depends on:
t
*/

--------------------------------------------------------------------------------
-- to utf8
--------------------------------------------------------------------------------

< include_conversion_infos s/$(text)/t/
drop utf8
utf8 = t~utf8(mem:)
< include_conversion_infos s/$(text)/utf8/
t~utf8~"==":.object(utf8)=                      -- 1

< include_conversion_mutablebuffers.rex

t~utf8(b: mb)
mb~encoding=                                    -- utf8

t~utf8(b: mb_utf8)
mb_utf8~encoding=                               -- utf8

t~utf8(b: mb_wtf8)
mb_wtf8~encoding=                               -- wtf8

t~utf8(b: mb_utf16be)                           -- error (ok)
mb_utf16be~encoding=                            -- utf16be

t~utf8(b: mb_utf16le)                           -- error (ok)
mb_utf16le~encoding=                            -- utf16le

t~utf8(b: mb_wtf16be)                           -- error (ok)
mb_wtf16be~encoding=                            -- wtf16be

t~utf8(b: mb_wtf16le)                           -- error (ok)
mb_wtf16le~encoding=                            -- wtf16le

t~utf8(b: mb_utf32be)                           -- error (ok)
mb_utf32be~encoding=                            -- utf32be

t~utf8(b: mb_utf32le)                           -- error (ok)
mb_utf32le~encoding=                            -- utf32le

t~utf8(b: mb_unicode8)                          -- no error if t~isCompatibleWithASCII
mb_unicode8~encoding=                           -- unicode8

t~utf8(b: mb_unicode16)                         -- error (ok)
mb_unicode16~encoding=                          -- unicode16

t~utf8(b: mb_unicode32)                         -- error (ok)
mb_unicode32~encoding=                          -- unicode32
