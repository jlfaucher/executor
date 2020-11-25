separator = "-"~copies(80)

say separator
say "Object's methods"
.object~methods~pipe(.sort byIndex | .console {dataflow["source"]~index~quoted~left(30)} | .linecount | .console)


say separator
say "Object's instance methods"
.object~instancemethods~pipe(.sort byIndex | .console {dataflow["source"]~index~quoted~left(30)}| .linecount | .console)


say separator
say "Class' methods"
.class~methods~pipe(.sort byindex | .console {dataflow["source"]~index~quoted~left(30)} | .linecount | .console)


say separator
say "Class' instance methods"
.class~instancemethods~pipe(.sort byIndex | .console {dataflow["source"]~index~quoted~left(30)} | .linecount | .console)


say separator
say "RexxBlock' methods, with their defining class"
.RexxBlock~pipe(.superClasses recursive once mem.class | .class.instanceMethods | .sort byIndex | .console {index~left(30)} {dataflow["class"]~item~id})


say separator
say "All classes having their own _description_ method."
.object~pipe(.subClasses recursive once | .select {item~instanceMethods(item)~allIndexes~hasItem("_DESCRIPTION_") } | .sort | .console item)


say separator
say "All packages that are visible from current context, including the current package (source of the pipeline)."
.context~package~pipe(.importedPackages recursive once after | .sort {item~name} | .console {item~name})


say separator
say "Public classes by package"
.context~package~pipe(.importedPackages recursive once after mem.package | .inject {item~publicClasses} iterateAfter | .sort {item~id} {dataflow["package"]~item~name} | .console {.file~new(dataflow["package"]~item~name)~name} ":" item)


say separator
tmp = "~/tmp"
say "The 50 first files and directories in the "tmp" directory"
tmp~pipe(.fileTree recursive.memorize | .take 50 | .console dataflow)


say separator
say "List the files and directories in the "tmp" directory, using a pipe component"
say "files = {use arg depth=1; return .fileTree rec.depth | .sort | .console | .lineCount | .console}"
files = {use arg depth=1; return .fileTree rec.depth | .sort | .console | .lineCount | .console}
say
say '"'tmp'"~pipe(files~())'
tmp~pipe(files~())
say
say '"'tmp'"~pipe(files~(2))'
tmp~pipe(files~(2))
say
say '"'tmp'"~pipe(files~(3))'
tmp~pipe(files~(3))


say separator
say "Count the files and directories in the "tmp" directory"
tmp~pipe(.fileTree recursive | .lineCount | .console)


::requires "pipeline/pipe_extension.cls"

