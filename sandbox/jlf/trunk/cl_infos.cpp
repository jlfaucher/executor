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
if (_MSC_VER >= 1400) mscver="8.0";
if (_MSC_VER >= 1500) mscver="9.0";
if (_MSC_VER >= 1600) mscver="10.0";
if (_MSC_VER >= 1700) mscver="11.0";
if (_MSC_VER >= 1800) mscver="12.0";
if (_MSC_VER >= 1900) mscver="14.0";
int bitness=32;
char *cpu="X86";
#ifdef _WIN64
bitness=64;
cpu="X64";
#endif
printf("%s %s %i\n", mscver, cpu, bitness);
}

/*
https://en.wikipedia.org/wiki/Microsoft_Visual_Studio

Product name                Codename        Internal version    cl.exe version  Supported .NET Framework versions   Release date
Visual Studio	            N/A	            4.0	                0.0	            N/A                                                 April 1995
Visual Studio 97            Boston          5.0                 0.0             N/A                                                 February 1997
Visual Studio 6.0           Aspen           6.0                 0.0             N/A                                                 June 1998
Visual Studio .NET (2002)   Rainier         7.0                 0.0             1.0                                                 February 13, 2002
Visual Studio .NET 2003     Everett         7.1                 13.0            1.1                                                 April 24, 2003
Visual Studio 2005          Whidbey         8.0                 14.00           2.0, 3.0                                            November 7, 2005
Visual Studio 2008          Orcas           9.0                 15.00           2.0, 3.0, 3.5                                       November 19, 2007
Visual Studio 2010          Dev10/Rosario   10.0                16.00           2.0, 3.0, 3.5, 4.0                                  April 12, 2010
Visual Studio 2012          Dev11           11.0                17.00           2.0, 3.0, 3.5, 4.0, 4.5, 4.5.1, 4.5.2               September 12, 2012
Visual Studio 2013          Dev12           12.0                18.00           2.0, 3.0, 3.5, 4.0, 4.5, 4.5.1, 4.5.2               October 17, 2013
Visual Studio 2015          Dev14           14.0                19.00           2.0, 3.0, 3.5, 4.0, 4.5, 4.5.1, 4.5.2, 4.6, 5.0     July 20, 2015
*/