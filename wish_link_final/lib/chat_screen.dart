import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class ChatScreen extends StatefulWidget {
  final String friendId;

  ChatScreen({required this.friendId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 사용자 인증이 되지 않은 경우 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다.')),
      );
      Navigator.pop(context); // 채팅 화면에서 나가도록 처리
    }
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty && user != null) {
      // 친구 관계 확인
      final friendDoc = await _firestore
          .collection('friends')
          .doc(user!.uid)
          .collection('friends')
          .doc(widget.friendId)
          .get();

      if (friendDoc.exists) {
        _firestore.collection('chats').add({
          'senderId': user!.uid,
          'receiverId': widget.friendId,
          'text': _controller.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _controller.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅을 시작하려면 친구 관계를 맺어야 합니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('1대1 채팅')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: Rx.combineLatest2(
                _firestore
                    .collection('chats')
                    .where('senderId', isEqualTo: user!.uid)
                    .where('receiverId', isEqualTo: widget.friendId)
                    .snapshots()
                    .map((snapshot) => snapshot.docs),
                _firestore
                    .collection('chats')
                    .where('senderId', isEqualTo: widget.friendId)
                    .where('receiverId', isEqualTo: user!.uid)
                    .snapshots()
                    .map((snapshot) => snapshot.docs),
                (senderMessages, receiverMessages) {
                  return [...senderMessages, ...receiverMessages]..sort(
                      (a, b) => (b['timestamp'] as Timestamp)
                          .compareTo(a['timestamp'] as Timestamp));
                },
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                List<Widget> messageWidgets = [];

                for (var message in messages) {
                  final messageText = message['text'];
                  final messageSender = message['senderId'];
                  final isMine = messageSender == user!.uid;
                  final messageWidget = ListTile(
                    title: Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          messageText,
                          style: TextStyle(
                            color: isMine ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                  messageWidgets.add(messageWidget);
                }

                return ListView(
                  reverse: true, // 최신 메시지가 아래에 표시되도록 설정
                  children: messageWidgets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
