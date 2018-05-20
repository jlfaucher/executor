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
method sayStackFrames   (not used)
method singularPlural
method prettyString     (not used)
attribute traceFilter
*/


::method displayClasses class
    -- All or specified classes (public & private) that are visible from current context, with their package
    -- classnames is an array of Argument
    use strict arg classnames, displayer, context
    matchers = .array~new
    do classname over classnames
        matcher = pattern2matcher(classname, /*wholestring*/ .true, /*caseless*/ .true, displayer, "[object filter]")
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
    displayer~sayCollection(classes, /*title*/.nil, /*comparator*/.ColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false)


::method displayClassMethods class
    -- Display the methods of each specified class
    -- classnames is an array of Argument
    use strict arg classnames, inherited, displaySource, displayer, context, filteringStream
    matchers = .array~new
    do classname over classnames
        matcher = pattern2matcher(classname, /*wholestring*/ .true, /*caseless*/ .true, displayer, "[object filter]")
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
        displayer~sayCollection(methods, /*title*/.nil, .ColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false){
            expose displaySource
            if displaySource then do
                method = item~getUserData
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
                  methodDescription = flags~left(10) index~quoted(x2c(27))
                  -- remember: the same key (methodDescription) can be used several times
                  -- so don't store the method instance on the key ! Store it on the value (classDescription).
                  classDescription = class~id~quoted(x2c(27)) "("packageInfos(package)")"
                  classDescription~setUserData(item) -- to let retrieve the method (yes!)
                  methods[methodDescription] = classDescription
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
        matcher = pattern2matcher(classname, /*wholestring*/ .true, /*caseless*/ .true, displayer, "[object filter]")
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
        else displayer~sayInfo("no help")
        say
        return


::method displayMethods class
    -- Display the defining classes of each specified method
    -- methodnames is an array of Argument
    use strict arg methodnames, displaySource, displayer, context
    matchers = .array~new
    do methodname over methodnames
        matcher = pattern2matcher(methodname, /*wholestring*/ .true, /*caseless*/ .true, displayer, "[object filter]")
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
              methodDescription = flags~left(10) index~quoted(x2c(27))
              -- remember: the same key (methodDescription) can be used several times
              -- so don't store the method instance on the key ! Store it on the value (classDescription).
              classDescription = class~id~quoted(x2c(27)) "("packageInfos(package)")"
              classDescription~setUserData(item) -- to let retrieve the method (yes!)
              methods[methodDescription] = classDescription
            },
    )
    displayer~sayCollection( methods, /*title*/.nil, .ColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false){
        expose displaySource
        if displaySource then do
            method = item~getUserData
            if .nil <> method then method~source~each{say " >" index~right(4,0) item}
        end
    }


::method displayPackages class
    -- All packages that are visible from current context, including the current package (source of the pipeline).
    use strict arg packagenames, displaySource, displayer, context
    matchers = .array~new
    do packagename over packagenames
        matcher = pattern2matcher(packagename, /*wholestring*/ .true, /*caseless*/ .true, displayer, "[object filter]")
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
    -- routinenames is an array of Argument
    use strict arg routinenames, displaySource, displayer, context
    matchers = .array~new
    do routinename over routinenames
        matcher = pattern2matcher(routinename, /*wholestring*/ .true, /*caseless*/ .true, displayer, "[object filter]")
        matchers~append(matcher)
    end
    routineInfos = .routineInfo~collect(context, matchers)
    -- Now build a collection where the indexes are the routine names preceded by some flags (visibility), and the items are the package filenames.
    routines = .relation~new
    s = routineInfos~supplier
    do while s~available
        routineInfo = s~item
        routineFlags = routineInfos(routineInfo~routine, routineInfo~visibility)
        routineDescription = routineFlags~left(10) routineInfo~name~quoted(x2c(27))
        -- remember: the same key (routineDescription) can be used several times
        -- so don't store the routine instance on the key ! Store it on the value (packageDescription).
        packageDescription = "("packageInfos(routineInfo~package)")"
        packageDescription~setUserData(routineInfo~routine) -- to let retrieve the routine (yes!)
        routines[routineDescription] = packageDescription
        s~next
    end
    -- Sort by routine name, ignoring the 10 first characters which are routine flags.
    displayer~sayCollection(routines, /*title*/.nil, /*comparator*/.ColumnComparator~new(11,999), /*iterateOverItem*/.true, /*surroundItemByQuotes*/.false, /*surroundIndexByQuotes*/.false){
        expose displaySource
        if displaySource then do
            routine = item~getUserData
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
            say variablename path~quoted(x2c(27))
        end
        say variablename "length:" variablevalue~length
        say
    end

::constant separators ": ~ @ |"


::attribute classRoutineFilters     -- array of Argument
::attribute defaultEntityFilters    -- array of Argument
::attribute methodFilters           -- array of Argument
::attribute packageFilters          -- array of Argument
::attribute query                   -- string : the first token of the whole string. For example : "classes", "methods", "packages" etc... see dispatchHelp
::attribute queryFilterArgs         -- array of Argument : the whole string splitted in Arguments
::attribute streamFilters           -- array of Argument


::method init
    use strict arg queryFilter, string2args
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

    self~queryFilterArgs = string2args~call(queryFilter, /*withInfos*/ .true, /*breakTokens*/ .Filter~operators .QueryManager~separators)
    do arg over self~queryFilterArgs
        if self~query == .nil then self~query = arg -- the first arg is the query
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
    if method == .nil then return "----" -- Hidden method, see documentation of .class~methods
    if instanceLevel then level = "."; else level = "C" -- Remember: "I" not displayed because of "PIG"
    if method~isGuarded then guarded = "G"; else guarded = "."
    if method~isPrivate then visibility = "."; else visibility = "P" -- Remember: "p" vs "P" not readable
    if method~isProtected then protected = "P"; else protected = "."
    return visibility || level || guarded || protected


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
    -- arg is an Argument
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
    -- args is an array of Argument
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

    -- filters is an array of Argument
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
            matcherCaselessInclude = pattern2matcher(filter~argument, /*wholestring*/ .false, /*caseless*/ .true)
            matcherStrictInclude = pattern2matcher(filter~argument, /*wholestring*/ .false, /*caseless*/ .false)

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
    -- filters is an array of Argument
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
    -- When whole, and the pattern is not a regular expression, then the charecter "*" is recognized as a generic character when first or last character.
    -- When not whole, and the pattern is not a regular expression, then the character "^" is recognized as the metacharacter 'begining of string' when first character.
    -- When not whole, and the pattern is not a regular expression, then the character "$" is recognized as the metacharacter 'end of string' when last character.
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
        leftCaret = \firstCharIsQuoted & stringPattern~left(1) == "^"
        rightDollar = \lastCharIsQuoted & stringPattern~right(1) == "$"
        if (leftStar & rightStar) | (leftCaret & rightDollar) then do
            if stringPattern~length <= 2 then stringPattern = "" -- "*" or "**" or "^" or "$" or "^$"--> ""
            else stringPattern = stringPattern~substr(2, stringPattern~length - 2) -- "*...*" or "^...$" --> "..."
        end
        else if leftStar | leftCaret then stringPattern = stringPattern~substr(2)
        else if rightStar | rightDollar then stringPattern = stringPattern~left(stringPattern~length - 1)

        if stringPattern == "" then return {expose description; return .true}
        else if wholeString then do
            -- leftCaret and rightDollar have no impact
            if \leftStar & \rightStar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~equals(stringPattern)}
            end
            else if \leftStar & rightStar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~equals(stringPattern)}
            end
            else if leftStar & \rightStar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~equals(stringPattern)}
            end
            else do -- leftStar & rightStar
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessPos(stringPattern) <> 0}
                else             matcher = {expose description stringPattern; use strict arg string; return string~pos(stringPattern) <> 0}
            end
        end
        else do -- \wholeString
            -- leftStar and rightStar have no impact
            if \leftCaret & \rightDollar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessPos(stringPattern) <> 0}
                else             matcher = {expose description stringPattern; use strict arg string; return string~pos(stringPattern) <> 0}
            end
            else if \leftCaret & rightDollar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~equals(stringPattern)}
            end
            else if leftCaret & \rightDollar then do
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~left(stringPattern~length)~equals(stringPattern)}
            end
            else do -- leftCarret & rightDollar
                if caseless then matcher = {expose description stringPattern; use strict arg string; return string~caselessEquals(stringPattern)}
                else             matcher = {expose description stringPattern; use strict arg string; return string~equals(stringPattern)}
            end
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
