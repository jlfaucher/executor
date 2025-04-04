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
/* REXX Kernel                                        MutableBufferClass.hpp  */
/*                                                                            */
/* Primitive MutableBuffer Class Definition                                   */
/*                                                                            */
/******************************************************************************/
#ifndef Included_RexxMutableBuffer
#define Included_RexxMutableBuffer

#include "StringClass.hpp"
#include "IntegerClass.hpp"
#include "BufferClass.hpp"

class RexxMutableBuffer;
class RexxClass;

class RexxMutableBufferClass : public RexxClass {
 public:
   RexxMutableBufferClass(RESTORETYPE restoreType) { ; };
   void *operator new(size_t size, void *ptr) { return ptr; };
   RexxMutableBuffer *newRexx(RexxObject**, size_t, size_t); // in behaviour
};

 class RexxMutableBuffer : public RexxObject {
     friend class RexxMutableBufferClass;
  public:
   inline void       *operator new(size_t size, void *ptr){return ptr;};
          void       *operator new(size_t size, RexxClass *bufferClass);
          void       *operator new(size_t size);
                      RexxMutableBuffer();
                      RexxMutableBuffer(size_t, size_t);
   inline             RexxMutableBuffer(RESTORETYPE restoreType) { ; };

   void               live(size_t);
   void               liveGeneral(int reason);
   void               flatten(RexxEnvelope *envelope);

   RexxObject        *copy();
   void               ensureCapacity(size_t addedLength);

   RexxObject        *lengthRexx(); // in behaviour

   RexxMutableBuffer *append(RexxObject*); // in behaviour
   RexxMutableBuffer *appendCstring(const char*, size_t blength); // Must not overload append : would generate error cannot convert from 'overloaded-function' to 'PCPPM' in memory/setup.cpp
   RexxMutableBuffer *insert(RexxObject*, RexxObject*, RexxObject*, RexxObject*); // in behaviour
   RexxMutableBuffer *overlay(RexxObject*, RexxObject*, RexxObject*, RexxObject*); // in behaviour
   RexxMutableBuffer *replaceAt(RexxObject *str, RexxObject *pos, RexxObject *len, RexxObject *pad); // in behaviour
   RexxMutableBuffer *mydelete(RexxObject*, RexxObject*); // in behaviour
   RexxString        *substr(RexxInteger *startPosition, RexxInteger *len, RexxString *pad); // in behaviour
   RexxInteger       *lastPos(RexxString *needle, RexxInteger *_start, RexxInteger *_range); // in behaviour
   RexxInteger       *posRexx(RexxString *needle, RexxInteger *_start, RexxInteger *_range); // in behaviour
   RexxInteger       *caselessLastPos(RexxString *needle, RexxInteger *_start, RexxInteger *_range); // in behaviour
   RexxInteger       *caselessPos(RexxString *needle, RexxInteger *_start, RexxInteger *_range); // in behaviour
   RexxString        *subchar(RexxInteger *startPosition); // in behaviour

   RexxInteger       *getBufferSize() { return new_integer(bufferLength); } // in behaviour
   RexxObject        *setBufferSize(RexxInteger*); // in behaviour
   RexxArray         *makeArrayRexx(RexxString *div); // in behaviour
   RexxArray         *makeArray();
   RexxString        *makeString();
   RexxString        *primitiveMakeString();
   RexxInteger       *countStrRexx(RexxString *needle); // in behaviour
   RexxInteger       *caselessCountStrRexx(RexxString *needle); // in behaviour
   RexxMutableBuffer *changeStr(RexxString *needle, RexxString *newNeedle, RexxInteger *countArg); // in behaviour
   RexxMutableBuffer *caselessChangeStr(RexxString *needle, RexxString *newNeedle, RexxInteger *countArg); // in behaviour
   RexxMutableBuffer *upper(RexxInteger *_start, RexxInteger *_length); // in behaviour
   RexxMutableBuffer *lower(RexxInteger *_start, RexxInteger *_length); // in behaviour
   RexxMutableBuffer *translate(RexxString *tableo, RexxString *tablei, RexxString *pad, RexxInteger *, RexxInteger *); // in behaviour
   RexxInteger *match(RexxInteger *start_, RexxString *other, RexxInteger *offset_, RexxInteger *len_); // in behaviour
   RexxInteger *caselessMatch(RexxInteger *start_, RexxString *other, RexxInteger *offset_, RexxInteger *len_); // in behaviour
   bool primitiveMatch(stringsize_t start, RexxString *other, stringsize_t offset, stringsize_t len);
   bool primitiveCaselessMatch(stringsize_t start, RexxString *other, stringsize_t offset, stringsize_t len);
   RexxInteger *matchChar(RexxInteger *position_, RexxString *matchSet); // in behaviour
   RexxInteger *caselessMatchChar(RexxInteger *position_, RexxString *matchSet); // in behaviour
   RexxInteger *verify(RexxString *, RexxString *, RexxInteger *, RexxInteger *); // in behaviour
   RexxString  *subWord(RexxInteger *, RexxInteger *); // in behaviour
   RexxArray   *subWords(RexxInteger *, RexxInteger *); // in behaviour
   RexxString  *word(RexxInteger *); // in behaviour
   RexxInteger *wordIndex(RexxInteger *); // in behaviour
   RexxInteger *wordLength(RexxInteger *); // in behaviour
   RexxInteger *words(); // in behaviour
   RexxInteger *wordPos(RexxString *, RexxInteger *); // in behaviour
   RexxInteger *caselessWordPos(RexxString *, RexxInteger *); // in behaviour
   RexxMutableBuffer *delWord(RexxInteger *position, RexxInteger *plength); // in behaviour
   RexxMutableBuffer *space(RexxInteger *space_count, RexxString  *pad);

   inline const char *getStringData() { return data->getData(); }
   inline size_t     getLength()    { return dataLength; }
   inline void        setLength(size_t l) { dataLength = l; data->setDataLength(l);};
   inline size_t     getBufferLength() { return bufferLength; }
   RexxObject        *setBufferLength(size_t);
   inline char *      getData()       { return data->getData(); }
   inline void copyData(size_t offset, const char *string, size_t l) { data->copyData(offset, string, l); }
   inline void openGap(size_t offset, size_t _size, size_t tailSize) { data->openGap(offset, _size, tailSize); }
   inline void closeGap(size_t offset, size_t _size, size_t tailSize) { data->closeGap(offset, _size, tailSize); }
   inline void adjustGap(size_t offset, size_t _size, size_t _newSize) { data->adjustGap(offset, _size, _newSize); }
   inline void setData(size_t offset, codepoint_t character, size_t l) { data->setData(offset, (char)character, l); }
   inline char getCharB(size_t offset) { return getData()[offset]; }
   size_t setDataLength(size_t l);
   inline size_t getCapacity() { return bufferLength; }
   char *setCapacity(size_t newLength);

   bool         checkIsASCII();
   RexxInteger *isASCIIRexx();
   inline bool  isASCIIChecked() {return (this->Attributes & STRING_ISASCII_CHECKED) != 0;};
   inline void  setIsASCIIChecked(bool value=true)
   {
       if (value) this->Attributes |= STRING_ISASCII_CHECKED;
       else
       {
           this->Attributes &= ~STRING_ISASCII_CHECKED;
           this->setIsASCII(false); // isASCII() can be true only when isASCIIChecked() is true
       }
   }
   // if isASCII() is true then it's really ASCII
   // if isASCII() is false then it's really not ASCII only when isASCIIChecked() is true, otherwise can't tell
   inline bool  isASCII() {return (this->Attributes & STRING_ISASCII) != 0;};
   inline void  setIsASCII(bool value=true)
   {
       if (value) this->Attributes |= STRING_ISASCII;
       else this->Attributes &= ~STRING_ISASCII;
   }

   inline RexxObject *getEncoding() { return this->encoding; }
   inline void setEncoding(RexxObject *e)
   {
       OrefSet(this, this->encoding, e);
       if (e != OREF_NULL) this->setHasReferences();
   }
   inline RexxObject *setEncodingRexx(RexxObject *e)
   {
       RexxObject *previousEncoding = this->getEncoding();
       this->setEncoding(e);
       return previousEncoding;
   }

   static void createInstance();
   static RexxClass *classInstance;

 protected:
   size_t            bufferLength;    /* buffer length in bytes          */
   size_t            defaultSize;     /* default size when emptied       */
   size_t            dataLength;      // current length of data in bytes
   size_t             Attributes;      /* buffer attributes               */
   RexxObject        *encoding;        // mutable buffer encoding or OREF_NULL
   RexxBuffer        *data;            /* buffer used for the data        */
 };

#endif
