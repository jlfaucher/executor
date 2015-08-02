#/*******************************************************************************
# Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.
# Copyright (c) 2005-2012 Rexx Language Association. All rights reserved.
#
# This program and the accompanying materials are made available under
# the terms of the Common Public License v1.0 which accompanies this
# distribution. A copy is also available at the following address:
# http://www.oorexx.org/license.html
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in
# the documentation and/or other materials provided with the distribution.
#
# Neither the name of Rexx Language Association nor the names
# of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ******************************************************************************/

# NOTE: If for some reason there is a problem with setting the compiler version
# in this section, simply comment out everything except the setting of the
# proper VCPP macro for your system.
#
# These compiler defines allow the support of different versions of Mircrosoft's
# Visual C++ compiler.  The build has not necessarily been tested on all of the
# following versions, so some of the !IFDEF statements may need to be adjusted.
# VCPP == 14 ==> Visual C++ 2015
# VCPP == 12 ==> Visual C++ 2013
# VCPP == 11 ==> Visual C++ 2012
# VCPP == 10 ==> Visual C++ 2010
# VCPP ==  9 ==> Visual C++ 2008
# VCPP ==  8 ==> Visual C++ 2005
# VCPP ==  7 ==> Visual C++ 2003
# VCPP ==  6 ==> Visual C++ 6.0
#
!IF "$(MSVCVER)" == "14.0"
VCPP = 14
!ELSEIF "$(MSVCVER)" == "12.0"
VCPP = 12
!ELSEIF "$(MSVCVER)" == "11.0"
VCPP = 11
!ELSEIF "$(MSVCVER)" == "10.0"
VCPP = 10
!ELSEIF "$(MSVCVER)" == "9.0"
VCPP = 9
!ELSEIF "$(MSVCVER)" == "8.0"
VCPP = 8
!ELSEIF "$(MSVCVER)" == "7.0"
VCPP = 7
!ELSEIF "$(MSVCVER)" == "6.0"
VCPP = 6
!ELSE
!ERROR MSVCVER does not appear to be set. Check windows-build.txt for details
!ENDIF

# include the version information
!include "$(OR_MAINSRC)\oorexx.ver.incl"

# Make file include for WIN32 stuff
#
# Include the WIN32 standard include file
# Back out if no source/output dirs set
!IFNDEF OR_OUTDIR
!ERROR Build error, OR_OUTDIR not set
!ENDIF
!IFNDEF OR_ORYXINCL
!ERROR Build error, OR_ORYXINCL not set
!ENDIF

!IF "$(MKASM)" == "1"
MK_ASM=/FAcs /Fa$(OR_OUTDIR)\ASM\$(@B).asm
!ELSE
MK_ASM=
!ENDIF

OR_CC=cl
#
# set up the link command
#
OR_LINK=link
#
# set up the lib command
#
OR_IMPLIB=lib

# The ooRexx version definition for the compile flags.
VER_DEF = -DORX_VER=$(ORX_MAJOR) -DORX_REL=$(ORX_MINOR) -DORX_MOD=$(ORX_MOD_LVL) -DOOREXX_BLD=$(ORX_BLD_LVL) -DOOREXX_COPY_YEAR=\"$(ORX_COPY_YEAR)\"

# The start of the warning flags for the compile flags.
WARNING_FLAGS = /D_CRT_SECURE_NO_DEPRECATE /D_CRT_NONSTDC_NO_DEPRECATE

# Visual C++ 6.0 chokes on /Wp64 and in Visual C++ 9.0 the flag is deprecated
!IF $(VCPP) == 7
WARNING_FLAGS = /Wp64 $(WARNING_FLAGS)
!ELSEIF $(VCPP) == 8
WARNING_FLAGS = /Wp64 $(WARNING_FLAGS)
!ENDIF

# Turn on extra warnings by defining EXTRAWARNINGS to 1.
#
# /W4 gives a lint-like level of warnings.
# /wd<number> turns off warning 'number'  /wd4100 then turns off warning C4100.
#
# Uncomment the following, or alternatively set EXTRAWARNINGS as an environment
# variable.
# EXTRAWARNINGS = 1
!IF "$(EXTRAWARNINGS)" == "1"
WARNING_FLAGS = /W4 /wd4100 /wd4706 /wd4701 $(WARNING_FLAGS)
!ELSE
WARNING_FLAGS = /W3 $(WARNING_FLAGS)
!ENDIF

!IF $(VCPP) >= 8
Z_FLAGS =
!ELSE
Z_FLAGS = -Zd
!ENDIF

!IF $(VCPP) >= 14
HAVE_INTTYPES_H = /DHAVE_INTTYPES_H
!ENDIF

#
# set up the compile flags used in addition to the $(cflags) windows sets
#
# JLF notes :
# /O1 =  /Og /Os /Oy /Ob2 /Gs /GF /Gy       # smallest code in the majority of cases
# /O2 = /Og /Oi /Ot /Oy /Ob2 /Gs /GF /Gy    # fastest code in the majority of cases
# /Ox = /Og /Oi /Ot /Oy /Ob2                # favors execution speed over smaller size
# The /Oy option makes using the debugger more difficult because the compiler suppresses frame pointer information.
# Specify the /Oy- option after any other optimization compiler options (/Z7, /Zi, /ZI).
#
# /Gs       # Controls stack probes.
# /MD       # Creates a multithreaded DLL using MSVCRT.lib.
# /MDd      # Creates a debug multithreaded DLL using MSVCRTD.lib.
# /MT       # Creates a multithreaded executable file using LIBCMT.lib.
# /MTd      # Creates a debug multithreaded executable file using LIBCMTD.lib.
# /Zi       # Generates complete debugging information.

!IF "$(NODEBUG)" == "1"
#JLF : better to have debug infos in release build, may help in case of crash
#my_cdebug = $(Z_FLAGS)     -O2 /Gr /DNDEBUG               /Gs #Gs added by IH
my_cdebug =  $(Z_FLAGS) -Zi -O2 /Gr /DNDEBUG /DEBUGTYPE:CV /Gs #Gs added by IH
#added by IH for the NT queue pull problem
cflags_noopt=/nologo /D:_X86_ /DWIN32 $(WARNING_FLAGS) -c /Ox /Gf /Gr /DNDEBUG /Gs /DNULL=0
!ELSE
my_cdebug = -Zi /Od /Gr /D_DEBUG /DEBUGTYPE:CV
#/DCHECKOREFS /DMEMPROFILE /DVERBOSE_GC
#added by IH for the NT queue pull problem
cflags_noopt=/nologo /D:_X86_ /DWIN32 $(WARNING_FLAGS) -c $(my_cdebug) /DNULL=0
!ENDIF

cflags_common=/EHsc /nologo /D:_X86_ /DWIN32 $(VER_DEF) $(WARNING_FLAGS) -c $(my_cdebug) $(MK_ASM) $(RXDBG) /DNULL=0 $(HAVE_INTTYPES_H)

# ooRexx has always been using a statically linked CRT.
!IFDEF NOCRTDLL
# statically linked rexx
!IF "$(NODEBUG)" == "1"
cflags_dll=/MT
!ELSE
cflags_dll=/MTd
!ENDIF
!ELSE
!IF "$(NODEBUG)" == "1"
cflags_dll=/MD
!ELSE
cflags_dll=/MDd
!ENDIF
!ENDIF
cflags_exe=

!IFDEF CPLUSPLUS
Tp=/Tp
!ELSE
Tp=
!ENDIF

#
# set up the Link flags used in addition to the $(cflags) windows sets
#
# JLF notes :
# /opt:ref  # Eliminates functions and/or data that are never referenced
            # If /DEBUG is specified, the default for /OPT is NOREF (otherwise, it is REF),
            # and all functions are preserved in the image. To override this default and
            # optimize a debugging build, specify /OPT:REF.
            # The /OPT:REF option disables incremental linking.

!IF "$(NODEBUG)" == "1"
#JLF : better to have debug infos in release build, may help in case of crash
#my_ldebug =
my_ldebug =/DEBUG -debugtype:cv /opt:ref
!ELSE
my_ldebug = /PROFILE /DEBUG -debugtype:cv
!ENDIF

libs_common=user32.lib gdi32.lib winspool.lib comdlg32.lib comctl32.lib advapi32.lib delayimp.lib ole32.lib oleaut32.lib uuid.lib shell32.lib kernel32.lib

lflags_common= /MAP /NOLOGO $(my_ldebug) /SUBSYSTEM:Windows $(lflags_lib) $(libs_common)
lflags_common_console= /MAP /NOLOGO $(my_ldebug) /SUBSYSTEM:Console $(lflags_lib) user32.lib comdlg32.lib gdi32.lib kernel32.lib
lflags_dll = /DLL
lflags_exe =

#
# set up the rc flags used
#
!IF "$(CPU)" == "X64"
M_FILE = "rexx64.exe.manifest"
!ELSE
M_FILE = "rexx32.exe.manifest"
!ENDIF
rcflags_common=rc /DWIN32 -dOOREXX_VER=$(ORX_MAJOR) -dOOREXX_REL=$(ORX_MINOR) -dOOREXX_SUB=$(ORX_MOD_LVL) -dOOREXX_BLD=$(ORX_BLD_LVL) -dOOREXX_VER_STR=\"$(ORX_VER_STR)\" -dOOREXX_COPY_YEAR=\"$(ORX_COPY_YEAR)\" -dMANIFEST_FILE=$(M_FILE)

#
# *** Inference Rule for CPP->OBJ
# *** For .CPP files in OR_LIBSRC directory
#
{$(OR_COMMONPLATFORMSRC)}.cpp{$(OR_OUTDIR)}.obj:
    @ECHO .
    @ECHO Compiling $(**)
    $(OR_CC) $(cflags_common) $(cflags_dll)  /Fo$(@) $(OR_ORYXINCL) $(Tp)$(**)

#
# *** Inference Rule for CPP->OBJ
# *** For .CPP files in OR_LIBSRC directory
#
{$(OR_COMMONSRC)}.cpp{$(OR_OUTDIR)}.obj:
    @ECHO .
    @ECHO Compiling $(**)
    $(OR_CC) $(cflags_common) $(cflags_dll)  /Fo$(@) $(OR_ORYXINCL) $(Tp)$(**)

