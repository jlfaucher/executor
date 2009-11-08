/*
Depends on BNF4OOo
http://sourceforge.net/projects/bnf4ooo/
a project of Franz Hohenegger.

BNF4OOo must be in the PATH.
This is a very preliminary binding to BNF4OOo :
Create the file <BNF4OOo>/xml/BNF4OOo.xml from a syntax diagram parse tree.
Call the script rexxmain.rex of BNF4OOo to convert XML to BNF.
Get the resulting bnf in the file <BNF4OOo>/bnf/bnf.txt
*/

-- Getting filePaths
.SyntaxDiagramBNFizer~BNF4OOoPath = filespec("Location", syssearchpath("PATH", "BNFController.cls"))
if .SyntaxDiagramBNFizer~BNF4OOoPath == "" then do
    say "Can't find BNF4OOo in your PATH"
    return 1
end
call "publicRoutines.rex"
.SyntaxDiagramBNFizer~bnfFile = qualify(.SyntaxDiagramBNFizer~BNF4OOoPath"/".local~bnf4OOo.fileDir[bnfFile])
.SyntaxDiagramBNFizer~xmlFile = qualify(.SyntaxDiagramBNFizer~BNF4OOoPath"/".local~bnf4OOo.fileDir[bnf4OOoFile])

return 0

::requires "indentedstream.cls"
::requires "sdparser.cls"


-------------------------------------------------------------------------------
::class "SyntaxDiagramBNFizer" public
::attribute BNF4OOoPath class
::attribute bnffile class
::attribute bnflines -- array of strings
::attribute errorCount
::attribute messages -- list of strings
::attribute xmlfile class
::attribute xmllines -- array of strings
::attribute xmlstream


::method bnfize class
    use strict arg astEntries
    if self~BNF4OOoPath == "" then return .nil
    
    bnfizer = self~new
    if bnfizer~errorCount <> 0 then return bnfizer
    
    -- Generate the XML4BNF from the parser AST
    bnfizer~xmlstream~lineout('<?xml version="1.0" encoding="UTF-8"?>')
    bnfizer~xmlstream~lineout('<BNF4OOo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BNF4OOo.xsd">')
    bnfizer~xmlstream~indent
    do astEntry over astEntries
        bnfizer~bnfize(astEntry)
    end
    bnfizer~xmlstream~dedent
    bnfizer~xmlstream~lineout("</BNF4OOo>")
    bnfizer~xmlstream~close
    
    -- Transform the XML4BNF to BNF
    currentDir = directory(self~BNF4OOoPath) -- Make BNF4OOo the default directory (mandatory)
    'rexx rexxmain.rex xml2bnf' -- Run in a different process to avoid problems with the XML parser (two different versions)
    call directory currentDir -- Restore
    
    -- Get the XML (for diagnostic)
    bnfizer~readxml

    -- Get the BNF (for insertion in doc)
    bnfizer~readbnf
    
    return bnfizer


::method bnfize
    use strict arg astElement
    if astElement == .nil then return .true
    -- The current package has (should have) the same set of classes as the parser's AST.
    serializer = .context~package~findclass(astElement~class~id)
    if serializer == .nil then do
        self~addError("[error] Unknown AST class : "astElement~class~id)
        return .false
    end
    return serializer~serialize(astElement, self)


::method init
    use strict arg -- none
    self~errorCount = 0
    self~bnflines = .Array~new
    self~messages = .List~new
    self~objectName = self~class~id
    self~xmlstream = .stream~new(self~class~xmlfile)
    if self~xmlstream~command("open write replace") <> "READY:" then do
        self~addError("[error] Error opening "self~class~xmlfile)
        self~addMessage("[error] "self~xmlstream~description)
        return
    end
    self~xmlstream = .IndentedStream~new(self~xmlstream)

    
::method addMessage
    use strict arg message
    self~messages~append(message)
    
    
::method addError
    use strict arg message
    self~addMessage(message)
    self~errorCount += 1
    
    
::method readxml
    use strict arg -- none
    xmlstream = .stream~new(self~class~xmlfile)
    if xmlstream~command("open read") <> "READY:" then do
        self~addError("[error] Error opening "self~class~xmlfile)
        self~addMessage("[error] "xmlstream~description)
        return
    end
    self~xmllines = xmlstream~arrayIn
    xmlstream~close

    
::method readbnf
    use strict arg -- none
    bnfstream = .stream~new(self~class~bnffile)
    if bnfstream~command("open read") <> "READY:" then do
        self~addError("[error] Error opening "self~class~bnffile)
        self~addMessage("[error] "bnfstream~description)
        return
    end
    self~bnflines = bnfstream~arrayIn
    bnfstream~close

    
::method dump
    use strict arg stream = (.IndentedStream~stdout)
    -- diagnostic
    if self~errorCount == 0 then stream~lineout("BNF generation : OK")
    else stream~lineout("BNF generation : KO")
    do m over self~messages 
        stream~lineout(m)
    end
    stream~lineout("")
    -- XML
    do l over self~xmllines 
        stream~lineout(l)
    end
    stream~lineout("")
    -- BNF
    do l over self~bnflines 
        stream~lineout(l)
    end
    stream~lineout("")


::method inspect -- for debug
    use strict arg stream = (.IndentedStream~stdout)
    stream~lineout(self~string" :")
    stream~lineout("")
    self~dump(stream)

    
-------------------------------------------------------------------------------
::class "XMLSerializer"


::method serialize class
    use strict arg astElement, bnfizer
    done = .true
    if astElement~importance == .sdparser~AbstractSyntaxElement~default then do
        bnfizer~xmlstream~lineout("<argument>")
        bnfizer~xmlstream~indent
    end
    else if astElement~importance == .sdparser~AbstractSyntaxElement~optional then do
        bnfizer~xmlstream~lineout("<optional>")
        bnfizer~xmlstream~indent
    end
    self~opentag(astElement, bnfizer)
    bnfizer~xmlstream~indent
        do child over astElement~childs
            done = bnfizer~bnfize(child)
            if \ done then leave
        end
    bnfizer~xmlstream~dedent
    self~closetag(astElement, bnfizer)
    if astElement~importance == .sdparser~AbstractSyntaxElement~default then do
        bnfizer~xmlstream~dedent
        bnfizer~xmlstream~lineout("</argument>")
    end
    else if astElement~importance == .sdparser~AbstractSyntaxElement~optional then do
        bnfizer~xmlstream~dedent
        bnfizer~xmlstream~lineout("</optional>")
    end
    return done

    
-------------------------------------------------------------------------------
::class "SyntaxDiagram" subclass "XMLSerializer"


::method opentag class
    use strict arg syntaxDiagram, bnfizer
    -- If no title, its because a fragment is embedded (see in sdparser.cls : SyntaxDiagramParser~parse)
    if syntaxDiagram~title <> "" then do
        bnfizer~xmlstream~lineout('<definition id="'syntaxDiagram~title'" name="'syntaxDiagram~label'">')
        bnfizer~xmlstream~indent
    end
    
    
::method closetag class
    use strict arg syntaxDiagram, bnfizer
    if syntaxDiagram~title <> "" then do
        bnfizer~xmlstream~dedent
        bnfizer~xmlstream~lineout("</definition>")
    end
    

-------------------------------------------------------------------------------
::class "Group" subclass "XMLSerializer"


::method opentag class
    use strict arg group, bnfizer
    /*
    If I understand correctly, must transform that way :
    -----
    (not sure for this part about optionalloop - more work needed, not implemented)
    If a group is declared "required", and has a repsep then
        Can't use an optionalloop
    If a groupcomp or groupseq is declared optional, and has a repsep then
        Use an optionalloop
    If a groupcomp or groupseq has no importance attribute, and has a repsep (child 1), and childs 2..n are optional then
        Use an optionalloop
    If a groupchoice is declared optional, and has a repsep then 
        The childs are optional by default. 
        [No : If you find one child explicitely "required" then you can't use optionalloop]
        I made a test, the required child is not displayed on the main line, which remains empty.
        So the visual interpretation is "optional".
        It's maybe a bug in the DITA addin syntaxdiagram2svg, or maybe it's a non-sense to have both.
        Use an optionalloop, always
    If a groupchoice has no importance attribute, and has a repsep then
        It's not optional by default... except if an empty <groupseq/> has been used to make the
        main line empty. I have this case in rexxref/sd_func.xml for sd_Built_in_Functions_LINES_Lines_Remaining.
        I think I can eliminate this case by removing this empty line in Group~simplify and declaring the group "optional".
    -----
    groupchoice + repsep : loop xor
    groupcomp + repsep : loop
    groupseq + repsep : loop
    -----
    groupchoice : xor
    groupcomp : bracket
    groupseq : bracket
    
    Note : we loose the distinction between groupcomp and groupseq, so will need to rebuild it
    when parsing the bnf, based on the presence of spaces between elements (tricky).
    
    Note : expression in repspep are not supported (not needed for ooRexx doc - currently)
    */
    if group~childs~firstItem~isA(.sdparser~RepSep) then do
        bnfizer~xmlstream~lineout("<loop>")
        bnfizer~xmlstream~indent
        if group~kind == .sdparser~Group~groupchoice then do
            bnfizer~xmlstream~lineout("<xor>")
            bnfizer~xmlstream~indent
        end
    end
    else do
        if group~kind == .sdparser~Group~groupchoice then bnfizer~xmlstream~lineout("<xor>")
        else bnfizer~xmlstream~lineout("<bracket>")
        bnfizer~xmlstream~indent
    end
    
    
::method closetag class
    use strict arg group, bnfizer
    if group~childs~firstItem~isA(.sdparser~RepSep) then do
        if group~kind == .sdparser~Group~groupchoice then do
            bnfizer~xmlstream~dedent
            bnfizer~xmlstream~lineout("</xor>")
        end
        bnfizer~xmlstream~dedent
        bnfizer~xmlstream~lineout("</loop>")
    end
    else do
        bnfizer~xmlstream~dedent
        if group~kind == .sdparser~Group~groupchoice then bnfizer~xmlstream~lineout("</xor>")
        else bnfizer~xmlstream~lineout("</bracket>")
    end


-------------------------------------------------------------------------------
::class "RepSep" subclass "XMLSerializer"


::method serialize class
    use strict arg repsep, bnfizer
    -- Nothing to do, managed by Group
    return .true


-------------------------------------------------------------------------------
::class "FragRef" subclass "XMLSerializer"


::method serialize class
    use strict arg fragref, bnfizer
    fragmentId = "fragmentId" -- Don't know how to get the fragment's id, I think it's impossible to guess it from the doc.
    bnfizer~xmlstream~lineout('<data id="'fragmentId'" name="'fragref~text'"/>')
    return .true


-------------------------------------------------------------------------------
::class "Fragment" subclass "XMLSerializer"


::method opentag class
    use strict arg fragment, bnfizer
    bnfizer~xmlstream~lineout('<definition id="'fragment~title'" name="'fragment~label'">')
    bnfizer~xmlstream~indent
    
    
::method closetag class
    use strict arg fragment, bnfizer
    bnfizer~xmlstream~dedent
    bnfizer~xmlstream~lineout("</definition>")

    
-------------------------------------------------------------------------------
::class "Kwd" subclass "XMLSerializer"


::method serialize class
    use strict arg kwd, bnfizer
    bnfizer~xmlstream~lineout('<data name="'kwd~text'"/>')
    return .true


-------------------------------------------------------------------------------
::class "Var" subclass "XMLSerializer"


::method serialize class
    use strict arg var, bnfizer
    bnfizer~xmlstream~lineout('<data name="'var~text'"/>')
    return .true


-------------------------------------------------------------------------------
::class "Characters" subclass "XMLSerializer"


::method serialize class
    use strict arg characters, bnfizer
    bnfizer~xmlstream~lineout('<data name="'self~xlatetext(characters~text)'"/>')
    return .true


::method xlatetext class
    use strict arg text
    text = text~changestr('&', '&amp;') -- always do this one first!
    text = text~changestr('>', '&gt;')
    text = text~changestr('<', '&lt;')
    return text


-------------------------------------------------------------------------------
::class "Comment" subclass "XMLSerializer"


::method serialize class
    return .true -- nothing to do

