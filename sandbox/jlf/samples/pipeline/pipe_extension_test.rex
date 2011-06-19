call Doers.AddVisibilityFrom(.context)
call evaluate "demonstration"

--::options trace i
::routine demonstration

--- Strange... without this instruction, I don't get the first comments
nop

-- The coactivity yields two results.
-- The hello outputs are not in the pipeline flow (not displayed by the .displayer).
.coactivity~new("echo hello ; .yield[a] ; say hello ; .yield[b]")~pipe(.upper|.displayer)


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
.array~of(1, 2, 3)~pipe(.do["say 'value='value 'index='index"] | .displayer)


-- Do something for each item (the returned result replaces the value).
.array~of(1, 2, 3)~pipe(.do["return 2*value"] | .displayer)


-- Inject a value for each item. The index of the injected value is made of two indexes.
.array~of(1, 2, 3)~pipe(.inject["value+1"] | .displayer)


-- Inject two values for each item (each item of the returned collection is written in the pipe).
.array~of(1, 2, 3)~pipe(.inject[".array~of(value+1, value+2)"] | .displayer)


-- Each injected value can be used as input to inject a new value, recursively.
-- If the recursion is infinite, must specify a limit (here 10).
.array~of(1, 2, 3)~pipe(.inject["value+1"] recursive.10 | .displayer)


-- Factorial, no value injected for -1
.array~of(-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)~pipe(.inject[,
    "use arg n;",
    "if n < 0 then return;",
    "if n == 0 then return 1;",
    "return n * .context~executable~call(n - 1)"] | .displayer)


-- Select files whose name contains "rexx" in c:\program files\oorexx
.file~new("c:\program files\oorexx")~listFiles~pipe(,
    .select["value~name~caselessPos('rexx') <> 0"] |,
    .displayer,
    )


-- Select files whose name contains "rexx" in c:\program files\oorexx, sorted by file size.
-- The "length" message is sent to the value.
.file~new("c:\program files\oorexx")~listFiles~pipe(,
    .select["value~name~caselessPos('rexx') <> 0"] |,
    .sortWith[.MessageComparator~new("length/N")] |,
    .displayer,
    )


-- Same as above, but simpler... You can sort directly by length, no need of MessageComparator
.file~new("c:\program files\oorexx")~listFiles~pipe(,
    .select["value~name~caselessPos('rexx') <> 0"] |,
    .sort "value~length" |,
    .displayer,
    )


-- Sort by file size, then by file extension (with only one .sort pipestage)
.file~new("c:\program files\oorexx")~listFiles~pipe(,
    .select["value~name~caselessPos('rexx') <> 0"] |,
    .sort "value~length" "filespec('e', value~name)" |,
    .displayer,
    )


-- All instance methods of the context.
-- Notice that the default sort by value is useless here... Must sort by index.
.context~instanceMethods~pipe(.sort byIndex | .displayer)


-- All private methods of the context.
.context~instanceMethods~pipe(,
    .select["value~isPrivate"] |,
    .sort byIndex |,
    .displayer,
    )


-- Instance methods of the specified classes (not including those inherited).
-- Each class is written in the pipeline, followed by the returned methods.
.array~of(.RexxContext, .Package, .Method)~pipe(,
    .inject["value~instanceMethods(value~class)"] |,
    .sort byIndex |,
    .displayer,
    )


-- Methods (not inherited) of all the classes whose id starts with "R".
.environment~pipe(,
    .select["value~isA(.class)"] |,
    .select["value~id~caselessAbbrev('R') <> 0"] |,
    .inject["value~methods(value)"] |,
    .sort byIndex |,
    .displayer,
    )


-- All packages that are visible from current context, including the current package (source of the pipeline).
-- Notice the circular dependency between packages (supported by inject - the recursion is stopped) :
-- extensions.cls --> doers.cls --> extensions.cls
-- This is because of Doers.AddVisibilityFrom.
.context~package~pipe(,
    .inject["value~importedPackages"] recursive |,
    .displayer index.10,
               "'    '~copies(index~items)",
               ".file~new(value~name)~name",
               newline,
    )


-- The .take pipeStage lets stop the preceding pipeStages when the number of items to take
-- has been reached, whatever its position in the pipeline.
supplier = .array~of(1,2,3,4,5,6,7,8,9)~supplier
supplier~pipe(.displayer '"2*"' value '"="' | .do["return 2*value"] | .take 2 | .displayer value newline)
say supplier~index
supplier~pipe(.displayer '"4*"' value '"="' | .do["return 4*value"] | .take 4 | .displayer value newline)
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
supplier1~pipe(.take 2 | .append[supplier2] | .take 5 | .displayer)
say supplier1~index
say supplier2~index
supplier1~pipe(.take 4 | .append[supplier2] | .take 9 | .displayer)
say supplier1~index
say supplier2~index


-- Remove header and footer
.array~of("header", 1, 2 ,3 , "footer")~pipe(.drop first 1 | .drop last 1 | .displayer)


-------------------------------------------------------------------------------
::routine evaluate
    use strict arg routineName
    routine = .context~package~findRoutine(routineName)
    routineSource = routine~source
    clause = ""
    do sourceline over routineSource
        if sourceline~strip~left(3) == "---" then iterate -- Comments starting with 3 '-' are removed
        else if sourceline~strip == "nop" then iterate -- nop is a workaround to get the first comments
        else if sourceline~strip~left(2) == "--" then say sourceline -- Comments starting with 2 '-' are kept
        else if sourceline~strip == "" then say
        else do
            say sourceline
            if sourceline~right(1) == "," then clause ||= sourceline~left(sourceline~length - 1)
            else do
                clause ||= sourceline
                interpret clause
                clause = ""
            end
        end
    end


::requires "extension/extensions.cls"
::requires "concurrency/coactivity.cls"
::requires "pipeline/pipe_extension.cls"
::requires "rgf_util2/rgf_util2_wrappers"
