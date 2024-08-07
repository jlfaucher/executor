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
/* REXX Kernel                                               ClassClass.hpp   */
/*                                                                            */
/* Primitive Class Class Definitions                                          */
/*                                                                            */
/******************************************************************************/
#ifndef Included_RexxClass
#define Included_RexxClass



 class RexxClass : public RexxObject {
  public:
   void *operator new(size_t, size_t, const char *, RexxBehaviour *, RexxBehaviour *);
   inline void *operator new(size_t size, void *ptr) {return ptr;};
   inline void operator delete(void *) { }
   inline void operator delete(void *, void *) { }
   inline void operator delete(void *, size_t, const char *, RexxBehaviour *, RexxBehaviour *) { }

   inline RexxClass(){;};
   inline RexxClass(RESTORETYPE restoreType) { ; };

   void live(size_t);
   void liveGeneral(int reason);
   void flatten(RexxEnvelope*);
   RexxObject *unflatten(RexxEnvelope*);
   RexxObject *makeProxy(RexxEnvelope*);
   bool        isEqual(RexxObject *);

   HashCode     hash();
   HashCode     getHashValue();
   RexxObject * equal(RexxObject *);
   RexxObject * strictEqual(RexxObject *);
   RexxObject * notEqual(RexxObject *);
   RexxObject * setRexxDefined();
   RexxInteger *queryMixinClass();
   RexxObject  *isMetaClassRexx(); // ooRexx5
   RexxObject  *isAbstractRexx(); // ooRexx5
   RexxString  *getId();
   RexxClass   *getBaseClass();
   RexxClass   *getMetaClass();
   RexxClass   *getSuperClass();
   RexxArray   *getSuperClasses();
   RexxArray   *getClassSuperClasses() { return classSuperClasses; }
   RexxArray   *getSubClasses();
   void         defmeths(RexxTable *);
   void         setInstanceBehaviour(RexxBehaviour *);
   RexxTable  *getInstanceBehaviourDictionary();
   RexxTable  *getBehaviourDictionary();
   RexxString *defaultName();
   void        subClassable(bool);
   void        subClassable(RexxClass *superClass, bool restricted);
   void        mergeSuperClassScopes(RexxBehaviour *target_instance_behaviour);
   RexxObject *defineMethod(RexxString *, RexxMethod *);
   RexxObject *defineMethods(RexxTable *);
   RexxObject *deleteMethod(RexxString *);
   RexxObject *defineClassMethod(RexxString *method_name, RexxMethod *newMethod);
   void        removeClassMethod(RexxString *method_name);
   RexxMethod *method(RexxString *);
   RexxSupplier *methods(RexxClass *);
   void        updateSubClasses();
   void        updateInstanceSubClasses();
   void        createClassBehaviour(RexxBehaviour *);
   void        createInstanceBehaviour(RexxBehaviour *);
   void        methodDictionaryMerge(RexxTable *, RexxTable *);
   RexxTable  *methodDictionaryCreate(RexxTable *, RexxClass *);
   RexxObject *inherit(RexxClass *, RexxClass *);
   RexxObject *uninherit(RexxClass *);
   RexxObject *enhanced(RexxObject **, size_t, size_t);
   RexxClass  *mixinclass(PackageClass *, RexxString *, RexxClass *, RexxTable *);
   RexxClass  *subclass(PackageClass *, RexxString *, RexxClass *, RexxTable *);
   RexxClass  *mixinClassRexx(RexxString *, RexxClass *, RexxObject *); // ooRexx5 because the C++ mixinclass method takes a new argument 'package'
   RexxClass  *subclassRexx(RexxString *, RexxClass *, RexxObject *); // ooRexx5 because the C++ subclass method takes a new argument 'package'
   RexxClass  *newRexx(RexxObject **args, size_t argCount, size_t named_argCount);
   void        setMetaClass(RexxClass *);
   bool        isCompatibleWith(RexxClass *other);
   RexxObject *isSubclassOf(RexxClass *other);
   RexxString  *defaultNameRexx();
   void        setPackage(PackageClass *s); // ooRexx5
   PackageClass *getPackage(); // ooRexx5
   void        completeNewObject(RexxObject *obj, RexxObject **initArgs = OREF_NULL, size_t argCount = 0); // ooRexx5


   inline bool         isRexxDefined() { return (classFlags & REXX_DEFINED) != 0; };
   inline bool         isMixinClass()  { return (classFlags & MIXIN) != 0; };
   inline bool         isMetaClass() { return (classFlags & META_CLASS) != 0; };
   inline bool         isAbstract() { return (classFlags & ABSTRACT) != 0; } // ooRexx5
   inline bool         hasUninitDefined()   { return (classFlags & HAS_UNINIT) != 0; };
   inline void         setHasUninitDefined()   { classFlags |= HAS_UNINIT; };
   inline void         clearHasUninitDefined()   { classFlags &= ~HAS_UNINIT; };
   // NB:  This clears every flag BUT the UNINIT flag
   inline void         setInitialFlagState()   { classFlags &= HAS_UNINIT; };
   inline bool         parentHasUninitDefined()   { return (classFlags & PARENT_HAS_UNINIT) != 0; };
   inline void         setParentHasUninitDefined()   { classFlags |= PARENT_HAS_UNINIT; };
   inline bool         isPrimitiveClass() { return (classFlags & PRIMITIVE_CLASS) != 0; }
   inline void         setMixinClass() { classFlags |= MIXIN; }
   inline void         setNonPrimitive() { classFlags &= ~PRIMITIVE_CLASS; };
   inline RexxBehaviour *getInstanceBehaviour() {return this->instanceBehaviour;};
   inline void         setMetaClass() { classFlags |= META_CLASS; }
   inline void         setAbstract() { classFlags |= ABSTRACT; } // ooRexx5
   inline void         clearAbstract() { classFlags &= ~ABSTRACT; } // ooRex5
          void         addSubClass(RexxClass *);
          void         removeSubclass(RexxClass *c);
          void         checkAbstract(); // ooRexx5
          void         makeAbstract(); // ooRexx5

   static void processNewArgs(RexxObject **, size_t, RexxObject ***, size_t *, size_t, RexxObject **, RexxObject **);

   static void createInstance();
   // singleton class instance;
   static RexxClass *classInstance;

 protected:
     enum
     {
        REXX_DEFINED      = 0x00000001,   // this class is a native rexx class
        MIXIN             = 0x00000004,   // this is a mixin class
        HAS_UNINIT        = 0x00000008,   // this class has an uninit method
        META_CLASS        = 0x00000010,   // this class is a meta class
        PRIMITIVE_CLASS   = 0x00000020,   // this is a primitive class
        PARENT_HAS_UNINIT = 0x00000040,
        ABSTRACT          = 0x00000080    // the class is abstract
     };

                                        /* Subclassable and subclassed       */
     RexxString    *id;                 /* classes will have a name string   */
                                        /* class methods specific to this    */
                                        /* class                             */
     RexxTable     *classMethodDictionary;
                                        /* instances of this class inherit   */
     RexxBehaviour *instanceBehaviour;  /* this behaviour                    */
                                        /* methods added to this class       */
     RexxTable     *instanceMethodDictionary;
     RexxClass     *baseClass;          /* Baseclass of this class           */
     RexxArray     *metaClass;          /* Metaclass of this class           */
                                        /* Metaclass mdict                   */
     RexxArray     *metaClassMethodDictionary;
     RexxIdentityTable *metaClassScopes;  /* Metaclass scopes                  */
                                        /* The superclass and any inherited  */
     RexxArray     *classSuperClasses;  /* mixins for class behaviour        */
                                        /* The superclass and any inherited  */
                                        /* mixins for instance behaviour     */
     RexxArray     *instanceSuperClasses;
                                        /* class specific information        */
                                        /* defines for this field are at the */
     uint32_t       classFlags;         /* top of this header file           */

     RexxList      *subClasses;         // our list of weak referenced subclasses
     PackageClass  *package;            // source we're defined in (if any)
 };
 #endif
