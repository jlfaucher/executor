/*
Replace the parsing of the cl's default output which was done in makeorx.bat.
It was not supporting localized versions of cl...
FR :
Compilateur d'optimisation Microsoft (R) 32 bits C/C++ version 16.00.30319.01 pour 80x86
*/
#include <stdio.h>
void main()
{
char *mscver="unknown";
if (_MSC_VER >= 1200) mscver="6.0";
if (_MSC_VER >= 1300) mscver="7.0";
if (_MSC_VER >= 1310) mscver="7.1";
if (_MSC_VER >= 1400) mscver="8.0";
if (_MSC_VER >= 1500) mscver="9.0";
if (_MSC_VER >= 1600) mscver="10.0";
if (_MSC_VER >= 1700) mscver="11.0";
if (_MSC_VER >= 1800) mscver="12.0";
if (_MSC_VER >= 1900) mscver="14.0";
if (_MSC_VER >= 1910) mscver="15.0";
if (_MSC_VER >= 1911) mscver="15.3";
if (_MSC_VER >= 1912) mscver="15.5";
int bitness=32;
char *cpu="X86";
#ifdef _WIN64
bitness=64;
cpu="X64";
#endif
printf("%s %s %i\n", mscver, cpu, bitness);
}

/*
https://en.wikipedia.org/wiki/Microsoft_Visual_C++

MSC    1.0   _MSC_VER == 100
MSC    2.0   _MSC_VER == 200
MSC    3.0   _MSC_VER == 300
MSC    4.0   _MSC_VER == 400
MSC    5.0   _MSC_VER == 500
MSC    6.0   _MSC_VER == 600
MSC    7.0   _MSC_VER == 700
MSVC++ 1.0   _MSC_VER == 800
MSVC++ 2.0   _MSC_VER == 900
MSVC++ 4.0   _MSC_VER == 1000 (Developer Studio 4.0)
MSVC++ 4.2   _MSC_VER == 1020 (Developer Studio 4.2)
MSVC++ 5.0   _MSC_VER == 1100 (Visual Studio 97 version 5.0)
MSVC++ 6.0   _MSC_VER == 1200 (Visual Studio 6.0 version 6.0)
MSVC++ 7.0   _MSC_VER == 1300 (Visual Studio .NET 2002 version 7.0)
MSVC++ 7.1   _MSC_VER == 1310 (Visual Studio .NET 2003 version 7.1)
MSVC++ 8.0   _MSC_VER == 1400 (Visual Studio 2005 version 8.0)
MSVC++ 9.0   _MSC_VER == 1500 (Visual Studio 2008 version 9.0)
MSVC++ 10.0  _MSC_VER == 1600 (Visual Studio 2010 version 10.0)
MSVC++ 11.0  _MSC_VER == 1700 (Visual Studio 2012 version 11.0)
MSVC++ 12.0  _MSC_VER == 1800 (Visual Studio 2013 version 12.0)
MSVC++ 14.0  _MSC_VER == 1900 (Visual Studio 2015 version 14.0)
MSVC++ 14.1  _MSC_VER == 1910 (Visual Studio 2017 version 15.0)
MSVC++ 14.11 _MSC_VER == 1911 (Visual Studio 2017 version 15.3)
MSVC++ 14.12 _MSC_VER == 1912 (Visual Studio 2017 version 15.5)
*/