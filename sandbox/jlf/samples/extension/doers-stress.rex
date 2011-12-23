say {
    say arg(1) ; return arg(1) * {
        say arg(1) ; return arg(1) * {
            say arg(1) ; return arg(1) * {
                say arg(1) ; return arg(1) * {
                    say arg(1) ; return arg(1) * {
                        say arg(1) ; return arg(1) * {
                            say arg(1) ; return arg(1) * {
                                say arg(1) ; return arg(1) * {
                                    say arg(1) ; return arg(1) * {
                                        say arg(1) ; return arg(1) * {
                                            say arg(1) ; return arg(1) * {
                                                say arg(1) ; return arg(1) * {
                                                    say arg(1) ; return arg(1) * {
                                                        say arg(1) ; return arg(1) * {
                                                            say arg(1) ; return arg(1) * {
                                                                say arg(1) ; return arg(1) * {
                                                                    say arg(1) ; return arg(1) * {
                                                                        say arg(1) ; return arg(1) * {
                                                                            say arg(1) ; return arg(1) * {
                                                                                say arg(1) ; return arg(1) * {
                                                                                    say arg(1) ; return arg(1) * {
                                                                                        say arg(1) ; return arg(1) * {
                                                                                            say arg(1) ; return arg(1)
                                                                                        }~(arg(1) - 1)
                                                                                    }~(arg(1) - 1)
                                                                                }~(arg(1) - 1)
                                                                            }~(arg(1) - 1)
                                                                        }~(arg(1) - 1)
                                                                    }~(arg(1) - 1)
                                                                }~(arg(1) - 1)
                                                            }~(arg(1) - 1)
                                                        }~(arg(1) - 1)
                                                    }~(arg(1) - 1)
                                                }~(arg(1) - 1)
                                            }~(arg(1) - 1)
                                        }~(arg(1) - 1)
                                    }~(arg(1) - 1)
                                }~(arg(1) - 1)
                            }~(arg(1) - 1)
                        }~(arg(1) - 1)
                    }~(arg(1) - 1)
                }~(arg(1) - 1)
            }~(arg(1) - 1)
        }~(arg(1) - 1)
    }~(arg(1) - 1)
}~(23)
say

odd = {use arg n ; call charout , n~format(5) "=" odd(n)}
signal on syntax
odd~duration(0)
odd~duration(1)
odd~duration(2)
odd~duration(101)
odd~duration(1000)
odd~duration(10001) -- control stack full
syntax:
say

say trampoline(1)
say

say trampoline{say "one" ; return {say "two"; return {say "three" ; return "four"}}}
say

t_odd = {use arg n ; call charout , n~format(6) "=" trampoline(t_odd(n))} 
t_odd~duration(0)
t_odd~duration(1)
t_odd~duration(2)
t_odd~duration(101)
t_odd~duration(1000)
t_odd~duration(10001) -- no control stack full
t_odd~duration(100000) -- no control stack full
say


-------------------------------------------------------------------------------
-- odd & even, mutual recursive, stack overflow if n too large

::routine odd
    use strict arg n
    if n == 0 then return .false
    return even(n-1)

::routine even
    use strict arg n
    if n == 0 then return .true
    return odd(n-1)

-------------------------------------------------------------------------------
-- odd & even, trampoline version, no stack overflow

::routine t_odd
    use strict arg n
    if n == 0 then return .false
    return {::cl expose n ; return t_even(n-1)}

::routine t_even
    use strict arg n
    if n == 0 then return .true
    return {::cl expose n ; return t_odd(n-1)}

-------------------------------------------------------------------------------
-- The trampoline function
-- If the return value is not a function then return the value.
-- If the return value is a function then call the function and recurse.

::routine trampoline
    use strict arg arg 
    do while arg~isA(.RexxBlock)
        arg = arg~()
    end
    return arg

-------------------------------------------------------------------------------
-- Helper to display duration

::extension RexxBlock
::method duration
    call time('r')
    self~doWith(arg(1, "a"))
    say " (duration "time('e')~format(2,8)")"


::requires "extension/extensions.cls"
