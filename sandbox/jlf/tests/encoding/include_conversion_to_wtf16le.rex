/*
Depends on:
t
*/

--------------------------------------------------------------------------------
-- to wtf16le
--------------------------------------------------------------------------------

< include_conversion_infos s/$(text)/t/
drop wtf16le
wtf16le = t~wtf16le(memorize:)
< include_conversion_infos s/$(text)/wtf16le/
t~wtf16le~"==":.object(wtf16le)=                -- 1

< include_conversion_mutablebuffers.rex

t~wtf16le(buffer: mb_utf8)                      -- error (ok)
mb_utf8~encoding=                               -- utf8

t~wtf16le(buffer: mb_wtf8)                      -- error (ok)
mb_wtf8~encoding=                               -- wtf8

t~wtf16le(buffer: mb_utf16be)                   -- error (ok)
mb_utf16be~encoding=                            -- utf16be

t~wtf16le(buffer: mb_utf16le)
mb_utf16le~encoding=                            -- wtf16le (yes, changed)

t~wtf16le(buffer: mb_wtf16be)                   -- error (ok)
mb_wtf16be~encoding=                            -- wtf16be

t~wtf16le(buffer: mb_wtf16le)
mb_wtf16le~encoding=                            -- wtf16le

t~wtf16le(buffer: mb_utf32be)                   -- error (ok)
mb_utf32be~encoding=                            -- utf32be

t~wtf16le(buffer: mb_utf32le)                   -- error (ok)
mb_utf32le~encoding=                            -- utf32le

t~wtf16le(buffer: mb_unicode8)                  -- error (ok)
mb_unicode8~encoding=                           -- unicode8

t~wtf16le(buffer: mb_unicode16)                 -- error (ok)
mb_unicode16~encoding=                          -- unicode16

t~wtf16le(buffer: mb_unicode32)                 -- error (ok)
mb_unicode32~encoding=                          -- unicode32
