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

Examples of extensions
----------------------

### Blocks (source literals)

A RexxBlock is a piece of source code surrounded by curly brackets.

Routine

    {use arg name, greetings
     say "hello" name || greetings
    }~("John", ", how are you ?")       -- hello John, how are you ?

Method

The first argument is the object, available in self, on which the method is executed.
The remaining arguments are passed to the method as arg(1), arg(2), ...

    {::method use arg greetings
     say "hello" self || greetings
    }~("John", ", how are you ?")       -- hello John, how are you ?

Coactivity

A coactivity remembers its internal state. It can be called several times,
the execution is resumed after the last executed .yield[].

    nextInteger = {::coactivity loop i=0; .yield[i]; end}
    say nextInteger~()                  -- 0
    say nextInteger~()                  -- 1
    nextInteger~makeArray(10)           -- [2,3,4,5,6,7,8,9,10,11]
    say nextInteger~()                  -- 12
    ...

Closure

A closure remembers the values of the variables defined in the outer environment of the block.
Updating a variable from the closure will have no impact on the original context (closure by value).

    v = 1                                -- captured
    {::closure expose v ; say v}~()      -- 1

### Array initializer

Initializer (instance method ~of) which takes into account the dimensions of the array.
Inspired by [APL][apl_glimpse_heaven]

If there is only one argument, and this argument is a string, then each word of the string is an item (APL-like).

    .array~new(2,3)~of(1 2 3 4 5 6)
    1 2 3
    4 5 6

If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.

    .array~new(2,3)~of(1~upto(6))
    1 2 3
    4 5 6

If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.
Implicit arguments :

- arg(1) : integerIndex : position of the current cell, from 1 to size.
- arg(2) : arrayIndex : position of the current cell, in each dimension.

The value returned by the doer is the item for the current cell.

    .array~new(2,3)~of{10*integerIndex}
    10 20 30
    40 50 60

Otherwise, when more than one argument, each argument is an item as-is.

    .array~new(2,3)~of(1,2,3,4,5,6)
    1 2 3
    4 5 6

If some arguments are omitted, then the corresponding item in the initialized array remains non-assigned.

    .array~new(2,3)~of(1,,3,,5,6)
    1 . 3
    . 5 6

Rules inspired by APL :
If there are too many items, the extra items are ignored.
If there are fewer items than implied by the dimensions, the list of items is reused as
many times as necessary to fill the array.

    .array~new(2,3)~of(1,2)
    1 2 1
    2 1 2

Generation of an identity matrix (1 on the diagonal, 0 everywhere else).
If (arrayIndex - arrayIndex[1])~reduce("+") == 0 is true then this is a diagonal index.

- [1,1,1] - 1 = [0,0,0], the sum of all items is 0 --> diagonal index
- [1,1,2] - 1 = [0,0,1], the sum of all items is not 0 --> not a diagonal index

This example also illustrates the availability of operators for array.

    .array~new(3,3)~of{ if (arrayIndex - arrayIndex[1])~reduce("+") == 0 then 1; else 0 }=
    1 0 0
    0 1 0
    0 0 1


### Coactivity / Inverse a recursive algorithm into an iterative one

Producer/consumer problems can often be implemented elegantly with coactivities.
Coactivities also provide an easy way to inverse recursive algorithms into iterative ones.
Illustration with a binary tree.

    btree = .BinaryTree~of(4, 6, 2, 7, 5, 3, 1)
    ascending = btree~visitAscending
    descending = btree~visitDescending
    do btree~items
        say ascending~()
        say descending~()
    end
    .coactivity~endAll

    ::requires "extension/extensions.cls"

Class Node

The binary tree stores items in nodes.
Each node holds an item.
Each node has a reference to a node on the left and a reference to a node on the right.
Items smaller than current node's item are stored in the left-side subtree, and larger items are stored in the right-side subtree.

    ::class Node private

    ::attribute leftNode
    ::attribute rightNode
    ::attribute item

    ::method init
        self~leftNode = .nil
        self~rightNode = .nil
        self~item = .nil

    ::method insert
        use arg item
        select
            when self~item == .nil then do
                self~item = item
            end
            when item < self~item then do
                if self~leftNode == .nil then self~leftNode = self~class~new
                self~leftNode~insert(item)
            end
            otherwise do
                if self~rightNode == .nil then self~rightNode = self~class~new
                self~rightNode~insert(item)
            end
        end

    ::method visitAscending unguarded
        if self~leftNode <> .nil then self~leftNode~visitAscending
        .yield[self~item]   -- can be executed only in the context of a coactivity
        if self~rightNode <> .nil then self~rightNode~visitAscending

    ::method visitDescending unguarded
        if self~rightNode <> .nil then self~rightNode~visitDescending
        .yield[self~item]   -- can be executed only in the context of a coactivity
        if self~leftNode <> .nil then self~leftNode~visitDescending

Class BinaryTree

    ::class BinaryTree public

    ::method of class
        use arg item, ...
        binaryTree = self~new
        do i = 1 to arg()
            binaryTree~insert(arg(i))
        end
        return binaryTree

    ::attribute rootNode private
    ::attribute items

    ::method init
        self~rootNode = .Node~new
        self~items = 0

    ::method insert
        self~items += 1
        forward to (self~rootNode)

    ::method visitAscending
        -- the message "visitAscending" is sent to self~rootNode, in the context of a coactivity
        return .Coactivity~new("visitAscending", false, self~rootNode)

    ::method visitDescending
        -- the message "visitDescending" is sent to self~rootNode, in the context of a coactivity
        return .Coactivity~new("visitDescending", false, self~rootNode)


### Closures / Value capture

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

[Rosetta Code][rosetta_code_function_composition]

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
        ::closure expose f ; use arg x
        return f ~ { ::closure expose x ; use arg v ; return x~(x)~(v) }
    }

Application of the Y combinator to factorial:

    say {
          use arg f
          return  { ::closure expose f ; use arg n ; if n == 0 then return 1 ; else return n * f~(n-1) }
        }~Y~(10)
    --> display 3628800

### Anonymous recursive functions

ooRexx supports anonymous recursive functions, so no need of the Y combinator...

    fact =  {
        use arg n
        if n == 0 then
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
[rosetta_code_function_composition]:http://rosettacode.org/wiki/Function_composition "Rosetta code : Function composition"
[apl_glimpse_heaven]:http://archive.vector.org.uk/art10011550 "APL - a Glimpse of Heaven"
