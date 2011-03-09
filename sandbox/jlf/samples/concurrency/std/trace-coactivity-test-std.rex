-- You want probably : 
-- ::options trace i
-- in coactivity.cls

'rexx coactivity-test-std.rex 2>&1 | rexx trace/tracer > coactivity-test-std.trace'
'rexx trace/tracer -csv coactivity-test-std.trace > coactivity-test-std.csv'

