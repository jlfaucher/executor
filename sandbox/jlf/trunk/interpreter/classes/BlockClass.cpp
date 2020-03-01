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
#include "BlockClass.hpp"
#include "RexxActivation.hpp"
#include "PackageClass.hpp"
#include "DirectoryClass.hpp"


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
    memory_mark(this->kind);
    memory_mark(this->rawExecutable);
}

void RexxSourceLiteral::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
    memory_mark_general(this->source);
    memory_mark_general(this->package);
    memory_mark_general(this->kind);
    memory_mark_general(this->rawExecutable);
}

void RexxSourceLiteral::flatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
  setUpFlatten(RexxSourceLiteral)

  newThis->source = OREF_NULL;   // this never should be getting flattened, so sever the connection
  newThis->package = OREF_NULL;  // idem
  newThis->kind = OREF_NULL; // idem
  newThis->rawExecutable = OREF_NULL;  // idem

  cleanUpFlatten
}


RexxSourceLiteral::RexxSourceLiteral(RexxString *s, PackageClass *p, size_t startLine)
{
    ProtectedObject pThis(this);
    RexxArray *sa = s->makeArrayRexx(NULL); // use default separator \n
    this->source = sa; // transient, no need of OrefSet
    this->package = p; // transient, no need of OrefSet
    RexxArray *sourceArray = (RexxArray *)sa->copy();
    ProtectedObject pSourceArray(sourceArray);

    // clauser = .Clauser~new(sourceArray)
    // The clauser will have a direct impact on sourceArray :
    // - The message KIND returns the kind of the source after removing the keyword(s) that declares the kind of the source.
    // - The message TRANSFORMSOURCE updates directly the sourceArray.
    RexxObject *clauserClass = TheEnvironment->at(OREF_CLAUSER);
    RexxObject *clauser = clauserClass->sendMessage(OREF_NEW, (RexxObject *)sourceArray); // must cast sourceArray, otherwise taken as array of arguments
    ProtectedObject pClauser(clauser);

    // kind = clauser~kind(remove: .true)
    RexxObject *arguments[0 + (1*2)]; // 0 positional arg, 1 named arg
    arguments[0] = OREF_REMOVE; // named arg name
    arguments[1] = TheTrueObject; // named arg value
    this->kind = (RexxString *)clauser->sendMessage(OREF_KIND, arguments, 0, 2); // transient, no need of OrefSet

    // clauser~transformSource(clauseBefore, clauseAfter)
    // Transform the source to accept auto named arguments, and to return implicitely the result of the last evaluated expression
    RexxString *clauseBefore = new_string("use auto named arg ; options \"NOCOMMANDS\"");
    ProtectedObject pClauseBefore(clauseBefore);
    RexxString *clauseAfter = new_string("if var(\"result\") then return result");
    ProtectedObject pClauseAfter(clauseAfter);
    clauser->sendMessage(OREF_TRANSFORMSOURCE, clauseBefore, clauseAfter);

    // rawExecutable = .Clauser~rawExecutable(kind, sourceArray, package)
    this->rawExecutable =clauserClass->sendMessage(OREF_RAWEXECUTABLE, this->kind, sourceArray, this->package); // transient, no need of OrefSet
    this->closure = (0 == strncmp(this->kind->getStringData(), "cl", 2));
}


RexxObject  *RexxSourceLiteral::evaluate(
    RexxActivation      *context,      /* current activation context        */
    RexxExpressionStack *stack )       /* evaluation stack                  */
{
    RexxContext *rexxContext = (RexxContext *)context->getContextObject();
    RexxObject *value = new RexxBlock(this, rexxContext);
    stack->push(value);                /* place on the evaluation stack     */
                                       /* trace if necessary                */
    context->traceIntermediate(value, TRACE_PREFIX_LITERAL);
    return value;                      /* also return the result            */
}


/******************************************************************************/
/* REXX Kernel                                                                */
/*                                                                            */
/* Primitive Rexx contextual source                                           */
/*                                                                            */
/******************************************************************************/

RexxClass *RexxBlock::classInstance = OREF_NULL;   // singleton class instance

/**
 * Create initial bootstrap objects
 */
void RexxBlock::createInstance()
{
    CLASS_CREATE(RexxBlock, "RexxBlock", RexxClass);
}


/**
 * Allocate a new RexxBlock object
 *
 * @param size   The size of the object.
 *
 * @return The newly allocated object.
 */
void *RexxBlock::operator new(size_t size)
{
    /* Get new object                    */
    return new_object(size, T_RexxBlock);
}


/**
 * Constructor for a RexxBlock object.
 *
 * @param p      The package class.
 */
RexxBlock::RexxBlock(RexxSourceLiteral *s, RexxContext *c)
{
    OrefSet(this, this->sourceLiteral, s);
    OrefSet(this, this->variables, (RexxDirectory *)TheNilObject);

	// c->getVariables will create a directory : see RexxVariableDictionary::getAllVariables
	// So a GC may happen, must protect this.
	ProtectedObject p(this);
    if (s->isClosure()) OrefSet(this, this->variables, (RexxDirectory *)c->getVariables());

	// Normally, next lines are done from RexxBlock::newRexx
	// But I don't allow to create a new block from Rexx code.
	// On the other hand, I want to extend the RexxBlock class and initialize some variables,
	// hence the sendMessage OREF_INIT.

#if 0 // To rework... this code is wrong (crash)
	// override the behaviour in case this is a subclass
	RexxBehaviour *behaviour = ((RexxClass *)this)->getInstanceBehaviour();
    if (behaviour != NULL) this->setBehaviour(behaviour);
    if (((RexxClass *)this)->hasUninitDefined())
    {
        this->hasUninit();
    }
#endif
    this->sendMessage(OREF_INIT);
}


/**
 * The Rexx accessible class NEW method.  This raises an
 * error because RexxBlock objects can only be created
 * by the internal interpreter.
 *
 * @param args   The NEW args
 * @param argc   The count of arguments
 *
 * @return Never returns.
 */
RexxObject *RexxBlock::newRexx(RexxObject **args, size_t argc, size_t named_argc)
{
    // we do not allow these to be allocated from Rexx code...
    reportException(Error_Unsupported_new_method, ((RexxClass *)this)->getId());
    return TheNilObject;
}


/**
 * An override for the copy method to keep RexxBlock
 * objects from being copied.
 *
 * @return Never returns.
 */
RexxObject *RexxBlock::copyRexx()
{
    // we do not allow these to be allocated from Rexx code...
    reportException(Error_Unsupported_copy_method, this);
    return TheNilObject;
}


void RexxBlock::live(size_t liveMark)
/******************************************************************************/
/* Function:  Normal garbage collection live marking                          */
/******************************************************************************/
{
    memory_mark(this->objectVariables);
    memory_mark(this->sourceLiteral);
    memory_mark(this->variables);
}

void RexxBlock::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
    memory_mark_general(this->objectVariables);
    memory_mark_general(this->sourceLiteral);
    memory_mark_general(this->variables);
}

void RexxBlock::flatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
  setUpFlatten(RexxBlock)

  flatten_reference(newThis->objectVariables, envelope);
  newThis->sourceLiteral = OREF_NULL; // this never should be getting flattened, so sever the connection
  newThis->variables = OREF_NULL;    // idem

  cleanUpFlatten
}
