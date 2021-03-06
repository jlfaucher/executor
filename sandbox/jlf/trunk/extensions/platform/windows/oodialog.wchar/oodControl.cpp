/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2010 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.oorexx.org/license.html                                         */
/*                                                                            */
/* Redistribution and use in source and binary forms, with or                 */
/* without modification, are permitted provided that the following            */
/* conditions are met:                                                        */
/*                                                                            */
/* Redistributions of source code must retain the above copyright             */
/* notice, this list of conditions and the following disclaimer.              */
/* Redistributions in binary form must reproduce the above copyright          */
/* notice, this list of conditions and the following disclaimer in            */
/* the documentation and/or other materials provided with the distribution.   */
/*                                                                            */
/* Neither the name of Rexx Language Association nor the names                */
/* of its contributors may be used to endorse or promote products             */
/* derived from this software without specific prior written permission.      */
/*                                                                            */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */
/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */
/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */
/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */
/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */
/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */
/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */
/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */
/*                                                                            */
/*----------------------------------------------------------------------------*/

/**
 * oodControl.cpp
 *
 * Contains the base classes used for an object that represents a Windows
 * Control.
 */
#include "ooDialog.hpp"     // Must be first, includes windows.h, commctrl.h, and oorexxapi.h

#include <shlwapi.h>
#include <OleAcc.h>
#include "APICommon.hpp"
#include "oodCommon.hpp"
#include "oodMessaging.hpp"
#include "oodDeviceGraphics.hpp"
#include "oodData.hpp"
#include "oodControl.hpp"

const rxcharT *controlType2winName(oodControl_t control)
{
    switch ( control )
    {
        case winStatic :               return WC_STATIC;
        case winPushButton :           return WC_BUTTON;
        case winRadioButton :          return WC_BUTTON;
        case winCheckBox :             return WC_BUTTON;
        case winGroupBox :             return WC_BUTTON;
        case winEdit :                 return WC_EDIT;
        case winListBox :              return WC_LISTBOX;
        case winComboBox :             return WC_COMBOBOX;
        case winScrollBar :            return WC_SCROLLBAR;
        case winTreeView :             return WC_TREEVIEW;
        case winListView :             return WC_LISTVIEW;
        case winTab :                  return WC_TABCONTROL;
        case winProgressBar :          return PROGRESS_CLASS;
        case winTrackBar :             return TRACKBAR_CLASS;
        case winMonthCalendar :        return MONTHCAL_CLASS;
        case winDateTimePicker :       return DATETIMEPICK_CLASS;
        case winUpDown :               return UPDOWN_CLASS;
        default :                      return _T("");
    }
}


const char *controlType2className(oodControl_t control)
{
    switch ( control )
    {
        case winStatic :               return "STATICCONTROL";
        case winPushButton :           return "BUTTONCONTROL";
        case winRadioButton :          return "RADIOBUTTON";
        case winCheckBox :             return "CHECKBOX";
        case winGroupBox :             return "GROUPBOX";
        case winEdit :                 return "EDITCONTROL";
        case winListBox :              return "LISTBOX";
        case winComboBox :             return "COMBOBOX";
        case winScrollBar :            return "SCROLLBAR";
        case winTreeView :             return "TREECONTROL";
        case winListView :             return "LISTVIEW";
        case winTab :                  return "TABCONTROL";
        case winProgressBar :          return "PROGRESSBAR";
        case winTrackBar :             return "SLIDERCONTROL";
        case winMonthCalendar :        return "MONTHCALENDAR";
        case winDateTimePicker :       return "DATETIMEPICKER";
        case winUpDown :               return "UPDOWN";
        default :                      return "";
    }
}


oodControl_t winName2controlType(const rxcharT *className)
{
    if (      _tcscmp(className, WC_STATIC         ) == 0 ) return winStatic;
    else if ( _tcscmp(className, WC_BUTTON         ) == 0 ) return winPushButton;
    else if ( _tcscmp(className, WC_EDIT           ) == 0 ) return winEdit;
    else if ( _tcscmp(className, WC_LISTBOX        ) == 0 ) return winListBox;
    else if ( _tcscmp(className, WC_COMBOBOX       ) == 0 ) return winComboBox;
    else if ( _tcscmp(className, WC_SCROLLBAR      ) == 0 ) return winScrollBar;
    else if ( _tcscmp(className, WC_TREEVIEW       ) == 0 ) return winTreeView;
    else if ( _tcscmp(className, WC_LISTVIEW       ) == 0 ) return winListView;
    else if ( _tcscmp(className, WC_TABCONTROL     ) == 0 ) return winTab;
    else if ( _tcscmp(className, PROGRESS_CLASS    ) == 0 ) return winProgressBar;
    else if ( _tcscmp(className, TRACKBAR_CLASS    ) == 0 ) return winTrackBar;
    else if ( _tcscmp(className, MONTHCAL_CLASS    ) == 0 ) return winMonthCalendar;
    else if ( _tcscmp(className, DATETIMEPICK_CLASS) == 0 ) return winDateTimePicker;
    else if ( _tcscmp(className, UPDOWN_CLASS      ) == 0 ) return winUpDown;
    else
    {
        return winUnknown;
    }
}

oodControl_t control2controlType(HWND hControl)
{
    oodControl_t type = winUnknown;

    TCHAR buf[64];
    if ( RealGetWindowClass(hControl, buf, RXITEMCOUNT(buf)) )
    {
        type = winName2controlType(buf);
        if ( type == winPushButton )
        {
            BUTTONTYPE buttonType = getButtonInfo(hControl, NULL, NULL);
            if ( buttonType == check )
            {
                type = winCheckBox;
            }
            else if ( buttonType == radio )
            {
                type = winRadioButton;
            }
            else if ( buttonType == group )
            {
                type = winGroupBox;
            }
        }
    }

    return type;
}

/**
 * Determine if a dialog control belongs to the specified dialog control class.
 *
 * @param hControl   Handle to the control.
 * @param control    One of the oodControl types specifying the class to check
 *                   for.
 *
 * @return True if the dialog control is the type specified, otherwise false.
 */
bool isControlMatch(HWND hControl, oodControl_t control)
{
    rxcharT buf[64];
    const rxcharT *pClass = controlType2winName(control);

    if ( ! RealGetWindowClass(hControl, buf, RXITEMCOUNT(buf)) || _tcscmp(buf, pClass) != 0 )
    {
        return false;
    }

    if ( control == winCheckBox || control == winRadioButton || control == winGroupBox )
    {
        BUTTONTYPE type = getButtonInfo(hControl, NULL, NULL);
        switch ( control )
        {
            case winCheckBox :
                if ( type != check )
                {
                    return false;
                }
                break;
            case winRadioButton :
                if ( type != radio )
                {
                    return false;
                }
                break;
            case winGroupBox :
                if ( type != group )
                {
                    return false;
                }
                break;
        }
    }
    return true;
}

/**
 * Resolves a string to the type of windows control it is.  The function only
 * compares enough letters to determine unequivocally if it matches one of the
 * supported dialog controls.
 *
 * Example:
 *
 * CSTRING msgName = "CONNECTEDITDATA";
 * oodControl_t ctrl = oodName2controlType(msgName + 7);
 *
 * @param name   The name to resolve.
 *
 * @return The windows control type.  winUnknown is returned if there is no
 *         match.
 *
 * @remarks  There are some generic message names such as getControlDataPage
 *           that need to match to winUnknown.  CO is not sufficient to
 *           distinguish between comboBox and control.
 */
oodControl_t oodName2controlType(CSTRING name)
{
    if      ( StrCmpNA(name, "CHECKBOX", 3      ) == 0 ) return winCheckBox;
    else if ( StrCmpNA(name, "COMBOBOX", 3      ) == 0 ) return winComboBox;
    else if ( StrCmpNA(name, "DATETIMEPICKER", 1) == 0 ) return winDateTimePicker;
    else if ( StrCmpNA(name, "EDIT", 1          ) == 0 ) return winEdit;
    else if ( StrCmpNA(name, "GROUPBOX", 1      ) == 0 ) return winGroupBox;
    else if ( StrCmpNA(name, "LISTBOX", 5       ) == 0 ) return winListBox;
    else if ( StrCmpNA(name, "LISTVIEW", 5      ) == 0 ) return winListView;
    else if ( StrCmpNA(name, "MONTHCALENDAR", 1 ) == 0 ) return winMonthCalendar;
    else if ( StrCmpNA(name, "PROGRESSBAR", 2   ) == 0 ) return winProgressBar;
    else if ( StrCmpNA(name, "PUSHBUTTON", 2    ) == 0 ) return winPushButton;
    else if ( StrCmpNA(name, "RADIOBUTTON", 1   ) == 0 ) return winRadioButton;
    else if ( StrCmpNA(name, "SCROLLBAR", 2     ) == 0 ) return winScrollBar;
    else if ( StrCmpNA(name, "STATIC", 2        ) == 0 ) return winStatic;
    else if ( StrCmpNA(name, "TAB", 3           ) == 0 ) return winTab;
    else if ( StrCmpNA(name, "TRACKBAR", 3      ) == 0 ) return winTrackBar;
    else if ( StrCmpNA(name, "TREEVIEW", 3      ) == 0 ) return winTreeView;
    else if ( StrCmpNA(name, "UPDOWN", 1        ) == 0 ) return winUpDown;
    else return winUnknown;
}

RexxClassObject oodClass4controlType(RexxMethodContext *c, oodControl_t controlType)
{
    RexxClassObject controlClass = NULLOBJECT;
    const char *className = controlType2className(controlType);

    controlClass = rxGetContextClass(c, className);
    if ( controlClass == NULLOBJECT )
    {
        // An exception has been raised, which we don't want.  So, clear it.
        c->ClearCondition();
    }
    return controlClass;
}


/**
 * Produce a string representation of an "object state."
 *
 * Windows Accessibility uses "Object State Constants" to describe the states of
 * objects. An object is associated with one or more of these state values at
 * any time.
 *
 * This is used in a few places in ooDialog.  MSDN is not explicit in describing
 * what state constants are valid in these places.  So this function includes
 * all the valid state contstants, even though most of them are probably not
 * used.
 */
RexxStringObject objectStateToString(RexxMethodContext *c, uint32_t state)
{
    char buf[512];
    buf[0] = '\0';

    if ( state & STATE_SYSTEM_ANIMATED)        strcat(buf, "ANIMATED ");
    if ( state & STATE_SYSTEM_BUSY)            strcat(buf, "BUSY ");
    if ( state & STATE_SYSTEM_CHECKED)         strcat(buf, "CHECKED ");
    if ( state & STATE_SYSTEM_COLLAPSED)       strcat(buf, "COLLAPSED ");
    if ( state & STATE_SYSTEM_DEFAULT)         strcat(buf, "DEFAULT ");
    if ( state & STATE_SYSTEM_EXPANDED)        strcat(buf, "EXPANDED ");
    if ( state & STATE_SYSTEM_EXTSELECTABLE)   strcat(buf, "EXTSELECTABLE ");
    if ( state & STATE_SYSTEM_FLOATING)        strcat(buf, "FLOATING ");
    if ( state & STATE_SYSTEM_FOCUSABLE)       strcat(buf, "FOCUSABLE ");
    if ( state & STATE_SYSTEM_FOCUSED)         strcat(buf, "FOCUSED ");
    if ( state & STATE_SYSTEM_HASPOPUP)        strcat(buf, "HASPOPUP ");
    if ( state & STATE_SYSTEM_HOTTRACKED)      strcat(buf, "HOTTRACKED ");
    if ( state & STATE_SYSTEM_INDETERMINATE)   strcat(buf, "INDETERMINATE ");
    if ( state & STATE_SYSTEM_INVISIBLE)       strcat(buf, "INVISIBLE ");
    if ( state & STATE_SYSTEM_LINKED)          strcat(buf, "LINKED ");
    if ( state & STATE_SYSTEM_MARQUEED)        strcat(buf, "MARQUEED ");
    if ( state & STATE_SYSTEM_MOVEABLE)        strcat(buf, "MOVEABLE ");
    if ( state & STATE_SYSTEM_MULTISELECTABLE) strcat(buf, "MULTISELECTABLE ");
    if ( state & STATE_SYSTEM_OFFSCREEN)       strcat(buf, "OFFSCREEN ");
    if ( state & STATE_SYSTEM_PRESSED)         strcat(buf, "PRESSED ");
    if ( state & STATE_SYSTEM_PROTECTED)       strcat(buf, "PROTECTED ");
    if ( state & STATE_SYSTEM_READONLY)        strcat(buf, "READONLY ");
    if ( state & STATE_SYSTEM_SELECTABLE)      strcat(buf, "SELECTABLE ");
    if ( state & STATE_SYSTEM_SELECTED)        strcat(buf, "SELECTED ");
    if ( state & STATE_SYSTEM_SELFVOICING)     strcat(buf, "SELFVOICING ");
    if ( state & STATE_SYSTEM_SIZEABLE)        strcat(buf, "SIZEABLE ");
    if ( state & STATE_SYSTEM_TRAVERSED)       strcat(buf, "TRAVERSED ");
    if ( state & STATE_SYSTEM_UNAVAILABLE)     strcat(buf, "UNAVAILABLE ");

    *(buf + strlen(buf)) = '\0';
    return c->String(buf);
}


/**
 * Creates the Rexx dialog control object that represents the underlying Windows
 * dialog control.
 *
 * The control object can, almost, be created entirely from within the C / C++
 * environment.  A method context and the Rexx parent dialog are needed.
 *
 * @param c
 * @param hControl
 * @param hDlg
 * @param id
 * @param controlType
 * @param self
 * @param isCategoryDlg
 * @param putInBag
 *
 * @return RexxObjectPtr
 */
RexxObjectPtr createRexxControl(RexxMethodContext *c, HWND hControl, HWND hDlg, uint32_t id, oodControl_t controlType,
                                RexxObjectPtr self, bool isCategoryDlg, bool putInBag)
{
    RexxObjectPtr result = TheNilObj;

    // Check if the Rexx control object has already been instantiated.
    RexxObjectPtr rxControl = (RexxObjectPtr)getWindowPtr(hControl, GWLP_USERDATA);
    if ( rxControl != NULLOBJECT )
    {
        // Okay, this specific control has already had a control object
        // instantiated to represent it.  We return this object.
        result = rxControl;
        goto out;
    }

    // No pointer is stored in the user data area, so no control object has been
    // instantiated for this specific control, yet.  We instantiate one now and
    // then store the object in the user data area of the control window.

    PNEWCONTROLPARAMS pArgs = (PNEWCONTROLPARAMS)malloc(sizeof(NEWCONTROLPARAMS));
    if ( pArgs == NULL )
    {
        outOfMemoryException(c->threadContext);
        goto out;
    }

    RexxClassObject controlCls = oodClass4controlType(c, controlType);
    if ( controlCls == NULLOBJECT )
    {
        goto out;
    }

    pArgs->isCatDlg = isCategoryDlg;
    pArgs->controlType = controlType;
    pArgs->hwnd = hControl;
    pArgs->hwndDlg = hDlg;
    pArgs->id = id;
    pArgs->parentDlg = self;

    rxControl = c->SendMessage1(controlCls, "NEW", c->NewPointer(pArgs));
    free(pArgs);

    if ( rxControl != NULLOBJECT && rxControl != TheNilObj )
    {
        result = rxControl;
        setWindowPtr(hControl, GWLP_USERDATA, (LONG_PTR)result);

        if ( putInBag )
        {
            c->SendMessage1(self, "PUTCONTROL", result);
        }
    }

out:
    return result;
}


/**
 * Creates a Rexx dialog control from within a dialog method, using the window
 * handle of the control.
 *
 * In the Windows API it is easy to get the window handle of a control within a
 * dialog.  Normally we create Rexx dialog control objects from within Rexx
 * code, but it is convenient to be able to create the Rexx dialog control from
 * within native code.
 *
 * For instance, the Windows PropertySheet API gives you access to the window
 * handle of the tab control within the property sheet. From that handle we want
 * to be able to create a Rexx dialog control object to pass back into the Rexx
 * code.  Actually, this is the only case so far, but the code is made generic
 * in the assumption that other uses will come up.
 *
 * @param c      The method context we are operating in.
 * @param pcpbd  The CSelf struct of the dialog the control resides in.
 * @param hCtrl  The window handle of the companion control.  This can be null,
 *               in which case .nil is returned.
 * @param type   The type of the dialog control.
 *
 * @return A Rexx dialog control object that represents the dialo control, or
 *         .nil if the object is not instantiated.
 *
 * @remarks  The second from the last argument to createRexxControl() is true if
 *           the parent dialog is a CategoryDialog, otherwise false.  Since the
 *           CategoryDialog is now deprecated, we just pass false.
 */
RexxObjectPtr createControlFromHwnd(RexxMethodContext *c, pCPlainBaseDialog pcpbd, HWND hCtrl, oodControl_t type)
{
    RexxObjectPtr result = TheNilObj;

    if ( hCtrl == NULL )
    {
        goto done_out;
    }

    uint32_t id = (uint32_t)GetDlgCtrlID(hCtrl);

    result = createRexxControl(c, hCtrl, pcpbd->hDlg, id, type, pcpbd->rexxSelf, false, true);

done_out:
    return result;
}


/**
 * Creates a Rexx dialog control from within a dialog control method, using a
 * window handle of another control.
 *
 * In the Windows API for dialog controls, it is often possible to obtain the
 * handle of a "buddy" or "companion" control of a control.  For instance, with
 * the date time picker control, it is possible to obtain the window handle of
 * the drop down month calendar control. The 'originating' control is the date
 * time picker and the companion control is the month calendar.
 *
 * In these cases, this function will convert the window handle to a Rexx dialog
 * control object.
 *
 * @param c      The method context we are operating in.
 * @param pcdc   The CSelf struct of the originating control.
 * @param hCtrl  The window handle of the dialog control.  This can be null, in
 *               which case .nil is returned.
 * @param type   The type of the dialog control.
 *
 * @return A Rexx dialog control object that represents the underlying Windows
 *         dialog control, or .nil if the object is not instantiated.
 */
RexxObjectPtr createControlFromHwnd(RexxMethodContext *c, pCDialogControl pcdc, HWND hCtrl, oodControl_t type)
{
    RexxObjectPtr result = TheNilObj;

    if ( hCtrl == NULL )
    {
        goto done_out;
    }

    bool     isCategoryDlg = (c->IsOfType(pcdc->oDlg, "CATEGORYDIALOG") ? true : false);
    uint32_t id = (uint32_t)GetDlgCtrlID(hCtrl);

    result = createRexxControl(c, hCtrl, pcdc->hDlg, id, type, pcdc->oDlg, isCategoryDlg, false);

done_out:
    return result;
}


/**
 *  Methods for the .DialogControl class.
 */
#define DIALOGCONTROL_CLASS        "DialogControl"

/**
 * Validates that the CSelf pointer for a DialogControl object is not null.
 */
inline pCDialogControl validateDCCSelf(RexxMethodContext *c, void *pcdc)
{
    if ( pcdc == NULL )
    {
        baseClassIntializationException(c);
    }
    return (pCDialogControl)pcdc;
}



/**
 * Free subclass data for the KeyEventProc subclass.
 *
 * @assumes  The caller passed in a proper SUBCLASSDATA pointer, i.e., that
 *           pData->pData points to a KEYEVENTDATA struct.
 */
void freeKeyEventData(SUBCLASSDATA *p)
{
    if ( p != NULL )
    {
        if ( p->pData != NULL )
        {
            KEYEVENTDATA *pKeyEvent = (KEYEVENTDATA *)p->pData;
            if ( pKeyEvent->method != NULL )
            {
                free(pKeyEvent->method);
            }
            LocalFree(pKeyEvent);
        }
        LocalFree(p);
    }
}


/**
 * Subclass procedure for any dialog control.  Reports key press events to
 * ooDialog for those key presses connected to an ooDialog method by the user.
 *
 * All messages are passed on unchanged to the control.
 *
 * processKeyPress() is used to actually decipher the key press data and set
 * up the ooDialog method invocation.  That function documents what is sent on
 * to the ooDialog method.
 */
LRESULT CALLBACK KeyPressSubclassProc(HWND hwnd, UINT msg, WPARAM wParam,
  LPARAM lParam, UINT_PTR id, DWORD_PTR dwData)
{
    SUBCLASSDATA *pSubclassData = (SUBCLASSDATA *)dwData;
    if ( ! pSubclassData )
    {
        return DefSubclassProc(hwnd, msg, wParam, lParam);
    }

    KEYPRESSDATA *pKeyData = (KEYPRESSDATA *)pSubclassData->pData;

    switch ( msg )
    {
        case WM_GETDLGCODE:
            /* Don't do anything for now. This message has some interesting
             * uses, perhaps a future enhancement.
             */
            break;

        case WM_SYSKEYDOWN:
            /* Sent when the alt key is down.  We need both WM_SYSKEYDOWN and
             * WM_KEYDOWN to catch everything that a keyboard hook catches.
             */
            if (  pKeyData->key[wParam] && !(lParam & KEY_RELEASED) && !(lParam & KEY_WASDOWN) )
            {
                processKeyPress(pSubclassData, wParam, lParam);
            }
            break;

        case WM_KEYDOWN:
            /* WM_KEYDOWN will never have KEY_RELEASED set. */
            if (  pKeyData->key[wParam] && !(lParam & KEY_WASDOWN) )
            {
                processKeyPress(pSubclassData, wParam, lParam);
            }
            break;

        case WM_NCDESTROY:
            /* The window is being destroyed, remove the subclass, clean up
             * memory.
             */
            RemoveWindowSubclass(hwnd, KeyPressSubclassProc, id);
            freeKeyPressData(pSubclassData);
            break;
    }
    return DefSubclassProc(hwnd, msg, wParam, lParam);
}

/**
 * Convenience function to remove the key press subclass procedure and free the
 * associated memory.
 *
 * If for some reason remvoing the subclass fails, we can not free the memory
 * because the subclass procedure may (will) still acess it.
 */
static BOOL removeKeyPressSubclass(SUBCLASSDATA *pData, HWND hDlg, INT id)
{
    BOOL success = SendMessage(hDlg, WM_USER_SUBCLASS_REMOVE, (WPARAM)&KeyPressSubclassProc, (LPARAM)id) != 0;
    if ( success )
    {
        freeKeyPressData(pData);
    }
    return success;
}


static keyPressErr_t connectKeyPressSubclass(RexxMethodContext *c, CSTRING methodName, CSTRING keys, CSTRING filter,
                                             pCDialogControl pcdc)
{
    keyPressErr_t result = nameErr;
    if ( ! requiredComCtl32Version(c, c->GetMessageName(), COMCTL32_6_0) )
    {
        goto done_out;
    }
    if ( *methodName == '\0' )
    {
        c->RaiseException2(Rexx_Error_Invalid_argument_null, c->String("positional"), TheOneObj);
        goto done_out;
    }
    if ( *keys == '\0' )
    {
        c->RaiseException2(Rexx_Error_Invalid_argument_null, c->String("positional"), TheTwoObj);
        goto done_out;
    }

    SUBCLASSDATA *pSubclassData = NULL;
    BOOL success = GetWindowSubclass(pcdc->hCtrl, KeyPressSubclassProc, pcdc->id, (DWORD_PTR *)&pSubclassData);

    // If pSubclassData is null, the subclass is not installed.  The data block needs to
    // be allocated and then install the subclass.  Otherwise, just update the
    // data block.
    if ( pSubclassData == NULL )
    {
        pSubclassData = (SUBCLASSDATA *)LocalAlloc(LPTR, sizeof(SUBCLASSDATA));
        if ( pSubclassData == NULL )
        {
            result = memoryErr;
            goto done_out;
        }

        KEYPRESSDATA *pKeyPressData = (KEYPRESSDATA *)LocalAlloc(LPTR, sizeof(KEYPRESSDATA));
        if ( pKeyPressData == NULL )
        {
            LocalFree(pSubclassData);
            result = memoryErr;
            goto done_out;
        }

        pSubclassData->hCtrl = pcdc->hCtrl;
        pSubclassData->uID = pcdc->id;
        pSubclassData->pData = pKeyPressData;

        // The subclass is not installed, abort and clean up if there is any
        // error in setKeyPressData()
        result = setKeyPressData(pKeyPressData, methodName, keys, filter);
        if ( result == noErr )
        {
            if ( SendMessage(pcdc->hDlg, WM_USER_SUBCLASS, (WPARAM)KeyPressSubclassProc, (LPARAM)pSubclassData) == 0 )
            {
                // Subclassing failed, we need to clean up memory, or else it
                // will leak.
                freeKeyPressData(pSubclassData);
                result = winAPIErr;
            }
        }
        else
        {
            freeKeyPressData(pSubclassData);
        }
    }
    else
    {
        // The subclass is installed, it has a valid key press data table.  If
        // there are any errors, the error is reported, but the existing data
        // table is left alone.
        if ( success )
        {
            result = setKeyPressData((KEYPRESSDATA *)pSubclassData->pData, methodName, keys, filter);
        }
        else
        {
            result = winAPIErr;
        }
    }

done_out:
    return result;
}


/**
 * Tests if the key code is considered an extended key for the purposes of
 * connectKeyEvent().
 *
 * Note that PageUp is VK_PRIOR and PageDown is VK_NEXT.
 *
 *
 * @param wParam
 *
 * @return bool
 */
static inline bool isExtendedKeyEvent(WPARAM wParam)
{
    return (wParam >= VK_PRIOR && wParam <= VK_DOWN) || wParam == VK_INSERT || wParam == VK_DELETE;
}

/**
 * Subclass procedure for any dialog control that uses connectKeyEvent().
 *
 * Some what experimental for now.  To begin with, this is kept minimal to allow
 * for future expansion.
 *
 * When connected, (which would be the only time this subclass procedure is in
 * use,) all WM_CHAR messages are sent to the Rexx method.  The method can reply
 * false to NOT send the message on to the subclassed control, reply true to
 * pass the message on unchanged, and reply with a virtual key code which
 * replaces the actual virtual key code.
 *
 * In addition, the extended key codes HOME END INS DEL PAGEUP PAGEDOWN and the
 * arrow keys are sent to the Rexx method.  For these, for now, the user can
 * reply false to suppress the message being sent to the subclassed control.
 * And true to send it on to the subclassed control, but actually, anything
 * other than false is treated as true.
 *
 * @remarks  We know, or think we know, that this function is running in the
 *           thread of the dialog message loop.  So, for a thread context, we
 *           just grab it from the pCPlainBaseDialg.
 */
LRESULT CALLBACK KeyEventProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam, UINT_PTR id, DWORD_PTR dwData)
{
    SUBCLASSDATA *pSubclassData = (SUBCLASSDATA *)dwData;
    if ( ! pSubclassData )
    {
        return DefSubclassProc(hwnd, msg, wParam, lParam);
    }
    KEYEVENTDATA *pKeyEvent = (KEYEVENTDATA *)pSubclassData->pData;

    switch ( msg )
    {
        case WM_KEYDOWN:
            if (  lParam & KEY_ISEXTENDED && isExtendedKeyEvent(wParam) )
            {
                RexxThreadContext *c = pSubclassData->dlgProcContext;
                RexxArrayObject args = getKeyEventRexxArgs(c, wParam);

                RexxObjectPtr reply = c->SendMessage(pSubclassData->rexxDialog, pKeyEvent->method, args);

                if ( ! checkForCondition(c, false) && reply == TheFalseObj )
                {
                    return TRUE;
                }
            }
            break;

        case WM_CHAR:
        {
            RexxThreadContext *c = pSubclassData->dlgProcContext;
            RexxArrayObject args = getKeyEventRexxArgs(c, wParam);

            RexxObjectPtr reply = c->SendMessage(pSubclassData->rexxDialog, pKeyEvent->method, args);

            if ( ! checkForCondition(c, false) && reply != NULLOBJECT )
            {
                if ( reply == TheFalseObj )
                {
                    return TRUE;
                }
                else if ( reply != TheTrueObj )
                {
                    // TheTrueObj just means don't do anything, so DefSubClassProc() handles it.
                    uint32_t chr;
                    if ( c->UnsignedInt32(reply, &chr) )
                    {
                        return DefSubclassProc(hwnd, msg, (WPARAM)chr, lParam);
                    }
                }
            }
        } break;

        case WM_NCDESTROY:
            /* The window is being destroyed, remove the subclass, clean up
             * memory.
             */
            RemoveWindowSubclass(hwnd, KeyEventProc, id);
            freeKeyEventData(pSubclassData);
            break;
    }
    return DefSubclassProc(hwnd, msg, wParam, lParam);
}

RexxMethod1(RexxObjectPtr, dlgctrl_init_cls, OSELF, self)
{
    if ( isOfClassType(context, self, DIALOGCONTROL_CLASS) )
    {
        TheDialogControlClass = (RexxClassObject)self;
        context->RequestGlobalReference(TheDialogControlClass);
    }
    return NULLOBJECT;
}


/** DialogControl::new()
 *
 *
 */
RexxMethod3(RexxObjectPtr, dlgctrl_new_cls, OPTIONAL_RexxObjectPtr, args, OSELF, self, SUPER, superClass)
{
    RexxMethodContext *c = context;
    RexxObjectPtr control = TheNilObj;

    if ( argumentOmitted(1) || ! c->IsPointer(args) )
    {
        goto done_out;
    }

    // Forwarding this message to the super class will also invoke the init()
    // method of the control instance object.
    control = c->ForwardMessage(NULLOBJECT, NULL, superClass, NULL);
    if ( control == NULLOBJECT )
    {
        control = TheNilObj;
    }

done_out:
    return control;
}

/** DialogControl::init()
 *
 *  The base init() for all dialog control objects.
 *
 *  Initializes the WindowBase and sets the 3 attributes: id, hDlg, and oDlg.
 *  These attributes are 'get' only attributes and can not be changed.
 */
RexxMethod2(uint32_t, dlgctrl_init, OPTIONAL_POINTER, args, OSELF, self)
{
    RexxMethodContext *c = context;
    uint32_t result = 1;

    if ( argumentOmitted(1) || args == NULL )
    {
        goto done_out;
    }

    // Set up for the DialogControl CSelf.
    RexxBufferObject cdcBuf = c->NewBuffer(sizeof(CDialogControl));
    if ( cdcBuf == NULLOBJECT )
    {
        goto done_out;
    }

    // Do the WindowBase initialization.
    pCWindowBase wbCSelf;
    PNEWCONTROLPARAMS params = (PNEWCONTROLPARAMS)args;
    if ( ! initWindowBase(context, params->hwnd, self, &wbCSelf) )
    {
        goto done_out;
    }

    if ( ! initWindowExtensions(context, self, params->hwnd, wbCSelf, NULL) )
    {
        goto done_out;
    }


    pCDialogControl cdcCSelf = (pCDialogControl)c->BufferData(cdcBuf);
    memset(cdcCSelf, 0, sizeof(CDialogControl));

    cdcCSelf->controlType = params->controlType;
    cdcCSelf->lastItem = -1;
    cdcCSelf->wndBase = wbCSelf;
    cdcCSelf->rexxSelf = self;
    cdcCSelf->hCtrl = params->hwnd;
    cdcCSelf->id = params->id;
    cdcCSelf->hDlg = params->hwndDlg;
    cdcCSelf->oDlg = params->parentDlg;
    cdcCSelf->isInCategoryDlg = params->isCatDlg;

    context->SetObjectVariable("CSELF", cdcBuf);

    context->SetObjectVariable("ID", c->UnsignedInt32(params->id));
    context->SetObjectVariable("HDLG", pointer2string(context, params->hwndDlg));
    context->SetObjectVariable("ODLG", params->parentDlg);
    result = 0;

done_out:
    return result;
}

/** DialogControl::unInit()
 *
 *  Release the global reference for CWindowBase::rexxHwnd.
 *
 */
RexxMethod1(RexxObjectPtr, dlgctrl_unInit, CSELF, pCSelf)
{
    if ( pCSelf != NULLOBJECT )
    {
        pCWindowBase pcwb = ((pCDialogControl)pCSelf)->wndBase;
        if ( pcwb->rexxHwnd != TheZeroObj )
        {
            context->ReleaseGlobalReference(pcwb->rexxHwnd);
            pcwb->rexxHwnd = TheZeroObj;
        }
    } return NULLOBJECT;
}

RexxMethod1(RexxObjectPtr, dlgctrl_assignFocus, CSELF, pCSelf)
{
    SendMessage(((pCDialogControl)pCSelf)->hDlg, WM_NEXTDLGCTL, (WPARAM)((pCDialogControl)pCSelf)->hCtrl, TRUE);
    return TheZeroObj;
}

/** DialogControl::connectKeyEvent()
 *
 *  Experimental!  Connects a key event to a method in the Rexx dialog.
 *
 *
 *  @return True for success, false for error
 *
 *
 */
RexxMethod2(RexxObjectPtr, dlgctrl_connectKeyEvent, CSTRING, methodName, CSELF, pCSelf)
{
    oodResetSysErrCode(context->threadContext);

    RexxObjectPtr result = TheFalseObj;
    if ( ! requiredComCtl32Version(context, "connectKeyEvent", COMCTL32_6_0) )
    {
        goto done_out;
    }
    if ( *methodName == '\0' )
    {
        context->RaiseException2(Rexx_Error_Invalid_argument_null, context->String("positional"), TheOneObj);
        goto done_out;
    }

    pCDialogControl pcdc = (pCDialogControl)pCSelf;

    SUBCLASSDATA *pData = NULL;
    BOOL success = GetWindowSubclass(pcdc->hCtrl, KeyEventProc, pcdc->id, (DWORD_PTR *)&pData);

    // Nothing fancy yet, we could allow removing the subclass.

    if ( pData != NULL )
    {
        // The subclass is already installed, we call this an error.
        oodSetSysErrCode(context->threadContext, ERROR_NOT_SUPPORTED);
        goto done_out;
    }

    pData = (SUBCLASSDATA *)LocalAlloc(LPTR, sizeof(SUBCLASSDATA));
    if ( pData == NULL )
    {
        outOfMemoryException(context->threadContext);
        goto done_out;
    }

    KEYEVENTDATA *pKeyEventData = (KEYEVENTDATA *)LocalAlloc(LPTR, sizeof(KEYEVENTDATA));
    if ( pKeyEventData == NULL )
    {
        LocalFree(pData);
        outOfMemoryException(context->threadContext);
        goto done_out;
    }

    pKeyEventData->method = (char *)malloc(strlen(methodName) + 1);
    if ( pKeyEventData->method == NULL )
    {
        freeKeyEventData(pData);
        outOfMemoryException(context->threadContext);
        goto done_out;
    }
    strcpy(pKeyEventData->method, methodName);

    pData->hCtrl = pcdc->hCtrl;
    pData->uID = pcdc->id;
    pData->pData = pKeyEventData;

    if ( SendMessage(pcdc->hDlg, WM_USER_SUBCLASS, (WPARAM)KeyEventProc, (LPARAM)pData) == 0 )
    {
        // The subclass was not installed, free memeory, set error code.
        freeKeyEventData(pData);
        oodSetSysErrCode(context->threadContext, ERROR_SIGNAL_REFUSED);
        goto done_out;
    }

    result = TheTrueObj;

done_out:
    return result;
}

RexxMethod4(int32_t, dlgctrl_connectKeyPress, CSTRING, methodName, CSTRING, keys, OPTIONAL_CSTRING, filter,
            CSELF, pCSelf)
{
    keyPressErr_t result = connectKeyPressSubclass(context, methodName, keys, filter, (pCDialogControl)pCSelf);
    if ( result == memoryErr )
    {
        outOfMemoryException(context->threadContext);
    }
    return -(int32_t)result;
}

RexxMethod2(int32_t, dlgctrl_connectFKeyPress, CSTRING, methodName, CSELF, pCSelf)
{
    keyPressErr_t result = connectKeyPressSubclass(context, methodName, "FKEYS", NULL, (pCDialogControl)pCSelf);
    if ( result == memoryErr )
    {
        outOfMemoryException(context->threadContext);
    }
    return -(int32_t)result;
}

RexxMethod2(int32_t, dlgctrl_disconnectKeyPress, OPTIONAL_CSTRING, methodName, CSELF, pCSelf)
{
    char *tmpName = NULL;
    keyPressErr_t result = winAPIErr;

    if ( ! requiredComCtl32Version(context, context->GetMessageName(), COMCTL32_6_0) )
    {
        goto done_out;
    }

    pCDialogControl pcdc = (pCDialogControl)pCSelf;

    SUBCLASSDATA *pSubclassData = NULL;
    GetWindowSubclass(pcdc->hCtrl, KeyPressSubclassProc, pcdc->id, (DWORD_PTR *)&pSubclassData);

    // If pSubclassData is not null, the subclass is still installed, otherwise
    // the subclass has already been removed, (or never existed.)
    if ( pSubclassData != NULL )
    {
        // If no method name, remove the whole thing.
        if ( argumentOmitted(1) )
        {
            result = (removeKeyPressSubclass(pSubclassData, pcdc->hDlg, pcdc->id) ? noErr : winAPIErr);
            goto done_out;
        }

        // Have a method name, just remove that method from the mapping.
        tmpName = strdupupr(methodName);
        if ( tmpName == NULL )
        {
            result = memoryErr;
            goto done_out;
        }

        KEYPRESSDATA *pKeyPressData = (KEYPRESSDATA *)pSubclassData->pData;

        uint32_t index = seekKeyPressMethod(pKeyPressData, tmpName);
        if ( index == 0 )
        {
            result = nameErr;
            goto done_out;
        }

        // If only 1 method left, remove the subclass entirely.  Otherwise,
        // remove the subclass, fix up the subclass data block, then reinstall
        // the subclass.
        BOOL success = FALSE;
        if ( pKeyPressData->usedMethods == 1 )
        {
            success = removeKeyPressSubclass(pSubclassData, pcdc->hDlg, pcdc->id);
        }
        else
        {
            if ( SendMessage(pcdc->hDlg, WM_USER_SUBCLASS_REMOVE, (WPARAM)KeyPressSubclassProc, (LPARAM)pcdc->id) )
            {
                removeKeyPressMethod(pKeyPressData, index);
                success = (BOOL)SendMessage(pcdc->hDlg, WM_USER_SUBCLASS, (WPARAM)KeyPressSubclassProc, (LPARAM)pSubclassData);

                // If not success, then the subclass procedure is no longer
                // installed, (even though it was originally,) and the memory
                // will never be cleaned up, so clean it up now.
                if ( ! success )
                {
                    freeKeyPressData(pSubclassData);
                }
            }
        }
        result = (success ? noErr : winAPIErr);
    }

done_out:
    return -(int32_t)result;
}

RexxMethod2(logical_t, dlgctrl_hasKeyPressConnection, OPTIONAL_CSTRING, methodName, CSELF, pCSelf)
{
    if ( ComCtl32Version <  COMCTL32_6_0 )
    {
        return FALSE;
    }

    pCDialogControl pcdc = (pCDialogControl)pCSelf;

    SUBCLASSDATA *pData = NULL;
    if ( ! GetWindowSubclass(pcdc->hCtrl, KeyPressSubclassProc, pcdc->id, (DWORD_PTR *)&pData) )
    {
        return FALSE;
    }
    if ( pData == NULL )
    {
        return FALSE;
    }
    if ( argumentOmitted(1) )
    {
        return TRUE;
    }

    char *tmpName = strdupupr(methodName);
    if ( tmpName == NULL )
    {
        outOfMemoryException(context->threadContext);
        return FALSE;
    }

    BOOL exists = (seekKeyPressMethod((KEYPRESSDATA *)pData->pData, tmpName) > 0);
    free(tmpName);
    return exists;
}

/** DialogControl::tabstop()
 *  DialogControl::group()
 */
RexxMethod3(RexxObjectPtr, dlgctrl_tabGroup, OPTIONAL_logical_t, addStyle, NAME, method, CSELF, pCSelf)
{
    oodResetSysErrCode(context->threadContext);

    pCDialogControl pcdc = (pCDialogControl)pCSelf;
    if ( argumentOmitted(1) )
    {
        addStyle = TRUE;
    }
    uint32_t style = GetWindowLong(pcdc->hCtrl, GWL_STYLE);

    if ( *method == 'T' )
    {
        style = (addStyle ? (style | WS_TABSTOP) : (style & ~WS_TABSTOP));
    }
    else
    {
        style = (addStyle ? (style | WS_GROUP) : (style & ~WS_GROUP));
    }
    return setWindowStyle(context, pcdc->hCtrl, style);
}

/** DialogControl::clearRect()
 *
 *  Clears the rectangle specified in this control's client area.
 *
 *  @param  The coordinates of the rectangle.
 *    Form 1:  A .Rect object.
 *    Form 2:  A .Point object and a .Point object.
 *    Form 3:  x1, y1, y1, y2
 *
 *  @return  0 on success, 1 on error.
 *
 *  @note  Sets the .SystemErrorCode.
 */
RexxMethod2(RexxObjectPtr, dlgctrl_clearRect, ARGLIST, args, CSELF, pCSelf)
{
    oodResetSysErrCode(context->threadContext);

    RECT r = {0};
    size_t arraySize;
    size_t argsUsed;

    if ( ! getRectFromArglist(context, args, &r, true, 1, 4, &arraySize, &argsUsed) )
    {
        return TheOneObj;
    }
    if ( argsUsed < arraySize )
    {
        return tooManyArgsException(context->threadContext, argsUsed);
    }

    return clearRect(context, getDChCtrl(pCSelf), &r);
}

/** DialogControl::redrawRect()
 *
 *  Immediately redraws the specified rectangle in this control.
 *
 *  @param  The coordinates of the rectangle.
 *    Form 1:  A .Rect object.
 *    Form 2:  A .Point object and a .Point object.
 *    Form 3:  x1, y1, y1, y2
 *
 *  @param erase  [OPITONAL]  Whether the background should be erased first.
 *                The default is false.
 *
 *  @return  0 on success, 1 on error.
 *
 *  @note  Sets the .SystemErrorCode.
 */
RexxMethod2(RexxObjectPtr, dlgctrl_redrawRect, ARGLIST, args, CSELF, pCSelf)
{
    oodResetSysErrCode(context->threadContext);

    bool doErase = false;
    RECT r = {0};
    size_t arraySize;
    size_t argsUsed;

    if ( ! getRectFromArglist(context, args, &r, true, 1, 5, &arraySize, &argsUsed) )
    {
        return TheOneObj;
    }

    if ( arraySize > argsUsed + 1 )
    {
        return tooManyArgsException(context->threadContext, argsUsed + 1);
    }
    else if ( arraySize == (argsUsed + 1) )
    {
        // The object at argsUsed + 1 has to exist, otherwise arraySize would
        // equal argsUsed.
        RexxObjectPtr obj = context->ArrayAt(args, argsUsed + 1);

        logical_t erase;
        if ( ! context->Logical(obj, &erase) )
        {
            return notBooleanException(context->threadContext, argsUsed + 2, obj);
        }
        doErase = erase ? true : false;
    }

    return redrawRect(context, getDChCtrl(pCSelf), &r, doErase, true);
}


/** DialogControl::textSize()
 *
 *  Computes the width and height in pixels of the specified string of text when
 *  displayed by this control.
 *
 *  @param text  The text whose size is needed.
 *  @param size  [IN/OUT]  A .Size object, the calculated size is returned here.
 *
 *  @return  True on success, otherwise false.  It is unlikely that this
 *           function would fail.
 *
 *  @note  Sets the .SystemErrorCode.
 */
RexxMethod3(RexxObjectPtr, dlgctrl_textSize, CSTRING, text, RexxObjectPtr, _size, CSELF, pCSelf)
{
    oodResetSysErrCode(context->threadContext);
    RexxObjectPtr result = TheFalseObj;

    PSIZE size = rxGetSize(context, _size, 2);
    if ( size == NULL )
    {
        return result;
    }

    HWND hCtrl = getDChCtrl(pCSelf);
    HDC  hdc = GetDC(hCtrl);
    if ( hdc == NULL )
    {
        oodSetSysErrCode(context->threadContext);
        return result;
    }

    HFONT hFont = (HFONT)SendMessage(hCtrl, WM_GETFONT, 0, 0);
    if ( hFont == NULL )
    {
        // Font has not been set.
        hFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);
    }

    HFONT hOldFont = (HFONT)SelectObject(hdc, hFont);

    RXCA2T(text);
    if ( GetTextExtentPoint32(hdc, textT, (int)_tcslen(textT), size) != 0 )
    {
        result = TheTrueObj;
    }

    // Clean up.
    SelectObject(hdc, hOldFont);
    ReleaseDC(hCtrl, hdc);

    return result;
}

/** DialogControl::getTextSizeDlg()
 *
 *  Gets the size (width and height) in dialog units for any given string.
 *
 *  Since dialog units only have meaning for a specific dialog, normally the
 *  dialog units are calculated using the font of the dialog.  Optionally, this
 *  method will calculate the dialog units using a specified font.
 *
 *  @param  text         The string whose size is needed.
 *
 *  @param  fontName     Optional. If specified, use this font to calculate the
 *                       size.  The default is to use the font of the owner
 *                       dialog of the dialog control.  This would be the normal
 *                       usage.
 *
 *  @param  fontSize     Optional. If specified, use this font size with
 *                       fontName to calculate the size.  The default if omitted
 *                       is 8.  This arg is ignored if fontName is omitted.
 *
 *  @param  hwndFontSrc  Optional. Use this window's font to calculate the size.
 *                       This arg is always ignored if fontName is specified.
 *
 *  @return  A .Size object representing the area (width and height,) in dialog
 *           units, needed for the specified string.
 *
 *  @note  This method, mapped to a dialog control object, does not really make
 *         sense.  It, and its convoluted optional arguments, are maintained
 *         only for backward compatibility.  Its use should be strongly
 *         discouraged.
 */
RexxMethod5(RexxObjectPtr, dlgctrl_getTextSizeDlg, CSTRING, text, OPTIONAL_CSTRING, fontName,
            OPTIONAL_uint32_t, fontSize, OPTIONAL_POINTERSTRING, hwndFontSrc, CSELF, pCSelf)
{
    HWND hwndSrc = NULL;
    if ( argumentExists(2) )
    {
        if ( argumentOmitted(3) )
        {
            fontSize = DEFAULT_FONTSIZE;
        }
    }
    else if ( argumentExists(4) )
    {
        hwndSrc = (HWND)hwndFontSrc;
        if ( hwndFontSrc == NULL )
        {
            nullObjectException(context->threadContext, "window handle", 4);
            return NULLOBJECT;
        }
    }

    SIZE textSize = {0};
    RXCA2T(text);
    RXCA2T(fontName);
    if ( getTextSize(context, textT, fontNameT, fontSize, hwndSrc, getDCownerDlg(pCSelf), &textSize) )
    {
        return rxNewSize(context, textSize.cx, textSize.cy);
    }
    return NULLOBJECT;
}


/** DialogControl::captureMouse
 *
 *  Sets the mouse capture to this dialog control.  captureMouse() captures
 *  mouse input either when the mouse is over the control, or when the mouse
 *  button was pressed while the mouse was over the control and the button is
 *  still down. Only one window at a time can capture the mouse.
 *
 *  If the mouse cursor is over a window created by another thread, the system
 *  will direct mouse input to the specified window only if a mouse button is
 *  down.
 *
 *  @return  The window handle of the window that previously had captured the
 *           mouse, or the null handle if there was no such window.
 */
RexxMethod1(RexxObjectPtr, dlgctrl_captureMouse, CSELF, pCSelf)
{
    HWND oldCapture = (HWND)SendMessage(getDChDlg(pCSelf), WM_USER_GETSETCAPTURE, 1, (LPARAM)getDChCtrl(pCSelf));
    return pointer2string(context, oldCapture);
}

/** DialogControl::setColor()
 *  DialogControl::setSysColor
 */
RexxMethod4(logical_t, dlgctrl_setColor, int32_t, bkColor, OPTIONAL_int32_t, fgColor, NAME, method, CSELF, pCSelf)
{
    pCDialogControl pcdc = validateDCCSelf(context, pCSelf);
    if ( pcdc == NULL )
    {
        return 0;
    }
    return oodColorTable(context, dlgToCSelf(context, pcdc->oDlg), pcdc->id, bkColor,
                         argumentOmitted(2) ? -1 : fgColor, method[3] == 'S');
}

/** DialogControl::data()
 *
 *  Gets the "data" of the dialog control.
 *
 *  @return  The 'data' of the control.
 *
 *  @remarks  The original ooDialog code used the abstraction that there were
 *            only two objects involved.  The ooDialog object and the underlying
 *            Windows dialog.  The dialog controls were considered to be the
 *            'data' of the underlying Windows dialog.  In this abstraction, an
 *            edit control was part of the 'data' of the dialog and its 'data'
 *            was the edit control's text.  For a check box the 'data' is
 *            checked or not, etc..
 *
 */
RexxMethod1(RexxObjectPtr, dlgctrl_data, CSELF, pCSelf)
{
    pCDialogControl pcdc = (pCDialogControl)pCSelf;

    return getControlData(context, dlgToCSelf(context, pcdc->oDlg), pcdc->id, pcdc->hDlg, pcdc->controlType);
}

/** DialogControl::"data="
 *
 *  Sets the "data" of the dialog control.
 *
 *  @param  data  What to set the 'data' of the dialog control to.  Its meaning
 *                and format are dependent on the type of control.
 *
 *  @return  No return for "=" methods.
 *
 *  @remarks  See the remarks in dlgctrl_data above.
 */
RexxMethod2(RexxObjectPtr, dlgctrl_dataEquals, CSTRING, data, CSELF, pCSelf)
{
    pCDialogControl pcdc = (pCDialogControl)pCSelf;

    setControlData(context, dlgToCSelf(context, pcdc->oDlg), pcdc->id, data, pcdc->hDlg, pcdc->controlType);
    return NULLOBJECT;
}


