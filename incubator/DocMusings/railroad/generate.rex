-- Generate railroads using Clapham
'java net.hydromatic.clapham.Clapham -d clapham_bnf declarations.bnf'
'java net.hydromatic.clapham.Clapham -d clapham_wsn declarations.wsn'

-- Generate railroads using com.moldflow.dita.syntaxdiagram2svg
outputdir = "syntaxdiagram2svg_out"
call SysMkDir outputdir
'xsltproc --stringparam CSSPATH "../syntaxdiagram2svg/css"',
         '--stringparam JSPATH "../syntaxdiagram2svg/js"',
         '--stringparam OUTPUTDIR "'outputdir'"',
         '"syntaxdiagram2svg/transform.xsl"',
         'declarations.xml',
         '>'outputdir'/debug.txt 2>&1'

call SysFileTree outputdir"/*.svg", "svgfiles", "FO"
BATIK_ROOT = value("BATIK_ROOT",,"ENVIRONMENT")
do i=1 to svgfiles.0
    -- of course, launching the Java VM for each image is not the most efficient technique...
    'java -jar "'BATIK_ROOT'/extensions/batik-rasterizer-ext.jar" -onload "'svgfiles.i'"'
end

