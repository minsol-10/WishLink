import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFriendScreen extends StatefulWidget {
  @override
  _AddFriendScreenState createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _nicknameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _sendFriendRequest(BuildContext context) async {
    final nickname = _nicknameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user == null) {
        throw '사용자가 로그인하지 않았습니다.';
      }

      // Check if the nickname exists
      var snapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get();

      if (snapshot.docs.isEmpty) {
        throw '존재하지 않는 닉네임입니다.';
      }

      // Get the friend's user ID
      final friendId = snapshot.docs.first.id;

      // Check if a friend request already exists
      var requestSnapshot = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: user.uid)
          .where('receiverId', isEqualTo: friendId)
          .get();

      if (requestSnapshot.docs.isNotEmpty) {
        throw '이미 친구 신청을 보냈습니다.';
      }

      // Add friend request to Firestore
      await _firestore.collection('friend_requests').add({
        'senderId': user.uid,
        'receiverId': friendId,
        'status': 'pending', // 상태: 대기 중
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Ensure context is still valid before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 신청을 보냈습니다.')),
        );
      }
    } catch (e) {
      // Ensure context is still valid before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('친구 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(labelText: '친구의 닉네임'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _sendFriendRequest(context), // Pass context here
              child: Text('친구 신청 보내기'),
            ),
          ],
        ),
      ),
    );
  }
}
