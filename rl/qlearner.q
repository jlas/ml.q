/
 * Q Learning is a reinforcement learning method for incrementally estimating
 * the optimal action-value function. It is an off-policy temporal difference
 * method. As such, it is model-free and uses bootstrapping.
\

\d .qlearner

/
 * Initialize the state for the learner. The state is stored in a dictionary
 * and passed back to the caller. Subsequent calls to learner functions require
 * that it be passed back.
 * @param {symbols} actions - list of action names
 * @param {symbols} states - list of state names
 * @param {float} alpha - learning rate
 * @param {float} epsilon - probability of selecting random action
 * @param {float} gamma - discount factor
\
init_learner:{[actions;states;alpha;epsilon;gamma]
 qhat:{[a;x;y] x,enlist[y]!enlist[a!count[a]#0f]}[actions] over (enlist[![`$();()]],states);
 store:(`state`action`alpha`epsilon`gamma`qhat!(first states;`;alpha;epsilon;gamma;qhat));
 store};

/
 * Selects the next action and places it in store`action
\
next_action:{[store]
 actions:cols first[store`qhat];
 action:$[store[`epsilon]<first[1?1.0];
  / retrieve actions from qhat dict so we dont have to store separately
  first 1?cols first store`qhat;
  first key asc store[`qhat][store`state]];
 store[`action]:action;
 store};

/
 * Make an observation
 * @param {float} reward - reward received for taking cur action in cur state
 * @param {symbol} newstate - newstate transitioned to
\
observe:{[store;reward;newstate]
 curstate:store[`state];
 curaction:store[`action];
 qhat:store[`qhat];
 curq:qhat[curstate][curaction];
 newq:reward + store[`gamma]*first[desc qhat[newstate]];
 newq:newq*store[`alpha] + curq*(1-store[`alpha]);
 store[`qhat]:qhat,enlist[curstate]!enlist[qhat[curstate],enlist[curaction]!enlist[newq]];
 store[`state]:newstate;
 store};
