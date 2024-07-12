import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/auth/profile_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/widgets/chat_user_card.dart';
import 'package:chat_app/models/chat_user.dart'; // Import unified ChatUser model

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all users
  List<ChatUser> list = [];

  // for storing search results
  List<ChatUser> searchList = [];
  // for storing search status
  bool _isSearching = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '5683487624-r4rljt7ruu5ti20vbjjo4jjid2r9vp5d.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();
  }

  void _search(String query) {
    final results = list.where((user) {
      final userName = user.name.toLowerCase();
      final userEmail = user.email.toLowerCase();
      final searchLower = query.toLowerCase();
      return userName.contains(searchLower) || userEmail.contains(searchLower);
    }).toList();

    setState(() {
      searchList = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        // if search is on back button is pressed then close search
        // or else simple close current screen on back button click
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: const Icon(CupertinoIcons.home),
            title: _isSearching
                ? TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search...',
                      hintStyle: TextStyle(fontSize: 18, letterSpacing: 0.5),
                    ),
                    onChanged: _search,
                  )
                : const Text('A Talk'),
            actions: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        searchList.clear();
                      }
                    });
                  },
                  icon: Icon(
                    _isSearching
                        ? CupertinoIcons.clear_circled_solid
                        : Icons.search,
                  )),
              IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(user: APIs.me),
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert))
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              onPressed: _logout,
              child: const Icon(Icons.add_comment_rounded),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: APIs.getAllUsers(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('No data available'));
              }

              list = snapshot.data!.docs.map((doc) {
                return ChatUser.fromJson(doc.data() as Map<String, dynamic>);
              }).toList();

              final displayList = _isSearching ? searchList : list;

              return ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (BuildContext context, int index) {
                  return ChatUserCard(user: displayList[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      log('Error during logout: $e');
    }
  }
}
