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
#include "Utilities.hpp"

/**
 * Encapsulation of vsnprintf Unix implementation.
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
    http://linux.die.net/man/3/snprintf

    Return value
    Upon successful return, return the number of characters printed (not including the trailing '\0' used to end output to strings).
    The functions snprintf() do not write more than size bytes (including the trailing '\0').
    If the output was truncated due to this limit then the return value is the number of characters (not including the trailing '\0') which would have been written to the final string if enough space had been available.
    Thus, a return value of size or more means that the output was truncated. (See also below under NOTES.)
    If an output error is encountered, a negative value is returned.

    Conforming To
    The snprintf() function conform to C99.
    Concerning the return value of snprintf(), SUSv2 and C99 contradict each other:
    when snprintf() is called with size=0 then SUSv2 stipulates an unspecified return value less than 1,
    while C99 allows str to be NULL in this case, and gives the return value (as always) as the number of characters that would have been written in case the output string has been large enough.

    Notes
    The glibc implementation of the functions snprintf() conforms to the C99 standard, i.e., behaves as described above, since glibc version 2.1.
    Until glibc 2.0.6 they would return -1 when the output was truncated.
    */

    /*
    vsnprintf behavior, assuming the buffer is 4 bytes :
            0   1   2   3
    "x"     x   \0              return value = 1
    "xx"    x   x   \0          return value = 2
    "xxx"   x   x   x   \0      return value = 3
    "xxxx"  x   x   x   \0      return value = 4    <-- different from Windows
    "xxxxx" x   x   x   \0      return value = 5    <-- different from Windows
    */

    if (buffer == NULL || count == 0 || format == NULL) return -1;
    int n = ::vsnprintf(buffer, count, format, args);
    buffer[count-1] = '\0'; // Normally not needed, but...
    if (n >= count) n = -1; // The output has been truncated, return -1 to have a common behavior with Windows platform
    return n;
}


/**
 * Encapsulation of snprintf Unix implementation.
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


// Could be in SysThread.cpp, but for the moment, it's here...
wholenumber_t Utilities::currentThreadId()
{
    return (wholenumber_t)pthread_self();
}


// This indicator is used to control the display of additional informations in the trace output for concurrency.
static bool TRACE_CONCURRENCY = false;

void Utilities::traceConcurrency(bool trace)
{
    TRACE_CONCURRENCY = trace;
}


bool Utilities::traceConcurrency()
{
    // I don't put this part of code in SystemInterpreter::setupProgram
    // where RXTRACE is managed, because would be initialized too late :
    // Some mutexes/semaphores have been already used before calling setupProgram.
    static bool firstcall = true;
    if (firstcall)
    {
        firstcall = false;
        const char *rxTraceBuf = getenv("RXTRACE_CONCURRENCY");
        if (rxTraceBuf != NULL)
        {
            if (!Utilities::strCaselessCompare(rxTraceBuf, "ON"))    /* request to turn on?               */
            {
                /* turn on tracing                   */
                Utilities::traceConcurrency(true);
            }
        }
    }
    return TRACE_CONCURRENCY;
}


// This indicator is used to control the display of additional informations in the trace output while parsing.
static bool TRACE_PARSING = false;

void Utilities::traceParsing(bool trace)
{
    TRACE_PARSING = trace;
}


bool Utilities::traceParsing()
{
    static bool firstcall = true;
    if (firstcall)
    {
        firstcall = false;
        const char *rxTraceBuf = getenv("RXTRACE_PARSING");
        if (rxTraceBuf != NULL)
        {
            if (!Utilities::strCaselessCompare(rxTraceBuf, "ON"))    /* request to turn on?               */
            {
                /* turn on tracing                   */
                Utilities::traceParsing(true);
            }
        }
    }
    return TRACE_PARSING;
}

