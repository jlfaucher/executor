#include <conf.h>

/************************************************************************/
/* Section: Atomic datatypes */
/************************************************************************/
#if defined(_TOOL_OS_WIN32)

#define _TOOL_OS_WIN

typedef char gtcharA;
typedef unsigned short gtcharW;

#else /* Unix */

typedef char gtcharA;
typedef unsigned short gtcharW;

#endif /* Unix */


#ifdef TOOL_WIDE_API
#define gtchar gtcharW
#else
#define gtchar gtcharA
#endif

// Can be either [multi-]byte (if UNICODE *NOT* defined) or Unicode (if UNICODE defined)
typedef gtchar *  GtString;
typedef const gtchar * GtCString;

// Always [multi-]byte
typedef gtcharA *GtStringA;
typedef const gtcharA *GtCStringA;

// Always Unicode
typedef gtcharW *GtStringW;
typedef const gtcharW *GtCStringW;

// Conversion [multi-]byte <--> Unicode
// The following functions depend on the code page selected using API_SetCodePage
extern GtBool TOOL_PUBLIC API_StringA2W(GtCStringA pszA, GtStringW *ppszW);
extern GtBool TOOL_PUBLIC API_StringW2A(GtCStringW pszW, GtStringA *ppszA);

// Code page selection to indicate how to interpret the [multi-]byte strings
// You must use values that can be passed to system functions like WideCharToMultiByte, MultiByteToWideChar AND setlocale
// Code page examples :
//    Symbol  Value Meaning
//    --------------------------------
//    CP_ACP      0 ANSI code page
//             1252 ANSI Latin 1
//            28591 ISO 8859-1 Latin 1
//    CP_UTF7 65000 Unicode UTF-7
//    CP_UTF8 65001 Unicode UTF-8
extern GtBool TOOL_PUBLIC API_SetCodePage(gtuint16 codepage);
extern gtuint16 TOOL_PUBLIC API_GetCodePage();

#define GTCHARCOUNT(X) (sizeof(X) / sizeof(gtchar))

// Returns GtTrue if wide char are used internally
extern GtBool TOOL_PUBLIC API_UseWideChar();

// Controls how the strings (the C strings, not the OBJ strings) are passed
// to/from the user functions that are called by name :
// - When the name of the function ends with 'A', strings are passed as byte chars
// - When the name of the function ends with 'W', strings are passed as wide chars
// - Otherwise, the type of the strings is indicated by API_UserFnIsWide().
extern GtBool TOOL_PUBLIC API_UserFnIsWide(); // GtTrue ==> wide chars supported
extern GtBool TOOL_PUBLIC API_UserFnSetWide(GtBool b); // Returns the old value


/************************************************************************/
/* Section: Complex datatypes */
/************************************************************************/

typedef void (*GtErrorFnA)(GtCStringA);
typedef void (*GtErrorFnW)(GtCStringW);
#ifdef TOOL_WIDE_API
#define GtErrorFn GtErrorFnW
#else
#define GtErrorFn GtErrorFnA
#endif

