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
 * oodViewControls.cpp
 *
 * Contains methods for the DateTimePicker, List-view, MonthCalendar, Tab, and
 * Tree-view controls.
 */
#include "ooDialog.hpp"     // Must be first, includes windows.h, commctrl.h, and oorexxapi.h

#include <shlwapi.h>

#include "APICommon.hpp"
#include "oodCommon.hpp"
#include "oodControl.hpp"
#include "oodResources.hpp"

/**
 * This is the window procedure used to subclass the edit control for both the
 * ListView and TreeControl objects.  It would be nice to convert this to use
 * the better API: SetWindowSubclass / RemoveWindowSubclass.
 *
 * TODO this whole subclassing thing is no longer needed.
 */
WNDPROC wpOldEditProc = NULL;

LONG_PTR CALLBACK CatchReturnSubProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch ( uMsg )
    {
        case WM_GETDLGCODE:
            return(DLGC_WANTALLKEYS | CallWindowProc(wpOldEditProc, hWnd, uMsg, wParam, lParam));

        case WM_CHAR:
            //Process this message to avoid message beeps.
            if ( (wParam == VK_RETURN) || (wParam == VK_ESCAPE) )
            {
                return 0;
            }
            else
            {
                return CallWindowProc(wpOldEditProc, hWnd,uMsg, wParam, lParam);
            }

        default:
            return CallWindowProc(wpOldEditProc, hWnd, uMsg, wParam, lParam);
    }
}


/** TreeControl::subclassEdit()
 *  TreeControl::restoreEditClass()
 *  ListView::subclassEdit()
 *  ListView::restoreEditClass()
 */
RexxMethod2(RexxObjectPtr, generic_subclassEdit, NAME, method, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    HWND hEdit;
    if ( ((pCDialogControl)pCSelf)->controlType == winTreeView )
    {
        hEdit = TreeView_GetEditControl(hwnd);
    }
    else
    {
        hEdit = ListView_GetEditControl(hwnd);
    }

    if ( *method == 'S' )
    {
        WNDPROC oldProc = (WNDPROC)setWindowPtr(hEdit, GWLP_WNDPROC, (LONG_PTR)CatchReturnSubProc);
        if ( oldProc != (WNDPROC)CatchReturnSubProc )
        {
            wpOldEditProc = oldProc;
        }
        return pointer2string(context, oldProc);
    }
    else
    {
        setWindowPtr(hEdit, GWLP_WNDPROC, (LONG_PTR)wpOldEditProc);
    }
    return TheZeroObj;
}


/**
 * Methods for the DateTimePicker class.
 */
#define DATETIMEPICKER_CLASS     "DateTimePicker"
#define DATETIMEPICKER_WINNAME   "Date and Time Picker"

// This is used for MonthCalendar also
#define SYSTEMTIME_MIN_YEAR               1601
#define SYSTEMTIME_RANGE_EXCEPTION_MSG    "indexes 1 and 2 of argument 1, the array object, can not both be missing"


/**
 * Converts a DateTime object to a SYSTEMTIME structure.  The fields of the
 * struct are filled in with the corresponding values of the DateTime object.
 *
 * @param c         The method context we are operating in.
 * @param dateTime  An ooRexx DateTime object.
 * @param sysTime   [in/out] The SYSTEMTIME struct to fill in.
 * @param part      Specifies which fields of the SYSTEMTIME struct fill in.
 *                  Unspecified fields are left alone.
 *
 * @return True if no errors, false if a condition is raised.
 *
 * @note  Assumes the dateTime object is not null and is actually a DateTime
 *        object.
 *
 * @note The year part of the DateTime object must be in range for a SYSTEMTIME.
 *       The lower range for SYSTEMTIME is 1601. The upper range of a DateTime
 *       object is 9999 and of a SYSTEMTIME 30827, so we only check the lower
 *       range.  An exception is raised if out of range.
 */
bool dt2sysTime(RexxThreadContext *c, RexxObjectPtr dateTime, SYSTEMTIME *sysTime, DateTimePart part)
{
    if ( part == dtNow )
    {
        GetLocalTime(sysTime);
    }
    else
    {
        // format: yyyy-dd-mmThh:mm:ss.uuuuuu.
        RexxObjectPtr dt = c->SendMessage0(dateTime, "ISODATE");
        const char *isoDate = c->CString(dt);

        sscanf(isoDate, "%4hu-%2hu-%2huT%2hu:%2hu:%2hu.%3hu", &(*sysTime).wYear, &(*sysTime).wMonth, &(*sysTime).wDay,
               &(*sysTime).wHour, &(*sysTime).wMinute, &(*sysTime).wSecond, &(*sysTime).wMilliseconds);

        SYSTEMTIME st = {0};
        sscanf(isoDate, "%4hu-%2hu-%2huT%2hu:%2hu:%2hu.%3hu", &st.wYear, &st.wMonth, &st.wDay,
               &st.wHour, &st.wMinute, &st.wSecond, &st.wMilliseconds);

        if ( st.wYear < SYSTEMTIME_MIN_YEAR )
        {
            userDefinedMsgException(c, "The DateTime object can not represent a year prior to 1601");
            goto failed_out;
        }

        switch ( part )
        {
            case dtTime :
                sysTime->wHour = st.wHour;
                sysTime->wMinute = st.wMinute;
                sysTime->wSecond = st.wSecond;
                sysTime->wMilliseconds = st.wMilliseconds;
                break;

            case dtDate :
                sysTime->wYear = st.wYear;
                sysTime->wMonth = st.wMonth;
                sysTime->wDay = st.wDay;
                break;

            case dtFull :
                sysTime->wYear = st.wYear;
                sysTime->wMonth = st.wMonth;
                sysTime->wDay = st.wDay;
                sysTime->wHour = st.wHour;
                sysTime->wMinute = st.wMinute;
                sysTime->wSecond = st.wSecond;
                sysTime->wMilliseconds = st.wMilliseconds;
                break;
        }
    }
    return true;

failed_out:
    return false;
}


/**
 * Given an array of DateTime objects, converts them to an an array of
 * SYSTEMTIME structs.
 *
 * The array is assumed to be argument 1 of a method and only the first two
 * indexes are converted.
 *
 * @param c          The method context we are operating in.
 * @param dateTimes  The Rexx array of DateTime objects.
 * @param sysTimes   [IN/OUT] On entry an array of 2 SYSTEMTIMEs, on return the
 *                   SYSTEMTIME structs will be filled in according to the other
 *                   arguments.
 * @param part       Should the conversion be just the time portion, just the
 *                   date portion, or both.
 * @param needBoth   Are both index 1 and index 2 in the Rexx array required.
 * @param gdtr       [IN/OUT] Pointer to a variable to receive the GDTR_xxx
 *                   flags for the conversion.  This is ignored if NULL.
 *
 * @return True on success, false otherwise.  If false, an exceptions has been
 *         raised.
 */
bool dt2sysTimeRange(RexxMethodContext *c, RexxArrayObject dateTimes, SYSTEMTIME *sysTimes,
                     DateTimePart part, bool needBoth, uint32_t *gdtr)
{
    memset(sysTimes, 0, 2 * sizeof(SYSTEMTIME));

    RexxObjectPtr startDate = c->ArrayAt(dateTimes, 1);
    RexxObjectPtr endDate = c->ArrayAt(dateTimes, 2);

    if ( needBoth && (startDate == NULLOBJECT || endDate == NULLOBJECT) )
    {
        sparseArrayException(c->threadContext, 1, (startDate == NULLOBJECT ? 1 : 2));
        goto err_out;
    }

    uint32_t gdtrVal = 0;

    if ( startDate != NULLOBJECT )
    {
        if ( ! c->IsOfType(startDate, "DATETIME") )
        {
            wrongObjInArrayException(c->threadContext, 1, 1, "a DateTime object", startDate);
            goto err_out;
        }

        if ( ! dt2sysTime(c->threadContext, startDate, sysTimes, part) )
        {
            goto err_out;
        }
        gdtrVal |= GDTR_MIN;
    }

    if ( endDate != NULLOBJECT )
    {
        if ( ! c->IsOfType(endDate, "DATETIME") )
        {
            wrongObjInArrayException(c->threadContext, 1, 2, "a DateTime object", endDate);
            goto err_out;
        }

        if ( ! dt2sysTime(c->threadContext, endDate, sysTimes + 1, part) )
        {
            goto err_out;
        }
        gdtrVal |= GDTR_MAX;
    }

    if ( gdtrVal == 0 )
    {
        userDefinedMsgException(c->threadContext, SYSTEMTIME_RANGE_EXCEPTION_MSG);
    }

    if ( gdtr != NULL )
    {
        *gdtr = gdtrVal;
    }
    return true;

err_out:
    return false;
}

/**
 * Gets the time range (minimum and maximum allowable times) for a MonthCalendar
 * or a DateTimePicker control
 *
 * @param c
 * @param range
 * @param hCtrl
 * @param ctrlType
 *
 * @return CSTRING
 */
CSTRING getTimeRange(RexxMethodContext *c, RexxArrayObject range, HWND hCtrl, oodControl_t ctrlType)
{
    SYSTEMTIME sysTime[2];
    memset(&sysTime, 0, 2 * sizeof(SYSTEMTIME));

    DateTimePart dtPart;
    uint32_t ret;

    if ( ctrlType == winMonthCalendar )
    {
        dtPart = dtDate;
        ret =  MonthCal_GetRange(hCtrl, &sysTime);
    }
    else
    {
        dtPart = dtFull;
        ret =  DateTime_GetRange(hCtrl, &sysTime);
    }

    RexxObjectPtr minDate;
    RexxObjectPtr maxDate;

    CSTRING result;
    switch ( ret )
    {
        case 0 :
            result = "none";
            minDate = TheZeroObj;
            maxDate = TheZeroObj;
            break;
        case (GDTR_MIN | GDTR_MAX) :
            sysTime2dt(c->threadContext, (SYSTEMTIME *)&sysTime, &minDate, dtPart);
            sysTime2dt(c->threadContext, (SYSTEMTIME *)&sysTime + 1, &maxDate, dtPart);
            result = "both";
            break;
        case GDTR_MIN :
            result = "min";
            sysTime2dt(c->threadContext, (SYSTEMTIME *)&sysTime, &minDate, dtPart);
            maxDate = TheZeroObj;
            break;
        case GDTR_MAX :
            result = "max";
            minDate = TheZeroObj;
            sysTime2dt(c->threadContext, (SYSTEMTIME *)&sysTime + 1, &maxDate, dtPart);
            break;
        default :
            result = "error";  // I don'think this is possible.
            minDate = TheZeroObj;
            maxDate = TheZeroObj;
            break;
    }

    c->ArrayPut(range, minDate, 1);
    c->ArrayPut(range, maxDate, 2);

    return result;
}


/**
 * Creates a DateTime object that represents the time set in a SYSTEMTIME
 * struct.
 *
 * @param c
 * @param sysTime
 * @param dateTime  [in/out]
 */
void sysTime2dt(RexxThreadContext *c, SYSTEMTIME *sysTime, RexxObjectPtr *dateTime, DateTimePart part)
{
    RexxClassObject dtClass = c->FindClass("DATETIME");

    if ( part == dtNow )
    {
        *dateTime = c->SendMessage0(dtClass, "NEW");
    }
    else
    {
        char buf[64];
        switch ( part )
        {
            case dtDate :
                _snprintf(buf, RXITEMCOUNT(buf), "%hu%02hu%02hu", sysTime->wYear, sysTime->wMonth, sysTime->wDay);
                *dateTime = c->SendMessage1(dtClass, "FROMSTANDARDDATE", c->String(buf));
                break;

            case dtTime :
                _snprintf(buf, RXITEMCOUNT(buf), "%02hu:%02hu:%02hu.%03hu000",
                          sysTime->wHour, sysTime->wMinute, sysTime->wSecond, sysTime->wMilliseconds);
                *dateTime = c->SendMessage1(dtClass, "FROMLONGTIME", c->String(buf));
                break;

            case dtFull :
                _snprintf(buf, RXITEMCOUNT(buf), "%hu-%02hu-%02huT%02hu:%02hu:%02hu.%03hu000",
                          sysTime->wYear, sysTime->wMonth, sysTime->wDay,
                          sysTime->wHour, sysTime->wMinute, sysTime->wSecond, sysTime->wMilliseconds);
                *dateTime = c->SendMessage1(dtClass, "FROMISODATE", c->String(buf));
                break;
        }
    }
}


static uint32_t calPart2flag(CSTRING part)
{
    // This is an invalid flag.  When used in the DateTime_xx or MonthCalenddar_XX
    // macros, the macros then return the error code.
    uint32_t flag = (uint32_t)-1;

    if (      StrStrIA(part, "BACKGROUND"  ) != NULL ) flag = MCSC_BACKGROUND;
    else if ( StrStrIA(part, "MONTHBK"     ) != NULL ) flag = MCSC_MONTHBK;
    else if ( StrStrIA(part, "TEXT"        ) != NULL ) flag = MCSC_TEXT;
    else if ( StrStrIA(part, "TITLEBK"     ) != NULL ) flag = MCSC_TITLEBK;
    else if ( StrStrIA(part, "TITLETEXT"   ) != NULL ) flag = MCSC_TITLETEXT;
    else if ( StrStrIA(part, "TRAILINGTEXT") != NULL ) flag = MCSC_TRAILINGTEXT;
    return flag;
}


/**
 * Produce a string representation of a Month Calendar's style.
 */
static RexxStringObject mcStyle2String(RexxMethodContext *c, uint32_t style)
{
    char buf[256];
    buf[0] = '\0';

    if ( style & MCS_DAYSTATE )         strcat(buf, "DAYSTATE"   );
    if ( style & MCS_MULTISELECT )      strcat(buf, "MULTI"      );
    if ( style & MCS_NOTODAY )          strcat(buf, "NOTODAY"    );
    if ( style & MCS_NOTODAYCIRCLE )    strcat(buf, "NOCIRCLE"   );
    if ( style & MCS_WEEKNUMBERS )      strcat(buf, "WEEKNUMBERS");
    if ( style & MCS_NOTRAILINGDATES )  strcat(buf, "NOTRAILING" );
    if ( style & MCS_SHORTDAYSOFWEEK )  strcat(buf, "SHORTDAYS"  );
    if ( style & MCS_NOSELCHANGEONNAV ) strcat(buf, "NOSELCHANGE");

    *(buf + strlen(buf)) = '\0';
    return c->String(buf);
}


/**
 * Produce a Month Calendar's style from a string of keywords.
 */
static uint32_t string2mcStyle(CSTRING style)
{
    uint32_t flags = 0;

    if ( StrStrIA(style, "DAYSTATE"   ) != NULL ) flags |= MCS_DAYSTATE;
    if ( StrStrIA(style, "MULTI"      ) != NULL ) flags |= MCS_MULTISELECT;
    if ( StrStrIA(style, "NOTODAY"    ) != NULL ) flags |= MCS_NOTODAY;
    if ( StrStrIA(style, "NOCIRCLE"   ) != NULL ) flags |= MCS_NOTODAYCIRCLE;
    if ( StrStrIA(style, "WEEKNUMBERS") != NULL ) flags |= MCS_WEEKNUMBERS;
    if ( StrStrIA(style, "NOTRAILING" ) != NULL ) flags |= MCS_NOTRAILINGDATES;
    if ( StrStrIA(style, "SHORTDAYS"  ) != NULL ) flags |= MCS_SHORTDAYSOFWEEK;
    if ( StrStrIA(style, "NOSELCHANGE") != NULL ) flags |= MCS_NOSELCHANGEONNAV;

    return flags;
}


/** DateTimePicker::closeMonthCal()
 *
 *  Closes the drop down month calendar control of the date time picker.
 *
 *  @return  This method always returns zero
 *
 *  @note    Requires Vista or later.  This method causes the date time picker
 *           to destroy the month calendar control and to send a DTN_CLOSEUP
 *           notification (the CLOSEUP event notification) that the control is
 *           closing.
 */
RexxMethod2(RexxObjectPtr, dtp_closeMonthCal, RexxObjectPtr, _size, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        wrongWindowsVersionException(context, "getIdelaSize", "Vista");
        return TheZeroObj;
    }

    DateTime_CloseMonthCal(getDChCtrl(pCSelf));
    return TheZeroObj;
}


/** DateTimePicker::getDateTime()
 *
 *  Retrieves the current selected system time of the date time picker and
 *  returns it as a DateTime object.
 *
 *  If the date time picker has the DTS_SHOWNONE style, it can also be set to
 *  "no date" when the user has unchecked the check box.  If the control is in
 *  this state, the .nil object is returned to the user.
 *
 *  @returns  A DateTime object representing the current selected system time of
 *            the control, or the .nil object if the control is in the
 *            'no date' state.
 */
RexxMethod1(RexxObjectPtr, dtp_getDateTime, CSELF, pCSelf)
{
    SYSTEMTIME sysTime = {0};
    RexxObjectPtr dateTime = TheNilObj;

    switch ( DateTime_GetSystemtime(getDChCtrl(pCSelf), &sysTime) )
    {
        case GDT_VALID:
            sysTime2dt(context->threadContext, &sysTime, &dateTime, dtFull);
            break;

        case GDT_NONE:
            // This is valid.  It means the DTP is using the DTS_SHOWNONE  style
            // and that the user has the check box is not checked.  We return
            // the .nil object.
            break;

        case GDT_ERROR:
        default :
            // Some error with the DTP, raise an exception.
            controlFailedException(context->threadContext, FUNC_WINCTRL_FAILED_MSG, "DateTime_GetSystemtime", DATETIMEPICKER_WINNAME);
            break;
    }
    return dateTime;
}

/** DateTimePicker::getInfo()
 *
 *  Returns a Directory object with information about the date time picker.
 *
 *  @note  The directory object will contain the following indexes:
 *
 *         CHECKRECT:  A .Rect object describing location of the checkbox, if
 *         the date time picker has the SHOWNONE style.  If a checkbox is
 *         displayed and checked, an edit control should be available to update
 *         the selected date-time value.
 *
 *         CHECKSTATE:  A list of <object state> keywords describing the state
 *         of the check box.
 *
 *         BUTTONRECT:  A RECT structure describing the location of the
 *         drop-down grid or the up/down control.
 *
 *         BUTTONSTATE:  A list of <object state> keywords describing the state
 *         of the check box.
 *
 *         EDIT:  The Edit control object.
 *
 *         DROPDOWN:  The MonthCalendar control object.
 *
 *         UPDOWN:  The UpDown control object.
 */
RexxMethod1(RexxObjectPtr, dtp_getInfo, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        return wrongWindowsVersionException(context, "getInfo", "Vista");
    }

    HWND hDTP = getDChCtrl(pCSelf);
    RexxDirectoryObject result = context->NewDirectory();

    DATETIMEPICKERINFO info = {0};
    info.cbSize = sizeof(DATETIMEPICKERINFO);

    DateTime_GetDateTimePickerInfo(hDTP, &info);

    // TODO need to test this on Vista and see what the actual values are
    // depending on the style of the DTP.

    context->DirectoryPut(result, rxNewRect(context, &(info.rcCheck)), "CHECKRECT");
    context->DirectoryPut(result, objectStateToString(context, info.stateCheck), "CHECKSTATE");

    context->DirectoryPut(result, rxNewRect(context, &(info.rcButton)), "BUTTONRECT");
    context->DirectoryPut(result, objectStateToString(context, info.stateButton), "BUTTONSTATE");

    RexxObjectPtr ctrl = createControlFromHwnd(context, (pCDialogControl)pCSelf, info.hwndDropDown, winMonthCalendar);
    context->DirectoryPut(result, ctrl, "DROPDOWN");

    ctrl = createControlFromHwnd(context, (pCDialogControl)pCSelf, info.hwndEdit, winEdit);
    context->DirectoryPut(result, ctrl, "EDIT");

    ctrl = createControlFromHwnd(context, (pCDialogControl)pCSelf, info.hwndUD, winUpDown);
    context->DirectoryPut(result, ctrl, "UPDOWN");

    return result;
}


/** DateTimePicker::getIdealSize()
 *
 *  Gets the size needed to display the date time picker without clipping.
 *
 *  @param  size  [IN/OUT] A .Size object, on return the object will be set to
 *                the ideal size.
 *
 *  @return  This method always returns true, becuase it will always succeed.
 *           However, if the size argument is not a .Size object, a syntax
 *           condition is raised.
 *
 *  @note    Requires Vista or later.
 */
RexxMethod2(RexxObjectPtr, dtp_getIdealSize, RexxObjectPtr, _size, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        wrongWindowsVersionException(context, "getIdelaSize", "Vista");
        return TheZeroObj;
    }

    PSIZE s = rxGetSize(context, _size, 1);
    if ( s != NULL )
    {
        DateTime_GetIdealSize(getDChCtrl(pCSelf), s);
    }
    return TheTrueObj;
}


/** DateTimePicker::getMonthCal()
 *
 *  Gets the MonthCalendar object for a date and time picker's (DTP) child month
 *  calendar control.
 *
 *  One reason for gettng the MonthCalendar object is to customize the dropdown
 *  month-calendar control. For instance, if you don't want the "Go To Today,"
 *  you need to set the control's NOTODAY style.  Use this method to retrieve
 *  the MonthCalendar object.  You can then use this object to set the desired
 *  month-calendar style, or otherwise customize the control.
 *
 *  @return  A MonthCalendar object for the underlying child month calendar, if
 *           the child control exists, otherwise the .nil object.
 *
 *  @note  DTP controls create a child month calendar control when the user
 *         clicks the drop-down arrow.  When the month calendar is no longer
 *         needed, it is destroyed.  So your program must not rely on a using a
 *         single MonthCalendar object for the DTP's child month calendar.
 *
 *         Rather, you should instantiate a new MonthCalendar, if you need one,
 *         each time the user clicks the drop-down arrow.  Connect the DROPDOWN
 *         event to know when a new month calendar control is created.  After
 *         the month calendar is created, use this method to instantiate a new
 *         MonthCalendar object.  Connect the CLOSEUP event to know when the
 *         month calendar control is destroyed. Once the close up event is
 *         received, the MonthCalendar object will no longer be valid.  Invoking
 *         methods on the object will raise a syntax condition.
 */
RexxMethod1(RexxObjectPtr, dtp_getMonthCal, CSELF, pCSelf)
{
    HWND hDTP = getDChCtrl(pCSelf);
    return createControlFromHwnd(context, (pCDialogControl)pCSelf, DateTime_GetMonthCal(hDTP), winMonthCalendar);
}


/** DateTimePicker::getMonthCalColor()
 *
 *  Gets the color for a given portion of the month calendar within a date and
 *  time picker (DTP) control.
 *
 *  @param  calPart  Keyword specifying which part of the month calendar to get
 *                   the color for.
 *
 *  @return  The color for the part specified as a COLORREF, or CLR_NONE on
 *           error.
 *
 *  @note  Using the wrong keyword, mispelled, etc., will result in CLR_NONE
 *         being returned.
 */
RexxMethod2(uint32_t, dtp_getMonthCalColor, CSTRING, calPart, CSELF, pCSelf)
{
    return (COLORREF)DateTime_GetMonthCalColor(getDChCtrl(pCSelf), calPart2flag(calPart));
}


/** DateTimePicker::getMonthCalStyle()
 *
 *  Gets the month calendar style for the date and time picker.
 *
 *  @return  A string of keywords that consist of the style of the month
 *           calendar control used by the date time picker.
 *
 *  @note  See <LINK to DynamicDialog::createMonthCalendar> for the month
 *         calendar style keywords.
 *
 *         Vista or later only.
 */
RexxMethod1(RexxObjectPtr, dtp_getMonthCalStyle, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        wrongWindowsVersionException(context, "getMonthCalStyle", "Vista");
        return TheZeroObj;
    }

    uint32_t style = (uint32_t)DateTime_GetMonthCalStyle(getDChCtrl(pCSelf));
    return mcStyle2String(context, style);
}


/** DateTimePicker::getRange()
 *
 *  Gets the current minimum and maximum allowable system times for a date and
 *  time picker (DTP) control.
 *
 *  @param  range  [IN/OUT] An array in which the minimum and maximum times are
 *                 returned as .DateTime objects.  The minimum time will be at
 *                 index 1 and the maximum at index 2.  If either index is set
 *                 to zero, then no corresponding limit is set for the date time
 *                 picker control.
 *
 *  @return  A keyword indicating the result.  See below for the possible
 *           keywords
 *
 *  @note  The returned keyword indicates whether a minimum or maximum limit has
 *         been set for the DTP.  The keyword will be one of: none, min, max,
 *         both, or possibly error.  (An error is unlikely.)
 */
RexxMethod2(CSTRING, dtp_getRange, RexxArrayObject, range, CSELF, pCSelf)
{
    return getTimeRange(context, range, getDChCtrl(pCSelf), winDateTimePicker);
}

/** DateTimePicker::setDateTime()
 *
 *  Sets the system time for the date time picker to the time represented by the
 *  DateTime object.  If, and only if, the date time picker has the DTS_SHOWNONE
 *  style, it can also be set to "no date."  The Rexx user can set this state by
 *  passing in the .nil object.
 *
 *  @param dateTime  The date and time to set the control to.
 *
 *  @return   Returns 0, always
 *
 *  @note  The minimum year a date time picker can be set to is 1601.  If the
 *         DateTime object represents a year prior to 1601, an exception is
 *         raised.
 *
 */
RexxMethod2(RexxObjectPtr, dtp_setDateTime, RexxObjectPtr, dateTime, CSELF, pCSelf)
{
    SYSTEMTIME sysTime = {0};
    HWND hwnd = getDChCtrl(pCSelf);

    if ( isShowNoneDTP(hwnd) && dateTime == TheNilObj )
    {
        DateTime_SetSystemtime(hwnd, GDT_NONE, &sysTime);
    }
    else
    {
        if ( requiredClass(context->threadContext, dateTime, "DATETIME", 1) )
        {
            if ( dt2sysTime(context->threadContext, dateTime, &sysTime, dtFull) )
            {
                if ( DateTime_SetSystemtime(hwnd, GDT_VALID, &sysTime) == 0 )
                {
                    controlFailedException(context->threadContext, FUNC_WINCTRL_FAILED_MSG, "DateTime_SetSystemtime", DATETIMEPICKER_WINNAME);
                }
            }
        }
    }
    return TheZeroObj;
}


/** DateTimePicker::setFormat()
 *
 *  Sets the display of the date and time picker (DTP) control based on the
 *  given format string.
 *
 *  @param  format  The format string that the DTP should use.
 *
 *  @return  Returns true on success, otherwise false.
 *
 *  @note  It is acceptable to include extra characters within the format string
 *         to produce a more rich display. However, any nonformat characters
 *         must be enclosed within single quotes. For example, the format string
 *         "'Today is: 'hh':'m':'s ddddMMMdd', 'yyy" would produce output like
 *         "Today is: 04:22:31 Tuesday Mar 23, 1996".
 *
 *         A DTP control tracks locale changes when it is using the default
 *         format string. If you set a custom format string, it will not be
 *         updated in response to locale changes.
 *
 *         <for docs @see point reader to section on format strings>
 */
RexxMethod2(logical_t, dtp_setFormat, CSTRING, format, CSELF, pCSelf)
{
    return DateTime_SetFormat(getDChCtrl(pCSelf), format);
}


/** DateTimePicker::setMonthCalColor()
 *
 *  Sets the color for a given portion of the month calendar within a date and
 *  time picker (DTP) control.
 *
 *  @param  calPart  Keyword specifying which part of the month calendar to set
 *                   the color.
 *
 *  @param  color    The color, as a COLORREF, to use for the specified part of
 *                   the month calendar.
 *
 *  @return  The previous color for the part specified as a COLORREF, or
 *           CLR_NONE on error.
 */
RexxMethod3(uint32_t, dtp_setMonthCalColor, CSTRING, calPart, uint32_t, color, CSELF, pCSelf)
{
    return (COLORREF)DateTime_SetMonthCalColor(getDChCtrl(pCSelf), calPart2flag(calPart), color);
}


/** DateTimePicker::setMonthCalStyle()
 *
 *  Sets the month calendar style for the date and time picker.
 *
 *  @return  A string of keywords that consist of the style of the month
 *           calendar control used by the date time picker.
 *
 *  @note  See <LINK to DynamicDialog::createMonthCalendar> for the month
 *         calendar style keywords.
 *
 *         Vista or later only.
 */
RexxMethod2(RexxObjectPtr, dtp_setMonthCalStyle, CSTRING, newStyle, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        wrongWindowsVersionException(context, "setMonthCalStyle", "Vista");
        return TheZeroObj;
    }

    uint32_t style = (uint32_t)DateTime_SetMonthCalStyle(getDChCtrl(pCSelf), string2mcStyle(newStyle));
    return mcStyle2String(context, style);
}


/** DateTimePicker::setRange()
 *
 *  Sets the minimum and maximum allowable dates / times for the date time
 *  picker control.
 *
 *  @param dateTimes  An array of DateTime objects used to set the minimum and
 *                    maximum dates.  The DateTime object at index 1 sets the
 *                    minimum date and the DateTime object at index 2 sets the
 *                    maximum date.
 *
 *  @return  True on success, otherwise false.
 *
 *  @note  The array must contain at least one of the indexes.  If it contains
 *         neither, an exception is raised. If one of the array indexes is
 *         empty, then the corresponding date is not set.
 *
 *         Exceptions are raised for invalid arguments.
 */
RexxMethod2(RexxObjectPtr, dtp_setRange, RexxArrayObject, dateTimes, CSELF, pCSelf)
{
    SYSTEMTIME sysTime[2];
    uint32_t which = 0;

    if ( dt2sysTimeRange(context, dateTimes, (SYSTEMTIME *)&sysTime, dtDate, false, &which) )
    {
        return  (DateTime_SetRange(getDChCtrl(pCSelf), which, &sysTime) == 0 ? TheFalseObj : TheTrueObj);
    }
    return TheFalseObj;
}


/**
 * Methods for the MonthCalendar class.
 *
 * Note that a MonthCalendar object can be created from a DateTimePicker when
 * the date time picker displays the month calendar.  The underlying month
 * calendar control is destroyed when the date time picker closes it up.  For
 * this reason, extra care is used in the MonthCalendar class to ensure the
 * window handle for the control is still valid.
 */
#define MONTHCALENDAR_CLASS    "MonthCalendar"
#define MONTHCALENDAR_WINNAME  "Month Calendar"

inline HWND getMonthCalendar(RexxMethodContext *c, void *pCSelf)
{
    HWND hMC = getDChCtrl(pCSelf);
    if ( hMC == NULL )
    {
        invalidWindowException(c, getDCrexxSelf(pCSelf));
    }
    return hMC;
}

#define MC_GRIDINFO_PART_NAMES             "control, next, prev, footer, calendard, header, body, row, cell"
#define MC_GRIDINFO_WHAT_FLAG_ERR_MSG      "must contain at least one of the keywords: date, rect, or name"

/* Determine if a month calendar is a multi-selection month calendar. */
inline bool isMultiSelectionMonthCalendar(HWND hCtrl)
{
    return ((GetWindowLong(hCtrl, GWL_STYLE) & MCS_MULTISELECT) == MCS_MULTISELECT);
}

inline RexxObjectPtr setDayState(HWND hMC, LPMONTHDAYSTATE pmds, int count, RexxObjectPtr result)
{
    if ( result != TheFalseObj )
    {
        result = (MonthCal_SetDayState(hMC, count, pmds) == 0 ? TheFalseObj : TheTrueObj);
    }
    return result;
}

/* Convert Month Calendar integer day to its string name. */
inline CSTRING day2dayName(int32_t iDay)
{
    switch ( iDay )
    {
        case 0 : return "Monday";
            break;
        case 1 : return "Tuesday";
            break;
        case 2 : return "Wednesday";
            break;
        case 3 : return "Thursday";
            break;
        case 4 : return "Friday";
            break;
        case 5 : return "Saturday";
            break;
        case 6 : return "Sunday";
            break;
        default : return  "";
            break;
    }
}


static int32_t dayName2day(CSTRING day)
{
    if (      StrStrIA(day, "MONDAY"   ) != NULL ) return 0;
    else if ( StrStrIA(day, "TUESDAY"  ) != NULL ) return 1;
    else if ( StrStrIA(day, "WEDNESDAY") != NULL ) return 2;
    else if ( StrStrIA(day, "THURSDAY" ) != NULL ) return 3;
    else if ( StrStrIA(day, "FRIDAY"   ) != NULL ) return 4;
    else if ( StrStrIA(day, "SATURDAY" ) != NULL ) return 5;
    else if ( StrStrIA(day, "SUNDAY"   ) != NULL ) return 6;
    else return -1;
}


/**
 * Change a month calendar's style.
 *
 * @param c
 * @param pCSelf
 * @param _style
 * @param _additionalStyle
 * @param remove
 *
 * @return uint32_t
 *
 *  @remarks  MSDN suggests setting last error to 0 before calling
 *            GetWindowLong() as the correct way to determine error.
 */
static uint32_t mcChangeStyle(RexxMethodContext *c, pCDialogControl pCSelf, CSTRING _style, CSTRING _additionalStyle, bool remove)
{
    oodResetSysErrCode(c->threadContext);
    SetLastError(0);

    HWND hMC = getMonthCalendar(c, pCSelf);
    if ( hMC == NULL )
    {
        return 0;
    }

    uint32_t newStyle = 0;
    uint32_t oldStyle = (uint32_t)GetWindowLong(hMC, GWL_STYLE);

    if ( oldStyle == 0 && GetLastError() != 0 )
    {
        goto err_out;
    }

    if ( remove )
    {
        newStyle &= ~monthCalendarStyle(_style, 0);
        if ( _additionalStyle != NULL )
        {
            newStyle = monthCalendarStyle(_additionalStyle, newStyle);
        }
    }
    else
    {
        newStyle = monthCalendarStyle(_style, oldStyle);
    }

    if ( SetWindowLong(hMC, GWL_STYLE, newStyle) == 0 && GetLastError() != 0 )
    {
        goto err_out;
    }
    return oldStyle;

err_out:
    oodSetSysErrCode(c->threadContext);
    return 0;
}


static void firstDay2directory(RexxMethodContext *c, uint32_t firstDay, RexxDirectoryObject *pDirectory)
{
    int32_t       iDay = LOWORD(firstDay);
    RexxObjectPtr usesLocale = HIWORD(firstDay) == 0 ? TheTrueObj : TheFalseObj;
    CSTRING       dayName = day2dayName(iDay);

    RexxDirectoryObject result = *pDirectory;

    c->DirectoryPut(result, c->Int32(iDay), "DAY");
    c->DirectoryPut(result, usesLocale, "USINGLOCALE");
    c->DirectoryPut(result, c->String(dayName), "DAYNAME");
}


bool putHitInfo(RexxMethodContext *c, RexxDirectoryObject hitInfo, MCHITTESTINFO *info)
{
    bool done = true;
    bool needDate = false;

    switch ( info->uHit )
    {
        case MCHT_CALENDARBK :
            c->DirectoryPut(hitInfo, c->String("CalendarBackground"), "HIT");
            break;

        case MCHT_CALENDARCONTROL :
            c->DirectoryPut(hitInfo, c->String("CalendarControl"), "HIT");
            break;

        case MCHT_CALENDARDATE :
            c->DirectoryPut(hitInfo, c->String("CalendarDate"), "HIT");
            needDate = true;
            break;

        case MCHT_CALENDARDATEMIN :
            c->DirectoryPut(hitInfo, c->String("CalendarDateMin"), "HIT");
            break;

        case MCHT_CALENDARDATEMAX :
            c->DirectoryPut(hitInfo, c->String("CalendarDateMax"), "HIT");
            break;

        case MCHT_CALENDARDATENEXT :
            c->DirectoryPut(hitInfo, c->String("CalendarDateNext"), "HIT");
            break;

        case MCHT_CALENDARDATEPREV :
            c->DirectoryPut(hitInfo, c->String("CalendarDatePrev"), "HIT");
            break;

        case MCHT_CALENDARDAY :
            c->DirectoryPut(hitInfo, c->String("CalendarDay"), "HIT");
            needDate = true;
            break;

        case MCHT_CALENDARWEEKNUM :
            c->DirectoryPut(hitInfo, c->String("CalendarWeekNum"), "HIT");
            needDate = true;
            break;

        case MCHT_NOWHERE :
            c->DirectoryPut(hitInfo, c->String("NoWhere"), "HIT");
            done = false;
            break;

        case MCHT_TITLEBK :
            c->DirectoryPut(hitInfo, c->String("TitleBackground"), "HIT");
            break;

        case MCHT_TITLEBTNNEXT :
            c->DirectoryPut(hitInfo, c->String("TitleButtonNext"), "HIT");
            break;

        case MCHT_TITLEBTNPREV :
            c->DirectoryPut(hitInfo, c->String("TitleButtonPrev"), "HIT");
            break;

        case MCHT_TITLEMONTH :
            c->DirectoryPut(hitInfo, c->String("TitleMonth"), "HIT");
            break;

        case MCHT_TITLEYEAR :
            c->DirectoryPut(hitInfo, c->String("TitleYear"), "HIT");
            break;

        case MCHT_TODAYLINK :
            // Not documented, so not sure if this is ever returned.
            c->DirectoryPut(hitInfo, c->String("TodayLink"), "HIT");
            break;

        default :
            // Shouldn't happen, but if it does this is okay, the HIT index is
            // already the empty string and we are done.
            done = true;
            break;
    }

    if ( needDate )
    {
        RexxObjectPtr date;

        sysTime2dt(c->threadContext, &(info->st), &date, dtDate);
        c->DirectoryPut(hitInfo, date, "DATE");
    }
    return done;
}


/** MonthCalendar::date   [Attribute Get]
 *
 *  Returns the currently selected date for the month calendar.
 *
 *  @note  This attribute was not originally meant for month calendars with the
 *         multi-selection style.  When used for multi-selection, the value will
 *         be the first selected date in the selection range for the calendar.
 *
 *         Use the getSelectionRange() method for multi-selection calendars.
 */
RexxMethod1(RexxObjectPtr, get_mc_date, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    RexxObjectPtr dateTime = NULLOBJECT;

    SYSTEMTIME sysTime[2];
    LRESULT result = 0;
    memset(&sysTime, 0, 2 * sizeof(SYSTEMTIME));

    if ( isMultiSelectionMonthCalendar(hMC) )
    {
        result = MonthCal_GetSelRange(hMC, &sysTime);
    }
    else
    {
        result = MonthCal_GetCurSel(hMC, &sysTime);
    }

    if ( result == 0 )
    {
        controlFailedException(context->threadContext, FUNC_WINCTRL_FAILED_MSG, "MonthCal_GetCurSel", MONTHCALENDAR_WINNAME);
    }
    else
    {
        sysTime2dt(context->threadContext, (SYSTEMTIME *)&sysTime, &dateTime, dtDate);
    }
    return dateTime;
}

/** MonthCalendar::date=  [Attribute Set]
 *
 *  Sets the currently selected date for the month calendar.
 *
 *  @param dateTime  A DateTime object used to set the selected date.  The time
 *                   portion of the object is ignored.
 *
 *  @note  This attribute was not originally meant for month calendars with the
 *         multi-selection style.  When used for multi-selection, the first and
 *         last date of the selection is set to the same date.
 *
 *         Use the setSelectionRange() method for multi-selection calendars to
 *         set a full range.
 */
RexxMethod2(RexxObjectPtr, set_mc_date, RexxObjectPtr, dateTime, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    SYSTEMTIME sysTime[2];
    LRESULT result = FALSE;
    memset(&sysTime, 0, 2 * sizeof(SYSTEMTIME));

    if ( requiredClass(context->threadContext, dateTime, "DATETIME", 1) )
    {
        if ( dt2sysTime(context->threadContext, dateTime, (SYSTEMTIME *)&sysTime, dtDate) )
        {
            if ( isMultiSelectionMonthCalendar(hMC) )
            {
                sysTime[1].wDay   = sysTime[0].wDay;
                sysTime[1].wMonth = sysTime[0].wMonth;
                sysTime[1].wYear  = sysTime[0].wYear;

                result = MonthCal_SetSelRange(hMC, &sysTime);
            }
            else
            {
                result = MonthCal_SetCurSel(hMC, &sysTime);
            }

            if ( result == 0 )
            {
                controlFailedException(context->threadContext, FUNC_WINCTRL_FAILED_MSG,
                                       "MonthCal_SetCurSel", MONTHCALENDAR_WINNAME);
            }
        }
    }
    return NULLOBJECT;
}


/** MonthCalendar::addStyle()
 *  MonthCalendar::removeStyle()
 *
 *  @note  Sets the .SystemErrorCode.
 */
RexxMethod3(uint32_t, mc_addRemoveStyle, CSTRING, style, NAME, method, CSELF, pCSelf)
{
    return mcChangeStyle(context, (pCDialogControl)pCSelf, style, NULL, (*method == 'R'));
}

/** MonthCalendar::replaceStyle()
 *
 *
 *  @note  Sets the .SystemErrorCode.
 */
RexxMethod3(uint32_t, mc_replaceStyle, CSTRING, removeStyle, CSTRING, additionalStyle, CSELF, pCSelf)
{
    return mcChangeStyle(context, (pCDialogControl)pCSelf, removeStyle, additionalStyle, true);
}


RexxMethod1(uint32_t, mc_getCalendarBorder, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        wrongWindowsVersionException(context, "getBorder", "Vista");
        return 0;
    }

    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return 0;
    }

    return MonthCal_GetCalendarBorder(hMC);
}


RexxMethod1(uint32_t, mc_getCalendarCount, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        wrongWindowsVersionException(context, "getCount", "Vista");
        return 0;
    }

    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return 0;
    }

    return MonthCal_GetCalendarCount(hMC);
}


RexxMethod1(RexxObjectPtr, mc_getCALID, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        return wrongWindowsVersionException(context, "getCALID", "Vista");
    }

    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    CSTRING id = "";
    switch( MonthCal_GetCALID(hMC) )
    {
        case CAL_GREGORIAN              : id = "GREGORIAN"; break;
        case CAL_GREGORIAN_US           : id = "GREGORIAN_US"; break;
        case CAL_JAPAN                  : id = "JAPAN"; break;
        case CAL_TAIWAN                 : id = "TAIWAN"; break;
        case CAL_KOREA                  : id = "KOREA"; break;
        case CAL_HIJRI                  : id = "HIJRI"; break;
        case CAL_THAI                   : id = "THAI"; break;
        case CAL_HEBREW                 : id = "HEBREW"; break;
        case CAL_GREGORIAN_ME_FRENCH    : id = "GREGORIAN_ME_FRENCH"; break;
        case CAL_GREGORIAN_ARABIC       : id = "GREGORIAN_ARABIC"; break;
        case CAL_GREGORIAN_XLIT_ENGLISH : id = "CAL_GREGORIAN_XLIT_ENGLISH"; break;
        case CAL_GREGORIAN_XLIT_FRENCH  : id = "CAL_GREGORIAN_XLIT_FRENCH"; break;
        case CAL_UMALQURA               : id = "UMALQURA"; break;
    }

    return context->String(id);
}


/** MonthCalendar::getColor()
 *
 *  Retrieves the color for a given portion of a month calendar control.
 *
 *  @param  calPart  Specifies which part of the calendar to get the color for.
 *
 *  @return  The color for the portion of the month calendar specified, or
 *           CLR_INVALID on error.
 *
 *  @notes  You can use .Image~colorRef(CLR_INVALID) to test for error.  (An
 *          error is not very likely.)  I.e.:
 *
 *          color = monthCalendar~getColor("TRAILINGTEXT")
 *          if color == .Image~colorRef(CLR_INVALID) then do
 *            -- some error routine
 *          end
 *
 */
RexxMethod2(uint32_t, mc_getColor, CSTRING, calPart, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return 0;
    }

    uint32_t part = calPart2flag(calPart);
    return (COLORREF)MonthCal_GetColor(hMC, part);
}

RexxMethod1(RexxObjectPtr, mc_getCurrentView, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        return wrongWindowsVersionException(context, "getBorder", "Vista");
    }

    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    CSTRING id = "";
    switch( MonthCal_GetCurrentView(hMC) )
    {
        case MCMV_MONTH   : id = "Monthly"; break;
        case MCMV_YEAR    : id = "Annual"; break;
        case MCMV_DECADE  : id = "Decade"; break;
        case MCMV_CENTURY : id = "Century"; break;
    }

    return context->String(id);
}


/** MonthCalendar::getFirstDayOfWeek()
 *
 *  Retrieves the first day of the week for the month calendar control.
 *
 *  @param  info  [OPTIONAL]  A directory object which will be filled with more
 *                detailed information than just the first day.
 *
 *  @return  A number specifying the first day of the week.  0 for Monday, 1 for
 *           Tuesday, etc..
 *
 *  @note  If the optional directory object is passed to the method, on return
 *         it will contain these indexes:
 *
 *         day          The number specifying the first day of the week.  This
 *                      is the same number as the return.
 *
 *         usingLocale  True or false, specifying whether if the first day of
 *                      the week is set to the LOCALE_IFIRSTDAYOFWEEK.
 *
 *         dayName      The string name of the day, Monday, Tuesday, etc..
 */
RexxMethod2(int32_t, mc_getFirstDayOfWeek, OPTIONAL_RexxObjectPtr, result, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return 0;
    }

    uint32_t ret = MonthCal_GetFirstDayOfWeek(hMC);

    int32_t       iDay = LOWORD(ret);
    RexxObjectPtr usesLocale = HIWORD(ret) == 0 ? TheTrueObj : TheFalseObj;
    CSTRING       dayName = day2dayName(iDay);

    if ( argumentExists(1) )
    {
        if ( ! context->IsOfType(result, "DIRECTORY") )
        {
            wrongClassException(context->threadContext, 1, "Directory");
        }
        else
        {
            firstDay2directory(context, ret, (RexxDirectoryObject *)&result);
        }
    }
    return LOWORD(ret);
}


/** MonthCalendar::getGridInfo()
 *
 *
 *  @note  Indexes for row, column, and calendar offset are 1-based.
 *
 */
RexxMethod2(RexxObjectPtr, mc_getGridInfo, RexxObjectPtr, _gridInfo, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        return wrongWindowsVersionException(context, "getGridInfo", "Vista");
    }

    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    MCGRIDINFO info = {0};
    info.cbSize = sizeof(MCGRIDINFO);

    if ( ! context->IsOfType(_gridInfo, "DIRECTORY") )
    {
        wrongClassException(context->threadContext, 1, "Directory");
        goto err_out;
    }
    RexxDirectoryObject gridInfo = (RexxDirectoryObject)_gridInfo;
    int32_t num;

    RexxObjectPtr _part = context->DirectoryAt(gridInfo, "PART");
    RexxObjectPtr _what = context->DirectoryAt(gridInfo, "WHAT");
    RexxObjectPtr _calIndex = context->DirectoryAt(gridInfo, "INDEX");

    if ( _part == NULLOBJECT )
    {
        missingIndexInDirectoryException(context->threadContext, 1, "PART");
        goto err_out;
    }
    if ( _what == NULLOBJECT )
    {
        missingIndexInDirectoryException(context->threadContext, 1, "WHAT");
        goto err_out;
    }

    if ( _calIndex == NULLOBJECT )
    {
        // TODO MSDN doc does not say if this is 0-based or 1-based. ???
        info.iCalendar = 0;
        context->DirectoryPut(gridInfo, TheOneObj, "INDEX");
    }
    else
    {
        if ( ! context->Int32(_calIndex, &num) )
        {
            wrongObjInDirectoryException(context->threadContext, 1, "INDEX", "whole number", _calIndex);
            goto err_out;
        }
        info.iCalendar = num - 1;
    }

    CSTRING partName = context->ObjectToStringValue(_part);
    CSTRING whatFlag = context->ObjectToStringValue(_what);

    if ( stricmp(partName,      "CONTROL")  == 0 ) info.dwPart = MCGIP_CALENDARCONTROL;
    else if ( stricmp(partName, "NEXT")     == 0 ) info.dwPart = MCGIP_NEXT;
    else if ( stricmp(partName, "PREV")     == 0 ) info.dwPart = MCGIP_PREV;
    else if ( stricmp(partName, "FOOTER")   == 0 ) info.dwPart = MCGIP_FOOTER;
    else if ( stricmp(partName, "CALENDAR") == 0 ) info.dwPart = MCGIP_CALENDAR;
    else if ( stricmp(partName, "HEADER")   == 0 ) info.dwPart = MCGIP_CALENDARHEADER;
    else if ( stricmp(partName, "BODY")     == 0 ) info.dwPart = MCGIP_CALENDARBODY;
    else if ( stricmp(partName, "ROW")      == 0 ) info.dwPart = MCGIP_CALENDARROW;
    else if ( stricmp(partName, "CELL")     == 0 ) info.dwPart = MCGIP_CALENDARCELL;
    else
    {
        wrongValueAtDirectoryIndexException(context->threadContext, 1, "PART", MC_GRIDINFO_PART_NAMES, _part);
        goto err_out;
    }

    if ( StrStrIA(whatFlag,      "DATE") != NULL ) info.dwFlags |= MCGIF_DATE;
    else if ( stricmp(whatFlag, "RECT") != NULL ) info.dwFlags |= MCGIF_RECT;
    else if ( stricmp(whatFlag, "NAME") != NULL ) info.dwFlags |= MCGIF_NAME;

    if ( info.dwFlags == 0 )
    {
        directoryIndexException(context->threadContext, 1, "WHAT", MC_GRIDINFO_WHAT_FLAG_ERR_MSG, _what);
        goto err_out;
    }

    if ( info.dwPart == MCGIP_CALENDARROW || info.dwPart == MCGIP_CALENDARCELL )
    {
        RexxObjectPtr row = context->DirectoryAt(gridInfo, "ROW");
        if ( row == NULLOBJECT )
        {
            missingIndexInDirectoryException(context->threadContext, 1, "ROW");
            goto err_out;
        }
        if ( ! context->Int32(row, &num) )
        {
            wrongObjInDirectoryException(context->threadContext, 1, "ROW", "whole number", row);
            goto err_out;
        }
        info.iRow = num - 1;

        if ( info.dwPart == MCGIP_CALENDARCELL )
        {
            RexxObjectPtr col = context->DirectoryAt(gridInfo, "COL");
            if ( col == NULLOBJECT )
            {
                missingIndexInDirectoryException(context->threadContext, 1, "COL");
                goto err_out;
            }
            if ( ! context->Int32(col, &num) )
            {
                wrongObjInDirectoryException(context->threadContext, 1, "COL", "whole number", col);
                goto err_out;
            }
            info.iCol = num - 1;
        }
    }

    if ( ! MonthCal_GetCalendarGridInfo(hMC, &info) )
    {
        goto err_out;
    }

    if ( info.dwPart == MCGIP_CALENDARCELL )
    {
        context->DirectoryPut(gridInfo, (info.bSelected ? TheTrueObj : TheFalseObj), "SELECTED");
    }

    if ( info.dwFlags & MCGIF_DATE )
    {
        RexxObjectPtr startDate;
        RexxObjectPtr endDate;
        sysTime2dt(context->threadContext, &info.stStart, &startDate, dtDate);
        sysTime2dt(context->threadContext, &info.stEnd, &endDate, dtDate);

        context->DirectoryPut(gridInfo, startDate, "STARTDATE");
        context->DirectoryPut(gridInfo, endDate, "ENDDATE");
    }

    if ( info.dwFlags & MCGIF_RECT )
    {
        context->DirectoryPut(gridInfo, rxNewRect(context, &info.rc), "RECT");
    }

    if ( (info.dwFlags & MCGIF_NAME) && (info.dwPart == MCGIP_CALENDAR || info.dwPart == MCGIP_CALENDARCELL || info.dwPart == MCGIP_CALENDARHEADER) )
    {
        context->DirectoryPut(gridInfo, unicode2string(context, info.pszName), "NAME");
    }

    return TheTrueObj;

err_out:
    return TheFalseObj;
}


RexxMethod2(RexxObjectPtr, mc_getMinRect, RexxObjectPtr, _rect, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    PRECT r = rxGetRect(context, _rect, 1);
    if ( r != NULL )
    {
        return (MonthCal_GetMinReqRect(hMC, r) == 0 ? TheFalseObj : TheTrueObj);
    }
    return TheFalseObj;
}


/** MonthCalendar::getMonthRange()
 *
 *  Retrieves date information (using DateTime objects) that represents the
 *  high and low limits of a month calendar control's display.
 *
 *  @param  range  [IN / OUT] An array object in which the range is returned.
 *                 The lower limit (a DateTime object) will be returned at index
 *                 1 and the upper limit (a DateTime object) will be returned at
 *                 index 2.
 *
 *  @param  span   [OPTIONAL]  A keyword specifying whether the range should
 *                 include only months that are ENTIRELY displayed or to include
 *                 trailing and following months that are only PARTIALLY
 *                 displayed.  The default if omitted is PARTIALLY.  Only the
 *                 first letter of ENTIRELY or PARTIALLY are required and case
 *                 is insignificant.
 *
 *  @return  The number of months in the range.
 */
RexxMethod3(int32_t, mc_getMonthRange, RexxArrayObject, range, OPTIONAL_CSTRING, span, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return 0;
    }

    uint32_t flag = GMR_DAYSTATE;
    if ( argumentExists(2) )
    {
        switch ( toupper(*span) )
        {
            case 'E' : flag = GMR_VISIBLE;
                break;
            case 'P' : flag = GMR_DAYSTATE;
                break;
            default :
                goto err_out;
        }
    }

    SYSTEMTIME sysTime[2];
    memset(&sysTime, 0, 2 * sizeof(SYSTEMTIME));

    int32_t ret = MonthCal_GetMonthRange(hMC, flag, &sysTime);

    RexxObjectPtr lowMonth, highMonth;
    sysTime2dt(context->threadContext, (SYSTEMTIME *)&sysTime, &lowMonth, dtDate);
    sysTime2dt(context->threadContext, (SYSTEMTIME *)&sysTime + 1, &highMonth, dtDate);

    context->ArrayPut(range, lowMonth, 1);
    context->ArrayPut(range, highMonth, 2);

    return ret;

err_out:
    wrongArgOptionException(context->threadContext, 2, "[P]artially, or [E]ntirely", span);
    return -1;
}


/** MonthCalendar::getRange()
 *
 *  Gets the current minimum and maximum allowable dates for a month calendar
 *  control.
 *
 *  @param  range  [IN/OUT] An array in which the minimum and maximum dates are
 *                 returned as .DateTime objects.  The minimum date will be at
 *                 index 1 and the maximum at index 2.  If either index is set
 *                 to zero, then no corresponding limit is set for the month
 *                 calendar control.
 *
 *  @return  A keyword indicating the result.  See below for the possible
 *           keywords.
 *
 *  @note  The returned keyword indicates whether a minimum or maximum limit has
 *         been set for the month calendar control.  The keyword will be one of:
 *         none, min, max, both, or possibly error.  (An error is unlikely.)
 */
RexxMethod2(CSTRING, mc_getRange, RexxArrayObject, range, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return "";
    }
    return getTimeRange(context, range, hMC, winMonthCalendar);

}

RexxMethod2(RexxObjectPtr, mc_getSelectionRange, RexxArrayObject, range, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    if ( ! isMultiSelectionMonthCalendar(hMC) )
    {
        goto err_out;
    }

    SYSTEMTIME sysTime[2];
    memset(&sysTime, 0, 2 * sizeof(SYSTEMTIME));

    if ( MonthCal_GetSelRange(hMC, &sysTime) == 0 )
    {
        goto err_out;
    }

    RexxObjectPtr startDate;
    sysTime2dt(context->threadContext, (SYSTEMTIME *)&sysTime, &startDate, dtDate);
    context->ArrayPut(range, startDate, 1);

    RexxObjectPtr endDate;
    sysTime2dt(context->threadContext, (SYSTEMTIME *)&sysTime + 1, &endDate, dtDate);
    context->ArrayPut(range, endDate, 2);

    return TheTrueObj;

err_out:
    return TheFalseObj;
}


/** MonthCalendar::getToday()
 *
 *  Retrieves the date information for the date specified as "today" for a month
 *  calendar control.
 *
 *  @return  The "today" date as a DateTime object or .nil on error.
 */
RexxMethod1(RexxObjectPtr, mc_getToday, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    RexxObjectPtr result = TheNilObj;
    SYSTEMTIME sysTime = {0};

    if ( MonthCal_GetToday(hMC, &sysTime) != 0 )
    {
        sysTime2dt(context->threadContext, &sysTime, &result, dtDate);
    }
    return result;
}


/** MonthCalendar::hitTest()
 *
 *
 *  @note  Indexes for row, column, and calendar offset are 1-based.
 *
 */
RexxMethod2(RexxObjectPtr, mc_hitTest, RexxObjectPtr, _pt, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    RexxDirectoryObject hitInfo = context->NewDirectory();

    MCHITTESTINFO info = {0};
    info.cbSize = sizeof(MCHITTESTINFO);

    PPOINT pt = rxGetPoint(context, _pt, 1);
    if ( pt == NULL )
    {
        goto done_out;
    }
    context->DirectoryPut(hitInfo, _pt, "POINT");

    info.pt.x = pt->x;
    info.pt.y = pt->y;

    MonthCal_HitTest(hMC, &info);

    bool done = putHitInfo(context, hitInfo, &info);

    if ( info.cbSize > MCHITTESTINFO_V1_SIZE && ! done )
    {
        context->DirectoryPut(hitInfo, rxNewRect(context, &info.rc), "RECT");

        context->DirectoryPut(hitInfo, context->WholeNumber(info.iOffset + 1), "OFFSET");
        context->DirectoryPut(hitInfo, context->WholeNumber(info.iRow + 1), "ROW");
        context->DirectoryPut(hitInfo, context->WholeNumber(info.iCol + 1), "COLUMN");
    }

done_out:
    return hitInfo;
}


RexxMethod2(RexxObjectPtr, mc_setCalendarBorder, OPTIONAL_uint32_t, border, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        return wrongWindowsVersionException(context, "setBorder", "Vista");
    }

    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    if ( argumentExists(1) )
    {
        MonthCal_SetCalendarBorder(hMC, TRUE, border);
    }
    else
    {
        MonthCal_SetCalendarBorder(hMC, FALSE, 0);
    }
    return TheZeroObj;
}


/** MonthCalendar::setCALID()
 *
 *  Sets the calendar ID for the month calendar control.
 *
 * @param id  Keyword specifying which calendar ID to use.
 *
 * @return  0, always.
 */
RexxMethod2(RexxObjectPtr, mc_setCALID, CSTRING, id, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        return wrongWindowsVersionException(context, "setCALID", "Vista");
    }

    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    uint32_t calID = CAL_GREGORIAN;

    if (      StrStrIA(id, "GREGORIAN"                 ) != NULL ) calID = CAL_GREGORIAN ;
    else if ( StrStrIA(id, "GREGORIAN_US"              ) != NULL ) calID = CAL_GREGORIAN_US;
    else if ( StrStrIA(id, "JAPAN"                     ) != NULL ) calID = CAL_JAPAN;
    else if ( StrStrIA(id, "TAIWAN"                    ) != NULL ) calID = CAL_TAIWAN;
    else if ( StrStrIA(id, "KOREA"                     ) != NULL ) calID = CAL_KOREA;
    else if ( StrStrIA(id, "HIJRI"                     ) != NULL ) calID = CAL_HIJRI;
    else if ( StrStrIA(id, "THAI"                      ) != NULL ) calID = CAL_THAI;
    else if ( StrStrIA(id, "HEBREW"                    ) != NULL ) calID = CAL_HEBREW;
    else if ( StrStrIA(id, "GREGORIAN_ME_FRENCH"       ) != NULL ) calID = CAL_GREGORIAN_ME_FRENCH;
    else if ( StrStrIA(id, "GREGORIAN_ARABIC"          ) != NULL ) calID = CAL_GREGORIAN_ARABIC;
    else if ( StrStrIA(id, "CAL_GREGORIAN_XLIT_ENGLISH") != NULL ) calID = CAL_GREGORIAN_XLIT_ENGLISH;
    else if ( StrStrIA(id, "CAL_GREGORIAN_XLIT_FRENCH" ) != NULL ) calID = CAL_GREGORIAN_XLIT_FRENCH;
    else if ( StrStrIA(id, "UMALQURA"                  ) != NULL ) calID = CAL_UMALQURA;

    MonthCal_SetCALID(hMC, calID);
    return TheZeroObj;
}


/** MonthCalendar::setColor()
 *
 *  Sets the color for a given part of a month calendar control.
 *
 *  @param  which  Specifies which portion will have its color set.
 *  @param  color  A COLORREF specifying the color for the calendar part.
 *
 *  @return  The previous color for the part of the month calendar specified,
 *           or CLR_INVALID on error.
 *
 *  @notes  You can use .Image~colorRef(CLR_INVALID) to test for error.  (An
 *          error is not very likely.)  I.e.:
 *
 *          oldColor = monthCalendar~setColor("TRAILINGTEXT", color)
 *          if oldColor == .Image~colorRef(CLR_INVALID) then do
 *            -- some error routine
 *          end
 *
 */
RexxMethod3(uint32_t, mc_setColor, CSTRING, which, uint32_t, color, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return 0;
    }

    uint32_t flag = calPart2flag(which);
    return (COLORREF)MonthCal_SetColor(hMC, flag, color);
}


RexxMethod2(RexxObjectPtr, mc_setCurrentView, CSTRING, view, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        return wrongWindowsVersionException(context, "getBorder", "Vista");
    }

    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    uint32_t mcmv = MCMV_MONTH;

    if (      StrStrIA(view, "MONTHLY") != NULL ) mcmv = MCMV_MONTH;
    else if ( StrStrIA(view, "ANNUAL")  != NULL ) mcmv = MCMV_YEAR;
    else if ( StrStrIA(view, "DECADE")  != NULL ) mcmv = MCMV_DECADE;
    else if ( StrStrIA(view, "CENTURY") != NULL ) mcmv = MCMV_CENTURY;

    return (MonthCal_SetCurrentView(hMC, mcmv) ? TheTrueObj : TheFalseObj);
}

RexxMethod2(RexxObjectPtr, mc_setDayState, RexxArrayObject, list, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    LPMONTHDAYSTATE pmds;
    size_t count = context->ArrayItems(list);

    RexxObjectPtr result = makeDayStateBuffer(context, list, count, &pmds);
    return setDayState(hMC, pmds, (int)count, result);
}

RexxMethod4(RexxObjectPtr, mc_setDayStateQuick, uint32_t, ds1, uint32_t, ds2, uint32_t, ds3, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    LPMONTHDAYSTATE pmds;
    RexxObjectPtr result = quickDayStateBuffer(context, ds1, ds2, ds3, &pmds);
    return setDayState(hMC, pmds, 3, result);
}

/** MonthCalendar::setFirstDayOfWeek()
 *
 *  Sets the first day of the week for the month calendar control.
 *
 *  @param  firstDay  Which day is to be the first day of the week.  This can
 *                    either be the name of the day (Monday, Tuesday, etc., case
 *                    insignificant) or the number of the day (0 for Monday, 1
 *                    for Tuesday, etc..)
 *
 *  @return  A directory object with information concerning the previous first
 *           day of the week. @see <getfirstDayOfWeek>
 *
 *  @note  The returned directory object will contain these indexes with the
 *         information for the previous first day of the week:
 *
 *         day          The number specifying the first day of the week. 0 for
 *                      Monday, etc..
 *
 *         usingLocale  True or false, specifying if the first day of the week
 *                      is set to the LOCALE_IFIRSTDAYOFWEEK.
 *
 *         dayName      The string name of the day, Monday, Tuesday, etc..
 */
RexxMethod2(RexxObjectPtr, mc_setFirstDayOfWeek, RexxObjectPtr, firstDay, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    int32_t iDay = -1;
    if ( ! context->Int32(firstDay, &iDay) )
    {
        iDay = dayName2day(context->ObjectToStringValue(firstDay));
    }

    if ( iDay < 0 || iDay > 6 )
    {
        return wrongArgValueException(context->threadContext, 1, "name of the day or a nubmer from 0 to 6", firstDay);
    }

    uint32_t ret = (uint32_t)MonthCal_SetFirstDayOfWeek(hMC, iDay);

    RexxDirectoryObject result = context->NewDirectory();
    firstDay2directory(context, ret, &result);

    return result;
}

/** MonthCalendar::setRange()
 *
 *  Sets the minimum and maximum allowable dates for the month calendar control.
 *
 *  @param dateTimes  An array of DateTime objects used to set the minimum and
 *                    maximum dates.  The DateTime object at index 1 sets the
 *                    minimum date and the DateTime object at index 2 sets the
 *                    maximum date.
 *
 *  @return  True on success, otherwise false.
 *
 *  @note  The array must contain at least one of the indexes.  If it contains
 *         neither, and exceptions is raised. If one of the array indexes is
 *         empty, then the corresponding date is not set.  The time portion of
 *         the DateTime object(s) is ignored.
 *
 *         Exceptions are raised for invalid arguments.
 */
RexxMethod2(RexxObjectPtr, mc_setRange, RexxArrayObject, dateTimes, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC != NULL )
    {
        SYSTEMTIME sysTime[2];
        uint32_t which = 0;

        if ( dt2sysTimeRange(context, dateTimes, (SYSTEMTIME *)&sysTime, dtDate, false, &which) )
        {
            return  (MonthCal_SetRange(hMC, which, &sysTime) == 0 ? TheFalseObj : TheTrueObj);
        }
    }
    return TheFalseObj;
}


/** MonthCalendar::setSelectionRange()
 *
 *  Sets the selection for a month calendar control to a given date range.
 *
 *  @param dateTimes  An array of DateTime objects used to set the minimum and
 *                    maximum dates.  The DateTime oject at index 1 must be the
 *                    first date in the selection, and the DateTime object at
 *                    index 2 must be the last date in the selection.  Both
 *                    indexes are required.
 *
 *  @return  True on success, otherwise false.
 *
 *  @note  The time portion of the DateTime object(s) is ignored.  Exceptions
 *         are raised for invalid arguments.
 *
 *         This method will fail if applied to a month calendar control that
 *         does not have the MULTI (MCS_MULTISELECT) style.
 */
RexxMethod2(RexxObjectPtr, mc_setSelectionRange, RexxArrayObject, dateTimes, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC != NULL )
    {
        SYSTEMTIME sysTime[2];

        if ( dt2sysTimeRange(context, dateTimes, (SYSTEMTIME *)&sysTime, dtDate, true, NULL) )
        {
            return  (MonthCal_SetSelRange(hMC, &sysTime) == 0 ? TheFalseObj : TheTrueObj);
        }
    }
    return TheFalseObj;
}


/** MonthCalendar::setToday()
 *
 *  Sets the "today" selection for a month calendar control.
 *
 *  @param date  [OPTIONAL]  A DateTime object specifying the "today" date.  If
 *               this argument is omitted, then  the control returns to the
 *               default setting.
 *
 *  @return  0 always.  The return has no meaning.
 */
RexxMethod2(RexxObjectPtr, mc_setToday, OPTIONAL_RexxObjectPtr, date, CSELF, pCSelf)
{
    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    SYSTEMTIME sysTime = {0};
    SYSTEMTIME *pSysTime = NULL;

    if ( argumentExists(1) )
    {
        if ( ! context->IsOfType(date, "DATETIME") )
        {
            wrongClassException(context->threadContext, 1, "DateTime");
            goto done_out;
        }
        dt2sysTime(context->threadContext, date, &sysTime, dtDate);
    }

    MonthCal_SetToday(hMC, &sysTime);

done_out:
    return TheZeroObj;
}


/** MonthCalendar::sizeRectToMin()
 *
 *  Calculates how many calendars will fit in the given rectangle, and then
 *  returns the minimum size that a rectangle needs to be to fit that number of
 *  calendars.
 *
 *  @parm  _rect  [IN / OUT]  On entry, contains a .Rect object that describes a
 *         region that is greater than or equal to the size necessary to fit the
 *         desired number of calendars. When this method returns, the .Rect
 *         object will contains the minimum size needed for this number of
 *         calendars.
 *
 *  @return  0, always.  The return has no meaning.
 *
 */
RexxMethod2(RexxObjectPtr, mc_sizeRectToMin, RexxObjectPtr, _rect, CSELF, pCSelf)
{
    if ( ! _isAtLeastVista() )
    {
        wrongWindowsVersionException(context, "sizeRectToMin", "Vista");
        goto done_out;
    }

    HWND hMC = getMonthCalendar(context, pCSelf);
    if ( hMC == NULL )
    {
        return NULLOBJECT;
    }

    PRECT r = rxGetRect(context, _rect, 1);
    if ( r != NULL )
    {
        MonthCal_SizeRectToMin(hMC, r);
    }

done_out:
    return TheZeroObj;
}


/**
 *  Methods for the .ListView class.
 */
#define LISTVIEW_CLASS            "ListView"

#define LVSTATE_ATTRIBUTE         "LV!STATEIMAGELIST"
#define LVSMALL_ATTRIBUTE         "LV!SMALLIMAGELIST"
#define LVNORMAL_ATTRIBUTE        "LV!NORMALIMAGELIST"

inline bool hasCheckBoxes(HWND hList)
{
    return ((ListView_GetExtendedListViewStyle(hList) & LVS_EX_CHECKBOXES) != 0);
}

/**
 * Checks that the list view is either in icon view, or small icon view.
 * Certain list view messages and functions are only applicable in those views.
 *
 * Note that LVS_ICON == 0 so LVS_TYPEMASK must be used.
 */
inline bool isInIconView(HWND hList)
{
    uint32_t style = (uint32_t)GetWindowLong(hList, GWL_STYLE);
    return ((style & LVS_TYPEMASK) == LVS_ICON) || ((style & LVS_TYPEMASK) == LVS_SMALLICON);
}

/**
 * Checks if the list view is in report view.
 */
bool isInReportView(HWND hList)
{
    uint32_t style = (uint32_t)GetWindowLong(hList, GWL_STYLE);
    return ((style & LVS_TYPEMASK) == LVS_REPORT);
}

/**
 * Returns the index of the first selected item in the list view, or -1 if no
 * items are selected.
 */
inline int32_t getSelected(HWND hList)
{
    return ListView_GetNextItem(hList, -1, LVNI_SELECTED);
}

inline int getColumnCount(HWND hList)
{
    return Header_GetItemCount(ListView_GetHeader(hList));
}

inline CSTRING getLVAttributeName(uint8_t type)
{
    switch ( type )
    {
        case LVSIL_STATE :
            return LVSTATE_ATTRIBUTE;
        case LVSIL_SMALL :
            return LVSMALL_ATTRIBUTE;
        case LVSIL_NORMAL :
        default :
            return LVNORMAL_ATTRIBUTE;
    }
}

/**
 * Change the window style of a list view to align left or align top.
 */
static void applyAlignStyle(HWND hList, bool doTop)
{
    uint32_t flag = (doTop ? LVS_ALIGNTOP : LVS_ALIGNLEFT);

    uint32_t style = (uint32_t)GetWindowLong(hList, GWL_STYLE);
    SetWindowLong(hList, GWL_STYLE, ((style & ~LVS_ALIGNMASK) | flag));

    int count = ListView_GetItemCount(hList);
    if ( count > 0 )
    {
        count--;
        ListView_RedrawItems(hList, 0, count);
        UpdateWindow(hList);
    }
}

/**
 * Parse a list-view control extended style string sent from ooDialog into the
 * corresponding style flags.
 *
 * The extended list-view styles are set (and retrieved) in a different manner
 * than other window styles.  This function is used only to parse those extended
 * styles.  The normal list-view styles are parsed using EvaluateListStyle.
 */
static uint32_t parseExtendedStyle(const char * style)
{
    uint32_t dwStyle = 0;

    if ( strstr(style, "BORDERSELECT"    ) ) dwStyle |= LVS_EX_BORDERSELECT;
    if ( strstr(style, "CHECKBOXES"      ) ) dwStyle |= LVS_EX_CHECKBOXES;
    if ( strstr(style, "FLATSB"          ) ) dwStyle |= LVS_EX_FLATSB;
    if ( strstr(style, "FULLROWSELECT"   ) ) dwStyle |= LVS_EX_FULLROWSELECT;
    if ( strstr(style, "GRIDLINES"       ) ) dwStyle |= LVS_EX_GRIDLINES;
    if ( strstr(style, "HEADERDRAGDROP"  ) ) dwStyle |= LVS_EX_HEADERDRAGDROP;
    if ( strstr(style, "INFOTIP"         ) ) dwStyle |= LVS_EX_INFOTIP;
    if ( strstr(style, "MULTIWORKAREAS"  ) ) dwStyle |= LVS_EX_MULTIWORKAREAS;
    if ( strstr(style, "ONECLICKACTIVATE") ) dwStyle |= LVS_EX_ONECLICKACTIVATE;
    if ( strstr(style, "REGIONAL"        ) ) dwStyle |= LVS_EX_REGIONAL;
    if ( strstr(style, "SUBITEMIMAGES"   ) ) dwStyle |= LVS_EX_SUBITEMIMAGES;
    if ( strstr(style, "TRACKSELECT"     ) ) dwStyle |= LVS_EX_TRACKSELECT;
    if ( strstr(style, "TWOCLICKACTIVATE") ) dwStyle |= LVS_EX_TWOCLICKACTIVATE;
    if ( strstr(style, "UNDERLINECOLD"   ) ) dwStyle |= LVS_EX_UNDERLINECOLD;
    if ( strstr(style, "UNDERLINEHOT"    ) ) dwStyle |= LVS_EX_UNDERLINEHOT;

    // Needs Comctl32.dll version 5.8 or higher
    if ( ComCtl32Version >= COMCTL32_5_8 )
    {
      if ( strstr(style, "LABELTIP") ) dwStyle |= LVS_EX_LABELTIP;
    }

    // Needs Comctl32 version 6.0 or higher
    if ( ComCtl32Version >= COMCTL32_6_0 )
    {
      if ( strstr(style, "DOUBLEBUFFER") ) dwStyle |= LVS_EX_DOUBLEBUFFER;
      if ( strstr(style, "SIMPLESELECT") ) dwStyle |= LVS_EX_SIMPLESELECT;
    }
    return dwStyle;
}


/**
 * Change a list-view's style.
 *
 * @param c
 * @param pCSelf
 * @param _style
 * @param _additionalStyle
 * @param remove
 *
 * @return uint32_t
 *
 *  @remarks  MSDN suggests setting last error to 0 before calling
 *            GetWindowLong() as the correct way to determine error.
 */
static uint32_t changeStyle(RexxMethodContext *c, pCDialogControl pCSelf, CSTRING _style, CSTRING _additionalStyle, bool remove)
{
    oodResetSysErrCode(c->threadContext);
    SetLastError(0);

    HWND     hList = getDChCtrl(pCSelf);
    uint32_t oldStyle = (uint32_t)GetWindowLong(hList, GWL_STYLE);

    if ( oldStyle == 0 && GetLastError() != 0 )
    {
        goto err_out;
    }

    uint32_t newStyle = 0;
    if ( remove )
    {
        newStyle = oldStyle & ~listViewStyle(_style, 0);
        if ( _additionalStyle != NULL )
        {
            newStyle = listViewStyle(_additionalStyle, newStyle);
        }
    }
    else
    {
        newStyle = listViewStyle(_style, oldStyle);
    }

    if ( SetWindowLong(hList, GWL_STYLE, newStyle) == 0 && GetLastError() != 0 )
    {
        goto err_out;
    }
    return oldStyle;

err_out:
    oodSetSysErrCode(c->threadContext);
    return 0;
}


/**
 * Produce a string representation of a List-View's extended styles.
 */
static RexxStringObject extendedStyleToString(RexxMethodContext *c, HWND hList)
{
    char buf[256];
    DWORD dwStyle = ListView_GetExtendedListViewStyle(hList);
    buf[0] = '\0';

    if ( dwStyle & LVS_EX_BORDERSELECT )     strcat(buf, "BORDERSELECT ");
    if ( dwStyle & LVS_EX_CHECKBOXES )       strcat(buf, "CHECKBOXES ");
    if ( dwStyle & LVS_EX_FLATSB )           strcat(buf, "FLATSB ");
    if ( dwStyle & LVS_EX_FULLROWSELECT )    strcat(buf, "FULLROWSELECT ");
    if ( dwStyle & LVS_EX_GRIDLINES )        strcat(buf, "GRIDLINES ");
    if ( dwStyle & LVS_EX_HEADERDRAGDROP )   strcat(buf, "HEADERDRAGDROP ");
    if ( dwStyle & LVS_EX_INFOTIP )          strcat(buf, "INFOTIP ");
    if ( dwStyle & LVS_EX_MULTIWORKAREAS )   strcat(buf, "MULTIWORKAREAS ");
    if ( dwStyle & LVS_EX_ONECLICKACTIVATE ) strcat(buf, "ONECLICKACTIVATE ");
    if ( dwStyle & LVS_EX_REGIONAL )         strcat(buf, "REGIONAL ");
    if ( dwStyle & LVS_EX_SUBITEMIMAGES )    strcat(buf, "SUBITEMIMAGES ");
    if ( dwStyle & LVS_EX_TRACKSELECT )      strcat(buf, "TRACKSELECT ");
    if ( dwStyle & LVS_EX_TWOCLICKACTIVATE ) strcat(buf, "TWOCLICKACTIVATE ");
    if ( dwStyle & LVS_EX_UNDERLINECOLD )    strcat(buf, "UNDERLINECOLD ");
    if ( dwStyle & LVS_EX_UNDERLINEHOT )     strcat(buf, "UNDERLINEHOT ");
    if ( dwStyle & LVS_EX_LABELTIP )         strcat(buf, "LABELTIP ");
    if ( dwStyle & LVS_EX_DOUBLEBUFFER )     strcat(buf, "DOUBLEBUFFER ");
    if ( dwStyle & LVS_EX_SIMPLESELECT )     strcat(buf, "SIMPLESELECT ");

    return c->String(buf);
}


static int getColumnWidthArg(RexxMethodContext *context, RexxObjectPtr _width, size_t argPos)
{
    int width = OOD_BAD_WIDTH_EXCEPTION;

    if ( argumentOmitted(argPos) )
    {
        width = LVSCW_AUTOSIZE;
    }
    else
    {
        CSTRING tmpWidth = context->ObjectToStringValue(_width);

        if ( stricmp(tmpWidth, "AUTO") == 0 )
        {
            width = LVSCW_AUTOSIZE;
        }
        else if ( stricmp(tmpWidth, "AUTOHEADER") == 0 )
        {
            width = LVSCW_AUTOSIZE_USEHEADER;
        }
        else if ( ! context->Int32(_width, &width) )
        {
            wrongArgValueException(context->threadContext, argPos, "AUTO, AUTOHEADER, or a numeric value", _width);
        }
    }
    return width;
}


/**
 * Inserts a new list view item or a new subitem into in an existing list view
 * item.
 *
 * Note that as a byproduct of the way the underlying Windows API works, this
 * method would also modify an existing subitem.
 *
 * @param itemIndex
 * @param subitemIndex
 * @param text
 * @param imageIndex
 *
 * @return  -1 on error, othewise the inserted item index.
 *
 * @note  If a subitem is being inserted, the returned index will be the index
 *        of the item the subitem is inserted into.
 *
 */
RexxMethod5(int32_t, lv_insert, OPTIONAL_uint32_t, _itemIndex, OPTIONAL_uint32_t, subitemIndex, CSTRING, text,
            OPTIONAL_int32_t, imageIndex, CSELF, pCSelf)
{
    RXCA2T(text);
    HWND hList = getDChCtrl(pCSelf);
    int32_t newItem = -1;
    int32_t itemIndex = _itemIndex;
    LVITEM lvi = {0};

    if ( argumentOmitted(1) )
    {
        itemIndex = getDCinsertIndex(pCSelf);
        if ( subitemIndex > 0 )
        {
            itemIndex--;
            if ( itemIndex > (ListView_GetItemCount(hList) - 1) )
            {
                userDefinedMsgException(context->threadContext, 2, "A subitem can not be inserted prior to inserting the item");
                goto done_out;
            }
        }
    }

    imageIndex = (argumentOmitted(4) ? -1 : imageIndex);

    lvi.mask = LVIF_TEXT;
    lvi.iItem = itemIndex;
    lvi.iSubItem = subitemIndex;
    lvi.pszText = (LPTSTR)textT.target(); // rxwchar tocheck : I assume it's safe to cast to non-const... Was like that before rxwcharization

    if ( imageIndex > -1 )
    {
        lvi.iImage = imageIndex;
        lvi.mask |= LVIF_IMAGE;
    }

    if ( subitemIndex == 0 )
    {
        newItem = ListView_InsertItem(hList, &lvi);
        ((pCDialogControl)pCSelf)->lastItem = newItem;
    }
    else
    {
        if ( ListView_SetItem(hList, &lvi) )
        {
            newItem = itemIndex;
        }
    }

done_out:
    return newItem;
}


RexxMethod5(RexxObjectPtr, lv_modify, OPTIONAL_uint32_t, itemIndex, OPTIONAL_uint32_t, subitemIndex, CSTRING, text,
            OPTIONAL_int32_t, imageIndex, CSELF, pCSelf)
{
    RXCA2T(text);
    HWND hList = getDChCtrl(pCSelf);

    if ( argumentOmitted(1) )
    {
        itemIndex = getDCinsertIndex(pCSelf);
        if ( subitemIndex > 0 )
        {
            itemIndex--;
        }
    }
    itemIndex  = (argumentOmitted(1) ? getSelected(hList) : itemIndex);
    imageIndex = (argumentOmitted(4) ? -1 : imageIndex);

    if ( itemIndex < 0 )
    {
        itemIndex = 0;
    }

    LVITEM lvi = {0};
    lvi.mask = LVIF_TEXT;
    lvi.iItem = itemIndex;
    lvi.iSubItem = subitemIndex;
    lvi.pszText = (LPTSTR)textT.target(); // rxwchar tocheck : I assume it's safe to cast to non-const... Was like that before rxwcharization

    if ( imageIndex > -1 )
    {
        lvi.iImage = imageIndex;
        lvi.mask |= LVIF_IMAGE;
    }

    return (ListView_SetItem(hList, &lvi) ? TheZeroObj : TheOneObj);
}


RexxMethod2(int32_t, lv_add, ARGLIST, args, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    uint32_t itemIndex = getDCinsertIndex(pCSelf);
    int32_t imageIndex = -1;
    int32_t result = -1;

    LVITEM lvi = {0};
    lvi.mask = LVIF_TEXT;

    size_t argCount = context->ArraySize(args);
    for ( size_t i = 1; i <= argCount; i++ )
    {
        RexxObjectPtr _text = context->ArrayAt(args, i);
        if ( _text == NULLOBJECT )
        {
            continue;
        }

        const rxcharA *_textValue = context->ObjectToStringValue(_text);
        RXCA2T(_textValue);
        lvi.pszText = (LPTSTR)_textValueT.target(); // rxwchar tocheck : I assume it's safe to cast to non-const... Was like that before rxwcharization

        if ( i < argCount )
        {
            RexxObjectPtr _imageIndex = context->ArrayAt(args, i + 1);
            if ( _imageIndex != NULLOBJECT )
            {
                if ( ! context->Int32(_imageIndex, &imageIndex) )
                {
                    wrongRangeException(context->threadContext, (int)(i + 1), INT32_MIN, INT32_MAX, _imageIndex);
                    result = -1;
                    goto done_out;
                }
            }
        }

        if ( imageIndex > -1 )
        {
            lvi.iImage = imageIndex;
            lvi.mask |= LVIF_IMAGE;
        }

        if ( i == 1 )
        {
            lvi.iItem = itemIndex;
            lvi.iSubItem = 0;

            result = ListView_InsertItem(hList, &lvi);

            if ( result != -1 )
            {
                ((pCDialogControl)pCSelf)->lastItem = result;
            }
        }
        else
        {
            lvi.iItem = itemIndex - 1;
            lvi.iSubItem = (int)(i - 1);

            if ( ListView_SetItem(hList, &lvi) )
            {
                result = lvi.iItem;
            }
        }

        // As soon as we find a non-omitted arg, we quit.  That is / was the
        // behaviour prior to the conversion to the C++ API.
        break;
    }

done_out:
    return result;
}


RexxMethod5(int32_t, lv_addRow, OPTIONAL_uint32_t, index, OPTIONAL_int32_t, imageIndex, OPTIONAL_CSTRING, text,
            ARGLIST, args, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    index      = (argumentOmitted(1) ? getDCinsertIndex(pCSelf) : index);
    imageIndex = (argumentOmitted(2) ? -1 : imageIndex);
    text       = (argumentOmitted(3) ? "" : text);
    RXCA2T(text);

    LVITEM lvi = {0};
    lvi.mask = LVIF_TEXT;
    lvi.iItem = index;
    lvi.iSubItem = 0;
    lvi.pszText = (LPTSTR)textT.target(); // rxwchar tocheck : I assume it's safe to cast to non-const... Was like that before rxwcharization

    if ( imageIndex > -1 )
    {
        lvi.iImage = imageIndex;
        lvi.mask |= LVIF_IMAGE;
    }

    int32_t itemIndex = ListView_InsertItem(hList, &lvi);

    if ( itemIndex == -1 )
    {
        goto done_out;
    }
    ((pCDialogControl)pCSelf)->lastItem = itemIndex;

    size_t argCount = context->ArraySize(args);

    for ( size_t i = 4; i <= argCount; i++ )
    {
        RexxObjectPtr _columnText = context->ArrayAt(args, i);
        if ( _columnText == NULLOBJECT )
        {
            continue;
        }

        const rxcharA *_columTextValue = context->ObjectToStringValue(_columnText);
        RXCA2T(_columTextValue);
        ListView_SetItemText(hList, itemIndex, (int)(i - 3), (LPTSTR)_columTextValueT.target()); // rxwchar tocheck : I assume it's safe to cast to non-const
    }

done_out:
    return itemIndex;
}

/** ListView::next()
 *  ListView::nextSelected()
 *  ListView::nextLeft()
 *  ListView::nextRight()
 *  ListView::previous()
 *  ListView::previousSelected()
 *
 *
 *  @remarks  For the next(), nextLeft(), nextRight(), and previous() methods,
 *            we had this comment:
 *
 *            The Windows API appears to have a bug when the list contains a
 *            single item, insisting on returning 0.  This, rather
 *            unfortunately, can cause some infinite loops because iterating
 *            code is looking for a -1 value to mark the iteration end.
 *
 *            And in the method did: if self~Items < 2 then return -1
 *
 *            In this code, that check is not added yet, and the whole premise
 *            needs to be tested.  I find no mention of this bug in any Google
 *            searches I have done, and it seems odd that we are the only people
 *            that know about the bug?
 */
RexxMethod3(int32_t, lv_getNextItem, OPTIONAL_int32_t, startItem, NAME, method, CSELF, pCSelf)
{
    uint32_t flag;

    if ( *method == 'N' )
    {
        switch ( method[4] )
        {
            case '\0' :
                flag = LVNI_BELOW | LVNI_TORIGHT;
                break;
            case 'S' :
                flag = LVNI_BELOW | LVNI_TORIGHT | LVNI_SELECTED;
                break;
            case 'L' :
                flag = LVNI_TOLEFT;
                break;
            default :
                flag = LVNI_TORIGHT;
                break;
        }
    }
    else
    {
        flag = (method[8] == 'S' ? LVNI_ABOVE | LVNI_TOLEFT | LVNI_SELECTED : LVNI_ABOVE | LVNI_TOLEFT);
    }

    if ( argumentOmitted(1) )
    {
        startItem = -1;
    }
    return ListView_GetNextItem(getDChCtrl(pCSelf), startItem, flag);
}

/** ListView::selected()
 *  ListView::focused()
 *  ListView::dropHighlighted()
 *
 *
 */
RexxMethod2(int32_t, lv_getNextItemWithState, NAME, method, CSELF, pCSelf)
{
    uint32_t flag;

    if ( *method == 'S' )
    {
        flag = LVNI_SELECTED;
    }
    else if ( *method == 'F' )
    {
        flag = LVNI_FOCUSED;
    }
    else
    {
        flag = LVNI_DROPHILITED;
    }
    return ListView_GetNextItem(getDChCtrl(pCSelf), -1, flag);
}

/** ListView::find()
 *  ListView::findPartial()
 *
 */
RexxMethod5(int32_t, lv_find, CSTRING, text, OPTIONAL_int32_t, startItem, OPTIONAL_logical_t, wrap, NAME, method, CSELF, pCSelf)
{
    RXCA2T(text);
    HWND hList = getDChCtrl(pCSelf);

    if ( argumentOmitted(2) )
    {
        startItem = -1;
    }

    LVFINDINFO finfo = {0};
    finfo.psz = textT;
    finfo.flags = LVFI_STRING;
    if ( wrap )
    {
        finfo.flags = LVFI_STRING | LVFI_WRAP;
    }
    if ( method[4] == 'P' )
    {
        finfo.flags |= LVFI_PARTIAL;
    }

    return ListView_FindItem(hList, startItem, &finfo);
}

/** ListView::findNearestXY()
 *
 *  Finds the item nearest to the position specified by startPoint.  This method
 *  is only valid if the list view is in icon or small icon view.
 *
 *  @param  startPoint  The position, x and y co-ordinates of the starting point
 *                       for the search.  This can be specified in two forms.
 *
 *      Form 1:  arg 1 is a .Point object.
 *      Form 2:  arg 1 is the x co-ordinate and arg2 is the y co-ordinate.
 *
 *  @param  direction   [OPTIONAL] Keyword that controls the direction of the
 *                      search from the start position.  The default is DOWN,
 *                      the keywords are DOWN, UP, LEFT, and RIGHT.
 *
 *
 */
RexxMethod2(int32_t, lv_findNearestXY, ARGLIST, args, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);
    LVFINDINFO finfo = {0};

    if ( ! isInIconView(hList) )
    {
        goto err_out;
    }

    size_t arraySize;
    size_t argsUsed;
    POINT  point;
    if ( ! getPointFromArglist(context, args, &point, 1, 3, &arraySize, &argsUsed) )
    {
        goto err_out;
    }

    if ( arraySize > (argsUsed + 1) )
    {
        tooManyArgsException(context->threadContext, argsUsed + 1);
        goto err_out;
    }

    finfo.flags = LVFI_NEARESTXY;

    if ( argsUsed == arraySize )
    {
        finfo.vkDirection = VK_DOWN;
    }
    else
    {
        RexxObjectPtr _direction = context->ArrayAt(args, argsUsed + 1);
        CSTRING direction = context->ObjectToStringValue(_direction);

        if ( StrStrIA(direction,      "UP")    != NULL ) finfo.vkDirection = VK_UP;
        else if ( StrStrIA(direction, "LEFT")  != NULL ) finfo.vkDirection  = VK_LEFT;
        else if ( StrStrIA(direction, "RIGHT") != NULL ) finfo.vkDirection  = VK_RIGHT;
        else if ( StrStrIA(direction, "DOWN")  != NULL ) finfo.vkDirection  = VK_DOWN;
        else
        {
            wrongArgValueException(context->threadContext, argsUsed + 1, "DOWN, UP, LEFT, or RIGHT", _direction);
            goto err_out;
        }
    }

    finfo.pt.x = point.x;
    finfo.pt.y = point.y;
    return ListView_FindItem(hList, -1, &finfo);  // TODO what should startItem be????  old code used -1.

err_out:
    return -1;
}

RexxMethod4(RexxObjectPtr, lv_setItemText, uint32_t, index, OPTIONAL_uint32_t, subitem, CSTRING, text, CSELF, pCSelf)
{
    RXCA2T(text);
    ListView_SetItemText(getDChCtrl(pCSelf), index, subitem, (LPTSTR)textT.target()); // rxwchar tocheck : I assume it's safe to cast to non const... Was like that before rxwcharization
    return TheZeroObj;
}

RexxMethod3(RexxStringObject, lv_itemText, uint32_t, index, OPTIONAL_uint32_t, subitem, CSELF, pCSelf)
{
    rxcharT buf[256];
    ListView_GetItemText(getDChCtrl(pCSelf), index, subitem, buf, RXITEMCOUNT(buf));
    RXCT2A(buf);
    return context->String(bufA);
}

RexxMethod2(RexxStringObject, lv_itemState, uint32_t, index, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    uint32_t state = ListView_GetItemState(hList, index, LVIS_CUT | LVIS_DROPHILITED | LVIS_FOCUSED | LVIS_SELECTED);

    char buf[64];
    *buf = '\0';

    if ( state & LVIS_CUT )         strcat(buf, "CUT ");
    if ( state & LVIS_DROPHILITED ) strcat(buf, "DROP ");
    if ( state & LVIS_FOCUSED )     strcat(buf, "FOCUSED ");
    if ( state & LVIS_SELECTED )    strcat(buf, "SELECTED ");

    if ( *buf != '\0' )
    {
        *(buf + strlen(buf) - 1) = '\0';
    }
    return context->String(buf);
}


/** ListView::select()
 *  ListView::deselect()
 *  ListView::focus()
 *
 *
 */
RexxMethod3(RexxObjectPtr, lv_setSpecificState, uint32_t, index, NAME, method, CSELF, pCSelf)
{
    uint32_t state = 0;
    uint32_t mask = 0;

    if ( *method == 'S' )
    {
        mask |= LVIS_SELECTED;
        state |= LVIS_SELECTED;
    }
    else if ( *method == 'D' )
    {
        mask |= LVIS_SELECTED;
    }
    else
    {
        mask |= LVIS_FOCUSED;
        state |= LVIS_FOCUSED;
    }
    ListView_SetItemState(getDChCtrl(pCSelf), index, state, mask);
    return TheZeroObj;
}

RexxMethod3(RexxObjectPtr, lv_setItemState, uint32_t, index, CSTRING, _state, CSELF, pCSelf)
{
    uint32_t state = 0;
    uint32_t mask = 0;

    if ( StrStrIA(_state, "NOTCUT") != NULL )
    {
        mask |= LVIS_CUT;
    }
    else if ( StrStrIA(_state, "CUT") != NULL )
    {
        mask |= LVIS_CUT;
        state |= LVIS_CUT;
    }

    if ( StrStrIA(_state, "NOTDROP") != NULL )
    {
        mask |= LVIS_DROPHILITED;
    }
    else if ( StrStrIA(_state, "DROP") != NULL )
    {
        mask |= LVIS_DROPHILITED;
        state |= LVIS_DROPHILITED;
    }

    if ( StrStrIA(_state, "NOTFOCUSED") != NULL )
    {
        mask |= LVIS_FOCUSED;
    }
    else if ( StrStrIA(_state, "FOCUSED") != NULL )
    {
        mask |= LVIS_FOCUSED;
        state |= LVIS_FOCUSED;
    }

    if ( StrStrIA(_state, "NOTSELECTED") != NULL )
    {
        mask |= LVIS_SELECTED;
    }
    else if ( StrStrIA(_state, "SELECTED") != NULL )
    {
        mask |= LVIS_SELECTED;
        state |= LVIS_SELECTED;
    }

    ListView_SetItemState(getDChCtrl(pCSelf), index, state, mask);
    return TheZeroObj;
}

/** ListView::BkColor=
 *  ListView::TextColor=
 *  ListView::TextBkColor=
 *
 *
 *  @remarks.  This method is hopelessly outdated.  It should take a COLORREF so
 *             that the user has access to all available colors rather than be
 *             limited to 18 colors out of a 256 color display.
 */
RexxMethod3(RexxObjectPtr, lv_setColor, uint32_t, color, NAME, method, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    COLORREF ref = PALETTEINDEX(color);

    if ( *method == 'B' )
    {
        ListView_SetBkColor(hList, ref);
    }
    else if ( method[4] == 'C' )
    {
        ListView_SetTextColor(hList, ref);
    }
    else
    {
        ListView_SetTextBkColor(hList, ref);
    }
    return NULLOBJECT;
}

/** ListView::BkColor
 *  ListView::TextColor
 *  ListView::TextBkColor
 *
 *
 *  @remarks.  This method is hopelessly outdated.  It should return a COLORREF
 *             so that the user has access to all available colors rather than
 *             be limited to 18 colors out of a 256 color display.
 */
RexxMethod2(int32_t, lv_getColor, NAME, method, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    COLORREF ref;

    if ( *method == 'B' )
    {
        ref = ListView_GetBkColor(hList);
    }
    else if ( method[4] == 'C' )
    {
        ref = ListView_GetTextColor(hList);
    }
    else
    {
        ref = ListView_GetTextBkColor(hList);
    }

    for ( int32_t i = 0; i < 256; i++ )
    {
        if ( ref == PALETTEINDEX(i) )
        {
            return i;
        }
    }
    return -1;
}

/** ListView::arrange()
 *  ListView::snaptoGrid()
 *  ListView::alignLeft()
 *  Listview::alignTop()
 *
 *  @remarks  MSDN says of ListView_Arrange():
 *
 *  LVA_ALIGNLEFT  Not implemented. Apply the LVS_ALIGNLEFT style instead.
 *  LVA_ALIGNTOP   Not implemented. Apply the LVS_ALIGNTOP style instead.
 *
 *  However, I don't see that changing the align style in these two cases really
 *  does anything.
 */
RexxMethod2(RexxObjectPtr, lv_arrange, NAME, method, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    int32_t flag = 0;
    switch ( method[5] )
    {
        case 'G' :
            flag = LVA_DEFAULT;
            break;
        case 'O' :
            flag = LVA_SNAPTOGRID;
            break;
        case 'L' :
            applyAlignStyle(hList, false);
            return TheZeroObj;
        case 'T' :
            applyAlignStyle(hList, true);
            return TheZeroObj;
    }
    return (ListView_Arrange(hList, flag) ? TheZeroObj : TheFalseObj);
}

RexxMethod3(int32_t, lv_checkUncheck, int32_t, index, NAME, method, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    if ( ! hasCheckBoxes(hList) )
    {
        return -2;
    }

    ListView_SetCheckState(hList, index, (*method == 'C'));
    return 0;
}

RexxMethod2(RexxObjectPtr, lv_isChecked, int32_t, index, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    if ( hasCheckBoxes(hList) )
    {
        if ( index >= 0 && index <= ListView_GetItemCount(hList) - 1 )
        {
            if ( ListView_GetCheckState(hList, index) != 0 )
            {
                return TheTrueObj;
            }
        }
    }
    return TheFalseObj;
}


RexxMethod2(int32_t, lv_getCheck, int32_t, index, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    if ( ! hasCheckBoxes(hList) )
    {
        return -2;
    }
    if ( index < 0 || index > ListView_GetItemCount(hList) - 1 )
    {
        return -3;
    }
    return (ListView_GetCheckState(hList, index) == 0 ? 0 : 1);
}

/** ListView::hasCheckBoxes()
 */
RexxMethod1(RexxObjectPtr, lv_hasCheckBoxes, CSELF, pCSelf)
{
    return (hasCheckBoxes(getDChCtrl(pCSelf)) ? TheTrueObj : TheFalseObj);
}

/** ListView::getExtendedStyle()
 *  ListView::getExtendedStyleRaw()
 *
 */
RexxMethod2(RexxObjectPtr, lv_getExtendedStyle, NAME, method, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);
    if ( method[16] == 'R' )
    {
        return context->UnsignedInt32(ListView_GetExtendedListViewStyle(hList));
    }
    else
    {
        return extendedStyleToString(context, hList);
    }
}

/** ListView::addExtendedStyle()
 *  ListView::clearExtendedStyle()
 *
 */
RexxMethod3(int32_t, lv_addClearExtendStyle, CSTRING, _style, NAME, method, CSELF, pCSelf)
{
    uint32_t style = parseExtendedStyle(_style);
    if ( style == 0  )
    {
        return -3;
    }

    HWND hList = getDChCtrl(pCSelf);

    if ( *method == 'C' )
    {
        ListView_SetExtendedListViewStyleEx(hList, style, 0);
    }
    else
    {
        ListView_SetExtendedListViewStyleEx(hList, style, style);
    }
    return 0;
}

RexxMethod3(int32_t, lv_replaceExtendStyle, CSTRING, remove, CSTRING, add, CSELF, pCSelf)
{
    uint32_t removeStyles = parseExtendedStyle(remove);
    uint32_t addStyles = parseExtendedStyle(add);
    if ( removeStyles == 0 || addStyles == 0  )
    {
        return -3;
    }

    HWND hList = getDChCtrl(pCSelf);
    ListView_SetExtendedListViewStyleEx(hList, removeStyles, 0);
    ListView_SetExtendedListViewStyleEx(hList, addStyles, addStyles);
    return 0;
}

/** ListView::addStyle()
 *  ListView::removeStyle()
 *
 *  @note  Sets the .SystemErrorCode.
 */
RexxMethod3(uint32_t, lv_addRemoveStyle, CSTRING, style, NAME, method, CSELF, pCSelf)
{
    return changeStyle(context, (pCDialogControl)pCSelf, style, NULL, (*method == 'R'));
}

/** ListView::replaceStyle()
 *
 *
 *  @note  Sets the .SystemErrorCode.
 */
RexxMethod3(uint32_t, lv_replaceStyle, CSTRING, removeStyle, CSTRING, additionalStyle, CSELF, pCSelf)
{
    return changeStyle(context, (pCDialogControl)pCSelf, removeStyle, additionalStyle, true);
}

RexxMethod3(RexxObjectPtr, lv_getItemInfo, uint32_t, index, OPTIONAL_uint32_t, subItem, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    LVITEM lvi;
    rxcharT buf[256];

    lvi.iItem = index;
    lvi.iSubItem = subItem;
    lvi.mask = LVIF_TEXT | LVIF_IMAGE | LVIF_STATE;
    lvi.pszText = buf;
    lvi.cchTextMax = 255;
    lvi.stateMask = LVIS_CUT | LVIS_DROPHILITED | LVIS_FOCUSED | LVIS_SELECTED;

    if ( ! ListView_GetItem(hList, &lvi) )
    {
        return TheNegativeOneObj;
    }

    RexxStemObject stem = context->NewStem("InternalLVItemInfo");

    const rxcharT *lvi_pszText = lvi.pszText;
    RXCT2A(lvi_pszText);
    context->SetStemElement(stem, "!TEXT", context->String(lvi_pszTextA));
    context->SetStemElement(stem, "!IMAGE", context->Int32(lvi.iImage));

    *buf = _T('\0');
    if ( lvi.state & LVIS_CUT)         _tcscat(buf, _T("CUT "));
    if ( lvi.state & LVIS_DROPHILITED) _tcscat(buf, _T("DROP "));
    if ( lvi.state & LVIS_FOCUSED)     _tcscat(buf, _T("FOCUSED "));
    if ( lvi.state & LVIS_SELECTED)    _tcscat(buf, _T("SELECTED "));

    if ( *buf != _T('\0') )
    {
        *(buf + _tcslen(buf) - 1) = _T('\0');
    }
    RXCT2A(buf);
    context->SetStemElement(stem, "!STATE", context->String(bufA));

    return stem;
}

RexxMethod1(int, lv_getColumnCount, CSELF, pCSelf)
{
    return getColumnCount(getDChCtrl(pCSelf));
}

RexxMethod2(RexxObjectPtr, lv_getColumnInfo, uint32_t, index, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    LVCOLUMN lvi;
    rxcharT buf[256];

    lvi.mask = LVCF_TEXT | LVCF_SUBITEM | LVCF_FMT | LVCF_WIDTH;
    lvi.pszText = buf;
    lvi.cchTextMax = 255;

    if ( ! ListView_GetColumn(hList, index, &lvi) )
    {
        return TheNegativeOneObj;
    }

    RexxStemObject stem = context->NewStem("InternalLVColInfo");

    const rxcharT *lvi_pszText = lvi.pszText;
    RXCT2A(lvi_pszText);
    context->SetStemElement(stem, "!TEXT", context->String(lvi_pszTextA));
    context->SetStemElement(stem, "!COLUMN", context->Int32(lvi.iSubItem));
    context->SetStemElement(stem, "!WIDTH", context->Int32(lvi.cx));

    char *align = "LEFT";
    if ( (LVCFMT_JUSTIFYMASK & lvi.fmt) == LVCFMT_CENTER )
    {
        align = "CENTER";
    }
    else if ( (LVCFMT_JUSTIFYMASK & lvi.fmt) == LVCFMT_RIGHT )
    {
        align = "RIGHT";
    }
    context->SetStemElement(stem, "!ALIGN", context->String(align));

    return stem;
}

RexxMethod3(RexxObjectPtr, lv_setColumnWidthPx, uint32_t, index, OPTIONAL_RexxObjectPtr, _width, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    int width = getColumnWidthArg(context, _width, 2);
    if ( width == OOD_BAD_WIDTH_EXCEPTION )
    {
        return TheOneObj;
    }
    return (ListView_SetColumnWidth(hList, index, width) ? TheZeroObj : TheOneObj);
}

RexxMethod5(RexxObjectPtr, lv_modifyColumnPx, uint32_t, index, OPTIONAL_CSTRING, label, OPTIONAL_RexxObjectPtr, _width,
            OPTIONAL_CSTRING, align, CSELF, pCSelf)
{
    RXCA2T(label);
    HWND hList = getDChCtrl(pCSelf);
    LVCOLUMN lvi = {0};

    if ( argumentExists(2) && *label != '\0' )
    {
        lvi.pszText = (LPTSTR)labelT.target(); // rxwchar tocheck : I assume it's safe to cast to non const... Was like that before rxwcharization
        lvi.cchTextMax = (int)_tcslen(labelT);
        lvi.mask |= LVCF_TEXT;
    }
    if ( argumentExists(3) )
    {
        lvi.cx = getColumnWidthArg(context, _width, 3);
        if ( lvi.cx == OOD_BAD_WIDTH_EXCEPTION )
        {
            goto err_out;
        }
        lvi.mask |= LVCF_WIDTH;
    }
    if ( argumentExists(4) && *align != '\0' )
    {
        if ( StrStrIA(align, "CENTER")     != NULL ) lvi.fmt = LVCFMT_CENTER;
        else if ( StrStrIA(align, "RIGHT") != NULL ) lvi.fmt = LVCFMT_RIGHT;
        else if ( StrStrIA(align, "LEFT")  != NULL ) lvi.fmt = LVCFMT_LEFT;
        else
        {
            wrongArgValueException(context->threadContext, 4, "LEFT, RIGHT, or CENTER", align);
            goto err_out;
        }
        lvi.mask |= LVCF_FMT;
    }

    return (ListView_SetColumn(hList, index, &lvi) ? TheZeroObj : TheOneObj);

err_out:
    return TheNegativeOneObj;
}

RexxMethod1(RexxObjectPtr, lv_getColumnOrder, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    int count = getColumnCount(hwnd);
    if ( count == -1 )
    {
        return TheNilObj;
    }

    RexxArrayObject order = context->NewArray(count);
    RexxObjectPtr result = order;

    // the empty array covers the case when count == 0

    if ( count == 1 )
    {
        context->ArrayPut(order, context->Int32(0), 1);
    }
    else if ( count > 1 )
    {
        int *pOrder = (int *)malloc(count * sizeof(int));
        if ( pOrder == NULL )
        {
            outOfMemoryException(context->threadContext);
        }
        else
        {
            if ( ListView_GetColumnOrderArray(hwnd, count, pOrder) == 0 )
            {
                result = TheNilObj;
            }
            else
            {
                for ( int i = 0; i < count; i++)
                {
                    context->ArrayPut(order, context->Int32(pOrder[i]), i + 1);
                }
            }
            free(pOrder);
        }
    }
    return result;
}

RexxMethod2(logical_t, lv_setColumnOrder, RexxArrayObject, order, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    size_t    items   = context->ArrayItems(order);
    int       count   = getColumnCount(hwnd);
    int      *pOrder  = NULL;
    logical_t success = FALSE;

    if ( count != -1 )
    {
        if ( count != items )
        {
            userDefinedMsgException(context->threadContext, "the number of items in the order array does not match the number of columns");
            goto done;
        }

        int *pOrder = (int *)malloc(items * sizeof(int));
        if ( pOrder != NULL )
        {
            RexxObjectPtr item;
            int column;

            for ( size_t i = 0; i < items; i++)
            {
                item = context->ArrayAt(order, i + 1);
                if ( item == NULLOBJECT || ! context->ObjectToInt32(item, &column) )
                {
                    wrongObjInArrayException(context->threadContext, 1, i + 1, "a valid column number");
                    goto done;
                }
                pOrder[i] = column;
            }

            if ( ListView_SetColumnOrderArray(hwnd, count, pOrder) )
            {
                // If we don't redraw the list view and it is already displayed
                // on the screen, it will look mangled.
                RedrawWindow(hwnd, NULL, NULL, RDW_ERASE | RDW_INVALIDATE | RDW_UPDATENOW);
                success = TRUE;
            }
        }
        else
        {
            outOfMemoryException(context->threadContext);
        }
    }

done:
    safeFree(pOrder);
    return success;
}

/** ListView::insertColumnPx()
 *
 *
 *  @param column
 *  @param text
 *  @param width   The width of the column in pixels
 *
 *
 *  @note  Even though the width argument in insertColumn() was documented as
 *         being in pixels, the code actually converted it to dialog units.
 *         This method is provided to really use pixels.
 *
 */
RexxMethod5(int, lv_insertColumnPx, OPTIONAL_uint16_t, column, CSTRING, text, uint16_t, width,
            OPTIONAL_CSTRING, fmt, CSELF, pCSelf)
{
    RXCA2T(text);
    HWND hwnd = getDChCtrl(pCSelf);

    LVCOLUMN lvi = {0};
    int retVal = 0;
    rxcharT szText[256];

    lvi.mask = LVCF_TEXT | LVCF_SUBITEM | LVCF_FMT | LVCF_WIDTH;

    // If omitted, column is 0, which is also the default.
    lvi.iSubItem = column;

    lvi.cchTextMax = (int)_tcslen(textT);
    if ( lvi.cchTextMax > RXITEMCOUNT(szText) - 1 )
    {
        userDefinedMsgException(context->threadContext, 2, "the column title must be less than 256 characters");
        return 0;
    }
    _tcscpy(szText, textT);
    lvi.pszText = szText;
    lvi.cx = width;

    lvi.fmt = LVCFMT_LEFT;
    if ( argumentExists(4) )
    {
        char f = toupper(*fmt);
        if ( f == 'C' )
        {
            lvi.fmt = LVCFMT_CENTER;
        }
        else if ( f == 'R' )
        {
            lvi.fmt = LVCFMT_RIGHT;
        }
    }

    retVal = ListView_InsertColumn(hwnd, lvi.iSubItem, &lvi);
    if ( retVal != -1 && lvi.fmt != LVCFMT_LEFT && lvi.iSubItem == 0 )
    {
        /* According to the MSDN docs: "If a column is added to a
         * list-view control with index 0 (the leftmost column) and with
         * LVCFMT_RIGHT or LVCFMT_CENTER specified, the text is not
         * right-aligned or centered." This is the suggested work around.
         */
        lvi.iSubItem = 1;
        ListView_InsertColumn(hwnd, lvi.iSubItem, &lvi);
        ListView_DeleteColumn(hwnd, 0);
    }
    return retVal;
}

RexxMethod2(int, lv_stringWidthPx, CSTRING, text, CSELF, pCSelf)
{
    return ListView_GetStringWidth(getDChCtrl(pCSelf), text);
}

// TODO Review Implementation before release.  Maybe add / use a .ListViewItem or .LVItem
RexxMethod5(int32_t, lv_addFullRow, CSTRING, text, OPTIONAL_int32_t, itemIndex, OPTIONAL_int32_t, imageIndex,
            OPTIONAL_RexxObjectPtr, subItems, CSELF, pCSelf)
{
    RXCA2T(text);
    HWND hwnd = getDChCtrl(pCSelf);

    if ( argumentOmitted(2) )
    {
        itemIndex = getDCinsertIndex(pCSelf);
    }
    if ( argumentOmitted(3) )
    {
        imageIndex = -1;
    }

    LVITEM lvi;
    lvi.mask = LVIF_TEXT;

    lvi.iItem = itemIndex;
    lvi.iSubItem = 0;
    lvi.pszText = (LPTSTR)textT.target(); // rxwchar tocheck : I assume it's safe to cast to non const... Was like that before rxwcharization

    if ( imageIndex > -1 )
    {
        lvi.iImage = imageIndex;
        lvi.mask |= LVIF_IMAGE;
    }

    itemIndex = ListView_InsertItem(hwnd, &lvi);

    if ( itemIndex == -1 )
    {
        goto done_out;
    }
    ((pCDialogControl)pCSelf)->lastItem = itemIndex;

    if ( argumentOmitted(4) )
    {
        goto done_out;
    }
    if ( ! context->IsArray(subItems) )
    {
        wrongClassException(context->threadContext, 4, "Array");
        goto done_out;
    }

    size_t count = context->ArrayItems((RexxArrayObject)subItems);
    for ( size_t i = 1; i <= count; i++)
    {
        RexxDirectoryObject subItem = (RexxDirectoryObject)context->ArrayAt((RexxArrayObject)subItems, i);
        if ( subItem == NULLOBJECT || ! context->IsDirectory(subItem) )
        {
            wrongObjInArrayException(context->threadContext, 4, i, "a Directory object");
            goto done_out;
        }

        RexxObjectPtr subItemText = context->DirectoryAt(subItem, "TEXT");
        if ( subItemText == NULLOBJECT )
        {
            missingIndexInDirectoryException(context->threadContext, 4, "TEXT");
            goto done_out;
        }
        imageIndex = -1;
        if ( ! rxIntFromDirectory(context, subItem, "ICON", &imageIndex, 4, false) )
        {
            goto done_out;
        }

        lvi.mask = LVIF_TEXT;
        lvi.iSubItem = (int)i;
        const rxcharA *subItemTextValue = context->ObjectToStringValue(subItemText);
        RXCA2T(subItemTextValue);
        lvi.pszText = (LPTSTR)subItemTextValueT.target(); // rxwchar tocheck : I assume it's safe to cast to non const... Was like that before rxwcharization

        if ( imageIndex > -1 )
        {
            lvi.iImage = imageIndex;
            lvi.mask |= LVIF_IMAGE;
        }

        ListView_SetItem(hwnd, &lvi);
    }

done_out:
    return itemIndex;
}


RexxMethod2(RexxObjectPtr, lv_getItemPos, uint32_t, index, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    POINT p;
    if ( ! ListView_GetItemPosition(hList, index, &p) )
    {
        return TheZeroObj;
    }
    return rxNewPoint(context, p.x, p.y);
}

/** ListView::setItemPos()
 *
 *  Moves a list view item to the specified position, (when the list view is in
 *  icon or small icon view.)
 *
 *  @param  index  The index of the item to move.
 *
 *  The other argument(s) specify the new position, and are optional.  If
 *  omitted the position defaults to (0, 0).  The position can either be
 *  specified using a .Point object, or using an x and a y co-ordinate.
 *
 *  @return  -1 if the list view is not in icon or small icon view, otherwise 0.
 */
RexxMethod4(RexxObjectPtr, lv_setItemPos, uint32_t, index, OPTIONAL_RexxObjectPtr, _obj, OPTIONAL_int32_t, y, CSELF, pCSelf)
{
    HWND hList = getDChCtrl(pCSelf);

    if ( ! isInIconView(hList) )
    {
        return TheNegativeOneObj;
    }

    POINT p = {0};
    if ( argumentOmitted(2) )
    {
        // Doesn't matter if arg 3 is omitted or not, we just use it.  The
        // default if omitted is 0.
        p.y = y;
    }
    else
    {
        if ( argumentExists(3) )
        {
            // Arg 2 & arg 3 exist, they must both be integers then.
            if ( ! context->Int32(_obj, (int32_t *)&(p.x)) )
            {
                return wrongRangeException(context->threadContext, 2, INT32_MIN, INT32_MAX, _obj);
            }
            p.y = y;
        }
        else
        {
            // Arg 2 exists and arg 3 doesn't.  Arg 2 can be a .Point or an
            // integer.
            if ( context->IsOfType(_obj, "POINT") )
            {
                PPOINT tmp = (PPOINT)context->ObjectToCSelf(_obj);
                p.x = tmp->x;
                p.y = tmp->y;
            }
            else
            {
                // Arg 2 has to be an integer, p.y is already set at its
                // default of 0
                if ( ! context->Int32(_obj, (int32_t *)&(p.x)) )
                {
                    return wrongRangeException(context->threadContext, 2, INT32_MIN, INT32_MAX, _obj);
                }
            }
        }
    }

    ListView_SetItemPosition32(hList, index, p.x, p.y);
    return TheZeroObj;
}

/** ListView::setImageList()
 *
 *  Sets or removes one of a list-view's image lists.
 *
 *  @param ilSrc  The image list source. Either an .ImageList object that
 *                references the image list to be set, or a single bitmap from
 *                which the image list is constructed, or .nil.  If ilSRC is
 *                .nil, an existing image list, if any is removed.
 *
 *  @param width  [optional]  This arg serves two purposes.  If ilSrc is .nil or
 *                an .ImageList object, this arg indentifies which of the
 *                list-views image lists is being set, normal, small, or state.
 *                The default is LVSI_NORMAL.
 *
 *                If ilSrc is a bitmap, then this arg is the width of a single
 *                image.  The default is the height of the actual bitmap.
 *
 *  @param height [optional]  This arg is only used if ilSrc is a bitmap, in
 *                which case it is the height of the bitmap.  The default is the
 *                height of the actual bitmap
 *
 *  @param ilType [optional]  Only used if ilSrc is a bitmap.  In that case it
 *                indentifies which of the list-views image lists is being set,
 *                normal, small, or state. The default is LVSI_NORMAL.
 *
 *  @return       Returns the exsiting .ImageList object if there is one, or
 *                .nil if there is not an existing object.
 *
 *  @note  When the ilSrc is a single bitmap, an image list is created from the
 *         bitmap.  This method is not as flexible as if the programmer created
 *         the image list herself.  The bitmap must be a number of images, all
 *         the same size, side-by-side in the bitmap.  The width of a single
 *         image determines the number of images.  The image list is created
 *         using the ILC_COLOR8 flag, only.  No mask can be used.  No room is
 *         reserved for adding more images to the image list, etc..
 */
RexxMethod5(RexxObjectPtr, lv_setImageList, RexxObjectPtr, ilSrc,
            OPTIONAL_int32_t, width, OPTIONAL_int32_t, height, OPTIONAL_int32_t, ilType, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);
    oodResetSysErrCode(context->threadContext);

    HIMAGELIST himl = NULL;
    RexxObjectPtr imageList = NULL;
    int type = LVSIL_NORMAL;

    if ( ilSrc == TheNilObj )
    {
        imageList = ilSrc;
        if ( argumentExists(2) )
        {
            type = width;
        }
    }
    else if ( context->IsOfType(ilSrc, "ImageList") )
    {
        imageList = ilSrc;
        himl = rxGetImageList(context, imageList, 1);
        if ( himl == NULL )
        {
            goto err_out;
        }

        if ( argumentExists(2) )
        {
            type = width;
        }
    }
    else
    {
        imageList = oodILFromBMP(context, &himl, ilSrc, width, height, hwnd);
        if ( imageList == NULLOBJECT )
        {
            goto err_out;
        }

        if ( argumentExists(4) )
        {
            type = ilType;
        }
    }

    if ( type > LVSIL_STATE )
    {
        wrongRangeException(context->threadContext, argumentExists(4) ? 4 : 2, LVSIL_NORMAL, LVSIL_STATE, type);
        goto err_out;
    }

    ListView_SetImageList(hwnd, himl, type);
    return rxSetObjVar(context, getLVAttributeName(type), imageList);

err_out:
    return NULLOBJECT;
}

/** ListView::getImageList()
 *
 *  Gets the list-view's specifed image list.
 *
 *  @param  type [optional] Identifies which image list to get.  Normal, small,
 *          or state. Normal is the default.
 *
 *  @return  The image list, if it exists, otherwise .nil.
 */
RexxMethod2(RexxObjectPtr, lv_getImageList, OPTIONAL_uint8_t, type, OSELF, self)
{
    if ( argumentOmitted(1) )
    {
        type = LVSIL_NORMAL;
    }
    else if ( type > LVSIL_STATE )
    {
        wrongRangeException(context->threadContext, 1, LVSIL_NORMAL, LVSIL_STATE, type);
        return NULLOBJECT;
    }

    RexxObjectPtr result = context->GetObjectVariable(getLVAttributeName(type));
    if ( result == NULLOBJECT )
    {
        result = TheNilObj;
    }
    return result;
}


/**
 *  Methods for the .TreeControl class.
 */
#define TREECONTROL_CLASS         "TreeControl"

#define TVSTATE_ATTRIBUTE         "TV!STATEIMAGELIST"
#define TVNORMAL_ATTRIBUTE        "TV!NORMALIMAGELIST"

static CSTRING tvGetAttributeName(uint8_t type)
{
    switch ( type )
    {
        case TVSIL_STATE :
            return TVSTATE_ATTRIBUTE;
        case TVSIL_NORMAL :
        default :
            return TVNORMAL_ATTRIBUTE;
    }
}


static void parseTvModifyOpts(CSTRING opts, TVITEMEX *tvi)
{
    if ( StrStrIA(opts, "NOTBOLD") != NULL )
    {
        tvi->stateMask |= TVIS_BOLD;
    }
    else if ( StrStrIA(opts, "BOLD") != NULL )
    {
        tvi->state |= TVIS_BOLD;
        tvi->stateMask |= TVIS_BOLD;
    }

    if ( StrStrIA(opts, "NOTDROP") != NULL )
    {
        tvi->stateMask |= TVIS_DROPHILITED;
    }
    else if ( StrStrIA(opts, "DROP") != NULL )
    {
        tvi->state |= TVIS_DROPHILITED;
        tvi->stateMask |= TVIS_DROPHILITED;
    }

    if ( StrStrIA(opts, "NOTSELECTED") != NULL )
    {
        tvi->stateMask |= TVIS_SELECTED;
    }
    else if ( StrStrIA(opts, "SELECTED") != NULL )
    {
        tvi->state |= TVIS_SELECTED;
        tvi->stateMask |= TVIS_SELECTED;
    }

    if ( StrStrIA(opts, "NOTCUT") != NULL )
    {
        tvi->stateMask |= TVIS_CUT;
    }
    else if ( StrStrIA(opts, "CUT") != NULL )
    {
        tvi->state |= TVIS_CUT;
        tvi->stateMask |= TVIS_CUT;
    }

    if ( StrStrIA(opts, "NOTEXPANDEDONCE") != NULL )
    {
        tvi->stateMask |= TVIS_EXPANDEDONCE;
    }
    else if ( StrStrIA(opts, "EXPANDEDONCE") != NULL )
    {
        tvi->state |= TVIS_EXPANDEDONCE;
        tvi->stateMask |= TVIS_EXPANDEDONCE;
    }
    else if ( StrStrIA(opts, "NOTEXPANDED") != NULL )
    {
        tvi->stateMask |= TVIS_EXPANDED;
    }
    else if ( StrStrIA(opts, "EXPANDED") != NULL )
    {
        tvi->state |= TVIS_EXPANDED;
        tvi->stateMask |= TVIS_EXPANDED;
    }

    if ( tvi->state != 0 || tvi->stateMask != 0 )
    {
        tvi->mask |= TVIF_STATE;
    }
}


RexxMethod8(RexxObjectPtr, tv_insert, OPTIONAL_CSTRING, _hItem, OPTIONAL_CSTRING, _hAfter, OPTIONAL_CSTRING, label,
            OPTIONAL_int32_t, imageIndex, OPTIONAL_int32_t, selectedImage, OPTIONAL_CSTRING, opts, OPTIONAL_uint32_t, children,
            CSELF, pCSelf)
{
    HWND hwnd  = getDChCtrl(pCSelf);

    TVINSERTSTRUCT  ins;
    TVITEMEX       *tvi = &ins.itemex;

    if ( argumentExists(1) )
    {
        if ( stricmp(_hItem, "ROOT") == 0 )
        {
            ins.hParent = TVI_ROOT;
        }
        else
        {
            ins.hParent = (HTREEITEM)string2pointer(_hItem);
        }
    }
    else
    {
        ins.hParent = TVI_ROOT;
    }

    if ( argumentExists(2) )
    {
        if ( stricmp(_hAfter,      "FIRST") == 0 ) ins.hInsertAfter = TVI_FIRST;
        else if ( stricmp(_hAfter, "SORT")  == 0 ) ins.hInsertAfter = TVI_SORT;
        else if ( stricmp(_hAfter, "LAST")  == 0 ) ins.hInsertAfter = TVI_LAST;
        else ins.hInsertAfter = (HTREEITEM)string2pointer(_hAfter);
    }
    else
    {
        ins.hInsertAfter = TVI_LAST;
    }

    memset(tvi, 0, sizeof(TVITEMEX));

    label         = (argumentOmitted(3) ? "" : label);
    imageIndex    = (argumentOmitted(4) ? -1 : imageIndex);
    selectedImage = (argumentOmitted(5) ? -1 : selectedImage);

    tvi->mask = TVIF_TEXT;
    RXCA2T(label);
    tvi->pszText = (LPTSTR)labelT.target(); // rxwchar tocheck : I assume it's safe to cast to non const... Was like that before rxwcharization
    tvi->cchTextMax = (int)_tcslen(labelT);

    if ( imageIndex > -1 )
    {
        tvi->iImage = imageIndex;
        tvi->mask |= TVIF_IMAGE;
    }
    if ( selectedImage > -1 )
    {
        tvi->iSelectedImage = selectedImage;
        tvi->mask |= TVIF_SELECTEDIMAGE;
    }

    if ( argumentExists(6) )
    {
        if ( StrStrIA(opts, "BOLD")     != NULL ) tvi->state |= TVIS_BOLD;
        if ( StrStrIA(opts, "EXPANDED") != NULL ) tvi->state |= TVIS_EXPANDED;

        if ( tvi->state != 0 )
        {
            tvi->stateMask = tvi->state;
            tvi->mask |= TVIF_STATE;
        }
    }
    if ( children > 0 )
    {
        tvi->cChildren = children;
        tvi->mask |= TVIF_CHILDREN;
    }

    return pointer2string(context, TreeView_InsertItem(hwnd, &ins));
}

RexxMethod7(int32_t, tv_modify, OPTIONAL_CSTRING, _hItem, OPTIONAL_CSTRING, label, OPTIONAL_int32_t, imageIndex,
            OPTIONAL_int32_t, selectedImage, OPTIONAL_CSTRING, opts, OPTIONAL_uint32_t, children, CSELF, pCSelf)
{
    RXCA2T(label);
    HWND hwnd  = getDChCtrl(pCSelf);

    TVITEMEX tvi = {0};

    if ( argumentExists(1) )
    {
        tvi.hItem = (HTREEITEM)string2pointer(_hItem);
    }
    else
    {
        tvi.hItem = TreeView_GetSelection(hwnd);
    }

    if ( tvi.hItem == NULL )
    {
        return -1;
    }
    tvi.mask = TVIF_HANDLE;

    if ( argumentExists(2) )
    {
        tvi.pszText = (LPTSTR)labelT.target(); // rxwchar tocheck : I assume it's safe to cast to non const... Was like that before rxwcharization
        tvi.cchTextMax = (int)_tcslen(labelT);
        tvi.mask |= TVIF_TEXT;
    }
    if ( argumentExists(3) && imageIndex > -1 )
    {
        tvi.iImage = imageIndex;
        tvi.mask |= TVIF_IMAGE;
    }
    if ( argumentExists(4) && imageIndex > -1 )
    {
        tvi.iSelectedImage = selectedImage;
        tvi.mask |= TVIF_SELECTEDIMAGE;
    }
    if ( argumentExists(5) && *opts != '\0' )
    {
        parseTvModifyOpts(opts, &tvi);
    }
    if ( argumentExists(6) )
    {
        tvi.cChildren = (children > 0 ? 1 : 0);
        tvi.mask |= TVIF_CHILDREN;
    }

    return (TreeView_SetItem(hwnd, &tvi) == 0 ? 1 : 0);
}


RexxMethod2(RexxObjectPtr, tv_itemInfo, CSTRING, _hItem, CSELF, pCSelf)
{
    HWND hwnd  = getDChCtrl(pCSelf);

    TVITEM tvi = {0};
    rxcharT buf[256];

    tvi.hItem = (HTREEITEM)string2pointer(_hItem);
    tvi.mask = TVIF_HANDLE | TVIF_TEXT | TVIF_STATE | TVIF_IMAGE | TVIF_CHILDREN | TVIF_SELECTEDIMAGE;
    tvi.pszText = buf;
    tvi.cchTextMax = 255;
    tvi.stateMask = TVIS_EXPANDED | TVIS_BOLD | TVIS_SELECTED | TVIS_EXPANDEDONCE | TVIS_DROPHILITED | TVIS_CUT;

    if ( TreeView_GetItem(hwnd, &tvi) == 0 )
    {
        return TheNegativeOneObj;
    }

    RexxStemObject stem = context->NewStem("InternalTVItemInfo");

    const rxcharT *tvi_pszText = tvi.pszText;
    RXCT2A(tvi_pszText);
    context->SetStemElement(stem, "!TEXT", context->String(tvi_pszTextA));
    context->SetStemElement(stem, "!CHILDREN", (tvi.cChildren > 0 ? TheTrueObj : TheFalseObj));
    context->SetStemElement(stem, "!IMAGE", context->Int32(tvi.iImage));
    context->SetStemElement(stem, "!SELECTEDIMAGE", context->Int32(tvi.iSelectedImage));

    *buf = _T('\0');
    if ( tvi.state & TVIS_EXPANDED     ) _tcscat(buf, _T("EXPANDED "));
    if ( tvi.state & TVIS_BOLD         ) _tcscat(buf, _T("BOLD "));
    if ( tvi.state & TVIS_SELECTED     ) _tcscat(buf, _T("SELECTED "));
    if ( tvi.state & TVIS_EXPANDEDONCE ) _tcscat(buf, _T("EXPANDEDONCE "));
    if ( tvi.state & TVIS_DROPHILITED  ) _tcscat(buf, _T("INDROP "));
    if ( tvi.state & TVIS_CUT          ) _tcscat(buf, _T("CUT "));
    if ( *buf != _T('\0') )
    {
        *(buf + _tcslen(buf) - 1) = _T('\0');
    }
    RXCT2A(buf);
    context->SetStemElement(stem, "!STATE", context->String(bufA));

    return stem;
}


RexxMethod2(RexxObjectPtr, tv_getSpecificItem, NAME, method, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);
    HTREEITEM result = NULL;

    switch ( *method )
    {
        case 'R' :
            result = TreeView_GetRoot(hwnd);
            break;
        case 'S' :
            result = TreeView_GetSelection(hwnd);
            break;
        case 'D' :
            result = TreeView_GetDropHilight(hwnd);
            break;
        case 'F' :
            result = TreeView_GetFirstVisible(hwnd);
            break;
    }
    return pointer2string(context, result);
}


RexxMethod3(RexxObjectPtr, tv_getNextItem, CSTRING, _hItem, NAME, method, CSELF, pCSelf)
{
    HWND      hwnd  = getDChCtrl(pCSelf);
    HTREEITEM hItem = (HTREEITEM)string2pointer(_hItem);
    uint32_t  flag  = TVGN_PARENT;

    if ( strcmp(method, "PARENT")               == 0 ) flag = TVGN_PARENT;
    else if ( strcmp(method, "CHILD")           == 0 ) flag = TVGN_CHILD;
    else if ( strcmp(method, "NEXT")            == 0 ) flag = TVGN_NEXT;
    else if ( strcmp(method, "NEXTVISIBLE")     == 0 ) flag = TVGN_NEXTVISIBLE;
    else if ( strcmp(method, "PREVIOUS")        == 0 ) flag = TVGN_PREVIOUS;
    else if ( strcmp(method, "PREVIOUSVISIBLE") == 0 ) flag = TVGN_PREVIOUSVISIBLE;

    return pointer2string(context, TreeView_GetNextItem(hwnd, hItem, flag));
}


/** TreeControl::select()
 *  TreeControl::makeFirstVisible()
 *  TreeControl::dropHighLight()
 */
RexxMethod3(RexxObjectPtr, tv_selectItem, OPTIONAL_CSTRING, _hItem, NAME, method, CSELF, pCSelf)
{
    HWND      hwnd  = getDChCtrl(pCSelf);
    HTREEITEM hItem = NULL;
    uint32_t  flag;

    if ( argumentExists(1) )
    {
        hItem = (HTREEITEM)string2pointer(_hItem);
    }

    switch ( *method )
    {
        case 'S' :
            flag = TVGN_CARET;
            break;
        case 'M' :
            flag = TVGN_FIRSTVISIBLE;
            break;
        default:
            flag = TVGN_DROPHILITE;
    }
    return (TreeView_Select(hwnd, hItem, flag) ? TheZeroObj : TheOneObj);
}


/** TreeControl::expand()
 *  TreeControl::collapse()
 *  TreeControl::collapseAndReset()
 *  TreeControl::toggle()
 */
RexxMethod3(RexxObjectPtr, tv_expand, CSTRING, _hItem, NAME, method, CSELF, pCSelf)
{
    HWND      hwnd  = getDChCtrl(pCSelf);
    HTREEITEM hItem = (HTREEITEM)string2pointer(_hItem);
    uint32_t  flag  = TVE_EXPAND;

    if ( *method == 'C' )
    {
        flag = (method[8] == 'A' ? (TVE_COLLAPSERESET | TVE_COLLAPSE) : TVE_COLLAPSE);
    }
    else if ( *method == 'T' )
    {
        flag = TVE_TOGGLE;
    }
    return (TreeView_Expand(hwnd, hItem, flag) ? TheZeroObj : TheOneObj);
}


RexxMethod2(RexxObjectPtr, tv_hitTestInfo, ARGLIST, args, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    size_t sizeArray;
    size_t argsUsed;
    POINT  point;
    if ( ! getPointFromArglist(context, args, &point, 1, 2, &sizeArray, &argsUsed) )
    {
        return NULLOBJECT;
    }

    if ( argsUsed == 1 && sizeArray == 2)
    {
        return tooManyArgsException(context->threadContext, 1);
    }

    TVHITTESTINFO hti;
    hti.pt.x = point.x;
    hti.pt.y = point.y;

    HTREEITEM hItem = TreeView_HitTest(hwnd, &hti);

    RexxDirectoryObject result = context->NewDirectory();

    context->DirectoryPut(result, pointer2string(context, TreeView_HitTest(hwnd, &hti)), "HITEM");

    char buf[128];
    *buf = '\0';

    if ( hti.flags & TVHT_ABOVE          ) strcat(buf, "ABOVE ");
    if ( hti.flags & TVHT_BELOW          ) strcat(buf, "BELOW ");
    if ( hti.flags & TVHT_NOWHERE        ) strcat(buf, "NOWHERE ");
    if ( hti.flags & TVHT_ONITEM         ) strcat(buf, "ONITEM ");
    if ( hti.flags & TVHT_ONITEMBUTTON   ) strcat(buf, "ONBUTTON ");
    if ( hti.flags & TVHT_ONITEMICON     ) strcat(buf, "ONICON ");
    if ( hti.flags & TVHT_ONITEMINDENT   ) strcat(buf, "ONINDENT ");
    if ( hti.flags & TVHT_ONITEMLABEL    ) strcat(buf, "ONLABEL ");
    if ( hti.flags & TVHT_ONITEMRIGHT    ) strcat(buf, "ONRIGHT ");
    if ( hti.flags & TVHT_ONITEMSTATEICON) strcat(buf, "ONSTATEICON ");
    if ( hti.flags & TVHT_TOLEFT         ) strcat(buf, "TOLEFT ");
    if ( hti.flags & TVHT_TORIGHT        ) strcat(buf, "TORIGHT ");

    if ( *buf != '\0' )
    {
        *(buf + strlen(buf) - 1) = '\0';
    }
    context->DirectoryPut(result, context->String(buf),"LOCATION");
    return result;
}


/** TreeControl::setImageList()
 *
 *  Sets or removes one of a tree-view's image lists.
 *
 *  @param ilSrc  The image list source. Either an .ImageList object that
 *                references the image list to be set, or a single bitmap from
 *                which the image list is constructed, or .nil.  If ilSRC is
 *                .nil, an existing image list, if any is removed.
 *
 *  @param width  [optional]  This arg serves two purposes.  If ilSrc is .nil or
 *                an .ImageList object, this arg indentifies which of the
 *                tree-views image lists is being set, normal, or state. The
 *                default is TVSI_NORMAL.
 *
 *                If ilSrc is a bitmap, then this arg is the width of a single
 *                image.  The default is the height of the actual bitmap.
 *
 *  @param height [optional]  This arg is only used if ilSrc is a bitmap, in which case it
 *                is the height of the bitmap.  The default is the height of the
 *                actual bitmap
 *
 *  @return       Returns the exsiting .ImageList object if there is one, or
 *                .nil if there is not an existing object.
 *
 *  @note  When the ilSrc is a single bitmap, an image list is created from the
 *         bitmap.  This method is not as flexible as if the programmer created
 *         the image list herself.  The bitmap must be a number of images, all
 *         the same size, side-by-side in the bitmap.  The width of a single
 *         image determines the number of images.  The image list is created
 *         using the ILC_COLOR8 flag, only.  No mask can be used.  No room is
 *         reserved for adding more images to the image list, etc..
 *
 *         The image list can only be assigned to the normal image list.  There
 *         is no way to use the image list for the state image list.
 */
RexxMethod4(RexxObjectPtr, tv_setImageList, RexxObjectPtr, ilSrc,
            OPTIONAL_int32_t, width, OPTIONAL_int32_t, height, CSELF, pCSelf)
{
    oodResetSysErrCode(context->threadContext);
    HWND hwnd = getDChCtrl(pCSelf);

    HIMAGELIST himl = NULL;
    int type = TVSIL_NORMAL;
    RexxObjectPtr imageList = NULLOBJECT;

    if ( ilSrc == TheNilObj )
    {
        imageList = ilSrc;
        if ( argumentExists(2) )
        {
            type = width;
        }
    }
    else if ( context->IsOfType(ilSrc, "ImageList") )
    {
        imageList = ilSrc;
        himl = rxGetImageList(context, imageList, 1);
        if ( himl == NULL )
        {
            goto err_out;
        }
        if ( argumentExists(2) )
        {
            type = width;
        }
    }
    else
    {
        imageList = oodILFromBMP(context, &himl, ilSrc, width, height, hwnd);
        if ( imageList == NULLOBJECT )
        {
            goto err_out;
        }
    }

    if ( type != TVSIL_STATE && type != TVSIL_NORMAL )
    {
        invalidTypeException(context->threadContext, 2, " TVSIL_XXX flag");
        goto err_out;
    }

    TreeView_SetImageList(hwnd, himl, type);
    return rxSetObjVar(context, tvGetAttributeName(type), imageList);

err_out:
    return NULLOBJECT;
}

/** TreeControl::getImageList()
 *
 *  Gets the tree-view's specifed image list.
 *
 *  @param  type [optional] Identifies which image list to get, normal, or
 *               state. Normal is the default.
 *
 *  @return  The image list, if it exists, otherwise .nil.
 */
RexxMethod2(RexxObjectPtr, tv_getImageList, OPTIONAL_uint8_t, type, OSELF, self)
{
    if ( argumentOmitted(1) )
    {
        type = TVSIL_NORMAL;
    }
    else if ( type != TVSIL_STATE && type != TVSIL_NORMAL )
    {
        return invalidTypeException(context->threadContext, 2, " TVSIL_XXX flag");
    }

    RexxObjectPtr result = context->GetObjectVariable(tvGetAttributeName(type));
    if ( result == NULLOBJECT )
    {
        result = TheNilObj;
    }
    return result;
}


/**
 *  Methods for the .TabControl class.
 */
#define TABCONTROL_CLASS          "TabControl"

#define TABIMAGELIST_ATTRIBUTE    "TAB!IMAGELIST"


/** TabControl::setItemSize()
 *
 *  Sets the width and height of the tabs.
 *
 *  @param  size  The new size (cx, cy), in pixels.  The amount can be specified
 *                in these formats:
 *
 *      Form 1:  A .Size object.
 *      Form 2:  cx, cy
 *
 *  @return  The previous size of the tabs, as a .Size object
 *
 *  @note  You can use a .Point object instead of a .Size object to specify the
 *         new size, although semantically that is incorrect.
 */
RexxMethod2(RexxObjectPtr, tab_setItemSize, ARGLIST, args, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    size_t sizeArray;
    size_t argsUsed;
    POINT  point;
    if ( ! getPointFromArglist(context, args, &point, 1, 2, &sizeArray, &argsUsed) )
    {
        return NULLOBJECT;
    }

    if ( argsUsed == 1 && sizeArray == 2)
    {
        return tooManyArgsException(context->threadContext, 1);
    }

    uint32_t oldSize = TabCtrl_SetItemSize(hwnd, point.x, point.y);
    return rxNewSize(context, LOWORD(oldSize), HIWORD(oldSize));
}


/** TabControl::setPadding()
 *
 *  Sets the amount of space (padding) around each tab's icon and label.
 *
 *  @param  size  The padding size (cx, cy), in pixels.  The amount can be
 *                specified in these formats:
 *
 *      Form 1:  A .Size object.
 *      Form 2:  cx, cy
 *
 *  @return  0, always.
 *
 *  @note  You can use a .Point object instead of a .Size object to specify the
 *         new size, although semantically that is incorrect.
 */
RexxMethod2(RexxObjectPtr, tab_setPadding, ARGLIST, args, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    size_t sizeArray;
    size_t argsUsed;
    POINT  point;
    if ( ! getPointFromArglist(context, args, &point, 1, 2, &sizeArray, &argsUsed) )
    {
        return NULLOBJECT;
    }

    if ( argsUsed == 1 && sizeArray == 2)
    {
        return tooManyArgsException(context->threadContext, 1);
    }

    TabCtrl_SetPadding(hwnd, point.x, point.y);
    return TheZeroObj;
}


RexxMethod5(int32_t, tab_insert, OPTIONAL_int32_t, index, OPTIONAL_CSTRING, label, OPTIONAL_int32_t, imageIndex,
            OPTIONAL_RexxObjectPtr, userData, CSELF, pCSelf)
{
    RXCA2T(label);
    HWND hwnd = getDChCtrl(pCSelf);

    if ( argumentOmitted(1) )
    {
        index = ((pCDialogControl)pCSelf)->lastItem;
    }

    TCITEM ti = {0};
    index++;

    ti.mask = TCIF_TEXT | TCIF_IMAGE | TCIF_PARAM;
    ti.pszText = (argumentOmitted(2) ? _T("") : labelT.target()); // no compilation error ? assign const to non const...
    ti.iImage  = (argumentOmitted(3) ? -1 : imageIndex);
    ti.lParam  = (LPARAM)(argumentOmitted(4) ? TheZeroObj : userData);

    int32_t ret = TabCtrl_InsertItem(hwnd, index, &ti);
    if ( ret != -1 )
    {
        ((pCDialogControl)pCSelf)->lastItem = ret;
    }
    return ret;
}


RexxMethod5(int32_t, tab_modify, int32_t, index, OPTIONAL_CSTRING, label, OPTIONAL_int32_t, imageIndex,
            OPTIONAL_RexxObjectPtr, userData, CSELF, pCSelf)
{
    RXCA2T(label);
    HWND hwnd = getDChCtrl(pCSelf);

    TCITEM ti = {0};

    if ( argumentExists(2) )
    {
        ti.mask |= TCIF_TEXT;
        ti.pszText = (LPTSTR)labelT.target(); // rxwchar tocheck : I assume it's safe to cast to non const... Was like that before rxwcharization
    }
    if ( argumentExists(3) )
    {
        ti.mask |= TCIF_IMAGE;
        ti.iImage = imageIndex;
    }
    if ( argumentExists(4) )
    {
        ti.mask |= TCIF_PARAM;
        ti.lParam = (LPARAM)userData;
    }

    if ( ti.mask == 0 )
    {
        return 1;
    }

    return (TabCtrl_SetItem(hwnd, index, &ti) ? 0 : 1);
}


RexxMethod2(int32_t, tab_addSequence, ARGLIST, args, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    TCITEM ti = {0};
    ti.mask = TCIF_TEXT;

    int32_t ret = -1;
    int32_t index = ((pCDialogControl)pCSelf)->lastItem;
    size_t count = context->ArraySize(args);

    for ( size_t i = 1; i <= count; i++ )
    {
        index++;
        RexxObjectPtr arg = context->ArrayAt(args, i);
        if ( arg == NULLOBJECT )
        {
            missingArgException(context->threadContext, i);
            goto done_out;
        }

        const rxcharA *argValue = context->ObjectToStringValue(arg);
        RXCA2T(argValue);
        ti.pszText = (LPTSTR)argValueT.target(); // rxwchar tocheck : I assume it's safe to cast to non const... Was like that before rxwcharization

        ret = TabCtrl_InsertItem(hwnd, index, &ti);
        if ( ret == -1 )
        {
            goto done_out;
        }

        ((pCDialogControl)pCSelf)->lastItem = ret;
    }

done_out:
    return ret;
}


RexxMethod2(int32_t, tab_addFullSeq, ARGLIST, args, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    TCITEM ti = {0};
    ti.mask = TCIF_TEXT;

    int32_t ret = -1;
    int32_t index = ((pCDialogControl)pCSelf)->lastItem;
    size_t count = context->ArraySize(args);

    for ( size_t i = 1; i <= count; i += 3 )
    {
        index++;
        RexxObjectPtr label = context->ArrayAt(args, i);
        if ( label == NULLOBJECT )
        {
            missingArgException(context->threadContext, i);
            goto done_out;
        }

        const rxcharA *labelValue = context->ObjectToStringValue(label);
        RXCA2T(labelValue);
        ti.pszText = (LPTSTR)labelValueT.target(); // rxwchar tocheck : I assume it's safe to cast to non const... Was like that before rxwcharization

        RexxObjectPtr _imageIndex = context->ArrayAt(args, i + 1);
        RexxObjectPtr userData = context->ArrayAt(args, i + 2);

        if ( _imageIndex != NULLOBJECT )
        {
            int32_t imageIndex;
            if ( ! context->Int32(_imageIndex, &imageIndex) )
            {
                notPositiveArgException(context->threadContext, i + 1, _imageIndex);
                goto done_out;
            }

            ti.mask |= TCIF_IMAGE;
            ti.iImage = imageIndex;
        }
        if ( userData != NULLOBJECT )
        {
            ti.mask |= TCIF_PARAM;
            ti.lParam = (LPARAM)userData;
        }

        int32_t ret = TabCtrl_InsertItem(hwnd, index, &ti);
        if ( ret == -1 )
        {
            goto done_out;
        }

        ((pCDialogControl)pCSelf)->lastItem = ret;
    }

done_out:
    return ret;
}


RexxMethod2(RexxObjectPtr, tab_itemInfo, int32_t, index, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    rxcharT buff[256];
    TCITEM ti;

    ti.mask = TCIF_TEXT | TCIF_IMAGE | TCIF_PARAM;
    ti.pszText = buff;
    ti.cchTextMax = 255;

    RexxObjectPtr result = TheNegativeOneObj;

    if ( TabCtrl_GetItem(hwnd, index, &ti) )
    {
        RexxStemObject stem = context->NewStem("ItemInfo");
        const rxcharT *ti_pszText = ti.pszText;
        RXCT2A(ti_pszText);
        context->SetStemElement(stem, "!TEXT", context->String(ti_pszTextA));
        context->SetStemElement(stem, "!IMAGE", context->Int32(ti.iImage));
        context->SetStemElement(stem, "!PARAM", (ti.lParam == 0 ? TheZeroObj : (RexxObjectPtr)ti.lParam));
        result = stem;
    }
    return result;
}


RexxMethod1(RexxObjectPtr, tab_selected, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    rxcharT buff[256];
    TCITEM ti = {0};

    ti.mask = TCIF_TEXT;
    ti.pszText = buff;
    ti.cchTextMax = 255;

    if ( TabCtrl_GetItem(hwnd, TabCtrl_GetCurSel(hwnd), &ti) == 0 )
    {
        return TheZeroObj;
    }
    RXCT2A(buff);
    return context->String(buffA);
}


RexxMethod2(int32_t, tab_select, CSTRING, text, CSELF, pCSelf)
{
    RXCA2T(text);
    HWND hwnd = getDChCtrl(pCSelf);
    int32_t result = -1;

    rxcharT buff[256];
    TCITEM ti = {0};
    size_t count;

    count = TabCtrl_GetItemCount(hwnd);
    if ( count == 0 )
    {
        goto done_out;
    }

    ti.mask = TCIF_TEXT;
    ti.cchTextMax = 255;

    size_t i = 0;
    while ( i < count)
    {
        // Note that MSDN says: If the TCIF_TEXT flag is set in the mask member
        // of the TCITEM structure, the control may change the pszText member of
        // the structure to point to the new text instead of filling the buffer
        // with the requested text. The control may set the pszText member to
        // NULL to indicate that no text is associated with the item.
        ti.pszText = buff;

        if ( TabCtrl_GetItem(hwnd, i, &ti) == 0 )
        {
            goto done_out;
        }

        if ( ti.pszText != NULL && _tcsicmp(ti.pszText, textT) == 0 )
        {
            result = TabCtrl_SetCurSel(hwnd, i);
            break;
        }
        i++;
    }

done_out:
    return result;
}


RexxMethod3(RexxObjectPtr, tab_getItemRect, uint32_t, item, RexxObjectPtr, rect, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    PRECT r = rxGetRect(context, rect, 2);
    if ( r == NULL )
    {
        return NULLOBJECT;
    }

    return (TabCtrl_GetItemRect(hwnd, item, r) == 0 ? TheFalseObj : TheTrueObj);
}


/** TabControl::calcWindowRect()
 *
 *  calcWindowRect() takes a display rectangle and adjusts the rectangle to be
 *  the window rect of the tab control needed for that display size.
 *
 *  Therefore, if the display size must be a fixed size, use calcWindowRect() to
 *  receive the size the tab control needs to be and use it to set the size for
 *  the control.
 *
 *  @param  [IN / OUT] On entry, a .Rect object specifying the display rectangle
 *                     and on return the corrsponding window rect for the tab.
 *
 *  @return  The return is 0 and has no meaning.
 *
 *  TabControl::calcDisplayRect()
 *
 *  caclDisplayRect() takes the window rect of the tab control, and adjusts the
 *  rectangle to the size the display will be.
 *
 *  So, if the tab control needs to be a fixed size, use calcDisplayRect() to
 *  get the size the display rect will be for the fixed size of the tab control
 *  and use that to set the size of the control or dialog set into the tab
 *  control
 *
 *  @param  [IN / OUT] On entry, a .Rect object specifying the window rect of
 *                     the tab, and on return the corrsponding display rect.
 *
 *  @return  The return is 0 and has no meaning.
 *
 *  @remarks  MSDN says of the second arg to TabCtrl_AdjustRect():
 *
 *            Operation to perform. If this parameter is TRUE, prc specifies a
 *            display rectangle and receives the corresponding window rectangle.
 *            If this parameter is FALSE, prc specifies a window rectangle and
 *            receives the corresponding display area.
 */
RexxMethod3(RexxObjectPtr, tab_calcRect, RexxObjectPtr, rect, NAME, method, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);

    PRECT r = rxGetRect(context, rect, 1);
    if ( r == NULL )
    {
        return NULLOBJECT;
    }

    BOOL calcWindowRect = (method[4] == 'W');

    TabCtrl_AdjustRect(hwnd, calcWindowRect, r);
    return TheZeroObj;
}


/** TabControl::setImageList()
 *
 *  Sets or removes the image list for a Tab control.
 *
 *  @param ilSrc  The image list source. Either an .ImageList object that
 *                references the image list to be set, or a single bitmap from
 *                which the image list is constructed, or .nil.  If ilSRC is
 *                .nil, an existing image list, if any is removed.
 *
 *  @param width  [optional]  This arg is only used if ilSrc is a single bitmap.
 *                Then this arg is the width of a single image.  The default is
 *                the height of the actual bitmap.
 *
 *  @param height [optional]  This arg is only used if ilSrc is a bitmap, in
 *                which case it is the height of the bitmap.  The default is the
 *                height of the actual bitmap
 *
 *  @return       Returns the exsiting .ImageList object if there is one, or
 *                .nil if there is not an existing object.
 *
 *  @note  When the ilSrc is a single bitmap, an image list is created from the
 *         bitmap.  This method is not as flexible as if the programmer created
 *         the image list herself.  The bitmap must be a number of images, all
 *         the same size, side-by-side in the bitmap.  The width of a single
 *         image determines the number of images.  The image list is created
 *         using the ILC_COLOR8 flag, only.  No mask can be used.  No room is
 *         reserved for adding more images to the image list, etc..
 */
RexxMethod4(RexxObjectPtr, tab_setImageList, RexxObjectPtr, ilSrc,
            OPTIONAL_int32_t, width, OPTIONAL_int32_t, height, CSELF, pCSelf)
{
    HWND hwnd = getDChCtrl(pCSelf);
    oodResetSysErrCode(context->threadContext);

    HIMAGELIST himl = NULL;
    RexxObjectPtr imageList = NULLOBJECT;

    if ( ilSrc == TheNilObj )
    {
        imageList = ilSrc;
    }
    else if ( context->IsOfType(ilSrc, "ImageList") )
    {
        imageList = ilSrc;
        himl = rxGetImageList(context, imageList, 1);
        if ( himl == NULL )
        {
            goto err_out;
        }
    }
    else
    {
        imageList = oodILFromBMP(context, &himl, ilSrc, width, height, hwnd);
        if ( imageList == NULLOBJECT )
        {
            goto err_out;
        }
    }

    TabCtrl_SetImageList(hwnd, himl);
    return rxSetObjVar(context, TABIMAGELIST_ATTRIBUTE, imageList);

err_out:
    return NULLOBJECT;
}

/** TabControl::getImageList()
 *
 *  Gets the Tab control's image list.
 *
 *  @return  The image list, if it exists, otherwise .nil.
 */
RexxMethod1(RexxObjectPtr, tab_getImageList, OSELF, self)
{
    RexxObjectPtr result = context->GetObjectVariable(TABIMAGELIST_ATTRIBUTE);
    return (result == NULLOBJECT) ? TheNilObj : result;
}

