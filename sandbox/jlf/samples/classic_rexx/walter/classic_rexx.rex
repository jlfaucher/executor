/* REXX ----------------------------------------------------------
* Use all kinds of old REXX features
*---------------------------------------------------------------*/
Parse Version version

Select
  When pos('370',version)>0 Then Do
    oid='OLDREXX TEXT A'
    'ERASE' oid
    End
  When left(version,11)='REXX-ooRexx' Then Do
    oid='oldrexx.txt'
    Call SysfileDelete oid
    End
  When left(version,11)='REXX-Regina' Then Do
    Say version
    oid='oldrexx.reg'
    'erase' oid
    End
  Otherwise Do
    Say 'Unknown version:' version
    Exit
    End
  End
Call o version

Call oh 'Use of @#$¢ as or in symbols'
@='Klammeraffe'; Call o '@='@
#='Kanalgitter'; Call o '#='#
$='Dollar     '; Call o '$='$
¢='Cent       '; Call o '¢='¢

Call oh 'a= as a short form of a=""'
a=
Call o 'a='a'<'

Call oh 'Multi-line strings (extending a string over line boundaries)'
s='First
 Line'
Call o 's='s

Call oh 'the Upper instruction'
Upper s
Call o 's='s

Call oh 'Bifs: externals, find, index, justify, linesize'
Call o "externals()         ="externals()         ;
Call o "find('abc d ef gh,'d  ef')  ="find('abc d ef gh','d  ef')  ;
Call o "index('abcdef','c') ="index('abcdef','c') ;
Call o "justify('abc def',9)="justify('abc def',9);
Call o "center('abc def',9) ="center('abc def',9) ;
Call o "linesize()          ="linesize()          ;

Call oh '/= and /== as alternatives to \= or \=='
x=13
Call o "x="||x
Call o "x/=13 -->"||(x/=13)
Call o "x/==' 13 '-->"||(x/==' 13 ')
Exit
oh:Call lineout oid,copies('-',62)
o: Say arg(1)
   Return lineout(oid,arg(1))
