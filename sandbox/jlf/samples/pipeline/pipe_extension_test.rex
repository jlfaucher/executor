call evaluate "demonstration"

--::options trace i
::routine demonstration

--- Strange... without this instruction, I don't get the first comments
nop

-- ----------------------------------------------------------------------------
-- Overview of pipe indexes
-- ----------------------------------------------------------------------------

-- A minimal pipe index is created from a tag and a nested pipe index (which can be .nil).
i0 = .pipeIndex~create("tag0", .nil)
say i0 -- by default, the tags are not included in the representation string, so nothing visible.
say i0~makeString(.true) -- showTags=.true


-- Any number of local indexes can be memorized.
-- Representation : the strings (except the strings numbers) are surrounded by quotes.
i1 = .pipeIndex~create("tag1", .nil, "a", 1, 2, 3, 4)
say i1 ; say i1~makeString(.true)


-- Nested pipe indexes are used when memorizing intermediate calculations.
-- Representation : the pipe indexes are separated by |
i2 = .pipeIndex~create("tag2", i1, "a", 1, 2)
say i2 ; say i2~makeString(.true)


-- Representation : the objects other than strings are surrounded by round brackets.
-- When showTags is .true then a tag class#id is inserted before the representation of objects. 
-- The id is a short id (starts from 1, incremented for each new instance of the same class in the index).
i3 = .pipeIndex~create("tag3", i2, .mutableBuffer~new(22222), .file~new("my file"))
say i3 ; say i3~makeString(.true)


-- showPool=.true : when a value (other than numbers) appears several times then it is replaced by a reference to the first occurence of the value.
-- The references are named i1, i2, etc... (no relation with the variables i1, i2, i3 used so far, this is just a naming convention).
-- The operator == is used for the comparison.
-- "a" and .file~new("my file" are entered in the pool, because there is more than one occurence of them.
-- .mutableBuffer~new(22222) is not entered in the pool, because two distincts instances are never equal, even if their string representation is the same.
i4 = .pipeIndex~create("tag4", i3, .file~new("my file"), .mutableBuffer~new(22222))
say i4 ; say i4~makeString(.false, .true)


-- The 'makeString' method has more arguments :
--     localMask : which local indexes to include ("" means all). Ex : "2 3".
--     showNested : if .false then the nested index is not included.
-- The convenience method 'show' lets select the local indexes to include in the representation
-- while providing default values for the other parameters : 
-- ~show(localMask) <==> ~makeString(.false, .false, localMask, .false)
say i4 ; say i4~makestring(.true) ; say i4~get("tag2")~show("1 3") -- order in show argument not significant


-- ----------------------------------------------------------------------------
-- Overview of the sources supported by pipes
-- ----------------------------------------------------------------------------

-- Any object can be a source of pipe.
-- When the object does not support the method ~supplier then it's injected as-is.
-- Its associated index is always 1.
"hello"~pipe(.console)


-- By default, the tags are not shown, use the option showTags.
-- showTags is interpreted as the string "SHOWTAGS" because no value assigned.
-- If showTags was a variable with an assigned value, then you should use explicitely the string "showTags" (caseless).
-- Other options supported by .console : index, value
-- The string "INDEX" (caseless) is replaced by the result of {index~makeString).
-- The string "VALUE" (caseless) is replaced by the result of {value~string}.
"hello"~pipe(.console showTags)


-- A collection can be a source of pipe : each item of the collection is injected in the pipe.
-- The indexes are those of the collection.
.array~of(10,20,30)~pipe(.console)
.array~of(10,20,30)~pipe(.console showTags)


-- A coactivty can be a source of pipe : each yielded value is injected in the pipe (lazy).
-- Example :
-- This coactivity yields two results.
-- The hello outputs are not in the pipeline flow (not displayed by the .console).
{::c echo hello ; .yield["a"] ; say hello ; .yield["b"] }~doer~pipe(.console)
{::c echo hello ; .yield["a"] ; say hello ; .yield["b"] }~doer~pipe(.console showTags)


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

-- A collection can be sorted by value (default)
.array~of(b, a, c)~pipe(.sort byValue | .console)


-- ...or by index
.array~of(b, a, c)~pipe(.sort byIndex | .console)


-- ...ascending (default)
-- The order of options is important : a byValue option is impacted only by the preceding options
-- This is because several byValue options can be specified, and a sort is made for each.
.array~of(b, a, c)~pipe(.sort ascending byValue | .console)


-- ...descending
.array~of(b, a, c)~pipe(.sort descending byValue | .console)


-- ...by index descending
-- The order of options is important : a byIndex option is impacted only by the preceding options.
-- This is because several byIndex options can be specified, and a sort is made for each.
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


-- ----------------------------------------------------------------------------
-- Options available on any pipeStage : memorizeIndex
-- ----------------------------------------------------------------------------

"aaaBBBcccDDDeee"~pipe(.reverse mem | .console showTags)


"aaaBBBcccDDDeee"~pipe(.upper mem | .console showTags)


"aaaBBBcccDDDeee"~pipe(.lower mem | .console showTags)


"aaaBBBcccDDDeee"~pipe(.changeStr["B", "b", 2] mem | .console showTags)


"aaaBBBcccDDDeee"~pipe(.delStr[4, 9] mem | .console showTags)


"aaaBBBcccDDDeee"~pipe(.left[3] mem >> .console showTags "secondary :" index ":" value | .console showTags "primary:" index ":" value)


"aaaBBBcccDDDeee"~pipe(.right[3] mem >> .console showTags "secondary :" index ":" value | .console showTags "primary:" index ":" value)


"aaaBBBcccDDDeee"~pipe(.insert["---", 3] mem | .console showTags)


"aaaBBBcccDDDeee"~pipe(.overlay["---", 3] mem | .console showTags)


"48656c6c6f"~pipe(.x2c mem | .console showTags)


.array~of("a", "", "b", , "c", , "", "d")~pipe(.dropNull mem | .console showTags)


.array~of("header", 1, 2 ,3 , "footer")~pipe(,
    .drop first mem >> .console showTags "secondary of drop first :" index ":" value |,
    .drop last mem >> .console showTags "secondary of drop last :" index ":" value |,
    .console showTags "primary:" index ":" value) -- Remove header and footer


-- ----------------------------------------------------------------------------
-- .do and .inject pipeStages
-- ----------------------------------------------------------------------------

-- Do something for each item (no returned value).
.array~of(1, , 2, , 3)~pipe(.do {say 'value='value 'index='index} | .console)


-- Do something for each item (the returned result replaces the item's value).
-- Note : the index created by .do is a pair (value, resultIndex) where
--     value is the processed value.
--     resultIndex is the index of the current result calculated with value.
-- Here, only one result is calculated for a value, so resultIndex is always 1.
.array~of(1, , 2, , 3)~pipe(.do {return 2*value} mem | .console)


-- Inject a value for each item (the returned value is injected after the input value).
-- Use the default index.
-- Index, 1st part : index of the values in the array on entry (1, 3, 5)
-- Index, 2nd part : pair (value, resultIndex)
.array~of(1, , 2, , 3)~pipe(.inject {value*10} memorize after | .console)


-- Inject a value for each item (the returned value is injected after the input value).
-- The index is user-defined.
-- Two helpers are available for user-defined indexes :
-- .index_value : the first arg is the index, the second arg is the value.
-- .value_index : the first arg is the value, the second arg is the index.
-- Note : This user-defined index is used only for the values calculated by .inject (10, 20, 30).
--        The input values always have an index equal to 1 (1st line, 3rd line, 5th line).
--        It's like getting a single result from the input value (result == value, index == 1).
.array~of(1, , 2, , 3)~pipe(.inject {.index_value~of(value, value*10)} memorize after | .console)


-- Inject two values for each item (each item of the returned collection is written in the pipe).
-- Use the default index.
.array~of(1, , 2, , 3)~pipe(.inject {.array~of(value*10, value*20)} memorize after | .console)


-- Inject two values for each item (each item of the returned collection is written in the pipe).
-- The index is user-defined, and it's an array : each item in the index array becomes a local index.
-- Ex: the last two lines are 
-- (an Array),5|3,1,2,4 : 30
-- (an Array),5|3,2,2,4 : 60
-- From the 5th item of the input array (value=3), 2 values have been injected (30 with index 1, 60 with index 2).
-- A user-defined index has been appended to the default index : (2,4) which is (value-1, value+1).
.array~of(1, , 2, , 3)~pipe(.inject {
    .index_value~of(                              -
        .array~of(value-1, value+1),    /*index : made of several values, each value being a local index*/ -
        .array~of(value*10, value*20)   /*values : two values will be injected*/ -
        )
    } memorize after | .console)


-- Each injected value can be used as input to inject a new value, recursively.
-- The default order is depth-first.
-- If the recursion is infinite, must specify a limit (here 0, 1 and 2).
-- The options 'before' and 'after' are not used, so the initial value is discarded.
-- Use the default index.
.array~of(1, , 2, , 3)~pipe(.inject {value*10} recursive.0 | .console)
.array~of(1, , 2, , 3)~pipe(.inject {value*20} recursive.1 | .console)
.array~of(1, , 2, , 3)~pipe(.inject {value*30} recursive.2 | .console)


-- Same as previous example, but here, the recursive.memorize option is used.
-- The index is like a call stack : you get one pair (value, resultIndex) for each level of recursion.
-- Ex : the last line is
-- (an Array),5|3,1|90,1|2700,1 : 81000
-- The item at index 5 in input array has generated 3 intermediate pairs by recursion : (3,1) then (90,1) then (2700,1)
.array~of(1, , 2, , 3)~pipe(.inject {value*10} recursive.0.memorize | .console)
.array~of(1, , 2, , 3)~pipe(.inject {value*20} recursive.1.memorize | .console)
.array~of(1, , 2, , 3)~pipe(.inject {value*30} recursive.2.memorize | .console)


-- Factorial, no value injected for -1
.array~of(-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)~pipe(.inject {
    use arg n
    if n < 0 then return
    if n == 0 then return 1
    return n * .context~executable~call(n - 1)} | .console)


-- ----------------------------------------------------------------------------
-- Additional sorting facilities
-- ----------------------------------------------------------------------------

-- Select files in the installation directory, whose path contains "math" , sorted by file size.
-- The "length" message is sent to the value and the returned result is used as a key for sorting.
.file~new(installdir())~listFiles~pipe(,
    .all["math"] caseless |,
    .sortWith[.MessageComparator~new("length/N")] |,
    .console index ":" value {"length="value~length},
    )


-- Same as above, but simpler... You can sort directly by length, no need of MessageComparator
.file~new(installdir())~listFiles~pipe(,
    .all["math"] caseless |,
    .sort {value~length} |,
    .console index ":" value {"length="value~length},
    )


-- Sort by file size, then by file extension (with only one .sort pipestage)
.file~new(installdir())~listFiles~pipe(,
    .all["math"] caseless |,
    .sort {value~length} {filespec('e', value~name)} |,
    .console,
    )


-- ----------------------------------------------------------------------------
-- Various examples with collections and recursive processing
-- Illustration of the depthFirst vs breadthFirst options
-- ----------------------------------------------------------------------------

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
    .inject {value~instanceMethods(value~class)} after memorize |,
    .sort byIndex |,
    .console,
    )


-- Methods (not inherited) of all the classes whose id starts with "R".
.environment~pipe(,
    .select {value~isA(.class)} |,
    .select {value~id~caselessAbbrev('R') <> 0} |,
    .inject {value~methods(value)} after memorize |,
    .sort byIndex |,
    .console,
    )


-- All packages that are visible from current context, including the current package (source of the pipeline).
.context~package~pipe(,
    .inject {value~importedPackages} recursive.memorize after |,
    .console index.92,
             {'  '~copies(index~depth)},
             {.file~new(value~name)~name},
    )


-- Same as above, but in breadth-first order
.context~package~pipe(,
    .inject {value~importedPackages} recursive.breadthFirst.memorize after |,
    .console index.92,
             {'  '~copies(index~depth)},
             {.file~new(value~name)~name},
    )


-- ----------------------------------------------------------------------------
-- .take pipeStage
-- ----------------------------------------------------------------------------

-- The .take pipeStage lets stop the preceding pipeStages when the number of items to take
-- has been reached, whatever its position in the pipeline.
-- Note the "" at the end of the first .console. This is an indicator to not insert a newline.
supplier = .array~of(1,2,3,4,5,6,7,8,9)~supplier
supplier~pipe(.console "2*" value "=" "" | .do {return 2*value} | .take 2 | .console value)
say supplier~index -- this is the index of the last processed item
supplier~next -- skip the last processed item
supplier~pipe(.console "4*" value "=" "" | .do {return 4*value} | .take 4 | .console value)
say supplier~index


-- Display the 4 first sorted items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.sort | .take 4 | .console)


-- Sort the 4 first items
.array~of(5, 8, 1, 3, 6, 2)~pipe(.take 4 | .sort | .console)


-- Select files in the installation directory, whose name contains "rexx".
-- Note : the .select is not equivalent to .all["rexx"], because .select tests only the name,
-- whereas .all tests the string representation of the value, which is the absolute path.
-- Take the 15 firsts.
.file~new(installdir())~listFiles~pipe(,
    .select {value~name~caselessPos('rexx') <> 0} |,
    .take 15 |,
    .console,
    )


-- ----------------------------------------------------------------------------
-- .append pipeStage
-- ----------------------------------------------------------------------------

-- The .append pipeStage copies items from its primary input to its primary output, and then invokes
-- the producer passed as argument and writes the items produced by that producer to its primary output.
-- If the producer is a doer, then the producer is executed to get the effective producer.
-- If the effective producer understands the message "supplier" then each pair (value, index) returned
-- by the supplier is appended.
-- Otherwise, the effective producer is appended as-is (single object) with local index 1.
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


-- ----------------------------------------------------------------------------
-- pipeStages which support partitions
-- ----------------------------------------------------------------------------

-- Drop the first value
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop | .console)


-- Drop the first value of each partition
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop {value} | .console)


-- Drop the last value
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop last | .console)


-- Drop the last value of each partition
.array~of(1,1,1,2,2,2,3,3,3,1,1,1)~pipe(.drop last {value} | .console)


datas = .directory~new
datas["key1"] = .array~of("header", 1, 2, "footer")
datas["key2"] = .array~of("header", 5, 3, -9, 12, "footer")
datas["key3"] = .array~of("header", 4, 6, 5, "footer")


-- The whole datas, including headers and footers
datas~pipe(.inject {value} mem | .console)


-- The datas without the headers and footers
datas~pipe(.inject {value} memorize | .drop first {index["inject"]~value } | .drop last {index["inject"]~value } | .console)


-- No partition here, so the whole set of words is written twice, separated by "==="
.array~of("one two three","un deux trois")~pipe(.words | .buffer[2, "==="] | .console)


-- There is a partition on the strings received by .words, so there is a separator "===" between each set of words extracted from each string
.array~of("one two three","un deux trois")~pipe(.words mem | .buffer[2, "==="] {index["words"]~value} | .console)


-- ----------------------------------------------------------------------------
-- .fanout, .fanin, .merge pipeStages
-- ----------------------------------------------------------------------------

-- Here, only the output from fanout1 is sent to console.
fanout1 = .left[3]  mem | .lower mem
fanout2 = .right[3] mem | .upper mem | .inject {"my_"value} after
.array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout mem >> fanout2 > fanout1 | .console showTags)


-- Here, each branch of the fanout remains separated. Each branch has its own console.
fanout1 = .left[3]  mem | .lower mem | .console showTags
fanout2 = .right[3] mem | .upper mem | .inject {"my_"value} after | .console showTags
.array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout mem >> fanout2 > fanout1)


-- Here, a fanin is used to serialize the branches of the fanout.
-- The output from fanout1 is sent to console, then the output from fanout2 (delayed)
fanin = .fanin mem | .console showTags
fanout1 = .left[3]  mem | .lower mem | fanin  -- not bufferized
fanout2 = .right[3] mem | .upper mem | .inject {"my_"value} after | fanin~secondaryConnector -- bufferized until fanout1 is eof
.array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout mem >> fanout2 > fanout1)

-- Here, a merge is used to serialize the branches of the fanout.
-- There is no specific order (no delay).
merge = .merge mem | .console showTags
fanout1 = .left[3]  mem | .lower mem | merge  -- not bufferized
fanout2 = .right[3] mem | .upper mem | .inject {"my_"value} after | (merge)~secondaryConnector -- not bufferized
.array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout mem >> fanout2 > fanout1)


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
    .getFiles | .lineCount |,
    .console,
    )


-- Number of lines in each *.cls files of ooRexx
installdir()~pipe(,
    .fileTree recursive |,
    .endsWith[".cls"] |,
    .getFiles memorize | .lineCount {index["getFiles"]~value} |,
    .console,
    )


-- Total number of words in the *.cls files of ooRexx
installdir()~pipe(,
    .fileTree recursive |,
    .endsWith[".cls"] |,
    .getFiles | .wordCount |,
    .console,
    )


-- Number of words in each *.cls files of ooRexx
installdir()~pipe(,
    .fileTree recursive |,
    .endsWith[".cls"] |,
    .getFiles memorize | .wordCount {index["getFiles"]~value} |,
    .console,
    )


-- Total number of characters in the *.cls files of ooRexx (not counting the newline characters)
installdir()~pipe(,
    .fileTree recursive |,
    .endsWith[".cls"] |,
    .getFiles | .charCount |,
    .console,
    )


-- Number of characters in each *.cls files of ooRexx (not counting the newline characters)
installdir()~pipe(,
    .fileTree recursive |,
    .endsWith[".cls"] |,
    .getFiles memorize | .charCount {index["getFiles"]~value} |,
    .console,
    )


-- From here, some methods of the pipeline classes are instrumented to let profiling.
-- The performances are impacted because the profiled methods are instrumented with an additional forward.
.pipeProfiler~instrument("start", "process", "eof", "isEOP")


-- Alphanumeric words of 16+ chars found in the *.cls files of ooRexx.
-- Only the first two words per file are taken :
--     .take 2 {index["getFiles"]~value}
-- Here, the partition expression returns the file object processed by the pipeStage "getFiles".
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
    .endsWith[".cls"] |,
    .getFiles memorize | .words | .select {value~datatype('a') & value~length >= 16} |,
    .take 2 {index["getFiles"]~value} | .sort caseless | .console,
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

