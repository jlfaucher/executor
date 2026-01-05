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

Ill-formed title number, no space after the number
# 3.   .Level 1
# 4.   .1Level 1
# 5.   .1.Level 1
# 6.   ..1Level 1
# 7.   ..1..Level 1

Ill-formed title number, no space after the number
## 7.1.   .Level 2
## 7.2.   .1.1Level 2
## 7.3.   .1.1.Level 2
## 7.4.   ..1.1Level 2
## 7.5.   ..1.1..Level 2

No title text
# 8.   
## 8.1.   

4 spaces after the tag
# 9.      
## 9.1.      

No space after the tag
#No space
##No space

Title with sequences of several spaces in the middle and at the end
# 10.   Title    level    1    with    spaces    
# 11.   Title    level    1    with    spaces    
## 11.1.   Title    level    2    with    spaces    
## 11.2.   Title    level    2    with    spaces    
