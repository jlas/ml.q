# Examples

## Trading

    q)store:.qlearner.init_learner[`long`short;`side,.trading.states;0.9;0.1;0.9];
    q)data:.trading.get_data["IBM"];
    q)train:500#data;
    q)test:500_data;
    q)store:.qlearner.init_state[store;(`side,.trading.states)!(0b,first[train][.trading.states])];
    q)store:.trading.learn over -1_enlist[store],1_train,enlist[];
    q)r:.trading.realized[.trading.testhlpr_[store;test]];
    q)select date, return from r
    date       return
    --------------------
    2002.01.31 1
    2002.02.01 1.000964
    2002.02.20 1.08021
    2002.02.27 1.066395
    2002.04.01 1.019704
    2002.04.10 0.8911973
    ..
