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

#include "RexxCore.h"
#include "ContextualSourceClass.hpp"
#include "RexxActivation.hpp"
#include "PackageClass.hpp"


/******************************************************************************/
/* REXX Kernel                                                                */
/*                                                                            */
/* Primitive Rexx source literal                                              */
/*                                                                            */
/******************************************************************************/

/**
 * Allocate a new RexxSourceLiteral object
 *
 * @param size   The size of the object.
 *
 * @return The newly allocated object.
 */
void *RexxSourceLiteral::operator new(size_t size)
{
    /* Get new object                    */
    return new_object(size, T_SourceLiteral);
}


void RexxSourceLiteral::live(size_t liveMark)
/******************************************************************************/
/* Function:  Normal garbage collection live marking                          */
/******************************************************************************/
{
    memory_mark(this->source);
    memory_mark(this->package);
}

void RexxSourceLiteral::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
    memory_mark_general(this->source);
    memory_mark_general(this->package);
}

void RexxSourceLiteral::flatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
  setUpFlatten(RexxSourceLiteral)

  newThis->source = OREF_NULL;   // this never should be getting flattened, so sever the connection
  newThis->package = OREF_NULL;  // idem

  cleanUpFlatten
}


RexxSourceLiteral::RexxSourceLiteral(RexxString *s, PackageClass *p) 
{
    RexxArray *sa = s->makeArray(NULL); // use default separator \n
    ProtectedObject pr(sa);
    OrefSet(this, this->source, sa);
    OrefSet(this, this->package, p);
    OrefSet(this, this->routine, OREF_NULL);
    // If the first character > 32 is not a ':' then create an executable
    bool colon = false;
    for (sizeC_t i=0; i < s->getCLength(); i++)
    {
        codepoint_t c = s->getCharC(i);
        if (c <= 32) continue;
        colon = (c == ':');
        break;
    }
    if (!colon)
    {
        OrefSet(this, this->routine, this->makeRoutine(sa, p));
    }
}


RexxObject  *RexxSourceLiteral::evaluate(
    RexxActivation      *context,      /* current activation context        */
    RexxExpressionStack *stack )       /* evaluation stack                  */
{
    RexxContext *rexxContext = (RexxContext *)context->getContextObject();
    RexxObject *value = new RexxContextualSource(this, rexxContext);
    stack->push(value);                /* place on the evaluation stack     */
                                       /* trace if necessary                */
    context->traceIntermediate(value, TRACE_PREFIX_LITERAL);
    return value;                      /* also return the result            */
}


RoutineClass *RexxSourceLiteral::makeRoutine(RexxArray *source, PackageClass *parentSource) 
{
    RoutineClass *routine = new RoutineClass(new_string(""), source);
    ProtectedObject p(routine);

    // if there is a parent source, then merge in the scope information
    if (parentSource != OREF_NULL)
    {
        routine->getSourceObject()->inheritSourceContext(parentSource->getSourceObject());
    }

    return routine;
}


/******************************************************************************/
/* REXX Kernel                                                                */
/*                                                                            */
/* Primitive Rexx contextual source                                           */
/*                                                                            */
/******************************************************************************/

RexxClass *RexxContextualSource::classInstance = OREF_NULL;   // singleton class instance

/**
 * Create initial bootstrap objects
 */
void RexxContextualSource::createInstance()
{
    CLASS_CREATE(RexxContextualSource, "RexxContextualSource", RexxClass);
}


/**
 * Allocate a new RexxContextualSource object
 *
 * @param size   The size of the object.
 *
 * @return The newly allocated object.
 */
void *RexxContextualSource::operator new(size_t size)
{
    /* Get new object                    */
    return new_object(size, T_RexxContextualSource);
}


/**
 * Constructor for a RexxContextualSource object.
 *
 * @param p      The package class.
 */
RexxContextualSource::RexxContextualSource(RexxSourceLiteral *s, RexxContext *c)
{
    OrefSet(this, this->sourceLiteral, s);
    OrefSet(this, this->context, c);
}


/**
 * The Rexx accessible class NEW method.  This raises an
 * error because RexxContextualSource objects can only be created
 * by the internal interpreter.
 *
 * @param args   The NEW args
 * @param argc   The count of arguments
 *
 * @return Never returns.
 */
RexxObject *RexxContextualSource::newRexx(RexxObject **args, size_t argc)
{
    // we do not allow these to be allocated from Rexx code...
    reportException(Error_Unsupported_new_method, ((RexxClass *)this)->getId());
    return TheNilObject;
}


/**
 * An override for the copy method to keep RexxContextualSource
 * objects from being copied.
 *
 * @return Never returns.
 */
RexxObject *RexxContextualSource::copyRexx()
{
    // we do not allow these to be allocated from Rexx code...
    reportException(Error_Unsupported_copy_method, this);
    return TheNilObject;
}


RexxArray *RexxContextualSource::getSource() 
{ 
    return (RexxArray *)(sourceLiteral->getSource()->copy()); 
}


PackageClass *RexxContextualSource::getPackage() 
{
    return sourceLiteral->getPackage();
}


RexxContext *RexxContextualSource::getContext() 
{
    return context;
}


RexxObject *RexxContextualSource::getExecutable()
{
    RoutineClass *routine = sourceLiteral->getExecutable();
    if (routine == OREF_NULL) return TheNilObject;
    return routine;
}


/**
 * Call a source literal routine from Rexx-level code.
 *
 * @param args   The call arguments.
 * @param count  The count of arguments.
 *
 * @return The call result (if any).
 */
RexxObject *RexxContextualSource::callRexx(RexxObject **args, size_t count)
{
    RoutineClass *routine = sourceLiteral->getExecutable();
    if (routine == OREF_NULL) 
    {
        reportException(Error_Incorrect_call_user_defined, new_string("This contextual source has no executable (deferred parsing)"));
        return TheNilObject;
    }
    return routine->callRexx(args, count);
}


/**
 * Call a source literal routine from Rexx-level code.
 *
 * @param args   The call arguments.
 *
 * @return The call result (if any).
 */
RexxObject *RexxContextualSource::callWithRexx(RexxArray *args)
{
    // this is required and must be an array
    args = arrayArgument(args, ARG_ONE);

    RoutineClass *routine = sourceLiteral->getExecutable();
    if (routine == OREF_NULL) 
    {
        reportException(Error_Incorrect_call_user_defined, new_string("This contextual source has no executable (deferred parsing)"));
        return TheNilObject;
    }
    return routine->callWithRexx(args);
}



void RexxContextualSource::live(size_t liveMark)
/******************************************************************************/
/* Function:  Normal garbage collection live marking                          */
/******************************************************************************/
{
    memory_mark(this->sourceLiteral);
    memory_mark(this->context);
}

void RexxContextualSource::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
    memory_mark_general(this->sourceLiteral);
    memory_mark_general(this->context);
}

void RexxContextualSource::flatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
  setUpFlatten(RexxContextualSource)

  newThis->sourceLiteral = OREF_NULL; // this never should be getting flattened, so sever the connection
  newThis->context = OREF_NULL;    // idem

  cleanUpFlatten
}
