/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

-- Copied from rgf_util2, needed for routine escape3
.local~rgf.non.printable=xrange("00"x,"1F"x)||"FF"x

/*
Initialization of the encodings.
Not possible to use a method 'activate' or 'init'

       *-* Compiled method INIT with scope "Object"
       *-* Compiled method NEW with scope "RexxText"
   324 *-* characters~setEntry(name, .RexxText~new(.String~new(encoded), self))
   361 *-* self~declareCharacter("combining acute accent", "cc81"x)
   358 *-* ::class "UTF_8_Encoding" subclass Encoding public
    14 *-* ::requires "extension/string.cls"
REX0093E: Error 93 running /local/rexx/oorexx/executor/sandbox/jlf-executor/samples/extension/string.cls line 324:  Incorrect call to method
REX0432E: Error 93.902:  Too many positional arguments in invocation of method; 0 expected

*/
.Byte_Encoding~initialize
.UTF_8_Encoding~initialize
.UTF_16BE_Encoding~initialize
--.UTF_16LE_Encoding~initialize

/*
These declarations must be in this source file, not in extensions.cls..
Otherwise same error as above.
*/
::extension String                          inherit EncodedString
::extension RexxText                        inherit RexxTextInitializer RexxTextPrettyPrinter RexxTextContents RexxTextOperators

--::options trace i

/******************************************************************************/
-- Should find a better name...
::class "StringHelpers" mixinclass Object public

::method quoted
    use strict arg quote='"'
    return quote || self~changeStr(quote, quote||quote)  || quote


::method unquoted
    use strict arg quote='"'
    if self~left(1) == quote & self~right(1) == quote then
        return self~substr(2, self~length - 2)~changeStr(quote||quote, quote)
    else
        return self


/*
Similar to ~makeArray(separator), with these differences:
- Can be caseless (makeArray is always case sensitive).
- If the string ends with a separator, an empty string item is added (makeArray does not).
  This is consistent with the size of the array literals :
      1,,2,3,               -- array of size 5, 3 items (sparse array)
      "1,,2,3,"~split(",")  -- array of size 5, 5 items
- If the separator is an empty string then the result is an array containing the whole string
  (makeArray returns an array containing each character of the string).
- When no separator is provided, the default value is the *current* platform end-of-line
  (makeArray is splitting on *any supported* platform end-of-line).
*/
::method split
    /*
    ""~split(";")                                   -- ['']
    ";"~split(";")                                  -- ['','']
    ";;"~split(";")                                 -- ['','','']
    "my first path;my second path"~split(";")       -- ['my first path','my second path']
    "my first path;my second path;"~split(";")      -- ['my first path','my second path','']
    "I go to school to learn english"~split("to")   -- ['I go ',' school ',' learn english']
    */
    use strict arg separator=.endofline, caseless=.false
    collectedSubstrings = .Array~new
    if self == "" then return collectedSubstrings
    rest = self || separator -- because I want an empty string when the last separator is followed by nothing
    do while rest <> ""
       if caseless then parse caseless value rest with first (separator) rest
       else             parse          value rest with first (separator) rest
       collectedSubstrings~append(first)
    end
    return collectedSubstrings


::method caselessSplit
    /*
    "I go TO school to learn english"~split("to")   -- ['I go ',' school ',' learn english']
    */
    use strict arg separator
    return self~split(separator, .true)


::method contains
    -- regex.cls uses the method .String~contains which is available only from ooRexx v5.
    forward message "pos" continue
    return result <> 0


::method caselessContains
    -- ooRexx v5
    forward message "caselessPos" continue
    return result <> 0


/******************************************************************************/
::class "StringPrettyPrinter" mixinclass Object public

::method ppString
    use arg surroundByQuotes=.true
    -- strings are surrounded by quotes, except string numbers.
    if self~dataType("N") then do
        if self < 0 then return self -- the first character is the minus sign
        return " "self               -- the first character is a space (could also display a plus sign)
    end
    pp = self
    if surroundByQuotes then pp = pp~quoted("'")
    return escape3(pp) -- JLF : Use 0xXX notation for escaped characters


/******************************************************************************/
::class "MutableBufferPrettyPrinter" mixinclass Object public

::method ppString
    -- Mutable buffers are prefixed with "M"
    pp = "M'"self~string"'"
    -- Use 0xXX notation for escaped character
    return escape3(pp)


/******************************************************************************/
::class "EncodedString" mixinclass Object public

::attribute text get
    expose text -- attribute added on the String instance
    use strict arg encoding="default"
    if \var("text") then do -- no stored counterpart
        text = .RexxText~new(self, encoding) -- store the Text counterpart created from itself with specified encoding
    end
    if arg(1, "e") then do
        -- If the encoding was explicitely specified
        encoding = .Encoding~factory(encoding)
        if text~encoding <> encoding then text~encoding=encoding
    end
    return text

::attribute text set
    expose text -- attribute added on the String instance
    use strict arg aText
    if \var("text") then do -- no stored counterpart
        if \aText~isA(.RexxText) then raise syntax 93.900 array("EncodeString: the counterpart must be a Text")
        text = aText -- store the Text counterpart passed by argument
    end
    else do
        -- A Text counterpart is already assigned.
        -- Raise an error if different from the current one
        if aText <> text then raise syntax 93.900 array("EncodedString: a Text counterpart is already assigned")
    end


::method makeRexxText
    return self~text


/******************************************************************************/
::class "RexxTextInitializer" mixinclass Object public

::method init
    expose indexer
    use strict arg string, encoding="default"
    if \string~isA(.String) then raise syntax 93.900 array("Text:" string "is not a String")
    encoding = .Encoding~factory(encoding)
    indexer = encoding~analyze(string)
    -- if we reach this point, it means the analyze is ok, otherwise an error was raised.
    string~text = self -- store itself as counterpart of string


/*
Don't activate this one.
I need to get the control when concatenating strings
::method makestring
    expose string
    return string
*/


::attribute string get
    expose indexer
    use strict arg -- none
    return indexer~string


::attribute text get
    use strict arg -- none
    return self


::attribute encoding get
    expose indexer
    use strict arg -- none
    return indexer~class


::attribute encoding set
    expose indexer
    use strict arg newEncoding
    newEncoding = .Encoding~factory(newEncoding)
    if indexer~class <> newEncoding then do
        indexer = newEncoding~analyze(indexer~string)
    end


-- Must use a method to return the indexer, because the indexer is not visible from the other mixinclasses
::method indexer -- private
    expose indexer
    return indexer


/******************************************************************************/
::class "RexxTextPrettyPrinter" mixinclass Object public

::method ppString
    -- Texts are prefixed with "T"
    pp = "T'"self~string"'"
    -- Use 0xXX notation for escaped character
    return escape3(pp)


/******************************************************************************/
::class "RexxTextContents" mixinclass Object public

-- Remember: don't use expose indexer, because it's not visible. Must use self~indexer.

::method length
    return self~indexer~graphemeIndexesSize


::method codepoints
    forward to (self~indexer)


::method codepoint
    forward to (self~indexer)


::method graphemes
    forward to (self~indexer)


::method grapheme
    forward to (self~indexer)


::method c2x
    return self~string~c2x


/******************************************************************************/
::class "RexxTextOperators" mixinclass Object public

::method " "
    use strict arg right
    right = right~request("rexxtext")
    if .nil == right then return -- no result: try the alternative message
    encoding = EncodingForConcatenation(self, right)
    return encoding~concatenate(self, encoding~spaceCharacter, right)


::method " op:right"
    use strict arg left
    left = left~request("rexxtext")
    if .nil == left then return -- no result: try the alternative message
    encoding = EncodingForConcatenation(left, self)
    return encoding~concatenate(left, encoding~spaceCharacter, self)


::method "||"
    use strict arg right
    right = right~request("rexxtext")
    if .nil == right then return -- no result: try the alternative message
    encoding =EncodingForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "||op:right"
    use strict arg left
    left = left~request("rexxtext")
    if .nil == left then return -- no result: try the alternative message
    encoding =EncodingForConcatenation(left, self)
    return encoding~concatenate(left, self)


::method "" -- abuttal
    use strict arg right
    right = right~request("rexxtext")
    if .nil == right then return -- no result: try the alternative message
    encoding =EncodingForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "op:right" -- abuttal
    use strict arg left
    left = left~request("rexxtext")
    if .nil == left then return -- no result: try the alternative message
    encoding = EncodingForConcatenation(left, self)
    return encoding~concatenate(left, self)


::routine EncodingForConcatenation
    use strict arg leftText, rightText
    return .Encoding~forConcatenation(leftText~encoding, leftText~string~isASCII, rightText~encoding, rightText~string~isASCII)


/******************************************************************************/
::class "Encoding" public

::attribute default class get
    expose default
    use strict arg -- none
    if \var("default") then default = .Byte_Encoding
    return default


::attribute default class set
    expose default
    use strict arg encodingName
    default = self~factory(encodingName)


::method factory class
    use strict arg encoding
    if encoding~isA(.Class), encoding~isSubClassOf(self) then return encoding
    encoding = encoding~upper

    if encoding == "DEFAULT" then return .Encoding~default
    if encoding == "BYTE" then return .Byte_Encoding

    if encoding == "UTF-8" then return .UTF_8_Encoding
    if encoding == "UTF8" then return .UTF_8_Encoding

    if encoding == "UTF-16BE" then return .UTF_16BE_Encoding
    if encoding == "UTF_16BE" then return .UTF_16BE_Encoding
    if encoding == "UTF16BE" then return .UTF_16BE_Encoding

    /*
    if encoding == "UTF-16LE" then return .UTF_16LE_Encoding
    if encoding == "UTF_16LE" then return .UTF_16LE_Encoding
    if encoding == "UTF16LE" then return .UTF_16LE_Encoding
    */

    -- The Unicode norm specifies that the default UTF-16 is big endian
    if encoding == "UTF-16" then return .UTF_16BE_Encoding
    if encoding == "UTF_16" then return .UTF_16BE_Encoding
    if encoding == "UTF16" then return .UTF_16BE_Encoding

    raise syntax 93.900 array("Encoding: '"encoding"' is not supported")


::method forConcatenation class
    use strict arg leftEncoding, leftIsASCII, rightEncoding, rightIsASCII
    if leftEncoding == rightEncoding then return leftEncoding
    if leftIsASCII, leftEncoding == .Byte_Encoding, rightEncoding == .UTF_8_Encoding then return rightEncoding
    if rightIsASCII, rightEncoding == .Byte_Encoding, leftEncoding == .UTF_8_Encoding then return leftEncoding
    raise syntax 93.900 array("Encoding: cannot concatenate" leftEncoding "with" rightEncoding)


::method concatenate class
    -- Arguments : zero to N text.
    s = ""
    do i = 1 to arg()
        s ||= arg(i)~string
    end
    return .RexxText~new(s, self)


::method activate class
    expose characters
    characters = .directory~new


::method declareCharacter class
    expose characters
    use strict arg name, encoded
    -- The Strings constants are made unique by the interpreter (only one occurence).
    -- Must memorize the Text with a copy of the string constant , otherwise error "a Text counterpart is already assigned"
    characters~setEntry(name, .RexxText~new(.String~new(encoded), self))


::method character class
    expose characters
    use strict arg name
    return characters~entry(name)


::method SpaceCharacter class
    expose spaceCharacter
    if \var("spaceCharacter") then spaceCharacter = self~getCharacter("space")
    return spaceCharacter


/********************/
/* Instance methods */
/********************/


::method init
    expose string codepointIndexes codepointIndexesSize graphemeIndexes graphemeIndexesSize
    use strict arg string, codepointIndexes, codepointIndexesSize, graphemeIndexes, graphemeIndexesSize


::method string
    expose string
    return string


::method codepointIndexesSize
    expose codepointIndexesSize
    return codepointIndexesSize


::method codepoints
    return .CodePointSupplier~new(self)


::method codepoint
    expose string codepointIndexes codepointIndexesSize
    use strict arg index
    if index < 1 | index > codepointIndexesSize then raise syntax 93.900 array ("Invalid codepoint index:" index)
    from = codepointIndexes[index]
    to = codepointIndexes[index+1]
    return self~class~codepoint(string, from, to)


::method graphemeIndexesSize
    expose graphemeIndexesSize
    return graphemeIndexesSize


::method graphemes
    return .GraphemeSupplier~new(self)


::method grapheme
    expose string graphemeIndexes graphemeIndexesSize
    use strict arg index
    if index < 1 | index > graphemeIndexesSize then raise syntax 93.900 array ("Invalid grapheme index:" index)
    from = graphemeIndexes[index]
    to = graphemeIndexes[index+1]
    return .RexxText~new(string~substr(from, to-from), self~class)


/******************************************************************************/
::class "Byte_Encoding" subclass Encoding public

::method initialize class
    self~declareCharacter("space", "20"x)


::method analyze class
    use strict arg string
    size = string~length -- size in bytes
    -- Bytes, codepoints and graphemes are identical
    -- The string holds all the needed informations, no need to calculate indexes
    return self~new(string, .nil, size, .nil, size)


-- Remember: don't use expose string, because it's not visible. Must use self~string.

::method codepoint
    use strict arg index
    if index < 1 | index > self~codepointIndexesSize then raise syntax 93.900 array ("Invalid codepoint index:" index)
    return self~string~subchar(index)~c2d


::method grapheme
    use strict arg index
    if index < 1 | index > self~codepointIndexesSize then raise syntax 93.900 array ("Invalid grapheme index:" index)
    return .RexxText~new(self~string~subchar(index), self~class)


/******************************************************************************/
::class "UTF_8_Encoding" subclass Encoding public

::method initialize class
    self~declareCharacter("combining acute accent", "cc81"x)
    self~declareCharacter("space", "20"x)


::method analyze class
    use strict arg string
    size = string~length -- size in bytes
    codepointIndexes = .array~new(size)
    graphemeIndexes = .array~new(size)
    index = 1
    do forever
        next = self~getchar(string, index)
        codepointIndexes~append(index)
        -- to rework, a grapheme can be made of several codepoints
        graphemeIndexes~append(index)
        if next == index then leave
        index = next
    end
    -- Return compacted arrays (their size can be lesser than string's length)
    codepointIndexes = codepointIndexes~makeArray
    graphemeIndexes = graphemeIndexes~makeArray
    return self~new(string, codepointIndexes, codepointIndexes~size-1, graphemeIndexes, graphemeIndexes~size-1)


-- precondition : the string is a valid UTF-8, the indexes are valid (1 to 4 bytes)
::method codepoint class
    use strict arg string, index, next
    size = next - index
    if size == 1 then return bitand(string, index, "7F"x)
    if size == 2 then return bitand(string, index, "1F"x)  *     64 + bitand(string, index+1, "3F"x)
    if size == 3 then return bitand(string, index, "0F"x)  *   4096 + bitand(string, index+1, "3F"x) *   64 +  + bitand(string, index+2, "3F"x)
    if size == 4 then return bitand(string, index, "07"x)  * 216144 + bitand(string, index+1, "3F"x) * 4096 +  + bitand(string, index+2, "3F"x) * 64 + bitand(string, index+3, "3F"x)
    return

bitand: procedure
    use strict arg string, index, mask
    return string~subchar(index)~bitand(mask)~c2d


-- derived from get_utf8char
-- https://rosettacode.org/wiki/Read_a_file_character_by_character/UTF8#REXX
-- Credits: Walter Pachl

::method getchar class
  use strict arg string, index
  c = string~subchar(index)
  if c == "" then return index
  index += 1
  b=c~c2x~x2b
  If left(b,1)=0 Then
    Nop
  Else Do
    p=pos('0',b)
    if p < 3 | p > 5 then raise syntax 93.900 array ("Invalid UTF-8")
    Do i=1 To p-2
      c = string~subchar(index)
      If c == "" Then raise syntax 93.900 array ("Invalid UTF-8")
      b=c~c2x~x2b
      if b~left(2) <> "10" then raise syntax 93.900 array ("Invalid UTF-8")
      index += 1
    End
  End
  Return index


/******************************************************************************/
::class "UTF_16BE_Encoding" subclass Encoding public

::method initialize class
    self~declareCharacter("combining acute accent", "0301"x)
    self~declareCharacter("space", "0020"x)


::method analyze class
    use strict arg string
    size = string~length -- size in bytes
    codepointIndexes = .array~new(size)
    graphemeIndexes = .array~new(size)
    index = 1
    do forever
        next = self~getchar(string, index)
        codepointIndexes~append(index)
        -- to rework, a grapheme can be made of several codepoints
        graphemeIndexes~append(index)
        if next == index then leave
        index = next
    end
    -- Return compacted arrays (their size can be lesser than string's length)
    codepointIndexes = codepointIndexes~makeArray
    graphemeIndexes = graphemeIndexes~makeArray
    return self~new(string, codepointIndexes, codepointIndexes~size-1, graphemeIndexes, graphemeIndexes~size-1)


-- precondition : the string is a valid UTF-8, the indexes are valid (2 or 4 bytes)
::method codepoint class
    use strict arg string, index, next
    size = next - index
    if size == 2 then return -1 -- todo
    if size == 4 then return -1 -- todo


::method getchar class
  use strict arg string, index
  length = string~length
  if index > length then return index
  if length - index < 1 then raise syntax 93.900 array ("Invalid UTF-16BE")
  c = string~substr(index, 2)
  index += 2
  if c >= "D800"x & c <= "DBFF"x then do
      -- got high surrogate, get low surrogate
      if length - index < 1 then raise syntax 93.900 array ("Invalid UTF-16BE")
      c = string~substr(index, 2)
      if \(c >= "DC00"x & c <= "DFFF"x) then raise syntax 93.900 array ("Invalid UTF-16BE")
      index += 2
  end
  return index


/******************************************************************************/
::class "CodePointSupplier" public subclass Supplier

::method init
    expose indexer index
    use strict arg indexer
    empty = .array~new(0) -- No need to create a copy, the string is immutable
    self~init:super(empty, empty)
    index = 1


::method size
    expose indexer
    return indexer~codepointIndexesSize


::method available
    expose indexer index
    return index <= indexer~codepointIndexesSize


::method index
    expose index
    if self~available then return index


::method item
    expose indexer index
    if self~available then return indexer~codepoint(index)


::method next
    expose index
    index += 1


/******************************************************************************/
::class "GraphemeSupplier" public subclass Supplier

::method init
    expose indexer index
    use strict arg indexer
    empty = .array~new(0) -- No need to create a copy, the string is immutable
    self~init:super(empty, empty)
    index = 1


::method size
    expose indexer
    return indexer~graphemeIndexesSize


::method available
    expose indexer index
    return index <= indexer~graphemeIndexesSize


::method index
    expose index
    if self~available then return index


::method item
    expose indexer index
    if self~available then return indexer~grapheme(index)


::method next
    expose index
    index += 1


/******************************************************************************/
-- Copied from rgf_util2
-- Escape non-printable chars by printing them between square brackets [].
::routine escape3 public
  parse arg a1

  res=""

  do while a1\==""
     pos1=verify(a1, .rgf.non.printable, "M")
     if pos1>0 then
     do
        pos2=verify(a1, .rgf.non.printable, "N" , pos1)

        if pos2=0 then
           pos2=length(a1)+1

        if pos1=1 then
        do
           parse var a1 char +(pos2-pos1) a1
           bef=""
        end
        else
           parse var a1 bef +(pos1-1) char +(pos2-pos1) a1

        if res=="" then
        do
           if bef \=="" then res=bef -- res=enquote2(bef) '|| '
        end
        else
        do
           res=res||bef -- res=res '||' enquote2(bef) '|| '
        end

        res=res || '['char~c2x']'
     end
     else
     do
        if res<>""  then
           res=res||a1 -- res=res '||' enquote2(a1)
        else
           res=a1

        a1=""
     end
  end
  return res
