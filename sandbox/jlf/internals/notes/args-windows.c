/*
build:
cl args-windows.c Shell32.lib User32.lib
*/

// 1: similar to rexx
// 2: wmain (new)
// 3: similar to rexxhide (no console)
#define MAIN 2


#include <stdio.h>
#include <windows.h>
#include <shlwapi.h>

// defined in oorexx rexxapitypes.h
typedef int int32_t;


// Copied with adaptations from oodShared.cpp
/**
 * Allocates a buffer and converts a wide character (Unicode) string to an ANSI
 * string.
 *
 * @param wstr    The string to convert.
 *
 * @return The converted string, or null on error.
 *
 * @note  The caller is responsible for freeing the returned string.
 *        Memory is allocated using LocalAlloc.
 */
char *unicode2ansi(int codePage, LPWSTR wstr)
{
    if (wstr == NULL)
    {
        return NULL;
    }

    char *ansiStr = NULL;
    int32_t neededLen = WideCharToMultiByte(codePage, 0, wstr, -1, NULL, 0, NULL, NULL);

    if ( neededLen != 0 )
    {
        ansiStr = (char *)LocalAlloc(LPTR, neededLen);
        if ( ansiStr != NULL )
        {
            if ( WideCharToMultiByte(codePage, 0, wstr, -1, ansiStr, neededLen, NULL, NULL) == 0 )
            {
                /* conversion failed */
                LocalFree(ansiStr);
                ansiStr = NULL;
            }
        }
    }

    return ansiStr;
}


// Adaptation of commandLineToArgv
/**
 * Convert an array of UTF-16 strings to an array of ANSI strings.
 *
 * @param codePage      convert UTF-16 to this code page
 * @param argc          count of strings in wargv
 * @param wargv         array of UTF-16 strings
 *
 * @return An array of null-terminated ANSI strings, or null on error.
 *
 * @note  If there is no error, it is the responsibility of the caller to free
 *        with LocalFree both the returned array and the strings in the array.
 *
 *        On error, there is no memory to free.
 */
char **wArgvToArgv(int codePage, int argc, wchar_t *wargv[ ])
{
    if (wargv == NULL) return NULL;

    char **args = (char **)LocalAlloc(LPTR, argc * sizeof(char **));
    if (args == NULL) return NULL;

    for ( int i = 0; i < argc; i++)
    {
        wchar_t *a = wargv[i];
        args[i] = unicode2ansi(codePage, a);
        if (args[i] == NULL)
        {
            // error, free the array and the strings already put in the array
            for (int32_t j = 0; j < i; j++)
            {
                LocalFree(args[j]);
            }
            LocalFree(args);
            return NULL;
        }
    }

    return args;
}


// Copied with adaptations from oodWinMain.cpp
/**
 * Gets the wide character string command line arguments in conventional argv /
 * argc format and convert the argument array to an array of ANSI strings.
 *
 * @param codePage
 * @param count
 *
 * @return An array of null-terminated ANSI strings, or null on error.
 *
 * @note  If there is no error, it is the responsibility of the caller to free
 *        with LocalFree both the returned array and the strings in the array.
 *
 *        On error, there is no memory to free.
 */
char **commandLineToArgv(int codePage, int32_t *count)
{
    LPWSTR  *szArglist = NULL;
    char   **args      = NULL;
    int32_t nArgs      = 0;

    *count = 0;
    szArglist = CommandLineToArgvW(GetCommandLineW(), &nArgs);
    if (szArglist == NULL) return NULL;

    args = (char **)LocalAlloc(LPTR, nArgs * sizeof(char **));
    if (args == NULL)
    {
        LocalFree(szArglist);
        return NULL;
    }

    for ( int32_t i = 0; i < nArgs; i++)
    {
        LPWSTR a = szArglist[i];
        args[i] = unicode2ansi(codePage, a);
        if (args[i] == NULL)
        {
            // error, free the array and the strings already put in the array
            for (int32_t j = 0; j < i; j++)
            {
                LocalFree(args[j]);
            }
            LocalFree(szArglist);
            LocalFree(args);
            return NULL;
        }
    }

    LocalFree(szArglist);
    *count = nArgs;
    return args;
}


// Copied from ArgumentParser.h
// Utility to parse out a command line string into the unix-style
// argv/argc format.  Used for setting the array of arguments
// in .local
PCHAR* CommandLineToArgvA(PCHAR CmdLine, int32_t* _argc)
{
    char     **argv;
    char      *_argv;
    size_t    len;
    int32_t   argc;
    char      a;
    size_t    i, j;

    BOOLEAN  in_QM;
    BOOLEAN  in_TEXT;
    BOOLEAN  in_SPACE;

    len = strlen(CmdLine);
    i = ((len+2)/2)*sizeof(void *) + sizeof(void *);

    argv = (char**)GlobalAlloc(GMEM_FIXED,
                               i + (len+2)*sizeof(char));

    _argv = (PCHAR)(((PUCHAR)argv)+i);

    argc = 0;
    argv[argc] = _argv;
    in_QM = FALSE;
    in_TEXT = FALSE;
    in_SPACE = TRUE;
    i = 0;
    j = 0;

    while ( a = CmdLine[i] )
    {
        if (in_QM)
        {
            if (a == '\"')
            {
                in_QM = FALSE;
            }
            else
            {
                _argv[j] = a;
                j++;
            }
        }
        else
        {
            switch (a)
            {
                case '\"':
                    in_QM = TRUE;
                    in_TEXT = TRUE;
                    if (in_SPACE)
                    {
                        argv[argc] = _argv+j;
                        argc++;
                    }
                    in_SPACE = FALSE;
                    break;
                case ' ':
                case '\t':
                case '\n':
                case '\r':
                    if (in_TEXT)
                    {
                        _argv[j] = '\0';
                        j++;
                    }
                    in_TEXT = FALSE;
                    in_SPACE = TRUE;
                    break;
                default:
                    in_TEXT = TRUE;
                    if (in_SPACE)
                    {
                        argv[argc] = _argv+j;
                        argc++;
                    }
                    _argv[j] = a;
                    j++;
                    in_SPACE = FALSE;
                    break;
            }
        }
        i++;
    }
    _argv[j] = '\0';
    argv[argc] = NULL;

    (*_argc) = argc;
    return argv;
}


void print_c2x(const char *s)
{
    printf("    ");
    for (int i = 0; i < strlen(s); i++)
    {
        printf("%02x ", (unsigned char)s[i]);
    }
    printf("\n");
}


int sprint_c2x(char *buffer, const char *s)
{
    int offset = 0;

    offset += sprintf(buffer + offset, "    ");
    for (int i = 0; i < strlen(s); i++)
    {
        offset += sprintf(buffer + offset, "%02x ", (unsigned char)s[i]);
    }
    offset += sprintf(buffer + offset, "\n");

    return offset;
}


#if MAIN == 1

int main(int argc, char **argv)
{
    printf("\n");
    printf("Original equipment manufacturer (GetOEMCP) = %i\n", GetOEMCP());
    printf("Windows ANSI code page code page (GetACP) = %i\n", GetACP());

    printf("\n");
    printf("input code page (GetConsoleCP) = %i\n", GetConsoleCP());
    printf("output code page (GetConsoleOutputCP) = %i\n", GetConsoleOutputCP());

    printf("\n");
    printf("current implementation: chcp has no impact\n");
    for (int i = 0; i < argc; i++)
    {
        printf("%i : %s\n", i, argv[i]);
        print_c2x(argv[i]);
    }

    printf("\n");
    printf("new implementation: chcp has an impact\n");
    argv = commandLineToArgv(GetConsoleCP(), &argc);
    for (int i = 0; i < argc; i++)
    {
        printf("%i : %s\n", i, argv[i]);
        print_c2x(argv[i]);
    }
}

#elif MAIN == 2

int wmain( int argc, wchar_t *wargv[ ] )
{
    printf("\n");
    printf("Original equipment manufacturer (GetOEMCP) = %i\n", GetOEMCP());
    printf("Windows ANSI code page code page (GetACP) = %i\n", GetACP());

    printf("\n");
    printf("input code page (GetConsoleCP) = %i\n", GetConsoleCP());
    printf("output code page (GetConsoleOutputCP) = %i\n", GetConsoleOutputCP());

    char **argv = wArgvToArgv(GetConsoleCP(), argc, wargv);

    printf("\n");
    for (int i = 0; i < argc; i++)
    {
        printf("%i : %s\n", i, argv[i]);
        print_c2x(argv[i]);
    }
}

#elif MAIN == 3

int WINAPI WinMain(
    HINSTANCE hInstance,                 // handle to current instance
    HINSTANCE hPrevInstance,             // handle to previous instance
    LPSTR lpCmdLine,                     // pointer to command line
    int nCmdShow)
{
    CHAR  buffer[10000];
    int offset = 0;
    int argc;                            // parsed count of arguments
    PCHAR *argv;                         // parsed out arguments

    offset += sprintf(buffer + offset, "\n");
    offset += sprintf(buffer + offset, "Original equipment manufacturer (GetOEMCP) = %i\n", GetOEMCP());
    offset += sprintf(buffer + offset, "Windows ANSI code page code page (GetACP) = %i\n", GetACP());

    offset += sprintf(buffer + offset, "\n");
    offset += sprintf(buffer + offset, "input code page (GetConsoleCP) = %i\n", GetConsoleCP());
    offset += sprintf(buffer + offset, "output code page (GetConsoleOutputCP) = %i\n", GetConsoleOutputCP());

    offset += sprintf(buffer + offset, "\n");
    offset += sprintf(buffer + offset, "lpCmdLine = %s\n", lpCmdLine);

    offset += sprintf(buffer + offset, "\n");
    offset += sprintf(buffer + offset, "current implementation:\n");
    argv = CommandLineToArgvA(lpCmdLine, &argc);
    for (int i = 0; i < argc; i++)
    {
        offset += sprintf(buffer + offset, "%i : %s\n", i, argv[i]);
        offset += sprint_c2x(buffer + offset, argv[i]);
    }

    offset += sprintf(buffer + offset, "\n");
    offset += sprintf(buffer + offset, "new implementation:\n");
    argv = commandLineToArgv(65001, &argc);
    for (int i = 0; i < argc; i++)
    {
        offset += sprintf(buffer + offset, "%i : %s\n", i, argv[i]);
        offset += sprint_c2x(buffer + offset, argv[i]);
    }

    MessageBox(NULL, buffer, "rexxhide", MB_OK | MB_ICONHAND);
}

#endif
