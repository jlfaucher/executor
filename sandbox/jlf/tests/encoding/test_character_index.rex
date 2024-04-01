-- byte
call test_characterIndexC 'xrange()~text("latin1")'
call test_characterIndexC 'xrange()~text("utf8")'

-- utf8
call test_characterIndexC 'xrange()              ~text("latin1")~utf8'
call test_characterIndexC '"noël👩‍👨‍👩‍👧🎅"~text("utf8")'
call test_characterIndexC '"äöü äöü x̂ ϔ ﷺ baﬄe"~text("utf8")'

-- wtf8
call test_characterIndexC 'xrange()              ~text("latin1")~wtf8'
call test_characterIndexC '"noël👩‍👨‍👩‍👧🎅"~text("wtf8")'
call test_characterIndexC '"äöü äöü x̂ ϔ ﷺ baﬄe"~text("wtf8")'

-- utf16be
call test_characterIndexC 'xrange()              ~text("latin1")~utf16be'
call test_characterIndexC '"noël👩‍👨‍👩‍👧🎅"~text("utf8")  ~utf16be'
call test_characterIndexC '"äöü äöü x̂ ϔ ﷺ baﬄe"~text("utf8")  ~utf16be'

-- wtf16be
call test_characterIndexC 'xrange()              ~text("latin1")~wtf16be'
call test_characterIndexC '"noël👩‍👨‍👩‍👧🎅"~text("utf8")  ~wtf16be'
call test_characterIndexC '"äöü äöü x̂ ϔ ﷺ baﬄe"~text("utf8")  ~wtf16be'

-- utf16le
call test_characterIndexC 'xrange()              ~text("latin1")~utf16le'
call test_characterIndexC '"noël👩‍👨‍👩‍👧🎅"~text("utf8")  ~utf16le'
call test_characterIndexC '"äöü äöü x̂ ϔ ﷺ baﬄe"~text("utf8")  ~utf16le'

-- wtf16le
call test_characterIndexC 'xrange()              ~text("latin1")~wtf16le'
call test_characterIndexC '"noël👩‍👨‍👩‍👧🎅"~text("utf8")  ~wtf16le'
call test_characterIndexC '"äöü äöü x̂ ϔ ﷺ baﬄe"~text("utf8")  ~wtf16le'

-- utf32be
call test_characterIndexC 'xrange()              ~text("latin1")~utf32be'
call test_characterIndexC '"noël👩‍👨‍👩‍👧🎅"~text("utf8")  ~utf32be'
call test_characterIndexC '"äöü äöü x̂ ϔ ﷺ baﬄe"~text("utf8")  ~utf32be'

-- utf32le
call test_characterIndexC 'xrange()              ~text("latin1")~utf32le'
call test_characterIndexC '"noël👩‍👨‍👩‍👧🎅"~text("utf8")  ~utf32le'
call test_characterIndexC '"äöü äöü x̂ ϔ ﷺ baﬄe"~text("utf8")  ~utf32le'

-- unicode
call test_characterIndexC 'xrange()              ~text("latin1")~unicode'
call test_characterIndexC '"noël👩‍👨‍👩‍👧🎅"~text("utf8")  ~unicode'
call test_characterIndexC '"äöü äöü x̂ ϔ ﷺ baﬄe"~text("utf8")  ~unicode'


::routine test_characterIndexC
    use strict arg expression
    text = "text =" expression -- ~space(0)     -- space(0) is a bad idea! some expressions have significant spaces
    say "--------------------------------------------------------------------------------"
    say text
    say "--------------------------------------------------------------------------------"
    interpret text
    say
    say "text~description ="
    say text~description
    say
    say "text~c2g ="
    say text~c2g~quoted"x"
    say
    do indexB=1 to text~string~length + 5
        indexC = text~indexer~characterIndexC(indexB)
        character = text~character(abs(indexC))
        say "indexB" indexB~right(3) "--> indexC" indexC~right(4) "    " character~c2x~quoted"x"
    end
    say

::requires "extension/extensions.cls"
