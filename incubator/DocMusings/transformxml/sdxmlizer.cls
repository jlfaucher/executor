::requires "sdparser"
::requires "indentedstream.cls"


-------------------------------------------------------------------------------
/*
Generate XML files that will be processed by an XSLT script derived from 
com.moldflow.dita.syntaxdiagram2svg ("Plus" plugins for Dita). 
No need of the DITA Open Toolkit, because this plugin works independently.
See http://dita.xml.org/wiki/plugins-for-the-dita-open-toolkit
and
http://tech.groups.yahoo.com/group/dita-users/message/12082
This plugin has been designed by Deborah Pickett.
It's available under the same open-source terms as DITA-OT.
*/


::class "SyntaxDiagramXMLizer" public
::attribute errorCount
::attribute messages -- list of strings
::attribute stream


::method xmlize class
    use strict arg astEntries, stream = (.IndentedStream~stdout)
    xmlizer = self~new(stream)
    do astEntry over astEntries
        xmlizer~xmlize(astEntry)
    end
    return xmlizer


::method xmlize
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
    use strict arg stream
    self~errorCount = 0
    self~messages = .List~new
    self~stream = stream
    self~objectName = self~class~id
    
    
::method addMessage
    use strict arg message
    self~messages~append(message)
    
    
::method addError
    use strict arg message
    self~addMessage(message)
    self~errorCount += 1
    
    
::method dump
    use strict arg stream = (.IndentedStream~stdout)
    -- diagnostic
    if self~errorCount == 0 then stream~lineout("XML generation : OK")
    else stream~lineout("XML generation : KO")
    do m over self~messages 
        stream~lineout(m)
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
    use strict arg astElement, xmlizer
    done = .true
    self~opentag(astElement, xmlizer)
    xmlizer~stream~indent
        do child over astElement~childs
            done = xmlizer~xmlize(child)
            if \ done then leave
        end
    xmlizer~stream~dedent
    self~closetag(astElement, xmlizer)
    return done

    
::method attributes class
    use strict arg astElement
    if astElement~importance <> 0 then return ' importance="'astElement~importanceString'"'
    return ""
    
    
-------------------------------------------------------------------------------
::class "SyntaxDiagram" subclass "XMLSerializer"


::method opentag class
    use strict arg syntaxDiagram, xmlizer
    xmlizer~stream~lineout("<syntaxdiagram" || self~attributes(syntaxDiagram) || ">")
    xmlizer~stream~indent
        if syntaxDiagram~title <> "" then xmlizer~stream~lineout("<title>"syntaxDiagram~title"</title>")
    xmlizer~stream~dedent
    
    
::method closetag class
    use strict arg syntaxDiagram, xmlizer
    xmlizer~stream~lineout("</syntaxdiagram>")
    

-------------------------------------------------------------------------------
::class "Group" subclass "XMLSerializer"


::method opentag class
    use strict arg group, xmlizer
    xmlizer~stream~lineout("<" || group~kindString || self~attributes(group) || ">")
    xmlizer~stream~indent
        xmlizer~xmlize(group~repsep)
    xmlizer~stream~dedent
    
    
::method closetag class
    use strict arg group, xmlizer
    xmlizer~stream~lineout("</"group~kindString">")
    

-------------------------------------------------------------------------------
::class "RepSep" subclass "XMLSerializer"


::method serialize class
    use strict arg repsep, xmlizer
    if repsep~childs~isEmpty then do
        -- Concise representation
        xmlizer~stream~lineout("<repsep" || self~attributes(repsep) || ">" || repsep~text || "</repsep>")
        return .true
    end
    else return self~serialize:super(repsep, xmlizer)


::method opentag class
    use strict arg group, xmlizer
    xmlizer~stream~lineout("<repsep" || self~attributes(group) || ">")
    
    
::method closetag class
    use strict arg group, xmlizer
    xmlizer~stream~lineout("</repsep>")
    

-------------------------------------------------------------------------------
::class "FragRef" subclass "XMLSerializer"


::method serialize class
    use strict arg fragref, xmlizer
    xmlizer~stream~lineout("<fragref" || self~attributes(fragref) || ">" || fragref~text || "</fragref>")
    return .true


-------------------------------------------------------------------------------
::class "Fragment" subclass "XMLSerializer"


::method opentag class
    use strict arg fragment, xmlizer
    xmlizer~stream~lineout("<fragment" || self~attributes(fragment) || ">")
    xmlizer~stream~indent
        if fragment~title <> "" then xmlizer~stream~lineout("<title>"fragment~title"</title>")
    xmlizer~stream~dedent
    
    
::method closetag class
    use strict arg fragment, xmlizer
    xmlizer~stream~lineout("</fragment>")
    

-------------------------------------------------------------------------------
::class "Kwd" subclass "XMLSerializer"


::method serialize class
    use strict arg kwd, xmlizer
    xmlizer~stream~lineout("<kwd" || self~attributes(kwd) || ">" || kwd~text || "</kwd>")
    return .true


-------------------------------------------------------------------------------
::class "Var" subclass "XMLSerializer"


::method serialize class
    use strict arg var, xmlizer
    xmlizer~stream~lineout("<var" || self~attributes(var) || ">" || var~text || "</var>")
    return .true


-------------------------------------------------------------------------------
::class "Characters" subclass "XMLSerializer"


::method serialize class
    use strict arg characters, xmlizer
    xmlizer~stream~lineout("<"characters~kindString || self~attributes(characters) || ">" || self~xlatetext(characters~text) || "</" || characters~kindString || ">")
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

