import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  // For json encoding/decoding

class AddAddressScreen extends StatefulWidget {
  final String virtualAddress;
  final double latitude;
  final double longitude;

  AddAddressScreen({
    Key? key,
    required this.virtualAddress,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  late String _selectedType = 'Residential';
  String _street = '';
  String _address = '';
  String _province = '';
  String _district = '';
  String _ward = '';
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
    String address = _address;
    String province = _province;
    String district = _district;
    String ward = _ward;
    String type = _selectedType;  // Assuming _selectedType holds the type value

    // Form data as per your API structure
    var body = jsonEncode({
      "street": street,
      "address": address,
      "province": province,
      "district": district,
      "ward": ward,
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
              // Plot Number or Address
              TextField(
                decoration: InputDecoration(hintText: "Plot Number or Address"),
                onChanged: (value) {
                  _address = value;
                },
              ),
              // Street
              TextField(
                decoration: InputDecoration(hintText: "Street"),
                onChanged: (value) {
                  _street = value;
                },
              ),
              // Ward
              TextField(
                decoration: InputDecoration(hintText: "Ward"),
                onChanged: (value) {
                  _ward = value;
                },
              ),
              // District
              TextField(
                decoration: InputDecoration(hintText: "District"),
                onChanged: (value) {
                  _district = value;
                },
              ),
              // Province
              TextField(
                decoration: InputDecoration(hintText: "Province"),
                onChanged: (value) {
                  _province = value;
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
