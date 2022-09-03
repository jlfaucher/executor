::extension File inherit FileExtension

-- Should find a better name...
::class "FileExtension" mixinclass Object public

::method listFilesIfNotSymbolicLink
    /*
    Convenience method to let write :
    g=.file~new("/")~generate("listFilesIfNotSymbolicLink")~iterateAfter~recursive

    More details :

    SysFileTree for Unix does not dereference symbolic links, which is good because it's possible to create recursive paths.

    SysFileTree for Windows dereferences the symbolic links (tested with a junction), but does not crash with recursive paths.
    The buffers are allocated on the heap if needed, and I think FindFirstFile returns a NULL handle when the path becomes too long, which stops the recursion.

    File~listFiles dereferences the symbolic links...
    So MUST test SysIsFileLink when recursively walking through the directories.
    Otherwise internal buffer overflow.
    */
    use strict arg -- none
    if SysIsFileLink(self~absolutePath) then return .nil -- risk of infinite path !
    return self~listFiles
