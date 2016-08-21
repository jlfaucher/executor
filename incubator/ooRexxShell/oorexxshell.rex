#!/usr/bin/rexx
/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2006 Rexx Language Association. All rights reserved.    */
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

/*
ooRexxShell, derived from rexxtry.
This shell supports several interpreters:
- ooRexx itself
- the system address (cmd under Windows, bash under Linux)
- any other external environment (you need to modify this script, search for hostemu for an example).
The prompt indicates which interpreter is active.
By default the shell is in ooRexx mode.
When not in ooRexx mode, you enter raw commands that are passed directly to the external environment.
When in ooRexx mode, you have a shell identical to rexxtry.
You switch from an interpreter to an other one by entering its name alone.

Example (Windows):
ooRexx[CMD]> 'dir oorexx | find ".dll"'             -- here you need to surround by quotes
ooRexx[CMD]> cmd dir oorexx | find ".dll"           -- unless you temporarily select cmd
ooRexx[CMD]> say 1+2                                -- 3
ooRexx[CMD]> cmd                                    -- switch to the cmd interpreter
CMD[ooRexx]> dir | find ".dll"                      -- raw command, no need of surrounding quotes
CMD[ooRexx]> cd c:\program files
CMD[ooRexx]> say 1+2                                -- error, the ooRexx interpreter is not active here
CMD[ooRexx]> oorexx say 1+2                         -- you can temporarily select an interpreter
CMD[ooRexx]> hostemu                                -- switch to the hostemu interpreter
HostEmu[ooRexx]> execio * diskr "install.txt" (finis stem in.  -- store the contents of the file in the stem in.
HostEmu[ooRexx]> oorexx in.=                        -- temporarily switch to ooRexx to display the stem
HostEmu[ooRexx]> exit                               -- the exit command is supported whatever the interpreter
*/

.platform~initialize

-- Use a security manager to trap the calls to the systemCommandHandler:
-- Windows: don't call directly CreateProcess, to avoid loss of doskey history (prepend "cmd /c")
-- Unix: support aliases (prepend "bash -O expand_aliases -c")
.ooRexxShell~securityManager = .securityManager~new -- make it accessible from command line
shell = .context~package~findRoutine("SHELL")
shell~setSecurityManager(.ooRexxShell~securityManager)

-- In case of error, must end any running coactivity, otherwise the program doesn't terminate
signal on any name error

.ooRexxShell~isInteractive = (arg(1) == "" & lines() == 0) -- Example of not interactive session: echo dir | oorexxshell

if .ooRexxShell~isInteractive then do
    -- Use a property file to remember the current directory
    settings = .Properties~load(.ooRexxShell~settingsFile)
    previousDirectory = settings["OOREXXSHELL_DIRECTORY"]
    if previousDirectory <> .nil then call directory previousDirectory
end

-- Bypass defect 2933583 (fixed in release 4.0.1):
-- Must pass the current address (default) because will be reset to system address when entering in SHELL routine
shell~call(arg(1), address())

finalize:
if .ooRexxShell~isExtended then .Coactivity~endAll

if .ooRexxShell~isInteractive then do
    settings = .Properties~load(.ooRexxShell~settingsFile)
    settings["OOREXXSHELL_DIRECTORY"] = directory()
    settings~save(.ooRexxShell~settingsFile)
end

if .ooRexxShell~RC == .ooRexxShell~reload then return .ooRexxShell~reload

-- 0 means ok (return 0), anything else means ko (return 1)
return .ooRexxShell~RC <> 0

error:
condition = condition("O")
if condition <> .nil then do
    if condition~message <> .nil then .ooRexxShell~sayError(condition~message)
    else if condition~errortext <> .nil then .ooRexxShell~sayError(condition~errortext)
    .ooRexxShell~sayError("Code=" condition~code)
    .ooRexxShell~sayError(condition~traceback~makearray~tostring)
end
signal finalize

-------------------------------------------------------------------------------
--::options trace i

::routine SHELL
use strict arg .ooRexxShell~initialArgument, .ooRexxShell~initialAddress

.ooRexxShell~readline = .true -- assign .false if you want only the basic "parse pull" functionality
.ooRexxShell~showInfos = .true -- assign .false if you don't want the infos displayed after each line interpretation
.oorexxShell~showColor = .true -- assign .false if you don't want the colors.

.ooRexxShell~defaultColor = "default"
.ooRexxShell~errorColor = "bred"
.ooRexxShell~infoColor = "bgreen"
.ooRexxShell~promptColor = "byellow"
.ooRexxShell~traceColor = "bpurple"
if .platform~is("windows") & .color~defaultBackground == 15 /*white*/ then do
    .ooRexxShell~infoColor = "green"
    .ooRexxShell~promptColor = "yellow"
end

.ooRexxShell~systemAddress = systemAddress()

.ooRexxShell~interpreters = .Directory~new
.ooRexxShell~interpreters~setEntry("oorexx", "ooRexx")
.ooRexxShell~interpreters~setEntry(.ooRexxShell~initialAddress, .ooRexxShell~initialAddress)
.ooRexxShell~interpreters~setEntry(.ooRexxShell~systemAddress, .ooRexxShell~systemAddress)
.ooRexxShell~interpreters~setEntry(address(), address()) -- maybe the same as systemAddress, maybe not

call loadOptionalComponents

address value .ooRexxShell~initialAddress
.ooRexxShell~interpreter = "oorexx"

.ooRexxShell~queueName = rxqueue("create")
.ooRexxShell~queueInitialName = rxqueue("set", .ooRexxShell~queueName)

call checkReadlineCapability

select
    when .ooRexxShell~isInteractive then do
        call intro
        call main
    end
    otherwise do
        if .ooRexxShell~initialArgument <> "" then push unquoted(.ooRexxShell~initialArgument) -- One-liner
        call main
    end
end

call rxqueue "delete", .ooRexxShell~queueName

return


-------------------------------------------------------------------------------
main: procedure

    REPL:
        if .ooRexxShell~debug then trace i ; else trace off
        call on halt name haltHandler
        .ooRexxShell~prompt = ""
        if .ooRexxShell~isInteractive then .ooRexxShell~prompt = prompt(address())
        .ooRexxShell~inputrx = readline(.ooRexxShell~prompt)~strip
        .ooRexxShell~RC = 0
        select
            when .ooRexxShell~inputrx == "" then
                nop

            when .ooRexxShell~inputrx~left(1) == "?" then
                .ooRexxShell~help(.ooRexxShell~inputrx~substr(2))

            when .ooRexxShell~inputrx~caselessEquals("coloroff") then
                .ooRexxShell~showColor = .false
            when .ooRexxShell~inputrx~caselessEquals("coloron") then
                .ooRexxShell~showColor = .true

            when .ooRexxShell~inputrx~caselessEquals("debugoff") then
                .ooRexxShell~debug = .false
            when .ooRexxShell~inputrx~caselessEquals("debugon") then
                .ooRexxShell~debug = .true

            when .ooRexxShell~inputrx~caselessEquals("exit") then
                exit

            when .ooRexxShell~inputrx~caselessEquals("readlineoff") then
                .ooRexxShell~readline = .false
            when .ooRexxShell~inputrx~caselessEquals("readlineon") then do
                .ooRexxShell~readline = .true
                call checkReadlineCapability
            end

            when .ooRexxShell~inputrx~caselessEquals("reload") then do
                -- Often, I modify some packages that are loaded by ooRexxShell at startup.
                -- To benefit from the changes, I have to reload the components.
                -- Can't do that without leaving the interpreter (to my knowledge).
                .ooRexxShell~RC = .ooRexxShell~reload
                exit
            end

            when .ooRexxShell~inputrx~caselessEquals("securityoff") then
                .ooRexxShell~securityManager~isEnabledByUser = .false
            when .ooRexxShell~inputrx~caselessEquals("securityon") then
                .ooRexxShell~securityManager~isEnabledByUser = .true

            when .ooRexxShell~inputrx~caselessEquals("tb") then
                .error~say(.ooRexxShell~traceback~makearray~tostring)
            when .ooRexxShell~inputrx~caselessEquals("bt") then -- backtrace seems a better name (command "bt" in lldb)
                .error~say(.ooRexxShell~traceback~makearray~tostring)

            when .ooRexxShell~inputrx~word(1)~caselessEquals("traceoff") then
                .ooRexxShell~trace(.false, .ooRexxShell~inputrx)
            when .ooRexxShell~inputrx~word(1)~caselessEquals("traceon") then
                .ooRexxShell~trace(.true, .ooRexxShell~inputrx)

            when .ooRexxShell~inputrx~word(1)~caselessEquals("trapoff") then
                .ooRexxShell~trap(.false, .ooRexxShell~inputrx)
            when .ooRexxShell~inputrx~word(1)~caselessEquals("trapon") then
                .ooRexxShell~trap(.true, .ooRexxShell~inputrx)

            when .ooRexxShell~interpreters~hasEntry(.ooRexxShell~inputrx) then do
                -- Change the default interpreter
                .ooRexxShell~interpreter = .ooRexxShell~interpreters~entry(.ooRexxShell~inputrx)
            end

            when .ooRexxShell~interpreters~hasEntry(.ooRexxShell~inputrx~word(1)) then do
                -- The line starts with an interpreter name: use it instead of the default interpreter
                .ooRexxShell~commandInterpreter = .ooRexxShell~interpreters~entry(.ooRexxShell~inputrx~word(1))
                .ooRexxShell~command = .ooRexxShell~inputrx~substr(.ooRexxShell~inputrx~wordIndex(2))
                signal dispatchCommand -- don't call, because some ooRexx interpreter informations would be saved/restored
            end

            otherwise do
                -- Interpret the line with the default interpreter
                .ooRexxShell~commandInterpreter = .ooRexxShell~interpreter
                .ooRexxShell~command = .ooRexxShell~inputrx
                signal dispatchCommand -- don't call, because some ooRexx interpreter informations would be saved/restored
            end
        end

        CONTINUE_REPL:
        if var("RC") then .ooRexxShell~RC = RC
        if \.ooRexxShell~isInteractive & queued() == 0 & lines() == 0 then return -- When non-interactive, stop loop when queue is empty and default input stream is empty.
    signal REPL


-------------------------------------------------------------------------------
intro: procedure
    parse version version
    .ooRexxShell~sayInfo
    .ooRexxShell~sayInfo(version)
    .ooRexxShell~sayInfo("Input queue name:" .ooRexxShell~queueName)
    return


-------------------------------------------------------------------------------
prompt: procedure
    use strict arg currentAddress
    .color~select(.ooRexxShell~promptColor)
    say
    say directory()
    .color~select(.ooRexxShell~defaultColor)
    -- No longer display the prompt, return it and let readline display it
    prompt = .ooRexxShell~interpreter
    if .ooRexxShell~interpreter~caselessEquals("ooRexx") then prompt ||= "["currentAddress"]" ; else prompt ||= "[ooRexx]"
    if .ooRexxShell~securityManager~isEnabledByUser then prompt ||= "> " ; else prompt ||= "!>"
    return prompt


-------------------------------------------------------------------------------
checkReadlineCapability: procedure
    -- Bypass a bug in official ooRexx which delegates to system() when the passed address is bash.
    -- The bug is that system() delegates to /bin/sh, and should be called only when the passed address is sh.
    -- Because of this bug, the readline procedure (which depends on bash) is not working and must be deactivated.
    if .ooRexxShell~isInteractive, .ooRexxShell~systemAddress~caselessEquals("bash") then do
        address value .ooRexxShell~systemAddress
            "echo $BASH_VERSION | rxqueue "quoted(.ooRexxShell~queueName)" /lifo"
        address -- restore
        bash_version = ""
        if queued() <> 0 then parse pull bash_version
        if bash_version == "" then do
            .ooRexxShell~readline = .false
            .ooRexxShell~sayError("[readline] ooRexx bug detected, fallback to raw input (no more history, no more globbing)")
        end
    end
    return


-------------------------------------------------------------------------------
readline: procedure
    use strict arg prompt
    inputrx = ""
    RC = 0
    if .ooRexxShell~traceReadline then do
        .ooRexxShell~sayTrace("[readline] queued()=" queued())
        .ooRexxShell~sayTrace("[readline] lines()=" lines())
    end
    select
        when queued() == 0 & lines() == 0 & .ooRexxShell~systemAddress~caselessEquals("cmd") & .ooRexxShell~readline then do
            -- I want the doskey macros and filename tab autocompletion... Delegates the input to cmd.
            -- HKEY_CURRENT_USER/Software/Microsoft/Command Processor/CompletionChar = 9
            address value .ooRexxShell~systemAddress
                "(title ooRexxShell) &",
                "(set inputrx=) &",
                "(set /p inputrx="quoted(prompt)") &",
                "(if defined inputrx set inputrx | rxqueue "quoted(.ooRexxShell~queueName)" /lifo) &",
                "(if not defined inputrx echo inputrx= | rxqueue "quoted(.ooRexxShell~queueName)" /lifo)"
            address -- restore
            if queued() <> 0 then parse pull inputrx
            if inputrx == "" then do
                if RC == 0 then inputrx = "exit" -- eof. Example: happens after "dir" has been processed when doing that: echo dir | oorexxshell
            end
            else if inputrx~abbrev("inputrx=") then inputrx = inputrx~substr(9) -- remove "inputrx="
        end
        when queued() == 0 & lines() == 0 & .ooRexxShell~systemAddress~caselessEquals("bash") & .ooRexxShell~readline then do
            -- I want all the features of readline when editing my command line (history, tab completion, ...)
            -- Two strings are pushed to rxqueue in one line, separated with \000 (NUL) :
            -- one generated by the internal command 'set', which manages the escaped characters.
            -- one generated by the internal command 'print', to get the input as-is.
            -- Temporary: A third string is pushed to rxqueue, to let me see what I get with printf %q
            address value .ooRexxShell~systemAddress
                "set -o noglob ;",
                "HISTFILE=".ooRexxShell~historyFile" ;",
                "history -r ;",
                "read -r -e -p "quoted(prompt)" inputrx ;",
                "history -s -- $inputrx ;",
                "history -w ;",
                "(set | grep ^inputrx= | tr '\n' '\000' ; printf ""%s\000"" ""$inputrx"" ; printf ""%q"" ""$inputrx"") | rxqueue "quoted(.ooRexxShell~queueName)" /lifo"
            address -- restore
            if queued() <> 0 then do
                -- inputrx1: quoted in a way that can be reused as shell input.
                -- inputrx2: unquoted (as is)
                parse pull inputrx
                if inputrx == "" then inputrx = "exit" -- eof, happens after "ls" has been processed when doing that: echo ls | oorexxshell
                else do
                    if inputrx~abbrev("inputrx=") then do
                        -- Since the line read from the queue starts with "inputrx=",
                        -- we assume that this line has been sent by the read command.
                        parse var inputrx "inputrx=" inputrx1 "0"x inputrx2 "0"x inputrx3
                        if .ooRexxShell~traceReadline then do
                            .ooRexxShell~sayTrace("[readline] inputrx1=" inputrx1)
                            .ooRexxshell~sayTrace("[readline] inputrx2=" inputrx2)
                            .ooRexxShell~sayTrace("[readline] inputrx3=" inputrx3) -- not used, I want just to compare with inputrx1
                        end

                        -- If inputrx1 contains more than one word, then it has been surrounded by quotes:
                        -- Ex: echo, 'echo a', ls, 'ls -la'
                        -- Remove these quotes.
                        inputrx1 = unquoted(inputrx1, "'")

                        -- Select the most appropriate line, depending on the target interpreter
                        interpreter = .ooRexxShell~interpreter -- default
                        if .ooRexxShell~interpreters~hasEntry(inputrx1~word(1)) then interpreter = inputrx1~word(1) -- temporary interpreter
                        if interpreter~caselessEquals("bash") then inputrx = inputrx1
                        else inputrx = inputrx2
                    end
                    else do
                        -- Since the line read from the queue does not start with "inputrx",
                        -- we assume that this line has been sent by another process, not by the read command.
                        nop
                    end
                end
            end
        end
        otherwise do
            call charout ,prompt
            parse pull inputrx -- Input queue or standard input or keyboard.
            --if .ooRexxShell~isInteractive then say inputrx
        end
    end
    if .ooRexxShell~traceReadline then do
        .ooRexxShell~sayTrace("[readline] inputrx=" inputrx)
    end
    if RC <> 0 then do
        .ooRexxShell~readline = .false
        .ooRexxShell~sayError("[readline] RC="RC)
        .ooRexxShell~sayError("[readline] Something is not working, fallback to raw input (no more history, no more globbing)")
    end
    return inputrx


-------------------------------------------------------------------------------
-- Don't know how to avoid these hardcoded values...
-- 'rexx -e "say address()"' would work IF the default address was the right one
-- to execute the command. But in THE (for example), the default address is THE,
-- and that command wouldn't work.
-- With Regina, I could use ADDRESS SYSTEM, but there is no such generic environment
-- in ooRexx (each platform has a different environment).
systemAddress: procedure
    select
        when .platform~is("windows") then return "cmd"
        -- From here, calculated like SYSINITIALADDRESS in utilities\rexx\platform\unix\rexx.cpp
        when .platform~is("aix") then return "ksh"
        when .platform~is("sunos") then return "sh"
        otherwise return "bash"
    end


-------------------------------------------------------------------------------
haltHandler:
    .ooRexxShell~sayInfo("Halt disabled.")
    return


-------------------------------------------------------------------------------
-- Remember: don't implement that as a procedure or routine or method !
-- Moreover don't call it, you must jump to (signal) it...
dispatchCommand:
    call time('r') -- to see how long this takes
    RC = 0
    .ooRexxShell~error = .false
    call rxqueue "set", .ooRexxShell~queueInitialName -- Reactivate the initial queue, for the command evaluation
    if .ooRexxshell~securityManager~isEnabledByUser then .ooRexxShell~securityManager~isEnabled = .true
    if .ooRexxShell~commandInterpreter~caselessEquals("ooRexx") then
        signal interpretCommand -- don't call
    else
        signal addressCommand -- don't call

    return_to_dispatchCommand:
    if .ooRexxshell~securityManager~isEnabledByUser then .ooRexxShell~securityManager~isEnabled = .false
    options "COMMANDS" -- Commands must be enabled for proper execution of ooRexxShell
    call rxqueue "set", .ooRexxShell~queueName -- Back to the private ooRexxShell queue
    if .ooRexxShell~error then .ooRexxShell~sayCondition(condition("O"))
    if RC <> 0 & \.ooRexxShell~error then do
        -- RC can be set by interpretCommand or by addressCommand
        -- Not displayed in case of error, because the integer portion of Code already provides the same value as RC
        .ooRexxShell~sayError("RC=" RC)
    end
    if RC <> 0 | .ooRexxShell~error then do
        .ooRexxShell~sayInfo(.ooRexxShell~command)
    end
    if .ooRexxShell~isInteractive & .ooRexxShell~showInfos then do
        .ooRexxShell~sayInfo("Duration:" time('e')) -- elapsed duration
        if .ooRexxShell~isExtended then .ooRexxShell~sayInfo("#Coactivities:" .Coactivity~count) -- counter of coactivities
    end
    signal CONTINUE_REPL


-------------------------------------------------------------------------------
-- Remember: don't implement that as a procedure or routine or method !
-- Any variable created by interpret would not be available to the next interpret,
-- because not created in the same context.
-- Moreover don't call it, you must jump to (signal) it...
interpretCommand:
    .ooRexxShell~command =  transformSource(.ooRexxShell~command)
    if .ooRexxShell~traceDispatchCommand then do
        .ooRexxShell~sayTrace("[interpret] command=" .ooRexxShell~command)
    end
    if .ooRexxShell~hasLastResult then result = .ooRexxShell~lastResult -- restore previous result
                                  else drop result
    if .ooRexxShell~trapSyntax then signal on syntax name interpretError
    if .ooRexxShell~trapLostdigits then signal on lostdigits
    interpret .ooRexxShell~command
    signal off syntax
    signal off lostdigits
    if var("result") then .ooRexxShell~lastResult = result -- backup current result
                     else .ooRexxShell~dropLastResult
    signal return_to_dispatchCommand

    lostdigits:
    interpretError:
    .ooRexxShell~error = .true
    signal return_to_dispatchCommand


-------------------------------------------------------------------------------
transformSource: procedure
    use strict arg command

    signal on syntax name transformSourceError -- the clauser can raise an error
    if .ooRexxShell~isExtended then do
        -- Manage the "=" shortcut at the end of each clause
        sourceArray = .array~of(command)
        clauser = .Clauser~new(sourceArray)
        do while clauser~clauseAvailable
            clause = clauser~clause~strip
            if clause~right(1) == "=" then do
                clause = clause~left(clause~length - 1)
                clauser~clause = 'options "NOCOMMANDS";' clause '; call dumpResult var("result"), result; options "COMMANDS"'
            end
            clauser~nextClause
        end
        command = sourceArray[1]
    end
    else do
        -- Manage the "=" shortcut at the end of the command (.clauser not available)
        /*
        This is a rudimentary support!
        Examples of bad support:
        say 1; say 2; 1=
            --> call dumpResult .true, say 1; say 2; 1
            SAY 1
            2
            bash: 1: not found
        1,2,3=
            --> call dumpResult .true, 1,2,3
            Too many arguments in invocation of DUMPRESULT; maximum expected is 2
        */
        command = command~strip
        if command~right(1) == "=" then command = "call dumpResult .true," command~left(command~length - 1)
    end
    transformSourceError: -- in case of error, just return the original command: an error will be raised by interpret, and caught.
    return command


-------------------------------------------------------------------------------
-- Remember: don't implement that as a procedure or routine or method !
-- Moreover don't call it, you must jump to (signal) it...
addressCommand:
    address value .ooRexxShell~commandInterpreter
    (.ooRexxShell~command)
    address -- restore previous
    signal return_to_dispatchCommand


-------------------------------------------------------------------------------
dumpResult: procedure
    use strict arg hasValue, value
    if \hasValue then do
        say "[no result]"
        return
    end

    if .CoactivitySupplier~isA(.Class), value~isA(.CoactivitySupplier) then say .ooRexxShell~prettyString(value) -- must not consume the datas
    else if .ooRexxShell~isExtended, value~isA(.enclosedArray) then say value~ppRepresentation(100) -- condensed output, 100 items max
    else if .ooRexxShell~isExtended, value~isA(.array), value~dimension == 1 then say value~ppRepresentation(100) -- condensed output, 100 items max
    else if value~isA(.Collection) | value~isA(.Supplier) then .ooRexxShell~sayCollection(value)
    else say .ooRexxShell~prettyString(value)

    return value -- To get this value in the variable RESULT


-------------------------------------------------------------------------------
-- Load optional packages/libraries
-- Remember: don't implement that as a procedure or routine or method !
loadOptionalComponents:
    if .platform~is("windows") then do
        call loadPackage("oodialog.cls")
        call loadPackage("winsystm.cls")
    end
    if \.platform~is("windows") then do
        call loadLibrary("rxunixsys")
    end
    if loadLibrary("hostemu") then .ooRexxShell~interpreters~setEntry("hostemu", "HostEmu")
    call loadPackage("mime.cls")
    call loadPackage("rxftp.cls")
    call loadLibrary("rxmath")
    call loadPackage("rxregexp.cls")
    .ooRexxShell~hasRegex = loadPackage("regex/regex.cls")
    call loadPackage("smtp.cls")
    call loadPackage("socket.cls")
    call loadPackage("streamsocket.cls")
    call loadPackage("pipeline/pipe.rex")
    --call loadPackage("ooSQLite.cls")
    .ooRexxShell~hasRgfUtil2 = loadPackage("rgf_util2/rgf_util2.rex") -- http://wi.wu.ac.at/rgf/rexx/orx20/rgf_util2.rex
    .ooRexxShell~hasBsf = loadPackage("BSF.CLS")
    if value("UNO_INSTALLED",,"ENVIRONMENT") <> "" then call loadPackage("UNO.CLS")
    .ooRexxShell~isExtended = .true
    if \loadPackage("extension/extensions.cls", .true) then do -- requires jlf sandbox ooRexx
        .ooRexxShell~isExtended = .false
        call loadPackage("extension/std/extensions-std.cls") -- works with standard ooRexx, but integration is weak
    end
    if .ooRexxShell~isExtended then do
        call loadPackage("oorexxshell_queries.cls")
        call loadPackage("pipeline/pipe_extension.cls")
        call loadPackage("rgf_util2/rgf_util2_wrappers.rex")
        -- regex.cls use the method .String~contains which is available only from ooRexx v5.
        -- Add this method if not available.
        if \ ""~hasMethod("contains") then .String~define("contains", "use strict arg needle; return self~pos(needle) <> 0")
    end

    return


-------------------------------------------------------------------------------
-- Remember: don't implement that as a procedure or routine or method !
loadPackage:
    use strict arg filename, silent=.false
    signal on syntax name loadPackageError
    .context~package~loadPackage(filename)
    if .ooRexxShell~isInteractive then .ooRexxShell~sayInfo("loadPackage OK for" filename)
    return .true
    loadPackageError:
    if \ silent then .ooRexxShell~sayError("loadPackage KO for" filename)
    return .false


-------------------------------------------------------------------------------
-- Remember: don't implement that as a procedure or routine or method !
loadLibrary:
    use strict arg filename
    signal on syntax name loadLibraryError
    if .context~package~loadLibrary(filename) then do
        if .ooRexxShell~isInteractive then .ooRexxShell~sayInfo("loadLibrary OK for" filename)
        return .true
    end
    loadLibraryError:
    .ooRexxShell~sayError("loadLibrary KO for" filename)
    return .false


-------------------------------------------------------------------------------
::class ooRexxShell
-------------------------------------------------------------------------------

::constant reload 200 -- Arbitrary value that will be returned to the system, to indicate that a restart of the shell is requested

::attribute command class -- The current command to interpret, can be a substring of inputrx
::attribute commandInterpreter class -- The current interpreter, can be the first word of inputrx, or the default interpreter
::attribute error class -- Will be .true if the last command raised an error
::attribute hasBsf class -- Will be .true if BSF.cls has been loaded
::attribute hasRegex class -- Will be .true is regex.cls has been loaded
::attribute hasRgfUtil2 class -- Will be .true if rgf_util2.rex has been loaded
::attribute historyFile class
::attribute initialAddress class -- The initial address on startup, not necessarily the system address (can be "THE")
::attribute initialArgument class -- The command line argument on startup
::attribute inputrx class -- The current input to interpret
::attribute interpreter class -- One of the environments in 'interpreters' or the special value "ooRexx"
::attribute interpreters class -- The set of interpreters that can be activated
::attribute isExtended class -- Will be .true if the extended ooRexx interpreter is used.
::attribute isInteractive class -- Are we in interactive mode ?
::attribute lastResult class -- result's value from the last interpreted line
::attribute prompt class -- The prompt to display
::attribute queueName class -- Private queue for no interference with the user commands
::attribute queueInitialName class -- Backup the initial external queue name (probably "SESSION")
::attribute RC class -- Return code from the last executed command
::attribute readline class -- When .true, the readline functionality is activated (history, tab expansion...)
::attribute securityManager class
::attribute settingsFile class
::attribute showInfos class
::attribute systemAddress class -- "CMD" under windows, "bash" under linux, etc...
::attribute traceback class -- traceback of last error

::attribute showColor class
::attribute defaultColor class
::attribute errorColor class
::attribute infoColor class
::attribute promptColor class
::attribute traceColor class

::attribute traceDispatchCommand class
::attribute traceFilter class
::attribute traceReadline class

::attribute debug class

::attribute trapLostdigits class -- default true: the condition LOSTDIGITS is trapped when interpreting the command
::attribute trapSyntax class -- default true: the condition SYNTAX is trapped when interpreting the command


::method init class
    self~debug = .false
    self~hasBsf = .false
    self~hasRegex = .false
    self~hasRgfUtil2 = .false
    self~isExtended = .false
    self~traceReadline = .false
    self~traceDispatchCommand = .false
    self~traceFilter = .false
    self~traceback = .array~new
    self~trapSyntax = .true
    self~trapLostdigits = .true

    HOME = value("HOME",,"ENVIRONMENT") -- probably defined under MacOs and Linux, but maybe not under Windows
    if HOME == "" then do
        HOMEDRIVE = value("HOMEDRIVE",,"ENVIRONMENT")
        HOMEPATH = value("HOMEPATH",,"ENVIRONMENT")
        HOME = HOMEDRIVE || HOMEPATH
    end

    -- Use a property file to remember the current directory
    self~settingsFile = HOME || "/.oorexxshell.ini"

    -- When possible, use a history file specific for ooRexxShell
    self~historyFile = HOME || "/.history_oorexxshell"


::method hasLastResult class
    expose lastResult
    return var("lastResult")


::method dropLastResult class
    expose lastResult
    drop lastResult


::method sayInfo class
    use strict arg text=""
    .color~select(.ooRexxShell~infoColor, .output)
    .output~say(text)
    .color~select(.ooRexxShell~defaultColor, .output)


::method sayTrace class
    use strict arg text=""
    .color~select(.ooRexxShell~traceColor, .traceOutput)
    .traceOutput~say(text)
    .color~select(.ooRexxShell~defaultColor, .traceOutput)


::method sayError class
    use strict arg text=""
    .color~select(.ooRexxShell~errorColor, .error)
    .error~say(text)
    .color~select(.ooRexxShell~defaultColor, .error)


::method sayCondition class
    use strict arg condition
    if condition~condition <> "SYNTAX" then .ooRexxShell~sayError(condition~condition)
    if condition~description <> .nil, condition~description <> "" then .ooRexxShell~sayError(condition~description)

    -- For SYNTAX conditions
    if condition~message <> .nil then .ooRexxShell~sayError(condition~message)
    else if condition~errortext <> .nil then .ooRexxShell~sayError(condition~errortext)
    if condition~code <> .nil then .ooRexxShell~sayError("Code=" condition~code)

    .ooRexxShell~traceback = condition~traceback


::method sayCollection class
    -- The package rgfutil2 is optional, use it if loaded.
    if .ooRexxShell~hasRgfUtil2 then .context~package~findroutine("dump2")~callWith(arg(1, "a"))
    else say arg(1)


::method prettyString class
    -- The package rgfutil2 is optional, use it if loaded.
    if .ooRexxShell~hasRgfUtil2 then return .context~package~findroutine("pp2")~callWith(arg(1, "a"))
    return arg(1)


::method singularPlural class
    use strict arg count, singularText, pluralText
    if abs(count) <= 1 then return count singularText
    return count pluralText


::method help class
    use strict arg queryFilter
    queryFilterArgs = string2args(queryFilter, .true) -- true: array of Argument
    queryArgs = queryFilterArgs
    filteringStream = .nil
    signal on syntax name helpError -- trap regular expression errors
    if .filteringStream~isa(.class) then do
        filterArgs = .array~new -- no filter by default (but will allow to display the lineCount)
        -- filter specified in the query ?
        firstFilterIndex = .filteringStream~firstFilterIndex(queryFilterArgs)
        if firstFilterIndex <> 0 then do
            -- 2 sections : the query and the filter
            queryArgs = queryFilterArgs~section(1, firstFilterIndex - 1)
            filterArgs = queryFilterArgs~section(firstFilterIndex)
        end
        filteringStream = .filteringStream~new(.output~current, filterArgs)
        if \filteringStream~valid then return -- Syntax error in regular expression
        if .ooRexxShell~traceFilter then filteringStream~traceFilter(self)
        .output~destination(filteringStream)
    end
    .ooRexxShell~dispatchHelp(queryFilter, queryArgs, filteringStream)
    if filteringStream <> .nil then do
        filteringStream~flush
        .output~destination -- restore the previous destination
        /*if filteringStream~lineCount > 0 then*/ .ooRexxShell~sayInfo("[Info]" .ooRexxShell~singularPlural(filteringStream~lineCount, "line", "lines") "displayed")
    end
    return

    helpError:
    if filteringStream <> .nil then do
        filteringStream~flush
        .output~destination -- restore the previous destination
    end
    .ooRexxShell~sayCondition(condition("O"))



::method dispatchHelp class
    use strict arg queryFilter, queryArgs, filteringStream
    if queryArgs[1] == .nil then do
        say "Help:"
        say "    ?: display help."
        say "    ?c[lasses] c1 c2... : display classes."
        say "    ?c[lasses].m[ethods] c1 c2... : display local methods per classes (cm)."
        say "    ?c[lasses].m[ethods].i[nherited] c1 c2... : local & inherited methods (cmi)."
        say "    ?d[ocumentation]: invoke ooRexx documentation."
        say "    ?f[lags]: describe the flags displayed for classes & methods."
        say "    ?h[elp] c1 c2 ... : local description of classes."
        say "    ?h[elp].i[nherited] c1 c2 ... : local & inherited description of classes (hi)."
        say "    ?i[nterpreters]: interpreters that can be selected."
        say "    ?m[ethods] method1 method2 ... : display methods."
        say "    ?p[ackages]: display the loaded packages."
        say "    ?r[outines] routine1 routine2... : display routines."
        .ooRexxShell~helpCommands
        return
    end

    arg1 = queryArgs[1]
    word1 = arg1~string
    parse var word1 subword1 "." rest1
    rest = queryArgs~section(2)

    if "classes"~caselessAbbrev(subword1) then do
        methods = .false
        inherited = .false
        do while rest1 <> ""
            parse var rest1 first1 "." rest1
            if "methods"~caselessAbbrev(first1) then methods = .true
            else if "inherited"~caselessAbbrev(first1) then inherited = .true
            else do
                .ooRexxShell~sayError("Expected 'methods' or 'inherited' after" quoted(subword1".") "in" quoted(word1)". Got" quoted(first1))
                return
            end
        end
        if inherited then methods = .true
        if methods then .ooRexxShell~helpClassMethods(rest, inherited)
        else .ooRexxShell~helpClasses(rest)
    end

    -- For convenience... cm is shorter than c.m, cmi is shorter than c.m.i
    else if "cm"~caselessEquals(word1) then .ooRexxShell~helpClassMethods(rest, .false, filteringStream)
    else if "cmi"~caselessEquals(word1) then .ooRexxShell~helpClassMethods(rest, .true, filteringStream)

    else if "documentation"~caselessAbbrev(word1) & rest~isEmpty then .ooRexxShell~helpDocumentation

    else if "flags"~caselessAbbrev(word1) & rest~isEmpty then .ooRexxShell~helpFlags

    else if "help"~caselessAbbrev(subword1) then do
        inherited = .false
        do while rest1 <> ""
            parse var rest1 first1 "." rest1
            if "inherited"~caselessAbbrev(first1) then inherited = .true
            else do
                .ooRexxShell~sayError("Expected 'inherited' after" quoted(subword1".") "in" quoted(word1)". Got" quoted(first1))
                return
            end
        end
        .ooRexxShell~helpHelp(rest, inherited)
    end

    -- For convenience... hi is shorter than h.i
    else if "hi"~caselessEquals(word1) then .ooRexxShell~helpHelp(rest, .true)

    else if "interpreters"~caselessAbbrev(word1) & rest~isEmpty then .ooRexxShell~helpInterpreters
    else if "methods"~caselessAbbrev(word1) then .ooRexxShell~helpMethods(rest)
    else if "packages"~caselessAbbrev(word1) & rest~isEmpty then .ooRexxShell~helpPackages
    else if "routines"~caselessAbbrev(word1) then .ooRexxShell~helpRoutines(rest)

    else .ooRexxShell~sayError("Query not understood:" queryFilter)


::method helpClasses class
    -- All or specified classes (public & private) that are visible from current context, with their package
    if \.ooRexxShell~isExtended then do; .ooRexxShell~sayError("Needs extended ooRexx"); return; end
    use strict arg classnames
    .classInfoQuery~displayClasses(classnames, self, .context)


::method helpClassMethods class
    -- Display the methods of each specified class
    if \.ooRexxShell~isExtended then do; .ooRexxShell~sayError("Needs extended ooRexx"); return; end
    use strict arg classnames, inherited, filteringStream
    .classInfoQuery~displayClassMethods(classnames, inherited, self, .context, filteringStream)


::method helpCommands class
    .ooRexxShell~helpInterpreters
    say "Other commands:"
    say "    bt: display the backtrace of the last error (same as tb)."
    say "    coloroff: deactivate the colors."
    say "    coloron : activate the colors."
    say "    debugoff: deactivate the full trace of the internals of ooRexxShell."
    say "    debugon : activate the full trace of the internals of ooRexxShell."
    say "    exit: exit ooRexxShell."
    say "    readlineoff: use the raw parse pull for the input."
    say "    readlineon : delegate to the system readline (history, tab completion)."
    say "    reload: exit the current session and reload all the packages/librairies."
    say "    securityoff: deactivate the security manager. No transformation of commands."
    say "    securityon : activate the security manager. Transformation of commands."
    say "    tb: display the traceback of the last error (same as bt)."
    say "    traceoff [d[ispatch]] [f[ilter]] [r[eadline]] [s[ecurity]]: deactivate the trace."
    say "    traceon  [d[ispatch]] [f[ilter]] [r[eadline]] [s[ecurity]]: activate the trace."
    say "    trapoff [l[ostdigits]] [s[yntax]]: deactivate the conditions traps."
    say "    trapon  [l[ostdigits]] [s[yntax]]: activate the conditions traps."
    say "Input queue name:" .ooRexxShell~queueName


::method helpDocumentation class
    -- The current address can be anything, not necessarily the system address.
    -- Switch to the system address
    address value .ooRexxShell~systemAddress
    select
        when .platform~is("windows"), value("REXX_HOME",,"ENVIRONMENT") <> "" then do
            /* issue the pdf as a command using quotes because the install dir may contain blanks */
            'start "Rexx Online Documentation"' '"' || value("REXX_HOME",,"ENVIRONMENT") || "\doc\rexxref.pdf" || '"'
        end
        when .platform~is("windows") then do
            -- Fallback if REXX_HOME not defined: Web site
            'start http://www.oorexx.org/docs'
        end
        when (.platform~is("aix") | .platform~is("linux") | .platform~is("sunos")), value("REXX_HOME",,"ENVIRONMENT") <> "" then do
            'acroread "' || value("REXX_HOME",,"ENVIRONMENT") || '"/doc/rexxref.pdf&'
        end
        when .platform~is("macosx") | .platform~is("darwin") then do
            'open "http://www.oorexx.org/docs/"' -- not perfect: switch to Safari but the new window is not visible (at least on my machine).
        end
        otherwise .ooRexxShell~sayError(.platform~name "has no online help for ooRexx.")
    end
    address -- restore


::method helpFlags class
    if \.ooRexxShell~isExtended then do; .ooRexxShell~sayError("Needs extended ooRexx"); return; end
    .classInfoQuery~displayFlags


::method helpHelp class
    if \.ooRexxShell~isExtended then do; .ooRexxShell~sayError("Needs extended ooRexx"); return; end
    use strict arg classnames, inherited
    .classInfoQuery~displayHelp(classnames, inherited, self, .context)


::method helpInterpreters class
    say "Interpreters:"
    do interpreter over .ooRexxShell~interpreters~allIndexes~sort
        say "    "interpreter~lower": to activate the ".ooRexxShell~interpreters[interpreter]" interpreter."
    end


::method helpMethods class
    -- Display the defining classes of each specified method
    if \.ooRexxShell~isExtended then do; .ooRexxShell~sayError("Needs extended ooRexx"); return; end
    use strict arg methodnames
    .classInfoQuery~displayMethods(methodnames, self, .context)


::method helpPackages class
    -- All packages that are visible from current context, including the current package (source of the pipeline).
    if \.ooRexxShell~isExtended then do; .ooRexxShell~sayError("Needs extended ooRexx"); return; end
    .classInfoQuery~displayPackages(self, .context)


::method helpRoutines class
    -- Display the defining package of each specified routine
    if \.ooRexxShell~isExtended then do; .ooRexxShell~sayError("Needs extended ooRexx"); return; end
    use strict arg routinenames
    .classInfoQuery~displayRoutines(routinenames, self, .context)


::method trace class
    use strict arg trace, inputrx
    parse var inputrx . rest
    if rest == "" then do
        self~traceDispatchCommand = trace
        self~traceFilter = trace
        self~traceReadline = trace
        self~securityManager~traceCommand = trace
    end
    do arg over string2args(rest)
        if "dispatchcommand"~caselessAbbrev(arg) then self~traceDispatchCommand = trace
        else if "filter"~caselessAbbrev(arg) then self~traceFilter = trace
        else if "readline"~caselessAbbrev(arg) then self~traceReadline = trace
        else if "securitymanager"~caselessAbbrev(arg) then self~securityManager~traceCommand = trace
        else .ooRexxShell~sayError("Unknown:" arg)
    end


::method trap class
    use strict arg trap, inputrx
    parse var inputrx . rest
    if rest == "" then do
        self~trapLostdigits = trap
        self~trapSyntax = trap
    end
    do arg over string2args(rest)
        if "lostdigit"~caselessAbbrev(arg) then self~trapLostdigits= trap
        else if "syntax"~caselessAbbrev(arg) then self~trapSyntax = trap
        else .ooRexxShell~sayError("Unknown:" arg)
    end


-------------------------------------------------------------------------------
::class securityManager
-------------------------------------------------------------------------------
-- Under the control of the user:

-- isEnabledByUser is true by default, can be set to false using the command securityoff.
-- When false, the security manager is deactivated (typically for debug purpose).
::attribute isEnabledByUser
::attribute traceCommand

-- Under the control of ooRexxShell
::attribute isEnabled


::method init
   self~isEnabledByUser = .true
   self~isEnabled = .false
   self~traceCommand = .false


::method unknownDisabled
    -- This is an optimization available only with Executor.
    -- If the method "unknownDisabled" exists, then the method "unknown" of the security manager is disabled (never called).

    -- When a security manager is registered, the official ooRexx interpreter
    -- raises an error if the following messages are not understood:
    -- "call", "command", "environment", "local", "method", "requires", "stream".
    -- So no choice with official ooRexx, either the corresponding method or the method "unknown" must be defined.

    -- Optimizations with Executor:
    -- When the security manager is registered, the methods
    -- "call", "command", "environment", "local", "method", "requires", "stream"
    -- are searched on the security manager. If not found, and "unknown" is not defined or "unknownDisabled" is defined
    -- then the corresponding messages are flagged to be never sent.
    -- The test of existence is done only when the security manager is registered, not at each checkpoint.


::method unknown
    -- I assume that you used often the environment symbols .true, .false, .nil ?
    -- I assume that you often create instances of predefined classes like .array, .list, .directory, etc... ?
    -- If you are curious, then activate the following lines.
    -- You will see that each access to the global .environment will raise two messages sent to the security manager:
    -- "local" and then "environment".
    -- Messages sent for nothing, since I return 0 to indicate that the program is authorized to perform the action.
    -- do 1000000;x=.true;end   -- 5.440 sec
    -- do 1000000;x=1;end       -- 0.080 sec (here, the security manager is not used)

    -- use arg message, arguments
    -- say message quoted(arguments[1]~name)
    return 0


::method command
    if .ooRexxShell~debug then trace i ; else trace off
    use arg info

    isEnabled = self~isEnabledByUser & self~isEnabled
    if isEnabled then status = "enabled" ; else status = "disabled"

    if self~traceCommand then do
        .ooRexxShell~sayTrace("[securityManager ("status")] address=" info~address)
        .ooRexxShell~sayTrace("[securityManager ("status")] command=" info~command)
    end

    if \ isEnabled then return 0 -- delegate to system
    -- Use a temporary property file to remember the child process directory
    temporarySettingsFile = .ooRexxShell~settingsFile"."SysQueryProcess("PID")
    if SysFileExists(temporarySettingsFile) then call SysFileDelete temporarySettingsFile -- will be created by the command execution, maybe
    command = self~adjustCommand(info~address, info~command, temporarySettingsFile)
    if command == info~command then return 0 -- command not impacted, delegate to system
    self~isEnabled = .false
        address value info~address
        command
        info~rc = RC
        address -- restore previous
    self~isEnabled = .true
    if SysFileExists(temporarySettingsFile) then do
        settings = .Properties~load(temporarySettingsFile)
        directory = settings["OOREXXSHELL_DIRECTORY"]
        if directory <> .nil then call directory directory
        call SysFileDelete temporarySettingsFile
    end
    return 1


::method adjustCommand
    if .ooRexxShell~debug then trace i ; else trace off
    use strict arg address, command, temporarySettingsFile
    if address~caselessEquals("cmd") then do
        -- [WIN32] Bypass a problem with doskey history:
        -- When a command is directly executable (i.e. passed without "cmd /c" to CreateProcess
        -- in SystemCommands.cpp) then the history is cleared...
        -- So add "cmd /c" in front of the command...
        -- But I don't want it for the commands directly managed by the systemCommandHandler.
        if command~caselessPos("set ") == 1, command~substr(5)~strip~pos("=") > 1 then return command -- variable assignment: "set <nospace>="
        if command~caselessPos("cd ") == 1 then return command -- change directory
        if .RegularExpression~new("[:ALPHA:]:")~~match(command)~position == 2 & command~length == 2 then return command -- change drive
        args = string2args(command)
        if args[1]~caselessEquals("cmd") then return command -- already prefixed by "cmd ..."
        if args[1]~caselessEquals("start") then return command -- already prefixed by "start ..."
        exepath = .platform~which(args[1])
        exefullpath = qualify(exepath)
        if .platform~subsystem(exefullpath) == 2 then return 'start "" 'command -- Don't wait when GUI application
        --return 'cmd /c "'command'"'
        return 'cmd /v /c ' ||,
               quoted(,
                   paren(command) ||,
                   ' & set OOREXXSHELL_ERRORLEVEL=!ERRORLEVEL!' ||,
                   ' & echo OOREXXSHELL_DIRECTORY=!CD! > ' || quoted(temporarySettingsFile) ||,
                   ' & doskey' ||, -- seems to help keeping the history when a command fails, don't ask me why
                   ' & exit /b !OOREXXSHELL_ERRORLEVEL!',
               )
    end
    else if address~caselessEquals("bash") then do
        -- If directly managed by the systemCommandHandler then don't add bash in front of the command
        -- if command~caselessEquals("cd") == 1 then return command -- home directory
        -- if command~caselessPos("cd ") == 1 then return command -- change directory
        if command~caselessPos("set ") == 1 then return command -- variable assignment
        if command~caselessPos("unset ") == 1 then return command -- variable unassignment
        if command~caselessPos("export ") == 1 then return command -- variable assignment
        if command~word(1)~caselessEquals("bash") then return command -- already prefixed by "bash ..."
        -- Expands the aliases, assuming you have defined them...
        -- One way to define them is to do:
        -- export BASH_ENV=~/bash_env
        -- and declare the aliases in this file.
        -- The trap command is used to save the current directory of the child process
        return "bash -O expand_aliases -c 'function trap_exit { echo OOREXXSHELL_DIRECTORY=$PWD > "temporarySettingsFile" ; } ; trap trap_exit EXIT ; history -r ; "command"'" -- the special characters have been already escaped by readline()
    end
    return command


-------------------------------------------------------------------------------
::class color
-------------------------------------------------------------------------------

-- Initialized by .WindowsPlatform~init, not used by Linux & Darwin platforms.
::attribute default class
::attribute defaultBackground class -- 0 to 15
::attribute defaultForeground class -- 0 to 15

::method select class
    if \ .ooRexxShell~isInteractive then return -- to not put control characters in stdout/stderr
    if \ .ooRexxShell~showColor then return -- you don't want the colors
    use strict arg color, stream=.stdout
    select
        when .platform~is("windows") then do
            select
                when color~caselessEquals("default") then .platform~SetConsoleTextColor(self~default)
                when color~caselessEquals("bdefault") then do
                    if self~defaultForeground >= 8 then do
                         -- if already bold then use as-is
                        .platform~SetConsoleTextColor(self~default)
                    end
                    else do
                        -- use bold version of foreground (+8)
                        .platform~SetConsoleTextColor(self~defaultBackground * 16 + self~defaultForeground + 8)
                    end
                end
                when color~caselessEquals("black") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 0)
                when color~caselessEquals("bblack") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 8)
                when color~caselessEquals("red") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 4)
                when color~caselessEquals("bred") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 12)
                when color~caselessEquals("green") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 2)
                when color~caselessEquals("bgreen") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 10)
                when color~caselessEquals("yellow") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 6)
                when color~caselessEquals("byellow") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 14)
                when color~caselessEquals("blue") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 1)
                when color~caselessEquals("bblue") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 9)
                when color~caselessEquals("purple") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 5)
                when color~caselessEquals("bpurple") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 13)
                when color~caselessEquals("cyan") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 3)
                when color~caselessEquals("bcyan") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 11)
                when color~caselessEquals("white") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 7)
                when color~caselessEquals("bwhite") then .platform~SetConsoleTextColor(self~defaultBackground * 16 + 15)
                otherwise nop
            end
        end
        when .platform~is("linux") | .platform~is("macosx") | .platform~is("darwin") then do
            select
                when color~caselessEquals("default") then stream~charout(d2c(27)"[0m")
                when color~caselessEquals("bdefault") then stream~charout(d2c(27)"[1m")
                when color~caselessEquals("black") then stream~charout(d2c(27)"[0;30m")
                when color~caselessEquals("bblack") then stream~charout(d2c(27)"[1;30m")
                when color~caselessEquals("red") then stream~charout(d2c(27)"[0;31m")
                when color~caselessEquals("bred") then stream~charout(d2c(27)"[1;31m")
                when color~caselessEquals("green") then stream~charout(d2c(27)"[0;32m")
                when color~caselessEquals("bgreen") then stream~charout(d2c(27)"[1;32m")
                when color~caselessEquals("yellow") then stream~charout(d2c(27)"[0;33m")
                when color~caselessEquals("byellow") then stream~charout(d2c(27)"[1;33m")
                when color~caselessEquals("blue") then stream~charout(d2c(27)"[0;34m")
                when color~caselessEquals("bblue") then stream~charout(d2c(27)"[1;34m")
                when color~caselessEquals("purple") then stream~charout(d2c(27)"[0;35m")
                when color~caselessEquals("bpurple") then stream~charout(d2c(27)"[1;35m")
                when color~caselessEquals("cyan") then stream~charout(d2c(27)"[0;36m")
                when color~caselessEquals("bcyan") then stream~charout(d2c(27)"[1;36m")
                when color~caselessEquals("white") then stream~charout(d2c(27)"[0;37m")
                when color~caselessEquals("bwhite") then stream~charout(d2c(27)"[1;37m")
                otherwise nop
            end
            stream~flush -- to avoid filtering by filteringStream
        end
        otherwise nop
    end


-------------------------------------------------------------------------------
::class GCI -- http://rexx-gci.sourceforge.net/
-------------------------------------------------------------------------------
::attribute isInstalled class


::method init class
    self~isInstalled = .false
    if RxFuncadd(RxFuncDefine, "gci", "RxFuncDefine") <> 0 then return
    if RxFuncadd(GciFuncDrop, "gci", "GciFuncDrop") <> 0 then return
    if RxFuncadd(GciPrefixChar, "gci", "GciPrefixChar") <> 0 then return
    self~isInstalled = .true


/*
To compile gci-sources.1.1 for ooRexx under Win32, I had to create the file rexxsaa.h,
located above the GCI source directory, which contains:

#include "<your path to> rexx.h"
typedef void* PVOID ;
#define APIRET ULONG
typedef CONST char *PCSZ ;

Other change in gci_win32.def, to fix a syntax error:
4c4
< LIBRARY gci INITINSTANCE
---
> LIBRARY gci ; INITINSTANCE

Other change in gci_convert.win32.vc, to support 64 bits:
89c89,94
< #define GCI_STACK_ELEMENT unsigned
---
> #if defined(_M_IX86)
> #define GCI_STACK_ELEMENT unsigned __int32
> #else
> #define GCI_STACK_ELEMENT unsigned __int64
> #endif
>

*/


-------------------------------------------------------------------------------
::class platform
-------------------------------------------------------------------------------

-- Class level

::attribute current class -- the current platform is a singleton


::method initialize class -- init not supported (can't instantiate itself or subclass from init)
    use strict arg -- none
    parse source sysrx .
    select
        when sysrx~caselessAbbrev("windows") then self~current = .WindowsPlatform~new("windows")
        when sysrx~caselessAbbrev("aix") then self~current = self~new("aix")
        when sysrx~caselessAbbrev("sunos") then self~current = self~new("sunos")
        when sysrx~caselessAbbrev("linux") then self~current = self~new("linux")
        otherwise self~current = self~new(sysrx~word(1)~lower)
    end


::method is class
    use strict arg name
    return self~name~caselessEquals(name)


::method unknown class -- delegates to the singleton
    use strict arg msg, args
    forward to (self~current) message (msg) arguments (args)


-- Instance level

::attribute name


::method init
    use strict arg name
    self~name = name


::method which
    use strict arg filespec
    if filespec("location", filespec) == "" then return SysSearchPath("PATH", filespec)
    else if SysIsFile(filespec) then return filespec
    return ""


-------------------------------------------------------------------------------
::class WindowsPlatform subclass platform
-------------------------------------------------------------------------------

-- GCI type definitions
::constant LONG "integer32"         -- typedef long                LONG;
::constant SHORT "integer16"        -- typedef short               SHORT;
::constant CHAR "integer8"          -- typedef char                CHAR;
::constant ULONG "unsigned32"       -- typedef unsigned long       ULONG;
::constant USHORT "unsigned16"      -- typedef unsigned short      USHORT;
::constant UCHAR "unsigned8"        -- typedef unsigned char       UCHAR;
::constant DWORD "unsigned32"       -- typedef unsigned long       DWORD;
::constant DWORDLONG "unsigned64"   -- typedef unsigned __int64    DWORDLONG;
::constant BOOL "integer32"         -- typedef int                 BOOL;
::constant BOOLEAN "unsigned8"      -- typedef BYTE                BOOLEAN;
::constant BYTE "unsigned8"         -- typedef unsigned char       BYTE;
::constant WORD "unsigned16"        -- typedef unsigned short      WORD;
::constant FLOAT "float32"          -- typedef float               FLOAT;
::constant INT "integer32"          -- typedef int                 INT;
::constant UINT "unsigned32"        -- typedef unsigned int        UINT;
::constant HANDLE "integer"         -- typedef void                *HANDLE; -- todo: must be integer64 under win64, is it managed by GCI ?
::constant STRUCT "container"
::constant PSTRUCT "indirect container"


::method init
    forward class (super) continue

    -- This part was in init at class level, but I realized that it was executed whatever the platform.
    -- Better to move the declaration of the FFI here.
    if .GCI~isInstalled then do
        self~class~defineGetConsoleScreenBufferInfo
        self~class~defineSetConsoleTextAttribute
        self~class~defineGetStdHandle
    end

    self~class~current = self -- normally you never call directly a method of .WindowsPlatform, but just in case...
    -- Default background & foreground colors
    wAttributes = 0
    consoleInfo = self~GetConsoleInfo
    if consoleInfo <> .nil then wAttributes = consoleInfo["WATTRIBUTES"]
    colorAttributes = wAttributes // 255 -- first byte
    .Color~default = colorAttributes
    .Color~defaultBackground = colorAttributes % 16 -- last 4 bits
    .Color~defaultForeground = colorAttributes // 16 -- first 4 bits


::method which
    -- The order of precedence in locating executable files is given by the PATHEXT environment variable.
    use strict arg filespec
    pathext = value("PATHEXT",, "ENVIRONMENT")~translate(" ", ";")
    if filespec("location", filespec) == "" then do
        if filespec("name", filespec)~pos(".") == 0 then do
            do while pathext <> ""
                parse var pathext ext pathext
                which = SysSearchPath("PATH", filespec || ext)
                if which <> "" then return which
            end
        end
        which = SysSearchPath("PATH", filespec)
        if which <> "" then return which
    end
    else do
        if filespec("name", filespec)~pos(".") == 0 then do
            do while pathext <> ""
                parse var pathext ext pathext
                if SysIsFile(filespec || ext) then return filespec || ext
            end
        end
        if SysIsFile(filespec) then return filespec
    end
    return ""


::method subsystem
    -- Return the id of the subsystem needed to execute the executable.
    -- Remember: GetBinaryType does not return this information.
    -- Rexx adaptation of:
    -- http://support.microsoft.com/?scid=kb%3Ben-us%3B90493&x=13&y=16
    /*
    #define IMAGE_SUBSYSTEM_UNKNOWN              0   // Unknown subsystem.
    #define IMAGE_SUBSYSTEM_NATIVE               1   // Image doesn't require a subsystem.
    #define IMAGE_SUBSYSTEM_WINDOWS_GUI          2   // Image runs in the Windows GUI subsystem.
    #define IMAGE_SUBSYSTEM_WINDOWS_CUI          3   // Image runs in the Windows character subsystem.
    ...
    More values defined in winnt.h
    */
    if .ooRexxShell~debug then trace i ; else trace off
    use strict arg exename
    signal on notready
    stream = .Stream~new(exename)
    if stream~query("size") == 0 then do
        -- this test is mandatory, because stream~open raises Error 93.938:  Method argument 1 must have a string value
        -- when an empty file is opened in binary mode, without specifying "Reclength <length>"
        -- Sounds like a bug...
        return .false
    end
    if stream~open("read shared binary") <> "READY:" then return 0
    e_magic = stream~charIn(1, 2)
    if e_magic <> "4D5A"x then return 0 -- MZ
    e_lfnanew = stream~charIn(61, 4)
    stream~seek(littleendian2integer32(e_lfnanew) + 1)
    ntSignature = stream~charIn(, 4)
    if ntSignature <> "50450000"x then return 0 -- PE\0\0
    stream~seek("+88")
    subsystem = stream~charIn(, 2)
    return littleendian2integer16(subsystem)
    notready:
    return .false


::constant STD_INPUT_HANDLE -10
::constant STD_OUTPUT_HANDLE -11
::constant STD_ERROR_HANDLE -12
::constant INVALID_HANDLE_VALUE -1

::method defineGetStdHandle class private
    /*
    HANDLE WINAPI GetStdHandle(
      __in  DWORD nStdHandle
    );
    */
    stem.calltype = "stdcall"
    stem.0 = 1
    stem.1.type = self~DWORD
    stem.return.type = self~HANDLE
    return RxFuncDefine("GetStdHandle", "kernel32", "GetStdHandle", "stem") == 0 -- return .true if no error


::method GetStdHandle private
    use strict arg deviceId
    stem.1.value = unsigned32(deviceId) -- GCI complains when passing a negative value...
    call GetStdHandle "stem"
    return stem.return.value


::method defineGetConsoleScreenBufferInfo class private
    /*
    typedef struct _COORD {
      SHORT X;
      SHORT Y;
    } COORD, *PCOORD;

    typedef struct _SMALL_RECT {
      SHORT Left;
      SHORT Top;
      SHORT Right;
      SHORT Bottom;
    } SMALL_RECT;

    typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
      COORD      dwSize;
      COORD      dwCursorPosition;
      WORD       wAttributes;
      SMALL_RECT srWindow;
      COORD      dwMaximumWindowSize;
    } CONSOLE_SCREEN_BUFFER_INFO;

    BOOL WINAPI GetConsoleScreenBufferInfo(
      _In_  HANDLE                      hConsoleOutput,
      _Out_ PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo
    );
    */
    stem.calltype = "stdcall"
    stem.0 = 2

    stem.1.type = self~HANDLE

    stem.2.type = self~PSTRUCT
    stem.2.0 = 5

    stem.2.1.type = self~STRUCT     -- COORD dwSize;
    stem.2.1.0 = 2
    stem.2.1.1.type = self~SHORT    --      SHORT X;
    stem.2.1.2.type = self~SHORT    --      SHORT Y;

    stem.2.2.type = self~STRUCT     -- COORD dwCursorPosition;
    stem.2.2.0 = 2
    stem.2.2.1.type = self~SHORT    --      SHORT X;
    stem.2.2.2.type = self~SHORT    --      SHORT Y;

    stem.2.3.type = self~WORD       -- WORD wAttributes;

    stem.2.4.type = self~STRUCT     -- SMALL_RECT srWindow;
    stem.2.4.0 = 4
    stem.2.4.1.type = self~SHORT    --      SHORT Left;
    stem.2.4.2.type = self~SHORT    --      SHORT Top;
    stem.2.4.3.type = self~SHORT    --      SHORT Right;
    stem.2.4.4.type = self~SHORT    --      SHORT Bottom;

    stem.2.5.type = self~STRUCT     -- COORD dwMaximumWindowSize;
    stem.2.5.0 = 2
    stem.2.5.1.type = self~SHORT    --      SHORT X;
    stem.2.5.2.type = self~SHORT    --      SHORT Y;

    stem.return.type = self~BOOL

    return RxFuncDefine("GetConsoleScreenBufferInfo", "kernel32", "GetConsoleScreenBufferInfo", "stem") == 0 -- return .true if no error


::method GetConsoleScreenBufferInfo private
    use strict arg consoleHandle
    stem.1.value = consoleHandle

    stem.2.value = 5

    stem.2.1.value = 2
    stem.2.1.1.value = 0            -- dwSize.X
    stem.2.1.2.value = 0            -- dwSize.Y

    stem.2.2.value = 2
    stem.2.2.1.value = 0            -- dwCursorPosition.X
    stem.2.2.2.value = 0            -- dwCursorPosition.Y

    stem.2.3.value = 0              -- wAttributes

    stem.2.4.value = 4
    stem.2.4.1.value = 0            -- srWindow.Left
    stem.2.4.2.value = 0            -- srWindow.Top
    stem.2.4.3.value = 0            -- srWindow.Right
    stem.2.4.4.value = 0            -- srWindow.Bottom

    stem.2.5.value = 2
    stem.2.5.1.value = 0            -- dwMaximumWindowSize.X
    stem.2.5.2.value = 0            -- dwMaximumWindowSize.Y

    call GetConsoleScreenBufferInfo "stem"

    info.isValid = stem.return.value
    info.dwSize.X = stem.2.1.1.value
    info.dwSize.Y = stem.2.1.2.value
    info.dwCursorPosition.X = stem.2.2.1.value
    info.dwCursorPosition.Y = stem.2.2.2.value
    info.wAttributes = stem.2.3.value
    info.srWindow.Left = stem.2.4.1.value
    info.srWindow.Top = stem.2.4.2.value
    info.srWindow.Right = stem.2.4.3.value
    info.srWindow.Bottom = stem.2.4.4.value
    info.dwMaximumWindowSize.X = stem.2.5.1.value
    info.dwMaximumWindowSize.Y = stem.2.5.2.value

    return info.


::method GetConsoleInfo
    use strict arg -- none
    signal on syntax -- trap unregistered GCI functions
    consoleHandle = self~GetStdHandle(self~STD_OUTPUT_HANDLE)
    if consoleHandle == self~INVALID_HANDLE_VALUE then return .nil
    return self~GetConsoleScreenBufferInfo(consoleHandle)
    syntax:
    return .nil


::method defineSetConsoleTextAttribute class private
    /*
    BOOL WINAPI SetConsoleTextAttribute(
      __in  HANDLE hConsoleOutput,
      __in  WORD wAttributes
    );
    */
    stem.calltype = "stdcall"
    stem.0 = 2
    stem.1.type = self~HANDLE
    stem.2.type = self~WORD
    stem.return.type = self~BOOL
    return RxFuncDefine("SetConsoleTextAttribute", "kernel32", "SetConsoleTextAttribute", "stem") == 0 -- return .true if no error


::method SetConsoleTextAttribute private
    use strict arg consoleHandle, characterAttributes
    stem.1.value = consoleHandle
    stem.2.value = characterAttributes
    call SetConsoleTextAttribute "stem"
    return stem.return.value


::method SetConsoleTextColor
    use strict arg colorNumber
    signal on syntax -- trap unregistered GCI functions
    consoleHandle = self~GetStdHandle(self~STD_OUTPUT_HANDLE)
    if consoleHandle == self~INVALID_HANDLE_VALUE then return .false
    self~SetConsoleTextAttribute(consoleHandle, colorNumber)
    return result <> 0 -- return .true if no error
    syntax:
    return .false


-------------------------------------------------------------------------------
::class Argument
-------------------------------------------------------------------------------

::attribute container           -- the string container from which the string value has been extracted
::attribute containerEnd        -- index of last character in container
::attribute containerStart      -- index of first character in container
::attribute quotedFlags         -- string of booleans : "1" when the corresponding character in string is part of a chunk surrounded by quotes
::attribute string              -- the string value of the argument (the quotes are removed)


::method init
    expose container containerEnd containerStart quotedFlags string
    use strict arg string, quotedFlags="", container="", containerStart=0, containerEnd=0


::method left
    -- Extract a left substring while keeping the contextual informations
    copy = self~copy
    forward to(self~string) continue
    copy~string = result
    forward to(self~quotedFlags) continue
    copy~quotedFlags = result
    return copy


::method right
    -- Extract a right substring while keeping the contextual informations
    copy = self~copy
    forward to(self~string) continue
    copy~string = result
    forward to(self~quotedFlags) continue
    copy~quotedFlags = result
    return copy


::method substr
    -- Extract a substring while keeping the contextual informations
    copy = self~copy
    forward to(self~string) continue
    copy~string = result
    forward to(self~quotedFlags) continue
    copy~quotedFlags = result
    return copy


::routine string2args public
    -- Converts a string to an array of arguments.
    -- Arguments are separated by whitespaces (anything <= 32) and can be quoted.
    -- An argument can be made of several quoted chunks. Ex : aa"bb"cc"dd"ee
    -- If withInfos == .false then the result is an array of String.
    -- If withInfos == .true then the result is an array of Argument.

    -- Ex:
    -- 11111111111111111111111111 222222222222222 333333333333333333333
    -- "hello "John" how are you" good" bye "John "my name is ""BOND"""
    -- 0000000001111111111222222222233333333334444444444555555555566666
    -- 1234567890123456789012345678901234567890123456789012345678901234
    -- arg1 = |hello John how are you|      containerStart = 01      containerEnd = 26      quotedFlags = 1111110000111111111111
    -- arg2 = |good bye John|               containerStart = 28      containerEnd = 42      quotedFlags = 0000111110000
    -- arg3 = |my name is "BOND"|           containerStart = 44      containerEnd = 64      quotedFlags = 11111111111111111

    use strict arg string, withInfos=.false

    args = .Array~new
    i = 1

    loop label arguments
        -- Skip whitespaces
        loop
            if i > string~length then return args
            if string~subchar(i) > " " then leave
            i += 1
        end

        current = .MutableBuffer~new
        quotedFlags = .MutableBuffer~new
        firstCharPosition = i
        loop label current_argument
            c = string~subchar(i)
            quote = ""
            if c == '"' | c == "'" then quote = c
            if quote <> "" then do
                -- Chunk surrounded by quotes: whitespaces are kept, double occurrence of quotes are replaced by a single embedded quote
                loop label quoted_chunk
                    i += 1
                    if i > string~length then return args~~append(result())
                    select
                        when string~subchar(i) == quote & string~subchar(i+1) == quote then do
                            current~append(quote)
                            quotedFlags~append("1")
                            i += 1
                        end
                        when string~subchar(i) == quote then do
                            i += 1
                            leave quoted_chunk
                        end
                        otherwise do
                            current~append(string~subchar(i))
                            quotedFlags~append("1")
                        end
                    end
                end quoted_chunk
            end
            if string~subchar(i) <= " " then do
                args~append(result())
                leave current_argument
            end
            -- Chunk not surrounded by quotes: ends when a whitespace or quote is reached
            loop
                if i > string~length then return args~~append(result())
                c = string~subchar(i)
                if c <= " " | c == '"' | c == "'" then leave
                current~append(c)
                quotedFlags~append("0")
                i += 1
            end
        end current_argument
    end arguments
    return args

    result:
        if withInfos then return .Argument~new(/*string*/         current~string,,
                                               /*quotedFlags*/    quotedFlags~string,,
                                               /*container*/      string,,
                                               /*containerStart*/ firstCharPosition,,
                                               /*containerEnd*/   i-1)
        else return current~string


-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

::routine quoted public
    -- Remember: keep it, because the method .String~quoted is NOT available with standard ooRexx.
    use strict arg string, quote='"'
    return quote || string || quote


::routine unquoted public
    -- Remember: keep it, because the method .String~unquoted is NOT available with standard ooRexx.
    use strict arg string, quote='"'
    if string~left(1) == quote & string~right(1) == quote then
        return string~substr(2, string~length - 2)
    else
        return string


::routine paren public
    use strict arg string
    return "(" || string || ")"


::routine unsigned32 public
    use strict arg number
    numeric digits 10
    if number >= 0 then return number
    return 4294967296 + number


::routine littleendian2integer16 public
    use strict arg string
    byte2 = string~subchar(2)~c2d
    byte1 = string~subchar(1)~c2d
    integer16 = 256 * byte2 + byte1
    if byte2 >= 128 then return integer16 - 65536
    return integer16


::routine littleendian2integer32 public
    use strict arg string
    numeric digits 10
    byte4 = string~subchar(4)~c2d
    byte3 = string~subchar(3)~c2d
    byte2 = string~subchar(2)~c2d
    byte1 = string~subchar(1)~c2d
    integer32 = 16777216 * byte4 + 65536 * byte3 + 256 * byte2 + byte1
    if byte4 >= 128 then return integer32 - 4294967296
    return integer32


-------------------------------------------------------------------------------
::requires "rxregexp.cls"
