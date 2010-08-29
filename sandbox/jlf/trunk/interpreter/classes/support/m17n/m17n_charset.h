/* charset.h
 *  Copyright (C) 2004-2010, Parrot Foundation.
 *  SVN Info
 *     $Id: charset.h 46897 2010-05-22 20:50:13Z plobsing $
 *  Overview:
 *     This is the header for the 8-bit fixed-width encoding
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

#ifndef M17N_CHARSET_H_GUARD
#define M17N_CHARSET_H_GUARD


#include "m17n/m17n_encoding.h"
#include "m17n/m17n_cclass.h"

class CHARSET;
class IRexxString;
class RexxString;


#if !defined M17N_NO_EXTERN_CHARSET_PTRS
extern CHARSET *m17n_iso_8859_1_charset_ptr;
extern CHARSET *m17n_binary_charset_ptr;
extern CHARSET *m17n_default_charset_ptr;
extern CHARSET *m17n_unicode_charset_ptr;
extern CHARSET *m17n_ascii_charset_ptr;
#endif


// Not yet implemented
typedef RexxString * (*charset_from_unicode_t)(RexxString *src);
typedef wholenumber_t   (*charset_is_wordchar_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_wordchar_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_not_wordchar_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_is_whitespace_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_whitespace_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_not_whitespace_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_is_digit_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_digit_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_not_digit_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_is_punctuation_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_punctuation_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_not_punctuation_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_is_newline_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_newline_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_not_newline_t)(RexxString *src, wholenumber_t offset);
typedef wholenumber_t   (*charset_find_word_boundary_t)(RexxString *src, wholenumber_t offset);

typedef RexxString * (*charset_converter_t)(RexxString *src);

const char * m17n_charset_c_name(wholenumber_t number_of_charset);
RexxString * m17n_charset_name(wholenumber_t number_of_charset);
wholenumber_t m17n_charset_number(RexxString *charsetname);
wholenumber_t m17n_charset_number_of_str(IRexxString *src);

void m17n_deinit();
void m17n_init();

CHARSET * m17n_default_charset();

CHARSET * m17n_find_charset(const char *charsetname, bool raiseException=false);

charset_converter_t m17n_find_charset_converter(CHARSET *lhs, CHARSET *rhs);

CHARSET * m17n_get_charset(wholenumber_t number_of_charset);

CHARSET * m17n_load_charset(const char *charsetname);

wholenumber_t m17n_make_default_charset(
    const char *charsetname,
    CHARSET *charset);

wholenumber_t m17n_register_charset(CHARSET *charset);

void m17n_register_charset_converter(
    CHARSET *lhs,
    CHARSET *rhs,
    charset_converter_t func);


class CHARSET {
public:
    virtual RexxString * get_graphemes(RexxString *src, wholenumber_t offset, wholenumber_t count) = 0;
    virtual RexxString * convert(RexxString *src) = 0; // JLF : previous name was to_charset (not appropriate)
    virtual RexxString * compose(RexxString *src) = 0;
    virtual RexxString * decompose(RexxString *src) = 0;
    virtual RexxString * upcase(RexxString *src) = 0;
    virtual RexxString * downcase(RexxString *src) = 0;
    virtual RexxString * titlecase(RexxString *src) = 0;
    virtual RexxString * upcase_first(RexxString *src) = 0;
    virtual RexxString * downcase_first(RexxString *src) = 0;
    virtual RexxString * titlecase_first(RexxString *src) = 0;
    virtual wholenumber_t compare(IRexxString *lhs, IRexxString *rhs) = 0;
    virtual wholenumber_t index(IRexxString *src, IRexxString *search_string, wholenumber_t offset) = 0;
    virtual wholenumber_t rindex(IRexxString *src, IRexxString *search_string, wholenumber_t offset) = 0;
    virtual wholenumber_t validate(IRexxString *src) = 0;
    virtual wholenumber_t is_cclass(wholenumber_t, IRexxString *src, wholenumber_t offset) = 0;
    virtual wholenumber_t find_cclass(wholenumber_t, IRexxString *src, wholenumber_t offset, wholenumber_t count) = 0;
    virtual wholenumber_t find_not_cclass(wholenumber_t, IRexxString *src, wholenumber_t offset, wholenumber_t count) = 0;
    virtual RexxString * string_from_codepoint(wholenumber_t codepoint) = 0;

    wholenumber_t number;
    const char *name;
    ENCODING *preferred_encoding;
};

#define CHARSET_GET_GRAPHEMES(source, offset, count) ((source)->getCharset())->get_graphemes((source), (offset), (count))
#define CHARSET_TO_UNICODE(source, dest) ((source)->getCharset())->to_unicode((source), (dest)) /* JLF deprecated */
#define CHARSET_COMPOSE(source) ((source)->getCharset())->compose((source))
#define CHARSET_DECOMPOSE(source) ((source)->getCharset())->decompose((source))
#define CHARSET_UPCASE(source) ((source)->getCharset())->upcase((source))
#define CHARSET_DOWNCASE(source) ((source)->getCharset())->downcase((source))
#define CHARSET_TITLECASE(source) ((source)->getCharset())->titlecase((source))
#define CHARSET_UPCASE_FIRST(source) ((source)->getCharset())->upcase_first((source))
#define CHARSET_DOWNCASE_FIRST(source) ((source)->getCharset())->downcase_first((source))
#define CHARSET_TITLECASE_FIRST(source) ((source)->getCharset())->titlecase_first((source))
#define CHARSET_COMPARE(lhs, rhs) ((CHARSET *)(lhs)->getCharset())->compare((lhs), (rhs))
#define CHARSET_INDEX(source, search, offset) ((source)->getCharset())->index((source), (search), (offset))
#define CHARSET_RINDEX(source, search, offset) ((source)->getCharset())->rindex((source), (search), (offset))
#define CHARSET_VALIDATE(source) ((source)->getCharset())->validate((source))
#define CHARSET_IS_CCLASS(flags, source, offset) ((source)->getCharset())->is_cclass((flags), (source), (offset))
#define CHARSET_FIND_CCLASS(flags, source, offset, count) ((source)->getCharset())->find_cclass((flags), (source), (offset), (count))
#define CHARSET_FIND_NOT_CCLASS(flags, source, offset, count) ((source)->getCharset())->find_not_cclass((flags), (source), (offset), (count))
#define CHARSET_GET_PREFERRED_ENCODING(source) ((source)->getCharset())->preferred_encoding

#define CHARSET_ENCODE(source) ((source)->getEncoding())->encode((source)) /* JLF previous name was CHARSET_TO_ENCODING (not appropriate) */
#define CHARSET_GET_CODEPOINT(source, offset) ((source)->getEncoding())->get_codepoint((source), (offset))
#define CHARSET_GET_BYTE(source, offset) ((source)->getEncoding())->get_byte((source), (offset))
#define CHARSET_SET_BYTE(source, offset, value) ((source)->getEncoding())->set_byte((source), (offset), (value))
#define CHARSET_GET_CODEPOINTS(source, offset, count) ((source)->getEncoding())->get_codepoints((source), (offset), (count))
#define CHARSET_GET_BYTES(source, offset, count) ((source)->getEncoding())->get_bytes((source), (offset), (count))
#define CHARSET_CODEPOINTS(source) ((source)->getEncoding())->codepoints((source))
#define CHARSET_BYTES(source) ((source)->getEncoding())->bytes((source))


#endif /* M17N_CHARSET_H_GUARD */
