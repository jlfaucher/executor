::routine createDirectory public
    -- Creates the specified directory (and recursively the parents if needed).
    -- Returns 0 if the directory already exists.
    -- Returns 1 if the directory has been created.
    -- Returns -1 if the creation failed because a file (not a directory) with the same name already exists.
    -- Returns -2 if the creation failed for any other reason.
    use strict arg path
    if SysIsFileDirectory(path) then return 0
    if SysIsFile(path) then return -1
    parent = filespec("location", path)
    if parent == path then parent = filespec("location", path~substr(1, path~length - 1))
    parentStatus = createDirectory(parent)
    if parentStatus < 0 then return parentStatus
    if SysMkDir(path) <> 0 then return -2
    return 1


-------------------------------------------------------------------------------
::routine createDirectoryVerbose public
    -- Creates the specified directory.
    -- Displays an error message in case of trouble.
    -- Returns 0 if the directory already exists.
    -- Returns 1 if the directory has been created.
    -- Returns -1 if the creation failed because a file (not a directory) with the same name already exists.
    -- Returns -2 if the creation failed for any other reason.
    use strict arg path, log=.stderr
    createDirectory = createDirectory(path)
    select
        when createDirectory == -1 then 
            do
                log~lineout("[error] Can't create directory, a file with same name already exists :")
                log~lineout("[error] "path)
            end
        when createDirectory < 0 then 
            do
                log~lineout("[error] Unable to create directory :")
                log~lineout(path)
            end
        otherwise nop
    end
    return createDirectory
