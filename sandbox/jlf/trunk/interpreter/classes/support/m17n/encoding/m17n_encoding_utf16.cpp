/*
Copyright (C) 2001-2010, Parrot Foundation.
$Id: utf16.c 46192 2010-04-30 08:27:15Z jimmy $

=head1 NAME

src/string/encoding/utf16.c - UTF-16 encoding

=head1 DESCRIPTION

UTF-16 encoding with the help of the ICU library.

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
#include "ProtectedObject.hpp"

#include "m17n_unicode.h"
#include "m17n_encoding_utf16.h"

#if defined(HAVE_ICU)
#  include <unicode/utf16.h>
#  include <unicode/ustring.h>
#endif

#define UNIMPL reportException(Rexx_Error_Execution_user_defined, "unimpl utf16")


/*

=item C<static RexxMutableBuffer * encode(IRexxString *src)>

Converts the string C<src> to this particular encoding.

=cut

*/

RexxMutableBuffer *
ENCODING_UTF16::encode(IRexxString *src)
{
    if (src->getEncoding() == m17n_utf16_encoding_ptr || src->getEncoding() == m17n_ucs2_encoding_ptr)
    {
        return src->makeMutableBuffer();
    }

    sizeC_t src_clen = src->getCLength();
    if (src_clen == 0)
    {
        return new RexxMutableBuffer(0, 0, m17n_unicode_charset_ptr, m17n_ucs2_encoding_ptr); // downgrade ?
    }

#if defined(HAVE_ICU)
    UErrorCode err;
    int32_t dest_clen;
    sizeB_t dest_blen = sizeof (UChar) * src_clen;

    RexxMutableBuffer *result= new RexxMutableBuffer(dest_blen, src_clen, m17n_unicode_charset_ptr, m17n_utf16_encoding_ptr);
    ProtectedObject pr(result);
    UChar *p = (UChar *)result->getData();

    if (src->getCharset() == m17n_iso_8859_1_charset_ptr || src->getCharset() == m17n_ascii_charset_ptr) 
    {
        for (dest_clen = 0; dest_clen < src_clen; ++dest_clen) {
            p[dest_clen] = (UChar) src->getStringData()[dest_clen];
        }
    }
    else {
        err = U_ZERO_ERROR;
        // Todojlf : from UTF8 ? are we sure that src is UTF8 ?
        u_strFromUTF8(p, src_clen, &dest_clen, src->getStringData(), src->getBLength(), &err);
        if (!U_SUCCESS(err)) 
        {
            /*
             * have to resize - required len in UChars is in dest_len
             */
            dest_blen = sizeof (UChar) * dest_clen;
            result->ensureCapacity(dest_blen - result->getBLength());
            p = (UChar *)result->getData();
            u_strFromUTF8(p, dest_clen, &dest_clen, src->getStringData(), src->getBLength(), &err);
            //PARROT_ASSERT(U_SUCCESS(err));
        }
    }
    result->setBLength(dest_blen);
    result->setCLength(dest_clen); // todojlf : watch that ! in original source, was src_clen, but I think that was wrong

    /* downgrade if possible */
    if (dest_clen == src_clen)
    {
        result->setEncoding(m17n_ucs2_encoding_ptr);
    }
    return result;
#else
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
    return (RexxMutableBuffer *)TheNilObject;
#endif
}

/*

=item C<static codepoint_t get_codepoint(RexxString *src, sizeC_t
offset)>

Returns the codepoint in string C<src> at position C<offset>.

=cut

*/

codepoint_t
ENCODING_UTF16::get_codepoint(IRexxString *src, sizeC_t offset)
{
#if defined(HAVE_ICU)
    const UChar *s = (UChar*) src->getStringData();
    codepoint_t c;
	sizeB_t pos;

    pos = 0;
    U16_FWD_N_UNSAFE(s, pos, offset);
    U16_GET_UNSAFE(s, pos, c);
    return c;
#else
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
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
ENCODING_UTF16::find_cclass(IRexxString *s, wholenumber_t *typetable,
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
ENCODING_UTF16::get_byte(IRexxString *src, sizeB_t offset)
{
    const char *contents = src->getStringData();
    if (offset >= src->getBLength()) 
    {
        return 0;
    }
    return contents[size_v(offset)];
}

/*

=item C<static void set_byte(IRexxString *src, sizeB_t offset,
wholenumber_t byte)>

Sets, in string C<src> at position C<offset>, the byte C<byte>.

=cut

*/

void
ENCODING_UTF16::set_byte(IRexxString *src, sizeB_t offset, wholenumber_t byte)
{
    char *contents;

    if (offset >= src->getBLength())
    {
        reportException(Rexx_Error_Execution_user_defined, "set_byte past the end of the buffer");
    }

    contents = src->getWritableData();
    contents[size_v(offset)] = (char)byte;
}

/*

=item C<static RexxString * get_codepoints(RexxString *src, sizeC_t
offset, sizeC_t count)>

Returns the codepoints in string C<src> at position C<offset> and length
C<count>.

=cut

*/

RexxString *
ENCODING_UTF16::get_codepoints(RexxString *src, sizeC_t offset, sizeC_t count)
{
#if defined(HAVE_ICU)
    sizeC_t pos = 0, start;
    const UChar *s = (UChar*) src->getStringData();

    U16_FWD_N_UNSAFE(s, pos, offset);
    start = pos * sizeof (UChar);
    U16_FWD_N_UNSAFE(s, pos, count);

    return new_string(src->getStringData() + start,
                      pos * sizeof (UChar) - start,
                      count,
                      src->getCharset(), src->getEncoding());
#else
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
    return (RexxString *)TheNilObject;
#endif
}


/*

=item C<static RexxString * get_bytes(RexxString *src, sizeB_t
offset, sizeB_t count)>

Returns the bytes in string C<src> at position C<offset> and length C<count>.

=cut

*/

RexxString *
ENCODING_UTF16::get_bytes(RexxString *src, sizeB_t offset, sizeB_t count)
{
    UNIMPL;
    return (RexxString *)TheNilObject;
}

/*

=item C<static sizeC_t codepoints(IRexxString *src)>

Returns the number of codepoints in string C<src>.

=cut

*/

sizeC_t
ENCODING_UTF16::codepoints(IRexxString *src)
{
    return codepoints(src->getStringData(), src->getBLength());
}

sizeC_t
ENCODING_UTF16::codepoints(const char *src, sizeB_t blength)
{
#if defined(HAVE_ICU)
    const UChar * const s = (UChar*) src;
    sizeC_t pos = 0, charpos = 0;
    while ((size_v) (pos * sizeof (UChar)) < blength) {
        U16_FWD_1_UNSAFE(s, pos);
        ++charpos;
    }
    return charpos;
#else
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
    return 0;
#endif
}

/*

=item C<static sizeB_t bytes(IRexxString *src)>

Returns the number of bytes in string C<src>.

=cut

*/

sizeB_t
ENCODING_UTF16::bytes(IRexxString *src)
{
    return src->getBLength();
}

/*

=item C<static codepoint_t utf16_iter_get(IRexxString *str, const
String_iter *i, sizeC_t offset)>

Get the character at C<i> plus C<offset>.

=cut

*/

codepoint_t
ENCODING_UTF16::iter_get(IRexxString *str, String_iter *i, sizeC_t offset)
{
#if defined(HAVE_ICU)
    const UChar *s = (UChar*) str->getStringData();
    sizeC_t c, pos;

    pos = i->bytepos / sizeof (UChar);
    if (offset > 0) {
        U16_FWD_N_UNSAFE(s, pos, offset);
    }
    else if (offset < 0) {
        U16_BACK_N_UNSAFE(s, pos, -offset);
    }
    U16_GET_UNSAFE(s, pos, c);

    return c;
#else
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
    return -1;
#endif
}

/*

=item C<static void utf16_iter_skip(IRexxString *str,
String_iter *i, sizeC_t skip)>

Moves the string iterator C<i> by C<skip> characters.

=cut

*/

void
ENCODING_UTF16::iter_skip(IRexxString *str, String_iter *i, sizeC_t skip)
{
#if defined(HAVE_ICU)
    const UChar *s = (const UChar*) str->getStringData();
    sizeC_t pos = i->bytepos / sizeof (UChar);

    if (skip > 0) {
        U16_FWD_N_UNSAFE(s, pos, skip);
    }
    else if (skip < 0) {
        U16_BACK_N_UNSAFE(s, pos, -skip);
    }

    i->charpos += skip;
    i->bytepos = pos * sizeof (UChar);
#else
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
#endif
}

/*

=item C<static codepoint_t utf16_iter_get_and_advance(IRexxString
*str, String_iter *i)>

Moves the string iterator C<i> to the next UTF-16 codepoint.

=cut

*/

codepoint_t
ENCODING_UTF16::iter_get_and_advance(IRexxString *str, String_iter *i)
{
#if defined(HAVE_ICU)
    const UChar *s = (const UChar*) str->getStringData();
    sizeC_t c, pos;
    pos = i->bytepos / sizeof (UChar);
    /* TODO either make sure that we don't go past end or use SAFE
     *      iter versions
     */
    U16_NEXT_UNSAFE(s, pos, c);
    i->charpos++;
    i->bytepos = pos * sizeof (UChar);
    return c;
#else
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
    return -1;
#endif
}

/*

=item C<static void utf16_iter_set_and_advance(IRexxString *str,
String_iter *i, codepoint_t c)>

With the string iterator C<i>, appends the codepoint C<c> and advances to the
next position in the string.

=cut

*/

void
ENCODING_UTF16::iter_set_and_advance(IRexxString *str, String_iter *i, codepoint_t c)
{
#if defined(HAVE_ICU)
    UChar *s = (UChar*) str->getWritableData();
    sizeC_t pos;
    pos = i->bytepos / sizeof (UChar);
    U16_APPEND_UNSAFE(s, pos, c);
    i->charpos++;
    i->bytepos = pos * sizeof (UChar);
#else
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
#endif
}

/*

=item C<static void utf16_iter_set_position(IRexxString *str,
String_iter *i, sizeC_t n)>

Moves the string iterator C<i> to the position C<n> in the string.

=cut

*/

void
ENCODING_UTF16::iter_set_position(IRexxString *str, String_iter *i, sizeC_t n)
{
#if defined(HAVE_ICU)
    const UChar *s = (const UChar*) str->getStringData();
    sizeC_t pos;
    pos = 0;
    U16_FWD_N_UNSAFE(s, pos, n);
    i->charpos = n;
    i->bytepos = pos * sizeof (UChar);
#else
    reportException(Rexx_Error_Execution_user_defined, "no ICU lib loaded");
#endif
}

/*

=item C<void Parrot_encoding_utf16_init()>

Initializes the UTF-16 encoding.

=cut

*/

void
m17n_encoding_utf16_init()
{
    ENCODING_UTF16 * const return_encoding = new ENCODING_UTF16;
    return_encoding->name = "utf-16";
    return_encoding->max_bytes_per_codepoint = 4; /* Max bytes per codepoint 0 .. 0x10ffff */
}
