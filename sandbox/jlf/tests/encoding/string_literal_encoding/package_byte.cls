.context~package~encoding = "byte"
say "prolog of package_byte.cls"~left(30) .context~package~encoding

::class package_byte public

::constant c_name                   "package_byte"
::constant c_noel                   "Noël"
::constant c_noel_h                 '4E 6F C3 AB 6C'
::constant c_noel_x                 '4E 6F C3 AB 6C'x

::method m_name class;      return  "package_byte"
::method m_noel class;      return  "Noël"
::method m_noel_h class;    return  '4E 6F C3 AB 6C'
::method m_noel_x class;    return  '4E 6F C3 AB 6C'x

::method m_noel_x2c class
    return self~m_noel_h~x2c


::requires "extension/text.cls"
