import 'package:flutter/material.dart';

import 'package:smart_events_app_flutter/utils/user_account.dart';
import '../screens/sign_in_screen.dart';
import '../utils/app_constants.dart';
import '../utils/authentication.dart';
import '../utils/user_account.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key, required User user, required UserAccount userAccount})
      : _user = user, _userAccount = userAccount,
        super(key: key);

  final User _user;
  final UserAccount _userAccount;

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  late User _user;
  late UserAccount _userAccount;
  bool _isSigningOut = false;

  Route _routeToSignInScreen() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SignInScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(-1.0, 0.0);
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
    return SimpleDialog(
      children:[
        Stack(
          children: [
            Column(
              children: [
                _user.photoURL != null
                    ? ClipOval(
                  child: Material(
                      color: AppConstants.COLOR_CEDARVILLE_BLUE.withOpacity(0.3),
                      child: Image.network(
                          _user.photoURL!,
                          height: 100,
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
                        size: 100,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(_userAccount.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))
                ),
                Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.badge),
                        const SizedBox(width: 5),
                        Text(_userAccount.student_id.isEmpty ? "Missing" : _userAccount.student_id, style: const TextStyle(fontSize: 18))
                      ]
                    )
                ),
                Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone),
                          const SizedBox(width: 5),
                          Text(_userAccount.phone_number.isEmpty ? "Missing" : _userAccount.phone_number, style: const TextStyle(fontSize: 18))
                        ]
                    )
                ),
                _isSigningOut
                    ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.COLOR_CEDARVILLE_BLUE
                    ),
                )
                    : ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Colors.red,
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
                  child: const Padding(
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
            Positioned(
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.edit_note, color: AppConstants.COLOR_CEDARVILLE_BLUE),
                  iconSize: 30,
                  onPressed: () {

                  },
                )
            ),
          ]
        )
      ],
      elevation: 10,
    );
  }
}