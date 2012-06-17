/*
rgf_util2 wrappers to make the services available as methods on predefined classes.
Quickly implemented, but could be more efficient...
obj~method2(args) --> routine(obj, reworked_args) --> obj~method(re_reworked_args)

For a real library of methods, an rgf_util2_oo.rex should be written to use the variable
"self" where appropriate, instead of passing the object as first parameter.
obj~method2(args) --> obj~method(reworked_args)
*/

::requires "rgf_util2/rgf_util2.rex"


-- Each method delegates to a routine having the same name.
-- Can't call directly the routine, because some arguments may be omitted, and must remain omitted.
-- The only way to keep them omitted is to pass the arguments array.
-- The self object must be inserted in the list of arguments, most of the time in first position,
-- but sometimes in second position (like changeStr2).

::extension Object
-- Beware ! .nil is somewhat bizarre and can't be extended, i.e. .nil~pp2 will raise "does not understand"
::method pp2 ; return pp2~call(self, .context~args)
::method ppIndex2 ; return ppIndex2~call(self, .context~args)
-- Sometimes I want the maximum of details, whatever the object. Will be redefined for collections.
::method dump2 ; say pp2~call(self, .context~args) ; return self


::routine dump public
    -- .nil can't be extended, so must find a way to dump *ANY* object with all the details, including .nil
    -- Since a method can't do that, a routine will do !
    use strict arg object
    if object == .nil then say pp2(object)
    else if object~class == .class then say pp2(object)
    else object~dump2
    return object


-- JLF : redefines the pp2 routine which is defined in rgf_util2.rex
-- Since I pretty-print array using square brackets, I prefer to avoid square brackets
/* Show non-printable chars as Rexx hex-strings.
   If non-string object, then show its string value and hash-value.
*/
::routine pp2 public       -- rgf, 20091214
  use strict arg a1

  if \a1~isA(.string) then
  do
     if a1~isA(.Collection) then
        return "("a1~string "("a1~items "items)" "id#_" || (a1~identityHash)")"
     else
        return "("a1~string "id#_" || (a1~identityHash)")" -- JLF round bracked instead of square bracket
  end

  -- strings are surrounded by quotes, except string numbers
  a1str = a1~string
  if \a1~dataType("N") then a1str = "'"a1str"'"
  return escape2(a1str)


::extension String
::method abbrev2 ; return abbrev2~call(self, .context~args)
::method changeStr2 ; return changeStr2~call(self, .context~args, 2)
::method compare2 ; return compare2~call(self, .context~args)
::method countStr2 ; return countStr2~call(self, .context~args, 2)
::method delStr2 ; return delStr2~call(self, .context~args)
::method delWord2 ; return delWord2~call(self, .context~args)
::method lastPos2 ; return lastPos2~call(self, .context~args, 2)
::method left2 ; return left2~call(self, .context~args)
::method lower2 ; return lower2~call(self, .context~args)
::method overlay2 ; return overlay2~call(self, .context~args)
::method pos2 ; return pos2~call(self, .context~args, 2)
::method right2 ; return right2~call(self, .context~args)
::method subchar2 ; return subchar2~call(self, .context~args)
::method substr2 ; return substr2~call(self, .context~args)
::method subWord2 ; return subWord2~call(self, .context~args)
::method upper2 ; return upper2~call(self, .context~args)
::method word2 ; return word2~call(self, .context~args)
::method wordIndex2 ; return wordIndex2~call(self, .context~args)
::method wordLength2 ; return wordLength2~call(self, .context~args)
::method wordPos2 ; return wordPos2~call(self, .context~args, 2)
::method parseWords2 ; return parseWords2~call(self, .context~args)
::method escape2 ; return escape2~call(self, .context~args)
::method enquote2 ; return enquote2~call(self, .context~args)


::extension Collection
::method dump2 ; dump2~call(self, .context~args) ; return self
::method makeRelation2 ; return makeRelation2~call(self, .context~args)


::extension Array
::method sort2 ; return sort2~call(self, .context~args)
::method stableSort2 ; return stableSort2~call(self, .context~args)


::extension Supplier
::method dump2 ; dump2~call(self, .context~args) ; return self


::extension Method
::method ppMethod2 ; return ppMethod2~call(self, .context~args)


------------------------------------------------------------------------------
-- Helpers to wrap rgf_util2

::extension Array
::method prepend
    -- We need to forward the method's arguments to the routine, with an additional parameter
    -- inserted at the begining of the arguments array.
    use strict arg item
    size = self~dimension(1)
    r = .Array~new(size+1)
    r[1] = item
    do i=1 to size
        if self~hasIndex(i) then r[i+1] = self[i]
    end
    return r
::method swap
   -- Some routine have the self object in second position (ex : changeStr2)
   -- This method lets swap two items, given their indexes.
   use strict arg index1, index2
   item1 = self[index1]
   item2 = self[index2]
   self[index1] = item2
   self[index2] = item1
   return self


::extension String
::method call
    -- Here, the string (self) is the name of a routine
    -- Call this routine by passing object as first parameter (default)
    use strict arg object, argsArray, objectPos=1
    objectArgsArray = argsArray~prepend(object)
    if objectPos <> 1 then objectArgsArray~swap(1, objectPos)
    .context~package~findRoutine(self)~callWith(objectArgsArray)
    if var('result') then return result
    return

