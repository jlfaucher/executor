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
::requires "extension/extensions.cls" -- first need: ~quoted
::requires "extension/stringChunk.cls"
::requires "extension/stringChunkExtended.cls"

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
        'RexxBlock',            -- extension
        'RexxContext',
        'RexxQueue',
        'RexxText',             -- extension
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
        'Unicode',              -- extension
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
    -- Remember (again): this implementation works with ooRexx 4.2 where classes have no "package" method.
    .object~pipe(,
        .subclasses "recursive" "once" "after",
      | .do { expose publicClasses privateClasses
              if \publicClasses~hasIndex(item) & \privateClasses~hasIndex(item) then do
                  package = .nil
                  if item~hasMethod("package") then package = item~package
                  if .nil == package then do
                      -- No package, can't guess if the class is public or private.
                      -- Assume it's public.
                      publicClasses[item] = package
                  end
                  else do
                      -- I have a problem with Executor:
                      -- The publicClasses directory of the Rexx package is empty.
                      -- In this case, assume that all the Rexx classes are public.
                      if package~publicClasses~items == 0 | package~publicClasses~hasEntry(item~id) then do -- yes! hasEntry, not hasIndex which needs uppercases
                          publicClasses[item] = package
                      end
                      else do
                          privateClasses[item] = package
                      end
                  end
              end
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
    if .nil == package, self~class~isPredefinedClass(klass~id) then package = self~class~REXXPackage


-------------------------------------------------------------------------------
::class "RoutineInfo" public
-------------------------------------------------------------------------------

::method collect class
    use strict arg context, matchers=(.array~new)
    publicRoutines = .relation~new
    context~package~pipe(,
        .importedPackages "recursive" "once" "after" "mem.package",
      | .inject {item~publicRoutines} "iterateAfter",
      | .do { expose publicRoutines
              publicRoutines[item] = .routineInfo~new(index, item, dataflow["package"]~item, "public")
            },
    )
    privateRoutines = .relation~new
    context~package~pipe(,
        .importedPackages "recursive" "once" "after" "mem.package",
      | .inject {item~routines} "iterateAfter",
      | .do { expose publicRoutines privateRoutines
              if \publicRoutines~hasIndex(item) then privateRoutines[item] = .routineInfo~new(index, item, dataflow["package"]~item, "private")
            },
    )
    -- Now build a collection of routineInfo.
    routineInfos = .table~new -- index is a routine, item is a routineInfo
    s = publicRoutines~supplier
    do while s~available
        matched = matchers~isEmpty
        do matcher over matchers while \matched
            matched = matcher~(s~item~name)
        end
        if matched then routineInfos[s~index] = s~item
        s~next
    end
    s = privateRoutines~supplier
    do while s~available
        matched = matchers~isEmpty
        do matcher over matchers while \matched
            matched = matcher~(s~item~name)
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
method prettyString
attribute traceFilter
*/


::method displayClasses class
    -- All or specified classes (public & private) that are visible from current context, with their package
    -- classnames is an array of StringChunk
    use strict arg classnames, verbose, maxPackageNameWidth, displayer, context
    matchers = .array~new
    do classname over classnames
        matcher = classname~matcher(wholestring: .true, caseless: .true, trace: displayer~traceFilter, displayer: displayer, prefix: "[object filter]")
        matchers~append(matcher)
    end
    classInfos = .classInfo~collect(context, matchers)
    -- Now build a collection where the indexes are the class names preceded by some flags (mixing, private), and the items are the package filenames.
    classes = .relation~new
    s = classInfos~supplier
    do while s~available
        classInfo = s~item
        classFlags = classInfos(classInfo~klass, classInfo~visibility)
        classMetadata = classMetadata(classInfo~klass~id, classInfo~package)
        package = packageInfos(classInfo~package, maxPackageNameWidth)
        classes[classFlags~left(10) classInfo~klass~id~quoted("'")] = package || classMetadata
        s~next
    end
    -- Sort by class name, ignoring the 10 first characters which are class flags.
    displayer~sayCollection(classes, /*title*/.nil, /*comparator*/.CaselessColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*unescapedCharacters*/.endOfLine)


::method displayClassMethods class
    -- Display the methods of each specified class
    -- classnames is an array of StringChunk
    use strict arg classnames, inherited, displaySource, verbose, maxPackageNameWidth, displayer, context, filteringStream
    matchers = .array~new
    do classname over classnames
        matcher = classname~matcher(wholestring: .true, caseless: .true, trace: displayer~traceFilter, displayer: displayer, prefix: "[object filter]")
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
        classMetadata = classMetadata(classInfo~klass~id, classInfo~package)
        filteringStream~doBeforeNextLine = {
            expose maxPackageNameWidth displayer count classInfo classMetadata
            say
            info = -
                "[Info]" -
                "["count"]" -
                "Class" -
                classInfo~klass~id~quoted("'") -
                classInfos(classInfo~klass, classInfo~visibility) -
                packageInfos(classInfo~package, maxPackageNameWidth)
            displayer~sayInfo(info || classMetadata)
        } -- This action will be executed before the first line of methods is displayed, if any (will depend on the filtering)
        methods = .relation~new
        call collectMethods
        lineCount = filteringStream~lineCount
        displayer~sayCollection(methods, /*title*/.nil, .CaselessColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*unescapedCharacters*/.endOfLine, /*maxCount*/){
            expose displaySource
            if displaySource then do
                method = item~getUserData("method")
                if .nil <> method then method~source~each{say " >" index~right(4,0) item}
            end
        }
        filteringStream~doBeforeNextLine = .nil
        if filteringStream~lineCount <> lineCount then do
            info = -
                "[Info]" -
                "["count"]" -
                "Class" -
                "'"classInfo~klass~id"' has" -
                displayer~singularPlural(methods~items, "method", "methods")
            displayer~sayInfo(info || classMetadata)
        end
        count += 1
    end
    return

    collectMethods:
        signal on syntax name pipeError -- TEMPORARY : some classes don't understand message ~pipe
        -- Bug: With ooRexx < 5.0, the package of a method created with ::ATTRIBUTE is .nil.
        -- Bypass this bug by using the package of the class.
        injectClass = .inject {item~klass} "mem.class"
        if inherited then injectClass |= .superclasses "recursive" "once" "after" "mem.superclass"
        classInfo~pipe(,
            injectClass,
          | .splitter[.inject {item~instanceMethods(item)} "iterateAfter" "mem.classMethod",,
                      .inject {item~methods(item)} "iterateAfter" "mem.instanceMethod"],
          | .do { expose maxPackageNameWidth classInfos classMetadata methods
                  package = .nil
                  if .nil <> item then package = item~package -- if method not hidden
                  superclass = dataflow["superclass"] -- will be .nil if not getting inherited methods
                  if .nil == superclass then superclassId = ""
                  else do
                      superclass = superclass~item
                      superclassId = superclass~id~quoted("'")
                      superclassInfo = classInfos[superclass]
                      if .nil == package then package = superclassInfo~package
                  end
                  class = dataflow["class"]~item
                  classId = class~id~quoted("'")
                  classInfo = classInfos[class]
                  if .nil == package then package = classInfo~package
                  instanceLevel = .nil <> dataflow["instanceMethod"]
                  -- Insert class flags at the begining to have the same format than displayClasses.
                  -- That allows to reuse a filter applicable to classes.
                  classFlags = classInfos(classInfo~klass, classInfo~visibility)
                  methodFlags = methodInfos(item, instanceLevel)
                  flags = classFlags methodFlags
                  methodDescription = flags~left(10) index~quoted("'")
                  classDescription = " "~join(classId, superclassId, packageInfos(package, maxPackageNameWidth))
                  -- A method is associated with two packages:
                  -- - its own package (MP).
                  -- - the package of the current class (CCP), where the method is defined or inherited.
                  -- MP differs from CCP when the method is inherited.
                  methodMetadata = methodMetadata(index, package)
                  description = classDescription || classMetadata || methodMetadata
                  -- remember: the same key (methodDescription) can be used several times
                  -- so don't store the method instance on the key ! Store it on the value (description).
                  description~setUserData("method", item) -- to let retrieve the method (yes!)
                  methods[methodDescription] = description
                },
        )
        return

    pipeError:
        displayer~sayError("[Error]" condition("O")~message)
        return


::method displayHelp class
    -- classnames is an array of StringChunk
    use strict arg classnames, inherited, verbose, maxPackageNameWidth, displayer, context
    if classnames~isEmpty then do
        if inherited then do
            -- Classes having the "_description" class method (can be inherited)
            selectClass = .select { .nil <> item~instanceMethod("_DESCRIPTION_") }
        end
        else do
            -- Classes having their own "_description_" class method (not an inherited one).
            selectClass = .select { item~instanceMethods(item)~allIndexes~hasItem("_DESCRIPTION_") }
        end
        displayer~sayInfo("Classes with help text:")
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
        matcher = classname~matcher(wholestring: .true, caseless: .true, trace: displayer~traceFilter, displayer: displayer, prefix: "[object filter]")
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
        info = -
            "[Info]" -
            "["count"]" -
            "Class" -
            classInfo~klass~id~quoted("'") -
            classInfos(classInfo~klass, classInfo~visibility) -
            packageInfos(classInfo~package, maxPackageNameWidth)
        classMetadata = classMetadata(classInfo~klass~id, classInfo~package)
        displayer~sayInfo(info || classMetadata)
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
    use strict arg methodnames, displaySource, verbose, maxPackageNameWidth, displayer, context
    matchers = .array~new
    do methodname over methodnames
        matcher = methodname~matcher(wholestring: .true, caseless: .true, trace: displayer~traceFilter, displayer: displayer, prefix:"[object filter]")
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
      | .do { expose maxPackageNameWidth classInfos methods
              package = .nil
              if .nil <> item then package = item~package -- if method not hidden
              class = dataflow["class"]~item
              classInfo = classInfos[class]
              if .nil == package then package = classInfo~package
              instanceLevel = .nil <> dataflow["instanceMethod"]
              classFlags = classInfos(classInfo~klass, classInfo~visibility)
              methodFlags = methodInfos(item, instanceLevel)
              flags = classFlags methodFlags
              methodDescription = flags~left(10) index~quoted("'")
              classDescription = class~id~quoted("'") packageInfos(package, maxPackageNameWidth)
              classMetadata = classMetadata(class~id, classInfo~package)
              methodMetadata = methodMetadata(index, package)
              description = classDescription || classMetadata || methodMetadata
              -- remember: the same key (methodDescription) can be used several times
              -- so don't store the method instance on the key ! Store it on the value (description).
              description~setUserData("method", item) -- to let retrieve the method (yes!)
              methods[methodDescription] = description
            },
    )
    displayer~sayCollection( methods, /*title*/.nil, .CaselessColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*unescapedCharacters*/.endOfLine, /*maxCount*/){
        expose displaySource
        if displaySource then do
            method = item~getUserData("method")
            if .nil <> method then method~source~each{say " >" index~right(4,0) item}
        end
    }


::method displayPackages class
    -- All packages that are visible from current context, including the current package (source of the pipeline).
    use strict arg packagenames, displaySource, verbose, maxPackageNameWidth, displayer, context
    matchers = .array~new
    do packagename over packagenames
        matcher = packagename~matcher(wholestring: .true, caseless: .true, trace: displayer~traceFilter, displayer: displayer, prefix: "[object filter]")
        matchers~append(matcher)
    end
    context~package~pipe(,
        .importedPackages "recursive" "once" "after",
      | .select { expose matchers
                  matched = matchers~isEmpty
                  do matcher over matchers while \matched
                      matched = matcher~(item~name)
                  end
                  matched
                } "mem.package",
      | .inject {expose maxPackageNameWidth; packageInfos(item, maxPackageNameWidth) || packageMetadata("P", item)},
      | .sort {item},
      | .console {item},
      | .do { expose displaySource
              if displaySource then do
                dataflow["package"]~item~source~each{say " >" index~right(4,0) item}
              end
            },
    )


::method displayRoutines class
    -- All or specified routines (public & private) that are visible from current context, with their package
    -- routinenames is an array of StringChunk
    use strict arg routinenames, displaySource, verbose, maxPackageNameWidth, displayer, context
    matchers = .array~new
    do routinename over routinenames
        matcher = routinename~matcher(wholestring: .true, caseless: .true, trace: displayer~traceFilter, displayer: displayer, prefix: "[object filter]")
        matchers~append(matcher)
    end
    routineInfos = .routineInfo~collect(context, matchers)
    -- Now build a collection where the indexes are the routine names preceded by some flags (visibility), and the items are the package filenames.
    routines = .relation~new
    s = routineInfos~supplier
    do while s~available
        routineInfo = s~item
        routineFlags = routineInfos(routineInfo~routine, routineInfo~visibility)
        routineDescription = routineFlags~left(10) routineInfo~name~quoted("'")
        packageDescription = packageInfos(routineInfo~package, maxPackageNameWidth)
        routineMetadata = routineMetadata(routineInfo~name, routineInfo~package)
        description = packageDescription || routineMetadata
        -- remember: the same key (routineDescription) can be used several times
        -- so don't store the routine instance on the key ! Store it on the value (description).
        description~setUserData("routine", routineInfo~routine) -- to let retrieve the routine (yes!)
        routines[routineDescription] = description
        s~next
    end
    -- Sort by routine name, ignoring the 10 first characters which are routine flags.
    displayer~sayCollection(routines, /*title*/.nil, /*comparator*/.CaselessColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*unescapedCharacters*/.endOfLine, /*maxCount*/){
        expose displaySource
        if displaySource then do
            routine = item~getUserData("routine")
            if .nil \== routine then routine~source~each{say " >" index~right(4,0) item}
        end
    }


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


::method displayMetadataSyntax class
    say "Metadata is displayed in verbose mode."
    say "Metadata is on the same line as data, separated with .endOfLine."
    say ""
    say "Metadata syntax"
    say "    <T> indicates the type of metadata:"
    say "        C = class"
    say "        M = method"
    say "        P = package"
    say "        R = routine"
    say ""
    say "    The letter(s) after the type indicates the property:"
    say "        <T>PD: package directory"
    say "        <T>PF: package filename"
    say "        <T>N:  name (PN is not provided because it would be redundant with PPN)"
    say "        <T>PN: package name (can be a full path)"
    say ""
    say "    Examples of metadata:"
    say "        CPD     .../CPD(packages)/CPD(encoding)/CPF(unicode.cls)"
    say "        CPF     .../CPD(packages)/CPD(encoding)/CPF(unicode.cls)"
    say "        CN      CN(Unicode)"
    say "        CPN     CPN(.../packages/encoding/unicode.cls)"
    say "        MPD     .../MPD(packages)/MPD(encoding)/MPF(unicode.cls)"
    say "        MPF     .../MPD(packages)/MPD(encoding)/MPF(unicode.cls)"
    say "        MN      MN(UTF8PROC_TRANSFORM)"
    say "        MPN     MPN(.../packages/encoding/unicode.cls)"
    say "        PPD     .../PPD(packages)/PPD(encoding)/PPF(unicode.cls)"
    say "        PPF     .../PPD(packages)/PPD(encoding)/PPF(unicode.cls)"
    say "        PPN     PPN(.../packages/encoding/unicode.cls)"
    say "        RPD     .../RPD(packages)/RpD(encoding)/RPF(unicode.cls)"
    say "        RPF     .../RPD(packages)/RPD(encoding)/RPF(unicode.cls)"
    say "        RN      RN(ICU4C_U_CHARNAME)"
    say "        RPN     RPN(.../packages/encoding/unicode.cls)"


::method displayPath class
    use strict arg variablenames
    if variablenames~items == 0 then variablenames = .array~of("PATH")
    -- Don't use matchers, because there is no portable way to get the list of all environment variables.
    -- So if you specify a variable name like *path*, this name will be searched exactly as-is.
    do variablename over variablenames
        variablevalue = value(variablename,, "environment")
        do path over variablevalue~makeArray(.File~pathSeparator)
            say variablename path~quoted("'")
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

    displayer~sayInfo("queryFilterArgs =")
    displayer~sayCollection(self~queryFilterArgs)

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

::routine methodInfos private
    use strict arg method, instanceLevel
    if .nil == method then return "----" -- Hidden method, see documentation of .class~methods
    if instanceLevel then level = "."; else level = "C" -- Remember: "I" not displayed because of "PIG"
    if method~isGuarded then guarded = "G"; else guarded = "."
    if method~isPrivate then visibility = "."; else visibility = "P" -- Remember: "p" vs "P" not readable
    if method~isProtected then protected = "P"; else protected = "."
    return visibility || level || guarded || protected


::routine methodPackageInfos private
    -- Not used because
    -- Bug: With ooRexx < 5.0, the package of a method created with ::ATTRIBUTE is .nil.
    use strict arg method, maxPackageNameWidth
    if .nil == method then return "UNDEFINED"
    return packageInfos(method~package, maxPackageNameWidth)


::routine packageInfos private
    -- With ooRexx < 5.0
    --     The package of the predefined methods is .nil.
    --     It's not possible to get directly the package of a class.
    -- With ooRexx >= 5.0
    --     The package of a class created dynamically is still .nil.
    use strict arg package, maxPackageNameWidth
    if .nil == package then return "()"

    packageName = package~name -- can be a full path
    width = maxPackageNameWidth~string
    if \ datatype(width, "W") then width = 0
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

    packageInfo = "("packageName")"
    return packageInfo


::routine classInfos private
    use strict arg class, visibility
    if visibility == "private" then visibility = "."; else visibility = "P" -- Remember: "p" vs "P" not readable
    if class~queryMixinClass then mixin = "M"; else mixin = "."
    return visibility || mixin


::routine routineInfos private
    use strict arg routine, visibility
    if visibility == "private" then visibility = "."; else visibility = "P" -- Remember: "p" vs "P" not readable
    return visibility


-------------------------------------------------------------------------------
-- Helpers for metadata
-------------------------------------------------------------------------------

/*
<T> indicates the type of metadata:
    C = class
    M = method
    P = package
    R = routine

The letter(s) after the type indicates the property:
    <T>PD: package directory
    <T>PF: package filename
    <T>N:  name (PN is not provided because it would be redundant with PPN)
    <T>PN: package name (can be a full path)

Examples:
    CPD     .../CPD(packages)/CPD(encoding)/CPF(unicode.cls)
    CPF     .../CPD(packages)/CPD(encoding)/CPF(unicode.cls)
    CN      CN(Unicode)
    CPN     CPN(.../packages/encoding/unicode.cls)
    MPD     .../MPD(packages)/MPD(encoding)/MPF(unicode.cls)
    MPF     .../MPD(packages)/MPD(encoding)/MPF(unicode.cls)
    MN      MN(UTF8PROC_TRANSFORM)
    MPN     MPN(.../packages/encoding/unicode.cls)
    PPD     .../PPD(packages)/PPD(encoding)/PPF(unicode.cls)
    PPF     .../PPD(packages)/PPD(encoding)/PPF(unicode.cls)
    PPN     PPN(.../packages/encoding/unicode.cls)
    RPD     .../RPD(packages)/RpD(encoding)/RPF(unicode.cls)
    RPF     .../RPD(packages)/RPD(encoding)/RpF(unicode.cls)
    RN      RN(ICU4C_U_CHARNAME)
    RPN     RPN(.../packages/encoding/unicode.cls)
*/

::routine pathMetadata private
    /*
    Each path component (directory or filename) is wrapped as:
        <T><PT>D(name) or <T><PT>F(name)
    where <PT> is the path type (<PT> = "P" for a package path).
    This format allows simple pattern matching without regular expressions.

    Example:
        Given the package
            .../packages/encoding/unicode.cls

        Package path metadata (<PT> = "P"):
            Class defined in this package (<T> = "C"):
                .../CPD(packages)/CPD(encoding)/CPF(unicode.cls)

            Method defined in this package (<T> = "M"):
                .../MPD(packages)/MPD(encoding)/MPF(unicode.cls)

            Method inherited from the Object class:
                MPF(REXX)

            Routine defined in this package (<T> = "R"):
                .../RPD(packages)/RPD(encoding)/RPF(unicode.cls)
    */
    use strict arg type, pathType, path

    separator = .File~separator
    buffer = .MutableBuffer~new
    pos = 0
    if separator == "\", path~matchChar(2, ":") then do -- same test as .File implementation
        -- Windows drive letter
        buffer~append(path~left(2))
        pos = 2 -- yes, not 3
    end
    letter = "D"
    do forever
        pos += 1
        if pos > path~length then leave
        nextpos = path~pos(separator, pos)
        if nextpos == 0 then do
            nextpos = path~length + 1
            letter = "F"
        end
        -- Keep it compatible with ooRexx 4.2: only one argument per append
        if nextpos == pos then do
            buffer~append(path~substr(pos, 1))
        end
        else do
            buffer~append(type)
            buffer~append(pathType)
            buffer~append(letter)
            buffer~append("(")
            buffer~append(path~substr(pos, nextpos - pos))
            buffer~append(")")
            if nextpos > path~length then leave
            buffer~append("/") -- yes, always "/", not separator, to make queries behave consistently across platforms.
            pos = nextpos
        end
    end
    return buffer~string


::routine packageMetadata private
    use strict arg type, package
    if .nil == package then return type"()"

    marker = .endofline
    indent = "    "

    packageName = package~name -- can be a full path
    -- Normalize path separators so queries behave consistently across platforms
    packageName = package~name~changeStr("\", "/")
    metadata   = ""
    -- metadata ||= marker || indent || "PN("packageName")" -- redundant with PPN
    metadata ||= marker || indent || type"PN("packageName")"
    metadata ||= marker || indent || pathMetadata(type, "P", packageName)
    return metadata


::routine classMetadata private
    use strict arg className, package

    marker = .endofline
    indent = "    "

    metadata   = packageMetadata("C", package)
    metadata ||= marker || indent || "CN("className")"
    return metadata


::routine methodMetadata private
    use strict arg methodName, package

    marker = .endofline
    indent = "    "

    metadata   = packageMetadata("M", package)
    metadata ||= marker || indent || "MN("methodName")"
    return metadata


::routine routineMetadata private
    use strict arg routineName, package

    marker = .endofline
    indent = "    "

    metadata   = packageMetadata("R", package)
    metadata ||= marker || indent || "RN("routineName")"
    return metadata


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


::attribute displayer get
::attribute verbose
::attribute previousLineWasDisplayed
::attribute strictInclude
::attribute strictExclude
::attribute caselessInclude
::attribute caselessExclude
::attribute strictIncludeMetadata
::attribute strictExcludeMetadata
::attribute caselessIncludeMetadata
::attribute caselessExcludeMetadata


::method init
    -- Examples of valid filters:
    -- ""                                 -- no filter
    -- "value"                            -- caseless equals value
    -- "=value"                           -- caseless equals value
    -- "== value"                         -- casesensitive equals value
    -- "<> value1 value2 = value3 value4" -- (<> value1 AND <> value2) AND (= value3 OR = value4)
    -- A value can be a string surrounded by quotes

    expose displayer verbose

    -- this attribute is used to display a line only if the previous line was displayed.
    self~previousLineWasDisplayed = .false

    -- filters is an array of StringChunk
    use strict arg filters, displayer, verbose

    self~strictExclude = .array~new
    self~strictInclude = .array~new
    self~caselessExclude = .array~new
    self~caselessInclude = .array~new

    self~strictExcludeMetadata = .array~new
    self~strictIncludeMetadata = .array~new
    self~caselessExcludeMetadata = .array~new
    self~caselessIncludeMetadata = .array~new

    currentOperator = .Filter~CaselessEqual
    do filter over filters
        filter = .Filter~parse(filter)
        if filter~operator <> 0 then currentOperator = filter~operator
        if filter~argument~string <> "" then do
            -- Remember: don't pass trace: from here, it's too early
            -- The trace will be done by .Filtering~traceFilter
            matcherCaselessInclude = filter~argument~matcher(wholestring: .false, caseless: .true)
            matcherStrictInclude = filter~argument~matcher(wholestring: .false, caseless: .false)

            if filter~argument~containerStartChar == "`" then do
                if currentOperator == .filter~StrictDifferent then self~strictExcludeMetadata~append(matcherStrictInclude) -- will negate the result
                else if currentOperator == .filter~StrictEqual then self~strictIncludeMetadata~append(matcherStrictInclude)
                else if currentOperator == .filter~CaselessDifferent then self~caselessExcludeMetadata~append(matcherCaselessInclude) -- will negate the result
                else if currentOperator == .filter~CaselessEqual then self~caselessIncludeMetadata~append(matcherCaselessInclude)
            end
            else do
                if currentOperator == .filter~StrictDifferent then self~strictExclude~append(matcherStrictInclude) -- will negate the result
                else if currentOperator == .filter~StrictEqual then self~strictInclude~append(matcherStrictInclude)
                else if currentOperator == .filter~CaselessDifferent then self~caselessExclude~append(matcherCaselessInclude) -- will negate the result
                else if currentOperator == .filter~CaselessEqual then self~caselessInclude~append(matcherCaselessInclude)
            end
        end
    end


::method traceFilter
    expose displayer
    use strict arg -- none

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

    prefix = "[line metadata filter]"
    first = .true
    do matcher over self~strictIncludeMetadata
        if \first then displayer~sayTrace(prefix "OR")
        call traceMatcher matcher, displayer, prefix
        first = .false
    end
    do matcher over self~caselessIncludeMetadata
        if \first then displayer~sayTrace(prefix "OR")
        call traceMatcher matcher, displayer, prefix
        first = .false
    end
    do matcher over self~strictExcludeMetadata
        if first then displayer~sayTrace(prefix "NOT")
        else displayer~sayTrace(prefix "AND NOT")
        call traceMatcher matcher, displayer, prefix
        first = .false
    end
    do matcher over self~caselessExcludeMetadata
        if first then displayer~sayTrace(prefix "NOT")
        else displayer~sayTrace(prefix "AND NOT")
        call traceMatcher matcher, displayer, prefix
        first = .false
    end


::method selectLine
    use strict arg data, metadata

    -- Empty lines are not filtered
    if data == "" then return .true

    -- Info lines are not filtered
    if data~abbrev("[Info]") then return .true

    -- A source line is displayed only if the previous line was displayed
    -- " > 0001"
    if data~length >= 7 & data~left(3) == " > " & data~substr(4, 4, "x")~datatype("w") then return self~previousLineWasDisplayed

    do matcher over self~strictExclude
        if matcher~(data) then return .false
    end
    do matcher over self~strictExcludeMetadata
        if matcher~(metadata) then return .false
    end
    do matcher over self~caselessExclude
        if matcher~(data) then return .false
    end
    do matcher over self~caselessExcludeMetadata
        if matcher~(metadata) then return .false
    end

    if    self~strictInclude~size == 0 -
        & self~caselessInclude~size == 0 -
        & self~strictIncludeMetadata~size == 0 -
        & self~caselessIncludeMetadata~size == 0 -
    then return .true

    do matcher over self~strictInclude
        if matcher~(data) then return .true
    end
    do matcher over self~strictIncludeMetadata
        if matcher~(metadata) then return .true
    end
    do matcher over self~caselessInclude
        if matcher~(data) then return .true
    end
    do matcher over self~caselessIncludeMetadata
        if matcher~(metadata) then return .true
    end

    return .false


::method select
    use strict arg data, metadata

    selected = self~selectLine(data, metadata)
    self~previousLineWasDisplayed = selected
    return selected


-------------------------------------------------------------------------------
::class "FilteringStream" public subclass "Filtering"
-------------------------------------------------------------------------------

::attribute interceptedDestination
::attribute lineCount
::attribute stringbuffer
::attribute doBeforeNextLine -- doer triggered once, only if at least one line is displayed


::method init
    expose marker ppMarker -- used to split the line in two parts: visible and additional

    -- filters is an array of StringChunk
    use strict arg destination, filters, displayer, verbose=.false

    self~init:super(filters, displayer, verbose)
    marker = .endofline
    ppMarker = self~displayer~prettyString(marker, /*surroundByQuotes:*/ .false)
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
    dataMetadata = self~splitDataMetadata(line)
    data = dataMetadata[1]
    metadata = dataMetadata[2]
    if self~select(data, metadata) then do
        self~lineCount += 1
        if .nil <> self~doBeforeNextLine then do
            action = self~doBeforeNextLine
            self~doBeforeNextLine = .nil -- reset before call to avoid infinite recursion
            action~()
        end
        if self~verbose then forward to (self~interceptedDestination) array (line)
                        else forward to (self~interceptedDestination) array (data)
    end
    return 0


::method say
    expose stringbuffer
    use strict arg string

    stringbuffer~append(string)
    line = stringbuffer~string
    stringbuffer~delete(1)
    dataMetadata = self~splitDataMetadata(line)
    data = dataMetadata[1]
    metadata = dataMetadata[2]
    if self~select(data, metadata) then do
        self~lineCount += 1
        if .nil <> self~doBeforeNextLine then do
            action = self~doBeforeNextLine
            self~doBeforeNextLine = .nil -- reset before call to avoid infinite recursion
            action~()
        end
        if self~verbose then forward to (self~interceptedDestination) array (line)
                        else forward to (self~interceptedDestination) array (data)
    end
    return 0


::method flush
    expose stringbuffer
    line = stringbuffer~string
    stringbuffer~delete(1)
    dataMetadata = self~splitDataMetadata(line)
    data = dataMetadata[1]
    metadata = dataMetadata[2]
    -- no filtering, to let always display the escape characters for colors
    if .true /*self~select(data, metadata)*/ then do
        -- self~lineCount += 1 -- incomplete line...
        if self~verbose then self~interceptedDestination~charOut(line)
                        else self~interceptedDestination~charOut(data)
        forward to (self~interceptedDestination)
    end
    return 0


::method splitDataMetadata
    -- Everything before first marker is data
    -- Everything from first marker is metadata
    expose marker ppMarker
    use strict arg line
    -- if line~startsWith("[splitDataMetadata]") then return .array~of(line, "")
    -- say "[splitDataMetadata]" line

    pos = line~pos(marker)
    if pos == 0 then pos = line~pos(ppMarker) -- control characters are pretty-printed [XX]
    if pos == 0 then pos = line~length + 1
    data = line~left(pos - 1)
    metadata = line~substr(pos)
    return .array~of(data, metadata)
