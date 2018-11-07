# DBSCAN in kdb+/q

DBSCAN (Density Based Spatial Clustering of Applications with Noise) is a
clustering technique introduced at [KDD-96](http://www.aaai.org/Papers/KDD/1996/KDD96-037.pdf).

A cluster is defined to be formed by "core" points and "border" points:
 * Core points have some minimum number of points in its neighborhood
 * Border points have at least one core point in its neighborhood

The approach to DBSCAN presented here augments the original algorithm by relying on a
[Euclidean distance matrix](https://en.wikipedia.org/wiki/Euclidean_distance_matrix)
to find all neighbor points.

Then we use the [Disjoint-set data structure](https://en.wikipedia.org/wiki/Disjoint-set_data_structure)
to form the clusters by doing a `union` on pairs of collocated points.

Unfortunately this approach does not handle more than a few thousand points
and only supports a Euclidean distance metric. Future work would address these
issues.