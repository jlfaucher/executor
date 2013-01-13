/**** 
Usage :
    $sourcename [-help] <sd_File> [<logFile>]
Description :
    Create a subdirectory <sd_File> (without suffix) and generate an image file 
    for each syntax diagram or fragment in <sd_File>.
    Generated formats : SVG, PNG, PDF.
Prerequisites :
    Assumes that the syntaxdiagram2svg addin is located in the directory
    ../railroad/syntaxdiagram2svg (path relative to current script directory).
    Depends on xsltproc. 
    Depends on the environment variable BATIK_RASTERIZER_JAR.
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

----------------
-- Prerequisites
----------------

error = .false
BATIK_RASTERIZER_JAR = value("BATIK_RASTERIZER_JAR",,"ENVIRONMENT")
if BATIK_RASTERIZER_JAR == "" then do
    log~lineout("[error] The environment variable BATIK_RASTERIZER_JAR is not defined")
    error = .true
end
if error then return 1

------------------
-- DITA XML to SVG
------------------

-- For the time being, the path to syntaxdiagram2svg is derived from the current script path,
-- assuming it is located in the ../railroad/syntaxdiagram2svg directory
-- (incubator directories)
meDir = filespec("location", me)
if meDir~right(1)~matchChar(1, "/\") then meDir = meDir~left(meDir~length - 1)
meUpperDir = filespec("location", meDir)
syntaxdiagram2svg = meUpperDir || "railroad/syntaxdiagram2svg"

csspath = (syntaxdiagram2svg"/css")
jspath = (syntaxdiagram2svg"/js")
syntaxdiagram2svg_xsltscript = syntaxdiagram2svg"/transform.xsl"
syntaxdiagram2svg_log = outputDir"/_syntaxdiagram2svg.log"

-- Todo : test under Linux, is file:/// supported ? --> yes
-- Something sure : I need it under Windows, otherwise absolute path not supported
'xsltproc --stringparam CSSPATH "file:///'csspath'"',
         '--stringparam JSPATH "file:///'jspath'"',
         '--stringparam OUTPUTDIR "file:///'outputDir'"',
         '"'syntaxdiagram2svg_xsltscript'"',
         '"'sdFile'"',
         '>"'syntaxdiagram2svg_log'" 2>&1'
if RC <> 0 then do
    log~lineout("[error] XSLT script for SVG generation failed")
    return 1
end

-----------------
-- SVG rasterizer
-----------------

constants_xml = syntaxdiagram2svg"/resource/constants.xml"
constants_js = syntaxdiagram2svg"/js/constants.js" -- this file is generated from constants.xml, included by each SVG file, and read on load
make_constants_xsltscript = syntaxdiagram2svg"/xsl/make-constants.xsl"
make_constants_log = outputDir"/_make_constants.log"
allsvg = outputDir"/*.svg"
batik_log = outputDir"/_batik.log"

--------------------------
-- SVG rasterizer : to PNG
--------------------------

'xsltproc --stringparam TARGET_FORMAT PNG',
         '--output "'constants_js'"',
         '"'make_constants_xsltscript'"',
         '"'constants_xml'"',
         '>"'make_constants_log'" 2>&1'
if RC <> 0 then do
    log~lineout("[error] XSLT script for generation of PNG constants failed")
    return 1
end

-- If I surround allsvg by quotes then the wildcard character no longer works.
-- so don't use a path with spaces...
'java -jar "'BATIK_RASTERIZER_JAR'" -onload -m image/png -cssMedia screen 'allsvg' >"'batik_log'" 2>&1'
if RC <> 0 then do
    log~lineout("[error] Batik's rasterizer failed when converting to PNG")
    return 1
end

-------------------------------------------
-- SVG rasterizer : to PDF (better quality)
-------------------------------------------

'xsltproc --stringparam TARGET_FORMAT PDF',
         '--output "'constants_js'"',
         '"'make_constants_xsltscript'"',
         '"'constants_xml'"',
         '>"'make_constants_log'" 2>&1'
if RC <> 0 then do
    log~lineout("[error] XSLT script for generation of PNG constants failed")
    return 1
end

-- If I surround allsvg by quotes then the wildcard character no longer works.
-- so don't use a path with spaces...
'java -jar "'BATIK_RASTERIZER_JAR'" -onload -m application/pdf -cssMedia print 'allsvg' >"'batik_log'" 2>&1'
if RC <> 0 then do
    log~lineout("[error] Batik's rasterizer failed when converting to PDF")
    return 1
end

return 0

::requires 'string2args.cls'
::requires 'help.cls'
::requires 'directory.cls'

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
