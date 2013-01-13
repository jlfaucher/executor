/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Description: Very simple class to parse XML.                               */
/*                                                                            */
/* Copyright (c) 2006-2009 Rexx Language Association. All rights reserved.    */
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
/* Author: W. David Ashley                                                    */
/* Contributors: Ruurd Idenburg                                               */
/*                                                                            */
/*----------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Notes:                                                                     */
/*                                                                            */
/* The xmlparser class is a very simple parser for XML files. It is not an    */
/* official 100% compatible XML parser because it has a lot of limitations,   */
/* most of which you could probably care less about.                          */
/*                                                                            */
/* 1. The parser only understands ASCII, which is a valid subset of UTF-8.    */
/*    It does not understand any other encoding except 8-bit ASCII.           */
/* 2. It does not test that the document is well-formed. It assumes that the  */
/*    document is a well-formed XML document.                                 */
/* 3. The parser does not know how to handle XML processing instructions. It  */
/*    passes those instructions through the passthrough method intact so      */
/*    that the user can try to make sense of them.                            */
/*                                                                            */
/* To use the xmlparser you need to be aware of the following.                */
/*                                                                            */
/* 1. The parser requires ooRexx version 3.2.0 or later.                      */
/* 2. The parser uses a SAX-like interface, but methods of the class are used */
/*    instead of a call-back mechanism. The default methods perform no        */
/*    actions. The user will need to subclass the xmlparser class and         */
/*    override the call-back methods in order to insert their own actions     */
/*    for each XML chunk type.                                                */
/* 3. The call-back methods use the xmlchunk class to pass data to the        */
/*    methods. This is a very simple class and is used as a container for     */
/*    specific types of XML chunks.                                           */
/* 4. Text chunks (CDATA) are passed through the text method intact. If the   */
/*    parser encounters multiple lines of text it invokes the text method     */
/*    for each line individually. It also does not collapse white space chars.*/
/* 5. XML tags are collapsed. This means that if a tag crosses a line         */
/*    boundary then the lines are collapsed together. This is important       */
/*    for processing instruction tags, comment tags and other special tags.   */
/*                                                                            */
/*----------------------------------------------------------------------------*/




/*
JLF : adaptation of xmlparser.cls to my own needs.
- reprint the parsed XML the most possible like the original one.
- add missing closing tags
I need to modify the parser, to keep the text unchanged, hence this copy...

The following files contain unsupported text under programlisting :
    oodialog/dialogcontrolCommon.sgml
    oodialog/windowBaseCommon.sgml
    oodialog/windowExtensionsCommon.sgml
Must modify the parser to support that :
    <programlisting format='linespecific'>
    >>--<link linkend="disable">disable</link>----------------------------><
    </programlisting>
The parser raises an "invalid tag name" because of the < followed by EOL
*/



/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Class: XMLPARSER                                                           */
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/

::class xmlparser subclass object public


/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Class: XMLPARSER                                                           */
/*        Private methods                                                     */
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/

::constant parserver '0.5'             -- the version of this parser
::method src         attribute private -- the array of xml lines to be parsed
::method lineidx     attribute private -- the index into the array of xml lines
::method charidx     attribute private -- the index into a xml line
::method errortxt    attribute private -- error text
::method eof         attribute private -- done parsing?
::attribute endofline                  -- derived from the first line of the xml file, assume all lines have this EOL
::attribute lastlineendofline          -- except the last line which may have no EOL 
::attribute debug

::method init
self~debug = .false


/*----------------------------------------------------------------------------*/
/* Method: create_error                                                       */
/* Description: creates an xmlerror instance.                                 */
/*----------------------------------------------------------------------------*/

::method create_error private
use strict arg msg, errline, errpos
xmlerror = .xmlerror~new
xmlerror~text = msg
xmlerror~filename = self~xmlfile
xmlerror~line = errline
xmlerror~charpos = errpos
return xmlerror


/*----------------------------------------------------------------------------*/
/* Method: xlatetext                                                          */
/* Description: translate & attributes to their normal characters.            */
/*----------------------------------------------------------------------------*/

::method xlatetext private
use strict arg text
text = text~changestr('&gt;', '>')
text = text~changestr('&lt;', '<')
text = text~changestr('&amp;', '&') -- always do this one last!
return text


/*----------------------------------------------------------------------------*/
/* Method: detect_eol_style                                                   */
/* Description: detect the EOL style of the first line and last line          */
/*----------------------------------------------------------------------------*/
::method detect_eol_style
use strict arg stream
self~endofline = ""
previouschar = ""
stream~seek("=1")
do forever
    currentchar = stream~charin
    if currentchar == "" then leave -- EOF
    if c2x(currentchar) == "0A" then do
        if c2x(previouschar) == "0D" then self~endofline = x2c("0D0A")
        else self~endofline = x2c("0A")
        leave
    end
    previouschar = currentchar
end

-- It's not possible to make a distinction between a last (non empty) line without EOL
-- and a last (non empty) line with EOL, when working with the array returned by stream~arrayIn.
-- Hence this attribute...
self~lastlineendofline = ""
stream~seek("<1")
lastchar = stream~charin
if c2x(lastchar) == "0A" then self~lastlineendofline = self~endofline
return


/*----------------------------------------------------------------------------*/
/* Method: current char                                                       */
/* Description: return the current character, or one of the relative          */
/* characters of the current line                                             */
/*----------------------------------------------------------------------------*/

::method currentchar private
expose src lineidx charidx
use strict arg offset=0 -- can be negative
if lineidx > src~items then return ''
charpos = charidx + offset
if charpos < 1 then return ''
if charpos > src[lineidx]~length then return ''
return src[lineidx]~substr(charpos, 1)


/*----------------------------------------------------------------------------*/
/* Method: getchar                                                            */
/* Description: get a single character from the xml document.                 */
/*----------------------------------------------------------------------------*/

::method getchar private
expose src lineidx charidx eof
use strict arg
if lineidx > src~items then do
   eof = .true
   return ''
   end
if charidx > src[lineidx]~length then do
   lineidx = lineidx + 1
   charidx = 1
   if lineidx > src~items then do
      if self~lastlineendofline <> "" then return self~lastlineendofline
      eof = .true
      return ''
      end
   return self~endofline
   end
character = src[lineidx]~substr(charidx, 1)
charidx = charidx + 1
return character


/*----------------------------------------------------------------------------*/
/* Method: getchunk                                                           */
/* Description: returns a chunk of the xml document.                          */
/*----------------------------------------------------------------------------*/

::method getchunk private
expose src lineidx charidx errortxt eof
use strict arg
errlineidx = lineidx
errcharidx = charidx
chunk = .xmlchunk~new
chunk~line = lineidx
chunk~col = charidx
if self~currentchar() <> '<' then do
   /* we found some TEXT */
   curline = lineidx
   buffer1 = .MutableBuffer~new
   do while eof = .false 
      /*
      To support that :
          <programlisting format='linespecific'>
          >>--<link linkend="disable">disable</link>----------------------------><
          </programlisting>
      must do that :
          '<' followed by EOL or EOF is part of the text
      */
      if self~currentchar() == '<' & self~currentchar(1) <> '' then leave 
      -- Do NOT collapse the white space and newlines out of the chunk!
      -- We leave that task up to the client of this class.
      -- Instead, we return a chunk with self~endofline stuck in between
      -- at the linebreaks.
      buffer1~append(self~getchar())
      if curline <> lineidx then do
         curline = lineidx
         end
      end
   chunk~text = self~xlatetext(buffer1)~string
   -- if chunk~text~strip <> '' then ,              -- never strip a TEXT
    self~text(chunk) -- call the public override method
   return chunk
   end
/* we found an XML tag, process it */
character = self~getchar() -- skip the '<'
curline = lineidx
nestlevel = 0
buffer2 = .MutableBuffer~new
do i=0 to 7
   buffer2~append(self~currentchar(i))
end
iscdata = (buffer2~string == "![CDATA[")
iscomment = (buffer2~string~left(3) == "!--")
buffer3 = .MutableBuffer~new
do while eof = .false
   if \iscdata & \iscomment & buffer3~substr(1, 1) = '!' then do
      -- It is possible for tags to be contained within other tags in XML
      -- processing tags. The next two IF statements take care of that nesting
      -- possibility. It will be up to the user to parse out the contained
      -- tags.
      if self~currentchar() = '<' then nestlevel = nestlevel + 1
      if self~currentchar() = '>' & level > 0 then nestlevel = nestlevel - 1
      end
   buffer3~append(self~getchar())
   if curline <> lineidx then do
      curline = lineidx
      end
   if self~currentchar() = '>' then do
      if iscdata then do
         if self~currentchar(-2) || self~currentchar(-1) == "]]" then leave
         end
      else if iscomment then do
         if self~currentchar(-2) || self~currentchar(-1) == "--" then leave
         end
      else if nestlevel = 0 then leave
      end
   if eof = .true then do
      errortxt = 'Error line' errlineidx': EOF within an XML tag.'
      self~error(self~create_error(errortxt, errlineidx, errcharidx)) -- call the public override method
      return .nil
      end
   end
raw_element = buffer3~string
if \iscdata then buffer3~changeStr(self~endofline, " "~copies(self~endofline~length)) -- replace endofline by space(s)
element = buffer3~string~strip()
if self~debug then .stderr~lineout("[debug] "errlineidx":"currentSourceLine()":element=["element"]")
select
   when element~substr(1, 1) = '/' then do
      chunk~tag = element~substr(2)
      chunk~text = '' -- empty ==> </tag> will be displayed
      self~end_element(chunk) -- call the public override method
      end
   when pos('?', element~substr(1, 1)) > 0 then do
      chunk~tag = ''
      chunk~text = raw_element
      self~passthrough(chunk) -- call the public override method
      end
   when pos('!--', element~substr(1, 3)) > 0 then do
      chunk~tag = ''
      chunk~text = raw_element
      self~passthrough(chunk) -- call the public override method
      end
   when pos('!', element~substr(1, 1)) > 0 then do
      chunk~tag = ''
      chunk~text = raw_element
      self~passthrough(chunk) -- call the public override method
      end
   when pos(element~substr(1, 1), xrange('a', 'z') || xrange('A', 'Z')) > 0 then do
      parse var element tag element
      element = element~strip()
      if self~debug then 
          do
              .stderr~lineout("[debug] "errlineidx":"currentSourceLine()":tag    =["tag"]")
              .stderr~lineout("[debug] "errlineidx":"currentSourceLine()":element=["element"]")
          end
      -- the following is needed in case the '/' immediately follows the tag
      if tag~pos('/') > 0 then do
         tag = tag~substr(1, tag~length - 1)
         element = '/' element
         end
      chunk~tag = tag
      chunk~text = raw_element
      /* process the attributes */
      if element~length > 0 then chunk~attr = .directory~new
      do while element~length() > 0
         -- To increase the chances of parsing success, remove all the spaces before the first quote, if any
         -- before: a  =  " value of a "  b  =  ' value of b '
         -- after : a=" value of a "  b  =  ' value of b '
         firstQuote = element~pos('"')
         firstApos = element~pos("'")
         if firstQuote <> 0 & firstApos <> 0 then pos = min(firstQuote, firstApos)
         else if firstQuote <> 0 then pos = firstQuote
         else if firstApos <> 0 then pos = firstApos
         else pos = 0
         if pos <> 0 then element = element~left(pos - 1)~space(0) || element~substr(pos)
         if self~debug then .stderr~lineout("[debug] "errlineidx":"currentSourceLine()":element=["element"]")
         if pos('="', element~word(1)) > 0 then do
            parse var element attrname '="' attrvalue '"' element
            attrname = attrname~strip()
            --attrvalue = attrvalue~strip() -- the value between quotes must remain as-is
            attrvalue = self~xlatetext(attrvalue)
            chunk~attr[attrname] = attrvalue
            end
         else if pos("='", element~word(1)) > 0 then do
            parse var element attrname "='" attrvalue "'" element
            attrname = attrname~strip()
            --attrvalue = attrvalue~strip() -- the value between quotes must remain as-is
            attrvalue = self~xlatetext(attrvalue)
            chunk~attr[attrname] = attrvalue
            end
         else do
            parse var element attrname element
            if attrname <> '/' then do
               -- do not allow attributes without values!
               errortxt = 'Error line' errlineidx 'column' errcharidx || ,
                          ': Invalid tag attribute' attrname'.'
               self~error(self~create_error(errortxt, errlineidx, errcharidx)) -- call the public override method
               /* stop parsing */
               eof = .true
               return .nil
               end
            end
         end
      self~start_element(chunk) -- call the public override method
      if attrname = '/' then do
         endchunk = .xmlchunk~new
         endchunk~line = lineidx
         endchunk~col = charidx
         endchunk~text = raw_element -- won't be printed as-is (because already printed by start_element), but will be used to decide to print nothing instead of </tag>
         endchunk~tag = tag
         self~end_element(endchunk) -- call the public override method
         end
      end
   otherwise do
      errortxt = 'Error line' errlineidx 'column 'errcharidx': Invalid tag name.'
      self~error(self~create_error(errortxt, errlineidx, errcharidx)) -- call the public override method
      /* stop parsing */
      eof = .true
      return .nil
      end
   end
character = self~getchar() -- skip the '>'
return chunk

currentSourceLine:
return SIGL

/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Class: XMLPARSER                                                           */
/*        Public methods                                                      */
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/

::method xmlfile attribute private -- the XML file name, if known


/*----------------------------------------------------------------------------*/
/* Method: start_element                                                      */
/* Description: called when a start element tag has been encountered.         */
/* Arguments:   an xmlchunk instance.                                         */
/*----------------------------------------------------------------------------*/

::method start_element
/* this method is designed to be overridden by a subclass */
use strict arg chunk
return


/*----------------------------------------------------------------------------*/
/* Method: end_element                                                        */
/* Description: called when an end element tag has been encountered.          */
/* Arguments:   an xmlchunk instance.                                         */
/*----------------------------------------------------------------------------*/

::method end_element
/* this method is designed to be overridden by a subclass */
use strict arg chunk
return


/*----------------------------------------------------------------------------*/
/* Method: text                                                               */
/* Description: called when character data has been encountered.              */
/* Arguments:   an xmlchunk instance.                                         */
/*----------------------------------------------------------------------------*/

::method text
/* this method is designed to be overridden by a subclass */
use strict arg chunk
return


/*----------------------------------------------------------------------------*/
/* Method: passthrough                                                        */
/* Description: called when comment tag or a processing instruction has been  */
/*              encountered.                                                  */
/* Arguments:   an xmlchunk instance.                                         */
/*----------------------------------------------------------------------------*/

::method passthrough
/* this method is designed to be overridden by a subclass */
use strict arg chunk
return


/*----------------------------------------------------------------------------*/
/* Method: error                                                              */
/* Description: called on an error.                                           */
/* Arguments:   an xmlerror instance.                                         */
/*----------------------------------------------------------------------------*/

::method error
/* this method is designed to be overridden by a subclass */
use strict arg xmlerror
return


/*----------------------------------------------------------------------------*/
/* Method: getversion                                                         */
/* Description: return the version of this class.                             */
/*----------------------------------------------------------------------------*/

::method getversion
return self~parserver


/*----------------------------------------------------------------------------*/
/* Method: parse_array                                                        */
/* Description: parse the specified array of XML code.                        */
/*----------------------------------------------------------------------------*/

::method parse_array
expose src lineidx charidx errortxt eof
use strict arg src
eof = .false
/* make sure this is an xml document */
/* Not applicable to the SGML files of oorexx
if src[1]~pos('<?xml') <> 1 then do
   errortxt = 'Error: Invalid XML document.'
   self~error(self~create_error(errortxt, 1, 1))
   return ""
   end
*/
/* parse the xml array */
lineidx = 1
charidx = 1
errortxt = ''
do while eof = .false
   chunk = self~getchunk()
   end
return errortxt


/*----------------------------------------------------------------------------*/
/* Method: parse_file                                                         */
/* Description: parse the specified file of XML code.                         */
/*----------------------------------------------------------------------------*/

::method parse_file
expose errortxt xmlfile
use strict arg xmlfile
tfile = .stream~new(xmlfile)
errortxt = tfile~open('read')
if errortxt <> 'READY:' then do
   errortxt = tfile~description
   tfile~close()
   return errortxt
   end
lines = tfile~arrayin()
self~detect_eol_style(tfile) -- don't assume that the file has the eol style of the current platform
tfile~close()

errortxt = self~parse_array(lines)
return errortxt


/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Class: XMLCHUNK                                                            */
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/

::class xmlchunk subclass object public


/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Class: XMLCHUNK                                                            */
/*        Private methods                                                     */
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Class: XMLCHUNK                                                            */
/*        Public methods                                                      */
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/

::method text        attribute         -- the text
::method tag         attribute         -- the xml tag name
::method attr        attribute         -- the tag attributes
::attribute line                       -- the start line of the chunk
::attribute col                        -- the start col of the chunk             

/*----------------------------------------------------------------------------*/
/* Method: init                                                               */
/* Description: instance initialization                                       */
/*----------------------------------------------------------------------------*/

::method init
use strict arg
self~text = .nil  -- For the start_element and passthrough methods this contains
                  -- the entire text string enclosed within the '<' and '>'
                  -- brackets. For the text method it contains a single line
                  -- of CDATA text.
self~tag = .nil   -- For  the start_element and end_element methods this is
                  -- the XML element (tag) name. For the end_element method the
                  -- leading '/' character is not a part of this string.
self~attr = .nil  -- For the start_element method this is an ooRexx directory
                  -- class instance. Each attribute and value is contained in
                  -- the ooRexx directory instance.
self~line = 0
self~col = 0
return


/*----------------------------------------------------------------------------*/
/* Method: cdata_text                                                         */
/* Description: text of the cdata section, without the start/end tags         */
/*----------------------------------------------------------------------------*/
::method cdata_text
    if self~text~left(8) <> "![CDATA[" then return .nil 
    if self~text~right(2) <> "]]" then return .nil
    return self~text~substr(9, self~text~length - 10)
    
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Class: XMLERROR                                                            */
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/

::class xmlerror subclass object public


/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Class: XMLERROR                                                            */
/*        Private methods                                                     */
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Class: XMLERROR                                                            */
/*        Public methods                                                      */
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/

::method text        attribute         -- the error message text, if any
::method filename    attribute         -- the xml file name, if known
::method line        attribute         -- the error line number
::method charpos     attribute         -- the error character position


/*----------------------------------------------------------------------------*/
/* Method: init                                                               */
/* Description: instance initialization                                       */
/*----------------------------------------------------------------------------*/

::method init
use strict arg
self~text = ''
self~filename = ''
self~line = 0
self~charpos = 0
return

