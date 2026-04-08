/*
This is an adaptation of oorexxshell_queries.cls to ensure compatibility
with ooRexx 4.2, ooRexx 5 and Executor5-bulk
*/

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

::requires "pipeline/pipe_std.cls"
::requires "extension/callable_std.cls"
::requires "extension/extender_std.cls"
::requires "extension/stringChunk.cls"
::requires "extension/stringChunkMatcher.cls"

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
        'AlarmNotification',    -- ooRexx5
        'ArgUtil',
        'Array',
        'Bag',
        'BagMixin',             -- ooRexx5
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
        'EventSemaphore',       -- ooRexx5
        'File',
        'IdentityTable',
        'InputOutputStream',
        'InputStream',
        'InvertingComparator',
        'List',
        'LocalServer',          -- ooRexx5
        'ManyItemMixin',        -- ooRexx5
        'MapCollection',
        'Message',
        'MessageNotification',  -- ooRexx5
        'Method',
        'Monitor',
        'MutableBuffer',
        'MutexSemaphore',       -- ooRexx5
        'NumericComparator',
        'Object',
        'OLEObject',
        'OLEVariant',
        'Orderable',
        'OrderedCollection',
        'OutputStream',
        'Package',
        'Pointer',
        'Properties',
        'Queue',
        'Relation',
        'RexxBlock',            -- Executor extension
        'RexxContext',
        'RexxInfo',             -- ooRexx5
        'RexxQueue',
        'RexxText',             -- Executor extension
        'Routine',
        'SERIALIZEFUNCTIONS',
        'Serializable',
        'Set',
        'SetMixin',             -- ooRexx5
        'SetCollection',
        'Singleton',            -- ooRexx5
        'SourceLiteralParser',  -- Executor extension
        'StackFrame',
        'Stem',
        'Stream',
        'StreamSupplier',
        'String',
        'StringTable',          -- ooRexx5
        'Supplier',
        'SupplierMixin',        -- ooRexx5
        'Table',
        'TICKER',               -- ooRexx5
        'TimeSpan',
        'TraceObject',          -- ooRexx5
        'Unicode',              -- Executor extension, Executor5-bulk extension
        'Validate',
        'VariableReference',    -- ooRexx5
        'WeakReference',
        'server'


::method isPredefinedClass class
    use strict arg classname
    return self~predefinedClassNames~wordpos(classname) <> 0


::method collect class
    -- Remember: this implementation works with ooRexx 4.2 where classes have no "package" method.
    use strict arg context, matchers=(.array~new)
    publicClasses = .relation~new
    ( -
        .importedPackages "recursive" "once" "after" "mem.package" -
      | .inject .Lambda~new('use arg item; return item~publicClasses') "iterateAfter" -
      | .do .Closure~new(' expose publicClasses; use arg item, index, dataflow; publicClasses[item] = dataflow["package"]~item ', .context) -
    )~go(context~package)
    privateClasses = .relation~new
    ( -
        .importedPackages "recursive" "once" "after" "mem.package" -
      | .inject .Lambda~new('use arg item; return item~classes') "iterateAfter" -
      | .do .Closure~new( -
              'expose publicClasses privateClasses;' -
              'use arg item, index, dataflow, pipeContext;' -
              'if \publicClasses~hasIndex(item) then privateClasses[item] = dataflow["package"]~item;' -
            , .context) -
    )~go(context~package)
    -- Previous queries do not return the predefined classes.
    -- Remember (again): this implementation works with ooRexx 4.2 where classes have no "package" method.
    ( -
        .subclasses "recursive" "once" "after" -
      | .do .Closure~new( -
              'expose publicClasses privateClasses;' -
              'use arg item, index, dataflow, pipeContext;' -
              'if \publicClasses~hasIndex(item) & \privateClasses~hasIndex(item) then do;' -
              '    package = .nil;' -
              '    if item~hasMethod("package") then package = item~package;' -
              '    /*say "*** item~id =" item~id "package =" package*/;' -
              '    if .nil == package then do;' -
              '        /* No package, can''t guess if the class is public or private. */;'-
              '        /* Assume it''s public. */;' -
              '        publicClasses[item] = package;' -
              '    end;' -
              '    else do;' -
              '        /* I have a problem with Executor: */;' -
              '        /* The publicClasses directory of the Rexx package is empty. */;' -
              '        /* In this case, assume that all the Rexx classes are public. */;' -
              '        if package~publicClasses~items == 0 | package~publicClasses~hasEntry(item~id) then do /* yes! hasEntry, not hasIndex which needs uppercases */;' -
              '            publicClasses[item] = package;' -
              '        end;' -
              '        else do;' -
              '            privateClasses[item] = package;' -
              '        end;' -
              '    end;' -
              'end;' -
            , .context) -
    )~go(.object)
    -- Now build a collection of classInfo.
    classInfos = .table~new -- index is a class, item is a classInfo
    s = publicClasses~supplier
    do while s~available
        matched = matchers~isEmpty
        do matcher over matchers while \matched
            matched = matcher~match(s~index~id)
        end
        if matched then classInfos[s~index] = .classInfo~new(s~index, s~item, "public")
        s~next
    end
    s = privateClasses~supplier
    do while s~available
        matched = matchers~isEmpty
        do matcher over matchers while \matched
            matched = matcher~match(s~index~id)
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
    if .nil == package, self~class~isPredefinedClass(klass~id) then package = self~class~REXXPackage


-------------------------------------------------------------------------------
::class "RoutineInfo" public
-------------------------------------------------------------------------------

::method collect class
    use strict arg context, matchers=(.array~new)
    publicRoutines = .relation~new
    ( -
        .importedPackages "recursive" "once" "after" "mem.package" -
      | .inject .Lambda~new('use arg item; return item~publicRoutines') "iterateAfter" -
      | .do .Closure~new( -
              'expose publicRoutines;' -
              'use arg item, index, dataflow, pipeContext;' -
              'publicRoutines[item] = .routineInfo~new(index, item, dataflow["package"]~item, "public");' -
            , .context) -
    )~go(context~package)
    privateRoutines = .relation~new
    (,
        .importedPackages "recursive" "once" "after" "mem.package",
      | .inject .Lambda~new('use arg item; return item~routines') "iterateAfter",
      | .do .Closure~new( -
              'expose publicRoutines privateRoutines;' -
              'use arg item, index, dataflow, pipeContext;' -
              'if \publicRoutines~hasIndex(item) then privateRoutines[item] = .routineInfo~new(index, item, dataflow["package"]~item, "private");' -
            , .context) -
    )~go(context~package)
    -- Now build a collection of routineInfo.
    routineInfos = .table~new -- index is a routine, item is a routineInfo
    s = publicRoutines~supplier
    do while s~available
        matched = matchers~isEmpty
        do matcher over matchers while \matched
            matched = matcher~match(s~item~name)
        end
        if matched then routineInfos[s~index] = s~item
        s~next
    end
    s = privateRoutines~supplier
    do while s~available
        matched = matchers~isEmpty
        do matcher over matchers while \matched
            matched = matcher~match(s~item~name)
        end
        if matched then routineInfos[s~index] = s~item
        s~next
    end
    return routineInfos


::attribute name -- the routine name
::attribute routine -- the routine
::attribute package get -- the package where the routine is defined
::attribute visibility get -- the visibility of the routine in the package: "public", "private"


::method init
    expose name routine package visibility
    use strict arg name, routine, package, visibility


-------------------------------------------------------------------------------
::class "QueryManager" public
-------------------------------------------------------------------------------

/*
The QueryManager uses a displayer passed as argument.
Displayer:
method sayInfo
method sayTrace
method sayError
method sayCollection
method sayCondition     (not used)
method sayPrettyString  (not used)
method sayStackFrames   (not used)
method singularPlural
method prettyString     (not used)
attribute traceFilter
attribute maxPackageNameWidth
*/


::method displayClasses class
    -- All or specified classes (public & private) that are visible from current context, with their package
    -- classnames is an array of StringChunk
    use strict arg classnames, displayer, context
    matchers = .array~new
    do classname over classnames
        matcher = matcher(classname, /*wholestring:*/ .true, /*caseless:*/ .true, /*trace:*/ displayer~traceFilter, /*displayer:*/ displayer, /*prefix:*/ "[object filter]")
        matchers~append(matcher)
    end
    classInfos = .classInfo~collect(context, matchers)
    -- Now build a collection where the indexes are the class names preceded by some flags (mixing, private), and the items are the package filenames.
    classes = .relation~new
    s = classInfos~supplier
    do while s~available
        classInfo = s~item
        classFlags = classInfos(classInfo~klass, classInfo~visibility)
        package = packageInfos(classInfo~package, displayer)
        classes[classFlags~left(10) quoted(classInfo~klass~id, "'")] = package
        s~next
    end
    -- Sort by class name, ignoring the 10 first characters which are class flags.
    displayer~sayCollection(classes, /*title*/.nil, /*comparator*/.CaselessColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false)


::method displayClassMethods class
    -- Display the methods of each specified class
    -- classnames is an array of StringChunk
    use strict arg classnames, inherited, displaySource, displayer, context, filteringStream
    matchers = .array~new
    do classname over classnames
        matcher = matcher(classname, /*wholestring:*/ .true, /*caseless:*/ .true, /*trace:*/ displayer~traceFilter, /*displayer:*/ displayer, /*prefix:*/ "[object filter]")
        matchers~append(matcher)
    end
    classInfos = .classInfo~collect(context) -- don't filter with matchers here, must have ALL the classes, to get the right package of inherited methods.
    classInfosSorted = .list~new
    (,
        .select .Closure~new( -
                 'expose matchers;' -
                 'use arg item, index, dataflow, pipeContext;' -
                 'matched = matchers~isEmpty;' -
                 'do matcher over matchers while \matched;' -
                 '    matched = matcher~match(index~id);' -
                 'end;' -
                 'return matched;' -
                , .context) -
      | .sort .Lambda~new('use arg item; return item~klass~id') .Lambda~new('use arg item; return item~visibility') .Lambda~new('use arg item; return item~package') -
      | .do .Closure~new('expose classInfosSorted; use arg item; classInfosSorted~append(item)', .context) -
    )~go(classInfos)
    count = 1
    do classInfo over classInfosSorted
        --say
        --displayer~sayInfo("[Info]" "["count"]" "Class" quoted(classInfo~klass~id, "'") classInfos(classInfo~klass, classInfo~visibility) packageInfos(classInfo~package, displayer))
        filteringStream~doBeforeNextLine = -
            .Closure~new( -
                'expose displayer count classInfo;' -
                'use arg /* none */ ;' -
                'say;' -
                'info =' -
                '    "[Info]"' -
                '    "["count"]"' -
                '    "Class"' -
                '    quoted(classInfo~klass~id, "''")' -
                '    classInfos(classInfo~klass, classInfo~visibility)' -
                '    packageInfos(classInfo~package, displayer);' -
                'displayer~sayInfo(info);' -
            , .context) -- This action will be executed before the first line of methods is displayed, if any (will depend on the filtering)
        methods = .relation~new
        call collectMethods
        lineCount = filteringStream~lineCount
        displayer~sayCollection(methods, /*title*/.nil, .CaselessColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*maxCount*/, -
            .Closure~new( -
                'expose displaySource;' -
                'use arg item, index;' -
                'if displaySource then do;' -
                '    method = item~getUserData("method");' -
                '    call displaySource method;' -
                'end;' -
            , .context) -
        )
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
        injectClass = .inject .Lambda~new('use arg item; return item~klass') "mem.class"
        if inherited then injectClass |= .superclasses "recursive" "once" "after" "mem.superclass"
        ( -
            injectClass -
          | .splitter[.inject .Lambda~new('use arg item; return item~instanceMethods(item)') "iterateAfter" "mem.classMethod", -
                      .inject .Lambda~new('use arg item; return item~methods(item)') "iterateAfter" "mem.instanceMethod"] -
          | .do .Closure~new( -
                 'expose displayer classInfos methods;' -
                 'use arg item, index, dataflow, pipeContext;' -
                  'package = .nil;' -
                  'if .nil <> item then package = item~package /* if method not hidden */ ;' -
                  'superclass = dataflow["superclass"] /* will be .nil if not getting inherited methods */ ;' -
                  'if .nil == superclass then superclassId = "";' -
                  'else do;' -
                  '    superclass = superclass~item;' -
                  '    superclassId = quoted(superclass~id, "''");' -
                  '    superclassInfo = classInfos[superclass];' -
                  '    if .nil == package then package = superclassInfo~package;' -
                  'end;' -
                  'class = dataflow["class"]~item;' -
                  'classId = quoted(class~id, "''");' -
                  'classInfo = classInfos[class];' -
                  'if .nil == package then package = classInfo~package;' -
                  'instanceLevel = .nil <> dataflow["instanceMethod"];' -
                  '/* Insert class flags at the begining to have the same format than displayClasses. */' -
                  '/* That allows to reuse a filter applicable to classes. */' -
                  'classFlags = classInfos(classInfo~klass, classInfo~visibility);' -
                  'methodFlags = methodInfos(item, instanceLevel);' -
                  'flags = classFlags methodFlags;' -
                  'methodDescription = flags~left(10) quoted(index, "''");' -
                  '/* remember: the same key (methodDescription) can be used several times */' -
                  '/* so don''t store the method instance on the key ! Store it on the value (classDescription). */' -
                  'classDescription = classId superclassId packageInfos(package, displayer);' -
                  'classDescription = .Extender~new(classDescription);' -
                  'classDescription~setUserData("method", item) /* to let retrieve the method (yes!) */ ;' -
                  'methods[methodDescription] = classDescription;' -
                , .context) -
        )~go(classInfo)
        return

    pipeError:
        displayer~sayError("[Error]" condition("O")~message)
        return


::method displayHelp class
    -- classnames is an array of StringChunk
    use strict arg classnames, inherited, displayer, context
    if classnames~isEmpty then do
        if inherited then do
            -- Classes having the "_description" class method (can be inherited)
            selectClass = .select .Lambda~new(' use arg item; return .nil <> item~instanceMethod("_DESCRIPTION_") ')
        end
        else do
            -- Classes having their own "_description_" class method (not an inherited one).
            selectClass = .select .Lambda~new(' use arg item; return item~instanceMethods(item)~allIndexes~hasItem("_DESCRIPTION_") ')
        end
        displayer~sayInfo("Classes with help text:")
        ( -
            .subClasses "recursive" "once" -
          | selectClass -
          | .sort -
          | .console "    " .Lambda~new('use arg item; return item~id') -
        )~go(.object)
        return
    end

    -- For each specified class, display the comment stored in the source of the method _description_, if any.
    matchers = .array~new
    do classname over classnames
        matcher = matcher(classname, /*wholestring:*/ .true, /*caseless:*/ .true, /*trace:*/ displayer~traceFilter, /*displayer:*/ displayer, /*prefix:*/ "[object filter]")
        matchers~append(matcher)
    end
    classInfos = .classInfo~collect(context, matchers)
    classInfosSorted = .list~new
    ( -
        .select .Closure~new( -
                  'expose matchers;' -
                  'use arg item, index, dataflow, pipeContext;' -
                  'matched = matchers~isEmpty;' -
                  'do matcher over matchers while \matched;' -
                  '    matched = matcher~match(index~id);' -
                  'end;' -
                  'return matched;' -
                , .context) -
      | .sort .Lambda~new('use arg item; return item~klass~id') .Lambda~new('use arg item; return item~visibility') .Lambda~new('use arg item; return item~package') -
      | .do .Closure~new('expose classInfosSorted; use arg item; classInfosSorted~append(item)', .context) -
    )~go(classInfos)
    count = 1
    do classInfo over classInfosSorted
        say
        info = -
            "[Info]" -
            "["count"]" -
            "Class" -
            classInfo~klass~id~quoted("'") -
            classInfos(classInfo~klass, classInfo~visibility) -
            packageInfos(classInfo~package, displayer)
        displayer~sayInfo(info)
        call displayClassHelp classInfo~klass
        count += 1
    end
    return

    displayClassHelp: procedure expose displayer
        use strict arg class
        description = class~instanceMethod("_description_")
        if .nil <> description then do
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
        else displayer~sayInfo("no help")
        say
        return


::method displayMethods class
    -- Display the defining classes of each specified method
    -- methodnames is an array of StringChunk
    use strict arg methodnames, displaySource, displayer, context
    matchers = .array~new
    do methodname over methodnames
        matcher = matcher(methodname, /*wholestring:*/ .true, /*caseless:*/ .true, /*trace:*/ displayer~traceFilter, /*displayer:*/ displayer, /*prefix:*/ "[object filter]")
        matchers~append(matcher)
    end

    -- Bug: With ooRexx < 5.0, the package of a method created with ::ATTRIBUTE is .nil.
    -- Bypass this bug by using the package of the class.
    classInfos = .classInfo~collect(context) -- will be used to get the package of the class

    methods = .relation~new
    ( -
        .subClasses "recursive" "once" "after" "mem.class" -
      | .splitter[.inject .Lambda~new('use arg item; return item~instanceMethods(item)') "iterateAfter" "mem.classMethod", -
                  .inject .Lambda~new('use arg item; return item~methods(item)') "iterateAfter" "mem.instanceMethod"] -
      | .select .Closure~new( -
                  'expose matchers;' -
                  'use arg item, index, dataflow, pipeContext;' -
                  'matched = matchers~isEmpty;' -
                  'do matcher over matchers while \matched;' -
                  '    matched = matcher~match(index);' -
                  'end;' -
                  'return matched;' -
                , .context) -
      | .do .Closure~new( -
              'expose displayer classInfos methods;' -
              'use arg item, index, dataflow, pipeContext;' -
              'package = .nil;' -
              'if .nil <> item then package = item~package /* if method not hidden */ ;' -
              'class = dataflow["class"]~item;' -
              'classInfo = classInfos[class];' -
              'if .nil == package then package = classInfo~package;' -
              'instanceLevel = .nil <> dataflow["instanceMethod"];' -
              'classFlags = classInfos(classInfo~klass, classInfo~visibility);' -
              'methodFlags = methodInfos(item, instanceLevel);' -
              'flags = classFlags methodFlags;' -
              'methodDescription = flags~left(10) quoted(index, "''");' -
              '/* remember: the same key (methodDescription) can be used several times */' -
              '/* so don''t store the method instance on the key ! Store it on the value (classDescription). */' -
              'classDescription = quoted(class~id, "''") packageInfos(package, displayer);' -
              'classDescription = .Extender~new(classDescription);' -
              'classDescription~setUserData("method", item) /* to let retrieve the method (yes!) */ ;' -
              'methods[methodDescription] = classDescription;' -
            , .context) -
    )~go(.object)
    displayer~sayCollection( methods, /*title*/.nil, .CaselessColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*maxCount*/, -
        .Closure~new( -
            'expose displaySource;' -
            'use arg item, index;' -
            'if displaySource then do;' -
            '    method = item~getUserData("method");' -
            '    call displaySource method;' -
            'end;' -
        , .context) -
    )


::method displayPackages class
    -- All packages that are visible from current context, including the current package (source of the pipeline).
    use strict arg packagenames, displaySource, displayer, context
    matchers = .array~new
    do packagename over packagenames
        matcher = matcher(packagename, /*wholestring:*/ .true, /*caseless:*/ .true, /*trace:*/ displayer~traceFilter, /*displayer:*/ displayer, /*prefix:*/ "[object filter]")
        matchers~append(matcher)
    end
    ( -
        .importedPackages "recursive" "once" "after" -
      | .select .Closure~new( -
                  'expose matchers;' -
                  'use arg item, index, dataflow, pipeContext;' -
                  'matched = matchers~isEmpty;' -
                  'do matcher over matchers while \matched;' -
                  '    matched = matcher~match(item~name);' -
                  'end;' -
                  'return matched;' -
                , .context) -
      | .sort .Lambda~new('use arg item; return item~name') -
      | .console .Lambda~new('use arg item; return item~name') -
      | .do .Closure~new( -
              'expose displaySource;' -
              'use arg item, index, dataflow, pipeContext;' -
              'if displaySource then do;' -
              '    call displaySource item;' -
              'end;' -
            , .context) -
    )~go(context~package)


::method displayRoutines class
    -- All or specified routines (public & private) that are visible from current context, with their package
    -- routinenames is an array of StringChunk
    use strict arg routinenames, displaySource, displayer, context
    matchers = .array~new
    do routinename over routinenames
        matcher = matcher(routinename, /*wholestring:*/ .true, /*caseless:*/ .true, /*trace:*/ displayer~traceFilter, /*displayer:*/ displayer, /*prefix:*/ "[object filter]")
        matchers~append(matcher)
    end
    routineInfos = .routineInfo~collect(context, matchers)
    -- Now build a collection where the indexes are the routine names preceded by some flags (visibility), and the items are the package filenames.
    routines = .relation~new
    s = routineInfos~supplier
    do while s~available
        routineInfo = s~item
        routineFlags = routineInfos(routineInfo~routine, routineInfo~visibility)
        routineDescription = routineFlags~left(10) quoted(routineInfo~name, "'")
        -- remember: the same key (routineDescription) can be used several times
        -- so don't store the routine instance on the key ! Store it on the value (packageDescription).
        packageDescription = packageInfos(routineInfo~package, displayer)
        packageDescription = .Extender~new(packageDescription)
        packageDescription~setUserData("routine", routineInfo~routine) -- to let retrieve the routine (yes!)
        routines[routineDescription] = packageDescription
        s~next
    end
    -- Sort by routine name, ignoring the 10 first characters which are routine flags.
    displayer~sayCollection(routines, /*title*/.nil, /*comparator*/.CaselessColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*maxCount*/, -
        .Closure~new( -
            'expose displaySource;' -
             'use arg item, index;' -
            'if displaySource then do;' -
            '    routine = item~getUserData("routine");' -
            '    call displaySource routine;' -
            'end;' -
        , .context) -
    )


::method displayFlags class
    say "Class flags"
    say "    col 1: P=Public"
    say "    col 2: M=Mixin"
    say "Method flags"
    say "    col 3: space separator"
    say "    col 4: P=Public"
    say "    col 5: C=Class"
    say "    col 6: G=Guarded"
    say "    col 7: P=Protected"
    say "Routine flags"
    say "    col 1: P=Public"


::method displayPath class
    use strict arg variablenames
    if variablenames~items == 0 then variablenames = .array~of("PATH")
    -- Don't use matchers, because there is no portable way to get the list of all environment variables.
    -- So if you specify a variable name like *path*, this name will be searched exactly as-is.
    do variablename over variablenames
        variablevalue = value(variablename,, "environment")
        do path over variablevalue~makeArray(.File~pathSeparator)
            say variablename quoted(path, "'")
        end
        say variablename "length:" variablevalue~length
    end

-- Remember: to use | in a regular expression, you must surround it by quotes
-- /"aaaa|bbbbb", /aaaa"|"bbbb
-- BUT NOT "/aaaa|bbbb" because / is not recognized a prefix of regular expression
::constant separators ": ~ @ |"


::attribute classRoutineFilters     -- array of StringChunk
::attribute defaultEntityFilters    -- array of StringChunk
::attribute methodFilters           -- array of StringChunk
::attribute packageFilters          -- array of StringChunk
::attribute query                   -- string : the first token of the whole string. For example : "classes", "methods", "packages" etc... see dispatchHelp
::attribute queryFilterArgs         -- array of StringChunk : the whole string splitted in StringChunks
::attribute streamFilters           -- array of StringChunk


::method init
    use strict arg queryFilter, routine_stringChunks
    /*
    queryFilter is a string like "QueryWord PackageFilters : ClassRoutineFilters ~ MethodFilters | StreamFilter"
    where :
        - the filters are optional. See the class Filtering for the syntax.
        - the separators between entities (package, class, method) are optional.
        - when no separator then the filters are for the default entity of the query.
        - the sequence of separators is always ":" "~" "|".
        - a separator cannot appear several times.
        - If a StreamFilter is provided, then it must be always preceded by "|" (otherwise the filter would be associated to the default entity).
    */
    self~query = .nil
    self~defaultEntityFilters = .array~new
    self~packageFilters = .array~new
    self~classRoutineFilters = .array~new
    self~methodFilters = .array~new
    self~streamFilters = .array~new

    entityLeft = .directory~new
    entityLeft[":"] = "package"
    entityLeft["~"] = "classRoutine"
    entityLeft["|"] = "" -- no impact on the entity

    entityRight = .directory~new
    entityRight[":"] = "classRoutine"
    entityRight["~"] = "method"
    entityRight["|"] = "stream"

    currentEntity = "defaultEntity"

    separatorsAlreadySeen = .set~new

    self~queryFilterArgs = routine_stringChunks~call(queryFilter, /*withInfos*/ .true, /*breakTokens*/ .Filter~operators .QueryManager~separators)
    do arg over self~queryFilterArgs
        if .nil == self~query then self~query = arg -- the first arg is the query
        else do
            entity = entityLeft[arg~string]
            if .nil <> entity then do
                separator = arg~string
                if separatorsAlreadySeen~hasIndex(separator) then raise syntax 93.900 array("Separator" separator "used more than once")
                separatorsAlreadySeen~put(separator)
                if currentEntity == "defaultEntity" then do
                    if entity <> "" then do
                        self~send(entity"Filters=", self~defaultEntityFilters) -- assign the default entity filters to the entity on the left of the separator
                        self~defaultEntityFilters = .array~new -- no more default entity filters
                    end
                end
                currentEntity = entityRight[separator] -- the next filters will be associated to the entity on the right of the separator
            end
            else self~send(currentEntity"Filters") ~ append(arg)
        end
    end


::method dump
    use strict arg displayer

    displayer~sayInfo
    displayer~sayInfo("query =" self~query)

    displayer~sayInfo("defaultEntityFilters =")
    displayer~sayCollection(self~defaultEntityFilters)

    displayer~sayInfo("packageFilters =")
    displayer~sayCollection(self~packageFilters)

    displayer~sayInfo("classRoutineFilters =")
    displayer~sayCollection(self~classRoutineFilters)

    displayer~sayInfo("methodFilters =")
    displayer~sayCollection(self~methodFilters)

    displayer~sayInfo("streamFilters =")
    displayer~sayCollection(self~streamFilters)


-------------------------------------------------------------------------------
-- Helpers for QueryManager
-------------------------------------------------------------------------------

::routine methodInfos public
    use strict arg method, instanceLevel
    if .nil == method then return "----" -- Hidden method, see documentation of .class~methods
    if instanceLevel then level = "."; else level = "C" -- Remember: "I" not displayed because of "PIG"
    if method~isGuarded then guarded = "G"; else guarded = "."
    if method~isPrivate then visibility = "."; else visibility = "P" -- Remember: "p" vs "P" not readable
    if method~isProtected then protected = "P"; else protected = "."
    return visibility || level || guarded || protected


::routine methodPackageInfos public
    -- Not used because
    -- Bug: With ooRexx < 5.0, the package of a method created with ::ATTRIBUTE is .nil.
    use strict arg method, displayer
    if .nil == method then return "UNDEFINED"
    return packageInfos(method~package, displayer)


::routine packageInfos public
    -- With ooRexx < 5.0
    --     The package of the predefined methods is .nil.
    --     It's not possible to get directly the package of a class.
    -- With ooRexx >= 5.0
    --     The package of a class created dynamically is still .nil.
    use strict arg package, displayer
    if .nil == package then return "()"
    packageName = package~name -- can be a full path
    width = displayer~maxPackageNameWidth
    if \ width~datatype("W") then width = 0
    if width > 0 then do
        -- return the full path, truncated
        if width < 3 then width = 3
        if packageName~length > width then do
            packageName = "..." || packageName~right(width - 3)
        end
    end
    else if width == 0 then do
        -- return the filename only, not the full path. Not truncated.

        -- With ooRexx4.2, .File~new does not support an empty string, and the
        -- error message is cryptic:
        -- Incorrect position argument specified; found "0"
        if packageName \== "" then packageName = .File~new(packageName)~name
    end
    else do -- width < 0
        -- return a path containing at most abs(width) path separators
        pos = packageName~length + 1
        separator = .File~separator
        do abs(width) + 1 while pos > 1
            pos = packageName~lastPos(separator, pos - 1)
        end
        if pos > 1 then do
            packageName = "..." || packageName~substr(pos)
        end
    end
    return "("packageName")" || d2c(0) package~name -- package full path used for filtering, will be removed from the output


::routine classInfos public
    use strict arg class, visibility
    if visibility == "private" then visibility = "."; else visibility = "P" -- Remember: "p" vs "P" not readable
    if class~queryMixinClass then mixin = "M"; else mixin = "."
    return visibility || mixin


::routine routineInfos public
    use strict arg routine, visibility
    if visibility == "private" then visibility = "."; else visibility = "P" -- Remember: "p" vs "P" not readable
    return visibility


::routine displaySource private
    use arg object
    if .nil == object then return
    index = 1
    do item over object~source
        say " >" index~right(4,0) item
        index += 1
    end


::routine quoted private
    use strict arg string, quote='"'
    return quote || string~changestr(quote, quote~copies(2)) || quote


::routine cleanup
    -- Everything from \0 is deleted
    use strict arg line
    -- if line~pos("[cleanup]") == 1 then return line -- startsWith not supported by ooRexx 4.2
    -- say "[cleanup]" line

    marker = d2c(0)
    pos = line~pos(marker)
    if pos \== 0 then line = line~left(pos - 1)
    else do
        marker = "[00]"
        pos = line~pos(marker)
        if pos \== 0 then line = line~left(pos - 1)
    end
    return line


-------------------------------------------------------------------------------
::class "Filter"
-------------------------------------------------------------------------------

::constant StrictDifferent      1
::constant StrictEqual          2
::constant CaselessDifferent    3
::constant CaselessEqual        4
::constant Operators            "= <> == \=="

::method parse class
    -- "=something"     not recognized as filter operator, because is quoted
    -- =something       recognized as filter operator
    -- arg is an StringChunk
    use strict arg arg
    if operator("\==", self~StrictDifferent) then return filter
    if operator("==", self~StrictEqual) then return filter
    if operator("<>", self~CaselessDifferent) then return filter
    if operator("=", self~CaselessEqual) then return filter
    return self~new(0, arg) -- no operator

    operator: procedure expose arg filter self
        use strict arg operatorString, operatorCode
        left = arg~left(operatorString~length)
        if left~string <> operatorString then return .false
        if left~quotedFlags~countStr("1") <> 0 then return .false -- at least one char is quoted
        argument = arg~substr(operatorString~length + 1)
        filter = self~new(operatorCode, argument)
        return .true


::attribute operator
::attribute argument

::method init
    expose operator argument
    use strict arg operator, argument


-------------------------------------------------------------------------------
::class "Filtering" private
-------------------------------------------------------------------------------

::method firstFilterIndex class
    -- args is an array of StringChunk
    use strict arg args
    index = 0
    do arg over args
        index += 1
        filter = .Filter~parse(arg)
        if filter~operator <> 0 then return index -- This is the first filter operator. Returns its index.
    end
    return 0


::attribute strictInclude
::attribute strictExclude
::attribute caselessInclude
::attribute caselessExclude


::method init
    -- Examples of valid filters:
    -- ""                                 -- no filter
    -- "value"                            -- caseless equals value
    -- "=value"                           -- caseless equals value
    -- "== value"                         -- casesensitive equals value
    -- "<> value1 value2 = value3 value4" -- (<> value1 AND <> value2) AND (= value3 OR = value4)
    -- A value can be a string surrounded by quotes

    -- filters is an array of StringChunk
    use strict arg filters
    self~strictExclude = .array~new
    self~strictInclude = .array~new
    self~caselessExclude = .array~new
    self~caselessInclude = .array~new
    currentOperator = .Filter~CaselessEqual
    do filter over filters
        filter = .Filter~parse(filter)
        if filter~operator <> 0 then currentOperator = filter~operator
        if filter~argument~string <> "" then do
            -- Remember: don't pass trace: from here, it's too early
            -- The trace will be done by .Filtering~traceFilter
            matcherCaselessInclude = matcher(filter~argument, /*wholestring:*/ .false, /*caseless:*/ .true)
            matcherStrictInclude = matcher(filter~argument, /*wholestring:*/ .false, /*caseless:*/ .false)

            if currentOperator == .filter~StrictDifferent then self~strictExclude~append(matcherStrictInclude) -- will negate the result
            else if currentOperator == .filter~StrictEqual then self~strictInclude~append(matcherStrictInclude)
            else if currentOperator == .filter~CaselessDifferent then self~caselessExclude~append(matcherCaselessInclude) -- will negate the result
            else if currentOperator == .filter~CaselessEqual then self~caselessInclude~append(matcherCaselessInclude)
        end
    end


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
    use strict arg string

    -- Empty lines are not filtered
    if string == "" then return .true

    -- Info lines are not filtered
    if string~abbrev("[Info]") then return .true

    do matcher over self~strictExclude
        if matcher~match(string) then return .false
    end
    do matcher over self~caselessExclude
        if matcher~match(string) then return .false
    end

    if self~strictInclude~size == 0 & self~caselessInclude~size == 0 then return .true

    do matcher over self~strictInclude
        if matcher~match(string) then return .true
    end
    do matcher over self~caselessInclude
        if matcher~match(string) then return .true
    end
    return .false


-------------------------------------------------------------------------------
::class "FilteringStream" public subclass "Filtering"
-------------------------------------------------------------------------------

::attribute interceptedDestination
::attribute lineCount
::attribute stringbuffer
::attribute doBeforeNextLine -- doer triggered once, only if at least one line is displayed


::method init
    -- filters is an array of StringChunk
    use strict arg destination, filters
    self~init:super(filters)
    self~interceptedDestination = destination
    self~lineCount = 0
    self~stringbuffer = .mutablebuffer~new
    self~doBeforeNextLine = .nil


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
        if .nil <> self~doBeforeNextLine then do
            action = self~doBeforeNextLine
            self~doBeforeNextLine = .nil -- reset before call to avoid infinite recursion
            action~call()
        end
        line = cleanup(line)
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
        if .nil <> self~doBeforeNextLine then do
            action = self~doBeforeNextLine
            self~doBeforeNextLine = .nil -- reset before call to avoid infinite recursion
            action~call()
        end
        line = cleanup(line)
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
        line = cleanup(line)
        self~interceptedDestination~charOut(line)
        forward to (self~interceptedDestination)
    end
    return 0
