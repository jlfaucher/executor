/* encoding.h
 *  Copyright (C) 2004-2007, Parrot Foundation.
 *  SVN Info
 *     $Id: encoding.h 46999 2010-05-25 22:53:48Z darbelo $
 *  Overview:
 *     This is the header for the generic encoding functions
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

#ifndef M17N_ENCODING_H_GUARD
#define M17N_ENCODING_H_GUARD

#include "m17n_string.h"

class IRexxString;
class RexxString;
class RexxMutableBuffer;

class ENCODING {
public:
    virtual RexxMutableBuffer * encode(IRexxString *src) = 0; // JLF : previous name was to_encoding (not appropriate)
    virtual codepoint_t get_codepoint(IRexxString *src, sizeC_t offset) = 0;
    virtual wholenumber_t get_byte(IRexxString *src, sizeB_t offset) = 0;
    virtual void set_byte(IRexxString *src, sizeB_t offset, wholenumber_t byte) = 0;
    virtual RexxString * get_codepoints(RexxString *src, sizeC_t offset, sizeC_t count) = 0;
    virtual RexxString * get_bytes(RexxString *src, sizeB_t offset, sizeB_t count) = 0;
    virtual sizeC_t codepoints(IRexxString *src) = 0;
    virtual sizeC_t codepoints(const char *src, sizeB_t blength) = 0;
    virtual sizeB_t bytes(IRexxString *src) = 0;
    virtual sizeC_t find_cclass(IRexxString *s, wholenumber_t *typetable, wholenumber_t flags, sizeC_t offset, sizeC_t count) = 0;

    virtual codepoint_t iter_get(IRexxString *str, String_iter *i, sizeC_t offset) = 0;
    virtual void iter_skip(IRexxString *str, String_iter *i, sizeC_t skip) = 0;
    virtual codepoint_t iter_get_and_advance(IRexxString *str, String_iter *i) = 0;
    virtual void iter_set_and_advance(IRexxString *str, String_iter *i, codepoint_t c) = 0;
    virtual void iter_set_position(IRexxString *str, String_iter *i, sizeC_t pos) = 0;

    wholenumber_t number;
    const char *name;
    uint8_t max_bytes_per_codepoint;
};


//#if !defined M17N_NO_EXTERN_ENCODING_PTRS
extern ENCODING *m17n_fixed_8_encoding_ptr;
extern ENCODING *m17n_utf8_encoding_ptr;
extern ENCODING *m17n_utf16_encoding_ptr;
extern ENCODING *m17n_ucs2_encoding_ptr;
extern ENCODING *m17n_ucs4_encoding_ptr;
extern ENCODING *m17n_default_encoding_ptr;
//#endif

#define M17N_DEFAULT_ENCODING m17n_fixed_8_encoding_ptr
#define M17N_FIXED_8_ENCODING m17n_fixed_8_encoding_ptr
#define M17N_DEFAULT_FOR_UNICODE_ENCODING NULL

typedef wholenumber_t (*encoding_converter_t)(ENCODING *lhs, ENCODING *rhs);

ENCODING * m17n_default_encoding();

const char * m17n_encoding_c_name(wholenumber_t number_of_encoding);

RexxString* m17n_encoding_name(wholenumber_t number_of_encoding);

wholenumber_t m17n_encoding_number(RexxString *encodingname);

wholenumber_t m17n_encoding_number_of_str(IRexxString *src);

ENCODING * m17n_find_encoding(const char *encodingname);

encoding_converter_t m17n_find_encoding_converter(
    ENCODING *lhs,
    ENCODING *rhs);

ENCODING* m17n_get_encoding(wholenumber_t number_of_encoding);

ENCODING * m17n_load_encoding(const char *encodingname);

wholenumber_t m17n_make_default_encoding(
    const char *encodingname,
    ENCODING *encoding);

wholenumber_t m17n_register_encoding(ENCODING *encoding);

void m17n_deinit_encodings();


#define ENCODING_GET_CODEPOINT(src, offset) \
    ((src)->getEncoding())->get_codepoint((src), (offset))
#define ENCODING_GET_BYTE(src, offset) \
    ((src)->getEncoding())->get_byte((src), (offset))
#define ENCODING_SET_BYTE(src, offset, value) \
    ((src)->getEncoding())->set_byte((src), (offset), (value))
#define ENCODING_GET_CODEPOINTS(src, offset, count) \
    ((src)->getEncoding())->get_codepoints((src), (offset), (count))
#define ENCODING_GET_BYTES(src, offset, count) \
    ((src)->getEncoding())->get_bytes((src), (offset), (count))
#define ENCODING_FIND_CCLASS(src, typetable, flags, pos, end) \
    ((src)->getEncoding())->find_cclass((src), (typetable), (flags), (pos), (end))

#endif /* M17N_ENCODING_H_GUARD */
