prompt off address directory
demo on

call loadUnicodeCharacterNames

.Unicode~memorizeTranscodings = .false
.Unicode~memorizeTransformations = .false


-- ===============================================================================
-- 2024 Apr 24

/*
Rework the support of encoding for RexxBlock.
The definition doesn't change:
A RexxBlock has the same encoding as its definition package.
New methods:
    encoding
    encoding=
    hasEncoding
    setEncoding
Examples:
*/
block = {say .context~package~encoding; s1 = "Père Noël"; say s1~class s1~encoding; s2 = "Père" "Noël"; say s~class s~encoding}
block~hasEncoding=                                  -- 1
block~encoding=                                     -- (The UTF8_Encoding class)
block~()
/*
    The UTF8_Encoding class                         -- encoding of the definition package
    The RexxText class The UTF8_Encoding class      -- encoding of the definition package (string literal)
    The String class The UTF8_Encoding class        -- encoding of the calculated string
*/

-- Changing the block encoding
block = {say .context~package~encoding; s1 = "Père Noël"; say s1~class s1~encoding; s2 = "Père" "Noël"; say s~class s~encoding}
oldEncoding = block~setEncoding("byte")
oldEncoding=                                        -- (The UTF8_Encoding class)
block~hasEncoding=                                  -- 1
block~encoding=                                     -- (The Byte_Encoding class)
block~()
/*
    The Byte_Encoding class                         -- encoding of the definition package
    The String class The Byte_Encoding class        -- encoding of the definition package (string literal)
    The String class The UTF8_Encoding class        -- Calculated string. TODO should be The Byte_Encoding
*/
block~setEncoding(oldEncoding)
block~hasEncoding=                                  -- 1
block~encoding=                                     -- (The UTF8_Encoding class)
block~()
/*
    The UTF8_Encoding class
    The String class The Byte_Encoding class        -- Once a string literal has a stored encoding, it doesn't change
    The String class The UTF8_Encoding class
*/


-- ===============================================================================
-- 2024 Apr 22

/*
The encoding of a string literal is the encoding of its definition package.
It is set when the string literal is first evaluated.
Once a string literal has received its encoding, it does not change even if the
package encoding is changed later. Only string literals not yet evaluated will
be impacted. It is possible to explicitly change the encoding using the
~setEncoding method or using the ~encoding = new_encoding assignment.
The same goes for the default encoding. Once a calculated string has received
its encoding, it does not change even if the default encoding is changed later.
Examples:
*/
system rexx string_literal_encoding/package_main.rex


/*
Consequence of the previous rule, the hexadecimal and binary strings are no longer
declared Byte encoded. Now their encoding is given by their definition package.
Idem for the BIFs/BIMs D2C and X2C, their results are no longer declared Byte encoded.
Since they have no assigned encoding, their results encoding depend on the default
encoding.
Examples:
*/
"41"x=                      -- 'A'
"41"x~hasEncoding=          -- 1    The encoding is stored
"41"x~encoding=             -- (The UTF8_Encoding class)    This is the encoding of the definition package
"41"~x2c=                   -- 'A'
"41"~x2c~hasEncoding=       -- 0    No stored encoding
"41"~x2c~encoding=          -- (The UTF8_Encoding class)    This is the default encoding


/*
For the proper management of the encoding of string literals, the globalStrings
directory is no longer used by the parser when building an image.
Now, each source (package) manages its own directory, even when building an image.
For the moment, all the packages that are included in rexx.img are byte encoded,
so this change is not needed. But maybe in the future, I may have packages with
different encodings in rexx.img.
*/


/*
It's now possible to reset the encoding of a string, mutable buffer or package
by passing .nil when using
    target~encoding = .nil
    target~setEncoding(.nil)
After reset, the encoding is no longer stored and the default encoding is returned.
A RexxText has always an encoding, so an error is raised when passing .nil.
This same error is raised when the target is a string linked to a RexxText.
Examples:
*/
s = "Noel"
s~description=                          -- 'UTF-8 ASCII (4 bytes)'
oldEncoding = s~setEncoding(.nil)
oldEncoding=                            -- (The UTF8_Encoding class)
s~description=                          -- 'UTF-8 ASCII by default (4 bytes)'
s~setEncoding(oldEncoding)
s~description=                          -- 'UTF-8 ASCII (4 bytes)'

t = "Noël"
t~description=                          -- 'UTF-8 not-ASCII (4 characters, 4 codepoints, 5 bytes, 0 error)'
t~setEncoding(.nil)                     -- Encoding: 'The NIL object' is not supported
s = t~string
s~description=                          -- 'UTF-8 not-ASCII (4 characters, 4 codepoints, 5 bytes, 0 error)'
s~setEncoding(.nil)                     -- Encoding: 'The NIL object' is not supported


/*
The method ~setEncoding returns .nil when the target has no stored encoding.
That allows to reset properly the encoding when restoring the previous value.
Note: the method ~encoding never returns .nil. It returns the default encoding
when no encoding is stored.
Examples:
*/
.context~package~hasEncoding=                       -- 0                            The encoding is not stored
.context~package~encoding=                          -- (The UTF8_Encoding class)    It's the default encoding
oldEncoding = .context~package~setEncoding("byte")
oldEncoding=                                        -- (The NIL object)
.context~package~hasEncoding=                       -- 1                            The encoding is stored
.context~package~encoding=                          -- (The Byte_Encoding class)
.context~package~setEncoding(oldEncoding)=          -- (The Byte_Encoding class)    Previous encoding
.context~package~hasEncoding=                       -- 0                            Return to non-stored encoding
.context~package~encoding=                          -- (The UTF8_Encoding class)    It's the default encoding


/*
New methods:
    .String~detach
    .RexxText~detach
The string is detached from its text counterpart.
The text becomes an empty text "".
Useful when working with big strings, to reclaim memory.
No need to call ~detach on both targets. There is a forward to the counterpart.
Examples:
*/
s = "Noel"
t = s~text
t=              -- T'Noel'
s~hasText=      -- 1
s~detach
s~hasText=      -- 0
t=              -- T''

t = "Noël"
s = t~string
t=              -- T'Noël'
s~hasText=      -- 1
t~detach
s~hasText=      -- 0
t=              -- T''


/*
New methods:
    .String~byte
    .RexxText~byte
Returns a copy of the string or text, with encoding = The Byte_Encoding.
The Byte_Encoding is a raw encoding with few constraints. It's often used for
diagnostic or repair. It can be always absorbed when doing a concatenation or a
comparison. BUT it's impossible to transcode from/to it without errors if the
string contains not-ASCII characters. Here, no transcoding, it's a copy as-is
whose encoding is The Byte_Encoding.
Examples:
*/
"50C3"x~description=                    -- 'UTF-8 not-ASCII (2 characters, 2 codepoints, 2 bytes, 1 error)'
"Père"~text~startsWith("50C3"x)=        -- Invalid UTF-8 string (raised by utf8proc)
"50C3"x~byte~description=               -- 'Byte not-ASCII (2 characters, 2 codepoints, 2 bytes, 0 error)'
"Père"~text~startsWith("50C3"x~byte)=   -- 0 (not aligned)


/*
New methods:
    .String~bytes
    .RexxText~bytes
Returns a ByteSupplier which provides each byte in decimal.
Examples:
*/
"Noel"~bytes==
"Noël"~bytes==


-- ===============================================================================
-- 2024 Apr 12

/*
[interpreter]

Add support for dynamic target when sending messages.
The target is calculated based on the initial target and the arguments
values/types of the message. It's still a single-dispatch.
The ~~ form of message is not impacted: it returns the object that received the
message (the initial target), not the calculated target.


New method .Object~dynamicTarget which returns the target in function of the arguments:
    RexxObject *RexxObject::dynamicTargetRexx(RexxObject **arguments, size_t argCount, size_t named_argCount)
    {
        return this->dynamicTarget(arguments, argCount, named_argCount);
    }
By default, the dynamic target is the receiver object.
Native classes can override the virtual method dynamicTarget.
For the moment, it's not possible to override this method with an ooRexx method.
Examples:
*/
(1,2)~dynamicTarget=                       -- initial target: [ 1, 2]
(1,2)~dynamicTarget("string")=             -- initial target: [ 1, 2]
(1,2)~dynamicTarget("string", "teẌt")=     -- initial target: [ 1, 2]


/*
The forward instruction does not depend on the dynamic target calculation.
If you need to forward using the dynamic target then do:
    forward message "DYNAMICTARGET" continue
    forward to (result)
*/


/*
[Encoded strings]

+---------------------------------------------------------------+
|                   3rd important milestone                     |
| The String messages become polymorphic on RexxString/RexxText |
+---------------------------------------------------------------+
If at least one positional argument is a RexxText then the String message is
sent to the RexxText counterpart of the String instance, otherwise the String
message is sent to the String instance.

The RexxString class overrides the virtual method dynamicTarget:
    RexxObject *RexxString::dynamicTarget(RexxObject **arguments, size_t count, size_t named_count)
    {
        if (hasRexxTextArguments(arguments, count, named_count))
        {
            RexxText *text = this->requestText();
            return text;
        }
        return this;
    }
Examples:
*/
"Noel"~dynamicTarget=                       -- initial target: 'Noel'
"Noel"~dynamicTarget("string")=             -- initial target: 'Noel'
"Noel"~dynamicTarget("string", "teẌt")=     -- text counterpart of the initial target: T'Noel'  because "teẌt" is a RexxText


/*
Examples of dynamic target with ~center:
*/
"é"~c2x=; "é"~class=                        -- 'C3A9'   (The RexxText class)
"test"~center(10, "é")=                     -- T'ééétestééé'

"C3A9"x=; result~description=               -- T'é'     'UTF-8 not-ASCII (1 character, 1 codepoint, 2 bytes, 0 error)'
"test"~center(10, "C3A9"x)=                 -- T'ééétestééé'

x2c("C3A9")=; result~description=           -- 'é'      'UTF-8 not-ASCII by default (2 bytes)'
-- next error is ok: the pad is a string made of 2 bytes
"test"~center(10, x2c("C3A9"))=             -- Incorrect pad or character argument specified; found "é"


/*
Examples of dynamic target with ~left:
*/
"test"~left(10)=                            -- 'test      '
"test"~left(10, ".")=                       -- 'test......'
"test"~left(10, "🦖")=                     -- T'test🦖🦖🦖🦖🦖🦖'


/*
The ~~ form of message is not impacted: it always returns the initial target
*/
"test"~right(10, "é")~left(20, "è")=        -- T'éééééétestèèèèèèèèèè'
"test"~~right(10, "é")~left(20, "è")=       -- T'testèèèèèèèèèèèèèèèè'
"test"~right(10, "é")~~left(20, "è")=       -- T'éééééétest'
"test"~~right(10, "é")~~left(20, "è")=      -- 'test'


/*
[doers]

RexxText inherit from TextDoer.
Examples:
*/
"c2x"~text~do("a")=                     -- 61  (was Object "c2x" does not understand message "DO")
"ça va ?"~characters~each=              -- [T'ç',T'a',T' ',T'v',T'a',T' ',T'?']
"ça va ?"~characters~each("c2x")=       -- ['C3A7', 61, 20, 76, 61, 20,'3F']


/*
A RexxBlock has the same encoding as its definition package.
Examples:
*/
{.context~package~encoding}~()=         -- (The UTF8_Encoding class)

oldEncoding = .context~package~setEncoding("byte")
{.context~package~encoding}~()=         -- (The Byte_Encoding class)
.context~package~setEncoding(oldEncoding)

-- was: Incorrect pad or character argument specified; found "é"
-- because the package encoding of the block was The Byte_Encoding (default)
-- and the string literal "é" was not converted to a RexxText instance.
-- Now the package encoding of the block is The UTF8_Encoding and it works:
("un", "deux")~each{item~right(10, "é")}==


-- ===============================================================================
-- 2024 Apr 10

/*
+-----------------------------------------------------------+
|                  2nd important milestone                  |
| The string BIFs become polymorphic on RexxString/RexxText |
+-----------------------------------------------------------+
If at least one positional argument is a RexxText then the string BIFs forward
to RexxText, otherwise the string BIFs forward to RexxString.
Enhanced BIFs:
    ABBREV
    CENTER      implemented on RexxText
    CENTRE      implemented on RexxText
    CHANGESTR
    COMPARE     implemented on RexxText
    COPIES      implemented on RexxText
    COUNTSTR
    D2C         implemented on RexxText
    DELSTR
    DELWORD
    INSERT
    LASTPOS
    LEFT        implemented on RexxText
    LENGTH      implemented on RexxText
    LOWER       implemented on RexxText
    OVERLAY
    POS         implemented on RexxText
    REVERSE     implemented on RexxText
    RIGHT       implemented on RexxText
    SPACE
    STRIP       implemented on RexxText
    SUBSTR      implemented on RexxText
    SUBWORD
    UPPER       implemented on RexxText
    VERIFY
    WORD
    WORDINDEX
    WORDLENGTH
    WORDPOS
    WORDS
    X2C         implemented on RexxText
Examples:
*/
-- CENTER
CENTER("Noel", 10, "*")=                        -- '***Noel***'
CENTER("Noel", 10, "🤶")=                       -- T'🤶🤶🤶Noel🤶🤶🤶'  because "🤶" is a RexxText
CENTER("Noël", 10, "*")=                        -- T'***Noël***'            because "Noël" is a RexxText
CENTER("Noël"~string, 10, "*")=                 --  '**Noël***'
CENTER("Noël", 10, "🤶")=                       -- T'🤶🤶🤶Noël🤶🤶🤶'
CENTER("Noël"~string, 10, "🤶")=                -- T'🤶🤶🤶Noël🤶🤶🤶'  because "🤶" is a RexxText
CENTER("Noël", 10, "🤶"~string)=                -- T'🤶🤶🤶Noël🤶🤶🤶'  because "Noël" is a RexxText
CENTER("Noel", 10, "🤶"~string)=                -- CENTER positional argument 3 must be a single character; found "🤶"
CENTER("Noël"~string, 10, "🤶"~string)=         -- CENTER positional argument 3 must be a single character; found "🤶"

-- Other BIFs
ABBREV("Printer","Pri")=                        --  1
ABBREV("Printer 🖨","Pri")=                     -- Object "Printer 🖨" does not understand message "ABBREV"
CHANGESTR("p", "mpNoelpp", "m", 2)=             -- 'mmNoelmp'
CHANGESTR("🎅", "🤶🎅Noël🎅🎅", "🤶", 2)=   -- Object "🤶🎅Noël🎅🎅" does not understand message "CHANGESTR"
COMPARE("straSssSSssse", "stra", "S")=          -- 6
COMPARE("straßssßßssse", "stra", "ß")=          -- 6
COPIES("🤶", 4)=                                -- T'🤶🤶🤶🤶'
COUNTSTR("m", "mpmp")=                          --  2
COUNTSTR("🤶", "🤶🎅🤶🎅")=                 -- Object "🤶🎅🤶🎅" does not understand message "COUNTSTR"
D2C(65)=                                        -- 'A'
D2C(65~text)=                                   -- T'A'
DELSTR("Noel", 3, 2)=                           -- 'No'
DELSTR("Noël", 3, 2)=                           -- Object "Noël" does not understand message "DELSTR"
DELWORD("Pere Noel p", 2, 2)=                   -- 'Pere '
DELWORD("Père Noël 🎅", 2, 2)=                  -- Object "Père Noël 🎅" does not understand message "DELWORD"
INSERT("123", "abc", 5, 6, "+")=                -- 'abc++123+++'
INSERT("123", "abc", 5, 6, "🎅")=               -- Object "abc" does not understand message "INSERT"
LASTPOS("m", "mMere Noelm")=                    -- 11
LASTPOS("🤶", "🤶Mère Noël🤶")=                 -- Object "🤶Mère Noël🤶" does not understand message "LASTPOS"
LEFT("abc d",8,".")=                            -- 'abc d...'
LEFT("abc d",8,"🤶")=                           -- T'abc d🤶🤶🤶'
LENGTH("Père Noël 🎅"~string)=                  -- 16
LENGTH("Père Noël 🎅")=                         -- 11
LOWER("PÈRE NOËL")=                             -- T'père noël'
OVERLAY("123","abc",5,6,"+")=                   -- 'abc+123+++'
OVERLAY("123","abc",5,6,"🤶")=                  -- Object "abc" does not understand message "OVERLAY"
POS("Frei", "Bundesstraße im Freiland")=        -- 17
REVERSE("Noël")=                                -- T'lëoN'
RIGHT("12",5,"0")=                              --  00012
RIGHT("12",5,"𝟶")=                             -- T'𝟶𝟶𝟶12'
SPACE("abc  def  ",2,"+")=                      -- 'abc++def'
SPACE("abc  def  ",2,"⊕")=                      -- Object "abc  def  " does not understand message "SPACE"
STRIP("12.0000", "T", '.0')=                    --  12
STRIP("12.øøøø", "T", '.ø')=                   -- T'12'    where 'ø'~c2x='C3B8'.
STRIP(("12.øø" || "C3"x || "øø")~string, "T", '.ø'~string)=    --  12  Every byte of the last parameter is searched and removed
STRIP("12.øø" || "C3"x || "øø", "T", '.ø')=                    -- Invalid UTF-8 string (raised by utf8proc)
STRIP(("12.øø" || "C3"x || "øø")~transcodeTo("ISO-8859-1", replacementCharacter:"#"), "T", '.ø'~transcodeTo("ISO-8859-1"))=   -- T'12.??#'
SUBSTR("abc",2,6,".")=                          -- 'bc....'
SUBSTR("abc",2,6,"🤶")=                         -- T'bc🤶🤶🤶🤶'
SUBWORD("Now is   the time",2,2)=               -- 'is   the'
SUBWORD("Now is   the 🕑",2,2)=                 -- Object "Now is   the 🕑" does not understand message "SUBWORD"
UPPER("père noël")=                             -- T'PÈRE NOËL'
VERIFY("ABCDEF","ABC","N",2,3)=                 --  4
VERIFY("ABCDEF","ABC","N"~text,2,3)=            -- Object "ABCDEF" does not understand message "VERIFY" (yes! ANY parameter is tested, including the option)
WORD("Now is the time",3)=                      -- 'the'
WORD("Now is the 🕑",3)=                        -- Object "Now is the 🕑" does not understand message "WORD"
WORDINDEX("Now is the time",3)=                 --  8
WORDINDEX("Now is the 🕑",3)=                   -- Object "Now is the 🕑" does not understand message "WORDINDEX"
WORDLENGTH("Now is the time",4)=                --  4
WORDLENGTH("Now is the 🕑",4)=                  -- Object "Now is the 🕑" does not understand message "WORDLENGTH"
WORDPOS("the","Now is the time")=               --  3
WORDPOS("the","Now is the 🕑")=                 -- Object "Now is the 🕑" does not understand message "WORDPOS"
WORDS("Now is the time")=                       --  4
WORDS("Now is the 🕑")=                         -- Object "Now is the 🕑" does not understand message "WORDS"
X2C(41)=                                        -- 'A'
X2C(41~text)=                                   -- T'A'


/*
Still not sure:
When the target is a String, should the BIF d2c and x2c return a RexxText when
the result is not-ASCII and the evaluation context encoding is not Byte?
That would be consistent with the rules for string literal (R1, R2).
Currently, assuming the package encoding is UTF-8:
"FF"x is a RexxText but x2c("FF") is a String.
And what about "FF"~x2c? currently it's a String.
Examples:
*/
"FF"x=;result~description=                      -- T'[FF]'      'UTF-8 not-ASCII (1 character, 1 codepoint, 1 byte, 1 error)'
x2c("FF")=;result~description=                  -- '[FF]'       'UTF-8 not-ASCII by default (1 byte)'
"FF"~x2c=;result~description=                   -- '[FF]'       'UTF-8 not-ASCII by default (1 byte)'
"FF"~text~x2c=;result~description=              -- T'[FF]'      'UTF-8 not-ASCII (1 character, 1 codepoint, 1 byte, 1 error)'
"FF"~text("cp1252")~x2c=;result~description=    -- T'[FF]'      'windows-1252 not-ASCII (1 character, 1 codepoint, 1 byte, 0 error)'
---
"41"x=;result~description=                      -- 'A'          'UTF-8 ASCII (1 byte)'
x2c("41")=;result~description=                  -- 'A'          'UTF-8 ASCII by default (1 byte)'
"41"~x2c=;result~description=                   -- 'A'          'UTF-8 ASCII by default (1 byte)'
"41"~text~x2c=;result~description=              -- T'A'         'UTF-8 ASCII (1 character, 1 codepoint, 1 byte, 0 error)'
"41"~text("cp1252")~x2c=;result~description=    -- T'A'         'windows-1252 ASCII (1 character, 1 codepoint, 1 byte, 0 error)'


-- ===============================================================================
-- 2024 Apr 03

/*
No longer apply the rule R3 during the automatic conversion of String literals
to RexxText instances. If the package encoding is not a byte encoding then any
not-ASCII String literal is converted to a RexxText, whatever its encoding.
Reason: inconsistency between
    "noel" "FF"x~~setEncoding("cp1252")=        -- 'noel [FF]' because concatenation of 2 String instances
    "noël" "FF"x~~setEncoding("cp1252")=        -- Encoding: cannot append... because concatenation of a RexxText with a String
Now:
*/
    "FF"x=                                      -- T'[FF]'  (was a String thanks to R3)
    "noel" "FF"x~~setEncoding("cp1252")=        -- Encoding: cannot append windows-1252 not-ASCII '[FF]' to UTF-8 ASCII 'noel'   (was 'noel [FF]')
                                                -- Note: no longer "by default" in "UTF-8 ASCII 'noel'" because the string literal has now a stored encoding
/*
Unchanged:
*/
    "noël" "FF"x=                               -- T'noël [FF]'     no error because the Byte_Encoding is always absorbed
    "FF"x "noël"=                               -- T'[FF] noël'     idem
    "noël" "FF"x~~setEncoding("cp1252")=        -- Encoding: cannot append windows-1252 not-ASCII '[FF]' to UTF-8 not-ASCII 'noël'
    "FF"x~~setEncoding("cp1252") "noël"=        -- Encoding: cannot append UTF-8 not-ASCII 'noël' to windows-1252 not-ASCII '[FF]'


-- ===============================================================================
-- 2024 Apr 01

/*
A package has an encoding:
.Package
    encoding
    encoding=
    hasEncoding
Rules for the calculation of a package default encoding:
Case 1: package not requesting "text.cls", directly or indirectly.
    Most of the legacy packages don't support an automatic conversion to text.
    The package's default encoding is Byte (not .Encoding~defaultEncoding).
Case 2: package requesting "text.cls", directly or indirectly.
    We assume that the requester supports an automatic conversion to text.
    The package's default encoding is .Encoding~defaultEncoding.
*/


/*
New method setEncoding on String, MutableBuffer, Package and RexxText, to change
the current encoding and return the previous encoding.
The bytes are not impacted, it's just an update of the encoding annotation.
Example, assuming the default encoding is UTF-8:
*/
"Noel"~setEncoding("windows-1252")=     -- (The UTF8_Encoding class)    (previous encoding)
"Noël"~setEncoding("byte")=             -- (The UTF8_Encoding class)    (previous encoding)
/*
Example, when the default encoding is Byte:
*/
oldEncoding = .encoding~setDefaultEncoding("byte")
"Noel"~setEncoding("windows-1252")=     -- (The Byte_Encoding class)    (previous encoding)
"Noël"~setEncoding("byte")=             -- (The Byte_Encoding class)    (previous encoding)
.encoding~setDefaultEncoding(oldEncoding)


/*
New methods on the class Encoding, to change the current encoding and return
the previous encoding:
    setDefaultEncoding
    setDefaultInputEncoding
    setDefaultOutputEncoding
*/


/*
Relax the constraints for the Byte_Encoding in the methods compatibleEncoding
and asEncodingFor: The Byte_Encoding can be always absorbed.
Reason: The Byte_Encoding is often used for diagnostic or repair.
Examples:
*/
"Père"~c2g=                             -- '50 C3A8 72 65'
"Père"~text~startsWith("50C3"x~byte)=   -- false (not aligned) (was Encoding: cannot compare Byte not-ASCII 'P\C3' with UTF-8 not-ASCII 'Père')
"Père"~text~startsWith("50C3A8"x~byte)= -- true (was Encoding: cannot compare Byte not-ASCII 'Pè' with UTF-8 not-ASCII 'Père')


/*
+-------------------------------------------+
|          1st important milestone          |
| Activation of the automatic conversion    |
| of String literals to RexxText instances  |
+-------------------------------------------+
This is managed in RexxString::evaluate
Rules:
if string~isASCII then value = string                               -- R1 don't convert to RexxText if the string literal is ASCII (here, NO test of encoding, just testing the bytes)
else if .context~package~encoding~isByte then value = string        -- R2 don't convert to RexxText if the encoding of its definition package is the Byte_Encoding or a subclass of it (legacy package).
-- else if string~isCompatibleWithByteString then value = string    -- R3 (no longer applied) don't convert to RexxText if the string literal is compatible with a Byte string.
else value = string~text                                            -- R4 convert to RexxText
Examples, assuming the package encoding is UTF-8:
*/
"Noel"~class=                                       -- (The String class)       R1

oldEncoding = .context~package~setEncoding("byte")
"Noël"~class=                                       -- (The String class)       R2
.context~package~setEncoding(oldEncoding)

-- The rule R3 is no longer applied
-- The only way to test it is to use an hexadecimal (or binary) string literal.
-- [later] The hexadecimal string literals are no longer Byte encoded, so this test is no longer a good test
"Noël"~c2x=                                         -- '4E 6F C3AB 6C'
'4E 6F C3AB 6C'x~encoding=                          -- (The UTF8_Encoding class) (was (The Byte_Encoding class) so R3 could apply, but we no longer apply it)
'4E 6F C3AB 6C'x~class=                             -- (The RexxText class)     R4

"Noël"~class=                                       -- (The RexxText class)     R4
"Noël"~string~class=                                -- (The String class)       R4 The string literal is a RexxText, the method ~string returns a String with encoding UTF-8
"Noël"~~setEncoding("byte")~class=                  -- (The RexxText class)     R4 The string literal is a RexxText, its encoding is changed from UTF-8 to Byte
"Noël"~~setEncoding("byte")~string~class=           -- (The String class)       R4 The string literal is a RexxText, its encoding is changed from UTF-8 to Byte, the method ~string returns a String with encoding Byte


/*
Deactivate (again) the constraint "self~isCompatibleWithByteString" when converting
a RexxText to a String (.Unicode~unckeckedConversionToString = .true).
Reason: after activation of the automatic conversion to RexxText, I get these
errors if I keep the constraint "self~isCompatibleWithByteString".
    say "Noël"              -- raise an error "UTF-8 not-ASCII 'Noël' cannot be converted to a String instance"
    xrange("00"x,"ff"x)     -- raise an error "UTF-8 not-ASCII '[FF]' cannot be converted to a String instance"
The constraint "self~isCompatibleWithByteString" was put in place to detect when
a RexxText instance is "lost" during conversion to string. Now that we have a
common interface on String and RexxText, plus an automatic conversion to RexxText,
this "loss" should occur less often. But still occurs.
Example, assuming the default encoding and the package encoding are UTF-8:
*/
"Noël"~length=          -- 4
"Noël"~text~length=     -- 4
"Noël"~string~length=   -- 5
length("Noël")=         -- 4    (was 5, should be 4    (with the constraint, would raise UTF-8 not-ASCII 'Noël' cannot be converted to a String instance))
length("Noël"~string)=  -- 5


/*
----------
ABANDONNED
(incompatible with the decision to assign the encoding of the definition package
to the string literals)
----------
The strings created by D2C, X2C are declared Byte encoded.
It's because it's not unusual to create ill-formed encoded strings with these BIF/BIM.
The Byte_Encoding is a raw encoding with few constraints, BUT it's impossible
to transcode from/to it without errors if the string contains not-ASCII characters.
That's why, often, a more specialized byte encoding is applied on the byte string,
to interpret the bytes differently.
Implementation notes:
    D2C: RexxNumberString::d2xD2c calls StringUtil::packHex
    X2C: StringUtil::packHex
Examples:
*/
"é"~encoding=                                   -- (The UTF8_Encoding class)

-- D2C
"é"~c2d=                                       -- 50089
d2c(50089)=                                     -- 'é'
50089~d2c=                                      -- 'é'
d2c(50089)~encoding=                            -- (The UTF8_Encoding class)    (was (The Byte_Encoding class))
50089~d2c~encoding=                             -- (The UTF8_Encoding class)    (was (The Byte_Encoding class))

-- X2C
"é"~c2x=                                        -- 'C3A9'
x2c("C3A9")=                                    -- 'é'
"C3A9"~x2c=                                     -- 'é'
x2c("C3A9")~encoding=                           -- (The UTF8_Encoding class)    (was (The Byte_Encoding class))
"C3A9"~x2c~encoding=                            -- (The UTF8_Encoding class)    (was (The Byte_Encoding class))

-- Valid Byte string, but invalid UTF-8 string
"C3"~x2c~class=                                 -- (The String class)
"C3"~x2c~encoding=                              -- (The UTF8_Encoding class)    (was (The Byte_Encoding class))
-- Apply an UTF-8 view through the String interface
"C3"~x2c~~setEncoding("utf8")~description=      -- 'UTF-8 not-ASCII (1 byte)'
"C3"~x2c~~setEncoding("utf8")~errors=           -- 'UTF-8 encoding: byte sequence at byte-position 1 is truncated, expected 2 bytes.'
-- Apply an UTF-8 view through the RexxText interface
"C3"~x2c~text("utf8")~description=              -- 'UTF-8 not-ASCII (1 character, 1 codepoint, 1 byte, 1 error)'
"C3"~x2c~text("utf8")~errors=                   -- 'UTF-8 encoding: byte sequence at byte-position 1 is truncated, expected 2 bytes


/*
----------
ABANDONNED
(incompatible with the decision to assign the encoding of the definition package
to the string literals)
----------
The hexadecimal and binary strings are declared Byte encoded, for the same reasons
as D2C, X2C.
Implementation notes:
    RexxSource::packLiteral (Scanner.cpp)
Examples:
*/
-- The encoding of a string literal is the encoding of its definition package.
"é"~encoding=                                   -- (The UTF8_Encoding class)

-- The encoding of an hexadecimal string is the Byte encoding.
"é"~c2x=                                        -- 'C3A9'
"C3A9"x=                                        -- T'é'
"C3A9"x~encoding=                               -- (The UTF8_Encoding class)    (was (The Byte_Encoding class))

-- The encoding of a binary string is the Byte encoding.
"é"~c2x~x2b=                                    -- 1100001110101001
"11000011 10101001"b=                           -- T'é'
"11000011 10101001"b~encoding=                  -- (The UTF8_Encoding class)    (was (The Byte_Encoding class))


/*
Implementation of Strip:
*/
"Noël"~strip=                       -- T'Noël'
"\tNoël "~unescape~strip=           -- T'Noël'
"Noël"~strip("b", "ë")=             -- T'Noël'
"Noë"~strip("b", "ë")=              -- T'No'
"🤶Noël🎅"~strip("b", "lë🎅🤶")=  -- T'No'
"\u{NBSP}\u{EN SPACE}\u{EM SPACE}\u{HAIR SPACE}\u{FIGURE SPACE}\u{THIN SPACE}"~unescape~strip=          -- T'      '
"\u{NBSP}\u{EN SPACE}\u{EM SPACE}\u{HAIR SPACE}\u{FIGURE SPACE}\u{THIN SPACE}"~unescape~strip(lump:)=   -- T''


/*
New methods on String for compatibility with RexxText (inherit StringRexxTextInterface).
Most of these methods forward to string~text.
*/
"a"~errors=                                 -- (The NIL object)
"a"~isCompatibleWithASCII=                  -- 1
"a"~isCompatibleWithByteString=             -- 1
"a"~isUpper=                                -- 0
"A"~isUpper=                                -- 1
"a"~isLower=                                -- 1
"A"~isLower=                                -- 0
"a"~codepoints=                             -- (a CodePointSupplier)
"a"~maximumCodepoint=                       -- 97
"a"~maximumUnicodeCodepoint=                -- 97
"a"~UnicodeCharacters=                      -- [( "a"   U+0061 Ll 1 "LATIN SMALL LETTER A" )]
"a"~characters=                             -- ['a']
"a"~character(1)=                           -- 'a'
buffer = .MutableBuffer~new; "a"~character(1, :buffer)=     -- M'a'
"a"~transcodeTo("utf16")=                   -- T'[00]a'
"a"~utf8=                                   -- T'a'
"a"~wtf8=                                   -- T'a'
"a"~utf16=                                  -- T'[00]a'
"a"~utf16be=                                -- T'[00]a'
"a"~utf16le=                                -- T'a[00]'
"a"~wtf16=                                  -- T'[00]a'
"a"~wtf16be=                                -- T'[00]a'
"a"~wtf16le=                                -- T'a[00]
"a"~utf32=                                  -- T'[000000]a'
"a"~utf32be=                                -- T'[000000]a'
"a"~utf32le=                                -- T'a[000000]'
"a"~unicode~c2x=                            -- 61
"a"~unicodeN~c2x=                           -- 61
"a"~unicode8~c2x=                           -- 61
"a"~unicode16~c2x=                          -- 6100
"a"~unicode32~c2x=                          -- 61000000
"a"~c2u=                                    -- 'U+0061'
'U+0061'~u2c=                               -- T'a[000000]'
'U+0061'~u2c~c2x=                           -- 61000000
'U+0061'~u2c~utf8=                          -- T'a'
"ab"~c2g=                                   -- '61 62'
"z"~checkHexadecimalValueCompatibility=     -- [no result] (good, no error raised)
"z"~checkNumericValueCompatibility=         -- [no result] (good, no error raised)
"z"~checkLogicalValueCompatibility=         -- [no result] (good, no error raised)
"\u{FLAG IN HOLE}"~unescape=                -- T'⛳'
"a"~transform=                              -- T'a'
"a"~transformer=                            -- (a RexxTextTransformer)
"abc def"~title=                            -- T'Abc Def'
"a"~isNFC=                                  -- 1
"a"~NFC=                                    -- T'a'
"a"~isNFD=                                  -- 1
"a"~NFD=                                    -- T'a'
"a"~isNFKC=                                 -- 1
"a"~NFKC=                                   -- T'a'
"a"~isNFKD=                                 -- 1
"a"~NFKD=                                   -- T'a'
"a"~isCasefold=                             -- -1
"A"~isCasefold=                             -- -1
"a"~transform(casefold:)~isCasefold=        -- 1
"A"~transform(casefold:)~isCasefold=        -- 1
"a"~casefold=                               -- T'a'
"A"~casefold=                               -- T'a'
"a"~isMarkStripped=                         -- -1
"a"~transform(stripMark:)~isMarkStripped=   -- 1
"a"~isIgnorableStripped=                    -- -1
"a"~transform(stripIgnorable:)~isIgnorableStripped=     -- 1
"a"~isCCStripped=                           -- -1
"a"~transform(stripCC:)~isCCStripped=       -- 1
"a"~isNAStripped=                           -- -1
"a"~transform(stripNA:)~isNAStripped=       -- 1
"ab"~graphemes=                             -- ['a','b']
"ab"~grapheme(1)=                           -- 'a'


/*
Implementation of the abstract method 'transform' for Byte_Encoding and its subclasses.
Parameters:
    normalization = 0           Ignored, there is no normalization for byte strings.
    casefold = .false           if .true then apply ~lower
    lump= .false                Ignored
    stripMark = .false          if .true then replace the accented letters by their base letter
    stripIgnorable= .false      Ignored
    stripCC = .false            if .true then remove the codepoints < 20x
    stripNA = .false            if .true then remove the unassigned codepoints
Examples:
*/
-- casefold
"Père Noël"~transcodeTo("windows-1252")=                                                     -- T'P?re No?l'
"Père Noël"~transcodeTo("windows-1252")~c2x=                                                 -- '50 E8 72 65 20 4E 6F EB 6C'
'50 E8 72 65 20 4E 6F EB 6C'x~byte~transform(casefold:)=                                     -- T'p?re no?l'
'50 E8 72 65 20 4E 6F EB 6C'x~byte~transform(casefold:)~encoding=                            -- (The Byte_Encoding class)
'50 E8 72 65 20 4E 6F EB 6C'x~byte~transform(casefold:)~utf8=                                -- Cannot convert Byte not-ASCII character 232 (E8) at byte-position 2 to UTF-8
'50 E8 72 65 20 4E 6F EB 6C'x~byte~transform(casefold:)~~setEncoding("windows-1252")~utf8=   -- T'père noël'

-- stripMark depends on the encoding
"80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F 90 93 94 95 96 97 98 99 9A 9F A0 A1 A2 A3 A4 A5"x~text("ibm-437")~utf8=                           -- T'ÇüéâäàåçêëèïîìÄÅÉôöòûùÿÖÜƒáíóúñÑ'
"80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F 90 93 94 95 96 97 98 99 9A 9F A0 A1 A2 A3 A4 A5"x~text("ibm-437")~transform(stripMark:)~utf8=     -- T'CueaaaaceeeiiiAAEooouuyOUfaiounN'
"83 8A 9A 9F C0 C1 C2 C3 C4 C5 C7 C8 C9 CA CB CC CD CE CF D1 D2 D3 D4 D5 D6 D8 D9 DA DB DC DD E0 E1 E2 E3 E4 E5 E7 E8 E9 EA EB EC ED EE EF F1 F2 F3 F4 F5 F6 F8 F9 FA FB FC FD FF"x~text("ibm-1252")~utf8=                        -- T'ƒŠšŸÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöøùúûüýÿ'
"83 8A 9A 9F C0 C1 C2 C3 C4 C5 C7 C8 C9 CA CB CC CD CE CF D1 D2 D3 D4 D5 D6 D8 D9 DA DB DC DD E0 E1 E2 E3 E4 E5 E7 E8 E9 EA EB EC ED EE EF F1 F2 F3 F4 F5 F6 F8 F9 FA FB FC FD FF"x~text("ibm-1252")~transform(stripMark:)~utf8=  -- T'fSsYAAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuyy'
"C0 C1 C2 C3 C4 C5 C7 C8 C9 CA CB CC CD CE CF D1 D2 D3 D4 D5 D6 D8 D9 DA DB DC DD E0 E1 E2 E3 E4 E5 E7 E8 E9 EA EB EC ED EE EF F1 F2 F3 F4 F5 F6 F8 F9 FA FB FC FD FF"x~text("iso-8859-1")~utf8=                            -- T'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöøùúûüýÿ'
"C0 C1 C2 C3 C4 C5 C7 C8 C9 CA CB CC CD CE CF D1 D2 D3 D4 D5 D6 D8 D9 DA DB DC DD E0 E1 E2 E3 E4 E5 E7 E8 E9 EA EB EC ED EE EF F1 F2 F3 F4 F5 F6 F8 F9 FA FB FC FD FF"x~text("iso-8859-1")~transform(stripMark:)~utf8=      -- T'AAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuyy'
"83 8A 8E 9A 9E 9F C0 C1 C2 C3 C4 C5 C7 C8 C9 CA CB CC CD CE CF D1 D2 D3 D4 D5 D6 D8 D9 DA DB DC DD E0 E1 E2 E3 E4 E5 E7 E8 E9 EA EB EC ED EE EF F1 F2 F3 F4 F5 F6 F8 F9 FA FB FC FD FF"x~text("windows-1252")~utf8=                            -- T'ƒŠŽšžŸÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöøùúûüýÿ'
"83 8A 8E 9A 9E 9F C0 C1 C2 C3 C4 C5 C7 C8 C9 CA CB CC CD CE CF D1 D2 D3 D4 D5 D6 D8 D9 DA DB DC DD E0 E1 E2 E3 E4 E5 E7 E8 E9 EA EB EC ED EE EF F1 F2 F3 F4 F5 F6 F8 F9 FA FB FC FD FF"x~text("windows-1252")~transform(stripMark:)~utf8=      -- T'fSZszYAAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuyy'

-- several transformations
"Père Noël"~transcodeTo("windows-1252")~transform(casefold:, stripMark:)~utf8=                      -- T'pere noel'
'50 E8 72 65 20 4E 6F EB 6C'x~~setEncoding("windows-1252")~transform(casefold:, stripMark:)~utf8=   -- T'pere noel'
-- next: the transform is done on Byte string, which has no rule for stripMark.
-- the accents are not removed.
'50 E8 72 65 20 4E 6F EB 6C'x~byte~transform(casefold:, stripMark:)~~setEncoding("windows-1252")~utf8=   -- T'père noël'


-- ===============================================================================
-- 2024 Mar 17

/*
For consistency with other methods, add the optional named argument 'buffer' to
    []
    c2g
    c2x
    x2b
    x2d
Examples:
*/
buffer = .MutableBuffer~new
"Tête à tête"~text[2, 5, :buffer]=  -- M'ête à'
"A"~text~c2g(:buffer)=              -- M'ête à41'
"A"~text~c2x(:buffer)=              -- M'ête à4141'
"41"~text~x2b(:buffer)=             -- M'ête à414101000001'
"41"~text~x2d(:buffer)=             -- M'ête à41410100000165'


/*
For compatibility with Python, add support for \N{Unicode name}.
Example:
*/
"\N{for all} x \N{there exists} y such that x+y=0"~text~unescape=       -- T'∀ x ∃ y such that x+y=0'


/*
Add support for code point labels.
Examples:
*/
.unicode~character("<control-000A>")=           -- ( ""    U+000A Cc 0 "", "LINE FEED", "NEW LINE", "END OF LINE", "LF", "NL", "EOL" )
"hello\N{<control-000A>}bye"~text~unescape=     -- T'hello[0A]bye'
"hello\U{<control-000A>}bye"~text~unescape=     -- T'hello[0A]bye'


/*
Modify the display of UnicodeCharacter properties to show the codepoint values
in U+ and 0x notation.
*/
.Unicode["🤶"]~properties=


/*
Modification of the rule for buffer encoding neutrality.
    old: If left is a        buffer with no encoding then use the right encoding.
    new: If left is an empty buffer with no encoding then use the right encoding.
Impacted methods:
    .Encoding~compatibleEncoding
    .StringIndexer~asEncodingFor
Examples:
*/
buffer = .MutableBuffer~new
-- This is an empty buffer with no explicit encoding:
-- The rule for encoding neutrality will apply.
buffer~description=                                                     -- 'UTF-8 ASCII by default (0 byte)'
"Test"~text~utf16~left(2, :buffer)=                                     -- M'[00]T[00]e'
-- The buffer encoding is now UTF-16BE.
buffer~description=                                                     -- 'UTF-16BE (4 bytes)'

buffer = .MutableBuffer~new("not empty")
buffer~description=                                                     -- 'UTF-8 ASCII (9 bytes)'
                                                                        -- Note: no longer "UTF-8 ASCII by default" because the string literal has now a stored encoding
-- Here, the rule for encoding neutrality does not apply.
"Test"~text~utf16~left(2, :buffer)=                                     -- Encoding: cannot append UTF-16BE to UTF-8 ASCII 'not empty'
                                                                        -- Note: no longer "UTF-8 ASCII by default" because the string literal has now a stored encoding


/*
New method ~u2c on String and RexxText.
Create a Unicode32 text from a sequence of U+xxxx.
The U+ string/text must be compatible with a byte encoding (Byte or subclass,
UTF-8 ASCII, WTF-8 ASCII).
In other words, will not support a sequence of U+xxxx encoded in UTF-16 or UTF-32.
Examples:
*/
-- U+ string
"U+004E u+006F U+00EB U+006C U+1F936 U+1F385"~u2c~description=          -- 'Unicode32 (6 characters, 6 codepoints, 24 bytes, 0 error)'
"U+004E u+006F U+00EB U+006C U+1F936 U+1F385"~u2c~c2x=                  -- '4E000000 6F000000 EB000000 6C000000 36F90100 85F30100'
"U+004E u+006F U+00EB U+006C U+1F936 U+1F385"~u2c~utf8=                 -- T'Noël🤶🎅'

-- U+ text
"U+004E u+006F U+00EB U+006C U+1F936 U+1F385"~text~u2c~description=     -- 'Unicode32 (6 characters, 6 codepoints, 24 bytes, 0 error)'
"U+004E u+006F U+00EB U+006C U+1F936 U+1F385"~text~u2c~c2x=             -- '4E000000 6F000000 EB000000 6C000000 36F90100 85F30100'
"U+004E u+006F U+00EB U+006C U+1F936 U+1F385"~text~u2c~utf8=            -- T'Noël🤶🎅'

buffer = .MutableBuffer~new
"U+0031 U+0032"~text~u2c(:buffer)=                                      -- M'1[000000]2[000000]'
-- The buffer encoding is now Unicode32.
buffer~description=                                                     -- 'Unicode32 (8 bytes)'

-- Examples of invalid U+ string/text
"U+004E u+006F U+00EB U+006C U+1F936 U+1F385"~text~utf16~u2c=           -- UTF-16BE '[00]U[00]+[00]0[00]0[00]4[00]E[00] ...' is not compatible with an U+ string.
"A+004E"~u2c=                                                           -- Expecting U+ or u+ followed by 4..6 hex digits, got 'A+004E'
"u+4E"~u2c=                                                             -- Expecting U+ or u+ followed by 4..6 hex digits, got 'u+4E'
"u+000004E"~u2c=                                                        -- Expecting U+ or u+ followed by 4..6 hex digits, got 'u+000004E'


/*
New supported methods on RexxText:
- d2c       forward to String, return a Text or a MutableBuffer
- d2x       forward to String, return a String or a MutableBuffer
Examples:
*/
"65"~text~d2c=              -- T'A'
"65"~text~d2x=              -- 41
buffer = .MutableBuffer~new
"65"~text~d2c(:buffer)=     -- M'A'
"65"~text~d2x(:buffer)=     -- M'A41'
buffer~encoding = "utf16"
"65"~text~d2c(:buffer)=     -- Encoding: cannot append Byte ASCII 'A' to UTF-16BE 'A41'


/*
Partial implementation of translate (ASCII string only):
Examples:
*/
"hello"~text~translate=              -- 'HELLO'
"hello"~text~translate(,,"x")=       -- 'xxxxx'
"hello"~text~translate(,"el","x")=   -- 'hxxxo'


-- ===============================================================================
-- 2023 Dec 04

/*
Reworked the implementation of caselessMatchChar, matchCar.
*/

"Bundesschnellstraße"~text~caselessMatchChar(18, "s")=           -- now 0: "ß" casefolded to "ss" doesn't match "s"
"BAFFLE"~text~caselessMatchChar(5, "ﬄ")=                        -- now 0: "L" casefolded to "l" doesn't match "ﬄ" casefolded to "ffl" (no more iteration on each character of "ffl")
"baﬄe"~text~matchChar(3, "f", normalization:.Unicode~NFKD)=     -- now 0: "ﬄ" transformed to "ffl" doesn't match "f"

/*
After rework, I have these other differences:
*/

-- Case 1 sounds good (no more iteration on each character of "ffl")
"BAFFLE"~text~caselessMatchChar(3, "ﬄ")=        -- 0    was 1 "ﬄ" becomes "ffl" (3 graphemes), there is a match on "f" at 3
"BAFFLE"~text~caselessPos("ﬄ", aslist:, aligned:0)=
/*
    a List (1 items)
     0 : [+3.3,+6.6]
*/
-- I get the same result as before by explicitely decomposing the ligature "ﬄ" to "ffl" BEFORE :
"BAFFLE"~text~caselessMatchChar(3, "ﬄ"~text~transform(normalization:.Unicode~NFKD))=    -- 1
-- here, it's ok because the match is on several characters
"BAFFLE"~text~caselessMatch(3, "ﬄ")=            -- 1


-- Case 2 sounds good (no more iteration on each character of "ffl")
"BAFFLE"~text~caselessMatchChar(5, "ﬄ")=        -- 0    was 1 "ﬄ" becomes "ffl" (3 graphemes), there is a match on "l" at 5
"BAFFLE"~text~caselessMatch(5, "ﬄ")=            -- 0


-- Case 3 sounds good (no more iteration on each character of "ffl")
"baﬄe"~text~caselessMatchChar(3, "F")=          -- 0    was 1 "ﬄ" at 3 (1 grapheme) becomes "ffl" (3 graphemes), there is a match on "f"


-- Case 4 sound good (hum... did I really think that the character "ﬄ" at pos 3 can match an "l"?)
"baﬄe"~text~caselessMatchChar(3, "L")=          -- 0    was 1 "ﬄ" at 3 (1 grapheme) becomes "ffl" (3 graphemes), there is a match on "l"


-- ===============================================================================
-- 2023 Nov 28

/*
https://github.com/unicode-org/icu4x/issues/4365
Segmenter does not work correctly in some languages
        let text = "as `নমস্কাৰ, আপোনাৰ কি খবৰ?`
    hi `हैलो, क्या हाल हैं?`
    mai `नमस्ते अहाँ केना छथि?`
    mr `नमस्कार, कसे आहात?`
    ne `नमस्ते, कस्तो हुनुहुन्छ?`
    or `ନମସ୍କାର ତୁମେ କେମିତି ଅଛ?`
    sa `हे त्वं किदं असि?`
    te `హాయ్, ఎలా ఉన్నారు?`";
icu4c: 151
rust: 161
---
ICU4X and ICU4C are just using different definitions of EGCs; ICU4C has had a
tailoring for years which has just been incorporated into Unicode 15.1, whereas
ICU4X implements the 15.0 version without that tailoring.
The difference is the handling of aksaras in some indic scripts:
in Unicode 15.1 (and in any recent ICU4C) क्या is one EGC, but it is two EGCs
(क्, या) in untailored Unicode 15.0 (and in ICU4X).
---
executor: 151
*/
s="as `নমস্কাৰ, আপোনাৰ কি খবৰ?`"'0D'x"hi `हैलो, क्या हाल हैं?`"'0D'x"mai `नमस्ते अहाँ केना छथि?`"'0D'x"mr `नमस्कार, कसे आहात?`"'0D'x"ne `नमस्ते, कस्तो हुनुहुन्छ?`"'0D'x"or `ନମସ୍କାର ତୁମେ କେମିତି ଅଛ?`"'0D'x"sa `हे त्वं किदं असि?`"'0D'x"te `హాయ్, ఎలా ఉన్నారు?`"
s~text~length=  -- 151


/*
https://boyter.org/posts/unicode-support-what-does-that-actually-mean/
According wikipedia the character ſ is a long s. Which means if you want to
support unicode you need to ensure that if someone does a case insensitive
comparison then the following examples are all string equivalent.
ſecret == secret == Secret
ſatisfaction == satisfaction == ſatiſfaction == Satiſfaction == SatiSfaction === ſatiSfaction
*/
"ſ"~text~casefold=                                      -- "s"
"ſecret"~text~caselessEquals("secret")=                 -- 1
"ſecret"~text~caselessEquals("Secret")=                 -- 1
"ſatisfaction"~text~caselessEquals("satisfaction")=     -- 1
"satisfaction"~text~caselessEquals("ſatiſfaction")=     -- 1
"ſatiſfaction"~text~caselessEquals("Satiſfaction")=     -- 1
"Satiſfaction"~text~caselessEquals("SatiSfaction")=     -- 1
"SatiSfaction"~text~caselessEquals("ſatiSfaction")=     -- 1


-- ===============================================================================
-- 2023 Nov 21

/*
To rework? matchChar sometimes returns .true whereas pos returns 0.
Examples in demoTextCompatibility:

KO? 2023.12.04: yes
*/
"Bundesschnellstraße"~text~caselessMatchChar(18, "s")=      -- now 0, was 1 before 2023.12.04
"Bundesschnellstraße"~text~caselessPos("s", aslist:, aligned:0)=
/*
    a List (5 items)
     0 : [+6.6,+7.7]
     1 : [+7.7,+8.8]
     2 : [+14.14,+15.15]
     3 : [+18.18,-18.19]
     4 : [-18.19,+19.20]
*/

/*
KO? 2023.12.04: yes
*/
"BAFFLE"~text~caselessMatchChar(5, "ﬄ")=                    -- now 0, was 1 before 2023.12.04
"BAFFLE"~text~caselessPos("ﬄ", aslist:, aligned:0)=
/*
    a List (1 items)
     0 : [+3.3,+6.6]
*/

/*
KO? 2023.12.04: yes
*/
"baﬄe"~text~matchChar(3, "f", normalization:.Unicode~NFKD)=     -- now 0, was 1 before 2023.12.04
"baﬄe"~text~pos("f", normalization:.Unicode~NFKD, aslist:, aligned:0)=
/*
    a List (2 items)
     0 : [+3.3,-3.4]
     1 : [-3.4,-3.5]
*/


-- ===============================================================================
-- 2023 Nov 17

/*
Rework the implementation of caselessCompare, to get the right answer here:
*/
"sss"~text~caselessCompare("", "ß")=                --  3 (not  4 because the 3rd  's' matches only half of the casefolded pad "ß" which is "ss")
"straßssßßssse"~text~caselessCompare("stra", "ß")=  -- 12 (not 13 because the last 's' matches only half of the casefolded pad "ß" which is "ss")

/*
Analysis using Unicode scalars:

-----------------------------------------
CASE 1 : aligned in self, aligned in arg1
-----------------------------------------
*/

"straßssßßssse"~text~compare("stra", "ß")=          --  6
/*
    "straßssßßssse"~text~unicode~c2g=
         1  2  3  4  5  6  7  8  9  0  1  2  3      -- (external character indexes)
         s  t  r  a  ß  s  s  ß  ß  s  s  s  e
         73 74 72 61 DF 73 73 DF DF 73 73 73 65     -- (unicode scalars)
    -------------------------------------------
    "straßßßßßßßßß"~text~unicode~c2g=
         1  2  3  4  5  6  7  8  9  0  1  2  3      -- (external character indexes)
         s  t  r  a  ß  ß  ß  ß  ß  ß  ß  ß  ß
         73 74 72 61 DF DF DF DF DF DF DF DF DF     -- (unicode scalars)
                        |
                        first different unicode scalar
*/

/*
Debug output: the indexer supports the named parameter debug
"straßssßßssse"~text~indexer~compare("stra", "ß", debug:.true)=
    selfTextTransformer~iSubtext~string = straßssßßssse
    selfTextTransformer~iSubtext~c2g = 73 74 72 61 C39F 73 73 C39F C39F 73 73 73 65
    selfTextTransformedString~length = 16
    textTextTransformer~iSubtext~string = straßßßßßßßßß
    textTextTransformer~iSubtext~c2g = 73 74 72 61 C39F C39F C39F C39F C39F C39F C39F C39F C39F
    textTextTransformedString~length = 22
    posB1 = 7
    posC1 = +6.7
    posB2 = 7
    posC2 = +6.7
     6
*/


/*
---------------------------------------------
CASE 2 : aligned in self, not aligned in arg1
---------------------------------------------
*/

"straßssßßssse"~text~caselessCompare("stra", "ß")=                              -- 12
/*
    "straßssßßssse"~text~unicode~c2g=
         1  2  3  4  5     6  7  8     9     0  1  2  3                         -- (external character indexes)
         s  t  r  a  ß     s  s  ß     ß     s  s  s  e
         73 74 72 61 DF    73 73 DF    DF    73 73 73 65                        -- (unicode scalars)
    "straßssßßssse"~text~casefold~unicode~c2g=
         1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6                         -- (internal byte indexes)
         s  t  r  a  s  s  s  s  s  s  s  s  s  s  s  e
         73 74 72 61 73 73 73 73 73 73 73 73 73 73 73 65                        -- (unicode scalars)
    ----------------------------------------------------
    "straßßßßßßßßß"~text~unicode~c2g=
         1  2  3  4  5     6     7     8     9     0     1     2     3          -- (external character indexes)
         s  t  r  a  ß     ß     ß     ß     ß     ß     ß     ß     ß
         73 74 72 61 DF    DF    DF    DF    DF    DF    DF    DF    DF         -- (unicode scalars)
    "straßßßßßßßßß"~text~casefold~unicode~c2g=
         1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2       -- (internal byte indexes)
         s  t  r  a  ß     ß     ß     ß     ß     ß     ß     ß     ß
         73 74 72 61 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73      -- (unicode scalars)
                                                   |  |
                                                   |  +-- 65 at (13,16) <> 73 at (-10,+16) but can't be 13 because would match only the first 73 of ß at (10,15)
                                                   +-- yes, 12.
*/

/*
Debug output: the indexer supports the named parameter debug
"straßssßßssse"~text~indexer~caselessCompare("stra", "ß", debug:.true)=
    selfTextTransformer~iSubtext~string = strassssssssssse
    selfTextTransformer~iSubtext~c2g = 73 74 72 61 73 73 73 73 73 73 73 73 73 73 73 65
    selfTextTransformedString~length = 16
    textTextTransformer~iSubtext~string = strassssssssssssssssss
    textTextTransformer~iSubtext~c2g = 73 74 72 61 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73
    textTextTransformedString~length = 22
    posB1 = 16
    posC1 = +13.16
    posB2 = 16
    posC2 = -10.16
     12
*/

-- Another way to test: at which moment the growing padded string on the right will no longer be found at pos 1
--   1234567890123
    "straßssßßssse"~text~caselessPos("straß")=          -- 1
--   straß
    "straßssßßssse"~text~caselessPos("straßß")=         -- 1
--   straßß
    "straßssßßssse"~text~caselessPos("straßßß")=        -- 1
--   straßß ß
    "straßssßßssse"~text~caselessPos("straßßßß")=       -- 1
--   straßß ßß
    "straßssßßssse"~text~caselessPos("straßßßßß")=      -- 1
--   straßß ßßß
    "straßssßßssse"~text~caselessPos("straßßßßßß")=     -- 0    The last ß doesn't match "se" at 12
--   straßß ßßß ß


/*
---------------------------------------------
CASE 3 : not aligned in self, aligned in arg1
---------------------------------------------
*/

"stra"~text~caselessCompare("straßssßßssse", "ß")=  -- 9
/*
    1  2  3  4  5     6     7     8     9     0     1     2     3               -- (external character indexes)
    s  t  r  a  ß     ß     ß     ß     ß     ß     ß     ß     ß
    1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2            -- (internal byte indexes)
    73 74 72 61 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73           -- (unicode scalars of the casefolded string)
    -----------------------------------------------------------------
    1  2  3  4  5     6  7  8     9     0  1  2  3                              -- (external character indexes)
    s  t  r  a  ß     s  s  ß     ß     s  s  s  e
    1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6                              -- (internal byte indexes)
    73 74 72 61 73 73 73 73 73 73 73 73 73 73 73 65                             -- (unicode scalars of the casefolded string)
                                        |        |
                                        |        + 73 at (-10,16) <> 65 at (13,16)
                                        +-- yes, 9.
*/

/*
Debug output: the indexer supports the named parameter debug
"stra"~text~indexer~caselessCompare("straßssßßssse", "ß", debug:.true)=
    selfTextTransformer~iSubtext~string = strassssssssssssssssss
    selfTextTransformer~iSubtext~c2g = 73 74 72 61 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73 73
    selfTextTransformedString~length = 22
    textTextTransformer~iSubtext~string = strassssssssssse
    textTextTransformer~iSubtext~c2g = 73 74 72 61 73 73 73 73 73 73 73 73 73 73 73 65
    textTextTransformedString~length = 16
    posB1 = 16
    posC1 = -10.16
    posB2 = 16
    posC2 = +13.16
     9
*/

"straß"        ~text~caselessCompare("straßssßßssse", "ß")=  -- 9
"straßß"       ~text~caselessCompare("straßssßßssse", "ß")=  -- 9
"straßßß"      ~text~caselessCompare("straßssßßssse", "ß")=  -- 9
"straßßßß"     ~text~caselessCompare("straßssßßssse", "ß")=  -- 9
"straßßßßß"    ~text~caselessCompare("straßssßßssse", "ß")=  -- 9
"straßßßßßß"   ~text~caselessCompare("straßssßßssse", "ß")=  -- 9
"straßßßßßßß"  ~text~caselessCompare("straßssßßssse", "ß")=  -- 9
"straßßßßßßßß" ~text~caselessCompare("straßssßßssse", "ß")=  -- 9

"straß"        ~text~caselessCompareTo("straßssßßssse")=  -- -1
"straßß"       ~text~caselessCompareTo("straßssßßssse")=  -- -1
"straßßß"      ~text~caselessCompareTo("straßssßßssse")=  -- -1
"straßßßß"     ~text~caselessCompareTo("straßssßßssse")=  -- -1
"straßßßßß"    ~text~caselessCompareTo("straßssßßssse")=  -- -1     up to 9 characters, it's lesser
"straßßßßßß"   ~text~caselessCompareTo("straßssßßssse")=  -- 1      from 10 characters, it's greater
"straßßßßßßß"  ~text~caselessCompareTo("straßssßßssse")=  -- 1
"straßßßßßßßß" ~text~caselessCompareTo("straßssßßssse")=  -- 1

"stra"     ~caselessCompare("strasssssse", "s")=    -- 11
"stra"~text~caselessCompare("strasssssse", "s")=    -- 11
"strasssssse"     ~caselessCompare("stra", "s")=    -- 11
"strasssssse"~text~caselessCompare("stra", "s")=    -- 11

"strà"     ~caselessCompare("stràsssssse", "s")=    -- 11 (was 12 before automatic conversion of string literals to text)
"strà"~text~caselessCompare("stràsssssse", "s")=    -- 11
"stràsssssse"     ~caselessCompare("strà", "s")=    -- 11 (was 12 before automatic conversion of string literals to text)
"stràsssssse"~text~caselessCompare("strà", "s")=    -- 11


/*
---------------------------------------------
CASE 4 : not aligned in self, aligned in arg1
---------------------------------------------
*/

iota_dt = "\u{GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS}"~text~unescape
("a" iota_dt~casefold "b")~compare("a" iota_dt, normalization: 0)=  -- 3

/*
Debug output: the indexer supports the named parameter debug
("a" iota_dt~casefold "b")~indexer~compare("a" iota_dt, normalization: 0, debug:.true)=
    selfTextTransformer~iSubtext~string = a ΐ b
    selfTextTransformer~iSubtext~c2g = 61 20 CEB9CC88CC81 20 62
    selfTextTransformedString~length = 10
    textTextTransformer~iSubtext~string = a ΐ
    textTextTransformer~iSubtext~c2g = 61 20 CE90 20 20
    textTextTransformedString~length = 6
    posB1 = 4
    posC1 = -3.4
    posB2 = 4
    posC2 = -3.4
     3
*/


-- ===============================================================================
-- 2023 Oct 04

/*
Reactivate the constraint "self~isCompatibleWithByteString" when converting a
RexxText to a String. It can be disabled by setting
    .Unicode~unckeckedConversionToString = .true
Currently, the only case where this constraint is disabled is when testing
the regular expressions in diary_examples.rex.


Some checks of encoding compatibiliy were missing.
Added in:
- compareText: caselessCompare, compare
- compareToText: caselessCompareTo, compareTo
- endsWithText: caselessEndsWith, endsWith
- matchCharText: caselessMatchChar, matchChar
- matchText: caselessMatch, match
- posText: caselessPos, pos


New supported methods:
- abs       forward to String, return a String
- b2x       forward to String, return a String
- bitAnd    forward to String, return a String
- bitOr     forward to String, return a String
- bitXor    forward to String, return a String
Examples:
*/
    (-1)~text~abs=          -- 1
    ("-x")~text~abs=        -- ABS method target must be a number; found "-x".
    ("-é")~text~abs=        -- UTF-8 not-ASCII '-é' is not compatible with a Rexx numeric value.

    100~text~b2x=           -- 4
    "x"~text~b2x=           -- Only 0, 1, and whitespace characters are valid in a binary string; character found "x".
    "é"~text~b2x=           -- UTF-8 not-ASCII 'é' is not compatible with a Rexx numeric value.

    "12"x~text~bitAnd=                                  -- '[12]'   ("12"x)
    "73"x~text~bitAnd("27"x~text)=                      -- '#'      ("23"x)
    "13"x~text~bitAnd("5555"x~text)=                    -- '[11]U'  ("1155"x)
    "13"x~text~bitAnd("5555"x~text,"74"x~text)=         -- '[11]T'  ("1154"x)
    "pQrS"~text~bitAnd(,"DF"x~text("byte"))=            -- "PQRS"

    "12"x~text~bitOr=                                   -- '[12]'       ("12"x)
    "15"x~text~bitOr("24"x~text)=                       -- 5            ("35"x)
    "15"x~text~bitOr("2456"x~text)=                     -- '5V'         ("3556"x)
    "15"x~text~bitOr("2456"x~text,"F0"x~text("byte"))=  -- '5?'         ("35F6"x)
    "1111"x~text~bitOr(,"4D"x~text)=                    -- ']]'         ("5D5D"x)
    "pQrS"~text~bitOr(,"20"x~text)=                     -- "pqrs"

    "12"x~text~bitXor=                                  -- '[12]'       ("12"x)
    "12"x~text~bitXor("22"x~text)=                      -- 0            ("30"x)
    "1211"x~text~bitXor("22"x~text)=                    -- '0[11]'      ("3011"x)
    "1111"x~text~bitXor("444444"x~text)=                -- 'UUD'        ("555544"x)
    "1111"x~text~bitXor("444444"x~text,"40"x~text)=     -- 'UU[04]'     ("555504"x)
    "1111"x~text~bitXor(,"4D"x~text)=                   -- '\\'         ("5C5C"x)
    "C711"x~text~bitXor("222222"x~text," "~text)=       -- '?3[02]'     ("E53302"x)


/*
Implementation of caselessStartsWith, startsWith:
(forwards to caselessPos or pos, and returns .true if result == 1)
(was already implemented, waiting for 'pos' implementation)
Examples:
*/
    "Père"~text~c2g=                                -- '50 C3A8 72 65'
    "Père"~text~startsWith("50"x)=                  -- true
    "Père"~text~startsWith("50C3"x)=                -- was Invalid UTF-8 string     (utf8proc error because "50C3"x is an invalid UTF-8 encoding)
    "Père"~text~startsWith("50C3"x~text("byte"))=   -- false (not aligned)    (was Encoding: cannot compare Byte not-ASCII 'P?' with UTF-8 not-ASCII 'Père')
    "Père"~text~startsWith("50C3A8"x)=              -- true

    "éßﬄ"~text~c2g=                                 -- 'C3A9 C39F EFAC84'
    "éßﬄ"~text~casefold~c2g=                        -- 'C3A9 73 73 66 66 6C'
    "éßﬄ"~text~caselessStartsWith("É")=             -- true
    "éßﬄ"~text~caselessStartsWith("És")=            -- false
    "éßﬄ"~text~caselessStartsWith("Éss")=           -- true
    "éßﬄ"~text~caselessStartsWith("Éssf")=          -- false
    "éßﬄ"~text~caselessStartsWith("Éssff")=         -- false
    "éßﬄ"~text~caselessStartsWith("Éssffl")=        -- true

    "noël👩‍👨‍👩‍👧🎅"~text~startsWith("noël👩")=                       -- false
    "noël👩‍👨‍👩‍👧🎅"~text~startsWith("noël👩", aligned:.false)=       -- true
    "noël👩‍👨‍👩‍👧🎅"~text~startsWith("noël👩‍👨‍👩‍")=                  -- false
    "noël👩‍👨‍👩‍👧🎅"~text~startsWith("noël👩‍👨‍👩‍", aligned:.false)=  -- true
    "noël👩‍👨‍👩‍👧🎅"~text~startsWith("noël👩‍👨‍👩‍👧")=                 -- true


-- ===============================================================================
-- 2023 Oct 03

/*
Move the routine createCharacterTranscodingTable from byte_common.cls to
byte_encoding.cls. It's used only by Byte_Encoding and its subclasses.


The 'text' method of UnicodeCharacter has been replaced by 'transcodeTo'.
Reason 1: the byte encodings were not supported correctly.
Reason 2: the fact a transcoding is needed is against the definition of the
'text' method (apply a view on the bytes without modifying them).


Finalize the support of replacement character during transcoding.
A replacement character can be .nil or "" or a character.
When a character, it can be a String or a RexxText made of one codepoint or a UnicodeCharacter.
In all cases, the corresponding codepoint is used. This codepoint is transcoded to the target encoding.

Behavior when a source codepoint does not have a matching target codepoint:
- When the replacement character is .nil, an error is raised.
- When the replacement character is "", the source codepoint is ignored (not transcoded)
- Otherwise the source codepoint is replaced by the replacement character.

Reminder: if the 'strict' named argument is false (default) then the fallback
codepoint transcodings are used, if any. So when 'strict' is false, potentially
more source could be transcoded.

Examples:
*/
    -- The Windows-1252 encoding has some fallback codepoint transcodings.
    -- HOP is one of them: 81x --> +U0081 only when strict:.false
    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~utf8(strict:.false)=   -- T'Noël (strict:.false is the default)
    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~utf8(strict:.false)~unicodecharacters==
    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~utf8(strict:.true)=    -- Cannot convert windows-1252 not-ASCII character 129 (81) at byte-position 5 to UTF-8.
    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~utf8(strict:.true, replacementCharacter:"")=       -- T'Noël'
    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~utf8(strict:.true, replacementCharacter:"#")=      -- T'Noël#'
    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~utf8(strict:.true, replacementCharacter:"🎅")=     -- T'Noël🎅'

    "Noël\u{HOP}"~text("utf8")~unescape~transcodeTo("byte")=                    -- Cannot convert UTF-8 not-ASCII codepoint 235 (EB) at position 3 to Byte.
    "Noël\u{HOP}"~text("utf8")~unescape~transcodeTo("windows-1252")=            -- T'No?l?'
    "Noël\u{HOP}"~text("utf8")~unescape~transcodeTo("windows-1252")~c2x=        -- '4E 6F EB 6C 81'
    "Noël\u{HOP}"~text("utf8")~unescape~transcodeTo("windows-1252", strict:)=   -- Cannot convert UTF-8 not-ASCII codepoint 129 (81) at position 5 to windows-1252.

    -- "byte" encoding: only 00..7F can be transcoded
    ("No" || "EB"x || "l" || "81"x)~text("byte")~utf8=                                                      -- Cannot convert Byte not-ASCII character 235 (EB) at byte-position 3 to UTF-8.
    ("No" || "EB"x || "l" || "81"x)~text("byte")~utf8(replacementCharacter:"")=                             -- T'Nol'
    ("No" || "EB"x || "l" || "81"x)~text("byte")~utf8(replacementCharacter:"#")=                            -- T'No#l#'      1 replacement character for ë because "ë" is 'EB'x
    ("No" || "EB"x || "l" || "81"x)~text("byte")~utf8(replacementCharacter:"🎅")=                           -- T'No🎅l🎅'
    ("No" || "EB"x || "l" || "81"x)~text("byte")~utf8(replacementCharacter:"🎅"~text)=                      -- T'No🎅l🎅'
    ("No" || "EB"x || "l" || "81"x)~text("byte")~utf8(replacementCharacter:.unicode["Father Christmas"])=   -- T'No🎅l🎅'

    "Noël"~text("byte")~utf8(replacementCharacter:"")=                          -- T'Nol'
    "Noël"~text("byte")~utf8(replacementCharacter:"#")=                         -- T'No##l'         2 replacement characters for ë because "ë" is 'C3 AB'x
    "Noël"~text("byte")~utf8(replacementCharacter:"🎅")=                        -- T'No🎅🎅l'
    "Noël"~text("byte")~utf8(replacementCharacter:"🎅🎅")=                     -- The transcoded replacement character must have at most one codepoint, got UTF-8 not-ASCII (2 characters, 2 codepoints, 8 bytes, 0 error) '🎅🎅'.
    "Noël"~text("byte")~utf8(replacementCharacter:"🎅🎅"~text)=                -- The transcoded replacement character must have at most one codepoint, got UTF-8 not-ASCII (2 characters, 2 codepoints, 8 bytes, 0 error) '🎅🎅'.

    "Noël"~text("utf8")~transcodeTo("byte")=                                    -- Cannot convert UTF-8 not-ASCII codepoint 235 (EB) at position 3 to Byte.
    "Noël"~text("utf8")~transcodeTo("byte", replacementCharacter:"")=           -- T'Nol'
    "Noël"~text("utf8")~transcodeTo("byte", replacementCharacter:"#")=          -- T'No#l'
    "Noël"~text("utf8")~transcodeTo("byte", replacementCharacter:"🎅")=         -- The replacement character UTF-8 not-ASCII '🎅' cannot be transcoded to Byte.

    "Noël🤶"~text("utf8")~transcodeTo("unicode", replacementCharacter:"🎅")=        -- T'N[000000]o[000000]?[000000]l[000000]??[0100]'
    "Noël🤶"~text("utf8")~transcodeTo("unicode", replacementCharacter:"🎅")~c2x=    -- '4E000000 6F000000 EB000000 6C000000 36F90100'
    "Noël🤶"~text("utf8")~transcodeTo("unicode", replacementCharacter:"🎅")~c2u=    -- 'U+004E U+006F U+00EB U+006C U+1F936'

    "Noël🤶"~text("utf8")~transcodeTo("unicode8", replacementCharacter:"")=          -- T'No?l'
    "Noël🤶"~text("utf8")~transcodeTo("unicode8", replacementCharacter:"")~c2x=      -- '4E 6F EB 6C'
    "Noël🤶"~text("utf8")~transcodeTo("unicode8", replacementCharacter:"#")=         -- T'No?l#'
    "Noël🤶"~text("utf8")~transcodeTo("unicode8", replacementCharacter:"#")~c2x=     -- '4E 6F EB 6C 23'
    "Noël🤶"~text("utf8")~transcodeTo("unicode8", replacementCharacter:"🎅")=       -- The replacement character UTF-8 not-ASCII '🎅' cannot be transcoded to Unicode8.

    "Noël🤶"~text("utf8")~transcodeTo("unicode16", replacementCharacter:"")=         -- T'N[00]o[00]?[00]l[00]'
    "Noël🤶"~text("utf8")~transcodeTo("unicode16", replacementCharacter:"#")=        -- T'N[00]o[00]?[00]l[00]#[00]'
    "Noël🤶"~text("utf8")~transcodeTo("unicode16", replacementCharacter:"#")~c2x=    -- '4E00 6F00 EB00 6C00 2300'
    "Noël🤶"~text("utf8")~transcodeTo("unicode16", replacementCharacter:"#")~c2u=    -- 'U+004E U+006F U+00EB U+006C U+0023'
    "Noël🤶"~text("utf8")~transcodeTo("unicode16", replacementCharacter:"🎅")=      -- The replacement character UTF-8 not-ASCII '🎅' cannot be transcoded to Unicode16.

    "Noël🤶"~text("utf8")~transcodeTo("unicode32")=         -- T'N[000000]o[000000]?[000000]l[000000]6?[0100]'
    "Noël🤶"~text("utf8")~transcodeTo("unicode32")~c2x=     -- '4E000000 6F000000 EB000000 6C000000 36F90100'
    "Noël🤶"~text("utf8")~transcodeTo("unicode32")~c2u=     -- 'U+004E U+006F U+00EB U+006C U+1F936'


/*
The method c2u is no longer abstract for the byte encodings.
Now, a byte encoding is converted on the fly to UnicodeN in non strict mode,
replacing any unsupported character by .Unicode~replacementCharacter.
Idem for the method unicodeCharacters.
Examples:
*/
    "FF FE FD FC"x~text("byte")~c2x=                                               -- 'FF FE FD FC'
    "FF FE FD FC"x~text("byte")~c2g=                                               -- 'FF FE FD FC'
    "FF FE FD FC"x~text("byte")~codepoints==
    "FF FE FD FC"x~text("byte")~c2u=                                               -- 'U+FFFD U+FFFD U+FFFD U+FFFD'
    "FF FE FD FC"x~text("byte")~unicodeCharacters==

    "FF FE FD FC"x~text("utf8")~c2x=                                               -- 'FF FE FD FC'
    "FF FE FD FC"x~text("utf8")~c2g=                                               -- 'FF FE FD FC'
    "FF FE FD FC"x~text("utf8")~c2u=                                               -- 'U+FFFD U+FFFD U+FFFD U+FFFD'
    "FF FE FD FC"x~text("utf8")~codepoints==

    "FF FE FD FC"x~text("unicode8")~c2x=                                           -- 'FF FE FD FC'
    "FF FE FD FC"x~text("unicode8")~c2g=                                           -- 'FF FE FD FC'
    "FF FE FD FC"x~text("unicode8")~codepoints==
    "FF FE FD FC"x~text("unicode8")~c2u=                                           -- 'U+00FF U+00FE U+00FD U+00FC'
    "FF FE FD FC"x~text("unicode8")~unicodecharacters==

    ("No" || "EB"x || "l" || "81"x)~text("byte")~c2x=                           -- '4E 6F EB 6C 81'
    ("No" || "EB"x || "l" || "81"x)~text("byte")~c2g=                           -- '4E 6F EB 6C 81'
    ("No" || "EB"x || "l" || "81"x)~text("byte")~c2u=                           -- 'U+004E U+006F U+FFFD U+006C U+FFFD'
    ("No" || "EB"x || "l" || "81"x)~text("byte")~unicodecharacters==

    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~c2x=                   -- '4E 6F EB 6C 81'
    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~c2g=                   -- '4E 6F EB 6C 81'
    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~c2u=                   -- 'U+004E U+006F U+00EB U+006C U+0081'
    ("No" || "EB"x || "l" || "81"x)~text("windows-1252")~unicodecharacters==


-- ===============================================================================
-- 2023 Sep 27

/*
Add the named parameters 'stripCC' and 'stripNA' to all the methods supporting
the named parameter 'normalization'. This is utf8proc specific.
- stripCC: remove control characters (see utf8proc doc for more information:
  HorizontalTab (HT) and FormFeed (FF) are transformed into space)
- stripNA: remove unassigned codepoints
Example:
*/
.unicode["ESA"]=        -- ( ""    U+0087 Cc 0 "", "END OF SELECTED AREA", "ESA"
.unicode["NBSP"]=       -- ( " "   U+00A0 Zs 1 "NO-BREAK SPACE", "NBSP" )
.unicode["SSA"]=        -- ( ""    U+0086 Cc 0 "", "START OF SELECTED AREA", "SSA"
.unicode["U+0378"]=     -- ( "͸"   U+0378 Cn 1 "" )     unassigned

"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape=                                         -- T'Mrs. 🤶 a͸nd Mr. 🎅
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~c2g=                                     -- 'C286 4D 72 73 2E C2A0 F09FA4B6 20 61 CDB8 6E 64 20 4D 72 2E C2A0 F09F8E85 C287'
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~transform(stripNA:)~c2g=                 -- 'C286 4D 72 73 2E C2A0 F09FA4B6 20 61      6E 64 20 4D 72 2E C2A0 F09F8E85 C287'
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~transform(stripNA:, stripCC:)~c2g=       -- '     4D 72 73 2E C2A0 F09FA4B6 20 61      6E 64 20 4D 72 2E C2A0 F09F8E85     '

"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~pos("and")=                              -- 0
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~pos("and", stripNA:)=                    -- 9
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~pos("and", stripNA:, stripCC:)=          -- 9    yes! 9, not 8 because it's the EXTERNAL position

"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~caselessPos("mr.")=                      -- 14
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~caselessPos("mr.", stripNA:)=            -- 14   yes! 14, not 13
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~caselessPos("mr.", stripNA:, stripCC:)=  -- 14   yes! 14, not 12

"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~caselessPos("\U{SSA}"~text~unescape)=              -- 1
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~caselessPos("\U{SSA}"~text~unescape, stripCC:)=    -- 0

"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~caselessPos("a\u0378nd"~text~unescape)=                        -- 9
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~caselessPos("a\u0378nd"~text~unescape, stripCC:)=              -- 9
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~caselessPos("a\u0378nd"~text~unescape, stripNA:)=              -- 9    yes! 9, not 0 because \u0378 is removed both in the needle and in thehaystack
"\U{SSA}Mrs.\U{NBSP}🤶 a\u0378nd Mr.\U{NBSP}🎅\U{ESA}"~text~unescape~caselessPos("a\u0378nd"~text~unescape, stripNA:, stripCC:)=    -- 9    yes! 9, not 8


/*
caselessEndsWith, endsWith: returns false if the start of the 'other' string is
not aligned with a character.
Examples
*/
"#éßﬄ#…"~text~endsWith("…")=                      -- true
"#éßﬄ#…"~text~caselessEndsWith("…")=              -- true

"#éßﬄ#…"~text~endsWith("fl#…")=                   -- false, ﬄ remains ﬄ
"#éßﬄ#…"~text~caselessEndsWith("FL#…")=           -- false, ﬄ becomes ffl but FL is not aligned with ffl

"#éßﬄ#…"~text~endsWith("ﬄ#…")=                   -- true
"#éßﬄ#…"~text~caselessEndsWith("ﬄ#…")=           -- true

"#éßﬄ#…"~text~endsWith("ffl#…")=                  -- false, ﬄ remains ﬄ
"#éßﬄ#…"~text~caselessEndsWith("FFL#…")=          -- true,  ﬄ becomes ffl and FFL is aligned with ffl

"#éßﬄ#…"~text~endsWith("sﬄ#…")=                  -- false, ß remains ß
"#éßﬄ#…"~text~caselessEndsWith("Sﬄ#…")=          -- false, ß becomes ss but s is not aligned with ss

"#éßﬄ#…"~text~endsWith("ßﬄ#…")=                  -- true
"#éßﬄ#…"~text~caselessEndsWith("ßﬄ#…")=          -- true

"#éßﬄ#…"~text~endsWith("ssﬄ#…")=                 -- false, ß remains ß
"#éßﬄ#…"~text~caselessEndsWith("SSﬄ#…")=         -- true,  ß becomes ss

"#éßﬄ#…"~text~endsWith("éßﬄ#…")=                 -- true
"#éßﬄ#…"~text~caselessEndsWith("ÉSSFFL#…")=       -- true

"#éßﬄ#…"~text~endsWith("#éßﬄ#…")=                -- true
"#éßﬄ#…"~text~caselessEndsWith("#ÉSSFFL#…")=      -- true

"#e\U{COMBINING ACUTE ACCENT}ßﬄ#…"~text~unescape~c2g=                                                                   -- '23 65CC81 C39F EFAC84 23 E280A6'
  "\U{COMBINING ACUTE ACCENT}ßﬄ#…"~text~unescape~c2g=                                                                   -- '     CC81 C39F EFAC84 23 E280A6'
"#e\U{COMBINING ACUTE ACCENT}ßﬄ#…"~text~unescape~endsWith("\U{COMBINING ACUTE ACCENT}ßﬄ#…"~text~unescape)=             -- false, not aligned with e\U{COMBINING ACUTE ACCENT}

"#e\U{COMBINING ACUTE ACCENT}ßﬄ#…"~text~unescape~casefold~c2g=                                                          -- '23 65CC81 73 73 66 66 6C 23 E280A6'
  "\U{COMBINING ACUTE ACCENT}SSFFL#…"~text~unescape~casefold~c2g=                                                        -- '     CC81 73 73 66 66 6C 23 E280A6'
"#e\U{COMBINING ACUTE ACCENT}ßﬄ#…"~text~unescape~caselessEndsWith("\U{COMBINING ACUTE ACCENT}SSFFL#…"~text~unescape)=   -- false, not aligned with e\U{COMBINING ACUTE ACCENT}


/*
New 'RexxTextTransformer' class:
    - Converts positions in a transformed string to positions in the corresponding
      untransformed string. This is used for the caselessXXX methods which takes
      or return positions.
    - Supports inflating and deflating transformations.
      jlf 2023 Sep 28: better names are expansion and contraction.
    - The transformation can be made on a part of the string (from startC, for
      lengthC characters).
    - The methods for the transformation are the same as for RexxText:
      NFC, NFD, NFKC, NFKD, casefold, transform. The result is the instance of
      RexxTextTransformer, not the transformed text.
    - Only one call to a transformation method can be done. This is because the
      parameters of the transformation are memorized to re-apply internally the
      transformation character by character, when moving the cursors.
    - The 'transformer' method lets create an instance of RexxTextTransformer
      from a text.

    Example:
        - full text        = original text (untransformed)
        - external subtext = part of the full text to transform
        - internal subtext = transformed part of the full text

        The method ib2xc converts an internal byte (ib) position in the internal
        subtext (iSubtext) to an external character (xc) position in the external
        full text.
        ib2xc supports only growing positions. The only way to go backward is to
        use backupPos/restorePos or resetPos.

                                     --                          Transformed part of the full text
                                     --                       +-------------------------------------+               -- GLOBAL INDEXES (offsetC=3, offsetB=7)
                                     --  01   | 02   | 03     | 04 | 05     | 06    | 07       | 08 | 09            -- (external character indexes) <--------+
                                     --  1 2  | 3 4  | 5 6 7  | 8  | 9 0    | 1 2   | 3 4 5    | 6  | 7 8 9         -- (external byte indexes)               |
            "éßﬄ#éßﬄ#…"~text~c2g   --  C3A9 | C39F | EFAC84 | 23 | C3A9   | C39F  | EFAC84   | 23 | E280A6        -- (external bytes)                      |
                                     --  é    | ß    | ﬄ     | #  | é      | ß     | ﬄ       | #  | …             -- (full text)                           ^
                                     --  1 2  | 3 4  | 5 6 7  | 8  | 9 0 1  | 2  3  | 4  5  6  | 7  | 8 9 0         -- (internal byte indexes, offset=7)     |
                                     --  C3A9 | C39F | EFAC84 | 23 | 65CC81 | 73 73 | 66 66 6C | 23 | E280A6        -- (internal bytes)                      |
                                                              +-------------------------------------+                                                        |
                                                                                                                    -- RELATIVE INDEXES                      |
                                                            --  01 | 02     | 03    | 04       | 05                 -- (external character indexes) <--------+
                                                            --  1  | 2 3    | 4 5   | 6 7 8    | 9                  -- (external byte indexes)               |
            "#éßﬄ#"~text~c2g=                              --  23 | C3A9   | C39F  | EFAC84   | 23                 -- (external bytes)                      |
                                                            --  #  | é      | ß     | ﬄ       | #                  -- (external subtext)                    ^
                                                                                                                                                             |
                                                                                                                    -- RELATIVE INDEXES                      |
                                                            --  01 | 02     | 03 04 | 05 06 07 | 08                 -- (internal character indexes)          |
                                                            --  1  | 2 3 4  | 5  6  | 7  8  9  | 0                  -- (internal byte indexes) ------>-------+
            "#éßﬄ#"~text~NFD(casefold:)~c2g=               --  23 | 65CC81 | 73 73 | 66 66 6C | 23                 -- (internal bytes)
                                                            --  #  | é      | s  s  | f  f  l  | #                  -- (internal subtext)
*/
transformer = "éßﬄ#éßﬄ#…"~text~transformer(4, 5)~NFD(casefold:)
transformer~fulltext=       -- T'éßﬄ#éßﬄ#…'
transformer~xSubtext=       -- T'#éßﬄ#'
transformer~iSubtext=       -- T'#éssffl#'

-- ib2xc supports only growing positions
transformer~ib2xc(1)=       -- 4    the internal byte position 1 in the internal subtext corresponds to the 4th external character in the full text
transformer~ib2xc(7)=       -- 7
transformer~ib2xc(2)=       -- Error RexxTextTransformer: You specified a byte position (2) lower than the previous one (7).

-- The previous error is avoided by backuping/restoring the current position
transformer~resetPos        -- reset to allow iteration again from internal byte position 1
transformer~ib2xc(1)=       -- 4
transformer~backupPos
transformer~ib2xc(7)=       -- 7
transformer~restorePos
transformer~ib2xc(2)=       -- 5

transformer~resetPos
do i=1 to transformer~iSubtext~string~length; say "byte pos" i~right(2) "    character pos=" transformer~ib2xc(i)~string~left(20) transformer~ib2xc(i, aligned:.false); end
/*
    byte pos  1     character pos= 4                    +4.8    -- the 8th internal byte is aligned with the 4th external character
    byte pos  2     character pos= 5                    +5.9
    byte pos  3     character pos= The NIL object       -5.10   -- the 10th internal byte is part of the 5th external character, but is not aligned with it.
    byte pos  4     character pos= The NIL object       -5.11
    byte pos  5     character pos= 6                    +6.12
    byte pos  6     character pos= The NIL object       -6.13
    byte pos  7     character pos= 7                    +7.14
    byte pos  8     character pos= The NIL object       -7.15
    byte pos  9     character pos= The NIL object       -7.16
    byte pos 10     character pos= 8                    +8.17
*/
/*
    More details on positions mappings.
    transformer~iSubtext is the transformed part of the full text.
    The internal relative byte position 1 becomes the internal global byte position 8:
        There are 7 bytes (offsetB=7) before the part to transform: 1 + 7 = 8.
        It's the same offsetB=7 for external and internal bytes, because this part is not transformed.
        Remember:
        It doesn't make sense to return the external byte position, because some internal byte positions
        have no corresponding external byte position. For example the internal global byte position 11.
        For diagnostics and analysis, only internal byte positions are relevant.
    The external relative character position 1 becomes the external global character position 4:
        There are 3 characters (offsetC=3) before the part to transform: 1 + 3 = 4.
        It's the same offsetC=3 for external and internal characters, because this part is not transformed.
        Remember:
        The user works only with external global character positions.
        It wouldn't make sense to return internal character positions.
    Example of alignment:
        The internal relative byte position 1 becomes the internal global byte position 8,
        is part of the 4th external character and is aligned with it.
    Example of non-alignment:
        The internal relative byte position 3 becomes the internal global byte position 10,
        is part of the 5th external character and is not aligned with it.
*/


-- ===============================================================================
-- 2023 Sep 16

/*
Relax the constraint "self~isCompatibleWithByteString" when converting a RexxText
to a String.
That allows to go further in the tests of regular expression.
*/
unckeckedConversionToString = .Unicode~unckeckedConversionToString -- backup
.Unicode~unckeckedConversionToString = .true


-- bug in regex.cls
p = .Pattern~compile("(.)*foo")
p~matches("xfooxxxxxxfooXXXX")=         -- Invalid position argument specified; found "0".


-- False success in text mode
-- "à" is 2 bytes 'C3A0', "🎅" is 4 bytes 'F09F8E85'
-- When compiling a String then each of the bytes of "à" or "🎅" become candidate for matching
-- When compiling a RexxText then only the sequence of all the bytes of "à" or "🎅" should match... But that's not the case.
pB = .Pattern~compile("[àb🎅]")
pT = .Pattern~compile("[àb🎅]"~text)
pB~startsWith('àXXXX')=                             -- 1
pT~startsWith('àXXXX'~text)=                        -- 1 but matched only C3
pB~startsWith('bXXXX')=                             -- 1
pT~startsWith('bXXXX'~text)=                        -- 1
pB~startsWith('🎅XXXX')=                            -- 1
pT~startsWith('🎅XXXX'~text)=                       -- 1
pB~startsWith('F0'x || 'XXXX')=                     -- Invalid UTF-8 string (raised by utf8proc) (was 1 before automatic conversion of string literals to text)
pT~startsWith('F0'x || 'XXXX'~text)=                -- Invalid UTF-8 string (raised by utf8proc)
pT~startsWith('F0'x || 'XXXX')=                     -- Invalid UTF-8 string (raised by utf8proc) (was 1 (not good) before automatic conversion of string literals to text)
pB~startsWith('9F'x || 'XXXX')=                     -- Invalid UTF-8 string (raised by utf8proc) (was 1 before automatic conversion of string literals to text)
pT~startsWith('9F'x || 'XXXX'~text)=                -- Invalid UTF-8 string (raised by utf8proc)
pT~startsWith('9F'x || 'XXXX')=                     -- Invalid UTF-8 string (raised by utf8proc) (was 1 (not good) before automatic conversion of string literals to text)


-- greedy pattern
pB = .Pattern~compile("(.)*fô🎅")
pT = .Pattern~compile("(.)*fô🎅"~text)
pB~matches("xfooxxxxxxfô🎅")=                        -- 1
pT~matches("xfooxxxxxxfô🎅"~text)=                   -- 1
pB~startsWith("xfooxxxxxxfô🎅")=                     -- 1
pT~startsWith("xfooxxxxxxfô🎅"~text)=                -- 1


-- zero or one occurrences of "a"
pB = .Pattern~compile("a?")
pT = .Pattern~compile("a?"~text)
pB~matches("")=                                     -- 1
pT~matches(""~text)=                                -- 1
pB~matches("a")=                                    -- 1
pT~matches("a"~text)=                               -- 1
pB~matches("aa")=                                   -- 0
pT~matches("aa"~text)=                              -- 0


-- zero or one occurrences of "🎅"
pB = .Pattern~compile("🎅?")
pT = .Pattern~compile("🎅?"~text)
pB~matches("")=                                     -- 1 (was 0 (KO) before automatic conversion of string literals to text)
pT~matches(""~text)=                                -- 1
pB~matches("🎅")=                                   -- 1
pT~matches("🎅"~text)=                              -- 1
pB~matches("🎅🎅")=                                 -- 0
pT~matches("🎅🎅"~text)=                            -- 0


-- exactly 3 occurrences of "a"
pB = .Pattern~compile("a{3}")
pT = .Pattern~compile("a{3}"~text)
pB~matches("aa")=                                   -- 0
pT~matches("aa"~text)=                              -- 0
pB~matches("aaa")=                                  -- 1
pT~matches("aaa"~text)=                             -- 1
pB~matches("aaaa")=                                 -- 0
pT~matches("aaaa"~text)=                            -- 0


-- exactly 3 occurrences of "🎅"
pB = .Pattern~compile("🎅{3}")
pT = .Pattern~compile("🎅{3}"~text)
pB~matches("🎅🎅")=                                 -- 0
pT~matches("🎅🎅"~text)=                            -- 0
pB~matches("🎅🎅🎅")=                               -- 1 (was 0    KO before automatic conversion of string literals to text)
pT~matches("🎅🎅🎅"~text)=                          -- 1
pB~matches("🎅🎅🎅🎅")=                             -- 0
pT~matches("🎅🎅🎅🎅"~text)=                        -- 0


-- repetitive "b" in the middle
pB = .Pattern~compile("ab{2}c")
pT = .Pattern~compile("ab{2}c"~text)
pB~matches("ac")=                                   -- 0
pT~matches("ac"~text)=                              -- 0
pB~matches("abc")=                                  -- 0
pT~matches("abc"~text)=                             -- 0
pB~matches("abbc")=                                 -- 1
pT~matches("abbc"~text)=                            -- 1
pB~matches("abbbc")=                                -- 0
pT~matches("abbbc"~text)=                           -- 0


-- repetitive "🎅" in the middle
pB = .Pattern~compile("a🎅{2}c")
pT = .Pattern~compile("a🎅{2}c"~text)
pB~matches("ac")=                                   -- 0
pT~matches("ac"~text)=                              -- 0
pB~matches("a🎅c")=                                 -- 0
pT~matches("a🎅c"~text)=                            -- 0
pB~matches("a🎅🎅c")=                               -- 1 (was 0 (KO) before automatic conversion of string literals to text)
pT~matches("a🎅🎅c"~text)=                          -- 1
pB~matches("a🎅🎅🎅c")=                             -- 0
pT~matches("a🎅🎅🎅c"~text)=                        -- 0


-- "a" or "b"
pB = .Pattern~compile("a|b")
pT = .Pattern~compile("a|b"~text)
pB~matches("a")=                                    -- 1
pT~matches("a"~text)=                               -- 1
pB~matches("b")=                                    -- 1
pT~matches("b"~text)=                               -- 1
pB~matches("c")=                                    -- 0
pT~matches("c"~text)=                               -- 0
pB~startsWith("abc")=                               -- 1
pT~startsWith("abc"~text)=                          -- 1
pB~startsWith("bac")=                               -- 1
pT~startsWith("bac"~text)=                          -- 1
r = pB~find("xxxabcxxx")
r~matched=; r~start=; r~end=; r~text=; r~length=
r = pT~find("xxxabcxxx"~text)
r~matched=; r~start=; r~end=; r~text=; r~length=
r = pB~find("xxxbacxxx")
r~matched=; r~start=; r~end=; r~text=; r~length=
r = pT~find("xxxbacxxx"~text)
r~matched=; r~start=; r~end=; r~text=; r~length=


-- "🤶" or "🎅"
pB = .Pattern~compile("🤶|🎅")
pT = .Pattern~compile("🤶|🎅"~text)
pB~matches("🤶")=                                   -- 1
pT~matches("🤶"~text)=                              -- 1
pB~matches("🎅")=                                   -- 1
pT~matches("🎅"~text)=                              -- 1
pB~matches("c")=                                    -- 0
pT~matches("c"~text)=                               -- 0
pB~startsWith("🤶🎅c")=                             -- 1
pT~startsWith("🤶🎅c"~text)=                        -- 1
pB~startsWith("🎅🤶c")=                             -- 1
pT~startsWith("🎅🤶c"~text)=                        -- 1
r = pB~find("xxx🤶🎅cxxx")
r~matched=; r~start=; r~end=; r~text=; r~length=    -- now ok (r~end was 8 and r~length was 4 before automatic conversion of string literals to text)
r = pT~find("xxx🤶🎅cxxx"~text)
r~matched=; r~start=; r~end=; r~text=; r~length=
r = pB~find("xxx🎅🤶cxxx")
r~matched=; r~start=; r~end=; r~text=; r~length=    -- now ok (r~end was 8 and r~length was 4 before automatic conversion of string literals to text)
r = pT~find("xxx🎅🤶cxxx"~text)
r~matched=; r~start=; r~end=; r~text=; r~length=


.Unicode~unckeckedConversionToString = unckeckedConversionToString -- restore


-- ===============================================================================
-- 2023 Sep 14

/*
Fix implementation of caselessPos, pos for ligatures.
The results were not good for some byte indexes when using aligned:.false
*/

--------------
-- test case 1
--------------
-- pos with ligature "ﬄ" in strict mode (default)

"bâﬄé"~text~c2u=                            -- 'U+0062 U+00E2 U+FB04 U+00E9'

/*
                                             --  01 | 02   | 03     | 04     (external grapheme indexes)
                                             --  1  | 2 3  | 4 5 6  | 7 8    (external byte indexes)
"bâﬄé"~text~c2g=                            -- '62 | C3A2 | EFAC84 | C3A9'
                                             --  b  | â    | ﬄ     | é
*/

"bâﬄé"~text~pos("é")=                       -- 4
"bâﬄé"~text~pos("e")=                       -- 0
"bâﬄé"~text~pos("e", stripMark:)=           -- 4
"bâﬄé"~text~pos("f")=                       -- 0 because in strict mode, "ﬄ" remains U+FB04
"bâﬄé"~text~pos("f", asList:, overlap:, aligned:.false)=  -- a List (0 items)

--------------
-- test case 2
--------------
-- caselessPos with ligature "ﬄ" in strict mode (default)
-- (apply casefold internally but returns external indexes)
-- The ligature is decomposed by casefold.

/*
                                             --  01 | 02   | 03       | 04     (external grapheme indexes)
                                             --  1  | 2 3  | 4 5 6    | 7 8    (external byte indexes)
"bâﬄé"~text~c2g=                            -- '62 | C3A2 | EFAC84   | C3A9'
                                             --  b  | â    | ﬄ       | é

                                             --  01 | 02   | 03 04 05 | 06     (internal grapheme indexes)
                                             --  1  | 2 3  | 4  5  6  | 7 8    (internal byte indexes)
"bâﬄé"~text~casefold~c2g=                   -- '62 | C3A2 | 66 66 6C | C3A9'
                                             --  b  | â    | f  f  l  | é
*/

"bâﬄé"~text~caselessPos("É")=               -- 4
"bâﬄé"~text~caselessPos("E")=               -- 0
"bâﬄé"~text~caselessPos("E", stripMark:)=   -- 4
"bâﬄé"~text~caselessPos("F")=               -- 0 because "F" matches only a subset of "ﬄ"-->"ffl"
"bâﬄé"~text~caselessPos("FF")=              -- 0 because "FF" matches only a subset of "ﬄ"-->"ffl"
"bâﬄé"~text~caselessPos("FL")=              -- 0 because "FL" matches only a subset of "ﬄ"-->"ffl"
"bâﬄé"~text~caselessPos("FFL")=             -- 3 because "FFL" matches all of "ﬄ"-->"ffl"
"bâﬄé"~text~caselessPos("F", asList:, overlap:, aligned:.false)=
"bâﬄﬄé"~text~caselessPos("É")=              -- 5
"bâﬄﬄé"~text~caselessPos("FFL", asList:, overlap:, aligned:.false)=
"bâﬄﬄé"~text~caselessPos("F", asList:, overlap:, aligned:.false)=
"bâﬄﬄé"~text~caselessPos("FLFF")=                   -- 0
"bâﬄﬄé"~text~caselessPos("FLFF", aligned:.false)=   -- [-3.5,-4.9]
"bâﬄﬄé"~text~caselessPos("FFLFFL")=                 -- 3

--------------
-- test case 3
--------------
-- pos with ligature "ﬄ" in non-strict mode
-- (in non-strict mode, the normalization is NFKD, but returns external indexes)
-- The ligature is decomposed by NFKD

/*
                                             --  01 | 02     | 03       | 04     (external grapheme indexes)
                                             --  1  | 2 3    | 4 5 6    | 7 8    (external byte indexes)
"bâﬄé"~text~c2g=                            -- '62 | C3A2   | EFAC84   | C3A9'
                                             --  b  | â      | ﬄ       | é

                                             --  01 | 02     | 03 04 05 | 06     (internal grapheme indexes)
                                             --  1  | 2 3 4  | 5  6  7  | 8 9 0  (internal byte indexes)
"bâﬄé"~text~NFKD~c2g=                       -- '62 | 61CC82 | 66 66 6C | 65CC81'
                                             --  b  | a ^    | f  f  l  | e ´
*/

"bâﬄé"~text~pos("é", strict:.false)=                -- 4
"bâﬄé"~text~pos("e", strict:.false)=                -- 0
"bâﬄé"~text~pos("e", strict:.false, stripMark:)=    -- 4
"bâﬄé"~text~pos("f", strict:.false)=                -- 0 because "f" matches only a subset of "ﬄ"-->"ffl"
"bâﬄé"~text~pos("ff", strict:.false)=               -- 0 because "ff" matches only a subset of "ﬄ"-->"ffl"
"bâﬄé"~text~pos("ffl", strict:.false)=              -- 3 because "ffl" matches all of "ﬄ"-->"ffl"
"bâﬄé"~text~pos("f", strict:.false, asList:, overlap:, aligned:.false)=
"bâﬄﬄé"~text~pos("é", strict:.false)=               -- 5
"bâﬄﬄé"~text~pos("ffl", strict:.false, asList:, overlap:, aligned:.false)=
"bâﬄﬄé"~text~pos("f", strict:.false, asList:, overlap:, aligned:.false)=
"bâﬄﬄé"~text~pos("flff", strict:.false)=                    -- 0
"bâﬄﬄé"~text~pos("flff", strict:.false, aligned:.false)=    -- [-3.6,-4.10]
"bâﬄﬄé"~text~pos("fflffl", strict:.false)=                  -- 3

--------------
-- test case 4
--------------
-- caselessPos with ligature "ﬄ" in non-strict mode
-- (apply casefold internally but returns external indexes)
-- (in non-strict mode, the normalization is NFKD, but returns external indexes)
-- The ligature is decomposed both by casefold and by NFKD.

/*
                                             --  01 | 02     | 03       | 04     (external grapheme indexes)
                                             --  1  | 2 3    | 4 5 6    | 7 8    (external byte indexes)
"bâﬄé"~text~c2g=                            -- '62 | C3A2   | EFAC84   | C3A9'
                                             --  b  | â      | ﬄ       | é

                                             --  01 | 02     | 03 04 05 | 06     (internal grapheme indexes)
                                             --  1  | 2 3 4  | 5  6  7  | 8 9 0  (internal byte indexes)
"bâﬄé"~text~NFKD~c2g=                       -- '62 | 61CC82 | 66 66 6C | 65CC81'
                                             --  b  | a ^    | f  f  l  | e ´
*/

"bâﬄé"~text~caselessPos("É", strict:.false)=               -- 4
"bâﬄé"~text~caselessPos("E", strict:.false)=               -- 0
"bâﬄé"~text~caselessPos("E", strict:.false, stripMark:)=   -- 4
"bâﬄé"~text~caselessPos("F", strict:.false)=               -- 0 because "F" matches only a subset of "ﬄ"-->"ffl"
"bâﬄé"~text~caselessPos("FF", strict:.false)=              -- 0 because "FF" matches only a subset of "ﬄ"-->"ffl"
"bâﬄé"~text~caselessPos("FFL", strict:.false)=             -- 3 because "FFL" matches all of "ﬄ"-->"ffl"
"bâﬄé"~text~caselessPos("F", strict:.false, asList:, overlap:, aligned:.false)=
"bâﬄﬄé"~text~caselessPos("É", strict:.false)=              -- 5
"bâﬄﬄé"~text~caselessPos("FFL", strict:.false, asList:, overlap:, aligned:.false)=
"bâﬄﬄé"~text~caselessPos("F", strict:.false, asList:, overlap:, aligned:.false)=
"bâﬄﬄé"~text~caselessPos("FLFF", strict:.false)=                    -- 0
"bâﬄﬄé"~text~caselessPos("FLFF", strict:.false, aligned:.false)=    -- [-3.6,-4.10]
"bâﬄﬄé"~text~caselessPos("FFLFFL", strict:.false)=                  -- 3


-- ===============================================================================
-- 2023 Sep 11

/*
casefold now supports the option stripMark.

Rework the implementation of caselessPos, pos.
- Thanks to Raku and Chrome, I realize that a matching should be succesful only
  if all the bytes of a grapheme are matched.
- New named argument 'asList', to return a list of positions
  (similar to Raku's method .indices).
- New named argument overlap: (same as Raku)
  If the optional named argument 'overlap' is specified, the search continues
  from the position directly following the previous match, otherwise the search
  will continue after the previous match.
*/

/*
Remember:
aligned=.false is intended for analysis of matchings and [non-]regression tests.
Otherwise, I don't see any use.
When aligned:.false, a returned position has the form +/-posC.posB where posB is
the position of the matched byte in the transformed haystack, and posC is the
corresponding grapheme position in the untransformed haystack.
Don't use trunc(abs(position)) because you may need up to numeric digits 40:
    position max can be +/-(2**64-1)||"."||(2**64-1)
Use instead:
    if position~matchChar(1, "+-") then parse var position 2 posC "." posB
*/

/*
Additional test cases to cover corner cases for caselessPos, pos.
*/

--------------
-- test case 1
--------------
-- case no overlap versus overlap

/*
                                --  01   | 02   | 03   | 04   | 05   | 06
                                --  1 2  | 3 4  | 5 6  | 7 8  | 9 0  | 1 2
"àààààà"~text~c2g=              -- 'C3A0 | C3A0 | C3A0 | C3A0 | C3A0 | C3A0'
                                --  à    | à    | à    | à    | à    | à

                                --  01   | 02   | 03   | 04   | 05   | 06
                                --  1 2  | 3 4  | 5 6  | 7 8  | 9 0  | 1 2
"àààààà"~text~casefold~c2g=     -- 'C3A0 | C3A0 | C3A0 | C3A0 | C3A0 | C3A0'
                                --  à    | à    | à    | à    | à    | à
*/

"àààààà"~text~caselessPos("aa", stripMark:)=                                    -- 1
"àààààà"~text~caselessPos("aa", stripMark:, asList:)~allItems=                  -- [ 1, 3, 5]
"àààààà"~text~caselessPos("aa", stripMark:, asList:, overlap:)~allItems=        -- [ 1, 2, 3, 4, 5]
"àààààà"~text~caselessPos("aa", stripMark:, asList:, aligned:.false)=
"àààààà"~text~caselessPos("aa", stripMark:, asList:, overlap:, aligned:.false)=

--------------
-- test case 2
--------------
-- case where the end of the matching is inside the untransformed grapheme

/*
                            --  01
                            --  1 2
"ß"~text~c2g=               -- 'C39F'
                            --  ß

                            --  01 02
                            --  1  2
"ß"~text~casefold~c2g=      -- '73 73'
                            --  s  s
*/

"ß"~text~caselessPos("s")=                                  -- 0, not 1 because 1 would match only the first byte of "ß"-->"ss"
"ß"~text~caselessPos("s", asList:)=                         -- a List (0 items)
"ß"~text~caselessPos("s", asList:, overlap:)=               -- a List (0 items)
"ß"~text~caselessPos("s", asList:, aligned:.false)=
"ß"~text~caselessPos("s", asList:, overlap:, aligned:.false)=

/*
                            --  01 | 02
                            --  1  | 2 3
"sß"~text~c2g=              -- '73 | C39F'
                            --  s  | ß

                            --  01 | 02 03
                            --  1  | 2  3
"sß"~text~casefold~c2g=     -- '73 | 73 73'
                            --  s  | s  s
*/

"sß"~text~caselessPos("ss")=                                -- 2, not 1 because 1 would match only the first byte of "ß"-->"ss"
"sß"~text~caselessPos("ss", asList:)~allItems=              -- [ 2]
"sß"~text~caselessPos("ss", asList:, overlap:)~allItems=    -- [ 2]
"sß"~text~caselessPos("ss", asList:, aligned:.false)=
"sß"~text~caselessPos("ss", asList:, overlap:, aligned:.false)=

/*
                            --  01 | 02    | 03
                            --  1  | 2 3   | 4
"sßs"~text~c2g=             -- '73 | C39F  | 73'
                            --  s  | ß     | s

                            --  01 | 02 03 | 04
                            --  1  | 2  3  | 4
"sßs"~text~casefold~c2g=    -- '73 | 73 73 | 73'
                            --  s  | s  s  | s
*/

"sßs"~text~caselessPos("s", 2)=                             -- 3, not 2 because 2 would match only the first byte of "ß"-->"ss"
"sßs"~text~caselessPos("s", 2, asList:)~allItems=           -- [ 3]
"sßs"~text~caselessPos("s", 2, asList:, overlap:)~allItems= -- [ 3]
"sßs"~text~caselessPos("s", 2, asList:, aligned:.false)=
"sßs"~text~caselessPos("s", 2, asList:, overlap:, aligned:.false)=

"sßs"~text~caselessPos("ss")=                               -- 2, not 1 because 1 would match only the first byte of "ß"-->"ss"
"sßs"~text~caselessPos("ss", asList:)~allItems=             -- [ 2]
"sßs"~text~caselessPos("ss", asList:, overlap:)~allItems=   -- [ 2]
"sßs"~text~caselessPos("ss", asList:, aligned:.false)=
"sßs"~text~caselessPos("ss", asList:, overlap:, aligned:.false)=

--------------
-- test case 3
--------------
-- caselessPos (apply casefold internally but returns external indexes)
-- search 1 character, no overlap when searching a single character.

/*
                                                        --  01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11    | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19    | 20 | 21 | 22 | 23
                                                        --  1  | 2  | 3  | 4  | 5  | 6  | 7  | 8  | 9  | 0  | 1 2   | 3  | 4  | 5  | 6  | 7  | 8  | 9  | 0 1   | 2  | 3  | 4  | 5
"Bundesstraße sss sßs ss"~text~c2g=                     -- '42 | 75 | 6E | 64 | 65 | 73 | 73 | 74 | 72 | 61 | C39F  | 65 | 20 | 73 | 73 | 73 | 20 | 73 | C39F  | 73 | 20 | 73 | 73'
                                                        --  B  | u  | n  | d  | e  | s  | s  | t  | r  | a  | ß     | e  | _  | s  | s  | s  | _  | s  | ß     | s  | _  | s  | s
                                                        --                           ^    ^                   ^                 ^    ^    ^         ^    ^       ^         ^    ^

                                                        --  01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11    | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19    | 20 | 21 | 22 | 23
                                                        --  1  | 2  | 3  | 4  | 5  | 6  | 7  | 8  | 9  | 0  | 1  2  | 3  | 4  | 5  | 6  | 7  | 8  | 9  | 0  1  | 2  | 3  | 4  | 5
"Bundesstraße sss sßs ss"~text~casefold~c2g=            -- '62 | 75 | 6E | 64 | 65 | 73 | 73 | 74 | 72 | 61 | 73 73 | 65 | 20 | 73 | 73 | 73 | 20 | 73 | 73 73 | 73 | 20 | 73 | 73'
                                                        --  B  | u  | n  | d  | e  | s  | s  | t  | r  | a  | ß     | e  | _  | s  | s  | s  | _  | s  | ß     | s  | _  | s  | s
*/

"Bundesstraße sss sßs ss"~text~caselessPos("s")=        -- 6
"Bundesstraße sss sßs ss"~text~caselessPos("s", 7)=     -- 7
"Bundesstraße sss sßs ss"~text~caselessPos("s", 8)=     -- 14
"Bundesstraße sss sßs ss"~text~caselessPos("s", 15)=    -- 15
"Bundesstraße sss sßs ss"~text~caselessPos("s", 16)=    -- 16
"Bundesstraße sss sßs ss"~text~caselessPos("s", 17)=    -- 18
"Bundesstraße sss sßs ss"~text~caselessPos("s", 19)=    -- 20
"Bundesstraße sss sßs ss"~text~caselessPos("s", 21)=    -- 22
"Bundesstraße sss sßs ss"~text~caselessPos("s", 23)=    -- 23
"Bundesstraße sss sßs ss"~text~caselessPos("s", 24)=    -- 0
"Bundesstraße sss sßs ss"~text~caselessPos("s", asList:)~allItems=              -- [ 6, 7, 14, 15, 16, 18, 20, 22, 23]
"Bundesstraße sss sßs ss"~text~caselessPos("s", asList:, overlap:)~allItems=    -- [ 6, 7, 14, 15, 16, 18, 20, 22, 23]
"Bundesstraße sss sßs ss"~text~caselessPos("s", asList:, aligned:.false)=
"Bundesstraße sss sßs ss"~text~caselessPos("s", asList:, overlap:, aligned:.false)=

--------------
-- test case 4
--------------
-- caselessPos (apply casefold internally but returns external indexes)
-- search 3 characters

/*
                                                        --  01 02 03 04 05 06 07 08 09 10 11   12 13 14 15 16 17 18 19   20 21 22 23
"Bundesstraße sss sßs ss"~text~c2g=                     -- '42 75 6E 64 65 73 73 74 72 61 C39F 65 20 73 73 73 20 73 C39F 73 20 73 73'
                                                        --  B  u  n  d  e  s  s  t  r  a  ß    e  _  s  s  s  _  s  ß    s  _  s  s
                                                        --                                           |           |  |
*/

                                                                                --                  Raku                Chrome
"Bundesstraße sss sßs ss"~text~caselessPos("sSs")=                              -- 14               13                  y
"Bundesstraße sss sßs ss"~text~caselessPos("sSs", 15)=                          -- 18               17                  y
"Bundesstraße sss sßs ss"~text~caselessPos("sSs", 19)=                          -- 19   (overlap)   18 (if overlap)     y
"Bundesstraße sss sßs ss"~text~caselessPos("sSs", 20)=                          -- 0
"Bundesstraße sss sßs ss"~text~caselessPos("sSs", asList:)~allItems=            -- [ 14, 18]
"Bundesstraße sss sßs ss"~text~caselessPos("sSs", asList:, overlap:)~allItems=  -- [ 14, 18, 19]
"Bundesstraße sss sßs ss"~text~caselessPos("sSs", asList:, aligned:.false)=
"Bundesstraße sss sßs ss"~text~caselessPos("sSs", asList:, overlap:, aligned:.false)=

--------------
-- test case 5
--------------
-- caselessPos (apply casefold internally but returns external indexes)
-- search 4 characters

/*
                                                        --  01 02 03 04 05 06 07 08 09 10 11   12 13 14 15 16 17 18 19   20 21 22 23
"Bundesstraße sss sßs ss"~text~c2g=                     -- '42 75 6E 64 65 73 73 74 72 61 C39F 65 20 73 73 73 20 73 C39F 73 20 73 73'
                                                        --  B  u  n  d  e  s  s  t  r  a  ß    e  _  s  s  s  _  s  ß    s  _  s  s
                                                        --                                                       |
*/

"Bundesstraße sss sßs ss"~text~caselessPos("sSsS")=                             -- 18 (good, same result as Raku and Chrome)
"Bundesstraße sss sßs ss"~text~caselessPos("sSsS", asList:)~allItems=           -- [ 18]
"Bundesstraße sss sßs ss"~text~caselessPos("sSsS", asList:, overlap:)~allItems= -- [ 18]
"Bundesstraße sss sßs ss"~text~caselessPos("sSsS", asList:, aligned:.false)=
"Bundesstraße sss sßs ss"~text~caselessPos("sSsS", asList:, overlap:, aligned:.false)=

--------------
-- test case 6
--------------
-- caselessPos (apply casefold internally but returns external indexes)
-- search 2 characters in a long sequence

/*
                                                        --  01 02 03 04 05   06 07 08   09   10 11 12 13
"straßssßßssse"~text~c2g=                               -- '73 74 72 61 C39F 73 73 C39F C39F 73 73 73 65'
                                                        --  s  t  r  a  ß    s  s  ß    ß    s  s  s  e
                                                        --              |    |  |  |    |    |  |
*/

                                                        --                  Raku                Chome
"straßssßßssse"~text~caselessPos("Ss")=                 -- 5                4                   y
"straßssßßssse"~text~caselessPos("Ss", 6)=              -- 6                5 (if overlap)      y       why Raku needs overlap?
"straßssßßssse"~text~caselessPos("Ss", 7)=              -- 8                7                   y
"straßssßßssse"~text~caselessPos("Ss", 9)=              -- 9                8 (if overlap)      y       why Raku needs overlap?
"straßssßßssse"~text~caselessPos("Ss", 10)=             -- 10               9                   y
"straßssßßssse"~text~caselessPos("Ss", 11)=             -- 11   (overlap)   10 (if overlap)     y
"straßssßßssse"~text~caselessPos("Ss", 12)=             -- 0
"straßssßßssse"~text~caselessPos("Ss", asList:)~allItems=           -- [ 5, 6, 8, 9, 10]
"straßssßßssse"~text~caselessPos("Ss", asList:, overlap:)~allItems= -- [ 5, 6, 8, 9, 10, 11]
"straßssßßssse"~text~caselessPos("Ss", asList:, aligned:.false)=
"straßssßßssse"~text~caselessPos("Ss", asList:, overlap:, aligned:.false)=

--------------
-- test case 7
--------------
-- pos, caselessPos

/*
                                                    --  01 02 03 04 05   06 07 08 09 10   11 12                                                 13
                                                    --  0                         1                      2                   3                    4
                                                    --  1  2  3  4  5 6  7  8  9  0  1 2  3  4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8  9 0 1 2
"straße noël👩‍👨‍👩‍👧🎅"~text~c2g=                         -- '73 74 72 61 C39F 65 20 6E 6F C3AB 6C F09F91A9E2808DF09F91A8E2808DF09F91A9E2808DF09F91A7 F09F8E85'
                                                    --                                                                                 |
*/

"👧🎅"~text~c2g=                                   -- 'F09F91A7 F09F8E85'
"👧🎅"~text~casefold~c2g=                          -- 'F09F91A7 F09F8E85'

"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅", 1, aligned:.false)=         -- [-12.35,+14.43]
"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅", 12, aligned:.false)=        -- [-12.35,+14.43]
"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅", 13, aligned:.false)=        -- 0
"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅", 13, asList:)=               -- a List (0 items)
"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅", 13, asList:, overlap:)=     -- a List (0 items)
"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅", asList:, aligned:.false)=
"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅", asList:, overlap:, aligned:.false)=

"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", 1, aligned:.false)=     -- [-12.35,+14.43]
"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", 12, aligned:.false)=    -- [-12.35,+14.43]
"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", 13, aligned:.false)=    -- 0
"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", asList:, aligned:.false)=
"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", asList:, overlap:, aligned:.false)=

-- yes, 12.35, not 12.34 even if "ë" (2 bytes) becomes internally "e" (1 byte)
-- because the indexes are external (relative to the target string, not related to the internal transformed string)
"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", 1, aligned:.false, stripMark:)=     -- [-12.35,+14.43]
"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", 12, aligned:.false, stripMark:)=    -- [-12.35,+14.43]
"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", 13, aligned:.false, stripMark:)=    -- 0
"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", asList:, aligned:.false, stripMark:)=
"straße noël👩‍👨‍👩‍👧🎅"~text~caselessPos("👧🎅", asList:, overlap:, aligned:.false, stripMark:)=

--------------
-- test case 8
--------------
-- casefold

/*
                                                    --  01 02 03 04 05 06 07 08 09 10 11   12 13                                                 14
                                                    --  0                          1                      2                   3                    4
                                                    --  1  2  3  4  5  6  7  8  9  0  1 2  3  4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8  9 0 1 2
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold~c2g=                -- '73 74 72 61 73 73 65 20 6E 6F C3AB 6C F09F91A9E2808DF09F91A8E2808DF09F91A9E2808DF09F91A7 F09F8E85'
                                                    --                                                                                  |
*/

-- here we get 13 because "ß" is replaced by "ss" before calling pos
-- the byte position .35 is unchanged because "ß" is 2 bytes, as is "ss".
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold~pos("👧🎅", 1, aligned:.false)=                -- [-13.35,+15.43]
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold~pos("👧🎅", asList:, aligned:.false)=
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold~pos("👧🎅", asList:, overlap:, aligned:.false)=

-- stripMark has no impact on the byte position because it's an internal transformation
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold~pos("👧🎅", 1, aligned:.false, stripMark:)=    -- [-13.35,+15.43]
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold~pos("👧🎅", asList:, aligned:.false, stripMark:)=
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold~pos("👧🎅", asList:, overlap:, aligned:.false, stripMark:)=

-- here we get 13.34 because stripMark has an impact on the byte position:
-- "ë" (2 bytes" becomes "e" (1 byte) before calling pos.
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold(stripMark:)~pos("👧🎅", 1, aligned:.false)=    -- [-13.34,+15.42]
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold(stripMark:)~pos("👧🎅", asList:, aligned:.false)=
"straße noël👩‍👨‍👩‍👧🎅"~text~casefold(stripMark:)~pos("👧🎅", asList:, overlap:, aligned:.false)=

--------------
-- test case 9
--------------
-- pos with a needle inside a grapheme of the haystack
-- Raku consider there is no matching.

"👨‍👩"~text~c2g=                                  -- 'F09F91A8E2808DF09F91A9'

"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👨‍👩")=                   -- 0
"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👨‍👩", aligned:.false)=   -- [-12.21,-12.32]
"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👨‍👩", asList:, aligned:.false)=
"straße noël👩‍👨‍👩‍👧🎅"~text~pos("👨‍👩", asList:, overlap:, aligned:.false)=

---------------
-- test case 10
---------------
-- pos with ignorable (no internal transformation)
-- TAG SPACE is ignorable

/*
                                                                                --  01 02   03         04 05 06 07 08 09 10 11   12 13 14 15 16 17         18   19 20
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~c2g=             -- '54 C38A 74F3A080A0 65 20 73 73 73 20 73 C39F 73 20 73 73 20 74F3A080A0 C3AA 54 45'
                                                                                --  T  Ê    t TAG SPAC e  _  s  s  s  _  s  ß    s  _  s  s  _  t TAG SPAC ê    T  E
                                                                                --                           |  |                      |
*/

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("ss", asList:)~allItems=             -- [ 6, 14]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("ss", asList:, overlap:)~allItems=   -- [ 6, 7, 14]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("ss", asList:, aligned:.false)=
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("ss", asList:, overlap:, aligned:.false)=

--------------
-- test case 11
--------------
-- caselessPos with ignorable (apply casefold internally but returns external indexes)
-- TAG SPACE is ignorable

/*
                                                                                --  01 02   03         04 05 06 07 08 09 10 11   12 13 14 15 16 17         18   19 20
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~c2g=             -- '54 C38A 74F3A080A0 65 20 73 73 73 20 73 C39F 73 20 73 73 20 74F3A080A0 C3AA 54 45'
                                                                                --  T  Ê    t TAG SPAC e  _  s  s  s  _  s  ß    s  _  s  s  _  t TAG SPAC ê    T  E
                                                                                --                           |  |           |          |
*/

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("ss", asList:)~allItems=             -- [ 6, 11, 14]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("ss", asList:, overlap:)~allItems=   -- [ 6, 7, 11, 14]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("ss", asList:, aligned:.false)=
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("ss", asList:, overlap:, aligned:.false)=


"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", asList:)~allItems=             -- [ 19]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", asList:, overlap:)~allItems=   -- [ 19]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", asList:, aligned:.false)=
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", asList:, overlap:, aligned:.false)=

---------------
-- test case 12
---------------
-- pos with ignorable (apply casefold + stripMark internally but returns external indexes)
-- TAG SPACE is ignorable

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("te", stripMark:, asList:)=              -- a List (0 items)
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("te", stripMark:, asList:, overlap:)=    -- a List (0 items)

---------------
-- test case 13
---------------
-- caselessPos with ignorable (apply casefold + stripMark internally but returns external indexes)
-- TAG SPACE is ignorable

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:, asList:)~allItems=             -- [ 1, 19]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:, asList:, overlap:)~allItems=   -- [ 1, 19]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:, asList:, aligned:.false)=
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:, asList:, overlap:, aligned:.false)=

---------------
-- test case 14
---------------
-- caselessPos with ignorable (apply casefold + stripIgnorable internally but returns external indexes)
-- TAG SPACE is ignorable

/*
                                                                                --  01 02   03         04 05 06 07 08 09 10 11   12 13 14 15 16 17         18   19 20
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~c2g=             -- '54 C38A 74F3A080A0 65 20 73 73 73 20 73 C39F 73 20 73 73 20 74F3A080A0 C3AA 54 45'
                                                                                --  T  Ê    t TAG SPAC e  _  s  s  s  _  s  ß    s  _  s  s  _  t TAG SPAC ê    T  E
                                                                                --  |       |                                                   |               |
*/

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:, stripIgnorable:, asList:)~allItems=            -- [ 1, 3, 17, 19]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:, stripIgnorable:, asList:, overlap:)~allItems=  -- [ 1, 3, 17, 19]
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:, stripIgnorable:, asList:, aligned:.false)=
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:, stripIgnorable:, asList:, overlap:, aligned:.false)=


-- ===============================================================================
-- 2023 Sep 06

/*
Fix the implementation of caselessPos, pos.
Was not returning the right position when the length of the string changed
internally. Now the results are identical to Raku's (with a few exceptions).
*/

"Bundesstraße im Freiland"~text~pos("Freiland")=                -- 17
"Bundesstraße im Freiland"~text~caselessPos("freiland")=        -- 17

--------------
-- test case 1
--------------
-- pos (no internal transformation)

/*
                                                        --  01 02 03 04 05 06 07 08 09 10 11   12 13 14 15 16 17 18 19   20 21 22 23
"Bundesstraße sss sßs ss"~text~c2g=                     -- '42 75 6E 64 65 73 73 74 72 61 C39F 65 20 73 73 73 20 73 C39F 73 20 73 73'
                                                        --  B  u  n  d  e  s  s  t  r  a  ß    e  _  s  s  s  _  s  ß    s  _  s  s
                                                        --                 |                         |                         |        no overlap
                                                        --                 |                         |  |                      |        with overlap
*/

"Bundesstraße sss sßs ss"~text~pos("ss")=               -- 6
"Bundesstraße sss sßs ss"~text~pos("ss", 7)=            -- 14
"Bundesstraße sss sßs ss"~text~pos("ss", 15)=           -- 15 (overlap)
"Bundesstraße sss sßs ss"~text~pos("ss", 16)=           -- 22
"Bundesstraße sss sßs ss"~text~pos("ss", 23)=           -- 0

--------------
-- test case 2
--------------
-- caselessPos (apply casefold internally but returns external indexes)

/*
                                                        --  01 02 03 04 05 06 07 08 09 10 11   12 13 14 15 16 17 18 19   20 21 22 23
"Bundesstraße sss sßs ss"~text~c2g=                     -- '42 75 6E 64 65 73 73 74 72 61 C39F 65 20 73 73 73 20 73 C39F 73 20 73 73'
                                                        --  B  u  n  d  e  s  s  t  r  a  ß    e  _  s  s  s  _  s  ß    s  _  s  s
                                                        --                 |              |          |           |             |        no overlap
                                                        --                 |              |          |  |        |  |          |        with overlap
*/

"Bundesstraße sss sßs ss"~text~caselessPos("ss")=       -- 6
"Bundesstraße sss sßs ss"~text~caselessPos("ss", 7)=    -- 11
"Bundesstraße sss sßs ss"~text~caselessPos("ss", 12)=   -- 14
"Bundesstraße sss sßs ss"~text~caselessPos("ss", 15)=   -- 15 (overlap)
"Bundesstraße sss sßs ss"~text~caselessPos("ss", 16)=   -- 19           (Raku doesn't return this index, am I wrong? sounds good to me...)
"Bundesstraße sss sßs ss"~text~caselessPos("ss", 20)=   -- 22
"Bundesstraße sss sßs ss"~text~caselessPos("ss", 23)=   -- 0

--------------
-- test case 3
--------------
-- casefold~pos (the returned indexes are different from caselessPos because the string is transformed before calling ~pos)
-- Use "ü" instead of "u" to have a non-ASCII string.
-- Without "ü", the 'pos' method would forward to String.

/*
                                                        --  01 02   03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
"Bündesstraße sss sßs ss"~text~casefold~c2g=            -- '62 C3BC 6E 64 65 73 73 74 72 61 73 73 65 20 73 73 73 20 73 73 73 73 20 73 73'
                                                        --  b  ü    n  d  e  s  s  t  r  a  s  s  e  _  s  s  s  _  s  s  s  s  _  s  s
                                                        --                   |              |           |           |     |        |    no overlap
                                                        --                   |              |           |  |        |  |  |        |    with overlap
*/

"Bündesstraße sss sßs ss"~text~casefold~pos("ss")=      -- 6
"Bündesstraße sss sßs ss"~text~casefold~pos("ss", 7)=   -- 11
"Bündesstraße sss sßs ss"~text~casefold~pos("ss", 12)=  -- 15
"Bündesstraße sss sßs ss"~text~casefold~pos("ss", 16)=  -- 16 (overlap)
"Bündesstraße sss sßs ss"~text~casefold~pos("ss", 17)=  -- 19
"Bündesstraße sss sßs ss"~text~casefold~pos("ss", 20)=  -- 20 (overlap)
"Bündesstraße sss sßs ss"~text~casefold~pos("ss", 21)=  -- 21 (overlap)
"Bündesstraße sss sßs ss"~text~casefold~pos("ss", 22)=  -- 24
"Bündesstraße sss sßs ss"~text~casefold~pos("ss", 25)=  -- 0


--------------
-- test case 4
--------------
-- TAG SPACE is ignorable
"TÊt\u{TAG SPACE}e"~text~unescape~length=                                       -- 4
"TÊt\u{TAG SPACE}e"~text~unescape~c2g=                                          -- '54 C38A 74F3A080A0 65'
"TÊt\u{TAG SPACE}e"~text~unescape~transform(stripIgnorable:)~c2g=               -- '54 C38A 74 65'

--------------
-- test case 5
--------------
-- pos with ignorable (no internal transformation)

/*
                                                                                --  01 02   03         04 05 06 07 08 09 10 11   12 13 14 15 16 17         18   19 20
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~c2g=             -- '54 C38A 74F3A080A0 65 20 73 73 73 20 73 C39F 73 20 73 73 20 74F3A080A0 C3AA 54 45'
                                                                                --  T  Ê    t TAG SPAC e  _  s  s  s  _  s  ß    s  _  s  s  _  t TAG SPAC ê    T  E
                                                                                --                           |  |                      |
*/

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("ss")=       -- 6
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("ss", 7)=    -- 7
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("ss", 8)=    -- 14
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("ss", 15)=   -- 0

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("te")=       -- 0

--------------
-- test case 6
--------------
-- caselessPos with ignorable (apply casefold internally but returns external indexes)

/*
                                                                                --  01 02   03         04 05 06 07 08 09 10 11   12 13 14 15 16 17         18   19 20
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~c2g=             -- '54 C38A 74F3A080A0 65 20 73 73 73 20 73 C39F 73 20 73 73 20 74F3A080A0 C3AA 54 45'
                                                                                --  T  Ê    t TAG SPAC e  _  s  s  s  _  s  ß    s  _  s  s  _  t TAG SPAC ê    T  E
                                                                                --                           |  |        |  |          |
*/

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("ss")=       -- 6
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("ss", 7)=    -- 7 (overlap)
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("ss", 8)=    -- 11
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("ss", 12)=   -- 14
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("ss", 15)=   -- 0

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te")=       -- 19
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", 20)=   -- 0

--------------
-- test case 7
--------------
-- pos with ignorable (apply casefold + stripMark internally but returns external indexes)
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~pos("te", stripMark:)=   -- 0

--------------
-- test case 8
--------------
-- caselessPos with ignorable (apply casefold + stripMark internally but returns external indexes)
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:)=       -- 1
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", 2, stripMark:)=    -- 19
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", 20, stripMark:)=   -- 0

--------------
-- test case 9
--------------
-- caselessPos with ignorable (apply casefold + stripIgnorable internally but returns external indexes)

/*
                                                                                --  01 02   03         04 05 06 07 08 09 10 11   12 13 14 15 16 17         18   19 20
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~c2g=             -- '54 C38A 74F3A080A0 65 20 73 73 73 20 73 C39F 73 20 73 73 20 74F3A080A0 C3AA 54 45'
                                                                                --  T  Ê    t TAG SPAC e  _  s  s  s  _  s  ß    s  _  s  s  _  t TAG SPAC ê    T  E
                                                                                --  |       |                                                   |               |
*/

"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", stripMark:, stripIgnorable:)=      -- 1
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", 2, stripMark:, stripIgnorable:)=   -- 3
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", 4, stripMark:, stripIgnorable:)=   -- 17
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", 18, stripMark:, stripIgnorable:)=  -- 19
"TÊt\u{TAG SPACE}e sss sßs ss t\u{TAG SPACE}êTE"~text~unescape~caselessPos("te", 20, stripMark:, stripIgnorable:)=  -- 0


-- ===============================================================================
-- 2023 Aug 29

/*
Implementation of caselessContains, contains:
(forwards to caselessPos or pos, and returns .true if result <> 0)
(was already implemented, waiting for 'pos' implementation)
Examples:
*/
    "Père Noël Père Noël"~text~contains("oë")=                   -- .true
    "Père Noël Père Noël"~text~contains("oë", , 7)=              -- .false
    "Père Noël Père Noël"~text~contains("oë", , 8)=              -- .true
    "Père Noël Père Noël"~text~contains("oë", 8)=                -- .true
    "Père Noël Père Noël"~text~contains("oë", 8, 10)=            -- .false
    "Père Noël Père Noël"~text~contains("oë", 8, 11)=            -- .true
    "Père Noël Père Noël"~text~caselessContains("OË", 8, 11)=    -- .true

    "noël👩‍👨‍👩‍👧🎅"~text~contains("👧🎅")=                            -- .false
    "noël👩‍👨‍👩‍👧🎅"~text~contains("👧🎅", aligned:.false)=            -- .true
    "noël👩‍👨‍👩‍👧🎅"~text~contains("👩‍👨‍👩‍👧🎅", aligned:.false)=            -- .true


-- ===============================================================================
-- 2023 Aug 28

/*
Add a named argument 'aligned' to caselessPos, pos:
- If aligned=.true (default) then return the first character position in the
  untransformed haystack such as all the bytes of the transformed needle are
  matched with corresponding bytes in the transformed haystack AND the first
  and last byte positions are aligned with character positions.
  If no match then return 0.
- If aligned=.false then return a couple (array) of numbers +/-posC.posB where
  posB is the position of the matched byte in the transformed haystack, and posC
  is the corresponding grapheme position in the untransformed haystack.
  A number is negative if the byte position is not aligned with the corresponding
  character position.
  The first number is the start of the matching.
  The second number is the end of the matching + 1.

aligned=.false is intended for analysis of matchings and [non-]regression tests.
Otherwise, I don't see any use.

Example:
*/
    "noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅")=                           -- 0
    "noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅", aligned:.false)=           -- [-5.27,+7.35]
    "noël👩‍👨‍👩‍👧🎅"~text~pos("👩‍👨‍👩‍👧🎅", aligned:.false)=           -- [+5.6,+7.35]


/*
Comparison operators:
Take into account the default normalization managed by the .Unicode class
*/
.Unicode~normalizationName(.Unicode~defaultNormalization(strict:.true))=    -- NFC when strict
.Unicode~normalizationName(.Unicode~defaultNormalization(strict:.false))=   -- NFKD when not strict
/*
Example:
*/
    ("baﬄe"~text == "baffle"~text) =    -- false
    ("baﬄe"~text = "baffle"~text) =     -- true
/*
Reminder: the non-strict mode supports all the Unicode spaces, not just U+0032.
*/
    string1 = " Le\u{IDEOGRAPHIC SPACE}Pè\u{ZERO-WIDTH-SPACE}re\u{HYPHEN}Noël"~text~unescape
    string2 = "Le\u{OGHAM SPACE MARK}Père\u{EN DASH}No\u{ZERO-WIDTH-SPACE}ël "~text~unescape
    (string1 == string2) =              -- false
    (string1 = string2) =               -- true


-- ===============================================================================
-- 2023 Aug 26

t = "noël👩‍👨‍👩‍👧🎅"~text; t~c2g=    -- '6E 6F C3AB 6C F09F91A9E2808DF09F91A8E2808DF09F91A9E2808DF09F91A7 F09F8E85'
t = "noël👩‍👨‍👩‍👧🎅"~text; do indexB=1 to t~string~length + 2; indexC = t~indexer~characterIndexC(indexB); character = t~character(abs(indexC)); say "indexB" indexB~right(3) "--> indexC" indexC~right(4) "    " character~c2x; end


-- Implementation of caselessCompare, compare
-- ------------------------------------------
    "hello"~text~compare("hello")=                          -- 0
    "hello"~text~compare("helloo")=                         -- 6
    "hello"~text~compare("hellô")=                          -- 5
    "hello"~text~caselessCompare("hellô",stripMark:)=       -- 0
    "hellÔ"~text~caselessCompare("hellô")=                  -- 0
    "hellÔ"~text~caselessCompare("")=                       -- 1
    "hellÔ"~text~caselessCompare("", "h")=                  -- 2
    zwsp = "\u{ZERO WIDTH SPACE}"~text~unescape             -- ignorable
    ("he"zwsp"llo")~compare("hellô")=                       -- 3 (ok)
    ("he"zwsp"llo")~compare("hellô", stripIgnorable:)=      -- 6 (ok? not 5 because the ignorable character count as a character)


-- casefold 2 characters: "ß" becomes "ss"
    "Bundesstraße im Freiland"~text~caselessCompare("Bundesstraße")=        -- 14 (good)
    "Bundesstraße im Freiland"~text~caselessCompare("Bundesstraße", "_")=   -- 13 (good)
    "Bundesstraße im Freiland"~text~caselessCompare("bundesstrasse")=       -- 14 (good)
    "Bundesstrasse im Freiland"~text~caselessCompare("bundesstraße")=       -- 15 (good)
    "straßssßßssse"~text~compare("stra", "ß")=                              --  6 (good)
    "straßssßßssse"~text~caselessCompare("stra", "ß")=                      -- 12 (not 13 because the last 's' match half of the pad 'ss')

/*
This test case is a little bit strange because:
- the case-folded character looks identical to the original character.
- the normalization and the casefold have the same effect.
*/
-- casefold 3 characters: "ΐ" 'U+0390' becomes "ΐ" 'U+03B9 U+0308 U+0301'
    iota_dt = "\u{GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS}"~text~unescape
    iota_dt~casefold~UnicodeCharacters==
    ("a" iota_dt "b")~compare("a")=                         -- 3
    ("a" iota_dt "b")~compare("a" iota_dt)=                 -- 5
    ("a" iota_dt~casefold "b")~compare("a" iota_dt)=                                -- 5 (yes! not 3 because the default NFC transforms iota_dt~casefold 'U+03B9 U+0308 U+0301' into 'U+0390')
    ("a" iota_dt~casefold "b")~compare("a" iota_dt, normalization: .Unicode~NFD)=   -- 5 (yes! not 3 because NFD transforms iota_dt 'U+0390' into 'U+03B9 U+0308 U+0301'
    ("a" iota_dt~casefold "b")~compare("a" iota_dt, normalization: 0)=              -- 3 because normalization deactivated
    ("a" iota_dt "b")~caselessCompare("a")=                 -- 3
    ("a" iota_dt "b")~caselessCompare("a" iota_dt)=         -- 5
    ("a" iota_dt "b")~caselessCompare("a ", iota_dt)=       -- 4


-- Implementation of caselessEndsWith, endsWith
-- --------------------------------------------
    "hello"~text~endsWith("")=                              -- false
    "hello"~text~endsWith("o")=                             -- true
    "hello"~text~endsWith("ô")=                             -- false
    "hello"~text~endsWith("ô", stripMark:)=                 -- true
    "hello"~text~endsWith("O")=                             -- false
    "hello"~text~caselessEndsWith("O")=                     -- true


-- Rework implementation of caselessMatchChar, matchChar
-- -----------------------------------------------------
    "BAFFLE"~text~caselessMatchChar(3, "ﬄ")=               -- 0, was 1 before 2023.12.04      "ﬄ" becomes "ffl" (3 graphemes), there is a match on "f" at 3
    "BAFFLE"~text~caselessMatchChar(5, "ﬄ")=               -- 0, was 1 before 2023.12.04      "ﬄ" becomes "ffl" (3 graphemes), there is a match on "l" at 5
    "baffle"~text~caselessMatchChar(5, "L")=               -- 1      there is a match on "l" at 5 (forward to string)
    "baﬄe"~text~caselessMatchChar(3, "ﬄ")=                 -- 1      "ﬄ" at 3 (1 grapheme) becomes "ffl" (3 graphemes), there is a match on "l"
    "baﬄe"~text~caselessMatchChar(3, "F")=                 -- 0, was 1 before 2023.12.04      "ﬄ" at 3 (1 grapheme) becomes "ffl" (3 graphemes), there is a match on "f"
    "baﬄe"~text~caselessMatchChar(3, "L")=                 -- 0, was 1 before 2023.12.04      "ﬄ" at 3 (1 grapheme) becomes "ffl" (3 graphemes), there is a match on "l"
    "baﬄe"~text~caselessMatchChar(4, "E")=                 -- 1      the grapheme at 4 is "e", not "f". There is a match with "e"


-- Rework implementation of caselessCompareTo, compareTo
-- -----------------------------------------------------
    "Père Noël"~text~nfc~compareTo("Père Noël"~text~nfc)=                       -- 0 (equal)
    "Père Noël"~text~nfc~compareTo("Père Noël"~text~nfd)=                       -- 0 (equal)
    "Père Noël"~text~nfd~compareTo("Père Noël"~text~nfc)=                       -- 0 (equal)
    "Père Noël"~text~nfd~compareTo("Père Noël"~text~nfd)=                       -- 0 (equal)
    ---
    "Pere Noël"~text~nfc~compareTo("Père Noel"~text~nfc, stripMark:)=           -- 0 (equal)
    "Pere Noël"~text~nfc~compareTo("Père Noel"~text~nfd, stripMark:)=           -- 0 (equal)
    "Pere Noël"~text~nfd~compareTo("Père Noel"~text~nfc, stripMark:)=           -- 0 (equal)
    "Pere Noël"~text~nfd~compareTo("Père Noel"~text~nfd, stripMark:)=           -- 0 (equal)
    ---
    "1st Père Noël"~text~nfc~compareTo("2nd Père Noël"~text~nfc)=               -- -1 (lesser)
    "1st Père Noël"~text~nfc~compareTo("2nd Père Noël"~text~nfd)=               -- -1 (lesser)
    "1st Père Noël"~text~nfd~compareTo("2nd Père Noël"~text~nfc)=               -- -1 (lesser)
    "1st Père Noël"~text~nfd~compareTo("2nd Père Noël"~text~nfd)=               -- -1 (lesser)
    ---
    "Père Noël 2nd"~text~nfc~compareTo("Père Noël 1st"~text~nfc)=               -- 1 (greater)
    "Père Noël 2nd"~text~nfc~compareTo("Père Noël 1st"~text~nfd)=               -- 1 (greater)
    "Père Noël 2nd"~text~nfd~compareTo("Père Noël 1st"~text~nfc)=               -- 1 (greater)
    "Père Noël 2nd"~text~nfd~compareTo("Père Noël 1st"~text~nfd)=               -- 1 (greater)
    ---
    "Pere Noël"~text~nfc~compareTo("Père Noel"~text~nfc, 3, 4)=                 -- 0 (equal)
    "Pere Noël"~text~nfc~compareTo("Père Noel"~text~nfd, 3, 4)=                 -- 0 (equal)
    "Pere Noël"~text~nfd~compareTo("Père Noel"~text~nfc, 3, 4)=                 -- 0 (equal)
    "Pere Noël"~text~nfd~compareTo("Père Noel"~text~nfd, 3, 4)=                 -- 0 (equal)
    ---
    "PÈRE NOËL"~text~nfc~compareTo("Père Noël"~text~nfc)=                       -- -1 (lesser)
    "PÈRE NOËL"~text~nfc~compareTo("Père Noël"~text~nfd)=                       -- -1 (lesser)
    "PÈRE NOËL"~text~nfd~compareTo("Père Noël"~text~nfc)=                       -- -1 (lesser)
    "PÈRE NOËL"~text~nfd~compareTo("Père Noël"~text~nfd)=                       -- -1 (lesser)
    ---
    "PÈRE NOËL"~text~nfc~caselessCompareTo("Père Noël"~text~nfc)=               -- 0 (equal)
    "PÈRE NOËL"~text~nfc~caselessCompareTo("Père Noël"~text~nfd)=               -- 0 (equal)
    "PÈRE NOËL"~text~nfd~caselessCompareTo("Père Noël"~text~nfc)=               -- 0 (equal)
    "PÈRE NOËL"~text~nfd~caselessCompareTo("Père Noël"~text~nfd)=               -- 0 (equal)
    ---
    "PERE NOËL"~text~nfc~caselessCompareTo("Père Noel"~text~nfc, 3, 4)=         -- 0 (equal)
    "PERE NOËL"~text~nfc~caselessCompareTo("Père Noel"~text~nfd, 3, 4)=         -- 0 (equal)
    "PERE NOËL"~text~nfd~caselessCompareTo("Père Noel"~text~nfc, 3, 4)=         -- 0 (equal)
    "PERE NOËL"~text~nfd~caselessCompareTo("Père Noel"~text~nfd, 3, 4)=         -- 0 (equal)


-- Implementation of caselessPos, pos
-- ----------------------------------

/*
    --       P  è       r  e  _  N  o  ë       l
    --       1  2       3  4  5  6  7  8       9
    -- NFC  '50 C3A8    72 65 20 4E 6F C3AB    6C'
    --       1  2 3     4  5  6  7  8  9 10    11
    -- NFD  '50 65 CC80 72 65 20 4E 6F 65 CC88 6C'
    --       1  2  3 4  5  6  7  8  9  19 1112 13
*/
                                                            --      self needle
    "Père Noël Père Noël"~text~pos("l")=                    -- 9    NFC, NFC
    "Père Noël Père Noël"     ~pos("l")=                    -- 9    NFC, NFC    (was 11 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", , 8)=               -- 0    NFC, NFC
    "Père Noël Père Noël"     ~pos("l", , 10)=              -- 9    NFC, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", , 9)=               -- 9    NFC, NFC
    "Père Noël Père Noël"     ~pos("l", , 11)=              -- 9    NFC, NFC    (was 11 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", 10)=                -- 19   NFC, NFC
    "Père Noël Père Noël"     ~pos("l", 12)=                -- 19   NFC, NFC    (was 23 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", 10, 9)=             -- 0    NFC, NFC
    "Père Noël Père Noël"     ~pos("l", 12, 11)=            -- 19   NFC, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", 10, 10)=            -- 19   NFC, NFC
    "Père Noël Père Noël"     ~pos("l", 12, 12)=            -- 19   NFC, NFC    (was 23 before automatic conversion of string literals to text)

    ---

    "Père Noël Père Noël"~text~pos("l")=                    -- 9    NFD, NFC
    "Père Noël Père Noël"     ~pos("l")=                    -- 9    NFD, NFC    (was 13 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", , 8)=               -- 0    NFD, NFC
    "Père Noël Père Noël"     ~pos("l", , 12)=              -- 9    NFD, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", , 9)=               -- 9    NFD, NFC
    "Père Noël Père Noël"     ~pos("l", , 13)=              -- 9    NFD, NFC    (was 13 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", 10)=                -- 19   NFD, NFC
    "Père Noël Père Noël"     ~pos("l", 14)=                -- 19   NFD, NFC    (was 27 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", 10, 9)=             -- 0    NFD, NFC
    "Père Noël Père Noël"     ~pos("l", 14, 13)=            -- 19   NFD, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("l", 10, 10)=            -- 19   NFD, NFC
    "Père Noël Père Noël"     ~pos("l", 14, 14)=            -- 19   NFD, NFC    (was 27 before automatic conversion of string literals to text)

    ---

    "Père Noël Père Noël"~text~pos("oë")=                   -- 7    NFC, NFC
    "Père Noël Père Noël"     ~pos("oë")=                   -- 7    NFC, NFC    (was 8 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", , 7)=              -- 0    NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", , 9)=              -- 7    NFC, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", , 8)=              -- 7    NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", , 10)=             -- 7    NFC, NFC    (was 8 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", 8)=                -- 17   NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", 9)=                -- 17   NFC, NFC    (was 20 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", 8, 10)=            -- 0    NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", 9, 13)=            -- 17   NFC, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", 8, 11)=            -- 17   NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", 9, 14)=            -- 17   NFC, NFC    (was 20 before automatic conversion of string literals to text)

    ---

    "Père Noël Père Noël"~text~pos("oë")=                   -- 7    NFD, NFC
    "Père Noël Père Noël"     ~pos("oë")=                   -- 7    NFD, NFC    (was "always 0, no need to test all the combinations" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", , 7)=              -- 0    NFD, NFC

    "Père Noël Père Noël"~text~pos("oë", , 8)=              -- 7    NFD, NFC

    "Père Noël Père Noël"~text~pos("oë", 8)=                -- 17   NFD, NFC

    "Père Noël Père Noël"~text~pos("oë", 8, 10)=            -- 0    NFD, NFC

    "Père Noël Père Noël"~text~pos("oë", 8, 11)=            -- 17   NFD, NFC

    ---

    "Père Noël Père Noël"~text~pos("oë")=                   -- 7    NFC, NFD
    "Père Noël Père Noël"     ~pos("oë")=                   -- 7    NFC, NFD    (was "always 0, no need to test all the combinations" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", , 7)=              -- 0    NFC, NFD

    "Père Noël Père Noël"~text~pos("oë", , 8)=              -- 7    NFC, NFD

    "Père Noël Père Noël"~text~pos("oë", 8)=                -- 17   NFC, NFD

    "Père Noël Père Noël"~text~pos("oë", 8, 10)=            -- 0    NFC, NFD

    "Père Noël Père Noël"~text~pos("oë", 8, 11)=            -- 17   NFC, NFD

    ---

    "Père Noël Père Noël"~text~pos("oë")=                   -- 7    NFD, NFD
    "Père Noël Père Noël"     ~pos("oë")=                   -- 7    NFD, NFD    (was 9 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", , 7)=              -- 0    NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", , 11)=             -- 7    NFD, NFD    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", , 8)=              -- 7    NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", , 12)=             -- 7    NFD, NFD    (was 9 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", 8)=                -- 17   NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", 10)=               -- 17   NFD, NFD    (was 23 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", 8, 10)=            -- 0    NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", 10, 16)=           -- 17   NFD, NFD    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~pos("oë", 8, 11)=            -- 17   NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", 10, 17)=           -- 17   NFD, NFD    (was 23 before automatic conversion of string literals to text)

    ---

    "Père Noël Père Noël"~text~pos("oe")=                   -- 0    NFC, NFC    always 0, no need to test all the combinations
    "Père Noël Père Noël"~text~pos("oe", stripMark:)=       -- 7    NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", , 7, stripMark:)=  -- 0    NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", , 8, stripMark:)=  -- 7    NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", 8, stripMark:)=    -- 17   NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", 8, 10, stripMark:)=-- 0    NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", 8, 11, stripMark:)=-- 17   NFC, NFC

    ---
    -- caseless tests not in the diary:
    ---

    "Père Noël Père Noël"~text~caselessPos("L")=                    -- 9    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L")=                    -- 9    NFC, NFC    (was 11 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", , 8)=               -- 0    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", , 10)=              -- 9    NFC, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", , 9)=               -- 9    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", , 11)=              -- 9    NFC, NFC    (was 11 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", 10)=                -- 19   NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 12)=                -- 19   NFC, NFC    (was 23 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", 10, 9)=             -- 0    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 12, 11)=            -- 19   NFC, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", 10, 10)=            -- 19   NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 12, 12)=            -- 19   NFC, NFC    (was 23 before automatic conversion of string literals to text)

    ---

    "Père Noël Père Noël"~text~caselessPos("L")=                    -- 9    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L")=                    -- 9    NFD, NFC    (was 13 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", , 8)=               -- 0    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", , 12)=              -- 9    NFD, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", , 9)=               -- 9    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", , 13)=              -- 9    NFD, NFC    (was 13 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", 10)=                -- 19   NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 14)=                -- 19   NFD, NFC    (was 27 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", 10, 9)=             -- 0    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 14, 13)=            -- 19   NFD, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("L", 10, 10)=            -- 19   NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 14, 14)=            -- 19   NFD, NFC    (was 27 before automatic conversion of string literals to text)

    ---

    "Père Noël Père Noël"~text~caselessPos("OË")=                   -- 7    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË")=                   -- 7    NFC, NFC    (was "yes, 0, not 8 because "OË"~lower=='oË'" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", , 7)=              -- 0    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", , 9)=              -- 7    NFC, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", , 8)=              -- 7    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", , 10)=             -- 7    NFC, NFC    (was "yes, 0, not 8 because "OË"~lower=='oË'" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", 8)=                -- 17   NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", 9)=                -- 17   NFC, NFC    (was "yes, 0, not 20 because "OË"~lower=='oË'" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 10)=            -- 0    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", 9, 13)=            -- 17   NFC, NFC    (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 11)=            -- 17   NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", 9, 14)=            -- 17   NFC, NFC    (was "yes, 0, not 20 because "OË"~lower=='oË'" before automatic conversion of string literals to text)

    ---

    "Père Noël Père Noël"~text~caselessPos("OË")=                   -- 7    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("OË")=                   -- 7    NFD, NFC    (was "always 0, no need to test all the combinations" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", , 7)=              -- 0    NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", , 8)=              -- 7    NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", 8)=                -- 17   NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 10)=            -- 0    NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 11)=            -- 17   NFD, NFC

    ---

    "Père Noël Père Noël"~text~caselessPos("OË")=                   -- 7    NFC, NFD
    "Père Noël Père Noël"     ~caselessPos("OË")=                   -- 7    NFC, NFD   (was "always 0, no need to test all the combinations" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", , 7)=              -- 0    NFC, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", , 8)=              -- 7    NFC, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", 8)=                -- 17   NFC, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 10)=            -- 0    NFC, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 11)=            -- 17   NFC, NFD

    ---

    "Père Noël Père Noël"~text~caselessPos("OË")=                   -- 7    NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË")=                   -- 7    NFD, NFD   (was "yes, 9 (it works...) because the NFD representation isolate the accent: "oë"~c2x=='6F65CC88',  "OË"~lower~c2x=='6F65CC88'" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", , 7)=              -- 0    NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", , 11)=             -- 7    NFD, NFD   (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", , 8)=              -- 7    NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", , 12)=             -- 7    NFD, NFD   (was "yes, 9 (it works thanks to the NFD), see previous comment" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", 8)=                -- 17   NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", 10)=               -- 17   NFD, NFD   (was "yes, 23 (it works thanks to the NFD), see previous comment" before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 10)=            -- 0    NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", 10, 16)=           -- 17   NFD, NFD   (was 0 before automatic conversion of string literals to text)

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 11)=            -- 17   NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", 10, 17)=           -- 17   NFD, NFD   (was "yes, 23 (it works thanks to the NFD), see previous comment" before automatic conversion of string literals to text)

    ---

    "Père Noël Père Noël"~text~caselessPos("OE")=                   -- 0    NFC, NFC    always 0, no need to test all the combinations
    "Père Noël Père Noël"~text~caselessPos("OE", stripMark:)=       -- 7    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", , 7, stripMark:)=  -- 0    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", , 8, stripMark:)=  -- 7    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", 8, stripMark:)=    -- 17   NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", 8, 10, stripMark:)=-- 0    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", 8, 11, stripMark:)=-- 17   NFC, NFC


-- ===============================================================================
-- 2023 Aug 07

-- Add conversion from a Unicode encoding to a Byte encoding.
"Père Noël"~text~transcodeTo("cp437")~c2x=                                  -- '50 8A 72 65 20 4E 6F 89 6C'
'50 8A 72 65 20 4E 6F 89 6C'x~text("cp437")~utf8~c2x=                       -- '50 C3A8 72 65 20 4E 6F C3AB 6C'
'50 8A 72 65 20 4E 6F 89 6C'x~text("cp437")~transcodeTo("utf8")~c2x=        -- '50 C3A8 72 65 20 4E 6F C3AB 6C'

-- The replacementCharacter "FF"x is interpreted as a UTF-8 string (default encoding). "FF"x~text~c2u= -- 'U+FFFD'
-- Was: Hence the error "The replacement character UTF-8 not-ASCII '[FF]' cannot be transcoded to ISO-8859-1."
-- Now: Invalid UTF-8 string (since automatic conversion of string literals to text)
-- Now: Direct transcoding from 'Byte' to 'ISO-8859-1' is not supported (since the systematic absorption of The Byte_Encoding)
-- TODO: test case to get the previous error message '...cannot be transcoded...'
text = "Père Noël 🎅 10€"~text; do encoding over .Byte_Encoding~subclasses~~append(.Byte_Encoding); say encoding~name~left(13)":" text~transcodeTo(encoding, replacementCharacter:"FF"x~byte)~c2x; end

-- Here, the replacementCharacter is interpreted as a byte string encoded in the target encoding
text = "Père Noël 🎅 10€"~text; do encoding over .Byte_Encoding~subclasses~~append(.Byte_Encoding); say encoding~name~left(13)":" text~transcodeTo(encoding, replacementCharacter:"FF"x~text(encoding))~c2x; end


-- ===============================================================================
-- 2023 Aug 04


--- Following expressions return the same result correctly tagged 'ISO-8859-1'
b = .MutableBuffer~new; "Pere"~text("windows-1252")~append(" "~text("windows-1252"), buffer:b)~appendEncoded("Noël"~text("iso-8859-1"), buffer:b)=; result~description=
b = .MutableBuffer~new; "Pere"~text("windows-1252")~appendEncoded(" "~text("windows-1252"), buffer:b)~appendEncoded("Noël"~text("iso-8859-1"), buffer:b)=; result~description=
b = .MutableBuffer~new; b~appendEncoded("Pere"~text("windows-1252"), " "~text("windows-1252"), "Noël"~text("iso-8859-1"))=; result~description=

-- Following expressions (not using 'appendEncoded') return the same result as above, but wrongly tagged 'windows-1252' or 'UTF-8'
b = .MutableBuffer~new; "Pere"~text("windows-1252")~append(" "~text("windows-1252"), buffer:b)~append("Noël"~text("iso-8859-1"), buffer:b)=; result~description=
b = .MutableBuffer~new; b~append("Pere"~text("windows-1252"), " "~text("windows-1252"), "Noël"~text("iso-8859-1"))=; result~description=


-- ===============================================================================
-- 2023 Jun 28

-- Bitkey is now 2 bytes (4 hex digits) always.

-- For debug, give temporarily access to the flags stored on an indexer.
"Père Noël"~text~nfc(casefold:, stripMark:)~indexer~flags=


-- ===============================================================================
-- 2023 May 31

-- Add support for functional methods to RexxText.

-- Example inspired by https://elixir-lang.org/
-- Frequency of each character, ignoring the accents:
"Notre père Noël 🎅"~text~transform(stripMark:)~reduce(by: "characters", initial: .stem~new~~put(0)){accu[item~string] += 1}=

-- Add support for generator methods to RexxText.

g="Noël 🎅"~text~generateC
g~()=       -- T'N'
g~()=       -- T'o'
g~()=       -- T'ë'
g~()=       -- T'l'
g~()=       -- T' '
g~()=       -- T'🎅'
g~()=       -- [no result]


-- ===============================================================================
-- 2023 May 29

-- For convenience, additional way to search a character:
-- with a routine
.UnicodeCharacter("bed")=                   -- ( "🛏"   U+1F6CF So 1 "BED" )
.UnicodeCharacter("bed", hexadecimal:)=     -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
-- with the operator []
.UnicodeCharacter["bed"]=                   -- ( "🛏"   U+1F6CF So 1 "BED" )
.UnicodeCharacter["bed", hexadecimal:]=     -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )

-- This comes in complement of:
.Unicode["bed", hexadecimal:]=              -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
.Unicode~character("bed", hexadecimal:)=    -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )


-- New method UnicodeCharacter~properties at class level: return a list of property names.
.UnicodeCharacter~properties=


-- ===============================================================================
-- 2023 May 24

-- For convenience, it's now possible to search directly a character if it's made of one codepoint only:
.Unicode~character("a")=    -- ( "a"   U+0061 Ll 1 "LATIN SMALL LETTER A" )
.Unicode~character("à")=    -- ( "à"   U+00E0 Ll 1 "LATIN SMALL LETTER A WITH GRAVE" )
.Unicode~character("à")=    -- Error: The character 'à' is made of several codepoints: U+0061 U+0300

-- For the last example, you can get an array of characters:
"à"~text~UnicodeCharacters==


-- New method UnicodeCharacter~properties at instance level: Return a directory of properties.
.Unicode~character("U+000D")~properties=


-- ===============================================================================
-- 2023 March 20

-- Rework implementation of caselessMatch to support correctly
"Bundesstraße im Freiland"~text~caselessMatch(14, "im")=    -- .true


-- ===============================================================================
-- 2023 March 08

-- Implementation of caselessMatchChar, matchChar
"Noëlle"~text~matchChar(2, "aeiouy")=                       -- 1
"Noëlle"~text~matchChar(3, "aeiouy")=                       -- 0
"Noëlle"~text~matchChar(3, "aeëiouy")=                      -- 1    include the accents in the list of accepted characters
"Noëlle"~text~matchChar(3, "aeiouy", stripMark:)=           -- 1    or remove the accents from the tested string
"Noëlle"~text~matchChar(6, "aeiouy")=                       -- 1

"Bundesschnellstraße"~text~matchChar(14, "s")=              -- 1
"Bundesschnellstraße"~text~matchChar(18, "s")=              -- 0
"Bundesschnellstraße"~text~matchChar(18, "sß")=             -- 1
"Bundesschnellstraße"~text~caselessMatchChar(18, "s")=      -- 0, was 1 before 2023.12.04    "ß" becomes "ss" which is 2 graphemes. The first grapheme at 18 matches "s"
"Bundesschnellstraße"~text~caselessMatchChar(19, "s")=      -- 0    "ß" becomes "ss" which is 2 graphemes. The grapheme at 19 is "e", not the second "s"
"Bundesschnellstraße"~text~caselessMatchChar(19, "e")=      -- 1    "ß" becomes "ss" which is 2 graphemes. The grapheme at 19 is "e", not the second "s"

-- The ligature disappears in NFK[CD] but not in NF[CD]
"baﬄe"~text~NFKC=                                            -- T'baffle'
"baﬄe"~text~NFKD=                                            -- T'baffle'
"baﬄe"~text~matchChar(3, "f")=                               -- 0     "ﬄ" is ONE grapheme because NFC
"baﬄe"~text~matchChar(3, "ﬄ")=                               -- 1     "ﬄ" is ONE grapheme because NFC
"baﬄe"~text~matchChar(3, "ﬄ", normalization:.Unicode~NFKD)=  -- 1     "ﬄ" becomes "ffl" (3 graphemes). There is a match because the first grapheme is "f"
"baﬄe"~text~matchChar(3, "f", normalization:.Unicode~NFKD)=  -- 0, was 1 before 2023.12.04     "ﬄ" becomes "ffl" (3 graphemes). There is a match because the first grapheme is "f"
"baﬄe"~text~matchChar(4, "f", normalization:.Unicode~NFKD)=  -- 0     "ﬄ" becomes "ffl" (3 graphemes). The grapheme at 4 is "e", not the second "f"
"baﬄe"~text~matchChar(4, "e", normalization:.Unicode~NFKD)=  -- 1     "ﬄ" becomes "ffl" (3 graphemes). The grapheme at 4 is "e", not the second "f"

-- The ligature disappears when casefolded
"baﬄe"~text~casefold=                                        -- T'baffle'
"BAFFLE"~text~caselessMatchChar(3, "ﬄ")=                     -- 0, was 1 before 2023.12.04     "ﬄ" becomes "ffl" (3 graphemes), there is a match on "f" at 3
"BAFFLE"~text~caselessMatchChar(5, "ﬄ")=                     -- 0, was 1 before 2023.12.04     "ﬄ" becomes "ffl" (3 graphemes), there is a match on "l" at 5
"BAFFLE"~text~caselessMatchChar(5, "L")=                     -- 1      there is a match on "l" at 5 (forward to String)


-- Implementation of caselessEquals, equals
"ŒUF"~text~caselessEquals("œuf")=           -- 1
"œuf"~text~caselessEquals("ŒUF")=           -- 1
"Straße"~text~caselessEquals("strasse")=    -- 1
"strasse"~text~caselessEquals("Straße")=    -- 1


-- Some ligatures are not decomposed by NFKC.
"ŒUF"~text~caselessEquals("oeuf")=                                  -- 0
"ŒUF"~text~caselessEquals("oeuf", normalization:.Unicode~NFKC)=     -- 0


-- ===============================================================================
-- 2022 November 20

/*
For consistency, all the conversion methods accept the named argument 'strict',
even if it's not needed for the unicode encodings.
Previously, was supported only for the byte encodings.
The default value of 'strict' is now .false.

The conversion methods accept the named argument 'memorize(3)'.
Its default value is given by .unicode~memorizeTranscodings (was memorizeConversions) which is .false by default.
Example:
    s = "hello"
    t = s~text
    utf16 = t~utf16(memorize:)
    utf32 = t~utf32(memorize:)
    t~utf16~"==":.object(utf16)=         -- 1
    t~utf32~"==":.object(utf32)=         -- 1
*/

/*
CP1252 to UTF-8, UTF-16, UTF-32
"Un œuf de chez MaPoule™ coûte ±0.40€"
*/
str_cp1252 = "Un " || "9C"x || "uf de chez MaPoule" || "99"x || " co" || "FB"x || "te " || "B1"x || "0.40" || "80"x
txt_cp1252 = str_cp1252~text("cp1252")
utf8  = txt_cp1252~utf8(memorize:)
utf16 = txt_cp1252~utf16(memorize:)
utf32 = txt_cp1252~utf32(memorize:)
txt_cp1252~utf8 ~"==":.object(utf8) =         -- 1
txt_cp1252~utf16~"==":.object(utf16)=         -- 1
txt_cp1252~utf32~"==":.object(utf32)=         -- 1

/*
When an optional buffer is passed, must check that its encoding is compatible.
Done for the conversion methods.
Example:
*/
b = .mutablebuffer~new            -- No encoding yet
"hello"~text~utf16(buffer:b)      -- now the buffer's encoding is UTF-16
"bye"~text~utf8(buffer:b)         -- Encoding: cannot append UTF-8 to UTF-16BE '[00]h[00]e[00]l[00]l[00]o'.


-- ===============================================================================
-- 2022 November 08

/*
Additional arguments are supported by NFC, NFD, NFKC, NFKD, Casefold:
    lump
        Lumps certain different codepoints together.
        All the concerned characters become the same character, but still remain distinct characters.
        E.g. HYPHEN U+2010 and MINUS U+2212 to ASCII "-"
             all space characters (general category Zs) to U+0020
    stripIgnorable
        Strips the characters whose property Default_Ignorable_Code_Point = true
        such as SOFT-HYPHEN or ZERO-WIDTH-SPACE
    stripCC
        Strips and/or converts control characters:
        characters 00-1F and 7F-9F, except 09 which is replaced by 20.
    stripMark
        Strips all character markings:
        characters whose category is Mc Me Mn (i.e. accents)
            Mc Spacing Mark
            Me Enclosing Mark
            Mn Nonspacing Mark
        This option works only with normalization.
    stripNA
        Strips the characters whose category is Cn Unassigned
        Note that the value gc=Cn does not actually occur in UnicodeData.txt,
        because that data file does not list unassigned code points.

Remark: the normalization NFKC_Casefold (short alias NFKC_CF) is done with
    ~NFKC(Casefold: .true, stripIgnorable: .true)
*/

/*
Two RexxText values are considered equal if their extended grapheme clusters are canonically equivalent.
This is the definition of Swift.
Q&A https://lists.isocpp.org/sg16/2018/08/0121.php
TODO: confirm that it's NFC, and only that.
The definition of canonical equivalence by the Unicode standard seems not limited to NFC.
https://unicode.org/notes/tn5/

The strict comparison operators now use the NFC normalization (update: use .Unicode~defaultNormalization(strict:.true)).
After normalization, they delegate to the String's strict comparison operators.

The non-strict comparison operators now use the NFC normalization (update: use .Unicode~defaultNormalization(strict:.false))
plus
    stripIgnorable:.true
    lump:.true
After normalization + transformations, they delegate to the String's non-strict comparison operators.
Thanks to the lump transformation, all the Unicode spaces are supported.

Examples:
*/

textNFC = "Noël"~text~NFC
textNFC~UnicodeCharacters==
textNFD="Noël"~text~NFD
textNFD~UnicodeCharacters==
(textNFC == textNFD)=                                               -- 1
(textNFC = textNFD)=                                                -- 1
(" "textNFC == textNFD" ")=                                         -- 0 because strict
(" "textNFC = textNFD" ")=                                          -- 1
(" "textNFC = (textNFD"\u{NBSP}")~unescape)=                        -- 1
(" "textNFC = (textNFD"\u{ZWSP}")~unescape)=                        -- 1
("-"textNFC = ("\u{OBLIQUE HYPHEN}"textNFD"\u{ZWSP}")~unescape)=    -- 1

"pere noel"~text~caselessCompareTo("Père Noël")=                    -- -1 (lesser)
"pere noel"~text~caselessCompareTo("Père Noël", stripMark:.true)=   --  0 (equal because the accents are ignored)

-- Add support for ISO-8859-1 encoding (alias Latin1).
-- Example:
-- all the supported characters: ranges 20-7E and A0-FF
text = xrange("20"x, "7E"x, "A0"x, "FF"x)~text("ISO-8859-1")

-- The ? are just ISO-8859-1 encoded characters that can't be displayed as-is in a console UTF-8 (copy-paste of the console output)
-- After conversion to UTF-8, all is good.
text=       -- T' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~???????????????????????????????????????????????????????????????????????????????????????????????[FF]'
text~utf8=  -- T' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ'

-- ranges 00-1F and 7F-9F are undefined
-- an error is triggered even with the option strict: .false, because there is no fallback mapping
text = xrange("20"x, "FF"x)~text("ISO-8859-1")
text~utf8(strict: .false)=                      -- Error ISO-8859-1 encoding: cannot convert ISO-8859-1 not-ASCII character 127 (7F) at byte-position 96 to UTF-8.


-- ===============================================================================
-- 2022 November 06

/*
Refactoring
    Prefix the native methods by the library name (utf8proc_, ziglyph_ or icu4x_).
    That will make more easy the comparison of similar services.

    Remove the native methods 'NFC', 'NFD', 'NFKC', 'NFKD' and 'NFKC_Casefold':
    all replaced by 'utf8proc_transform'.

    ~Casefold is now limited to case fold.
    Previously, NKFC + case fold was applied (because the method NFKC_Casefold of utf8proc was called).

    NFC, NFD, NFKC and NFKD now supports the named argument 'casefold' (default = .false).

Examples
*/
"Père Noël ß ㎒"~text~casefold=                      -- T'père noël ss ㎒'
"Père Noël ß ㎒"~text~NFKC=                          -- T'Père Noël ß MHz'
"Père Noël ß ㎒"~text~NFKC(casefold:.true)=          -- T'père noël ss mhz'

/*
Performance
    NFC, NFD, NFKC, NFKD and Casefold now supports the named argument 'returnString'.
    - When true, the returned value is a String.
    - When false (default), the returned value is a RexxText.
    Maybe this optimization will be replaced by a more general optimization: RexxText indexation on need.

    2 cached values are managed in case of memorization:
    - one for the main transformation,
    - one for the main transformation + case fold.
    That makes 9 possible cached value and 5 indicators per indexer (so per string).
        isCasefold                  CasefoldString
        isNFC       NFCString       NFCCasefoldString
        isNFD       NFDString       NFDCasefoldString
        isNFKC      NFKCString      NFKCCasefoldString
        isNFKD      NFKDString      NFKDCasefoldString

    The memorization can be activated globally:
    .Unicode~memorizeTransformations = .true

Examples
*/
-- Direct access to utf8proc, returns a string
s = "Père Noël ß ㎒"; do 10000; .Unicode~utf8proc_transform(s, normalization:3, casefold:.true); end -- Duration:   0.05
---
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(casefold:.true); end                                     -- Duration:   7.70
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(casefold:.true, returnString:.true); end                 -- Duration:   0.33
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(casefold:.true, returnString:.true, memorize:.true); end -- Duration:   0.11
-- The cache for NFKC  + casefold is different from the cache for NFKC only:
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC; end                                                     -- Duration:   6.50
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(returnString:.true); end                                 -- Duration:   0.30
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(returnString:.true, memorize:.true); end                 -- Duration:   0.10


-- ===============================================================================
-- 2022 November 05

/*
New methods on RexxText
    caselessContains        (not ready: posText)
    caselessCompareTo
    caselessMatch
    caselessMatchChar       (not ready: matchCharText)
    caselessEndsWith        (not ready: endsWithText)
    caselessPos             (not ready: posText)
    caselessStartsWith      (not ready: posText)
    compareTo
    contains                (not ready: posText)
    endsWith                (not ready: endsWithText)
    match
    matchChar               (not ready: matchCharText)
    pos                     (not ready: posText)
    startsWith              (not ready: posText)

For caseless, apply NFC Casefold to all the text/string arguments.
Compared to the ooRexx methods, the purpose of these methods is to convert the grapheme indexes to/from byte indexes.
The real work is done by the ooRexx methods, called with the right byte indexes.
From a byte index returned by an ooRexx method, a grapheme index is derived.


Examples:
*/
                                                --  1  2    3  4  5  6  7  8 9  10 (grapheme indexes)
                                                --  1  2 3  4  5  6  7  8  9 10 11 (byte indexes)
    "père Noël"~text~c2x=                       -- '70 C3A8 72 65 20 4E 6F C3AB 6C'
                                                --  p  è    r  e     N  o  ë    l
    "père Noël"~match(1, "Noël")=               -- .false (byte indexes)
    "père Noël"~text~match(1, "Noël")=          -- .false (grapheme indexes)
    "père Noël"~match(7, "Noël")=               -- .false (was ".true (byte indexes)" before automatic conversion of string literals to text)
    "père Noël"~text~match(6, "Noël")=          -- .true (grapheme indexes)
    "père Noël"~match(11, "Noël", 5)=           -- Invalid position argument specified; found "11" (was ".true (byte indexes)" before automatic conversion of string literals to text)
    "père Noël"~text~match(9, "Noël", 4)=       -- .true (grapheme indexes)

    "père Noël"~text~caselessMatch(1, "NOËL")=  -- .false
    "père Noël"~text~caselessMatch(6, "NOËL")=  -- .true

    -- the first "äXü" is NFC, the second "äẌü" is NFD
    nfcString = "äXü"
        nfcText = nfcString~text
        nfcText~c2x=                            -- 'C3A4 58 C3BC'
        nfcText~UnicodeCharacters==
    nfdString = "äXü"
        nfdText = nfdString~text
        nfdText~c2x=                            -- '61 CC88 58 75 CC88'
        nfdText~UnicodeCharacters==

    nfcString~match(1, nfdString)=              -- 1    (was "0 (because binary representation is different)" before automatic conversion of string literals to text)
    nfcText  ~match(1, nfdText)=                -- 1
    nfdText  ~match(1, nfcText)=                -- 1

    -- match with "X"

    nfcString~match(3, nfdString, 4, 1)=        -- Invalid position argument specified; found "4"   (was "1 (byte indexes)" before automatic conversion of string literals to text)
    nfcText  ~match(2, nfdText,   2, 1)=        -- 1 (grapheme indexes)

    nfdString~match(4, nfcString, 3, 1)=        -- Invalid position argument specified; found "4"   (was "1 (byte indexes)" before automatic conversion of string literals to text)
    nfdText  ~match(2, nfcText,   2, 2)=        -- 1 (grapheme indexes)

-- ===============================================================================
-- 2022 October 15

/*
New native method .Unicode~transform
Mainly for internal use, will replace the current native methods NFC, NFD, NFKC, NFKD.
The purpose of this method is to support additional transformations provided by utf8proc.
Takes a byte string as input (UTF-8 encoded), returns a new transformed byte string as output (UTF-8).

Examples:
*/
    string = "\u{BEL}Le\u{IDEOGRAPHIC SPACE}\u{OGHAM SPACE MARK}\u{ZERO-WIDTH-SPACE}Père\t\u{HYPHEN}\u{SOFT-HYPHEN}\u{EN DASH}\u{EM DASH}Noël\x{EFB790}\r\n"
    text = string~text~unescape
    text~UnicodeCharacters==

    text=                                                               -- T'[07]Le　 ​Père[09]‐­–—Noël﷐[0D0A]'

    -- Performs unicode case folding, to be able to do a case-insensitive string comparison.
    .Unicode~utf8proc_transform(text~string, casefold:.true)=           --  '[07]le　 ​père[09]‐­–—noël﷐[0D0A]'

    -- Strip "default ignorable characters" such as SOFT-HYPHEN or ZERO-WIDTH-SPACE
    .Unicode~utf8proc_transform(text~string, stripIgnorable:.true)=     --  '[07]Le　 Père[09]‐–—Noël﷐[0D0A]'

    -- Lumps certain characters together. See lump.md for details:
    -- https://github.com/JuliaStrings/utf8proc/blob/master/lump.md
    -- E.g. HYPHEN U+2010 and MINUS U+2212 to ASCII "-"
    -- jlf: I was expecting to have only one space and one "-" but that's not the case
    -- Seems working as designed... All the concerned characters become the same character, but still remain distinct characters.
    .Unicode~utf8proc_transform(text~string, lump:.true)=               --  '[07]Le  ​Père[09]-­--Noël﷐[0D0A]'

    -- NLF2LF: Convert LF, CRLF, CR and NEL into LF
    .Unicode~utf8proc_transform(text~string, NLF:1)=                    --  '[07]Le　 ​Père[09]‐­–—Noël﷐[0A]'

    -- NLF2LS: Convert LF, CRLF, CR and NEL into LS (U+2028 Zl 0 "LINE SEPARATOR")
    .Unicode~utf8proc_transform(text~string, NLF:2)=                    --  '[07]Le　 ​Père[09]‐­–—Noël﷐'

    -- NLF2PS: convert LF, CRLF, CR and NEL into PS (U+2029 Zp 0 "PARAGRAPH SEPARATOR")
    .Unicode~utf8proc_transform(text~string, NLF:3)=                    --  '[07]Le　 ​Père[09]‐­–—Noël﷐ '

    -- Strips and/or converts control characters.
    .Unicode~utf8proc_transform(text~string, stripCC:.true)=            --  'Le　 ​Père ‐­–—Noël﷐ '

    -- Strips all character markings.
    -- This includes non-spacing, spacing and enclosing (i.e. accents).
    -- This option works only with normalization.
    .Unicode~utf8proc_transform(text~string, stripMark:.true, normalization:1)=  --  '[07]Le　 ​Pere[09]‐­–—Noel﷐[0D0A]'

    -- Strips unassigned codepoints.
    .Unicode~utf8proc_transform(text~string, stripNA:.true)=            --  '[07]Le　 ​Père[09]‐­–—Noël[0D0A]'

    -- Application of several options
    .Unicode~utf8proc_transform(text~string, casefold:.true, lump:.true, normalization:1, stripIgnorable:.true, stripCC:.true, stripMark:.true, stripNA:.true)= --  'le  pere ---noel '


-- ===============================================================================
-- 2022 September 14

/*
New methods on RexxText
    center
    centre
Examples:
*/
    "noël👩‍👨‍👩‍👧🎅"~text~description=                  -- 'UTF-8 not-ASCII (6 graphemes, 12 codepoints, 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~center(10)=                   -- T'  noël👩‍👨‍👩‍👧🎅  '
    "noël👩‍👨‍👩‍👧🎅"~text~center(10)~description=       -- 'UTF-8 not-ASCII (10 graphemes, 16 codepoints, 38 bytes, 0 error)'
    pad = "═"
    pad~description=                                          -- 'UTF-8 not-ASCII (1 character, 1 codepoint, 3 bytes, 0 error)' (was 'UTF-8 not-ASCII (1 grapheme, 1 codepoint, 3 bytes, 0 error)' before automatic conversion of string literals to text)
    pad~c2x=                                                  -- 'E29590'
    "noël👩‍👨‍👩‍👧🎅"~text~center(10, pad)=              -- T'══noël👩‍👨‍👩‍👧🎅══'
    "noël👩‍👨‍👩‍👧🎅"~text~center(10, pad)~description=  -- 'UTF-8 not-ASCII (10 graphemes, 16 codepoints, 46 bytes, 0 error)'


-- ===============================================================================
-- 2022 September 09


-- Start working on encoding~previousCodepointIndexB:
    "🎅noël"~text~c2x=  -- 'F09F8E85 6E 6F C3AB 6C'
    .utf8_encoding~previousCodepointIndexB("🎅noël", 0)=   -- 0
    .utf8_encoding~previousCodepointIndexB("🎅noël", 1)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 2)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 3)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 4)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 5)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 6)=   -- 5
    .utf8_encoding~previousCodepointIndexB("🎅noël", 7)=   -- 6
-- Currently, only Byte_encoding and UTF8_encoding supports this new method.
-- Still lot of work to detect the same errors as nextCodepointIndex.


-- ===============================================================================
-- 2022 September 08

-- Set/get an encoding on a string without having an associated RexxText
-- (similar to MutableBuffer)
s = "nonsense"
s~encoding =                      -- returns the default encoding: (The UTF8_Encoding class)
s~hasText =                       -- 0
s~encoding = .UTF16BE_Encoding    -- tag the string: encoded UTF16BE
s~encoding =                      -- (The UTF16BE_Encoding class)
s~hasText =                       -- still no associated RexxText: 0
t = s~text                        -- associates a RexxText to the string
s~hasText =                       -- the string has an associated text: 1
t~encoding =                      -- the encoding of the text is the one of the string: (The UTF16BE_Encoding class)
t~utf8 =                          -- T'湯湳敮獥'      Soup
-- Setting/getting the encoding of the string will set/get the encoding of the associated RexxText
s~encoding = .UTF16LE_Encoding
t~encoding =                      -- the encoding of the text has been changed: (The UTF16LE_Encoding class)
t~utf8 =                          -- T'潮獮湥敳'      tide


-- ===============================================================================
-- 2022 September 07

/*
Add method MutableBuffer~isASCII
Implementation more complex than for String, because mutable.
Try to avoid to rescan the whole buffer, when possible.
The native methods that modify the buffer are never scanning the buffer, they
are just setting the boolean indicators is_ASCII_checked and is_ASCII.
It's only the Rexx method ~isASCII which scans the whole buffer, if needed.
Impacted methods:
    append
    caselessChangeStr
    changeStr
    delete
    delWord
    insert
    overlay
    replaceAt
    setBufferSize
    space
    translate
*/

b = .MutableBuffer~new("pere")
b~isASCII =                             -- 1
b~insert("noël", 5)=                    -- M'pere noël'
b~isASCII =                             -- 0
b~setBufferSize(7)=                     -- M'pere no'
b~isASCII=                              -- 1
b~append("ë", "l")=                     -- M'pere noël'
b~isASCII=                              -- 0
b~replaceAt("e", 8, 2)=                 -- M'pere noel'
b~isASCII=                              -- 1
b~changeStr("noel", "noël")=            -- M'pere noël'
b~isASCII=                              -- 0
b~delete(8,2)=                          -- M'pere nol'
b~isASCII=                              -- 1
b~overlay("ël", 8)=                     -- M'pere noël'
b~isASCII=                              -- 0
b~delWord(2)=                           -- M'pere '
b~isASCII=                              -- 1
b~translate("è" || "91"x, "er ")=       -- M'pèÑ'    ("è" is "C3A8"x so "e"-->"C3"x, "r"-->A8"x and " "-->"91"x
b~isASCII=                              -- 0


-- ===============================================================================
-- 2022 August 18

/*
Added Unicode case folding.
See https://www.w3.org/TR/charmod-norm/
Case folding is the process of making two texts which differ only in case identical for comparison purposes.
Implemented with utf8proc, which applies an NFKC normalization on the case-folded string.

Methods on RexxText:
    ~Casefold   ~isCasefold
*/
"ß"~text~casefold=               -- T'ss'
"㎒"~text~casefold=              -- T'mhz'   (jlf Nov 8, 2022: now unchanged because no longer NFKC)

("sTrasse", "straße", "STRASSE")~each{item~text~casefold}==

-- utf8proc doesn't support language-sensitive case-folding.
-- Example:
-- The name of the second largest city in Turkey is "Diyarbakır", which contains both the dotted and dotless letters i.
"Diyarbakır"~text~upper=        -- T'DIYARBAKIR'   should be DİYARBAKIR
"DİYARBAKIR"~text~casefold=     -- T'di̇yarbakir'   should be diyarbakır

-- The Julia developers, who uses utf8proc, have decided to remain locale-independent.
-- See https://github.com/JuliaLang/julia/issues/7848


-- ===============================================================================
-- 2022 August 07

/*
Added normalization NFC, NFD, NFKC, NFKD.
http://unicode.org/faq/normalization.html
Implemented with utf8proc.

Methods on RexxText:
    ~NFC    ~isNFC
    ~NFD    ~isNFD
    ~NFKC   ~isNFKC
    ~NFKD   ~isNFKD

Possible values for isNFxx:
    -1  unknown
     0  no
     1  yes
A same text can be in several normalization forms.
Text exclusively containing ASCII characters (U+0000..U+007F) is left unaffected
by all of the Normalization Forms: The 4 indicators isNFxx are 1.

The methods NFxx sets the corresponding indicator isNFxx
- on the source text : 0 or 1 (test if both strings are equal)
- on the result text : 1
*/

-- The normalized text can be memorized on the original text:
    text = "père Noël"~text
    textNFD = text~nfd(memorize:.true)
-- From now, the returned NFD is always the memorized text:
    text~nfd == textNFD=                    -- .true


/*
    Some remarks about the string used in this demo:
    - the first "äöü" is NFC, the second "äöü" is NFD
    - "x̂" is two codepoints in any normalization.
    - "ϔ" normalization forms are all different.
    - "ﷺ" is one of the worst cases regarding the expansion factor in NFKS/NFKS: 18x
    - "baﬄe"~text~subchar(3)=     -- T'ﬄ'
      "baﬄe"~text~upper=          -- T'BAﬄE', should be BAFFLE (to rework: utf8proc supports only simple uppercase)
      The ligature disappears in NFK[CD] but not in NF[CD]
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~description=      -- 'UTF-8 not-ASCII (18 graphemes, 22 codepoints, 34 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~upper=            -- T'ÄÖÜ ÄÖÜ X̂ ϔ ﷺ BAﬄE

/*
    NFD
    Normalization Form D
    Canonical Decomposition
    Characters are decomposed by canonical equivalence, and multiple combining characters are arranged in a specific order.
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfd~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfd~description=  -- 'UTF-8 not-ASCII (18 graphemes, 26 codepoints, 39 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfd~upper=        -- T'ÄÖÜ ÄÖÜ X̂ ϔ ﷺ BAﬄE'

/*
    NFC
    Normalization Form C
    Canonical Decomposition, followed by Canonical Composition
    Characters are decomposed and then recomposed by canonical equivalence.
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfc~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfc~description=  -- 'UTF-8 not-ASCII (18 graphemes, 19 codepoints, 31 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfc~upper=        -- T'ÄÖÜ ÄÖÜ X̂ ϔ ﷺ BAﬄE'

/*
    NFKD
    Normalization Form KD
    Compatibility Decomposition (K is used to stand for compatibility to avoid confusion with the C standing for composition)
    Characters are decomposed by compatibility, and multiple combining characters are arranged in a specific order.
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkd~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkd~description= -- 'UTF-8 not-ASCII (37 graphemes, 45 codepoints, 69 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkd~upper=       -- T'ÄÖÜ ÄÖÜ X̂ Ϋ صلى الله عليه وسلم BAFFLE

/*
    NFKC
    Normalization Form KC
    Compatibility Decomposition, followed by Canonical Composition
    Characters are decomposed by compatibility, then recomposed by canonical equivalence.
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkc~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkc~description= -- 'UTF-8 not-ASCII (37 graphemes, 38 codepoints, 61 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkc~upper=       -- T'ÄÖÜ ÄÖÜ X̂ Ϋ صلى الله عليه وسلم BAFFLE'


-- The normalization forms are implemented only for UTF-8 and WTF-8.
"D800 DC01"x~text("utf16")~nfd~UnicodeCharacters==  -- Method TRANSFORM is ABSTRACT and cannot be directly invoked.
"D800 DC01"x~text("utf16")~utf8~nfd~UnicodeCharacters==
"\uD800\uDC01"~text("wtf8")~unescape~nfd~UnicodeCharacters==

-- If the WTF-8 string is not a valid UTF-8 string then an error is raised by utf8proc
"D800"x     ~text("wtf16")~wtf8~nfd~UnicodeCharacters==    -- Invalid UTF-8 string
"\uD800"~text("wtf8")~unescape~nfd~UnicodeCharacters==     -- Invalid UTF-8 string


-- ===============================================================================
-- 2022 August 03

/*
https://discourse.julialang.org/t/stupid-question-on-unicode/27674/10
    Should I support this when unescaping?
    (High surrogate followed by low surrogate)
    Surrogate pairs are a UTF-16-specific construct.
    However, string escapes aren’t byte sequences of a particular encoding.
    They are somewhat arbitrary substitutions / macros.
*/

        "\uD83D\uDE3F"~text~unescape~errors==

        "\uD83D\uDE3F"~text~wtf8~unescape~errors==

--    Yes, I should support it when the encoding is WTF-8, because the concatenation manages correctly this case:
        ("\uD83D"~text~wtf8~unescape || "\uDE3F"~text~wtf8~unescape)~UnicodeCharacters==

        ("\uD83D"~text~wtf8~unescape || "\uDE3F"~text~wtf8~unescape)~description=

--    Done, now "\uD83D\uDE3F"~text~wtf8~unescape=    -- "😿"


-- ===============================================================================
-- 2022 July 20

/*
I realize that I can pass options when filtering the unicode characters.
Same options as when sending the message "matcher" to a string.

-- Options: not wholestring, trace with prefix "> "
*/
.unicode~characters("father", wholeString:0, trace:1, prefix:">")

-- Same options with a regular expression.
-- "/father" is faster than "/.*father.*" but still very slow compared to "father"
.unicode~characters("/father", wholeString:0, trace:1, prefix:"> ")

-- Note that "/.*father.*" in mode not wholestring is just unusable: 419 sec under MBP 2010 Intel Core 2 Duo
-- [2022 Dec 22] Still unusable under MBP 2021 M1 Pro: 78s (only 5.37 faster)


-- ===============================================================================
-- 2022 July 17


-- For convenience, add an optional parameter 'filter' to the method .unicode~characters
    .unicode~characters("*rex*")==
-- is equivalent to
    matcher = "*rex*"~matcher; .unicode~characters~select{expose matcher; matcher~(item~name)}==

-- Regular expressions are supported:
-- returns all the characters whose name starts with "math" and ends with "psi"
    .unicode~characters("/^math.*psi$")==

/*
The regular expressions are implemented with 100% ooRexx code, and as such
can be particularly inefficient...
When applied to a collection of 43885 Unicode characters, we have:
    .unicode~characters("/.*father.*")    -- 30.5 sec
The same filter without regular expression:
    .unicode~characters("*father*")       -- 0.9 sec

Something to clarify:
Why such a difference of duration for the following pieces of code?
In the end, it's the same code in both cases:
matcher = "/.*father.*"~matcher; supplier = .unicode~characters; collectedItems = .Array~new; do while supplier~available; item = supplier~item; if matcher~(item~name) then collectedItems~append(item); supplier~next; end; collectedItems==
64 sec
matcher = "/.*father.*"~matcher; .unicode~characters~select{expose matcher; matcher~(item~name)}==
31 sec
*/

-- ===============================================================================
-- 2022 July 13

/*
Rework ~unescape to be closer to other languages:
\u{...} and \U{...} are equivalent
\u{X..X} is now hexadecimal, no more decimal codepoint. The first character must be 0..9.
\uXXXX is now supported
\UXXXXXXXX is now supported

Ex:
*/
"\u{bed} is different from \u{0bed}"~text~unescape=                         -- T'🛏 is different from ௭'
.unicode~character("bed")=                                                  -- ( "🛏"   U+1F6CF So 1 "BED" )
.unicode~character("bed", hexadecimal:.true)=                               -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
.unicode~character("U+0bed")=                                               -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
"The \u{t-rex} shows his \u{flexed biceps}!"~text~unescape=                 -- T'The 🦖 shows his 💪!'
"\u0031 + \u0032\u0033 = \u0032\u0034"~text~unescape=                       -- T'1 + 23 = 24'
"\U00000031 + \U00000032\U00000033 = \U00000032\U00000034"~text~unescape=   -- T'1 + 23 = 24'

-- ===============================================================================
-- 2022 February 13

/*
New method unescape, available only for Byte, UTF-8 and WTF-8.
    \b                  backspace (BS)
    \t                  horizontal tab (HT)
    \n                  linefeed (LF)
    \f                  form feed (FF)
    \r                  carriage return (CR)
    \u{Unicode name}    Character name in the Unicode database
    \u{N..N}            Unicode character denoted by 1-8 hex digits. The first character must be a digit 0..9.
    \u{U+X..X}          Unicode character denoted by 1-n hex digits
    \x{X..X}            sequence of 1..n hexadecimal digits
Examples:
*/
    "hello\u{space}John\n"~text~unescape=           -- T'hello John[0A]'
    "hello\u{20}John\n"~text~unescape=
    "hello\u{U+20}John\n"~text~unescape=

    -- \u is not supported for Byte encoding, you can use \x
    "hello\u{U+20}John\n"~text("byte")~unescape=    -- Byte encoding: \u not supported.
    "hello\x{20}John\n"~text("byte")~unescape       -- T'hello John[0A]'

    -- No implementation for UTF-16, WTF-16, UTF-32.
    "hello\u{U+20}John\n"~text~utf16~unescape=      -- Method UNESCAPE is ABSTRACT and cannot be directly invoked.


-- ===============================================================================
-- 2021 September 30

/*
New methods:
.String
    join (was concatenateSeparated)

.MutableBuffer
    join (was concatenateSeparated)

.Unicode
    []  (equivalent to .Unicode~character)

.UnicodeCharacter
    makeRexxText
    text
    wtf8
    wtf16
    wtf16be
    wtf16le

.RexxText
    join
    left
    right
    x2d

Examples:
*/

-- https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries
-- no break before ZWJ (GB9), but break after if not emoji modifier sequence or emoji zwj sequence (GB11)
.unicode["zwj"]~utf8~join("ab", "cd", .unicode["woman"]~utf8, .unicode["father christmas"]~utf8)~c2g=  -- '61 62E2808D 63 64E2808D F09F91A9E2808DF09F8E85'
.unicode["zwj"]~utf8~join("ab", "cd", .unicode["woman"]~utf8, .unicode["father christmas"]~utf8)~graphemes==

"noël👩‍👨‍👩‍👧🎅"~text~UnicodeCharacters==

-- https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries
-- Do not break within emoji modifier sequences or emoji zwj sequences (GB11).
"noël👩‍👨‍👩‍👧🎅"~text~graphemes==

do i=0 to 9; "left("i") = " || "noël👩‍👨‍👩‍👧🎅"~text~left(i)=; end

do i=0 to 9; "right("i") = " || "noël👩‍👨‍👩‍👧🎅"~text~right(i)=; end


-- ===============================================================================
-- 2021 September 28

/*
New methods:
.RexxText
    reverse

Examples:
*/

-- Correct reverse
"noël"~text~c2x=            -- '6E 6F C3AB 6C'
"noël"~text~reverse~c2x=    -- '6C C3AB 6F 6E'
"noël"~text~reverse=        -- T'lëon'

-- Correct reverse (was Wrong reverse before automatic conversion of string literals to text)
"noël"~c2x=             -- '6E 6F C3AB 6C'
"noël"~reverse~c2x=     -- '6C C3AB 6F 6E'
"noël"~reverse=         -- T'lëon'


-- ===============================================================================
-- 2021 September 27

/*
New native methods:
.Unicode
    codepointToLower
    codepointToUpper
    codepointToTitle
    codepointIsLower
    codepointIsUpper

New methods:
.RexxText
    lower
    upper
    isLower
    isUpper
    characters

Examples:
*/

"aàâäeéèêëiîïoôöuûü"~text~isUpper=              -- .false
"aàâäeéèêëiîïoôöuûü"~text~isLower=              -- .true
"AÀÂÄEÉÈÊËIÎÏOÔÖUÛÜ"~text~isUpper=              -- .true
"AÀÂÄEÉÈÊËIÎÏOÔÖUÛÜ"~text~isLower=              -- .false
"Le père Noël est fatigué..."~text~upper=       -- T'LE PÈRE NOËL EST FATIGUÉ...'
"LE PÈRE NOËL EST FATIGUÉ..."~text~lower=       -- T'le père noël est fatigué...'

/*
utf8proc supports only the basic cases (those in UnicodeData.txt).
The cases described in SpecialCasing.txt are not supported by utf8proc.
Examples:
*/
-- # The German es-zed is special--the normal mapping is to SS.
-- # Note: the titlecase should never occur in practice. It is equal to titlecase(uppercase(<es-zed>))
-- # <code>; <lower>; <title>; <upper>; (<condition_list>;)? # <comment>
-- 00DF; 00DF; 0053 0073; 0053 0053; # LATIN SMALL LETTER SHARP S

/*
TODO: full casing not yet implemented
    .Unicode~codepointToLowerFull
    .Unicode~codepointToUpperFull
    .Unicode~codepointToTitleFull
The rest of the framework is ready for full casing.
*/

.unicode~character("LATIN SMALL LETTER SHARP S")~utf8=          -- T'ß'
.unicode~character("LATIN SMALL LETTER SHARP S")~toUpperSimple= -- 7838, which is the codepoint of (U+1E9E Lu "LATIN CAPITAL LETTER SHARP S")
.unicode~character(7838)~utf8=                                  -- T'ẞ'
-- T'ß' to uppercase should be T'SS':
"0053 0053"x~text("utf16")~UnicodeCharacters==

-- # Preserve canonical equivalence for I with dot. Turkic is handled below.
-- 0130; 0069 0307; 0130; 0130; # LATIN CAPITAL LETTER I WITH DOT ABOVE
.unicode~character("LATIN CAPITAL LETTER I WITH DOT ABOVE")~utf8=           -- T'İ'
.unicode~character("LATIN CAPITAL LETTER I WITH DOT ABOVE")~toLowerSimple=  -- 105, which is the codepoint of (U+0069 Ll "LATIN SMALL LETTER I")
.unicode~character(105)~utf8=                                               -- T'i'
-- T'İ' to lowercase should be T'i̇̇':
"0069 0307"x~text("utf16")~UnicodeCharacters==

-- # Turkish and Azeri
-- # I and i-dotless; I-dot and i are case pairs in Turkish and Azeri
-- # The following rules handle those cases.
-- 0130; 0069; 0130; 0130; tr; # LATIN CAPITAL LETTER I WITH DOT ABOVE
-- 0130; 0069; 0130; 0130; az; # LATIN CAPITAL LETTER I WITH DOT ABOVE

-- # Note: the following case is already in the UnicodeData.txt file.
-- # 0131; 0131; 0049; 0049; tr; # LATIN SMALL LETTER DOTLESS I
.unicode~character("LATIN SMALL LETTER DOTLESS I")~utf8=            -- T'ı'
.unicode~character("LATIN SMALL LETTER DOTLESS I")~toUpperSimple=   -- 73, which is the codepoint of (U+0049 Lu "LATIN CAPITAL LETTER I")
.unicode~character(73)~utf8=                                        -- T'I'


-- Which characters have their title character different from their upper character?
.unicode~characters~select{item~toTitleSimple <> item~toUpperSimple}~each{.Unicode[item~toTitleSimple]~utf8 .Unicode[item~ToUpperSimple]~utf8 item~utf8 item}==


-- ===============================================================================
-- 2021 September 22

/*
New native methods:
.Unicode
    codepointBidiMirrored
    codepointDecompositionType


Add character aliases.
.unicode~characters returns now a supplier, instead of the internal array of characters.
The indexes of the characters supplier are the codepoints, not the indexes of the
internal array which are codepoint+2.
*/
.unicode~characters==

/*
Add character intervals.
.UnicodeCharacterInterval
    codepointFrom
    codepointTo
    name
    isExpanded
*/
.unicode~characterIntervals==


-- Informations about Unicode:
-- Remove dataDirectory because the value is different between Windows and Macos/Linux
.Unicode~informations~~remove("dataDirectory")=


-- ===============================================================================
-- 2021 September 13, updated September 22

/*
Add character informations.

The loading of the character names is optional.
By default, they are not loaded.
From ooRexxShell, execute: call loadUnicodeCharacterNames
By default, the character intervals are not expanded.
From ooRexxShell, execute: call expandUnicodeCharacterIntervals

The other character properties are always loaded (provided by utf8proc)

.Unicode
    characters          --> supplier of UnicodeCharacter
    character(index)    --> UnicodeCharacter (index can be a loose matching name (UAX44-LM2) or a codepoint)
    characterIntervals  --> supplier of UnicodeCharacterInterval

.UnicodeCharacter
    codepoint       --> integer -1..1114111
    name            --> string
    aliases         --> array of .UnicodeAlias

    bidiClass       --> enum 1, 2, 3, ...
    bidiClassName   --> enum 'L', 'LRE', 'LRO', ...
    boundClass      --> enum 0, 1, 2, ...
    boundClassName  --> enum 'START', 'OTHER', 'CR', ...
    category        --> enum 0, 1, 2, ...
    categoryName    --> enum 'Cn', 'Lu', 'Ll', ...
    charWidth       --> integer
    combiningClass  --> integer 0..254
    controlBoundary --> boolean
    decompType      --> enum 0, 1, 2, ...
    decompTypeName  --> enum '<none>', '<font>', '<nobreak>, ...
    ignorable       --> boolean

Examples:
*/
-- All the Unicode characters (sparse array).
.unicode~characters==

-- The last 10 characters
.unicode~characters~pipe(.take "last" 10 | .console)

-- get a character by codepoint
.unicode~character(8203)=                   -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("U+200B")=               -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("u+200b")=               -- (U+200B Cf "ZERO WIDTH SPACE")

-- get a character by name.
-- loose matching name. See https://unicode.org/reports/tr44/#UAX44-LM2
.unicode~character("ZERO WIDTH SPACE")=     -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("ZERO_WIDTH-SPACE")=     -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("ZEROWIDTHSPACE")=       -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("zerowidthspace")=       -- (U+200B Cf "ZERO WIDTH SPACE")

-- select characters using a matcher
-- remember: it's better to initialize the matcher outside the iteration.
matcher = "*chris*"~matcher; .unicode~characters~select{expose matcher; matcher~(item~name)}==

-- string character names
"noël👩‍👨‍👩‍👧🎅"~text~codepoints~each{uchar = .unicode~character(item); uchar~charWidth uchar~categoryName uchar~name}==

-- shortest name:
.unicode~characters~reduce{if accu~name~length > item~name~length, item~name~length <> 0 then item }=

-- longest name:
.unicode~characters~reduce{if accu~name~length < item~name~length then item }=


-- ===============================================================================
-- 2021 September 12

/*
[String chunks]

The functionality of splitting text by quoted/unquoted chunks is moved from
ooRexxShell to a dedicated package:
extension/stringChunk.cls               (compatible with official ooRexx)

The initial need was to parse a command line and split it the same way as a cmd
or bash shell. Also used to parse the queries in ooRexxShell.
The quotes are removed, but each character is associated to a 'quote flag' to
remember if the character was inside a quoted section.
These flags are typically used by the matchers of type string pattern, to decide
if a character can be special or not.

Description:
    routine stringChunks
    use strict arg string, withInfos=.false, breakTokens="", splitLevel=1

    Converts a string to an array of String or to an array of stringChunk.
    The type of result is indicated by the argument withInfos:
    - If withInfos == .false (default) then the result is an array of String.
    - If withInfos == .true then the result is an array of StringChunk.

    A StringChunk is a substring which references the start and end character
    in its container. It's associated to a string of booleans (quotedFlags)
    which indicate for each character if it was inside a quoted section.

    A quote is either " or '.

    An unquoted section is splitted in StringChunks delimited by whitespaces
    (anything <= 32) and break tokens.

    A quoted section is not splitted:
    - Whitespaces are kept,
    - single occurences of quotes are removed,
    - double occurrence of quotes are replaced by a single embedded quote,
    - break tokens and escape characters are ignored.

    An escape character is any character passed in the argument escapeCharacters.
    An escape character sets the quote flag of the next character to 1.
    Escape characters are removed, even if they are not followed by another
    character (truncated string).
    Example with 'a' declared escape character:
    - "a" --> ""
    - "aa" --> "a"
    - "aaa" --> "a"
    - "aaaa" --> "aa"

    If a quote is declared escape character, there is no impact: a quote is
    already an escape mechanism.

    If a space is declared escape character, there is an impact when splitLevel=0:
    the quote flag of a character following an unquoted space is set to 1, the
    unquoted spaces are removed
    Example:
        'one two "three four" five six' --> onetwothree fourfivesix
                                            00010011111111111000100

    Break tokens are passed in the argument breakTokens.
    A break token cannot contains spaces.
    The break tokens can be case sensitive (default) or case insensitive.
    Each break token can be prefixed by:
    - cs:  case sensitive
    - ci:  case insensitive
    - cl:  caseless (synonym of case insensitive)
    Any other prefix is not an error. It's just not a case prefix.

    If a quote is declared break token then it's no longer recognized as a quote.
    If an escape character is declared break token then it's no longer recognized
    as an escape character.

    The split process is controlled by the argument splitLevel:
    - If splitLevel == 0 then the string is not splitted but the quotes and
      escape characters are managed, quotedFlags is set.
        'xx aa"b b"cc"d d"ee yy' is 1 StringChunk.
    - If splitLevel == 1 (default) then adjacent quoted/unquoted sections are kept glued.
        'xx aa"b b"cc"d d"ee yy' is 3 StringChunk: xx "aab bccd dee" yy
    - If splitLevel == 2 then adjacent quoted/unquoted sections are separated.
        'xx aa"b b"cc"d d"ee yy' is splitted in 7 StringChunk: xx aa "b b" cc "d d" ee yy

    Illustration with splitLevel=1:
     11111111111111111111111111 222222222222222 333333333333333333333
    '"hello "John" how are you" good" bye "John "my name is ""BOND"""'
     0000000001111111111222222222233333333334444444444555555555566666
     1234567890123456789012345678901234567890123456789012345678901234
    arg1 = |hello John how are you|      containerStart = 01      containerEnd = 26      quotedFlags = 1111110000111111111111
    arg2 = |good bye John|               containerStart = 28      containerEnd = 42      quotedFlags = 0000111110000
    arg3 = |my name is "BOND"|           containerStart = 44      containerEnd = 64      quotedFlags = 11111111111111111

Extensions available in Executor only:
    .String~chunk           withInfos is true, splitLevel is 0 --> always returns ONE StringChunk
    .String~chunks          withInfos is true by default, splitLevel is 1 by default

Examples:
*/
    -- splitLevel = 0: no split
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(splitLevel:0)~each{item~sayDescription(25, index, 2)}
/*
        1  |aab\ bccd\ dee\* ff|       01 23 |aa"b\ b"cc"d\ d"ee\* ff|
        1  |0011110011110000000|
*/

    -- splitLevel = 1: Adjacent quoted/unquoted sections are kept glued
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(splitLevel:1)~each{item~sayDescription(25, index, 2)}
/*
        1  |aab\ bccd\ dee\*|          01 20 |aa"b\ b"cc"d\ d"ee\*|
        1  |0011110011110000|
        2  |ff|                        22 23 |ff|
        2  |00|
*/

    -- splitLevel = 2: Adjacent quoted/unquoted sections are separated
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(splitLevel:2)~each{item~sayDescription(25, index, 2)}
/*
        1  |aa|                        01 02 |aa|
        1  |00|
        2  |b\ b|                      03 08 |"b\ b"|
        2  |1111|
        3  |cc|                        09 10 |cc|
        3  |00|
        4  |d\ d|                      11 16 |"d\ d"|
        4  |1111|
        5  |ee\*|                      17 20 |ee\*|
        5  |0000|
        6  |ff|                        22 23 |ff|
        6  |00|
*/

    -- Default splitLevel (1)
    -- The quote is declared break token, there is no more quoted sections, and the quote itself is returned
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens: '"')~each{item~sayDescription(25, index, 2)}
/*
        1  |aa|                        01 02 |aa|
        1  |00|
        2  |"|                         03 03 |"|
        2  |0|
        3  |b\|                        04 05 |b\|
        3  |00|
        4  |b|                         07 07 |b|
        4  |0|
        5  |"|                         08 08 |"|
        5  |0|
        6  |cc|                        09 10 |cc|
        6  |00|
        7  |"|                         11 11 |"|
        7  |0|
        8  |d\|                        12 13 |d\|
        8  |00|
        9  |d|                         15 15 |d|
        9  |0|
        10 |"|                         16 16 |"|
        10 |0|
        11 |ee\*|                      17 20 |ee\*|
        11 |0000|
        12 |ff|                        22 23 |ff|
        12 |00|
*/

    -- Same as previous, plus \ which is declared escape character
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens: '"', escapeCharacters:"\")~each{item~sayDescription(25, index, 2)}
/*
        1  |aa|                        01 02 |aa|
        1  |00|
        2  |"|                         03 03 |"|
        2  |0|
        3  |b b|                       04 07 |b\ b|
        3  |010|
        4  |"|                         08 08 |"|
        4  |0|
        5  |cc|                        09 10 |cc|
        5  |00|
        6  |"|                         11 11 |"|
        6  |0|
        7  |d d|                       12 15 |d\ d|
        7  |010|
        8  |"|                         16 16 |"|
        8  |0|
        9  |ee*|                       17 20 |ee\*|
        9  |001|
        10 |ff|                        22 23 |ff|
        10 |00|
*/

    -- A break token can be made of several characters, and can contain a quote
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens: ' a"b ')~each{item~sayDescription(25, index, 2)}
/*
        1  |a|                         01 01 |a|
        1  |0|
        2  |a"b|                       02 04 |a"b|
        2  |000|
        3  |\|                         05 05 |\|
        3  |0|
        4  |bccd\|                     07 13 |b"cc"d\|
        4  |01100|
        5  |dee\* ff|                  15 23 |d"ee\* ff|
        5  |01111111|
*/

    -- If an escape character is also declared break token then it's no longer an escape character
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens:"\", escapeCharacters:"\")~each{item~sayDescription(25, index, 2)}==
/*
        1  |aab\ bccd\ dee|            01 18 |aa"b\ b"cc"d\ d"ee|
        1  |00111100111100|
        2  |\|                         19 19 |\|
        2  |0|
        3  |*|                         20 20 |*|
        3  |0|
        4  |ff|                        22 23 |ff|
        4  |00|
*/

    -- A break token can contain characters that are declared escape character
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens:"e\*", escapeCharacters:"\*")~each{item~sayDescription(25, index, 2)}==
/*
        1  |aab\ bccd\ de|             01 17 |aa"b\ b"cc"d\ d"e|
        1  |0011110011110|
        2  |e\*|                       18 20 |e\*|
        2  |000|
        3  |ff|                        22 23 |ff|
        3  |00|
*/

    -- A break token can be case insensitive (prefix ci: or cl:)
    '1Plus2'~chunks(breakTokens:"ci:plus")~each{item~sayDescription(25, index, 2)}
/*
        1  |1|                         1 1 |1|
        1  |0|
        2  |Plus|                      2 5 |Plus|
        2  |0000|
        3  |2|                         6 6 |2|
        3  |0|
*/

/*
[String patterns]

The functionality of selecting text using patterns is moved from ooRexxShell
to a dedicated package:
extension/stringChunkExtended.cls       (not compatible with official ooRexx)

Description
    .StringChunk~matcher
    use strict named arg wholeString(1)=.true, caseless(1)=.true,-
                         trace(1)=.false, displayer(1)=.traceOutput, prefix(1)=""

    Pattern matching by equality (whole) or by inclusion (not whole), caseless or not.

    If the package regex.cls is loaded, then the pattern (a StringChunk) can be
    a regular expression prefixed by "/".

    When whole, and the pattern is not a regular expression, then the charecter
    "*" is recognized as a generic character when first or last character.

    When not whole, and the pattern is not a regular expression, then the character
    "^" is recognized as the metacharacter 'begining of string' when first character.

    When not whole, and the pattern is not a regular expression, then the character
    "$" is recognized as the metacharacter 'end of string' when last character.

    The returned result is a closure (matcher) which implements the pattern matching,
    or .nil if error.

    The pattern matching is tested when the closure is evaluated with a string passed
    as argument.

    Examples:

        '*' or '**'      : matches everything
        '"*"' or '"**"'  : matches exactly "*" or "**", see case stringPattern
        '***'            : matches all names containing "*", see case *stringPattern*
        '*"*"*'          : matches all names containing "*", see case *stringPattern*
        '*"**"*'         : matches all names containing "**", see case *stringPattern*
        '*stringPattern' : string~right(stringPattern~length)~caselessEquals(stringPattern)
        'stringPattern*' : string~left(stringPattern~length)~caselessEquals(stringPattern)
        '*stringPattern*': string~caselessPos(stringPattern) <> 0
        'stringPattern'  : string~caselessEquals(stringPattern)
*/

        -- caseless equality
        matcher = "object"~matcher
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- false

        -- caseless equality with generic character
        matcher = "*object"~matcher
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- true

        -- caseless inclusion
        matcher = "object"~matcher(wholeString:.false)
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- true

        -- caseless inclusion, regular expression: "object" at the begining or at the end.
        matcher = "/^object|object$"~matcher(wholeString:.false)
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- true
        say matcher~("my ObjeCts") -- false

        -- trace
        "*stringPattern"~matcher(trace:.true)
/*
        output:
            description: stringChunkPattern="*stringPattern" wholeString=1 caseless=1
            stringPattern="stringPattern"
            matcher: expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~caselessEquals(stringPattern)
*/

        -- trace when regular expression
        "/.*stringPattern"~matcher(trace:.true)
/*
        output:
            description: stringChunkPattern="/.*stringPattern" wholeString=1 caseless=1
            stringPattern=".*stringPattern"
            pattern = .Pattern~compile(stringPattern, .RegexCompiler~new(.RegexCompiler~caseless))
            matcher: expose description pattern; use strict arg string; return pattern~matches(string)
*/

-- ===============================================================================
-- 2021 August 11

/*
Added support for strings of codepoints encoded as native integers.
3 representations:
    Unicode8_Encoding
    Unicode16_Encoding
    Unicode32_Encoding.
The method ~unicode returns one of these encodings, depending on the character
with the largest Unicode codepoint (1, 2, or 4 bytes) in the source string.
Unlike the flexible representation of Python, the 3 representions are first-class.
No BOM, the endiannes is the CPU one. This is for internal use only.
Unicode32_Encoding can be used with utf8proc for the functions taking a buffer of 32-bit integers.
*/

"côté"~text("unicode8")=    -- T'côté Just an interpretative layer put above the string
"côté"~text("unicode8")~pipe{item~description(short:1) ":" item~c2x}=
--    'Unicode8 not-ASCII : 63 C3 B4 74 C3 A9

"côté"~text~unicode=        -- T'c?t?' UTF-8 converted to Unicode8
"côté"~text~unicode~pipe{item~description(short:1) ":" item~c2x}=
--    'Unicode8 not-ASCII : 63 F4 74 E9

"noël‍👨‍👩‍👧"~text~maximumCodepoint~pipe{"U+"item~d2x}=   -- U+1F469 is the maximum codepoint
"noël‍👨‍👩‍👧"~text~unicode~description(technical:1)=      -- For this maximum codepoint, we need Unicode32
--    'Unicode32 not-ASCII (5 graphemes (1 index from index 5), 10 codepoints (0 index), 40 bytes, 0 error)'

-- The endianness of the UnicodeXX_Encoding is the one of the machine.
-- With an Intel CPU, it's little-endian.
"noël‍👨‍👩‍👧"~text~unicode~c2x=
--    '6E000000 6F000000 EB000000 6C000000 0D200000 68F40100 0D200000 69F40100 0D200000 67F40100'

-- The default endianness for UTF32 is big-endian.
"noël‍👨‍👩‍👧"~text~utf32~c2x=
--    '0000006E 0000006F 000000EB 0000006C 0000200D 0001F468 0000200D 0001F469 0000200D 0001F467'


-- ===============================================================================
-- 2021 may 31

/*
Encodeded strings.
The ooRexx programmer has the choice:
- working with String at byte level
- working with RexxText at grapheme level.
- the same instance of String is used in both cases.

    aString
     ▲  text --------> aRexxText
     │                     indexer (anEncoding)
     │                          codepoints (sequential access)
     │                          graphemes  (direct access)
     +-----------------------<- string
*/

-- First binding of utf8proc, for the detection of grapheme cluster break.
"( ͡° ͜ʖ﻿ ͡°)"~text~description=                    -- 'UTF-8 not-ASCII ( 9 graphemes, 12 codepoints, 20 bytes )'
"( ͡° ͜ʖ﻿ ͡°)"~text~graphemes~each{item~c2x}=       -- [ 28,'20CDA1','C2B0','20CD9C','CA96','EFBBBF','20CDA1','C2B0', 29]

-- Classes in relation with Unicode and encoded strings:
?c *encoding* *encoded* *indexer* *codepoint* *grapheme* *RexxText* *Unicode*

-- ===============================================================================
-- 2021 mar 24

/*
Optimization of String~isASCII:
The old implementation checks from start to end.
The new implementation checks from start ascending, from middle descending, from middle ascending, from end descending.
That will divide by 4 the number of iterations, while increasing the chance to find a not-ascii character faster.
Strangely, the new implementation is also faster when all the characters are ASCII.

Benchmark using a version where the flag isASCII is not stored:
*/
-- MUST declare the byte encoding as default encoding, otherwise "é" is converted to text and the concatenation is catastrophically long!
previousEncoding = .encoding~setDefaultEncoding("byte") -- backup and change to Byte
big10m = "0123456789"~copies(1e6)
s = big10m                              -- 10 millions of ASCII characters, must check all of them
-- do 1000; s~isASCIIold; end              -- 9.3s
do 1000; s~isASCII; end                 -- 6.2s
s = "é" || big10m                       -- 1 non-ASCII character followed by 10 millions of ASCII characters
-- do 1000; s~isASCIIold; end              -- 0.001s
do 1000; s~isASCII; end                 -- 0.001s
s = big10m || "é"                       -- 10 millions of ASCII characters followed by 1 non-ASCII character
-- do 1000; s~isASCIIold; end              -- 9.3s
do 1000; s~isASCII; end                 -- 0.001s
big5m = "01234"~copies(1e6)
s = big5m || "é" || big5m               -- 1 non-ASCII character in the middle of 10 millions of ASCII characters
-- do 1000; s~isASCIIold; end              -- 4.7s
do 1000; s~isASCII; end                 -- 0.001s
.encoding~setDefaultEncoding(previousEncoding) -- restore


-- ===============================================================================
-- 2021 mar 15

/*
Encoded strings (prototype).
Added support for UTF-8.
Added suppliers for codepoints and graphemes.
*/

s = "ça va ?"
s~length=                           -- 7 (was 8 before automatic conversion of string literals to text)
s~eachC{item~c2x" "}=               -- ['C3A7 ', 61 , 20 , 76 , 61 , 20 ,'3F ']     (was ['C3 ','A7 ', 61 , 20 , 76 , 61 , 20 ,'3F '] before automatic conversion of string literals to text)
s~text~encoding=                    -- (The UTF8_Encoding class)
s~text~length=                      -- 7
s~text("utf8")~length==             -- 7
s~text~codepoints~each=             -- [ 231, 97, 32, 118, 97, 32, 63]
s~text~graphemes~each("c2x")=       -- ['C3A7', 61, 20, 76, 61, 20,'3F']
