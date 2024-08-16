import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MemoService extends ChangeNotifier {
  final memoCollection = FirebaseFirestore.instance.collection('memos');

  // 메모 생성
  void create(DateTime date, String content, String uid) async {
    await memoCollection.add({
      'date': date.toIso8601String(),
      'content': content,
      'uid': uid,
    });
    notifyListeners(); // 화면 갱신
  }

  // 특정 UID에 해당하는 메모 읽기
  Future<List<CalendarMemo>> read(String uid) async {
    QuerySnapshot querySnapshot = await memoCollection
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .get();

    List<CalendarMemo> memos = querySnapshot.docs.map((doc) {
      return CalendarMemo.fromDocument(doc);
    }).toList();

    return memos;
  }

  // 메모 업데이트
  void update(String docId, String newContent) async {
    await memoCollection.doc(docId).update({
      'content': newContent,
    });
    notifyListeners(); // 화면 갱신
  }

  // 메모 삭제
  void delete(String docId) async {
    await memoCollection.doc(docId).delete();
    notifyListeners(); // 화면 갱신
  }
}

// 메모 클래스
class CalendarMemo {
  String id;
  DateTime date;
  String content;
  String uid;

  CalendarMemo({
    required this.id,
    required this.date,
    required this.content,
    required this.uid,
  });

  // Firebase에서 가져온 Document를 Memo 객체로 변환
  factory CalendarMemo.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CalendarMemo(
      id: doc.id,
      date: DateTime.parse(data['date']),
      content: data['content'],
      uid: data['uid'],
    );
  }

  // 메모를 Map으로 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'content': content,
      'uid': uid,
    };
  }
}
