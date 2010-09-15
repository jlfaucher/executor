[JLF sept 15, 2010] Fixed in trunk revision 6147

Current implementation of MutableBuffer~replaceAt calls adjustGap when needed.
This script illustrates the performance problem of adjustGap, which occurs because
the encapsulated buffer's dataLength is equal to its bufferSize.
When the buffer size is 200Mb then adjusGap always use a dataLength equal to 200Mb,
even if the mutable buffer's dataLength is 16 characters...

The methods delete and insert don"t have this problem, because they call
openGap and closeGap which doesn't depend on the encapsulated buffer size.


The small buffer size is 200 bytes.
The big buffer size is 200 * 1000 * 1000 bytes.
In both case, the tests are made with a data length which is 16 characters or less


rexx perf small : 
testReplaceAt needs 0.001490
testDeleteInsert needs 0.000389

valgrind --tool=callgrind rexx perf small silent
13,112,534


rexx perf big :
testReplaceAt needs 1.933851			<-- problem here
testDeleteInsert needs 0.003299

valgrind --tool=callgrind rexx perf small silent
1,163,127,212					<-- problem here
