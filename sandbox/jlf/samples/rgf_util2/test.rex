/*
Demonstration of Rony's library as methods instead of routines.
This script iterates over the source lines of the routine "demonstration",
print the current source line and the result of its evaluation.
*/

call evaluate "demonstration"

::routine demonstration
.local

"Print"~abbrev2("Pri")
"PRINT"~abbrev2("Pri", 1)
"Print"~abbrev2("Pri", -1)
"Print"~abbrev2("PRI", , "I")
"PRINT"~abbrev2("Pri", , "C")

"I0II00"~changeStr2("I", "X")
"I0II00"~changeStr2("I", "X", 1)
"I0II00"~changeStr2("I", "X", -1)
"I0II00"~changeStr2("I", "X", -2)
"AB0ABBAAB0AB"~changeStr2("ab", "--", 2)
"AB0ABBAAB0AB"~changeStr2("AB", "--", 2)
"AB0ABBAAB0AB"~changeStr2("AB", "--", -2)
"I0II00"~changeStr2("i", "X", , "C")
"I0II00"~changeStr2("i", "X", 1, "I")

"abc"~compare2("abc")
"abc"~compare2("ABC")
"abc"~compare2("ak")
"Ab-- "~compare2("aB", "-", "I")
"Ab-- "~compare2("aB", "-", "C")
"Ab-- "~compare2("Ab", "-", "C")

"101101"~countStr2("1")
"J0KKK0"~countStr2("KK")
"J0KKKK0"~countStr2("KK")
"J0kkk0"~countStr2("KK")
"J0KKK0"~countStr2("KK", "I")
"J0KKKK0"~countStr2("kk","I")
"J0kkk0"~countStr2("KK", "I")
"J0kkk0"~countStr2("KK", "C")

"abcd"~delStr2(3)
"abcde"~delStr2(3, 2)
"abcde"~delStr2(6)
"abcd"~delStr2(-3)
"abcde"~delStr2(-3, -2)
"abc"~delStr2(1)
"abc"~delStr2(-1)
"abc"~delStr2(3)
"abc"~delStr2(-3)

" eins zwei drei "~delWord2(-1)
" eins zwei drei "~delWord2( 2)
" eins zwei drei "~delWord2( 2, 1)
" eins zwei drei "~delWord2( 2,-2)
" eins zwei drei "~delWord2(-2)
" eins zwei drei "~delWord2(-2, 1)
" eins zwei drei "~delWord2(-2,-1)
" eins zwei drei "~delWord2(-2,-2)
" eins zwei drei "~delWord2(-2, 2)

"abc def ghi"~lastPos2(" ")
"abc def ghi"~lastPos2(" ", 8)
"abc def ghi"~lastPos2(" ", -1)
"abc def ghi"~lastPos2(" ", -8)
"efGXYZXYXY"~lastPos2("xY", 9)
-- maxArgs=4, should be 5 ?
"efGXYZXYXY"~lastPos2("xY", 9, "I")
"efGXYZXYXY"~lastPos2("xY", 9, "C")

"abc d"~left2(8 )
"abc d"~left2(-8 )
"abc d"~left2(8, ".")
"abc d"~left2(-8, ".")

"ABCDEF"~lower2(4)
"ABCDEF"~lower2(-4)
"ABCDEF"~lower2(3, 2)
"ABCDEF"~lower2(-3, -2)

"abc"~overlay2("12", 2)
"abc"~overlay2("12", 2, 1)
"abc"~overlay2("12", 2, 2)
"abc"~overlay2("12", 2, 3)
"abc"~overlay2("12", 2, 4)
"abc"~overlay2("12", 2, -1)
"abc"~overlay2("12", 2, -2)
"abc"~overlay2("12", 2, -3)
"abc"~overlay2("12", 2, -4)
"abc"~overlay2("12", 2, -3, ".")
"abc"~overlay2("12", 2, -4, ".")
"abc"~overlay2("12", -4, -1)
"abc"~overlay2("12", -4, -2)
"abc"~overlay2("12", -4, -3)
"abc"~overlay2("12", -4, -4)
"abc"~overlay2("12", -4, -5)

"this: is-it, isn't it?"~parseWords2(": -?,")
"Ol' McDonald's farm: so huge!"~parseWords2(.rgf.alpha || "'", "Word")[3]
"Ol' McDonald's farm: so huge!"~parseWords2(.rgf.alpha || "'", "Word", "Position")
"Immer Ärger mit übergroßen Öffis!"~parseWords2(.rgf.alpha || "ÄäÖöÜüß", "W")
"Immer Ärger mit übergroßen Öffis!"~parseWords2(.rgf.alpha || "ÄäÖöÜüß", "W", "P")

"Saturday"~pos2("day")
"Saturday"~pos2("Day")
 -- maxArgs=4, should be 5 ?
"Saturday"~pos2("Day", , "I")
"Saturday"~pos2("Day", , "C")

"abc d"~right2(8)
"abc d"~right2(-8)
"abc d"~right2(8, ".")
"abc d"~right2(-8, ".")
12~right2(5, "0")
12~right2(-5, "0")

"abc"~subChar2(3)
"abc"~subChar2(-3)
"abc"~subChar2(4)
"abc"~subChar2(-4)

'ab'~subStr2(-1, -3, ".")
"abc"~subStr2(-2)
"abc"~subStr2(-2, -4 )
"abc"~subStr2(-2, -6, ".")
"abc"~subStr2(-4)
"abc"~subStr2(-4, , ".")
"abc"~subStr2(-4, 1, ".")
"abc"~subStr2(-4, -1, ".")

" eins zwei drei "~subWord2(2)
" eins zwei drei "~subWord2(3)
" eins zwei drei "~subWord2(2, 1)
" eins zwei drei "~subWord2(2, 2)
" eins zwei drei "~subWord2(2)
" eins zwei drei "~subWord2(3)
" eins zwei drei "~subWord2(2,-1)
" eins zwei drei "~subWord2(2, 1)
" eins zwei drei "~subWord2(2,-2)
" eins zwei drei "~subWord2(2,-2)
" eins zwei drei "~subWord2(2, 2)

"abcdef"~upper2(3, 2)
"abcdef"~upper2(-3, -2)
"abcdef"~upper2(4)
"abcdef"~upper2(-4)

" eins zwei drei "~word2(-2)
" eins zwei drei "~word2(3)
" eins zwei drei "~word2(-3)

" eins zwei drei "~wordIndex2( 2)
" eins zwei drei "~wordIndex2(-2)
" eins zwei drei "~wordIndex2( 3)
" eins zwei drei "~wordIndex2(-3)

" eins zwei three"~wordLength2( 1)
" eins zwei three"~wordLength2(-1)

" eins zwei drei "~wordPos2("EINS")
" EINS zwei drei "~wordPos2("eins")
" eins zwei drei "~wordPos2("EINS", , "C")
" EINS zwei drei "~wordPos2("eins", , "C")
" eins zwei drei "~wordPos2("EINS", , "I")
" EINS zwei drei "~wordPos2("eins", , "I")
" eins zwei drei "~wordPos2(" eins ", -1)
" eins zwei drei "~wordPos2(" eins ", -4)

::routine evaluate
    use strict arg routineName
    routine = .context~package~findRoutine(routineName)
    routineSource = routine~source
    do sourceline over routineSource
        if sourceline~strip~left(2) == "--" then iterate
        if sourceline~strip == "" then say
        else do
            call charout , sourceline" = "
            interpret "r="sourceline" ; say r~ppIndex2 ; if r~isA(.Collection) then r~dump2"
        end
    end
    
::requires "rgf_util2/rgf_util2_wrappers.rex"

