/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 2007-2009 Rexx Language Association. All rights reserved.    */
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

/*  oorexxtry.rex  */
/*
What:   21st Century version of Rexxtry
Who:    Lee Peedin
See documentation for version control

10/04/07    Extended fileNameDialog mask for open (*.*)
10/05/07    Added charout method to sayCatcher class
            Added lineout method to sayCatcher class

10/15/07    Directives now work - return values aren't captured
10/16/07    Added header to copy all

11/29/07    Modified ~getText for occasions when lines should not be stripped.
            Place in the incubator

04/19/09    Removed deprecated createFont() and replaced it with createFontEx().
04/19/09    Enhanced the menu to use check marks for font name, size, and silent.
*/

    parse arg isDefault
    .local~useDefault = .false
    if isDefault~translate = 'DEFAULT' then
        .local~useDefault = .true

    -- Default code page UTF-8 when using wide-char oodialog (i.e if setCodePage available)
    -- To investigate : if I change the code page to 65001 from the "Code" area then at the next
    -- run, some characters like russian or japanese are not displayed correctly.
    -- At the second run, everything is ok...
    -- By setting the code page here, I'm sure it works always.
    .local~ooRexx.wcharOOdialog = .false
    signal on any name after.setCodePage
    call setCodePage 65001 -- UTF-8 -- This routine is available only with wide-char ooDialog
    .local~ooRexx.wcharOOdialog = .true
    after.setCodePage:

    call LoadEnvironment                        -- Set up the environment to work with
    .platform~initialize
    call LoadOptionalComponents
    code = .oort_dialog~new()                   -- Create the dialog
    if code~initCode \= 0 then
        do
            call errorDialog 'Error creating code dialog. initCode:' code~initCode
            exit
        end
    say
    say "This console will receive the output of your system commands."
    say "Try 'dir' for example."
    say

    -- In case of error, must end any running coactivity, otherwise the program doesn't terminate
    signal on any name error

    code~Execute('ShowTop')                     -- Execute the dialog

    error:
    if .local~ooRexx.isExtended then .Coactivity~endAll

    code~DeInstall                              -- Finished, so deInstall
exit

-------------------------------------------------------------------------------
-- Load optional packages/libraries
-- Remember : don't implement that as a procedure or routine or method !
loadOptionalComponents:
    call loadLibrary("hostemu")
    call loadPackage("mime.cls")
    call loadPackage("rxftp.cls")
    call loadLibrary("rxmath")
    call loadPackage("rxregexp.cls")
    call loadPackage("regex/regex.cls")
    call loadPackage("smtp.cls")
    call loadPackage("socket.cls")
    call loadPackage("streamsocket.cls")
    call loadPackage("pipeline/pipe.rex")
    call loadPackage("ooSQLite.cls")
    call loadPackage("rgf_util2/rgf_util2.rex") -- http://wi.wu.ac.at/rgf/rexx/orx20/rgf_util2.rex
    .local~ooRexx.hasBsf = loadPackage("BSF.CLS")
    call loadPackage("UNO.CLS")
    .local~ooRexx.isExtended = .true
    if \loadPackage("extension/extensions.cls") then do -- requires jlf sandbox ooRexx
        .local~ooRexx.isExtended = .false
        call loadPackage("extension/std/extensions-std.cls") -- works with standard ooRexx, but integration is weak
    end
    if .local~ooRexx.isExtended then do
        call loadPackage("pipeline/pipe_extension.cls")
        call loadPackage("rgf_util2/rgf_util2_wrappers.rex")
    end

    return


-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or routine or method !
loadPackage:
    use strict arg filename
    signal on syntax name loadPackageError
    .context~package~loadPackage(filename)
    say "loadPackage OK for" filename
    return .true
    loadPackageError:
    say "loadPackage KO for" filename
    return .false


-------------------------------------------------------------------------------
-- Remember : don't implement that as a procedure or routine or method !
loadLibrary:
    use strict arg filename
    signal on syntax name loadLibraryError
    if .context~package~loadLibrary(filename) then do
        say "loadLibrary OK for" filename
        return .true
    end
    loadLibraryError:
    say "loadLibrary KO for" filename
    return .false


-------------------------------------------------------------------------------
::requires "ooDialog.cls"                       -- Needed for the dialog
::requires 'winsystm.cls'                       -- Needed for the Windows clipboard

::class oort_dialog subclass userdialog
::method Init
    self~init:super
    rc = self~Create(.dx,.dy,.dwidth,.dheight,.title,'ThickFrame MinimizeBox MaximizeBox')
    self~InitCode = (rc=0)
    self~connectResize('OnResize')
    self~fontMenuHelper

::method DefineDialog
    expose u
    u = .dlgAreaU~new(self)
    if .nil \= u~lastError then
        call errorDialog u~lastError

---------- Arguments title & dialog area
    at = .dlgArea~new(0,0,u~w,10)
    self~addText(at~x,at~y,at~w,at~h,'Arguments','CENTER',17)
    ad = .dlgArea~new(0,at~y + 10,u~w,u~h('15%'))
    self~addEntryLine(12,'args_data',ad~x,ad~y,ad~w,ad~h,'multiline hscroll vscroll')

---------- Code title & dialog area
    ct = .dlgArea~new(0,ad~y + ad~h,u~w,10)
    self~addText(ct~x,ct~y,ct~w,ct~h,'Code','CENTER',18)
    cd = .dlgArea~new(0,ct~y + ct~h,u~w,u~h('40%'))
    self~addEntryLine(13,'code_data',cd~x,cd~y,cd~w,cd~h,'multiline hscroll vscroll')

---------- Says title & dialog area
    st = .dlgArea~new(0,cd~y + cd~h,u~w('50%'),10)
    self~addText(st~x,st~y,st~w,st~h,'Says','CENTER',19)
    sd = .dlgArea~new(0,st~y + st~h,u~w('50%'),u~h('43%'))
    self~addEntryLine(14,'say_data',sd~x,sd~y,sd~w,sd~h,'notab readonly multiline hscroll vscroll')

---------- Returns title & dialog area
    rt = .dlgArea~new(sd~x + sd~w,cd~y + cd~h,u~w('50%'),10)
    self~addText(rt~x,rt~y,rt~w,rt~h,'Returns','CENTER',20)
    rd = .dlgArea~new(rt~x,st~y + st~h,u~w('50%'),u~h('15%'))
    self~addEntryLine(15,'results_data',rd~x,rd~y,rd~w,rd~h,'notab readonly multiline hscroll vscroll')

---------- Errors/Information title & dialog area
    et = .dlgArea~new(rt~x,rd~y + rd~h,u~w('50%'),10)
    self~addText(et~x,et~y,et~w,et~h,'Errors / Information','CENTER',21)
    ed = .dlgArea~new(rt~x,et~y + et~h,u~w('50%'),u~h('17%'))
    self~addEntryLine(16,'error_data',ed~x,ed~y,ed~w,ed~h,'notab readonly multiline hscroll vscroll')

---------- Run & Exit buttons for easier execution
    self~AddButton(80,ed~x     ,ed~y + ed~h + 2,35,10,'&Run','RunIt')
    self~AddButton(81,ed~x + 40,ed~y + ed~h + 2,35,10,'E&xit','Cancel')

----------
    self~createMenu
    self~AddPopupMenu('&File')
       self~addMenuItem('&Run'   ,22,     ,'RunIt')
       self~addMenuItem('&SaveAs',23,     ,'FileDialog')
       self~addMenuItem('&Open'  ,25,     ,'FileDialog')
       self~addMenuItem('E&xit'  ,24,'END','Cancel')

    self~addPopUpMenu('&Edit')
       self~addPopupMenu('Font&Name')
           self~addMenuItem('&Arial Unicode MS',30,     ,'onFontMenuClick')
           self~addMenuItem('&Lucida Console',31,     ,'onFontMenuClick')
           self~addMenuItem('&Courier New'   ,32,'END','onFontMenuClick')
      self~addMenuSeparator
      self~addPopUpMenu('Font&Size','END')
           self~addMenuItem('&8' ,40,     ,'onFontMenuClick')
           self~addMenuItem('1&0',41,     ,'onFontMenuClick')
           self~addMenuItem('1&2',42,     ,'onFontMenuClick')
           self~addMenuItem('1&4',43,     ,'onFontMenuClick')
           self~addMenuItem('1&6',44,     ,'onFontMenuClick')
           self~addMenuItem('1&8',45,'END','onFontMenuClick')

   self~AddPopUpMenu('&Tools')
       self~addPopupMenu('&Copy')
           self~addMenuItem('&Args'   ,50,     ,'Clipboard')
           self~addMenuItem('&Code'   ,51,     ,'Clipboard')
           self~addMenuItem('&Says'   ,52,     ,'ClipBoard')
           self~addMenuItem('&Returns',53,     ,'ClipBoard')
           self~addMenuItem('&Errors' ,54,     ,'ClipBoard')
           self~addMenuItem('A&ll'    ,55,'END','ClipBoard')
           self~addMenuSeparator
       self~addPopupMenu('C&lear')
           self~addMenuItem('&Args'   ,60,     ,'ClearAll')
           self~addMenuItem('&Code'   ,61,     ,'ClearAll')
           self~addMenuItem('&Says'   ,62,     ,'ClearAll')
           self~addMenuItem('&Returns',63,     ,'ClearAll')
           self~addMenuItem('&Errors' ,64,     ,'ClearAll')
           self~addMenuItem('A&ll'    ,65,'END','ClearAll')
           self~addMenuSeparator
       self~addPopupMenu('&Silent')
           self~addMenuItem('&No'     ,66,     ,'Silent')
           self~addMenuItem('&Yes'    ,67,'END','Silent')
           self~addMenuSeparator
       self~addPopupMenu('Sa&ve Settings','END')
           self~addMenuItem('Sa&ve'   ,72,'END','SaveSettings')
   self~addPopupMenu('&Help','END')
       self~addMenuItem('Current &Settings',71,     ,'Settings')
       self~addMenuItem('&About'   ,70,'END','Help')

::method InitDialog
    expose args_input code_input result_input say_input errors_input
    -- Use font data from .ini file or defaults if .ini not present yet

    -- FW_EXTRALIGHT == 200
    d = .Directory~new
    d~weight = 200
    hfont = self~createFontEx(.fontname,.fontsize,d)
    self~setMenu

    -- Set the font and silent menu item check marks.
    self~setFontMenuChecks
    if .silent then self~checkMenuItem(67)
    else self~checkMenuItem(66)

    -- Get the controls for all dialog elements that will need to be adjusted
    args_input   = self~newEdit(12)
    code_input   = self~newEdit(13)
    say_input    = self~newEdit(14)
    result_input = self~newEdit(15)
    errors_input = self~newEdit(16)
    args_title   = self~newStatic(17)
    code_title   = self~newStatic(18)
    say_title    = self~newStatic(19)
    result_title = self~newStatic(20)
    errors_title = self~newStatic(21)

    -- Set the color of the titles
    args_title  ~setColor(5,10)
    code_title  ~setColor(16,10)
    say_title   ~setColor(15,0)
    result_title~setColor(14,0)
    errors_title~setColor(13,10)

    -- Set the font name/size to the default values
    self~ReDraw

    if \.useDefault then
        do
            -- Read oorexxtry.ini position & size the dialog based on its values
            handle = self~getSelf
            k1 = SysIni('oorexxtry.ini','oorexxtry','k1')
            k2 = SysIni('oorexxtry.ini','oorexxtry','k2')
            k3 = SysIni('oorexxtry.ini','oorexxtry','k3')
            k4 = SysIni('oorexxtry.ini','oorexxtry','k4')
            if k1 = 'ERROR:' | k2 = 'ERROR:' | k3 = 'ERROR:' | k4 = 'ERROR:' then
                nop -- First exection will not find the ini file
            else
                do
                    self~setWindowRect(handle,k1,k2,k3-k1,k4-k2)
                    self~ensureVisible
                end
        end

-- Run menu option
::method RunIt
    expose args_input code_input result_input say_input errors_input
    parse value code_input~getPos() with siX siY
    parse value code_input~getSize() with siW siH
    ch1 = code_input~Cursor_Wait
    parse value self~CursorPos with preCX preCY
    code_input~SetCursorPos((siX+(siW/2))*self~FactorX,(siY+(siH/2))*self~FactorY)
    arg_array = self~getText(args_input,.false) -- JLF don't strip, an empty line is an omitted argument
    .local~si = say_input
    w1 = code_input~selected~word(1)
    w2 = code_input~selected~word(2)
    code_array = self~getText(code_input,.true)
    if (w1 = .max_length & w2 = .max_length) | (w1 = w2) then
        nop     -- we've already loaded our code_array
    else
        do
            code_string = code_array~makeString
            code_array  = code_string~substr(w1,w2-w1)~makearray
        end
    if .local~ooRexx.isExtended then call transformSource code_array

    -- Clear any previous error data
    self~error_data    = ''
    errors_input~title = self~error_data

    -- Clear any previous say data
    self~say_data      = ''
    say_input~title    = self~say_data

    -- Clear any previous returns data
    self~results_data  = ''
    result_input~title = self~results_data

    .local~emsg = ''
    .local~imsg = ''

    self~error_data  = 'Code Is Executing'
    errors_input~title = self~error_data

    .local~Error? = .false
    .local~badarg = ''
    -- Interpret each argument so that expressions can be used
    signal on syntax name ArgSyntax
    do i = 1 to arg_array~items
        .local~badarg = i arg_array[i]
        if arg_array[i]~strip == "" then arg_array~remove(i)
        else interpret 'arg_array['i'] =' arg_array[i]
    end
    signal off syntax

    -- Run the code in a dynamically created method

    found_cc = .false
    do ca = 1 to code_array~items
        a_ca = code_array[ca]~strip()
        if a_ca~pos('::') = 1 then
            do
                found_cc = .true
                leave ca
            end
    end

    -- The thread is different at each run (thread created by ooDialog)
    if .local~ooRexx.hasBsf then call BsfAttachToTid .local~ooRexx.BsfJavaThreadId
    call time('r') -- to see how long this takes
    if \found_cc then
        do
            exec = .executor~new('oorexxtry.code',code_array)
            exec~run(arg_array)
        end
    else
        do
            tempFile = '.\ooRexxTry_test9999.rex'
            c_stream = .stream~new(tempFile)
            c_stream~open('Write Replace')
            c_stream~lineout('.context~parentContext~package~findRoutine("updatePackageEnvironment")~call(.context~package, .context~parentContext~package)')
            do ca = 1 to code_array~items
                c_stream~lineout(code_array[ca])
            end
            c_stream~close
            arg_string = ''
            do ca = 1 to arg_array~items
                arg_ca = '"'arg_array[ca]'"'
                arg_string = arg_string','arg_ca
            end
            arg_string = arg_string~strip('b',',')
            exec = .executor~new('oorexxtry.code','call "'tempFile'"' arg_string)
            exec~run(arg_array)
            rv = SysFileDelete(tempFile)
        end
    duration = time('e')
    if .local~ooRexx.hasBsf then call BsfDetach

    if .emsg \= '' then
        do
            if \.silent then
                call beep 600,100
            self~error_data    = .emsg
            errors_input~title = self~error_data
            self~results_data  = ''
            result_input~title = self~results_data
        end
    else
        do
            self~error_data  = 'Code Execution Complete'
            self~error_data ||= .endOfLine || "Duration:" duration
            if .local~ooRexx.isExtended then self~error_data ||= .endOfLine || "#Coactivities: " || .Coactivity~count
            errors_input~title = self~error_data
        end

    if .nil \= .run_results['returns'] then
        do
            self~results_data  = .run_results['returns']
            result_input~title = self~results_data
        end
    if \.silent then        -- Let the user know when code execution is complete
        call beep 150,150
    code_input~RestoreCursorShape(ch1)
    self~SetCursorPos(preCX,preCY)
    self~ReturnFocus
return

transformSource: procedure
    use strict arg sourceArray
    signal on syntax name transformSourceError -- the clauser can raise an error
    clauser = .Clauser~new(sourceArray)
    do while clauser~clauseAvailable
        clause = clauser~clause~strip
        if clause~left(2) == "::" then leave -- don't transform code inside directives
        if clause~right(1) == "=" then do
            clause = clause~left(clause~length - 1)
            -- Remember : when assigning a value to current clause, sourceArray is impacted
            clauser~clause = 'options "NOCOMMANDS";' clause ';call dumpResult var("result"), result; options "COMMANDS"'
        end
        clauser~nextClause
    end
    transformSourceError: -- in case of error, just return : an error will be raised by the interpreter, and caught.
    return

ArgSyntax:
    msg = 'Trapped In'~right(11)'..: ArgSyntax'
    obj = condition('o')
    msg = msg||.endOfLine||'Message'~right(11)'..:' obj['MESSAGE']
    msg = msg||.endOfLine||'ErrorText'~right(11)'..:' obj['ERRORTEXT']
    msg = msg||.endOfLine||'Code'~right(11)'..:' obj['CODE']
    msg = msg||.endOfLine||('Argument' .badarg~word(1))~right(11)'..:' .badarg~subword(2)
    .local~emsg = msg
    if \.silent then
        call beep 600,100
    self~error_data    = .emsg
    errors_input~title = self~error_data
    self~results_data      = ''
    result_input~title = self~results_data
    .local~emsg = ''
    self~focusItem(12)
    args_input~select(1,1)
    code_input~RestoreCursorShape(ch1)
    self~SetCursorPos(preCX,preCY)
return


::routine updatePackageEnvironment public
    use strict arg package, referencePackage
    -- Add visibility on the routine dumpResult
    dumpResult = referencePackage~findRoutine("dumpResult")
    package~addPublicRoutine("dumpResult", dumpResult)
    -- Make visible (via ~importedPackages) all the packages imported in the reference package
    -- Note :
    -- These packages are already in the search path, thanks to the default "PROGRAMSCOPE" context used when creating the executor's method.
    -- I make them explicitely visible to have the same results under oorexxshell and oorexxtry when calling .context~package~importedPackages.
    do p over referencePackage~importedPackages
        package~addPackage(p)
    end


::routine dumpResult public
    use strict arg hasValue, value
    if \hasValue then do
        say "[no result]"
        return
    end
    else do
        if value~isA(.CoactivitySupplier) then say pp2(value) -- must not consume the datas
        else if value~isA(.array), value~dimension <= 1 then say value~ppRepresentation(100) -- condensed output, 100 items max
        else if value~isA(.Collection) | value~isA(.Supplier) then call dump2 value
        else say pp2(value)
        return value -- To get this value in the variable RESULT
    end


::method Cancel
    handle = self~getSelf
    sp = self~getWindowRect(handle)
    -- Write out the size,position,fontname,fontsize, & silent to the .ini file
    if \self~isMinimized & \self~isMaximized then
        do
            rv = SysIni('oorexxtry.ini','oorexxtry','k1',sp~word(1))
            rv = SysIni('oorexxtry.ini','oorexxtry','k2',sp~word(2))
            rv = SysIni('oorexxtry.ini','oorexxtry','k3',sp~word(3))
            rv = SysIni('oorexxtry.ini','oorexxtry','k4',sp~word(4))
        end
    rv = SysIni('oorexxtry.ini','oorexxtry','fn',.fontname)
    rv = SysIni('oorexxtry.ini','oorexxtry','fs',.fontsize)
    rv = SysIni('oorexxtry.ini','oorexxtry','sl',.silent)
return self~ok:super

-- Clipboard menu option
::method ClipBoard
    expose args_input errors_input code_input say_input result_input
    use arg msg, args
    cp = .WindowsClipBoard~new
    select
        when msg = 50 then
            do
                cp_array  = self~getText(args_input,.false)
                cp_string = cp_array~makestring
                cp~Copy(cp_string)
                .local~imsg = 'Arguments Are On ClipBoard'
            end
        when msg = 51 then
            do
                cp_array  = self~getText(code_input,.false)
                cp_string = cp_array~makestring
                cp~Copy(cp_string)
                .local~imsg = 'Code Is On ClipBoard'
            end
        when msg = 52 then
            do
                cp_array  = self~getText(say_input,.false)
                cp_string = cp_array~makestring
                cp~Copy(cp_string)
                .local~imsg = 'Says Are On The ClipBoard'
            end
        when msg = 53 then
            do
                cp_array  = self~getText(result_input,.false)
                cp_string = cp_array~makestring
                cp~Copy(cp_string)
                .local~imsg = 'Returns Are On ClipBoard'
            end
        when msg = 54 then
            do
                cp_array  = self~getText(errors_input,.false)
                cp_string = cp_array~makestring
                cp~Copy(cp_string)
                .local~imsg = 'Errors Are On ClipBoard'
            end
        when msg = 55 then
            do
                allData = 'The Following Output Was Generated With ooRexxTry'.endOfLine||.endOfLine
                cp_array  = self~getText(args_input,.false)
                cp_string = cp_array~makestring
                allData = alldata||'Arguments'||.endOfLine||cp_string||.endOfLine||'-'~copies(20)||.endOfLine

                cp_array  = self~getText(code_input,.false)
                cp_string = cp_array~makestring
                allData = allData||'Code'||.endOfLine||cp_string||.endOfLine||'-'~copies(20)||.endOfLine

                cp_array  = self~getText(say_input,.false)
                cp_string = cp_array~makestring
                allData = allData||'Says'||.endOfLine||cp_string||.endOfLine||'-'~copies(20)||.endOfLine

                cp_array  = self~getText(result_input,.false)
                cp_string = cp_array~makestring
                allData = allData||'Results'||.endOfLine||cp_string||.endOfLine||'-'~copies(20)||.endOfLine

                cp_array  = self~getText(errors_input,.false)
                cp_string = cp_array~makestring
                allData = allData||'Errors/Information'||.endOfLine||cp_string||.endOfLine||'-'~copies(20)||.endOfLine

                cp~Copy(allData)
                .local~imsg = 'All Data Is On ClipBoard'
            end
        otherwise
            nop
    end
    self~error_data    = .imsg
    errors_input~title = self~error_data
    self~ReturnFocus

-- Code2File menu option
::method FileDialog
    expose code_input errors_input
    use arg msg, args
    if msg = 23 then
        do
            c_array = self~getText(code_input,.false)
            c_string = c_array~makestring
            action = 'S'
            dtitle = 'ooRexxTry File Save'
        end
    else
        do
            action = 'L'
            dtitle = 'ooRexxTry File Open'
        end

    delimiter = '0'x
    filemask      = 'ooRexx Files (*.rex)'delimiter'*.rex'delimiter||-
                    'All Files (*.*)'delimiter'*.*'delimiter
    handle = self~getSelf
    a_file = FileNameDialog(.preferred_path,handle,filemask,action,dtitle,'.rex')
    if a_file \= 0 then
        do
            ostream = .stream~new(a_file)
            if msg = 23 then
                do
                    ostream~open('Write Replace')
                    ostream~lineout(c_string)
                    ostream~close
                    .local~imsg        = 'Code Saved As' a_file
                    self~error_data    = .imsg
                    errors_input~title = self~error_data
                end
            else
                do
                    oarray = ostream~charin(,ostream~chars)~makearray
                    ostream~close
                    mycode = ''
                    do i = 1 to oarray~items
                        mycode = mycode||oarray[i]
                        if i < oarray~items then
                            mycode = mycode||.endOfLine
                    end
                    self~code_data   = mycode
                    code_input~title = self~code_data

                    .local~imsg        = 'Code From' a_file 'In Code Dialog'
                    self~error_data    = .imsg
                    errors_input~title = self~error_data
                end
        end
    self~ReturnFocus

-- ClearAll menu option
::method ClearAll
    expose args_input code_input result_input say_input errors_input
    use arg msg, args
    select
        when msg = 60 then
            do
                self~args_data   = ''
                args_input~title = self~args_data
            end
        when msg = 61 then
            do
                self~code_data   = ''
                code_input~title = self~code_data
            end
        when msg = 62 then
            do
                self~say_data = ''
                say_input~title = self~say_data
            end
        when msg = 63 then
            do
                self~results_data = ''
                result_input~title = self~results_data
            end
        when msg = 64 then
            do
                self~error_data = ''
                errors_input~title = self~error_data
            end
        when msg = 65 then
            do
                self~args_data   = ''
                args_input~title = self~args_data

                self~code_data   = ''
                code_input~title = self~code_data

                self~results_data = ''
                result_input~title = self~results_data

                self~say_data = ''
                say_input~title = self~say_data

                self~error_data = ''
                errors_input~title = self~error_data
            end
        otherwise
            nop
    end
    self~ReturnFocus

::method Silent
    use arg msg, args
    select
        when msg = 66 then do
            .local~silent = .false
            self~checkMenuItem(66)
            self~unCheckMenuItem(67)
        end
        when msg = 67 then do
            .local~silent = .true
            self~checkMenuItem(67)
            self~unCheckMenuItem(66)
        end
        otherwise
            nop
    end
    self~ReturnFocus

::method SaveSettings
    use arg msg, args
    handle = self~getSelf
    sp = self~getWindowRect(handle)
    select
        when msg = 72 then
            do
                if \self~isMinimized & \self~isMaximized then
                    do
                        rv = SysIni('oorexxtry.ini','oorexxtry','k1',sp~word(1))
                        rv = SysIni('oorexxtry.ini','oorexxtry','k2',sp~word(2))
                        rv = SysIni('oorexxtry.ini','oorexxtry','k3',sp~word(3))
                        rv = SysIni('oorexxtry.ini','oorexxtry','k4',sp~word(4))
                    end
                rv = SysIni('oorexxtry.ini','oorexxtry','fn',.fontname)
                rv = SysIni('oorexxtry.ini','oorexxtry','fs',.fontsize)
                rv = SysIni('oorexxtry.ini','oorexxtry','sl',.silent)
            end
        otherwise
            nop
    end
    self~ReturnFocus

::method ReturnFocus
    expose code_input
    w1 = code_input~selected~word(1)
    w2 = code_input~selected~word(2)
    code_array = self~getText(code_input,.true)
    if w1 = .max_length & w2 = .max_length then
        do
            sel_start = .max_length
            sel_end   = .max_length
        end
    else
        do
            sel_start = w1
            sel_end   = w2
        end
    self~focusItem(13)
    code_input~select(sel_start,sel_end)

-- Method to handle all the resizing
::method OnResize
    expose u
    use arg dummy,sizeinfo
    u~resize(self,sizeinfo)

::method Help
    expose code_input u
    handle = self~getSelf
    parse value self~GetWindowRect(handle) with var1 var2 var3 var4
    .local~dw = (var3 - var1) / self~factorX
    .local~dh = (var4 - var2) / self~factorY

    parse value self~GetPos with dx dy
    .local~dx = dx
    .local~dy = dy

    help = .help_dialog~new()
    if help~initCode \= 0 then
        do
            call errorDialog 'Error creating help dialog. initCode:' help~initCode
            exit
        end
    help~Execute('ShowTop')
    help~DeInstall

::method Settings
    expose code_input u
    handle = self~getSelf
    parse value self~GetWindowRect(handle) with var1 var2 var3 var4
    .local~dw = (var3 - var1) / self~factorX
    .local~dh = (var4 - var2) / self~factorY

    parse value self~GetPos with dx dy
    .local~dx = dx
    .local~dy = dy

    settings = .settings_dialog~new()
    if settings~initCode \= 0 then
        do
            call errorDialog 'Error creating help dialog. initCode:' settings~initCode
            exit
        end
    settings~Execute('ShowTop')
    settings~DeInstall

-- Redraw applicable areas of the dialog based on the font menu choice
::method ReDraw
    expose args_input code_input say_input result_input errors_input

    -- FW_EXTRALIGHT == 200
    d = .Directory~new
    d~weight = 200
    hfont = self~createFontEx(.fontname,.fontsize,d)
    args_input  ~setFont(hfont)
    code_input  ~setFont(hfont)
    say_input   ~setFont(hfont)
    result_input~setFont(hfont)
    errors_input~setFont(hfont)

::method getText
    use arg the_input,stripIt
    iarray = .array~new()
    max_length = 0
    do i = 1 to the_input~lines
        if stripIt then
            do
                if the_input~getLine(i)~strip() \= '' then
                    do
                        iarray~append(the_input~getLine(i))
                        max_length += iarray[iarray~last]~length
                    end
            end
        else
            do
                iarray~append(the_input~getLine(i))
                max_length += iarray[iarray~last]~length
            end
    end
    .local~max_length = max_length + 1
return iarray

-- This method is invoked whenever the user clicks on one of the font menu items.
-- The first arg to the method is the resource id of the menu id that was clicked.
::method onFontMenuClick
    expose fontMenuIDs
    use arg id

    -- Map the menu item id to a font setting.  Could be size of name.
    item = fontMenuIDs~index(id)

    -- If item is a number, then it is a font size menu item, otherwis a font name.
    if item~datatype('W') then .local~fontSize = item
    else .local~fontname = item

    -- Reset the menu item check marks and redraw in the new font.
    self~setFontMenuChecks
    self~ReDraw

-- This method sets the appropriate font menu item check state.  Checked for selected
-- and unchecked for unselected.
::method setFontMenuChecks private
    expose fontMenuIDs

    -- Iterate over all items in the table unchecking each menu item.  Brute force,
    -- but easy, and there are not many items. The alternative is to keep track of
    -- which items are checked and uncheck / check the correct ones.
    do id over fontMenuIDs~allItems
        self~uncheckMenuItem(id)
    end

    -- Now check the menu item that matches what font name and size is currently
    -- in use.
    self~checkMenuItem(fontMenuIDs[.fontname])
    self~checkMenuItem(fontMenuIDs[.fontsize])

-- A private help method that sets up things to make working with the font menu easier
::method fontMenuHelper private
    expose fontMenuIDs

    -- Create a table that maps menu item IDs to the matching font setting.  Since
    -- the Table class has the index() method, the mapping works both ways.
    fontMenuIDs = .Table~new
    fontMenuIDs["Arial Unicode MS"] = 30
    fontMenuIDs["Lucida Console"] = 31
    fontMenuIDs["Courier New"]    = 32

    fontMenuIDs[ 8] = 40
    fontMenuIDs[10] = 41
    fontMenuIDs[12] = 42
    fontMenuIDs[14] = 43
    fontMenuIDs[16] = 44
    fontMenuIDs[18] = 45

-- Class that dynamically creates a method to take the arguments and execute the code
::class executor public
::method init
    expose rt_method
    use arg method_name,code
    .local~Error? = .false
    signal on syntax name ExecSyntax
    rt_method = .method~new(method_name, code)
    call updatePackageEnvironment rt_method~package, .context~package
return

-- Syntax trap similiar to rexxc.exe
ExecSynTax:
    msg = 'Trapped In'~right(11)'..: ExecSyntax'
    obj = condition('o')
    msg = msg||.endOfLine||'Message'~right(11)'..:' obj['MESSAGE']
    msg = msg||.endOfLine||'ErrorText'~right(11)'..:' obj['ERRORTEXT']
    msg = msg||.endOfLine||'Code'~right(11)'..:' obj['CODE']
    msg = msg||.endOfLine||'Line #'~right(11)'..:' obj['POSITION']
    .local~emsg = msg
    .local~Error? = .true
return

-- Method that actually runs our code
::method run
    expose rt_method say_string
    signal on syntax name RunSyntax
    .local~run_results = .directory~new
    .local~say_stg = ''
    my_result = ''
    if \.Error? then
        do
            -- Redirect STDOUT for say statements
            scrnOut = .SayCatcher~New('STDOUT')~~Command('open write nobuffer')
            theSayMonitor = .monitor~New(scrnOut)
            .output~Destination(theSayMonitor)
            -- Run the Code
            args = arg(1)
            self~run:super(rt_method, 'a', args)
            -- Test if there was anything returned by the code
            if symbol('result') = 'VAR' then
                my_result = result
            -- Load the says and returns into environment variables for updating the dialog areas
            .local~run_results['returns'] = my_result
            -- Redirect STDOUT back to what it was (probably the screen)
            .output~Destination()
        end
return .run_results

-- Syntax trap for errors in the code
RunSyntax:
    msg = 'Trapped In'~right(11)'..: RunSyntax'
    obj = condition('o')
    msg = msg||.endOfLine||'Message'~right(11)'..:' obj['MESSAGE']
    msg = msg||.endOfLine||'ErrorText'~right(11)'..:' obj['ERRORTEXT']
    msg = msg||.endOfLine||'Code'~right(11)'..:' obj['CODE']
    msg = msg||.endOfLine||'Line #'~right(11)'..:' obj['POSITION']
    .local~emsg = msg
return

-- Class to "catch" all say,charout,lineout statements in the code
-- Will not catch charout & lineout if the first argument is supplied
::class SayCatcher subclass stream
::method say
    expose .si
    use arg input
    .local~say_stg = .say_stg||input||.endOfLine
    .si~title = .say_stg
return

::method charout
    expose .si
    use arg input
    .local~say_stg = .say_stg||input
    .si~title = .say_stg
return 0

::method lineout
    expose .si
    use arg input
    .local~say_stg = .say_stg||input||.endOfLine
    .si~title = .say_stg
return 0


::class help_dialog subclass userdialog
::method Init
    self~init:super
    lp = (.dx + (.dw / 2) - 50)~format( , 0)
    tp = (.dy + (.dh / 2) - 30)~format( , 0)
    rc = self~Create(lp,tp,100,60,.title)
    self~InitCode = (rc=0)

::method DefineDialog
    expose h
    h = .dlgAreaU~new(self)
    if .nil \= h~lastError then
        call errorDialog h~lastError
    vt = .dlgArea~new(h~x,0,h~w,10)
    self~addText(vt~x,vt~y,vt~w,vt~h,'Version','CENTER',20)
    vd = .dlgArea~new(h~x,vt~y + vt~h,h~w,10)
    self~addText(vd~x,vd~y,vd~w,vd~h,.version,'CENTER',21)

    at = .dlgArea~new(h~x,vd~y + vd~h,h~w,10)
    self~addText(at~x,at~y,at~w,at~h,'Author','CENTER',22)
    ad = .dlgArea~new(h~x,at~y + at~h,h~w,10)
    self~addText(ad~x,ad~y,ad~w,ad~h,'Lee Peedin','CENTER',23)

    dt = .dlgArea~new(h~x,ad~y + ad~h,h~w,10)
    self~addText(dt~x,dt~y,dt~w,dt~h,'Documentation','CENTER',24)
    dd = .dlgArea~new(h~x,dt~y + dt~h,h~w,10)
    self~AddButton(25,dd~x,dd~y,dd~w,10,'&PDF','Help')

::method InitDialog
    v_title = self~newStatic(20)
    a_title = self~newStatic(22)
    d_title = self~newStatic(24)

    v_title~setColor(5,10)
    a_title~setColor(5,10)
    d_title~setColor(5,10)

::method Help
    -- The help doc is supposed to be in the 'doc' subdirectory, but we will also check the
    -- current directory, then the Rexx home directory.
    if SysFileExists('doc\ooRexxTry.pdf') then do
        helpDoc = 'doc\ooRexxTry.pdf'
    end
    else if SysFileExists('ooRexxTry.pdf') then do
        helpDoc = 'ooRexxTry.pdf'
    end
    else if SysfileExists(value("REXX_HOME",,"ENVIRONMENT")||"\doc\ooRexxTry.pdf") then do
        helpDoc = value("REXX_HOME",,"ENVIRONMENT")||"\doc\ooRexxTry.pdf"
    end
    else do
        msg = "The ooRexxTry.pdf help documentation could not be located."                     || .endOfLine -
              || .endOfLine || -
              "Tried:"                                                                         || .endOfLine -
              "  doc subdirectory:  "||directory()||"\doc\ooRexxTry.pdf"                       || .endOfLine -
              "  current directory: "||directory()||"\ooRexxTry.pdf"                           || .endOfLine -
              "  Rexx home:         "||value("REXX_HOME",,"ENVIRONMENT")||"\doc\ooRexxTry.pdf" || .endOfLine -
              || .endOfLine || -
              "Sorry, no help is available"
        call errorDialog msg
        return
    end
    'start "ooRexxTry Online Documentation"' '"'||helpDoc||'"'


::class settings_dialog subclass userdialog
::method Init
    self~init:super
    lp = (.dx + (.dw / 2) - 50)~format( , 0)
    tp = (.dy + (.dh / 2) - 30)~format( , 0)
    rc = self~Create(lp,tp,100,60,.title)
    self~InitCode = (rc=0)

::method DefineDialog
    expose h
    h = .dlgAreaU~new(self)
    if .nil \= h~lastError then
        call errorDialog h~lastError
    vt = .dlgArea~new(h~x,0,h~w,10)
    self~addText(vt~x,vt~y,vt~w,vt~h,'Font Name','CENTER',20)
    vd = .dlgArea~new(h~x,vt~y + vt~h,h~w,10)
    self~addText(vd~x,vd~y,vd~w,vd~h,.fontname,'CENTER',21)

    at = .dlgArea~new(h~x,vd~y + vd~h,h~w,10)
    self~addText(at~x,at~y,at~w,at~h,'Font Size','CENTER',22)
    ad = .dlgArea~new(h~x,at~y + at~h,h~w,10)
    self~addText(ad~x,ad~y,ad~w,ad~h,.fontsize,'CENTER',23)

    dt = .dlgArea~new(h~x,ad~y + ad~h,h~w,10)
    self~addText(dt~x,dt~y,dt~w,dt~h,'Silent','CENTER',24)
    dd = .dlgArea~new(h~x,dt~y + dt~h,h~w,10)
    self~addText(dd~x,dd~y,dd~w,dd~h,.silent,'CENTER',23)

::method InitDialog
    v_title = self~newStatic(20)
    a_title = self~newStatic(22)
    d_title = self~newStatic(24)

    v_title~setColor(14,0)
    a_title~setColor(14,0)
    d_title~setColor(14,0)

::routine LoadEnvironment
    .local~px = ScreenSize()[3]
    .local~py = ScreenSize()[4]

-- Establish dialog area sizes based of the user's screen resolution - will only be used for the first
-- execution - from then on data is retrieved from the .ini file, unless user specifies default as an
-- execution argument from the command line
    .local~dwidth  = ((.px / 2.5) * .65)~format(,0)
    .local~dheight = ((.py / 2.5) * .65)~format(,0)
    .local~dx      = 0
    .local~dy      = 0


-- Need a few generic variables
    .local~version        = '1.0'             -- Internal version control
    .local~preferred_path = ''                  -- Default starting path for Save As dialog - will be either
                                                -- the folder ooRexxTry is executed from or the last folder that
                                                -- was accessed using the Windows File Dialog
    .local~title          = 'ooRexxTry'       -- Title to use for the dialogs
    if .local~ooRexx.wcharOOdialog then .local~title ||= " (wide-char ooDialog)"
                                   else .local~title ||= " (byte-char ooDialog)"

-- If the .ini file is present, use it for font/silent variables
    .local~fontname = SysIni('oorexxtry.ini','oorexxtry','fn')
    .local~fontsize = SysIni('oorexxtry.ini','oorexxtry','fs')
    .local~silent   = SysIni('oorexxtry.ini','oorexxtry','sl')

-- Else use some defaults
    if .fontname = 'ERROR:' | .useDefault then
        .local~fontname = 'Arial Unicode MS' -- 'Lucida Console'
    if .fontsize = 'ERROR:' | .useDefault then
        .local~fontsize = 8 -- 12
    if .silent   = 'ERROR:' | .useDefault then
        .local~silent   = .false
return


-------------------------------------------------------------------------------
::class platform
-------------------------------------------------------------------------------

-- Class level

::attribute current class -- the current platform is a singleton


::method initialize class -- init not supported (can't instantiate itself or subclass from init)
    use strict arg -- none
    parse source sysrx .
    select
        when sysrx~caselessAbbrev("windows") then self~current = self~new("windows")
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

