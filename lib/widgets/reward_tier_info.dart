import 'dart:math';

import 'package:flutter/material.dart';

import 'package:smart_events_app_flutter/utils/rewards.dart';

class RewardTierDialog extends StatefulWidget {
  const RewardTierDialog({Key? key, required List<RewardTier> data})
      : _data = data,
        super(key: key);

  final List<RewardTier> _data;

  @override
  _RewardTierDialogState createState() => _RewardTierDialogState();
}

class _RewardTierDialogState extends State<RewardTierDialog> {
  late List<RewardTier> _data;
  late Future<Map<String, List<Reward>>> _tierRewards;

  @override
  void initState() {
    _data = widget._data;
    _tierRewards = _fetchDataForBuild(_data);

    super.initState();
  }

  Future<Map<String, List<Reward>>> _fetchDataForBuild(List<RewardTier> tiers) async {
    Map<String, List<Reward>> rewards = <String, List<Reward>>{};
    for(RewardTier tier in tiers){
      List<Reward> list = [];
      for(String id in tier.rewards){
        Reward reward = await Rewards.fetchReward(id);
        list.add(reward);
      }
      rewards.putIfAbsent(tier.id, () => list);
    }
    return rewards;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children:[
        Center(
            child: FutureBuilder <Map<String, List<Reward>>>(
                future: _tierRewards,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    Map<String, List<Reward>> rewards = snapshot.data!;
                    return SizedBox(
                        width: 400,
                        height: min(_data.length * 80, 400),
                        child: ListView.builder(
                          itemCount: _data.length,
                          itemBuilder: (context, index) {
                            final RewardTier item = _data[index];
                            final List<Reward> rewardList = rewards[item.id]!;
                            final String rewardString = rewardList.map((e) => e.name).join(", ");
                            return ListTile(
                              title: Text(item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.description, style: const TextStyle(color: Colors.black)),
                                  Text(rewardString),
                                ],
                              )
                            );
                          },
                        )
                    );
                  }
                  else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }
                  // By default show a loading spinner.
                  return const CircularProgressIndicator();
                }
            )
        )
      ],
      elevation: 10,
    );
  }
}