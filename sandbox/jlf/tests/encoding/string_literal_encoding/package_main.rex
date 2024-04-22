/*
rexx package_main.rex > package_main.out.txt
*/

width = 30

say
call display ".package_byte~m_name",          .package_byte~m_name
call display ".package_byte~m_noel",          .package_byte~m_noel
call display ".package_byte~m_noel_x",        .package_byte~m_noel_x
call display ".package_byte~m_noel_x2c",      .package_byte~m_noel_x2c

say
call display ".package_cp1252~m_name",        .package_cp1252~m_name
call display ".package_cp1252~m_noel",        .package_cp1252~m_noel
call display ".package_cp1252~m_noel_x",      .package_cp1252~m_noel_x
call display ".package_cp1252~m_noel_x2c",    .package_cp1252~m_noel_x2c

say
call display ".package_utf8~m_name",          .package_utf8~m_name
call display ".package_utf8~m_noel",          .package_utf8~m_noel
call display ".package_utf8~m_noel_x",        .package_utf8~m_noel_x
call display ".package_utf8~m_noel_x2c",      .package_utf8~m_noel_x2c

say
call display ".package_utf16be~m_name",       .package_utf16be~m_name
call display ".package_utf16be~m_noel",       .package_utf16be~m_noel
call display ".package_utf16be~m_noel_x",     .package_utf16be~m_noel_x
call display ".package_utf16be~m_noel_x2c",   .package_utf16be~m_noel_x2c

say
call display ".package_utf32be~m_name",       .package_utf32be~m_name
call display ".package_utf32be~m_noel",       .package_utf32be~m_noel
call display ".package_utf32be~m_noel_x",     .package_utf32be~m_noel_x
call display ".package_utf32be~m_noel_x2c",   .package_utf32be~m_noel_x2c

exit


display: procedure expose width
    use strict arg expression, value
    say expression~left(width)    value~left(width)~utf8    value~class~id~left(width)    value~encoding
    return


::requires "extension/text.cls"
::requires "package_byte.cls"
::requires "package_cp1252.cls"
::requires "package_utf8.cls"
::requires "package_utf16be.cls"
::requires "package_utf32be.cls"
