import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_constants.dart';

class UserAccount {
  final String id;
  final String name;
  final String email;
  final String student_id;
  final String phone_number;
  final int reward_points;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.student_id,
    required this.phone_number,
    required this.reward_points
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
        id: json['_id'],
        name: json['name'],
        email: json['email'],
        student_id: json['student_id'],
        phone_number: json['phone_number'],
        reward_points: json['reward_points']
    );
  }

  static Future <String?> getUserID(User user) async {
    final prefs = await SharedPreferences.getInstance();

    String? storedUserID = prefs.getString("USER_ID");
    if(storedUserID == null){
      storedUserID = await fetchUserId(user.email!);
      if(storedUserID != null) {
        prefs.setString("USER_ID", storedUserID);
      }
    }
    return storedUserID;
  }

  static Future <String?> fetchUserId(String userEmail) async {
    final response =
    await http.post(Uri.parse(AppConstants.API_URL + '/find_user/'), body: {"email": userEmail});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if(data["status"] == "success") {
        return data["data"]["user_id"];
      }
      else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future <UserAccount> fetchUserAccount(User user, String id) async {
    final idToken = await user.getIdToken();
    //https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=

    // final responseTest =
    // await http.get(
    //     Uri.parse('https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=${idToken}')
    // );
    // print(jsonDecode(responseTest.body));

    final response =
    await http.get(
        Uri.parse(AppConstants.API_URL + '/user/' + id),
        headers: {
          "Authorization": 'Bearer '+ idToken,
          "Content-Type": "application/x-www-form-urlencoded",
          "isFirebaseAuth": "true"
        }
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserAccount.fromJson(data['data']);
    } else {
      throw Exception('[User] Unexpected error occured!');
    }
  }

  static Future <UserAccount?> addUserAccount(User user, String email, String name, String studentId, String phone) async {
    final auth = await user.getIdToken();
    final response =
    await http.post(
        Uri.parse(AppConstants.API_URL + '/user/'),
        headers: {
          "Authorization": 'Bearer '+ auth,
          "Content-Type": "application/x-www-form-urlencoded",
          "isFirebaseAuth": "true"
        },
        body: {
          "email": email,
          "name": name,
          "student_id": studentId,
          "phone_number": phone
        }
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if(data['status'] == "success") {
        return UserAccount.fromJson(data['data']);
      }
      else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future <UserAccount?> updateUserAccount(User user, UserAccount account, String name, String studentId, String phone) async {
    final auth = await user.getIdToken();
    final response =
    await http.put(
        Uri.parse(AppConstants.API_URL + '/user/' + account.id),
        headers: {
          "Authorization": 'Bearer '+ auth,
          "Content-Type": "application/x-www-form-urlencoded",
          "isFirebaseAuth": "true"
        },
        body: {
          "name": name,
          "student_id": studentId,
          "phone_number": phone
        }
    );
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if(data['status'] == "success") {
        return UserAccount.fromJson(data['data']);
      }
      else {
        return null;
      }
    } else {
      return null;
    }
  }
}