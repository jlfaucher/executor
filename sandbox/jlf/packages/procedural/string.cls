/*
Procedural version of the Executor's extended methods.
*/

/******************************************************************************/
::class "StringHelpers" public

/* Enquote string, escape quote/apostrophe. Optionally supply character(s) to serve as
   quote/apostrophe.
*/
::method quoted_extension class
  use strict arg string, quote='"'
  return quote || string~changestr(quote, quote~copies(2)) || quote


/******************************************************************************/
::class "MutableBufferPrettyPrinter" public

::method ppString_extension class
    use strict arg mutableBuffer, surroundByQuotes=.true
    -- Mutable buffers are prefixed with "M"
    pp = "M'"mutableBuffer~string"'"
    -- Use 0xXX notation for escaped character
    return escape3(pp)


/******************************************************************************/
::class "StringPrettyPrinter" public

::method ppString_extension class
    use strict arg string, surroundByQuotes=.true
    -- strings are surrounded by quotes, except string numbers.
    if string~dataType("N") then do
        if string < 0 then return string -- the first character is the minus sign
        if string~matchChar(1, " +") then return string -- the first character is already a space or a plus
        return " "string               -- the first character is a space (could also display a plus sign)
    end
    pp = string
    if surroundByQuotes then pp = .ExtensionDispatcher~quoted(pp, "'")
    return escape3(pp) -- Use 0xXX notation for escaped characters


/******************************************************************************/
-- escape2 copied from rgf_util2 and adapted. Renamed escape3.
-- Escape non-printable chars by printing them between square brackets [].

/*
rgf_util2 uses escape2 (better for novices), Executor uses escape3:
    escape2("000102414243040506"x)      -- ["000102"x || "ABC" || "040506"x]
    escape3("000102414243040506"x)      -- '[000102]ABC[040506]'
*/

::routine escape3 private -- private to avoid collision with string.cls where this routine is also declared
  parse arg a1

  --non_printable=xrange("00"x,"1F"x)||"FF"x
  non_printable="00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F FF"x
  res=""

  do while a1\==""
     pos1=verify(a1, non_printable, "M")
     if pos1>0 then
     do
        pos2=verify(a1, non_printable, "N" , pos1)

        if pos2=0 then
           pos2=length(a1)+1

        if pos1=1 then
        do
           parse var a1 char +(pos2-pos1) a1
           bef=""
        end
        else
           parse var a1 bef +(pos1-1) char +(pos2-pos1) a1

        if res=="" then
        do
           if bef \=="" then res=bef -- res=enquote2(bef) '|| '
        end
        else
        do
           res=res||bef -- res=res '||' enquote2(bef) '|| '
        end

        res=res || '['char~c2x']'
     end
     else
     do
        if res<>""  then
           res=res||a1 -- res=res '||' enquote2(a1)
        else
           res=a1

        a1=""
     end
  end
  return res
