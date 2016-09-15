/*
Copyright (C) 2004-2010, Parrot Foundation.
$Id: ascii.c 47917 2010-06-29 23:18:38Z jkeenan $

=head1 NAME

src/string/charset/ascii.c

=head1 DESCRIPTION

This file implements the charset functions for ascii data and common
charset functionality for similar charsets like iso-8859-1.

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

#include "m17n_string.h"
#include "m17n_string_funcs.h"
#include "m17n_encoding.h"
#include "m17n_charset_ascii.h"

/*
 * TODO check interpreter error and warnings setting
 */

#include "m17n_charset_tables.h"

/*

=item C<RexxString * ascii_get_graphemes(RexxString *src, sizeC_t
offset, sizeC_t count)>

Retrieves the graphemes for the RexxString C<src>, starting at
C<offset> and ending at C<offset + count>.

=cut

*/

RexxString *
CHARSET_ASCII::get_graphemes(RexxString *src, sizeC_t offset, sizeC_t count)
{
    return ENCODING_GET_BYTES(src, size_v(offset), size_v(count)); // ascii : char pos and byte pos are identical
}

/*

=item C<static RexxString * to_ascii(RexxString *src)>

Attempts to convert RexxString C<src> to ASCII in RexxString C<dest>. Throws
an exception if unconvertable UNICODE characters are involved.

=cut

*/

static RexxString *
to_ascii(RexxString *src)
{
    String_iter iter;
    sizeC_t lenC = src->getCLength();
    sizeB_t lenB = src->getBLength();

    RexxString *dest = raw_string(lenB, lenC, m17n_ascii_charset_ptr, m17n_ascii_charset_ptr->preferred_encoding);

    char *p = dest->getWritableData();
    STRING_ITER_INIT(&iter);
    while (iter.charpos < lenC) {
        const codepoint_t c = STRING_ITER_GET_AND_ADVANCE(RexxStringWrapper(src), &iter);
        if (c >= 128)
            reportException(Rexx_Error_Execution_user_defined,
                    "can't convert unicode string to ascii"); // todojlf : "unicode" is hardcoded but can be other than unicode, no ?
        *p++ = (unsigned char)c;
    }
    return dest;
}

/*

=item C<static RexxString * convert(RexxString *src)>

Converts RexxString C<src> to ASCII charset RexxString C<dest>.

=cut

*/

RexxString *
CHARSET_ASCII::convert(RexxString *src)
{
    charset_converter_t conversion_func =
        m17n_find_charset_converter(src->getCharset(), m17n_ascii_charset_ptr);

    if (conversion_func) {
         return conversion_func(src);
    }
    else {
        return to_ascii(src);
    }
}

/*

=item C<static RexxString* compose(RexxString *src)>

Can't compose ASCII strings, so performs a string copy on it and
returns the new string.

=cut

*/

RexxString*
CHARSET_ASCII::compose(RexxString *src)
{
    RexxString *dest = src->makeString();

    return dest;
}

/*

=item C<static RexxString* decompose(RexxString *src)>

Can't decompose ASCII, so we perform a string copy instead and return
a pointer to the new string.

=cut

*/

RexxString*
CHARSET_ASCII::decompose(RexxString *src)
{
    RexxString * const dest = src->makeString();

    return dest;
}

/*

=item C<static RexxString* upcase(RexxString *src)>

Converts the RexxString C<src> to all uppercase.

=cut

*/

RexxString*
CHARSET_ASCII::upcase(RexxString *src, sizeC_t start, sizeC_t length) // todo : implement start, length
{
    RexxString * const result = (RexxString *) src->clone();
    const sizeB_t n = src->getBLength();

    if (n != 0) {
        char * const buffer = result->getWritableData();
        sizeB_t offset;

        for (offset = 0; offset < n; ++offset) {
            buffer[size_v(offset)] = (char)toupper((unsigned char)buffer[size_v(offset)]);
        }
    }

    return result;
}

/*

=item C<static RexxString* downcase(RexxString *src)>

Converts the RexxString C<src> to all lower-case.

=cut

*/

RexxString*
CHARSET_ASCII::downcase(RexxString *src, sizeC_t start, sizeC_t length) // todo : implement start, length
{
    RexxString       *result = (RexxString *) src->clone();
    const sizeB_t n      = src->getBLength();

    if (n != 0) {
        char * const buffer = result->getWritableData();
        sizeB_t offset;

        for (offset = 0; offset < n; ++offset) {
            buffer[size_v(offset)] = (char)tolower((unsigned char)buffer[size_v(offset)]);
        }
    }

    return result;
}

/*

=item C<static RexxString* titlecase(RexxString *src)>

Converts the RexxString given by C<src> to title case, where
the first character is upper case and all the rest of the characters
are lower-case.

=cut

*/

RexxString*
CHARSET_ASCII::titlecase(RexxString *src)
{
    RexxString       *result = (RexxString *) src->clone();
    const sizeB_t n      = src->getBLength();

    if (n != 0) {
        char * const buffer = result->getWritableData();
        sizeB_t offset;

        buffer[0] = (char)toupper((unsigned char)buffer[0]);
        for (offset = 1; offset < n; ++offset) {
            buffer[size_v(offset)] = (char)tolower((unsigned char)buffer[size_v(offset)]);
        }
    }

    return result;
}

/*

=item C<static RexxString* upcase_first(RexxString *src)>

Sets the first character in the RexxString C<src> to upper case,
but doesn't modify the rest of the string.

=cut

*/

RexxString*
CHARSET_ASCII::upcase_first(RexxString *src)
{
    RexxString * const result = (RexxString *) src->clone();

    if (result->getBLength() > 0) {
        char * const buffer = result->getWritableData();
        buffer[0] = (char)toupper((unsigned char)buffer[0]);
    }

    return result;
}

/*

=item C<static RexxString* downcase_first(RexxString *src)>

Sets the first character of the RexxString C<src> to lowercase,
but doesn't modify the rest of the characters.

=cut

*/

RexxString*
CHARSET_ASCII::downcase_first(RexxString *src)
{
    RexxString * const result = (RexxString *) src->clone();

    if (result->getBLength() > 0) {
        char * const buffer = result->getWritableData();
        buffer[0] = (char)tolower((unsigned char)buffer[0]);
    }

    return result;
}

/*

=item C<static RexxString* titlecase_first(RexxString *src)>

Converts the first letter of RexxString C<src> to upper case,
but doesn't modify the rest of the string.

=cut

*/

RexxString*
CHARSET_ASCII::titlecase_first(RexxString *src)
{
    RexxString * const result = (RexxString *) src->clone();

    if (result->getBLength() > 0) {
        char * const buffer = result->getWritableData();
        buffer[0] = (char)toupper((unsigned char)buffer[0]);
    }

    return result;
}

/*

=item C<wholenumber_t ascii_compare(IRexxString *lhs, IRexxString
*rhs)>

Compares two strings as ASCII strings. If IRexxString C<lhs> > C<rhs>, returns
1. If C<lhs> == C<rhs> returns 0. If IRexxString C<lhs> < C<rhs>, returns  -1.

=cut

*/

wholenumber_t
CHARSET_ASCII::compare(IRexxString *lhs, IRexxString *rhs)
{
    const sizeB_t l_len = lhs->getBLength();
    const sizeB_t r_len = rhs->getBLength();
    const sizeB_t min_len = l_len > r_len ? r_len : l_len;
    String_iter iter;

    if (lhs->getEncoding() == rhs->getEncoding()) {
        const int ret_val = memcmp(lhs->getStringData(), rhs->getStringData(), min_len);
        if (ret_val)
            return ret_val < 0 ? -1 : 1;
    }
    else {
        STRING_ITER_INIT(&iter);
        while (iter.bytepos < min_len) {
            const wholenumber_t cl = ENCODING_GET_BYTE(lhs, iter.bytepos);
            const codepoint_t cr = STRING_ITER_GET_AND_ADVANCE(rhs, &iter);
            if (cl != cr)
                return cl < cr ? -1 : 1;
        }
    }
    if (l_len < r_len) {
        return -1;
    }
    if (l_len > r_len) {
        return 1;
    }
    return 0;
}

/*

=item C<sizeC_t mixed_cs_index(IRexxString *src, IRexxString
*search, sizeC_t offs)>

Searches for the first instance of IRexxString C<search> in IRexxString C<src>.
returns the position where the substring is found if it is indeed found.
Returns -1 otherwise. Operates on different types of strings, not just
ASCII.

=cut

*/

sizeC_t
mixed_cs_index(IRexxString *src, IRexxString *search,
    sizeC_t offs)
{
    String_iter start, end;

    STRING_ITER_INIT(&start);
    STRING_ITER_SET_POSITION(src, &start, offs);

    return str_iter_index(src, &start, &end, search);
}

/*

=item C<sizeC_t m17n_byte_index(IRexxString *base, IRexxString
*search, sizeB_t start_offset)>

Looks for the location of a substring within a longer string.  Takes
pointers to the strings and the offset within the string at which
to start searching as arguments.

Returns an offset value if it is found, or -1 if no match.

=cut

*/

sizeC_t
m17n_byte_index(IRexxString *base,
        IRexxString *search, sizeB_t start_offset)
{
    const char * const str_start  = base->getStringData();
    const sizeB_t       str_len    = base->getBLength();
    const char * const search_str = search->getStringData();
    const sizeB_t       search_len = search->getBLength();
    const char        *str_pos    = str_start + size_v(start_offset);
    sizeB_t             len_remain = str_len   - size_v(start_offset);
    const char        *search_pos;

    /* find the next position of the first character in the search string
     * ooRexx strings can have NULLs, so strchr() won't work here */
    while ((search_pos = (const char *)memchr(str_pos, *search_str, len_remain))) {
        const sizeB_t offset = sizeB_v(search_pos - str_start);

        /* now look for the entire string */
        if (memcmp(search_pos, search_str, search_len) == 0)
            return size_v(offset);

        /* otherwise loop and memchr() with the rest of the string */
        len_remain = str_len    - offset;
        str_pos    = search_pos + 1;

        if (len_remain < search_len)
            return -1;
    }

    return -1;
}

/*

=item C<sizeC_t ascii_cs_index(IRexxString *src, IRexxString
*search_string, sizeC_t offset)>

Searches for the first instance of IRexxString C<search> in IRexxString C<src>.
returns the position where the substring is found if it is indeed found.
Returns -1 otherwise.

=cut

*/

sizeC_t
CHARSET_ASCII::index(IRexxString *src,
        IRexxString *search_string, sizeC_t offset)
{
    sizeC_t retval;
    if (src->getCharset() != search_string->getCharset()) {
        return mixed_cs_index(src, search_string, offset);
    }

    // PARROT_ASSERT(src->encoding == m17n_fixed_8_encoding_ptr);
    retval = m17n_byte_index(src,
            search_string, size_v(offset));
    return retval;
}

/*

=item C<sizeC_t m17n_byte_rindex(IRexxString *base,
IRexxString *search, sizeB_t start_offset)>

Substring search (like m17n_byte_index), but works backwards,
from the rightmost end of the string.

Returns offset value or -1 (if no match).

=cut

*/

sizeC_t
m17n_byte_rindex(IRexxString *base,
        IRexxString *search, sizeB_t start_offset)
{
    const sizeB_t searchlen          = search->getBLength();
    const char * const search_start = search->getStringData();
    sizeB_t max_possible_offset     = (base->getBLength() - search->getBLength());
    sizeB_t current_offset;

    if (start_offset != 0 && start_offset < max_possible_offset)
        max_possible_offset = start_offset;

    for (current_offset = max_possible_offset; current_offset >= 0;
            current_offset--) {
        const char * const base_start = base->getStringData() + current_offset;
        if (memcmp(base_start, search_start, searchlen) == 0) {
            return size_v(current_offset);
        }
    }

    return -1;
}

/*

=item C<sizeC_t ascii_cs_rindex(IRexxString *src, IRexxString
*search_string, sizeC_t offset)>

Searches for the last instance of IRexxString C<search_string> in IRexxString
C<src>. Starts searching at C<offset>.

=cut

*/

sizeC_t
CHARSET_ASCII::rindex(IRexxString *src,
        IRexxString *search_string, sizeC_t offset)
{
    sizeC_t retval;

    if (src->getCharset() != search_string->getCharset())
        reportException(Rexx_Error_Execution_user_defined,
            "Cross-charset index not supported");

    // PARROT_ASSERT(src->encoding == m17n_fixed_8_encoding_ptr);
    retval = m17n_byte_rindex(src,
            search_string, size_v(offset));
    return retval;
}

/*

=item C<static wholenumber_t validate(IRexxString *src)>

Verifies that the given string is valid ASCII. Returns 1 if it is ASCII,
returns 0 otherwise.

=cut

*/

wholenumber_t
CHARSET_ASCII::validate(IRexxString *src)
{
    String_iter iter;
    const sizeC_t length = src->getCLength();

    STRING_ITER_INIT(&iter);
    while (iter.charpos < length) {
        const codepoint_t codepoint = STRING_ITER_GET_AND_ADVANCE(src, &iter);
        if (codepoint >= 0x80)
            return 0;
    }
    return 1;
}

/*

=item C<static RexxString * string_from_codepoint(sizeC_t codepoint)>

Creates a new RexxString object from a single codepoint C<codepoint>. Returns
the new RexxString.

=cut

*/

RexxString *
CHARSET_ASCII::string_from_codepoint(codepoint_t codepoint)
{
    char real_codepoint = (char)codepoint;
    RexxString * const return_string = new_string(&real_codepoint, 1, 1, m17n_ascii_charset_ptr, m17n_ascii_charset_ptr->preferred_encoding);
    return return_string;
}

/*

=item C<static wholenumber_t is_cclass(wholenumber_t flags, IRexxString *src,
sizeC_t offset)>

Returns Boolean.

=cut

*/

wholenumber_t
CHARSET_ASCII::is_cclass(wholenumber_t flags, IRexxString *src, sizeC_t offset)
{
    codepoint_t codepoint;

    if (offset >= src->getCLength())
        return 0;
    codepoint = ENCODING_GET_CODEPOINT(src, offset);

    if (codepoint >= sizeof (m17n_ascii_typetable) / sizeof (m17n_ascii_typetable[0])) {
        return 0;
    }
    return (m17n_ascii_typetable[codepoint] & flags) ? 1 : 0;
}

/*

=item C<static sizeC_t find_cclass(wholenumber_t flags, IRexxString
*src, sizeC_t offset, sizeC_t count)>

Find a character in the given character class.  Delegates to the find_cclass
method of the encoding plugin.

=cut

*/

sizeC_t
CHARSET_ASCII::find_cclass(wholenumber_t flags, IRexxString *src, sizeC_t offset, sizeC_t count)
{
    sizeC_t pos = offset;
    sizeC_t end = offset + count;

    end = src->getCLength() < end ? src->getCLength() : end;
    return ENCODING_FIND_CCLASS(src, m17n_ascii_typetable, flags, pos, end);
}

/*

=item C<static sizeC_t find_not_cclass(wholenumber_t flags, IRexxString
*src, sizeC_t offset, sizeC_t count)>

Returns C<sizeC_t>.

=cut

*/

sizeC_t
CHARSET_ASCII::find_not_cclass(wholenumber_t flags, IRexxString *src, sizeC_t offset, sizeC_t count)
{
    sizeC_t pos = offset;
    sizeC_t end = offset + count;

    end = src->getCLength() < end ? src->getCLength() : end;
    for (; pos < end; ++pos) {
        const codepoint_t codepoint = ENCODING_GET_CODEPOINT(src, pos);
        if ((m17n_ascii_typetable[codepoint] & flags) == 0) {
            return pos;
        }
    }
    return end;
}

/*

/*

=item C<void m17n_charset_ascii_init()>

Initialize the ASCII charset but registering all the necessary
function pointers and settings.

=cut

*/

void
m17n_charset_ascii_init()
{
    CHARSET_ASCII * return_set = new CHARSET_ASCII;
    return_set->name = "ascii";
    return_set->preferred_encoding = m17n_fixed_8_encoding_ptr;
    m17n_register_charset(return_set);
}

/*

=item C<RexxString * charset_cvt_ascii_to_binary(RexxString *src)>

Converts an ASCII RexxString C<src> to a binary RexxString C<dest>.

=cut

*/

RexxString *
charset_cvt_ascii_to_binary(RexxString *src)
{
    RexxString * const dest = (RexxString *) src->clone();
    sizeB_t offs;

    for (offs = 0; offs < src->getBLength(); ++offs) {
        const wholenumber_t c = ENCODING_GET_BYTE(RexxStringWrapper(src), offs);
        ENCODING_SET_BYTE(RexxStringWrapper(dest), offs, c);
    }

    dest->setCharset(m17n_binary_charset_ptr);
    return dest;
}

/*

=item C<RexxString * charset_cvt_ascii_to_iso_8859_1(RexxString
*src)>

Converts ASCII RexxString C<src> to ISO8859-1 RexxString C<dest>.

=cut

*/

RexxString *
charset_cvt_ascii_to_iso_8859_1(RexxString *src)
{
    RexxString * const dest = (RexxString *) src->clone();
    sizeB_t offs;

    for (offs = 0; offs < src->getBLength(); ++offs) {
        const wholenumber_t c = ENCODING_GET_BYTE(RexxStringWrapper(src), offs);
        ENCODING_SET_BYTE(RexxStringWrapper(dest), offs, c);
    }

    dest->setCharset(m17n_iso_8859_1_charset_ptr);
    return dest;
}
