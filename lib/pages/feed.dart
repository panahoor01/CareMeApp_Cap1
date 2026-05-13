import 'package:flutter/material.dart';
import 'package:flutter_application_practice/square.dart';

class UserHomePage extends StatelessWidget {
  UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/logo2.png', height: 30),
            ),
            const SizedBox(width: 15),
            const Text('CareMe', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: MySquare.posts.length,
        itemBuilder: (context, index) {
          return MySquare(post: MySquare.posts[index]);
        },
      ),
    );
  }
}
