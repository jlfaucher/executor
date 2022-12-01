/*
Depends on:
t
*/

--------------------------------------------------------------------------------
-- to wtf16be
--------------------------------------------------------------------------------

< include_conversion_infos s/$(text)/t/
drop wtf16be
wtf16be = t~wtf16be(mem:)
< include_conversion_infos s/$(text)/wtf16be/
t~wtf16be~"==":.object(wtf16be)=                -- 1

< include_conversion_mutablebuffers.rex

t~wtf16be(b: mb_utf8)                           -- error (ok)
mb_utf8~encoding=                               -- utf8

t~wtf16be(b: mb_wtf8)                           -- error (ok)
mb_wtf8~encoding=                               -- wtf8

t~wtf16be(b: mb_utf16be)
mb_utf16be~encoding=                            -- wtf16be (yes, changed)

t~wtf16be(b: mb_utf16le)                        -- error (ok)
mb_utf16le~encoding=                            -- utf16le

t~wtf16be(b: mb_wtf16be)
mb_wtf16be~encoding=                            -- wtf16be

t~wtf16be(b: mb_wtf16le)                        -- error (ok)
mb_wtf16le~encoding=                            -- wtf16le

t~wtf16be(b: mb_utf32be)                        -- error (ok)
mb_utf32be~encoding=                            -- utf32be

t~wtf16be(b: mb_utf32le)                        -- error (ok)
mb_utf32le~encoding=                            -- utf32le

t~wtf16be(b: mb_unicode8)                       -- error (ok)
mb_unicode8~encoding=                           -- unicode8

t~wtf16be(b: mb_unicode16)                      -- error (ok)
mb_unicode16~encoding=                          -- unicode16

t~wtf16be(b: mb_unicode32)                      -- error (ok)
mb_unicode32~encoding=                          -- unicode32
