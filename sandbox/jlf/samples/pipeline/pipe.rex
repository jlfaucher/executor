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


::requires "profiling/profiling.cls"


::class "pipeStage" mixinclass Object public                  -- base pipeStage class

::method _description_ class
nop
/*
Base pipeStage class.

By default, a pipeStage has two inputs I1 & I2, and two ouputs O1 & O2.
process : I1
processSecondary : I2
write : O1 (linked by default to follower's I1)
writeSecondary : 02 (linked by default to follower's I1)

Connectors
'|'  connect leftPipeStage's O1 with rightPipeStage's I1 (primary follower) : 01 --> I1
'>'  same as '|', but careful, the '>' operator has a higher precedence than '|'
'>>' connect leftPipeStage's O2 with rightPipeStage's I1 (secondary follower) : O2 --> I1

Reminder of the precedence (highest at the top) :
(message send)         : ~ ~~ (not overloaded for pipes)
(prefix operators)     : + - \ (not overloaded for pipes)
(power)                : ** (not overloaded for pipes)
(multiply and divide)  : * / % // (not overloaded for pipes)
(add and subtract)     : + - (not overloaded for pipes)
(blank) || (abuttal)   : (blank) is overloaded for adding options.
(comparison operators) : > >> are overloaded for pipes, the rest is not used : = < == << \= >< <> \> \< \== \>> \<< >= >>= <= <<=
(and operator)         : & (not overloaded for pipes).
(or, exclusive or)     : | is overloaded, && is not used.

The chain of connected pipeStages is a pipe.
Any object can be a source of pipe :
- When the object does not support the method ~supplier then it's injected as-is.
  The index is 1.
- A collection can be a source of pipe : each item of the collection is injected in the pipe.
  The indexes are those of the collection.
- A coactivty can be a source of pipe : each yielded item is injected in the pipe (lazily).
  The indexes are those returned by the coactivity supplier.

Most sub classes need only override the process() method to implement a pipeStage.
The transformed results are passed down the pipeStage chain by calling the write method.

Careful to >>
    "hello"~pipe(.left[2] >> .upper | .console)
Here, the result is not what you expect. You want "LLO", you get "he"...
This is because .console is the primary follower of .left, not the primary
follower of .upper.
Why ? because the pipestage returned by .left[2] >> .upper is .left,
and .console is attached to the pipestage found by starting from .left
and walking through the 'next' references until a pipestage with no 'next'
is found. So .upper is not walked though, because it's a secondary follower.

You need additional parentheses to get the expected behavior.
Here, .console is the primary follower of .upper.
    "hello"~pipe(.left[2] >> ( .upper | .console ) )

Note : by default, the connection is always made with follower's I1.
See .secondaryConnector to learn how to connect to follower's I2.
*/
nop

-- .myStep[arg1, arg2]
::method '[]' class                         -- create a pipeStage instance with arguments
forward to (self) message('NEW')            -- just forward this as a new message


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


-- .myStep arg1 arg2
::method " " class                          -- another way to pass arguments (one by one)
use strict arg arg
me = self~new                               -- no arg for init
me~options~append(arg)
return me

---------- instance attributes / methods ----------

::attribute I1Counter                       -- number of stages whose primary/secondary output is linked to self primary input (I1)
::attribute I2Counter                       -- number of stages whose primary/secondary output is linked to self secondary input (I2)
::attribute isEOP                           -- becomes .true if the pipeStage has finished processing the datas (see .take)
::attribute memorize                        -- if .true then a new dataflow is created, which is linked to the previous one.
::attribute next                            -- next stage of the pipeStage
::attribute options                         -- the options are passed one by one, accumulated here
::attribute secondary                       -- a potential secondary attribute
::attribute tag                             -- dataflow's tag

::method new                                -- the pipeStage chaining process
return self                                 -- just return ourself


::method init
expose I1Counter I2Counter isEOP memorize next options secondary tag var varName
I1Counter = 0
I2Counter = 0
isEOP = .false                              -- indicator of End Of Process
memorize = .false
next = .nil
options = .array~new                        -- options are passed like that : .myStage opt1 opt2 ...
secondary = .nil                            -- all pipeStages have a secondary output potential
tag = ""


::method '|'
use strict arg follower
follower = follower~new                     -- make sure this is an instance
return self~append(follower)                -- do the chain append logic


::method '>'
use strict arg follower
follower = follower~new                     -- make sure this is an instance
return self~append(follower)                -- do the chain append logic


::method '>>'
use strict arg follower
follower = follower~new                     -- make sure this is an instance
return self~appendSecondary(follower)       -- do the chain append logic


::method " "                                -- the options are passed one by one
expose options
use strict arg arg
options~append(arg)
return self                                 -- by returning self, let chain the blank operators


::method append                             -- append a pipeStage to the entire chain
expose next
use strict arg follower
if .nil == next then do                     -- if we're the end already, just update the next
    follower~I1LinkFromO1(self)             -- link self primary output (O1) to follower primary input (I1)
end
else do
    next~append(follower)                   -- have our successor append it.
end
return self                                 -- we're our own return value


::method appendSecondary                    -- append a pipeStage to the secondary output of entire chain
expose next
use strict arg follower
-- yes, must be like that ! The goal is to support that :
-- a > b > c >> d
-- The pipeline above is in fact this expression :
-- ((a > b) > c) >> d
-- where
-- a > b returns a where a~next=b
-- a > c returns a where a~next~next=c
-- So if you want to hook d on the secondary output of c, then you have to follow 'next'.
if .nil == next then do                     -- if we're the end already, just update the next
    follower~I1LinkFromO2(self)             -- link self secondary output (O2) to follower primary input (I1)
end
else do
    next~appendSecondary(follower)          -- have our successor append it.
end
return self                                 -- we're our own return value


::method insert                             -- insert a pipeStage after this one, but before the next
expose next
user strict arg newpipeStage
newpipeStage~append(next)                   -- if newpipeStage has followers, then the last follower will be linked to next
next~I1UnlinkFromO1(self)                   -- unlink self primary output (O1) to next primary input (I1)
newpipeStage~I1LinkFromO1(self)             -- link self primary output (O1) to newpipeStage primary input (I1)
return self                                 -- we're our own return value


::method I1LinkFromO1                       -- link previousPipeStage primary output (O1) to self primary input (I1)
use strict arg previousPipeStage
previousPipeStage~next = self
self~I1Counter += 1


::method I1UnlinkFromO1                     -- unlink previousPipeStage primary output (O1) to self primary input (I1)
use strict arg previousPipeStage
previousPipeStage~next = .nil
self~I1Counter -= 1


::method I2LinkFromO1                       -- link previousPipeStage primary output (O1) to self secondary input (I2)
use strict arg previousPipeStage
previousPipeStage~next = self
self~I2Counter += 1


::method I2UnlinkFromO1                     -- unlink previousPipeStage primary output (O1) to self secondary input (I2)
use strict arg previousPipeStage
previousPipeStage~next = .nil
self~I2Counter -= 1


::method I1LinkFromO2                       -- link previousPipeStage secondary output (O2) to self primary input (I1)
use strict arg previousPipeStage
previousPipeStage~secondary = self
self~I1Counter += 1


::method I1UnlinkFromO2                     -- unlink previousPipeStage secondary output (O2) to self primary input (I1)
use strict arg previousPipeStage
previousPipeStage~secondary = .nil
self~I1Counter -= 1


::method I2LinkFromO2                       -- link previousPipeStage secondary output (O2) to self secondary input (I2)
use strict arg previousPipeStage
previousPipeStage~secondary = self
self~I2Counter += 1


::method I2UnlinkFromO2                     -- link previousPipeStage secondary output (O2) to self secondary input (I2)
use strict arg previousPipeStage
previousPipeStage~secondary = .nil
self~I2Counter -= 1


::method go                                 -- execute using a provided object
use strict arg source, profile=.false
if profile then do
    profiler = .pipeProfiler~new
    profiler~push(self, "go")               -- the root message of the call stack
    .context~package~setSecurityManager(profiler)
end
anyErrorTrapped = .false
signal on any name anyError                 -- In case of error, must ensure that the pipe is reset and the security manager is detached
self~begin(source)                          -- now go feed the pipeline
self~eof                                    -- signal that processing is finished
finalize:
    self~reset
    if profile then do
        profiler~reportResults(profiler~pull)
        .context~package~setSecurityManager
    end
    if anyErrorTrapped then raise propagate
    return
anyError:
    anyErrorTrapped = .true
    signal finalize


::method begin                              -- start pumping the pipeline
use strict arg source
self~start                                  -- signal that processing is starting
if \source~hasMethod("supplier") then do
  -- Remember : similar test in .append, .inject
  -- Initial dataflow, each following pipeStage will create an enclosing dataflow, when requested.
  dataflow = .dataflow~create(.nil, "source", source, 1)
  self~process(source, 1, dataflow)         -- pump this down the pipe
end
else do
    supplier = source~supplier              -- get a data supplier
    do while \self~isEOP, supplier~available-- while more data
      -- Initial dataflow, each following pipeStage will create an enclosing dataflow, when requested.
      dataflow = .dataflow~create(.nil, "source", supplier~item, supplier~index)
      self~process(supplier~item, supplier~index, dataflow) -- pump this down the pipe
      -- Matter of choice : should I stay on current item or get the next item before leaving ?
      -- Current choice works good for coactivities : no lost item when piping directly the coactivity
      -- to several pipes. But if you pass the same supplier to several pipes then you have to call
      -- ~next if you don't want to get the last processed item again.
      -- Remember :
      -- If you change that, change also .append.
      if self~isEOP then leave
      supplier~next                         -- get the next data item
    end
end


::method start                              -- process "start-of-pipe" condition
expose next options secondary
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
error = .false
do a over arg(1, "a")
    if a~isA(.String) then do
        if a~strip == "" then iterate
        parse var a first "." rest
        if "memorize"~caselessAbbrev(first, 3) then do
            -- memorize[.tag]
            self~memorize = .true
            do while rest <> ""
                parse var rest first "." rest
                if first <> "" then do
                    if self~tag <> "" then raise syntax 93.900 array(self~class~id ": Only one tag is supported")
                    self~tag = first
                end
            end
            iterate
        end
    end
    error = .true
    .error~lineout("Unknown option '"a"'")
end
if error then raise syntax 93.900 array(self~class~id ": Unknown option")


::method checkEOP
-- Accept zero to n arguments, each argument being a pipeStage or .nil
-- If all the args are .nil then don't change isEOP (this is a terminal pipeStage).
-- If all the nonNil arguments (i.e. pipeStages) are EOP then the current pipeStage becomes EOP.
allNIL = .true
do pipeStage over arg(1, "a")
    if .nil <> pipeStage then do
        allNIL = .false
        if \pipeStage~isEOP then return -- can stop immediately, self is not EOP
    end
end
if allNIL then return
self~isEOP = .true


::method process                            -- default data processing
use strict arg item, index, dataflow        -- get the data item
self~write(item, index, dataflow)           -- send this down the line
self~checkEOP(self~next)


::method newDataflow
-- Can be redefined by subclasses (ex : .inject)
use strict arg previousDataflow, item, index
return .dataflow~create(previousDataflow, self, item, index)


::method write                              -- handle the result from a process method
expose next
use strict arg item, index, dataflow
if .nil <> next, \next~isEOP then do
    newDataflow = dataflow
    if self~memorize then newDataflow = self~newDataflow(dataflow, item, index)
    next~process(item, index, newDataflow)  -- only forward if we have an active successor
    return newDataflow
end
return .nil


::method writeSecondary                     -- handle a secondary output result from a process method
expose secondary
use strict arg item, index, dataflow
if .nil <> secondary, \secondary~isEOP then do
    newDataflow = dataflow
    if self~memorize then newDataflow = self~newDataflow(dataflow, item, index)
    secondary~process(item, index, newDataflow)-- only forward if we have an active successor
    return newDataflow
end
return .nil


::method processSecondary                   -- handle a secondary input result from a process method
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
expose next secondary
if .nil <> next then do
    next~secondaryEof                       -- only forward if we have a successor
end
if .nil <> secondary then do
    secondary~secondaryEof                  -- only forward if we have a successor
end


::method reset
expose next secondary
if .nil <> next then do
    next~reset
end
if .nil <> secondary then do
    secondary~reset
end


/******************************************************************************/
::class "secondaryConnector" public subclass pipeStage

::method _description_ class
nop
/*
.SecondaryConnector : I1 --> I2
A secondaryConnector SC is an adapter which is inserted between two pipeStages :
    PS1 -->(I1) .secondaryConnector -->(I2) PS2
- The triplet (item, index, dataflow) received through I1 by ~process is forwarded to the
  secondary input of the next pipeStage (calls PS2~processSecondary).
- The eof signal is forwarded to the secondary eof of the next pipeStage (calls
  PS2~secondaryEof.
Example (the secondary connector brings nothing here, because the default implementation
of ~processSecondary is to forward to ~process):
    "X"~pipe(.inject {item "one"} | .secondaryConnector | .inject {item "two"} | .console)
    -- display : 1 : 'X one two'
See .fanin and .merge for more examples.
*/
nop


::method append                             -- append a secondaryConnector pipeStage to the entire chain
use strict arg follower
if .nil == self~next then do                -- if we're the end already, just update the next
    follower~I2LinkFromO1(self)             -- link self primary output (O1) to follower secondary input (I2)
end
else do
    self~next~append(follower)              -- have our successor append it.
end
return self                                 -- we're our own return value


::method appendSecondary                    -- append a secondaryConnector pipeStage to the secondary output of entire chain
use strict arg follower
if .nil == self~next then do                -- if we're the end already, just update the next
    follower~I2LinkFromO2(self)             -- link self secondary output (O2) to follower primary input (I1)
end
else do
    self~next~appendSecondary(follower)     -- have our successor append it.
end
return self                                 -- we're our own return value


::method insert                             -- insert a pipeStage after this one, but before the next
user strict arg newpipeStage
newpipeStage~append(self~next)              -- if newpipeStage has followers, then the last follower will be linked to next
self~next~I2UnlinkFromO1(self)              -- unlink self primary output (O1) to next secondary input (I2)
newpipeStage~I2LinkFromO1(self)             -- link self primary output (O1) to newpipeStage secondary input (I2)
return self                                 -- we're our own return value


::method process                            -- processing operations connect with nextPipeStage secondaries
forward to(self~next) message('processSecondary')


::method eof                                -- processing operations connect with nextPipeStage secondaries
forward to(self~next) message('secondaryEof')


/******************************************************************************/
::class "pipeProfiler" public subclass Profiler

::method _description_ class
nop
/*
A subclass of Profiler, specialized for pipes.
The instrument method is applied to all the subclasses of PipeStage.
Example :
    .pipeProfiler~instrument("start", "process", "eof", "isEOP")
    .array~of(b, a, c)~pipeProfile(.sort byItem | .console)
See also : .Profiler
*/
nop


::method instrumentClass class
use strict arg class, messages
self~instrumentMethods(class, messages)
do class over class~subclasses
    self~instrumentClass(class, messages) -- recursively instrument this class and its subclasses
end


::method instrument class
use strict arg message, ...
messages = arg(1, "a")
self~instrumentClass(.pipeStage, messages)


/******************************************************************************/
::routine compareObjects
use strict arg o1, o2, caseless, strict
/*
-- special support for arrays : compare item by item
if o1~isA(.array) & o2~isA(.array) then do
    s1 = o1~supplier
    s2 = o2~supplier
    do while s1~available & s2~available
        item1 = s1~item
        item2 = s2~item
        compare = compareObjects(item1, item2, caseless, strict)
        if compare <> 0 then return compare
        s1~next
        s2~next
    end
    if s1~available then return 1 -- longer > shorter
    if s2~available then return -1 -- shorter < longer
    return 0
end
if o1~isA(.array) then return 1 -- array > notArray
if o2~isA(.array) then return -1 -- notArray < array
*/
return compareStrings(o1~string, o2~string, caseless, strict)


::routine compareStrings
use strict arg s1, s2, caseless, strict
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


/******************************************************************************/
::class "dataflowPool"

::attribute nextValueIndex
::attribute nextArrayIndex
::attribute nextEnclosedArrayIndex
::attribute values

::method init
self~nextValueIndex = 1
self~nextArrayIndex = 1
self~nextEnclosedArrayIndex = 1
self~values = .table~new


::class "dataflowValuePoolValue"

::attribute index
::attribute count
::attribute printed

::method init
self~index = 0
self~count = 0
self~printed = .false


/******************************************************************************/
::class "dataflow" public subclass Array inherit Comparable

/*
Remember 1 : no reference to the next dataflow ! A dataflow can have several followers.
Remember 2 : the internal structure is an array because it's easy to store additional informations
             and manage them in a generic way (iterate from index 3 up to ~items).
*/

::method _description_ class
nop
/*
A dataflow is an array :
  array[1] : link to previous dataflow (received from previous pipeStage).
  array[2] : tag (generally the id of the pipeStage class, or "source" for the initial dataflow).
  array[3] : index of produced item.
  array[4] : produced item.

  1          2     3       4
+----------+-----+-------+------+
| previous | tag | index | item |
+----------+-----+-------+------+
   ^
   |  +----------+-----+-------+------+
   +--| previous | tag | index | item |
      +----------+-----+-------+------+
         ^
         |
         +-- etc...

A pipeStage receives a triplet (item, index, dataflow). It applies transformations or filters
on this triplet. When a pipeStage forwards an item to a following pipeStage, it forwards the
received dataflow unchanged, unless the option "memorize" has been used. In this case, a new
dataFlow is created, with the structure described above.

dataflow[tag, nth=1]
    Returns dataflow~get(tag, nth).
dataflow~get(tag, nth=1)
    Retrieves a dataflow by tag, from most recent to oldest. If several dataflows
    have the same tag, then the argument 'nth' lets specify which one to return.
    tag can be a negative number. In this case, a relative dataflow is returned.
dataflow~index
    Returns the index of the produced item.
dataflow~length
    Returns the number of linked dataflows, including the current one ( >= 1 ).
dataflow~makeString(mask="1 2 3 4", showPool=.false)
    Returns a string representation of the dataflow.
    - mask lets indicate which fields to include.
      if previous is included, then the same mask is used everywhere.
    - the parameter showPool lets reduce the length of the string, by inserting
      references to previous items, instead of repeating the items.
      Ex :
      with showPool == .false : "my string",(a Method)|"my string",(a Method)
      with showPool == .true  : v1="my string",v2=(a Method)|*v1,*v2
dataflow~previous
    Returns the previous dataflow.
dataflow~tag
    Returns the dataflow's tag.
dataflow~item
    Returns the produced item.
*/
nop

::constant arrayPrintMaxSize 100 -- single-dimension arrays whose number of items is <= to this number will be printed item by item

::constant firstIndexPoolManaged 3 -- The items from this index up to the end of the dataflow's array are impacted by showPool.

::method create class
use strict arg previous, tag, item, index -- follow the order convention used everywhere : item first, then index
dataflow = self~new(4)
if tag~isA(.pipeStage) then do
    pipeStage = tag
    if pipeStage~tag <> "" then tag = pipeStage~tag
    else tag = pipeStage~class~id
end
else if \tag~isA(.String) then raise syntax 93.900 array(self~id"~create: 'tag' must be a pipeStage or a string")
dataflow~tag = tag
if .nil <> previous, \ previous~isA(.dataflow) then raise syntax 93.900 array(self~id"~create: 'previous' must be either a dataflow or .nil")
dataflow~previous = previous
dataflow~index = index
dataflow~item = item
return dataflow


::method "previous="
use strict arg previous
self[1] = previous


::method previous
return self[1]


::method "tag="
use strict arg tag
self[2] = tag


::method tag
return self[2]


::method "index="
use strict arg index
self[3] = index


::method index
return self[3]


::method "item="
use strict arg item
self[4] = item


::method item
return self[4]


::method length
if .nil <> self~previous then return 1 + self~previous~length
return 1


::method "[]"
use strict arg index, ...
if index~isA(.String), index~dataType("W"), index > 0 then forward class (super)
forward message "get"


::method get
-- Retrieve a dataflow by tag. Start from self, and go to previous dataflows.
use strict arg tag, nth=1
if tag~isA(.String), tag~dataType("W"), tag < 0 then do
    -- tag is a negative whole number : search for relative dataflows. Here nth is not used.
    use strict arg count
    do until .nil == current
        current = self~previous
        count += 1
        if count == 0 then return current
    end
end
else do
    -- tag is used as a key. Here nth is used to decide which dataflow to return if the same key is used several times.
    count = 1
    current = self
    do while .nil <> current
        if current~tag~caselessEquals(tag) then do
            if count == nth then return current
            count += 1
        end
        current = current~previous
    end
end
return .nil -- not found


::method compareTo
use strict arg other, caseless=.false, strict=.false
-- compare the tags
compare = compareStrings(self~tag, other~tag, caseless, strict)
if compare <> 0 then return compare
-- compare the index
compare = compareObjects(self~index, other~index, caseless, strict)
if compare <> 0 then return compare
-- compare the item
compare = compareObjects(self~item, other~item, caseless, strict)
if compare <> 0 then return compare
-- compare the previous dataflows
previousDataflow1 = self~previous
previousDataflow2 = other~previous
if .nil == previousDataflow1 & .nil == previousDataflow2 then return 0
else if .nil == previousDataflow1 then return -1 -- nil < nonNil
else if .nil == previousDataflow2 then return 1 -- nonNil > nil
return previousDataflow1~compareTo(previousDataflow2)


::method makeString
/*
mask lets indicate which fields to include.
If previous is included, then the same mask is used everywhere.

A dataflow can generate a long string.
The parameter showPool lets reduce the length of the string, by inserting
references to previous items, instead of repeating the items.
Ex :
with showPool == .false : "my string",(a Method)|"my string",(a Method)
with showPool == .true  : v1="my string",v2=(a Method)|*v1,*v2
*/
use strict arg mask="1 2 3 4", showPool=.false, pool=(.dataflowPool~new)
/*****************************************
* Pass 1: count the occurences of values *
*****************************************/
-- Collect the index, item and additional values (if any) of the current dataflow.
-- Here we just count the number of occurences of each value.
-- The first occurence of a value having more than 1 occurence will be tagged
-- vN= or aN= or eN= (value, array, enclosed array).
-- But to know that, you need first to know if the value has more than 1 occurence...
do index = self~firstIndexPoolManaged to self~dimension(1)
    if mask~pos(index) == 0 then iterate
    call dataflow_value self[index], showPool, pool
end
/********************************
* Pass 2: string representation *
********************************/
previous = self~previous
string = ""
if mask~pos(1) <> 0, previous~isA(.Dataflow) then string = previous~makeString(mask, showPool, pool)" | "
if mask~pos(2) <> 0 then string ||= self~tag":"
-- Now we print the index, item and additional values (if any) of the current dataflow
separator = ""
do index = self~firstIndexPoolManaged to self~dimension(1)
    if mask~pos(index) == 0 then iterate
    string ||= separator || dataflow_representation(self[index], showPool, pool)
    separator = ","
end
return string


::routine dataflow_value
/*
pool~values is a collection which remembers the values inserted in the dataflow representation.
The goal is to know if a given value appears more than once in the representation (count > 1) : shared value.
If reused and showPool==.true, then a compacted representation will be used (see dataflow_representation).
*/
use strict arg val, showPool, pool
-- The arrays and enclosed arrays are always managed with a pool, even if not showPool, to support self-referencing.
if \showPool, val~class~id <> "EnclosedArray", \val~isA(.array) then return
isnum = .false
if val~isA(.String) then do
    isnum = val~dataType("N")
end
if isnum then return -- numbers are not managed by pool
poolValue = pool~values[val]
if .nil == poolValue then do
    poolValue = .dataflowValuePoolValue~new
    pool~values[val] = poolValue
end
poolValue~count += 1
if poolValue~count > 1 then return -- first occurence already analyzed
if val~class~id == "EnclosedArray" then do
    call dataflow_value val~disclose, showPool, pool
end
else if val~isA(.array), val~dimension == 1, val~items <= .dataflow~arrayPrintMaxSize then do
    -- each item of the array will be inserted in the representation.
    do v over val
        call dataflow_value v, showPool, pool
    end
end


::routine dataflow_representation
/*
pool~values is a collection which remembers the values inserted in the dataflow representation.
The goal is to know if a given value appears more than once in the representation (count > 1) : shared value.
- The first occurence of a shared value is represented by vN or aN or eN = <shared value representation>
- The next occurences of this shared value is just *vN or *aN *eN (value, array, enclosed array).
*/
use strict arg val, showPool, pool
-- The arrays and enclosed arrays are always managed with a pool, even if not showPool, to support self-referencing.
if showPool | val~class~id == "EnclosedArray" | val~isA(.array) then do
    poolValue = pool~values[val]
    if .nil == poolValue then do
        -- should not happen, but...
        poolValue = .dataflowValuePoolValue~new
        pool~values[val] = poolValue
        poolValue~count = 1
    end
end
-- if val~isA(.enclosedArray) then do -- Can't use this test because .enclosedArray is not a class here. I don't want to require "extension/array.cls"
if val~class~id == "EnclosedArray" then do
    if showPool, poolValue~printed then return "*e"poolValue~index
    -- Here, first printing
    poolValue~printed = .true -- set it now, will be tested to avoid infinite recursion with self-referencing enclosed arrays
    poolValue~index = pool~nextEnclosedArrayIndex
    pool~nextEnclosedArrayIndex += 1
    valstr = "<"dataflow_representation(val~disclose, showPool, pool)">"
    if \showPool then return valstr
    if poolValue~count == 1 then return valstr -- no need of eN= in front
    return "e" || poolValue~index || "=" || valstr
end
else if val~isA(.array), val~dimension == 1, val~items <= .dataflow~arrayPrintMaxSize then do
    /*
    Remember : this part of code is a duplication of .array~ppRepresentation.
    Must find a way to avoid this duplication...
    One difference is the call to dataflow_representation instead of ppRepresentation,
    but the problem is that additional parameters are passed : showPool, pool.
    Other difference : no maxItems. Most of the time, the arrays passing through the pipe are not printed as a whole, they are iterated over.
    Other difference : no management of sparse array. Most of the time, an array is iterated over using a supplier, which skips the holes.
    */
    if showPool, poolValue~printed then return "*a"poolValue~index
    -- Here, first printing
    -- each item of the array is inserted.
    poolValue~printed = .true -- set it now, will be tested to avoid infinite recursion with self-referencing arrays
    poolValue~index = pool~nextArrayIndex
    pool~nextArrayIndex += 1
    valstr = "["
    separator = ""
    do v over val
        valstr ||= separator || dataflow_representation(v, showPool, pool)
        separator = ","
    end
    valstr ||= "]"
    if \showPool then return valstr
    if poolValue~count == 1 then return valstr -- no need of aN= in front
    return "a" || poolValue~index || "=" || valstr
end
else do
    valstr = val~string
    if val~isA(.String) then do
        isnum = val~dataType("N")
        if \isnum then valstr = "'"valstr"'" -- strings are surrounded by quotes, except string numbers
    end
    else do
        isnum = .false
        -- To make a distinction between a real string and other objects, surround by (...)
        -- For the arrays, indicate their shape
        if val~isA(.array) then valstr = "("valstr val~shapeToString")"
        else valstr = "("valstr")"
    end
    if isnum | \showPool then return valstr
    else do
        if poolValue~printed then return "*v"poolValue~index
        if poolValue~count == 1 then return valstr -- no need of vN= in front
        poolValue~index = pool~nextValueIndex
        pool~nextValueIndex += 1
        poolValue~printed = .true
        return "v" || poolValue~index || "=" || valstr
    end
end


/******************************************************************************/
::class "indexedItem" public inherit Comparable -- declared public to let profile
::attribute index -- any type
::attribute item -- any type
::attribute dataflow -- always a .dataflow

::method init
expose dataflow index item
use strict arg item, index, dataflow


::method compareTo
use strict arg other, start=1, length=(-1), caseless=.false
-- This method is called by ooRexx 'sort' framework, when appropriate.
-- So it's a bad idea to compare the indexes,  only the items must be compared.
-- This method is not used by the pipeline services, which offers specialized comparators.
-- To let use the standard ColumnComparator, I added the optional parameters start and length.
/*
comparator = .indexedItemComparator~new(caseless,,"index")
comparison = comparator~compare(self, other)
if comparison <> 0 then return comparison
*/
comparator = .indexedItemComparator~new(caseless)
comparison = comparator~compareTo(self, other, start, length)
return comparison


::method caselessCompareTo
use strict arg other, start=1, length=(-1)
return self~compareTo(other, start, length, .true)


-- Remember : compareTo and caselessCompareTo above are still necessary because the
-- 'other' argument is of type indexedItem. The unknown method below unboxes the
-- item of self, but not the item of other.
::method unknown
use strict arg msg, args
forward to (self~item) message (msg) arguments (args)


/******************************************************************************/
::class "indexedItemComparator" public inherit Comparator

::method init
expose caseless criterion strict
use strict arg caseless=.false, strict=.false, criterion="item"


::method compareIndexes
expose caseless strict
use strict arg first, second
index1 = first~index
index2 = second~index
return compareObjects(index1, index2, caseless, strict)


::method compareItems
expose caseless strict
use strict arg first, second
item1 = first~item
item2 = second~item
return compareObjects(item1, item2, caseless, strict)


::method compareExpressions
expose caseless criterion strict
use strict arg first, second
result1 = criterion~do(      first~item,        first~index,           first~dataflow,-
                       item: first~item, index: first~index, dataflow: first~dataflow)
result2 = criterion~do(      second~item,        second~index,           second~dataflow,-
                       item: second~item, index: second~index, dataflow: second~dataflow)
return compareObjects(result1, result2, caseless, strict)


::method compare
expose criterion
use strict arg first, second
if criterion~string == "index" then return self~compareIndexes(first, second)
if criterion~string == "item" then return self~compareItems(first, second)
return self~compareExpressions(first, second)


-- For convenience, add support for .ColumnComparator.
-- The comparison is by item.
::method compareTo
expose caseless strict
use strict arg first, second, start=1, length=(-1)
item1 = first~item
item2 = second~item
if length == -1 then do
    s1 = item1~string~substr(start)
    s2 = item2~string~substr(start)
end
else do
    s1 = item1~string~substr(start, length)
    s2 = item2~string~substr(start, length)
end
return compareStrings(s1, s2, caseless, strict)


/******************************************************************************/
::class "sort" public subclass pipeStage    -- sort piped data

::method _description_ class
nop
/*
A sort pipeStage.
primary (accumulator)
.sort ['ascending'|'descending'] ['case'|'caseless'] ['numeric'|'strict'] ['quickSort'|'stableSort'] ['byIndex'|'byItem'|<criteria-doer>])*
Options :
*/
nop

::attribute descending
::attribute caseless
::attribute quickSort
::attribute strict

::method init
expose items
use strict arg -- none
items = .array~new                          -- create a new list
forward class (super)


::method initOptions
expose caseless criteria descending quickSort strict
descending = .false
caseless = .false
quickSort = .false -- use a stable sort by default
strict = .false
unknown = .array~new
criteria = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "ascending"~caselessAbbrev(a, 1) then do ; criteria~append(.array~of("descending=", .false)) ; iterate ; end
        if "byIndex"~caselessAbbrev(a, 3) then do ; criteria~append(.array~of("sortBy", "index")) ; iterate ; end
        if "byItem"~caselessAbbrev(a, 3) then do ; criteria~append(.array~of("sortBy", "item")) ; iterate ; end
        if "caseless"~caselessAbbrev(a, 1) then do ; criteria~append(.array~of("caseless=", .true)) ; iterate ; end
        if "\caseless"~caselessAbbrev(a, 2) then do ; criteria~append(.array~of("caseless=", .false)) ; iterate ; end -- needed to let reset when several sort keys
        if "descending"~caselessAbbrev(a, 1) then do ; criteria~append(.array~of("descending=", .true)) ; iterate ; end
        if "numeric"~caselessAbbrev(a, 1) then do ; criteria~append(.array~of("strict=", .false)) ; iterate ; end
        if "quickSort"~caselessAbbrev(a, 1) then do ; criteria~append(.array~of("quickSort=", .true)) ; iterate ; end
        if "stableSort"~caselessAbbrev(a, 3) then do ; criteria~append(.array~of("quickSort=", .false)) ; iterate ; end
        if "strict"~caselessAbbrev(a, 3) then do ; criteria~append(.array~of("strict=", .true)) ; iterate ; end
    end
    else do
        if a~hasMethod("doer") then do
            function = a~doer
            criteria~append(.array~of("sortBy", function))
            iterate
        end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)    -- forward the initialization to super to process the unknown options


::method sortBy
expose caseless descending items quickSort strict
use strict arg criterion
comparator = .indexedItemComparator~new(caseless, strict, criterion)
if descending then comparator = .InvertingComparator~new(comparator)
if quickSort then items~sortWith(comparator)
             else items~stableSortWith(comparator)


::method process                            -- process sorter piped data item
expose items                                -- access internal state data
use strict arg item, index, dataflow        -- access the passed item
items~append(.indexedItem~new(item, index, dataflow))


::method eof                                -- process the "end-of-pipe"
expose criteria items
message = ""
do criterion over criteria                  -- apply each criterion
    message = criterion[1]
    argument = criterion[2]
    self~send(message, argument)
end
-- if the last criterion is not a "sortBy", then do a sortBy item.
if message <> "sortBy" then self~sortBy("item")
do i = 1 to items~items while .nil <> self~next, \self~next~isEOP -- copy all sorted items to the primary stream
   indexedItem = items[i]
   self~write(indexedItem~item, indexedItem~index, indexedItem~dataflow)
end
forward class(super)                        -- make sure we propagate the done message


::method reset
expose items
use strict arg -- none
items = .array~new                          -- create a new list
forward class (super)


/******************************************************************************/
::class "sortWith" public subclass pipeStage-- sort piped data

::method init
expose comparator items                     -- list of sorted items
use strict arg comparator                   -- get the comparator
items = .array~new                          -- create a new list
forward class (super)                       -- forward the initialization


::method initOptions
expose quickSort
quickSort = .false -- use a stable sort by default
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "quickSort"~caselessAbbrev(a, 1) then do ; quickSort = .true ; iterate ; end
        if "stableSort"~caselessAbbrev(a, 3) then do ; quickSort = .false ; iterate ; end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process                            -- process sorter piped data item
expose items                                -- access internal state data
use strict arg item, index, dataflow        -- access the passed item
items~append(.indexedItem~new(item, index, dataflow)) -- append the item to the accumulator array


::method eof                                -- process the "end-of-pipe"
expose comparator items quickSort
if quickSort then items~sortWith(comparator)
             else items~stableSortWith(comparator)
do i = 1 to items~items while .nil <> self~next, \self~next~isEOP -- copy all sorted items to the primary stream
   indexedItem = items[i]
   self~write(indexedItem~item, indexedItem~index, indexedItem~dataflow)
end
forward class(super)                        -- make sure we propagate the done message


::method reset
expose items
use strict arg -- none
items = .array~new                          -- create a new list
forward class (super)


/******************************************************************************/
::class "reverse" public subclass pipeStage -- a string reversal pipeStage

::method process                            -- pipeStage processing item
use strict arg item, index, dataflow        -- get the data item
newItem = item~string~reverse
self~write(newItem, 1, dataflow)            -- send it along in reversed form
self~checkEOP(self~next)


/******************************************************************************/
::class "upper" public subclass pipeStage   -- a uppercasing pipeStage

::method process                            -- pipeStage processing item
use strict arg item, index, dataflow        -- get the data item
newItem = item~string~upper
self~write(newItem, 1, dataflow)            -- send it along in upper form
self~checkEOP(self~next)


/******************************************************************************/
::class "lower" public subclass pipeStage   -- a lowercasing pipeStage

::method process                            -- pipeStage processing item
use strict arg item, index, dataflow        -- get the data item
newItem = item~string~lower
self~write(newItem, 1, dataflow)            -- send it along in lower form
self~checkEOP(self~next)


/******************************************************************************/
::class "changeStr" public subclass pipeStage-- a string replacement pipeStage

::method init
expose count new old
use strict arg old, new, count = 999999999  -- old and new are required, default count is max item
forward class (super)                       -- forward the initialization


::method process                            -- pipeStage processing item
expose count new old
use strict arg item, index, dataflow        -- get the data item
newItem = item~string~changestr(old, new, count)
self~write(newItem, 1, dataflow)            -- send it along in altered form
self~checkEOP(self~next)


/******************************************************************************/
::class "delStr" public subclass pipeStage  -- a string deletion pipeStage

::method init
expose length offset
use strict arg offset, length               -- both are required.
forward class (super)                       -- forward the initialization


::method process                            -- pipeStage processing item
expose length offset
use strict arg item, index, dataflow        -- get the data item
newItem = item~string~delstr(offset, length)
self~write(newItem, 1, dataflow)            -- send it along in altered form
self~checkEOP(self~next)


/******************************************************************************/
::class "left" public subclass pipeStage    -- a splitter pipeStage

::method init
expose length
use strict arg length                       -- the length is the left part
forward class (super)                       -- forward the initialization


::method process                            -- pipeStage processing item
expose length
use strict arg item, index, dataflow        -- get the data item
newItem1 = item~string~left(length)
newItem2 = item~string~substr(length + 1)
self~write(newItem1, 1, dataflow)           -- send the left portion along the primary stream
self~writeSecondary(newItem2, 1, dataflow)  -- the secondary gets the remainder portion
self~checkEOP(self~next, self~secondary)


/******************************************************************************/
::class "right" public subclass pipeStage   -- a splitter pipeStage

::method init
expose length
use strict arg length                       -- the length is the right part
forward class (super)                       -- forward the initialization


::method process                            -- pipeStage processing item
expose length offset
use strict arg item, index, dataflow        -- get the data item
newItem1 = item~string~right(length)
remainderLength = item~string~length - length
remainder = ""
if remainderLength > 0 then remainder = item~string~left(remainderLength)
newItem2 = remainder
self~write(newItem1, 1, dataflow)             -- send the right portion along the primary stream
self~writeSecondary(newItem2, 1, dataflow)    -- the secondary gets the remainder portion
self~checkEOP(self~next, self~secondary)


/******************************************************************************/
::class "insert" public subclass pipeStage  -- insert a string into each line

::method init
expose insert offset
use strict arg insert, offset               -- we need an offset and an insertion string
forward class (super)                       -- forward the initialization


::method process                            -- pipeStage processing item
expose insert offset
use strict arg item, index, dataflow        -- get the data item
newItem = item~string~insert(insert, offset)
self~write(newItem, 1, dataflow)            -- send the left portion along the primary stream
self~checkEOP(self~next)


/******************************************************************************/
::class "overlay" public subclass pipeStage -- overlay a string into each line

::method init
expose offset overlay
use strict arg overlay, offset              -- we need an offset and an insertion string
forward class (super)                       -- forward the initialization


::method process                            -- pipeStage processing item
expose offset overlay
use strict arg item, index, dataflow        -- get the data item
newItem = item~string~overlay(overlay, offset)
self~write(newItem, 1, dataflow)            -- send the left portion along the primary stream
self~checkEOP(self~next)


/******************************************************************************/
::class "dropNull" public subclass pipeStage-- drop null records

::method process                            -- pipeStage processing item
use strict arg item, index, dataflow        -- get the data item
if item~string \== '' then do               -- forward along non-null records
    self~write(item, index, dataflow)
    self~checkEOP(self~next)
end


/******************************************************************************/
::class "drop" public subclass pipeStage    -- drop the first or last n records
-- .drop ['first' | 'last'] [count=1] [partition]

::method init
expose array counter partitionCount previousPartitionItem
counter = 0                                 -- if first, we need to count the processed items
array = .array~new                          -- if last, we need to accumulate these until the end
partitionCount = 0
previousPartitionItem = .nil
forward class (super)                       -- forward the initialization


::method initOptions
expose count first partitionFunction
first = .true                               -- selects items from the begining by default
count = 1                                   -- number of items to be selected by default
firstSpecified = .false
lastSpecified = .false
countSpecified = .false
partitionFunction = .nil
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "first"~caselessAbbrev(a, 1) then do
            if lastSpecified then raise syntax 93.900 array(self~class~id ": You can't specify 'first' after 'last'")
            if countSpecified then raise syntax 93.900 array(self~class~id ": You can't specify 'first' after the number")
            firstSpecified = .true
            first = .true
            iterate
        end
        if "last"~caselessAbbrev(a, 1) then do
            if firstSpecified then raise syntax 93.900 array(self~class~id ": You can't specify 'last' after 'first'")
            if countSpecified then raise syntax 93.900 array(self~class~id ": You can't specify 'last' after the number")
            lastSpecified = .true
            first = .false
            iterate
        end
        if a~dataType("W") then do
            if countSpecified then raise syntax 93.900 array(self~class~id ": You specified already a number")
            count = a
            countSpecified = .true
            iterate
        end
        unknown~append(a)
        iterate
    end
    if a~hasMethod("doer") then do
        if .nil <> partitionFunction then raise syntax 93.900 array(self~class~id ": Only one partition expression is supported")
        partitionFunction = a~doer
        iterate
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)    -- forward the initialization to super to process the unknown options


::method processFirst
expose count counter partitionCount partitionFunction previousPartitionItem
use strict arg item, index, dataflow
if .nil <> partitionFunction then do
    partitionItem = partitionFunction~do(      item,        index,           dataflow,-
                                         item: item, index: index, dataflow: dataflow)
    if partitionCount == 0 then do
        partitionCount = 1
        previousPartitionItem = partitionItem
    end
    if previousPartitionItem <> partitionItem then do
        counter = 0
        partitionCount += 1
    end
    previousPartitionItem = partitionItem
end
counter += 1                                -- if we've dropped our quota, start forwarding
if counter > count then do
    self~write(item, index, dataflow)
end
else do
    self~writeSecondary(item, index, dataflow) -- non-selected records go down the secondary stream
end
self~checkEOP(self~next, self~secondary)
if counter >= count & .nil == self~next & .nil == partitionFunction then self~isEOP = .true


::method endOfPartition
expose array count
if array~items < count then do              -- didn't even receive that many items?
    loop indexedItem over array while .nil <> self~secondary, \self~secondary~isEOP
        self~writeSecondary(indexedItem~item, indexedItem~index, indexedItem~dataflow) -- send everything down the secondary pipe
    end
end
else do
    first = array~items - count             -- this is the count of selected items
    loop i = 1 to first while .nil <> self~next, \self~next~isEOP
        indexedItem = array[i]
        self~write(indexedItem~item, indexedItem~index, indexedItem~dataflow)-- the selected go to the main pipe
    end
    loop i = first + 1 to array~items while .nil <> self~secondary, \self~secondary~isEOP
        indexedItem = array[i]
        self~writeSecondary(indexedItem~item, indexedItem~index, indexedItem~dataflow) -- the discarded go down the secondary pipe
    end
end


::method processLast
expose array partitionCount partitionFunction previousPartitionItem
use strict arg item, index, dataflow
if .nil <> partitionFunction then do
    partitionItem = partitionFunction~do(      item,        index,           dataflow,-
                                         item: item, index: index, dataflow: dataflow)
    if partitionCount == 0 then do
        partitionCount = 1
        previousPartitionItem = partitionItem
    end
    if previousPartitionItem <> partitionItem then do
        self~endOfPartition
        array~empty
        partitionCount += 1
    end
    previousPartitionItem = partitionItem
end
array~append(.indexedItem~new(item, index, dataflow)) -- just add to the accumulator


::method process
expose first
use strict arg item, index, dataflow
if first then self~processFirst(item, index, dataflow)
         else self~processLast(item, index, dataflow)


::method eof
expose first
if \first then self~endOfPartition
forward class(super)                        -- make sure we propagate the done message


::method reset
counter = 0                                 -- if first, we need to count the processed items
array = .array~new                          -- if last, we need to accumulate these until the end
partitionCount = 0
previousPartitionItem = .nil
forward class (super)


/******************************************************************************/
::class "take" public subclass pipeStage    -- take the first or last n records
-- .take ['first' | 'last'] [counter=1] [partition]

::method init
expose array counter partitionCount previousPartitionItem
counter = 0                                 -- if first, we need to count the processed items
array = .array~new                          -- if last, we need to accumulate these until the end
partitionCount = 0
previousPartitionItem = .nil
forward class (super)                       -- forward the initialization


::method initOptions
expose count first partitionFunction
first = .true                               -- selects items from the begining by default
count = 1                                   -- number of items to be selected by default
firstSpecified = .false
lastSpecified = .false
countSpecified = .false
partitionFunction = .nil
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "first"~caselessAbbrev(a, 1) then do
            if lastSpecified then raise syntax 93.900 array(self~class~id ": You can't specify 'first' after 'last'")
            if countSpecified then raise syntax 93.900 array(self~class~id ": You can't specify 'first' after the number")
            firstSpecified = .true
            first = .true
            iterate
        end
        if "last"~caselessAbbrev(a, 1) then do
            if firstSpecified then raise syntax 93.900 array(self~class~id ": You can't specify 'last' after 'first'")
            if countSpecified then raise syntax 93.900 array(self~class~id ": You can't specify 'last' after the number")
            lastSpecified = .true
            first = .false
            iterate
        end
        if a~dataType("W") then do
            if countSpecified then raise syntax 93.900 array(self~class~id ": You specified already a number")
            count = a
            countSpecified = .true
            iterate
        end
        unknown~append(a)
        iterate
    end
    if a~hasMethod("doer") then do
        if .nil <> partitionFunction then raise syntax 93.900 array(self~class~id ": Only one partition expression is supported")
        partitionFunction = a~doer
        iterate
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)    -- forward the initialization to super to process the unknown options


::method processFirst
expose count counter partitionCount partitionFunction previousPartitionItem
use strict arg item, index, dataflow
if .nil <> partitionFunction then do
    partitionItem = partitionFunction~do(      item,        index,           dataflow,-
                                         item: item, index: index, dataflow: dataflow)
    if partitionCount == 0 then do
        partitionCount = 1
        previousPartitionItem = partitionItem
    end
    if previousPartitionItem <> partitionItem then do
        counter = 0
        partitionCount += 1
    end
    previousPartitionItem = partitionItem
end
counter += 1                                -- if we've dropped our quota, stop forwarding
if counter > count then do
    self~writeSecondary(item, index, dataflow)
end
else do
    self~write(item, index, dataflow)       -- still in the first bunch, send to main pipe
end
self~checkEOP(self~next, self~secondary)
if counter >= count & .nil == self~secondary & .nil == partitionFunction then self~isEOP = .true


:: method endOfPartition
expose array count
if array~items < count then do          -- didn't even receive that many items?
    loop indexedItem over array while .nil <> self~next, \self~next~isEOP
        self~write(indexedItem~item, indexedItem~index, indexedItem~dataflow) -- send everything down the main pipe
    end
end
else do
    first = array~items - count         -- this is the count of discarded items
    loop i = 1 to first while .nil <> self~secondary, \self~secondary~isEOP
        indexedItem = array[i]
        self~writeSecondary(indexedItem~item, indexedItem~index, indexedItem~dataflow) -- the discarded go down the secondary pipe
    end
    loop i = first + 1 to array~items while .nil <> self~next, \self~next~isEOP
        indexedItem = array[i]
        self~write(indexedItem~item, indexedItem~index, indexedItem~dataflow) -- the selected go to the main pipe
    end
end


::method processLast
expose array partitionCount partitionFunction previousPartitionItem
use strict arg item, index, dataflow
if .nil <> partitionFunction then do
    partitionItem = partitionFunction~do(      item,        index,           dataflow,-
                                         item: item, index: index, dataflow: dataflow)
    if partitionCount == 0 then do
        partitionCount = 1
        previousPartitionItem = partitionItem
    end
    if previousPartitionItem <> partitionItem then do
        self~endOfPartition
        array~empty
        partitionCount += 1
    end
    previousPartitionItem = partitionItem
end
array~append(.indexedItem~new(item, index, dataflow))-- just add to the accumulator


::method process
expose first
use strict arg item, index, dataflow
if first then self~processFirst(item, index, dataflow)
         else self~processLast(item, index, dataflow)


::method eof
expose first
if \first then self~endOfPartition
forward class(super)                        -- make sure we propagate the done message


::method reset
counter = 0                                 -- if first, we need to count the processed items
array = .array~new                          -- if last, we need to accumulate these until the end
partitionCount = 0
previousPartitionItem = .nil
forward class (super)


/******************************************************************************/
::class "x2c" public subclass pipeStage     -- translate records to hex characters

::method process                            -- pipeStage processing item
use strict arg item, index, dataflow        -- get the data item
newItem = item~string~x2c
self~write(newItem, 1, dataflow)
self~checkEOP(self~next)


/******************************************************************************/
::class "bitbucket" public subclass pipeStage-- just consume the records

::method process                            -- pipeStage processing item
nop                                         -- do nothing with the data


/******************************************************************************/
::class "fanout" public subclass pipeStage  -- write records to both output streams

::method process                            -- pipeStage processing item
use strict arg item, index, dataflow        -- get the data item
self~write(item, index, dataflow)
self~writeSecondary(item, index, dataflow)
self~checkEOP(self~next, self~secondary)


/******************************************************************************/
::class "merge" public subclass pipeStage

::method _description_ class
nop
/*
Merge the results from primary and secondary streams.
Example :
    -- A merge is used to serialize the branches of the fanout.
    -- There is no specific order (no delay).
    merge = .merge mem | .console
    fanout1 = .left[3]  mem | .lower mem | merge  -- not bufferized
    fanout2 = .right[3] mem | .upper mem | .inject {"my_"item} after | .secondaryConnector | merge -- not bufferized
    .array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout mem >> fanout2 > fanout1)
*/
nop

-- No need of specialized implementation !
-- The default behavior of secondaryProcess is already to merge, so...


/******************************************************************************/
::class "fanin" public subclass pipeStage   -- process main stream, then secondary stream

::method _description_ class
nop
/*
Example :
    -- A fanin is used to serialize the branches of the fanout.
    -- The output from fanout1 is sent to console, then the output from fanout2 (delayed)
    fanin = .fanin mem | .console
    fanout1 = .left[3]  mem | .lower mem | fanin  -- not bufferized
    fanout2 = .right[3] mem | .upper mem | .inject {"my_"item} after | .secondaryConnector | fanin -- bufferized until fanout1 is eof
    .array~of("aaaBBB", "CCCddd", "eEeFfF")~pipe(.fanout mem >> fanout2 > fanout1)
*/
nop


::method init
expose primaryEof secondaryEof array        -- need pair of EOF conditions
use strict arg -- none
primaryEof = .false
secondaryEof = .false
array = .array~new                          -- accumulator for secondary
forward class (super)                       -- forward the initialization


::method processSecondary                   -- handle the secondary input
expose array
use strict arg item, index, dataflow
array~append(.indexedItem~new(item, index, dataflow)) -- just append to the end of the array


::method finalize
expose primaryEof secondaryEof array
if self~I1Counter == 0 then primaryEof = .true
if self~I2Counter == 0 then secondaryEof = .true
if primaryEof & secondaryEof then do
    loop i = 1 to array~items while .nil <> self~next, \self~next~isEOP -- need to write out the deferred items
        indexedItem = array[i]
        self~write(indexedItem~item, indexedItem~index, indexedItem~dataflow)
    end
    forward class (super) message('eof') continue
    forward class (super) message('secondaryEof') continue
end


::method eof
expose primaryEof
primaryEof = .true                          -- mark this branch as finished.
self~finalize                               -- will finalize if the other input hit EOF already


::method secondaryEof                       -- eof on the secondary input
expose secondaryEof
secondaryEof = .true                        -- mark ourselves finished
self~finalize                               -- will finalize if both branches finished


::method reset
primaryEof = .false
secondaryEof = .false
array = .array~new                          -- accumulator for secondary
forward class (super)


/******************************************************************************/
::class "duplicate" public subclass pipeStage-- duplicate each record N times

::method initOptions
expose copies
copies = 1                                  -- by default, we do one duplicate
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if a~dataType("W") then do ; copies = a ; iterate ; end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process                            -- pipeStage processing item
expose copies
use strict arg item, index, dataflow        -- get the data item
loop n=1 to copies + 1 while .nil <> self~next, \self~next~isEOP -- write this out with the duplicate count
    self~write(item, n, dataflow)
end
self~checkEOP(self~next)


/******************************************************************************/
::class "console" subclass pipeStage public

::method init
use strict arg -- none
forward class (super)


::method initOptions
expose actions showPool showTags
actions = .array~new
showTags = .true
showPool = .true
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if \ "memorize"~caselessAbbrev(a, 3) then do -- MUST detect this option here, otherwise would be taken as a string to display
            parse var a first "." rest
            if "dataflow"~caselessAbbrev(first, 1) then do
                dataflowWidth = -1
                if rest <> "" then do -- dataflow.width
                    if rest~dataType("W") then dataflowWidth = rest
                    else raise syntax 93.900 array(self~class~id ": Expected a whole number after "dataflow". in "a)
                end
                actions~append(.array~of("displayDataflow", dataflowWidth))
                iterate
            end
            if "index"~caselessAbbrev(first, 1) then do
                indexWidth = -1
                if rest <> "" then do -- index.width
                    if rest~dataType("W") then indexWidth = rest
                    else raise syntax 93.900 array(self~class~id ": Expected a whole number after "index". in "a)
                end
                actions~append(.array~of("displayIndex", indexWidth))
                iterate
            end
            if "item"~caselessAbbrev(first, 1) then do
                itemWidth = -1
                if rest <> "" then do -- item.width
                    if rest~dataType("W") then itemWidth = rest
                    else raise syntax 93.900 array(self~class~id ": Expected a whole number after "item". in "a)
                end
                actions~append(.array~of("displayItem", itemWidth))
                iterate
            end
            actions~append(.array~of("displayString", a))
            iterate
        end
    end
    else if a~hasMethod("doer") then do
        function = a~doer
        actions~append(.array~of("displayExpression", function))
        iterate
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method representation
use strict arg val
return dataflow_representation(val, .false, .nil) -- showPool=.false, pool=.nil, values=.nil


::method displayDataflow -- private (in comment otherwise error "does not understand message DISPLAYDATAFLOW_UNPROTECTED when profiling)
expose showPool showTags
if showTags then mask="1 2 3 4 5 6 7"
else mask = "1 2 4 5 6 7"
use strict arg width, item, index, dataflow
if width == -1 then .output~charout(dataflow~makeString(mask, showPool))
               else .output~charout(dataflow~makeString(mask, showPool)~left(width))
.output~charout(" ")


::method displayIndex -- private (in comment otherwise error "does not understand message DISPLAY_INDEX_UNPROTECTED when profiling)
use strict arg width, item, index, dataflow
if width == -1 then .output~charout(self~representation(index))
               else .output~charout(self~representation(index)~left(width))
.output~charout(" ")

::method displayItem -- private (in comment otherwise error "does not understand message DISPLAYITEM_UNPROTECTED when profiling)
use strict arg width, item, index, dataflow
if width == -1 then .output~charout(self~representation(item))
               else .output~charout(self~representation(item)~left(width))
.output~charout(" ")


::method displayString -- private (in comment otherwise error "does not understand message DISPLAYSTRING_UNPROTECTED when profiling)
expose isEmptyString
use strict arg string, item, index, dataflow
isEmptyString = (string == "")
.output~charout(string)
.output~charout(" ")


::method displayExpression -- private (in comment otherwise error "does not understand message DISPLAYEXPRESSION_UNPROTECTED when profiling)
use strict arg expression, item, index, dataflow
val = expression~do(      item,        index,           dataflow,-
                    item: item, index: index, dataflow: dataflow)
.output~charout(val~string)
.output~charout(" ")


::method process                            -- process a data item
expose actions isEmptyString showPool
use strict arg item, index, dataflow        -- get the data item
if actions~items == 0 then do
    -- default display
    indexStr = self~representation(index)
    if indexStr <> "" then .output~charout(indexStr" : ")
    .output~lineout(self~representation(item))
end
else do
    do action over actions                 -- do each action
        message = action[1]
        argument = action[2]
        isEmptyString = .false
        self~send(message, argument, item, index, dataflow)
    end
    if \isEmptyString then .output~lineout("") -- newline
end
forward class(super)


/******************************************************************************/
::class "all" public subclass pipeStage     -- a string selector pipeStage

::method init
expose patterns                             -- access the exposed item
patterns = arg(1,'a')                       -- get the patterns list
forward class (super)                       -- forward the initialization


::method initOptions
expose caseless
caseless = .false
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "caseless"~caselessAbbrev(a, 5) then do ; caseless = .true ; iterate ; end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process                            -- process a selection pipeStage
expose caseless patterns                    -- expose the pattern list
use strict arg item, index, dataflow        -- access the data item
selected = .false
do i = 1 to patterns~size while \selected   -- loop through all the patterns
                                            -- this pattern in the data?
    if caseless then selected = (item~string~caselessPos(patterns[i]) <> 0)
                else selected = (item~string~pos(patterns[i]) <> 0)
end
if selected then self~write(item, index, dataflow) -- send it along
            else self~writeSecondary(item, index, dataflow) -- send all mismatches down the other branch, if there
self~checkEOP(self~next, self~secondary)


/******************************************************************************/
::class "notAll" public subclass pipeStage  -- a string de-selector pipeStage

::method init
expose patterns                             -- access the exposed item
patterns = arg(1,'a')                       -- get the patterns list
forward class (super)                       -- forward the initialization


::method initOptions
expose caseless
caseless = .false
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "caseless"~caselessAbbrev(a, 5) then do ; caseless = .true ; iterate ; end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process                            -- process a selection pipeStage
expose caseless patterns                    -- expose the pattern list
use strict arg item, index, dataflow        -- access the data item
selected = .false
do i = 1 to patterns~size while \selected   -- loop through all the patterns
                                            -- this pattern in the data?
    if caseless then selected = (item~string~caselessPos(patterns[i]) <> 0)
                else selected = (item~string~pos(patterns[i]) <> 0)
    if selected then self~writeSecondary(item, index, dataflow) -- send it along the secondary...don't want this one
end
if \selected then self~write(item, index, dataflow)  -- send all mismatches down the main branch
self~checkEOP(self~next, self~secondary)


/******************************************************************************/
::class "startsWith" public subclass pipeStage-- a string selector pipeStage

::method init
expose patterns                             -- access the exposed item
patterns = arg(1,'a')                       -- get the patterns list
forward class (super)                       -- forward the initialization


::method initOptions
expose caseless
caseless = .false
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "caseless"~caselessAbbrev(a, 5) then do ; caseless = .true ; iterate ; end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process                            -- process a selection pipeStage
expose caseless patterns                    -- expose the pattern list
use strict arg item, index, dataflow        -- access the data item
selected = .false
do i = 1 to patterns~size while \selected   -- loop through all the patterns
                                            -- this pattern in the data?
    if caseless then selected = (item~string~caselessPos(patterns[i]) == 1)
                else selected = (item~string~pos(patterns[i]) == 1)
end
if selected then self~write(item, index, dataflow) -- send it along
            else self~writeSecondary(item, index, dataflow) -- send all mismatches down the other branch, if there
self~checkEOP(self~next, self~secondary)


/******************************************************************************/
::class "endsWith" public subclass pipeStage-- a string selector pipeStage

::method init
expose patterns                             -- access the exposed item
patterns = arg(1,'a')                       -- get the patterns list
forward class (super)                       -- forward the initialization


::method initOptions
expose caseless
caseless = .false
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "caseless"~caselessAbbrev(a, 5) then do ; caseless = .true ; iterate ; end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process                            -- process a selection pipeStage
expose caseless patterns                    -- expose the pattern list
use strict arg item, index, dataflow        -- access the data item
selected = .false
do i = 1 to patterns~size while \selected   -- loop through all the patterns
                                            -- this pattern in the data?
    itemString = item~string
    itemStringLength = itemString~length
    pattern = patterns[i]
    patternLength = pattern~length
    if patternLength <= itemStringLength then do
        right = item~string~right(patternLength)
        if caseless then selected = (right~caselessEquals(pattern))
                    else selected = (right == pattern)
    end
end
if selected then self~write(item, index, dataflow) -- send it along
            else self~writeSecondary(item, index, dataflow) -- send all mismatches down the other branch, if there
self~checkEOP(self~next, self~secondary)


/******************************************************************************/
::class "stemCollector" subclass pipeStage public-- collect items in a stem

::method init
expose stem.                                -- expose target stem
use strict arg stem.                        -- get the stem variable target
-- Don't reset the stem, up to the user to reset before running the pipe
-- stem.~empty
if \stem.0~datatype("N") then stem.0 = 0    -- start with zero items, only if stem.0 is not a number
forward class (super)                       -- forward the initialization


::method process                            -- process a stem pipeStage item
expose stem.                                -- expose the stem
use strict arg item, index, dataflow        -- get the data item
stem.0 = stem.0 + 1                         -- stem the item count
stem.[stem.0, 'VALUE'] = item               -- save the item
stem.[stem.0, 'INDEX'] = index              -- save the index
stem.[stem.0, 'DATAFLOW'] = dataflow        -- save the dataflow
forward class(super)


-- No need of reset, the reset of the collected  datas is under the responsability of the user
-- ::method reset


/******************************************************************************/
::class "arrayCollector" subclass pipeStage public-- collect items in an array

::method init                               -- initialize a collector
expose dataflowArray idx indexArray itemArray -- expose target array
use strict arg itemArray, indexArray=.nil, dataflowArray=.nil -- get the array variable target
-- Don't reset the array, up to the user to reset before running the pipe
-- itemArray~empty
-- if .nil <> indexArray then indexArray~empty
-- if .nil <> dataflowArray then dataflowArray~empty
forward class (super)                       -- forward the initialization


::method process                            -- process a stem pipeStage item
expose dataflowArray idx indexArray itemArray -- expose the array
use strict arg item, index, dataflow        -- get the data item
itemArray~append(item)                      -- save the item
if .nil <> indexArray then indexArray~append(index) -- save the index
if .nil <> dataflowArray then dataflowArray~append(dataflow) -- save the dataflow
forward class(super)                        -- allow superclass to send down pipe


-- No need of reset, the reset of the collected  datas is under the responsability of the user
-- ::method reset


/******************************************************************************/
::class "between" subclass pipeStage public -- write only records from first trigger record
                                            -- up to a matching record
::method init
expose endString finished started startString
use strict arg startString, endString
started = .false                            -- not processing any lines yet
finished = .false
forward class (super)                       -- forward the initialization


::method initOptions
expose caseless
caseless = .false
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "caseless"~caselessAbbrev(a, 5) then do ; caseless = .true ; iterate ; end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process
expose endString finished started startString
use strict arg item, index, dataflow
if \started then do                         -- not turned on yet?  see if we've hit the trigger
    if caseless then started = (item~string~caselessPos(startString) > 0)
                else started = (item~string~pos(startString) > 0)
    if started then self~write(item, index, dataflow) -- pass along
               else self~writeSecondary(item, index, dataflow) -- non-selected lines go to the secondary bucket
end
else if \finished then do                   -- still processing?
    if caseless then finished = (item~string~caselessPos(endString) > 0)
                else finished = (item~string~pos(endString) > 0)
    self~write(item, index, dataflow)    -- pass along
end
else do
    self~writeSecondary(item, index, dataflow) -- non-selected lines go to the secondary bucket
end
self~checkEOP(self~next, self~secondary)


::method reset
expose finished started
started = .false                            -- not processing any lines yet
finished = .false
forward class (super)


/******************************************************************************/
::class "after" subclass pipeStage public   -- write only records from first trigger record

::method init
expose started startString
use strict arg startString
started = .false                            -- not processing any lines yet
forward class (super)                       -- forward the initialization


::method initOptions
expose caseless
caseless = .false
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "caseless"~caselessAbbrev(a, 5) then do ; caseless = .true ; iterate ; end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process
expose caseless endString started startString
use strict arg item, index, dataflow
if \started then do                         -- not turned on yet?  see if we've hit the trigger
    if caseless then started = (item~string~caselessPos(startString) > 0)
                else started = (item~string~pos(startString) > 0)
    if \started then self~writeSecondary(item, index, dataflow) -- pass along the secondary stream
end
else self~write(item, index, dataflow)      -- pass along
self~checkEOP(self~next, self~secondary)


::method reset
expose started
started = .false                            -- not processing any lines yet
forward class (super)


/******************************************************************************/
::class "before" subclass pipeStage public  -- write only records before first trigger record

::method init
expose endString finished
use strict arg endString
finished = .false
forward class (super)                       -- forward the initialization


::method initOptions
expose caseless
caseless = .false
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "caseless"~caselessAbbrev(a, 5) then do ; caseless = .true ; iterate ; end
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process
expose caseless endString finished
use strict arg item, index, dataflow
if \finished then do                        -- still processing?
    if caseless
        then finished = (item~string~caselessPos(endString) > 0)
        else finished = (item~string~pos(endString) > 0)
    self~write(item, index, dataflow)   -- pass along
end
else do
    self~writeSecondary(item, index, dataflow) -- non-selected lines go to the secondary bucket
end
self~checkEOP(self~next, self~secondary)


::method reset
expose finished
finished = .false
forward class (super)


/******************************************************************************/
::class "buffer" subclass pipeStage public  -- accumulate all the records, send them <count> times when eof

::method init
expose buffer count delimiter partitionCount previousPartitionItem
use strict arg count = 1, delimiter = ("")
buffer = .array~new
partitionCount = 0
previousPartitionItem = .nil
forward class (super)                       -- forward the initialization


::method initOptions
expose count first partitionFunction
partitionFunction = .nil
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        unknown~append(a)
        iterate
    end
    if a~hasMethod("doer") then do
        if .nil <> partitionFunction then raise syntax 93.900 array(self~class~id ": Only one partition expression is supported")
        partitionFunction = a~doer
        iterate
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)    -- forward the initialization to super to process the unknown options


::method endOfPartition
expose buffer count delimiter partitionCount
loop i = 1 to count while .nil <> self~next, \self~next~isEOP -- now write copies of the set to the stream
     if partitionCount > 1 | i > 1 then do
         self~write(delimiter, 1, .nil) -- put a delimiter between the sets
     end
     loop j = 1 to buffer~items while .nil <> self~next, \self~next~isEOP -- and send along the buffered lines
         indexedItem = buffer[j]
         self~write(indexedItem~item, indexedItem~index, indexedItem~dataflow)
     end
end


::method process
expose buffer partitionCount partitionFunction previousPartitionItem
use strict arg item, index, dataflow
if .nil <> partitionFunction then do
    partitionItem = partitionFunction~do(      item,        index,           dataflow,-
                                         item: item, index: index, dataflow: dataflow)
    if partitionCount == 0 then do
        partitionCount = 1
        previousPartitionItem = partitionItem
    end
    if previousPartitionItem <> partitionItem then do
        self~endOfPartition
        buffer~empty
        partitionCount += 1
    end
    previousPartitionItem = partitionItem
end
buffer~append(.indexedItem~new(item, index, dataflow)) -- just accumulate the item


::method eof
self~endOfPartition
forward class(super)                        -- and send the done message along


::method reset
expose buffer partitionCount previousPartitionItem
buffer = .array~new
partitionCount = 0
previousPartitionItem = .nil
forward class (super)


/******************************************************************************/
::class "partitionedCounter" subclass pipeStage public -- abstract

::method init
expose counter partitionCount previousPartitionItem
use strict arg -- none
counter = 0
partitionCount = 0
previousPartitionItem = .nil
forward class (super)                       -- forward the initialization


::method initOptions
expose first count partitionFunction
partitionFunction = .nil
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        unknown~append(a)
        iterate
    end
    if a~hasMethod("doer") then do
        if .nil <> partitionFunction then raise syntax 93.900 array(self~class~id ": Only one partition expression is supported")
        partitionFunction = a~doer
        iterate
    end
    unknown~append(a)
end
forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method endOfPartition
expose counter partitionCount previousPartitionItem
self~write(counter, previousPartitionItem, .nil); -- write out the counter message


::method count abstract


::method process
expose counter partitionCount partitionFunction previousPartitionItem
use strict arg item, index, dataflow
if .nil <> partitionFunction then do
    partitionItem = partitionFunction~do(      item,        index,           dataflow,-
                                         item: item, index: index, dataflow: dataflow)
    if partitionCount == 0 then do
        partitionCount = 1
        previousPartitionItem = partitionItem
    end
    if previousPartitionItem <> partitionItem then do
        self~endOfPartition
        counter = 0
        partitionCount += 1
    end
    previousPartitionItem = partitionItem
end
counter += self~count(item, index, dataflow)


::method eof
self~endOfPartition
forward class(super)                        -- and send the done message along


::method reset
expose counter partitionCount previousPartitionItem
counter = 0
partitionCount = 0
previousPartitionItem = .nil
forward class (super)


/******************************************************************************/
::class "lineCount" subclass partitionedCounter public-- count number of records passed through the pipeStage

::method count
use strict arg item, index, dataflow
return 1                                    -- just bump the counter on each record


/******************************************************************************/
::class "charCount" subclass partitionedCounter public-- count number of characters passed through the pipeStage

::method count
use strict arg item, index, dataflow
return item~string~length                   -- just bump the counter for the length of each record


/******************************************************************************/
::class "wordCount" subclass partitionedCounter public-- count number of words passed through the pipeStage

::method count
use strict arg item, index, dataflow
return item~string~words                    -- just bump the counter for the number of words


/******************************************************************************/
/**
 * A simple splitter sample that splits the stream based on a pivot item.
 * strings that compare < the pivot item are routed to pipeStage 1.  All other
 * strings are routed to pipeStage 2
 */

::class "pivot" subclass pipeStage public

::method init
expose pivotItem
forward class (super) continue              -- forward the initialization
-- we did the initialization first, as we're about to override the pipeStages
-- store the pipeStage item and hook up the two output streams
use strict arg pivotItem, self~next, self~secondary


::method process                            -- process the split
expose pivotItem
use strict arg item, index, dataflow
if item~string < pivotItem then do         -- simple split test
    self~write(item, index, dataflow)
end
else do
    self~writeSecondary(item, index, dataflow)
end
self~checkEOP(self~next, self~secondary)


/******************************************************************************/
/**
 * a base class for pipeStages that split the processing stream into two or more
 * pipeStages.  The default behavior is to broadcast each line down all of the branches.
 * To customize, override process() and route the transformed lines down the
 * appropriate branch(es) using result with a target index specified.  If you wish
 * to use the default broadcast behavior, just call self~process:super(newItem) to
 * perform the broadcast.
 */

::class "splitter" subclass pipeStage public

::method init
expose stages
stages = arg(1, 'A')                        -- just save the arguments as an array
forward class (super)                       -- forward the initialization


::method start                              -- process "start-of-pipe" condition
expose stages
do stage over stages
    forward continue to (stage)
end


::method append                             -- override for the single append version
expose stages
if self~next == .nil then do                -- if first append
    use strict arg follower
    do stage over stages                    -- append the follower to each of the filter chains
        stage~append(follower)
    end
end
forward class (super)                       -- to update splitter's next. Nothing will go trough it, but useful to know what's the next stage.


::method insert                             -- this doesn't make sense for a splitter
raise syntax 93.963                         -- Can't do this, so raise an unsupported error


::method write                              -- broadcast a result to a particular filter
expose stages
use strict arg which, item, index, dataflow -- which is the fiter index, item is the result
stage = stages[which]
if \stage~isEOP then stage~process(item, index, dataflow); -- have the filter handle this


::method eof                                -- broadcast a done message down all of the branches
expose stages
do stage over stages
    stage~eof
end
-- needed ? forward class(super)                        -- make sure we propagate the done message


::method process                            -- process the stage stream
expose stages
use strict arg item, index, dataflow
do stage over stages                        -- send this down all of the branches
    stage~process(item, index, dataflow)
end
forward message ("checkEOP") arguments (stages)


--::method reset
-- Nothing to reset. Must keep the stages provided at creation.


/******************************************************************************/
-- A 'fileLines' pipeStage to get the contents of a text file line by line.
-- The input item can be a string (used as a path) or a .File instance.
-- In CMS pipelines, this stage is named "getFiles", but I prefer "fileLines"...
::class "fileLines" public subclass pipeStage

::method process
use strict arg item, index, dataflow
if \item~isA(.File) then item = .File~new(item~string)
stream = .Stream~new(item~absolutePath)
signal on notready
stream~open("read")
linepos = 1
do while .nil <> self~next, \self~next~isEOP
    linetext = stream~linein
    self~write(linetext, linepos, dataflow)
    linepos += 1
end
notready:
self~checkEOP(self~next)
stream~close


/******************************************************************************/
-- A 'words' pipeStage to get the words of the current item.
::class "words" public subclass pipeStage

::method process
use strict arg item, index, dataflow
wordpos = 1
do word over item~string~space~makearray(" ") while .nil <> self~next, \self~next~isEOP
    self~write(word, wordpos, dataflow)
    wordpos += 1
end
self~checkEOP(self~next)


/******************************************************************************/
-- A 'characters' pipeStage to get the characters of the current item.
::class "characters" public subclass pipeStage

::method process
use strict arg item, index, dataflow
charpos = 1
do char over item~string~makearray("") while .nil <> self~next, \self~next~isEOP
    self~write(char, charpos, dataflow)
    charpos += 1
end
self~checkEOP(self~next)


/******************************************************************************/
/*
A 'system' pipeStage to execute a system command and get the contents of its stdout line by line.
To investigate : is it possible to get its stderr ?
Maybe with bash : cmd > >(cmd1) 2> >(cmd2) Send stdout of cmd to cmd1 and stderr of cmd to cmd2.
Not good : no easy way to get the exit code of the user command, when piping to rxqueue...
http://stackoverflow.com/questions/2851622/unix-shell-getting-exit-code-with-piped-child
http://stackoverflow.com/questions/8833396/pipe-command-output-but-keep-the-error-code
http://cfajohnson.com/shell/cus-faq-2.html#Q11
Usage :
    .system ["<command>"|<command-doer>]
    if no command specified then use current item as command
Example :
    "*.log"~pipe(.system {"ls" item} | .console)
    .array~of("ls", "hello", "dummy")~pipe(.system | .console)
*/
::class "system" public subclass pipeStage

::method initOptions
expose command doer trace
command = .nil
doer = .nil
trace = .false
unknown = .array~new
do a over arg(1, "a")
    if a~isA(.String) then do
        if "trace"~caselessAbbrev(a, 1) then do ; trace = .true ; iterate ; end
        if \ "memorize"~caselessAbbrev(a, 3) then do -- MUST detect this option here, otherwise would be taken as a command
            if .nil <> command then raise syntax 93.900 array(self~class~id ": Only one command is supported")
            command = a
            iterate
        end
    end
    else do
        -- The doer is supposed to return the command to execute.
        if a~hasMethod("doer") then do
            if .nil <> command then raise syntax 93.900 array(self~class~id ": Only one command is supported")
            command = a
            doer = a~doer
            iterate
        end
    end
    unknown~append(a)
end
if .nil == command then doer = .routines~UseItemAsCommand -- {use arg item; return item}~doer -- raise syntax 93.900 array(self~class~id ": No command specified")
forward class (super) arguments (unknown) -- forward the initialization to super to process the unknown options

::method process protected
expose command doer trace
-- not a block do...end, to not see the 'end' in the trace output
if trace then .traceOutput~say("       >I> Method .system~process")
if trace then trace i
use strict arg item, index, dataflow
if .nil <> doer then command = doer~do(      item,        index,           dataflow,-
                                       item: item, index: index, dataflow: dataflow)
queue = .RexxQueue~new(.RexxQueue~create)
command '| rxqueue "'queue~get'"'
error = (RC <> 0) -- doesn't work ! RC is the return code of rxqueue, not the return code of command
linepos = 1
do while queue~queued() <> 0, .nil <> self~next, \self~next~isEOP
    line = queue~linein
    newIndex = .array~of(command, linepos)
    if error then self~writeSecondary(line, newIndex, dataflow)
    else self~write(line, newIndex, dataflow)
    linepos += 1
end
queue~delete
self~checkEOP(self~next)

-- This routine is needed to keep current file compatible with standard ooRexx.
-- It replaces this block : {use arg item; return item}~doer
::routine UseItemAsCommand
    use arg item
    return item

