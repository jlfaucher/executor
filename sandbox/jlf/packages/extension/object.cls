-- Object can't inherit from a mixinclass (would raise "cannot inherit from itself")
::extension Object

------------------------------
-- Compatibility with ooRexx 5
------------------------------

::method isNil
    return .nil == self


------------
-- User data
------------

-- I wanted to define the class StringUserData, subclass of String, to let me
-- associate a user data to a string. But ooRexx < 5 has a bug:
-- The message "==" is sent with zero argument when requesting the hashcode of a string
-- (this is a documented behavior in the sources: RexxString::hash, RexxString::strictEqual)
-- and the implementation does not support the lack of argument when sent to a subclass of String.
-- Seems to be fixed in ooRexx 5.
-- In the meantime, I use this extension (applicable to any object, not just strings).

::method setUserData
    expose userData
    use strict arg key, value
    if \var("userData") then userData = .Directory~new
    userData[key] = value

::method getUserData
    expose userData
    use strict arg key
    if var("userData") then return userData[key]
    return .nil

---------------
-- Pretty Print
---------------

::method ppString class
    -- To make a distinction between a real string and other objects, surround by (...)
    return "("self~string")"


::method ppString
    -- Will be redefined by subclasses like array, string, etc...
    -- To make a distinction between a real string and other objects, surround by (...)
    return "("self~string")"


----------
-- Unknown
----------

-- This method is needed to avoid a stack overflow when forwarding the message "unknown".
-- Ex:
-- The class RepeaterCollector defines an "unknown" method to support the form number~number.
-- If not applicable, then it forwards the message "unknown" to the class (super): here RepeaterGenerator.
-- If RepeaterGenerator has no "unknown" method then the interpreter recalls RepeaterCollector~unknown.
::method unknown unguarded
    use arg msg, args
    raise syntax 97.1 array(self, msg)