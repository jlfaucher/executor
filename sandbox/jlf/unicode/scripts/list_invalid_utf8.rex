/*
Usage:
rexx list_invalid_utf8.rex > list_invalid_utf8-output.rex
(the output file size is 10.8 MB)


This script lists all the ill-formed UTF-8 byte sequences:
- “non-shortest form” byte sequences (called "overlong encoding" in https://en.wikipedia.org/wiki/UTF-8)
- high/low surrogates (acceptable with WTF-8)

Table 3-7. Well-Formed UTF-8 Byte Sequences
    Code Points         First Byte  Second Byte     Third Byte      Fourth Byte
    U+0000..U+007F      00..7F
    U+0080..U+07FF      C2..DF      80..BF                                  CAREFUL! 1st byte C0 and C1 are invalid (non-shortest form)
    U+0800..U+0FFF      E0          A0..BF          80..BF                  CAREFUL! 2nd byte 80..9F are invalid
    U+1000..U+CFFF      E1..EC      80..BF          80..BF
    U+D000..U+D7FF      ED          80..9F          80..BF                  CAREFUL! 2nd byte A0..BF are invalid (high/low surrogate)
    U+E000..U+FFFF      EE..EF      80..BF          80..BF
    U+10000..U+3FFFF    F0          90..BF          80..BF          80..BF  CAREFUL! 2nd byte 80..8F are invalid (non-shortest form)
    U+40000..U+FFFFF    F1..F3      80..BF          80..BF          80..BF
    U+100000..U+10FFFF  F4          80..8F          80..BF          80..BF  CAREFUL! 2nd byte 90..BF are invalid (codepoint > U+10FFFF)
As a consequence of the well-formedness conditions specified in Table 3-7,
the following byte values are disallowed in UTF-8:
C0–C1, F5–FF.
*/

counter = { n=0; { expose n; use strict named arg add=0; n += add; n } }~()

say "----------"
say "non-shortest form byte sequences: from (C080 ; U+0000 ; 00) to (C1BF ; U+007F ; 7F)"
say "----------"

do b1 = "C0"~x2d to "C1"~x2d
    do b2 = "80"~x2d to "BF"~x2d
        t = (b1~d2c || b2~d2c)~text
        call display t, counter
    end
end


say
say "----------"
say "non-shortest form byte sequences: from (E08080 ; U+0000 ; 00) to (E081BF ; U+007F ; 7F), from (E08280 ; U+0080 ; C280) to (E09FBF ; U+07FF ; DFBF)"
say "----------"

    do b2 = "80"~x2d to "9F"~x2d
        do b3 = "80"~x2d to "BF"~x2d
            t = ("E0"x || b2~d2c || b3~d2c)~text
            call display t, counter
        end
    end


say
say "----------"
say "High/low surrogate U+D800..U+DFFF"
say "----------"

    do b2 = "A0"~x2d to "BF"~x2d
        do b3 = "80"~x2d to "BF"~x2d
            t = ("ED"x || b2~d2c || b3~d2c)~text
            call display t, counter
        end
    end


say
say "----------"
say "non-shortest form byte sequences: from (F0808080 ; U+0000 ; 00) to (F08081BF ; U+007F ; 7F), from (F0808280 ; U+0080 ; C280) to (F0809FBF ; U+07FF ; DFBF), from (F080A080 ; U+0800 ; E0A080) to (F08FBFBF ; U+FFFF ; EFBFBF)"
say "----------"

    do b2 = "80"~x2d to "8F"~x2d
        do b3 = "80"~x2d to "BF"~x2d
            do b4 = "80"~x2d to "BF"~x2d
                t = ("F0"x || b2~d2c || b3~d2c || b4~d2c)~text
                call display t, counter
            end
        end
    end


say
say "----------"
say "codepoint > U+10FFFF - not listed, too many values (184000) and useless to list"
say "----------"

/*
    do b2 = "90"~x2d to "BF"~x2d
        do b3 = "80"~x2d to "BF"~x2d
            do b4 = "80"~x2d to "BF"~x2d
                t = ("F4"x || b2~d2c || b3~d2c || b4~d2c)~text
                call display t, counter
                if t~string == "F4BCBABF"x then leave b2 -- beyond, all the characters are invalid
            end
        end
    end
*/

say
say "----------"
say counter~() "ill-formed UTF-8 byte sequences"
say "----------"


::routine display
    use strict arg text, counter
    size = .UTF8_Encoding~byteSequenceSize(text~string, 1)
    rawCodepoint = .UTF8_Encoding~decode(text~string, 1, size) -- never the replacement character
    shortest = .UTF8_Encoding~encode(rawCodepoint)
    error = ""
    if text~errors <> .nil then error = " ; error:" text~errors~size text~errors[1]
    say text~c2x ";" text~c2u ";" shortest~c2x || error
    counter~(add:1)


::requires "extension/extensions.cls"
