/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

::extension Package inherit PackageCompatibilityWithOORexx5


/******************************************************************************/
::class "PackageCompatibilityWithOORexx5" mixinclass Object public

::attribute local get
    expose local
    -- Method init not working, so manage initialization here
    if \ var("local") then local = .Directory~new
    return local
