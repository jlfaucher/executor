-- Object can't inherit from a mixinclass (would raise "cannot inherit from itself")
::extension Object

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

::method setUserData class
    expose userData
    use strict arg key, value
    if \var("userData") then userData = .Directory~new
    userData[key] = value

::method setUserData
    expose userData
    use strict arg key, value
    if \var("userData") then userData = .Directory~new
    userData[key] = value

::method getUserData class
    expose userData
    use strict arg key
    if var("userData") then return userData[key]
    return .nil

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
