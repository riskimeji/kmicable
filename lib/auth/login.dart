import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kmicable/dashbord/dashboard.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  late String ids = '0';
  bool isLoading = false;

  Future<void> getId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var obtainedId = prefs.getString('id');
    setState(() {
      ids = obtainedId!;
    });
    // if (ids != '0') {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => const Dashboard()),
    //   );
    // } else {
    //   // Tindakan lain jika ids adalah '0'
    // }

    // return;
  }

  @override
  void initState() {
    super.initState();
    getId();
  }

  Future<void> fetchLogin() async {
    setState(() {
      isLoading = true;
    });

    String url =
        "https://galonumkm.000webhostapp.com/kmicable/api/auth/login.php";
    var response = await http.post(Uri.parse(url),
        body: {'username': username.text, 'password': password.text});
    var json = jsonDecode(response.body);
    if (json['success'] == true) {
      var id = json['id'];
      var nama = json['nama'];
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('id', id);
      prefs.setString('nama', nama);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Failed'),
            content: const Text('Username or password is incorrect.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bgLogin.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo2.png',
                          width: 80,
                          height: 80,
                        ),
                        Image.asset(
                          'assets/logo1.jpeg',
                          width: 80,
                          height: 80,
                        ),
                      ],
                    ),
                    const Text(
                      'PT KMI Wire and Cable Tbk',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: username,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            fillColor: Colors.white.withOpacity(0.6),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: password,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            fillColor: Colors.white.withOpacity(0.6),
                            filled: true,
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            fetchLogin();
                          },
                          style: ElevatedButton.styleFrom(
                            primary: const Color(0xFF362981),
                            onPrimary: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 60),
                          ),
                          child: const Text('Login'),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    const SizedBox(height: 60),
                    const Text(
                      'Created by Achamad Naro. V9',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: isLoading,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
