import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_events_app_flutter/utils/app_constants.dart';
import 'package:smart_events_app_flutter/utils/user_account.dart';

import '../utils/strings.dart';
import 'main_screen.dart';


class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final studentIDController = TextEditingController();
  final phoneController = TextEditingController();

  late User _user;

  @override
  void initState() {
    _user = widget._user;
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
              const SizedBox(height: 10),
              Flexible(
                flex: 1,
                child: Image.asset(
                  'assets/smart_events_logo.png',
                  height: 130,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Sign Up", style: TextStyle(fontSize: 50, color: AppConstants.COLOR_CEDARVILLE_BLUE, fontWeight: FontWeight.bold))
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Your Information", style: TextStyle(fontSize: 30, color: AppConstants.COLOR_CEDARVILLE_BLUE))
                ],
              ),
              const Divider(
                color: AppConstants.COLOR_CEDARVILLE_BLUE,
              ),
              Form(
                key: _formKey,
                child: Column(
                children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 10.0,
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
                          // If the form is valid, display a snackbar. In the real world,
                          // you'd often call a server or save the information in a database.
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(content: Text('Processing Data')),
                          // );
                          signUpUser();
                        }
                      },
                      child: const Text('Sign Up', style: TextStyle(fontSize: 20),),
                    ),
                  ],
                )
              )
            ],
          ),
        ),
      ),
    );
  }

  signUpUser() async {
    String email = _user.email!;
    String name = nameController.text;
    String studentID = studentIDController.text;
    String phoneNumber = phoneController.text;

    UserAccount? account = await UserAccount.addUserAccount(_user, email, name, studentID, phoneNumber);

    if(account == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error Creating User')),
      );
    }
    else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
            MainScreen(
              user: _user,
            ),
        ),
      );
    }
  }
}