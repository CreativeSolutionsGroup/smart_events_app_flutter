import 'package:http/http.dart' as http;
import 'app_constants.dart';
import 'dart:convert';
import 'dart:core';

class Rewards {

  static Future <List<RewardTier>> fetchRewardTiers() async {
    final response =
    await http.get(Uri.parse(AppConstants.API_URL + '/reward_tier'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<RewardTier> map = data["data"].map((data) =>
          RewardTier.fromJson(data)
      ).toList().cast<RewardTier>();
      return map;
    } else {
      throw Exception('[UserRewards] Unexpected error occured!');
    }
  }

  static Future <List<RewardTier>> getSortedRewardTiers() async {
    List<RewardTier> tiers = await fetchRewardTiers();
    tiers.sort((RewardTier a, RewardTier b) => b.min_points > a.min_points ? 1 : -1);
    return tiers;
  }

  static getMaxRewardTierPoints(List<RewardTier> tiers){
    if(tiers.isEmpty){
      return -1;
    }
    return tiers[0].min_points;
  }

  static RewardTier? getNextTier(RewardTier tier, List<RewardTier> tiers){
    List<RewardTier> reverse = tiers.reversed.toList();
    int index = reverse.indexOf(tier);
    if(index > -1 && index < tiers.length - 1){
      return reverse.elementAt(index + 1);
    }
    return null;
  }

  static RewardTier? getUserRewardTier(List<RewardTier> tiers, int userPoints){
    for(RewardTier tier in tiers.reversed){
      if(userPoints <= tier.min_points){
        return tier;
      }
    }
    return null;
  }

  static Future <List<UserReward>> fetchUserRewards(String userID) async {
    final response =
    await http.get(Uri.parse(AppConstants.API_URL + '/user/' + userID + "/rewards"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<UserReward> map = data["data"].map((data) =>
          UserReward.fromJson(data)
      ).toList().cast<UserReward>();
      return map;
    } else {
      throw Exception('[UserRewards] Unexpected error occured!');
    }
  }

  static Future <Reward> fetchReward(String rewardId) async {
    final response =
    await http.get(Uri.parse(AppConstants.API_URL + '/reward/' + rewardId));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Reward.fromJson(data['data']);
    } else {
      throw Exception('[Reward] Unexpected error occured!');
    }
  }

}

class RewardTier {
  final String id;
  final String name;
  final String description;
  final String color;
  final int min_points;
  final List<String> rewards;

  RewardTier({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.min_points,
    required this.rewards
  });

  factory RewardTier.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rewards = json['rewards'];
    return RewardTier(
        id: json["_id"],
        name: json['name'],
        description: json['description'],
        color: json['color'],
        min_points: json['min_points'],
        rewards: rewards.cast<String>()
    );
  }
}

class UserReward {
  final String user_id;
  final String reward_id;
  final int remaining_uses;
  final String date_earned;

  UserReward({
    required this.user_id,
    required this.reward_id,
    required this.remaining_uses,
    required this.date_earned
  });

  factory UserReward.fromJson(Map<String, dynamic> json) {
    return UserReward(
        user_id: json['user_id'],
        reward_id: json['reward_id'],
        remaining_uses: json['remaining_uses'],
        date_earned: json['date_earned']
    );
  }
}

class Reward {
  final String id;
  final String name;
  final String description;
  final String? image_url;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    this.image_url
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
        id: json['_id'],
        name: json['name'],
        description: json['description'],
        image_url: json['image_url']
    );
  }
}