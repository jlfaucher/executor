/*****************************************************************************/
/* Section: GtCase Default Callbacks */
/*****************************************************************************/

/* Example, see below 
#define BUFLEN 40
static gtchar pszTitle   [BUFLEN];
static gtchar pszVersion [BUFLEN];
static gtchar pszComments[BUFLEN];
*/

/* CopyRight Info Callback */
#ifdef TOOL_UNICODE
void GtdCpyWrtInfoW(GtStringW * title, GtStringW * version, GtStringW * comments)
#else
void GtdCpyWrtInfoA(GtStringA * title, GtStringA * version, GtStringA * comments)
#endif
{
/* Example of customizing the banner
  _tcscpy(pszTitle,    _T("My CASE Tool"));
  _tcscpy(pszVersion,  _T("Version 1.0"));
  _tcscpy(pszComments, _T("(c) 1996 Foo Bar Company"));
  *title    = pszTitle;
  *version  = pszVersion;
  *comments = pszComments;
*/

/*  set pointers to NULL when original TOOL banner is wanted.
*/
  *title    = (GtString) 0;
  *version  = (GtString) 0;
  *comments = (GtString) 0;
}


/* Installing Document Drivers  */
#ifdef TOOL_UNICODE
void TOOL_PUBLIC GtdDocInitW(gtint16 argc, GtStringW *argv)
{
  /* Register automatic documentation drivers */
#ifdef _TOOL_OS_WIN

  GtDocRegisterW(_T("RTF"),   _T("RTF"),   _T("winword.exe"),  RTFMethodsW());
  GtDocRegisterW(_T("HTML"),  _T("HTML"),  _T("mosaic.exe"),  HTMLMethodsW());
  GtDocRegisterW(_T("ASCII"), _T("ASCII"), _T("notepad.exe"),  ASCMethodsW());

#else

  GtDocRegister(_T("ASCII"), _T("ASCII"), _T("vi"),      ASCMethods());
//  GtDocRegister("MIF",   "MIF",   "framemaker",   MIFMethods());

#endif /* _TOOL_OS_WIN */
}

#else // Not TOOL_UNICODE

void TOOL_PUBLIC GtdDocInitA(gtint16 argc, GtStringA *argv)
{
  /* Register automatic documentation drivers */
#ifdef _TOOL_OS_WIN

  GtDocRegisterA(_T("RTF"),   _T("RTF"),   _T("winword.exe"),  RTFMethodsA());
  GtDocRegisterA(_T("HTML"),  _T("HTML"),  _T("mosaic.exe"),  HTMLMethodsA());
  GtDocRegisterA(_T("ASCII"), _T("ASCII"), _T("notepad.exe"),  ASCMethodsA());

#else

  GtDocRegister(_T("ASCII"), _T("ASCII"), _T("vi"),      ASCMethods());
//  GtDocRegister("MIF",   "MIF",   "framemaker",   MIFMethods());

#endif /* _TOOL_OS_WIN */
}
#endif // Not Unicode


/* General Initialization Function */
#ifdef TOOL_UNICODE
void TOOL_PUBLIC GtdInitW(gtint16 argc, GtStringW *argv)
#else
void TOOL_PUBLIC GtdInitA(gtint16 argc, GtStringA *argv)
#endif
{
  gtchar buffer[6]; // true or false
  ToolApi_GetProfileString(_T("tool.ini"), _T("Environment"), _T("TOOL_USERFN_WIDE"), _T(""), buffer, GTCHARCOUNT(buffer));
  if (_tcsicmp(buffer, _T("true")) == 0) ToolApi_UserFnSetWide(GtTrue);
  if (_tcsicmp(buffer, _T("false")) == 0) ToolApi_UserFnSetWide(GtFalse);

  /* Put your initializations hereafter... */
}
