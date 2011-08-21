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
/* Primitive Translator Token Class                                           */
/*                                                                            */
/******************************************************************************/
#include <ctype.h>
#include <string.h>
#include "RexxCore.h"
#include "StringClass.hpp"
#include "Token.hpp"
#include "SourceFile.hpp"

RexxToken::RexxToken(
    int            _classId,            /* class of token                    */
    int            _subclass,           /* token subclass                    */
    RexxString     *_value,             /* token value                       */
    SourceLocation &_location)          /* token location descriptor         */
/******************************************************************************/
/* Function:  Complete set up of a TOKEN object                               */
/******************************************************************************/
{
    OrefSet(this, this->value, _value);   /* use the provided string value     */
    this->classId = _classId;             /* no assigned token class           */
    this->subclass = _subclass;           /* no specialization yet             */
    this->tokenLocation = _location;      /* copy it over                      */
}

void RexxToken::live(size_t liveMark)
/******************************************************************************/
/* Function:  Normal garbage collection live marking                          */
/******************************************************************************/
{
    memory_mark(this->value);
}

void RexxToken::liveGeneral(int reason)
/******************************************************************************/
/* Function:  Generalized object marking                                      */
/******************************************************************************/
{
    memory_mark_general(this->value);
}

void RexxToken::flatten(RexxEnvelope *envelope)
/******************************************************************************/
/* Function:  Flatten an object                                               */
/******************************************************************************/
{
  setUpFlatten(RexxToken)

    flatten_reference(newThis->value, envelope);

  cleanUpFlatten
}


/**
 * Check and update this token for the special assignment forms
 * (+=, -=, etc.).
 *
 * @param source The source for the original operator token.
 */
void RexxToken::checkAssignment(RexxSource *source, RexxString *newValue)
{
    // check if the next character is a special assignment shortcut
    if (source->nextSpecial('=', tokenLocation))
    {
        // this is a special type, which uses the same subtype.
        classId = TOKEN_ASSIGNMENT;
        // this is the new string value of the token
        value = newValue;
    }
}


void *RexxToken::operator new(size_t size)
/******************************************************************************/
/* Function:  Create a new token object                                       */
/******************************************************************************/
{
                                       /* Get new object                    */
    return new_object(size, T_Token);
}


#define CODE_TEXT(code) case code : return #code;

const char *RexxToken::codeText(int code)
/******************************************************************************/
/* Function:  Returns the text of a code symbol                               */
/******************************************************************************/
{
    static char buffer[10]; // Used only to return the code as number, when no text
    switch(code)
    {
    /* token types */
    CODE_TEXT(TOKEN_NULL)
    CODE_TEXT(TOKEN_BLANK)
    CODE_TEXT(TOKEN_SYMBOL)
    CODE_TEXT(TOKEN_LITERAL)
    CODE_TEXT(TOKEN_OPERATOR)
    CODE_TEXT(TOKEN_EOC)
    CODE_TEXT(TOKEN_COMMA)
    CODE_TEXT(TOKEN_PREFIX)
    CODE_TEXT(TOKEN_LEFT)
    CODE_TEXT(TOKEN_RIGHT)
    CODE_TEXT(TOKEN_POINT)
    CODE_TEXT(TOKEN_COLON)
    CODE_TEXT(TOKEN_TILDE)
    CODE_TEXT(TOKEN_DTILDE)
    CODE_TEXT(TOKEN_SQLEFT)
    CODE_TEXT(TOKEN_SQRIGHT)
    CODE_TEXT(TOKEN_DCOLON)
    CODE_TEXT(TOKEN_CONTINUE)
    CODE_TEXT(TOKEN_ASSIGNMENT)
    CODE_TEXT(TOKEN_SOURCE_LITERAL)

    /* token extended types - symbols */
    CODE_TEXT(SYMBOL_CONSTANT)
    CODE_TEXT(SYMBOL_VARIABLE)
    CODE_TEXT(SYMBOL_NAME)
    CODE_TEXT(SYMBOL_COMPOUND)
    CODE_TEXT(SYMBOL_STEM)
    CODE_TEXT(SYMBOL_DUMMY)
    CODE_TEXT(SYMBOL_DOTSYMBOL)
    CODE_TEXT(INTEGER_CONSTANT)
    CODE_TEXT(LITERAL_HEX)
    CODE_TEXT(LITERAL_BIN)

    /* token extended types - operators */
    CODE_TEXT(OPERATOR_PLUS)
    CODE_TEXT(OPERATOR_SUBTRACT)
    CODE_TEXT(OPERATOR_MULTIPLY)
    CODE_TEXT(OPERATOR_DIVIDE)
    CODE_TEXT(OPERATOR_INTDIV)
    CODE_TEXT(OPERATOR_REMAINDER)
    CODE_TEXT(OPERATOR_POWER)
    CODE_TEXT(OPERATOR_ABUTTAL)
    CODE_TEXT(OPERATOR_CONCATENATE)
    CODE_TEXT(OPERATOR_BLANK)
    CODE_TEXT(OPERATOR_EQUAL)
    CODE_TEXT(OPERATOR_BACKSLASH_EQUAL)
    CODE_TEXT(OPERATOR_GREATERTHAN)
    CODE_TEXT(OPERATOR_BACKSLASH_GREATERTHAN)
    CODE_TEXT(OPERATOR_LESSTHAN)
    CODE_TEXT(OPERATOR_BACKSLASH_LESSTHAN)
    CODE_TEXT(OPERATOR_GREATERTHAN_EQUAL)
    CODE_TEXT(OPERATOR_LESSTHAN_EQUAL)
    CODE_TEXT(OPERATOR_STRICT_EQUAL)
    CODE_TEXT(OPERATOR_STRICT_BACKSLASH_EQUAL)
    CODE_TEXT(OPERATOR_STRICT_GREATERTHAN)
    CODE_TEXT(OPERATOR_STRICT_BACKSLASH_GREATERTHAN)
    CODE_TEXT(OPERATOR_STRICT_LESSTHAN)
    CODE_TEXT(OPERATOR_STRICT_BACKSLASH_LESSTHAN)
    CODE_TEXT(OPERATOR_STRICT_GREATERTHAN_EQUAL)
    CODE_TEXT(OPERATOR_STRICT_LESSTHAN_EQUAL)
    CODE_TEXT(OPERATOR_LESSTHAN_GREATERTHAN)
    CODE_TEXT(OPERATOR_GREATERTHAN_LESSTHAN)
    CODE_TEXT(OPERATOR_AND)
    CODE_TEXT(OPERATOR_OR)
    CODE_TEXT(OPERATOR_XOR)
    CODE_TEXT(OPERATOR_BACKSLASH)

    /* token extended types - instruction keywords */
    CODE_TEXT(IS_KEYWORD)
    // For the text of each keyword see RexxToken::keywordText

    /* token extended types - instruction option keywords */
    CODE_TEXT(IS_SUBKEY)

    /* token extended types - end of clause */
    CODE_TEXT(CLAUSEEND_EOF)
    CODE_TEXT(CLAUSEEND_SEMICOLON)
    CODE_TEXT(CLAUSEEND_EOL)
    CODE_TEXT(CLAUSEEND_NULL)

    /* directive types */
    CODE_TEXT(IS_DIRECTIVE)

    /* directive sub-keywords */
    CODE_TEXT(IS_SUBDIRECTIVE)

    /* condition keywords */
    CODE_TEXT(IS_CONDITION)

    /* builtin function codes */
    CODE_TEXT(IS_BUILTIN)

    default:
        Utilities::snprintf(buffer, sizeof(buffer), "%i", code);
        return buffer;
    }
}


const char *RexxToken::keywordText(int code)
/******************************************************************************/
/* Function:  Returns the text of a keyword                                   */
/******************************************************************************/
{
    static char buffer[10]; // Used only to return the code as number, when no text
    switch(code)
    {
    /* token extended types - instruction keywords */
    CODE_TEXT(KEYWORD_ADDRESS)
    CODE_TEXT(KEYWORD_ARG)
    CODE_TEXT(KEYWORD_CALL)
    CODE_TEXT(KEYWORD_DO)
    CODE_TEXT(KEYWORD_DROP)
    CODE_TEXT(KEYWORD_EXIT)
    CODE_TEXT(KEYWORD_IF)
    CODE_TEXT(KEYWORD_INTERPRET)
    CODE_TEXT(KEYWORD_ITERATE)
    CODE_TEXT(KEYWORD_LEAVE)
    CODE_TEXT(KEYWORD_METHOD)
    CODE_TEXT(KEYWORD_NOP)
    CODE_TEXT(KEYWORD_NUMERIC)
    CODE_TEXT(KEYWORD_OPTIONS)
    CODE_TEXT(KEYWORD_PARSE)
    CODE_TEXT(KEYWORD_PROCEDURE)
    CODE_TEXT(KEYWORD_PULL)
    CODE_TEXT(KEYWORD_PUSH)
    CODE_TEXT(KEYWORD_QUEUE)
    CODE_TEXT(KEYWORD_REPLY)
    CODE_TEXT(KEYWORD_RETURN)
    CODE_TEXT(KEYWORD_SAY)
    CODE_TEXT(KEYWORD_SELECT)
    CODE_TEXT(KEYWORD_SIGNAL)
    CODE_TEXT(KEYWORD_TRACE)
    CODE_TEXT(KEYWORD_VAR)
    CODE_TEXT(KEYWORD_GUARD)
    CODE_TEXT(KEYWORD_USE)
    CODE_TEXT(KEYWORD_INITPROC)
    CODE_TEXT(KEYWORD_EXPOSE)
    CODE_TEXT(KEYWORD_RAISE)
    CODE_TEXT(KEYWORD_ELSE)
    CODE_TEXT(KEYWORD_THEN)
    CODE_TEXT(KEYWORD_END)
    CODE_TEXT(KEYWORD_OTHERWISE)
    CODE_TEXT(KEYWORD_IFTHEN)
    CODE_TEXT(KEYWORD_WHENTHEN)
    CODE_TEXT(KEYWORD_WHEN)
    CODE_TEXT(KEYWORD_ASSIGNMENT)
    CODE_TEXT(KEYWORD_COMMAND)
    CODE_TEXT(KEYWORD_MESSAGE)
    CODE_TEXT(KEYWORD_LABEL)
    CODE_TEXT(KEYWORD_ENDIF)
    CODE_TEXT(KEYWORD_BLOCK)
    CODE_TEXT(KEYWORD_FIRST)
    CODE_TEXT(KEYWORD_LAST)
    CODE_TEXT(KEYWORD_ENDELSE)
    CODE_TEXT(KEYWORD_ENDTHEN)
    CODE_TEXT(KEYWORD_ENDWHEN)
    CODE_TEXT(KEYWORD_REQUIRES)
    CODE_TEXT(KEYWORD_CLASS)
    CODE_TEXT(KEYWORD_INSTRUCTION)
    CODE_TEXT(KEYWORD_FORWARD)
    CODE_TEXT(KEYWORD_LOOP)
    CODE_TEXT(KEYWORD_LIBRARY)

    default:
        Utilities::snprintf(buffer, sizeof(buffer), "%i", code);
        return buffer;
    }
}
