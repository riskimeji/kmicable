import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:kmicable/reportprog/prog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime? selectedDate;
  String? selectedShift;
  String? selectedPlace;
  String? pembahasanMateri;
  List<PesertaData> pesertaList = [];

  var idUser;

  Future<void> getId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var idObtained = prefs.getString('id');
    setState(() {
      idUser = idObtained!;
      print(idUser);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2023, 12, 31),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void _addPeserta() {
    setState(() {
      final firstPesertaData = pesertaList.first;
      pesertaList
          .add(PesertaData(namaPesertaList: firstPesertaData.namaPesertaList));
    });
  }

  void _removePeserta(int index) {
    setState(() {
      pesertaList.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (selectedDate == null ||
        selectedShift == null ||
        selectedPlace == null ||
        pembahasanMateri == null ||
        pesertaList.any(
            (peserta) => peserta.peserta == null || peserta.jabatan == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pastikan semua data terisi'),
        ),
      );
      return;
    }
    // Mengirim data ke API
    try {
      // Buat list yang akan menyimpan data peserta
      List<Map<String, String>> pesertaDataList = [];

      // Tambahkan data peserta ke list
      for (var peserta in pesertaList) {
        pesertaDataList.add({
          'nama': peserta.peserta!,
          'jabatan': peserta.jabatan!,
        });
      }

      // Buat objek JSON yang berisi data form
      final formData = {
        'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
        'shift': selectedShift!,
        'user_id': idUser!,
        'tempat': selectedPlace!,
        'materi': pembahasanMateri!,
        'peserta': jsonEncode(
            pesertaDataList), // Menggunakan jsonEncode untuk mengubah list peserta menjadi JSON string
      };

      // Kirim request POST ke API
      var url =
          "https://galonumkm.000webhostapp.com/kmicable/api/preg/post.php";
      // var url = "http://192.168.1.15/kmicable/api/preg/post.php";
      final response = await http.post(
        Uri.parse(url),
        body: formData,
      );
      var json = jsonDecode(response.body);
      if (json['message'] != 'already') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sukses Input Data'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal Input Data'),
          ),
        );
      }
      // Periksa kode status response
      // if (response.statusCode == 200) {
      //   // Sukses
      //   // Lakukan tindakan yang sesuai, misalnya menampilkan notifikasi atau pindah ke halaman lain
      //   print('Form submitted successfully');
      // } else {
      //   // Gagal
      //   print('Form submission failed');
      // }
    } catch (error) {
      // Tangani error
      print('An error occurred: $error');
    }
  }

  void _cetakData() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const ProgramPage()));
  }

  Future<List<dynamic>> _fetchPesertaData() async {
    // var urls = 'http://192.168.1.15/kmicable/api/data/view_user.php';
    var urls =
        'https://galonumkm.000webhostapp.com/kmicable/api/data/view_user.php';
    final response = await http.get(Uri.parse(urls));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to fetch peserta data');
    }
  }

  @override
  void initState() {
    super.initState();
    getId();
    // Tambahkan satu objek PesertaData saat halaman pertama kali dibuka
    pesertaList.add(PesertaData());
    _fetchPesertaData().then((data) {
      setState(() {
        pesertaList[0].namaPesertaList =
            data.map<String>((item) => item['nama'] as String).toList();
      });
    }).catchError((error) {
      print('An error occurred: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Input Data'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tanggal'),
              const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  selectedDate != null
                      ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                      : 'Pilih Tanggal',
                ),
              ),
              const SizedBox(height: 16.0),
              const Text('Shift'),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: selectedShift,
                onChanged: (value) {
                  setState(() {
                    selectedShift = value;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: 'SHIFT I',
                    child: Text('SHIFT I'),
                  ),
                  DropdownMenuItem(
                    value: 'SHIFT II',
                    child: Text('SHIFT II'),
                  ),
                  DropdownMenuItem(
                    value: 'SHIFT III',
                    child: Text('SHIFT III'),
                  ),
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              const Text('Tempat'),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: selectedPlace,
                onChanged: (value) {
                  setState(() {
                    selectedPlace = value;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: 'LT 1',
                    child: Text('LT 1'),
                  ),
                  DropdownMenuItem(
                    value: 'LT 2',
                    child: Text('LT 2'),
                  ),
                  DropdownMenuItem(
                    value: 'LT 3',
                    child: Text('LT 3'),
                  ),
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              const Text('Pembahasan Materi'),
              const SizedBox(height: 8.0),
              TextField(
                maxLines: null,
                onChanged: (value) {
                  setState(() {
                    pembahasanMateri = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan pembahasan materi',
                ),
              ),
              const SizedBox(height: 16.0),
              const Text('Peserta & Jabatan'),
              const SizedBox(height: 8.0),
              Column(
                children:
                    List<Widget>.generate(pesertaList.length, (int index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: pesertaList[index].peserta,
                            onChanged: (value) {
                              setState(() {
                                pesertaList[index].peserta = value;
                              });
                            },
                            items:
                                pesertaList[index].namaPesertaList?.map((nama) {
                              return DropdownMenuItem(
                                value: nama,
                                child: Text(nama),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: pesertaList[index].jabatan,
                            onChanged: (value) {
                              setState(() {
                                pesertaList[index].jabatan = value;
                              });
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'Jabatan 1',
                                child: Text('Jabatan 1'),
                              ),
                              DropdownMenuItem(
                                value: 'Jabatan 2',
                                child: Text('Jabatan 2'),
                              ),
                              DropdownMenuItem(
                                value: 'Jabatan 3',
                                child: Text('Jabatan 3'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _removePeserta(index),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addPeserta,
                child: const Text('Tambah Peserta'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _cetakData,
                child: const Text('Cetak Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PesertaData {
  String? peserta;
  String? jabatan;
  List<String>? namaPesertaList;

  PesertaData({this.peserta, this.jabatan, this.namaPesertaList});
}
