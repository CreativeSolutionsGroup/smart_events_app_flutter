import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_events_app_flutter/screens/main_screen.dart';
import 'package:smart_events_app_flutter/utils/rewards.dart';

import '../utils/app_constants.dart';
import '../utils/authentication.dart';
import '../utils/user_account.dart';

class RewardsBasicView extends StatefulWidget {
  const RewardsBasicView({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _RewardsBasicViewState createState() => _RewardsBasicViewState();
}

class DataRequiredForBuild {
  UserAccount userAccount;
  List<RewardTier> rewardTiers;
  RewardTier currentTier;

  DataRequiredForBuild({
    required this.userAccount,
    required this.rewardTiers,
    required this.currentTier
  });
}

class _RewardsBasicViewState extends State<RewardsBasicView> {
  late User _user;
  late Future<DataRequiredForBuild> _data;

  @override
  void initState() {
    _user = widget._user;
    _data = _fetchDataForBuild(_user);
    super.initState();
  }

  Future<DataRequiredForBuild> _fetchDataForBuild(User user) async {
    print("Test");
    String userID = await UserAccount.getUserID(user);
    print(userID);
    UserAccount userAccount = await UserAccount.fetchUserAccount(user, userID);
    List<RewardTier> tiers = await Rewards.getSortedRewardTiers();
    print(tiers);
    RewardTier currentTier = Rewards.getUserRewardTier(tiers, userAccount.reward_points)!;
    print(currentTier.min_points);
    return DataRequiredForBuild(
        userAccount: userAccount,
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
            UserAccount? account = snapshot.data!.userAccount;
            List<RewardTier> tiers = snapshot.data!.rewardTiers;
            RewardTier? currentTier = snapshot.data!.currentTier;
            RewardTier? nextTier = Rewards.getNextTier(currentTier, tiers);

            int currentPoints = account.reward_points;
            int maxPoints = nextTier == null ? Rewards.getMaxRewardTierPoints(tiers) : nextTier.min_points;
            int minValue = currentPoints - currentTier.min_points;
            int maxValue = maxPoints - currentTier.min_points;

            double progress = minValue == 0 ? 0.0 : (minValue / maxValue);

            return Card(
                color: AppConstants.COLOR_CEDARVILLE_BLUE,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: _user.photoURL != null
                              ? ClipOval(
                            child: Material(
                              color: AppConstants.COLOR_CEDARVILLE_BLUE.withOpacity(0.3),
                              child: Image.network(
                                _user.photoURL!,
                                height: 50,
                              ),
                            ),
                          )
                              : ClipOval(
                            child: Material(
                              color: Colors.grey,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //TODO Convert colors
                          Text(currentTier.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                        ]
                    ),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${account.reward_points}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                            ]
                        )
                    ),
                    Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 5 , bottom: 10),
                        child: LinearProgressIndicator(
                          value: progress,
                          color: AppConstants.COLOR_CEDARVILLE_YELLOW,
                        )
                    )
                  ],
                )
            );
          }
          else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          // By default show a loading spinner.
          return CircularProgressIndicator();
        }
    );
  }
}