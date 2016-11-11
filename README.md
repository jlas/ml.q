<pre>
              __
   ____ ___  / /____ _
  / __ `__ \/ // __ `/
 / / / / / / // /_/ /
/_/ /_/ /_/_(_)__, /
                /_/
</pre>

Machine Learning for kdb+/q

## Examples

### k nearest neighbors

Find the n closest points to a target

    q)t:(`a`b`c!) each {3?100} each til 1000000
    q)knn[t;1 2 3;3]
    a b c dist
    ----------
    1 2 3 0
    1 2 4 1
    0 2 3 1

### k-means clustering

Find n centroids in a dataset partitioned by k-means

    q)iris:flip `sl`sw`pl`pw`class!("FFFFS";",") 0: `:iris.csv
    q)kmeans[delete class from iris;3]
    sl       sw       pl       pw
    -----------------------------------
    6.85     3.073684 5.742105 2.071053
    5.901613 2.748387 4.393548 1.433871
    5.006    3.418    1.464    0.244

Iris Dataset available here: https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data

### Decision Tree (ID3)

    q)outlook:`sunny`sunny`overcast`rain`rain`rain`overcast`sunny`sunny`rain`sunny`overcast`overcast`rain;
    q)temp:`hot`hot`hot`mild`cool`cool`cool`mild`cool`mild`mild`mild`hot`mild;
    q)humidity:`high`high`high`high`normal`normal`normal`high`normal`normal`normal`high`normal`high;
    q)wind:`weak`strong`weak`weak`weak`strong`strong`weak`weak`weak`strong`strong`weak`strong;
    q)class:`no`no`yes`yes`yes`no`yes`no`yes`yes`yes`yes`yes`no;
    q)t:([] outlook:outlook;temp:temp;humidity:humidity;wind:wind;class:class);
    q)id3[t]
