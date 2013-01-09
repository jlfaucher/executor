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
int bitness=32;
char *cpu="X86";
#ifdef _WIN64
bitness=64;
cpu="X64";
#endif
printf("%s %s %i\n", mscver, cpu, bitness);
}