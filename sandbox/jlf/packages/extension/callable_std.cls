/*
Keep it compatible with official ooRexx 4.2.
*/

/******************************************************************************/
/*
Compatibility with Executor.
A DoerFactory is an object that can create a doer.
A doer can be created from :
- a lambda
- a closure
*/

::class "DoerFactory" public

::method doer unguarded
    use strict arg -- none
    return self


/******************************************************************************/
/*
Compatibility with Executor.
A Doer is an object that can execute itself. (understands "do")
This is an abstraction of routine, method, message, coactivity, closure.
*/

::class "Doer" public subclass DoerFactory

::method needsObject unguarded
    use strict arg -- none
    return .false


::method do unguarded
    forward message "call"


::method doWith unguarded
    use strict arg array
    forward message "call" arguments (array)


::method source abstract


/******************************************************************************/
/*
This is a lambda implementation which is compatible with ooRexx 4.2, ooRexx 5
and Executor5-bulk.
See oorexxshell_queries_std.cls for a concrete usage example.

Example 1:
    say each((1,2,3), .routines~2times)
    say each((1,2,3), .lambda~new('return 2 * arg(1)'))

    ::routine 2times
        return 2 * arg(1)

    ::routine each
        use strict arg array, callable
        newArray = .array~new
        do item over array
            newItem = callable~call(item)
            newArray~append(newItem)
        end
        return newArray

Output:
    2
    4
    6

Example 2:
    -- From ooRexxShell:
    -- Display all the files in the home directory whose name contains "bash".
    -- Here, .context must be passed to allow finding the "matcher" routine
    -- that was loaded by ooRexxShell.
    (.filetree | .select .lambda~new('use arg item; return matcher("*bash*")~match(item~name)', .context) | .console)~go("~")

Output:
    49 : (~/.bashrc)
    116 : (~/.bash_sessions)
    205 : (~/.bash_history)
    215 : (~/.bash_env)

*/
::class "Lambda" public subclass Doer

::attribute source get

::method init
    expose source
    use strict arg source, context=.nil
    if .nil <> context then do
        -- Class and routine lookup scope from the context~package.
        method = .Method~new("CALL", source, context~package)
    end
    else do
        -- Class and routine search scope from the current package.
        -- Will work only if you have ZERO dependency in source.
        method = .Method~new("CALL", source, "PROGRAMSCOPE")
    end
    self~setMethod("CALL", method, "OBJECT")


/******************************************************************************/
/*
This is a Closure implementation which is compatible with ooRexx 4.2, ooRexx 5
and Executor5-bulk.
See oorexxshell_queries_std.cls for a concrete usage example.

Example:
    v = 1
    -- capture the value of v: 1
    closure = .Closure~new('expose v; say v; v += 10', .context)
    v = 2
    closure~call()                          -- display 1
    closure~call()                          -- display 11
    closure~call()                          -- display 21
    say v                                   -- v not impacted by the closure: 2
*/

::class "Closure" public subclass lambda

::method init
    expose !_closure.variableNames_!
    use strict arg source, context

    self~init:super(source, context)

    variables = context~variables
    !_closure.variableNames_! = ""
    do v over variables
        !_closure.variableNames_! ||= " "v
    end
    self~initVariables(variables)


::method initVariables
    expose !_closure.variableNames_! (!_closure.variableNames_!)
    -- Must use variable names that will not collide with user-defined variables
    use strict arg !_closure.variables_!
    !_closure.supplier_! = !_closure.variables_!~supplier
    do while !_closure.supplier_!~available
        call value !_closure.supplier_!~index, !_closure.supplier_!~item
        !_closure.supplier_!~next
    end


::method variables unguarded
    expose !_closure.variableNames_! (!_closure.variableNames_!)
    -- Must use variable names that will not collide with user-defined variables
    !_closure.directory_! = .Directory~new
    do !_closure.variableName_! over !_closure.variableNames_! ~ subwords
        !_closure.directory_! ~ put(value(!_closure.variableName_!), !_closure.variableName_!)
    end
    return !_closure.directory_!
