/*
The current implementation for name matching is optimized regarding the comparison
of two names, but rather naive regarding in which order the names are compared.
I did not use an hash table because the matching can be made on a subset of the characters.

The optimal order is when the caller pass the named arguments in the same order as the names declared by the callee.
Once a name has been matched, it''s skipped when searching other matchings.

The worst order is when the caller pass the named arguments in the opposite order of the names declared by the callee.

-- Optimal case
-- For a total of 15 combinations, only 5 name comparisons are needed
use name arg N1, N2, N3, N4, N5
f(n1:1, n2:2, n3:3, n4:4, n5:5)
n1 N1 	compare --> matched
n2 N1	skip
n2 N2	compare --> matched
n3 N1	skip
n3 N2	skip
n3 N3	compare --> matched
n4 N1	skip
n4 N2	skip
n4 N3	skip
n4 N4	compare --> matched
n5 N1	skip
n5 N2	skip
n5 N3	skip
n5 N4	skip
n5 N5	compare --> matched

-- Worst case
-- For a total of 15 combinations, 15 name comparisons are needed
f(n5:1, n4:2, n:3, n2:4, n1:5)
n5 N1   compare
n5 N2   compare
n5 N3   compare
n5 N4   compare
n5 N5	compare --> matched
n4 N1   compare
n4 N2   compare
n4 N3   compare
n4 N4	compare --> matched
n3 N1   compare
n3 N2   compare
n3 N3	compare --> matched
n2 N1   compare
n2 N2	compare --> matched
n1 N1	compare --> matched

*/

use arg n=100000
say n "calls"

width1 = 20

----------------------------- positional arguments -----------------------------

call time('r')
do n
    call positional
end
positional = time('e')~format(2,2)
say "positional="~left(width1) positional


--------------------------------- short names ----------------------------------

call time('r')
do n
    call optimalCallShortNames
end
optimal = time('e')~format(2,2)
say "optimal short names="~left(width1) optimal


call time('r')
do n
    call worstCallShortNames
end
worst = time('e')~format(2,2)
say "worst short names="~left(width1) worst


ratio = (worst/optimal)~format(2,2)
say "ratio short names="~left(width1) ratio


---------------------------------- long names ----------------------------------

call time('r')
do n
    call optimalCallLongNames
end
optimal = time('e')~format(2,2)
say "optimal long names="~left(width1) optimal


call time('r')
do n
    call worstCallLongNames
end
worst = time('e')~format(2,2)
say "worst long names="~left(width1) worst


ratio = (worst/optimal)~format(2,2)
say "ratio long names="~left(width1) ratio


--------------------------------------------------------------------------------

::routine callPositional
    call positional,
        1,,
        2,,
        3,,
        4,,
        5,,
        6,,
        7,,
        8,,
        9,,
        10,,
        11,,
        12,,
        13,,
        14,,
        15


::routine optimalCallShortNames
    call shortNames,
        a: 1,,
        b: 2,,
        c: 3,,
        d: 4,,
        e: 5,,
        f: 6,,
        g: 7,,
        h: 8,,
        i: 9,,
        j: 10,,
        k: 11,,
        l: 12,,
        m: 13,,
        n: 14,,
        o: 15


::routine optimalCallLongNames
    call longNames,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01: 1,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ02: 2,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ03: 3,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ04: 4,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ05: 5,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ06: 6,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ07: 7,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ08: 8,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ09: 9,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0A: 10,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0B: 11,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0C: 12,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0D: 13,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0E: 14,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0F: 15


::routine worstCallShortNames
    call shortNames,
        o: 15,,
        n: 14,,
        m: 13,,
        l: 12,,
        k: 11,,
        j: 10,,
        i: 9,,
        h: 8,,
        g: 7,,
        f: 6,,
        e: 5,,
        d: 4,,
        c: 3,,
        b: 2,,
        a: 1


::routine worstCallLongNames
    call longNames,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0F: 15,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0E: 14,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0D: 13,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0C: 12,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0B: 11,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0A: 10,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ09: 9,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ08: 8,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ07: 7,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ06: 6,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ05: 5,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ04: 4,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ03: 3,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ02: 2,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01: 1


--------------------------------------------------------------------------------

::routine positional -- the length of the argument names has no impact
use arg,
        a,,
        b,,
        c,,
        d,,
        e,,
        f,,
        g,,
        h,,
        i,,
        j,,
        k,,
        l,,
        m,,
        n,,
        o


::routine shortNames
use named arg,
        a,,
        b,,
        c,,
        d,,
        e,,
        f,,
        g,,
        h,,
        i,,
        j,,
        k,,
        l,,
        m,,
        n,,
        o


::routine longNames
use named arg,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ02,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ03,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ04,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ05,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ06,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ07,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ08,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ09,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0A,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0B,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0C,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0D,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0E,,
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0F
