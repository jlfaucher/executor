.context~package~encoding = "cp1252"
say "prolog of package_cp1252.cls"~left(30) .context~package~encoding

::class package_cp1252 public

/*
With ooRexx4, a CONSTANT string is NEVER evaluated.
Consequence: its encoding is the default encoding, and it's never converted to Text.
Maybe ooRexx5 has solved this problem, should retrofit the new implementation.
*/
::constant c_name                   "package_cp1252"
::constant c_noel                   "Noël"              -- REMEMBER! Not evaluated, so not tagged CP1252
::constant c_noel_h                 '4E 6F C3 AB 6C'
::constant c_noel_x                 '4E 6F C3 AB 6C'x

::method m_name class;      return  "package_cp1252"
::method m_noel class;      return  "Noël"
::method m_noel_h class;    return  '4E 6F C3 AB 6C'
::method m_noel_x class;    return  '4E 6F C3 AB 6C'x

::method m_noel_x2c class
    return self~m_noel_h~x2c


::requires "extension/text.cls"
