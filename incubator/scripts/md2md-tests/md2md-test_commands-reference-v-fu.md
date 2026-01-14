level1TitlesCount = 8
line     1    line in  = # <!--no number-->Level 1, no number
line     1               1234567890123456789
line     1    title level 1    rawCommand = <!--no number-->L
line     1    line out = # <!--no number-->Level 1, no number
line     2    line in  = 
line     2               1234567890123456789
line     2    is not a Markdown title
line     2    line out = 
line     3    line in  = # Level 1
line     3               1234567890123456789
line     3    title level 1    next = 1.
line     3    title level 1    startNumber = 3 , endNumber = 8 , startTitle = 3
line     3    line out = # 1.   Level 1
line     4    line in  = ## Level 2
line     4               1234567890123456789
line     4    title level 2    next = 1.1.
line     4    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line     4    line out = ## 1.1.   Level 2
line     5    line in  = ### Level 3
line     5               1234567890123456789
line     5    title level 3    next = 1.1.1.
line     5    title level 3    startNumber = 5 , endNumber = 10 , startTitle = 5
line     5    line out = ### 1.1.1.   Level 3
line     6    line in  = #### Level 4
line     6               1234567890123456789
line     6    title level 4    next = 1.1.1.1.
line     6    title level 4    startNumber = 6 , endNumber = 11 , startTitle = 6
line     6    line out = #### 1.1.1.1.   Level 4
line     7    line in  = ##### Level 5
line     7               1234567890123456789
line     7    title level 5    next = 1.1.1.1.1.
line     7    title level 5    startNumber = 7 , endNumber = 12 , startTitle = 7
line     7    line out = ##### 1.1.1.1.1.   Level 5
line     8    line in  = ###### Level 6
line     8               1234567890123456789
line     8    title level 6    next = 1.1.1.1.1.1.
line     8    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line     8    line out = ###### 1.1.1.1.1.1.   Level 6
line     9    line in  = ####### Level 7
line     9               1234567890123456789
line     9    is not a Markdown title
line     9    line out = ####### Level 7
line    10    line in  = ###### <!--no_number-->Level 6, no number
line    10               1234567890123456789
line    10    title level 6    rawCommand = <!--no_number-->L
line    10    line out = ###### <!--no_number-->Level 6, no number
line    11    line in  = ###### Level 6
line    11               1234567890123456789
line    11    title level 6    next = 1.1.1.1.1.2.
line    11    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line    11    line out = ###### 1.1.1.1.1.2.   Level 6
line    12    line in  = ##### Level 5
line    12               1234567890123456789
line    12    title level 5    next = 1.1.1.1.2.
line    12    title level 5    startNumber = 7 , endNumber = 12 , startTitle = 7
line    12    line out = ##### 1.1.1.1.2.   Level 5
line    13    line in  = ## Level 2
line    13               1234567890123456789
line    13    title level 2    next = 1.2.
line    13    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    13    line out = ## 1.2.   Level 2
line    14    line in  = ## <!--reset-->Level 2, reset
line    14               1234567890123456789
line    14    title level 2    rawCommand = <!--reset-->L
line    14    title level 2    next = 1.1.
line    14    title level 2    startNumber = 4 , endNumber = 21 , startTitle = 4
line    14    line out = ## 1.1.   <!--reset-->Level 2, reset
line    15    line in  = ## Level 2
line    15               1234567890123456789
line    15    title level 2    next = 1.2.
line    15    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    15    line out = ## 1.2.   Level 2
line    16    line in  = ### Level 3
line    16               1234567890123456789
line    16    title level 3    next = 1.2.1.
line    16    title level 3    startNumber = 5 , endNumber = 10 , startTitle = 5
line    16    line out = ### 1.2.1.   Level 3
line    17    line in  = ### <!--no-number-->Level 3, no number
line    17               1234567890123456789
line    17    title level 3    rawCommand = <!--no-number-->L
line    17    line out = ### <!--no-number-->Level 3, no number
line    18    line in  = ### Level 3
line    18               1234567890123456789
line    18    title level 3    next = 1.2.2.
line    18    title level 3    startNumber = 5 , endNumber = 10 , startTitle = 5
line    18    line out = ### 1.2.2.   Level 3
line    19    line in  = ## Level 2
line    19               1234567890123456789
line    19    title level 2    next = 1.3.
line    19    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    19    line out = ## 1.3.   Level 2
line    20    line in  = ### Level 3
line    20               1234567890123456789
line    20    title level 3    next = 1.3.1.
line    20    title level 3    startNumber = 5 , endNumber = 10 , startTitle = 5
line    20    line out = ### 1.3.1.   Level 3
line    21    line in  = ## <!--reset-->
line    21               1234567890123456789
line    21    title level 2    rawCommand = <!--reset--> 
line    21    title level 2    next = 1.1.
line    21    title level 2    startNumber = 4 , endNumber = 16 , startTitle = 4
line    21    line out = ## 1.1.   <!--reset-->
line    22    line in  = ### Level 3
line    22               1234567890123456789
line    22    title level 3    next = 1.1.1.
line    22    title level 3    startNumber = 5 , endNumber = 10 , startTitle = 5
line    22    line out = ### 1.1.1.   Level 3
line    23    line in  = ## Level 2
line    23               1234567890123456789
line    23    title level 2    next = 1.2.
line    23    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    23    line out = ## 1.2.   Level 2
line    24    line in  = ### Level 3
line    24               1234567890123456789
line    24    title level 3    next = 1.2.1.
line    24    title level 3    startNumber = 5 , endNumber = 10 , startTitle = 5
line    24    line out = ### 1.2.1.   Level 3
line    25    line in  = 
line    25               1234567890123456789
line    25    is not a Markdown title
line    25    line out = 
line    26    line in  = 
line    26               1234567890123456789
line    26    is not a Markdown title
line    26    line out = 
line    27    line in  = # <!--nonumber-->Level 1, no number
line    27               1234567890123456789
line    27    title level 1    rawCommand = <!--nonumber-->L
line    27    line out = # <!--nonumber-->Level 1, no number
line    28    line in  = # <!--no.number-->Level 1, no number
line    28               1234567890123456789
line    28    title level 1    rawCommand = <!--no.number-->L
line    28    line out = # <!--no.number-->Level 1, no number
line    29    line in  = # <!--no:number-->Level 1, no number
line    29               1234567890123456789
line    29    title level 1    rawCommand = <!--no:number-->L
line    29    line out = # <!--no:number-->Level 1, no number
line    30    line in  = 
line    30               1234567890123456789
line    30    is not a Markdown title
line    30    line out = 
line    31    line in  = # Level 1
line    31               1234567890123456789
line    31    title level 1    next = 2.
line    31    title level 1    startNumber = 3 , endNumber = 8 , startTitle = 3
line    31    line out = # 2.   Level 1
line    32    line in  = ## Level 2
line    32               1234567890123456789
line    32    title level 2    next = 2.1.
line    32    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    32    line out = ## 2.1.   Level 2
line    33    line in  = ### Level 3
line    33               1234567890123456789
line    33    title level 3    next = 2.1.1.
line    33    title level 3    startNumber = 5 , endNumber = 10 , startTitle = 5
line    33    line out = ### 2.1.1.   Level 3
line    34    line in  = 
line    34               1234567890123456789
line    34    is not a Markdown title
line    34    line out = 
line    35    line in  = # <!--unknown_command-->Unknown command
line    35               1234567890123456789
line    35    title level 1    rawCommand = <!--unknown_command-->U
line    35    Unknown command: unknowncommand
line    35    title level 1    next = 3.
line    35    title level 1    startNumber = 3 , endNumber = 32 , startTitle = 3
line    35    line out = # 3.   <!--unknown_command-->Unknown command
line    36    line in  = 
line    36               1234567890123456789
line    36    is not a Markdown title
line    36    line out = 
line    37    line in  = # <not_a_command>Not a command
line    37               1234567890123456789
line    37    title level 1    next = 4.
line    37    title level 1    startNumber = 3 , endNumber = 21 , startTitle = 3
line    37    line out = # 4.   <not_a_command>Not a command

-----------------------
End of verbose messages
-----------------------

# <!--no number-->Level 1, no number

# 1.   Level 1
## 1.1.   Level 2
### 1.1.1.   Level 3
#### 1.1.1.1.   Level 4
##### 1.1.1.1.1.   Level 5
###### 1.1.1.1.1.1.   Level 6
####### Level 7
###### <!--no_number-->Level 6, no number
###### 1.1.1.1.1.2.   Level 6
##### 1.1.1.1.2.   Level 5
## 1.2.   Level 2
## 1.1.   <!--reset-->Level 2, reset
## 1.2.   Level 2
### 1.2.1.   Level 3
### <!--no-number-->Level 3, no number
### 1.2.2.   Level 3
## 1.3.   Level 2
### 1.3.1.   Level 3
## 1.1.   <!--reset-->
### 1.1.1.   Level 3
## 1.2.   Level 2
### 1.2.1.   Level 3


# <!--nonumber-->Level 1, no number
# <!--no.number-->Level 1, no number
# <!--no:number-->Level 1, no number

# 2.   Level 1
## 2.1.   Level 2
### 2.1.1.   Level 3

# 3.   <!--unknown_command-->Unknown command

# 4.   <not_a_command>Not a command

--------------
Errors summary
--------------

line    35    Unknown command: unknowncommand
