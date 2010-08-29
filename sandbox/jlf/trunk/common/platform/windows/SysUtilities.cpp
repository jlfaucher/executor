/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2010 Rexx Language Association. All rights reserved.    */
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
/****************************************************************************/
/* REXX Kernel                                                              */
/*                                                                          */
/* Utility Functions                                                        */
/*                                                                          */
/****************************************************************************/

#include <stdio.h>
#include <stdarg.h>

#include "Utilities.hpp"

/**
 * Encapsulation of _vsnprintf Windows implementation. 
 * The goal is to have the same behavior on all platforms. 
 *
 * @param buffer  Buffer receiving the formated output.
 * @param size    Size of buffer.
 * @param format  Format string.
 * @param args    Pointer to optional arguments
 *
 * @return Upon successful completion, return the number of bytes stored in buffer, not counting the terminating null character
 *         or a negative value if an error was encountered.
 */
int Utilities::vsnprintf(char *buffer, size_t count, const char *format, va_list args)
{
    /*
    http://msdn.microsoft.com/en-us/library/1kt27hek%28v=VS.71%29.aspx

    Return value
    _vsnprintf returns the number of bytes stored in buffer, not counting the terminating null character. 
    If the number of bytes required to store the data exceeds count, then count bytes of data are stored in buffer and a negative value is returned. 
    
    Remarks
    The _snprintf function formats and stores count or fewer characters and values (including a terminating null character that is always appended
    unless count is zero or the formatted string length is greater than or equal to count characters) in buffer.    
    */
    
    /*
    _vsnprintf behavior, assuming the buffer is 4 bytes :
            0   1   2   3
    "x"     x   \0              return value = 1
    "xx"    x   x   \0          return value = 2
    "xxx"   x   x   x   \0      return value = 3
    "xxxx"  x   x   x   x       return value = -1 (truncated, no final '\0')
    "xxxxx" x   x   x   x       return value = -1 (truncated, no final '\0')
    */
    
    if (buffer == NULL || count == 0) return -1;
    int n = _vsnprintf(buffer, count, format, args);
    buffer[count-1] = '\0'; // Unlike Unix implementation, we are not sure to have a final '\0'
    return n;
}


/**
 * Encapsulation of snprintf Windows implementation.
 * The goal is to have the same behavior on all platforms. 
 *
 * @param buffer  Buffer receiving the formated output.
 * @param size    Size of buffer.
 * @param format  Format string.
 * @param ...     Optional arguments
 *
 * @return Upon successful completion, return the number of bytes stored in buffer, not counting the terminating null character
 *         or a negative value if an error was encountered.
 */
int Utilities::snprintf(char *buffer, size_t count, const char *format, ...)
{
    va_list args;
    va_start(args, format);
    int n = Utilities::vsnprintf(buffer, count, format, args);
    va_end(args);
    return n;
}

