/*****************************************************************************/
/* Section: Conversion Functions */
/*****************************************************************************/

static OBJ API_String_(GtCString psz)
{
  return String(psz);
}
 
OBJ TOOL_PUBLIC API_StringA(GtCStringA pszA)
{
#ifdef TOOL_UNICODE
    GtString pszW;
    GtBool done = GTA2W(pszA, &pszW);

    OBJ result = NIL;
    if (done == GtTrue) result = API_String_(pszW);

    FreeMem(pszW, 0);
    return result;
#else
    return API_String_(pszA);
#endif
}

#ifdef TOOL_UNICODE
OBJ TOOL_PUBLIC API_StringW(GtCStringW pszW)
{
    return API_String_(pszW);
}
#endif

GtBool TOOL_PUBLIC API_StringA2W(GtCStringA pszA, GtStringW *ppszW)
{
    return GTA2W(pszA, ppszW);
}

GtBool TOOL_PUBLIC API_StringW2A(GtCStringW pszW, GtStringA *ppszA)
{
    return GTW2A(pszW, ppszA);
}

GtBool TOOL_PUBLIC API_UseWideChar()
{
#ifdef TOOL_UNICODE
    return GtTrue;
#else
    return GtFalse;
#endif
}

// With the byte version of tool, this value is stored but ignored when the user functions are called.
GtBool TOOL_PUBLIC API_UserFnSetWide(GtBool b)
{
    return UserFnSetWide(b);
}

GtBool TOOL_PUBLIC API_UserFnIsWide()
{
    return UserFnIsWide();
}

