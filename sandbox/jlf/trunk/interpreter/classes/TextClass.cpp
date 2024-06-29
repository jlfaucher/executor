/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2021 Rexx Language Association. All rights reserved.    */
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

#include "RexxCore.h"
#include "ProtectedObject.hpp"
#include "TextClass.hpp"


/******************************************************************************/
/*                                                                            */
/* RexxText Class                                                             */
/*                                                                            */
/******************************************************************************/

// singleton class instance
RexxTextClass *RexxText::classInstance = OREF_NULL; // TheRexxTextClass

RexxText *RexxText::nullText = OREF_NULL; // Initialized by RexxMemory::restore (RexxMemory.cpp) and RexxMemory::createImage (Setup.cpp)


void RexxText::createInstance()
{
    CLASS_CREATE(RexxText, "RexxText", RexxTextClass);
}

/*static*/ RexxText *RexxText::newText(RexxString *s)
{
    RexxObject *newObj = OREF_NULL;

    // This method is called from RexxMemory::createImage and RexxMemory::restore
    // At that moment, there is no current activity, and ProtectedObject can't be used.
    // Use GlobalProtectedObject?
    if (ActivityManager::currentActivity != NULL)
    {
        // Normal situation
        newObj = new RexxText();
        ProtectedObject p(newObj);
        newObj->setBehaviour(TheRexxTextClass->getInstanceBehaviour());
        if (TheRexxTextClass->hasUninitDefined())
        {
            newObj->hasUninit();
        }
        ProtectedObject p_result;
        RexxObject *arguments[1];
        arguments[0] = s;
        bool messageUnderstood = newObj->messageSend(OREF_INIT, arguments, 1, 0, p_result, false);
    }
    else
    {
        // Special situation
        newObj = new RexxText();
        // ProtectedObject p(newObj);
        newObj->setBehaviour(TheRexxTextClass->getInstanceBehaviour());
        if (TheRexxTextClass->hasUninitDefined())
        {
            newObj->hasUninit();
        }
#if 0
        // Can't send "INIT" because the extension is maybe not loaded
        // Anyway, can't use messageSend because a ProtectedObject is needed
        // TODO manage a native init which doesn't depend on extensions
        ProtectedObject p_result;
        RexxObject *arguments[1];
        arguments[0] = s;
        bool messageUnderstood = newObj->messageSend(OREF_INIT, arguments, 1, 0, p_result, false);
#endif
    }
    return (RexxText *)newObj;
}

/*static*/ RexxText *RexxText::newText(const char *s, size_t blength)
{
    RexxString *string = new_string(s, blength);

    // This method is called from RexxMemory::createImage and RexxMemory::restore
    // At that moment, there is no current activity, and ProtectedObject can't be used.
    if (ActivityManager::currentActivity != NULL)
    {
        // Normal situation
        ProtectedObject p_string(string);
        return newText(string);
    }
    else
    {
        // Special situation
        // ProtectedObject p_string(string);
        return newText(string);
    }
}

RexxObject  *RexxText::newRexx(RexxObject **init_args, size_t argCount, size_t named_argCount)
{
    RexxObject *newObj = new RexxText();
    ProtectedObject p(newObj);
    newObj->setBehaviour(((RexxClass *)this)->getInstanceBehaviour());
    if (((RexxClass *)this)->hasUninitDefined())
    {
        newObj->hasUninit();
    }
    newObj->sendMessage(OREF_INIT, init_args, argCount, named_argCount);
    return newObj;
}

void *RexxText::operator new(size_t size)
{
    return new_object(size, T_RexxText);
}

void RexxText::live(size_t liveMark)
{
    memory_mark(this->objectVariables);
}

void RexxText::liveGeneral(int reason)
{
    memory_mark_general(this->objectVariables);
}

void RexxText::flatten(RexxEnvelope *envelope)
{
    setUpFlatten(RexxText)
    flatten_reference(newThis->objectVariables, envelope);
    cleanUpFlatten
}

RexxString *RexxText::primitiveMakeString()
{
    return (RexxString *)this->sendMessage(OREF_REQUEST, OREF_STRINGSYM);
}


// Handle a REQUEST('TEXT') request for a REXX text object
RexxText  *RexxText::primitiveMakeText()
{
    return this;
}


RexxString *RexxText::makeString()
{
    return (RexxString *)this->sendMessage(OREF_REQUEST, OREF_STRINGSYM);
}

// Handle a REQUEST('TEXT') request for a REXX text object
RexxText *RexxText::makeText()
{
    if (this->isBaseClass())
    {
        return this;
    }
    else
    {
        // return new_text(this->getString(), this->getEncoding()); // TODO
        return this;
    }
}


// Return the primitive text value of this object
RexxText *RexxText::textValue()
{
    if (isOfClass(RexxText, this))
    {
        return this;
    }
    else
    {
        // return new_text(this->getString(), this->getEncoding()); // TODO
        return this;
    }
}


void RexxTextClass::live(size_t liveMark)
{
    this->RexxClass::live(liveMark);     // do RexxClass level marking

    // mark the static objects
    memory_mark(RexxText::nullText);
}

void RexxTextClass::liveGeneral(int reason)
{
    this->RexxClass::liveGeneral(reason);// do RexxClass level marking

    // mark the static objects
    memory_mark_general(RexxText::nullText);
}


/******************************************************************************/
/*                                                                            */
/* Helpers                                                                    */
/*                                                                            */
/******************************************************************************/

/* All possible oorexx user-defined errors:
    Error_Program_unreadable_user_defined
    Error_Program_interrupted_user_defined
    Error_System_resources_user_defined
    Error_Unmatched_quote_user_defined
    Error_Control_stack_user_defined
    Error_Invalid_character_user_defined
    Error_Symbol_or_string_user_defined
    Error_Symbol_expected_user_defined
    Error_Invalid_data_user_defined
    Error_Invalid_character_string_user_defined
    Error_Invalid_data_string_user_defined
    Error_Invalid_subkeyword_string_user_defined
    Error_Invalid_whole_number_user_defined
    Error_Name_too_long_user_defined
    Error_Invalid_variable_user_defined
    Error_Expression_user_defined
    Error_Logical_value_user_defined
    Error_Invalid_expression_user_defined
    Error_Unmatched_parenthesis_user_defined
    Error_Unexpected_comma_user_defined
    Error_Invalid_template_user_defined
    Error_Incorrect_call_user_defined
    Error_Conversion_user_defined
    Error_Overflow_user_defined
    Error_Routine_not_found_user_defined
    Error_Function_no_data_user_defined
    Error_Variable_reference_user_defined
    Error_System_service_user_defined
    Error_Interpretation_user_defined
    Error_Invalid_argument_user_defined
    Error_External_name_not_found_user_defined
    Error_No_result_object_user_defined
    Error_OLE_Error_user_defined
    Error_Incorrect_method_user_defined
    Error_No_method_user_defined
    Error_Execution_user_defined
    Error_Translation_user_defined
*/


ssize_t integerRange(RexxObject *obj, ssize_t min, ssize_t max, wholenumber_t error, const char *errorMessage)
{
    if (obj != OREF_NULL)
    {
        RexxInteger *integer = (RexxInteger *)REQUEST_INTEGER(obj);
        if (integer != TheNilObject)
        {
            wholenumber_t value = integer->getValue();
            if (value >= min && value <= max) return value;
        }
    }
    reportException(error, errorMessage);
    return 0; // To avoid warning, must return something (should never reach this line)
}


ssize_t integer(RexxObject *obj, const char *errorMessage)
{
    if (obj != OREF_NULL)
    {
        RexxInteger *integer = (RexxInteger *)REQUEST_INTEGER(obj);
        if (integer != TheNilObject) return integer->getValue();
    }
    reportException(Error_Invalid_argument_user_defined, errorMessage);
    return 0; // To avoid warning, must return something (should never reach this line)
}


bool isLittleEndian()
{
    int64_t v64 = 1;
    return *((int8_t*)&v64) == 1;
}


/******************************************************************************/
/*                                                                            */
/* Unicode Class                                                              */
/*                                                                            */
/******************************************************************************/

// singleton class instance
RexxClass *Unicode::classInstance = OREF_NULL;


void Unicode::createInstance()
{
    CLASS_CREATE(Unicode, "Unicode", RexxClass);
}

RexxObject *Unicode::newRexx(RexxObject **init_args, size_t argCount, size_t named_argCount)
{
    // This class has no instance...
    reportException(Error_Unsupported_new_method, ((RexxClass *)this)->getId());
    return TheNilObject;
}

RexxObject *Unicode::copyRexx()
{
    // This class cannot be copied because it holds tons of informations about the Unicode characters...
    reportException(Error_Unsupported_copy_method, this);
    return TheNilObject;
}

void *Unicode::operator new(size_t size)
{
    return new_object(size, T_Unicode);
}

void Unicode::live(size_t liveMark)
{
    memory_mark(this->objectVariables);
}

void Unicode::liveGeneral(int reason)
{
    memory_mark_general(this->objectVariables);
}

void Unicode::flatten(RexxEnvelope *envelope)
{
    setUpFlatten(Unicode)
    flatten_reference(newThis->objectVariables, envelope);
    cleanUpFlatten
}

RexxInteger *Unicode::systemIsLittleEndian()
{
    int64_t v64 = 1;
    return isLittleEndian() ? TheTrueObject : TheFalseObject;
}

/******************************************************************************/
/*                                                                            */
/* Unicode Class - utf8proc                                                   */
/*                                                                            */
/******************************************************************************/

#include "m17n/utf8proc/utf8proc.h"


void raiseError(utf8proc_ssize_t errcode)
{
    const char *errmsg = utf8proc_errmsg(errcode);
    switch (errcode)
    {
        case UTF8PROC_ERROR_NOMEM:
        case UTF8PROC_ERROR_OVERFLOW:
            reportException(Error_System_resources_user_defined, errmsg);
        case UTF8PROC_ERROR_INVALIDUTF8:
        case UTF8PROC_ERROR_NOTASSIGNED:
            reportException(Error_Invalid_character_string_user_defined, errmsg);
        case UTF8PROC_ERROR_INVALIDOPTS:
            reportException(Error_Invalid_argument_user_defined, errmsg);
        default:
            reportException(Error_System_service_user_defined, errmsg);
    }
}


RexxString *Unicode::utf8proc_version()
{
    return new_string(utf8proc_unicode_version());
}


/**
 * Given a pair of consecutive codepoints, return whether a grapheme break is
 * permitted between them.
 *
 * @param array An array of 3 items:
 *     codepoint1 [IN]     The first codepoint.
 *     codepoint2 [IN]     The second codepoint.
 *     state      [IN OUT] Initial value must be 0.
 *
 * @return .true if a grapheme break is permitted, .false otherwise.
 */
RexxInteger *Unicode::utf8proc_graphemeBreak(RexxArray *array)
{
    array = arrayArgument(array, OREF_positional, ARG_ONE);
    ProtectedObject p(array);
    utf8proc_int32_t codepoint1 = (utf8proc_int32_t)integerRange(array->get(1), 0, SSIZE_MAX, Error_Invalid_argument_user_defined, "GraphemeBreak: The first codepoint must be a non negative integer");
    utf8proc_int32_t codepoint2 = (utf8proc_int32_t)integerRange(array->get(2), 0, SSIZE_MAX, Error_Invalid_argument_user_defined, "GraphemeBreak: The second codepoint must be a non negative integer");
    utf8proc_int32_t state =      (utf8proc_int32_t)integerRange(array->get(3), 0, SSIZE_MAX, Error_Invalid_argument_user_defined, "GraphemeBreak:The state must be a non negative integer");
    utf8proc_bool graphemeBreak = utf8proc_grapheme_break_stateful(codepoint1, codepoint2, &state);
    array->put(new_integer(state), 3); // Output argument
    return graphemeBreak ? TheTrueObject : TheFalseObject;
}

RexxInteger *Unicode::utf8proc_codepointCategory(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointCategory: codepoint must be an integer");
    const utf8proc_property_t *property = utf8proc_get_property(codepoint);
    return new_integer(property->category); // see utf8proc_category_t
}
#if 0
/** Unicode categories. */
typedef enum {
  UTF8PROC_CATEGORY_CN  = 0, /**< Other, not assigned */
  UTF8PROC_CATEGORY_LU  = 1, /**< Letter, uppercase */
  UTF8PROC_CATEGORY_LL  = 2, /**< Letter, lowercase */
  UTF8PROC_CATEGORY_LT  = 3, /**< Letter, titlecase */
  UTF8PROC_CATEGORY_LM  = 4, /**< Letter, modifier */
  UTF8PROC_CATEGORY_LO  = 5, /**< Letter, other */
  UTF8PROC_CATEGORY_MN  = 6, /**< Mark, nonspacing */
  UTF8PROC_CATEGORY_MC  = 7, /**< Mark, spacing combining */
  UTF8PROC_CATEGORY_ME  = 8, /**< Mark, enclosing */
  UTF8PROC_CATEGORY_ND  = 9, /**< Number, decimal digit */
  UTF8PROC_CATEGORY_NL = 10, /**< Number, letter */
  UTF8PROC_CATEGORY_NO = 11, /**< Number, other */
  UTF8PROC_CATEGORY_PC = 12, /**< Punctuation, connector */
  UTF8PROC_CATEGORY_PD = 13, /**< Punctuation, dash */
  UTF8PROC_CATEGORY_PS = 14, /**< Punctuation, open */
  UTF8PROC_CATEGORY_PE = 15, /**< Punctuation, close */
  UTF8PROC_CATEGORY_PI = 16, /**< Punctuation, initial quote */
  UTF8PROC_CATEGORY_PF = 17, /**< Punctuation, final quote */
  UTF8PROC_CATEGORY_PO = 18, /**< Punctuation, other */
  UTF8PROC_CATEGORY_SM = 19, /**< Symbol, math */
  UTF8PROC_CATEGORY_SC = 20, /**< Symbol, currency */
  UTF8PROC_CATEGORY_SK = 21, /**< Symbol, modifier */
  UTF8PROC_CATEGORY_SO = 22, /**< Symbol, other */
  UTF8PROC_CATEGORY_ZS = 23, /**< Separator, space */
  UTF8PROC_CATEGORY_ZL = 24, /**< Separator, line */
  UTF8PROC_CATEGORY_ZP = 25, /**< Separator, paragraph */
  UTF8PROC_CATEGORY_CC = 26, /**< Other, control */
  UTF8PROC_CATEGORY_CF = 27, /**< Other, format */
  UTF8PROC_CATEGORY_CS = 28, /**< Other, surrogate */
  UTF8PROC_CATEGORY_CO = 29, /**< Other, private use */
} utf8proc_category_t;
#endif


RexxInteger *Unicode::utf8proc_codepointCombiningClass(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointCombiningClass: codepoint must be an integer");
    const utf8proc_property_t *property = utf8proc_get_property(codepoint);
    return new_integer(property->combining_class); // see utf8proc_category_t
}


RexxInteger *Unicode::utf8proc_codepointBidiClass(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointBidiClass: codepoint must be an integer");
    const utf8proc_property_t *property = utf8proc_get_property(codepoint);
    return new_integer(property->bidi_class); // see utf8proc_bidi_class_t
}
#if 0
/** Bidirectional character classes. */
typedef enum {
  UTF8PROC_BIDI_CLASS_L     = 1, /**< Left-to-Right */
  UTF8PROC_BIDI_CLASS_LRE   = 2, /**< Left-to-Right Embedding */
  UTF8PROC_BIDI_CLASS_LRO   = 3, /**< Left-to-Right Override */
  UTF8PROC_BIDI_CLASS_R     = 4, /**< Right-to-Left */
  UTF8PROC_BIDI_CLASS_AL    = 5, /**< Right-to-Left Arabic */
  UTF8PROC_BIDI_CLASS_RLE   = 6, /**< Right-to-Left Embedding */
  UTF8PROC_BIDI_CLASS_RLO   = 7, /**< Right-to-Left Override */
  UTF8PROC_BIDI_CLASS_PDF   = 8, /**< Pop Directional Format */
  UTF8PROC_BIDI_CLASS_EN    = 9, /**< European Number */
  UTF8PROC_BIDI_CLASS_ES   = 10, /**< European Separator */
  UTF8PROC_BIDI_CLASS_ET   = 11, /**< European Number Terminator */
  UTF8PROC_BIDI_CLASS_AN   = 12, /**< Arabic Number */
  UTF8PROC_BIDI_CLASS_CS   = 13, /**< Common Number Separator */
  UTF8PROC_BIDI_CLASS_NSM  = 14, /**< Nonspacing Mark */
  UTF8PROC_BIDI_CLASS_BN   = 15, /**< Boundary Neutral */
  UTF8PROC_BIDI_CLASS_B    = 16, /**< Paragraph Separator */
  UTF8PROC_BIDI_CLASS_S    = 17, /**< Segment Separator */
  UTF8PROC_BIDI_CLASS_WS   = 18, /**< Whitespace */
  UTF8PROC_BIDI_CLASS_ON   = 19, /**< Other Neutrals */
  UTF8PROC_BIDI_CLASS_LRI  = 20, /**< Left-to-Right Isolate */
  UTF8PROC_BIDI_CLASS_RLI  = 21, /**< Right-to-Left Isolate */
  UTF8PROC_BIDI_CLASS_FSI  = 22, /**< First Strong Isolate */
  UTF8PROC_BIDI_CLASS_PDI  = 23, /**< Pop Directional Isolate */
} utf8proc_bidi_class_t;
#endif


RexxInteger *Unicode::utf8proc_codepointBidiMirrored(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointBidiMirrored: codepoint must be an integer");
    const utf8proc_property_t *property = utf8proc_get_property(codepoint);
    return property->bidi_mirrored ? TheTrueObject : TheFalseObject;
}


RexxInteger *Unicode::utf8proc_codepointDecompositionType(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointDecompositionType: codepoint must be an integer");
    const utf8proc_property_t *property = utf8proc_get_property(codepoint);
    return new_integer(property->decomp_type); // see utf8proc_decomp_type_t

    /* not returned, internal use
    utf8proc_uint16_t decomp_seqindex;
    utf8proc_uint16_t casefold_seqindex;
    utf8proc_uint16_t uppercase_seqindex;
    utf8proc_uint16_t lowercase_seqindex;
    utf8proc_uint16_t titlecase_seqindex;
    utf8proc_uint16_t comb_index;
    unsigned bidi_mirrored:1;
    unsigned comp_exclusion:1;
    */
}
#if 0
/** Decomposition type. */
typedef enum {
  UTF8PROC_DECOMP_TYPE_FONT      = 1, /**< Font */
  UTF8PROC_DECOMP_TYPE_NOBREAK   = 2, /**< Nobreak */
  UTF8PROC_DECOMP_TYPE_INITIAL   = 3, /**< Initial */
  UTF8PROC_DECOMP_TYPE_MEDIAL    = 4, /**< Medial */
  UTF8PROC_DECOMP_TYPE_FINAL     = 5, /**< Final */
  UTF8PROC_DECOMP_TYPE_ISOLATED  = 6, /**< Isolated */
  UTF8PROC_DECOMP_TYPE_CIRCLE    = 7, /**< Circle */
  UTF8PROC_DECOMP_TYPE_SUPER     = 8, /**< Super */
  UTF8PROC_DECOMP_TYPE_SUB       = 9, /**< Sub */
  UTF8PROC_DECOMP_TYPE_VERTICAL = 10, /**< Vertical */
  UTF8PROC_DECOMP_TYPE_WIDE     = 11, /**< Wide */
  UTF8PROC_DECOMP_TYPE_NARROW   = 12, /**< Narrow */
  UTF8PROC_DECOMP_TYPE_SMALL    = 13, /**< Small */
  UTF8PROC_DECOMP_TYPE_SQUARE   = 14, /**< Square */
  UTF8PROC_DECOMP_TYPE_FRACTION = 15, /**< Fraction */
  UTF8PROC_DECOMP_TYPE_COMPAT   = 16, /**< Compat */
} utf8proc_decomp_type_t;
#endif


RexxInteger *Unicode::utf8proc_codepointIgnorable(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointIgnorable: codepoint must be an integer");
    const utf8proc_property_t *property = utf8proc_get_property(codepoint);
    return property->ignorable ? TheTrueObject : TheFalseObject;
}


RexxInteger *Unicode::utf8proc_codepointControlBoundary(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointControlBoundary: codepoint must be an integer");
    const utf8proc_property_t *property = utf8proc_get_property(codepoint);
    return property->control_boundary ? TheTrueObject : TheFalseObject;
}


RexxInteger *Unicode::utf8proc_codepointCharWidth(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointCharWidth: codepoint must be an integer");
    const utf8proc_property_t *property = utf8proc_get_property(codepoint);
    return new_integer(property->charwidth);

    /* not returned, not used?
    unsigned pad:2;
    */
}


RexxInteger *Unicode::utf8proc_codepointBoundClass(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointBoundClass: codepoint must be an integer");
    const utf8proc_property_t *property = utf8proc_get_property(codepoint);
    return new_integer(property->boundclass); // see utf8proc_boundclass_t
}
#if 0
/** Boundclass property. (TR29) */
typedef enum {
  UTF8PROC_BOUNDCLASS_START              =  0, /**< Start */
  UTF8PROC_BOUNDCLASS_OTHER              =  1, /**< Other */
  UTF8PROC_BOUNDCLASS_CR                 =  2, /**< Cr */
  UTF8PROC_BOUNDCLASS_LF                 =  3, /**< Lf */
  UTF8PROC_BOUNDCLASS_CONTROL            =  4, /**< Control */
  UTF8PROC_BOUNDCLASS_EXTEND             =  5, /**< Extend */
  UTF8PROC_BOUNDCLASS_L                  =  6, /**< L */
  UTF8PROC_BOUNDCLASS_V                  =  7, /**< V */
  UTF8PROC_BOUNDCLASS_T                  =  8, /**< T */
  UTF8PROC_BOUNDCLASS_LV                 =  9, /**< Lv */
  UTF8PROC_BOUNDCLASS_LVT                = 10, /**< Lvt */
  UTF8PROC_BOUNDCLASS_REGIONAL_INDICATOR = 11, /**< Regional indicator */
  UTF8PROC_BOUNDCLASS_SPACINGMARK        = 12, /**< Spacingmark */
  UTF8PROC_BOUNDCLASS_PREPEND            = 13, /**< Prepend */
  UTF8PROC_BOUNDCLASS_ZWJ                = 14, /**< Zero Width Joiner */

  /* the following are no longer used in Unicode 11, but we keep
     the constants here for backward compatibility */
  UTF8PROC_BOUNDCLASS_E_BASE             = 15, /**< Emoji Base */
  UTF8PROC_BOUNDCLASS_E_MODIFIER         = 16, /**< Emoji Modifier */
  UTF8PROC_BOUNDCLASS_GLUE_AFTER_ZWJ     = 17, /**< Glue_After_ZWJ */
  UTF8PROC_BOUNDCLASS_E_BASE_GAZ         = 18, /**< E_BASE + GLUE_AFTER_ZJW */

  /* the Extended_Pictographic property is used in the Unicode 11
     grapheme-boundary rules, so we store it in the boundclass field */
  UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC = 19,
  UTF8PROC_BOUNDCLASS_E_ZWG = 20, /* UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC + ZWJ */
} utf8proc_boundclass_t;
#endif


RexxInteger *Unicode::utf8proc_codepointToLowerSimple(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointToLower: codepoint must be an integer");
    return new_integer(utf8proc_tolower(codepoint));
}


RexxInteger *Unicode::utf8proc_codepointToUpperSimple(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointToUpper: codepoint must be an integer");
    return new_integer(utf8proc_toupper(codepoint));
}


RexxInteger *Unicode::utf8proc_codepointToTitleSimple(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointToTitle: codepoint must be an integer");
    return new_integer(utf8proc_totitle(codepoint));
}


RexxInteger *Unicode::utf8proc_codepointIsLower(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointIsLower: codepoint must be an integer");
    return utf8proc_islower(codepoint) ? TheTrueObject : TheFalseObject;

}


RexxInteger *Unicode::utf8proc_codepointIsUpper(RexxObject *rexxCodepoint)
{
    utf8proc_int32_t codepoint = (utf8proc_int32_t)integer(rexxCodepoint, "CodepointIsUpper: codepoint must be an integer");
    return utf8proc_isupper(codepoint) ? TheTrueObject : TheFalseObject;

}


// utf8proc helper
RexxString *normalize(RexxString *string, utf8proc_option_t options)
{
    utf8proc_uint8_t *retval;
    string = stringArgument(string, OREF_positional, ARG_ONE);
    const utf8proc_uint8_t *str = (const utf8proc_uint8_t *)string->getStringData();
    utf8proc_ssize_t strlength = (utf8proc_ssize_t)string->getLength();
    utf8proc_ssize_t reslength = utf8proc_map(str, strlength, &retval, options);
    if (reslength < 0) raiseError(reslength); // here, reslength is an error code
    // Not so easy to optimize memory allocation...
    // utf8proc_map allocates a buffer of 32-bit codepoints
    // and then reuse this same buffer to convert to utf-8
    // In the end, the buffer is reallocated to shrink it.
    RexxString *result = new_string((const char *)retval, reslength);
    free(retval);
    return result;
}


RexxObject *Unicode::utf8proc_transform(RexxString *string, RexxObject **named_arglist, size_t named_argcount)
{
    string = stringArgument(string, OREF_positional, ARG_ONE);

    // use strict named arg casefold = .false, lump= .false, nlf = 0, normalization = 0, stripCC = .false, stripIgnorable= .false, stripMark = .false, stripNA = .false
    NamedArguments expectedNamedArguments(8); // 8 named arguments
    expectedNamedArguments[0] = NamedArgument("CASEFOLD",      TheFalseObject); // default value = .false
    expectedNamedArguments[1] = NamedArgument("LUMP",          TheFalseObject); // default value = .false
    expectedNamedArguments[2] = NamedArgument("NLF",           IntegerZero);    // default value = 0 (0=none, 1=NLF2LF, 2=NLF2LS, 3=NLF2PS)
    expectedNamedArguments[3] = NamedArgument("NORMALIZATION", IntegerZero);    // default value = 0 (0=none, 1=NFC, 2=NFD, 3=NFKC, 4=NFKD)
    expectedNamedArguments[4] = NamedArgument("STRIPCC",       TheFalseObject); // default value = .false
    expectedNamedArguments[5] = NamedArgument("STRIPIGNORABLE",TheFalseObject); // default value = .false
    expectedNamedArguments[6] = NamedArgument("STRIPMARK",     TheFalseObject); // default value = .false
    expectedNamedArguments[7] = NamedArgument("STRIPNA",       TheFalseObject); // default value = .false
    expectedNamedArguments.match(named_arglist, named_argcount, /*strict*/ true, /*extraAllowed*/ false);
    ssize_t casefold =      integerRange(expectedNamedArguments[0].value, 0, 1, Error_Logical_value_user_defined, "Transform: value of named argument \"casefold\" must be 0 or 1");
    ssize_t lump =          integerRange(expectedNamedArguments[1].value, 0, 1, Error_Logical_value_user_defined, "Transform: value of named argument \"lump\" must be 0 or 1");
    ssize_t nlf =           integerRange(expectedNamedArguments[2].value, 0, 3, Error_Invalid_argument_user_defined, "Transform: value of named argument \"nlf\" must be 0..3");
    ssize_t normalization = integerRange(expectedNamedArguments[3].value, 0, 4, Error_Invalid_argument_user_defined, "Transform: value of named argument \"normalization\" must be 0..4");
    ssize_t stripCC =       integerRange(expectedNamedArguments[4].value, 0, 1, Error_Logical_value_user_defined, "Transform: value of named argument \"stripCC\" must be 0 or 1");
    ssize_t stripIgnorable= integerRange(expectedNamedArguments[5].value, 0, 1, Error_Logical_value_user_defined, "Transform: value of named argument \"stripIgnorable\" must be 0 or 1");
    ssize_t stripMark =     integerRange(expectedNamedArguments[6].value, 0, 1, Error_Logical_value_user_defined, "Transform: value of named argument \"stripMark\" must be 0 or 1");
    ssize_t stripNA =       integerRange(expectedNamedArguments[7].value, 0, 1, Error_Logical_value_user_defined, "Transform: value of named argument \"stripNA\" must be 0 or 1");

    int                     options = 0;
    if (casefold)           options |= UTF8PROC_CASEFOLD;
    if (lump)               options |= UTF8PROC_LUMP;
    if (nlf == 1)           options |= UTF8PROC_NLF2LF;
    if (nlf == 2)           options |= UTF8PROC_NLF2LS;
    if (nlf == 3)           options |= UTF8PROC_NLF2PS;
    if (normalization == 1) options |= UTF8PROC_STABLE | UTF8PROC_COMPOSE;                      // NFC
    if (normalization == 2) options |= UTF8PROC_STABLE | UTF8PROC_DECOMPOSE;                    // NFD
    if (normalization == 3) options |= UTF8PROC_STABLE | UTF8PROC_COMPOSE | UTF8PROC_COMPAT;    // NFKC
    if (normalization == 4) options |= UTF8PROC_STABLE | UTF8PROC_DECOMPOSE | UTF8PROC_COMPAT;  // NFKD
    if (stripCC)            options |= UTF8PROC_STRIPCC;
    if (stripIgnorable)     options |= UTF8PROC_IGNORE;
    if (stripMark)          options |= UTF8PROC_STRIPMARK;
    if (stripNA)            options |= UTF8PROC_STRIPNA;

    return normalize(string, utf8proc_option_t(options));
}

#if 0 // options that can be passed from executor

  /** Strip "default ignorable characters" such as SOFT-HYPHEN or ZERO-WIDTH-SPACE. */
  UTF8PROC_IGNORE    = (1<<5),

  /**
   * Indicating that NLF-sequences (LF, CRLF, CR, NEL) are representing a
   * line break, and should be converted to the codepoint for line
   * separation (LS).
   */
   // convert LF, CRLF, CR and NEL into LS
  UTF8PROC_NLF2LS    = (1<<7),

  /**
   * Indicating that NLF-sequences are representing a paragraph break, and
   * should be converted to the codepoint for paragraph separation
   * (PS).
   */
   // convert LF, CRLF, CR and NEL into PS
  UTF8PROC_NLF2PS    = (1<<8),

  /** Indicating that the meaning of NLF-sequences is unknown. */
  // convert LF, CRLF, CR and NEL into LF
  UTF8PROC_NLF2LF    = (UTF8PROC_NLF2LS | UTF8PROC_NLF2PS),

  /** Strips and/or convers control characters.
   *
   * NLF-sequences are transformed into space, except if one of the
   * NLF2LS/PS/LF options is given. HorizontalTab (HT) and FormFeed (FF)
   * are treated as a NLF-sequence in this case.  All other control
   * characters are simply removed.
   */
  UTF8PROC_STRIPCC   = (1<<9),

  /**
   * Performs unicode case folding, to be able to do a case-insensitive
   * string comparison.
   */
  UTF8PROC_CASEFOLD  = (1<<10),

  /** Lumps certain characters together.
   *
   * E.g. HYPHEN U+2010 and MINUS U+2212 to ASCII "-". See lump.md for details.
   *
   * If NLF2LF is set, this includes a transformation of paragraph and
   * line separators to ASCII line-feed (LF).
   */
  UTF8PROC_LUMP      = (1<<12),

  /** Strips all character markings.
   *
   * This includes non-spacing, spacing and enclosing (i.e. accents).
   * @note This option works only with @ref UTF8PROC_COMPOSE or
   *       @ref UTF8PROC_DECOMPOSE
   */
  UTF8PROC_STRIPMARK = (1<<13),

  /**
   * Strip unassigned codepoints.
   */
  UTF8PROC_STRIPNA    = (1<<14),

#endif


/******************************************************************************/
/*                                                                            */
/* Unicode Class - uni-algo                                                   */
/*                                                                            */
/******************************************************************************/

#include <sstream>
#include <string>

#include "m17n/uni-algo/include/uni_algo/version.h"


RexxString *Unicode::unialgo_version()
{
    std::stringstream version;
    version << una::version::library.major() << "." << una::version::library.minor() << "." << una::version::library.patch();
    // Don't use version.str().cstr() because cstr() would return a pointer to a temporary object
    // See https://stackoverflow.com/questions/1374468/stringstream-string-and-char-conversion-confusion
    const std::string& version_str = version.str();
    const char* version_cstr = version_str.c_str();
    return new_string(version_cstr);
}
