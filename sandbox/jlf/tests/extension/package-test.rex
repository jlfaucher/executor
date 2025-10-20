--------------------------------------------------------------------------------
-- .Package~local (compatibility with ooRexx5)
--------------------------------------------------------------------------------

p1 = .Package~new("P1", "say 'Package P1'")
p1~local~var1 = "p1 var1"
p1~local~var2 = "p1 var2"
call dump2 p1~local

p2 = .Package~new("P2", "say 'Package P2'")
p2~local~var1 = "p2 var1"
p2~local~var2 = "p2 var2"
call dump2 p2~local


::requires "extension/extensions.cls"
::requires "rgf_util2/rgf_util2.rex" -- for the dump2 method
