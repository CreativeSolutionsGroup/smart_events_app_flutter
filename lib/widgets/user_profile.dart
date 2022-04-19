import 'package:flutter/material.dart';

import 'package:smart_events_app_flutter/utils/user_account.dart';
import '../screens/sign_in_screen.dart';
import '../utils/app_constants.dart';
import '../utils/authentication.dart';
import '../utils/strings.dart';
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
  bool _isEditing = false;

  //Edit Info
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController studentIDController;
  late TextEditingController phoneController;

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

    nameController = TextEditingController(text: _userAccount.name.isEmpty ? "" : _userAccount.name);
    studentIDController = TextEditingController(text: _userAccount.student_id.isEmpty ? "" : _userAccount.student_id);
    phoneController = TextEditingController(text: _userAccount.phone_number.isEmpty ? "" : _userAccount.phone_number);
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    studentIDController.dispose();
    phoneController.dispose();
    super.dispose();
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
                    : const ClipOval(
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
                _isEditing ? buildEditing(context) : buildDefaultInfo(context)
              ],
            ),
            Positioned(
                right: 10,
                child: IconButton(
                  icon: Icon(_isEditing ? Icons.cancel : Icons.edit_note, color: AppConstants.COLOR_CEDARVILLE_BLUE),
                  iconSize: 30,
                  onPressed: () {
                      bool oldEditing = _isEditing;
                      _isEditing = !oldEditing;
                      setState(() {
                        _isEditing = !oldEditing;
                      });
                  },
                )
            ),
          ]
        )
      ],
      elevation: 10,
    );
  }

  buildDefaultInfo(BuildContext context){
    return Column(
      children: [
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
    );
  }

  buildEditing(BuildContext context){
    return Column(
      children: [
        Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10.0,
                    bottom: 10.0,
                    left: 5.0,
                    right: 5.0
                  ),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Your Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    controller: nameController,
                    keyboardType: TextInputType.name,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10.0,
                    bottom: 10.0,
                    left: 5.0,
                    right: 5.0
                  ),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Student ID',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your Student ID';
                      }
                      if(!Strings.REGEX_STUDENT_ID.hasMatch(value)){
                        return 'Please enter a 7 digit Student ID';
                      }
                      return null;
                    },
                    controller: studentIDController,
                    keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10.0,
                    bottom: 10.0,
                    left: 5.0,
                    right: 5.0
                  ),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Phone Number',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if(!Strings.REGEX_PHONE_NUMBER.hasMatch(value)){
                        return 'Enter a valid phone number (ex. 123-456-7890)';
                      }
                      return null;
                    },
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate returns true if the form is valid, or false otherwise.
                    if (_formKey.currentState!.validate()) {
                      //TODO Prevent updating when info has not changed
                      updateUser();
                    }
                  },
                  child: const Text('Update', style: TextStyle(fontSize: 20),),
                ),
              ],
            )
        )
      ],
    );
  }

  updateUser() async {
    String name = nameController.text;
    String studentID = studentIDController.text;
    String phoneNumber = phoneController.text;

    UserAccount? account = await UserAccount.updateUserAccount(_user, _userAccount, name, studentID, phoneNumber);

    if(account == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error Updating User')),
      );
    }
    else {
      setState(() {
        _isEditing = false;
        _userAccount = account;
      });
    }
  }
}