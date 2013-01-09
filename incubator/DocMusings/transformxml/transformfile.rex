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
        [-debug] [-dsssl] [-dump] [-help] [-syntdiag] [-xslt]
        [-reportlinks <linksFile>]
        <inputFile> [<outputFile> [<logFile>]]
Description :
    This script is intended to work on the XML files of the ooRexx doc.
    It reads the file <inputFile>, parses it and writes the transformed XML in
    the file <outputFile> (or stdout if no outputFile). 
    By default, there is no transformation and the layout of the output file
    is kept the most similar possible to the layout of the input.
    
    Options :
    -debug    : Insert additional informations in the ouptut. A part is sent to
                stderr, another part is inserted in the XML output (making it
                non valid).
    -dsssl    : Generate DocBook XML compatible with DSSSL (default).
    -dump     : The XML elements and attributes are dumped without attempting to
                keep the original layout.
                When used with -syntdiag, the internal structures of the parser
                are dumped in the sd_<file>.xml.
    -reportlinks <linksFile> : 
                Appends in the file <linksFile> the links having several words in
                their child text. Such links are known to bring troubles when they
                are at the boundary of two pages.
    -syntdiag : Replace textual syntax diagrams by a reference to an image (the
                name of the image is derived from the enclosing DocBook section).
                And generate an XML syntax diagram file that will be processed 
                by syntaxdiagram2svg. Batik can generate the image from the svg.
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

if arguments~logFile <> "" then do
    log = .stream~new(arguments~logFile)
    log~open("write append shared nobuffer")
end

parser = .myparser~new()
parser~debug = arguments~debug
parser~dump = arguments~dump
parser~log = log

if arguments~dsssl then parser~target = "dsssl"
if arguments~xslt then parser~target = "xslt"

if arguments~outputFile <> "" then do
    parser~output = .stream~new(arguments~outputFile)
    if parser~output~command("open write replace shared") <> "READY:" then do
        parser~logErr("[error] Error opening "arguments~outputFile)
        parser~logTxt("[error] "parser~output~description)
        return 1
    end
    parser~outputFile = arguments~outputFile
end

if arguments~syntdiag then do
    parser~syntdiag = .true 
    -- The name of the syntax diagram file is derived from the output file, if any
    -- Otherwise use the default name
    if parser~outputFile~caselessEquals("stdout") == .false then do
        location = filespec("location", parser~outputFile)
        nameSuffix = filespec("name", parser~outputFile)
        suffix = filespec("extension", parser~outputFile)
        name = nameSuffix~left(nameSuffix~length - suffix~length - 1)
        parser~syntdiagBasename = "sd_" || name
        parser~syntdiagOutputFile = location || parser~syntdiagBasename || ".xml"
    end
    -- The file will be created later, when the first syntax diagram is created
end

if arguments~reportlinks then do
    parser~links = .stream~new(arguments~reportlinksValue)
    if parser~links~command("open write append shared nobuffer") <> "READY:" then do
        parser~logErr("[error] Error opening "arguments~reportlinksValue)
        parser~logTxt("[error] "parser~links~description)
        return 1
    end
end

parser~inputFile = arguments~inputFile
signal on syntax -- The parser can abort by raising a syntax 4 (??? why only a "syntax" can be propagated automatically ???)
errortxt = parser~parse_file(arguments~inputFile)
if parser~output <> .stdout then parser~output~close -- must close explicitely, otherwise the touch in case of error will fail
if errortxt <> "" then do
    parser~logErr("[error] The XML parser returned "errortxt)
    return 1
end

if parser~syntdiagOutput <> .nil then do
    parser~syntdiagOutput~lineout("</syntaxdiagrams>")
    parser~syntdiagOutput~close
end

if parser~check_stack_empty == .false then return 1

-- Convert the syntax diagrams to images
if parser~syntdiagOutput <> .nil then call sd2image parser~syntdiagOutputFile

if parser~errorCount <> 0 then return 1
return 0

syntax: -- In fact, it's an abort, not a syntax error...
    if parser~output <> .stdout then parser~output~close -- must close explicitely, otherwise the touch in case of error will fail
    return 1

::requires 'arguments.cls'
::requires 'help.cls'
::requires "indentedstream.cls"
::requires 'myxmlparser.cls'
::requires 'rxregexp.cls'
--::requires 'sdbnfizer.cls' -- to reactivate if needed
::requires 'sdtokenizer.cls'
::requires 'sdparser.cls'
::requires 'sdxmlizer.cls'


-------------------------------------------------------------------------------
::class myparser subclass xmlparser
::attribute documentNode
::attribute dump
::attribute elementsStack
::attribute errorCount
::attribute inputFile
::attribute log
::attribute output
::attribute outputFile
::attribute syntdiag
::attribute syntdiagBasename
::attribute syntdiagNames
::attribute syntdiagOutput
::attribute syntdiagOutputFile
::attribute target
::attribute links


::method init
    self~init:super
    self~documentNode = .Node~new(.nil) -- Toplevel title is ""
    self~dump = .false
    self~elementsStack = .Queue~new
    self~errorCount = 0
    self~links = .nil
    self~log = .stderr
    self~output = .stdout
    self~outputFile = "stdout"
    self~syntdiag = .false
    self~syntdiagBasename = "SyntaxDiagram"
    self~syntdiagNames = .Directory~new -- To avoid name collision, manage a counter per name
    self~syntdiagOutput = .nil -- The file will be created when the first syntax diagram is added
    self~syntdiagOutputFile = self~syntdiagBasename".xml"
    self~target = "dsssl"

    
::method start_element
    use strict arg chunk
    self~elementsStack~push(.Node~new(chunk))
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
    use strict arg chunk
    self~check_endtag_validity(chunk)
    if self~debug then self~output~charout('[end_element:'chunk~line':'chunk~col'[')
    if self~dump then do
        self~output~charout('</'chunk~tag'>')
    end
    else do
        -- print nothing if not empty, because already printed by start_element (text is used as a flag to decide if the element must be closed or not)
        if chunk~text = '' then self~output~charout('</'chunk~tag'>')
    end
    if self~debug then self~output~charout(']end_element]')
    self~elementsStack~pull
    return

    
::method passthrough
    use strict arg chunk
    if self~syntdiag, self~transform_syntax_diagram(chunk) then return
    if self~target == "dsssl", self~make_dsssl_compliant(chunk) then return
    if self~target == "xslt", self~make_xslt_compliant(chunk) then return
    -- insert the cdata normally
    if self~debug then self~output~charout('[passthrough:'chunk~line':'chunk~col'[')
    self~output~charout('<'chunk~text'>')
    if self~debug then self~output~charout(']passthrough]')
    return

    
::method text
    use strict arg chunk
    if self~is_title_text(chunk) then self~set_title(chunk)
    if self~debug then self~output~charout('[text:'chunk~line':'chunk~col'[')
    self~output~charout(chunk~text)
    if self~debug then self~output~charout(']text]')
    
    if self~links <> .nil then do
        if self~parent == .nil then return
        parentChunk = self~parent~chunk
        if parentChunk == .nil then return
        if parentChunk~tag == "link" then do
            chunkText = chunk~text~changeStr(d2c(10), " ")~changeStr(d2c(13), " ")
            if chunkText~words <= 1 then return
            self~links~charout(self~inputFile" ; "parentChunk~line" ; "parentChunk~col" ;")
            do w = 1 to chunkText~words
                self~links~charout(" "chunkText~word(w))
            end
            self~links~lineout("")
        end
    end
    return


::method logTxt
    use strict arg text
    self~log~lineout(text)
    return
    
    
::method logErr
    use strict arg text
    self~logTxt(text)
    self~errorCount += 1
    return
    
    
::method error
    use strict arg err
    self~logErr("[error] "err~text)
    return


::method xlatetext private
    use strict arg text
    /*
    text = text~changestr('&', '&amp;') -- always do this one first!
    text = text~changestr('>', '&gt;')
    text = text~changestr('<', '&lt;')
    */
    return text

    
::method check_endtag_validity
    use strict arg chunk
    loop
        topNode = self~elementsStack~peek
        if topNode == .nil then do
            self~logErr("[error] The elements stack is empty. Can't close "chunk~tag":"chunk~line':'chunk~col)
            self~abort
        end
        if topNode~chunk~tag == chunk~tag then return 1
        if topNode~chunk~tag == "imagedata" then do
            self~elementsStack~pull -- Known problem, imagedata not closed, remove it
            iterate
        end
        if topNode~chunk~tag == "colspec" then do
            self~elementsStack~pull -- Known problem, colspec not closed, remove it
            iterate
        end
        self~logErr("[error] The closing tag does not match the last opened tag :")
        self~logTxt("[error]     opened tag  = "topNode~chunk~tag":"topNode~chunk~line':'topNode~chunk~col)
        self~logTxt("[error]     closing tag = "chunk~tag":"chunk~line':'chunk~col)
        self~abort
    end

    
::method check_stack_empty
    if self~elementsStack~isEmpty then return .true
    self~logErr("[error] The elements stack is not empty.")
    return .false

    
::method transform_syntax_diagram
    use strict arg chunk
    if chunk~cdata_text == .nil then return .false
    
    tokenizer = self~tokenize_syntax_diagram(chunk~cdata_text, chunk~line)
    if tokenizer == .nil then return .false
    if tokenizer~errorCount <> 0 then return .false
    
    parser = self~parse_syntax_diagram(tokenizer, chunk~line)
    if parser~errorCount <> 0 then return .false

    xmlizer = self~xmlize_syntax_diagram(tokenizer, parser)
    if xmlizer~errorCount <> 0 then return .false
    
    -- bnfizer = self~bnfize_syntax_diagram(tokenizer, parser)
    -- if bnfizer <> .nil, bnfizer~errorCount <> 0 then return .false
    
    -- good, from here, we know that the syntax diagram has been converted to XML.
    -- we can reference each image or insert the comments.
    self~reference_syntax_diagram(parser)
    
    return .true

    
::method tokenize_syntax_diagram
    use strict arg text, line
    tokenizer = .SyntaxDiagramTokenizer~tokenize(text, self~endofline)
    if tokenizer == .nil then return .nil
    
    -- From here, we know that this cdata contains a textual syntax diagram
    if self~syntdiagOutput == .nil then do
        self~syntdiagOutput = .stream~new(self~syntdiagOutputFile)
        if self~syntdiagOutput~command("open write replace shared") <> "READY:" then do
            self~logErr("[error] Error opening "self~syntdiagOutputFile)
            self~logTxt("[error] "self~syntdiagOutput~description)
            self~abort
        end
        self~syntdiagOutput = .IndentedStream~new(self~syntdiagOutput)
        self~syntdiagOutput~lineout("<syntaxdiagrams>")
        self~syntdiagOutput~lineout("")
    end
    
    tokenizer~name = self~syntax_diagram_name -- name guaranted unique
    
    self~syntdiagOutput~charout("<!--")
    self~syntdiagOutput~lineout("="~copies(76))
    self~syntdiagOutput~lineout(tokenizer~name)
    self~syntdiagOutput~charout("="~copies(77))
    self~syntdiagOutput~lineout("-->")
    self~syntdiagOutput~lineout("")
    
    -- I don't want to enforce the rule that any syntax diagram must be in a <programlisting>
    -- But I'd like to know when it's not the case...
    topNode = self~elementsStack~peek
    if topNode~chunk~tag <> "programlisting" then do
        self~log~lineout("[warning] "tokenizer~name" not in <programlisting>...</programlisting>")
    end
    
    if tokenizer~errorCount <> 0 then do
        self~syntdiagOutput~lineout("<![CDATA[")
        tokenizer~inspect(self~syntdiagOutput)
        self~syntdiagOutput~lineout("]]>")
        self~syntdiagOutput~lineout("")
        
        self~logErr("[error] Syntax diagram tokenization failed for "tokenizer~name" line "line)
        -- not abort because we can continue by inserting the textual sd
    end
    return tokenizer
        
    
::method parse_syntax_diagram
    use strict arg tokenizer, line
    parser = .SyntaxDiagramParser~parse(tokenizer, self)
    if parser~errorCount <> 0 then do
        self~syntdiagOutput~lineout("<![CDATA[")
        tokenizer~inspect(self~syntdiagOutput)
        self~syntdiagOutput~lineout("]]>")
        self~syntdiagOutput~lineout("")
        
        self~syntdiagOutput~lineout("<![CDATA[")
        parser~inspect(self~syntdiagOutput)
        self~syntdiagOutput~lineout("]]>")
        self~syntdiagOutput~lineout("")
        
        self~logErr("[error] Syntax diagram parsing failed for "tokenizer~name" line "line)
        -- not abort because we can continue by inserting the textual sd
    end
    return parser
    
        
::method xmlize_syntax_diagram
    use strict arg tokenizer, parser
    self~syntdiagOutput~lineout("<![CDATA[")
    tokenizer~dumpText(self~syntdiagOutput)
    self~syntdiagOutput~lineout("]]>")
    self~syntdiagOutput~lineout("")

    xmlizer = .SyntaxDiagramXMLizer~xmlize(parser~mainEntries, self~syntdiagOutput)
    self~syntdiagOutput~lineout("")

    if xmlizer~errorCount <> 0 | self~dump then do
        self~syntdiagOutput~lineout("<![CDATA[")
        xmlizer~inspect(self~syntdiagOutput)
        parser~dumpAbstractSyntaxTree(self~syntdiagOutput)
        self~syntdiagOutput~lineout("]]>")
        self~syntdiagOutput~lineout("")
    end
        
    if xmlizer~errorCount <> 0 then do
        self~logErr("[error] Syntax diagram XML generation failed for "tokenizer~name)
        -- not abort because we can continue by inserting the textual sd
    end
    return xmlizer
    
    
::method bnfize_syntax_diagram
    use strict arg tokenizer, parser
    bnfizer = .SyntaxDiagramBNFizer~bnfize(parser~mainEntries)
    if bnfizer == .nil then return .nil
    
    self~syntdiagOutput~lineout("<![CDATA[")
    bnfizer~inspect(self~syntdiagOutput)
    self~syntdiagOutput~lineout("]]>")
    self~syntdiagOutput~lineout("")
        
    if bnfizer~errorCount <> 0 then do
        self~logErr("[error] Syntax diagram BNF generation failed for "tokenizer~name)
        -- not abort because we can continue by inserting the textual sd
    end
    return bnfizer
    
    
::method reference_syntax_diagram
    use strict arg parser
    cdata = .false -- consecutive comments will be serialized in the same cdata
    newline = .false -- don't insert a newline if last line, because on return a newline will be inserted 
    do entry over parser~mainEntries
        if newline then do
            self~output~lineout("")
            newline = .false
        end
        if entry~isA(.sdparser~Comment) then do
            if cdata == .false then do
                self~output~lineout("<![CDATA[")
                cdata = .true
            end
            self~output~lineout(entry~text)
        end
        else do
            if cdata == .true then do
                self~output~lineout("]]>")
                cdata = .false
            end
            
            -- I have two candidate formats : PDF and PNG
            -- No need of two distinct imagedata. Use a single one, without extension, and
            -- assign PDF or PNG to %graphic-default-extension%.
            -- Inside programlisting, only inline media objects are allowed
            fileref = self~syntdiagBasename"/"entry~hrefbase -- relative path without extension
            self~output~lineout('<inlinemediaobject>')
            self~output~lineout('    <imageobject>')
            self~output~charout('        <imagedata fileref="'fileref'"')
            if self~target == "dsssl" then self~output~lineout('>') -- bug OpenJade
            else self~output~lineout('/>')
            self~output~lineout('    </imageobject>')
            self~output~charout('</inlinemediaobject>')
            
            newline = .true
        end
    end
    if cdata == .true then self~output~charout("]]>")
    
    
::method syntax_diagram_label
    use strict arg -- none
    parent1 = self~parent_with_title(1)
    label = parent1~title
    return label

    
::method syntax_diagram_name
    use strict arg prefix="", suffix=""
    -- Use the concatenation of two titles to reduce the risk of collision
    parent1 = self~parent_with_title(1)
    parent2 = self~parent_with_title(2)
    name = prefix" "parent2~title" "parent1~title" "suffix
    name = filename(name, "_")
    if self~syntdiagNames[name] == .nil then do
        self~syntdiagNames[name] = 1
    end
    else do
        self~syntdiagNames[name] += 1
        name = name"_"self~syntdiagNames[name]
    end
    return name

    
::method make_dsssl_compliant
    use strict arg chunk
    return .false

    
::method make_xslt_compliant
    use strict arg chunk
    return .false -- no longer needed since publican adaptation
    
    if chunk~text~left(6) == "<?xml " then do
        self~output~lineout('<?xml version="1.0" standalone="no"?>')
        return .true
    end
    if chunk~text~left(10) == "<!DOCTYPE " then do
    /*
    <!DOCTYPE article PUBLIC "-//OASIS//DTD DocBook V4.2//EN"
    must have a system identifier
    <!DOCTYPE article PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN" "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd"
    */
        return .false -- not yet implemented
    end
    return .false

    
::method is_title_text
    use strict arg chunk
    topNode = self~elementsStack~peek
    if topNode = .nil then return .false
    return topNode~chunk~tag == "title" -- <title>text

    
::method set_title
    -- Store the text of the <title> in the 'title' property of the <parent>
    -- ...<parent><title>text
    --  3     2      1
    use strict arg chunk
    if self~elementsStack~hasIndex(2) then self~elementsStack~at(2)~title = chunk~text

    
::method parent
    use strict arg -- none
    index = self~elementsStack~first
    if index == .nil then return self~documentNode
    return self~elementsStack~at(index)
    
    
::method parent_with_title
    use strict arg number
    index = self~elementsStack~first
    do while index <> .nil
        node = self~elementsStack~at(index)
        if node~title <> "" then do
            number -= 1
            if number <= 0 then return node
        end
        index = self~elementsStack~next(index)
    end
    return self~documentNode -- fallback if no parent with title in the stack
    
    
::method abort
    self~logErr("[error] Aborting !")
    -- Don't know what's the best here... I want to abort the program, but exit 1 does not work, raise user abort does not work, it seems that only raise syntax works...
    raise syntax 4 -- ABORT


-------------------------------------------------------------------------------
-- I need to store additional infos about the chunk, use a wrapper
::class Node
::attribute chunk
::attribute title

::method init
    use strict arg chunk
    self~chunk = chunk
    self~title = ""


-------------------------------------------------------------------------------
::class Arguments subclass CommonArguments

::method initEntries
    self~initEntries:super
    self~inputFile = ""
    self~logFile = ""
    self~outputFile = ""


::method parseArguments
    -- inputFile is mandatory
    if self~argIndex > self~args~items then do
        self~errors~append("[error] <inputFile> is missing")
        return
    end
    self~inputFile = self~args[self~argIndex]~strip
    self~argIndex += 1
    
    -- outputFile is optional
    if self~argIndex > self~args~items then return
    self~outputFile = self~args[self~argIndex]~strip
    if self~outputFile~left(1) == "-" then do
        self~errors~append("[error] Options are before <inputFilename>")
        return
    end
    self~argIndex += 1
    
    -- logFile is optional
    if self~argIndex > self~args~items then return
    self~logFile = self~args[self~argIndex]~strip
    if self~outputFile~left(1) == "-" then do
        self~errors~append("[error] Options are before <inputFilename>")
        return
    end
    self~argIndex += 1
    
    -- no more argument expected
    if self~argIndex > self~args~items then return
    self~errors~append("[error] Unexpected arguments :" self~args~section(self~argIndex)~toString("L", " "))
    return


-------------------------------------------------------------------------------
::routine filename
    -- "my name" --> "my_name"
    -- "special characters (like +?%) supported ? yes !" --> "special_characters_like_supported_yes" 
    use strict arg text, separator
    buffer = .MutableBuffer~new(text)
    alnum = .RegularExpression~new("[:ALNUM:]")
    do i=1 to buffer~length
        if \alnum~match(buffer~subchar(i)) then buffer~replaceAt(" ", i, 1)
    end
    return buffer~string~space~translate(separator, " ")

