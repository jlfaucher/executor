#/*----------------------------------------------------------------------------*/
#/*                                                                            */
#/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
#/* Copyright (c) 2005-2009 Rexx Language Association. All rights reserved.    */
#/*                                                                            */
#/* This program and the accompanying materials are made available under       */
#/* the terms of the Common Public License v1.0 which accompanies this         */
#/* distribution. A copy is also available at the following address:           */
#/* http://www.oorexx.org/license.html                                         */
#/*                                                                            */
#/* Redistribution and use in source and binary forms, with or                 */
#/* without modification, are permitted provided that the following            */
#/* conditions are met:                                                        */
#/*                                                                            */
#/* Redistributions of source code must retain the above copyright             */
#/* notice, this list of conditions and the following disclaimer.              */
#/* Redistributions in binary form must reproduce the above copyright          */
#/* notice, this list of conditions and the following disclaimer in            */
#/* the documentation and/or other materials provided with the distribution.   */
#/*                                                                            */
#/* Neither the name of Rexx Language Association nor the names                */
#/* of its contributors may be used to endorse or promote products             */
#/* derived from this software without specific prior written permission.      */
#/*                                                                            */
#/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */
#/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */
#/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */
#/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */
#/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */
#/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
#/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */
#/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */
#/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */
#/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */
#/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */
#/*                                                                            */
#/*----------------------------------------------------------------------------*/

# NOTE:  /OPT:REF in linker flags eliminates unreferenced functions and data.
#        Need to use /Gy when compiling to use /OPT:REF.

!include "$(OR_LIBSRC)\ORXWIN32.MAK"
C=cl
OPTIONS= $(cflags_common) $(cflags_dll) $(OR_ORYXINCL)
OR_LIB=$(OR_OUTDIR)

!IFNDEF WCHAR
WCHAR=0
!ENDIF

!IF "$(WCHAR)" == "0"
WCHAR_OPTIONS=
OOD_OUTDIR=$(OR_OUTDIR)
!ELSE
WCHAR_OPTIONS=/DUNICODE /D_UNICODE
OOD_OUTDIR=$(OR_OUTDIR)\wchar
!ENDIF

# NMAKE-compatible MAKE file for ooDialog
all:  $(OOD_OUTDIR) $(OOD_OUTDIR)\oodialog.dll

# All Source Files
SOURCEF= $(OOD_OUTDIR)\APICommon.obj $(OOD_OUTDIR)\oodBarControls.obj $(OOD_OUTDIR)\oodBaseDialog.obj $(OOD_OUTDIR)\oodBasicControls.obj \
         $(OOD_OUTDIR)\oodCommon.obj $(OOD_OUTDIR)\oodControl.obj $(OOD_OUTDIR)\oodData.obj $(OOD_OUTDIR)\oodDeviceGraphics.obj \
         $(OOD_OUTDIR)\ooDialog.obj $(OOD_OUTDIR)\oodMenu.obj $(OOD_OUTDIR)\oodMessaging.obj $(OOD_OUTDIR)\oodPackageEntry.obj \
         $(OOD_OUTDIR)\oodResources.obj $(OOD_OUTDIR)\oodRoutines.obj $(OOD_OUTDIR)\oodUser.obj $(OOD_OUTDIR)\oodUtilities.obj \
         $(OOD_OUTDIR)\oodViewControls.obj $(OOD_OUTDIR)\rxwchar.obj $(OOD_OUTDIR)\oodialog.res

# All Source files that include APICommon.hpp
APICOMMON_SOURCEF = $(OOD_OUTDIR)\APICommon.obj $(OOD_OUTDIR)\oodBaseDialog.obj $(OOD_OUTDIR)\oodBasicControls.obj \
                    $(OOD_OUTDIR)\oodCommon.obj $(OOD_OUTDIR)\oodControl.obj $(OOD_OUTDIR)\oodData.obj \
                    $(OOD_OUTDIR)\oodDeviceGraphics.obj $(OOD_OUTDIR)\ooDialog.obj $(OOD_OUTDIR)\oodMenu.obj \
                    $(OOD_OUTDIR)\oodMessaging.obj $(OOD_OUTDIR)\oodRoutines.obj $(OOD_OUTDIR)\oodUser.obj $(OOD_OUTDIR)\oodUtilities.obj \
                    $(OOD_OUTDIR)\oodViewControls.obj

# All Source files that include oodCommon.hpp
COMMON_SOURCEF = $(OOD_OUTDIR)\oodBarControls.obj $(OOD_OUTDIR)\oodBaseDialog.obj $(OOD_OUTDIR)\oodBasicControls.obj \
                 $(OOD_OUTDIR)\oodCommon.obj $(OOD_OUTDIR)\oodData.obj $(OOD_OUTDIR)\oodDeviceGraphics.obj $(OOD_OUTDIR)\oodMenu.obj \
                 $(OOD_OUTDIR)\oodMessaging.obj $(OOD_OUTDIR)\oodRoutines.obj $(OOD_OUTDIR)\oodUser.obj $(OOD_OUTDIR)\oodUtilities.obj \
                 $(OOD_OUTDIR)\oodViewControls.obj

# All Source files that include oodDeviceGraphics.hpp
OODEVICECONTEXT_SOURCEF = $(OOD_OUTDIR)\oodBaseDialog.obj $(OOD_OUTDIR)\oodControl.cpp $(OOD_OUTDIR)\ooDeviceGraphics.cpp \
                          $(OOD_OUTDIR)\ooDialog.cpp $(OOD_OUTDIR)\oodRoutines.obj$(OOD_OUTDIR)\oodMessaging.obj  $(OOD_OUTDIR)\oodUser.obj \
                          $(OOD_OUTDIR)\oodUtilities.obj

# All Source files that include oodData.hpp
OODDATA_SOURCEF = $(OOD_OUTDIR)\oodBaseDialog.obj $(OOD_OUTDIR)\ooDialog.cpp $(OOD_OUTDIR)\oodData.obj $(OOD_OUTDIR)\oodUser.obj

# All Source files that include oodControl.hpp
OODCONTROL_SOURCEF = $(OOD_OUTDIR)\oodBarControls.obj $(OOD_OUTDIR)\oodBaseDialog.obj $(OOD_OUTDIR)\oodBasicControls.obj \
                     $(OOD_OUTDIR)\oodControl.obj $(OOD_OUTDIR)\oodData.obj $(OOD_OUTDIR)\ooDialog.cpp $(OOD_OUTDIR)\oodUser.obj \
                     $(OOD_OUTDIR)\oodViewControls.obj

# All Source files that include oodMessaging.hpp
OODMESSAGING_SOURCEF = $(OOD_OUTDIR)\oodBaseDialog.obj $(OOD_OUTDIR)\oodControl.obj $(OOD_OUTDIR)\oodDeviceGraphics.obj \
                       $(OOD_OUTDIR)\ooDialog.obj $(OOD_OUTDIR)\oodMenu.obj $(OOD_OUTDIR)\oodMessaging.obj $(OOD_OUTDIR)\oodUser.obj

# All Source files that include oodResources.hpp
OODRESOURCES_SOURCEF = $(OOD_OUTDIR)\oodBasicControls.obj $(OOD_OUTDIR)\oodResources.obj $(OOD_OUTDIR)\oodViewControls.obj

# All Source files that include rxwchar.hpp
RXWCHAR_SOURCEF = $(OOD_OUTDIR)\rxwchar.cpp oodialog.hpp

.c{$(OOD_OUTDIR)}.obj:
    $(C) $(OPTIONS) $(WCHAR_OPTIONS) /DINCL_32  -c $(@B).c /Fo$(OOD_OUTDIR)\$(@B).obj

#
# *** .cpp -> .obj rules
#
{$(OR_OODIALOGSRC)}.cpp{$(OOD_OUTDIR)}.obj:
    @ECHO .
    @ECHO Compiling $(@B).cpp
    $(OR_CC) $(cflags_common) $(WCHAR_OPTIONS) $(cflags_dll) /Fo$(OOD_OUTDIR)\$(@B).obj $(OR_ORYXINCL)  $(OR_OODIALOGSRC)\$(@B).cpp


{$(OR_OODIALOGSRC)}.c{$(OOD_OUTDIR)}.obj:
    @ECHO .
    @ECHO Compiling $(@B).c
    $(OR_CC) $(cflags_common) $(WCHAR_OPTIONS) $(cflags_dll) /Fo$(OOD_OUTDIR)\$(@B).obj $(OR_ORYXINCL)  $(OR_OODIALOGSRC)\$(@B).c


$(OOD_OUTDIR)\oodialog.dll:     $(SOURCEF)
    $(OR_LINK) \
        $(SOURCEF)  \
    $(lflags_common) $(lflags_dll) \
    $(OR_LIB)\rexx.lib \
    $(OR_LIB)\rexxapi.lib \
    WINMM.LIB \
    COMDLG32.LIB \
    COMCTL32.LIB \
    shlwapi.lib \
    -def:$(OR_OODIALOGSRC)\ooDialog.def \
    -out:$(OOD_OUTDIR)\$(@B).dll


# Update the version information block
$(OOD_OUTDIR)\oodialog.res: $(OR_OODIALOGSRC)\oodialog.rc
    @ECHO .
    @ECHO ResourceCompiling $(@B).res
        $(rc) $(rcflags_common) /i $(OR_OODIALOGSRC) /i $(OR_WINKERNELSRC) -r -fo$(OOD_OUTDIR)\$(@B).res $(OR_OODIALOGSRC)\$(@B).rc

# Source .obj files that should be recompiled when header file(s) change.
$(SOURCEF) : ooDialog.hpp
$(COMMON_SOURCEF) : oodCommon.hpp
$(APICOMMON_SOURCEF) : APICommon.hpp
$(OODEVICECONTEXT_SOURCEF) : oodDeviceGraphics.hpp
$(OODDATA_SOURCEF) : oodData.hpp
$(OODCONTROL_SOURCEF) : oodControl.hpp
$(OODMESSAGING_SOURCEF) : oodMessaging.hpp
$(OODRESOURCES_SOURCEF) : oodResources.hpp
$(OOD_OUTDIR)\oodMenu.obj : oodMenu.hpp
$(RXWCHAR_SOURCEF) : rxwchar.hpp

$(OOD_OUTDIR):
    mkdir $(OOD_OUTDIR)
    
clean:
    del $(SOURCEF)
    del $(OOD_OUTDIR)\oodialog.lib
    del $(OOD_OUTDIR)\oodialog.exp
    del $(OOD_OUTDIR)\oodialog.map
    del $(OOD_OUTDIR)\oodialog.pdb
    del $(OOD_OUTDIR)\oodialog.dll

