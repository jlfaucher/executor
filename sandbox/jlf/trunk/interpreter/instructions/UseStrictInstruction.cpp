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
/* Primitive USE STRICT instruction class                                     */
/*                                                                            */
/******************************************************************************/
#include <stdlib.h>
#include "RexxCore.h"
#include "ArrayClass.hpp"
#include "QueueClass.hpp"
#include "RexxActivation.hpp"
#include "UseStrictInstruction.hpp"
#include "ExpressionBaseVariable.hpp"


RexxInstructionUseStrict::RexxInstructionUseStrict(size_t count, bool strict, bool extraAllowed, bool autoCreate, bool named, RexxQueue *variable_list, RexxQueue *defaults)
{
    if (strict && autoCreate && named && !extraAllowed)
    {
        // use strict auto named arg
        reportException(Error_Translation_user_defined, "STRICT AUTO requires the \"...\" argument marker at the end of the argument list");
    }

    // set the variable count and the option flag
    variableCount = count;
    variableSize = extraAllowed; // we might allow an unchecked number of additional arguments
    minimumRequired = 0;         // do don't necessarily require any of these.
    strictChecking = strict;     // record if this is the strict form
    autoCreation = autoCreate;
    namedArg = named;

    // items are added to the queues in reverse order, so we pop them off and add
    // them to the end of the list as we go.
    while (count > 0)     // loop through our variable set, adding everything in.
    {
        // decrement first, so we store at the correct offset.
        count--;
        OrefSet(this, variables[count].variable, (RexxVariableBase *)variable_list->pop());
        OrefSet(this, variables[count].defaultValue, defaults->pop());

        // if this is a real variable, see if this is the last of the required ones.
        if (minimumRequired < count + 1 && variables[count].variable != OREF_NULL)
        {
            // no default value means this is a required argument, this is the min we'll accept.
            if (variables[count].defaultValue == OREF_NULL)
            {
                minimumRequired = count + 1;
            }
        }
    }
}


/**
 * The runtime, non-debug live marking routine.
 */
void RexxInstructionUseStrict::live(size_t liveMark)
{
  size_t i;                            /* loop counter                      */
  size_t count;                        /* argument count                    */

  memory_mark(this->nextInstruction);  /* must be first one marked          */
  for (i = 0, count = variableCount; i < count; i++)
  {
      memory_mark(this->variables[i].variable);
      memory_mark(this->variables[i].defaultValue);
  }
}


/**
 * The generalized live marking routine used for non-performance
 * critical marking operations.
 */
void RexxInstructionUseStrict::liveGeneral(int reason)
{
  size_t i;                            /* loop counter                      */
  size_t count;                        /* argument count                    */

                                       /* must be first one marked          */
  memory_mark_general(this->nextInstruction);
  for (i = 0, count = variableCount; i < count; i++)
  {
      memory_mark_general(this->variables[i].variable);
      memory_mark_general(this->variables[i].defaultValue);
  }
}


/**
 * The flattening routine, used for serializing object trees.
 *
 * @param envelope The envelope were's flattening into.
 */
void RexxInstructionUseStrict::flatten(RexxEnvelope *envelope)
{
  size_t i;                            /* loop counter                      */
  size_t count;                        /* argument count                    */

  setUpFlatten(RexxInstructionUseStrict)

  flatten_reference(newThis->nextInstruction, envelope);
  for (i = 0, count = variableCount; i < count; i++)
  {
      flatten_reference(newThis->variables[i].variable, envelope);
      flatten_reference(newThis->variables[i].defaultValue, envelope);
  }
  cleanUpFlatten
}


void RexxInstructionUseStrict::execute(RexxActivation *context, RexxExpressionStack *stack)
{
    if (this->namedArg) this->executeNamedArguments(context, stack);
    else this->executePositionalArguments(context, stack);
}


void RexxInstructionUseStrict::executePositionalArguments(RexxActivation *context, RexxExpressionStack *stack)
{
    context->traceInstruction(this);     // trace if necessary
    // get the argument information from the context
    RexxObject **arglist = context->getMethodArgumentList();
    size_t argcount = context->getMethodArgumentCount();
    // strict checking means we need to enforce min/max limits
    if (strictChecking)
    {
        // not enough of the required arguments?  That's an error
        if (argcount < minimumRequired)
        {
            // this is a pain, but there are different errors for method errors vs. call errors.
            if (context->inMethod())
            {
                reportException(Error_Incorrect_method_minarg, OREF_positional, minimumRequired);
            }
            else
            {
                reportException(Error_Incorrect_call_minarg, OREF_positional, context->getCallname(), minimumRequired);
            }
        }
        // potentially too many?
        if (!variableSize && argcount > variableCount)
        {
            if (context->inMethod())
            {
                reportException(Error_Incorrect_method_maxarg, OREF_positional, variableCount);
            }
            else
            {
                reportException(Error_Incorrect_call_maxarg, OREF_positional, context->getCallname(), variableCount);
            }
        }
    }

    // now we process each of the variable definitions left-to-right
    for (size_t i = 0; i < variableCount; i++)
    {
        // get our current variable.  We're allowed to skip over variables, so
        // there might not be anything here.
        RexxVariableBase *variable = variables[i].variable;
        if (variable != OREF_NULL)
        {
            // get the corresponding argument
            RexxObject *argument = getArgument(arglist, argcount, i);
            if (argument != OREF_NULL)
            {
                context->traceResult(argument);  // trace if necessary
                // assign the value
                variable->assign(context, stack, argument);
            }
            else
            {
                // grab a potential default value
                RexxObject *defaultValue = variables[i].defaultValue;

                // and omitted argument is only value if we've marked it as optional
                // by giving it a default value
                if (defaultValue != OREF_NULL)
                {
                    // evaluate the default value now
                    defaultValue = defaultValue->evaluate(context, stack);
                    context->traceResult(defaultValue);  // trace if necessary
                    // assign the value
                    variable->assign(context, stack, defaultValue);
                    stack->pop();    // remove the value from the stack
                }
                else
                {
                    // not doing strict checks, revert to old rules and drop the variable.
                    if (!strictChecking)
                    {
                        variable->drop(context);

                    }
                    else
                    {
                        if (context->inMethod())
                        {
                            reportException(Error_Incorrect_method_noarg, OREF_positional, i + 1);
                        }
                        else
                        {
                            reportException(Error_Incorrect_call_noarg, context->getCallname(), OREF_positional, i + 1);
                        }
                    }
                }
            }
        }
    }
    context->pauseInstruction();    // do debug pause if necessary
}


/**
 * Get the argument corresponding to a given argument position.
 *
 * @param arglist The argument list for the method.
 * @param count   The argument count.
 * @param target  The target argument offset.
 *
 * @return The argument corresponding to the position.  Returns OREF_NULL
 *         if the argument doesn't exist.
 */
RexxObject *RexxInstructionUseStrict::getArgument(RexxObject **arglist, size_t count, size_t target)
{
    // is this beyond what we've been provided with?
    if (target + 1 > count)
    {
        return OREF_NULL;
    }
    // return the target item
    return arglist[target];
}


void RexxInstructionUseStrict::executeNamedArguments(RexxActivation *context, RexxExpressionStack *stack)
{
    context->traceInstruction(this);     // trace if necessary
    // get the argument information from the context
    RexxObject **arglist = context->getMethodArgumentList();
    size_t argcount = context->getMethodArgumentCount();
    size_t named_argcount = 0;
    if (arglist != OREF_NULL) arglist[argcount]->unsignedNumberValue(named_argcount);

    // strict checking means we need to enforce min/max limits
    if (strictChecking)
    {
        // not enough of the required arguments?  That's an error
        if (named_argcount < minimumRequired)
        {
            if (context->inMethod())
            {
                reportException(Error_Incorrect_method_minarg, OREF_positional, minimumRequired);
            }
            else
            {
                reportException(Error_Incorrect_call_minarg, OREF_positional, context->getCallname(), minimumRequired);
            }
        }
        // potentially too many?
        if (!variableSize && named_argcount > variableCount)
        {
            if (context->inMethod())
            {
                reportException(Error_Incorrect_method_maxarg, OREF_positional, variableCount);
            }
            else
            {
                reportException(Error_Incorrect_call_maxarg, OREF_positional, context->getCallname(), variableCount);
            }
        }
    }

    // Helper storage to associate the values passed by the caller to the expected arguments declared in the USE instruction
    NamedArguments namedArguments(this->variableCount);

    // Iterate over the named arguments declared by the callee with the instruction USE NAMED ARG.
    // Collect their names.
    for (size_t i = 0; i < this->variableCount; i++)
    {
        RexxVariableBase *variable = this->variables[i].variable;
        namedArguments[i].name = variable->getName()->getStringData();
    }

    // Iterate over the named arguments passed by the caller, match them with the names declared by the callee.
    // In case of additional argument not declared by the callee (no match):
    // - If strict without ellipsis (...) then an error is raised by the function namedArgument
    // - otherwise if mode auto then a variable is created.
    for (size_t i= argcount + 1; i < (argcount + 1 + (2 * named_argcount)); i+=2)
    {
        RexxString *argName = (RexxString *)arglist[i];
        RexxObject *argValue = arglist[i+1];
        bool match = namedArgument(argName, argValue, namedArguments, this->strictChecking && !this->variableSize);
        if (!match && this->autoCreation)
        {
            context->traceResult(argValue); // trace if necessary
            RexxVariableBase *retriever = RexxVariableDictionary::getVariableRetriever(argName);
            retriever->assign(context, stack, argValue);
        }
    }

    // Now that we have matched each named argument of the caller, we can decide if a default value on callee side is needed.
    // There is no evaluation of a default value when a value has been provided by the caller.
    // The order of evaluation is the order of declaration in USE NAMED ARG (left-to-right).
    // The automatic variables are already created and can be used during the evaluation of a default value.
    for (size_t i=0;  i < this->variableCount; i++)
    {
        RexxVariableBase *variable = this->variables[i].variable;
        NamedArgument &namedArgument = namedArguments[i];
        if (namedArgument.assigned)
        {
            RexxObject *argValue = namedArgument.value;
            context->traceResult(argValue); // trace if necessary
            variable->assign(context, stack, argValue);
        }
        else
        {
            // grab a potential default value
            RexxObject *defaultValue = this->variables[i].defaultValue;

            // and omitted argument is only value if we've marked it as optional
            // by giving it a default value
            if (defaultValue != OREF_NULL)
            {
                // evaluate the default value now
                defaultValue = defaultValue->evaluate(context, stack);
                context->traceResult(defaultValue);  // trace if necessary
                // assign the value
                variable->assign(context, stack, defaultValue);
                stack->pop();    // remove the value from the stack
            }
            else
            {
                if (!this->strictChecking)
                {
                    // not doing strict checks, revert to old rules and drop the variable.
                    variable->drop(context);

                }
                else
                {
                    if (context->inMethod())
                    {
                        reportException(Error_Incorrect_method_noarg, OREF_positional, variable->getName());
                    }
                    else
                    {
                        reportException(Error_Incorrect_call_noarg, context->getCallname(), OREF_positional, variable->getName());
                    }
                }
            }
        }
    }

    context->pauseInstruction();    // do debug pause if necessary
}


/*============================================================================*/
/* Named argument helpers for internal methods                                */
/*============================================================================*/

/*
Store the value of the named argument in the right box, if recognized (abbreviation supported)
Assumption: you will not call this helper with the same name twice, because once a name has been matched, it is skipped.
Example:
    // USE NAMED ARG ITEM, INDEX=2, MAXDEPTH=10
    NamedArguments namedArguments(3);
    namedArguments[0] = NamedArgument("ITEM", 2, OREF_NULL);        // At least 2 characters, no default value
    namedArguments[1] = NamedArgument("INDEX", 2, IntegerZero);     // At least 2 characters, default value = 0
    namedArguments[2] = NamedArgument("MAXDEPTH", 1, IntegerTen);   // At least 1 character, default value = 10
    // For each named argument passed by the caller
    namedArgument(name1, value1, namedArguments);
    namedArgument(name2, value2, namedArguments);
    namedArgument(name3, value3, namedArguments);
*/
bool namedArgument(RexxString *name, RexxObject *value, NamedArguments &expectedNamedArguments, bool strict)
{
    if (name == OREF_NULL) return false;

    // The logic is similar to RexxString::abbrev, but here I avoid to use strlen.
    // For a given expected argument name, there is only one loop over the characters, which stops as soon as possible.
    // So, passing a named argument like N:value where the expected argument name is "NAMEDPARAMETERS" with abbrev=1
    // should be *almost* as efficient as testing if the first character is equal to "N".
    // (this kind of test is done in RexxObject::run: testing only the first character and ignoring the rest of the characters)

    // There is no order for the named argument, so try all the expected names
    for (size_t i=0; i < expectedNamedArguments.count; i++)
    {
        const char *nameIterator = name->getStringData();
        const char *expectedNameIterator = expectedNamedArguments[i].name;

        if (expectedNamedArguments[i].assigned) continue; // Already matched

        size_t minimumLength = expectedNamedArguments[i].minimumLength;
        while(1)
        {
            if (minimumLength > 0)
            {
                // Checking the mandatory characters
                if (*nameIterator != *expectedNameIterator) break; // no match
                if (*nameIterator == '\0')
                {
                    // good, the name matches an expected argument name
                    expectedNamedArguments[i].value = value;
                    expectedNamedArguments[i].assigned = true;
                    return true;
                }
                minimumLength--;
            }
            else
            {
                // Checking the optional characters
                if (*nameIterator == '\0')
                {
                    // good, the name matches an expected argument name
                    expectedNamedArguments[i].value = value;
                    expectedNamedArguments[i].assigned = true;
                    return true;
                }
                if (*nameIterator != *expectedNameIterator) break; // no match
            }
            nameIterator++;
            expectedNameIterator++;
        }
    }
    // The name did not match an expected argument name
    if (strict) reportException(Error_Invalid_argument_general, OREF_named, name, "is not an expected argument name");
    return false;
}

