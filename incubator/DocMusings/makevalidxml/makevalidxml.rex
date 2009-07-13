/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Description: Test the XML parser class.                                    */
/*                                                                            */
/* Copyright (c) 2006 Rexx Language Association. All rights reserved.         */
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
/*                                                                            */
/*----------------------------------------------------------------------------*/

/**** 
Usage :
    makevalidxml [-debug] [-dump] [-fix] [-help] [-xinclude] <filename>
Description :
    This script is intended to work on the XML files of the ooRexx doc.
    It reads the file <filename>, parses it and sends it to stdout. 
    By default, the layout of the output file is kept the most similar possible
    to the layout of the input.
    Options :
    -debug    : Insert additional informations in the ouptut.
    -dump     : The elements and attributes are dumped without attempting to
                keep the original layout.
    -fix      : The output is modified where needed, to make it valid XML.
    -xinclude : Use <xi:include> instead of XML entities to include files.
****/


parse source . callType .
arguments = .Arguments~new(callType, arg(1,"array"))

if arguments~error <> "" then do
    call Help arguments~error
    return 1
end

if arguments~helpOption then do
    call Help
    return 0
end

parser = .myparser~new()
parser~debug = arguments~debugOption
parser~dump = arguments~dumpOption
errortxt = parser~parse_file(arguments~filename)
if errortxt <> "" then do
    say errortxt
    return 1
end

return 0


::requires 'myxmlparser.cls'

::class myparser subclass xmlparser
::attribute dump

::method start_element
    use arg chunk
    if self~dump then do
        if self~debug then say '[start_element:'chunk~line':'chunk~col'['
        call charout , '<'chunk~tag
        if chunk~attr <> .nil then 
            do f over chunk~attr
                call charout , ' 'f'="'self~textxlate(chunk~attr[f])'"'
            end
        call charout , '>' -- say '>'
        if self~debug then say ']start_element]'
    end
    else do
        if self~debug then call charout , '[start_element:'chunk~line':'chunk~col'['
        call charout , '<'chunk~text'>'
        if self~debug then call charout , ']start_element]'
    end
    return

::method end_element
    use arg chunk
    if self~dump then do
        if self~debug then say '[end_element'chunk~line':'chunk~col'['
        call charout , '</'chunk~tag'>' -- say '</'chunk~tag'>'
        if self~debug then say ']end_element]'
    end
    else do
        if self~debug then call charout , '[end_element:'chunk~line':'chunk~col'['
        if chunk~text = '' then call charout , '</'chunk~tag'>'
        if self~debug then call charout , ']end_element]'
    end
    return

::method passthrough
    use arg chunk
    if self~dump then do
        if self~debug then say '[passthrough:'chunk~line':'chunk~col'['
        call charout , '<'chunk~text'>' -- say '<'chunk~text'>'
        if self~debug then say ']passthrough]'
    end
    else do
        if self~debug then call charout , '[passthrough:'chunk~line':'chunk~col'['
        call charout , '<'chunk~text'>'
        if self~debug then call charout , ']passthrough]'
    end
    return

::method text
    use arg chunk
    if self~dump then do
        if self~debug then call charout , '[text:'chunk~line':'chunk~col'['
        call charout , chunk~text
        if self~debug then say ']text]'
    end
    else do
        if self~debug then call charout , '[text:'chunk~line':'chunk~col'['
        call charout , chunk~text
        if self~debug then call charout , ']text]'
    end
    return

::method error
    use arg err
    say err~text
    return

::method xlatetext private
    use arg text
    /*
    text = text~changestr('&', '&amp;') -- always do this one first!
    text = text~changestr('>', '&gt;')
    text = text~changestr('<', '&lt;')
    */
    return text

-------------------------------------------------------------------------------
::class Arguments
::attribute debugOption
::attribute dumpOption
::attribute error
::attribute filename
::attribute fixOption
::attribute helpOption
::attribute xincludeOption

::method init
    self~debugOption = .false
    self~dumpOption = .false
    self~error = ""
    self~filename = ""
    self~fixOption = .false
    self~helpOption = .false
    self~xincludeOption = .false
    
    -- Tokenize the arguments, if needed
    use strict arg callType, arguments -- always an array
    select
        when callType == "COMMAND" & arguments~items == 1 then args = String2Args(arguments[1])
        when callType == "SUBROUTINE" & arguments~items == 1 & arguments[1]~isA(.array) then args = arguments[1]
        otherwise args = arguments
    end
    
    -- Use makeArray to have a non-sparse array,
    -- because omitted parameters have no corresponding index,
    -- and we ignore omitted parameters here.
    args = args~makeArray
    
    -- Process the options
    loop i=1 to args~items
        option = args[i]
        if option~left(1) <> "-" then leave
        select
            when "-debug"~caseLessEquals(option) then self~debugOption = .true
            when "-dump"~caseLessEquals(option) then self~dumpOption = .true
            when "-fix"~caseLessEquals(option) then self~fixOption = .true
            when "-help"~caseLessEquals(option) then self~helpOption = .true
            when "-xinclude"~caseLessEquals(option) then self~xincludeOption = .true
            otherwise do
                self~error = "Unknown option" option
                return
            end
        end
        -- Return now if help requested
        if self~helpOption then return
    end
    
    -- Process the arguments
    if i > args~items then do
        self~error = "<filename> is missing"
        return
    end
    self~filename = args[i]~strip
    i += 1
    if i > args~items then return
    self~error = "Unexpected arguments :" args~section(i)~toString("L", " ")
    return

    
-------------------------------------------------------------------------------
::routine String2Args public
    -- Converts a string to an array of arguments.
    -- Arguments are separated by whitespaces (anything < 32) and can be quoted.
    -- This routine tries to follow the behavior of cmd.exe, which lets write such things :
    --                                                  %1                      %2              %3
    --     myscript c:\dir1\my dir\dir 2                c:\dir1\my              dir\dir         2
    --     myscript "c:\dir1\my dir\dir 2"              "c:\dir1\my dir\dir 2"
    --     myscript c:\dir1\"my dir"\dir 2              c:\dir1\"my dir"\dir    2
    --     myscript c:\dir1\my dir\dir" 2"              c:\dir1\my              dir\dir" 2"
    --     myscript he says "I told you "hello"!"       he                      says            "I told you "hello"!"
    --     myscript he says "I told you ""hello""!"     he                      says            "I told you ""hello""!"
    --
    -- Unlike cmd, this routine does an additional processing : 
    -- Quotes are removed from the value, except when they are doubled inside a quoted string.
    --     cmd parameter                value in args
    --     c:\dir1\my                   'c:\dir1\my'
    --     "c:\dir1\my dir\dir 2"       'c:\dir1\my dir\dir 2'
    --     c:\dir1\"my dir"\dir         'c:\dir1\my dir\dir'
    --     "I told you "hello"!"        'I told you hello!'
    --     "I told you ""hello""!"      'I told you "hello"!'
    use strict arg string

    args = .Array~new
    i = 1

    loop label arguments
        -- Skip whitespaces
        loop
            if i > string~length then return args
            if string~subchar(i) > " " then leave
            i += 1
        end
    
        -- Process current argument : can be made of several chunks, all chunks are concatenated
        -- Example                  chunk1          chunk2          chunk3      value
        -- one                      one                                        'one'
        -- "one two"                "one two"                                   'one two'
        -- one" two "three          one             " two "         three       'one two three'
        -- one" ""two"" "three      one             " ""two"" "     three       'one "two" three'
        current = .MutableBuffer~new
        loop label current_argument
            if string~subchar(i) == '"' then do
                -- Chunk surrounded by quotes : whitespaces are kept, double occurrence of quotes are replaced by a single embedded quote  
                loop label quoted_chunk
                    i += 1
                    if i > string~length then return args~~append(current~string)
                    select
                        when string~subchar(i) == '"' & string~subchar(i+1) == '"' then do
                            current~append('"')
                            i += 1
                        end
                        when string~subchar(i) == '"' then do
                            i += 1
                            leave quoted_chunk
                        end
                        otherwise current~append(string~subchar(i)) 
                    end
                end quoted_chunk
            end
            if string~subchar(i) <= " " then do
                args~append(current~string)
                leave current_argument
            end
            -- Chunk not surrounded by quotes : ends when a whitespace or quote is reached 
            loop
                if i > string~length then return args~~append(current~string)
                if string~subchar(i) <= " " | string~subchar(i) == '"' then leave
                current~append(string~subchar(i))
                i += 1
            end
        end current_argument
    end arguments
    return args
    
-------------------------------------------------------------------------------
::routine Help
    use strict arg errorMessage=""
    if errorMessage <> "" then say errorMessage
    -- The help text is taken from the comment at the begining of the source file.
    display = .false
    do line = 1 to sourceline()
        sourceline = sourceline(line)
        if sourceline~pos("****/") <> 0 then leave
        if display then say sourceline
        if sourceline~pos("/****") <> 0 then display = .true
    end
    return    

