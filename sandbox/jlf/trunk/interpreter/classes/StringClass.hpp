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
/* REXX Kernel                                               StringClass.hpp  */
/*                                                                            */
/* Primitive String Class Definition                                          */
/*                                                                            */
/******************************************************************************/
#ifndef Included_RexxString
#define Included_RexxString

#include "NumberStringClass.hpp"
#include "IntegerClass.hpp"
#include "StringUtil.hpp"
#include "Utilities.hpp"
#include "m17n_charset.h"
#include "m17n_encoding.h"

                                       /* return values from the is_symbol  */
                                       /* validation method                 */
#define  STRING_BAD_VARIABLE   0
#define  STRING_STEM           1
#define  STRING_COMPOUND_NAME  2
#define  STRING_LITERAL        3
#define  STRING_LITERAL_DOT    4
#define  STRING_NUMERIC        5
#define  STRING_NAME           6

#define  STRING_HASLOWER       0x01    /* string does contain lowercase     */
#define  STRING_NOLOWER        0x02    /* string does not contain lowercase */
#define  STRING_NONNUMERIC     0x04    /* string is non-numeric             */

#define  INITIAL_NAME_SIZE     10      /* first name table allocation       */
#define  EXTENDED_NAME_SIZE    10      /* amount to extend table by         */
                                       /* Strip function options     */
#define  STRIP_BOTH                'B'
#define  STRIP_LEADING             'L'
#define  STRIP_TRAILING            'T'
                                       /* Datatype function options  */
#define  DATATYPE_ALPHANUMERIC     'A'
#define  DATATYPE_BINARY           'B'
#define  DATATYPE_LOWERCASE        'L'
#define  DATATYPE_MIXEDCASE        'M'
#define  DATATYPE_NUMBER           'N'
#define  DATATYPE_SYMBOL           'S'
#define  DATATYPE_VARIABLE         'V'
#define  DATATYPE_UPPERCASE        'U'
#define  DATATYPE_WHOLE_NUMBER     'W'
#define  DATATYPE_HEX              'X'
#define  DATATYPE_9DIGITS          '9'
#define  DATATYPE_LOGICAL          'O' // lOgical.
                                       /* Verify function options    */
#define  VERIFY_MATCH              'M'
#define  VERIFY_NOMATCH            'N'

#define ch_SPACE ' '

                                       /* character validation sets for the */
                                       /* datatype function                 */
#define  HEX_CHAR_STR   "0123456789ABCDEFabcdef"
#define  ALPHANUM       \
"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
#define  BINARI         "01"
#define  LOWER_ALPHA    "abcdefghijklmnopqrstuvwxyz"
#define  MIXED_ALPHA    \
"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define  UPPER_ALPHA    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


/*********************************************************************/
/*                                                                   */
/*      Name:                   IntToHexdigit                        */
/*                                                                   */
/*      Descriptive name:       convert int to hexadecimal digit     */
/*                                                                   */
/*      Returns:                A hexadecimal digit representing n.  */
/*                                                                   */
/*********************************************************************/

                                       /* convert the number                */
inline char IntToHexDigit(int n)
{
    return "0123456789ABCDEF"[n];
}

 class RexxString : public RexxObject {
  public:
   inline void       *operator new(size_t size, void *ptr){return ptr;};
   inline RexxString() {;} ;
   inline RexxString(RESTORETYPE restoreType) { ; };

   void        live(size_t);
   void        liveGeneral(int reason);
   void        flatten(RexxEnvelope *envelope);
   RexxObject *unflatten(RexxEnvelope *);

   virtual HashCode hash();
   virtual HashCode getHashValue();

   inline HashCode getStringHash()
   {
       if (hashValue == 0)                // if we've never generated this, the code is zero
       {
           stringsizeB_t len = this->getBLength();

           HashCode h = 0;
           // the hash code is generated from all of the string characters.
           // we do this in a lazy fashion, since most string objects never need to
           // calculate a hash code, particularly the long ones.
           // This hashing algorithm is very similar to that used for Java strings.
           for (stringsizeB_t i = 0; i < len; i++)
           {
               h = 31 * h + this->stringData[stringsize_v(i)];
           }
           this->hashValue = h;
       }
       return hashValue;
   }
   HashCode getObjectHashCode();

   bool         numberValue(wholenumber_t &result, size_t precision);
   bool         numberValue(wholenumber_t &result);
   bool         unsignedNumberValue(uwholenumber_t &result, size_t precision);
   bool         unsignedNumberValue(uwholenumber_t &result);
   bool         doubleValue(double &result);
   RexxNumberString *numberString();
   RexxInteger *integerValue(size_t precision);
   RexxString  *makeString();
   RexxString  *primitiveMakeString();
   void         copyIntoTail(RexxCompoundTail *buffer);
   RexxString  *stringValue();
   bool         truthValue(int);
   virtual bool logicalValue(logical_t &);

   bool        isEqual(RexxObject *); // in behaviour
   bool        primitiveIsEqual(RexxObject *);
   bool        primitiveCaselessIsEqual(RexxObject *);
   wholenumber_t strictComp(RexxObject *);
   wholenumber_t comp(RexxObject *);
   wholenumber_t compareTo(RexxObject *);
   RexxInteger *equal(RexxObject *);
   RexxInteger *strictEqual(RexxObject *); // in behaviour
   RexxInteger *notEqual(RexxObject *); // in behaviour
   RexxInteger *strictNotEqual(RexxObject *); // in behaviour
   RexxInteger *isGreaterThan(RexxObject *); // in behaviour
   RexxInteger *isLessThan(RexxObject *); // in behaviour
   RexxInteger *isGreaterOrEqual(RexxObject *); // in behaviour
   RexxInteger *isLessOrEqual(RexxObject *); // in behaviour
   RexxInteger *strictGreaterThan(RexxObject *); // in behaviour
   RexxInteger *strictLessThan(RexxObject *); // in behaviour
   RexxInteger *strictGreaterOrEqual(RexxObject *); // in behaviour
   RexxInteger *strictLessOrEqual(RexxObject *); // in behaviour

   sizeB_t      copyData(sizeB_t, char *, sizeB_t);
   RexxObject *lengthRexx(); // in behaviour
   RexxString *concatRexx(RexxObject *); // in behaviour
   RexxString *concat(RexxString *);
   RexxString *concatToCstring(const char *, const char *charsetName=NULL);
   RexxString *concatToCstring(const char *, CHARSET *charset, ENCODING *encoding);
   RexxString *concatWithCstring(const char *, const char *charsetName=NULL);
   RexxString *concatWithCstring(const char *, CHARSET *charset, ENCODING *encoding);
   RexxString *concatBlank(RexxObject *); // in behaviour
   bool        checkLower();
   RexxString *upper();
   RexxString *upper(sizeC_t, sizeC_t);
   RexxString *upperRexx(RexxInteger *, RexxInteger *); // in behaviour
   RexxString *lower();
   RexxString *lower(sizeC_t, sizeC_t);
   RexxString *lowerRexx(RexxInteger *, RexxInteger *); // in behaviour
   RexxString *stringTrace();
   void        setNumberString(RexxObject *);
   RexxString *concatWith(RexxString *, char);

   RexxObject *plus(RexxObject *right); // in behaviour
   RexxObject *minus(RexxObject *right); // in behaviour
   RexxObject *multiply(RexxObject *right); // in behaviour
   RexxObject *divide(RexxObject *right); // in behaviour
   RexxObject *integerDivide(RexxObject *right); // in behaviour
   RexxObject *remainder(RexxObject *right); // in behaviour
   RexxObject *power(RexxObject *right); // in beahviour
   RexxObject *abs(); // in behaviour
   RexxObject *sign(); // in behaviour
   RexxObject *notOp(); // in beahviour
   RexxObject *operatorNot(RexxObject *);
   RexxObject *andOp(RexxObject *); // in behaviour
   RexxObject *orOp(RexxObject *); // in behaviour
   RexxObject *xorOp(RexxObject *); // in behaviour
   RexxObject *Max(RexxObject **args, size_t argCount); // in behaviour
   RexxObject *Min(RexxObject **args, size_t argCount); // in behaviour
   RexxObject *trunc(RexxInteger *decimals); // in behaviour
   RexxObject *format(RexxObject *Integers, RexxObject *Decimals, RexxObject *MathExp, RexxObject *ExpTrigger); // in behaviour
   RexxObject *isInteger();
   RexxObject *logicalOperation(RexxObject *, RexxObject *, unsigned int);
   RexxString *extractB(sizeB_t offset, sizeB_t sublength) // Extract bytes 
   {
       return this->getEncoding()->get_bytes(this, offset, sublength);
   }
   RexxString *extractC(sizeC_t offset, sizeC_t sublength) // Extract characters
   {
       return this->getEncoding()->get_codepoints(this, offset, sublength);
   }
   RexxObject *evaluate(RexxActivation *, RexxExpressionStack *);
   RexxObject *getValue(RexxActivation *);
   RexxObject *getValue(RexxVariableDictionary *);
   RexxObject *getRealValue(RexxActivation *);
   RexxObject *getRealValue(RexxVariableDictionary *);
                                       /* the following methods are in    */
                                       /* OKBSUBS                         */
   RexxString  *center(RexxInteger *, RexxString *); // in behaviour
   RexxString  *delstr(RexxInteger *, RexxInteger *); // in behaviour
   RexxString  *insert(RexxString *, RexxInteger *, RexxInteger *, RexxString *); // in behaviour
   RexxString  *left(RexxInteger *, RexxString *); // in behaviour
   RexxString  *overlay(RexxString *, RexxInteger *, RexxInteger *, RexxString *); // in behaviour
   RexxString  *replaceAt(RexxString *, RexxInteger *, RexxInteger *, RexxString *); // in behaviour
   RexxString  *reverse(); // in behaviour
   RexxString  *right(RexxInteger *, RexxString *); // in behaviour
   RexxString  *strip(RexxString *, RexxString *); // in behaviour
   RexxString  *substr(RexxInteger *, RexxInteger *, RexxString *); // in behaviour
   RexxString  *subchar(RexxInteger *); // in behaviour
   RexxString  *delWord(RexxInteger *, RexxInteger *); // in behaviour
   RexxString  *space(RexxInteger *, RexxString *); // in behaviour
   RexxString  *subWord(RexxInteger *, RexxInteger *); // in behaviour
   RexxArray   *subWords(RexxInteger *, RexxInteger *); // in behaviour
   RexxString  *word(RexxInteger *); // in behaviour
   RexxInteger *wordIndex(RexxInteger *); // in behaviour
   RexxInteger *wordLength(RexxInteger *); // in behaviour
   RexxInteger *wordPos(RexxString *, RexxInteger *); // in behaviour
   RexxInteger *caselessWordPos(RexxString *, RexxInteger *); // in behaviour
   RexxInteger *words(); // in behaviour
                                       /* the following methods are in    */
                                       /* OKBMISC                         */
   RexxString  *changeStr(RexxString *, RexxString *, RexxInteger *); // in behaviour
   RexxString  *caselessChangeStr(RexxString *, RexxString *, RexxInteger *); // in behaviour
   RexxInteger *abbrev(RexxString *, RexxInteger *); // in behaviour
   RexxInteger *caselessAbbrev(RexxString *, RexxInteger *); // in behaviour
   RexxInteger *compare(RexxString *, RexxString *); // in behaviour
   RexxInteger *caselessCompare(RexxString *, RexxString *); // in behaviour
   RexxString  *copies(RexxInteger *); // in behaviour
   RexxObject  *dataType(RexxString *); // in behaviour

   RexxInteger *lastPosRexx(RexxString *, RexxInteger *, RexxInteger *); // in behaviour
   RexxInteger *caselessLastPosRexx(RexxString *, RexxInteger *, RexxInteger *); // in behaviour
   sizeC_t       lastPos(RexxString  *needle, sizeC_t start);
   sizeC_t       caselessLastPos(RexxString  *needle, sizeC_t start);
   const char * caselessLastPos(const char *needle, sizeB_t needleLen, const char *haystack, sizeB_t haystackLen);

   RexxInteger *posRexx(RexxString *, RexxInteger *, RexxInteger *); // in behaviour
   RexxInteger *caselessPosRexx(RexxString *, RexxInteger *, RexxInteger *); // in behaviour
   sizeC_t       pos(RexxString *, sizeC_t);
   sizeC_t       caselessPos(RexxString *, sizeC_t);

   RexxString  *translate(RexxString *, RexxString *, RexxString *, RexxInteger *, RexxInteger *); // in behaviour
   RexxInteger *verify(RexxString *, RexxString *, RexxInteger *, RexxInteger *); // in behaviour
   RexxInteger *countStrRexx(RexxString *); // in behaviour
   RexxInteger *caselessCountStrRexx(RexxString *); // in behaviour
   size_t       caselessCountStr(RexxString *);
                                       /* the following methods are in    */
                                       /* OKBBITS                         */
   RexxString  *bitAnd(RexxString *, RexxString *); // in behaviour
   RexxString  *bitOr(RexxString *, RexxString *); // in behaviour
   RexxString  *bitXor(RexxString *, RexxString *); // in behaviour
                                       /* the following methods are in    */
                                       /* OKBCONV                         */
   RexxString  *b2x(); // in behaviour
   RexxString  *c2d(RexxInteger *); // in behaviour
   RexxString  *c2x(); // in behaviour
   RexxString  *encodeBase64(); // in behaviour
   RexxString  *decodeBase64(); // in behaviour
   RexxString  *d2c(RexxInteger *); // in behaviour
   RexxString  *d2x(RexxInteger *); // in behaviour
   RexxString  *x2b(); // in behaviour
   RexxString  *x2c(); // in behaviour
   RexxString  *x2d(RexxInteger *); // in behaviour
   RexxString  *x2dC2d(RexxInteger *, bool);

   RexxInteger *match(RexxInteger *start_, RexxString *other, RexxInteger *offset_, RexxInteger *len_); // in behaviour
   RexxInteger *caselessMatch(RexxInteger *start_, RexxString *other, RexxInteger *offset_, RexxInteger *len_); // in behaviour
   bool primitiveMatch(stringsizeC_t start, RexxString *other, stringsizeC_t offset, stringsizeC_t len);
   bool primitiveCaselessMatch(stringsizeC_t start, RexxString *other, stringsizeC_t offset, stringsizeC_t len);
   RexxInteger *matchChar(RexxInteger *position_, RexxString *matchSet); // in behaviour
   RexxInteger *caselessMatchChar(RexxInteger *position_, RexxString *matchSet); // in behaviour

   RexxInteger *compareToRexx(RexxString *other, RexxInteger *start_, RexxInteger *len_); // in behaviour
   RexxInteger *caselessCompareToRexx(RexxString *other, RexxInteger *start_, RexxInteger *len_); // in behaviour
   RexxInteger *primitiveCompareTo(RexxString *other, stringsizeC_t start, stringsizeC_t len);
   RexxInteger *primitiveCaselessCompareTo(RexxString *other, stringsizeC_t start, stringsizeC_t len);

   RexxInteger *equals(RexxString *other); // in behaviour
   RexxInteger *caselessEquals(RexxString *other); // in behaviour

   RexxArray   *makeArray(RexxString *); // in behaviour

/****************************************************************************/
/*                                                                          */
/*      RexxString Methods in OKBMISC.C                                     */
/*                                                                          */
/****************************************************************************/
   int         isSymbol();

/* Inline_functions */

   inline CHARSET *getCharset() { return m17n_get_charset(this->charset); }
   inline void setCharset(CHARSET *c) { this->charset = c ? (int8_t) c->number : -1; }
   inline ENCODING *getEncoding() { return m17n_get_encoding(this->encoding); }
   inline void setEncoding(ENCODING *e) { this->encoding = e ? (int8_t) e->number : -1; }
   inline sizeB_t  getBLength() { return this->blength; };
   inline sizeC_t  getCLength() { return this->clength; };
   inline void    setBLength(sizeB_t l) { this->blength = l; };
   inline void    setCLength(sizeC_t l) { this->clength = l; };
   inline void finish(stringsizeB_t bl, ssizeC_t cl=-1) 
   { 
       this->blength = bl;
       this->clength =
           cl == -1 ?
               this->getEncoding()->codepoints(this->getStringData(), bl)
               : 
               cl;
   }
   inline const char *getStringData() { return this->stringData; };
   inline char *getWritableData() { return &this->stringData[0]; };
   inline void put(sizeB_t s, const void *b, sizeB_t l) { memcpy(getWritableData() + s, b, l); };
   inline void put(sizeB_t s, RexxString *o) { put(s, o->getStringData(), o->getBLength()); }; // todo m17n ? for the moment I use sizeB_t, like previous put method. 
   inline void set(sizeB_t s,int c, sizeB_t l) { memset((this->stringData + s), c, l); };
   inline char getCharB(sizeB_t p) { return *(this->stringData+p); }; // m17n : returns a byte, not a codepoint
   inline codepoint_t getCharC(sizeC_t p) { return *(this->stringData+size_v(p)); }; // todo call m17n : convert charpos to bytepos and return a codepoint, not a byte
   inline char putCharB(sizeB_t p,char c) { return *(this->stringData+p) = c; }; // m17n : stores a byte, not a codepoint
   //inline char putCharC(sizeC_t p,codepoint_t c) { return *(this->stringData+p) = c; }; // todo call m17n : stores a codepoint (ako replaceChar ? i.e. string can grow or shrink when utf-8 ? or is it limited to pure ascii chars <= 0x7F ?)
   inline bool upperOnly() {return (this->Attributes&STRING_NOLOWER) != 0;};
   inline bool hasLower() {return (this->Attributes&STRING_HASLOWER) != 0;};
   inline void  setUpperOnly() { this->Attributes |= STRING_NOLOWER;};
   inline void  setHasLower() { this->Attributes |= STRING_HASLOWER;};
   inline bool  nonNumeric() {return (this->Attributes&STRING_NONNUMERIC) != 0;};
   inline void  setNonNumeric() { this->Attributes |= STRING_NONNUMERIC;};
   inline bool  strCompare(const char * s) {return this->memCompare((s), strlen(s));};
   inline bool  strCaselessCompare(const char * s) { return this->blength == strlen(s) && Utilities::strCaselessCompare(s, this->stringData) == 0;}
   inline bool  memCompare(const char * s, sizeB_t l) { return l == this->blength && memcmp(s, this->stringData, l) == 0; }
   inline bool  memCompare(RexxString *other) 
   { 
       return other->charset == this->charset &&
              other->encoding == this->encoding &&
              other->blength == this->blength &&
              memcmp(other->stringData, this->stringData, blength) == 0; 
   }
   inline void  memCopy(char * s) { memcpy(s, stringData, blength); }
   inline void  toRxstring(CONSTRXSTRING &r) { r.strptr = getStringData(); r.strlength = size_v(getBLength()); } // no encoding support, so better to use blength
   inline void  toRxstring(RXSTRING &r) { r.strptr = getWritableData(); r.strlength = size_v(getBLength()); }
          void  copyToRxstring(RXSTRING &r);
   inline bool  endsWith(codepoint_t c) { return getCLength() > 0 && this->getCharC(this->getCLength() - 1) == c; }

   RexxNumberString *createNumberString();

   inline RexxNumberString *fastNumberString() {
       if (this->nonNumeric())              /* Did we already try and convert to */
                                            /* to a numberstring and fail?       */
        return OREF_NULL;                   /* Yes, no need to try agian.        */

       if (this->NumberString != OREF_NULL) /* see if we have already converted  */
         return this->NumberString;         /* return the numberString Object.   */
       return createNumberString();         /* go build the number string version */
   }

   inline int sortCompare(RexxString *other) {
       sizeB_t compareLength = blength;
       if (compareLength > other->blength) {
           compareLength = other->blength;
       }
       int result = memcmp(stringData, other->stringData, compareLength);
       if (result == 0) {
           if (blength > other->blength) {
               result = 1;
           }
           else if (blength < other->blength) {
               result = -1;
           }
       }
       return result;
   }

   inline int sortCaselessCompare(RexxString *other) {
       sizeB_t compareLength = blength;
       if (compareLength > other->blength) {
           compareLength = other->blength;
       }
       int result = StringUtil::caselessCompare(stringData, other->stringData, compareLength);
       if (result == 0) {
           if (blength > other->blength) {
               result = 1;
           }
           else if (blength < other->blength) {
               result = -1;
           }
       }
       return result;
   }

   inline int sortCompare(RexxString *other, sizeC_t startCol, sizeC_t colLength) {
       int result = 0;
       if ((startCol < clength ) && (startCol < other->clength)) {
           sizeC_t stringLength = clength;
           if (stringLength > other->clength) {
               stringLength = other->clength;
           }
           stringLength = stringLength - startCol + 1;
           sizeC_t compareLength = colLength;
           if (compareLength > stringLength) {
               compareLength = stringLength;
           }

           result = memcmp(stringData + size_v(startCol), other->stringData + size_v(startCol), size_v(compareLength)); // todo m17n
           if (result == 0 && stringLength < colLength) {
               if (clength > other->clength) {
                   result = 1;
               }
               else if (clength < other->clength) {
                   result = -1;
               }
           }
       }
       else {
           if (clength == other->clength) {
               result = 0;
           }
           else {
               result = clength < other->clength ? -1 : 1;
           }
       }
       return result;
   }

   inline int sortCaselessCompare(RexxString *other, sizeC_t startCol, sizeC_t colLength) {
       int result = 0;
       if ((startCol < clength ) && (startCol < other->clength)) {
           sizeC_t stringLength = clength;
           if (stringLength > other->clength) {
               stringLength = other->clength;
           }
           stringLength = stringLength - startCol + 1;
           sizeC_t compareLength = colLength;
           if (compareLength > stringLength) {
               compareLength = stringLength;
           }

           result = StringUtil::caselessCompare(stringData + size_v(startCol), other->stringData + size_v(startCol), size_v(compareLength)); // todo m17n
           if (result == 0 && stringLength < colLength) {
               if (clength > other->clength) {
                   result = 1;
               }
               else if (clength < other->clength) {
                   result = -1;
               }
           }
       }
       else {
           if (clength == other->clength) {
               result = 0;
           }
           else {
               result = clength < other->clength ? -1 : 1;
           }
       }
       return result;
   }


   static RexxString *newString(const char *, sizeB_t bl, ssizeC_t cl=-1, const char *charsetName=NULL);
   static RexxString *newString(const char *, sizeB_t bl, ssizeC_t cl, CHARSET *charset, ENCODING *encoding);
   static RexxString *rawString(sizeB_t bl, ssizeC_t cl=-1, const char *charsetName=NULL);
   static RexxString *rawString(sizeB_t bl, ssizeC_t cl, CHARSET *charset, ENCODING *encoding);
   static RexxString *newUpperString(const char *, stringsizeB_t bl, sstringsizeC_t cl=-1, const char *charsetName=NULL);
   static RexxString *newUpperString(const char *, stringsizeB_t bl, sstringsizeC_t cl, CHARSET *charset, ENCODING *encoding);
   static RexxString *newString(double d);
   static RexxString *newString(double d, size_t precision);
   static RexxString *newProxy(const char *);
   // NB:  newRexx() cannot be static and exported as an ooRexx method.
          RexxString *newRexx(RexxObject **, size_t); // in behaviour
   static PCPPM operatorMethods[];

   static void createInstance();
   static RexxClass *classInstance;

 protected:

   int8_t encoding;                    // string encoding (how the codepoints are serialized in stringData)
   int8_t charset;                     // string charset (what is the semantic of the codepoints)
   HashCode hashValue;                 // stored has value
   sizeC_t clength;                    /* string length in characters     */
   sizeB_t blength;                    /* string length in bytes          */
   RexxNumberString *NumberString;     /* lookaside information           */
   size_t Attributes;                  /* string attributes               */
   char stringData[4];                 /* Start of the string data part   */
 };


// some handy functions for doing cstring/RexxString manipulations

 inline void * rmemcpy(void *t, RexxString *s, sizeB_t blen) // todo m17n : blen or clen ?
 {
     return memcpy(t, s->getStringData(), blen);
 }

 inline int rmemcmp(const void *t, RexxString *s, sizeB_t blen) // todo m17n : blen or clen ?
 {
     return memcmp(t, s->getStringData(), blen);
 }

 inline char * rstrcpy(char *t, RexxString *s)
 {
     return strcpy(t, s->getStringData());
 }

 inline char * rstrcat(char *t, RexxString *s)
 {
     return strcat(t, s->getStringData());
 }

 inline int rstrcmp(const char *t, RexxString *s)
 {
     return strcmp(t, s->getStringData());
 }

 inline int rsnprintf(RexxString *s, const char *format, ...)
 {
     va_list args;
     va_start(args, format);
     int n = Utilities::vsnprintf(s->getWritableData(), size_v(s->getBLength()), format, args);
     va_end(args);
     s->finish(n >= 0 ? n : 0);
     return n;
 }

// String creation inline functions

inline RexxString *new_string(const char *s, stringsizeB_t bl, ssizeC_t cl=-1, const char *charsetName=NULL)
{
    return RexxString::newString(s, bl, cl, charsetName);
}

inline RexxString *new_string(const char *s, stringsizeB_t bl, ssizeC_t cl, CHARSET *charset, ENCODING *encoding)
{
    return RexxString::newString(s, bl, cl, charset, encoding);
}

inline RexxString *raw_string(stringsizeB_t bl, sstringsizeC_t cl=-1, const char *charsetName=NULL)
{
    return RexxString::rawString(bl, cl, charsetName);
}

inline RexxString *raw_string(stringsizeB_t bl, stringsizeC_t cl, CHARSET *charset, ENCODING *encoding)
{
    return RexxString::rawString(bl, cl, charset, encoding);
}

inline RexxString *new_string(double d)
{
    return RexxString::newString(d);
}

inline RexxString *new_string(double d, size_t p)
{
    return RexxString::newString(d, p);
}


inline RexxString *new_string(const char *string, const char *charsetName=NULL)
{
    return new_string(string, strlen(string), -1, charsetName);
}

inline RexxString *new_string(const char *string, CHARSET *charset, ENCODING *encoding)
{
    return new_string(string, strlen(string), -1, charset, encoding);
}

inline RexxString *new_string(char cc, const char *charsetName=NULL)
{
    return new_string(&cc, 1, 1, charsetName);
}

inline RexxString *new_string(char cc, CHARSET *charset, ENCODING *encoding)
{
    return new_string(&cc, 1, 1, charset, encoding);
}

inline RexxString *new_string(RXSTRING &r, const char *charsetName=NULL)
{
    return new_string(r.strptr, r.strlength, -1, charsetName);
}

inline RexxString *new_string(RXSTRING &r, CHARSET *charset, ENCODING *encoding)
{
    return new_string(r.strptr, r.strlength, -1, charset, encoding);
}

inline RexxString *new_string(CONSTRXSTRING &r, const char *charsetName=NULL)
{
    return new_string(r.strptr, r.strlength, -1, charsetName);
}

inline RexxString *new_string(CONSTRXSTRING &r, CHARSET *charset, ENCODING *encoding)
{
    return new_string(r.strptr, r.strlength, -1, charset, encoding);
}

inline RexxString *new_proxy(const char *name)
{
    return RexxString::newProxy(name);
}

inline RexxString *new_upper_string(const char *s, stringsizeB_t bl, sstringsizeC_t cl=-1, const char *charsetName=NULL)
{
    return RexxString::newUpperString(s, bl, cl, charsetName);
}

inline RexxString *new_upper_string(const char *s, stringsizeB_t bl, sstringsizeC_t cl, CHARSET *charset, ENCODING *encoding)
{
    return RexxString::newUpperString(s, bl, cl, charset, encoding);
}

inline RexxString *new_upper_string(const char *string, const char *charsetName=NULL)
{
    return new_upper_string(string, strlen(string), -1, charsetName);
}

inline RexxString *new_upper_string(const char *string, CHARSET *charset, ENCODING *encoding)
{
    return new_upper_string(string, strlen(string), -1, charset, encoding);
}


// For the needs of m17n, must have a common interface for RexxString and RexxMutableBuffer.
class IRexxString {
  public:
    operator IRexxString *() { return this; } // Convenience operator to let write f(wrapper) instead of f(&wrapper) when calling a function f(IRexxString *str)
    IRexxString *operator ->() { return this; } // Convenience operator to let write macro(wrapper) instead of macro(&wrapper) when calling a macro which expands to str->m
    virtual RexxString *makeString() = 0;
    virtual RexxMutableBuffer *makeMutableBuffer() = 0;
    virtual CHARSET *getCharset() = 0;
    virtual void setCharset(CHARSET *c) = 0;
    virtual ENCODING *getEncoding() = 0;
    virtual void setEncoding(ENCODING *e) = 0;
    virtual sizeB_t getBLength() = 0;
    virtual sizeC_t getCLength() = 0;
    virtual void setBLength(sizeB_t l) = 0; 
    virtual void setCLength(sizeC_t l) = 0;
    virtual const char *getStringData() = 0;
    virtual char *getWritableData() = 0;
};
 
 // Can't use multiple inheritance, so I use delegation...
class RexxStringWrapper : public IRexxString {
  public:
    RexxStringWrapper(RexxString *s) : str(s) {}
    inline RexxString *makeString() { return str->makeString(); }
    RexxMutableBuffer *makeMutableBuffer();
    inline CHARSET *getCharset() { return str->getCharset(); }
    inline void setCharset(CHARSET *c) { return str->setCharset(c); }
    inline ENCODING *getEncoding() { return str->getEncoding(); }
    inline void setEncoding(ENCODING *e) { str->setEncoding(e); }
    inline sizeB_t getBLength() { return str->getBLength(); }
    inline sizeC_t getCLength() { return str->getCLength(); }
    inline void setBLength(sizeB_t l) { str->setBLength(l); }
    inline void setCLength(sizeC_t l) { str->setCLength(l); }
    inline const char *getStringData() { return str->getStringData(); }
    inline char *getWritableData() { return str->getWritableData(); }
  private:
    RexxString *str;
};

#endif
