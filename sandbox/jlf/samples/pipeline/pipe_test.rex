#!/usr/bin/rexx
/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2006 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.oorexx.org/license.html                          */
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
/*  Show samples uses of the pipe implementation in pipe.rex                  */
/*                                                                            */
/*                                                                            */
/* -------------------------------------------------------------------------- */
/*                                                                            */
/*  Description:                                                              */
/*  This program demonstrates how one could use the pipes implemented in the  */
/*  pipe sample.                                                              */
/******************************************************************************/

info = .array~of('Tom','Mike','Rick','Steve')  /* Create an array to use      */
                                               /* stages on (any collection   */
                                               /* would work).                */

pipe = .sort|.reverse|.console                 /* Pipe to sort, reverse       */
                                               /* elements and display.       */

pipe~go(info)                                  /* Run it                      */

say '-----------------------------------'

pipe = .all['e']|.console                      /* Pipe to select elements with*/
                                               /* 'e' and display.            */

pipe~go(info)                                  /* Run it                      */
say '-----------------------------------'
valueArray1 = .array~new
indexArray1 = .array~new
valueArray2 = .array~new
indexArray2 = .array~new

-- this hooks stagess up to two different output streams
-- the >> secondary stage must preceed the primary hooked up to the same
-- stage
pipe = .all['e'] >> .arraycollector[valueArray2, indexArray2] > .arraycollector[valueArray1, indexArray1]


pipe~go(info)                                  /* Run it                      */


say 'Items selected by all are'

index = valueArray1~first
do while index <> .nil
   say index "#" indexArray1[index] ":" valueArray1[index]
   index = valueArray1~next(index)
end

say
say 'Items not selected by all are'

index = valueArray2~first
do while index <> .nil
   say index "#" indexArray2[index] ":" valueArray2[index]
   index = valueArray2~next(index)
end

say '-----------------------------------'

pipe = .sort|.stemcollector[a.]                /* Pipe to sort, put in a.     */

pipe~go(info)                                  /* Run it                      */

Do i = 1 To a.0                                /* Show stem values            */
  --Say a.i.index ":" a.i.value
  -- index is 'The NIL object' here. Don't know why a.i.'INDEX' doesn't work...
  Say a.[i, 'INDEX'] ":" a.i.value
End

say '-----------------------------------'

valueArray1 = .array~new
indexArray1 = .array~new
valueArray2 = .array~new
indexArray2 = .array~new

pivot = 'S'

pipe = .pivot[pivot, .arraycollector[valueArray1, indexArray1], .arraycollector[valueArray2, indexArray2]]

pipe~go(info)                                  /* Run it                      */

say 'Items less than pivot' pivot 'are'

index = valueArray1~first
do while index <> .nil
   say index "#" indexArray1[index] ":" valueArray1[index]
   index = valueArray1~next(index)
end

say
say 'Items greater than or equal to pivot' pivot 'are'

index = valueArray2~first
do while index <> .nil
   say index "#" indexArray2[index] ":" valueArray2[index]
   index = valueArray2~next(index)
end


::REQUIRES 'pipe'

