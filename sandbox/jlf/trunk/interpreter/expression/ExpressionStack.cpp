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
/* REXX Kernel                                                                */
/*                                                                            */
/* Primitive Expression Stack Class                                           */
/*                                                                            */
/******************************************************************************/
#include <stdlib.h>
#include "RexxCore.h"
#include "StringClass.hpp"
#include "ExpressionStack.hpp"
#include "ActivityManager.hpp"
#include "ProtectedObject.hpp"


void RexxExpressionStack::live(size_t liveMark)
/******************************************************************************/
/* Function:  Normal garbage collection live marking                          */
/******************************************************************************/
{
   RexxObject **entry;                 /* marked stack entry                */

                                       /* loop through the stack entries    */
   for (entry = this->stack; entry <= this->top; entry++)
   {
       memory_mark(*entry);              /* marking each one                  */
   }
}

void RexxExpressionStack::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
   RexxObject **entry;                 /* marked stack entry                */

   for (entry = this->stack; entry <= this->top; entry++)
   {
       memory_mark_general(*entry);      /* marking each one                  */
   }
}

void RexxExpressionStack::flatten(RexxEnvelope * envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
    setUpFlatten(RexxExpressionStack)

    size_t i;                            /* pointer for scanning stack entries*/
    size_t count;                        /* number of elements                */

    count = this->top - this->stack;     /* get the total count               */
                                         /* loop through the stack entries    */
    for (i = 0; i < count; i++)
    {
        flatten_reference(newThis->stack[i], envelope);
    }

    cleanUpFlatten
}

void RexxExpressionStack::migrate(RexxActivity *activity)
/******************************************************************************/
/* Function:  Migrate the expression stack to a new activity                  */
/******************************************************************************/
{
    RexxObject **oldFrame = stack;
    /* allocate a new frame */
    activity->allocateStackFrame(this, size);
    /* copy the enties over to the new stack. */
    memcpy(stack, oldFrame, sizeof(RexxObject *) * size);
}
