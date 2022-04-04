import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smart_events_app_flutter/utils/app_constants.dart';
import 'package:smart_events_app_flutter/utils/rewards.dart';
import 'package:smart_events_app_flutter/utils/user_account.dart';
import 'package:smart_events_app_flutter/widgets/home_rewards.dart';

import 'package:firebase_auth/firebase_auth.dart';
import "dart:core";

import 'package:smart_events_app_flutter/widgets/qr_dialog.dart';

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
    for(UserReward userReward in userRewards){
        Reward reward = await Rewards.fetchReward(userReward.reward_id);
        rewards.putIfAbsent(userReward.reward_id, () => reward);
    }
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
              const Text("Your Rewards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: AppConstants.COLOR_CEDARVILLE_BLUE)),
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
            //Sort the used rewards to the bottom
            userRewards.sort((a, b) => (
                a.remaining_uses == 0 ? 1 : b.remaining_uses == 0 ? -1 : 0
            ));
            //Sort rewards by date earned
            userRewards.sort((a, b) => (
                DateTime.parse(a.date_earned).isBefore(DateTime.parse(b.date_earned)) ? 1 : 0
            ));
            Map<String, Reward> rewards = snapshot.data!.rewards;

            if(userRewards.isEmpty){
              return const Center(
                  child: Text("Empty", style: TextStyle(fontSize: 18))
              );
            }
            return
              RefreshIndicator(
                  child: ListView.builder(
                    itemCount: rewards.length,
                    itemBuilder: (BuildContext context, int index) {
                      UserReward userReward = userRewards[index];
                      Reward? reward = rewards[userReward.reward_id];
                      return Card(
                          color: userReward.remaining_uses <= 0 ? Colors.black.withOpacity(0.5) : Colors.grey[100],
                          child:
                            InkWell(
                              child: Column(
                                children: [
                                  Stack(
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
                                                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                                              if (loadingProgress == null) {
                                                                return child;
                                                              }
                                                              return const Center(
                                                                child: CircularProgressIndicator(),
                                                              );
                                                            }
                                                        )
                                                    : const Text("Error"),
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
                                              ),
                                            ],
                                          )
                                      ),
                                      //Count Indicator
                                      Visibility(
                                          visible: userReward.remaining_uses > 1,
                                          child: Positioned(
                                            top: 10,
                                            right: 10,
                                            child: Container(
                                              width: 30,
                                              height: 30,
                                              decoration: const BoxDecoration(
                                                color: AppConstants.COLOR_CEDARVILLE_YELLOW,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text('${userReward.remaining_uses}', style: const TextStyle(fontWeight: FontWeight.bold))
                                              )
                                            ),
                                          )
                                      ),
                                    ]
                                  ),
                                ],
                              ),
                              onTap: () {

                                if(userReward.remaining_uses <= 0){
                                  _displayWarningDialog(context, "This reward has already been used");
                                  return;
                                }

                                String data = jsonEncode({"type": "reward", "reward_id": reward.id});
                                _displayQRDialog(context, reward.name, data);
                              }
                          )
                      );
                    }
                ),
                onRefresh: () {
                  return Future.delayed(
                    const Duration(seconds: 1),
                    () async {
                      _data = _fetchDataForBuild(_userAccount);
                    },
                  );
                },
              );
          }
          else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          // By default show a loading spinner.
          return const Center(
              child: CircularProgressIndicator()
          );
        }
    );
  }

  _displayQRDialog(BuildContext context, String title, String data) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return QRDialog(title: title, data: data);
      },
    );
  }

  _displayWarningDialog(BuildContext context, String text) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(text),
        );
      },
    );
  }
}