A title markdown is a line starting by 1..6 # followed by 1 space or by an end-of-line.

Reverse order (non-sense)
####### Level 7 (Markdown has only 6 title levels, this one is not a title, unchanged)
###### Level 6
###### Level 6
##### Level 5
## Level 2

Normal order

# Test 1
## Level 2
### Level 3
#### Level 4
##### Level 5
###### Level 6
####### Level 7
###### Level 6
###### Level 6
##### Level 5
## Level 2

# Test 2
## Level 2
### Level 3
#### Level 4
##### Level 5
###### Level 6
####### Level 7
###### Level 6
###### Level 6
##### Level 5
## Level 2

Some particular cases

Ill-formed title number, no space after the number
# .Level 1
# .1Level 1
# .1.Level 1
# ..1Level 1
# ..1..Level 1

Ill-formed title number, no space after the number
## .Level 2
## .1.1Level 2
## .1.1.Level 2
## ..1.1Level 2
## ..1.1..Level 2

No title text
#
##

4 spaces after the tag
#    
##    

No space after the tag
#No space
##No space

Title with sequences of several spaces in the middle and at the end
# Title    level    1    with    spaces    
#           Title    level    1    with    spaces    
## Title    level    2    with    spaces    
##          Title    level    2    with    spaces    
