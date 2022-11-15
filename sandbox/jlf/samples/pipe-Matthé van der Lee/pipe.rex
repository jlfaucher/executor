#!/usr/bin/rexx
/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-20xx Rexx Language Association. All rights reserved.    */
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
/*  A pipelines implementation                                                */
/*                                                                            */
/* -------------------------------------------------------------------------- */
/*                                                                            */
/*  Description:                                                              */
/*  This program demonstrates the use of ::class and ::method directives to   */
/*  create an implementation of a facility similar to CMS Pipelines.          */
/******************************************************************************/

----------------------------------------------------------------------------------------------------------

--
-- Base STAGE class. Most subclasses need only override the PROCESS() method to implement a stage.
-- The (transformed) records are passed down the pipeline by calling the WRITE method.
--

::class stage public                              -- base stage class

::method new                                      -- NEW message received
return self                                       -- just return ourselves

::method '[]' class                               -- create a stage instance with arguments
forward to(self) message('NEW')                   -- just forward this as a new message

::method init
expose inStream,                                  -- array of input streams
  outStream,                                      -- output streams
  productive,                                     -- if flag set, stage can run first in pipelines
  runList,                                        -- array of additional pipes to start
  runsOn,                                         -- stage parameters
  alias,                                          -- substitute name used in stage messages
  trace                                           -- tracing flag

inStream = .array~new
outStream = .array~new                            -- init the input and output stages
productive = .false                               -- by default, stage cannot be the first stage in a pipe
runList = .array~new
if arg(1)~isA(.array) then runsOn = 'an Array'
else runsOn = quote(arg(1))
alias = .nil
trace = .false

::method inStream attribute
::method outStream attribute
::method productive attribute
::method runList attribute
::method runsOn attribute
::method alias attribute
::method trace attribute

/*
 * input and output stream numbers start at zero, like in CMS Pipelines; so input stream 0 is the "primary" input
 * stream, 1 is the "secondary" input stream, and so on
 * as array indexes must be positive integers, a correction of +1 is needed in places - provided by function !
 */

::method setInStream                              -- register an input stream
expose inStream                                   -- expose array
use strict arg streamNo, stage                    -- get input stream number and stage to connect
if inStream[!(streamNo)] = .nil then,             -- stream number not in use
  inStream[!(streamNo)] = stage                   -- connect stage
else call noGood self~name, 'input stream' streamNo 'already defined as' inStream[!(streamNo)]~fullName

::method setOutStream                             -- register an output stream
expose outStream                                  -- expose output streams array
use strict arg streamNo, stage, force = .false    -- stream number, stage and FORCE flag
if force | outStream[!(streamNo)] = .nil then,    -- under duress, or when the stream number is not in use yet
  outStream[!(streamNo)] = stage                  -- register the output stream
else call noGood self~name, 'output stream' streamNo 'already defined as' outStream[!(streamNo)]~fullName

::method '|' class                                -- concatenate a stage instance with the following stage
use strict arg follower
me = self~new                                     -- create a new stage instance
return me|follower                                -- perform the hook up

::method '|'
use strict arg follower
follower = follower~new                           -- make sure this is an instance
self~append(follower)                             -- do the chain append logic
return self                                       -- we're our own return value

::method append                                   -- append a stage to the chain
expose outStream
use strict arg follower                           -- the stage to connect
if outStream[!(0)] = .nil then do                 -- we're at the end already
  follower~setInStream(0,self)                    -- set us as its primary input
  self~setOutStream(0,follower)                   -- set primary output stream
  end
else outStream[!(0)]~append(follower)             -- else have our successor append it

::method run                                      -- run pipeline starting at this stage
expose productive trace runList
if \productive then,                              -- not capable of executing as a first stage
  call noGood self~name, 'cannot run as the first stage in a pipeline'
use strict arg main = .true                       -- by default, we run as the main pipeline
if trace then say 'Now running' self~fullName
if \main | runList~items > 0 then reply           -- let other pipelines run concurrently
if main & trace then self~showTopology            -- main pipeline, display topology
self~prepare(trace)                               -- prepare all stages
do pipeLine over runList                          -- additional pipes to run
  if trace then pipeLine~runTraced(.false)        -- TRACE active, trace pipeline execution
  else pipeLine~run(.false)                       -- else run it silently, as a subsidiary pipe
  end
self~start('begin')                               -- start feeding the pipeline ourselves

::method runTraced                                -- run and trace pipeline events
expose trace
trace = .true                                     -- switch on tracing
use strict arg main = .true                       -- default is: run as the main pipeline
self~run(main)

::method prepare                                  -- plumbing completed, let stages check their input and output
expose inStream outStream done trace              -- input and output stages, DONE flag, trace flag
if done = '!' then return                         -- already done us
done = '!'                                        -- remember that's done
use strict arg trace
if trace then say 'Preparing stage',              -- issue a trace message
  self~fullName(.true)                            -- displaying our original name
self~ready                                        -- get ourselves ready to go
do stream over inStream
  if stream \= .nil then stream~prepare(trace)    -- recursively ready all connected input stages
  end
do stream over outStream
  if stream \= .nil then stream~prepare(trace)    -- and connected output stages
  end

::method ready                                    -- optionally provided by subclass

::method begin                                    -- to be provided by subclass!
call noGood self~name, 'stage does not understand message BEGIN'

::method process                                  -- default data processing
use strict arg record, streamNo = 0               -- input record and input stream anumber
self~write(record)                                -- output the record on the primary output stream

::method write                                    -- write to an output stream
expose outStream
use strict arg data, streamNo = 0                 -- output data, output stream number
index = !(streamNo)                               -- set corresponding array index
if outStream[index] \= .nil then do               -- specified stream is connected
  if self~trace then say 'Stage' self~fullName',',-- issue a trace message
    'write to' outstream[index]~fullName',',
    'data <'data~left(25~min(data~length)) ||,    -- showing at most 25 characters of the record
    copies('...',data~length>25)'>'
  outStream[index]~process(data)                  -- have the stream process the data
  end

::method eof                                      -- end of file on an input stream
expose outStream trace
use strict arg streamNo = 0                       -- default is primary input
if outStream~items = 0 then do                    -- no output streams connected,
  if trace then say 'EOF' self~fullName ||,       -- just issue a message if tracing is in effect
    copies(', on instream' streamNo,streamNo>0)
  end
else do i = 1 to outStream~last                   -- propagate EOF to all connected outstreams
  stream = outStream[i]
  if stream = .nil then iterate                   -- not connected, ignore
  if trace then say 'EOF' self~fullName',',       -- tracing
    'propagate to' copies('outstream' ?(i) '= ',,
    i>1) || stream~fullName
  stream~eof                                      -- connected, forward it the EOF
  end

::method '+' class                                -- add another pipeline (class method)
use strict arg follower
me = self~new                                     -- create a new stage instance
follower = follower~new                           -- make sure this is an instance
return me+follower                                -- perform the hook up

::method '+'                                      -- add another pipeline
expose trace runList
use strict arg pipeLine                           -- pipeline to add
runList~append(pipeLine)                          -- add it to the run list
return self

::method connect                                  -- establish an input or output connector
use strict arg streamNo, inout = 'INPUT'          -- stream number and i/o type
if \streamNo~datatype('w') | streamNo < 1 then call noGood self~name,,
  'invalid stream number <'streamNo'>, specify a positive whole number'
else select
  when 'INPUT'~caselessAbbrev(inout,1) then,      -- an additional input stream is requested
    return .inputStream~new(self,streamNo)        -- create and return one
  when 'OUTPUT'~caselessAbbrev(inout,1) then,     -- an additional output stream is to be connected
    return .outputStream~new(self,streamNo)       -- set it up
  otherwise call noGood self~name, 'CONNECT option not recognized <'inout'>, specify INPUT or OUTPUT'
  end

::method name                                     -- return stage name
expose runsOn alias
use strict arg original = .false
if original | alias = .nil then,                  -- original name requested, or no alias set
  it = subWord(self,2)                            -- use the class name
else it = alias                                   -- else use alias
return it'('runsOn')'                             -- return name with run-time parameters

::method fullName                                 -- return full name
use strict arg original = .false                  -- original name requested
numeric digits 15
return self~name(original)', id',                 -- return name and ooRexx object id in hex
  d2x(self~identityHash,12)

::method showTopology                             -- show pipeline topology
expose invocationCount                            -- previous invocation number
say 'Pipeline topology:'
if invocationCount~datatype('w') then,            -- another invocation of the method
  invocationCount += 1                            -- increment count
else invocationCount = 1                          -- first invocation
self~topology(invocationCount)                    -- invoke TOPOLOGY
say '  end of topology'

::method topology                                 -- display SELF and input and output stages
expose inStream outStream invocation              -- i/o streams and previous invocation number
use strict arg count
if invocation = count then return                 -- already seen this stage this time
invocation = count                                -- seen it now
say '  stage' self~fullName                       -- say full name
if inStream~items > 0 then do i = 1 to inStream~last
  stream = inStream[i]                            -- show input stream stages - as far as connected
  if stream \= .nil then say '    instream' ?(i) 'is' stream~fullName
  end
else say '    no input streams'
if outStream~items > 0 then do i = 1 to outStream~last
  stream = outStream[i]                          -- show connected output streams
  if stream \= .nil then say '    outstream' ?(i) 'is' stream~fullName
  end
else say '    no output streams'
do stream over inStream
  if stream \= .nil then stream~topology(count)   -- recursively display all connected input streams
  end
do stream over outStream
  if stream \= .nil then stream~topology(count)   -- and all connected output streams
  end

----------------------------------------------------------------------------------------------------------

::class inputStream subclass stage                -- an additional input stream for a stage

::method init                                     -- set us up as an additional input stream for the stage
expose stage streamNo
use strict arg stage, streamNo                    -- stage to connect to, stream number
self~init:super                                   -- init super class
stage~setInStream(streamNo,self)                  -- we are input stream STREAMNO for the stage
self~setOutStream(0,stage)                        -- and the stage is our primary output

::method name                                     -- return our name
expose stage streamNo
return 'Instream' streamNo 'of' stage~name

::method process                                  -- process an incoming record
expose stage streamNo
use strict arg record                             -- retrieve record
if self~trace then say self~fullName',',          -- issue a trace message if requested
  'write to' stage~fullName',',
  'data <'record~left(25~min(record~length)) ||,
  copies('...',record~length>25)'>'
stage~process(record,streamNo)                    -- send it to the stage along with the stream number

::method eof                                      -- EOF handling
expose stage streamNo
if self~trace then say 'EOF' self~fullName',',
  'propagate to' stage~fullName
stage~eof(streamNo)                               -- notify the stage of EOF on this stream

----------------------------------------------------------------------------------------------------------

::class outputStream subclass stage               -- secondary, tertiary, quaternary ... ouput for a stage

::method init                                     -- connect an additional output stream
expose stage streamNo                             -- stage to connect to, output stream number
use strict arg stage, streamNo                    -- get arguments
self~init:super                                   -- init superclass
stage~setOutStream(streamNo,self)                 -- register us as output stream STREAMNO for the stage
self~setInStream(0,stage)                         -- and the stage as our primary input
self~productive = .true                           -- an N-ary output stage can run first in a pipeline

::method name
expose stage streamNo
return 'Outstream' streamNo 'of' stage~name       -- name for TRACE messages

::method begin                                    -- no processing required to begin

----------------------------------------------------------------------------------------------------------
--
-- the actual pipeline stage classes are constructed below.
--
-- stage operands are as for CMS Pipelines, except where indicated after the ::CLASS directive. refer to
-- the CMS Pipelines documentation for a complete description of stage syntax and operation.
--
-- in general, the stage names follow CMS, except when precluded; for example, the STEM class already
-- exists in ooRexx, so we use STEMSTAGE instead; and the file i/o stages <, > and >> are named FILEIN,
-- FILEOUT and FILEAPPEND here.
--
-- stages currently defined:
--
-- ABBREV     ALL        APPEND     ARRAYSTAGE BETWEEN    BUFFER     CHANGE     CHOP       CMD
-- COLLATE    COMBINE    COMMAND    CONS       COPY       COUNT      DAM        DEAL       DROP
-- DUP        DUPLICATE  FANIN      FANINANY   FANOUT     FBLOCK     FILEAPPEND FILEIN     FILEOUT
-- FIND       GATE       GATHER     GET        GETFILES   HOLE       INSIDE     JOIN       JUXTAPOSE
-- LITERAL    LOCATE     LOOKUP     NFIND      NLOCATE    NOT        NOTINSIDE  OUTSIDE    OVERLAY
-- PAD        PICK       PREDSELECT PREFACE    REVERSE    SORT       SPACE      SPEC       SPILL
-- SPLIT      STACK      STEMSTAGE  STRFRLABEL STRIP      STRTOLABEL STRWHILE   TAKE       TERM
-- VERIFY     XLATE      XRANGE     ZONE
--
----------------------------------------------------------------------------------------------------------

::class abbrev public subclass stage              -- select lines beginning with an abbreviation of a word

::method init                                     -- determine processing options
expose word number anycase                        -- expose controls
forward class(super) continue                     -- forward the initialization
use strict arg specs = ''                         -- fetch specifications

word = specs~word(1)                              -- the word to abbreviate
number = specs~word(2)                            -- minimum length of abbreviation
anycase = specs~word(3)                           -- ignore case

if number = '' then number = 0
else if \number~datatype('w') | number < 0 then,  -- must be non-negative
  call noGood self~name, 'number <'number'> invalid, specify a non-negative integer'

if anycase = '' then anycase = .false             -- default is match exact case
else do
  anycase = 'ANYCASE'~caselessAbbrev(anycase,3)   -- must be ANYCASE or an abbreviation thereof
  if \anycase then call noGood self~name, 'operand <'specs~word(3)'> not recognized'
  end

::method process
expose word number anycase                        -- expose controls
use strict arg record                             -- the record to process

parse var record w1 ' '                           -- input up to the first blank

if anycase then ok =,
  word~caselessAbbrev(w1,number)                  -- ok if abbreviates
else ok = word~abbrev(w1,number)

if ok then self~write(record)                     -- it starts with the given string
else self~write(record,1)                         -- no, send to secondary output, if connected

----------------------------------------------------------------------------------------------------------

::class all public subclass stage                 -- a CMS XEDIT-like selector stage

::method init                                     -- interpret our instructions
expose node type. child.                          -- have these exposed for PROCESS method
forward class(super) continue                     -- forward the INIT message
parsed = parseForPickAndAll(self~name,arg(1))     -- have our instructions parsed
node = parsed[1]                                  -- the principal node
type. = parsed[2]                                 -- node types stem
child. = parsed[3]                                -- children stem

::method process                                  -- processing for the ALL stage
expose node type. child.                          -- expose these controls
use strict arg record                             -- retrieve next record from the pipeline
if evaluate(node) then self~write(record)         -- ok, record passes the tests, accept record
else self~write(record,1)                         -- else send it to secondary out, if connected
return

evaluate: procedure expose record type. child.    -- evaluate the logical value of a node
arg node                                          -- node to evaluate
select case type.node                             -- result depends on node type
  when '|' then do                                -- a disjunction
    it = .false                                   -- prime the result to FALSE
    do i = 1 to child.node.0                      -- do each child node
      it = it | evaluate(child.node.i)            -- evaluate and OR it in
      end
    return it                                     -- return the result
    end
  when '&' then do                                -- a conjunction
    it = .true                                    -- prime the result to TRUE
    do i = 1 to child.node.0                      -- do all children
      it = it & evaluate(child.node.i)            -- evaluate child and AND it in
      end
    return it                                     -- then return the outcome
    end
  when '\' then return \evaluate(child.node.1)    -- negation, negate evaluation of its subnode
  otherwise return record~contains(child.node.1)  -- a literal, return TRUE iff it occurs in the record
  end

----------------------------------------------------------------------------------------------------------

::class append public subclass stage              -- copy primary input stream, then run a pipeline
-- argument is the pipeline to append, e.g. use .append[.stemStage[myStem.]] to preface a stem's contents

::method init                                     -- initialize
expose it secondary eofs                          -- pipeline, secondary input stream, number of EOFs
use strict arg it = .nil                          -- the pipeline to append
if \it~isA(.stage) then call noGood self~name, 'argument must be a stage instance, found <'it'>'
self~init:super                                   -- init superclass
self~runsOn = it~name                             -- set our RUNSON attribute
secondary = self~connect(1)                       -- create secondary input to catch the pipeline's output
eofs = 0                                          -- no EOFs yet

::method ready
expose it secondary                               -- pipeline, secondary input stream
reply                                             -- avoid a deadlock
it~trace = self~trace                             -- copy trace setting
stage = it                                        -- determine the final stage of the pipeline
do while stage~outStream[!(0)] \= .nil            -- which is the one missing an output stage
  stage = stage~outStream[!(0)]
  end
stage~setOutStream(0,secondary)                   -- that stage's primary output is our secondary input

::method eof                                      -- EOF on either input stream
expose it eofs                                    -- pipeline and EOF count
eofs += 1                                         -- another EOF
if eofs = 1 then do                               -- this EOF necessarily from our primary input stream
  it~run(.false)                                  -- start the pipeline as a subsidiary
  return                                          -- and wait for it to signal EOF
  end
self~eof:super                                    -- all done, propagate EOF to super

----------------------------------------------------------------------------------------------------------

::class arrayStage subclass stage public          -- fill an array, or pump its contents into the pipeline
-- operand: a local, one-dimensional array containing strings; when run as the first stage in a pipeline,
-- we send any existing array elements down the pipe; otherwise we empty the array, store any incoming
-- records in it, and pass all input records on to the primary output stream (if connected)

::method init
expose array initIndex                            -- target array plus INITINDEX flag
forward class(super) continue                     -- initialize super class first
self~productive = .true                           -- we can run as first stage in pipelines
initIndex = .true                                 -- must initialize INDEX when we're not the first stage
use strict arg array = ''                         -- get target array
if \array~isA(.array) then call noGood self~name, 'argument should be a local array'

::method begin                                    -- run as the first stage in a pipeline
expose array initIndex                            -- expose array, flag
initIndex = .false                                -- clear the flag
do line over array
  self~write(line)                                -- send all array items down the pipe
  end
self~eof                                          -- signal eof

::method process                                  -- process a data item
expose array initIndex index                      -- array, index initialization flag, and index itself

if initIndex then do                              -- must initialize INDEX
  index = 0                                       -- do so
  initIndex = .false                              -- done so
  array~empty                                     -- clear any prior contents
  end

use strict arg record                             -- access pipeline item
index += 1                                        -- bump array index
array[index] = record                             -- store the record in the array
forward class(super)                              -- and output to follow-up stage(s)

::method eof
expose array initIndex
if initIndex then array~empty                     -- no data has arrived on the primary input stream
self~eof:super

----------------------------------------------------------------------------------------------------------

::class between public subclass stage             -- pass records between labels, including the labels

::method init                                     -- initialize
expose specs
forward class(super) continue
specs = arg(1)                                    -- store invocation argument

::method ready
expose specs,                                     -- operation specifications
  anycase,                                        -- ignore case
  groupStart,                                     -- group starts when a record begins with this string
  groupSize,                                      -- size of group
  groupEnd,                                       -- or ending label signifies end-of-group
  group                                           -- group in progress flag

if 'ANYCASE'~,
  caselessAbbrev(specs~word(1),3) then do         -- ANYCASE requested
  anycase = .true
  specs = specs~subWord(2)                        -- remove keyword
  end
else anycase = .false

it = delimitedString(specs,.false)                -- delimited string must be next
if it = .nil then call noGood self~name, 'invalid delimited string: <'specs'>'
specs = it[1]                                     -- data after the delimited string
groupStart = it[2]                                -- group start label

if specs~datatype('w') & specs > 1 then,          -- a number >= 2
  groupSize = format(specs)                       -- save as maximum group size
else do                                           -- not numeric, another delimited string
  it = delimitedString(specs,.false)              -- retrieve it
  if it = .nil then call noGood self~name,,       -- invalid
    'invalid data: <'specs'>, specify a number >= 2 or a delimited string'
  specs = it[1]                                   -- remaining data should be blank
  if specs \= '' then call noGood self~name, 'excessive options <'specs'>'
  groupEnd = it[2]                                -- set end label
  groupSize = -1                                  -- group size not in effect
  end

group = .false                                    -- presently no group in progress

::method process                                  -- process incoming record
expose anycase groupStart groupSize groupEnd group count
use strict arg record

if group then do                                  -- a group is in progress
  if groupSize < 0 then do                        -- look for end label
    if anycase then group =,                      -- reset GROUP flag when found
      \record~caselessAbbrev(groupEnd)
    else group = \record~abbrev(groupEnd)
    end
  else do                                         -- check whether group size is reached
    count += 1                                    -- increment group count
    if count = groupSize then group = .false      -- size is reached, end group
    end
  self~write(record)                              -- send to primary out regardless
  end
else do                                           -- no group active
  if anycase then group =,                        -- set GROUP flag if starting label matches
    record~caselessAbbrev(groupStart)
  else group = record~abbrev(groupStart)
  if group then do                                -- initialize group
    if groupsize > 1 then count = 1               -- label is its first item
    self~write(record)                            -- send to primary out
    end
  else self~write(record,1)                       -- still no group, relay to secondary output stream
  end

----------------------------------------------------------------------------------------------------------

::class buffer subclass stage public              -- buffer records between a null records

::method init
expose buffer,                                    -- input buffer
  count,                                          -- output copies count
  delim,                                          -- delimiter to emit between the copies
  files                                           -- input comes in the form of files, separated by nulls
forward class(super) continue
use strict arg specs = ''                         -- get specifications

w1 = specs~word(1)                                -- first word may be an output copies count

if w1~datatype('w') & w1 >= 0 then do             -- yes
  count = w1                                      -- save COUNT
  delim = specs~subWord(2)                        -- a delimiter may be next
  end
else do                                           -- no
  count = 1                                       -- default COUNT is 1
  delim = specs~strip
  end

if delim \== '' then do                           -- delimiter specified
  it = delimitedString(delim)                     -- if not null, it must be given as a delimited string
  if it = .nil then call noGood self~name, 'invalid delimiter <'delim'>, argument must be a delimited string'
  delim = it                                      -- okay
  end

files = (arg() > 0)                               -- set FILES flag
buffer = .array~new                               -- create a buffer

::method process
expose buffer count delim files
use strict arg record

if files then do                                  -- check for null records
  if record == '' then do                         -- here's one
    do i = 1 to count                             -- emit a number of copies of the file to the output stream
      if i > 1 then self~write(delim)             -- put a delimiter between the copies
      do line over buffer                         -- send along the lines buffered
        self~write(line)
        end
      end
    self~write(record)                            -- output the null line read
    buffer~empty                                  -- clear buffer
    end
  else buffer~append(record)                      -- not a null record, store into the buffer
  end
else buffer~append(record)                        -- normal processing, just put buffer the line

::method eof
expose buffer count delim files

if files then do                                  -- input comes as a set of files
  if buffer~items > 0 then do                     -- last file still in progress
    do i = 1 to count                             -- emit a number of copies of it to the output stream
      if i > 1 then self~write(delim)             -- put a delimiter between the copies
      do line over buffer                         -- send along the lines buffered
        self~write(line)
        end
      end
    end
  end
else do                                           -- normal processing, just flush the buffer to primary out
  do line over buffer
    self~write(line)                              -- send out each buffered line
    end
  end

drop buffer count delim files
forward class(super)                              -- and send the done message along

----------------------------------------------------------------------------------------------------------

::class change public subclass stage              -- change strings in specified zones of input records

::method init
expose anycase,                                   -- case to be ignored
  special,                                        -- special rules apply when ANYCASE holds
  needle,                                         -- string to change
  newNeedle,                                      -- replacement string
  ranges,                                         -- input record ranges to operate on
  count,                                          -- max changes per input record
  newNeedlUp,                                     -- uppercased NEWNEEDLE
  newNeedlUp1                                     -- first character thereof
forward class(super) continue
use strict arg specs = ''                         -- specifications

if 'ANYCASE'~,
  caselessAbbrev(specs~word(1),3) then do         -- ANYCASE requested
  anycase = .true
  specs = specs~subWord(2)                        -- remove keyword
  end
else do
  anycase = .false                                -- need exact matches
  specs = specs~strip
  end

special = .false                                  -- no "special" treatment needed for ANYCASE
ranges = .array~new(10)                           -- array of up to 10 ranges
ranges[1] = .array~of('1,-1')                     -- default range is the complete record

if specs~left(1) = '(' then do                    -- up to 10 ranges between parentheses
  parse var specs '(' list ')' rest               -- get the list
  do i = 1 while list \= ''
    if i = 11 then call noGood self~name, 'more than 10 input ranges specified between the parentheses'
    it = range(list)                              -- determine this range
    if \it[1] then call noGood self~name, 'invalid range <'list~word(i)'>'
    list = it[2]                                  -- rest of list
    ranges[i] = .array~of(it[3])                  -- store range
    end
  select
    when i = 1 then,                              -- the list was empty
      call noGood self~name, 'specify between 1 and 10 ranges between the parentheses'
    when ranges~items = 1 then nop                -- single range
    otherwise do                                  -- multiple ranges
      endColumn = 0                               -- overall end column
      do range over ranges                        -- check ranges do not overlap
        parse value range[1] with  r1 ',' r2      -- find range start and end
        if endColumn = -1 | r1 <= endColumn then, -- overall end already at end of record, or is >= R1
          call noGood self~name, 'ranges overlap, or are not in ascending order'
        endColumn = r2                            -- adapt overall end
        end
      end
    end
  specs = rest~strip('l')                         -- further specifications
  end
else if specs \= '' then do                       -- not a list
  it = inputRange(specs)                          -- a single input range may be given
  if it[1] then do                                -- yes
    specs = it[2]                                 -- input remainder
    ranges[1] = it~section(3)                     -- save the range (it is an array)
    end
  else specs = specs~strip('l')
  end

parse var specs delim 2 needle (delim) newNeedle, -- delimited string may be of the form /NEEDLE/NEWNEEDLE/
  (delim) rest                                    -- get NEEDLE, NEWNEEDLE and remainder
if specs~lastpos(delim) =,                        -- last position of delimiter must equal
  needle~length+newNeedle~length+3 then,          -- the sum of the strings lengths plus three
  specs = rest                                    -- ok
else do                                           -- parsing unsuccessful, need two separate delimited strings
  new = ''                                        -- for forthcoming INTERPRET
  do i = 1 to 2
    it = delimitedString(specs,.false)            -- retrieve one
    if it = .nil then call noGood self~name, 'invalid delimited string <'specs'>'
    interpret new'needle' '= it[2]'               -- ok, assign to (NEW)NEEDLE
    specs = it[1]                                 -- what's left of SPECS
    drop new                                      -- value NEW for second iteration
    end
  end

count = specs~strip
if needle == '' then do                           -- needle is null, COUNT must be omitted or equal to 1
  if count = '' then count = 1                    -- omitted, default is 1
  if count \= 1 then call noGood self~name, 'needle is the null string,',
    'a change count of <'count'> is not valid, it should be 1'
  end
else do
  if count = '' | count = '*' then count = -1     -- the default is to change all occurrences of needle
  else if \count~datatype('w') | count < 0 then,
    call noGood self~name, 'invalid change count <'count'>,',
    'specify a non-negative number or * to change all occurrences of <'needle'>'
  end

if anycase then select
  when newNeedle == '' then nop                   -- replacement string is null
  when needle~verify(xrange('upper'),'m') > 0 |,  -- needle contains uppercase characters
    needle~verify(xrange('alpha'),'m') = 0 then,  -- or no letters at all
    nop                                           -- normal ANYCASE handling
  when needle~verify(xrange('lower'),'m') \= 1,   -- doesn't begin with one or more lowercase characters
    then nop
  otherwise special = .true                       -- it does, employ the bizarre special ANYCASE rules
  end

if special then do                                -- ANYCASE, special handling
  newNeedlUp = newNeedle~upper                    -- uppercase form of NEWNEEDLE
  newNeedlUp1 = newNeedlUp~left(1) ||,            -- only the first character uppercased
    newNeedle~substr(2)
  end


::method process                                  -- processing
expose anycase special needle newNeedle ranges count newNeedlUp newNeedlUp1
use strict arg record

if count = 0 |,                                   -- change count is zero, or
  \anycase & newNeedle~equals(needle) then,       -- NEWNEEDLE is equal to NEEDLE,
  signal output                                   -- so there is nothing to do

if needle == '' then do                           -- NEEDLE is the null string
  range = ranges[1]                               -- must insert NEWNEEDLE before the first range
  from = applyRange(range,record,,,.true)         -- apply the first range, requesting the "from" position
  select case from                                -- test starting position
    when 0 then record = record || newNeedle      -- range starts right after record end, append
    when -1 then nop                              -- invalid, leave alone
    otherwise record =,                           -- the record extends into the range
      record~left(from-1) ||,                     -- data preceding range
      newNeedle           ||,                     -- insert NEWNEEDLE after that
      record~substr(from)                         -- and append the rest of the record
    end
  signal output                                   -- that's it
  end

if record == '' then signal output                -- no use inspecting null records

statement = 'parse var record'                    -- initialize PARSE statement to extract the ranges
haystacks = 0                                     -- # of haystacks that need changing
gaps = 0                                          -- # of gaps before, between or after haystacks
preceding. = 0                                    -- no gaps precede the haystacks
to = 1                                            -- first unused position in input record

do range over ranges                              -- loop over ranges
  it = applyRange(range,record,,,,.true)          -- apply range to record, requesting start and length
  parse var it from ',' len                       -- get start position and length
  if len < 1 then leave                           -- this range out of scope, subsequent ones will be too
  haystacks += 1                                  -- another haystack
  if from > to then do                            -- gap detected before range
    gaps += 1
    statement = statement to 'gap.'gaps           -- store in GAP. stem
    preceding.haystacks = gaps                    -- haystack is preceded by this gap
    end
  statement = statement from 'haystack.'haystacks -- save haystack in HAYSTACK. stem
  to = from+len                                   -- set next unused position
  end

if haystacks = 0 then signal output               -- nothing to do

if to <= record~length then do                    -- gap after last haystack
  gaps += 1
  statement = statement to 'gap.'gaps             -- save in GAP. stem
  end
else gaps = 0                                     -- no final gap, reset GAPS count

interpret statement                               -- now parse the record

number = count                                    -- copy CHANGE count

if special then do                                -- ANYCASE with a bit of a twist
  ln = needle~length                              -- needle length
  lr = newNeedle~length                           -- replacement string length
  do i = 1 to haystacks
    p = 1                                         -- starting position in haystack
    do while p <= haystack.i~length               -- while length not exceeded
      p = haystack.i~caselessPos(needle,p)        -- find next position of needle
      if p > 0 then do                            -- found at P
        it = haystack.i~substr(p,ln)              -- string to be replaced
        vl = it~left(2)~verify(xrange('lower'))   -- test it for lowercase,
        vu = it~left(2)~verify(xrange('upper'))   -- and uppercase characters
        select
          when vl = 0 then it = newNeedle         -- first 2 chars (exist and) are lowercase
          when vu = 0 then it = newNeedlUp        -- they are uppercase
          when vu = 2 then it = newNeedlUp1       -- first one is uppercase, second not (or is absent)
          otherwise it = newNeedle                -- else substitute NEWNEEDLE
          end
        haystack.i = haystack.i~left(p-1) ||,
          it                              ||,     -- replace occurrence by IT
          haystack.i~substr(p+ln)
        number -= 1                               -- done another replacement
        if number = 0 then leave i                -- limit reached
        p += lr                                   -- skip over replacement string
        end
      else p = haystack.i~length+1                -- no more instances
      end
    end
  end
else select
  when count < 0 & anycase then do i = 1,         -- change all occurrences of NEEDLE, disregarding case
      to haystacks
    haystack.i = haystack.i~,
     caselessChangeStr(needle,newNeedle)
    end
  when count < 0 then do i = 1 to haystacks       -- same, but respect case
    haystack.i = haystack.i~,
     changeStr(needle,newNeedle)
    end
  when anycase then do i = 1 to haystacks,        -- ignore case, change requested number of occurrences
      while number > 0
    n = haystack.i~caselessCountStr(needle)       -- get # of occurrences of needle
    if n = 0 then iterate                         -- none found, loop
    n = min(n,number)                             -- do not exceed NUMBER
    haystack.i = haystack.i~,                     -- perform N changes
     caselessChangeStr(needle,newNeedle,n)
    number -= n                                   -- N changes done
    end
  otherwise do i = 1 to haystacks,                -- ditto, but only change exact matches of the needle
      while number > 0
    n = haystack.i~countStr(needle)               -- # of exact matches
    if n = 0 then iterate                         -- zero, don't bother
    n = min(n,number)                             -- do not exceed NUMBER
    haystack.i = haystack.i~,                     -- change N times
     changeStr(needle,newNeedle,n)
    number -= n                                   -- another N changes performed
    end
  end

record = ''                                       -- rebuild record

do i = 1 to haystacks
  gap = preceding.i                               -- non-haystack data preceding this haystack
  if gap > 0 then record = record || gap.gap      -- append data to the record
  record = record || haystack.i                   -- then add the haystack
  end

if gaps > 0 then record = record || gap.gaps      -- must append final gap

output: self~write(record)                        -- output the resulting record

----------------------------------------------------------------------------------------------------------

::class chop subclass stage public                -- chop input records

::method init                                     -- initialize
expose posChop chopPos,                           -- chop at a specified position
  strChop string strLen,                          -- or before string STRING which is of length STRLEN
  offset before not,                              -- offset from match, BEFORE flag, negate target
  anycase matchFound?                             -- caseless operation, match detection expression
forward class(super) continue

posChop = .true                                   -- assume this is a position chop
strChop = .false                                  -- not a string chop
before = .false
use strict arg at = 80                            -- default instruction: at column 80 (CMS/TSO legacy)

if at~datatype('w') then chopPos = format(at)     -- argument is a whole number, save the chop position
else do
  posChop = .false                                -- chop before a string ot a character
  specs = consume(at,'ANYCase')                   -- test if ANYCASE was specified, minimum abbreviation 4
  anycase = specs[4] = 1                          -- set flag if so
  if specs[2]~datatype('w') then do               -- offset specified
    offset = specs[2]                             -- store integer
    specs[1] = specs[3]                           -- skip it
    end
  else offset = 0                                 -- default offset is zero
  specs = consume(specs,'BEFORE','AFTER')         -- BEFORE or AFTER may be next
  before = specs[4] \= 2                          -- chop before string or character, unless AFTER
  specs = consume(specs,'NOT')                    -- check for keyword NOT
  not = specs[4] = 1                              -- chop before the string or character is NOT matched
  string = hexrange(specs[1])                     -- now retrieve the target, trying an XRANGE first
  if string = .nil then do                        -- failed
    specs = consume(specs,'STRing','ANYof')       -- need keyword STRING or ANYOF now
    warning = specs[4] = 0                        -- issue warning when missing
    strChop = specs[4] = 1                        -- STRING was specified
    string = delimitedString(specs[1])            -- need a delimited string now
    select
      when string = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
      when string == '' then call noGood self~name, 'null string found'
      when warning & string~length > 1 then say self~name': ANYOF assumed in front of <'specs[1]'>'
      otherwise nop
      end
    end
  end

if strChop then do
  strLen = string~length                          -- set string length
  matchFound? = copies('\',not)  ||,              -- phrase to be interpreted to determine a match:
    'record~substr(i,'strLen')~' ||,              -- [\]RECORD~SUBSTR(I,STRLEN)~[CASELESS]EQUALS(STRING)
    copies('caseless',anycase)   ||,
    'equals(string)'
  end
else if \posChop then do
  strLen = 1                                      -- string length 1
  if anycase then string =,                       -- for ANYCASE, adapt STRING variable
    string~lower || string~upper
  matchFound? = 'record~substr(i,1)~' ||,         -- we have a match when:
    'verify(string)' copies('\',not)'= 0'         -- RECORD~SUBSTR(I,1)~VERIFY(STRING) [\]= 0
  end

if \posChop & \before then offset =,              -- AFTER, adapt offset to apply on finding a match
  -offset-strLen

::method process                                  -- processing for a CHOP stage
expose posChop chopPos string strLen offset not matchFound?

use strict arg record                             -- retrieve the input record

recLen = record~length                            -- input record length

if posChop then do                                -- chop after the requested position
  if chopPos >= 0 then p = chopPos                -- position not negative, take literally
  else p = chopPos+recLen+1                       -- negative position is relative to record end
  select
    when p <= 0 then do                           -- nothing left after chopping
      self~write('')                              -- so output a null line
      self~write(record,1)                        -- and send input straight to secondary output
      end
    when p < recLen then do                       -- do an actual chop
      self~write(left(record,p))                  -- and send to primary output
      self~write(substr(record,p+1),1)            -- emit remainder to secondary out
      end
    otherwise do                                  -- not long enough to be chopped
      self~write(record)                          -- output the record unaltered
      self~write('',1)                            -- write a null record to secondary output stream
      end
    end
  end
else do                                           -- chop before the string or any of its characters
  do i = 1 to recLen                              -- scan the input record
    interpret 'matched =' matchFound?             -- do we have a match?
    if matched then do                            -- yes
      match = i-offset                            -- apply any offset
      select
        when match < 2 then do                    -- before record position 1
          self~write('')                          -- nothing remains
          self~write(record,1)                    -- send entire record to secondary out
          end
        when match > recLen then do               -- beyond end of record
          self~write(record)                      -- send record to primary out
          self~write('',1)                        -- and a null string to 2out
          end
        otherwise do
          self~write(record~left(match-1))        -- chop before the match and send to 1out
          self~write(record~substr(match),1)      -- remainder goes to 2out
          end
        end
      return
      end
    else if not then i += strLen-1                -- no match here and NOT holds: skip fragment
    end
  self~write(record)                              -- not matched, write record to primary outstream
  self~write('',1)                                -- null line goes to secondary outstream
  end

----------------------------------------------------------------------------------------------------------

::class cmd public subclass stage                 -- CMD is a synonym for COMMAND, defined further down

::method init                                     -- emulate COMMAND
expose cmd
forward class(super) continue
self~productive = .true                           -- CMD can be the first pipeline stage
cmd = .command[arg(1)]                            -- create a COMMAND stage instance

::method ready                                    -- prepare for running
expose cmd                                        -- expose the COMMAND stage
if self~inStream[!(0)] \= .nil then do
  cmd~setInStream(0,self~inStream[!(0)])          -- copy our primary input stream, if we have one
  self~inStream[!(0)]~setOutStream(0,cmd,.true)   -- force our input stream to output to the new stage
  end
if self~outStream[!(0)] \= .nil then,
  cmd~setOutStream(0,self~outStream[!(0)])        -- copy output stream
cmd~alias = 'CMD'                                 -- set alias
cmd~prepare(self~trace)                           -- prepare COMMAND

::method begin
expose cmd
cmd~begin                                         -- begin the COMMAND stage

----------------------------------------------------------------------------------------------------------

::class collate public subclass stage             -- collate streams

::method init                                     -- interpret parms
expose stop,                                      -- stop when either stream has EOF
  pad,                                            -- padding character for shorter keys
  anycase,                                        -- caseless key comparisons
  masterKey,                                      -- key location in master records (primary input stream)
  detailKey,                                      -- ditto for detail records (secondary input)
  output,                                         -- output sequence: detail, master or both
  eof.                                            -- EOF flags
forward class(super) continue

parsed = parseForLookupOrCollate(self~name,arg(1))-- parse specifications

stop = parsed[1]                                  -- store parser's findings
pad = parsed[2]
anycase = parsed[3]
masterKey = parsed[4]                             -- master key comes first(!)
detailKey = parsed[5]
output = parsed[6]
eof. = .false                                     -- no input streams presently at EOF

::method ready
expose queue key used                             -- queues we use
if self~inStream[2] = .nil then call noGood self~name, 'secondary input stream not connected'
if self~inStream~items > 2 then call noGood self~name, 'too many streams'
queue = .array~of(.queue~new,.queue~new)          -- create queues for primary and secondary input
key = .array~of(.queue~new,.queue~new)            -- and queues for record keys
used = .queue~new                                 -- "used" flags for master records (primary input)

::method process                                  -- a record has arrived on either stream
expose stop pad anycase detailKey masterKey,
  output eof. queue key used
use strict arg record, streamNo = 0               -- access record and input stream number

if streamNo >= 0 then do                          -- real record, not a trigger from method EOF
  queue[!(streamNo)]~queue(record)                -- queue incoming record on the appropriate queue
  if record \= .nil then do                       -- not an EOF message
    key[!(streamNo)]~queue(key())                 -- queue key as well
    if streamNo = 0 then used~queue(.false)       -- a master record, queue an "unused" flag
    end
  end

do forever                                        -- multiple details may match new master, so loop
  do i = 1 to 2                                   -- check the two streams
    if \eof.i then do                             -- not at EOF
      if queue[i]~size = 0 then return            -- await further input
      record.i = queue[i]~peek                    -- head of the queue for the stream
      if record.i = .nil then do                  -- an EOF message
        queue[i]~pull                             -- pull it
        eof.i = .true                             -- set flag
        end
      end
    end
  if stop & (eof.1 | eof.2) then return           -- STOP ANYEOF
  do i = 1 to 2
    if eof.i then do                              -- stream has EOF
      do queue[3-i]~items                         -- flush sister stream
        if i = 1 then self~write(queue[2]~pull,2) -- unmatched detail, send to tertiary output stream
        else do                                   -- a master record
          if used~pull then queue[1]~pull         -- it matched some detail records, just dequeue it
          else self~write(queue[1]~pull,1)        -- else output it on the secondary output stream
          end
        key[3-i]~pull                             -- remove key as well
        end
      if eof.[3-i] then do                        -- the other stream had EOF too
        drop stop pad anycase detailKey masterKey,-- clean up
          output eof. queue key used
        self~eof:super                            -- and issue EOF
        end
      return
      end
    key.i = key[i]~peek                           -- retrieve record key
    len.i = key.i~length                          -- key length
    end
  if pad \= -1 then select                        -- padding requested
    when len.1 < len.2 then key.1 =,              -- master key is shorter, pad it
      key.1 || copies(pad,len.2-len.1)
    when len.1 > len.2 then key.2 =,              -- the detail key is the shortest
      key.2 || copies(pad,len.1-len.2)
    otherwise nop                                 -- the two keys are of the same length
    end
  if anycase then comparison =,                   -- compare keys, either ignoring
    .caselessComparator~new~compare(key.1,key.2)
  else comparison =,                              -- or respecting case
    .comparator~new~compare(key.1,key.2)
  if comparison = 0 then do                       -- keys agree
    do w = 1 to output~words                      -- output requested data items
      if output~word(w) = 'DETAIL' then,
        self~write(record.1)                      -- write detail record to primary out
      else self~write(record.2)                   -- else send matching master there
      end
    queue[2]~pull                                 -- remove detail from queue
    key[2]~pull                                   -- key too
    used[1] = .true                               -- this master key has now been used
    end                                           -- there may be more details that match it
  else do
    i = (comparison+1)/2+1                        -- I = 1 if KEY.1 < KEY.2, I = 2 if KEY.1 > KEY.2
    if i = 2 then self~write(record.2,2)          -- detail not matched, send to tertiary out
    else if \used~pull then self~write(record.1,1)-- master not used, transmit to secondary out
    queue[i]~pull                                 -- pop the master or detail record
    key[i]~pull                                   -- remove key as well
    end
  end

key:                                              -- fetch record key
if streamNo = 0 then,                             -- primary input, master record
  return applyRange(masterKey,record)             -- use MASTERKEY and invoke APPLYRANGE
else return applyRange(detailKey,record)          -- this is a detail record so use DETAILKEY

::method eof
expose eof.
use strict arg streamNo = 0                       -- EOF on an input stream

if \eof.[!(streamNo)] then,                       -- EOF flag not set for this stream
  self~start('process',.nil,streamNo)             -- send a nil item to PROCESS, to handle the EOF

----------------------------------------------------------------------------------------------------------

::class combine subclass stage public             -- combine input records using AND, OR and XOR
-- note: more than two connected input streams are supported

::method init                                     -- initialize
expose specs
forward class(super) continue
specs = arg(1)                                    -- specifications

::method ready                                    -- prepare for operation
expose specs,                                     -- specs
  single,                                         -- single input stream
  stop,                                           -- stop limit
  number,                                         -- number of additional reords to combine
  queue,                                          -- input queue(s)
  record.0,                                       -- stem size for the case of multiple input streams
  keyed,                                          -- combine records with the same key 
  key,                                            -- previous key
  count,                                          -- count used with NUMBER
  operator,                                       -- combination operator
  eof.,                                           -- EOF flags
  completed                                       -- processing completed flag

single = self~inStream~items = 1                  -- we have a single input stream

if single then do
  w1 = specs~word(1)                              -- first word of specs
  keyed = .false                                  -- assume KEYLENGTH not specified
  select
    when w1~datatype('w') & w1 >= 0 then do       -- a number specifying the groups to combine
      number = w1+1                               -- group size is the number plus 1
      specs = specs~subWord(2)
      end
    when w1 = '*' then do                         -- asterisk means combine all records
      number = 0                                  -- set to zero
      specs = specs~subWord(2)
      end
    when 'KEYLENGTH'~caselessAbbrev(w1,6) then do -- combine records according to their key
      number = specs~word(2)                      -- key comprises the first NUMBER columns
      if \number~datatype('w') | number < 0 then,
        call noGood self~name, 'invalid key length <'number'>'
      keyed = .true
      key = .nil                                  -- no "previous key"
      specs = specs~subWord(3)
     end
    otherwise number = 2                          -- default is to combine two records at a time
    end
  count = 0                                       -- initialize counter
  queue = .queue~new                              -- queue for the single input stream
  end
else do                                           -- we have multiple input streams
  specs = consume(specs,'STOP',4)                 -- check STOP keyword
  if specs[4] = 1 then do                         -- specified
    specs = consume(specs,'ANYEOF','ALLEOF')      -- EOF handling
    select case specs[4]
      when 1 then stop = 1                        -- stop when any stream has EOF
      when 2 then stop = 0                        -- or when they all do (no limit)
      otherwise do
        if \specs[2]~datatype('w') | specs[2] < 1,
          then call noGood self~name, 'invalid STOP operand <'specs[2]'>'
        stop = specs[2]                           -- set EOF limit
        specs = specs[3]                          -- remaining specs
        end
      end
    end
  else stop = 0                                   -- no threshold
  queue = .array~new                              -- array of input queues
  do i = 1 to self~inStream~last                  -- do all input streams
    if self~inStream[i] = .nil then iterate       -- not connected
    queue[i] = .queue~new                         -- create queue for this stream
    end
  record.0 = self~inStream~items                  -- set size of RECORD. stem
  end

specs = consume(specs,'Or','AND','N',,            -- find the desired method of combination
  'EXClusiveor','X','FIRST','LAST')
select case specs[4]
  when 1    then operator = 'O'                   -- OR
  when 2, 3 then operator = 'N'                   -- AND
  when 4, 5 then operator = 'X'                   -- XOR
  when 6    then operator = 'F'                   -- FIRST
  when 7    then operator = 'L'                   -- LAST
  otherwise call noGood self~name, 'invalid operator <'specs[2]'>'
  end

if specs[1] \== '' then call noGood self~name, 'excessive options <'specs[1]'>'
else drop specs

eof. = .false                                     -- clear EOF flags
completed = .false                                -- processing not completed

::method process
expose single stop queue number record.0 keyed key count operator eof. completed
use strict arg record, streamNo = 0

if single then do                                 -- single input stream
  if streamNo = -1 then do                        -- this is a sweep message from method EOF
    n = queue~items                               -- items queued
    if n > 0 then do
      do i = 1 to n
        record.i = queue~pull                     -- move item to RECORD. stem
        end
      record.0 = n                                -- set count
      if keyed then self~write(key||combine())    -- output the combination with key included
      else self~write(combine())                  -- or output the final combined record group
      end
    return                                        -- processing complete
    end
  if keyed then do                                -- combine records that have the same key
    newKey =,                                     -- record key consists of the first NUMBER columns
      record~left(min(number,record~length))
    if newKey \== key then do                     -- change of key
      n = queue~items                             -- items queued for previous key
      if n > 0 then do
        do i = 1 to n
          record.i = queue~pull                   -- put them into the RECORD. stem
          end
        record.0 = n
        self~write(key || combine())              -- write the combined record
        end
      key = newKey                                -- set new key
      end
    queue~queue(record~substr(number+1))          -- queue the input record less the key
    end
  else do                                         -- combine groups of NUMBER records
    queue~queue(record)                           -- queue the record
    count += 1                                    -- increment count
    if count = number then do                     -- group is now complete
      do i = 1 to number
        record.i = queue~pull
        end
      record.0 = count
      self~write(combine())                       -- output the combined group
      count = 0                                   -- and start a fresh one
      end
    end
  return                                          -- await further events
  end
else do                                           -- multiple input streams
  if completed then return                        -- processing completed, ignore data
  queue[!(streamNo)]~queue(record)                -- queue the input line on the corresponding queue
  do forever                                      -- do while the going is good
    eofs = 0                                      -- number of EOFs
    do i = 1 to self~inStream~last                -- check streams
      if self~inStream[i] = .nil then iterate     -- disconnected
      eofs += eof.i                               -- keep track of EOFs
      if stop > 0 & eofs >= stop then signal done -- too many, done
      end
    if eofs = record.0 then signal done           -- input streams all depleted
    do i = 1 to self~inStream~last                -- get records
      if self~inStream[i] = .nil then iterate
      if eof.i then item = ''                     -- EOF, treat stream as if it held a null record
      else do
        if queue[i]~size = 0 then return          -- no record on this stream, wait for one
        item = queue[i]~peek                      -- peek at the head of the queue
        if item = .nil then do                    -- it is the EOF message
          eof.i = .true                           -- set flag
          eofs += 1                               -- another EOF
          if stop > 0 & eofs >= stop |,           -- STOP limit reached,
            eofs = record.0 then signal done      -- or all streams at EOF now
          queue[i]~pull                           -- pop the message
          item = ''                               -- null record
          end
        end
      record.i = item                             -- store current item for this stream
      end
    self~start('write',combine())                 -- output the combined record
    do i = 1 to self~inStream~last
      if self~inStream[i] \= .nil & \eof.i then,
        queue[i]~pull                             -- remove item from every queue
      end
    end
  end

combine:                                          -- combine records according to specifications
record = ''                                       -- initialize output buffer
do i = 1 to record.0
  recLen = record~length                          -- current buffer length
  n = min(recLen,record.i~length)                 -- or length of RECORD.I, whichever is smaller
  if n > 0 then select case operator              -- work to do, select operator
    when 'O' then record =,
      record~left(n)~bitOr(record.i~left(n))  ||, -- O = bitwise OR
      record~substr(n+1)
    when 'N' then record =,
      record~left(n)~bitAnd(record.i~left(n)) ||, -- N = bitwise AND
      record~substr(n+1)
    when 'X' then record =,
      record~left(n)~bitXor(record.i~left(n)) ||, -- X = bitwise XOR
      record~substr(n+1)
    when 'F' then if i = 1 then record =,
      record.i~left(n) || record~substr(n+1)      -- F = first record determines contents
    otherwise if i = record.0 then record =,
      record.i~left(n) || record~substr(n+1)      -- L = last record does
    end
  record = record || record.i~substr(recLen+1)    -- append any RECORD.I contents beyond RECLEN
  end
return record                                     -- produce the desired result

done: completed = .true                           -- set COMPLETED flag
do i = 1 to self~inStream~last                    -- do input streams
  if self~inStream[i] = .nil then iterate         -- skip if not connected
  queue[i]~empty                                  -- clear queues
  end
drop stop queue number keyed key record.0 count,  -- free storage, but keep SINGLE and COMPLETED
  operator eof.
self~eof:super                                    -- signal EOF
return

::method eof
expose single stop queue number keyed key record.0 count operator eof. completed
use strict arg streamNo = 0                       -- EOF for some input stream
if single then do                                 -- a single input stream is connected
  self~process(.nil,-1)                           -- send a sweep message to PROCESS (on "stream -1")
  self~eof:super                                  -- propagate the EOF
  drop single stop queue number keyed key,        -- clean up
    record.0 count operator eof. completed
  end
else do                                           -- multiple streams scenario
  if completed then return                        -- ignore when processing completed
  if \eof.[!(streamNo)] then,                     -- when EOF flag not yet set for this stream,
    self~start('process',.nil,streamNo)           -- relay a nil item to PROCESS, to deal with the EOF
  end

----------------------------------------------------------------------------------------------------------

::class command public subclass stage             -- issue commands, write response to pipeline

::method init                                     -- initialize
expose initial command tempfile stream            -- initial command, temporary file, i/o stream
forward class(super) continue
self~productive = .true                           -- we can be the first stage in a pipeline

use strict arg command = ''                       -- optional initial command
initial = (command \= '')
e = 'ENVIRONMENT'
tempfile =  value('HOMEDRIVE',,e)   ||,           -- temp file for trapping command output
  value('HOMEPATH',,e)'\Documents\' ||,
  'pipetmp.txt'
stream = .stream~new(tempfile)                    -- create a stream for this file

::method begin
expose initial command tempfile stream
if initial then do
  itinial = .false
  call hostCommand self, command, tempfile,,      -- issue the initial command, if any
    stream
  end

::method process
expose tempfile stream
call hostCommand self, arg(1), tempfile, stream   -- run incoming host command

::method eof
expose tempfile
'DEL' tempfile                                    -- clean up

----------------------------------------------------------------------------------------------------------

::routine hostCommand                             -- run an external environment command

use strict arg caller, command, tempfile, stream

''strip(command) '>' tempfile                     -- issue it and trap its output

do line over stream~arrayIn
  caller~write(line)                              -- have caller emit the output lines
  end

stream~close

return

----------------------------------------------------------------------------------------------------------

::class cons subclass stage public                -- perform console i/o
-- no arguments supported; TERM is a synonym for CONS

::method init
forward class(super) continue
self~productive = .true                           -- we can run as the first stage
self~runsOn = ''

::method begin                                    -- running first in a pipeline
say 'Please enter data to send down the pipeline. Enter a null line to signal EOF.'
do forever
  parse pull data                                 -- read terminal input
  if data == '' then leave                        -- finished
  self~write(data)                                -- output data
  end
self~eof                                          -- signal EOF

::method process                                  -- process a record from the pipeline
use strict arg record                             -- get it
say record                                        -- display it
self~write(record)

----------------------------------------------------------------------------------------------------------

::class copy public subclass stage                -- an arcane filter

::method init
expose buffered                                   -- data buffered flag
forward class(super) continue
self~runsOn = ''
buffered = .false                                 -- no data buffered yet

::method process                                  -- an input record has arrived
expose buffer buffered                            -- input buffer holding at most one record, and flag
use strict arg record
if buffered then self~write(buffer)               -- a previous record was delayed, output it
else buffered = .true                             -- set flag
buffer = record                                   -- delay the new record

::method eof                                      -- eof
expose buffer buffered
if buffered then self~write(buffer)               -- output any buffered item
buffered = .false
drop buffer buffered
self~eof:super

----------------------------------------------------------------------------------------------------------

::class count subclass stage public               -- count bytes, words, or records

::method init
expose option. count.                             -- counting options, counts per option
forward class(super) continue
use strict arg specs = ''                         -- access the options

if specs = '' then call noGood self~name, 'counting options missing'

option. = .false                                  -- initialize option flags to all FALSE

do forever
  specs = consume(specs,,                         -- test the options requested
    'CHARACTErs','CHARS','BYTES',,                -- CHARACTERS; CHARS and BYTES are synonyms
    'WORDS',,                                     -- second option is WORDS, cannot be abbreviated
    'LINES','RECORDS',,                           -- third one is LINES, for which RECORDS is a synonym
    'MINline',,                                   -- fourth is MINline, abbreviate to MIN at least
    'MAXline')                                    -- fifth is MAXline, MAX suffices
  select case specs[4]                            -- test which applies and set corresponding flag
    when 1, 2, 3 then option.1 = .true
    when 4       then option.2 = .true
    when 5, 6    then option.3 = .true
    when 7       then option.4 = .true
    when 8       then option.5 = .true
    otherwise call noGood self~name, 'option <'specs[2]'> not recognized'
    end
  if specs[1] == '' then leave                    -- end of input
  end

count. = 0                                        -- initialize counts
count.4 = copies('9',18)                          -- set shortest length to "infinity"

::method ready
expose secondary
secondary = (self~outStream[!(1)] \= .nil)        -- secondary output stream exists

::method process
expose option. count. secondary
use strict arg record
numeric digits 18                                 -- request sufficient precision

do i = 1 to 5                                     -- all five options
  if option.i then select case i                  -- option is in effect
    when 1 then count.i += record~length          -- 1 = count bytes
    when 2 then do                                -- 2 = count true words , i.e. blank delimited ones
      ix = record~verify(' ')                     -- locate the first non-blank character
      do while ix > 0
        count.i += 1                              -- found another word
        ix = record~verify(' ','m',ix+1)          -- position of next blank
        if ix = 0 then leave                      -- not found
        ix = record~verify(' ',,ix+1)             -- next non-blank
        end
      end
    when 3 then count.i += 1                      -- 3 = count lines
    when 4 then count.i =,                        -- 4 = find minimal record size
      min(count.i,record~length)
    when 5 then count.i =,                        -- 5 = find maximal record size
      max(count.i,record~length)
    otherwise nop
    end
  end

if secondary then self~write(record)              -- secondary outstream connected, send record to primary

::method eof
expose option. count. secondary

counts = ''                                       -- the counts record to output

do i = 1 to 5
  if option.i then counts = counts || count.i ''  -- option used, append the pertinent count plus a blank
  end

counts = counts~strip('t')                        -- remove trailing blank

if secondary then self~write(counts,1)            -- write counts line to secondary output if connected
else self~write(counts)                           -- else write it to primary output stream

forward class(super)                              -- and send the done message along

----------------------------------------------------------------------------------------------------------

::class dam subclass stage public                 -- pass records once primary input arrives

::method init                                     -- initialize
expose waitingForInputFromPrimaryInputStream      -- a self-explanatory flag
self~init:super
self~runsOn = ''                                  -- no arguments defined
waitingForInputFromPrimaryInputStream = .true     -- no primary input received yet

::method ready                                    -- verify that our input and output streams are balanced
expose queue eof.
queue = .array~new                                -- array of queues to store our input while we wait
eof. = .false                                     -- EOF flags

if self~inStream~items > 0 then do                -- verify input streams
  do i = 1 to self~inStream~last
    if self~inStream[i] = .nil then iterate       -- not connected, iterate
    if self~outStream[i] = .nil then call bad,
      'no output stream for input stream' ?(i)    -- no corresponding output stream
    end
  end

if self~outStream~items > 0 then do               -- verify output streams
  do i = 1 to self~outStream~last
    if self~outStream[i] = .nil then iterate      -- this one is not connected
    if self~inStream[i] = .nil then call bad,
      'no input stream for output stream' ?(i)    -- input stream missing
    queue[i] = .queue~new                         -- create a queue for this stream
    end
  end

return

bad:                                              -- no good
drop queue eof.                                   -- clean up
call noGood self~name, arg(1)                     -- show message and signal an error

::method process
expose waitingForInputFromPrimaryInputStream queue
use strict arg record, streamNo = 0               -- the record and the stream it came in on
queue[!(streamNo)]~queue(record)                  -- queue the input record on the relevant queue

if waitingForInputFromPrimaryInputStream then do  -- we are still waiting for input from primary
  if streamNo > 0 then return                     -- and present record doesn't help, return
  waitingForInputFromPrimaryInputStream  = .false -- burst the dam
  end

do i = 1 to self~inStream~last                    -- short each stream
  if self~inStream[i] = .nil then iterate         -- not connected, ignore
  do queue[i]~items                               -- do all items queued for this input stream
    self~write(queue[i]~pull,?(i))                -- dequeue and send to corresponding output stream
    end
  end

::method eof                                      -- handle an EOF message
expose queue eof.
use strict arg streamNo = 0                       -- EOF on this stream
eof.[!(streamNo)] = .true                         -- set flag for the stream

do i = 1 to self~inStream~last                    -- check input streams
  if self~inStream[i] \= .nil & \eof.i then return-- this one not EOF
  end

drop queue eof.
self~eof:super

----------------------------------------------------------------------------------------------------------

::class deal public subclass stage                -- deal input records to output streams round robin
-- supported operands: SECONDARY [LATCH], KEY inputRange [STRIP], STREAMID inputRange [STRIP]

::method init
expose default,                                   -- default flag stands for round robin
  secondary,                                      -- output stream numbers arrive on secondary instream
  latch,                                          -- process secondary input records as they arrive
  key,                                            -- use a key to decide an output stream switch
  range,                                          -- input record range determining the key or stream id
  strip,                                          -- the range should be stripped
  stripLeft,                                      -- from the left of the input record
  stream,                                         -- output stream number
  oldKey                                          -- previous key
forward class(super) continue

specs = consume(arg(1),,                          -- check specifications for the keywords:
  'SECONDARy','KEY','STREAMid')                   -- SECONDARy, KEY and STREAMID

default = specs[4] = 0                            -- set flags depending on CONSUME()'s response
secondary = specs[4] = 1
key = specs[4] = 2
streamid = specs[4] = 3                           -- output stream number is given by input record field

select
  when secondary then do                          -- SECONDARY is in effect
    specs = consume(specs,'LATCH')                -- check if LATCH is specified
    latch = specs[4] = 1                          -- LATCH, set flag
    end                                           -- else process primary & secondary input records in pairs
  when key | streamid then do                     -- determine position of key or stream id in input lines
    it = inputRange(specs[1])                     -- extract input range
    if it[1] then do                              -- was okay
      range = it~section(3)                       -- store the range
      specs = consume(it[2],'STRIP')              -- keyword STRIP may be given next
      strip = specs[4] = 1                        -- set flag
      if strip then do                            -- inspect the range items
        do item over range
          sub = item = 'SUB'                      -- test for SUBSTR
          if sub then leave                       -- leave when present
          if item~substr(2,1) \= 'S' then,        -- ignore separator items
            parse var item from ',' to            -- get FROM and TO columns
          end
        if sub | 'F1'~pos(from) = 0 & to \= -1,   -- FROM and TO not boundary columns, or SUBSTR was used
          then call noGood self~name, 'STRIP requires the input range',
          'to be either at the beginning or at the end of the record'
        stripLeft = 'F1'~pos(from) > 0            -- strip the key off the left or the right of the record
        end
      end
    else call noGood self~name, 'invalid input range <'specs[1]'>'
    end
  otherwise nop
  end

if specs[1] \== '' then call noGood self~name, 'excessive options <'specs[1]'>'
stream = 1                                        -- start at the first output stream
oldKey = .nil                                     -- no key yet

::method ready                                    -- check input and output streams
expose secondary latch streams queue eofs
if secondary & self~instream[!(1)] = .nil then,
  call noGood self~name, 'SECONDARY specified, but secondary input stream is not connected'
if self~inStream~items > 1+secondary then call noGood self~name, 'too many input streams connected'
streams = ''                                      -- initialize list of output stream numbers
if self~outStream~items > 0 then,
   do i = 1 to self~outStream~last
  if self~outStream[i] \= .nil then,
    streams = streams ?(i)                        -- add the true stream number to the list
  end
if streams = '' then call noGood self~name, 'no output streams connected'
if secondary then do                              -- output stream numbers arrive on 2in
  eofs = 0                                        -- number of EOFs
  if latch then stream = streams~word(1)          -- set initial output stream number
  else do                                         -- input comes in pairs
    queue = .array~new(2)
    queue[1] = .queue~new                         -- queue for records on 1in
    queue[2] = .queue~new                         -- and one for records on 2in
    end
  end

::method process
expose default secondary latch queue key range strip stripLeft stream streams oldKey
use strict arg record, streamNo = 0

select                                            -- perform requested form of processing
  when default then do                            -- round robin
    self~write(record,streams~word(stream))       -- output on stream whose turn it is
    stream += 1                                   -- set next stream
    if stream > streams~words then stream = 1     -- start a new cycle
    end
  when secondary then do                          -- output stream numbers arrive on secondary in
    if latch then do                              -- process 2in as soon as they arrive
      if streamNo = 0 then,                       -- primary input record
        self~write(record,stream)                 -- output on stream that was selected last
      else do                                     -- line on secondary input
        stream = record~strip                     -- select new outstream
        if streams~wordPos(stream) = 0 then,      -- invalid input
          call bad 'secondary'
        end
      end
    else do                                       -- need a record on both input streams
      queue[!(streamNo)]~queue(record)            -- queue incoming line on appropriate queue
      record = queue[1]~peek
      if record = .nil then return                -- no input on primary instream, wait
      stream = queue[2]~peek
      if stream = .nil then return                -- no input on secondary instream
      stream = stream~strip
      if streams~wordPos(stream) = 0 then,        -- input invalid
        call bad 'secondary'
      queue[1]~pull
      queue[2]~pull                               -- dequeue queue heads
      self~write(record,stream)
      end
    end
  when key then do                                -- output stream changes when input record key does
    newKey = applyRange(range,record)             -- look up key in the record
    if newKey \== oldKey then do                  -- if key changes, change stream
      if oldKey \= .nil then do
        stream += 1                               -- set next stream
        if stream > streams~words then stream = 1 -- start a new cycle
        end
      oldKey = newKey                             -- save key
      end
    if strip then do
      if stripLeft then record =,
        record~substr(newKey~length+1)            -- strip from the left
      else record =,
        record~left(record~length-newKey~length)  -- or from the right
      end
    self~write(record,streams~word(stream))       -- output on current stream
    end
  otherwise do                                    -- output stream given by input record field
    stream = applyRange(range,record)             -- find the desired output stream number
    if streams~wordPos(stream~strip) = 0 then,    -- invalid input
      call bad 'primary'
    if strip then do
      if stripLeft then record =,
        record~substr(stream~length+1)            -- strip from the left
      else record =,
        record~left(record~length-stream~length)  -- strip from the right
      end
    self~write(record,stream)                     -- shake it all about
    end
  end

return                                            -- done

bad: call noGood self~name, 'invalid output stream number <'stream'> requested in' arg(1) 'input record'

::method eof
expose default secondary latch queue eofs
if secondary then do                              -- secondary instream was used
  eofs += 1                                       -- another EOF
  if eofs < 2 then return                         -- need one more
  if \latch then drop queue                       -- discard queues
  end
self~eof:super

----------------------------------------------------------------------------------------------------------

::class drop public subclass stage                -- drop the first or last N records or bytes

::method init
expose specs
forward class(super) continue
specs = arg(1)                                    -- invocation parameter

::method ready
expose specs first n bytes count queue            -- FIRST flag, number N, BYTES flag, item count, queue

specs = consume(specs,'FIRST','LAST')             -- test keywords FIRST and LAST
first = specs[4] \= 2                             -- FIRST is the default, except when LAST is specified
n = specs[2]                                      -- number of records or bytes to drop

select case n
  when '' then n = 1                              -- the default for N is 1
  when '*' then do                                -- * means drop all input
    n = -1                                        -- store as -1
    specs[1] = specs[3]                           -- consume asterisk
    end
  otherwise do
    if n~datatype('w') & n >= 0 then,             -- a nonnegative integer, consume it
      specs[1] = specs[3]
    else n = 1                                    -- other, perhaps the BYTES keyword
    end
  end

specs = consume(specs,'BYTEs')                    -- N may reflect bytes rather then records
bytes = specs[4] = 1                              -- set flag if this is requested
if specs[1] \== '' then call noGood self~name, 'operand <'specs[1]'> not recognized'

if \first & n > 0 then do                         -- LAST with a positive N
  if bytes then queue = .queue~new                -- a queue for DROP LAST N BYTES
  else queue = .circularQueue~new(n)              -- circular queue used if BYTES not in effect
  end
count = 0                                         -- initialize count

::method process                                  -- process incoming record
expose first n bytes count queue
use strict arg record

select
  when n < 0 then self~write(record,1)            -- must drop all input, send to secondary output
  when first then do                              -- FIRST
    if bytes then do                              -- must drop N bytes
      if count >= n then self~write(record)       -- already done
      else do
        len = record~length                       -- record length
        count += len                              -- increment byte count
        x = count-n                               -- excess bytes
        if x < 0 then self~write(record,1)        -- none so far, output record to secondary out
        else do                                   -- limit reached or exceeded
          self~write(record~left(len-x),1)        -- drop the first part of the record to 2out
          if x > 0 then,                          -- if anything remains,
            self~write(record~right(x))           -- send it to primary output
          end
        end
      end
    else do                                       -- drop N records
      count += 1                                  -- increment record count
      if count > n then self~write(record)        -- we've dropped our quota, send to primary output
      else self~write(record,1)                   -- still in the first bunch, transfer to secondary out
      end
    end
  when n = 0 then self~write(record)              -- drop the last 0 items, so send everything to primary
  when bytes then do                              -- drop last N bytes
    queue~queue(record)                           -- queue incoming data
    count += record~length                        -- increment queued byte count
    do while count >= n                           -- perhaps we can emit some delayed lines
      record = queue~peek                         -- have a peek at the head of the queue
      if count >= n+record~length then do         -- can be missed without compromising the quota N
        self~write(record)                        -- write the delayed record
        queue~pull                                -- dequeue it
        count -= record~length                    -- and decrement queued bytes
        end
      else leave                                  -- must wait for more input
      end
    end
  otherwise do                                    -- last N > 0 records
    it = queue~queue(record)                      -- queue record, possibly causing an item to fall off
    if it \= .nil then self~write(it)             -- send the delayed item to primary output
    end
  end

::method eof
expose first n bytes count queue

if \first & n > 0 then do                         -- LAST, but not LAST * or LAST 0
  if bytes then do                                -- dropping bytes
    record = queue~pull                           -- this record to be split
    if count > n then,                            -- excess bytes are queued
      self~write(record~left(count-n))            -- write them to the primary outstream
    self~write(record~substr(count-n+1),1)        -- record remainder goes to secondary out
    end                                           -- fall thru and purge the queue
  do record over queue                            -- the last N records or bytes were queued
    self~write(record,1)                          -- send them to our secondary outstream
    end
  end

drop queue                                        -- free storage
forward class(super)                              -- forward EOF to super

----------------------------------------------------------------------------------------------------------

::class dup public subclass stage                 -- DUP is a synonym for DUPLICATE

::method init
expose double
forward class(super) continue
double = .duplicate[arg(1)]                       -- create a DUPLICATE stage

::method ready                                    -- prepare for running
expose double                                     -- expose the new stage
if self~inStream[!(0)] \= .nil then do
  double~setInStream(0,self~inStream[!(0)])       -- copy our primary input stream
  self~inStream[!(0)]~setOutStream(0,double,.true)-- force our input stream to output to the new stage
  end
if self~outStream[!(0)] \= .nil then,
  double~setOutStream(0,self~outStream[!(0)])     -- and output stream
double~alias = 'DUP'                              -- set alias for error messages
double~prepare(self~trace)

----------------------------------------------------------------------------------------------------------

::class duplicate public subclass stage           -- duplicate each record N times

::method init
expose copies                                     -- number of additional copies to write
forward class(super) continue
use strict arg copies = 1                         -- by default, output one duplicate of each record

if copies = '*' then copies = -2                  -- * requests infinite duplication
else if \copies~datatype('w') | copies < -1 then,
  call noGood self~name, 'invalid count <'copies'>, specify * or a whole number >= -1'

::method process                                  -- process a record
expose copies
use strict arg record                             -- retrieve it

if copies = -2 then do forever                    -- option "*", send out the first record over and over
  self~write(record)
  end
else do copies+1                                  -- output each record the requested number of times,
  self~write(record)                              -- which may be zero
  end

----------------------------------------------------------------------------------------------------------

::class fanin public subclass stage               -- process each input stream in turn
-- operands supported: none

::method init
expose eof. items. array                          -- EOF flags per input stream, item counts, buffer array
forward class(super) continue                     -- FANIN produces no data, but can run first in pipeline
self~productive = .true
self~runsOn = ''
eof. = .false                                     -- clear EOF flags
items. = 0
array = .array~new                                -- buffer array

::method ready
expose lowest at                                  -- LOWEST numbered input stream, AT used by EOF() method
if self~inStream~items = 0 then call noGood self~name, 'no input streams'
do at = 1 to self~inStream~last
  if self~inStream[at] \= .nil then leave
  end
lowest = ?(at)                                    -- lowest numbered connected input stream

::method begin                                    -- no action required to BEGIN

::method process                                  -- data processing
expose items. array lowest
use strict arg record, streamNo = 0               -- input record and input stream anumber

if streamNo = lowest then self~write(record)      -- lowest number input stream, do not delay this record
else do
  items.streamNo += 1                             -- another line from this stream
  array[!(streamNo),items.streamNo] = record      -- store it in the array
  end

::method eof
expose expose eof. items. array lowest at
use strict arg streamNo = 0                       -- number of the input stream that is at EOF
eof.streamNo = .true                              -- this stream now at EOF
streams = self~inStream~last-1

if streamNo <= at then do str = at to streams     -- perhaps we can output some buffered input streams
  do i = 0 to str                                 -- check completion of input streams up to this one
    if self~inStream[!(i)] \= .nil & \eof.i then, -- this one is connected, but not at EOF
      leave
    end
  if i > str then do                              -- they completed
    if self~inStream[!(str)] \= .nil then,        -- and input stream STR is connected
       do i = 1 to items.str                      -- we can now output stream number STR
      self~write(array[!(str),i])                 -- forward all records received on that stream
      end
    at = str+1                                    -- next time start at the next higher stream
    end
  else do                                         -- STR or an earlier stream not at EOF
    at = str                                      -- remember to retry at this one next time
    leave
    end
  end

if at > streams then do
  self~eof:super                                  -- all of our input streams are done
  drop eof. items. array lowest at
  end

----------------------------------------------------------------------------------------------------------

::class faninany public subclass stage            -- merge results from all input streams
-- operands supported: none

::method init
expose eof.                                       -- an array of EOF conditions
forward class(super) continue
self~productive = .true
self~runsOn = ''
eof. = .false

::method begin                                    -- no action required; no overriding PROCESS() method

::method eof
expose eof.                                       -- expose interlock flags
use strict arg streamNo = 0

eof.[!(streamNo)] = .true                         -- this stream is at EOF

do i = 1 to self~inStream~last                    -- do all input streams
  if self~inStream[i] \= .nil & \eof.i then return-- this one is connected but not at EOF
  end

self~eof:super                                    -- all connected input streams are at EOF, so so are we

----------------------------------------------------------------------------------------------------------

::class fanout public subclass stage              -- write records to all connected output streams
-- operands supported: none

::method init
forward class(super) continue
self~runsOn = ''

::method process                                  -- process an item
use strict arg record                             -- get input record

if self~outStream~items = 0 then return           -- output streams array is empty

do i = 1 to self~outStream~last                   -- all output streams
  if self~outStream[i] \= .nil then,              -- this one's connected
    self~write(record,?(i))                       -- so output to that stream
  end

----------------------------------------------------------------------------------------------------------

::class fblock subclass stage public              -- block data, spanning input records

::method init                                     -- init stage
expose blksize blkplus pad block                  -- block size, pad character and output block
forward class(super) continue
use strict arg specs = ''                         -- specifications

blksize = specs~word(1)
if \blksize~datatype('w') | blksize < 1 then call noGood self~name, 'invalid block size <'blksize'>'

pad = specs~subWord(2)                            -- optional pad character to pad the final block with
if pad = '' then pad = -1
else do
  pad = xorc(pad)                                 -- it must be an XORC
  if pad = .nil then call noGood self~name, 'invalid XORC specified for padding: <'specs~subWord(2)'>'
  end

blkplus = blksize+1
block = ''

::method process
expose blksize blkplus block
use strict arg record                             -- input record

block = block || record                           -- concatenate it to the output block
do while block~length >= blksize                  -- while we can output
  parse var block chunk =(blkplus) block          -- get a chunk of length BLKSIZE
  self~write(chunk)                               -- output it
  end

::method eof                                      -- EOF
expose blksize pad block
if block~length > 0 then do                       -- a block was in progress
  if pad \= -1 then block = block ||,             -- pad to the correct length if requested
    copies(pad,blksize-block~length)
  self~write(block)                               -- emit the final block
  end
self~eof:super                                    -- propagate the EOF

----------------------------------------------------------------------------------------------------------

::class fileAppend subclass stage public          -- append incoming records to a file
-- supported operands: a file name; this stage corresponds to stage >> in CMS Pipelines

::method init                                     -- initialize stage
expose stream                                     -- i/o stream
forward class(super) continue
use strict arg fileName                           -- access file name
stream = .stream~new(fileName)
result = stream~open('W AP')                      -- attempt to open it for append
if result \= 'READY:' then call noGood self~name, 'error <'result'> opening the file'

::method process
expose stream                                     -- stream
use strict arg record                             -- get input record
stream~lineOut(record)                            -- write it to the file
self~write(record)                                -- then to primary out

::method eof
expose stream                                     -- get stream
stream~lineOut()                                  -- close it
drop stream
self~eof:super                                    -- forward the EOF

----------------------------------------------------------------------------------------------------------

::class fileIn subclass stage public              -- send the contents of a file down the pipeline
-- argument is a file name; this stage corresponds to stage < in CMS Pipelines

::method init                                     -- initialization
expose stream                                     -- i/o stream
forward class(super) continue
self~productive = .true                           -- we must run as the first stage in a pipeline
use strict arg fileName                           -- the name of the file to read
stream = .stream~new(fileName)                    -- create a stream object for it

::method begin                                    -- running as a first stage
expose stream                                     -- expose stream
result = stream~open('REA')                       -- open it for input
if result \= 'READY:' then call noGood,           -- failed
  self~name, 'error <'result'> opening the file'
do while stream~lines('n')                        -- while stream not depleted
  self~write(stream~lineIn())                     -- read next line and send it along the pipeline
  end
drop stream                                       -- clean up
self~eof                                          -- and trigger end of file to primary output

::method process                                  -- PROCESS method should never be driven
call noGood self~name, 'too many input streams'

----------------------------------------------------------------------------------------------------------

::class fileOut subclass stage public             -- store input records in a file
-- supported operands: a file name; this stage corresponds to stage > in CMS Pipelines

::method init                                     -- initialize stage
expose stream                                     -- i/o stream
forward class(super) continue
use strict arg fileName                           -- access file name
stream = .stream~new(fileName)
result = stream~open('W REP')                     -- open it for write replace
if result \= 'READY:' then call noGood self~name, 'error <'result'> opening the file'

::method process
expose stream                                     -- stream
use strict arg record                             -- get input record
stream~lineOut(record)                            -- write it to the file
self~write(record)                                -- and to our primary output

::method eof
expose stream                                     -- get stream
stream~lineOut()                                  -- close it
drop stream
self~eof:super

----------------------------------------------------------------------------------------------------------

::class find public subclass stage                -- find using XEDIT logic

::method init                                     -- get FIND pattern (see XEDIT or CMS Pipelines manuals)
expose pattern                                    -- expose it
forward class(super) continue
use strict arg pattern = ''                       -- load it

::method process
expose pattern                                    -- expose pattern
use strict arg record                             -- and access the input record

ok = (record~length >= pattern~length)            -- must be at least as long as the pattern

do i = 1 to pattern~length while ok               -- check all pattern positions
  select case pattern~substr(i,1)
    when ' ' then nop                             -- a blank matches anything
    when '_' then ok = (record~substr(i,1) = '')  -- underscore requires a blank in the data item
    otherwise ok =,                               -- any other character must match identically
      (record~substr(i,1) = pattern~substr(i,1))
    end
  end

if ok then self~write(record)                     -- if pattern matched, send to primary output
else self~write(record,1)                         -- else send to secondary output

----------------------------------------------------------------------------------------------------------

::class gate subclass stage public                -- pass non-primary input until primary input arrives

::method init
expose waitingForInputFromPrimaryInputStream      -- a self-explanatory flag
self~init:super
self~runsOn = ''
waitingForInputFromPrimaryInputStream = .true     -- no primary input received yet

::method process
expose waitingForInputFromPrimaryInputStream
use strict arg record, streamNo = 0               -- the record and the stream it came in on

if waitingForInputFromPrimaryInputStream |,       -- still waiting for input from primary,
  streamNo = 0 then self~write(record)            -- or this IS such, pass the record

if streamNo = 0 then,                             -- primary input
  waitingForInputFromPrimaryInputStream  = .false -- ignore non-primary input from now on

----------------------------------------------------------------------------------------------------------

::class gather subclass stage public              -- copy records from input streams

::method init
expose specs
specs = arg(1)                                    -- specifications
forward class(super) continue

::method ready
expose specs,
  roundRobin,                                     -- round robin operation
  stop,                                           -- EOF count forcing a stop
  range,                                          -- range used with keyword STREAMID
  queue,                                          -- queues
  stream,                                         -- current input stream for round robin
  eof.,                                           -- EOF flags
  completed                                       -- processing complete flag

specs = consume(specs,'STOP',4)                   -- test for keyword STOP

if specs[4] = 1 then do
  roundRobin = .true                              -- this is round robin
  specs = consume(specs,'ANYEOF','ALLEOF')        -- EOF handling
  select case specs[4]
    when 1 then stop = 1                          -- ANYEOF, stop when any stream ends
    when 2 then stop = 0                          -- default is to stop when all streams end
    otherwise do
      stop = specs[2]                             -- a specific number of EOFs is given
      if \stop~datatype('w') | stop < 1 then,
        call noGood self~name, 'invalid STOP operand <'stop'>'
      specs[1] = specs[3]
      end
    end
  end
else do
  specs = consume(specs,'STREAMid',6)             -- test for STREAMID
  if specs[4] = 1 then do
    it = inputRange(specs[1])                     -- primary input record range contains stream number
    if it[1] then do                              -- range is ok
      roundRobin = .false                         -- processing is STREAMID mode
      specs[1] = it[2]                            -- leftover specs
      range = it~section(3)                       -- store the range
      end
    else call noGood self~name, 'invalid input range <'specs[1]'>'
    end
  end

select
  when specs[1] \== '' then call noGood self~name, 'excessive options <'specs[1]'>'
  when self~inStream~items = 0 then call noGood self~name, 'no input streams are connected'
  when \roundRobin & self~inStream[!(0)] = .nil then call noGood self~name,,
    'primary input stream not connected'
  otherwise do                                    -- configuration looks ok
    queue = .array~new                            -- array of input queues
    do i = 1 to self~inStream~last                -- do all input streams
      if self~inStream[i] = .nil then iterate     -- not connected
      queue[i] = .queue~new                       -- connected, create a queue for it
      end
    eof. = .false                                 -- init EOF flags
    stream = 0                                    -- for round robin, start with primary in
    completed = .false                            -- processing has not completed
    end
  end


::method process
expose roundRobin stop range queue stream eof. completed
use strict arg record, streamNo = 0

if completed then return                          -- completed, ignore any further input

queue[!(streamNo)]~queue(record)                  -- queue the input record on the pertinent queue

if roundRobin then do forever                     -- read the input streams round robin
  eofs = 0                                        -- number of EOFs
  do i = 1 to self~inStream~last                  -- test EOFs
    if self~inStream[i] = .nil then iterate       -- not connected
    eofs += eof.i                                 -- keep track of EOFs
    if stop > 0 & eofs >= stop then signal done   -- too many, we're done
    end
  if eofs = self~inStream~items then signal done  -- input streams all exhausted
  if eof.[!(stream)] then record = .nil           -- the stream whose turn it is is at EOF
  else do                                         -- not EOF
    if queue[!(stream)]~size = 0 then return      -- wait for input to arrive on the current stream
    record = queue[!(stream)]~pull                -- get input
    if record = .nil then do                      -- it is the EOF record
      eof.[!(stream)] = .true                     -- set flag
      eofs += 1                                   -- another EOF
      if eofs = self~inStream~items |,            -- all of our streams at EOF
        stop > 0 & eofs >= stop then signal done  -- or STOP threshold is exceeded
      end
    end
  if record = .nil then do                        -- stream is at EOF
    it = next()                                   -- get the stream next in line
    if it = stream then return                    -- that's us again, give up
    stream = it                                   -- next stream
    iterate                                       -- try again with that one
    end
  self~write(record)                              -- ok, output the record
  stream = next()                                 -- move on to next stream
  end
else do forever                                   -- stream to read is given by primary input record
  if queue[!(0)]~size = 0 then return             -- primary input hasn't got data ready
  record = queue[!(0)]~peek                       -- test head of queue
  if record = .nil then signal done               -- EOF message - we cannot proceed any further
  stream = applyRange(range,record)               -- extract desired stream number
  numeric digits 10
  if stream = '' then stream = 0                  -- null string or blanks is interpreted as zero
  else if (\stream~datatype('w') | stream < 0),   -- stream may be specified in binary decimal
    & stream~length = 4 then stream = stream~c2d  -- convert to decimal
  if \stream~datatype('w') | stream < 0 then,     -- verify
    call noGood self~name, 'input stream number '''applyRange(range,record)~c2x'''x invalid'
  if self~inStream[!(stream)] = .nil then call noGood self~name,,
    'input stream '''applyRange(range,record)~c2x'''x not connected'
  numeric digits
  if stream > 0 then do                           -- not primary in
    if queue[!(stream)]~size = 0 then return      -- wait for data to arrive on the stream
    record = queue[!(stream)]~pull                -- get a record from the stream
    if record = .nil then signal done             -- it's the EOF message - can't proceed
    end
  self~write(record)                              -- ok, write the record
  queue[!(0)]~pull                                -- consume line from primary input
  end

next:                                             -- return the next available stream
do i = 1 while i < self~inStream~last             -- we intentionally use < instead of <=
  next = (stream+i)~modulo(self~inStream~last)    -- next stream, wrapping around using MODULO()
  if self~inStream[!(next)] = .nil then iterate   -- disconnected
  if queue[!(next)]~size > 0 | \eof.[!(next)],    -- records queued or no EOF is okay
    then return next
  end
return stream                                     -- no other stream available...

done: completed = .true                           -- set COMPLETED flag
do i = 1 to self~inStream~last                    -- do input streams
  if self~inStream[i] = .nil then iterate         -- disconnected, skip
  queue[i]~empty                                  -- clear queue
  end
drop roundRobin stop range queue stream eof.
self~eof:super
return

::method eof
expose eof. completed
if completed then return                          -- processing completed, ignore
use strict arg streamNo = 0                       -- EOF on an input stream
if \eof.[!(streamNo)] then,
  self~start('process',.nil,streamNo)             -- send a nil record to PROCESS, to handle this EOF

----------------------------------------------------------------------------------------------------------

::class get subclass stage public                 -- GET is a synonym for stage GETFILES below

::method init                                     -- init
expose get
forward class(super) continue
self~runsOn = ''                                  -- no args
get = .getFiles~new                               -- create a GETFILES stage

::method ready                                    -- do some plumbing
expose get                                        -- expose the new stage
if self~inStream[!(0)] \= .nil then do
  get~setInStream(0,self~inStream[!(0)])          -- copy our primary input stream
  self~inStream[!(0)]~setOutStream(0,get,.true)   -- force our input stream to output to the new stage
  end
if self~outStream[!(0)] \= .nil then,
  get~setOutStream(0,self~outStream[!(0)])        -- and output stream
get~alias = 'GET'                                 -- set alias for error messages
get~prepare(self~trace)

----------------------------------------------------------------------------------------------------------

::class getFiles subclass stage public            -- read file names and send their contents into the pipe

::method init                                     -- initialization
forward class(super) continue
self~runsOn = ''                                  -- no arguments

::method process                                  -- process a file
fileName = arg(1)                                 -- the file to read
stream = .stream~new(fileName)                    -- create stream object
result = stream~open('REA')                       -- open it for input
if result \= 'READY:' then call noGood self~name, 'error <'result'> opening file <'fileName'>'
do while stream~lines('n')                        -- while stream not depleted
  self~write(stream~lineIn())                     -- read next line and send it down the pipe
  end
                                              
----------------------------------------------------------------------------------------------------------

::class hole public subclass stage                -- make all input disappear into a hole

::method init                                     -- initialize
forward class(super) continue
self~runsOn = ''                                  -- no arguments defined

::method process                                  -- just ignore any input records

----------------------------------------------------------------------------------------------------------

::class inside public subclass stage              -- pass records strictly between labels

::method init                                     -- initialize
expose specs
forward class(super) continue
specs = arg(1)                                    -- store run-time options

::method ready
expose specs,
  anycase groupStart groupSize groupEnd group     -- controls are as for the BETWEEN stage

if 'ANYCASE'~caselessAbbrev(specs~word(1),3),     -- ANYCASE requested
   then do
  anycase = .true
  specs = specs~subWord(2)                        -- remove keyword
  end
else anycase = .false

it = delimitedString(specs,.false)                -- delimited string must be next
if it = .nil then call noGood self~name, 'invalid delimited string: <'specs'>'
specs = it[1]                                     -- data after the delimited string
groupStart = it[2]                                -- group start label

if specs~datatype('w') & specs > -1 then,         -- a number >= 0
  groupSize = format(specs)                       -- save as maximum group size
else do                                           -- not numeric, another delimited string
  it = delimitedString(specs,.false)              -- retrieve it
  if it = .nil then call noGood self~name,,       -- not valid
    'data not recognized: <'specs'>, specify a number >= 0 or a delimited string'
  specs = it[1]                                   -- remaining data should be blank
  if specs \= '' then call noGood self~name, 'excessive options <'specs'>'
  groupEnd = it[2]                                -- set end label
  groupSize = -1                                  -- group size not in effect
  end

group = .false                                    -- no group in progress

::method process                                  -- process a record
expose anycase groupStart groupSize groupEnd group count
use strict arg record

if group then do                                  -- a group is in progress
  if groupSize < 0 then do                        -- look for end label
    if anycase then group =,                      -- reset GROUP flag when found
      \record~caselessAbbrev(groupEnd)
    else group = \record~abbrev(groupEnd)
    end
  else do                                         -- check whether group size is reached
    count += 1                                    -- increment group count
    if count = groupSize then group = .false      -- size reached, end group
    end
  if group then self~write(record)                -- the group continues, send record to primary out
  else self~write(record,1)                       -- ended, send to secondary out
  end
else do                                           -- no group active
  self~write(record,1)                            -- send to secondary output stream in any case
  if anycase then group =,                        -- start new group if starting label matches
    record~caselessAbbrev(groupStart)
  else group = record~abbrev(groupStart)
  if group & groupsize >= 0 then count = -1       -- initialize group
  end

----------------------------------------------------------------------------------------------------------

::class join subclass stage public                -- join records
-- supported operands: number (of records to join, default is 1), delimitedString

::method init
expose reads,                                     -- number of additional READs to do before we can output
  delim,                                          -- delimiter to put between input records
  buffer,                                         -- a buffer to delay input records in
  count                                           -- input record count
forward class(super) continue
use strict arg specs = ''                         -- get specification
w1 = specs~word(1)                                -- first word, may specify READS

select
  when w1 = '*' then do                           -- join all input records together
    reads = -1
    specs = specs~subWord(2)
    end
  when w1~datatype('w') & w1 >= 0 then do         -- nonnegative integer, assign to READS
    reads = w1
    specs = specs~subWord(2)
    end
  otherwise do
    reads = 1                                     -- default for READS is 1
    specs = specs~strip
    end
  end

if specs == '' then delim = ''                    -- default is no delimiter
else do                                           -- handle delimiter specification
  delim = delimitedString(specs)                  -- it is a delimited string
  if delim = .nil then,                           -- bad show
    call noGood self~name, 'invalid delimited string <'specs'>'
  end

buffer = ''
count = 0

::method process
expose reads buffer delim count

use strict arg record                             -- retrieve input record

if count = 0 then buffer = record                 -- first in batch
else buffer = buffer || delim || record           -- else append to buffer preceded by the delimiter
count += 1                                        -- another line read

if reads < 0 then nop                             -- must join all input records
else if count > reads then do                     -- we have a complete output record
  self~write(buffer)                              -- emit output
  buffer = ''                                     -- reinitialize buffer
  count = 0                                       -- and READ count
  end

::method eof
expose buffer count

if count > 0 then self~write(buffer)              -- we have input to output

buffer = ''

forward class(super)                              -- send the EOF along

----------------------------------------------------------------------------------------------------------

::class juxtapose public subclass stage           -- juxtapose primary records with higher input records

::method init                                     -- initialize
expose buffer count counter eof.                  -- buffer line, COUNT flag, counter, EOF switches
forward class(super) continue
use strict arg specs = ''

count = (specs = 'COUNT')                         -- prefix output with a count
if count & specs~words > 1 |,
  \count & specs~words > 0 then call noGood self~name, 'excessive options <'arg(1)'>'

buffer = .nil
counter = 0                                       -- initialize controls
eof. = .false

::method process
expose buffer count counter
use strict arg record, streamNo = 0               -- access input record and stream

if streamNo = 0 then do                           -- primary input stream
  if buffer \= .nil & counter = 0 then,           -- a line was buffered, but it was never used,
    self~write(buffer,1)                          -- transfer it to secondary output
  buffer = record                                 -- buffer the record
  counter = 0                                     -- init its use count
  end
else do                                           -- higher numbered input stream
  if buffer = .nil then self~write(record)        -- no prior primary input record, output the line
  else do
    counter += 1                                  -- increment the count of higher stream records
    if count then self~write(counter~,            -- output the record, prefixed with count and buffer
      right(10) || buffer || record)              -- (count is 10 bytes, right aligned)
    else self~write(buffer || record)             -- or just prefixed with buffer
    end
  end

::method eof
expose buffer counter eof.
use strict arg streamNo = 0
eof.[!(streamNo)] = .true                         -- set flag

do i = 1 to self~inStream~last                    -- check that all connected instreams had EOF
  if self~inStream[i] \= .nil & \eof.i then return-- this one hasn't, return
  end

if buffer \= .nil & counter = 0 then,             -- primary input record buffered and never used
  self~write(buffer,1)                            -- send to secondary output
self~eof:super

----------------------------------------------------------------------------------------------------------

::class literal public subclass stage             -- preface a header record

::method init                                     -- retrieve header
expose header doHeader                            -- expose header and write-header flag
forward class(super) continue                     -- init superclass first
self~productive = .true                           -- we can run as first stage in pipelines
use strict arg header = ''                        -- retrieve header line
doHeader = .true                                  -- must output header

::method begin                                    -- running first in a pipeline
self~eof                                          -- just signal end-of-data

::method process
expose header doHeader                            -- expose attributes
if doHeader then do
  self~write(header)                              -- send out header first
  doHeader = .false
  end
forward class(super)                              -- propagate the PROCESS message

::method eof
expose header doHeader                            -- expose
if doHeader then do                               -- header not written yet
  self~write(header)                              -- emit it after all
  doHeader = .false
  end
forward class(super)                              -- propagate the EOF

----------------------------------------------------------------------------------------------------------

::class locate public subclass stage              -- locate data or an input position
-- supported operands: ANYCASE, inputRanges, ANYOF, delimitedString

::method init
expose anycase,                                   -- case irrelevant flag
  ranges,                                         -- input record ranges to scan
  anyof,                                          -- locate string characters rather than entire string
  string                                          -- the search string
forward class(super) continue

specs = consume(arg(1),'ANYCase')                 -- test if ANYCASE is specified
anycase = specs[4] = 1                            -- set flag when so

ranges = .array~new(10)                           -- array of up to 10 ranges, each itself an array
ranges[1] = .array~of('1,-1')                     -- default range is *-*, the complete record

if specs[1]~abbrev('(') then do                   -- up to 10 ranges between parentheses
  parse value specs[1] with '(' list ')' rest     -- get the list
  do i = 1 while list \= ''
    if i = 11 then call noGood self~name, 'more than 10 input ranges specified between the parentheses'
    it = inputRange(list)                         -- determine next range
    if it[1] then do                              -- was ok
      list = it[2]                                -- rest of the list
      ranges[i] = it~section(3)                   -- ok, store range
      end
    else call noGood self~name, 'invalid input range <'list'>'
    end
  if i = 1 then call noGood self~name, 'specify between 1 and 10 input ranges between the parentheses'
  specs = consume(rest)                           -- any remaining specifications
  end
else if specs[1] \== '' then do                   -- not a list
  it = inputRange(specs[1])                       -- a single input range may be given
  if it[1] then do                                -- yes
    specs = it[2]                                 -- remainder of input
    ranges[1] = it~section(3)                     -- save range
    end
  end

specs = consume(specs,'ANYof')                    -- ANYOF?
anyof = specs[4] = 1                              -- if so, set flag

if specs[1] == '' then string = ''                -- no search string
else do                                           -- search string given as a delimited string
  string = delimitedString(specs[1])              -- extract string
  if string = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
  end

if anyof & anycase then string =,                 -- search string both in lower and in uppercase
  string~lower || string~upper

::method process
expose anycase ranges anyof string
use strict arg record                             -- get input record

ok = .false                                       -- assume the locate fails

do range over ranges while \ok                    -- all requested ranges
  range = applyRange(range,record)                -- apply range to record
  if range \== '' then do                         -- data found in range
    if string == '' then ok = .true               -- no search string specified and the range exists
    else select                                   -- find search string
      when anyof then ok =,                       -- ANYOF, need any character in STRING
        range~verify(string,'m') > 0
      when anycase then ok =,                     -- need entire search string, disregarding case
        range~caselessContains(string)
      otherwise ok = range~contains(string)       -- we need an exact copy of the search string
      end
    end
  end

if ok then self~write(record)                     -- if pattern matched, then relay to primary output
else self~write(record,1)                         -- else to the secondary outstream

----------------------------------------------------------------------------------------------------------

::class lookup public subclass stage              -- look up record (key) in a reference data set
-- supported operands: COUNT, (NO)PAD, ANYCASE, AUTOADD [BEFORE], KEYONLY,
-- [inputRange [inputRange]], [DETAIL [MASTER] | MASTER [DETAIL]]

::method init                                     -- interpret parms
expose count,                                     -- keep track of master key usage
  pad,                                            -- pad character
  anycase,                                        -- caseless key compare
  autoAdd,                                        -- add unknown keys to reference
  before,                                         -- add before comparing
  keyOnly,                                        -- save master records' keys only
  detailKey,                                      -- key location in detail records
  masterKey,                                      -- ditto for master records
  output,                                         -- output detail, master, or both
  detailKeyLen,                                   -- used with PAD
  masterKeyLen,                                   -- ditto
  masterKeys,                                     -- array of master keys
  master.,                                        -- reference stem
  eof.,                                           -- EOF flags
  buffer.,                                        -- buffer for detail records while not ready
  use.                                            -- use count per master key
forward class(super) continue

parsed = parseForLookupOrCollate(self~name,arg(1))-- parse specifications

count = parsed[1]                                 -- store parser's findings
pad = parsed[2]
anycase = parsed[3]
detailKey = parsed[4]
masterKey = parsed[5]
output = parsed[6]
detailKeyLen = parsed[7]
masterKeyLen = parsed[8]
autoadd = parsed[9]
before = parsed[10]
keyonly = parsed[11]

masterKeys = .array~new                           -- an array holding the master keys
master. = .nil                                    -- initialize the reference data set
eof. = .false                                     -- no input streams are at EOF
buffer.0 = 0                                      -- no detail records are buffered
use. = 0                                          -- no master keys used yet


::method ready
if self~inStream[2] = .nil then call noGood self~name, 'secondary input stream not connected'
if self~inStream~items > 2 then call noGood self~name, 'too many input streams connected'


::method process
expose count pad anycase autoAdd before keyOnly detailKey masterKey,
  output detailKeyLen masterKeyLen masterKeys master. eof. buffer. use.

use strict arg record, streamNo = 0               -- a record has arrived on either stream

if streamNo = 1 then do                           -- secondary input stream: a master record
  if checkMaster(record) then return              -- it already exists in the reference
  if keyOnly then master.key = originalKey        -- no need to keep the entire master
  else master.key = item                          -- store the master record
  masterKeys~append(key)                          -- and save its key
  return                                          -- done
  end

if streamNo = -1 then do                          -- all streams at EOF, but lines are buffered
  call emptyBuffer                                -- process buffered lines
  self~eof(-1)                                    -- send "EOF on stream -1"
  return
  end

if \eof.1 then do                                 -- not ready for primary input
  buffer.0 += 1
  buffer.[buffer.0] = record                      -- buffer the record
  return
  end

if buffer.0 > 0 then call emptyBuffer             -- process any buffered items first

call process(record)                              -- then process the record itself
return

emptyBuffer:
do i = 1 to buffer.0
  call process(buffer.i)                          -- process the buffered items
  end
drop buffer.
buffer.0 = 0
return

process: use arg item                             -- process a detail record
it = lookUpMaster(item)                           -- retrieve matching master record key
if \it[1] then do label noMaster                  -- match failed
  if autoAdd then do                              -- add new master
    key = it[2]                                   -- detail record key, unedited
    call addMaster                                -- add master
    use.key = before                              -- this key now used 0 or 1 times
    if before then leave noMaster                 -- "matched after all", fall thru
    end
  self~write(item,1)                              -- send item to secondary out
  return                                          -- and return
  end noMaster
else use.key += 1                                 -- matched, master key used once again
do w = 1 to output~words                          -- output requested data items
  if output~word(w) = 'DETAIL' then,
    self~write(item)                              -- write detail record to primary out
  else self~write(master.key)                     -- else send matching master thither; NOTE:
  end                                             -- KEY variable set by LOOKUPMASTER or ADDMASTER,
return                                            -- admittedly dirty...

checkMaster: use arg item                         -- check whether master already exists
key = applyRange(masterKey,item)                  -- extract master key
originalKey = key                                 -- remember the unedited key
if pad \= -1 then if key~length < masterKeyLen,   -- padding requested
  then key = key ||,
  copies(pad,masterKeyLen-key~length)             -- pad to the right length
if anycase then key = key~upper                   -- uppercase key when ANYCASE holds
return (master.key \= .nil)                       -- return "master exists" flag

lookUpMaster: use arg item                        -- find the master for a detail record
master = .array~new(2)                            -- array to return
key = applyRange(detailKey,item)                  -- locate detail key
master[2] = key                                   -- save it at index 2
if pad \= -1 then if key~length < detailKeyLen,   -- PAD in effect
  then key = key ||,
  copies(pad,detailKeyLen-key~length)             -- append pad characters until length is correct
if anycase then key = key~upper                   -- ANYCASE, uppercase the key
master[1] = (master.key \= .nil)                  -- store "master exists" flag at index one
return master

addMaster:                                        -- insert a new master record in the reference
originalKey = key                                 -- save original key
if pad \= -1 then if key~length < masterKeyLen,   -- padding needed
  then key = key ||,
  copies(pad,masterKeyLen-key~length)             -- pad to get the correct length
if anycase then key = key~upper                   -- uppercase key if ANYCASE holds
if keyOnly then master.key = originalKey          -- no need to keep the entire master
else master.key = item                            -- store the master record
masterKeys~append(key)                            -- save key
return


::method eof
expose count masterKeys master. eof. buffer. use.
use strict arg streamNo = 0                       -- number of the input stream that is at EOF

eof.streamNo = .true                              -- set its EOF flag

if eof.0 & eof.1 then do                          -- both input streams now at EOF
  if buffer.0 > 0 then do                         -- but records are still buffered
    self~process(.nil,-1)                         -- send a message "on stream -1"
    return
    end
  if count then do key over masterKeys            -- COUNT requested, output to tertiary out
    self~write(use.key~right(10)master.key,2)     -- output all masters prefixed with use count
    end
  else do key over masterKeys
    if use.key = 0 then self~write(master.key,2)  -- emit only unused master records - without count
    end
  drop count masterKeys master. eof. use.
  self~eof:super                                  -- all done, signal EOF to the underlying stage object
  end

----------------------------------------------------------------------------------------------------------

::routine parseForLookupOrCollate                 -- common parser for the LOOKUP and COLLATE stages

use strict arg name, specs                        -- name of calling stage, string to parse
lookup = name~abbrev('LOOK')                      -- set flag indicating parsing is for LOOKUP
results = .array~new                              -- array of results

if lookup then do
  specs = consume(specs,'COUNT')                  -- LOOKUP, start with the COUNT keyword
  count = specs[4] = 1                            -- set flag if specified
  end
else do                                           -- COLLATE, try STOP
  specs = consume(specs,'STOP')
  stop = specs[4] = 1                             -- flag if specified
  if stop then do                                 -- ANYEOF is mandatory next
    specs = consume(specs,'ANYEOF')
    if specs[4] = 0 then call name, 'invalid STOP parameter <'specs[2]'>'
    end
  end

specs = consume(specs,'NOPAD','PAD')              -- NOPAD or PAD
if specs[4] = 2 then do                           -- PAD
  pad = xorc(specs[2])                            -- need a pad character given by an XORC
  if pad = .nil then call name, 'invalid pad character <'specs[2]'>'
  specs[1] = specs[3]                             -- consume the XORC
  end
else pad = -1                                     -- NOPAD specified or defaulted: don't pad short keys

specs = consume(specs,'ANYcase')                  -- ANYCASE
anycase = specs[4] = 1                            -- if specified, we'll ignore case when comparing keys

if lookup then do                                 -- for LOOKUP,
  specs = consume(specs,'AUTOADD')                -- test AUTOADD
  autoAdd = specs[4] = 1
  if autoAdd then do                              -- automatically (??) add unknown keys
    specs = consume(specs,'BEFORE')
    before = specs[4] = 1                         -- cheating: add unknown keys before matching them
    end
  specs = consume(specs,'KEYONLY')                -- KEYONLY
  keyOnly = specs[4] = 1                          -- keep master records' keys only
  end

it = inputRange(specs[1])                         -- one or two input ranges may be next

if it[1] then do                                  -- range ok
  specs = it[2]                                   -- consume the range specification
  detailKey = it~section(3)                       -- store details' key
  detCheck = checkKey(detailKey)                  -- and check it for separators and fixed length
  it = inputRange(specs)                          -- fetch another input range
  if it[1] then do                                -- okay
    specs = it[2]                                 -- consume specification
    masterKey = it~section(3)                     -- save master key
    mstCheck = checkKey(masterKey)                -- check key
    if mstCheck[1] = .nil then do                 -- no field separator present
      if detCheck[1] \= .nil then index =,        -- while the detail key has one
        masterKey~insert(detCheck[1],.nil)        -- copy separator from detail key; index = 1
      else index = .nil                           -- set index for the next INSERT to .NIL
      end
    else index = 1                                -- field separator already present
    if mstCheck[2] = .nil & detCheck[2] \= .nil,  -- no word separator, while detail key has one
      then masterKey~insert(detCheck[2],index)    -- copy from detail key
    if lookup then if autoAdd &,                  -- LOOKUP with AUTOADD
      masterKey~makestring(,'.') \=,
      detailKey~makestring(,'.') then,            -- key must agree with details' key
      call noGood name, 'with AUTOADD, the master key should be identical to the detail key'
    end
  else do
    masterKey = detailKey                         -- master key defaults to detail key
    mstCheck = detCheck
    end
  specs = consume(specs)                          -- set WORD(1) and SUBWORD(2)
  end
else do                                           -- default for both is the entire record
  detailKey = .array~of('1,-1')
  masterKey = detailKey
  detCheck = checkKey(detailKey)
  mstCheck = detCheck
  end

if lookup & pad \= -1 then do                     -- PAD in effect, do a check for LOOKUP
  unsupported = .true                             -- we don't do binary searches
  if detCheck[3] \== '' then do                   -- word and field ranges are not fixed length
    parse value detCheck[3] with from to .        -- ok, get FROM and TO
    detailKeyLen = to-from+(sign(from)=sign(to))  -- okay, store fixed length of details key
    if mstCheck[3] \== '' then do                 -- ordinary range
      parse value mstCheck[3] with from to .      -- get FROM and TO
      masterKeyLen = to-from+(sign(from)=sign(to))-- master key's fixed length
      if masterKeyLen \= detailKeyLen then,       -- issue a warning when lengths differ
        say name': warning, key lengths differ; detail records will never match...'
      unsupported = .false                        -- all right, reset flag
      end
    end
  if unsupported then call noGood name,,          -- alas...
    'PAD is supported only in combination with fixed length keys'
  end

dm = 'DETAIL MASTER'                              -- determine what to output and in which order
i = dm~caselessWordPos(specs[2])

if i = 0 then do                                  -- not specified
  if lookup then output = dm                      -- default is: output DETAIL, followed by MASTER
  else output = dm~word(2) dm~word(1)             -- for COLLATE it is MASTER first, then DETAIL
  end
else do                                           -- DETAIL or MASTER was specified
  output = specs[2]~upper                         -- save
  specs = consume(specs[3])                       -- remove WORD(1)
  if specs[2] \== '' then do                      -- there was a second output specification
    j = dm~caselessWordPos(specs[2])              -- look up next keyword in string DM
    if i+j = 3 then do                            -- it is the first keyword's alternative
      output = output specs[2]~upper              -- add it
      specs[1] = specs[3]                         -- consume
      end
    else signal problem                           -- keyword specified twice or not recognized
    end
  end

if specs[1] == '' then do                         -- ok, no more input
  if lookup then results[1] = count               -- store findings
  else results[1] = stop
  results[2] = pad
  results[3] = anycase
  results[4] = detailKey
  results[5] = masterKey
  results[6] = output
  if lookup then do                               -- options specific to LOOKUP
    results[7] = detailKeyLen
    results[8] = masterKeyLen
    results[9] = autoadd
    results[10] = before
    results[11] = keyonly
    end
  return results                                  -- return the results
  end

problem: call noGood name, 'excessive options <'specs[1]'>'

checkKey:                                         -- check a key for separators and fixed length
check = .array~new                                -- results array
do i = 1 to arg(1)~items                          -- do all range items the key consists of
  rangeItem = arg(1)[i]
  select
    when rangeItem~abbrev('FS') then,             -- field separator
      check[1] = rangeItem                        -- save in CHECK[1]
    when rangeItem~abbrev('WS') then,             -- a word separator
      check[2] = rangeItem                        -- store in CHECK[2]
    when rangeItem = 'SUB' then do                -- SUBSTR
      check[3] = ''                               -- range considered to be not of fixed length
      return check                                -- ignore WS/FS that belong to the SUB
      end
    otherwise do                                  -- neither a separator nor SUBSTR
      parse var rangeItem from ',' to             -- FROM and TO values for the range
      if from~datatype('w') & from <= to then,    -- not a word range or a field range and FROM <= TO
        check[3] = from to                        -- save FROM and TO
      else check[3] = ''                          -- not of fixed length
      end
    end
  end
return check                                      -- return findings

----------------------------------------------------------------------------------------------------------

::class nfind public subclass stage               -- converse of FIND

::method init                                     -- get the FIND pattern
expose match                                      -- expose it
forward class(super) continue
use strict arg pattern = ''                       -- and load it

::method process
expose pattern                                    -- expose the pattern
use strict arg record                             -- access the data item

ok = (record~length >= pattern~length)            -- must be at least as long as the pattern

do i = 1 to pattern~length while ok               -- check all pattern positions
  select case pattern~substr(i,1)
    when ' ' then nop                             -- a blank matches anything
  when '_' then ok =,                             -- underscore requires a blank in the data item
     (record~substr(i,1) = '')
  otherwise ok =,                                 -- any other character must match identically
     (record~substr(i,1) = pattern~substr(i,1))
  end
  end

if ok then self~write(record,1)                   -- if pattern matched, send to secondary output
else self~write(record)                           -- else send to primary output

----------------------------------------------------------------------------------------------------------

::class nlocate public subclass stage             -- converse of LOCATE
-- supported operands: ANYCASE, inputRanges, ANYOF, delimitedString

::method init                                     -- do a NOT LOCATE
expose it                                         -- the LOCATE instance we are about to create
forward class(super) continue
interpret 'it = .locate['self~runsOn']'           -- create the LOCATE

::method ready
expose it                                         -- the LOCATE instance created aerlier
if self~inStream[!(0)] \= .nil then do
  it~setInStream(0,self~inStream[!(0)])           -- replumbing: our input stream is input for LOCATE
  self~inStream[!(0)]~setOutStream(0,it,.true)    -- force our input stream to output to LOCATE
  end
if self~outStream[!(1)] \= .nil then,
  it~setOutStream(0,self~outStream[!(1)])         -- the stage's primary out is our secondary out
if self~outStream[!(0)] \= .nil then,
  it~setOutStream(1,self~outStream[!(0)])         -- stage's secondary out is our primary output
it~alias = 'NLOCATE'                              -- alias for error messages
it~prepare(self~trace)

----------------------------------------------------------------------------------------------------------

::class not public subclass stage                 -- swap a stage's primary and secondary output streams

::method init                                     -- init
expose it                                         -- a stage instance
self~init:super
use strict arg it = .nil                          -- the stage to negate
self~runsOn = it~name
if \it~isA(.stage) then call noGood self~name, 'argument must be a stage instance, found <'it'>'

::method ready
expose it                                         -- the stage instance we are negating
if self~inStream[!(0)] \= .nil then do
  it~setInStream(0,self~inStream[!(0)])           -- replumbing: our input stream is input for the stage
  self~inStream[!(0)]~setOutStream(0,it,.true)    -- force our input stream to output to IT
  end
if self~outStream[!(1)] \= .nil then,
  it~setOutStream(0,self~outStream[!(1)])         -- stage's primary out is our 2ary out (if we have one)
if self~outStream[!(0)] \= .nil then,
  it~setOutStream(1,self~outStream[!(0)])         -- and stage's secondary out is our primary out
it~alias = 'NOT' it~name                          -- adapt name
it~prepare(self~trace)                            -- prepare stage for operation

----------------------------------------------------------------------------------------------------------

::class notinside public subclass stage           -- the converse of INSIDE

::method init                                     -- treat as NOT INSIDE
expose it                                         -- an INSIDE instance
forward class(super) continue
interpret 'it = .inside['self~runsOn']'           -- create an INSIDE stage

::method ready
expose it                                         -- the INSIDE instance
if self~inStream[!(0)] \= .nil then do
  it~setInStream(0,self~inStream[!(0)])           -- replumbing: our input stream is input for INSIDE
  self~inStream[!(0)]~setOutStream(0,it,.true)    -- force our input stream to output to INSIDE
  end
if self~outStream[!(1)] \= .nil then,
  it~setOutStream(0,self~outStream[!(1)])         -- stage's primary out is our 2ary out
if self~outStream[!(0)] \= .nil then,
  it~setOutStream(1,self~outStream[!(0)])         -- and stage's secondary out is our primary out
it~alias = 'NOTINSIDE'                            -- alias for error messages
it~prepare(self~trace)

----------------------------------------------------------------------------------------------------------

::class outside public subclass stage             -- pass records not between labels, including the labels

::method init                                     -- simulate NOT BETWEEN
expose it                                         -- the BETWEEN instance
forward class(super) continue
interpret 'it = .between['self~runsOn']'          -- create a BETWEEN stage

::method ready
expose it                                         -- the BETWEEN stage
if self~inStream[!(0)] \= .nil then do
  it~setInStream(0,self~inStream[!(0)])           -- replumbing: our input stream is input for the stage
  self~inStream[!(0)]~setOutStream(0,it,.true)    -- force our input stream's output stream to BETWEEN
  end
if self~outStream[!(1)] \= .nil then,
  it~setOutStream(0,self~outStream[!(1)])         -- stage's primary out is our 2ary out (if connected)
if self~outStream[!(0)] \= .nil then,
  it~setOutStream(1,self~outStream[!(0)])         -- and stage's secondary out is our primary out
it~alias = 'OUTINSIDE'                            -- alias for error messages
it~prepare(self~trace)

----------------------------------------------------------------------------------------------------------

::class overlay public subclass stage             -- overlay data from input streams

::method init                                     -- initialization
expose pad                                        -- padding character
forward class(super) continue
use strict arg specs = ''

select
  when specs = '' then pad = ' '                  -- the default pad character is a blank
  when specs~words = 1 then do
    pad = xorc(specs~word(1))                     -- character must be given as an XORC
    if pad = .nil then call noGood self~name, 'invalid XORC <'specs'>'
    end
  otherwise call noGood self~name, 'excessive options'
  end

::method ready
expose queue  eof.
queue = .array~new                                -- queues for the input streams
do i = 1 to self~inStream~last
  if self~inStream[i] = .nil then iterate         -- this one not connected
  queue[i] = .queue~new                           -- connected, create a queue for it
  end
eof. = .false                                     -- init EOF flags

::method process
expose pad queue eof.
use strict arg record, streamNo = 0

queue[!(streamNo)]~queue(record)                  -- queue incoming record

do forever
  eofs = 0                                        -- # of input streams that have finished
  do i = 1 to self~inStream~last                  -- check streams
    if self~inStream[i] = .nil then iterate
    if eof.i then eofs += 1                       -- this one is at EOF
    else do
      if queue[i]~size = 0 then return            -- no input, wait for some
      item = queue[i]~peek                        -- head of the queue
      if item = .nil then do                      -- an EOF message
        eof.i = .true
        eofs += 1                                 -- keep track
        queue[i]~pull                             -- discard EOF message
        end
      end
    if eof.i then item = ''                       -- stream at EOF, treat as a null record coming in
    current.i = item                              -- current item for this stream
    end
  if eofs = self~inStream~items then do           -- all streams are at EOF
    self~eof:super                                -- trigger superclass's EOF method
    return                                        -- all done
    end
  output = ''                                     -- initialize the output buffer
  do i = 1 to self~inStream~last                  -- all input streams
    if self~inStream[i] = .nil then iterate
    item = current.i                              -- load the current item for this stream
    j = 1                                         -- set to first ITEM position
    do while j > 0 & j <= item~length             -- find next substring of ITEM to overlay OUTPUT with
      k = item~pos(pad,j)                         -- get next pad character position
      if k > 0 then do                            -- found one
        output = output~,
          overlay(item~substr(j,k-j),j)           -- overlay OUTPUT with a section of ITEM
        j = k+1                                   -- position after the PAD
        end
      else do                                     -- not found
        output = output~,
          overlay(item~substr(j),j)               -- overlay OUTPUT with ITEM substring that starts at J
        j = 0                                     -- this stream done
        end
      end
    end
  self~write(output)                              -- output the resulting line
  do i = 1 to self~inStream~last                  -- consume the items used
    if self~inStream[i] = .nil then iterate
    if \eof.i then queue[i]~pull                  -- pop queue heads
    end
  end

::method eof
expose eof.
use strict arg streamNo = 0                       -- EOF on an input stream

if \eof.[!(streamNo)] then,                       -- if its EOF flag is off,
  self~process(.nil,streamNo)                     -- send an EOF message to PROCESS
  
----------------------------------------------------------------------------------------------------------

::class pad public subclass stage                 -- pad data to a specified minimum length
-- operands not supported: MODULO

::method init                                     -- initialization
expose right length pad                           -- RIGHT flag, minimum length, padding character
forward class(super) continue

specs = consume(arg(1),'RIGHT','LEFT')            -- look for keyword RIGHT or LEFT
right = specs[4] \= 2                             -- padding on the right is the default

if \specs[2]~datatype('w') | specs[2] < 0 then call noGood self~name, 'invalid minimum length <'specs[2]'>'
length = specs[2]                                 -- a valid length was specified

if specs[3] == '' then pad = ' '                  -- the default pad character is a blank
else do
  pad = xorc(specs[3])                            -- padding character is given as an XORC
  if pad = .nil then call noGood self~name, 'invalid pad character <'specs[3]'>'
  end

::method process
expose right length pad
use strict arg record                             -- retrieve record
if record~length < length then do                 -- pad shorter items
  if right then record = record~left(length,pad)  -- on the right
  else record = record~right(length,pad)          -- or on the left
  end
self~write(record)                                -- output the padded item

----------------------------------------------------------------------------------------------------------

::class pick public subclass stage                -- select lines that satisfy a relation
--
-- supported syntax: [NOPAD | [PAD xorc]] [ANYCASE] formula
-- "formula" is a formula of the propositional calculus that has as atoms all strings of the form:
--   operand1 operator operand2
-- where "operand1" is an INPUTRANGE, "operator" is one of == \== ¬== << <<= >> >>=, and "operand2" is
-- either another INPUTRANGE or a DELIMITEDSTRING
--
-- formulas are defined as follows:
--   every atom is a formula
--   if F is a formula, then so are \F and its synonym ¬F (negation)
--   if F and G are formulas, then so are F&G (conjunction) and F|G and its synonym F!G (disjunction)
--   nothing else is a formula
--
-- blanks are ignored before and after operators and the connectives \, ¬, &, | and !
-- AND (symbol &) takes precedence over OR (| or !), but you may place formulas between parentheses;
-- for example: .pick['3.3 == /abc/ & (w1 << w2 | w3 = //)'] will select a record if it has "abc" in
-- positions 3-5, and either its first word is strictly smaller (as a string) than its second word,
-- or the record consists of less than two words (its third word is null), or both
--
-- parentheses are required for formulas following a negation symbol (\ or its equivalent ¬)
--
-- an input record is selected if and only if the formula, applied to the record, evaluates to TRUE
--
-- the syntax is a subset of what CMS Pipelines stage PICK supports, except that we support negation

::method init                                     -- initialization
expose pad anycase node type. child.
forward class(super) continue

specs = consume(arg(1),'NOPAD','PAD')             -- look for keyword NOPAD or PAD
if specs[4] = 2 then do                           -- PAD specified
  pad = xorc(specs[2])                            -- pad character is given as an XORC
  if pad = .nil then call noGood self~name, 'invalid pad character <'specs[2]'>'
  specs = specs[3]                                -- rest of the specs
  end
else pad = -1                                     -- no padding required

specs = consume(specs,'ANYcase')                  -- ANYCASE may be specified
anycase = specs[4] = 1                            -- for caseless operation

parsed = parseForPickAndAll(self~name,specs[1])   -- remaining instructions parsed by parseForPickAndAll
node = parsed[1]                                  -- the main node
type. = parsed[2]                                 -- node types stem
child. = parsed[3]                                -- children stem

::method process
expose pad anycase node type. child.
use strict arg record
if evaluate(node) then self~write(record)         -- accept record if it passes the tests
else self~write(record,1)                         -- else reject it
return

evaluate: procedure,                              -- evaluate the logical value of a node
  expose record pad anycase type. child.          -- expose controls
arg node                                          -- the node to evaluate
select case type.node                             -- result depends on node type
  when '|' then do                                -- a disjunction
    it = .false                                   -- prime the result to FALSE
    do i = 1 to child.node.0                      -- do each child node
      it = it | evaluate(child.node.i)            -- evaluate and OR it in
      end
    return it                                     -- return the result
    end
  when '&' then do                                -- a conjunction
    it = .true                                    -- prime the result to TRUE
    do i = 1 to child.node.0                      -- do all children
      it = it & evaluate(child.node.i)            -- evaluate child and AND it in
      end
    return it                                     -- return the truth value
    end
  when '\' then return \evaluate(child.node.1)    -- negation, negate the evaluation of its subnode
  otherwise do                                    -- a test, perform it
    operand1 = applyRange(child.node.1,record)    -- first operand is an input range
    operator = child.node.2                       -- operator
    if child.node.3 then operand2 =,              -- second operand is another range
      applyRange(child.node.4,record)             -- fetch it
    else operand2 = child.node.4                  -- else it is a literal string
    if pad \= -1 then do                          -- PAD is in effect
      len1 = operand1~length
      len2 = operand2~length                      -- operand lengths
      select
        when len1 < len2 then operand1 =,         -- first operand is shorter
          operand1 || copies(pad,len2-len1)       -- pad it
        when len1 > len2 then operand2 =,         -- second operand is shorter
          operand2 || copies(pad,len1-len2)
        otherwise nop                             -- lengths agree
        end
      end
    if anycase then do                            -- ignore case
      it = .CaselessComparator~new~,              -- caselessly compare the operands
        compare(operand1,operand2)
      select case operator                        -- process the comparison result, depending on operator
        when '==' then return it = 0              -- operands are equal if the comparison returned 0
        when '\==', '¬==' then return it \= 0
        when '<<' then return it = -1             -- first operand is smaller if -1 was returned
        when '<<=' then return it \= 1
        when '>>' then return it = 1              -- the second operand is smaller if 1 was returned
        otherwise return it \= -1                 -- otherwise the operator is >>=
        end
      end
    else interpret 'return',                      -- else compare respecting case, and return the result
      'operand1' operator 'operand2'
    end
  end

----------------------------------------------------------------------------------------------------------

::routine parseForPickAndAll                      -- common parsing for the PICK and ALL stages

use strict arg name, specs                        -- name of calling stage, string to parse
pick = name~abbrev('PICK')                        -- set flag indicating parsing relates to PICK
results = .array~new                              -- array of results
if pick then validOperators =,                    -- operators valid for PICK
  '== \== ¬== <<= << >>= >>'                      -- <<= should precede << here, same for >>= and >>
list = 'name specs pos nodenum lookAhead',        -- list of variables to expose in local subroutines
  'type. child. pick validOperators'
nodenum = 0                                       -- no nodes yet
pos = 0                                           -- current position in SPECS string

lookAhead = nextLexeme()                          -- start at the first token

if lookAhead = -1 then,                           -- none detected
  call noGood name, 'no template specified'

node = disjunction()                              -- main node must be a disjunction, determine it

if lookAhead \= -1 then,                          -- extraneous data
  call noGood name, 'extraneous data <'specs~substr(pos)'>'

results[1] = node
results[2] = type.                                -- store the results
results[3] = child.
return results                                    -- and return them

display: procedure expose (list)                  -- recursively display a node
arg n                                             -- node to display
it = ''                                           -- initialize result
select case type.n                                -- act depending on type
  when '|' then do                                -- disjunction
    do i = 1 to child.n.0                         -- do all child nodes
      if i > 1 then it = it'|'                    -- not the first child, append an OR
      it = it || display(child.n.i)               -- append the child
      end
    return '('it')'                               -- surround by parentheses
    end
  when '&' then do                                -- case of a conjunction
    do i = 1 to child.n.0                         -- all children
      if i > 1 then it = it'&'                    -- append AND when not the first child
      it = it || display(child.n.i)               -- then append child
      end
    return it                                     -- return display value
    end
  when '\' then,                                  -- a negation
    return '\('display(child.n.1)')'              -- return negated child node
  otherwise return '/'child.n.1'/'                -- a literal, present it as a delimited string
  end

disjunction: procedure expose (list)              -- return a disjunction
i = 0                                             -- initialize the number of child nodes
do forever
  it = conjunction()                              -- every child must be a conjunction
  i += 1                                          -- ok, determined another child
  kid.i = it                                      -- store it in the KID. stem
  if '!|'~pos(lookAhead) > 0 then,                -- ! or | means that another conjunct is forthcoming
    parse value match(lookAhead) with .           -- so consume operator and iterate
  else do                                         -- end of disjuncts
    if i = 1 then return it                       -- disjunction consists of a single conjunction
    nodenum += 1                                  -- else make a new node for this disjunction
    type.nodenum = '|'                            -- its type is "a disjunction"
    child.nodenum.0 = i                           -- store number of its children
    do i = 1 to child.nodenum.0
      child.nodenum.i = kid.i                     -- save the children
      end
    return nodenum                                -- return the new node number
    end
  end

conjunction: procedure expose (list)              -- get a conjunction
i = 0                                             -- no child nodes yet
do forever
  it = factor()                                   -- next child
  i += 1                                          -- another child
  kid.i = it                                      -- store into KID. stem
  if lookAhead = '&' then,                        -- more children underway
    parse value match(lookAhead) with .           -- consume the ampersand and continue
  else do                                         -- end of factors
    if i = 1 then return it                       -- conjunction consists of a single factor, return it
    nodenum += 1                                  -- new node for this conjunction
    type.nodenum = '&'                            -- type is "conjunction"
    child.nodenum.0 = i                           -- set number of child nodes
    do i = 1 to child.nodenum.0
      child.nodenum.i = kid.i                     -- store subordinate nodes
      end
    return nodenum                                -- return node number
    end
  end

factor: procedure expose (list)                   -- get a conjunct
select case lookAhead                             -- inspect character under cursor
  when -1 then call noGood name, 'unexpected end of template'
  when '\', '¬' then do                           -- symbol signifying logical NOT
    connective = lookAhead                        -- save connective
    parse value match(lookAhead) with .           -- consume it
    if pick & lookAhead \= '(' then call noGood,  -- for PICK, the negandum must be parenthesized
      name, 'opening parenthesis expected after connective <'connective'>, found <'specs~substr(pos)'>'
    it = factor()                                 -- get factor to be negated
    nodenum += 1                                  -- create a new node
    type.nodenum = '\'                            -- of type "negation"
    child.nodenum.0 = 1                           -- single child
    child.nodenum.1 = it                          -- viz. the negated node
    end
  when '(' then do                                -- a parenthesized expression
    parse value match(lookAhead) with .           -- match the "("
    it = disjunction()                            -- obtain a disjunction node
    if \match(')') then,                          -- need a ")" now
      call noGood name, 'missing closing parenthesis'
    return it                                     -- okay, return disjunction node
    end
  when '!', '|', '&' then,                        -- unexpected OR or AND symbol
    call noGood name, lookAhead 'left operand missing'
  when ')' then,                                  -- ")" uncalled for
    call noGood name, 'missing opening parenthesis'
  otherwise do
    if pick then do                               -- this is for PICK
      it = inputRange(specs~substr(pos))          -- expecting an input range next
      if \it[1] then call noGood name, 'invalid input range <'specs~substr(pos)'>'
      specs = it[2]                               -- get input remainder
      if specs == '' then call noGood name, 'operator missing'
      nodenum += 1                                -- literal, create a new node
      type.nodenum = 'T'                          -- type is "test"
      child.nodenum.0 = 3                         -- 3 children: range, operator, rangeOrLiteral
      child.nodenum.1 = it~section(3)             -- save the first child
      do i = 1 to validOperators~words            -- try the valid operators
        if specs~abbrev(validOperators~word(i)),
           then do
          operator = validOperators~word(i)       -- operator matched
          specs = specs~substr(operator~length+1) -- remaining input
          leave
          end
        end
      if i > validOperators~words then,           -- operator not recognized
        call noGood name, 'operator at <'specs'> not valid, use one of <'validOperators'>'
      child.nodenum.2 = operator                  -- store operator
      it = delimitedString(specs,.false,.false)   -- try a delimited string
      if it = .nil then do                        -- nope, must be another input range
        it = inputRange(specs)                     -- extract the range
        if \it[1] then call noGood name, 'invalid input range or delimited string at <'specs'>'
        specs = it[2]                             -- rest of the specs
        child.nodenum.3 = .true                   -- second operand is a range
        child.nodenum.4 = it~section(3)           -- store it
        end
      else do                                     -- a valid delimited string
        specs = it[1]                             -- remaining input
        child.nodenum.3 = .false                  -- second operand is literal string
        child.nodenum.4 = it[2]                   -- store it
        end
      end
    else do                                       -- called by ALL, delimited string expected
      it = delimitedString(specs~substr(pos),,    -- extract the literal string, extra chars are ok
        .false,.false)                            -- and no blank is required after the string
      if it = .nil then call noGood name, 'invalid delimited string <'specs~substr(pos)'>'
      specs = it[1]                               -- input remainder
      nodenum += 1                                -- create a new node
      type.nodenum = 'L'                          -- type is "literal"
      child.nodenum.0 = 1                         -- single child
      child.nodenum.1 = it[2]                     -- store child
      end
    pos = 0                                       -- restart at position 0
    lookAhead = nextLexeme()                      -- look for next lexeme
    end
  end
return nodenum                                    -- okay, return node number

match:                                            -- verify that LOOKAHEAD character is as expected
if lookAhead = arg(1) then do                     -- it is
  lookAhead = nextLexeme()                        -- move on to the next token
  return .true                                    -- indicate success
  end
call noGood name, 'expected character <'arg(1)'>' ||,
  copies(', found <'lookAhead'> instead',lookAhead \= -1)copies(' missing',lookAhead = -1)

nextLexeme:                                       -- locate the start of the next lexeme
pos += 1                                          -- bump position within SPECS string
if pos > specs~length then return -1              -- fallen off end
pos = specs~verify(' ',,pos)                      -- get next non-blank character
if pos = 0 then return -1                         -- none found
return specs~substr(pos,1)                        -- all right, return the character

----------------------------------------------------------------------------------------------------------

::class predselect public subclass stage          -- control destructive test of records

::method init                                     -- init
self~init:super
self~runsOn = ''                                  -- no arguments

::method ready                                    -- check streams
expose buffer                                     -- a buffer for primary input
if self~inStream[!(0)] = .nil then call noGood self~name, 'primary input stream not defined'
if self~inStream[!(1)] = .nil |,                  -- secondary in and primary out must exist
  self~outStream[!(0)] = .nil then call noGood self~name,,
  'secondary input stream or primary output stream not defined'
tertiary = self~inStream[!(2)] \= .nil            -- check whether tertiary input is connected
if tertiary & self~outStream[!(1)] = .nil then,   -- if so, secondary out should exist
  call noGood self~name, 'secondary output stream not defined'
if self~inStream~last > !(1)+tertiary |,
   self~outStream~last > !(0)+tertiary then,
  call noGood self~name, 'too many streams'
buffer = .nil                                     -- no data in buffer

::method process                                  -- incoming data
expose buffer
use strict arg record, streamNo = 0               -- get the record and the stream it arrived on

if streamNo = 0 then buffer = record              -- primary input, store data
else if buffer \= .nil then do                    -- secondary or tertiary, ignore when nothing buffered
  self~write(buffer,streamNo-1)                   -- emit buffer to primary or secondary out
  buffer = .nil                                   -- reset buffer
  end

::method eof
use strict arg streamNo = 0                       -- the input stream reporting EOF

if streamNo = 0 then do                           -- primary in
  self~eof:super                                  -- propagate to all output streams
  self~outStream~empty                            -- empty array
  end
else if self~outStream[streamNo] \= .nil then do  -- secondary or tertiary in
  self~outStream[streamNo]~eof                    -- transmit to primary or secondary out
  self~outStream~remove(streamNo)                 -- remove the outstream we just sent EOF to
  end

----------------------------------------------------------------------------------------------------------

::class preface public subclass stage             -- first run a pipeline, then short primary input stream
-- argument is a pipeline to preface, e.g. use .preface[.arrayStage[myArray]] to preface an array

::method init                                     -- init
expose it buffer eofs secondary                   -- stage, buffer, number of EOFs, secondary instream
use strict arg it = .nil                          -- the pipeline to preface
if \it~isA(.stage) then call noGood self~name, 'argument must be a stage instance, found <'it'>'
self~init:super
self~runsOn = it~name                             -- set RUNSON attribute
buffer = .array~new                               -- buffer for input on primary input stream
secondary = self~connect(1)                       -- connect secondary input to catch the pipeline's EOF
eofs = 0                                          -- no EOFs yet

::method ready
expose it secondary                               -- stage instance, secondary input stream
reply                                             -- avoid a deadlock
stage = it                                        -- find the final stage
do while stage~outStream[!(0)] \= .nil            -- i.e., the one without an output stage
  stage = stage~outStream[!(0)]
  end
stage~setOutStream(0,secondary)                   -- set our secondary input stage as its output stream
it~trace = self~trace                             -- copy trace setting
it~run(.false)                                    -- and start the subsidiary pipeline

::method process                                  -- process record from the stage or from primary input
expose buffer                                     -- buffer for data on primary instream
use strict arg record, streamNo = 0               -- get data and stream number it arrived on
if streamNo = 0 then buffer~append(record)        -- primary input, buffer the record
else self~write(record)                           -- secondary input is from the pipe, output immediately

::method eof                                      -- EOF on either instream
expose buffer eofs                                -- input buffer and EOF count
eofs += 1                                         -- another EOF
if eofs < 2 then return                           -- need one more
do record over buffer
  self~write(record)                              -- now output anything received on primary input stream
  end
drop buffer
self~eof:super                                    -- propagate the EOF

----------------------------------------------------------------------------------------------------------

::class reverse public subclass stage             -- reverse the contents if incoming records

::method init
forward class(super) continue
self~runsOn = ''                                  -- no defined parameters

::method process                                  -- process an item
use strict arg record                             -- access it
self~write(record~reverse)                        -- and pass it through in reversed form

----------------------------------------------------------------------------------------------------------

::class sort public subclass stage                -- sort input lines

::method init
expose items,                                     -- array of items to sort
  count,                                          -- occurrence count requested
  unique,                                         -- suppress duplicates
  anycase,                                        -- ANYCASE flag
  ranges,                                         -- array of ranges
  asc,                                            -- ascending sort flags array
  padChar,                                        -- pad character per range
  maxLength.,                                     -- maximum field length per range
  itemRanges                                      -- ranges per input record
forward class(super) continue

ranges = .array~new(10)                           -- up to 10 input ranges
asc = .array~new(10)                              -- ASCENDING flags
padChar = .array~new(10)                          -- padding characters

specs = consume(arg(1),'COUNT','UNIQue')          -- see if COUNT or UNIQUE were specified
count = specs[4] = 1                              -- count key occurrences
unique = specs[4] = 2                             -- output records with unique keys only

specs = consume(specs,'NOPAD','PAD')
if specs[4] = 2 then do                           -- PAD specified
  pad = xorc(specs[2])                            -- operand must be an XORC
  if pad = .nil then call noGood self~name, 'invalid pad character <'specs[2]'>'
  specs[1] = specs[3]                             -- consume pad character
  end
else pad = -1                                     -- NOPAD specified, or [NO]PAD keyword omitted

specs = consume(specs,'ANYcase')                  -- ANYCASE may be next
anycase = specs[4] = 1                            -- caseless operation

specs = consume(specs,'Ascending','Descending')   -- ascending or descending sort
if specs[1] = '' | specs[4] > 0 then do
  ranges[1] = .array~of('1,-1')                   -- key is entire record
  asc[1] = specs[4] \= 2                          -- ascending sort, unless DESCENDING was specified
  padChar[1] = pad                                -- padding is as specified or defaulted to
  end
else do 10 while specs[1] \== ''                  -- allow at most 10 input ranges
  it = inputRange(specs[1])                       -- get one
  if \it[1] then call noGood self~name, 'invalid input range <'specs[1]'>'
  specs = it[2]                                   -- input following the range specification
  ranges~append(it~section(3))                    -- save range
  specs = consume(specs,'Ascending','Descending') -- ASCENDING or DESCENDING may be given
  asc~append(specs[4] \= 2)                       -- default is ASCENDING
  specs = consume(specs,'NOPAD','PAD')            -- test for (NO)PAD keywords
  select case specs[4]
    when 0 then padChar~append(pad)               -- this range uses the default character
    when 1 then padChar~append(-1)                -- no padding for the range
    otherwise do                                  -- a pad character specific to this range
      it = xorc(specs[2])                         -- it must be an XORC
      if it = .nil then call noGood self~name, 'invalid range pad character <'specs[2]'>'
      padChar~append(it)
      specs[1] = specs[3]                         -- consume pad character
      end
    end
  end

if specs[1] \== '' then call noGood self~name, 'excessive options <'specs[1]'>'

items = .array~new                                -- buffers the input records
itemRanges = .array~new                           -- ranges per input record
maxLength. = 0                                    -- init max field length per range

::method process
expose items ranges maxLength. itemRanges
use strict arg record                             -- input item

index = items~append(record)                      -- append it to the array

do r = 1 to ranges~items
  it = applyRange(ranges[r],record)               -- extract range from current record
  maxLength.r = max(maxLength.r,it~length)        -- keep track of maximum field length
  itemRanges[r,index] = it                        -- store in ITEMRANGES array
  end

::method eof                                      -- EOF, sort and output the accumulated lines
expose items count unique anycase ranges asc padChar maxLength. itemRanges

keys = .array~new
keyLen = 0

do r = 1 to ranges~items
  keyLen += maxlength.r
  end

do i = 1 to items~items
  key = ''
  do r = 1 to ranges~items
    it = itemRanges[r,i]
    padLen = maxlength.r-it~length
    if padLen > 0 & padChar[r] \= -1 then it =,   -- apply padding
      it || copies(padChar[r],padLen)
    if \asc[r] then it =,                         -- descending applies to this range
      it~bitXor(copies('ff'x,it~length))          -- XOR the string with fox-foxes
    key = key || it                               -- append to the key
    end
  keys~append(key || right(i,10))                 -- also store relative record number, sortably
  end

if anycase then,                                  -- case to be ignored
  keys~stableSortWith(.CaselessComparator~new)    -- so use a caseless comparator
else keys~stableSort                              -- else do a normal stable sort

if count | unique then do                         -- COUNT or UNIQUE are in effect
  previous = .nil                                 -- there's no previous key
  occurrences = 0                                 -- init occurrences count
  do key over keys
    parse var key key =(keyLen+1) index .         -- extract key proper and relative record number
    if key \= previous then do                    -- differs from previous one
      if previous \= .nil then do                 -- there was a previous one
        if unique then,                           -- must suppress duplicate lines
          self~write(items[prevIndex])            -- so emit a single copy of previous
        else self~write(right(occurrences,10) ||, -- must prefix record with the occurrence count
          items[prevIndex])
        occurrences = 0                           -- reset occurrences counter
        end
      previous = key                              -- remember key
      prevIndex = index                           -- and index
      end
    occurrences += 1                              -- another occurrence of this item
    end
  if occurrences > 0 then do                      -- line dangling
    if unique then self~write(items[prevIndex])   -- output it as is
    else self~write(right(occurrences,10) ||,     -- or prefixed with the occurrence count
      items[prevIndex])
    end
  end
else do key over keys                             -- not COUNT or UNIQUE, just output the sorted lines
  index = key~substr(keyLen+1)                    -- extract relative line number
  self~write(items[index])                        -- write the line
  end

drop items ranges asc padChar maxLength.,         -- release storage
  itemRanges

forward class(super)                              -- make sure to propagate the EOF message

----------------------------------------------------------------------------------------------------------

::class space public subclass stage               -- generalized REXX SPACE()

::method init                                     -- initialization
expose replace delim                              -- replacement string and delimiters string
forward class(super) continue
use strict arg specs = ''

w1 = specs~word(1)                                -- get first word

if w1~datatype('w') & w1 >= 0 then do             -- a non-negative whole number
  number = w1                                     -- set as replacement count
  specs = specs~subWord(2)                        -- consume parameter
  end
else number = -1                                  -- not specified, or negative

specs = consume(specs,'STRing')                   -- STRING keyword
string = specs[4] = 1                             -- set flag if specified

if string then do
  it = delimitedString(specs[1],.false)           -- a delimited string must follow
  if it = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
  replace = it[2]                                 -- ok, save replacement string
  specs[1] = it[1]                                -- pick up any remaining data
  end
else do
  if specs[1] = '' then replace = ' '             -- default replacement string is a single blank
  else do
    it = delimitedString(specs[1],.false)         -- first, try a delimited string anyway
    if it = .nil then do                          -- no good, replacement string must be an XORC
      xorc = xorc(specs[2])                       -- try parsing an XORC
      if xorc = .nil then call noGood self~name,, -- failed too
        'invalid replacement <'specs[1]'>, please specify a delimited string or an XORC'
      if xorc~datatype('w') & number < 0 then,    -- XORC must not be numeric if NUMBER was omitted
        call noGood self~name, 'numeric replacement XORC <'specs[2]'>, please specify NUMBER first'
      replace = xorc                              -- set the replacement string
      specs[1] = specs[3]                         -- remove XORC item
      end
    else do                                       -- valid delimited string after all
      replace = it[2]                             -- assign it to REPLACE
      specs[1] = it[1]                            -- leftover specs
      end
    end
  end

if number < 0 then number = 1                     -- default for NUMBER is 1

specs = consume(specs,'ANYof')                    -- test for ANYOF keyword
if specs[4] = 1 then do                           -- specified
  it = delimitedString(specs[1],.false)           -- a delimited string must be next
  if it = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
  delim = it[2]                                   -- ok, save delimiters string
  specs[1] = it[1]                                -- pick up any remaining input
  end
else do
  if specs[1] = '' then do                        -- no more input
    if number = 0 & \string then,                 -- count is 0, hence replacement string is irrelevant
      delim = replace                             -- must interpret REPLACE as a delimiters string!
    else delim = ' '                              -- default delimiter is a single blank
    end
  else do
    it = delimitedString(specs[1],.false)         -- try a delimited string first
    if it = .nil then do                          -- failed, delimiters string must be an XORC
      xorc = xorc(specs[2])                       -- try XORC
      if xorc = .nil then call noGood self~name,, -- failed as well
        'invalid delimiters string <'specs[1]'>, please specify a delimited string or an XORC'
      delim = xorc                                -- set delimiter character
      specs[1] = specs[3]                         -- remove the XORC
      end
    else do                                       -- a valid delimited string
      delim = it[2]                               -- assign it to DELIM
      specs[1] = it[1]                            -- leftover input
      end
    end
  end

if specs[1] \= '' then call noGood self~name, 'excessive options <'specs[1]'>'

replace = replace~copies(number)                  -- set the resulting replacement string

::method process                                  -- process an input record
expose replace delim
use strict arg record

output = ''                                       -- initialize output record
i = 1                                             -- set to start of input record

do while i > 0                                    -- while found what we are looking for
  j = record~verify(delim,,i)                     -- find non-delimiter starting at position I
  if j > 0 then do                                -- found it at position J
    i = record~verify(delim,'m',j)                -- find next delimiter character
    if i = 0 then output = output   ||,           -- no further delimiters
      copies(replace,output \== '') ||,           -- append replacement string to output record
      record~substr(j)                            -- followed by the input record from position J
    else output = output            ||,
      copies(replace,output \== '') ||,           -- append replacer
      record~substr(j,i-j)                        -- and a delimiter-free section of the input record
    end
  else i = 0                                      -- if J = 0, rest of input record consists of delimiters
  end

self~write(output)                                -- emit the output record built

----------------------------------------------------------------------------------------------------------

::class spec subclass stage public                -- rearrange records according to specifications
-- SPEC facilities not supported: counters, labels, conditional processing, breaks (except EOF), and
-- structures

::method init                                     -- init
expose specs                                      -- specifications
forward class(super) continue
self~productive = .true                           -- SPEC can run first in pipelines
use strict arg specs = ''                         -- access specs

::method ready                                    -- streams are known, inspect specs
expose specs,                                     -- specs, captured by INIT method
  c.,                                             -- the cycle
  completed,                                      -- processing completed
  stop,                                           -- number of EOFs needed to force a stop
  eof.,                                           -- EOF flag per stream
  open,                                           -- number of streams not at EOF
  useEOF,                                         -- EOF processing required
  eofCycle,                                       -- start of the EOF cycle
  streams,                                        -- list of input stream numbers used
  useFirst,                                       -- primary reading station facility is used
  useSecond,                                      -- secondary reading station facility is used
  runIn,                                          -- runin cycle
  second,                                         -- the record on the secondary reading station
  queue,                                          -- input queues
  recno.,                                         -- relative record number per stream
  reads.,                                         -- implied reads per stream
  current.

stop = 0                                          -- by default, stop when all input streams are drained
streams = ''                                      -- input streams used
current = 0                                       -- current stream
current. = .nil                                   -- current record per stream
useEOF = .false                                   -- no EOF cycle
eofCycle = 0
useFirst = .false                                 -- primary input not used
useSecond = .false                                -- no second reading station
noSELECTs = .true                                 -- SELECT command not processed yet
reads. = 1                                        -- (implied) READ count per stream
conversions =,                                    -- data conversions supported:
  'B2C B2D B2D(8) B2U B2U(8) B2V B2X',            -- from binary to characters, decimal, VARCHAR or hex
  'C2B C2D C2D(8) C2U C2U(8) C2V C2X',            -- from chars to binary, decimal, VARCHAR or hex
  'D2B D2C D2X',                                  -- from 32 bit decimal to binary, chars or hexadecimal
  'D2B(8) D2C(8) D2X(8)',                         -- from 64 bit decimal to binary, chars or hexadecimal
  'U2B U2C U2X',                                  -- from 32 bit unsigned to binary, chars or hexadecimal
  'U2B(8) U2C(8) U2X(8)',                         -- from 64 bit unsigned to binary, chars or hexadecimal
  'V2B V2C V2X',                                  -- from VARCHAR to binary, chars or hexadecimal
  'X2B X2C X2D X2D(8) X2U X2U(8) X2V'             -- from hex to binary, chars, decimal or VARCHAR
c = 0                                             -- command number

do while specs \= ''                              -- parse specifications
  c += 1                                          -- another command
  c.c = .array~new                                -- commands are kept as arrays
  c.c[1] = specs~word(1)~upper                    -- store commmand
  specs = consume(specs,'STOP','READ','READSTOP',,-- consume these keywords, when specified
    'EOF','WRITE','NOWRITE','NOPRINT','SELECT',,
    'OUTSTREAM','PAD','WORDSEParator','WS',,      -- WORDSEPARATOR and FIELDSEPARATOR admit abbreviations
    'FIELDSEParator','FS')
  select case specs[4]                            -- handle keyword
    when 1 then do                                -- STOP
      if c > 1 then call noGood self~name, 'STOP should be the first specification'
      select case specs[2]~upper
        when 'ALLEOF' then nop                    -- when all streams are at EOF (the default)
        when 'ANYEOF' then stop = 1               -- when any input stream is at EOF
        otherwise do                              -- else value should be a positive whole number
          if \datatype(specs[2],'w') |,           -- issue an error when it's not
            specs[2] < 1 then call noGood self~name, 'invalid STOP operand <'specs[2]'>'
          stop = specs[2]                         -- set stopping threshold
          end
        end
      specs = specs[3]                            -- data following the STOP operand
      c -= 1                                      -- do not store STOP as a command
      end
    when 2, 3, 4, 5, 6, 7 then do                 -- READ, READSTOP, EOF, WRITE, NOWRITE, NOPRINT
      select case specs[4]
        when 2, 3 then if current \= -1 &,        -- READ(STOP), ignore for second reading and after EOF
          eofCycle = 0 then reads.current += 1    -- increment read count on this stream
        when 4 then do                            -- EOF: start of EOF cycle
          if useEOF then call noGood self~name, 'duplicate EOF item'
          if streams = '' then streams = 0
          useEOF = .true                          -- set flag
          eofCycle = c+1                          -- EOF processing starts at the next command
          end
        when 7 then c.c[1] = 'NOWRITE'            -- NOPRINT is a synonym for NOWRITE
        otherwise nop
        end
      specs = specs[1]                            -- remove keyword
      end
    when 8 then do                                -- SELECT: switch to another input stream
      stream = specs[2]                           -- the stream to be SELECTed
      select case stream~upper                    -- select selected stream
        when 'FIRST' then stream = 0              -- primary input or reading station
        when 'SECOND' then do                     -- secondary reading station
          useSecond = .true                       -- set flag to indicate station is used
          c.c[2] = -1                             -- store as "input stream -1"
          stream = 0                              -- primary input stream must exist
          end
        otherwise if \datatype(stream,'w') |,     -- must be a non-negative integer
          stream < 0 then call noGood self~name, 'invalid stream number <'stream'> for SELECT'
        end
      if self~inStream[!(stream)] = .nil then,    -- stream not connected
        call noGood self~name, 'SELECT: input stream' stream 'is not connected'
      if streams~wordPos(stream) = 0 then,        -- this is a new stream
        streams = streams stream                  -- add to the list
      if c.c[2] = .nil then c.c[2] = stream       -- save requested input stream number
      if c.c[2] = 0 then useFirst = .true         -- primary input stream used
      noSELECTs = .false                          -- SELECT processed
      current = c.c[2]                            -- set current stream
      specs = specs[3]                            -- skip keyword and argument
      end
    when 9 then do                                -- OUTSTREAM: switch to a different output stream
      stream = specs[2]                           -- number of the desired output stream
      if \datatype(stream,'w') | stream < 0 then, -- must be nonnegative
        call noGood self~name, 'invalid stream number <'stream'> for OUTSTREAM'
      if self~outStream[!(stream)] = .nil then,   -- this output stream is not connected
        call noGood self~name, 'OUTSTREAM: output stream' stream 'is not connected'
      c.c[2] = stream                             -- store the desired output stream
      specs = specs[3]
      end
    when 10, 11, 12, 13, 14 then do               -- padding or a word or field separator
      xorc = xorc(specs[2])                       -- the character to use should be an XORC
      if xorc = .nil then call noGood self~name, 'invalid XORC <'specs[2]'> specified for' c.c[1]
      if specs[4] = 11 then c.c[1] = 'WS'         -- store WORDSEPARATOR abbreviations as WS
      else if specs[4] = 13 then c.c[1] = 'FS'    -- and FIELDSEPARATOR ones as FS
      c.c[2] = xorc                               -- save the pad or separator character
      specs = specs[3]
      end
    otherwise do                                  -- an input and output specification
      select case c.c[1]
        when 'NUMBER', 'RECNO' then do            -- input record number, optional FROM and/or BY
          specs = consume(specs[3],'FROM')        -- FROM operand
          if specs[4] = 1 then do
            from = specs[2]                       -- counting starts at parameter
            if \from~datatype('w') then call noGood self~name,,
              'whole number required after FROM, found <'from'>'
            specs = specs[3]                      -- remove FROM and its parameter
            end
          else from = 1                           -- start counting at 1
          specs = consume(specs,'BY')             -- BY operand
          if specs[4] = 1 then do
            by = specs[2]                         -- the increment to use
            if \by~datatype('w') then call noGood self~name,,
              'whole number required after BY, found <'by'>'
            specs = specs[3]                      -- skip BY and its parameter
            end
          else do
            by = 1                                -- increment by 1 by default
            specs = specs[1]                      -- turn SPECS into a string again
            end
          c.c[1] = 'RECNO'                        -- store as a RECNO
          c.c[2] = from by                        -- with FROM and BY parms in C.C[2]
          end
        when 'TOD' then specs = specs[3]          -- time-of-day, skip keyword
        otherwise do                              -- it may be an inputRange
          it = inputRange(specs[1])               -- try and extract an inputRange
          if it[1] then do                        -- range valid
            if useEOF then call noGood self~name, 'no data will be available for input field'
            if noSELECTs then do                  -- by default, this is from primary input
              streams = 0                         -- add to the list
              useFirst = .true                    -- primary input is used
              end
            specs = it[2]                         -- recover the specs that follow the input range
            c.c[1] = 'RNG'                        -- this is a range
            c.c[2] = it~section(3)                -- the range in question
            end
          else do                                 -- inputRange failed
            it = delimitedString(specs[1],,       -- try a delimited string
              .false,.false)
            if it = .nil then call noGood,        -- didn't work either
              self~name, 'an input range or a delimited string was expected, found <'specs[1]'>'
            else do                               -- valid delimited (or binary or hex) string
              specs = it[1]                       -- data after the delimited string
              c.c[1] = 'LIT'                      -- the input field is a literal string
              c.c[2] = it[2]                      -- store string
              end
            end
          end
        end
      call nextWord                               -- get the next word, both plaintext and uppercased
      if upper = 'STRIP' then do
        c.c[3] = upper                            -- input field to be stripped
        call nextWord                             -- get next word
        end
      if conversions~wordPos(upper) > 0 then do
        c.c[4] = upper                            -- data conversion requested, save converter
        call nextWord
        end
      if upper~abbrev('N') then do                -- N, N.10, NW, NW.3, NF or NF.8 etc. output placement
        parse var word op '.' len                 -- extract operator (N, NW or NF) and length
        it = consume(op,'Next','NEXTWord',,       -- parse operator
          'NWord','NEXTField','NField')
        select case it[4]
          when 1 then op = 'N'                    -- NEXT or an abbreviation, store as N
          when 2, 3 then op = 'NW'                -- an abbreviation of N(EXT)WORD, retain NW
          when 4, 5 then op = 'NF'                -- N(EXT)FIELD or an abbreviation, save as NF
          otherwise nop                           -- produce an error below
          end
        if it[4] = 0 | word~endsWith('.') |,      -- CONSUME error, or dot coded but a length is absent,
          len \= '' & (\datatype(len,'w') |,      -- or length is given but isn't a positive integer
          len < 1) then call noGood self~name, 'output column <'word'> not acceptable'
        c.c[5] = op'.'len                         -- store output placement (note: LEN may be null)
        end
      else do                                     -- else it must be an ordinary output range
        it = range(word,,.true)                   -- go fetch it
        if \it[1] then call noGood self~name, 'invalid output placement: <'word'>'
        c.c[5] = it[3]                            -- store the range
        end
      it = consume(specs,'Center','Centre',,      -- test for an optional output alignment
        'Left','Right')
      if it[4] > 0 then do                        -- was specified
        c.c[6] = specs~word(1)~left(1)~upper      -- store a C, L or R at index 6
        specs = it[1]                             -- consume the keyword
        end
      end
    end
  end

if c = 0 then call noGood self~name, 'specifications missing'
else c.0 = c                                      -- save number of commands

queue = .array~new                                -- create input queues
do i = 1 to streams~words                         -- all input streams used
  stream = streams~word(i)                        -- stream number
  queue[!(stream)] = .queue~new                   -- queue for this stream
  end

second = .nil                                     -- no record on the secondary reading station
runIn = useFirst & useSecond                      -- runin cycle must be run
recno. = 0                                        -- initialize record numbers for all input streams
eof. = .false                                     -- clear EOF flags
open = streams~words                              -- all streams used are open
completed = .false                                -- processing not complete

nextWord:
word = specs~word(1)                              -- get next word of the specs
upper = word~upper                                -- uppercase it
specs = specs~subWord(2)                          -- rest of the specification list
return


::method begin                                    -- no action needed for BEGIN


::method process                                  -- process input

expose c. completed stop useEOF eofCycle streams useFirst useSecond,
  runIn second queue recno. eof. open reads. current.

--trace r
use strict arg record, streamNo = 0               -- received a record on some input stream

if streams~wordPos(streamNo) = 0 then return      -- ignore streams not used in processing

queue[!(streamNo)]~queue(record)                  -- queue incoming record

do forever                                        -- do what we can this time
  if completed then return                        -- all done, quit
  do i = 1 to streams~words                       -- check participating input streams
    stream = streams~word(i)                      -- look up stream number
    if \eof.stream then do                        -- not at EOF
      n = queue[!(stream)]~items                  -- items queued
      if n < reads.stream & \queue[!(stream)]~,   -- insuffient input to satisfy all READ commands
         section(1,reads.stream)~hasItem(.nil),   -- and EOF not in sight
        then return                               -- wait for more input
      if n > 0 & queue[!(stream)][1] = .nil,      -- nil object heading the queue
         then do
        eof.stream = .true                        -- message came from our EOF method
        open -= 1                                 -- one less open stream
        queue[!(stream)]~empty                    -- clear its queue
        end
      end
    end
  noItems = .true                                 -- assume no input items can be processed presently
  if stop = 0 | streams~words-open < stop then do -- EOF threshold not exceeded, get input records
    do i = 1 to streams~words
      stream = streams~word(i)                    -- stream number
      if stream = 0 & useSecond then iterate      -- treat below
      item = queue[!(stream)]~peek                -- head of queue for this stream
      if item = .nil then item = ''               -- streams at EOF are considered to hold a null record
      else noItems = .false                       -- there are items to process
      current.stream = item                       -- save current item for the stream
      end
    if useSecond then do                          -- second reading station used
      if runIn then do                            -- runin cycle
        item = queue[!(0)]~peek                   -- head of the queue
        if item = .nil & \eof.0 then return       -- no record, wait for more input
        noItems = .false                          -- there is input to process
        second = .nil                             -- for second reading, use a null record on the runin
        end
      else do
        item = queue[!(0)]~pull                   -- no(t) runin, pop head of queue
        if item = .nil then item = ''             -- eof, use a null line
        else noItems = .false                     -- items to process
        second = current.0                        -- set second reading station record
        if \useFirst then do                      -- first reading not used
          if streams = 0 & second = .nil then,    -- no other streams and no record on second reading
            noItems = .true
          else if recno.0 = 0 then recno.0 = 1    -- adjust initial record number
          end
        end
      current.0 = item                            -- load current item for stream 0
      end
    end
  else open = 0                                   -- STOP kicking in
  from = 1                                        -- starting point within the cycle
  if noItems then do                              -- STOP took effect or no actual items to process
    if useEOF & open = 0 | second \= .nil then do -- overall EOF or the second station holds pending data
      do i = 1 to streams~words
        stream = streams~word(i)
        if stream \= 0 then current.stream = .nil -- remove data from streams other than primary input
        end
      runOut = .true                              -- start the runout cycle
      if second = .nil then from = eofCycle       -- this is an EOF cycle
      completed = .true                           -- no further processing after runout
      end
    else return                                   -- wait for more input to arrive
    end
  else runOut = .false                            -- not the runout cycle
  stream = 0                                      -- start with primary input stream, even if not there
  record = current.0                              -- and its current item
  pad = ' '                                       -- set default pad character
  ws = ' '                                        -- word separator
  fs = '09'x                                      -- field separator
  buffer = ''                                     -- null output buffer
  output = 0                                      -- output to primary out, initially
  write = .true                                   -- write buffer at end of cycle
  secondSelected = .false                         -- second reading station currently not selected
  selected = .false                               -- indeed, no SELECTs issued yet
trace o
  do c = from to c.0                              -- run command cycle from starting point set
    if runOut & useSecond & \secondSelected |,
       record = .nil & selected then do           -- no record
      do while 'SELECT EOF'~wordPos(c.c[1]) = 0
        c += 1                                    -- ignore commands until the next SELECT or EOF
        if c > c.0 then leave
        end
      if c > c.0 then leave                       -- no commands left
      end
    select case c.c[1]                            -- execute the command at hand
      when 'READ', 'READSTOP' then do             -- READ(STOP) on present stream
        if secondSelected then do                 -- stream is second reading station
          completed = .true                       -- so abandon processing
          self~start('eof',-1)                    -- and have EOF issued
          return
          end
        if stream = 0 & useSecond then,           -- second reading station used
          second = current.0                      -- copy current item
        if queue[!(stream)]~items > 0 &,
           queue[!(stream)][1] = .nil then do     -- nil object at head of queue
          eof.stream = .true                      -- this message came from EOF
          open -= 1                               -- reduce open streams count
          queue[!(stream)]~empty                  -- empty this queue
          item = .nil                             -- no next item
          end
        else do
          it = queue[!(stream)]~pull              -- consume current record, if any
          recno.stream += it \= .nil              -- another input record consumed (or not)
          item = queue[!(stream)]~peek            -- get next item on the queue
          end
        if item = .nil then do                    -- stream has dried up
          if c.c[1] = 'READ' then item = ''       -- for READ, use a null item
          else c = c.0                            -- READSTOP, ignore rest of cycle
          completed = .true                       -- ignore EOF cycle
          end
        current.stream = item                     -- replace current item for this stream
        record = item                             -- load the data into the record buffer
        end
      when 'EOF' then if \runOut then leave       -- EOF cycle starts
      when 'WRITE' then do                        -- emit the output record constructed
        self~write(buffer,output)                 -- to the output stream in effect
        buffer = ''                               -- clear buffer
        end
      when 'NOWRITE' then write = .false          -- don't write a record at the end of the cycle
      when 'SELECT' then do                       -- select an input stream
        stream = c.c[2]                           -- load the stream number
        secondSelected = stream < 0               -- the second reading station
        if secondSelected then record = second    -- use the record it holds, if any
        else record = current.stream              -- else use current item for the stream
        selected = .true
        end
      when 'OUTSTREAM' then output = c.c[2]       -- select a different output stream
      when 'PAD' then pad = c.c[2]                -- change pad character
      when 'WS' then ws = c.c[2]                  -- change word separator
      when 'FS' then fs = c.c[2]                  -- change field separator
      otherwise do                                -- command is an input/output sequence
        select case c.c[1]                        -- input source
          when 'RECNO' then do                    -- the record number on the current input stream
            if secondSelected then it = recno.0-1 -- second reading station
            else it = recno.stream                -- get its present value
            parse value c.c[2] with from by .     -- get FROM and BY parms
            it = (it*by+from)~right(10)           -- format using these, length 10, right aligned
            end
          when 'TOD' then do                      -- "TOD clock"
            numeric digits 18                     -- request enough precision
            it = time('f')~d2c(8)                 -- microseconds since 0 Jan 1, converted to a double
            numeric digits                        -- restore precision
            end
          when 'LIT' then it = c.c[2]             -- LIT, retrieve the literal
          when 'RNG' then do                      -- an input range
            if record = .nil then iterate         -- record unavailable
            it = applyRange(c.c[2],record,ws,fs)  -- issue APPLYRANGE to get the data
            end
          otherwise nop
          end
        if c.c[3] = 'STRIP' then it =,            -- strip blanks (and just these) off both sides
          it~strip(,' ')
        if it == '' & c.c[1] = 'RNG' then iterate -- ignore null ranges, even if not null before STRIPping
        if it \== '' & c.c[4] \= .nil then do     -- data conversion requested
          numeric digits 20
          if 'DU'~pos(c.c[4]~left(1)) > 0 then do -- from (un)signed decimal to binary, character or hex
            if \it~datatype('w') then call bad it -- not an integer
            select                                -- determine maximum and minimum values
              when c.c[4]~startsWith('D') &,
                   c.c[4]~endsWith('(8)') then,   -- D2*, 64 bits
                max = 2**63-1
              when c.c[4]~startsWith('D') then,   -- D2*, 32 bits
                max = 2**31-1
              when c.c[4]~endsWith('(8)') then,   -- U2*, 64 bits
                max = 2**64-1
              otherwise max = 2**32-1             -- U2*, 32 bits
              end
            if c.c[4]~startsWith('U') then min = 0-- unsigned, number must be non-negative
            else min = -max-1                     -- signed, compute minimum
            if it < min | it > max then,
              call bad it, '!'                    -- number out of range
            end
          select case c.c[4]
            when 'B2C' then it = it~b2x~x2c       -- B2C conversion: through an intermediary B2X
            when 'B2D' then it = c2dec(it~b2x~x2c)-- same for B2D, using routine C2DEC below
            when 'B2D(8)' then it =,              -- binary to 64 bit signed decimal
              c2dec(it~b2x~x2c,8)
            when 'B2U' then it = c2u(it~b2x~x2c)  -- binary to unsigned, using C2U() routine
            when 'B2U(8)' then it =,              -- binary to 64 bit unsigned
              c2u(it~b2x~x2c,8)
            when 'B2V' then it = c2v(it~b2x~x2c)  -- binary to VARCHAR, use routine C2V below
            when 'B2X' then it = it~b2x           -- binary to hex
            when 'C2B' then it = it~c2x~x2b       -- CHAR to binary
            when 'C2D' then it = c2dec(it)        -- CHAR to decimal
            when 'C2D(8)' then it = c2dec(it,8)   -- CHAR to 64 bit decimal
            when 'C2U' then it = c2u(it)          -- CHAR to 32 bit unsigned
            when 'C2U(8)' then it = c2u(it,8)     -- CHAR to 64 bit unsigned
            when 'C2V' then it = c2v(it)          -- CHAR to VARCHAR
            when 'C2X' then it = it~c2x           -- CHAR to hex
            when 'D2B', 'U2B' then it =,          -- signed or unsigned decimal to binary
              it~d2x(8)~x2b
            when 'D2C', 'U2C' then it = it~d2c(4) -- decimal to CHAR
            when 'D2X', 'U2X' then it = it~d2x(8) -- decimal to hex
            when 'D2B(8)', 'U2B(8)' then it =,    -- 64 bit decimal to binary
              it~d2x(16)~x2b
            when 'D2C(8)', 'U2C(8)' then it =,    -- 64 bit decimal to CHAR
              it~d2c(8)
            when 'D2X(8)', 'U2X(8)' then it =,    -- 64 bit decimal to hex
              it~d2x(16)
            when 'V2B' then it =,                 -- VARCHAR to binary
              (it~length~d2c(2)||it)~c2x~x2b
            when 'V2C' then it =,                 -- VARCHAR to CHAR
              it~length~d2c(2)||it
            when 'V2X' then it =,                 -- VARCHAR to hex
              (it~length~d2c(2)||it)~c2x
            when 'X2B' then it = it~x2b           -- hex to binary
            when 'X2C' then it = it~x2c           -- hex to CHAR
            when 'X2D' then it = c2dec(it~x2c)    -- hex to decimal
            when 'X2D(8)' then it =,              -- hex to 64 bit decimal
              c2dec(it~x2c,8)
            when 'X2U' then it = c2u(it~x2c)      -- hex to unsigned
            when 'X2U(8)' then it = c2u(it~x2c,8) -- hex to 64 bit unsigned
            when 'X2V' then it = c2v(it~x2c)      -- hex to VARCHAR
            end
          numeric digits
          end
        if c.c[5]~abbrev('N') then do             -- must output at next available position (N, NW or NF)
          parse value c.c[5] with op '.' len      -- operator and an optional length
          if buffer \== '' then select case op    -- ignore if buffer still void
            when 'NW' then buffer = buffer||' '   -- must append a blank (NOT the WS character)
            when 'NF' then buffer = buffer||'09'x -- add a TAB character (NOT the FS)
            otherwise nop                         -- NEXT = next available output position
            end
          pos = buffer~length+1                   -- must append data to buffer
          if len = '' then len = it~length        -- output length not specified, take from data item
          end
        else do                                   -- an output range was used
          range = c.c[5]                          -- retrieve it
          if range~pos(',') > 0 then do           -- range is of the form "from,to"
            parse var range pos ',' lastpos       -- get first and last output position
            len = lastpos-pos+1                   -- derive field length
            end
          else do                                 -- range given as starting column only
            pos = range                           -- set output position
            len = it~length                       -- length of input item
            end
          end
        if pos > buffer~length+1 then,            -- item will be put beyond current buffer end
          buffer = buffer~left(pos-1,pad)         -- pad to the starting position
        if len > it~length then select case c.c[6]-- requested length exceeds DATA's, check alignment
          when .nil, 'L' then it =,               -- none or Left, the default
            it~left(len,pad)                      -- pad to the correct length, left aligned
          when 'C' then it = it~center(len,pad)   -- center the data
          otherwise it = it~right(len,pad)        -- align right
          end
        buffer = buffer~left(pos-1) || it ||,     -- unaffected buffer head, followed by the data
          buffer~substr(pos+len)                  -- and any unaffected tail
        end
      end
    end
  if write then self~write(buffer,output)         -- write the buffer to the outstream in effect
  if completed then do                            -- processing is now complete
    self~start('eof',-1)                          -- issue EOF to successor stage
    return
    end
  do i = 1 to streams~words                       -- pop all heads of queue processed
    stream = streams~word(i)                      -- input stream number
    if stream = 0 & useSecond & \runIn then do    -- primary and not runin, already popped queue head
      second = current.0                          -- copy record to second reading
      recno.stream += second \= .nil              -- another line read
      end
    else do                                       -- not primary, or executing runin
      it = queue[!(stream)]~pull                  -- drop the head of queue
      if stream = 0 & useSecond then second = it  -- for primary, copy record to second reading station
      recno.stream += it \= .nil                  -- another record consumed, or not
      end
    end
  runIn = .false                                  -- runin done now, or not
  end                                             -- start another cycle

c2dec: use strict arg data, precision = 4         -- conversion for c2d or c2d(8), with sign extension
dLength = data~length                             -- data length
select
  when dLength < precision then do                -- shorter than 4 or 8 bytes
    sign = (-(data >= '80'x))~d2c(1)              -- sign byte '00'x or 'FF'x
    data = copies(sign,precision-dLength)data     -- extend sign
    end
  when dLength > precision then do                -- data longer than 4 or 8 bytes
    parse var data ext =(dLength-precision+1) data-- get sign extension
    sign = (-(data >= '80'x))~d2c(1)              -- sign of actual data
    if ext \= copies(sign,dLength-precision) then,-- extension invalid
      call bad arg(1)
    end
  otherwise nop                                   -- data length is ok
  end
if precision = 8 then return data~c2d(precision)  -- convert to decimal for precision 8
else return data~c2d(precision)~right(11)         -- 11 bytes, right aligned, for precision 4

c2u: use strict arg data, precision = 4           -- conversion for c2u or c2u(8)
dLength = data~length                             -- data length
select
  when dLength < precision then data =,           -- shorter than 4 or 8 bytes
    data = copies('00'x,precision-dLength)data    -- extend sign
  when dLength > precision then do                -- data longer than 4 or 8 bytes
    parse var data sb =(dLength-precision+1) data -- superfluous bytes
    if sb \= copies('00'x,dLength-precision) then,-- error if they aren't zeroes
      call bad arg(1)
    end
  otherwise nop                                   -- length is okay
  end
if precision = 8 then return data~c2d             -- convert to decimal for precision 8
else return data~c2d~right(11)                    -- 11 bytes, right aligned, for precision 4

c2v: data = arg(1)                                -- convert VARCHAR to CHAR
dLength = data~length
if dLength >= 2 then do                           -- need a halfword for the string length
  vLength = data~left(2)~c2d                      -- determine length
  if dLength >= 2+vLength then return,            -- sufficient data present
    data~substr(3,vLength)                        -- starting at position 3
  end
call bad data                                     -- bad data no good

bad: call noGood self~name, 'invalid' c.c[4] 'conversion operand <'arg(1)'>' ||,
  copies(' = '''arg(1)~c2x'''x',arg(2)=='')


::method eof                                      -- EOF on an input stream
expose specs c. stop useEOF eofCycle streams useFirst useSecond runIn,
  second queue recno. eof. open reads. current.
use strict arg streamNo = 0                       -- stream signaling EOF

if streams~wordPos(streamNo) > 0 & \eof.streamNo,
  then self~process(.nil,streamNo)                -- send a nil record to PROCESS to handle this EOF
else if streamNo < 0 then do                      -- all done now
  do it over queue
    it~empty                                      -- empty input queues
    end
  drop specs c. stop useEOF eofCycle streams useFirst useSecond runIn,
    second queue recno. open reads. current.      -- clean up
  self~eof:super                                  -- and forward the EOF
  end

----------------------------------------------------------------------------------------------------------

::class spill subclass stage public               -- spill long lines at word boundaries

::method init                                     -- init stage
expose number,                                    -- maximum output record length
  strSplit,                                       -- split at a specified string
  string,                                         -- or at any of a specified list of characters
  strLen,                                         -- string length
  not,                                            -- negate target
  anycase,                                        -- case insensitive processing
  keep,                                           -- keep the split string or character when matched
  offset,                                         -- offset string
  offLen,                                         -- and length
  lastOccurrence,                                 -- an expression to be INTERPRETed
  startsWith,                                     -- another such
  endsWith                                        -- and another
forward class(super) continue

parse arg number specs                            -- first parameter is maximum output record length
if \number~datatype('w') | number < 1 then,       -- it must be a positive integer
  call noGood self~name, 'maximum output record length not a positive whole number: <'number'>'

parse value '0 0 0 0' with,
  strSplit not anycase keep offset .              -- initialize controls

specs = consume(specs,'STRing','ANYof','NOT',,    -- scan for separator keywords
  'NOTANYof')
if specs[4] = 0 then do
  it = delimitedString(specs[1],.false)           -- none present, test for a delimited string
  if it = .nil then it = .array~of(specs[1],' ')  -- no, use default separator
  else if it[2]~length > 1 then strSplit = .true  -- yes, use default option STRING
  end
else do
  select case specs[4]
    when 1 then strSplit = .true                  -- keyword STRING
    when 3, 4 then do                             -- keywords NOT or NOTANYOF
      if specs[4] = 3 then do                     -- NOT must be followed by ANYOF
        specs = consume(specs,'ANYof')
        if specs[4] = 0 then call noGood self~name, 'ANYOF expected after NOT, found <'specs[2]'>'
        end
      not = .true                                 -- NOT is in effect
      end
    otherwise nop                                 -- ANYOF
    end
  it = delimitedString(specs[1],.false)           -- a delimited string is required next
  if it = .nil then call noGood self~name, 'delimited string expected'
  end

if it[2] == '' then call noGood self~name, 'null string found'
string = it[2]                                    -- store string
strLen = string~length                            -- and length
if strLen = 1 then strSplit = .true               -- processes faster
specs = it[1]                                     -- data after the delimited string

do forever
  specs = consume(specs,'ANYcase','KEEP','OFFSET')-- check for further keywords
  select case specs[4]
    when 0 then leave                             -- not specified
    when 1 then anycase = .true                   -- caseless processing
    when 2 then keep = .true                      -- keep separators
    otherwise do                                  -- OFFSET
      if specs[2]~datatype('w') & specs[2] >= 0,  -- a non-negative integer
         then do
        offset = ''~left(specs[2])                -- use that many blanks
        specs[1] = specs[3]                       -- remaining specifications
        end
      else do
        it = delimitedString(specs[1],.false)     -- must be a delimited string
        if it = .nil then call noGood self~name, 'number or delimited string expected after OFFSET'
        offset = it[2]                            -- pick up string
        specs[1] = it[1]                          -- and rest of the specs
        end
      end
    end
  end

if specs[1] \= '' then call noGood self~name, 'excessive options <'specs[1]'>'

offLen = offset~length                            -- length of offset string
if offLen >= number then call noGood self~name, 'offset not shorter than width'

if strSplit then do                               -- split before last occurrence of string
  lastOccurrence = 'line~'||,                     -- phrase to be interpreted to find that occurrence
    copies('caseless',anycase)'lastPos(string)'
  startsWith = 'it~'copies('caseless',anycase)||, -- ditto to test if something starts with the string
    'startsWith(string)'
  endsWith = 'it~'copies('caseless',anycase)||,   -- or ends with it
    'endsWith(string)'
  end
else do                                           -- split before last characters found in string
  if anycase then string =,                       -- ANYCASE, adapt STRING
    string~lower || string~upper
  if not then do                                  -- NOT specified, take complement of STRING
    p = string~substr(random(1,string~length),1)  -- pick any character from the string
    string = xrange()~translate(,string,p)~,      -- determine the characters NOT in string
      changeStr(p,'')                             -- remove pad character
    end
  end


::method ready
expose secondary                                  -- secondary output stream present
if self~inStream[!(0)] = .nil |,
  self~inStream~items \= 1 then call noGood self~name, 'need (only) primary input'
secondary = self~outStream[!(1)] \= .nil          -- set flag when secondary out is connected


::method process
expose number strSplit string strLen not anycase, -- expose controls
  keep offset offLen lastOccurrence startsWith endsWith,
  secondary
use strict arg record, streamNo = 0               -- spill a record
continuation = .false                             -- next line isn't a continuation line

if strSplit then do forever                       -- split long lines at STRING
  n = number-offLen*continuation                  -- maximum length of a line we can output
  if record~length <= n then leave                -- record is short enough, done
  parse var record line =(n+strLen) record        -- LINE is the first N+STRLEN-1 characters
  interpret 'i =' lastOccurrence                  -- get last position of STRING within LINE
  if i = 0 | keep & i = 1 then do                 -- no match, or KEEP and data starts with string
    if secondary then do                          -- secondary out is connected
      self~write(copies(offset,continuation)||,   -- send the remainder there
        line||record,1)
      return                                      -- and make no further attempts at splitting
      end
    parse value line||record with,                -- break up the record
      line =(n+1) record                          -- LINE is first N characters, RECORD is rest
    self~write(copies(offset,continuation)line)   -- write the line to primary out
    continuation = .true                          -- set flag
    iterate
    end
  if keep then do                                 -- keep the string
    if i+strLen-1 <= n then i += strLen           -- it can be included in LINE, else in RECORD
    record = line~substr(i)record                 -- find remainder
    line = line~left(i-1)                         -- and the line to output
    end
  else do
    record = clip(line~substr(i+strLen)record)    -- strip the record
    line = clip(line~left(i-1))                   -- and the line
    end
  if line \== '' then do
    self~write(copies(offset,continuation)line)   -- output the line
    continuation = .true
    end
  if record == '' & continuation then return      -- nothing left and output was produced
  end
else do forever                                   -- STRING consists of separator characters
  n = number-offLen*continuation                  -- maximum length of a line we can output
  if record~length <= n then leave                -- record is short enough now
  parse var record line =(n+1) record             -- LINE is first N characters, RECORD is rest
  if \keep then do                                -- not KEEP
    if \record~matchChar(1,string) then do        -- remainder does not start with a separator
      i = line~reverse~verify(string,'m')         -- apply method "[caseless]LastMatch"
      if i > 0 then parse value line||record,     -- detected a character of STRING
        with line =(n+1-i) record                 -- split after it
      else if secondary then do                   -- no match, but we have secondary output
        self~write(copies(offset,continuation)||, -- send the remainder there
          line||record,1)
        return                                    -- and give up
        end
      end
    line = line~strip(,string)                    -- strip separator characters off LINE and RECORD
    record = record~strip(,string)
    end
  if line \== '' then do
    self~write(copies(offset,continuation)line)   -- output a line
    continuation = .true
    end
  if record == '' & continuation then return      -- nothing left and output was produced
  end

self~write(copies(offset,continuation)record)     -- output the remainder, either offset or not
return

clip: it = arg(1)                                 -- strip STRING from argument item
do forever
  interpret 'matched =' startsWith                -- item starts with the string
  if matched then it = it~right(it~length-strLen) -- remove the string from the left
  else leave
  end
do forever
  interpret 'matched =' endsWith                  -- item ends with the string
  if matched then it = it~left(it~length-strLen)  -- remove from the right
  else leave
  end
return it

----------------------------------------------------------------------------------------------------------

::class split subclass stage public               -- split input records

::method init                                     -- initialization
expose strSplit,                                  -- split at a specified string
  string,                                         -- or (default) at any of a specified list of characters
  strLen,                                         -- string length
  splitAt,                                        -- remove the split string or character when matched
  anycase,                                        -- case insensitive processing
  minimum,                                        -- minimum # of characters before a match can occur
  offset,                                         -- bytes to shift on finding a match
  not,                                            -- negate target
  limit,                                          -- maximum number of splits (when target is not BLANK)
  matchFound?                                     -- an expression to be INTERPRETed
forward class(super) continue

strSplit = .false                                 -- split before any character of string
string = ' '                                      -- initialize the string to a single blank
offset = 0                                        -- offset to apply when target is matched
limit = -1                                        -- no limit to the number of splits we can make

specs = consume(arg(1),'ANYCase')
anycase = specs[4] = 1                            -- ANYCase specified, ignore case

specs = consume(specs,'MINimum')                  -- MINIMUM, minimum abbreviation is MIN
if specs[4] = 1 then do                           -- grace number of bytes before we start matching
  if \specs[2]~datatype('w') | specs[2] < 1 then, -- needs to be a positive integer
    call noGood self~name, 'MINIMUM value not a positive whole number: <'specs[2]'>'
  minimum = specs[2]                              -- ok, store number
  specs = consume(specs[3])                       -- consume value
  end
else minimum = 0

specs = consume(specs,'AT','BEFORE','AFTER')      -- consume keywords AT, BEFORE and AFTER
type = specs[4]                                   -- 1 for AT, 2 for BEFORE, 3 for AFTER

if type = 0 then do                               -- neither of these
  w2 = specs[3]~word(1)                           -- try the second word, since BEFORE or AFTER may be
  i = 'BEFORE AFTER'~caselessWordPos(w2)          -- preceded by the offset integer
  if i > 0 then do                                -- they are
    if \specs[2]~datatype('w') then call noGood self~name, 'invalid whole number <'specs[2]'>',
      'found preceding <'w2'>'
    offset = specs[2]                             -- offset is valid
    type = i+1                                    -- split type is BEFORE or AFTER
    specs = consume(specs[1]~subWord(3))          -- consume offset and keyword
    end
  else type = 1                                   -- default is SPLIT AT, target is removed from the input
  end

specs = consume(specs,'NOT')                      -- check whether or not NOT was specified
not = specs[4] = 1                                -- must negate the target

if specs[1] \== '' then do                        -- input continues
  string = hexrange(specs[2])                     -- try an XRANGE first
  if string = .nil then do                        -- invalid
    it = delimitedString(specs[1],.false)         -- maybe it's a delimited string
    if it = .nil then do                          -- failed too
      specs = consume(specs,'STRing','ANYof')     -- test keywords STRING and ANYOF
      if specs[4] = 0 then call noGood self~name, 'operand not recognized: <'specs[2]'>'
      strSplit = specs[4] = 1                     -- match the string rather any of its characters
      it = delimitedString(specs[1],.false)       -- a delimited string should follow
      if it = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
      end
    else if it[2]~length > 1 then,                -- warning if "long" string not preceded by STR or ANY
      say self~name': ANYOF assumed in front of <'specs[1]'>'
    if it[2] == '' then call noGood self~name, 'null string found'
    string = it[2]                                -- store string
    limit = it[1]                                 -- data following the delimited string, perhaps a limit
    end
  else limit = specs[3]                           -- split before any character in STRING = the XRANGE
  if limit = '' then limit = -1
  else do                                         -- a final parameter, if any, must be numeric
    if \limit~datatype('w') | limit < 0 then,     -- and non-negative
      call noGood self~name, 'invalid splitting limit <'specs[1]'>'
    limit = limit~format                          -- store maximum number of splits to carry out
    end
  end

if strSplit then do                               -- split before occurrences of string
  strLen = string~length                          -- set string length
  matchFound? = copies('\',not)  ||,              -- phrase to be interpreted to determine a match:
    'record~substr(i,'strLen')~' ||,              -- [\]RECORD~SUBSTR(I,STRLEN)~[CASELESS]EQUALS(STRING)
    copies('caseless',anycase)   ||,
    'equals(string)'
  end
else do                                           -- split before any character of string
  strLen = 1                                      -- string length 1
  if anycase then string =,                       -- ANYCASE, adapt STRING
    string~lower || string~upper
  matchFound? = 'record~substr(i,1)~' ||,         -- we have a match when:
    'verify(string)' copies('\',not)'= 0'         -- RECORD~SUBSTR(I,1)~VERIFY(STRING) [\]= 0
  end

if type = 3 then offset = -offset-strLen          -- AFTER, adapt offset to take when a match is found
splitAt = type = 1                                -- set flag to indicate AT


::method process                                  -- processing for SPLIT
expose string splitAt strLen minimum offset not limit matchFound?
use strict arg record                             -- retrieve data record

if record == '' | limit = 0 then do               -- a null string, or the splitting limit is zero
  self~write(record)                              -- copy straight to the output
  return
  end

recLen = record~length                            -- input record length
previous = 1                                      -- "previous" split position
outpos = 1                                        -- overall output position
limes = limit                                     -- copy LIMIT

do i = minimum+1 to recLen                        -- scan the input record
  interpret 'matched =' matchFound?               -- do we have a match?
  if matched then do                              -- yes
    match = i-offset                              -- apply any offset
    if match > previous &,                        -- beyond the previous match
       previous > 0 & previous <= recLen then do  -- previous split position exists in the record
      if previous > outpos then,                  -- but exceeds the output position
        if done(outpos,previous-outpos) then,     -- catch up until PREVIOUS
        return                                    -- return if LIMIT is reached
      maxLen = min(match,recLen+1)-previous       -- then output from PREVIOUS onwards
      if done(previous,maxLen) then return        -- up to MATCH or record end, whichever's first
      outpos = match                              -- set new OUTPOS
      end
    previous = match                              -- set new PREVIOUS
    if splitAt then do                            -- AT, remove search string
      if not then do                              -- NOT, string was NOT matched
        outpos += 1                               -- increment OUTPOS and PREVIOUS
        previous += 1                             -- as we do not want this emitted
        end
      else do                                     -- normal processing, skip the matched string
        outpos += strLen
        previous += strLen
        end
      end
    if \not then i += strLen-1                    -- skip matched string, unless NOT is in effect
    i += minimum                                  -- MINIMUM # of characters to ignore before matching
    end
  else if not then i += strLen-1                  -- no match here and NOT holds: skip fragment
  end

match = i-offset                                  -- end of record, write any previous match
if match > previous &,
   previous > 0 & previous <= recLen then do
  if previous > outpos then,                      -- first catch up from OUTPOS
    if done(outpos,previous-outpos) then return
  self~write(record~substr(previous))             -- and then output the substring starting at PREVIOUS
  outpos = recLen+1                               -- adjust OUTPOS
  end
if outpos <= recLen then,                         -- output position still not beyond record end
  self~write(record~substr(outpos))               -- write the remainder

return

done: use strict arg from, len                    -- output a split off fragment, checking the LIMIT
self~write(record~substr(from,len))               -- emit fragment
limes -= 1                                        -- decrement limit
done = limes = 0                                  -- done if limit now zero
if done then self~write(record~substr(from+len))  -- output remainder of the record
return done                                       -- and return DONE flag

----------------------------------------------------------------------------------------------------------

::class stack subclass stage public               -- read or write the stack
-- no parameters supported; if not running first in a pipeline, records are stacked FIFO

::method init
forward class(super) continue
self~productive = .true                           -- we can run as the first stage in a pipeline
self~runsOn = ''

::method begin                                    -- running as a first stage
do queued()
  parse pull record                               -- read the stack
  self~write(record)                              -- output the record
  end
self~eof                                          -- and signal EOF

::method process                                  -- not running first
use strict arg record                             -- access the incoming record
queue record                                      -- queue it
forward class(super)                              -- and perform default PROCESSing

----------------------------------------------------------------------------------------------------------

::class stemStage subclass stage public           -- fill a stem or send its contents down the pipeline
-- a simple form of CMS Pipelines stage STEM; operand is a local stem variable containing strings;
-- when run as the first stage in a pipeline, it sends strings STEM.1 through STEM.[STEM.0] down the pipe;
-- otherwise it stores incoming data into the stem, sets STEM.0 to the number of records read, and passes
-- all input to its primary output stream (if connected); STEM.X variables existing prior to execution are
-- unaffected (for any X other than the numbers 0 through STEM.0)

::method init
expose stem. initCount                            -- target stem and INITCOUNT flag
forward class(super) continue
if \arg(1)~isA(.stem) then call noGood self~name, 'argument should be a local stem variable'
self~productive = .true                           -- we can run as the first stage in a pipeline
initCount = .true                                 -- initialize stem.0 to 0 when not the first stage
use strict arg stem.                              -- get the target stem variable

::method begin                                    -- running as the first stage in a pipeline
expose stem. initCount                            -- expose stem and flag
if \stem.0~datatype('n') then call noGood self~name, 'not a valid number: <'stem.0'>'
initCount = .false                                -- switch this off for EOF
do i = 1 to stem.0
  self~write(stem.i)                              -- pump the individual stem items into the pipe
  end
self~eof                                          -- and signal eof

::method process                                  -- process a pipeline item
expose stem. initCount                            -- expose stem and initialization flag

if initCount then do                              -- stem.0 not initialized yet
  stem.0 = 0
  initCount = .false                              -- now initialized
  end

use strict arg record                             -- retrieve the data item
stem.0 += 1                                       -- increment item count
stem.[stem.0] = record                            -- store item into the stem
forward class(super)                              -- output to follow-up stage through super's method

::method eof
expose stem. initCount
if initCount then do                              -- PROCESS method was never driven
  stem.0 = 0
  initCount = .false
  end
self~eof:super

----------------------------------------------------------------------------------------------------------

::class strFrLabel public subclass stage          -- select records from the first one with leading string

::method init
expose anycase,                                   -- case to be ignored
  string,                                         -- string to match
  inclusive,                                      -- first record starting with string is to be included
  seenString                                      -- that record has been seen
forward class(super) continue

specs = consume(arg(1),'ANYcase')                 -- ANYCASE keyword
anycase = specs[4] = 1                            -- ignore case

specs = consume(specs,'INCLUSIVe','EXCLUSIVe')    -- keywords INCLUSIVE (the default) or EXCLUSIVE
inclusive = specs[4] \= 2                         -- first record having the leading string is included

it = delimitedString(specs[1],.false)             -- a delimited string must be next
if it = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
if it[1] \= '' then call noGood self~name, 'excessive options <'it[1]'>'
string = it[2]                                    -- ok, store the string

seenString = .false                               -- ain't seen it at the start of a record yet

::method process                                  -- handle an input record
expose anycase string inclusive seenString
use strict arg record
select
  when seenString then self~write(record)         -- a record having the leading string has already passed
  when record~abbrev(string) |,                   -- found the string, respecting case
     anycase & record~caselessAbbrev(string),     -- or disregarding case, if allowed
     then do
    seenString = .true                            -- set flag
    if inclusive then self~write(record)          -- output on the primary output stream from now on
    else self~write(record,1)                     -- or starting with the the next record
    end
  otherwise self~write(record,1)                  -- nope, send to secondary out
  end

----------------------------------------------------------------------------------------------------------

::class strip public subclass stage               -- strip records

::method init                                     -- initialize
expose blt,                                       -- BLT option, 1 = BOTH, 2 = LEADING, 3 = TRAILING
  not,                                            -- negate match (strip if a match is NOT found)
  string strLen limit,                            -- character string, length, max characters to remove
  left? right?                                    -- interpreted expressions used with matching
forward class(super) continue

specs = consume(arg(1),'ANYCase')
anycase = specs[4] = 1                            -- ignore case

specs = consume(specs,'BOTH','LEADING','TRAILING')-- check for keywords stipulating WHERE we should strip
blt = specs[4]                                    -- save relative number (1 for BOTH, etc.)
if blt = 0 then blt = 1                           -- default is strip from both ends

specs = consume(specs,'NOT','TO')                 -- NOT and TO are synonymous
not = specs[4] > 0                                -- if specified, negate target

limit = -1                                        -- no stripping limit
anyof = .true                                     -- strip off any characters from string STRING

if specs[1] \== '' then do                        -- specifications continue
  string = hexrange(specs[2])                     -- check if a hexrange is specified
  if string = .nil then do                        -- nope
    specs = consume(specs,'STRing','ANYof')       -- check STRING and ANYOF keywords
    if specs[4] = 1 then anyof = .false           -- STRING, we must strip off the entire STRING
    it = delimitedString(specs[1],.false)         -- need a delimited string next
    if it = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
    if it[2] == '' then call noGood self~name, 'null string found'
    if specs[4] = 0 & it[2]~length > 1 then say,  -- issue warning
      self~name': ANYOF assumed in front of <'specs[1]'>'
    string = it[2]                                -- set STRING
    limit = it[1]                                 -- data following the delimited string
    end
  else limit = specs[3]                           -- STRING was set to a valid XRANGE
  if (\limit~datatype('w') | limit < 0) &,        -- LIMIT, if specified, is a non-negative integer
     limit \= '' then call noGood self~name, 'excessive options <'limit'>'
  end

if anyof then do                                  -- strip off any character occurring in STRING
  strLen = 1                                      -- matching length is 1
  if anycase then string =,                       -- for ANYCASE, adapt STRING
    string~lower || string~upper
  left? = 'record~left(1)~verify(string)',        -- phrase to determine a match on the left
    copies('\',not)'= 0'
  right? = left?~changeStr('left','right')        -- or right
  end
else do                                           -- strip off occurrences of the entire string STRING
  strLen = string~length                          -- length of a match
  left? = copies('\',not)'record~' ||,            -- expression used to decide a match on the left
    copies('caseless',anycase)     ||,
    'startsWith(string)'
  right? = left?~changeStr('starts','ends')       -- or right
  end

::method process
expose blt not string strLen limit left? right?
use strict arg record                             -- input record

if limit < 0 then leftMargin = record~length      -- unlimited stripping
else leftMargin = limit                           -- else set limit
rightMargin = leftMargin                          -- it applies to both sides independently

do while record~length > 0
  if leftMargin > 0 & blt \= 3 then do            -- room left for stripping, and not TRAILING
    interpret 'matched =' left?                   -- a character or string match?
    if matched then do                            -- yes, strip leading characters
      if not then i = 1                           -- for NOT, remove one character
      else i =,                                   -- else do not exceed either STRLEN or
        min(leftMargin,strLen,record~length)      -- the record boundary
      record = record~substr(i+1)                 -- clip
      leftMargin -= i                             -- adjust margin by # of characters removed
      end
    else leftMargin = 0                           -- no match, give up
    end
  if rightMargin > 0 & blt \= 2 &,                -- not LEADING, so strip trailing
     record~length > 0 then do                    -- if there's anything left to strip
    interpret 'matched =' right?                  -- test record
    if matched then do                            -- a match on the right
      if not then i = 1                           -- NOT, remove one character
      else i =,                                   -- else don't exceed STRLEN and record end
        min(leftMargin,strLen,record~length)
      record = record~left(record~length-i)       -- remove I characters
      rightMargin -= i                            -- adapt margin
      end
    else rightMargin = 0                          -- done
    end
  if leftMargin = 0 & rightMargin = 0 then leave  -- all done
  end

self~write(record)                                -- emit what's left of the poor record

----------------------------------------------------------------------------------------------------------

::class strToLabel public subclass stage          -- select records to the first one with leading string

::method init
expose anycase inclusive string seenString        -- controls as for STRFRLABEL
forward class(super) continue

specs = consume(arg(1),'ANYcase')                 -- ANYCASE keyword
anycase = specs[4] = 1                            -- ignore case

specs = consume(specs,'INCLUSIVe','EXCLUSIVe')    -- keywords INCLUSIVE or EXCLUSIVE (the default)
inclusive = specs[4] = 1                          -- first record having the leading string is included

it = delimitedString(specs[1],.false)             -- a delimited string must be next
if it = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
if it[1] \= '' then call noGood self~name, 'excessive options <'it[1]'>'
string = it[2]                                    -- ok, store the string

seenString = .false                               -- haven't seen it yet

::method process                                  -- process an input record
expose anycase inclusive string seenString
use strict arg record
select
  when seenString then self~write(record,1)       -- a record having the leading string has already passed
  when record~abbrev(string) |,                   -- found the string, respecting case
     anycase & record~caselessAbbrev(string),     -- or disregarding case, when allowed
     then do
    seenString = .true                            -- set flag
    if inclusive then self~write(record)          -- output on 2out starting with the next record
    else self~write(record,1)                     -- or starting now
    end
  otherwise self~write(record)                    -- nope, send to 1out
  end

----------------------------------------------------------------------------------------------------------

::class strWhile public subclass stage            -- select run of records with leading string

::method init
expose anycase string seenString
forward class(super) continue

specs = consume(arg(1),'ANYcase')                 -- ANYCASE keyword
anycase = specs[4] = 1                            -- ignore case

it = delimitedString(specs[1],.false)             -- a delimited string must be next
if it = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
if it[1] \= '' then call noGood self~name, 'excessive options <'it[1]'>'
string = it[2]                                    -- ok, store the string

seenString = .true                                -- we HAVE already seen it

::method process                                  -- process input
expose anycase string seenString
use strict arg record
if seenString & (record~abbrev(string) |,         -- while flag set and string present, respecting case
   anycase & record~caselessAbbrev(string)) then, -- or ignoring case, as the case may be
  self~write(record)                              -- continue writing to the primary output stream
else do                                           -- the record no longer starts with the string
  seenString = .false                             -- clear the flag
  self~write(record,1)                            -- and send to secondary out
  end

----------------------------------------------------------------------------------------------------------

::class take public subclass stage                -- take the first or last N records (opposite of DROP)

::method init                                     -- treat as NOT DROP
expose it                                         -- a .DROP instance
forward class(super) continue
use strict arg specs = ''                         -- specifications
interpret 'it = .drop['self~runsOn']'             -- create a DROP stage

::method ready
expose it                                         -- the DROP created earlier
if self~inStream[!(0)] \= .nil then do
  it~setInStream(0,self~inStream[!(0)])           -- replumbing: our input stream is input for DROP
  self~inStream[!(0)]~setOutStream(0,it,.true)    -- force our input stream to output to DROP
  end
if self~outStream[!(1)] \= .nil then,
  it~setOutStream(0,self~outStream[!(1)])         -- DROP's primary out is our secondary out
if self~outStream[!(0)] \= .nil then,
  it~setOutStream(1,self~outStream[!(0)])         -- and DROP's secondary out is our primary out
it~alias = 'TAKE'
it~prepare(self~trace)                            -- prepare the DROP stage

----------------------------------------------------------------------------------------------------------

::class term public subclass stage                -- TERM is a synonym for CONS

::method init
expose it                                         -- a .CONS
forward class(super) continue
self~runsOn = ''
self~productive = .true
it = .cons~new                                    -- create CONS instance

::method ready
expose it                                         -- the CONS
if self~outStream[!(0)] \= .nil then,
  it~setOutStream(0,self~outStream[!(0)])         -- copy primary output stream to CONS
if self~inStream[!(0)] \= .nil then do            -- primary input stream is connected
  it~setInStream(0,self~inStream[!(0)])           -- copy that too
  self~inStream[!(0)]~setOutStream(0,it,.true)    -- force predecessor stage to write to CONS instead
  end
it~alias = 'TERM'                                 -- set alias
it~prepare(self~trace)                            -- prepare stage

::method begin
expose it
it~begin

----------------------------------------------------------------------------------------------------------

::class var subclass stage public                 -- set variable or send its contents down the pipeline
-- stage under construction...

::method init
expose variable first                             -- target variable and "first input record" flag
forward class(super) continue
use strict arg >varRef                            -- get target variable reference
self~productive = .true                           -- we can run as a first stage
self~runsOn = quote(varRef)
variable = >varRef
first = .true                                     -- raise flag

::method begin                                    -- running first in the pipeline
expose variable                                   -- expose the variable
self~write(variable)                              -- send it down the pipe
self~eof:super                                    -- and signal eof

::method process                                  -- process a record from our predecessor in the pipeline
expose variable first                             -- expose variable name and flag
use strict arg record                             -- retrieve the record

if first then do                                  -- it is the first record we received, set the variable
  variable = record
  first = .false                                  -- reset flag
  end

self~write(record)                                -- then output the input record

::method eof                                      -- EOF - DROP not supported...
expose variable first                             -- expose variable name and flag
if first then do                                  -- no input received from predecessor stage
  drop variable                                   -- drop variable
  first = .false
  end
self~eof:super                                    -- forward to superclass

----------------------------------------------------------------------------------------------------------

::class verify subclass stage public              -- verify that record contains only specified characters

::method init
expose range reference                            -- record range to verify, reference to verify against
forward class(super) continue

specs = consume(arg(1),'ANYcase')                 -- check ANYCASE
anycase = specs[4] = 1

it = inputRange(specs[1])                         -- an input range may be provided
if it[1] then do                                  -- yes
  specs[1] = it[2]                                -- rest of the specs
  range = it~section(3)                           -- retrieve range
  end
else range = .array~of('1,-1')                    -- use the default range, the entire record

reference = delimitedString(specs[1]~strip('t'))  -- find the reference string
if reference = .nil then call noGood self~name, 'invalid delimited string <'specs[1]'>'
if anycase then reference =,                      -- case to disregard
  reference~lower || reference~upper              -- so adapt reference

::method process
expose range reference
use strict arg record

data = applyRange(range,record)                   -- find the operative range
if data~verify(reference) = 0 then,               -- if verified,
  self~write(record)                              -- output the record on the primary output stream
else self~write(record,1)                         -- else send on the secondary one

----------------------------------------------------------------------------------------------------------

::class xlate subclass stage public               -- apply a translation table to each input record
-- supported operands are as in CMS Pipelines, except for INPUT, OUTPUT and TO/FROM codepages other than
-- A2E and E2A (translations from ASCII to EBCDIC and conversely)

::method init
expose ranges table ovr.,                         -- ranges array, translation table, overrides stem,
  apply queue                                     -- apply overrides flag, input queue
forward class(super) continue
use strict arg specs = ''

specs = specs~strip                               -- strip specs
ranges = .array~new                               -- create array

if specs~abbrev('(') then do                      -- a list of input ranges between parentheses
  specs = specs~substr(2)~strip('l')              -- discard the (
  do forever
    if specs~abbrev(')') then do                  -- list ends
      specs = specs~substr(2)~strip               -- remove the )
      leave
      end
    it = inputRange(specs)                        -- get next input range
    if \it[1] then call noGood self~name, 'invalid inputRange at <'specs'>'
    specs = it[2]                                 -- leftover data
    ranges~append(it~section(3))                  -- store the range into the array
    end
  if ranges~items = 0 then call noGood self~name, 'no input ranges provided'
  end
else do                                           -- perhaps a single inputRange is given
  it = inputRange(specs)                          -- test input
  if it[1] then do                                -- one is
    specs = it[2]
    ranges~append(it~section(3))                  -- store it in the array
    end
  else ranges~append(.array~of('1,-1'))           -- translate the entire record by default
  end

w1 = specs~word(1)
select
  when 'UPper'~caselessAbbrev(w1,2) then dft = 1  -- default translation is to uppercase
  when 'LOWer'~caselessAbbrev(w1,3) then dft = 2  -- to lowercase
  when 'A2E'~caselessEquals(w1) then dft = 3      -- ASCII to EBCDIC
  when 'E2A'~caselessEquals(w1) then dft = 4      -- EBCDIC to ASCII
  otherwise dft = 0                               -- use neutral table
  end
if dft > 0 then specs = specs~subWord(2)          -- remove keyword

ovr.0 = 0                                         -- overriding translations may be given
do while specs \= ''
  parse var specs xr.1 xr.2 specs                 -- by pairs of hexranges
  do i = 1 to 2
   it = hexrange(xr.i)
   if it = .nil then call noGood self~name, 'invalid XRANGE <'xr.i'>'
    ovr.0 += 1
    ovr.[ovr.0] = it
   end
  end

if dft = 0 & ovr.0 = 0 then dft = 1               -- no "default table", nor overrides, use uppercase

select case dft
  when 1 then table = xrange()~upper              -- uppercase table
  when 2 then table = xrange()~lower              -- lowercase table
  when 3 then table =,                            -- A2E
    '00010203372D2E2F1605250B0C0D0E0F'x ||,
    '101112133C3D322618193F271C1D1E1F'x ||,
    '404F7F7B5B6C507D4D5D5C4E6B604B61'x ||,
    'F0F1F2F3F4F5F6F7F8F97A5E4C7E6E6F'x ||,
    '7CC1C2C3C4C5C6C7C8C9D1D2D3D4D5D6'x ||,
    'D7D8D9E2E3E4E5E6E7E8E94AE05A5F6D'x ||,
    '79818283848586878889919293949596'x ||,
    '979899A2A3A4A5A6A7A8A9C0BBD0A107'x ||,
    '202122232415061728292A2B2C090A1B'x ||,
    '30311A333435360838393A3B04143EFF'x ||,
    '41AAB0B19FB26AB5BDB49A8ABACAAFBC'x ||,
    '908FEAFABEA0B6B39DDA9B8BB7B8B9AB'x ||,
    '6465626663679E687471727378757677'x ||,
    'AC69EDEEEBEFECBF80FDFEFBFCADAE59'x ||,
    '4445424643479C485451525358555657'x ||,
    '8C49CDCECBCFCCE170DDDEDBDC8D8EDF'x
  when 4 then table =,                            -- E2A
    '000102039C09867F978D8E0B0C0D0E0F'x ||,
    '101112139D8508871819928F1C1D1E1F'x ||,
    '80818283840A171B88898A8B8C050607'x ||,
    '909116939495960498999A9B14159E1A'x ||,
    '20A0E2E4E0E1E3E5E7F15B2E3C282B21'x ||,
    '26E9EAEBE8EDEEEFECDF5D242A293B5E'x ||,
    '2D2FC2C4C0C1C3C5C7D1A62C255F3E3F'x ||,
    'F8C9CACBC8CDCECFCC603A2340273D22'x ||,
    'D8616263646566676869ABBBF0FDFEB1'x ||,
    'B06A6B6C6D6E6F707172AABAE6B8C6A4'x ||,
    'B57E737475767778797AA1BFD0DDDEAE'x ||,
    'A2A3A5B7A9A7B6BCBDBEAC7CAFA8B4D7'x ||,
    '7B414243444546474849ADF4F6F2F3F5'x ||,
    '7D4A4B4C4D4E4F505152B9FBFCF9FAFF'x ||,
    '5CF7535455565758595AB2D4D6D2D3D5'x ||,
    '30313233343536373839B3DBDCD9DA9F'x
  otherwise table = xrange()                      -- neutral table
  end

apply = (ovr.0 > 0)                               -- overrides still to be applied
queue = .queue~new                                -- queue holding records on primary input stream
eofs = 0                                          -- no EOFs yet

::method ready
expose secondary
secondary = (self~inStream[!(1)] \= .nil)         -- secondary input stream is connected
if self~inStream~items > 1+secondary then call noGood self~name, 'too many input streams connected'

::method process
expose ranges table ovr. apply queue secondary

use strict arg record, streamNo = 0

if secondary then select case streamNo            -- secondary input is connected
  when 1 then do                                  -- received a record on that stream
    secondary = .false                            -- clear flag
    it = self~inStream[!(1)]                      -- the input stream
    do i = 1 to it~outStream~last                 -- find its output stream that outputs to us
      stage = it~outStream[i]
      if stage = .nil then iterate
      if stage = self then do                     -- gotcha
        it~setOutStream(?(i),.nil,.true)          -- sever output stream
        leave
        end
      end
    table = record~left(256)                      -- load translation table from the record
    end
  when 0 then do                                  -- primary in, cannot process until we know the table
    queue~queue(record)                           -- so queue the record
    return                                        -- and return
    end
  otherwise nop                                   -- triggered by EOF
  end

if apply then do                                  -- apply overriding translations to the table
  do i = 1 to ovr.0 by 2                          -- do all hexrange pairs
    from.1 = ovr.i
    to.1 = ovr.[i+1]                              -- FROM and TO hexranges
    f = from.1~length
    t = to.1~length
    select
      when t < f then to.1 =,                     -- if TO is shorter,
        to.1 || copies(to.1~substr(t),f-t)        -- repeat its final character
      when t > f then to.1 = to.1~left(f)         -- it is longer, truncate
      otherwise nop
      end
    p = from.1~pos('00'x)                         -- find binary zero
    if p > 1 then do                              -- a wraparound xrange
      parse var from.1 from.1 =(p) from.2         -- split it into two
      parse var to.1 to.1 =(p) to.2               -- at the zero byte
      n = 2
      end
    else n = 1                                    -- a single OVERLAY will do
    do m = 1 to n
      c = from.m~left(1)~c2d                      -- offset of 1st character of FROM.M in a neutral table
      table = table~overlay(to.m,c+1)             -- overlay the actual table with TO.M at that point
      end
    end
  apply = .false                                  -- clear flag
  end

if queue~items > 0 then do forever
  item = queue~pull
  if item = .nil then leave
  self~write(xlate(item))
  end

if streamNo \= -1 then,                           -- unless called by EOF method,
  self~write(xlate(record))                       -- emit the translated input record

return

xlate: use strict arg data                        -- apply translation to all requested ranges
do range over ranges
  it = applyRange(range,data,,,,.true)            -- get start and length of the range
  parse var it from ',' len                       -- as FROM and LEN
  if len > 0 then data = data~overlay(data~,      -- overlay DATA with the translated range
    substr(from,len)~translate(table),from)       -- that starts at position FROM
  end
return data

::method eof
expose queue secondary
use strict arg streamNo = 0                       -- number of the input stream that signals EOF

if streamNo = 1 then secondary = .false           -- EOF on secondary input stream, clear flag
else do                                           -- on primary input
  if queue~items > 0 then self~process(.nil,-1)   -- send a sweep message
  self~eof:super                                  -- forward the EOF
  end

----------------------------------------------------------------------------------------------------------

::class xrange subclass stage public              -- send a hexrange down the pipeline
-- operands are as in CMS Pipelines; a single operand acceptable to REXX XRANGE() may be used as well

::method init
expose xrange                                     -- the literal to emit
forward class(super) continue
self~productive = .true                           -- we must run as a first stage
use strict arg specs = ''

select case specs~words
  when 0 then xrange = xrange()                   -- default is '00'x thru 'ff'x
  when 1 then do                                  -- a single argument
    w1 = specs~strip
    xrange = hexrange(w1)                         -- try an XRANGE first
    if xrange = .nil then xrange = xrange(w1)     -- failed, use REXX XRANGE() option ALNUM, ALPHA etc.
    end                                           -- (which may lead to a syntax error)
  when 2 then xrange =,                           -- start and end characters separated by blanks
    hexrange(specs~word(1)'-'specs~word(2))       -- should form an XRANGE, will give .NIL if not
  otherwise xrange = .nil                         -- too many arguments
  end

if xrange = .nil then call noGood self~name, 'invalid XRANGE <'specs'>'

::method ready
if self~inStream~items > 0 then call noGood self~name, 'must run as the first stage in a pipeline'

::method begin
expose xrange
self~write(xrange)                                -- write the literal
self~eof                                          -- and signal EOF

----------------------------------------------------------------------------------------------------------

::class zone subclass stage public                -- run a selection stage on a zone of the input record
-- this is the only stage expecting two arguments: the zone to filter and the filter to use

::method init
expose range casei reverse filter,                -- the zone, CASEI and REVERSE flags, the stage,
  i2 i3,                                          -- secondary and tertiary input streams for ourselves
  o3                                              -- our tertiary output stream
use strict arg specs = '', filter = .nil          -- specifications and the selector stage
if \filter~isA(.stage) then call noGood self~name, 'second argument must be a stage instance, found <'filter'>'
self~init:super
self~runsOn = quote(specs)','filter~name          -- adjust stage argument for TRACE messages

it = inputRange(specs)                             -- the inputRange should come first
if \it[1] then call noGood self~name, 'invalid input range <'specs'>'
specs = it[2]                                     -- data following the range
range = it~section(3)                             -- the range in question

specs = consume(specs,'CASEI')
casei = specs[4] = 1                              -- ignore case

specs = consume(specs,'REVERSE')
reverse = specs[4] = 1                            -- reverse zone contents before passing it to the filter

if specs[1] \= '' then call noGood self~name, 'excessive options <'specs[1]'>'

i2 = self~connect(1)                              -- create secondary,
i3 = self~connect(2)                              -- and tertiary input streams for ourselves
o3 = self~connect(2,'o')                          -- plus a tertiary output stream to drive the filter

::method ready                                    -- do some plumbing
expose filter i2 i3 o3
filter~setOutStream(0,i2,.true)                   -- register our secondary in as primary out of FILTER
filter~setOutStream(1,i3,.true)                   -- and our 3in as is its secondary out
filter~setInStream(0,o3)                          -- input stream is our 3out
o3~setOutStream(0,filter)                         -- output of 3out is the filter
filter~prepare(self~trace)                        -- prepare the filter stage to run

::method process                                  -- process input
expose range casei reverse inputRecord            -- INPUTRECORD = original input record
use strict arg record, inStream = 0               -- get the record, and the stream it came on

select case inStream
  when 0 then do                                  -- primary input
    inputRecord = record                          -- store record
    it = applyRange(range,record,,,,.true)        -- find range
    parse var it from ',' len                     -- get start and length
    if len = 0 then self~write('',2)              -- out of scope, send a null string to the filter
    else do
      it = record~substr(from,len)                -- take the corresponding substring
      if casei then it = it~upper                 -- uppercase it for CASEI
      if reverse then it = it~reverse             -- and reverse it for REVERSE
      self~write(it,2)                            -- send the data to the filter
      end
    end
  when 1 then self~write(inputRecord)             -- secondary input = primary output of the filter
  otherwise self~write(inputRecord,1)             -- rejected by filter, send original to secondary out
  end

::method eof                                      -- EOF, necessarily on our primary in
self~setOutStream(2,.nil,.true)                   -- sever tertiary output stream
self~eof:super                                    -- and forward the EOF

----------------------------------------------------------------------------------------------------------

::routine !                                       -- translate a stream number into an array index
return arg(1)+1

----------------------------------------------------------------------------------------------------------

::routine ?                                       -- translate an array index into a stream number
return arg(1)-1

----------------------------------------------------------------------------------------------------------

::routine quote                                   -- return a string that evaluates as our argument

return ''''arg(1)~changeStr('''','''''')''''      -- repeat each single quote, and wrap in single quotes

----------------------------------------------------------------------------------------------------------

::routine delimitedString                         -- get a delimited string, may be given in binary or hex

use strict arg data, noExtraneous = .true,,       -- input; by default: don't allow extraneous data
  noSubsequentNonBlank = .true                    -- and don't allow non-blank character immediately after

data = data~strip                                 -- have the input stripped
delim = data~left(1)                              -- get delimiter character
len = data~length                                 -- data length
i = data~pos(delim,2)                             -- second occurrence of the delimiter

if i > 0 then do                                  -- found
  if noExtraneous then do                         -- argument must be a complete delimited string
    if i < len then return .nil                   -- extraneous data present
    return substr(data,2,len-2)                   -- return the string - which may be null
    end
  else do                                         -- other characters may follow
    if noSubsequentNonBlank &,                    -- non-blank following the delimiter not allowed
      data~substr(i+1,1) \= '' then return .nil   -- error
    return .array~of(data~substr(i+1),,           -- return any leftover data
      data~substr(2,i-2))                         -- plus the requested string
    end
  end
else do                                           -- string may be specified binarily or hexadecimally
  i = 'BHX'~caselessPos(delim)                    -- type must be B (for binary), or H or X (for hex)
  select case i
    when 0 then return .nil                       -- bad type
    when 1 then it = '01'                         -- binary string
    otherwise it = xrange('xdigit')               -- hexadecimal string (I is 2 or 3)
    end
  j = data~verify(it,,2)                          -- find non-digit from position 2 onwards
  if noExtraneous then do                         -- NOEXTRANEOUS in effect
    if j > 0 then return .nil                     -- contains invalid digits
    w1 = data~substr(2)                           -- load data following the type
    end
  else do
    if j = 0 then do                              -- no non-digits found
      w1 = data~substr(2)                         -- load string
      rest = ''                                   -- no data left over
      end
    else do                                       -- non-digit found at position J
      w1 = data~substr(2,j-2)                     -- load string
      rest = data~substr(j)                       -- leftover data
      if noSubsequentNonBlank &,                  -- non-blank following the string not allowed
        rest~left(1) \= '' then return .nil       -- error
      end
    end
  len = w1~length                                 -- length of the binary or hexadecimal string
  if i = 1 then do                                -- type is binary
    if len < 8 | len~modulo(8) > 0 then,          -- length should be a positive multiple of 8
      return .nil
    it = w1~b2x~x2c                               -- ok, convert it to hex and thence to characters
    end
  else do                                         -- type is hex
    if len < 2 | len~modulo(2) = 1 then,          -- length should be a positive even number
      return .nil
    it = w1~x2c                                   -- ok, convert hexadecimal to characters
    end
  if noExtraneous then return it                  -- NOEXTRANEOUS, just return the converted string
  return .array~of(rest,it)                       -- else make sure to return remaining input as well
  end

----------------------------------------------------------------------------------------------------------

::routine inputRange                              -- return an inputRange

use strict arg text, rangePart = .false           -- the text to figure out, rangePart flag

items = .array~of(.false,'')                      -- ok flag and what will remain of the text

if \rangePart then do                             -- skip initial WS/FS and SUBSTRING tests for rangeParts
  text = consume(text,'WORDSEParator','WS',,      -- check for WORDSEPARATOR or FIELDSEPARATOR keywords
    'FIELDSEParator','FS')
  do while text[4] > 0                            -- handle these first; any number of them may be present
    call handleSeparator                          -- extract separator character
    text = consume(text,'WORDSEParator','WS',,    -- there may be further WS's or FS's
      'FIELDSEParator','FS')
    end
  text = consume(text,'SUBSTRing')                -- test for "SUBSTRING rangePart OF"
  do while text[4] = 1                            -- SUBSTR keyword found
    sub = inputRange(text[1],.true)               -- fetch the rangePart
    if \sub[1] then return items                  -- no good
    items~append('SUB')                           -- ok, add a marker
    items~appendAll(sub~section(3))               -- plus the rangePart
    text = consume(sub[2],'OF')                   -- OF keyword expected now
    if text[4] = 0 then return items              -- missing
    text = consume(text,'SUBSTRing')              -- test for another SUBSTRing
    end
  end

text = consume(text,'WORDSEParator','WS',,        -- check again for separators
  'FIELDSEParator','FS')
if text[4] > 0 then call handleSeparator          -- and handle

control = ''                                      -- assume that WORDS and FIELDS aren't specified
p = text[1]~verify('-0123456789' '09'x,'m')       -- a number may immediately follow these keywords

if p > 1 then do                                  -- found white space or numeric at or beyond position 2
  q = consume(text[1]~left(p-1),'Words','Fields') -- look for WORDS and FIELDS keywords
  if q[4] > 0 then do                             -- found one
    control = 'WF'~substr(q[4],1)                 -- set control field to W or F
    text[1] = text[1]~substr(p)~strip('l')        -- store remainder, to be parsed by the RANGE routine
    end
  end

range = range(text[1],.true)                      -- rest must be a normal column range
if \range[1] then return items                    -- range invalid

items[1] = .true                                  -- was a tremendous success
items[2] = range[2]                               -- remaining text
items~append(control||range[3])                   -- add column range prefixed by control field
return items

handleSeparator:                                  -- process a separator character
xorc = xorc(text[2])                              -- given as an XORC (single character or 2 hex nibbles)
if xorc = .nil then return items                  -- no good
if text[4] < 3 then items~append('WS'xorc)        -- add a WS or an FS item
else items~append('FS'xorc)
text[1] = text[3]                                 -- consume the XORC
return

----------------------------------------------------------------------------------------------------------

::routine range                                   -- return an input or output column range

use strict arg text,,                             -- text to parse
  inputRange = .false,,                           -- for an input range
  outputRange = .false                            -- for an output range

results = .array~of(.false)                       -- results array with ok flag primed to "failed"

parse var text w1 rest                            -- first word and remainder of text

if inputRange then do                             -- accept signed numbers on input ranges
  if w1~pos(';') > 0 then do
    parse var w1 r1 ';' r2                        -- get start and end of range
    r2 = numericPart(r2,.true)                    -- find the numeric part of R2, accepting a minus sign
    if \r1~datatype('w') | r1 = 0 |,              -- R1 must be a non-zero whole number
       \r2~datatype('w') | r2 = 0 |,              -- error when R2 isn't a nonzero integer, or when
       r2 < r1 & (r1 < 0 | r2 > 0) then,          -- both are of the same sign and R2 is smaller than R1
      return results
    results[1] = .true                            -- succeeded
    results[2] = rest~strip('l')                  -- excess data
    results[3] = r1','r2                          -- range is "from R1 to R2, inclusive"
    return results
    end
  else if \w1~contains('.') then do               -- no period present
    w1 = numericPart(w1,.true)                    -- get numeric part of W1, allowing "-"
    if w1~datatype('w') & w1 \= 0 then do         -- single column
      results[1] = .true                          -- success
      results[2] = rest~strip('l')                -- leftover input
      results[3] = w1','w1                        -- range is "from position W1 to position W1"
      return results
      end
    else nop                                      -- fall through
    end
  end

if w1~contains('-') then do                       -- a normal number range
  parse var w1 r1 '-' r2                          -- get begin and end
  r2 = numericPart(r2,,.true)                     -- numeric or asterisk only
  if \outputRange then do                         -- (generalized) input range
    if r1 = '*' then r1 = 1                       -- * means: beginning of the record
    if r2 = '*' then r2 = -1                      -- or the end of the record for R2
    end
  if \r1~datatype('w') | \r2~datatype('w') |,     -- both must be positive integers
    r1 < 1 | (r2 < r1 & r2 \= -1) then,           -- and R2 must be -1 or >= R1
    return results
  results[1] = .true                              -- all was well
  results[2] = rest~strip('l')                    -- data remaining
  results[3] = r1','r2                            -- "from R1 to R2, inclusive"
  return results
  end
else if w1~contains('.') then do                  -- column plus range length
  parse var w1 r1 '.' r2                          -- find begin and length
  r2 = numericPart(r2)                            -- for R2, use the numeric part
  if \outputRange & r1 = '*' then r1 = 1          -- * is: start of record (not for an output range)
  if \r1~datatype('w') | \r2~datatype('w') |,     -- both must be integers,
    r1 < 1 | r2 < 0 then return results           -- R1 positive and R2 non-negative
  results[1] = .true                              -- ok
  results[2] = rest~strip('l')                    -- data remaining
  results[3] = r1','r1+r2-1                       -- set from and end positions
  return results
  end

w1 = numericPart(w1)
if \w1~datatype('w') | w1 < 1 then,               -- a single position, must be a positive whole number
  return results

results[1] = .true                                -- set OK flag
results[2] = rest~strip('l')                      -- remaining data
if outputRange then results[3] = w1               -- an output range, just store the output column
else results[3] = w1','w1                         -- input range, also indicate end column

return results                                    -- return the range

numericPart: use strict arg string,,              -- find the numeric initial part of a string
  negative = .false, star = .false                -- don't accept a minus sign or an asterisk
if star & string~abbrev('*') then do              -- asterisk
  rest = string~substr(2) rest                    -- add any other data to variable REST
  return '*'                                      -- return the asterisk
  end
p = string~,                                      -- find beginning of non-numeric data,
  verify('0123456789'copies('-',negative))        -- allowing or disallowing a minus sign
if p = 0 | string~pos('-') > 1 then return string -- not found, or minus not in position 1, leave alone
if p > 0 then do                                  -- data was found
  rest = string~substr(p) rest                    -- add to REST
  return string~left(p-1)                         -- & remove from string
  end
else return string                                -- entire string was numeric

----------------------------------------------------------------------------------------------------------

::routine applyRange                              -- apply a range to a given record

use strict arg range, record,,                    -- the range and the record to apply it to
  ws = ' ', fs = '09'x,,                          -- optional word/field separator characters
  forChange = .false,,                            -- invoked by stage CHANGE: return starting position
  specify = .false                                -- return starting position and length instead of data

effectiveFROM = 1                                 -- FROM position in the original record

do i = 1 to range~items
  item = range[i]                                 -- inspect range item
  select
    when item~abbrev('WS') then ws =,             -- overriding word separator, set character
      item~substr(3,1)
    when item~abbrev('FS') then fs =,             -- field separator
      item~substr(3,1)
    when item = 'SUB' then do                     -- SUBSTRing
      do j = i+1 to range~items
        select
          when range[j]~abbrev('WS') then ws =,   -- process any separators first
            range[j]~substr(3,1)
          when range[j]~abbrev('FS') then fs =,
            range[j]~substr(3,1)
          otherwise leave
          end
        end
      item = range[j]                             -- range item to apply to result of following recursion:
      it = applyRange(range~section(j+1),record,, -- apply the rest of the range array to the record
        ws,fs,,.true)
      parse var it from ',' len                   -- get start and length
      effectiveFROM += from-1                     -- adjust effective FROM position
      record = record~substr(from,len)            -- resulting record
      if len = 0 then leave                       -- this range out of scope
      it = applyRangeItem(item,record,ws,fs,,     -- apply range item to the result, under given options
        forChange)
      parse var it from ',' len                   -- find start and length
      effectiveFROM += from-1                     -- adjust effective FROM again
      if \forChange & \specify then record =,     -- neither FORCHANGE nor SPECIFY applies
        record~substr(from,len)                   -- take the SUBSTRING
      leave                                       -- all range items have been processed, quit
      end
    otherwise do
      it = applyRangeItem(item,record,ws,fs,,     -- apply the range item
        forChange)
      parse var it from ',' len
      effectiveFROM += from-1                     -- adjust FROM position in original record
      if forChange then do                        -- invoked by CHANGE when the needle is the null string
        if from < 2 then return from
        end
      else if \specify then record =,             -- not SPECIFY, so return data rather than FROM, LEN
        record~substr(from,len)
      end
    end
  end

select                                            -- return the requested information
  when forChange then return effectiveFROM
  when specify then return effectiveFROM','len
  otherwise return record
  end

----------------------------------------------------------------------------------------------------------

::routine applyRangeItem                          -- apply a single range item to a given record

use strict arg range, record,,                    -- range and record
  ws = ' ', fs = '09'x,,                          -- optional word and field separators
  forChange = .false                              -- this is for CHANGE, return start only

select                                            -- check range type
  when range~abbrev('W') then do                  -- word range
    if range~abbrev('WS') then,                   -- a WS just for this input field
      parse var range 3 sep 4 range               -- get the separator and the actual range
    else do
      sep = ws                                    -- use specified word separator
      range = range~substr(2)                     -- extract range
      end
    parse var range from ',' to                   -- range start and end
    firstNonseparator = record~verify(sep)        -- get position of first non-separator character
    if firstNonseparator > 0 then do              -- words exist
      len = 0                                     -- init word length
      ix = firstNonseparator
      do while ix > 0
        len += 1                                  -- found another word
        ix = record~verify(sep,'m',ix+1)          -- position of next separator
        if ix = 0 then leave                      -- not found
        ix = record~verify(sep,,ix+1)             -- next non-separator
        end
      if from <= len then do                      -- in range
        if from < 0 then from +=len+1             -- negative is relative to record end
        if forChange then do                      -- for CHANGE, ignore TO
          if from < 1 then return 1               -- FROM too small, return "preface"
          return wIndex(record,from)              -- return "before position of FROMth word"
          end
        if to < 0 then to += len+1                -- adjust TO similarly
        from = max(from,1)                        -- FROM can't be less than 1
        to = min(to,len)                          -- TO cannot exceed word count, clip if necessary
        if to >= from then do                     -- word range nonempty
          from = wIndex(record,from)              -- starting position of the FROMth word
          if to = len then to = record~length     -- TO is the final word, position at end
          else to = wIndex(record,to+1)-1         -- word TO+1 exists, position before it
          do while record~substr(to,1) == sep     -- while character is a separator
            to -= 1                               -- back up
            end
          return from','to-from+1                 -- return start and length
          end                                     -- else computed TO < computed FROM, fall thru
        end                                       -- else out of range, fall thru
      else if forChange then return 0             -- except for CHANGE - in which case return "append"
      end                                         -- no words in record, fall thru
    else if forChange then do                     -- except when we are called by CHANGE
      if from > 0 then return 0                   -- if FROM is positive, append
      else return 1                               -- else preface
      end
    end
  when range~abbrev('F') then do                  -- field range
    if range~abbrev('FS') then,                   -- an FS just for this input field
      parse var range 3 sep 4 range               -- get separator and range proper
    else do
      sep = fs                                    -- employ the provided field separator
      range = range~substr(2)                     -- extract range proper
      end
    parse var range from ',' to                   -- find range start, end
    len = record~countStr(sep)+1                  -- field count is # separators present in the record + 1
    if from <= len then do                        -- in scope
      if from < 0 then from += len+1              -- negative is relative to record end, compute actual FROM
      if forChange then do                        -- forChange, ignore TO
        if from < 1 then return 1                 -- FROM still too small, return "preface"
        i = 1                                     -- start at position 1
        do from-1                                 -- skip earlier fields
          i = record~pos(sep,i)+1                 -- locate next separator, and position after it
          end
        return i                                  -- field FROM sits at position I
        end
      if to < 0 then to += len+1                  -- TO negative, compute actual value
      from = max(from,1)                          -- FROM can't be less than 1
      to = min(to,len)                            -- TO can't exceed field count
      if to >= from then do                       -- field range non-empty
        i = 1                                     -- initialize the position to 1
        do from-1                                 -- skip earlier fields
          i = record~pos(sep,i)+1                 -- locate next separator and position after it
          end
        if to = len then,                         -- TO is the last field
          return i','record~length-i+1            -- return "from FROM through record end"
        pos = i                                   -- FROM is at position I
        do to-from+1                              -- find the separator preceding field TO+1
          i = record~pos(sep,i)+1                 -- locate next one, and position after it
          end
        return pos','i-pos-1                      -- and return start and length
        end                                       -- empty field range, fall through
      end                                         -- out of scope, fall through
    else if forChange then return 0               -- except when FORCHANGE, in which case return "append"
    end
  otherwise do                                    -- an ordinary column range
    len = record~length                           -- record length
    parse var range from ',' to                   -- get FROM and TO values
    if forChange then do                          -- position requested; will be valid when >= 0
      if from > 0 then do
        if from <= len+1 then return from         -- 1 <= FROM <= LEN+1, never mind TO
        else return -1                            -- out of scope
        end
      else from += len+1                          -- FROM can't be zero, so it must be negative
      if to < 0 then to += len+1                  -- TO negative, find intended TO
      if from > 0 then do
        if to >= from-1 then return from          -- valid or within an inch from
        return -1                                 -- else range out of scope
        end
      return 1                                    -- computed FROM is less than 1, return "preface"
      end
    else if from <= len then do                   -- substring requested
      if from < 0 then from += len+1              -- negative is relative to record end, adjust FROM
      if to < 0 then to += len+1                  -- TO negative, adjust
      from = max(from,1)                          -- FROM cannot be less than one
      to = min(to,len)                            -- TO can't exceed record length
      if to >= from then return from','to-from+1  -- the substring exists
      end                                         -- else fall thru to return "out of range"
    end
  end

return '1,0'                                      -- out of range

wIndex: use strict arg string, number             -- true word index, ignoring whitespace other than BLANK
count = 0                                         -- initialize word count
ix = firstNonseparator                            -- position of first non-separator
do while ix > 0
  count += 1                                      -- another word
  if count = number then return ix                -- wordIndex determined
  ix = string~verify(sep,'m',ix+1)                -- next separator
  if ix = 0 then leave                            -- not present
  ix = string~verify(sep,,ix+1)                   -- next non-separator
  end
return 0                                          -- return zero when word number NUMBER does not exist

----------------------------------------------------------------------------------------------------------

::routine xorc                                    -- return an XORC character value

use strict arg xorc

if xorc = '' then return .nil                     -- no input

select                                            -- determine the character
  when xorc~length = 1 then return xorc           -- a single character, use as is
  when xorc~length = 2 & xorc~datatype('x'),      -- single character given hexadecimally
    then return xorc~x2c                          -- convert to character
  when 'BLANK SPACE'~caselessWordPos(xorc) > 0,   -- BLANK or SPACE keyword
    then return ' '                               -- return blank
  when 'TABULATE'~caselessAbbrev(xorc,3),         -- keyword TABULATE can be abbreviated to TAB
    then return '09'x                             -- return a tab character
  otherwise return .nil                           -- not a valid XORC
  end

----------------------------------------------------------------------------------------------------------

::routine hexrange                                -- return an XRANGE (hexademal character range)

use strict arg hexrange

if pos(' ',hexrange) > 0 then return .nil         -- embedded blanks not permitted

select
  when hexrange~pos('-') > 0 then do              -- range was specified as a "from-to" range
    parse var hexrange r1 '-' r2                  -- find from and to
    r1 = xorc(r1)                                 -- get XORC
    if r1 = .nil then return .nil                 -- failed
    r2 = xorc(r2)                                 -- same for end value
    if r2 = .nil then return .nil
    return xrange(r1,r2)                          -- use REXX builtin
    end
  when hexrange~pos('.') > 0 then do              -- range length given
    parse var hexrange r1 '.' r2
    r1 = xorc(r1)                                 -- get range start XORC
    if r1 = .nil then return .nil                 -- no good
    if \r2~datatype('w') | r2 < 1 then,           -- length not a positive integer
      return .nil
    d1 = r1~c2d                                   -- find decimal value of "from" character
    d2 = (d1+r2-1)~modulo(256)                    -- add range length mod 256
    return xrange(r1,d2~d2c)                      -- return the derived XRANGE
    end
  otherwise do                                    -- must be a single XORC
    r1 = xorc(hexrange)                           -- get it
    if r1 = .nil then return .nil                 -- invalid
    return r1                                     -- ok, return intended character
    end
  end

----------------------------------------------------------------------------------------------------------

::routine consume                                 -- consume (an abbreviation of) a specification operand

specs = arg(1)                                    -- array used for parsing stage specifications
if \specs~isA(.array) then,                       -- a string was passed rather than an array
  specs = .array~of(specs)                        -- turn it into an array
w1 = specs[1]~word(1)                             -- get first word

do a = 2                                          -- process remaining arguments
  if \arg(a,'e') then do                          -- done all
    specs[1] = specs[1]~strip                     -- strip string
    specs[2] = w1                                 -- save word
    specs[3] = specs[1]~subWord(2)                -- and text following it
    specs[4] = 0                                  -- no arguments were matched
    return specs                                  -- return the results array
    end
  len = arg(a)~verify(xrange('lower'),'m')-1      -- position of first lowercase character minus one
  if len < 0 then len = arg(a)~length             -- none present, match entire the keyword
  if arg(a)~caselessAbbrev(w1,len) then do        -- an abbreviation of the keyword is matched
    specs[1] = specs[1]~subWord(2)                -- consume the keyword
    specs[2] = specs[1]~word(1)                   -- save next word
    specs[3] = specs[1]~subWord(2)                -- and the text following it
    specs[4] = a-1                                -- sequence number of matching keyword
    return specs                                  -- return results
    end
  end

----------------------------------------------------------------------------------------------------------

::routine noGood                                 -- report an error

say arg(1)':' arg(2)                             -- explain the problem

raise syntax 88.900 array (arg(2))               -- and raise an "invalid argument" error