/*
Convert a plain text file to HTML.
The URLs are converted to hyperlinks.
An URL starts with http:// or https://, ends at the first space or at the end of the line.
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
    call openHTML inputname, outputobject
    signal on notready
    do while inputobject~state == "READY"
        line = inputobject~linein
        line = transformLine(line)
        outputobject~lineout(line)
    end
    notready:
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
        buffer~append(line~substr(pos, startURL - pos)) -- copy text before the URL
        -- Search the end of the URL
        -- For the moment, just search fo a space or EOL.
        -- But in theory, should be more strict:
        -- https://stackoverflow.com/questions/1547899/which-characters-make-a-url-invalid
        -- ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=
        -- Any other character needs to be encoded with the percent-encoding (%hh)
        pos = line~pos(" ", startURL)
        if pos == 0 then pos = line~length + 1
        URL = line~substr(startURL, pos - startURL)
        call anchorHTML URL, buffer
    end
    if pos == 1 then return line -- no transformation
    return buffer~string || line~substr(pos)


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


::routine closeHTML
    use strict arg outputobject
    outputobject~lineout('</pre>')
    outputobject~lineout('</body>')
    outputobject~lineout('</html>')


::routine anchorHTML
    use strict arg URL, buffer
    -- Force to open in new tab
    -- https://stackoverflow.com/questions/15551779/open-link-in-new-tab-or-window
    buffer~append('<a target="_blank" rel="noopener noreferrer" href="'URL'">'URL'</a>')


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
