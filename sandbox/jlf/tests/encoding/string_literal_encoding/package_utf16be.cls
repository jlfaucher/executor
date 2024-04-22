.context~package~encoding = "utf16be"
say "prolog of package_utf16be.cls"~left(30) .context~package~encoding

::class package_utf16be public

::constant c_name                   "package_utf16be"
::constant c_noel                   "Noël"
::constant c_noel_h                 '004E 006F 00EB 006C'
::constant c_noel_x                 '004E 006F 00EB 006C'x

::method m_name class;      return  "package_utf16be"
::method m_noel class;      return  "Noël"
::method m_noel_h class;    return  '004E 006F 00EB 006C'
::method m_noel_x class;    return  '004E 006F 00EB 006C'x

::method m_noel_x2c class
    return self~m_noel_h~x2c


::requires "extension/text.cls"
