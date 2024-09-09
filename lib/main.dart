import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Color primaryColor = Color(0xFF1D9944);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: primaryColor,
        ),
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _loginWithPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: 'mina.nassef09@gmail.com',
        password: _passwordController.text.trim(),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SpeakerControl()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message!;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _loginWithPassword,
                    child: Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}

class SpeakerControl extends StatefulWidget {
  @override
  _SpeakerControlState createState() => _SpeakerControlState();
}

class _SpeakerControlState extends State<SpeakerControl> {
  String ipAddress = '41.155.214.76';
  TextEditingController _ipController = TextEditingController();
  double _currentVolume = 50;
  List<Map<String, dynamic>> musicList =
      []; // Changed to dynamic to store duration
  String? selectedMusicID;
  List<int> allSpeakerIDs = [];
  List<int> availableSpeakerIDs = [];
  List<int> selectedSpeakerIDs = [];

  @override
  void initState() {
    super.initState();
    _ipController.text = ipAddress;
    fetchMusicList();
    fetchAllSpeakers();
  }

  Future<void> fetchMusicList() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress:25012/api/getAllMusicsInfo'),
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedMusicList = [];
        for (var dir in data) {
          for (var music in dir['musicInfoArray']) {
            if (music['cpFileName'] != 'LINE') {
              fetchedMusicList.add({
                'cpFileName': music['cpFileName'],
                'serverMusicID': music['serverMusicID'],
                'duration': music['wFileTime'], // Storing duration
              });
            }
          }
        }
        setState(() {
          musicList = fetchedMusicList;
        });
      } else {
        print('Failed to fetch music list: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching music list: $e');
    }
  }

  Future<void> fetchAllSpeakers() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress:25012/api/getAllDevicesInfo'),
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        List<int> fetchedSpeakerIDs = [];
        for (var device in data) {
          if (device['byDevTypeName'] == 'Network play terminal') {
            fetchedSpeakerIDs.add(device['unDevID']);
          }
        }
        setState(() {
          allSpeakerIDs = fetchedSpeakerIDs;
        });
        fetchAvailableSpeakers();
      } else {
        print('Failed to fetch speaker IDs: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching speaker IDs: $e');
    }
  }

  Future<void> fetchAvailableSpeakers() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress:25012/api/getAllDevicesInfo'),
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        List<int> fetchedAvailableSpeakerIDs = [];
        for (var device in data) {
          if (device['byCurStateStr'] != 'Offline') {
            fetchedAvailableSpeakerIDs.add(device['unDevID']);
          }
        }
        setState(() {
          availableSpeakerIDs = fetchedAvailableSpeakerIDs;
        });
      } else {
        print('Failed to fetch speaker details: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching speaker details: $e');
    }
  }

  Future<void> playMusic(String deviceIDArray, String musicID) async {
    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress:25012/api/postPlayMusic'),
        body: {
          'deviceIDArray': deviceIDArray,
          'musicID': musicID,
        },
      );
      if (response.statusCode == 200) {
        print('Music played successfully');
      } else {
        print('Failed to play music: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error playing music: $e');
    }
  }

  Future<void> stopMusic(String deviceIDArray) async {
    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress:25012/api/postStopMusic'),
        body: {
          'deviceIDArray': deviceIDArray,
        },
      );
      if (response.statusCode == 200) {
        print('Music stopped successfully');
      } else {
        print('Failed to stop music: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error stopping music: $e');
    }
  }

  Future<void> setVolume(String deviceIDArray, double volume) async {
    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress:25012/api/postSetvol'),
        body: {
          'deviceIDArray': deviceIDArray,
          'vol': volume.toString(),
        },
      );
      if (response.statusCode == 200) {
        print('Volume set successfully');
      } else {
        print('Failed to set volume: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  Future<void> playAllMusicInSequence() async {
    if (selectedMusicID == null) return; // Ensure a music is selected

    // Find the index of the selected music in the music list
    int startIndex = musicList.indexWhere(
      (music) => music['serverMusicID'] == selectedMusicID,
    );

    if (startIndex == -1) return; // If the music is not found, return early

    // Play all music from the selected one onward
    for (int i = startIndex; i < musicList.length; i++) {
      String musicID = musicList[i]['serverMusicID'];
      int duration = musicList[i]['duration']; // Duration in seconds

      // Update selectedMusicID to the current music ID
      setState(() {
        selectedMusicID = musicID; // This will trigger the UI to update
      });

      // Play the music
      await playMusic(json.encode(selectedSpeakerIDs), musicID);

      // Wait for the duration of the track before moving to the next one
      await Future.delayed(Duration(seconds: duration));

      // Stop the current music before moving to the next one
      await stopMusic(json.encode(selectedSpeakerIDs));
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speaker Control'),
        leading: Padding(
          padding:
              EdgeInsets.only(top: 0.0, bottom: 0.0, left: 8.0, right: 0.0),
          child: Image.asset('assets/Nassera.png'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'IP Address',
                        prefixIcon: Icon(Icons.network_wifi),
                      ),
                      onChanged: (value) {
                        setState(() {
                          ipAddress = value;
                          fetchMusicList();
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed:
                              musicList.isEmpty || selectedSpeakerIDs.isEmpty
                                  ? null
                                  : () {
                                      playAllMusicInSequence();
                                    },
                          child: Text('Play Music'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: selectedSpeakerIDs.isEmpty
                          ? null
                          : () {
                              stopMusic(json.encode(selectedSpeakerIDs));
                            },
                      child: Text('Stop Music'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Volume: ${_currentVolume.toInt()}'),
            Slider(
              value: _currentVolume,
              min: 0,
              max: 100,
              divisions: 100,
              label: _currentVolume.toInt().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentVolume = value;
                });
                setVolume(json.encode(selectedSpeakerIDs), _currentVolume);
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Music',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: musicList.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(musicList[index]['cpFileName']!),
                              onTap: () {
                                setState(() {
                                  selectedMusicID =
                                      musicList[index]['serverMusicID'];
                                });
                              },
                              selected: selectedMusicID ==
                                  musicList[index]['serverMusicID'],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Speakers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: allSpeakerIDs.length,
                          itemBuilder: (context, index) {
                            final speakerID = allSpeakerIDs[index];
                            final isAvailable =
                                availableSpeakerIDs.contains(speakerID);
                            return CheckboxListTile(
                              title: Text('Speaker $speakerID'),
                              value: selectedSpeakerIDs.contains(speakerID),
                              onChanged: isAvailable
                                  ? (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedSpeakerIDs.add(speakerID);
                                        } else {
                                          selectedSpeakerIDs.remove(speakerID);
                                        }
                                      });
                                    }
                                  : null,
                              activeColor: Theme.of(context).primaryColor,
                              enabled: isAvailable,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
