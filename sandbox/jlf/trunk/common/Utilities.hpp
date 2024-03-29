/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2009 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.ibm.com/developerworks/oss/CPLv1.0.htm                          */
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

#ifndef Included_Utilities
#define Included_Utilities

#include <rexx.h>
#include <sys/types.h>
#include <stdarg.h>

#ifdef __REXX64__
#define CONCURRENCY_TRACE "%16.16x %16.16x %16.16x %5.5hu%c "
#else
#define CONCURRENCY_TRACE "%8.8x %8.8x %8.8x %5.5hu%c "
#endif

#define CONCURRENCY_BUFFER_SIZE 100 // Must be enough to support CONCURRENCY_TRACE


// For concurrency trace
class RexxActivity;
class RexxActivation;
class RexxVariableDictionary;
struct ConcurrencyInfos
{
    wholenumber_t threadId;
    RexxActivity *activity;
    RexxActivation *activation;
    RexxVariableDictionary *variableDictionary;
    unsigned short reserveCount;
    char lock;
};

// Can't include RexxActivation.hpp to call the function GetConcurrencyInfos
// A pointer to this function will be passed during the initialization of the interpreter.
typedef void (*ConcurrencyInfosCollector) (struct ConcurrencyInfos &concurrencyInfos);


class Utilities
{
public:
    static int strCaselessCompare(const char *opt1, const char *opt2);
    static int memicmp(const void *opt1, const void *opt2, size_t len);
    static void strupper(char *str);
    static void strlower(char *str);
    static const char *strnchr(const char *, size_t n, char ch);
    static const char *locateCharacter(const char *s, const char *set, size_t l);
    static int vsnprintf(char *buffer, size_t count, const char *format, va_list args);
    static int snprintf(char *buffer, size_t count, const char *format, ...);
    static wholenumber_t currentThreadId(); // Could be in SysThread.hpp, but for the moment, it's here...
    static void traceConcurrency(bool);
    static bool traceConcurrency();
    static void traceParsing(bool);
    static bool traceParsing();

    // For concurrency trace
    static void SetConcurrencyInfosCollector(ConcurrencyInfosCollector);
    static void GetConcurrencyInfos(struct ConcurrencyInfos &concurrencyInfos);
};

#endif

