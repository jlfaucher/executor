prompt off directory
demo on

--------------
-- ooRexxShell
--------------

/*
To have an overview of the supported queries, enter a question mark:
?
*/
sleep
?
sleep 10 no prompt

/*
QUERIES ABOUT CLASSES
?c[lasses] c1 c2... :                       display classes.
?c[lasses].m[ethods] c1 c2... :             display local methods per classes (cm).
?c[lasses].m[ethods].i[nherited] c1 c2... : display local & inherited methods (cmi).
*/
sleep no prompt

/*
List of all classes:
?classes
*/
sleep
?classes
sleep no prompt

/*
A first level of filtering can be done when specifying class names.
This is a filtering at object level.
Several names can be specified, the interpretation is: name1 or name2 or ...
If the package regex.cls is available, then the names starting with "/" are
regular expressions which are compiled into a pattern.
Otherwise the names are just string patterns. The character "*" has a special
meaning when first or last character, and not quoted.
*/
sleep no prompt

/*
List of classes whose id contains "string" (caseless).
?classes *string*
*/
sleep
?classes *string*
sleep no prompt

/*
Methods of the class TextOrBufferOrStringIterator (add '.m[ethods]').
?classes.methods TextOrBufferOrStringIterator
*/
sleep
?classes.methods TextOrBufferOrStringIterator
sleep no prompt

/*
Source of the methods of the class TextOrBufferOrStringIterator (add '.s[ource]').
?classes.methods.source TextOrBufferOrStringIterator
*/
sleep
?classes.methods.source TextOrBufferOrStringIterator
sleep no prompt

/*
Methods of the class TextOrBufferOrStringIterator, including the inherited methods (add '.i[nherited]').
?classes.methods.inherited TextOrBufferOrStringIterator
*/
sleep
?classes.methods.inherited TextOrBufferOrStringIterator
sleep no prompt

/*
QUERIES ABOUT METHODS
?m[ethods] method1 method2 ...
*/
sleep no prompt

/*
List of all methods, whatever their classes:
?methods
*/
sleep
?methods
sleep no prompt

/*
List of methods whose name contains "MakeString" (caseless).
?methods *makestring*
*/
sleep
?methods *makestring*
sleep no prompt

/*
List of public and private routines.
?r[outines] routine1 routine2...
*/
sleep
?routines
sleep no prompt

/*
List of packages visible from the current context.
?p[ackages]
*/
sleep
?packages
sleep no prompt

/*
The output of the queries can be filtered line by line using these operators:
\==     strict different: line selected if none of the patterns matches the line.
==      strict equal : line selected if at least one pattern matches the lines.
<>      caseless different: same as \== except caseless.
=       caseless equal: same as == except caseless.
*/
sleep no prompt

/*
If the package regex.cls is available, then the operands starting with "/" are
regular expressions which are compiled into a pattern. The matching with this
pattern is then tested for each line.
Otherwise the patterns are just string patterns.
*/
sleep no prompt

/*
The next queries will test the values of the flags displayed in the first columns.
?f[lags]: describe the flags displayed for classes & methods & routines.
*/
sleep
?flags
sleep 5 no prompt

/*
Display the mixin classes : all lines where 2nd character is "M".
?classes == /^.M
*/
sleep
?classes == /^.M
sleep no prompt

/*
Display the extension methods of the class "String".
The package of the predefined methods is displayed (REXX).
By filtering out the lines which contains "(REXX)", we have the extension methods.
?classes.methods.inherited string \== (REXX)
*/
sleep
?classes.methods.inherited string \== (REXX)
sleep no prompt

/*
Display the hidden methods: all lines containing "----" from 4th character.
?methods =/^...----
*/
sleep
?methods =/^...----
sleep no prompt

/*
Display the methods not guarded whose package is REXX:
all lines where 6th char <> "G" and which contains "(REXX)".
?methods \== /^.....G == (REXX)
*/
sleep
?methods \== /^.....G == (REXX)
sleep no prompt

/*
End of demonstration.
*/
demo off
