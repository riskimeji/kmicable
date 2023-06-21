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
  late String ids;

  @override
  Widget build(BuildContext context) {
    @override
    Future<void> getId() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var obtainedId = prefs.getString('id');
      setState(() {
        ids = obtainedId!;
      });
      print(ids);
    }

    void initState() {
      super.initState();
      getId().whenComplete(() async {
        Timer(const Duration(seconds: 2),
            () => Get.to(ids == '' ? const LoginPage() : const Dashboard()));
      });
    }

    Future<void> fetchLogin() async {
      // String url = "http://192.168.1.15/kmicable/api/auth/login.php";
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
        // await SessionManager().set("id", id);
        // await SessionManager().set("nama", nama);
        // ignore: use_build_context_synchronously
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
              content: const Text('Username, email, or password is incorrect.'),
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
    }

    return Scaffold(
      body: Container(
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
                        fillColor:
                            Colors.white.withOpacity(0.6), // Transparansi 80%
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: password,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        fillColor:
                            Colors.white.withOpacity(0.6), // Transparansi 80%
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
                        primary: const Color(
                            0xFF362981), // Ubah warna tombol menjadi #362981
                        onPrimary:
                            Colors.white, // Ubah warna teks menjadi putih
                        elevation: 0, // Hapus bayangan tombol
                        minimumSize: const Size(
                            double.infinity, 60), // Sesuaikan ukuran tombol
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
    );
  }
}
