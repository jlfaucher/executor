/*
Depends on:
t
*/

--------------------------------------------------------------------------------
-- to utf16le
--------------------------------------------------------------------------------

< include_conversion_infos s/$(text)/t/
drop utf16le
utf16le = t~utf16le(memorize:)
< include_conversion_infos s/$(text)/utf16le/
t~utf16le~"==":.object(utf16le)=                -- 1

< include_conversion_mutablebuffers.rex

t~utf16le(buffer: mb)
mb~encoding=                                    -- utf16le

t~utf16le(buffer: mb_utf8)                      -- error (ok)
mb_utf8~encoding=                               -- utf8

t~utf16le(buffer: mb_wtf8)                      -- error (ok)
mb_wtf8~encoding=                               -- wtf8

t~utf16le(buffer: mb_utf16be)                   -- error (ok)
mb_utf16be~encoding=                            -- utf16be

t~utf16le(buffer: mb_utf16le)
mb_utf16le~encoding=                            -- utf16le

t~utf16le(buffer: mb_wtf16be)                   -- error (ok)
mb_wtf16be~encoding=                            -- wtf16be

t~utf16le(buffer: mb_wtf16le)
mb_wtf16le~encoding=                            -- wtf16le

t~utf16le(buffer: mb_utf32be)                   -- error (ok)
mb_utf32be~encoding=                            -- utf32be

t~utf16le(buffer: mb_utf32le)                   -- error (ok)
mb_utf32le~encoding=                            -- utf32le

t~utf16le(buffer: mb_unicode8)                  -- error (ok)
mb_unicode8~encoding=                           -- unicode8

t~utf16le(buffer: mb_unicode16)                 -- error (ok)
mb_unicode16~encoding=                          -- unicode16

t~utf16le(buffer: mb_unicode32)                 -- error (ok)
mb_unicode32~encoding=                          -- unicode32
