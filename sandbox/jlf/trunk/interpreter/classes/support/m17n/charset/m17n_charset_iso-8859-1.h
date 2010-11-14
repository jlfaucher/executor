/* iso_8859_1.h
 *  Copyright (C) 2004-2007, Parrot Foundation.
 *  SVN Info
 *     $Id: iso-8859-1.h 46064 2010-04-27 14:55:24Z petdance $
 *  Overview:
 *     This is the header for the iso_8859-1 charset functions
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

#ifndef M17N_CHARSET_ISO_8859_1_H_GUARD
#define M17N_CHARSET_ISO_8859_1_H_GUARD

#include "m17n_charset_ascii.h"

class CHARSET_ISO_8859 : public CHARSET_ASCII {
public:
    RexxString * convert(RexxString *src);
    RexxString * compose(RexxString *src);
    RexxString * decompose(RexxString *src);
    RexxString * upcase(RexxString *src, ssizeC_t start=-1, ssizeC_t length=-1);
    RexxString * downcase(RexxString *src, ssizeC_t start=-1, ssizeC_t length=-1);
    RexxString * titlecase(RexxString *src);
    RexxString * upcase_first(RexxString *src);
    RexxString * downcase_first(RexxString *src);
    RexxString * titlecase_first(RexxString *src);
    wholenumber_t validate(IRexxString *src);
    wholenumber_t is_cclass(wholenumber_t, IRexxString *src, sizeC_t offset);
    sizeC_t find_cclass(wholenumber_t, IRexxString *src, sizeC_t offset, sizeC_t count);
    sizeC_t find_not_cclass(wholenumber_t, IRexxString *src, sizeC_t offset, sizeC_t count);
    RexxString * string_from_codepoint(codepoint_t codepoint);
};

RexxString * charset_cvt_iso_8859_1_to_ascii(RexxString *src);

void m17n_charset_iso_8859_1_init();

#endif /* M17N_CHARSET_ISO_8859_1_H_GUARD */
