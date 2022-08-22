/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2021 Rexx Language Association. All rights reserved.    */
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

#ifndef Included_RexxText
#define Included_RexxText

#include "ObjectClass.hpp"


/******************************************************************************/
/* REXX Kernel                                                                */
/*                                                                            */
/* Primitive RexxText Class Definition                                        */
/*                                                                            */
/******************************************************************************/

// A RexxText is a RexxString by delegation, not by inheritance (don't inherit from RexxString)
class RexxText : public RexxObject
{
public:
    inline void *operator new(size_t, void *ptr) { return ptr; }
    inline void  operator delete(void *, void *) { ; }
    void *operator new(size_t);
    inline void  operator delete(void *) { ; }

    void live(size_t);
    void liveGeneral(int reason);
    void flatten(RexxEnvelope*);

    inline RexxText() { ; };
    inline RexxText(RESTORETYPE restoreType) { ; };

    RexxObject  *newRexx(RexxObject **, size_t, size_t);
    static void createInstance();
    static RexxClass *classInstance; // RexxCore.h #define TheRexxTextClass RexxText::classInstance

    RexxString *primitiveMakeString(); // needed to convert "b"~text to string when calling left("b"~text, 1)
    RexxString *makeString();          // needed to convert "b"~text to string when calling "abc"~pos("b"~text)
};


/******************************************************************************/
/* REXX Kernel                                                                */
/*                                                                            */
/* Primitive Unicode Class Definition                                         */
/*                                                                            */
/******************************************************************************/

class Unicode : public RexxObject
{
public:
    inline void *operator new(size_t, void *ptr) { return ptr; }
    inline void  operator delete(void *, void *) { ; }
    void *operator new(size_t);
    inline void  operator delete(void *) { ; }

    void live(size_t);
    void liveGeneral(int reason);
    void flatten(RexxEnvelope*);

    inline Unicode() { ; };
    inline Unicode(RESTORETYPE restoreType) { ; };

    RexxObject  *newRexx(RexxObject **, size_t, size_t);
    RexxObject  *copyRexx();
    static void createInstance();
    static RexxClass *classInstance; // RexxCore.h #define TheUnicodeClass Unicode::classInstance

    RexxString *version();
    RexxInteger *systemIsLittleEndian();
    RexxInteger *graphemeBreak(RexxArray *);

    RexxInteger *codepointCategory(RexxObject *rexxCodepoint);
    RexxInteger *codepointCombiningClass(RexxObject *rexxCodepoint);
    RexxInteger *codepointBidiClass(RexxObject *rexxCodepoint);
    RexxInteger *codepointBidiMirrored(RexxObject *rexxCodepoint);
    RexxInteger *codepointDecompositionType(RexxObject *rexxCodepoint);
    RexxInteger *codepointIgnorable(RexxObject *rexxCodepoint);
    RexxInteger *codepointControlBoundary(RexxObject *rexxCodepoint);
    RexxInteger *codepointCharWidth(RexxObject *rexxCodepoint);
    RexxInteger *codepointBoundClass(RexxObject *rexxCodepoint);
    RexxInteger *codepointToLower(RexxObject *rexxCodepoint);
    RexxInteger *codepointToUpper(RexxObject *rexxCodepoint);
    RexxInteger *codepointToTitle(RexxObject *rexxCodepoint);
    RexxInteger *codepointIsLower(RexxObject *rexxCodepoint);
    RexxInteger *codepointIsUpper(RexxObject *rexxCodepoint);
    RexxString *NFD(RexxString *str);
    RexxString *NFC(RexxString *str);
    RexxString *NFKD(RexxString *str);
    RexxString *NFKC(RexxString *str);
    RexxString *NFKC_Casefold(RexxString *str);
};

#endif
