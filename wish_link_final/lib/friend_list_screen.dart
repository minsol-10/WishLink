import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'friend_request_screen.dart';

class FriendListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('친구 목록'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendRequestScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friends')
            .doc(user!.uid)
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final friends = snapshot.data!.docs;
          List<ListTile> friendWidgets = [];
          for (var friend in friends) {
            final friendId = friend.id;
            friendWidgets.add(
              ListTile(
                title: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text('Loading...');
                    }
                    final friendData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final friendName = friendData['nickname'];
                    return Text(friendName);
                  },
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteFriend(user.uid, friendId);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(friendId: friendId),
                    ),
                  );
                },
              ),
            );
          }
          return ListView(
            children: friendWidgets,
          );
        },
      ),
    );
  }

  void _deleteFriend(String userId, String friendId) {
    FirebaseFirestore.instance
        .collection('friends')
        .doc(userId)
        .collection('friends')
        .doc(friendId)
        .delete();
  }
}
