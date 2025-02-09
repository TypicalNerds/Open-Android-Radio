import 'package:flutter/material.dart';
import 'dart:io';

// Identifiers used to get app version and user agents are located here
class Identifiers {
  static String appVersion = "0.0.7"; // App Version Number

  String getUserAgent() {
    if (Platform.isAndroid) {
      return "OpenAndroidRadio/$appVersion (Android; Linux) JustAudio";
    } else if (Platform.isIOS) {
      return "OpenAndroidRadio/$appVersion (iOS) JustAudio";
    } else {
      return "OpenAndroidRadio/$appVersion (Unknown) JustAudio";
    }
  }
}

// Define the apps Colour scheme here to keep it easier to manage.
// TODO - Move existing formatting to this file
class AppColors {
  // Text
  static const Color primary = Colors.white;

  // Backgrounds

  // Gradients

}

// Define all of the styles here to pass through when necessary
// This is separate to avoid problems where the material design text types aren't picked up correctly so manual formatting overrides can be performed.
class AppStyles {
  // Brightness Values
  static const Brightness appBrightness = Brightness.dark;

  // All Text Themes Here
  static const TextStyle titleLarge = TextStyle(color: Colors.white);
  static const TextStyle titleMedium = TextStyle(color: Colors.white);
  static const TextStyle titleSmall = TextStyle(color: Colors.white);

}

// Define the Material App Theme to pass through to the
ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: AppStyles.appBrightness,

  textTheme: const TextTheme(
    titleLarge: AppStyles.titleLarge,
    titleMedium: AppStyles.titleMedium,
    titleSmall: AppStyles.titleSmall,
  ),
        
  );