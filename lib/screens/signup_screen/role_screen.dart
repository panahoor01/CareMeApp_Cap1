import 'package:flutter/material.dart';

import '../../auth/user_model.dart';
import 'name_screen.dart';

class RoleScreen extends StatelessWidget {
  final user = UserModel();

  RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign up")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              user.role = "client";
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NameScreen(user: user)),
              );
            },
            child: Text("I'm a client"),
          ),

          ElevatedButton(
            onPressed: () {
              user.role = "beautician";
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NameScreen(user: user)),
              );
            },
            child: Text("I'm a beautician"),
          ),
        ],
      ),
    );
  }
}
