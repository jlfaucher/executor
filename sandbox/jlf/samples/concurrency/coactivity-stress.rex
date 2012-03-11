--trace i
/*
Under WinXP 2Go, works good with 3500 consumers.

Under MacOs 4Go, failure in system service at 1280 nth consumer.
Maybe some system parameters must be changed, did not investigate.
sysctl kern.num_threads -- 2560
sysctl kern.num_taskthreads -- 2560
*/
use arg consumerCount=2
if consumerCount < 1 then return

producer = {::coactivity
            i = 1
            do forever
                --say "producer .yield["i"]"
                .yield[i]
                i += 1
            end
           }~doer

call time('r') -- to see how long this takes
do i=1 to consumerCount
    --say "i="i
    .consumer~new("consumer" i, producer~select{item // 2 == 0}~take(10))
end
.consumer~wait--Verbose

say "-----"
say producer~do

call stats

-- When debugging under Visual Studio, .Coactivity~endAll is very slow and very CPU intensive.
-- Ex : when using consumerCount=1000, then 1001 coactivies must be halted.
-- The duration is around 50s under debugger, whereas it's only around 0.2s when not under debugger.

say "-----"
say "Starting .Coactivity~endAll"
count = .Coactivity~endAll
say ".Coactivity~endAll halted" count "coactivities" 

call stats

--pause
return


-------------------------------------------------------------------------------
stats:
duration = time('e') -- elapsed duration
say "global duration="duration / 1", duration per consumer="duration / consumerCount

-- Following variables are monitoring counters added to the interpreter 
say "yieldCounter=".yieldCounter
say "addWaitingActivityCounter=".addWaitingActivityCounter
say "relinquishCounter=".relinquishCounter
say "requestAccessCounter=".requestAccessCounter
return


-------------------------------------------------------------------------------
::class consumer
::attribute counter class

::method init class
    expose counter
    counter = 0

::method wait class
    expose counter
    guard on when counter==0

::method waitVerbose class unguarded
    expose counter
    say "**** waitVerbose, counter="
    do while counter <> 0
        previous = counter
        say "***** waiting for a modification of the counter"
        guard off when previous <> counter | counter == 0
        say "***** previous value="previous", current value="counter
    end

::method init
    use strict arg ident, producer
    .consumer~counter += 1 -- do it before the reply ! 
    reply
    supplier = producer~supplier
    do while supplier~available
        --say .consumer~counter ident ":" supplier~index "->" supplier~item
        supplier~next
    end
    .consumer~counter -= 1
    --say .consumer~counter ident ": terminated"


::requires "extension/extensions.cls"

