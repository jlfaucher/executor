/*
Not possible to have a package encoded UTF16-BE
*/

.context~package~encoding = "utf16be"   -- error

-- The rest of this file is useless
-- Will never be executed since the prolog raises an error.

say "prolog of package_utf16be.cls"~left(30) .context~package~encoding

::class package_utf16be public

::constant c_name                   "package_utf16be"       -- is an invalid UTF-16BE string (no error raised while evaluating because String)
                                                            -- 'UTF-16BE encoding: byte sequence at byte-position 15 is truncated, expected 2 bytes.

::constant c_noel                   "Noël"                  -- is an invalid UTF-16BE string (error raised while evaluating because RexxText)
                                                            -- UTF-16BE encoding: byte sequence at byte-position 5 is truncated, expected 2 bytes.

::constant c_noel_h                 '004E 006F 00EB 006C'   -- is an invalid UTF-16BE string (no error while evaluating because String)
                                                            -- 'UTF-16BE encoding: byte sequence at byte-position 19 is truncated, expected 2 bytes.

::constant c_noel_x                 '004E 006F 00EB 006C'x

::method m_name class;      return  "package_utf16be"
::method m_noel class;      return  "Noël"
::method m_noel_h class;    return  '004E 006F 00EB 006C'
::method m_noel_x class;    return  '004E 006F 00EB 006C'x

::method m_noel_x2c class
    return self~m_noel_h~x2c


::requires "extension/text.cls"
