call evaluate "demonstration"
say
say "Ended coactivities:" .Coactivity~endAll

--::options trace i
::routine demonstration

--- Strange... without this instruction, I don't get the first comments
nop

-- ----------------------------------------------------------------------------
-- Overview of dataflows
-- ----------------------------------------------------------------------------
--   1          2     3       4
-- +----------+-----+-------+------+
-- | previous | tag | index | item |
-- +----------+-----+-------+------+
--    ^
--    |  +----------+-----+-------+------+
--    +--| previous | tag | index | item |
--       +----------+-----+-------+------+
--          ^
--          |
--          +-- etc...


-- A dataflow is created from a tag, a pair of (item, index), and a previous dataflow (which can be .nil).
-- Representation : the strings (except the strings numbers) are surrounded by quotes.
df1 = .dataflow~create(.nil, "tag1", "item1", "index1")
say df1 -- by default, all the fields are included in the representation string.
say df1~makeString(2) -- show tag
say df1~makeString(23) -- show tag, index
say df1~makeString(234) -- show tag, index, item


-- A dataflow can be linked to a previous dataflow.
-- Representation : the dataflows are separated by |
df2 = .dataflow~create(df1, "tag2", "item2", "index2")
say df2


-- Representation : the objects other than strings are surrounded by round brackets.
df3 = .dataflow~create(df2, "tag3", .mutableBuffer~new(22222), .file~new("my file"))
say df3


-- showPool=.true : when an item (other than a number) appears several times then it is replaced by a reference to the first occurence of the item.
-- The references are named v1, v2, etc...
-- The operator == is used for the comparison.
-- Example :
-- "a" and .file~new("my file" are entered in the pool, because there is more than one occurence of them.
-- .mutableBuffer~new(22222) is not entered in the pool, because two distincts instances are never equal, even if their string representation is the same.
df4 = .dataflow~create(df3, "tag4", .file~new("my file"), "a")
df5 = .dataflow~create(df4, "tag5", .mutableBuffer~new(22222), "a")
say df5 ; say df5~makeString(1234, .true)


-- ----------------------------------------------------------------------------
-- Overview of the sources supported by pipes
-- ----------------------------------------------------------------------------

-- Any object can be a source of pipe.
-- When the object does not support the method ~supplier then it's injected as-is.
-- Its associated index is always 1.
"hello"~pipe(.console)


-- By default, the dataflows are not shown, use the option dataflow.
-- dataflow is interpreted as the string "DATAFLOW" because no value assigned.
-- If dataflow was a variable with an assigned value, then you should use explicitely the string "dataflow" (caseless).
-- Other options supported by .console : index, item
"hello"~pipe(.console dataflow)


-- A collection can be a source of pipe : each item of the collection is injected in the pipe.
-- The indexes are those of the collection.
.array~of(10,20,30)~pipe(.console)
.array~of(10,20,30)~pipe(.console dataflow)


-- A coactivty can be a source of pipe : each yielded item is injected in the pipe.
-- Example :
-- This coactivity yields two results.
-- The hello outputs are not in the pipeline flow (not displayed by the .console).
-- 07/10/2019 : now the RexxBlock are always with implicit return. Must add options "COMMANDS".
{::coactivity options "COMMANDS"; echo hello ; .yield["a"] ; say hello ; .yield["b"] }~doer~pipe(.console)
{::coactivity options "COMMANDS"; echo hello ; .yield["a"] ; say hello ; .yield["b"] }~doer~pipe(.console dataflow)


-- ----------------------------------------------------------------------------
-- Overview of the pipe operators.
-- Reminder of the precedence (highest at the top) :
-- (message send)         : ~ ~~ (not overloaded for pipes)
-- (prefix operators)     : + - \ (not overloaded for pipes)
-- (power)                : ** (not overloaded for pipes)
-- (multiply and divide)  : * / % // (not overloaded for pipes)
-- (add and subtract)     : + - (not overloaded for pipes)
-- (blank) || (abuttal)   : (blank) is overloaded for adding options.
-- (comparison operators) : > >> are overloaded for pipes, the rest is not used : = < == << \= >< <> \> \< \== \>> \<< >= >>= <= <<=
-- (and operator)         : & (not overloaded for pipes).
-- (or, exclusive or)     : | is overloaded, && is not used.
-- ----------------------------------------------------------------------------

-- stage1 | stage2
-- stage1 > stage2
-- | and > share the same implementation...
-- (they connect the primary output of stage1 to the primary input of stage2)
"hello"~pipe(.left[2] | .upper | .console)

-- Same pipeline as previous, but with methods only
"hello"~pipe(    (.left~new(2) ~append(.upper~new))    ~append(.console~new)    )


-- ...but | and > don't have the same precedence ! No impact here.
"hello"~pipe(.left[2] | .upper > .console)

-- Same pipeline as previous, but with methods only
"hello"~pipe(    .left~new(2) ~append(   .upper~new ~append(.console~new)    )    )


-- stage1 >> stage2
-- Connects the secondary output of stage1 to the primary input of stage2
-- Here, the result is not what you expect. You want "LLO", you get "he"...
-- This is because .console is the primary follower of .left, not the primary
-- follower of .upper.
-- Why ? because the pipestage returned by .left[2] >> .upper is .left,
-- and .console is attached to the pipestage found by starting from .left
-- and walking through the 'next' references until a pipestage with no 'next'
-- is found. So .upper is not walked though, because it's a secondary follower.
"hello"~pipe(.left[2] >> .upper | .console)

-- Same pipeline as previous, but with methods only
"hello"~pipe(    (.left~new(2) ~appendSecondary(.upper~new))    ~append(.console~new)    )


-- ...You need additional parentheses to get the expected behavior.
-- Here, .console is the primary follower of .upper.
"hello"~pipe(.left[2] >> ( .upper | .console ) )

-- Same pipeline as previous, but with methods only
"hello"~pipe(    .left~new(2) ~appendSecondary(    .upper~new ~append(.console~new)    )    )


-- ----------------------------------------------------------------------------
-- Overview of the sorting facilities
-- ----------------------------------------------------------------------------

-- A collection can be sorted by item (default)
.array~of(b, a, c)~pipe(.sort byItem | .console)


-- ...or by index
.array~of(b, a, c)~pipe(.sort byIndex | .console)


-- ...ascending (default)
-- The order of options is important : a byItem option is impacted only by the preceding options
-- This is because several byItem options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort ascending byItem | .console)


-- ...descending
.array~of(b, a, c)~pipe(.sort descending byItem | .console)


-- ...by index descending
-- The order of options is important : a byIndex option is impacted only by the preceding options.
-- This is because several byIndex options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort descending byIndex | .console)


-- ...caseless (stable by default)
.array~of("bb", "AA", "bB", "Aa", "Bb", "aA", "BB", "aa")~pipe(.sort caseless byItem | .console)


-- ...caseless quickSort (unstable)
-- No difference bewteen stable and unstable ? yes, see commit 6275 in interpreter/memory/setup.cpp :
--  // there have been some problems with the quick sort used as the default sort, so map everything
--  // to the stable sort.  The stable sort, in theory, uses more memory, but in practice, this is not true.
--  defineKernelMethod(CHAR_SORT         ,TheArrayBehaviour, CPPM(RexxArray::stableSortRexx), 0);
--  defineKernelMethod(CHAR_SORTWITH     ,TheArrayBehaviour, CPPM(RexxArray::stableSortWithRexx), 1);
--  defineKernelMethod(CHAR_STABLESORT   ,TheArrayBehaviour, CPPM(RexxArray::stableSortRexx), 0);
--  defineKernelMethod(CHAR_STABLESORTWITH ,TheArrayBehaviour, CPPM(RexxArray::stableSortWithRexx), 1);
.array~of("bb", "AA", "bB", "Aa", "Bb", "aA", "BB", "aa")~pipe(.sort caseless quickSort byItem | .console)


-- Sort descending with a comparator.
-- The DescendingComparator use the default CompareTo, which is made on items.
.array~of(b, a, c)~pipe(.sortWith[.DescendingComparator~new] | .console)


-- Sort by column with a comparator.
.array~of("c:2", "b:2", "A:2", "c:1", "a:1", "B:1", "C:3")~pipe(,
    .sortWith[.InvertingComparator~new(.CaselessColumnComparator~new(3,1))] |,
    .sortWith[.CaselessColumnComparator~new(1,1)] |,
    .console,
    )


-- ----------------------------------------------------------------------------
-- Options available on any pipeStage : memorize
-- ----------------------------------------------------------------------------

"aaaBBBcccDDDeee"~pipe(.reverse memorize | .console dataflow)


"aaaBBBcccDDDeee"~pipe(.upper memorize | .console dataflow)


"aaaBBBcccDDDeee"~pipe(.lower memorize | .console dataflow)


"aaaBBBcccDDDeee"~pipe(.changeStr["B", "b", 2] memorize | .console dataflow)


"aaaBBBcccDDDeee"~pipe(.delStr[4, 9] memorize | .console dataflow)


"aaaBBBcccDDDeee"~pipe(.left[3] memorize >> .console "secondary :" dataflow | .console "primary:" dataflow)


"aaaBBBcccDDDeee"~pipe(.right[3] memorize >> .console "secondary :" dataflow | .console "primary:" dataflow)


"aaaBBBcccDDDeee"~pipe(.insert["---", 3] memorize | .console dataflow)


"aaaBBBcccDDDeee"~pipe(.overlay["---", 3] memorize | .console dataflow)


"48656c6c6f"~pipe(.x2c memorize | .console dataflow)


.array~of("a", "", "b", , "c", , "", "d")~pipe(.dropNull memorize | .console dataflow)


.array~of("header", 1, 2 ,3 , "footer")~pipe(,
    .drop first memorize >> .console "secondary of drop first :" dataflow |,
    .drop last memorize >> .console "secondary of drop last :" dataflow |,
    .console "primary:" dataflow) -- Remove header and footer


-- ----------------------------------------------------------------------------
-- .do and .inject pipeStages
-- ----------------------------------------------------------------------------

-- .do is a synonym of .inject.
-- Sometimes, the name '.do' is better than the name '.inject'.
-- Both support the same options and have the same behavior.


-- Do something for each item (no returned value, so no value passed to .console).
.array~of(1, , 2, , 3)~pipe(.do {say 'item='item 'dataflow='dataflow~makeString} | .console)


-- Do something for each item (the returned result replaces the item's value).
-- Here, only one result is calculated for an item, so resultIndex is always 1.
.array~of(1, , 2, , 3)~pipe(.do {return 2*item} memorize | .console)


-- Inject a value for each item (the returned value is injected after the input item).
.array~of(1, , 2, , 3)~pipe(.inject after {item*10} memorize | .console dataflow)


-- Inject two values for each item (each item of the returned collection is written in the pipe).
-- Note the "iterateAfter" option : using this option, when the result of .inject is an object which
-- understands "supplier" then each pair (item, index) returned by the supplier is injected in the pipe.
.array~of(1, , 2, , 3)~pipe(.inject after {.array~of(item*10, item*20)} iterateAfter memorize | .console dataflow)


-- Each injected value can be used as input to inject a new value, recursively.
-- The default order is depth-first.
-- If the recursion is infinite, must specify a limit (here 0, 1 and 2).
-- The options 'before' and 'after' are not used, so the initial item is discarded.
.array~of(1, , 2, , 3)~pipe(.inject {item*10} recursive.0 | .console dataflow "item =" item)
.array~of(1, , 2, , 3)~pipe(.inject {item*20} recursive.1 | .console dataflow "item =" item)
.array~of(1, , 2, , 3)~pipe(.inject {item*30} recursive.2 | .console dataflow "item =" item)


-- Same as previous example, but here, the recursive.memorize option is used.
-- The dataflow is like a call stack.
-- Ex : the last line is
-- source:5,3 | inject:1,90 | inject:1,2700 | inject:1,81000 item = 81000
-- The item at index 5 in input array has injected 3 "inject" dataflows by recursion.
.array~of(1, , 2, , 3)~pipe(.inject {item*10} recursive.0.memorize | .console dataflow "item =" item)
.array~of(1, , 2, , 3)~pipe(.inject {item*20} recursive.1.memorize | .console dataflow "item =" item)
.array~of(1, , 2, , 3)~pipe(.inject {item*30} recursive.2.memorize | .console dataflow "item =" item)


-- Factorial, no value injected for -1
.array~of(-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)~pipe(.inject {
    use arg n
    if n < 0 then return
    if n == 0 then return 1
    return n * .context~executable~call(n - 1)} | .console dataflow item)


-- Another illustration of the "iterateAfter" option.
10~pipe(.inject {item~times} | .console)
10~pipe(.inject {item~times} iterateAfter | .console)
10~pipe(.inject {item~times.generate} | .console)
10~pipe(.inject {item~times.generate} iterateAfter | .console)


-- Another illustration of the "iterateAfter" option.
-- In this example, the block passed to .inject returns another block whose doer is a coactivity.
-- The option "iterateAfter" force to check if the returned value has the "supplier" method.
-- If yes, then .inject iterates over the items returned by the supplier and sends them to the next pipeStage.
-- A block has no "supplier" method, but its doer may have one. This is the case in this example.
-- The method "hasMethod" has been redefined on RexxBlock to return .true if the doer has the method "supplier".
-- The method "supplier" has been defined on RexxBlock to forward to its doer.
-- Note :
-- The pipeStage .take is mandatory because the generator passed to .inject will generate an infinite sequence of numbers.
1~pipe(.inject {{::coactivity expose item ; do forever ; .yield[item] ; item += 1 ; end}} iterateAfter | .take 10 | .console)


-- ----------------------------------------------------------------------------
-- Additional sorting facilities
-- ----------------------------------------------------------------------------

-- Select files in the installation directory, whose path contains "rexx" , sorted by file size.
-- The "length" message is sent to the item and the returned result is used as a key for sorting.
.file~new(installdir())~listFiles~pipe(,
    .all["rexx"] caseless |,
    .sortWith[.MessageComparator~new("length/N")] |,
    .console dataflow {"length="item~length},
    )


-- Same as above, but simpler... You can sort directly by length, no need of MessageComparator
.file~new(installdir())~listFiles~pipe(,
    .all["rexx"] caseless |,
    .sort {item~length} |,
    .console dataflow {"length="item~length},
    )


-- Sort by file size, then by file extension (with only one .sort pipestage)
.file~new(installdir())~listFiles~pipe(,
    .all["rexx"] caseless |,
    .sort {item~length} {filespec('e', item~name)} |,
    .console dataflow {"length="item~length},
    )


-- ----------------------------------------------------------------------------
-- Various examples with collections and recursive processing
-- Illustration of the depthFirst vs breadthFirst options
-- ----------------------------------------------------------------------------

-- All instance methods of the context.
-- Notice that the default sort by item is useless here... Must sort by index.
.context~instanceMethods~pipe(.sort byIndex | .console)


-- All private methods of the context.
.context~instanceMethods~pipe(,
    .select {item~isPrivate} |,
    .sort byIndex |,
    .console,
    )


-- Instance methods of the specified classes (not including those inherited).
-- Each class is written in the pipeline, followed by the returned methods (option 'after').
.array~of(.RexxContext, .Package, .Method)~pipe(,
    .inject after {item~instanceMethods(item~class)} iterateAfter memorize |,
    .sort byIndex {dataflow["source"]~item} |,
    .console dataflow,
    )


-- Methods (not inherited) of all the classes whose id starts with "R".
.environment~pipe(,
    .select {item~isA(.class)} |,
    .select {item~id~caselessAbbrev('R') <> 0} |,
    .inject after {item~methods(item)} iterateAfter memorize |,
    .sort byIndex {dataflow["source"]~item} |,
    .console dataflow,
    )


-- All packages that are visible from current context, including the current package (source of the pipeline).
.context~package~pipe(,
    .inject after {item~importedPackages} iterateAfter recursive.memorize.cycle |,
    .console {'  '~copies(dataflow~length)} {.file~new(item~name)~name},
    )


-- Same as above, but in breadth-first order
.context~package~pipe(,
    .inject after {item~importedPackages} iterateAfter recursive.breadthFirst.memorize.cycle |,
    .console {'  '~copies(dataflow~length)} {.file~new(item~name)~name},
    )


-- ----------------------------------------------------------------------------
-- .take pipeStage
-- ----------------------------------------------------------------------------

-- The .take pipeStage lets stop the preceding pipeStages when the number of items to take
-- has been reached, whatever its position in the pipeline.
-- Note the "" at the end of the first .console. This is an indicator to not insert a newline.
supplier = .array~of(1,2,3,4,5,6,7,8,9)~supplier
supplier~pipe(.console "2*" item "=" "" | .do {return 2*item} | .take 2 | .console item)
say supplier~index -- this is the index of the last processed item
supplier~next -- skip the last processed item
supplier~pipe(.console "4*" item "=" "" | .do {return 4*item} | .take 4 | .console item)
say supplier~index


-- Display the 4 first sorted items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.sort | .take 4 | .console)


-- Sort the 4 first items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.take 4 | .sort | .console)


-- Select files in the installation directory, whose name contains "rexx".
-- Note : the .select is not equivalent to .all["rexx"], because .select tests only the name,
-- whereas .all tests the string representation of the item, which is the absolute path.
-- Take the 15 firsts.
.file~new(installdir())~listFiles~pipe(,
    .select {item~name~caselessPos('rexx') <> 0} |,
    .take 15 |,
    .console,
    )


-- ----------------------------------------------------------------------------
-- .append pipeStage
-- ----------------------------------------------------------------------------

-- The .append pipeStage copies items from its primary input to its primary output, and then invokes
-- the producer passed as argument and writes the items produced by that producer to its primary output.
-- If the producer is a doer, then the producer is executed to get the effective producer.
-- If the effective producer understands the message "supplier" then each pair (item, index)
-- returned by the supplier is appended.
-- Otherwise, the effective producer is appended as-is (single object) with local index 1.
supplier1 = .array~of(1,2,3,4,5,6,7,8,9)~supplier
supplier2 = .array~of(10,11,12,13,14,15,16,17,18,19)~supplier
-- The first .take limits supplier1 to 2 items.
-- The second .take sees the two items produced by supplier1, so only 3 items are accepted from supplier2.
supplier1~pipe(.take 2 | .append supplier2 iterate | .take 5 | .console)
say supplier1~index
say supplier2~index
supplier1~next
supplier2~next
supplier1~pipe(.take 4 | .append supplier2 iterate | .take 9 | .console)
say supplier1~index
say supplier2~index


-- ----------------------------------------------------------------------------
-- pipeStages which support partitions
-- ----------------------------------------------------------------------------

-- Drop the first item
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop | .console)


-- Drop the first item of each partition
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop {item} | .console)


-- Drop the last item
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop last | .console)


-- Drop the last item of each partition
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop last {item} | .console)


datas = .directory~new
datas["key1"] = .array~of("header", 1, 2, "footer")
datas["key2"] = .array~of("header", 5, 3, -9, 12, "footer")
datas["key3"] = .array~of("header", 4, 6, 5, "footer")


-- The whole datas, including headers and footers
datas~pipe(.inject {item} iterateBefore memorize | .console)


-- The datas without the headers and footers
datas~pipe(.inject {item} iterateBefore memorize | .drop first {dataflow["source"]~item } | .drop last {dataflow["source"]~item } | .console)


-- No partition here, so the whole set of words is written twice, separated by "==="
.array~of("one two three","un deux trois")~pipe(.words | .buffer[2, "==="] | .console)


-- There is a partition on the source items, so there is a separator "===" between each set of words extracted from each string
.array~of("one two three","un deux trois")~pipe(.words memorize | .buffer[2, "==="] {dataflow["source"]~item} | .console)


-- ----------------------------------------------------------------------------
-- .fanout, .fanin, .merge pipeStages
-- ----------------------------------------------------------------------------

-- Here, only the output from fanout1 is sent to console.
fanout1 = .left[3]  memorize | .lower memorize
fanout2 = .right[3] memorize | .upper memorize | .inject after {"my_"item}
.array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout memorize >> fanout2 > fanout1 | .console dataflow item)


-- Here, each branch of the fanout remains separated. Each branch has its own console.
fanout1 = .left[3]  memorize | .lower memorize | .console dataflow item
fanout2 = .right[3] memorize | .upper memorize | .inject after {"my_"item} | .console dataflow item
.array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout memorize >> fanout2 > fanout1)


-- Here, a fanin is used to serialize the branches of the fanout.
-- The output from fanout1 is sent to console, then the output from fanout2 (delayed)
fanin = .fanin memorize | .console dataflow item
fanout1 = .left[3]  memorize | .lower memorize | fanin  -- not bufferized
fanout2 = .right[3] memorize | .upper memorize | .inject after {"my_"item} | .secondaryConnector | fanin -- bufferized until fanout1 is eof
.array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout memorize >> fanout2 > fanout1)

-- Here, a merge is used to serialize the branches of the fanout.
-- There is no specific order (no delay).
merge = .merge memorize | .console dataflow item
fanout1 = .left[3]  memorize | .lower memorize | merge  -- not bufferized
fanout2 = .right[3] memorize | .upper memorize | .inject after {"my_"item} | .secondaryConnector | merge -- not bufferized
.array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout memorize >> fanout2 > fanout1)


-- ----------------------------------------------------------------------------
-- .fileTree pipeStage
-- ----------------------------------------------------------------------------

-- The *.cls files of ooRexx
installdir()~pipe(,
    .fileTree recursive |,
    .endsWith[".cls"] |,
    .console,
    )


-- Total number of lines in the *.cls files of ooRexx
installdir()~pipe(,
    .fileTree recursive |,
    .endsWith[".cls"] |,
    .fileLines | .lineCount |,
    .console,
    )


-- Number of lines in each *.cls files of ooRexx
installdir()~pipe(,
    .fileTree recursive memorize.file |,
    .endsWith[".cls"] |,
    .fileLines | .lineCount {dataflow["file"]~item} |,
    .console,
    )


-- Total number of words in the *.cls files of ooRexx
installdir()~pipe(,
    .fileTree recursive |,
    .endsWith[".cls"] |,
    .fileLines | .wordCount |,
    .console,
    )


-- Number of words in each *.cls files of ooRexx
installdir()~pipe(,
    .fileTree recursive memorize.file |,
    .endsWith[".cls"] |,
    .fileLines | .wordCount {dataflow["file"]~item} |,
    .console,
    )


-- Total number of characters in the *.cls files of ooRexx (not counting the newline characters)
installdir()~pipe(,
    .fileTree recursive |,
    .endsWith[".cls"] |,
    .fileLines | .charCount |,
    .console,
    )


-- Number of characters in each *.cls files of ooRexx (not counting the newline characters)
installdir()~pipe(,
    .fileTree recursive memorize.file |,
    .endsWith[".cls"] |,
    .fileLines | .charCount {dataflow["file"]~item} |,
    .console,
    )


-- Alphanumeric words of 16+ chars found in the *.cls files of ooRexx.
-- Only the first two words per file are taken :
--     .take 2 {dataflow["file"]~item}
-- Here, the partition expression returns the current file object produced by the pipeStage "fileTree".
-- Exemple of result :
-- source:1,'d:/local/Rexx/ooRexx/svn/sandbox/jlf/trunk/Win32rel/' | FILE:338,(d:\local\Rexx\ooRexx\svn\sandbox\jlf\trunk\Win32rel\winsystm.cls) | fileLines:250,'::method DeleteDesktopIcon' | words:2,'DeleteDesktopIcon' 'DeleteDesktopIcon'
-- "DeleteDesktopIcon" is the 2nd word of the 250th line of the file
-- "d:\local\Rexx\ooRexx\svn\sandbox\jlf\trunk\Win32dbg\winsystm.cls"
-- which is the 338th file/directory of the directory
-- "d:/local/Rexx/ooRexx/svn/sandbox/jlf/trunk/Win32rel/"
--
-- To investigate : I get sometimes a crash in the sort.
--
call time('r') -- to see how long this takes
installdir()~pipe(,
    .fileTree recursive memorize.file |,
    .endsWith[".cls"] |,
    .fileLines memorize | .words memorize | .select {item~datatype('a') & item~length >= 16} |,
    .take 2 {dataflow["file"]~item} | .sort caseless | .console dataflow item,
    )
say "duration="time('e') -- elapsed duration


-- From here, some methods of the pipeline classes are instrumented to let profiling.
-- The performances are impacted because the profiled methods are instrumented with an additional forward.
.pipeProfiler~instrument("start", "process", "eof", "isEOP")


-- Same as above, but with profiling
call time('r') -- to see how long this takes
installdir()~pipeProfile(,
    .fileTree recursive memorize.file |,
    .endsWith[".cls"] |,
    .fileLines memorize | .words memorize | .select {item~datatype('a') & item~length >= 16} |,
    .take 2 {dataflow["file"]~item} | .sort caseless | .console dataflow item,
    )
say "duration="time('e') -- elapsed duration


say installdir() ; say


-------------------------------------------------------------------------------
--::requires "extension/extensions.cls"
--::requires "concurrency/coactivity.cls"
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
            say "   "evaluate_sourceline
            evaluate_curly_bracket_count += evaluate_sourceline~countStr("{") - evaluate_sourceline~countStr("}")
            if ",-"~pos(evaluate_sourceline~right(1)) <> 0 then do
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

