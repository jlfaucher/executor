/*
Copyright (C) 2004-2009, Parrot Foundation.
$Id: charset.c 46998 2010-05-25 22:43:21Z darbelo $

=head1 NAME

src/string/charset.c - global charset functions

=head1 DESCRIPTION

These are m17n generic charset handling functions

=over 4

=cut

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

#define M17N_NO_EXTERN_CHARSET_PTRS

#include "RexxCore.h"
#include "StringClass.hpp"

#include "m17n_charset.h"
#include "m17n_string.h"

#include "encoding/m17n_encoding_fixed_8.h"
#include "encoding/m17n_encoding_utf8.h"
#include "encoding/m17n_encoding_utf16.h"
#include "encoding/m17n_encoding_ucs2.h"
#include "encoding/m17n_encoding_ucs4.h"

#include "charset/m17n_charset_ascii.h"
#include "charset/m17n_charset_binary.h"
#include "charset/m17n_charset_iso-8859-1.h"
#include "charset/m17n_charset_unicode.h"

#include <vector>   // temporary, until I switch to ooRexx collection

CHARSET *m17n_iso_8859_1_charset_ptr;
CHARSET *m17n_binary_charset_ptr;
CHARSET *m17n_default_charset_ptr;
CHARSET *m17n_unicode_charset_ptr;
CHARSET *m17n_ascii_charset_ptr;

/* all registered charsets are collected in one global structure */

typedef struct To_converter {
    CHARSET *to;
    charset_converter_t func;
} To_converter;

typedef struct One_charset {
    CHARSET *charset;
    // RexxString *name; // tofojlf : redundant
    std::vector<To_converter> to_converters;
} One_charset;

static std::vector<One_charset> all_charsets;

static void register_static_converters();


/*

=item C<void m17n_deinit()>

Deinitializes (unloads) the charset system. Frees all charsets and the array
that holds the charsets back to the system.

=cut

*/

void
m17n_deinit()
{
    int i;
    const int n = all_charsets.size();

    for (i = 0; i < n; ++i) {
        all_charsets[i].to_converters.clear();
        delete all_charsets[i].charset;
    }
    all_charsets.clear();
    m17n_deinit_encodings();
}

/*

=item C<CHARSET * m17n_find_charset(const char
*charsetname)>

Searches through the list of charsets for the charset given by C<charsetname>.
Returns the charset if it is found, NULL otherwise.

=cut

*/

CHARSET *
m17n_find_charset(const char *charsetname, bool raiseException)
{
    int i;
    const int n = all_charsets.size();

    for (i = 0; i < n; ++i) {
        if (STREQ(all_charsets[i].charset->name, charsetname))
            return all_charsets[i].charset;
    }

    if (raiseException) 
    {
        RexxString *msg = raw_string(200, 200);
        rsnprintf(msg, "Can't make %s charset strings", charsetname);
        reportException(Rexx_Error_Execution_user_defined, msg);
    }

    return NULL;
}

/*

=item C<CHARSET * m17n_load_charset(const char
*charsetname)>

Throws an exception (Can't load charsets dynamically yet. https://trac.parrot.org/parrot/wiki/StringsTasklist).

=cut

*/

CHARSET *
m17n_load_charset(const char *charsetname)
{
    reportException(Rexx_Error_Execution_user_defined,
        "Can't load charsets yet");
    return NULL;
}

/*

=item C<wholenumber_t m17n_charset_number(RexxString *charsetname)>

Return the number of the charset or -1 if not found.

=cut

*/

wholenumber_t
m17n_charset_number(RexxString *charsetname)
{
    int i;
    const int n = all_charsets.size();

    for (i = 0; i < n; ++i) {
        if (charsetname->strCompare(all_charsets[i].charset->name))
            return i;
    }
    return -1;
}

/*

=item C<wholenumber_t m17n_charset_number_of_str(RexxString *src)>

Return the number of the charset of the given string or -1 if not found.

=cut

*/

wholenumber_t
m17n_charset_number_of_str(IRexxString *src)
{
    int i;
    const int n = all_charsets.size();

    for (i = 0; i < n; ++i) {
        if (src->getCharset() == all_charsets[i].charset)
            return i;
    }
    return -1;
}

/*

=item C<RexxString * m17n_charset_name(wholenumber_t number_of_charset)>

Returns the name of the charset given by the wholenumber_t index
C<number_of_charset>.

=cut

*/

RexxString *
m17n_charset_name(wholenumber_t number_of_charset)
{
    if (number_of_charset < 0 || number_of_charset >= (wholenumber_t)all_charsets.size())
        return NULL;
    return new_string(all_charsets[number_of_charset].charset->name);
}

/*

=item C<CHARSET * m17n_get_charset(wholenumber_t
number_of_charset)>

Returns the charset given by the wholenumber_t index C<number_of_charset>.

=cut

*/

CHARSET *
m17n_get_charset(wholenumber_t number_of_charset)
{
    if (number_of_charset < 0 || number_of_charset >= (wholenumber_t)all_charsets.size())
        return NULL;
    return all_charsets[number_of_charset].charset;
}

/*

=item C<const char * m17n_charset_c_name(wholenumber_t
number_of_charset)>

Returns a NULL-terminated C string with the name of the charset given by
wholenumber_t index C<number_of_charset>.

=cut

*/

const char *
m17n_charset_c_name(wholenumber_t number_of_charset)
{
    if (number_of_charset < 0 || number_of_charset >= (wholenumber_t)all_charsets.size())
        return NULL;
    return all_charsets[number_of_charset].charset->name;
}

/*

=item C<static wholenumber_t register_charset(CHARSET *charset)>

Adds a new charset C<charset> to the list of all charsets. 
Returns -1 and does nothing if a charset with that name
already exists. Returns the index (>= 0) otherwise.

=cut

*/

static wholenumber_t
register_charset(CHARSET *charset)
{
    int i;
    const int n = all_charsets.size();

    for (i = 0; i < n; ++i) {
        if (STREQ(all_charsets[i].charset->name, charset->name))
            return -1;
    }
    all_charsets.resize(n+1);
    all_charsets[n].charset = charset;
    charset->number = n;

    return n;
}

/*

/*

=item C<static void register_static_converters()>

Registers several standard converters between common charsets, including:

    ISO 8859_1 -> ascii
    ISO 8859_1 -> bin
    ascii -> bin
    ascii -> ISO 8859_1

=cut

*/

static void
register_static_converters()
{
    m17n_register_charset_converter(
            m17n_iso_8859_1_charset_ptr, m17n_ascii_charset_ptr,
            charset_cvt_iso_8859_1_to_ascii);
    m17n_register_charset_converter(
            m17n_iso_8859_1_charset_ptr, m17n_binary_charset_ptr,
            charset_cvt_ascii_to_binary);

    m17n_register_charset_converter(
            m17n_ascii_charset_ptr, m17n_binary_charset_ptr,
            charset_cvt_ascii_to_binary);
    m17n_register_charset_converter(
            m17n_ascii_charset_ptr, m17n_iso_8859_1_charset_ptr,
            charset_cvt_ascii_to_iso_8859_1);
}

/*

=item C<wholenumber_t m17n_register_charset(const char *charsetname,
CHARSET *charset)>

Register a new charset C<charset> with name C<charsetname>. Charset may only
be one of the 4 following names:

    binary
    iso-8859-1
    unicode
    ascii

Attempts to register other charsets are ignored. Returns 0 if the registration
failed, for any reason.

=cut

*/

wholenumber_t
m17n_register_charset(CHARSET *charset)
{
    if (STREQ("binary", charset->name)) {
        m17n_binary_charset_ptr = charset;
        return register_charset(charset);
    }

    if (STREQ("iso-8859-1", charset->name)) {
        m17n_iso_8859_1_charset_ptr = charset;
        return register_charset(charset);
    }

    if (STREQ("unicode", charset->name)) {
        m17n_unicode_charset_ptr = charset;
        return register_charset(charset);
    }

    if (STREQ("ascii", charset->name)) {
        if (!m17n_default_charset_ptr)
            m17n_default_charset_ptr = charset;

        m17n_ascii_charset_ptr = charset;
        return register_charset(charset);
    }

    return 0;
}

/*

=item C<void m17n_init()>

Creates the initial charsets and encodings, and registers the initial
charset converters.

=cut

*/

void
m17n_init()
{
    /* the order is crucial here:
     * 1) encodings, default = fixed_8
     * 2) charsets   default = ascii */
    m17n_encoding_fixed_8_init();
    m17n_encoding_utf8_init();
    m17n_encoding_ucs2_init();
    m17n_encoding_utf16_init();
    m17n_encoding_ucs4_init();

    m17n_charset_ascii_init();
    m17n_charset_iso_8859_1_init();
    m17n_charset_binary_init();
    m17n_charset_unicode_init();

    /* now install charset converters */
    register_static_converters();
}

/*

=item C<wholenumber_t m17n_make_default_charset(const char
*charsetname, CHARSET *charset)>

Sets the current default charset to C<charset> with name C<charsetname>.

=cut

*/

wholenumber_t
m17n_make_default_charset(const char *charsetname,
        CHARSET *charset)
{
    m17n_default_charset_ptr = charset;
    return 1;
}

/*

=item C<CHARSET * m17n_default_charset()>

Returns the default charset.

=cut

*/

CHARSET *
m17n_default_charset()
{
    return m17n_default_charset_ptr;
}

/*

=item C<charset_converter_t m17n_find_charset_converter(const
CHARSET *lhs, CHARSET *rhs)>

Finds a converter from charset C<lhs> to charset C<rhs>.

=cut

*/

charset_converter_t
m17n_find_charset_converter(
        CHARSET *lhs, CHARSET *rhs)
{
    int i;
    const int n = all_charsets.size();

    for (i = 0; i < n; ++i) {
        if (lhs == all_charsets[i].charset) {
            One_charset& left = all_charsets[i];
            const int nc = left.to_converters.size();
            int j;
            for (j = 0; j < nc; ++j) {
                if (left.to_converters[j].to == rhs)
                    return left.to_converters[j].func;
            }
        }
    }
    return NULL;
}

/*

=item C<void m17n_register_charset_converter(CHARSET
*lhs, CHARSET *rhs, charset_converter_t func)>

Registers a converter C<func> from charset C<lhs> to C<rhs>.

=cut

*/

void
m17n_register_charset_converter(
        CHARSET *lhs, CHARSET *rhs,
        charset_converter_t func)
{
    int i;
    const int n = all_charsets.size();

    for (i = 0; i < n; ++i) {
        if (lhs == all_charsets[i].charset) {
            One_charset& left = all_charsets[i];
            const int nc = left.to_converters.size();

            left.to_converters.resize(nc+1);
            left.to_converters[nc].to = rhs;
            left.to_converters[nc].func = func;
        }
    }
}
