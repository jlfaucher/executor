### Language identifier: none

#### Y combinator with memoization

```
    ::class RoutineDoer
    ::method YM
    f = self
    table = .Table~new
    return {use arg a ; return a~(a)} ~ {
        expose f table ; use arg x
        return f ~ { expose x table
                     use arg v
                     r = table[v]
                     if r <> .nil then return r
                     r = x~(x)~(v)
                     table[v] = r
                     return r
                   }
    }
```
#### Symmetric implementations of binary operators

```
    a = .array~of(10,20,30)
    100 a=                  -- ['100 10','100 20','100 30'] instead of '100 an Array'
    a 100=                  -- ['10 100','20 100','30 100']
    100 || a =              -- [10010,10020,10030]          instead of '100an Array'
    a || 100 =              -- [10100,20100,30100]
    100 - a =               -- [90, 80, 70]
    (100+200i) * a =        -- [1000+2000i, 2000+4000i, 3000+6000i]
```

### Language identifier: rexx

#### Y combinator with memoization

```rexx
    ::class RoutineDoer
    ::method YM
    f = self
    table = .Table~new
    return {use arg a ; return a~(a)} ~ {
        expose f table ; use arg x
        return f ~ { expose x table
                     use arg v
                     r = table[v]
                     if r <> .nil then return r
                     r = x~(x)~(v)
                     table[v] = r
                     return r
                   }
    }
```
#### Symmetric implementations of binary operators

```rexx
    a = .array~of(10,20,30)
    100 a=                  -- ['100 10','100 20','100 30'] instead of '100 an Array'
    a 100=                  -- ['10 100','20 100','30 100']
    100 || a =              -- [10010,10020,10030]          instead of '100an Array'
    a || 100 =              -- [10100,20100,30100]
    100 - a =               -- [90, 80, 70]
    (100+200i) * a =        -- [1000+2000i, 2000+4000i, 3000+6000i]
```

### Language identifier: rexx {executor}

#### Y combinator with memoization

```rexx {executor}
    ::class RoutineDoer
    ::method YM
    f = self
    table = .Table~new
    return {use arg a ; return a~(a)} ~ {
        expose f table ; use arg x
        return f ~ { expose x table
                     use arg v
                     r = table[v]
                     if r <> .nil then return r
                     r = x~(x)~(v)
                     table[v] = r
                     return r
                   }
    }
```
#### Symmetric implementations of binary operators

```rexx {executor}
    a = .array~of(10,20,30)
    100 a=                  -- ['100 10','100 20','100 30'] instead of '100 an Array'
    a 100=                  -- ['10 100','20 100','30 100']
    100 || a =              -- [10010,10020,10030]          instead of '100an Array'
    a || 100 =              -- [10100,20100,30100]
    100 - a =               -- [90, 80, 70]
    (100+200i) * a =        -- [1000+2000i, 2000+4000i, 3000+6000i]
```

### Language identifier: rexx {executor style=light}

#### Y combinator with memoization

```rexx {executor style=light}
    ::class RoutineDoer
    ::method YM
    f = self
    table = .Table~new
    return {use arg a ; return a~(a)} ~ {
        expose f table ; use arg x
        return f ~ { expose x table
                     use arg v
                     r = table[v]
                     if r <> .nil then return r
                     r = x~(x)~(v)
                     table[v] = r
                     return r
                   }
    }
```
#### Symmetric implementations of binary operators

```rexx {executor style=light}
    a = .array~of(10,20,30)
    100 a=                  -- ['100 10','100 20','100 30'] instead of '100 an Array'
    a 100=                  -- ['10 100','20 100','30 100']
    100 || a =              -- [10010,10020,10030]          instead of '100an Array'
    a || 100 =              -- [10100,20100,30100]
    100 - a =               -- [90, 80, 70]
    (100+200i) * a =        -- [1000+2000i, 2000+4000i, 3000+6000i]
```

### Language identifier: executor

#### Y combinator with memoization

```executor
    ::class RoutineDoer
    ::method YM
    f = self
    table = .Table~new
    return {use arg a ; return a~(a)} ~ {
        expose f table ; use arg x
        return f ~ { expose x table
                     use arg v
                     r = table[v]
                     if r <> .nil then return r
                     r = x~(x)~(v)
                     table[v] = r
                     return r
                   }
    }
```
#### Symmetric implementations of binary operators

```executor
    a = .array~of(10,20,30)
    100 a=                  -- ['100 10','100 20','100 30'] instead of '100 an Array'
    a 100=                  -- ['10 100','20 100','30 100']
    100 || a =              -- [10010,10020,10030]          instead of '100an Array'
    a || 100 =              -- [10100,20100,30100]
    100 - a =               -- [90, 80, 70]
    (100+200i) * a =        -- [1000+2000i, 2000+4000i, 3000+6000i]
```
