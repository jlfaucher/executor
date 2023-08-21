-- This file is the main file to be loaded by the external callers

-- Load the optional packages xxx_encoding.cls which are in the sub-directory "optional" of current package.
-- The encoding classes are declared in .environment, to make them available everywhere.
package = .context~package
directory = .file~new(package~name)~parent || "/optional"
pattern = .file~new("*_encoding.cls", directory)
if 0 == sysFileTree(pattern~string, encodingPackages., "FO") then do
    do i=1 to encodingPackages.0
        package~loadPackage(encodingPackages.i)
    end
end

-- Load the Unicode packages xxx_encoding.cls
-- The encoding classes are declared in .environment, to make them available everywhere.
::requires "encoding/unicode.cls"

::requires "encoding/stringInterface.cls"


-- ::options trace i

/******************************************************************************/
/*
TODOs

Unicode8 16 32 : should I create common methods in Unicode_Encoding?

Remove the index for codepoints (codepointIndexes).
There is no need of direct access to a codepoint.

Characters indexes : see if it's possible to replace .Array by a class being really a sparse array.
This class should be ultra specialized for the management of string indexes.
For example, could manage a flexible storage in function of the size of the index.
Maybe a multi-stage table ?
Interface:
    indexTable~new(stringSizeInBytes)
    indexTable~size
    indexTable~items
    indexTable~[integer]
    indexTable~[integer]=bytePosition
    indexTable~first     --  index of the first item in the table

See if it's possible to apply NFC transformation on invalid utf-8
currently not possible with utf8proc.

Replace 23.900 by 93.900 when 23.900 is not the good error code to raise.

*/
