::routine createDirectory public
    -- Creates the specified directory.
    -- Returns 0 if the directory already exists.
    -- Returns 1 if the directory has been created.
    -- Returns -1 if the creation failed because a file (not a directory) with the same name already exists.
    -- Returns -2 if the creation failed for any other reason.
    use strict arg path
    if SysIsFileDirectory(path) then return 0
    if SysIsFile(path) then return -1
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
