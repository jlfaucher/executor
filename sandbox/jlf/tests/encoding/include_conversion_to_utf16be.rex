/*
Depends on:
t
*/

--------------------------------------------------------------------------------
-- to utf16be
--------------------------------------------------------------------------------

< include_conversion_infos s/$(text)/t/
drop utf16be
utf16be = t~utf16be(mem:)
< include_conversion_infos s/$(text)/utf16be/
t~utf16be~"==":.object(utf16be)=                -- 1

< include_conversion_mutablebuffers.rex

t~utf16be(b: mb)
mb~encoding=                                    -- utf16be

t~utf16be(b: mb_utf8)                           -- error (ok)
mb_utf8~encoding=                               -- utf8

t~utf16be(b: mb_wtf8)                           -- error (ok)
mb_wtf8~encoding=                               -- wtf8

t~utf16be(b: mb_utf16be)
mb_utf16be~encoding=                            -- utf16be

t~utf16be(b: mb_utf16le)                        -- error (ok)
mb_utf16le~encoding=                            -- utf16le

t~utf16be(b: mb_wtf16be)
mb_wtf16be~encoding=                            -- wtf16be

t~utf16be(b: mb_wtf16le)                        -- error (ok)
mb_wtf16le~encoding=                            -- wtf16le

t~utf16be(b: mb_utf32be)                        -- error (ok)
mb_utf32be~encoding=                            -- utf32be

t~utf16be(b: mb_utf32le)                        -- error (ok)
mb_utf32le~encoding=                            -- utf32le

t~utf16be(b: mb_unicode8)                       -- error (ok)
mb_unicode8~encoding=                           -- unicode8

t~utf16be(b: mb_unicode16)                      -- error (ok)
mb_unicode16~encoding=                          -- unicode16

t~utf16be(b: mb_unicode32)                      -- error (ok)
mb_unicode32~encoding=                          -- unicode32
