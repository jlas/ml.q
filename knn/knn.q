\d .knn

/
 * k nearest neighbors
 *
 * test:
 *   q)t:(`a`b`c!) each {3?100} each til 1000000
 *   q)\ts knn[t;1 1 1;5]
 *   2155 136389072
\
knn:{[t;p;k]
 dist:sqrt (+/) each xexp[;2] each (p -) each (value each t);
 min[(count t;k)] # `dist xasc update dist:dist from t}


/
 * kdtree - create a kdtree for faster knn lookup.
 *
 * Given an input table we construct the tree as such, at each level:
 *   1) Pick a column from the table
 *   2) Find the median of the values in that column
 *   3) Partition the table into two sets:
 *     - Where value of column < median
 *     - Where value of column >= median
 *   4) Repeat from 1) on the partitioned tables until target depth reached
 *
 * @param {table} t
 * @param {int} depth
 * @returns {dict} - The return value is a dictionary with keys `meds`leaves.
 *   The `meds value contains a list with medians and columns encountered at
 *   each internal node of the tree. This is a binary heap encoded list, i.e.
 *   the root is at index 1 and its left child is at 2*i and right child at
 *   2*i + 1. The `leaves value contains a list of tables, which are the
 *   partitioned tables at the lowest depth. The kdtree is a complete binary
 *   tree so the first entry corresponds to the left-most leaf and the last
 *   entry corresponds to the right-most leaf.
\
kdtree:{[t;depth]
 cols_:cols t;
 queue:enlist[t];
 / meds is binary heap encoded list, first element is dummy
 meds:enlist[::];
 leaves:();

 i:0;
 while[count queue;
  i+:1;
  curdepth:floor 2 xlog i;
  t2:queue[0];
  queue:1_queue;
  ax:cols_[curdepth mod count cols_];
  md:med t2[ax];
  meds,:enlist[(ax;md)];
  slct:md > t2[ax];
  / Create partitions
  r:(select from t2 where slct;select from t2 where not slct);
  $[curdepth < depth;queue,:r;leaves,:r]];

 `meds`leaves!(meds;leaves)};


/
 * Recursive helper for kdtree k nearest neighbor
 * @param {dict} kdtree
 * @param {dict} target point
 * @param {int} k
 * @param {int} index of binary heap encoded tree node
 * @returns {table}
\
kdknn_:{[kdt;p;k;i]
 meds:kdt`meds;
 leaves:kdt`leaves;

 / Base case, index pointing to a leaf node
 if[i >= count meds;:knn[leaves[i-count[meds]];p;k]];

 ax:meds[i][0];
 md:meds[i][1];

 / Set up the first branch to try, based on if current point is < or >= the
 / median. Also set up the alternate branch in case a closer neighbor exists
 / on the other side
 i1:2*i;
 i2:1+i1;
 if[p[ax] >= md;i1:i2;i2:-1+i1];
 nn:kdknn_[kdt;p;k;i1];

 / If not enough candidates found should try alt branch
 trygt:k > count nn;

 / If point is closer to splitting plane than any neighbor, try alt branch
 xspltplane:{[p;ax;md;n] n[`dist] >= abs p[ax] - md };
 if[not trygt;trygt:any xspltplane[p;ax;md] each nn];

 / Try alt branch
 if[trygt;nn,:kdknn_[kdt;p;k;i2]];

 / Return nearest neighbors
 min[(count nn;k)] # `dist xasc nn};


/
 * kdtree k nearest neighbors
 * @param {dict} kdtree generated with kdtree function
 * @param {dict or list} point
 * @param {int} k
 * @returns {table}
 *
 * test:
 *   q)t:(`a`b`c!) each {3?100} each til 1000000
 *   q)kdt:kdtree[t;5]
 *   q)kdknn[kdt;1 1 1;3]
\
kdknn:{[kdt;p;k]
 / Make point a dict
 if[99h<>type p;p:cols[kdt[`leaves][0]]!p];
 kdknn_[kdt;p;k;1]};
