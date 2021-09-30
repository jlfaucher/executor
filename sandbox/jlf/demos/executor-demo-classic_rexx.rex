demo on

---------------
-- Classic Rexx
---------------

/*
Executor has been adapted to improve the compatibility with classic rexx:
- added support for variables # @ $ ¢
- added support for assignment V=   (assign "")
- added support for instruction UPPER var1 var2 ...
*/
sleep no prompt

/*
Illustration by running the Rosetta Code solutions for REXX.
The solutions are installed locally from https://github.com/acmeism/RosettaCodeData
The script RunRosettaCode must be executed from the directory which contains the directory Lang.
*/
sleep
system
sleep
cd /local/RosettaCodeData/git
sleep
ls Lang/Rexx
sleep
ls Lang/Rexx | wc
sleep 3 no prompt

/*
There are more than 600 REXX solutions.
For the moment, the script covers 213 solutions.
The script lets list or execute all the covered solutions.
The solutions can be filtered by number or by name.
*/
sleep
rexx runRosettaCode
sleep 5 no prompt

/*
Some solutions are skipped because they take too much time, or are incomplete,
or execute a system command which may be dangerous.
*/
sleep
rexx runRosettaCode -list
sleep 5 no prompt

/*
Start the execution of all the REXX solutions.
Some solution takes time to calculate, hence the scrolling pauses.
*/
sleep
rexx runRosettaCode -run
sleep no prompt

/*
Results for Regina:         Results for ooRexx5:
Ok=173                      Ok=75
Skip=17                     Skip=16
Ko=23                       Ko=122
duration=253.671976         duration=23.638713
*/
sleep no prompt

/*
End of demonstration.
*/
prompt directory on
demo off
