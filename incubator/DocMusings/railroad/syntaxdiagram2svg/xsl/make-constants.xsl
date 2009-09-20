<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Need different values, depending on the image format that will be
generated from the SVG :
- add "TARGET_FORMAT" parameter
- test it where appropriate
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

    <xsl:output method="text"/>
    <xsl:param name="TARGET_FORMAT" select="''"/>
    
    <xsl:template match="/">
        <xsl:text>
            function syntaxdiagram_Constants() { }
            var syntaxdiagram_Dispatch = new Array;
        </xsl:text>
        <xsl:apply-templates></xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="scalar">
        <xsl:if test="not(@target_format) or @target_format=$TARGET_FORMAT">
            <xsl:text>syntaxdiagram_Constants.</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>=</xsl:text>
            <xsl:apply-templates></xsl:apply-templates>
            <xsl:text>;&#x0a;</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="string">
        <xsl:if test="not(@target_format) or @target_format=$TARGET_FORMAT">
            <xsl:text>syntaxdiagram_Constants.</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>="</xsl:text>
            <xsl:apply-templates></xsl:apply-templates>
            <xsl:text>";&#x0a;</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="array">
        <xsl:text>syntaxdiagram_Constants.</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>= new Array;</xsl:text>
        <xsl:apply-templates></xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="array/scalar">
        <xsl:text>syntaxdiagram_Constants.</xsl:text>
        <xsl:value-of select="../@name"/>
        <xsl:text>["</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>"] =</xsl:text>
        <xsl:apply-templates></xsl:apply-templates>
        <xsl:text>;&#x0a;</xsl:text>
    </xsl:template>
</xsl:stylesheet>
