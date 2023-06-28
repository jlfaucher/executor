/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2010 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.oorexx.org/license.html                                         */
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

#include <tchar.h>
#include <string>

typedef char rxcharA;
typedef wchar_t rxcharW;

typedef rxcharA *CSTRINGA;
typedef rxcharW *CSTRINGW;

#ifdef UNICODE
#pragma message ( "********** UNICODE **********" )
typedef wchar_t rxcharT;
typedef std::wstring rxstringT;
#else
#pragma message ( "********** NOT UNICODE **********" )
typedef char rxcharT;
typedef std::string rxstringT;
#endif

typedef const rxcharT *CSTRINGT;
typedef rxcharT CHART;
typedef rxcharT *PCHART;

// The arguments passed to the string functions must be character's number, not byte's number
#define RXTCHARCOUNT(byteCount) ((byteCount) / sizeof(rxcharT))
#define RXITEMCOUNT(anArray) (sizeof(anArray) / sizeof(anArray[0]))

// The arguments passed to the malloc functions must be byte's number, not character's number
#define RXTBYTECOUNT(rxcharTCount) ((rxcharTCount) * sizeof(rxcharT))
#define RXTMALLOC(rxcharTCount) (malloc((rxcharTCount) * sizeof(rxcharT)))
#define RXTLOCALALLOC(flags, rxcharTCount) (LocalAlloc(flags, (rxcharTCount) * sizeof(rxcharT)))

// Converter from rxcharA to rxcharT
#define RXCA2T(variable) rxConverter<rxcharA, rxcharT> variable##T(variable)

// Converter from rxcharT to rxcharA
#define RXCT2A(variable) rxConverter<rxcharT, rxcharA> variable##A(variable)

// Default code page. For the moment, use a global variable.
extern bool rxsetCodePage(int codepage);
extern int rxgetCodePage();

// The following functions depend on the code page selected using rxsetCodePage
extern bool rxA2W(const rxcharA *pszA, rxcharW **ppszW);
extern bool rxW2A(const rxcharW *pszW, rxcharA **ppszA);


//-----------------------------------------------------------------------------------


// Helper class to manage the conversion rxcharA <--> rxcharW
// NOTE : You must delete the strings returned by the methods xxxCopy.
// For the other methods and operators , the destructor automatically frees memory, if needed.

/* Usage :
    rxConverter<rxcharA, rxcharW> converter1 = "multi byte string";
    rxcharA *s1 = converter1.sourceCopy();      // returns a COPY of the multi byte string at each call (you must delete it at each call)
    const rxcharA *cs1 = converter1.source();   // returns directly the multi byte string, no copy (don't delete it).
    rxcharW *ws1 = converter1.targetCopy();     // convert to wide char if not yet done, and return a COPY of the wide char string at each call (you must delete it at each call).
    const rxcharW *wcs1a = converter1.target(); // convert to wide char if not yet done, and return the same wide char string at each call (don't delete it, will be automatically freed).
    const rxcharW *wcs1b = converter1;          // same as target()

    rxConverter<rxcharW, rxcharA> converter2 = L"wide char string";
    rxcharA *s2 = converter2.targetCopy();      // convert to multi byte if not yet done, and return a COPY of the multi byte string at each call (you must delete it at each call).
    const rxcharA *cs2a = converter2.target();  // convert to multi byte if not yet done, and return the same multi byte string at each call (don't delete it, will be automatically freed).
    const rxcharA *cs2b = converter2;           // same as target()
    rxcharW *wcs1 = converter2.sourceCopy();    // returns a COPY of the wide char string at each call (you must delete it at each call)
    const rxcharW *wcs2 = converter2.source();  // returns directly the wide char string, no copy (don't delete it).
*/

template <class Source, class Target>
class rxConverter
{
public:
    rxConverter() : s(NULL), t(NULL), done(false) {};
    rxConverter(const Source *string) : s(string), t(NULL), done(false) {};
    ~rxConverter() { if (t != NULL) free(t); t=NULL; };
    rxConverter<Source, Target>& operator=(const Source *string) { if (t != NULL) free(t); t = NULL; s = string; done = false; return *this; }
    operator const Target *() { return target(); };
    const Source *source() { done = true; return s; };
    const Target *target();
    Source *sourceCopy();
    Target *targetCopy();
protected:
    const Source *s;
    Target *t;
    bool done; // indicator of success/error for the last conversion
};

