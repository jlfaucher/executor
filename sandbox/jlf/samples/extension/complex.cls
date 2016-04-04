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

--::options trace i
::requires "rxmath" library
                                                /* complex number data class      */
::class complex public

::method '[]' class                             /* create a new complex number    */
    use arg first, second                       /* access the two numbers         */
    forward to (self) message('NEW')            /* just forward this as a new message */

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

::method real                                   /* return real part of a complex  */
    expose real                                 /* access the state information   */
    return real                                 /* return that value              */

::method imaginary                              /* return imaginary part          */
    expose imaginary                            /* access the state information   */
    return imaginary                            /* return the value               */

/*
::method arg
    -- Complex argument
    -- http://mathworld.wolfram.com/ComplexArgument.html
    -- arg(x+iy) = arctan(y/x)
    expose real imaginary
    return RxCalcArcTan(real / imaginary, , "r")
*/

::method equals
    expose real imaginary
    use strict arg right
    right = right~request("complex")
    if .nil == right then return
    return real=right~real & imaginary=right~imaginary

::method notEquals
    expose real imaginary
    use strict arg right
    right = right~request("complex")
    if .nil == right then return
    return real\=right~real | imaginary\=right~imaginary

::method strictEquals
    expose real imaginary
    use strict arg right
    right = right~request("complex")
    if .nil == right then return
    return real==right~real & imaginary==right~imaginary

::method strictNotEquals
    expose real imaginary
    use strict arg right
    right = right~request("complex")
    if .nil == right then return
    return real\==right~real | imaginary\==right~imaginary

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

::method string                                 /* format as a string value       */
    expose real imaginary                       /* get the state info             */
    if imaginary < 0 then return real||imaginary'i'
    return real'+'imaginary'i'                  /* format as real+imaginaryi      */


/******************************************************************************/
-- ComplexOperators
-- A partial implementation of the operators is defined on the class 'complex'.
-- The following methods address only the missing functionalities.

::method "+op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    left~"+"(self) -- left + self
    if var("result") then return result


::method "-op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    left~"-"(self) -- left - self
    if var("result") then return result


::method "*op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    left~"*"(self) -- left * self
    if var("result") then return result


::method "/op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    left~"/"(self) -- left / self
    if var("result") then return result


::method "%op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    left~"%"(self) -- left % self
    if var("result") then return result


::method "//op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    left~"//"(self) -- left // self
    if var("result") then return result


/******************************************************************************/
-- Add support for notation a+bi where a and b are numbers.
::class "ComplexString" mixinclass Object public

::method makeComplex
    if self~datatype("N") then return .complex~new(self)
    if self~right(1)~caselessEquals("i") then do
        imaginary = self~left(self~length-1)
        if imaginary == "" then imaginary = 1
        if imaginary~datatype("N") then return .complex~new(0, imaginary)
    end
    return .nil

/*
::method arg
    use strict arg -- none
    complex = self~request("complex")
    if .nil == complex then forward class (super)
    return complex~arg
*/

::method "+op:left"
    -- For the moment, this message is sent only for the unary +
    use strict arg -- none
    left = self~request("complex")
    if .nil <> left then return left -- unary +


::method "+op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    right = self~request("complex")
    if .nil == right then return
    left~"+"(right) -- left + right
    if var("result") then return result


::method "-op:left"
    -- For the moment, this message is sent only for the unary -
    use strict arg -- none
    left = self~request("complex")
    if .nil == left then return
    left~"-" -- -left -- unary -
    if var("result") then return result


::method "-op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    right = self~request("complex")
    if .nil == right then return
    left~"-"(right) -- left - right
    if var("result") then return result


::method "*op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    right = self~request("complex")
    if .nil == right then return
    left~"*"(right) -- left * right
    if var("result") then return result


::method "/op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    right = self~request("complex")
    if .nil == right then return
    left~"/"(right) -- left / right
    if var("result") then return result


::method "%op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    right = self~request("complex")
    if .nil == right then return
    left~"%"(right) -- left % right
    if var("result") then return result


::method "//op:right"
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    right = self~request("complex")
    if .nil == right then return
    left~"//"(right) -- left // right
    if var("result") then return result


::method "**op:right"
    -- Limited support, I want mainly support i**2
    use strict arg left
    left = left~request("complex")
    if .nil == left then return
    if \ self~datatype("W") then return
    if self == 0 then return 1 -- not sure it's correct for a complex number
    r = 1
    do abs(self) ; r *= left ; end -- naive calculation
    if self < 0 then return 1/r
    return r


/*
Others operators
*/

/* Not activated
::method "="
*/

::method "=op:right"

::method "\="

::method "\=op:right"

/* Not activated
::method "<>"
*/

::method "<>op:right"

/* Not activated
::method "=="
*/

::method "==op:right"

/* Not activated
::method "\=="
*/

::method "\==op:right"

/* Not activated
::method "><"
*/

::method "><op:right"

::method "\"
    use strict arg -- none, no binary version

::method ">"

::method ">op:right"

::method "<"

::method "<op:right"

::method ">="

::method ">=op:right"

::method "\<"

::method "\<op:right"

::method "<="

::method "<=op:right"

::method "\>"

::method "\>op:right"

::method ">>"

::method ">>op:right"

::method "<<"

::method "<<op:right"

::method ">>="

::method ">>=op:right"

::method "\<<"

::method "\<<op:right"

::method "<<="

::method "<<=op:right"

::method "\>>"

::method "\>>op:right"

::method "&"

::method "&op:right"

::method "|"

::method "|op:right"

::method "&&"

::method "&&op:right"


/*
Operators not needed for complex numbers

::method " "

::method " op:right"

::method "||"

::method "||op:right"

::method "" -- abuttal

::method "op:right" -- abuttal

*/