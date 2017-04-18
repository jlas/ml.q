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

/ technical indicators
states:`momentum`volatility`upxsma`downxsma;

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
  vol:0^5 mdev log close%close[i-1],
  sma20:mavg[20;close],
  sma50:mavg[50;close],
  rtn5:-1+close[i+5]%close from t;
 t:update volatility:(med[vol] <) each vol from t;
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
 * Calculate realized returns, assumptions:
 *  - Start with exactly enough cash to purchase (at close) one share at time 0
 *  - Only valid positions are long 1 share or short 1 share
 *  - It follows that each transaction (except first) must be 2 shares
 *  - We are concerned with total return so exact qty doesnt matter
 * @param {table} data
 * @returns {table}
\
realized:{[data]
 / first record treated as a buy
 if[not first[data]`side;'"initial side should be 1b"];

 / ensure state change to get realized rtns up to last observation
 if[1=count distinct (-2#data)`side;
  data:update side:not side from data where i=-1+count[data]];

 data:select from data where side<>prev side;
 data:update qty:2, dir:-1+2*side from data;
 data:update qty:1 from data where i=0;

 data:update qtydelta:dir*qty, cashdelta:dir*qty*close from data;
 data:update netcash:1_(-\) (close[0],cashdelta), netqty:(+\) qtydelta from data;

 / return computed relative to value at time 0 i.e. close price of share
 update return:(netcash+close*netqty) % first close from data};

testhlpr_:{[store;data]
 first_:enlist[enlist[first[data],enlist[`side]!enlist[1b]]];
 policy[store] over first_,1_data};

/
 * Apply learned policies and calculate returns over test data
 * @param {dict} store - learner metadata
 * @param {table list} data - list of data slices
 * @returns {float} - total return
\
testhlpr:{[store;data]
 r:realized[testhlpr_[store;data]];
 last r[`return]};

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
 store:.qlearner.init_learner[`long`short;`side,states;lrnargs`alpha;lrnargs`epsilon;lrnargs`gamma];
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

/
 * Calculate returns on a random trading policy
 * @param {string} ticker - stock ticker for which to lookup data
\
randtest:{[ticker]
 data:get_data[ticker];
 data[`side]:1b,(count[data]-1)?01b;
 last[realized[data]]`return};
