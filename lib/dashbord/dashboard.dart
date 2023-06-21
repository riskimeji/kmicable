import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:get/get.dart';
import 'package:kmicable/auth/login.dart';
import 'package:kmicable/reportprog/repot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  var nama;
  var id;

  Future<void> getId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var namaObtained = prefs.getString('nama');
    var idObtained = prefs.getString('id');
    setState(() {
      nama = namaObtained!;
      id = idObtained!;
    });
  }

  @override
  void initState() {
    getId();
    // isLoading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // @override
    // void initState() {
    //   super.initState();
    //   getId();
    // }

    void logout() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('id', '');
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bgLogin.jpg'),
            // image: AssetImage('bgLogin.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Text(
                    nama ?? '',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ReportPage()));
                        },
                        child: SizedBox(
                          width: 160.0,
                          height: 160.0,
                          child: Card(
                            color: const Color(0xffc3f2f8),
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                    ),
                                    Image.asset(
                                      'assets/upload.png',
                                      // 'upload.png',
                                      width: 150,
                                      height: 100,
                                    ),
                                    const SizedBox(height: 10.0),
                                    const Text(
                                      "Report Prog",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          logout();
                        },
                        child: SizedBox(
                          width: 160.0,
                          height: 160.0,
                          child: Card(
                            color: const Color(0xffc3f2f8),
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                    ),
                                    Image.asset(
                                      'assets/logout.png',
                                      // 'logout.png',
                                      width: 150,
                                      height: 100,
                                    ),
                                    const SizedBox(height: 10.0),
                                    const Text(
                                      "Logout",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
