/*
 * Copyright (C) 2005-2007, Parrot Foundation.
 */

/* cclass.h
*
* $Id: cclass.h 37201 2009-03-08 12:07:48Z fperrad $
*
*   m17n character classes
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

#ifndef M17N_CCLASS_H_GUARD
#define M17N_CCLASS_H_GUARD

/* &gen_from_enum(cclass.pasm) subst(s/enum_cclass_(\w+)/uc("CCLASS_$1")/e) */
typedef enum {                           /* ASCII characters matching this class: */
enum_cclass_any = 0xffff,                /* all */
enum_cclass_none = 0x0000,               /* none */
enum_cclass_uppercase = 0x0001,          /* A-Z */
enum_cclass_lowercase = 0x0002,          /* a-z */
enum_cclass_alphabetic = 0x0004,         /* a-z, A-Z */
enum_cclass_numeric = 0x0008,            /* 0-9 */
enum_cclass_hexadecimal = 0x0010,        /* 0-9, a-f, A-F */
enum_cclass_whitespace = 0x0020,         /* ' ', '\f', '\n', '\r', '\t', '\v' */
enum_cclass_printing = 0x0040,           /* any printable character including space */
enum_cclass_graphical = 0x0080,          /* any printable character except space */
enum_cclass_blank = 0x0100,              /* ' ', '\t' */
enum_cclass_control = 0x0200,            /* control characters */
enum_cclass_punctuation = 0x0400,        /* all except ' ', a-z, A-Z, 0-9 */
enum_cclass_alphanumeric = 0x0800,       /* a-z, A-Z, 0-9 */
enum_cclass_newline = 0x1000,            /* '\n', '\r' */
enum_cclass_word = 0x2000                /* a-z, A-Z, 0-9, '_'*/
} M17N_CCLASS_FLAGS;
/* &end_gen */

#endif /* M17N_CCLASS_H_GUARD */
