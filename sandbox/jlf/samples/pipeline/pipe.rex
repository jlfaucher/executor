#!/usr/bin/rexx
--::options trace i
/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2006 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.oorexx.org/license.html                                         */
/*                                                                            */
/* Redistribution and use in source and binary forms, with or                 */
/* without modification, are permitted provided that the following            */
/* conditions are met:                                                        */
/*                                                                            */
/* Redistributions of source code must retain the above copyright             */
/* notice, this list of conditions and the following disclaimer.              */
/* Redistributions in binary form must reproduce the above copyright          */
/* notice, this list of conditions and the following disclaimer in            */
/* the documentation and/or other materials provided with the distribution.   */
/*                                                                            */
/* Neither the name of Rexx Language Association nor the names                */
/* of its contributors may be used to endorse or promote products             */
/* derived from this software without specific prior written permission.      */
/*                                                                            */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */
/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */
/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */
/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */
/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */
/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */
/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */
/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */
/*                                                                            */
/*----------------------------------------------------------------------------*/
/******************************************************************************/
/*  pipe.rex            Open Object Rexx Samples                              */
/*                                                                            */
/*  A pipeline implementation                                                 */
/*                                                                            */
/* -------------------------------------------------------------------------- */
/*                                                                            */
/*  Description:                                                              */
/*  This program demonstrates the use of ::class and ::method directives to   */
/*  create a simple implementation of a CMS-like pipeline function.           */
/******************************************************************************/


/**
 * Base pipeStage class.  Most sub classes need only override the process() method to
 * implement a pipeStage.  The transformed results are passed down the pipeStage chain
 * by calling the write method.
 */

::class pipeStage public                    -- base pipeStage class
::method init
expose next secondary options
next = .nil
secondary = .nil                            -- all pipeStages have a secondary output potential
options = .array~new                        -- arguments can be passed like that : .myStage~new(a1,a2) or .myStage[a1,a2] or .myStage a1 a2

::method '|' class                          -- concatenate an instance of a pipeStage with following pipeStage
use strict arg follower
me = self~new                               -- create a new pipeStage instance
return me|follower                          -- perform the hook up

::method '>' class                          -- concatenate an instance of a pipeStage with following pipeStage
use strict arg follower
me = self~new                               -- create a new pipeStage instance
return me>follower                          -- perform the hook up

::method '>>' class                         -- concatenate an instance of a pipeStage with following pipeStage
use strict arg follower
me = self~new                               -- create a new pipeStage instance
return me>>follower                         -- perform the hook up

::method '|'
use strict arg follower
follower = follower~new                     -- make sure this is an instance
self~append(follower)                       -- do the chain append logic
return self                                 -- we're our own return value

::method '>'
use strict arg follower
follower = follower~new                     -- make sure this is an instance
self~append(follower)                       -- do the chain append logic
return self                                 -- we're our own return value

::method '>>'
use strict arg follower
follower = follower~new                     -- make sure this is an instance
self~appendSecondary(follower)              -- do the chain append logic
return self                                 -- we're our own return value

::method append                             -- append a pipeStage to the entire chain
expose next
use strict arg follower
if .nil == next then do                     -- if we're the end already, just update the next
    next = follower
end
else do
    next~append(follower)                   -- have our successor append it.
end

::method appendSecondary                    -- append a to the secondary output of entire chain
expose next secondary
use strict arg follower
if .nil == next then do                     -- if we're the end already, just update the next
    secondary = follower                    -- append this to the secondary port.
end
else do
    next~appendSecondary(follower)          -- have our successor append it.
end

::method insert                             -- insert a pipeStage after this one, but before the next
expose next
user strict arg newpipeStage
newpipeStage~next = next                    -- just hook into the chain
next = newpipeStage

-- .myStep[arg1, arg2]
::method '[]' class                         -- create a pipeStage instance with arguments
forward to (self) message('NEW')            -- just forward this as a new message

-- .myStep arg1 arg2
::method " " class                          -- another way to pass arguments (one by one)
use strict arg arg
instance = self~new                         -- no arg for init
instance~options~append(arg)
return instance

::method " "                                -- the 2nd argument and next are passed one by one
expose options
use strict arg arg                          -- to the instance
options~append(arg)
return self                                 -- by returning self, let chain the blank operators

::method go                                 -- execute using a provided object
expose source                               -- get the source supplier
use strict arg source                       -- set to the supplied object
self~begin                                  -- now go feed the pipeline

::method options attribute                  -- the options are passed one by one, accumulated here
::method secondary attribute                -- a potential secondary attribute
::method next attribute                     -- next stage of the pipeStage
::method source attribute                   -- source of the initial data
                                            -- that they are class objects for
::method new                                -- the pipeStage chaining process
return self                                 -- just return ourself

::method begin                              -- start pumping the pipeline
expose source                               -- access the data and next chain
self~start                                  -- signal that processing is starting
engine = source~supplier                    -- get a data supplier
do while engine~available                   -- while more data
  -- The index is passed as an array, because some pipeStage may create
  -- additional indexes that will be appended.
  self~process(engine~item, .array~of(engine~index)) -- pump this down the pipe
  engine~next                               -- get the next data item
end
self~eof                                    -- signal that processing is finished

::method start                              -- process "start-of-pipe" condition
expose next secondary options
forward continue arguments (options) message "initOptions" -- now we have all the options, lets process them
if .nil <> next then do
    next~start                              -- only forward if we have a successor
end
if .nil <> secondary then do
    secondary~start                         -- only forward if we have a successor
end

::method initOptions
-- Here, we receive the options that are unknown to the current pipeStage.
if arg() == 0 then return
do a over arg(1, "a")
    .stderr~lineout("Unknown option '"a"'") 
end
raise syntax 93.900 array("Unknown option") 

::method process                            -- default data processing
use strict arg value, index                 -- get the data item
self~write(value, index)                    -- send this down the line

::method write                              -- handle the result from a process method
expose next
use strict arg data, index
if .nil <> next then do
    next~process(data, index)               -- only forward if we have a successor
end

::method writeSecondary                     -- handle a secondary output result from a process method
expose secondary
use strict arg data, index
if .nil <> secondary then do
    secondary~process(data, index)          -- only forward if we have a successor
end

::method processSecondary                   -- handle a secondary output result from a process method
forward message('PROCESS')                  -- this by default is a merge operation

::method eof                                -- process "end-of-pipe" condition
expose next secondary
if .nil <> next then do
    next~eof                                -- only forward if we have a successor
end
if .nil <> secondary then do
    secondary~eof                           -- only forward if we have a successor
end

::method secondaryEof                       -- process "end-of-pipe" condition
-- we just ignore this one, and rely on the secondary

::method secondaryConnector                 -- retrieve a secondary connector for a pipeStage
return new .SecondaryConnector(self)

/******************************************************************************/
::class SecondaryConnector subclass pipeStage

::method init
expose pipeStage
use strict arg pipeStage                    -- this just hooks up
forward class (super)                       -- forward the initialization

::method process                            -- processing operations connect with pipeStage secondaries
expose pipeStage
forward to(pipeStage) message('processSecondary')

::method eof                                -- processing operations connect with pipeStage secondaries
expose pipeStage
forward to(pipeStage) message('secondaryEof')


/******************************************************************************/
::class indexedValue inherit Comparable
::attribute index -- always an array, even when only one value
::attribute value -- any type

::method init
expose value index
use strict arg value, index

::method compareTo
use strict arg other, start=1, length=(-1), caseless=.false
-- This method is called by ooRexx 'sort' framework, when appropriate.
-- So it's a bad idea to compare the indexes,  only the values must be compared.
-- This method is not used by the pipeline services, which offers specialized comparators.
-- To let use the standard ColumnComparator, I added the optional parameters start and length.
/*
comparator = .indexedValueComparator~new(caseless,,"index")
comparison = comparator~compare(self, other)
if comparison <> 0 then return comparison
*/
comparator = .indexedValueComparator~new(caseless)
comparison = comparator~compareTo(self, other, start, length)
return comparison

::method caselessCompareTo
use strict arg other, start=1, length=(-1)
return self~compareTo(other, start, length, .true)

-- Remember : compareTo and caselessCompareTo above are still necessary because the
-- 'other' argument is of type indexedValue. The unknown method below unboxes the
-- value of self, but not the value of other.
::method unknown
use strict arg msg, args
forward to (self~value) message (msg) arguments (args)


/******************************************************************************/
::class indexedValueComparator public inherit Comparator

::method init
expose caseless strict expression doer context
use strict arg caseless=.false, strict=.false, expression="value", context=.nil
doer = .nil
if expression~caselessEquals("value") then return
if expression~caselessEquals("index") then return
-- Parse the expression now (only once)
doer = self~makeFunctionDoer(expression, context) -- see pipe_extension

::method compareStrings
expose caseless strict
use strict arg s1, s2
if caseless then do
    s1 = s1~upper
    s2 = s2~upper
end
if strict then do
    if s1 << s2 then return -1
    if s1 >> s2 then return 1
end
else do
    if s1 < s2 then return -1
    if s1 > s2 then return 1
end
return 0

::method compareIndexes
use strict arg first, second
index1 = first~index
index2 = second~index
-- An index is an array of values
do i=1 to index1~dimension(1)
    i1 = index1[i]
    i2 = index2[i]
    if i1 == .nil & i2 == .nil then iterate
    if i1 == .nil then return -1
    if i2 == .nil then return 1
    compare = self~compareStrings(i1~string, i2~string)
    if compare <> 0 then return compare
end
return 0

::method compareValues
use strict arg first, second
value1 = first~value
value2 = second~value
return self~compareStrings(value1~string, value2~string)

::method compare
expose expression
use strict arg first, second
if expression~caselessEquals("index") then return self~compareIndexes(first, second)
if expression~caselessEquals("value") then return self~compareValues(first, second)
return self~compareExpressions(first, second)

-- For convenience, add support for .ColumnComparator.
-- The comparison is by value.
::method compareTo
use strict arg first, second, start=1, length=(-1)
value1 = first~value
value2 = second~value
if length == -1 then do
    s1 = value1~string~substr(start)
    s2 = value2~string~substr(start)
end
else do
    s1 = value1~string~substr(start, length)
    s2 = value2~string~substr(start, length)
end
return self~compareStrings(s1, s2)


/******************************************************************************/
::class sort public subclass pipeStage      -- sort piped data
::attribute descending
::attribute caseless
::attribute quickSort
::attribute strict

::method init
expose items context
use strict arg context=.nil                 -- will be used for the options of type expression
items = .array~new                          -- create a new list
forward class (super)

::method initOptions
expose descending caseless quickSort strict criteria
descending = .false
caseless = .false
quickSort = .false -- use a stable sort by default
strict = .false
unknown = .array~new
criteria = .array~new
do a over arg(1, "a")
    if "byIndex"~caselessAbbrev(a, 3) then criteria~append(.array~of("sortBy", "index")) 
    else if "byValue"~caselessAbbrev(a, 1) then criteria~append(.array~of("sortBy", "value"))
    else if "ascending"~caselessAbbrev(a, 1) then criteria~append(.array~of("descending=", .false))
    else if "descending"~caselessAbbrev(a, 1) then criteria~append(.array~of("descending=", .true))
    else if "case"~caselessAbbrev(a, 4) then criteria~append(.array~of("caseless=", .false))
    else if "caseless"~caselessAbbrev(a, 5) then criteria~append(.array~of("caseless=", .true))
    else if "stableSort"~caselessAbbrev(a, 3) then criteria~append(.array~of("quickSort=", .false))
    else if "quickSort"~caselessAbbrev(a, 1) then criteria~append(.array~of("quickSort=", .true))
    else if "numeric"~caselessAbbrev(a, 1) then criteria~append(.array~of("strict=", .false))
    else if "strict"~caselessAbbrev(a, 3) then criteria~append(.array~of("strict=", .true))
    else do
        -- The sort by expression is an optional feature, not available with standard ooRexx.
        -- compareExpressions depends on doers, and is implemented in a separate file.
        if .indexedValueComparator~method("compareExpressions") <> .nil
            then criteria~append(.array~of("sortBy", a)) -- assume this is an expression
            else unknown~append(a)
    end
end
forward class (super) arguments (unknown)    -- forward the initialization to super to process the unknown options

::method sortBy
expose items context descending caseless quickSort strict
use strict arg criterion
comparator = .indexedValueComparator~new(caseless, strict, criterion, context)
if descending then comparator = .InvertingComparator~new(comparator)
if quickSort then items~sortWith(comparator)
             else items~stableSortWith(comparator)

::method process                            -- process sorter piped data item
expose items                                -- access internal state data
use strict arg value, index                 -- access the passed value
items~append(.indexedValue~new(value, index))

::method eof                                -- process the "end-of-pipe"
expose items criteria
do criterion over criteria                  -- apply each criterion
    message = criterion[1]
    argument = criterion[2]
    self~send(message, argument)
end
do i = 1 to items~items                     -- copy all sorted items to the primary stream
   indexedValue = items[i]
   self~write(indexedValue~value, indexedValue~index)
end
forward class(super)                        -- make sure we propagate the done message


/******************************************************************************/
::class sortWith public subclass pipeStage  -- sort piped data

::method init
expose items comparator                     -- list of sorted items
use strict arg comparator                   -- get the comparator
items = .array~new                          -- create a new list
forward class (super)                       -- forward the initialization

::method initOptions
expose quickSort
quickSort = .false -- use a stable sort by default
unknown = .array~new
do a over arg(1, "a")
    if "quickSort"~caselessAbbrev(a, 1) then quickSort = .true
    else unknown~append(a) 
end
forward class (super) arguments (unknown)    -- forward the initialization to super to process the unknown options

::method process                            -- process sorter piped data item
expose items                                -- access internal state data
use strict arg value, index                 -- access the passed value
items~append(.indexedValue~new(value, index)) -- append the value to the accumulator array

::method eof                                -- process the "end-of-pipe"
expose items comparator quickSort
if quickSort then items~sortWith(comparator)
             else items~stableSortWith(comparator)
do i = 1 to items~items                     -- copy all sorted items to the primary stream
   indexedValue = items[i]
   self~write(indexedValue~value, indexedValue~index)
end
forward class(super)                        -- make sure we propagate the done message


/******************************************************************************/
::class reverse public subclass pipeStage   -- a string reversal pipeStage
::method process                            -- pipeStage processing item
use strict arg value, index                 -- get the data item
self~write(value~string~reverse, index) -- send it along in reversed form


/******************************************************************************/
::class upper public subclass pipeStage     -- a uppercasing pipeStage
::method process                            -- pipeStage processing item
use strict arg value, index                 -- get the data item
self~write(value~string~upper, index) -- send it along in upper form


/******************************************************************************/
::class lower public subclass pipeStage     -- a lowercasing pipeStage
::method process                            -- pipeStage processing item
use strict arg value, index                 -- get the data item
self~write(value~string~lower, index) -- send it along in lower form


/******************************************************************************/
::class changestr public subclass pipeStage -- a string replacement pipeStage

::method init
expose old new count
use strict arg old, new, count = 999999999  -- old and new are required, default count is max value
forward class (super)                       -- forward the initialization

::method process                            -- pipeStage processing item
expose old new count
use strict arg value, index                 -- get the data item
self~write(value~string~changestr(old, new, count), index) -- send it along in altered form


/******************************************************************************/
::class delstr public subclass pipeStage    -- a string deletion pipeStage

::method init
expose offset length
use strict arg offset, length               -- both are required.
forward class (super)                       -- forward the initialization

::method process                            -- pipeStage processing item
expose offset length
use strict arg value, index                 -- get the data item
self~write(value~string~delstr(offset, length), index) -- send it along in altered form


/******************************************************************************/
::class left public subclass pipeStage      -- a splitter pipeStage

::method init
expose length
use strict arg length                       -- the length is the left part
forward class (super)                       -- forward the initialization

::method process                            -- pipeStage processing item
expose length
use strict arg value, index                 -- get the data item
self~write(value~string~left(length), index) -- send the left portion along the primary stream
self~writeSecondary(value~string~substr(length + 1), index) -- the secondary gets the remainder portion


/******************************************************************************/
::class right public subclass pipeStage     -- a splitter pipeStage

::method init
expose length
use strict arg length                       -- the length is the right part
forward class (super)                       -- forward the initialization

::method process                            -- pipeStage processing item
expose offset length
use strict arg value, index                 -- get the data item
self~write(value~string~substr(length + 1), index) -- the remainder portion goes down main pipe
self~writeSecondary(value~string~left(length), index) -- send the left portion along the secondary stream


/******************************************************************************/
::class insert public subclass pipeStage    -- insert a string into each line

::method init
expose insert offset
use strict arg insert, offset               -- we need an offset and an insertion string
forward class (super)                       -- forward the initialization

::method process                            -- pipeStage processing item
expose insert offset
use strict arg value, index                 -- get the data item
self~write(value~string~insert(insert, offset), index) -- send the left portion along the primary stream


/******************************************************************************/
::class overlay public subclass pipeStage   -- overlay a string into each line

::method init
expose overlay offset
use strict arg overlay, offset              -- we need an offset and an insertion string
forward class (super)                       -- forward the initialization

::method process                            -- pipeStage processing item
expose insert offset
use strict arg value, index                 -- get the data item
self~write(value~string~overlay(overlay, offset), index) -- send the left portion along the primary stream


/******************************************************************************/
::class dropnull public subclass pipeStage  -- drop null records

::method process                            -- pipeStage processing item
use strict arg value, index                 -- get the data item
if value~string \== '' then do              -- forward along non-null records
    self~write(value, index)
end


/******************************************************************************/
::class dropFirst public subclass pipeStage -- drop the first n records

::method init
expose count counter
use strict arg count
counter = 0
forward class (super)                       -- forward the initialization

::method process
expose count counter
use strict arg value, index
counter += 1                                -- if we've dropped our quota, start forwarding
if counter > count then do
    self~write(value, index)
end
else do
    self~writeSecondary(value, index)       -- non-selected records go down the secondary stream
end


/******************************************************************************/
::class dropLast public subclass pipeStage  -- drop the last n records

::method init
expose count array
use strict arg count
array = .array~new                          -- we need to accumulate these until the end
forward class (super)                       -- forward the initialization

::method process
expose array
use strict arg value, index
array~append(.indexedValue~new(value, index)) -- just add to the accumulator

::method eof
expose count array
if array~items < count then do              -- didn't even receive that many items?
    loop indexedValue over array
        self~write(indexedValue~value, indexedValue~index) -- send everything down the main pipe
    end
end
else do
    first = array~items - count             -- this is the count of discarded items
    loop i = 1 to first
        indexedValue = array[i]
        self~writeSecondary(indexedValue~value, indexedValue~index) -- the discarded ones go to the secondary pipe
    end
    loop i = first + 1 to array~items
        indexedValue = array[i]
        self~write(indexedValue~value, indexedValue~index) -- the remainder ones go down the main pipe
    end
end
forward class(super)                        -- make sure we propagate the done message


/******************************************************************************/
::class takeFirst public subclass pipeStage -- take the first n records

::method init
expose count counter
use strict arg count
counter = 0
forward class (super)                       -- forward the initialization

::method process
expose count counter
use strict arg value, index
counter += 1                                -- if we've dropped our quota, stop forwarding
if counter > count then do
    self~writeSecondary(value, index)
end
else do
    self~write(value, index)                -- still in the first bunch, send to main pipe
end


/******************************************************************************/
::class takeLast public subclass pipeStage  -- drop the last n records

::method init
expose count array
use strict arg count
array = .array~new                          -- we need to accumulate these until the end

::method process
expose array
use strict arg value, index
array~append(.indexedValue~new(value, index)) -- just add to the accumulator

::method eof
expose count array
if array~items < count then do              -- didn't even receive that many items?
    loop indexedValue over array
        self~writeSecondary(indexedValue~value, indexedValue~index) -- send everything down the secondary pipe
    end
end
else do
    first = array~items - count             -- this is the count of selected items
    loop i = 1 to first
        indexedValue = array[i]
        self~write(indexedValue~value, indexedValue~index) -- the selected go to the main pipe
    end
    loop i = first + 1 to array~items
        indexedValue = array[i]
        self~writeSecondary(indexedValue~value, indexedValue~index) -- the discarded ones go down the secondary pipe
    end
end
forward class(super)                        -- make sure we propagate the done message


/******************************************************************************/
::class x2c public subclass pipeStage       -- translate records to hex characters

::method process                            -- pipeStage processing item
use strict arg value, index                 -- get the data item
self~write(value~string~x2c)


/******************************************************************************/
::class bitbucket public subclass pipeStage -- just consume the records

::method process                            -- pipeStage processing item
nop                                         -- do nothing with the data


/******************************************************************************/
::class fanout public subclass pipeStage    -- write records to both output streams

::method process                            -- pipeStage processing item
use strict arg value, index                 -- get the data item
self~write(value, index)
self~writeSecondary(value, index)

::method eof                                -- make sure done messages get propagated along all streams
self~next~eof
self~secondary~eof


/******************************************************************************/
::class merge public subclass pipeStage     -- merge the results from primary and secondary streams

::method init
expose mainDone secondaryEof                -- need pair of EOF conditions
use strict arg -- none
mainDone = .false
secondaryEof = .false
forward class (super)                       -- forward the initialization

::method eof
expose mainDone secondaryEof                -- need interlock flags
if secondaryEof then do                     -- the other input hit EOF already?
    forward class(super)                    -- handle as normal
end
mainDone = .true                            -- mark this branch as finished.

::method secondaryEof                       -- eof on the seconary input
expose mainDone secondaryEof                -- need interlock flags
secondaryEof = .true                        -- mark ourselves finished
if mainDone then do                         -- if both branches finished, do normal done.
    forward message('DONE')
end


/******************************************************************************/
::class fanin public subclass pipeStage     -- process main stream, then secondary stream

::method init
expose mainDone secondaryEof array          -- need pair of EOF conditions
use strict arg -- none
mainDone = .false
secondaryEof = .false
array = .array~new                          -- accumulator for secondary
forward class (super)                       -- forward the initialization

::method processSecondary                   -- handle the secondary input
expose array
use strict arg value, index
array~append(.indexedValue~new(value, index)) -- just append to the end of the array

::method eof
expose mainDone secondaryEof array          -- need interlock flags
if secondaryEof then do                     -- the other input hit EOF already?
    loop i = 1 to array~items               -- need to write out the deferred items
        indexedValue = array[i]
        self~write(indexedValue~value, indexedValue~index)
    end
    forward class(super)                    -- handle as normal
end
mainDone = .true                            -- mark this branch as finished.

::method secondaryEof                       -- eof on the seconary input
expose mainDone secondaryEof                -- need interlock flags
secondaryEof = .true                        -- mark ourselves finished
if mainDone then do                         -- if both branches finished, do normal done.
    forward message('DONE')
end


/******************************************************************************/
::class duplicate public subclass pipeStage -- duplicate each record N times

::method init
expose copies
use strict arg copies = 1                   -- by default, we do one duplicate
forward class (super)                       -- forward the initialization

::method process                            -- pipeStage processing item
expose copies
use strict arg value, index                 -- get the data item
loop copies + 1                             -- write this out with the duplicate count
    self~write(value, index)
end


/******************************************************************************/
::class displayer subclass pipeStage public

::method process                            -- process a data item
use strict arg value, index                 -- get the data value
say index~tostring(, ".") ":" value         -- display this item
forward class(super)


/******************************************************************************/
::class all public subclass pipeStage       -- a string selector pipeStage

::method init
expose patterns                             -- access the exposed item
use strict arg ...
patterns = arg(1,'a')                       -- get the patterns list
forward class (super)                       -- forward the initialization

::method process                            -- process a selection pipeStage
expose patterns                             -- expose the pattern list
use strict arg value, index                 -- access the data item
do i = 1 to patterns~size                   -- loop through all the patterns
                                            -- this pattern in the data?
  if (value~string~pos(patterns[i]) <> 0) then do
    self~write(value, index)                -- send it along
    return                                  -- stop the loop
  end
end
self~writeSecondary(value, index)           -- send all mismatches down the other branch, if there


/******************************************************************************/
::class caselessAll public subclass pipeStage -- a string selector pipeStage

::method init
expose patterns                             -- access the exposed item
use strict arg ...
patterns = arg(1,'a')                       -- get the patterns list
forward class (super)                       -- forward the initialization

::method process                            -- process a selection pipeStage
expose patterns                             -- expose the pattern list
use strict arg value, index                 -- access the data item
do i = 1 to patterns~size                   -- loop through all the patterns
                                            -- this pattern in the data?
  if (value~string~caselessPos(patterns[i]) <> 0) then do
    self~write(value, index)                -- send it along
    return                                  -- stop the loop
  end
end
self~writeSecondary(value, index)           -- send all mismatches down the other branch, if there


/******************************************************************************/
::class startsWith public subclass pipeStage -- a string selector pipeStage

::method init
expose match                                -- access the exposed item
use strict arg match                        -- get the patterns list
forward class (super)                       -- forward the initialization

::method process                            -- process a selection pipeStage
expose match                                -- expose the pattern list
use strict arg value, index                 -- access the data item
if (value~string~pos(match) == 1) then do -- match string occur in first position?
  self~write(value, index)                  -- send it along
end
else do
   self~writeSecondary(value, index)        -- send all mismatches down the other branch, if there
end


/******************************************************************************/
::class notall public subclass pipeStage    -- a string de-selector pipeStage

::method init
expose patterns                             -- access the exposed item
use strict arg ...
patterns = arg(1,'a')                       -- get the patterns list
forward class (super)                       -- forward the initialization

::method process                            -- process a selection pipeStage
expose patterns                             -- expose the pattern list
use strict arg value, index                 -- access the data item
do i = 1 to patterns~size                   -- loop through all the patterns
                                            -- this pattern in the data?
  if (value~string~pos(patterns[i]) <> 0) then do
    self~writeSecondary(value, index)       -- send it along the secondary...don't want this one
    return                                  -- stop the loop
  end
end
self~write(value, index)                    -- send all mismatches down the main branch


/******************************************************************************/
::class stemcollector subclass pipeStage public -- collect items in a stem

::method init
expose stem.                                -- expose target stem
use strict arg stem.                        -- get the stem variable target
stem.0 = 0                                  -- start with zero items
forward class (super)                       -- forward the initialization

::method process                            -- process a stem pipeStage item
expose stem.                                -- expose the stem
use strict arg value, index                 -- get the data item
stem.0 = stem.0 + 1                         -- stem the item count
stem.[stem.0, 'VALUE'] = value              -- save the value
stem.[stem.0, 'INDEX'] = index              -- save the index
forward class(super)

/******************************************************************************/
::class arraycollector subclass pipeStage public -- collect items in an array

::method init                               -- initialize a collector
expose valueArray indexArray idx            -- expose target array
use strict arg valueArray, indexArray=.nil  -- get the array variable target
idx = 0
forward class (super)                       -- forward the initialization

::method process                            -- process a stem pipeStage item
expose valueArray indexArray idx            -- expose the array
use strict arg value, index                 -- get the data item
idx = idx + 1
valueArray[idx] = value                     -- save the value
if indexArray <> .nil then indexArray[idx] = index -- save the index
self~process:super(value, index)            -- allow superclass to send down pipe

/******************************************************************************/
::class between subclass pipeStage public   -- write only records from first trigger record
                                            -- up to a matching record
::method init
expose startString endString started finished
use strict arg startString, endString
started = .false                            -- not processing any lines yet
finished = .false
forward class (super)                       -- forward the initialization

::method process
expose startString endString started finished
use strict arg value, index
if \started then do                         -- not turned on yet?  see if we've hit the trigger
    if value~string~pos(startString) > 0 then do
        started = .true
        self~write(value, index)            -- pass along
    end
    else do
        self~writeSecondary(value, index)   -- non-selected lines go to the secondary bucket
    end
    return
end
if \finished then do                        -- still processing?
    if value~string~pos(endString) > 0 then do -- check for the end position
        finished = .true
    end
    self~write(value, index)                -- pass along
end
else do
    self~writeSecondary(value, index)       -- non-selected lines go to the secondary bucket
end

/******************************************************************************/
::class after subclass pipeStage public     -- write only records from first trigger record

::method init
expose startString started
use strict arg startString
started = .false                            -- not processing any lines yet
forward class (super)                       -- forward the initialization

::method process
expose startString endString started
use strict arg value, index
if \started then do                         -- not turned on yet?  see if we've hit the trigger
    if value~string~pos(startString) = 0 then do
        self~writeSecondary(value, index)   -- pass along the secondary stream
        return
    end
    started = .true
end
self~write(value, index)                    -- pass along


/******************************************************************************/
::class before subclass pipeStage public    -- write only records before first trigger record

::method init
expose endString finished
use strict arg endString
finished = .false
forward class (super)                       -- forward the initialization

::method process
expose endString finished
use strict arg value, index
if \finished then do                        -- still processing?
    if value~string~pos(endString) > 0 then do -- check for the end position
        finished = .true
    end
    self~write(value, index)                -- pass along
end
else do
    self~writeSecondary(value, index)       -- non-selected lines go to the secondary bucket
end


/******************************************************************************/
::class buffer subclass pipeStage public    -- write only records before first trigger record

::method init
expose buffer count delimiter
use strict arg count = 1, delimiter = ("")
buffer = .array~new
forward class (super)                       -- forward the initialization

::method process
expose buffer
use strict arg value, index
buffer~append(.indexedValue~new(value, index)) -- just accumulate the value

::method eof
expose buffer count delimiter
loop i = 1 to count                         -- now write copies of the set to the stream
     if i > 1 then do
         self~write(delimiter, index)       -- put a delimiter between the sets
     end
     loop j = 1 to buffer~items             -- and send along the buffered lines
         indexedValue = buffer[i]
         self~write(indexedValue~value, indexedValue~index)
     end
end
forward class(super)                        -- and send the done message along


/******************************************************************************/
::class lineCount subclass pipeStage public -- count number of records passed through the pipeStage

::method init
expose counter
use strict arg -- none
counter = 0
forward class (super)                       -- forward the initialization

::method process
expose counter
use strict arg value, index
counter += 1                                -- just bump the counter on each record

::method eof
expose counter
self~write(counter, .nil);                  -- write out the counter message
forward class(super)                        -- and send the done message along


/******************************************************************************/
::class charCount subclass pipeStage public -- count number of characters passed through the pipeStage

::method init
expose counter
use strict arg -- none
counter = 0
forward class (super)                       -- forward the initialization

::method process
expose counter
use strict arg value, index
counter += value~string~length   -- just bump the counter for the length of each record

::method eof
expose counter
self~write(counter, .nil);                  -- write out the counter message
forward class(super)                        -- and send the done message along


/******************************************************************************/
::class wordCount subclass pipeStage public -- count number of characters passed through the pipeStage

::method init
expose counter
use strict arg -- none
counter = 0
forward class (super)                       -- forward the initialization

::method process
expose counter
use strict arg value, index
counter += value~string~words    -- just bump the counter for the number of words

::method eof
expose counter
self~write(counter, .nil);                  -- write out the counter message
forward class(super)                        -- and send the done message along



/******************************************************************************/
/**
 * A simple splitter sample that splits the stream based on a pivot value.
 * strings that compare < the pivot value are routed to pipeStage 1.  All other
 * strings are routed to pipeStage 2
 */

::class pivot subclass pipeStage public

::method init
expose pivotvalue
forward class (super) continue              -- forward the initialization
-- we did the initialization first, as we're about to override the pipeStages
-- store the pipeStage value and hook up the two output streams
use strict arg pivotvalue, self~next, self~secondary

::method process                            -- process the split
expose pivotvalue
use strict arg value, index
if value~string < pivotvalue then do -- simple split test
    self~write(value, index)
end
else do
    self~writeSecondary(value, index)
end


/******************************************************************************/
/**
 * a base class for pipeStages that split the processing stream into two or more
 * pipeStages.  The default behavior is to broadcast each line down all of the branches.
 * To customize, override process() and route the transformed lines down the
 * appropriate branch(es) using result with a target index specified.  If you wish
 * to use the default broadcast behavior, just call self~process:super(newValue) to
 * perform the broadcast.
 */

::class splitter subclass pipeStage public

::method init
expose stages
use strict arg ...
stages = arg(1, 'A')                        -- just save the arguments as an array
forward class (super)                       -- forward the initialization

::method append                             -- override for the single append version
expose stages
use strict arg follower
do stage over stages                        -- append the follower to each of the filter chains
    stage~append(follower)
end

::method insert                             -- this doesn't make sense for a fan out
raise syntax 93.963                         -- Can't do this, so raise an unsupported error

::method write                              -- broadcast a result to a particular filter
expose stages
use strict arg which, value, index          -- which is the fiter index, value is the result
stages[which]~process(value, index);        -- have the filter handle this

::method eof                                -- broadcast a done message down all of the branches
expose stages
do stage over stages
    stage~eof
end
-- needed ? forward class(super)                        -- make sure we propagate the done message

::method process                            -- process the stage stream
expose stages
use strict arg value, index
do stage over stages                        -- send this down all of the branches
    stage~process(value, index)
end

