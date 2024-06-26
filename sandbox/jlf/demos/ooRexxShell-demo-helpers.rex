prompt off directory
demo on

--------------
-- ooRexxShell
--------------
sleep no prompt

/*
Helper to display the system PATH:
?path v1 v2 ... : display value of system variable, splitted by path separator.
If no variable is specified then the value of the system variable PATH is displayed.
*/
sleep
?path
sleep no prompt

/*
Filter the system PATH to see only the folders in relation with rexx.
?path = rexx
*/
sleep
?path = rexx
sleep no prompt

/*
Display the LIBRARY_PATH (Linux)
?path LIBRARY_PATH
*/
sleep
?path LIBRARY_PATH
sleep no prompt

/*
Display the DYLD_LIBRARY_PATH (MacOs)
?path DYLD_LIBRARY_PATH
*/
sleep
?path DYLD_LIBRARY_PATH
sleep no prompt

/*
Display the CLASSPATH
?path CLASSPATH
*/
sleep
?path CLASSPATH
sleep no prompt

/*
End of demonstration.
*/
demo off
