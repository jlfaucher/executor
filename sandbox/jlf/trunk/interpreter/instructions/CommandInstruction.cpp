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
/* Primitive Command Parse Class                                              */
/*                                                                            */
/******************************************************************************/
#include <stdlib.h>
#include "RexxCore.h"
#include "RexxActivation.hpp"
#include "CommandInstruction.hpp"


RexxInstructionCommand::RexxInstructionCommand(
    RexxObject *_expression)            /* command expression                */
/******************************************************************************/
/* Function:  Complete initialzation a command instruction object             */
/******************************************************************************/
{
                                       /* save the command expression       */
  OrefSet(this, this->expression, _expression);
}

void RexxInstructionCommand::execute(
    RexxActivation      *context,      /* current activation context        */
    RexxExpressionStack *stack )       /* evaluation stack                  */
/****************************************************************************/
/* Function:  Execute a REXX command instruction                            */
/****************************************************************************/
{
    context->traceCommand(this);         /* trace if necessary                */
                                         /* get the expression value          */
    RexxObject *result = this->expression->evaluate(context, stack);
    if (context->enableCommands())
    {
        RexxString *command = REQUEST_STRING(result);    /* force to string form              */
        /* are we tracing commands?          */
        if (context->tracingCommands())
        {
            /* then we always trace full command */
            context->traceValue((RexxObject *)command, TRACE_PREFIX_RESULT);
        }
        /* go process the command            */
        context->command(context->getAddress(), command);
    }
    else
    {
        if (result != OREF_NULL)   /* result returned?                  */
        {
            /* set the RESULT variable to the    */
            /* message return value              */
            context->setLocalVariable(OREF_RESULT, VARIABLE_RESULT, (RexxObject *)result);
            context->traceResult((RexxObject *)result);  /* trace if necessary                */
        }
        else                               /* drop the variable RESULT          */
        {
            context->dropLocalVariable(OREF_RESULT, VARIABLE_RESULT);
        }
    }
}

