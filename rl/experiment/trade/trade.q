/
 * Run trading experiments with market data. Assumes existence of market data
 * directory and files named with tickers, e.g. data/IBM.csv
\

\l ../../algo/qlearner.q
\l ../../model/trading.q

/ local data directory
.trading.datadir:"../../../data/";

/ number of tickers to process
ntickers:500;

/
 * Run training episodes and one test run
 * @param {string} ticker
 * @param {int} episodes
 * @returns {table}
\
singleshot:{[ticker;episodes]
 store:.qlearner.init_learner[`long`short`hold;`side,.trading.states;.3;0.1;.3];
 data:.trading.get_data[ticker];
 / partition half-half train / test
 part:("i"$count[data]%2);
 train:part#data;
 test:part _ data;
 i:-1;
 while[episodes>i+:1;store:.trading.trainiter[store;train]];
 r:.trading.testhlpr_[store;test];
 r2:.trading.realized[r];
 r:update return:1f^fills return, bhreturn:1f^close%close[0] from r lj `date xkey r2;
 select date,return,bhreturn from r};

/ Train and test and write out the top N runs to disk
getreturns:{[ticker;topcnt]
 r:{singleshot["IBM";100]} peach til 100;
 top:r[topcnt#idesc {last[x]`return} each r];
 r:([] date:first[top]`date;bhreturn:first[top]`bhreturn);
 r:{[r;x] r[`$("rtn",string[first 1#x])]:(1_x)`return;r} over enlist[r],til[count[top]],'top;
 `:results/rtntop.csv 0:.h.tx[`csv;r];};

/
 * Batch functions: run a batch of experiments for multiple tickers and multiple
 * learner configurations. e.g. calling runbatch[] will train and test a learner
 * for each configuration, cross validated against each security.
 * NOTE: This may take a long time. Results are written to disk incrementally.
\

batch_:{[lrnargs]
 tickers:ntickers#ssr[;".csv";""] each value "\\ls ",.trading.datadir;
 ({enlist[`$x]} each tickers),'.trading.traintest[;lrnargs;5] peach tickers};

batch:{[lrnargs]
 fn:{rtns:1_x; ([] ticker:count[rtns]#first[x]; returns:rtns)};
 (lrnargs,) each (,/) fn each batch_[lrnargs]};

batchwrap:{[x;y]
 r:x,batch[y];
 `:results/results.csv 0:.h.tx[`csv;r];
 r};

runbatch:{
 kparams:`alpha`epsilon`gamma`episodes;
 dparams:kparams!(
  .1 * 1 _ til 10;
  0.1;
  .1 * 1 _ til 10;
  100);
 params:flip kparams!flip (cross/) (dparams[kparams]);
 batchwrap over enlist[0#params],params};
