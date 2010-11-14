/*
Copyright (C) 2001-2010, Parrot Foundation.
$Id: ucs2.c 46192 2010-04-30 08:27:15Z jimmy $

=head1 NAME

src/string/encoding/ucs2.c - UCS-2 encoding

=head1 DESCRIPTION

UCS-2 encoding with the help of the ICU library.

=head2 Functions

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

#include "m17n_unicode.h"

#if !defined(HAVE_ICU)
static void no_ICU_lib() /* HEADERIZER SKIP */
{
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
}
#endif


#include "m17n_encoding_ucs2.h"

#if defined(HAVE_ICU)
#  include <unicode/ustring.h>
#endif

#define UNIMPL reportException(Rexx_Error_Execution_user_defined, "unimpl ucs2")

/*

=item C<static RexxMutableBuffer * encode(IRexxString *src)>

Converts the string C<src> to this particular encoding.

=cut

*/

RexxMutableBuffer *
ENCODING_UCS2::encode(IRexxString *src)
{
    RexxMutableBuffer *result =
        m17n_utf16_encoding_ptr->encode(src);

    /* conversion to utf16 downgrads to ucs-2 if possible - check result */
    if (result->getEncoding() == m17n_utf16_encoding_ptr)
        reportException(Rexx_Error_Execution_user_defined, "can't convert string with surrogates to ucs2");

    return result;
}

/*

=item C<static codepoint_t get_codepoint(IRexxString *src, sizeC_t
offset)>

Returns the codepoint in string C<src> at position C<offset>.

=cut

*/

codepoint_t
ENCODING_UCS2::get_codepoint(IRexxString *src, sizeC_t offset)
{
#if defined(HAVE_ICU)
    const UChar *s = (const UChar*) src->getStringData();
    return s[offset];
#else
    no_ICU_lib();
    return -1;
#endif
}


/*

=item C<static sizeC_t find_cclass(IRexxString *s, wholenumber_t
*typetable, wholenumber_t flags, sizeC_t pos, sizeC_t end)>

Stub, the charset level handles this for unicode strings.

=cut

*/

sizeC_t
ENCODING_UCS2::find_cclass(IRexxString *s, wholenumber_t *typetable,
wholenumber_t flags, sizeC_t pos, sizeC_t end)
{
    reportException(Rexx_Error_Execution_user_defined, "No find_cclass support in unicode encoding plugins");
    return -1;
}

/*

=item C<static wholenumber_t get_byte(IRexxString *src, sizeB_t
offset)>

Returns the byte in string C<src> at position C<offset>.

=cut

*/

wholenumber_t
ENCODING_UCS2::get_byte(IRexxString *src, sizeB_t offset)
{
    UNIMPL;
    return -1;
}

/*

=item C<static void set_byte(IRexxString *src, sizeB_t offset,
wholenumber_t byte)>

Sets, in string C<src> at position C<offset>, the byte C<byte>.

=cut

*/

void
ENCODING_UCS2::set_byte(IRexxString *src, sizeB_t offset,
        wholenumber_t byte)
{
    UNIMPL;
}

/*

=item C<static RexxString * get_codepoints(RexxString *src, sizeC_t
offset, sizeC_t count)>

Returns the codepoints in string C<src> at position C<offset> and length
C<count>.

=cut

*/

RexxString *
ENCODING_UCS2::get_codepoints(RexxString *src, sizeC_t offset, sizeC_t count)
{
#if defined(HAVE_ICU)
    RexxString *return_string = raw_string(count * sizeof (UChar), count, src->getCharset(), src->getEncoding());
    return_string->put(0, src->getStringData() + offset * sizeof (UChar), count * sizeof (UChar));
#else
    String_iter iter;
    STRING_ITER_INIT(&iter);
    iter_set_position(RexxStringWrapper(src), &iter, offset);
    sizeB_t start = iter.bytepos;
    iter_set_position(RexxStringWrapper(src), &iter, offset + count);
    sizeB_t bcount = iter.bytepos - start;
    RexxString *return_string = raw_string(bcount, count, src->getCharset(), src->getEncoding());
    return_string->put(0, src->getStringData() + start, bcount);
#endif
    return return_string;
}

/*

=item C<static RexxString * get_bytes(RexxString *src, sizeB_t
offset, sizeB_t count)>

Returns the bytes in string C<src> at position C<offset> and length C<count>.

=cut

*/

RexxString *
ENCODING_UCS2::get_bytes(RexxString *src, sizeB_t offset,
        sizeB_t count)
{
    UNIMPL;
    return (RexxString *)TheNilObject;
}


/*

=item C<static sizeC_t codepoints(RexxString *src)>

Returns the number of codepoints in string C<src>.

=cut

*/

sizeC_t
ENCODING_UCS2::codepoints(IRexxString *src)
{
#if defined(HAVE_ICU)
    return src->getBLength() / sizeof (UChar);
#else
    no_ICU_lib();
    return 0;
#endif
}

sizeC_t
ENCODING_UCS2::codepoints(const char *src, sizeB_t blength)
{
#if defined(HAVE_ICU)
    return blength / sizeof (UChar);
#else
    no_ICU_lib();
    return 0;
#endif
}

/*

=item C<static sizeB_t bytes(IRexxString *src)>

Returns the number of bytes in string C<src>.

=cut

*/

sizeB_t
ENCODING_UCS2::bytes(IRexxString *src)
{
    return src->getBLength();
}

/*

=item C<static codepoint_t ucs2_iter_get(IRexxString *str, const
String_iter *i, sizeC_t offset)>

Get the character at C<i> + C<offset>.

=cut

*/

codepoint_t
ENCODING_UCS2::iter_get(IRexxString *str, String_iter *i, sizeC_t offset)
{
    return get_codepoint(str, i->charpos + offset);
}

/*

=item C<static void ucs2_iter_skip(IRexxString *str, String_iter
*i, sizeC_t skip)>

Moves the string iterator C<i> by C<skip> characters.

=cut

*/

void
ENCODING_UCS2::iter_skip(IRexxString *str, String_iter *i, sizeC_t skip)
{
#if defined(HAVE_ICU)
    i->charpos += skip;
    i->bytepos += skip * sizeof (UChar);
#else
    no_ICU_lib();
#endif
}

/*

=item C<static codepoint_t ucs2_iter_get_and_advance(IRexxString
*str, String_iter *i)>

Moves the string iterator C<i> to the next UCS-2 codepoint.

=cut

*/

codepoint_t
ENCODING_UCS2::iter_get_and_advance(IRexxString *str, String_iter *i)
{
#if defined(HAVE_ICU)
    const UChar *s = (const UChar*) str->getStringData();
    size_t pos = i->bytepos / sizeof (UChar);

    /* TODO either make sure that we don't go past end or use SAFE
     *      iter versions
     */
    const UChar c = s[pos++];
    i->charpos++;
    i->bytepos = pos * sizeof (UChar);
    return c;
#else
    no_ICU_lib();
    return -1;
#endif
}

/*

=item C<static void ucs2_iter_set_and_advance(IRexxString *str,
String_iter *i, codepoint_t c)>

With the string iterator C<i>, appends the codepoint C<c> and advances to the
next position in the string.

=cut

*/

void
ENCODING_UCS2::iter_set_and_advance(IRexxString *str, String_iter *i, codepoint_t c)
{
#if defined(HAVE_ICU)
    UChar *s = (UChar*) str->getWritableData();
    sizeB_t pos = i->bytepos / sizeof (UChar);
    s[pos++] = (UChar)c;
    i->charpos++;
    i->bytepos = pos * sizeof (UChar);
#else
    no_ICU_lib();
#endif
}

/*

=item C<static void ucs2_iter_set_position(IRexxString *str,
String_iter *i, sizeC_t n)>

Moves the string iterator C<i> to the position C<n> in the string.

=cut

*/

void
ENCODING_UCS2::iter_set_position(IRexxString *str, String_iter *i, sizeC_t n)
{
#if defined(HAVE_ICU)
    i->charpos = n;
    i->bytepos = n * sizeof (UChar);
#else
    no_ICU_lib();
#endif
}

/*

=item C<void m17n_encoding_ucs2_init()>

Initializes the UCS-2 encoding.

=cut

*/

void
m17n_encoding_ucs2_init()
{
    ENCODING_UCS2 * const return_encoding = new ENCODING_UCS2;
    return_encoding->name = "ucs-2";
    return_encoding->max_bytes_per_codepoint = 2; /* Max bytes per codepoint 0 .. 0x10ffff */
    m17n_register_encoding(return_encoding);
}
