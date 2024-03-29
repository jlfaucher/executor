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
/*********************************************************************/
/*                                                                   */
/*   Function:  Miscellaneous system specific routines               */
/*                                                                   */
/*********************************************************************/
#include "RexxCore.h"
#include "StringClass.hpp"
#include "DirectoryClass.hpp"
#include "RexxActivity.hpp"
#include "RexxActivation.hpp"
#include "PointerClass.hpp"
#include <stdlib.h>
#include <process.h>
#include "malloc.h"
#include <signal.h>
#include "Interpreter.hpp"
#include "SystemInterpreter.hpp"

RexxString *SystemInterpreter::getSystemName()
/******************************************************************************/
/* Function: Get System Name                                                  */
/******************************************************************************/
{
    char chVerBuf[26];                   // buffer for version
    strcpy(chVerBuf, "WindowsNT"); // Windows NT
    return new_string(chVerBuf);                     /* return as a string                */
}


RexxString *SystemInterpreter::getSourceString(
  RexxString * callType,               /* type of call token                */
  RexxString * programName )           /* program name token                */
/******************************************************************************/
/* Function:  Produce a system specific source string                         */
/******************************************************************************/
{
    char  *outPtr;                  /* copy pointer                     */
    const char  *chSysName;               /* copy pointer                     */

    RexxString *rsSysName = getSystemName();    /* start with the system stuff       */
    chSysName= rsSysName->getStringData();

    RexxString *source_string = raw_string(rsSysName->getLength() + 2 + callType->getLength() + programName->getLength());

    outPtr = source_string->getWritableData();  /* point to the result data          */
    strcpy(outPtr, chSysName);           /* copy the system name              */
    outPtr +=rsSysName->getLength();     /* step past the name                */
    *outPtr++ = ' ';                     /* put a blank between               */
                                         /* copy the call type                */
    memcpy(outPtr, callType->getStringData(), callType->getLength());
    outPtr += callType->getLength();     /* step over the call type           */
    *outPtr++ = ' ';                     /* put a blank between               */
                                         /* copy the system name              */
    memcpy(outPtr, programName->getStringData(), programName->getLength());
    return source_string;                /* return the source string          */
}


int WinExceptionFilter( int xCode )
/******************************************************************************/
/* Function:  Exception Filter used by Windows exception handling             */
/******************************************************************************/
{
    return EXCEPTION_CONTINUE_SEARCH;
}


#define MAX_ADDRESS_NAME_LENGTH  250   /* maximum command environment name  */



/**
 * Validate an external address name.
 *
 * @param Name   The name to validate
 */
void SystemInterpreter::validateAddressName(RexxString *name )
{
    /* name too long?                    */
    if (name->getLength() > MAX_ADDRESS_NAME_LENGTH)
    {
        /* go report an error                */
        reportException(Error_Environment_name_name, MAX_ADDRESS_NAME_LENGTH, name);
    }
}


/**
 * This was an undocumented API prior to 4.0, but is known to have been used by
 * some IBM applications. Therefore this was maintained solely for binary
 * compatibility.
 *
 * However, it is now also used to turn off processing Windows messages in a
 * special case situation.  See the SysSemaphore::waitHandle() comments for more
 * info. This is done on a per-thread basis, RexxSetProcessMessages() must be
 * invoked while executing on the proper thread.
 *
 * @return TRUE always.
 */
BOOL APIENTRY RexxSetProcessMessages(BOOL turnOn)
{
    if ( ! turnOn )
    {
        SysSemaphore::setNoMessageLoop();
    }
    return TRUE;
}

