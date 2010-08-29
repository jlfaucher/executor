/* unicode.h
 *  Copyright (C) 2001-2006, Parrot Foundation.
 *  SVN Info
 *     $Id: unicode.h 37201 2009-03-08 12:07:48Z fperrad $
 *  Overview:
 *     Unicode support header
 *  Data Structure and Algorithms:
 *  History:
 *  Notes:
 *  References:
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

#ifndef M17N_UNICODE_H_GUARD
#define M17N_UNICODE_H_GUARD

typedef unsigned char utf8_t;
typedef unsigned short utf16_t;
typedef unsigned long utf32_t;

#define UNICODE_SURROGATE_FIRST         0xD800u
#define UNICODE_SURROGATE_LAST          0xDFFFu
#define UNICODE_HIGH_SURROGATE_FIRST    0xD800u
#define UNICODE_HIGH_SURROGATE_LAST     0xDBFFu
#define UNICODE_HIGH_SURROGATE_SHIFT    10
#define UNICODE_LOW_SURROGATE_FIRST     0xDC00u
#define UNICODE_LOW_SURROGATE_LAST      0xDFFFu
#define UNICODE_LOW_SURROGATE_MASK      0x3FFu

#define UNICODE_IS_SURROGATE(c)        ((c) >= UNICODE_SURROGATE_FIRST && \
                                        (c) <= UNICODE_SURROGATE_LAST)
#define UNICODE_IS_HIGH_SURROGATE(c)   ((c) >= UNICODE_HIGH_SURROGATE_FIRST && \
                                        (c) <= UNICODE_HIGH_SURROGATE_LAST)
#define UNICODE_IS_LOW_SURROGATE(c)    ((c) >= UNICODE_LOW_SURROGATE_FIRST && \
                                        (c) <= UNICODE_LOW_SURROGATE_LAST)
#define UNICODE_IS_INVARIANT(c)        ((c) <  0x80u)

#define UNICODE_HIGH_SURROGATE(c) \
  ((((c) - 0x10000u) >> UNICODE_HIGH_SURROGATE_SHIFT) + UNICODE_HIGH_SURROGATE_FIRST)
#define UNICODE_LOW_SURROGATE(c) \
  ((((c) - 0x10000u) & UNICODE_LOW_SURROGATE_MASK) + UNICODE_LOW_SURROGATE_FIRST)
#define UNICODE_DECODE_SURROGATE(high, low) \
  ((((high) - UNICODE_HIGH_SURROGATE_FIRST) << UNICODE_HIGH_SURROGATE_SHIFT) + \
    ((low) - UNICODE_LOW_SURROGATE_FIRST) + 0x10000u)

#define UNISKIP(uv) ((uv) < 0x80    ? 1 : \
                      (uv) < 0x800   ? 2 : \
                      (uv) < 0x10000 ? 3 : 4)

#define UTF16SKIP(s) (UNICODE_IS_HIGH_SURROGATE(*(s)) ? 2 : 1)

/*

 The following table is from Unicode 3.1.

 Code Points            1st Byte  2nd Byte  3rd Byte  4th Byte

   U+0000..U+007F       00..7F
   U+0080..U+07FF       C2..DF    80..BF
   U+0800..U+0FFF       E0        A0..BF    80..BF
   U+1000..U+FFFF       E1..EF    80..BF    80..BF
  U+10000..U+3FFFF      F0        90..BF    80..BF    80..BF
  U+40000..U+FFFFF      F1..F3    80..BF    80..BF    80..BF
 U+100000..U+10FFFF     F4        80..8F    80..BF    80..BF

 */

#define UTF8_IS_START(c)                ((c) >= 0xC0u && (c) <= 0xFDu)
#define UTF8_IS_CONTINUATION(c)         ((c) >= 0x80u && (c) <= 0xBFu)
#define UTF8_IS_CONTINUED(c)            ((c) &  0x80u)

#define UTF8_START_MARK(len) (len == 1 ? 0 : (0x7Eu << (7-len)) & 0xFF)
#define UTF8_START_MASK(len) (len == 1 ? 0x7Fu : 0x1Fu >> (len-2))

#define UTF8_CONTINUATION_MARK           0x80u
#define UTF8_ACCUMULATION_SHIFT          6
#define UTF8_CONTINUATION_MASK           0x3Fu
#define UTF8_ACCUMULATE(old, new)       (((old) << UTF8_ACCUMULATION_SHIFT) | ((new) & UTF8_CONTINUATION_MASK))

extern const char m17n_utf8skip[256];

#define UTF8SKIP(s) m17n_utf8skip[(int)*(s)]

#define UTF8_MAXLEN 4
#define UTF16_MAXLEN 4

#endif /* M17N_UNICODE_H_GUARD */
