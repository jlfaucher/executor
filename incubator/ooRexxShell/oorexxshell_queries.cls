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
-- I simulate this package, but using a slightly different name to avoid confusion.
::attribute REXXPackage class get

::method init class
    expose REXXPackage
    REXXPackage = .package~new("_REXX_", "")


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
    use strict arg classnames, displayer, context
    matchers = .array~new
    do classname. over classnames
        matcher = pattern2block(classname.string) -- wholeString, caseless
        if matcher == .nil then return -- Syntax error in regular expression
        matchers~append(matcher)
    end
    classInfos = .classInfo~collect(context, matchers)
    -- Now build a collection where the indexes are the class names preceded by some flags (mixing, private), and the items are the package filenames.
    classes = .relation~new
    s = classInfos~supplier
    do while s~available
        classInfo = s~item
        classes[classInfos(classInfo~klass, classInfo~visibility)~left(10) classInfo~klass~id~quoted(x2c(27))] = "("packageInfos(classInfo~package)")"
        s~next
    end
    -- Sort by class name, ignoring the 10 first characters which are class flags.
    displayer~sayCollection(classes, /*title*/.nil, /*comparator*/.ColumnComparator~new(10,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false)


::method displayClassMethods class
    -- Display the methods of each specified class
    use strict arg classnames, inherited, displayer, context
    matchers = .array~new
    do classname. over classnames
        matcher = pattern2block(classname.string) -- wholeString, caseless
        if matcher == .nil then return -- Syntax error in regular expression
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
        say
        displayer~sayInfo("[Info]" "["count"]" "Class" classInfo~klass~id~quoted(x2c(27)) classInfos(classInfo~klass, classInfo~visibility) "("packageInfos(classInfo~package)")")
        methods = .relation~new
        call collectMethods
        displayer~sayCollection(methods, /*title*/.nil, .ColumnComparator~new(10,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false)
        displayer~sayInfo("[Info]" "["count"]" "Class" "'"classInfo~klass~id"' has" displayer~singularPlural(methods~items, "method", "methods"))
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
                  class = dataflow["class"]~item
                  package = classInfos[class]~package
                  instanceLevel = dataflow["instanceMethod"] <> .nil
                  methods[methodInfos(item, instanceLevel)~left(10) index~quoted(x2c(27))] = class~id~quoted(x2c(27)) "("packageInfos(package)")"
                },
        )
        return

    pipeError:
        displayer~sayError("[Error]" condition("O")~message)
        return


::method displayHelp class
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
    do classname. over classnames
        matcher = pattern2block(classname.string) -- wholeString, caseless
        if matcher == .nil then return -- Syntax error in regular expression
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
    use strict arg methodnames, displayer, context
    matchers = .array~new
    do methodname. over methodnames
        matcher = pattern2block(methodname.string) -- wholeString caseless
        if matcher == .nil then return -- Syntax error in regular expression
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
              class = dataflow["class"]~item
              package = classInfos[class]~package
              instanceLevel = dataflow["instanceMethod"] <> .nil
              methods[methodInfos(item, instanceLevel)~left(10) index~quoted(x2c(27))] = class~id~quoted(x2c(27)) "("packageInfos(package)")"
            },
    )
    displayer~sayCollection( methods, /*title*/.nil, .ColumnComparator~new(10,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false)
    return


::method displayPackages class
    -- All packages that are visible from current context, including the current package (source of the pipeline).
    use strict arg displayer, context
    context~package~pipe(.importedPackages "recursive" "once" "after" | .sort {item~name} | .console {item~name})


-------------------------------------------------------------------------------
::class filteringStream public
-------------------------------------------------------------------------------

::constant StrictDifferent      1
::constant StrictEqual          2
::constant CaselessDifferent    3
::constant CaselessEqual        4


::method parse class
    -- "=something"     not recognized as filter operator, because is quoted
    -- =something       recognized as filter operator
    use strict arg arg.
    if operator("\==", self~StrictDifferent) then return operator
    if operator("==", self~StrictEqual) then return operator
    if operator("<>", self~CaselessDifferent) then return operator
    if operator("=", self~CaselessEqual) then return operator
    return filter(0, arg.string)
    operator: procedure expose arg. operator
        use strict arg operatorString, operatorCode
        if arg.isquoted then return .false
        pos = arg.string~pos(operatorString)
        if pos <> 1 then return .false
        operator = filter(operatorCode, arg.string~substr(operatorString~length + 1))
        return .true
    filter: procedure
        use strict arg operatorCode, operatorArgument
        return .stem~new~~put(operatorCode, "OPERATOR")~~put(operatorArgument, "ARGUMENT")


::method firstFilterIndex class
    use strict arg args
    index = 0
    do arg. over args
        index += 1
        filter. = self~parse(arg.)
        if filter.operator <> 0 then return index -- This is the first filter operator. Returns its index.
    end
    return 0


::attribute valid
::attribute interceptedDestination
::attribute strictInclude
::attribute strictExclude
::attribute caselessInclude
::attribute caselessExclude
::attribute lineCount


::method init
    -- Examples of valid filters:
    -- ""
    -- "value"
    -- "=value"
    -- "== value"
    -- "<> value1 value2 = value3 \== value4 value5"
    -- A value can be a string surrounded by quotes
    use strict arg destination, filters
    self~valid = .false -- Will become .true at the end, if no error
    self~interceptedDestination = destination
    self~strictExclude = .array~new
    self~strictInclude = .array~new
    self~caselessExclude = .array~new
    self~caselessInclude = .array~new
    self~lineCount = 0
    currentOperator = self~CaselessEqual
    do filter over filters
        filter. = self~class~parse(filter)
        if filter.operator <> 0 then currentOperator = filter.operator
        if filter.argument <> "" then do
            matcherCaselessInclude = pattern2block(filter.argument, .false) -- not wholeString, caseless
            if matcherCaselessInclude == .nil then return -- Syntax error in regular expression

            matcherStrictInclude = pattern2block(filter.argument, .false, .false) -- not wholeString, caseSensitive
            if matcherStrictInclude == .nil then return -- Syntax error in regular expression

            if currentOperator == self~StrictDifferent then self~strictExclude~append(matcherStrictInclude) -- will negate the result
            else if currentOperator == self~StrictEqual then self~strictInclude~append(matcherStrictInclude)
            else if currentOperator == self~CaselessDifferent then self~caselessExclude~append(matcherCaselessInclude) -- will negate the result
            else if currentOperator == self~CaselessEqual then self~caselessInclude~append(matcherCaselessInclude)
        end
    end
    self~valid = .true


::method traceFilter
    use strict arg displayer

    prefix = "[filter]"
    first = .true
    do matcher over self~strictInclude
        if \first then displayer~sayTrace(prefix "OR")
        call traceMatcher
    end
    do matcher over self~caselessInclude
        if \first then displayer~sayTrace(prefix "OR")
        call traceMatcher
    end
    do matcher over self~strictExclude
        if first then displayer~sayTrace(prefix "NOT")
        else displayer~sayTrace(prefix "AND NOT")
        call traceMatcher
    end
    do matcher over self~caselessExclude
        if first then displayer~sayTrace(prefix "NOT")
        else displayer~sayTrace(prefix "AND NOT")
        call traceMatcher
    end
    return

    traceMatcher:
        -- matcher is a closure created by pattern2block.
        -- The variables of pattern2block have been captured, and can be retrieved, in particular the description.
        displayer~sayTrace(prefix matcher~variables["DESCRIPTION"])
        do line over matcher~source
            displayer~sayTrace(prefix line)
        end
        first = .false
        return


::method select
    if \self~valid then return .false

    use strict arg string
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
    use strict arg string
    if self~select(string) then forward to (self~interceptedDestination)
    return 0


::method lineOut
    use strict arg string
    if self~select(string) then do
        self~lineCount += 1
        forward to (self~interceptedDestination)
    end
    return 0


::method say
    use strict arg string
    if self~select(string) then do
        self~lineCount += 1
        forward to (self~interceptedDestination)
    end
    return 0


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

::routine methodInfos public
    use strict arg method, instanceLevel
    if method == .nil then return "----"
    if instanceLevel then level = "I"; else level = "C"
    if method~isGuarded then guarded = "G"; else guarded = "."
    if method~isPrivate then private = "P"; else private = "."
    if method~isProtected then protected = "P"; else protected = "."
    return level || guarded || private || protected


::routine pattern2block public
    -- Pattern matching by equality (whole) or by inclusion (not whole), caseless or not.
    -- The result is a block which implements the pattern matching, or .nil if error.
    -- The pattern matching is tested when the block is evaluated with a string passed as argument.
    -- If the package regex.cls is loaded, then the pattern can be a regular expression.
    -- Example:
    --   matcher = pattern2block("object") -- caseless equality
    --   matcher~("ObjeCt") -- true
    --   matcher~("my ObjeCt") -- false
    --   matcher = pattern2block("object", false) -- caseless inclusion
    --   matcher~("ObjeCt") -- true
    --   matcher~("my ObjeCt") -- true
    --   matcher = pattern2block("^object|object$", false) -- caseless inclusion, regular expression: "object" at the begining or at the end.
    --   matcher~("ObjeCt") -- true
    --   matcher~("my ObjeCt") -- true
    --   matcher~("my ObjeCts") -- false

    use strict arg stringPattern, wholeString=.true, caseless=.true
    block = .nil

    -- Build a description of the matcher, will be displayed when tracing the filters
    description = "stringPattern="stringPattern~quoted "wholeString="wholeString "caseless="caseless

    if .Pattern~isa(.class), .Pattern~hasMethod("compile") then do
        signal on syntax name patternCompileError
        if caseless then pattern = .Pattern~compile(stringPattern, .RegexCompiler~new(.RegexCompiler~caseless))
        else             pattern = .Pattern~compile(stringPattern)

        if wholeString then block = {expose pattern; use strict arg string; return pattern~matches(string)}
        else                block = {expose pattern; use strict arg string; return pattern~find(string)~matched}
    end
    else do
        -- the pattern remains a string
        if wholeString then do
            if caseless then block = {expose stringPattern; use strict arg string; return string~caselessEquals(stringPattern)}
            else             block = {expose stringPattern; use strict arg string; return string~equals(stringPattern)}
        end
        else do
            if caseless then block = {expose stringPattern; use strict arg string; return string~caselessPos(stringPattern) <> 0}
            else             block = {expose stringPattern; use strict arg string; return string~pos(stringPattern) <> 0}
        end
    end
    return block

    patternCompileError:
        displayer~sayError("[Error] Regular expression" string~quoted)
        displayer~sayError("[Error]" condition("O")~message)
        return .nil


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
    if visibility == "private" then private = "P"; else private = "."
    if class~queryMixinClass then mixin = "M"; else mixin = "."
    return mixin || private
