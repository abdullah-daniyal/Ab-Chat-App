import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/api/apis.dart';
import 'package:intl/intl.dart';
import 'package:chat_app/screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({Key? key, required this.user}) : super(key: key);

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  String _currentDate = '';
  bool _hasUserMessaged = false;

  @override
  void initState() {
    super.initState();
    _checkUserMessaged();
    _getCurrentDate();
  }

  void _getCurrentDate() {
    var now = DateTime.now().toUtc().add(Duration(hours: 5)); // Adjust for Pakistan Standard Time (UTC+5)
    var formatter = DateFormat('dd MMM, yyyy');
    _currentDate = formatter.format(now);
  }

  void _checkUserMessaged() async {
    bool hasMessaged = await APIs.hasUserMessaged(widget.user.id);
    setState(() {
      _hasUserMessaged = hasMessaged;
    });
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center, // Centers the Gmail image
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.user.image,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.info_outline, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double imageSize = 50.0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)));
        },
        child: ListTile(
          leading: GestureDetector(
            onTap: _showDialog,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(imageSize / 2),
              child: CachedNetworkImage(
                width: imageSize,
                height: imageSize,
                imageUrl: widget.user.image,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const CircleAvatar(
                  child: Icon(CupertinoIcons.person),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(widget.user.name),
          subtitle: Text(widget.user.about, maxLines: 1),
          trailing: StreamBuilder<int>(
            stream: APIs.getUnreadMessageCountStream(widget.user.id),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data ?? 0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (unreadCount > 0)
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  if (_hasUserMessaged)
                    Text(
                      _currentDate,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}