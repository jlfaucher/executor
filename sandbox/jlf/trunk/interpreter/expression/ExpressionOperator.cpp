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
/* Primitive Operator Parse Class                                             */
/*                                                                            */
/******************************************************************************/
#include <stdlib.h>
#include "RexxCore.h"
#include "RexxActivation.hpp"
#include "ExpressionOperator.hpp"

/*
See also :
RexxObject::operatorMethods
RexxInteger::operatorMethods
RexxNumberString::operatorMethods
RexxString::operatorMethods

can't be an array of RexxString* because the global names are not yet initialized when this array is initialized.
so this is an array of pointers to the global names, hence the RexxString** declaration...
*/
RexxString **RexxExpressionOperator::operatorNames[] =
{
    OREF_NULL,          // First entry not used. See Token.hpp, the indexes start at 1 : #define OPERATOR_PLUS  1
    &OREF_PLUS,
    &OREF_SUBTRACT,
    &OREF_MULTIPLY,
    &OREF_DIVIDE,
    &OREF_INTDIV,
    &OREF_REMAINDER,
    &OREF_POWER,
    &OREF_NULLSTRING,
    &OREF_CONCATENATE,
    &OREF_BLANK,
    &OREF_EQUAL,
    &OREF_BACKSLASH_EQUAL,
    &OREF_GREATERTHAN,
    &OREF_BACKSLASH_GREATERTHAN,
    &OREF_LESSTHAN,
    &OREF_BACKSLASH_LESSTHAN,
    &OREF_GREATERTHAN_EQUAL,
    &OREF_LESSTHAN_EQUAL,
    &OREF_STRICT_EQUAL,
    &OREF_STRICT_BACKSLASH_EQUAL,
    &OREF_STRICT_GREATERTHAN,
    &OREF_STRICT_BACKSLASH_GREATERTHAN,
    &OREF_STRICT_LESSTHAN,
    &OREF_STRICT_BACKSLASH_LESSTHAN,
    &OREF_STRICT_GREATERTHAN_EQUAL,
    &OREF_STRICT_LESSTHAN_EQUAL,
    &OREF_LESSTHAN_GREATERTHAN,
    &OREF_GREATERTHAN_LESSTHAN,
    &OREF_AND,
    &OREF_OR,
    &OREF_XOR,
    &OREF_BACKSLASH
};


// If msgname is the name of an operator, then return the index of this operator, otherwise return 0
int RexxExpressionOperator::operatorIndex(RexxString *msgname)
{
    const char *name = msgname->getStringData();
    size_t count = sizeof operatorNames / sizeof operatorNames[0];
    for (size_t i=1; i <= count; i++)
    {
        RexxString *operatorName = *(operatorNames[i]);
        if (operatorName->strCompare(name) == true) return i;
    }
    return 0;
}

RexxExpressionOperator::RexxExpressionOperator(
    int         op,                    /* operator index                    */
    RexxObject *left,                  /* left expression objects           */
    RexxObject *right)                 /* right expression objects          */
/******************************************************************************/
/* Function:  Initialize a translator operator object                         */
/******************************************************************************/
{
                                       /* just fill in the three terms      */
  this->oper = op;
  OrefSet(this, this->left_term, left);
  OrefSet(this, this->right_term, right);
}


RexxObject *RexxBinaryOperator::evaluate(
    RexxActivation      *context,      /* current activation context        */
    RexxExpressionStack *stack )       /* evaluation stack                  */
/******************************************************************************/
/* Function:  Execute a REXX binary operator                                  */
/******************************************************************************/
{
    /* evaluate the target               */
    RexxObject *left = this->left_term->evaluate(context, stack);
    /* evaluate the right term           */
    RexxObject *right = this->right_term->evaluate(context, stack);

    // To optimize... probably by managing a table of overriden operators
    {
        RexxString *operatorName = *(operatorNames[this->oper]);
        ProtectedObject result;
        const size_t argcount = 2;
        RexxActivation::overridableFunctionCall(operatorName, argcount, stack->arguments(argcount), result);
        if (result != OREF_NULL)
        {
            stack->operatorResult(result); // replace top two stack elements with result
            return result;
        }
    }

    /* evaluate the message              */
    RexxObject *result = callOperatorMethod(left, this->oper, right);
    /* replace top two stack elements    */
    stack->operatorResult(result);       /* with this one                     */
                                         /* trace if necessary                */
    context->traceOperator(operatorName()->getStringData(), result);
    return result;                       /* return the result                 */
}

RexxObject *RexxUnaryOperator::evaluate(
    RexxActivation      *context,      /* current activation context        */
    RexxExpressionStack *stack )       /* evaluation stack                  */
/******************************************************************************/
/* Function:  Execute a REXX prefix operator                                  */
/******************************************************************************/
{
    /* evaluate the target               */
    RexxObject *term = this->left_term->evaluate(context, stack);

    // To optimize... probably by managing a table of overriden operators
    {
        RexxString *operatorName = *(operatorNames[this->oper]);
        ProtectedObject result;
        const size_t argcount = 1;
        RexxActivation::overridableFunctionCall(operatorName, argcount, stack->arguments(argcount), result);
        if (result != OREF_NULL)
        {
            stack->prefixResult(result); // replace the top element with result
            return result;
        }
    }

    /* process this directly             */
    RexxObject *result = callOperatorMethod(term, this->oper, OREF_NULL);
    stack->prefixResult(result);         /* replace the top element           */
                                         /* trace if necessary                */
    context->tracePrefix(operatorName()->getStringData(), result);
    return result;                       /* return the result                 */
}

void RexxExpressionOperator::live(size_t liveMark)
/******************************************************************************/
/* Function:  Normal garbage collection live marking                          */
/******************************************************************************/
{
  memory_mark(this->left_term);
  memory_mark(this->right_term);
}

void RexxExpressionOperator::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
  memory_mark_general(this->left_term);
  memory_mark_general(this->right_term);
}

void RexxExpressionOperator::flatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
   setUpFlatten(RexxExpressionOperator)

   flatten_reference(newThis->left_term, envelope);
   flatten_reference(newThis->right_term, envelope);

   cleanUpFlatten
}


void *RexxUnaryOperator::operator new(size_t size)
/******************************************************************************/
/* Function:  Create a new translator object                                  */
/******************************************************************************/
{
                                       /* Get new object                    */
    return new_object(size, T_UnaryOperatorTerm);
}

void *RexxBinaryOperator::operator new(size_t size)
/******************************************************************************/
/* Function:  Create a new translator object                                  */
/******************************************************************************/
{
                                       /* Get new object                    */
    return new_object(size, T_BinaryOperatorTerm);
}

