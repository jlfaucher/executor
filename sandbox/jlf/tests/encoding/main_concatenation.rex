prompt off address directory
trap on novalue
demo on

/*
Remember:
All the strings in this file are UTF-8.
When I put an encoding on them, their contents remain UTF-8, that's the
normal behavior: a text is a view, a layer, an interpretation of the bytes.
The bytes themselves are not impacted by a view.
That's why a text like "Noël"~text("unicode-8") will show
"4E 6F C3 AB 6C" instead of "4E 6F EB 6C".
The concatenation rules depend on the encoding and the asciiness, so the tests
remain pertinent: in both representations, the string is not ASCII.
*/

drop t
t = "Joyeux"~text "Noel"
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux"~text "Noël"
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux" "Noel"~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux" "Noël"~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux"~text || " Noel"
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux"~text || " Noël"
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux" || " Noel"~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Joyeux" || " Noël"~text
< include_concatenation_infos s/$(text)/t/

/*
        Left                    Right                   Candidates      Result          Rule
        ------------------------------------------------------------------------------------
        Byte ASCII              Byte ASCII              Left, Right     Left            R3      Left
        Byte ASCII              Byte not-ASCII          Right           Right           R4      Right
        Byte not-ASCII          Byte ASCII              Left            Left            R5      Left
        Byte not-ASCII          Byte not-ASCII                          error                   None
        Unicode ASCII           Unicode ASCII           Left, Right     Left            R1      Left
        Unicode ASCII           Unicode not-ASCII       Right           Right           R4      Right
        Unicode not-ASCII       Unicode ASCII           Left            Left            R5      Left
        Unicode not-ASCII       Unicode not-ASCII                       error                   None
        Byte ASCII              Unicode ASCII           Left, Right     Right           R2      Promote to Right
        Byte ASCII              Unicode not-ASCII       Right           Right           R4      Promote to Right
        Byte not-ASCII          Unicode ASCII           Left            Left            R5      Demote to Left
        Byte not-ASCII          Unicode not-ASCII                       error                   None
        Unicode ASCII           Byte ASCII              Left, Right     Left            R1      Promote to Left
        Unicode ASCII           Byte not-ASCII          Right           Right           R4      Demote to Right
        Unicode not-ASCII       Byte ASCII              Left            Left            R5      Promote to Left
        Unicode not-ASCII       Byte not-ASCII                          error                   None
*/

/*
        Left                    Right                   Candidates      Result          Rule
        ------------------------------------------------------------------------------------
        Byte ASCII              Byte ASCII              Left, Right     Left            R3      Left
        Byte ASCII              Byte not-ASCII          Right           Right           R4      Right
        Byte not-ASCII          Byte ASCII              Left            Left            R5      Left
        Byte not-ASCII          Byte not-ASCII                          error                   None
*/

drop t
t = "Pere"~text("windows-1252") "Noel"~text("iso-8859-1")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Pere"~text("windows-1252")~appendEncoded(" "~text("windows-1252"), buffer:b)~appendEncoded("Noel"~text("iso-8859-1"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Pere"~text("windows-1252"), " "~text("windows-1252"), "Noel"~text("iso-8859-1"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Pere"~text("windows-1252") "Noël"~text("iso-8859-1")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Pere"~text("windows-1252")~appendEncoded(" "~text("windows-1252"), buffer:b)~appendEncoded("Noël"~text("iso-8859-1"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Pere"~text("windows-1252"), " "~text("windows-1252"), "Noël"~text("iso-8859-1"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Père"~text("windows-1252") "Noel"~text("iso-8859-1")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Père"~text("windows-1252")~appendEncoded(" "~text("windows-1252"), buffer:b)~appendEncoded("Noel"~text("iso-8859-1"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Père"~text("windows-1252"), " "~text("windows-1252"), "Noel"~text("iso-8859-1"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Père"~text("windows-1252") "Noël"~text("iso-8859-1")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Père"~text("windows-1252")~appendEncoded(" "~text("windows-1252"), buffer:b)~appendEncoded("Noël"~text("iso-8859-1"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Père"~text("windows-1252"), " "~text("windows-1252"), "Noël"~text("iso-8859-1"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

/*
        Left                    Right                   Candidates      Result          Rule
        ------------------------------------------------------------------------------------
        Unicode ASCII           Unicode ASCII           Left, Right     Left            R1      Left
        Unicode ASCII           Unicode not-ASCII       Right           Right           R4      Right
        Unicode not-ASCII       Unicode ASCII           Left            Left            R5      Left
        Unicode not-ASCII       Unicode not-ASCII                       error                   None
*/

drop t
t = "Pere"~text("utf-8") "Noel"~text("unicode-8")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Pere"~text("utf-8")~appendEncoded(" "~text("utf-8"), buffer:b)~appendEncoded("Noel"~text("unicode-8"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Pere"~text("utf-8"), " "~text("utf-8"), "Noel"~text("unicode-8"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Pere"~text("utf-8") "Noël"~text("unicode-8")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Pere"~text("utf-8")~appendEncoded(" "~text("utf-8"), buffer:b)~appendEncoded("Noël"~text("unicode-8"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Pere"~text("utf-8"), " "~text("utf-8"), "Noël"~text("unicode-8"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Père"~text("utf-8") "Noel"~text("unicode-8")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Père"~text("utf-8")~appendEncoded(" "~text("utf-8"), buffer:b)~appendEncoded("Noel"~text("unicode-8"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Père"~text("utf-8"), " "~text("utf-8"), "Noel"~text("unicode-8"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Père"~text("utf-8") "Noël"~text("unicode-8")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Père"~text("utf-8")~appendEncoded(" "~text("utf-8"), buffer:b)~appendEncoded("Noël"~text("unicode-8"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Père"~text("utf-8"), " "~text("utf-8"), "Noël"~text("unicode-8"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

/*
        Left                    Right                   Candidates      Result          Rule
        ------------------------------------------------------------------------------------
        Byte ASCII              Unicode ASCII           Left, Right     Right           R2      Promote to Right
        Byte ASCII              Unicode not-ASCII       Right           Right           R4      Promote to Right
        Byte not-ASCII          Unicode ASCII           Left            Left            R5      Demote to Left
        Byte not-ASCII          Unicode not-ASCII                       error                   None
*/

drop t
t = "Pere"~text("byte") "Noel"~text("unicode-8")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Pere"~text("byte")~appendEncoded(" "~text("byte"), buffer:b)~appendEncoded("Noel"~text("unicode-8"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Pere"~text("byte"), " "~text("byte"), "Noel"~text("unicode-8"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Pere"~text("byte") "Noël"~text("unicode-8")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Pere"~text("byte")~appendEncoded(" "~text("byte"), buffer:b)~appendEncoded("Noël"~text("unicode-8"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Pere"~text("byte"), " "~text("byte"), "Noël"~text("unicode-8"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Père"~text("byte") "Noel"~text("unicode-8")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Père"~text("byte")~appendEncoded(" "~text("byte"), buffer:b)~appendEncoded("Noel"~text("unicode-8"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Père"~text("byte"), " "~text("byte"), "Noel"~text("unicode-8"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Père"~text("byte") "Noël"~text("unicode-8")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Père"~text("byte")~appendEncoded(" "~text("byte"), buffer:b)~appendEncoded("Noël"~text("unicode-8"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Père"~text("byte"), " "~text("byte"), "Noël"~text("unicode-8"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

/*
        Left                    Right                   Candidates      Result          Rule
        ------------------------------------------------------------------------------------
        Unicode ASCII           Byte ASCII              Left, Right     Left            R1      Promote to Left
        Unicode ASCII           Byte not-ASCII          Right           Right           R4      Demote to Right
        Unicode not-ASCII       Byte ASCII              Left            Left            R5      Promote to Left
        Unicode not-ASCII       Byte not-ASCII                          error                   None
*/

drop t
t = "Pere"~text("unicode-8") "Noel"~text("byte")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Pere"~text("unicode-8")~appendEncoded(" "~text("unicode-8"), buffer:b)~appendEncoded("Noel"~text("byte"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Pere"~text("unicode-8"), " "~text("unicode-8"), "Noel"~text("byte"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Pere"~text("unicode-8") "Noël"~text("byte")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Pere"~text("unicode-8")~appendEncoded(" "~text("unicode-8"), buffer:b)~appendEncoded("Noël"~text("byte"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Pere"~text("unicode-8"), " "~text("unicode-8"), "Noël"~text("byte"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Père"~text("unicode-8") "Noel"~text("byte")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Père"~text("unicode-8")~appendEncoded(" "~text("unicode-8"), buffer:b)~appendEncoded("Noel"~text("byte"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Père"~text("unicode-8"), " "~text("unicode-8"), "Noel"~text("byte"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop t
t = "Père"~text("unicode-8") "Noël"~text("byte")
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
"Père"~text("unicode-8")~appendEncoded(" "~text("unicode-8"), buffer:b)~appendEncoded("Noël"~text("byte"), buffer:b)
t = b~string~text
< include_concatenation_infos s/$(text)/t/

drop b t
b = .MutableBuffer~new
b~appendEncoded("Père"~text("unicode-8"), " "~text("unicode-8"), "Noël"~text("byte"))
t = b~string~text
< include_concatenation_infos s/$(text)/t/
