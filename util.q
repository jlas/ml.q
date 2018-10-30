/
 * Identity matrix
\
ident:{[n] {(x#0),1,(y-x+1)#0}[;n] each til n}

/
 * Extract diagonal from a matrix
\
diag:{(x .) each til[count x],'til count[x]}

/
 * Euclidean distance matrix (edm)
 * See https://arxiv.org/abs/1502.07541
\
edm:{m:x mmu flip[x]; diag[m] + flip diag[m] - 2*m}

/
 * Look up d[i], then look up d[j] for each j in d[i], and so on...
 * @param {dict} d
 * @param {any} i - first key to look up
\
recursive_flatten:{[d;i]
 x:enlist i;
 prevx:0N;
 while[not prevx ~ x:distinct x,(,/) d each x; prevx:x];
 x}

/
 * Disjoint-set data structure and algo
 * Returns a dict where each key either has
 *  - A single entry, the parent of the node
 *  - Multiple entries, the children of the node
 * @param {dict} d
 * @param {list} l - two keys to join
\
dj:{[d;l]
 / Find all children to merge recursively
 rf:recursive_flatten[d;] each l;

 / Count, sort, then select index of node with hightest num of children from
 / each flattened list
 idx:first each idesc each ((count each d) each) each rf;

 / For each flattened list select actual node from index
 roots:(((rf) .) each) (til count idx),'idx;
 idx:idesc count each d each roots;

 / Root is the node with most children
 root:first roots idx;

 / Update preferred root with new children
 children:((,/)rf) except root;
 d[root]:distinct d[root],children;
 / Update children with new root
 d,children!enlist each count[children]#root}
