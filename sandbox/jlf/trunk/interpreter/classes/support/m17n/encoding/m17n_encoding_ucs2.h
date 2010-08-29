/* ucs2.h
 *  Copyright (C) 2004, Parrot Foundation.
 *  SVN Info
 *     $Id: ucs2.h 45852 2010-04-21 10:06:00Z bacek $
 *  Overview:
 *     This is the header for the ucs2 fixed-width encoding.
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

#ifndef M17N_ENCODING_UCS2_H_GUARD
#define M17N_ENCODING_UCS2_H_GUARD

#include "m17n_encoding.h"

class ENCODING_UCS2 : public ENCODING {
public:
    RexxMutableBuffer * encode(IRexxString *src);
    wholenumber_t get_codepoint(IRexxString *src, wholenumber_t offset);
    wholenumber_t get_byte(IRexxString *src, wholenumber_t offset);
    void set_byte(IRexxString *src, wholenumber_t offset, wholenumber_t count);
    RexxString * get_codepoints(RexxString *src, wholenumber_t offset, wholenumber_t count);
    RexxString * get_bytes(RexxString *src, wholenumber_t offset, wholenumber_t count);
    wholenumber_t codepoints(IRexxString *src);
    wholenumber_t codepoints(const char *src, wholenumber_t blength);
    wholenumber_t bytes(IRexxString *src);
    wholenumber_t find_cclass(IRexxString *s, wholenumber_t *typetable, wholenumber_t flags, wholenumber_t offset, wholenumber_t count);

    wholenumber_t iter_get(IRexxString *str, String_iter *i, wholenumber_t offset);
    void iter_skip(IRexxString *str, String_iter *i, wholenumber_t skip);
    wholenumber_t iter_get_and_advance(IRexxString *str, String_iter *i);
    void iter_set_and_advance(IRexxString *str, String_iter *i, wholenumber_t c);
    void iter_set_position(IRexxString *str, String_iter *i, wholenumber_t pos);
};

void m17n_encoding_ucs2_init();

#endif /* M17N_ENCODING_UCS2_H_GUARD */
