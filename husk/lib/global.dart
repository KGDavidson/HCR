import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences prefs;
Map<String, List<dynamic>> savedComicsData;
Map<String, List<String>> searchItems = <String, List<String>>{};
Map<String, List<String>> newReleasesItems = <String, List<String>>{};
Map<String, List<String>> mostPopularItems = <String, List<String>>{};
Map<String, List<String>> latestUpdatedItems = <String, List<String>>{};
Map<String, List<String>> topTodayItems = <String, List<String>>{};
Map<String, List<String>> topWeekItems = <String, List<String>>{};
Map<String, List<String>> topMonthItems = <String, List<String>>{};

String currentSearchPageSearchString = "";
String currentLibraryPageSearchString = "";

String singleComicHref;
List<String> issueHrefs;
String singleComicName;
int singleIssue;
