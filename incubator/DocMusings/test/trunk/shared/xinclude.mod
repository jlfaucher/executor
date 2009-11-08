<!-- 

DTD customization for XIncludes
See http://www.sagehill.net/docbookxsl/ValidXinclude.html#XincludeDTD

-->


<!--===========================================================================
Declare the xi:include and xi:fallback elements and their attributes
============================================================================-->

<!ELEMENT xi:include (xi:fallback?) >
<!ATTLIST xi:include
    xmlns:xi   CDATA       #FIXED    "http://www.w3.org/2001/XInclude"
    href       CDATA       #REQUIRED
    xpointer   CDATA       #IMPLIED
    parse      (xml|text)  "xml"
    encoding   CDATA       #IMPLIED >

<!ELEMENT xi:fallback ANY>
<!ATTLIST xi:fallback
    xmlns:xi   CDATA   #FIXED   "http://www.w3.org/2001/XInclude" >

    
<!--===========================================================================
Extend the DocBook DTD to support xi:include at appropriate places
============================================================================-->

<!-- inside bookinfo, chapterinfo, etc. -->      
<!ENTITY % local.info.class "| xi:include">

<!-- Allow an xi:include in place of a chapter -->
<!ENTITY % local.chapter.class "| xi:include">

<!-- Allow an xi:include in place of a section -->
<!ENTITY % local.section.class "| xi:include">

<!-- inside chapter or section elements -->
<!ENTITY % local.divcomponent.mix "| xi:include">

<!-- inside para, programlisting, literallayout, etc. -->   
<!ENTITY % local.para.char.mix "| xi:include">

