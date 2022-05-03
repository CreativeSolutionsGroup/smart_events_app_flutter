import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_constants.dart';

class CheckIn {
  final String id;
  final String event_id;
  final String name;
  final String description;
  final String message;
  final String image_url;
  final String start_time;
  final String end_time;
  final int reward_points;
  final List<String> beacon_ids;

  CheckIn({
    required this.id,
    required this.event_id,
    required this.name,
    required this.description,
    required this.message,
    required this.image_url,
    required this.start_time,
    required this.end_time,
    required this.reward_points,
    required this.beacon_ids,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    final List<dynamic> beacons = json['beacons'];
    return CheckIn(
        id: json['_id'],
        event_id: json['event_id'],
        name: json['name'],
        description: json['description'],
        message: json['message'],
        image_url: json['image_url'],
        start_time: json['start_time'],
        end_time: json['end_time'],
        reward_points: json['reward_points'],
        beacon_ids: beacons.cast<String>()
    );
  }

  static Future <List<CheckIn>> fetchActiveCheckins() async {
    final response =
    await http.get(Uri.parse(AppConstants.API_URL + '/checkins_active'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<CheckIn> map = data["data"].map((data) =>
          CheckIn.fromJson(data)
      ).toList().cast<CheckIn>();
      return map;
    } else {
      throw Exception('[CheckIn] Unexpected error occured!');
    }
  }

  static Future <CheckIn> fetchCheckIn(String checkInID) async {
    final response =
    await http.get(Uri.parse(AppConstants.API_URL + '/checkin/' + checkInID));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CheckIn.fromJson(data["data"]);
    } else {
      throw Exception('[CheckIn] Unexpected error occured!');
    }
  }

  static Future <bool> postCheckInToCheckIn(BuildContext context, String checkInID, String userID) async {
    final response =
    await http.post(
        Uri.parse(AppConstants.API_URL + '/user_checkin'),
        body: {
          "check_in_id": checkInID,
          "user_id": userID
        }
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if(data["status"] == "success"){
        showCheckIn(context, checkInID);
        return true;
      }
      if(data["status"] == "duplicate"){
        showCheckInWarning(context, 'You have already checked in');
      }
      if(data['status'] == "error") {
        showCheckInWarning(context, 'Error Checking In');
      }
      return false;
    } else {
      throw Exception('[CheckIn] Unexpected error occured!');
    }
  }

  static showCheckInWarning(BuildContext context, String message){
    showDialog(
        context: context,
        builder: (context) {
      return AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    },
    );
  }

  static showCheckIn(BuildContext context, String checkInID) async{
    CheckIn checkIn = await fetchCheckIn(checkInID);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(checkIn.name),
          ),
          content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Visibility(
                    visible: checkIn.image_url.isNotEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      //TODO: Give this a loading animation
                      child: Image.network(checkIn.image_url)
                    )
                  ),
                  Text(checkIn.message),
                  const SizedBox(height: 10),
                  Text("+"+checkIn.reward_points.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.COLOR_CEDARVILLE_YELLOW, fontSize: 24))
                ],
              ),
          actions: [
            TextButton(
              //TODO: Refresh the user's points after they are awarded them so they display correctly
              onPressed: () => Navigator.pop(context), //Maybe pop back to the main screen not the scan dialog
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class BeaconSE {
  final String id;
  final String name;
  final String identifier;
  final String uuid;

  BeaconSE({
    required this.id,
    required this.name,
    required this.identifier,
    required this.uuid,
  });

  factory BeaconSE.fromJson(Map<String, dynamic> json) {
    return BeaconSE(
        id: json['_id'],
        name: json['name'],
        identifier: json['identifier'],
        uuid: json['uuid']
    );
  }

  static Future <List<BeaconSE>> fetchBeacons() async {
    final response =
    await http.get(Uri.parse(AppConstants.API_URL + '/beacon'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<BeaconSE> map = data["data"].map((data) =>
          BeaconSE.fromJson(data)
      ).toList().cast<BeaconSE>();
      return map;
    } else {
      throw Exception('[BeaconSE] Unexpected error occured!');
    }
  }
}

