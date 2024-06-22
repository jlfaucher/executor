-- Return a string whose encoding is that of the MutableBuffer.
.MutableBuffer~define("stringNative", .MutableBuffer~method("string"))
.MutableBuffer~define("string", "forward message 'encodedString'")

::extension RexxText        inherit RexxTextInitializer
::extension RexxText        inherit RexxTextContents
::extension RexxText        inherit RexxTextOperators
::extension RexxText        inherit RexxTextStringInterface
-- ::extension RexxText        inherit RexxTextPrettyPrinter    -- Moved to notrace.cls

::extension String          inherit EncodedString
::extension String          inherit StringRexxTextInterface

::extension MutableBuffer   inherit EncodedMutableBuffer

::extension Package         inherit EncodedPackage

::extension RexxBlock       inherit EncodedRexxBlock

::requires "extension/string.cls"   -- for escape3
::requires "encoding/stringEncoding.cls"

--::options trace r

/******************************************************************************/
/*
TODOs

Test if the cache optimization of the methods isXXX is useful
Testing 'if var("XXX")' has a cost.

07/08/2022
I tested
    t = "hello"~text
    do 1000000; t~isUnicode; end
If I don't cache the value on the RexxText then it's +1 sec
But even if it's a little bit faster, I think I should not pollute my code with such optimizations everywhere.
*/


/******************************************************************************/
/*
WON'T DOs

Will not support arithmetic with digits encoded in UTF-16 or UTF-32
"41"~text~utf16~c2u=    -- 'U+0034 U+0031'
"41"~text~utf16 + 0=    -- error UTF-16BE '[00]4[00]1' is not compatible with a Rexx numeric value.

Will not support x2b, x2c, x2d with hexadecimal digits encoded in UTF-16 or UTF-32
"41"~text~utf16~x2b=    -- error UTF-16BE '[00]4[00]1' is not compatible with a Rexx hexadecimal value.

b2x, c2x, d2x will always return a String, not a RexxText.
So "41"~text~utf16~c2x will not return an UTF-16 representation of the hexadecimal digits.

*/


/******************************************************************************/
::routine textPackage public
    return .context~package


/******************************************************************************/
::extension Object

/*
By default, an object is compatible with String (can be converted to a string).
See also this same method on RexxText and String.
*/
::method isCompatibleWithByteString class
    return .true

::method isCompatibleWithByteString
    return .true


/*
Should find a better name (like requestEncodedStringable) but I find the current name crystal clear.
At the moment of writing this comment, the result can be a RexxText or a MutableBuffer or a String.

The purpose of this method is to avoid to create systematically a RexxText when
needing an object supporting the Trait "EncodedStringable".
::Trait "EncodedStringable"
::method ~encoding
::method ~isCompatibleWithASCII

A RexxText is returned as-is.
A MutableBuffer is returned as-is (avoid to request a String from it)
A String is returned as a RexxText if already associated to a RexxText, otherwise returned as-is.
For any other object, a String is requested.

Here, we are in the case any other object.
See also this same method on RexxText and MutableBuffer and String.
*/
::method requestTextOrBufferOrString class
    string = self~request("STRING")
    if .nil <> string then return string
    return self~string

::method requestTextOrBufferOrString
    string = self~request("STRING")
    if .nil <> string then return string
    return self~string


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isTextOrBufferOrString class
    return .false

::method isTextOrBufferOrString
    return .false


/*
Should find a better name (like requestByteEncodedStringable) but I find the current name crystal clear.
At the moment of writing this comment, the result can be a MutableBuffer or a String.

The purpose of this method is to avoid to create systematically a String when
needing an object supporting the Trait "ByteEncodedStringable".
::Trait "ByteEncodedStringable"
::method ~encoding
::method ~isCompatibleWithASCII

A RexxText is returned as a String.
A MutableBuffer is returned as-is (avoid to request a String from it)
A String is returned as-is.
For any other object, a String is requested.

Here, we are in the case any other object.
See also this same method on RexxText and MutableBuffer and String.

-----------
First need:
-----------
.utf8_encoding~previousCodepointIndexB("🎅noël", 2)=
utf8proc raises "Invalid UTF-8 string" because the string "🎅noël" is converted
automatically to text
and this kind of comparison occurs :
    if startByte < "80"x
where startByte is a RexxText
because startByte = string~subchar(indexB)
==> the comparison startByte < "80"x is a Unicode comparison.

*/
::method requestBufferOrString class
    string = self~request("STRING")
    if .nil <> string then return string
    return self~string

::method requestBufferOrString
    string = self~request("STRING")
    if .nil <> string then return string
    return self~string


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isBufferOrString class
    return .false

::method isBufferOrString
    return .false


/******************************************************************************/
::class "EncodedString" mixinclass Object private

/*
    aString
     ▲  text --------> aRexxText
     │                     indexer (anEncoding)
     │                          codepoints (sequential access)
     │                          characters  (direct access to graphemes)
     +-<---------------------<- string
*/

/*
    REMEMBER!
    The string's encoding is lost when using a string's method which returns a string
    (like left, right, substr, etc...).
    Exception:
    The 'string' method is ok because it returns the string itself (no copy).
*/

::method text
    expose encoding myText -- attribute added on the String instance
    -- Don't use the exposed encoding as default value because can be unassigned.
    -- Use the attribute encoding which returns the default encoding if unassigned.
    use strict arg textEncoding=(self~encoding)
    if \var("myText") then do -- no stored counterpart
        myText = .RexxText~new(self, textEncoding) -- store the RexxText counterpart created from itself with specified encoding
        -- self~!setText(myText) -- Object "<string>" does not understand message "!SETTEXT"
        forward to (self) message "!SETTEXT" array(myText) continue -- no dynamic target
    end
    else if arg(1, "e") then do
        -- If the encoding was explicitely specified then change the encoding
        textEncoding = .Encoding~factory(textEncoding, self~string)
        if myText~encoding <> textEncoding then do
            -- "Noël"~text("utf8") == "Noël"~text("byte")=  -- true because "Noël" is the same interned string in both expressions
            -- Next line is an attempt to detect this strange situation, but it's not perfect.
            -- if var("encoding") then raise syntax 23.900 array("EncodedString: The text method can't overwrite the current encoding" encoding~name "with" textEncoding~name)
            myText~encoding = textEncoding
        end
    end
    -- align string & text encoding.
    encoding = myText~encoding
    self~!setEncoding(encoding)
    return myText


::attribute text set -- private
    -- Can't declare this method private, because it's used by RexxText
    -- But the assignment is secured:
    -- If not yet linked to a RexxText then only a RexxText linked to this string can be assigned
    -- If already linked to a RexxText then only this RexxText is accepted
    expose encoding myText -- attribute added on the String instance
    use strict arg aText
    if .nil == aText then do
        self~detach
        return
    end
    if \var("myText") then do -- no stored counterpart
        if aText~isA(.RexxText), aText~string~identityHash == self~identityHash then do
            myText = aText -- store the RexxText counterpart passed by argument
            -- self~!setText(myText) -- Object "<string>" does not understand message "!SETTEXT"
            forward to (self) message "!SETTEXT" array(myText) continue -- no dynamic target
        end
        else raise syntax 23.900 array("EncodedString: the counterpart must be a RexxText linked to this String")
    end
    else do
        -- A RexxText counterpart is already assigned.
        -- Raise an error if different from the current one
        if aText~identityHash <> myText~identityHash then do
            -- Must test identityHash because operator "<>" overloaded to test the Unicode characters
            raise syntax 23.900 array("EncodedString: a RexxText counterpart is already assigned")
        end
    end
    -- align string & text encoding.
    encoding = myText~encoding
    self~!setEncoding(encoding)


::method detach
    expose myText
    use strict arg -- none

    if var("myText") then do
        -- detach the string from its text
        myOldText = myText
        drop myText -- do it now to avoid infinite recursion
        self~!setText -- OREF_NULL
        myOldText~detach
    end


::attribute encoding get
    expose encoding myText
    use strict arg -- none
    if var("myText") then return myText~encoding
    if var("encoding") then return encoding
    return .Encoding~defaultEncoding


::attribute encoding set
    expose encoding myText
    use strict arg newEncoding
    if .nil == newEncoding then do
        if var("myText") then myText~encoding = newEncoding -- will raise an error because .nil not supported
        drop encoding
        self~!setEncoding -- OREF_NULL
    end
    else do
        newEncoding = .Encoding~factory(newEncoding, self~string)
        if var("myText") then myText~encoding = newEncoding
        encoding = newEncoding
        self~!setEncoding(encoding)
    end


::method setEncoding
    use strict arg newEncoding=(self~encoding)
    if self~hasEncoding then previousEncoding = self~encoding
                        else previousEncoding = .nil
    self~encoding = newEncoding
    return previousEncoding


::method hasEncoding
    expose encoding
    use strict arg -- none
    return var("encoding")


::method hasText
    expose myText
    use strict arg -- none
    return var("myText")


::method makeRexxText
    use strict arg -- none
    return self~text


::method makeRexxTextOrString
    use strict arg returnString=.false
    if returnString then return self
    return self~text


/*
Allows to use a String or a MutableBuffer or a RexxText indistinctly.
Here, we are on a String.
Return a text only if already created.
Otherwise return the string.
*/
::method requestTextOrBufferOrString
    expose myText
    use strict arg -- none
    if var("myText") then return myText
    return self


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isTextOrBufferOrString
    use strict arg -- none
    return .true -- it's a String


/*
Allows to use a String or a MutableBuffer or a RexxText indistinctly.
Here, we are on a String.
Always return the string (see also the implementation on MutableBuffer and RexxText)
*/
::method requestBufferOrString
    use strict arg -- none
    return self -- a string


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isBufferOrString
    use strict arg -- none
    return .true -- it's a String


::method copy
    -- If the string is linked to a RexxText then the RexxText must also be cloned.
    expose myText
    use strict arg -- none
    if \var("myText") then return self~copy:super
    textCopy = myText~copy
    return textCopy~string


/******************************************************************************/
::class "EncodedMutableBuffer" mixinclass Object private

/*
    Nothing sophisticated here...
    Just manage the attribute 'encoding', to know what is the current encoding of the MutableBuffer.
    By "current", I mean that this encoding may change during the life of the MutableBuffer,
    especially when doing concatenations. For example, an UTF-8 buffer will become a WTF-8 buffer
    when appending a WTF-8 string.
    There is no analysis of contents, no indexer, no associated text.
    The analysis is done when a RexxText instance is created from the buffer's string.
*/

/*
    REMEMBER!
    The buffer's encoding is lost when using a buffer's method which returns a string
    (like left, right, substr, etc...).
    Exception:
    The 'string' method is redefined to keep the encoding (forwards the message "encodedString").
*/

-- TODO: make it native
-- Remember: needed to fix RexxMutableBufferClass::newRexx to pass all the new's arguments to init
::method init_extended
    expose encoding
    -- if the optional argument 'string' is provided then memorize its encoding
    if arg(1, "e"), arg(1)~hasEncoding then encoding = arg(1)~encoding
    -- forward class (super) -- don't forward, that would raise an unknown method


::attribute encoding get
    expose encoding
    use strict arg -- none
    if var("encoding") then return encoding
    return .Encoding~defaultEncoding


::attribute encoding set
    expose encoding
    use strict arg newEncoding
    if .nil == newEncoding then do
        drop encoding
        self~!setEncoding -- OREF_NULL
    end
    else do
        encoding = .Encoding~factory(newEncoding, self~string)
        self~!setEncoding(encoding)
    end


::method setEncoding
    use strict arg newEncoding=(self~encoding)
    if self~hasEncoding then previousEncoding = self~encoding
                        else previousEncoding = .nil
    self~encoding = newEncoding
    return previousEncoding


::method hasEncoding
    expose encoding
    use strict arg -- none
    return var("encoding")


-- Apparently, this method is not called when named "string"
-- Maybe a problem with inherited methods
-- Workaround: see at the begining of this file
::method encodedString
    expose encoding
    use strict arg -- none
    string = self~stringNative
    if var("encoding") then string~encoding = encoding
    return string


/*
Allows to use a String or a MutableBuffer or a RexxText indistinctly.
Here, we are on a MutableBuffer.
Return directly the buffer, without requesting a string from it.
*/
::method requestTextOrBufferOrString
    use strict arg -- none
    return self


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isTextOrBufferOrString
    use strict arg -- none
    return .true -- it's a MutableBuffer


/*
Allows to use a String or a MutableBuffer or a RexxText indistinctly.
Here, we are on a MutableBuffer.
Return directly the buffer, without requesting a string from it.
*/
::method requestBufferOrString
    use strict arg -- none
    return self


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isBufferOrString
    use strict arg -- none
    return .true -- it's a MutableBuffer


::method description
    /*
    .MutableBuffer~new("noël👩‍👨‍👩‍👧🎅")~description(short:1)      -- 'UTF-8 not-ASCII by default'
    .MutableBuffer~new("noël👩‍👨‍👩‍👧🎅")~description               -- 'UTF-8 not-ASCII by default (34 bytes)'
    */
    use strict arg -- none
    use strict named arg short=.false, technical=.false /* not used */
    sizesDescription = ""
    if \short then sizesDescription = "(" ||,
                                      self~length~singularPluralCount("byte", "bytes"),
                                      || ")"
    -- It's useful to know if the buffer has an explicit encoding (because impacts the concatenation)
    defaultEncoding = ""
    if \self~hasEncoding then defaultEncoding = "by default"
    return " "~join(self~encoding~description(self~isASCII), defaultEncoding, sizesDescription)


::method descriptionForError
    -- Display the <length> first characters
    use strict arg length=10
    string = self~substr(1, min(length, self~length)) -- left
    if self~length > length then string = string~left(length - 3)"..."
    -- escape3 is needed to have a proper display like this: [00]4[00]1
    return self~description(short:1) "'"escape3(string)"'"


::method isCompatibleWithASCII
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if self~encoding~isCompatibleWithASCII, self~isASCII then return .true
    return .false


-- If you modify this method then see if the method IndexerHelpers~append (at class level) must be modified as well
::method appendEncoded
    -- I tried to use the name "append" for this method, but it's a bad idea!
    -- ~append must remain the native implementation, because it's used in many
    -- places, and because a stack overflow occurs.

    -- Positional arguments : zero to N text or buffer or string.
    use strict arg ...
    use strict named arg buffer=.nil -- yes, support this parameter, to offer the same interface as .RexxText~appendEncoded
    if .nil == buffer then buffer = self
    if buffer \== self then buffer~appendEncoded(self)

    do i=1 to arg()
        text = arg(i)~requestTextOrBufferOrString
        if .nil == text then signal must_have_a_text_or_buffer_or_string_value
        encoding = .Encoding~forConcatenation(buffer, text) -- raise an error if not compatible
        buffer~encoding = encoding
        encoding~concatenate(text, :buffer)
    end
    return buffer

    must_have_a_text_or_buffer_or_string_value: raise syntax 93.900 array("Method positional argument "i" must have a text or buffer or string value")


/******************************************************************************/
::class "EncodedPackage" mixinclass Object private

/*
    Nothing sophisticated here...
    Just manage the attribute 'encoding', to know what is the encoding of the Package.
    This encoding is used when evaluating a String literal, to decide if the string must be converted to a RexxText.
    Todo later: support ::options encoding <anEncoding>
*/

::attribute encoding get
    -- REMEMBER!
    -- This method is called EACH TIME a string literal is evaluated, for the rule R2
    expose hasImportedTextPackage encoding
    use strict arg -- none

    -- Return the stored encoding, if any
    if var("encoding") then return encoding

    /*
    If the text package is requested (directly or indirectly), we consider that
    the package supports RexxText and any default encoding.

    REMEMBER! Don't limit the rule to "If the text package is requested directly",
    because as soon as text.cls is loaded (directly or indirectly), the message
    "encoding" is understood, and the variable hasImportedTextPackage is calculated
    only once. That would imply different results in function of the ::requires:
        ::requires "extension/text.cls"
        ::requires "extension/extensions.cls"
    would calculate hasImportedTextPackage = .true
    whereas
        ::requires "extension/extensions.cls"
        ::requires "extension/text.cls"
    could calculate hasImportedTextPackage = .false if a string literal is
    evaluated before the explicit ::requires.
    */
    if \var("hasImportedTextPackage") then hasImportedTextPackage = hasImportedPackage(self, textPackage())

    -- If the package is text-aware then return the default encoding.
    if hasImportedTextPackage then return .Encoding~defaultEncoding

    -- Here, we consider it's a legacy package not supporting RexxText.
    -- By returning The Byte_Encoding, we deactivate the automatic conversion to RexxText.
    -- And since The Byte_Encoding is always absorbed by the other encodings, we eliminate the concatenaion/comparison errors.
    return .Byte_encoding

    hasImportedPackage: procedure
        use strict arg importer, package
        importedPackages = importer~importedPackages
        if importedPackages~hasItem(package) then return .true
        do importer over importedPackages
            if hasImportedPackage(importer, package) then return .true
        end
        return .false


::attribute encoding set
    expose encoding
    use strict arg newEncoding
    if .nil == newEncoding then do
        drop encoding
        self~!setEncoding -- OREF_NULL
    end
    else do
        encoding = .Encoding~factory(newEncoding, self~string)
        self~!setEncoding(encoding)
    end


::method setEncoding
    use strict arg newEncoding=(self~encoding)
    if self~hasEncoding then previousEncoding = self~encoding
                        else previousEncoding = .nil
    self~encoding = newEncoding
    return previousEncoding


::method hasEncoding
    expose encoding
    use strict arg -- none
    return var("encoding")


/******************************************************************************/
::class "EncodedRexxBlock" mixinclass Object private

/*
    Nothing sophisticated here...
    The encoding of a RexxBlock is given by the package of its source literal.
    This encoding is used when evaluating a String literal inside the block, to decide if the string must be converted to a RexxText.
*/

::attribute encoding get
    forward to (self~rawExecutable~package)


::attribute encoding set
    forward to (self~rawExecutable~package)


::method setEncoding
    forward to (self~rawExecutable~package)


::method hasEncoding
    forward to (self~rawExecutable~package)


/******************************************************************************/
::class "RexxTextInitializer" mixinclass Object private

::method init
    -- The RexxText is not referencing directly the String, it's the indexer
    expose indexer /* rest is optim */ string text encoding
    use strict arg argString, argEncoding=(argString~encoding)
    .validate~classtype("1", argString, .string)
    -- Some strings are interned by the interpreter, and the same instance can be returned
    -- at different occasions.This is the case for the empty string (null string singleton
    -- OREF_NULLSTRING. If the string is already linked to a RexxText then a new instance
    -- must be created (don't make a copy, that would copy the link to the RexxText).
    if argString~hasText then argString = .String~new(argString)
    argEncoding = .Encoding~factory(argEncoding, argString)
    indexer = argEncoding~analyze(argString)

    -- Optimization by redundance (pure attributes are 3 to 4 times faster than methods just exposing and returning the value)
    string = indexer~string
    text = self
    encoding = indexer~encoding

    -- store itself as counterpart of string
    -- string~text = self                               -- can't do that because infinite recursion
    forward to (string) message "TEXT=" array(self)     -- no dynamic target ==> no infinite recursion


/*
Don't activate this one.
I need to get the control when concatenating strings
[later]
In fact, this method is NEVER called, even if activated.
It's because RexxText is a base class, so the C++ method primitiveMakeString is
called by the interpreter. This method returns .nil.
No message sent, so no way to return something.
[later]
For experimentation,
I added the C++ methods primitiveMakeString and makeString to RexxText which
always send the message request("string"), ignoring the fact that RexxText is a
base class...
*/
::method makestring
    expose indexer
    use strict arg -- none
    if .Unicode~unckeckedConversionToString then return indexer~string -- for experimentation, don't check if compatible

    if self~isCompatibleWithByteString then return indexer~string
    raise syntax 23.900 array(self~descriptionForError "cannot be converted to a String instance")


::attribute string get
/*
::attribute string get
    expose indexer
    use strict arg -- none
    return indexer~string
*/


::attribute string set private


::method detach
    expose indexer /* rest is optim */ string encoding
    use strict arg -- none
    if var("string") then do
        oldString = string
        drop string -- do it now to avoid infinite recursion
        forward to (oldString) continue -- request the string to detach itself
        newString = .String~new("")
        newEncoding = newString~encoding
        newEncoding = .Encoding~factory(newEncoding, newString)
        indexer = newEncoding~analyze(newString)

        -- Optimization by redundance
        string = indexer~string
        encoding = indexer~encoding

        -- store itself as counterpart of string
        -- string~text = self                               -- can't do that because infinite recursion
        forward to (string) message "TEXT=" array(self)    -- no dynamic target ==> no infinite recursion
    end

/*
Added after the activation of automatic conversion to RexxText
to support the same interface on String and RexxText.
    "Noel"~text("byte")  -- here, "Noel" is a String
    "Noël"~text("byte")  -- here, "Noël" is a RexxText
*/
::method text
    use strict arg textEncoding=(self~encoding)
    self~encoding = textEncoding
    return self


/*
Added after the activation of automatic conversion to RexxText
to support the same interface on String and RexxText.
*/
::method hasText
    return .true


/*
Before the activation of the dynamic target
    s = "hello"
    s~text = .RexxText~new("hello")
raises
    EncodedString: the counterpart must be a RexxText linked to this String
raised by EncodeString~"text="
Now, with the dynamic target, I have
    Object "hello" does not understand message "TEXT="
It's because the target "hello" is converted to text T"hello"
    initial:            "hello~"TEXT="(<a RexxText>)
    dynamic target:    T"hello~"TEXT="(<a RexxText>)
Since this method "TEXT=" should be private on String, I stay like that.
*/
::attribute text set private
    /*useless*/ -- forward to (self~string) -- no dynamic target


/*
Allows to use a String or a MutableBuffer or a RexxText indistinctly.
Here, we are on a RexxText.
*/
::method requestTextOrBufferOrString
    use strict arg -- none
    return self


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isTextOrBufferOrString
    use strict arg -- none
    return .true -- it's a RexxText


/*
Allows to use a String or a MutableBuffer or a RexxText indistinctly.
Here, we are on a RexxText.
Always return the string.
*/
::method requestBufferOrString
    use strict arg -- none
    return self~string


-- Equivalent to isPolymorphicString in StringClass.cpp
::method isBufferOrString
    use strict arg -- none
    return .true -- it's a RexxText converted to string


::constant hasEncoding 1

::attribute encoding get
/*
    expose indexer
    use strict arg -- none
    return indexer~encoding
*/

::attribute encoding set
    expose indexer /* rest is optim */ string encoding
    use strict arg newEncoding
    -- if .nil == newEncoding then return -- reset ignored, a RexxText has always an encoding
    newEncoding = .Encoding~factory(newEncoding, indexer~string)
    if indexer~encoding <> newEncoding then do
        indexer = newEncoding~analyze(indexer~string)
        -- Optimization by redundance
        string = indexer~string
        encoding = indexer~encoding
    end


::method setEncoding
    use strict arg newEncoding=(self~encoding)
    previousEncoding = self~encoding -- can't be .nil because a RexxText has always an encoding
    self~encoding = newEncoding
    return previousEncoding


-- Must use an attribute to return the indexer, because the indexer is not visible from the other mixinclasses
::attribute indexer -- private -- this method should be accessible only by RexxText, StringIndexer and its subclasses


::method copy
    use strict arg -- none
    selfCopy = self~copy:super -- for the moment, the copy has the same indexer as self
    indexerCopy = selfCopy~indexer~copy -- creates a copy of the indexer and also a copy of the indexed string
    selfCopy~indexer = indexerCopy -- from now, the copy has its own indexer, which has its own indexed string

    -- Optimization by redundance (pure attributes are 3 to 4 times faster than methods just exposing and returning the value)
    selfCopy~string = indexerCopy~string
    selfCopy~text = selfCopy
    selfCopy~encoding = indexerCopy~encoding

    stringCopy = indexerCopy~string -- this string copy is not yet linked to the RexxText copy

    -- can't do that because infinite recursion
    -- stringCopy~text = selfCopy -- from now, the string copy is linked to its RexxText counterpart

    forward to (stringCopy) message "TEXT=" array(selfCopy) continue -- no dynamic target ==> no infinite recursion

    return selfCopy


/******************************************************************************/
::class "RexxTextContents" mixinclass Object private

-- Remember: don't use expose indexer, because it's not visible. Must use self~indexer.

::method description
    forward to (self~indexer)


::method descriptionForError
    forward to (self~indexer)


::method errors
    forward to (self~indexer)


::method isASCII
    forward to (self~string)


::method isCompatibleWithASCII
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if self~encoding~isCompatibleWithASCII, self~string~isASCII then return .true
    return .false


::method isCompatibleWithByteString
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if self~encoding~isByte then return .true
    if self~encoding~isCompatibleWithASCII, self~string~isASCII then return .true
    return .false


::method isUpper
    expose isUpper
    if var("isUpper") then return isUpper
    forward to (self~indexer) continue
    isUpper = result
    return result


::method isLower
    expose isLower
    if var("isLower") then return isLower
    forward to (self~indexer) continue
    isLower = result
    return result


::method bytes
    forward to (self~indexer)


::method codepoints
    forward to (self~indexer)


::method maximumCodepoint
    forward to (self~indexer)


-- For Byte encodings, returns the maximum Unicode codepoint if the text was converted to Unicode.
-- For Unicode encodings, it's the same value as maximumCodepoint.
::method maximumUnicodeCodepoint
    forward to (self~indexer)

/*
-- No direct access to codepoint, not needed.
::method codepoint
    forward to (self~indexer)
*/


::method UnicodeCharacters
    forward to (self~indexer)


::method characters
    forward to (self~indexer)


::method character
    use strict arg indexC
    forward to (self~indexer)


-- General service to convert to another encoding
::method transcodeTo
    forward to (self~indexer)


-- Byte representation
/*
The Byte_Encoding is a raw encoding with few constraints, BUT it's impossible
to transcode from/to it without errors if the string contains not-ASCII characters.
Here, no transcoding, it's a copy as-is whose encoding is The Byte_Encoding.
The Byte_Encoding is often used for diagnostic or repair. It can be always
absorbed when doing a concatenation or a comparison.
*/
::method byte
    -- if self~encoding == .Byte_Encoding then return self -- always a copy, even if already with the byte encoding
    return self~copy~~setEncoding("byte")

-- UTF-8 representation
::method UTF8
    forward to (self~indexer)


-- WTF-8 representation
::method WTF8
    forward to (self~indexer)


-- UTF-16BE or UTF-16LE representation
::method UTF16
    forward to (self~indexer)


-- UTF-16BE representation
::method UTF16BE
    forward to (self~indexer)


-- UTF-16LE representation
::method UTF16LE
    forward to (self~indexer)


-- WTF-16BE or WTF-16LE representation
::method WTF16
    forward to (self~indexer)


-- WTF-16BE representation
::method WTF16BE
    forward to (self~indexer)


-- WTF-16LE representation
::method WTF16LE
    forward to (self~indexer)


-- UTF-32BE or UTF-32LE representation
::method UTF32
    forward to (self~indexer)


-- UTF-32BE representation
::method UTF32BE
    forward to (self~indexer)


-- UTF-32LE representation
::method UTF32LE
    forward to (self~indexer)


-- Unicode representation (Unicode8, Unicode16 or Unicode32)
::method Unicode
    forward message "UnicodeN"


::method UnicodeN
    forward to (self~indexer)


-- Unicode representation limited to codepoints < 256
::method Unicode8
    forward to (self~indexer)


-- Unicode representation limited to codepoints < 65536
::method Unicode16
    forward to (self~indexer)


-- Unicode representation limited to codepoints <= .Unicode~maxCodepoint
::method Unicode32
    forward to (self~indexer)


::method c2u
    forward to (self~indexer)


::method u2c
    forward to (self~string) -- yes, not self~indexer


::method c2g
    forward to (self~indexer)


::method checkHexadecimalValueCompatibility
    -- The purpose is not to check that the text is an hexadecimal value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    use strict arg -- none
    if \self~isCompatibleWithByteString then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx hexadecimal value")


::method checkNumericValueCompatibility
    -- The purpose is not to check that the text is a numeric value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    use strict arg -- none
    if \self~isCompatibleWithByteString then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx numeric value")


::method checkLogicalValueCompatibility
    -- The purpose is not to check that the text is a logical value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    use strict arg -- none
    if \self~isCompatibleWithByteString then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx logical value")


::method unescape
    forward to (self~indexer)


::method transform
    forward to (self~indexer)


::method transformer
    forward to (self~indexer)


::method title
    forward to (self~indexer)


::method isNFC
    forward to (self~indexer)


::method NFC
    forward to (self~indexer)


::method isNFD
    forward to (self~indexer)


::method NFD
    forward to (self~indexer)


::method isNFKC
    forward to (self~indexer)


::method NFKC
    forward to (self~indexer)


::method isNFKD
    forward to (self~indexer)


::method NFKD
    forward to (self~indexer)


::method isCasefold
    forward to (self~indexer)


::method casefold
    forward to (self~indexer)


::method isMarkStripped
    forward to (self~indexer)


-- no standalone method Markless
-- works only with normalization.


::method isIgnorableStripped
    forward to (self~indexer)


::method isCCStripped
    forward to (self~indexer)


::method isNAStripped
    forward to (self~indexer)


-- Compatibility with initial interface
::method graphemes; forward message "characters"
::method grapheme; forward message "character"


/******************************************************************************/
::class "StringRexxTextInterface" mixinclass Object private

/*
Methods that must be supported by String to be compatible with RexxText.
*/

::method description
    /*
    "noël👩‍👨‍👩‍👧🎅"~description(short:1)      -- 'UTF-8 not-ASCII by default'
    "noël👩‍👨‍👩‍👧🎅"~description               -- 'UTF-8 not-ASCII by default (34 bytes)'
    */
    if self~hasText then forward to (self~text)
    use strict arg -- none
    use strict named arg short=.false, technical=.false /* not used */
    sizesDescription = ""
    if \short then sizesDescription = "(" ||,
                                      self~length~singularPluralCount("byte", "bytes"),
                                      || ")"
    defaultEncoding = ""
    if \self~hasEncoding then defaultEncoding = "by default"
    return " "~join(self~encoding~description(self~isASCII), defaultEncoding, sizesDescription)


::method descriptionForError
    if self~hasText then forward to (self~text)
    -- Display the <length> first characters
    use strict arg length=10
    string = self
    if string~length > length then string = string~left(length - 3)"..."
    -- escape3 is needed to have a proper display like this: [00]4[00]1
    return self~description(short:1) "'"escape3(string)"'"


::method errors
    /* if self~hasText then */ forward to (self~text)
    return .nil -- no errors


-- ::method isASCII
-- native method


/*
Depending on its encoding, an encoded string may be not compatible with ASCII.
*/
::method isCompatibleWithASCII
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if self~encoding~isCompatibleWithASCII, self~isASCII then return .true
    return .false


/*
Depending on its encoding, an encoded string may be not compatible with
the String methods (byte-oriented).
*/
::method isCompatibleWithByteString
    -- IMPORTANT! Don't cache the value because it can be invalidated when the encoding is changed
    if self~encoding~isByte then return .true
    if self~encoding~isCompatibleWithASCII, self~isASCII then return .true
    return .false


::method isUpper
    return self~datatype("U")


::method isLower
    return self~datatype("L")


::method bytes
    /* if self~hasText then */ forward to (self~text)


::method codepoints
    /* if self~hasText then */ forward to (self~text)


::method maximumCodepoint
    /* if self~hasText then */ forward to (self~text)


::method maximumUnicodeCodepoint
    /* if self~hasText then */ forward to (self~text)

/*
-- No direct access to codepoint, not needed.
::method codepoint
    /* if self~hasText then */ forward to (self~text)
*/


::method UnicodeCharacters
    /* if self~hasText then */ forward to (self~text)


::method characters
    return self~makearray("")


::method character
    -- 2 modes:
    -- if the buffer is passed as argument then append the character to the buffer, and return the buffer
    -- otherwise return the character as a String (maybe evaluated as a RexxText depending on encoding)
    use strict arg indexC
    use strict named arg buffer=.nil
    if .nil <> buffer then return buffer~~append(self~subchar(indexC))
                      else return self~subchar(indexC)


-- General service to convert to another encoding
::method transcodeTo
    forward to (self~text)


-- Byte representation
/*
The Byte_Encoding is a raw encoding with few constraints, BUT it's impossible
to transcode from/to it without errors if the string contains not-ASCII characters.
Here, no transcoding, it's a copy as-is whose encoding is The Byte_Encoding.
The Byte_Encoding is often used for diagnostic or repair. It can be always
absorbed when doing a concatenation or a comparison.
*/
::method byte
    -- if self~encoding == .Byte_Encoding then return self -- always a copy, even if already with the byte encoding
    return self~copy~~setEncoding("byte")

-- UTF-8 representation
::method UTF8
    forward to (self~text)


-- WTF-8 representation
::method WTF8
    forward to (self~text)


-- UTF-16BE or UTF-16LE representation
::method UTF16
    forward to (self~text)


-- UTF-16BE representation
::method UTF16BE
    forward to (self~text)


-- UTF-16LE representation
::method UTF16LE
    forward to (self~text)


-- WTF-16BE or WTF-16LE representation
::method WTF16
    forward to (self~text)


-- WTF-16BE representation
::method WTF16BE
    forward to (self~text)


-- WTF-16LE representation
::method WTF16LE
    forward to (self~text)


-- UTF-32BE or UTF-32LE representation
::method UTF32
    forward to (self~text)


-- UTF-32BE representation
::method UTF32BE
    forward to (self~text)


-- UTF-32LE representation
::method UTF32LE
    forward to (self~text)


-- Unicode representation (Unicode8, Unicode16 or Unicode32)
::method Unicode
    forward message "UnicodeN"


::method UnicodeN
    forward to (self~text)


-- Unicode representation limited to codepoints < 256
::method Unicode8
    forward to (self~text)


-- Unicode representation limited to codepoints < 65536
::method Unicode16
    forward to (self~text)


-- Unicode representation limited to codepoints <= .Unicode~maxCodepoint
::method Unicode32
    forward to (self~text)


::method c2u
    forward to (self~text)


::method u2c
    -- Create a Unicode32 text from a sequence of U+xxxx
    use strict named arg buffer=.nil
    return .Unicode32_Encoding~encodeUplusString(self, :buffer)


::method c2g
    forward to (self~text)


::method checkHexadecimalValueCompatibility
    -- The purpose is not to check that the text is an hexadecimal value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    use strict arg -- none
    if \self~isCompatibleWithByteString then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx hexadecimal value")


::method checkNumericValueCompatibility
    -- The purpose is not to check that the text is a numeric value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    use strict arg -- none
    if \self~isCompatibleWithByteString then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx numeric value")


::method checkLogicalValueCompatibility
    -- The purpose is not to check that the text is a logical value (will be checked by the String class)
    -- The purpose is to ensure that the text encoding is compatible with the String class,
    -- and to provide an accurate error.
    use strict arg -- none
    if \self~isCompatibleWithByteString then raise syntax 23.900 array(self~descriptionForError "is not compatible with a Rexx logical value")


::method unescape
    forward to (self~text)


::method transform
    forward to (self~text)


::method transformer
    forward to (self~text)


::method title
    forward to (self~text)


::method isNFC
    forward to (self~text)


::method NFC
    forward to (self~text)


::method isNFD
    forward to (self~text)


::method NFD
    forward to (self~text)


::method isNFKC
    forward to (self~text)


::method NFKC
    forward to (self~text)


::method isNFKD
    forward to (self~text)


::method NFKD
    forward to (self~text)


::method isCasefold
    forward to (self~text)


::method casefold
    forward to (self~text)


::method isMarkStripped
    forward to (self~text)


-- no standalone method Markless
-- works only with normalization.


::method isIgnorableStripped
    forward to (self~text)


::method isCCStripped
    forward to (self~text)


::method isNAStripped
    forward to (self~text)


-- Compatibility with initial interface
::method graphemes; forward message "characters"
::method grapheme; forward message "character"


/******************************************************************************/
::class "RexxTextStringInterface" mixinclass Object private

/*
Methods that must be supported by RexxText to be compatible with String.

Class methods
=============
Last column comes from https://www.regular-expressions.info/posixbrackets.html
TODO review:
    https://htmlpreview.github.io/?https://github.com/unicode-org/icu-docs/blob/main/design/posix_classes.html
    http://www.unicode.org/reports/tr18/#Compatibility_Properties

alnum                           (new 5) alpha + digit                                                   [\p{L}\p{Nl} \p{Nd}]
alpha                           (new 5) Lowercase + Uppercase + Lt + Lm + Lo + Nl + Other_Alphabetic    \p{L}\p{Nl}
blank                           (new 5) "horizontal" whitespace: space separators plus U+0009 tab.      [\p{Zs}\t]
cntrl                           (new 5) Cc                                                              \p{Cc}
cr                              (new 5)
digit                           (new 5) Nd                                                              \p{Nd}
graph                           (new 5)                                                                 [^\p{Z}\p{C}]
lower                           (new 5) Ll + Other_Lowercase                                            \p{Ll}              not other?
nl                              (new 5)
null                            (new 5)
print                           (new 5)                                                                 \P{C}
punct                           (new 5)                                                                 \p{P}
space                           (new 5)                                                                 [\p{Z}\t\r\n\v\f]
tab                             (new 5)
upper                           (new 5) Lu + Other_Uppercase                                            \p{Lu}              not other?
xdigit                          (new 5)                                                                 [A-Fa-f0-9]

Instance methods
================
[]                              (new 5) full
?                               (new 5) full
abbrev
abs                             full
append                          (new 5) full
b2x                             full, always forward to String
bitAnd                          full, always forward to String
bitOr                           full, always forward to String
bitXor                          full, always forward to String
c2d                             full, always forward to String
c2x                             full, always forward to String
caselessAbbrev
caselessChangeStr
caselessCompare                 full UTF-8
caselessCompareTo               full UTF-8 (expansion like "ß" --> "ss" is supported but the result maybe be surprising when providing a length - false positive?)
caselessContains                (new 5) full UTF-8
caselessContainsWord            (new 5)
caselessCountStr
caselessEndsWith                (new 5) full UTF-8
caselessEquals                  full UTF-8
caselessLastPos
caselessMatch                   full UTF-8
caselessMatchChar               full UTF-8
caselessPos                     full UTF-8
caselessStartsWith              (new 5) full UTF-8
caselessWordPos
center                          full
centre                          full
changeStr
compare                         full UTF-8
compareTo                       full UTF-8
contains                        (new 5) full UTF-8
containsWord                    (new 5)
copies                          full
countStr
d2c                             full for text which isCompatibleWithByteString
d2x                             full for text which isCompatibleWithByteString
dataType
decodeBase64
delStr
delWord
encodeBase64
endsWith                        (new 5) full UTF-8
equals                          full UTF-8
format
hashCode                        full
insert
join                            (extension) full
lastPos
left                            full
length                          full
lower                           full except cases in SpecialCasing.txt
makeArray
makeString                      full (raise an error if not compatible with String)
match                           full UTF-8
matchChar                       full UTF-8
makeArray
max
min
modulo                          (new 5)
overlay
pos                             full UTF-8
replaceAt
reverse                         full
right                           full
round
sign
space
startsWith                      (new 5) full UTF-8
strip                           full UTF-8
subChar                         full
substr                          full
subWord
subWords
translate
trunc
upper                           full except cases in SpecialCasing.txt
verify
word
wordIndex
wordLength
wordPos
words
x2b                             full
x2c                             full
x2d                             full

Other methods/routines
======================
stringChunks
    parse (only for breakTokens)
    pos (only for escapeCharacters)
    caselessWordPos (only for breakTokens)
    .LengthComparator~new("d") (only for breakTokens)

*/

::method "[]"
    -- ooRexx v5
    use strict arg n, length=1
    use strict named arg buffer=.nil
    maxLength = self~length - n + 1 -- don't care about n<=0, will be caught by substr
    if maxLength <= 0 then return self~encoding~emptyString
    return self~substr(n, min(length, maxLength), :buffer)


::method ?
    -- ooRexx v5
    self~checkLogicalValueCompatibility
    forward to (self~string)


::method abs
    self~checkNumericValueCompatibility
    forward to (self~string)


::method append
    forward to (self~indexer)


-- Redundant, to offer the same interface as MutableBuffer
::method appendEncoded
    forward message "append"


::method b2x
    self~checkNumericValueCompatibility
    forward to (self~string)


::method bitAnd
    forward to (self~string)


::method bitOr
    forward to (self~string)


::method bitXor
    forward to (self~string)


::method c2d
    forward to (self~string)


::method c2x
    forward to (self~indexer)


::method caselessCompare
    forward to (self~indexer)


::method caselessCompareTo
    forward to (self~indexer)


::method caselessContains
    -- Force asList: to .false, we want a position
    forward message "caselessPos" to (self~indexer) namedArguments (.context~namedArgs~~setEntry("asList", .false)) continue
    return result <> 0 -- the result will be an array if aligned:.false.


::method caselessEndsWith
    forward to (self~indexer)


::method caselessEquals
    forward message "caselessCompareTo" to (self~indexer) continue
    return result == 0


::method caselessMatch
    forward to (self~indexer)


::method caselessMatchChar
    forward to (self~indexer)


::method caselessPos
    forward to (self~indexer)


::method caselessStartsWith
    -- Force asList: to .false, we want a position
    forward message "caselessPos" to (self~indexer) namedArguments (.context~namedArgs~~setEntry("asList", .false)) continue
    -- the result will be an array if aligned:.false
    if result~isA(.array) then return result[1] == +1.1
    return result == 1


::method center
    forward to (self~indexer)


::method centre
    forward message "center"


::method compare
    forward to (self~indexer)


::method compareTo
    forward to (self~indexer)


::method contains
    -- Force asList: to .false, we want a position
    forward message "pos" to (self~indexer) namedArguments (.context~namedArgs~~setEntry("asList", .false)) continue
    return result \== 0 -- the result will be an array if aligned:.false


::method copies
    use strict named arg buffer=.nil
    forward to (self~string) continue
    -- It's a new string without encoding
    -- TODO result~setEncoding, self~encoding)
    if .nil <> buffer then return buffer~~appendEncoded(result)
                      else return .RexxText~new(result, self~encoding)


::method d2c
    use strict named arg buffer=.nil
    self~checkNumericValueCompatibility
    forward to (self~string) continue
    -- It's a new string without encoding
    -- TODO result~setEncoding, self~encoding)
    if .nil <> buffer then return buffer~~appendEncoded(result)
                      else return .RexxText~new(result, self~encoding)


::method d2x
    use strict named arg buffer=.nil
    self~checkNumericValueCompatibility
    forward to (self~string) continue
    if .nil <> buffer then return buffer~~appendEncoded(result)
                      else return result -- yes, return a String, not a RexxText


::method endsWith
    forward message "endsWith" to (self~indexer)


::method equals
    forward message "compareTo" to (self~indexer) continue
    return result == 0


::method hashCode
    forward to (self~string)


::method join -- extension
    -- Positional arguments : zero to N text/string or arrays of text/string (recursively).
    -- The text value of each argument is joined, with self used as separator
    -- If the encoding of an argument is not compatible for concatenation with self then an error is raised
    use strict named arg buffer=.nil, appender=(self~encoding)
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    if \buffer~hasEncoding then buffer~encoding = self~encoding
    buffer~join(arg(1, "a"), separator: self, :appender)
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~encoding)


::method left
    use strict arg _length, _pad="" -- not used, it's just to check that we get at least the length, and that we don't get more than 2 arguments
    -- equivalent to substr(1, length, pad)
    forward message "substr" arguments (arg(1, "a")~~insert(1, .nil))


::method length -- number of characters
    use strict arg -- none
    return self~indexer~characterCount


::method lower
    forward to (self~indexer)


::method match
    forward to (self~indexer)


::method matchChar
    forward to (self~indexer)

::method pos
    forward to (self~indexer)


::method reverse
    forward to (self~indexer)


::method right
    forward to (self~indexer)


::method startsWith
    -- Force asList: to .false, we want a position
    forward message "pos" to (self~indexer) namedArguments (.context~namedArgs~~setEntry("asList", .false)) continue
    -- the result will be an array if aligned:.false
    if result~isA(.array) then return (result[1] = 1.1) -- hum, testing with == returns false. Should test == "+1.1" to get true when the result is something like (+1.1,-5.10)
    return result == 1


::method strip
    forward to (self~indexer)


::method subchar
    forward message "character"


::method substr
    forward to (self~indexer)


::method translate
    forward to (self~indexer)


::method upper
    forward to (self~indexer)


::method x2b
    use strict named arg buffer=.nil
    self~checkHexadecimalValueCompatibility
    forward to (self~string) continue
    if .nil <> buffer then return buffer~~appendEncoded(result)
                      else return result -- yes, return a String, not a RexxText


::method x2c
    use strict named arg buffer=.nil
    self~checkHexadecimalValueCompatibility
    forward to (self~string) continue
    -- It's a new string without encoding
    -- TODO result~setEncoding, self~encoding)
    if .nil <> buffer then return buffer~~appendEncoded(result)
                      else return .RexxText~new(result, self~encoding)


::method x2d
    use strict named arg buffer=.nil
    self~checkHexadecimalValueCompatibility
    forward to (self~string) continue
    if .nil <> buffer then return buffer~~appendEncoded(result)
                      else return result -- yes, return a String, not a RexxText


/******************************************************************************/
::class "RexxTextOperators" mixinclass Object private

/**************/
/* Arithmetic */
/**************/

::method '*'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '*op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "*" to (left) array (self~string)

::method '**'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '**op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "**" to (left) array (self~string)

::method '+'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '+op:right'
    -- here, necessarily 2 args
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "+" to (left) array (self~string)

::method '-'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '-op:right'
    -- here, necessarily 2 args
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "-" to (left) array (self~string)

::method '/'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '/op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "/" to (left) array (self~string)

::method '//'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '//op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "//" to (left) array (self~string)

::method '%'
    self~checkNumericValueCompatibility
    forward to (self~string)

::method '%op:right'
    use strict arg left
    self~checkNumericValueCompatibility
    forward message "%" to (left) array (self~string)


/**************/
/* Comparison */
/**************/

::method compareSelfRight private
    use strict arg right, message
    use strict named arg strict
    /*
    ooRexx doc about string comparison methods:
    Both must be string objects. If argument is not a string object, it is
    converted to its string representation for the comparison. The one exception
    is when argument is .nil for the ==, \==, =, \=, ><, and <> operators.
    A string object will never compare equal to .nil, even when the string
    matches the string value of .nil ("The NIL object").
    As a result, == will always return .false when compared to .nil and \== will
    always return .true. All of the relational comparisons (for example, <, >,
    <=, etc.) will always return .false when compared to .nil.

    About strict versus non-strict comparison in ooRexx doc:
    For all other comparison operators, if both terms involved are numeric, a
    numeric comparison is effected. Otherwise, both terms are treated as
    character strings, leading and trailing whitespace characters are ignored,
    and the shorter string is padded with blanks on the right.

    Note: there is no need to implement a Unicode-aware numeric comparison,
    because Executor doesn't try to support arithmetic with digits encoded in
    UTF-16 or UTF-32. When compatible with byte strings, Executor forwards to
    the String class which supports a numeric comparison.
    */
    if .nil == right then forward message (message) to (self~string) array(right) -- delegate to String for the management of .nil
    -- Give chance to an alternative operator before requesting a text or buffer or string
    messageOpRight = message"op:right"
    if \right~isTextOrBufferOrString, right~hasMethod(messageOpRight) then do
        right~send(messageOpRight, self)
        if var("result") then return result
    end
    right = right~requestTextOrBufferOrString
    if .nil == right then return
    if .Encoding~comparisonMode(self, right) == "b" then do
        forward message (message) to (self~string) array (right~string)
    end
    -- Unicode comparison
    right = right~request("RexxText")
    if .nil == right then return
    selfNormalized = self~transform(normalization: .Unicode~defaultNormalization(:strict), lump: \strict, stripIgnorable: \strict)
    rightNormalized = right~transform(normalization: .Unicode~defaultNormalization(:strict), lump: \strict, stripIgnorable: \strict)
    forward message (message) to (selfNormalized~string) array (rightNormalized~string)


::method compareLeftSelf private
    use strict arg left, message
    use strict named arg strict
    left = left~requestTextOrBufferOrString
    if .nil == left then return
    if .Encoding~comparisonMode(left, self) == "b" then do
        forward message (message) to (left~string) array (self~string)
    end
    -- Unicode comparison
    left = left~request("RexxText")
    if .nil == left then return
    leftNormalized = left~transform(normalization: .Unicode~defaultNormalization(:strict), lump: \strict, stripIgnorable: \strict)
    selfNormalized = self~transform(normalization: .Unicode~defaultNormalization(:strict), lump: \strict, stripIgnorable: \strict)
    forward message (message) to (leftNormalized~string) array (selfNormalized~string)


::method '<'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<', strict: .false)

::method '<op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<', strict: .false)

::method '<<'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<<', strict: .true)

::method '<<op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<<', strict: .true)

::method '<<='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<<=', strict: .true)

::method '<<=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<<', strict: .true)

::method '<='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<=', strict: .true)

::method '<=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<=', strict: .false)

::method '<>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '<>', strict: .false)

::method '<>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '<>', strict: .false)

::method '='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '=', strict: .false)

::method '=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '=', strict: .false)

::method '=='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '==', strict: .true)

::method '==op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '==', strict: .true)

::method '>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>', strict: .false)

::method '>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>', strict: .false)

::method '><'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '><', strict: .false)

::method '><op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '><', strict: .false)

::method '>='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>=', strict: .false)

::method '>=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>=', strict: .false)

::method '>>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>>', strict: .true)

::method '>>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>>', strict: .true)

::method '>>='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '>>=', strict: .true)

::method '>>=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>>=', strict: .true)

::method '\<'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\<', strict: .false)

::method '\<op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\<', strict: .false)

::method '\='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\=', strict: .false)

::method '\=op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\=', strict: .false)

::method '\=='
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\==', strict: .true)

::method '\==op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\==', strict: .true)

::method '\>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\>', strict: .false)

::method '\>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '>', strict: .false)

::method '\>>'
    use strict arg right
    forward to (self) message "compareSelfRight" array (right, '\>>', strict: .true)

::method '\>>op:right'
    use strict arg left
    forward to (self) message "compareLeftSelf" array (left, '\>>', strict: .true)


/***********/
/* Logical */
/***********/

::method '&&'
    self~checkLogicalValueCompatibility
    forward to (self~string)

::method '&&op:right'
    use strict arg left
    self~checkLogicalValueCompatibility
    forward message "&&" to (left) array (self~string)

::method '&'
    self~checkLogicalValueCompatibility
    forward to (self~string)

::method '&op:right'
    use strict arg left
    self~checkLogicalValueCompatibility
    forward message "&" to (left) array (self~string)

::method '\' -- unary only
    self~checkLogicalValueCompatibility
    forward to (self~string)

::method '|'
    self~checkLogicalValueCompatibility
    forward to (self~string)

::method '|op:right'
    use strict arg left
    self~checkLogicalValueCompatibility
    left~checkLogicalValueCompatibility
    forward message "|" to (left) array (self~string)


/*****************/
/* Concatenation */
/*****************/

::method " "
    use strict arg right
    -- Give chance to an alternative operator before requesting a text or buffer or string
    if \right~isTextOrBufferOrString, right~hasMethod(" op:right") then do
        right~" op:right"(self)
        if var("result") then return result
    end
    right = right~requestTextOrBufferOrString
    if .nil == right then return
    encoding = .Encoding~ForConcatenation(self, right)
    return encoding~concatenate(self, encoding~spaceCharacter, right)


::method " op:right"
    use strict arg left
    left = left~requestTextOrBufferOrString
    if .nil == left then return
    encoding = .Encoding~ForConcatenation(left, self)
    return encoding~concatenate(left, encoding~spaceCharacter, self)


::method "||"
    use strict arg right
    -- Give chance to an alternative operator before requesting a text or buffer or string
    if \right~isTextOrBufferOrString, right~hasMethod("||op:right") then do
        right~"||op:right"(self)
        if var("result") then return result
    end
    right = right~requestTextOrBufferOrString
    if .nil == right then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "||op:right"
    use strict arg left
    left = left~requestTextOrBufferOrString
    if .nil == left then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(left, self)
    return encoding~concatenate(left, self)


::method "" -- abuttal
    use strict arg right
    -- Give chance to an alternative operator before requesting a text or buffer or string
    if \right~isTextOrBufferOrString, right~hasMethod("op:right") then do
        right~"op:right"(self)
        if var("result") then return result
    end
    right = right~requestTextOrBufferOrString
    if .nil == right then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(self, right)
    return encoding~concatenate(self, right)


::method "op:right" -- abuttal
    use strict arg left
    left = left~requestTextOrBufferOrString
    if .nil == left then return -- no result: try the alternative message
    encoding = .Encoding~ForConcatenation(left, self)
    return encoding~concatenate(left, self)
