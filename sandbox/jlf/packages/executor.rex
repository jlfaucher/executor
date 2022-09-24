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
- If no RESULT value then returns the RC value (rexx doesn't return the RC value)
    executor -e "true"                  -- RC == 0
    executor -e "false"                 -- RC == 1      rexx returns 0
    executor -e "true; return 10"       -- RC == 10
    executor -e "false; return 10"      -- RC == 10

*/

signal on syntax name trap_error
--.environment["DEBUGOUTPUT"] = .traceOutput
.environment["DEBUGOUTPUT"] = .nullOutput

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
    else if option~left(1) == "-"  then signal unknown_option
    else if option \== ""          then signal run_script
    else if actions~isEmpty        then signal usage
    else return execute_actions()


unknown_option:
    .error~say("Unknown option" option)
usage:
    .error~say("Usage:")
    .error~say("    executor (-l libray | -p package)* [-f] filename [arguments]")
    .error~say("    executor (-l libray | -p package)*  -e  string   [arguments]")
    .error~say("    executor -v")
    return 1 -- rexx returns 256 - 1 = 255


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
        expose string args
        if args == "" then call interpret_string      -- arg() == 0
                      else call interpret_string args -- arg() == 1, whatever the number of C arguments
        -- return result and RC, if any
        res = .array~new(2)
        if var("result") then res[1] = result
        if var("RC") then res[2] = RC
        return res

        interpret_string:
            .context~package~setUserData("name", "running INSTORE")
            .context~package~setUserData("displayStackFrame", "stop before")
            options COMMANDS
            interpret string
            -- Note: if the string contains a return, then you don't reach this line
            if var("result") then return result
            return
    }


run_fscript:
    call shift_c_args -- remove -f
run_script:
    filename = c_arg()
    if filename == "" then do
        .error~say("Missing filename")
        signal usage
    end
    if .nil == .context~package~findProgram(filename) then raise syntax 3.901 array (filename)
    call shift_c_args -- remove filename to be aligned with rexx
    args = remaining_c_args() -- as a string
    return execute_actions{
        expose filename args
        .context~package~setUserData("displayStackFrame", "stop before")
        if args == "" then call (filename)      -- arg() == 0
                      else call (filename) args -- arg() == 1, whatever the number of C arguments
        -- return result and RC, if any
        res = .array~new(2)
        if var("result") then res[1] = result
        if var("RC") then res[2] = RC
        return res
    }


display_version:
    "rexx -v"
    return RC


execute_actions: procedure expose actions
    use strict arg final_action=.nil
    signal on syntax name action_error

    -- Load all the extensions packages
    call loadPackage "extension/extensions.cls"
    call loadPackage "pipeline/pipe_extension.cls"
    call loadPackage "rgf_util2/rgf_util2.rex"

    -- Run the intermediate actions (load the libraries/packages specified on the command line)
    results = actions~each("do")
    ok = results~reduce("&", initial:.true) -- each action returns either a boolean result or no result
    if \ok then do
        -- at least one action has returned a .false value, stop now
        if var("RC") then return RC(RC) -- assume it's an error code, so apply the transformation
        return RC(1) -- arbitrary value of error code (no equivalent with rexx)
    end

    call declareAllPublicClasses
    call declareAllPublicRoutines

    if .nil \== final_action then do
        res = final_action~do
        if res~hasIndex(1) then action_result = res[1]
        if res~hasIndex(2) then action_RC = res[2]
    end

    return:
    if var("action_result") then return action_result
    if var("action_RC") then return action_RC -- here, it's not an error code, so return as-is
    return 0

    action_error:
    if var("result") then action_result = result
    if var("RC") then action_RC = RC(RC) -- here, it's an error code, so apply the transformation
    call sayCondition condition("O")
    signal return


-- Global
-- 1st need: catch 3.901 raised when findProgram returns .nil
trap_error:
    call sayCondition condition("O")
    if var("RC") then return RC(RC) -- here, it's an error code, so apply the transformation
    return


-------------------------------------------------------------------------------

-- To be aligned with rexx, apply this transformation when returning the RC value to the OS.
-- Not clear why the negative value gives 255-value on OS side, because the returned value is an int, not an uint8...
-- Maybe it's the OS which convert the returned value to an uint8 ?
/*
int main (int argc, char **argv) {
    ...
        rc = pgmThrdInst->DisplayCondition();
        if (rc != 0) {
            pgmInst->Terminate();
            return -rc;   // well, the negation of the error number is the return code
        }
        if (result != NULL) {
            pgmThrdInst->ObjectToInt32(result, &rc);
        }

        pgmInst->Terminate();

        return rc;
    ...
*/
::routine RC
    use strict arg value
    return 255 - value


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
