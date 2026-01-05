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
