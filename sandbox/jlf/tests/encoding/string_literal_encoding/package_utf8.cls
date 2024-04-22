.context~package~encoding = "utf8"
say "prolog of package_utf8.cls"~left(30) .context~package~encoding

::class package_utf8 public

::constant c_name                   "package_utf8"
::constant c_noel                   "Noël"
::constant c_noel_h                 '4E 6F C3AB 6C'
::constant c_noel_x                 '4E 6F C3AB 6C'x

::method m_name class;      return  "package_utf8"
::method m_noel class;      return  "Noël"
::method m_noel_h class;    return  '4E 6F C3AB 6C'
::method m_noel_x class;    return  '4E 6F C3AB 6C'x

::method m_noel_x2c class
    return self~m_noel_h~x2c


::requires "extension/text.cls"
