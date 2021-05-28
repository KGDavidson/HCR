import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapping_page_scroll/snapping_page_scroll.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
//import 'package:flutter/rendering.dart';

List<Widget> emptyLibrary = <Widget>[
  Container(
    padding: EdgeInsets.fromLTRB(10,10,10,0),
    height: 150,
    width: double.maxFinite,
    child: Card(
      elevation: 5,
      child: InkWell(
        splashFactory: InkRipple.splashFactory,
        child: Container(
          margin: EdgeInsets.fromLTRB(10,10,10,10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(20,0,0,0),
                        child: Text(
                          "Search and favourite your comics!",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.topLeft,
                        margin: EdgeInsets.fromLTRB(20,0,0,0),
                        child: Text(
                          "Pull down to refresh...",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    ),
  ),
];

const Map<String, String> HEADERS = <String, String>{
  'user-agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
  'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
  'authority': 'readcomiconline.li',
  'pragma': 'no-cache',
  'cache-control': 'no-cache',
  'sec-ch-ua': '" Not;A Brand";v="99", "Google Chrome";v="91", "Chromium";v="91"',
  'sec-ch-ua-mobile': '?0',
  'upgrade-insecure-requests': '1',
  'sec-fetch-site': 'same-origin',
  'sec-fetch-mode': 'no-cors',
  'sec-fetch-user': '?1',
  'sec-fetch-dest': 'image',
  'referer': 'https://readcomiconline.li/',
  'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
  'Referer': 'https://readcomiconline.li/',
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36',
};
const Duration animationDuration = Duration(milliseconds: 200);

String searchString;
String singleComicHref;
List<String> issueHrefs;
String singleComicName;
int singleIssue;

List<bool> sortOrder = [true, false];

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //debugPaintSizeEnabled = true;
    return MaterialApp(
      title: 'Husk Comic Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LibraryPage(),
    );
  }
}

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class SingleComicPage extends StatefulWidget {
  @override
  _SingleComicPageState createState() => _SingleComicPageState();
}

class Reader extends StatefulWidget {
  @override
  _ReaderState createState() => _ReaderState();
}

Route animatePage(page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset(1.0, 0.0);
      var end = Offset.zero;
      var curve = Curves.ease;

      var tween = Tween(begin: begin, end: end);
      var curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: curve,
      );

      return SlideTransition(
        position: tween.animate(curvedAnimation),
        child: child,
      );
    },
  );
}

class _LibraryPageState extends State<LibraryPage> {
  List<Widget> libraryItems = <Widget>[];

  bool loading = false;
  bool error = false;

  RefreshController refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    library();
  }

  Future library() async {
    setState(() {
      loading = true;
      error = false;
    });
    final prefs = await SharedPreferences.getInstance();
    String savedComics;
    savedComics = prefs.getString("saved");
    if (savedComics != null) {
      Map<String, List<dynamic>> savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
      if (savedComicsData.entries.length > 0) {
        libraryItems = [];
        for (MapEntry<String, List<dynamic>> comic in savedComicsData.entries) {
          String comicName = comic.key;
          String imageUrl = comic.value[0];
          String description = comic.value[1];
          String comicHref = comic.value[2];
          libraryItems.add(
            Container(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              height: 150,
              width: double.maxFinite,
              child: Card(
                elevation: 5,
                child: InkWell(
                  splashFactory: InkRipple.splashFactory,
                  onTap: () {
                    singleComicHref = comicHref;
                    Navigator.of(context).push(animatePage(SingleComicPage()));
                  },
                  child: Container(
                    margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 5,
                              )
                          ),
                          height: double.maxFinite,
                          child: FadeInImage.assetNetwork(
                              placeholder: 'assets/loading.png',
                              image: imageUrl
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
                                  child: Text(
                                    comicName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  alignment: Alignment.topLeft,
                                  margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
                                  child: Text(
                                    description,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      } else {
        libraryItems = emptyLibrary;
      }
    } else {
      libraryItems = emptyLibrary;
    }
    setState(() {
      loading = false;
      error = false;
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xffFF99DF), Color(0xff00C8F0)])
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (overscroll) {
                  overscroll.disallowGlow();
                  return;
                },
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 60,
                        margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
                        width: double.maxFinite,
                        child: TextField(
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            searchString = value;
                            Navigator.of(context).push(animatePage(SearchPage()));
                          },
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(100)),
                              borderSide:  BorderSide(color: Colors.black, width: 5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(100)),
                              borderSide:  BorderSide(color: Colors.black, width: 5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(100)),
                              borderSide:  BorderSide(color: Colors.black, width: 5),
                            ),
                            contentPadding: EdgeInsets.all(20),
                            hintText: 'Search ...',
                            hasFloatingPlaceholder: false,
                          ),
                        ),
                      ),
                      loading ? Center(
                        child: CircularProgressIndicator(),
                      ) : error ? Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.pink,
                            size: 50.0,
                            semanticLabel: 'Error loading search results',
                          )
                      ) : Container(
                        height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 80,
                        child: SmartRefresher(
                          controller: refreshController,
                          enablePullDown: true,
                          header: MaterialClassicHeader(),
                          onRefresh: () async {
                            await library();
                            refreshController.refreshCompleted();
                          },
                          child: ListView (
                            children: libraryItems,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
    );
  }
}

class _SearchPageState extends State<SearchPage> {
  List<Widget> searchResults = <Widget>[];

  bool loading = false;
  bool error = false;

  @override
  void initState() {
    super.initState();
    search();
  }

  void search() async {
    setState(() {
      loading = true;
      error = false;
    });
    var uri = Uri.parse("https://readcomiconline.li/Search/Comic");
    var formData = new Map<String, dynamic>();
    formData['keyword'] = searchString;

    final response = await http.post(uri, headers: HEADERS, body: formData);
    if (response.statusCode == 200) {
      List<dom.Element> comics = html.parse(response.body).getElementsByClassName("listing")[0].getElementsByTagName("tr");
      comics.removeAt(0);
      comics.removeAt(0);

      for (int i = 0; i < comics.length; i++){
        dom.Element comic = comics[i];
        String titleHTML = comic.children[0].attributes['title'];
        dom.Document title = html.parse(titleHTML);

        String comicName = comic.children[0].getElementsByTagName("a")[0].text.trim();
        String comicHref = "https://readcomiconline.li" + comic.children[0].getElementsByTagName("a")[0].attributes["href"];
        String latestIssue = comic.children[1].text.replaceAll("Issue ", "").replaceAll("Completed", "//").trim();
        String description = title.getElementsByTagName("p")[0].text.replaceAll("...", "").replaceAll("N/a", "...").trim();
        String imgSrc = title.getElementsByTagName("img")[0].attributes['src'];
        String imageUrl;
        if (imgSrc.contains("http")){
          imageUrl = imgSrc;
        } else {
          imageUrl = "https://readcomiconline.li" + imgSrc;
        }
        searchResults.add(
          Container(
            padding: EdgeInsets.fromLTRB(10,10,10,0),
            height: 150,
            width: double.maxFinite,
            child: Card(
              elevation: 5,
              child: InkWell(
                splashFactory: InkRipple.splashFactory,
                onTap: () {
                  singleComicHref = comicHref;
                  Navigator.of(context).push(animatePage(SingleComicPage()));
                },
                child: Container(
                  margin: EdgeInsets.fromLTRB(10,10,10,10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 5,
                              )
                          ),
                          height: double.maxFinite,
                          child: Stack (
                            children: <Widget>[
                              FadeInImage.assetNetwork(
                                  placeholder: 'assets/loading.png',
                                  image: imageUrl
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(1,1,4,4),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                ),
                                child: Text(
                                  latestIssue,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                alignment: Alignment.centerLeft,
                                margin: EdgeInsets.fromLTRB(20,0,0,0),
                                child: Text(
                                  comicName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.topLeft,
                                margin: EdgeInsets.fromLTRB(20,0,0,0),
                                child: Text(
                                  description,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
      setState(() {
        loading = false;
        error = false;
      });
    } else {
      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xffFF99DF), Color(0xff00C8F0)])
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 8) {
                    Navigator.of(context).pop(this);
                  }
                },
                child: Container(
                  height: double.maxFinite,
                  child: loading ? Center(
                    child: CircularProgressIndicator(),
                  ) : error ? Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.pink,
                        size: 50.0,
                        semanticLabel: 'Error loading search results',
                      )
                  ) : SingleChildScrollView(
                    child: Column (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: searchResults,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
    );
  }
}

class _SingleComicPageState extends State<SingleComicPage> {
  List<bool> issuesRead = <bool>[];
  List<dom.Element> issues;

  String publisher;
  String writer;
  String artist;
  String pubDate;
  String imageUrl;
  String summary;

  bool loading = false;
  bool error = false;

  bool singleComicSaved = false;
  bool reversedList = false;
  bool showRead = false;
  bool showDownloaded = false;

  @override
  void initState() {
    super.initState();
    loadComic();
  }

  void loadComic() async {
    setState(() {
      loading = true;
      error = false;
    });

    var formData = new Map<String, dynamic>();
    final response = await http.post(Uri.parse(singleComicHref), headers: HEADERS, body: formData);
    if (response.statusCode == 200) {
      dom.Document doc = html.parse(response.body);
      issues = doc.getElementsByClassName("listing")[0].getElementsByTagName("tr");
      issues.removeAt(0);
      issues.removeAt(0);
      dom.Element infoSection = doc.getElementById("leftside").getElementsByClassName("barContent")[0];
      singleComicName = infoSection.getElementsByClassName("bigChar")[0].text;
      List<dom.Element> infos = infoSection.getElementsByTagName("p");
      publisher = "-";
      writer = "-";
      artist = "-";
      pubDate = "-";
      summary = "-";
      for (dom.Element info in infos){
        try {
          switch (info.getElementsByTagName("span")[0].text) {
            case "Publisher:":
              try {
                publisher = info.getElementsByTagName("a")[0].text.trim();
              } catch (e) {}
              break;
            case "Writer:":
              try {
                writer = info.getElementsByTagName("a")[0].text.trim();
              } catch (e) {}
              break;
            case "Artist:":
              try {
                artist = info.getElementsByTagName("a")[0].text.trim();
              } catch (e) {}
              break;
            case "Publication date:":
              try {
                pubDate = info.text.replaceAll("Publication date:", "").trim();
              } catch (e) {}
              break;
          }
        } catch (e){}
      }
      summary = infos.elementAt(infos.length - 2).text;
      String imgSrc = doc.getElementById("rightside").getElementsByClassName("rightBox")[0].getElementsByTagName("img")[0].attributes['src'];
      imageUrl;
      if (imgSrc.contains("http")){
        imageUrl = imgSrc;
      } else {
        imageUrl = "https://readcomiconline.li" + imgSrc;
      }

      issueHrefs = [];

      issues = issues.reversed.toList();
      issuesRead = List<bool>.filled(issues.length, false);

      final prefs = await SharedPreferences.getInstance();
      String savedComics;
      savedComics = prefs.getString("saved");
      singleComicSaved = false;
      if (savedComics != null) {
        Map<String, List<dynamic>> savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
        if (savedComicsData.containsKey(singleComicName)) {
          singleComicSaved = true;
          if (savedComicsData[singleComicName].length < 4) {
            savedComicsData[singleComicName].add(Map<String, int>());
            savedComicsData[singleComicName][3][singleIssue.toString()] = 0;
          } else {
            Map<String, dynamic> issuesProgress = savedComicsData[singleComicName][3];

            for (MapEntry<String, dynamic> issueProgress in issuesProgress.entries) {
              int issueNumber = int.parse(issueProgress.key);
              if (issueProgress.value == -1) {
                issuesRead[issueNumber] = true;
              }
            }
          }
        }
      }
      setState(() {
        loading = false;
        error = false;
      });
    } else {
      setState(() {
        loading = false;
        error = true;
      });
    }
    setState(() {});
  }

  List<Widget> buildIssuesList(){
    List<Widget> singleComicResults = <Widget>[];
    for (dom.Element issue in issues) {
      String issueNumber;
      try {
        issueNumber = issue.getElementsByTagName("td")[0].text.split("#")[1].trim();
      } catch (e) {
        issueNumber = issue.getElementsByTagName("td")[0].text.trim();
      }
      String issueDate = issue.getElementsByTagName("td")[1].text.trim();
      String issueHref = issue.getElementsByTagName("td")[0].getElementsByTagName("a")[0].attributes["href"];
      issueHrefs.add(issueHref);
      if (showRead | !issuesRead[issueHrefs.indexOf(issueHref)]) {
        singleComicResults.add(
          Container(
            padding: EdgeInsets.fromLTRB(10, 2, 10, 0),
            height: 70,
            width: double.maxFinite,
            child: Card(
                elevation: 5,
                child: InkWell(
                  onTap: () {
                    singleIssue = issueHrefs.indexOf(issueHref);
                    Navigator.of(context).push(animatePage(Reader()));
                  },
                  splashFactory: InkRipple.splashFactory,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                issueDate,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              VerticalDivider(),
                              Flexible(
                                child: Text(
                                  "#" + issueNumber,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            IconButton(
                                onPressed: () {

                                },
                                icon: Icon(
                                  Icons.download,
                                  color: Colors.blueGrey,
                                )
                            ),
                            IconButton(
                                onPressed: () async {
                                  issuesRead[issueHrefs.indexOf(issueHref)] =
                                  !issuesRead[issueHrefs.indexOf(issueHref)];
                                  final prefs = await SharedPreferences
                                      .getInstance();
                                  String savedComics;
                                  savedComics = prefs.getString("saved");
                                  singleComicSaved = false;
                                  if (savedComics != null) {
                                    Map<String,
                                        List<dynamic>> savedComicsData = Map<
                                        String,
                                        List<dynamic>>.from(
                                        json.decode(savedComics));
                                    if (savedComicsData.containsKey(
                                        singleComicName)) {
                                      singleComicSaved = true;
                                      if (savedComicsData[singleComicName]
                                          .length < 4) {
                                        savedComicsData[singleComicName].add(
                                            Map<String, int>());
                                        savedComicsData[singleComicName][3][singleIssue
                                            .toString()] = 0;
                                      } else {
                                        Map<String,
                                            dynamic> issuesProgress = savedComicsData[singleComicName][3];
                                        int issueNumber = issueHrefs.indexOf(
                                            issueHref);
                                        if (issuesRead[issueNumber]) {
                                          issuesProgress[issueNumber
                                              .toString()] = -1;
                                        } else {
                                          issuesProgress[issueNumber
                                              .toString()] = 0;
                                        }
                                      }
                                    }
                                    prefs.setString(
                                        "saved", jsonEncode(savedComicsData));
                                  }
                                  setState(() {});
                                },
                                icon: issuesRead[issueHrefs.indexOf(issueHref)]
                                    ? Icon(
                                  Icons.album,
                                  color: Color(0xff00c8f0),
                                )
                                    : Icon(
                                  Icons.adjust,
                                  color: Colors.blueGrey,
                                )
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                )
            ),
          ),
        );
      }
    }
    if (reversedList) {
      singleComicResults = singleComicResults.reversed.toList();
    }
    return singleComicResults;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xffFF99DF), Color(0xff00C8F0)])
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 8) {
                  Navigator.of(context).pop(this);
                }
              },
              child: Container(
                height: double.maxFinite,
                child:loading ? Center(
                  child: CircularProgressIndicator(),
                ) : error ? Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.pink,
                      size: 50.0,
                      semanticLabel: 'Error loading search results',
                    )
                ) : SingleChildScrollView(
                  child: Column (
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.fromLTRB(10,10,10,5),
                        width: double.maxFinite,
                        child: Card(
                          elevation: 5,
                          child: Stack(
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  Container(
                                    height: 170,
                                    margin: EdgeInsets.fromLTRB(10,10,10,10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[
                                        Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 5,
                                              )
                                          ),
                                          height: double.maxFinite,
                                          child: FadeInImage.assetNetwork(
                                              placeholder: 'assets/loading.png',
                                              image: imageUrl
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: <Widget>[
                                              Expanded(
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  margin: EdgeInsets.fromLTRB(20,20,20,20),
                                                  child: Text(
                                                    singleComicName,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 22,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  alignment: Alignment.topLeft,
                                                  margin: EdgeInsets.fromLTRB(20,0,20,0),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: <Widget>[
                                                      Text(
                                                        publisher,
                                                        overflow: TextOverflow.ellipsis,
                                                        textAlign: TextAlign.left,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Text(
                                                        writer,
                                                        overflow: TextOverflow.ellipsis,
                                                        textAlign: TextAlign.left,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Text(
                                                        artist,
                                                        overflow: TextOverflow.ellipsis,
                                                        textAlign: TextAlign.left,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Text(
                                                        pubDate,
                                                        overflow: TextOverflow.ellipsis,
                                                        textAlign: TextAlign.left,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 50,
                                    margin: EdgeInsets.fromLTRB(10,0,10,10),
                                    child: Text(
                                      summary,
                                    ),
                                  )
                                ],
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                    onPressed: () async {
                                      List<dynamic> comicData = [
                                        imageUrl,
                                        summary,
                                        singleComicHref,
                                      ];

                                      final prefs = await SharedPreferences.getInstance();
                                      String savedComics = prefs.getString("saved");
                                      Map<String, dynamic> savedComicsData;
                                      try{
                                         savedComicsData = json.decode(savedComics);
                                      } catch (e) {print(e);}

                                      if (savedComicsData == null){
                                        savedComicsData = <String, List<dynamic>>{};
                                      }
                                      if (singleComicSaved){
                                        savedComicsData.remove(singleComicName);
                                      } else {
                                        savedComicsData[singleComicName] = comicData;
                                      }
                                      prefs.setString('saved', json.encode(savedComicsData));
                                      singleComicSaved = !singleComicSaved;
                                      setState(() {});
                                    },
                                    icon: singleComicSaved ? Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ) : Icon(
                                      Icons.favorite_border,
                                      color: Colors.red,
                                    )
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(10,2,10,0),
                        height: 70,
                        width: double.maxFinite,
                        child: Card(
                          elevation: 5,
                          child: Container(
                            margin: EdgeInsets.fromLTRB(10,10,10,10),
                            padding: EdgeInsets.fromLTRB(10,0,10,0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                ElevatedButton(
                                  onPressed: () {

                                  },
                                  child: Text("Download All"),
                                  style: ElevatedButton.styleFrom(
                                      primary: Color(0xff00c8f0),
                                      side: BorderSide(
                                          width: 1.5,
                                          color: Colors.black
                                      )
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    IconButton(
                                      onPressed: (){
                                        reversedList = !reversedList;
                                        setState(() {});
                                      },
                                      icon: reversedList ? Icon(Icons.keyboard_arrow_up) : Icon(Icons.keyboard_arrow_down),
                                    ),
                                    IconButton(
                                      onPressed: (){
                                        showDownloaded = !showDownloaded;
                                        setState(() {});
                                      },
                                      icon: showDownloaded ? Icon(Icons.download, color: Color(0xff00c8f0),) : Icon(Icons.download, color: Colors.blueGrey),
                                    ),
                                    IconButton(
                                      onPressed: (){
                                        showRead = !showRead;
                                        setState(() {});
                                      },
                                      icon: showRead ? Icon(Icons.album, color: Color(0xff00c8f0),) : Icon(Icons.adjust, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: buildIssuesList(),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
    );
  }
}

class _ReaderState extends State<Reader> {
  PageController controller = PageController(viewportFraction: 0.99);
  RefreshController swipeController = RefreshController(initialRefresh: false);
  int _currentPage = 0;
  int t;
  double p;

  List<Widget> pages = <Widget>[];

  bool loading = false;
  bool error = false;

  @override
  void initState() {
    super.initState();
    reader();
  }

  void reader() async {
    final prefs = await SharedPreferences.getInstance();
    String savedComics;
    savedComics = prefs.getString("saved");
    if (savedComics != null) {
      Map<String, List<dynamic>> savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
      if (savedComicsData[singleComicName].length < 4) {
        savedComicsData[singleComicName].add(Map<String, int>());
        savedComicsData[singleComicName][3][singleIssue.toString()] = 0;
      } else {
        int initPage = (savedComicsData[singleComicName][3][singleIssue.toString()]);
        if (initPage != null){
          controller = PageController(viewportFraction: 0.99, initialPage: initPage);
        }
      }
    }

    setState(() {
      loading = true;
      error = false;
    });

    var formData = new Map<String, dynamic>();
    final response = await http.post(Uri.parse("https://readcomiconline.li/" + issueHrefs[singleIssue] + "&quality=hq"), headers: HEADERS, body: formData);
    if (response.statusCode == 200){
      String html = response.body;
      String pagesJS = html.split("var lstImages = new Array();")[1].split("var currImage = 0;")[0];
      pages = [];
      List<String> pageSplit = pagesJS.split('lstImages.push("');
      for (String page in pageSplit){
        String pageUrl = page.split('"')[0];
        if (Uri.parse(pageUrl).isAbsolute) {
          pages.add(
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    InteractiveViewer(
                      child: FadeInImage.assetNetwork(
                        image: pageUrl,
                        placeholder: 'assets/loading.png',
                      ),
                    ),
                    Text(
                      (pageSplit.indexOf(page)).toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    )
                  ],
                ),
              )
          );
        }
      }
      setState(() {
        loading = false;
        error = false;
      });
    }else {
      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  Future savePage(pageNum) async {
    final prefs = await SharedPreferences.getInstance();
    String savedComics;
    savedComics = prefs.getString("saved");
    if (savedComics != null) {
      Map<String, List<dynamic>> savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
      if (savedComicsData[singleComicName].length < 4) {
        savedComicsData[singleComicName].add(Map<String, int>());
      }
      savedComicsData[singleComicName][3][singleIssue.toString()] = pageNum;
      prefs.setString("saved", json.encode(savedComicsData));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return loading ? Center(
      child: CircularProgressIndicator(),
    ) : error ? Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.pink,
          size: 50.0,
          semanticLabel: 'Error loading search results',
        )
    ) : Listener(
      onPointerMove: (pos) async { //Get pointer position when pointer moves
        //If time since last scroll is undefined or over 100 milliseconds
        if (t == null || DateTime.now().millisecondsSinceEpoch - t > 100) {
          t = DateTime.now().millisecondsSinceEpoch;
          p = pos.position.dy; //x position
        } else {
          //Calculate velocity
          double v = (p - pos.position.dy) / (DateTime.now().millisecondsSinceEpoch - t);
          if (v < -3 || v > 2) {
            _currentPage = controller.page.toInt();
            await controller.animateToPage(_currentPage + (v * 0.5).round(),duration: Duration(milliseconds: 800), curve: Curves.easeOutCubic);
          } else {
            _currentPage = controller.page.toInt();
            await controller.animateToPage(_currentPage + ((v/v.abs())).round(), duration: Duration(milliseconds: 800), curve: Curves.easeOutCubic);
          }
        }
        if(controller.page.toInt() == pages.length - 1) {
          await savePage(-1);
        } else {
          print(controller.page.toInt());
          await savePage(controller.page.toInt());
        }
      },
      child: SmartRefresher(
        controller: swipeController,
        enablePullDown: true,
        enablePullUp: true,
        onRefresh: () async {
          print("not");
          if (singleIssue >= 1 && singleIssue < issueHrefs.length){
            singleIssue -= 1;
            reader();
          }
          swipeController.refreshCompleted();
        },
        onLoading: () async {
          await savePage(-1);
          if (singleIssue >= 0 && singleIssue < issueHrefs.length - 1){
            singleIssue += 1;
            reader();
          }
          swipeController.loadComplete();
        },
        child: CustomScrollView(
          controller: controller,
          physics: NeverScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                  return pages[index];
                },
                childCount: pages.length,
              ),
            ),
          ]
        ),
      ),
    );
  }
}