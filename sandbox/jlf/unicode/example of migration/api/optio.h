TOOL_START_EXTERN_C

/****************************************************************************/
/* Section: Getting/Setting Fonts option Info                               */
/****************************************************************************/
extern GtCStringA  TOOL_PUBLIC API_GetDefaultFontFaceA();
extern GtCStringW  TOOL_PUBLIC API_GetDefaultFontFaceW();
#ifdef TOOL_WIDE_API
#define API_GetDefaultFontFace API_GetDefaultFontFaceW
#else
#define API_GetDefaultFontFace API_GetDefaultFontFaceA
#endif

extern gtint32 TOOL_PUBLIC API_GetDefaultFontSize();

extern void TOOL_PUBLIC API_SetDefaultFontFaceA(GtCStringA face_nameA);
extern void TOOL_PUBLIC API_SetDefaultFontFaceW(GtCStringW face_nameW);
#ifdef TOOL_WIDE_API
#define API_SetDefaultFontFace API_SetDefaultFontFaceW
#else
#define API_SetDefaultFontFace API_SetDefaultFontFaceA
#endif

extern void TOOL_PUBLIC API_SetDefaultFontSize(gtint32 size);

extern GtCStringA  TOOL_PUBLIC API_GetDefaultReportFontFaceA();
extern GtCStringW  TOOL_PUBLIC API_GetDefaultReportFontFaceW();
#ifdef TOOL_WIDE_API
#define API_GetDefaultReportFontFace API_GetDefaultReportFontFaceW
#else
#define API_GetDefaultReportFontFace API_GetDefaultReportFontFaceA
#endif

extern gtint32 TOOL_PUBLIC API_GetDefaultReportFontSize();

extern void TOOL_PUBLIC API_SetDefaultReportFontFaceA(GtCStringA face_nameA);
extern void TOOL_PUBLIC API_SetDefaultReportFontFaceW(GtCStringW face_nameW);
#ifdef TOOL_WIDE_API
#define API_SetDefaultReportFontFace API_SetDefaultReportFontFaceW
#else
#define API_SetDefaultReportFontFace API_SetDefaultReportFontFaceA
#endif

extern void TOOL_PUBLIC API_SetDefaultReportFontSize(gtint32 size);

extern GtCStringA  TOOL_PUBLIC API_GetDefaultReportTitleFontFaceA();
extern GtCStringW  TOOL_PUBLIC API_GetDefaultReportTitleFontFaceW();
#ifdef TOOL_WIDE_API
#define API_GetDefaultReportTitleFontFace API_GetDefaultReportTitleFontFace
#else
#define API_GetDefaultReportTitleFontFace API_GetDefaultReportTitleFontFace
#endif

extern gtint32 TOOL_PUBLIC API_GetDefaultReportTitleFontSize();

extern void TOOL_PUBLIC API_SetDefaultReportTitleFontFaceA(GtCStringA face_nameA);
extern void TOOL_PUBLIC API_SetDefaultReportTitleFontFaceW(GtCStringW face_nameW);
#ifdef TOOL_WIDE_API
#define API_SetDefaultReportTitleFontFace API_SetDefaultReportTitleFontFaceW
#else
#define API_SetDefaultReportTitleFontFace API_SetDefaultReportTitleFontFaceA
#endif

extern void TOOL_PUBLIC API_SetDefaultReportTitleFontSize(gtint32 size);

TOOL_END_EXTERN_C

