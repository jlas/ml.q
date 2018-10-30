\l ../util.q

/
 * dbscan clustering - returns cluster indices where -1 = noise
 * See https://en.wikipedia.org/wiki/DBSCAN
 *
 * @param t {table}
 * @param {int} minpts - a point is a core point if at least minpts number of
 *  points are within distance epsilon
 * @param {float} epsilon - radius of reachability
\
dbscan:{[t;minpts;epsilon]
 dist:xexp[edm[t];0.5];
 dist_filt:epsilon >= dist + 0Wj * ident[count dist];
 core:(1 + til count dist) * minpts <= 1 + sum each dist_filt;
 dist_filt*:(1 + til count dist);

 / Get reachable core points for each point
 r:except[;0] each inter[core;] each flip dist_filt;
 / Add index
 r:(1 + til count dist),'r;
 / Build dict with index as key
 d:(first each r)!((1_) each r);

 / Run disjoint set algo to combine core points
 djargs:(,/) {[d;x] x,'d[x]}[d;] each key d;
 d:dj over enlist[d],djargs;

 / Make root keys point to themselves
 root_keys:key[d] where 1 < count each d each key d;
 d:d,root_keys!enlist each root_keys;

 / Make noise cluster and assign as default
 d:((1 + til count t)!enlist each count[t]#-1),d;

 / Get cluster assignments
 d:first each d each (1 + til count t);

 / Normalize cluster numbers to 0, 1, 2 ...
 k:asc distinct d;
 (k!-1 + til count k) each d}
