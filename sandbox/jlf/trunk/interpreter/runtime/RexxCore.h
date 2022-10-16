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
/* REXX Kernel                                                RexxCore.h      */
/*                                                                            */
/* Global Declarations                                                        */
/******************************************************************************/

/******************************************************************************/
/* Globally required include files                                            */
/******************************************************************************/
#ifndef RexxCore_INCLUDED
#define RexxCore_INCLUDED

#include "oorexxapi.h"                 // this is the core to everything

/* ANSI C definitions */
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>
#include <stdexcept>

/* REXX Library definitions */
#define OREF_NULL NULL                 /* definition of a NULL REXX object  */

#include "RexxPlatformDefinitions.h"

/******************************************************************************/
/* Literal definitions                                                        */
/******************************************************************************/
#include "RexxConstants.hpp"

/******************************************************************************/
/* Kernel Internal Limits                                                     */
/******************************************************************************/

const int MAX_ERROR_NUMBER = 99999;        /* maximum error code number         */
const int MAX_SYMBOL_LENGTH = 250;         /* length of a symbol name           */

/******************************************************************************/
/* Defines for argument error reporting                                       */
/******************************************************************************/

const int ARG_ONE    = 1;
const int ARG_TWO    = 2;
const int ARG_THREE  = 3;
const int ARG_FOUR   = 4;
const int ARG_FIVE   = 5;
const int ARG_SIX    = 6;
const int ARG_SEVEN  = 7;
const int ARG_EIGHT  = 8;
const int ARG_NINE   = 9;
const int ARG_TEN    = 10;


/* Object Reference Assignment */
#ifndef CHECKOREFS
#define OrefSet(o,r,v) ((o)->isOldSpace() ? memoryObject.setOref((void *)&(r),(RexxObject *)v) : (RexxObject *)(r=v))
#else
#define OrefSet(o,r,v) memoryObject.checkSetOref((RexxObject *)o, (RexxObject **)&(r), (RexxObject *)v, __FILE__, __LINE__)
#endif


// forward declaration of commonly used classes
class RexxExpressionStack;
class RexxActivation;
class RexxObject;
class RexxClass;
class RexxDirectory;
class RexxIntegerClass;
class RexxArray;
class RexxMemory;
class RexxString;

/******************************************************************************/
/* Change EXTERN definition if not already created by GDATA                   */
/******************************************************************************/

#ifndef INITGLOBALPTR                  // if not the global, this is a NOP.
#define INITGLOBALPTR
#endif
#ifndef EXTERN
#define EXTERN extern                  /* turn into external definition     */
#endif

#ifndef EXTERNMEM
#define EXTERNMEM extern               /* turn into external definition     */
#endif

/******************************************************************************/
/* Primitive Method Type Definition Macros                                    */
/******************************************************************************/
                                       /* following two are used by OKINIT  */
                                       /*  to build the VFT Array.          */
#define CLASS_EXTERNAL(b,c)
#define CLASS_INTERNAL(b,c)

#define koper(name) RexxObject *name(RexxObject *);


/******************************************************************************/
/* Global Objects - General                                                   */
/******************************************************************************/


// this one is special, and is truly global.
EXTERNMEM RexxMemory  memoryObject;   /* memory object                     */

// TODO:  make these into statics inside classes.

#define TheArrayClass RexxArray::classInstance
#define TheClassClass RexxClass::classInstance
#define TheDirectoryClass RexxDirectory::classInstance
#define TheIntegerClass RexxInteger::classInstance
#define TheListClass RexxList::classInstance
#define TheMessageClass RexxMessage::classInstance
#define TheMethodClass RexxMethod::classInstance
#define TheRoutineClass RoutineClass::classInstance
#define ThePackageClass PackageClass::classInstance
#define TheRexxContextClass RexxContext::classInstance
#define TheNumberStringClass RexxNumberString::classInstance
#define TheObjectClass RexxObject::classInstance
#define TheQueueClass RexxQueue::classInstance
#define TheStemClass RexxStem::classInstance
#define TheStringClass RexxString::classInstance
#define TheMutableBufferClass RexxMutableBuffer::classInstance
#define TheSupplierClass RexxSupplier::classInstance
#define TheTableClass RexxTable::classInstance
#define TheIdentityTableClass RexxIdentityTable::classInstance
#define TheRelationClass RexxRelation::classInstance
#define ThePointerClass RexxPointer::classInstance
#define TheBufferClass RexxBuffer::classInstance
#define TheWeakReferenceClass WeakReference::classInstance
#define TheStackFrameClass StackFrameClass::classInstance
#define TheRexxBlockClass RexxBlock::classInstance
#define TheRexxTextClass RexxText::classInstance
#define TheUnicodeClass Unicode::classInstance

#define TheEnvironment RexxMemory::environment
#define TheStaticRequires RexxMemory::staticRequires
#define TheFunctionsDirectory RexxMemory::functionsDir
#define TheCommonRetrievers RexxMemory::commonRetrievers
#define TheKernel RexxMemory::kernel
#define TheSystem RexxMemory::system

#define TheNilObject RexxNilObject::nilObject

#define TheNullArray RexxArray::nullArray

#define TheFalseObject RexxInteger::falseObject
#define TheTrueObject RexxInteger::trueObject
#define TheNullPointer RexxPointer::nullPointer

#define IntegerZero RexxInteger::integerZero
#define IntegerOne RexxInteger::integerOne
#define IntegerTwo RexxInteger::integerTwo
#define IntegerThree RexxInteger::integerThree
#define IntegerFour RexxInteger::integerFour
#define IntegerFive RexxInteger::integerFive
#define IntegerSix RexxInteger::integerSix
#define IntegerSeven RexxInteger::integerSeven
#define IntegerEight RexxInteger::integerEight
#define IntegerNine RexxInteger::integerNine
#define IntegerMinusOne RexxInteger::integerMinusOne

#include "ClassTypeCodes.h"



/******************************************************************************/
/* Utility Macros                                                             */
/******************************************************************************/

#define RXROUNDUP(n,to)  ((((n)+(to-1))/(to))*to)
#define rounddown(n,to)  (((n)/(to))*to)

#define isOfClass(t,r) (r)->isObjectType(The##t##Behaviour)
#define isOfClassType(t,r) (r)->isObjectType(T_##t)

/******************************************************************************/
/* Utility Functions                                                          */
/******************************************************************************/

                                       /* find an environment symbol        */
#define env_find(s) (TheEnvironment->entry(s))

/******************************************************************************/
/* Thread constants                                                           */
/******************************************************************************/

#define NO_THREAD       -1

/******************************************************************************/
/* Global Objects - Names                                                     */
/******************************************************************************/
#undef GLOBAL_NAME
#define GLOBAL_NAME(name, value) EXTERN RexxString * OREF_##name INITGLOBALPTR;
#include "GlobalNames.h"

#include "ObjectClass.hpp"               /* get real definition of Object     */

 #include "TableClass.hpp"
 #include "StackClass.hpp"
 #include "RexxMemory.hpp"               /* memory next, to get OrefSet       */
 #include "RexxBehaviour.hpp"                /* now behaviours and                */
 #include "ClassClass.hpp"                /* classes, which everything needs   */
 #include "RexxEnvelope.hpp"                /* envelope is needed for flattens   */
 #include "RexxActivity.hpp"               /* activity is needed for errors     */
 #include "NumberStringClass.hpp"               /* added to make 'number_digits()'   */
                                       /* in 'ArrayClass.c' visible            */
/******************************************************************************/
/* Method arguments special codes                                             */
/******************************************************************************/

const size_t A_COUNT   = 127;            /* pass arguments as pointer/count pair */

/******************************************************************************/
/* Return codes                                                               */
/******************************************************************************/

const int RC_OK         = 0;
const int RC_LOGIC_ERROR  = 2;

const int POSITIVE    = 1;             /* integer must be positive          */
const int NONNEGATIVE = 2;             /* integer must be non-negative      */
const int WHOLE       = 3;             /* integer must be whole             */


/******************************************************************************/
/* Argument helpers                                                           */
/******************************************************************************/

// some very common class tests
inline bool isString(RexxObject *o) { return isOfClass(String, o); }
inline bool isInteger(RexxObject *o) { return isOfClass(Integer, o); }
inline bool isNumberString(RexxObject *o) { return isOfClass(NumberString, o); }
inline bool isPolymorphicString(RexxObject *o) { return isInteger(o) || isNumberString(o) || isString(o); }
inline bool isArray(RexxObject *o) { return isOfClass(Array, o); }
inline bool isStem(RexxObject *o) { return isOfClass(Stem, o); }
inline bool isActivation(RexxObject *o) { return isOfClass(Activation, o); }
inline bool isMethod(RexxObject *o) { return isOfClass(Method, o); }

#include "ActivityManager.hpp"

/* The next macro is specifically for REQUESTing a STRING, since there are    */
/* four primitive classes that are equivalents for strings.  It will trap on  */
/* OREF_NULL. */
inline RexxString *REQUEST_STRING(RexxObject *object)
{
  return (isOfClass(String, object) ? (RexxString *)object : (object)->requestString());
}


// The next routine checks for required arguments and raises a missing argument
// error for the given position.
inline void requiredArgument(RexxObject *object, RexxString *kind, size_t position)
{
    if (object == OREF_NULL)             /* missing argument?                 */
    {
        missingArgument(kind, position);        /* raise an error                    */
    }
}


/* The next routine is specifically for REQUESTing a STRING needed as a method*/
/* argument.  This raises an error if the object cannot be converted to a     */
/* string value.                                                              */
inline RexxString * stringArgument(RexxObject *object, RexxString *kind, size_t position)
{
    if (object == OREF_NULL)             /* missing argument?                 */
    {
        missingArgument(kind, position);        /* raise an error                    */
    }
                                           /* force to a string value           */
    return object->requiredString(kind, position);
}


/* The next routine is specifically for REQUESTing a STRING needed as a method*/
/* argument.  This raises an error if the object cannot be converted to a     */
/* string value.                                                              */
inline RexxString * stringArgument(RexxObject *object, RexxString *kind, const char *name)
{
    if (object == OREF_NULL)             /* missing argument?                 */
    {
        reportException(Error_Invalid_argument_noarg, kind, name);
    }
                                           /* force to a string value           */
    return object->requiredString(kind, name);
}


inline RexxString *optionalStringArgument(RexxObject *o, RexxString *d, RexxString *kind, size_t p)
{
    return (o == OREF_NULL ? d : stringArgument(o, kind, p));
}


inline RexxString *optionalStringArgument(RexxObject *o, RexxString *d, RexxString *kind, const char *p)
{
    return (o == OREF_NULL ? d : stringArgument(o, kind, p));
}


// resides in the string class util
size_t lengthArgument(RexxObject *o, size_t p);

inline size_t optionalLengthArgument(RexxObject *o, size_t d, size_t p)
{
    return (o == OREF_NULL ? d : lengthArgument(o, p));
}

// resides in the string class util
size_t positionArgument(RexxObject *o, size_t p);

inline size_t optionalPositionArgument(RexxObject *o, size_t d, size_t p)
{
    return (o == OREF_NULL ? d : positionArgument(o, p));
}

codepoint_t padArgument(RexxObject *o, size_t p);

inline codepoint_t optionalPadArgument(RexxObject *o, codepoint_t d, size_t p)
{
    return (o == OREF_NULL ? d : padArgument(o, p));
}

char optionArgument(RexxObject *o, size_t p);

inline char optionalOptionArgument(RexxObject *o, char d, size_t p)
{
    return (o == OREF_NULL ? d : optionArgument(o, p));
}

inline size_t optionalNonNegative(RexxObject *o, size_t d, RexxString *kind, size_t p)
{
    return (o == OREF_NULL ? d : o->requiredNonNegative(kind, p));
}

inline size_t optionalPositive(RexxObject *o, size_t d, RexxString *kind, size_t p)
{
    return (o == OREF_NULL ? d : o->requiredPositive(kind, p));
}

/* The next routine is specifically for REQUESTing an ARRAY needed as a method*/
/* argument.  This raises an error if the object cannot be converted to a     */
/* single dimensional array item                                              */
inline RexxArray *arrayArgument(RexxObject *object, RexxString *kind, size_t position)
{
    if (object == OREF_NULL)             /* missing argument?                 */
    {
        missingArgument(kind, position);      /* raise an error                    */
    }
    /* force to array form               */
    RexxArray *array = object->requestArray();
    /* not an array?                     */
    if (array == TheNilObject || array->getDimension() != 1)
    {
        /* raise an error                    */
        // reportException(Error_Execution_noarray, object);
        // jlf: don't impact Error_Execution_noarray with kind, because used in several places where kind has no meaning
        // jlf: instead, use Error_Invalid_argument_noarray (where I added a 3rd parameter: object)
        // jlf: drawback, some test cases may fail because of this change, will see...
        // jlf: about new_integer, few risks to create a new instance, so no need to protect it against GC
        reportException(Error_Invalid_argument_noarray, kind, new_integer(position), object);
    }
    return array;
}


inline RexxArray * arrayArgument(RexxObject *object, RexxString *kind, RexxString *name)
{
    if (object == OREF_NULL)             /* missing argument?                 */
    {
        reportException(Error_Invalid_argument_noarg, kind, name);
    }

    /* force to array form               */
    RexxArray *array = object->requestArray();
    /* not an array?                     */
    if (array == TheNilObject || array->getDimension() != 1)
    {
        /* raise an error */
        reportException(Error_Invalid_argument_noarray, kind, name, object);
    }
    return array;
}


/* The next routine is specifically for REQUESTing a STRING needed as a method*/
/* argument.  This raises an error if the object cannot be converted to a     */
/* string value.                                                              */
inline void classArgument(RexxObject *object, RexxClass *clazz, RexxString *kind, RexxString *name)
{
    if (object == OREF_NULL)             /* missing argument?                 */
    {
        reportException(Error_Invalid_argument_noarg, kind, name);
    }

    if (!object->isInstanceOf(clazz))
    {
        reportException(Error_Invalid_argument_noclass, kind, name, clazz->getId());
    }
}


/* The next macro is specifically for REQUESTing an ARRAY, since there are    */
/* six primitive classes that can produce array equivalents.  It will trap on */
/* OREF_NULL. */
inline RexxArray * REQUEST_ARRAY(RexxObject *obj) { return ((obj)->requestArray()); }

/* The next macro is specifically for REQUESTing an INTEGER,                  */
inline RexxInteger * REQUEST_INTEGER(RexxObject *obj) { return ((obj)->requestInteger(Numerics::ARGUMENT_DIGITS));}


/******************************************************************************/
/* Named argument helpers                                                     */
/******************************************************************************/

struct NamedArgument
{
    NamedArgument(const char *name=NULL, ssize_t minimumLength=-1, RexxObject *value=OREF_NULL)
    : name(name), minimumLength(minimumLength), value(value) { assigned = false; };

    const char *name;       // name of the named argument
    ssize_t minimumLength;  // abbreviation supported, pass -1 if no abbreviation
    RexxObject *value;      // default value or OREF_NULL
    bool assigned;          // true if a value has been assigned
};

class NamedArguments
{
  public:
    NamedArguments(size_t count): count(count)
    {
        // count=0 is accepted
        this->namedArguments = new NamedArgument[count];
        if (this->namedArguments == NULL) throw std::invalid_argument( "NamedArguments: memory error" );
    }

    ~NamedArguments()
    {
        delete[] this->namedArguments;
        this->namedArguments = NULL;
    }

    NamedArgument &operator[](size_t index)
    {
        if (this->namedArguments == NULL) throw std::invalid_argument( "NamedArguments: this instance has been deleted" );
        if (index >= this->count) throw std::invalid_argument( "NamedArguments: invalid index" );
        return this->namedArguments[index];
    }

    // Resides in UseStrictInstruction.cpp.
    // Match namedArglist (name1, value1, name2, value2, ...) with the declared namedArguments
    void match(RexxObject **namedArglist, size_t namedArgCount, bool strict, bool extraAllowed, size_t minimumRequired=0);

    // name: name of the argument passed by the caller, to search in expectedNamedArguments. Can be null.
    // value: value of the argument passed by the caller, to store in expectedNamedArguments if name is found. Can be null.
    // strict: raise error if true and name not null and name not found.
    // name_minimumLength: passed when checking at parse_time if some names collide in the USE instruction
    //     @parse_time: check each name <N> declared in the USE instruction with all other names <ON> in this USE instruction.
    //                  name_minimumLength is the minimumLength of the name <N>.
    //     @run_time : match the name passed by the caller (no abbreviation on caller side, name_minimumLength is always -1).
    bool match(RexxString *name, RexxObject *value, bool strict = true, ssize_t name_minimumLength = -1, size_t from = 0, bool parse_time = false);
    bool match(const char *name, RexxObject *value, bool strict = true, ssize_t name_minimumLength = -1, size_t from = 0, bool parse_time = false);

    const size_t count;

  private:
    bool checkNameMatching(const char *name, ssize_t name_minimumLength, size_t i, bool parse_time);

    NamedArgument *namedArguments; // array
};


/******************************************************************************/
/* Typed method invocation macros                                             */
/******************************************************************************/

inline RexxObject * callOperatorMethod(RexxObject *object, size_t methodOffset, RexxObject *argument) {
                                       /* get the entry point               */
  PCPPM cppEntry = object->behaviour->getOperatorMethod(methodOffset);
                                       /* go issue the method               */
  return (object->*((PCPPM1)cppEntry))(argument);
}

#endif
