
import 'package:flutter/material.dart';
import 'package:open_android_radio/station_list.dart';
import 'package:open_android_radio/theme.dart'; // Needed for theming the app

import 'dart:convert';
import 'package:text_scroll/text_scroll.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import Shared Preferences library to allow saving of stations

// Import HTTP for grabbing json presets from web

class ChangeOrder extends StatefulWidget {
  const ChangeOrder({super.key, required this.stations});
  final List<Map<String, dynamic>> stations;
  
  @override
  State<ChangeOrder> createState() => _ChangeOrderState(); 
}

class _ChangeOrderState extends State<ChangeOrder> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Re-Arrange Stations",
          style: AppStyles.titleLarge,
        ),

      ),
      body: ReorderableListView.builder(
        itemCount: stations.length,
        buildDefaultDragHandles: false, // Disable default drag handle to avoid entire handle from being button
        onReorder: (oldIndex, newIndex) async {
          var reorderedStations = stations;
          if (newIndex > oldIndex) {
              newIndex -= 1;
          }

          // Remove the item at oldIndex and insert it at newIndex
          final item = reorderedStations[oldIndex];
          reorderedStations.removeAt(oldIndex);
          reorderedStations.insert(newIndex, item);

          // Set stations list to the new order
          setState(() {
            // Replace the old list entirely
            stations = List.from(reorderedStations);
          });

          // Save the updated list to SharedPreferences
          SharedPreferences.getInstance().then((prefs) {
            final encodedStations = jsonEncode(stations);
            prefs.setString('customStations', encodedStations);
          });
        },
        
        itemBuilder: (context, index) {
          final station = stations[index];
          return Column(
            key: Key(station['name']),
            children: [
              ListTile(
                enabled: true,
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
                onLongPress: null,

                // Add drag handle
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle),
                ),
              )
            ],
          );
      },
      ),


    );
  }
  

}