import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 4;
  static const double xl = 6;
  static const double pill = 4;

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
  static BorderRadius get panel => BorderRadius.circular(xl);
  static BorderRadius get rounded => BorderRadius.circular(pill);
}
