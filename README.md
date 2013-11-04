Experimental ooRexx
===================
Forked from http://sourceforge.net/projects/oorexx/

- incubator/DocMusings
- incubator/ooRexxShell
- sandbox/jlf

DocMusings provides a set of scripts to convert the ASCII railroads of the ooRexx documentation to [graphical syntax diagrams][doc].

The experimental ooRexx interpreter implemented in sandbox/jlf is described by this [pdf][slides] and can be downloaded [here][download].

Miscellaneous notes:

- [Sandbox diary][sandbox_diary]
- [DocMusings][doc_musings_diary]
- [Doc XML transformation][doc_transformation_diary]
- [Railroad][railroad_diary]
- [Internal notes][internal_notes]

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

[Rosetta Code][rosetta_code_y_combinator]

The [Y combinator][wikipedia_fixed_point_combinator] allows recursion to be defined as a set of rewrite rules.
It takes a single argument, which is a function that isn't recursive.
It returns a version of the function which is recursive.

See [Mike Vanier article][mike_vanier_article].

call-by-name Y combinator (not for ooRexx, for languages which support lazy evaluation):

    Y = λf.(λx.f (x x)) (λx.f (x x))
    (define Y
      (lambda (f)
        ( (lambda (x) (f (x x)))
          (lambda (x) (f (x x))))))

call-by-value Y combinator (applicable to ooRexx, explicit delayed evaluation done by the lambda (v) wrapper):

    Y = λf.(λx.f (λv.((x x) v))) (λx.f (λv.((x x) v)))
    (define Y
      (lambda (f)
        ( (lambda (x) (f (lambda (v) ((x x) v))))
          (lambda (x) (f (lambda (v) ((x x) v)))))))

Equivalent form:

    (define Y
      (lambda (f)
        ( (lambda (a) (a a))
          (lambda (x) (f (lambda (v) ((x x) v)))))))

The call-by-value is implemented as a method on the class Doer
(no function passed as argument, self is directly the function).

    ::class Doer
    ::method Y
    f = self
    return {use arg a ; return a~(a)} ~ {
        ::closure expose f ; use strict arg x
        return f ~ { ::closure expose x ; use strict arg v ; return x~(x)~(v) }
    }

Application of the Y combinator to factorial:

    say {
          use strict arg f
          return  {::closure expose f ; use strict arg n ; if n == 0 then return 1 ; else return n * f~(n-1) }
        }~Y~(10)
    --> display 3628800

### Anonymous recursive functions

ooRexx supports anonymous recursive functions, so no need of the Y combinator...

    fact =  {
        use strict arg n
        if n==0 then
            return 1
        else
            return n * .context~executable~(n-1)
    }
    say fact~(10)                           -- 3628800

[sandbox_diary]: https://github.com/jlfaucher/executor/blob/master/sandbox/jlf/_diary.txt "Sandbox diary"
[doc_musings_diary]: https://github.com/jlfaucher/executor/blob/master/incubator/DocMusings/_diary.txt "DocMusings diary"
[doc_transformation_diary]: https://github.com/jlfaucher/executor/blob/master/incubator/DocMusings/transformxml/_diary.txt "Doc XML transformations diary"
[railroad_diary]: https://github.com/jlfaucher/executor/blob/master/incubator/DocMusings/railroad/_diary.txt "Railroad diary"
[internal_notes]: https://github.com/jlfaucher/executor/tree/master/sandbox/jlf/internals/notes "Internal notes"
[doc]: http://dl.dropbox.com/u/20049088/oorexx/docs/trunk/index.html "Graphical syntax diagrams"
[slides]: http://dl.dropbox.com/u/20049088/oorexx/sandbox/slides-sandbox-jlf.pdf "slides-sandbox-jlf.pdf"
[download]: http://dl.dropbox.com/u/20049088/oorexx/sandbox/index.html "Download"
[wikipedia_fixed_point_combinator]: http://en.wikipedia.org/wiki/Fixed-point_combinator#Y_combinator "Wikipedia fixed point combinator"
[mike_vanier_article]: http://mvanier.livejournal.com/2897.html "Mike Vanier : Y combinator"
[rosetta_code_y_combinator]: http://rosettacode.org/wiki/Y_combinator "Rosetta code : Y combinator"
[rosetta_code_accumulator_factory]: http://rosettacode.org/wiki/Accumulator_factory "Rosetta code : Accumulator factory"
[rosetta_code_closures_value_capture]: http://rosettacode.org/wiki/Closures/Value_capture "Rosetta code : Closures/Value capture"
