use arg takeNumber=10

do count=1 to takeNumber

    -- *NAIVE* generation of factorials from 1! :
    call time('r')
    g=0~generateI{item+1}~recursive~eachI{item[1]~times.generate~reduce("*")}
    g~take(count)~iterator~each{::closure expose takeNumber ; say item[2]"! =" item[1]}
    duration = time('e') -- elapsed duration
    stats1 = .stats~new("stats1", duration)
    
    say "-----"
    
    -- Less naive generation of factorials from 0! :
    call time('r')
    g=0~generateI{if item == 0 then 1; else stack[1] * depth}~recursive
    g~take(count+1)~iterator~each{::closure expose takeNumber ; say item[3]"! =" item[1]}
    duration = time('e') -- elapsed duration
    stats2 = .stats~new("stats2", duration)
    
    say "-----"
    stats1~display
    say "-----"
    stats2~display
    say "-----"

end

count = .Coactivity~endAll
say ".Coactivity~endAll halted" count "coactivities" 

return

-------------------------------------------------------------------------------
::requires "extension/extensions.cls"

::class stats

::method init
    expose ident duration yieldCounter addWaitingActivityCounter relinquishCounter requestAccessCounter
    use strict arg ident, duration
    -- Following variables are monitoring counters added to the interpreter 
    yieldCounter = .yieldCounter
    addWaitingActivityCounter = .addWaitingActivityCounter
    relinquishCounter = .relinquishCounter
    requestAccessCounter = .requestAccessCounter

::method display
    expose ident duration yieldCounter addWaitingActivityCounter relinquishCounter requestAccessCounter
    say ident "duration="duration
    say ident "yieldCounter="yieldCounter
    say ident "addWaitingActivityCounter="addWaitingActivityCounter
    say ident "relinquishCounter="relinquishCounter
    say ident "requestAccessCounter="requestAccessCounter

