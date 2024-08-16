import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateGroupScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  Future<void> _createGroup(BuildContext context) async {
    String groupName = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 이름을 입력하세요.')),
      );
      return;
    }

    try {
      // Firestore에 새 그룹 추가 (그룹 생성자 ID 포함)
      await FirebaseFirestore.instance.collection('groups').add({
        'name': groupName,
        'created_at': Timestamp.now(),
        'creator_id': user!.uid, // 생성자 ID 추가
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹이 성공적으로 생성되었습니다.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 생성 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _deleteGroup(
      String groupId, String? creatorId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    // creatorId가 null인 경우나 현재 사용자가 그룹의 생성자가 아닌 경우
    if (creatorId == null || user!.uid != creatorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이 그룹을 삭제할 권한이 없습니다.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 삭제 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('그룹 생성 및 관리'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '그룹 이름',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _createGroup(context),
              child: Text('그룹 생성'),
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('groups').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final groups = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final groupData = group.data() as Map<String, dynamic>;
                      final creatorId = groupData.containsKey('creator_id')
                          ? groupData['creator_id'] as String?
                          : null;
                      return ListTile(
                        title: Text(groupData['name']),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteGroup(group.id, creatorId, context);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
