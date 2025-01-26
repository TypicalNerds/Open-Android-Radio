import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Used to Access the Clipboard to import/export stations
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; // Import service to enable background playback
import 'package:text_scroll/text_scroll.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import Shared Preferences library to allow saving of stations
// ignore: unused_import 
import 'package:url_launcher/url_launcher.dart'; // This Import is Used to Open the GitHub Repo, Don't Remove it
import 'package:url_launcher/url_launcher_string.dart'; // This Import is Used to Open the GitHub Repo, Don't Remove it
import 'package:http/http.dart' as http; // Import HTTP for grabbing json presets from web

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.typicalnerds.open_android_radio.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
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
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
        ),
        
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Open Android Radio',),
    );
  }
}

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
                leading: station.containsKey('imageUrl')
                    ? Image.network(
                        station['imageUrl'],
                        fit: BoxFit.contain,
                        width: 80,
                        height:50 ,
                        semanticLabel: "${station['name']} logo",
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.radio,
                          size: 40,
                        ),
                      )
                    : const Icon(Icons.radio, size: 40),
                    // Add Station Name
                title: TextScroll(
                  station['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                overflow: TextOverflow.visible,
                ),
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
                          album: "Open Android Radio",
                          artUri: Uri.parse(station['imageUrl']),
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
                    colors: [
                    Colors.pink,
                    Colors.deepPurple,
                  ],
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
                _showEditStationDialog(context, station, index);
                // TODO - RELOAD ON EDIT
                
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

void _showEditStationDialog(BuildContext context, Map<String, dynamic> station, int index) {
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
    barrierDismissible: false,
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
                          Navigator.pop(context); // Close the dialog
                        });
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



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  
  @override
  State<MyHomePage> createState() => _MyHomePageState();
  
}



// This is the main part of the homepage
class _MyHomePageState extends State<MyHomePage> {
  // Initalise Just Audio
  //final player = AudioPlayer();
  final player = AudioPlayer(
      userAgent: 'openandroidradio/1.0 (Linux;Android 15)',
  useProxyForRequestHeaders: true, // default
);
// Create songTitles and stationName Variables
String? songTitle = "";
String? stationName = "";
// Create placeholder widgets to initialise TextScroll variables
Widget songTitleScroll = const TextScroll("Nothing is Playing Right Now");
Widget stationNameScroll = const TextScroll("Open Android Radio");
Widget floatingStopButton = FloatingActionButton(
  onPressed: () => print("it kept complaining about using null here so here you go you fucking dumbass compiler"),
  child: Icon(Icons.stop, semanticLabel: "Stop Playback",),
  tooltip: "Stop Playback",
  );

// Menu to be shown to give user options to either remove a station or edit it
void _importTypeSelection(BuildContext context, List<Map<String, dynamic>> stations) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Import Options"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Import from Device Clipboard
            ListTile(
              leading: Icon(Icons.paste),
              title: Text("From Clipboard"),
              onTap: () {
                importStationsFromClipboard();
                Navigator.pop(context);
              }
            ),
            // Remove Prompt
            ListTile(
              leading: Icon(Icons.code),
              title: Text("From OAR GitHub"),
              onTap: () {
                Navigator.of(context).pop();
                _showGitHubImportPresetsMenu();
              },
              
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

// Export stations to clipboard
  Future<void> exportStationsToClipboard() async {
    // ignore: unused_local_variable
    final prefs = await SharedPreferences.getInstance(); // Im fucking terrified what this will do if it's removed so lets leave it alone
    final encodedStations = jsonEncode(stations);
    await Clipboard.setData(ClipboardData(text: encodedStations));  // Using built-in Clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Stations exported to clipboard.")),
    );
  }

  // Import stations from clipboard
  Future<void> importStationsFromClipboard() async {
  final clipboardData = await Clipboard.getData('text/plain');
  if (clipboardData != null && clipboardData.text != null) {
    try {
      // Decode the stations from the clipboard data
      final decodedStations = jsonDecode(clipboardData.text!) as List<dynamic>;

      // Update the stations list
      setState(() {
        stations = decodedStations.cast<Map<String, dynamic>>().toList();
      });

      // Save the imported stations to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final encodedStations = jsonEncode(stations);
      await prefs.setString('customStations', encodedStations);  // Save to preferences

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stations imported and saved.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to import stations.")),
      );
    }
  }
}

// Selection for Importing Web Presets from OAR-Presets GitHub
// GitHub Repo Available Here: https://github.com/TypicalNerds/OAR-Presets/
void _showGitHubImportPresetsMenu() async {
  // Specify the URL for grabbing the presets
  const presetsConfigUrl =
      'https://raw.githubusercontent.com/TypicalNerds/OAR-Presets/refs/heads/main/preset-config.json';

  try {
    // Fetch the presets configuration file
    final response = await http.get(Uri.parse(presetsConfigUrl));

    if (response.statusCode == 200) {
      final List<dynamic> presetsJson = jsonDecode(response.body);
      final List<Map<String, String>> presets = presetsJson.map((preset) {
        return {
          'name': preset['name'].toString(),
          'description': preset['description'].toString(),
          'url': preset['url'].toString(),
        };
      }).toList();

      // Show dialog with dynamically loaded presets
      showDialog(
        context: context,
        builder: (context) {
          Map<String, String>? selectedPreset;
          return AlertDialog(
            title: const Text('Import Presets'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: DropdownButtonFormField<Map<String, String>>(
                    decoration: const InputDecoration(labelText: 'Select a Preset'),
                    isExpanded: true, // Ensures dropdown expands to available width
                    items: presets
                        .map((preset) => DropdownMenuItem<Map<String, String>>(
                              value: preset,
                              child: Text(
                                preset['name'] ?? 'Unnamed Preset',
                                overflow: TextOverflow.ellipsis, // Handle text overflow
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPreset = value;
                      });
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedPreset != null) {
                    Navigator.of(context).pop(); // Close the dialog
                    await _importDefaultStationsFromWeb(
                        context, selectedPreset!['url']!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a preset.')),
                    );
                  }
                },
                child: const Text('Import'),
              ),
            ],
          );
        },
      );
    } else {
      throw Exception('Failed to fetch presets configuration. Status code: ${response.statusCode}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to load presets configuration.")),
    );
  }
}


// Call this to initiate the import process of a station using a preset from a URL
Future<void> _importDefaultStationsFromWeb(BuildContext context, String url) async {
  try {
    // Fetch stations from the selected URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print("----- Response Code Passed");
      // Decode the stations from the URL response
      final decodedStations = (jsonDecode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();

      // Update the stations list
      setState(() {
        stations = decodedStations;
      });

      // Save the imported stations to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final encodedStations = jsonEncode(stations);
      await prefs.setString('customStations', encodedStations);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preset stations imported and saved.")),
      );
    } else {
      throw Exception('Failed to fetch stations. Status code: ${response.statusCode}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to import stations.")),
    );
  }
}

// Function to save stations
Future<void> saveCustomStations() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedStations = jsonEncode(stations);
    await prefs.setString('customStations', encodedStations);
    loadCustomStations();
  }

// Function used to load saved stations
Future<void> loadCustomStations() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedStations = prefs.getString('customStations');
    if (encodedStations != null) {
      final decodedStations = jsonDecode(encodedStations) as List<dynamic>;
      setState(() {
        stations = decodedStations.cast<Map<String, dynamic>>().toList();
      });
    }
  }

// Prompt user to enter values for custom station.
void addCustomStation() {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
    builder: (context) {
      final nameController = TextEditingController();
      final linkController = TextEditingController();
      final imageUrlController = TextEditingController();

      // FocusNodes to manage the focus between fields
      final nameFocusNode = FocusNode();
      final linkFocusNode = FocusNode();
      final imageUrlFocusNode = FocusNode();

      // Variables to track validation state and error messages
      bool isNameValid = true;
      bool isLinkValid = true;
      bool isImageUrlValid = true;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Station'),
            content: SingleChildScrollView( // Make the content scrollable
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Station Name',
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
                      hintText: 'Stream URL',
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
                      hintText: 'Image URL',
                      errorText: isImageUrlValid ? null : 'This field is required',
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    textInputAction: TextInputAction.done, // "Done" action to complete the form
                    onEditingComplete: () {
                      // Trigger the Add button's action (or any other form submission action)
                      setState(() {
                        // Validation logic on form submission
                        isNameValid = nameController.text.isNotEmpty;
                        isLinkValid = linkController.text.isNotEmpty;
                        isImageUrlValid = imageUrlController.text.isNotEmpty;
                      });

                      // Only proceed if all fields are valid
                      if (isNameValid && isLinkValid && isImageUrlValid) {
                        stations.add({
                          'name': nameController.text,
                          'link': linkController.text,
                          'imageUrl': imageUrlController.text,
                        });
                        saveCustomStations(); // Save updated stations
                        Navigator.pop(context); // Close dialog after adding the station
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
                  // Validate and submit the form when the Add button is pressed
                  setState(() {
                    isNameValid = nameController.text.isNotEmpty;
                    isLinkValid = linkController.text.isNotEmpty;
                    isImageUrlValid = imageUrlController.text.isNotEmpty;
                  });

                  // Only proceed if all fields are valid
                  if (isNameValid && isLinkValid && isImageUrlValid) {
                    stations.add({
                      'name': nameController.text,
                      'link': linkController.text,
                      'imageUrl': imageUrlController.text,
                    });
                    saveCustomStations(); // Save updated stations
                    Navigator.pop(context); // Close dialog after adding the station
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}

// TODO - Add Confirmation
  // Confirmation dialog to remove a station
  void removeStation(int index, BuildContext context) {
    setState(() {
                  stations.removeAt(index); // Dynamically remove the station and trigger UI update
                  saveCustomStations(); // Save updated stations
                });
  }

  @override
  void initState() {
    super.initState();
    loadCustomStations();
    
    // Listen for when there is media playing or not
    player.playerStateStream.listen(
      (PlayerState) {
          if (PlayerState.playing == true || PlayerState.processingState == ProcessingState.buffering || PlayerState.processingState == ProcessingState.loading) {
            // If nothing is playing, remove the stop button
            setState(() {
              floatingStopButton = Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  gradient: LinearGradient(
                    colors: [
                    Colors.pink,
                    Colors.deepPurple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  ),
                ),
                child: FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  onPressed: () => player.stop(),
                  child: Icon(Icons.stop, semanticLabel: "Stop",),
                  ),
              );
              

            });
            
           } else {
            // If Something is Playing, Enable the Stop Button
            setState(() {
              floatingStopButton = Container();
            });
            
            
           }
        
      },

    );

    player.icyMetadataStream.listen((metadata) {
      setState(() {
        // Check if there is any song or station data present and that it is not blank
        // If there is no song title but is a radio station detected,
        // fallback to "Open Android Radio" as station name, "No Data" as songTitle
        //
        // If there is no station name or title metadata available, fallback to "Open Android Radio" as station name, "No Data" as songTitle

        // Check if Player is Loading
        if (player.playerState.playing == false && player.playerState.processingState == ProcessingState.loading || player.playerState.playing == false && player.playerState.processingState == ProcessingState.buffering) {
          songTitle = metadata?.headers?.name.toString() ?? "Loading";
          stationName = "Open Android Radio";
          // Next Line: No Metadata at all will display unavailable message
        } else if (metadata?.headers == null && metadata?.info == null) {
          songTitle = "Metadata Unavailable";
          stationName = "Open Android Radio";
          // Next If: If song metadata is empty & station isn't, show just station name with OAR placeholder text.
        } else if (metadata?.info?.title.toString().isEmpty == true && metadata?.headers?.name.toString().isEmpty == false) {
          songTitle = metadata?.headers?.name.toString() ?? "Metadata Error";
          stationName = "Open Android Radio";
          // Next Line Checks if Track info is present but no station name is present
        } else if (metadata?.info?.title.toString().isEmpty == false && metadata?.headers?.name.toString().isEmpty == true) {
          songTitle = metadata?.info?.title.toString() ?? "Metadata Error";
          stationName = "Open Android Radio";
          // Next Line checks if the metadata is blank for both station & song names
        } else if (metadata?.info?.title.toString().isEmpty == true && metadata?.headers?.name.toString().isEmpty == true) {
          songTitle = "Metadata Unavailable";
          stationName = "Open Android Radio";
        } else {
          songTitle = metadata?.info?.title.toString() ?? metadata?.headers?.name.toString() ?? "Metadata Error";
          stationName = metadata?.headers?.name.toString() ?? "Open Android Radio";
        }

        // Update songTitleScroll widget with new text and refresh formatting.
        songTitleScroll = TextScroll(
          songTitle!,
          fadedBorder: true,
          fadeBorderSide: FadeBorderSide.both,
          textAlign: TextAlign.left,
          pauseBetween: Duration(seconds: 0),
          velocity: const Velocity(pixelsPerSecond: Offset(20, 0)),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            overflow: TextOverflow.visible,
            ),
            intervalSpaces: 15,
          
          );
          // Update stationNameScroll widget with new text and refresh formatting.
        stationNameScroll = TextScroll(
          stationName!,
          style: const TextStyle(color: Colors.grey),
          );
      });
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      // That goofy ahh bar at the top of the screen
      appBar: AppBar(
        // App Bar Gradient (makes that shit look a little bit nicer)
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue, ],
                  transform: GradientRotation(1),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  ),
          ),
        ),
        // Title of the App
        title: Text(widget.title),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18
          ),
          // Debugging Code, Uncomment to print current icymetadata
          // actions: [
          //   IconButton(onPressed: () {
          //     print("----- ICY Headers:  ${player.icyMetadata!.headers}");
          //     print("----- ICY Info:  ${player.icyMetadata!.info}");
          //   }, icon: Icon(Icons.print)),
          // ],
      ),

      body: StationList(stations: stations, player: player, removeStation: removeStation,),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.deepPurple,],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  ),
              ),
              child: Text(
                'Open Android Radio \n(v0.0.6-beta)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // Button to allow the user to add Custom Stations
            ListTile(
              title: const Text('Add Station'),
              leading: const Icon(Icons.add),
              onTap: addCustomStation,
            ),
            // Opens the Import Type Selection Menu
            ListTile(
              title: const Text('Import Stations'),
              leading: const Icon(Icons.import_export),
              onTap: () => _importTypeSelection(context, stations),
            ),
            ListTile(
              title: const Text('Export Stations'),
              leading: const Icon(Icons.file_copy),
              onTap: exportStationsToClipboard,
            ),
              // Opens the GitHub Repo
            ListTile(
              title: const Text('GitHub Repo'),
              leading: const Icon(Icons.code),
              onTap: () => launchUrlString("https://github.com/TypicalNerds/Open-Android-Radio"),
            ),
            ListTile(
              title: const Text('Terms of Use'),
              leading: const Icon(Icons.info),
              onTap: () => launchUrlString("https://github.com/TypicalNerds/Open-Android-Radio/blob/main/ToS.md"),
            ),
            ListTile(
              title: const Text('Help'),
              leading: const Icon(Icons.help_center),
              onTap: () => launchUrlString("https://youtube.com/playlist?list=PLFetoIJeQKyodXVrshz4SW8xuAvlEddf6"),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: kBottomNavigationBarHeight,
          
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    songTitleScroll,
                    stationNameScroll,
                  ],
                ),
        ),
      ],
    ),
  ),
),
floatingActionButton: floatingStopButton,
floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
    );
  }
}
// © Connor Spowart 2024
// DEVELOPMENT BUILD: NOT SUITABLE FOR PRODUCTION
