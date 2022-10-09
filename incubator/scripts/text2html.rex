/*
Convert a plain text file to HTML.
The first line is a H1 title.
An H2 title is a line preceded and followed by a line of equals signs (at least 10, same length).
===...===
title
===...===
A TOC is created from the H2 titles.
The URLs are converted to hyperlinks.
An URL starts with http:// or https://, ends at the first space or at the end of the line.

KEEP THIS SCRIPT COMPATIBLE WITH OOREXX5
*/

if arg() == 0 then signal help

force = .false
parse_options:
    option = c_arg()
    option = option~lower

         if option == "-f"         then signal option_force
    else if option == "--force"    then signal option_force
    else if option == "-h"         then signal help
    else if option == "--help"     then signal help
    else if option == "--"         then signal option_end_of_options
    else if option~left(1) == "-"  then signal unknown_option
    else signal end_of_options

option_force:
    force = .true
    call shift_c_args -- skip the option
    signal parse_options -- continue parsing

option_end_of_options:
    call shift_c_args -- skip the option
    signal end_of_options

end_of_options:
    inputname = c_arg()
    call shift_c_args
    outputname = c_arg()
    call shift_c_args
    rest = remaining_c_args()
    if rest \== "" then signal unexpected_arguments
    if inputname == "" then inputname = "stdin"
    if outputname == "" then outputname = "stdout"
    inputobject = .stream~new(inputname)
    status = inputobject~open("READ")
    if status \== "READY:" then signal cannot_open_inputname
    outputobject = .stream~new(outputname)
    if force == .false, outputobject~query("EXISTS") \== "" then signal outputname_exists
    status = outputobject~open("WRITE REPLACE")
    if status \== "READY:" then signal cannot_open_outputname
    call transform inputname, inputobject, outputobject
    exit 0

cannot_open_inputname:
    .error~say("Can't open" inputname)
    .error~say(status)
    exit -1

cannot_open_outputname:
    .error~say("Can't open" outputname)
    .error~say(status)
    exit -1

outputname_exists:
    .error~say(outputname "exists, use -f to force overwriting")
    exit -1

unknown_option:
    .error~say("Unknown option" option)
    signal usage

unexpected_arguments:
    .error~say("Unexpected arguments:" rest)
    signal usage

help:
    .error~say("Description:")
    .error~say("    Convert a plain text file to HTML.")
    .error~say("    The URLs are converted to hyperlinks.")
    .error~say("    An URL starts with http:// or https://, ends at the first space or at the end of the line.")
    signal usage

usage:
    parse source . . script
    scriptname = .file~new(script)~name
    dotpos = scriptname~lastpos(".")
    if dotpos \== 0 then scriptname = scriptname~left(dotpos - 1)
    .error~say("Usage:")
    .error~say("    "scriptname" [-h | --help] [-f | --force] [--] [inputname [outputname]]")
    .error~say("    where")
    .error~say("        -f --force  force overwriting if outputname already exists")
    .error~say("        -h --help   display help")
    .error~say("        --          indicate the end of options")
    .error~say("        inputname default value is stdin")
    .error~say("        outputname default value is stdout")
    exit -1


-------------------------------------------------------------------------------
-- Transformation from text to HTML

::routine transform
    use strict arg inputname, inputobject, outputobject

    toc = .list~new
    contents = .list~new

    lineNumber = 0
    previousPreviousLine = ""
    previousLine = ""
    line = ""
    titleState = 0 -- if a line L1 contains only "=" then the next line L2 is a title if the line L3 after contains only "=" and have same length as L1

    signal on notready
    do while inputobject~state == "READY"
        lineNumber += 1
        previousPreviousLine = previousLine
        previousLine = line
        line = inputobject~linein
        line = transformLine(line)
        if lineNumber == 1, isValidTitle(line) then do
            -- the first line, when not empty, is the H1 title
            title = titleHTML(line, 1) -- <h1>
            toc~append(title)
            toc~append("")
            toc~append("Contents:")
        end
        else if titleState == 2 then do
            titleState = 0
            if isTitleSeparator(line, previousPreviousLine~length) then do
                -- good, we have a well-formed title
                titleLink = linkHTML(previousLine)
                toc~append("    " || titleLink)
                title = titleHTML(previousLine, 2) -- <h2>
                contents~append(title)
            end
            else do
                -- not a well-formed title
                contents~append(previousPreviousLine)
                contents~append(previousLine)
                contents~append(line)
            end
        end
        else if titleState == 1 then do
            if isTitleSeparator(line) then do
                -- not a well-formed title: this line should be the title, but it is a title separator
                contents~append(previousLine)
                -- stay in state 1, assume that the current line is a title start
            end
            else if isValidTitle(line) then do
                -- good candidate line for a title
                titleState = 2
            end
            else do
                -- not a well-formed title
                contents~append(previousLine)
                contents~append(line)
                titleState = 0
            end
        end
        else if isTitleSeparator(line) then do
            -- first title separator met
            titleState = 1
        end
        else contents~append(line)
    end
    notready:

    -- flush buffered lines for title, if any
    if titleState == 1 then contents~append(previousLine)
    else if titleState == 2 then do
        contents~append(previousPreviousLine)
        contents~append(previousLine)
    end

    call openHTML inputname, outputobject
    call outputLinesHTML toc, outputobject
    call outputLinesHTML contents, outputobject
    call closeHTML outputobject

    return


::routine transformLine
    use strict arg line
    buffer = .mutableBuffer~new
    pos = 1
    do while pos <= line~length
        startURL = line~caselessPos("http://", pos)
        if startURL == 0 then startURL = line~caselessPos("https://", pos)
        if startURL == 0 then leave

        -- We found an URL

        -- copy text before the URL
        before = line~substr(pos, startURL - pos)
        before = escapeEntitiesHTML(before)
        buffer~append(before)

        -- Search the end of the URL
        -- For the moment, just search fo a space or EOL.
        -- But in theory, should be more strict:
        -- https://stackoverflow.com/questions/1547899/which-characters-make-a-url-invalid
        -- ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=
        -- Any other character needs to be encoded with the percent-encoding (%hh)
        pos = line~pos(" ", startURL)
        if pos == 0 then pos = line~length + 1

        -- Make the URL clickable
        URL = line~substr(startURL, pos - startURL)
        call anchorHTML URL, buffer
    end
    if pos == 1 then rest = line -- no transformation
                else rest = line~substr(pos)
    rest = escapeEntitiesHTML(rest)
    return buffer~string || rest


::routine linkHtml
    use strict arg string
    id = identifier(string)
    return '<a href="#' || id || '">' || string || '</a>'


::routine titleHTML
    use strict arg string, level
    id = identifier(string)
    return '<hr><h' || level || ' id="' || id || '">' || string || '</h' || level || '><hr>'


::routine anchorHTML
    use strict arg URL, buffer
    -- Force to open in new tab
    -- https://stackoverflow.com/questions/15551779/open-link-in-new-tab-or-window
    buffer~append('<a target="_blank" rel="noopener noreferrer" href="' || URL || '">' || URL || '</a>')


::routine escapeEntitiesHTML
    use strict arg line
    line = line~changeStr("&", "&amp;")
    line = line~changeStr("<", "&lt;")
    line = line~changeStr(">", "&gt;")
    return line


::routine openHTML
    use strict arg inputname, outputobject
    outputobject~lineout('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"')
    outputobject~lineout('                      "http://www.w3.org/TR/html4/loose.dtd">')
    outputobject~lineout('<html>')
    outputobject~lineout('<head>')
    outputobject~lineout('    <title>'inputname'</title>')
    outputobject~lineout('</head>')
    outputobject~lineout('<body>')
    outputobject~lineout('<pre>')


::routine outputLinesHTML
    use strict arg collection, outputobject
    supplier = collection~supplier
    do while supplier~available
        line = supplier~item
        outputobject~charout(line) -- no linefeed by default
        if line~right(4) \== "<hr>" then outputobject~lineout("") -- linefeed except if ends with <hr>
        supplier~next
    end


::routine closeHTML
    use strict arg outputobject
    outputobject~lineout('</pre>')
    outputobject~lineout('</body>')
    outputobject~lineout('</html>')


::routine identifier
    use strict arg string
    buffer = .mutableBuffer~new("", string~length)
    subst = "_"
    do i = 1 to string~length
        c = string~subchar(i)
        if c < "0"       then buffer~append(subst)
        else if c <= "9" then buffer~append(c)
        else if c < "A"  then buffer~append(subst)
        else if c <= "Z" then buffer~append(c)
        else if c < "a"  then buffer~append(subst)
        else if c <= "z" then buffer~append(c)
        else buffer~append(subst)
    end
    return buffer~string


::routine isTitleSeparator
    use strict arg line, length=(-1)
    if line~length < 10 then return .false -- at least 10 "=" needed
    if length \== -1 then do
        -- 2nd title separator must have same length as 1st title separator
        if line~length \== length then return .false
    end
    return line~verify("=") == 0 -- true if line contains only "="


::routine isValidTitle
    use strict arg line
    -- valid if line contains at least a digit or a letter
    return line~verify("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", "MATCH") \== 0


-------------------------------------------------------------------------------
-- Helpers to manipulate the C arguments

::routine c_arg
    if .nil == .syscargs[1] then return ""
    return .syscargs[1]


::routine shift_c_args
    .syscargs~delete(1)
    return


::routine remaining_c_args
    return .syscargs~toString("line", " ") -- concatenate all the remaining C arguments, separated by a space character.
