import 'dart:convert';

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

