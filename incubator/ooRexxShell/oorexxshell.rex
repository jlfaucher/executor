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

argrx = arg(1)
parse var argrx word1 rest
do while word1~left(2) == "--"
    if word1~caselessEquals("--showInitialization") then do
        -- Typical usage: when non-interactive demo, we want to show the initialization
        .ooRexxShell~showInitialization = .true
    end
    else if word1~caselessEquals("--showStackFrames") then do
        .ooRexxShell~showStackFrames = .true
    end
    else if word1~caselessEquals("--declareAll") then do
        .ooRexxShell~declareAll = .true
    end
    else do
        .ooRexxShell~sayError("Unknown option" word1)
        return -1
    end
    argrx = rest
    parse var argrx word1 rest
end


.ooRexxShell~isInteractive = (argrx == "" & lines() == 0) -- Example of not interactive session: echo say 1+2 | oorexxshell
if .ooRexxShell~isInteractive then .ooRexxShell~showInitialization = .true

.platform~initialize

-- Use a security manager to trap the calls to the systemCommandHandler:
-- Windows: don't call directly CreateProcess, to avoid loss of doskey history (prepend "cmd /c")
-- Unix: support aliases (run in interactive mode)
.ooRexxShell~securityManager = .SecurityManager~new -- make it accessible from command line
shell = .context~package~findRoutine("SHELL")
shell~setSecurityManager(.ooRexxShell~securityManager)

-- In case of error, must end any running coactivity, otherwise the program doesn't terminate
signal on any name error

-- Bypass defect 2933583 (fixed in release 4.0.1):
-- Must pass the current address (default) because will be reset to system address when entering in SHELL routine
shell~call(argrx, address())

finalize:
if .ooRexxShell~isExtended then .Coactivity~endAll

if .ooRexxShell~isInteractive then do
    settings = .Properties~load(.ooRexxShell~settingsFile)
    settings["OOREXXSHELL_DIRECTORY"] = directory()
    settings~save(.ooRexxShell~settingsFile)
end

-- reload under Macos not always working, and I don't know why
RC = .ooRexxShell~RC
if RC \== .ooRexxShell~reload then RC = (RC <> 0) -- 0 means ok (return 0), anything else means ko (return 1)
exit RC

error:
condition = condition("O")
if condition <> .nil then do
    .ooRexxShell~sayCondition(condition, /*shortFormat*/ .false)
    if .nil \== condition~traceback then .ooRexxShell~sayError(condition~traceback~makearray~tostring)
end
else say "SHOULD NOT HAPPEN: trapped an error, but no condition object to display"
signal finalize


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

-- Deactivate the readline mode when Windows, because the history is not managed correctly.
-- We lose the doskey macros and the filename autocompletion. Too bad...
if .platform~is("windows") then .ooRexxShell~readline = .false
/*
    May 24, 2024:
    No longer reproducible under Windows 11 ARM
    Nov 01, 2022:
    That makes weeks that I try to understand why UTF-8 strings containing accents are corrupted
    (any byte >= 128 is replaced by \0), whereas it worked flawlessly for years.
    I suddenly realize that it's because I deactivated the readline mode on Dec 20, 2020.
    This post explains why the input bug occurs when using chcp 65001:
    https://stackoverflow.com/questions/39736901/chcp-65001-codepage-results-in-program-termination-without-any-error
    When readline is on, ooRexxShell delegates to cmd to read a line:
        set /p inputrx="My prompt> "
    This input mode is not impacted by the UTF-8 input bug!
    I did not reactivate the readline mode by default, but now, I know how to get valid UTF-8 strings with accents.

    Demonstration:
        Launch ooRexxshell, by default readline is off.
        "père Noël"~c2x=    -- '70 00 72 65 20 4E 6F 00 6C'
                            --  p  è  r  e  ␣  N  o  ë  l
        readline on
        "père Noël"~c2x=    -- '70 C3A8 72 65 20 4E 6F C3AB 6C'
                            --  p  è    r  e  ␣  N  o  ë    l
*/

-- Deactivate the readline mode when the environment variable OOREXXSHELL_RLWRAP is defined.
if environment_string("OOREXXSHELL_RLWRAP") <> "" then .ooRexxShell~readline = .false

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
builder/scripts/setenv-oorexx :
    declare the variable $REXX_ENVIRONMENT
    dump all the aliases in the file $REXX_ENVIRONMENT
    save the value of $LD_LIBRARY_PATH in the file $REXX_ENVIRONMENT
    save the value of $DYLD_LIBRARY_PATH in the file $REXX_ENVIRONMENT
~/.profile : defines $ENV = . ~/.bash_env (see man sh)
~/.bashrc : execute ~/.bash_env (no need to define $BASH_ENV)
~/.bash_env : defines some aliases, calls $REXX_ENVIRONMENT
oorexxshell.rex: executes bash and sh in interactive mode (which expand the aliases and redefine $[DY]LD_LIBRARY_PATH)
*/

call loadOptionalComponents

-- Change the current directory AFTER loading the optional components,
-- to increase the chance to load these components even if the PATH is not set.
-- Typical test case : you execute
--     ./rexx <path to>/oorexxshell.rex
-- from the directory containing the rexx executable
if .ooRexxShell~isInteractive then do
    -- Use a property file to remember the current directory
    settings = .Properties~load(.ooRexxShell~settingsFile)
    previousDirectory = settings["OOREXXSHELL_DIRECTORY"]
    if previousDirectory <> .nil then call directory previousDirectory
end

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
.ooRexxShell~queueInitialName = rxqueue("set", .ooRexxShell~queueName) -- SESSION

if .ooRexxShell~hasIndentedStream then do
    .ooRexxShell~indentedOutputStream = .IndentedStream~new(.output~current)
    .output~destination(.ooRexxShell~indentedOutputStream)
    .ooRexxShell~indentedErrorStream = .IndentedStream~new(.error~current)
    .error~destination(.ooRexxShell~indentedErrorStream)
end

call checkReadlineCapability

if .ooRexxShell~initialArgument <> "" then push unquoted(.ooRexxShell~initialArgument) -- One-liner
if .ooRexxShell~showInitialization then call intro
call main

call rxqueue "delete", .ooRexxShell~queueName

return


-------------------------------------------------------------------------------
main: procedure

    -- Reset here, not in REPL because JDOR returns Java objects that might be needed later
    .ooRexxShell~RC = 0

    REPL:
        if .ooRexxShell~debug then trace i ; else trace off
        call on halt name haltHandler

        -- Will be used by .ooRexxShell~sleep to test if the previous command was an end of multiline commment.
        -- The duration of the pause will be proportional to the number of characters in the multiline comment.
        -- Also used by readline to decide if the history file must be updated (a repeated input is stored only once).
        .ooRexxShell~inputrxPrevious = .ooRexxShell~inputrx
        .ooRexxShell~maybeCommandPrevious = .ooRexxShell~maybeCommand

        .ooRexxShell~prompt = prompt(address())
        .ooRexxShell~inputrx = readline(.ooRexxShell~prompt)
        .ooRexxShell~input = .ooRexxShell~inputrx~strip -- remember: don't apply ~space here!

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

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~word(1) == "<" then
                .ooRexxShell~queueFileCommand(.ooRexxShell~input)

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("color off") then
                .ooRexxShell~showColor = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("color on") then
                .ooRexxShell~showColor = .true
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("color codes off") then
                .ooRexxShell~showColorCodes = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("color codes on") then
                .ooRexxShell~showColorCodes = .true

            when .ooRexxShell~maybeCommand &.ooRexxShell~input~space~caselessEquals("debug off") then
                .ooRexxShell~debug = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("debug on") then
                .ooRexxShell~debug = .true

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("demo off") then
                .ooRexxShell~demo = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("demo on") then do
                .ooRexxShell~demo = .true
                -- .ooRexxShell~demoFast = .false   -- remember: don't do that, to give priority to "demo fast" from the command  line
            end

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("demo fast") then do
                .ooRexxShell~demo = .true   -- "demo fast" is first of all "demo". That allows to not put "demo on" in a script when using "demo fast" from the command line
                .ooRexxShell~demoFast = .true
            end

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("test regression") then do
                -- Settings for [non-]regression tests
                -- A script can test .ooRexxShell~testRegression to deactivate the parts that display different values at each execution
                -- The command "infos next" is deactivated (because it displays the duration)
                .ooRexxShell~demo = .true
                .ooRexxShell~demoFast = .true
                .ooRexxShell~testRegression = .true
            end

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~caselessEquals("exit") then
                exit

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~word(1)~caselessEquals("goto") then
                .ooRexxShell~goto(.ooRexxShell~input)

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("indent+") then do
                if .ooRexxShell~hasIndentedStream then do
                    .ooRexxShell~indentedOutputStream~indent
                    .ooRexxShell~indentedErrorStream~indent
                end
            end
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("indent-") then do
                if .ooRexxShell~hasIndentedStream then do
                    .ooRexxShell~indentedOutputStream~dedent
                    .ooRexxShell~indentedErrorStream~dedent
                end
            end

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("infos off") then
                .ooRexxShell~showInfos = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("infos on") then
                .ooRexxShell~showInfos = .true
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("infos next") then
                .ooRexxShell~showInfosNext = \.ooRexxShell~testRegression -- deactivated in mode "test regression"

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessAbbrev("prompt off") then
                .ooRexxShell~promptSettings(.false, .ooRexxShell~input)
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessAbbrev("prompt on") then
                .ooRexxShell~promptSettings(.true, .ooRexxShell~input)

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

            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("tutor off") then
                .ooRexxShell~useTutor = .false
            when .ooRexxShell~maybeCommand & .ooRexxShell~input~space~caselessEquals("tutor on") then do
                if .ooRexxShell~hasTutor then .ooRexxShell~useTutor = .true
                else .ooRexxShell~sayError("The TUTOR component is not loaded")
            end

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
    call time 'r' -- to see how long this takes
    -- RC = 0 -- No longer reset (first need: JDOR)
    .ooRexxShell~securityManager~hasInterceptedCommand = .false -- will become .true if the command has been sent to the addressed environment
    .ooRexxShell~error = .false
    call rxqueue "set", .ooRexxShell~queueInitialName -- Reactivate the initial SESSION queue, for the command evaluation
    if .ooRexxshell~securityManager~isEnabledByUser then .ooRexxShell~securityManager~isEnabled = .true

    if .ooRexxShell~commandInterpreter~caselessEquals("ooRexx") then
        signal interpretCommand -- don't call
    else
        signal addressCommand -- don't call

    return_to_dispatchCommand:
    if .ooRexxshell~securityManager~isEnabledByUser then .ooRexxShell~securityManager~isEnabled = .false
    options "COMMANDS" -- Commands must be enabled for proper execution of ooRexxShell
    call rxqueue "set", .ooRexxShell~queueName -- Back to the public ooRexxShell input queue

    if .ooRexxShell~error then do
        -- The integer portion of condition~code provides the same value as RC
        .ooRexxShell~sayCondition(condition("O"), /*shortFormat*/ .true)
    end
    else do
        if .ooRexxShell~securityManager~hasInterceptedCommand then .ooRexxShell~sayRC(RC)
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

    -- JMB's TUTOR
    signal on syntax name tutorError
    result = transformSourceTutor(.ooRexxShell~command)
    signal off syntax
    if .nil == result then signal tutorError
    .ooRexxShell~command = result

    -- Keep it here, to let display the transformed RXU command.
    -- In case of error raised by RXU, this trace won't be displayed
    if .ooRexxShell~traceDispatchCommand then do
        .ooRexxShell~sayTrace("[interpret]" .ooRexxShell~command)
    end

    if .ooRexxShell~trapLostdigits then signal on lostdigits
    if .ooRexxShell~trapNoMethod then signal on noMethod
    if .ooRexxShell~trapNoString then signal on noString
    if .ooRexxShell~trapNoValue then signal on noValue
    if .ooRexxShell~trapSyntax then signal on syntax

    if .ooRexxShell~hasLastResult then result = .ooRexxShell~lastResult -- restore previous result
                                  else drop result

    interpret .ooRexxShell~command
    after_interpret:

    if var("result") then .ooRexxShell~lastResult = result -- backup current result
                     else .ooRexxShell~dropLastResult

    signal off lostdigits
    signal off noMethod
    signal off noString
    signal off noValue
    signal off syntax
    signal return_to_dispatchCommand

    -- Trap interpret errors
    lostdigits:
    noMethod:
    noString:
    noValue:
    syntax:
    .ooRexxShell~error = .true
    signal after_interpret -- to reset the trap errors

    -- Trap Tutor transformation errors
    tutorError:
    if .ooRexxShell~traceDispatchCommand then do
        .ooRexxShell~sayTrace("[interpret]" .ooRexxShell~command)
    end
    .ooRexxShell~sayError("RXU error")
    .ooRexxShell~error = .true
    signal return_to_dispatchCommand


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
    if .ooRexxShell~isInteractive then do
        if .ooRexxShell~isExtended, .unicode~totalCharactersLoaded == 0 then do
            .ooRexxShell~sayComment("Unicode character names not loaded, execute: call loadUnicodeCharacterNames")
        end

        if .ooRexxShell~useTutor then do
            .ooRexxShell~sayComment("Unicode-REXX (TUTOR) loaded")
            .ooRexxShell~sayComment("    Options DefaultString is" .Unicode.DefaultString)
            .ooRexxShell~sayComment("    Options Coercions     is" .Unicode.Coercions)
        end
    end

    parse version version
    .ooRexxShell~sayInfo
    .ooRexxShell~sayInfo(version)
    .ooRexxShell~sayInfo("Input queue name:" .ooRexxShell~queueName)
    return


-------------------------------------------------------------------------------
::routine promptDirectory
    use strict arg
    if .ooRexxShell~promptDirectory then do
        .color~select(.ooRexxShell~promptColor)
        --say
        say directory()
        .color~select(.ooRexxShell~resetColor)
    end

::routine prompt
    use strict arg currentAddress
    -- No longer display the prompt, return it and let readline display it
    prompt = ""
    if .ooRexxShell~promptInterpreter then prompt = .ooRexxShell~interpreter
    if .ooRexxShell~promptAddress then do
        if .ooRexxShell~interpreter~caselessEquals("ooRexx") then prompt ||= "["currentAddress"]"
                                                             -- else prompt ||= "[ooRexx]"
    end
    if .ooRexxShell~securityManager~isEnabledByUser then prompt ||= "> " ; else prompt ||= "!> "
    return prompt


-------------------------------------------------------------------------------
::routine checkReadlineCapability
    -- Bypass a bug in official ooRexx 4 which delegates to system() when the passed address is bash.
    -- The bug is that system() delegates to /bin/sh, and should be called only when the passed address is sh.
    -- Because of this bug, the readline procedure (which depends on bash) is not working and must be deactivated.
    if .ooRexxShell~readline, .ooRexxShell~isInteractive, .ooRexxShell~readlineAddress~caselessEquals("bash") then do
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
            if inputrx <> "", inputrx <> .ooRexxShell~inputrxPrevious, .ooRexxShell~isInteractive then history~lineout(inputrx)
        end
        when queued() == 0 & lines() == 0 & .ooRexxShell~readlineAddress~caselessEquals("bash") & .ooRexxShell~readline then do
            inputrx = readline_with_bash(prompt)
            if inputrx <> "", inputrx <> .ooRexxShell~inputrxPrevious, .ooRexxShell~isInteractive then history~lineout(inputrx)
        end
        otherwise do
            if .ooRexxShell~isInteractive then do
                call promptDirectory
                call charout , prompt
            end
            queue_or_stdin = queued() <> 0 | lines() <> 0
            parse pull inputrx -- Input queue or standard input or keyboard.
            if .ooRexxShell~isInteractive & queue_or_stdin then say inputrx -- display the input only if coming from queue or from stdin
            if inputrx <> "", inputrx <> .ooRexxShell~inputrxPrevious, .ooRexxShell~isInteractive then history~lineout(inputrx)
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
    RC = .ooRexxShell~RC -- restore (first need: JDOR)

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
            when .ooRexxShell~gotoLabel <> "" then nop -- keep this line first
            when inputrx == "/*" then .ooRexxShell~sayComment(inputrx)
            when inputrx == "*/" then .ooRexxShell~sayComment(inputrx)
            when .ooRexxShell~showComment then .ooRexxShell~sayComment(inputrx)
            when inputrx~left(2) == "--" then .ooRexxShell~sayComment(inputrx)
            when maybeCommand & input~caselessEquals("demo off") then nop
            when maybeCommand & input~caselessEquals("demo on") then nop
            when maybeCommand & input~word(1)~caselessEquals("goto") then nop
            when maybeCommand & input~caselessEquals("indent+") then nop
            when maybeCommand & input~caselessEquals("indent-") then nop
            when maybeCommand & input~caselessEquals("infos next") then nop
            when maybeCommand & input~caselessAbbrev("prompt off") then nop
            when maybeCommand & input~caselessAbbrev("prompt on") then nop
            when maybeCommand & input~word(1)~right(1) == ":" & input~words == 1 & \isDriveLetter(input~word(1)) then nop -- label (when not drive letter)
            when maybeCommand & input~word(1)~caselessEquals("sleep") then do
                if .ooRexxShell~maybeCommand & .ooRexxShell~input~word(1)~caseLessEquals("sleep") then nop -- prompt already displayed
                else if input~caselessPos("no prompt") <> 0 then nop -- don't display the prompt
                else do
                    call promptDirectory
                    call charout , prompt
                end
            end
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
    if .ooRexxShell~hasClauser then do
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
                if .ooRexxShell~isExtended then clauser~clause = 'options "NOCOMMANDS";' clause '; if var("result") then call dumpResult result,' dumpLevel '; else call dumpResult ,' dumpLevel ';options "COMMANDS"'
                                           else clauser~clause = "result =" clause "; call dumpResult result," dumpLevel
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
::routine transformSourceTutor
    -- Return the transformed command
    -- or return .nil if an error was raised and trapped by RXU (not silent)
    -- or raise an error if an error was raised by RXU but not trapped (silent)
    use strict arg command

    if .ooRexxShell~useTutor then do
        signal on syntax name rxuError
        Call "rxu.rex" .Array~of(command), "silent"
        if .nil == result then do
            -- .nil is returned when rxu.rex has trapped and managed an error.
            -- condition("S") is ""
            signal rxuError
        end
        else do
            -- here, rxu.rex did not complain
            if result~isA(.Array) then command = result[1]
            else command = result
        end
        signal off syntax
    end
    return command

    -- Trap RXU transformation errors
    rxuError:
    if condition("S") == "" then return .nil
    raise propagate


-------------------------------------------------------------------------------
::routine dumpResult
    use strict arg value=.nil, dumpLevel=0
    -- value is not passed when no result (to avoid triggering the "no value" condition)
    if arg(1, "o") then do
        say "[no result]"
        return
    end

    comparator = .nil
    if .nil <> .ooRexxShell~comparatorClass then comparator = .ooRexxShell~comparatorClass~new

    if .CoactivitySupplier~isA(.Class), value~isA(.CoactivitySupplier) then .ooRexxShell~sayPrettyString(value) -- must not consume the datas

    else if .ooRexxShell~isExtended, value~isA(.enclosedArray), dumpLevel == 1 then .ooRexxShell~sayPPrepresentation(value, .ooRexxShell~maxItemsDisplayed) -- condensed output, limited to maxItemsDisplayed

    else if value~hasMethod("ppRepresentation"),                                                         value~isA(.array),                       value~dimension == 1, dumpLevel == 1 then .ooRexxShell~sayPPrepresentation(value, .ooRexxShell~maxItemsDisplayed) -- condensed output, limited to maxItemsDisplayed
    else if .ExtensionDispatcher~isA(.class), .ExtensionDispatcher~hasMethod(value, "ppRepresentation"), .ExtensionDispatcher~isA(value, .array), value~dimension == 1, dumpLevel == 1 then .ooRexxShell~sayPPrepresentation(value, .ooRexxShell~maxItemsDisplayed) -- condensed output, limited to maxItemsDisplayed

    else if value~isA(.Collection)                                                        /*, dumpLevel == 2*/  then .ooRexxShell~sayCollection(value, /*title*/, comparator, /*iterateOverItem*/, /*surroundItemByQuotes*/, /*surroundIndexByQuotes*/, /*maxCount*/.ooRexxShell~maxItemsDisplayed) -- detailled output, limited to maxItemsDisplayed
    else if .ExtensionDispatcher~isA(.class), .ExtensionDispatcher~isA(value, .Collection)/*, dumpLevel == 2*/  then .ooRexxShell~sayCollection(value, /*title*/, comparator, /*iterateOverItem*/, /*surroundItemByQuotes*/, /*surroundIndexByQuotes*/, /*maxCount*/.ooRexxShell~maxItemsDisplayed) -- detailled output, limited to maxItemsDisplayed

    -- if "==" (dumpLevel 2) then a supplier is displayed as a collection. A copy is made to not consume the datas.
    else if value~isA(.Supplier), dumpLevel == 2 then .ooRexxShell~sayCollection(value~copy, /*title*/, .comparator, /*iterateOverItem*/, /*surroundItemByQuotes*/, /*surroundIndexByQuotes*/, /*maxCount*/.ooRexxShell~maxItemsDisplayed) -- detailled output, limited to maxItemsDisplayed

    else .ooRexxShell~sayPrettyString(value)

    return value -- To get this value in the variable RESULT


-------------------------------------------------------------------------------
-- Load optional packages/libraries
::routine loadOptionalComponents
    -- Initial customization, before any preloaded package
    -- Be silentLoaded when not interactive, to not display a full path which is incompatible with regression tests
    call loadPackage .oorexxshell~portableCustomizationFile1, /*silentLoaded*/ \ .ooRexxShell~isInteractive, /*silentNotLoaded*/ .true
    call loadPackage .oorexxshell~customizationFile1, /*silentLoaded*/ \ .ooRexxShell~isInteractive, /*silentNotLoaded*/ .true

    -- The routine stringChunks is used internally by ooRexxShell
    -- Try to load the stand-alone package (don't ::requires it, to avoid an error if not found)
    call loadPackage "extension/stringChunk.cls"
   .ooRexxShell~routine_stringChunks = .context~package~findroutine("stringChunks")

    -- The class IndentedStream is optional. Used internally by the "<" command.
    .ooRexxShell~hasIndentedStream = loadPackage("utilities/indentedStream.cls", /*silentLoaded*/ .false, /*silentNotLoaded*/ .true)

    -- Load the extensions now, because some packages may depend on extensions
    -- for compatibility with ooRexx5 (ex: json, regex)
    .ooRexxShell~isExtended = .true
    if \loadPackage("extension/extensions.cls", /*silentLoaded*/ .false, /*silentNotLoaded*/ .true, /*reportError*/ .false) then do -- requires jlf sandbox ooRexx
        .ooRexxShell~isExtended = .false
        call loadPackage "extension/std/extensions-std.cls" -- works with standard ooRexx, but integration is weak
        call loadPackage "procedural/dispatcher.cls" -- procedural version of a selection of Executor's extensions
        .ooRexxShell~hasTutor = loadPackage("Unicode.cls", /*silentLoaded*/ .false, /*silentNotLoaded*/ .true, , "U") -- Namespace "U"
        .ooRexxShell~useTutor = .ooRexxShell~hasTutor
    end

    if .platform~is("windows") then do
        -- call loadPackage "orexxole.cls" -- not needed, already included in the image
        call loadPackage "oodialog.cls"
        call loadPackage "winsystm.cls"
    end
    if \.platform~is("windows") then do
        call loadLibrary "rxunixsys"
        call loadPackage "ncurses.cls"
    end
    call loadPackage "csvStream.cls"
    call loadPackage "dateparser.cls", /*silentLoaded*/ .false, /*silentNotLoaded*/ .true -- ooRexx5 only
    if loadLibrary("hostemu") then .ooRexxShell~interpreters~setEntry("hostemu", "HostEmu")
    call loadPackage "json.cls"
    call loadPackage "mime.cls"
    call loadPackage "rxftp.cls"
    call loadLibrary "rxmath"
    call loadPackage "rxregexp.cls"

    /*
    reportError = .false to not display this error:
        Object ".STRINGTABLE" does not understand message "NEW"
    .StringTable is a new class from ooRexx 5.
    extension/collection.cls and procedural/collection.cls provide a compatible workaround.
    ooRexx 4.2 and Executor will raise the error if the workaround is not loaded.
    */
    .ooRexxShell~hasRegex = loadPackage("regex/regex.cls", /*silentLoaded*/ .false, /*silentNotLoaded*/ .false, /*reportError*/ .false)

    call loadPackage "smtp.cls"
    call loadPackage "socket.cls"
    call loadPackage "streamsocket.cls"
    call loadPackage "pipeline/pipe.cls"
    --call loadPackage "ooSQLite.cls"

    -- derived from the offical rgf_util2.rex (in BSF4ooRexx)
    .ooRexxShell~hasRgfUtil2 = loadPackage("rgf_util2/rgf_util2.rex", /*silentLoaded*/ .false, /*silentNotLoaded*/ .true) -- Try this one first (executor version), because I find also the other one (bsf4oorexx version)
    if .ooRexxShell~hasRgfUtil2 == .false then .ooRexxShell~hasRgfUtil2 = loadPackage("rgf_util2.rex")
    if .ooRexxShell~hasRgfUtil2 == .true,,
       .nil <> .context~package~findroutine("rgf_util_extended") then do
            .ooRexxShell~hasRgfUtil2Extended = .true
            .ooRexxShell~routine_dump2 = .context~package~findroutine("dump2")
            .ooRexxShell~routine_pp2 = .context~package~findroutine("pp2")
            .ooRexxShell~comparatorClass = .NumberComparator
    end

    .local~bsf.quiet=.true -- BSF.CLS will not display the pick up messages
    .ooRexxShell~hasBsf = loadPackage("BSF.CLS")

    if .ooRexxShell~hasBsf then do
        -- JDOR is not available for ooRexx 4.2 and Executor. Don't complain if not loaded.
        if loadPackage("jdor.cls", /*silentLoaded*/ .false, /*silentNotLoaded*/ .true) then call initialize_JDOR

        -- JDORFX is not available for ooRexx 4.2 and Executor. Don't complain if not loaded.
        if loadPackage("jdorfx.cls", /*silentLoaded*/ .false, /*silentNotLoaded*/ .true) then call initialize_JDORFX

        if environment_string("UNO_INSTALLED") <> "" then call loadPackage "UNO.CLS"
	end

    if .Clauser~isA(.Class) then .ooRexxShell~hasClauser = .true
                            else .ooRexxShell~hasClauser = loadPackage("oorexxshell_clauser.cls")

    if .ooRexxShell~isExtended then do
        .ooRexxShell~hasQueries = loadPackage("oorexxshell_queries.cls")
        call loadPackage "pipeline/pipe_extension.cls"
        call loadPackage "rgf_util2/rgf_util2_wrappers.rex"
    end

    -- Second customization, after all preloaded packages
    -- Be silentLoaded when not interactive, to not display a full path which is incompatible with regression tests
    call loadPackage .oorexxshell~portableCustomizationFile2, /*silentLoaded*/ \ .ooRexxShell~isInteractive, /*silentNotLoaded*/ .true
    call loadPackage .oorexxshell~customizationFile2, /*silentLoaded*/ \ .ooRexxShell~isInteractive, /*silentNotLoaded*/ .true

    call checkCircularRequires
    if .ooRexxShell~declareAll then do
        call declareAllPublicClasses
        call declareAllPublicRoutines
    end
    return


-------------------------------------------------------------------------------
::routine loadUnicodeCharacterNames
    status = .Unicode~loadDerivedName("check") -- check if the Unicode data file exists
    if status <> "" then do
        .ooRexxShell~sayError("Can't load the Unicode character names:" status)
        .ooRexxShell~sayError(.Unicode~loadDerivedName("getFile"))
        return .false
    end
    if .ooRexxShell~isInteractive | .ooRexxShell~demo then do
        .ooRexxShell~sayInfo("Load the Unicode character names" .Unicode~version "")
        status = .Unicode~loadDerivedName(/*action*/ "load", /*showProgress*/ .true) -- load all the Unicode characters
        .ooRexxShell~sayInfo
        .ooRexxShell~sayInfo(status)
    end
    else do
        status = .Unicode~loadDerivedName(/*action*/ "load", /*showProgress*/ .false) -- load all the Unicode characters
    end

    status = .Unicode~loadNameAliases("check") -- check if the Unicode data file exists
    if status <> "" then do
        .ooRexxShell~sayError("Can't load the Unicode character name aliases:" status)
        .ooRexxShell~sayError(.Unicode~loadNameAliases("getFile"))
        return .false
    end
    -- Small file, no need of progress
    status = .Unicode~loadNameAliases(/*action*/ "load", /*showProgress*/ .false) -- load the name aliases
    if .ooRexxShell~isInteractive | .ooRexxShell~demo then do
        .ooRexxShell~sayInfo(status)
        .ooRexxShell~sayComment("Unicode character intervals not expanded, execute: call expandUnicodeCharacterIntervals")
    end

    return .true


::routine expandUnicodeCharacterIntervals
    status = .Unicode~expandCharacterIntervals(.true)
    if .ooRexxShell~isInteractive | .ooRexxShell~demo, status <> "" then do
        .ooRexxShell~sayInfo
        .ooRexxShell~sayInfo(status)
    end


-------------------------------------------------------------------------------
::routine loadPackage
    use strict arg filename, silentLoaded=.false, silentNotLoaded=.false, reportError=.true, namespace=""
    signal on syntax name loadPackageError
    if namespace == "" then do
        -- Compatible with ooRexx4
        .context~package~loadPackage(filename)
    end
    else do
        -- Not compatible with ooRexx4
        package = .Package~new(filename)
        .context~package~addPackage(package, namespace)
    end
    if .ooRexxShell~showInitialization, \ silentLoaded then .ooRexxShell~sayInfo("loadPackage OK for" filename)
    return .true
    loadPackageError:
    condition = condition("O")
    if reportError, condition <> .nil, condition~code == 43.901 then reportError = .false -- Don't report the error "file not found"
    if \ silentNotLoaded then do
        .ooRexxShell~sayError("loadPackage KO for" filename)
        if reportError then .ooRexxShell~sayCondition(condition, /*shortFormat*/ .false)
    end
    return .false


-------------------------------------------------------------------------------
::routine initialize_JDOR
    use strict arg -- none
    signal on syntax name error
    call addJdorHandler
    return .true

    error:
    .ooRexxShell~sayError("JDOR initialization KO")
    return .false


-------------------------------------------------------------------------------
::routine initialize_JDORFX
    use strict arg -- none
    signal on syntax name error
    call addJdorFXHandler
    return .true

    error:
    .ooRexxShell~sayError("JDORFX initialization KO")
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
::routine checkCircularRequires
    -- Temporary until I retrofit the ooRexx5 native check
    use strict arg package=(.context~package), packageStack=(.queue~new), level=0
    if packageStack~hasItem(package) then do
        -- already visited
        if .ooRexxShell~isInteractive then do
            .ooRexxShell~sayError("Circular ::requires")
            .ooRexxShell~sayError("    "package~name)
            packageSupplier = packageStack~supplier
            do while packageSupplier~available
                .ooRexxShell~sayError("    "packageSupplier~item~name)
                packageSupplier~next
            end
        end
        return .true -- circular
    end

    circular = .false
    packageStack~push(package)
    importedPackageSupplier = package~importedPackages~supplier
    do while importedPackageSupplier~available
        package = importedPackageSupplier~item
        call checkCircularRequires package, packageStack, level+1
        if result == .true then return .true -- stop at first detection of circular requires
        importedPackageSupplier~next
    end
    packageStack~pull
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
    if level == 0, .ooRexxShell~isInteractive then do
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
    if level == 0, .ooRexxShell~isInteractive then do
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
::attribute commandColor class
::attribute commandInterpreter class -- The current interpreter, can be the first word of inputrx, or the default interpreter
::attribute commentColor class
::attribute comparatorClass class -- The comparator class used to sort the collections for display, or .nil
::attribute configHome class -- User-specific configurations (XDG_CONFIG_HOME)
::attribute countCommentChars class -- Used in demo mode
::attribute countCommentLines class -- Used in demo mode
::attribute customizationFile1 class
::attribute customizationFile2 class
::attribute debug class
::attribute declareAll class -- Command line option
::attribute defaultSleepDelay class -- Used in demo mode
::attribute demo class
::attribute demoFast class
::attribute error class -- Will be .true if the last command raised an error
::attribute errorColor class
::attribute gotoLabel class -- Used in demo mode: either "" or the label to reach
::attribute hasBsf class -- Will be .true if BSF.cls has been loaded
::attribute hasClauser class -- Will be .true if the Clauser class is available (either natively with Executor, or if oorexxshell_clauser.cls has been loaded
::attribute hasIndentedStream class -- Will be true if indentedStream.cls has been loaded
::attribute hasQueries class -- Will be true if oorexxshell_queries.cls has been loaded
::attribute hasRegex class -- Will be .true is regex.cls has been loaded
::attribute hasRgfUtil2 class -- Will be .true if rgf_util2.rex has been loaded
::attribute hasRgfUtil2Extended class -- Will be .true if rgf_util2.rex has been loaded and is the extended version
::attribute hasTutor class -- Will be true if JMB's TUTOR has been loaded
::attribute historyFile class
::attribute indentedErrorStream class -- Used by the command "<" to show the level of include
::attribute indentedOutputStream class -- Used by the command "<" to show the level of include
::attribute infoColor class
::attribute initialAddress class -- The initial address on startup, not necessarily the system address (can be "THE")
::attribute initialArgument class -- The command line argument on startup
::attribute input class -- The current input to interpret
::attribute inputrx class -- The current input returned by readline, with all the space characters
::attribute inputrxPrevious class -- The previous input returned by readline, with all the space characters
::attribute interpreter class -- One of the environments in 'interpreters' or the special value "ooRexx"
::attribute interpreters class -- The set of interpreters that can be activated
::attribute isExtended class -- Will be .true if the extended ooRexx interpreter is used.
::attribute isInteractive class -- Are we in interactive mode ?
::attribute isPortable class -- Will be .true if a portable ooRexx is used.
::attribute lastCondition class -- Condition object of last error trapped by ooRexxShell
::attribute lastResult class -- result's value from the last interpreted line
::attribute maxItemsDisplayed class -- The maximum number of items to display when displaying a collection
::attribute maybeCommand class -- Indicator used during the analysis of the command line
::attribute maybeCommandPrevious class
::attribute ooRexxHome class -- value of the environment variable OOREXX_HOME
::attribute portableConfigHome class -- User-specific configurations
::attribute portableCustomizationFile1 class
::attribute portableCustomizationFile2 class
::attribute portableHome class
::attribute portableStateHome class -- state data that should persist between restarts (logs, history, ...)
::attribute prompt class -- The prompt to display
::attribute promptAddress class -- .true by default: display the current system address in interpreter[address]
::attribute promptColor class
::attribute promptDirectory class -- .true by default: display the prompt directory
::attribute promptInterpreter class -- .true by default: display the current interpreter name in interpreter[address]
::attribute queueName class -- Private queue for no interference with the user commands
::attribute queueInitialName class -- Backup the initial external queue name (probably "SESSION")
::attribute RC class -- Return code from the last executed command
::attribute readline class -- When .true, the readline functionality is activated (history, tab expansion...)
::attribute readlineAddress class -- "CMD" under Windows, "bash" under Linux/MacOs
::attribute resetColor class
::attribute rexxHome class -- value of the environment variable REXX_HOME
::attribute routine_dump2 class -- The routine dump2 of extended rgf_util, or .nil
::attribute routine_pp2 class -- The routine pp2 of extended rgf_util, or .nil
::attribute routine_stringChunks class -- The routine stringChunks, or .nil
::attribute runtimeDir class -- User-specific non-essential runtime files (XDG_RUNTIME_DIR).
::attribute securityManager class
::attribute settingsFile class
::attribute showColor class
::attribute showColorCodes class
::attribute showComment class
::attribute showInfos class
::attribute showInfosNext class
::attribute showInitialization class -- Command line option
::attribute showStackFrames class -- Command line option
::attribute stackFrames class -- stackframes of last error
::attribute stateHome class -- state data that should persist between restarts (logs, history, ...) (XDG_STATE_HOME).
::attribute systemAddress class -- "CMD" under Windows, "sh" under Linux/MacOs
::attribute testRegression class -- a script can test this attribute to decide if some parts are deactivated to have repeatable results (for [non-]regression tests)
::attribute traceback class -- traceback of last error
::attribute traceColor class
::attribute traceDispatchCommand class
::attribute traceFilter class
::attribute traceReadline class
::attribute trapLostdigits class -- default true: the condition LOSTDIGITS is trapped when interpreting the command
::attribute trapNoMethod class -- default true
::attribute trapNoString class -- default false, will be true if I find a way to optimize the integration of alternative operators
::attribute trapNoValue class -- default false
::attribute trapSyntax class -- default true: the condition SYNTAX is trapped when interpreting the command
::attribute userHome class
::attribute useTutor class -- default true if the TUTOR component has been loaded, can be deactivated by the user: tutor off


-- can't use init because depends on the class .color, not yet activated
::method activate class
    -- command line options
    self~declareAll = .false
    self~showInitialization = .false
    self~showStackFrames = .false

    -- execution
    self~command = ""
    self~commandInterpreter = ""
    self~initialAddress = ""
    self~initialArgument = ""
    self~maybeCommand = .false

    -- demo
    self~countCommentChars = 0
    self~countCommentLines = 0
    self~defaultSleepDelay = 2
    self~demo = .false
    self~demoFast = .false -- by default, the demo is slow (SysSleep is executed)
    self~gotoLabel = ""

    -- mode
    self~isExtended = .false
    self~isInteractive = .false
    self~testRegression = .false

    -- readline
    self~promptAddress = .true
    self~promptDirectory = .true
    self~promptInterpreter = .true
    self~readline = .false

    -- displayer
    self~maxItemsDisplayed = 1000
    self~showColor = .true
    self~showColorCodes = .false
    self~showComment = .false
    self~showInfos = .false
    self~showInfosNext = .false

    -- diagnostic
    self~debug = .false
    self~traceback = .array~new
    self~traceReadline = .false
    self~traceDispatchCommand = .false
    self~traceFilter = .false

    -- error management
    self~error = .false
    self~lastCondition = .nil
    self~stackFrames = .list~new
    self~trapLostdigits = .true
    self~trapNoMethod = .false
    self~trapNoString = .false
    self~trapNoValue = .false
    self~trapSyntax = .true

    -- optional components
    self~hasBsf = .false
    self~hasClauser = .false
    self~hasIndentedStream = .false
    self~hasQueries = .false
    self~hasRegex = .false
    self~hasRgfUtil2 = .false
    self~hasRgfUtil2Extended = .false
    self~hasTutor = .false
    self~useTutor = .false

    -- optional services
    self~comparatorClass = .nil
    self~routine_dump2 = .nil
    self~routine_pp2 = .nil
    self~routine_stringChunks = .nil

    self~indentedErrorStream = .nil
    self~indentedOutputStream = .nil

    -- additional initializations
    self~initColors
    self~initEnvironment


::method initEnvironment class
    .environment~setentry(self~id, self) -- Make the .ooRexxShell class available from the customization file

    -- Environment variables defined when using a portable version of ooRexx
    self~isPortable = environment_string("PORTABLE_OOREXX") == "1"
    self~ooRexxHome = environment_directory_path("OOREXX_HOME")
    self~rexxHome = environment_directory_path("REXX_HOME")
    PACKAGES_HOME = environment_directory_path("PACKAGES_HOME") -- needed for migration
    self~portableHome = ""
    if self~isPortable then do
        -- Would be better to use an environment variable like PORTABLE_HOME, but none is defined.
        -- OOREXX_HOME is not candidate (even if its current value is what I need).
        -- Fallback: use the parent directory of PACKAGES_HOME.
        if PACKAGES_HOME \== "" then do
            self~portableHome = PACKAGES_HOME || .file~separator || ".." -- could be an other value in the future
            self~portableHome = .file~new(self~portableHome)~absolutePath -- normalized path
        end
    end

    -- Migration to XDG
    -- To be done before the creation of .config and .local in the portable home
    -- otherwise the old .config and .local would not be moved.
    call migrate PACKAGES_HOME, ".config", self~portableHome, ".config"
    call migrate PACKAGES_HOME, ".local",  self~portableHome, ".local"

    -- Application of (some) XDG recommendations.
    -- https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    -- The XDG environment variables are maybe defined under Linux, probably not defined under MacOs and Windows
    XDG_DATA_HOME = environment_directory_path("XDG_DATA_HOME")         -- not needed by ooRexxShell ($HOME/.local/share)
    XDG_CONFIG_HOME = environment_directory_path("XDG_CONFIG_HOME")
    XDG_STATE_HOME = environment_directory_path("XDG_STATE_HOME")
    XDG_CACHE_HOME = environment_directory_path("XDG_CACHE_HOME")       -- not needed by ooRexxShell ($HOME/.cache)
    XDG_RUNTIME_DIR = environment_directory_path("XDG_RUNTIME_DIR")

    self~userHome = environment_directory_path("HOME") -- probably defined under MacOs and Linux, but maybe not under Windows
    if self~userHome == "" then self~userHome = environment_directory_path("USERPROFILE") -- Windows specific

    -- I don't use .file~temporaryPath because it's not available with ooRexx 4.2
    TMPDIR = environment_directory_path("TMPDIR")
    if TMPDIR == "" then TMPDIR = environment_directory_path("TMP")
    if TMPDIR == "" then TMPDIR = environment_directory_path("TEMP")
    if TMPDIR == "" then do
        TMPDIR = self~userHome
        dir = TMPDIR || .file~separator || "tmp"
        if createDirectory(dir) >= 0 then TMPDIR = dir
    end

    -- .ooRexxShell~configHome is equivalent to $XDG_CONFIG_HOME
    -- The recommended value is $HOME/.config
    self~configHome = XDG_CONFIG_HOME
    if self~configHome == "" then do
        self~configHome = self~userHome
        dir = self~userHome || .file~separator || ".config"
        if createDirectory(dir) >= 0 then self~configHome = dir
    end
    dir = self~configHome || .file~separator || "oorexxshell"
    if createDirectory(dir) >= 0 then self~configHome = dir

    -- .ooRexxShell~portableConfigHome can be empty
    self~portableConfigHome = self~portableHome
    if self~portableConfigHome \== "" then do
        dir = self~portableConfigHome || .file~separator || ".config" || .file~separator || "oorexxshell"
        if createDirectory(dir) >= 0 then self~portableConfigHome = dir
    end

    -- .ooRexxShell~stateHome is equivalent to $XDG_STATE_HOME
    -- The recommended value is $HOME/.local/state
    self~stateHome = XDG_STATE_HOME
    if self~stateHome == "" then do
        self~stateHome = self~userHome
        dir = self~userHome || .file~separator || ".local" || .file~separator || "state"
        if createDirectory(dir) >= 0 then self~stateHome = dir
    end
    dir = self~stateHome || .file~separator || "oorexxshell"
    if createDirectory(dir) >= 0 then self~stateHome = dir

    -- .ooRexxShell~portableStateHome can be empty
    self~portableStateHome = self~portableHome
    if self~portableStateHome \== "" then do
        dir = self~portableStateHome || .file~separator || ".local" || .file~separator || "state" || .file~separator || "oorexxshell"
        if createDirectory(dir) >= 0 then self~portableStateHome = dir
    end

    -- .ooRexxShell~runtimeDir is equivalent to $XDG_RUNTIME_DIR
    -- The recommended value is /run/user/$UID
    -- https://0pointer.net/blog/projects/tmp.html
    -- Point 2: You need a place to put your socket (or other communication primitive) and your code runs unprivileged: use a subdirectory beneath $XDG_RUNTIME_DIR.
    self~runtimeDir = XDG_RUNTIME_DIR
    if self~runtimeDir == "" then self~runtimeDir = TMPDIR
    dir = self~runtimeDir || .file~separator || "oorexxshell"
    if createDirectory(dir) >= 0 then self~runtimeDir = dir

    -- Use a property file to remember the current directory
    -- If portable then put it in the portable bundle
    dir = self~portableStateHome
    if dir == "" then dir = self~stateHome
    SETTINGS = "settings.ini"
    self~settingsFile = dir || .file~separator || SETTINGS

    -- When possible, use a history file specific for ooRexxShell
    -- For the moment, don't use portableStateHome or stateHome because it doesn't work with rlwrap
    HISTORY_FILE = ".oorexxshell_history"
    self~historyFile = self~userHome || .file~separator || HISTORY_FILE

    -- Allow customization by end user
    CUSTOM1 = "custom1.rex"
    CUSTOM2 = "custom2.rex"
    self~portableCustomizationFile1 = ""
    self~portableCustomizationFile2 = ""
    if self~portableConfigHome \== "" then do
        self~portableCustomizationFile1 = self~portableConfigHome || .file~separator || CUSTOM1
        self~portableCustomizationFile2 = self~portableConfigHome || .file~separator || CUSTOM2
    end
    self~customizationFile1 = self~configHome || .file~separator || CUSTOM1
    self~customizationFile2 = self~configHome || .file~separator || CUSTOM2

    -- Migration to XDG
    call migrate PACKAGES_HOME, ".oorexxshell.ini",                 self~portableStateHome,     SETTINGS
    call migrate self~userHome, ".oorexxshell.ini",                 self~stateHome,             SETTINGS
    call migrate PACKAGES_HOME, ".oorexxshell_customization.rex",   self~portableConfigHome,    CUSTOM1
    call migrate self~userHome, ".oorexxshell_customization.rex",   self~configHome,            CUSTOM1
    call migrate PACKAGES_HOME, ".oorexxshell_customization2.rex",  self~portableConfigHome,    CUSTOM2
    call migrate self~userHome, ".oorexxshell_customization2.rex",  self~configHome,            CUSTOM2

    return

    migrate: procedure
        use strict arg sourceDir, sourcefile, targetDir, targetFile
        if sourceDir == "" then return
        if targetDir == "" then return
        source = sourceDir || .file~separator || sourceFile
        target = targetDir || .file~separator || targetFile
        if source \== target, SysFileExists(source), \ SysFileExists(target) then call move source, target
        return

    move: procedure
        use strict arg source, target
        code = SysFileMove(source, target)
        if code == 0 then do
            .ooRexxShell~sayComment("Migration to XDG: moved '" || source || "' to '" || target || "'")
        end
        else do
            .ooRexxShell~sayError("Migration to XDG: failed to move '" || source || "' to '" || target || "'")
            .ooRexxShell~sayError(SysGetErrorText(code))
        end
        return


::method initColors class
    -- Color settings (can be customized by the end user)
    .ooRexxShell~resetColor = "reset"
    .ooRexxShell~errorColor = "bred"
    .ooRexxShell~infoColor = "bgreen"
    .ooRexxShell~commentColor = "bblue"
    .ooRexxShell~promptColor = "byellow"
    .ooRexxShell~traceColor = "magenta"
    .ooRexxShell~commandColor = "bmagenta"

    /*
    -- defaultBackground no longer supported
    -- if you want to use these colors then define them in the customization file
    if .platform~is("windows") then do
        if .color~defaultBackground == 0 then do -- black
            .ooRexxShell~commentColor = "bcyan" -- instead of blue which is less readable
        end
        if .color~defaultBackground == 15 then do -- white
            .ooRexxShell~infoColor = "green"
            .ooRexxShell~promptColor = "yellow"
        end
    end
    */


::method informations class
    -- Remember: keep it compatible with ooRexx 4.2, don't use a literal array.
    -- [custom]     can be customized in the customization file
    -- [info]       don't touch
    messages = ,
    ",[custom] commandColor",
    ",[info]   commandInterpreter",
    ",[custom] commentColor",
    ",[info]   configHome",
    ",[info]   customizationFile1",
    ",[info]   customizationFile2",
    ",[custom] debug",
    ",[custom] demo",
    ",[custom] demoFast",
    ",[custom] defaultSleepDelay",
    ",[custom] errorColor",
    ",[info]   hasBsf",
    ",[info]   hasClauser",
    ",[info]   hasIndentedStream",
    ",[info]   hasQueries",
    ",[info]   hasRegex",
    ",[info]   hasRgfUtil2",
    ",[info]   hasRgfUtil2Extended",
    ",[info]   hasTutor",
    ",[info]   historyFile",
    ",[custom] infoColor",
    ",[info]   initialAddress",
    ",[info]   initialArgument",
    ",[info]   interpreter",
    ",[info]   isExtended",
    ",[info]   isInteractive",
    ",[info]   isPortable",
    ",[custom] maxItemsDisplayed",
    ",[info]   ooRexxHome",
    ",[info]   portableConfigHome",
    ",[info]   portableCustomizationFile1",
    ",[info]   portableCustomizationFile2",
    ",[info]   portableHome",
    ",[info]   portableStateHome",
    ",[custom] promptAddress",
    ",[custom] promptColor",
    ",[custom] promptDirectory",
    ",[custom] promptInterpreter",
    ",[info]   queueName",
    ",[info]   queueInitialName",
    ",[info]   RC",
    ",[custom] readline",
    ",[info]   readlineAddress",
    ",[custom] resetColor",
    ",[info]   rexxHome",
    ",[info]   runtimeDir",
    ",[info]   settingsFile",
    ",[custom] showColor",
    ",[custom] showInfos",
    ",[info]   stateHome",
    ",[custom] systemAddress",
    ",[custom] testRegression",
    ",[custom] traceDispatchCommand",
    ",[custom] traceFilter",
    ",[custom] traceReadline",
    ",[custom] trapLostdigits",
    ",[custom] trapNoMethod",
    ",[custom] trapNoString",
    ",[custom] trapNoValue",
    ",[custom] trapSyntax",
    ",[info]   userHome",
    ",[custom] useTutor"
    informations = .directory~new
    do message over messages~makeArray(",")
        message = message~strip
        if message == "" then iterate
        -- suffix made of 9 characters, the real message starts at 10
        suffixLength = 9
        prefix = message~left(suffixLength)
        realMessage = message~substr(suffixLength + 1) -- remove prefix
        value = .ooRexxshell~send(realMessage)
        informations~put(value, prefix || ".ooRexxShell~" || realMessage)
    end
    informations~put(.ooRexxShell~securityManager~isEnabledByUser,  "[custom] .ooRexxShell~securityManager~isEnabledByUser")
    informations~put(.ooRexxShell~securityManager~traceCommand,     "[custom] .ooRexxShell~securityManager~traceCommand")
    informations~put(.ooRexxShell~securityManager~verbose,          "[custom] .ooRexxShell~securityManager~verbose")
    informations~put(.color~background,                             "[custom] .color~background")

    if .ooRexxShell~hasTutor then do
        informations~put(.unicode.coercions,                        "[info]   .unicode.coercions")
        informations~put(.unicode.defaultString,                    "[info]   .unicode.defaultString")
    end

    return informations


-----------------
-- Last result --
-----------------

::method hasLastResult class
    expose lastResult
    return var("lastResult")


::method dropLastResult class
    expose lastResult
    drop lastResult


---------------
-- Displayer --
---------------

::method sayInfo class
    use strict arg text=""
    .color~select(.ooRexxShell~infoColor, .output)
    .output~say(text)
    .color~select(.ooRexxShell~resetColor, .output)


::method charoutInfo class
    use strict arg text=""
    .color~select(.ooRexxShell~infoColor, .output)
    .output~charout(text)
    .color~select(.ooRexxShell~resetColor, .output)


::method sayComment class
    use strict arg text=""
    .color~select(.ooRexxShell~commentColor, .output)
    say text
    .color~select(.ooRexxShell~resetColor, .output)
    .ooRexxShell~countCommentLines += 1
    .ooRexxShell~countCommentChars += text~length


::method charoutComment class
    -- no newline, no count
    use strict arg text=""
    .color~select(.ooRexxShell~commentColor, .output)
    call charout , text
    .color~select(.ooRexxShell~resetColor, .output)


::method sayTrace class
    use strict arg text=""
    .color~select(.ooRexxShell~traceColor, .traceOutput)
    .traceOutput~say(text)
    .color~select(.ooRexxShell~resetColor, .traceOutput)


::method sayRC class
    /*
    RC can be set by interpretCommand or by addressCommand.
    - When interpretCommand: RC can be any value (for example, can be a Java object when using JDOR).
    - When addressCommand: RC is a number. Generally, 0 means "no error".
    */
    use strict arg RC
    if RC == 0 then return
    .color~select(.ooRexxShell~errorColor, .error)
    -- since RC can be any value (case of JDOR), display it as a result
    call charout , "RC="
    call dumpResult RC
    .color~select(.ooRexxShell~resetColor, .error)


::method sayError class
    use strict arg text=""
    .color~select(.ooRexxShell~errorColor, .error)
    .error~say(text)
    .color~select(.ooRexxShell~resetColor, .error)


::method sayCondition class
    use strict arg condition, shortFormat = .true
    if condition == .nil then return

    .ooRexxShell~lastCondition = condition
    .ooRexxShell~traceback = condition~traceback
    .ooRexxShell~stackFrames = condition~stackFrames
    if .ooRexxShell~showStackFrames | \ (.ooRexxShell~isInteractive | .ooRexxShell~demo) then .ooRexxShell~sayStackFrames

    if shortFormat then do
        -- Here the file name and line number are irrelevant
        if condition~condition <> "SYNTAX" then .ooRexxShell~sayError(condition~condition)
        if condition~description <> .nil, condition~description <> "" then .ooRexxShell~sayError(condition~description)

        -- For SYNTAX conditions
        if condition~message <> .nil then .ooRexxShell~sayError(condition~message)
        else if condition~errortext <> .nil then .ooRexxShell~sayError(condition~errortext)
        if condition~code <> .nil then .ooRexxShell~sayError("Error code=" condition~code)
    end
    else do
        -- Here the file name and line number are relevant
        .ooRexxShell~sayError("Error" condition~rc "running" condition~package~name "line" condition~position":" condition~errortext)
        .ooRexxShell~sayError("Error" condition~code":" condition~message)
    end


::method sayStackFrames class
    use strict arg stream=.output -- you can pass .error if you want to separate normal output and error output
    if .nil == .ooRexxShell~stackFrames then return
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
    if .nil == .ooRexxShell~traceback then return
    supplier = .ooRexxShell~traceback~supplier
    do while supplier~available
        stream~say(supplier~item)
        supplier~next
    end


::method sayCollection class
    numeric digits -- stop any propagated settings, to have the default value for digits()
    use strict arg coll, title=(coll~defaultName), comparator=.nil, iterateOverItem=.false, surroundItemByQuotes=.true, surroundIndexByQuotes=.true, maxCount=(9~copies(digits())) /*no limit*/, action=.nil
    -- The package rgfutil2 is optional, use it if loaded.
    if .ooRexxShell~routine_dump2 <> .nil then .ooRexxShell~routine_dump2~call(coll, title, comparator, iterateOverItem, surroundItemByQuotes, surroundIndexByQuotes, maxCount, action)
    else do
        say coll
        -- no sort, no alignment, nothing
        -- if you want that then set your environment correctly to let load the extended rgf_util2
        supplier = coll~supplier
        do while supplier~available
            say supplier~index":" supplier~item
            supplier~next
        end
    end


::method sayPPrepresentation class
    numeric digits -- stop any propagated settings, to have the default value for digits()
    use strict arg value /*enclosedArray or array*/, maxItems=(9~copies(digits())) /*no limit*/
    if value~hasMethod("ppRepresentation") then say value~ppRepresentation(maxItems) -- condensed output, limited to maxItems
    else if .ExtensionDispatcher~isA(.class), .ExtensionDispatcher~hasMethod(value, "ppRepresentation") then say .ExtensionDispatcher~ppRepresentation(value, maxItems) -- condensed output, limited to maxItems
    else say value


::method sayPrettyString class
    use strict arg value
    say self~prettyString(value)


::method charoutSlowly class
    use strict arg text, delay=0.05
    .color~select(.ooRexxShell~commandColor, .error)
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
    .color~select(.ooRexxShell~resetColor, .error)


::method prettyString class
    use strict arg value, surroundByQuotes=.true
    -- The package rgfutil2 is optional, use it if loaded.
    if .ooRexxShell~routine_pp2 <> .nil then return .ooRexxShell~routine_pp2~call(value, surroundByQuotes)
    -- JLF to rework: surroundByQuotes is supported only by String~ppString
    -- Can't pass a named argument because I want to keep ooRexxShell compatible with official ooRexx.
    if value~hasMethod("ppString") then return value~ppString(surroundByQuotes)
    if .ExtensionDispatcher~isA(.class), .ExtensionDispatcher~hasMethod(value, "ppString") then return .ExtensionDispatcher~ppString(value, surroundByQuotes)
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

    queryManager = .QueryManager~new(queryFilter, .ooRexxShell~routine_stringChunks)
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
    .ooRexxShell~sayCondition(condition("O"), /*shortFormat*/ .false)


::method helpNoQueries class
    use strict arg interpreterContext, queryFilter, debugQueryFilter=.false -- queryFilter is the string after '?'
    queryFilterArgs = .ooRexxShell~stringChunks(queryFilter, .true) -- true: array of StringChunk
    if debugQueryFilter then do
        self~sayCollection(queryFilterArgs)
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
    -- else .ooRexxShell~sayError(text)


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
    say "    < filename: read the file and put each line in the queue."
    say "    color off|on: deactivate|activate the colors."
    say "    color codes off|on: deactivate|activate the display of the color codes."
    say "    debug off|on: deactivate|activate the full trace of the internals of ooRexxShell."
    say "    demo off|on|fast: deactivate|activate the demonstration mode."
    say "    exit: exit ooRexxShell."
    say "    goto <label>: used in a demo script to skip lines, until <label:> (note colon) is reached."
    say "    indent+ | indent-: used by the command < to show the level of inclusion."
    say "    infos off|on|next: deactivate|activate the display of informations after each execution."
    say "    prompt off|on [a[ddress]] [d[irectoy]] [i[nterpret]]: deactivate|activate the display of the prompt components."
    say "    readline off: use the raw parse pull for the input."
    say "    readline on: delegate to the system readline (history, tab completion)."
    say "    reload: exit the current session and reload all the packages/libraries."
    say "    security off: deactivate the security manager. No transformation of commands."
    say "    security on : activate the security manager. Transformation of commands."
    say "    sleep [n] [no prompt]: used in demo mode to pause during n seconds (default" .ooRexxShell~defaultSleepDelay "sec)."
    say "    test regression: activate the regression testing mode."
    say "    trace off|on [d[ispatch]] [f[ilter]] [r[eadline]] [s[ecurity][.verbose]]: deactivate|activate the trace."
    say "    trap off|on [l[ostdigits]] [nom[ethod]] [nos[tring]] [nov[alue]] [s[yntax]]: deactivate|activate the conditions traps."
    if .ooRexxShell~hasTutor then say   "    tutor off|on: deactivate|activate TUTOR (Unicode)."
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
    DOC = .nil
    if .ooRexxShell~rexxHome <> "" then do
        DOC = .file~new("doc", .ooRexxShell~rexxHome)
        if \ DOC~isDirectory then DOC = .nil
    end
    if .nil == DOC, .ooRexxShell~ooRexxHome <> "" then do
        DOC = .file~new("doc", .ooRexxShell~ooRexxHome)
        if \ DOC~isDirectory then DOC = .nil
    end
    if .nil == DOC then DOC = "http://www.oorexx.org/docs"
    select
        when .platform~is("windows") then do
            'start "Rexx Documentation"' '"' || DOC || '"'
        end
        /*
        when (.platform~is("aix") | .platform~is("linux") | .platform~is("sunos")) then do
            -- How to open a directory or a URL?
        end
        */
        when .platform~is("macosx") | .platform~is("darwin") then do
            'open "' || DOC || '"'
        end
        otherwise .ooRexxShell~sayError("See '" || DOC || "'")
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

::method promptSettings class
    use strict arg prompt, input
    parse var input . . rest
    if rest == "" then do
        self~promptAddress = prompt
        self~promptDirectory = prompt
        self~promptInterpreter = prompt
    end
    do arg over .ooRexxShell~stringChunks(rest)
        if "off"~caselessEquals(arg) then prompt = .false
        else if "on"~caselessEquals(arg) then prompt = .true
        else if "address"~caselessAbbrev(arg, 1) then self~promptAddress= prompt
        else if "directory"~caselessAbbrev(arg, 1) then self~promptDirectory = prompt
        else if "interpreter"~caselessAbbrev(arg, 1) then self~promptInterpreter = prompt
        else .ooRexxShell~sayError("Unknown prompt component:" arg)
    end


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
    do arg over .ooRexxShell~stringChunks(rest)
        parse var arg word1 "." rest
        if "off"~caselessEquals(arg) then trace = .false
        else if "on"~caselessEquals(arg) then trace = .true
        else if "dispatchcommand"~caselessAbbrev(arg, 1) then self~traceDispatchCommand = trace
        else if "filter"~caselessAbbrev(arg, 1) then self~traceFilter = trace
        else if "readline"~caselessAbbrev(arg, 1) then self~traceReadline = trace
        else if "securitymanager"~caselessAbbrev(word1, 1) then do
            self~securityManager~traceCommand = trace
            self~securityManager~verbose = .false
            if rest <> "" then do
                if "verbose"~caselessAbbrev(rest, 1) then self~securityManager~verbose = trace
                else .ooRexxShell~sayError("Expected 'v[erbose]' after" quoted(word1".")". Got" quoted(rest))
            end
        end
        -- for convenience: "sv" is shorter than "s.v"
        else if "sv"~caselessEquals(arg) then do
            self~securityManager~traceCommand = trace
            self~securityManager~verbose = trace
        end
        else .ooRexxShell~sayError("Unknown trace argument:" arg)
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
    do arg over .ooRexxShell~stringChunks(rest)
        if "off"~caselessEquals(arg) then trap = .false
        else if "on"~caselessEquals(arg) then trap = .true
        else if "lostdigits"~caselessAbbrev(arg, 1) then self~trapLostdigits= trap
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
    interpretCondition = interpretCondition(rest)
    if interpretCondition \== .true then return .false -- don't do it (whatever the reason: syntax error, interpret error or result not a boolean)
    if word2 == "" then do
        .ooRexxShell~sayError("Missing label")
        return .false
    end
    if isDriveLetter(word2":") then do
        .ooRexxShell~sayError("Can't go to this label, because "word2": is a drive letter")
        return .false
    end
    .ooRexxShell~gotoLabel = word2
    return .true


::method queueFileCommand class
    -- The command "< filename" allows to include the file's lines in the queue.
    -- The file is searched using the method ~findProgram.
    -- Returns .true if no error.

    use strict arg input
    parse var input . args
    results = .ooRexxShell~parseQueueFileArguments(args)
    if .nil == results then return .false
    if results~isA(.array) then do
        filename = results[1]
        substitutions = results[2]
        if \.ooRexxShell~queueFile(filename, .true) then return .false
        return .ooRexxShell~queueFile(filename, .false, substitutions)
    end
    return .true -- here results == .false, which deactivates the '<' command. It's not an error.


::method queueFile class
    -- Remember: if you call this method from the prompt line then the updated
    -- queue is not the ooRexxShell queue used for input, it's the SESSION queue
    -- (search for "rxqueue" in this file to see how these 2 different queues
    -- are managed).

    use strict arg filename, check=.false, substitutions=.nil, directory="", visitedFiles=(.queue~new)
    program = .nil
    if directory \== "" then program = .context~package~findProgram(directory || .file~separator || filename)
    if .nil == program then program = .context~package~findProgram(filename)
    if .nil == program then do
        .ooRexxShell~sayError("File not found:" filename)
        return .false
    end
    if visitedFiles~hasItem(program) then do
        .ooRexxShell~sayError("Recursive inclusion:" filename)
        return .false
    end
    visitedFiles~push(program)
    directory = .file~new(program)~parent
    error = .false
    multiLineComments = .false
    stream = .stream~new(program)
    if \check then do
        queue "indent+"
        fileInfo = "-- Start of file" filename
        box = "-"~copies(fileInfo~length)
        queue box
        queue fileInfo
        queue box
    end
    signal on notready
    do forever
        rawline = stream~linein
        maybeCommand = rawline~left(1, ".") \== " "
        line = rawline~strip
        if line == "*/" then multiLineComments = .false
        else if line == "/*" then multiLineComments = .true
        monoLineComment = line~left(2) == "--"
        parse var line word1 rest
        if \multiLineComments, \monoLineComment, maybeCommand, word1 == "<" then do
            results = .ooRexxShell~parseQueueFileArguments(rest)
            if .nil == results then error = .true
            else if results~isA(.array) then do
                -- Remember: don't overwrite filename and substitutions
                filenameArgument = results[1]
                substitutionsArgument = results[2]
                .ooRexxShell~queueFile(filenameArgument, check, substitutionsArgument, directory, visitedFiles)
                if result == .false then error = .true
            end
            else nop -- here results == .false, which deactivates the '<' command. It's not an error.
        end
        else if \check then queue applySubstitutions(rawline, substitutions)
    end
    notready:
    if \check then do
        fileInfo = "-- End of file" filename
        box = "-"~copies(fileInfo~length)
        queue box
        queue fileInfo
        queue box
        queue "indent-"
    end
    visitedFiles~pull
    stream~close
    return error == .false

    applySubstitutions: procedure
        use strict arg string, substitutions
        if .nil \== substitutions then do
            loop i=1 to substitutions~items by 2
                toReplace = substitutions~at(i)
                replacedBy = substitutions~at(i+1)
                if .nil == toReplace then iterate
                if .nil == replacedBy then iterate
                string = string~caselessChangeStr(toReplace, replacedBy)
            end
        end
        return string


::method parseQueueFileArguments class
    -- returns .nil in case of error
    -- returns .false if a 'when condition' deactivates the '<' command
    -- otherwise returns an array (filename, substitutions)
    use strict arg args
    results = parse_qword_rest(args)
    filename = results[1]
    rest = results[2]
    if filename == "" then do
        .ooRexxShell~sayError("Usage: < filename [substitutions] [when condition]")
        return .nil
    end
    -- Parse the substitution rules: s/text/newtext/ where the character after s can be any character
    substitutions = .queue~new
    do while rest \== ""
        if rest~subchar(1) \== "s" then leave -- it's maybe a 'when condition'
        separator = rest~subchar(2)
        if rest~countStr(separator) < 3 then do
            .ooRexxShell~sayError("Invalid substitution rule. Expected s/text/newtext/. Got" rest)
            return .nil
        end
        parse var rest (rest~left(2)) toReplace (separator) replacedBy (separator) nextRest
        substitutions~append(toReplace)
        substitutions~append(replacedBy)
        rest = nextRest~strip
    end
    -- Optional when condition
    -- Pass an error message related to the substitutions, that will be displayed in case of syntax error
    -- (because both "s/text/newtext/" and "when expression" are candidate)
    interpretCondition = interpretCondition(rest, "Invalid substitution rule. Expected s/text/newtext/.")
    if interpretCondition == .true then return .array~of(filename, substitutions)
    if interpretCondition == .false then return .false -- the 'when condition' deactivates the '<' command
    return .nil -- error


::method stringChunks class
    if .nil <> .ooRexxShell~routine_stringChunks then return .ooRexxShell~routine_stringChunks~callWith(arg(1, "a"))
    -- Poor man's implementation:
    --   quotes are not correctly supported
    --   parameter 'withInfos' not supported, you will never get a list of StringChunk, you will always get a list of strings
    use strict arg string, withInfos=.false
    words = .array~new
    do word over string~subwords
        words~append(unquoted(word))
    end
    -- ignore withInfos, always return an array of strings
    return words


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
    ::attribute hasInterceptedCommand
    ::attribute isEnabled


::method init
   self~hasInterceptedCommand = .false
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

    self~hasInterceptedCommand = .true -- tested by ooRexxShell to decide if RC is displayed
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
    temporarySettingsFile = .ooRexxShell~runtimeDir || .file~separator || "oorexxshell-"SysQueryProcess("PID") || ".ini"
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
        args = .ooRexxShell~stringChunks(command)
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
        -- export BASH_ENV=~/.bash_env
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
        -- export ENV=~/.bash_env
        -- and declare the aliases in this file.
        -- This file is executed when sh is interactive (yes! the opposite of bash...).
        -- The trap command is used to save the current directory of the child process
        -- The 'set -m' command is used to get rid of the message "sh: no job control in this shell" when doing 'cat commands.txt | ooRexxShell', where a command is a system command
        return .array~of(address, "set -m; sh -i -c 'trap_exit () { echo OOREXXSHELL_DIRECTORY=$PWD > "temporarySettingsFile" ; } ; trap trap_exit EXIT ; "command"'") -- the special characters have been already escaped by readline()
    end
    else if address~caselessEquals("zsh") then do
        -- Not supported by executor (yet) nor by ooRexx4. Supported natively by ooRexx5 but this workaround will work as well.
        -- sh needs that the command be surrounded by '"' to not interpret ';' inside the command.
        return .array~of(.ooRexxShell~systemAddress, "zsh -c '"command"'")
    end
    else if address~caselessEquals("pwsh") then do
        -- cmd doesn't support that the command be surrounded by '"'.
        -- sh needs that the command be surrounded by '"' to not interpret ';' inside the command.
        if .platform~is("windows") then return .array~of(.ooRexxShell~systemAddress, "pwsh -command "command)
        else return .array~of(.ooRexxShell~systemAddress, "pwsh -command '"command"'")
    end
    return .array~of(address, command)


-------------------------------------------------------------------------------
::class color
-------------------------------------------------------------------------------

/*
https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
https://ss64.com/nt/syntax-ansi.html
https://en.wikipedia.org/wiki/ANSI_escape_code
*/

::attribute background class set
    expose background background_AES
    use strict arg background
    background_AES = self~ANSI_Escape_Sequence(background, /* isBackground */ .true)

::attribute background class get


::method init class
    .environment~setentry(self~id, self) -- Make the .color class available from the customization file
    self~background = ""


::method select class
    expose background_AES
    use strict arg color, stream=.output

    if \ .ooRexxShell~showColor then return -- you don't want the colors

    background = background_AES
    color = self~ANSI_Escape_Sequence(color)
    if .ooRexxShell~showColorCodes then do
        -- Can't do that in ANSI_Escape_Sequence because background_AES is
        -- calculated only when storing a value, not when using it.
        background = background~changeStr(d2c(27), "ESC")
        color = color~changeStr(d2c(27), "ESC")
    end

    stream~charout(background)
    stream~charout(color)

    stream~flush -- to avoid filtering by filteringStream


::method name2code class private
    /*
    Return -1 if color name unknown
    otherwise return a number of 1 or 2 or 3 digits.
    - 1 digit:  Reset (0), style (1 to 9).
    - 2 digits: Foreground color code (30 to 37), or foreground default color (39).
                The corresponding background color code is foreground + 10.
    - 3 digits: Style (first digit) followed by a foreground color code (next 2 digits).
    */
    use strict arg color

    select
        when color~caselessEquals("reset") then return 0
        when color~caselessEquals("bold") then return 1
        when color~caselessEquals("faint") then return 2
        when color~caselessEquals("italic") then return 3
        when color~caselessEquals("underline") then return 4
        when color~caselessEquals("blinking") then return 5
        when color~caselessEquals("inverse") then return 7
        when color~caselessEquals("hidden") then return 8
        when color~caselessEquals("strikethrough") then return 9
        when color~caselessEquals("black") then return 30
        when color~caselessEquals("bblack") then return 130
        when color~caselessEquals("red") then return 31
        when color~caselessEquals("bred") then return 131
        when color~caselessEquals("green") then return 32
        when color~caselessEquals("bgreen") then return 132
        when color~caselessEquals("yellow") then return 33
        when color~caselessEquals("byellow") then return 133
        when color~caselessEquals("blue") then return 34
        when color~caselessEquals("bblue") then return 134
        when color~caselessEquals("magenta") then return 35
        when color~caselessEquals("bmagenta") then return 135
        when color~caselessEquals("cyan") then return 36
        when color~caselessEquals("bcyan") then return 136
        when color~caselessEquals("white") then return 37
        when color~caselessEquals("bwhite") then return 137
        when color~caselessEquals("default") then return 39
        otherwise return -1
    end


::method ANSI_Escape_Sequence class private
    /*
    Convert a color to an ANSI escape sequence.
    Color format:
        (space* (color_name | black_box)? space*)*
    If a part of the color format is not supported then assume this part is
    already an ANSI escape sequence, to display as-is
    */
    use strict arg color, isBackground = .false
    buffer = .MutableBuffer~new
    loop forever
        wordIndex = color~wordIndex(1)
        if wordIndex == 0 then do
            buffer~append(color) -- empty or spaces only
            leave
        end
        buffer~append(color~left(wordIndex - 1)) -- append the spaces before the 1st word
        parse var color word1 color
        code = self~name2code(word1)
        if code >= 0 then do
            select
                when code~length == 3 then  do
                    style = code~left(1)
                    code = code~substr(2)
                    if isBackground then code += 10
                    buffer~append(d2c(27)"["style";"code"m")                -- Esc[1;30m
                end
                when code~length == 2 then do
                    if isBackground then code += 10
                    buffer~append(d2c(27)"["code"m")                        -- Esc[30m
                end
                when code~length == 1 then buffer~append(d2c(27)"["code"m") -- Esc[1m
                otherwise buffer~append(word1) -- black box
            end
        end
        else buffer~append(word1)
    end
    return buffer~string


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

::method init
    forward class (super) continue

    self~class~current = self -- normally you never call directly a method of .WindowsPlatform, but just in case...


::method which
    -- The order of precedence in locating executable files is given by the PATHEXT environment variable.
    use strict arg filespec
    pathext = environment_string("PATHEXT")~translate(" ", ";")
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


-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

::routine parse_qword_rest public
    -- Parse a quoted string (optional) otherwise parse a word
    -- The double quotes are not supported
    use strict arg string
    string = string~strip
    char1 = string~subchar(1)
    if char1 == '"' | char1 == "'" then parse var string (char1) word1 (char1) rest
    else parse var string word1 rest
    return .array~of(word1, rest~strip)


::routine quoted public
    -- Remember: keep it, because the method .String~quoted is NOT available with standard ooRexx.
    use strict arg string, quote='"'
    return quote || string~changestr(quote, quote~copies(2)) || quote


::routine unquoted public
    -- Remember: keep it, because the method .String~unquoted is NOT available with standard ooRexx.
    use strict arg string, quote='"'
    if string~left(1) == quote & string~right(1) == quote then
        return string~substr(2, string~length - 2)~changeStr(quote~copies(2), quote)
    else
        return string


::routine paren public
    use strict arg string, parenLeft="(", parenRight=")"
    return parenLeft || string || parenRight


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


::routine createDirectory public
    -- Creates the specified directory (and recursively the parents if needed).
    -- Returns 0 if the directory already exists.
    -- Returns 1 if the directory has been created.
    -- Returns -1 if the creation failed because a file (not a directory) with the same name already exists.
    -- Returns -2 if the creation failed for any other reason.
    use strict arg path
    if SysIsFileDirectory(path) then return 0
    if SysIsFile(path) then return -1
    parent = filespec("location", path)
    if parent == path then parent = filespec("location", path~substr(1, path~length - 1))
    parentStatus = createDirectory(parent)
    if parentStatus < 0 then return parentStatus
    if SysMkDir(path) <> 0 then return -2
    return 1


::routine environment_string
    use strict arg varname
    return value(varname,, "ENVIRONMENT")


::routine environment_directory_path
    use strict arg varname
    value = value(varname,, "ENVIRONMENT")
    if value == "" then return value
    dir = .file~new(value)
    if dir~isDirectory then return dir~absolutePath -- normalized path, remove final "/" or "\", if any
    .ooRexxShell~sayError(varname "is not a directory")
    .ooRexxShell~sayError(dir~absolutePath)
    raise syntax 98.900 array("Halt")


::routine interpretCondition public
    -- returns "syntax_error" in case of syntax error (no "when" or no condition)
    -- returns "evaluation_error" in case of error raised when evaluating the condition
    -- otherwise returns .true or .false
    use strict arg whenCondition, otherExpectation=""
    if whenCondition~strip \== "" then do
        parse var whenCondition word1 rest
        if \word1~caselessEquals("when") | rest~strip == "" then do
            if otherExpectation \== "" then do
                .ooRexxShell~sayError(otherExpectation)
                .ooRexxShell~sayError("and / or")
                .ooRexxShell~sayError("Expected 'when' followed by a condition")
                .ooRexxShell~sayError("Got:" word1 rest)
            end
            else .ooRexxShell~sayError("Expected 'when' followed by a condition. Got:" word1 rest)
            return "syntax_error"
        end
        call evaluation rest
        if datatype(result, "O") then return result -- boolean (good)
        if \var("result") then .ooRexxShell~sayError("The 'when expression' did not return a result")
        else .ooRexxShell~sayError("The 'when expression' did not return a boolean. Got:" result~string)
        return .false
    end
    return .true -- no 'when condition'

    evaluation: procedure
        -- Use an inner procedure to let the caller catch the result if the string contains "return [something]"
        -- With official ooRexx, a security manager should be used to intercept the system calls.
        -- I will not do that, but I try to reduce the risks by using a (hopfully) non-existent environment
        use strict arg string
        signal on syntax
        options "NOCOMMANDS" -- to allow "when expression" instead of "when result=expression"
        address "a non existent environment to reduce the risks of executing a system command"
        drop result
        interpret string -- if contains "return" then returns immediatly to the caller
        address -- restore
        if var("result") then return result
        return

        syntax:
        address -- restore
        -- Todo: display filename and line number (if we are executing < "filename")
        .ooRexxShell~sayCondition(condition("O"), /*shortFormat*/ .true)
        return "evaluation_error"
