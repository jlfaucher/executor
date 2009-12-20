/**** 
Usage :
    $sourcename 
        [-debug] [-dsssl] [-dump] [-help] [-syntdiag] [-xslt]
        [-startat <filename>]
        <inputDirectory> <outputDirectory> [<logFile>]
Description :
    This script is intended to work on the XML files of the ooRexx doc.
    It iterates over the directories and files found in <inputDirectory> and 
    applies transformfile on the *.sgml files, using the options passed
    as parameters. The sgml files are written to <outputDirectory>, with the
    same relative path.
    By default, there is no transformation.
    Options :
    -debug    : Insert additional informations in the ouptut. A part is sent to
                stderr, another part is inserted in the XML output (making it
                non valid).
    -dsssl    : Generate DocBook XML compatible with DSSSL.
    -dump     : The elements and attributes are dumped without attempting to
                keep the original layout.
    -startat  : Lets start the iteration at <filename>. Useful when you have
                to bypass errors in the XML files and restart the iteration.
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
    log~open("write replace")
    log~open("write append shared nobuffer")
end

-- Beware ! qualify has not the same behaviour under Windows and under Linux :
-- Under Windows, the final slash is not removed
-- Under Linux, the final slash is removed
-- That's why the final "/" is outside the call to qualify
inputDirectory = qualify(arguments~inputDirectory)"/"
outputDirectory = qualify(arguments~outputDirectory)"/"

if inputDirectory == outputDirectory then do
    log~lineout("[error] <outputDirectory> must be different from <inputDirectory>")
    return 1
end

if \SysFileExists(inputDirectory) then do
    log~lineout("[error] <inputDirectory> not found")
    return 1
end

call SysFileTree inputDirectory"*.sgml", "files", "FOS"
if files.0 <> 0 then do
    skip = arguments~startat
    do i=1 to files.0
        fullpath = files.i
        if fullpath~pos(inputDirectory) <> 1 then do
            log~lineout("[error] Assert failed : fullpath does not start with <inputDirectory>")
            return 1
        end
        relativepath = fullpath~substr(inputDirectory~length + 1)
        filepath = filespec("path", relativepath)
        filename = filespec("name", relativepath)

        if skip then if filename <> arguments~startatValue then iterate
        skip = .false
        
        log~lineout("[info] Processing file "fullpath)
        if createDirectoryVerbose(outputDirectory || filepath, log) < 0 then return 1
        call transformfile arguments~debugOption,,
                           arguments~dssslOption,,
                           arguments~dumpOption,,
                           arguments~syntdiagOption,,
                           arguments~xsltOption,,
                           fullpath,,
                           outputDirectory || relativepath,,
                           arguments~logFile
        if result <> 0 then do
            log~lineout("[error] Got an error while processing "fullpath)
            return 1
        end
    end
end

return 0

::requires 'arguments.cls'
::requires 'help.rex'
::requires 'directory.rex'

-------------------------------------------------------------------------------
::class Arguments subclass CommonArguments

::method init
    use strict arg callType, arguments -- always an array
    self~init:super(callType, arguments)
    -- Return now if help requested
    if self~help then return
    
    self~inputDirectory = ""
    self~logFile = ""
    self~outputDirectory = ""
    self~startat = .false
    
    -- Process the options
    loop i=1 to self~args~items
        option = self~args[i]
        if option~left(1) <> "-" then leave
        select
            when self~parseOption(option) then nop
            when "-startat"~caseLessEquals(option) then do 
                value = self~args[i+1]
                if value == "" | value~left(1) == "-" then do
                    self~errors~append("[error] Value expected for option "option)
                end
                self~startat = .true
                self~startatOption = option
                self~startatValue = value
                i += 1
            end
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
    -- inputDirectory is mandatory
    if i > self~args~items then do
        self~errors~append("[error] <inputDirectory> is missing")
        return
    end
    self~inputDirectory = self~args[i]~strip
    i += 1

    -- outputDirectory is mandatory
    if i > self~args~items then do
        self~errors~append("[error] <outputDirectory> is missing")
        return
    end
    self~outputDirectory = self~args[i]~strip
    if self~outputDirectory~left(1) == "-" then do
        self~errors~append("[error] Options are before <inputFilename>")
        return
    end
    i += 1

    -- logFile is optional
    if i > self~args~items then return
    self~logFile = self~args[i]~strip
    if self~logFile~left(1) == "-" then do
        self~errors~append("[error] Options are before <inputFilename>")
        return
    end
    i += 1

    -- no more argument expected
    if i > self~args~items then return
    self~errors~append("[error] Unexpected arguments :" self~args~section(i)~toString("L", " "))
    return
