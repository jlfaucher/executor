parse arg n
if n == "" then n = 10
say "n =" n

say "not interpreted"
d = 0
do i = 1 to n+1
    t=time("r");do 10000000; x = left("noël",3); end; t = time("e")
    if i == 1 then iterate -- ignore the first calculation, as it is often longer than subsequent calculations
    say t
    d = d + t
end
say "average" d / n

say "interpreted"
d = 0
do i = 1 to n+1
    interpret 't=time("r");do 10000000; x = left("noël",3); end; t = time("e")'
    if i == 1 then iterate -- ignore the first calculation, as it is often longer than subsequent calculations
    say t
    d = d + t
end
say "average" d / n

say "routine"
r = .routine~new("r", 't=time("r");do 10000000; x = left("noël",3); end; t = time("e"); return t')
d = 0
do i = 1 to n+1
    t = r~call
    if i == 1 then iterate -- ignore the first calculation, as it is often longer than subsequent calculations
    say t
    d = d + t
end
say "average" d / n
