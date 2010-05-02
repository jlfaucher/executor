/****************************************************************************/
/* Section: Functions */
/****************************************************************************/
static GtBool API_Init_(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, int argc, gtchar ** argv)
{
  if (!ZSetInstanceContext(hInstance, hPrevInst, ctrlMainLoop))
    return GtFalse;
    
  gtint16 ret;
  if (GtInitialize(&ret, argc, argv)) 
        return GtTrue;
  else
    return GtFalse;
}

GtBool TOOL_PUBLIC API_InitA(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, int argc, gtcharA **argvA)
{
    UserFnSetWide(GtFalse); // By default, consider that the client functions don't support wide char strings.

#ifdef TOOL_UNICODE
    gtcharW **argvW = NULL;
    if (argvA != NULL)
    {
        argvW = (gtcharW **)AllocMem(sizeof(gtcharW*) * argc);
        if (argvW != NULL)
        {
            for (int i=0; i<argc; i++)
            {
                argvW[i] = NULL;
                gtcharA *pszA = argvA[i];
                if (pszA != NULL)
                {
                    gtcharW *pszW;
                    GtBool done = GTA2W(pszA, &pszW);
                    if (done == GtTrue) argvW[i] = pszW;
                }
            }
        }
    }

    GtBool result = API_Init_(hInstance, hPrevInst, ctrlMainLoop, argc, argvW);

    if (argvW != NULL)
    {
        for (int i=0; i<argc; i++) FreeMem(argvW[i], 0);
        FreeMem(argvW, 0);
    }

    return result;
#else
    return API_Init_(hInstance, hPrevInst, ctrlMainLoop, argc, argvA);
#endif
}

#ifdef TOOL_UNICODE
GtBool TOOL_PUBLIC API_InitW(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, int argc, gtcharW **argvW)
{
    UserFnSetWide(GtTrue); // By default, consider that the client functions support wide char strings.
    return API_Init_(hInstance, hPrevInst, ctrlMainLoop, argc, argvW);
}
#endif

static GtBool API_Init2_(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, GtBool light_exit,
                          int argc, gtchar ** argv)
{
  if (!ZSetInstanceContext(hInstance, hPrevInst, ctrlMainLoop))
    return GtFalse;

  GtSetLightExitFlag(light_exit);

  gtint16 ret;
  if (GtInitialize(&ret, argc, argv))
    return GtTrue;
  else
    return GtFalse;
}

GtBool TOOL_PUBLIC API_Init2A(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, GtBool light_exit, int argc, gtcharA **argvA)
{
    UserFnSetWide(GtFalse); // By default, consider that the client functions don't support wide char strings.

#ifdef TOOL_UNICODE
    gtcharW **argvW = NULL;
    if (argvA != NULL)
    {
        argvW = (gtcharW **)AllocMem(sizeof(gtcharA*) * argc);
        if (argvW != NULL)
        {
            for (int i=0; i<argc; i++)
            {
                argvW[i] = NULL;
                gtcharA *pszA = argvA[i];
                if (pszA != NULL)
                {
                    gtcharW *pszW;
                    GtBool done = GTA2W(pszA, &pszW);
                    if (done == GtTrue) argvW[i] = pszW;
                }
            }
        }
    }

    GtBool result = API_Init2_(hInstance, hPrevInst, ctrlMainLoop, light_exit, argc, argvW);

    if (argvW != NULL)
    {
        for (int i=0; i<argc; i++) FreeMem(argvW[i], 0);
        FreeMem(argvW, 0);
    }

    return result;
#else
    return API_Init2_(hInstance, hPrevInst, ctrlMainLoop, light_exit, argc, argvA);
#endif
}

#ifdef TOOL_UNICODE
GtBool TOOL_PUBLIC API_Init2W(gtuint32 hInstance, gtuint32 hPrevInst, GtBool ctrlMainLoop, GtBool light_exit, int argc, gtcharW **argvW)
{
    UserFnSetWide(GtTrue); // By default, consider that the client functions support wide char strings.
    return API_Init2_(hInstance, hPrevInst, ctrlMainLoop, light_exit, argc, argvW);
}
#endif


void TOOL_PUBLIC API_PreInit(GtHwnd topLevelHwnd, GtHwnd wnd)
{
    GtSetTopLevelParentWindow(topLevelHwnd) ;
    GtSetMDIWindow(wnd) ;
}


GtBool TOOL_PUBLIC API_UseExceptionCatching()
{
	return GtUseExceptionCatching();
}


GtBool TOOL_PUBLIC API_IsTOOLInitialized()
{
	return GtIsTOOLInitialized();
}

void TOOL_PUBLIC API_Exit()
{
  GtExit();
}

void TOOL_PUBLIC API_LightExit()
{
  GtLightQuit();
}


void TOOL_PUBLIC API_MainLoop(void)
{
  GtMainLoop();
}

static GtBool API_ExecProgram_(GtString *argv)
{
  return ExecProgram2(argv); // ??? This function does nothing...
}

GtBool TOOL_PUBLIC API_ExecProgramA(gtcharA **argvA)
{
#ifdef TOOL_UNICODE
    // Don't know how to calculate the number of entries in argvA.
    // I suppose that the first NULL pointer is the end marker...
    gtcharW **argvW = NULL;
    int argc = 0;
    if (argvA != NULL)
    {
        while (argvA[argc] != NULL) argc++;
        argvW = (gtcharW **)AllocMem(sizeof(gtcharA*) * (argc+1));
        if (argvW != NULL)
        {
            for (int i=0; i<argc; i++)
            {
                argvW[i] = NULL;
                gtcharA *pszA = argvA[i];
                if (pszA != NULL)
                {
                    gtcharW *pszW;
                    GtBool done = GTA2W(pszA, &pszW);
                    if (done == GtTrue) argvW[i] = pszW;
                }
            }
            argvW[argc] = NULL; // The end marker
        }
    }

    GtBool result = API_ExecProgram_(argvW);

    if (argvW != NULL)
    {
        for (int i=0; i<argc; i++) FreeMem(argvW[i], 0);
        FreeMem(argvW, 0);
    }

    return result;
#else
    return API_ExecProgram_(argvA);
#endif
}

#ifdef TOOL_UNICODE
GtBool TOOL_PUBLIC API_ExecProgramW(gtcharW **argvW)
{
    return API_ExecProgram_(argvW);
}
#endif

static GtBool API_SetFnMap_(GtCString module, GtFunTableEntry *map)
{
  return SetFnMap((UNJUSTIFIED GtString)module, (gtchar *)map);
}

GtBool TOOL_PUBLIC API_SetFnMapA(GtCStringA moduleA, GtFunTableEntry *map)
{
#ifdef TOOL_UNICODE
    GtString moduleW;
    GtBool done = GTA2W(moduleA, &moduleW);
    
    if (done == GtTrue) done = API_SetFnMap_(moduleW, map);

    FreeMem(moduleW, 0);
    return done;
#else
    return API_SetFnMap_(moduleA, map);
#endif
}

#ifdef TOOL_UNICODE
GtBool TOOL_PUBLIC API_SetFnMapW(GtCStringW moduleW, GtFunTableEntry *map)
{
    return API_SetFnMap_(moduleW, map);
}
#endif


void TOOL_PUBLIC API_SetErrorFnA(GtErrorFnA errorFnA)
{
  GtSetErrorFnA(errorFnA);
}


#ifdef TOOL_UNICODE
void TOOL_PUBLIC API_SetErrorFnW(GtErrorFnW errorFnW)
{
  GtSetErrorFnW(errorFnW);
}
#endif


void TOOL_PUBLIC API_SetRWStatusFn(GtRWStatusFn rwStatusFn)
{
    GtSetRWStatusFn(rwStatusFn);
}


void  API_SetPopupStatusFn( GtPopupStatusFn popupStatusFn)
{
    GtSetPopupStatusFn( popupStatusFn) ;
}

extern "C" void  API_SetResizeableNodeCheckFn( GtResizeableNodeCheckFn ResizeableNodeCheckFn)
{
    GtSetResizeableNodeCheckFn( ResizeableNodeCheckFn) ;
}

GtTranslationFnA TOOL_PUBLIC API_SetTranslationFnA(GtTranslationFnA translationFnA)
{
    GtTranslationFnA currentFnA = GtGetTranslationFnA();
    GtSetTranslationFnA(translationFnA);
    return currentFnA;
}


#ifdef TOOL_UNICODE
GtTranslationFnW TOOL_PUBLIC API_SetTranslationFnW(GtTranslationFnW translationFnW)
{
    GtTranslationFnW currentFnW = GtGetTranslationFnW();
    GtSetTranslationFnW(translationFnW);
    return currentFnW;
}
#endif


static gtint32 TOOL_PUBLIC API_GetProfileString_ (const gtchar * pszFile , const gtchar * pszSection, const gtchar * pszEntry, const gtchar * pszDefault, gtchar * pszValue   , gtint16 cBufSize)
{ 
return GtGetProfileString (   (UNJUSTIFIED GtString)pszFile ,    (UNJUSTIFIED GtString)pszSection,   (UNJUSTIFIED GtString)pszEntry,   (UNJUSTIFIED GtString)pszDefault,   pszValue ,     cBufSize);
}

gtint32 TOOL_PUBLIC API_GetProfileStringA ( GtCStringA pszFileA ,  GtCStringA pszSectionA, GtCStringA pszEntryA, GtCStringA pszDefaultA, /* out */ GtStringA pszValueA, gtint16 cBufSize)
{
#ifdef TOOL_UNICODE
    GtStringW pszFileW;
    GtBool done1 = GTA2W(pszFileA, &pszFileW);

    GtStringW pszSectionW;
    GtBool done2 = GTA2W(pszSectionA, &pszSectionW);

    GtStringW pszEntryW;
    GtBool done3 = GTA2W(pszEntryA, &pszEntryW);

    GtStringW pszDefaultW;
    GtBool done4 = GTA2W(pszDefaultA, &pszDefaultW);

    // Must allocate a wide char buffer to ensure that we have enough room...
    GtStringW pszValueW = NULL;
    GtBool done5 = GtTrue;
    if (pszValueA != NULL)
    {
        *pszValueA = '\0';
        pszValueW = (GtStringW) AllocMem(sizeof(gtcharW) * (cBufSize+1));
        if (pszValueW == NULL) done5 = GtFalse;
    }

    gtint32 result = 0;
    if (done1 == GtTrue && done2 == GtTrue && done3 == GtTrue && done4 == GtTrue && done5 == GtTrue)
    {
        result = API_GetProfileString_ ( pszFileW ,  pszSectionW, pszEntryW, pszDefaultW, pszValueW, cBufSize);
    }

    if (result != 0 && pszValueA != NULL)
    {
        // The following post-conditions must be ensured :
        // - The return value is the number of characters copied to the buffer, 
        //   not including the terminating null character.
        // - If neither lpAppName nor lpKeyName is NULL and the supplied destination buffer
        //   is too small to hold the requested string, the string is truncated and followed
        //   by a null character, and the return value is equal to nSize minus one.
        // - If either lpAppName or lpKeyName is NULL and the supplied destination buffer is
        //   too small to hold all the strings, the last string is truncated and followed by
        //   two null characters. In this case, the return value is equal to nSize minus two.

        GtStringA tmpA;
        // Note : pszValueW may contain one or two null characters at the end.
        // They are not taken into account by GTW2A
        GtBool done = GTW2A(pszValueW, &tmpA);
        // The 8 bits buffer should be always big enough, but...
        if (done == GtTrue && strlen(tmpA) < cBufSize)
        {
            memset(pszValueA, '\0', cBufSize); // Fill the buffer with null characters because this could be useful to fulfil the postconditions.
            strcpy(pszValueA, tmpA);
            // Normally, result should be always equal to strlen(tmpA), because result
            // contains the number of chars, not the number of bytes...
            result = strlen(tmpA);
        }
        else
        {
            result = 0;
        }
        FreeMem(tmpA, 0);
    }

    FreeMem(pszValueW, 0);
    FreeMem(pszDefaultW, 0);
    FreeMem(pszEntryW, 0);
    FreeMem(pszSectionW, 0);
    FreeMem(pszFileW, 0);

    return result;
#else
    return API_GetProfileString_ ( pszFileA ,  pszSectionA, pszEntryA, pszDefaultA, pszValueA, cBufSize);
#endif
}

#ifdef TOOL_UNICODE
gtint32 TOOL_PUBLIC API_GetProfileStringW ( GtCStringW pszFileW ,  GtCStringW pszSectionW, GtCStringW pszEntryW, GtCStringW pszDefaultW, /* out */ GtStringW pszValueW, gtint16 cBufSize)
{
    return API_GetProfileString_ ( pszFileW ,  pszSectionW, pszEntryW, pszDefaultW, pszValueW, cBufSize);
}
#endif

static void API_WriteProfileString_ ( const gtchar * pszFile ,  const gtchar * pszSection, const gtchar * pszEntry, const gtchar * pszValue)
{
GtWriteProfileString (   (UNJUSTIFIED GtString)pszFile ,    (UNJUSTIFIED GtString)pszSection,   (UNJUSTIFIED GtString)pszEntry,   (UNJUSTIFIED GtString)pszValue);
}

void TOOL_PUBLIC API_WriteProfileStringA ( GtCStringA pszFileA ,  GtCStringA pszSectionA, GtCStringA pszEntryA, GtCStringA pszValueA)
{
#ifdef TOOL_UNICODE
    GtStringW pszFileW;
    GtBool done1 = GTA2W(pszFileA, &pszFileW);

    GtStringW pszSectionW;
    GtBool done2 = GTA2W(pszSectionA, &pszSectionW);

    GtStringW pszEntryW;
    GtBool done3 = GTA2W(pszEntryA, &pszEntryW);

    GtStringW pszValueW;
    GtBool done4 = GTA2W(pszValueA, &pszValueW);

    if (done1 == GtTrue && done2 == GtTrue && done3 == GtTrue && done4 == GtTrue)
    {
        API_WriteProfileString_ ( pszFileW ,  pszSectionW, pszEntryW, pszValueW);
    }

    FreeMem(pszValueW, 0);
    FreeMem(pszEntryW, 0);
    FreeMem(pszSectionW, 0);
    FreeMem(pszFileW, 0);
#else
    API_WriteProfileString_ ( pszFileA ,  pszSectionA, pszEntryA, pszValueA);
#endif
}

#ifdef TOOL_UNICODE
void TOOL_PUBLIC API_WriteProfileStringW ( GtCStringW pszFileW ,  GtCStringW pszSectionW, GtCStringW pszEntryW, GtCStringW pszValueW)
{
    API_WriteProfileString_ ( pszFileW ,  pszSectionW, pszEntryW, pszValueW);
}
#endif

GtHwnd TOOL_PUBLIC API_GetGlobalHwnd(void)
{
    return GtGetGlobalHwnd() ;
}


GtBool TOOL_PUBLIC API_IsSilentMode()
{
    return GtIsSilentMode();
}


GtBool TOOL_PUBLIC API_SetSilentMode(GtBool mode)
{
    return GtSetSilentMode(mode);
}


static GtCString API_GetGt40Path_()
{
    return GetGt40Path();
}

GtCStringA TOOL_PUBLIC API_GetGt40PathA(void)
{
#ifdef TOOL_UNICODE
    GtCStringW resultW = API_GetGt40Path_();

    GtCStringA resultA;
    GtBool done = HGTW2A(resultW, &resultA);
    if (done == GtTrue)
    {
        // Yes, returned as a GtCString, even if should be deleted...
        // It's because of the signature of GetGt40Path which is const.
        return resultA;
    }

    return NULL;
#else
    return API_GetGt40Path_();
#endif
}

#ifdef TOOL_UNICODE
GtCStringW TOOL_PUBLIC API_GetGt40PathW (void)
{
    return API_GetGt40Path_();
}
#endif


static GtCString API_GetDefaultSystemFont_()
{
    return ZGetDefaultSystemFont();
}

GtCStringA TOOL_PUBLIC API_GetDefaultSystemFontA()
{
#ifdef TOOL_UNICODE
    GtCStringW resultW = API_GetDefaultSystemFont_();

    GtCStringA resultA;
    GtBool done = HGTW2A(resultW, &resultA);
    if (done == GtTrue)
    {
        return resultA;
    }

    return NULL;
#else
    return API_GetDefaultSystemFont_();
#endif
}

#ifdef TOOL_UNICODE
GtCStringW TOOL_PUBLIC API_GetDefaultSystemFontW ()
{
    return API_GetDefaultSystemFont_();
}
#endif


static GtCString API_SetDefaultSystemFont_(GtCString fontname)
{ 
    return ZSetDefaultSystemFont(fontname);
}   

GtCStringA API_SetDefaultSystemFontA(GtCStringA fontnameA)
{
#ifdef TOOL_UNICODE
    GtStringW fontnameW;
    GtBool done = GTA2W(fontnameA, &fontnameW);

    GtCStringW resultW = NULL;
    if (done == GtTrue) resultW = API_SetDefaultSystemFont_(fontnameW);

    FreeMem(fontnameW, 0);

    GtCStringA resultA;
    done = HGTW2A(resultW, &resultA);
    if (done == GtTrue)
    {
        return resultA;
    }

    return NULL;
#else
    return API_SetDefaultSystemFont_(fontnameA);
#endif
}

#ifdef TOOL_UNICODE
GtCStringW API_SetDefaultSystemFontW(GtCStringW fontnameW)
{
    return API_SetDefaultSystemFont_(fontnameW);
}
#endif
