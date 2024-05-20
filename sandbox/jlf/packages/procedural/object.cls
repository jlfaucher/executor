/*
Procedural version of the Executor's extended methods.
*/

/******************************************************************************/
-- Object can't inherit from a mixinclass.
-- Naming convention: Object_<package name>

::class "Object_object" public

::method ppString_extension class
    use strict arg object, surroundByQuotes=.true

    -- Unlike rgf_util2, doesn't display an identityHash.
    -- To make a distinction between a real string and other objects, surround by (...)
    return "("object~string")"
