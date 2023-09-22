separator = "-"~copies(80)

say separator
say "Object's methods"
.object~methods~pipe(.sort "byIndex" | .console {dataflow["source"]~index~quoted~left(30)} | .linecount | .console "item" "Object's methods")


say separator
say "Object's instance methods"
.object~instancemethods~pipe(.sort "byIndex" | .console {dataflow["source"]~index~quoted~left(30)}| .linecount | .console "item" "Object's instance methods")


say separator
say "Class' methods"
.class~methods~pipe(.sort "byindex" | .console {dataflow["source"]~index~quoted~left(30)} | .linecount | .console "item" "Class' methods")


say separator
say "Class' instance methods"
.class~instancemethods~pipe(.sort "byIndex" | .console {dataflow["source"]~index~quoted~left(30)} | .linecount | .console "item" "Class' instance methods")


say separator
say "RexxBlock' methods, with their defining class"
.RexxBlock~pipe(.superClasses "recursive" "once" "mem.class" | .class.instanceMethods | .sort "byIndex" | .console {index~left(30)} {dataflow["class"]~item~id})


say separator
say "All classes having their own _description_ method."
.object~pipe(.subClasses "recursive" "once" | .select {item~instanceMethods(item)~allIndexes~hasItem("_DESCRIPTION_") } | .sort | .console "item")


say separator
say "All packages that are visible from current context, including the current package (source of the pipeline)."
.context~package~pipe(.importedPackages "recursive" "once" "after" | .sort {item~name} | .console {item~name})


say separator
say "Public classes by package"
.context~package~pipe(.importedPackages "recursive" "once" "after" "mem.package" | .inject {item~publicClasses} "iterateAfter" | .sort {item~id} {dataflow["package"]~item~name} | .console {.file~new(dataflow["package"]~item~name)~name} ":" "item")


say separator
dir = ".."
count = 10
say "The "count" first files and directories in the '"dir"' directory"
dir~pipe(.fileTree | .sort | .take count | .console "item")


say separator
dir = ".."
count = 3
say "List the files and directories in the '"dir"' directory, using a pipe component"
say "Limited to" count "files per directory"
files = {use named arg depth=0, count=5; return .fileTree "rec."depth "mem.file" | .sort | .take count {dataflow["file"]~item~parent} | .console "item" | .lineCount | .console "item"}
say "files = {" files~source[1]"}"
do depth=0 to 2
    say
    say '"'dir'"~pipe(files~(depth:'depth', count:'count'))'
    dir~pipe(files~(:depth, :count))
    say
    say separator
end

say "Count the files and directories in the '"dir"' directory and all its subdirectories"
dir~pipe(.fileTree recursive | .lineCount | .console "item")


::requires "pipeline/pipe_extension.cls"

