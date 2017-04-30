\l knn.q

/
 * Randomized test case: generate random data points and compare knn lookups
 * using kdtree and vanilla knn functions.
\
test:{
 t:(`a`b`c!) each {3?10000.} each til 10000;
 fn1:.knn.kdknn[.knn.kdtree[t;cols t;5]];
 fn2:.knn.knn[t];
 points:(`a`b`c!) each {3?100} each til 100;
 / use a xasc sort since order of points with same dist is not deterministic
 cmp:{[fn1;fn2;p] (`dist`a`b`c xasc fn1[p;3])~(`dist`a`b`c xasc fn2[p;3])};
 all cmp[fn1;fn2] each points};

/
 * Simple test case: 4 data points in a tree with height 2:
 *              a
 *          /       \
 *        b           b
 *       / \         / \
 *    0 0   0 1   1 0   1 1
 *
 * At the root we branch depending on the ques.: is the a axis of the target
 * point < or >= to 1? Likewise at the 2nd level we branch based on the ques.:
 * is the b axis of the target point < or >= to 1?
\
test_simple:{
 meds:(::;(`a;1);(`b;1);(`b;1));
 leaves:(enlist[`a`b!0 0];enlist[`a`b!0 1];enlist[`a`b!1 0];enlist[`a`b!1 1]);
 kdt:`meds`leaves!(meds;leaves);
 result:([] a:0 0 1 1;b:0 1 0 1;dist:`float$(0;1;1;sqrt[2]));
 fn:.knn.kdknn[kdt;`a`b!0 0];
 / use a xasc sort since order of points with same dist is not deterministic
 cmp:{[fn;result;k] (`dist`a`b xasc fn[k])~k#result};
 all cmp[fn;result] each 1 3 4};


assert:{[c] $[c;1"Passed\n";1"Failed\n"]};
assert test[];
assert test_simple[];
exit 0;
