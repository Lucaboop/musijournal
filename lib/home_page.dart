import 'package:cloud_firestore/cloud_firestore.dart';
import 'JournalAlreadyWritten.dart';
import 'journalwriting.dart';
import 'AllPastJournals.dart';
import 'ProfileSettings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// class OpenAIService {
//   final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
//
//   Future<String> sendMessage(String message) async {
//     final response = await http.post(
//       Uri.parse('https://api.openai.com/v1/chat/completions'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $apiKey',
//       },
//       body: jsonEncode({
//         "model": "gpt-4.1-mini",
//         "messages": [
//           {
//             "role": "user",
//             "content": message
//           }
//         ]
//       }),
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//
//       return data['choices'][0]['message']['content'];
//     } else {
//       print(response.body);
//       throw Exception('Failed to get response');
//     }
//   }
// }
//
// final OpenAIService openAIService = OpenAIService();
//
// void askAI() async {
//   try {
//     String reply = await openAIService.sendMessage(
//         "Hello!"
//     );
//
//     print(reply);
//   } catch (e) {
//     print(e);
//   }
// }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. Variables are now INSIDE the state class
  bool userWroteToday = false;
  bool isLoading = true; // This prevents the user from clicking before we know the answer

  @override
  void initState() {
    super.initState();
    // 2. Call the function when the screen loads
    _checkIfUserWroteToday();
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
  //
  Future<QuerySnapshot<Map<String, dynamic>>> retrieveUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    QuerySnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection("journal_entries").get();

    return userDoc;
  }

  // 3. The function is now inside the class and handles errors safely
  Future<void> _checkIfUserWroteToday() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() { isLoading = false; });
        return; // The code stops here!
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        setState(() { isLoading = false; });
        return;
      }

      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      if (!data.containsKey("lastWrittenDate")) {
        setState(() { isLoading = false; });
        return;
      }


      Timestamp? timestamp = data["lastWrittenDate"] as Timestamp?;

      if (timestamp != null) {
        DateTime now = DateTime.now();
        DateTime lastDate = timestamp.toDate();


        if (now.year == lastDate.year && now.month == lastDate.month && now.day == lastDate.day) {
          setState(() {
            userWroteToday = true;
          });
        } else {
        }
      }
    } catch (e) {
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
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
                        Icon(//streak of journaling
                          Icons.local_fire_department_sharp
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 67, top: 9),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => const ProfileSettings(), // The new page widget
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.circle,
                              size: 80,
                            ),
                          ),
                        ),
                        // Padding(
                        //   padding: const EdgeInsets.only(left: 105, top: 20),
                        //   child: CircleAvatar(
                        //     backgroundColor: Colors.brown,
                        //     radius: 30,
                        //   ),
                        // ),
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
                            userWroteToday = false; // THIS IS ONYL FOR TESTING PURPOSES PLEASE REMOVE LATER
                            if(userWroteToday == true)
                            {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const JournalAlreadyWritten()),
                              ).then((_) {
                                _checkIfUserWroteToday();
                              });
                            }
                            else
                            {
                              // User? user = FirebaseAuth.instance.currentUser;
                              // FirebaseFirestore.instance.collection("users").doc(user?.uid).update({
                              //   // "hasWrittenToday": true,
                              //   // "lastWrittenDate": DateTime.now(),
                              // });

                              // setState(() {
                              //   userWroteToday = true;
                              // });
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const journalWriting()),
                              ).then((_) {
                                _checkIfUserWroteToday();
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
                              MaterialPageRoute(builder: (context) => const PastJournals()),
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
                        "Todays Emotion",
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
                        child:  Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bolt,
                                  size: 100,
                                  color: Colors.yellow,
                                ),
                                Text(
                                    "Energetic / Excited",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                    )
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 20, right:20, bottom: 10),
                              child: Text(
                                  "Recommended Songs",
                                style: TextStyle(
                                  color: Colors.black,
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
                                          borderRadius: BorderRadius.circular(10),
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
                                          borderRadius: BorderRadius.circular(10),
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
                    FloatingActionButton(onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const journalWriting()),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                          "Weekly Emotional Trend",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          )
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 20),
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
                                padding: const EdgeInsets.only(left: 15.0, top: 15),
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
                                future: retrieveUserInfo(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  // 2. Check if Firebase threw an error

                                  if (snapshot.hasError) {
                                    return Text("Error: ${snapshot.error}");
                                  }

                                  final data = snapshot.data?.docs;
                                  if(data == null || data.isEmpty)
                                    {
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "No journals found...",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 30,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
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
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: data?.length,
                                      itemBuilder: (context, index)
                                      {
                                        final fields = data?[index].data();

                                        DateTime Date = fields?["timestamp"].toDate();
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                height: fields?["intensity"] * 1.7,
                                                width: 30,
                                                decoration: BoxDecoration(
                                                  color: Moods[fields?["mood"]],
                                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                                ),
                                              ),
                                              Text(
                                                Days[Date.weekday-1],
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