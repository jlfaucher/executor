/*
Review calls of completeNewObject
    Array and Message don't pass any user argument to init (probably because there is no initRexx method to catch "init"
    MutableBuffer don't pass the last 2 user arguments to init
    The other classes pass all the user arguments, except Method, Routine, Package, Stem, String, WeakReference which remove the new's required arguments.

processNewArgs removes the new's required arguments (bad name, sometimes optional. Better name is "accepted" or "supported")
    BaseExecutable: 2 or 3 required (pgmname, (RexxObject **)&source, option). Method, Routine.
    Package: 2 or 3 required (pgmname, &programSource, option)
    Stem: 1 required (name, which is optional... if provided, remove it)
    String: 1 required (stringObj)
    WeakReference: 1 required (refObj)

Classes not using processNewArgs but removing some args:
    Class

Classes having new's arguments that are not removed when sending "init"
    Stream          (name is mandatory)
    Bag             (optional size managed by HashCollection::initRexx)
    CircularQueue   (size is mandatory)
        ::CLASS 'CircularQueue' subclass queue public
        ::method init                 -- create an instance, memorizes the size
          use strict arg size
          self~init:super             -- should forward the size to super
    Directory       (optional size)
    IdentityTable
    List
    Properties
    Queue           (optional size managed by QueueClass::initRexx)
    Relation
    Set
    StringTable
    Table
    (to continue with utility classes)

Workaround to get all the user arguments:
method new class

--------------------------------------------------------------------------------
HashCollection and subclasses
--------------------------------------------------------------------------------

class HashCollection : public RexxObject                                    HashCollection.hpp
    class EqualityHashCollection : public HashCollection                    HashCollection.hpp
        class IndexOnlyHashCollection : public EqualityHashCollection       HashCollection.hpp
            class BagClass : public IndexOnlyHashCollection                 BagClass.hpp
            class SetClass : public IndexOnlyHashCollection                 SetClass.hpp
        class RelationClass : public EqualityHashCollection                 RelationClass.hpp
        class TableClass : public EqualityHashCollection                    TableClass.hpp
    class IdentityHashCollection : public HashCollection                    HashCollection.hpp
        class IdentityTable : public IdentityHashCollection                 IdentityTableClass.hpp
    class StringHashCollection : public HashCollection                      HashCollection.hpp
        class DirectoryClass : public StringHashCollection                  DirectoryClass.hpp
        class MethodDictionary: public StringHashCollection                 MethodDictionnary.hpp
        class StringTable : public StringHashCollection                     StringTableClass.hpp


--------------------------------------------------------------------------------
Native "init" implementation: initRexx
--------------------------------------------------------------------------------

setup.cpp "init"
    RexxObject::initRexx        0
    QueueClass::initRexx        1
    HashCollection::initRexx    1       not declared in CppCode.cpp
    DirectoryClass::initRexx    1       ??? not found
    ListClass::initRexx         1
    SupplierClass::initRexx     2

CppCode.cpp
    CPPM(RexxObject::initRexx),
    CPPM(ListClass::initRexx),
    CPPM(QueueClass::initRexx),
    CPPM(SupplierClass::initRexx),
    CPPM(DirectoryClass::initRexx),


RexxObject *RexxObject::initRexx()
{
    return OREF_NULL;
}


The following native "init" allow to not reach the Object's init, so no error "too many args" raised by Object.
There is no forward to super (good, Object takes 0 arg)).


RexxObject *QueueClass::initRexx(RexxObject *initialSize)
{
    // It would be nice to do this expansion in the new method, but it sort
    // of messes up subclasses (e.g. CircularQueue) if we steal the first new
    // argument.  We will set the capacity here, even if it means an immediate expansion

    // the capacity is optional, but must be a positive numeric value
    size_t capacity = optionalLengthArgument(initialSize, DefaultArraySize, ARG_ONE);
    ensureSpace(capacity);
    return OREF_NULL;
}


RexxObject *HashCollection::initRexx(RexxObject *initialSize)
{
    // the capacity is optional, but must be a positive numeric value
    size_t capacity = optionalLengthArgument(initialSize, DefaultTableSize, ARG_ONE);
    initialize(capacity);
    return OREF_NULL;
}


RexxObject *ListClass::initRexx(RexxObject *initialSize)
{
    // the capacity is optional, but must be a positive numeric value
    size_t capacity = optionalLengthArgument(initialSize, DefaultListSize, ARG_ONE);
    initialize(capacity);
    return OREF_NULL;
}


RexxObject *SupplierClass::initRexx(ArrayClass *_items, ArrayClass *_indexes)
{
    Protected<ArrayClass> new_items = arrayArgument(_items, ARG_ONE);           // both values are required
    Protected<ArrayClass> new_indexes = arrayArgument(_indexes, ARG_TWO);

    // technically, we could probably directly assign these since this really is a constructor,
    // but it doesn't hurt to use these here.
    setField(items, new_items);
    setField(indexes, new_indexes);
    position = 1;
    return OREF_NULL;
}


--------------------------------------------------------------------------------
Call stacks: from .bag~new to .bag~init
--------------------------------------------------------------------------------

.bag~new(10)
#5	0x00000001003631f5 in HashCollection::initRexx(RexxObject*) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/support/HashCollection.cpp:66
#6	0x000000010038f267 in CPPCode::run(Activity*, MethodClass*, RexxObject*, RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/execution/CPPCode.cpp:174
#7	0x0000000100329d31 in MethodClass::run(Activity*, RexxObject*, RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/MethodClass.cpp:171
#8	0x000000010033f4cb in RexxObject::messageSend(RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/ObjectClass.cpp:899
#9	0x000000010031c905 in RexxObject::sendMessage(RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/ObjectClass.hpp:510
#10	0x000000010031d7d6 in RexxClass::completeNewObject(RexxObject*, RexxObject**, unsigned long) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/ClassClass.cpp:1899
#11	0x0000000100317d63 in BagClass::newRexx(RexxObject**, unsigned long) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/BagClass.cpp:128

.myBag~new(10)
#5	0x00000001003631f5 in HashCollection::initRexx(RexxObject*) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/support/HashCollection.cpp:66
#6	0x000000010038f267 in CPPCode::run(Activity*, MethodClass*, RexxObject*, RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/execution/CPPCode.cpp:174
#7	0x0000000100329d31 in MethodClass::run(Activity*, RexxObject*, RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/MethodClass.cpp:171
#8	0x000000010033f74b in RexxObject::messageSend(RexxString*, RexxObject**, unsigned long, RexxClass*, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/ObjectClass.cpp:955
#9	0x00000001003f8030 in ExpressionStack::send(RexxString*, RexxClass*, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/expression/ExpressionStack.hpp:78
#10	0x00000001004126e6 in RexxInstructionMessage::execute(RexxActivation*, ExpressionStack*) at /local/rexx/oorexx/official/main/trunk/interpreter/instructions/MessageInstruction.cpp:191
#11	0x0000000100393425 in RexxActivation::run(RexxObject*, RexxString*, RexxObject**, unsigned long, RexxInstruction*, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/execution/RexxActivation.cpp:591
#12	0x00000001003a156c in RexxCode::run(Activity*, MethodClass*, RexxObject*, RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/execution/RexxCode.cpp:210
#13	0x0000000100329d31 in MethodClass::run(Activity*, RexxObject*, RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/MethodClass.cpp:171
#14	0x000000010033f4cb in RexxObject::messageSend(RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/ObjectClass.cpp:899
#15	0x000000010031c905 in RexxObject::sendMessage(RexxString*, RexxObject**, unsigned long, ProtectedObject&) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/ObjectClass.hpp:510
#16	0x000000010031d7d6 in RexxClass::completeNewObject(RexxObject*, RexxObject**, unsigned long) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/ClassClass.cpp:1899
#17	0x0000000100317d63 in BagClass::newRexx(RexxObject**, unsigned long) at /local/rexx/oorexx/official/main/trunk/interpreter/classes/BagClass.cpp:128


--------------------------------------------------------------------------------
Big picture: How a user-defined init is supported per class
--------------------------------------------------------------------------------

(hierarchy copied from rexxpg)

Object                                              RexxObject::initRexx        0
ok  Alarm
ok  AlarmNotification (mixin)
0   Array (inherit OrderedCollection)
ok  Bag (inherit MapCollection SetCollection)       HashCollection::initRexx    1
N/A Buffer
-1  Class
ok  Collection (mixin)
        MapCollection (mixin)
        OrderedCollection (mixin)
        SetCollection (mixin)
ok  Comparable (mixin)
    Comparator (mixin)
        CaselessColumnComparator (mixin)
        CaselessComparator (mixin)
        CaselessDescendingComparator (mixin)
        ColumnComparator (mixin)
        DescendingComparator (mixin)
        InvertingComparator (mixin)
        NumericComparator (mixin)
    DateTime (inherit Comparable Orderable)
ok  Directory (inherit MapCollection)               HashCollection::initRexx    1
        Properties
    EventSemaphore
    File (inherit Comparable Orderable)
ok? IdentityTable (inherit MapCollection)           HashCollection::initRexx    1
    InputOutputStream (mixin) (inherit InputStream OutputStream)
        Stream (mixin)
    InputStream (mixin)
    List (inherit OrderedCollection)
0   Message (inherit MessageNotification AlarmNotification)
    MessageNotification (mixin)
-3  Method
    Monitor
KO  MutableBuffer
    MutexSemaphore
    Orderable (mixin)
    OutputStream (mixin)
    Package
    Pointer
    Queue (inherit OrderedCollection)
ok      CircularQueue
ok? Relation (inherit MapCollection)                HashCollection::initRexx    1
    RexxContext
    RexxInfo
    RexxQueue
-3  Routine
ok? Set (inherit MapCollection SetCollection)       HashCollection::initRexx    1
    Singleton
    StackFrame
-1  Stem (inherit MapCollection)
-1  String (inherit Comparable)
ok? StringTable (inherit MapCollection)             HashCollection::initRexx    1
ok  Supplier
        StreamSupplier
ok? Table (inherit MapCollection)                   HashCollection::initRexx    1
    Ticker
    TimeSpan (inherit Comparable Orderable)
    Validate
    VariableReference
    WeakReference

*/
--------------------------------------------------------------------------------
-- Demo, to run with ooRexx5
--------------------------------------------------------------------------------

alarm = .myAlarm~new("00:00:00", .myAlarmNotification~new, "arg1", "arg2")
alarm~cancel

alarmNotif = .myAlarmNotification~new("arg1", "arg2")

array1 = .myArray~new(2,2,2)

bag = .bag~new(10)
bag = .myBag~new(10, "arg1", "arg2")

cqueue = .myCircularQueue~new(10, "arg1", "arg2")

class = .myClass~new("arg1", "arg2")

collection = .myCollection~new("arg1", "arg2")

comparable = .myComparable~new("arg1", "arg2")

directory = .Directory~new(10)
directory = .myDirectory~new(10, "arg1", "arg2")

msg1 = .myMessage~new("target", "substr", "individual", 2, 3)
msg2 = .myMessage~new("target", "substr", "array", (2, 3))

buf1 = .myMutableBuffer~new("test")
buf2 = .myMutableBuffer~new("test", 10)
buf3 = .myMutableBuffer~new("test", 10, "arg3", "arg4", "arg5")

stem = .myStem~new("arg1", "arg2")

str = .myString~new("test", "arg1", "arg2")

supplier = .mySupplier~new("arg1", "arg2")


::class myAlarm subclass Alarm
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    self~init:super(arg(1), arg(2))


::class myAlarmNotification subclass AlarmNotification
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    -- forward class (super)    -- reach Object~init: 0 argument expected at scope Object


::class myArray subclass Array
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    -- forward class (super)    -- reach Object~init: 0 argument expected at scope Object


::class myBag subclass Bag
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    if arg(1, "e") then self~init:super(arg(1))    -- HashCollection::initRexx


::class myClass subclass Class
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    -- forward class (super)    -- reach Object~init: 0 argument expected at scope Object


::class myCircularQueue subclass CircularQueue
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    if arg(1, "e") then self~init:super(arg(1))    -- Queue takes an optional size


::class myCollection subclass Collection
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    -- forward class (super)    -- reach Object~init: 0 argument expected at scope Object


::class myComparable subclass Comparable
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    -- forward class (super)    -- reach Object~init: 0 argument expected at scope Object


::class myDirectory subclass Directory
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    if arg(1, "e") then self~init:super(arg(1))    -- DirectoryClass::initRexx  CAN'T FIND IT! Is it HashCollection::initRexx associated to .Directory~init?


::class myMessage subclass Message
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    -- forward class (super)    -- reach Object~init: 0 argument expected at scope Object


::class myMutableBuffer subclass MutableBuffer
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    -- forward class (super)    -- reach Object~init: 0 argument expected at scope Object


::class myStem subclass Stem
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    -- This one surprised me... It's possible to pass an optional name .Stem~new(name)
    -- but not possible to pass it via init, because there is no Stem~init (and probably too late anyway)
    -- forward class (super)    -- reach Object~init: 0 argument expected at scope Object


::class myString subclass String
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    -- This one surprised me... A string arg is mandatory .String~new(string)
    -- but not possible to pass it via init, because there is no String~init (and probably too late anyway)
    -- forward class (super)    -- String takes a mandatory string arg


::class mySupplier subclass Supplier
    ::method new class
    say
    say self~id "new"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)

    ::method init
    say
    say self~class~id "init"
    say "arg()="arg()
    if arg() \== 0 then say arg(1, "a")~tostring
    say "super="super
    forward class (super)    -- reach Object~init: 0 argument expected at scope Object
