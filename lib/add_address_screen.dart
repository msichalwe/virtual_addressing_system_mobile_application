import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  // For json encoding/decoding

class AddAddressScreen extends StatefulWidget {
  final String virtualAddress;
  final double latitude;
  final double longitude;
  final String address;
  final String province;
  final int placeId;


  AddAddressScreen({
    Key? key,
    required this.virtualAddress,
    required this.latitude,
    required this.longitude, required this.province, required this.placeId, required this.address
  }) : super(key: key);

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  late String _selectedType = 'Residential';
  String _street = '';
  String _area = '';
  String _province = '';
  String _district = '';
  bool _isLoading = false; // For loading indicator
  final List<String> _typeOptions = [
    'Industrial',
    'Residential',
    'Institutional',
    'Agricultural',
    'Government',
    'School',
    'Church',
    'Medical Facility',
    'Commerical',
    'Bare',
    'Other',
  ];



  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });
    // Example form data variables (replace these with your actual state variables)
    String street = _street;
    String area = _area;
    String province = _province;
    String district = _district;
    int placeId = widget.placeId;
    String address = widget.address;
    String type = _selectedType;  // Assuming _selectedType holds the type value

    // Form data as per your API structure
    var body = jsonEncode({
      "street": street,
      "area": area,
      "province": province,
      "district": district,
      "address" : address,
      "placeId" : placeId,
      "type": type,
      "virtualAddress": {
        "name": widget.virtualAddress,
        "lat": widget.latitude.toString(),
        "lng": widget.longitude.toString(),
      }
    });

    var url = Uri.parse('https://virtual-addressing.vercel.app/api/property');

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Virtual address added successfully.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        // Handle error response
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ERROR'),
            content: const Text('Somthing went wrong'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        print("Failed to add property: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle network error
      print("Error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Virtual Address'),
      ),
      body:_isLoading ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              // Virtual Address (Disabled)
              TextField(
                enabled: false,
                controller: TextEditingController(text: widget.virtualAddress),
                decoration: InputDecoration(labelText: "Virtual Address"),
              ),
              // Latitude (Disabled)
              TextField(
                enabled: false,
                controller: TextEditingController(text: "${widget.latitude}"),
                decoration: InputDecoration(labelText: "Latitude"),
              ),
              // Longitude (Disabled)
              TextField(
                enabled: false,
                controller: TextEditingController(text: "${widget.longitude}"),
                decoration: InputDecoration(labelText: "Longitude"),
              ),
              TextField(
                enabled: false,
                controller: TextEditingController(text: "${widget.address}"),
                decoration: InputDecoration(labelText: "Generated Address"),
              ),
              TextField(
                enabled: false,
                controller: TextEditingController(text: "${widget.placeId}"),
                decoration: InputDecoration(labelText: "Generated PlaceId"),
              ),
              TextField(
                decoration: InputDecoration(hintText: "Ward"),
                controller: TextEditingController(text: "${widget.province}"),
                onChanged: (value) {
                  _province = value;
                },
              ),
              // Plot Number or Address
              TextField(
                decoration: InputDecoration(hintText: "Area"),
                onChanged: (value) {
                  _area = value;
                },
              ),
              // Street
              TextField(
                decoration: InputDecoration(hintText: "Street"),
                onChanged: (value) {
                  _street = value;
                },
              ),
              // District
              TextField(
                decoration: InputDecoration(hintText: "District"),
                onChanged: (value) {
                  _district = value;
                },
              ),
              // Type
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Type",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                  items:
                      _typeOptions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 30),
                child:   ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Add Virtual Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
