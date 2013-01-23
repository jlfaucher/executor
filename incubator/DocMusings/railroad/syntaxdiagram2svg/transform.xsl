<?xml version="1.0" ?>

<!-- 
JLF : Entry point to call the service which creates the railroads.
Iterate over the <syntaxdiagram> and <fragment>, and create one SVG file 
for each, provided they have a title :
- the filename of the syntax diagram is given by its title.
- the filename of the fragment is the concatenation of the syntax diagram's
  title and its own title. If the enclosing syntax diagram has no title,
  then the fragment's title is used alone.
So, these three cases are supported :
<syntaxdiagrams>
    <syntaxdiagram>
        <title>syntax diagram</title>                   ==> "syntax diagram.svg"
        <fragment>
            <title>fragment</title>                     ==> "syntax diagram-fragment.svg"
        </fragment>
    </syntaxdiagram>
    <syntaxdiagram>                                     ==> no SVG file (no title)
        <fragment>
            <title>full qualified fragment</title>      ==> "full qualified fragment.svg"
        </fragment>
    </syntaxdiagram>
</syntaxdiagrams>

Note : the top-level <syntaxdiagrams> element is not part of any standard.
I use it because an XML file must have only one root element.
-->

<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:syntaxdiagram2svg="http://www.moldflow.com/namespace/2008/syntaxdiagram2svg"
    xmlns:helper="http://www.oorexx.org/helper"
    xmlns:exsl="http://exslt.org/common"
    xmlns:func="http://exslt.org/functions"
    extension-element-prefixes="exsl func"
version="1.0"
>

<xsl:import href="xsl/syntaxdiagram2svg.xsl"/>

<xsl:output method="xml" encoding="utf-8"/>

<xsl:param name="BASEPATH" select="''"/>
<xsl:param name="CSSPATH" select="'css'"/>
<xsl:param name="JSPATH" select="'js'"/>
<xsl:param name="OUTPUTDIR" select="'.'"/>

<xsl:variable name="SUFFIX" select="'.svg'"/>

<xsl:template match="/syntaxdiagrams/syntaxdiagram">
    <xsl:variable name="diagram_title" select="normalize-space(title)"/>
    <xsl:if test="$diagram_title">
        <xsl:for-each select="*[1]"> <!-- The entry point is always the first child of the diagram -->
            <xsl:variable name="filename" select="concat(helper:end_separator($OUTPUTDIR), $diagram_title, $SUFFIX)"/>
            <xsl:message>Generating diagram <xsl:value-of select="$filename"/></xsl:message>
            <exsl:document href="{$filename}">
                <xsl:call-template name="syntaxdiagram2svg:create-svg-document">
                    <xsl:with-param name="CSSPATH" select="helper:end_separator($CSSPATH)"/>
                    <xsl:with-param name="JSPATH" select="helper:end_separator($JSPATH)"/>
                    <xsl:with-param name="BASEPATH" select="helper:end_separator($BASEPATH)"/>
                </xsl:call-template>
            </exsl:document>
        </xsl:for-each>
    </xsl:if>
    <!-- Now process the fragments of the current diagram, if any -->
    <xsl:for-each select=".//fragment">
        <xsl:variable name="fragment_title" select="normalize-space(title)"/>
        <xsl:if test="$fragment_title" >
            <xsl:for-each select="*[1]"> <!-- The entry point is always the first child of the fragment -->
                <xsl:variable name="qualifiedName" select="helper:concat2sep($diagram_title, '-', $fragment_title)"/>
                <xsl:variable name="filename" select="concat(helper:end_separator($OUTPUTDIR), $qualifiedName, $SUFFIX)"/>
                <xsl:message>Generating fragment <xsl:value-of select="$filename"/></xsl:message>
                <exsl:document href="{$filename}">
                    <xsl:call-template name="syntaxdiagram2svg:create-svg-document">
                        <xsl:with-param name="CSSPATH" select="helper:end_separator($CSSPATH)"/>
                        <xsl:with-param name="JSPATH" select="helper:end_separator($JSPATH)"/>
                        <xsl:with-param name="BASEPATH" select="helper:end_separator($BASEPATH)"/>
                    </xsl:call-template>
                </exsl:document>
            </xsl:for-each>
        </xsl:if>
    </xsl:for-each>
</xsl:template>


<!-- Catch-all rule, to not send text and cdata to stdout -->
<xsl:template match="text()">
</xsl:template>


<!-- Add a final separator, if path not empty and don't have already one. -->
<func:function name="helper:end_separator">
    <xsl:param name="path"/>
    <xsl:param name="separator" select="'/'"/>

    <xsl:variable name="normalized_path" select="normalize-space($path)"/>
    <xsl:choose>
        <xsl:when test="not($normalized_path)">
            <func:result select="$normalized_path"/>
        </xsl:when>
        <xsl:when test="substring($normalized_path, string-length($normalized_path), 1) = $separator">
            <func:result select="$normalized_path"/>
        </xsl:when>
        <xsl:otherwise>
            <func:result select="concat($normalized_path, $separator)"/>
        </xsl:otherwise>
    </xsl:choose>
</func:function>


<!-- Concatenate two strings, inserting a separator between each string if necessary -->
<func:function name="helper:concat2sep">
    <xsl:param name="string1"/>
    <xsl:param name="separator"/>
    <xsl:param name="string2"/>

    <xsl:choose>
        <xsl:when test="$string1 and $string2">
            <func:result select="concat($string1, $separator, $string2)"/>
        </xsl:when>
        <xsl:when test="$string1">
            <func:result select="$string1"/>
        </xsl:when>
        <xsl:when test="$string2">
            <func:result select="$string2"/>
        </xsl:when>
        <xsl:otherwise>
            <func:result select="''"/>
        </xsl:otherwise>
    </xsl:choose>
</func:function>

</xsl:stylesheet>

