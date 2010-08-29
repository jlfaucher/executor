/* string.h
 *  Copyright (C) 2001-2003, Parrot Foundation.
 *  SVN Info
 *     $Id: string.h 46020 2010-04-26 05:43:32Z bacek $
 *  Overview:
 *     This is the api header for the string subsystem
 *  Data Structure and Algorithms:
 *  History:
 *  Notes:
 *  References:
 */

/*----------------------------------------------------------------------------*/
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

#ifndef M17N_STRING_H_GUARD
#define M17N_STRING_H_GUARD

/* String iterator */
struct String_iter {
    wholenumber_t bytepos;
    wholenumber_t charpos;
};

#define STRING_ITER_INIT(iter) \
    (iter)->charpos = (iter)->bytepos = 0
#define STRING_ITER_GET(str, iter, offset) \
    ((str)->getEncoding())->iter_get((str), (iter), (offset))
#define STRING_ITER_SKIP(str, iter, skip) \
    ((str)->getEncoding())->iter_skip((str), (iter), (skip))
#define STRING_ITER_GET_AND_ADVANCE(str, iter) \
    ((str)->getEncoding())->iter_get_and_advance((str), (iter))
#define STRING_ITER_SET_AND_ADVANCE(str, iter, c) \
    ((str)->getEncoding())->iter_set_and_advance((str), (iter), (c))
#define STRING_ITER_SET_POSITION(str, iter, pos) \
    ((str)->getEncoding())->iter_set_position((str), (iter), (pos))

#define STREQ(x, y)  (strcmp((x), (y))==0)
#define STRNEQ(x, y) (strcmp((x), (y))!=0)


#endif /* M17N_STRING_H_GUARD */
