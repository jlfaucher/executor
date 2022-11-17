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
sleep no prompt


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
sleep
"\uD83D"~text("wtf8")~append("\uDE3F")~unescape=    -- High surrogate followed by low surrogate is valid WTF-8
sleep
"\uD83D"~text("utf8")~append("\uDE3F")~unescape=    -- High surrogate followed by low surrogate is INVALID UTF-8
sleep no prompt


-- c2d
"e"~text~c2d=
"é"~text~c2d=
sleep no prompt


-- c2x
"noël👩‍👨‍👩‍👧🎅"~text~c2x=
sleep no prompt


-- center
"noelFC"~text~center(10)=; result~description=              -- forward to String
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(10)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(9)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(8)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(7)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(6)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(5)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(4)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(3)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(2)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(1)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(0)=; result~description=
sleep no prompt

-- center with pad
"="~description=                                            -- 'UTF-8 ASCII (1 byte)'
"="~c2x=                                                    -- '3D'
sleep
"noelFC"~text~center(10, "=")=; result~description=         -- forward to String
sleep
"═"~description=                                            -- 'UTF-8 not-ASCII (3 bytes)'
sleep
"═"~text~description=                                       -- 'UTF-8 not-ASCII (1 grapheme, 1 codepoint, 3 bytes, 0 error)'
sleep
"═"~c2x=                                                    -- 'E29590'
sleep
"noelFC"~text~center(10, "═")=; result~description=         -- don't forward to String because the pad is more than 1 byte
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(10, "═")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(9, "═")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(8, "═")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(7, "═")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~center(6, "═")=; result~description=
sleep no prompt


-- contains
"noel"~text~contains("oe")=                 -- forward to String
sleep
"noel"~text~contains("oe"~text)=            -- forward to String
sleep
"noel"~text~contains("oë")=
sleep
"noel"~text~contains("oë"~text)=
sleep
"noël"~text~contains("oe")=
sleep
"noël"~text~contains("oe"~text)=
sleep
"noël"~text~contains("oë")=
sleep
"noël"~text~contains("oë"~text)=
sleep no prompt


-- copies
"noël👩‍👨‍👩‍👧🎅"~text~copies(4)=; result~description=
sleep no prompt


-- hashCode
"noël👩‍👨‍👩‍👧🎅"~text~hashCode~class=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~hashCode~c2x=
sleep no prompt


-- length
"noël👩‍👨‍👩‍👧🎅"~text~length=
sleep no prompt


-- match
"noel"~text~match(2, "oe")=                 -- forward to String
sleep
"noel"~text~match(2, "oe"~text)=            -- forward to String
sleep
"noel"~text~match(2, "oë")=
sleep
"noel"~text~match(2, "oë"~text)=
sleep
"noël"~text~match(2, "oe")=
sleep
"noël"~text~match(2, "oe"~text)=
sleep
"noël"~text~match(2, "oë")=
sleep
"noël"~text~match(2, "oë"~text)=
sleep
"noël"~text~match(2, "oël")=
sleep
"noël"~text~match(2, "oël"~text)=
sleep
"noël"~text~match(3, "ë")=
sleep
"noël"~text~match(3, "ë"~text)=
sleep
"noël"~text~match(3, "ël")=
sleep
"noël"~text~match(3, "ël"~text)=
sleep
"noël"~text~match(4, "l")=
sleep
"noël"~text~match(4, "l"~text)=
sleep no prompt


-- matchChar
"noel"~text~matchChar(3, "Ee")=             -- forward to String
sleep
"noel"~text~matchChar(3, "Ee"~text)=        -- forward to String
sleep
"noel"~text~matchChar(3, "EËeë")=
sleep
"noel"~text~matchChar(3, "EËeë"~text)=
sleep
"noël"~text~matchChar(3, "EËeë")=
sleep
"noël"~text~matchChar(3, "EËeë"~text)=
sleep
"noël"~text~matchChar(3, "EËeë")=
sleep
"noël"~text~matchChar(4, "Ll"~text)=
sleep
"noël"~text~matchChar(4, "Ll"~text)=
sleep no prompt


-- pos
"noel"~text~pos("oe")=                      -- forward to String
sleep
"noel"~text~pos("oe"~text)=                 -- forward to String
sleep
"noel"~text~pos("oë")=
sleep
"noel"~text~pos("oë"~text)=
sleep
"noël"~text~pos("oe")=
sleep
"noël"~text~pos("oe"~text)=
sleep
"noël"~text~pos("oë")=
sleep
"noël"~text~pos("oë"~text)=
sleep
"noël"~text~pos("l")=
sleep
"noël"~text~pos("l"~text)=
sleep no prompt


-- subchar
"noël👩‍👨‍👩‍👧🎅"~text~subchar(3)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~subchar(4)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~subchar(5)=; result~description=
sleep no prompt


-- substr
"noel"~text~substr(3, 3, "x")=; result~description=    -- forward to String
sleep
"noel"~substr(3, 3, "▷")=; result~description=        -- forward to String: error because the pad character is 3 bytes
sleep
"noel"~substr(3, 3, "▷"~text)=; result~description=   -- forward to String: error because the pad character is not compatible with String
sleep
"noel"~text~substr(3, 3, "▷")=; result~description=   -- no error because self is a RexxText and the pad character is one grapheme when converted to the default encoding
sleep
"noël👩‍👨‍👩‍👧🎅"~text~substr(3, 3, "▷")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~text~substr(3, 6, "▷")=; result~description=
sleep no prompt


-- x2c
"F09F9180"~text~x2c=
sleep
"not an hexadecimal value"~text~x2c
sleep
"not an hexadecimal value 🤔"~text~x2c
sleep no prompt


---------------------------------------------------------
-- Text encoding - Compatibility with regular expressions
---------------------------------------------------------

/*
A way to test the compatibility of RexxText with String is to pass instances of
RexxText to the regular expression engine regex.cls, and see what happens...
*/
sleep no prompt

p = .Pattern~compile("a.c"~text)
p~matches("abc"~text)=
sleep
p~matches("aôc"~text)=
sleep no prompt

p = .Pattern~compile("à.c"~text)
sleep no prompt


/*


-----------------------------------------
-- Text encoding - Compatibility with BIF
-----------------------------------------

/*
[Intermediate solution]

Several solutions in RosettaCode are in error because the pad character used
with the function 'center' is a UTF-8 string made of several bytes.
The function center now supports utf-8 pad made of 1 grapheme.
When the pad is not a 1 byte character then the interpreter converts the string
to a RexxText and sends it the message "center".
The returned value is the String associated to the RexxText.

The invariants of the method 'center' are true for the RexxText, but not true for
the String (which is normal).
*/

"═"~description=                                -- 'UTF-8 not-ASCII (3 bytes)'
sleep
"═"~text~description=                           -- 'UTF-8 not-ASCII (1 grapheme, 1 codepoint, 3 bytes, 0 error)'
sleep
"═"~c2x=                                        -- 'E29590'
sleep
center("hello", 20, "═")=                       -- '═══════hello════════'
sleep
center("hello", 20, "═")~text~description=      -- 'UTF-8 not-ASCII (20 graphemes, 20 codepoints, 50 bytes, 0 error)'
sleep no prompt

-- Idem for the function 'left'
left("hello", 20, "═")=                         -- 'hello═══════════════'
sleep
left("hello", 20, "═")~text~description=        -- 'UTF-8 not-ASCII (20 graphemes, 20 codepoints, 50 bytes, 0 error)'
sleep no prompt


/*
[General solution]

The new path I would like to explore is the support of graphemes by ALL the BIF...
I have already a tiny support for center() and left(), only triggered in case of
pad character made of several bytes.

The generalization would be to route the BIF either towards String or towards RexxText,
in function of the compatibility of the arguments with String:
BIF(str1, str2, ..., strN)
    --> forward to String (byte-oriented) if str's encoding is Byte or UTF-8 (with ASCII characters only)
    --> forward to RexxText otherwise
*/
sleep no prompt

-- UTF-8 encoding

"Noel"~isCompatibleWithByteString=              -- 1
sleep
length("Noel")=                                 -- 4 because "Noel"~length = 4
sleep
"Noël"~isCompatibleWithByteString=              -- 0
sleep
length("Noël")=                                 -- TODO: 4 because "Noël"~text~length = 4
sleep
"Noël"~length=                                  -- 5 because String remains byte-oriented, not impacted by the default encoding
sleep no prompt

-- UTF-16BE encoding
s = "0041004200430044"x
s=                                              -- '[00]A[00]B[00]C[00]D'
sleep
s~isCompatibleWithByteString=                   -- 1
sleep
s~description=                                  -- 'UTF-8 ASCII (8 bytes)'
sleep
length(s)=                                      -- 8 because encoding UTF-8 ASCII is compatible with String
s~encoding = "UTF16"
s~isCompatibleWithByteString=                   -- 0
sleep
s~description=                                  -- 'UTF-16BE (8 bytes)'
sleep
s~length=                                       -- 8 because String is always byte-oriented (ignores the encoding)
sleep
length(s)=                                      -- TODO: 4 because forwards to Text (encoding UTF-16BE is not compatible with String)
sleep
s~text~utf8=                                    -- ABCD
sleep no prompt

-- UTF-32 encoding
s = "0000004100000042"x
s=                                              -- '[000000]A[000000]B'
sleep
s~isCompatibleWithByteString=                   -- 1
sleep
s~description=                                  -- 'UTF-8 ASCII (8 bytes)'
sleep
length(s)=                                      -- 8 because encoding UTF-8 ASCII is compatible with String
s~encoding = "UTF32"
s~isCompatibleWithByteString=                   -- 0
sleep
s~description=                                  -- 'UTF-32BE (8 bytes)'
sleep
s~length=                                       -- 8 because String is always byte-oriented (ignores the encoding)
sleep
length(s)=                                      -- TODO: 2 because forwards to Text (encoding UTF-32 is not compatible with String)
sleep
s~text~utf8=                                    -- AB
sleep no prompt


/*
End of demonstration.
*/
prompt directory on
demo off
