import 'package:flutter/material.dart';

import '../../auth/user_model.dart';
import 'gender_screen.dart';

class BirthdayScreen extends StatelessWidget {
  final UserModel user;

  BirthdayScreen({required this.user});

  final birthdayController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Birthday')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: birthdayController,
              decoration: InputDecoration(labelText: "Birthday (YYYY-MM-DD)"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                user.birthday = birthdayController.text;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GenderScreen(user: user)),
                );
              },
              child: Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
