import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SignIn.dart';
class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final FocusNode emailFocusNode = FocusNode();
  FocusNode firstNameFocusNode = FocusNode();
  FocusNode lastnameFocusNode = FocusNode();
  final emailController = TextEditingController(text: FirebaseAuth.instance.currentUser?.email);
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  String? selectedGenre;

  List<String> Genres = [
    "Currently Trending",
    "Classical",
    "Rock and Roll",
    "EDM",
    "Rap",
    "HipHop",
    "Pop",
    "Jazz",
  ];

  Future<bool> checkIfEmailExists(String email) async {
    var snapshot = await FirebaseFirestore.instance.collection("users").where('email', isEqualTo: email).get();
    if(snapshot.docs.isNotEmpty)
      {
        return true;
      }
    return false;
  }
  Future<void> getUserData(String? userId) async {
    DocumentSnapshot user = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    Map<String, dynamic> data = user.data() as Map<String, dynamic>;
    setState(() {
      firstNameController.text = data['first'];
      lastNameController.text = data['last'];
      selectedGenre = data['preferredGenre'];
    });
    print("current email is ${FirebaseAuth.instance.currentUser?.email}");
  }

  Future<bool> verifyOldPassword(String oldPassword) async {
    User? user = FirebaseAuth.instance.currentUser;
    AuthCredential credential = EmailAuthProvider.credential(
      email: user?.email ?? '',
      password: oldPassword,
    );
    try {
      await user?.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseException catch (e) {
      if(e.code == 'wrong-password')
        {
          return false;
        }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    final User? user = FirebaseAuth.instance.currentUser;
    late final String? uid = user?.uid;
    getUserData(uid);
    print(user?.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: const Text (
                      'Profile Settings',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      )
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 130.0),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                )
              ]
            ),
            Icon(
              Icons.circle,
              size: 120,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                      spreadRadius: 1,
                    )
                  ]
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, left: 25, right: 15),
                        child: Text(
                            "First Name",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            )
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left:25.0),
                            child: TextField(
                              focusNode: firstNameFocusNode,
                              controller: firstNameController,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => firstNameFocusNode.requestFocus(),
                          icon: Icon(Icons.edit),
                        )
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, left: 25, right: 15),
                        child: Text(
                            "Last Name",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            )
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left:25.0),
                            child: TextField(
                              focusNode: lastnameFocusNode,
                              controller: lastNameController,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => lastnameFocusNode.requestFocus(),
                          icon: Icon(Icons.edit),
                        )
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, left: 25, right: 15),
                        child: Text(
                          "Email",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                          )
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left:25.0),
                            child: TextField(
                              controller: emailController,
                              focusNode: emailFocusNode,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => emailFocusNode.requestFocus(),
                          icon: Icon(Icons.edit),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, left: 25, right: 15),
                        child: Text(
                          "Password",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          )
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left:25.0),
                            child: TextField(
                              readOnly: true,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: "* * * * * * * * *", // i cant access passwords, so ill do this
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: Text("Enter your old password", style: TextStyle(color: Colors.black, fontSize: 20)),
                                  actions: [
                                    Column(
                                      children: [
                                        TextField(
                                          controller: oldPasswordController,
                                          obscureText: true,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder()
                                          ),
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        Text("Enter your new password", style: TextStyle(color: Colors.black, fontSize: 20)),
                                        TextField(
                                          controller: newPasswordController,
                                          obscureText: true,
                                          decoration: InputDecoration(
                                              border: OutlineInputBorder()
                                          ),
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            bool isOldPassCorrect = await verifyOldPassword(oldPasswordController.text);
                                            if(isOldPassCorrect)
                                            {
                                              if(oldPasswordController.text == newPasswordController.text)
                                              {
                                                toastification.show(
                                                  type: ToastificationType.error,
                                                  context: context,
                                                  title: Text('Old and new passwords are identical'),
                                                  autoCloseDuration: const Duration(seconds: 5),
                                                );
                                              }
                                              else
                                              {
                                                User? user = FirebaseAuth.instance.currentUser;
                                                try {
                                                  await user?.updatePassword(newPasswordController.text);
                                                  toastification.show(
                                                    type: ToastificationType.success,
                                                    context: context,
                                                    title: Text('Password successfully changed.'),
                                                    autoCloseDuration: const Duration(seconds: 5),
                                                  );
                                                } on FirebaseAuthException catch (e) {
                                                  if(e.code == "weak-password")
                                                    {
                                                      toastification.show(
                                                        type: ToastificationType.error,
                                                        context: context,
                                                        title: Text('New password too short, must be 6 characters or more.'),
                                                        autoCloseDuration: const Duration(seconds: 5),
                                                      );
                                                    }
                                                }

                                                Navigator.pop(context);
                                              }
                                            }
                                            else
                                            {
                                              toastification.show(
                                                type: ToastificationType.error,
                                                context: context,
                                                title: Text('Old password incorrect.'),
                                                autoCloseDuration: const Duration(seconds: 5),
                                              );
                                            }
                                          },
                                          child: Text("Enter"),
                                        ),
                                      ],
                                    )
                                  ],
                                );
                              },
                            );
                          },
                          icon: Icon(Icons.edit),
                        )
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, left: 25, right: 15),
                        child: Text(
                          "Preferred Music Genre",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          )
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 25, right: 45),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        value: selectedGenre,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGenre = newValue;
                          });
                        },
                        items: Genres.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 25.0),
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: Colors.black,
                                )
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30.0, bottom: 30, left: 20, right :20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  User? user = FirebaseAuth.instance.currentUser;
                                  FirebaseFirestore.instance.collection("users").doc(
                                      user?.uid).set({
                                    "first": firstNameController.text,
                                    "last": lastNameController.text,
                                    "preferredGenre": selectedGenre,
                                    "email": FirebaseAuth.instance.currentUser?.email,
                                  });
                                  if(user?.email != emailController.text)
                                  {
                                    if(await checkIfEmailExists(emailController.text) == true)
                                    {
                                      toastification.show(
                                        type: ToastificationType.error,
                                        context: context,
                                        title: Text('That email is already in use.'),
                                        autoCloseDuration: const Duration(seconds: 5),
                                      );
                                    }
                                    else
                                    {
                                      await user?.verifyBeforeUpdateEmail(emailController.text);
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text("Verification Email Sent", style: TextStyle(color: Colors.black)),
                                            content: Text("Please sign in again after verifying.", style: TextStyle(color: Colors.black)),
                                            backgroundColor: Colors.white,
                                            actions: [
                                              Center(
                                                child: ElevatedButton.icon(
                                                  onPressed: () async {
                                                    User? user = FirebaseAuth.instance.currentUser;
                                                    await FirebaseAuth.instance.signOut();
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute<void>(
                                                        builder: (context) => const SignIn(), // The new page widget
                                                      )
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    fixedSize: const Size(180, 50),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    side: BorderSide(width:1),
                                                    backgroundColor: Colors.white,
                                                  ),
                                                  icon: const Icon(Icons.logout),
                                                  label: const Text(
                                                    "Sign Out",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    )
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      );
                                    }
                                  } else
                                  {
                                    toastification.show(
                                      type: ToastificationType.success,
                                      context: context,
                                      description: Text('Changes saved.'),
                                      autoCloseDuration: const Duration(seconds: 5),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: const Size(180, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                side: BorderSide(width:1),
                                backgroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.save_alt),
                              label: const Text(
                                "Save All",
                                style: TextStyle(
                                  color: Colors.black,
                                )
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) => const SignIn(), // The new page widget
                                    )
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: const Size(180, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  side: BorderSide(width:1),
                                  backgroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.logout),
                                label: const Text(
                                  "Sign Out",
                                  style: TextStyle(
                                    color: Colors.black,
                                  )
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}
