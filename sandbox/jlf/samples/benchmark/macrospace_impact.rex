-- See stats at the end of the file

stats0 = .stats~new("stats0", 0)
stats0~display

use arg N = 1000000

call time('r')
do N
    call SysUtilVersion
end
duration = time('e')
stats1 = .stats~new("stats1", duration)
stats1~display

options "nomacrospace"
call time('r')
do N
    call SysUtilVersion
end
duration = time('e')
stats2 = .stats~new("stats2", duration)
stats2~display


::class stats

::method init
    expose ident duration yieldCounter addWaitingActivityCounter relinquishCounter requestAccessCounter getAPIManagerCounter
    use strict arg ident, duration
    -- Following variables are monitoring counters added to the interpreter
    yieldCounter = .yieldCounter
    addWaitingActivityCounter = .addWaitingActivityCounter
    relinquishCounter = .relinquishCounter
    requestAccessCounter = .requestAccessCounter
    getAPIManagerCounter = .getAPIManagerCounter

::method display
    expose ident duration yieldCounter addWaitingActivityCounter relinquishCounter requestAccessCounter getAPIManagerCounter
    say ident "duration="duration
    say ident "yieldCounter="yieldCounter
    say ident "addWaitingActivityCounter="addWaitingActivityCounter
    say ident "relinquishCounter="relinquishCounter
    say ident "requestAccessCounter="requestAccessCounter
    say ident "getAPIManagerCounter="getAPIManagerCounter
    say "-----"

/*
The duration is local to each loop.
The monitoring counters are global (no reset when starting a loop).

At work, win7, with network, 1000000 :
stats0 duration=0
stats0 yieldCounter=0
stats0 addWaitingActivityCounter=0
stats0 relinquishCounter=22
stats0 requestAccessCounter=26
-----
stats1 duration=35.094000
stats1 yieldCounter=0
stats1 addWaitingActivityCounter=0
stats1 relinquishCounter=36
stats1 requestAccessCounter=2000044
-----
stats2 duration=3.273000
stats2 yieldCounter=0
stats2 addWaitingActivityCounter=0
stats2 relinquishCounter=50
stats2 requestAccessCounter=4000062


At work, win7, without network, 1000000 :
stats0 duration=0
stats0 yieldCounter=0
stats0 addWaitingActivityCounter=0
stats0 relinquishCounter=22
stats0 requestAccessCounter=26
-----
stats1 duration=31.732000
stats1 yieldCounter=0
stats1 addWaitingActivityCounter=0
stats1 relinquishCounter=36
stats1 requestAccessCounter=2000044
-----
stats2 duration=2.995000
stats2 yieldCounter=0
stats2 addWaitingActivityCounter=0
stats2 relinquishCounter=50
stats2 requestAccessCounter=4000062


At work, puppy linux in virtualbox, with network, 1000000 :
stats0 duration=0
stats0 yieldCounter=0
stats0 addWaitingActivityCounter=0
stats0 relinquishCounter=21
stats0 requestAccessCounter=29
-----
stats1 duration=26.211558
stats1 yieldCounter=0
stats1 addWaitingActivityCounter=0
stats1 relinquishCounter=1019837
stats1 requestAccessCounter=1000047
-----
stats2 duration=2.861503
stats2 yieldCounter=0
stats2 addWaitingActivityCounter=0
stats2 relinquishCounter=2039653
stats2 requestAccessCounter=2000065


At work, puppy linux in virtualbox, without network, 1000000
stats0 duration=0
stats0 yieldCounter=0
stats0 addWaitingActivityCounter=0
stats0 relinquishCounter=21
stats0 requestAccessCounter=29
-----
stats1 duration=21.878454
stats1 yieldCounter=0
stats1 addWaitingActivityCounter=0
stats1 relinquishCounter=1019837
stats1 requestAccessCounter=1000047
-----
stats2 duration=2.711924
stats2 yieldCounter=0
stats2 addWaitingActivityCounter=0
stats2 relinquishCounter=2039653
stats2 requestAccessCounter=2000065


At home, Macos Yosemite, with WIFI network, 1000000 :
stats0 duration=0
stats0 yieldCounter=0
stats0 addWaitingActivityCounter=0
stats0 relinquishCounter=21
stats0 requestAccessCounter=25
stats0 getAPIManagerCounter=1
-----
stats1 duration=125.822719                                  <-- very slow !
stats1 yieldCounter=0
stats1 addWaitingActivityCounter=0
stats1 relinquishCounter=1019839
stats1 requestAccessCounter=1000046
stats1 getAPIManagerCounter=1000001
-----
stats2 duration=2.461318
stats2 yieldCounter=0
stats2 addWaitingActivityCounter=0
stats2 relinquishCounter=2039657
stats2 requestAccessCounter=2000067
stats2 getAPIManagerCounter=1000001

At home, Macos Yosemite, without WIFI network, 1000000 :
stats0 duration=0
stats0 yieldCounter=0
stats0 addWaitingActivityCounter=0
stats0 relinquishCounter=21
stats0 requestAccessCounter=25
stats0 getAPIManagerCounter=1
-----
stats1 duration=119.758971                                  <-- very slow !
stats1 yieldCounter=0
stats1 addWaitingActivityCounter=0
stats1 relinquishCounter=1019839
stats1 requestAccessCounter=1000046
stats1 getAPIManagerCounter=1000001
-----
stats2 duration=2.503144
stats2 yieldCounter=0
stats2 addWaitingActivityCounter=0
stats2 relinquishCounter=2039657
stats2 requestAccessCounter=2000067
stats2 getAPIManagerCounter=1000001

*/