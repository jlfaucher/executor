/************************************************************************/
/* Section: Unicode */
/************************************************************************/

#ifdef TOOL_NOT_UNICODE
#error Wide char tool : The TOOL_NOT_UNICODE macro must not be defined
#endif

// The strings handled internally are UTF16 strings
#ifndef TOOL_UNICODE
#define TOOL_UNICODE
#endif

// It's up to you to decide which API you want to use :
// - If you don't define TOOL_WIDE_API, the byte char API is used.
// - If you define TOOL_WIDE_API, the wide char API is used.

