import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/birthday_screen.dart';

import '../../auth/user_model.dart';

class NameScreen extends StatelessWidget {
  final UserModel user;

  NameScreen({required this.user});

  final firstController = TextEditingController();
  final lastController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: firstController,
            decoration: InputDecoration(labelText: "First Name"),
          ),
          TextField(
            controller: lastController,
            decoration: InputDecoration(labelText: "Last Name"),
          ),

          ElevatedButton(
            onPressed: () {
              user.firstName = firstController.text;
              user.lastName = lastController.text;

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BirthdayScreen(user: user)),
              );
            },
            child: Text("Continue"),
          ),
        ],
      ),
    );
  }
}
