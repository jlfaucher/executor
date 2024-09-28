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
/* REXX Kernel                                               StringClass.c    */
/*                                                                            */
/* Primitive String Class                                                     */
/*                                                                            */
/******************************************************************************/
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <limits>

#include "RexxCore.h"
#include "StringClass.hpp"
#include "TextClass.hpp"
#include "DirectoryClass.hpp"
#include "RexxActivation.hpp"
#include "RexxActivity.hpp"
#include "ProtectedObject.hpp"
#include "StringUtil.hpp"
#include "RexxCompoundTail.hpp"
#include "SystemInterpreter.hpp"
#include "PackageClass.hpp"

// singleton class instance
RexxClass *RexxString::classInstance = OREF_NULL;


/**
 * Create initial class object at bootstrap time.
 */
void RexxString::createInstance()
{
    CLASS_CREATE(String, "String", RexxClass);
}


// Never called
RexxString::RexxString()
{
}


/*
Called ONCE at start-up (per interpreter)

#0	RexxString::RexxString(RESTORETYPE) at /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/classes/StringClass.cpp:159
#1	RexxMemory::buildVirtualFunctionTable() at /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/behaviour/VirtualFunctionTable.cpp:253
       objectPtr = new (objectLoc) RexxString(RESTOREIMAGE);
       virtualFunctionTable[T_String] = getVftPointer(objectLoc);
#2	RexxMemory::initialize(bool, char const*) at /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/memory/RexxMemory.cpp:207
#3	Interpreter::startInterpreter(Interpreter::InterpreterStartupMode, char const*) at /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/runtime/Interpreter.cpp:134
#4	Interpreter::createInterpreterInstance(RexxOption*) at /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/runtime/Interpreter.cpp:305
#5	in Interpreter::createInstance(RexxInstance_*&, RexxThreadContext_*&, RexxOption*) at /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/runtime/Interpreter.cpp:263
#6	::RexxCreateInterpreter(RexxInstance **, RexxThreadContext **, RexxOption *) at /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/api/InterpreterAPI.cpp:383
*/
RexxString::RexxString(RESTORETYPE restoreType)
{
}


HashCode RexxString::hash()
/******************************************************************************/
/* Function:  retrieve the hash value of a string object                      */
/******************************************************************************/
{
    if (!isString(this))            /*  a nonprimitive object?           */
    {
        /* see if == overridden.             */
        RexxObject *result = this->sendMessage(OREF_STRICT_EQUAL);
        if (result == OREF_NULL)
        {
            reportException(Error_No_result_object_message, OREF_STRICT_EQUAL);
        }
        return result->requestString()->getStringHash();
    }
    else
    {
        return this->getHashValue();       /* return the string hash            */
    }
}


/**
 * Get the primitive hash value of this String object.
 *
 * @return The calculated string hash for the string.
 */
HashCode RexxString::getHashValue()
{
    // this will calculate the hash if it hasn't been done yet
    return getStringHash();
}


/**
 * Convert a string returned from an object HashCode() method into
 * a binary hashcode suitable for the hash collections.
 *
 * @return A binary hash code from a string value.
 */
HashCode RexxString::getObjectHashCode()
{
    HashCode h;

    // ok, we need to pick this string apart and turn this into a numeric code
    // a null string is simple.
    if (getLength() == 0)
    {
        h = 1;
    }

    // if we have at least 4 characters, use them as binary, since that's
    // what is normally returned here.
    else if (getLength() >= sizeof(HashCode))
    {
        h = *((HashCode *)getStringData());
    }
    else
    {
        // either 1 or 2 characters.  Just pick up a short value, which will
        // also pick up terminating null if only a single character
        h = *((short *)getStringData());
    }
    return h;
}



void RexxString::live(size_t liveMark)
/******************************************************************************/
/* Function:  Normal garbage collection live marking                          */
/******************************************************************************/
{
    memory_mark(this->NumberString);
    memory_mark(this->text);
    memory_mark(this->encoding);
    memory_mark(this->objectVariables);
}

void RexxString::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
    memory_mark_general(this->NumberString);
    memory_mark_general(this->text);
    memory_mark_general(this->encoding);
    memory_mark_general(this->objectVariables);
}

void RexxString::flatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
  setUpFlatten(RexxString)

   flatten_reference(newThis->NumberString, envelope);
   OrefSet(newThis, newThis->text, OREF_NULL);       // not flattened
   //flatten_reference(newThis->text, envelope);
   OrefSet(newThis, newThis->encoding, OREF_NULL);   // iidem
   //flatten_reference(newThis->encoding, envelope);
   flatten_reference(newThis->objectVariables, envelope);

  cleanUpFlatten
}

RexxObject *RexxString::unflatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  unflatten an object                                             */
/******************************************************************************/
{
    if (this->isProxyObject())
    {        /* is this a proxy object?              */
        // just perform an environment lookup
        return TheEnvironment->entry(this);
    }
    else
    {
        // perform a normal default unflatten op.
        return this->RexxObject::unflatten(envelope);
    }
}

RexxObject *RexxString::dynamicTarget(RexxObject **arguments, size_t count, size_t named_count)
/******************************************************************************/
/* Function:  Return either a RexxText instance or a RexxString instace       */
/******************************************************************************/
{
    if (hasRexxTextArguments(arguments, count, named_count))
    {
        RexxText *text = this->requestText();
        return text;
    }

    return this;
}


RexxString *RexxString::stringValue()
/******************************************************************************/
/* Function:  Return the primitive string value of this object                */
/******************************************************************************/
{
    if (isOfClass(String, this))             /* already a primitive string?       */
    {
        return this;                       /* just return our selves            */
    }
    else                                 /* need to build a new string        */
    {
        return new_string(this->getStringData(), this->getLength());
    }
}

RexxString  *RexxString::makeString()
/******************************************************************************/
/* Function:  Handle a REQUEST('STRING') request for a REXX string object     */
/******************************************************************************/
{
    if (this->isBaseClass())             /* really a primitive string?        */
    {
        return this;                       /* this is easy                      */
    }
    else                                 /* need to create a new string       */
    {
        return new_string(this->getStringData(), this->getLength());
    }
}

/**
 * Baseclass optimization for handling request array calls.
 *
 * @return The string object converted to an array using default arguments.
 */
RexxArray  *RexxString::makeArray()
{
    // forward to the Rexx version with default arguments
    return this->makeArrayRexx(OREF_NULL);
}


void RexxString::copyIntoTail(RexxCompoundTail *tail)
/******************************************************************************/
/* Function:  Handle a tail construction request for an internal object       */
/******************************************************************************/
{
                                       /* copy this directly into the tail */
    tail->append(this->getStringData(), this->getLength());
}


RexxString  *RexxString::primitiveMakeString()
/******************************************************************************/
/* Function:  Handle a REQUEST('STRING') request for a REXX string object     */
/******************************************************************************/
{
    return this;                         /* this is easy                      */
}

bool RexxString::numberValue(wholenumber_t &result, stringsize_t digits)
/******************************************************************************/
/* Function:  Convert a string object to a long value.  Returns false         */
/*            it will not convert.                                            */
/******************************************************************************/
{
    if (!(isString(this)))               /* subclassed string object?         */
    {
        return this->requestString()->numberValue(result, digits);
    }
                                         /* get the string value's long value */
    RexxNumberString *numberstring = this->fastNumberString();
    if (numberstring != OREF_NULL )      /* convert ok?                       */
    {
                                         /* convert to integer with proper    */
                                         /* precision                         */
        return numberstring->numberValue(result, digits);
    }
    return false;                        /* return the "not value long" value */
}

bool RexxString::numberValue(wholenumber_t &result)
/******************************************************************************/
/* Function:  Convert a string object to a long value.  Returns false         */
/*            it will not convert.                                            */
/******************************************************************************/
{
    if (!(isString(this)))               /* subclassed string object?         */
    {
        return this->requestString()->numberValue(result);
    }
                                         /* get the string value's long value */
    RexxNumberString *numberstring = this->fastNumberString();
    if (numberstring != OREF_NULL )      /* convert ok?                       */
    {
                                         /* convert to integer with proper    */
                                         /* precision                         */
        return numberstring->numberValue(result);
    }
    return false;                        /* return the "not value long" value */
}


bool RexxString::unsignedNumberValue(uwholenumber_t &result, stringsize_t digits)
/******************************************************************************/
/* Function:  Convert a string object to a long value.  Returns false         */
/*            it will not convert.                                            */
/******************************************************************************/
{
    if (!(isString(this)))               /* subclassed string object?         */
    {
        return this->requestString()->unsignedNumberValue(result, digits);
    }
                                         /* get the string value's long value */
    RexxNumberString *numberstring = this->fastNumberString();
    if (numberstring != OREF_NULL )      /* convert ok?                       */
    {
                                         /* convert to integer with proper    */
                                         /* precision                         */
        return numberstring->unsignedNumberValue(result, digits);
    }
    return false;                        /* return the "not value long" value */
}


bool RexxString::unsignedNumberValue(uwholenumber_t &result)
/******************************************************************************/
/* Function:  Convert a string object to a long value.  Returns false         */
/*            it will not convert.                                            */
/******************************************************************************/
{
    if (!(isString(this)))               /* subclassed string object?         */
    {
        return this->requestString()->unsignedNumberValue(result);
    }
                                         /* get the string value's long value */
    RexxNumberString *numberstring = this->fastNumberString();
    if (numberstring != OREF_NULL )      /* convert ok?                       */
    {
                                         /* convert to integer with proper    */
                                         /* precision                         */
        return numberstring->unsignedNumberValue(result);
    }
    return false;                        /* return the "not value long" value */
}

bool RexxString::doubleValue(double &result)
/******************************************************************************/
/* Function:  Convert a string object to a double value                       */
/******************************************************************************/
{
    RexxNumberString *numberDouble = this->fastNumberString(); /* convert String to Numberstring    */
    if (numberDouble != OREF_NULL)       /* Did we get a numberstring?        */
    {
        return numberDouble->doubleValue(result);/* Yup, convert it to double         */
    }
    // non numeric, so this could be one of the special cases
    if (strCompare("nan"))
    {
        result = std::numeric_limits<double>::signaling_NaN();
        // this will be false if this is really a NaN value. If true,
        // then fall back and use the quiet version.
        if (!isnan(result))
        {
          result = std::numeric_limits<double>::quiet_NaN();
        }
        return true;
    }
    if (strCompare("+infinity"))
    {
        result = +HUGE_VAL;
        return true;
    }
    if (strCompare("-infinity"))
    {
        result = -HUGE_VAL;
        return true;
    }
    return false;                      /* not number string, so NODOUBLE    */
}


RexxNumberString *RexxString::numberString()
/******************************************************************************/
/* Function:   Convert a String Object into a Number Object                   */
/******************************************************************************/
{
    RexxString       *newSelf;           /* converted string value            */

    if (this->nonNumeric())              /* Did we already try and convert to */
    {
        /* to a numberstring and fail?       */
        return OREF_NULL;                   /* Yes, no need to try agian.        */
    }

    if (this->NumberString != OREF_NULL) /* see if we have already converted  */
    {
        return this->NumberString;         /* return the numberString Object.   */
    }

    if (!isOfClass(String, this))
    {          /* not truly a string type?          */
        newSelf = this->requestString();   /* do the conversion                 */
                                           /* get a new numberstring Obj        */
        OrefSet(this, this->NumberString, (RexxNumberString *)new_numberstring(newSelf->getStringData(), newSelf->getLength()));
        if (this->NumberString != OREF_NULL)     /* Did number convert OK?            */
        {
            this->setHasReferences();     /* Make sure we are sent Live...     */
        }
    }
    else
    {                               /* real primitive string             */
                                    /* get a new numberstring Obj        */
        OrefSet(this, this->NumberString, (RexxNumberString *)new_numberstring(this->getStringData(), this->getLength()));
        if (this->NumberString == OREF_NULL)     /* Did number convert OK?            */
        {
            this->setNonNumeric();           /* mark as a nonnumeric              */
        }
        else
        {
            this->setHasReferences();        /* Make sure we are sent Live...     */
                                             /* connect the string and number     */
            this->NumberString->setString(this);
        }
    }
    return this->NumberString;           /* return the numberString Object.   */
}

RexxNumberString *RexxString::createNumberString()
/******************************************************************************/
/* Function:   Convert a String Object into a Number Object                   */
/******************************************************************************/
{
    RexxString       *newSelf;           /* converted string value            */

    if (!isOfClass(String, this))
    {          /* not truly a string type?          */
        newSelf = this->requestString();   /* do the conversion                 */
                                           /* get a new numberstring Obj        */
        OrefSet(newSelf, newSelf->NumberString, (RexxNumberString *)new_numberstring(newSelf->getStringData(), newSelf->getLength()));
        /* save the number string            */
        if (newSelf->NumberString != OREF_NULL)     /* Did number convert OK?            */
        {
            newSelf->setHasReferences();     /* Make sure we are sent Live...     */
        }
        return newSelf->NumberString;
    }
    else
    {                               /* real primitive string             */
                                    /* get a new numberstring Obj        */
        OrefSet(this, this->NumberString, (RexxNumberString *)new_numberstring(this->getStringData(), this->getLength()));
        if (this->NumberString == OREF_NULL)     /* Did number convert OK?            */
        {
            this->setNonNumeric();           /* mark as a nonnumeric              */
        }
        else
        {
            this->setHasReferences();        /* Make sure we are sent Live...     */
                                             /* connect the string and number     */
            this->NumberString->setString(this);
        }
        return this->NumberString;
    }
}


size_t RexxString::copyData(size_t startPos, char *buffer, size_t bufl)
/******************************************************************************/
/* Function:  Get a section of a string and copy it into a buffer             */
/******************************************************************************/
{
    size_t copylen = 0;

    if (startPos < this->getLength())
    {
        if (bufl <= this->getLength() - startPos)
        {
            copylen = bufl;
        }
        else
        {
            copylen = this->getLength() - startPos;
        }
        memcpy(buffer, this->getStringData() + startPos, copylen);
    }

    return copylen;
}

// in behaviour
RexxObject *RexxString::lengthRexx()
/******************************************************************************/
/* Function:  Return the length of a string as an integer object              */
/******************************************************************************/
{
                                       /* no longer return string byte length, now returns characters count         */
    return new_integer(getLength());
}

bool RexxString::isEqual(
    RexxObject *otherObj)              /* other comparison object           */
/******************************************************************************/
/* Function:  Primitive strict equal\not equal method.  This determines       */
/*            only strict equality, not greater or less than values.          */
/******************************************************************************/
{
    requiredArgument(otherObj, OREF_positional, ARG_ONE);         /* this is required.                 */
    if (!this->isBaseClass())            /* not a primitive?                  */
    {
        /* do the full lookup compare        */
        RexxObject *result = this->sendMessage(OREF_STRICT_EQUAL, otherObj);
        if (result == OREF_NULL)
        {
            reportException(Error_No_result_object_message, OREF_STRICT_EQUAL);
        }
        return result->truthValue(Error_Logical_value_method);
    }

    if (otherObj == TheNilObject)        // strings never compare equal to the NIL object
    {
        return false;
    }

    RexxString *other = REQUEST_STRING(otherObj);    /* force into string form            */
    size_t otherLen = other->getLength();     /* get length of second string.      */
    if (otherLen != this->getLength())        /* lengths different?                */
    {
        return false;                      /* also unequal                      */
    }
                                           /* now compare the actual string     */
    return !memcmp(this->getStringData(), other->getStringData(), otherLen);
}

bool RexxString::primitiveIsEqual(
    RexxObject *otherObj)              /* other comparison object           */
/******************************************************************************/
/* Function:  Primitive strict equal\not equal method.  This determines       */
/*            only strict equality, not greater or less than values.          */
/******************************************************************************/
{
    requiredArgument(otherObj, OREF_positional, ARG_ONE);         /* this is required.                 */
    if (otherObj == TheNilObject)        // strings never compare equal to the NIL object
    {
        return false;
    }

    RexxString *other = REQUEST_STRING(otherObj);    /* force into string form            */
    size_t otherLen = other->getLength();            /* get length of second string.      */
    if (otherLen != this->getLength())        /* lengths different?                */
    {
        return false;                      /* also unequal                      */
    }
                                           /* now compare the actual string     */
    return !memcmp(this->getStringData(), other->getStringData(), otherLen);
}


/**
 * Primitive string caseless comparison.
 *
 * @param otherObj The other string to compare.
 *
 * @return true if the strings compare, false otherwise.
 */
bool RexxString::primitiveCaselessIsEqual(RexxObject *otherObj)
{
    // we have one required string object
    requiredArgument(otherObj, OREF_positional, ARG_ONE);
    if (otherObj == TheNilObject)        // strings never compare equal to the NIL object
    {
        return false;
    }
    RexxString *other = REQUEST_STRING(otherObj);
    stringsize_t otherLen = other->getLength();
    // can't compare equal if different lengths
    if (otherLen != this->getLength())
    {
        return false;
    }
    // do the actual string compare
    return StringUtil::caselessCompare(this->getStringData(), other->getStringData(), otherLen) == 0;
}


/**
 * Wrapper around the compareTo() method for doing sort
 * comparison of strings.
 *
 * @param other  The other comparison object
 *
 * @return -1, 0, 1 depending on the comparison result.
 */
wholenumber_t RexxString::compareTo(RexxObject *other )
{
    if (this->isBaseClass())
    {
        return compareToRexx((RexxString *)other, OREF_NULL, OREF_NULL)->getValue();
    }
    else
    {
        return RexxObject::compareTo(other);
    }
}


wholenumber_t RexxString::comp(RexxObject *other, RexxString *alternativeOperator, RexxInteger **alternativeOperatorResultPtr)
/******************************************************************************/
/* Function:  Do a value comparison of two strings for the non-strict         */
/*            comparisons.  This returns for the compares:                    */
/*                                                                            */
/*             a value < 0 when this is smaller than other                    */
/*             a value   0 when this is equal to other                        */
/*             a value > 0 when this is larger than other                     */
/******************************************************************************/
{
    RexxString *second;                  /* string value of other             */
    RexxNumberString *firstNum;          /* numberstring value of this        */
    RexxNumberString *secondNum;         /* numberstring value of other       */
    const char *firstStart;              /* comparison start pointer          */
    const char *secondStart;             /* other start pointer               */
    size_t firstLen;                     /* this compare length               */
    size_t secondLen;                    /* other compare length              */
    wholenumber_t result;                /* compare result                    */

                                         /* We need to see if the objects can */
                                         /* be Converted to NumberString Objs */
                                         /* 1st, this way we know if the COMP */
                                         /* method of number String will      */
                                         /* succeed.  Will only fail if an    */
                                         /* object cannot be represented as a */
                                         /* number.  This is important since  */
                                         /* NumberString calls String to do   */
                                         /* the compare if it can't, since    */
                                         /* this is the method NumberString   */
                                         /* will call, we must make sure a    */
                                         /* call to NumberString succeeds or  */
                                         /* we will get into a loop.          */
    requiredArgument(other, OREF_positional, ARG_ONE);            /* make sure we have a real argument */
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return false;
    }

    // Before doing a string comparison, try the alternative operator, if any.
    // Do that only if 'other' is not a string and not a number and not an integer (no performance degradation)
    if (!isPolymorphicString(other))
    {
        if (alternativeOperator != OREF_NULL && alternativeOperatorResultPtr != NULL)
        {
            // Try an alternative operator
            // CAREFUL! Here, the operator returns a boolean result, not a value -1,0,1.
            // That's why a separated parameter is used to return this boolean result.
            ProtectedObject result;
            RexxObject *args[1];
            args[0] = this; // positional argument
            bool alternativeResult = other->messageSend(alternativeOperator, args, 1, 0, result, false);
            if (alternativeResult && (RexxObject *)result != OREF_NULL)
            {
                *alternativeOperatorResultPtr = (RexxInteger *)(RexxObject *)result;
                return 0; // You are not supposed to test this value, because *alternativeOperatorResultPtr is non NULL
            }
        }
    }

                                         /* try and convert both numbers      */
    firstNum = this->fastNumberString();
    secondNum = other->numberString();
    if (firstNum != OREF_NULL && secondNum != OREF_NULL)
    //if (((firstNum = this->fastNumberString()) != OREF_NULL) && ((secondNum = other->numberString()) != OREF_NULL ))
    {
        /* yes, send converted numbers and do*/
        /* the compare                       */
        return firstNum->comp(secondNum);
    }

    second = REQUEST_STRING(other);      /* yes, get a string object.         */
                                         /* objects are converted.  now strip */
                                         /* any leading/trailing blanks.      */

    firstLen = this->getLength();             /* get the initial length            */
    firstStart = this->getStringData(); /* and starting position           */

    secondLen = second->getLength();          /* get length of second string.      */
    secondStart = second->getStringData(); /* get pointer to start of data */

    /* while we have leading blanks.     */
    while (firstLen > 0 && (*firstStart == ch_BLANK || *firstStart == ch_TAB))
    {
        firstStart++;                       /* ignore character and look at next */
        firstLen--;                         /* and string is now one char less.  */
    }
    /* while we have leading blanks.     */
    while (secondLen > 0 && (*secondStart == ch_BLANK || *secondStart == ch_TAB))
    {
        secondStart++;                      /* ignore character and look at next */
        secondLen--;                        /* and string is now one char less.  */
    }

    if (firstLen >= secondLen)
    {         /* determine the longer string.      */
              /* first string is larger,           */

              /* do a memory compare of strings,   */
              /* use length of smaller string.     */
        result = memcmp(firstStart, secondStart, secondLen);
        /* equal but different lengths?      */
        if ((result == 0) && (firstLen != secondLen))
        {
            /* point to first remainder char     */
            firstStart = firstStart + secondLen;
            while (firstLen-- > secondLen)
            { /* while still have more to compare  */
                // Need unsigned char or chars above 0x7f will compare as less than
                // blank.
                unsigned char current = *firstStart++;
                if (current != ch_BLANK && current != ch_TAB)
                {
                    return current - ch_BLANK;
                }
            }
        }
    }

    else
    {                               /* The length of second obj is longer*/
                                    /* do memory compare of strings, use */
                                    /*  length of smaller string.        */
        result = memcmp(firstStart, secondStart, firstLen);
        if (result == 0)
        {                /* if strings compared equal, we have*/
                         /* we need to compare the trailing   */
                         /* part with blanks                  */
            secondStart = secondStart + firstLen;
            while (secondLen-- > firstLen)
            { /* while the longer string stills has*/
                // Need unsigned char or chars above 0x7f will compare as less than
                // blank.
                unsigned char current = *secondStart++;
                if (current != ch_BLANK && current != ch_TAB)
                {
                    return ch_BLANK - current;
                }
            }
        }
    }
    return result;                       /* return the compare result         */
}

wholenumber_t RexxString::strictComp(RexxObject *otherObj, RexxString *alternativeOperator, RexxInteger **alternativeOperatorResultPtr)
/******************************************************************************/
/* Function:  Do a strict comparison of two strings.  This returns:           */
/*                                                                            */
/*             a value < 0 when this is smaller than other                    */
/*             a value   0 when this is equal to other                        */
/*             a value > 0 when this is larger than other                     */
/******************************************************************************/
{
    wholenumber_t result;                /* compare result                    */

    requiredArgument(otherObj, OREF_positional, ARG_ONE);         /* this is required.                 */

    // Before doing a string comparison, try the alternative operator, if any.
    // Do that only if 'other' is not a string and not a number and not an integer (no performance degradation)
    if (!isPolymorphicString(otherObj))
    {
        if (alternativeOperator != OREF_NULL && alternativeOperatorResultPtr != NULL)
        {
            // Try an alternative operator
            // CAREFUL! Here, the operator returns a boolean result, not a value -1,0,1.
            // That's why a separated parameter is used to return this boolean result.
            ProtectedObject result;
            RexxObject *args[1];
            args[0] = this; // positional argument
            bool alternativeResult = otherObj->messageSend(alternativeOperator, args, 1, 0, result, false);
            if (alternativeResult && (RexxObject *)result != OREF_NULL)
            {
                *alternativeOperatorResultPtr = (RexxInteger *)(RexxObject *)result;
                return 0; // You are not supposed to test this value, because *alternativeOperatorResultPtr is non NULL
            }
        }
    }

    RexxString *other = REQUEST_STRING(otherObj);    /* force into string form            */
    size_t otherLen = other->getLength();       /* get length of second string.      */
    const char *otherData = other->getStringData();  /* get pointer to start of data.     */

    if (this->getLength() >= otherLen)
    {      /* determine the longer string.      */
        /* first string is larger,           */
        /* do a memory compare of strings,   */
        /* use length of smaller string.     */
        result = memcmp(this->getStringData(), otherData, otherLen);
        /* if strings are equal, and         */
        /* are not equal, the self is greater*/
        if ((result == 0) && (this->getLength() > otherLen))
        {
            result = 1;                      /* otherwise they are equal.         */
        }
    }
    else
    {                               /* The length of second obj is longer*/
                                    /* do memory compare of strings, use */
                                    /*  length of smaller string.        */
        result = memcmp(this->getStringData(), otherData, this->getLength());
        if (result == 0)                  /* if stings compared equal,         */
        {
            result = -1;                  /*  then the other string is bigger. */
        }
    }
    return result;                       /* finished, return our result       */
}

// in behaviour
RexxObject *RexxString::plus(RexxObject *right_term)
/******************************************************************************/
/* Function:  String addition...performed by RexxNumberString                 */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *self = this;
        if (right_term == OREF_NULL)
        {
            bool alternativeResult = this->messageSend(OREF_PLUS_LEFT, OREF_NULL, 0, 0, result, false);
            if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
        }
        else
        {
            if (right_term->classObject() == TheIntegerClass || right_term->classObject() == TheNumberStringClass) right_term = right_term->stringValue();
            RexxObject *args[1];
            args[0] = self; // positional argument
            bool alternativeResult = right_term->messageSend(OREF_PLUS_RIGHT, args, 1, 0, result, false);
            if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
        }
        /* this is a conversion error        */
        reportException(Error_Conversion_operator, this);
    }
    return numstr->plus(right_term);     /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::minus(RexxObject *right_term)
/******************************************************************************/
/* Function:  String subtraction...performed by RexxNumberString              */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *self = this;
        if (right_term == OREF_NULL)
        {
            bool alternativeResult = this->messageSend(OREF_SUBTRACT_LEFT, OREF_NULL, 0, 0, result, false);
            if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
        }
        else
        {
            if (right_term->classObject() == TheIntegerClass || right_term->classObject() == TheNumberStringClass) right_term = right_term->stringValue();
            RexxObject *args[1];
            args[0] = self; // positional argument
            bool alternativeResult = right_term->messageSend(OREF_SUBTRACT_RIGHT, args, 1, 0, result, false);
            if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
        }
        /* this is a conversion error        */
        reportException(Error_Conversion_operator, this);
    }
    return numstr->minus(right_term);    /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::multiply(RexxObject *right_term)
/******************************************************************************/
/* Function:  String multiplication...performed by RexxNumberString           */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *self = this;
        if (right_term->classObject() == TheIntegerClass || right_term->classObject() == TheNumberStringClass) right_term = right_term->stringValue();
        RexxObject *args[1];
        args[0] = self; // positional argument
        bool alternativeResult = right_term->messageSend(OREF_MULTIPLY_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
        /* this is a conversion error        */
        reportException(Error_Conversion_operator, this);
    }
    return numstr->multiply(right_term); /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::divide(RexxObject *right_term)
/******************************************************************************/
/* Function:  String division...performed by RexxNumberString                 */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *self = this;
        if (right_term->classObject() == TheIntegerClass || right_term->classObject() == TheNumberStringClass) right_term = right_term->stringValue();
        RexxObject *args[1];
        args[0] = self; // positional argument
        bool alternativeResult = right_term->messageSend(OREF_DIVIDE_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
        /* this is a conversion error        */
        reportException(Error_Conversion_operator, this);
    }
    return numstr->divide(right_term);   /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::integerDivide(RexxObject *right_term)
/******************************************************************************/
/* Function:  String division...performed by RexxNumberString                 */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *self = this;
        if (right_term->classObject() == TheIntegerClass || right_term->classObject() == TheNumberStringClass) right_term = right_term->stringValue();
        RexxObject *args[1];
        args[0] = self; // positional argument
        bool alternativeResult = right_term->messageSend(OREF_INTDIV_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
        /* this is a conversion error        */
        reportException(Error_Conversion_operator, this);
    }
    return numstr->integerDivide(right_term); /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::remainder(RexxObject *right_term)
/******************************************************************************/
/* Function:  String division...performed by RexxNumberString                 */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *self = this;
        if (right_term->classObject() == TheIntegerClass || right_term->classObject() == TheNumberStringClass) right_term = right_term->stringValue();
        RexxObject *args[1];
        args[0] = self; // positional argument
        bool alternativeResult = right_term->messageSend(OREF_REMAINDER_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
        /* this is a conversion error        */
        reportException(Error_Conversion_operator, this);
    }
    return numstr->remainder(right_term);     /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::power(RexxObject *right_term)
/******************************************************************************/
/* Function:  String division...performed by RexxNumberString                 */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *self = this;
        if (right_term->classObject() == TheIntegerClass || right_term->classObject() == TheNumberStringClass) right_term = right_term->stringValue();
        RexxObject *args[1];
        args[0] = self; // positional argument
        bool alternativeResult = right_term->messageSend(OREF_POWER_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
        /* this is a conversion error        */
        reportException(Error_Conversion_operator, this);
    }
    return numstr->power(right_term);    /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::abs(void)
/******************************************************************************/
/* Function:  String absolute value...performed by RexxNumberString           */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        /* this is a conversion error        */
        reportException(Error_Incorrect_method_string_nonumber, CHAR_ABS, this);
    }
    return numstr->abs();                /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::sign(void)
/******************************************************************************/
/* Function:  String sign value...performed by RexxNumberString               */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        /* this is a conversion error        */
        reportException(Error_Incorrect_method_string_nonumber, CHAR_SIGN, this);
    }
    return numstr->Sign();               /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::Max(RexxObject **arguments, size_t argCount, size_t named_argCount)
/******************************************************************************/
/* Function:  String max value...performed by RexxNumberString                */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        /* this is a conversion error        */
        reportException(Error_Incorrect_method_string_nonumber, CHAR_ORXMAX, this);
    }
    /* have numberstring do this         */
    return numstr->Max(arguments, argCount, named_argCount);
}

// in behaviour
RexxObject *RexxString::Min(RexxObject **arguments, size_t argCount, size_t named_argCount)
/******************************************************************************/
/* Function:  String min value...performed by RexxNumberString                */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        /* this is a conversion error        */
        reportException(Error_Incorrect_method_string_nonumber, CHAR_ORXMIN, this);
    }
    /* have numberstring do this         */
    return numstr->Min(arguments, argCount, named_argCount);
}

// in behaviour
RexxObject *RexxString::trunc(RexxInteger *decimals)
/******************************************************************************/
/* Function:  String Trunc...performed by RexxNumberString                    */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        /* this is a conversion error        */
        reportException(Error_Incorrect_method_string_nonumber, CHAR_TRUNC, this);
    }
    return numstr->trunc(decimals);      /* have numberstring do this         */
}

/**
 * The String class version of the floor method.
 *
 * @return The formatted numeric version.
 */
RexxObject *RexxString::floor()
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        /* this is a conversion error        */
        reportException(Error_Incorrect_method_string_nonumber, "FLOOR", this);
    }
    return numstr->floor();      /* have numberstring do this         */
}

/**
 * The String class version of the ceiling method.
 *
 * @return The formatted numeric version.
 */
RexxObject *RexxString::ceiling()
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        /* this is a conversion error        */
        reportException(Error_Incorrect_method_string_nonumber, "CEILING", this);
    }
    return numstr->ceiling();      /* have numberstring do this         */
}

/**
 * The String class version of the round method.
 *
 * @return The formatted numeric version.
 */
RexxObject *RexxString::round()
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        /* this is a conversion error        */
        reportException(Error_Incorrect_method_string_nonumber, "ROUND", this);
    }
    return numstr->round();      /* have numberstring do this         */
}

// in behaviour
RexxObject *RexxString::format(RexxObject *Integers, RexxObject *Decimals, RexxObject *MathExp, RexxObject *ExpTrigger)
/******************************************************************************/
/* Function:  String Format...performed by RexxNumberString                   */
/******************************************************************************/
{
    RexxNumberString *numstr;            /* converted number string           */

                                         /* non-numeric?                      */
    if ((numstr = this->fastNumberString()) == OREF_NULL)
    {
        /* this is a conversion error        */
        reportException(Error_Incorrect_method_string_nonumber, CHAR_FORMAT, this);
    }
    /* have numberstring do this         */
    return numstr->formatRexx(Integers, Decimals, MathExp, ExpTrigger);
}


/**
 * The string equals() method, which does a strict compare with
 * another string object.
 *
 * @param other  The other string object.
 *
 * @return True if the strings are equal, false for inequality.
 */
// in behaviour
RexxInteger *RexxString::equals(RexxString *other)
{
    return this->primitiveIsEqual(other) ? TheTrueObject : TheFalseObject;
}

/**
 * The string equals() method, which does a strict caseless
 * compare with another string object.
 *
 * @param other  The other string object.
 *
 * @return True if the strings are equal, false for inequality.
 */
// in behaviour
RexxInteger *RexxString::caselessEquals(RexxString *other)
{
    return this->primitiveCaselessIsEqual(other) ? TheTrueObject : TheFalseObject;
}


// in behaviour
RexxInteger *RexxString::strictEqual(RexxObject *other)
/******************************************************************************/
/* Function:  Strict ("==") equality operator...also returns the hash value   */
/*            if sent with no other object                                    */
/******************************************************************************/
{
    // Before doing a string comparison, try the alternative operator, if any.
    // Do that only if 'other' is not a string and not a number and not an integer (no performance degradation)
    if (other != OREF_NULL && !isPolymorphicString(other))
    {
        if (other == TheNilObject)        // strings never compare equal to the NIL object
        {
            return TheFalseObject;
        }
        // Try an alternative operator
        ProtectedObject result;
        result = (RexxObject *)OREF_NULL;
        RexxObject *args[1];
        args[0] = this; // positional argument
        bool alternativeResult = other->messageSend(OREF_STRICT_EQUAL_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxInteger *)(RexxObject *)result;
    }

    // legacy implementation
    return this->primitiveIsEqual(other) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::strictNotEqual(RexxObject *other)
/******************************************************************************/
/* Function:  Strict ("\==") inequality operator                              */
/******************************************************************************/
{
    // Before doing a string comparison, try the alternative operator, if any.
    // Do that only if 'other' is not a string and not a number and not an integer (no performance degradation)
    if (!isPolymorphicString(other))
    {
        if (other == TheNilObject)        // strings never compare equal to the NIL object
        {
            return TheTrueObject;
        }
        // Try an alternative operator
        ProtectedObject result;
        result = (RexxObject *)OREF_NULL;
        RexxObject *args[1];
        args[0] = this; // positional argument
        bool alternativeResult = other->messageSend(OREF_STRICT_BACKSLASH_EQUAL_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxInteger *)(RexxObject *)result;
    }

    // legacy implementation
    return !this->primitiveIsEqual(other) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::equal(RexxObject *other)
/******************************************************************************/
/* Function:  Non-strict ("=") string equality operator                       */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheFalseObject;
    }
    // return ((this->comp(other) == 0) ? TheTrueObject : TheFalseObject);
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->comp(other, OREF_EQUAL_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result == 0) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::notEqual(RexxObject *other)
/******************************************************************************/
/* Function:  Non-Strict ("\=") string inequality operator                    */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheTrueObject;
    }
    // return ((this->comp(other) != 0) ? TheTrueObject : TheFalseObject);
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->comp(other, OREF_BACKSLASH_EQUAL_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result != 0) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::isGreaterThan(RexxObject *other)
/******************************************************************************/
/* Function:  Non-strict greater than operator (">")                          */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheFalseObject;
    }
    // return ((this->comp(other) > 0) ? TheTrueObject : TheFalseObject);
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->comp(other, OREF_GREATERTHAN_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result > 0) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::isLessThan(RexxObject *other)
/******************************************************************************/
/* Function:  Non-strict less than operatore ("<")                            */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheFalseObject;
    }
    // return ((this->comp(other) < 0) ? TheTrueObject : TheFalseObject);
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->comp(other, OREF_LESSTHAN_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result < 0) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::isGreaterOrEqual(RexxObject *other)
/******************************************************************************/
/* Function:  Non-strict greater than or equal operator (">=" or "\<")        */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheFalseObject;
    }
    // return ((this->comp(other) >= 0) ? TheTrueObject : TheFalseObject);
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->comp(other, OREF_GREATERTHAN_EQUAL_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result >= 0) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::isLessOrEqual(RexxObject *other)
/******************************************************************************/
/* Function:  Non-strict less than or equal operator ("<=" or "\>")           */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheFalseObject;
    }
    // return ((this->comp(other) <= 0) ? TheTrueObject : TheFalseObject);
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->comp(other, OREF_LESSTHAN_EQUAL_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result <= 0) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::strictGreaterThan(RexxObject *other)
/******************************************************************************/
/* Function:  Strict greater than comparison (">>")                           */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheFalseObject;
    }
    // return (this->strictComp(other) > 0) ? TheTrueObject : TheFalseObject;
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->strictComp(other, OREF_STRICT_GREATERTHAN_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result > 0) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::strictLessThan(RexxObject *other)
/******************************************************************************/
/* Function:  Strict less than comparison ("<<")                              */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheFalseObject;
    }
    // return (this->strictComp(other) < 0) ? TheTrueObject : TheFalseObject;
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->strictComp(other, OREF_STRICT_LESSTHAN_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result < 0) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::strictGreaterOrEqual(RexxObject *other)
/******************************************************************************/
/* Function:  Strict greater than or equal to comparison (">>=" or "\<<")     */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheFalseObject;
    }
    // return (this->strictComp(other) >= 0) ? TheTrueObject : TheFalseObject;
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->strictComp(other, OREF_STRICT_GREATERTHAN_EQUAL_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result >= 0) ? TheTrueObject : TheFalseObject;
}

// in behaviour
RexxInteger *RexxString::strictLessOrEqual(RexxObject *other)
/******************************************************************************/
/* Function:  Strict less than or equal to operatore ("<<=" or "\>>")         */
/******************************************************************************/
{
    if (other == TheNilObject)           // all conditionals return .false when compared to .nil
    {
        return TheFalseObject;
    }
    // return (this->strictComp(other) <= 0) ? TheTrueObject : TheFalseObject;
    RexxInteger *alternativeResult = OREF_NULL;
    wholenumber_t result = this->strictComp(other, OREF_STRICT_LESSTHAN_EQUAL_RIGHT, &alternativeResult);
    if (alternativeResult != OREF_NULL) return alternativeResult;
    return (result <= 0) ? TheTrueObject : TheFalseObject;
}

RexxString *RexxString::concat(RexxString *other)
/******************************************************************************/
/* Function:  Concatenate two strings together                                */
/******************************************************************************/
{
    size_t blen1;                        /* length of first string            */
    size_t blen2;                        /* length of second string           */
    RexxString *result;                  /* result string                     */
    char *data;                          /* character pointer                 */

    blen1 = this->getLength();          /* get this length                   */
    blen2 = other->getLength();         /* and the other length              */

    if (blen2 == 0)                      // some people have taken to using a''b
    {
        // to perform concatenation operations
        return this;                     // it makes sense to optimize concatenation
    }                                    // with a null string by just returning
    if (blen1 == 0)                      // the non-null object.
    {
        return other;
    }
    /* create a new string               */
    result = (RexxString *)raw_string(blen1+blen2);
    data = result->getWritableData();    /* point to the string data          */

    // both lengths are non-zero because of the test above, so we can
    // unconditionally copy
    /* copy the front part               */
    memcpy(data, this->getStringData(), blen1);
    memcpy(data + blen1, other->getStringData(), blen2);
    return result;                       /* return the result                 */

}

// in behaviour
RexxString *RexxString::concatRexx(RexxObject *otherObj)
/******************************************************************************/
/* Function:  Rexx level concatenate...requires conversion and checking       */
/******************************************************************************/
{
    size_t blen1;                        /* length of first string            */
    size_t blen2;                        /* length of second string           */
    RexxString *result;                  /* result string                     */
    RexxString *other;
    char *data;                          /* character pointer                 */

    requiredArgument(otherObj, OREF_positional, ARG_ONE);         /* this is required.                 */
                                         /* ensure a string value             */

    if (!isPolymorphicString(otherObj))
    {
        // Give a chance for an alternative operator before REQUEST_STRING
        ProtectedObject result;
        RexxObject *self = this;
        RexxObject *args[1];
        args[0] = self; // positional argument
        bool alternativeResult = otherObj->messageSend(OREF_CONCATENATE_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxString *)(RexxObject *)result;
    }

    other = (RexxString *)REQUEST_STRING(otherObj);

    /* added error checking for NULL pointer (from NilObject) */
    if (other == OREF_NULL)
    {
        reportException(Error_Incorrect_method_nostring, OREF_positional, IntegerOne);
    }

    /* the following logic also appears  */
    /* in string_concat, but is repeated */
    /* here because this is a VERY high  */
    /* use function                      */
    blen1 = this->getLength();               /* get this length                   */
    blen2 = other->getLength();              /* and the other length              */
    /* create a new string               */
    result = (RexxString *)raw_string(blen1+blen2);
    data = result->getWritableData();    /* point to the string data          */
    if (blen1 != 0)
    {                     /* have real data?                   */
                          /* copy the front part               */
        memcpy(data, this->getStringData(), blen1);
        data += blen1;                     /* step past the length              */
    }
    if (blen2 != 0)                      /* have a second length              */
    {
        /* and the second part               */
        memcpy(data, other->getStringData(), blen2);
    }
    return result;                       /* return the result                 */
}

RexxString *RexxString::concatToCstring(const char *other)
/******************************************************************************/
/* Function:  Concatenate a string object onto an ASCII-Z string              */
/******************************************************************************/
{
    size_t blen1;                        /* length of first string            */
    size_t blen2;                        /* length of ASCII-Z string          */
    RexxString *result;                  /* result string                     */

    blen1 = this->getLength();          /* get this length                   */
    blen2 = strlen(other);               /* and the other length              */
                                         /* create a new string               */
    result = (RexxString *)raw_string(blen1+blen2);
    /* copy the front part               */
    memcpy(result->getWritableData(), other, blen2);
    /* and the second part               */
    memcpy(result->getWritableData() + blen2, this->getStringData(), blen1);
    return result;
}

RexxString *RexxString::concatWithCstring(const char *other)
/******************************************************************************/
/* Function:  Concatenate an ASCII-Z string onto a string object              */
/******************************************************************************/
{
    size_t blen1;                        /* length of first string            */
    size_t blen2;                        /* length of ASCII-Z string          */
    RexxString *result;                  /* result string                     */

    blen1 = this->getLength();          /* get this length                   */
    blen2 = strlen(other);               /* and the other length              */
                                         /* create a new string               */
    result = (RexxString *)raw_string(blen1+blen2);
    /* copy the string object            */
    memcpy(result->getWritableData(), this->getStringData(), blen1);
    /* copy the ASCII-Z string           */
    memcpy(result->getWritableData() + blen1, other, blen2);
    return result;
}

// in behaviour
RexxString *RexxString::concatBlank(RexxObject *otherObj)
/******************************************************************************/
/* Function:  Concatenate two strings with a blank in between                 */
/******************************************************************************/
{
    size_t blen1;                        /* length of first string            */
    size_t blen2;                        /* length of second string           */
    RexxString *result;                  /* result string                     */
    RexxString *other;                   /* result string                     */
    char *data;                          /* character pointer                 */

    requiredArgument(otherObj, OREF_positional, ARG_ONE);         /* this is required.                 */

    if (!isPolymorphicString(otherObj))
    {
        // Give a chance for an alternative operator before REQUEST_STRING
        ProtectedObject result;
        RexxObject *self = this;
        RexxObject *args[1];
        args[0] = self; // positional argument
        bool alternativeResult = otherObj->messageSend(OREF_BLANK_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxString *)(RexxObject *)result;
    }
                                         /* ensure a string value             */
    other = (RexxString *)REQUEST_STRING(otherObj);

    /* added error checking for NULL pointer (from NilObject) */
    if (other == OREF_NULL)
    {
        reportException(Error_Incorrect_method_nostring, OREF_positional, IntegerOne);
    }

    /* the following logic also appears  */
    /* in string_concat_with, but is     */
    /* repeated here because this is a   */
    /* VERY high use function            */
    blen1 = this->getLength();               /* get this length                   */
    blen2 = other->getLength();              /* and the other length              */
    /* create a new string               */
    result = (RexxString *)raw_string(blen1+blen2+1);
    data = result->getWritableData();    /* point to the string data          */
    if (blen1 != 0)
    {                     /* have a first string?              */
                          /* copy the front part               */
        memcpy(data, this->getStringData(), blen1);
        data += blen1;                   /* step past the length              */
    }
    *data++ = ' ';                       /* stuff in the seperating blank     */
    if (blen2 != 0)                      /* have a second string?             */
    {
        /* and the second part               */
        memcpy(data, other->getStringData(), blen2);
    }
    return result;
}

bool RexxString::truthValue(int errorCode)
/******************************************************************************/
/* Function:  Determine the truth value of a string object, raising the       */
/*            given error if bad.                                             */
/******************************************************************************/
{
    RexxString *testString;              /* string to test                    */

    if (!isOfClass(String, this))            /*  a nonprimitive object?           */
    {
        testString = this->requestString();/* get the real string value         */
    }
    else
    {
        testString = this;                 /* just use the string directly      */
    }
    if (testString->getLength() != 1)    /* not exactly 1 character long?     */
    {
        /* report the error                  */
        reportException(errorCode, testString);
    }
    if (*(testString->getStringData()) == '0')/* exactly '0'?                      */
    {
        return false;                    /* have a false                      */
    }
                                         /* not exactly '1'?                  */
    else if (!(*(testString->getStringData()) == '1'))
    {
        reportException(errorCode, this);/* report the error                  */
    }
    return true;                         /* this is true                      */
}


/**
 * Convert an object to a logical value without raising an
 * error.
 *
 * @param result The converted value.
 *
 * @return true if this converted ok, false for an invalid logical.
 */
bool RexxString::logicalValue(logical_t &result)
{
    RexxString *testString;              /* string to test                    */

    if (!isOfClass(String, this))            /*  a nonprimitive object?           */
    {
        testString = this->requestString();/* get the real string value         */
    }
    else
    {
        testString = this;                 /* just use the string directly      */
    }

    if (testString->getLength() != 1)    /* not exactly 1 character long?     */
    {
        return false;     // not a valid logical
    }
    if (testString->getChar(0) == '0')/* exactly '0'?                      */
    {
        result = false;                  // this is false and the conversion worked
        return true;
    }
                                         /* exactly '1'?                  */
    else if (testString->getChar(0) == '1')
    {
        result = true;                   // this is true and the conversion worked
        return true;
    }
    return false;       // did not convert correctly
}

bool RexxString::checkIsASCII()
{
    if (this->isASCIIChecked()) return this->isASCII();
    bool isASCII = StringUtil::checkIsASCII(this->getStringData(), this->getLength());
    this->setIsASCII(isASCII);
    this->setIsASCIIChecked(true);
    return isASCII;
}

// In behaviour
RexxInteger *RexxString::isASCIIRexx()
{
    return this->checkIsASCII() ? TheTrueObject : TheFalseObject;
}


bool RexxString::checkLower()
/******************************************************************************/
/* Function:  Tests for existence of lowercase characters                     */
/******************************************************************************/
{
    // Todo : current implementation works only for ascii:fixed_8 and iso-8859-1:fixed_8
    const char *data;                    /* current data pointer              */
    const char *endData;                 /* end location                      */

    data = this->getStringData();        /* point to the string               */
    endData = data + this->getLength();  /* set the end point                 */

    while (data < endData)
    {             /* loop through entire string        */
        if (*data != toupper(*data))
        {     /* have something to uppercase?      */
            this->setHasLower();             /* remember we have this             */
            return true;                     /* just return now                   */
        }
        data++;                            /* step the position                 */
    }
    /* no lowercase?                     */
    this->setUpperOnly();                /* set the upper only attribute      */
    return false;                        /* return then translation flag      */
}

RexxString *RexxString::upper()
/******************************************************************************/
/* Function:  Translate a string to uppercase...will only create a new        */
/*            string if characters actually have to be translated.            */
/******************************************************************************/
{
    RexxString *newstring;               /* newly created string              */
                                         /* something to uppercase?           */
    if (!this->upperOnly() && (this->hasLower() || this->checkLower()))
    {
        /* create a new string               */
        const char *data;                    /* current data pointer              */
        char * outdata;                      /* output data                       */
        const char *endData;                 /* end of the data                   */
        newstring = (RexxString *)raw_string(this->getLength());
        data = this->getStringData();      /* point to the data start           */
                                           /* point to output data              */
        outdata = newstring->getWritableData();
        endData = data + this->getLength();    /* set the loop terminator           */
        while (data < endData)
        {           /* loop through entire string        */
            *outdata = toupper(*data);       /* copy the uppercase character      */
            data++;                          /* step the position                 */
            outdata++;                       /* and the output position           */
        }
        return newstring;                  /* return the new string             */
    }
    return this;                         /* return this unchanged             */
}

RexxString *RexxString::stringTrace()
/******************************************************************************/
/* Function:  Translate a string to "traceable" form, removing non-displayable*/
/*            characters                                                      */
/******************************************************************************/
{
    RexxString *newCopy;                 /* new copy of string                */
    // NOTE:  since we're doing value comparisons on single character values here,
    // we need to process this as unsigned characters to handle values
    // greater than 0x7f.
    const unsigned char *Current;        /* current string location           */
    size_t    i;                         /* string length                     */
    bool      NonDisplay;                /* have non-displayables             */

    i = this->getLength();               /* get the length                    */
                                         /* point to the start                */
    Current = (const unsigned char *)this->getStringData();
    NonDisplay = false;                  /* no non-displayable characters     */

    for (; i > 0; i--)
    {                 /* loop for the entire string        */
                      /* control character?                */
        if (*Current < ch_SPACE)
        {
            NonDisplay = true;               /* got a non-displayable             */
            break;                           /* get out of here                   */
        }
        Current++;                         /* step the pointer                  */
    }
    if (!NonDisplay)                     /* all displayable?                  */
    {
        return this;                       /* leave unchanged                   */
    }
                                           /* copy the string                   */
    newCopy = (RexxString *) this->copy();
    i = newCopy->getLength();                 /* get the length                    */
    /* point to the start                */
    char *outptr = newCopy->getWritableData();

    for (; i > 0; i--)
    {                 /* loop for the entire string        */
                      /* control character?                */
        if (*outptr < ch_SPACE && *outptr != ch_TAB)
        {
            *outptr = '?';                 /* yes, change to question           */
        }
        outptr++;                        /* step the pointer                  */
    }
    return newCopy;                      /* return the converted string       */
}


RexxString *RexxString::lower()
/******************************************************************************/
/* Function:  Translate a string to lower case                                */
/******************************************************************************/
{
    RexxString *newstring;               /* newly created string              */
    const char *   data;                 /* current data pointer              */
    char *         outdata;              /* output data                       */
    size_t i;                            /* loop counter                      */
    bool   needTranslation;              /* translation required              */

    data = this->getStringData();        /* point to the string               */
    needTranslation = false;             /* no translation required           */

    for (i = 0; i < this->getLength(); i++)
    { /* loop through entire string        */
        if (*data != tolower(*data))
        {     /* have something to lowercase?      */
            needTranslation = true;          /* flag it                           */
            break;                           /* stop at the first one             */
        }
        data++;                            /* step the position                 */
    }
    if (needTranslation)
    {               /* something to uppercase?           */
                    /* create a new string               */
        newstring = (RexxString *)raw_string(this->getLength());
        data = this->getStringData();      /* point to the data start           */
                                           /* point to output data              */
        outdata = newstring->getWritableData();
        /* loop through entire string        */
        for (i = 0; i < this->getLength(); i++)
        {
            *outdata = tolower(*data);       /* copy the lowercase character      */
            data++;                          /* step the position                 */
            outdata++;                       /* and the output position           */
        }
    }
    else
    {
        newstring = this;                  /* return untranslated string        */
    }
    return newstring;                    /* return the new copy               */
}


/**
 * Rexx exported method stub for the lower() method.
 *
 * @param start  The optional starting location.  Defaults to the first character
 *               if not specified.
 * @param length The length to convert.  Defaults to the segment from the start
 *               position to the end of the string.
 *
 * @return A new string object with the case conversion applied.
 */
// in behaviour
RexxString *RexxString::lowerRexx(RexxInteger *_start, RexxInteger *_length)
{
    size_t startPos = optionalPositionArgument(_start, 1, ARG_ONE) - 1;
    size_t rangeLength = optionalLengthArgument(_length, getLength(), ARG_TWO);

    // if we're starting beyond the end bounds, return unchanged
    if (startPos >= getLength())
    {
        return this;
    }

    rangeLength = Numerics::minVal(rangeLength, getLength() - startPos);

    // a zero length value is also a non-change.
    if (rangeLength == 0)
    {
        return this;
    }

    return lower(startPos, rangeLength);
}


/**
 * Rexx exported method stub for the upper() method.
 *
 * @param start  The optional starting location.  Defaults to the first character
 *               if not specified.
 * @param length The length to convert.  Defaults to the segment from the start
 *               position to the end of the string.
 *
 * @return A new string object with the case conversion applied.
 */
// in behaviour
RexxString *RexxString::upperRexx(RexxInteger *_start, RexxInteger *_length)
{
    size_t startPos = optionalPositionArgument(_start, 1, ARG_ONE) - 1;
    size_t rangeLength = optionalLengthArgument(_length, getLength(), ARG_TWO);

    // if we're starting beyond the end bounds, return unchanged
    if (startPos >= getLength())
    {
        return this;
    }

    rangeLength = Numerics::minVal(rangeLength, getLength() - startPos);

    // a zero length value is also a non-change.
    if (rangeLength == 0)
    {
        return this;
    }

    return upper(startPos, rangeLength);
}



/**
 * Lowercase a portion of a Rexx string, returning a new string object.  This
 * method assumes the offset and length are already valid
 * for this string object.
 *
 * @param start  The starting offset of the segment to lowercase (origin 0).
 *
 * @param length The length to lowercase.
 *
 * @return A new string object with the case conversion applied.
 */
RexxString *RexxString::lower(size_t offset, size_t _length)
{
    // get a copy of the string
    RexxString *newstring = extract(0, getLength());

    char *data = newstring->getWritableData() + offset;
    // now uppercase in place
    for (size_t i = 0; i < _length; i++)
    {
        *data = tolower(*data);
        data++;
    }
    return newstring;
}



/**
 * Uppercase a portion of a Rexx string, returning a new string
 * object.  This method assumes the offset and length are
 * already valid for this string object.
 *
 * @param start  The starting offset of the segment to uppercase
 *               (origin 0).
 *
 * @param length The length to lowercase.
 *
 * @return A new string object with the case conversion applied.
 */
RexxString *RexxString::upper(size_t offset, size_t _length)
{
    // get a copy of the string
    RexxString *newstring = extract(0, getLength());

    char *data = newstring->getWritableData() + offset;
    // now uppercase in place
    for (size_t i = 0; i < _length; i++)
    {
        *data = toupper(*data);
        data++;
    }
    return newstring;
}

RexxInteger *RexxString::integerValue(
    size_t digits)                     /* precision to use                  */
/******************************************************************************/
/* Function:  Convert a string object to an integer.  Returns .nil for        */
/*            failures.                                                       */
/******************************************************************************/
{
    RexxNumberString *numberStr;         /* string's numberstring version     */
    RexxInteger *newInteger;             /* returned integer string           */

                                         /* Force String conversion through   */
                                         /* NumberString                      */
                                         /* get the number string version     */
    if ((numberStr = this->fastNumberString()) != OREF_NULL )
    {
        /* try for an integer                */
        newInteger = numberStr->integerValue(digits);
        /* did it convert?                   */
        if (newInteger != TheNilObject && newInteger->getStringrep() == OREF_NULL)
        {
            newInteger->setString(this);     /* connect the string value          */
        }
        return newInteger;                 /* return the new integer            */
    }
    else
    {
        return(RexxInteger *)TheNilObject;/* return .nil for failures          */
    }
}

void RexxString::setNumberString(RexxObject *NumberRep)
/******************************************************************************/
/* Function:  Set a number string value on to the string                      */
/******************************************************************************/
{

    OrefSet(this, this->NumberString, (RexxNumberString *)NumberRep);

    if (NumberRep != OREF_NULL)          /* actually get one?                 */
    {
        this->setHasReferences();           /* Make sure we are sent Live...     */
    }
    else
    {
        // No longer do that because now we have also text and encoding references
        // this->setHasNoReferences();         /* no more references                */
    }
    return;
}

RexxString *RexxString::concatWith(RexxString *other,
                                   char        between)
/******************************************************************************/
/* Function:  Concatenate two strings with a single character between         */
/******************************************************************************/
{
    size_t blen1;                        /* length of first string            */
    size_t blen2;                        /* length of second string           */
    RexxString *result;                  /* result string                     */
    char *data;                          /* character pointer                 */

    blen1 = this->getLength();          /* get this length                   */
    blen2 = other->getLength();         /* and the other length              */
    /* create a new string               */
    result = (RexxString *)raw_string(blen1+blen2+1);
    data = result->getWritableData();         /* point to the string data          */
    if (blen1 != 0)
    {                     /* have a first string?              */
                          /* copy the front part               */
        memcpy(data, this->getStringData(), blen1);
        data += blen1;                   /* step past the length              */
    }
    *data++ = between;                   /* stuff in the seperating char      */
    if (blen2 != 0)                      /* have a second string?             */
    {
        /* and the second part               */
        memcpy(data, other->getStringData(), blen2);
    }
    return result;
}

// in beahviour
RexxObject *RexxString::andOp(RexxObject *other)
/******************************************************************************/
/* Function:  Logical AND of a string with another logical value              */
/******************************************************************************/
{
    RexxObject *otherTruth;              /* truth value of the other object   */

    requiredArgument(other, OREF_positional, ARG_ONE);            /* make sure the argument is there   */

    // Before doing a logical value operation, try the alternative operator, if any.
    // Do that only if 'other' is not a string and not a number and not an integer (no performance degradation)
    if (!isPolymorphicString(other))
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *args[1];
        args[0] = this; // positional argument
        bool alternativeResult = other->messageSend(OREF_AND_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
    }

                                         /* validate the boolean              */
    // jlf: check first the left side, it's more clear to report an error about the left side when both sides are wrong
    // otherwise you have the wrong impression that only the right side is wrong (the evaluation is from left to right)
    bool thisTruthValue = this->truthValue(Error_Logical_value_method);
    otherTruth = other->truthValue(Error_Logical_value_method) ? TheTrueObject : TheFalseObject;
    /* perform the operation             */
    return(!thisTruthValue) ? TheFalseObject : otherTruth;
}

// in behaviour
RexxObject *RexxString::orOp(RexxObject *other)
/******************************************************************************/
/* Function:  Logical OR of a string with another logical value               */
/******************************************************************************/
{
    RexxObject *otherTruth;              /* truth value of the other object   */

    requiredArgument(other, OREF_positional, ARG_ONE);            /* make sure the argument is there   */

    // Before doing a logical value operation, try the alternative operator, if any.
    // Do that only if 'other' is not a string and not a number and not an integer (no performance degradation)
    if (!isPolymorphicString(other))
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *args[1];
        args[0] = this; // positional argument
        bool alternativeResult = other->messageSend(OREF_OR_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
    }

                                         /* validate the boolean              */
    // jlf: check first the left side, it's more clear to report an error about the left side when both sides are wrong
    // otherwise you have the wrong impression that only the right side is wrong (the evaluation is from left to right)
    bool thisTruthValue = this->truthValue(Error_Logical_value_method);
    otherTruth = other->truthValue(Error_Logical_value_method) ? TheTrueObject : TheFalseObject;
    /* perform the operation             */
    return(thisTruthValue) ? TheTrueObject : otherTruth;
}

// in behaviour
RexxObject *RexxString::xorOp(RexxObject *other)
/******************************************************************************/
/* Function:  Logical XOR of a string with another logical value              */
/******************************************************************************/
{
    requiredArgument(other, OREF_positional, ARG_ONE);            /* make sure the argument is there   */

    // Before doing a logical value operation, try the alternative operator, if any.
    // Do that only if 'other' is not a string and not a number and not an integer (no performance degradation)
    if (!isPolymorphicString(other))
    {
        // Try an alternative operator
        ProtectedObject result;
        RexxObject *args[1];
        args[0] = this; // positional argument
        bool alternativeResult = other->messageSend(OREF_XOR_RIGHT, args, 1, 0, result, false);
        if (alternativeResult && (RexxObject *)result != OREF_NULL) return (RexxObject *)result;
    }

                                         /* get as a boolean                  */
    // jlf: check first the left side, it's more clear to report an error about the left side when both sides are wrong
    // otherwise you have the wrong impression that only the right side is wrong (the evaluation is from left to right)
    bool thisTruthValue = this->truthValue(Error_Logical_value_method);
    bool truth = other->truthValue(Error_Logical_value_method);
    /* first one false?                  */
    if (!thisTruthValue)
    {
        /* value is always the second        */
        return truth ? TheTrueObject : TheFalseObject;
    }
    else                                 /* value is inverse of second        */
    {
        return(truth) ? TheFalseObject : TheTrueObject;
    }
}

// in behaviour
RexxArray *RexxString::makeArrayRexx(RexxString *div)
/******************************************************************************/
/* Function:  Split string into an array                                      */
/******************************************************************************/
{
    return StringUtil::makearray(this, div);
}


// in beahviour
RexxObject *RexxString::notOp()
/******************************************************************************/
/* Function:  Logical NOT of a string                                         */
/******************************************************************************/
{
  return this->truthValue(Error_Logical_value_method) ? (RexxObject *)TheFalseObject : (RexxObject *)TheTrueObject;
}

RexxObject *RexxString::operatorNot(RexxObject *other)
/******************************************************************************/
/* Function:  Logical NOT of a string                                         */
/******************************************************************************/
{
  return this->truthValue(Error_Logical_value_method) ? (RexxObject *)TheFalseObject : (RexxObject *)TheTrueObject;
}

RexxObject *RexxString::isInteger()
/******************************************************************************/
/* Function:  Test if this string is an integer value                         */
/******************************************************************************/
{
    const char *digitPtr;
    size_t digitsLeft;

    digitPtr = this->getStringData();
    digitsLeft = this->getLength();

    /* Skip all leading blanks           */
    for (; digitsLeft != 0 && (*digitPtr == ch_BLANK || *digitPtr == ch_TAB); ++digitPtr, --digitsLeft) ;

    if (digitsLeft != 0)
    {                   /* Still Digits left ?               */
        if (*digitPtr == ch_PLUS || *digitPtr == ch_MINUS)
        {
            /* need to move past the sign and    */
            /*  remove any remaining blanks.     */
            for (++digitPtr, --digitsLeft;
                digitsLeft != 0 && (*digitPtr == ch_BLANK || *digitPtr == ch_TAB);
                ++digitPtr, --digitsLeft) ;
            /* Yes, skip any blanks              */
            if (digitsLeft == 0)                /* Did we reach end of data ?        */
            {
                /* Yes, not valid                    */
                return TheFalseObject;
            }
        }
        /* we are now ready to check for     */
        /*digits                             */
        for (; digitsLeft != 0 && *digitPtr >= ch_ZERO && *digitPtr <= ch_NINE;
            ++digitPtr, --digitsLeft) ;
        /* found our first non-digit, or end */
        /* is it a decimal point?            */
        if ( digitsLeft != 0 && *digitPtr == ch_PERIOD)
        {
            digitPtr++;                      /* Yes, see if remaining digits are 0*/
            digitsLeft--;
            for (; digitsLeft != 0 && *digitPtr == ch_ZERO; ++digitPtr, --digitsLeft) ;
        }
        /* if chars left make sure all are   */
        /* blanks.                           */
        for (; digitsLeft != 0 && (*digitPtr == ch_BLANK || *digitPtr == ch_TAB); ++digitPtr, --digitsLeft) ;
        /* skipped all trailing blanks.      */
        /* we better be at the end of the    */
        /* string, otherwise its invalid.    */
        if (digitsLeft == 0)
        {
            /* yes its the end, return true      */
            return TheTrueObject;
        }
    }

    /* all other cases are invalid....   */
    return(RexxObject *) TheFalseObject;
}

RexxObject *RexxString::evaluate(
    RexxActivation      *context,      /* current activation context        */
    RexxExpressionStack *stack )       /* evaluation stack                  */
/******************************************************************************/
/* Function:  Polymorphic method that makes string a polymorphic expression   */
/*            term for string literals.                                       */
/******************************************************************************/
{
    RexxObject *value = this;    // by default, evaluate to itself
    if (this->text == OREF_NULL) // this->text can be the text counterpart, or this, or OREF_NULL
    {
        // First evaluation
        this->setText(this); // By default, evaluate to itself.
                             // Also used as a flag to know that the string literal has been evaluated (not OREF_NULL).

        PackageClass *package = context->getPackage();
        RexxObject *packageEncoding = OREF_NULL;
        const char *packageEncodingName = "<NULL>";
        ProtectedObject result;
        // OREF_SETENCODING instead of OREF_ENCODING:
        // With a single message, force the package's encoding to be stored, if not already done, and retrieve its encoding
        bool messageUnderstood = package->messageSend(OREF_SETENCODING, OREF_NULL, 0, 0, result, false);
        if (messageUnderstood && (RexxObject *)result != OREF_NULL) // the package has an encoding
        {
            packageEncoding = (RexxObject *)result;
        }
        ProtectedObject p_packageEncoding(packageEncoding);

        if (this->checkIsASCII() == false) // don't convert ASCII strings
        {
            if (packageEncoding != OREF_NULL)
            {
                messageUnderstood = packageEncoding->messageSend(OREF_ISBYTE, OREF_NULL, 0, 0, result, false);
                if (messageUnderstood && ((RexxObject *)result)->integerValue(9)->getValue() == 0) // not byte encoding
                {
                    // The string has currently no encoding (1st evaluation).
                    // Must store the package encoding on the string before requesting a RexxText
                    // otherwise the resulting text encoding will be the default encoding.
                    RexxObject *args[1];
                    args[0] = packageEncoding; // positional argument
                    bool messageUnderstood = this->messageSend(OREF_SETENCODING, args, 1, 0, result, false);
                    // OREF_SETENCODING do that: this~!setEncoding(packageEncoding);

                    // Convert to RexxText
                    // REMEMBER!
                    // Don't use the C++ methods RexxObject::makeText or RexxObject::textValue or RexxObject::requestText
                    // That would be too costly when the package text.cls is not loaded because they would forward UNKNOWN.
                    // Here, the messageSend will not forward UNKNOWN if the message OREF_TEXT is not understood.
                    messageUnderstood = this->messageSend(OREF_TEXT, OREF_NULL, 0, 0, result, false);
                    if (messageUnderstood && (RexxObject *)result != OREF_NULL)
                    {
                        this->setText((RexxObject *)result);
                        this->setevaluateAsText();
                    }
                }
            }
        }
        value = this->text;
        if (this->encoding == OREF_NULL && packageEncoding != OREF_NULL)
        {
            ProtectedObject p_value(value);
            // The encoding of this value is equal to the encoding of the package
            RexxObject *args[1];
            args[0] = packageEncoding; // positional argument
            bool messageUnderstood = value->messageSend(OREF_SETENCODING, args, 1, 0, result, false);
            // OREF_SETENCODING do that: value~!setEncoding(packageEncoding);
        }
    }
    else
    {
        // Not first evaluation
        if (this->evaluateAsText()) value = this->text;
    }
    stack->push((RexxObject *)value);     /* place on the evaluation stack     */
                                          /* trace if necessary                */
    context->traceIntermediate((RexxObject *)value, TRACE_PREFIX_LITERAL);
    return value;                         /* also return the result            */
}


/**
 * Copy a string to an RXSTRING, with appropriate allocation
 * of a new buffer if required.
 *
 * @param r
 */
void RexxString::copyToRxstring(RXSTRING &r)
{
    size_t result_length = getLength() + 1;
    if (r.strptr == NULL || r.strlength < result_length)
    {
        r.strptr = (char *)SystemInterpreter::allocateResultMemory(result_length);
    }
    // copy all of the data + the terminating null
    memcpy(r.strptr, getStringData(), result_length);
    // fill in the length too
    r.strlength = getLength();
}


RexxObject  *RexxString::getValue(
    RexxActivation *context)           /* current activation context        */
/******************************************************************************/
/* Function:  Polymorphic get_value function used with expression terms       */
/******************************************************************************/
{
  return (RexxObject *)this;           /* just return this value            */
}


RexxObject  *RexxString::getValue(
    RexxVariableDictionary *context)   /* current activation context        */
/******************************************************************************/
/* Function:  Polymorphic get_value function used with expression terms       */
/******************************************************************************/
{
  return (RexxObject *)this;           /* just return this value            */
}


RexxObject  *RexxString::getRealValue(
    RexxActivation *context)           /* current activation context        */
/******************************************************************************/
/* Function:  Polymorphic get_value function used with expression terms       */
/******************************************************************************/
{
  return (RexxObject *)this;           /* just return this value            */
}


RexxObject  *RexxString::getRealValue(
    RexxVariableDictionary *context)   /* current activation context        */
/******************************************************************************/
/* Function:  Polymorphic get_value function used with expression terms       */
/******************************************************************************/
{
  return (RexxObject *)this;           /* just return this value            */
}


RexxString *RexxString::newString(const char *string, size_t blength)
/******************************************************************************/
/* Function:  Allocate (and initialize) a string object                       */
/******************************************************************************/
{
    /* calculate the size                */
    /* STRINGOBJ - excess chars (3)      */
    /* + length. only sub 3 to allow     */
    /* for terminating NULL              */
    size_t size2 = sizeof(RexxString) - (sizeof(char) * 3) + blength;
    /* allocate the new object           */
    RexxString *newObj = (RexxString *)new_object(size2, T_String);
    /* clear the front part              */
    newObj->setLength(blength);         /* save the length in bytes          */
    newObj->hashValue = 0;               // make sure the hash value is zeroed
                                         /* Null terminate, allows faster     */
                                         /* conversion to ASCII-Z string      */
    newObj->putChar(blength, '\0');
    /* copy it over                      */
    newObj->put(0, string, blength);

    newObj->setEncoding(OREF_NULL);
    newObj->setText(OREF_NULL);

    /* by  default, we don't need Live   */
    newObj->setHasNoReferences();        /*sent                               */

                                         /* NOTE: That if we can set          */
                                         /*  this->NumebrString elsewhere     */
                                         /*we need to mark ourselves as       */
    return newObj;                       /*having OREFs                       */
}

RexxString *RexxString::rawString(size_t blength)
/******************************************************************************/
/* Function:  Allocate (and initialize) an empty string object                */
/******************************************************************************/
{
                                       /* calculate the size                */
                                       /* STRINGOBJ - excess chars (3)      */
                                       /* + length. only sub 3 to allow     */
                                       /* for terminating NULL              */
  size_t size2 = sizeof(RexxString) - (sizeof(char) * 3) + blength;
                                       /* allocate the new object           */
  RexxString *newObj = (RexxString *)new_object(size2, T_String);
  newObj->setLength(blength);         /* save the length in bytes          */
  newObj->hashValue = 0;               // make sure the hash value is zeroed
                                       /* Null terminate, allows faster     */
                                       /* conversion to ASCII-Z string      */
  newObj->putChar(blength, '\0');

  newObj->setEncoding(OREF_NULL);
  newObj->setText(OREF_NULL);

                                       /* by  default, we don't need Live   */
  newObj->setHasNoReferences();        /*sent                               */

                                       /* NOTE: That if we can set          */
                                       /*  this->NumebrString elsewhere     */
                                       /*we need to mark ourselves as       */
  return newObj;                       /*having OREFs                       */
}

/**
 * Allocate an initialize a string object that will also
 * contain only uppercase characters.  This allows a creation
 * and uppercase operation to be done in one shot, without
 * requiring two string objects to be created.
 *
 * @param string The source string data.
 * @param blength The length in bytes of the string data.
 * @param clength The length in characters of the string data.
 *
 * @return A newly constructed string object.
 */
RexxString *RexxString::newUpperString(const char * string, stringsize_t blength)
{
    // Todo : current implementation works only for ascii:fixed_8 and iso-8859-1:fixed_8
    /* calculate the size                */
    /* STRINGOBJ - excess chars (3)      */
    /* + length. only sub 3 to allow     */
    /* for terminating NULL              */
    size_t size2 = sizeof(RexxString) - (sizeof(char) * 3) + blength;
    /* allocate the new object           */
    RexxString *newObj = (RexxString *)new_object(size2, T_String);
    newObj->setLength(blength);         /* save the length in bytes          */
    newObj->hashValue = 0;               // make sure the hash value is zeroed
                                         /* create a new string               */
                                         /* point to output data              */
    char *outdata = newObj->getWritableData();
    // set the input markers
    const char *indata = string;
    const char *endData = indata + blength;
    while (indata < endData)             /* loop through entire string        */
    {
        *outdata = toupper(*indata);     /* copy the uppercase character      */
        indata++;                        /* step the position                 */
        outdata++;                       /* and the output position           */
    }
    newObj->setUpperOnly();              /* flag the string as uppercased     */
                                         /* Null terminate, allows faster     */
                                         /* conversion to ASCII-Z string      */
    newObj->putChar(blength, '\0');

    newObj->setEncoding(OREF_NULL);
    newObj->setText(OREF_NULL);

    /* by  default, we don't need Live   */
    newObj->setHasNoReferences();        /*sent                               */

                                         /* NOTE: That if we can set          */
                                         /*  this->NumebrString elsewhere     */
                                         /*we need to mark ourselves as       */
    return newObj;                       /*having OREFs                       */
}

RexxString *RexxString::newString(double number)
/******************************************************************************/
/* Function: Create a string from a double value                              */
/******************************************************************************/
{
                                       /* get double as a number string.    */
  return new_numberstringFromDouble(number)->stringValue();
}


/**
 * Convert a double value to a string using the provided
 * precision.
 *
 * @param number    The number to convert.
 * @param precision The precision requested for the result.
 *
 * @return A string value of the converted result.
 */
RexxString *RexxString::newString(double number, stringsize_t precision)
{
    if (number == 0)                     /* zero result?               */
    {
        return new_string("0");
    }
    else
    {
        char buffer[64];
        // format as a string
        snprintf(buffer, sizeof buffer, "%.*g", (int)precision, number);
        size_t len = strlen(buffer);
        // if the last character is a decimal, we remove that
        if (buffer[len - 1] == '.')
        {
            len--;
        }
        return new_string(buffer, len);
    }
}


RexxString *RexxString::newProxy(const char *string)
/******************************************************************************/
/* Function:  Create a proxy object from this string                          */
/******************************************************************************/
{
  RexxString *sref;
                                       /* The provided source string is null*/
                                       /*  terminated so let class_new      */
                                       /*  compute the length.              */
                                       /* get a new string object           */
  sref = (RexxString *)new_string(string);
                                       /* here we need to identify this     */
                                       /*string                             */
  sref->makeProxiedObject();           /*  as being a proxy object          */

  return sref;
}

// in behaviour
RexxString *RexxString::newRexx(RexxObject **init_args, size_t argCount, size_t named_argCount)
/******************************************************************************/
/* Arguments: Subclass init arguments                                         */
/* Function:  Create a new string value (used primarily for subclasses)       */
/******************************************************************************/
{
    // this method is defined on the object class, but this is actually attached
    // to a class object instance.  Therefore, any use of the this pointer
    // will be touching the wrong data.  Use the classThis pointer for calling
    // any methods on this object from this method.
    RexxClass *classThis = (RexxClass *)this;
    classThis->checkAbstract(); // ooRexx5

    RexxObject *stringObj;               /* string value                      */

                                         /* break up the arguments            */
    RexxClass::processNewArgs(init_args, argCount, &init_args, &argCount, 1, (RexxObject **)&stringObj, NULL);
    /* force argument to string value    */
    RexxString *string = (RexxString *)stringArgument(stringObj, OREF_positional, ARG_ONE);
    ProtectedObject p(string);
    /* create a new string object        */
    string = new_string(string->getStringData(), string->getLength());
    p = string;
    string->setBehaviour(classThis->getInstanceBehaviour());
    if (classThis->hasUninitDefined())
    {
        string->hasUninit();
    }
    /* Initialize the new instance       */
    string->sendMessage(OREF_INIT, init_args, argCount, named_argCount);
    return string;                       /* return the new string             */
}


PCPPM RexxString::operatorMethods[] =
{
   NULL,                               /* first entry not used              */
   (PCPPM)&RexxString::plus,                    //  "+"
   (PCPPM)&RexxString::minus,                   //  "-"
   (PCPPM)&RexxString::multiply,                //  "*"
   (PCPPM)&RexxString::divide,                  //  "/"
   (PCPPM)&RexxString::integerDivide,           //  "%"
   (PCPPM)&RexxString::remainder,               //  "//"
   (PCPPM)&RexxString::power,                   //  "**"
   (PCPPM)&RexxString::concatRexx,              //  ""      should be ::abuttal
   (PCPPM)&RexxString::concatRexx,              //  "||"
   (PCPPM)&RexxString::concatBlank,             //  " "
   (PCPPM)&RexxString::equal,                   //  "="
   (PCPPM)&RexxString::notEqual,                //  "\="
   (PCPPM)&RexxString::isGreaterThan,           //  ">"
   (PCPPM)&RexxString::isLessOrEqual,           //  "\>"    should be ::isBackslashGreaterThan
   (PCPPM)&RexxString::isLessThan,              //  "<"
   (PCPPM)&RexxString::isGreaterOrEqual,        //  "\<"    should be ::isBackslashLessThan
   (PCPPM)&RexxString::isGreaterOrEqual,        //  ">="
   (PCPPM)&RexxString::isLessOrEqual,           //  "<="
   (PCPPM)&RexxString::strictEqual,             //  "=="
   (PCPPM)&RexxString::strictNotEqual,          //  "\=="
   (PCPPM)&RexxString::strictGreaterThan,       //  ">>"
   (PCPPM)&RexxString::strictLessOrEqual,       //  "\>>"   should be ::strictBackslashGreaterThan
   (PCPPM)&RexxString::strictLessThan,          //  "<<"
   (PCPPM)&RexxString::strictGreaterOrEqual,    //  "\<<"   should be ::strictBackslashLessThan
   (PCPPM)&RexxString::strictGreaterOrEqual,    //  ">>="
   (PCPPM)&RexxString::strictLessOrEqual,       //  "<<="
   (PCPPM)&RexxString::notEqual,                //  "<>"    should be ::lessThanGreaterThan
   (PCPPM)&RexxString::notEqual,                //  "><"    should be ::greaterThanLessThan
   (PCPPM)&RexxString::andOp,                   //  "&"
   (PCPPM)&RexxString::orOp,                    //  "|"
   (PCPPM)&RexxString::xorOp,                   //  "&&"
   (PCPPM)&RexxString::operatorNot,             //  "\"
};
