-- You want probably : 
-- ::options trace i
-- in coactivity.cls

'rexx coactivity-test.rex 2>&1 | rexx trace/tracer > coactivity-test.trace'
'rexx trace/tracer -csv coactivity-test.trace > coactivity-test.csv'

