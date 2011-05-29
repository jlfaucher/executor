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
expose next secondary
next = .nil
secondary = .nil                            -- all pipeStages have a secondary output potential

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


::method '[]' class                         -- create a pipeStage instance with arguments
forward to (self) message('NEW')            -- just forward this as a new message

::method go                                 -- execute using a provided object
expose source                               -- get the source supplier
use strict arg source                       -- set to the supplied object
self~begin                                  -- now go feed the pipeline

::method secondary attribute                -- a potential secondary attribute
::method next attribute                     -- next stage of the pipeStage
::method source attribute                   -- source of the initial data
                                            -- that they are class objects for
::method new                                -- the pipeStage chaining process
return self                                 -- just return ourself

::method begin                              -- start pumping the pipeline
expose source                               -- access the data and next chain

engine = source~supplier                    -- get a data supplier
do while engine~available                   -- while more data
  self~process(engine~item, engine~index)   -- pump this down the pipe
  engine~next                               -- get the next data item
end
self~eof                                    -- signal that processing is finished

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
self~init:super                             -- forward the initialization

::method process                            -- processing operations connect with pipeStage secondaries
expose pipeStage
forward to(pipeStage) message('processSecondary')

::method eof                                -- processing operations connect with pipeStage secondaries
expose pipeStage
forward to(pipeStage) message('secondaryEof')


/******************************************************************************/
::class indexedValue inherit Comparable
::attribute index
::attribute value

::method init
expose value index
use strict arg value, index
    
::method compareTo
expose index
use strict arg other
-- Strange result with compareTo : 10~compareTo(2) returns -1
--return index~string~compareTo(other~index~string)
if index~string < other~index~string then return -1
if index~string = other~index~string then return 0
return 1


/******************************************************************************/
::class sortByIndex public subclass pipeStage -- sort piped data
::method init                               -- sorter initialization method
expose items                                -- list of sorted items
items = .array~new                          -- create a new list
self~init:super                             -- forward the initialization

::method process                            -- process sorter piped data item
expose items                                -- access internal state data
use strict arg value, index                 -- access the passed value
items~append(.indexedValue~new(value, index)) -- append the value to the accumulator array

::method eof                                -- process the "end-of-pipe"
expose items                                -- expose the list
items~sort                                  -- sort the accumulated items

do i = 1 to items~items                     -- copy all sorted items to the primary stream
   indexedValue = items[i]
   self~write(indexedValue~value, indexedValue~index)
end

forward class(super)                        -- make sure we propagate the done message


/******************************************************************************/
::class sort public subclass sortByIndex


/******************************************************************************/
::class sortByValue public subclass pipeStage -- sort piped data
::method init                               -- sorter initialization method
expose items                                -- list of sorted items
items = .array~new                          -- create a new list
self~init:super                             -- forward the initialization

::method process                            -- process sorter piped data item
expose items                                -- access internal state data
use strict arg value, index                 -- access the passed value
items~append(.indexedValue~new(index, value)) -- append the value to the accumulator array

::method eof                                -- process the "end-of-pipe"
expose items                                -- expose the list
items~sort                                  -- sort the accumulated items

do i = 1 to items~items                     -- copy all sorted items to the primary stream
   indexedValue = items[i]
   self~write(indexedValue~index, indexedValue~value)
end

forward class(super)                        -- make sure we propagate the done message


/******************************************************************************/
::class sortWith public subclass pipeStage  -- sort piped data
::method init                               -- sorter initialization method
expose items comparator                     -- list of sorted items
use strict arg comparator                   -- get the compartor
items = .array~new                          -- create a new list
self~init:super                             -- forward the initialization

::method process                            -- process sorter piped data item
expose items                                -- access internal state data
use strict arg value, index                 -- access the passed value
items~append(.indexedValue~new(value, index)) -- append the value to the accumulator array

::method eof                                -- process the "end-of-pipe"
expose items comparator                     -- expose the list
items~sortWith(comparator)                  -- sort the accumulated items

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
self~init:super                             -- forward the initialization

::method process                            -- pipeStage processing item
expose old new count
use strict arg value, index                 -- get the data item
self~write(value~string~changestr(old, new, count), index) -- send it along in altered form


/******************************************************************************/
::class delstr public subclass pipeStage    -- a string deletion pipeStage
::method init
expose offset length
use strict arg offset, length               -- both are required.
self~init:super                             -- forward the initialization

::method process                            -- pipeStage processing item
expose offset length
use strict arg value, index                 -- get the data item
self~write(value~string~delstr(offset, length), index) -- send it along in altered form


/******************************************************************************/
::class left public subclass pipeStage      -- a splitter pipeStage
::method init
expose length
use strict arg length                       -- the length is the left part
self~init:super                             -- forward the initialization

::method process                            -- pipeStage processing item
expose offset length
use strict arg value, index                 -- get the data item
self~write(value~string~left(length), index) -- send the left portion along the primary stream
self~writeSecondary(value~string~substr(length + 1), index) -- the secondary gets the remainder portion


/******************************************************************************/
::class right public subclass pipeStage     -- a splitter pipeStage
::method init
expose length
use strict arg length                       -- the length is the left part
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization

::method process                            -- pipeStage processing item
expose insert offset
use strict arg value, index                 -- get the data item
self~write(value~string~insert(insert, offset), index) -- send the left portion along the primary stream


/******************************************************************************/
::class overlay public subclass pipeStage   -- overlay a string into each line
::method init
expose overlay offset
use strict arg overlay, offset              -- we need an offset and an insertion string
self~init:super                             -- forward the initialization

::method process                            -- pipeStage processing item
expose insert offset
use strict arg value, index                 -- get the data item
self~write(value~string~overlay(overlay, offset), index) -- send the left portion along the primary stream


/******************************************************************************/
::class dropnull public subclass pipeStage  -- drop null records
::method process                            -- pipeStage processing item
use strict arg value, index                 -- get the data item
if value~string \== '' then do   -- forward along non-null records
    self~write(value, index)
end


/******************************************************************************/
::class dropFirst public subclass pipeStage -- drop the first n records
::method init
expose count counter
use strict arg count
counter = 0
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization

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


/******************************************************************************/
::class takeFirst public subclass pipeStage -- take the first n records
::method init
expose count counter
use strict arg count
counter = 0
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization

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
mainDone = .false
secondaryEof = .false
self~init:super                             -- forward the initialization

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
mainDone = .false
secondaryEof = .false
array = .array~new                          -- accumulator for secondary
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization

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
say index ":" value                         -- display this item
forward class(super)


/******************************************************************************/
::class all public subclass pipeStage       -- a string selector pipeStage
::method init                               -- process initial strings
expose patterns                             -- access the exposed item
patterns = arg(1,'a')                       -- get the patterns list
self~init:super                             -- forward the initialization

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
::method init                               -- process initial strings
expose patterns                             -- access the exposed item
patterns = arg(1,'a')                       -- get the patterns list
self~init:super                             -- forward the initialization

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
::method init                               -- process initial strings
expose match                                -- access the exposed item
use strict arg match                        -- get the patterns list
self~init:super                             -- forward the initialization

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
::method init                               -- process initial strings
expose patterns                             -- access the exposed item
patterns = arg(1,'a')                       -- get the patterns list
self~init:super                             -- forward the initialization

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
::method init                               -- initialize a collector
expose stem.                                -- expose target stem
use strict arg stem.                        -- get the stem variable target
stem.0 = 0                                  -- start with zero items
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization

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
counter = 0
self~init:super                             -- forward the initialization

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
counter = 0
self~init:super                             -- forward the initialization

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
counter = 0
self~init:super                             -- forward the initialization

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
self~init:super                             -- forward the initialization
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
stages = arg(1, 'A')                        -- just save the arguments as an array
self~init:super                             -- forward the initialization

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

::method process                            -- process the stage stream
expose stages
use strict arg value, index
do stage over stages                        -- send this down all of the branches
    stage~process(value, index)
end

