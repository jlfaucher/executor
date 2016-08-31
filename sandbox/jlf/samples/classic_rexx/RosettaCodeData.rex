/*
Run the Rosetta Code solutions for REXX.
The solutions are installed locally from https://github.com/acmeism/RosettaCodeData
This script has been tested for the git version 18/11/2015.
Some solution have been locally updated with a more recent version from RC, in case of error.

rexx run                -- run all
rexx run 1 3 integer    -- run the solution 1 and 3, and all the solutions whone name contains "integer"
rexx run -1             -- run the last solution
*/

parse arg filter /* optional, let select which solution(s) to run */

path="RosettaCodeData/Lang/REXX/"
separator = copies("=", 80)
count = 0
countOk = 0
countKo = 0
countSkip = 0

countSolutions = 0
pass = 1 /* how many solutions to run */
call runall

pass = 2 /* run the solutions */
call runall

say separator
say "Summary"
say separator
do i=1 to countKo
    say "Ko:" right(i,3) runKo.i
end
say "countKo="countKo
say "countSkip="countSkip
say "countOk="countOk

return

/*----------------------------------------------------------------------------*/
filter: procedure
parse arg filter, count, countSolutions, solution
if filter = "" then return 1
words = filter
do while words <> ""
    parse var words word words
    if datatype(word, "N") then do
        /* solution number */
        if word = count then return 1 /* count from begining */
        if word = count - countSolutions -1 then return 1 /* count from end */
    end
    else if pos(word, solution) <> 0 then return 1
end
return 0

/*----------------------------------------------------------------------------*/
skip: procedure expose count countSkip countSolutions filter pass

if pass = 1 then do
    countSolutions = countSolutions + 1
    return
end
count = count + 1

parse arg solution, args

if \filter(filter, count, countSolutions, solution) then return
countSkip = countSkip + 1
return

/*----------------------------------------------------------------------------*/
run: procedure expose count countKo countOk countSolutions filter path pass runKo. runOk. separator

if pass = 1 then do
    countSolutions = countSolutions + 1
    return
end
count = count + 1

parse arg solution, args

if \filter(filter, count, countSolutions, solution) then return

say separator
say "["count"]" solution
say separator

stdin = ""
if pos("stdin:", args) = 1 then do
    stdin = substr(args, 7)
end

if stdin <> "" then "echo "stdin" | rexx" path || solution
else "rexx" path || solution args

say

if RC = 0 then do
    countOk = countOk + 1
    runOk.countOk = solution
end
else do
    countKo = countKo + 1
    runKo.countKo = solution
end
return

/*----------------------------------------------------------------------------*/
runall:

/* syntax error in git version 18/11/2015
   fixed in version copied from RC on 28/08/2016 */
call run "9-billion-names-of-God-the-integer/9-billion-names-of-god-the-integer.rexx"

/* interactive */
call run "24-game/24-game-1.rexx", "stdin:quit"

call run "24-game-Solve/24-game-solve.rexx", "1111-1129"

call run "99-Bottles-of-Beer/99-bottles-of-beer.rexx"

call run "100-doors/100-doors-1.rexx"

call run "100-doors/100-doors-2.rexx"   /* hard-way */

call run "100-doors/100-doors-3.rexx"   /* easy-way */

call run "100-doors/100-doors-4.rexx"

call run "A+B/a+b-1.rexx", "stdin:10 20"

call run "A+B/a+b-2.rexx", "stdin:10 20"

call run "A+B/a+b-3.rexx", "stdin:10 20"

call run "A+B/a+b-4.rexx", "stdin:10 20 30 40 50"

call run "ABC-Problem/abc-problem-1.rexx"

call run "ABC-Problem/abc-problem-2.rexx"

/* Error 40.23: CENTER argument 3 must be a single character; found "═" */
/* same error with Regina */
call run "Abundant,-deficient-and-perfect-number-classifications/abundant,-deficient-and-perfect-number-classifications-1.rexx"

/* Error 40.23: CENTER argument 3 must be a single character; found "═" */
/* same error with regina */
call run "Abundant,-deficient-and-perfect-number-classifications/abundant,-deficient-and-perfect-number-classifications-2.rexx"

/* not activated : needs 44 sec */
call skip "Abundant,-deficient-and-perfect-number-classifications/abundant,-deficient-and-perfect-number-classifications-3.rexx"

call run "Accumulator-factory/accumulator-factory.rexx"

/* oorexx 64bits: stack overflow */
/* regina: ok */
call run "Ackermann-function/ackermann-function-1.rexx"

call run "Ackermann-function/ackermann-function-2.rexx"

call run "Ackermann-function/ackermann-function-3.rexx"

/* RC=0 but command fails (both oorexx & regina) */
call run "Active-Directory-Search-for-a-user/active-directory-search-for-a-user.rexx"

call run "Address-of-a-variable/address-of-a-variable.rexx"

call run "AKS-test-for-primes/aks-test-for-primes-1.rexx"

call run "AKS-test-for-primes/aks-test-for-primes-2.rexx"

call run "Align-columns/align-columns-1.rexx"

/* oorexx & regina: Error 40.23:  CENTER argument 3 must be a single character; found "═" */
call run "Align-columns/align-columns-2.rexx"

/* oorexx & regina: Error 40.23:  CENTER argument 3 must be a single character; found "═" */
call run "Align-columns/align-columns-3.rexx"

/* oorexx & regina: Error 40.23:  CENTER argument 3 must be a single character; found "═" */
call run "Aliquot-sequence-classifications/aliquot-sequence-classifications.rexx"

call run "Almost-prime/almost-prime-1.rexx"
call run "Almost-prime/almost-prime-2.rexx"
call run "Almost-prime/almost-prime.rexx"

call run "Amb/amb-1.rexx"
call run "Amb/amb-2.rexx"

/* not activated: too long */
call skip "Amicable-pairs/amicable-pairs-1.rexx"

call run "Amicable-pairs/amicable-pairs-2.rexx", 20000
call run "Amicable-pairs/amicable-pairs-3.rexx", 20000
call run "Amicable-pairs/amicable-pairs-4.rexx", 20000
call run "Amicable-pairs/amicable-pairs-5.rexx", 20000

call run "Anagrams/anagrams-1.rexx"
call run "Anagrams/anagrams-2.rexx"
call run "Anagrams/anagrams-3.rexx"

/* upper var */
call run "Anagrams/anagrams-4.rexx"

/* upper var */
call run "Anagrams/anagrams-5.rexx"

call run "Anagrams/anagrams-6.rexx"

return


/*
Error 40.23:  CENTER argument 3 must be a single character; found "═"
Encoding problem.

say "═"~c2x --> E29590
"═" is encoded E2 95 90
For rexx, the string contains 3 characters instead of one.

"E2 95 90"~x2b= 11100010 10010101 10010000
utf8 mask:      1110bbbb 10bbbbbb 10bbbbbb
code point:         0010   010101   010000
                    0010 0101 0101 0000
                       2    5    5    0

Character	═
Character name	BOX DRAWINGS DOUBLE HORIZONTAL
Hex code point	2550
Decimal code point	9552
Hex UTF-8 bytes	E2 95 90

*/