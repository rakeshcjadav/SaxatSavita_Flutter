import 'package:flutter/material.dart';

class ElevatedButtonWithIcon extends ElevatedButton {
  const ElevatedButtonWithIcon({
    super.key,
    required Widget child,
    required super.onPressed,
  }) : super(child: child);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: () {}, child: Column());
  }
}
