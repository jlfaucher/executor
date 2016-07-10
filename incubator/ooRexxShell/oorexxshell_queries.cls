-- Optional: regular expressions
hasRegex = loadPackage("regex/regex.cls")
return

loadPackage:
    use strict arg filename
    signal on syntax name loadPackageError
    .context~package~loadPackage(filename)
    return .true
    loadPackageError:
    return .false

::requires "pipeline/pipe_extension.cls"
--::options trace i

-------------------------------------------------------------------------------
::class "ClassInfo" public
-------------------------------------------------------------------------------

-- Bypass a missing feature in ooRexx < 5.0:
-- There is no package associated to a predefined class.
-- From ooRexx5, the package REXX is available.
::attribute REXXPackage class get

::method init class
    expose REXXPackage
    REXXPackage = .package~new("REXX", "")


::method predefinedClassNames class
    return,
        'Alarm',
        'ArgUtil',
        'Array',
        'Bag',
        'Buffer',
        'CaselessColumnComparator',
        'CaselessComparator',
        'CaselessDescendingComparator',
        'CircularQueue',
        'Class',
        'Clauser',
        'Collection',
        'ColumnComparator',
        'Comparable',
        'Comparator',
        'DateTime',
        'DescendingComparator',
        'Directory',
        'File',
        'IdentityTable',
        'InputOutputStream',
        'InputStream',
        'InvertingComparator',
        'List',
        'MapCollection',
        'Message',
        'Method',
        'Monitor',
        'MutableBuffer',
        'NumericComparator',
        'Object',
        'Orderable',
        'OrderedCollection',
        'OutputStream',
        'Package',
        'Pointer',
        'Properties',
        'Queue',
        'Relation',
        'RexxBlock',            -- extension
        'RexxContext',
        'RexxQueue',
        'Routine',
        'SERIALIZEFUNCTIONS',
        'Serializable',
        'Set',
        'SetCollection',
        'SourceLiteralParser',  -- extension
        'StackFrame',
        'Stem',
        'Stream',
        'StreamSupplier',
        'String',
        'Supplier',
        'Table',
        'TimeSpan',
        'WeakReference',
        'server'


::method isPredefinedClass class
    use strict arg classname
    return self~predefinedClassNames~wordpos(classname) <> 0


::method collect class
    use strict arg context, matchers=(.array~new)
    publicClasses = .relation~new
    context~package~pipe(,
        .importedPackages "recursive" "once" "after" "mem.package",
      | .inject {item~publicClasses} "iterateAfter",
      | .do { expose publicClasses; publicClasses[item] = dataflow["package"]~item },
    )
    privateClasses = .relation~new
    context~package~pipe(,
        .importedPackages "recursive" "once" "after" "mem.package",
      | .inject {item~classes} "iterateAfter",
      | .do { expose publicClasses privateClasses
              if \publicClasses~hasIndex(item) then privateClasses[item] = dataflow["package"]~item
            },
    )
    -- Previous queries do not return the predefined classes.
    .object~pipe(,
        .subclasses "recursive" "once" "after",
      | .do { expose publicClasses privateClasses
              if \publicClasses~hasIndex(item) & \privateClasses~hasIndex(item) then publicClasses[item] = .nil
            },
    )
    -- Now build a collection of classInfo.
    classInfos = .table~new -- index is a class, item is a classInfo
    s = publicClasses~supplier
    do while s~available
        matched = matchers~isEmpty
        do matcher over matchers while \matched
            matched = matcher~(s~index~id)
        end
        if matched then classInfos[s~index] = .classInfo~new(s~index, s~item, "public")
        s~next
    end
    s = privateClasses~supplier
    do while s~available
        matched = matchers~isEmpty
        do matcher over matchers while \matched
            matched = matcher~(s~index~id)
        end
        if matched then classInfos[s~index] = .classInfo~new(s~index, s~item, "private")
        s~next
    end
    return classInfos


::attribute klass -- the class
::attribute package get -- the package where the class is defined
::attribute visibility get -- the visibility of the class in the package: "public", "private"


::method init
    expose klass package visibility
    use strict arg klass, package, visibility
    if package == .nil, self~class~isPredefinedClass(klass~id) then package = self~class~REXXPackage


-------------------------------------------------------------------------------
::class "ClassInfoQuery" public
-------------------------------------------------------------------------------

::method displayClasses class
    -- All or specified classes (public & private) that are visible from current context, with their package
    -- classnames is an array of Argument
    use strict arg classnames, displayer, context
    matchers = .array~new
    do classname over classnames
        matcher = pattern2matcher(classname, /*wholestring*/ .true, /*caseless*/ .true, /*displayer*/ displayer, "[object filter]")
        matchers~append(matcher)
    end
    classInfos = .classInfo~collect(context, matchers)
    -- Now build a collection where the indexes are the class names preceded by some flags (mixing, private), and the items are the package filenames.
    classes = .relation~new
    s = classInfos~supplier
    do while s~available
        classInfo = s~item
        classFlags = classInfos(classInfo~klass, classInfo~visibility)
        classes[classFlags~left(10) classInfo~klass~id~quoted(x2c(27))] = "("packageInfos(classInfo~package)")"
        s~next
    end
    -- Sort by class name, ignoring the 10 first characters which are class flags.
    displayer~sayCollection(classes, /*title*/.nil, /*comparator*/.ColumnComparator~new(10,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false)


::method displayClassMethods class
    -- Display the methods of each specified class
    -- classnames is an array of Argument
    use strict arg classnames, inherited, displayer, context, filteringStream
    matchers = .array~new
    do classname over classnames
        matcher = pattern2matcher(classname, /*wholestring*/ .true, /*caseless*/ .true, /*displayer*/ displayer, "[object filter]")
        matchers~append(matcher)
    end
    classInfos = .classInfo~collect(context) -- don't filter with matchers here, must have ALL the classes, to get the right package of inherited methods.
    classInfosSorted = .list~new
    classInfos~pipe(,
        .select {expose matchers
                 matched = matchers~isEmpty
                 do matcher over matchers while \matched
                     matched = matcher~(index~id)
                 end
                 matched
                },
      | .sort {item~klass~id} {item~visibility} {item~package},
      | .do {expose classInfosSorted; classInfosSorted~append(item)},
    )
    count = 1
    do classInfo over classInfosSorted
        --say
        --displayer~sayInfo("[Info]" "["count"]" "Class" classInfo~klass~id~quoted(x2c(27)) classInfos(classInfo~klass, classInfo~visibility) "("packageInfos(classInfo~package)")")
        filteringStream~doBeforeNextLine = {
            expose displayer count classInfo
            say
            displayer~sayInfo("[Info]" "["count"]" "Class" classInfo~klass~id~quoted(x2c(27)) classInfos(classInfo~klass, classInfo~visibility) "("packageInfos(classInfo~package)")")
        } -- This action will be executed before the first line of methods is displayed, if any (will depend on the filtering)
        methods = .relation~new
        call collectMethods
        lineCount = filteringStream~lineCount
        displayer~sayCollection(methods, /*title*/.nil, .ColumnComparator~new(10,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false)
        filteringStream~doBeforeNextLine = .nil
        if filteringStream~lineCount <> lineCount then do
            displayer~sayInfo("[Info]" "["count"]" "Class" "'"classInfo~klass~id"' has" displayer~singularPlural(methods~items, "method", "methods"))
        end
        count += 1
    end
    return

    collectMethods:
        signal on syntax name pipeError -- TEMPORARY : some classes don't understand message ~pipe
        -- Bug: With ooRexx < 5.0, the package of a method created with ::ATTRIBUTE is .nil.
        -- Bypass this bug by using the package of the class.
        injectClass = .inject {item~klass} "mem.class"
        if inherited then injectClass |= .superclasses "recursive" "once" "after" "mem.class"
        classInfo~pipe(,
            injectClass,
          | .splitter[.inject {item~instanceMethods(item)} "iterateAfter" "mem.classMethod",,
                      .inject {item~methods(item)} "iterateAfter" "mem.instanceMethod"],
          | .do { expose classInfos methods
                  package = .nil
                  if item <> .nil then package = item~package -- if method not hidden
                  class = dataflow["class"]~item
                  classInfo = classInfos[class]
                  if package == .nil then package = classInfo~package
                  instanceLevel = dataflow["instanceMethod"] <> .nil
                  -- Insert class flags at the begining to have the same format than displayClasses.
                  -- That allows to reuse a filter applicable to classes.
                  classFlags = classInfos(classInfo~klass, classInfo~visibility)
                  methodFlags = methodInfos(item, instanceLevel)
                  flags = classFlags methodFlags
                  methods[flags~left(10) index~quoted(x2c(27))] = class~id~quoted(x2c(27)) "("packageInfos(package)")"
                },
        )
        return

    pipeError:
        displayer~sayError("[Error]" condition("O")~message)
        return


::method displayHelp class
    -- classnames is an array of Argument
    use strict arg classnames, inherited, displayer, context
    if classnames~isEmpty then do
        if inherited then do
            -- Classes having the "_description" class method (can be inherited)
            selectClass = .select { item~instanceMethod("_DESCRIPTION_") <> .nil }
        end
        else do
            -- Classes having their own "_description_" class method (not an inherited one).
            selectClass = .select { item~instanceMethods(item)~allIndexes~hasItem("_DESCRIPTION_") }
        end
        say "Classes with help text:"
        .object~pipe(,
            .subClasses "recursive" "once",
          | selectClass,
          | .sort,
          | .console "    " {item~id},
        )
        return
    end

    -- For each specified class, display the comment stored in the source of the method _description_, if any.
    matchers = .array~new
    do classname over classnames
        matcher = pattern2matcher(classname, /*wholestring*/ .true, /*caseless*/ .true, /*displayer*/ displayer, "[object filter]")
        matchers~append(matcher)
    end
    classInfos = .classInfo~collect(context, matchers)
    classInfosSorted = .list~new
    classInfos~pipe(,
        .select { expose matchers
                  matched = matchers~isEmpty
                  do matcher over matchers while \matched
                      matched = matcher~(index~id)
                  end
                  matched
                },
      | .sort {item~klass~id} {item~visibility} {item~package},
      | .do {expose classInfosSorted; classInfosSorted~append(item)},
    )
    count = 1
    do classInfo over classInfosSorted
        say
        displayer~sayInfo("[Info]" "["count"]" "Class" classInfo~klass~id~quoted(x2c(27)) classInfos(classInfo~klass, classInfo~visibility) "("packageInfos(classInfo~package)")")
        call displayClassHelp classInfo~klass
        count += 1
    end
    return

    displayClassHelp: procedure
        use strict arg class
        description = class~instanceMethod("_description_")
        if description <> .nil then do
            source = description~source -- an array
            items = source~items
            if items > 4 then do
                -- by necessity, the comment must have an instruction before and after, to be kept in the source (bug ?)
                -- by convention, a description is like that :
                -- nop
                -- /*
                -- description (several lines)
                -- */
                -- nop
                source = source~section(3, items - 4)
            end
            do line over source; say line; end -- better than say source~tostring, to have a good count of lines by a monitor
        end
        else say "no help"
        say
        return


::method displayMethods class
    -- Display the defining classes of each specified method
    -- methodnames is an array of Argument
    use strict arg methodnames, displayer, context
    matchers = .array~new
    do methodname over methodnames
        matcher = pattern2matcher(methodname, /*wholestring*/ .true, /*caseless*/ .true, /*displayer*/ displayer, "[object filter]")
        matchers~append(matcher)
    end

    -- Bug: With ooRexx < 5.0, the package of a method created with ::ATTRIBUTE is .nil.
    -- Bypass this bug by using the package of the class.
    classInfos = .classInfo~collect(context) -- will be used to get the package of the class

    methods = .relation~new
    .object~pipe(,
        .subClasses "recursive" "once" "after" "mem.class",
      | .splitter[.inject {item~instanceMethods(item)} "iterateAfter" "mem.classMethod",,
                  .inject {item~methods(item)} "iterateAfter" "mem.instanceMethod"],
      | .select { expose matchers
                  matched = matchers~isEmpty
                  do matcher over matchers while \matched
                      matched = matcher~(index)
                  end
                  matched
                },
      | .do { expose classInfos methods
              package = .nil
              if item <> .nil then package = item~package -- if method not hidden
              class = dataflow["class"]~item
              classInfo = classInfos[class]
              if package == .nil then package = classInfo~package
              instanceLevel = dataflow["instanceMethod"] <> .nil
              classFlags = classInfos(classInfo~klass, classInfo~visibility)
              methodFlags = methodInfos(item, instanceLevel)
              flags = classFlags methodFlags
              methods[flags~left(10) index~quoted(x2c(27))] = class~id~quoted(x2c(27)) "("packageInfos(package)")"
            },
    )
    displayer~sayCollection( methods, /*title*/.nil, .ColumnComparator~new(10,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false)
    return


::method displayPackages class
    -- All packages that are visible from current context, including the current package (source of the pipeline).
    use strict arg displayer, context
    context~package~pipe(.importedPackages "recursive" "once" "after" | .sort {item~name} | .console {item~name})


-------------------------------------------------------------------------------
-- Helpers for ClassInfoQuery
-------------------------------------------------------------------------------

::routine methodInfos public
    use strict arg method, instanceLevel
    if method == .nil then return "----" -- Hidden method, see documentation of .class~methods
    if instanceLevel then level = "I"; else level = "C"
    if method~isGuarded then guarded = "G"; else guarded = "."
    if method~isPrivate then visibility = "p"; else visibility = "P"
    if method~isProtected then protected = "P"; else protected = "."
    return level || guarded || visibility || protected


::routine methodPackageInfos public
    -- Not used because
    -- Bug: With ooRexx < 5.0, the package of a method created with ::ATTRIBUTE is .nil.
    use strict arg method
    if method == .nil then return "UNDEFINED"
    return packageInfos(method~package)


::routine packageInfos public
    -- With ooRexx < 5.0
    -- The package of the predefined methods is .nil.
    -- It's not possible to get directly the package of a class.
    -- With ooRexx >= 5.0
    -- The package of a class created dynamically is still .nil.
    use strict arg package
    if package == .nil then return ""
    return .file~new(package~name)~name


::routine classInfos public
    use strict arg class, visibility
    if visibility == "private" then visibility = "p"; else visibility = "P"
    if class~queryMixinClass then mixin = "M"; else mixin = "."
    return mixin || visibility


-------------------------------------------------------------------------------
::class "Filter"
-------------------------------------------------------------------------------

::constant StrictDifferent      1
::constant StrictEqual          2
::constant CaselessDifferent    3
::constant CaselessEqual        4

::method parse class
    -- "=something"     not recognized as filter operator, because is quoted
    -- =something       recognized as filter operator
    -- arg is an Argument
    use strict arg arg
    if operator("\==", self~StrictDifferent) then return filter
    if operator("==", self~StrictEqual) then return filter
    if operator("<>", self~CaselessDifferent) then return filter
    if operator("=", self~CaselessEqual) then return filter
    return self~new(0, arg) -- no operator

    operator: procedure expose arg filter
        use strict arg operatorString, operatorCode
        left = arg~left(operatorString~length)
        if left~string <> operatorString then return .false
        if left~quotedFlags~countStr("1") <> 0 then return .false -- at least one char is quoted
        argument = arg~substr(operatorString~length + 1)
        filter = .Filter~new(operatorCode, argument)
        return .true


::attribute operator
::attribute argument

::method init
    expose operator argument
    use strict arg operator, argument


-------------------------------------------------------------------------------
::class "FilteringStream" public
-------------------------------------------------------------------------------

::method firstFilterIndex class
    -- args is an array of Argument
    use strict arg args
    index = 0
    do arg over args
        index += 1
        filter = .Filter~parse(arg)
        if filter~operator <> 0 then return index -- This is the first filter operator. Returns its index.
    end
    return 0


::attribute valid
::attribute interceptedDestination
::attribute strictInclude
::attribute strictExclude
::attribute caselessInclude
::attribute caselessExclude
::attribute lineCount
::attribute stringbuffer
::attribute doBeforeNextLine -- doer triggered once, only if at least one line is displayed


::method init
    -- Examples of valid filters:
    -- ""                                 -- no filter
    -- "value"                            -- caseless equals value
    -- "=value"                           -- caseless equals value
    -- "== value"                         -- casesensitive equals value
    -- "<> value1 value2 = value3 value4" -- (<> value1 AND <> value2) AND (= value3 OR = value4)
    -- A value can be a string surrounded by quotes

    -- filters is an array of Argument
    use strict arg destination, filters
    self~valid = .false -- Will become .true at the end, if no error
    self~interceptedDestination = destination
    self~strictExclude = .array~new
    self~strictInclude = .array~new
    self~caselessExclude = .array~new
    self~caselessInclude = .array~new
    self~lineCount = 0
    self~stringbuffer = .mutablebuffer~new
    currentOperator = .Filter~CaselessEqual
    do filter over filters
        filter = .Filter~parse(filter)
        if filter~operator <> 0 then currentOperator = filter~operator
        if filter~argument~string <> "" then do
            matcherCaselessInclude = pattern2matcher(filter~argument, /*wholestring*/ .false, /*caseless*/ .true)
            matcherStrictInclude = pattern2matcher(filter~argument, /*wholestring*/ .false, /*caseless*/ .false)

            if currentOperator == .filter~StrictDifferent then self~strictExclude~append(matcherStrictInclude) -- will negate the result
            else if currentOperator == .filter~StrictEqual then self~strictInclude~append(matcherStrictInclude)
            else if currentOperator == .filter~CaselessDifferent then self~caselessExclude~append(matcherCaselessInclude) -- will negate the result
            else if currentOperator == .filter~CaselessEqual then self~caselessInclude~append(matcherCaselessInclude)
        end
    end
    self~doBeforeNextLine = .nil
    self~valid = .true


::method traceFilter
    use strict arg displayer

    prefix = "[line filter]"
    first = .true
    do matcher over self~strictInclude
        if \first then displayer~sayTrace(prefix "OR")
        call traceMatcher matcher, displayer, prefix
        first = .false
    end
    do matcher over self~caselessInclude
        if \first then displayer~sayTrace(prefix "OR")
        call traceMatcher matcher, displayer, prefix
        first = .false
    end
    do matcher over self~strictExclude
        if first then displayer~sayTrace(prefix "NOT")
        else displayer~sayTrace(prefix "AND NOT")
        call traceMatcher matcher, displayer, prefix
        first = .false
    end
    do matcher over self~caselessExclude
        if first then displayer~sayTrace(prefix "NOT")
        else displayer~sayTrace(prefix "AND NOT")
        call traceMatcher matcher, displayer, prefix
        first = .false
    end


::method select
    if \self~valid then return .false

    use strict arg string

    -- Empty lines are not filtered
    if string == "" then return .true

    -- Info lines are not filtered
    if string~abbrev("[Info]") then return .true

    do matcher over self~strictExclude
        if matcher~(string) then return .false
    end
    do matcher over self~caselessExclude
        if matcher~(string) then return .false
    end

    if self~strictInclude~size == 0 & self~caselessInclude~size == 0 then return .true

    do matcher over self~strictInclude
        if matcher~(string) then return .true
    end
    do matcher over self~caselessInclude
        if matcher~(string) then return .true
    end
    return .false


::method charOut
    expose stringbuffer
    use strict arg string
    stringbuffer~append(string)
    return 0


::method lineOut
    expose stringbuffer
    use strict arg string

    stringbuffer~append(string)
    line = stringbuffer~string
    stringbuffer~delete(1)
    if self~select(line) then do
        self~lineCount += 1
        if self~doBeforeNextLine <> .nil then do
            action = self~doBeforeNextLine
            self~doBeforeNextLine = .nil -- reset before call to avoid infinite recursion
            action~()
        end
        forward to (self~interceptedDestination) array (line)
    end
    return 0


::method say
    expose stringbuffer
    use strict arg string

    stringbuffer~append(string)
    line = stringbuffer~string
    stringbuffer~delete(1)
    if self~select(line) then do
        self~lineCount += 1
        if self~doBeforeNextLine <> .nil then do
            action = self~doBeforeNextLine
            self~doBeforeNextLine = .nil -- reset before call to avoid infinite recursion
            action~()
        end
        forward to (self~interceptedDestination) array (line)
    end
    return 0


::method flush
    expose stringbuffer
    line = stringbuffer~string
    stringbuffer~delete(1)
    -- no filtering, to let always display the escape characters for colors
    if .true /*self~select(line)*/ then do
        -- self~lineCount += 1 -- incomplete line...
        self~interceptedDestination~charOut(line)
        forward to (self~interceptedDestination)
    end
    return 0


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

::routine pattern2matcher public
    -- Pattern matching by equality (whole) or by inclusion (not whole), caseless or not.
    -- If the package regex.cls is loaded, then the pattern can be a regular expression prefixed by "/".
    -- When whole, and the pattern is not a regular expression, then the charecter "*" is recognized
    -- as a generic character when first or last character.
    -- The returned result is a block (matcher) which implements the pattern matching, or .nil if error.
    -- The pattern matching is tested when the block is evaluated with a string passed as argument.
    -- Examples:

    --   matcher = pattern2matcher("object") -- caseless equality
    --   matcher~("ObjeCt") -- true
    --   matcher~("my ObjeCt") -- false

    --   matcher = pattern2matcher("*object") -- caseless equality with generic character
    --   matcher~("ObjeCt") -- true
    --   matcher~("my ObjeCt") -- true

    --   matcher = pattern2matcher("object", false) -- caseless inclusion
    --   matcher~("ObjeCt") -- true
    --   matcher~("my ObjeCt") -- true

    --   matcher = pattern2matcher("/^object|object$", false) -- caseless inclusion, regular expression: "object" at the begining or at the end.
    --   matcher~("ObjeCt") -- true
    --   matcher~("my ObjeCt") -- true
    --   matcher~("my ObjeCts") -- false

    -- stringPattern is an Argument
    use strict arg stringPattern, wholeString=.true, caseless=.true, displayer=.nil, prefix=""
    matcher = .nil

    firstCharIsQuoted = stringPattern~quotedFlags~subchar(1) == "1"
    lastCharIsQuoted = stringPattern~quotedFlags~subchar(stringPattern~string~length) == "1"
    stringPattern = stringPattern~string

    -- Build a description of the matcher, will be displayed when tracing the filters
    description = "stringPattern="stringPattern~quoted "wholeString="wholeString "caseless="caseless

    regularExpression = \firstCharIsQuoted & stringPattern~subchar(1) == "/"
    if regularExpression then do
        if .Pattern~isa(.class), .Pattern~hasMethod("compile") then do
            -- Good, the package regex.cls is loaded
            stringPattern = stringPattern~substr(2) -- remove the "/"
        end
        else raise syntax 93.900 array("Regular expression" stringPattern~quoted "not supported: The package regex.cls is not loaded")
    end

    if regularExpression then do
        signal on syntax name patternCompileError
        if caseless then pattern = .Pattern~compile(stringPattern, .RegexCompiler~new(.RegexCompiler~caseless))
        else             pattern = .Pattern~compile(stringPattern)

        if wholeString then matcher = {expose pattern; use strict arg string; return pattern~matches(string)}
        else                matcher = {expose pattern; use strict arg string; return pattern~find(string)~matched}
    end
    else do
        -- the pattern remains a string
        leftStar = \firstCharIsQuoted & stringPattern~left(1) == "*"
        rightStar = \lastCharIsQuoted & stringPattern~right(1) == "*"
        if leftStar & rightStar then do
            if stringPattern~length <= 2 then stringPattern = "" -- "*" or "**" --> ""
            else stringPattern = stringPattern~substr(2, stringPattern~length - 2) -- "*...*" --> "..."
        end
        else if leftStar then stringPattern = stringPattern~substr(2)
        else if rightStar then stringPattern = stringPattern~left(stringPattern~length - 1)

        if stringPattern == "" then return {expose description; return .true}
        else if wholeString & \leftStar & \rightStar then do
            if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessEquals(stringPattern)}
            else             matcher = {expose description stringPattern; use strict arg string; return string~equals(stringPattern)}
        end
        else if wholeString & \leftStar & rightStar then do
            if caseless then matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~caselessEquals(stringPattern)}
            else             matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~equals(stringPattern)}
        end
        else if wholeString & leftStar & \rightStar then do
            if caseless then matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~caselessEquals(stringPattern)}
            else             matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~equals(stringPattern)}
        end
        else do -- \wholeString | (leftStar & rightStar)
            if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessPos(stringPattern) <> 0}
            else             matcher = {expose description stringPattern; use strict arg string; return string~pos(stringPattern) <> 0}
        end
    end
    if displayer <> .nil, displayer~traceFilter then call traceMatcher matcher, displayer, prefix
    return matcher

    patternCompileError:
        raise syntax 93.900 array("Regular expression" stringPattern~quoted ":" condition("O")~message)


::routine traceMatcher
    use strict arg matcher, displayer, prefix
    -- matcher is a closure created by pattern2matcher.
    -- The variables of pattern2matcher have been captured, and can be retrieved, in particular the description.
    displayer~sayTrace(prefix matcher~variables~description)
    do line over matcher~source
        displayer~sayTrace(prefix line)
    end
