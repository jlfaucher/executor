call Doers.AddVisibilityFrom(.context)
call evaluate "demonstration"

--::options trace i
::routine demonstration

--- Strange... without this instruction, I don't get the first comments
nop

-- The coactivity yields two results.
-- The hello outputs are not in the pipeline flow (not displayed by the .displayer).
.coactivity~new("echo hello ; .yield[a] ; say hello ; .yield[b]")~pipe(.upper|.displayer)


-- A collection can be sorted by value (default)
.array~of(b, a, c)~pipe(.sort byValue | .displayer)


-- ...or by index
.array~of(b, a, c)~pipe(.sort byIndex | .displayer)


-- ...ascending (default)
.array~of(b, a, c)~pipe(.sort byValue ascending | .displayer)


-- ...descending
.array~of(b, a, c)~pipe(.sort byValue descending | .displayer)


-- ...by index descending
.array~of(b, a, c)~pipe(.sort byIndex descending | .displayer)


-- ...descending (using a comparator).
-- The DescendingComparator use the default CompareTo, which is made on values.
.array~of(b, a, c)~pipe(.sortWith[.DescendingComparator~new] | .displayer)


-- ...caseless
.array~of("b", "A", "c", "a", "B")~pipe(.sort byValue caseless | .displayer)


-- ...stable (default)
.array~of("c:2", "b:2", "A:2", "c:1", "a:1", "B:1", "C:3")~pipe(,
    .sortWith[.InvertingComparator~new(.CaselessColumnComparator~new(3,1))] |,
    .sortWith[.CaselessColumnComparator~new(1,1)] |,
    .displayer,
    )


-- Select files whose name contains "rexx" in c:\program files\oorexx
.file~new("c:\program files\oorexx")~listFiles~pipe(,
    .select["arg(1)~name~caselessPos('rexx') <> 0"] |,
    .displayer,
    )


-- All instance methods of the context.
-- Notice that the default sort by value is useless here... Must sort by index.
.context~instanceMethods~pipe(.sort byIndex | .displayer)


-- All private methods of the context.
.context~instanceMethods~pipe(,
    .select["arg(1)~isPrivate"] |,
    .sort byIndex |,
    .displayer,
    )


-- Instance methods of the context (not including those inherited).
-- The 'instanceMethods' has been moved in the pipeline, to get the class from the current item.
-- The context is written in the pipeline, followed by the returned methods.
.context~pipe(,
    .inject["arg(1)~instanceMethods(arg(1)~class)"] |,
    .sort byIndex |,
    .displayer,
    )


-- Methods (not inherited) of all the classes whose id starts with "R".
.environment~pipe(,
    .select["arg(1)~isA(.class)"] |,
    .select["arg(1)~id~caselessAbbrev('R') <> 0"] |,
    .inject["arg(1)~methods(arg(1))"] |,
    .sort byIndex |,
    .displayer,
    )


-- All packages that are visible from current context, including the current package (source of the pipeline).
-- The .displayer is not useful here (will be extended to let choose the values to display)...
.context~package~pipe(,
    .inject["arg(1)~importedPackages"] recursive |,
    .sort |,
    .displayer,
    )


-- ...In the meantime, use the .do pipeStage to display the useful values.
-- The package names are indented to highlight the dependency between packages.
-- arg(2) returns the current index, which is always an array.

-- Notice the circular dependency between packages (supported by inject - the recursion is stopped) :
-- extensions.cls --> doers.cls --> extensions.cls
-- This is because of Doers.AddVisibilityFrom

.context~package~pipe(,
    .inject["arg(1)~importedPackages"] recursive |,
    .sort |,
    .do["say '  '~copies(arg(2)~items) arg(1)~name"],
    )


::routine evaluate
    use strict arg routineName
    routine = .context~package~findRoutine(routineName)
    routineSource = routine~source
    clause = ""
    do sourceline over routineSource
        if sourceline~strip~left(3) == "---" then iterate -- Comments starting with 3 '-' are removed
        else if sourceline~strip == "nop" then iterate -- nop is a workaround to get the first comments
        else if sourceline~strip~left(2) == "--" then say sourceline -- Comments starting with 2 '-' are kept
        else if sourceline~strip == "" then say
        else do
            say sourceline
            if sourceline~right(1) == "," then clause ||= sourceline~left(sourceline~length - 1)
            else do
                clause ||= sourceline
                interpret clause
                clause = ""
            end
        end
    end


::requires "extension/extensions.cls"
::requires "concurrency/coactivity.cls"
::requires "pipeline/pipe_extension.cls"
::requires "rgf_util2/rgf_util2_wrappers"
