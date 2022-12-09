/*
internalIndexer is a private method that must not be used in production.
This method gives access to the instance of StringIndexer linked to the text.
*/

arg(1)~internalIndexer~stringsCache~pipe(-
    .sort "byindex" |-
    .console {index~ppstring~left(35)} ":" {item~description~left(75)} {item~ppstring~left(100)}-
)

::requires "pipeline/pipe_extension.cls"
