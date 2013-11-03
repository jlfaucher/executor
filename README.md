Experimental ooRexx git repository
==================================
Forked from http://sourceforge.net/projects/oorexx/

- incubator/DocMusings
- incubator/ooRexxShell
- sandbox/jlf

DocMusings provides a set of scripts to convert the ASCII railroads of the ooRexx documentation to [graphical syntax diagrams][doc].

The experimental ooRexx interpreter implemented in sandbox/jlf is described by this [pdf][slides] and can be downloaded [here][download].

Examples
--------

### Closures/Value capture

[Rosetta Code][rosetta_code_closures_value_capture]

    a = .array~new
    do i=1 to 10
        a~append{::closure expose i; return i*i}
    end
    do i=1 to 9
        say a[i]~()
    end

A more compact code... item is an implicit parameter.

    1~upto(10){ {::closure expose item; return item * item} } ~ take(9) ~ each{ say item~() }

### Accumulator factory

[Rosetta Code][rosetta_code_accumulator_factory]

    accumulator = {
        use arg sum
        return  {
            ::closure
            expose sum
            use arg n
            sum += n
            return sum
        }
    }

    x = accumulator~(1) -- an accumulator (closure), sum initialized to 1
    x~(5)               -- add 5 to sum
    accumulator~(3)     -- another accumulator (closure), no effect on x
    say x~(2.3)         -- add 2.3 to sum and print the current sum : 8.3


### Function composition

[Rosetta Code][rosetta_code_accumulator_factory]

    compose = {
        use arg f, g
        return {
            ::closure expose f g
            use arg x
            return f~(g~(x))
        }
    }

    double = { return 2 * arg(1) }
    negative = { return -arg(1) }
    say compose~(negative, double)~(5)  -- -10

    binary2decimal = compose~("x2d", "b2x")
    say binary2decimal~(11111111)  -- 255

### Y combinator

Y = λf.(λx.f (x x)) (λx.f (x x))

The [Y combinator][wikipedia_fixed_point_combinator] allows recursion to be defined as a set of rewrite rules.
It takes a single argument, which is a function that isn't recursive.
It returns a version of the function which is recursive.

[Rosetta Code][rosetta_code_y_combinator]

Implemented as a method on the class Doer (no function passed as argument, self is directly the function).

    --  (define Y
    --    (lambda (f)
    --      ((lambda (x) (f (x x)))
    --       (lambda (x) (f (x x))))))

    ::class Doer
    ::method Y
    f = self
    lambda_x =  {
        ::closure expose f ; use strict arg x
        return f ~ {::closure expose x ; use strict arg v ; return x~(x)~(v)}
    }
    return lambda_x~(lambda_x)

Application to factorial:

    fact =  {
        use strict arg f
        return  {
            ::closure expose f
            use strict arg n
            if n==0 then
                return 1
            else
                return n * f~(n-1)
        }
    }~Y
    say fact~(10)          -- 3628800

ooRexx supports anonymous recursive functions, so no need of the Y combinator...

    fact =  {
        use strict arg n
        if n==0 then
            return 1
        else
            return n * .context~executable~(n-1)
    }
    say fact~(10)          -- 3628800

[doc]: http://dl.dropbox.com/u/20049088/oorexx/docs/trunk/index.html "Graphical syntax diagrams"
[slides]: http://dl.dropbox.com/u/20049088/oorexx/sandbox/slides-sandbox-jlf.pdf "slides-sandbox-jlf.pdf"
[download]: http://dl.dropbox.com/u/20049088/oorexx/sandbox/index.html "Download"
[wikipedia_fixed_point_combinator]: http://en.wikipedia.org/wiki/Fixed-point_combinator#Y_combinator "Wikipedia fixed point combinator"
[rosetta_code_y_combinator]: http://rosettacode.org/wiki/Y_combinator "Rosetta code : Y combinator"
[rosetta_code_accumulator_factory]: http://rosettacode.org/wiki/Accumulator_factory "Rosetta code : Accumulator factory"
[rosetta_code_closures_value_capture]: http://rosettacode.org/wiki/Closures/Value_capture "Rosetta code : Closures/Value capture"
