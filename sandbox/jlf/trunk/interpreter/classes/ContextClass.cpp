/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2009 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.ibm.com/developerworks/oss/CPLv1.0.htm                          */
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
/* Primitive Rexx execution context                                           */
/*                                                                            */
/******************************************************************************/
#include "RexxCore.h"
#include "ContextClass.hpp"
#include "RexxActivation.hpp"
#include "SupplierClass.hpp"
#include "DirectoryClass.hpp"

RexxClass *RexxContext::classInstance = OREF_NULL;   // singleton class instance

/**
 * Create initial bootstrap objects
 */
void RexxContext::createInstance()
{
    CLASS_CREATE(RexxContext, "RexxContext", RexxClass);
}


/**
 * Allocate a new RexxContext object
 *
 * @param size   The size of the object.
 *
 * @return The newly allocated object.
 */
void *RexxContext::operator new(size_t size)
{
    /* Get new object                    */
    return new_object(size, T_RexxContext);
}


/**
 * Constructor for a RexxContext object.
 *
 * @param a      The activation we're attached to.
 */
RexxContext::RexxContext(RexxActivation *a)
{
    activation = a;
}


/**
 * The Rexx accessible class NEW method.  This raises an
 * error because RexxContext objects can only be created
 * by the internal interpreter.
 *
 * @param args   The NEW args
 * @param argc   The count of arguments
 *
 * @return Never returns.
 */
RexxObject *RexxContext::newRexx(RexxObject **args, size_t argc, size_t named_argc)
{
    // we do not allow these to be allocated from Rexx code...
    reportException(Error_Unsupported_new_method, ((RexxClass *)this)->getId());
    return TheNilObject;
}


void RexxContext::live(size_t liveMark)
/******************************************************************************/
/* Function:  Normal garbage collection live marking                          */
/******************************************************************************/
{
    memory_mark(this->objectVariables);
    memory_mark(this->activation);
}

void RexxContext::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
    memory_mark_general(this->objectVariables);
    memory_mark_general(this->activation);
}

void RexxContext::flatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
  setUpFlatten(RexxContext)

  // jlf : todo... flatten or not flatten ?
  //flatten_reference(newThis->objectVariables, envelope);
  newThis->objectVariables = OREF_NULL;
  newThis->activation = OREF_NULL;   // this never should be getting flattened, so sever the connection

  cleanUpFlatten
}


/**
 * An override for the copy method to keep RexxContext
 * objects from being copied.
 *
 * @return Never returns.
 */
RexxObject *RexxContext::copyRexx()
{
    // we do not allow these to be allocated from Rexx code...
    reportException(Error_Unsupported_copy_method, this);
    return TheNilObject;
}


/**
 * Check that the backing RexxActivation is still available.
 */
void RexxContext::checkValid()
{
    if (activation == OREF_NULL)
    {
        reportException(Error_Execution_context_not_active);
    }
}


/**
 * Return the package object for the code that's currently
 * executing.
 *
 * @return The package instance.
 */
PackageClass *RexxContext::getPackage()
{
    checkValid();
    return activation->getPackage();
}


/**
 * Return the current digits setting for the running context
 *
 * @return The current digits value
 */
RexxObject *RexxContext::getDigits()
{
    checkValid();
    return new_integer(activation->digits());
}


/**
 * Return the current digits propagate setting for the running context
 *
 * @return The current digits propagate value
 */
RexxObject *RexxContext::getDigitsPropagate()
{
    checkValid();
    return activation->propagateNumericSettings() ? TheTrueObject : TheFalseObject;
}


/**
 * Return the current fuzz setting for the running context
 *
 * @return The current fuzz value
 */
RexxObject *RexxContext::getFuzz()
{
    checkValid();
    return new_integer(activation->fuzz());
}


/**
 * Return the current form setting for the running context
 *
 * @return The current form value
 */
RexxObject *RexxContext::getForm()
{
    checkValid();
    return activation->form() == Numerics::FORM_SCIENTIFIC ? OREF_SCIENTIFIC : OREF_ENGINEERING;
}


/**
 * Return a supplier for all of the variables in the current
 * context.
 *
 * @return A supplier object for iterating over the variables
 */
RexxObject *RexxContext::getVariables()
{
    checkValid();
    return activation->getAllLocalVariables();
}


/**
 * Return the executable backing the current context
 *
 * @return The executable object (either a method or routine)
 */
RexxObject *RexxContext::getExecutable()
{
    checkValid();
    return activation->getExecutable();
}


/**
 * Return the positional arguments used to invoke the current context
 *
 * @return The array of positional arguments
 */
RexxObject *RexxContext::getArgs()
{
    checkValid();
    RexxObject **arglist = activation->getMethodArgumentList();
    size_t size = activation->getMethodArgumentCount();
    return new (size, arglist) RexxArray;
}


/**
 * Return the named arguments used to invoke the current context
 *
 * @return The directory of named arguments
 */
RexxObject *RexxContext::getNamedArgs()
{
    checkValid();
    RexxObject **arglist = activation->getMethodArgumentList();
    if (arglist == OREF_NULL) return new_directory(); // Empty directory

    size_t argcount = activation->getMethodArgumentCount();
    size_t named_argcount = activation->getMethodNamedArgumentCount();;

    if (named_argcount == 0) return new_directory(); // Empty directory

    // Now we are sure to have a directory on return (and not OREF_NULL)
    return RexxDirectory::fromIndexItemArray(arglist + argcount, named_argcount);
}


/**
 * Set the positional & named arguments used to invoke the current context
 */
RexxObject *RexxContext::setArgs(RexxObject *positionalArguments,
                                 /* named arguments*/ RexxObject **named_arglist, size_t named_argcount)
{
    checkValid();

    RexxArray *positionalArgumentsArray = arrayArgument(positionalArguments, OREF_positional, ARG_ONE);
    ProtectedObject p1(positionalArgumentsArray);

    // use strict named arg namedArguments=.NIL
    NamedArguments expectedNamedArguments(1); // At most, one named argument
    expectedNamedArguments[0] = NamedArgument("NAMEDARGUMENTS", TheNilObject); // Default value = .NIL
    expectedNamedArguments.match(named_arglist, named_argcount, /*strict*/ true, /*extraAllowed*/ false);

    ProtectedObject p2;
    RexxDirectory *namedArgumentsDirectory = (RexxDirectory *)expectedNamedArguments[0].value;
    if (namedArgumentsDirectory != TheNilObject)
    {
        namedArgumentsDirectory = namedArgumentsDirectory->requestDirectory();
        p2 = namedArgumentsDirectory;
        if (namedArgumentsDirectory == TheNilObject)
        {
            reportException(Error_Execution_user_defined , "SETARGS namedArguments must be a directory or NIL");
        }
    }

    activation->setArguments(positionalArgumentsArray, namedArgumentsDirectory);
    return OREF_NULL; // no return value
}


/**
 * Return the current executable condition information
 *
 * @return The condition information
 */
RexxObject *RexxContext::getCondition()
{
    checkValid();
                                       /* get current trapped condition     */
    RexxObject *conditionobj = activation->getConditionObj();
    return conditionobj == OREF_NULL ? TheNilObject : conditionobj->copy();
}


/**
 * Return the execution context current line position.
 *
 * @return The current line number of the context.
 */
RexxObject *RexxContext::getLine()
{
    checkValid();
    return activation->getContextLine();
}


/**
 * Return the execution context return status
 *
 * @return The .RS value of the context.
 */
RexxObject *RexxContext::getRS()
{
    checkValid();
    return activation->getContextReturnStatus();
}


/**
 * @return The parent's context.
 */
RexxObject *RexxContext::getParentContextObject()
{
    checkValid();
    return activation->getParentContextObject();
}


/**
 * Retrieve the name associated with the current context.
 * If this is the top level, then the name of the package
 * is returned.  For internal call contexts, the label name
 * is returned, and for routines or methods, the name used
 * to invoke the code is returned.
 *
 * @return The appropriate name for this context.
 */
RexxObject *RexxContext::getName()
{
    checkValid();
    return activation->getCallname();
}

/**
 * Retrieve the stack frames from the current context.
 *
 * @return A list of the current stack frames.
 */
RexxObject *RexxContext::getStackFrames()
{
    checkValid();
    // we don't want to include the stackframes frame in the list, so ask
    // that it be skipped.
    return activation->getStackFrames(true);
}
