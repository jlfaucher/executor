/*----------------------------------------------------------------------------*/;
/*                                                                            */;
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */;
/* Copyright (c) 2005-2010 Rexx Language Association. All rights reserved.    */;
/*                                                                            */;
/* This program and the accompanying materials are made available under       */;
/* the terms of the Common Public License v1.0 which accompanies this         */;
/* distribution. A copy is also available at the following address:           */;
/* http://www.oorexx.org/license.html                                         */;
/*                                                                            */;
/* Redistribution and use in source and binary forms, with or                 */;
/* without modification, are permitted provided that the following            */;
/* conditions are met:                                                        */;
/*                                                                            */;
/* Redistributions of source code must retain the above copyright             */;
/* notice, this list of conditions and the following disclaimer.              */;
/* Redistributions in binary form must reproduce the above copyright          */;
/* notice, this list of conditions and the following disclaimer in            */;
/* the documentation and/or other materials provided with the distribution.   */;
/*                                                                            */;
/* Neither the name of Rexx Language Association nor the names                */;
/* of its contributors may be used to endorse or promote products             */;
/* derived from this software without specific prior written permission.      */;
/*                                                                            */;
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */;
/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */;
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */;
/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */;
/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */;
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */;
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */;
/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */;
/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */;
/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */;
/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */;
/*                                                                            */;
/*----------------------------------------------------------------------------*/;

#ifndef APICommon_Included
#define APICommon_Included


#define NO_HMODULE_MSG            "failed to obtain %s module handle; OS error code %d"
#define NO_PROC_MSG               "failed to get procedeure adddress for %s(); OS error code %d"
#define API_FAILED_MSG            "system API %s() failed; OS error code %d"
#define COM_API_FAILED_MSG        "system API %s() failed; COM code 0x%08x"
#define NO_MEMORY_MSG             "failed to allocate memory"
#define FUNC_WINCTRL_FAILED_MSG   "the '%s'() function of the Windows '%s' control failed"
#define MSG_WINCTRL_FAILED_MSG    "the '%s' message of the Windows '%s' control failed"
#define NO_LOCAL_ENVIRONMENT_MSG  "the .local environment was not found"
#define NO_SIZE_CLASS_MSG         "the .Size class was not found"

extern void  severeErrorException(RexxThreadContext *c, char *msg);
extern void  systemServiceException(RexxThreadContext *context, char *msg);
extern void  systemServiceException(RexxThreadContext *context, char *msg, const char *sub);
extern void  systemServiceExceptionCode(RexxThreadContext *context, const char *msg, const char *arg1, DWORD rc);
extern void  systemServiceExceptionCode(RexxThreadContext *context, const char *msg, const char *arg1);
extern void  systemServiceExceptionComCode(RexxThreadContext *context, const char *msg, const char *arg1, HRESULT hr);
extern void  outOfMemoryException(RexxThreadContext *c);
extern void  userDefinedMsgException(RexxThreadContext *c, CSTRING msg);
extern void  userDefinedMsgException(RexxThreadContext *c, CSTRING formatStr, int number);
extern void  userDefinedMsgException(RexxThreadContext *c, int pos, CSTRING msg);
extern void  userDefinedMsgException(RexxMethodContext *c, CSTRING msg);
extern void  userDefinedMsgException(RexxMethodContext *c, size_t pos, CSTRING msg);
extern void  invalidImageException(RexxThreadContext *c, size_t pos, CSTRING type, CSTRING actual);
extern void  stringTooLongException(RexxThreadContext *c, int pos, size_t len, size_t realLen);
extern void  numberTooSmallException(RexxThreadContext *c, int pos, int min, RexxObjectPtr actual);
extern void  notNonNegativeException(RexxThreadContext *c, size_t pos, RexxObjectPtr actual);
extern void  notPositiveException(RexxThreadContext *c, size_t pos, RexxObjectPtr actual);
extern void  wrongObjInArrayException(RexxThreadContext *c, size_t argPos, size_t index, CSTRING obj, RexxObjectPtr actual);
extern void  wrongObjInArrayException(RexxThreadContext *c, size_t argPos, size_t index, CSTRING obj);
extern void  wrongObjInDirectoryException(RexxThreadContext *c, int argPos, CSTRING index, CSTRING needed, RexxObjectPtr actual);
extern void *executionErrorException(RexxThreadContext *c, CSTRING msg);
extern void  doOverException(RexxThreadContext *c, RexxObjectPtr obj);
extern void  failedToRetrieveException(RexxThreadContext *c, CSTRING item, RexxObjectPtr source);
extern void  missingIndexInDirectoryException(RexxThreadContext *c, int argPos, CSTRING index);
extern void  directoryIndexException(RexxThreadContext *c, size_t pos, CSTRING index, CSTRING msg, RexxObjectPtr actual);
extern void  wrongValueAtDirectoryIndexException(RexxThreadContext *, size_t pos, CSTRING index, CSTRING list, RexxObjectPtr actual);
extern void  emptyArrayException(RexxThreadContext *c, int argPos);
extern void  sparseArrayException(RexxThreadContext *c, size_t argPos, size_t index);
extern void  nullObjectException(RexxThreadContext *c, CSTRING name, size_t pos);
extern void  nullObjectException(RexxThreadContext *c, CSTRING name);
extern void  nullPointerException(RexxThreadContext *c, int pos);

extern RexxObjectPtr wrongClassException(RexxThreadContext *c, size_t pos, const char *n);
extern RexxObjectPtr wrongArgValueException(RexxThreadContext *c, size_t pos, const char *list, RexxObjectPtr actual);
extern RexxObjectPtr wrongArgValueException(RexxThreadContext *c, size_t pos, const char *list, const char *actual);
extern RexxObjectPtr wrongRangeException(RexxThreadContext *c, size_t pos, int min, int max, RexxObjectPtr actual);
extern RexxObjectPtr wrongRangeException(RexxThreadContext *c, size_t pos, int min, int max, int actual);
extern RexxObjectPtr notBooleanException(RexxThreadContext *c, size_t pos, RexxObjectPtr actual);
extern RexxObjectPtr wrongArgOptionException(RexxThreadContext *c, size_t pos, CSTRING list, RexxObjectPtr actual);
extern RexxObjectPtr wrongArgOptionException(RexxThreadContext *c, size_t pos, CSTRING list, CSTRING actual);
extern RexxObjectPtr invalidTypeException(RexxThreadContext *c, size_t pos, const char *type);

extern CSTRING rxGetStringAttribute(RexxMethodContext *context, RexxObjectPtr obj, CSTRING name);
extern bool    rxGetNumberAttribute(RexxMethodContext *context, RexxObjectPtr obj, CSTRING name, wholenumber_t *pNumber);
extern bool    rxGetUIntPtrAttribute(RexxMethodContext *context, RexxObjectPtr obj, CSTRING name, uintptr_t *pNumber);
extern bool    rxGetUInt32Attribute(RexxMethodContext *context, RexxObjectPtr obj, CSTRING name, uint32_t *pNumber);

extern bool            requiredClass(RexxThreadContext *c, RexxObjectPtr obj, const char *name, size_t pos);
extern int32_t         getLogical(RexxThreadContext *c, RexxObjectPtr obj);
extern size_t          rxArgCount(RexxMethodContext * context);
extern bool            rxStr2Number(RexxMethodContext *c, CSTRING str, uint64_t *number, size_t pos);
extern bool            rxStr2Number32(RexxMethodContext *c, CSTRING str, uint32_t *number, size_t pos);
extern RexxClassObject rxGetContextClass(RexxMethodContext *c, CSTRING name);
extern RexxObjectPtr   rxSetObjVar(RexxMethodContext *c, CSTRING varName, RexxObjectPtr val);
extern RexxObjectPtr   rxNewBuiltinObject(RexxMethodContext *c, CSTRING className);
extern RexxObjectPtr   rxNewBuiltinObject(RexxThreadContext *c, CSTRING className);
extern bool            checkForCondition(RexxThreadContext *c, bool clear);
extern void            standardConditionMsg(RexxThreadContext *c, RexxDirectoryObject condObj, RexxCondition *condition);
extern bool            isInt(int, RexxObjectPtr, RexxThreadContext *);
extern bool            isOfClassType(RexxMethodContext *, RexxObjectPtr, CSTRING);
extern void            dbgPrintClassID(RexxThreadContext *c, RexxObjectPtr obj);
extern void            dbgPrintClassID(RexxMethodContext *c, RexxObjectPtr obj);


/**
 *  Missing argument; argument 'argument' is required
 *
 *  Missing argument; argument 2 is required
 *
 *  Raises 88.901
 *
 * @param c    The thread context we are operating under.
 * @param pos  The 'argument' position.
 *
 * @return NULLOBJECT
 */
inline RexxObjectPtr missingArgException(RexxThreadContext *c, size_t argPos)
{
    c->RaiseException2(Rexx_Error_Invalid_argument_noarg, c->String("positional"), c->WholeNumber(argPos));
    return NULLOBJECT;
}

/**
 *  Too many arguments in invocation; 'number' expected
 *
 *  Too many arguments in invocation; 5 expected
 *
 *  Raises 93.903
 *
 * @param c    The thread context we are operating under.
 * @param max  The maximum arguments expected.
 *
 * @return NULLOBJECT
 */
inline RexxObjectPtr tooManyArgsException(RexxThreadContext *c, size_t max)
{
    c->RaiseException2(Rexx_Error_Invalid_argument_maxarg, c->String("positional"), c->WholeNumber(max));
    return NULLOBJECT;
}

/**
 *  Method argument argument must be zero or a positive whole number; found
 *  "value"
 *
 *  Method argument 3 must be zero or a positive whole number; found "an Array"
 *
 *  Raises 93.906
 *
 * @param c    The thread context we are operating under.
 * @param max  The maximum arguments expected.
 *
 * @return NULLOBJECT
 */
inline RexxObjectPtr notPositiveArgException(RexxThreadContext *c, size_t argPos, RexxObjectPtr actual)
{
    c->RaiseException3(Rexx_Error_Incorrect_method_nonnegative, c->String("positional"), c->WholeNumber(argPos), actual);
    return NULLOBJECT;
}

/**
 * Given a condition object, extracts and returns as a whole number the subcode
 * of the condition.
 */
inline wholenumber_t conditionSubCode(RexxCondition *condition)
{
    return (condition->code - (condition->rc * 1000));
}

inline RexxObjectPtr rxNewBag(RexxMethodContext *c)
{
    return rxNewBuiltinObject(c, "BAG");
}

inline RexxObjectPtr rxNewList(RexxMethodContext *c)
{
    return rxNewBuiltinObject(c, "LIST");
}

inline RexxObjectPtr rxNewQueue(RexxMethodContext *c)
{
    return rxNewBuiltinObject(c, "QUEUE");
}


#endif
