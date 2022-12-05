a = , -- this is a continuation
"after continuation"
say a~class -- The String class
say a -- after continuation

a = ,, -- this is a continuation
"after continuation"
say a~ppRepresentation -- [..,'after continuation']
say a~shape~ppRepresentation -- [2]

a = 1,
  2,
  3,
  4
say a~class -- The String class
say a -- 1 2 3 4

a = 1,
  2,
  ,
  4
say a~class -- The String class
say a -- 1 2 4

a = 1,,
  2,,
  3,,
  4
say a~ppRepresentation -- [1,2,3,4]
say a~shape~ppRepresentation -- [4]

a = 1,,
  2,,
  ,,
  4
say a~ppRepresentation -- [1,2,..,4]
say a~shape~ppRepresentation -- [4]

options nocommands

-- Next line is evaluated as a sparse array of 2 elements
,;
say result~ppRepresentation -- [..]
say result~shape~ppRepresentation --[2]

-- Next line is evaluated as a sparse array of 2 elements followed by a continuation
,,
;
say result~ppRepresentation -- [..]
say result~shape~ppRepresentation --[2]
