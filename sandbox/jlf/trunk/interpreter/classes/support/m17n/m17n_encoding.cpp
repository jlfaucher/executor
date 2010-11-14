/*
Copyright (C) 2004-2010, Parrot Foundation.
$Id: encoding.c 46998 2010-05-25 22:43:21Z darbelo $

=head1 NAME

src/string/encoding.c - global encoding functions

=head1 DESCRIPTION

These are m17n generic encoding handling functions

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

#include "RexxCore.h"
#include "StringClass.hpp"

#include "m17n_encoding.h"
#include "m17n_string.h"

#include <vector>

ENCODING *m17n_default_encoding_ptr = NULL;
ENCODING *m17n_fixed_8_encoding_ptr = NULL;
ENCODING *m17n_utf8_encoding_ptr    = NULL;
ENCODING *m17n_ucs2_encoding_ptr    = NULL;
ENCODING *m17n_utf16_encoding_ptr   = NULL;
ENCODING *m17n_ucs4_encoding_ptr    = NULL;

typedef struct One_encoding {
    ENCODING *encoding;
    // RexxString *name; // todojlf : redundant
} One_encoding;

static std::vector<One_encoding> all_encodings;

/*

=item C<void m17n_deinit_encodings()>

Deinitialize encodings and free all memory used by them.

=cut

*/

void
m17n_deinit_encodings()
{
    const int n = all_encodings.size();
    int i;

    for (i = 0; i < n; ++i) {
        delete all_encodings[i].encoding;
    }
    all_encodings.clear();
}

/*

=item C<ENCODING * m17n_find_encoding(const char
*encodingname)>

Finds an encoding with the name C<encodingname>. Returns the encoding
if it is successfully found, returns NULL otherwise.

=cut

*/

ENCODING *
m17n_find_encoding(const char *encodingname)
{
    const int n = all_encodings.size();
    int i;

    for (i = 0; i < n; ++i)
        if (STREQ(all_encodings[i].encoding->name, encodingname))
            return all_encodings[i].encoding;
    return NULL;
}

/*

=item C<ENCODING * m17n_load_encoding(const char
*encodingname)>

Loads an encoding. Currently throws an exception because we cannot load
encodings. See https://trac.parrot.org/parrot/wiki/StringsTasklist.

=cut

*/

/* Yep, this needs to be a char * parameter -- it's tough to load in
   encodings and such for strings if we can't be sure we've got enough
   info set up to actually build strings...

 */

ENCODING *
m17n_load_encoding(const char *encodingname)
{
    reportException(Rexx_Error_Execution_user_defined,
        "Can't load encodings yet");
    return NULL;
}

/*

=item C<wholenumber_t m17n_encoding_number(RexxString
*encodingname)>

Return the number of the encoding or -1 if not found.

=cut

*/

wholenumber_t
m17n_encoding_number(RexxString *encodingname)
{
    const int n = all_encodings.size();
    int i;

    for (i = 0; i < n; ++i) {
        if (encodingname->strCompare(all_encodings[i].encoding->name))
            return i;
    }
    return -1;
}

/*

=item C<wholenumber_t m17n_encoding_number_of_str(RexxString *src)>

Return the number of the encoding of the given string or -1 if not found.

=cut

*/

wholenumber_t
m17n_encoding_number_of_str(IRexxString *src)
{
    const int n = all_encodings.size();
    int i;

    for (i = 0; i < n; ++i) {
        if (src->getEncoding() == all_encodings[i].encoding)
            return i;
    }
    return -1;
}

/*

=item C<RexxString* m17n_encoding_name(wholenumber_t number_of_encoding)>

Returns the name of a character encoding based on the wholenumber_t index
C<number_of_encoding> to the All_encodings array.

=cut

*/

RexxString*
m17n_encoding_name(wholenumber_t number_of_encoding)
{
    if (number_of_encoding >= (wholenumber_t)all_encodings.size() ||
        number_of_encoding < 0)
        return NULL;
    return new_string(all_encodings[number_of_encoding].encoding->name);
}

/*

=item C<ENCODING* m17n_get_encoding(wholenumber_t
number_of_encoding)>

Returns the encoding given by the wholenumber_t index C<number_of_encoding>.

=cut

*/

ENCODING*
m17n_get_encoding(wholenumber_t number_of_encoding)
{
    if (number_of_encoding >= (wholenumber_t)all_encodings.size() ||
        number_of_encoding < 0)
        return NULL;
    return all_encodings[number_of_encoding].encoding;
}

/*

=item C<const char * m17n_encoding_c_name(wholenumber_t
number_of_encoding)>

Returns the NULL-terminated C string representation of the encodings name
given by the C<number_of_encoding>.

=cut

*/

const char *
m17n_encoding_c_name(wholenumber_t number_of_encoding)
{
    if (number_of_encoding >= (wholenumber_t)all_encodings.size() ||
        number_of_encoding < 0)
        return NULL;
    return all_encodings[number_of_encoding].encoding->name;
}

/*

=item C<static wholenumber_t register_encoding(ENCODING *encoding)>

Registers a new character encoding C<encoding>.
Returns the index (>= 0) if successful, returns -1 otherwise (if name already used).

=cut

*/

static wholenumber_t
register_encoding(ENCODING *encoding)
{
    const int n = all_encodings.size();
    int i;

    for (i = 0; i < n; ++i) {
        if (STREQ(all_encodings[i].encoding->name, encoding->name))
            return -1;
    }
    all_encodings.resize(n+1);
    all_encodings[n].encoding = encoding;
    encoding->number = n;

    return n;
}

/*

=item C<wholenumber_t m17n_register_encoding(ENCODING *encoding)>

Registers a character encoding C<encoding>.
Only allows one of 5 possibilities: fixed_8, utf8, utf16, ucs2 and ucs4.

=cut

*/

wholenumber_t
m17n_register_encoding(ENCODING *encoding)
{
    if (STREQ("fixed-8", encoding->name)) {
        m17n_fixed_8_encoding_ptr = encoding;
        if (!m17n_default_encoding_ptr) {
            m17n_default_encoding_ptr = encoding;

        }
        return register_encoding(encoding);
    }
    if (STREQ("utf-8", encoding->name)) {
        m17n_utf8_encoding_ptr = encoding;
        return register_encoding(encoding);
    }
    if (STREQ("utf-16", encoding->name)) {
        m17n_utf16_encoding_ptr = encoding;
        return register_encoding(encoding);
    }
    if (STREQ("ucs-2", encoding->name)) {
        m17n_ucs2_encoding_ptr = encoding;
        return register_encoding(encoding);
    }
    if (STREQ("ucs-4", encoding->name)) {
        m17n_ucs4_encoding_ptr = encoding;
        return register_encoding(encoding);
    }
    return 0;
}

/*

=item C<wholenumber_t m17n_make_default_encoding(const char
*encodingname, ENCODING *encoding)>

Sets the default encoding to C<encoding> with name C<encodingname>.

=cut

*/

wholenumber_t
m17n_make_default_encoding(const char *encodingname,
        ENCODING *encoding)
{
    m17n_default_encoding_ptr = encoding;
    return 1;
}

/*

=item C<ENCODING * m17n_default_encoding()>

Gets the default encoding.

=cut

*/

ENCODING *
m17n_default_encoding()
{
    return m17n_default_encoding_ptr;
}

/*

=item C<encoding_converter_t m17n_find_encoding_converter(
ENCODING *lhs, ENCODING *rhs)>

Finds a converter from encoding C<rhs> to C<lhs>. Not yet implemented, so
throws an exception.

=cut

*/

encoding_converter_t
m17n_find_encoding_converter(ENCODING *lhs, ENCODING *rhs)
{
    /* XXX Apparently unwritten https://trac.parrot.org/parrot/wiki/StringsTasklist */
    reportException(Rexx_Error_Execution_user_defined,
        "Can't find encoding converters yet.");
    return NULL;
}
