TOOL_START_EXTERN_C

GtBool TOOL_PUBLIC API_InitA(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, int argc, gtcharA **argvA);
GtBool TOOL_PUBLIC API_InitW(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, int argc, gtcharW **argvW);
#ifdef TOOL_WIDE_API
#define API_Init API_InitW
#else
#define API_Init API_InitA
#endif

GtBool TOOL_PUBLIC API_Init2A(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, GtBool light_exit, int argc, gtcharA **argvA);
GtBool TOOL_PUBLIC API_Init2W(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, GtBool light_exit, int argc, gtcharW **argvW);
#ifdef TOOL_WIDE_API
#define API_Init2 API_Init2W
#else
#define API_Init2 API_Init2A
#endif


GtBool TOOL_PUBLIC API_IsTOOLInitialized();
GtBool TOOL_PUBLIC API_UseExceptionCatching();


void TOOL_PUBLIC API_Exit();
void TOOL_PUBLIC API_LightExit();

void TOOL_PUBLIC API_MainLoop(void);

GtBool TOOL_PUBLIC API_SetFnMapA(GtCStringA moduleA, GtFunTableEntry *map);
GtBool TOOL_PUBLIC API_SetFnMapW(GtCStringW moduleW, GtFunTableEntry *map);
#ifdef TOOL_WIDE_API
#define API_SetFnMap API_SetFnMapW
#else
#define API_SetFnMap API_SetFnMapA
#endif

void TOOL_PUBLIC API_SetErrorFnA(GtErrorFnA errorFnA);
void TOOL_PUBLIC API_SetErrorFnW(GtErrorFnW errorFnW);
#ifdef TOOL_WIDE_API
#define API_SetErrorFn API_SetErrorFnW
#else
#define API_SetErrorFn API_SetErrorFnA
#endif

void TOOL_PUBLIC API_SetRWStatusFn(GtRWStatusFn rwStatusFn);
void TOOL_PUBLIC API_SetPopupStatusFn( GtPopupStatusFn popupStatusFn);
void TOOL_PUBLIC API_SetResizeableNodeCheckFn( GtResizeableNodeCheckFn ResizeableNodeCheckFn);

GtBool TOOL_PUBLIC API_ExecProgramA(gtcharA **argvA);
GtBool TOOL_PUBLIC API_ExecProgramW(gtcharW **argvW);
#ifdef TOOL_WIDE_API
#define API_ExecProgram API_ExecProgramW
#else
#define API_ExecProgram API_ExecProgramA
#endif

gtint32 TOOL_PUBLIC API_GetProfileStringA ( GtCStringA pszFileA ,  GtCStringA pszSectionA, GtCStringA pszEntryA, GtCStringA pszDefaultA, /* out */ GtStringA pszValueA, gtint16 cBufSize);
gtint32 TOOL_PUBLIC API_GetProfileStringW ( GtCStringW pszFileW ,  GtCStringW pszSectionW, GtCStringW pszEntryW, GtCStringW pszDefaultW, /* out */ GtStringW pszValueW, gtint16 cBufSize);
#ifdef TOOL_WIDE_API
#define API_GetProfileString API_GetProfileStringW
#else
#define API_GetProfileString API_GetProfileStringA
#endif

void TOOL_PUBLIC API_WriteProfileStringA ( GtCStringA pszFileA ,  GtCStringA pszSectionA, GtCStringA pszEntryA, GtCStringA pszValueA);
void TOOL_PUBLIC API_WriteProfileStringW ( GtCStringW pszFileW ,  GtCStringW pszSectionW, GtCStringW pszEntryW, GtCStringW pszValueW);
#ifdef TOOL_WIDE_API
#define API_WriteProfileString API_WriteProfileStringW
#else
#define API_WriteProfileString API_WriteProfileStringA
#endif

void API_PreInit(GtHwnd topLevelHwnd, GtHwnd wnd) ;


/*HWND*/ GtHwnd TOOL_PUBLIC API_GetGlobalHwnd(void) ;

GtBool TOOL_PUBLIC API_IsSilentMode();
GtBool TOOL_PUBLIC API_SetSilentMode(GtBool mode); // Returns the previous value

GtCStringW TOOL_PUBLIC API_GetGt40PathW(void);
GtCStringA TOOL_PUBLIC API_GetGt40PathA(void);
#ifdef TOOL_WIDE_API
#define API_GetGt40Path API_GetGt40PathW
#else
#define API_GetGt40Path API_GetGt40PathA
#endif


// For CJK.
// The functions here work on system fonts, whereas the functions in optio.h work on logical fonts.
// Typically, the system font you select with API_SetDefaultSystemFont is assigned to the logical font "Helvetica".
// When you open the dialog box "Property Style" and select "Helvetica", you select the system font specified with API_SetDefaultSystemFont.
// If you select a font like "Arial Unicode MS" then you will see the CJK characters in TOOL...

GtCStringW TOOL_PUBLIC API_GetDefaultSystemFontW();
GtCStringA TOOL_PUBLIC API_GetDefaultSystemFontA();
#ifdef TOOL_WIDE_API
#define API_GetDefaultSystemFont API_GetDefaultSystemFontW
#else
#define API_GetDefaultSystemFont API_GetDefaultSystemFontA
#endif

GtCStringW TOOL_PUBLIC API_SetDefaultSystemFontW(GtCStringW fontnameW);
GtCStringA TOOL_PUBLIC API_SetDefaultSystemFontA(GtCStringA fontnameA);
#ifdef TOOL_WIDE_API
#define API_SetDefaultSystemFont API_SetDefaultSystemFontW
#else
#define API_SetDefaultSystemFont API_SetDefaultSystemFontA
#endif


TOOL_END_EXTERN_C

