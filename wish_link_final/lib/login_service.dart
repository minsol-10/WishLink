import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'main.dart';

class SignUpService {
  // 회원가입 메서드
  Future<void> signUp({
    required String nickname,
    required BuildContext context,
  }) async {
    try {
      // 닉네임 중복 확인
      bool nicknameExists = await _checkIfExists('nickname', nickname);
      if (nicknameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 사용 중인 닉네임입니다.')),
        );
        return;
      }

      // 성공적으로 회원가입되었음을 알리는 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입이 완료되었습니다!')),
      );
    } catch (e) {
      // 예외 발생 시 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입에 실패했습니다: $e')),
      );
    }
  }
}

// Firestore에서 중복 여부 확인
Future<bool> _checkIfExists(String field, String value) async {
  QuerySnapshot querySnapshot;
  if (field == 'id') {
    querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('id', isEqualTo: value)
        .get();
  } else if (field == 'nickname') {
    querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: value)
        .get();
  } else {
    throw ArgumentError('Invalid field: $field');
  }

  return querySnapshot.docs.isNotEmpty;
}

class LoginService {
  // 로그인 메서드
  Future<void> signIn(
      {required String id,
      required String password,
      required BuildContext context,
      required}) async {
    try {
      // 입력받은 비밀번호 해싱 (SHA-256)
      var bytes = utf8.encode(password);
      var digest = sha256.convert(bytes);

      // Firestore에서 해당 ID로 저장된 사용자 문서 가져오기
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(id).get();

      if (!userDoc.exists) {
        // 가 존재하지 않는 경우
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('존재하지 않는 아이디입니다.')),
        );
        return;
      }

      // 저장된 비밀번호와 입력된 비밀번호의 해시 비교
      String storedPassword = userDoc.get('password');
      if (storedPassword != digest.toString()) {
        // 비밀번호가 일치하지 않는 경우
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
        );
        return;
      }

      // 로그인 성공
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인에 성공했습니다!')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OnboardingPage()),
      );
      // 여기서 로그인 성공 후의 로직을 추가할 수 있습니다.
    } catch (e) {
      // 예외 발생 시 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인에 실패했습니다: $e')),
      );
    }
  }
}
