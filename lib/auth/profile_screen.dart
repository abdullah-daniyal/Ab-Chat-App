import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/models/chat_user.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Uint8List? _imageBytes;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  String? _profileImageUrl;
  bool isCurrentUser = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    isCurrentUser = FirebaseAuth.instance.currentUser!.uid == widget.user.id;
    _nameController.text = widget.user.name;
    _aboutController.text = widget.user.about;
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.user.id).get();
      if (userDoc.exists && userDoc.data() != null) {
        var userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('profileImage')) {
          setState(() {
            _profileImageUrl = userData['profileImage'];
          });
        }
      }
    } catch (e) {
      // Handle errors or show an error message
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() async {
        _imageBytes = Uint8List.fromList(await pickedFile.readAsBytes());
      });
      // Optionally, upload the image to Firebase Storage and update the user's profile image URL
    }
  }

  Future<void> _updateProfile() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.id).update({
        'name': _nameController.text,
        'about': _aboutController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
    } catch (e) {
      // Handle errors or show an error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile Screen'),
          actions: <Widget>[
            if (!isCurrentUser) IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                // Implement navigation to the friend's profile here
              },
            ),
          ],
        ),
        floatingActionButton: isCurrentUser ? FloatingActionButton.extended(
          onPressed: () => FirebaseAuth.instance.signOut().then((_) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
          }),
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Logout'),
          backgroundColor: Colors.red,
        ) : null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: isCurrentUser ? _pickImage : null,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImageUrl != null ? CachedNetworkImageProvider(_profileImageUrl!) : null,
                  child: _profileImageUrl == null ? const Icon(Icons.person, size: 60) : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                readOnly: !isCurrentUser,
              ),
              TextField(
                controller: _aboutController,
                decoration: const InputDecoration(labelText: 'About'),
                readOnly: !isCurrentUser,
              ),
              if (isCurrentUser) ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Update Profile'),
              )
            ],
          ),
        ),
      ),
    );
  }
}