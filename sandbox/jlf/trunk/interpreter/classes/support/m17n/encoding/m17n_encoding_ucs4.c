/*
Copyright (C) 2010, Parrot Foundation.
$Id: ucs4.c 47006 2010-05-26 02:08:28Z petdance $

=head1 NAME

src/string/encoding/ucs4.c - UCS-4 encoding

=head1 DESCRIPTION

UCS-4 encoding with the help of the ICU library.

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

#include "m17n_encoding_ucs4.h"

#if defined(HAVE_ICU)
#  include <unicode/ustring.h>
#endif

/*

=item C<static RexxMutableBuffer * encode(RexxString *src)>

Converts the string C<src> to this particular encoding.

=cut

*/

RexxMutableBuffer *
ENCODING_UCS4::encode(IRexxString *src)
{
#if defined(HAVE_ICU)
    if (src->getEncoding() == m17n_ucs4_encoding_ptr) {
        return src->makeMutableBuffer();
    }
    else {
        wholenumber_t len = src->getCLength();
        RexxMutableBuffer *res = new RexxMutableBuffer(len * sizeof (UChar32), 0, m17n_unicode_charset_ptr, m17n_ucs4_encoding_ptr);
        UChar32 *buf = (UChar32 *) res->getData();
        wholenumber_t offs;
        for (offs = 0; offs < len; offs++){
            buf[offs] = src->getEncoding()->get_codepoint(src, offs); // todojf : reimplement with iterator ! highly inefficient !!!!
        };
        res->setCLength(len);
        res->setBLength(len * sizeof (UChar32));

        return res;
    }
#else
    no_ICU_lib();
    return (RexxMutableBuffer *)TheNilObject;
#endif

}

/*

=item C<static wholenumber_t get_codepoint(IRexxString *src, wholenumber_t
offset)>

Returns the codepoint in string C<src> at position C<offset>.

=cut

*/

wholenumber_t
ENCODING_UCS4::get_codepoint(IRexxString *src, wholenumber_t offset)
{
#if defined(HAVE_ICU)
    const UChar32 *s = (const UChar32*) src->getStringData();
    return s[offset];
#else
    no_ICU_lib();
    return -1;
#endif
}


/*

=item C<static wholenumber_t find_cclass(IRexxString *s, wholenumber_t
*typetable, wholenumber_t flags, wholenumber_t pos, wholenumber_t end)>

Stub, the charset level handles this for unicode strings.

=cut

*/

wholenumber_t
ENCODING_UCS4::find_cclass(IRexxString *s, wholenumber_t *typetable,
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
ENCODING_UCS4::get_byte(IRexxString *src, wholenumber_t offset)
{
    reportException(Rexx_Error_Execution_user_defined, "No get_byte for UCS-4");
    return -1;
}

/*

=item C<static void set_byte(IRexxString *src, wholenumber_t offset,
wholenumber_t byte)>

Sets, in string C<src> at position C<offset>, the byte C<byte>.

=cut

*/

void
ENCODING_UCS4::set_byte(IRexxString *src, wholenumber_t offset,
        wholenumber_t byte)
{
    reportException(Rexx_Error_Execution_user_defined, "No set_byte for UCS-4");
}

/*

=item C<static RexxString * get_codepoints(RexxString *src, wholenumber_t
offset, wholenumber_t count)>

Returns the C<count> codepoints stored at position C<offset> in string
C<src> as a new string.

=cut

*/

RexxString *
ENCODING_UCS4::get_codepoints(RexxString *src, wholenumber_t offset, wholenumber_t count)
{
#if defined(HAVE_ICU)
    return new_string(src->getStringData() + offset * sizeof (UChar32),
                      count * sizeof (UChar32), 
                      count,
                      src->getCharset(), src->getEncoding());
#else
    no_ICU_lib();
    return (RexxString *)TheNilObject;
#endif
}

/*

=item C<static RexxString * get_bytes(RexxString *src, wholenumber_t
offset, wholenumber_t count)>

Returns the bytes in string C<src> at position C<offset> and length C<count>.

=cut

*/

RexxString *
ENCODING_UCS4::get_bytes(RexxString *src, wholenumber_t offset,
        wholenumber_t count)
{
    reportException(Rexx_Error_Execution_user_defined, "No get_bytes for UCS-4");
    return (RexxString *)TheNilObject;
}


/*

=item C<static wholenumber_t codepoints(IRexxString *src)>

Returns the number of codepoints in string C<src>.

=cut

*/

wholenumber_t
ENCODING_UCS4::codepoints(IRexxString *src)
{
#if defined(HAVE_ICU)
    return src->getBLength() / sizeof (UChar32);
#else
    no_ICU_lib();
    return 0;
#endif
}

wholenumber_t
ENCODING_UCS4::codepoints(const char *src, wholenumber_t blength)
{
#if defined(HAVE_ICU)
    return blength / sizeof (UChar32);
#else
    no_ICU_lib();
    return 0;
#endif
}

/*

=item C<static wholenumber_t bytes(IRexxString *src)>

Returns the number of bytes in string C<src>.

=cut

*/

wholenumber_t
ENCODING_UCS4::bytes(IRexxString *src)
{
    return src->getBLength();
}

/*

=item C<static wholenumber_t ucs4_iter_get(IRexxString *str, const
String_iter *i, wholenumber_t offset)>

Get the character at C<i> + C<offset>.

=cut

*/

wholenumber_t
ENCODING_UCS4::iter_get(IRexxString *str, String_iter *i, wholenumber_t offset)
{
    return get_codepoint(str, i->charpos + offset);
}

/*

=item C<static void ucs4_iter_skip(IRexxString *str, String_iter
*i, wholenumber_t skip)>

Moves the string iterator C<i> by C<skip> characters.

=cut

*/

void
ENCODING_UCS4::iter_skip(IRexxString *str, String_iter *i, wholenumber_t skip)
{
#if defined(HAVE_ICU)
    i->charpos += skip;
    i->bytepos += skip * sizeof (UChar32);
#else
    no_ICU_lib();
#endif
}

/*

=item C<static wholenumber_t ucs4_iter_get_and_advance(IRexxString
*str, String_iter *i)>

Moves the string iterator C<i> to the next codepoint.

=cut

*/

wholenumber_t
ENCODING_UCS4::iter_get_and_advance(IRexxString *str, String_iter *i)
{

#if defined(HAVE_ICU)
    const UChar32 *s = (const UChar32*) str->getStringData();
    const UChar32 c = s[i->charpos++];
    i->bytepos += sizeof (UChar32);
    return c;
#else
    no_ICU_lib();
    return (wholenumber_t)0; /* Stop the static analyzers from panicing */
#endif
}

/*

=item C<static void ucs4_iter_set_and_advance(IRexxString *str,
String_iter *i, wholenumber_t c)>

With the string iterator C<i>, appends the codepoint C<c> and advances to the
next position in the string.

=cut

*/

void
ENCODING_UCS4::iter_set_and_advance(IRexxString *str, String_iter *i, wholenumber_t c)
{

#if defined(HAVE_ICU)
    UChar32 *s = (UChar32*) str->getWritableData();
    s[i->charpos++] = (UChar32)c;
    i->bytepos += sizeof (UChar32);
#else
    no_ICU_lib();
#endif
}

/*

=item C<static void ucs4_iter_set_position(IRexxString *str,
String_iter *i, wholenumber_t n)>

Moves the string iterator C<i> to the position C<n> in the string.

=cut

*/

void
ENCODING_UCS4::iter_set_position(IRexxString *str, String_iter *i, wholenumber_t n)
{
#if defined(HAVE_ICU)
    i->charpos = n;
    i->bytepos = n * sizeof (UChar32);
#else
    no_ICU_lib();
#endif
}

/*

=item C<void Parrot_encoding_ucs4_init()>

Initializes the UCS-4 encoding.

=cut

*/

void
m17n_encoding_ucs4_init()
{
    ENCODING_UCS4 * const return_encoding = new ENCODING_UCS4;
    return_encoding->name = "ucs-4";
    return_encoding->max_bytes_per_codepoint = 4;
    m17n_register_encoding(return_encoding);
}
