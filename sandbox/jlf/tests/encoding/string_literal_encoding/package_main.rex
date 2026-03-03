/*
rexx package_main.rex > package_main.out.txt
*/

width = 30

if loadPackage("package_byte.cls") then do
    call display ".package_byte~m_name",          .package_byte~m_name
    call display ".package_byte~m_noel",          .package_byte~m_noel
    call display ".package_byte~m_noel_x",        .package_byte~m_noel_x
    call display ".package_byte~m_noel_x2c",      .package_byte~m_noel_x2c
    say
end

if loadPackage("package_cp1252.cls") then do
    call display ".package_cp1252~m_name",        .package_cp1252~m_name
    call display ".package_cp1252~m_noel",        .package_cp1252~m_noel
    call display ".package_cp1252~m_noel_x",      .package_cp1252~m_noel_x
    call display ".package_cp1252~m_noel_x2c",    .package_cp1252~m_noel_x2c
    say
end

if loadPackage("package_utf8.cls") then do
    call display ".package_utf8~m_name",          .package_utf8~m_name
    call display ".package_utf8~m_noel",          .package_utf8~m_noel
    call display ".package_utf8~m_noel_x",        .package_utf8~m_noel_x
    call display ".package_utf8~m_noel_x2c",      .package_utf8~m_noel_x2c
    say
end

-- Will raise an error.
-- Not possible to have a package encoded UTF16-BE
if loadPackage("package_utf16be.cls") then do
    call display ".package_utf16be~m_name",       .package_utf16be~m_name
    call display ".package_utf16be~m_noel",       .package_utf16be~m_noel
    call display ".package_utf16be~m_noel_x",     .package_utf16be~m_noel_x
    call display ".package_utf16be~m_noel_x2c",   .package_utf16be~m_noel_x2c
    say
end

-- Will raise an error.
-- Not possible to have a package encoded UTF32-BE
if loadPackage("package_utf32be.cls") then do
    call display ".package_utf32be~m_name",       .package_utf32be~m_name
    call display ".package_utf32be~m_noel",       .package_utf32be~m_noel
    call display ".package_utf32be~m_noel_x",     .package_utf32be~m_noel_x
    call display ".package_utf32be~m_noel_x2c",   .package_utf32be~m_noel_x2c
    say
end

exit


/*
REMEMBER!
While the left method loses the encoding on strings, the following expression
will raise an error when value is not a valid UTF-8 string:
    value~left(width)~utf8
Workaround:
    value~utf8~left(width)
BUT...
Not possible to convert a byte string to UTF-8
Decision: no longer convert to UTF-8
*/
display: procedure expose width
    use strict arg expression, value
    say expression~left(width)    value~left(width)    value~class~id~left(width)    value~encoding
    return


::routine loadPackage
    use strict arg filename
    signal on syntax name loadPackageError
    .context~package~loadPackage(filename)
    return .true

    loadPackageError:
    condition = condition("O")
    say "loadPackage KO for" filename":" condition~message
    return .false

::requires "extension/text.cls"
