--::options trace i
::requires "concurrency/coactivity.cls"

--------------------------------------------------------------------------------
/*
An example of generator (recursive method).

The binary tree stores values in nodes.
Each node holds a value.
Each node has a reference to a node on the left and a reference to a node on the right.
Values smaller than current node's value are stored in the left-side subtree, and larger values are stored in the right-side subtree.

myBinaryTree = .BinaryTree~of(4, 6, 2, 7, 5, 3, 1)
do o over myBinaryTree~ascendingValues
    say o
end
-- display 1, 2, 3, 4, 5, 6, 7
*/


::class Node private

::attribute leftNode
::attribute rightNode
::attribute value

::method init
    self~leftNode = .nil
    self~rightNode = .nil
    self~value = .nil

::method insert
    use strict arg value
    select
        when self~value == .nil then do
            self~value = value
        end
        when value < self~value then do
            if self~leftNode == .nil then self~leftNode = .Node~new
            self~leftNode~insert(value)
        end
        otherwise do
            if self~rightNode == .nil then self~rightNode = .Node~new
            self~rightNode~insert(value)
        end
    end
    
::method visitAscending
    -- No need of yieldFrom à la Python... Yield from inner invocations is supported.
    if self~leftNode <> .nil then self~leftNode~visitAscending
    .yield[self~value]
    if self~rightNode <> .nil then self~rightNode~visitAscending

::method visitDescending
    -- No need of yieldFrom à la Python... Yield from inner invocations is supported.
    if self~rightNode <> .nil then self~rightNode~visitDescending
    .yield[self~value]
    if self~leftNode <> .nil then self~leftNode~visitDescending


::class BinaryTree public

::method of class
    use strict arg value, ...
    binaryTree = .BinaryTree~new
    do i = 1 to arg()
        binaryTree~insert(arg(i))
    end
    return binaryTree

::attribute rootNode

::method init
    self~rootNode = .Node~new

::method insert
    use strict arg value
    self~rootNode~insert(value)

::method ascendingValues
    return .Coactivity~new("visitAscending", , self~rootNode)

::method descendingValues
    return .Coactivity~new("visitDescending", , self~rootNode)


/*
To illustrate the difference between a stackful coroutine and the limited support in Python
(can yield only to its immediate caller).
http://www.cosc.canterbury.ac.nz/greg.ewing/python/yield-from/yf_current/Examples/binary_tree.py


#
#   Here is a binary tree that produces an inorder traversal
#   of its items when iterated over. (Courtesy of Scott Dial)
#

class BinaryTree:
  def __init__(self, left=None, us=None, right=None):
    self.left = left
    self.us = us
    self.right = right

  def __iter__(self):
    if self.left:
      yield from self.left
    if self.us:
      yield self.us
    if self.right:
      yield from self.right

#
#   For comparison, here is the same thing using for-loops
#   instead of yield-from.
#

class BinaryTree_ForLoop:
  def __init__(self, left=None, us=None, right=None):
    self.left = left
    self.us = us
    self.right = right

  def __iter__(self):
    if self.left:
      for node in self.left:
        yield node
    if self.us:
      yield self.us
    if self.right:
      for node in self.right:
        yield node
*/

