/*
Depends on:
t
*/

--------------------------------------------------------------------------------
-- to unicode
--------------------------------------------------------------------------------

< include_conversion_infos s/$(text)/t/
drop unicode
unicode = t~unicode(mem:)
< include_conversion_infos s/$(text)/unicode/
t~unicode~"==":.object(unicode)=                -- 1

< include_conversion_mutablebuffers.rex

t~unicode(b: mb_utf8)
mb_utf8~encoding=                               -- utf8

t~unicode(b: mb_wtf8)
mb_wtf8~encoding=                               -- wtf8

t~unicode(b: mb_utf16be)                        -- error (ok)
mb_utf16be~encoding=                            -- utf16be

t~unicode(b: mb_utf16le)                        -- error (ok)
mb_utf16le~encoding=                            -- utf16le

t~unicode(b: mb_wtf16be)                        -- error (ok)
mb_wtf16be~encoding=                            -- wtf16be

t~unicode(b: mb_wtf16le)                        -- error (ok)
mb_wtf16le~encoding=                            -- wtf16le

t~unicode(b: mb_utf32be)                        -- error (ok)
mb_utf32be~encoding=                            -- utf32be

t~unicode(b: mb_utf32le)                        -- error (ok)
mb_utf32le~encoding=                            -- utf32le

t~unicode(b: mb_unicode8)
mb_unicode8~encoding=                           -- unicode8

t~unicode(b: mb_unicode16)                      -- error (TODO: must be ok)
mb_unicode16~encoding=                          -- unicode16

t~unicode(b: mb_unicode32)                      -- error (TODO: must be ok)
mb_unicode32~encoding=                          -- unicode32
