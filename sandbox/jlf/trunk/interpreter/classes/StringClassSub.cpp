/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2009 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.oorexx.org/license.html                          */
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
/******************************************************************************/
/* REXX Kernel                                                                */
/*                                                                            */
/* substring oriented REXX string methods                                     */
/*                                                                            */
/******************************************************************************/

#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "RexxCore.h"
#include "StringClass.hpp"
#include "ActivityManager.hpp"
#include "StringUtil.hpp"
#include "ProtectedObject.hpp"


/* the CENTER function (and the CENTRE function) */
/******************************************************************************/
/* Arguments:  String len, string pad character                               */
/*                                                                            */
/*  Returned:  string                                                         */
/******************************************************************************/
// in behaviour
RexxString *RexxString::center(RexxInteger *_length,
                               RexxString  *pad)
{
    codepoint_t     PadChar;                    /* pad character                     */
    size_t   LeftPad;                    /* required left pads                */
    size_t   RightPad;                   /* required right pads               */
    size_t   Space;                      /* result string size                */
    size_t   Width;                      /* centering width                   */
    size_t   Len;                        /* string length                     */
    RexxString *Retval;                  /* return string                     */

                                         /* see how long result should be     */
    Width = lengthArgument(_length, ARG_ONE);

    /* Get pad character (optional) blank*/
    /*  is used if omitted.              */
    PadChar = optionalPadArgument(pad, ' ', ARG_TWO);
    Len = this->getLength();                  /* get length of input to center     */
    if (Width == Len)                    /* if input length and               */
    {
        /* requested are  the same           */
        Retval = this;                     /* then copy input                   */
    }
    else if (Width == 0)                     /* centered in zero?                 */
    {
        Retval = OREF_NULLSTRING;          /* return a null string              */
    }
    else
    {
        if (Width > Len)
        {                 /* otherwise                         */
                          /* if requested larger               */
            LeftPad = (Width - Len) / 2;     /* get left pad count                */
            RightPad = (Width - Len)-LeftPad;/* and right pad count               */
            Space = RightPad + LeftPad + Len;/* total space required              */
                                             /* allocate space                    */
            Retval = (RexxString *)raw_string(Space);
            /* set left pad characters           */
            memset(Retval->getWritableData(), (int)PadChar, LeftPad);
            if (Len != 0)                         /* something to copy?                */
            {
                /* copy the string                   */
                memcpy(Retval->getWritableData() + LeftPad, this->getStringData(), Len);
            }
            /* now the trailing pad chars        */
            memset(Retval->getWritableData() + LeftPad + Len, (int)PadChar, RightPad);
        }
        else
        {                             /* requested smaller than            */
                                      /* input                             */
            LeftPad = (Len - Width) / 2;     /* get left truncate count           */
                                             /* copy the data                     */
            Retval = (RexxString *)new_string(this->getStringData() + LeftPad, Width);
        }
    }
    return Retval;                       /* done, return output buffer        */
}

/* the DELSTR function */
/******************************************************************************/
/* Arguments:  Starting position of string to be deleted                      */
/*             length of string to be deleted                                 */
/*  Returned:  string                                                         */
/******************************************************************************/
// in behaviour
RexxString *RexxString::delstr(RexxInteger *position,
                               RexxInteger *_length)
{
    RexxString *Retval;                  /* return value:                     */
    size_t   BackLen;                    /* end string section                */
    size_t   StringLen;                  /* original string length            */
    size_t   DeleteLen;                  /* deleted length                    */
    size_t   DeletePos;                  /* delete position                   */
    char    *Current;                    /* current copy position             */

    StringLen = this->getLength();            /* get string length                 */
    /* get start string position         */
    DeletePos = positionArgument(position, ARG_ONE);
    /* get the length to delete          */
    DeleteLen = optionalLengthArgument(_length, StringLen - DeletePos + 1, ARG_TWO);

    if (DeletePos > StringLen)           /* beyond string bounds?             */
    {
        Retval = this;                     /* return string unchanged           */
    }
    else
    {                               /* need to actually delete           */
        DeletePos--;                       /* make position origin zero         */
                                           /* deleting more than string?        */
        if (DeleteLen >= (StringLen - DeletePos))
        {
            BackLen = 0;                     /* no back part                      */
        }
        else                               /* find length to delete             */
        {
            BackLen = StringLen - (DeletePos + DeleteLen);
        }
        /* allocate result string            */
        Retval = (RexxString *)raw_string(DeletePos + BackLen);
        /* point to string part              */
        Current = Retval->getWritableData();
        if (DeletePos != 0)
        {                   /* have a front part?                */
                            /* copy it                           */
            memcpy(Current, this->getStringData(), DeletePos);
            Current += DeletePos;            /* step past the front               */
        }

        if (BackLen != 0)
        {                     /* have a trailing part              */
                              /* copy that over                    */
            memcpy(Current, this->getStringData() + DeletePos + DeleteLen, BackLen);
        }
    }
    return Retval;                       /* return the new string             */
}

/* the INSERT function */
/******************************************************************************/
/* Arguments:  string to be inserted                                          */
/*             position in self to place new string                           */
/*             length of new string to insert, padded if necessary            */
/*             pad character to use.                                          */
/*  Returned:  string                                                         */
/******************************************************************************/
// in behaviour
RexxString *RexxString::insert(RexxString  *newStrObj,
                               RexxInteger *position,
                               RexxInteger *_length,
                               RexxString  *pad)
{
    RexxString *Retval;                  /* return string                     */
    RexxString *newStr;                  /* return string                     */
    codepoint_t     PadChar;                    /* HugeString for Padding char       */
    size_t   ReqLenChar;                 /* Actual req char len of new.       */
    size_t   ReqPadChar;                 /* Actual req char len of new.       */
    size_t   ReqLeadPad;                 /* Actual req char len of new.       */
    size_t   TargetSize;                 /* byte size of target string        */
    size_t   NCharLen;                   /* Char len of new HugeString.       */
    size_t   TCharLen;                   /* Char len of target HugeStr.       */
    size_t   FCharLen;                   /* Char len of front portion.        */
    size_t   BCharLen;                   /* Char len of back portion.         */
    size_t   BuffSiz;                    /* Estimated result area size.       */
    size_t   NChar;                      /* Character position.               */
    char *   Current;                    /* current copy location             */

    TCharLen = this->getLength();             /* get the target string length      */
    /* get the needle string (and length)*/
    newStr = stringArgument(newStrObj, OREF_positional, ARG_ONE);
    ProtectedObject p(newStr);
    NCharLen = newStr->getLength();
    /* use optionalLengthArgument for starting  */
    /* position becase a value of 0 IS   */
    /* valid for INSERT                  */
    NChar = optionalLengthArgument(position, 0, ARG_TWO);
    /* get the optional length, using the*/
    /* needle length as the defaul       */
    ReqLenChar = optionalLengthArgument(_length, NCharLen, ARG_THREE);

    /*  is used if omitted.              */
    PadChar = optionalPadArgument(pad, ' ', ARG_FOUR);
    ReqLeadPad = 0;                      /* set lead pad to zero              */
    TargetSize = TCharLen;               /* copy the target size              */

    if (NChar == 0)
    {                    /* inserting at the front?           */
        ReqLeadPad = 0;                    /* no leading pads                   */
        FCharLen = 0;                      /* no front part                     */
        BCharLen = TCharLen;               /* trailer is entire target          */
    }
    else if (NChar >= TCharLen)
    {        /* need leading pads?                */
        ReqLeadPad = (NChar - TCharLen);   /* calculate needed                  */
        FCharLen = TCharLen;               /* front part is all                 */
        BCharLen = 0;                      /* trailer is nothing                */
    }
    else
    {                               /* have a split                      */
        ReqLeadPad = 0;                    /* no leading pad                    */
        FCharLen = NChar;                  /* NChar front chars                 */
        BCharLen = TCharLen - NChar;       /* and some trailer too              */
    }
    NCharLen = Numerics::minVal(NCharLen, ReqLenChar);/* truncate new, if needed           */
    ReqPadChar = ReqLenChar - NCharLen;  /* calculate pad chars               */
                                         /* calculate result size             */
    BuffSiz = NCharLen + TargetSize + ReqPadChar + ReqLeadPad;
    Retval = raw_string(BuffSiz);        /* allocate the result               */
    Current = Retval->getWritableData(); /* point to start                    */

    if (FCharLen != 0)
    {                      /* have leading chars                */
                           /* copy the leading part             */
        memcpy(Current, this->getStringData(), FCharLen);
        Current += FCharLen;               /* step copy location                */
    }
    if (ReqLeadPad != 0)
    {                    /* if required leading pads          */
                         /* add the pads now                  */
        memset(Current, (int)PadChar, ReqLeadPad);
        Current += ReqLeadPad;             /* step the output pointer           */
    }

    if (NCharLen != 0)
    {                      /* new string to copy?               */
                           /* copy the inserted part            */
        memcpy(Current, newStr->getStringData(), NCharLen);
        Current += NCharLen;               /* step copy location                */ //
    }

    if (ReqPadChar != 0)
    {                    /* if required trailing pads         */
                         /* add the pads now                  */
        memset(Current, (int)PadChar, ReqPadChar);
        Current += ReqPadChar;             /* step the output pointer           */
    }

    if (BCharLen != 0)
    {                      /* have trailing chars               */
                           /* copy the leading part             */
        memcpy(Current, this->getStringData() + FCharLen, BCharLen);
    }
    return Retval;                       /* Return the new string             */
}

/* the LEFT function */
/******************************************************************************/
/* Arguments:  String len, string pad character                               */
/*                                                                            */
/*  Returned:  string                                                         */
/******************************************************************************/
// in behaviour
RexxString *RexxString::left(RexxInteger *_length,
                             RexxString  *pad)
{
    codepoint_t      PadChar;                   /* pad character                     */
    size_t    Size;                      /* requested size                    */
    size_t    Length;                    /* string length                     */
    RexxString *Retval;                  /* returned result                   */
    char *    Current;                   /* current copy location             */
    size_t    CopyLength;                /* length to copy                    */

                                         /* get the target length             */
    Size = lengthArgument(_length, ARG_ONE);

    /*  is used if omitted.              */
    PadChar = optionalPadArgument(pad, ' ', ARG_TWO);
    Length = this->getLength();               /* get input length                  */

    if (Size == 0)                           /* requesting zero bytes?            */
    {
        Retval = OREF_NULLSTRING;          /* return a null string              */
    }
    else
    {
        Retval = raw_string(Size);         /* allocate a result string          */
        CopyLength = Numerics::minVal(Length, Size);    /* adjust the length                 */
        /* point to data part                */
        Current = Retval->getWritableData();
        if (CopyLength != 0)
        {                  /* have real data?                   */
                           /* copy it                           */
            memcpy(Current, this->getStringData(), CopyLength);
            Current += CopyLength;           /* bump the pointer                  */
        }
        if (Size > Length)                 /* need to pad?                      */
        {
            /* pad the string                    */
            memset(Current, (int)PadChar, Size - Length);
        }
    }
    return Retval;                       /* return string piece               */
}

/******************************************************************************/
/* Function:  Process the OVERLAY function/method                             */
/******************************************************************************/
// in behaviour
RexxString *RexxString::overlay(
    RexxString  *newStrObj,            /* overlayed string                  */
    RexxInteger *position,             /* overlay position                  */
    RexxInteger *_length,               /* overlay length                    */
    RexxString  *pad)                  /* pad character to use.             */
{
    RexxString *Retval;                  /* return string                     */
    RexxString *newStr;                  /* return string                     */
    size_t   OverlayPos;                 /* overlay position                  */
    size_t   OverlayLen;                 /* overlay length                    */
    size_t   NewLen;                     /* length of overlay string          */
    size_t   TargetLen;                  /* target length                     */
    size_t   FrontLen;                   /* front length                      */
    size_t   BackLen;                    /* back length                       */
    size_t   FrontPad;                   /* front pad length                  */
    size_t   BackPad;                    /* back pad length                   */
    codepoint_t     PadChar;                    /* pad character                     */
    char    *Current;                    /* current copy location             */

    TargetLen = this->getLength();       /* get the haystack length           */
                                         /* get the overlay string value      */
    newStr = stringArgument(newStrObj, OREF_positional, ARG_ONE);
    ProtectedObject p(newStr);
    NewLen = newStr->getLength();
    /* get the overlay position          */
    OverlayPos = optionalPositionArgument(position, 1, ARG_TWO);
    /* get final overlay length          */
    OverlayLen = optionalLengthArgument(_length, NewLen, ARG_THREE);
    /*  is used if omitted.              */
    PadChar = optionalPadArgument(pad, ' ', ARG_FOUR);

    if (OverlayLen > NewLen)             /* need to pad?                      */
        BackPad = OverlayLen - NewLen;     /* get the pad size                  */
    else
    {                               /* need to truncate                  */
        NewLen = OverlayLen;               /* used specified length             */
        BackPad = 0;                       /* no back padding                   */
    }

    if (OverlayPos > TargetLen)
    {        /* overlaying past the end?          */
             /* get front padding                 */
        FrontPad = OverlayPos - TargetLen - 1;
        FrontLen = TargetLen;              /* copy entire string                */
    }
    else
    {                               /* overlay is within bounds          */
        FrontPad = 0;                      /* no padding here                   */
        FrontLen = OverlayPos - 1;         /* just copy the front part          */
    }
    /* fall off the back side?           */
    if (OverlayPos + OverlayLen > TargetLen)
    {
        BackLen = 0;                       /* no back part                      */
    }
    else
    {
        /* calculate the back part           */
        BackLen = TargetLen - (OverlayPos + OverlayLen - 1);
    }
    /* allocate result string            */
    Retval = raw_string(FrontLen + BackLen + FrontPad + OverlayLen);

    Current = Retval->getWritableData(); /* get copy location                 */

    if (FrontLen != 0)
    {                      /* something in front?               */
                           /* copy the front part               */
        memcpy(Current, this->getStringData(), FrontLen);
        Current += FrontLen;               /* step the pointer                  */
    }

    if (FrontPad != 0)
    {                      /* padded in front?                  */
        memset(Current, (int)PadChar, FrontPad);/* set the pad characters            */
        Current += FrontPad;               /* step the pointer                  */
    }

    if (NewLen != 0)
    {                        /* non-null new string?              */
                             /* copy the string                   */
        memcpy(Current, newStr->getStringData(), NewLen);
        Current += NewLen;                 /* step the pointer                  */
    }

    if (BackPad != 0)
    {                       /* padded in back?                   */
                            /* set the pad characters            */
        memset(Current, (int)PadChar, BackPad);
        Current += BackPad;                /* step the pointer                  */
    }

    if (BackLen != 0)
    {                       /* trailing part?                    */
                            /* copy the string                   */
        memcpy(Current, this->getStringData() + OverlayPos + OverlayLen - 1, BackLen);
    }
    return Retval;                       /* return new string                 */
}


/**
 * Replace a substring starting at a given position and
 * length with another string.  This operation is essentially
 * a delstr() followed by an insert() operation.
 *
 * @param newStrObj The replacement string
 * @param position  The replacement position (required)
 * @param _length   The length of string to replace (optional).  If omitted,
 *                  the length of the replacement string is used and this
 *                  is essentially an overlay operation.
 * @param pad       The padding character if padding is required.  The default
 *                  is a ' '
 *
 * @return A new instance of the string with the value replace.
 */
// in behaviour
RexxString *RexxString::replaceAt(RexxString  *newStrObj, RexxInteger *position, RexxInteger *_length, RexxString  *pad)
{
    size_t targetLen = this->getLength();   // get the length of the replacement target
    // the replacement value is required and must be a string
    RexxString *newStr = stringArgument(newStrObj, OREF_positional, ARG_ONE);
    ProtectedObject p(newStr);
    // the length of the replacement string is the default replacement length
    size_t newLen = newStr->getLength();
    // the overlay position is required
    size_t replacePos = positionArgument(position, ARG_TWO);
    // the replacement length is optional, and defaults to the length of the replacement string
    size_t replaceLen = optionalLengthArgument(_length, newLen, ARG_THREE);
    // we only pad if the start position is past the end of the string
    codepoint_t padChar = optionalPadArgument(pad, ' ', ARG_FOUR);
    size_t padding = 0;
    size_t frontLen = 0;
    size_t backLen = 0;
    // the only time we need to pad is if the replacement position is past the
    // end of the string
    if (replacePos > targetLen)
    {
        padding = replacePos - targetLen - 1;
        frontLen = targetLen;
    }
    else
    {
        // this is within bounds, so we copy up to that position
        frontLen = replacePos - 1;
    }
    // is this within the bounds of the string?
    if (replacePos + replaceLen - 1 < targetLen)
    {
        // calculate the back part we need to copy
        backLen = targetLen - (replacePos + replaceLen - 1);
    }
    // allocate a result string
    RexxString *retval = raw_string(frontLen + backLen + padding + newLen);
    // and get a copy location
    char *current = retval->getWritableData();

    if (frontLen > 0)
    {                      /* something in front?               */
                           /* copy the front part               */
        memcpy(current, this->getStringData(), frontLen);
        current += frontLen;               /* step the pointer                  */
    }
    // padding only happens if we've copy the entire front portion
    if (padding > 0)
    {
        memset(current, (int)padChar, padding);
        current += padding;
    }
    // replace with a non-null string?  copy into the current position
    if (newLen > 0)
    {
        memcpy(current, newStr->getStringData(), newLen);
        current += newLen;
    }
    // the remainder, if there is any, get's copied after the
    // replacement string with no padding
    if (backLen > 0)
    {
        memcpy(current, this->getStringData() + replacePos + replaceLen - 1, backLen);
    }
    return retval;
}

/* the REVERSE function */
/******************************************************************************/
/* Arguments:  none                                                           */
/*                                                                            */
/*  Returned:  string reversed.                                               */
/******************************************************************************/
// in behaviour
RexxString *RexxString::reverse()
{
    RexxString *Retval;                  /* temp pointer for reversal       */
    size_t     Length;                   /* string length                   */
    char      *String;                   /* current location                */
    const char *End;                      /* string end position             */

    Length = this->getLength();               /* get first argument              */
    if (Length != 0)
    {                        /* if really data                  */
        Retval = raw_string(Length);       /* get result storage              */
                                           /* get new string pointer          */
        String = Retval->getWritableData();
        /* point to end of original        */
        End = this->getStringData() + Length - 1;

        while (Length-- != 0)                   /* reverse entire string           */
        {
            *String++ = *End--;              /* copy a single char              */
        }
                                             /* done building the string          */
    }
    else                                 /* if null input                     */
    {
        Retval = OREF_NULLSTRING;          /* return null output                */
    }
    return Retval;                       /* return the reversed string        */
}

/* the RIGHT function */
/******************************************************************************/
/* Arguments:  length of result                                               */
/*             pad character to use if needed.                                */
/*                                                                            */
/*  Returned:  string right justified.                                        */
/******************************************************************************/
// in behaviour
RexxString *RexxString::right(RexxInteger *_length,
                              RexxString  *pad)
{
    codepoint_t      PadChar;                   /* pad character                     */
    size_t    Size;                      /* requested size                    */
    size_t    Length;                    /* string length                     */
    RexxString *Retval;                  /* returned result                   */
    char *    Current;                   /* current copy location             */
    size_t    CopyLength;                /* length to copy                    */

                                         /* get the target length             */
    Size = lengthArgument(_length, ARG_ONE);

    /*  is used if omitted.              */
    PadChar = optionalPadArgument(pad, ' ', ARG_TWO);
    Length = this->getLength();               /* get input length                  */

    if (Size == 0)                           /* requesting zero bytes?            */
    {
        /* return a null string              */
        Retval = OREF_NULLSTRING;
    }
    else
    {
        Retval = raw_string(Size);         /* allocate a result string          */
        CopyLength = Numerics::minVal(Length, Size);    /* adjust the length                 */
        /* point to data part                */
        Current = Retval->getWritableData();
        if (Size > Length)
        {               /* need to pad?                      */
                        /* pad the string                    */
            memset(Current, (int)PadChar, Size - Length);
            Current += Size - Length;        /* bump the pointer                  */
        }
        if (CopyLength != 0)                    /* have real data?                   */
        {
            /* copy it                           */
            memcpy(Current, this->getStringData() + Length - CopyLength, CopyLength);
        }
    }
    return Retval;                       /* return string piece               */
}

/**
 * Strip a set of leading and/or trailing characters from
 * a string, returning a new string value.
 *
 * @param option    The option indicating which characters to strip.
 * @param stripchar The set of characters to strip.
 *
 * @return A new string instance, with the target characters removed.
 */
// in behaviour
RexxString *RexxString::strip(RexxString *optionString, RexxString *stripchar)
{
    // get the option character
    char option = optionalOptionArgument(optionString, STRIP_BOTH, ARG_ONE);
    if (option != STRIP_TRAILING &&      /* must be a valid option            */
        option != STRIP_LEADING &&
        option != STRIP_BOTH )
    {
        reportException(Error_Incorrect_method_option, "BLT", option);
    }
    // get the strip character set.  The default is to remove spaces and
    // horizontal tabs
    stripchar = optionalStringArgument(stripchar, OREF_NULL, OREF_positional, ARG_TWO);

    // the default is to strip whitespace characters
    const char *chars = stripchar == OREF_NULL ? " \t" : stripchar->getStringData();
    size_t charsLen = stripchar == OREF_NULL ? strlen(" \t") : stripchar->getLength();

    const char *front = this->getStringData();       /* point to string start             */
    size_t length = this->getLength();               /* get the length                    */

                                         /* need to strip leading?            */
    if (option == STRIP_LEADING || option == STRIP_BOTH)
    {
        // loop while more string or we don't find one of the stripped characters
        while (length > 0)
        {
            if (!StringUtil::matchCharacter(*front, chars, charsLen))
            {
                break;
            }
            front++;                         /* step the pointer                  */
            length--;                        /* reduce the length                 */
        }
    }

    // need to strip trailing?
    if (option == STRIP_TRAILING || option == STRIP_BOTH)
    {
        // point to the end and scan backwards now
        const char *back = front + length - 1;
        while (length > 0)
        {
            if (!StringUtil::matchCharacter(*back, chars, charsLen))
            {
                break;
            }
            back--;                          /* step the pointer back             */
            length--;                        /* reduce the length                 */
        }
    }

    // if there is anything left, extract the remaining part
    if (length > 0)
    {
        return new_string(front, length);
    }
    else
    {
        // null string, everything stripped away
        return OREF_NULLSTRING;
    }
}

/* the SUBSTR function */
/******************************************************************************/
/* Arguments:  String position for substr                                     */
/*             requested length of new string                                 */
/*             pad character to use, if necessary                             */
/*                                                                            */
/*  Returned:  string, sub string of original.                                */
/******************************************************************************/
// in behaviour
RexxString *RexxString::substr(RexxInteger *position,
                               RexxInteger *_length,
                               RexxString  *pad)
{
    return StringUtil::substr(getStringData(), getLength(), position, _length, pad);
}


/**
 * Extract a single character from a string object.
 * Returns a null string if the specified position is
 * beyond the bounds of the string.
 *
 * @param positionArg
 *               The position of the target  character.  Must be a positive
 *               whole number.
 *
 * @return Returns the single character at the target position.
 *         Returns a null string if the position is beyond the end
 *         of the string.
 */
// in behaviour
RexxString *RexxString::subchar(RexxInteger *positionArg)
{
    return StringUtil::subchar(getStringData(), getLength(), positionArg);
}

