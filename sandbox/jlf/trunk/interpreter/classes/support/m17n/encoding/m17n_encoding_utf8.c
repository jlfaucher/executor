/*
Copyright (C) 2001-2010, Parrot Foundation.
$Id: utf8.c 46193 2010-04-30 08:53:15Z jimmy $

=head1 NAME

src/string/encoding/utf8.c - UTF-8 encoding

=head1 DESCRIPTION

UTF-8 (L<http://www.utf-8.com/>).

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
#include "m17n_encoding_utf8.h"


#define UNIMPL reportException(Rexx_Error_Execution_user_defined, "unimpl utf8")

const char m17n_utf8skip[256] = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* ascii */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* ascii */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* ascii */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* ascii */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* ascii */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* ascii */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* ascii */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* ascii */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* bogus */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* bogus */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* bogus */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     /* bogus */
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,     /* scripts */
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,     /* scripts */
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,     /* cjk etc. */
    4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6      /* cjk etc. */
};

/*

=item C<static wholenumber_t utf8_characters(const utf8_t *ptr, wholenumber_t
byte_len)>

Returns the number of characters in the C<byte_len> bytes from C<*ptr>.

XXX This function is unused.

=cut

*/

static wholenumber_t
utf8_characters(const utf8_t *ptr, wholenumber_t byte_len)
{
    const utf8_t *u8ptr = ptr;
    const utf8_t *u8end = u8ptr + byte_len;
    wholenumber_t characters = 0;

    while (u8ptr < u8end) {
        u8ptr += UTF8SKIP(u8ptr);
        ++characters;
    }

    if (u8ptr > u8end)
        reportException(Rexx_Error_Execution_user_defined, "Unaligned end in UTF-8 string\n");

    return characters;
}

/*

=item C<static wholenumber_t utf8_decode(const utf8_t *ptr)>

Returns the integer for the UTF-8 character found at C<*ptr>.

=cut

*/

static wholenumber_t
utf8_decode(const utf8_t *ptr)
{
    const utf8_t *u8ptr = ptr;
    wholenumber_t c = *u8ptr;

    if (UTF8_IS_START(c)) {
        wholenumber_t len = UTF8SKIP(u8ptr);
        wholenumber_t count;

        c &= UTF8_START_MASK(len);
        for (count = 1; count < len; ++count) {
            ++u8ptr;

            if (!UTF8_IS_CONTINUATION(*u8ptr))
                reportException(Rexx_Error_Execution_user_defined, "Malformed UTF-8 string\n");

            c = UTF8_ACCUMULATE(c, *u8ptr);
        }

        if (UNICODE_IS_SURROGATE(c))
            reportException(Rexx_Error_Execution_user_defined, "Surrogate in UTF-8 string\n");
    }
    else if (!UNICODE_IS_INVARIANT(c)) {
        reportException(Rexx_Error_Execution_user_defined, "Malformed UTF-8 string\n");
    }

    return c;
}

/*

=item C<static size_t utf8_encode(void *ptr, wholenumber_t c)>

Stores the UTF-8 encoding of integer C<c> from ptr and returns the number of bytes (can be 0 if exception).

=cut

*/

static size_t
utf8_encode(void *ptr, wholenumber_t c)
{
    wholenumber_t        len   = UNISKIP(c);

    utf8_t *u8ptr = (utf8_t *)ptr;
    utf8_t *u8end = (utf8_t *)ptr + len - 1;

    if (c > 0x10FFFF || UNICODE_IS_SURROGATE(c)) {
        reportException(Rexx_Error_Execution_user_defined, "Invalid character for UTF-8 encoding\n");
        return 0;
    }

    while (u8end > u8ptr) {
        *u8end-- = (utf8_t)((c & UTF8_CONTINUATION_MASK) | UTF8_CONTINUATION_MARK);
        c >>= UTF8_ACCUMULATION_SHIFT;
    }
    *u8end = (utf8_t)((c & UTF8_START_MASK(len)) | UTF8_START_MARK(len));

    return len;
}

/*

=item C<static const void * utf8_skip_forward(const void *ptr, wholenumber_t n)>

Moves C<ptr> C<n> characters forward.

=cut

*/

static const void *
utf8_skip_forward(const void *ptr, wholenumber_t n)
{
    const utf8_t *u8ptr = (const utf8_t *)ptr;

    while (n-- > 0) {
        u8ptr += UTF8SKIP(u8ptr);
    }

    return u8ptr;
}

/*

=item C<static const void * utf8_skip_backward(const void *ptr, wholenumber_t n)>

Moves C<ptr> C<n> characters back.

XXX This function is unused.

=cut

*/

static const void *
utf8_skip_backward(const void *ptr, wholenumber_t n)
{
    const utf8_t *u8ptr = (const utf8_t *)ptr;

    while (n-- > 0) {
        --u8ptr;
        while (UTF8_IS_CONTINUATION(*u8ptr))
            --u8ptr;
    }

    return u8ptr;
}

/*

=back

=head2 Iterator Functions

=over 4

=cut

*/

/*

=item C<static wholenumber_t utf8_iter_get(IRexxString *str, const
String_iter *i, wholenumber_t offset)>

Get the character at C<i> plus C<offset>.

=cut

*/

wholenumber_t
ENCODING_UTF8::iter_get(IRexxString *str, String_iter *i, wholenumber_t offset)
{
    const utf8_t *u8ptr = (utf8_t *)(str->getStringData() + i->bytepos);

    if (offset > 0) {
        u8ptr = (const utf8_t *)utf8_skip_forward(u8ptr, offset);
    }
    else if (offset < 0) {
        u8ptr = (const utf8_t *)utf8_skip_backward(u8ptr, -offset);
    }

    return utf8_decode(u8ptr);
}

/*

=item C<static void utf8_iter_skip(IRexxString *str, String_iter
*i, wholenumber_t skip)>

Moves the string iterator C<i> by C<skip> characters.

=cut

*/

void
ENCODING_UTF8::iter_skip(IRexxString *str, String_iter *i, wholenumber_t skip)
{
    const utf8_t *u8ptr = (utf8_t *)(str->getStringData() + i->bytepos);

    if (skip > 0) {
        u8ptr = (const utf8_t *)utf8_skip_forward(u8ptr, skip);
    }
    else if (skip < 0) {
        u8ptr = (const utf8_t *)utf8_skip_backward(u8ptr, -skip);
    }

    i->charpos += skip;
    i->bytepos = (const char *)u8ptr - str->getStringData();
}

/*

=item C<static wholenumber_t utf8_iter_get_and_advance(IRexxString
*str, String_iter *i)>

The UTF-8 implementation of the string iterator's C<get_and_advance>
function.

=cut

*/

static
wholenumber_t
utf8_iter_get_and_advance(const char *str, wholenumber_t blength, String_iter *i)
{
    const utf8_t *u8ptr = (utf8_t *)(str + i->bytepos);
    wholenumber_t c = *u8ptr;

    if (UTF8_IS_START(c)) {
        wholenumber_t len = UTF8SKIP(u8ptr);

        c &= UTF8_START_MASK(len);
        i->bytepos += len;
        if (i-> bytepos > blength)
        {
            reportException(Rexx_Error_Execution_user_defined, "Truncated UTF-8 string\n");
            return -1;
        }

        for (len--; len; len--) {
            u8ptr++;

            if (!UTF8_IS_CONTINUATION(*u8ptr))
            {
                reportException(Rexx_Error_Execution_user_defined, "Malformed UTF-8 string\n");
                return -1;
            }
            c = UTF8_ACCUMULATE(c, *u8ptr);
        }

        if (UNICODE_IS_SURROGATE(c))
        {
            reportException(Rexx_Error_Execution_user_defined, "Surrogate in UTF-8 string\n");
            return -1;
        }
    }
    else if (!UNICODE_IS_INVARIANT(c)) {
        reportException(Rexx_Error_Execution_user_defined, "Malformed UTF-8 string\n");
        return -1;
    }
    else {
        i->bytepos++;
    }

    i->charpos++;
    return c;
}

wholenumber_t
ENCODING_UTF8::iter_get_and_advance(IRexxString *str, String_iter *i)
{
    return utf8_iter_get_and_advance(str->getStringData(), str->getBLength(), i);
}

/*

=item C<static void utf8_iter_set_and_advance(IRexxString *str,
String_iter *i, wholenumber_t c)>

The UTF-8 implementation of the string iterator's C<set_and_advance>
function.

=cut

*/

void
ENCODING_UTF8::iter_set_and_advance(IRexxString *str, String_iter *i, wholenumber_t c)
{
    char *pos = str->getWritableData() + i->bytepos;
    size_t count = utf8_encode(pos, c);

    i->bytepos += count;
    /* XXX possible buffer overrun exception? */
    //PARROT_ASSERT(i->bytepos <= Buffer_buflen(str));
    i->charpos++;
}

/*

=item C<static void utf8_iter_set_position(IRexxString *str,
String_iter *i, wholenumber_t pos)>

The UTF-8 implementation of the string iterator's C<set_position>
function.

=cut

*/

void
ENCODING_UTF8::iter_set_position(IRexxString *str, String_iter *i, wholenumber_t pos)
{
    const utf8_t *u8ptr = (const utf8_t *)str->getStringData();

    if (pos == 0) {
        i->charpos = 0;
        i->bytepos = 0;
        return;
    }

    /*
     * we know the byte offsets of three positions: start, current and end
     * now find the shortest way to reach pos
     */
    if (pos < i->charpos) {
        if (pos <= (i->charpos >> 1)) {
            /* go forward from start */
            u8ptr = (const utf8_t *)utf8_skip_forward(u8ptr, pos);
        }
        else {
            /* go backward from current */
            u8ptr = (const utf8_t *)utf8_skip_backward(u8ptr + i->bytepos, i->charpos - pos);
        }
    }
    else {
        wholenumber_t  len = str->getBLength();
        if (pos <= i->charpos + ((len - i->charpos) >> 1)) {
            /* go forward from current */
            u8ptr = (const utf8_t *)utf8_skip_forward(u8ptr + i->bytepos, pos - i->charpos);
        }
        else {
            /* go backward from end */
            u8ptr = (const utf8_t *)utf8_skip_backward(u8ptr + str->getBLength(), len - pos);
        }
    }

    i->charpos = pos;
    i->bytepos = (const char *)u8ptr - (const char *)str->getStringData();
}


/*

=item C<static RexxMutableBuffer * encode(IRexxString *src)>

Converts the string C<src> to this particular encoding.

=cut

*/

RexxMutableBuffer *
ENCODING_UTF8::encode(IRexxString *src)
{
    ENCODING *src_encoding;
    wholenumber_t dest_pos, src_len;
    char *p;

    if (src->getEncoding() == m17n_utf8_encoding_ptr)
        return src->makeMutableBuffer();

    if (src->getCLength() == 0)
        return new RexxMutableBuffer(0, 0, m17n_unicode_charset_ptr, m17n_utf8_encoding_ptr);

    RexxMutableBuffer *result= new RexxMutableBuffer(src->getBLength(), src->getBLength(), m17n_unicode_charset_ptr, m17n_utf8_encoding_ptr);
    ProtectedObject pr(result);
    src_len = src->getCLength();
    result->setCLength(src_len);

    /* save source encoding before possibly changing it */
    src_encoding = src->getEncoding();

    if (src->getCharset() == m17n_ascii_charset_ptr) {
        // todojlf : replace by memcpy
        for (dest_pos = 0; dest_pos < src_len; ++dest_pos) {
            result->getData()[dest_pos] = src->getStringData()[dest_pos];
        }
        result->setBLength(src_len);
    }
    else {
        String_iter src_iter;
        STRING_ITER_INIT(&src_iter);
        dest_pos = 0;
        while (src_iter.charpos < src_len) {
            wholenumber_t c = src_encoding->iter_get_and_advance(src, &src_iter);
            result->ensureCapacity(m17n_utf8_encoding_ptr->max_bytes_per_codepoint);
            p = result->getData() + dest_pos;
            size_t count = utf8_encode(p, c);
            dest_pos += count;
        }
        result->setBLength(dest_pos);
    }

    return result;
}

/*

=item C<static wholenumber_t get_codepoint(IRexxString *src, wholenumber_t
offset)>

Returns the codepoint in string C<src> at position C<offset>.

=cut

*/

wholenumber_t
ENCODING_UTF8::get_codepoint(IRexxString *src, wholenumber_t offset)
{
    const utf8_t * const start = (const utf8_t *)utf8_skip_forward(src->getStringData(), offset);
    return utf8_decode(start);
}


/*

=item C<static wholenumber_t find_cclass(IRexxString *s, wholenumber_t
*typetable, wholenumber_t flags, wholenumber_t pos, wholenumber_t end)>

Stub, the charset level handles this for unicode strings.

=cut

*/

wholenumber_t
ENCODING_UTF8::find_cclass(IRexxString *s, wholenumber_t *typetable,
wholenumber_t flags, wholenumber_t pos, wholenumber_t end)
{
    reportException(Rexx_Error_Execution_user_defined, "No find_cclass support in unicode encoding plugins");
    return -1;
}

/*

=item C<static wholenumber_t get_byte(IRexxString *src, wholenumber_t
offset)>

Returns the byte in string C<src> at position C<offset>.

=cut

*/

wholenumber_t
ENCODING_UTF8::get_byte(IRexxString *src, wholenumber_t offset)
{
    const char *contents = src->getStringData();
    if (offset >= (wholenumber_t) src->getBLength()) {
/*        Parrot_ex_throw_from_c_args(NULL, 0,
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
ENCODING_UTF8::set_byte(IRexxString *src,
        wholenumber_t offset, wholenumber_t byte)
{
    char *contents;

    if (offset >= (wholenumber_t) src->getBLength())
        reportException(Rexx_Error_Execution_user_defined, "set_byte past the end of the buffer");

    contents = src->getWritableData();
    contents[offset] = (char)byte;
}

/*

=item C<static RexxString * get_codepoints(RexxString *src, wholenumber_t
offset, wholenumber_t count)>

Returns the codepoints in string C<src> at position C<offset> and length
C<count>.

=cut

*/

RexxString *
ENCODING_UTF8::get_codepoints(RexxString *src, wholenumber_t offset, wholenumber_t count)
{
    String_iter    iter;
    STRING_ITER_INIT(&iter);
    if (offset) iter_set_position(RexxStringWrapper(src), &iter, offset);
    wholenumber_t startb = iter.bytepos;
    wholenumber_t startc = iter.charpos;
    if (count) iter_set_position(RexxStringWrapper(src), &iter, offset + count);
    wholenumber_t endb = iter.bytepos;
    wholenumber_t endc = iter.charpos;
    return new_string(src->getStringData() + startb, endb - startb, endc - startc, src->getCharset(), src->getEncoding()); 
}

/*

=item C<static RexxString * get_bytes(RexxString *src, wholenumber_t
offset, wholenumber_t count)>

Returns the bytes in string C<src> at position C<offset> and length C<count>.

=cut

*/

RexxString *
ENCODING_UTF8::get_bytes(RexxString *src, wholenumber_t offset, wholenumber_t count)
{
    return new_string(src->getStringData() + offset, count, count, src->getCharset(), src->getEncoding()); 
}



/*

=item C<static wholenumber_t codepoints(IRexxString *src)>

Returns the number of codepoints in string C<src>.

=cut

*/

wholenumber_t
ENCODING_UTF8::codepoints(IRexxString *src)
{
    String_iter iter;
    STRING_ITER_INIT(&iter);
    while (iter.bytepos < (wholenumber_t) src->getBLength())
        iter_get_and_advance(src, &iter);
    return iter.charpos;
}

wholenumber_t
ENCODING_UTF8::codepoints(const char *src, wholenumber_t blength)
{
    String_iter iter;
    STRING_ITER_INIT(&iter);
    while (iter.bytepos < blength)
        utf8_iter_get_and_advance(src, blength, &iter);
    return iter.charpos;
}

/*

=item C<static wholenumber_t bytes(IRexxString *src)>

Returns the number of bytes in string C<src>.

=cut

*/

wholenumber_t
ENCODING_UTF8::bytes(IRexxString *src)
{
    return src->getBLength();
}

/*

=item C<void m17n_encoding_utf8_init()>

Initializes the UTF-8 encoding.

=cut

*/

void
m17n_encoding_utf8_init()
{
    ENCODING_UTF8 * const return_encoding = new ENCODING_UTF8;
    return_encoding->name = "utf-8";
    return_encoding->max_bytes_per_codepoint = 4;
    m17n_register_encoding(return_encoding);
}
