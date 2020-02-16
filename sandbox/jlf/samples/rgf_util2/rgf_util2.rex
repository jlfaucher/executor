/*
      url to documentation and reference card (as of 2010-05-14):
                  http://wi.wu.ac.at/rgf/rexx/orx20/

      author:     Rony G. Flatscher, copyright 2008-2011, all rights reserved
      date:       2007-06-01 - 2007-06-02; 2007-07-30; 2007-08-02, 2007-08-07, 2007-08-15,
                  2007-10-20, 2007-10-23
                  2007-12-30 - made NumberComparator more flexible, allows to use
                               intermixed non-numbers, if programmer wishes to do so
                             - MessageComparator: now allows collection of message-names
                               and/or message objects to use for comparisons
                  2008-01-08 - added "/numeric" hint for message names
                  2008-02-15 - changed StringComparator to be more flexible with its
                               argument
                  2008-02-16 - changed StringComparator to be simpler & more flexible,
                               as well as sort2, stableSort2; created samples (f:\test\orx\rgf_util2)
                  2008-02-17 - changed/improved StringColumnComparator, created samples for it
                  2008-02-19 - removed usage of built-in comparators in sort2() and
                               stableSort2(), so none of the 3.2.0 specialized
                               Comparators are needed
                             - added "-length" to ABBREV2(),
                  2008-02-20 - added "-count" to CHANGESTR2() ("change last 'count' needle occurrences)
                             - added negative starting position to lastPos2()
                             - added left2()-BIF, handling with negative start position
                             - added right2()-BIF, handling with negative start position
                             - added/enhanced pos2()-BIF with negative start position
                  2008-02-21 - added DELSTR2(), LOWER2(), SUBSTR2(), UPPER2()
                               which now all accept negative numbers
                  2008-02-22 - added OVERLAY2(), which now accepts negative numbers
                  2008-02-25 - added PARSEWORDS2()
                  2008-03-13 - changed DUMP2 to cater for the different kind of collections,
                               ones), will not sort OrderedCollections, but honor their order
                               [will show exact array-index values (including multi-dimensional],
                               will sort by index-value otherwise, in the case of "allAt"-collections
                               (e.g. Relation) will give a list of the items associated with the
                               same index
                  2008-03-14 - changed DUMP2() to display item, if allAt() returns a collection
                               containing only one item; added SUBCHAR2() allowing negative
                               positions as well
                               added negative position to WORDPOS2()
                               added DELWORD2, SUBWORD2(), WORD2(), WORDINDEX2(), WORDLENGTH2()
                  2008-03-16 - tested and fixed StringOfWords class
                  2008-03-19 - recoded sort2() and stableSort2() to take advantage of .StringComparator
                               and .StringColumnComparator
                  2008-03-27 - allow in list of messages array-elements with two entries, where
                                  - arr[1]=messageString|messageObject
                                  - arr[2]=flagString
                             - added option "M" (message sort) to sort2() and stableSort2()
                  2008-03-29, - sort2() and stableSort2() now accept as their first argument
                                an object with a "makeArray" method in addition to instances
                                of array
                              - .MessageComparator: if an array-element is given, then index 3 in
                                addition to index 2 are regarded to be flag (parts)
                  2008-03-16: - dump2 now gracefully deals with non-collection and non-supplier
                                objects: an appropriate hint is given, as well as the type and
                                (string) value of the argument
                  2009-03-15: - changed default of string-routines to use the "caseless"
                                version
                  2009-03-20: - changed NumericComparator to use caseless comparison in case
                                relaxed comparisons are carried out
                              - change default sort2() and stableSort2() to use "N", i.e.
                                ascending sort with numeric comparisons, and caseless comparisons
                              - added MakeArray to class StringOfWords

                  2009-12-14: - make sure all public routines have a trailing "2" to indicate that
                                they come from this package and to avoid name clashes with earlier
                                implementations
                  2009-12-19: - changed default for sort2() and stableSort2() to "ignore case", if
                                string objects are to be sorted
                  2009-12-22: - When creating a NumberComparator one can now determine the order (A|D)
                                and kind of comparison (I | C)
                  2009-12-26: - default to "I"gnore case in .StringColumnComparator
                              - parseWords2: if returning position array, supply third array element
                  2009-12-27: - .StringOfWords:
                                - delWord(): make sure dirty flags are set
                                - subWord(): don't change string itself, if returning subwords
                                - wordPos(): default for compare now "I[gnore]" case
                  2009-12-28: - .StringOfWords:
                                - delWord(): do not edit string in place, return an edited copy
                  2010-01-16, change "rgf.numbers" to "rgf.digits" (thanks to Walter Pachl!)
                  2010-08-15, .NumberComparator ignored second argument (order) in constructor,
                              if first argument was set to .true (thanks to Glenn Knickerbocker
                              on comp.lang.rexx)
                  2011-05-30, - fix error not allowing suppliers to be shown in dump2(); this
                                follows Jean-Louis fix in his ooRexx sandbox as of 2011-05-30;
                                also changed sequence of argument checking to follow sequence
                                of arguments as seen in Jean-Louis' version of rgf_util2.rex
                  2011-06-08, - new routine ppCondition2(co[,bShowPackage=.false [,indent1="09"x [,indent2="0909"x [,indent3="090909"x [,lf=.endOfLine]]]]]]):
                                returns a string rendering of the supplied condition object "co"

                              - new routine ppPackage2(package[,indent1=""[, indent2="09"x[, lf==.endOfLine]]):
                                returns a string rendering of the supplied package object
                  2011-08-03, - ppCondition2(): make sure that length is only calculated, if a string in hand
                  2017-02-18, - ppCondition2(): add additional information to stackframe output to ease debugging


      purpose:    set of 3.2 utilities to ease programming of 3.2.0, e.g. offer sort2()- and
                  stableSort2()-BIFs that handle all kind of standard sorting needs, thereby
                  removing the need for "low level" coding in ooRexx itself

      TODO:       - ? create a DateTime2 class with renaming existing conversion
                    methods to start with "to"; also supply epoch-related
                    conversions (from/to); also allow to define the date
                    when Julian calendar took effect; supply method to determine
                    Easter Sunday (depending on the calendar in use)

                  - create routines "leftWord([-]n)", "rightWord([-]n)"

      license:    Choice of
                  ASF 2.0, <http://www.apache.org/licenses/LICENSE-2.0>:
                  --------------- cut here ----------------
                     Copyright 2008-2017 Rony G. Flatscher

                     Licensed under the Apache License, Version 2.0 (the "License");
                     you may not use this file except in compliance with the License.
                     You may obtain a copy of the License at

                         http://www.apache.org/licenses/LICENSE-2.0

                     Unless required by applicable law or agreed to in writing, software
                     distributed under the License is distributed on an "AS IS" BASIS,
                     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
                     See the License for the specific language governing permissions and
                     limitations under the License.
                  --------------- cut here ----------------

                  or

                  LGPL 3.0, <http://www.fsf.org/licensing/licenses/lgpl.html> (as of: 2008-02-17)

      version:    1.0.6
*/

.local~rgf.non.printable=xrange("00"x,"1F"x)||"FF"x
.local~rgf.alpha.low="abcdefghijklmnopqrstuvwxyz"
.local~rgf.alpha.upper =.rgf.alpha.low~upper
.local~rgf.alpha    =.rgf.alpha.low || .rgf.alpha.upper
.local~rgf.digits   ="0123456789"
.local~rgf.alphanumeric=.rgf.alpha  || .rgf.digits

.local~rgf.symbol.chars=".!_?"

.local~rgf.showIdentityHash = .false -- JLF

parse version "_" v "("

if v<4 then       -- ooRexx smaller than 4.0.0, then use ".public_routines"
do
      -- make version"2" BIFs globally available
   do idx over .methods
     .public_routines~put(.methods[idx], idx)
   end

      -- make the classes seen globally via .local directory
   .local~messageComparator     =.messageComparator
   .local~NumberComparator      =.NumberComparator
   .local~StringComparator      =.StringComparator
   .local~StringColumnComparator=.StringColumnComparator
   .local~StringOfWords         =.StringOfWords
end
else  -- running under ooRexx 4.0.0 or higher
do
    thisPackage=.context~package
    do idx over .methods
       -- routine=.routine~new(idx, .methods[idx]~source)
       routine=.routine~new("DYNAMICALLY_CREATED_"idx, .methods[idx]~source)
       thisPackage~addPublicRoutine(idx, routine)
    end

      -- make the classes seen globally via the package's public classes
   thisPackage~addPublicClass("MessageComparator"     , .messageComparator     )
   thisPackage~addPublicClass("NumberComparator"      , .NumberComparator      )
   thisPackage~addPublicClass("StringComparator"      , .StringComparator      )
   thisPackage~addPublicClass("StringColumnComparator", .StringColumnComparator)
   thisPackage~addPublicClass("StringOfWords"         , .StringOfWords         )
end


::routine rgf_util_extended public
  -- JLF :
  -- To let test if the extended version of rgf_util2.rex is loaded
  -- dump2 and pp2 takes more arguments in this extended version.


::routine interpreter_extended public
    -- Temporary helper, maybe I will put in place something better...
    -- In Executor
    --     The tokenizer has been modified to split a symbol of the form <number><after number> in two distinct tokens.
    --     0a is the number 0 followed by the symbol a. If a=0 then 0a is (0 "" 0) = "00"
    -- In Official ooRexx, 0a is parsed as "0A" and is not impacted by the value of the variable a.
    a = 0
    return 0a == "00"


/* ======================================================================= */
/* === methods to be used for new BIFs                                 === */
/* ======================================================================= */

   -- 2008-02-19, rgf:   abbrev      info, string [, n-length]
   /* if length is negative, then  */
/* ======================================================================= */
::method "abbrev2"
  use strict arg arg1, arg2, ...

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArgs=4

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="abbrev"        -- base name for the message to send

  bCaseDependent =.false   -- default to caseless version
  if argNr>=BIFpos, \datatype(arg(argNr),"N")  then
  do
     letter=arg(argNr)~strip~left(1)~upper
     if pos(letter,"CI")=0 then     -- illegal argument!
        raise syntax 93.914 array (argNr, "C, I", arg(argNr))
     bCaseDependent=(letter="C")
     argNr-=1              -- decrease one from total number of arguments
  end

  newArr=.array~new        -- create new array for the arguments
  newArr[1]=arg2           -- save info
  if arg(3,"Exists"), datatype(arg(3),"N") then
  do
     arg3=arg(3)           -- negative?
     if arg3<0 then        -- length, i.e. extract from right
     do
        newArr[1]=arg2~right(-arg3) -- get the chars from the right
     end
     else
     do
        newArr[2]=arg3
     end
  end

      -- now invoke the operation
  if bCaseDependent then
     return .message~new(arg(1), methName,           "A", newArr)~send
  else
     return .message~new(arg(1), "caseless"methName, "A", newArr)~send

syntax:
  raise propagate

/* ======================================================================= */
/* if count is negative, then the number of changes occur from the right side
   ("change the last 'count' of 'needle' occurrences in string")
*/
::method "changeStr2"   -- (needle,haystack,newNeedle[,[-]count][,CI])
  use strict arg arg1needle, arg2haystack, arg3newNeedle, ... -- make sure at least three args are supplied
  parse arg arg1needle, arg2haystack, arg3newNeedle, arg4count

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last mandatory BIF argument position
  maxArgs=5

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="changeStr"     -- base name for the message to send

  bCaseDependent =.false   -- default to caseless version

  newArr=.array~new        -- create new array for the arguments
  newArr[1]=arg1needle
  newArr[2]=arg3newNeedle

  signal on syntax
  if argNr>(BIFpos) then   -- either count or "CI"
  do
     count=.nil
     if \datatype(arg(argNr),"W")  then   -- "C" or "I"
     do
        letter=arg(argNr)~strip~left(1)~upper
        if pos(letter,"CI")=0 then     -- illegal argument!
           raise syntax 93.914 array (argNr, "C, I", arg(argNr))
        bCaseDependent=(letter="C")

        if argNr>4, arg(4,"E") then -- check for "count" argument
           count=arg4count    -- save count-value
     end
     else
        count=arg4count       -- save count-value
  end

  if datatype(count,"N") then -- count is numeric, check it out
  do
     if count<0 then       -- change the "count" last occurrences in string!
     do
         -- search starting position for changes
        len=length(arg2haystack) -- remember length of string
        pos=len                  -- start out with last position of string

            -- find starting position
        do i=1 to -count until pos=0
           oldPos=pos

           if oldPos<=1 then leave   -- already at beginning!
           if bCaseDependent then
           do
              pos=        lastPos(arg1needle, arg2haystack, oldPos-(1-(len=oldPos)))
           end
           else   -- ignore case
           do
              pos=lastPos2(arg1needle, arg2haystack, oldPos-(1-(len=oldPos)), "I")
           end
        end

         -- carry out the changes
        if oldPos>1, pos>0 then  -- o.k., not all "needle"s to change: split, change and return
        do
            -- extract part that does not get changed
           mb=.MutableBuffer~new~~append( arg2haystack~substr(1,Pos-1) )

            -- change needle in remainder, add changed string to MutableBuffer
           if bCaseDependent then
              mb~append( .message~new(arg2haystack~substr(Pos), methName,           "A", newArr)~send)
           else
              mb~append( .message~new(arg2haystack~substr(Pos), "caseless"methName, "A", newArr)~send)
           return mb~string      -- return changed string
        end
     end
     else
     do
        newArr[3]=arg4count      -- save "count" argument
     end
  end

      -- now invoke the operation
  if bCaseDependent then
     return .message~new(arg2haystack, methName,           "A", newArr)~send
  else
     return .message~new(arg2haystack, "caseless"methName, "A", newArr)~send

syntax:
  raise propagate

/* ======================================================================= */
-- string1, string2[, [padChar] [,{C|I}]]
::method "compare2"
  use strict arg arg1string1, arg2string2, arg3padChar=" ", ...

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArg=4

  signal on syntax
  if argNr>maxArg then     -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArg)

  methName="compare"       -- base name for the message to send

  bCaseDependent =.false   -- default to caseless version
  if argNr>BIFpos then
  do
     letter=arg(maxArg)~strip~left(1)~upper
     if pos(letter,"CI")=0 then     -- illegal argument!
        raise syntax 93.914 array (argNr, "C, I", arg(maxArg))
     bCaseDependent=(letter="C")
     argNr-=1              -- decrease one from total number of arguments
  end

  newArr=.array~new        -- create new array for the arguments
  newArr[1]=arg2string2    -- other string
  newArr[2]=arg3padChar    -- pad character

      -- now invoke the operation
  if bCaseDependent then
     return .message~new(arg1string1, methName,           "A", newArr)~send
  else
     return .message~new(arg1string1, "caseless"methName, "A", newArr)~send

syntax:
  raise propagate


/* ======================================================================= */
-- not a BIF ::method "compareTo2"

/* ======================================================================= */
-- needle, haystack[,{C|I}]
::method "countStr2"
  use strict arg arg1needle, arg2haystack, ...

  argNr=arg()              -- get maximum number of arguments
  BIFpos=2                 -- last classic BIF argument position
  maxArg=3

  signal on syntax
  if argNr>maxArg then          -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArg)

  methName="countStr"      -- base name for the message to send

  bCaseDependent =.false   -- default to caseless version
  if argNr>BIFpos then
  do
     letter=arg(maxArg)~strip~left(1)~upper
     if pos(letter,"CI")=0 then     -- illegal argument!
        raise syntax 93.914 array (maxArg, "C, I", arg(maxArg))
     bCaseDependent=(letter="C")
  end

      -- now invoke the operation
  if bCaseDependent then
     return .message~new(arg2haystack, methName,           "I", arg1needle  )~send
  else
     return .message~new(arg2haystack, "caseless"methName, "I", arg1needle  )~send

syntax:
  raise propagate


   -- 2008-02-21, rgf:   delStr2(string ,n-start [, n-length])
   /* if length is negative, then  */
/* ======================================================================= */
::method "delStr2"
  use strict arg arg1, ...    -- make sure we have at least one arg
  parse arg ., arg2, arg3

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArgs=3

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="delStr"        -- base name for the message to send

  len1=length(arg1)        -- get length of string
  newArr=.array~new        -- create new array for the arguments

  if datatype(arg2,"W") then   -- start
  do
     if arg2<0 then        -- negative, start from right
     do
        tmp=len1+arg2+1    -- get starting position
        if tmp<2 then      -- start at first char
           arg2=1
        else
           arg2=tmp
     end
     newArr[1]=arg2        -- start position
  end
  else
  do
      raise syntax 93.905 array('2 ("start position")', arg2)
  end

  if arg(3,"Exists") then  -- length
  do
     if datatype(arg2, "W") then
     do
        if arg3<0 then        -- we need to move the starting point to the left!
        do
           arg2=arg2+arg3+1   -- subtract arg3
           if arg2<1 then     -- reset start to 1
              newArr[1]=1
           else               -- new start pos
              newArr[1]=arg2

           arg3=-arg3         -- turn it into a positive number
        end
     end
     else
     do
        raise syntax 93.905 array('3 ("length")', arg3)
     end

     newArr[2]=arg3        -- length
  end

      -- now invoke the operation
  return .message~new(arg(1), methName, "A", newArr)~send

syntax:
  raise propagate


   -- 2008-03-14, rgf:
/* ======================================================================= */
/*    delWord2(string, start[, length])
         ... if no words, returns received string

*/
::method "delWord2"    -- allows negative start and length
  use strict arg string, arg2, ...     -- make sure we have at least one arg

  parse arg string, arg2, arg3

  argNr=arg()              -- get maximum number of arguments
  maxArgs=3

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="delWord"       -- base name for the message to send
  newArr=.array~new        -- create new array for the arguments

  nrWords=words(string)    -- calc # of words

  if \datatype(arg2, "W") then
     raise syntax 93.905 array('2 ("starting word position")', arg3)

  newArr[1]=arg2           -- save starting pos
  if arg2<0 then
  do
     tmp=nrWords+arg2+1    -- calc starting position from right
     if tmp<1 then         -- if before first word, start at first word
        tmp=1
     newArr[1]=tmp         -- save new starting position
  end

  if arg(3,"Exists") then  -- if given, process length argument
  do
     if \datatype(arg3, "W") then
        raise syntax 93.905 array('3 ("number of words")', arg3)

     if arg3<0 then        -- determine new starting position and number of words to delete
     do
        oldStart=newArr[1] -- save old starting position
        tmp=oldStart+arg3+1
        if tmp<1 then      -- oops, make sure we start at first word
           tmp=1

        newArr[1]=tmp            -- new start position
        newArr[2]=oldStart-tmp+1 -- length argument (nr of words to delete)
     end
     else
     do
        newArr[2]=arg3     -- length argument
     end
  end

  if nrWords=0 then        -- nothing to do, return empty/spacy string
     return string

      -- now invoke the operation
  return .message~new(string, methName, "A", newArr)~send

syntax:
  raise propagate





/* ======================================================================= */
-- not a BIF ::method "Equals2"



/* ======================================================================= */
/*      lastPos     needle, haystack   [,[n-start] [,{C|I}]] */
::method "lastPos2"
  use strict arg arg1needle, arg2haystack, ...

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArgs=4

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  StringPos=1              -- position of string object to work with
  methName="lastPos"       -- base name for the message to send

  bCaseDependent =.false   -- default to caseless version
  if argNr>=BIFpos, \datatype(arg(argNr),"N")  then
  do
     letter=arg(argNr)~strip~left(1)~upper
     if pos(letter,"CI")=0 then     -- illegal argument!
        raise syntax 93.914 array (argNr, "C, I", arg(argNr))
     bCaseDependent=(letter="C")
     argNr-=1              -- decrease one from total number of arguments
  end

  newArr=.array~new        -- create new array for the arguments
  newArr[1]=arg1needle     -- needle
  arg3=arg(3)
  if arg(3,"Exists"), datatype(arg3,"N")  then
  do
     if arg3<0 then        -- negative start column: count from right
     do
         len2=length(arg2haystack)          -- get length of string to scan
         if -arg3 >= len2 then      -- beyond starting position, scan string normally
            return 0       -- beyond start, needle cannot be found!
         else
            newArr[2]=len2+arg3+1   -- determine starting position
     end
     else   -- positive start column
     do
        newArr[2]=arg3     -- save starting position
     end
  end

      -- now invoke the operation
  if bCaseDependent then
     return .message~new(arg2haystack, methName,           "A", newArr)~send
  else
     return .message~new(arg2haystack, "caseless"methName, "A", newArr)~send

syntax:
  raise propagate


/* ======================================================================= */
-- not a BIF ::method "match2"

/* ======================================================================= */
/*      left2     string, length [,pad]                      */
::method "left2"
  use strict arg arg1string, arg2length, ...

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArgs=3

  --signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  if \datatype(arg2length,"W") then
  do
      raise syntax 93.905 array('"length"', arg2)
  end


  bLeftBIF=(arg2length>0)  -- use left() or right() BIF ?
  newArr=.array~new        -- create new array for the arguments

  if bLeftBIF then
     newArr[1]=arg2length
  else
     newArr[1]=-arg2length

  if arg(3,"Exists") then  -- padChar supplied ?
     newArr[2]=arg(3)

      -- now invoke the operation
  if bLeftBIF then
     return .message~new(arg1string, "left",  "A", newArr)~send
  else
     return .message~new(arg1string, "right", "A", newArr)~send

syntax:
  raise propagate



   -- 2008-02-21, rgf:   lower2(string [,[n-start] [, n-length]])
   /* if length is negative, then  */
/* ======================================================================= */
::method "lower2"
  use strict arg arg1, ...    -- make sure we have at least one arg
  parse arg ., arg2, arg3

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArgs=3

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="lower"         -- base name for the message to send

  len1=length(arg1)        -- get length of string
  newArr=.array~new        -- create new array for the arguments

  if arg(2,"Exists") then   -- start
  do
     if datatype(arg2, "W") then
     do
        if arg2<0 then        -- negative, start from right
        do
           tmp=len1+arg2+1    -- get starting position
           if tmp<2 then      -- start at first char
              arg2=1
           else
              arg2=tmp
        end
     end
     else
     do
         raise syntax 93.905 array('2 ("start position")', arg2)
     end

     newArr[1]=arg2        -- start position
  end

  if arg(3,"Exists") then -- length
  do
     if datatype(arg3,"W") then
     do
        if arg3<0 then        -- we need to move the starting point to the left!
        do
           arg2=arg2+arg3+1   -- subtract arg3
           if arg2<1 then     -- reset start to 1
              newArr[1]=1
           else               -- new start pos
              newArr[1]=arg2

           arg3=-arg3         -- turn it into a positive number
        end
     end
     else
     do
        raise syntax 93.905 array('3 ("length")', arg3)
     end

     newArr[2]=arg3        -- length
  end

      -- now invoke the operation
  return .message~new(arg(1), methName, "A", newArr)~send

syntax:
  raise propagate



/* ======================================================================= */
-- not a BIF ::method "match2"
/* ======================================================================= */
-- not a BIF ::method "matchChar2"


   -- 2008-02-22, rgf:   overlay2(new, target [,[n-target-start] [, n-new-length]] [,pad])
   --> ATTENTION: if beyond start, prepend appropriate length pad-filled !
/* ======================================================================= */
::method "overlay2"
  use strict arg new1string, arg1string, ...   -- make sure we have at least two arg
  parse arg ., ., arg2start, arg3NewLength, arg4pad

  argNr=arg()              -- get maximum number of arguments
  BIFpos=5                 -- last classic BIF argument position
  maxArgs=5

  signal on syntax
  if argNr>maxArgs then    -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="overlay"       -- base name for the message to send

  len1=length(arg1string)        -- get length of string
  newArr=.array~new        -- create new array for the arguments
  newArr[1]=new1string     -- "new"-string

  prepend=""               -- optional prepend string (if positioning before start!)

  arg2startori=arg2start         -- save passed-in value, if any
  if arg4pad=="" then arg4pad=" "-- define blank as the default pad char

  if arg(3,"Exists") then  -- start in "target"-string
  do
     if datatype(arg2start,"W") then
     do
        if arg2start<0 then      -- negative, start from right
        do
           tmp=len1+arg2start+1  -- get starting position
           if tmp<2 then         -- start at first char
           do
              if tmp<0 then
                 prepend=copies(arg4pad, -tmp+1)   -- create prepend-string
              else if tmp=0 then    -- fencepost
                 prepend=arg4pad

              arg2start=1
           end
           else
              arg2start=tmp
        end
     end
     else
     do
         raise syntax 93.905 array('3 ("start position in ''target'' string")', arg2start)
     end

     newArr[2]=arg2start   -- start position
  end

  if arg(4,"Exists") then  -- "new"-length
  do
     if datatype(arg3NewLength,"W") then
     do
        if arg3NewLength<0 then  -- we need to move the starting point to the left!
        do
           arg3NewLength=-arg3NewLength   -- turn into a positive number
           newArr[1]=right(new1string, arg3NewLength, arg4pad) -- "new"-string
        end
        else
           newArr[1]=left(new1string,  arg3NewLength, arg4pad) -- "new"-string
     end
     else
     do
        raise syntax 93.905 array('3 ("length of ''new''-string")', arg3NewLength)
     end

     newArr[3]=arg3NewLength  -- length
  end

  if arg4pad<>"" then         -- pad-char
     newArr[4]=arg4pad

      -- now invoke the operation
  return .message~new(prepend||arg1string, methName, "A", newArr)~send

syntax:
  raise propagate




/* ======================================================================= */
/*      Pos     needle, haystack   [,[n-start] [,{C|I}]] */
::method "Pos2"
  use strict arg arg1needle, arg2haystack, ...

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArgs=4

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="Pos"           -- base name for the message to send

  bCaseDependent =.false   -- default to caseless version
  if argNr>=BIFpos, \datatype(arg(argNr),"W")  then
  do
     letter=arg(argNr)~strip~left(1)~upper
     if pos(letter,"CI")=0 then     -- illegal argument!
        raise syntax 93.914 array (argNr, "C, I", arg(argNr))
     bCaseDependent=(letter="C")
     argNr-=1              -- decrease one from total number of arguments
  end

  newArr=.array~new        -- create new array for the arguments
  newArr[1]=arg1needle     -- needle
  arg3=arg(3)
  if arg(3,"Exists"), datatype(arg3,"N")  then
  do
     if arg3<0 then        -- negative start column: count from right
     do
         len2=length(arg2haystack)          -- get length of string to scan
         if -arg3 >= len2 then      -- beyond starting position, scan string normally
            return 0       -- beyond start, needle cannot be found!
         else
            newArr[2]=len2+arg3+1   -- determine starting position
     end
     else   -- positive start column
     do
        newArr[2]=arg3     -- save starting position
     end
  end

      -- now invoke the operation
  if bCaseDependent then
     return .message~new(arg2haystack, methName,           "A", newArr)~send
  else
     return .message~new(arg2haystack, "caseless"methName, "A", newArr)~send

syntax:
  raise propagate




/* ======================================================================= */
/*      right2     string, length [,pad]                      */
::method "right2"
  use strict arg arg1string, arg2length, ...

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArgs=3

  --signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  if \datatype(arg2length,"W") then
  do
      raise syntax 93.905 array('"length"', arg2)
  end
  bLeftBIF=(arg2length>0)  -- use left() or right() BIF ?

  newArr=.array~new        -- create new array for the arguments

  if bLeftBIF then
     newArr[1]=arg2length
  else
     newArr[1]=-arg2length

  if arg(3,"Exists") then  -- padChar supplied ?
     newArr[2]=arg(3)

      -- now invoke the operation
  if bLeftBIF then
     return .message~new(arg1string, "right", "A", newArr)~send
  else
     return .message~new(arg1string, "left",  "A", newArr)~send


syntax:
  raise propagate





/* ======================================================================= */
/* "Front end" to .Arrays two sort methods "sort" and "sortWith" to simplify usage.
   Sorts array in place, but also returns it.
*/

/*
   usage: sort2(array [,A|D][,][C|I][N])
          sort2(array, comparator [,A|D])

          A|D   ... Ascending (default)    | Descending
          C|I|N ... respect Case | Ignore case (default) | Numeric (Rexx-style numbers, default)

------------
   sort2(array)                       ... sort()

   sort2(array, comparator[,"A|D"])   ... sortWith(comparator)

   sort2(array, collection)           ... sortWith(.StringColumnComparator(...))
   sort2(array, n, ...)

   sort2(array, ["A|D"][,"C|I|N"])    ... sortWith(.StringComparator)
   sort2(array, "[A[scending]|D[escending]][",C[aseDependent]|I[gnoreCase]|N[umeric]"])
   sort2(array, "A[C|I|N] | D[C|I|N]"...)

   Sort2(array, "M[essages]", message...) ... sortWith(.MessageComparator(...))
   Sort2(array, "M[essages]", arrayOfMessages...)

*/
::method "sort2"
  use strict arg arg1, arg2="A", arg3="IN", ...

  signal on syntax

  if \arg1~isA(.array)  then
  do
     if \arg1~hasMethod("makeArray") then
        raise syntax 93.948 array (1, "Array (or a class with a method 'MAKEARRAY')")
     arg1=arg1~makeArray         -- get the array that represents the collection
  end

  argNr=arg()                    -- get number of args
  if argNr=1 then                -- default sort as only array collection is given
  do
     if arg1[1]~isA(.string) then   -- string objects to sort?
        return sort2(arg1, "A", "IN")    -- sort decimal numerically and caselessly

     return arg1~sort            -- sort without any assumptions
  end

   -- two arguments only, if strings to sort default to "IN" (case-independent, numeric)
  if argNr=2, arg2~isA(.string) then   -- if a descending sort
  do
     order=arg2~strip~left(1)~upper    -- extract first letter in capital
     if order="A" then           -- sort ascendingly
     do
        if arg1[1]~isA(.string) then      -- string objects to sort?
           return sort2(arg1, "A", "IN")  -- sort ignoring case, compare numbers as numbers

        return arg1~sort
     end
     else if order="D" then      -- sort descendingly
     do
        if arg1[1]~isA(.string) then      -- string objects to sort?
           return sort2(arg1, "D", "IN")  -- sort ignoring case, compare numbers as numbers

        return arg1~sortWith(.DescendingComparator~new)
     end
  end


  if arg2~isA(.Comparator) then  -- o.k. a comparator given, use it
  do
     if argNr>3 then             -- in this case a maximum of three args allowed
        raise syntax 93.902 array (3)

     kind="A"                    -- default to ascending sort
     if argNr=3 then             -- a third argument given
     do
        kind=arg3~strip~left(1)~upper  -- get first char in uppercase
        if pos(kind, "AD")=0 then   -- not a valid argument given!
           raise syntax 93.914 array (3, "A, D", arg3)
     end

     if kind="A" then            -- sort ascendingly
        return arg1~sortWith(arg2)
     else
        return arg1~sortWith(.InvertingComparator~new(arg2))
  end

  if datatype(arg2,"W") | arg2~isA(.OrderedCollection) | arg2~isA(.Supplier) then
  do
     if arg2~isA(.Collection) | arg2~isA(.Supplier) then  -- a collection indicating positions, lengths, type of sort
     do
         if argNr>2 then            -- in this case only two arguments allowed!
            raise syntax 93.902 array (2)
     end
     else   -- argument is a number, hence interpreted as a starting column
     do
         arg2=arg(2,"Array")        -- turn all args into an array collection
     end

         -- use a StringColumnComparator for sorting
      return arg1~sortWith(.StringColumnComparator~new(arg2))
  end

   -- ---rgf, 2008-03-27: allow message(s) as arguments
  if arg2~isA(.string) then         -- check whether "M"essage argument given
  do
     if arg2~strip~left(1)~upper="M" then
     do
         if argNr=3 then   -- single argument follows
            comparator=.MessageComparator~new(arg3)
         else              -- turn remaining args into an array object
            comparator=.MessageComparator~new(arg(3,"Array"))

         return arg1~sortWith(comparator)
     end
  end

   -- o.k. now use ".StringComparator" for sorting ("CIN")
  if argNr>3 then                   -- in this case only three args allowed at most
     raise syntax 93.902 array (3)

  if argNr=2 then -- let .StringComparator deal with the args
     return arg1~sortWith(.StringComparator~new(arg2))
  else
     return arg1~sortWith(.StringComparator~new(arg2, arg3))

syntax: raise propagate





/*
   usage: stableSort2(array [,A|D][,][C|I|N])
          stableSort2(array, comparator [,A|D])

          A|D   ... Ascending (default)    | Descending
          C|I|N ... respect Case | Ignore case (default) | Numeric (Rexx-style numbers)

------------
   stableSort2(array)                       ... sort()

   stableSort2(array, comparator[,"A|D"])   ... sortWith(comparator)

   stableSort2(array, collection)           ... sortWith(.StringColumnComparator(...))
   stableSort2(array, n, ...)

   stableSort2(array, ["A|D"][,"C|I|N"])    ... sortWith(.StringComparator)
   stableSort2(array, "[A[scending]|D[escending]][",C[aseDependent]|I[gnoreCase]|N[umeric]"])
   stableSort2(array, "A[C|I|N] | D[C|I|N]"...)

   stableSort2(array, "M[essages]", message...) ... sortWith(.MessageComparator(...))
   stableSort2(array, "M[essages]", arrayOfMessages...)

*/
::method "stableSort2"
  use strict arg arg1, arg2="A", arg3="I", ...

  signal on syntax

  if \arg1~isA(.array)  then
  do
     if \arg1~hasMethod("makeArray") then
        raise syntax 93.948 array (1, "Array (or a class with a method 'MAKEARRAY')")
     arg1=arg1~makeArray         -- get the array that represents the collection
  end

  argNr=arg()                    -- get number of args
  if argNr=1 then                -- default sort as only array collection is given
  do
     if arg1[1]~isA(.string) then   -- string objects to sort?
        return stableSort2(arg1, "A", "N")  -- sort decimal numerically and caselessly

     return arg1~stableSort      -- sort without any assumptions
  end

   -- two arguments only, if strings to sort default to "IN" (case-independent, numeric)
  if argNr=2, arg2~isA(.string) then   -- if a descending sort
  do
     order=arg2~strip~left(1)~upper    -- extract first letter in capital
     if order="A" then           -- sort ascendingly
     do
        if arg1[1]~isA(.string) then      -- string objects to sort?
           return stableSort2(arg1, "A", "IN")  -- sort ignoring case, compare numbers as numbers

        return arg1~stableSort
     end
     else if order="D" then      -- sort descendingly
     do
        if arg1[1]~isA(.string) then      -- string objects to sort?
           return stableSort2(arg1, "D", "IN")  -- sort ignoring case, compare numbers as numbers

        return arg1~stableSortWith(.DescendingComparator~new)
     end
  end


  if arg2~isA(.Comparator) then  -- o.k. a comparator given, use it
  do
     if argNr>3 then             -- in this case a maximum of three args allowed
        raise syntax 93.902 array (3)

     kind="A"                    -- default to ascending sort
     if argNr=3 then             -- a third argument given
     do
        kind=arg3~strip~left(1)~upper  -- get first char in uppercase
        if pos(kind, "AD")=0 then   -- not a valid argument given!
           raise syntax 93.914 array (3, "A, D", arg3)
     end

     if kind="A" then            -- sort ascendingly
        return arg1~stableSortWith(arg2)
     else
        return arg1~stableSortWith(.InvertingComparator~new(arg2))
  end

  if datatype(arg2,"W") | arg2~isA(.OrderedCollection) | arg2~isA(.Supplier) then
  do
     if arg2~isA(.Collection) | arg2~isA(.Supplier) then  -- a collection indicating positions, lengths, type of sort
     do
         if argNr>2 then            -- in this case only two arguments allowed!
            raise syntax 93.902 array (2)
     end
     else   -- argument is a number, hence interpreted as a starting column
     do
         arg2=arg(2,"Array")        -- turn all args into an array collection
     end

         -- use a StringColumnComparator for sorting
      return arg1~stableSortWith(.StringColumnComparator~new(arg2))
  end

   -- ---rgf, 2008-03-27: allow message(s) as arguments
  if arg2~isA(.string) then         -- check whether "M"essage argument given
  do
     if arg2~strip~left(1)~upper="M" then
     do
         if argNr=3 then   -- single argument follows
            comparator=.MessageComparator~new(arg3)
         else              -- turn remaining args into an array object
            comparator=.MessageComparator~new(arg(3,"Array"))

         return arg1~stableSortWith(comparator)
     end
  end

   -- o.k. now use ".StringComparator" for sorting ("CIN")
  if argNr>3 then                   -- in this case only three args allowed at most
     raise syntax 93.902 array (3)

  if argNr=2 then -- let .StringComparator deal with the args
     return arg1~stableSortWith(.StringComparator~new(arg2))
  else
     return arg1~stableSortWith(.StringComparator~new(arg2, arg3))

syntax: raise propagate






   -- 2008-03-14, rgf:   subChar2(string,n-pos)
   /* if length is negative, then position from right (end of string) */
   --> ATTENTION: if beyond start, prepend appropriate length pad-filled !
/* ======================================================================= */
::method "subchar2"
  use strict arg arg1, arg2   -- make sure we have at least one arg
  parse arg arg1, arg2

  argNr=arg()              -- get maximum number of arguments
  maxArgs=2

  signal on syntax
  if argNr<>maxArgs then   -- not correct amount of arguments ?
  do
     if argNr<maxArgs then
        raise syntax 93.901 array (2)
     else
        raise syntax 93.902 array (2)
  end


  len1=length(arg1)        -- get length of string

  if datatype(arg2,"W") then
  do
     if arg2<0 then        -- negative, start from right
     do
        arg2=len1+arg2+1    -- calc starting position
        if arg2<1 then      -- beyond string, return empty string (i.e. no char)
           return ""
     end

     if arg2=0 then
        raise syntax 93.924 array (arg2)
     else if arg2>len1 then-- beyond string, return empty string (i.e. no char)
        return ""
  end
  else
  do
      raise syntax 93.905 array('2 ("start position")', arg2)
  end

      -- now invoke the operation
  return arg1~substr(arg2,1)  -- return extracted char

syntax:
  raise propagate



   -- 2008-02-21, rgf:   substr2(string [,[n-start] [, n-length]] [,pad])
   /* if length is negative, then  */
   --> ATTENTION: if beyond start, prepend appropriate length pad-filled !
/* ======================================================================= */
::method "substr2"
  use strict arg arg1, ...    -- make sure we have at least one arg
  parse arg ., arg2, arg3, arg4

  argNr=arg()              -- get maximum number of arguments
  BIFpos=4                 -- last classic BIF argument position
  maxArgs=4

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="substr"        -- base name for the message to send

  len1=length(arg1)        -- get length of string
  newArr=.array~new        -- create new array for the arguments

  prepend=""               -- optional prepend string (if positioning before start!)

  arg2ori=arg2             -- save passed-in value, if any
  if arg4=="" then arg4=" "-- define blank as the default pad char

  if arg(2,"Exists") then  -- start
  do
     if datatype(arg2,"W") then
     do
        if arg2<0 then        -- negative, start from right
        do
           tmp=len1+arg2+1    -- get starting position
           if tmp<2 then      -- start at first char
           do
              if tmp<0 then
                 prepend=copies(arg4, -tmp+1)  -- create prepend-string
              else if tmp=0 then    -- fencepost
                 prepend=arg4

              arg2=1
           end
           else
              arg2=tmp
        end
     end
     else
     do
         raise syntax 93.905 array('2 ("start position")', arg2)
     end

     newArr[1]=arg2        -- start position
  end

  if arg(3,"Exists") then -- length
  do
     if datatype(arg3,"W") then
     do
        if arg3<0 then        -- we need to move the starting point to the left!
        do
           tmp =arg2+arg3   -- subtract arg3

           if tmp <1 then     -- reset start to 1
           do
              newArr[1]=1     -- substring from new pos "1"
              if tmp <0 then  -- create (new?) prepend string
                 prepend=prepend||copies(arg4, -tmp) -- create prepend-string
           end
           else               -- new start pos
              newArr[1]=tmp+1
           arg3=-arg3         -- turn it into a positive number
        end
     end
     else
     do
        raise syntax 93.905 array('3 ("length")', arg3)
     end

     newArr[2]=arg3        -- length
  end

  if arg4<>"" then         -- pad-char
     newArr[3]=arg4

      -- now invoke the operation
  return .message~new(prepend||arg1, methName, "A", newArr)~send

syntax:
  raise propagate

pp:
  if .nil=arg(1) then return ""
                 else return "," arg(1)




   -- 2008-03-14, rgf:
/* ======================================================================= */
/*    subWord2(string, start[, length])
         ... if no words, returns received string
*/
::method "subWord2"  -- allows negative start and length
  use strict arg string, arg2, ... -- make sure we have at least two args

  parse arg string, arg2, arg3

  argNr=arg()              -- get maximum number of arguments
  maxArgs=3

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="subWord"       -- base name for the message to send
  newArr=.array~new        -- create new array for the arguments

  nrWords=words(string)    -- calc # of words

  if \datatype(arg2, "W") then
     raise syntax 93.905 array('2 ("starting word position")', arg3)

  newArr[1]=arg2           -- save starting pos
  if arg2<0 then
  do
     tmp=nrWords+arg2+1    -- calc starting position from right
     if tmp<1 then         -- if before first word, start at first word
        tmp=1
     newArr[1]=tmp         -- save new starting position
  end

  if arg(3,"Exists") then  -- if given, process length argument
  do
     if \datatype(arg3, "W") then
        raise syntax 93.905 array('3 ("number of words")', arg3)

     if arg3<0 then        -- determine new starting position and number of words to delete
     do
        oldStart=newArr[1] -- save old starting position
        tmp=oldStart+arg3+1
        if tmp<1 then      -- oops, make sure we start at first word
           tmp=1

        newArr[1]=tmp            -- new start position
        newArr[2]=oldStart-tmp+1 -- length argument (nr of words to delete)
     end
     else
     do
        newArr[2]=arg3     -- length argument
     end
  end

  if nrWords=0 then        -- nothing to do, return empty/spacy string
     return string

      -- now invoke the operation
  return .message~new(string, methName, "A", newArr)~send

syntax:
  raise propagate


   -- 2008-02-21, rgf:   upper2(string [,[n-start] [, n-length]])
   /* if length is negative, then  */
/* ======================================================================= */
::method "upper2"
  use strict arg arg1, ...    -- make sure we have at least one arg
  parse arg ., arg2, arg3

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArgs=3

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="upper"         -- base name for the message to send

  len1=length(arg1)        -- get length of string
  newArr=.array~new        -- create new array for the arguments

  if arg(2,"Exists") then  -- start
  do
     if datatype(arg2,"W") then
     do
        if arg2<0 then        -- negative, start from right
        do
           tmp=len1+arg2+1    -- get starting position
           if tmp<2 then      -- start at first char
              arg2=1
           else
              arg2=tmp
        end
     end
     else
     do
         raise syntax 93.905 array('2 ("start position")', arg2)
     end

     newArr[1]=arg2        -- start position
  end

  if arg(3,"Exists") then -- length
  do
     if datatype(arg3,"W") then
     do
        if arg3<0 then        -- we need to move the starting point to the left!
        do
           arg2=arg2+arg3+1   -- subtract arg3
           if arg2<1 then     -- reset start to 1
              newArr[1]=1
           else               -- new start pos
              newArr[1]=arg2

           arg3=-arg3         -- turn it into a positive number
        end
     end
     else
     do
        raise syntax 93.905 array('3 ("length")', arg3)
     end

     newArr[2]=arg3        -- length
  end

      -- now invoke the operation
  return .message~new(arg(1), methName, "A", newArr)~send

syntax:
  raise propagate



   -- 2008-03-14, rgf:
/* ======================================================================= */
/*    WORD2(string, pos)
      ... if beyond string, then return empty string
*/
::method "word2"       -- extract and return word
  use strict arg string, arg2 -- make sure we have at least one arg

  parse arg string, arg2

  argNr=arg()              -- get maximum number of arguments
  maxArgs=2

  methName="word"          -- base name for the message to send
  newArr=.array~new        -- create new array for the arguments

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  if \datatype(arg2, "W") then
     raise syntax 93.905 array("2 (position)", arg2)  -- must be a number

  nrWords=words(string)    -- get total number of words
  newArr[1]=arg2           -- save position

  if arg2<0 then           -- negative, position from right
  do
     tmp=nrWords+arg2+1    -- calc new position
     if tmp<1 then         -- beyond string, return empty string
        return ""
     newArr[1]=tmp         -- save new position
  end
      -- now invoke the operation
  return .message~new(string, methName, "A", newArr)~send

syntax:
  raise propagate




   -- 2008-03-14, rgf:
/* ======================================================================= */
/*    WORDINDEX2(string, pos)
      ... if beyond string, then return 0
*/
::method "wordIndex2"
  use strict arg string, arg2 -- make sure we have at least one arg

  parse arg string, arg2

  argNr=arg()              -- get maximum number of arguments
  maxArgs=2

  methName="wordIndex"     -- base name for the message to send
  newArr=.array~new        -- create new array for the arguments

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  if \datatype(arg2, "W") then
     raise syntax 93.905 array("2 (position)", arg2)  -- must be a number

  nrWords=words(string)    -- get total number of words
  newArr[1]=arg2           -- save position

  if arg2<0 then           -- negative, position from right
  do
     tmp=nrWords+arg2+1    -- calc new position
     if tmp<1 then         -- beyond string, return empty string
        return 0
     newArr[1]=tmp         -- save new position
  end

      -- now invoke the operation
  return .message~new(string, methName, "A", newArr)~send

syntax:
  raise propagate


   -- 2008-03-14, rgf:
/* ======================================================================= */
/*    WORDLENGTH2(string, position)
      ... if beyond string, then return 0
*/
::method "wordLength2"
  use strict arg string, arg2 -- make sure we have at least one arg

  parse arg string, arg2

  argNr=arg()              -- get maximum number of arguments
  maxArgs=2

  methName="wordLength"    -- base name for the message to send
  newArr=.array~new        -- create new array for the arguments

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  if \datatype(arg2, "W") then
     raise syntax 93.905 array("2 (position)", arg2)  -- must be a number

  nrWords=words(string)    -- get total number of words
  newArr[1]=arg2           -- save position

  if arg2<0 then           -- negative, position from right
  do
     tmp=nrWords+arg2+1    -- calc new position
     if tmp<1 then         -- beyond string, return empty string
        return 0
     newArr[1]=tmp         -- save new position
  end

      -- now invoke the operation
  return .message~new(string, methName, "A", newArr)~send

syntax:
  raise propagate





/* ======================================================================= */
/*
    WORDPOS2(phrase,string[,start][,{C|I}])
*/
::method "wordPos2"
  use strict arg arg1, arg2, arg3=1, ...

  argNr=arg()              -- get maximum number of arguments
  BIFpos=3                 -- last classic BIF argument position
  maxArgs=4
  newArr=.array~new        -- create new array for the arguments
  newArr[1]=arg1           -- save phrase (single or multiple word/s) to search

  signal on syntax
  if argNr>maxArgs then -- too many arguments ?
     raise syntax 93.902 array ("at most" maxArgs)

  methName="wordPos"       -- base name for the message to send

  bCaseDependent =.false   -- default to caseless version
  if argNr>=BIFpos, \datatype(arg(argNr),"W")  then
  do
     letter=arg(argNr)~strip~left(1)~upper
     if pos(letter,"CI")=0 then     -- illegal argument!
        raise syntax 93.914 array (argNr, "C, I", arg(argNr))
     bCaseDependent=(letter="C")
     argNr-=1              -- decrease one from total number of arguments
  end

  if arg(3,"Exists"), datatype(arg3,"W")  then
  do
     if arg3<0 then
     do
        tmp=words(arg2)+arg3+1   -- calc starting position from the right
        if tmp<1 then            -- beyond string, then start with first word!
           tmp=1
        newArr[2]=tmp
     end
     else
     do
        newArr[2]=arg3
     end
  end

      -- now invoke the operation
  if bCaseDependent then
     return .message~new(arg2, methName,           "A", newArr)~send
  else
     return .message~new(arg2, "caseless"methName, "A", newArr)~send

syntax:
  raise propagate



/* ---rgf, 2008-02-26

   parseWords2(string[, reference=char-string[, kind="D"|"W"]] [, returnType="W"ords|"P"os)

   ... returns a one-dimensional array of words parsed from "string" or
       a two-dimensional array of starting position and length of word

       string      ... string from which words should be parsed
       reference   ... string of characters that delimit words or constitute words;
                       default value: " " ||2"09"x

       "d"elimiterChars|"W"ordChars ... "char-string" consists of all those characters
                       that either "D"elimit (default) or constitute "W"ords

       "W"ords|"P"os   "W"ords (default) returns a single dimensional array of
                       the parsed words; "P"os returns a two-dimensional array of
                       positions of start-position (index "1") and length of parsed
                       word (index  "2")
*/

::method "parseWords2"
  use strict arg string, reference=(" "||"09"x), kind="D", returnType="W"

  signal on syntax

  .ArgUtil~validateClass("string",     string,    .string)  -- check for correct type
  .ArgUtil~validateClass("reference",  reference, .string)  -- check for correct type
  .ArgUtil~validateClass("kind",       kind     , .string)  -- check for correct type

  if kind<>"D" then     -- not a default value
  do
     tmp=kind~strip~left(1)~upper
     if pos(tmp, "DW")=0 then
        raise syntax 93.914 array("'kind'", "D[elimiter] | W[ord-characters]", kind)
     kind=tmp
  end

  .ArgUtil~validateClass("returnType", returnType, .string)  -- check for correct type
  if returnType<>"W" then  -- not a default value
  do
     tmp=returnType~strip~left(1)~upper
     if pos(tmp, "WP")=0 then
        raise syntax 93.914 array("'returnType'", "W[ords] | P[ositions]", returnType)
     returnType=tmp
  end

  if returnType="W" then   -- single-dimensioned array of words
     res=.array~new
  else                     -- two-dimensional array of position and length
     res=.array~new(0,0)

  maxLen=length(string)
  pos=1
  endPos=0
  do i=1 while endpos<maxLen -- for 30

     if kind="D" then      -- words are space-delimited according to "reference"
     do
        if i=1 then        -- first iteration?
           pos   =verify(string, reference, "Nomatch")         -- find beginning of word
        else
           pos   =verify(string, reference, "Nomatch", endPos) -- find beginning of word

        if pos=0 then      -- no more words to find
           leave

        endPos=verify(string, reference, "Match",   pos) -- find next space (end of word)
        if endPos=0 then   -- last word, string ends with it
           endPos=maxLen+1
     end
     else                  -- "reference" defines the characters a word consists of
     do
        if i=1 then        -- first iteration?
           pos   =verify(string, reference, "Match")            -- find beginning of word
        else
        do
           pos   =verify(string, reference, "Match", endPos)    -- find beginning of word
        end

        if pos=0 then      -- no more words to find
           leave

        endPos=verify(string, reference, "Nomatch",    pos)  -- find next space (end of word)
        if endPos=0 then   -- last word, string ends with it
           endPos=maxLen+1
     end

     if returnType="W" then
     do
        res[i]=string~substr(pos,endPos-pos)  -- extract and save word
     end
     else
     do
        res[i,1]=pos          -- save starting position
        res[i,2]=endPos-pos   -- save length of word
        res[i,3]=endPos       -- save starting position of next word, if any
     end
  end

  return res         -- return result array

syntax:              -- propagate condition
  raise propagate






/* ======================================================================= */
/*
   JLF: Helper to display the shape of an array.
*/

::routine shape public
    use arg coll, separator=""
    if coll~hasMethod("shapeToString"), coll~isA(.array) then do
        shape = coll~shapeToString
        if shape <> "no shape" then shape = "shape" shape
        return shape || separator
    end
    return ""


/* ======================================================================= */
/* Dump collection or supplier. */
/*
    dumpArray2(--coll--[,-title-]-)

      coll       ... collection or supplier object to dump in sorted order
      title      ... optional, title to be displayed
      comparator ... the comparator to use in sorting
*/
::routine dump2 public
  -- JLF: I prefer a notation closer to the standard notation "a String" or "an Array"
  -- JLF: add surroundItemByQuotes, surroundIndexByQuotes
  -- JLF: add action, to let do something for each item
  use arg coll, title=(/*"type: The" coll~class~id "class"*/ coll~defaultName), comparator=.nil, iterateOverItem=.false, surroundItemByQuotes=.true, surroundIndexByQuotes=.true, maxCount=(9~copies(digits())) /*no limit*/, action=.nil

  if .nil=comparator, title~isA(.comparator) then
  do
     comparator=title
     title=(/*"type: The" coll~class~id "class"*/ coll~defaultName)
  end

  -- JLF
  doer = .nil
  if .nil <> action then do
    doer = action~doer
  end

  if coll~isA(.supplier) then
  do
     s=coll
     len=5  -- define an arbitrary high width
     availability = "" --JLF
     if \s~available then availability = "(nothing available)" -- JLF
     if title <> .nil then say title availability -- JLF .nil
  end
  else if \coll~isA(.Collection) then   -- make sure we have a Collection else
  do
     if arg(2,"E") then    -- title omitted !
        say title

     say "DUMP2(): ---> argument to dump is *NOT* a *COLLECTION/SUPPLIER* ! <--- "
     say "                       type:" pp2(coll~class)
     say "       default string value:" pp2(coll)
     -- .ArgUtil~validateClass("collection", coll, .Collection) -- must be of type Collection
     return false -- nothing displayed
  end
  else      -- a collection in hand
  do
     shape = shape(coll, ", ") -- JLF
     items = coll~items -- calculate once, can be long for big array
     if title <> .nil then say title" ("shape || items "items)" -- JLF .nil shape
     len=length(items)
  end

  -- JLF say
  count=0


  if coll~isA(.Collection) then s=makeSortedSupplier(coll, comparator, maxCount)

   -- determine maximum length of "pretty printed" index-value
  maxWidth=0
  s2=s~copy
  do maxCount while s2~available
     maxWidth=max(maxWidth,length(ppIndex2(s2~index, surroundIndexByQuotes)))
     s2~next
  end

  count=0
  do while s~available
     count=count+1
     if count > maxCount then do
         say "..."
         return false -- truncated
     end
     if s~item~isa(.array) & iterateOverItem then do
         -- JLF one line per subitem
         do subitem over s~item~sort
            say ppIndex2(s~index, surroundIndexByQuotes)~left(maxWidth) ":" pp2(subitem, surroundItemByQuotes)
            -- JLF
            if .nil <> doer then do
              -- named argument notation, not namespace notation!
              if doer~arity >= 2 then doer~do(      subitem,        s~index,-
                                              item: subitem, index: s~index)
                                 else doer~do(      subitem,-
                                              item: subitem)
            end
         end
     end
     else do
         -- JLF shorter output
         -- say "   " "#" right(count,len)":" "index="ppIndex2(s~index)~left(maxWidth) "-> item="pp2(s~item)
         say ppIndex2(s~index, surroundIndexByQuotes)~left(maxWidth) ":" pp2(s~item, surroundItemByQuotes)
         -- JLF
         if .nil <> doer then do
           -- named argument notation, not namespace notation!
           if doer~arity >= 2 then doer~do(      s~item,        s~index,-
                                           item: s~item, index: s~index)
                              else doer~do(      s~item,-
                                           item: s~item)
         end
     end
     s~next
  end
  -- JLF say "-"~copies(50)
  return true -- not truncated


/* Sort a collection considering its type and return a sorted supplier object. */
makeSortedSupplier: procedure
  use arg coll, comparator=.nil, maxCount=(9~copies(digits()))

  if coll~isA(.OrderedCollection) then do  -- don't sort, just return the supplier
     if coll~isA(.array) then do
         if interpreter_extended() then
             return coll~supplier(maxCount+1) -- +1 to let display the ellipsis
         else
             return coll~supplier -- maxCount not supported
     end
     return coll~supplier -- optional argument maxCount not yet implemented
  end

  if coll~isA(.SetCollection) then        -- use items part, sort it and return it as a supplier
  do
     arr=coll~allItems                    -- get array representation
     call sortArray arr, comparator       -- sort elements
     return .supplier~new(arr, arr)       -- return supplier with sorted elements
  end

  if coll~hasMethod('allAt') then         -- handle collections with idx -> coll
  do
     arr=.set~new~union(coll~allIndexes)~makeArray -- remove duplicate indexes, if any
     call sortArray arr, comparator       -- sort elements

     arr2=.array~new

     do i=1 to arr~items                  -- iterate over all indexes
        tmp=coll~allAt(arr[i])            -- get all items associated with index
        if tmp~items=1 then
           arr2[i]=tmp~at(1)              -- save single item to show
        else
           arr2[i]=tmp                    -- save collection of associated items (jlf: tmp)
     end

     return .supplier~new(arr2, arr)
  end

   -- o.k. only MapCollection/Collection left, assuming 1:1 mapping between index and item
  arr=coll~allIndexes                  -- remove duplicate indexes, if any
  call sortArray arr, comparator       -- sort elements

  arr2=.array~new
  do i=1 to arr~items                  -- iterate over all indexes
     arr2[i]=coll[arr[i]]              -- retrieve item part
  end
  return .supplier~new(arr2, arr)


   -- just sort the passed in array, depending on whether a comparator is needed or not
sortArray: procedure
  use arg arr, comparator=.nil

  if .nil=comparator, \arr[1]~hasMethod('compareTo') then   -- no comparator available, use string renderings
     comparator=.MessageComparator~new("string", .true)

  if .nil<>comparator then
     arr~stableSortWith(comparator)
  else
     arr~stableSort

  return





/* ======================================================================= */
/* This comparator expects a message name or a message object to send to
   both objects. If a message name is given, the appropriate message object
   will get created and used. The result of sending the message will then
   be used to carry out the actual comparison.

   The second argument is optional (default value: .false), and if supplied
   must be a logical value. If .true, then the result values from sending
   the message will be cached in a table.

   .MessageComparator~new(-message-[,-bCache-])

      message ... message name or message object; this will get sent to each
                  object and its result will be used for comparison
      bCache  ... optional (default: .false), if .true, then the result of
                  each message will be stored in a table; if an object is
                  contained more than once in the collection, then sending
                  a message to it will return the cached result of the previous
                  execution; this should help performance in situations where
                  each execution of the message is very time consuming

         20071020 - idea: allow array of message-arrays (each entry is an
                    array with a msgName/msgObject, and optionally "I|A" and
                    arguments for that particular msg)

         20071230 - better idea: ordered collection of message names or
                    message objects; if one message only, create own "compare"-
                    methods for it

         20080103 - added in multiple message mode the option to attach "/numeric"
                    to a message name (=string), if values should be sorted as
                    numbers; done

         20080324 - idea: allow "/[a[scending]|d[escending]][n[umeric]|[c[ase]|i[gnore]],
                          then apply respective comparators

*/
::class "MessageComparator" mixinclass Comparator

::method init
  expose message cacheTable messages messageArray numericComparator caselessComparator asc
  use strict arg message, bCache=.false

  signal on syntax
  if \datatype(bCache,"O") then
     raise syntax 34.900 array ("Method argument 2 ('cache') must be a logical value, received:" bCache)

  bSingleMessage=\(message~isA(.collection)) -- determine whether we received a collection

  if \bSingleMessage, bCache=.true then
     raise syntax 88.900 array ("Using multiple messages for comparisons, caching not allowed! Argument 'cache' must be omitted or set to '.false'.")

  emptyString=""                    -- define empty string

  if bSingleMessage then
  do
      -- set var "asc" (A[sc]/D[esc]), "kind" (N|I|C)
     asc="A"                        -- default to A[scending] sort
     kind=""

     bNumericMessage=.false         -- indicates whether message result should be compared as a number
     if message~isA(.string) then   -- name of a message, create message object
     do
        parse caseless var message message "/" +1 flags
         -- set var "asc" (A[sc]/D[esc]), "kind" (N|I|C)
        if flags<>"" then
           parse value determineSortingKind(flags) with asc kind

        message=.message~new(.nil, message~strip)  -- make sure to strip leading & trailing space
     end
     else if \message~isA(.message) then
     do
        raise syntax 93.900 array ("Method argument 1 must be either a message name (a string) or a message object, found:" message)
     end


     if bCache then
        cacheTable=.table~new       -- create table to use for cache

     if kind="N" then               -- numeric sort
     do
        numericComparator=.NumberComparator~new -- create the numeric comparator
        if bCache then
           self~setMethod("compare", self~instanceMethod("cached_plain_numeric_compare"), "Object")
        else
           self~setMethod("compare", self~instanceMethod("plain_numeric_compare"), "Object")
     end

     else if kind="I" then          -- case independent sort
     do
        caselessComparator=.CaselessComparator~new -- create the caseless comparator
        if bCache then
           self~setMethod("compare", self~instanceMethod("cached_plain_caseless_compare"), "Object")
        else
           self~setMethod("compare", self~instanceMethod("plain_caseless_compare"), "Object")
     end

     else                           -- plain sort
     do
        if bCache then
           self~setMethod("compare", self~instanceMethod("cached_plain_compare"), "Object")
        else
           self~setMethod("compare", self~instanceMethod("plain_compare"), "Object")
     end

  end

  else   -- collection of messages!
  do
        -- create the comparator objects
     numericComparator =.NumberComparator~new
     caselessComparator=.CaselessComparator~new
     messages=.array~new      -- use a list to keep all message objects

      -- three dimensions: 1=messageObject, 2=kind (I|N|C|""), 3=ascending (A|D)
     messageArray =.array~new(message~items,3)

     i=0
     do msg over message   -- iterate over received collection
        i+=1
        asc="A"            -- default to A[scending] sort
        kind=""            -- no kind given, regular comparison

        if msg~isA(.array) then  -- [1]=msg (a string or message), [2]=flagString [, [3]=flagString2]
        do
           flags=msg[2]    -- get flags
           if \flags~isA(.string) then
              raise syntax 93.900 array ("Message item #" i": array object must have a string value ('flags') at index '2'.")

           if msg~hasindex(3), msg[3]~isA(.String) then     -- maybe index #3 has flag information also?
              flags=flags msg[3] -- in this case [2]="A|D", [3]="C|I|N"

           if \(msg[1]~isA(.String) | msg[1]~isA(.Message)) then
              raise syntax 93.900 array ("Message item #" i": array object must have a string value ('methodName') or message object ('method') at index '1'.")

           parse value determineSortingKind(flags) with asc kind  -- process flags

           msg=msg[1]      -- now assign first element
        end

        if msg~isA(.string) then       -- name of a message, create message object
        do
               -- check whether message contains a "/" which indicates flags coming up
           parse var msg msg "/" +1 flags
               -- set var "asc" (A[sc]/D[esc]), "kind" (N|I|C)
           if flags<>"" then
              parse value determineSortingKind(flags) with asc kind

           messageArray[i,1]=.message~new(.nil, msg~strip) -- save message object

           messageArray[i,2]=kind         -- save "kind" (N|I|C|"")

           if asc="D" then messageArray[i,3]="D"   -- descending sort
                      else messageArray[i,3]="A"   -- ascending sort
        end

        else if msg~isA(.message) then -- a message object in hand
        do
           messageArray[i,1]=msg       -- save message object
           messageArray[i,2]=kind      -- kind: regular comparison
           messageArray[i,3]=asc       -- ascending sort
        end

        else   -- neither string nor message object !
           raise syntax 93.900 array ("Item #" i "of the supplied collection must be either a message name (a string) or a message object!")
     end

     self~setMethod("compare", self~instanceMethod("multiple_messages_compare"), "Object")
  end

  return

/* Analyze flags return blank delimited string:

      A|D [N|I|C]
*/
determineSortingKind: procedure
  parse arg flags
  signal on syntax

  if words(flags)=1 then         -- could be a concatenation of "nd", "ac", "di", etc.
  do
     flags=flags~strip~left(2)~translate
     if pos(flags~subchar(2), "NADCI")=0 then   -- second char is not an option, remove it
        flags=flags~left(1)
  end
  else
  do
     tmpStr=""
     do i=1 to words(flags)      -- get first character of word
        tmpStr=tmpStr || word(flags,i)~left(1)
     end
     flags=tmpStr~upper          -- into uppercase
  end

  pos=verify(flags,"NADCI", "N") -- any non-matching chars?
  if pos>1 then
    raise syntax 93.914 array("'/flags'", "[C[aseDependent] | I[gnoreCase] | N[umeric]]  [A[asc] | D[esc]]]", msg)

  res=""
  if pos("D", flags)>0 then
  do
     res="D"       -- descending
     if pos("A", flags)>0 then
        raise syntax 93.300 array("Contradictionary flags: only one of the flags 'A'[scending] and 'D'[escending] must be given.")
  end
  else   -- default value, if neither "D" nor "A" is given
     res="A"       -- ascending

  if pos("N", flags)>0 then
  do
     res=res "N"   -- numeric/number
     if verify(flags, "CI", "M")>0 then
        raise syntax 93.300 array("Contradictionary flags: only one of the flags 'C'[aseDependent], 'I'[gnoreCase] and 'N'[umeric] must be given.")
  end
  else if pos("I", flags)>0 then
  do
     res=res "I"   -- ignore case
     if verify(flags, "CN", "M")>0 then
        raise syntax 93.300 array("Contradictionary flags: only one of the flags 'C'[aseDependent], 'I'[gnoreCase] and 'N'[umeric] must be given.")
  end
  else if pos("C", flags)>0 then
  do
     res=res "C"   -- respect case
     if verify(flags, "IN", "M")>0 then
        raise syntax 93.300 array("Contradictionary flags: only one of the flags 'C'[aseDependent], 'I'[gnoreCase] and 'N'[umeric] must be given.")
  end

  return res

syntax:     -- propagate syntax exception, if any
  raise propagate




   /* this version caches the result of the messages sent, and therefore
      can reuse previous message results directly */
::method cached_plain_compare
  expose message cacheTable asc
  use strict arg left, right

  if \cacheTable~hasindex(left) then      -- not cached yet?
     cacheTable[left]=message~copy~send(left)   -- get value

  if \cacheTable~hasindex(right) then     -- not cached yet?
     cacheTable[right]=message~copy~send(right) -- get value

  if asc="A" then    -- ascending
     return cacheTable[left]~compareTo(cacheTable[right])
  else               -- descending
     return cacheTable[right]~compareTo(cacheTable[left])



::method cached_plain_numeric_compare
  expose message cacheTable numericComparator asc
  use strict arg left, right

  if \cacheTable~hasindex(left) then      -- not cached yet?
     cacheTable[left]=message~copy~send(left)   -- get value

  if \cacheTable~hasindex(right) then     -- not cached yet?
     cacheTable[right]=message~copy~send(right) -- get value

  if asc="A" then    -- ascending
     return numericComparator~compare(cacheTable[left], cacheTable[right])
  else               -- descending
     return numericComparator~compare(cacheTable[right], cacheTable[left])


::method cached_plain_caseless_compare
  expose message cacheTable caselessComparator asc
  use strict arg left, right

  if \cacheTable~hasindex(left) then      -- not cached yet?
     cacheTable[left]=message~copy~send(left)   -- get value

  if \cacheTable~hasindex(right) then     -- not cached yet?
     cacheTable[right]=message~copy~send(right) -- get value

  if asc="A" then    -- ascending
     return caselessComparator~compare(cacheTable[left], cacheTable[right])
  else               -- descending
     return caselessComparator~compare(cacheTable[right], cacheTable[left])



::method plain_compare
  expose message asc
  use strict arg left, right

  if asc="A" then    -- ascending
     return message~copy~send(left)~compareTo(message~copy~send(right))
  else               -- descending
     return message~copy~send(right)~compareTo(message~copy~send(left))


::method plain_numeric_compare
  expose message numericComparator asc
  use strict arg left, right

  if asc="A" then    -- ascending
     return numericComparator~compare(message~copy~send(left), message~copy~send(right))
  else               -- descending
     return numericComparator~compare(message~copy~send(right), message~copy~send(left))

::method plain_caseless_compare
  expose message caselessComparator asc
  use strict arg left, right

  if asc="A" then    -- ascending
     return caselessComparator~compare(message~copy~send(left), message~copy~send(right))
  else               -- descending
     return caselessComparator~compare(message~copy~send(right), message~copy~send(left))




::method multiple_messages_compare
  expose messageArray numericComparator caselessComparator
  use strict arg left, right

  do i=1 to messageArray~dimension(1)    -- process all messages until a comparison yields unequal
     msg=messageArray[i,1]        -- get message object

     if messageArray[i,2]="" then         -- regular comparison
     do
        if messageArray[i,3]="A" then     -- Ascending sort
           res=msg~copy~send(left)~compareTo(msg~copy~send(right))
        else
           res=msg~copy~send(right)~compareTo(msg~copy~send(left))
     end

     else if messageArray[i,2]="I" then   -- case independent comparison!
     do
        if messageArray[i,3]="A" then     -- Ascending sort
           res=caselessComparator~compare(msg~copy~send(left), msg~copy~send(right))
        else
           res=caselessComparator~compare(msg~copy~send(right), msg~copy~send(left))
     end

     else if messageArray[i,2]="N" then   -- numeric comparison!
     do
        if messageArray[i,3]="A" then     -- Ascending sort
           res=numericComparator~compare(msg~copy~send(left), msg~copy~send(right))
        else
           res=numericComparator~compare(msg~copy~send(right), msg~copy~send(left))
     end

     else                     -- standard comparison
     do
        if messageArray[i,3]="A" then     -- Ascending sort
           res=msg~copy~send(left)~compareTo(msg~copy~send(right))
        else
           res=msg~copy~send(right)~compareTo(msg~copy~send(left))
     end

     if res<>0 then
        return res
  end
  return 0                    -- default return value




/* ======================================================================= */
/* Compares Rexx (string) numbers. If the instance is created with an (optional)
   argument of .true, then numbers are compared as numbers, but if one or both
   arguments are not numbers, then the normal string "compareTo" will be employed.

   Comparison of numbers is carried out under NUMERIC DIGITS 40, which allows
   comparing numbers in the 2**128 range

   Restriction:   this class is used by .StringComparator and uses StringComparator objects as well
*/
::class "NumberComparator" mixinclass Comparator
::method init
  expose stringComparator order
  use arg bIgnoreNonNumbers=.true, order="A", case="I"

  if bIgnoreNonNumbers=.false then
     return    -- just use the plain number comparisons (default: method "compare", already defined)

  if \datatype(bIgnoreNonNumbers, "O") then  -- not boolean/lOgical !
     raise syntax 34.901 array (bIgnoreNumbers)

  order=order~strip~left(1)~translate
  if pos(order, "AD")=0 then
     raise syntax 93.914 array ("# 2 (order)", "A, D", arg(2))


  case=case~strip~left(1)~translate
  if pos(case, "CI")=0 then
     raise syntax 93.914 array ("# 3 (comparison type)", "C, I", arg(3))

   -- replace default "compare" method with the desired relaxed one
  if order="A" then
     self~setMethod("compare", self~instanceMethod("compareWithNonNumbers"), "OBJECT")
  else
     self~setMethod("compare", self~instanceMethod("compareWithNonNumbersDescending"), "OBJECT")

    -- now create and set comparator to use for non-numbers
  stringComparator=.stringComparator~new(order, case) -- get string comparator to use
  stringComparator=.StringComparator~new(order, case)



   -- number only version, if non-number let runtime raise the syntax error
::method compare
  expose order
  use strict arg left, right

  numeric digits 40        -- allow to deal with numbers up to 2**128
  if order="A" then return (left-right)~sign    -- returns -1 (left<right), +1 (left>right), 0 (left=right)
               else return -((left-right)~sign) -- descending: invert comparison results

::method stringComparator           -- getter
  expose stringComparator
  return stringComparator

::method "stringComparator="        -- setter
  expose stringComparator
  use arg stringComparator


::method compareWithNonNumbers      -- used by StringComparator as well !
  expose stringComparator           -- stringComparator to use, if left and/or right are not numbers
  use strict arg left, right

  if datatype(left, "n"), datatype(right, "n") then
  do
     numeric digits 40           -- allow to deal with numbers up to 2**128
     return (left-right)~sign    -- returns -1 (left<right), +1 (left>right), 0 (left=right)
  end

  return stringComparator~compare(left,right) -- rgf, 20090520


::method compareWithNonNumbersDescending  -- used by StringComparator as well !
  expose stringComparator           -- stringComparator to use, if left and/or right are not numbers
  use strict arg left, right

  -- if var("stringComparator")=.false then stringComparator=.StringComparator~new("D", "I")   -- 20090520, rgf


  if datatype(left, "n"), datatype(right, "n") then
  do
     numeric digits 40           -- allow to deal with numbers up to 2**128
     return -((left-right)~sign) -- returns -1 (left<right), +1 (left>right), 0 (left=right)
  end

  return stringComparator~compare(left,right) -- rgf, 20090520



/* ======================================================================= */
/* Single class to wrap comparators for string objects:
   - ascending, case-dependent (Comparator: "A", "C"), also: "AC", "CA"
   - descending, case-dependent (DescendingComparator: "D", "C"), also: "DC", "CD"
   - ascending, case-independent (CaselessComparator: "A", "I"), also: "AI", "IA"
   - descending, case-independent (CaselessDescendingComparator: "D", "I"), also: "DI", "ID"

   .StringComparator~new([A|D] ,[C|I][N])

      A|D ... optional: "A"scending (default), "D"escending
      C|I|N ... optional: "C"ase dependent (default), "I"gnore case (default), "N"umeric (Rexx-style numbers (default) )

   [hint: argument letters and sequence from SysStemSort]


   Restriction:   this class is used by .NumberComparator and uses NumberComparator objects as well
*/
::class "StringComparator" mixinclass Comparator
::method init
  parse upper arg order, case

  if order="" then order="A"  -- default to ascending
              else order=order~strip~translate

  if case ="" then case="NI"  -- default to ignore case and compare numeric strings as Rexx numbers
              else case=case~strip~translate

  pos=pos(order, "AD")        -- check whether valid argument
  if pos=0 then
     raise syntax 93.914 array ("# 1 (order)", "AD", order)

  pos=verify(case, "ICN")     -- check whether built of valid arguments
  if pos<>0 then
     raise syntax 93.914 array ("# 2 (comparison type)", "CIN", case)

  bCompareNumeric=(pos("N", case)>0)   -- numeric comparisons ?

  if pos("C", case)>0 then    -- respect case explicitly given?
     case="C"                 -- respect case
  else
     case="I"                 -- ignore case (default)

  if bCompareNumeric=.true then     -- numeric strings should be compared according to the Rexx rules
  do
      -- create a number comparator that uses a .StringComparator
     numComp=.NumberComparator~new(.true, order, case)

      -- now get the comparison method from the numberComparator object
     self~setMethod("compare", numComp~instanceMethod("compare"))

      -- now get (from numComp) and add (to this instance) the getter and setter methods with the same scope
     self~setMethod("stringComparator=", numComp~instanceMethod("stringComparator=")) -- setter
     self~setMethod("stringComparator",  numComp~instanceMethod("stringComparator"))  -- getter

      -- now get (from numComp) the stringComparator object and use it (in this instance)
     self~stringComparator=numComp~stringComparator
  end
  else   -- plain string comparisons, treat numeric values as string of characteres
  do
      sign=""        -- no sign for return value
      if order="D" then
         sign="-"    -- inverse the result

      if case="I" then     -- ignore case in comparisons
        self~setMethod("compare", "use strict arg left, right; return" sign"left~caselessCompareTo(right)")
      else
        self~setMethod("compare", "use strict arg left, right; return" sign"left~compareTo(right)")
  end


::method compare abstract  -- by default abstract to define the protocol





/* ======================================================================= */
/*
    usage: NEW({pos [,length] [,A|D} [,C|I|N]} [, ...])
           NEW(coll [,defaultAD [,defaultCIN]])

    sorts by the given column, there can be as many columns as the user sees fit

    where arguments:
            pos         start position
            length      optional, indicates comparison length
            A|D         optional, sort "A"scending/"D"escending
            C|I|N       optional, use "C"ase-sensitive|case-"I"ndependent|
                                  "N"umberComparator
                                  "O"numberComparator relaxed (treats non-numbers as 0)

            coll        ordered collection or supplier object containing the arguments
                        in the above described sequence
            defaultAD   default value for sorting order, in case it is omitted
            defaultCIN  default value for comparison type, in case it is omitted

    there can be any number of columns, two consecutive numbers are interpreted
    as pos and length; 'length' is omitted if 'pos' is followed by a non-numeric
    argument (A|D or C|I|N)
*/
::class 'StringColumnComparator' mixinclass Comparator

::method init
  expose numberComparator
  use strict arg arg1, ...

  def=""
  if datatype(arg(2),"M") then def=arg(2)
  if datatype(arg(3),"M") then def=def||arg(3)

   -- check and set sort options
  parse value checkSortOptions(def) with def defAD defCIN

   /* if argument is an ordered collection or supplier, then use its content
      to set up the comparison code */
  if arg1~isA(.OrderedCollection) | arg1~isA(.Supplier) then
     args=arg1~allItems -- get items/values as an array
  else
     args=arg(1, "A")   -- get arguments as an array

      -- comparator for Rexx numbers (defaults to allow comparing numbers with strings as well)
  numberComparator=.numberComparator~new

      -- analyze columns and type of comparison, store in temp array
  resArr=.array~new     -- [1]...'pos', [2]...'length' or .nil, [3]...A|D, [4]...C|I
  count=0               -- index into resulting array

  items=args~items      -- number of args
  do i=1 to items
      -- expecting position
     val=args[i]        -- get argument
     if \datatype(val, "W") | val<1 then
        raise syntax 93.907 array (i, val)   -- raise an error

     count=count+1            -- new column to sort
     resArr[count,1]=val      -- save starting position

      -- set default sorting options
     resArr[count,3]=defAD    -- use default a/descending order
     resArr[count,4]=defCIN   -- use case-sensitive, insensitive, number

     if i=items then leave    -- no more infos

      -- length available ?
     i+=1                     -- position on next arg, if available
     val=args[i]
     if datatype(val, "W") then
     do
        resArr[count,2]=val   -- save length
        if i=items then leave -- already last item processed?

        if datatype(args[i+1],"W") then   -- a number coming up, i.e. a new starting position!
           iterate i          -- iterate

        i+=1                  -- position on next item, i.e. sorting option
        val=args[i]           -- a sorting options
     end

      -- a sorting option in hand?
     if i<items, \datatype(args[i+1],"W") then
     do
        i+=1                 -- position on next item, i.e. a sorting option (CIN)
        val=val||args[i]
     end

        -- determine and assign sorting options
     parse value checkSortOptions(val) with val resArr[count,3] resArr[count,4]
  end

   /* o.k., we now create the code for the method 'compare' */
  methArr=.array~of("expose numberComparator", "", "use strict arg left, right", "")

  dim1=resArr~dimension(1) -- get nr. of entries in first dimension
  do i=1 to dim1
     if i<dim1 then        -- not the last comparison ?
     do
        methArr~append("res="createCodeSnippet(resArr,i))
        methArr~append("if res<>0 then return res")
        methArr~append("")
     end
     else
        methArr~append('return' createCodeSnippet(resArr,i))
  end

   /* now use this code for a method 'compare', use object's scope */
  self~setMethod("compare", methArr, "Object")

  return

   /* -------------- check for options ------------------- */
      -- check options, make sure all are set
checkSortOptions: procedure
  parse upper arg def, arg2
  def=(def||arg2)~space(0)

      -- check for "A"scdending, "D"escending
  pos=verify("AD", def, "M")  -- find matching char
  if pos=0 then
     def=def||"A"             -- add ascending as default

      -- check for "C"ase-sensitive, case "I"nsensitive, "N"umber comparison
  pos=verify("CIN", def, "M") -- find matching char
  if pos=0 then
     def=def||"I"             -- ignore case by default
     -- def=def||"C"          -- add case-sensitive as default

  pos=verify(def, "ADCIN", "N")  -- find non-matching char
  if pos<>0 then                 -- error: non-matching char in option string!
     raise syntax 93.915 array ("ADCIN", def":" substr(def,pos,1))

  return def -
         substr(def, verify(def, "AD" , "M") ,1) - -- extract option letter
         substr(def, verify(def, "CIN", "M"),1)   -- extract option letter



   /* -------------- create comparison code -------------- */
createCodeSnippet: procedure
  use arg resArr, idx

   -- determine starting position and (optional) length
  startPosAndLength=resArr[idx,1]  -- start column
  if .nil<>resArr[idx,2] then    -- length given?
      startPosAndLength=startPosAndLength","resArr[idx,2]

  pos=pos(resArr[idx,4], "CIN") -- determine which kind of comparison

  if pos<3 then                  -- string comparisons using "[caseless]CompareTo"
  do
     if pos=2 then               -- case-Independent comparisons
        tmpStr="left~caselessCompareTo(right,"
     else                        -- CASE-dependent comparisons
        tmpStr="left~compareTo(right,"

     tmpStr=tmpStr startPosAndLength   -- supply start position (and optional length)
  end
  else                           -- Rexx numbers to compare!
  do
     tmpStr="numberComparator~compare(left~subStr("startPosAndLength")," -
                                     "right~substr("startPosAndLength")"
  end

  if resArr[idx,3]="D" then      -- sort descending: invert result
     return "-"tmpStr")"         -- return the comparison statement

  return tmpStr")"               -- return the comparison statement






/* ======================================================================= */
/* Enclose string in square brackets show non-printable chars as Rexx hex-strings.
   If non-string object, then show its string value and hash-value.
*/

::routine pp2 public       -- rgf, 20091214
  use strict arg a1, surroundByQuotes=.true

  if a1~hasMethod("ppString") then return a1~ppString(surroundByQuotes)

  -- JLF : this routine is redundant with the method ~ppstring defined by extension

  -- JLF : can't use .Text, its package is not imported here
  a1.isaText = (a1~class~id=="RexxText")

  -- JLF : texts are prefixed with "T"
  if a1.isaText then return escape3("T'"a1~string"'") -- JLF : Use 0xXX notation for escaped characters

  -- JLF : mutable buffers are prefixed with "M"
  if a1~isa(.MutableBuffer) then return escape3("M'"a1~string"'") -- JLF : Use 0xXX notation for escaped characters

  -- JLF : strings are surrounded by quotes, except string numbers.
  if a1~isA(.string) then do
      if a1~dataType("N") then return a1
      if surroundByQuotes then a1 = "'"a1"'"
      return escape3(a1) -- JLF : Use 0xXX notation for escaped characters
  end

  -- JLF : condensed output, 100 items max
  if a1~isA(.array), /*a1~dimension == 1,*/ a1~hasMethod("ppRepresentation") then
     return a1~ppRepresentation(100, surroundByQuotes)

  -- JLF : Since I pretty-print array using square brackets, I prefer to avoid square brackets
  if a1~isA(.Collection) then do
     shape = shape(a1, ", ") -- JLF
     if .local~rgf.showIdentityHash then return "("a1~string "("shape || a1~items "items)" "id#_" || (a1~identityHash)")"
     else return "("a1~string "("shape || a1~items "items))"
  end
  else
     if .local~rgf.showIdentityHash then return "("a1~string "id#_" || (a1~identityHash)")"
     else return "("a1~string")"


/* ======================================================================= */
/* Enclose string in square brackets show non-printable chars as Rexx hex-strings.
   If non-string object, then show its string value and hash-value.

   Formats Index-values.
*/
::routine ppIndex2 public  -- rgf, 20091214
  use strict arg a1, surroundByQuotes=.true -- JLF: add surroundByQuotes

  if \a1~isA(.string) then
  do
     if a1~isA(.array), a1~dimension=1 then
     do
        -- if a1~dimension=1 then   -- create comma-delimited list of index-values?
        -- jlf: works only for non-sparse array, which is the case of array indexes
        do
           tmpStr=""
           bFirst=.true
           minWid=1
           maxElements=5
           do i=1 to a1~items for maxElements
              tmpVal=a1[i]
              if datatype(tmpVal,"W"), length(tmpVal)<minWid then
                 tmpVal=tmpVal~right(minWid)

              if bFirst then
              do
                 tmpStr=tmpVal
                 bFirst=.false
              end
              else
                 tmpStr=tmpStr","tmpVal~string -- jlf: add ~string to support correctly an array
           end
           if a1~items>maxElements then
           do
              tmpStr=tmpStr", ..."
           end
           return "["tmpStr"]"
        end
     end

     if .local~rgf.showIdentityHash then return "["a1~string "id#_" || (a1~identityHash)"]"
     return "["a1~string"]"
  end

  return pp2(a1, surroundByQuotes)     -- rgf, 20091228



/* Escape non-printable chars in Rexx-style. */
::routine escape2 public   -- rgf, 20091214
  parse arg a1

  res=""

  do while a1\==""
     pos1=verify(a1, .rgf.non.printable, "M")
     if pos1>0 then
     do
        pos2=verify(a1, .rgf.non.printable, "N" , pos1)

        if pos2=0 then
           pos2=length(a1)+1

        if pos1=1 then
        do
           parse var a1 char +(pos2-pos1) a1
           bef=""
        end
        else
           parse var a1 bef +(pos1-1) char +(pos2-pos1) a1

        if res=="" then
        do
           if bef \=="" then res=enquote2(bef) '|| '
        end
        else
        do
           res=res '||' enquote2(bef) '|| '
        end

        res=res || '"'char~c2x'"x'
     end
     else
     do
        if res<>""  then
           res=res '||' enquote2(a1)
        else
           res=a1

        a1=""
     end
  end
  return res



/* Escape non-printable chars by printing them between square brackets []. */
::routine escape3 public
  parse arg a1

  res=""

  do while a1\==""
     pos1=verify(a1, .rgf.non.printable, "M")
     if pos1>0 then
     do
        pos2=verify(a1, .rgf.non.printable, "N" , pos1)

        if pos2=0 then
           pos2=length(a1)+1

        if pos1=1 then
        do
           parse var a1 char +(pos2-pos1) a1
           bef=""
        end
        else
           parse var a1 bef +(pos1-1) char +(pos2-pos1) a1

        if res=="" then
        do
           if bef \=="" then res=bef -- res=enquote2(bef) '|| '
        end
        else
        do
           res=res||bef -- res=res '||' enquote2(bef) '|| '
        end

        res=res || '['char~c2x']'
     end
     else
     do
        if res<>""  then
           res=res||a1 -- res=res '||' enquote2(a1)
        else
           res=a1

        a1=""
     end
  end
  return res



/* ======================================================================= */
/* Returns a new relation object created from the passed in collection
   object. If the second argument is given, it must be a message name or
   a message object.


   makeRelation2(coll [,message])

      coll    ... collection or supplier object to turn into a relation object
      message ... optional, must be the name of a message or a message
                  object which gets sent to each object in the collection
                  and which result object is used as the index object to
                  which the collection object should be associated with
                  in the new relation
*/
::routine makeRelation2  public
  use strict arg coll, message=.nil

  if .nil=message then  -- only one argument, assuming collection object
  do
     return .relation~new~~putAll(coll~supplier)
  end

  if message~isA(.string) then      -- name of a message, create message object
     message=.message~new(.nil, message)
  else if \message~isA(.message) then
     raise syntax 36.900 array ("Argument 2 must be a message name (a string) or a message object!")

  rel=.relation~new
  do o over coll
     rel[message~copy~send(o)]=o    -- use message result as index for o
  end
  return rel




/* ======================================================================= */
/* Enquote string, escape quote/apostrophe. Optionally supply character(s) to serve as
   quote/apostrophe.
*/
::routine enquote2 public  -- rgf, 20091214
  use arg string, quote='"'

  return quote || string~changestr(quote, quote~copies(2)) || quote



/* ======================================================================= */
/*
   Expects a method object and an optional string for indenting/prefixing.

   Returns a string containing the source code or a comment indicating that
   no source code is available for the method.
*/
::routine ppMethod2 public -- rgf, 20091214
  use strict arg meth, indent=""

  src=meth~source       /* get source */

  tmpStr=""
  do s over src
     if tmpStr="" then  /* first round ?  */
        tmpStr=indent || s
     else
        tmpStr=tmpStr || .endOfLine || indent || s
  end

  if tmpStr="" then     /* no source code available   */
     return "/* no source code available */"

  return tmpStr


/* Class that allows to define deliberately which characters constitute
   delimiters of words or which characters constitute words. All word-related
   BIFs are implemented as methods. Operations that change the string value
   (methods delWord, subWord) will change the instance's string value accordingly.

   The characters that serve either as word-delimiters or as constituting
   words are available via the attribute "reference", the interpretation
   of the reference characters is controlled via the attribute "kind" (values
   "D"elimiter- or "W"ord-characters). The string value to operate on is available
   via the attribute "string".

   The following attributes are available:

   string    ... the string to work upon

   reference ... a string of characters that either serve as word delimiters or
                 define the characters that constitute words (e.g. allows for
                 defining all letters in German, including umlauts!)

   kind      ... determines how "reference" is interpreted: "D"elimiter characters
                 or "W"ord characters (characters that constitute a word)

   wordArray ... a read-only attribute that supplies a one-dimensional array of
                 words extracted from "string" according to "reference" characters
                 interpreted according to "kind"

   positionArray ... a read-only attribute that supplies a two-dimensional array
                 of positions and lengths of the words contained in "string"
                 according to "reference" characters interpreted according to "kind"

*/
::class "StringOfWords"
/* Arguments:
   string      ... mandatory
   reference   ... optional (default: " "||"09"x), defines a string of characters
   kind        ... optional (default: "D"), determines whether "reference" contains
                   characters that "d"elimit words or constitute "w"ords.
*/
::method init
  expose string oldKind positionArray wordArray

  signal on syntax
      -- check arguments
  use strict arg string, reference=(" "||"09"x), kind="D"

  .ArgUtil~validateClass("string",     string,    .string)  -- check for correct type

  .ArgUtil~validateClass("reference",  reference, .string)  -- check for correct type
  if reference=="" then       -- empty string, define default: blank/tab
     reference=" "||"09"x
  self~reference=reference -- assign reference

  .ArgUtil~validateClass("kind",       kind     , .string)  -- check for correct type
  self~kind=kind           -- check & assign "kind"-value
  return

syntax: raise propagate


::attribute string get
::attribute string set
  expose string posDirty? wordDirty?
  parse arg string
   -- make sure arrays are regenerated at access time
  posDirty?=.true
  wordDirty?=.true


::attribute reference get  -- character-string used for VERIFY()-reference
::attribute reference set
  expose reference oldReference dirty?
  parse arg tmp

  if reference\==tmp  then -- save "D" or "W" to use directly with parseWords2()
  do
     reference=tmp         -- save "D" or "W" to use directly with parseWords2()
     posDirty?=.true       -- on next access of pos+len-array, re-create array object
     wordDirty?=.true      -- on next access of pos+len-array, re-create array object
  end

   -- determines whether "reference" is used for determining space or word characters
   -- "D"elimiter-chars, "W"ord-chars
::attribute kind get
::attribute kind set
  expose internalKind kind posDirty? wordDirty?
  parse arg tmp .

  signal on syntax
  tmp1=tmp~left(1)~upper
  if pos(tmp1, "DW")=0 then
    raise syntax 93.914 array("'kind'", "D[elimiter] | W[ord-characters]", tmp)
  kind=tmp
  if internalKind<>tmp1 then  -- save "D" or "W" to use directly with parseWords2()
  do
     internalKind=tmp1     -- save "D" or "W" to use directly with parseWords2()
     posDirty?=.true       -- on next access of pos+len-array, re-create array object
     wordDirty?=.true      -- on next access of pos+len-array, re-create array object
  end
  return
syntax: raise propagate



::attribute positionArray get -- execute "parseWords2"
  expose posDirty? internalKind positionArray reference string

  if posDirty? then  -- string/reference/kind changed, make sure we (re-)generate the position/length array
  do
/* TODO: parseWords2() vs. parseWords() ? */
      positionArray=parseWords2(string, reference, internalKind, "P")
      posDirty?=.false
  end
  return positionArray~copy



::attribute wordArray get
  expose wordArray wordDirty? internalKind reference string

  if wordDirty? then  -- string/reference/kind changed, make sure we (re-)generate the position/length array
  do
/* TODO: parseWords2() vs. parseWords() ? */
      wordArray=parseWords2(string, reference, internalKind, "W")
      wordDirty?=.false
  end
  return wordArray~copy


::method makeArray
  forward message (wordArray)



/* The following methods are the counterparts of the word-related BIFs.
   It is intentional that the arrays are retrieved via a message, such that
   on-demand creating of the array object is possible and therefore reflects
   the words in the string according to the currently set delimiters and kinds
   of parsing.
*/



/* delWord(position[, length]) */
::method delWord     -- in place, i.e. changing this string ?
  expose string posDirty? wordDirty?

  signal on syntax
  use strict arg position, ...   -- make sure at least one argument
  parse arg position, length

  if \datatype(position, "W") then
     raise syntax 93.905 array("'position'", position)  -- must be a number

  if position=0 then             -- must not be null!
     raise syntax 93.924 array(position)  -- must be a number

  tmpString=string            -- default to string value

  arr=self~positionArray      -- get positional array
  words=arr~dimension(1)      -- get number of words

  if position<0 then             -- negative value? Position from right
  do
     position=words+position+1      -- get number of words, deduct "position"
     if position<1 then          -- not enough words in string, impossible to position value
     do
        position=1               -- position on first word
     end
  end

  if length="" then     -- length omitted? delete all remaining words
  do
     if position<=words then  -- only delete, if position is within words-range
     do
        tmpString=string~left(arr[position,1]-1)   -- change string in place
        posDirty?=.true
        wordDirty?=.true
     end
     return tmpString
  end
  else if \datatype(length, "W") then
     raise syntax 93.905 array("'length'", arg(2))  -- must be a number


  if length=0 then            -- don't change anything
  do
     return tmpString
  end

  if length<0 then            -- move positioning position to left?
  do
     tmpPos=position+length+1
     if tmpPos<1 then         -- beyond start, delete all words up to and including position
     do
        length=position       -- set length to position
        position=1            -- set start to 1
     end
     else
     do
        length=position-tmpPos+1 -- number of words affected
        position=tmpPos          -- starting position
     end
  end

  if position+length-1 < words then    -- after deleting there will be words left over?
  do
     tmpString=string~left(arr[position,1]-1) || string~substr(arr[position+length,1])
     posDirty?=.true
     wordDirty?=.true
  end
  else
  do
     if position<=words then
     do
        tmpString=string~left(arr[position,1]-1)
        posDirty?=.true
        wordDirty?=.true
     end
  end

  return tmpString

syntax: raise propagate


/* subWord() strips leading and trailing spaces of returned string (but keeps
   them between words)!
*/
::method subWord     -- result has never leading or trailing spaces!
  expose string

  signal on syntax
  use strict arg position, ...   -- make sure at least one argument
  parse arg position, length

  if \datatype(position, "W") then
     raise syntax 93.905 array("'position'", position)  -- must be a number

  if position=0 then             -- must not be null!
     raise syntax 93.924 array(position)  -- must be a number

  arr=self~positionArray      -- get positional array
  words=arr~dimension(1)      -- get number of words

  if position<0 then             -- negative value? Position from right
  do
     position=words+position+1   -- get number of words, deduct "position"
     if position<1 then          -- not enough words in string, impossible to position value
        position=1               -- position on first word
  end

  tmpString=""

  if length="" then     -- length omitted? delete all remaining words
  do
     if position>words then
        tmpString=""
     else
     do
        tmpPos=arr[position,1]            -- starting position (no leading spaces)
        endPos=arr[words,1]+arr[words,2]  -- ending position (no trailing spaces)
        tmpLen=endPos-tmpPos           -- calculate length
        tmpString=string~substr(tmpPos,tmpLen)  -- extract subword string
     end
     return tmpString
  end
  else if \datatype(length, "W") then
     raise syntax 93.905 array("'length'", arg(2))  -- must be a number


  if length=0 then         -- return empty string
  do
     tmpString=""
     return tmpString
  end

  if length<0 then         -- move positioning position to left?
  do
     tmpPos=position+length+1

     if tmpPos<1 then         -- beyond start, delete all words up to and including position
     do
        length=position       -- set length to position
        position=1            -- set start to 1
     end
     else
     do
        length=position-tmpPos+1 -- number of words affected
        position=tmpPos          -- starting position
     end

  end

  if position>words then
     tmpString=""
  else
  do
     tmpPos=arr[position,1]            -- starting position (no leading spaces)
     lastWord=min(position+length-1,words)        -- calc last word to be included
     endPos=arr[lastWord,1]+arr[lastWord,2]  -- ending position (no trailing spaces)
     tmpLen=endPos-tmpPos             -- calculate length
     tmpString=string~substr(tmpPos,tmpLen)  -- extract subword string
  end

  return tmpString

syntax: raise propagate



::method word        -- extract and return word
  expose string

  signal on syntax
  use strict arg position

  if \datatype(position, "W") then
     raise syntax 93.905 array("'n' (n-th word in string)", arg(2))  -- must be a number

  arr=self~positionArray      -- get positional array
  maxItems=arr~dimension(1)   -- get # of entries
  if position<1 then
  do
     position=maxItems+position+1  -- calc position from right
     if position<1 then       -- minimum start is 1
        return ""
  end

  if maxItems<position then
     return ""


  return string~substr(arr[position,1], arr[position,2]) -- return extracted word

syntax: raise propagate



::method words       -- return # of words
  return self~positionArray~dimension(1)



::method wordIndex
  signal on syntax
  use strict arg position

  if \datatype(position, "W") then
     raise syntax 93.905 array("'n' (n-th word in string)", arg(2))  -- must be a number

  arr=self~positionArray      -- get positional array
  maxItems=arr~dimension(1)   -- get # of entries
  if position<1 then
  do
     position=maxItems+position+1  -- calc position from right
     if position<1 then       -- minimum start is 1
        return 0
  end

  if maxItems<position then
     return 0

  return arr[position,1]      -- return length of word

syntax: raise propagate



::method wordLength
  signal on syntax
  use strict arg position

  if \datatype(position, "W") then
     raise syntax 93.905 array("'n' (n-th word in string)", arg(2))  -- must be a number

  arr=self~positionArray      -- get positional array
  maxItems=arr~dimension(1)   -- get # of entries
  if position<1 then
  do
     position=maxItems+position+1  -- calc position from right
     if position<1 then       -- minimum start is 1
        return 0
  end

  if maxItems<position then
     return 0

  return arr[position,2]      -- return length of word

syntax: raise propagate



::method wordPos
  expose string

  signal on syntax
  use strict arg phrase, startPos=1, letter="I"

  argNr=arg()     -- get total number of arguments

  if argNr=2 then -- only two args
  do
     if \ datatype(startPos,"W") then  -- the "letter" argument is last one?
     do
         letter=startPos~strip~left(1)~upper -- assuming C or I argument
         startPos=1
     end
  end

  if \datatype(startPos,"W") then
     raise syntax 93.905 array ("2 ('startPosition')", startPos)

  if arg(3,"Exists") then
     letter=letter~strip~left(1)~upper

  if pos(letter,"CI")=0 then     -- illegal argument!
     raise syntax 93.914 array (argNr, "C, I", arg(argNr))

  bCaselessCompare=(letter="I")

  arr=self~positionArray      -- get positional array

  phrObj=self~class~new(phrase)     -- wrap phrase, could contain more than one word!
  arrPhrasePos=phrObj~positionArray -- get position array of words
  arrPhraseWord=phrObj~wordArray    -- get array of words
  firstPhraseWordLength=arrPhrasePos[1,2] -- save length of first word in phrase

  maxItems=arr~dimension(1)         -- get maximum entries in dimension 1, i.e. max nr of words in string
  if startPos<1 then                -- negative start position
  do
     tmpPos=maxItems+startPos+1     -- calc start position from right
     if tmpPos<1 then               -- minimum start poistion is 1
        tmpPos=1

     startPos=tmpPos                -- set startPos
  end

  maxPhraseItems=arrPhrasePos~dimension(1)  -- get maximum of words in phrase
  do i=startPos to maxItems
     if arr[i,2]=firstPhraseWordLength then  -- o.k. word of same length
     do
         if (i+maxPhraseItems-1)>maxItems then  -- not enough words left, hence cannot match
            return 0                   -- indicate phrase not found

         bFound=.true
         do k=1 to maxPhraseItems while bFound
           m=i+k-1
           if bCaselessCompare then
              bFound=bFound & ((string~caselessMatch(arr[m,1], arrPhraseWord[k]))=1)
           else
              bFound=bFound & ((string~        match(arr[m,1], arrPhraseWord[k]))=1)
         end

         if bFound then             -- found! return position
            return i
     end
  end
  return 0                    -- not found


syntax: raise propagate


/* rgf, maybe "todo" as of 2010-01-12
   - Folding sort2() and stableSort2() ?
   - DateTime2: alle "toXXX", updateable, epochable
   - Class ConstantGroup
*/


/* create and return a string rendering of the supplied condition object
   rgf, 2011-06-08
*/
::routine ppCondition2 public
  use strict arg co, bShowPackageInfo=.false, indent1="09"x, lf=.endOfLine

  indent2=indent1~copies(2)
  indent3=indent1~copies(3)

  maxWidth=0            -- determine length of widest index
  do idx over co
     if idx~isA(.string) then maxWidth=max(maxWidth,idx~length)
  end
  maxWidth+=2           -- add square brackets

  mb=.MutableBuffer~new

  do idx over co~allindexes~sort
     entry=co[idx]
     mb~~append(indent1) ~~append(pp2(idx)~left(maxWidth)) ~~append("=") ~~append(pp2(entry)) ~~append(lf)
     if entry~isA(.collection) then
     do
        bStackFrames=(idx="STACKFRAMES")
        do val over entry
           mb ~~append(indent2) ~~append(pp2(val)) ~~append(lf)
           if bStackFrames then
           do
               type=val~type
               tmpStr="    running" ("/"type"/")~left(14)
               target=val~target
               if target<>.nil then
               do
                  tmpStr ||= " target:" pp2(target)
               end

               name=val~name
               if name<>.nil | name<>"" then
                  tmpStr ||= " name:" pp2(name)

               items=val~arguments~items
               if items>0 then
               do
                  if items>1 then tmpStr ||= " arguments: "
                             else tmpStr ||= " argument: "
                  tmpStr ||= pp2(args_to_string(val))
               end

               if val~executable<>.nil then
               do
                  pkgName=val~executable~package~name
                  tmpStr ||= " package:" pp2(pkgName)
/*
                  tmpStr ||= " package:" pp2(filespec('Name',pkgName))
                  location=filespec('Location',pkgName)
                  if location<>"" then tmpStr ||= " in" pp2(location)
*/
               end

               line=val~line
               if line<>.nil then tmpStr ||= ", line #" val~line

               mb ~~append(indent3) ~~append(tmpStr) ~~append(lf) ~~append(lf)
           end
        end
     end
     else if entry~isA(.package), bShowPackageInfo=.true then
     do
        mb ~~append(ppPackage2(entry, indent2, indent3, lf))
     end

  end

  return mb~string


args_to_string: procedure
  use arg stackFrame, maxLen=10
  args=stackFrame~arguments
  if args~size=0 then return ""

  if args~hasindex(1)=.false, args~size>1 then
     str=" "
  else
     str=""
say "... args_to_string:" "items="pp2(args~items) "size="pp2(args~size) pp2(args~toString(,","))
  do i=1 to args~size
     if args~hasindex(i)=.true then -- not omitted, process argument
     do
        val=args[i]
        tmp=""
        select
        when val=.nil then tmp=".nil"  -- .nil
        when val=""   then tmp='""'    -- empty string
        otherwise
           do
              tmp=val~string           -- get string representatoin
              if tmp~length>maxLen then
                 tmp=tmp~substr(1,maxLen)"..."
              tmp=enquote(tmp)
           end
        end
        str||=tmp

        if i<args~size then str ||=", "
     end
     else   -- omitted argument
     do
        str||=", "
     end
  end
  return str --~strip

enquote: procedure
  parse arg a
  q='"';qq='""'
  return q || a~changestr(q,qq) || q



/* Create and return a string rendering of the package information.
   rgf, 2011-06-08
*/
::routine ppPackage2 public
  use strict arg package, indent1="", indent2="09"x, lf=.endOfLine

  width=20
  mb = .MutableBuffer~new
  mb ~~append(indent1) ~~append(pp2("name")~left(width, ".")) ~~append(pp2(package~name)) ~~append(lf)
  mb ~~append(indent1) ~~append(pp2("size")~left(width, ".")) ~~append(pp2(package~sourceSize)) ~~append( " line(s)")~~append(lf)
  mb ~~append(indent1) ~~append("---") ~~append(lf)

  mb ~~append(indent1) ~~append(pp2("definedMethods")~left(width, ".")) ~~append(listCollection(package~definedMethods, indent2, lf)) ~~append(lf)
  mb ~~append(indent1) ~~append("---") ~~append(lf)

  mb ~~append(indent1) ~~append(pp2("defined classes")~left(width, ".")) ~~append(listCollection(package~classes, indent2, lf)) ~~append(lf)
  mb ~~append(indent1) ~~append(pp2("publicClasses")~left(width, ".")) ~~append(listCollection(package~publicClasses, indent2, lf)) ~~append(lf)
  mb ~~append(indent1) ~~append(pp2("importedClasses")~left(width, ".")) ~~append(listCollection(package~importedClasses, indent2, lf)) ~~append(lf)
  mb ~~append(indent1) ~~append("---") ~~append(lf)

  mb ~~append(indent1) ~~append(pp2("defined routines")~left(width, ".")) ~~append(listCollection(package~routines, indent2, lf)) ~~append(lf)
  mb ~~append(indent1) ~~append(pp2("publicRoutines")~left(width, ".")) ~~append(listCollection(package~publicRoutines, indent2, lf)) ~~append(lf)
  mb ~~append(indent1) ~~append(pp2("importedRoutines")~left(width, ".")) ~~append(listCollection(package~importedRoutines, indent2, lf)) ~~append(lf)
  mb ~~append(indent1) ~~append("---") ~~append(lf)

  mb ~~append(indent1) ~~append(pp2("importedPackages")~left(width, ".")) ~~append(listCollection(package~importedPackages, indent2, lf)) ~~append(lf)
  mb ~~append(indent1) ~~append("---") ~~append(lf)
  return mb~string


listCollection: procedure
  use strict arg coll, indent, lf
  mb=.MutableBuffer~new
  mb~~append(pp2(coll)) ~~append(lf)

  if coll~isA(.MapCollection) then
  do
     if coll~isA(.Directory) then   -- index is a string, comparisons are o.k.
        workColl=coll~allIndexes~sort
     else                           -- else make sure we get a string value to sort on
        workColl=sort2(coll~allIndexes, "Message", "string")
  end
  else   -- do not sort
      workColl=coll~allItems

  do idx over workColl  -- iterate over
     if idx~isA(.package) then
        mb~~append(indent) ~~append(pp2(idx~name)) ~~append(lf)
     else
        mb~~append(indent) ~~append(pp2(idx)) ~~append(lf)
  end
  return mb~string

