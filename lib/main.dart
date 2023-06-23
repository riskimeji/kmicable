import 'package:flutter/material.dart';
import 'package:kmicable/auth/login.dart';
import 'package:kmicable/dashbord/dashboard.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final SharedPreferences prefs = await SharedPreferences.getInstance();
//   // var id = '0';
//   var obtainedId = prefs.getString('id');
//   var stateModel = StateModel(obtainedId!);
//   // print(obtainedId);
//   runApp(
//     ChangeNotifierProvider<StateModel>.value(
//       value: stateModel,
//       child: const MyApp(),
//     ),
//   );
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  var obtainedId = prefs.getString('id');
  var stateModel = StateModel(obtainedId ?? '0'); // Add null check here
  runApp(
    ChangeNotifierProvider<StateModel>.value(
      value: stateModel,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return Consumer<StateModel>(
      builder: (context, stateModel, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: stateModel.ids != '0' ? const Dashboard() : const LoginPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class StateModel with ChangeNotifier {
  String ids;

  StateModel(this.ids);

  void updateIds(String newIds) {
    ids = newIds;
    notifyListeners();
  }
}
