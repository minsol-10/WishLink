import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestScreen extends StatefulWidget {
  @override
  _FriendRequestScreenState createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _respondToRequest(
      String requestId, String senderId, bool accept) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자가 로그인하지 않았습니다.')),
      );
      return;
    }

    try {
      if (accept) {
        await _firestore
            .collection('friends')
            .doc(user!.uid)
            .collection('friends')
            .doc(senderId)
            .set({});

        await _firestore
            .collection('friends')
            .doc(senderId)
            .collection('friends')
            .doc(user!.uid)
            .set({});
      }

      await _firestore.collection('friend_requests').doc(requestId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? '친구 신청을 수락했습니다.' : '친구 신청을 거절했습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('받은 친구 신청')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('friend_requests')
            .where('receiverId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('친구 신청이 없습니다.'));
          }

          final requests = snapshot.data!.docs;
          List<ListTile> requestWidgets = [];
          for (var request in requests) {
            final requestId = request.id;
            final senderId = request['senderId'];

            requestWidgets.add(
              ListTile(
                title: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(senderId).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text('Loading...');
                    }

                    final senderData =
                        snapshot.data?.data() as Map<String, dynamic>?;

                    if (senderData == null) {
                      return Text('알 수 없는 사용자');
                    }

                    final senderName = senderData['nickname'];
                    if (senderName == null) {
                      return Text('닉네임 없음');
                    }

                    return Text(senderName);
                  },
                ),
                subtitle: Text('친구 신청'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () =>
                          _respondToRequest(requestId, senderId, true),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () =>
                          _respondToRequest(requestId, senderId, false),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            children: requestWidgets,
          );
        },
      ),
    );
  }
}
