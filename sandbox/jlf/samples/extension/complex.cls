/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2006 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.oorexx.org/license.html                          */
/*                                                                            */
/* Redistribution and use in source and binary forms, with or                 */
/* without modification, are permitted provided that the following            */
/* conditions are met:                                                        */
/*                                                                            */
/* Redistributions of source code must retain the above copyright             */
/* notice, this list of conditions and the following disclaimer.              */
/* Redistributions in binary form must reproduce the above copyright          */
/* notice, this list of conditions and the following disclaimer in            */
/* the documentation and/or other materials provided with the distribution.   */
/*                                                                            */
/* Neither the name of Rexx Language Association nor the names                */
/* of its contributors may be used to endorse or promote products             */
/* derived from this software without specific prior written permission.      */
/*                                                                            */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */
/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */
/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */
/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */
/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */
/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */
/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */
/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */
/*                                                                            */
/*----------------------------------------------------------------------------*/
/******************************************************************************/
/*  complex.rex         Open Object Rexx Samples                              */
/*                                                                            */
/*  A complex number class.                                                   */
/*                                                                            */
/* -------------------------------------------------------------------------- */
/*                                                                            */
/*  Description:                                                              */
/*  This program demonstrates how to create a complex number class using the  */
/*  ::class and ::method directives.                                          */
/******************************************************************************/

.complex~initialize

--::options trace i
::requires "rxmath" library
::requires "extension/novalue.cls"
                                                /* complex number data class      */
::class complex public

::attribute i class get         -- singleton
::attribute i class set private

::method initialize class -- init not supported (can't instantiate itself or subclass from init)
    self~i = self~new(0, 1)
    .GlobalVariables~declare("I", self~i)

::method '[]' class                             /* create a new complex number    */
    forward message('NEW')                      /* just forward this as a new message */

::attribute real
::attribute imaginary

::method init                                   /* initialize a complex number    */
    expose real imaginary                       /* expose the state data          */
    use arg first, second                       /* access the two numbers         */
    if arg(1, 'o') then
        real = 0
    else
        real = first + 0                        /* force rounding               */

    if arg(2,'o') then                          /* no second argument?            */
        imaginary = 0                           /* imaginary part is zero         */
    else
        imaginary = second + 0                  /* force rounding on the second   */

-- The lack of method makestring & string can have a HUGE impact on performances !
-- See infinity.cls for a detailled explanation
::method makestring                             /* format as a string value       */
    expose real imaginary                       /* get the state info             */
    if imaginary < 0 then return real||imaginary'i'
    return real'+'imaginary'i'                  /* format as real+imaginaryi      */

::method string
    forward message "makestring"

/*
::method arg
    -- Complex argument
    -- http://mathworld.wolfram.com/ComplexArgument.html
    -- arg(x+iy) = arctan(y/x)
    expose real imaginary
    return RxCalcArcTan(real / imaginary, , "r")
*/


-- ::method " "

-- ::method " op:right"

-- ::method "||"

::method "||op:right"
    -- CAREFUL ! This alternative message can be sent for "||" and "".
    -- NO WAY to make a distinction between both... unless the interpreter is modified.
    forward message "op:right"

--::method "" -- abuttal
--    forward message "*"

::method "op:right" -- abuttal
    -- NEVER SENT by the interpreter, because "" is implemented as "||".
    -- Only "||op:right" can be sent by the interpreter.
    -- 2i is equivalent to 2*i.
    -- To clarify the semantic, I will probably add a new operator and no longer depend on abuttal.
    -- Reason : (2)(i) should not be equivalent to 2*i, because it's not a split of symbol.
    if self == i then do
        -- The translation abuttal-->* is only applicable to i
        use strict arg left
        -- The translation abuttal-->* is only applicable if the multiplier is a number
        if left~isA(.string), left~datatype("N") then forward message "*op:right"
    end

::method '+'                                    /* addition method                */
    expose real imaginary                       /* access the state values        */
    use arg adder                               /* get the operand                */
    if arg(1,'o') then                          /* prefix plus operation?         */
        return self                             /* don't do anything with this    */
    adder = adder~request("complex")
    if .nil == adder then return
    tempreal = real + adder~real                /* add the real parts             */
                                                /* add the imaginary parts        */
    tempimaginary = imaginary + adder~imaginary
                                                /* return a new item of same class*/
    return self~class~new(tempreal, tempimaginary)

::method "+op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    forward to (left) message "+" array (self) -- left + self

::method '-'                                    /* subtraction method             */
    expose real imaginary                       /* access the state values        */
    use arg adder                               /* get the operand                */
    if arg(1,'o') then                          /* prefix minus operation?        */
                                                /* negate the number              */
        return self~class~new(-real, -imaginary)
    adder = adder~request("complex")
    if .nil == adder then return
    tempreal = real - adder~real                /* subtract the real part         */
                                                /* subtract the imaginary part    */
    tempimaginary = imaginary - adder~imaginary
                                                /* return a new item              */
    return self~class~new(tempreal, tempimaginary)

::method "-op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    forward to (left) message "-" array (self) -- left - self

::method '*'                                    /* multiplication method          */
    expose real imaginary                       /* access the state values        */
    use arg multiplier                          /* get the operand                */
                                                /* calculate the real part        */
    multiplier = multiplier~request("complex")
    if .nil == multiplier then return
    tempreal = (real * multiplier~real) - (imaginary * multiplier~imaginary)
                                                /* calculate the imaginary part   */
    tempimaginary = (real * multiplier~imaginary) + (imaginary * multiplier~real)
                                                /* return a new item              */
    return self~class~new(tempreal, tempimaginary)

::method "*op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    left~"*"(self) -- left * self
    if var("result") then return result

::method '/'                                    /* division method                */
    expose real imaginary                       /* access the state values        */
    use arg divisor                             /* get the operand                */
    divisor = divisor~request("complex")
    if .nil == divisor then return
    a=real                                      /* get real and imaginaries for   */
    b=imaginary                                 /* both numbers                   */
    c=divisor~real
    d=divisor~imaginary
    qr=((b*d)+(a*c))/(c**2+d**2)                /* generate the new result values */
    qi=((b*c)-(a*d))/(c**2+d**2)
    return self~class~new(qr,qi)                /* return the new value           */

::method "/op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    forward to (left) message "/" array (self) -- left / self

::method '%'                                    /* integer division method        */
    expose real imaginary                       /* access the state values        */
    use arg divisor                             /* get the operand                */
    divisor = divisor~request("complex")
    if .nil == divisor then return
    a=real                                      /* get real and imaginaries for   */
    b=imaginary                                 /* both numbers                   */
    c=divisor~real
    d=divisor~imaginary
    qr=((b*d)+(a*c))%(c**2+d**2)                /* generate the new result values */
    qi=((b*c)-(a*d))%(c**2+d**2)
    return self~class~new(qr,qi)                /* return the new value           */

::method "%op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    left~"%"(self) -- left % self
    if var("result") then return result

::method '//'                                   /* remainder method               */
    expose real imaginary                       /* access the state values        */
    use arg divisor                             /* get the operand                */
    divisor = divisor~request("complex")
    if .nil == divisor then return
    a=real                                      /* get real and imaginaries for   */
    b=imaginary                                 /* both numbers                   */
    c=divisor~real
    d=divisor~imaginary
    qr=((b*d)+(a*c))//(c**2+d**2)               /* generate the new result values */
    qi=((b*c)-(a*d))//(c**2+d**2)
    return self~class~new(qr,qi)                /* return the new value           */

::method "//op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    forward to (left) message "//" array (self) -- left // self

::method "**"
    -- Limited support, I want mainly support i**n
    -- See http://mathworld.wolfram.com/ComplexNumber.html
    use arg exponent
    if \ exponent~isA(.String) then return -- datatype works only on string
    if \ exponent~datatype("W") then return
    if exponent == 0 then return 1
    r = 1
    do abs(exponent) ; r *= self ; end -- naive calculation
    if exponent < 0 then return 1/r
    return r

-- ::method "**op:right" -- complex exponent

::method "="
    expose real imaginary
    use strict arg right
    right = right~request("complex")
    if .nil == right then return
    return real=right~real & imaginary=right~imaginary

::method "=op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    forward to (left) message "=" array (self) -- left = self

::method "\="
    expose real imaginary
    use strict arg right
    right = right~request("complex")
    if .nil == right then return
    return real\=right~real | imaginary\=right~imaginary

::method "\=op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    forward to (left) message "\=" array (self) -- left \= self

::method "<>"
    forward message "\="

::method "<>op:right"
    -- NEVER SENT by the interpreter, because "<>" is implemented as "\=".
    -- Only "\=op:right" can be sent by the interpreter.
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    forward to (left) message "<>" array (self) -- left <> self

::method "=="
    expose real imaginary
    use strict arg right
    right = right~request("complex")
    if .nil == right then return
    return real==right~real & imaginary==right~imaginary

::method "==op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    forward to (left) message "==" array (self) -- left == self

::method "\=="
    expose real imaginary
    use strict arg right
    right = right~request("complex")
    if .nil == right then return
    return real\==right~real | imaginary\==right~imaginary

::method "\==op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    forward to (left) message "\==" array (self) -- left \== self

-- ::method "><"

-- ::method "><op:right"
    -- NEVER SENT by the interpreter, because "><" is implemented as "\=".
    -- Only "\=op:right" can be sent by the interpreter.

-- ::method "\"

-- ::method ">"

-- ::method ">op:right"

-- ::method "<"

-- ::method "<op:right"

-- ::method ">="

-- ::method ">=op:right"

-- ::method "\<"
    -- NEVER SENT by the interpreter, because "\<" is implemented as ">=".
    -- Only ">=op:right" can be sent by the interpreter.

-- ::method "\<op:right"

-- ::method "<="

-- ::method "<=op:right"

-- ::method "\>"

-- ::method "\>op:right"
    -- NEVER SENT by the interpreter, because "\>" is implemented as "<=".
    -- Only "<=op:right" can be sent by the interpreter.

-- ::method ">>"

-- ::method ">>op:right"

-- ::method "<<"

-- ::method "<<op:right"

-- ::method ">>="

-- ::method ">>=op:right"

-- ::method "\<<"

-- ::method "\<<op:right"
    -- NEVER SENT by the interpreter, because "\<<" is implemented as ">>=".
    -- Only ">>=op:right" can be sent by the interpreter.

-- ::method "<<="

-- ::method "<<=op:right"

-- ::method "\>>"

-- ::method "\>>op:right"
    -- NEVER SENT by the interpreter, because "\>>" is implemented as "<<=".
    -- Only "<<=op:right" can be sent by the interpreter.

-- ::method "&"

-- ::method "&op:right"

-- ::method "|"

-- ::method "|op:right"

-- ::method "&&"

-- ::method "&&op:right"


/******************************************************************************/
-- A number (i.e. an instance of String) can be converted to a complex
::class "ComplexString" mixinclass Object public

::method makeComplex
    if self~datatype("N") then return .complex~new(self)
    return .nil
