import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_sms/flutter_sms.dart';

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> cont = [''];
  String text = "Stop Service";
  String number = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getContacts();
  }

  //Get Emergency Contacts
  void getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'contacts';
    cont = prefs.getStringList(key) ?? [];

    print(cont);
  }

//Clear Shared preferences
  void clearShared() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  //Saves Number to Shared Preference
  void _saveNum() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'contacts';
    final value = prefs.getStringList(key) ?? [];
    value.add(number);
    prefs.setStringList(key, value);
    print(value);
    setState(() {
      cont=value;
    });
  }

  //Get Users Location
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  //Send SMS to the given Contacts
  void _sendSMS() async {
    final location = await _determinePosition();
    print(location);
    String message = 'I am in danger, Help me! \n ' + location.toString();
    if (cont.isEmpty) {
      return;
    }
    String _result =
        await sendSMS(message: message, recipients: cont).catchError((onError) {
      print(onError);
    });
    print(_result);

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SOS APP'),
        ),
        body: Column(
          children: [
            //Add Contact to submit message
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      keyboardType:TextInputType.number ,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter a Contact'),
                      onChanged: (text) {
                        number = text;
                      },
                    ),
                  ),
                ),
                MaterialButton(
                    child: Text("Add Contact"),
                    color: Colors.blueAccent,
                    height: 60,
                    onPressed: _saveNum)
              ],
            ),

            //Show the Give Contacts
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Contacts",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex:1,
                child: ListView.builder(
                    itemCount: cont.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.all(8.0),

                        child: Text(cont[index],textAlign: TextAlign.center,),
                      );
                    })),
            Expanded(
              flex: 1,
              child: RawMaterialButton(
                constraints: BoxConstraints(minHeight: 120, minWidth: 120),
                onPressed: _sendSMS,
                elevation: 8.0,
                fillColor: Colors.redAccent,
                child: Text(
                  "SOS",
                  style: TextStyle(color: Colors.white, fontSize: 32),
                ),
                padding: EdgeInsets.all(15.0),
                shape: CircleBorder(),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
