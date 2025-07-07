import 'package:flutter/material.dart';

class FifaCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.05, size.height * 0.1);
    path.lineTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.95, size.height * 0.1);
    path.quadraticBezierTo(size.width, size.height * 0.1, size.width, size.height * 0.15);
    path.lineTo(size.width, size.height * 0.9);
    path.quadraticBezierTo(size.width, size.height, size.width * 0.95, size.height);
    path.lineTo(size.width * 0.05, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height * 0.9);
    path.lineTo(0, size.height * 0.15);
    path.quadraticBezierTo(0, size.height * 0.1, size.width * 0.05, size.height * 0.1);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
