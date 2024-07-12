import 'dart:io';
import 'dart:developer';
import 'package:chat_app/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class APIs {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;
  static final FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  static late ChatUser me;

  static User get user => auth.currentUser!;

  static Future<void> signOut() async {
    await auth.signOut();
  }

  static Future<bool> userExists() async {
    try {
      var doc = await firestore.collection('users').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      log('Error checking user existence: $e');
      return false;
    }
  }

  static Future<void> getSelfInfo() async {
    try {
      var doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        me = ChatUser.fromJson(doc.data()!);
        await getFirebaseMessagingToken();
        APIs.updateActiveStatus(true);
        log('My Data: ${doc.data()}');
      } else {
        await createUser();
        await getSelfInfo();
      }
    } catch (e) {
      log('Failed to fetch or create user: $e');
    }
  }

  static Future<void> createUser() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final pushToken = await fMessaging.getToken();
    final Map<String, dynamic> userData = {
      'id': user.uid,
      'name': user.displayName ?? "No Name",
      'email': user.email ?? "No Email",
      'about': "Hey, I'm using A Talk",
      'image': user.photoURL ?? "",
      'createdAt': timestamp,
      'isOnline': false,
      'lastActive': timestamp,
      'pushToken': pushToken ?? ''
    };

    try {
      await firestore.collection('users').doc(user.uid).set(userData);
    } catch (e) {
      log('Failed to create user: $e');
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  static Future<void> updateUserInfo() async {
    final pushToken = await fMessaging.getToken();
    try {
      await firestore.collection('users').doc(user.uid).update({
        'name': me.name,
        'about': me.about,
        'pushToken': pushToken ?? me.pushToken
      });
    } catch (e) {
      log('Failed to update user info: $e');
    }
  }

  static Future<void> updateProfilePicture(File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('images/${user.uid}.$ext');
    try {
      final uploadTask =
          await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
      final imageUrl = await ref.getDownloadURL();
      me.image = imageUrl;
      await firestore
          .collection('users')
          .doc(user.uid)
          .update({'image': me.image});
    } catch (e) {
      log('Error uploading profile picture: $e');
    }
  }

  static String getConversationId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    String chatId = getConversationId(APIs.user.uid, user.id);
    return firestore
        .collection('chats/$chatId/messages')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  static Stream<int> getUnreadMessageCountStream(String userId) {
    String chatId = getConversationId(APIs.user.uid, userId);
    return firestore
        .collection('chats/$chatId/messages')
        .where('read', isEqualTo: false)
        .where('toId', isEqualTo: APIs.user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> sendMessage(ChatUser chatUser, String msg) async {
    String chatId = getConversationId(APIs.user.uid, chatUser.id);
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final Map<String, dynamic> message = {
      'toId': chatUser.id,
      'fromId': APIs.user.uid,
      'msg': msg,
      'sent': time,
      'read': false,
      'type': 'text'
    };

    try {
      await firestore.collection('chats/$chatId/messages').add(message);
    } catch (e) {
      log('Failed to send message: $e');
    }
  }

  static void _messageReadListener(String userId) {
    String chatId = getConversationId(APIs.user.uid, userId);
    firestore
        .collection('chats/$chatId/messages')
        .snapshots()
        .listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.modified) {
          var doc = docChange.doc.data();
          if (doc != null &&
              doc['read'] == true &&
              doc['toId'] == APIs.user.uid) {
            getUnreadMessageCountStream(userId);
          }
        }
      }
    });
  }

  static Future<bool> hasUserMessaged(String userId) async {
    String chatId = getConversationId(APIs.user.uid, userId);
    var snapshot = await firestore
        .collection('chats/$chatId/messages')
        .where('fromId', isEqualTo: userId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<void> sendImageMessage(
      ChatUser chatUser, String imageUrl) async {
    String chatId = getConversationId(APIs.user.uid, chatUser.id);
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final Map<String, dynamic> message = {
      'toId': chatUser.id,
      'fromId': APIs.user.uid,
      'msg': imageUrl,
      'sent': time,
      'read': false,
      'type': 'image' // Specify the type as 'image'
    };

    try {
      await firestore.collection('chats/$chatId/messages').add(message);
    } catch (e) {
      log('Failed to send image message: $e');
    }
  }

  static void updateActiveStatus(bool bool) {}

  static getFirebaseMessagingToken() {}
}
