/*
Run the Rosetta Code solutions for REXX.
The solutions are installed locally from https://github.com/acmeism/RosettaCodeData
This script has been written for the commit of Dec 05 2016.

rexx runRosettaCode                 -- run all
rexx runRosettaCode 1 3 integer     -- run the solution 1 and 3, and all the solutions whone name contains "integer"
rexx runRosettaCode -1              -- run the last solution

KEEP THIS SCRIPT COMPATIBLE WITH REGINA
*/

path="RosettaCodeData/Lang/REXX/"
/*
From the directory REXX, find all the scripts;
find -L . -type f
*/

parse version version
say "Your REXX interpreter is" version

parse var version "REXX-"ipret"_".
isRegina = (ipret == "Regina")
isooRexx = (ipret == "ooRexx")

parse source system .
system = upper(system)
/* Problem with Regina :
   Under MacOS, system=="UNIX", not "MACOSX" or "DARWIN"
   Under Ubuntu, system=="UNIX", not "LINUX"*/
if system == "UNIX" then do
   "test `uname -s` = 'Darwin'"
   if RC = 0 then system = "MACOS"
   else do
       "test `uname -s` = 'Linux'"
       if RC = 0 then system = "LINUX"
   end
end
say "Your system is" system
isWindows = (left(system, 3) == "WIN")
isLinux = (system == "LINUX")
isMacOS = (left(system, 5) == "MACOS")

if isWindows
then do
    display = "type"
    delete = "del /q"
end
else do
    display = "cat"
    delete = "rm -f"
end

parse arg filter /* optional, let select which solution(s) to run */

separator = copies("=", 80)
runOk.0 = 0
runKo.0 = 0
runSkip.0 = 0

countSolutions = 0
pass = 1 /* how many solutions to run */
call runall

indexSolution = 0 /* current solution number during pass 2, used to filter */
pass = 2 /* run the solutions */
call time("reset")
call runall
duration = time("elapsed")

say
say separator
say "Summary Ok"
say separator

do i=1 to runOk.0
    say "Ok:" runOk.i
end

say
say separator
say "Summary Skip"
say separator

do i=1 to runSkip.0
    say "Skip:" runSkip.i
end

say
say separator
say "Summary Ko"
say separator

do i=1 to runKo.0
    say "Ko:" runKo.i
end

say
say separator
say "Summary counters"
say separator

say "Ok="runOk.0
say "Skip="runSkip.0
say "Ko="runKo.0
say "duration="duration
say

return

/*----------------------------------------------------------------------------*/
filter: procedure
parse arg filter, indexSolution, countSolutions, solution
if filter = "" then return 1
words = filter
do while words <> ""
    parse var words word words
    if datatype(word, "N") then do
        /* solution number */
        if word = indexSolution then return 1 /* count from begining */
        if word = indexSolution - countSolutions -1 then return 1 /* count from end */
    end
    else if pos(word, solution) <> 0 then return 1
end
return 0

/*----------------------------------------------------------------------------*/
skip:

if pass = 1 then do
    countSolutions += 1
    return
end
indexSolution += 1

parse arg solution, args

if \filter(filter, indexSolution, countSolutions, solution) then return
runSkip.0 += 1
index = runSkip.0
runSkip.index = right(indexSolution, 4) ";" 0 ";" 0 ";" solution
return

/*----------------------------------------------------------------------------*/
run:

if pass = 1 then do
    countSolutions += 1
    return
end
indexSolution += 1

parse arg solution, args

if \filter(filter, indexSolution, countSolutions, solution) then return

say separator
say "["indexSolution"]" solution
say separator

if args == "stdin" then do
    file = "solution_input.txt"
    call stream file, "c", "open write replace"
    do i=3 to arg()
        call lineout file, arg(i)
    end
    call stream file, "c", "close"

    call time("reset")
    display file "|" "rexx" path || solution
    solution_RC = RC
    duration = time("elapsed")
    delete file
end
else do
    call time("reset")
    "rexx" path || solution args
    solution_RC = RC
    duration = time("elapsed")
end


say
say "RC="solution_RC
say "duration="duration
say

if solution_RC = 0 then do
    runOk.0 += 1
    index = runOk.0
    runOk.index = right(indexSolution, 4) ";" duration ";" solution_RC ";" solution
end
else do
    runKo.0 += 1
    index = runKo.0
    runKo.index = right(indexSolution, 4) ";" duration ";" solution_RC ";" solution
end
return

/*----------------------------------------------------------------------------*/
runall:

call run "9-billion-names-of-God-the-integer/9-billion-names-of-god-the-integer.rexx"

/* interactive */
call run "24-game/24-game-1.rexx", "stdin", "quit"

/* 24-game-2.rexx: just a routine, nothing to execute */
/* 24-game-3.rexx: same as 2 */

call run "24-game-Solve/24-game-solve.rexx", "1111-1129"

call run "99-Bottles-of-Beer/99-bottles-of-beer.rexx"

call run "100-doors/100-doors-1.rexx"

call run "100-doors/100-doors-2.rexx"   /* hard-way */

call run "100-doors/100-doors-3.rexx"   /* easy-way */

call run "100-doors/100-doors-4.rexx"

call run "A+B/a+b-1.rexx", "stdin", "10 20"

call run "A+B/a+b-2.rexx", "stdin", "10 20"

call run "A+B/a+b-3.rexx", "stdin", "10 20"

call run "A+B/a+b-4.rexx", "stdin", "10 20 30 40 50"

call run "ABC-Problem/abc-problem-1.rexx"

call run "ABC-Problem/abc-problem-2.rexx"

/* [KO] Error 40.23: CENTER argument 3 must be a single character; found "═" */
/* same error with Regina */
call run "Abundant,-deficient-and-perfect-number-classifications/abundant,-deficient-and-perfect-number-classifications-1.rexx"

/* [KO] Error 40.23: CENTER argument 3 must be a single character; found "═" */
/* same error with regina */
call run "Abundant,-deficient-and-perfect-number-classifications/abundant,-deficient-and-perfect-number-classifications-2.rexx"

/* not activated : needs 44 sec */
call skip "Abundant,-deficient-and-perfect-number-classifications/abundant,-deficient-and-perfect-number-classifications-3.rexx"

call run "Accumulator-factory/accumulator-factory.rexx"

/* [KO] executor 64bits: stack overflow */
/* oorexx-4.2 64bits (after replacing variable #) : stack overflow */
/* oorexx-5 (after replacing variable #) : ok */
/* regina: ok */
call run "Ackermann-function/ackermann-function-1.rexx"

call run "Ackermann-function/ackermann-function-2.rexx"

call run "Ackermann-function/ackermann-function-3.rexx"

/* RC=0 but command fails (both oorexx & regina) */
call run "Active-Directory-Search-for-a-user/active-directory-search-for-a-user.rexx"

/* Could not find routine "STORAGE" */
call skip "Address-of-a-variable/address-of-a-variable.rexx"

call run "AKS-test-for-primes/aks-test-for-primes-1.rexx"

call run "AKS-test-for-primes/aks-test-for-primes-2.rexx"

call run "Align-columns/align-columns-1.rexx"

/* [KO] oorexx & regina: Error 40.23:  CENTER argument 3 must be a single character; found "═" */
call run "Align-columns/align-columns-2.rexx"

/* [KO] oorexx & regina: Error 40.23:  CENTER argument 3 must be a single character; found "═" */
call run "Align-columns/align-columns-3.rexx"

/* [KO] oorexx & regina: Error 40.23:  CENTER argument 3 must be a single character; found "═" */
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

call run "Anagrams-Deranged-anagrams/anagrams-deranged-anagrams.rexx"

call run "Anonymous-recursion/anonymous-recursion-1.rexx"
call run "Anonymous-recursion/anonymous-recursion-2.rexx"

call run "Append-a-record-to-the-end-of-a-text-file/append-a-record-to-the-end-of-a-text-file.rexx"

call run "Apply-a-callback-to-an-array/apply-a-callback-to-an-array.rexx"

/* not activated: too long */
call skip "Arbitrary-precision-integers--included-/arbitrary-precision-integers--included--1.rexx"

/* not activated: too long */
call skip "Arbitrary-precision-integers--included-/arbitrary-precision-integers--included--2.rexx"

call run "Arena-storage-pool/arena-storage-pool.rexx"

call run "Arithmetic-Complex/arithmetic-complex.rexx"

/* Remember : don't pass an expression whose result is a wholenumber
   If the result is wholenumber then it's returned and taken as an error code. */
call run "Arithmetic-evaluation/arithmetic-evaluation.rexx", "1/3"

call run "Arithmetic-geometric-mean/arithmetic-geometric-mean.rexx"

call run "Arithmetic-geometric-mean-Calculate-Pi/arithmetic-geometric-mean-calculate-pi-1.rexx"
call run "Arithmetic-geometric-mean-Calculate-Pi/arithmetic-geometric-mean-calculate-pi-2.rexx"
call run "Arithmetic-geometric-mean-Calculate-Pi/arithmetic-geometric-mean-calculate-pi-3.rexx"

call run "Arithmetic-Integer/arithmetic-integer.rexx", "stdin", "100 200"

/* not activated: too long */
call skip "Arithmetic-Rational/arithmetic-rational.rexx"

call run "Array-concatenation/array-concatenation-1.rexx"
call run "Array-concatenation/array-concatenation-2.rexx"
call run "Array-concatenation/array-concatenation-3.rexx"

call run "Arrays/arrays-1.rexx"
call run "Arrays/arrays-2.rexx"
call run "Arrays/arrays-3.rexx"
call run "Arrays/arrays-4.rexx"
call run "Arrays/arrays-5.rexx"
call run "Arrays/arrays-6.rexx"

/* To investigate : why is Regina blocked */
if isRegina then call skip "Assertions/assertions.rexx", "stdin", "", "", "Trace Off"
else call run "Assertions/assertions.rexx", "stdin", "", "", "Trace Off"

call run "Associative-array-Creation/associative-array-creation-1.rexx"
call run "Associative-array-Creation/associative-array-creation-2.rexx"

/* [RC=0 but KO anyway] bash: UPPER: command not found */
call run "Associative-array-Iteration/associative-array-iteration.rexx"

/* not activated: too long */
call skip "Average-loop-length/average-loop-length.rexx"

call run "Averages-Arithmetic-mean/averages-arithmetic-mean.rexx"

call run "Averages-Mean-angle/averages-mean-angle.rexx"

call run "Averages-Mean-time-of-day/averages-mean-time-of-day.rexx"

call run "Averages-Median/averages-median.rexx"

call run "Averages-Mode/averages-mode-1.rexx"
call run "Averages-Mode/averages-mode-2.rexx"

call run "Averages-Pythagorean-means/averages-pythagorean-means.rexx"

call run "Averages-Root-mean-square/averages-root-mean-square.rexx"

call run "Averages-Simple-moving-average/averages-simple-moving-average.rexx"

call run "Balanced-brackets/balanced-brackets-1.rexx"
call run "Balanced-brackets/balanced-brackets-2.rexx"
call run "Balanced-brackets/balanced-brackets-3.rexx"

call run "Balanced-ternary/balanced-ternary.rexx"

/* [KO] REX0385E: Error 40.23:  CENTER argument 3 must be a single character; found "─" */
call run "Benfords-law/benfords-law.rexx"

call run "Bernoulli-numbers/bernoulli-numbers.rexx"

call run "Best-shuffle/best-shuffle-1.rexx"

/* not rexx language */
call skip "Best-shuffle/best-shuffle-2.rexx"

/* not rexx language */
call skip "Best-shuffle/best-shuffle-3.rexx"

/* not rexx language */
call skip "Best-shuffle/best-shuffle-4.rexx"

call run "Binary-digits/binary-digits-1.rexx"
call run "Binary-digits/binary-digits-2.rexx"
call run "Binary-digits/binary-digits-3.rexx"
call run "Binary-digits/binary-digits-4.rexx"

call run "Binary-search/binary-search-1.rexx", 269
call run "Binary-search/binary-search-2.rexx", 823

call run "Binary-strings/binary-strings.rexx"

call run "Bitmap/bitmap-1.rexx"

/* [Warning] bash: erase: command not found */
call run "Bitmap/bitmap-2.rexx"

call run "Bitmap-Bresenhams-line-algorithm/bitmap-bresenhams-line-algorithm-1.rexx"
call run "Bitmap-Bresenhams-line-algorithm/bitmap-bresenhams-line-algorithm-2.rexx"

call run "Bitmap-Flood-fill/bitmap-flood-fill.rexx"

call run "Bitmap-Midpoint-circle-algorithm/bitmap-midpoint-circle-algorithm.rexx"

call run "Bitmap-Write-a-PPM-file/bitmap-write-a-ppm-file.rexx"

call run "Bitwise-IO/bitwise-io.rexx"

call run "Bitwise-operations/bitwise-operations.rexx"

call run "Boolean-values/boolean-values-1.rexx"
call run "Boolean-values/boolean-values-2.rexx"
call run "Boolean-values/boolean-values-3.rexx"
call run "Boolean-values/boolean-values-4.rexx"

/* [KO] false = ¬true */
call run "Boolean-values/boolean-values-5.rexx"

call run "Boolean-values/boolean-values-6.rexx"
call run "Box-the-compass/box-the-compass.rexx"

/* [KO] SCRSIZE BIF not available */
call run "Brownian-tree/brownian-tree.rexx"

call run "Bulls-and-cows/bulls-and-cows-1.rexx", "stdin", "1234", "quit"
call run "Bulls-and-cows/bulls-and-cows-2.rexx", "stdin", "1234", "quit"
call run "Bulls-and-cows-Player/bulls-and-cows-player.rexx", "stdin", "1 2", "quit"

/*
call run "Caesar-cipher/caesar-cipher-1.rexx
call run "Caesar-cipher/caesar-cipher-2.rexx
call run "Calendar/calendar.rexx
call run "Calendar---for-REAL-programmers/calendar---for-real-programmers.rexx
call run "Call-a-foreign-language-function/call-a-foreign-language-function.rexx
call run "Call-a-function/call-a-function-1.rexx
call run "Call-a-function/call-a-function-2.rexx
call run "Call-a-function-in-a-shared-library/call-a-function-in-a-shared-library.rexx
call run "Carmichael-3-strong-pseudoprimes/carmichael-3-strong-pseudoprimes-1.rexx
call run "Carmichael-3-strong-pseudoprimes/carmichael-3-strong-pseudoprimes-2.rexx
call run "Case-sensitivity-of-identifiers/case-sensitivity-of-identifiers-1.rexx
call run "Case-sensitivity-of-identifiers/case-sensitivity-of-identifiers-2.rexx
call run "Casting-out-nines/casting-out-nines.rexx
call run "Catalan-numbers/catalan-numbers-1.rexx
call run "Catalan-numbers/catalan-numbers-2.rexx
call run "Catalan-numbers-Pascals-triangle/catalan-numbers-pascals-triangle-1.rexx
call run "Catalan-numbers-Pascals-triangle/catalan-numbers-pascals-triangle-2.rexx
call run "Catalan-numbers-Pascals-triangle/catalan-numbers-pascals-triangle-3.rexx
call run "Catalan-numbers-Pascals-triangle/catalan-numbers-pascals-triangle-4.rexx
call run "Catamorphism/catamorphism.rexx
call run "Character-codes/character-codes-1.rexx
call run "Character-codes/character-codes-2.rexx
call run "Check-Machin-like-formulas/check-machin-like-formulas.rexx
call run "Check-that-file-exists/check-that-file-exists-1.rexx
call run "Check-that-file-exists/check-that-file-exists-2.rexx
call run "Chinese-remainder-theorem/chinese-remainder-theorem-1.rexx
call run "Chinese-remainder-theorem/chinese-remainder-theorem-2.rexx
call run "Cholesky-decomposition/cholesky-decomposition.rexx
call run "Circles-of-given-radius-through-two-points/circles-of-given-radius-through-two-points.rexx
call run "Closest-pair-problem/closest-pair-problem.rexx
call run "Closures-Value-capture/closures-value-capture.rexx
call run "Collections/collections-1.rexx
call run "Collections/collections-2.rexx
call run "Collections/collections-3.rexx
call run "Collections/collections-4.rexx
call run "Collections/collections-5.rexx
call run "Colour-bars-Display/colour-bars-display.rexx
call run "Combinations/combinations.rexx
call run "Combinations-and-permutations/combinations-and-permutations.rexx
call run "Combinations-with-repetitions/combinations-with-repetitions-1.rexx
call run "Combinations-with-repetitions/combinations-with-repetitions-2.rexx
call run "Combinations-with-repetitions/combinations-with-repetitions-3.rexx
call run "Comma-quibbling/comma-quibbling-1.rexx
call run "Comma-quibbling/comma-quibbling-2.rexx
call run "Comma-quibbling/comma-quibbling-3.rexx
call run "Command-line-arguments/command-line-arguments-1.rexx
call run "Command-line-arguments/command-line-arguments-2.rexx
call run "Comments/comments-1.rexx
call run "Comments/comments-2.rexx
call run "Comments/comments-3.rexx
call run "Compile-time-calculation/compile-time-calculation.rexx
call run "Compound-data-type/compound-data-type-1.rexx
call run "Compound-data-type/compound-data-type-2.rexx
call run "Conditional-structures/conditional-structures-1.rexx
call run "Conditional-structures/conditional-structures-2.rexx
call run "Conditional-structures/conditional-structures-3.rexx
call run "Conjugate-transpose/conjugate-transpose.rexx
call run "Constrained-random-points-on-a-circle/constrained-random-points-on-a-circle-1.rexx
call run "Constrained-random-points-on-a-circle/constrained-random-points-on-a-circle-2.rexx
call run "Constrained-random-points-on-a-circle/constrained-random-points-on-a-circle-3.rexx
call run "Constrained-random-points-on-a-circle/constrained-random-points-on-a-circle-4.rexx
call run "Continued-fraction/continued-fraction-1.rexx
call run "Continued-fraction/continued-fraction-2.rexx
call run "Continued-fraction/continued-fraction-3.rexx
call run "Continued-fraction-Arithmetic-Construct-from-rational-number/continued-fraction-arithmetic-construct-from-rational-number.rexx
call run "Convert-decimal-number-to-rational/convert-decimal-number-to-rational-1.rexx
call run "Convert-decimal-number-to-rational/convert-decimal-number-to-rational-2.rexx
call run "Convert-decimal-number-to-rational/convert-decimal-number-to-rational-3.rexx
call run "Conways-Game-of-Life/conways-game-of-life-1.rexx
call run "Conways-Game-of-Life/conways-game-of-life-2.rexx
call run "Copy-a-string/copy-a-string.rexx
call run "Count-in-factors/count-in-factors-1.rexx
call run "Count-in-factors/count-in-factors-2.rexx
call run "Count-in-octal/count-in-octal.rexx
call run "Count-occurrences-of-a-substring/count-occurrences-of-a-substring.rexx
call run "Count-the-coins/count-the-coins-1.rexx
call run "Count-the-coins/count-the-coins-2.rexx
call run "Count-the-coins/count-the-coins-3.rexx
call run "CRC-32/crc-32.rexx
call run "Create-a-file/create-a-file.rexx
call run "Create-a-file-on-magnetic-tape/create-a-file-on-magnetic-tape.rexx
call run "Create-a-two-dimensional-array-at-runtime/create-a-two-dimensional-array-at-runtime.rexx
call run "Create-an-HTML-table/create-an-html-table.rexx
call run "CSV-data-manipulation/csv-data-manipulation.rexx
call run "CSV-to-HTML-translation/csv-to-html-translation-1.rexx
call run "CSV-to-HTML-translation/csv-to-html-translation-2.rexx
call run "CSV-to-HTML-translation/csv-to-html-translation.rexx
call run "Currying/currying-1.rexx
call run "Currying/currying-2.rexx
call run "Cut-a-rectangle/cut-a-rectangle-1.rexx
call run "Cut-a-rectangle/cut-a-rectangle-2.rexx
call run "Date-format/date-format-1.rexx
call run "Date-format/date-format-2.rexx
call run "Date-format/date-format-3.rexx
call run "Date-manipulation/date-manipulation.rexx
call run "Day-of-the-week/day-of-the-week-1.rexx
call run "Day-of-the-week/day-of-the-week-2.rexx
call run "Day-of-the-week/day-of-the-week-3.rexx
call run "Day-of-the-week/day-of-the-week-4.rexx
call run "Deal-cards-for-FreeCell/deal-cards-for-freecell.rexx
call run "Death-Star/death-star.rexx
call run "Delete-a-file/delete-a-file.rexx
call run "Detect-division-by-zero/detect-division-by-zero.rexx
call run "Determine-if-a-string-is-numeric/determine-if-a-string-is-numeric.rexx
call run "Determine-if-only-one-instance-is-running/determine-if-only-one-instance-is-running.rexx
call run "Digital-root/digital-root-1.rexx
call run "Digital-root/digital-root-2.rexx
call run "Digital-root/digital-root-3.rexx
call run "Digital-root-Multiplicative-digital-root/digital-root-multiplicative-digital-root-1.rexx
call run "Digital-root-Multiplicative-digital-root/digital-root-multiplicative-digital-root-2.rexx
call run "Dinesmans-multiple-dwelling-problem/dinesmans-multiple-dwelling-problem.rexx
call run "Dining-philosophers/dining-philosophers.rexx
call run "Discordian-date/discordian-date.rexx
call run "DNS-query/dns-query-1.rexx
call run "DNS-query/dns-query-2.rexx
call run "Documentation/documentation-1.rexx
call run "Documentation/documentation-2.rexx
call run "Dot-product/dot-product-1.rexx
call run "Dot-product/dot-product-2.rexx
call run "Doubly-linked-list-Definition/doubly-linked-list-definition.rexx
call run "Doubly-linked-list-Element-definition/doubly-linked-list-element-definition.rexx
call run "Doubly-linked-list-Element-insertion/doubly-linked-list-element-insertion.rexx
call run "Doubly-linked-list-Traversal/doubly-linked-list-traversal.rexx
call run "Dragon-curve/dragon-curve.rexx
call run "Draw-a-clock/draw-a-clock.rexx
call run "Draw-a-cuboid/draw-a-cuboid.rexx
call run "Draw-a-sphere/draw-a-sphere.rexx
call run "Dutch-national-flag-problem/dutch-national-flag-problem-1.rexx
call run "Dutch-national-flag-problem/dutch-national-flag-problem-2.rexx
call run "Dynamic-variable-names/dynamic-variable-names.rexx
call run "Element-wise-operations/element-wise-operations-1.rexx
call run "Element-wise-operations/element-wise-operations-2.rexx
call run "Empty-directory/empty-directory.rexx
call run "Empty-program/empty-program-1.rexx
call run "Empty-program/empty-program-2.rexx
call run "Empty-program/empty-program-3.rexx
call run "Empty-program/empty-program-4.rexx
call run "Empty-program/empty-program-5.rexx
call run "Empty-string/empty-string.rexx
call run "Enforced-immutability/enforced-immutability.rexx
call run "Entropy/entropy-1.rexx
call run "Entropy/entropy-2.rexx
call run "Entropy/entropy-3.rexx
call run "Enumerations/enumerations.rexx
call run "Environment-variables/environment-variables-1.rexx
call run "Environment-variables/environment-variables-2.rexx
call run "Environment-variables/environment-variables-3.rexx
call run "Equilibrium-index/equilibrium-index-1.rexx
call run "Equilibrium-index/equilibrium-index-2.rexx
call run "Ethiopian-multiplication/ethiopian-multiplication-1.rexx
call run "Ethiopian-multiplication/ethiopian-multiplication-2.rexx
call run "Euler-method/euler-method-1.rexx
call run "Euler-method/euler-method-2.rexx
call run "Evaluate-binomial-coefficients/evaluate-binomial-coefficients-1.rexx
call run "Evaluate-binomial-coefficients/evaluate-binomial-coefficients-2.rexx
call run "Even-or-odd/even-or-odd.rexx
call run "Events/events.rexx
call run "Evolutionary-algorithm/evolutionary-algorithm-1.rexx
call run "Evolutionary-algorithm/evolutionary-algorithm-2.rexx
call run "Evolutionary-algorithm/evolutionary-algorithm-3.rexx
call run "Exceptions/exceptions.rexx
call run "Exceptions-Catch-an-exception-thrown-in-a-nested-call/exceptions-catch-an-exception-thrown-in-a-nested-call.rexx
call run "Executable-library/executable-library-1.rexx
call run "Executable-library/executable-library-2.rexx
call run "Executable-library/executable-library-3.rexx
call run "Execute-a-Markov-algorithm/execute-a-markov-algorithm.rexx
call run "Execute-a-system-command/execute-a-system-command.rexx
call run "Execute-Brain----/execute-brain----.rexx
call run "Execute-HQ9+/execute-hq9+.rexx
call run "Exponentiation-operator/exponentiation-operator.rexx
call run "Extend-your-language/extend-your-language-1.rexx
call run "Extend-your-language/extend-your-language-2.rexx
call run "Extensible-prime-generator/extensible-prime-generator.rexx
call run "Factorial/factorial-1.rexx
call run "Factorial/factorial-2.rexx
call run "Factorial/factorial-3.rexx
call run "Factors-of-a-Mersenne-number/factors-of-a-mersenne-number.rexx
call run "Factors-of-an-integer/factors-of-an-integer-1.rexx
call run "Factors-of-an-integer/factors-of-an-integer-2.rexx
call run "Fast-Fourier-transform/fast-fourier-transform.rexx
call run "Fibonacci-n-step-number-sequences/fibonacci-n-step-number-sequences.rexx
call run "Fibonacci-sequence/fibonacci-sequence.rexx
call run "Fibonacci-word/fibonacci-word.rexx
call run "Fibonacci-word-fractal/fibonacci-word-fractal.rexx
call run "File-input-output/file-input-output-1.rexx
call run "File-input-output/file-input-output-2.rexx
call run "File-modification-time/file-modification-time.rexx
call run "File-size/file-size-1.rexx
call run "File-size/file-size-2.rexx
call run "File-size/file-size-3.rexx
call run "files.txt
call run "Filter/filter-1.rexx
call run "Filter/filter-2.rexx
call run "Filter/filter-3.rexx
call run "Filter/filter-4.rexx
call run "Filter/filter-5.rexx
call run "Find-common-directory-path/find-common-directory-path.rexx
call run "Find-limit-of-recursion/find-limit-of-recursion-1.rexx
call run "Find-limit-of-recursion/find-limit-of-recursion-2.rexx
call run "Find-the-last-Sunday-of-each-month/find-the-last-sunday-of-each-month.rexx
call run "Find-the-missing-permutation/find-the-missing-permutation.rexx
call run "First-class-environments/first-class-environments.rexx
call run "First-class-functions/first-class-functions.rexx
call run "Five-weekends/five-weekends-1.rexx
call run "Five-weekends/five-weekends-2.rexx
call run "Five-weekends/five-weekends-3.rexx
call run "Five-weekends/five-weekends-4.rexx
call run "Five-weekends/five-weekends-5.rexx
call run "FizzBuzz/fizzbuzz-1.rexx
call run "FizzBuzz/fizzbuzz-2.rexx
call run "FizzBuzz/fizzbuzz-3.rexx
call run "FizzBuzz/fizzbuzz-4.rexx
call run "Flatten-a-list/flatten-a-list-1.rexx
call run "Flatten-a-list/flatten-a-list-2.rexx
call run "Flipping-bits-game/flipping-bits-game.rexx
call run "Flow-control-structures/flow-control-structures-1.rexx
call run "Flow-control-structures/flow-control-structures-10.rexx
call run "Flow-control-structures/flow-control-structures-11.rexx
call run "Flow-control-structures/flow-control-structures-2.rexx
call run "Flow-control-structures/flow-control-structures-3.rexx
call run "Flow-control-structures/flow-control-structures-4.rexx
call run "Flow-control-structures/flow-control-structures-5.rexx
call run "Flow-control-structures/flow-control-structures-6.rexx
call run "Flow-control-structures/flow-control-structures-7.rexx
call run "Flow-control-structures/flow-control-structures-8.rexx
call run "Flow-control-structures/flow-control-structures-9.rexx
call run "Floyds-triangle/floyds-triangle-1.rexx
call run "Floyds-triangle/floyds-triangle-2.rexx
call run "Floyds-triangle/floyds-triangle-3.rexx
call run "Floyds-triangle/floyds-triangle-4.rexx
call run "Forest-fire/forest-fire.rexx
call run "Fork/fork.rexx
call run "Formatted-numeric-output/formatted-numeric-output.rexx
call run "Forward-difference/forward-difference-1.rexx
call run "Forward-difference/forward-difference-2.rexx
call run "Forward-difference/forward-difference-3.rexx
call run "Forward-difference/forward-difference-4.rexx
call run "Four-bit-adder/four-bit-adder.rexx
call run "Fractran/fractran-1.rexx
call run "Fractran/fractran-2.rexx
call run "Function-composition/function-composition.rexx
call run "Function-definition/function-definition-1.rexx
call run "Function-definition/function-definition-2.rexx
call run "Function-frequency/function-frequency-1.rexx
call run "Function-frequency/function-frequency-2.rexx
call run "Gamma-function/gamma-function.rexx
call run "Gaussian-elimination/gaussian-elimination-1.rexx
call run "Gaussian-elimination/gaussian-elimination-2.rexx
call run "Generate-Chess960-starting-position/generate-chess960-starting-position-1.rexx
call run "Generate-Chess960-starting-position/generate-chess960-starting-position-2.rexx
call run "Generate-Chess960-starting-position/generate-chess960-starting-position-3.rexx
call run "Generate-lower-case-ASCII-alphabet/generate-lower-case-ascii-alphabet-1.rexx
call run "Generate-lower-case-ASCII-alphabet/generate-lower-case-ascii-alphabet-2.rexx
call run "Generator-Exponential/generator-exponential.rexx
call run "Generic-swap/generic-swap-1.rexx
call run "Generic-swap/generic-swap-2.rexx
call run "Generic-swap/generic-swap-3.rexx
call run "Globally-replace-text-in-several-files/globally-replace-text-in-several-files-1.rexx
call run "Globally-replace-text-in-several-files/globally-replace-text-in-several-files-2.rexx
call run "Gray-code/gray-code.rexx
call run "Grayscale-image/grayscale-image-1.rexx
call run "Grayscale-image/grayscale-image-2.rexx
call run "Greatest-common-divisor/greatest-common-divisor-1.rexx
call run "Greatest-common-divisor/greatest-common-divisor-2.rexx
call run "Greatest-common-divisor/greatest-common-divisor-3.rexx
call run "Greatest-element-of-a-list/greatest-element-of-a-list-1.rexx
call run "Greatest-element-of-a-list/greatest-element-of-a-list-2.rexx
call run "Greatest-element-of-a-list/greatest-element-of-a-list-3.rexx
call run "Greatest-element-of-a-list/greatest-element-of-a-list-4.rexx
call run "Greatest-subsequential-sum/greatest-subsequential-sum-1.rexx
call run "Greatest-subsequential-sum/greatest-subsequential-sum-2.rexx
call run "Greatest-subsequential-sum/greatest-subsequential-sum-3.rexx
call run "Guess-the-number/guess-the-number-1.rexx
call run "Guess-the-number/guess-the-number-2.rexx
call run "Guess-the-number-With-feedback/guess-the-number-with-feedback.rexx
call run "Guess-the-number-With-feedback--player-/guess-the-number-with-feedback--player--1.rexx
call run "Guess-the-number-With-feedback--player-/guess-the-number-with-feedback--player--2.rexx
call run "Hailstone-sequence/hailstone-sequence-1.rexx
call run "Hailstone-sequence/hailstone-sequence-2.rexx
call run "Hamming-numbers/hamming-numbers-1.rexx
call run "Hamming-numbers/hamming-numbers-2.rexx
call run "Handle-a-signal/handle-a-signal.rexx
call run "Happy-numbers/happy-numbers-1.rexx
call run "Happy-numbers/happy-numbers-2.rexx
call run "Happy-numbers/happy-numbers-3.rexx
call run "Harshad-or-Niven-series/harshad-or-niven-series-1.rexx
call run "Harshad-or-Niven-series/harshad-or-niven-series-2.rexx
call run "Harshad-or-Niven-series/harshad-or-niven-series-3.rexx
call run "Harshad-or-Niven-series/harshad-or-niven-series-4.rexx
call run "Hash-from-two-arrays/hash-from-two-arrays.rexx
call run "Hash-join/hash-join.rexx
call run "Haversine-formula/haversine-formula-1.rexx
call run "Haversine-formula/haversine-formula-2.rexx
call run "Haversine-formula/haversine-formula.rexx
call run "Hello-world-Graphical/hello-world-graphical-1.rexx
call run "Hello-world-Graphical/hello-world-graphical-2.rexx
call run "Hello-world-Line-printer/hello-world-line-printer.rexx
call run "Hello-world-Newbie/hello-world-newbie.rexx
call run "Hello-world-Newline-omission/hello-world-newline-omission.rexx
call run "Hello-world-Standard-error/hello-world-standard-error-1.rexx
call run "Hello-world-Standard-error/hello-world-standard-error-2.rexx
call run "Hello-world-Standard-error/hello-world-standard-error-3.rexx
call run "Hello-world-Standard-error/hello-world-standard-error-4.rexx
call run "Hello-world-Text/hello-world-text-1.rexx
call run "Hello-world-Text/hello-world-text-2.rexx
call run "Hello-world-Text/hello-world-text-3.rexx
call run "Here-document/here-document.rexx
call run "Heronian-triangles/heronian-triangles-1.rexx
call run "Heronian-triangles/heronian-triangles-2.rexx
call run "Hickerson-series-of-almost-integers/hickerson-series-of-almost-integers-1.rexx
call run "Hickerson-series-of-almost-integers/hickerson-series-of-almost-integers-2.rexx
call run "Hickerson-series-of-almost-integers/hickerson-series-of-almost-integers-3.rexx
call run "Higher-order-functions/higher-order-functions.rexx
call run "History-variables/history-variables-1.rexx
call run "History-variables/history-variables-2.rexx
call run "Hofstadter-Conway-$10,000-sequence/hofstadter-conway-$10,000-sequence.rexx
call run "Hofstadter-Figure-Figure-sequences/hofstadter-figure-figure-sequences-1.rexx
call run "Hofstadter-Figure-Figure-sequences/hofstadter-figure-figure-sequences-2.rexx
call run "Hofstadter-Q-sequence/hofstadter-q-sequence-1.rexx
call run "Hofstadter-Q-sequence/hofstadter-q-sequence-2.rexx
call run "Hofstadter-Q-sequence/hofstadter-q-sequence-3.rexx
call run "Holidays-related-to-Easter/holidays-related-to-easter.rexx
call run "Horizontal-sundial-calculations/horizontal-sundial-calculations.rexx
call run "Horners-rule-for-polynomial-evaluation/horners-rule-for-polynomial-evaluation-1.rexx
call run "Horners-rule-for-polynomial-evaluation/horners-rule-for-polynomial-evaluation-2.rexx
call run "Host-introspection/host-introspection.rexx
call run "Hostname/hostname-1.rexx
call run "Hostname/hostname-2.rexx
call run "Hostname/hostname-3.rexx
call run "Hostname/hostname-4.rexx
call run "Hostname/hostname-5.rexx
call run "HTTP/http-1.rexx
call run "HTTP/http-2.rexx
call run "HTTP/http-3.rexx
call run "Huffman-coding/huffman-coding.rexx
call run "I-before-E-except-after-C/i-before-e-except-after-c-1.rexx
call run "I-before-E-except-after-C/i-before-e-except-after-c-2.rexx
call run "IBAN/iban-1.rexx
call run "IBAN/iban-2.rexx
call run "Identity-matrix/identity-matrix-1.rexx
call run "Identity-matrix/identity-matrix-2.rexx
call run "Identity-matrix/identity-matrix-3.rexx
call run "Image-noise/image-noise.rexx
call run "Include-a-file/include-a-file-1.rexx
call run "Include-a-file/include-a-file-2.rexx
call run "Include-a-file/include-a-file-3.rexx
call run "Include-a-file/include-a-file-4.rexx
call run "Increment-a-numerical-string/increment-a-numerical-string-1.rexx
call run "Increment-a-numerical-string/increment-a-numerical-string-2.rexx
call run "Input-loop/input-loop-1.rexx
call run "Input-loop/input-loop-2.rexx
call run "Input-loop/input-loop-3.rexx
call run "Input-loop/input-loop-4.rexx
call run "Input-loop/input-loop-5.rexx
call run "Integer-comparison/integer-comparison.rexx
call run "Integer-overflow/integer-overflow.rexx
call run "Integer-sequence/integer-sequence.rexx
call run "Interactive-programming/interactive-programming-1.rexx
call run "Interactive-programming/interactive-programming-2.rexx
call run "Interactive-programming/interactive-programming-3.rexx
call run "Introspection/introspection-1.rexx
call run "Introspection/introspection-2.rexx
call run "Introspection/introspection-3.rexx
call run "Introspection/introspection-4.rexx
call run "Introspection/introspection-5.rexx
call run "Introspection/introspection-6.rexx
call run "Introspection/introspection-7.rexx
call run "Inverted-index/inverted-index.rexx
call run "Inverted-syntax/inverted-syntax.rexx
call run "Iterated-digits-squaring/iterated-digits-squaring-1.rexx
call run "Iterated-digits-squaring/iterated-digits-squaring-2.rexx
call run "Jensens-Device/jensens-device.rexx
call run "Josephus-problem/josephus-problem-1.rexx
call run "Josephus-problem/josephus-problem-2.rexx
call run "Jump-anywhere/jump-anywhere-1.rexx
call run "Jump-anywhere/jump-anywhere-2.rexx
call run "Jump-anywhere/jump-anywhere-3.rexx
call run "Jump-anywhere/jump-anywhere-4.rexx
call run "Jump-anywhere/jump-anywhere-5.rexx
call run "Kaprekar-numbers/kaprekar-numbers.rexx
call run "Keyboard-input-Flush-the-keyboard-buffer/keyboard-input-flush-the-keyboard-buffer-1.rexx
call run "Keyboard-input-Flush-the-keyboard-buffer/keyboard-input-flush-the-keyboard-buffer-2.rexx
call run "Keyboard-input-Keypress-check/keyboard-input-keypress-check.rexx
call run "Keyboard-input-Obtain-a-Y-or-N-response/keyboard-input-obtain-a-y-or-n-response-1.rexx
call run "Keyboard-input-Obtain-a-Y-or-N-response/keyboard-input-obtain-a-y-or-n-response-2.rexx
call run "Keyboard-input-Obtain-a-Y-or-N-response/keyboard-input-obtain-a-y-or-n-response-3.rexx
call run "Keyboard-macros/keyboard-macros.rexx
call run "Knapsack-problem-0-1/knapsack-problem-0-1.rexx
call run "Knapsack-problem-Bounded/knapsack-problem-bounded.rexx
call run "Knapsack-problem-Continuous/knapsack-problem-continuous-1.rexx
call run "Knapsack-problem-Continuous/knapsack-problem-continuous-2.rexx
call run "Knapsack-problem-Unbounded/knapsack-problem-unbounded-1.rexx
call run "Knapsack-problem-Unbounded/knapsack-problem-unbounded-2.rexx
call run "Knights-tour/knights-tour.rexx
call run "Knuth-shuffle/knuth-shuffle-1.rexx
call run "Knuth-shuffle/knuth-shuffle-2.rexx
call run "Knuth-shuffle/knuth-shuffle-3.rexx
call run "Knuths-algorithm-S/knuths-algorithm-s.rexx
call run "Langtons-ant/langtons-ant.rexx
call run "Largest-int-from-concatenated-ints/largest-int-from-concatenated-ints.rexx
call run "Last-Friday-of-each-month/last-friday-of-each-month.rexx
call run "Last-letter-first-letter/last-letter-first-letter-1.rexx
call run "Last-letter-first-letter/last-letter-first-letter-2.rexx
call run "Leap-year/leap-year-1.rexx
call run "Leap-year/leap-year-2.rexx
call run "Leap-year/leap-year-3.rexx
call run "Leap-year/leap-year-4.rexx
call run "Least-common-multiple/least-common-multiple-1.rexx
call run "Least-common-multiple/least-common-multiple-2.rexx
call run "Least-common-multiple/least-common-multiple-3.rexx
call run "Left-factorials/left-factorials.rexx
call run "Letter-frequency/letter-frequency-1.rexx
call run "Letter-frequency/letter-frequency-2.rexx
call run "Levenshtein-distance/levenshtein-distance-1.rexx
call run "Levenshtein-distance/levenshtein-distance-2.rexx
call run "Levenshtein-distance/levenshtein-distance-3.rexx
call run "Levenshtein-distance/levenshtein-distance-4.rexx
call run "Linear-congruential-generator/linear-congruential-generator.rexx
call run "List-comprehensions/list-comprehensions-1.rexx
call run "List-comprehensions/list-comprehensions-2.rexx
call run "Literals-Floating-point/literals-floating-point-1.rexx
call run "Literals-Floating-point/literals-floating-point-2.rexx
call run "Literals-Integer/literals-integer.rexx
call run "Literals-String/literals-string-1.rexx
call run "Literals-String/literals-string-2.rexx
call run "Literals-String/literals-string-3.rexx
call run "Literals-String/literals-string-4.rexx
call run "Logical-operations/logical-operations.rexx
call run "Long-multiplication/long-multiplication-1.rexx
call run "Long-multiplication/long-multiplication-2.rexx
call run "Longest-common-subsequence/longest-common-subsequence.rexx
call run "Longest-string-challenge/longest-string-challenge-1.rexx
call run "Longest-string-challenge/longest-string-challenge-2.rexx
call run "Longest-string-challenge/longest-string-challenge-3.rexx
call run "Look-and-say-sequence/look-and-say-sequence-1.rexx
call run "Look-and-say-sequence/look-and-say-sequence-2.rexx
call run "Loop-over-multiple-arrays-simultaneously/loop-over-multiple-arrays-simultaneously-1.rexx
call run "Loop-over-multiple-arrays-simultaneously/loop-over-multiple-arrays-simultaneously-2.rexx
call run "Loop-over-multiple-arrays-simultaneously/loop-over-multiple-arrays-simultaneously-3.rexx
call run "Loop-over-multiple-arrays-simultaneously/loop-over-multiple-arrays-simultaneously-4.rexx
call run "Loops-Break/loops-break.rexx
call run "Loops-Continue/loops-continue-1.rexx
call run "Loops-Continue/loops-continue-2.rexx
call run "Loops-Do-while/loops-do-while-1.rexx
call run "Loops-Do-while/loops-do-while-2.rexx
call run "Loops-Downward-for/loops-downward-for-1.rexx
call run "Loops-Downward-for/loops-downward-for-2.rexx
call run "Loops-Downward-for/loops-downward-for-3.rexx
call run "Loops-Downward-for/loops-downward-for-4.rexx
call run "Loops-For/loops-for-1.rexx
call run "Loops-For/loops-for-2.rexx
call run "Loops-For-with-a-specified-step/loops-for-with-a-specified-step-1.rexx
call run "Loops-For-with-a-specified-step/loops-for-with-a-specified-step-2.rexx
call run "Loops-Foreach/loops-foreach.rexx
call run "Loops-Infinite/loops-infinite-1.rexx
call run "Loops-Infinite/loops-infinite-2.rexx
call run "Loops-Infinite/loops-infinite-3.rexx
call run "Loops-Infinite/loops-infinite-4.rexx
call run "Loops-N-plus-one-half/loops-n-plus-one-half-1.rexx
call run "Loops-N-plus-one-half/loops-n-plus-one-half-2.rexx
call run "Loops-N-plus-one-half/loops-n-plus-one-half-3.rexx
call run "Loops-Nested/loops-nested.rexx
call run "Loops-While/loops-while-1.rexx
call run "Loops-While/loops-while-2.rexx
call run "Loops-While/loops-while-3.rexx
call run "Loops-While/loops-while-4.rexx
call run "LU-decomposition/lu-decomposition.rexx
call run "Lucas-Lehmer-test/lucas-lehmer-test.rexx
call run "Ludic-numbers/ludic-numbers.rexx
call run "Luhn-test-of-credit-card-numbers/luhn-test-of-credit-card-numbers-1.rexx
call run "Luhn-test-of-credit-card-numbers/luhn-test-of-credit-card-numbers-2.rexx
call run "LZW-compression/lzw-compression-1.rexx
call run "LZW-compression/lzw-compression-2.rexx
call run "Mad-Libs/mad-libs.rexx
call run "Magic-squares-of-odd-order/magic-squares-of-odd-order.rexx
call run "Main-step-of-GOST-28147-89/main-step-of-gost-28147-89.rexx
call run "Make-directory-path/make-directory-path.rexx
call run "Man-or-boy-test/man-or-boy-test.rexx
call run "Mandelbrot-set/mandelbrot-set-1.rexx
call run "Mandelbrot-set/mandelbrot-set-2.rexx
call run "Mandelbrot-set/mandelbrot-set-3.rexx
call run "Map-range/map-range-1.rexx
call run "Map-range/map-range-2.rexx
call run "Map-range/map-range-3.rexx
call run "Map-range/map-range-4.rexx
call run "Matrix-arithmetic/matrix-arithmetic-1.rexx
call run "Matrix-arithmetic/matrix-arithmetic-2.rexx
call run "Matrix-arithmetic/matrix-arithmetic-3.rexx
call run "Matrix-multiplication/matrix-multiplication.rexx
call run "Matrix-transposition/matrix-transposition.rexx
call run "Maximum-triangle-path-sum/maximum-triangle-path-sum.rexx
call run "Maze-generation/maze-generation-1.rexx
call run "Maze-generation/maze-generation-2.rexx
call run "Maze-generation/maze-generation-3.rexx
call run "MD5/md5.rexx
call run "MD5-Implementation/md5-implementation.rexx
call run "Memory-allocation/memory-allocation-1.rexx
call run "Memory-allocation/memory-allocation-2.rexx
call run "Memory-layout-of-a-data-structure/memory-layout-of-a-data-structure-1.rexx
call run "Memory-layout-of-a-data-structure/memory-layout-of-a-data-structure-2.rexx
call run "Menu/menu.rexx
call run "Metaprogramming/metaprogramming.rexx
call run "Metronome/metronome-1.rexx
call run "Metronome/metronome-2.rexx
call run "Metronome/metronome-3.rexx
call run "Middle-three-digits/middle-three-digits-1.rexx
call run "Middle-three-digits/middle-three-digits-2.rexx
call run "Miller-Rabin-primality-test/miller-rabin-primality-test.rexx
call run "Modular-exponentiation/modular-exponentiation-1.rexx
call run "Modular-exponentiation/modular-exponentiation-2.rexx
call run "Modular-inverse/modular-inverse.rexx
call run "Monte-Carlo-methods/monte-carlo-methods.rexx
call run "Monty-Hall-problem/monty-hall-problem-1.rexx
call run "Monty-Hall-problem/monty-hall-problem-2.rexx
call run "Move-to-front-algorithm/move-to-front-algorithm-1.rexx
call run "Move-to-front-algorithm/move-to-front-algorithm-2.rexx
call run "Multifactorial/multifactorial.rexx
call run "Multiplication-tables/multiplication-tables.rexx
call run "Multisplit/multisplit.rexx
call run "Mutual-recursion/mutual-recursion-1.rexx
call run "Mutual-recursion/mutual-recursion-2.rexx
call run "Mutual-recursion/mutual-recursion-3.rexx
call run "N-queens-problem/n-queens-problem.rexx
call run "Named-parameters/named-parameters-1.rexx
call run "Named-parameters/named-parameters-2.rexx
call run "Narcissist/narcissist-1.rexx
call run "Narcissist/narcissist-2.rexx
call run "Narcissistic-decimal-number/narcissistic-decimal-number-1.rexx
call run "Narcissistic-decimal-number/narcissistic-decimal-number-2.rexx
call run "Narcissistic-decimal-number/narcissistic-decimal-number-3.rexx
call run "Nautical-bell/nautical-bell.rexx
call run "Non-continuous-subsequences/non-continuous-subsequences.rexx
call run "Non-decimal-radices-Convert/non-decimal-radices-convert-1.rexx
call run "Non-decimal-radices-Convert/non-decimal-radices-convert-2.rexx
call run "Non-decimal-radices-Convert/non-decimal-radices-convert.rexx
call run "Non-decimal-radices-Input/non-decimal-radices-input.rexx
call run "Non-decimal-radices-Output/non-decimal-radices-output-1.rexx
call run "Non-decimal-radices-Output/non-decimal-radices-output-2.rexx
call run "Nth/nth.rexx
call run "Nth-root/nth-root.rexx
call run "Null-object/null-object.rexx
call run "Number-reversal-game/number-reversal-game.rexx
call run "Numeric-error-propagation/numeric-error-propagation.rexx
call run "Numerical-integration/numerical-integration.rexx
call run "Numerical-integration-Gauss-Legendre-Quadrature/numerical-integration-gauss-legendre-quadrature-1.rexx
call run "Numerical-integration-Gauss-Legendre-Quadrature/numerical-integration-gauss-legendre-quadrature-2.rexx
call run "Odd-word-problem/odd-word-problem.rexx
call run "Old-lady-swallowed-a-fly/old-lady-swallowed-a-fly.rexx
call run "One-dimensional-cellular-automata/one-dimensional-cellular-automata.rexx
call run "One-of-n-lines-in-a-file/one-of-n-lines-in-a-file.rexx
call run "Operator-precedence/operator-precedence.rexx
call run "Optional-parameters/optional-parameters-1.rexx
call run "Optional-parameters/optional-parameters-2.rexx
call run "Order-disjoint-list-items/order-disjoint-list-items.rexx
call run "Order-two-numerical-lists/order-two-numerical-lists.rexx
call run "Ordered-Partitions/ordered-partitions.rexx
call run "Ordered-words/ordered-words.rexx
call run "Palindrome-detection/palindrome-detection-1.rexx
call run "Palindrome-detection/palindrome-detection-2.rexx
call run "Pangram-checker/pangram-checker.rexx
call run "Paraffins/paraffins.rexx
call run "Parametric-polymorphism/parametric-polymorphism.rexx
call run "Parse-an-IP-Address/parse-an-ip-address-1.rexx
call run "Parse-an-IP-Address/parse-an-ip-address-2.rexx
call run "Parsing-RPN-calculator-algorithm/parsing-rpn-calculator-algorithm-1.rexx
call run "Parsing-RPN-calculator-algorithm/parsing-rpn-calculator-algorithm-2.rexx
call run "Parsing-RPN-calculator-algorithm/parsing-rpn-calculator-algorithm-3.rexx
call run "Parsing-RPN-to-infix-conversion/parsing-rpn-to-infix-conversion.rexx
call run "Parsing-Shunting-yard-algorithm/parsing-shunting-yard-algorithm-1.rexx
call run "Parsing-Shunting-yard-algorithm/parsing-shunting-yard-algorithm-2.rexx
call run "Partial-function-application/partial-function-application.rexx
call run "Pascals-triangle/pascals-triangle.rexx
call run "Pascals-triangle-Puzzle/pascals-triangle-puzzle.rexx
call run "Penneys-game/penneys-game.rexx
call run "Perfect-numbers/perfect-numbers-1.rexx
call run "Perfect-numbers/perfect-numbers-2.rexx
call run "Perfect-numbers/perfect-numbers-3.rexx
call run "Perfect-numbers/perfect-numbers-4.rexx
call run "Perfect-numbers/perfect-numbers-5.rexx
call run "Perfect-numbers/perfect-numbers-6.rexx
call run "Perfect-numbers/perfect-numbers-7.rexx
call run "Permutation-test/permutation-test.rexx
call run "Permutations/permutations-1.rexx
call run "Permutations/permutations-2.rexx
call run "Permutations-by-swapping/permutations-by-swapping.rexx
call run "Permutations-Derangements/permutations-derangements.rexx
call run "Permutations-Rank-of-a-permutation/permutations-rank-of-a-permutation.rexx
call run "Pernicious-numbers/pernicious-numbers.rexx
call run "Phrase-reversals/phrase-reversals-1.rexx
call run "Phrase-reversals/phrase-reversals-2.rexx
call run "Pi/pi.rexx
call run "Pick-random-element/pick-random-element-1.rexx
call run "Pick-random-element/pick-random-element-2.rexx
call run "Pig-the-dice-game/pig-the-dice-game.rexx
call run "Pig-the-dice-game-Player/pig-the-dice-game-player.rexx
call run "Playing-cards/playing-cards-1.rexx
call run "Playing-cards/playing-cards-2.rexx
call run "Plot-coordinate-pairs/plot-coordinate-pairs.rexx
call run "Power-set/power-set.rexx
call run "Price-fraction/price-fraction-1.rexx
call run "Price-fraction/price-fraction-2.rexx
call run "Primality-by-trial-division/primality-by-trial-division-1.rexx
call run "Primality-by-trial-division/primality-by-trial-division-2.rexx
call run "Primality-by-trial-division/primality-by-trial-division-3.rexx
call run "Prime-decomposition/prime-decomposition-1.rexx
call run "Prime-decomposition/prime-decomposition-2.rexx
call run "Priority-queue/priority-queue-1.rexx
call run "Priority-queue/priority-queue-2.rexx
call run "Probabilistic-choice/probabilistic-choice.rexx
call run "Problem-of-Apollonius/problem-of-apollonius.rexx
call run "Program-name/program-name-1.rexx
call run "Program-name/program-name-2.rexx
call run "Program-name/program-name-3.rexx
call run "Program-name/program-name-4.rexx
call run "Program-name/program-name-5.rexx
call run "Program-termination/program-termination-1.rexx
call run "Program-termination/program-termination-2.rexx
call run "Pythagorean-triples/pythagorean-triples-1.rexx
call run "Pythagorean-triples/pythagorean-triples-2.rexx
call run "Quaternion-type/quaternion-type.rexx
call run "Queue-Definition/queue-definition.rexx
call run "Queue-Usage/queue-usage.rexx
call run "Quickselect-algorithm/quickselect-algorithm-1.rexx
call run "Quickselect-algorithm/quickselect-algorithm-2.rexx
call run "Quine/quine-1.rexx
call run "Quine/quine-2.rexx
call run "Quine/quine-3.rexx
call run "Random-number-generator--device-/random-number-generator--device--1.rexx
call run "Random-number-generator--device-/random-number-generator--device--2.rexx
call run "Random-number-generator--included-/random-number-generator--included--1.rexx
call run "Random-number-generator--included-/random-number-generator--included--2.rexx
call run "Random-number-generator--included-/random-number-generator--included--3.rexx
call run "Random-numbers/random-numbers.rexx
call run "Range-expansion/range-expansion-1.rexx
call run "Range-expansion/range-expansion-2.rexx
call run "Range-extraction/range-extraction-1.rexx
call run "Range-extraction/range-extraction-2.rexx
call run "Range-extraction/range-extraction-3.rexx
call run "Ranking-methods/ranking-methods.rexx
call run "Rate-counter/rate-counter.rexx
call run "Ray-casting-algorithm/ray-casting-algorithm.rexx
call run "Read-a-configuration-file/read-a-configuration-file-1.rexx
call run "Read-a-configuration-file/read-a-configuration-file-2.rexx
call run "Read-a-configuration-file/read-a-configuration-file.rexx
call run "Read-a-file-line-by-line/read-a-file-line-by-line-1.rexx
call run "Read-a-file-line-by-line/read-a-file-line-by-line-2.rexx
call run "Read-a-file-line-by-line/read-a-file-line-by-line-3.rexx
call run "Read-a-file-line-by-line/read-a-file-line-by-line-4.rexx
call run "Read-a-specific-line-from-a-file/read-a-specific-line-from-a-file-1.rexx
call run "Read-a-specific-line-from-a-file/read-a-specific-line-from-a-file-2.rexx
call run "Read-entire-file/read-entire-file-1.rexx
call run "Read-entire-file/read-entire-file-2.rexx
call run "README
call run "Real-constants-and-functions/real-constants-and-functions-1.rexx
call run "Real-constants-and-functions/real-constants-and-functions-2.rexx
call run "Real-constants-and-functions/real-constants-and-functions-3.rexx
call run "Real-constants-and-functions/real-constants-and-functions-4.rexx
call run "Real-constants-and-functions/real-constants-and-functions-5.rexx
call run "Real-constants-and-functions/real-constants-and-functions-6.rexx
call run "Real-constants-and-functions/real-constants-and-functions-7.rexx
call run "Real-constants-and-functions/real-constants-and-functions-8.rexx
call run "Reduced-row-echelon-form/reduced-row-echelon-form.rexx
call run "Regular-expressions/regular-expressions-1.rexx
call run "Regular-expressions/regular-expressions-2.rexx
call run "Regular-expressions/regular-expressions-3.rexx
call run "Regular-expressions/regular-expressions-4.rexx
call run "Remove-duplicate-elements/remove-duplicate-elements-1.rexx
call run "Remove-duplicate-elements/remove-duplicate-elements-2.rexx
call run "Remove-duplicate-elements/remove-duplicate-elements-3.rexx
call run "Remove-duplicate-elements/remove-duplicate-elements-4.rexx
call run "Remove-lines-from-a-file/remove-lines-from-a-file.rexx
call run "Rename-a-file/rename-a-file-1.rexx
call run "Rename-a-file/rename-a-file-2.rexx
call run "Rep-string/rep-string-1.rexx
call run "Rep-string/rep-string-2.rexx
call run "Repeat-a-string/repeat-a-string.rexx
call run "Resistor-mesh/resistor-mesh.rexx
call run "Return-multiple-values/return-multiple-values.rexx
call run "Reverse-a-string/reverse-a-string-1.rexx
call run "Reverse-a-string/reverse-a-string-2.rexx
call run "Reverse-a-string/reverse-a-string-3.rexx
call run "Reverse-a-string/reverse-a-string-4.rexx
call run "Reverse-words-in-a-string/reverse-words-in-a-string-1.rexx
call run "Reverse-words-in-a-string/reverse-words-in-a-string-2.rexx
call run "Rock-paper-scissors/rock-paper-scissors-1.rexx
call run "Rock-paper-scissors/rock-paper-scissors-2.rexx
call run "Roman-numerals-Decode/roman-numerals-decode-1.rexx
call run "Roman-numerals-Decode/roman-numerals-decode-2.rexx
call run "Roman-numerals-Decode/roman-numerals-decode-3.rexx
call run "Roman-numerals-Encode/roman-numerals-encode-1.rexx
call run "Roman-numerals-Encode/roman-numerals-encode-2.rexx
call run "Roots-of-a-function/roots-of-a-function-1.rexx
call run "Roots-of-a-function/roots-of-a-function-2.rexx
call run "Roots-of-a-function/roots-of-a-function.rexx
call run "Roots-of-a-quadratic-function/roots-of-a-quadratic-function-1.rexx
call run "Roots-of-a-quadratic-function/roots-of-a-quadratic-function-2.rexx
call run "Roots-of-unity/roots-of-unity.rexx
call run "Rosetta-Code-Fix-code-tags/rosetta-code-fix-code-tags-1.rexx
call run "Rosetta-Code-Fix-code-tags/rosetta-code-fix-code-tags-2.rexx
call run "Rosetta-Code-Fix-code-tags/rosetta-code-fix-code-tags.rexx
call run "Rosetta-Code-Rank-languages-by-popularity/rosetta-code-rank-languages-by-popularity.rexx
call run "Rot-13/rot-13.rexx
call run "Run-length-encoding/run-length-encoding-1.rexx
call run "Run-length-encoding/run-length-encoding-2.rexx
call run "Run-length-encoding/run-length-encoding-3.rexx
call run "Run-length-encoding/run-length-encoding-4.rexx
call run "Runge-Kutta-method/runge-kutta-method.rexx
call run "Runtime-evaluation/runtime-evaluation.rexx
call run "Runtime-evaluation-In-an-environment/runtime-evaluation-in-an-environment.rexx
call run "S-Expressions/s-expressions.rexx
call run "Safe-addition/safe-addition.rexx
call run "Same-Fringe/same-fringe-1.rexx
call run "Same-Fringe/same-fringe-2.rexx
call run "Same-Fringe/same-fringe-3.rexx
call run "Scope-Function-names-and-labels/scope-function-names-and-labels.rexx
call run "Scope-modifiers/scope-modifiers-1.rexx
call run "Scope-modifiers/scope-modifiers-2.rexx
call run "Search-a-list/search-a-list-1.rexx
call run "Search-a-list/search-a-list-2.rexx
call run "Search-a-list/search-a-list-3.rexx
call run "Search-a-list/search-a-list-4.rexx
call run "SEDOLs/sedols.rexx
call run "Self-describing-numbers/self-describing-numbers-1.rexx
call run "Self-describing-numbers/self-describing-numbers-2.rexx
call run "Self-describing-numbers/self-describing-numbers-3.rexx
call run "Self-referential-sequence/self-referential-sequence.rexx
call run "Semiprime/semiprime-1.rexx
call run "Semiprime/semiprime-2.rexx
call run "Semordnilap/semordnilap-1.rexx
call run "Semordnilap/semordnilap-2.rexx
call run "Sequence-of-non-squares/sequence-of-non-squares.rexx
call run "Sequence-of-primes-by-Trial-Division/sequence-of-primes-by-trial-division-1.rexx
call run "Sequence-of-primes-by-Trial-Division/sequence-of-primes-by-trial-division-2.rexx
call run "Set/set.rexx
call run "Set-consolidation/set-consolidation.rexx
call run "Set-of-real-numbers/set-of-real-numbers-1.rexx
call run "Set-of-real-numbers/set-of-real-numbers-2.rexx
call run "Set-puzzle/set-puzzle.rexx
call run "Seven-sided-dice-from-five-sided-dice/seven-sided-dice-from-five-sided-dice.rexx
call run "Shell-one-liner/shell-one-liner.rexx
call run "Short-circuit-evaluation/short-circuit-evaluation.rexx
call run "Show-the-epoch/show-the-epoch.rexx
call run "Sierpinski-carpet/sierpinski-carpet.rexx
call run "Sierpinski-triangle/sierpinski-triangle.rexx
call run "Sieve-of-Eratosthenes/sieve-of-eratosthenes-1.rexx
call run "Sieve-of-Eratosthenes/sieve-of-eratosthenes-2.rexx
call run "Sieve-of-Eratosthenes/sieve-of-eratosthenes-3.rexx
call run "Sieve-of-Eratosthenes/sieve-of-eratosthenes-4.rexx
call run "Simple-database/simple-database.rexx
call run "Simulate-input-Keyboard/simulate-input-keyboard.rexx
call run "Singly-linked-list-Element-definition/singly-linked-list-element-definition.rexx
call run "Singly-linked-list-Element-insertion/singly-linked-list-element-insertion.rexx
call run "Singly-linked-list-Traversal/singly-linked-list-traversal.rexx
call run "Sleep/sleep-1.rexx
call run "Sleep/sleep-2.rexx
call run "Solve-a-Hidato-puzzle/solve-a-hidato-puzzle.rexx
call run "Solve-a-Holy-Knights-tour/solve-a-holy-knights-tour.rexx
call run "Solve-a-Hopido-puzzle/solve-a-hopido-puzzle.rexx
call run "Solve-a-Numbrix-puzzle/solve-a-numbrix-puzzle.rexx
call run "Solve-the-no-connection-puzzle/solve-the-no-connection-puzzle-1.rexx
call run "Solve-the-no-connection-puzzle/solve-the-no-connection-puzzle-2.rexx
call run "Sort-an-array-of-composite-structures/sort-an-array-of-composite-structures.rexx
call run "Sort-an-integer-array/sort-an-integer-array-1.rexx
call run "Sort-an-integer-array/sort-an-integer-array-2.rexx
call run "Sort-disjoint-sublist/sort-disjoint-sublist.rexx
call run "Sort-stability/sort-stability.rexx
call run "Sort-using-a-custom-comparator/sort-using-a-custom-comparator.rexx
call run "Sorting-algorithms-Bead-sort/sorting-algorithms-bead-sort.rexx
call run "Sorting-algorithms-Bogosort/sorting-algorithms-bogosort-1.rexx
call run "Sorting-algorithms-Bogosort/sorting-algorithms-bogosort-2.rexx
call run "Sorting-algorithms-Bubble-sort/sorting-algorithms-bubble-sort.rexx
call run "Sorting-algorithms-Cocktail-sort/sorting-algorithms-cocktail-sort-1.rexx
call run "Sorting-algorithms-Cocktail-sort/sorting-algorithms-cocktail-sort-2.rexx
call run "Sorting-algorithms-Comb-sort/sorting-algorithms-comb-sort.rexx
call run "Sorting-algorithms-Counting-sort/sorting-algorithms-counting-sort-1.rexx
call run "Sorting-algorithms-Counting-sort/sorting-algorithms-counting-sort-2.rexx
call run "Sorting-algorithms-Gnome-sort/sorting-algorithms-gnome-sort-1.rexx
call run "Sorting-algorithms-Gnome-sort/sorting-algorithms-gnome-sort-2.rexx
call run "Sorting-algorithms-Heapsort/sorting-algorithms-heapsort-1.rexx
call run "Sorting-algorithms-Heapsort/sorting-algorithms-heapsort-2.rexx
call run "Sorting-algorithms-Heapsort/sorting-algorithms-heapsort-3.rexx
call run "Sorting-algorithms-Insertion-sort/sorting-algorithms-insertion-sort.rexx
call run "Sorting-algorithms-Merge-sort/sorting-algorithms-merge-sort.rexx
call run "Sorting-algorithms-Pancake-sort/sorting-algorithms-pancake-sort.rexx
call run "Sorting-algorithms-Permutation-sort/sorting-algorithms-permutation-sort.rexx
call run "Sorting-algorithms-Quicksort/sorting-algorithms-quicksort-1.rexx
call run "Sorting-algorithms-Quicksort/sorting-algorithms-quicksort-2.rexx
call run "Sorting-algorithms-Radix-sort/sorting-algorithms-radix-sort.rexx
call run "Sorting-algorithms-Selection-sort/sorting-algorithms-selection-sort.rexx
call run "Sorting-algorithms-Shell-sort/sorting-algorithms-shell-sort.rexx
call run "Sorting-algorithms-Sleep-sort/sorting-algorithms-sleep-sort.rexx
call run "Sorting-algorithms-Stooge-sort/sorting-algorithms-stooge-sort.rexx
call run "Sorting-algorithms-Strand-sort/sorting-algorithms-strand-sort.rexx
call run "Soundex/soundex.rexx
call run "Sparkline-in-unicode/sparkline-in-unicode-1.rexx
call run "Sparkline-in-unicode/sparkline-in-unicode-2.rexx
call run "Special-characters/special-characters-1.rexx
call run "Special-characters/special-characters-10.rexx
call run "Special-characters/special-characters-11.rexx
call run "Special-characters/special-characters-12.rexx
call run "Special-characters/special-characters-13.rexx
call run "Special-characters/special-characters-14.rexx
call run "Special-characters/special-characters-15.rexx
call run "Special-characters/special-characters-16.rexx
call run "Special-characters/special-characters-17.rexx
call run "Special-characters/special-characters-18.rexx
call run "Special-characters/special-characters-19.rexx
call run "Special-characters/special-characters-2.rexx
call run "Special-characters/special-characters-20.rexx
call run "Special-characters/special-characters-3.rexx
call run "Special-characters/special-characters-4.rexx
call run "Special-characters/special-characters-5.rexx
call run "Special-characters/special-characters-6.rexx
call run "Special-characters/special-characters-7.rexx
call run "Special-characters/special-characters-8.rexx
call run "Special-characters/special-characters-9.rexx
call run "Special-variables/special-variables-1.rexx
call run "Special-variables/special-variables-2.rexx
call run "Speech-synthesis/speech-synthesis.rexx
call run "Spiral-matrix/spiral-matrix-1.rexx
call run "Spiral-matrix/spiral-matrix-2.rexx
call run "Stable-marriage-problem/stable-marriage-problem.rexx
call run "Stack/stack-1.rexx
call run "Stack/stack-2.rexx
call run "Stair-climbing-puzzle/stair-climbing-puzzle.rexx
call run "Standard-deviation/standard-deviation.rexx
call run "Start-from-a-main-routine/start-from-a-main-routine.rexx
call run "State-name-puzzle/state-name-puzzle.rexx
call run "Statistics-Basic/statistics-basic.rexx
call run "Stem-and-leaf-plot/stem-and-leaf-plot-1.rexx
call run "Stem-and-leaf-plot/stem-and-leaf-plot-2.rexx
call run "Stern-Brocot-sequence/stern-brocot-sequence.rexx
call run "String-append/string-append-1.rexx
call run "String-append/string-append-2.rexx
call run "String-case/string-case-1.rexx
call run "String-case/string-case-2.rexx
call run "String-case/string-case-3.rexx
call run "String-case/string-case-4.rexx
call run "String-case/string-case-5.rexx
call run "String-case/string-case-6.rexx
call run "String-case/string-case-7.rexx
call run "String-case/string-case-8.rexx
call run "String-comparison/string-comparison-1.rexx
call run "String-comparison/string-comparison-2.rexx
call run "String-concatenation/string-concatenation.rexx
call run "String-interpolation--included-/string-interpolation--included-.rexx
call run "String-length/string-length.rexx
call run "String-matching/string-matching.rexx
call run "String-prepend/string-prepend.rexx
call run "Strip-a-set-of-characters-from-a-string/strip-a-set-of-characters-from-a-string-1.rexx
call run "Strip-a-set-of-characters-from-a-string/strip-a-set-of-characters-from-a-string-2.rexx
call run "Strip-a-set-of-characters-from-a-string/strip-a-set-of-characters-from-a-string-3.rexx
call run "Strip-a-set-of-characters-from-a-string/strip-a-set-of-characters-from-a-string-4.rexx
call run "Strip-a-set-of-characters-from-a-string/strip-a-set-of-characters-from-a-string-5.rexx
call run "Strip-block-comments/strip-block-comments.rexx
call run "Strip-comments-from-a-string/strip-comments-from-a-string-1.rexx
call run "Strip-comments-from-a-string/strip-comments-from-a-string-2.rexx
call run "Strip-control-codes-and-extended-characters-from-a-string/strip-control-codes-and-extended-characters-from-a-string-1.rexx
call run "Strip-control-codes-and-extended-characters-from-a-string/strip-control-codes-and-extended-characters-from-a-string-2.rexx
call run "Strip-whitespace-from-a-string-Top-and-tail/strip-whitespace-from-a-string-top-and-tail-1.rexx
call run "Strip-whitespace-from-a-string-Top-and-tail/strip-whitespace-from-a-string-top-and-tail-2.rexx
call run "Substring/substring.rexx
call run "Substring-Top-and-tail/substring-top-and-tail-1.rexx
call run "Substring-Top-and-tail/substring-top-and-tail-2.rexx
call run "Substring-Top-and-tail/substring-top-and-tail-3.rexx
call run "Subtractive-generator/subtractive-generator.rexx
call run "Sum-and-product-of-an-array/sum-and-product-of-an-array.rexx
call run "Sum-digits-of-an-integer/sum-digits-of-an-integer-1.rexx
call run "Sum-digits-of-an-integer/sum-digits-of-an-integer-2.rexx
call run "Sum-digits-of-an-integer/sum-digits-of-an-integer-3.rexx
call run "Sum-multiples-of-3-and-5/sum-multiples-of-3-and-5-1.rexx
call run "Sum-multiples-of-3-and-5/sum-multiples-of-3-and-5-2.rexx
call run "Sum-multiples-of-3-and-5/sum-multiples-of-3-and-5-3.rexx
call run "Sum-of-a-series/sum-of-a-series-1.rexx
call run "Sum-of-a-series/sum-of-a-series-2.rexx
call run "Sum-of-a-series/sum-of-a-series-3.rexx
call run "Sum-of-squares/sum-of-squares-1.rexx
call run "Sum-of-squares/sum-of-squares-2.rexx
call run "Symmetric-difference/symmetric-difference-1.rexx
call run "Symmetric-difference/symmetric-difference-2.rexx
call run "Symmetric-difference/symmetric-difference-3.rexx
call run "System-time/system-time.rexx
call run "Table-creation-Postal-addresses/table-creation-postal-addresses-1.rexx
call run "Table-creation-Postal-addresses/table-creation-postal-addresses-2.rexx
call run "Table-creation-Postal-addresses/table-creation-postal-addresses-3.rexx
call run "Take-notes-on-the-command-line/take-notes-on-the-command-line.rexx
call run "Temperature-conversion/temperature-conversion.rexx
call run "Terminal-control-Clear-the-screen/terminal-control-clear-the-screen.rexx
call run "Terminal-control-Coloured-text/terminal-control-coloured-text.rexx
call run "Terminal-control-Cursor-movement/terminal-control-cursor-movement.rexx
call run "Terminal-control-Cursor-positioning/terminal-control-cursor-positioning.rexx
call run "Terminal-control-Dimensions/terminal-control-dimensions-1.rexx
call run "Terminal-control-Dimensions/terminal-control-dimensions-2.rexx
call run "Terminal-control-Dimensions/terminal-control-dimensions-3.rexx
call run "Terminal-control-Display-an-extended-character/terminal-control-display-an-extended-character.rexx
call run "Terminal-control-Hiding-the-cursor/terminal-control-hiding-the-cursor.rexx
call run "Terminal-control-Inverse-video/terminal-control-inverse-video.rexx
call run "Terminal-control-Positional-read/terminal-control-positional-read.rexx
call run "Terminal-control-Preserve-screen/terminal-control-preserve-screen.rexx
call run "Terminal-control-Ringing-the-terminal-bell/terminal-control-ringing-the-terminal-bell.rexx
call run "Ternary-logic/ternary-logic.rexx
call run "Test-a-function/test-a-function-1.rexx
call run "Test-a-function/test-a-function-2.rexx
call run "Text-processing-1/text-processing-1.rexx
call run "Text-processing-2/text-processing-2.rexx
call run "Text-processing-Max-licenses-in-use/text-processing-max-licenses-in-use-1.rexx
call run "Text-processing-Max-licenses-in-use/text-processing-max-licenses-in-use-2.rexx
call run "Textonyms/textonyms.rexx
call run "The-ISAAC-Cipher/the-isaac-cipher-1.rexx
call run "The-ISAAC-Cipher/the-isaac-cipher-2.rexx
call run "The-Twelve-Days-of-Christmas/the-twelve-days-of-christmas.rexx
call run "Tic-tac-toe/tic-tac-toe.rexx
call run "Time-a-function/time-a-function-1.rexx
call run "Time-a-function/time-a-function-2.rexx
call run "Tokenize-a-string/tokenize-a-string-1.rexx
call run "Tokenize-a-string/tokenize-a-string-2.rexx
call run "Top-rank-per-group/top-rank-per-group-1.rexx
call run "Top-rank-per-group/top-rank-per-group-2.rexx
call run "Topic-variable/topic-variable.rexx
call run "Topological-sort/topological-sort.rexx
call run "Topswops/topswops.rexx
call run "Total-circles-area/total-circles-area-1.rexx
call run "Total-circles-area/total-circles-area-2.rexx
call run "Towers-of-Hanoi/towers-of-hanoi-1.rexx
call run "Towers-of-Hanoi/towers-of-hanoi-2.rexx
call run "Trabb-Pardo-Knuth-algorithm/trabb-pardo-knuth-algorithm.rexx
call run "Tree-traversal/tree-traversal.rexx
call run "Trigonometric-functions/trigonometric-functions-1.rexx
call run "Trigonometric-functions/trigonometric-functions-2.rexx
call run "Trigonometric-functions/trigonometric-functions-3.rexx
call run "Truncatable-primes/truncatable-primes.rexx
call run "Truncate-a-file/truncate-a-file-1.rexx
call run "Truncate-a-file/truncate-a-file-2.rexx
call run "Twelve-statements/twelve-statements-1.rexx
call run "Twelve-statements/twelve-statements-2.rexx
call run "Twelve-statements/twelve-statements-3.rexx
call run "Ulam-spiral--for-primes-/ulam-spiral--for-primes--1.rexx
call run "Ulam-spiral--for-primes-/ulam-spiral--for-primes--2.rexx
call run "Unbias-a-random-generator/unbias-a-random-generator.rexx
call run "Undefined-values/undefined-values.rexx
call run "Unicode-variable-names/unicode-variable-names.rexx
call run "Universal-Turing-machine/universal-turing-machine-1.rexx
call run "Universal-Turing-machine/universal-turing-machine-2.rexx
call run "Universal-Turing-machine/universal-turing-machine-3.rexx
call run "Universal-Turing-machine/universal-turing-machine-4.rexx
call run "Unix-ls/unix-ls.rexx
call run "Update-a-configuration-file/update-a-configuration-file-1.rexx
call run "Update-a-configuration-file/update-a-configuration-file-2.rexx
call run "URL-decoding/url-decoding-1.rexx
call run "URL-decoding/url-decoding-2.rexx
call run "URL-decoding/url-decoding-3.rexx
call run "URL-encoding/url-encoding-1.rexx
call run "URL-encoding/url-encoding-2.rexx
call run "User-input-Text/user-input-text.rexx
call run "Vampire-number/vampire-number.rexx
call run "Van-der-Corput-sequence/van-der-corput-sequence-1.rexx
call run "Van-der-Corput-sequence/van-der-corput-sequence-2.rexx
call run "Variable-length-quantity/variable-length-quantity.rexx
call run "Variable-size-Get/variable-size-get.rexx
call run "Variable-size-Set/variable-size-set.rexx
call run "Variables/variables-1.rexx
call run "Variables/variables-2.rexx
call run "Variables/variables-3.rexx
call run "Variables/variables-4.rexx
call run "Variables/variables-5.rexx
call run "Variables/variables-6.rexx
call run "Variables/variables-7.rexx
call run "Variables/variables-8.rexx
call run "Variadic-function/variadic-function-1.rexx
call run "Variadic-function/variadic-function-2.rexx
call run "Variadic-function/variadic-function-3.rexx
call run "Vector-products/vector-products.rexx
call run "Verify-distribution-uniformity-Naive/verify-distribution-uniformity-naive.rexx
call run "Video-display-modes/video-display-modes-1.rexx
call run "Video-display-modes/video-display-modes-2.rexx
call run "Vigen-re-cipher/vigen-re-cipher-1.rexx
call run "Vigen-re-cipher/vigen-re-cipher-2.rexx
call run "Visualize-a-tree/visualize-a-tree.rexx
call run "Walk-a-directory-Non-recursively/walk-a-directory-non-recursively.rexx
call run "Walk-a-directory-Recursively/walk-a-directory-recursively-1.rexx
call run "Walk-a-directory-Recursively/walk-a-directory-recursively-2.rexx
call run "Wireworld/wireworld.rexx
call run "Word-wrap/word-wrap-1.rexx
call run "Word-wrap/word-wrap-2.rexx
call run "Word-wrap/word-wrap-3.rexx
call run "Write-float-arrays-to-a-text-file/write-float-arrays-to-a-text-file.rexx
call run "Write-language-name-in-3D-ASCII/write-language-name-in-3d-ascii-1.rexx
call run "Write-language-name-in-3D-ASCII/write-language-name-in-3d-ascii-2.rexx
call run "Write-language-name-in-3D-ASCII/write-language-name-in-3d-ascii-3.rexx
call run "Write-to-Windows-event-log/write-to-windows-event-log.rexx
call run "Xiaolin-Wus-line-algorithm/xiaolin-wus-line-algorithm.rexx
call run "XML-Input/xml-input-1.rexx
call run "XML-Input/xml-input-2.rexx
call run "XML-Input/xml-input-3.rexx
call run "XML-Output/xml-output.rexx
call run "XML-XPath/xml-xpath-1.rexx
call run "XML-XPath/xml-xpath-2.rexx
call run "Y-combinator/y-combinator.rexx
call run "Yin-and-yang/yin-and-yang.rexx
call run "Zebra-puzzle/zebra-puzzle.rexx
call run "Zeckendorf-number-representation/zeckendorf-number-representation-1.rexx
call run "Zeckendorf-number-representation/zeckendorf-number-representation-2.rexx
call run "Zeckendorf-number-representation/zeckendorf-number-representation-3.rexx
call run "Zero-to-the-zero-power/zero-to-the-zero-power.rexx
call run "Zhang-Suen-thinning-algorithm/zhang-suen-thinning-algorithm.rexx
call run "Zig-zag-matrix/zig-zag-matrix.rexx
*/

return


/*
Regina documentation:
UPPER is not part of the ANSI standard and is not common in other interpreters so should be avoided.
It is provided to ease porting of programs from CMS.
*/

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