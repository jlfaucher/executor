/**** 
Usage :
    $sourcename 
        [-debug] [-dsssl] [-doit] [-dump] [-help] [-syntdiag] [-xslt]
        [-startat <filename>]
        [-reportlinks <linksFile>]
        <inputDirectory> <outputDirectory> [<logFile>]
        
Description :
    This script is intended to work on the files of the ooRexx doc.

    It iterates over the directories and files found in <inputDirectory> and 
    applies transformfile on the *(.sgml|.xml) files, using the options passed
    as parameters. The sgml|xml files are written to <outputDirectory>, with the
    same relative path. 
    transformfile is called only when needed (date comparison).

    The files other than *(.sgml|.xml) are copied if needed (date comparison).

    By default, no action is performed, except listing the actions that would
    be done if the option -doit was specified.

    Options :
    -debug    : Insert additional informations in the ouptut. A part is sent to
                stderr, another part is inserted in the XML output (making it
                non valid).
    -doit     : Perform the actions.
    -dsssl    : Generate DocBook XML compatible with DSSSL (default).
    -dump     : The elements and attributes are dumped without attempting to
                keep the original layout.
    -reportlinks <linksFile> : 
                Create/reset the file <linksFile>, then write in it the links that 
                have several words in their child text. Such links are known to
                bring troubles when they are at the boundary of two pages.
                Note : it's recommended to use a non-existent <outputDirectory>
                to ensure that all the files are processed.
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

say "Working..."
actionCount = 0
call SysFileTree inputDirectory"*", "inputFiles", "FOS"
if inputFiles.0 <> 0 then do
    skip = arguments~startat
    do i=1 to inputFiles.0
        inputFile = inputFiles.i

        -- Files having ".svn" in their path are skipped
        if inputFile~pos(".svn") <> 0 then iterate
        
        if inputFile~pos(inputDirectory) <> 1 then do
            log~lineout("[error] Assert failed : inputFile does not start with <inputDirectory>")
            return 1
        end
        relativeFile = inputFile~substr(inputDirectory~length + 1)
        relativePath = filespec("path", relativeFile)
        filename = filespec("name", relativeFile)

        if skip then if filename <> arguments~startatValue then iterate
        skip = .false
        
        -- if outputFile more recent than inputFile then nothing to do
        inputFileLastUpdate = SysGetFileDateTime(inputFile, "W")
        if inputFileLastUpdate == -1 then do
            log~lineout("[error] Can't get last update time of "inputFile)
            return 1
        end
        outputFile = outputDirectory || relativeFile
        outputFileLastUpdate = SysGetFileDateTime(outputFile, "W")
        if outputFileLastUpdate <> -1, outputFileLastUpdate >>= inputFileLastUpdate then iterate
    
        actionCount += 1
        
        isDocbookFile = ,
            filespec("extension", inputFile)~caseLessEquals("sgml") ,
            | ,
            filespec("extension", inputFile)~caseLessEquals("xml") & \ filespec("name", inputFile)~caseLessMatch(1, "sd_")
        if \ isDocBookFile then do
            if arguments~doit then do
                log~lineout("[info] Copying file "inputFile)
                if createDirectoryVerbose(outputDirectory || relativePath, log) < 0 then return 1
                if SysFileCopy(inputFile, outputFile) <> 0 then do
                    log~lineout("[error] Can't make a copy of "inputFile)
                    return 1
                end
            end
            else log~lineout("[info] Would make a copy of "inputFile)
        end
        else do
            if arguments~doit then do
                log~lineout("[info] Processing file "inputFile)
                if createDirectoryVerbose(outputDirectory || relativePath, log) < 0 then return 1
                call transformfile arguments~debugOption,,
                                   arguments~dssslOption,,
                                   arguments~dumpOption,,
                                   arguments~reportlinksOption, arguments~reportlinksValue,,
                                   arguments~syntdiagOption,,
                                   arguments~xsltOption,,
                                   inputFile,,
                                   outputFile,,
                                   arguments~logFile
                if result <> 0 then do
                    log~lineout("[info] Got an error while processing "inputFile)
                    call SysSetFileDateTime outputFile, "2000-01-01", "00:00:00" -- touch with a low date & time, to force selection at next run
                    return 1
                end
            end
            else log~lineout("[info] Would process file "inputFile)
        end
    end
end

if actionCount == 0 then say "Nothing to do."
else if \arguments~doit then do
    say
    say "Use the option -doit to really execute the actions"
end
else say "Done."

return 0

::requires 'arguments.cls'
::requires 'help.cls'
::requires 'directory.cls'

-------------------------------------------------------------------------------
::class Arguments subclass CommonArguments

::method initEntries
    self~initEntries:super
    self~inputDirectory = ""
    self~logFile = ""
    self~outputDirectory = ""
    self~doit = .false
    self~startat = .false

    
::method parseOption
    use strict arg option
    if "-doit"~caseLessEquals(option) then do 
        self~argIndex += 1
        self~doit = .true
        self~startatOption = option
        return .true
    end
    if "-startat"~caseLessEquals(option) then do 
        self~argIndex += 1
        self~startat = .true
        self~startatOption = option
        value = self~args[self~argIndex]
        if value == .nil then value = ""
        if value == "" | value~left(1) == "-" then do
            self~errors~append("[error] Value expected for option "option)
            return .false
        end
        else do
            self~argIndex += 1
            self~startatValue = value
            return .true
        end
    end
    return self~parseOption:super(option)

    
::method parseArguments
    -- inputDirectory is mandatory
    if self~argIndex > self~args~items then do
        self~errors~append("[error] <inputDirectory> is missing")
        return
    end
    self~inputDirectory = self~args[self~argIndex]~strip
    self~argIndex += 1

    -- outputDirectory is mandatory
    if self~argIndex > self~args~items then do
        self~errors~append("[error] <outputDirectory> is missing")
        return
    end
    self~outputDirectory = self~args[self~argIndex]~strip
    if self~outputDirectory~left(1) == "-" then do
        self~errors~append("[error] Options are before <inputDirectory>")
        return
    end
    self~argIndex += 1

    -- logFile is optional
    if self~argIndex > self~args~items then return
    self~logFile = self~args[self~argIndex]~strip
    if self~logFile~left(1) == "-" then do
        self~errors~append("[error] Options are before <inputDirectory>")
        return
    end
    self~argIndex += 1

    -- no more argument expected
    if self~argIndex > self~args~items then return
    self~errors~append("[error] Unexpected arguments :" self~args~section(self~argIndex)~toString("L", " "))
    return

