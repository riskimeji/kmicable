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
  var idUser;
  String? tempat = '';
  String? materi = '';
  List<Map<String, dynamic>> peserta = [];
  bool isLoading = false;

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

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      // var url = "http://192.168.1.15/kmicable/api/preg/view_preg.php";
      var url =
          "https://galonumkm.000webhostapp.com/kmicable/api/preg/view_preg.php";
      var response = await http.post(Uri.parse(url), body: {
        'user_id': idUser.toString(),
        'date': selectedDate.toString(),
        'shift': selectedShift,
      });
      var jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        setState(() {
          isLoading = false;
          tempat = jsonData['data'][0]['tempat'];
          materi = jsonData['data'][0]['materi'];
          peserta = List<Map<String, dynamic>>.from(jsonData['data'])
              .map((data) => {
                    'nama_peserta': data['nama_peserta'],
                    'jabatan': data['jabatan'],
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
    var sheet = excel['Peserta Meeting'];

    // Menambahkan header kolom
    var headers = [
      'Tanggal',
      'Shift',
      'Tempat',
      'Pembahasan Materi',
      'Nama Peserta'
      // 'Jabatan'
    ];
    for (var row = 0; row < headers.length; row++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = headers[row];
    }

    // Menambahkan data pertemuan
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
        DateFormat('yyyy-MM-dd').format(selectedDate!);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value =
        selectedShift;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value =
        tempat;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value =
        materi;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value =
        'Jabatan';

    // Menambahkan data peserta
    var row = headers.length;
    for (var data in peserta) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = data['nama_peserta'];
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = data['jabatan'];
      row++;
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

  @override
  void initState() {
    getId();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Meeting'),
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
                    items: const [
                      DropdownMenuItem(
                        value: 'Non-Shift',
                        child: Text('Non-Shift'),
                      ),
                      DropdownMenuItem(
                        value: 'N1',
                        child: Text('N1'),
                      ),
                      DropdownMenuItem(
                        value: 'Shift 1',
                        child: Text('Shift 1'),
                      ),
                      DropdownMenuItem(
                        value: 'Shift 2',
                        child: Text('Shift 2'),
                      ),
                      DropdownMenuItem(
                        value: 'Shift 3',
                        child: Text('Shift 3'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedDate != null && selectedShift != null) {
                        _fetchData();
                        print(
                            'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}');
                        print('Selected Shift: $selectedShift');
                        // print('Selected Place: $tempat');
                        // print('Selected Materi: $pembahasanMateri');
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
                          Text('Tempat: ${tempat ?? ''}'),
                          const SizedBox(height: 4.0),
                          Text('Pembahasan Materi:\n${materi ?? ''}'),
                          const SizedBox(height: 4.0),
                          const Text('Peserta dan Jabatan:'),
                          Center(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('No.')),
                                DataColumn(label: Text('Peserta')),
                                DataColumn(label: Text('Jabatan')),
                              ],
                              rows: peserta
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => DataRow(
                                      cells: [
                                        DataCell(Text(
                                            '${entry.key + 1}')), // Nomor baris
                                        DataCell(
                                            Text(entry.value['nama_peserta'])),
                                        DataCell(Text(entry.value['jabatan'])),
                                      ],
                                    ),
                                  )
                                  .toList(),
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
