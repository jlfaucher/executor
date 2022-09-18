/*
This script allows to execute a script which depends on extensions, without
having to modify the script to requires the packages.
*/

parse arg script args
if script == "" then signal usage

.syscargs~delete(1) -- remove <my script> to be aligned with rexx

call declareAllPublicClasses
call declareAllPublicRoutines

call (script) args
return RC

usage:
say "Usage:"
say "executor <my script> <arg1> <arg2> ..."
return RC

--::options trace i
::requires "extension/extensions.cls"
::requires "pipeline/pipe_extension.cls"
::requires "rgf_util2/rgf_util2.rex"

-------------------------------------------------------------------------------
::routine declareAllPublicClasses
    -- Add all the public and imported public classes to .environment.

    package = .context~package
    call declare_classes package~publicClasses -- of executor.rex, if any
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
::routine declareAllPublicRoutines
    -- Add all the public and imported public routines to .globalRoutines.

    -- Official ooRexx doesn't support .globalRoutines
    -- Make it work without error, will have no effect on global visibility
    if .nil == .environment["GLOBALROUTINES"] then .environment["GLOBALROUTINES"] = .directory~new

    package = .context~package
    call declare_routines package~publicRoutines -- of executor.rex, if any
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
