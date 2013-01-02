/****************************************************************************/
/* Section: Getting/Setting Fonts option Info                               */
/****************************************************************************/
/* Default font Name and Size */
static GtString API_GetDefaultFontFace_()
{      
 return DefDefaultFontFace();
}

GtCStringA  TOOL_PUBLIC API_GetDefaultFontFaceA()
{
#ifdef TOOL_UNICODE
    GtCStringW resultW = API_GetDefaultFontFace_();

    GtCStringA resultA;
    GtBool done = HGTW2A(resultW, &resultA);
    if (done == GtTrue)
    {
        return resultA;
    }

    return NULL;
#else
    return API_GetDefaultFontFace_();
#endif
}

#ifdef TOOL_UNICODE
GtCStringW  TOOL_PUBLIC API_GetDefaultFontFaceW()
{
    return API_GetDefaultFontFace_();
}
#endif

gtint32 TOOL_PUBLIC API_GetDefaultFontSize()
{   
    return DefDefaultFontSize();
}

static void API_SetDefaultFontFace_(GtCString face_name)
{ 
   SetDefDefaultFontFace((UNJUSTIFIED GtString)face_name); 
}

void TOOL_PUBLIC API_SetDefaultFontFaceA(GtCStringA face_nameA)
{
#ifdef TOOL_UNICODE
    GtStringW face_nameW;
    GtBool done = GTA2W(face_nameA, &face_nameW);

    if (done == GtTrue) API_SetDefaultFontFace_(face_nameW);

    FreeMem(face_nameW, 0);
#else
    API_SetDefaultFontFace_(face_nameA);
#endif
}

#ifdef TOOL_UNICODE
void TOOL_PUBLIC API_SetDefaultFontFaceW(GtCStringW face_nameW)
{
    API_SetDefaultFontFace_(face_nameW);
}
#endif

void TOOL_PUBLIC API_SetDefaultFontSize(gtint32 size)
{ 
   SetDefDefaultFontSize(size);
}

/* Reporter font Name and Size */
static GtString API_GetDefaultReportFontFace_()
{      
 return DefReportFontFace();
}

GtCStringA  TOOL_PUBLIC API_GetDefaultReportFontFaceA()
{
#ifdef TOOL_UNICODE
    GtStringW resultW = API_GetDefaultReportFontFace_();

    GtCStringA resultA;
    GtBool done = HGTW2A(resultW, &resultA);
    if (done == GtTrue)
    {
        return resultA;
    }

    return NULL;
#else
    return API_GetDefaultReportFontFace_();
#endif
}

#ifdef TOOL_UNICODE
GtCStringW  TOOL_PUBLIC API_GetDefaultReportFontFaceW()
{
    return API_GetDefaultReportFontFace_();
}
#endif

gtint32 TOOL_PUBLIC API_GetDefaultReportFontSize()
{   
    return DefReportFontSize();
}

static void API_SetDefaultReportFontFace_(GtCString face_name)
{ 
   SetDefReportFontFace((UNJUSTIFIED GtString)face_name); 
}

void TOOL_PUBLIC API_SetDefaultReportFontFaceA(GtCStringA face_nameA)
{
#ifdef TOOL_UNICODE
    GtStringW face_nameW;
    GtBool done = GTA2W(face_nameA, &face_nameW);

    if (done == GtTrue) API_SetDefaultReportFontFace_(face_nameW);

    FreeMem(face_nameW, 0);
#else
    API_SetDefaultReportFontFace_(face_nameA);
#endif
}

#ifdef TOOL_UNICODE
void TOOL_PUBLIC API_SetDefaultReportFontFaceW(GtCStringW face_nameW)
{
    API_SetDefaultReportFontFace_(face_nameW);
}
#endif

void TOOL_PUBLIC API_SetDefaultReportFontSize(gtint32 size)
{ 
   SetDefReportFontSize(size);
}

/* Reporter Title font Name and Size */
static GtString API_GetDefaultReportTitleFontFace_()
{      
 return DefReportTitleFontFace();
}

GtCStringA  TOOL_PUBLIC API_GetDefaultReportTitleFontFaceA()
{
#ifdef TOOL_UNICODE
    GtCStringW resultW = API_GetDefaultReportTitleFontFace_();

    GtCStringA resultA;
    GtBool done = HGTW2A(resultW, &resultA);
    if (done == GtTrue)
    {
        return resultA;
    }
    return NULL;
#else
    return API_GetDefaultReportTitleFontFace_();
#endif
}

#ifdef TOOL_UNICODE
GtCStringW  TOOL_PUBLIC API_GetDefaultReportTitleFontFaceW()
{
    return API_GetDefaultReportTitleFontFace_();
}
#endif

gtint32 TOOL_PUBLIC API_GetDefaultReportTitleFontSize()
{   
    return DefReportTitleFontSize();
}

static void API_SetDefaultReportTitleFontFace_(GtCString face_name)
{ 
   SetDefReportTitleFontFace((UNJUSTIFIED GtString)face_name); 
}

void TOOL_PUBLIC API_SetDefaultReportTitleFontFaceA(GtCStringA face_nameA)
{
#ifdef TOOL_UNICODE
    GtStringW face_nameW;
    GtBool done = GTA2W(face_nameA, &face_nameW);

    if (done == GtTrue) API_SetDefaultReportTitleFontFace_(face_nameW);

    FreeMem(face_nameW, 0);
#else
    API_SetDefaultReportTitleFontFace_(face_nameA);
#endif
}

#ifdef TOOL_UNICODE
void TOOL_PUBLIC API_SetDefaultReportTitleFontFaceW(GtCStringW face_nameW)
{
    API_SetDefaultReportTitleFontFace_(face_nameW);
}
#endif

void TOOL_PUBLIC API_SetDefaultReportTitleFontSize(gtint32 size)
{ 
   SetDefReportTitleFontSize(size);
}

