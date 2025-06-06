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
/* Primitive Function Invocation Class                                        */
/*                                                                            */
/******************************************************************************/
#include <stdlib.h>
#include "RexxCore.h"
#include "StringClass.hpp"
#include "QueueClass.hpp"
#include "DirectoryClass.hpp"
#include "RexxActivation.hpp"
#include "RexxInstruction.hpp"
#include "ExpressionFunction.hpp"
#include "Token.hpp"
#include "StackClass.hpp"
#include "RexxActivity.hpp"
#include "ProtectedObject.hpp"

RexxExpressionFunction::RexxExpressionFunction(
    RexxString *function_name,         /* name of the function              */
    size_t      argCount,              /* count of positional arguments     */
    RexxQueue  *arglist,               /* function positional arguments     */
    size_t      namedArgCount,         /* count of named arguments     */
    RexxQueue  *namedArglist,          /* function named arguments          */
    size_t      builtinIndex,          /* index of possible built-in func   */
    bool        string )               /* string or symbol invocation       */
/******************************************************************************/
/* Function:  Create a function expression object                             */
/******************************************************************************/
{
                                         /* NOTE: the name oref needs to      */
                                         /* be filled in prior to doing any   */
                                         /* thing that might cause a gc       */
                                         /* set the default target            */
    OrefSet(this, this->functionName, function_name);

    /* save the positional argument count           */
    this->argument_count = (uint8_t)argCount;
    while (argCount > 0)               /* now copy the argument pointers    */
    {
        /* in reverse order                  */
        OrefSet(this, this->arguments[--argCount], arglist->pop());
    }

    // The named arguments are stored after the positional arguments
    // Each named argument has 2 entries : name, expression
    // named_argument_count = the number of named arguments
    this->named_argument_count = (uint8_t)namedArgCount;
    while (namedArgCount > 0)               /* now copy the argument pointers    */
    {
        /* in reverse order                  */
        --namedArgCount;
        OrefSet(this, this->arguments[this->argument_count + (2 * namedArgCount) + 1], namedArglist->pop()); // expression
        OrefSet(this, this->arguments[this->argument_count + (2 * namedArgCount) + 0], namedArglist->pop()); // name
    }

    /* set the builtin index for later   */
    /* resolution step                   */
    this->builtin_index = (uint16_t)builtinIndex;

    if (string)                          /* have a string lookup?             */
    {
        this->flags |= function_nointernal;/* do not check for internal routines*/
    }
}

void RexxExpressionFunction::resolve(
    RexxDirectory *labels)             /* current table of labels           */
/******************************************************************************/
/* Function:  Resolve a function target location                              */
/******************************************************************************/
{
    /* internal routines allowed?        */
    if (!(this->flags&function_nointernal))
    {
        if (labels != OREF_NULL)           /* have a labels table?              */
        {
                                           /* check the label table             */
            OrefSet(this, this->target, (RexxInstruction *)labels->at(this->functionName));
        }
        this->flags |= function_internal;  /* this is an internal call          */
    }
    if (this->target == OREF_NULL)     /* not found yet?                    */
    {
        /* have a builtin function?          */
        if (this->builtin_index != NO_BUILTIN)
        {
            this->flags |= function_builtin; /* this is a builtin function        */
        }
        else
        {
            this->flags |= function_external;/* have an external routine          */
        }
    }
}

void RexxExpressionFunction::live(size_t liveMark)
/******************************************************************************/
/* Function:  Normal garbage collection live marking                          */
/******************************************************************************/
{
    size_t i;                            /* loop counter                      */
    size_t count;                        /* argument count                    */

    memory_mark(this->functionName);
    memory_mark(this->target);
    for (i = 0, count = this->argument_count + (2 * this->named_argument_count); i < count; i++)
    {
        memory_mark(this->arguments[i]);
    }
}

void RexxExpressionFunction::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
    size_t i;                            /* loop counter                      */
    size_t count;                        /* argument count                    */

    memory_mark_general(this->functionName);
    memory_mark_general(this->target);
    for (i = 0, count = this->argument_count + (2 * this->named_argument_count); i < count; i++)
    {
        memory_mark_general(this->arguments[i]);
    }
}

void RexxExpressionFunction::flatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
    size_t i;                            /* loop counter                      */
    size_t count;                        /* argument count                    */

    setUpFlatten(RexxExpressionFunction)

    flatten_reference(newThis->functionName, envelope);
    flatten_reference(newThis->target, envelope);
    for (i = 0, count = this->argument_count + (2 * this->named_argument_count); i < count; i++)
    {
        flatten_reference(newThis->arguments[i], envelope);
    }

    cleanUpFlatten
}

RexxObject *RexxExpressionFunction::evaluate(
    RexxActivation      *context,      /* current activation context        */
    RexxExpressionStack *stack )       /* evaluation stack                  */
/******************************************************************************/
/* Function:  Execute a REXX function                                         */
/******************************************************************************/
{
    ProtectedObject result;              /* returned result                   */
    size_t      argcount;                /* count of positional arguments     */
    size_t      namedArgcount;           /* count of named arguments          */
    size_t      i;                       /* loop counter                      */
    size_t      stacktop;                /* top location on the stack         */

    ActivityManager::currentActivity->checkStackSpace();       /* have enough stack space?          */

    stacktop = stack->location();        /* save the stack top                */

    // Positional arguments
    argcount = this->argument_count;     /* get the argument count            */
    for (i = 0; i < argcount; i++)     /* loop through the argument list    */
    {
        /* real argument?                    */
        if (this->arguments[i] != OREF_NULL)
        {
            /* evaluate the expression           */
            result = this->arguments[i]->evaluate(context, stack);
            /* trace if necessary                */
            context->traceIntermediate(result, TRACE_PREFIX_ARGUMENT);
        }
        else
        {
            stack->push(OREF_NULL);          /* push an non-existent argument     */
                                             /* trace if necessary                */
            context->traceIntermediate(OREF_NULLSTRING, TRACE_PREFIX_ARGUMENT);
        }
    }

    // Named arguments
    namedArgcount = this->named_argument_count;
    for (i = argcount; i < argcount + (2 * namedArgcount); i+=2)
    {
        // Argument name: string literal
        RexxObject *name = this->arguments[i];
        stack->push(name); // a string
        context->traceIntermediate(name, TRACE_PREFIX_NAMED_ARGUMENT);

        // Argument expression
        RexxObject *argResult = this->arguments[i+1]->evaluate(context, stack);
        context->traceIntermediate(argResult, TRACE_PREFIX_ARGUMENT);
    }

    // More easy to work with an array of arguments (address of the first argument) than a stack of arguments (address of the last argument).
    RexxObject **_arguments = stack->arguments(argcount + (2 * namedArgcount));

    /* process various call types        */
    switch (this->flags&function_type_mask)
    {

        case function_internal:            /* need to process internal routine  */
            /* go process the internal call      */
            context->internalCall(this->functionName, this->target, _arguments, argcount, namedArgcount, result);
            break;

        case function_builtin:             /* builtin function call             */
            {
                // Check the global functions directory
                // this is actually considered part of the built-in functions, but these are
                // written in ooRexx.  The names are also case sensitive
                RoutineClass *routine = OREF_NULL;
#ifndef DISABLE_EXTENSIONS
                // Ignore the overridings if the flag function_nointernal is set
                // this->functionName should not be OREF_NULL, but just in case...
                if (!(this->flags&function_nointernal) && this->functionName != OREF_NULL) routine = (RoutineClass *)TheFunctionsDirectory->get(this->functionName);
#endif
                if (routine != OREF_NULL)
                {
                    // call the user-defined routine
                    routine->call(ActivityManager::currentActivity, this->functionName, _arguments, argcount, namedArgcount, OREF_SUBROUTINE, OREF_NULL, EXTERNALCALL, result);
                }
                else
                {
                    /* call the function                 */
                    result = (RexxObject *) (*(RexxSource::builtinTable[this->builtin_index]))(context, _arguments, argcount, namedArgcount, stack);
                }
            }
            break;

        case function_external:            /* need to call externally           */
            /* go process the internal call      */
            context->externalCall(this->functionName, _arguments, argcount, namedArgcount, OREF_FUNCTIONNAME, result);
            break;
    }
    if ((RexxObject *)result == OREF_NULL)    /* result returned?                  */
    {
        /* raise an error                    */
        if (this->functionName)
        {
            reportException(Error_Function_no_data_function, this->functionName);
        }
        else
        {
            reportException(Error_Function_no_data);  // no name => don't try to print one out...!
        }
    }
    stack->setTop(stacktop);             /* remove arguments from the stack   */
    stack->push((RexxObject *)result);   /* push onto the stack               */
                                         /* trace if necessary                */
    context->traceFunction(functionName, (RexxObject *)result);
    return(RexxObject *)result;         /* and return this to the caller     */
}

void *RexxExpressionFunction::operator new(size_t size,
    size_t   argCount)                 /* count of arguments                */
    // REMEMBER: argCount includes the count of named arguments, no need to pass a separated named_argCount
/******************************************************************************/
/* Function:  Create a new translator object                                  */
/******************************************************************************/
{
    if (argCount == 0)
    {
        // allocate with singleton item chopped off
        return new_object(size - sizeof(RexxObject *), T_FunctionCallTerm);
    }
    else
    {
        // argCount = positionalCount + (2 * namedCount)
        // Ex: (p1, p2, p3, n1:v1, n2:v2, n3:v3)
        //     positionalCount = 3
        //     namedCount = 3
        //     argCount = 3 + 2*3 = 9
        /* Get new object                    */
        return new_object(size + (argCount - 1) * sizeof(RexxObject *), T_FunctionCallTerm);
    }
}
