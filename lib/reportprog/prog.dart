import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:excel/excel.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({Key? key}) : super(key: key);

  @override
  ProgramPageState createState() => ProgramPageState();
}

class ProgramPageState extends State<ProgramPage> {
  DateTime? selectedDate;
  String? selectedShift;
  List<DropdownMenuItem<String>> shiftData = [];

  var idUser;
  String? tempat = '';
  // String? meetingid = '';
  String? materi = '';
  List<Map<String, dynamic>> peserta = [];
  List<Map<String, dynamic>> pembahasan = [];
  List<Map<String, dynamic>> location = [];
  bool isLoading = false;

  Future<void> getId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var idObtained = prefs.getString('id');
    setState(() {
      idUser = idObtained!;
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

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var url = "https://via-rosalina.com/api/preg/view_preg.php";
      var response = await http.post(Uri.parse(url), body: {
        'user_id': idUser.toString(),
        'date': selectedDate.toString(),
        'shift': selectedShift,
      });
      var jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        setState(() {
          isLoading = false;
          peserta = List<Map<String, dynamic>>.from(jsonData['data'])
              .map((data) => {
                    'nama_peserta': data['nama_peserta'],
                    'jabatan': data['jabatan'],
                    'meeting_id': data['meeting_id'],
                  })
              .toList();
          location = List<Map<String, dynamic>>.from(jsonData['data'])
              .map((data) => {
                    'tempat': data['tempat'],
                  })
              .toList();
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Data tidak ditemukan'),
        ));
      }
    } catch ($e) {
      // Handle error
    }
  }

  Future<void> _fetchDataMateri() async {
    setState(() {
      isLoading = true;
    });
    try {
      var url = "https://via-rosalina.com/api/preg/view_meeting_deatils.php";
      var response = await http.post(Uri.parse(url), body: {
        'user_id': idUser.toString(),
        'date': selectedDate.toString(),
        'shift': selectedShift,
      });
      var jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        setState(() {
          isLoading = false;
          pembahasan = List<Map<String, dynamic>>.from(jsonData['data'])
              .map((data) => {
                    'submateri': data['submateri'],
                    'materi': data['materi'],
                  })
              .toList();
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Data tidak ditemukan'),
        ));
      }
    } catch ($e) {
      // Handle error
    }
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    var sheet = excel['Data Briefing'];

    // Menambahkan header kolom
    var headers = [
      'Tanggal',
      'Shift',
      'Tempat',
      'Pembahasan',
      'Materi',
      'Nama Peserta',
      'Jabatan'
    ];
    for (var col = 0; col < headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = headers[col];
    }

// Menambahkan data pertemuan
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        DateFormat('yyyy-MM-dd').format(selectedDate!);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value =
        selectedShift;

    for (var i = 0; i < location.length; i++) {
      var tempat = location[i]['tempat'];

      // Menampilkan "Data Briefing: nomor"
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2 * i + 1))
          .value = 'Data Briefing: ${i + 1}';
      // Menampilkan nilai tempat
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2 * i + 2))
          .value = tempat;
    }

// Menambahkan data pembahasan materi
    var row = 1;
    var briefingIndex = 1;
    for (var i = 0; i < pembahasan.length; i++) {
      if (i % 3 == 0) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = 'Data Briefing: $briefingIndex';
        row++;
        briefingIndex++;
      }
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = pembahasan[i]['submateri'];
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = pembahasan[i]['materi'];
      if ((i + 1) % 3 == 0) {
        row++;
      }
      row++;
    }
    var rows = 1;
    var briefingsIndex = 1;

// Mengurutkan peserta berdasarkan meeting ID
    peserta.sort((a, b) => a['meeting_id'].compareTo(b['meeting_id']));

    var currentMeetingId = '';
    for (var i = 0; i < peserta.length; i++) {
      var meetingId = peserta[i]['meeting_id'];

      if (meetingId != currentMeetingId) {
        // Menampilkan judul Data Briefing jika meeting ID berbeda
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rows))
            .value = 'Data Briefing: $briefingsIndex';
        briefingsIndex++;
        rows++;

        currentMeetingId = meetingId;
      }

      // Menampilkan peserta pada meeting ID yang sama
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rows))
          .value = peserta[i]['nama_peserta'];
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rows))
          .value = peserta[i]['jabatan'];

      rows++;

      // Menambahkan baris kosong setelah setiap data briefing
      if (i < peserta.length - 1 && peserta[i + 1]['meeting_id'] != meetingId) {
        rows++;
      }
    }

    // Mendapatkan direktori penyimpanan aplikasi
    var directory = await getTemporaryDirectory();

    // Mendapatkan path file Excel
    var filePath = '${directory.path}/data_meeting.xlsx';

    // Menyimpan file Excel
    var fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }

    // Membuka file Excel
    OpenFile.open(filePath);
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

  @override
  void initState() {
    getId();
    _fetchShiftData().then((data) {
      setState(() {
        shiftData = data;
      });
    }).catchError((error) {
      print('An error occurred: $error');
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Briefing'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Informasi Pertemuan',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
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
                  ElevatedButton(
                    onPressed: () {
                      if (selectedDate != null && selectedShift != null) {
                        _fetchData();
                        _fetchDataMateri();
                        print(
                            'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}');
                        print('Selected Shift: $selectedShift');
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Please select date and shift'),
                        ));
                      }
                    },
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Informasi Pertemuan',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                              'Tanggal: ${selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : ''}'),
                          const SizedBox(height: 4.0),
                          Text('Shift: ${selectedShift ?? ''}'),
                          const SizedBox(height: 4.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tempat: '),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4.0),
                                  for (var i = 0; i < location.length; i++)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child:
                                              Text('Data Briefing: ${(i + 1)}'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Text(
                                            'Tempat: ${location[i]['tempat']}',
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pembahasan Materi: '),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4.0),
                                  for (var i = 0; i < pembahasan.length; i++)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (i % 3 == 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Text(
                                                'Data Briefing: ${(i ~/ 3) + 1}'), // Menampilkan nomor urut di atas setiap 3 data
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Text(
                                            '${pembahasan[i]['submateri']}: ${pembahasan[i]['materi']}',
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          const Text('Peserta dan Jabatan: \n'),
                          Center(
                            child: Column(
                              children: peserta
                                  .map((pesertaData) =>
                                      pesertaData['meeting_id'])
                                  .toSet()
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map(
                                (entry) {
                                  final meetingId = entry.value;
                                  final meetingPeserta = peserta
                                      .where((pesertaData) =>
                                          pesertaData['meeting_id'] ==
                                          meetingId)
                                      .toList();
                                  int nomorUrutan = 1;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),
                                      Center(
                                        child: Text(
                                          'Data Briefing ${entry.key + 1}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataTable(
                                        columns: const [
                                          DataColumn(label: Text('No.')),
                                          DataColumn(label: Text('Peserta')),
                                          DataColumn(label: Text('Jabatan')),
                                        ],
                                        rows: meetingPeserta.map((pesertaData) {
                                          final index =
                                              peserta.indexOf(pesertaData);
                                          final row = DataRow(
                                            cells: [
                                              DataCell(Text('$nomorUrutan')),
                                              DataCell(Text(
                                                  pesertaData['nama_peserta'])),
                                              DataCell(
                                                  Text(pesertaData['jabatan'])),
                                            ],
                                          );
                                          nomorUrutan++;
                                          return row;
                                        }).toList(),
                                      ),
                                    ],
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Center(
                            child: ElevatedButton(
                              onPressed: _exportToExcel,
                              child: const Text('Cetak Data'),
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
