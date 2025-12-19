A title markdown is a line starting by 1..6 # followed by 1 space or by an end-of-line.

Reverse order (non-sense)
####### Level 7 (Markdown has only 6 title levels, this one is not a title, unchanged)
###### 0.0.0.0.1.   Level 6
###### 0.0.0.0.2.   Level 6
##### 0.0.0.1.   Level 5
## 1.   Level 2

Normal order

#    Test 1
## 1.   Level 2
### 1.1.   Level 3
#### 1.1.1.   Level 4
##### 1.1.1.1.   Level 5
###### 1.1.1.1.1.   Level 6
####### Level 7
###### 1.1.1.1.2.   Level 6
###### 1.1.1.1.3.   Level 6
##### 1.1.1.2.   Level 5
## 2.   Level 2

#    Test 2
## 1.   Level 2
### 1.1.   Level 3
#### 1.1.1.   Level 4
##### 1.1.1.1.   Level 5
###### 1.1.1.1.1.   Level 6
####### Level 7
###### 1.1.1.1.2.   Level 6
###### 1.1.1.1.3.   Level 6
##### 1.1.1.2.   Level 5
## 2.   Level 2

Some particular cases

Ill-formed title number, no space after the number
#    .Level 1
#    .1Level 1
#    .1.Level 1
#    ..1Level 1
#    ..1..Level 1

Ill-formed title number, no space after the number
## 1.   .Level 2
## 2.   .1.1Level 2
## 3.   .1.1.Level 2
## 4.   ..1.1Level 2
## 5.   ..1.1..Level 2

No title text
#    
## 1.   

4 spaces after the tag
#       
## 1.      

No space after the tag
#No space
##No space

Title with sequences of several spaces in the middle and at the end
#    Title    level    1    with    spaces    
#    Title    level    1    with    spaces    
## 1.   Title    level    2    with    spaces    
## 2.   Title    level    2    with    spaces    
## 3.   Title    level    2    with    spaces    
## 4.   Title    level    2    with    spaces    
