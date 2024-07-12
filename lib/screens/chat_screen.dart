import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/auth/profile_screen.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showEmoji = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    String chatId = APIs.getConversationId(APIs.user.uid, widget.user.id);
    FirebaseFirestore.instance
        .collection('chats/$chatId/messages')
        .where('read', isEqualTo: false)
        .where('toId', isEqualTo: APIs.user.uid)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'read': true});
      }
    });
  }

  String _formatTimestamp(String timestamp) {
    final DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final DateFormat formatter = DateFormat('h:mm a');
    return formatter.format(dateTime);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await _uploadImageWeb(bytes);
      } else {
        File imageFile = File(image.path);
        await _uploadImageMobile(imageFile);
      }
    }
  }

  Future<void> _uploadImageWeb(Uint8List bytes) async {
    String chatId = APIs.getConversationId(APIs.user.uid, widget.user.id);
    String imageName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child('images/$chatId/$imageName')
          .putData(bytes, SettableMetadata(contentType: 'image/png'));

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Image URL: $downloadUrl');

      await APIs.sendImageMessage(widget.user, downloadUrl);
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
  }

  Future<void> _uploadImageMobile(File imageFile) async {
    String chatId = APIs.getConversationId(APIs.user.uid, widget.user.id);
    String imageName = path.basename(imageFile.path);
    try {
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child('images/$chatId/$imageName')
          .putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Image URL: $downloadUrl');

      await APIs.sendImageMessage(widget.user, downloadUrl);
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mq = MediaQuery.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          flexibleSpace: _appBar(),
        ),
        body: GestureDetector(
          onTap: () {
            if (_showEmoji) {
              setState(() {
                _showEmoji = false;
              });
            }
          },
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(
                          'chats/${APIs.getConversationId(APIs.user.uid, widget.user.id)}/messages')
                      .orderBy('sent', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      reverse: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        bool isSentByMe = doc['fromId'] == APIs.user.uid;
                        return _buildMessage(
                            doc['msg'], doc['sent'], isSentByMe, doc['type']);
                      },
                    );
                  },
                ),
              ),
              _chatInput(mq),
              if (_showEmoji)
                SizedBox(
                  height: mq.size.height * .35,
                  child: EmojiPicker(
                    textEditingController: _textController,
                    config: Config(
                      height: 256,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    double imageSize = 40.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(imageSize / 2),
          child: CachedNetworkImage(
            width: imageSize,
            height: imageSize,
            imageUrl: widget.user.image,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(CupertinoIcons.person, color: Colors.white),
            ),
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.user.name,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500)),
            const Text("Last seen not available",
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.video_camera_front, color: Colors.white),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.call, color: Colors.white),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfileScreen(user: widget.user)),
            );
          },
        ),
      ],
    );
  }

  Widget _chatInput(MediaQueryData mq) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.padding.bottom, horizontal: mq.padding.left),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      icon:
                          const Icon(Icons.emoji_emotions, color: Colors.white),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onTap: () {
                          if (_showEmoji) {
                            setState(() {
                              _showEmoji = false;
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: mq.size.height * 0.06,
            width: mq.size.height * 0.06,
            child: MaterialButton(
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  APIs.sendMessage(widget.user, _textController.text);
                  _textController.clear();
                }
              },
              shape: const CircleBorder(),
              color: Colors.blue,
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessage(
      String msg, String timestamp, bool isSentByMe, String type) {
    if (type == 'image') {
      return Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              decoration: BoxDecoration(
                color: isSentByMe ? Colors.blue : Colors.grey[850],
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: msg,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.cover,
                  width: 200,
                  height: 200,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 20, left: 20),
              child: Text(
                _formatTimestamp(timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } else {
      return Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isSentByMe ? Colors.blue : Colors.grey[850],
                borderRadius: isSentByMe
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(15))
                    : const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15)),
              ),
              child: Text(msg,
                  style: TextStyle(
                      color: isSentByMe ? Colors.white : Colors.white70)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 20, left: 20),
              child: Text(
                _formatTimestamp(timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }
  }
}
