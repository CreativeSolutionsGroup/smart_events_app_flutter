
import 'package:flutter/material.dart';
import 'package:smart_events_app_flutter/utils/app_constants.dart';
import 'package:smart_events_app_flutter/utils/user_account.dart';
import 'package:smart_events_app_flutter/widgets/beacon_scanner.dart';
import 'package:smart_events_app_flutter/widgets/home_rewards.dart';

import '../screens/sign_in_screen.dart';
import '../utils/authentication.dart';
import '../widgets/google_sign_in_button.dart';
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
  bool _isSigningOut = false;

  Route _routeToSignInScreen() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SignInScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

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
                          child: Image.network(
                            _user.photoURL!,
                            height: 40,
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
                      Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Notifications',
                                icon: Icon(Icons.notifications_none),
                                color: AppConstants.COLOR_CEDARVILLE_BLUE,
                                onPressed: () {
                                  //_displayScanningDialog(context);
                                },
                              ),
                              IconButton(
                                tooltip: 'Check In',
                                icon: Icon(Icons.where_to_vote),
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
              _isSigningOut
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.COLOR_CEDARVILLE_YELLOW),
              )
                  : ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    Colors.redAccent,
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onPressed: () async {
                  setState(() {
                    _isSigningOut = true;
                  });
                  await Authentication.signOut(context: context);
                  setState(() {
                    _isSigningOut = false;
                  });
                  Navigator.of(context)
                      .pushReplacement(_routeToSignInScreen());
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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