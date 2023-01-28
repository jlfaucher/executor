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

All the pipe stages support the common option "memorize[.tag]".

For the pipe stages supporting the option "recursive", an option "recursive.memorize" is available.
The common option "memorize[.tag]" is still needed to assign a tag.

.ItemToIndexItem :    I1 -- O1              -- convert an item of type array [newIndex, newItem] to an indexed item:
                                            -- the input index is replaced by newIndex
                                            -- the input item is replaced by newItem

.SecondaryConnector : I1 --> I2             -- adapter which forwards to its follower's secondary input

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

.fanout : I1 --- O1, O2                     -- Write records to both outputs streams.
.merge : I1, I2 --- O1                      -- Merge the results from primary and secondary streams (no specific order : no delay).
.fanin : I1, I2 (accumulator) --- O1        -- Process main stream, then secondary stream.

.duplicate : I1 --- O1
    [copies = 1]
.console : I1 --- O1
    (['index'[.width]] ['item'[.width]] ['dataflow'[.width]] [<any other string>] [<expression-doer>])*

.all[patterns...] : I1 --- O1 (selected), O2 (not selected)
    ['caseless']
.notall[patterns...] : I1 --- O1 (selected), O2 (not selected)
    ['caseless']
.startsWith[patterns...] : I1 --- O1 (selected), O2 (not selected)
    ['caseless']
.endsWith[patterns...] : I1 --- O1 (selected), O2 (not selected)
    ['caseless']

.stemcollector[stem] : I1 (non blocking accumulator) --- O1
.arraycollector[itemArray, indexArray=.nil, dataFlowArray=.nil] : I1 (non blocking accumulator) --- O1
.directorycollector[directory] : I1 (non blocking accumulator) --- O1

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

.pivot[pivotItem, next, secondary] : I1 --- O1, O2      -- If item < pivotItem then route to O1 else route to O2
.splitter[stages...] : I1 --- O1, O2, ...               -- split the processing stream into two or more pipeStages

.linesIn : I1 --- O1                        -- Equivalent to the < CMS pipe stage, except the argument can be taken from I1
    ["<file>"|<expression-doer>]
(was .fileLines)

.words : I1 --- O1
.characters : I1 --- O1

.system : I1 --- O1
    ["<command>"|<command-doer>]


The followings pipeStages need an extended interpreter
------------------------------------------------------

.append : I1 --- O1
    <producer-doerFactory>
    [iterate]

.inject : I1 --- O1
    ['after']
    ['before']
    [iterateAfter]
    [iterateBefore]
    ['once']
    ['recursive[.<limit>][.breadthFirst|.depthFirst][.cycles][.memorize]']
    ['trace']
    <producer-doerFactory>

.fileTree : I1 --- O1
    ['after']
    ['before']
    [iterateAfter]
    [iterateBefore]
    ['once']
    ['recursive[.<limit>][.breadthFirst|.depthFirst][.cycles][.memorize]']
    ['trace']

.superClasses : I1 --- O1
    ['after']
    ['before']
    [iterateAfter]
    [iterateBefore]
    ['once']
    ['recursive[.<limit>][.breadthFirst|.depthFirst][.cycles][.memorize]']
    ['trace']

.subClasses : I1 --- O1
    ['after']
    ['before']
    [iterateAfter]
    [iterateBefore]
    ['once']
    ['recursive[.<limit>][.breadthFirst|.depthFirst][.cycles][.memorize]']
    ['trace']

.class.instanceMethods : I1 --- O1
    ['after']
    ['before']
    [iterateAfter]
    [iterateBefore]
    ['once']
    ['recursive[.<limit>][.breadthFirst|.depthFirst][.cycles][.memorize]']
    ['trace']

.instanceMethods : I1 --- O1
    ['after']
    ['before']
    [iterateAfter]
    [iterateBefore]
    ['once']
    ['recursive[.<limit>][.breadthFirst|.depthFirst][.cycles][.memorize]']
    ['trace']

.importedPackages : I1 --- O1
    ['after']
    ['before']
    [iterateAfter]
    [iterateBefore]
    ['once']
    ['recursive[.<limit>][.breadthFirst|.depthFirst][.cycles][.memorize]']
    ['trace']

.select : I1 --- O1 (selected), O2 (not selected)
    <filter-doer>


The followings pipeStages can be used only in a copipe
------------------------------------------------------

.yield : I1 --- O1
    (['index'] ['item'] [<expression-doer>])*

A .yield stage is equivalent to a fitting stage, that allows to both read from
and write into the pipeline.
The arguments passed on resume are available in
    pipeContext~args        -- array (can be empty)
    pipeContext~namedArgs   -- directory (can be empty)
