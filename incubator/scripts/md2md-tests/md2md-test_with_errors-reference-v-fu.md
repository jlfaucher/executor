level1TitlesCount = 18
line     1    line in  = A title markdown is a line starting by 1..6 # followed by 1 space or by an end-of-line.
line     1               1234567890123456789
line     1    is not a Markdown title
line     1    line out = A title markdown is a line starting by 1..6 # followed by 1 space or by an end-of-line.
line     2    line in  = 
line     2               1234567890123456789
line     2    is not a Markdown title
line     2    line out = 
line     3    line in  = Reverse order (non-sense)
line     3               1234567890123456789
line     3    is not a Markdown title
line     3    line out = Reverse order (non-sense)
line     4    line in  = ####### Level 7 (Markdown has only 6 title levels, this one is not a title, unchanged)
line     4               1234567890123456789
line     4    is not a Markdown title
line     4    line out = ####### Level 7 (Markdown has only 6 title levels, this one is not a title, unchanged)
line     5    line in  = ###### Level 6
line     5               1234567890123456789
line     5    title level 6    next = 0.0.0.0.0.1.
line     5    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line     5    line out = ###### 0.0.0.0.0.1.   Level 6
line     6    line in  = ###### Level 6
line     6               1234567890123456789
line     6    title level 6    next = 0.0.0.0.0.2.
line     6    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line     6    line out = ###### 0.0.0.0.0.2.   Level 6
line     7    line in  = ##### Level 5
line     7               1234567890123456789
line     7    title level 5    next = 0.0.0.0.1.
line     7    title level 5    startNumber = 7 , endNumber = 12 , startTitle = 7
line     7    line out = ##### 0.0.0.0.1.   Level 5
line     8    line in  = ## Level 2
line     8               1234567890123456789
line     8    title level 2    next = 0.1.
line     8    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line     8    line out = ## 0.1.   Level 2
line     9    line in  = 
line     9               1234567890123456789
line     9    is not a Markdown title
line     9    line out = 
line    10    line in  = Normal order
line    10               1234567890123456789
line    10    is not a Markdown title
line    10    line out = Normal order
line    11    line in  = 
line    11               1234567890123456789
line    11    is not a Markdown title
line    11    line out = 
line    12    line in  = # Test 1
line    12               1234567890123456789
line    12    title level 1    next = 1.
line    12    title level 1    startNumber = 3 , endNumber = 7 , startTitle = 3
line    12    line out = # 1.   Test 1
line    13    line in  = ## Level 2
line    13               1234567890123456789
line    13    title level 2    next = 1.1.
line    13    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    13    line out = ## 1.1.   Level 2
line    14    line in  = ### Level 3
line    14               1234567890123456789
line    14    title level 3    next = 1.1.1.
line    14    title level 3    startNumber = 5 , endNumber = 10 , startTitle = 5
line    14    line out = ### 1.1.1.   Level 3
line    15    line in  = #### Level 4
line    15               1234567890123456789
line    15    title level 4    next = 1.1.1.1.
line    15    title level 4    startNumber = 6 , endNumber = 11 , startTitle = 6
line    15    line out = #### 1.1.1.1.   Level 4
line    16    line in  = ##### Level 5
line    16               1234567890123456789
line    16    title level 5    next = 1.1.1.1.1.
line    16    title level 5    startNumber = 7 , endNumber = 12 , startTitle = 7
line    16    line out = ##### 1.1.1.1.1.   Level 5
line    17    line in  = ###### Level 6
line    17               1234567890123456789
line    17    title level 6    next = 1.1.1.1.1.1.
line    17    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line    17    line out = ###### 1.1.1.1.1.1.   Level 6
line    18    line in  = ####### Level 7
line    18               1234567890123456789
line    18    is not a Markdown title
line    18    line out = ####### Level 7
line    19    line in  = ###### Level 6
line    19               1234567890123456789
line    19    title level 6    next = 1.1.1.1.1.2.
line    19    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line    19    line out = ###### 1.1.1.1.1.2.   Level 6
line    20    line in  = ###### Level 6
line    20               1234567890123456789
line    20    title level 6    next = 1.1.1.1.1.3.
line    20    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line    20    line out = ###### 1.1.1.1.1.3.   Level 6
line    21    line in  = ##### Level 5
line    21               1234567890123456789
line    21    title level 5    next = 1.1.1.1.2.
line    21    title level 5    startNumber = 7 , endNumber = 12 , startTitle = 7
line    21    line out = ##### 1.1.1.1.2.   Level 5
line    22    line in  = ## Level 2
line    22               1234567890123456789
line    22    title level 2    next = 1.2.
line    22    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    22    line out = ## 1.2.   Level 2
line    23    line in  = 
line    23               1234567890123456789
line    23    is not a Markdown title
line    23    line out = 
line    24    line in  = # Test 2
line    24               1234567890123456789
line    24    title level 1    next = 2.
line    24    title level 1    startNumber = 3 , endNumber = 7 , startTitle = 3
line    24    line out = # 2.   Test 2
line    25    line in  = ## Level 2
line    25               1234567890123456789
line    25    title level 2    next = 2.1.
line    25    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    25    line out = ## 2.1.   Level 2
line    26    line in  = ### Level 3
line    26               1234567890123456789
line    26    title level 3    next = 2.1.1.
line    26    title level 3    startNumber = 5 , endNumber = 10 , startTitle = 5
line    26    line out = ### 2.1.1.   Level 3
line    27    line in  = #### Level 4
line    27               1234567890123456789
line    27    title level 4    next = 2.1.1.1.
line    27    title level 4    startNumber = 6 , endNumber = 11 , startTitle = 6
line    27    line out = #### 2.1.1.1.   Level 4
line    28    line in  = ##### Level 5
line    28               1234567890123456789
line    28    title level 5    next = 2.1.1.1.1.
line    28    title level 5    startNumber = 7 , endNumber = 12 , startTitle = 7
line    28    line out = ##### 2.1.1.1.1.   Level 5
line    29    line in  = ###### Level 6
line    29               1234567890123456789
line    29    title level 6    next = 2.1.1.1.1.1.
line    29    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line    29    line out = ###### 2.1.1.1.1.1.   Level 6
line    30    line in  = ####### Level 7
line    30               1234567890123456789
line    30    is not a Markdown title
line    30    line out = ####### Level 7
line    31    line in  = ###### Level 6
line    31               1234567890123456789
line    31    title level 6    next = 2.1.1.1.1.2.
line    31    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line    31    line out = ###### 2.1.1.1.1.2.   Level 6
line    32    line in  = ###### Level 6
line    32               1234567890123456789
line    32    title level 6    next = 2.1.1.1.1.3.
line    32    title level 6    startNumber = 8 , endNumber = 13 , startTitle = 8
line    32    line out = ###### 2.1.1.1.1.3.   Level 6
line    33    line in  = ##### Level 5
line    33               1234567890123456789
line    33    title level 5    next = 2.1.1.1.2.
line    33    title level 5    startNumber = 7 , endNumber = 12 , startTitle = 7
line    33    line out = ##### 2.1.1.1.2.   Level 5
line    34    line in  = ## Level 2
line    34               1234567890123456789
line    34    title level 2    next = 2.2.
line    34    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    34    line out = ## 2.2.   Level 2
line    35    line in  = 
line    35               1234567890123456789
line    35    is not a Markdown title
line    35    line out = 
line    36    line in  = Some particular cases
line    36               1234567890123456789
line    36    is not a Markdown title
line    36    line out = Some particular cases
line    37    line in  = 
line    37               1234567890123456789
line    37    is not a Markdown title
line    37    line out = 
line    38    line in  = Detect the mismatch between the markdown tag and the title number (happens when manually edited)
line    38               1234567890123456789
line    38    is not a Markdown title
line    38    line out = Detect the mismatch between the markdown tag and the title number (happens when manually edited)
line    39    line in  = # 1. Level 1 or level 2?
line    39               1234567890123456789
line    39    title level 1    next = 3.
line    39    title level 1    startNumber = 3 , endNumber = 5 , startTitle = 6
line    39    line out = # 3.   Level 1 or level 2?
line    40    line in  = # 1.1. Level 1 or level 3?
line    40               1234567890123456789
line    40    title level 1    next = 4.
line    40    title level 1    startNumber = 3 , endNumber = 7 , startTitle = 8
line    40    Number of '#' incorrect? got 1 '#' for a counter level 2
line    40    line out = # 4.   Level 1 or level 3?
line    41    line in  = ## 1.1. Level 2 or level 3?
line    41               1234567890123456789
line    41    title level 2    next = 4.1.
line    41    title level 2    startNumber = 4 , endNumber = 8 , startTitle = 9
line    41    line out = ## 4.1.   Level 2 or level 3?
line    42    line in  = ## 1.1.1. Level 2 or level 4?
line    42               1234567890123456789
line    42    title level 2    next = 4.2.
line    42    title level 2    startNumber = 4 , endNumber = 10 , startTitle = 11
line    42    Number of '#' incorrect? got 2 '#' for a counter level 3
line    42    line out = ## 4.2.   Level 2 or level 4?
line    43    line in  = 
line    43               1234567890123456789
line    43    is not a Markdown title
line    43    line out = 
line    44    line in  = Ill-formed title number
line    44               1234567890123456789
line    44    is not a Markdown title
line    44    line out = Ill-formed title number
line    45    line in  = # . Level 1
line    45               1234567890123456789
line    45    title level 1    next = 5.
line    45    title level 1    startNumber = 3 , endNumber = 4 , startTitle = 5
line    45    Invalid title number: .
line    45    line out = # 5.   Level 1
line    46    line in  = # .1 Level 1
line    46               1234567890123456789
line    46    title level 1    next = 6.
line    46    title level 1    startNumber = 3 , endNumber = 5 , startTitle = 6
line    46    Invalid title number: .1
line    46    line out = # 6.   Level 1
line    47    line in  = # .1. Level 1
line    47               1234567890123456789
line    47    title level 1    next = 7.
line    47    title level 1    startNumber = 3 , endNumber = 6 , startTitle = 7
line    47    Invalid title number: .1.
line    47    line out = # 7.   Level 1
line    48    line in  = # ..1 Level 1
line    48               1234567890123456789
line    48    title level 1    next = 8.
line    48    title level 1    startNumber = 3 , endNumber = 6 , startTitle = 7
line    48    Invalid title number: ..1
line    48    line out = # 8.   Level 1
line    49    line in  = # ..1.. Level 1
line    49               1234567890123456789
line    49    title level 1    next = 9.
line    49    title level 1    startNumber = 3 , endNumber = 8 , startTitle = 9
line    49    Invalid title number: ..1..
line    49    line out = # 9.   Level 1
line    50    line in  = 
line    50               1234567890123456789
line    50    is not a Markdown title
line    50    line out = 
line    51    line in  = Ill-formed title number, no space after the number
line    51               1234567890123456789
line    51    is not a Markdown title
line    51    line out = Ill-formed title number, no space after the number
line    52    line in  = # .Level 1
line    52               1234567890123456789
line    52    title level 1    next = 10.
line    52    title level 1    startNumber = 3 , endNumber = 9 , startTitle = 3
line    52    line out = # 10.   .Level 1
line    53    line in  = # .1Level 1
line    53               1234567890123456789
line    53    title level 1    next = 11.
line    53    title level 1    startNumber = 3 , endNumber = 10 , startTitle = 3
line    53    line out = # 11.   .1Level 1
line    54    line in  = # .1.Level 1
line    54               1234567890123456789
line    54    title level 1    next = 12.
line    54    title level 1    startNumber = 3 , endNumber = 11 , startTitle = 3
line    54    line out = # 12.   .1.Level 1
line    55    line in  = # ..1Level 1
line    55               1234567890123456789
line    55    title level 1    next = 13.
line    55    title level 1    startNumber = 3 , endNumber = 11 , startTitle = 3
line    55    line out = # 13.   ..1Level 1
line    56    line in  = # ..1..Level 1
line    56               1234567890123456789
line    56    title level 1    next = 14.
line    56    title level 1    startNumber = 3 , endNumber = 13 , startTitle = 3
line    56    line out = # 14.   ..1..Level 1
line    57    line in  = 
line    57               1234567890123456789
line    57    is not a Markdown title
line    57    line out = 
line    58    line in  = Ill-formed title number
line    58               1234567890123456789
line    58    is not a Markdown title
line    58    line out = Ill-formed title number
line    59    line in  = ## . Level 2
line    59               1234567890123456789
line    59    title level 2    next = 14.1.
line    59    title level 2    startNumber = 4 , endNumber = 5 , startTitle = 6
line    59    Invalid title number: .
line    59    line out = ## 14.1.   Level 2
line    60    line in  = ## .1.1 Level 2
line    60               1234567890123456789
line    60    title level 2    next = 14.2.
line    60    title level 2    startNumber = 4 , endNumber = 8 , startTitle = 9
line    60    Invalid title number: .1.1
line    60    line out = ## 14.2.   Level 2
line    61    line in  = ## .1.1. Level 2
line    61               1234567890123456789
line    61    title level 2    next = 14.3.
line    61    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 10
line    61    Invalid title number: .1.1.
line    61    line out = ## 14.3.   Level 2
line    62    line in  = ## ..1.1 Level 2
line    62               1234567890123456789
line    62    title level 2    next = 14.4.
line    62    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 10
line    62    Invalid title number: ..1.1
line    62    line out = ## 14.4.   Level 2
line    63    line in  = ## ..1.1.. Level 2
line    63               1234567890123456789
line    63    title level 2    next = 14.5.
line    63    title level 2    startNumber = 4 , endNumber = 11 , startTitle = 12
line    63    Invalid title number: ..1.1..
line    63    line out = ## 14.5.   Level 2
line    64    line in  = 
line    64               1234567890123456789
line    64    is not a Markdown title
line    64    line out = 
line    65    line in  = Ill-formed title number, no space after the number
line    65               1234567890123456789
line    65    is not a Markdown title
line    65    line out = Ill-formed title number, no space after the number
line    66    line in  = ## .Level 2
line    66               1234567890123456789
line    66    title level 2    next = 14.6.
line    66    title level 2    startNumber = 4 , endNumber = 10 , startTitle = 4
line    66    line out = ## 14.6.   .Level 2
line    67    line in  = ## .1.1Level 2
line    67               1234567890123456789
line    67    title level 2    next = 14.7.
line    67    title level 2    startNumber = 4 , endNumber = 13 , startTitle = 4
line    67    line out = ## 14.7.   .1.1Level 2
line    68    line in  = ## .1.1.Level 2
line    68               1234567890123456789
line    68    title level 2    next = 14.8.
line    68    title level 2    startNumber = 4 , endNumber = 14 , startTitle = 4
line    68    line out = ## 14.8.   .1.1.Level 2
line    69    line in  = ## ..1.1Level 2
line    69               1234567890123456789
line    69    title level 2    next = 14.9.
line    69    title level 2    startNumber = 4 , endNumber = 14 , startTitle = 4
line    69    line out = ## 14.9.   ..1.1Level 2
line    70    line in  = ## ..1.1..Level 2
line    70               1234567890123456789
line    70    title level 2    next = 14.10.
line    70    title level 2    startNumber = 4 , endNumber = 16 , startTitle = 4
line    70    line out = ## 14.10.   ..1.1..Level 2
line    71    line in  = 
line    71               1234567890123456789
line    71    is not a Markdown title
line    71    line out = 
line    72    line in  = No title text
line    72               1234567890123456789
line    72    is not a Markdown title
line    72    line out = No title text
line    73    line in  = #
line    73               1234567890123456789
line    73    title level 1    next = 15.
line    73    title level 1    startNumber = 0 , endNumber = 0 , startTitle = 3
line    73    line out = # 15.   
line    74    line in  = ##
line    74               1234567890123456789
line    74    title level 2    next = 15.1.
line    74    title level 2    startNumber = 0 , endNumber = 0 , startTitle = 4
line    74    line out = ## 15.1.   
line    75    line in  = 
line    75               1234567890123456789
line    75    is not a Markdown title
line    75    line out = 
line    76    line in  = 4 spaces after the tag
line    76               1234567890123456789
line    76    is not a Markdown title
line    76    line out = 4 spaces after the tag
line    77    line in  = #    
line    77               1234567890123456789
line    77    title level 1    next = 16.
line    77    title level 1    startNumber = 0 , endNumber = 0 , startTitle = 3
line    77    line out = # 16.      
line    78    line in  = ##    
line    78               1234567890123456789
line    78    title level 2    next = 16.1.
line    78    title level 2    startNumber = 0 , endNumber = 0 , startTitle = 4
line    78    line out = ## 16.1.      
line    79    line in  = 
line    79               1234567890123456789
line    79    is not a Markdown title
line    79    line out = 
line    80    line in  = No space after the tag
line    80               1234567890123456789
line    80    is not a Markdown title
line    80    line out = No space after the tag
line    81    line in  = #No space
line    81               1234567890123456789
line    81    is not a Markdown title
line    81    line out = #No space
line    82    line in  = ##No space
line    82               1234567890123456789
line    82    is not a Markdown title
line    82    line out = ##No space
line    83    line in  = 
line    83               1234567890123456789
line    83    is not a Markdown title
line    83    line out = 
line    84    line in  = Title with sequences of several spaces in the middle and at the end
line    84               1234567890123456789
line    84    is not a Markdown title
line    84    line out = Title with sequences of several spaces in the middle and at the end
line    85    line in  = # Title    level    1    with    spaces    
line    85               1234567890123456789
line    85    title level 1    next = 17.
line    85    title level 1    startNumber = 3 , endNumber = 8 , startTitle = 3
line    85    line out = # 17.   Title    level    1    with    spaces    
line    86    line in  = #           Title    level    1    with    spaces    
line    86               1234567890123456789
line    86    title level 1    next = 18.
line    86    title level 1    startNumber = 13 , endNumber = 18 , startTitle = 13
line    86    line out = # 18.   Title    level    1    with    spaces    
line    87    line in  = ## Title    level    2    with    spaces    
line    87               1234567890123456789
line    87    title level 2    next = 18.1.
line    87    title level 2    startNumber = 4 , endNumber = 9 , startTitle = 4
line    87    line out = ## 18.1.   Title    level    2    with    spaces    
line    88    line in  = ##          Title    level    2    with    spaces    
line    88               1234567890123456789
line    88    title level 2    next = 18.2.
line    88    title level 2    startNumber = 13 , endNumber = 18 , startTitle = 13
line    88    line out = ## 18.2.   Title    level    2    with    spaces    
line    89    line in  = ## 1. Title    level    2    with    spaces    
line    89               1234567890123456789
line    89    title level 2    next = 18.3.
line    89    title level 2    startNumber = 4 , endNumber = 6 , startTitle = 7
line    89    Number of '#' incorrect? got 2 '#' for a counter level 1
line    89    line out = ## 18.3.   Title    level    2    with    spaces    
line    90    line in  = ## 1.       Title    level    2    with    spaces    
line    90               1234567890123456789
line    90    title level 2    next = 18.4.
line    90    title level 2    startNumber = 4 , endNumber = 6 , startTitle = 13
line    90    Number of '#' incorrect? got 2 '#' for a counter level 1
line    90    line out = ## 18.4.   Title    level    2    with    spaces    

-----------------------
End of verbose messages
-----------------------

A title markdown is a line starting by 1..6 # followed by 1 space or by an end-of-line.

Reverse order (non-sense)
####### Level 7 (Markdown has only 6 title levels, this one is not a title, unchanged)
###### 0.0.0.0.0.1.   Level 6
###### 0.0.0.0.0.2.   Level 6
##### 0.0.0.0.1.   Level 5
## 0.1.   Level 2

Normal order

# 1.   Test 1
## 1.1.   Level 2
### 1.1.1.   Level 3
#### 1.1.1.1.   Level 4
##### 1.1.1.1.1.   Level 5
###### 1.1.1.1.1.1.   Level 6
####### Level 7
###### 1.1.1.1.1.2.   Level 6
###### 1.1.1.1.1.3.   Level 6
##### 1.1.1.1.2.   Level 5
## 1.2.   Level 2

# 2.   Test 2
## 2.1.   Level 2
### 2.1.1.   Level 3
#### 2.1.1.1.   Level 4
##### 2.1.1.1.1.   Level 5
###### 2.1.1.1.1.1.   Level 6
####### Level 7
###### 2.1.1.1.1.2.   Level 6
###### 2.1.1.1.1.3.   Level 6
##### 2.1.1.1.2.   Level 5
## 2.2.   Level 2

Some particular cases

Detect the mismatch between the markdown tag and the title number (happens when manually edited)
# 3.   Level 1 or level 2?
# 4.   Level 1 or level 3?
## 4.1.   Level 2 or level 3?
## 4.2.   Level 2 or level 4?

Ill-formed title number
# 5.   Level 1
# 6.   Level 1
# 7.   Level 1
# 8.   Level 1
# 9.   Level 1

Ill-formed title number, no space after the number
# 10.   .Level 1
# 11.   .1Level 1
# 12.   .1.Level 1
# 13.   ..1Level 1
# 14.   ..1..Level 1

Ill-formed title number
## 14.1.   Level 2
## 14.2.   Level 2
## 14.3.   Level 2
## 14.4.   Level 2
## 14.5.   Level 2

Ill-formed title number, no space after the number
## 14.6.   .Level 2
## 14.7.   .1.1Level 2
## 14.8.   .1.1.Level 2
## 14.9.   ..1.1Level 2
## 14.10.   ..1.1..Level 2

No title text
# 15.   
## 15.1.   

4 spaces after the tag
# 16.      
## 16.1.      

No space after the tag
#No space
##No space

Title with sequences of several spaces in the middle and at the end
# 17.   Title    level    1    with    spaces    
# 18.   Title    level    1    with    spaces    
## 18.1.   Title    level    2    with    spaces    
## 18.2.   Title    level    2    with    spaces    
## 18.3.   Title    level    2    with    spaces    
## 18.4.   Title    level    2    with    spaces    

--------------
Errors summary
--------------

line    40    Number of '#' incorrect? got 1 '#' for a counter level 2
line    42    Number of '#' incorrect? got 2 '#' for a counter level 3
line    45    Invalid title number: .
line    46    Invalid title number: .1
line    47    Invalid title number: .1.
line    48    Invalid title number: ..1
line    49    Invalid title number: ..1..
line    59    Invalid title number: .
line    60    Invalid title number: .1.1
line    61    Invalid title number: .1.1.
line    62    Invalid title number: ..1.1
line    63    Invalid title number: ..1.1..
line    89    Number of '#' incorrect? got 2 '#' for a counter level 1
line    90    Number of '#' incorrect? got 2 '#' for a counter level 1
