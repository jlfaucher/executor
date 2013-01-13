/*
Description :
    Illustration of the performance problem when adjustGap is called internally.
Usage :
    rexx perf small [silent]
    rexx perf big [silent]
*/

use arg args
silent = args~caselessPos("silent") <> 0
small = args~caselessPos("small") <> 0
big = args~caselessPos("big") <> 0

sentence = "counter is N"
counterPos = sentence~length

if small then do
    smallBuffer = .MutableBuffer~new(sentence"...", 200)
    call testReplaceAt smallBuffer, counterPos, silent
    call testDeleteInsert smallBuffer, counterPos, silent
end

if big then do
    bigBuffer = .MutableBuffer~new(sentence"...", 200 * 1000 * 1000)
    call testReplaceAt bigBuffer, counterPos, silent
    call testDeleteInsert bigBuffer, counterPos, silent
end

exit 0

testReplaceAt: procedure
use strict arg buffer, counterPos, silent
if \silent then call time('r') -- to see how long this takes
do i=10 to 20
    -- replace "N" by the counter value (adjust gap, growing)
    buffer~replaceAt(i, counterPos, 1)
    if \silent then say buffer~string "buffer length is "buffer~length", buffer size is "buffer~getBufferSize")" 

    -- undo previous replace (adjust gap, shrinking)
    buffer~replaceAt("N", counterPos, i~length)
    if \silent then say buffer~string
end
if \silent then say time('e')
return

testDeleteInsert: procedure
use strict arg buffer, counterPos, silent
if \silent then call time('r') -- to see how long this takes
do i=10 to 20
    -- delete the "N" letter (close gap)
    buffer~delete(counterPos, 1)
    if \silent then say buffer~string "buffer length is "buffer~length", buffer size is "buffer~getBufferSize")" 
    
    -- insert the counter value (open gap)
    buffer~insert(i, counterPos-1)
    if \silent then say buffer~string

    -- undo previous insert (close gap)
    buffer~delete(counterPos, i~length)
    if \silent then say buffer~string
    
    -- restore the "N" letter
    buffer~insert("N", counterPos-1)
    if \silent then say buffer~string
end
if \silent then say time('e')
return
