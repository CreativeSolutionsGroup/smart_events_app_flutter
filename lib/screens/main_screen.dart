
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:smart_events_app_flutter/controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import 'package:smart_events_app_flutter/screens/sign_in_screen.dart';
import 'package:smart_events_app_flutter/tabs/attractionlist.dart';
import 'package:smart_events_app_flutter/tabs/user_rewards.dart';
import 'package:smart_events_app_flutter/utils/app_constants.dart';
import 'package:smart_events_app_flutter/utils/user_account.dart';
import 'package:smart_events_app_flutter/widgets/beacon_scanner.dart';

import '../tabs/home.dart';
import '../widgets/beacon_scanner_test.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key, required User user})
      : _user = user,
        super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final User _user;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late User _user;
  late Future<UserAccount> _userAccount;
  bool _isSigningOut = false;

  int _selectedIndex = 0; //Selected Tab

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
    _userAccount = _fetchUserAccount(_user);
    super.initState();
  }

  Future<UserAccount> _fetchUserAccount(User user) async {
    String userID = await UserAccount.getUserID(user);
    UserAccount userAccount = await UserAccount.fetchUserAccount(user, userID);
    return userAccount;
  }

  static List<Widget> _pages = <Widget>[
    Icon(
      Icons.home,
      size: 150,
    ),
    Icon(
      Icons.calendar_month,
      size: 150,
    ),
    AttractionList(),
    Icon(
      Icons.local_activity,
      size: 150,
    ),
    Icon(
      Icons.emoji_events,
      size: 150,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: buildTabPage(context)
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              backgroundColor: AppConstants.COLOR_CEDARVILLE_BLUE
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Calendar',
              backgroundColor: AppConstants.COLOR_CEDARVILLE_BLUE
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Events',
              backgroundColor: AppConstants.COLOR_CEDARVILLE_BLUE
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_activity),
              label: 'Tickets',
              backgroundColor: AppConstants.COLOR_CEDARVILLE_BLUE
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'Rewards',
              backgroundColor: AppConstants.COLOR_CEDARVILLE_BLUE
          ),
        ],
        selectedItemColor: AppConstants.COLOR_CEDARVILLE_YELLOW,
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

Widget buildTabPage(BuildContext context){
    return FutureBuilder <UserAccount>(
        future: _userAccount,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            UserAccount userAccount = snapshot.data!;
            if(_selectedIndex == 0){
              return HomeTab(user: _user, userAccount: userAccount);
            }
            else if(_selectedIndex == 4){
              return RewardsTab(user: _user, userAccount: userAccount);
            }
            else {
              return _pages.elementAt(_selectedIndex);
            }
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