import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';
import 'global_static.dart';
import 'search_page.dart';
import 'discover_page.dart';
import 'library_page.dart';

List<bool> sortOrder = [true, false];

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Husk Comic Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>{
  @override
  void initState() {
    super.initState();
    getPrefs();
  }

  getPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return (
        SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [MAIN_COLOUR_1, MAIN_COLOUR_2]
              ),
            ),
            child: DefaultTabController(
              length: 3,
              child:  Scaffold(
                backgroundColor: TRANSPARENT,
                bottomNavigationBar: Container(
                  color: MAIN_COLOUR_2,
                  child: TabBar(
                    labelColor: PRIMARY_WHITE,
                    unselectedLabelColor: SECONDARY_WHITE,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: MAIN_COLOUR_1,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.local_library_rounded),
                      ),
                      Tab(
                        icon: Icon(Icons.search),
                      ),
                      Tab(
                        icon: Icon(Icons.explore),
                      ),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    LibraryPage(),
                    SearchPage(),
                    DiscoverPage(),
                  ],
                ),
              ),
            )
          ),
        )
    );
  }
}