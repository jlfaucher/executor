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

#include "LocalAPIContext.hpp"
#include "ServiceException.hpp"
#include "rexx.h"


static wholenumber_t getAPIManagerCount = 0; // Monitoring

wholenumber_t RexxEntry getAPIManagerCounter()
{
    return getAPIManagerCount;
}

LocalAPIContext::LocalAPIContext(ServerManager t)
{
    localManager = NULL;
    target = t;
    contextInitialized = false;
    cleanupLocalManager = false;
}

LocalAPIManager *LocalAPIContext::getAPIManager()
{
	getAPIManagerCount++;
    localManager = LocalAPIManager::getInstance();
    contextInitialized = true;
    return localManager;
}

/**
 * Process a service exception thrown as part of an API
 *
 * @param e      The exception information (deleted before return).
 *
 * @return The mapped return code.
 */
RexxReturnCode LocalAPIContext::processServiceException(ServiceException *e)
{
    if (localManager != NULL)
    {
        RexxReturnCode rc = localManager->processServiceException(target, e);
        delete e;         // make sure we delete the exception object
        return rc;
    }
    // in theory, this should never happen.  For some reason, we got a non-global
    // failure, but the local manager doesn't exist.  Ok, just consider this a
    // memory error.
    delete e;                     // make sure it's deleted
    return RXAPI_MEMFAIL;
}
