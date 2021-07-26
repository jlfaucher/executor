#!/usr/bin/env rexx

/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Description: Class to encode and decode ooRexx objects in JSON.            */
/*                                                                            */
/* Copyright (c) 2010-2021 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.ibm.com/developerworks/oss/CPLv1.0.htm                          */
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
/* Author: Brandon W. Cherry                                                  */
/*                                                                            */
/*----------------------------------------------------------------------------*/

/** This ooRexx package supplies the <a href="https://en.wikipedia.org/wiki/JSON">JSON</a>
*   (JavaScript Object Notation) support.
*/



/* ========================================================================= */

/** This class implements <a href="https://www.rfc-editor.org/info/rfc8259">RFC 8259</a>
(formerly <code>RFC 4627</code>) and allows to encode Rexx objects as JSON strings and
*   parse JSON strings into Rexx objects.

<p> This version does no Unicode related encoding or decoding.
*   (Rexx programmers can do Unicode related processing e.g. by taking advantage of Java via the
*   <a href="https://sourceforge.net/projects/bsf4oorexx/">BSF4ooRexx</a>
*   package which defines the public routine 'bsf.iconv(string,fromCharset,toCharset)').

*<p>The mapping between Rexx and JSON is as follows:
*   <ul>
*   <li>a Rexx <code>MapCollection</code> maps to a JSON object (comma separated list of
*       index ':' item(s), enquoted in curly brackets), a JSON object by default to a <code>.Directory</code>,
*
*   <li>an OrderdCollection maps to a JSON array (comma separated list of values, enquoted in sqaure brackets),
*       a JSON array to a <code>.Array</code>,
*
*   <li>if a Rexx object contains the "makejson" conversion method, it will be used and the
        returned JSON encoding string used for it,
*
*   <li>string values map to JSON strings (enquoted in double quotes) and vice versa,
*
*   <li><code>.true</code> (the value <code>1</code>) maps to JSON <code>true</code> (no surrounding quotes),
*       a JSON <code>true</code> to an instance of <code>.JsonBoolean</code> that behaves like <code>.true</code>,
*
*   <li><code>.false</code> (the value <code>0</code>) maps to JSON <code>false</code> (no surrounding quotes),
*       a JSON <code>false</code> to an instance of <code>.JsonBoolean</code> that behaves like <code>.false</code>,
*
*   <li><code>.nil</code> maps to JSON <code>null</code> (no surrounding quotes).
*
*   </ul>
*
*   If one needs to keep the boolean property in the JSON encoding, the Rexx objects
*   <code>.json~true</code> (an instance of </code>.JsonBoolean</code>) and
*   <code>.json~false</code> (an instance of </code>.JsonBoolean</code>) must be used, as
*   they will render to their respective JSON encodings (<code>true</code> or <code>false</code>).
*
<p>Example:

<pre>
   obj=.StringTable~new          -- a .StringTable (a MapCollection)
   obj['Name']    ="Caesar"      -- a string
   obj['children']=3             -- a number
   obj['Parents']= .array~of('Anna', 'Bertram') -- a .Array (an OrderableCollection)
   obj['Salary']  =.nil          -- no value at all (not employed)
   obj['rich']    =.json~false   -- use .Json's false (a JsonBoolean)
   obj['poor']    =.json~true    -- use .Json's true (a JsonBoolean)
   call show "obj", obj          -- show Rexx object
   say "======================================"

   j=.json~new                   -- create a minifying JSON converter

   jsonString1=j~toJson(obj)     -- encode object as JSON string
   say
   say "json (minified):"
   say
   say jsonString1               -- show (minified) JSON string
   say
   say "rendering 'jsonString1' to 'obj1':"
   obj1=j~fromJson(jsonString1)  -- create object from JSON string
   call show "obj1", obj1        -- show Rexx object
   say "--------------------------------------"

   j~legible=.true               -- make JSON string legible for humans
   jsonString2=j~toJson(obj)
   say
   say "json (legible):"
   say
   say jsonString2               -- show (legible) JSON string
   say
   say "rendering 'jsonString2' to 'obj2':"
   obj2=j~fromJson(jsonString2)  -- create object from JSON string
   call show "obj2", obj2        -- show Rexx object
   say "--------------------------------------"
</pre>
*
<p> Yields:
*
<pre>
   show(): 'obj', dumping a .StringTable:

       children: 3
       Name    : Caesar
       Parents : Anna, Bertram
       poor    : 1
       rich    : 0
       Salary  : The NIL object
   ======================================

   json (minified):

   {"children":3,"Name":"Caesar","Parents":["Anna","Bertram"],"poor":true,"rich":false,"Salary":null}

   rendering 'jsonString1' to 'obj1':
   show(): 'obj1', dumping a .Directory:

       children: 3
       Name    : Caesar
       Parents : Anna, Bertram
       poor    : 1
       rich    : 0
       Salary  : The NIL object
   --------------------------------------

   json (legible):

   {
       "children": 3,
       "Name": "Caesar",
       "Parents": [
           "Anna",
           "Bertram"
       ],
       "poor": true,
       "rich": false,
       "Salary": null
   }

   rendering 'jsonString2' to 'obj2':
   show(): 'obj2', dumping a .Directory:

       children: 3
       Name    : Caesar
       Parents : Anna, Bertram
       poor    : 1
       rich    : 0
       Salary  : The NIL object
   --------------------------------------
</pre>

*
* @author Brandon W. Cherry (original author)
* @author Rony G. Flatscher (adapted and added code to ooRexx 4.2.0 and 5.0.0)
* @author Adrian Baginski (added minify, toMinifiedJson)
*/
::class  JSON public

/* --------------------------- class methods --------------------------- */

/** Class getter attribute method that returns the version information of this class.
*
* @return version as a string, formatted as: major*100+minor || "." || yyyymmdd
*/

::attribute version get class
  use strict arg           -- no argument allowed!
  return "100.20210608"    -- version in the form: major*100+minor || "." || yyyymmdd


/*
   BOM according to JSP2.3 specs, chapter "Table JSP.4-1 Byte representations of the BOM":
   Bytes Encoding Form
   FE FF       UTF-16, big-endian
   FF FE       UTF-16, little-endian
   00 00 FE FF UTF-32, big-endian
   FF FE 00 00 UTF-32, little-endian
   EF BB BF    UTF-8

   also cf: <https://en.wikipedia.org/wiki/Byte_order_mark>
*/

/** Determines the encoding by inspecting the first four bytes of a JSON string, cf.
*   cf. <https://www.ietf.org/rfc/rfc4627.txt>. Note, the JSON standard mandates UTF-8
*   encoding to be used if exchanging data with outside of a closed system. JSON parsers
*   are nevertheless expected to handle Unicode
    <a href="https://en.wikipedia.org/wiki/Byte_order_mark">BOMs</a> (byte order marks).
*
* @param string JSON string in which the first four bytes may be a BOM (byte order mark)
*
* @return "UTF-8", "UTF-16BE", "UTF-16LE", "UTF-32BE", "UTF-32LE", depending on the BOM
*/
::method getEncoding class    -- determine UTF-encoding, return UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE
  use strict arg string=""

  select
     when string~startsWith("00 00 FE FF"x) then return "UTF-32BE"
     when string~startsWith("FF FE 00 00"x) then return "UTF-32LE"
     when string~startsWith("FE FF"x      ) then return "UTF-16BE"
     when string~startsWith("FF FE"x      ) then return "UTF-16LE"
     otherwise return "UTF-8"    -- default encoding
  end

/** Determines at which position the JSON payload data starts.

* @param string JSON string in which the first four bytes may be a BOM (byte order mark)
*
* @return JSON data offset (5 for UTF-32, 3 for UTF-16, else 1)
*/
::method getEncodingDataOffset class    -- determine UTF-encoding, return UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE
  use strict arg string=""

  select
     when string~startsWith("00 00 FE FF"x) then return 5
     when string~startsWith("FF FE 00 00"x) then return 5
     when string~startsWith("FE FF"x      ) then return 3
     when string~startsWith("FF FE"x      ) then return 3
     otherwise return 1          -- default offset (default encoding, UTF-8)
  end


/** Returns the JSON BOM (byte order mark) characters according to the desired encoding,
*   cf. <https://www.ietf.org/rfc/rfc4627.txt>.
*
* @param encoding one of "UTF-8", "UTF-16BE", "UTF-16LE", "UTF-32BE", "UTF-32LE"
*
* @return the empty string for "UTF-8", or the BOM value to use according to the encoding parameter
*/
::method getJsonBOM class  -- determine UTF-encoding, return UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE
  use strict arg encoding="UTF-8"

  select
     when encoding="UTF-8"    then return ""    -- default, in JSON no explicit BOM
     when encoding="UTF-32BE" then return "00 00 FE FF"x
     when encoding="UTF-32LE" then return "FF FE 00 00"x
     when encoding="UTF-16BE" then return "FE FF"x
     when encoding="UTF-16LE" then return "FF FE"x
     otherwise return ""   -- use default encoding, ie. UTF-8
  end

/** Returns the .JsonBoolean proxy for <code>.true</code>, which ensures a proper JSON encoding.
    It can be used interchangeably with ooRexx' <code>.true</code> or <code>1</code> values.

    @return the .JsonBoolean value for <code>.true</code>
*/
::attribute true     get class
  return .jsonBoolean~true

/** Returns the .JsonBoolean proxy for <code>.false</code>, which ensures a proper JSON encoding.
    It can be used interchangeably with ooRexx' <code>.false</code> or <code>0</code> values.

    @return the .JsonBoolean value for <code>.false</code>
*/
::attribute false    get class
  return .jsonBoolean~false


/** Getter that returns the class to be used for collecting map values (either .Directory or .StringTable).
*
* @return the current class that will be used for storing the map values ("object attributes")
*/
::attribute jsonDirClass get class
  expose json_dirClass
  return json_dirClass

/** Setter that allows to change the <code>.Directory</code> to another dirlike class (e.g.
*   <code>.StringTable</code> since ooRexx 5.0) to be used to encode the JSON object in a Rexx object.
*
* @param newDirlikeClass either the .Directory class (default) or .StringTable class
*
P @return oldClass the class previously used to encode JSON object data
*/
::attribute jsonDirClass set class
  expose json_dirClass
  use strict arg newDirlikeClass
  json_dirClass=newDirlikeClass                    -- save class in package local
  -- .context~package~local~json.DirClass=newDirlikeClass  -- save in package local to speed up lookup
                     .local~json.DirClass=newDirlikeClass

/** StringTable with unescape JSON strings. */
::attribute uJS        private class

/** Array with escape for JSON strings. */
::attribute rexx2json  private class

/** String with JSON whitescape characters. */
::attribute whiteSpace private class

/** String with JSON whitescape and ending delimiter characters to ease parsing the end of a JSON value. */
::attribute endsValue  private class


/** Utility class method to ease reading JSON files into an ooRexx object.
*
<p>Example:
<pre>
   rexxObject = .json~fromJsonFile('some.json')
</pre>
*
*  @param fn file name or file object to read JSON data from
*
* @return rexxObject ooRexx object representing the JSON text
*/
::method fromJsonFile class
  use strict arg fn

  s=.stream~new(fn)~~open("read")   -- open stream for reading
  jsonText=s~charin(1,s~chars)      -- read all chars, close stream
  s~close
  json=self~new                     -- create json instance
  return json~fromJson(jsonText)    -- use it to create ooRexx representation


/** Utility class method to ease creating legible JSON files from an ooRexx object.
*   If a minified JSON file is desired instead, supply <code>.false</code> as the
*   third argument.
*
<p>Example:
<pre>
   .json~toJsonFile('some.json',someRexxObject)
</pre>
*
*  @param fn file name or file object to write produced JSON text to
*  @param rexxObject rexxObject to encode as JSON
*  @param isLegible optional logical value, defaults to <code>.true</code>
*
*/
::method toJsonFile class
  expose legible
  use strict arg fn, rexxObject, isLegible=.true

  json=self~new(isLegible)          -- create json instance
  jsonText=json~toJSON(rexxObject)  -- create JSON text representing the rexxObject

   -- open stream for writing, delete existing file, if any, write json text to it
  .stream~new(fn)~~open("write replace")~~charout(jsonText)~~close


/** Class constructor that sets up default values. */
::method init class
  expose uJS rexx2json whiteSpace endsValue
  self~jsonDirClass=.Directory      -- defaults to .Directory, can be set to .StringTable as well

  eJS = .StringTable~new   -- escape Javascript
  eJS['\']   = '\\'   -- escape for: backslash character
  eJS['08'x] = '\b'   -- escape for: backspace character
  eJS['09'x] = '\t'   -- escape for: tab character
  eJS['0A'x] = '\n'   -- escape for: newline (line feed) character
  eJS['0C'x] = '\f'   -- escape for: form feed character
  eJS['0D'x] = '\r'   -- escape for: carriage return character
  eJS['"']   = '\"'   -- escape for: double quote character
  eJS['/']   = '\/'   -- escape for: slash character

  uJS = .StringTable~new   -- unescape Javascript
  do index over eJS
      uJS[eJS[index]] = index
  end
    /*
    -- rgf, 2016-07-24: sequence to be applied in changeStr(): first must be "\" -> "\\" as "\" is the escape char
    -- rgf, 2021-06-01: to match current json.cls behaviour (and tests) we do not process "\uxxyy" if "xx" is not "00";
                        as a result we cannot blindly escape "\" to "\\" as we need to leave "\u" intact
    */
  -- rexx2json =.array~of(.array~of('\'  , '\\'), - -- escape for: backslash character
  rexx2json =.array~of(.array~of('08'x, '\b'), - -- escape for: backspace character
                       .array~of('09'x, '\t'), - -- escape for: tab character
                       .array~of('0A'x, '\n'), - -- escape for: newline (line feed) character
                       .array~of('0C'x, '\f'), - -- escape for: form feed character
                       .array~of('0D'x, '\r'), - -- escape for: carriage return character
                       .array~of('"'  , '\"'), - -- escape for: double quote character
                       .array~of('/'  , '\/'), - -- escape for: slash character
                      )

  whiteSpace="20 0d 0a 09"x
  endsValue=whitespace || "}],"   -- chars that indicate end of value (note includes blank!)


/* --------------------------- instance methods ------------------------ */


/** Attribute that controls whether whitespace gets added to the JSON string in order
*   to make it better legible for humans. Defaults to <code>.true</code>.
*/
::attribute legible get

/** Setter method that controls whether the created JSON string gets created to be better legible for humans.
*
* @param newLegible a logical value (either <code>.true</code> for legible or <code>.false</code> for minimized)
*/
::attribute legible set
  expose legible
  use strict arg newLegible
  legible=(newLegible=.true)  -- if not .true, then .false


/** Constructor that creates a minifying JSON object by default. If it is desired to
*   create legible JSON strings from Rexx objects, then supply the value <code>.true</code>
*   as an argument.
*
* @param legible a logical value, defaults to <code>.false</code>, which causes minified json encodings
*/
::method init
    expose uJS whitespace endsValue level indent rexx2json legible
    use strict arg legible=(.false) -- default to minified version

    .validate~logical("legible", legible) -- make sure we have a logical value
    clz=self~class
    uJS       =clz~uJS
    rexx2json =clz~rexx2json
    whitespace=clz~whitespace
    endsValue =clz~endsValue

    level =0      -- start out with level 0
    indent="    " -- use four spaces per level for indentation


/**
 * Converts a Rexx object its JSON string representation.
 *
 * @param  rexxObject   The object to convert may be a <code>MapCollection</code> like
               a <code>.directory</code> or <code>.stringTable</code>, an <code>OrderableCollection</code>
               like an <code>.array</code>, a <code>.string</code>, <code>.nil</code>, <code>.json~true</code>,
               <code>.json~false</code>, or one that has a either a <code>makeJson</code>,
               <code>makeString</code> or <code>makeArray</code> method.

 * @return a string that represents the JSON encoding of the supplied <code>rexxObject</code> in a
               minimized form (attribute <code>legible</code> set to <code>.false</code>) or
               in a legible form (attribute <code>legible</code> set to <code>.true</code>
               causing insertion of whitespace to ease reading for humans)
 */
::method toJSON
    expose buffer level legible
    use strict arg rexxObject
    buffer = .mutablebuffer~new
    self~encodeRexxObject(rexxObject)
    return buffer~string

/** Control method that determines which method should encode the supplied Rexx object.
*
* @param  rexxObject the Rexx object to encode as a JSON string
*/
::method encodeRexxObject private
    expose buffer level indent
    use arg rexxObject

    select
        when rexxObject~isA(.OrderedCollection) then do  -- e.g. .array, .list, ...
            self~encodeOrderedCollection(rexxObject)
        end
        when rexxObject~isA(.MapCollection) then do      -- e.g. .directory, .relation
            self~encodeMapCollection(rexxObject)
        end
        when rexxObject~isA(.string) then do             -- a plain string in hand
            self~encodeRexxString(rexxObject)
        end
        when rexxObject~isA(.JsonBoolean) then do        -- a JSON Boolean
             buffer~append(rexxObject~makeJSON)          -- no quotes
        end
        when rexxObject=.nil then do
            buffer~append('null')                        -- no quotes
        end
        otherwise
            if rexxObject~hasMethod('makejson') then     -- own rendering, if so use it
               buffer~append(rexxObject~makejson)

            else if rexxObject~hasMethod('makestring') then -- render as string
               self~encodeRexxString(rexxObject~makestring)

            else if rexxObject~hasMethod('makearray') then  -- render as array
               self~encodeRexxObject(rexxObject~makearray)  -- recursive call

            else        -- use rexxObject's objectname
               buffer~append('"', rexxObject~objectName, '"')
    end


/** Encodes any ooRexx ordered collection, including array objects.
*
* @param  rexxObject the Rexx object to encode
*/
::method encodeOrderedCollection private
    expose buffer level indent legible
    use arg rexxObject

    if legible then  -- add whitespace and indentations to make it for humans easier to read the JSON string
    do
       strIndent1=indent~copies(level)       -- create outer indentation string once
       strIndent2=indent~copies(level+1)     -- create inner indentation string once

       buffer~append('[')
       sup=rexxObject~supplier
       level+=1                  -- increase level
       /* if an array has no items, do not use indentation between opening and closing bracket */
       if \sup~available then
           strIndent1 = ""

       do while sup~available    -- iterate and encode item entries only
            buffer~append(.endOfLine)
            buffer~append(strIndent2)
            self~encodeRexxObject(sup~item, .true ) -- encode item object (recursive call), indent
            sup~next             -- position on next item
            if sup~available then
               buffer~append(',')
       end
       level-=1                  -- decrease level
       buffer~append(.endOfLine, strIndent1, ']')
    end
    else
    do
       buffer~append('[')
       sup=rexxObject~supplier

       do while sup~available    -- iterate and encode item entries only
            self~encodeRexxObject(sup~item)  -- encode item object (recursive call)
            sup~next             -- position on next item
            if sup~available then
               buffer~append(',')
       end
       buffer~append(']')
    end



/** Encodes any ooRexx unordered collection, including directory objects.
*   The index objects are sorted caselessly in ascending order to ease human
*   analysis of the encoded data.
*
*   If an unordered collection possesses the <code>ALLAT</code> method, then multiple
*   entries per index are expected (like the ooRexx <code>.Relation</code> class),
*   which will cause the encoding of multiple index entries, one per item. If the
*   index is not a string object, then the <code>MAKESTRING</code> method is used to
*   get a string object rendering representing the index object. If a
*   <code>MAKESTRING</code> method is not available then the object name and its
*   identity hash value (encoded as hexadecimal value) are used instead to represent
*   the index object.
*
* @param  rexxObject the Rexx object to encode
*/
::method encodeMapCollection private
    expose buffer level indent legible
    use arg rexxObject

    bHasAllAt=rexxObject~hasMethod("ALLAT")        -- e.g. a .relation
    tmpIdx=.set~new~union(rexxObject~allIndexes)~allindexes -- create an array with unique index objects
    tmpDir=.json.DirClass~new
    do idx over tmpIdx
       select  -- turn idx into a string, if necessary
          when idx~isA(.string)      then strIdx=idx
          when idx~isA(.JsonBoolean) then strIdx=idx~value  -- use logical value as string value
          when idx~hasMethod("MAKESTRING") then       -- use the request-protocol to obtain a string value
               strIdx=idx~request("STRING")
          otherwise
               strIdx=idx~objectName"@"idx~identityHash~d2x
       end

       if bHasAllAt then      -- per index more than one item?
       do
          arr=rexxObject~allAt(idx)
          if arr~items=1 then tmpDir[strIdx]=arr[1]
                         else tmpDir[strIdx]=sort(arr)
       end
       else
          tmpDir[strIdx]=rexxObject~at(idx)
    end
    tmpIdx~sortWith(.caselessComparator~new) -- sort caselessly in ascending order

    if legible then  -- add whitespace and indentations to make it for humans easier to read the JSON string
    do
       strIndent1=indent~copies(level)       -- create outer indentation string once
       strIndent2=indent~copies(level+1)     -- create inner indentation string once

       buffer~append('{', .endOfLine)
       level+=1                     -- increase level
       nrIdx=tmpIdx~size
       do i=1 to nrIdx
          strIdx=tmpIdx~at(i)       -- get index
          item=tmpDir~at(strIdx)    -- get item
               -- index part
          buffer~append(strIndent2)
          self~encodeRexxString(strIdx, .true)
          buffer~append(': ')
               -- item part
          self~encodeRexxObject(item) -- encode item portion (recursive call)
          if i<nrIdx then buffer~append(',')
          buffer~append(.endofline)
       end
       level-=1                     -- decrease level
       buffer~append(strIndent1, '}')
    end
    else
    do
       buffer~append('{')
       nrIdx=tmpIdx~size
       do i=1 to nrIdx
          strIdx=tmpIdx~at(i)       -- get index
          item=tmpDir~at(strIdx)    -- get item
               -- index part
          self~encodeRexxString(strIdx, .true)
          buffer~append(':')
               -- item part
          self~encodeRexxObject(item)
          if i<nrIdx then buffer~append(',')
       end
       buffer~append('}')
    end
    return

sort: procedure      -- try to sort allAt-array elements; if a syntax error occurs return argument as received
  signal on syntax   -- intercept a syntax condition while sorting elements
  use arg arr
  arr=arr~copy~sort
  return arr         -- return sorted array
syntax:
  return arr         -- return original array



/** Encodes a Rexx string, applying the JSON character escaping strings.
*
* @param  rexxObject the Rexx string to encode
* @param  bQuote optional logical value, defaults to .false, if .true, enquotes Rexx string value
*/
::method encodeRexxString private
    expose buffer eJS level indent rexx2json legible
    use strict arg rexxObject, bQuote=.false

    if rexxObject==""  then           -- empty string?
       buffer~append('""')
    else
    do
        if rexxObject~dataType('n') then  -- a numeric value?
        do
           if bQuote=.true then
              buffer~append('"', rexxObject, '"')
           else
              buffer~append(rexxObject)
        end
        else
        do
            mb=.mutableBuffer~new(rexxObject,rexxObject~length*2)
            -- leave Unicode escapes as is
            do pos=1
               pos=mb~pos('\', pos)
               if pos=0 then leave
               if mb[pos+1]<>'u' then
               do
                  mb~replaceAt("\\", pos, 1)
                  pos+=1
               end
            end

            do arr over rexx2json   -- iterate over replacement pairs
               mb~changeStr(arr[1],arr[2])
            end
            -- now replace remaining control chars
            ctlChars=xrange('00'x, '07'x, '0b'x, '0b'x, '0e'x, '1f'x)
            do forever
               pos=mb~verify(ctlChars,"Match")
               if pos=0 then leave  -- done escaping control characters to Unicode escapes
               char=mb[pos]         -- get char to escape
               mb~changeStr(char,"\u00"char~c2x)
            end

            buffer~append('"', mb~string, '"')
        end
    end


/* ========================================================================= */


/**
 * Converts a JSON encoded string to a Rexx object.
 *
 * @param  jsonString   some JSON encoded string
 */
::method fromJSON
    expose jsonString jsonPos jsonStringLength
    use strict arg jsonString

    signal on syntax
    .ArgUtil~validateClass("jsonString", jsonString, .string)  -- check for correct type

    if jsonString="" then
       raise syntax 93.900 array( 'empty string not allowed' )

    signal on user parseError
      -- determine starting character position
    jsonPos=self~class~getEncodingDataOffset(jsonString)

    jsonStringLength = jsonString~length
    self~trimTrailingWhitespace   -- skip leading whitespace starting out at jsonPos (changing it)
    self~trimLeadingWhitespace   -- skip leading whitespace starting out at jsonPos (changing it)

    rexxObject = self~parseJSONvalue
    if jsonPos >= jsonStringLength then return rexxObject

    self~trimLeadingWhitespace   -- skip leading whitespace starting out at jsonPos (changing it)
    if jsonPos >= jsonStringLength then return rexxObject
    message = 'Expected end of input'
    signal extraChars

parseError:
    c = condition('o')
    message = c['ADDITIONAL'][1]
extraChars:
    tmpAdd="jsonPos="jsonPos "| condition:" c~condition
    tmpJsonString=""
    len=jsonString~length
    if len>0 then
    do
       if len>25 then tmpJsonString=jsonString~left(25)"..."
                 else tmpJsonString=jsonString~left(len)
    end
    raise syntax 93.900 array(message 'at position ['jsonPos"]: ["tmpJsonString"], jsonString~length=["len"]" tmpAdd)

syntax: raise propagate


/** Control method that determines which parse method gets used.
 *
 *  @return the Rexx object that results from parsing the entire JSON encoded string and representing it
 */
::method parseJSONvalue private
    expose jsonString jsonPos
    signal on user parseError

    char=jsonString[jsonPos]
    select
        when char = '{' then do          -- an unordered JSON collection
            jsonPos += 1
            return self~parseJSONobject
        end
        when char = '[' then do          -- a JSON array
            jsonPos += 1
            return self~parseJSONarray
        end
        when char = '"' then do          -- a JSON string
            jsonPos += 1
            return self~parseJSONstring
        end
        otherwise return self~parseJSONother
    end
    return
parseError: raise propagate

/**
 * Converts a JSON object into a Rexx <code>Directory</code> object or - starting
 * with ooRexx 5.0 - optionally into a <code>StringTable</code> object.
 *
 */
::method parseJSONobject private
    expose jsonString jsonPos
    signal on user parseError

    rexxDirectory = .json.DirClass~new

    char=jsonString[jsonPos]
    if char == '}' then do
        jsonPos = jsonPos + 1
        return rexxDirectory
    end
    else self~parseJSONobjectValue(rexxDirectory)

    do forever
        self~trimLeadingWhitespace
        char=jsonString[jsonPos]
        select
            when char == '}' then do
                jsonPos = jsonPos + 1
                return rexxDirectory
            end
            when char == ',' then do
                jsonPos = jsonPos + 1
                self~parseJSONobjectValue(rexxDirectory)
            end
            otherwise raise user parseError array('Expected end of a JSON object or a new "name:value" pair')
        end
    end
    return
parseError: raise propagate

/**
 * Converts and stores a JSON <code>name:value</code> pair as an <code>index</code>/<code>item</code> pair
 * in the Rexx directory like object.
 *
 * @param  rexxDirectory   A Rexx directory object to store the JSON "name:value" pair as "index,item" pair
 */
::method parseJSONobjectValue private
    expose jsonString jsonPos
    signal on user parseError
    use arg rexxDirectory

    self~trimLeadingWhitespace
    char=jsonString[jsonPos]
    if char == '"' then do
        jsonPos = jsonPos + 1
        index = self~parseJSONstring
    end
    else raise user parseError array('JSON object name must start with a quote, which is missing')

    self~trimLeadingWhitespace
    char=jsonString[jsonPos]
    if char == ':' then do
        jsonPos = jsonPos + 1
        self~trimLeadingWhitespace
        rexxDirectory[index] = self~parseJSONvalue
    end
    else raise user parseError array('Expected colon separating JSON object name and value is missing')
    return
parseError: raise propagate

/**
 * Converts a JSON array into a Rexx array object.
 *
 * @return returns the Rexx array representing the parsed JSON array
 *
 */
::method parseJSONarray private
    expose jsonString jsonPos
    signal on user parseError

    rexxArray = .array~new

    /* remove all leading whitespaces */
    self~trimLeadingWhitespace
    char=jsonString[jsonPos]

    if char == ']' then do
        jsonPos += 1
        return rexxArray
    end
    else self~parseJSONarrayValue(rexxArray)

    do forever
        self~trimLeadingWhitespace
        char=jsonString[jsonPos]
        select
            when char == ']' then do
                jsonPos = jsonPos + 1
                return rexxArray
            end
            when char == ',' then do
                jsonPos = jsonPos + 1
                self~parseJSONarrayValue(rexxArray)
            end
            otherwise raise user parseError array('Expected end of a JSON array or a new "name:value" pair')
        end
    end

parseError: raise propagate


/**
 * Converts a JSON array value and appends it to a Rexx array.
 *
 * @param rexxArray a Rexx array to which the JSON array value gets appended
 *
 */
::method parseJSONarrayValue private
    expose jsonString
    signal on user parseError
    use arg rexxArray

    self~trimLeadingWhitespace
    rexxArray~append(self~parseJSONvalue)
    return

parseError: raise propagate


/**
 * Converts a quoted JSON string into a Rexx string. Any JSON character escapes are
 * converted to the characters they represent.
 *
 * @return the Rexx string representing the JSON string
 */
::method parseJSONstring private
    expose jsonString uJS jsonPos jsonStringLength
    signal on user parseError

    rexxString = .mutablebuffer~new
    do forever
        char=jsonString[jsonPos]
        if char == '\' then do
            parse value jsonString with =(jsonPos) char2 +2

            if char2='\u' then   -- one of the escaped control chars in hand
            do

               if jsonString~substr(jsonPos,4)='\u00' then
               do
                  ctlChar=jsonString~subStr(jsonPos+4,2)
                  if \ctlChar~datatype("X") then
                  do
                     message = """\u00"" is not followed by two hexadecimal characters, position:" jsonPos", chars=["ctlChar"]"
                     raise syntax 93.900 array(message)
                  end
                   rexxString~append(ctlChar~x2c)
                   jsonPos += 6
               end
               else  -- leave Unicode escape in place (remainder will be processed on next round)
               do
                 jsonPos += 2
                 rexxString~append(char2)
               end

            end
            else if uJS~hasIndex(char2) then do
                jsonPos = jsonPos + 2
                rexxString~append(uJS[char2])
            end

            -- illegal escape char raise exception
            else do
                message = "illegal escape """char2""" sequence, position:" jsonPos
                raise syntax 93.900 array(message)
            end
        end
        else do
            jsonPos = jsonPos + 1
            if char == '"' then
            do
               if jsonString[jsonPos] == '"' then   -- raise error
               do
                  message = "illegal sequence of double quotes at position:" jsonPos
                  raise syntax 93.900 array(message)
               end
               return rexxString~string -- Unicode-TODO: (rgf) unescape string; if BSF4ooRexx available one could also use java.util.Properties
            end
            else rexxString~append(char)
        end
        if jsonPos > jsonStringLength then raise user parseError array('Expected end of a quoted string, ending quote not found')
    end
    return
parseError: raise propagate


/**
 * Converts other JSON types (JSON number, JSON <code>true</code>, JSON <code>false</code>,
   JSON <code>null</code>) to corresponding Rexx objects.
 *
 */
::method parseJSONother private
    expose jsonString endsValue jsonPos jsonStringLength
    signal on user parseError

    length = jsonStringLength + 1
    do i = jsonPos to jsonStringLength
        char=jsonString[i]
        if endsValue~pos(char)>0 then leave
    end

    parse value jsonString with =(jsonPos) string +(i - jsonPos)

    if string~datatype('n') then do
        jsonPos = jsonPos + string~length
        return string
    end
    else do
        select
            when string == 'false' then do
                jsonPos = jsonPos + 5 -- string~length
                return .JsonBoolean~false
            end
            when string == 'true' then do
                jsonPos = jsonPos + 4 -- string~length
                return .JsonBoolean~true
            end
            when string == 'null' then do
                jsonPos = jsonPos + 4 -- string~length
                return .nil
            end
            otherwise nop
        end
    end
    raise user parseError array('Invalid JSON value, jsonPos=['jsonPos'], jsonStringLength=['jsonStringLength']' 'extracted value=['string']')

parseError: raise propagate


/**
 * Removes allowed leading whitespace.
 */
::method trimLeadingWhitespace private
    expose jsonString whitespace jsonPos jsonStringLength

    -- "0" if only whitespace chars, else pos of next non-whitespace, use current jsonPos to start out
    nonWs=jsonString~verify("20 0d 0a 09"x, 'Nomatch', jsonPos)
    if nonWs<>0 then jsonPos=nonWs


/**
 * Removes allowed trailing whitespace.
 */
::method trimTrailingWhitespace private
    expose jsonString whitespace jsonPos jsonStringLength

    do i=jsonStringLength to 1 by -1
       if whiteSpace~pos(jsonString[i])=0 then leave
    end
    jsonStringLength=i



/** Removes all "090a0d20"x (TAB, LF, CR, blank) whitespace characters to achieve the
*   smallest possible ("minified") JSON string.
*
* @param jsonString  a JSON encoded string
* @return jsonString the minified version of the JSON encoded String
*
*/
::method minify
  forward to (self~class)  -- forward to class method to do the work


/** * Removes all "090a0d20"x (TAB, LF, CR, blank) whitespace characters to achieve the
 *   smallest possible ("minified") JSON string.
 *
 * @author Adrian Baginski
 * @since 100.20170908
 * @param jsonString - A JSON Encoded String
 * @return jsonString - The minified version of the JSON String
 */
::method minify class
  use arg jsonString

  jsonString=.mutableBuffer~new(jsonString)
  jsonString~translate( ,"0d0a09"x)  -- replace CR, LF, TAB with blank

  currentPos = 1
  skipDeletingStr = .false

  currentLength=jsonString~length

  do while currentPos <= currentLength
    /* blank chars are only allowed when quoted in "" */
    if jsonString~subChar(currentPos)='"' then
    do
      /* invert the skipDeletingStr boolean if the previous char was not an escaping character */
      if currentPos>1, jsonString~subChar(currentPos-1)<>"\" then
        skipDeletingStr = \skipDeletingStr
    end

    else -- check for blanks, delete them if skipDeletingStr is .false
    do
       posOfNonBlank=jsonString~verify(" ", "N", currentPos)   -- find next position that is not a blank
       if posOfNonBlank>currentPos then   -- currentPos is a blank, so process
       do
          if skipDeletingStr then         -- do not delete blanks
          do
               -- find next blank or quote
              nextBlankOrQuote=jsonString~verify(' "', "Match", posOfNonBlank)
              if nextBlankOrQuote=0 then  -- not found, none left
                 currentPos=currentLength -- we are done, no more blanks or quotes in string
              else   -- position on next blank or quote
                 currentPos=nextBlankOrQuote-1  -- adjust for "currentPos += 1" at the end
          end
          else  -- delete blanks
          do
              nrOfBlanksToDelete=posOfNonBlank-currentPos
              jsonString = jsonString~delStr(currentPos, nrOfBlanksToDelete)
              currentLength -= nrOfBlanksToDelete -- adjust currentLength
              currentPos -= 1 -- adjust currentPos
          end
       end
     end
     currentPos += 1
  end
  return jsonString~string~strip -- return the string representation


/**
 * Forwards the provided Rexx Object to be converted to a JSON String.
 * Calls the method `minify` to remove all unnecessary line breaks and white spaces
 * Note: by default a JSON object will create minified JSON strings.
 *
 * @param rxObj - the object to be converted
 * @return minified - a minified JSON encoded string representing the parameter
 */
::method toMinifiedJson
  use arg rxObj
  jsonString = self~toJson(rxObj)
  minified   = self~class~minify(jsonString)
  return minified


/* ========================================================================= */

/** ooRexx class to represent a JSON boolean (logical) value. It inherits from the ooRexx mixinclass
*   <code>Comparable</code> and therefore implements its abstract method <code>compareTo</code>.
*
*/
::class "JsonBoolean" inherit comparable

/** Class getter attribute method that returns the version information of this class.
*
* @return version as a string, formatted as: major*100+minor || "." || yyyymmdd
*/

::attribute version get class
  use strict arg           -- no argument allowed!
  return "100.20210608"    -- version in the form: major*100+minor || "." || yyyymmdd

/** Class getter attribute method that refers to the proxy object that represents the value <code>.true</code>.
*/
::attribute true  get class   -- true proxy, class getter method
  expose true
  if \var("TRUE") then true=self~new(.true)
  return true

/** Class getter attribute method that refers to the proxy object that represents the value <code>.false</code>.
*/
::attribute false get class   -- false proxy, class getter method

/** Finalizes the class initialization by creating the two proxy class attribute values <code>true</code>
*   and <code>false</code>.
*/
::method    activate  class   -- initialization of class object complete, we now can use everything
  expose true false
  true =self~new(.true)       -- create and store true proxy value
  false=self~new(.false)      -- create and store false proxy value

/** Controls the creation of instances of this class, makes sure that the proxy values get created
*   and cached, otherwise returns the requested object.
*
* @param val a string representing a Boolean/logical value, i.e. one of &quot;0&quot;,
*            &quot;1&quot;, &quot;true&quot;, &quot;false&quot;,
*            &quot;.true&quot; or &quot;.false&quot; in any case.
*/
::method new class   -- make sure we hand out only the proxy objects for "true" and "false", do not create more instances
  expose true false        -- expose class attributes
  use strict arg val

  if "0 1 true false .true .false"~caselessWordPos(val)=0 then -- check for acceptable values
     raise syntax 88.900 array ("Argument must be one of '0', 'false', '.false', '1', 'true' or '.true', found:" val)

  value=("0 false .false"~caselessWordPos(val)=0)  -- .true, if no false values supplied
  if value=.true then
  do
     if \var('TRUE') then  -- attribute not set yet?
     do
        forward class (super) array (.true) continue -- let superclass' new method create and carry out initialisation
        true=result        -- assign created object to class attribute
        true~objectname=true~objectname"[1/.true]" -- add hint
     end
     return true           -- return the true proxy object
  end

  if \var('FALSE') then    -- attribute not set yet?
  do
     forward class (super) array (.false) continue -- let superclass' new metho d create and carry out initialisation
     false=result          -- assign created object to class attribute
     false~objectname=false~objectname"[0/.false]" -- add hint
  end
  return false             -- return the false proxy object

/** Getter attribute method that returns the Rexx string representing the logical value.
*/
::attribute value get   -- getter method

/** Constructor.
* @param value mandatory Rexx string representing the logical value
*/
::method init private   -- make constructor method inaccessible to other classes, own metaclass is allowed to access directly
  expose value
  use strict arg value  -- assign boolean value

/** Equal comparison method.
* @param other the other object representing a Boolean/logical value
* @return <code>.true</code>, if this object and <code>other</code> can be reqarded to be equal, <code>.false</code> else
*/
::method "="            -- equal method
  use strict arg other  -- other must be a Boolean value
  return self~compareTo(other)=0

/** Unequal comparison method.
* @param other the other object representing a Boolean/logical value
* @return <code>.true</code>, if this object and <code>other</code> cannot be reqarded to be equal, <code>.false</code> else
*/
::method "\="           -- unequal method
  use strict arg other  -- other must be a Boolean value
  return self~compareTo(other)\=0

/** Unequal comparison method, forwarding to method <code>&quot;\=&quot;</code>.
*/
::method "<>"           -- synonym for "\="
  forward message ("\=")

/** Unequal comparison method, forwarding to method <code>&quot;\=&quot;</code>.
*/
::method "><"           -- synonym for "\="
  forward message ("\=")

/** Implements the abstract method inherited from the mixinclass <code>Comparable</code>.
*/
::method compareTo   -- implementation for .orderable class: must return -1 if other greater, 0 if same, 1 otherwise
  expose value
  use strict arg other  -- other must be a Boolean value

  if other~isA(.JsonBoolean) then  -- get Rexx string representing logical value
     otherValue=other~value
  else
     otherValue=other~request("string") -- request the string value

  if otherValue=.nil then
     raise syntax 88.900 array ("Argument ""other"" ["other"] has no 'MAKESTRING' method")

  if value < otherValue then return -1    -- self smaller than other
  if value = otherValue then return  0    -- self equal to other
  return                             1    -- self greater than other

/** Renders the object as a Rexx string representing its logical value.
* @return a Rexx string representing its logical value, either &quot;<code>0</code>&quot; or
*         &quot;<code>1</code>&quot;
*/
::method makeString  -- allow instances of this class to be a plug in replacement for Rexx logical values
  expose value
  return value

/** Renders the object as a JSON string representing its logical value.
* @return a string representing its logical value JSON encoded, either &quot;<code>false</code>&quot;
*         or &quot;<code>true</code>&quot;
*/
::method makeJSON    -- creates the string "true" or "false", depending on the attribute "value"
  expose value
  if value=.true then return "true"
  return "false"

