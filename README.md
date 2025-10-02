# Simulations of several strategies in multi round Prisoners Dillema

100_000 random parings with different strategies. Each pair will interact with its opponent for 30 turns. The strategies have a population size of 100_000/num_strategies each.
The random pairings determined determinisitically using a prng.

First we will look at the performance of some basic strategies. Then we will introduce some modifications to the simulation which allow us to investigate more complicated behaviour.

[1. Baseline performance](#baseline-performance)
[2. Introducing Signal Error](#signal-error)
[3. Introducing forgiveness](#introducing-forgiveness)
[4. Introducing varying levels of judgement](#introducing-varying-levels-of-judgement)

## Baseline performance

The well performing tit-for-tat strategy wins in a society with equal distribution of strategies:

Highest-scoring Prisoner of .AlwaysBetray: 296
Highest-scoring Prisoner of .TitForTatBetrayLast: 4591
Highest-scoring Prisoner of .TitForTat: 4637

Total Population Score of .AlwaysBetray: 80424
Total Population Score of .TitForTatBetrayLast: 1213375
Total Population Score of .TitForTat: 1255535

Lowest-scoring Prisoner of .AlwaysBetray: 246
Lowest-scoring Prisoner of .TitForTatBetrayLast: 3716
Lowest-scoring Prisoner of .TitForTat: 4127

Tit-for-tat wins across the board. Even the worst performing tit-for-tat prisoner is event beating the average tit-for-tat-betray last prisoner:

lowest tit-for-tat prisoner -> 4127
average tit-for-tat betray last prisoner -> 3644

Notice that betray last always performs close to tit-for-tat with the gap widening for the lower performing percentiles within a population. The lowest performing betray last prisoner doing worse by about ~400 points when compared to the lowest tit-for-tat prisoner. Among the best performing the respective gap is less than 100.

## Signal Error

After introducing signal error the over all scores are worse when compared to without signal error. Signal error -> prisoner sees betray 10% of the time when the true action was cooperate:

Highest-scoring Prisoner of .AlwaysBetray: 296
Highest-scoring Prisoner of .TitForTat: 2152
Highest-scoring Prisoner of .TitForTatBetrayLast: 2220

Total Population Score of .AlwaysBetray: 80424
Total Population Score of .TitForTatBetrayLast: 562429
Total Population Score of .TitForTat: 566907

Lowest-scoring Prisoner of .AlwaysBetray: 246
Lowest-scoring Prisoner of .TitForTat: 1762
Lowest-scoring Prisoner of .TitForTatBetrayLast: 1853

Now the gap between tit-for-tat and betray last has closed and I didn't bother to run the experiment again with a different seed to make sure that these scores are not random.
Noties that Always betray doesnt do any worse because from the perspective of its opponents it was already acting in the worst possible way.

If we increase the signal error we should expect all strategies to perform more and more like always betray. Prisoner sees opponents action as betray 30% of the time when opponent cooperated:

Highest-scoring Prisoner of .AlwaysBetray: 296
Highest-scoring Prisoner of .TitForTat: 765
Highest-scoring Prisoner of .TitForTatBetrayLast: 782

Total Population Score of .AlwaysBetray: 80424
Total Population Score of .TitForTatBetrayLast: 190623
Total Population Score of .TitForTat: 191409

Lowest-scoring Prisoner of .AlwaysBetray: 246
Lowest-scoring Prisoner of .TitForTatBetrayLast: 593
Lowest-scoring Prisoner of .TitForTat: 608

Every strategy is doing much worse now. It would be interesting to see if the performance of each of these groups is a linear function of signal error. Maybe some other time.

Increasing the signal error further to 70% we can see that always betray has prevailed and the other strategies have sunk below it across the board:

Highest-scoring Prisoner of .TitForTatBetrayLast: 273
Highest-scoring Prisoner of .TitForTat: 284
Highest-scoring Prisoner of .AlwaysBetray: 296

Total Population Score of .TitForTat: 71049
Total Population Score of .TitForTatBetrayLast: 71197
Total Population Score of .AlwaysBetray: 80424

Lowest-scoring Prisoner of .TitForTatBetrayLast: 210
Lowest-scoring Prisoner of .TitForTat: 221
Lowest-scoring Prisoner of .AlwaysBetray: 246

With a signal error of 70% the probability of seeing atleast one betrayal converges very quickly within just 2 interactions the chance of no perceived betrayal falls to about 1%. This means that

## Introducing forgiveness

The idea behind forgiveness is that in environments with imperfect information two tit-for-tat prisoners would betray eachother once one of them percieved the other betraying. This would then get them stuck in an infinite betrayal loop. A small amount of forgiveness can break this loop and stabilize two tit-for-tat strategies back to cooperating again.

Introducing the new forgiving strategy in an environment with 10% signal error yields this:

Highest-scoring Prisoner of .TitForTat: 3561
Highest-scoring Prisoner of .AlwaysBetray: 3856
Highest-scoring Prisoner of .TitForTatBetrayLast: 3976
Highest-scoring Prisoner of .TitForTat10pctForgiveness: 4858

Total Population Score of .TitForTat: 721245
Total Population Score of .AlwaysBetray: 726832
Total Population Score of .TitForTatBetrayLast: 753572
Total Population Score of .TitForTat10pctForgiveness: 1005389

Lowest-scoring Prisoner of .TitForTat: 2313
Lowest-scoring Prisoner of .AlwaysBetray: 2946
Lowest-scoring Prisoner of .TitForTatBetrayLast: 3145
Lowest-scoring Prisoner of .TitForTat10pctForgiveness: 3705

Tit-for-tat with forgiveness of 10% performs significantly better while tit-for-tat falls to last place with obviously malicious strategies performing better than it. The society as a whole also performs significantly better simply because a forgiving strategies exists at all.

Lets increase the forgiveness percentage further (to 20%) to see the effect it has on its own score as well as society as a whole:

Highest-scoring Prisoner of .AlwaysBetray: 3550
Highest-scoring Prisoner of .TitForTatBetrayLast: 3912
Highest-scoring Prisoner of .TitForTat: 3953
Highest-scoring Prisoner of .TitForTat20pctForgiveness: 5096

Total Population Score of .AlwaysBetray: 650828
Total Population Score of .TitForTat: 726035
Total Population Score of .TitForTatBetrayLast: 751495
Total Population Score of .TitForTat20pctForgiveness: 1005326

Lowest-scoring Prisoner of .AlwaysBetray: 2438
Lowest-scoring Prisoner of .TitForTat: 2607
Lowest-scoring Prisoner of .TitForTatBetrayLast: 2717
Lowest-scoring Prisoner of .TitForTat20pctForgiveness: 3981

Rankings significantly improve for tit-for-tat with the best score of always betray sinking while other strategies dont move much.
tit-for-tat with 20% forgiveness gains in the lowest and highest scoring prisoner category while betray last looses in both with a small loss in highest scoring, 3976 -> 3912 and more significantly in lowest scoring category, 3145 -> 2717.

This seems to suggest that more forgiveness is better for a society since fair strategies (tit-for-tat and tit-for-tat with 20% forgiveness) seem to have been gaining while malicious ones (always betray and tit-for-tat betray last) seem to have been loosing. Lets see if society becomes fairer if some we make tit-for-tat with forgiveness even more forgiving (30% forgiveness):

Highest-scoring Prisoner of .AlwaysBetray: 3220
Highest-scoring Prisoner of .TitForTat: 3619
Highest-scoring Prisoner of .TitForTatBetrayLast: 3709
Highest-scoring Prisoner of .TitForTat30pctForgiveness: 4883

Total Population Score of .AlwaysBetray: 580738
Total Population Score of .TitForTat: 714161
Total Population Score of .TitForTatBetrayLast: 733132
Total Population Score of .TitForTat30pctForgiveness: 1006455

Lowest-scoring Prisoner of .AlwaysBetray: 2142
Lowest-scoring Prisoner of .TitForTatBetrayLast: 2587
Lowest-scoring Prisoner of .TitForTat: 2869
Lowest-scoring Prisoner of .TitForTat30pctForgiveness: 3933

While the best and worst performing tit-for-tat with forgiveness loose slighly the average gains slightly. The always betray strategy, however, looses significantly across the board. tit-for-tat now leads in the best and worst performing categories. While it has gained rank in the average it has not yet overtaken the betray last strategy. Society overall has also lost some score. Notice that scores are still better, in terms of absolute score, for all strategies. Its interesting that some people being forgiving improves the lives of everyone in society. While this could have been speculated to be the case as a result of complex interactions in real human societies seeing this emerge from interactions between such simplistic agents is odd.

Lets increase forgiveness even further (50% forgiveness) to see if the total population score of tit-for-tat overtakes the betray last strategy:

Highest-scoring Prisoner of .AlwaysBetray: 2348
Highest-scoring Prisoner of .TitForTat: 3673
Highest-scoring Prisoner of .TitForTatBetrayLast: 3713
Highest-scoring Prisoner of .TitForTat50pctForgiveness: 5077

Total Population Score of .AlwaysBetray: 433134
Total Population Score of .TitForTatBetrayLast: 704903
Total Population Score of .TitForTat: 712560
Total Population Score of .TitForTat50pctForgiveness: 991425

Lowest-scoring Prisoner of .AlwaysBetray: 1684
Lowest-scoring Prisoner of .TitForTat: 2542
Lowest-scoring Prisoner of .TitForTatBetrayLast: 3127
Lowest-scoring Prisoner of .TitForTat50pctForgiveness: 4196

Tit-for-tat has lost rank in the highest and lowest performing category while having gained in the average. Tit-for-tat has also gained absolute score in the highest performing category. Not enough, however, to overtake betray last which has gained absolute score in the highest scoring but only very little.
Overall scores of society have sunk and in the lowest performing category only betray last and tit-for-tat with forgiveness have gained absolute score.

## Introducing varying levels of judgement
