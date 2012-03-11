-- Remember : concurrency trace is displayed only when the env variable RXTRACE_CONCURRENCY=ON
-- You want probably : 
-- ::options trace i
-- in coactivity-test.rex, coactivity.cls and maybe in doers.cls

'rexx coactivity-test.rex 2>&1 | rexx trace/tracer > coactivity-test.trace'
'rexx trace/tracer -csv coactivity-test.trace > coactivity-test.csv'

