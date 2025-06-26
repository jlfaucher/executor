prompt off address directory
demo on

-- Copied from array.testGroup for ooRexx5
-- and adapted.


-- tests for Array Term

a = ,;
say a~ppRepresentation -- [..]
say a~shape~ppRepresentation --[2]

a = (,)
say a~ppRepresentation -- [..]
say a~shape~ppRepresentation --[2]

a = .nil,;
say a~ppRepresentation -- [(The NIL object),..]
say a~shape~ppRepresentation -- [2]

a = .nil, .nil
say a~ppRepresentation -- [(The NIL object),(The NIL object)]
say a~shape~ppRepresentation -- [2]

a = ("string", ,)
say a~ppRepresentation -- ['string',..]
say a~shape~ppRepresentation -- [3]

a = , , "string"
say a~ppRepresentation -- [..,'string']
say a~shape~ppRepresentation -- [3]

a = (, "string",)
say a~ppRepresentation -- [..,'string',..]
say a~shape~ppRepresentation -- [3]

a = 1, "two", 3, "four"
say a~ppRepresentation -- [1,'two',3,'four']
say a~shape~ppRepresentation -- [4]

a = 1, "two", 3, "four", 5
say a~ppRepresentation -- [1,'two',3,'four',5]
say a~shape~ppRepresentation -- [5]

a = 1, "two", 3, "four", 5, "six"
say a~ppRepresentation -- [1,'two',3,'four',5,'six']
say a~shape~ppRepresentation -- [6]

a = 1, "two", 3, "four", 5, "six", 7
say a~ppRepresentation -- [1,'two',3,'four',5,'six',7]
say a~shape~ppRepresentation -- [7]

a = 1, "two", 3, "four", 5, "six", 7, "eight"
say a~ppRepresentation -- [1,'two',3,'four',5,'six',7,'eight']
say a~shape~ppRepresentation -- [8]

a = 1, "two", 3, "four", 5, "six", 7, "eight", 9
say a~ppRepresentation -- [1,'two',3,'four',5,'six',7,'eight',9]
say a~shape~ppRepresentation -- [9]

interpret "a =" "1, "~copies(10000)
say a~ppRepresentation(100) -- [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,...]
say a~shape~ppRepresentation -- [10000]

a = (1, "two", 3)~~append("string")
say a~ppRepresentation -- [1,'two',3,'string']
say a~shape~ppRepresentation -- [4]

--------------------------------------------------------------------------------
-- more tests

-- [oorexx:bugs] #2025 a[1] = 1,2,3 fails (fixed)
a = .array~new
a[1] = 1,2,3
say a~ppRepresentation -- [[1,2,3]]
say a~shape~ppRepresentation -- [1]

a = 1 + 10,20
say a~ppRepresentation -- [11,20]
say a~shape~ppRepresentation -- [2]

a = 1 + (10,20)
say a~ppRepresentation -- [11,21]
say a~shape~ppRepresentation -- [2]

a = 10,20 + 1
say a~ppRepresentation -- [10,21]
say a~shape~ppRepresentation -- [2]

a = (10,20) + 1
say a~ppRepresentation -- [11,21]
say a~shape~ppRepresentation -- [2]

a = 3+5i, 2-4i
say a~ppRepresentation -- [(3+5i),(2-4i)]
say a~shape~ppRepresentation -- [2]

-- this is classic Rexx: an assignment with no value will reset the variable to ""
-- with ooRexx5: Error 35.918:  Missing expression following assignment instruction
interpret "a=,"
say a~class -- The String class
say a -- ""

call array_literal_continuation.rex
