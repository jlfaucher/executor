--::options trace i
::requires "concurrency/coactivity.cls"

--------------------------------------------------------------------------------
/*
An example of generator (recursive method).

The binary tree stores items in nodes.
Each node holds a item.
Each node has a reference to a node on the left and a reference to a node on the right.
Items smaller than current node's item are stored in the left-side subtree, and larger items are stored in the right-side subtree.

myBinaryTree = .BinaryTree~of(4, 6, 2, 7, 5, 3, 1)
do o over myBinaryTree~ascendingItems
    say o
end
-- display 1, 2, 3, 4, 5, 6, 7
*/


::class Node private

::attribute leftNode
::attribute rightNode
::attribute item

::method init
    self~leftNode = .nil
    self~rightNode = .nil
    self~item = .nil

::method insert
    use strict arg item
    select
        when .nil == self~item then do
            self~item = item
        end
        when item < self~item then do
            if .nil == self~leftNode then self~leftNode = self~class~new
            self~leftNode~insert(item)
        end
        otherwise do
            if .nil == self~rightNode then self~rightNode = self~class~new
            self~rightNode~insert(item)
        end
    end

::method visitAscending
    -- No need of yieldFrom à la Python... Yield from inner invocations is supported.
    if .nil <> self~leftNode then self~leftNode~visitAscending
    .yield[self~item]
    if .nil <> self~rightNode then self~rightNode~visitAscending

::method visitDescending
    -- No need of yieldFrom à la Python... Yield from inner invocations is supported.
    if .nil <> self~rightNode then self~rightNode~visitDescending
    .yield[self~item]
    if .nil <> self~leftNode then self~leftNode~visitDescending


::class BinaryTree public

::method of class
    use strict arg item, ...
    binaryTree = .BinaryTree~new
    do i = 1 to arg()
        binaryTree~insert(arg(i))
    end
    return binaryTree

::attribute items get
-- ::attribute rootNode

::method init
    expose items rootNode
    items = 0
    rootNode = .Node~new

::method insert
    expose items rootNode
    items += 1
    forward to (rootNode)

::method ascendingItems
    expose rootNode
    return .Coactivity~new("visitAscending", , rootNode)

::method descendingItems
    expose rootNode
    return .Coactivity~new("visitDescending", , rootNode)


--------------------------------------------------------------------------------
/*
Same example as above, but using a block.
No need of .Node~visitAscending, .Node~visitDescending.

myBinaryTree = .BinaryTree2~of(4, 6, 2, 7, 5, 3, 1)
do o over myBinaryTree~ascendingItems
    say o
end
-- display 1, 2, 3, 4, 5, 6, 7
*/

::class Node2 private

::attribute leftNode
::attribute rightNode
::attribute item

::method init
    self~leftNode = .nil
    self~rightNode = .nil
    self~item = .nil

::method insert
    use strict arg item
    select
        when .nil == self~item then do
            self~item = item
        end
        when item < self~item then do
            if .nil == self~leftNode then self~leftNode = self~class~new
            self~leftNode~insert(item)
        end
        otherwise do
            if .nil == self~rightNode then self~rightNode = self~class~new
            self~rightNode~insert(item)
        end
    end


::class BinaryTree2 public

::method of class
    use strict arg item, ...
    binaryTree = self~new
    do i = 1 to arg()
        binaryTree~insert(arg(i))
    end
    return binaryTree

::attribute items get
-- ::attribute rootNode

::method init
    expose items rootNode
    items = 0
    rootNode = .Node2~new

::method insert
    expose items rootNode
    items += 1
    forward to (rootNode)

::method ascendingItems
    expose rootNode
    return {::coactivity
            expose rootNode
            use arg node=(rootNode)
            -- No need of yieldFrom à la Python... Yield from inner invocations is supported.
            -- The recursive call is done with the wrapped executable (the method on the node), not with the method itself
            if .nil <> node~leftNode then self~(node~leftNode)
            .yield[node~item]
            if .nil <> node~rightNode then self~(node~rightNode)
           }

::method descendingItems
    expose rootNode
    return {::coactivity
            expose rootNode
            use arg node=(rootNode)
            -- No need of yieldFrom à la Python... Yield from inner invocations is supported.
            -- The recursive call is done with the wrapped executable (the method on the node), not with the method itself
            if .nil <> node~rightNode then self~(node~rightNode)
            .yield[node~item]
            if .nil <> node~leftNode then self~(node~leftNode)
           }


--------------------------------------------------------------------------------
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

