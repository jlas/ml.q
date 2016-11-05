/
 * k nearest neighbors
 *
 * test:
 *   q)t:(`a`b`c!) each {3?100} each til 1000000
 *   q)\ts knn[t;1 1 1;5]
 *   2155 136389072
 *
 * iris test:
 *   q)iris:flip `sl`sw`pl`pw`class!("FFFFS";",") 0: `:iris.csv
 *   q)\ts kmeans[delete class from iris;3]
 *   25 77184
\
knn:{[t;p;k]
 dist:sqrt (+/) each xexp[;2] each (p -) each (value each t);
 k # `dist xasc update dist:dist from t}

/
 * k means clustering
\
hlpr:{[t;k;means]
 f:{[t;x] sqrt (+/) each xexp[;2] each (x -) each (value each t)};
 r:f[t;] each means;
 zipped:{[k;x] (til k) ,' x}[k;] each flip r;
 cluster:first flip ({$[last x < last y;x;y]} over) each zipped;
 / 1st column keeps count
 m2::(k;(1+count t[0]))#0;
 {m2[first x]+:1,1 _ x} each cluster ,' value each t;
 m2::flip m2;
 (flip 1 _ m2) % first m2}

kmeans:{[t;k]
 means:t[k?count t];
 diff:(k;count t[0])#1;
 while[any any diff;
  omeans:means;
  means:hlpr[t;k;means];
  diff:0.01<abs omeans-means];
 flip (cols t)!flip means}

/masks:{(x =) each cluster} each til k;
/(sum flip r * masks) % sum flip masks}

entropy:{
 cnt:sum x;
 p:x%cnt;
 -1*sum p*xlog[2;p]}

/
 * t is table where 1st col is attribute and remaining cols are class counts
 * for each value in attribute, e.g.
 *
 * attr1 class1 class2
 * -------------------
 * 0     25     75
 * 1     33     67
 * ...
 *
 * cls is list of classes e.g. `class1`class2
 * clscnt is list of occurances of each class
 * setcnt is count of instances
\
ighlpr:{[t;cls;clscnt;setcnt]
 e:entropy each flip t[cls];
 p:(sum each flip t[cls])%setcnt;
 entropy[clscnt] - sum e*p}

/
 * test:
 *   / random integers with class labels:
 *   q)t:flip (`a`b`c`class!) flip {(3?100),1?`A`B`C} each til 10000
 *   q)infogain[t] each `a`b`c
 *   0.01451189 0.01573281 0.01328462
\
infogain:{[tbl;attrib]
 cls:exec distinct class from tbl;
 clscnt:(exec count i by class from tbl)[cls];
 setcnt:count tbl;
 d:distinct tbl[attrib];

 / change attrib colname for ease of use with select syntax
 t2:(`a xcol attrib xcols select from tbl);
 t2:select count i by a, class from t2;
 / create empty table to hold pivot
 t3:flip (`a,cls)!(enlist[d],{[d;x]count[d]#0}[d;] each til count cls);
 / pivot t2, change class column to a column per class value
 t3:{x lj `a xkey flip (`a,y[`class])!(enlist y[`a];enlist y[`x])} over (enlist t3),0!t2;
 ighlpr[t3;cls;clscnt;setcnt]}
