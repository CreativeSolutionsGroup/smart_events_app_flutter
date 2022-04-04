import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_events_app_flutter/utils/rewards.dart';
import 'package:smart_events_app_flutter/widgets/reward_tier_info.dart';

import '../utils/app_constants.dart';
import '../utils/user_account.dart';

class RewardsBasicView extends StatefulWidget {
  const RewardsBasicView({Key? key, required User user, required UserAccount userAccount})
      : _user = user, _userAccount = userAccount,
        super(key: key);

  final User _user;
  final UserAccount _userAccount;

  @override
  _RewardsBasicViewState createState() => _RewardsBasicViewState();
}

class DataRequiredForBuild {
  List<RewardTier> rewardTiers;
  RewardTier currentTier;

  DataRequiredForBuild({
    required this.rewardTiers,
    required this.currentTier
  });
}

class _RewardsBasicViewState extends State<RewardsBasicView> {
  late User _user;
  late UserAccount _userAccount;
  late Future<DataRequiredForBuild> _data;

  @override
  void initState() {
    _user = widget._user;
    _userAccount = widget._userAccount;
    _data = _fetchDataForBuild(_user, _userAccount);
    super.initState();
  }

  Future<DataRequiredForBuild> _fetchDataForBuild(User user, UserAccount userAccount) async {
    List<RewardTier> tiers = await Rewards.getSortedRewardTiers();
    RewardTier currentTier = Rewards.getUserRewardTier(tiers, userAccount.reward_points)!;
    return DataRequiredForBuild(
        rewardTiers: tiers,
        currentTier: currentTier
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder <DataRequiredForBuild>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            UserAccount? account = _userAccount;
            List<RewardTier> tiers = snapshot.data!.rewardTiers;
            RewardTier? currentTier = snapshot.data!.currentTier;
            RewardTier? nextTier = Rewards.getNextTier(currentTier, tiers);

            int currentPoints = account.reward_points;
            int maxPoints = nextTier == null ? Rewards.getMaxRewardTierPoints(tiers) : nextTier.min_points;
            int minValue = currentPoints - currentTier.min_points;
            int maxValue = maxPoints- currentTier.min_points;

            double progress = minValue == 0 || maxValue == 0 ? 0.0 : (minValue / maxValue);

            return Card(
                color: AppConstants.COLOR_CEDARVILLE_BLUE,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child:  Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("Rewards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.white))
                          ]
                      ),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //TODO Convert colors
                           GestureDetector(
                            onTap: () {
                              _displayTierDialog(context, tiers);
                            },
                            child: Text(currentTier.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                          )
                        ]
                    ),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${account.reward_points}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: AppConstants.COLOR_CEDARVILLE_YELLOW))
                            ]
                        )
                    ),
                    Visibility(
                      visible: nextTier != null,
                      child: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 5 , bottom: 10),
                          child: LinearProgressIndicator(
                            value: progress,
                            color: AppConstants.COLOR_CEDARVILLE_YELLOW,
                          )
                      )
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //TODO Convert colors
                          /*Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(nextTier == null ? "" : 'Next Tier: ${nextTier.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                          )*/
                          Padding(
                            padding: const EdgeInsets.only(left: 10, bottom: 10),
                            child: Text('${currentTier.min_points}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10, bottom: 10),
                            child: Text('$maxPoints', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                          ),
                        ]
                    ),
                  ],
                )
            );
          }
          else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          // By default show a loading spinner.
          return const CircularProgressIndicator();
        }
    );
  }

  _displayTierDialog(BuildContext context, List<RewardTier> data) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return RewardTierDialog(data: data);
      },
    );
  }
}