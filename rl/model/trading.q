/
 * Simplistic stock trading RL model.
 *
 * An optimal trading policy is learned by simulating trades. Buy / Sell signals
 * are calculated using simple technical strategies, e.g. momentum, moving
 * average crossing, etc. The reward signal is the returns from some time in the
 * future, e.g. 5 days.
 *
 * A learning agent undergoes cross-validated training / testing. That is, a
 * batch of market data is partitioned into, e.g. 5 different slices. One slice
 * is trained on while the others are used for testing, and this is repeated
 * so that each slice is eventually trained on.
 *
\

\d .trading

/ local data directory
datadir:"../../data/";

/ sliding window
swin:{[f;w;s] f each { 1_x,y }\[w#(type s)$0;s]};

states:`momentum`volitility`upxsma`downxsma;

/
 * Read market data csv and create technical indicators
 * @param {string} ticker - stock ticker to get data for
 * @returns {table}
\
get_data:{[ticker]
 t:1 _ flip `date`o`h`l`c`v`close!("DFFFFFF";",") 0: `$":",datadir,ticker,".csv";
 t:`date xasc t;
 t:update
  momentum:{(x>=0)} -1+close%close[i-5],
  volitility:{(x>=0)} 5 mavg -1+close%close[i-1],
  sma20:mavg[20;close],
  sma50:mavg[50;close],
  rtn5:-1+close[i+5]%close from t;
 t:update xsma:{(x>=0)-x<0} sma20-sma50 from t;
 t:update xsma:0^xsma-xsma[i-1] from t;
 t:update downxsma:.trading.swin[{any x<0};5;xsma],
  upxsma:.trading.swin[{any x>0};5;xsma] from t};

/
 * Process a single action and update reward & state
 * @param {dict} store - learner metadata
 * @param {dict} r - single record of trade data
 * @returns {dict} - learner metadata
\
learn:{[store;r]
 store:.qlearner.next_action[store];
 action:store`action;
 side:store[`curstate][`side];
 if[(action=`long)&(side=0b);side:1b];
 if[(action=`short)&(side=1b);side:0b];
 reward:$[side=0b;-1*r`rtn5;r`rtn5];
 newstate:(`side,states)!(side,r[states]);
 .qlearner.observe[store;reward;newstate]};

/
 * Applies a learned policy over market data, i.e. creates the long/short
 * inidicators in a market data table. Meant to be used as a reduce function.
 * @param {dict} store - learner metadata
 * @param {table} rprev - accumulated processed records
 * @param {dict} r - new record of trade data to process
 * @returns {table} - processed records
\
policy:{[store;rprev;r]
 prevside:last[rprev][`side];
 curstate:(`side,states)!(prevside,r[states]);
 action:.qlearner.best_action[store;curstate];
 side:prevside;
 if[(action=`long)&(prevside=0b);side:1b];
 if[(action=`short)&(prevside=1b);side:0b];
 newstate:curstate,enlist[`side]!enlist[side];
 r[`side]:side;
 rprev,r};

/
 * Calculate realized returns
 * @param {table} rprev - accumulated processed records
 * @param {dict} r - new record of trade data to process
 * @returns {table}
\
realized_:{[rprev;r]
 dir:$[1b=r[`side];1f;-1f];
 r[`cash]:last[rprev][`cash]-2*dir*r[`close];
 r[`return]:(r[`cash]+dir*r[`close])%first[rprev][`close];
 rprev,r};

/
 * Calculate realized returns
 * @param {table} data
 * @returns {table}
\
realized:{[data]
 r:select from data where side<>side[i-1];
 first_:enlist[enlist[first[r],`cash`return!0 1f]];
 realized_ over first_,1_r};

testhlpr_:{[store;data]
 first_:enlist[enlist[first[data],enlist[`side]!enlist[0b]]];
 policy[store] over first_,1_data};

/
 * Apply learned policies and calculate returns over test data
 * @param {dict} store - learner metadata
 * @param {table list} data - list of data slices
 * @returns {float} - total return
\
testhlpr:{[store;data]
 r:realized[testhlpr_[store;data]];
 r:last r[`return];
 $[null r;1f;r]};

/
 * Train a learner for one "episode" i.e. for an entire market data slice
 * @param {dict} store - learner metadata
 * @param {table} train - training data
 * @returns {dict} - learner metadata
\
trainiter:{[store;train]
 store:.qlearner.init_state[store;(`side,states)!(0b,first[train][states])];
 train:1 _ train;
 / TODO using , was finicky without empty list at end
 learn over -1_enlist[store],train,enlist[]};

/
 * Apply a train & test cycle for one set of cross-validation slices
 * @param {dict} lrnargs - learner parameters
 * @param {table list} slices - list of data slices
 * @param {list} islice - list of indices for slices list
 * @returns {list} - total return for each slice
\
traintesthlpr:{[lrnargs;slices;islice]
 store:.qlearner.init_learner[`long`short`hold;`side,states;lrnargs`alpha;lrnargs`epsilon;lrnargs`gamma];
 / first slice is the training set
 train:slices[first islice];
 / train for a variable number of episodes
 i:-1;
 while[lrnargs[`episodes]>i+:1;store:trainiter[store;train]];
 testhlpr[store] each slices[1 _ islice]};

/
 * Do a complete cross-validation train & test procedure
 * @param {string} ticker - stock ticker for which to lookup data
 * @param {dict} lrnargs - learner parameters
 * @param {int} cv - number of cross validation slices to use
 * @returns {list} - total return for each cross validation slice
\
traintest:{[ticker;lrnargs;cv]
 data:get_data[ticker];
 slicefn:{[d;part;offset] step:("i"$count[d]%part); step#(step*offset)_d};
 slices:slicefn[data;cv] each til cv;
 islices:{[cv_;i] (i+til cv_) mod cv_}[cv] each til cv;
 r:(,/) traintesthlpr[lrnargs;slices] each islices;
 r};
