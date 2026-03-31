/*
Extension by delegation.

First need:
Add support for user data.
See oorexxshell_queries_std.cls for a concrete usage example.

Example:
    myString = .Extender~new("dog")
    myString~setUserData("lang", "english")
    myString~setUserData("french", "chien")
    say myString "in" myString~getUserData("lang") "translates to" myString~getUserData("french") "in french."
Output:
    dog in english translates to chien in french.

Keep it compatible with official ooRexx 4.2.
*/

/******************************************************************************/
::class "Extender" public subclass Monitor


::method init
    forward class (super) continue


::method string
    forward to (self~current)


::method request
    forward to (self~current)


-- For proper display by ooRexxShell when the monitored object is a string,
-- ~isa(.String) must return .true.
::method isa
    forward to (self~current)


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
