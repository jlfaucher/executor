-- Sress script provided by Rony.
-- Regarding the syntax coloring, jEdit is on the knees with this source, see bitmap.

parse="pattern"
parse = parse "extending pattern"
parse var parse one two three
say "one:" one "from:" parse
say "two:" two "from:" parse
say "three:" three "from:" parse

someValue="xyz pattern extedning pattern 123"
parse var someValue first (parse) last
say "first:" first "from:" someValue", pattern:" parse
say "last:" last "from:" someValue", pattern:" parse


if=1
then=1
else=1

if if then say then "from branch #1"
      else if else then say else "from branch #2"

say "if:  " if
say "then:" then
say "else:" else


raise propagate  -- will "propagate" be highlighted as a subkeyword in this context?
propagate=.true  -- will ".true" be highlighed, but "propagate" not in this conetxt?

raise syntax 17.1 array ("someValue") -- will "syntax" and "array" be highlighted in this context?
array=.array~of(1,2,3) -- will "array" be highlighted in this context?

