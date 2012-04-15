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
    ['ascending'|'descending']              -- default : 'ascending'
    ['case'|'caseless']                     -- default : 'case'
    ['numeric'|'strict']                    -- default : 'numeric'
    ['quickSort'|'stableSort']              -- default : 'stableSort'
    ['byIndex'|'byItem'|<criteria-doer>])*  -- default : 'byItem'
.sortWith[comparator] : I1 --- O1 (delayed)
    ['quickSort'|'stableSort']              -- default : 'stableSort'

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
    [counter=1] [<partition-doer>]
.drop 'last' : I1 --- O1 (delayed), O2 (delayed)
    [counter=1] [<partition-doer>]
.take 'first' : I1 --- O1, O2
    [counter=1] [<partition-doer>]
.take 'last' : I1 --- O1 (delayed), O2 (delayed)
    [counter=1] [<partition-doer>]

.x2c : I1 --- O1

.bitbucket : I1 --- (no ouput)

.fanout : I1 --- O1, O2 -- Write records to both outputs streams.
.merge : I1, I2 --- O1 -- Merge the results from primary and secondary streams (no specific order : no delay).
.fanin : I1, I2 (accumulator) --- O1 -- Process main stream, then secondary stream.

.duplicate : I1 --- O1
    [copies = 1]
.console : I1 --- O1
    (['index'] ['item'] [<any other string>] [<expression-doer>])*

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
    [<partition-doer>]

.lineCount : I1 --- O1 (delayed)
    [<partition-doer>]
.charCount : I1 --- O1 (delayed)
    [<partition-doer>]
.wordCount : I1 --- O1 (delayed)
    [<partition-doer>]

.pivot[pivotItem, next, secondary] : I1 --- O1, O2 -- If item < pivotItem then route to O1 else route to O2
.splitter[stages...] : I1 --- O1, O2, ... -- split the processing stream into two or more pipeStages

.fileLines : I1 --- O1
.words : I1 --- O1
.characters : I1 --- O1

.system : I1 --- O1
    ["<command>"|<command-doer>]

.append : I1 --- O1
    <producer-doer>

.inject : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']
    <producer-doer>

.do : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']
    <producer-doer>

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

.importedPackages : I1 --- O1
    ['after']
    ['before']
    ['recursive[.breadthFirst|.depthFirst][.cycles][.memorizeIndex]']
    ['unique']
    ['trace']

.select : I1 --- O1 (selected), O2 (not selected)
    <filter-doer>
