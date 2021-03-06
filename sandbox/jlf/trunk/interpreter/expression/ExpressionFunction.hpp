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
/* REXX Kernel                                       ExpressionFunction.hpp   */
/*                                                                            */
/* Primitive Expression Function Class Definitions                            */
/*                                                                            */
/******************************************************************************/
#ifndef Included_RexxExpressionFunction
#define Included_RexxExpressionFunction

#define function_nointernal  0x01      /* bypass internal routine calls     */
#define function_type_mask   0x0e      /* type of call                      */
#define function_internal    0x02      /* internal call                     */
#define function_builtin     0x06      /* builtin call                      */
#define function_external    0x0e      /* external call                     */
#define function_on_off      0x20      /* call ON/OFF instruction           */

class RexxExpressionFunction : public RexxInternalObject {
 public:
  void *operator new(size_t, size_t);
  inline void *operator new(size_t size, void *ptr) {return ptr;};
  inline void  operator delete(void *) { ; }
  inline void  operator delete(void *, size_t) { ; }
  inline void  operator delete(void *, void *) { ; }

  RexxExpressionFunction(RexxString *, size_t, RexxQueue *, size_t, RexxQueue *, size_t, bool);
  inline RexxExpressionFunction(RESTORETYPE restoreType) { ; };
  void        resolve(RexxDirectory *);
  void        live(size_t);
  void        liveGeneral(int reason);
  void        flatten(RexxEnvelope *);
  RexxObject *evaluate(RexxActivation*, RexxExpressionStack *);

protected:

  RexxString *functionName;            // the name of the function
  RexxInstruction *target;             /* routine to call                   */
  int16_t builtin_index;               /* builtin function index            */
  uint8_t flags;                       /* bypass internal routine calls     */
  uint8_t argument_count;              /* count of positional arguments     */
  uint8_t named_argument_count;        // count of named arguments

  // positional arguments (1 entry per arg: expression) : from 0 to argument_count-1
  // followed by named arguments (2 entries per arg: name, expression) : from argument_count to argument_count + (2 * named_argument_count)-1
  RexxObject * arguments[1];           /* argument list                     */
};
#endif
