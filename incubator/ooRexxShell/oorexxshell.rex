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

.platform~initialize

-- Use a security manager to trap the calls to the systemCommandHandler :
-- Windows : don't call directly CreateProcess, to avoid loss of doskey history (prepend "cmd /c")
-- Unix : support aliases (prepend "bash -O expand_aliases -c")
.ooRexxShell~securityManager = .securityManager~new -- make it accessible from command line
shell = .context~package~findRoutine("SHELL")
shell~setSecurityManager(.ooRexxShell~securityManager)

-- Bypass defect 2933583 (fixed in release 4.0.1) : 
-- Must pass the current address (default) because will be reset to system address when entering in SHELL routine
shell~call(arg(1), address())

-- 0 means ok (return 0), anything else means ko (return 1)
return .ooRexxShell~RC <> 0  


-------------------------------------------------------------------------------
::routine SHELL
use strict arg .ooRexxShell~initialArgument, .ooRexxShell~initialAddress

.ooRexxShell~readline = .true -- assign .false if you want only the basic "parse pull" functionality

.ooRexxShell~defaultColor = "white"
.ooRexxShell~errorColor = "bred"
.ooRexxShell~infoColor = "bgreen"
.ooRexxShell~promptColor = "byellow"
.ooRexxShell~traceColor = "yellow"

.ooRexxShell~systemAddress = systemAddress()

.ooRexxShell~interpreters = .Directory~new
.ooRexxShell~interpreters~setEntry("oorexx", "ooRexx")
.ooRexxShell~interpreters~setEntry(.ooRexxShell~initialAddress, .ooRexxShell~initialAddress)
.ooRexxShell~interpreters~setEntry(.ooRexxShell~systemAddress, .ooRexxShell~systemAddress)
.ooRexxShell~interpreters~setEntry(address(), address()) -- maybe the same as systemAddress, maybe not

call loadOptionalComponents

address value .ooRexxShell~initialAddress
.ooRexxShell~interpreter = address()

.ooRexxShell~queuePrivateName = rxqueue("create")
.ooRexxShell~queueInitialName = rxqueue("set", .ooRexxShell~queuePrivateName)

select
    when .ooRexxShell~initialArgument == "" then do
        .ooRexxShell~isInteractive = .true
        call intro
        call main
    end
    otherwise do
        -- One-liner for default address() and exit.
        -- Beware ! It's not ooRexx by default, unless you start the line by the word oorexx. 
        .ooRexxShell~isInteractive = .false
        push unquoted(.ooRexxShell~initialArgument)
        call main
    end
end

call rxqueue "delete", .ooRexxShell~queuePrivateName

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
            when .ooRexxShell~inputrx == "?" then 
                call help
            when .ooRexxShell~inputrx~caselessEquals("exit") then 
                exit
            when .ooRexxShell~inputrx~caselessEquals("interpreters") then
                .ooRexxShell~sayInterpreters
            when .ooRexxShell~inputrx~caselessEquals("traceon") then
                .ooRexxShell~trace(.true)
            when .ooRexxShell~inputrx~caselessEquals("traceoff") then
                .ooRexxShell~trace(.false)
            when .ooRexxShell~inputrx~caselessEquals("debugon") then
                .ooRexxShell~debug = .true
            when .ooRexxShell~inputrx~caselessEquals("debugoff") then
                .ooRexxShell~debug = .false
            when .ooRexxShell~interpreters~hasEntry(.ooRexxShell~inputrx) then do
                -- Change the default interpreter
                .ooRexxShell~interpreter = .ooRexxShell~interpreters~entry(.ooRexxShell~inputrx)
            end
            when .ooRexxShell~interpreters~hasEntry(.ooRexxShell~inputrx~word(1)) then do
                -- The line starts with an interpreter name : use it instead of the default interpreter
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
        if \.ooRexxShell~isInteractive & queued() == 0 then return -- For one-liner, stop loop when queue is empty.
    signal REPL

    
-------------------------------------------------------------------------------
intro: procedure
    parse version version
    .color~select(.ooRexxShell~infoColor)
    say version
    .ooRexxShell~sayInterpreters
    say "? : to invoke ooRexx documentation."
    say "Other commands : exit interpreters traceoff traceon."
    .color~select(.ooRexxShell~defaultColor)
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
    if .ooRexxShell~interpreter~caselessEquals("ooRexx") then prompt ||= "["currentAddress"]"
    prompt ||= "> "
    return prompt
    
    
-------------------------------------------------------------------------------
readline: procedure
    use strict arg prompt
    inputrx = ""
    select
        when queued() == 0 & lines() == 0 & .ooRexxShell~systemAddress~caselessEquals("cmd") & .ooRexxShell~readline then do
            -- I want the doskey macros and filename tab autocompletion... Delegates the input to cmd.
            -- HKEY_CURRENT_USER/Software/Microsoft/Command Processor/CompletionChar = 9
            address value .ooRexxShell~systemAddress
                "(title ooRexxShell) &",
                "(set inputrx=) &",
                "(set /p inputrx="quoted(prompt)") &",
                "(if defined inputrx set inputrx | rxqueue "quoted(.ooRexxShell~queuePrivateName)")"
            address -- restore
            if queued() <> 0 then parse pull "inputrx=" inputrx
        end
        when queued() == 0 & lines() == 0 & .ooRexxShell~systemAddress~caselessEquals("bash") & .ooRexxShell~readline then do
            -- I want all the features of readline when editing my command line (history, tab completion, ...)
            -- Two lines are pushed to rxqueue :
            -- one generated by the internal command 'set', which manages the escaped characters.
            -- one generated by the internal command 'echo', to get the input as-is.
            address value .ooRexxShell~systemAddress
                "set -o noglob ;",
                "set -o history ;",
                "history -r ;",
                "read -r -e -p "quoted(prompt)" inputrx ;",
                "history -s $inputrx ;",
                "history -a ;",
                "history -w ;",
                "set | grep ^inputrx= | rxqueue "quoted(.ooRexxShell~queuePrivateName)" ;",
                "echo -E $inputrx | rxqueue "quoted(.ooRexxShell~queuePrivateName)
            address -- restore
            if queued() <> 0 then do
                parse pull "inputrx=" inputrx1 -- output of 'set'
                parse pull inputrx2 -- output of 'echo'
                if .ooRexxShell~traceReadline then do
                    .color~select(.ooRexxShell~traceColor)
                    say "[readline] inputrx1=" inputrx1
                    say "[readline] inputrx2=" inputrx2
                    .color~select(.ooRexxShell~defaultColor)
                end
                
                -- If inputrx1 contains more than one word, then it has been surrounded by quotes :
                -- Ex : echo, 'echo a', ls, 'ls -la'
                -- Remove these quotes.
                inputrx1 = unquoted(inputrx1, "'")
                
                -- Select the most appropriate line, depending on the target interpreter
                interpreter = .ooRexxShell~interpreter -- default
                if .ooRexxShell~interpreters~hasEntry(inputrx1~word(1)) then interpreter = inputrx1~word(1) -- temporary
                if interpreter~caselessEquals("bash") then inputrx = inputrx1
                else inputrx = inputrx2
            end
        end
        otherwise do
            call charout ,prompt
            parse pull inputrx -- Input keyboard or queue.
        end
    end
    if .ooRexxShell~traceReadline then do
        .color~select(.ooRexxShell~traceColor)
        say "[readline] inputrx=" inputrx
        .color~select(.ooRexxShell~defaultColor)
    end
    return inputrx

        
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
quoted: procedure
    use strict arg string, quote='"'
    return quote || string || quote
    

-------------------------------------------------------------------------------
unquoted: procedure
    use strict arg string, quote='"'
    if string~left(1) == quote & string~right(1) == quote then
        return string~substr(2, string~length - 2)
    else
        return string
    

-------------------------------------------------------------------------------
haltHandler:
    .color~select(.ooRexxShell~infoColor)
    say "Halt disabled."
    .color~select(.ooRexxShell~defaultColor)
    return


-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or routine or method !
-- Moreover don't call it, you must jump to (signal) it...
dispatchCommand:
    call rxqueue "set", .ooRexxShell~queueInitialName -- Reactivate the initial queue, for the command evaluation
    if .ooRexxShell~commandInterpreter~caselessEquals("ooRexx") then
        signal interpretCommand -- don't call
    else 
        signal addressCommand -- don't call
    return_to_dispatchCommand:
    call rxqueue "set", .ooRexxShell~queuePrivateName -- Back to the private ooRexxShell queue
    signal CONTINUE_REPL
    

-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or routine or method !
-- Any variable created by interpret would not be available to the next interpret,
-- because not created in the same context.
-- Moreover don't call it, you must jump to (signal) it...
interpretCommand:
    if .ooRexxShell~traceDispatchCommand then do
        .color~select(.ooRexxShell~traceColor)
        say "[interpret] command=" .ooRexxShell~command
        .color~select(.ooRexxShell~defaultColor)
    end
    RC = 0
    signal on syntax name interpretError
    interpret .ooRexxShell~command
    signal off syntax
    if RC <> 0 & .ooRexxShell~isInteractive then do
        .color~select(.ooRexxShell~infoColor)
        say .ooRexxShell~command
        .color~select(.ooRexxShell~errorColor)
        say "RC=" RC
        .color~select(.ooRexxShell~defaultColor)
    end
    signal return_to_dispatchCommand
    
    interpretError:
    .color~select(.ooRexxShell~infoColor)
    say .ooRexxShell~command
    .color~select(.ooRexxShell~errorColor)
    say condition("O")~message
    RC = condition("O")~code
    if RC <> 0 then say "RC=" RC
    .color~select(.ooRexxShell~defaultColor)
    signal return_to_dispatchCommand


-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or routine or method !
-- Moreover don't call it, you must jump to (signal) it...
addressCommand:
    address value .ooRexxShell~commandInterpreter
    (.ooRexxShell~command)
    address -- restore previous
    if RC <> 0 & .ooRexxShell~isInteractive then do
        .color~select(.ooRexxShell~infoColor)
        say .ooRexxShell~command
        .color~select(.ooRexxShell~errorColor)
        say "RC=" RC
        .color~select(.ooRexxShell~defaultColor)
    end
    signal return_to_dispatchCommand
    
    
-------------------------------------------------------------------------------
-- Load optional packages/libraries
-- Remember : don't implement that as a procedure or routine or method !
loadOptionalComponents:
    if .platform~is("windows") then do
        call loadPackage("oodialog.cls")
        call loadPackage("winsystm.cls")
    end
    if loadLibrary("hostemu") then .ooRexxShell~interpreters~setEntry("hostemu", "HostEmu")
    call loadPackage("mime.cls")
    call loadPackage("rxftp.cls")
    call loadLibrary("rxmath")
    call loadPackage("rxregexp.cls")
    call loadPackage("smtp.cls")
    call loadPackage("socket.cls")
    call loadPackage("streamsocket.cls")
    call loadPackage("BSF.CLS")
    call loadPackage("UNO.CLS")
    call loadPackage("rgf_util2.rex") -- http://wi.wu.ac.at/rgf/rexx/orx20/rgf_util2.rex
    return
    

-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or routine or method !
loadPackage:
    use strict arg filename
    signal on syntax name loadPackageError
    .context~package~loadPackage(filename)
    return .true
    loadPackageError:
    return .false

    
-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or routine or method !
loadLibrary:
    use strict arg filename
    signal on syntax name loadLibraryError
    return .context~package~loadLibrary(filename)
    loadLibraryError:
    return .false

    
-------------------------------------------------------------------------------
::class ooRexxShell
-------------------------------------------------------------------------------
::attribute command class -- The current command to interpret, can be a substring of inputrx
::attribute commandInterpreter class -- The current interpreter, can be the first word of inputrx, or the default interpreter
::attribute initialAddress class -- The initial address on startup, not necessarily the system address (can be "THE")
::attribute initialArgument class -- The command line argument on startup
::attribute inputrx class -- The current input to interpret
::attribute interpreter class -- One of the environments in 'interpreters' or the special value "ooRexx"
::attribute interpreters class -- The set of interpreters that can be activated
::attribute isInteractive class -- Are we in interactive mode, or are we executing a one-liner ?
::attribute prompt class -- The prompt to display
::attribute RC class -- Return code from the last executed command
::attribute readline class -- When .true, the readline functionality is activated (history, tab expansion...) 
::attribute securityManager class
::attribute queuePrivateName class -- Private queue for no interference with the user commands
::attribute queueInitialName class -- Backup the initial external queue name (probably "SESSION")
::attribute systemAddress class -- "CMD" under windows, "bash" under linux, etc...

::attribute defaultColor class
::attribute errorColor class
::attribute infoColor class
::attribute promptColor class
::attribute traceColor class

::attribute traceReadline class
::attribute traceDispatchCommand class

::attribute debug class

::method init class
    self~traceReadline = .false
    self~traceDispatchCommand = .false
    self~debug = .false

    
::method sayInterpreters class
    do interpreter over .ooRexxShell~interpreters~allIndexes~sort 
        say interpreter~lower" : to activate the ".ooRexxShell~interpreters[interpreter]" interpreter."
    end
    

::method trace class
    use strict arg trace
    self~traceReadline = trace
    self~traceDispatchCommand = trace
    self~securityManager~traceCommand = trace
    
    
-------------------------------------------------------------------------------
::class securityManager 
-------------------------------------------------------------------------------
::attribute isRunningCommand
::attribute traceCommand


::method init
   self~isRunningCommand = .false
   self~traceCommand = .false
   
   
::method unknown
    return 0

    
::method command
    use arg info
    if self~traceCommand then do
        .color~select(.ooRexxShell~traceColor)
        say "[securityManager] address=" info~address
        say "[securityManager] command=" info~command
        .color~select(.ooRexxShell~defaultColor)
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
        if .RegularExpression~new("[:ALPHA:]:")~~match(command)~position == 2 & command~length == 2 then return command -- change drive
        args = .platform~string2args(command)
        if args[1]~caselessEquals("cmd") then return command -- already prefixed by "cmd ..."
        if args[1]~caselessEquals("start") then return command -- already prefixed by "start ..."
        exepath = .platform~which(args[1])
        exefullpath = qualify(exepath)
        if .platform~subsystem(exefullpath) == 2 then return 'start "" 'command -- Don't wait when GUI application
        return 'cmd /c "'command'"'
        
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
        return "bash -O expand_aliases -c 'history -r ; "command"'" -- the special characters have been already escaped by readline()
    end
    return command


-------------------------------------------------------------------------------
::class color
-------------------------------------------------------------------------------
::method select class
    use strict arg color
    select
        when .platform~is("windows") then do
            select
                when color~caselessEquals("white") then .platform~SetConsoleTextColor(7)
                when color~caselessEquals("bwhite") then .platform~SetConsoleTextColor(15)
                when color~caselessEquals("red") then .platform~SetConsoleTextColor(4)
                when color~caselessEquals("bred") then .platform~SetConsoleTextColor(12)
                when color~caselessEquals("green") then .platform~SetConsoleTextColor(2)
                when color~caselessEquals("bgreen") then .platform~SetConsoleTextColor(10) 
                when color~caselessEquals("yellow") then .platform~SetConsoleTextColor(6) -- (called brown by by ctext)
                when color~caselessEquals("byellow") then .platform~SetConsoleTextColor(14) -- (called yellow by ctext)
                otherwise nop
            end
        end
        when .platform~is("linux") then do
            select
                when color~caselessEquals("white") then call charout , d2c(27)"[m"
                when color~caselessEquals("bwhite") then call charout , d2c(27)"[1m"
                when color~caselessEquals("red") then call charout , d2c(27)"[31m"
                when color~caselessEquals("bred") then call charout , d2c(27)"[1;31m"
                when color~caselessEquals("green") then call charout , d2c(27)"[32m"
                when color~caselessEquals("bgreen") then call charout , d2c(27)"[1;32m"
                when color~caselessEquals("yellow") then call charout , d2c(27)"[33m"
                when color~caselessEquals("byellow") then call charout , d2c(27)"[1;33m"
                otherwise nop
            end
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
located above the GCI source directory, which contains :

#include "<your path to> rexx.h"
typedef void* PVOID ;
# define APIRET ULONG
typedef CONST char *PCSZ ;

Other change in gci-win32.def:
LIBRARY gci ; INITINSTANCE
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
::constant ULONG "unsigned32"   -- typedef unsigned long       ULONG;
::constant USHORT "unsigned16"  -- typedef unsigned short      USHORT;
::constant UCHAR "unsigned8"    -- typedef unsigned char       UCHAR;
::constant DWORD "unsigned32"   -- typedef unsigned long       DWORD;
::constant BOOL "integer32"     -- typedef int                 BOOL;
::constant BYTE "unsigned8"     -- typedef unsigned char       BYTE;
::constant WORD "unsigned16"    -- typedef unsigned short      WORD;
::constant FLOAT "float32"      -- typedef float               FLOAT;
::constant INT "integer32"      -- typedef int                 INT;
::constant UINT "unsigned32"    -- typedef unsigned int        UINT;
::constant HANDLE "integer"     -- typedef void                *HANDLE; -- todo : must be integer64 under win64, is it managed by GCI ?


::method init class
    if .GCI~isInstalled then do
        self~defineSetConsoleTextAttribute
        self~defineGetStdHandle
    end
    
    
::method init
    forward class (super) continue
    self~class~current = self -- normally you never call directly a method of .WindowsPlatform, but just in case...
    
    
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
    
    
::method string2args
    -- Converts a string to an array of arguments.
    -- Arguments are separated by whitespaces (anything < 32) and can be quoted.
    use strict arg string

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
        loop label current_argument
            if string~subchar(i) == '"' then do
                -- Chunk surrounded by quotes : whitespaces are kept, double occurrence of quotes are replaced by a single embedded quote  
                loop label quoted_chunk
                    i += 1
                    if i > string~length then return args~~append(current~string)
                    select
                        when string~subchar(i) == '"' & string~subchar(i+1) == '"' then do
                            current~append('"')
                            i += 1
                        end
                        when string~subchar(i) == '"' then do
                            i += 1
                            leave quoted_chunk
                        end
                        otherwise current~append(string~subchar(i)) 
                    end
                end quoted_chunk
            end
            if string~subchar(i) <= " " then do
                args~append(current~string)
                leave current_argument
            end
            -- Chunk not surrounded by quotes : ends when a whitespace or quote is reached 
            loop
                if i > string~length then return args~~append(current~string)
                if string~subchar(i) <= " " | string~subchar(i) == '"' then leave
                current~append(string~subchar(i))
                i += 1
            end
        end current_argument
    end arguments
    return args
    
    
::method subsystem
    -- Return the id of the subsystem needed to execute the executable.
    -- Remember : GetBinaryType does not return this information.
    -- Rexx adaptation of :
    -- http://support.microsoft.com/?scid=kb%3Ben-us%3B90493&x=13&y=16
    /*
    #define IMAGE_SUBSYSTEM_UNKNOWN              0   // Unknown subsystem.
    #define IMAGE_SUBSYSTEM_NATIVE               1   // Image doesn't require a subsystem.
    #define IMAGE_SUBSYSTEM_WINDOWS_GUI          2   // Image runs in the Windows GUI subsystem.
    #define IMAGE_SUBSYSTEM_WINDOWS_CUI          3   // Image runs in the Windows character subsystem.
    ...
    More values defined in winnt.h
    */
    use strict arg exename
    signal on notready
    stream = .Stream~new(exename)
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
-- Helpers
-------------------------------------------------------------------------------
::routine unsigned32
    use strict arg number
    numeric digits 10
    if number >= 0 then return number
    return 4294967296 + number
    
    
::routine littleendian2integer16
    use strict arg string
    byte2 = string~subchar(2)~c2d
    byte1 = string~subchar(1)~c2d
    integer16 = 256 * byte2 + byte1
    if byte2 >= 128 then return integer16 - 65536
    return integer16
    
    
::routine littleendian2integer32
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

