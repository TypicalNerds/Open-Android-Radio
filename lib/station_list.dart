import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Used to Access the Clipboard to import/export stations
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; // Import service to enable background playback
import 'package:open_android_radio/theme.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import Shared Preferences library to allow saving of stations

// This Import is Used to Open the GitHub Repo, Don't Remove it
// Import HTTP for grabbing json presets from web

// Define All Default Radio Staions Here
// I'll admit, I didn't remember how to add these lists, so I used AI to create a sample template and went from there.
// Stations should have a URL for the stream and Logo as well as a Name to avoid issues.
List<Map<String, dynamic>> stations = [];

class StationList extends StatelessWidget {
  final List<Map<String, dynamic>> stations;
  final AudioPlayer player;
  final Function(int, BuildContext) removeStation;
  
  // Create List of Stations
  const StationList({super.key, required this.stations, required this.player, required this.removeStation,});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        return 
        Column(
          children: [
            Dismissible(
              key: Key(station['name']),
              background: Container(color: Colors.red),
              direction: DismissDirection.none,
              confirmDismiss: (direction) async {
            // Show a confirmation dialog before dismissing the item
            bool? confirmed = await _showConfirmationDialog(context);
            return confirmed ?? false; // If user cancels, it won't dismiss
          },
              onDismissed: (direction) {
                removeStation(index, context); // Confirmation dialog for dismissal
              },
              // Define whats shown on each station's tile.
              child: ListTile(
                enabled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 1.25),
                titleAlignment: ListTileTitleAlignment.center,
                
                // Add in Radio Station Image
                // If station image contains "http", assume it's a network image
                leading: station.containsKey('imageUrl') && station['imageUrl'] != null
                  ? station['imageUrl'].contains('http')
                  ? Image.network(
                    station['imageUrl'],
                    fit: BoxFit.contain,
                    width: 80,
                    height: 50,
                    semanticLabel: "${station['name']} logo",
                    errorBuilder: (context, error, stackTrace) => AppStyles.errorIcon, // Assume Placeholder if it fails
                  )
                  // If it doesn't have HTTP, assume it's a local image asset
                  : Image.asset(
                    station['imageUrl'], // Assumes local asset path
                    fit: BoxFit.contain,
                    width: 80,
                    height: 50,
                    semanticLabel: "${station['name']} logo",
                    errorBuilder: (context, error, stackTrace) => AppStyles.errorIcon, // Assume Placeholder Image if it fails to load
                  )
                  : AppStyles.errorIcon, // If it breaks, show a placeholder defined in the AppStyles
                    // Add Station Name
                title: TextScroll(
                  station['name'],
                  style: AppStyles.labelLarge,
                  velocity: Velocity(pixelsPerSecond: Offset(10,0)),
                  fadedBorder: true,
              fadeBorderSide: FadeBorderSide.both,
              textAlign: TextAlign.left,
              pauseBetween: Duration(seconds: 3),
              intervalSpaces: 12,
            
                ),
                tileColor: Colors.black87,
                minLeadingWidth: 80,
                minVerticalPadding: 8,
                minTileHeight: 50,
                onTap: () async {
                  // Try to change the audio source and play the newly selected station
                  try {
                    if (player.playerState.playing == true) {
                      await player.stop();
                      // TODO - Clear Player Cache when Stopped
                    }
                    // For some reason the stop command would sometimes get executed after stopping a station, hardcode a delay here to ensure it goes in the right order.
                    Future.delayed(Durations.medium2, () {
                      AudioSource source = AudioSource.uri(
                        Uri.parse(
                          station['link']
                        ),
                        tag: MediaItem(
                        id: "",
                        title: station['name'],
                        artist: "Open Android Radio",
                        artUri: _getArtUri(station['imageUrl']), // Clean up the Art URI (check if local asset or web)
                        isLive: true,
                          ),
                        );
                      
                    
                    player.setAudioSource(source);
                    player.play();
                    player.setLoopMode(LoopMode.one);
                    },);

                  } on PlayerException catch (e) {
                    // If an error occurs, copy it to clipboard and display an error message.
                    await Clipboard.setData(ClipboardData(text: "Error Log: $e"));  // Using built-in Clipboard functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Error Occured: Copied to Clipboard")),
                      );

                  }
                },

                // Add Icon to Open Submenu (Edit/Remove Options)
                trailing: IconButton(
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  onPressed: () {
                    // Open the Drop Down when pressed
                    _stationDropdown(context, station, index);
                  },

                  // Define the icon
                  icon: Container(
                    // Give it a bit of colour
                  decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: AppColors.gradientC,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  ),
                ),
                // Choose the actual Icon
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    semanticLabel: "More Options",
                  ),
                  )
                  ),
              ),
            ),
            Divider(
              color: Colors.grey, // Color of the divider line
              thickness: 1, // Thickness of the divider line
              height: 1, // Height between the tiles and the divider
            ),
          ],
        );
      },
    );
  }

  // Menu to be shown to give user options to either remove a station or edit it
void _stationDropdown(BuildContext context, Map<String, dynamic> station, int index) {
  showAdaptiveDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Station Options"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit Station
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Edit Station"),
              onTap: () {
                Navigator.pop(context);
                // Show the Edit Menu
                _showEditStationDialog(context, station, index);
              }
            ),
            // Remove Button
            ListTile(
              leading: Icon(Icons.delete),
              title: Text("Remove Station"),
              onTap: () {
                Navigator.pop(context);
                removeStation(index, context);
              } 
              
            ),
            // Close Menu
            ListTile(
              leading: Icon(Icons.close),
              title: Text("Close Menu"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ) 

      );
    },);
}

  // This method shows a confirmation dialog
  // TODO - Add to Remove Station Code to Give Confirmation
  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: const Text('Are you sure you want to remove this station?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // User canceled
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // User confirmed
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// Edit Station Menu
void _showEditStationDialog(BuildContext context, Map<String, dynamic> station, int index,) {
  final nameController = TextEditingController(text: station['name']);
  final linkController = TextEditingController(text: station['link']);
  final imageUrlController = TextEditingController(text: station['imageUrl']);

  // FocusNodes to manage focus between fields
  final nameFocusNode = FocusNode();
  final linkFocusNode = FocusNode();
  final imageUrlFocusNode = FocusNode();

  // Variables to track validation state and error messages
  bool isNameValid = true;
  bool isLinkValid = true;
  bool isImageUrlValid = true;

  // Show the edit station dialog
  showDialog(
    barrierDismissible: false, // Makes it so clicking outside the pop-up doesn't close it (makes it less frustrating to use)
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Station'),
            content: SingleChildScrollView( // Make the content scrollable
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Station Name*',
                      errorText: isNameValid ? null : 'This field is required',
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next, // Move to next field when Enter is pressed
                    onEditingComplete: () {
                      // Move focus to the next field
                      FocusScope.of(context).requestFocus(linkFocusNode);
                    },
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: linkController,
                    focusNode: linkFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Stream URL*',
                      errorText: isLinkValid ? null : 'This field is required',
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    textInputAction: TextInputAction.next, // Move to next field when Enter is pressed
                    onEditingComplete: () {
                      // Move focus to the next field
                      FocusScope.of(context).requestFocus(imageUrlFocusNode);
                    },
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: imageUrlController,
                    focusNode: imageUrlFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Image URL*',
                      errorText: isImageUrlValid ? null : 'This field is required',
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    textInputAction: TextInputAction.done, // "Done" action to complete the form
                    onEditingComplete: () {
                      // Trigger the Save button's action (or any other form submission action)
                      setState(() {
                        // Validation logic on form submission
                        isNameValid = nameController.text.isNotEmpty;
                        isLinkValid = linkController.text.isNotEmpty;
                        isImageUrlValid = imageUrlController.text.isNotEmpty;
                      });

                      // TODO - Potentially Saving When Edit Menu is closed unnecessarily
                      // Only proceed if all fields are valid
                      if (isNameValid && isLinkValid && isImageUrlValid) {
                        // Update the station in the list
                        stations[index] = {
                          'name': nameController.text,
                          'link': linkController.text,
                          'imageUrl': imageUrlController.text,
                        };
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Close dialog without action
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Validate and submit the form when the Save button is pressed
                  setState(() {
                    isNameValid = nameController.text.isNotEmpty;
                    isLinkValid = linkController.text.isNotEmpty;
                    isImageUrlValid = imageUrlController.text.isNotEmpty;
                  });

                  // Only proceed if all fields are valid
                  if (isNameValid && isLinkValid && isImageUrlValid) {
                    // Update the station in the list
                    stations[index] = {
                      'name': nameController.text,
                      'link': linkController.text,
                      'imageUrl': imageUrlController.text,
                    };

                    // Save the updated list to SharedPreferences
                    SharedPreferences.getInstance().then((prefs) {
                      final encodedStations = jsonEncode(stations);
                      prefs.setString('customStations', encodedStations);
                      // Trigger a rebuild by calling setState in the parent widget
                      ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Refresh Required to Show Changes")),
                      );
                      Navigator.pop(context); // Close the dialog

                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

// Sanitise Art URI
Uri _getArtUri(String? url) {
  if (url == null || url.isEmpty) {
    return Uri.parse("https://raw.githubusercontent.com/TypicalNerds/LakesideTV-Channel-Logos/refs/heads/main/Radio/Generic-OAR/Generic-Pink.png");
  }

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Uri.parse(url); // If already a valid HTTP URL, use it
  }

  // If the URL is an asset path, strip "assets/images/" and use GitHub raw URL
  return Uri.parse("https://raw.githubusercontent.com/TypicalNerds/LakesideTV-Channel-Logos/refs/heads/main/Radio/Generic-OAR/${url.replaceFirst("assets/images/", "")}");
}