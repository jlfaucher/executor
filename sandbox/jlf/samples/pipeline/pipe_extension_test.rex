call evaluate "demonstration"

--::options trace i
::routine demonstration

--- Strange... without this instruction, I don't get the first comments
nop

-- The coactivity yields two results.
-- The hello outputs are not in the pipeline flow (not displayed by the .displayer).
.coactivity~new{echo hello ; .yield[a] ; say hello ; .yield[b]}~pipe(.upper|.displayer)


-- A collection can be sorted by value (default)
.array~of(b, a, c)~pipe(.sort byValue | .displayer)


-- ...or by index
.array~of(b, a, c)~pipe(.sort byIndex | .displayer)


-- ...ascending (default)
-- The order of options is important : a value option is impacted only by the preceding options
-- This is because several value options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort ascending byValue | .displayer)


-- ...descending
.array~of(b, a, c)~pipe(.sort descending byValue | .displayer)


-- ...by index descending
-- The order of options is important : an index option is impacted only by the preceding options.
-- This is because several index options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort descending byIndex | .displayer)


-- ...caseless (stable by default)
.array~of("bb", "AA", "bB", "Aa", "Bb", "aA", "BB", "aa")~pipe(.sort caseless byValue | .displayer)


-- ...caseless quickSort (unstable)
.array~of("bb", "AA", "bB", "Aa", "Bb", "aA", "BB", "aa")~pipe(.sort caseless quickSort byValue | .displayer)


-- Sort descending with a comparator.
-- The DescendingComparator use the default CompareTo, which is made on values.
.array~of(b, a, c)~pipe(.sortWith[.DescendingComparator~new] | .displayer)


-- Sort by column with a comparator.
.array~of("c:2", "b:2", "A:2", "c:1", "a:1", "B:1", "C:3")~pipe(,
    .sortWith[.InvertingComparator~new(.CaselessColumnComparator~new(3,1))] |,
    .sortWith[.CaselessColumnComparator~new(1,1)] |,
    .displayer,
    )


-- Do something for each item (no returned value).
.array~of(1, 2, 3)~pipe(.do {say 'value='value 'index='index} | .displayer)


-- Do something for each item (the returned result replaces the item's value).
.array~of(1, 2, 3)~pipe(.do {return 2*value} | .displayer)


-- Inject a value for each item (the returned value is appended). 
-- The index of the injected value is pushed on the current index.
.array~of(1, 2, 3)~pipe(.inject {value*10} pushIndex append | .displayer)


-- Inject two values for each item (each item of the returned collection is written in the pipe).
.array~of(1, 2, 3)~pipe(.inject {.array~of(value*10, value*20)} pushIndex append | .displayer)


-- Each injected value can be used as input to inject a new value, recursively.
-- The default order is depth-first.
-- If the recursion is infinite, must specify a limit (here 0, 1 and 2).
-- The option 'append' is not used, so the initial value is discarded.
.array~of(1, 2, 3)~pipe(.inject {value*10} pushIndex recursive.0 | .displayer)
.array~of(1, 2, 3)~pipe(.inject {value*20} pushIndex recursive.1| .displayer)
.array~of(1, 2, 3)~pipe(.inject {value*30} pushIndex recursive.2 | .displayer)


-- Factorial, no value injected for -1
-- The option 'pushIndex' is not used, so the index remains made of one value.
.array~of(-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)~pipe(.inject {
    use arg n
    if n < 0 then return
    if n == 0 then return 1
    return n * .context~executable~call(n - 1)} | .displayer)


-- Select files whose name contains "rexx" in c:\program files\oorexx
.file~new("c:\program files\oorexx")~listFiles~pipe(,
    .select {value~name~caselessPos('rexx') <> 0} |,
    .displayer,
    )


-- Select files whose name contains "rexx" in c:\program files\oorexx, sorted by file size.
-- The "length" message is sent to the value.
.file~new("c:\program files\oorexx")~listFiles~pipe(,
    .select {value~name~caselessPos('rexx') <> 0} |,
    .sortWith[.MessageComparator~new("length/N")] |,
    .displayer,
    )


-- Same as above, but simpler... You can sort directly by length, no need of MessageComparator
.file~new("c:\program files\oorexx")~listFiles~pipe(,
    .select {value~name~caselessPos('rexx') <> 0} |,
    .sort {value~length} |,
    .displayer,
    )


-- Sort by file size, then by file extension (with only one .sort pipestage)
.file~new("c:\program files\oorexx")~listFiles~pipe(,
    .select {value~name~caselessPos('rexx') <> 0} |,
    .sort {value~length} {filespec('e', value~name)} |,
    .displayer,
    )


-- All instance methods of the context.
-- Notice that the default sort by value is useless here... Must sort by index.
.context~instanceMethods~pipe(.sort byIndex | .displayer)


-- All private methods of the context.
.context~instanceMethods~pipe(,
    .select {value~isPrivate} |,
    .sort byIndex |,
    .displayer,
    )


-- Instance methods of the specified classes (not including those inherited).
-- Each class is written in the pipeline (option append), followed by the returned methods.
-- The option pushIndex lets have the name of the method in the index.
.array~of(.RexxContext, .Package, .Method)~pipe(,
    .inject {value~instanceMethods(value~class)} append pushIndex |,
    .sort byIndex |,
    .displayer,
    )


-- Methods (not inherited) of all the classes whose id starts with "R".
.environment~pipe(,
    .select {value~isA(.class)} |,
    .select {value~id~caselessAbbrev('R') <> 0} |,
    .inject {value~methods(value)} append pushIndex |,
    .sort byIndex |,
    .displayer,
    )


-- All packages that are visible from current context, including the current package (source of the pipeline).
.context~package~pipe(,
    .inject {value~importedPackages} recursive append pushIndex |,
    .displayer index.15,
               {'    '~copies(index~items)},
               {.file~new(value~name)~name},
               newline,
    )


-- Same as above, but in breadth-first order
.context~package~pipe(,
    .inject {value~importedPackages} recursive.breadthFirst append pushIndex |,
    .displayer index.15,
               {'    '~copies(index~items)},
               {.file~new(value~name)~name},
               newline,
    )


-- The .take pipeStage lets stop the preceding pipeStages when the number of items to take
-- has been reached, whatever its position in the pipeline.
supplier = .array~of(1,2,3,4,5,6,7,8,9)~supplier
supplier~pipe(.displayer "2*" value "=" | .do {return 2*value} | .take 2 | .displayer value newline)
say supplier~index
supplier~pipe(.displayer "4*" value "=" | .do {return 4*value} | .take 4 | .displayer value newline)
say supplier~index


-- Display the 4 first sorted items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.sort | .take 4 | .displayer)


-- Sort the 4 first items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.take 4 | .sort | .displayer)


-- The .append pipeStage copies items from its primary input to its primary output, and then invokes
-- the supplier passed as argument and writes the items produced by that supplier to its primary output.
supplier1 = .array~of(1,2,3,4,5,6,7,8,9)~supplier
supplier2 = .array~of(10,11,12,13,14,15,16,17,18,19)~supplier
-- The first .take limits supplier1 to 2 items.
-- The second .take sees the two items produced by supplier1, so only 3 items are accepted from supplier2.
supplier1~pipe(.take 2 | .append supplier2 | .take 5 | .displayer)
say supplier1~index
say supplier2~index
supplier1~pipe(.take 4 | .append supplier2 | .take 9 | .displayer)
say supplier1~index
say supplier2~index


-- Remove header and footer
.array~of("header", 1, 2 ,3 , "footer")~pipe(.drop first | .drop last | .displayer)


-- The *.txt files of ooRexx
"c:\program files\oorexx"~pipe(,
    .fileTree recursive |,
    .select {filespec('e', value~name) == 'txt'} |,
    .displayer,
    )


-- Alphanumeric words of 15+ chars found in the *.txt files of ooRexx.
--
-- Exemple of result :
-- 1|c:\program files\oorexx\CPLv1.0.txt|149|8 : appropriateness
-- "appropriateness" is the 8th word of the 149th line of the file  
-- "c:\program files\oorexx\CPLv1.0.txt"
--
-- To investigate : I get sometimes a crash in the sort.
--
"c:\program files\oorexx"~pipe(,
    .fileTree recursive |,
    .select {filespec('e', value~name) == 'txt'} |,
    .getFiles | .words | .select {value~datatype('a') & value~length >= 15} |,
    .sort caseless | .displayer,
    )


-------------------------------------------------------------------------------
-- Don't know if I can do better... Spaghetti code because of error management.
-- I wanted to use "call on" but "call on syntax" is not supported.
::routine evaluate
    use strict arg evaluate_routineName
    evaluate_routine = .context~package~findRoutine(evaluate_routineName)
    evaluate_routineSource = evaluate_routine~source
    evaluate_curly_bracket_count = 0
    evaluate_string = ""
    evaluate_clause_separator = ""
    evaluate_supplier = evaluate_routineSource~supplier
    loop:
        if \ evaluate_supplier~available then return
        evaluate_sourceline = evaluate_supplier~item
        if evaluate_sourceline~strip~left(3) == "---" then nop -- Comments starting with 3 '-' are removed
        else if evaluate_sourceline~strip == "nop" then nop -- nop is a workaround to get the first comments
        else if evaluate_sourceline~strip~left(2) == "--" then say evaluate_sourceline -- Comments starting with 2 '-' are kept
        else if evaluate_sourceline~strip == "" then say
        else do
            say evaluate_sourceline
            evaluate_curly_bracket_count += evaluate_sourceline~countStr("{") - evaluate_sourceline~countStr("}")
            if evaluate_sourceline~right(1) == "," then do
                evaluate_string ||= evaluate_clause_separator || evaluate_sourceline~left(evaluate_sourceline~length - 1)
                evaluate_clause_separator = ""
            end
            else if evaluate_curly_bracket_count > 0 then do
                evaluate_string ||= evaluate_clause_separator || evaluate_sourceline
                evaluate_clause_separator = "; "
            end
            else if evaluate_curly_bracket_count == 0 then do
                evaluate_string ||= evaluate_clause_separator || evaluate_sourceline
                evaluate_clause_separator = ""
                signal on syntax
                interpret evaluate_string
                evaluate_string = ""
            end
        end
    iterate:
        evaluate_supplier~next
    signal loop
syntax:
    say "*** got an error :" condition("O")~message
    evaluate_string = ""
    signal iterate


::requires "extension/extensions.cls"
::requires "concurrency/coactivity.cls"
::requires "pipeline/pipe_extension.cls"
::requires "rgf_util2/rgf_util2_wrappers"
