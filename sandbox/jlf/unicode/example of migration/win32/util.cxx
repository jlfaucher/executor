/*****************************************************************************
                                Unicode stuff
*****************************************************************************/

// See setlocale : the 'locale' argument can be something like ".1252"
static GtCString CodePageToString(gtuint16 i)
{
    const size = 20;
    static gtchar buffer[size];
    int count = _sntprintf(buffer, size, _T(".%u"), i);
    buffer[size - 1] = '\0';
    return (count < 0) ? NULL : buffer;
}


static gtuint16 theCodePage = 0; // 0 means ANSI code page


GtBool TOOL_PUBLIC GtSetCodePage(gtuint16 codepage)
{
    GtCString cpstr = CodePageToString(codepage);
    if (cpstr == NULL) return GtFalse;
    GtCString locale = _tsetlocale(LC_CTYPE, cpstr);
    if (locale == NULL) return GtFalse;
    int done = _setmbcp(codepage);
    if (done == -1) return GtFalse;
    theCodePage = codepage;
    return GtTrue;
}


gtuint16 TOOL_PUBLIC GtGetCodePage()
{
#if 1
    return theCodePage;
#else // Hmmm... Could be too long...
    GtCString locale = _tsetlocale(LC_CTYPE, NULL);
    if (locale == NULL) return 0; // Panic !
    
    // The locale argument takes the following form: "lang[_country_region[.code_page]]" 
    GtCString cpstr = locale + _tcslen(locale); // Go to the end of the string
    while (cpstr != locale) // Move back until a non digit is encountered
    {
        if (!isdigit(*(cpstr-1))) break;
        cpstr--;
    }

    gtuint16 codepage = _tstoi(cpstr); // If cpstr is not a sequence of digits, then codepage=0, which is fine because it's CP_ACP (ANSI code page)
    return codepage;
#endif
}


GtBool GTA2W(GtCStringA pszA, GtStringW *ppszW)
{
    *ppszW = NULL;

    // If input is null then just return the same.
    if (NULL == pszA)
    {
        return GtTrue; // NOERROR
    }

    // Determine number of wide characters to be allocated for the
    // Unicode string.
    ULONG cCharacters =  strlen(pszA)+1;

    *ppszW = (GtStringW) AllocMem(cCharacters*2);
    if (NULL == *ppszW)
        return GtFalse; // E_OUTOFMEMORY;

    // Convert to Unicode.
    if (0 == MultiByteToWideChar(GtGetCodePage(), 0, pszA, cCharacters, *ppszW, cCharacters))
    {
        DWORD dwError = GetLastError();
        FreeMem(*ppszW, 0);
        *ppszW = NULL;
        return GtFalse; // HRESULT_FROM_WIN32(dwError);
    }

    return GtTrue;
}


GtBool GTW2A(GtCStringW pszW, GtStringA *ppszA)
{
    *ppszA = NULL;

    // If input is null then just return the same.
    if (pszW == NULL)
    {
        return GtTrue; // NOERROR
    }

    ULONG cCharacters = wcslen(pszW)+1;
    // Determine number of bytes to be allocated for ANSI string. An
    // ANSI string can have at most 2 bytes per character (for Double
    // Byte Character Strings.)
    ULONG cbAnsi = cCharacters*2;

    *ppszA = (GtStringA) AllocMem(cbAnsi);
    if (NULL == *ppszA)
        return GtFalse; // E_OUTOFMEMORY;

    // Convert to ANSI.
    if (0 == WideCharToMultiByte(GtGetCodePage(), 0, pszW, cCharacters, *ppszA, cbAnsi, NULL, NULL))
    {
        DWORD dwError = GetLastError();
        FreeMem(*ppszA, 0);
        *ppszA = NULL;
        return GtFalse; // HRESULT_FROM_WIN32(dwError);
    }

    return GtTrue;
}


// Hashed version of GTW2A : no memory leak
GtBool HGTW2A(GtCStringW pszW, GtCStringA *ppcszA)
{
    GtStringA pszA;
    GtBool done = GTW2A(pszW, &pszA);
    if (!done) return GtFalse;

#if _MSC_VER >= 1300 // VC7 and above
    // Beware ! This is a set of pointers, not a set of objects.
    // There is no copy of the referenced area.
    GtCStringAPair pair = theGtCStringAHSet.insert(pszA);
    if (*(pair.first) != pszA) FreeMem(pszA, 0); // Already inserted by a previous call, can free the string created by the current call
    *ppcszA = *(pair.first); // Returns the string stored in the hash table
    return GtTrue;
#else
    // hash table not supported by VC6... Anyway, not a problem, because wide version not supported with VC6...
    return GtTrue; // UnicodeMemoryLeak!
#endif
}


// By default, the strings passed to/from user functions called by name have
// the same type as the strings used internally.
#ifdef TOOL_UNICODE
static GtBool userFnIsWide = GtTrue;
#else
static GtBool userFnIsWide = GtFalse;
#endif


GtBool UserFnIsWide()
{
    return userFnIsWide;
}


GtBool UserFnSetWide(GtBool b)
{
    GtBool old = userFnIsWide;
    userFnIsWide = b;
    return old;
}

