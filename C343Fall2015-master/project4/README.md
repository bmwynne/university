### Partners ###
Brandon Wynne bmwynne
John Binzer jfbinzer
James Mantz jmantz

Bobby Mulligan also assisted us conceptually.

### Info ###
One of the first things we did was create a function print_matrix() that took a square matrix and its size as arguments and printed said matrix to the console. 
This was extremely helpful when attempting to code the portion to populate the matrix with scores.

Next we set up the default matrix. First we filled it with 0's and then filled in the scores along the x and y axes. (see Fig. 1 for an example of a 5x5 default matrix).

### table ###
```
0    -1    -2    -3    -4    -5
-1   0     0     0     0     0
-2   0     0     0     0     0
-3   0     0     0     0     0
-4   0     0     0     0     0
-5   0     0     0     0     0

          [Fig. 1]
```

Then we populated the matrix with scores using the algorithm Prof. Siek described during lecture. 
Once the matrix is populated with the correct scores, we create a pointer (called location_best in my program) to the bottom right corner of the matrix. 
The bottom right will always have the very best score. From there we compare the scores of three adjacent cells - to the left, to the left and above (diagonal), and above. 
We pick the best score and set our pointer equal to that location. In the diagonal case we have a perfect match, so we simply interate along our strings. 
In the case that the best score is above or to the left, we have to add a blank '_' to the correct string. 
The pointer is set equal to this cell and we iterate along the string that we DID NOT add a blank to. Finally we return the two strings with their added '_'s.