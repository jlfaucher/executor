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
/* REXX Kernel                                               ArrayClass.hpp   */
/*                                                                            */
/* Primitive Array Class Definitions                                          */
/*                                                                            */
/******************************************************************************/
#ifndef Included_RexxArray
#define Included_RexxArray

#define RaiseBoundsNone     0x00000000
#define RaiseBoundsUpper    0x00000001
#define RaiseBoundsInvalid  0x00000002
#define RaiseBoundsTooMany  0x00000004
#define RaiseBoundsAll      0x0000000F
#define ExtendUpper         0x00000010


typedef struct copyElementParm {
   size_t firstChangedDimension;
   RexxArray *newArray;
   RexxArray *newDimArray;
   RexxArray *oldDimArray;
   size_t deltaDimSize;
   size_t copyElements;
   size_t skipElements;
   RexxObject **startNew;
   RexxObject **startOld;
} COPYELEMENTPARM;

 class PartitionBounds {
 public:
     enum {
         SmallRange = 10   // the size where we revert to an insertion sort
     };

     PartitionBounds(size_t l, size_t r) : left(l), right(r) {}
     PartitionBounds() : left(0), right(0) {}

     inline bool isSmall() { return (right - left) <= SmallRange; }
     inline size_t midPoint() { return (left + right) / 2; }

     size_t left;       // start of the range
     size_t right;
 };


 class BaseSortComparator {
 public:
     inline BaseSortComparator() { }

     virtual wholenumber_t compare(RexxObject *first, RexxObject *second);
 };

 class WithSortComparator : public BaseSortComparator {
 public:
     inline WithSortComparator(RexxObject *c) : comparator(c) { }
     virtual wholenumber_t compare(RexxObject *first, RexxObject *second);
 protected:
     RexxObject *comparator;
 };


 class RexxArray : public RexxObject {
  public:

   inline void * operator new(size_t size, void *objectPtr) { return objectPtr; };
   void * operator new(size_t, RexxObject **, size_t, RexxClass *);
   void * operator new(size_t, RexxObject *);
   void * operator new(size_t, RexxObject *, RexxObject *);
   void * operator new(size_t, RexxObject *, RexxObject *, RexxObject *);
   void * operator new(size_t, RexxObject *, RexxObject *, RexxObject *, RexxObject *);
   void * operator new(size_t, RexxObject *, RexxObject *, RexxObject *, RexxObject *, RexxObject *);
   void * operator new(size_t, size_t, RexxObject **);
   void * operator new(size_t, size_t, size_t, RexxClass *cls = TheArrayClass);

   inline void operator delete(void *) {;}
   inline void operator delete(void *, void *) {;}
   inline void operator delete(void *, RexxObject **, size_t, RexxClass *) {;}
   inline void operator delete(void *, RexxObject *) {;}
   inline void operator delete(void *, RexxObject *, RexxObject *) {;}
   inline void operator delete(void *, RexxObject *, RexxObject *, RexxObject *) {;}
   inline void operator delete(void *, RexxObject *, RexxObject *, RexxObject *, RexxObject *) {;}
   inline void operator delete(void *, RexxObject *, RexxObject *, RexxObject *, RexxObject *, RexxObject *) {;}
   inline void operator delete(void *, size_t, RexxObject **) {;}
   inline void operator delete(void *, size_t, size_t, RexxClass *cls) {;}
   inline void operator delete(void *, RexxObject **) { ; }

   inline RexxArray(RESTORETYPE restoreType) { ; };
   inline RexxArray() { ; };
   inline ~RexxArray() { ; };

   void         init(size_t, size_t);
   void         live(size_t);
   void         liveGeneral(int reason);
   void         flatten(RexxEnvelope *);
   RexxObject  *copy();
   RexxArray   *makeArray();
   RexxArray   *allItems(RexxObject *maxItems=OREF_NULL);
   RexxArray   *allIndexes(RexxObject *maxIndexes=OREF_NULL);
   RexxString  *toString(RexxString *, RexxString *);
   RexxString  *makeString(RexxString *, RexxString *);
// Temporary bypass for BUG #1700606
#if 0
   RexxString  *primitiveMakeString();
#endif
   RexxObject  *getRexx(RexxObject **, size_t, size_t);
   RexxObject  *getApi(size_t pos);
   void         put(RexxObject * eref, size_t pos);
   RexxObject  *putRexx(RexxObject **, size_t, size_t);
   void         putApi(RexxObject * eref, size_t pos);
   RexxObject  *remove(size_t);
   RexxObject  *removeRexx(RexxObject **, size_t, size_t);
   RexxObject  *appendRexx(RexxObject *);
   size_t       append(RexxObject *);
   void         setExpansion(RexxObject * expansion);
   RexxInteger *available(size_t position);
   bool         validateIndex(RexxObject **, size_t, size_t, size_t, stringsize_t &);
   RexxInteger *sizeRexx();
   RexxObject  *firstRexx();
   RexxObject  *lastRexx();
   RexxObject  *firstItem();
   RexxObject  *lastItem();
   size_t       lastIndex();
   RexxObject  *nextRexx(RexxObject **, size_t, size_t);
   RexxObject  *previousRexx(RexxObject **, size_t, size_t);
   RexxArray   *section(size_t, size_t);
   RexxObject  *sectionRexx(RexxObject *, RexxObject *);
   RexxObject  *sectionSubclass(size_t, size_t);
   bool         hasIndexNative(size_t);
   RexxObject  *hasIndexRexx(RexxObject **, size_t, size_t);
   bool         hasIndexApi(size_t);
   size_t       items();
   RexxObject  *itemsRexx();
   RexxObject  *dimension(RexxObject *);
   RexxObject  *getDimensions();
   size_t       getDimension();
   RexxObject  *supplier(RexxObject *maxItems=OREF_NULL);
   RexxObject  *join(RexxArray *);
   RexxArray   *extend(size_t);
   void         shrink(size_t);
   size_t       indexOf(RexxObject *);
   RexxArray   *extendMulti(RexxObject **, size_t, size_t);
   void         resize();
   void         ensureSpace(size_t newSize);
   RexxObject  *newRexx(RexxObject **, size_t, size_t);
   RexxObject  *of(RexxObject **, size_t, size_t);
   RexxObject  *empty();
   RexxObject  *isEmpty();
   RexxObject  *fill(RexxObject *);
   RexxObject  *index(RexxObject *);
   RexxObject  *hasItem(RexxObject *);
   RexxObject  *removeItem(RexxObject *);
   wholenumber_t sortCompare(RexxObject *comparator, RexxObject *left, RexxObject *right);
   RexxArray   *stableSortRexx();
   RexxArray   *stableSortWithRexx(RexxObject *comparator);
   RexxObject  *insertRexx(RexxObject *_value, RexxObject *index);
   size_t       insert(RexxObject *_value, size_t index);
   RexxObject  *deleteRexx(RexxObject *index);
   RexxObject  *deleteItem(size_t index);

   inline size_t       addLast(RexxObject *item) { return this->insert(item, this->size() + 1); }
   inline size_t       addFirst(RexxObject *item) { return this->insert(item, 1); }
   inline size_t       insertAfter(RexxObject *item, size_t index) { return this->insert(item, index); }
   inline RexxArray   *array() { return this->makeArray(); }
   inline size_t       size() { return this->expansionArray->arraySize; }
   inline RexxObject  *get(size_t pos) { return (this->data())[pos-1];}
   inline RexxObject **data() { return this->expansionArray->objects; }
   inline RexxObject **data(size_t pos) { return &((this->data())[pos-1]);}
   inline RexxArray   *getExpansion() { return this->expansionArray; }
   size_t              findSingleIndexItem(RexxObject *item);
   RexxObject *        indexToArray(size_t idx);
   RexxObject *        convertIndex(size_t idx);

   inline bool isMultiDimensional() { return this->dimensions != OREF_NULL && this->dimensions->size() != 1; }
   inline bool isSingleDimensional() { return !isMultiDimensional(); }

   static RexxArray *createMultidimensional(RexxObject **dims, size_t count, RexxClass *);

   static void createInstance();
   // singleton class instance;
   static RexxClass *classInstance;
   static RexxArray *nullArray;

   static const size_t ARRAY_MIN_SIZE;
   static const size_t ARRAY_DEFAULT_SIZE;   // default size for ooRexx allocation

 protected:

   void         mergeSort(BaseSortComparator &comparator, RexxArray *working, size_t left, size_t right);
   void         merge(BaseSortComparator &comparator, RexxArray *working, size_t left, size_t mid, size_t right);
   static void  arraycopy(RexxArray *source, size_t start, RexxArray *target, size_t index, size_t count);
   size_t       find(BaseSortComparator &comparator, RexxObject *val, int bnd, size_t left, size_t right);
   void         openGap(size_t index, size_t elements);
   void         closeGap(size_t index, size_t elements);
   inline RexxObject **slotAddress(size_t index) { return &(this->data()[index - 1]); }
   inline size_t       dataSize() { return ((char *)slotAddress(size() + 1)) - ((char *)data()); }


   static const size_t MAX_FIXEDARRAY_SIZE;

   size_t arraySize;                   /* current size of array         */
   size_t maximumSize;                 /* Maximum size array can grow   */
   size_t lastElement;                 // location of last set element
   RexxArray *dimensions;              /* Array containing dimensions - null if 1-dimensional */
   RexxArray *expansionArray;          /* actual array containing data  */
   RexxObject  *objects[1];            /* Data.                         */
 };


inline RexxArray *new_externalArray(size_t s, RexxClass *c)
{
    return new (s, RexxArray::ARRAY_DEFAULT_SIZE, c) RexxArray;
}

/**
 * Create an array with a given size.
 *
 * @param s      The size of the array.
 *
 * @return The new array item.
 */
inline RexxArray *new_array(size_t s)
{
    return new (s, RexxArray::ARRAY_MIN_SIZE, TheArrayClass) RexxArray;
}


/**
* Make a zero-length array item.
*
* @return A new array.
*/
inline RexxArray *new_array()
{
    return new_array((size_t)0);
}


/**
 * Create an array populated with objects from another source.
 *
 * @param s      The number of objects.
 * @param o      The pointer to the set of objects.
 *
 * @return A new array object.
 */
inline RexxArray *new_array(size_t s, RexxObject **o)
{
    return new (s, o) RexxArray;
}


/**
 * Create a new array with one item.
 *
 * @param o1     The object to add to the array.
 *
 * @return A new array object.
 */
inline RexxArray *new_array(RexxObject *o1)
{
    return new (o1) RexxArray;
}


/**
 * Create a new array with two items.
 *
 * @param o1     The first object to add to the array.
 * @param o2     The second object to add
 *
 * @return A new array object.
 */
inline RexxArray *new_array(RexxObject *o1, RexxObject *o2)
{
    return new (o1, o2) RexxArray;
}


/**
 * Create a new array with three items.
 *
 * @param o1     The first object to add to the array.
 * @param o2     The second object to add
 * @param o3     The third object to add.
 *
 * @return A new array object.
 */
inline RexxArray *new_array(RexxObject *o1, RexxObject *o2, RexxObject *o3)
{
    return new (o1, o2, o3) RexxArray;
}


/**
 * Create a new array with four items.
 *
 * @param o1     The first object to add to the array.
 * @param o2     The second object to add
 * @param o3     The third object to add.
 * @param o4     The fourth object to add.
 *
 * @return A new array object.
 */
inline RexxArray *new_array(RexxObject *o1, RexxObject *o2, RexxObject *o3, RexxObject *o4)
{
    return new (o1, o2, o3, o4) RexxArray;
}


/**
 * Create a new array with five items.
 *
 * @param o1     The first object to add to the array.
 * @param o2     The second object to add
 * @param o3     The third object to add.
 * @param o4     The fourth object to add.
 * @param o5     The fifth object to add.
 *
 * @return A new array object.
 */
inline RexxArray *new_array(RexxObject *o1, RexxObject *o2, RexxObject *o3, RexxObject *o4, RexxObject *o5)
{
    return new (o1, o2, o3, o4, o5) RexxArray;
}

 #endif
