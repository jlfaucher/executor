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
----------
::method '|' class     -- concatenate an instance of a pipeStage with following pipeStage 'primary follower) : O1 --> I1
::method '>' class     -- concatenate an instance of a pipeStage with following pipeStage (same as '|')
::method '>>' class    -- concatenate an instance of a pipeStage with following pipeStage (secondary follower) : O2 --> I1


pipeStages
----------

.SecondaryConnector : I1 --> I2 -- adapter which forwards to its follower's secondary input

.sort : I1 --- O1 (delayed)
    ['ascending'|'descending']
    ['case'|'caseless']
    ['numeric'|'strict']
    ['quickSort'|'stableSort']
    ['byIndex'|'byValue'|{criteria}])*
.sortWith[comparator] : I1 --- O1 (delayed)
    ['quickSort'|'stableSort']

.reverse : I1 --- O1
.upper : I1 --- O1
.lower : I1 --- O1
.changestr[old, new, count = 999999999] : I1 --- O1
.delstr[offset, length] : I1 --- O1
.left[length] : I1 --- O1, O2
.right[length] : I1 --- O1, O2
.insert[insert, offset] : I1 --- O1
.overlay[overlay, offset] : I1 --- O1

.dropnull : I1 --- O1
.drop 'first' : I1 --- O1, O2
    [counter=1] [{partition}]
.drop 'last' : I1 --- O1 (delayed), O2 (delayed)
    [counter=1] [{partition}]
.take 'first' : I1 --- O1, O2
    [counter=1] [{partition}]
.take 'last' : I1 --- O1 (delayed), O2 (delayed)
    [counter=1] [{partition}]

.x2c : I1 --- O1

.bitbucket : I1 --- (no ouput)

.fanout : I1 --- O1, O2 -- Write records to both outputs streams.
.merge : I1, I2 --- O1 -- Merge the results from primary and secondary streams (no specific order : no delay).
.fanin : I1, I2 (accumulator) --- O1 -- Process main stream, then secondary stream.

.duplicate : I1 --- O1
    [copies = 1]
.console : I1 --- O1
    (['index'] ['value'] ['showTags'] [<any other string>] [{expression}])*

.all[patterns...] : I1 --- O1 (selected), O2 (not selected)
    ['caseless']
.notall[patterns...] : I1 --- O1 (selected), O2 (not selected)
    ['caseless']
.startsWith[patterns...] : I1 --- O1 (selected), O2 (not selected)
    ['caseless']
.endsWith[patterns...] : I1 --- O1 (selected), O2 (not selected)
    ['caseless']

.stemcollector[stem] : I1 (non blocking accumulator) --- O1
.arraycollector[array] : I1 (non blocking accumalator) --- O1

.between[startString, endString] : I1 --- O1 (selected), O2 (not selected)
    ['caseless']
.after[startString] : I1 --- O1 (after started), O2 (while not started)
    ['caseless']
.before[endString] : I1 --- O1 (while not started), O2 (after started)
    ['caseless']

.buffer[count = 1, delimiter = ""] : I1 --- O1 (delayed)
    [{partition}]

.lineCount : I1 --- O1 (delayed)
    [{partition}]
.charCount : I1 --- O1 (delayed)
    [{partition}]
.wordCount : I1 --- O1 (delayed)
    [{partition}]

.pivot[pivotvalue, next, secondary] : I1 --- O1, O2 -- If value < pivotvalue then route to O1 else route to O2
.splitter[stages...] : I1 --- O1, O2, ... -- split the processing stream into two or more pipeStages

.getFiles : I1 --- O1
.words : I1 --- O1
.characters : I1 --- O1

.system : I1 --- O1
    ["command"|{command}]

.append : I1 --- O1
    {producer}

.inject : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']
    {producer}

.do : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']
    {producer}

.fileTree : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']

.superClasses : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']

.subClasses : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']

.methods : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']

.instanceMethods : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']

.select : I1 --- O1 (selected), O2 (not selected)
    {filter}
