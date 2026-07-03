import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CreateSpotifyToken.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_openai/dart_openai.dart';

class journalWriting extends StatefulWidget {
  const journalWriting({super.key});

  @override
  State<journalWriting> createState() => _journalWritingState();
}
class _journalWritingState extends State<journalWriting> {
  Future<List<dynamic>>? _searchResultsFuture;
  String? _selectedSongId;
  String? songName;

  final List<IconData> items = [
    Icons.sentiment_very_satisfied,
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_very_dissatisfied_outlined,
    Icons.sentiment_neutral,
  ];

  final List<String> dropDownValueList = [
    'Happy',
    'Sad',
    'Angry',
    'Neutral',
  ];

  String dropDownValue = '';
  int? selectedIndex;
  final journalController = TextEditingController();
  final songController = TextEditingController();
  String? token;
  String? AIOverview;

  Future<void> getToken()
  async {
    final authService = SpotifyAuthService(); // Gets the Singleton
    token = await authService.getValidToken(); // Fetches a new token
  }
  @override
  void initState() {
    // TODO: implement initState
    getToken();
    super.initState();
  }
  void searchSong(String controller)
  {
    if(controller.isEmpty)
      {
        setState(() {
          _selectedSongId = null;
          _searchResultsFuture = null;
        });
      }
    else
      {
        setState(() {
          _selectedSongId = null;
          _searchResultsFuture =searchSpotifyTrack(controller, token!);
        });
      }
  }

  Future<List<dynamic>> searchSpotifyTrack(String query, String accessToken) async {
    // 1. Construct the URL safely
    // Uri.https automatically handles URL encoding (e.g., turning spaces into %20)
    List<dynamic> songs = [];
    final url = Uri.https('api.spotify.com', '/v1/search', {
      'q': query,
      'type': 'track', // You can add 'artist', 'album', etc., separated by commas
      'limit': '10',   // Limit the results to 10 items
    });

    try {
      // 2. Make the GET request
      final response = await http.get(
        url,
        headers: {
          // The Bearer token is strictly required by Spotify
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      // 3. Handle the Response
      if (response.statusCode == 200) {
        // Success! Parse the JSON string into a Dart Map
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Drill down into the JSON to get the list of tracks
        songs = data['tracks']['items'];

        List<dynamic> resolvedList = await songs;
        if(resolvedList.isEmpty) {
          print('No tracks found for "$query".');
          return songs;
        }

        // Loop through the results and extract what you need
        print('Top results for "$query":');
        for (var track in await songs) {
          String songName = track['name'];
          String artistName = track['artists'][0]['name'];
          String spotifyId = track['id'];

          print('- $songName by $artistName (ID: $spotifyId)');
        }

      } else {
        // Handle API errors (e.g., 401 Unauthorized if the token expired)
        print('Failed to search: ${response.statusCode}');
        print('Error message: ${response.body}');
      }
    } catch (e) {
      // Handle network errors (e.g., no internet connection)
      print('Network error occurred: $e');
    }
    return songs;
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


      int newIndex = selectedIndex!;
      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "${journalController.text}. The name of the song I chose was $songName. The main emotion I felt was ${dropDownValueList[newIndex]}"
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(253, 247, 254, 1),
      appBar: AppBar(
        toolbarHeight: 4,
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.bottomRight,
            colors: [Colors.lightBlueAccent, Colors.blue],
          ),
        ),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Positioned(
                left: 355,
                top: 14,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom:20, right: 50, left: 20),
                    child: const Text('How was your day today?',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      )
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: TextField(
                      controller: journalController,
                      maxLines: 15,
                      decoration: InputDecoration(
                        // contentPadding: EdgeInsets.symmetric(
                        //   vertical: 100,
                        //   horizontal: 1,
                        // ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        hintText: "Describe your day...",
                      ),
                      style: TextStyle(
                        color: Colors.black,
                      )
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: const Text('Choose a song',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: TextField(
                            onChanged: (value) {
                              searchSong(value);
                            },
                            controller: songController,
                            maxLines: 1,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(
                              //   vertical: 100,
                              //   horizontal: 1,
                              // ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                              hintText: "Search a song...",
                            ),
                            style: TextStyle(
                              color: Colors.black,
                            )
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(9.0),
                        child: Icon(
                          Icons.search,
                        ),
                      )
                      // IconButton(
                      //   icon: Icon(Icons.search),
                      //   onPressed: () {
                      //     if(songController.text != "")
                      //     {
                      //       setState(() {
                      //         // Overwrite the old future with the brand new network request
                      //         _selectedSongId = null;
                      //         _searchResultsFuture =searchSpotifyTrack(songController.text, token!);
                      //       });
                      //     }
                      //     else
                      //     {
                      //       toastification.show(
                      //         type: ToastificationType.error,
                      //         context: context,
                      //         title: Text("Please write a song name in the search box."),
                      //         autoCloseDuration: const Duration(seconds: 5),
                      //       );
                      //     }
                      //   },
                      // ),
                    ],
                  ),
                  FutureBuilder<List<dynamic>>(
                    // 1. The Future: We give it the search function we want it to run
                    future: _searchResultsFuture,

                    // 2. The Builder: What to draw on the screen
                    builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                      if(_searchResultsFuture == null)
                        {
                          return const Text("No songs found.");
                        }
                      // State 1: We are still waiting for Spotify to reply
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      // State 2: Spotify replied, but there was a network error
                      if (snapshot.hasError) {
                        return Text('Error searching: ${snapshot.error}');
                      }

                      // State 3: Spotify replied with our data! Let's build a list.
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        List<dynamic> tracks = snapshot.data!;

                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            // 1. WHAT IS CURRENTLY SELECTED?
                            // We point it to our variable.
                            initialValue: _selectedSongId,

                            // 2. THE DEFAULT TEXT
                            // What to show when _selectedSongId is null
                            hint: const Text("Tap to choose a song"),

                            // Prevents the dropdown text from overflowing the screen
                            isExpanded: true,
                            isDense: false,
                            // 3. THE LIST OF OPTIONS
                            // We map over the Spotify tracks and build a menu item for each one
                            items: tracks.map<DropdownMenuItem<String>>((track) {
                              String imageUrl = '';
                              var images = track['album']['images'];
                              if (images != null && images.isNotEmpty) {
                                imageUrl = images.last['url']; // Grabs the thumbnail-sized image
                              }

                              return DropdownMenuItem<String>(
                                value: track['id'],

                                // 2. Swap the Text for a Row!
                                child: Row(
                                  children: [

                                    // 3. The Album Art (or a fallback icon)
                                    if (imageUrl.isNotEmpty)
                                      Image.network(
                                        imageUrl,
                                        width: 40,   // Lock the size so the menu looks neat
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Icon(Icons.music_note),
                                      ),

                                    const SizedBox(width: 12), // Adds a nice gap between image and text

                                    // 4. The Song Name
                                    // We wrap the text in an 'Expanded' widget.
                                    // If a song title is crazy long, this forces it to add "..."
                                    // instead of crashing your screen!
                                    Expanded(
                                      child: Text(
                                        '${track['name']} by ${track['artists'][0]['name']}',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            // 4. WHEN THE USER CLICKS AN OPTION
                            onChanged: (String? newlySelectedId) {
                              final selectedTrack = tracks.firstWhere((track) => track['id'] == newlySelectedId);

                              // 2. Use setState to update your variables
                              setState(() {
                                _selectedSongId = newlySelectedId;
                                songName = selectedTrack['name']; // Save the name into your existing variable!
                              });
                              // Boom! You have successfully stored their choice!
                              print("Awesome! You stored Song ID: $_selectedSongId");
                            },
                          ),
                        );
                      }

                      // State 4: Spotify replied, but the search returned 0 results
                      return const Text('No songs found.');
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Text(
                        style: TextStyle(
                          fontSize: 20,
                        ),
                        "Today's Suggestions:",
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey,
                              border: Border.all(
                                color: Colors.black,
                                width: 5,
                              ),
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: 100,
                            ),
                          ),
                          Text("Song #1"),
                        ],
                      ),
                      Column(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey,
                              border: Border.all(
                                color: Colors.black,
                                width: 5,
                              ),
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: 100,
                            ),
                          ),
                          Text("Song #2"),
                        ],
                      ),
                      Column(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey,
                              border: Border.all(
                                color: Colors.black,
                                width: 5,
                              ),
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: 100,
                            ),
                          ),
                          Text("Song #3"),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: const Text('Choose an emotion',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  DropdownButton<int>(
                    value: selectedIndex,
                    hint: const Text("Select an emotion"),
                    items: items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final iconData = entry.value;
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Row(
                          children: [
                            Icon(iconData),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                dropDownValueList[index],
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (int? newIndex) {
                      setState(() {
                        selectedIndex = newIndex;
                        if (newIndex != null) {
                          dropDownValue = dropDownValueList[newIndex];
                        }
                      });
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 40,
                        width: 500,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),

                          onPressed: () async {

                            if(journalController.text.isNotEmpty == true && _selectedSongId?.isNotEmpty == true && selectedIndex != null)
                              {
                                AIOverview = await askChatGPT("You are to shortly analyze this person's journal of they day they had, and you are to analyze what feelings and emotions this person went through. You will then analyze the lyrics of the song provided and give an analysis on how those lyrics connect to the day that the person had. If the song has no lyrics, base your analysis off of other characterizing criteria, like tempo or genre. Finally, give advice to the person based on what they talked about in their journal. Keep it concise and specific by choosing words with specific meaning that reflects the author's day. Keep your summary under a paragraph. Word it as if you are talking to the person directly by using second person pronouns, with an analytical and less casual tone.");
                                String? intensity = await askChatGPT("You are to analyze this person's journal of the day they had and the song they chose to go with it. Then, give a score from 1 to 100 about how intense the emotion they picked was that day. YOU MAY ONLY RESPOND WITH A SINGLE NUMBER, NOTHING ELSE.");
                                print(intensity);
                                User? user = FirebaseAuth.instance.currentUser;

                                FirebaseFirestore.instance.collection("users").doc(user?.uid).update({
                                  "lastWrittenDate": DateTime.now(),
                                });

                                FirebaseFirestore.instance.collection("users").doc(user?.uid).collection("journal_entries").add({
                                  "content": journalController.text,
                                  "song": _selectedSongId,
                                  "mood": selectedIndex!,
                                  "timestamp": FieldValue.serverTimestamp(),
                                  "AIOverview": AIOverview,
                                  "intensity": int.parse(intensity!),
                                });

                                if (!context.mounted) return;

                                Navigator.pop(context);
                              }
                            else
                              {
                                toastification.show(
                                  type: ToastificationType.error,
                                  context: context,
                                  title: Text('Not all fields have been filled out.'),
                                  autoCloseDuration: const Duration(seconds: 5),
                                );
                              }
                          },
                          child: Text("Finish"),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height:30,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}