import 'package:flutter/material.dart';

class MySquare extends StatelessWidget {
  final String post;

  const MySquare({required this.post});

  static final List posts = [
    'post 1',
    'post 2',
    'post 3',
    'post 4',
    'post 5',
    'post 6',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Container(
        height: 200,
        color: Colors.grey,
        child: Center(child: Text(post)),
      ),
    );
  }
}
