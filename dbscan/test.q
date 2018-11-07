\l dbscan.q

/
 * Test a known collection of points
\
test:{
 t:value each flip `x`y!("FF";",") 0: `$"test.csv";
 all dbscan[t;3;.5] = 0 1 1 1 2 2 1 2 -1 0 0 2 1 0 2 1 -1 -1 1 0}

assert:{[c] $[c;1"Passed\n";1"Failed\n"]};
assert test[];
exit 0;
