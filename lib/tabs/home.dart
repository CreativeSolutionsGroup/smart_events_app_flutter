
import 'package:flutter/material.dart';
import 'package:smart_events_app_flutter/utils/app_constants.dart';
import 'package:smart_events_app_flutter/utils/checkin.dart';
import 'package:smart_events_app_flutter/utils/user_account.dart';
import 'package:smart_events_app_flutter/widgets/beacon_scanner.dart';
import 'package:smart_events_app_flutter/widgets/home_rewards.dart';
import 'package:smart_events_app_flutter/widgets/user_profile.dart';

import '../screens/sign_in_screen.dart';
import '../utils/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key, required User user, required UserAccount userAccount})
      : _user = user, _userAccount = userAccount,
        super(key: key);

  final User _user;
  final UserAccount _userAccount;

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late User _user;
  late UserAccount _userAccount;

  @override
  void initState() {
    _user = widget._user;
    _userAccount = widget._userAccount;

    super.initState();
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
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _user.photoURL != null
                          ? ClipOval(
                        child: Material(
                          color: AppConstants.COLOR_CEDARVILLE_BLUE.withOpacity(0.3),
                          child: GestureDetector(
                            onTap: () {
                              _displayUserDialog(context);
                            },
                            child: Image.network(
                              _user.photoURL!,
                              height: 40,
                            ),
                          )
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
                      Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Notifications',
                                icon: const Icon(Icons.notifications_none),
                                color: AppConstants.COLOR_CEDARVILLE_BLUE,
                                onPressed: () {
                                  //_displayScanningDialog(context);
                                },
                              ),
                              IconButton(
                                tooltip: 'Check In',
                                icon: const Icon(Icons.where_to_vote),
                                color: AppConstants.COLOR_CEDARVILLE_YELLOW,
                                onPressed: () {
                                  _displayScanningDialog(context);
                                },
                              )
                            ]
                          )
                        ]
                      )
                    ],
                  ),
              ),
              //Reward Summary
              RewardsBasicView(user: _user, userAccount: _userAccount),
            ],
          ),
        ),
      ),
    );
  }

  _displayUserDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return UserProfile(user: _user, userAccount: _userAccount);
      },
    );
  }

  _displayScanningDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BeaconScanner();
      },
    );
  }
}