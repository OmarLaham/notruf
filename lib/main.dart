import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notruf App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Notruf App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _home_counter = 0;
  int _gps_counter = 0;
  //Flutter text to speach
  FlutterTts flutterTts = FlutterTts();
  //geolocation
  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  String number_to_call = "112";
  String home_alarm_btn = "Home Alarm";
  String gps_alarm_btn = "GPS Alarm";
  double longitude;
  double latitude;
  String gps_address = "";

  dynamic clips = {
    "start_automation": {"path": "start_automation.wav", "delay": 18 + 1},
    "id_audio_path": {"path": "id.wav", "delay": 16 + 1},
    "home_audio_path": {"path": "home.wav", "delay": 15 + 1},
    "geo_created_audio_path": {"path": "geo_created.wav", "delay": 20},
    "explain_sirens_path": {"path": "explain_sirens.wav", "delay": 21 + 1},
    "sirens_audio_path": {"path": "ambulance_sirens.wav", "delay": 10 + 1}
  };
  String start_automation = "start_automation.wav";
  String id_audio_path = "id.wav";
  String home_audio_path = "home.wav";
  String geo_created_audio_path = "geo_created.wav";
  String explain_sirens_path = "explain_sirens.wav";
  String sirens_audio_path = "ambulance_sirens.wav";

  //inhale - exhale
  int inhale_exhale_time_max = 3;
  int inhale_exhale_time_tick = 2;
  String inhale_exhale_mode = "Inhale";
  String inhale_exhale_image_path = "inhale.jpg";
  int inhale_exhale_timer = 0;
  String inhale_exhale_scale = "";

  Future init_inhale_exhale_timer() async {
    while (true) {
      await Future.delayed(Duration(seconds: inhale_exhale_time_tick));

      setState(() {
        inhale_exhale_timer++;
        inhale_exhale_scale = inhale_exhale_scale + " .";

        if (inhale_exhale_timer > inhale_exhale_time_max) {
          inhale_exhale_timer = 1;
          inhale_exhale_scale = "";

          if (inhale_exhale_mode == "Inhale") {
            inhale_exhale_mode = "Exhale";
            inhale_exhale_image_path = "exhale.jpg";
          } else {
            inhale_exhale_mode = "Inhale";
            inhale_exhale_image_path = "inhale.jpg";
          }
        }
      });
    }
  }

  Future<void> getHumanAddress() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          forceAndroidLocationManager:
              true); //the more accurate the more u r consuming from the battery. have a look at the table:   https://pub.dev/packages/geolocator
      double longitude = position.longitude;
      double latitude = position.latitude;
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      // this is all you need
      Placemark placeMark = placemarks[0];
      String name = placeMark.name;
      String street = placeMark.street;
      String subLocality = placeMark.subLocality;
      String locality = placeMark.locality;
      String administrativeArea = placeMark.administrativeArea;
      String postalCode = placeMark.postalCode;
      String country = placeMark.country;
      gps_address =
          "${name}, ${street}, ${locality}, ${postalCode} ${administrativeArea}";
    } catch (e) {
      print(e);
    }
  }

  Future play_audio_file_to_microphone(String path) async {
    //TODO
    return null;
  }

  Future<AudioPlayer> play_audio_file_to_speaker(String clip) async {
    AudioCache cache = new AudioCache();
    //At the next line, DO NOT pass the entire reference such as assets/yes.mp3. This will not work.
    //Just pass the file name only.
    await cache.play(clips[clip]["path"]);
    await Future.delayed(Duration(seconds: clips[clip]["duration"]));
  }

  Future automate_call(String emergency_location) async {
    //tell that automation started
    await play_audio_file_to_speaker(id_audio_path);
    if (emergency_location == "home") {
      while (true) {
        //say your id and alergy shock
        await play_audio_file_to_speaker(id_audio_path);
        //say your home address
        await play_audio_file_to_speaker(home_audio_path);
        //explain why sirens
        await play_audio_file_to_speaker(explain_sirens_path);
        //play sierens
        await play_audio_file_to_speaker(sirens_audio_path);
      }
    } else if (emergency_location == "outdoor") {
      //say your id and alergy shock
      await play_audio_file_to_speaker(id_audio_path);
      //get location and compose custom location message
      await getHumanAddress();
      //synthesize voice message from human readable path
      String voice_message = "My current address is " + gps_address;
      await flutterTts.setVoice({"name": "Karen", "locale": "en-US"});
      final app_docs_directory = await getApplicationDocumentsDirectory();
      await flutterTts.synthesizeToFile(
          voice_message,
          Platform.isAndroid
              ? path.join(app_docs_directory.path, "human_readable_address.wav")
              : path.join(
                  app_docs_directory.path, "human_readable_address.caf"));

      //synthesize voice message from geolocation
      voice_message =
          'My geolocation is: longitude $longitude and  latitude $latitude';
      await flutterTts.synthesizeToFile(
          voice_message,
          Platform.isAndroid
              ? path.join(app_docs_directory.path, "geolocation_address.wav")
              : path.join(app_docs_directory.path, "geolocation_address.caf"));

      while (true) {
        //play human readable address
        await play_audio_file_to_speaker(Platform.isAndroid
            ? path.join(app_docs_directory.path, "human_readable_address.wav")
            : path.join(app_docs_directory.path, "human_readable_address.caf"));
        //wait 1 second
        await Future.delayed(Duration(seconds: 1));
        //play geolocation address
        await play_audio_file_to_speaker(Platform.isAndroid
            ? path.join(app_docs_directory.path, "geolocation_address.wav")
            : path.join(app_docs_directory.path, "geolocation_address.caf"));
        //explain why sirens
        await play_audio_file_to_speaker(explain_sirens_path);
        //play sierens
        await play_audio_file_to_speaker(sirens_audio_path);
      }
    }
  }

  Future call_ambulance(String emergency_location) async {
    //FlutterPhoneDirectCaller.callNumber(number_to_call);
    home_alarm_btn = "Automate Call!";
    gps_alarm_btn = "Automate Call!";
  }

  void _incrementHomeCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.

      if ((home_alarm_btn != "Home Alarm") || (gps_alarm_btn != "GPS Alarm")) {
        automate_call("home");
      }

      _home_counter++;
      if (_home_counter >= 3) {
        //play some sound from assets
        call_ambulance("home");
      }
    });
  }

  Future _incrementGPSCounter() async {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.

      if ((home_alarm_btn != "Home Alarm") || (gps_alarm_btn != "GPS Alarm")) {
        automate_call("outdoor");
      }

      _gps_counter++;
      if (_gps_counter >= 3) {
        call_ambulance("outdoor");
      }
    });
  }

  void initState() {
    super.initState();
    init_inhale_exhale_timer();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Watch breath and skin color',
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '$inhale_exhale_mode: $inhale_exhale_timer/$inhale_exhale_time_max',
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            Image.asset('assets/$inhale_exhale_image_path',
                width: 168, height: 168),
            Visibility(
              child: Text(
                'SET SOUND TO ',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              maintainSize: false,
              maintainAnimation: true,
              maintainState: true,
              visible: ((home_alarm_btn != "Home Alarm") ||
                  (gps_alarm_btn != "GPS Alarm")),
            ),
            Visibility(
              child: Text(
                'LOUDEST FOR SIRENS\n',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              maintainSize: false,
              maintainAnimation: true,
              maintainState: true,
              visible: ((home_alarm_btn != "Home Alarm") ||
                  (gps_alarm_btn != "GPS Alarm")),
            ),
            Text(
              'If you are at home press the button 3 times',
            ),
            Text(
              '$_home_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            ElevatedButton(
              onPressed: () {
                _incrementHomeCounter();
              },
              child: Text(home_alarm_btn),
            ),
            Text(
              'If you are NOT at home press the button 3 times',
            ),
            Text(
              '$_gps_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            ElevatedButton(
              onPressed: () {
                _incrementGPSCounter();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
              ),
              child: Text(gps_alarm_btn),
            ),
            Image.asset('assets/ambulance.jpg', width: 128, height: 128),
          ],
        ),
      ),
    );
  }
}
