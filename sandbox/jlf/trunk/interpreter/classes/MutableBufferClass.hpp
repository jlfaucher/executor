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
   RexxMutableBuffer *newRexx(RexxObject**, size_t); // in behaviour
};

 class RexxMutableBuffer : public RexxObject {
     friend class RexxMutableBufferClass;
  public:
   inline void       *operator new(size_t size, void *ptr){return ptr;};
          void       *operator new(size_t size, RexxClass *bufferClass);
          void       *operator new(size_t size);
                      RexxMutableBuffer(const char *charsetName=NULL);
                      RexxMutableBuffer(CHARSET *charset, ENCODING *encoding);
                      RexxMutableBuffer(sizeB_t, sizeB_t, const char *charsetName=NULL);
                      RexxMutableBuffer(sizeB_t, sizeB_t, CHARSET *charset, ENCODING *encoding);
   inline             RexxMutableBuffer(RESTORETYPE restoreType) { ; };

   void               live(size_t);
   void               liveGeneral(int reason);
   void               flatten(RexxEnvelope *envelope);

   RexxObject        *copy();
   void               ensureCapacity(sizeB_t addedLength);
#ifdef STRONG_TYPES
   void               ensureCapacity(sizeC_t addedLength);
#endif

   RexxObject        *lengthRexx(); // in behaviour

   RexxMutableBuffer *append(RexxObject*); // in behaviour
   RexxMutableBuffer *appendCstring(const char*, sizeB_t blength); // Must not overload append : would generate error cannot convert from 'overloaded-function' to 'PCPPM' in memory/setup.cpp
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
   RexxArray         *makearray(RexxString *div); // in behaviour
   RexxString        *makeString();
   RexxInteger       *countStrRexx(RexxString *needle); // in behaviour
   RexxInteger       *caselessCountStrRexx(RexxString *needle); // in behaviour
   RexxMutableBuffer *changeStr(RexxString *needle, RexxString *newNeedle, RexxInteger *countArg); // in behaviour
   RexxMutableBuffer *caselessChangeStr(RexxString *needle, RexxString *newNeedle, RexxInteger *countArg); // in behaviour
   RexxMutableBuffer *upper(RexxInteger *_start, RexxInteger *_length); // in behaviour
   RexxMutableBuffer *lower(RexxInteger *_start, RexxInteger *_length); // in behaviour
   RexxMutableBuffer *translate(RexxString *tableo, RexxString *tablei, RexxString *pad, RexxInteger *, RexxInteger *); // in behaviour
   RexxInteger *match(RexxInteger *start_, RexxString *other, RexxInteger *offset_, RexxInteger *len_); // in behaviour
   RexxInteger *caselessMatch(RexxInteger *start_, RexxString *other, RexxInteger *offset_, RexxInteger *len_); // in behaviour
   bool primitiveMatch(stringsizeB_t start, RexxString *other, stringsizeB_t offset, stringsizeB_t len);
   bool primitiveCaselessMatch(stringsizeB_t start, RexxString *other, stringsizeB_t offset, stringsizeB_t len);
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

   inline CHARSET *getCharset() { return m17n_get_charset(this->charset); }
   inline void setCharset(CHARSET *c) { this->charset = c ? (int8_t) c->number : -1; }
   inline ENCODING *getEncoding() { return m17n_get_encoding(this->encoding); }
   inline void setEncoding(ENCODING *e) { this->encoding = e ? (int8_t) e->number : -1; }
   inline const char *getStringData() { return data->getData(); }
   // inline size_t      getLength()     { return dataCLength; }
   inline sizeB_t     getBLength()    { return dataBLength; }
   inline sizeC_t     getCLength()    { return dataCLength; }
   // inline void        setLength(size_t l) { dataCLength = l; };
   inline void        setBLength(sizeB_t l) { dataBLength = l; data->setDataLength(size_v(l));};
   inline void        setCLength(sizeC_t l) { dataCLength = l; };
   inline sizeB_t     getBufferLength() { return bufferLength; }
   RexxObject        *setBufferLength(sizeB_t);
   inline char *      getData()       { return data->getData(); }
   inline void copyData(sizeB_t offset, const char *string, sizeB_t l) { data->copyData(offset, string, l); }
   inline void openGap(sizeB_t offset, sizeB_t _size, sizeB_t tailSize) { data->openGap(offset, _size, tailSize); }
   inline void closeGap(sizeB_t offset, sizeB_t _size, sizeB_t tailSize) { data->closeGap(offset, _size, tailSize); }
   inline void adjustGap(sizeB_t offset, sizeB_t _size, sizeB_t _newSize) { data->adjustGap(offset, _size, _newSize); }
   inline void setData(sizeB_t offset, char character, sizeB_t l) { data->setData(offset, character, l); }
   inline char getCharB(sizeB_t offset) { return getData()[size_v(offset)]; }
   inline codepoint_t getCharC(sizeC_t offset) { return getData()[size_v(offset)]; } // todo m17n : convert charpos to bytepos and return a codepoint, not a byte

   static void createInstance();
   static RexxClass *classInstance;

 protected:
   int8_t             encoding;        // string encoding (how the codepoints are serialized in stringData)
   int8_t             charset;         // string charset (what is the semantic of the codepoints)
   sizeB_t            bufferLength;    /* buffer length in bytes          */
   sizeB_t            defaultSize;     /* default size when emptied       */
   sizeB_t            dataBLength;     // current length of data in bytes
   sizeC_t            dataCLength;     // current length of data in characters
   RexxBuffer        *data;            /* buffer used for the data        */
 };
 
 // For the needs of m17n, must have a common interface for RexxString and RexxMutableBuffer.
 // Can't use multiple inheritance, so I use delegation...
 class RexxMutableBufferWrapper : public IRexxString {
  public:
   RexxMutableBufferWrapper(RexxMutableBuffer *s) : str(s) {}
   inline RexxString *makeString() { return str->makeString(); }
   inline RexxMutableBuffer *makeMutableBuffer() { return str; }
   inline CHARSET *getCharset() { return str->getCharset(); }
   inline void setCharset(CHARSET *c) { return str->setCharset(c); }
   inline ENCODING *getEncoding() { return str->getEncoding(); }
   inline void setEncoding(ENCODING *e) { str->setEncoding(e); }
   inline sizeB_t getBLength() { return str->getBLength(); };
   inline sizeC_t getCLength() { return str->getCLength(); };
   // inline void setLength(size_t l) { str->setLength(l); };
   inline void setBLength(sizeB_t l) { str->setBLength(l); };
   inline void setCLength(sizeC_t l) { str->setCLength(l); };
   inline const char *getStringData() { return str->getStringData(); }
   inline char *getWritableData() { return str->getData(); }
  private:
   RexxMutableBuffer *str;
 };
 
#endif
