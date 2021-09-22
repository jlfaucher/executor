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
- the system address (cmd under Windows, sh under Linux & MacOs)
- bash, zsh
- PowerShell core (pwsh)
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
-- Unix: support aliases (run in interactive mode)
.ooRexxShell~securityManager = .SecurityManager~new -- make it accessible from command line
shell = .context~package~findRoutine("SHELL")
shell~setSecurityManager(.ooRexxShell~securityManager)

-- In case of error, must end any running coactivity, otherwise the program doesn't terminate
signal on any name error

.ooRexxShell~isInteractive = (arg(1) == "" & lines() == 0) -- Example of not interactive session: echo dir | oorexxshell

-- Typical usage: when non-interactive demo, we want to show the initialization
.ooRexxShell~showInitialization = .ooRexxShell~isInteractive | arg(1)~caselessEquals("--showInitialization")

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
    .ooRexxShell~sayCondition(condition)
    .ooRexxShell~sayError(condition~traceback~makearray~tostring)
end
signal finalize


::requires "extension/stringChunk.cls"

-------------------------------------------------------------------------------
-- ::options trace i

::routine SHELL
-- We enter in the routine which manages the interpret instruction.
-- To avoid any accidental overwriting of ooRexxShell's variable by interpret,
-- all the variables in this routine and its internal routines are attributes of
-- the ooRexxShell class. If you choose to modify an attribute of ooRexxShell
-- from the command line, it's because you want it.
use strict arg .ooRexxShell~initialArgument, .ooRexxShell~initialAddress

if .ooRexxShell~isInteractive then do
    .ooRexxShell~readline = .true -- history, tab completion
    .ooRexxShell~showInfos = .true -- infos displayed after each line interpretation
    .oorexxShell~showColor = .true
end
else do
    .ooRexxShell~readline = .false -- basic "parse pull"
    .ooRexxShell~showInfos = .false -- don't display infos after each line interpretation
    .ooRexxShell~showColor = .false -- to not put control characters in stdout/stderr
end

if .ooRexxShell~showInitialization then do
    -- Typical usage: when demo, we want to show the initialization with colors
    .ooRexxShell~showColor = .true
end

-- Deactivate the realine mode when Windows, because the history is not managed correctly.
-- We lose the doskey macros and the filename autocompletion. Too bad...
if .platform~is("windows") then .ooRexxShell~readline = .false

-- Deactivate the readline mode when the environment variable OOREXXSHELL_RLWRAP is defined.
if value("OOREXXSHELL_RLWRAP", , "ENVIRONMENT") <> "" then .ooRexxShell~readline = .false

.ooRexxShell~defaultColor = "default"
.ooRexxShell~errorColor = "bred"
.ooRexxShell~infoColor = "bgreen"
.ooRexxShell~commentColor = "blue"
.ooRexxShell~promptColor = "byellow"
.ooRexxShell~traceColor = "bpurple"
if .platform~is("windows") & .color~defaultBackground == 15 /*white*/ then do
    .ooRexxShell~infoColor = "green"
    .ooRexxShell~promptColor = "yellow"
end

.ooRexxShell~readlineAddress = readlineAddress()
.ooRexxShell~systemAddress = systemAddress()

-- The index is always converted to uppercase, the item is used for display (list of possible values, prompt).
.ooRexxShell~interpreters = .Directory~new
.ooRexxShell~interpreters~setEntry("oorexx", "ooRexx")
.ooRexxShell~interpreters~setEntry(.ooRexxShell~initialAddress, .ooRexxShell~initialAddress)
.ooRexxShell~interpreters~setEntry(.ooRexxShell~systemAddress, .ooRexxShell~systemAddress)
.ooRexxShell~interpreters~setEntry(address(), address()) -- maybe the same as systemAddress, maybe not
.ooRexxShell~interpreters~setEntry("system", .ooRexxShell~systemAddress) -- an alias for .ooRexxShell~systemAddress)
.ooRexxShell~interpreters~setEntry("cmd", .ooRexxShell~systemAddress) -- an alias for .ooRexxShell~systemAddress)
.ooRexxShell~interpreters~setEntry("command", .ooRexxShell~systemAddress) -- an alias for .ooRexxShell~systemAddress)
if .platform~is("windows") then do
    .ooRexxShell~interpreters~setEntry("pwsh", "pwsh")
end
if \.platform~is("windows") then do
    do shell over .stream~new("/etc/shells")~arrayin
        shell = shell~strip
        if shell~left(1) == "#" then iterate
        lastSlashPos = shell~lastpos("/")
        if lastSlashPos == 0 then iterate
        shell = shell~substr(lastSlashPos + 1)
        if shell <> "" then .ooRexxShell~interpreters~setEntry(shell, shell)
    end
end

/*
builder/scripts/setenv-oorexx : declare the variable $rexx_environment, dump all the aliases in the file $rexx_environment
~/.bashrc : declares the variable $BASH_ENV and $ENV = ~/.bash_env
.bash_env : defines some aliases, calls $rexx_environment (id defined) which is a file defining more aliases (see builder/scripts/setenv-oorexx)
oorexxshell.rex: expands the aliases (run in interactive mode)
*/

call loadOptionalComponents

-- "a command"~pipe(.system) not caught by the security manager attached to SHELL, because .System is implemented in a different package.
Class_System = .context~package~findclass("system")
if .nil <> Class_System then do
    Method_System_Process = Class_System~method("process")
    if .nil <> Method_System_Process then do
        Method_System_Process~package~setSecurityManager(.ooRexxShell~securityManager)
    end
end

address value .ooRexxShell~initialAddress
.ooRexxShell~interpreter = .ooRexxShell~interpreters~entry("oorexx")

.ooRexxShell~queueName = rxqueue("create") -- public input queue
.ooRexxShell~queueInitialName = rxqueue("set", .ooRexxShell~queueName)

call checkReadlineCapability

select
    when .ooRexxShell~showInitialization then do
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

        -- Will be used by .ooRexxShell~sleep to test if the previous command was an end of multline commment.
        -- The duration of the pause will be proportional to the number of characters in the multiline comment.
        -- Also used by readline to decide if the history file must be updated (a repeated input is stored only once).
        .ooRexxShell~inputrxPrevious = .ooRexxShell~inputrx
        .ooRexxShell~maybeCommandPrevious = .ooRexxShell~maybeCommand

        .ooRexxShell~prompt = prompt(address())
        .ooRexxShell~inputrx = readline(.ooRexxShell~prompt)
        .ooRexxShell~input = .ooRexxShell~inputrx~strip -- remember: don't apply ~space here!

        .ooRexxShell~RC = 0

        -- If the input starts with a space then no command recognition.
        .ooRexxShell~maybeCommand = .ooRexxShell~inputrx~left(1, ".") <> " "
        select label analyze_command
            when .ooRexxShell~inputrx == "*/" then
                .ooRexxShell~showComment = .false
            when .ooRexxShell~showComment then -- No command is executed in showComment mode, even exit is not recognized
                nop
            when .ooRexxShell~inputrx == "/*" then do
                .ooRexxShell~showComment = .true
                .ooRexxShell~countCommentLines = 0
                .ooRexxShell~countCommentChars = 0
            end

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~word(1)~right(1) == ":" & .ooRexxShell~input~words == 1 & \isDriveLetter(.ooRexxShell~input~word(1)) then do
                -- label (other than drive letter)
                if (.ooRexxShell~gotoLabel":")~caseLessEquals(.ooRexxShell~input~word(1)) then
                    .ooRexxShell~gotoLabel = "" -- We have reached the label, we can resume the normal interpretation
            end
            when .ooRexxShell~gotoLabel <> "" then -- No command is executed until we reach this label
                nop

            when .ooRexxShell~input == "" then
                nop

            when .ooRexxShell~inputrx~left(2) == "--" then
                nop

            when .ooRexxShell~inputrx~left(1) == "?" then
                .ooRexxShell~help(.context, .ooRexxShell~inputrx~substr(2))

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("color off") then
                .ooRexxShell~showColor = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("color on") then
                .ooRexxShell~showColor = .true

            when .ooRexxShell~maybeCommand &.ooRexxShell~input~space~caselessEquals("debug off") then
                .ooRexxShell~debug = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("debug on") then
                .ooRexxShell~debug = .true

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("demo off") then
                .ooRexxShell~demo = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("demo on") then
                .ooRexxShell~demo = .true

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("demo fast") then
                .ooRexxShell~demoFast = .true

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~caselessEquals("exit") then
                exit

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~word(1)~caselessEquals("goto") then
                .ooRexxShell~goto(.ooRexxShell~input)

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("infos off") then
                .ooRexxShell~showInfos = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("infos on") then
                .ooRexxShell~showInfos = .true
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("infos next") then
                .ooRexxShell~showInfosNext = .true

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("prompt directory off") then
                .ooRexxShell~promptDirectory = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("prompt directory on") then
                .ooRexxShell~promptDirectory = .true

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("readline off") then
                .ooRexxShell~readline = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("readline on") then do
                .ooRexxShell~readline = .true
                call checkReadlineCapability
            end

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~caselessEquals("reload") then do
                -- Often, I modify some packages that are loaded by ooRexxShell at startup.
                -- To benefit from the changes, I have to reload the components.
                -- Can't do that without leaving the interpreter (to my knowledge).
                .ooRexxShell~RC = .ooRexxShell~reload
                exit
            end

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("security off") then
                .ooRexxShell~securityManager~isEnabledByUser = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("security on") then
                .ooRexxShell~securityManager~isEnabledByUser = .true

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~word(1)~caselessEquals("sleep") then
                .ooRexxShell~sleep(.ooRexxShell~input)

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessAbbrev("trace off") then
                .ooRexxShell~trace(.false, .ooRexxShell~input)
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessAbbrev("trace on") then
                .ooRexxShell~trace(.true, .ooRexxShell~input)

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessAbbrev("trap off") then
                .ooRexxShell~trap(.false, .ooRexxShell~input)
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessAbbrev("trap on") then
                .ooRexxShell~trap(.true, .ooRexxShell~input)

            when .ooRexxShell~maybeCommand & .ooRexxShell~interpreters~hasEntry(.ooRexxShell~input) then do
                -- Change the default interpreter
                .ooRexxShell~interpreter = .ooRexxShell~interpreters~entry(.ooRexxShell~input)
            end

            when .ooRexxShell~maybeCommand & .ooRexxShell~interpreters~hasEntry(.ooRexxShell~input~word(1)) then do
                -- The line starts with an interpreter name: use it instead of the default interpreter
                .ooRexxShell~commandInterpreter = .ooRexxShell~interpreters~entry(.ooRexxShell~input~word(1))
                .ooRexxShell~command = .ooRexxShell~input~substr(.ooRexxShell~input~wordIndex(2))
                signal dispatchCommand -- don't call, because some ooRexx interpreter informations would be saved/restored
            end

            otherwise do
                -- Interpret the line with the default interpreter
                .ooRexxShell~commandInterpreter = .ooRexxShell~interpreter
                .ooRexxShell~command = .ooRexxShell~input
                signal dispatchCommand -- don't call, because some ooRexx interpreter informations would be saved/restored
            end
        end analyze_command

        CONTINUE_REPL:
        if var("RC") then .ooRexxShell~RC = RC
        if \.ooRexxShell~isInteractive & queued() == 0 & lines() == 0 then return -- When non-interactive, stop loop when queue is empty and default input stream is empty.
    signal REPL


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
    call rxqueue "set", .ooRexxShell~queueName -- Back to the public ooRexxShell input queue
    if .ooRexxShell~error then .ooRexxShell~sayCondition(condition("O"))
    if RC <> 0 & \.ooRexxShell~error then do
        -- RC can be set by interpretCommand or by addressCommand
        -- Not displayed in case of error, because the integer portion of Code already provides the same value as RC
        .ooRexxShell~sayError("RC=" RC)
    end
    if RC <> 0 | .ooRexxShell~error then do
        if \.ooRexxShell~demo then .ooRexxShell~sayInfo(.ooRexxShell~command)
    end
    if .ooRexxShell~showInfos | .ooRexxShell~showInfosNext then do
        .ooRexxShell~sayInfo("Duration:" time('e')) -- elapsed duration
        if .ooRexxShell~isExtended, .Coactivity~count <> 0 then .ooRexxShell~sayInfo("#Coactivities:" .Coactivity~count) -- counter of coactivities
        .ooRexxShell~showInfosNext = .false
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
        .ooRexxShell~sayTrace("[interpret]" .ooRexxShell~command)
    end
    if .ooRexxShell~hasLastResult then result = .ooRexxShell~lastResult -- restore previous result
                                  else drop result
    if .ooRexxShell~trapLostdigits then signal on lostdigits
    if .ooRexxShell~trapNoMethod then signal on noMethod
    if .ooRexxShell~trapNoString then signal on noString
    if .ooRexxShell~trapNoValue then signal on noValue
    if .ooRexxShell~trapSyntax then signal on syntax
    interpret .ooRexxShell~command
    after_interpret:
    signal off lostdigits
    signal off noMethod
    signal off noString
    signal off noValue
    signal off syntax
    if var("result") then .ooRexxShell~lastResult = result -- backup current result
                     else .ooRexxShell~dropLastResult
    signal return_to_dispatchCommand

    lostdigits:
    noMethod:
    noString:
    noValue:
    syntax:
    .ooRexxShell~error = .true
    signal after_interpret -- to reset the trap errors


-------------------------------------------------------------------------------
-- Remember: don't implement that as a procedure or routine or method !
-- Moreover don't call it, you must jump to (signal) it...
addressCommand:
    if .ooRexxShell~traceDispatchCommand then do
        .ooRexxShell~sayTrace("[address" .ooRexxShell~commandInterpreter"]" .ooRexxShell~command)
    end
    address value .ooRexxShell~commandInterpreter
    (.ooRexxShell~command)
    address -- restore previous
    signal return_to_dispatchCommand


-------------------------------------------------------------------------------
Helpers
-------------------------------------------------------------------------------

::routine intro
    parse version version
    .ooRexxShell~sayInfo
    .ooRexxShell~sayInfo(version)
    .ooRexxShell~sayInfo("Input queue name:" .ooRexxShell~queueName)
    return


-------------------------------------------------------------------------------
::routine promptDirectory
    use strict arg
    .color~select(.ooRexxShell~promptColor)
    say
    if .ooRexxShell~promptDirectory then say directory()
    .color~select(.ooRexxShell~defaultColor)

::routine prompt
    use strict arg currentAddress
    -- No longer display the prompt, return it and let readline display it
    prompt = .ooRexxShell~interpreter
    if .ooRexxShell~interpreter~caselessEquals("ooRexx") then prompt ||= "["currentAddress"]" ; else prompt ||= "[ooRexx]"
    if .ooRexxShell~securityManager~isEnabledByUser then prompt ||= "> " ; else prompt ||= "!> "
    return prompt


-------------------------------------------------------------------------------
::routine checkReadlineCapability
    -- Bypass a bug in official ooRexx 4 which delegates to system() when the passed address is bash.
    -- The bug is that system() delegates to /bin/sh, and should be called only when the passed address is sh.
    -- Because of this bug, the readline procedure (which depends on bash) is not working and must be deactivated.
    if .ooRexxShell~isInteractive, .ooRexxShell~readlineAddress~caselessEquals("bash") then do
        address value .ooRexxShell~readlineAddress
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
::routine readline
    use strict arg prompt
    inputrx = ""
    RC = 0

    if .ooRexxShell~traceReadline then do
        .ooRexxShell~sayTrace("[readline] queued()=" queued())
        .ooRexxShell~sayTrace("[readline] lines()=" lines())
        .ooRexxShell~sayTrace("[readline] .ooRexxShell~readline=" .ooRexxShell~readline)
    end

    history = .stream~new(.ooRexxShell~historyFile)
    if history~query("size")0 = 0 then do
        -- Create the history file if not existent (size = '') or empty (size = 0).
        -- The line "oorexx" is written because of this known problem:
        -- https://superuser.com/questions/942009/bash-history-a-not-writing-unless-histfile-already-has-text
        -- My Mac has an old version of bash, and this problem occurs.
        history~lineout("oorexx")
        history~flush
    end

    select
        when .ooRexxShell~demo then do
            inputrx = readline_for_demo(prompt)
            -- don't update history file
        end
        when queued() == 0 & lines() == 0 & .ooRexxShell~readlineAddress~caselessEquals("cmd") & .ooRexxShell~readline then do
            inputrx = readline_with_cmd(prompt)
            if inputrx <> "", inputrx <> .ooRexxShell~inputrxPrevious then history~lineout(inputrx)
        end
        when queued() == 0 & lines() == 0 & .ooRexxShell~readlineAddress~caselessEquals("bash") & .ooRexxShell~readline then do
            inputrx = readline_with_bash(prompt)
            if inputrx <> "", inputrx <> .ooRexxShell~inputrxPrevious then history~lineout(inputrx)
        end
        otherwise do
            if .ooRexxShell~isInteractive then do
                call promptDirectory
                call charout , prompt
            end
            queue_or_stdin = queued() <> 0 | lines() <> 0
            parse pull inputrx -- Input queue or standard input or keyboard.
            if .ooRexxShell~isInteractive & queue_or_stdin then say inputrx -- display the input only if coming from queue or from stdin
            if inputrx <> "", inputrx <> .ooRexxShell~inputrxPrevious then history~lineout(inputrx)
        end
    end

    history~close

    if .ooRexxShell~traceReadline then do
        .ooRexxShell~sayTrace("[readline] inputrx=" inputrx)
    end

    if RC <> 0 then do
        .ooRexxShell~readline = .false
        .ooRexxShell~sayError("[readline] RC="RC)
        .ooRexxShell~sayError("[readline] Something is not working, fallback to raw input (no more history, no more globbing)")
    end

    return inputrx


    ---------------------------------------------------------------------------
    readline_for_demo: procedure expose RC
        use strict arg prompt
        -- Don't display the prompt yet
        -- because an empty input and the comments are displayed without prompt,
        -- and because some commands are not displayed.
        parse pull inputrx -- Input queue or standard input or keyboard.
        -- If the input starts with a space then no command recognition.
        maybeCommand = inputrx~left(1, ".") <> " "
        input = inputrx~space
        select
            when inputrx == "/*" then nop
            when inputrx == "*/" then nop
            when maybeCommand & input~caselessEquals("demo off") then nop
            when maybeCommand & input~caselessEquals("demo on") then nop
            when maybeCommand & input~word(1)~caselessEquals("goto") then nop
            when maybeCommand & input~caselessEquals("infos next") then nop
            when maybeCommand & input~caselessEquals("prompt directory off") then nop
            when maybeCommand & input~caselessEquals("prompt directory on") then nop
            when maybeCommand & input~word(1)~right(1) == ":" & input~words == 1 & \isDriveLetter(input~word(1)) then nop -- label (when not drive letter)
            when .ooRexxShell~gotoLabel <> "" then nop
            when maybeCommand & input~word(1)~caselessEquals("sleep") then do
                if .ooRexxShell~maybeCommand & .ooRexxShell~input~word(1)~caseLessEquals("sleep") then nop -- prompt already displayed
                else if input~caselessPos("no prompt") <> 0 then nop -- don't display the prompt
                else do
                    call promptDirectory
                    call charout , prompt
                end
            end
            when .ooRexxShell~showComment then .ooRexxShell~sayComment(inputrx)
            when inputrx~left(2) == "--" then .ooRexxShell~sayComment(inputrx)
            when input == "" then say
            otherwise do
                if .ooRexxShell~maybeCommand & .ooRexxShell~input~word(1)~caseLessEquals("sleep") then nop -- prompt already displayed
                else do
                    call promptDirectory
                    call charout , prompt
                end
                .ooRexxShell~charoutSlowly(inputrx)
                .ooRexxShell~SysSleep(2) -- Give time to read before "pressing enter"
                say -- "press enter"
            end
        end
        return inputrx


    ---------------------------------------------------------------------------
    readline_with_cmd: procedure expose RC
        -- This doesn't work correctly (loss of history). Readline no longer activated by default under Windows.
        --
        -- I want the doskey macros and filename tab autocompletion... Delegates the input to cmd.
        -- HKEY_CURRENT_USER/Software/Microsoft/Command Processor/CompletionChar = 9
        -- Tried to call clink, but it doesn't solve the problem of history lost.
        --    "(clink inject >nul 2>&1) &",
        use strict arg prompt
        call promptDirectory
        address value .ooRexxShell~readlineAddress
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
        return inputrx


    ---------------------------------------------------------------------------
    readline_with_bash: procedure expose RC
        -- I want all the features of readline when editing my command line (history, tab completion, ...)
        -- Two strings are pushed to rxqueue in one line, separated with \000 (NUL) :
        -- one generated by the internal command 'set', which manages the escaped characters.
        -- one generated by the internal command 'print', to get the input as-is.
        -- Temporary: A third string is pushed to rxqueue, to let me see what I get with printf %q
        use strict arg prompt
        call promptDirectory
        address value .ooRexxShell~readlineAddress
            "set -o noglob ;",
            "HISTFILE=".ooRexxShell~historyFile" ;",
            "history -r ;",
            "IFS= read -r -e -p "quoted(prompt)" inputrx ;",
            "history -s -- ""$inputrx"" ;",
            /* "history -a ;" */ ,
            "(export LC_ALL=C; set | grep ^inputrx= | tr '\n' '\000' ; printf ""%s\000"" ""$inputrx"" ; printf ""%q"" ""$inputrx"") | rxqueue "quoted(.ooRexxShell~queueName)" /lifo"
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

                    -- Clean inputrx3: since all spaces are prefixed with \, the interpreter name is not recognized
                    -- It's ok to systematically remove the \ at the end of the first word
                    parse var inputrx3 word1 rest
                    if word1~right(1) == "\" then inputrx3 = word1~left(word1~length - 1) rest

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
                    maybeCommand = inputrx~left(1, ".") <> " "
                    if maybeCommand & .ooRexxShell~interpreters~hasEntry(inputrx1~word(1)) then interpreter = .ooRexxShell~interpreters~entry(inputrx1~word(1)) -- temporary interpreter
                    if interpreter~caselessEquals("bash") then inputrx = inputrx1
                    else if interpreter~caselessEquals("sh") then inputrx = inputrx1
                    else if interpreter~caselessEquals("zsh") then inputrx = inputrx1
                    else inputrx = inputrx2
                    -- if no transformation foreseen (because the security manager is not enabled)
                    if \ .ooRexxShell~securityManager~isEnabledByUser then inputrx = inputrx2
                end
                else do
                    -- Since the line read from the queue does not start with "inputrx",
                    -- we assume that this line has been sent by another process, not by the read command.
                    nop
                end
            end
        end
        return inputrx


-------------------------------------------------------------------------------
-- Don't know how to avoid these hardcoded values...
-- 'rexx -e "say address()"' would work IF the default address was the right one
-- to execute the command. But in THE (for example), the default address is THE,
-- and that command wouldn't work.
-- With Regina, I could use ADDRESS SYSTEM, but there is no such generic environment
-- in ooRexx 4 (each platform has a different environment).
-- [13/12/2020]
-- Align with official ooRexx5 : default is "sh" for Linux/MacOs
-- But note the default address() for executor and ooRexx 4 is still bash.
::routine systemAddress
    select
        when .platform~is("windows") then return "cmd"
        otherwise return "sh"
    end


-- Use the readline facilities of the shell
-- Currently, only bash is supported for Linux/MacOs
::routine readlineAddress
    select
        when .platform~is("windows") then return "cmd"
        otherwise return "bash"
    end


-------------------------------------------------------------------------------
::routine transformSource
    use strict arg command

    signal on syntax name transformSourceError -- the clauser can raise an error
    if .ooRexxShell~isExtended then do
        -- Manage the "=" shortcut at the end of each clause
        sourceArray = .array~of(command)
        clauser = .Clauser~new(sourceArray)
        do while clauser~clauseAvailable
            clause = clauser~clause~strip

            dumpLevel = 0
            if clause~right(2) == "==" then dumpLevel = 2 -- no condensed output
            else if clause~right(1) == "=" then dumpLevel = 1 -- condensed output when possible

            if dumpLevel <> 0 then do
                clause = clause~left(clause~length - dumpLevel)
                clauser~clause = 'options "NOCOMMANDS";' clause '; if var("result") then call dumpResult result,' dumpLevel '; else call dumpResult ,' dumpLevel ';options "COMMANDS"'
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
        */
        command = command~strip

        dumpLevel = 0
        if command~right(2) == "==" then dumpLevel = 2 -- no condensed output
        else if command~right(1) == "=" then dumpLevel = 1 -- condensed output when possible

        if dumpLevel <> 0 then command = "result =" command~left(command~length - dumpLevel) "; call dumpResult result," dumpLevel
    end
    transformSourceError: -- in case of error, just return the original command: an error will be raised by interpret, and caught.
    return command


-------------------------------------------------------------------------------
::routine dumpResult
    use strict arg value=.nil, dumpLevel=0
    -- value is not passed when no result (to avoid triggering the "no value" condition)
    if arg(1, "o") then do
        say "[no result]"
        return
    end

    if .CoactivitySupplier~isA(.Class), value~isA(.CoactivitySupplier) then .ooRexxShell~sayPrettyString(value) -- must not consume the datas
    else if .ooRexxShell~isExtended, value~isA(.enclosedArray), dumpLevel == 1 then .ooRexxShell~sayPPrepresentation(value, .ooRexxShell~maxItemsDisplayed) -- condensed output, limited to maxItemsDisplayed
    else if .ooRexxShell~isExtended, value~isA(.array), value~dimension == 1, dumpLevel == 1 then .ooRexxShell~sayPPrepresentation(value, .ooRexxShell~maxItemsDisplayed) -- condensed output, limited to maxItemsDisplayed
    else if value~isA(.Collection)/*, dumpLevel == 2*/  then .ooRexxShell~sayCollection(value, /*title*/, .NumberComparator~new, /*iterateOverItem*/, /*surroundItemByQuotes*/, /*surroundIndexByQuotes*/, /*maxCount*/.ooRexxShell~maxItemsDisplayed) -- detailled output, limited to maxItemsDisplayed
    -- if "==" (dumpLevel 2) then a supplier is displayed as a collection. A copy is made to not consume the datas.
    else if value~isA(.Supplier), dumpLevel == 2 then .ooRexxShell~sayCollection(value~copy, /*title*/, .NumberComparator~new, /*iterateOverItem*/, /*surroundItemByQuotes*/, /*surroundIndexByQuotes*/, /*maxCount*/.ooRexxShell~maxItemsDisplayed) -- detailled output, limited to maxItemsDisplayed
    else .ooRexxShell~sayPrettyString(value)

    return value -- To get this value in the variable RESULT


-------------------------------------------------------------------------------
-- Load optional packages/libraries
::routine loadOptionalComponents
    -- Load the extensions now, because some packages may depend on extensions
    -- for compatibility with ooRexx5 (ex: json, regex)
    .ooRexxShell~isExtended = .true
    if \loadPackage("extension/extensions.cls", .true) then do -- requires jlf sandbox ooRexx
        .ooRexxShell~isExtended = .false
        call loadPackage("extension/std/extensions-std.cls") -- works with standard ooRexx, but integration is weak
    end

    if .platform~is("windows") then do
        -- call loadPackage("orexxole.cls") -- not needed, already included in the image
        call loadPackage("oodialog.cls")
        call loadPackage("winsystm.cls")
    end
    if \.platform~is("windows") then do
        call loadLibrary("rxunixsys")
        call loadPackage("ncurses.cls")
    end
    call loadPackage("csvStream.cls")
    if loadLibrary("hostemu") then .ooRexxShell~interpreters~setEntry("hostemu", "HostEmu")
    call loadPackage("json.cls")
    call loadPackage("mime.cls")
    call loadPackage("rxftp.cls")
    call loadLibrary("rxmath")
    call loadPackage("rxregexp.cls")

    .ooRexxShell~hasRegex = loadPackage("regex/regex.cls")

    call loadPackage("smtp.cls")
    call loadPackage("socket.cls")
    call loadPackage("streamsocket.cls")
    call loadPackage("pipeline/pipe.cls")
    --call loadPackage("ooSQLite.cls")
    .ooRexxShell~hasRgfUtil2Extended = .false
    if loadPackage("rgf_util2/rgf_util2.rex"),, -- derived from the offical rgf_util2.rex (in BSF4ooRexx)
       .nil <> .context~package~findroutine("rgf_util_extended") then do
            .ooRexxShell~hasRgfUtil2Extended = .true
            .ooRexxShell~dump2 = .context~package~findroutine("dump2")
            .ooRexxShell~pp2 = .context~package~findroutine("pp2")
    end

    .ooRexxShell~hasBsf = loadPackage("BSF.CLS")
    if value("UNO_INSTALLED",,"ENVIRONMENT") <> "" then call loadPackage("UNO.CLS")

    if .ooRexxShell~isExtended then do
        .ooRexxShell~hasQueries = loadPackage("oorexxshell_queries.cls")
        call loadPackage("pipeline/pipe_extension.cls")
        call loadPackage("rgf_util2/rgf_util2_wrappers.rex")
        .ooRexxShell~sayComment("Unicode character names not loaded, execute: call loadUnicodeCharacterNames")
    end

    call declareAllPublicClasses
    call declareAllPublicRoutines
    return


-------------------------------------------------------------------------------
::routine loadUnicodeCharacterNames
    status = .Unicode~loadDerivedName("check") -- check if the Unicode data file exists
    if status <> "" then do
        .ooRexxShell~sayError("Can't load the Unicode character names:" status)
        .ooRexxShell~sayError(.Unicode~loadDerivedName("getFile"))
        return .false
    end
    .ooRexxShell~sayInfo("Load the Unicode character names" .Unicode~version "")
    status = .Unicode~loadDerivedName(/*action*/ "load", /*showProgress*/ .true) -- load all the Unicode characters
    .ooRexxShell~sayInfo
    .ooRexxShell~sayInfo(status)

    status = .Unicode~loadNameAliases("check") -- check if the Unicode data file exists
    if status <> "" then do
        .ooRexxShell~sayError("Can't load the Unicode character name aliases:" status)
        .ooRexxShell~sayError(.Unicode~loadNameAliases("getFile"))
        return .false
    end
    -- Small file, no need of progress
    status = .Unicode~loadNameAliases(/*action*/ "load", /*showProgress*/ .false) -- load the name aliases
    .ooRexxShell~sayInfo(status)

    .ooRexxShell~sayComment("Unicode character intervals not expanded, execute: call expandUnicodeCharacterIntervals")

    return .true


::routine expandUnicodeCharacterIntervals
    status = .Unicode~expandCharacterIntervals(.true)
    if status <> "" then do
        .ooRexxShell~sayInfo
        .ooRexxShell~sayInfo(status)
    end


-------------------------------------------------------------------------------
::routine loadPackage
    use strict arg filename, silent=.false
    signal on syntax name loadPackageError
    .context~package~loadPackage(filename)
    if .ooRexxShell~showInitialization then .ooRexxShell~sayInfo("loadPackage OK for" filename)
    return .true
    loadPackageError:
    if \ silent then .ooRexxShell~sayError("loadPackage KO for" filename)
    return .false


-------------------------------------------------------------------------------
::routine loadLibrary
    use strict arg filename
    signal on syntax name loadLibraryError
    if .context~package~loadLibrary(filename) then do
        if .ooRexxShell~showInitialization then .ooRexxShell~sayInfo("loadLibrary OK for" filename)
        return .true
    end
    loadLibraryError:
    .ooRexxShell~sayError("loadLibrary KO for" filename)
    return .false


-------------------------------------------------------------------------------
::routine declareAllPublicClasses
    -- Add all the public and imported public classes to .environment.
    -- I need that when I use ooRexxShell to execute a script which depends on extensions for compatibility with ooRexx 5.
    -- The goal is to keep the script unchanged (don't add any requires for that).
    -- I don't use .context~package~importedClasses because I want to detect collisions, if any.
    use strict arg package=(.context~package), packageStack=(.queue~new), visitedPackages=(.Set~new), visitedClasses=(.Relation~new), collisions=(.Set~new), level=0
    if visitedPackages[package] <> .nil then return -- already visited

    visitedPackages[package] = package
    packageStack~push(package~name) -- will be used for a better diagnostic if collision
        publicClassSupplier = package~publicClasses~supplier
        do while publicClassSupplier~available
            className = publicClassSupplier~index
            classInstance = publicClassSupplier~item
            current = .environment[className]
            if current <> .nil, current <> classInstance then collisions[className] = className
                                                         else .environment[className] = classInstance
            visitedClasses[className] = packageStack~copy
            publicClassSupplier~next
        end

        importedPackageSupplier = package~importedPackages~supplier
        do while importedPackageSupplier~available
            package = importedPackageSupplier~item
            call declareAllPublicClasses package, packageStack, visitedPackages, visitedClasses, collisions, level+1
            importedPackageSupplier~next
        end
    packageStack~pull

    -- Report the collisions, if any
    if level == 0 then do
        do className over collisions~allIndexes~sort
            .ooRexxShell~sayError("Collision detected for class" className)
            definitionNumber = 1
            do packageStack over visitedClasses~allAt(className)~sort
                .ooRexxShell~sayError("    Package stack" definitionNumber)
                packageSupplier = packageStack~supplier
                do while packageSupplier~available
                    .ooRexxShell~sayError("        "packageSupplier~item)
                    packageSupplier~next
                end
                definitionNumber += 1
            end
        end
    end


-------------------------------------------------------------------------------
::routine declareAllPublicRoutines
    -- Add all the public and imported public routines to .globalRoutines.
    -- I need that when I use ooRexxShell to execute a script which depends on routines provided by rgf_util, for example.
    -- The goal is to keep the script unchanged (don't add any requires for that).
    -- I don't use .context~package~importedRoutines because I want to detect collisions, if any.
    use strict arg package=(.context~package), packageStack=(.queue~new), visitedPackages=(.Set~new), visitedroutines=(.Relation~new), collisions=(.Set~new), level=0
    if visitedPackages[package] <> .nil then return -- already visited

    -- Official ooRexx doesn't support .globalRoutines
    -- Make it work for the collision detection, will have no effect on global visibility
    if .nil == .environment["GLOBALROUTINES"] then .environment["GLOBALROUTINES"] = .directory~new

    visitedPackages[package] = package
    packageStack~push(package~name) -- will be used for a better diagnostic if collision
        publicRoutineSupplier = package~publicRoutines~supplier
        do while publicRoutineSupplier~available
            routineName = publicRoutineSupplier~index
            routineInstance = publicRoutineSupplier~item
            current = .globalRoutines[routineName]
            if current <> .nil, current <> routineInstance then collisions[routineName] = routineName
                                                           else .globalRoutines[routineName] = routineInstance
            visitedRoutines[routineName] = packageStack~copy
            publicRoutineSupplier~next
        end

        importedPackageSupplier = package~importedPackages~supplier
        do while importedPackageSupplier~available
            package = importedPackageSupplier~item
            call declareAllPublicRoutines package, packageStack, visitedPackages, visitedRoutines, collisions, level+1
            importedPackageSupplier~next
        end
    packageStack~pull

    -- Report the collisions, if any
    if level == 0 then do
        do routineName over collisions~allIndexes~sort
            .ooRexxShell~sayError("Collision detected for routine" routineName)
            definitionNumber = 1
            do packageStack over visitedRoutines~allAt(routineName) -- ~sort
                .ooRexxShell~sayError("    Package stack" definitionNumber)
                packageSupplier = packageStack~supplier
                do while packageSupplier~available
                    .ooRexxShell~sayError("        "packageSupplier~item)
                    packageSupplier~next
                end
                definitionNumber += 1
            end
        end
    end


-------------------------------------------------------------------------------
::class ooRexxShell public
-------------------------------------------------------------------------------

::constant reload 200 -- Arbitrary value that will be returned to the system, to indicate that a restart of the shell is requested

::attribute command class -- The current command to interpret, can be a substring of inputrx
::attribute commandInterpreter class -- The current interpreter, can be the first word of inputrx, or the default interpreter
::attribute countCommentChars class
::attribute countCommentLines class
::attribute demo class
::attribute demoFast class
::attribute defaultSleepDelay class
::attribute error class -- Will be .true if the last command raised an error
::attribute gotoLabel class -- Either "" or the label to reach
::attribute hasBsf class -- Will be .true if BSF.cls has been loaded
::attribute hasQueries class -- Will be true if oorexxshell_queries.cls has been loaded
::attribute hasRegex class -- Will be .true is regex.cls has been loaded
::attribute hasRgfUtil2Extended class -- Will be .true if rgf_util2.rex has been loaded and is the extended version
::attribute historyFile class
::attribute initialAddress class -- The initial address on startup, not necessarily the system address (can be "THE")
::attribute initialArgument class -- The command line argument on startup
::attribute input class -- The current input to interpret
::attribute inputrx class -- The current input returned by readline, with all the space characters
::attribute inputrxPrevious class -- The previous input returned by readline, with all the space characters
::attribute interpreter class -- One of the environments in 'interpreters' or the special value "ooRexx"
::attribute interpreters class -- The set of interpreters that can be activated
::attribute isExtended class -- Will be .true if the extended ooRexx interpreter is used.
::attribute isInteractive class -- Are we in interactive mode ?
::attribute lastResult class -- result's value from the last interpreted line
::attribute maxItemsDisplayed class -- The maximum number of items to display when displaying a collection
::attribute maybeCommand class -- Indicator used during the analysis of the command line
::attribute maybeCommandPrevious class
::attribute prompt class -- The prompt to display
::attribute promptDirectory class -- .true by default: display the prompt directory
::attribute queueName class -- Private queue for no interference with the user commands
::attribute queueInitialName class -- Backup the initial external queue name (probably "SESSION")
::attribute RC class -- Return code from the last executed command
::attribute readline class -- When .true, the readline functionality is activated (history, tab expansion...)
::attribute readlineAddress class -- "CMD" under Windows, "bash" under Linux/MacOs
::attribute securityManager class
::attribute settingsFile class
::attribute showComment class
::attribute showInfos class
::attribute showInfosNext class
::attribute showInitialization class
::attribute stackFrames class -- stackframes of last error
::attribute systemAddress class -- "CMD" under Windows, "sh" under Linux/MacOs
::attribute traceback class -- traceback of last error

::attribute showColor class
::attribute defaultColor class
::attribute errorColor class
::attribute infoColor class
::attribute promptColor class
::attribute traceColor class
::attribute commentColor class

::attribute traceDispatchCommand class
::attribute traceFilter class
::attribute traceReadline class

::attribute debug class

::attribute trapLostdigits class -- default true: the condition LOSTDIGITS is trapped when interpreting the command
::attribute trapNoMethod class -- default true
::attribute trapNoString class -- default false, will be true if I find a way to optimize the integration of alternative operators
::attribute trapNoValue class -- default true
::attribute trapSyntax class -- default true: the condition SYNTAX is trapped when interpreting the command

::attribute dump2 class -- The routine dump2 of extended rgf_util, or .nil
::attribute pp2 class -- The routine pp2 of extended rgf_util, or .nil

::method init class
    self~countCommentChars = 0
    self~countCommentLines = 0
    self~debug = .false
    self~defaultSleepDelay = 2
    self~demo = .false
    self~demoFast = .false -- by default, the demo is slow (SysSleep is executed)
    self~dump2 = .nil
    self~error = .false
    self~gotoLabel = ""
    self~hasBsf = .false
    self~hasQueries = .false
    self~hasRegex = .false
    self~hasRgfUtil2Extended = .false
    self~isExtended = .false
    self~isInteractive = .false
    self~maxItemsDisplayed = 1000
    self~maybeCommand = .false
    self~pp2 = .nil
    self~promptDirectory = .true
    self~readline = .false
    self~showColor = .false
    self~showComment = .false
    self~showInfosNext = .false
    self~stackFrames = .list~new
    self~traceReadline = .false
    self~traceDispatchCommand = .false
    self~traceFilter = .false
    self~traceback = .array~new
    self~trapLostdigits = .true
    self~trapNoMethod = .false
    self~trapNoString = .false
    self~trapNoValue = .true
    self~trapSyntax = .true

    HOME = value("HOME",,"ENVIRONMENT") -- probably defined under MacOs and Linux, but maybe not under Windows
    if HOME == "" then do
        HOMEDRIVE = value("HOMEDRIVE",,"ENVIRONMENT")
        HOMEPATH = value("HOMEPATH",,"ENVIRONMENT")
        HOME = HOMEDRIVE || HOMEPATH
    end

    -- Use a property file to remember the current directory
    self~settingsFile = HOME || "/.oorexxshell.ini"

    -- When possible, use a history file specific for ooRexxShell
    self~historyFile = HOME || "/.oorexxshell_history"


::method hasLastResult class
    expose lastResult
    return var("lastResult")


::method dropLastResult class
    expose lastResult
    drop lastResult


::method informations class
    -- Remember: keep it compatible with ooRexx 4.2, don't use a literal array.
    messages = ,
    "commandInterpreter",
    "debug",
    "demo",
    "defaultSleepDelay",
    "hasBsf",
    "hasQueries",
    "hasRegex",
    "hasRgfUtil2Extended",
    "historyFile",
    "initialAddress",
    "initialArgument",
    "interpreter",
    "isExtended",
    "isInteractive",
    "maxItemsDisplayed",
    "prompt",
    "promptDirectory",
    "queueName",
    "queueInitialName",
    "RC",
    "readline",
    "readlineAddress",
    "settingsFile",
    "showInfos",
    "systemAddress",
    "showColor",
    "traceDispatchCommand",
    "traceFilter",
    "traceReadline",
    "trapLostdigits",
    "trapNoMethod",
    "trapNoString",
    "trapNoValue",
    "trapSyntax"
    informations = .directory~new
    do message over messages~subwords
        value = .ooRexxshell~send(message)
        informations~put(value, message)
    end
    informations~put(.ooRexxShell~securityManager~isEnabledByUser, "securityManager~isEnabledByUser")
    informations~put(.ooRexxShell~securityManager~traceCommand, "securityManager~traceCommand")
    informations~put(.ooRexxShell~securityManager~verbose, "securityManager~verbose")

    return informations


---------------
-- Displayer --
---------------

::method sayInfo class
    use strict arg text=""
    .color~select(.ooRexxShell~infoColor, .output)
    .output~say(text)
    .color~select(.ooRexxShell~defaultColor, .output)


::method charoutInfo class
    use strict arg text=""
    .color~select(.ooRexxShell~infoColor, .output)
    .output~charout(text)
    .color~select(.ooRexxShell~defaultColor, .output)


::method sayComment class
    use strict arg text=""
    .color~select(.ooRexxShell~commentColor, .output)
    say text
    .color~select(.ooRexxShell~defaultColor, .output)
    .ooRexxShell~countCommentLines += 1
    .ooRexxShell~countCommentChars += text~length


::method charoutComment class
    -- no newline, no count
    use strict arg text=""
    .color~select(.ooRexxShell~commentColor, .output)
    call charout , text
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
    if condition == .nil then return

    .ooRexxShell~traceback = condition~traceback
    .ooRexxShell~stackFrames = condition~stackFrames
    if \ .ooRexxShell~isInteractive then .ooRexxShell~sayStackFrames

    if condition~condition <> "SYNTAX" then .ooRexxShell~sayError(condition~condition)
    if condition~description <> .nil, condition~description <> "" then .ooRexxShell~sayError(condition~description)

    -- For SYNTAX conditions
    if condition~message <> .nil then .ooRexxShell~sayError(condition~message)
    else if condition~errortext <> .nil then .ooRexxShell~sayError(condition~errortext)
    if condition~code <> .nil then .ooRexxShell~sayError("Error code=" condition~code)


::method sayStackFrames class
    if .ooRexxShell~demo then return
    use strict arg stream=.output -- you can pass .error if you want to separate normal output and error output
    supplier = .ooRexxShell~stackFrames~supplier
    do while supplier~available
        stackFrame = supplier~item
        executable = stackFrame~executable

        package = .nil
        if executable <> .nil then package = executable~package

        if package <> .nil then stream~say(package~name)
        else stream~say("<No package>")

        stream~say(stackFrame~traceLine)
        supplier~next
    end


::method sayTraceback class
    use strict arg stream=.output -- you can pass .error if you want to separate normal output and error output
    supplier = .ooRexxShell~traceback~supplier
    do while supplier~available
        stream~say(supplier~item)
        supplier~next
    end


::method sayCollection class
    use strict arg coll, title=(coll~defaultName), comparator=.nil, iterateOverItem=.false, surroundItemByQuotes=.true, surroundIndexByQuotes=.true, maxCount=(9~copies(digits())) /*no limit*/, action=.nil
    -- The package rgfutil2 is optional, use it if loaded.
    if .ooRexxShell~dump2 <> .nil then .ooRexxShell~dump2~call(coll, title, comparator, iterateOverItem, surroundItemByQuotes, surroundIndexByQuotes, maxCount, action)
    else say coll


::method sayPPrepresentation class
    use strict arg value /*enclosedArray or array*/, maxItems=(9~copies(digits())) /*no limit*/
    if .ooRexxShell~isExtended then say value~ppRepresentation(maxItems) -- condensed output, limited to maxItems
    else say value


::method sayPrettyString class
    use strict arg value
    say self~prettyString(value)


::method charoutSlowly class
    use strict arg text, delay=0.05
    -- Naive comment detection (could be inside a quoted string), but good enough.
    commentPos = text~pos("--")
    previousChar = ""
    do i=1 while char \== ""
        if i == commentPos then do
            .ooRexxShell~charoutComment(text~substr(i))
            leave
        end
        else do
            char = text~subchar(i)
            call charout , char
            sleep = delay
            if previousChar <> " " then .ooRexxShell~SysSleep(sleep) -- in case od several spaces, be slow only for the first space.
            previousChar = char
        end
    end


::method prettyString class
    use strict arg value, surroundByQuotes=.true
    -- The package rgfutil2 is optional, use it if loaded.
    if .ooRexxShell~pp2 <> .nil then return .ooRexxShell~pp2~call(value, surroundByQuotes)
    -- JLF to rework: surroundByQuotes is supported only by String~ppString
    -- Can't pass a named argument because I want to keep ooRexxShell compatible with official ooRexx.
    if value~hasMethod("ppString") then return value~ppString(surroundByQuotes)
    return value


::method singularPlural class
    -- Don't use the method singularPlural added on String by extension, because not available when using official ooRexx
    use strict arg count, singularText, pluralText
    if abs(count) <= 1 then return count singularText
    return count pluralText


----------
-- Help --
----------


::method help class
    use strict arg interpreterContext, queryFilter -- the string after '?'
    debugQuery = .false
    if queryFilter~left(1) == "?" then do
        -- If another "?" after the first "?" then we enter in debug mode (query analyzed and dumped but not executed)
        debugQuery = .true
        queryFilter = queryFilter~substr(2) -- skip the second "?"
    end
    if .ooRexxShell~hasQueries then do
        .ooRexxShell~helpWithQueries(interpreterContext, queryFilter, debugQuery)
    end
    else do
        .ooRexxShell~helpNoQueries(interpreterContext, queryFilter, debugQuery)
    end


::method helpWithQueries class
    use strict arg interpreterContext, queryFilter, debugQueryFilter=.false -- queryFilter is the string after '?'

    filteringStream = .nil

    signal on syntax name helpError -- trap the exceptions that could be raised by the query manager

    queryManager = .QueryManager~new(queryFilter, .context~package~findRoutine("stringChunks"))
    if debugQueryFilter then do
        queryManager~dump(self)
        return
    end

    filterArgs = .array~new -- no filter by default (but will allow to display the lineCount)
    -- filter specified in the query ?
    firstFilterIndex = .filteringStream~firstFilterIndex(queryManager~queryFilterArgs)
    if firstFilterIndex <> 0 then do
        -- 2 sections : the query and the filter
        queryArgs = queryManager~queryFilterArgs~section(1, firstFilterIndex - 1)
        filterArgs = queryManager~queryFilterArgs~section(firstFilterIndex)
    end
    else do
        queryArgs = queryManager~queryFilterArgs
    end
    filteringStream = .filteringStream~new(.output~current, filterArgs)
    if .ooRexxShell~traceFilter then filteringStream~traceFilter(self)
    .output~destination(filteringStream)

    .ooRexxShell~dispatchHelp(interpreterContext, queryFilter, queryArgs, filteringStream)

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


::method helpNoQueries class
    use strict arg interpreterContext, queryFilter, debugQueryFilter=.false -- queryFilter is the string after '?'
    queryFilterArgs = stringChunks(queryFilter, .true) -- true: array of StringChunk
    if debugQueryFilter then do
        self~displayCollection(queryFilterArgs)
        return
    end
    .ooRexxShell~dispatchHelp(interpreterContext, queryFilter, queryFilterArgs)


::method dispatchHelp class
    use strict arg interpreterContext, queryFilter, queryArgs, filteringStream=.nil
    if queryArgs[1] == .nil then do
        .ooRexxShell~helpCommands
        return
    end

    arg1 = queryArgs[1]
    word1 = arg1~string
    parse var word1 subword1 "." rest1
    rest = queryArgs~section(2)

    if "classes"~caselessAbbrev(subword1,1) then do
        methods = .false
        inherited = .false
        source = .false
        do while rest1 <> ""
            parse var rest1 first1 "." rest1
            if "methods"~caselessAbbrev(first1,1) then methods = .true
            else if "inherited"~caselessAbbrev(first1,1) then inherited = .true
            else if "source"~caselessAbbrev(first1,1) then source = .true
            else do
                .ooRexxShell~sayError("Expected 'm[ethods]' or 'i[nherited]' or 's[ource]' after" quoted(subword1".")". Got" quoted(first1))
                return
            end
        end
        if inherited | source then methods = .true
        if methods then .ooRexxShell~helpClassMethods(rest, inherited, source, filteringStream)
        else .ooRexxShell~helpClasses(rest)
    end

    -- For convenience... cm is shorter than c.m, cms is shorter than c.m.s, cmi is shorter than c.m.i, cmis is shorter than c.m.i.s
    else if "cm"~caselessEquals(word1) then .ooRexxShell~helpClassMethods(rest, .false, .false, filteringStream)
    else if "cms"~caselessEquals(word1) then .ooRexxShell~helpClassMethods(rest, .false, .true, filteringStream)
    else if "cmi"~caselessEquals(word1) then .ooRexxShell~helpClassMethods(rest, .true, .false, filteringStream)
    else if "cmis"~caselessEquals(word1) then .ooRexxShell~helpClassMethods(rest, .true, .true, filteringStream)

    else if "documentation"~caselessAbbrev(word1,1) & rest~isEmpty then .ooRexxShell~helpDocumentation

    else if "flags"~caselessAbbrev(word1,1) & rest~isEmpty then .ooRexxShell~helpFlags

    else if "help"~caselessAbbrev(subword1,1) then do
        inherited = .false
        do while rest1 <> ""
            parse var rest1 first1 "." rest1
            if "inherited"~caselessAbbrev(first1,1) then inherited = .true
            else do
                .ooRexxShell~sayError("Expected 'i[nherited]' after" quoted(subword1".")". Got" quoted(first1))
                return
            end
        end
        .ooRexxShell~helpHelp(rest, inherited)
    end

    -- For convenience... hi is shorter than h.i
    else if "hi"~caselessEquals(word1) then .ooRexxShell~helpHelp(rest, .true)

    else if "interpreters"~caselessAbbrev(word1,1) & rest~isEmpty then .ooRexxShell~helpInterpreters

    else if "methods"~caselessAbbrev(word1,1) then do
        source = .false
        do while rest1 <> ""
            parse var rest1 first1 "." rest1
            if "source"~caselessAbbrev(first1,1) then source = .true
            else do
                .ooRexxShell~sayError("Expected 's[ource]' after" quoted(subword1".")". Got" quoted(first1))
                return
            end
        end
        .ooRexxShell~helpMethods(rest, source)
    end

    -- For convenience... ms is shorter than m.s
    else if "ms"~caselessEquals(word1) then .ooRexxShell~helpMethods(rest, .true)

    else if "packages"~caselessAbbrev(word1,1) then do
        source = .false
        do while rest1 <> ""
            parse var rest1 first1 "." rest1
            if "source"~caselessAbbrev(first1,1) then source = .true
            else do
                .ooRexxShell~sayError("Expected 's[ource]' after" quoted(subword1".")". Got" quoted(first1))
                return
            end
        end
        .ooRexxShell~helpPackages(rest, source)
    end

    -- For convenience... ps is shorter than p.s
    else if "ps"~caselessEquals(word1) then .ooRexxShell~helpPackages(rest, .true)

    else if "path"~caselessEquals(word1) then .ooRexxShell~helpPath(rest)

    else if "routines"~caselessAbbrev(word1,1) then do
        source = .false
        do while rest1 <> ""
            parse var rest1 first1 "." rest1
            if "source"~caselessAbbrev(first1,1) then source = .true
            else do
                .ooRexxShell~sayError("Expected 's[ource]' after" quoted(subword1".")". Got" quoted(first1))
                return
            end
        end
        .ooRexxShell~helpRoutines(rest, source)
    end

    -- For convenience... rs is shorter than r.s
    else if "rs"~caselessEquals(word1) then .ooRexxShell~helpRoutines(rest, .true)

    else if "settings"~caselessAbbrev(word1, 1) & rest~isEmpty then .ooRexxShell~sayCollection(.ooRexxShell~informations)

    else if "sf"~caselessEquals(word1) & rest~isEmpty then .oorexxShell~sayStackFrames

    else if "tb"~caselessEquals(word1) & rest~isEmpty then .ooRexxShell~sayTraceback
    else if "bt"~caselessEquals(word1) & rest~isEmpty then .ooRexxShell~sayTraceback -- backtrace seems a better name (command "bt" in lldb)

    else if "variables"~caselessAbbrev(word1,1) & rest~isEmpty then .ooRexxShell~helpVariables(interpreterContext)

    else .ooRexxShell~sayError("Query not understood:" queryFilter)


::method checkQueryManagerPrerequisites class
    use strict arg verbose=.true
    if \.ooRexxShell~isExtended then do
        if verbose then .ooRexxShell~sayError("Needs extended ooRexx")
        return .false
    end
    if \.ooRexxShell~hasRgfUtil2Extended then do
        if verbose then .ooRexxShell~sayError("Needs extended rgf_util2")
        return .false
    end
    if \.ooRexxShell~hasQueries then do
        if verbose then .ooRexxShell~sayError("Package 'queries' not loaded")
        return .false
    end
    return .true


::method sayQueryManagerCommand class
    -- Display the text in error color if the interpreter is not extended.
    -- That will allow to see immediatly which commands are available only in extended mode.
    use strict arg text
    if .ooRexxShell~checkQueryManagerPrerequisites(.false) then say text
    else .ooRexxShell~sayError(text)


::method helpCommands class
    say                                 "Queries:"
    say                                 "    ?: display help."
    say                                 "    ?bt: display the backtrace of the last error (same as ?tb)."
    .ooRexxShell~sayQueryManagerCommand("    ?c[lasses] c1 c2... : display classes.")
    .ooRexxShell~sayQueryManagerCommand("    ?c[lasses].m[ethods] c1 c2... : display local methods per classes (cm).")
    .ooRexxShell~sayQueryManagerCommand("    ?c[lasses].m[ethods].i[nherited] c1 c2... : local & inherited methods (cmi).")
    say                                 "    ?d[ocumentation]: invoke ooRexx documentation."
    .ooRexxShell~sayQueryManagerCommand("    ?f[lags]: describe the flags displayed for classes & methods & routines.")
    .ooRexxShell~sayQueryManagerCommand("    ?h[elp] c1 c2 ... : local description of classes.")
    .ooRexxShell~sayQueryManagerCommand("    ?h[elp].i[nherited] c1 c2 ... : local & inherited description of classes (hi).")
    say                                 "    ?i[nterpreters]: interpreters that can be selected."
    .ooRexxShell~sayQueryManagerCommand("    ?m[ethods] method1 method2 ... : display methods.")
    .ooRexxShell~sayQueryManagerCommand("    ?p[ackages]: display the loaded packages.")
    .ooRexxShell~sayQueryManagerCommand("    ?path v1 v2 ... : display value of system variable, splitted by path separator.")
    .ooRexxShell~sayQueryManagerCommand("    ?r[outines] routine1 routine2... : display routines.")
    say                                 "    ?s[ettings]: display ooRexxShell's settings."
    say                                 "    ?sf: display the stack frames of the last error."
    say                                 "    ?tb: display the traceback of the last error (same as ?bt)."
    say                                 "    ?v[ariables]: display the defined variables."
    .ooRexxShell~sayQueryManagerCommand("    To display the source of methods, packages or routines: add the option .s[ource].")
    .ooRexxShell~sayQueryManagerCommand("        Short: ?cms, ?cmis, ?ms, ?ps, ?rs.")
    -- .ooRexxShell~helpInterpreters
    say "Commands:"
    say "    /* alone: Used in a demo to start a multiline comment. Ended by */ alone."
    say "    color off|on: deactivate|activate the colors."
    say "    debug off|on: deactivate|activate the full trace of the internals of ooRexxShell."
    say "    demo off|on: deactivate|activate the demonstration mode."
    say "    exit: exit ooRexxShell."
    say "    goto <label>: Used in a demo script to skip lines, until <label>: (note colon) is reached."
    say "    infos off|on|next: deactivate|activate the display of informations after each execution."
    say "    prompt directory off|on: deactivate|activate the display of the directory before the prompt."
    say "    readline off: use the raw parse pull for the input."
    say "    readline on: delegate to the system readline (history, tab completion)."
    say "    reload: exit the current session and reload all the packages/libraries."
    say "    security off: deactivate the security manager. No transformation of commands."
    say "    security on : activate the security manager. Transformation of commands."
    say "    sleep [n] [no prompt]: used in demo mode to pause during n seconds (default" .ooRexxShell~defaultSleepDelay "sec)."
    say "    trace off|on [d[ispatch]] [f[ilter]] [r[eadline]] [s[ecurity][.verbose]]: deactivate|activate the trace."
    say "    trap off|on [l[ostdigits]] [nom[ethod]] [nos[tring]] [nov[alue]] [s[yntax]]: deactivate|activate the conditions traps."
    say "Input queue name:" .ooRexxShell~queueName


::method helpClasses class
    -- All or specified classes (public & private) that are visible from current context, with their package
    use strict arg classnames
    if .ooRexxShell~checkQueryManagerPrerequisites then .QueryManager~displayClasses(classnames, self, .context)


::method helpClassMethods class
    -- Display the methods of each specified class
    use strict arg classnames, inherited, displaySource, filteringStream
    if .ooRexxShell~checkQueryManagerPrerequisites then .QueryManager~displayClassMethods(classnames, inherited, displaySource, self, .context, filteringStream)


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
        otherwise .ooRexxShell~sayError("Open the URL 'http://www.oorexx.org/docs' in your favorite browser")
    end
    address -- restore


::method helpFlags class
    if .ooRexxShell~checkQueryManagerPrerequisites then .QueryManager~displayFlags


::method helpHelp class
    use strict arg classnames, inherited
    if .ooRexxShell~checkQueryManagerPrerequisites then .QueryManager~displayHelp(classnames, inherited, self, .context)


::method helpInterpreters class
    say "Interpreters:"
    do interpreter over .ooRexxShell~interpreters~allIndexes~sort
        say "    "interpreter~lower": to activate the ".ooRexxShell~interpreters[interpreter]" interpreter."
    end


::method helpMethods class
    -- Display the defining classes of each specified method
    use strict arg methodnames, displaySource
    if .ooRexxShell~checkQueryManagerPrerequisites then .QueryManager~displayMethods(methodnames, displaySource, self, .context)


::method helpPackages class
    -- All packages that are visible from current context, including the current package (source of the pipeline).
    use strict arg packagenames, displaySource
    if .ooRexxShell~checkQueryManagerPrerequisites then .QueryManager~displayPackages(packagenames, displaySource, self, .context)


::method helpPath class
    -- Display the value of the specified system variables , one path per line.
    -- Example of variables: LD_LIBRARY_PATH, MANPATH, PATH
    -- Can be filtered, as any help output.
    use strict arg variablenames
    if .ooRexxShell~checkQueryManagerPrerequisites then .QueryManager~displayPath(variablenames)


::method helpRoutines class
    -- Display the defining package of each specified routine
    use strict arg routinenames, displaySource
    if .ooRexxShell~checkQueryManagerPrerequisites then .QueryManager~displayRoutines(routinenames, displaySource, self, .context)


::method helpVariables class
    -- Display the value of the defined variable
    use strict arg interpreterContext
    .ooRexxShell~sayCollection(interpreterContext~variables)
    -- .ooRexxShell~sayCollection(.context~parentContext~parentContext~parentContext~parentContext~variables)


-----------
-- Other --
-----------


::method trace class
    use strict arg trace, input
    parse var input . . rest
    if rest == "" then do
        self~traceDispatchCommand = trace
        self~traceFilter = trace
        self~traceReadline = trace
        self~securityManager~traceCommand = trace
        self~securityManager~verbose = .false
    end
    do arg over stringChunks(rest)
        parse var arg word1 "." rest
        if "dispatchcommand"~caselessAbbrev(arg) then self~traceDispatchCommand = trace
        else if "filter"~caselessAbbrev(arg) then self~traceFilter = trace
        else if "readline"~caselessAbbrev(arg) then self~traceReadline = trace
        else if "securitymanager"~caselessAbbrev(word1) then do
            self~securityManager~traceCommand = trace
            self~securityManager~verbose = .false
            if rest <> "" then do
                if "verbose"~caselessAbbrev(rest) then self~securityManager~verbose = trace
                else .ooRexxShell~sayError("Expected 'v[erbose]' after" quoted(word1".")". Got" quoted(rest))
            end
        end
        -- for convenience: "sv" is shorter than "s.v"
        else if "sv"~caselessEquals(arg) then do
            self~securityManager~traceCommand = trace
            self~securityManager~verbose = trace
        end
        else .ooRexxShell~sayError("Unknown:" arg)
    end


::method trap class
    use strict arg trap, input
    parse var input . . rest
    if rest == "" then do
        self~trapLostdigits = trap
        self~trapNoMethod = trap
        self~trapNoString = trap
        self~trapNoValue = trap
        self~trapSyntax = trap
    end
    do arg over stringChunks(rest)
        if "lostdigits"~caselessAbbrev(arg, 1) then self~trapLostdigits= trap
        else if "nomethod"~caselessAbbrev(arg, 3) then self~trapNoMethod = trap
        else if "nostring"~caselessAbbrev(arg, 3) then self~trapNoString = trap
        else if "novalue"~caselessAbbrev(arg, 3) then self~trapNoValue = trap
        else if "syntax"~caselessAbbrev(arg, 1) then self~trapSyntax = trap
        else .ooRexxShell~sayError("Unknown condition:" arg)
    end


::method sleep class
    use strict arg input
    parse var input . word2 word3 word4 rest
    error = .false
    delay = .ooRexxShell~defaultSleepDelay
    userDelay = .false
    if word2 == "" then nop
    else if word2~datatype == "NUM" then do
        delay = word2
        userDelay = .true
        if word3 == "" then nop
        else if word3~caselessEquals("no") & word4~caselessEquals("prompt") & rest == "" then nop
        else error = .true
    end
    else do
        if word2~caselessEquals("no") & word3~caselessEquals("prompt") & word4 == "" then nop
        else error = .true
    end
    if error then do
        .ooRexxShell~sayError("Usage:")
        .ooRexxShell~sayError("    sleep")
        .ooRexxShell~sayError("    sleep 5")
        .ooRexxShell~sayError("    sleep 5 no prompt")
        .ooRexxShell~sayError("    sleep no prompt")
        return
    end

    if \userDelay then do -- additional delay for comments
        if .ooRexxShell~inputrxPrevious == "*/" then do
            -- This sleep is immediatly after a multiline comment.
            /*
            -- Add a delay for each comment line, from the second line.
            delay += max(0, (.ooRexxShell~countCommentLines - 1) * 2)
            */
            delay = .ooRexxShell~countCommentChars / 30 -- sleep 1 second for 30 characters
        end
    end

    .ooRexxShell~SysSleep(delay)


::method SysSleep class
    use strict arg delay
    if \.ooRexxShell~demoFast then call SysSleep delay


::method goto class
    use strict arg input
    parse var input . word2 rest
    if rest <> "" then do
        .ooRexxShell~sayError("Expected a label, got:" word2 rest)
        return
    end
    if word2 == "" then do
        .ooRexxShell~sayError("Missing label")
        return
    end
    if isDriveLetter(word2":") then do
        .ooRexxShell~sayError("Can't go to this label, because "word2": is a drive letter")
        return
    end
    .ooRexxShell~gotoLabel = word2


-------------------------------------------------------------------------------
::class SecurityManager
-------------------------------------------------------------------------------
-- Under the control of the user:

-- isEnabledByUser is true by default, can be set to false using the command 'security off'.
-- When false, the security manager is deactivated (typically for debug purpose).
::attribute isEnabledByUser
::attribute traceCommand
::attribute verbose

-- Under the control of ooRexxShell
::attribute isEnabled


::method init
   self~isEnabledByUser = .true
   self~isEnabled = .false
   self~traceCommand = .false
   self~verbose = .false


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
    -- I assume that you often use the environment symbols .true, .false, .nil ?
    -- I assume that you often create instances of predefined classes like .array, .list, .directory, etc... ?
    -- jlf 2021 June 28: ooRexx5 is now optimized for the cases above.
    --                   but still not optimized for the other runtime objects (rexref chapter 6)
    -- If you are curious, then activate the following lines.
    -- You will see that each access to the global .environment will raise two messages sent to the security manager:
    -- "local" and then "environment".
    -- Messages sent for nothing, since I return 0 to indicate that the program is authorized to perform the action.
    -- do 1000000;x=.stdout;end   -- 6.25 sec with ooRexx5 on my (old) MacBookPro 2010, 0.25 sec with Executor
    -- do 1000000;x=.context;end   -- 12.20 sec with ooRexx5 on my (old) MacBookPro 2010, 0.16 sec with Executor (special optimization)
    -- do 1000000;x=1;end       -- 0.080 sec (here, the security manager is not used)

    -- use arg message, arguments
    -- say message quoted(arguments[1]~name)
    return 0


::method command
    if .ooRexxShell~debug then trace i ; else trace off
    use arg info

    isEnabled = self~isEnabledByUser & self~isEnabled
    if isEnabled then status = "enabled" ; else status = "disabled"

    if  \ self~verbose then do
        -- When not verbose, don't trace the command
        if \ isEnabled then return 0 -- delegate to system
    end

    if self~traceCommand then do
        .ooRexxShell~sayTrace("[SecurityManager ("status")] address=" info~address)
        .ooRexxShell~sayTrace("[SecurityManager ("status")] command=" info~command)
    end

    if \ isEnabled then return 0 -- delegate to system

    -- Use a temporary property file to remember the child process directory
    temporarySettingsFile = .ooRexxShell~settingsFile"."SysQueryProcess("PID")
    if SysFileExists(temporarySettingsFile) then call SysFileDelete temporarySettingsFile -- will be created by the command execution, maybe

    newAddressCommand = self~adjustAddressCommand(info~address, info~command, temporarySettingsFile)
    newAddress = newAddressCommand[1]
    newCommand = newAddressCommand[2]
    if newAddress == info~address & newCommand == info~command then return 0 -- address & command not impacted, delegate to system

    -- When not verbose, display the transformed command now
    -- When verbose, no need to display the command here, because the command is displayed at each entry in this method (1st entry: user command, 2nd entry: transformed command)
    if \ self~verbose then do
        if self~traceCommand then do
            .ooRexxShell~sayTrace("[SecurityManager ("status")] address=" newAddress)
            .ooRexxShell~sayTrace("[SecurityManager ("status")] command=" newCommand)
        end
    end

    self~isEnabled = .false
        address value newAddress
        newCommand
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


::method adjustAddressCommand
    if .ooRexxShell~debug then trace i ; else trace off
    use strict arg address, command, temporarySettingsFile

    if .ooRexxShell~commandInterpreter~caselessEquals("ooRexx") then do
        -- Could raise syntax errors because not adapted for concatenation.
    end

    if address~caselessEquals("cmd") then do
        -- [WIN32] Bypass a problem with doskey history:
        -- When a command is directly executable (i.e. passed without "cmd /c" to CreateProcess
        -- in SystemCommands.cpp) then the history is cleared...
        -- So add "cmd /c" in front of the command...
        -- But I don't want it for the commands directly managed by the systemCommandHandler.
        if command~caselessPos("set ") == 1, command~substr(5)~strip~pos("=") > 1 then return .array~of(address, command) -- variable assignment: "set <nospace>="
        if command~caselessPos("cd ") == 1 then return .array~of(address, command) -- change directory
        --if .RegularExpression~new("[:ALPHA:]:")~~match(command)~position == 2 & command~length == 2 then return .array~of(address, command) -- change drive
        if isDriveLetter(command) then return .array~of(address, command) -- change drive
        args = stringChunks(command)
        if .nil == args[1] then return .array~of(address, command)
        if args[1]~caselessEquals("cmd") then return .array~of(address, command) -- already prefixed by "cmd ..."
        if args[1]~caselessEquals("start") then return .array~of(address, command) -- already prefixed by "start ..."
        exepath = .platform~which(args[1])
        exefullpath = qualify(exepath)
        if .platform~subsystem(exefullpath) == 2 then return .array~of(address, 'start "" 'command) -- Don't wait when GUI application
        --return 'cmd /c "'command'"'
        return .array~of(address,,
               'cmd /v /c ' ||,
               quoted(,
                   paren(command) ||,
                   ' & set OOREXXSHELL_ERRORLEVEL=!ERRORLEVEL!' ||,
                   ' & echo OOREXXSHELL_DIRECTORY=!CD! > ' || quoted(temporarySettingsFile) ||,
                   '' ||, -- ' & doskey' ||, -- seems to help keeping the history when a command fails, don't ask me why
                   ' & exit /b !OOREXXSHELL_ERRORLEVEL!',
               ))
    end
    else if address~caselessEquals("bash") then do
        -- If directly managed by the systemCommandHandler then don't add bash in front of the command
        -- if command~caselessEquals("cd") == 1 then return .array~of(address, command) -- home directory
        -- if command~caselessPos("cd ") == 1 then return .array~of(address, command) -- change directory
        if command~caselessPos("set ") == 1 then return .array~of(address, command) -- variable assignment
        if command~caselessPos("unset ") == 1 then return .array~of(address, command) -- variable unassignment
        if command~caselessPos("export ") == 1 then return .array~of(address, command) -- variable assignment
        if command~word(1)~caselessEquals("bash") then return .array~of(address, command) -- already prefixed by "bash ..."
        -- Expands the aliases, assuming you have defined them...
        -- One way to define them is to do:
        -- export BASH_ENV=~/bash_env
        -- and declare the aliases in this file.
        -- This file is executed when bash is not interactive.
        -- This file is also executed when bash is interactive because ~/.bashrc calls it.
        -- (no longer need -O expand_aliases, because run in mode interactive: -i)
        -- The trap command is used to save the current directory of the child process
        -- The 'set -m' command is used to get rid of the message "bash: no job control in this shell" when doing 'cat commands.txt | ooRexxShell', where a command is a system command
        return .array~of(address, "set -m; bash -i -c 'function trap_exit { echo OOREXXSHELL_DIRECTORY=$PWD > "temporarySettingsFile" ; } ; trap trap_exit EXIT ; "command"'") -- the special characters have been already escaped by readline()
    end
    else if address~caselessEquals("sh") then do
        -- If directly managed by the systemCommandHandler then don't add bash in front of the command
        -- if command~caselessEquals("cd") == 1 then return .array~of(address, command) -- home directory
        -- if command~caselessPos("cd ") == 1 then return .array~of(address, command) -- change directory
        if command~caselessPos("set ") == 1 then return .array~of(address, command) -- variable assignment
        if command~caselessPos("unset ") == 1 then return .array~of(address, command) -- variable unassignment
        if command~caselessPos("export ") == 1 then return .array~of(address, command) -- variable assignment
        if command~word(1)~caselessEquals("sh") then return .array~of(address, command) -- already prefixed by "sh ..."
        -- Expands the aliases, assuming you have defined them...
        -- One way to define them is to do:
        -- export ENV=~/bash_env
        -- and declare the aliases in this file.
        -- This file is executed when sh is interactive (yes! the opposite of bash...).
        -- The trap command is used to save the current directory of the child process
        -- The 'set -m' command is used to get rid of the message "sh: no job control in this shell" when doing 'cat commands.txt | ooRexxShell', where a command is a system command
        return .array~of(address, "set -m; sh -i -c 'trap_exit () { echo OOREXXSHELL_DIRECTORY=$PWD > "temporarySettingsFile" ; } ; trap trap_exit EXIT ; "command"'") -- the special characters have been already escaped by readline()
    end
    else if address~caselessEquals("zsh") then do
        -- Not supported by executor (yet) nor by ooRexx4. Supported natively by ooRexx5 but this workaround will work as well.
        -- sh needs that the command be surrounded by '..' to not interpret ';' inside the command.
        return .array~of(.ooRexxShell~systemAddress, "zsh -c '"command"'")
    end
    else if address~caselessEquals("pwsh") then do
        -- cmd doesn't support that the command be surrounded by '..'.
        -- sh needs that the command be surrounded by '..' to not interpret ';' inside the command.
        if .platform~is("windows") then return .array~of(.ooRexxShell~systemAddress, "pwsh -command "command)
        else return .array~of(.ooRexxShell~systemAddress, "pwsh -command '"command"'")
    end
    return .array~of(address, command)


-------------------------------------------------------------------------------
::class color
-------------------------------------------------------------------------------

-- Initialized by .WindowsPlatform~init, not used by Linux & Darwin platforms.
::attribute default class
::attribute defaultBackground class -- 0 to 15
::attribute defaultForeground class -- 0 to 15

::method select class
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
    if RxFuncadd("RxFuncDefine", "gci", "RxFuncDefine") <> 0 then return
    if RxFuncadd("GciFuncDrop", "gci", "GciFuncDrop") <> 0 then return
    if RxFuncadd("GciPrefixChar", "gci", "GciPrefixChar") <> 0 then return
    self~isInstalled = .true


/*
Windows:
If you want the colors in the console then you must put gci.dll in your PATH.
You can get gci 32-bit here: http://rexx-gci.sourceforge.net
For 64-bit support and new type aliases, see https://github.com/jlfaucher/rexx-gci

Linux, MacOs : gci not needed.
The colors are managed with escape characters.
*/


-------------------------------------------------------------------------------
::class platform public
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
::CLASS 'LengthComparator' MIXINCLASS Object public
-------------------------------------------------------------------------------

::method init
    expose direction
    use strict arg criteria="ascending"
    select
        when "ascending"~caselessAbbrev(criteria, 1) then direction = 1
        when "descending"~caselessAbbrev(criteria, 1) then direction = -1
        otherwise raise syntax 93.900 array("LengthComparator: invalid criteria" criteria)
    end


::method compare
    expose direction
    use strict arg left, right
    return direction * sign(left~length - right~length)


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
    use strict arg string, parenLeft="(", parenRight=")"
    return parenLeft || string || parenRight


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


::routine isDriveLetter public
    -- "A:", "a:", ..., "Z:", "z:"
    use strict arg string
    if string~length <> 2 then return .false
    if string~subchar(2) <> ":" then return .false
    letterDrive = string~subchar(1)~upper
    return letterDrive >= "A" & letterDrive <= "Z"
