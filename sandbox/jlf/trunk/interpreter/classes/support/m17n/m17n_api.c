/*
Copyright (C) 2001-2010, Parrot Foundation.
$Id: api.c 48584 2010-08-20 13:50:18Z NotFound $

=head1 NAME

src/string/api.c - Parrot Strings

=head1 DESCRIPTION

This file implements the non-ICU parts of the Parrot string subsystem.

Note that C<bufstart> and C<buflen> are used by the memory subsystem. The
string functions may only use C<buflen> to determine if there is some space
left beyond C<bufused>. This is the I<only> valid usage of these two data
members, beside setting C<bufstart>/C<buflen> for external strings.

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

#include "m17n_encoding.h"

/*
=item C<wholenumber_t str_iter_index(RexxString *src,
String_iter *start, String_iter *end, RexxString *search)>

Find the next occurence of RexxString C<search> in RexxString C<src> starting at
String_iter C<start>. If C<search> is found C<start> is modified to mark the
beginning of C<search> and String_iter C<end> is set to the character after
C<search> in C<src>.  Returns the character position where C<search> was found
or -1 if it wasn't found.

=cut

*/

wholenumber_t
str_iter_index(
    IRexxString *src,
    String_iter *start, String_iter *end,
    IRexxString *search)
{
    String_iter search_iter, search_start, next_start;
    wholenumber_t len = search->getCLength();
    wholenumber_t c0;

    if (len == 0) {
        *end = *start;
        return start->charpos;
    }

    STRING_ITER_INIT(&search_iter);
    c0 = STRING_ITER_GET_AND_ADVANCE(search, &search_iter);
    search_start = search_iter;
    next_start = *start;

    while (start->charpos + len <= (wholenumber_t) src->getCLength()) {
        wholenumber_t c1 = STRING_ITER_GET_AND_ADVANCE(src, &next_start);

        if (c1 == c0) {
            wholenumber_t c2;
            *end = next_start;

            do {
                if (search_iter.charpos >= len)
                    return start->charpos;
                c1 = STRING_ITER_GET_AND_ADVANCE(src, end);
                c2 = STRING_ITER_GET_AND_ADVANCE(search, &search_iter);
            } while (c1 == c2);

            search_iter = search_start;
        }

        *start = next_start;
    }

    return -1;
}


