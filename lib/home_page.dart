import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'CreateSpotifyToken.dart';
import 'JournalAlreadyWritten.dart';
import 'journalwriting.dart';
import 'AllPastJournals.dart';
import 'ProfileSettings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool userWroteToday = false;
  bool isLoading = true;
  late Future<List<Map<String, dynamic>>> journalsFuture;
  int _weekOffset = 0;

  Map<String, DateTime> _getWeekRange(int offset) {
    DateTime now = DateTime.now();

    int daysFromMonday = now.weekday - 1;
    DateTime currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromMonday));
    DateTime targetMonday = currentMonday.add(Duration(days: offset * 7));
    DateTime targetSunday = targetMonday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return {
      'start': targetMonday,
      'end': targetSunday,
    };
  }

  Future<String?> askChatGPT(String prompt) async {
    try {
      // 1. Create the message you want to send
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            prompt,
          ),
        ],
        role: OpenAIChatMessageRole.system,
      );

      User? user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users') // Replace with your collection name
          .doc(user?.uid)     // Pass the specific Document ID
          .get();

      String prefSongGenre = docSnapshot.get("preferredGenre");

      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "My preferred music genre is $prefSongGenre."
          ),
        ],
        role: OpenAIChatMessageRole.user,
      );

      // 2. Send the request to the API
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini", // fast and cheap model
        messages: [systemMessage, userMessage],
      );

      // 3. Print or use the response!
      String? response = chatCompletion.choices.first.message.content?.first.text;
      // debugPrint(response);
      //
      // AIOverview = response;
      return(response);
    } catch (e) {
      print("Something went wrong: $e");
    }
    return null;
  }

  late Future<List<dynamic>> recommendedSongs;

  void getAI() async {
    String? AIresponse = await askChatGPT("Given the user's preferred music genre, find 3 songs with varying emotion from that genre. Only state the name of the songs, with a forwards slash to separate each song name.");
    recommendedSongs = findRecommendedSongs(AIresponse!);
  }

  Future<List<dynamic>> findRecommendedSongs(String AIResponse) async {
    final authService = SpotifyAuthService(); // Gets the Singleton
    String? token = await authService.getValidToken(); // Fetches a new token

    List<String> songNames = AIResponse.split(' / ');

    // 1. Create a list to hold the songs we find
    List<dynamic> allFoundSongs = [];

    for (String currentSong in songNames) {
      final url = Uri.https('api.spotify.com', '/v1/search', {
        'q': currentSong,
        'type': 'track',
        'limit': '1',
      });

      try {
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          dynamic song = data['tracks']['items'];

          List<dynamic> resolvedList = await song;
          if (resolvedList.isEmpty) {
            print('No tracks found for "$currentSong".');
            continue; // Skip to the next song instead of returning
          }

          print('Top result for "$currentSong":');
          String songName = song[0]['name']; // Ensure you are grabbing the first item in the array
          String artistName = song[0]['artists'][0]['name'];
          String spotifyId = song[0]['id'];

          print('- $songName by $artistName (ID: $spotifyId)');

          // Add the found song to our list
          allFoundSongs.add(song);

        } else {
          print('Failed to search: ${response.statusCode}');
          print('Error message: ${response.body}');
        }
      } catch (e) {
        print('Network error occurred: $e');
      }
    }

    // 2. Return the completed list at the very end of the function
    return allFoundSongs;

  }
    Future<List<Map<String, dynamic>>> retrieveUserInfo() async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final weekRange = _getWeekRange(_weekOffset);
      DateTime startOfWeek = weekRange['start']!;
      DateTime endOfWeek = weekRange['end']!;

      QuerySnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .collection("journal_entries")
          .where(
          "timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where(
          "timestamp", isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .orderBy("timestamp", descending: true)
          .get();

      List<Map<String, dynamic>> answer = [];

      for (var doc in userDoc.docs) {
        final Map<String, dynamic> data = doc.data();
        if (data["timestamp"] == null) continue;

        answer.add(data);
      }

      return answer.reversed.toList();
    }

    void _refreshJournals() {
      setState(() {
        journalsFuture = retrieveUserInfo();
      });
    }

    Future<void> _checkIfUserWroteToday() async {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          setState(() {
            isLoading = false;
          });
          return;
        }

        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
            'users').doc(user.uid).get();

        if (!userDoc.exists) {
          setState(() {
            isLoading = false;
          });
          return;
        }

        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        if (!data.containsKey("lastWrittenDate")) {
          setState(() {
            isLoading = false;
          });
          return;
        }


        Timestamp? timestamp = data["lastWrittenDate"] as Timestamp?;

        if (timestamp != null) {
          DateTime now = DateTime.now();
          DateTime lastDate = timestamp.toDate();


          if (now.year == lastDate.year && now.month == lastDate.month &&
              now.day == lastDate.day) {
            setState(() {
              userWroteToday = true;
            });
          } else {}
        }
      } catch (e) {} finally {
        setState(() {
          isLoading = false;
        });
      }
    }

    @override
    void initState() {
      super.initState();
      journalsFuture = retrieveUserInfo();
      _checkIfUserWroteToday();
      getAI();
    }

    final List<Color> Moods = [
      Colors.yellow,
      Colors.blue,
      Colors.red,
      Colors.grey,
    ];

    final List<String> Days = [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun",
    ];



    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 4,
          backgroundColor: Colors.black,
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.lightBlueAccent, Colors.blue],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: const Text (
                                'Good morning',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )
                            ),
                          ),
                          Icon( //streak of journaling
                              Icons.local_fire_department_sharp
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 67, top: 9),
                            child: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (
                                        context) => const ProfileSettings(), // The new page widget
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.circle,
                                size: 80,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 20),
                        child: Text(
                            'What would you like to do today?',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            )
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _checkIfUserWroteToday();
                              userWroteToday =
                              false; // THIS IS ONYL FOR TESTING PURPOSES PLEASE REMOVE LATER
                              if (userWroteToday == true) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (
                                      context) => const JournalAlreadyWritten()),
                                ).then((_) {
                                  _checkIfUserWroteToday();
                                  _refreshJournals();
                                });
                              }
                              else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (
                                      context) => const journalWriting()),
                                ).then((_) {
                                  _checkIfUserWroteToday();
                                  _refreshJournals();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              fixedSize: const Size(180, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text(
                                "New Journal",
                                style: TextStyle(
                                  color: Colors.black,
                                )
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const PastJournals()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              fixedSize: const Size(180, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.search),
                            label: const Text(
                                "Past Journals",
                                style: TextStyle(
                                  color: Colors.black,
                                )
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                            "Todays Recommendations",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            )
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, right: 20),
                        child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20, right: 20, bottom: 10, top: 10),
                                  child: Text(
                                    "Recommended Songs",
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius
                                                  .circular(10),
                                              color: Colors.grey,
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 5,
                                              )
                                          ),
                                          child: Icon(
                                            Icons.music_note,
                                            size: 100,
                                          ),
                                        ),
                                        Text(
                                            "Song #1"
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius
                                                  .circular(10),
                                              color: Colors.grey,
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 5,
                                              )
                                          ),
                                          child: Icon(
                                            Icons.music_note,
                                            size: 100,
                                          ),
                                        ),
                                        Text(
                                            "Song #2"
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius
                                                  .circular(10),
                                              color: Colors.grey,
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 5,
                                              )
                                          ),
                                          child: Icon(
                                            Icons.music_note,
                                            size: 100,
                                          ),
                                        ),
                                        Text(
                                            "Song #3"
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                        ),
                      ),
                      FutureBuilder<List<dynamic>>(
                        future: recommendedSongs,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          final List<dynamic> mySongs = snapshot.data ?? [];

                          return ListView.builder(
                            itemCount: mySongs.length,
                            itemBuilder: (context, index) {
                              return Text(mySongs[index]);
                            },
                          );
                        }
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.arrow_back_ios, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _weekOffset--;
                                });
                                _refreshJournals();
                              },
                            ),

                            Text(
                              _weekOffset == 0
                                  ? "This Week's Trend"
                                  : _weekOffset == -1
                                  ? "Last Week's Trend"
                                  : "Week of ${_getWeekRange(
                                  _weekOffset)['start']!.month}/${_getWeekRange(
                                  _weekOffset)['start']!.day}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: _weekOffset >= 0
                                    ? Colors.white38
                                    : Colors.white,
                              ),
                              onPressed: _weekOffset >= 0 ? null : () {
                                setState(() {
                                  _weekOffset++;
                                });
                                _refreshJournals();
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 20.0, right: 20, bottom: 20),
                        child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 15.0, top: 15),
                                    child: Text(
                                      "Emotional Intensity:",
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: FutureBuilder(
                                        future: journalsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child: CircularProgressIndicator());
                                          }

                                          // 2. Check if Firebase threw an error

                                          if (snapshot.hasError) {
                                            return Text(
                                                "Error: ${snapshot.error}");
                                          }

                                          final data = snapshot.data;
                                          if (data == null || data.isEmpty) {
                                            return Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      8.0),
                                                  child: Text(
                                                    "No journals this week...",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 30,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      8.0),
                                                  child: Text(
                                                    "Write your first?",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return SizedBox(
                                            height: 220,
                                            width: double.infinity,
                                            child: ListView.builder(
                                                scrollDirection: Axis
                                                    .horizontal,
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: data.length,
                                                itemBuilder: (context, index) {
                                                  final fields = data[index];

                                                  DateTime Date = fields["timestamp"]
                                                      .toDate();
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .all(8.0),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment
                                                          .end,
                                                      children: [
                                                        Container(
                                                          height: fields["intensity"] *
                                                              1.7,
                                                          width: 30,
                                                          decoration: BoxDecoration(
                                                            color: Moods[fields["mood"]],
                                                            borderRadius: BorderRadius
                                                                .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                    10),
                                                                topRight: Radius
                                                                    .circular(
                                                                    10)),
                                                          ),
                                                        ),
                                                        Text(
                                                          Days[Date.weekday -
                                                              1],
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                            ),
                                          );
                                        }
                                    )
                                ),
                              ],
                            )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }