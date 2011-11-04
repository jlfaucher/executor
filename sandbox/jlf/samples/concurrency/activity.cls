/*
An activity is a thread of execution that can run methods concurrently with methods on other activities.
An activity contains a stack of invocations that represent the Rexx programs running on the activity.
*/

if .context~package~loadLibrary("rxunixsys") then
    .local~rxunixsys.loaded = .true
else
    .local~rxunixsys.loaded = .false


--::options trace i
::options NOMACROSPACE

--------------------------------------------------------------------------------
::class "Activity" public

-- Emulate an Activity's environmement : one entry per activity, the key is the thread id.
-- See RFE 2868655 : "Add ThreadLocal concept".
-- Each entry is a directory.
--::attribute directory class private

::method init class
    expose directory
    directory = .Directory~new


::method currentThreadId class
    if .rxunixsys.loaded then return SysGetTid() -- Unix
    else return SysQueryProcess("TID") -- Windows


::method local class
    expose directory
    threadId=self~currentThreadId
    local = directory[threadId]
    if local == .nil then do
        local = .Directory~new
        directory[threadId] = local
    end
    return local

