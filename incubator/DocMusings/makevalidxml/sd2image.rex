/**** 
Usage :
    $sourcename [-help] <sd_File> [<logFile>]
Description :
    Create a subdirectory <sd_File> (without suffix) and generate an image file 
    for each syntax diagram or fragment in <sd_File>.
Prerequisites :
    Depends on xsltproc. 
    Assumes that the XSLT script to generate SVG is located in the directory
    ../railroad/syntaxdiagram2svg (path relative to current script directory).
    Depends on the environment variable BATIK_ROOT to retrieve Batik.
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

sdFile = qualify(arguments~sdFile)

if \SysFileExists(sdFile) then do
    log~lineout("[error] <sd_File> not found")
    return 1
end

sdFileDir = filespec("location", sdFile)
sdFileNameExt = filespec("name", sdFile)
sdFileExt = filespec("extension", sdFile)
sdFileName = sdFileNameExt~left(sdFileNameExt~length - sdFileExt~length - 1)

-- Each sd_File has its own subdirectory : 
-- mydir/sd_myfile.xml --> mydir/sd_myfile/
outputDir = sdFileDir || sdFileName
if createDirectoryVerbose(outputDir, log) < 0 then return 1

-- For the time being, the path to syntaxdiagram2svg is derived from the current script path,
-- assuming it is located in the ../railroad/syntaxdiagram2svg directory
-- (incubator directories)
meDir = filespec("location", me)
if meDir~right(1)~matchChar(1, "/\") then meDir = meDir~left(meDir~length - 1)
meUpperDir = filespec("location", meDir)
syntaxdiagram2svg = qualify(meUpperDir || "railroad/syntaxdiagram2svg")

if \SysFileExists(syntaxdiagram2svg"/transform.xsl") then do
    log~lineout("[error] XSLT script for SVG generation not found")
    return 1
end

csspath = qualify(syntaxdiagram2svg"/css")
jspath = qualify(syntaxdiagram2svg"/js")
xsltscript = qualify(syntaxdiagram2svg"/transform.xsl")
xsltproc_log = qualify(outputDir"/_xsltproc.log")

-- Todo : test under Linux, is file:/// supported ?
-- Something sure : I need it under Windows, otherwise absolute path not supported
'xsltproc --stringparam CSSPATH file:///"'csspath'"',
         '--stringparam JSPATH file:///"'jspath'"',
         '--stringparam OUTPUTDIR file:///"'outputDir'"',
         '"'xsltscript'"',
         '"'sdFile'"',
         '>"'xsltproc_log'" 2>&1'
if RC <> 0 then do
    log~lineout("[error] XSLT script for SVG generation failed")
    return 1
end

BATIK_ROOT = value("BATIK_ROOT",,"ENVIRONMENT")
if BATIK_ROOT == "" then do
    log~lineout("[error] The environment variable BATIK_ROOT has no value")
end

rasterizer = qualify(BATIK_ROOT"/extensions/batik-rasterizer-ext.jar")
allsvg = qualify(outputDir"/*.svg")
batik_log = qualify(outputDir"/_batik.log")

-- SVG to PNG
-- If I surround allsvg by quotes then the wildcard character no longer works.
-- so don't use a path with spaces...
'java -Xmx1024M -jar "'rasterizer'" -onload -m image/png 'allsvg' >"'batik_log'" 2>&1'
if RC <> 0 then do
    log~lineout("[error] Batik's rasterizer for SVG to PNG generation failed")
    return 1
end

-- SVG to PDF (better quality)
-- If I surround allsvg by quotes then the wildcard character no longer works.
-- so don't use a path with spaces...
'java -Xmx1024M -jar "'rasterizer'" -onload -m application/pdf 'allsvg' >"'batik_log'" 2>&1'
if RC <> 0 then do
    log~lineout("[error] Batik's rasterizer for SVG to PDF generation failed")
    return 1
end

return 0

::requires 'string2args.rex'
::requires 'help.rex'
::requires 'directory.rex'

-------------------------------------------------------------------------------
::class Arguments subclass Directory
::attribute args


::method init
    self~errors = .List~new
    self~help = .false
    self~logFile = ""
    self~sdFile = ""
    
    -- Tokenize the arguments, if needed
    use strict arg callType, arguments -- always an array
    select
        when callType == "COMMAND" & arguments~items == 1 then self~args = String2Args(arguments[1])
        when callType == "SUBROUTINE" & arguments~items == 1 & arguments[1]~isA(.array) then self~args = arguments[1]
        otherwise self~args = arguments
    end
    
    -- Use makeArray to have a non-sparse array,
    -- because omitted parameters have no corresponding index,
    -- and we ignore omitted parameters here.
    loop i=1 to self~args~items
        if self~args[i] == "" then self~args~remove(i)
    end
    self~args = self~args~makeArray
    
    if self~args~items == 0 then do
        self~help = .true
        return
    end
    
    -- Process the options
    loop i=1 to self~args~items
        option = self~args[i]
        if option~left(1) <> "-" then leave
        select
            when "-help"~caseLessEquals(option) then do
                self~help = .true
                self~helpOption = option
            end
            otherwise do
                self~errors~append("[error] Unknown option" option)
                return
            end
        end
        -- Return now if help requested
        if self~help then return
    end
    
    -- Process the arguments
    -- sdFile is mandatory
    if i > self~args~items then do
        self~errors~append("[error] <sdFile> is missing")
        return
    end
    self~sdFile = self~args[i]~strip
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
