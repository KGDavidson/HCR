import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences prefs;
Map<String, List<dynamic>> savedComicsData;
Map<String, List<String>> searchItems = <String, List<String>>{};

String currentSearchPageSearchString = "";
String currentLibraryPageSearchString = "";

String singleComicHref;
List<String> issueHrefs;
String singleComicName;
int singleIssue;
