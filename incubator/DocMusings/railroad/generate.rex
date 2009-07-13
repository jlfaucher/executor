if arg(1) = "svg" then signal svg

-- Generate railroads using Clapham
'java net.hydromatic.clapham.Clapham -d clapham_bnf declarations.bnf'
'java net.hydromatic.clapham.Clapham -d clapham_wsn declarations.wsn'

svg:
-- Generate railroads using com.moldflow.dita.syntaxdiagram2svg
outputdir = "syntaxdiagram2svg_out"
call SysMkDir outputdir
'xsltproc --stringparam CSSPATH "../syntaxdiagram2svg/css"',
         '--stringparam JSPATH "../syntaxdiagram2svg/js"',
         '--stringparam OUTPUTDIR "'outputdir'"',
         '"syntaxdiagram2svg/transform.xsl"',
         'declarations.xml',
         '>'outputdir'/debug.txt 2>&1'

BATIK_ROOT = value("BATIK_ROOT",,"ENVIRONMENT")
'java -Xmx1024M -jar "'BATIK_ROOT'/extensions/batik-rasterizer-ext.jar" -onload 'outputdir'/*.svg'

