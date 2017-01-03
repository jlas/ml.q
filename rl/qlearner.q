/
 * Q Learning is a reinforcement learning method for incrementally estimating
 * the optimal action-value function. It is an off-policy temporal difference
 * method. As such, it is model-free and uses bootstrapping.
\

\d .qlearner

/
 * Initialize the state for the learner. The state is stored in a metadata dict
 * and passed back to the caller. Subsequent calls to learner functions require
 * that it be passed back.
 * @param {symbols} actions - list of action names
 * @param {symbols} states - list of state names
 * @param {float} alpha - learning rate
 * @param {float} epsilon - probability of selecting random action
 * @param {float} gamma - discount factor
\
init_learner:{[actions;states;alpha;epsilon;gamma]
 qhat:("i"$xexp[2;count[states]])#enlist[actions!count[actions]#0f];
 curstate:states!count[states]#0b;
 store:(`states`curstate`action`alpha`epsilon`gamma`qhat!(states;curstate;`;alpha;epsilon;gamma;qhat));
 store};

/
 * Helper function to initialize learner's current state
 * @param {dict} store - qlearner metadata
 * @param {dict} newstate - state to assign to learner
\
init_state:{[store;newstate]
 store[`curstate]:store[`curstate],newstate;
 store};

/
 * Select the best action for given state
 * @param {dict} store - qlearner metadata
 * @param {dict} state - state for which to lookup best action
\
best_action:{[store;state]
 first key asc store[`qhat][2 sv state[store`states]]};

/
 * Selects the next action and places it in store`action
 * @param {dict} store - qlearner metadata
\
next_action:{[store]
 actions:cols first[store`qhat];
 action:$[store[`epsilon]>first[1?1.0];
  / retrieve actions from qhat dict so we dont have to store separately
  first 1?cols first store`qhat;
  best_action[store;store[`curstate]]];
 store[`action]:action;
 store};

/
 * Make an observation
 * @param {dict} store - qlearner metadata
 * @param {float} reward - reward received for taking cur action in cur state
 * @param {dict} newstate - newstate transitioned to
\
observe:{[store;reward;newstate]
 / convert newstate dict into decimal encoding
 newstate_:2 sv newstate[store`states];
 curstate:2 sv store[`curstate][store`states];
 curaction:store[`action];
 qhat:store[`qhat];
 curq:qhat[curstate][curaction];
 newq:reward + store[`gamma]*first[desc qhat[newstate_]];
 newq:newq*store[`alpha] + curq*(1-store[`alpha]);
 newq_:qhat[curstate],enlist[curaction]!enlist[newq];
 store[`qhat]:(curstate # store[`qhat]), enlist[newq_], (1+curstate) _ store[`qhat];
 store[`curstate]:store[`curstate],newstate;
 store};
