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

#include "RexxCore.h"
#include "ProtectedObject.hpp"
#include "TextClass.hpp"
#include "m17n/utf8proc/utf8proc.h"


/******************************************************************************/
/* REXX Kernel                                                                */
/*                                                                            */
/* Primitive RexxText Class                                                   */
/*                                                                            */
/******************************************************************************/

// singleton class instance
RexxClass *RexxText::classInstance = OREF_NULL;


void RexxText::createInstance()
{
    CLASS_CREATE(RexxText, "RexxText", RexxClass);
}

RexxObject  *RexxText::newRexx(RexxObject **init_args, size_t argCount, size_t named_argCount)
{
    RexxObject *newObj = new RexxText();
    ProtectedObject p(newObj);
    newObj->setBehaviour(((RexxClass *)this)->getInstanceBehaviour());
    if (((RexxClass *)this)->hasUninitDefined())
    {
        newObj->hasUninit();
    }
    newObj->sendMessage(OREF_INIT, init_args, argCount, named_argCount);
    return newObj;
}

void *RexxText::operator new(size_t size)
{
    return new_object(size, T_RexxText);
}

void RexxText::live(size_t liveMark)
{
    memory_mark(this->objectVariables);
}

void RexxText::liveGeneral(int reason)
{
    memory_mark_general(this->objectVariables);
}

void RexxText::flatten(RexxEnvelope *envelope)
{
    setUpFlatten(RexxText)
    flatten_reference(newThis->objectVariables, envelope);
    cleanUpFlatten
}

RexxString *RexxText::primitiveMakeString()
{
    return (RexxString *)this->sendMessage(OREF_REQUEST, OREF_STRINGSYM);
}


RexxString *RexxText::makeString()
{
    return (RexxString *)this->sendMessage(OREF_REQUEST, OREF_STRINGSYM);
}


/******************************************************************************/
/* REXX Kernel                                                                */
/*                                                                            */
/* Primitive Unicode Class                                                    */
/*                                                                            */
/******************************************************************************/

// singleton class instance
RexxClass *Unicode::classInstance = OREF_NULL;


void Unicode::createInstance()
{
    CLASS_CREATE(Unicode, "Unicode", RexxClass);
}

RexxObject  *Unicode::newRexx(RexxObject **init_args, size_t argCount, size_t named_argCount)
{
    // This class has no instance...
    reportException(Error_Unsupported_new_method, ((RexxClass *)this)->getId());
    return TheNilObject;
}

RexxObject *Unicode::copyRexx()
{
    // This class cannot be copied because it holds tons of informations about the Unicode characters...
    reportException(Error_Unsupported_copy_method, this);
    return TheNilObject;
}

void *Unicode::operator new(size_t size)
{
    return new_object(size, T_Unicode);
}

void Unicode::live(size_t liveMark)
{
    memory_mark(this->objectVariables);
}

void Unicode::liveGeneral(int reason)
{
    memory_mark_general(this->objectVariables);
}

void Unicode::flatten(RexxEnvelope *envelope)
{
    setUpFlatten(Unicode)
    flatten_reference(newThis->objectVariables, envelope);
    cleanUpFlatten
}

size_t nonNegativeInteger(RexxObject *obj, const char *errorMessage)
{
    if (obj != OREF_NULL)
    {
        RexxInteger *integer = (RexxInteger *)REQUEST_INTEGER(obj);
        if (integer != TheNilObject)
        {
            size_t value = integer->getValue();
            if (value >= 0) return value;
        }
    }
    reportException(Error_Invalid_argument_user_defined, errorMessage);
    return 0; // To avoid warning, must return something (should never reach this line)
}

/**
 * Given a pair of consecutive codepoints, return whether a grapheme break is
 * permitted between them.
 *
 * @param array An array of 3 items:
 *     codepoint1 [IN]     The first codepoint.
 *     codepoint2 [IN]     The second codepoint.
 *     state      [IN OUT] Initial value must be 0.
 *
 * @return .true if a grapheme break is permitted, .false otherwise.
 */
RexxObject *Unicode::GraphemeBreak(RexxArray *array)
{
    array = arrayArgument(array, OREF_positional, ARG_ONE);
    ProtectedObject p(array);
    utf8proc_int32_t codepoint1 = (utf8proc_int32_t)nonNegativeInteger(array->get(1), "GraphemeBreak: The first codepoint must be a non negative integer");
    utf8proc_int32_t codepoint2 = (utf8proc_int32_t)nonNegativeInteger(array->get(2), "GraphemeBreak: The second codepoint must be a non negative integer");
    utf8proc_int32_t state = (utf8proc_int32_t)nonNegativeInteger(array->get(3), "GraphemeBreak:The state must be a non negative integer");
    utf8proc_bool graphemeBreak = utf8proc_grapheme_break_stateful(codepoint1, codepoint2, &state);
    array->put(new_integer(state), 3); // Output argument
    return graphemeBreak ? TheTrueObject : TheFalseObject;
}

