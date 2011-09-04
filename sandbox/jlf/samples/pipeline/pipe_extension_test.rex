call evaluate "demonstration"

--::options trace i
::routine demonstration

--- Strange... without this instruction, I don't get the first comments
nop

-- The coactivity yields two results.
-- The hello outputs are not in the pipeline flow (not displayed by the .console).
{::c echo hello ; .yield[a] ; say hello ; .yield[b] }~doer~pipe(.upper|.console)


-- A collection can be sorted by value (default)
.array~of(b, a, c)~pipe(.sort byValue | .console)


-- ...or by index
.array~of(b, a, c)~pipe(.sort byIndex | .console)


-- ...ascending (default)
-- The order of options is important : a value option is impacted only by the preceding options
-- This is because several value options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort ascending byValue | .console)


-- ...descending
.array~of(b, a, c)~pipe(.sort descending byValue | .console)


-- ...by index descending
-- The order of options is important : an index option is impacted only by the preceding options.
-- This is because several index options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort descending byIndex | .console)


-- ...caseless (stable by default)
.array~of("bb", "AA", "bB", "Aa", "Bb", "aA", "BB", "aa")~pipe(.sort caseless byValue | .console)


-- ...caseless quickSort (unstable)
-- No difference bewteen stable and unstable ? yes, see commit 6275 in interpreter/memory/setup.cpp :
--  // there have been some problems with the quick sort used as the default sort, so map everything
--  // to the stable sort.  The stable sort, in theory, uses more memory, but in practice, this is not true.
--  defineKernelMethod(CHAR_SORT         ,TheArrayBehaviour, CPPM(RexxArray::stableSortRexx), 0);
--  defineKernelMethod(CHAR_SORTWITH     ,TheArrayBehaviour, CPPM(RexxArray::stableSortWithRexx), 1);
--  defineKernelMethod(CHAR_STABLESORT   ,TheArrayBehaviour, CPPM(RexxArray::stableSortRexx), 0);
--  defineKernelMethod(CHAR_STABLESORTWITH ,TheArrayBehaviour, CPPM(RexxArray::stableSortWithRexx), 1);
.array~of("bb", "AA", "bB", "Aa", "Bb", "aA", "BB", "aa")~pipe(.sort caseless quickSort byValue | .console)


-- Sort descending with a comparator.
-- The DescendingComparator use the default CompareTo, which is made on values.
.array~of(b, a, c)~pipe(.sortWith[.DescendingComparator~new] | .console)


-- Sort by column with a comparator.
.array~of("c:2", "b:2", "A:2", "c:1", "a:1", "B:1", "C:3")~pipe(,
    .sortWith[.InvertingComparator~new(.CaselessColumnComparator~new(3,1))] |,
    .sortWith[.CaselessColumnComparator~new(1,1)] |,
    .console,
    )


-- Do something for each item (no returned value).
.array~of(1, , 2, , 3)~pipe(.do {say 'value='value 'index='.console~arrayToString(index)} | .console)


-- Do something for each item (the returned result replaces the item's value).
-- Note : the index created by .do is a pair (value, resultIndex) where
--     value is the processed value.
--     resultIndex is the index of the current result calculated with value.
-- Here, only one result is calculated for a value, so resultIndex is always 1.
.array~of(1, , 2, , 3)~pipe(.do {return 2*value} | .console)


-- Inject a value for each item (the returned value is appended).
-- The index of the injected value is pushed on the current index.
-- Index, 1st column : index of the values in the array on entry (1, 3, 5)
-- Index, 2nd column and 3rd column : pair (value, resultIndex)
.array~of(1, , 2, , 3)~pipe(.inject {value*10} pushIndex after | .console)


-- Inject two values for each item (each item of the returned collection is written in the pipe).
.array~of(1, , 2, , 3)~pipe(.inject {.array~of(value*10, value*20)} pushIndex after | .console)


-- Each injected value can be used as input to inject a new value, recursively.
-- The default order is depth-first.
-- If the recursion is infinite, must specify a limit (here 0, 1 and 2).
-- The options 'before' and 'after' are not used, so the initial value is discarded.
-- The index is like a call stack : you get one pair (value, resultIndex) for each level of recursion.
-- Ex : the last line is
-- 5|3|1|90|1|2700|1 : 81000
-- The item at index 5 in input array has generated 3 pairs by recursion : (3,1) then (90,1) then (2700,1)
.array~of(1, , 2, , 3)~pipe(.inject {value*10} pushIndex recursive.0 | .console)
.array~of(1, , 2, , 3)~pipe(.inject {value*20} pushIndex recursive.1| .console)
.array~of(1, , 2, , 3)~pipe(.inject {value*30} pushIndex recursive.2 | .console)


-- Factorial, no value injected for -1
-- The option 'pushIndex' is not used, so the index remains made of one pair (value, resultIndex).
.array~of(-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)~pipe(.inject {
    use arg n
    if n < 0 then return
    if n == 0 then return 1
    return n * .context~executable~call(n - 1)} | .console)


-- Select files in the installation directory, whose name contains "rexx".
-- Take the 15 firsts.
.file~new(installdir())~listFiles~pipe(,
    .select {value~name~caselessPos('rexx') <> 0} |,
    .take 15 |,
    .console,
    )


-- Select files in the installation directory, whose name contains "rexx" , sorted by file size.
-- The "length" message is sent to the value.
-- Take the 15 firsts.
.file~new(installdir())~listFiles~pipe(,
    .select {value~name~caselessPos('rexx') <> 0} |,
    .sortWith[.MessageComparator~new("length/N")] |,
    .take 15 |,
    .console,
    )


-- Same as above, but simpler... You can sort directly by length, no need of MessageComparator
.file~new(installdir())~listFiles~pipe(,
    .select {value~name~caselessPos('rexx') <> 0} |,
    .sort {value~length} |,
    .take 15 |,
    .console,
    )


-- Sort by file size, then by file extension (with only one .sort pipestage)
.file~new(installdir())~listFiles~pipe(,
    .select {value~name~caselessPos('rexx') <> 0} |,
    .sort {value~length} {filespec('e', value~name)} |,
    .take 15 |,
    .console,
    )


-- All instance methods of the context.
-- Notice that the default sort by value is useless here... Must sort by index.
.context~instanceMethods~pipe(.sort byIndex | .console)


-- All private methods of the context.
.context~instanceMethods~pipe(,
    .select {value~isPrivate} |,
    .sort byIndex |,
    .console,
    )


-- Instance methods of the specified classes (not including those inherited).
-- Each class is written in the pipeline, followed by the returned methods (option 'after').
.array~of(.RexxContext, .Package, .Method)~pipe(,
    .inject {value~instanceMethods(value~class)} after pushIndex |,
    .sort byIndex |,
    .console,
    )


-- Methods (not inherited) of all the classes whose id starts with "R".
.environment~pipe(,
    .select {value~isA(.class)} |,
    .select {value~id~caselessAbbrev('R') <> 0} |,
    .inject {value~methods(value)} after pushIndex |,
    .sort byIndex |,
    .console,
    )


-- All packages that are visible from current context, including the current package (source of the pipeline).
.context~package~pipe(,
    .inject {value~importedPackages} recursive after pushIndex |,
    .console index.75,
             {'  '~copies(index~items)},
             {.file~new(value~name)~name},
             newline,
    )


-- Same as above, but in breadth-first order
.context~package~pipe(,
    .inject {value~importedPackages} recursive.breadthFirst after pushIndex |,
    .console index.75,
             {'  '~copies(index~items)},
             {.file~new(value~name)~name},
             newline,
    )


-- The .take pipeStage lets stop the preceding pipeStages when the number of items to take
-- has been reached, whatever its position in the pipeline.
supplier = .array~of(1,2,3,4,5,6,7,8,9)~supplier
supplier~pipe(.console "2*" value "=" | .do {return 2*value} | .take 2 | .console value newline)
say supplier~index -- this is the index of the last processed item
supplier~next -- skip the last processed item
supplier~pipe(.console "4*" value "=" | .do {return 4*value} | .take 4 | .console value newline)
say supplier~index


-- Display the 4 first sorted items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.sort | .take 4 | .console)


-- Sort the 4 first items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.take 4 | .sort | .console)


-- The .append pipeStage copies items from its primary input to its primary output, and then invokes
-- the supplier passed as argument and writes the items produced by that supplier to its primary output.
supplier1 = .array~of(1,2,3,4,5,6,7,8,9)~supplier
supplier2 = .array~of(10,11,12,13,14,15,16,17,18,19)~supplier
-- The first .take limits supplier1 to 2 items.
-- The second .take sees the two items produced by supplier1, so only 3 items are accepted from supplier2.
supplier1~pipe(.take 2 | .append supplier2 | .take 5 | .console)
say supplier1~index
say supplier2~index
supplier1~next
supplier2~next
supplier1~pipe(.take 4 | .append supplier2 | .take 9 | .console)
say supplier1~index
say supplier2~index


-- Remove header and footer
.array~of("header", 1, 2 ,3 , "footer")~pipe(.drop first | .drop last | .console)


-- The *.cls files of ooRexx
installdir()~pipe(,
    .fileTree recursive |,
    .select {filespec('e', value~name) == 'cls'} |,
    .console,
    )


-- From here, some methods of the pipeline classes are instrumented to let profiling.
-- The performances are impacted because the profiled methods are instrumented with an additional forward.
.pipeProfiler~instrument("start", "process", "eof", "isEOP")


-- Alphanumeric words of 16+ chars found in the *.cls files of ooRexx.
-- Only the first two words per file are taken :
--     .take 2 {index[3]}
-- Here, index[3] is the name of the file.
-- Exemple of result :
-- d:/local/Rexx/ooRexx/svn/sandbox/jlf/trunk/Win32rel/|336|d:\local\Rexx\ooRexx\svn\sandbox\jlf\trunk\Win32rel\winsystm.cls|250|2 : DeleteDesktopIcon
-- "DeleteDesktopIcon" is the 2nd word of the 250th line of the file
-- "d:\local\Rexx\ooRexx\svn\sandbox\jlf\trunk\Win32dbg\winsystm.cls"
-- which is the 336th file/directory of the directory
-- "d:/local/Rexx/ooRexx/svn/sandbox/jlf/trunk/Win32rel/"
--
-- To investigate : I get sometimes a crash in the sort.
--
installdir()~pipeProfile(,
    .fileTree recursive |,
    .select {filespec('e', value~name) == 'cls'} |,
    .getFiles | .words | .select {value~datatype('a') & value~length >= 16} |,
    .take 2 {index[3]} | .sort caseless | .console,
    )


say installdir() ; say


-------------------------------------------------------------------------------
::requires "extension/extensions.cls"
::requires "concurrency/coactivity.cls"
::requires "pipeline/pipe_extension.cls"
::requires "rgf_util2/rgf_util2_wrappers.rex"


-------------------------------------------------------------------------------
-- Installation directory of ooRexx
::routine installdir
installdir = "c:\program files\oorexx" -- Assume Windows platform by default
"which rexx | rxqueue"
if queued() then do
    parse pull whichrexx
    rexx = "rexx.exe"
    if \ whichrexx~right(rexx~length)~caselessEquals(rexx) then do
        rexx = "rexx"
        if \ whichrexx~right(rexx~length)~caselessEquals(rexx) then rexx = ""
    end
    if rexx <> "" then installdir = whichrexx~left(whichrexx~length - rexx~length)
end
return installdir


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

