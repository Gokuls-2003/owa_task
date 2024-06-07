import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markrers = {};
  List<dynamic> _users = [];
  String _searchQuery = " ";
  bool _hasInternet = true;
  bool _loading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkInternetConnection();
    if (_hasInternet) {
      fetchUsers();
    }
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http
          .get(Uri.parse("https://jsonplaceholder.typicode.com/users"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = data;
          _loading = false;
          _markrers = data.map<Marker>((user) {
            final lat = double.parse(user['address']['geo']['lat']);
            final lng = double.parse(user['address']['geo']['lng']);
            return Marker(
                markerId: MarkerId(user["id"].toString()),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(title: user['name']));
          }).toSet();
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _hasInternet = false;
      });
    }
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
      } else {
        setState(() {
          _hasInternet = false;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
      });
    }
  }

  void _updatecameraPosition() {
    final user = _users.firstWhere(
      (user) => user['name'].toString().toLowerCase().contains(_searchQuery),
      orElse: () => null,
    );
    if (user != null) {
      final lat = double.parse(user['address']['geo']['lat']);
      final lng = double.parse(user['address']['geo']['lng']);
      mapController.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
              hintText: "Search",
              border: InputBorder.none,
              suffixIcon: Icon(Icons.search)),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : !_hasInternet
              ? Center(
                  child: Text("Check your internet connection"),
                )
              : GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: LatLng(29.0588, 76.0856), zoom: 2),
                  markers: _markrers,
                  onMapCreated: (controller) {
                    mapController = controller;
                  }),
    );
  }
}
