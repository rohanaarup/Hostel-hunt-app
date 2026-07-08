import 'package:flutter/material.dart';

final ValueNotifier<bool> themeNotifier = ValueNotifier<bool>(false);

void toggleTheme() {
  themeNotifier.value = !themeNotifier.value;
}
