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
/*****************************************************************************/
/* REXX Unix Support                                                         */
/*                                                                           */
/* Semaphore support for Unix systems                                        */
/*                                                                           */
/*****************************************************************************/

#ifndef SysSemaphore_DEFINED
#define SysSemaphore_DEFINED

#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include "rexx.h"
#include "SysDebug.hpp"
#include "Utilities.hpp"

class SysSemaphore {
public:
     SysSemaphore(const char *variable) : semVariable(variable), postedCount(0), created(false) { }
     SysSemaphore(const char *variable, bool);
     ~SysSemaphore() { ; }
     void create();
     inline void open() { ; }
     void close();
     void post();
     void wait(const char *ds, int di);
     bool wait(const char *ds, int di, uint32_t);
     void reset();
     inline bool posted() { return postedCount != 0; }
     inline void setSemVariable(const char *variable) { semVariable = variable; } // See RexxActivity::RexxActivity, must reassign, so public setter needed.

protected:
     const char *semVariable;
     pthread_cond_t  semCond;
     pthread_mutex_t semMutex;
     int postedCount;
     bool created;
};

class SysMutex {
public:
     SysMutex(const char *variable) : mutexVariable(variable), created(false) { ; }
     SysMutex(const char *, bool);
     ~SysMutex() { ; }
     void create();
     inline void open() { ; }
     void close();
     inline void request(const char *ds, int di) 
     {
#ifdef _DEBUG
         if (Utilities::traceConcurrency()) dbgprintf(CONCURRENCY_TRACE "...... ... ", Utilities::currentThreadId(), NULL, NULL, 0, ' ');
         dbgprintf("(SysMutex)%s.request : before pthread_mutex_lock(0x%x) from %s (0x%x)\n", mutexVariable, &mutexMutex, ds, di);
#endif
         pthread_mutex_lock(&mutexMutex); 
#ifdef _DEBUG
         if (Utilities::traceConcurrency()) dbgprintf(CONCURRENCY_TRACE "...... ... ", Utilities::currentThreadId(), NULL, NULL, 0, ' ');
         dbgprintf("(SysMutex)%s.request : after pthread_mutex_lock(0x%x) from %s (0x%x)\n", mutexVariable, &mutexMutex, ds, di);
#endif
     }
     inline void release(const char *ds, int di) 
     {
#ifdef _DEBUG
         if (Utilities::traceConcurrency()) dbgprintf(CONCURRENCY_TRACE "...... ... ", Utilities::currentThreadId(), NULL, NULL, 0, ' ');
         dbgprintf("(SysMutex)%s.release : before pthread_mutex_unlock(0x%x) from %s (0x%x)\n", mutexVariable, &mutexMutex, ds, di);
#endif
         pthread_mutex_unlock(&mutexMutex); 
#ifdef _DEBUG
         if (Utilities::traceConcurrency()) dbgprintf(CONCURRENCY_TRACE "...... ... ", Utilities::currentThreadId(), NULL, NULL, 0, ' ');
         dbgprintf("(SysMutex)%s.release : after pthread_mutex_unlock(0x%x) from %s (0x%x)\n", mutexVariable, &mutexMutex, ds, di);
#endif
     }
     inline bool requestImmediate(const char *ds, int di) 
     { 
#ifdef _DEBUG
         if (Utilities::traceConcurrency()) dbgprintf(CONCURRENCY_TRACE "...... ... ", Utilities::currentThreadId(), NULL, NULL, 0, ' ');
         dbgprintf("(SysMutex)%s.requestImmediate : before pthread_mutex_trylock(0x%x) from %s (0x%x)\n", mutexVariable, &mutexMutex, ds, di);
#endif
         bool result = pthread_mutex_trylock(&mutexMutex) == 0;
#ifdef _DEBUG
         if (Utilities::traceConcurrency()) dbgprintf(CONCURRENCY_TRACE "...... ... ", Utilities::currentThreadId(), NULL, NULL, 0, ' ');
         dbgprintf("(SysMutex)%s.requestImmediate : after pthread_mutex_trylock(0x%x) from %s (0x%x)\n", mutexVariable, &mutexMutex, ds, di);
#endif
         return result;
     }

protected:
     const char *mutexVariable;
     pthread_mutex_t mutexMutex;
     bool created;
};
#endif
