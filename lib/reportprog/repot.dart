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
  String? selectedSubMateri1;
  String? selectedSubMateri2;
  String? selectedSubMateri3;
  String? pembahasanMateri1;
  String? pembahasanMateri2;
  String? pembahasanMateri3;
  List<PesertaData> pesertaList = [];
  List<Materi> materiList = [];
  List<DropdownMenuItem<String>> jabatanData = [];
  List<DropdownMenuItem<String>> shiftData = [];
  List<DropdownMenuItem<String>> placeData = [];
  List<DropdownMenuItem<String>> subMateriData = [];

  var idUser;
  bool isLoading = false; // Variable untuk mengontrol tampilan loading

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
      if (pesertaList.length > 1) {
        pesertaList.removeAt(index);
      }
    });
  }

  Future<void> _submitForm() async {
    setState(() {
      isLoading = true;
    });

    if (selectedDate == null ||
        selectedShift == null ||
        selectedPlace == null ||
        selectedSubMateri1 == null ||
        selectedSubMateri2 == null ||
        selectedSubMateri3 == null ||
        pembahasanMateri1 == null ||
        pembahasanMateri2 == null ||
        pembahasanMateri3 == null ||
        pesertaList.any(
            (peserta) => peserta.peserta == null || peserta.jabatan == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pastikan semua data terisi'),
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }
    // Mengirim data ke API
    try {
      List<Map<String, String>> materiDataList = [];
      Materi materi1 = Materi(selectedSubMateri1, pembahasanMateri1);
      Materi materi2 = Materi(selectedSubMateri2, pembahasanMateri2);
      Materi materi3 = Materi(selectedSubMateri3, pembahasanMateri3);
      materiList.add(materi1);
      materiList.add(materi2);
      materiList.add(materi3);
      // materiDataList.clear();
      for (var materi in materiList) {
        materiDataList.add({
          'submateri': materi.selectedSubMateri!,
          'materi': materi.pembahasanMateri!,
        });
      }

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
        'peserta': jsonEncode(pesertaDataList),
        'materi': jsonEncode(
            materiDataList) // Menggunakan jsonEncode untuk mengubah list peserta menjadi JSON string
      };

      // Kirim request POST ke API
      var url = "https://via-rosalina.com/api/preg/post.php";
      final response = await http.post(
        Uri.parse(url),
        body: formData,
      );
      var json = jsonDecode(response.body);
      if (json['message'] != 'already') {
        setState(() {
          isLoading = false;
          selectedSubMateri1 = null;
          selectedSubMateri2 = null;
          selectedSubMateri3 = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sukses Input Data'),
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ReportPage()),
          );
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data Sudah Tersedia'),
          ),
        );
      }
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
    var urls = 'https://via-rosalina.com/api/data/view_user.php';
    final response = await http.get(Uri.parse(urls));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to fetch peserta data');
    }
  }

  Future<List<DropdownMenuItem<String>>> _fetchJabatanData() async {
    var url = 'https://via-rosalina.com/api/data/view_jabatan.php';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      // Buat list dari DropdownMenuItem<String> dengan menggunakan map
      List<DropdownMenuItem<String>> items = jsonData.map((item) {
        String jabatan = item['name'] as String;
        return DropdownMenuItem<String>(
          value: jabatan,
          child: Text(jabatan),
        );
      }).toList();

      return items;
    } else {
      throw Exception('Failed to fetch jabatan data');
    }
  }

  Future<List<DropdownMenuItem<String>>> _fetchSubMateriData() async {
    var url = 'https://via-rosalina.com/api/data/view_submateri.php';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      // Buat list dari DropdownMenuItem<String> dengan menggunakan map
      List<DropdownMenuItem<String>> items = jsonData.map((item) {
        String submateri = item['name'] as String;
        return DropdownMenuItem<String>(
          value: submateri,
          child: Text(submateri),
        );
      }).toList();

      return items;
    } else {
      throw Exception('Failed to fetch Sub Materi data');
    }
  }

  Future<List<DropdownMenuItem<String>>> _fetchShiftData() async {
    setState(() {
      isLoading = true;
    });
    var url = 'https://via-rosalina.com/api/data/view_shift.php';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
      });
      final List<dynamic> jsonData = jsonDecode(response.body);

      // Buat list dari DropdownMenuItem<String> dengan menggunakan map
      List<DropdownMenuItem<String>> items = jsonData.map((item) {
        String shift = item['name'] as String;
        return DropdownMenuItem<String>(
          value: shift,
          child: Text(shift),
        );
      }).toList();

      return items;
    } else {
      throw Exception('Failed to fetch shift data');
    }
  }

  Future<List<DropdownMenuItem<String>>> _fetchPlaceData() async {
    var url = 'https://via-rosalina.com/api/data/view_place.php';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      // Buat list dari DropdownMenuItem<String> dengan menggunakan map
      List<DropdownMenuItem<String>> items = jsonData.map((item) {
        String place = item['name'] as String;
        return DropdownMenuItem<String>(
          value: place,
          child: Text(place),
        );
      }).toList();

      return items;
    } else {
      throw Exception('Failed to fetch shift data');
    }
  }

  @override
  void initState() {
    super.initState();
    getId();
    pesertaList.add(PesertaData());
    _fetchPesertaData().then((data) {
      setState(() {
        pesertaList[0].namaPesertaList =
            data.map<String>((item) => item['nama'] as String).toList();
      });
    }).catchError((error) {
      print('An error occurred: $error');
    });

    _fetchJabatanData().then((data) {
      setState(() {
        jabatanData =
            data; // Assign jabatanData dengan data yang diperoleh dari API
      });
    }).catchError((error) {
      print('An error occurred: $error');
    });
    _fetchShiftData().then((data) {
      setState(() {
        shiftData = data;
      });
    }).catchError((error) {
      print('An error occurred: $error');
    });
    _fetchPlaceData().then((data) {
      setState(() {
        placeData = data;
      });
    }).catchError((error) {
      print('An error occurred: $error');
    });
    _fetchSubMateriData().then((data) {
      setState(() {
        subMateriData = data;
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
      body: Container(
          child: Stack(
        children: [
          SingleChildScrollView(
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
                    items:
                        shiftData, // Menggunakan shiftData yang diambil dari API
                    iconSize: 20,
                    isDense: true,
                    decoration: const InputDecoration(
                      // fillColor: Colors.white.withOpacity(0.6),
                      // filled: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                    items: placeData,
                    iconSize: 20,
                    isExpanded: true, // Mengatur isExpanded menjadi true
                    isDense: true,
                    decoration: InputDecoration(
                      fillColor: Colors.white.withOpacity(0.6),
                      filled: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text('Pembahasan Materi 1'),
                  const SizedBox(height: 8.0),
                  DropdownButtonFormField<String>(
                    value: selectedSubMateri1,
                    onChanged: (value) {
                      setState(() {
                        selectedSubMateri1 = value;
                      });
                    },
                    items: subMateriData,
                    iconSize: 20,
                    isExpanded: true, // Mengatur isExpanded menjadi true
                    isDense: true,
                    decoration: InputDecoration(
                      fillColor: Colors.white.withOpacity(0.6),
                      filled: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  TextField(
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        pembahasanMateri1 = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan pembahasan materi',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text('Pembahasan Materi 2'),
                  const SizedBox(height: 8.0),
                  DropdownButtonFormField<String>(
                    value: selectedSubMateri2,
                    onChanged: (value) {
                      setState(() {
                        selectedSubMateri2 = value;
                      });
                    },
                    items: subMateriData,
                    iconSize: 20,
                    isExpanded: true, // Mengatur isExpanded menjadi true
                    isDense: true,
                    decoration: InputDecoration(
                      fillColor: Colors.white.withOpacity(0.6),
                      filled: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  TextField(
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        pembahasanMateri2 = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan pembahasan materi',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text('Pembahasan Materi 3'),
                  const SizedBox(height: 8.0),
                  DropdownButtonFormField<String>(
                    value: selectedSubMateri3,
                    onChanged: (value) {
                      setState(() {
                        selectedSubMateri3 = value;
                      });
                    },
                    items: subMateriData,
                    iconSize: 20,
                    isExpanded: true, // Mengatur isExpanded menjadi true
                    isDense: true,
                    decoration: InputDecoration(
                      fillColor: Colors.white.withOpacity(0.6),
                      filled: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  TextField(
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        pembahasanMateri3 = value;
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
                                items: pesertaList[index]
                                    .namaPesertaList
                                    ?.map((nama) {
                                  return DropdownMenuItem(
                                    value: nama,
                                    child: Text(nama),
                                  );
                                }).toList(),
                                iconSize: 20,
                                isExpanded:
                                    true, // Mengatur isExpanded menjadi true
                                isDense: true,
                                decoration: InputDecoration(
                                  fillColor: Colors.white.withOpacity(0.6),
                                  filled: true,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
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
                                items:
                                    jabatanData, // Menggunakan jabatanData yang telah diubah ke tipe List<DropdownMenuItem<String>>
                                iconSize: 20,
                                isDense: true,
                                decoration: InputDecoration(
                                  fillColor: Colors.white.withOpacity(0.6),
                                  filled: true,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
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
                    child: const Text('Tampilkan Data'),
                  ),
                ],
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
      )),
    );
  }
}

class PesertaData {
  String? peserta;
  String? jabatan;
  String? submateri;
  String? materi;
  List<String>? namaPesertaList;
  List<String>? namaMateriList;

  PesertaData(
      {this.peserta,
      this.jabatan,
      this.submateri,
      this.materi,
      this.namaMateriList,
      this.namaPesertaList});
}

class Materi {
  String? selectedSubMateri;
  String? pembahasanMateri;

  Materi(this.selectedSubMateri, this.pembahasanMateri);
}
