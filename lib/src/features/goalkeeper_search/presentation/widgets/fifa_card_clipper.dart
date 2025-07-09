import 'package:flutter/material.dart';
import 'dart:math' as math;

class FifaCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double cornerRadius = 24.0;
    final double topCutSize = size.width * 0.15;
    final double topCutHeight = size.height * 0.08;
    
    // Start from top-left corner with rounded edge
    path.moveTo(cornerRadius, 0);
    
    // Top edge with FIFA-style angled cuts
    path.lineTo(size.width * 0.35, 0);
    path.lineTo(size.width * 0.35 + topCutSize * 0.3, topCutHeight * 0.3);
    path.lineTo(size.width * 0.5 - topCutSize * 0.2, topCutHeight * 0.7);
    path.lineTo(size.width * 0.5, topCutHeight);
    path.lineTo(size.width * 0.5 + topCutSize * 0.2, topCutHeight * 0.7);
    path.lineTo(size.width * 0.65 - topCutSize * 0.3, topCutHeight * 0.3);
    path.lineTo(size.width * 0.65, 0);
    path.lineTo(size.width - cornerRadius, 0);
    
    // Top-right corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    
    // Right edge
    path.lineTo(size.width, size.height - cornerRadius);
    
    // Bottom-right corner
    path.quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height);
    
    // Bottom edge
    path.lineTo(cornerRadius, size.height);
    
    // Bottom-left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);
    
    // Left edge
    path.lineTo(0, cornerRadius);
    
    // Top-left corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class EnhancedFifaCardClipper extends CustomClipper<Path> {
  final double notchDepth;
  final double cornerRadius;
  
  const EnhancedFifaCardClipper({
    this.notchDepth = 0.05,
    this.cornerRadius = 24.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final double notchSize = size.width * notchDepth;
    final double notchHeight = size.height * 0.06;
    
    // Start from top-left with rounded corner
    path.moveTo(cornerRadius, 0);
    
    // Create FIFA-style top notches
    _createTopNotches(path, size, notchSize, notchHeight);
    
    // Top-right corner
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    
    // Right edge with subtle curves
    _createRightEdge(path, size);
    
    // Bottom-right corner
    path.quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height);
    
    // Bottom edge
    path.lineTo(cornerRadius, size.height);
    
    // Bottom-left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);
    
    // Left edge with subtle curves
    _createLeftEdge(path, size);
    
    // Top-left corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    
    path.close();
    return path;
  }
  
  void _createTopNotches(Path path, Size size, double notchSize, double notchHeight) {
    final double centerX = size.width * 0.5;
    final double firstNotchStart = centerX - notchSize * 1.5;
    final double firstNotchEnd = centerX - notchSize * 0.5;
    final double secondNotchStart = centerX + notchSize * 0.5;
    final double secondNotchEnd = centerX + notchSize * 1.5;
    
    // Line to first notch
    path.lineTo(firstNotchStart, 0);
    
    // First notch (angled cut)
    path.lineTo(firstNotchStart + notchSize * 0.2, notchHeight * 0.4);
    path.lineTo(firstNotchEnd - notchSize * 0.2, notchHeight * 0.8);
    path.lineTo(firstNotchEnd, notchHeight);
    
    // Center section
    path.lineTo(secondNotchStart, notchHeight);
    
    // Second notch (angled cut)
    path.lineTo(secondNotchStart + notchSize * 0.2, notchHeight * 0.8);
    path.lineTo(secondNotchEnd - notchSize * 0.2, notchHeight * 0.4);
    path.lineTo(secondNotchEnd, 0);
  }
  
  void _createRightEdge(Path path, Size size) {
    final double midY = size.height * 0.5;
    final double curve = size.width * 0.005;
    
    path.lineTo(size.width, midY - size.height * 0.1);
    path.quadraticBezierTo(size.width - curve, midY, size.width, midY + size.height * 0.1);
    path.lineTo(size.width, size.height - cornerRadius);
  }
  
  void _createLeftEdge(Path path, Size size) {
    final double midY = size.height * 0.5;
    final double curve = size.width * 0.005;
    
    path.lineTo(0, midY + size.height * 0.1);
    path.quadraticBezierTo(curve, midY, 0, midY - size.height * 0.1);
    path.lineTo(0, cornerRadius);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class PremiumCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double cornerRadius = 28.0;
    
    // Create a more sophisticated card shape for premium cards
    path.moveTo(cornerRadius, 0);
    
    // Top edge with multiple cuts for premium look
    path.lineTo(w * 0.3, 0);
    path.lineTo(w * 0.32, h * 0.03);
    path.lineTo(w * 0.35, h * 0.02);
    path.lineTo(w * 0.38, h * 0.04);
    
    path.lineTo(w * 0.45, h * 0.06);
    path.lineTo(w * 0.5, h * 0.08);
    path.lineTo(w * 0.55, h * 0.06);
    
    path.lineTo(w * 0.62, h * 0.04);
    path.lineTo(w * 0.65, h * 0.02);
    path.lineTo(w * 0.68, h * 0.03);
    path.lineTo(w * 0.7, 0);
    
    // Continue to top-right
    path.lineTo(w - cornerRadius, 0);
    path.quadraticBezierTo(w, 0, w, cornerRadius);
    
    // Right edge with elegant curves
    path.lineTo(w, h * 0.25);
    path.quadraticBezierTo(w - 3, h * 0.3, w, h * 0.35);
    path.lineTo(w, h * 0.65);
    path.quadraticBezierTo(w - 3, h * 0.7, w, h * 0.75);
    path.lineTo(w, h - cornerRadius);
    
    // Bottom-right corner
    path.quadraticBezierTo(w, h, w - cornerRadius, h);
    
    // Bottom edge
    path.lineTo(cornerRadius, h);
    
    // Bottom-left corner
    path.quadraticBezierTo(0, h, 0, h - cornerRadius);
    
    // Left edge with elegant curves
    path.lineTo(0, h * 0.75);
    path.quadraticBezierTo(3, h * 0.7, 0, h * 0.65);
    path.lineTo(0, h * 0.35);
    path.quadraticBezierTo(3, h * 0.3, 0, h * 0.25);
    path.lineTo(0, cornerRadius);
    
    // Top-left corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
