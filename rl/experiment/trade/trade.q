/
 * Run trading experiments with market data. Assumes existence of market data
 * directory and files named with tickers, e.g. data/IBM.csv
\

\l ../../algo/qlearner.q
\l ../../model/trading.q

/ local data directory
.trading.datadir:"../../../data/";

/ number of tickers to process
ntickers:120;

/
 * Run training episodes and one test run
 * @param {string} ticker
 * @param {int} episodes
 * @returns {table}
\
singleshot:{[ticker;episodes]
 store:.qlearner.init_learner[`long`short`hold;`side,.trading.states;.5;0.01;.5];
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

getreturns:{[ticker]
 `:results/rtn1.csv 0:.h.tx[`csv;singleshot[ticker;1]];
 `:results/rtn100.csv 0:.h.tx[`csv;singleshot[ticker;100]];};

/
 * Batch functions: run a batch of experiments for multiple tickers and multiple
 * learner configurations. e.g. calling runbatch[] will train and test a learner
 * for each configuration, cross validated against each security.
 * NOTE: This may take a long time. Results are written to disk incrementally.
\

batch_:{[lrnargs]
 tickers:ntickers#ssr[;".csv";""] each value "\\ls ",.trading.datadir;
 .trading.traintest[;lrnargs;5] peach tickers};

batch:{[lrnargs]
 r:batch_[lrnargs];
 enlist[lrnargs,`return`stdev!(avg first each r;sqrt avg xexp[;2] each last each r)]};

batchwrap:{[x;y]
 r:x,batch[y];
 `:results/results.csv 0:.h.tx[`csv;r];
 r};

runbatch:{
 kparams:`alpha`epsilon`gamma`episodes;
 dparams:kparams!(
  0.1;
  0.01;
  0.75;
  1);
 params:flip kparams!flip (cross/) (dparams[kparams]);
 batchwrap over enlist[0#params],params};
