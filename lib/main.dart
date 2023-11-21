import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'add_address_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool isLoading = false; // Flag to control the visibility of the loading indicator
  Location location = new Location();
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  late LocationData _locationData;

  late GoogleMapController mapController;
  Set<Polygon> polygons = Set();
  String selectedBoxId = '';
  String selectedLargeBoxId = '';
  double currentZoom = 12.0; // Default zoom level
  static const double zoomThreshold =
      15.0; // Threshold for generating smaller boxes

  final double latStart = -15.7000; // Southwestern latitude of Lusaka province
  final double lngStart = 28.0000; // Southwestern longitude of Lusaka province
  final double latStep = 0.09; // Latitude step (difference between each box)
  final double lngStep = 0.1; // Longitude step (difference between each box)

  void getCurrentVirtualAddress() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    findVirtualAddress(_locationData);

    if (_locationData != null) {
      print("Current location: ${_locationData.latitude}, ${_locationData.longitude}");
      findVirtualAddress(_locationData);
    } else {
      print("Failed to fetch location");
    }


  }

  void findVirtualAddress(LocationData locationData) {
    if (locationData.latitude != null && locationData.longitude != null) {
      String largeBoxId = determineLargeBoxId(locationData);
      String smallBoxId = determineSmallBoxId(locationData, largeBoxId);
      String fullVirtualAddress = "ZM-LSK-LSK-$largeBoxId+$smallBoxId";

      setState(() {
        selectedBoxId = fullVirtualAddress;
      });

      // Move the camera to the current location
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(locationData.latitude!, locationData.longitude!),
            zoom: 15.0, // Adjust zoom level as needed
          ),
        ),
      );
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    } else {
      // Handle the case when latitude or longitude is null
      // For example, show an error message
      print("Location data is not available.");
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }

  }


  String determineLargeBoxId(LocationData locationData) {
    // Replace this with your logic to calculate the large box ID
    // based on locationData.latitude and locationData.longitude
    return "LargeBoxID"; // Example ID
  }

  String determineSmallBoxId(LocationData locationData, String largeBoxId) {
    // Replace this with your logic to calculate the small box ID
    // based on the location within the large box
    return "SmallBoxID"; // Example ID
  }




  @override
  void initState() {
    super.initState();
    generateBoxes();
  }



  void submitVirtualAddress(String plotNumber, String street, String ward, String district, String province, String type) {
    // Logic to submit the data to your API
    // This may involve making an HTTP request
    // After submission, you may want to reload the map or perform another action
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: getCurrentVirtualAddress,
        tooltip: 'Get Current Virtual Address',
        child: Icon(Icons.my_location),
      ),
      appBar: AppBar(
        elevation: 0,
        title: Text('ZICTA Virtual Addressing Application'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
              },
              onCameraMove: handleCameraMove,
              initialCameraPosition: CameraPosition(
                target:
                    LatLng(-15.4167, 28.2833), // Coordinates for Lusaka, Zambia
                zoom: 12.0,
              ),
              polygons: polygons,
              onTap: onBoxTap,
            ),
          ),
          GestureDetector(
            onTap: () {

              if (!isLoading) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddAddressScreen(
                      virtualAddress: selectedBoxId,
                      latitude: _locationData.latitude!,
                      longitude: _locationData.longitude!,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  if(isLoading) CircularProgressIndicator(),
                  if (!isLoading) Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Selected Box ID: $selectedBoxId',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ),
                ],
              ),
            ),
          )


        ],
      ),
    );
  }

  void handleCameraMove(CameraPosition position) {
    setState(() {
      currentZoom = position.zoom;
      currentZoom = position.zoom;
    });

    if (currentZoom >= zoomThreshold) {
      LatLng center = position.target;
      String newSelectedLargeBoxId = findLargeBoxId(center);

      // Check if the new box ID is different or if zooming back into a large box
      if (newSelectedLargeBoxId != selectedLargeBoxId || polygons.isEmpty) {
        setState(() {
          selectedLargeBoxId = newSelectedLargeBoxId;
        });
        generateSmallBoxes(selectedLargeBoxId);
      }
    } else {
      // Reset the selectedLargeBoxId when zooming out
      if (selectedLargeBoxId.isNotEmpty) {
        setState(() {
          selectedLargeBoxId = '';
        });
        clearSmallBoxes();
      }
    }
  }

  String findLargeBoxId(LatLng center) {
    int i = ((center.latitude - latStart) / latStep).floor();
    int j = ((center.longitude - lngStart) / lngStep).floor();
    return String.fromCharCode('A'.codeUnitAt(0) + i) +
        String.fromCharCode('A'.codeUnitAt(0) + j);
  }

  void clearSmallBoxes() {
    setState(() {
      polygons.removeWhere((polygon) => polygon.polygonId.value.length > 2);
    });
  }

  void generateBoxes() {
    polygons.clear();
    LatLngBounds lusakaBounds = LatLngBounds(
      southwest: LatLng(-15.7000, 28.0000),
      northeast: LatLng(-14.8000, 29.0000),
    );

    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        String boxId = String.fromCharCode('A'.codeUnitAt(0) + i) +
            String.fromCharCode('A'.codeUnitAt(0) + j);

        List<LatLng> boxCoordinates = generateBoxCoordinates(
          lusakaBounds.southwest.latitude + i * latStep,
          lusakaBounds.southwest.longitude + j * lngStep,
          lusakaBounds.southwest.latitude + (i + 1) * latStep,
          lusakaBounds.southwest.longitude + (j + 1) * lngStep,
        );

        polygons.add(
          Polygon(
            polygonId: PolygonId(boxId),
            points: boxCoordinates,
            strokeWidth: 2,
            strokeColor: Colors.blue,
            fillColor: Colors.blue.withOpacity(0.2),
          ),
        );
      }
    }
  }

  void onBoxTap(LatLng position) {
    for (Polygon polygon in polygons) {
      if (isPointInsidePolygon(position, polygon.points)) {
        String boxId = polygon.polygonId.value;

        // Check if it's a small box
        if (boxId.length > 2) {
          String bigBoxId = boxId.substring(0, 2); // Extracting the big box ID
          String smallBoxId = boxId.substring(2);  // Extracting the small box ID
          String fullAddress = "ZM-LSK-LSK-$bigBoxId$smallBoxId";

          setState(() {
            selectedBoxId = fullAddress;
          });
          return; // Stop further checks after finding the small box
        }
      }
    }
  }


  Future<String> getAddressFromLatLng(LatLng position) async {
    // Use Google's Geocoding API to fetch address details
    // Return a string in the format "Country-Province-Town-Area"
    // Example return: "ZM-LSK-LSK-MW"
    return "ZM-LSK-LSK-MW";
  }

  List<LatLng> generateBoxCoordinates(
      double minLat, double minLng, double maxLat, double maxLng) {
    return [
      LatLng(minLat, minLng),
      LatLng(maxLat, minLng),
      LatLng(maxLat, maxLng),
      LatLng(minLat, maxLng),
    ];
  }

  void generateSmallBoxes(String selectedLargeBoxId) {
    // Clear existing smaller box polygons
    polygons.removeWhere((polygon) =>
    polygon.polygonId.value.length > selectedLargeBoxId.length &&
        polygon.polygonId.value.startsWith(selectedLargeBoxId));

    LatLngBounds selectedLargeBoxBounds = calculateBounds(selectedLargeBoxId);

    // Set the number of boxes per side to 64
    int numBoxesPerSide = 64;
    double latStep = (selectedLargeBoxBounds.northeast.latitude - selectedLargeBoxBounds.southwest.latitude) / numBoxesPerSide;
    double lngStep = calculateLongitudeStep(selectedLargeBoxBounds.southwest.latitude, latStep);

    // Generate smaller boxes within the selected large box
    for (int i = 0; i < numBoxesPerSide; i++) {
      for (int j = 0; j < numBoxesPerSide; j++) {
        String letter = String.fromCharCode('A'.codeUnitAt(0) + (i / 26).floor()); // To cycle through A-Z, then start again at A
        String number = ((i % 26) * 100 + j).toString().padLeft(3, '0'); // Combination of letter cycle count and j index
        String smallBoxId = selectedLargeBoxId + letter + number;

        double boxMinLat = selectedLargeBoxBounds.southwest.latitude + i * latStep;
        double boxMinLng = selectedLargeBoxBounds.southwest.longitude + j * lngStep;

        double boxMaxLat = boxMinLat + latStep;
        double boxMaxLng = boxMinLng + lngStep;

        List<LatLng> boxCoordinates = generateBoxCoordinates(boxMinLat, boxMinLng, boxMaxLat, boxMaxLng);

        polygons.add(
          Polygon(
            polygonId: PolygonId(smallBoxId),
            points: boxCoordinates,
            strokeWidth: 2,
            strokeColor: Colors.red,
            fillColor: Colors.red.withOpacity(0.2),
          ),
        );
      }
    }

    setState(() {});
  }


// Helper method to calculate the longitude step size for approximately square boxes
  double calculateLongitudeStep(double latitude, double latStep) {
    const double metersPerDegreeLatitude = 111320; // Approximate value
    double latDistanceMeters = latStep * metersPerDegreeLatitude;
    double metersPerDegreeLongitude = metersPerDegreeLatitude * cos(latitude * pi / 180);
    return latDistanceMeters / metersPerDegreeLongitude;
  }



  LatLngBounds calculateBounds(String boxId) {
    int i = boxId.codeUnitAt(0) - 'A'.codeUnitAt(0);
    int j = boxId.codeUnitAt(1) - 'A'.codeUnitAt(0);

    LatLngBounds lusakaBounds = LatLngBounds(
      southwest: LatLng(-15.7000, 28.0000),
      northeast: LatLng(-14.8000, 29.0000),
    );

    double boxMinLat = lusakaBounds.southwest.latitude + i * latStep;
    double boxMinLng = lusakaBounds.southwest.longitude + j * lngStep;

    return LatLngBounds(
      southwest: LatLng(boxMinLat, boxMinLng),
      northeast: LatLng(boxMinLat + latStep, boxMinLng + lngStep),
    );
  }

  bool isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;

    for (int i = 0; i < polygon.length - 1; i++) {
      if ((polygon[i].longitude > point.longitude) !=
              (polygon[i + 1].longitude > point.longitude) &&
          point.latitude <
              (polygon[i + 1].latitude - polygon[i].latitude) *
                      (point.longitude - polygon[i].longitude) /
                      (polygon[i + 1].longitude - polygon[i].longitude) +
                  polygon[i].latitude) {
        intersectCount++;
      }
    }

    return (intersectCount % 2) == 1;
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
