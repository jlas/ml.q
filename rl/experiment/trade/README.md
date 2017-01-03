# QLearning applied to trading

Here we present an approach to behaving optimally in a trading environment. We
model such an environment with some simplifying assumptions:

 * There is only one opportunity to trade per day which must be done by paying
 the `close` price provided by historical market data.
 * An agent either has a long or short position in one security. The exact
 number of shares is made irrelevent by using cumulative returns.
 * No transaction costs are taken into account.

## Training

To train an agent using the QLearning method we first determine an indicative
set of signals to represent the lucrative potential of moving stock prices. e.g.
price momentum, volatility, moving average crossings are used. These values are
encoded into a bitfield state value.

The QLearning algorithm is completely agnostic to the trading environment. The
abstract state values are simply numbers (encoded bitfields) which the algorithm
uses to track the perceived values of buying or selling while in any one state.

An agent is trained using a cross-validated approach, whereby the market data
is sliced into, e.g. 5, equally sized portions. The agent is trained on one
portion and its performance is then tested against the remaining 4. This process
is repeated until each slice acts as the training set. The performance numbers
are averaged.

For each slice training occurs over multiple "episodes". An episode iterates
through records in the training set until exhausted. Episodes are a tunable
parameter and we examine the effect of different values.

## Performance

Performance results are the averaged total returns from applying the train and
test procedure mentioned above over several unique securities.

Some initial results are presented here. While the returns are disappointing
the greater endeavor of this exercise might be to understand the behavior of
the learner parameters.

![return_120sec](https://raw.githubusercontent.com/jlas/ml.q/master/rl/experiment/trade/results/media/return_120sec.png)
