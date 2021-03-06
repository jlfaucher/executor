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
/* REXX Translator                                                            */
/*                                                                            */
/* Primitive Queue Parse Class                                                */
/*                                                                            */
/******************************************************************************/
#include <stdlib.h>
#include "RexxCore.h"
#include "StringClass.hpp"
#include "RexxActivation.hpp"
#include "RexxActivity.hpp"
#include "QueueInstruction.hpp"

RexxInstructionQueue::RexxInstructionQueue(
  RexxObject *_expression,              /* expresion to evaluate             */
  int type)                            /* top of queueing operation         */
/******************************************************************************/
/* Function:   Initialize a QUEUE instruction object                          */
/******************************************************************************/
{
    /* process the expression            */
    OrefSet(this, this->expression, _expression);
    if (type == QUEUE_LIFO)
    {
        instructionFlags |= queue_lifo;
    }
}

void RexxInstructionQueue::execute(
    RexxActivation      *context,      /* current activation context        */
    RexxExpressionStack *stack )       /* evaluation stack                  */
/****************************************************************************/
/* Function:  Execute a REXX QUEUE or PUSH instruction                      */
/****************************************************************************/
{
    RexxObject *result;                  /* expression result                 */
    RexxString *value;                   /* output value                      */

    ProtectedObject p_value;
    
    context->traceInstruction(this);     /* trace if necessary                */
    if (this->expression != OREF_NULL) /* have an expression value?         */
    {
        /* get the expression value          */
        result = this->expression->evaluate(context, stack);
        value = REQUEST_STRING(result);    /* get the string version            */
        p_value = value;
    }
    else
    {
        value =  OREF_NULLSTRING;          /* use a NULL string                 */
    }
    context->traceResult(value);         /* trace if necessary                */
                                         /* write out the line                */
    ActivityManager::currentActivity->queue(context, value, ((instructionFlags&queue_lifo) != 0) ? QUEUE_LIFO : QUEUE_FIFO);
    context->pauseInstruction();         /* do debug pause if necessary       */
}

