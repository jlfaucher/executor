/*
Copyright (C) 2004-2010, Parrot Foundation.
$Id: binary.c 48206 2010-07-28 21:52:30Z darbelo $

=head1 NAME

src/string/charset/binary.c

=head1 DESCRIPTION

This file implements the charset functions for binary data

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
#include "m17n_charset_binary.h"


/*

=item C<static RexxString* convert(RexxString *src)>

Converts the RexxString C<src> to RexxString C<dest> in binary mode. Throws
an exception if a suitable conversion function is not found.

=cut

*/

RexxString*
CHARSET_BINARY::convert(RexxString *src)
{
    charset_converter_t conversion_func =
        m17n_find_charset_converter(src->getCharset(), m17n_binary_charset_ptr);

    if (conversion_func)
         return conversion_func(src);

    reportException(Rexx_Error_Execution_user_defined,
        "conversion to binary not implemented");
    return (RexxString *)TheNilObject;
}

/*

=item C<static RexxString* compose(RexxString *src)>

Throws an exception because we cannot compose a binary string.

=cut

*/

/* A err. can't compose binary */
RexxString*
CHARSET_BINARY::compose(RexxString *src)
{
    reportException(Rexx_Error_Execution_user_defined, "Can't compose binary data");
    return (RexxString *)TheNilObject;
}

/*

=item C<static RexxString* decompose(RexxString *src)>

Throws an exception because we cannot decompose a binary string.

=cut

*/

/* A err. can't decompose binary */
RexxString*
CHARSET_BINARY::decompose(RexxString *src)
{
    reportException(Rexx_Error_Execution_user_defined, "Can't decompose binary data");
    return (RexxString *)TheNilObject;
}

/*

=item C<static RexxString* upcase(RexxString *src)>

Throws an exception because we cannot convert a binary string to
upper case.

=cut

*/

RexxString*
CHARSET_BINARY::upcase(RexxString *src, ssizeC_t start, ssizeC_t length)
{
    reportException(Rexx_Error_Execution_user_defined, "Can't upcase binary data");
    return (RexxString *)TheNilObject;
}

/*

=item C<static RexxString* downcase(RexxString *src)>

Throws an exception because we cannot convert a binary string to
lower-case.

=cut

*/

RexxString*
CHARSET_BINARY::downcase(RexxString *src, ssizeC_t start, ssizeC_t length)
{
    reportException(Rexx_Error_Execution_user_defined, "Can't downcase binary data");
    return (RexxString *)TheNilObject;
}

/*

=item C<static RexxString* titlecase(RexxString *src)>

Throws an exception because we cannot convert a binary string to
title case.

=cut

*/

RexxString*
CHARSET_BINARY::titlecase(RexxString *src)
{
    reportException(Rexx_Error_Execution_user_defined, "Can't titlecase binary data");
    return (RexxString *)TheNilObject;
}

/*

=item C<static RexxString* upcase_first(RexxString *src)>

Throws an exception because we cannot set the first "character" of the
binary string to uppercase.

=cut

*/

RexxString*
CHARSET_BINARY::upcase_first(RexxString *src)
{
    reportException(Rexx_Error_Execution_user_defined, "Can't upcase binary data");
    return (RexxString *)TheNilObject;
}

/*

=item C<static RexxString* downcase_first(RexxString *src)>

Throws an exception because we cannot set the first "character"
of the binary string to lowercase.

=cut

*/

RexxString*
CHARSET_BINARY::downcase_first(RexxString *src)
{
    reportException(Rexx_Error_Execution_user_defined, "Can't downcase binary data");
    return (RexxString *)TheNilObject;
}

/*

=item C<static RexxString* titlecase_first(RexxString *src)>

Throws an exception because we can't convert the first "character"
of binary data to title case.

=cut

*/

RexxString*
CHARSET_BINARY::titlecase_first(RexxString *src)
{
    reportException(Rexx_Error_Execution_user_defined, "Can't titlecase binary data");
    return (RexxString *)TheNilObject;
}

/*

=item C<static wholenumber_t compare(RexxString *lhs, RexxString
*rhs)>

Compare the two buffers, first by size, then with memcmp.

=cut

*/

wholenumber_t
CHARSET_BINARY::compare(IRexxString *lhs, IRexxString *rhs)
{
    const sizeB_t l_len = lhs->getBLength();
    const sizeB_t r_len = rhs->getBLength();
    if (l_len != r_len)
        return l_len < r_len ? -1 : 1;

    return memcmp(lhs->getStringData(), rhs->getStringData(), l_len);
}

/*

=item C<static wholenumber_t validate(IRexxString *src)>

Returns 1. All sequential data is valid binary data.

=cut

*/

/* Binary's always valid */
wholenumber_t
CHARSET_BINARY::validate(IRexxString *src)
{
    return 1;
}

/*

=item C<static wholenumber_t is_cclass(wholenumber_t flags, IRexxString *src,
sizeC_t offset)>

Returns Boolean.

=cut

*/

wholenumber_t
CHARSET_BINARY::is_cclass(wholenumber_t flags, IRexxString *src, sizeC_t offset)
{
    return 0;
}

/*

=item C<static sizeC_t find_cclass(wholenumber_t flags, IRexxString
*src, sizeC_t offset, sizeC_t count)>

Find a character in the given character class.

=cut

*/

sizeC_t
CHARSET_BINARY::find_cclass(wholenumber_t flags,
            IRexxString *src, sizeC_t offset, sizeC_t count)
{
    return offset + count;
}

/*

=item C<static wholenumber_t find_not_cclass(wholenumber_t flags, IRexxString
*src, sizeC_t offset, sizeC_t count)>

Returns C<wholenumber_t>.

=cut

*/

sizeC_t
CHARSET_BINARY::find_not_cclass(wholenumber_t flags,
               IRexxString *src, sizeC_t offset, sizeC_t count)
{
    return offset + count;
}

/*

=item C<static RexxString * string_from_codepoint(codepoint_t codepoint)>

Creates a new RexxString object from a single codepoint C<codepoint>. Returns
the new RexxString.

=cut

*/

RexxString *
CHARSET_BINARY::string_from_codepoint(codepoint_t codepoint)
{
    RexxString *return_string;
    char real_codepoint = (char)codepoint;
    return_string = new_string(&real_codepoint, 1, 1, m17n_binary_charset_ptr, m17n_binary_charset_ptr->preferred_encoding);
    return return_string;
}


/*

=item C<void m17n_charset_binary_init()>

Initialize the binary charset, including function pointers and
settings.

=cut

*/

void
m17n_charset_binary_init()
{
    CHARSET_BINARY * const return_set = new CHARSET_BINARY;
    return_set->name = "binary";
    return_set->preferred_encoding = m17n_fixed_8_encoding_ptr;
    m17n_register_charset(return_set);
}
