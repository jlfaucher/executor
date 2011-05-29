call Doers.AddVisibilityFrom(.context)
call evaluate "demonstration"

--::options trace i
::routine demonstration

.coactivity~new('.coactivity~yield("a") ; .coactivity~yield("b")')~pipe(.upper|.displayer)

-- a collection can be sorted by index...
.array~of(b, a, c)~pipe(.sortByIndex|.displayer)

-- ...or by value
.array~of(b, a, c)~pipe(.sortByValue|.displayer)

-- all instance methods of the context
.context~instanceMethods~pipe(.sort|.displayer) -- by default, sort by index

-- private methods of the context
.context~instanceMethods~pipe(.sort|.select["return arg(1)~isPrivate"]|.displayer)

-- all packages that are visible from current context, including the current package (source of the pipeline)
.context~package~pipe(.inject["return arg(1)~importedPackages"]|.sort|.do["say arg(1)~name"])


::routine evaluate
    use strict arg routineName
    routine = .context~package~findRoutine(routineName)
    routineSource = routine~source
    do sourceline over routineSource
        if sourceline~strip~left(2) == "--" then iterate
        if sourceline~strip == "" then say
        else do
            separator = "-"~copies(sourceline~length)
            say separator
            say sourceline
            say separator
            interpret sourceline
        end
    end


::requires "extension/extensions.cls"
::requires "concurrency/coactivity.cls"
::requires "pipeline/pipe_extension.cls"
