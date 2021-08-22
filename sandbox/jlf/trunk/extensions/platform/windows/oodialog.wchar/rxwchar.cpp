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

#include <windows.h>
#include <locale.h>
#include <mbctype.h>
#include "rxwchar.hpp"


static int theCodePage = 0; // ANSI code page by default


bool rxsetCodePage(int codepage)
{
    theCodePage = codepage;
    return true;
}


int rxgetCodePage()
{
    return theCodePage;
}


bool rxA2W(const rxcharA *pszA, rxcharW **ppszW)
{
    *ppszW = NULL;

    // If input is null then just return the same.
    if (NULL == pszA)
    {
        return true; // NOERROR
    }

    size_t lengthA = strlen(pszA) + 1;
    // Determine number of wide characters to be allocated for the Unicode string.
    size_t lengthW =  MultiByteToWideChar(rxgetCodePage(), 0, pszA, (int)lengthA, NULL, 0);

    *ppszW = (rxcharW *) RXTMALLOC(lengthW + 1);
    if (NULL == *ppszW) return false; // E_OUTOFMEMORY;

    // Convert to Unicode.
    if (0 == MultiByteToWideChar(rxgetCodePage(), 0, pszA, (int)lengthA, *ppszW, (int)lengthW))
    {
        DWORD dwError = GetLastError();
        free(*ppszW);
        *ppszW = NULL;
        return false; // HRESULT_FROM_WIN32(dwError);
    }

    return true;
}


bool rxW2A(const rxcharW *pszW, rxcharA **ppszA)
{
    *ppszA = NULL;

    // If input is null then just return the same.
    if (pszW == NULL)
    {
        return true; // NOERROR
    }

    size_t lengthW = wcslen(pszW) + 1;
    // Determine number of bytes to be allocated for ANSI string.
    size_t lengthA = WideCharToMultiByte(rxgetCodePage(), 0, pszW, (int)lengthW, NULL, 0, NULL, NULL);

    *ppszA = (rxcharA *) malloc(lengthA + 1);
    if (NULL == *ppszA) return false; // E_OUTOFMEMORY;

    // Convert to ANSI.
    if (0 == WideCharToMultiByte(rxgetCodePage(), 0, pszW, (int)lengthW, *ppszA, (int)lengthA, NULL, NULL))
    {
        DWORD dwError = GetLastError();
        free(*ppszA);
        *ppszA = NULL;
        return false; // HRESULT_FROM_WIN32(dwError);
    }

    return true;
}


//-----------------------------------------------------------------------------------


const rxcharA *rxConverter<rxcharA, rxcharA>::target()
{
    done = true;
    return s; // no need of conversion
}

const rxcharW *rxConverter<rxcharA, rxcharW>::target()
{
    done = true;
    if (t != NULL) return t;
    done = rxA2W(s, &t);
    return t;
}

const rxcharA *rxConverter<rxcharW, rxcharA>::target()
{
    done = true;
    if (t != NULL) return t;
    done = rxW2A(s, &t);
    return t;
}

const rxcharW *rxConverter<rxcharW, rxcharW>::target()
{
    done = true;
    return s; // no need of conversion
}

rxcharA *rxConverter<rxcharA, rxcharA>::sourceCopy()
{
    done = true;
    if (s == NULL) return NULL;
    rxcharA *copy = _strdup(s);
    done = (copy != NULL);
    return copy;
}

rxcharA *rxConverter<rxcharA, rxcharW>::sourceCopy()
{
    done = true;
    if (s == NULL) return NULL;
    rxcharA *copy = _strdup(s);
    done = (copy != NULL);
    return copy;
}

rxcharW *rxConverter<rxcharW, rxcharA>::sourceCopy()
{
    done = true;
    if (s == NULL) return NULL;
    rxcharW *copy = _wcsdup(s);
    done = (copy != NULL);
    return copy;
}

rxcharW *rxConverter<rxcharW, rxcharW>::sourceCopy()
{
    done = true;
    if (s == NULL) return NULL;
    rxcharW *copy = _wcsdup(s);
    done = (copy != NULL);
    return copy;
}

rxcharA *rxConverter<rxcharA, rxcharA>::targetCopy()
{
    const rxcharA *value = (*this);
    if (!done) return NULL;
    if (value == NULL) return NULL;
    rxcharA *copy = _strdup(value);
    done = (copy != NULL);
    return copy;
}

rxcharW *rxConverter<rxcharA, rxcharW>::targetCopy()
{
    const rxcharW *value = (*this);
    if (!done) return NULL;
    if (value == NULL) return NULL;
    rxcharW *copy = _wcsdup(value);
    done = (copy != NULL);
    return copy;
}

rxcharA *rxConverter<rxcharW, rxcharA>::targetCopy()
{
    const rxcharA *value = (*this);
    if (!done) return NULL;
    if (value == NULL) return NULL;
    rxcharA *copy = _strdup(value);
    done = (copy != NULL);
    return copy;
}

rxcharW *rxConverter<rxcharW, rxcharW>::targetCopy()
{
    const rxcharW *value = (*this);
    if (!done) return NULL;
    if (value == NULL) return NULL;
    rxcharW *copy = _wcsdup(value);
    done = (copy != NULL);
    return copy;
}
