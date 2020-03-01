/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2009 Rexx Language Association. All rights reserved.    */
/*                                                                            */
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
/******************************************************************************/
/* REXX Translator                                    BuiltinFunctions.h      */
/*                                                                            */
/* Builtin Function Execution Stub macros                                     */
/*                                                                            */
/******************************************************************************/

#ifndef OTPBIF_INCLUDED
#define OTPBIF_INCLUDED

void expandArgs(RexxObject **arguments, size_t argcount, size_t min, size_t max, const char *function);
RexxString *requiredStringArg(size_t position, RexxObject **arguments, size_t argcount, const char *function);
RexxString *optionalStringArg(size_t  position, RexxObject **arguments, size_t argcount, const char *function);
RexxInteger *requiredIntegerArg(size_t position, RexxObject **arguments, size_t argcount, const char *function);
RexxInteger *optionalIntegerArg(size_t position, RexxObject **arguments, size_t argcount, const char *function);
RexxObject *requiredBigIntegerArg(size_t position, RexxObject **arguments, size_t argcount, const char *function);
RexxObject *optionalBigIntegerArg(size_t position, RexxObject **arguments, size_t argcount, const char *function);

/*
x is the name of the builtin function.
n is the argument name.

#define ABBREV_MIN 2           // arg1 and arg2 are mandatory: at least 2 args
#define ABBREV_MAX 3           // arg3 is optional: at max 3 args
#define ABBREV_information 1   // arg1 is information
#define ABBREV_info        2   // arg2 is info
#define ABBREV_length      3   // arg3 length

BUILTIN(ABBREV)
{
    fix_args(ABBREV);
    RexxString *information = required_string(ABBREV, information);
    RexxString *info = required_string(ABBREV, info);
    RexxInteger *length = optional_integer(ABBREV, length);
    return information->abbrev(info, length);
}

Macro expansion:
RexxObject *builtin_function_abbrev ( RexxActivation * context, RexxObject **arguments, size_t argcount, size_t named_argcount, RexxExpressionStack *stack )
{
    expandArgs(arguments, argcount, 2, 3, CHAR_ABBREV);
    RexxString *information = requiredStringArg(argcount - 1)
    RexxString *info = requiredStringArg(argcount - 2)
    RexxInteger *length = ((argcount >= 3) ? optionalIntegerArg(argcount - 3, argcount, CHAR_ABBREV) : OREF_NULL)
}

ABBREV("Print","Pri")           ABBREV("Print","Pri",4)
argcount == 2                   argcount == 3
stack top       "Pri"           stack top       4
stack top-1     "Print"         stack top-1     "Pri"
                                stack top-2     "Print"
*/

#define fix_args(x) expandArgs(arguments, argcount, x##_MIN, x##_MAX, CHAR_##x)
#define check_args(x) expandArgs(arguments, argcount, x##_MIN, x##_MAX, CHAR_##x)

#define get_arg(x,n) arguments[x##_##n - 1]

#define required_string(x,n) requiredStringArg(x##_##n, arguments, argcount, CHAR_##x)
#define optional_string(x,n) optionalStringArg(x##_##n, arguments, argcount, CHAR_##x)

#define required_integer(x,n) requiredIntegerArg(x##_##n, arguments, argcount, CHAR_##x)
#define optional_integer(x,n) optionalIntegerArg(x##_##n, arguments, argcount, CHAR_##x)

#define required_big_integer(x,n) requiredBigIntegerArg(x##_##n, arguments, argcount, CHAR_##x)
#define optional_big_integer(x,n) optionalBigIntegerArg(x##_##n, arguments, argcount, CHAR_##x)

#define optional_argument(x,n) ((argcount >= x##_##n) ? arguments[x##_##n -1] : OREF_NULL )
#define arg_exists(x,n) ((argcount < x##_##n) ? false : arguments[x##_##n - 1] != OREF_NULL )
#define arg_omitted(x,n) ((argcount < x##_##n) ? true : arguments[x##_##n - 1] == OREF_NULL )

#define BUILTIN(x) RexxObject *builtin_function_##x ( RexxActivation * context, RexxObject **arguments, size_t argcount, size_t named_argcount, RexxExpressionStack *stack )

#define positive_integer(n,f,p) if (n <= 0) reportException(Error_Incorrect_call_positive, CHAR_##f, OREF_positional, p, n)
#define nonnegative_integer(n,f,p) if (n < 0) reportException(Error_Incorrect_call_nonnegative, CHAR_##f, OREF_positional, p, n)

#define  ALPHANUM "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
#endif
