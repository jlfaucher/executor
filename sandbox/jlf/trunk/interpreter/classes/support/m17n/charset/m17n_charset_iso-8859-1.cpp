/*
Copyright (C) 2004-2010, Parrot Foundation.
$Id: iso-8859-1.c 47917 2010-06-29 23:18:38Z jkeenan $

=head1 NAME

src/string/charset/iso-8859-1.c

=head1 DESCRIPTION

This file implements the charset functions for iso-8859-1 data

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
#include "MutableBufferClass.hpp"
#include "ProtectedObject.hpp"

#include "m17n_string.h"
#include "m17n_encoding.h"
#include "m17n_charset_iso-8859-1.h"

#include "m17n_charset_tables.h"

/*

=item C<static RexxString * to_iso_8859_1(RexxString *src)>

Converts RexxString C<src> to iso-8859-1 in RexxString C<dest>.

=cut

*/

static RexxString *
to_iso_8859_1(RexxString *src)
{
    sizeC_t src_len;
    String_iter iter;
    /* iso-8859-1 is never bigger then source */
    RexxString * dest = (RexxString *) src->clone();

    STRING_ITER_INIT(&iter);
    src_len = src->getCLength();
    while (iter.charpos < src_len) {
        const codepoint_t c = STRING_ITER_GET_AND_ADVANCE(RexxStringWrapper(src), &iter);
        if (c >= 0x100)
            reportException(Rexx_Error_Execution_user_defined,
                "lossy conversion to iso-8559-1");

        m17n_fixed_8_encoding_ptr->set_byte(RexxStringWrapper(dest), iter.bytepos - 1, c);
    }
    dest->setCharset(m17n_iso_8859_1_charset_ptr);
    dest->setEncoding(m17n_fixed_8_encoding_ptr);
    return dest;
}

/*

=item C<static RexxString * convert(RexxString *src)>

Converts the RexxString C<src> to an ISO-8859-1 RexxString C<dest>.

=cut

*/

RexxString *
CHARSET_ISO_8859::convert(RexxString *src)
{
    charset_converter_t conversion_func =
        m17n_find_charset_converter(src->getCharset(), m17n_iso_8859_1_charset_ptr);

    if (conversion_func)
        return conversion_func(src);
    else
        return to_iso_8859_1(src);
}


/*

=item C<static RexxString* compose(RexxString *src)>

ISO-8859-1 does not support composing, so we just copy the RexxString C<src> and return the
copy.

=cut

*/

RexxString*
CHARSET_ISO_8859::compose(RexxString *src)
{
    RexxString *dest = src->makeString();

    return dest;
}

/*

=item C<static RexxString* decompose(RexxString *src)>

SO-8859-1 does not support decomposing, so we throw an exception.

=cut

*/

RexxString*
CHARSET_ISO_8859::decompose(RexxString *src)
{
    reportException(Rexx_Error_Execution_user_defined,
            "decompose for iso-8859-1 not implemented");
    return (RexxString *)TheNilObject;
}

/*

=item C<static RexxString* upcase(RexxString *src)>

Convert all graphemes in the RexxString C<src> to upper case, for those
graphemes that support cases.

=cut

*/

RexxString*
CHARSET_ISO_8859::upcase(RexxString *src, ssizeC_t start, ssizeC_t length)
{
    unsigned char *buffer;
    sizeB_t        offset = 0;
    RexxString        *result = (RexxString *) src->clone();

    if (result->getBLength() == 0)
        return result;

    buffer = (unsigned char *)result->getWritableData();
    for (offset = 0; offset < result->getBLength(); ++offset) {
        unsigned int c = buffer[size_v(offset)]; /* XXX use encoding ? */
        if (c >= 0xe0 && c != 0xf7)
            c &= ~0x20;
        else
            c = toupper((unsigned char)c);
        buffer[size_v(offset)] = (unsigned char)c;
    }

    return result;
}

/*

=item C<static RexxString* downcase(RexxString *src)>

Converts all graphemes in RexxString C<src> to lower-case, for those graphemes
that support cases.

=cut

*/

RexxString*
CHARSET_ISO_8859::downcase(RexxString *src, ssizeC_t start, ssizeC_t length)
{
    unsigned char *buffer;
    sizeB_t        offset = 0;
    RexxString        *result = (RexxString *) src->clone();

    if (result->getBLength() == 0)
        return result;

    buffer = (unsigned char *)result->getWritableData();
    for (offset = 0; offset < result->getBLength(); ++offset) {
        unsigned int c = buffer[size_v(offset)];
        if (c >= 0xc0 && c != 0xd7 && c <= 0xde)
            c |= 0x20;
        else
            c = tolower((unsigned char)c);
        buffer[size_v(offset)] = (unsigned char)c;
    }

    return result;
}

/*

=item C<static RexxString* titlecase(RexxString *src)>

Converts the graphemes in RexxString C<src> to title case, for those graphemes
that support cases.

=cut

*/

RexxString*
CHARSET_ISO_8859::titlecase(RexxString *src)
{
    unsigned char *buffer;
    unsigned int   c;
    sizeB_t        offset;
    RexxString        *result = (RexxString *)src->clone();

    if (result->getBLength() == 0)
        return result;

    buffer = (unsigned char *)result->getWritableData();
    c = buffer[0];
    if (c >= 0xe0 && c != 0xf7)
        c &= ~0x20;
    else
        c = toupper((unsigned char)c);
    buffer[0] = (unsigned char)c;

    for (offset = 1; offset < result->getBLength(); ++offset) {
        c = buffer[size_v(offset)];
        if (c >= 0xc0 && c != 0xd7 && c <= 0xde)
            c |= 0x20;
        else
            c = tolower((unsigned char)c);
        buffer[size_v(offset)] = (unsigned char)c;
    }

    return result;
}

/*

=item C<static RexxString* upcase_first(RexxString *src)>

Converts the first grapheme in RexxString C<src> to upper case, if it
supports cases.

=cut

*/

RexxString*
CHARSET_ISO_8859::upcase_first(RexxString *src)
{
    unsigned char *buffer;
    unsigned int   c;
    RexxString        *result = (RexxString *) src->clone();

    if (result->getBLength() == 0)
        return result;

    buffer = (unsigned char *)result->getWritableData();
    c = buffer[0];
    if (c >= 0xe0 && c != 0xf7)
        c &= ~0x20;
    else
        c = toupper((unsigned char)c);
    buffer[0] = (unsigned char)c;

    return result;
}

/*

=item C<static RexxString* downcase_first(RexxString *src)>

Converts the first character of the RexxString C<src> to lower case, if the
grapheme supports lower case.

=cut

*/

RexxString*
CHARSET_ISO_8859::downcase_first(RexxString *src)
{
    unsigned char *buffer;
    unsigned int   c;
    RexxString        *result = (RexxString *) src->clone();

    if (result->getBLength() == 0)
        return result;

    buffer = (unsigned char *)result->getWritableData();
    c = buffer[0];
    if (c >= 0xc0 && c != 0xd7 && c <= 0xde)
        c &= ~0x20;
    else
        c = tolower((unsigned char)c);
    buffer[0] = (unsigned char)c;

    return result;
}

/*

=item C<static RexxString* titlecase_first(RexxString *src)>

Converts the first grapheme in RexxString C<src> to title case, if the grapheme
supports case.

=cut

*/

RexxString*
CHARSET_ISO_8859::titlecase_first(RexxString *src)
{
    return upcase_first(src);
}


/*

=item C<static wholenumber_t validate(IRexxString *src)>

Returns 1 if the IRexxString C<src> is a valid ISO-8859-1 IRexxString. Returns 0 otherwise.

=cut

*/

wholenumber_t
CHARSET_ISO_8859::validate(IRexxString *src)
{
    sizeC_t offset;
    const sizeC_t length =  src->getCLength(); // iterate over the characters

    for (offset = 0; offset < length; ++offset) {
        const codepoint_t codepoint = ENCODING_GET_CODEPOINT(src, offset); // todo : this is NOT optimized ! well, it's ok if the encoding is fixed_8 (should be...) but it's catastrophic if utf-8 !
        if (codepoint >= 0x100)
            return 0;
    }
    return 1;
}

/*

=item C<static wholenumber_t is_cclass(wholenumber_t flags, IRexxString *src,
sizeC_t offset)>

Returns Boolean.

=cut

*/

wholenumber_t
CHARSET_ISO_8859::is_cclass(wholenumber_t flags, IRexxString *src, sizeC_t offset)
{
    codepoint_t codepoint;

    if (offset >= src->getCLength()) return 0;
    codepoint = ENCODING_GET_CODEPOINT(src, offset);

    if ((size_t)codepoint >= sizeof (m17n_iso_8859_1_typetable) /
                     sizeof (m17n_iso_8859_1_typetable[0])) {
        return 0;
    }
    return (m17n_iso_8859_1_typetable[codepoint] & flags) ? 1 : 0;
}

/*

=item C<static sizeC_t find_cclass(wholenumber_t flags, IRexxString
*src, sizeC_t offset, sizeC_t count)>

Find a character in the given character class.  Delegates to the find_cclass
method of the encoding plugin.

=cut

*/

sizeC_t
CHARSET_ISO_8859::find_cclass(wholenumber_t flags,
                IRexxString *src, sizeC_t offset, sizeC_t count)
{
    const sizeC_t pos = offset;
    sizeC_t end = offset + count;

    end = src->getCLength() < end ? src->getCLength() : end;
    return ENCODING_FIND_CCLASS(src,
            m17n_iso_8859_1_typetable, flags, pos, end);
}

/*

=item C<static wholenumber_t find_not_cclass(wholenumber_t flags, IRexxString
*src, sizeC_t offset, sizeC_t count)>

Returns C<wholenumber_t>.

=cut

*/

sizeC_t
CHARSET_ISO_8859::find_not_cclass(wholenumber_t flags,
                IRexxString *src, sizeC_t offset, sizeC_t count)
{
    sizeC_t pos = offset;
    sizeC_t end = offset + count;

    end = src->getCLength() < end ? src->getCLength() : end;
    for (; pos < end; ++pos) {
        const codepoint_t codepoint = ENCODING_GET_CODEPOINT(src, pos);
        if ((m17n_iso_8859_1_typetable[codepoint] & flags) == 0) {
            return pos;
        }
    }
    return end;
}


/*

=item C<static RexxString * string_from_codepoint(codepoint_t codepoint)>

Creates a new RexxString from the single codepoint C<codepoint>.

=cut

*/

RexxString *
CHARSET_ISO_8859::string_from_codepoint(codepoint_t codepoint)
{
    char real_codepoint = (char)codepoint;
    RexxString * return_string = new_string(&real_codepoint, 1, 1, m17n_iso_8859_1_charset_ptr, m17n_iso_8859_1_charset_ptr->preferred_encoding);
    return return_string;
}

/*

=item C<void m17n_charset_iso_8859_1_init()>

Initializes the ISO-8859-1 charset by installing all the necessary function pointers.

=cut

*/

void
m17n_charset_iso_8859_1_init()
{
    CHARSET_ISO_8859 * const return_set = new CHARSET_ISO_8859;
    return_set->name = "iso-8859-1";
    return_set->preferred_encoding = m17n_fixed_8_encoding_ptr;
    m17n_register_charset(return_set);
}

/*

=item C<RexxString * charset_cvt_iso_8859_1_to_ascii(RexxString
*src)>

Converts RexxString C<src> in ISO-8859-1 to ASCII RexxString C<dest>.

=cut

*/

RexxString *
charset_cvt_iso_8859_1_to_ascii(RexxString *src)
{
    sizeB_t offs;
    RexxString *dest = (RexxString *) src->clone();

    for (offs = 0; offs < src->getBLength(); ++offs) { // iterate over bytes
        codepoint_t c = ENCODING_GET_BYTE(RexxStringWrapper(src), offs);
        if (c >= 0x80)
            reportException(Rexx_Error_Execution_user_defined, "lossy conversion to ascii");

        ENCODING_SET_BYTE(RexxStringWrapper(dest), offs, c);
    }
    return dest;
}
