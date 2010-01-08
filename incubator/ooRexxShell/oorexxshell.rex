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
This shell supports several interpreters :
- ooRexx itself
- the system address (cmd under Windows, bash under Linux)
- any other external environment (you need to modify this script, search for hostemu for an example).
The prompt indicates which interpreter is active.
By default the shell is in current address mode.
When not in ooRexx mode, you enter raw commands that are passed directly to the external environment.
When in ooRexx mode, you have a shell identical to rexxtry.
You switch from an interpreter to an other one by entering its name alone.

Example (Windows) :
CMD> dir | find ".dll"                              raw command, no need of surrounding quotes
CMD> cd c:\program files
CMD> say 1+2                                        error, the ooRexx interpreter is not active here
CMD> oorexx say 1+2                                 you can temporarily select an interpreter
CMD> oorexx                                         switch to the ooRexx interpreter
ooRexx[CMD] 'dir oorexx | find ".dll"'              here you need to surround by quotes
ooRexx[CMD] cmd dir oorexx | find ".dll"            unless you temporarily select cmd 
ooRexx[CMD] say 1+2                                 3
ooRexx[CMD] address myHandler                       selection of the "myHandler" subcommand handler (hypothetic, just an example)
ooRexx[MYHANDLER] 'myCommand myArg'                 an hypothetic command, must be surrounded by quotes because we are in ooRexx mode.
ooRexx[MYHANDLER] myhandler                         switch to the MYHANDLER interpreter
MYHANDLER> myCommand myArg                          an hypothetic command, no need of quotes
MYHANDLER> exit                                     the exit command is supported whatever the interpreter
*/

call on halt name haltHandler

.ooRexxShell~defaultColor = "white"
.ooRexxShell~errorColor = "bred"
.ooRexxShell~infoColor = "bgreen"
.ooRexxShell~promptColor = "yellow"

.ooRexxShell~systemAddress = systemAddress()

.ooRexxShell~interpreters = .Directory~new
.ooRexxShell~interpreters~setEntry("oorexx", "ooRexx")
.ooRexxShell~interpreters~setEntry(.ooRexxShell~systemAddress, .ooRexxShell~systemAddress)
.ooRexxShell~interpreters~setEntry(address(), address()) -- maybe the same as systemAddress, maybe not

-- Load optional packages/libraries
if .platform~is("windows") then do
    .context~package~loadPackage("bsf.cls")
    .context~package~loadPackage("oodialog.cls")
    .context~package~loadPackage("uno.cls")
    .context~package~loadPackage("winsystm.cls")
end
if .context~package~loadLibrary("hostemu") then .ooRexxShell~interpreters~setEntry("hostemu", "HostEmu")
.context~package~loadPackage("rxftp.cls")
.context~package~loadLibrary("rxmath")
.context~package~loadPackage("socket.cls")

.ooRexxShell~interpreter = address()

-- Use the security manager to trap the calls to the systemCommandHandler :
-- Windows : don't call directly CreateProcess, to avoid loss of doskey history (prepend "cmd /c")
-- Unix : support aliases (prepend "bash -O expand_aliases -c")
.ooRexxShell~securityManager = .securityManager~new -- make it accessible from command line
.Context~package~setSecurityManager(.ooRexxShell~securityManager)

parse arg argrx
select
    when argrx == "" then do
        .ooRexxShell~isInteractive = .true
        call intro
        call main
    end
    otherwise do
        -- One-liner for default address() and exit.
        -- Beware ! It's not ooRexx by default, unless you start the line by the word oorexx. 
        .ooRexxShell~isInteractive = .false
        push argrx
        call main
    end
end

return


-------------------------------------------------------------------------------
main: procedure

    -- trace i
    history = "" -- No history by default
	
    REPL:
    do forever
        .ooRexxShell~prompt = ""
        if .ooRexxShell~isInteractive then .ooRexxShell~prompt = prompt(address())
        .ooRexxShell~inputrx = readline(.ooRexxShell~prompt)~strip
        if history <> "" then call updateHistory .ooRexxShell~inputrx
        select
            when .ooRexxShell~inputrx == "?" then 
                call help
            when .ooRexxShell~inputrx~caselessEquals("exit") then 
                exit
            when .ooRexxShell~inputrx~caselessEquals("interpreters") then
                .ooRexxShell~sayInterpreters
            when .ooRexxShell~interpreters~hasEntry(.ooRexxShell~inputrx) then do
                -- Change the default interpreter
                .ooRexxShell~interpreter = .ooRexxShell~interpreters~entry(.ooRexxShell~inputrx)
            end
            when .ooRexxShell~interpreters~hasEntry(.ooRexxShell~inputrx~word(1)) then do
                -- The line starts with an interpreter name : use it instead of the default interpreter
                .ooRexxShell~commandInterpreter = .ooRexxShell~interpreters~entry(.ooRexxShell~inputrx~word(1))
                .ooRexxShell~command = .ooRexxShell~inputrx~substr(.ooRexxShell~inputrx~wordIndex(2))
                call dispatchCommand
            end
            otherwise do
                -- Interpret the line with the default interpreter
                .ooRexxShell~commandInterpreter = .ooRexxShell~interpreter
                .ooRexxShell~command = .ooRexxShell~inputrx
                call dispatchCommand
            end
        end
        if \.ooRexxShell~isInteractive & queued() == 0 then leave -- For one-liner, stop loop when queue is empty.
    end
    return

    
-------------------------------------------------------------------------------
intro: procedure
    parse version version
    .color~select(.ooRexxShell~infoColor)
    say version
    say "interpreters : to get the list of available interpreters."
    .ooRexxShell~sayInterpreters
    say "? : to invoke documentation for ooRexx."
    say "exit : to exit from the ooRexxShell."
    .color~select(.ooRexxShell~defaultColor)
    return


-------------------------------------------------------------------------------
prompt: procedure
    use strict arg systemAddress
    .color~select(.ooRexxShell~promptColor)
    say
    say directory()
    .color~select(.ooRexxShell~defaultColor)
    -- No longer display the prompt, return it and let readline display it
    prompt = .ooRexxShell~interpreter
    if .ooRexxShell~interpreter~caselessEquals("ooRexx") then prompt ||= "["systemAddress"]"
    prompt ||= "> "
    return prompt
    
    
-------------------------------------------------------------------------------
readline: procedure
    use strict arg prompt
    inputrx = ""
    select
        when queued() == 0 & lines() == 0 & .ooRexxShell~systemAddress~caselessEquals("cmd") then do
            -- I want the doskey macros and filename tab autocompletion... Delegates the input to cmd.
            address value .ooRexxShell~systemAddress
            "(title ooRexxShell) & (set inputrx=) & (set /p inputrx="quoted(prompt)") & (if defined inputrx set inputrx | rxqueue)"
            address -- restore
            if queued() <> 0 then parse pull "inputrx=" inputrx
        end
        when queued() == 0 & lines() == 0 & .ooRexxShell~systemAddress~caselessEquals("bash") then do
            -- I want all the features of readline when editing my command line (history, tab completion, ...)
            -- Ok, I have the editing capabilities of readline, but not yet successful for the history...
            -- Must use explicitely bash because, under linux, system("a command") delegates to /bin/sh
            -- and /bin/sh does not activate the history (I think).
            address value .ooRexxShell~systemAddress
            "bash -c '(set -o noglob ; set -o history ; history -a ; shopt -s histappend ; shopt -s expand_aliases ; read -e -p "quoted(prompt)" ; echo -E $REPLY) | rxqueue'"
            address -- restore
            if queued() <> 0 then parse pull inputrx
        end
        otherwise do
            call charout ,prompt
            parse pull inputrx -- Input keyboard or queue.
        end
    end
    return inputrx

        
-------------------------------------------------------------------------------
updateHistory: procedure expose history
    use strict arg command
    signal on syntax name badHistory
    rcrx=lineout(history, command)
    if rcrx <> 0 then do
        -- Catch non-syntax error from lineout.
        .color~select(.ooRexxShell~errorColor)
        say "Error on history=" history "', resetting to ''."
        .color~select(.ooRexxShell~defaultColor)
        history = ""
        return
    end
    call lineout history -- flush (in fact close) to see immediatly the output in the file
    return

    badHistory:
    .color~select(.ooRexxShell~errorColor)
    say "Invalid 'history' value '" history "', resetting to ''."
    .color~select(.ooRexxShell~defaultColor)
    history = ""
    return


-------------------------------------------------------------------------------
help: procedure
    -- The current address can be anything, not necessarily the system address.
    -- Switch to the system address
    address value .ooRexxShell~systemAddress
    select
        when .platform~is("windows") then do
            /* issue the pdf as a command using quotes because the install dir may contain blanks */
            'start "Rexx Online Documentation"' '"' || value("REXX_HOME",,"ENVIRONMENT") || "\doc\rexxref.pdf" || '"'
        end
        when .platform~is("aix") | .platform~is("linux") | .platform~is("sunos") then do
            'acroread /opt/oorexx/doc/rexxref.pdf&'
        end
        otherwise do
            say .platform~name "has no online help for ooRexx."
        end
    end
    address -- restore
    return


-------------------------------------------------------------------------------
-- Don't know how to avoid these hardcoded values...
-- 'rexx -e "say address()"' would work IF the default address was the right one
-- to execute the command. But in THE (for example), the default address is THE,
-- and that command wouldn't work.
systemAddress: procedure
    select
        when .platform~is("windows") then return "cmd"
        -- From here, calculated like SYSINITIALADDRESS in utilities\rexx\platform\unix\rexx.cpp
        when .platform~is("aix") then return "ksh"
        when .platform~is("sunos") then return "sh"
        otherwise return "bash"
    end

-------------------------------------------------------------------------------
quoted: procedure
    use strict arg string
    return '"'string'"'
    

-------------------------------------------------------------------------------
haltHandler:
    .color~select(.ooRexxShell~infoColor)
    say "Halt disabled."
    .color~select(.ooRexxShell~defaultColor)
    return


-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or method !
dispatchCommand:
    if .ooRexxShell~commandInterpreter~caselessEquals("ooRexx") then
        call interpretCommand
    else 
        call addressCommand
    return
    

-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or method !
-- Any variable created by interpret would not be available to the next interpret,
-- because not created in the global context.
interpretCommand:
    RC = 0
    signal on syntax name interpretError
    interpret .ooRexxShell~command
    signal off syntax
    if RC <> 0 then do
        .color~select(.ooRexxShell~infoColor)
        say .ooRexxShell~command
        .color~select(.ooRexxShell~errorColor)
        say "RC=" RC
        .color~select(.ooRexxShell~defaultColor)
    end
    return
    
    interpretError:
    .color~select(.ooRexxShell~infoColor)
    say .ooRexxShell~command
    .color~select(.ooRexxShell~errorColor)
    say condition("O")~message
    RC = condition("O")~code
    if RC <> 0 then say "RC=" RC
    .color~select(.ooRexxShell~defaultColor)
    return


-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or method !
addressCommand:
    if .ooRexxShell~commandInterpreter~caselessEquals(systemAddress()) then do
        -- Here we call the systemCommandHandler within the context of a method.
        -- It's ok because no risk of rexx variable creation/update.
        -- Will be caught by the security manager, to adjust the command, if needed.
        RC = .ooRexxShell~addressCommand(.ooRexxShell~commandInterpreter, .ooRexxShell~command)
    end
    else do
        -- Here we call the subCommandHandler within the global context.
        -- Any created/updated variable will be seen from the global context (we need that).
        -- Not caught by the security manager.
        address value .ooRexxShell~commandInterpreter
        (.ooRexxShell~command)
        address -- restore previous
        if RC <> 0 then do
            .color~select(.ooRexxShell~infoColor)
            say .ooRexxShell~command
            .color~select(.ooRexxShell~errorColor)
            say "RC=" RC
            .color~select(.ooRexxShell~defaultColor)
        end
    end
    return
    
    
-------------------------------------------------------------------------------
::class ooRexxShell
-------------------------------------------------------------------------------
::attribute command class -- The current command to interpret, can be a substring of inputrx
::attribute commandInterpreter class -- The current interpreter, can be the first word of inputrx, or the default interpreter
::attribute inputrx class -- The current input to interpret
::attribute interpreter class -- One of the environments in 'interpreters' or the special value "ooRexx"
::attribute interpreters class -- The set of interpreters that can be activated
::attribute isInteractive class -- Are we in interactive mode, or are we executing a one-liner ?
::attribute prompt class -- The prompt to display
::attribute securityManager class
::attribute systemAddress class -- "CMD" under windows, "bash" under linux, etc...

::attribute defaultColor class
::attribute errorColor class
::attribute infoColor class
::attribute promptColor class


::method sayInterpreters class
    use strict arg textIndent=""
    do interpreter over .ooRexxShell~interpreters~allIndexes~sort 
        say interpreter~lower" : to activate the ".ooRexxShell~interpreters[interpreter]" interpreter."
    end
    

::method traceSystemCommand
    use strict arg trace
    self~securityManager~traceCommand = trace
    
    
-------------------------------------------------------------------------------
-- Remember : MUST be a method to let the command be caught by the security manager.
-- If not caught then the doskey history won't work...
::method addressCommand class
    use strict arg address, command
    address value address
    command
    address -- restore previous
    if RC <> 0 then do
        .color~select(.ooRexxShell~infoColor)
        say command
        .color~select(.ooRexxShell~errorColor)
        say "RC=" RC
        .color~select(.ooRexxShell~defaultColor)
    end
    return RC
    

-------------------------------------------------------------------------------
::class securityManager 
-------------------------------------------------------------------------------
::attribute isRunningCommand
::attribute traceCommand


::method init
   self~isRunningCommand = .false
   self~traceCommand = .false
   
   
::method command
    use arg info
    if self~traceCommand then do
        say "[securityManager] command=" info~command
        say "[securityManager] address=" info~address
    end
    if self~isRunningCommand then return 0 -- recursive call, delegate to system 
    command = self~adjustCommand(info~address, info~command)
    if command == info~command then return 0 -- command not impacted, delegate to system
    self~isRunningCommand = .true
        address value info~address
        command
        info~rc = RC
        address -- restore previous
    self~isRunningCommand = .false
    return 1

    
::method environment
    return 0

    
::method call
    return 0

    
::method local
    return 0

    
::method adjustCommand
    use strict arg address, command
    if address~caselessEquals("cmd") then do
        -- [WIN32] Bypass a problem with doskey history : 
        -- When a command is directly executable (i.e. passed without "cmd /c" to CreateProcess
        -- in SystemCommands.cpp) then the history is cleared...
        -- So add "cmd /c" in front of the command...
        -- But I don't want it for the commands directly managed by the systemCommandHandler.
        if command~caselessPos("set ") == 1 then return command -- variable assignment
        if command~caselessPos("cd ") == 1 then return command -- change directory
        if .RegularExpression~new("[:ALPHA:]:")~~match(command)~position == 2 then return command -- change drive
        if command~word(1)~caselessEquals("cmd") then return command -- already prefixed by "cmd ..."
        return "cmd /c" command -- no need of surrounding quotes
    end
    else if address~caselessEquals("bash") then do
        -- If directly managed by the systemCommandHandler then don't add bash in front of the command
        if command~caselessEquals("cd") == 1 then return command -- home directory
        if command~caselessPos("cd ") == 1 then return command -- change directory
        if command~caselessPos("set ") == 1 then return command -- variable assignment
        if command~caselessPos("unset ") == 1 then return command -- variable unassignment
        if command~caselessPos("export ") == 1 then return command -- variable assignment
        if command~word(1)~caselessEquals("bash") then return command -- already prefixed by "bash ..."
        -- Expands the aliases, assuming you have defined them...
        -- One way to define them is to do :
        -- export BASH_ENV=~/bash_env
        -- and declare the aliases in this file.
        return "bash -O expand_aliases -c '"escaped(command)"'"
    end
    return command

    escaped: procedure
        use strict arg string
        -- todo
        return string
    

-------------------------------------------------------------------------------
::class color
-------------------------------------------------------------------------------

::method select class
    use strict arg color
    select
        when .platform~is("windows") then do
            -- The current address can be anything, not necessarily the system address.
            -- Switch to the system address
            address value .ooRexxShell~systemAddress
            -- You can get ctext here : http://dennisbareis.com/freew32.htm
            if SysSearchPath("path", "ctext.exe") <> "" then do
                'ctext {'color'}'
            end
            address -- restore
        end
        when .platform~is("linux") then do
            select
                when color~caselessEquals("white") then call charout , d2c(27)"[m"
                when color~caselessEquals("bwhite") then call charout , d2c(27)"[1m"
                when color~caselessEquals("red") then call charout , d2c(27)"[31m"
                when color~caselessEquals("bred") then call charout , d2c(27)"[1;31m"
                when color~caselessEquals("green") then call charout , d2c(27)"[32m"
                when color~caselessEquals("bgreen") then call charout , d2c(27)"[1;32m"
                when color~caselessEquals("brown") then call charout , d2c(27)"[33m"
                when color~caselessEquals("yellow") then call charout , d2c(27)"[1;33m"
                otherwise nop
            end
        end
        otherwise nop
    end


-------------------------------------------------------------------------------
::class platform
-------------------------------------------------------------------------------
::method is class
    use strict arg name
    return self~name == name
    
    
::method name class
    parse source sysrx .
    select
        when sysrx~caselessAbbrev("windows") then return "windows"
        when sysrx~caselessAbbrev("aix") then return "aix"
        when sysrx~caselessAbbrev("sunos") then return "sunos"
        when sysrx~caselessAbbrev("linux") then return "linux"
        otherwise return sysrx~word(1)~lower
    end


-------------------------------------------------------------------------------
::requires "rxregexp.cls"

