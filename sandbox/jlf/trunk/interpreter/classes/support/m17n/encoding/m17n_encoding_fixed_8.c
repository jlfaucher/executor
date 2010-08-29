/*
Copyright (C) 2004-2010, Parrot Foundation.
$Id: fixed_8.c 46192 2010-04-30 08:27:15Z jimmy $

=head1 NAME

src/string/encoding/fixed_8.c

=head1 DESCRIPTION

This file implements the encoding functions for fixed-width 8-bit codepoints

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

#include "m17n_encoding_fixed_8.h"


#define UNIMPL reportException(Rexx_Error_Execution_user_defined, "unimpl fixed_8")

/*

=item C<static RexxMutableBuffer * encode(RexxString *src)>

Converts the string C<src> to this particular encoding.

=cut

*/

RexxMutableBuffer *
ENCODING_FIXED_8::encode(IRexxString *src)
{
    UNIMPL;
    return (RexxMutableBuffer *)TheNilObject;
}


/*

=item C<static wholenumber_t get_codepoint(IRexxString *src, wholenumber_t
offset)>

codepoints are bytes, so delegate

=cut

*/

wholenumber_t
ENCODING_FIXED_8::get_codepoint(IRexxString *src, wholenumber_t offset)
{
    return get_byte(src, offset);
}


/*

=item C<static wholenumber_t find_cclass(IRexxString *s, const wholenumber_t
*typetable, wholenumber_t flags, wholenumber_t pos, wholenumber_t end)>

codepoints are bytes, so delegate

=cut

*/

wholenumber_t
ENCODING_FIXED_8::find_cclass(IRexxString *s, wholenumber_t *typetable, wholenumber_t flags, wholenumber_t pos, wholenumber_t end)
{
    const unsigned char *contents = (const unsigned char *)s->getStringData();
    for (; pos < end; ++pos) {
        if ((typetable[contents[pos]] & flags) != 0) {
            return pos;
        }
    }
    return end;
}

/*

=item C<static wholenumber_t get_byte(IRexxString *src, wholenumber_t
offset)>

Returns the byte in string C<src> at position C<offset>.

=cut

*/

wholenumber_t
ENCODING_FIXED_8::get_byte(IRexxString *src, wholenumber_t offset)
{
    const unsigned char *contents = (const unsigned char *)src->getStringData();

    if (offset >= (wholenumber_t) src->getBLength()) {
/*        m17n_ex_throw_from_c_args(NULL, 0,
                "get_byte past the end of the buffer (%i of %i)",
                offset, src->bufused); */
        return 0;
    }

    return contents[offset];
}

/*

=item C<static void set_byte(IRexxString *src, wholenumber_t offset,
wholenumber_t byte)>

Sets, in string C<src> at position C<offset>, the byte C<byte>.

=cut

*/

void
ENCODING_FIXED_8::set_byte(IRexxString *src, wholenumber_t offset, wholenumber_t byte)
{
    unsigned char *contents;

    if (offset >= (wholenumber_t) src->getBLength())
        reportException(Rexx_Error_Execution_user_defined, "set_byte past the end of the buffer");

    contents = (unsigned char *)src->getStringData();
    contents[offset] = (unsigned char)byte;
}

/*

=item C<static RexxString * get_codepoints(RexxString *src, wholenumber_t
offset, wholenumber_t count)>

Returns the codepoints in string C<src> at position C<offset> and length
C<count>.  (Delegates to C<get_bytes>.)

=cut

*/

RexxString *
ENCODING_FIXED_8::get_codepoints(RexxString *src, wholenumber_t offset, wholenumber_t count)
{
    RexxString * return_string = get_bytes(src, offset, count);
    return_string->setCharset(src->getCharset());
    return return_string;
}

/*

=item C<static RexxString * get_bytes(RexxString *src, wholenumber_t
offset, wholenumber_t count)>

Returns the bytes in string C<src> at position C<offset> and length C<count>.

=cut

*/

RexxString *
ENCODING_FIXED_8::get_bytes(RexxString *src, wholenumber_t offset, wholenumber_t count)
{
    RexxString *return_string = raw_string(count, count, src->getCharset(), src->getEncoding());
    return_string->put(0, src->getStringData() + offset, count);
    return return_string;
}


/*

=item C<static wholenumber_t codepoints(IRexxString *src)>

Returns the number of codepoints in string C<src>.

=cut

*/

wholenumber_t
ENCODING_FIXED_8::codepoints(IRexxString *src)
{
    return bytes(src);
}

wholenumber_t
ENCODING_FIXED_8::codepoints(const char *src, wholenumber_t blength)
{
    return blength;
}

/*

=item C<static wholenumber_t bytes(IRexxString *src)>

Returns the number of bytes in string C<src>.

=cut

*/

wholenumber_t
ENCODING_FIXED_8::bytes(IRexxString *src)
{
    return src->getBLength();
}

/*
 * iterator functions
 */

/*

=item C<static wholenumber_t fixed8_iter_get(IRexxString *str, const
String_iter *iter, wholenumber_t offset)>

Get the character at C<iter> plus C<offset>.

=cut

*/

wholenumber_t
ENCODING_FIXED_8::iter_get(IRexxString *str, String_iter *iter, wholenumber_t offset)
{
    return get_byte(str, iter->charpos + offset);
}

/*

=item C<static void fixed8_iter_skip(IRexxString *str,
String_iter *iter, wholenumber_t skip)>

Moves the string iterator C<i> by C<skip> characters.

=cut

*/

void
ENCODING_FIXED_8::iter_skip(IRexxString *str, String_iter *iter, wholenumber_t skip)
{
    iter->bytepos += skip;
    iter->charpos += skip;
    // PARROT_ASSERT(iter->bytepos <= Buffer_buflen(str));
}

/*

=item C<static wholenumber_t fixed8_iter_get_and_advance(IRexxString
*str, String_iter *iter)>

Moves the string iterator C<i> to the next codepoint.

=cut

*/

wholenumber_t
ENCODING_FIXED_8::iter_get_and_advance(IRexxString *str, String_iter *iter)
{
    const wholenumber_t c = get_byte(str, iter->charpos++);
    iter->bytepos++;
    return c;
}

/*

=item C<static void fixed8_iter_set_and_advance(IRexxString *str,
String_iter *iter, wholenumber_t c)>

With the string iterator C<i>, appends the codepoint C<c> and advances to the
next position in the string.

=cut

*/

void
ENCODING_FIXED_8::iter_set_and_advance(IRexxString *str, String_iter *iter, wholenumber_t c)
{
    set_byte(str, iter->charpos++, c);
    iter->bytepos++;
}

/*

=item C<static void fixed8_iter_set_position(IRexxString *str,
String_iter *iter, wholenumber_t pos)>

Moves the string iterator C<i> to the position C<n> in the string.

=cut

*/

void
ENCODING_FIXED_8::iter_set_position(IRexxString *str, String_iter *iter, wholenumber_t pos)
{
    iter->bytepos = iter->charpos = pos;
    // PARROT_ASSERT(pos <= Buffer_buflen(str));
}

/*

=item C<void m17n_encoding_fixed_8_init()>

Initializes the fixed-8 encoding.

=cut

*/

void
m17n_encoding_fixed_8_init()
{
    ENCODING_FIXED_8 * const return_encoding = new ENCODING_FIXED_8;
    return_encoding->name = "fixed-8";
    return_encoding->max_bytes_per_codepoint = 1;
    m17n_register_encoding(return_encoding);
}
