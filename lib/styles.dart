import 'package:flutter/material.dart';

class MyButtonStyles {
  static const ButtonStyle elevatedButtonStyle = ButtonStyle(
    elevation: WidgetStatePropertyAll(3),
    textStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
    ),
  );
}
