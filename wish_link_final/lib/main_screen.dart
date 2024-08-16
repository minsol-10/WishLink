import 'package:flutter/material.dart';
import 'add_friend_screen.dart';
import 'friend_list_screen.dart'; // 추가된 파일
import 'group_chat_screen.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('메인 화면'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person_add),
            title: Text('친구 추가'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFriendScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('1대1 채팅'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FriendListScreen()), // 친구 목록으로 수정
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.group),
            title: Text('그룹 채팅'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GroupChatScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
