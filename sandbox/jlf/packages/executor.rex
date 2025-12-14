/*
This script allows to execute a script which depends on extensions, without
having to modify the script to requires the extension packages.

Differences, compared to rexx -e:
- .syscargs has a value
   executor -e "call dump2 .syscargs" he said "good bye" and left.
        an Array (shape [5], 5 items)
         1 : 'he'
         2 : 'said'
         3 : 'good bye'
         4 : 'and'
         5 : 'left.'
- The directives :: are not supported. Use the options -l or -p.
*/

signal on syntax name trap_error
--.environment["DEBUGOUTPUT"] = .traceOutput
.environment["DEBUGOUTPUT"] = .nullOutput
defaultEncoding = .encoding~defaultEncoding

-- The intermediate actions are postponed until the whole arguments have been parsed
actions = .queue~new

parse_options:
    option = c_arg()
    option = option~lower

         if option == "-e"         then signal run_string
    else if option == "-f"         then signal run_fscript
    else if option == "-l"         then signal load_library
    else if option == "-p"         then signal load_package
    else if option == "-v"         then signal display_version
    else if option == "--encoding" then signal default_encoding
    else if option~left(1) == "-"  then signal unknown_option
    else if option \== ""          then signal run_script
    -- else if actions~isEmpty        then signal usage
    else return execute_actions()


usage:
    .error~say("Usage:")
    .error~say("    executor (-l libray | -p package)* --encoding encodingName [-f] filename [arguments]")
    .error~say("    executor (-l libray | -p package)* --encoding encodingName  -e  string   [arguments]")
    .error~say("    executor -v")
    return -1


missing_final_action:
    if \ actions~isEmpty then do
        .error~say("You did not specify what to execute:")
        .error~say("    either [-f] filename [arguments]")
        .error~say("    or      -e  string   [arguments]")
    end
    signal usage


unknown_option:
    .error~say("Unknown option" option)
    signal usage


display_version:
    "rexx -v"
    return RC


default_encoding:
    call shift_c_args -- remove --encoding
    encodingName = c_arg()
    if encodingName == "" then do
        .error~say("Missing encoding")
        signal usage
    end
    if encodingName~left(1) == "-" then do
        .error~say("Missing encoding, got option" encodingName)
        signal usage
    end
    call shift_c_args -- remove encoding
    defaultEncoding = getEncoding(encodingName, /*forDefaultEncoding:*/ .true)
    if defaultEncoding == .nil then do
        .error~say(encodingName~quoted "is an invalid default encoding.")
        .error~say("Supported default encodings:")
        call saySupportedDefaultEncodings, indent:4, stream:.error
        return -1
    end
    actions~append{ return .true } -- keep it, it's a way to know that an action was requested
    signal parse_options -- continue parsing


load_library:
    call shift_c_args -- remove -l
    library = c_arg()
    if library == "" then do
        .error~say("Missing library")
        signal usage
    end
    if library~left(1) == "-" then do
        .error~say("Missing library, got option" library)
        signal usage
    end
    call shift_c_args -- remove library
    actions~append{ expose library; loadLibrary(library) }
    signal parse_options -- continue parsing


load_package:
    call shift_c_args -- remove -p
    package = c_arg()
    if package == "" then do
        .error~say("Missing package")
        signal usage
    end
    if package~left(1) == "-" then do
        .error~say("Missing package, got option" package)
        signal usage
    end
    call shift_c_args -- remove package
    actions~append{ expose package; loadPackage(package) }
    signal parse_options -- continue parsing


run_string:
    -- In official oorexx, .syscargs has no value when evaluating program string.
    -- With executor, .syscargs has a value.
    -- Align it with what you get when running a script: the arguments passed to the script, and only that.
    call shift_c_args -- remove -e
    string = c_arg()
    if string == "" then do
        .error~say("Missing string")
        signal usage
    end
    call shift_c_args -- remove string
    args = remaining_c_args() -- as a string
    return execute_actions{
        expose string args defaultEncoding
        interpreter = .Interpreter~new(string, defaultEncoding)
        if args == "" then interpreter~interpret       -- arg() == 0
                      else interpreter~interpret(args) -- arg() == 1, whatever the number of C arguments
        -- return result and RC, if any
        res = .array~new(2)
        if var("result") then res[1] = result
        if var("RC") then res[2] = RC
        return res
    }


run_fscript:
    call shift_c_args -- remove -f
run_script:
    filename = c_arg()
    if filename == "" then do
        .error~say("Missing filename")
        signal usage
    end
    program = .context~package~findProgram(filename)
    if .nil == program then raise syntax 3.901 array (filename)
    call shift_c_args -- remove filename to be aligned with rexx
    args = remaining_c_args() -- as a string
    return execute_actions{
        expose program args defaultEncoding
        .context~package~setUserData("displayStackFrame", "stop before")
        -- can't use the call instruction because must have access to the package of the called program
        /*
        if args == "" then call (program)      -- arg() == 0
                      else call (program) args -- arg() == 1, whatever the number of C arguments
        */
        routine = .Routine~newFile(program)
        .encoding~setDefaultEncoding(defaultEncoding)
        routine~package~setEncoding(defaultEncoding)
        if args == "" then routine~call         -- arg() == 0
                      else routine~call(args)   -- arg() == 1, whatever the number of C arguments
        -- return result and RC, if any
        res = .array~new(2)
        if var("result") then res[1] = result
        if var("RC") then res[2] = RC
        return res
    }


execute_actions: procedure expose actions
    use strict arg final_action=.nil
    signal on syntax name action_error

    -- Load all the extensions packages
    call loadPackage "extension/extensions.cls"
    call loadPackage "pipeline/pipe_extension.cls"

    -- Load this package for pretty-printing of collections
    call loadPackage "rgf_util2/rgf_util2.rex"

    -- Run the intermediate actions (load the libraries/packages specified on the command line)
    results = actions~each("do")
    ok = results~reduce("&", initial:.true) -- each action returns either a boolean result or no result
    if \ok then do
        -- at least one action has returned a .false value, stop now
        if var("RC") then return -RC -- assume it's an error code: negative
        return -1 -- arbitrary value of error code (no equivalent with rexx)
    end

    call declareAllPublicClasses
    call declareAllPublicRoutines

    if .nil == final_action then signal missing_final_action

    res = final_action~do
    if res~hasIndex(1) then action_result = res[1]
    if res~hasIndex(2) then action_RC = res[2]

    return:
    if var("action_result") then return action_result
    if var("action_RC"), action_RC < 0 then return action_RC -- align with Rexx, return RC only in case of error (negative)
    return 0

    action_error:
    /*
        executor and rexx return the same values:
                                MacOs/Linux     Windows
        rexx -e "1/0"           RC = 214          RC = -42
        rexx -e "return 10"     RC = 10           RC = 10
        rexx -e "exit 10"       RC = 10           RC = 10
    */
    if var("result") then action_result = result
    if var("RC") then action_RC = -RC -- here, it's an error code: negative
    call sayCondition condition("O")
    signal return


-- Global
-- 1st need: catch 3.901 raised when findProgram returns .nil
trap_error:
    call sayCondition condition("O")
    if var("RC") then return -RC -- here, it's an error code: negative
    return


-------------------------------------------------------------------------------
-- Helpers to manipulate the C arguments

::routine c_arg
    if .nil == .syscargs[1] then return ""
    return .syscargs[1]


::routine shift_c_args
    .syscargs~delete(1)
    return


::routine remaining_c_args
    return .syscargs~toString("line", " ") -- concatenate all the remaining C arguments, separated by a space character.


-------------------------------------------------------------------------------
-- Helpers for encodings

::routine saySupportedDefaultEncodings
    use strict arg -- none
    use strict named arg indent=0, stream=.output
    spaces = " "~copies(indent)
    encodings = .encoding~defaultEncodingList
    allIndexes = encodings~allIndexes
    widthMax = 0
    do encodingName over allIndexes
        widthMax = max(widthMax, encodingName~length)
    end
    do encodingName over allIndexes~sort
        stream~say(spaces || encodingName~left(widthMax) || " : " || encodings[encodingName])
    end


::routine getEncoding
    use strict arg encodingName, forDefaultEncoding=.false
    signal on syntax name invalid_encoding
        encoding = .encoding~factory(encodingName)
    signal off syntax
    if forDefaultEncoding, \ encoding~canBeDefaultEncoding then signal invalid_encoding
    return encoding

    invalid_encoding:
    return .nil


-------------------------------------------------------------------------------
::routine loadPackage
    use strict arg filename
    use strict named arg stream=.error
    .context~package~setUserData("displayStackFrame", "stop before")
    signal on syntax name loadPackageError
    .context~package~loadPackage(filename)
    return .true

    loadPackageError:
    stream~say("Can't load package" filename)
    call sayCondition condition("O"), excludedPackage:.context~package
    return .false


-------------------------------------------------------------------------------
::routine loadLibrary
    use strict arg filename
    use strict named arg stream=.error
    .context~package~setUserData("displayStackFrame", "stop before")
    signal on syntax name loadLibraryError
    if .context~package~loadLibrary(filename) then return .true

    loadLibraryError:
    stream~say("Can't load library" filename)
    call sayCondition condition("O"), excludedPackage:.context~package
    return .false


-------------------------------------------------------------------------------
-- Add all the public and imported public classes to .environment.
::routine declareAllPublicClasses

    package = .context~package
    call declare_classes package~publicClasses -- of the current script, if any
    call declare_classes package~importedClasses
    return

    declare_classes: procedure
        use strict arg classes
        supplier = classes~supplier
        do while supplier~available
            className = supplier~index
            classInstance = supplier~item
            .environment[className] = classInstance
            supplier~next
        end
        return


-------------------------------------------------------------------------------
-- Add all the public and imported public routines to .globalRoutines.
::routine declareAllPublicRoutines

    package = .context~package
    call declare_routines package~publicRoutines -- of the current script, if any
    call declare_routines package~importedRoutines
    return

    declare_routines: procedure
        use strict arg routines
        supplier = routines~supplier
        do while supplier~available
            routineName = supplier~index
            routineInstance = supplier~item
            .globalRoutines[routineName] = routineInstance
            supplier~next
        end
        return

-------------------------------------------------------------------------------
-- Don't display the frames of Executor itself.
-- Display the user-defined name (if any) of the caller's package (goal: display "INSTORE" when applicable)

::routine sayCondition
    use strict arg condition
    use strict named arg stream=.error, excludedPackage=.nil

    if condition == .nil then return
    stackFrames = condition~stackFrames
    package = condition~package
    .debugOutput~say("condition package:" package~identityhash "|" package~getUserData("name") "|" package~name)

    raisedByExcludedPackage = (package == excludedPackage)
    if  raisedByExcludedPackage then return
    call sayStackFrames stackFrames, stream:stream

    if condition~condition <> "SYNTAX" then stream~say(condition~condition)
    if condition~description <> .nil, condition~description <> "" then stream~say(condition~description)

    -- For SYNTAX conditions
    if condition~errortext <> .nil then do
        packageName = userDefinedPackageName(stackFrames)
        if .nil == packageName, .nil \== package then packageName = package~name
        if .nil \== packageName then errorText = "Error" condition~rc packageName "line" condition~position":" condition~errortext
                                else errorText = "Error" condition~rc":" condition~errortext
        stream~say(errorText)
    end
    if condition~message <> .nil then stream~say("Error" condition~code":" condition~message)
    return

    userDefinedPackageName: procedure
        use strict arg stackFrames
        package = rexxCallerPackage(stackFrames)
        if .nil \== package then return package~getUserData("name")
        return .nil

    /*
    Example:
        StackFrame1     executable == .nil, skip it, it's a native code
        StackFrame2     executable \== .nil, return executable~package
        ...
    */
    rexxCallerPackage: procedure
        use strict arg stackFrames
        supplier = stackFrames~supplier
        do while supplier~available
            stackFrame = supplier~item
            executable = stackFrame~executable
            if .nil \== executable then return executable~package
            supplier~next
        end
        return .nil


::routine sayStackFrames
    .debugOutput~say("begin sayStackFrames"~center(80, "-"))
    use strict arg stackFrames
    use strict named arg stream=.error
    supplier = stackFrames~supplier
    first = .true -- always display the first stack frame
    do while supplier~available
        stackFrame = supplier~item
        executable = stackFrame~executable
        package = .nil
        if executable <> .nil then package = executable~package

        .debugOutput~say
        .debugOutput~say("index =" supplier~index)
        .debugOutput~say("stackFrame =" stackFrame)
        .debugOutput~say("stackFrame~type =" stackFrame~type)
        .debugOutput~say("displayStackFrame =" package~getUserData("displayStackFrame"))
        .debugOutput~say("executable =" executable~string executable~identityhash)
        if package <> .nil then .debugOutput~say("package" package~identityhash "|" package~getUserData("name") "|" package~name)
        else .debugOutput~say("<No package>")

        displayStackFrame = "yes"
        if .nil <> package then displayStackFrame = package~getUserData("displayStackFrame")
        if \first, displayStackFrame == "stop before" then leave
        stream~say(stackFrame~traceLine)
        if \first, displayStackFrame == "stop after" then leave
        first = .false
        supplier~next
    end
    .debugOutput~say("end sayStackFrames"~center(80, "-"))


-------------------------------------------------------------------------------
::class "Interpreter"

::method init
    expose string encoding
    use strict arg string, encoding

::method interpret
    expose string encoding
    .context~package~setUserData("name", "running INSTORE")
    .context~package~setUserData("displayStackFrame", "stop before")
    .context~package~setEncoding(encoding)
    .encoding~setDefaultEncoding(encoding)
    options COMMANDS
    interpret string
    -- Note: if the string contains a return or an exit, then you don't reach this line
    if var("result") then return result
    return


-------------------------------------------------------------------------------
::class "NullOutput"

::method say class
    -- nothing displayed


-------------------------------------------------------------------------------
--::options trace i

-- minimal inclusion to let the 'init' methods of RexxBlockDoer and Closure be executed.
/*
Remember:
See doers.cls, there are 2 "method init":
- one for RexxBlockDoer
- one for Closure
Without this requires, the blocks used in this script were not initialized correctly.
- The variable 'executable' of the blocks was uninitialized, its value was "EXECUTABLE"
  and the method ~doer returned "EXECUTABLE" instead of a routine.
- The instance variables of the closures were not created from the captured variables.
*/
::requires "extension/doers.cls"

-- For setUserData, getUserData
::requires "extension/object.cls"

-- For the list of possible default encodings
::requires "encoding/stringEncoding.cls"


-------------------------------------------------------------------------------

/*
    Under MacOs and Linux, exit codes are a number between 0 and 255.
    Other numbers can be used, but these are treated modulo 256,
    so exit -10 is equivalent to exit 246, and exit 257 is equivalent to exit 1.

    Windows uses 32-bit unsigned integers as exit codes, although the command
    interpreter treats them as signed.
*/

/*
    rexxref.pdf for EXIT instruction:
    1. If the program was called through a command interface, an attempt is made to convert the
    returned value to a return code acceptable by the underlying operating system. The returned string
    must be a whole number in the range -32768 to 32767. If the conversion fails, no error is raised,
    and a return code of 0 is returned.
    2. If you do not specify EXIT, EXIT is implied at the end of the program, but no result value is
    returned.
    3. On Unix/Linux systems the returned value is limited to a numerical value between 0 and 255.
*/
