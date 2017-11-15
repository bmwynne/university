# Project 3
# Angely Brandon Rodrigo

For Project 3, we were asked to update a line intersection interface. For BST.py, we were given a BSTNode, which had a key, left and right value. We were also given a function, less_than, which returned a Boolean value. The class BinarySearchTree, which has a root, parents, and function less. 

For insert, we are putting in the key into the tree. First, we check if the given root is not there, and in that case, we assign the root to be a new BSTNode with the value k, which automatically assigns left and right to None. In the case that the root exisits, we check to see if the key of the node is k, and if it is, then we can just return the node. If it isn't k, then we check to see if k is less than node.key, and if that is true, then we check if it has a left node, and if not, we made a newNode that was a BSTNode with the value k. Otherwise, we made the node equal to the left of the node. This method was mirrored on the right side.

For successor, we were trying to return the smallest key greater than the n.key (n was passed in). First, we searched to see if the key of the node exists, and if not, returned None. We then assigned node to equal the root and made a new variable, smallest assigned to None. We then made a while loop that holds if node is not None, and checkes if n.key is less than node.key, and then check if smallest is None or node.key is smaller than smaller.key, and if so, we made smallest equal to the node. 

For predecessor, we took the same idea that we had for successor and implemented it with respect to the largest, rather than the smallest.

For search, we checked if the root is None, and while it is not none, we created a variable node, and assigned the root to that variable. Then, if node.key is equal to the search value, we return node, otherwise we check to see if the the search value is less than the key of the node, and if so, we assigned node to the smaller value (node.left) and if not we assigned node to the larger value (node.right). Search returns None. 

For get_parent, we used a while loop to check if the left or right of the node is the passed in variable n, or assign the node equal to the left or right depending on if the key of n is less than the key of the node. We initially checked, using search, to see if the key of n is None or if n is the root of self. 

For delete_node, we searched for the passed in node's key, and then if p is not None, then we checked if p has left or right nodes, which in that case we set the boolean, twoChildren, to be True and False if not it does have have a right or left node. If twoChildren turned out to be False, we assigned child to be the left of p and if there is no left of p, then child is assigned to be right of p. We assigned the parent by using the get_parent function on child. If the p has twoChildren, then we assigned r to be the predecesor of child and parent to be the get_parent of r.


For AVLTree.py, we were asked to write a balanced tree. We used some of the functions that we made earlier, such as search, predecesor, and sucessor. We used some of the same logic from BST until the point where we were checking if k is less than node.key, which is where the AVL logic began. If k is less than node.key and the node does not have left or right children, and the node does not have a parent, then we created a new AVLNode and assigned the left of the node to the new node, which is then returned. We had to keep in mind the heights of the trees, to make sure that they are balanced. From there, we had to determine if we needed to preform a single or double rotation. In the case of a single rotation we would insert the node and then make the parent of the node the parent of the parent and then move the, then parent of the node to the other side of the node. 




