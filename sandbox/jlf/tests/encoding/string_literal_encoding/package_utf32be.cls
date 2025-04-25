/*
Not possible to have a package encoded UTF32-BE
*/

.context~package~encoding = "utf32be"   -- error

-- The rest of this file is useless
-- Will never be executed since the prolog raises an error.

say "prolog of package_utf32be.cls"~left(30) .context~package~encoding

::class package_utf32be public

::constant c_name                   "package_utf32be"
::constant c_noel                   "Noël"
::constant c_noel_h                 '0000004E 0000006F 000000EB 0000006C'
::constant c_noel_x                 '0000004E 0000006F 000000EB 0000006C'x

::method m_name class;      return  "package_utf32be"
::method m_noel class;      return  "Noël"
::method m_noel_h class;    return  '0000004E 0000006F 000000EB 0000006C'
::method m_noel_x class;    return  '0000004E 0000006F 000000EB 0000006C'x

::method m_noel_x2c class
    return self~m_noel_h~x2c


::requires "extension/text.cls"
