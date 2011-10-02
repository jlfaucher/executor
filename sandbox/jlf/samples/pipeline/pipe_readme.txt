=========================================
Possible integration in oorexxshell
=========================================

Currently the input line is assumed to be in totality either ooRexx syntax or 'address' syntax (cmd, bash, hostemu, 'the')
A command line can start with an interpreter name (oorexx, cmd, bash) and the rest of the line will be processed by the corresponding interpreter.
If the input line can be splitted in different syntaxes, then the following command line becomes possible :
    cmd[dir *.exe] | lineCount
Here, cmd[...] is both a syntax annotation and a pipeStage
If the stdout of the command is sent to a Rexx queue then it should be possible to make it enter in a pipeline.


=========================================
Notes about pipes
=========================================

fanout : forward eof to self~next and self~secondary, but not to super

merge : send a 'done' message

console : process does forward class (super) --> why needed here, and not in other classes ?
answer : because .console does not transform the values, it just displays them. So it can
forward to class (super) which will take care of sending the value & index to next pipestage.
The other classes transform the values, and write themselves the new value. If they forwarded
to class (super) then the unchanged value would be also sent to the next pipeStage.


http://freshmeat.net/projects/pv
pv (Pipe Viewer) is a terminal-based tool for monitoring the progress of data through a pipeline.
It can be inserted into any normal pipeline between two processes to give a visual indication of
how quickly data is passing through, how long it has taken, how near to completion it is, and an
estimate of how long it will be until completion.


http://www.softpanorama.org/Scripting/Shellorama/Control_structures/pipes_in_loops.shtml


=========================================
Documentation
=========================================


Connectors
::method '|' class                          -- concatenate an instance of a pipeStage with following pipeStage 'primary follower)
::method '>' class                          -- concatenate an instance of a pipeStage with following pipeStage (same as '|')
::method '>>' class                         -- concatenate an instance of a pipeStage with following pipeStage (secondary follower)


pipeStage
    SecondaryConnector(pipeStage)

    sort (['ascending'|'descending'] ['case'|'caseless'] ['numeric'|'strict'] ['quickSort'|'stableSort'] ['byIndex'|'byValue'|{criteria}])* -- primary (accumulator)
    sortWith(comparator) ['quickSort'|'stableSort'] -- primary (accumulator)

    reverse
    upper
    lower
    changestr(old, new, count = 999999999)
    delstr(offset, length)
    left(length)                            -- primary, secondary
    right(length)                           -- primary, secondary
    insert(insert, offset)
    overlay(overlay, offset)

    dropnull
    drop ['first'] [counter=1] [{partition}]-- primary, secondary
    drop last [counter=1] [{partition}]     -- primary (accumulator), secondary (accumulator)
    take ['first'] [counter=1] [{partition}]-- primary, secondary
    take last [counter=1] [{partition}]     -- primary (accumulator), secondary (accumulator)

    x2c

    bitbucket

    fanout                                  -- primary, secondary. Write records to both outputs streams.
    merge                                   -- primary, secondary. Merge the results from primary and secondary streams (no specific order : no delay).
    fanin                                   -- primary(in out), secondary (in accumulator). Process main stream, then secondary stream.

    duplicate [copies = 1]
    console (['index'] ['value'] ['showTags'] [<any other string>] [{expression}])*

    all(patterns...) ['caseless']           -- primary, secondary (mismatches)
    notall(patterns...) ['caseless']        -- primary, secondary (not selected)
    startsWith(patterns...) ['caseless']      -- primary, secondary (mismatches)
    endsWith(patterns...) ['caseless']        -- primary, secondary (mismatches)

    stemcollector(stem)                     -- primary (non blocking accumulator)
    arraycollector(array)                   -- primary (non blocking accumalator)

    between(startString, endString) ['caseless'] -- primary, secondary (not selected)
    after(startString) ['caseless']         -- primary, secondary (while not started)
    before(endString) ['caseless']          -- primary, secondary (after started)

    buffer(count = 1, delimiter = "") [{partition}] -- primary (accumulator)

    lineCount [{partition}]
    charCount [{partition}]
    wordCount [{partition}]

    pivot(pivotvalue, next, secondary)      -- primary, secondary. If value < pivotvalue then route to next else route to secondary
    splitter(stages...)                     -- primary (in). split the processing stream into two or more pipeStages

    getFiles
    words
    characters

    system ["command"|{command}]

    append {producer}

    inject          ['after'] ['before'] ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]'] ['unique'] ['trace'] {producer}
    do              ['after'] ['before'] ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]'] ['unique'] ['trace'] {producer}
    fileTree        ['after'] ['before'] ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]'] ['unique'] ['trace'] {producer}
    superClasses    ['after'] ['before'] ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]'] ['unique'] ['trace'] {producer}
    subClasses      ['after'] ['before'] ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]'] ['unique'] ['trace'] {producer}
    methods         ['after'] ['before'] ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]'] ['unique'] ['trace'] {producer}
    instanceMethods ['after'] ['before'] ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]'] ['unique'] ['trace'] {producer}

    select {filter}
