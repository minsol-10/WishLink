import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:wish_link_final/bucket_service.dart';
import 'package:wish_link_final/memo_service.dart';
import 'auth_service.dart';
import 'login_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'main_screen.dart';

// SharedPreferences 인스턴스를 어디서든 접근 가능하도록 전역 변수로 선언
late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // main 함수에서 async 사용하기 위함

  await Firebase.initializeApp(); // firebase 앱 시작

  // shared_preferences 인스턴스 생성
  prefs = await SharedPreferences.getInstance();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => AuthService()),
      ChangeNotifierProvider(create: (context) => BucketService()),
      ChangeNotifierProvider(create: (context) => MemoService()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser();
    // SharedPreferences에서 온보딩 완료 여부 조회
    // isOnboarded에 해당하는 값이 null을 반환하는 경우 false 할당
    bool isOnboarded = prefs.getBool("isOnboarded") ?? false;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.getTextTheme('Jua'),
      ),
      home: user == null ? Login() : HomePage(),
    );
  }
}

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Wish Link',
              style: TextStyle(fontSize: 28),
            ),
            centerTitle: true,
            backgroundColor: Color.fromARGB(251, 39, 190, 255),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(35),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 160,
                    ),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: ' 이메일',
                      labelStyle: TextStyle(fontSize: 19),
                    ),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: ' 비밀번호',
                      labelStyle: TextStyle(fontSize: 19),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        // 로그인
                        authService.signIn(
                          email: emailController.text,
                          password: passwordController.text,
                          onSuccess: () {
                            // 로그인 성공
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("로그인 성공"),
                            ));

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OnboardingPage()),
                            );
                          },
                          onError: (err) {
                            // 에러 발생
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(err),
                            ));
                          },
                        );
                      },
                      child: Text('로그인'),
                    ),
                  ), // Container
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        // 페이지 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Signup()),
                        );
                      },
                      child: Text('회원가입'),
                    ),
                  ),
                ], // children
              ), // column
            ), // padding
          ), // SingleChildScrollView
        );
      },
    ); // scaffold
  }
}

// Signup클래스 변경
class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController jobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '회원가입',
              style: TextStyle(fontSize: 28),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(35),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 160,
                    ),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(hintText: "이메일"),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(hintText: "비밀번호"),
                  ),
                  TextField(
                    controller: nicknameController,
                    decoration: InputDecoration(hintText: "닉네임"),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        AuthService authService = context.read<AuthService>();
                        bool nicknameExists = await authService
                            .isNicknameTaken(nicknameController.text);
                        if (nicknameExists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('이 닉네임은 이미 존재하는 닉네임입니다.')),
                          );
                          return;
                        }
                        authService.signUp(
                          email: emailController.text,
                          password: passwordController.text,
                          nickname: nicknameController.text,
                          onSuccess: () {
                            // 회원가입 성공
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("회원가입 성공"),
                            ));
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Login()),
                            );
                          },
                          onError: (err) {
                            // 에러 발생
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(err),
                            ));
                          },
                        );
                      },
                      child: Text('회원가입'),
                    ),
                  ),
                ], // children
              ), // column
            ), // padding
          ), // SingleChildScrollView
        );
      },
    );
  }
}

// 메인 페이지를 정의하는 StatefulWidget
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

// MainPage의 상태 관리
class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1; // 기본 선택된 페이지는 가운데 페이지 (버킷리스트 및 메모)

  // 각 탭에 대응하는 페이지 리스트
  static final List<Widget> _pages = <Widget>[
    DailyLifePage(), // 왼쪽 페이지
    HomePage(), // 가운데 페이지 (버킷리스트 및 메모)
    MainScreen(), // 오른쪽 페이지
  ];

  // 하단바의 아이템이 탭 되었을 때 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 선택된 인덱스로 상태를 변경
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 선택된 페이지를 body에 표시
      body: _pages[_selectedIndex],
      // 하단바 정의
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.photo_camera), // 일상 공유 아이콘
            label: 'Daily Life', // 일상 공유 라벨
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet), // 버킷 리스트 아이콘
            label: 'Bucket List', // 버킷 리스트 라벨
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_text), // 채팅 아이콘
            label: 'Chat', // 채팅 라벨
          ),
        ],
        currentIndex: _selectedIndex, // 현재 선택된 인덱스
        selectedItemColor: Colors.blueAccent, // 선택된 아이템의 색상
        onTap: _onItemTapped, // 탭될 때 호출되는 함수
      ),
    );
  }
}

// 기존 OnboardingPage 정의 유지
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        pages: [
          PageViewModel(
            title: "",
            bodyWidget: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
              children: [
                Padding(
                    padding: EdgeInsets.all(32),
                    child: Image.asset(
                      'assets/OB1.png',
                    )
                    // 이미지
                    ),
                Text(
                  "버킷리스트 한눈에 보기",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16), // 간격 추가
                Text(
                  "머릿속에 그리던 버킷리스트를 한눈에 확인하고 관리하세요.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center, // 중앙 정렬
                ),
              ],
            ),
          ),
          PageViewModel(
            title: "",
            bodyWidget: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
              children: [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Image.asset(
                    'assets/OB2.png',
                  ), // 이미지
                ),
                Text(
                  "캘린더에 메모 추가",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16), // 간격 추가
                Text(
                  "캘린더에 메모를 남겨 중요한 날들을 기록해 보세요.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center, // 중앙 정렬
                ),
              ],
            ),
          ),
          PageViewModel(
            title: "",
            bodyWidget: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
              children: [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Image.asset('assets/chat_image.png'), // 이미지
                ),
                Text(
                  "다른 사용자와의 소통",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16), // 간격 추가
                Text(
                  "희망찬 버킷리스트를 꿈꾸는 다른 사용자와 채팅해보세요.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center, // 중앙 정렬
                ),
              ],
            ),
          ),
          PageViewModel(
            title: "",
            bodyWidget: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
              children: [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Image.asset('assets/community.png'), // 이미지
                ),
                Text(
                  "성취한 버킷리스트 자랑",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16), // 간격 추가
                Text(
                  "버킷리스트 달성을 게시글로 공유하고 다른 사용자들과 소통해 보세요.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center, // 중앙 정렬
                ),
              ],
            ),
          ),
        ],
        next: Text("Next", style: TextStyle(fontWeight: FontWeight.w600)),
        done: Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
        onDone: () {
          // Done 클릭시 isOnboarded = true로 저장
          prefs.setBool("isOnboarded", true);

          // Done 클릭시 페이지 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        },
      ),
    );
  }
}

// 일상을 공유하는 페이지를 정의
class DailyLifePage extends StatelessWidget {
  const DailyLifePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController postController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '커뮤니티', // 사용자 닉네임 대신 "커뮤니티" 표시
          style: TextStyle(fontSize: 26),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.pencil, color: Colors.black),
            onPressed: () {
              _showPostDialog(context, postController);
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.person, color: Colors.black),
            onPressed: () {
              final userId = FirebaseAuth.instance.currentUser!.uid;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userId: userId),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feeds')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final feeds = snapshot.data!.docs;
          return ListView.builder(
            itemCount: feeds.length,
            itemBuilder: (context, index) {
              var feedData = feeds[index];
              return Feed(
                postId: feedData.id,
                postDescription: feedData['description'],
                postDate: feedData['date'],
                userId: feedData['userId'],
              );
            },
          );
        },
      ),
    );
  }

  void _showPostDialog(BuildContext context, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('새 글 작성'),
              content: SingleChildScrollView(
                // 추가된 부분
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: "내용을 입력하세요"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('업로드'),
                  onPressed: () {
                    _uploadPost(controller.text);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadPost(String description) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final String userId = user.uid;

      FirebaseFirestore.instance.collection('feeds').add({
        'description': description,
        'date': DateTime.now().toIso8601String(),
        'userId': userId,
      });
    } else {
      print("Error: user not logged in");
    }
  }
}

class Feed extends StatefulWidget {
  final String postId;
  final String postDescription;
  final String postDate;
  final String userId;

  const Feed({
    required this.postId,
    required this.postDescription,
    required this.postDate,
    required this.userId,
    super.key,
  });

  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                final userNickname = snapshot.data!.get('nickname');
                return Text(
                  userNickname,
                  style: TextStyle(fontWeight: FontWeight.bold),
                );
              } else {
                return Text('Loading...');
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.postDescription,
            style: TextStyle(fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.postDate.split('T').first, // 날짜만 표시
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                CupertinoIcons.heart,
                color: isFavorite ? Colors.pink : Colors.black,
              ),
              onPressed: () {
                setState(() {
                  isFavorite = !isFavorite;
                });
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feeds')
                  .doc(widget.postId)
                  .collection('comments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return IconButton(
                    icon: Icon(CupertinoIcons.chat_bubble, color: Colors.black),
                    onPressed: () {},
                  );
                }
                final commentCount = snapshot.data!.docs.length;
                return Row(
                  children: [
                    IconButton(
                      icon:
                          Icon(CupertinoIcons.chat_bubble, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CommentsPage(postId: widget.postId),
                          ),
                        );
                      },
                    ),
                    Text(commentCount.toString()),
                  ],
                );
              },
            ),
          ],
        ),
        Divider(),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String userId;

  const ProfilePage({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('프로필'),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          bottom: TabBar(
            tabs: [
              Tab(text: "내 게시물"),
              Tab(text: "내 댓글"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            UserPostsTab(userId: userId),
            UserCommentsTab(userId: userId),
          ],
        ),
      ),
    );
  }
}

// 사용자의 게시물 탭
class UserPostsTab extends StatelessWidget {
  final String userId;

  const UserPostsTab({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feeds')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final userPosts = snapshot.data!.docs;
        return ListView.builder(
          itemCount: userPosts.length,
          itemBuilder: (context, index) {
            var postData = userPosts[index];
            return ListTile(
              title: Text(postData['description']),
              subtitle: Text(postData['date'].toString().split('T').first),
              trailing: IconButton(
                icon: Icon(CupertinoIcons.delete),
                onPressed: () {
                  _deletePost(postData.id);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _deletePost(String postId) {
    FirebaseFirestore.instance.collection('feeds').doc(postId).delete();
  }
}

class UserCommentsTab extends StatelessWidget {
  final String userId;

  const UserCommentsTab({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('feeds').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final feeds = snapshot.data!.docs;

        if (feeds.isEmpty) {
          return Center(child: Text("작성한 게시물이 없습니다."));
        }

        return ListView.builder(
          itemCount: feeds.length,
          itemBuilder: (context, index) {
            var feedData = feeds[index];

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feeds')
                  .doc(feedData.id)
                  .collection('comments')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, commentSnapshot) {
                if (!commentSnapshot.hasData) {
                  return SizedBox(); // 로딩 시 아무것도 표시하지 않음
                }

                final userComments = commentSnapshot.data!.docs;

                if (userComments.isEmpty) {
                  return SizedBox(); // 해당 게시물에 사용자가 작성한 댓글이 없으면 아무것도 표시하지 않음
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: userComments.map((commentData) {
                    return ListTile(
                      title: Text(commentData['comment']),
                      subtitle:
                          Text(commentData['date'].toString().split('T').first),
                      trailing: IconButton(
                        icon: Icon(CupertinoIcons.delete),
                        onPressed: () {
                          _deleteComment(feedData.id, commentData.id);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  void _deleteComment(String postId, String commentId) {
    FirebaseFirestore.instance
        .collection('feeds')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}

class CommentsPage extends StatefulWidget {
  final String postId;

  const CommentsPage({required this.postId, Key? key}) : super(key: key);

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('댓글'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feeds')
                  .doc(widget.postId)
                  .collection('comments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var commentData = comments[index];
                    return ListTile(
                      title: Text(commentData['comment']),
                      subtitle:
                          Text(commentData['date'].toString().split('T').first),
                    );
                  },
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
                    controller: commentController,
                    decoration: InputDecoration(hintText: "댓글을 입력하세요"),
                  ),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.arrow_up_circle),
                  onPressed: () {
                    _addComment();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addComment() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null && commentController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('feeds')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'comment': commentController.text,
        'date': DateTime.now().toIso8601String(),
        'userId': user.uid, // userId 추가
      });
      commentController.clear();
    } else {
      // 사용자 로그인 상태가 아니거나 댓글이 비어있을 경우
      print("Error: user not logged in or comment is empty");
    }
  }
}

// 기존 HomePage 정의 유지, 이 페이지가 버킷 리스트 및 메모 기능을 담당
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Bucket> bucketList = []; // 전체 버킷리스트 목록
  Map<DateTime, List<Memo>> memoList = {}; // 날짜별 메모 목록
  DateTime selectedDate = DateTime.now(); // 선택한 날짜

  @override
  void initState() {
    super.initState();
    _loadMemos(); // 저장된 메모 로드
  }

  void _loadMemos() {
    // SharedPreferences에서 저장된 메모 로드
    List<String>? savedMemos = prefs.getStringList('memos');
    if (savedMemos != null) {
      setState(() {
        for (var memo in savedMemos) {
          Memo loadedMemo = Memo.fromJson(jsonDecode(memo));
          memoList.putIfAbsent(loadedMemo.date, () => []).add(loadedMemo);
        }
      });
    }
  }

  void _saveMemos() {
    // 메모를 SharedPreferences에 저장
    List<String> memos = memoList.values
        .expand((e) => e)
        .map((memo) => jsonEncode(memo.toJson()))
        .toList();
    prefs.setStringList('memos', memos);
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser()!;
    return Consumer<BucketService>(
      builder: (context, bucketService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text("버킷 리스트 및 메모"),
            actions: [
              TextButton(
                child: Text("로그아웃"),
                onPressed: () {
                  // 로그아웃
                  context.read<AuthService>().signOut();

                  // 로그인 페이지로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              TableCalendar(
                focusedDay: selectedDate,
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDate, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    selectedDate = selectedDay;
                  });
                  _showMemoDialog(context, selectedDay);
                },
              ),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: bucketService.read(user.uid),
                  builder: (context, snapshot) {
                    final documents = snapshot.data?.docs ?? []; // 문서들 가져오기

                    if (documents.isEmpty) {
                      return Center(child: Text("버킷 리스트를 작성해 주세요."));
                    } else {
                      return ListView.builder(
                        itemCount: documents.length, // bucketList 개수 만큼 보여주기
                        itemBuilder: (context, index) {
                          final doc = documents[index];
                          String job = doc.get('job');
                          bool isDone = doc.get('isDone');
                          return ListTile(
                            // 버킷 리스트 할 일
                            title: Text(
                              job,
                              style: TextStyle(
                                fontSize: 24,
                                color: isDone ? Colors.grey : Colors.black,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            // 삭제 아이콘 버튼
                            trailing: IconButton(
                              icon: Icon(CupertinoIcons.delete),
                              onPressed: () async {
                                bucketService.delete(doc.id);
                              },
                            ),
                            onTap: () {
                              // 아이템 클릭시
                              setState(() {
                                bucketService.update(doc.id, !isDone);
                                // documents[index].data()['isDone'] = !isDone;
                              });
                            },
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () async {
              // + 버튼 클릭시 버킷 생성 페이지로 이동
              String? job = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreatePage()),
              );
              if (job != null) {
                setState(() {
                  Bucket newBucket = Bucket(job, false);
                  bucketList.add(newBucket); // 버킷 리스트에 추가
                });
              }
            },
          ),
        );
      },
    );
  }

  void _showMemoDialog(BuildContext context, DateTime date) {
    TextEditingController memoController = TextEditingController();
    List<Memo>? selectedMemos = memoList[date];

    final authService = context.read<AuthService>();
    final user = authService.currentUser()!;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<MemoService>(
              builder: (context, memoService, child) {
                return AlertDialog(
                  title: Text("메모 입력"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: memoController,
                        decoration: InputDecoration(hintText: "메모를 입력하세요"),
                      ),
                      SizedBox(height: 16),
                      if (selectedMemos != null)
                        ...selectedMemos.map((memo) => ListTile(
                              title: Text(memo.content),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    selectedMemos.remove(memo);
                                    if (selectedMemos.isEmpty) {
                                      memoList.remove(date);
                                    }
                                    _saveMemos();
                                  });
                                },
                              ),
                            )),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("취소"),
                    ),
                    TextButton(
                      onPressed: () {
                        // 메모 내용이 비어있지 않을 때만 저장

                        if (memoController.text.trim().isNotEmpty) {
                          setState(() {
                            Memo newMemo =
                                Memo(date, memoController.text.trim());
                            memoService.create(
                                date, memoController.text.trim(), user.uid);
                            if (memoList[date] == null) {
                              memoList[date] = [newMemo];
                              memoService.create(
                                  date, memoController.text.trim(), user.uid);
                            } else {
                              memoList[date]!.add(newMemo);
                              memoService.create(
                                  date, memoController.text.trim(), user.uid);
                            }

                            _saveMemos(); // 메모 저장
                          });
                        }
                        Navigator.pop(context);
                      },
                      child: Text("저장"),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("정말로 삭제하시겠습니까?"),
          actionsPadding: EdgeInsets.all(0),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("취소"),
            ),
            // 확인 버튼
            TextButton(
              onPressed: () {
                setState(() {
                  // index에 해당하는 항목 삭제
                  bucketList.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: Text(
                "확인",
                style: TextStyle(color: Colors.pink),
              ),
            ),
          ],
        );
      },
    );
  }
}

// 채팅 페이지를 정의
class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
      ),
      body: Center(
        child: Text(
          '채팅 기능이 있는 페이지',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

// 버킷 클래스
class Bucket {
  String job; // 할 일
  bool isDone; // 완료 여부

  Bucket(this.job, this.isDone); // 생성자
}

// 메모 클래스
class Memo {
  DateTime date; // 메모 날짜
  String content; // 메모 내용

  Memo(this.date, this.content); // 생성자

  // 메모를 Map으로 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'content': content,
    };
  }

  // Map을 메모로 변환
  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      DateTime.parse(json['date']),
      json['content'],
    );
  }
}

// 버킷 생성 페이지
class CreatePage extends StatefulWidget {
  const CreatePage({Key? key}) : super(key: key);

  @override
  State<CreatePage> createState() => _CreatePageState();
}

// CreatePage의 상태 관리
class _CreatePageState extends State<CreatePage> {
  // TextField의 값을 가져올 때 사용합니다.
  TextEditingController textController = TextEditingController();
  TextEditingController jobController = TextEditingController();
  // 경고 메세지
  String? error;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser()!;
    return Consumer<BucketService>(
      builder: (context, bucketService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text("버킷리스트 작성"),
            // 뒤로가기 버튼
            leading: IconButton(
              icon: Icon(CupertinoIcons.chevron_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 텍스트 입력창
                TextField(
                  controller: jobController, // 연결해 줍니다.
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "하고 싶은 일을 입력하세요",
                    errorText: error,
                  ),
                ),
                SizedBox(height: 32),
                // 추가하기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    child: Text(
                      "추가하기",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    onPressed: () {
                      // 추가하기 버튼 클릭시
                      if (jobController.text.isNotEmpty) {
                        bucketService.create(jobController.text, user.uid);
                      }
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
