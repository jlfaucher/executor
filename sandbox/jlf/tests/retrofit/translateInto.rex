say "*********************************"
say "* Test case - inString outArray *"
say "*********************************"
say

say "(some strings contain control characters, displayed in hexadecimal between [])"
say

inString = ""
outArray = .array~new

-- A character can be translated to a sequence of characters
inString ||= "abcd"
outArray~append("aA")
outArray~append("bBb")
outArray~append("cCcC")
outArray~append("dDdDd")

-- Translate an \ escape sequence using a routine
-- The routine will tell how many characters have been matched, if applicable
inString ||= "\"
outArray~append(.routines~maybe_translate_backslash_u_4_hexdigits)

-- JavaScript escape sequence
-- If the translation of an \ escape sequence by the maybe_translate_backslash_u_4_hexdigits
-- routine is not applicable then the default translation will be applied.
inString ||= "08090A0C0D"x || '"\/'
outArray~append('\b')
outArray~append('\t')
outArray~append('\n')
outArray~append('\f')
outArray~append('\r')
outArray~append('\"')
outArray~append('\\')   -- default translation of "\"
outArray~append('\/')

-- convert the control characters to \00xx
-- here, no routine because inString is not an array. See next test case.
inString ||= .string~cntrl
do c over .string~cntrl~makeArray("")
    outArray~append("\u00" || c~c2x)
end

say " "~right(6) || "    " || "inString"~left(10) || "    " || "outArray"
do i=1 to inString~length
    call charout , i~right(6)
    call charout , "    "
    call charout , q(inString~subchar(i))~left(10)
    call charout , "    "
    call charout , q(outArray[i])~left(15)
    if outArray[i]~isa(.Routine) then call charout , .routines~index(outArray[i])
    say
end
say

string = "ab\u123456" || "000D0A"x || "0 \uNOT_HEX cdef"
say "string =     " q(string)
say "translation =" q(string~translateInto(.mutableBuffer~new, outArray, inString))


say
say "*********************************"
say "* Test case - inArray outString *"
say "*********************************"
say

say "(some strings contain control characters, displayed in hexadecimal between [])"
say

inArray = "00"x,-
          "07"x,-
          .routines~match_cntrl,-
          "James",-
          "Bond"

outString = "07*JB"

say " "~right(6) || "    " || "inArray"~left(15) || "    " || "outString"
do i=1 to inArray~items
    call charout , i~right(6)
    call charout , "    "
    call charout , q(inArray[i])~left(15)
    call charout , "    "
    call charout , q(outString~subchar(i))~left(10)
    if inArray[i]~isa(.Routine) then call charout , .routines~index(inArray[i])
    say
end
say

string = "My name is Bond, James Bond! My public ID is " || "000007"x || ". My secret ID is " || "01000500020807"x || "."
say "string =     " q(string)
say "translation =" q(string~translateInto(.mutableBuffer~new, outString, inArray))


say
say "********************************"
say "* Test case - inArray outArray *"
say "********************************"
say

say "(some strings contain control characters, displayed in hexadecimal between [])"
say

inArray = "00"x,-
          "07"x,-
          .routines~match_cntrl,-
          "<script>",-
          "<LOL>"

outArray = "0️⃣",-
           "7️⃣",-
           .routines~translate_cntrl,-
           .routines~translate_to_script_font,-     -- up to </script>
           "😂"

say " "~right(6) || "    " || "inArray"~left(15) || "    " || "outArray"
do i=1 to inArray~items
    call charout , i~right(6)
    call charout , "    "
    call charout , q(inArray[i])~left(15)
    call charout , "    "
    call charout , q(outArray[i])~left(15)
    if inArray[i]~isa(.Routine) then call charout , .routines~index(inArray[i])~left(15)
    if outArray[i]~isa(.Routine) then call charout , .routines~index(outArray[i])
    say
end
say

string = "My name is <script>Bond, James Bond</script> <LOL>! My public ID is " || "000007"x || ". My secret ID is " || "01000500020807"x || "."
say "string =     " q(string)
say "translation =" q(string~translateInto(.mutableBuffer~new, outArray, inArray))


say
say "*************************"
say "* Test case - no tables *"
say "*************************"
say

say "The 'end' variable is passed by reference."
say

string = "No tables, no pad: uppercase."
say "string =     " q(string)
--say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, /*startPos*/, /*length*/, >end))
say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, /*startPos*/, /*length*/))
say "end =" end
say

string = "No tables, no pad, startPos=4, length=6: uppercase."
say "string =     " q(string)
--say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, 4, 6, >end))
say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, 4, 6))
say "end =" end
say

string = "No tables, no pad, startPos=20, length=100: uppercase."
say "string =     " q(string)
--say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, 20, 100, >end))
say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, 20, 100))
say "end =" end
say

string = "startPos=100"
say "string =     " q(string)
--say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, 100, , >end))
say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, 100))
say "end =" end
say

string = "startPos=10, length=0"
say "string =     " q(string)
--say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, 10, 0, >end))
say "translation =" q(string~translateInto(.mutableBuffer~new, /*tableo*/, /*tablei*/, /*pad*/, 10, 0))
say "end =" end

say
say "********************************"
say "* Test case - stop translation *"
say "********************************"
say

say "(some strings contain control characters, displayed in hexadecimal between [])"
say

inArray = '\"',-
          '\\',-
          '\/',-
          '\b',-
          '\f',-
          '\n',-
          '\r',-
          '\t',-
          '\u00',-
          '\u',-
          '"'

outArray = '"',-
           '\',-
           '/',-
           '08'x,-
           '0C'x,-
           '0A'x,-
           '0D'x,-
           '09'x,-
           .routines~translate_backslash_u00_2_hexdigits,-
           .routines~translate_backslash_u_4_hexdigits,-
           .nil /* .nil or omitted item means stop */

say " "~right(6) || "    " || "inArray"~left(15) || "    " || "outArray"
do i=1 to inArray~items
    call charout , i~right(6)
    call charout , "    "
    call charout , q(inArray[i])~left(15)
    call charout , "    "
    call charout , q(outArray[i])~left(15)
    if inArray[i]~isa(.Routine) then call charout , .routines~index(inArray[i])~left(15)
    if outArray[i]~isa(.Routine) then call charout , .routines~index(outArray[i])
    say
end
say

say "Translate a JSON string, starting at position 15."
say "The next unescaped double quote will stop the translation."
say "Its position will be collected with the 'end' variable passed by reference."
say

string = '[ { "key1" : "My name is \"Bond\", \"James Bond\".\r\nMy ID is \"007\"." }]'
cols =   '123456789012345........................................................^'
say "string =     " q(string)
say "              " cols
--say "translation =" q(string~translateInto(.mutableBuffer~new, outArray, inArray, /*pad*/, 15, /*length*/, >end))
say "translation =" q(string~translateInto(.mutableBuffer~new, outArray, inArray, /*pad*/, 15, /*length*/))
say "end =" end


say
say "********************************************"
say "* Non-regression test - inString outString *"
say "********************************************"
say

call execute .routines~inString_outString~source, 70, 10
say


say
say "*******************************************"
say "* Non-regression test - inString outArray *"
say "*******************************************"
say

call execute .routines~inString_outArray~source, 85, 10
say


say
say "*******************************************"
say "* Non-regression test - inArray outString *"
say "*******************************************"
say

call execute .routines~inArray_outString~source, 85, 10
say


say
say "******************************************"
say "* Non-regression test - inArray outArray *"
say "******************************************"
say

call execute .routines~inArray_outArray~source, 90, 10
say


/*******************************************************************************
Routines used by translateInto
*******************************************************************************/

::routine maybe_translate_backslash_u_4_hexdigits
    use strict arg buffer, string, pad=" ", pos, matchLength
    -- "\uXXXX" where "\" is already matched
    if string~match(pos + 1, "u"), string~verify("0123456789ABCDEFabcdef", "NOMATCH", pos + 2, 4) == 0 then do
        escapeSequence = string[pos, 6]
        if escapeSequence~length == 6 then do
            buffer~append(escapeSequence) -- keep as-is
            return 6 -- advance by 6 characters
        end
    end
    -- not applicable
    return 0


::routine translate_backslash_u00_2_hexdigits
    use strict arg buffer, string, pad=" ", pos, matchLength
    -- "\u00XX" where "\u00" is already matched
    if string~verify("0123456789ABCDEFabcdef", "NOMATCH", pos + 4, 2) == 0 then do
        hex = string[pos + 4, 2]
        if hex~length == 2 then do
            buffer~append(hex~x2c)
            return 6 -- advance by 6 characters
        end
    end
    raise user parseError array("Invalid escape sequence")


::routine translate_backslash_u_4_hexdigits
    use strict arg buffer, string, pad=" ", pos, matchLength
    -- "\uXXXX" where "\u" is already matched
    if string~verify("0123456789ABCDEFabcdef", "NOMATCH", pos + 2, 4) == 0 then do
        escapeSequence = string[pos, 6]
        if escapeSequence~length == 6 then do
            buffer~append(escapeSequence) -- keep as-is
            return 6 -- advance by 6 characters
        end
    end
    raise user parseError array("Invalid escape sequence")


::routine match_cntrl
    use strict arg string, pos
    -- The returned value is not a boolean, it's a number of matched characters:
    -- 0 if no match
    -- 1 if match
    return .string~cntrl~contains(string~subchar(pos))


::routine translate_cntrl
    use strict arg buffer, string, pad=" ", pos, matchLength
    byte = string~subchar(pos)
    buffer~append("\u00")
    buffer~append(byte~c2x)
    return 1 -- advance by 1 character


::routine translate_to_script_font
    use strict arg buffer, string, pad=" ", pos, matchLength
    parse value string with "<script>" text "</script>" .
    alpha_sb = "𝓐","𝓑","𝓒","𝓓","𝓔","𝓕","𝓖","𝓗","𝓘","𝓙","𝓚","𝓛","𝓜","𝓝","𝓞","𝓟","𝓠","𝓡","𝓢","𝓣","𝓤","𝓥","𝓦","𝓧","𝓨","𝓩",-
               "𝓪","𝓫","𝓬","𝓭","𝓮","𝓯","𝓰","𝓱","𝓲","𝓳","𝓴","𝓵","𝓶","𝓷","𝓸","𝓹","𝓺","𝓻","𝓼","𝓽","𝓾","𝓿","𝔀","𝔁","𝔂","𝔃"
    text_sb = text~translateInto(buffer, alpha_sb, .string~alpha)
    return "<script>"~length + text~length + "</script>"~length


/*******************************************************************************
Non-regression testing
*******************************************************************************/

-- Executes an array of expressions and checks the expected results
::routine execute
    use strict arg tests, width1, width2
    header = " "~right(2) || "    " || " "~left(width1) || "Expected"~left(width2) || "Result"~left(width2) || "Status"
    i = 1
    do test over tests
        -- Known problem: the comments at the begining of the source are discarded.
        -- By using "nop --", I keep the comment.
        isComment = test~strip~startsWith("--") | test~strip~startsWith("nop --")
        if i == 1 then do
            if isComment then say test
            say header
        end
        if \isComment then do
            parse value test with expression "-->" expected
            interpret "value =" expression
            interpret "expected =" expected
            status = (value~string == expected)~?("ok", "KO")
            say i~right(2) || "    " || expression~left(width1) || q(expected)~left(width2) || q(value)~left(width2) || status
        end
        i += 1
    end


::routine inString_outString
nop -- The RexxRef examples for translate.
"abcdef"~translateInto(.mutableBuffer~new)                        --> "ABCDEF"
"abcdef"~translateInto(.mutableBuffer~new, "")                    --> "      "
"abcdef"~translateInto(.mutableBuffer~new, , "")                  --> "abcdef"
"abcdef"~translateInto(.mutableBuffer~new, , , , 3, 2)            --> "abCDef"
"abcdef"~translateInto(.mutableBuffer~new, "", , , 3, 2)          --> "ab  ef"
"abcdef"~translateInto(.mutableBuffer~new, , "", , 3, 2)          --> "abcdef"
"abcdef"~translateInto(.mutableBuffer~new, "12", "ec")            --> "ab2d1f"
"abcdef"~translateInto(.mutableBuffer~new, "12", "abcd", ".")     --> "12..ef"
"APQRV"~translateInto(.mutableBuffer~new, , "PR")                 --> "A Q V"
"APQRV"~translateInto(.mutableBuffer~new, "", "PR")               --> "A Q V"
"APQRV"~translateInto(.mutableBuffer~new, XRANGE("00"X, "Q"))     --> "APQ  "
"APQRV"~translateInto(.mutableBuffer~new, XRANGE("00"X, "Q"), "") --> "APQRV"
"4123"~translateInto(.mutableBuffer~new, "abcd", "1234", , 2, 2)  --> "4ab3"
"4123"~translateInto(.mutableBuffer~new, "abcd", "1234")          --> "dabc"


::routine inString_outArray
nop -- The RexxRef examples for translate, where tableo is an array.
"abcdef"~translateInto(.mutableBuffer~new, v())                                   --> "      "
"abcdef"~translateInto(.mutableBuffer~new, v(), , , 3, 2)                         --> "ab  ef"
"abcdef"~translateInto(.mutableBuffer~new, v("1","2"), "ec")                      --> "ab2d1f"
"abcdef"~translateInto(.mutableBuffer~new, v("1","2"), "abcd", ".")               --> "12..ef"
"APQRV"~translateInto(.mutableBuffer~new, v(), "PR")                              --> "A Q V"
"APQRV"~translateInto(.mutableBuffer~new, XRANGE("00"X, "Q")~makeArray(""))       --> "APQ  "
"APQRV"~translateInto(.mutableBuffer~new, XRANGE("00"X, "Q")~makeArray(""), "")   --> "APQRV"
"4123"~translateInto(.mutableBuffer~new, v("a","b","c","d"), "1234", , 2, 2)      --> "4ab3"
"4123"~translateInto(.mutableBuffer~new, v("a","b","c","d"), "1234")              --> "dabc"


::routine inArray_outString
nop -- The RexxRef examples for translate, where tablei is an array.
"abcdef"~translateInto(.mutableBuffer~new, , v())                             --> "abcdef"
"abcdef"~translateInto(.mutableBuffer~new, , v(), , 3, 2)                     --> "abcdef"
"abcdef"~translateInto(.mutableBuffer~new, "12", v("e","c"))                  --> "ab2d1f"
"abcdef"~translateInto(.mutableBuffer~new, "12", v("a","b","c","d"), ".")     --> "12..ef"
"APQRV"~translateInto(.mutableBuffer~new, , v("P","R"))                       --> "A Q V"
"APQRV"~translateInto(.mutableBuffer~new, "", v("P","R"))                     --> "A Q V"
"APQRV"~translateInto(.mutableBuffer~new, XRANGE("00"X, "Q"), v())            --> "APQRV"
"4123"~translateInto(.mutableBuffer~new, "abcd", v("1","2","3","4"), , 2, 2)  --> "4ab3"
"4123"~translateInto(.mutableBuffer~new, "abcd", v("1","2","3","4"))          --> "dabc"


::routine inArray_outArray
nop -- The RexxRef examples for translate, where tablei and tableo are arrays.
"abcdef"~translateInto(.mutableBuffer~new, v("1","2"), v("e","c"))                        --> "ab2d1f"
"abcdef"~translateInto(.mutableBuffer~new, v("1","2"), v("a","b","c","d"), ".")           --> "12..ef"
"APQRV"~translateInto(.mutableBuffer~new, v(), v("P","R"))                                --> "A Q V"
"APQRV"~translateInto(.mutableBuffer~new, XRANGE("00"X, "Q")~makeArray(""), v())          --> "APQRV"
"4123"~translateInto(.mutableBuffer~new, v("a","b","c","d"), v("1","2","3","4"), , 2, 2)  --> "4ab3"
"4123"~translateInto(.mutableBuffer~new, v("a","b","c","d"), v("1","2","3","4"))          --> "dabc"


/*******************************************************************************
Helpers
*******************************************************************************/

-- Copied from rgf_util2 and adapted.
-- Escape non-printable chars by printing them between square brackets [].
::routine escape3 public
  parse arg a1

  --non_printable=xrange("00"x,"1F"x)||"FF"x
  non_printable="00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 7F FF"x
  res=""

  do while a1\==""
     pos1=verify(a1, non_printable, "M")
     if pos1>0 then
     do
        pos2=verify(a1, non_printable, "N" , pos1)

        if pos2=0 then
           pos2=length(a1)+1

        if pos1=1 then
        do
           parse var a1 char +(pos2-pos1) a1
           bef=""
        end
        else
           parse var a1 bef +(pos1-1) char +(pos2-pos1) a1

        if res=="" then
        do
           if bef \=="" then res=bef -- res=enquote2(bef) '|| '
        end
        else
        do
           res=res||bef -- res=res '||' enquote2(bef) '|| '
        end

        res=res || '['char~c2x']'
     end
     else
     do
        if res<>""  then
           res=res||a1 -- res=res '||' enquote2(a1)
        else
           res=a1

        a1=""
     end
  end
  return res


-- Quoted string
::routine quoted
    use strict arg string, quote='"', double=.true
    if double then return quote || string~changeStr(quote, quote||quote) || quote
    return quote || string || quote


-- Quoted escaped string
::routine q
    use strict arg object
    if object~isa(.String) then return quoted(escape3(object), , /*doubled*/.false)
    if object~isa(.MutableBuffer) then return quoted(escape3(object~string), , /*doubled*/.false)
    return object~string


-- v for vector (a single-dimensional array)
-- (1) is not an array.
-- v(1) is an array.
-- What's our vector, Victor?
-- https://www.youtube.com/watch?v=NfDUkR3DOFw
::routine v public
    return arg(1, "a")
