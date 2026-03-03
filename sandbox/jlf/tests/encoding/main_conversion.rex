prompt off address directory
trap on novalue
demo on

.context~package~encoding = "byte"

-- .Unicode~loadDerivedName(/*action*/ "load")=    -- load all the Unicode characters
-- .Unicode~loadNameAliases(/*action*/ "load")=    -- load the name aliases

-- These regression tests were designed before the introduction of the immediate
-- "invalid text" error and before the introduction of the privileged encoding
-- status of Byte_Encoding.
.Unicode~immediateError = .false   -- no immediate error
.Unicode~promoteByteEncoding = .false -- the Byte_Encoding is not the privileged resulting encoding

--------------------------------------------------------------------------------
-- Supported encodings
--------------------------------------------------------------------------------

.encoding~list~pipe(.sort "byIndex" | .console "index.25" ":" "item")


--------------------------------------------------------------------------------
-- from Byte
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "7F"x)~text("Byte")           -- characters from 80x to FFx can't be converted to Unicode
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from CP1252 (alias of Windows-1252)
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")         -- all the characters from 00x to FFx can be converted to Unicode
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from ISO-8859-1
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("ISO-8859-1")     -- all the characters from 00x to FFx can be converted to Unicode
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from UTF-8
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "noël‍👨‍👩‍👧"
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from WTF-8
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "noël‍👨‍👩‍👧"
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "\uD83D\uDE3F"~text("wtf8")~unescape
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from UTF-16BE
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "noël‍👨‍👩‍👧"
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
t = t~utf16be
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from UTF-16LE
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "noël‍👨‍👩‍👧"
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
t = t~utf16le
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from WTF-16BE
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "noël‍👨‍👩‍👧"
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "\uD83D\uDE3F"~text("wtf8")~unescape
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
t = t~utf16be
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from WTF-16LE
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "noël‍👨‍👩‍👧"
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "\uD83D\uDE3F"~text("wtf8")~unescape
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
t = t~utf16le
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from UTF-32BE
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "noël‍👨‍👩‍👧"
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
t = t~utf32be
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from UTF-32LE
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "noël‍👨‍👩‍👧"
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
t = t~utf32le
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from UNICODE-8
--------------------------------------------------------------------------------

drop t
t = 0~255~reduce(initial: .mutableBuffer~new){.unicode~character(item)~unicode8(buffer: accu)}~string~text("unicode8")
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from UNICODE16
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
t = t~unicode16
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from UNICODE32
--------------------------------------------------------------------------------

drop t
t = xrange("00"x, "FF"x)~text("CP1252")~utf8
t ||= "noël‍👨‍👩‍👧"
t ||= "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
t ||= "äöü äöü x̂ ϔ ﷺ baﬄe"
t = t~unicode32
< include_conversion.rex
call display_cache t
