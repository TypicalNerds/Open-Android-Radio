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
  static const List<Color> gradientA = [Colors.blue, Colors.deepPurple,]; // Blue-Purple A
  static const List<Color> gradientB = [Colors.deepPurple, Colors.blue,]; // Blue-Purple A Reversed
  static const List<Color> gradientC = [Colors.pink, Colors.deepPurple,]; // Pink-Purple
  static const List<Color> gradientD = [Colors.blueAccent, Colors.purple,]; // Blue-Purple B
  
  
}

// Define all of the styles here to pass through when necessary
// This is separate to avoid problems where the material design text types aren't picked up correctly so manual formatting overrides can be performed.
class AppStyles {
  // Brightness Values
  static const Brightness appBrightness = Brightness.dark;

  // Placeholder Icon (used for station list)
  static Image errorIcon = Image.asset(
    "assets/icons/OAR-White.png", // Assumes local asset path
    fit: BoxFit.contain,
    width: 80,
    height: 50,
    semanticLabel: "Station Logo",
  );

  //------------------------------------------------------//
  //--------------All Text Themes Below Here--------------//
  //------------------------------------------------------//

  static const TextStyle titleLarge = TextStyle(color: Colors.white);
  static const TextStyle titleMedium = TextStyle(color: Colors.white);
  static const TextStyle titleSmall = TextStyle(color: Colors.white);

  // Label Styles
  static const TextStyle labelSmall = TextStyle(color: Colors.white);
  static const TextStyle labelMedium = TextStyle(color: Colors.white);
  static const TextStyle labelLarge = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, );

  // Display Styles

  //

  // Metadata Styles
  static const TextStyle songTitleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, overflow: TextOverflow.visible);
  static const TextStyle stationNameStyle = TextStyle(color: Colors.grey);



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

  popupMenuTheme: PopupMenuThemeData(

  )
        
  );