/*
This script needs a modified ooRexx interpreter which supports the ::EXTENSION directive
>>-::EXTENSION--classname----+-------------------+-----------------><
                             +-INHERIT--iclasses-+
                             
The idea here is to let add new methods on any class (including predefined classes), but not
let override a method of a predefined class.
Not possible to remove a method with ::extension.
*/

say .Object~new                 -- todo ::extension shouldn't allow to redefine a predefined method

.Class~define("do_floating", .methods~do_floating)
.Object~define("do_floating", .methods~do_floating)

--.Object~do_floating
--.Class~do_floating

.String~userprop_class = 1
.String~do_class                 -- runs Object::do_class
--.String~do_instance
--.String~do_floating

.String~new("test")~userprop_instance = 1
.String~new("test")~do_instance  -- runs Object::do_instance
.String~new("test")~do_floating  -- runs ::do_floating

"test"~userprop_instance = 1
"test"~do_instance               -- runs Object::do_instance
"test"~do_floating               -- runs ::do_floating

.Array~userprop_class = 1
.Array~do_class                  -- runs Mixin1::do_class
-- .Array~do_instance
-- .Array~do_floating

.array~of(1,2)~userprop_instance = 1
.array~of(1,2)~do_instance       -- runs Mixin2::do_instance
.array~of(1,2)~do_floating       -- runs ::do_floating

.C1~new~userprop_instance = 1
.C1~new~do_instance              -- currently, you can redefine several times a method. The 'last' redefinition wins
.C1~new~do_instance_extension    -- runs C1::do_instance_extension

.C2~new~userprop_instance = 1
.C2~new~do_instance              -- runs C2::do_instance
.C2~new~do_instance_extension    -- runs C1::do_instance_extension


-----------------------------------------------------------------------------
::method do_floating
    say "runs ::do_floating"

    
-----------------------------------------------------------------------------
-- No error here, despite the fact that the class is defined after
-- It's because the class is searched when the ExtensionDirective is installed (so after the whole parsing of the source)
::extension nonexistent
::method m

::class nonexistent

-----------------------------------------------------------------------------
::extension Class
::attribute userprop_class class
::attribute userprop_instance
::method do_class class
    say "runs Class::do_class"
::method do_instance
    say "runs Class::do_instance"

    
-----------------------------------------------------------------------------
::extension Object
::attribute userprop_class class
::attribute userprop_instance
::method do_class class
    say "runs Object::do_class"
::method do_instance
    say "runs Object::do_instance"
::method objectName
    return "todo ::extension shouldn't allow to redefine a predefined method"
    
-----------------------------------------------------------------------------
::class C1
::method do_instance
    say "runs C1::do_instance"

    
-----------------------------------------------------------------------------
::class Mixin1 mixinclass Object
::method do_class class
    say "runs Mixin1::do_class"

::class Mixin2 mixinclass Object
::method do_instance
    say "runs Mixin2::do_instance"

    
-----------------------------------------------------------------------------
::extension Array inherit Mixin1 Mixin2

    
-----------------------------------------------------------------------------
::class C2 subclass C1
::method do_instance
    say "runs C2::do_instance"


-----------------------------------------------------------------------------
::extension C1
::method do_instance_extension
    say "runs C1::do_instance_extension"
::method do_instance
    say "currently, you can redefine several times a method. The 'last' redefinition wins"

