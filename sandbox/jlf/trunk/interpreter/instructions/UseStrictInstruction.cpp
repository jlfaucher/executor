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
#include <algorithm>

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

        if (this->strictChecking)
        {
            if (this->namedArg)
            {
                if (variables[count].defaultValue == OREF_NULL) minimumRequired++;
            }
            else
            {
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
    }

    if (this->namedArg) this->checkNamedArguments();
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
    size_t named_argcount = context->getMethodNamedArgumentCount();

    // strict checking means we need to enforce min/max limits
    if (strictChecking)
    {
        // not enough of the required arguments?  That's an error
        if (named_argcount < minimumRequired)
        {
            if (context->inMethod())
            {
                reportException(Error_Incorrect_method_minarg, OREF_named, minimumRequired);
            }
            else
            {
                reportException(Error_Incorrect_call_minarg, OREF_named, context->getCallname(), minimumRequired);
            }
        }
        // potentially too many?
        if (!variableSize && named_argcount > variableCount)
        {
            if (context->inMethod())
            {
                reportException(Error_Incorrect_method_maxarg, OREF_named, variableCount);
            }
            else
            {
                reportException(Error_Incorrect_call_maxarg, OREF_named, context->getCallname(), variableCount);
            }
        }
    }

    // Helper storage to associate the values passed by the caller to the expected arguments declared in the USE instruction
    NamedArguments expectedNamedArguments(this->variableCount);

    // Iterate over the named arguments declared by the callee with the instruction USE NAMED ARG.
    // Collect their names.
    for (size_t i = 0; i < this->variableCount; i++)
    {
        // Remember: code at risk! I don't use the constructor, and that could bring troubles
        // as I had when I added nameLength and forgot to put a value here...
        RexxVariableBase *variable = this->variables[i].variable;
        expectedNamedArguments[i].name = variable->getName()->getStringData();
        expectedNamedArguments[i].nameLength = variable->getName()->getLength();
    }

    // Iterate over the named arguments passed by the caller, match them with the names declared by the callee.
    // In case of additional argument not declared by the callee (no match):
    // - If strict without ellipsis (...) then an error is raised
    // - otherwise if mode auto then a variable is created.
    // - otherwise the additional argument is ignored
    for (size_t i = argcount; i < (argcount + (2 * named_argcount)); i+=2)
    {
        RexxString *argName = (RexxString *)arglist[i];
        RexxObject *argValue = arglist[i+1];
        bool matched = expectedNamedArguments.match(argName, argValue, this->strictChecking && !this->variableSize);
        if (!matched && this->autoCreation)
        {
            context->traceResult(argValue); // trace if necessary
            RexxVariableBase *retriever = OREF_NULL;
            if (argName != OREF_NULL) retriever = RexxVariableDictionary::getVariableRetriever(argName);
            if (retriever == OREF_NULL || argName->getChar(0) == '.' || isdigit((int)argName->getChar(0)))
            {
                RexxString *error = argName->concatToCstring("Expected a symbol for the named argument name; found \"");
                ProtectedObject p(error);
                error = error->concatWithCstring("\"");
                p = error;
                reportException(Error_Symbol_expected_user_defined, error);
            }
            // a variable having already a value is not overwritten by an auto named argument
            if (!retriever->exists(context)) retriever->assign(context, stack, argValue);
        }
    }

    // Now that we have matched each named argument of the caller, we can decide if a default value on callee side is needed.
    // There is no evaluation of a default value when a value has been provided by the caller.
    // The order of evaluation is the order of declaration in USE NAMED ARG (left-to-right).
    // The automatic variables are already created and can be used during the evaluation of a default value.
    for (size_t i = 0;  i < this->variableCount; i++)
    {
        RexxVariableBase *variable = this->variables[i].variable;
        NamedArgument &namedArgument = expectedNamedArguments[i];
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
                        reportException(Error_Incorrect_method_noarg, OREF_named, variable->getName());
                    }
                    else
                    {
                        reportException(Error_Incorrect_call_noarg, context->getCallname(), OREF_named, variable->getName());
                    }
                }
            }
        }
    }

    context->pauseInstruction();    // do debug pause if necessary
}


// Helper to check that the argument names are distinct from each other.
// This check is made at parse_time, not at run_time.
void RexxInstructionUseStrict::checkNamedArguments()
{
    if (this->variableCount < 2) return; // 0 or 1 name argument, nothing to check

    // Helper storage to detect the collisions of names
    NamedArguments expectedNamedArguments(this->variableCount);

    // Iterate over the named arguments declared by the callee with the instruction USE NAMED ARG.
    // Collect their names.
    for (size_t i = 0; i < this->variableCount; i++)
    {
        // Remember: code at risk! I don't use the constructor, and that could bring troubles
        // as I had when I added nameLength and forgot to put a value here...
        RexxVariableBase *variable = this->variables[i].variable;
        expectedNamedArguments[i].name = variable->getName()->getStringData();
        expectedNamedArguments[i].nameLength = variable->getName()->getLength();
    }

    // Iterate over the collected named arguments, and check each one with all the followings.
    // If there is a match (other than with a stem name) then an error is raised : the names are not unique
    // Examples:
    // {use named arg n, n}
    for (size_t i = 0; i < this->variableCount; i++)
    {
        bool matched = expectedNamedArguments.match(expectedNamedArguments[i].name, expectedNamedArguments[i].nameLength, OREF_NULL, false, i+1, /*parse_time*/ true);
        // if we reach here with match==true, it's a match that doesn't raise an error (typically a match with a stem name).
        if (matched) continue; // just to be explicit : here, a matched name is not an error
    }
}


/*============================================================================*/
/* Named argument helpers for internal methods                                */
/*============================================================================*/

void NamedArguments::match(RexxObject **namedArglist, size_t namedArgCount, bool strict, bool extraAllowed, size_t minimumRequired)
{
    // strict checking means we need to enforce min/max limits
    if (strict)
    {
        // not enough of the required arguments?  That's an error
        if (namedArgCount < minimumRequired)
        {
		    reportException(Error_Incorrect_method_minarg, OREF_named, minimumRequired);
        }
        // potentially too many?
        if (!extraAllowed && namedArgCount > this->count)
        {
            reportException(Error_Incorrect_method_maxarg, OREF_named, this->count);
        }
    }

    // Iterate over the named arguments passed by the caller, match them with the names declared by the callee.
    // In case of additional argument not declared by the callee (no match):
    // - If strict and not extraAllowed then an error is raised
    // - otherwise the additional argument is ignored.
    for (size_t i= 0; i < (2 * namedArgCount); i+=2)
    {
        RexxString *argName = (RexxString *)namedArglist[i];
        RexxObject *argValue = namedArglist[i+1];
        this->match(argName, argValue, strict && !extraAllowed);
    }

    // Now that we have matched each named argument of the caller, we can check if some mandatory arguments are missing.
    if  (strict)
    {
        for (size_t i = 0;  i < this->count; i++)
        {
            NamedArgument &namedArgument = (*this)[i];
            if (!namedArgument.assigned && namedArgument.value == OREF_NULL)
            {
                reportException(Error_Incorrect_method_noarg, OREF_named, namedArgument.name);
            }
        }
    }
}


/*
Store the value of the named argument in the right box, if recognized.
Assumption: you will not call this helper with the same name twice, because once a name has been matched, it is skipped.
Example:
    // USE NAMED ARG ITEM, INDEX=0, MAXDEPTH=10
    NamedArguments namedArguments(3);
    namedArguments[0] = NamedArgument("ITEM", OREF_NULL);        // No default value
    namedArguments[1] = NamedArgument("INDEX", IntegerZero);     // Default value = 0
    namedArguments[2] = NamedArgument("MAXDEPTH", IntegerTen);   // Default value = 10
    // For each named argument passed by the caller
    namedArguments.match(name1, strlen(name1), value1);
    namedArguments.match(name2, strlen(name2), value2);
    namedArguments.match(name3, strlen(name3), value3);
*/

bool NamedArguments::match(RexxString *name, RexxObject *value, bool strict, size_t from, bool parse_time)
{
    if (name == NULL) return false;
    return this->match(name->getStringData(), name->getLength(), value, strict, from, parse_time);
}

bool NamedArguments::match(const char *name, size_t nameLength, RexxObject *value, bool strict, size_t from, bool parse_time)
{
    if (name == NULL) return false;

    // There is no order for the named argument, so try all the expected names.
    // At parse_time, called for the instruction use named arg:
    //     'from' will be the index+1 of the current name being checked for collision.
    //     Ex: for "use named arg a,b,c" will be called for 'a' (check ab ac) and for 'b' (check bc)
    // At run_time, called for the list of named arguments passed by the caller:
    //     'from' will be always 0. Ex: for "f(b:1, d:3)" will be called for 'b' (check ba bb) and 'd' (check da db dc)

    size_t i = 0;
    bool matched = false;
    for (i = from; i < this->count; i++)
    {
        matched = NamedArguments::checkNameMatching(name, nameLength, i, parse_time);
        if (matched)
        {
            if (value != OREF_NULL) this->namedArguments[i].value = value;
            this->namedArguments[i].assigned = true;
            return true;
        }
    }

    // The name did not match an expected argument name
    if (strict)
    {
	    RexxString *rexxname = new_string(name);
	    ProtectedObject p(rexxname);
        reportException(Error_Invalid_argument_general, OREF_named, rexxname, "is not an expected argument name");
    }
    return false;
}

void nameCollision(const char *name)
{
    char buffer[256];

    Utilities::snprintf(buffer, sizeof buffer - 1, "Use named arg: The name '%s' is declared more than once", name);
    reportException(Error_Translation_user_defined, buffer);
}

bool NamedArguments::checkNameMatching(const char *name, size_t nameLen, size_t i, bool parse_time)
{
    if (this->namedArguments[i].assigned) return false; // Already matched (assumption: you will not call this helper with the same name twice)
    const char *expectedName = this->namedArguments[i].name;
    bool matched = (strcmp(name, expectedName) == 0);
    if (matched && parse_time) nameCollision(name);
    return matched;
}
