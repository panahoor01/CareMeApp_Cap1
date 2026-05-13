import 'package:flutter/material.dart';

import '../../auth/user_model.dart';

class GenderScreen extends StatelessWidget {
  final UserModel user;

  const GenderScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Gender')),
      body: Center(child: Text('Selected birthday: ${user.birthday}')),
    );
  }
}
