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
/* REXX Kernel                                       ExtensionDirective.cpp   */
/*                                                                            */
/* Primitive Translator Abstract Directive Code                               */
/*                                                                            */
/******************************************************************************/
#include <stdlib.h>
#include "RexxCore.h"
#include "ExtensionDirective.hpp"
#include "Clause.hpp"
#include "DirectoryClass.hpp"
#include "TableClass.hpp"
#include "ListClass.hpp"
#include "RexxActivation.hpp"



/**
 * Construct an ExtensionDirective.
 *
 * @param n      The name of the requires target.
 * @param p      The public name of the requires target.
 * @param clause The source file clause containing the directive.
 */
ExtensionDirective::ExtensionDirective(RexxString *n, RexxString *p, RexxClause *clause) : RexxDirective(clause, KEYWORD_CLASS)
{
    idName = n;
    publicName = p;
}

/**
 * Normal garbage collecting live mark.
 *
 * @param liveMark The current live object mark.
 */
void ExtensionDirective::live(size_t liveMark)
{
    memory_mark(this->nextInstruction);  // must be first one marked (though normally null)
    memory_mark(this->publicName);
    memory_mark(this->idName);
    memory_mark(this->inheritsClasses);
    memory_mark(this->instanceMethods);
    memory_mark(this->classMethods);
}


/**
 * The generalized object marking routine.
 *
 * @param reason The processing faze we're running the mark on.
 */
void ExtensionDirective::liveGeneral(int reason)
{
    memory_mark_general(this->nextInstruction);  // must be first one marked (though normally null)
    memory_mark_general(this->publicName);
    memory_mark_general(this->idName);
    memory_mark_general(this->inheritsClasses);
    memory_mark_general(this->instanceMethods);
    memory_mark_general(this->classMethods);
}


/**
 * Flatten the directive instance.
 *
 * @param envelope The envelope we're flattening into.
 */
void ExtensionDirective::flatten(RexxEnvelope *envelope)
{
    setUpFlatten(ExtensionDirective)

        flatten_reference(newThis->nextInstruction, envelope);
        flatten_reference(newThis->publicName, envelope);
        flatten_reference(newThis->idName, envelope);
        flatten_reference(newThis->inheritsClasses, envelope);
        flatten_reference(newThis->instanceMethods, envelope);
        flatten_reference(newThis->classMethods, envelope);
        // by this time, we should be finished with this, and it should
        // already be null.  Make sure this is the case.

    cleanUpFlatten
}


/**
 * Allocate a new requires directive.
 *
 * @param size   The size of the object.
 *
 * @return The memory for the new object.
 */
void *ExtensionDirective::operator new(size_t size)
{
    return new_object(size, T_ExtensionDirective); /* Get new object                    */
}


/**
 * Do install-time processing of the ::extension directive.
 *
 * @param activation The activation we're running under for the install.
 */
void ExtensionDirective::install(RexxSource *source, RexxActivation *activation)
{
    // make this the current line for the error context
    activation->setCurrent(this);

    RexxClass *classObject;       // the class object we're extending

    // retrieve the class object to extend
    classObject = source->findClass(idName);
    if (classObject == OREF_NULL)   /* not found?                        */
    {
        reportException(Error_Execution_noclass, idName);
    }

    if (inheritsClasses != OREF_NULL)       /* have inherits to process?         */
    {
        // now handle the multiple inheritance issues
        for (size_t i = inheritsClasses->firstIndex(); i != LIST_END; i = inheritsClasses->nextIndex(i))
        {
            /* get the next inherits name        */
            RexxString *inheritsName = (RexxString *)inheritsClasses->getValue(i);
            /* go resolve the entry              */
            RexxClass *mixin = source->findClass(inheritsName);
            if (mixin == OREF_NULL)   /* not found?                        */
            {
                /* not found in environment, error!  */
                reportException(Error_Execution_noclass, inheritsName);
            }
            /* do the actual inheritance         */
            classObject->sendMessage(OREF_INHERIT, mixin);
        }
    }

    RexxString *methodName;

    if (instanceMethods != OREF_NULL) /* have instance methods to add?     */
    {
        /* define them to the class object   */
        for (HashLink i = instanceMethods->first(); (methodName = (RexxString *)instanceMethods->index(i)) != OREF_NULL; i = instanceMethods->next(i))
        {
            RexxMethod *method = (RexxMethod *)instanceMethods->value(i);
            classObject->defineMethod(methodName, method);
        }
    }

    if (classMethods != OREF_NULL) /* have class methods to add?     */
    {
        /* define them to the class object   */
        for (HashLink i = classMethods->first(); (methodName = (RexxString *)classMethods->index(i)) != OREF_NULL; i = classMethods->next(i))
        {
            RexxMethod *method = (RexxMethod *)classMethods->value(i);
            classObject->defineClassMethod(methodName, method);
        }
    }
}


/**
 * Add an inherits class to the class definition.
 *
 * @param name   The name of the inherited class.
 */
void ExtensionDirective::addInherits(RexxString *name)
{
    if (inheritsClasses == OREF_NULL)
    {
        OrefSet(this, this->inheritsClasses, new_list());
    }
    inheritsClasses->append(name);
}


/**
 * Retrieve the class methods directory for this class.
 *
 * @return The class methods directory.
 */
RexxTable *ExtensionDirective::getClassMethods()
{
    if (classMethods == OREF_NULL)
    {
        OrefSet(this, this->classMethods, new_table());
    }
    return classMethods;
}


/**
 * Retrieve the instance methods directory for this class.
 *
 * @return The instance methods directory.
 */
RexxTable *ExtensionDirective::getInstanceMethods()
{
    if (instanceMethods == OREF_NULL)
    {
        OrefSet(this, this->instanceMethods, new_table());
    }
    return instanceMethods;
}


/**
 * Check for a duplicate method defined om this class.
 *
 * @param name   The method name.
 * @param classMethod
 *               Indicates whether we are checking for a class or instance method.
 *
 * @return true if this is a duplicate of the method type.
 */
bool ExtensionDirective::checkDuplicateMethod(RexxString *name, bool classMethod)
{
    if (classMethod)
    {
        return getClassMethods()->get(name) != OREF_NULL;
    }
    else
    {
        return getInstanceMethods()->get(name) != OREF_NULL;
    }

}


/**
 * Add a method to an extension definition.
 *
 * @param name   The name to add.
 * @param method The method object that maps to this name.
 * @param classMethod
 *               Indicates whether this is a new class or instance method.
 */
void ExtensionDirective::addMethod(RexxString *name, RexxMethod *method, bool classMethod)
{
    if (classMethod)
    {
        getClassMethods()->put(method, name);
    }
    else
    {
        getInstanceMethods()->put(method, name);
    }
}


/**
 * Add a method to an extension definition.
 *
 * @param name   The name to add.
 * @param method The method object that maps to this name.
 */
void ExtensionDirective::addConstantMethod(RexxString *name, RexxMethod *method)
{
    // this gets added as both a class and instance method
    addMethod(name, method, false);
    addMethod(name, method, true);
}
