-- A kind of backtrack à la Prolog...
-- See also http://www.cs.arizona.edu/icon/intro.htm

c = 20~times.generate{
    say
    call charout , "Produce "item". "
    item
}

c = c~select{
    call charout , "Select item "item" ? "
    select = item // 3 == 0
    if select then call charout , "yes. " ; else call charout , "no. "
    return select
}

c = c~reject{
    call charout , "Reject item "item" ? "
    reject = item // 2 == 1
    if reject then call charout , "yes. " ; else call charout , "no. "
    return reject
}

c = c~each{
    say "-->" item
}

say c~statusText -- not started
do until c~isEnded
    say
    say "-----"
    say "c~do"
    c~do
end
say
say c~statusText -- ended

::requires "extension/extensions.cls"

/*
not started

-----
c~do

Produce 1. Select item 1 ? no.
Produce 2. Select item 2 ? no.
Produce 3. Select item 3 ? yes. Reject item 3 ? yes.
Produce 4. Select item 4 ? no.
Produce 5. Select item 5 ? no.
Produce 6. Select item 6 ? yes. Reject item 6 ? no. --> 6

Produce 7. Select item 7 ? no.
Produce 8. Select item 8 ? no.
Produce 9. Select item 9 ? yes. Reject item 9 ? yes.
Produce 10. Select item 10 ? no.
Produce 11. Select item 11 ? no.
Produce 12. Select item 12 ? yes. Reject item 12 ? no. --> 12

Produce 13. Select item 13 ? no.
Produce 14. Select item 14 ? no.
Produce 15. Select item 15 ? yes. Reject item 15 ? yes.
Produce 16. Select item 16 ? no.
Produce 17. Select item 17 ? no.
Produce 18. Select item 18 ? yes. Reject item 18 ? no. --> 18

Produce 19. Select item 19 ? no.
Produce 20. Select item 20 ? no.
ended
*/
