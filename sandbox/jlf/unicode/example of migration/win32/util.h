GT_START_EXTERN_C

extern GtBool GT_PUBLIC GtSetCodePage(gtuint16 codepage);
extern gtuint16 GT_PUBLIC GtGetCodePage();

// The following functions depend on the code page selected using GtSetCodePage
extern GtBool GT_PUBLIC GTA2W(GtCStringA pszA, GtStringW *ppszW);
extern GtBool GT_PUBLIC GTW2A(GtCStringW pszW, GtStringA *ppszA);

// Hashed version of GTW2A : No memory leak.
// Useful to support the legacy byte applications.
// The returned string is a constant, so don't delete it !
extern GtBool GT_PUBLIC HGTW2A(GtCStringW pszW, GtCStringA *ppcszA);

// Used to decide which kind of strings (byte or wide) can be passed to/from the user functions called by name, when their name is neither xxxA nor xxxW.
extern GtBool GT_PUBLIC UserFnIsWide();
extern GtBool GT_PUBLIC UserFnSetWide(GtBool b);

GT_END_EXTERN_C

