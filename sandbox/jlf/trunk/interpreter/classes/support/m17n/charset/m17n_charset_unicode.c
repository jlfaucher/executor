/*
Copyright (C) 2005-2010, Parrot Foundation.
$Id: unicode.c 47917 2010-06-29 23:18:38Z jkeenan $

=head1 NAME

src/string/charset/unicode.c

=head1 DESCRIPTION

This file implements the charset functions for unicode data

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

#include "m17n_charset_unicode.h"
#include "m17n_charset_ascii.h"
#include "m17n_charset_tables.h"


#ifdef EXCEPTION
#  undef EXCEPTION
#endif

#if defined(HAVE_ICU)
#  include <unicode/ucnv.h>
#  include <unicode/utypes.h>
#  include <unicode/uchar.h>
#  include <unicode/ustring.h>
#  include <unicode/unorm.h>
#endif
#define EXCEPTION(str) \
    reportException(Rexx_Error_Execution_user_defined, (str))

#define UNIMPL EXCEPTION("unimplemented unicode")


/*

=item C<static RexxString * get_graphemes(RexxString *src, wholenumber_t
offset, wholenumber_t count)>

Gets the graphemes from RexxString C<src> starting at C<offset>. Gets
C<count> graphemes total.

=cut

*/

RexxString *
CHARSET_UNICODE::get_graphemes(RexxString *src, wholenumber_t offset, wholenumber_t count)
{
    return ENCODING_GET_CODEPOINTS(src, offset, count);
}


/*

=item C<static RexxString* convert(RexxString *src)>

Converts input RexxString C<src> to unicode RexxString C<dest>.

=cut

*/

RexxString*
CHARSET_UNICODE::convert(RexxString *src)
{
    charset_converter_t conversion_func =
            m17n_find_charset_converter(src->getCharset(),
                    m17n_unicode_charset_ptr);

    if (conversion_func)
         return conversion_func(src);

    return m17n_utf8_encoding_ptr->encode(RexxStringWrapper(src))->makeString();
}


/*

=item C<static RexxString* compose(RexxString *src)>

If m17n is built with ICU, composes the RexxString C<src>. Attempts to
denormalize the RexxString into the ICU default, NFC.

If m17n does not have ICU included, throws an exception.

=cut

*/

RexxString*
CHARSET_UNICODE::compose(RexxString *src)
{
#if defined(HAVE_ICU)
    RexxString *dest;
    int src_len, dest_len;
    UErrorCode err;
    /*
       U_STABLE int32_t U_EXPORT2
       unorm_normalize(const UChar *source, int32_t sourceLength,
       UNormalizationMode mode, int32_t options,
       UChar *result, int32_t resultLength,
       UErrorCode *status);
       */
    dest_len = src_len = src->getBLength();
    dest = raw_string(dest_len * sizeof (UChar), 0, src->getCharset(), src->getEncoding());

    err      = U_ZERO_ERROR;
    dest_len = unorm_normalize((UChar *)src->getStringData(), src_len,
            UNORM_DEFAULT,      /* default is NFC */
            0,                  /* options 0 default - no specific icu version */
            (UChar *)dest->getWritableData(), dest_len, &err);


    if (!U_SUCCESS(err)) {
        err = U_ZERO_ERROR;
        // Allocate the needed size
        dest = raw_string(dest_len * sizeof (UChar), 0, src->getCharset(), src->getEncoding());
        dest_len = unorm_normalize((UChar *)src->getStringData(), src_len,
                UNORM_DEFAULT,      /* default is NFC */
                0,                  /* options 0 default - no specific icu version */
                (UChar *)dest->getWritableData(), dest_len, &err);
        // PARROT_ASSERT(U_SUCCESS(err));
    }
    dest->setBLength(dest_len * sizeof (UChar));
    dest->setCLength(dest_len);
    return dest;
#else
    reportException(Rexx_Error_Execution_user_defined,
        "no ICU lib loaded");
    return (RexxString *)TheNilObject;
#endif
}


/*

=item C<static RexxString* decompose(RexxString *src)>

Decompose function for unicode charset. This function is not yet implemented.

=cut

*/

RexxString*
CHARSET_UNICODE::decompose(RexxString *src)
{
    /* TODO: https://trac.parrot.org/parrot/wiki/StringsTasklist Implement this. */
    UNIMPL;
    return (RexxString *)TheNilObject;
}


/*

=item C<static RexxString* upcase(RexxString *src)>

Converts the RexxString C<src> to all upper-case graphemes, for those characters
which support upper-case versions.

Throws an exception if ICU is not installed.

=cut

*/

RexxString*
CHARSET_UNICODE::upcase(RexxString *src)
{
    if (src->getBLength()  == src->getCLength()
            && src->getEncoding() == m17n_utf8_encoding_ptr) {
        return m17n_ascii_charset_ptr->upcase(src);
    }

#if defined(HAVE_ICU)
    UErrorCode err;
    int dest_len, src_len, needed;
    /* encode will allocate new string */
    RexxMutableBuffer *res = m17n_utf16_encoding_ptr->encode(RexxStringWrapper(src));
    ProtectedObject p(res); // May need reallocation, must stay alive
    /*
       U_CAPI int32_t U_EXPORT2
       u_strToUpper(UChar *dest, int32_t destCapacity,
       const UChar *src, int32_t srcLength,
       const char *locale,
       UErrorCode *pErrorCode);
       */
    err = U_ZERO_ERROR;

    /* use all available space - see below XXX */
    /* TODO downcase, titlecase too */
    dest_len = res->getBufferLength() / sizeof (UChar);
    src_len  = res->getBLength() / sizeof(UChar);

    /*
     * XXX troubles:
     *   t/op/string_cs_45  upcase unicode:"\u01f0"
     *   this creates \u004a \u030c J+NON-SPACING HACEK
     *   the string needs resizing, *if* the src buffer is
     *   too short. *But* with icu 3.2/3.4 the src string is
     *   overwritten with partial result, despite the icu docs sayeth:
     *
     *      The source string and the destination buffer
     *      are allowed to overlap.
     *
     *  Workaround:  'preflighting' returns needed length
     *  Alternative: forget about inplace operation - create new result
     *
     */
    needed = u_strToUpper(NULL, 0,  // 0 : query needed size
            (UChar *)res->getData(), src_len,
            NULL,       /* locale = default */
            &err);

    if (needed > dest_len) {
        res->setBufferLength(needed * sizeof(UChar));
        dest_len = needed;
    }

    err      = U_ZERO_ERROR;
    dest_len = u_strToUpper((UChar *)res->getData(), dest_len,
            (UChar *)res->getStringData(), src_len,
            NULL,       /* locale = default */
            &err);
    // PARROT_ASSERT(U_SUCCESS(err));
    res->setBLength(dest_len * sizeof (UChar));

    /* downgrade if possible */
    if (dest_len == res->getCLength())
        res->setEncoding(m17n_ucs2_encoding_ptr);
    else {
        /* string is likely still ucs2 if it was earlier
         * but strlen changed due to combining char
         */
        res->setCLength(dest_len);
    }

    return res->makeString();

#else
    reportException(Rexx_Error_Execution_user_defined,
        "no ICU lib loaded");
    return (RexxString *)TheNilObject;
#endif
}


/*

=item C<static RexxString* downcase(RexxString *src)>

Converts all graphemes to lower-case, for those graphemes which have cases.

Throws an exception if ICU is not installed.

=cut

*/

RexxString*
CHARSET_UNICODE::downcase(RexxString *src)
{
    if (src->getBLength()  == src->getCLength()
            && src->getEncoding() == m17n_utf8_encoding_ptr) {
        return m17n_ascii_charset_ptr->downcase(src);
    }

#if defined(HAVE_ICU)
    UErrorCode err;
    int dest_len, src_len, needed;
    /* encode will allocate new string */
    RexxMutableBuffer *res = m17n_utf16_encoding_ptr->encode(RexxStringWrapper(src));
    ProtectedObject p(res); // May need reallocation, must stay alive
    /*
    U_CAPI int32_t U_EXPORT2
    u_strToLower(UChar *dest, int32_t destCapacity,
                 const UChar *src, int32_t srcLength,
                 const char *locale,
                 UErrorCode *pErrorCode);
     */
    err      = U_ZERO_ERROR;
    dest_len = res->getBufferLength() / sizeof (UChar);
    src_len  = res->getBLength() / sizeof (UChar);

    needed = u_strToLower(NULL, 0,  // 0 : query needed size,
            (UChar *)res->getData(), src_len,
            NULL,       /* locale = default */
            &err);

    if (needed > dest_len) {
        res->setBufferLength(needed * sizeof(UChar));
        dest_len = needed;
    }

    err = U_ZERO_ERROR;
    dest_len = u_strToLower((UChar *)res->getData(), dest_len,
            (UChar *)res->getStringData(), src_len,
            NULL,       /* locale = default */
            &err);
    // PARROT_ASSERT(U_SUCCESS(err));
    res->setBLength(dest_len * sizeof (UChar));

    /* downgrade if possible */
    if (dest_len == res->getCLength())
        res->setEncoding(m17n_ucs2_encoding_ptr);
    else {
        /* string is likely still ucs2 if it was earlier
         * but strlen changed due to combining char
         */
        res->setCLength(dest_len);
    }

    return res->makeString();

#else
    reportException(Rexx_Error_Execution_user_defined,
        "no ICU lib loaded");
    return (RexxString *)TheNilObject;
#endif
}


/*

=item C<static RexxString* titlecase(RexxString *src)>

Converts the string to title case, for those characters which support cases.

Throws an exception if ICU is not installed.

=cut

*/

RexxString*
CHARSET_UNICODE::titlecase(RexxString *src)
{
#if defined(HAVE_ICU)

    UErrorCode err;
    int dest_len, src_len, needed;

    if (src->getBLength()  == src->getCLength()
    &&  src->getEncoding() == m17n_utf8_encoding_ptr) {
        return m17n_ascii_charset_ptr->titlecase(src);
    }

    /* encode will allocate new string */
    RexxMutableBuffer *res = m17n_utf16_encoding_ptr->encode(RexxStringWrapper(src));
    ProtectedObject p(res); // May need reallocation, must stay alive

    /*
    U_CAPI int32_t U_EXPORT2
    u_strToTitle(UChar *dest, int32_t destCapacity,
                 const UChar *src, int32_t srcLength,
                 UBreakIterator *titleIter,
                 const char *locale,
                 UErrorCode *pErrorCode);
     */

    err      = U_ZERO_ERROR;
    dest_len = res->getBufferLength() / sizeof (UChar);
    src_len  = res->getBLength() / sizeof (UChar);

    needed = u_strToTitle(NULL, 0,  // 0 : query needed size
            (UChar *)res->getData(), src_len,
            NULL,       /* default titleiter */
            NULL,       /* locale = default */
            &err);

    if (needed > dest_len) {
        res->setBufferLength(needed * sizeof(UChar));
        dest_len = needed;
    }

    err = U_ZERO_ERROR;
    dest_len = u_strToTitle((UChar *)res->getData(), dest_len,
            (UChar *)res->getStringData(), src_len,
            NULL, NULL,
            &err);
    // PARROT_ASSERT(U_SUCCESS(err));
    res->setBLength(dest_len * sizeof (UChar));

    /* downgrade if possible */
    if (dest_len == res->getCLength())
        res->setEncoding(m17n_ucs2_encoding_ptr);
    else {
        /* string is likely still ucs2 if it was earlier
         * but strlen changed due to combining char
         */
        res->setCLength(dest_len);
    }

    return res->makeString();

#else
    reportException(Rexx_Error_Execution_user_defined,
        "no ICU lib loaded");
    return (RexxString *)TheNilObject;
#endif
}


/*

=item C<static RexxString* upcase_first(RexxString *src)>

Converts the first grapheme in the RexxString C<src> to uppercase, if the
grapheme supports it. Not implemented.

=cut

*/

RexxString*
CHARSET_UNICODE::upcase_first(RexxString *src)
{
    /* TODO: https://trac.parrot.org/parrot/wiki/StringsTasklist Implement this. */
    UNIMPL;
    return (RexxString *)TheNilObject;
}


/*

=item C<static RexxString* downcase_first(RexxString *src)>

Converts the first grapheme in the RexxString C<src> to lower-case, if
the grapheme supports it. Not implemented

=cut

*/

RexxString*
CHARSET_UNICODE::downcase_first(RexxString *src)
{
    /* TODO: https://trac.parrot.org/parrot/wiki/StringsTasklist Implement this. */
    UNIMPL;
    return (RexxString *)TheNilObject;
}


/*

=item C<static RexxString* titlecase_first(RexxString *src)>

Converts the first grapheme in RexxString C<src> to title case, if the
string supports it. Not implemented.

=cut

*/

RexxString*
CHARSET_UNICODE::titlecase_first(RexxString *src)
{
    /* TODO: https://trac.parrot.org/parrot/wiki/StringsTasklist Implement this. */
    UNIMPL;
    return (RexxString *)TheNilObject;
}


/*

=item C<static wholenumber_t compare(IRexxString *lhs, IRexxString
*rhs)>

Compares two IRexxStrings, C<lhs> and C<rhs>. Returns -1 if C<lhs> < C<rhs>. Returns
0 if C<lhs> = C<rhs>. Returns 1 if C<lhs> > C<rhs>.

=cut

*/

wholenumber_t
CHARSET_UNICODE::compare(IRexxString *lhs, IRexxString *rhs)
{
    String_iter l_iter, r_iter;
    wholenumber_t min_len, l_len, r_len;

    /* TODO make optimized equal - strings are equal length then already */
    STRING_ITER_INIT(&l_iter);
    STRING_ITER_INIT(&r_iter);

    l_len = lhs->getCLength();
    r_len = rhs->getCLength();

    min_len = l_len > r_len ? r_len : l_len;

    while (l_iter.charpos < min_len) {
        const wholenumber_t cl = STRING_ITER_GET_AND_ADVANCE(lhs, &l_iter);
        const wholenumber_t cr = STRING_ITER_GET_AND_ADVANCE(rhs, &r_iter);

        if (cl != cr)
            return cl < cr ? -1 : 1;
    }

    if (l_len < r_len)
        return -1;

    if (l_len > r_len)
        return 1;

    return 0;
}


/*

=item C<wholenumber_t mixed_cs_index(IRexxString *src, IRexxString
*search_string, wholenumber_t offset)>

Searches for the first instance of IRexxString C<search> in IRexxString C<src>.
returns the position where the substring is found if it is indeed found.
Returns -1 otherwise.

=cut

*/

wholenumber_t
CHARSET_UNICODE::index(IRexxString *src,
        IRexxString *search_string, wholenumber_t offset)
{
    return mixed_cs_index(src, search_string, offset);
}


/*

=item C<static wholenumber_t cs_rindex(IRexxString *src, IRexxString
*search_string, wholenumber_t offset)>

Finds the last index of substring C<search_string> in IRexxString C<src>,
starting from C<offset>. Not implemented.

=cut

*/

wholenumber_t
CHARSET_UNICODE::rindex(IRexxString *src,
        IRexxString *search_string, wholenumber_t offset)
{
    /* TODO: https://trac.parrot.org/parrot/wiki/StringsTasklist Implement this. */
    UNIMPL;
    return -1;
}


/*

=item C<static wholenumber_t validate(IRexxString *src)>

Returns 1 if the IRexxString C<src> is a valid unicode string, returns 0 otherwise.

=cut

*/

wholenumber_t
CHARSET_UNICODE::validate(IRexxString *src)
{
    String_iter iter;
    const wholenumber_t length = src->getCLength();

    STRING_ITER_INIT(&iter);
    while (iter.charpos < length) {
        const wholenumber_t codepoint = STRING_ITER_GET_AND_ADVANCE(src, &iter);
        /* Check for Unicode non-characters */
        if (codepoint >= 0xfdd0
        && (codepoint <= 0xfdef || (codepoint & 0xfffe) == 0xfffe)
        &&  codepoint <= 0x10ffff)
            return 0;
    }

    return 1;
}


/*

=item C<static int u_iscclass(wholenumber_t codepoint, wholenumber_t flags)>

Returns Boolean.

=cut

*/

static int
u_iscclass(wholenumber_t codepoint, wholenumber_t flags)
{
#if defined(HAVE_ICU)
            /* XXX which one
               return u_charDigitValue(codepoint);
               */
    if ((flags & enum_cclass_uppercase)    && u_isupper(codepoint))  return 1;
    if ((flags & enum_cclass_lowercase)    && u_islower(codepoint))  return 1;
    if ((flags & enum_cclass_alphabetic)   && u_isalpha(codepoint))  return 1;
    if ((flags & enum_cclass_numeric)      && u_isdigit(codepoint))  return 1;
    if ((flags & enum_cclass_hexadecimal)  && u_isxdigit(codepoint)) return 1;
    if ((flags & enum_cclass_whitespace)   && u_isspace(codepoint))  return 1;
    if ((flags & enum_cclass_printing)     && u_isprint(codepoint))  return 1;
    if ((flags & enum_cclass_graphical)    && u_isgraph(codepoint))  return 1;
    if ((flags & enum_cclass_blank)        && u_isblank(codepoint))  return 1;
    if ((flags & enum_cclass_control)      && u_iscntrl(codepoint))  return 1;
    if ((flags & enum_cclass_alphanumeric) && u_isalnum(codepoint))  return 1;
    if ((flags & enum_cclass_word)         &&
        (u_isalnum(codepoint) || codepoint == '_'))                  return 1;

    return 0;
#else
    if (codepoint < 256)
        return (m17n_iso_8859_1_typetable[codepoint] & flags) ? 1 : 0;

    if (flags == enum_cclass_any)
        return 1;

    /* All codepoints from u+0100 to u+02af are alphabetic, so we
     * cheat on the WORD and ALPHABETIC properties to include these
     * (and incorrectly exclude all others).  This is a stopgap until
     * ICU is everywhere, or we have better non-ICU unicode support. */
    if (flags == enum_cclass_word || flags == enum_cclass_alphabetic)
        return (codepoint < 0x2b0);

    if (flags & enum_cclass_whitespace) {
        /* from http://www.unicode.org/Public/UNIDATA/PropList.txt */
        switch (codepoint) {
          case 0x1680: case 0x180e: case 0x2000: case 0x2001:
          case 0x2002: case 0x2003: case 0x2004: case 0x2005:
          case 0x2006: case 0x2007: case 0x2008: case 0x2009:
          case 0x200a: case 0x2028: case 0x2029: case 0x202f:
          case 0x205f: case 0x3000:
            return 1;
          default:
            break;
        }
    }

    if (flags & enum_cclass_numeric) {
        /* from http://www.unicode.org/Public/UNIDATA/UnicodeData.txt */
        if (codepoint >= 0x0660 && codepoint <= 0x0669) return 1;
        if (codepoint >= 0x06f0 && codepoint <= 0x06f9) return 1;
        if (codepoint >= 0x07c0 && codepoint <= 0x07c9) return 1;
        if (codepoint >= 0x0966 && codepoint <= 0x096f) return 1;
        if (codepoint >= 0x09e6 && codepoint <= 0x09ef) return 1;
        if (codepoint >= 0x0a66 && codepoint <= 0x0a6f) return 1;
        if (codepoint >= 0x0ae6 && codepoint <= 0x0aef) return 1;
        if (codepoint >= 0x0b66 && codepoint <= 0x0b6f) return 1;
        if (codepoint >= 0x0be6 && codepoint <= 0x0bef) return 1;
        if (codepoint >= 0x0c66 && codepoint <= 0x0c6f) return 1;
        if (codepoint >= 0x0ce6 && codepoint <= 0x0cef) return 1;
        if (codepoint >= 0x0d66 && codepoint <= 0x0d6f) return 1;
        if (codepoint >= 0x0e50 && codepoint <= 0x0e59) return 1;
        if (codepoint >= 0x0ed0 && codepoint <= 0x0ed9) return 1;
        if (codepoint >= 0x0f20 && codepoint <= 0x0f29) return 1;
        if (codepoint >= 0x1040 && codepoint <= 0x1049) return 1;
        if (codepoint >= 0x17e0 && codepoint <= 0x17e9) return 1;
        if (codepoint >= 0x1810 && codepoint <= 0x1819) return 1;
        if (codepoint >= 0x1946 && codepoint <= 0x194f) return 1;
        if (codepoint >= 0x19d0 && codepoint <= 0x19d9) return 1;
        if (codepoint >= 0x1b50 && codepoint <= 0x1b59) return 1;
        if (codepoint >= 0xff10 && codepoint <= 0xff19) return 1;
    }

    if (flags & ~(enum_cclass_whitespace | enum_cclass_numeric | enum_cclass_newline))
        reportException(Rexx_Error_Execution_user_defined,
            "no ICU lib loaded");

    return 0;
#endif
}


/*

=item C<static wholenumber_t is_cclass(wholenumber_t flags, IRexxString *src,
wholenumber_t offset)>

Returns Boolean.

=cut

*/

wholenumber_t
CHARSET_UNICODE::is_cclass(wholenumber_t flags, IRexxString *src, wholenumber_t offset)
{
    wholenumber_t codepoint;

    if (offset >= (wholenumber_t) src->getCLength())
        return 0;

    codepoint = ENCODING_GET_CODEPOINT(src, offset);

    if (codepoint >= 256)
        return u_iscclass(codepoint, flags) != 0;

    return (m17n_iso_8859_1_typetable[codepoint] & flags) ? 1 : 0;
}


/*

=item C<static wholenumber_t find_cclass(wholenumber_t flags, IRexxString
*src, wholenumber_t offset, wholenumber_t count)>

Find a character in the given character class.

=cut

*/

wholenumber_t
CHARSET_UNICODE::find_cclass(wholenumber_t flags, IRexxString *src, wholenumber_t offset, wholenumber_t count)
{
    String_iter iter;
    wholenumber_t     codepoint;
    wholenumber_t     end = offset + count;

    STRING_ITER_INIT(&iter);
    STRING_ITER_SET_POSITION(src, &iter, offset);

    end = (wholenumber_t) src->getCLength() < end ? src->getCLength() : end;

    while (iter.charpos < end) {
        codepoint = STRING_ITER_GET_AND_ADVANCE(src, &iter);
        if (codepoint >= 256) {
            if (u_iscclass(codepoint, flags))
                    return iter.charpos - 1;
        }
        else {
            if (m17n_iso_8859_1_typetable[codepoint] & flags)
                return iter.charpos - 1;
        }
    }

    return end;
}


/*

=item C<static wholenumber_t find_not_cclass(wholenumber_t flags, IRexxString
*src, wholenumber_t offset, wholenumber_t count)>

Returns C<wholenumber_t>.

=cut

*/

wholenumber_t
CHARSET_UNICODE::find_not_cclass(wholenumber_t flags, IRexxString *src,
        wholenumber_t offset, wholenumber_t count)
{
    String_iter iter;
    wholenumber_t     codepoint;
    wholenumber_t     end = offset + count;
    int         bit;

    if (offset > (wholenumber_t) src->getCLength()) {
        /* XXX: Throw in this case? */
        return offset + count;
    }

    STRING_ITER_INIT(&iter);

    if (offset)
        STRING_ITER_SET_POSITION(src, &iter, offset);

    end = (wholenumber_t) src->getCLength() < end ? src->getCLength() : end;

    if (flags == enum_cclass_any)
        return end;

    while (iter.charpos < end) {
        codepoint = STRING_ITER_GET_AND_ADVANCE(src, &iter);
        if (codepoint >= 256) {
            for (bit = enum_cclass_uppercase;
                    bit <= enum_cclass_word ; bit <<= 1) {
                if ((bit & flags) && !u_iscclass(codepoint, bit))
                    return iter.charpos - 1;
            }
        }
        else {
            if (!(m17n_iso_8859_1_typetable[codepoint] & flags))
                return iter.charpos - 1;
        }
    }

    return end;
}


/*

=item C<static RexxString * string_from_codepoint(wholenumber_t codepoint)>

Returns a one-codepoint string for the given codepoint.

=cut

*/

RexxString *
CHARSET_UNICODE::string_from_codepoint(wholenumber_t codepoint)
{
    String_iter    iter;
    size_t capacity = m17n_unicode_charset_ptr->preferred_encoding->max_bytes_per_codepoint;
    RexxString * dest = new_string("", capacity, 1, m17n_unicode_charset_ptr, m17n_unicode_charset_ptr->preferred_encoding);

    STRING_ITER_INIT(&iter);
    STRING_ITER_SET_AND_ADVANCE(RexxStringWrapper(dest), &iter, codepoint);
    dest->setBLength(iter.bytepos);

    return dest;
}


/*

=item C<void m17n_charset_unicode_init()>

Initializes the Unicode charset by installing all the necessary function
pointers.

=cut

*/

void
m17n_charset_unicode_init()
{
    CHARSET_UNICODE *return_set = new CHARSET_UNICODE;
    return_set->name = "unicode";
    /*
     * for now use utf8
     * TODO replace it with a fixed uint_16 or uint_32 encoding
     *      XXX if this is changed, modify string_make so it
     *          still takes "utf8" when fed "unicode" as charset!
     */
    return_set->preferred_encoding = m17n_utf8_encoding_ptr;
    m17n_register_charset(return_set);
}
