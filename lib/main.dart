
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
  print("Initializing JustAudioBackground...");
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.typicalnerds.open_android_radio.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  print("Initialized JustAudioBackground...");
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
// I'll admit, I didn't remember how to add these lists, so I used Google Gemini to create a sample template and went from there.
// Stations should have a URL for the stream and Logo as well as a Name to avoid issues.
List<Map<String, dynamic>> stations = [];

class StationList extends StatelessWidget {
  final List<Map<String, dynamic>> stations;
  final AudioPlayer player;
  final Function(int, BuildContext) removeStation;
  
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
              confirmDismiss: (direction) async {
            // Show a confirmation dialog before dismissing the item
            bool? confirmed = await _showConfirmationDialog(context);
            return confirmed ?? false; // If user cancels, it won't dismiss
          },
              onDismissed: (direction) {
                removeStation(index, context); // Confirmation dialog for dismissal
              },
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
              intervalSpaces: 15,
            
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
                    print("Error Playing Station: $e");
                  }
                },
                onLongPress: () {
                  _showEditStationDialog(context, station, index);
                },
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
  // This method shows a confirmation dialog
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

// Setup the function for the edit station button
void _showEditStationDialog(BuildContext context, Map<String, dynamic> station, int index) {
  final nameController = TextEditingController(text: station['name']);
  final linkController = TextEditingController(text: station['link']);
  final imageUrlController = TextEditingController(text: station['imageUrl']);

  // show that dialogue
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        // give it a not so fancy title
        title: const Text('Edit Station'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Station Name'),
              keyboardType: TextInputType.name,
            ),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(hintText: 'Stream URL'),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            TextField(
              controller: imageUrlController,
              decoration: const InputDecoration(hintText: 'Image URL'),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Update the station in the list
              stations[index] = {
                'name': nameController.text,
                'link': linkController.text,
                'imageUrl': imageUrlController.text,
              };

              // Save the updated list to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final encodedStations = jsonEncode(stations);
              await prefs.setString('customStations', encodedStations);

              // Trigger UI update and close dialog
              Navigator.pop(context);
              (context as Element).markNeedsBuild(); // Refresh the widget tree
            },
            child: const Text('Save'),
          ),
        ],
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

void _showImportPresetsMenu(BuildContext context) async {
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedPreset != null) {
                    Navigator.pop(context); // Close the dialog
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

void addCustomStation() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final linkController = TextEditingController();
        final imageUrlController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Station'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Station Name'),
                keyboardType: TextInputType.name,
                
              ),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(hintText: 'Stream URL'),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(hintText: 'Image URL'),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog without action
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  stations.add({
                    'name': nameController.text,
                    'link': linkController.text,
                    'imageUrl': imageUrlController.text,
                  }); // Dynamically add the station to `stations` and trigger UI update
                  saveCustomStations(); // Save updated stations
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Confirmation dialog to remove a station
  void removeStation(int index, BuildContext context) {
    setState(() {
                  stations.removeAt(index); // CHANGED: Dynamically remove the station and trigger UI update
                  saveCustomStations(); // Save updated stations
                });
  }




  @override
  void initState() {
    super.initState();
    loadCustomStations();

    player.icyMetadataStream.listen((metadata) {
      setState(() {
        // Check if there is any song or station data present and that it is not blank
        // If there is no song title but is a radio station detected,
        // fallback to "Open Android Radio" as station name, "No Data" as songTitle
        //
        // If there is no station name or title metadata available, fallback to "Open Android Radio" as station name, "No Data" as songTitle
        if (metadata?.info?.title.toString().isEmpty == true && metadata?.headers?.name.toString().isEmpty == false) {
          songTitle = metadata?.headers?.name.toString() ?? "No Data";
          stationName = "Open Android Radio";
        } else {
          songTitle = metadata?.info?.title.toString() ?? metadata?.headers?.name.toString() ?? "No Data";
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18
          ),
          actions: [
          ],
      ),

      body: StationList(stations: stations, player: player, removeStation: removeStation),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Open Android Radio \n(v0.0.4-beta)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // Button to add Custom Stations
            ListTile(
              title: const Text('Add Station'),
              leading: const Icon(Icons.add),
              onTap: addCustomStation,
            ),
            ListTile(
              title: const Text('Export Stations'),
              leading: const Icon(Icons.file_copy),
              onTap: exportStationsToClipboard,
            ),
            ListTile(
              title: const Text('Import Stations'),
              leading: const Icon(Icons.import_export),
              onTap: importStationsFromClipboard,
            ),
            // Option to Restore Stations from Default List
            ListTile(
              title: const Text('Online Preset'),
              leading: const Icon(Icons.restore),
              onTap: () => _showImportPresetsMenu(context),
              ),
              // Opens the GitHub Repo
            ListTile(
              title: const Text('Github Repo'),
              leading: const Icon(Icons.code),
              onTap: () => launchUrlString("https://github.com/TypicalNerds/Open-Android-Radio"),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 0),
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

        IconButton(
          icon: const Icon(Icons.stop),
          onPressed: () {
            player.stop();
          },
        ),
      ],
    ),
  ),
),

    );
  }
}
// © Connor Spowart 2024
// DEVELOPMENT BUILD: NOT SUITABLE FOR PRODUCTION
