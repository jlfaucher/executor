/*
Usage:
rexx test_replacement_characters.rex > test_replacement_characters-output.txt
*/

counter = 0

/*
Unicode standard
In processing the UTF-8 code unit sequence <F0 80 80 41>, the only formal
requirement mandated by Unicode conformance for a converter is that the <41> be
processed and correctly interpreted as <U+0041>.
The converter could return <U+FFFD, U+0041>, handling <F0 80 80> as a single error,
or <U+FFFD, U+FFFD, U+FFFD, U+0041>, handling each byte of <F0 80 80> as a separate error,
or could take other approaches to signalling <F0 80 80> as an ill-formed code unit subsequence.
*/
call title
call infos "F0 80 80 41"x~text,,
           "U+FFFD U+FFFD U+FFFD U+0041"


/*
Unicode standard
Every byte of a “non-shortest form” sequence (see Definition D92),
or of a truncated version thereof, is replaced (The interpretation of
“non-shortest form” sequences has been forbidden since the publication of
Corrigendum #1.)
*/
call title "Non-Shortest Form Sequences"
call infos "C0 AF E0 80 BF F0 81 82 41"x~text,,
           "U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+0041"


/*
Unicode standard
Every byte of a sequence that would correspond to a surrogate code point,
or of a truncated version thereof, is replaced with one U+FFFD
(The interpretation of such byte sequences has been forbidden since Unicode 3.2.)
*/
call title "Ill-Formed Sequences for Surrogates"
call infos "ED A0 80 ED BF BF ED AF 41"x~text,,
           "U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+0041"


/*
Unicode standard
Every byte of a sequence that would correspond to a code point beyond U+10FFFF,
and any other byte that does not contribute to a valid sequence, is replaced
with one U+FFFD.
*/
call title "Other Ill-Formed Sequences"
call infos "F4 91 92 93 FF 41 80 BF 42"x~text,,
           "U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+0041 U+FFFD U+FFFD U+0042"


/*
Unicode standard
Only when a sequence of two or three bytes is a truncated version of a sequence
which is otherwise well-formed to that point, is more than one byte replaced
with a single U+FFFD.
*/
call title "Truncated Sequences"
call infos "E1 80 E2 F0 91 92 F1 BF 41"x~text,,
           "U+FFFD U+FFFD U+FFFD U+FFFD U+0041"


/*
Unicode standard
Edge cases from Table 3-7. Well-Formed UTF-8 Byte Sequences
*/
call title "All valid except it's out of range ==> all invalid"
call infos "F4 8F BF C0"x~text,,
           "U+FFFD U+FFFD"
call title "80..C1 are not valid start-byte"
call infos "80"x~text,,
           "U+FFFD"
call infos "C1 80"x~text,,
           "U+FFFD U+FFFD"
call title "80..9F are not allowed after E0"
call infos "E0 80"x~text,,
           "U+FFFD U+FFFD"
call infos "E0 9F"x~text,,
           "U+FFFD U+FFFD"


/*
Pair of surrogates in UTF-8
*/
call title "A pair of surrogates in UTF-8"
call infos "EDA080 EDB080"x~text,,
           "U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD"


/*
Pair of surrogates in WTF-8

http://simonsapin.github.io/wtf-8/
If the input contains a surrogate code point pair, the conversion will be
incorrect and the resulting sequence will not represent the original code points.
This situation should be considered an error, but this specification does not
define how to handle it. Possibilities include aborting the conversion, or
replacing one of the surrogate code points of the pair with a replacement character.

JLF:
If following the recommendation of W3C : U+FFFD Substitution of Maximal Subparts
The whole byte-sequence is invalid, must not consume it as a whole.
    ED A0 80 ED B0 80    high surrogate followed by low surrogate is invalid
       A0 80 ED B0 80    invalid start byte A0x
          80 ED B0 80    invalid start byte 80x
             ED B0 80    this is a valid codepoint for WTF-8 (isolated low-surrogate)
which gives:
    U+FFFD U+FFFD U+FFFD U+DC00
When converted to UTF-8, we get:
    U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD
which is identical to what we get when interpreting directly as UTF-8.

We could consider that WTF-8 doesn't need to following the recommendation of W3C,
because its specification says:
    WTF-8 is a hack intended to be used internally in self-contained systems
    with components that need to support potentially ill-formed UTF-16 for
    legacy reasons.
    Any WTF-8 data must be converted to a Unicode encoding at the system’s
    boundary before being emitted. UTF-8 is recommended. WTF-8 must not be used
    to represent text in a file format or for transmission over the Internet.
In this case, these interpretations could be possible:
    EDA080EDB080
    U+FFFD

    EDA080 EDB080
    U+FFFD U+FFFD
In both cases, the conversion to UTF-8 would be different from the direct
interpretation as UTF-8.
*/
call title "A pair of surrogates in WTF-8"
call infos "EDA080 EDB080"x~text("wtf8"),,
           "U+FFFD U+FFFD U+FFFD U+DC00"


/*
UTF32 invalid codepoints
*/
call title "UTF32 invalid codepoints"
call infos ("XXXhXXéXXXlXXXlö"~text("utf32") .utf32BE_encoding~encode("D800"~x2d)),,
           "U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD"

return

title: procedure expose counter
    use strict arg title=""
    counter += 1
    say counter")"
    if title <> "" then say title
    return


infos: procedure
    use strict arg text, expectedReplacements=""
    say text~string
    say "Codepoints:" text~c2x
    say "Executor:  " text~c2u
    if expectedReplacements <> "" then do
        say "Expected:  " expectedReplacements
        say (text~c2u == expectedReplacements)~?("Ok", "*** KO ***")
    end
    if text~errors <> .nil then do e over text~errors; say e; end
    say
    return


::requires "extension/extensions.cls"
