import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'add_address_screen.dart';
import 'package:geocoding_resolver/geocoding_resolver.dart';


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
  GeoCoder geoCoder = GeoCoder();
  bool isLoading = false;
  Location location = new Location();
  late LocationData _locationData;
  late Marker _currentLocationMarker;
  Set<Marker> _markers = Set();
  late GoogleMapController mapController;
  String selectedBoxId = '';
  final double latStart = -15.7000;
  final double lngStart = 28.0000;
  final double latStep = 0.09;
  final double lngStep = 0.1;
  Set<Polygon> polygons = Set<Polygon>();
  String detailedAddress = "";
  String gAddress = "";
  int gPlaceId = 0;
  String gProvince = "";


  @override
  void initState() {
    super.initState();
    getCurrentVirtualAddress();
    generateBoxes();
  }

  void getCurrentVirtualAddress() async {
    setState(() => isLoading = true);

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() => isLoading = false);
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() => isLoading = false);
        return;
      }
    }

    _locationData = await location.getLocation();
    findVirtualAddress(_locationData);
  }

  List<LatLng> generateBoxCoordinates(double minLat, double minLng, double maxLat, double maxLng) {
    return [
      LatLng(minLat, minLng),
      LatLng(maxLat, minLng),
      LatLng(maxLat, maxLng),
      LatLng(minLat, maxLng),
    ];
  }

  Future<String> generateUniqueVirtualAddress(double latitude, double longitude) async {
    Address address = await geoCoder.getAddressFromLatLng(latitude: latitude, longitude: longitude);

    // Use parts of the address to create a virtual address
    String virtualAddress = "${address.addressDetails.neighbourhood}-${address.addressDetails.city}-${address.addressDetails.countryCode}";

    return virtualAddress;
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


  void findVirtualAddress(LocationData initialLocation) {
    // Update for the first location fetch
    updateVirtualAddressAndMarker(initialLocation);

    // Setting up a listener for location changes
    location.onLocationChanged.listen((LocationData currentLocation) {
      updateVirtualAddressAndMarker(currentLocation);
    });
  }

  void updateVirtualAddressAndMarker(LocationData locationData) {
    if (locationData.latitude != null && locationData.longitude != null) {
      LatLng position = LatLng(locationData.latitude!, locationData.longitude!);
      String largeBoxId = determineLargeBoxId(locationData);
      String virtualAddress = generateVirtualAddress(locationData.latitude!, locationData.longitude!, largeBoxId);
      // Update _locationData with the latest locationData
      _locationData = locationData;
      if (locationData.latitude != null && locationData.longitude != null) {
        fetchAndPrintAddress(locationData.latitude!, locationData.longitude!);
      }

      setState(() {
        selectedBoxId = virtualAddress;
        _currentLocationMarker = Marker(
          markerId: MarkerId('currentLocation'),
          infoWindow: InfoWindow(title: 'Current Location', snippet: virtualAddress),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        );
        _markers.clear();
        _markers.add(_currentLocationMarker);

        // Consider if you want to move the camera as well
        mapController.animateCamera(CameraUpdate.newLatLng(position));
      });
      print("Updated Virtual Address____________: $virtualAddress");
      print("Updated Virtual Address_____________: $position");
    }
  }

  void fetchAndPrintAddress(double latitude, double longitude) async {
    try {
      Address address = await geoCoder.getAddressFromLatLng(latitude: latitude, longitude: longitude);
      setState(() {
        // gRoad = address.addressDetails.road;
        // gDistrict = address.addressDetails.city;
        // gArea = address.addressDetails.neighbourhood;
        gProvince = address.addressDetails.state;
        gAddress = address.displayName;
        gPlaceId = address.placeId;
        isLoading = false;
      });
      print("Address Details: ${address.displayName}");
     // print("MORE DETAILS_______: ${address.addressDetails.state + '------' + address.placeId.toString() + '------' +'---------'+ address.addressDetails.countryCode}");
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching address: $e");
    }
  }


  String determineLargeBoxId(LocationData locationData) {
    int latIndex = ((locationData.latitude! - latStart) / latStep).floor();
    int lngIndex = ((locationData.longitude! - lngStart) / lngStep).floor();
    return String.fromCharCode('A'.codeUnitAt(0) + latIndex) +
        String.fromCharCode('A'.codeUnitAt(0) + lngIndex);
  }

  String generateVirtualAddress(double latitude, double longitude, String largeBoxId) {
    String latCode = latitudeToCode(latitude);
    String lonCode = longitudeToCode(longitude);
    return "ZM-LSK-LSK-$largeBoxId-$latCode$lonCode";
  }

  String latitudeToCode(double latitude) {
    // Assuming Lusaka's latitude bounds are from -15.7000 to -14.8000
    double minLat = -15.7000;
    double maxLat = -14.8000;
    int range = 1000; // Increased granularity

    // Normalize latitude within Lusaka's bounds
    int normalizedLat = ((latitude - minLat) / (maxLat - minLat) * range).floor();

    // Convert to two letters (AA-ZZ)
    int firstLetter = normalizedLat ~/ 26; // Dividing by 26 for the first letter
    int secondLetter = normalizedLat % 26; // Modulo 26 for the second letter

    return String.fromCharCode('A'.codeUnitAt(0) + firstLetter) +
        String.fromCharCode('A'.codeUnitAt(0) + secondLetter);
  }


  String longitudeToCode(double longitude) {
    // Assuming Lusaka's longitude bounds are from 28.0000 to 29.0000
    double minLong = 28.0000;
    double maxLong = 29.0000;
    int range = 1000; // Increased granularity for Lusaka's area

    // Normalize longitude within Lusaka's bounds
    int normalizedLong = ((longitude - minLong) / (maxLong - minLong) * range).floor();

    // Convert to a letter and two-digit number
    int letterPart = normalizedLong ~/ 100; // Dividing by 100 for the letter
    int numberPart = normalizedLong % 100; // Modulo 100 for the two-digit number

    String letter = String.fromCharCode('A'.codeUnitAt(0) + (letterPart % 26));
    return letter + numberPart.toString().padLeft(2, '0');
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
              polygons: polygons,
              onMapCreated: (controller) => mapController = controller,
              markers: _markers,
              initialCameraPosition: CameraPosition(
                target: LatLng(-15.4167, 28.2833),
                zoom: 12.0,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!isLoading && _locationData != null) {
                print("Sending to AddAddressScreen: Lat: ${_locationData.latitude}, Lon: ${_locationData.longitude}");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddAddressScreen(
                      virtualAddress: selectedBoxId,
                      latitude: _locationData.latitude!,
                      longitude: _locationData.longitude!,
                      address : gAddress,
                      placeId: gPlaceId,
                      province:  gProvince
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  if (isLoading) CircularProgressIndicator(),
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

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
