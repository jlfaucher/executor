/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2009 Rexx Language Association. All rights reserved.    */
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

.environment~setentry("CLAUSER", .Clauser)


-----------------------------------------------------------------------------
-- Helper for source analysis & transformation.

/*
    The Clauser works directly on the source array passed at creation.
    It returns only non-empty clauses (unless you modify a clause, see below).
    You can modify the source array by replacing the current clause by a new one :
        myClauser~clause = mySourceFragment
    The new clause is inserted as-is and not iterated over by the clauser.
    Of course, you can create a new clauser using the modified source, and
    then you will iterate over your modified clauses.
    While you don't call ~nextClause, ~clause will return the last assigned value,
    which can be anything, like an empty string or a string containing several clauses.
*/

::class "Clauser" public

-- Special characters : Must be more than one char, to never be equal to a source char
::constant CLAUSEEND_EOF 10
::constant CLAUSEEND_EOL 11
::constant CONTINUATION 12

::constant TOKEN_EOC 1
::constant TOKEN_OTHER 2


::method isExposeClause class unguarded
    use strict arg clause
    parse lower var clause word1 word2 .
    if word1 == "expose" then do
        if word2 == "" then return .true -- expose
        if word2~left(1) == "(" then return .true -- expose (name)
        if datatype(word2, "symbol") then return .true -- expose name
    end
    return .false


::method init
    expose sourceArray buffer
    use strict arg sourceArray
    self~gotoLine(sourceArray~first)
    buffer = .MutableBuffer~new
    self~nextClause


::method clauseAvailable
    expose clause
    return clause <> .nil


::method clause
    expose clause
    if \ self~clauseAvailable then raise syntax 93.937
    return clause


-- Replace the current clause by the new source fragment (black box, can be several clauses, won't be scanned)
-- The new source fragment is always monoline
-- The new source fragment is always inserted in the first line of the current clause.
-- If the current clause is multiline, then the remaining lines are made empty.
::method "clause="
    expose sourceArray sourceLine lineNum lineOffset lineLength clauseStartLine clauseStartOffset clauseEndLine clauseEndOffset clause
    if \ self~clauseAvailable then raise syntax 937
    use strict arg newSourceFragment
    if clauseStartLine == clauseEndLine then do
        oldLength = clauseEndOffset - clauseStartOffset + 1
        newLength = newSourceFragment~length
        sourceArray[clauseStartLine] = sourceArray[clauseStartLine]~replaceAt(newSourceFragment, clauseStartOffset, oldLength)
        if lineNum == clauseStartLine then do
            lineOffset += newLength - oldLength -- continue AFTER the new source fragment
            self~gotoLine(lineNum, lineOffset)
        end
        clauseEndOffset = clauseStartOffset + newLength - 1
    end
    else do
        sourceArray[clauseStartLine] = sourceArray[clauseStartLine]~left(clauseStartOffset - 1) || newSourceFragment
        line = sourceArray~next(clauseStartLine)
        do while line <> .nil, line < clauseEndLine
            sourceArray[line] = ""
            line = sourceArray~next(line)
        end
        -- In the last line, remove the part of the current clause
        source = sourceArray[clauseEndLine]
        oldLength = source~length
        source = source~substr(clauseEndOffset + 1)
        newLength = source~length
        sourceArray[clauseEndLine] = source
        if lineNum == clauseEndLine then do
            lineOffset += newLength - oldLength -- continue AFTER the new source fragment
            self~gotoLine(lineNum, lineOffset)
        end
        -- The clause is now monoline
        clauseEndLine = clauseStartLine
        clauseEndOffset = sourceArray[clauseStartLine]~length
    end
    clause = newSourceFragment -- If you recall ~clause then you will get the modified clause


-- Append a source fragment (black box, can be several clauses, won't be scanned by this method) at the end of the sources
::method appendSourceFragment
    expose sourceArray
    use strict arg sourceFragment
    sourceArray~append(sourceFragment)


::method nextClause -- next non empty stripped clause
    expose lineNum lineOffset clauseStartLine clauseStartOffset buffer clause
    do while lineNum <> .nil
        buffer~delete(1)
        clauseStartLine = lineNum
        clauseStartOffset = lineOffset
        do until token == self~TOKEN_EOC
            token = self~sourceNextToken
        end
        clause = buffer~string~strip
        if clause <> "" then return
    end
    clause = .nil


::method gotoLine private
    expose sourceArray sourceLine lineNum lineOffset lineLength
    use strict arg lineNum, lineOffset=1
    if lineNum == .nil then return .false
    sourceLine = sourceArray[lineNum]
    lineLength = sourceLine~length
    return .true


::method gotoNextLine private
    expose sourceArray lineNum
    lineNum = sourceArray~next(lineNum)
    return self~gotoLine(lineNum)


-- ooRexx adaptation of method RexxSource::comment in interpreter/parser/scanner.cpp
::method skipComment private
    --Scan source to skip over a nest of comments
    expose sourceLine lineNum lineOffset lineLength
    level = 1 -- start the comment nesting
    lineOffset += 2 -- step over the comment start
    do while level > 0 --while still in a comment nest
        if lineOffset > lineLength then do -- hit the end of a line?
            if \ self~gotoNextLine then raise syntax 93.900 array("Unmatched comment delimiter /*)")
            iterate
        end
        inch = sourceLine~subchar(lineOffset)
        lineOffset += 1
        if inch == '*' & sourceLine~subchar(lineOffset) == '/' then do
            level -= 1
            lineOffset += 1
        end
        else if inch == '/' & sourceLine~subchar(lineOffset) == '*' then do
            level += 1
            lineOffset += 1
        end
    end


-- ooRexx adaptation of method RexxSource::locateToken in interpreter/parser/scanner.cpp
::method locateToken private
    -- Locate next significant token in source, skipping extra blanks and comments.
    expose sourceArray sourceLine lineNum lineOffset lineLength
    if lineNum == .nil then character = self~CLAUSEEND_EOF
    else if lineOffset > lineLength then character = self~CLAUSEEND_EOL
    else do
        do while lineOffset <= lineLength
            inch = sourceLine~subchar(lineOffset)
            if inch == ' ' | inch == '09'x then do
                character = ' '
                leave
            end
            -- possible continuation character?
            else if inch == ',' | inch == '-' then do
                -- line comment?
                if inch == '-' & sourceLine~subchar(lineOffset + 1) == '-' then do
                    lineOffset = lineLength + 1 -- skip the remaining characters of the line
                    leave
                end
                character = inch -- assume for now real character
                -- check for EOL (possibly following blanks and comments)
                startOffset = lineOffset
                startLine = lineNum
                lineOffset += 1
                do while lineOffset <= lineLength
                    inch2 = sourceLine~subchar(lineOffset)
                    if inch2 == '/' & sourceLine~subchar(lineOffset + 1) == '*' then do
                        self~skipComment
                        iterate
                    end
                    if inch2 == '-' & sourceLine~subchar(lineOffset + 1) == '-' then do
                        lineOffset = lineLength + 1
                        leave
                    end
                    if inch2 <> ' ' & inch2 <> '09'x then leave
                    lineOffset += 1
                end
                if lineOffset > lineLength then do -- continuation
                    nextLineNum = sourceArray~next(lineNum)
                    if nextLineNum <> .nil then do
                        self~gotoLine(nextLineNum)
                        character = self~CONTINUATION
                        leave
                    end
                end
                else do -- real character
                    self~gotoLine(startLine)
                    lineOffset = startOffset
                    character = inch
                    leave
                end
            end
            else if inch == '/' & sourceLine~subchar(lineOffset + 1) == '*' then self~skipComment
            else do
                character = inch -- this is a good character
                leave
            end
        end
        if lineOffset > lineLength then character = self~CLAUSEEND_EOL
    end
    return character


-- ooRexx adaptation of method RexxSource::nextSpecial in interpreter/parser/scanner.cpp
::method nextSpecial private
    -- Find the next special character and verify against a target
    expose sourceLine lineOffset
    use strict arg target
    inch = self~locateToken -- find the next token
    -- have something else on this line?
    if inch <> self~CLAUSEEND_EOF & inch <> self~CLAUSEEND_EOL then do
        if sourceLine~subchar(lineOffset) == target then do
            lineOffset +=1
            return .true
        end
    end
    return .false


-- ooRexx adaptation of a subset of method RexxSource::sourceNextToken in interpreter/parser/scanner.cpp
-- I don't need to get ALL the tokens, I just need to skip them correctly (in particular strings and
-- source literal). The comments and continuation characters are also properly supported.
-- Possible result : .nil (end of source), TOKEN_EOC (end of clause), TOKEN_OTHER
-- The clause is built incrementally, accumulating all the characters, except comments.
-- The line continuations are removed, replaced by a blank.
-- So a clause is always monoline, even if it's distributed on several lines in the source.
::method sourceNextToken
    expose sourceLine lineNum lineOffset lineLength clauseEndLine clauseEndOffset buffer
    use strict arg skipSourceLiteral=.false
    do forever
        inch = self~locateToken
        if inch == self~CLAUSEEND_EOF then return .nil
        else if inch == self~CLAUSEEND_EOL then do
            if skipSourceLiteral then buffer~append(";")
            clauseEndLine = lineNum
            clauseEndOffset = lineLength
            self~gotoNextLine
            return self~TOKEN_EOC
        end
        else if inch == self~CONTINUATION then do
            buffer~append(' ')
            return self~TOKEN_OTHER
        end
        else do
            -- [don't manage symbols, not needed]
            -- start of a quoted string? [don't manage the suffix type xXbB]
            if inch == "'" | inch == '"' then do
                buffer~append(inch)
                literalDelimiter = inch
                do forever
                    lineOffset += 1
                    if lineOffset > lineLength then do
                        -- Unmatched quote
                        if literalDelimiter == "'" then raise syntax 93.900 array("Unmatched single quote")
                        raise syntax 93.900 array("Unmatched double quote")
                    end
                    inch = sourceLine~subchar(lineOffset)
                    buffer~append(inch)
                    if literalDelimiter == inch then do
                        lineOffset += 1
                        if lineOffset > lineLength then leave
                        inch = sourceLine~subchar(lineOffset)
                        if inch <> literalDelimiter then leave
                        buffer~append(inch)
                    end
                end
            end
            else do
                lineOffset += 1
                if inch == '}' then raise syntax 93.900 array("Unexpected }")
                -- start of a source literal?
                else if inch == '{' then do
                    buffer~append(inch)
                    do forever
                        if self~nextSpecial('}') then do
                            buffer~append('}')
                            leave
                        end
                        if self~sourceNextToken(.true) == .nil then do
                            raise syntax 93.900 array("Curly bracket { requires a corresponding right curly bracket }")
                        end
                    end
                end
                else if inch == ';' then do
                    if skipSourceLiteral then buffer~append(inch)
                    clauseEndLine = lineNum
                    clauseEndOffset = lineOffset - 2 -- the offset of the character before ';'
                    return self~TOKEN_EOC
                end
                else do
                    buffer~append(inch)
                end
            end
        end
        return self~TOKEN_OTHER
    end


/*
Helper to transform a source.
Possible transformations :
- Insert a clause at the begining (takes care of the expose instruction, keep it always as
  first instruction).
- Insert a clause at the end.
*/
::method transformSource
    use strict arg clauseBefore="", clauseAfter=""

    if clauseBefore <> "" | clauseAfter <> "" then do
        -- If the clause is an "expose" clause then skip it (must remain the first clause, always)
        if self~clauseAvailable then do
            clause = self~clause
            if self~class~isExposeClause(clause) then self~nextClause
        end

        -- Insert the 'clauseBefore', if any
        if clauseBefore <> "" then do
            if self~clauseAvailable then self~clause = clauseBefore ";" self~clause
            else self~appendSourceFragment(clauseBefore)
        end

        -- Insert the 'clauseAfter', if any
        if clauseAfter <> "" then self~appendSourceFragment(clauseAfter)
    end
