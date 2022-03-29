import 'package:flutter/material.dart';
import 'package:smart_events_app_flutter/utils/app_constants.dart';
import 'package:smart_events_app_flutter/utils/rewards.dart';
import 'package:smart_events_app_flutter/utils/user_account.dart';
import 'package:smart_events_app_flutter/widgets/home_rewards.dart';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import "dart:core";

class RewardsTab extends StatefulWidget {
  const RewardsTab({Key? key, required User user, required UserAccount userAccount})
      : _user = user, _userAccount = userAccount,
        super(key: key);

  final User _user;
  final UserAccount _userAccount;

  @override
  _RewardsTabState createState() => _RewardsTabState();
}

class DataRequiredForBuild {
  List<UserReward> userRewards;
  Map<String, Reward> rewards;

  DataRequiredForBuild({
    required this.userRewards,
    required this.rewards
  });
}

class _RewardsTabState extends State<RewardsTab> {
  late User _user;
  late UserAccount _userAccount;
  late Future<DataRequiredForBuild> _data;

  @override
  void initState() {
    _user = widget._user;
    _userAccount = widget._userAccount;
    _data = _fetchDataForBuild(_userAccount);

    super.initState();
  }

  Future<DataRequiredForBuild> _fetchDataForBuild(UserAccount userAccount) async {
    List<UserReward> userRewards = await Rewards.fetchUserRewards(_userAccount.id);
    Map<String, Reward> rewards = <String, Reward>{};
    print(userRewards.length);
    for(UserReward userReward in userRewards){
        Reward reward = await Rewards.fetchReward(userReward.reward_id);
        rewards.putIfAbsent(userReward.reward_id, () => reward);
    }
    print(rewards.keys.length);
    return DataRequiredForBuild(
        userRewards: userRewards,
        rewards: rewards
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              //Reward Point Info
              Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    bottom: 10
                  ),
                  child: RewardsBasicView(user: _user, userAccount: _userAccount)
              ),
              Text("Your Rewards", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: AppConstants.COLOR_CEDARVILLE_BLUE)),
              //List of User Rewards
              const Divider(
                height: 20,
                thickness: 3,
                indent: 20,
                endIndent: 20,
                color: AppConstants.COLOR_CEDARVILLE_BLUE,
              ),
              Expanded(
                child: buildUserRewards(context),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUserRewards(BuildContext context){
    return FutureBuilder <DataRequiredForBuild>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            List<UserReward> userRewards = snapshot.data!.userRewards;
            userRewards.sort((a, b) => (
                a.remaining_uses == 0 ? 1 : b.remaining_uses == 0 ? -1 : 0
            ));
            Map<String, Reward> rewards = snapshot.data!.rewards;

            if(userRewards.isEmpty){
              return Center(
                  child: Text("Empty", style: const TextStyle(fontSize: 18))
              );
            }
            return
              ListView.builder(
                  itemCount: rewards.length,
                  itemBuilder: (BuildContext context, int index) {
                    UserReward userReward = userRewards[index];
                    Reward? reward = rewards[userReward.reward_id];
                    return Card(
                        color: userReward.remaining_uses <= 0 ? Colors.black.withOpacity(0.5) : Colors.grey[100],
                        child:
                          InkWell(
                            onTap: () {
                              //_displayDialog(context, attraction);
                            },
                            child: Container(
                              child: Column(
                                children: [
                                  Container(
                                      margin: const EdgeInsets.all(5),
                                      child: Row(
                                        children: [
                                          //Image
                                          Visibility(
                                            visible: reward!.image_url !=null && reward.image_url!.isNotEmpty,
                                            child: reward.image_url !=null ?
                                                    Image.network(
                                                        reward.image_url!,
                                                        height: 100,
                                                        width: 100,
                                                    )
                                                : Text("Error"),
                                          ),
                                          //Name and Description
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 5.0,
                                                  bottom: 5.0,
                                                  left: 10.0
                                                ),
                                                child: Text(reward.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                                              ),
                                              Padding(
                                                  padding: const EdgeInsets.only(
                                                      left: 10.0,
                                                      bottom: 5.0
                                                  ),
                                                  child: Text(reward.description)
                                              ),
                                            ],
                                          )
                                        ],
                                      )
                                  )
                                ],
                              ),
                            )
                        )
                    );
                  }
              );
          }
          else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          // By default show a loading spinner.
          return Center(
              child: CircularProgressIndicator()
          );
        }
    );
  }
}