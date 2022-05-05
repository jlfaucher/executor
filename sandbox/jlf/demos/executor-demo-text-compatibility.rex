prompt directory off
demo on

--------------------------------------------
-- Text encoding - Compatibility with String
--------------------------------------------

/*
Compatibility with the class String.
This is a work in progress, many methods not yet supported,
Unicode implementation still missing for many methods.
*/
sleep no prompt

/*
This string is used in several places:
"noël👩‍👨‍👩‍👧🎅"
Depending on your editor/browser, you may see 5 emojis, or 3 emojis.
With Unicode 13, the display is 3 emojis (woman + family + father christmas).
👩	U+1F469	WOMAN
‍	U+200D	ZERO WIDTH JOINER
👨	U+1F468	MAN
‍	U+200D	ZERO WIDTH JOINER
👩	U+1F469	WOMAN
‍	U+200D	ZERO WIDTH JOINER
👧	U+1F467	GIRL
🎅	U+1F385	FATHER CHRISTMAS

Notice that 👩‍👨‍👩‍👧 constitute only 1 grapheme thanks to the ZERO WIDTH JOINER.
*/
sleep no prompt

"noël👩‍👨‍👩‍👧🎅"~text~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~c2u=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~c2x=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~c2g=
sleep no prompt

-- []
"noël👩‍👨‍👩‍👧🎅"~text[3]=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text[3,3]=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text[3,6]=; result~description=
sleep

-- ?
"0"~text~?("true"~text, "false"~text)=
sleep
"1"~text~?("true"~text, "false"~text)=
sleep
"not a boolean value"~text~?("true"~text, "false"~text)=
sleep
"not a boolean value 🤔"~text~?("true"~text, "false"~text)=
sleep
"0"~text~?("true 🤔"~text, "false 🤔"~text)=
sleep
"1"~text~?("true 🤔"~text, "false 🤔"~text)=
sleep no prompt

-- append
"hello"~text~append(" ")~append("john"~text)=
sleep no prompt

-- c2d
"e"~text~c2d=
"é"~text~c2d=
sleep no prompt

-- c2x
"noël👩‍👨‍👩‍👧🎅"~text~c2x=
sleep no prompt

-- contains
"noel"~text~contains("oe"~text)=            -- forward to String
"noel"~text~contains("oë"~text)=
"noël"~text~contains("oe"~text)=
sleep no prompt

-- copies
"noël👩‍👨‍👩‍👧🎅"~text~copies(4)=; result~description=
sleep no prompt

-- hashCode
"noël👩‍👨‍👩‍👧🎅"~text~hashCode~class=
"noël👩‍👨‍👩‍👧🎅"~text~hashCode~c2x=
sleep no prompt

-- length
"noël👩‍👨‍👩‍👧🎅"~text~length=
sleep no prompt

-- match
"noel"~text~match(2, "oe"~text)=            -- forward to String
"noel"~text~match(2, "oë"~text)=
"noël"~text~match(2, "oe"~text)=
sleep no prompt

-- matchChar
"noel"~text~matchChar(2, "oe"~text)=        -- forward to String
"noel"~text~matchChar(2, "oë"~text)=
"noël"~text~matchChar(2, "oe"~text)=
sleep no prompt

-- pos
"noel"~text~pos("oe"~text)=                 -- forward to String
"noel"~text~pos("oë"~text)=
"noël"~text~pos("oe"~text)=
sleep no prompt

-- subchar
"noël👩‍👨‍👩‍👧🎅"~text~subchar(3)=; result~description=
"noël👩‍👨‍👩‍👧🎅"~text~subchar(4)=; result~description=
"noël👩‍👨‍👩‍👧🎅"~text~subchar(5)=; result~description=
sleep no prompt

-- substr
"noel"~text~substr(3, 3, "x")=    -- forward to String
sleep
"noel"~substr(3, 3, "▷")=        -- forward to String: error because the pad character is 3 bytes
sleep
"noel"~substr(3, 3, "▷"~text)=   -- forward to String: error because the pad character is not compatible with String
sleep
"noel"~text~substr(3, 3, "▷")=   -- no error because self is a RexxText and the pad character is one grapheme when converted to the default encoding
sleep
"noël👩‍👨‍👩‍👧🎅"~text~substr(3, 3, "▷")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~substr(3, 6, "▷")=; result~description=
sleep

-- x2c
"F09F9180"~text~x2c=
"not an hexadecimal value"~text~x2c
"not an hexadecimal value 🤔"~text~x2c
sleep no prompt

/*
A way to test the compatibility of RexxText with String is to pass instances of
RexxText to the regular expression engine regex.cls, and see what happens...
*/
sleep no prompt

p = .Pattern~compile("a.c"~text)
p~matches("abc"~text)=
p~matches("aôc"~text)=

p = .Pattern~compile("à.c"~text)
sleep no prompt

/*
End of demonstration.
*/
prompt directory on
demo off
