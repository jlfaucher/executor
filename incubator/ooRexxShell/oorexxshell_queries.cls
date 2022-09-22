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
method prettyString     (not used)
attribute traceFilter
*/


::method displayClasses class
    -- All or specified classes (public & private) that are visible from current context, with their package
    -- classnames is an array of StringChunk
    use strict arg classnames, displayer, context
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
        classes[classFlags~left(10) classInfo~klass~id~quoted("'")] = "("packageInfos(classInfo~package)")"
        s~next
    end
    -- Sort by class name, ignoring the 10 first characters which are class flags.
    displayer~sayCollection(classes, /*title*/.nil, /*comparator*/.ColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false)


::method displayClassMethods class
    -- Display the methods of each specified class
    -- classnames is an array of StringChunk
    use strict arg classnames, inherited, displaySource, displayer, context, filteringStream
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
        --say
        --displayer~sayInfo("[Info]" "["count"]" "Class" classInfo~klass~id~quoted("'") classInfos(classInfo~klass, classInfo~visibility) "("packageInfos(classInfo~package)")")
        filteringStream~doBeforeNextLine = {
            expose displayer count classInfo
            say
            displayer~sayInfo("[Info]" "["count"]" "Class" classInfo~klass~id~quoted("'") classInfos(classInfo~klass, classInfo~visibility) "("packageInfos(classInfo~package)")")
        } -- This action will be executed before the first line of methods is displayed, if any (will depend on the filtering)
        methods = .relation~new
        call collectMethods
        lineCount = filteringStream~lineCount
        displayer~sayCollection(methods, /*title*/.nil, .ColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*maxCount*/){
            expose displaySource
            if displaySource then do
                method = item~getUserData("method")
                if .nil <> method then method~source~each{say " >" index~right(4,0) item}
            end
        }
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
        if inherited then injectClass |= .superclasses "recursive" "once" "after" "mem.superclass"
        classInfo~pipe(,
            injectClass,
          | .splitter[.inject {item~instanceMethods(item)} "iterateAfter" "mem.classMethod",,
                      .inject {item~methods(item)} "iterateAfter" "mem.instanceMethod"],
          | .do { expose classInfos methods
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
                  -- remember: the same key (methodDescription) can be used several times
                  -- so don't store the method instance on the key ! Store it on the value (classDescription).
                  classDescription = " "~join(classId, superclassId, "("packageInfos(package)")")
                  classDescription~setUserData("method", item) -- to let retrieve the method (yes!)
                  methods[methodDescription] = classDescription
                },
        )
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
        displayer~sayInfo("[Info]" "["count"]" "Class" classInfo~klass~id~quoted("'") classInfos(classInfo~klass, classInfo~visibility) "("packageInfos(classInfo~package)")")
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
      | .do { expose classInfos methods
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
              -- remember: the same key (methodDescription) can be used several times
              -- so don't store the method instance on the key ! Store it on the value (classDescription).
              classDescription = class~id~quoted("'") "("packageInfos(package)")"
              classDescription~setUserData("method", item) -- to let retrieve the method (yes!)
              methods[methodDescription] = classDescription
            },
    )
    displayer~sayCollection( methods, /*title*/.nil, .ColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*maxCount*/){
        expose displaySource
        if displaySource then do
            method = item~getUserData("method")
            if .nil <> method then method~source~each{say " >" index~right(4,0) item}
        end
    }


::method displayPackages class
    -- All packages that are visible from current context, including the current package (source of the pipeline).
    use strict arg packagenames, displaySource, displayer, context
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
                },
      | .sort {item~name},
      | .console {item~name},
      | .do { expose displaySource
              if displaySource then do
                item~source~each{say " >" index~right(4,0) item}
              end
            },
    )


::method displayRoutines class
    -- All or specified routines (public & private) that are visible from current context, with their package
    -- routinenames is an array of StringChunk
    use strict arg routinenames, displaySource, displayer, context
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
        -- remember: the same key (routineDescription) can be used several times
        -- so don't store the routine instance on the key ! Store it on the value (packageDescription).
        packageDescription = "("packageInfos(routineInfo~package)")"
        packageDescription~setUserData("routine", routineInfo~routine) -- to let retrieve the routine (yes!)
        routines[routineDescription] = packageDescription
        s~next
    end
    -- Sort by routine name, ignoring the 10 first characters which are routine flags.
    displayer~sayCollection(routines, /*title*/.nil, /*comparator*/.ColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false, /*maxCount*/){
        expose displaySource
        if displaySource then do
            routine = item~getUserData("routine")
            routine~source~each{say " >" index~right(4,0) item}
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
    use strict arg method
    if .nil == method then return "UNDEFINED"
    return packageInfos(method~package)


::routine packageInfos public
    -- With ooRexx < 5.0
    -- The package of the predefined methods is .nil.
    -- It's not possible to get directly the package of a class.
    -- With ooRexx >= 5.0
    -- The package of a class created dynamically is still .nil.
    use strict arg package
    if .nil == package then return ""
    packageName = package~name
    if packageName == "" then return "" -- .file~new does not support an empty string, and the error message is cryptic: Incorrect position argument specified; found "0"
    return .file~new(packageName)~name  -- return the filename only, not the full path


::routine classInfos public
    use strict arg class, visibility
    if visibility == "private" then visibility = "."; else visibility = "P" -- Remember: "p" vs "P" not readable
    if class~queryMixinClass then mixin = "M"; else mixin = "."
    return visibility || mixin


::routine routineInfos public
    use strict arg routine, visibility
    if visibility == "private" then visibility = "."; else visibility = "P" -- Remember: "p" vs "P" not readable
    return visibility


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
            matcherCaselessInclude = filter~argument~matcher(wholestring: .false, caseless: .true)
            matcherStrictInclude = filter~argument~matcher(wholestring: .false, caseless: .false)

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
        if .nil <> self~doBeforeNextLine then do
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
