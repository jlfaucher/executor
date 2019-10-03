say "Generation without index of all natural numbers : 1 2 3 ..."
g=0~generate{item+1}~recursive
do 10; say g~(); end
say "..."
say


say "Generator : provide the option ~stack for a better control of the stack size in case of recursion."
say "Before the change, the stack size was arbitrarily 3 when the option 'cycles' was not used."
say "Now the default stack size is 0. That brings a little optimization."
say

count1 = 6
count2 = 1000
call charout , "stack(0):   "; call run count1, {expose count2; g=0~generate{depth}~stack(0)~recursive("b"); do count2; g~(); end}
call charout , "stack(1):   "; call run count1, {expose count2; g=0~generate{depth}~stack(1)~recursive("b"); do count2; g~(); end}
call charout , "stack(2):   "; call run count1, {expose count2; g=0~generate{depth}~stack(2)~recursive("b"); do count2; g~(); end}
call charout , "stack(3):   "; call run count1, {expose count2; g=0~generate{depth}~stack(3)~recursive("b"); do count2; g~(); end}
call charout , "stack(10):  "; call run count1, {expose count2; g=0~generate{depth}~stack(10)~recursive("b"); do count2; g~(); end}
call charout , "stack(100): "; call run count1, {expose count2; g=0~generate{depth}~stack(100)~recursive("b"); do count2; g~(); end}
say


say "Generation with index and stack(0) of all natural numbers : 1 2 3 ..."
g=0~generateI{item+1}~recursive
do 10; say g~()~ppRepresentation; end
say "..."
say


say "Generation with index and stack(1) of all natural numbers : 1 2 3 ..."
g=0~generateI{item+1}~recursive~stack(1)
do 10; say g~()~ppRepresentation; end
say "..."
say


say "Generation with index and stack(2) of all natural numbers : 1 2 3 ..."
g=0~generateI{item+1}~recursive~stack(2)
do 10; say g~()~ppRepresentation; end
say "..."
say


say "Generation with index and stack(3) of all natural numbers : 1 2 3 ..."
g=0~generateI{item+1}~recursive~stack(3)
do 10; say g~()~ppRepresentation; end
say "..."
say


say "Generation with index and unlimited stack of all natural numbers : 1 2 3 ..."
g=0~generateI{item+1}~recursive("cycles")
do 10; say g~()~ppRepresentation; end
say "..."
say

-------------------------------------------------------------------------------

say "Illustration of depthFirst (default) vs breadthFirst"
say "one two three"~generateW{if depth == 0 then item; else if item <> "" then item~substr(2)}~recursive~makeArray~ppRepresentation                     -- ['one','ne','e','','two','wo','o','','three','hree','ree','ee','e','']
say "one two three"~generateW{if depth == 0 then item; else if item <> "" then item~substr(2)}~recursive("breadthFirst")~makeArray~ppRepresentation     -- ['one','two','three','ne','wo','hree','e','o','ree','','','ee','e','']
say

say "Factorial"
say 1~times.generate~reduce("*")        -- 1
say 2~times.generate~reduce("*")        -- 2
say 3~times.generate~reduce("*")        -- 6
-- ...
say 100~times.generate~reduce("*")      -- 9.33262137E+157
say

say "*NAIVE* generation of factorials from 0"
g=(-1)~generate{item+1}~recursive~each{.array~of(item~times.generate~reduce(1, "*"), item)}
g~take(10)~iterator~each{say item[2]"! =" item[1]}
say

say "Less naive generation of factorials from 0"
g=0~generateI{if item == 0 then 1; else stack[1] * depth}~recursive~stack(1)    -- must allocate a stack otherwise error because stack == .nil
g~take(10)~iterator~each{say item[3]"! =" item[1]}
say

say "Collect all items in an array and then generate each array's item one by one (you don't get the first item immediatly)"
g=100000~times~generate{2*item}
do 100; call charout , g~(); end
say
say

say "Generate directly each item one by one (you get the first item immediatly)"
g=100000~times.generate{2*item}
do 100; call charout , g~(); end
say
say

-------------------------------------------------------------------------------

say "Generator : don't yield when no result if this is the last yield before end."
say "This is similar to the behavior of Coactivity, see yieldLast."
say "Not applicable when iterating over a supplier (options iterateBefore, iterateAfter)."
say

say "applicable: the last execution returns no result, we are not iterating over a supplier"
say 1~generate{}~iterator~each~ppRepresentation                          -- empty array instead of [.nil]
say

say "not applicable: we are iterating over a supplier. For 2 and 4, there was a yield of 'no result', and the last one is not discarded."
say 1~4~generate{if item//2=1 then item}~iterator~each~ppRepresentation  -- [1,(The NIL object),3,(The NIL object)]
say

say "This decision was taken while playing with executor to see how to split a string in substrings of 3 characters."
say "The string below, when encoded in UTF-8, is made of 3 bytes per character."
say "Before applying the change, the first one-liner returned an array of 8 items, because the last one was .nil (because of the last yield)."
say "After the change, both one-liners return ['こ','ん','に','ち','は','世','界']"
say

say 'こんにちは世界'~generate{if depth==0 then item; else do; item = item~substr(4); if item <> "" then item; end}~recursive~each{item~left(3)}~iterator~each~ppRepresentation
say 'こんにちは世界'~pipe{{::co expose item; loop while item <> "";call yield item~left(3); item=item~substr(4);end}}~iterator~each~ppRepresentation
say

-------------------------------------------------------------------------------

say "Ended coactivities:" .Coactivity~endAll

-------------------------------------------------------------------------------

::routine run
    use strict arg count, doer
    call time('r')
    call runN count, doer
    mean = time('e')/count
    say "    mean="mean~format(2,4)

::routine runN
    use strict arg count, doer
    do count
        call time('r')
        doer~()
        call charout ,time('e')~format(2,4)" "
    end


::requires "extension/extensions.cls"
::requires "pipeline/pipe_extension.cls"

