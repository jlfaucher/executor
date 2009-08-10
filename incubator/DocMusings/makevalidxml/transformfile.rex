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
    $sourcename 
        [-debug] [-dsssl] [-dump] [-help] [-xinclude] [-xslt] 
        <inputFile> [<outputFile> [<logFile>]]
Description :
    This script is intended to work on the XML files of the ooRexx doc.
    It reads the file <inputFile>, parses it and writes the transformed XML in
    the file <outputFile>. 
    By default, there is no transformation and the layout of the output file
    is kept the most similar possible to the layout of the input.
    Options :
    -debug    : Insert additional informations in the ouptut. A part is sent to
                stderr, another part is inserted in the XML output (making it
                non valid).
    -dsssl    : Generate DocBook XML compatible with DSSSL.
    -dump     : The elements and attributes are dumped without attempting to
                keep the original layout.
    -xinclude : Use <xi:include> instead of XML entities to include files.
                Will be ignored if the target format is not XSLT.
    -xslt     : Generate DocBook XML compatible with XSLT.
****/


log = .stderr
parse source . callType me
arguments = .Arguments~new(callType, arg(1,"array"))
if arguments~help then call Help me
do error over arguments~errors
    log~lineout(error)
end
if arguments~help | \arguments~errors~isEmpty then return 1

if arguments~logFile <> "" then log = .stream~new(arguments~logFile)

parser = .myparser~new()
parser~debug = arguments~debug
parser~dump = arguments~dump
parser~log = log

if arguments~dsssl then parser~target = "dsssl"
if arguments~xslt then parser~target = "xslt"

if arguments~outputFile <> "" then do
    parser~output = .stream~new(arguments~outputFile)
    if parser~output~command("open write replace") <> "READY:" then do
        log~lineout("[error] Error opening "arguments~outputFile)
        log~lineout("[error] "parser~output~description)
        return 1
    end
end

signal on syntax -- The parser can abort by raising a syntax 4 (??? why only a "syntax" can be propagated automatically ???)
errortxt = parser~parse_file(arguments~inputFile)
if errortxt <> "" then do
    log~lineout("[error] The XML parser returned "errortxt)
    return 1
end

parser~check_stack_empty

return 0

syntax: -- In fact, it's an abort, not a syntax error...
    return 1

::requires 'arguments.rex'
::requires 'help.rex'
::requires 'myxmlparser.cls'

-------------------------------------------------------------------------------
::class myparser subclass xmlparser
::attribute dump
::attribute elementsStack
::attribute log
::attribute output
::attribute target

::method init
    self~init:super
    self~dump = .false
    self~elementsStack = .Queue~new
    self~log = .stderr
    self~output = .stdout
    self~target = ""

::method start_element
    use arg chunk
    self~elementsStack~push(chunk)
    if self~debug then self~output~charout('[start_element:'chunk~line':'chunk~col'[')
    if self~dump then do
        self~output~charout('<'chunk~tag)
        if chunk~attr <> .nil then 
            do f over chunk~attr
                self~output~charout(' 'f'="'self~xlatetext(chunk~attr[f])'"')
            end
        self~output~charout('>')
    end
    else do
        self~output~charout('<'chunk~text'>')
    end
    if self~debug then self~output~charout(']start_element]')
    return

::method end_element
    use arg chunk
    self~check_endtag_validity(chunk)
    if self~debug then self~output~charout('[end_element:'chunk~line':'chunk~col'[')
    if self~dump then do
        self~output~charout('</'chunk~tag'>')
    end
    else do
        if chunk~text = '' then self~output~charout('</'chunk~tag'>')
    end
    if self~debug then self~output~charout(']end_element]')
    self~elementsStack~pull
    return

::method passthrough
    use arg chunk
    if self~debug then self~output~charout('[passthrough:'chunk~line':'chunk~col'[')
    if self~dump then do
        self~output~charout('<'chunk~text'>')
    end
    else do
        self~output~charout('<'chunk~text'>')
    end
    if self~debug then self~output~charout(']passthrough]')
    return

::method text
    use arg chunk
    if self~debug then self~output~charout('[text:'chunk~line':'chunk~col'[')
    if self~dump then do
        self~output~charout(chunk~text)
    end
    else do
        self~output~charout(chunk~text)
    end
    if self~debug then self~output~charout(']text]')
    return

::method error
    use arg err
    self~log~lineout("[error] "err~text)
    return

::method xlatetext private
    use arg text
    /*
    text = text~changestr('&', '&amp;') -- always do this one first!
    text = text~changestr('>', '&gt;')
    text = text~changestr('<', '&lt;')
    */
    return text

::method check_endtag_validity
    use arg chunk
    loop
        topChunk = self~elementsStack~peek
        if topChunk == nil then do
            self~log~lineout("[error] The elements stack is empty. Can't close "chunk~tag":"chunk~line':'chunk~col)
            self~abort
        end
        if topChunk~tag == chunk~tag then return 1
        if topChunk~tag == "imagedata" then do
            self~elementsStack~pull -- Known problem, imagedata not closed, remove it
            iterate
        end
        if topChunk~tag == "colspec" then do
            self~elementsStack~pull -- Known problem, colspec not closed, remove it
            iterate
        end
        if topChunk~tag == chunk~tag then return 1
        self~log~lineout("[error] The closing tag does not match the last opened tag :")
        self~log~lineout("[error]     opened tag  = "topChunk~tag":"topChunk~line':'topChunk~col)
        self~log~lineout("[error]     closing tag = "chunk~tag":"chunk~line':'chunk~col)
        self~abort
    end

::method check_stack_empty
    if self~elementsStack~isEmpty then return 1
    self~log~lineout("The elements stack is not empty.")
    self~abort

::method abort
    self~log~lineout("[error] Aborting !")
    raise syntax 4 -- Don't know what's the best here... I want to abort the program, but exit 1 does not work, raise user abort does not work, it seems that only raise syntax works...


-------------------------------------------------------------------------------
::class Arguments subclass CommonArguments

::method init
    use strict arg callType, arguments -- always an array
    self~init:super(callType, arguments)
    -- Return now if help requested
    if self~help then return
    
    self~inputFile = ""
    self~logFile = ""
    self~outputFile = ""
    
    -- Process the options
    loop i=1 to self~args~items
        option = self~args[i]
        if option~left(1) <> "-" then leave
        select
            when self~parseOption(option) then nop
            otherwise do
                self~errors~append("[error] Unknown option" option)
                return
            end
        end
        -- Return now if help requested
        if self~help then return
    end
    
    self~verifyOptions
    if \self~errors~isEmpty then return
    
    -- Process the arguments
    -- inputFile is mandatory
    if i > self~args~items then do
        self~errors~append("[error] <inputFile> is missing")
        return
    end
    self~inputFile = self~args[i]~strip
    i += 1
    
    -- outputFile is optional
    if i > self~args~items then return
    self~outputFile = self~args[i]~strip
    if self~outputFile~left(1) == "-" then do
        self~errors~append("[error] Options are before <inputFilename>")
        return
    end
    i += 1
    
    -- logFile is optional
    if i > self~args~items then return
    self~logFile = self~args[i]~strip
    if self~outputFile~left(1) == "-" then do
        self~errors~append("[error] Options are before <inputFilename>")
        return
    end
    i += 1
    
    -- no more argument expected
    if i > self~args~items then return
    self~errors~append("[error] Unexpected arguments :" self~args~section(i)~toString("L", " "))
    return

