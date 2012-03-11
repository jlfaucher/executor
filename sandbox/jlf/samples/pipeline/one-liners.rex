separator = "-"~copies(80)

say separator
say "Object's methods with their identity hash"
.object~methods~pipe(.sort byIndex | .console {dataflow["source"]~index~quoted~left(17)} " : " {item~identityHash} | .linecount | .console)


say separator
say "Object's instance methods with their identity hash"
.object~instancemethods~pipe(.sort byIndex | .console {dataflow["source"]~index~quoted~left(17)} " : " {item~identityHash} | .linecount | .console)


say separator
say "Class' methods with their identity hash"
.class~methods~pipe(.sort byindex | .console {dataflow["source"]~index~quoted~left(17)} " : " {item~identityHash} | .linecount | .console)


say separator
say "Class' instance methods with their identity hash"
.class~instancemethods~pipe(.sort byIndex | .console {dataflow["source"]~index~quoted~left(17)} " : " {item~identityHash} | .linecount | .console)


say separator
say "RexxBlock' methods, with their defining class"
.RexxBlock~pipe(.superClasses recursive once mem.class | .methods | .sort byIndex | .console {index~left(20)} {dataflow["class"]~item~id})


say separator
say "All classes having their own _description_ method."
.object~pipe(.subClasses recursive once | .select {item~instanceMethods(item)~allIndexes~hasItem("_DESCRIPTION_") } | .sort | .console item)


say separator
say "All classes understanding the ~help method"
.object~pipe(.subClasses recursive once | .select {item~hasMethod("help") } | .sort | .console item)


say separator
say "All packages that are visible from current context, including the current package (source of the pipeline)."
.context~package~pipe(.importedPackages recursive once after | .sort {item~name} | .console {item~name})


say separator
say "Public classes by package"
.context~package~pipe(.importedPackages recursive once after mem.package | .inject {item~publicClasses} iterateAfter | .sort {item~id} {dataflow["package"]~item~name} | .console {.file~new(dataflow["package"]~item~name)~name} ":" item)


say separator
say "The 50 first files and directories in the /tmp directory"
"/tmp"~pipe(.fileTree recursive.memorize | .take 50 | .console dataflow)


say separator
say "Count the files and directories in the /tmp directory"
"/tmp"~pipe(.fileTree recursive | .lineCount | .console)


::requires "pipeline/pipe_extension.cls"

