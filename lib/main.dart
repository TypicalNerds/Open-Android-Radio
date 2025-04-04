import 'homepage.dart';
import 'theme.dart'; // Import file for use with the themes.

import 'package:flutter/material.dart';
// Used to Access the Clipboard to import/export stations
import 'package:just_audio_background/just_audio_background.dart'; // Import service to enable background playback
// ignore: unused_import 
import 'package:url_launcher/url_launcher.dart'; // This Import is Used to Open the GitHub Repo, Don't Remove it
// This Import is Used to Open the GitHub Repo, Don't Remove it
// Import HTTP for grabbing json presets from web

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.typicalnerds.open_android_radio.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: "mipmap/ic_launcher_foreground",
    androidStopForegroundOnPause: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Android Radio',
      theme: appTheme,
      home: const MyHomePage(title: 'Open Android Radio',),
    );
  }
}

// © Connor Spowart 2024-2025
// DEVELOPMENT BUILD: NOT SUITABLE FOR PRODUCTION
