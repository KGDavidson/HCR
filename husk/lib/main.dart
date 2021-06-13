import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:path_provider/path_provider.dart';
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
  SharedPreferences prefs;
  List<Widget> libraryItems = <Widget>[];
  ScrollController listController = ScrollController();
  Map<String, List<dynamic>> savedComicsData;

  bool loading = true;
  bool error = false;

  bool showRead = false;
  bool reversedList = false;

  RefreshController refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    library();
  }

  Future library() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      loading = true;
      error = false;
    });
    String savedComics;
    savedComics = prefs.getString("saved");
    if (savedComics != null) {
      savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
    } else {
      libraryItems = emptyLibrary;
    }
    setState(() {
      loading = false;
      error = false;
    });
    return;
  }

  List<Widget> buildLibraryItems() {
    libraryItems = emptyLibrary;
    String savedComics;
    savedComics = prefs.getString("saved");
    Map<String, List<dynamic>> savedComicsData;
    if (savedComics != null) {
      savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
    }
    if (savedComicsData != null && savedComicsData.entries.length > 0) {
      libraryItems = [];
      for (MapEntry<String, List<dynamic>> comic in savedComicsData.entries) {
        String comicName = comic.key;
        String imageUrl = comic.value[0];
        String description = comic.value[1];
        String comicHref = comic.value[2];
        bool unread = true;
        if (savedComicsData[comicName].length >= 4) {
          unread = false;
          savedComicsData[comicName][3].values.forEach((value) {
            if (value != -1) {
              unread = true;
            }
          });
        }
        if (unread | showRead) {
          libraryItems.add(
            Container(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              height: 150,
              width: double.maxFinite,
              child: Card(
                  elevation: 5,
                  child: Stack(
                    children: <Widget>[
                      InkWell(
                        splashFactory: InkRipple.splashFactory,
                        onTap: () async {
                          singleComicHref = comicHref;
                          List<dynamic> currentComic = savedComicsData[comicName];
                          savedComicsData.remove(comicName);
                          savedComicsData[comicName] = currentComic;
                          prefs.setString("saved", json.encode(savedComicsData));
                          await Navigator.of(context).push(animatePage(SingleComicPage()));
                          library();
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
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                            onPressed: () async {
                              List<dynamic> comicData = [
                                imageUrl,
                                description,
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
                              savedComicsData.remove(comicName);
                              prefs.setString('saved', json.encode(savedComicsData));
                              library();
                            },
                            icon: Icon(
                              Icons.favorite,
                              color: Colors.red,
                            )
                        ),
                      )
                    ],
                  )
              ),
            ),
          );
        }
      }
    } else {
      libraryItems = emptyLibrary;
    }
    if (!reversedList){
      libraryItems = libraryItems.reversed.toList();
    }
    return libraryItems;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: 60,
                              margin: EdgeInsets.fromLTRB(20, 10, 0, 0),
                              child: TextField(
                                textInputAction: TextInputAction.search,
                                onSubmitted: (value) async {
                                  searchString = value;
                                  await Navigator.of(context).push(animatePage(SearchPage()));
                                  library();
                                },
                                decoration: InputDecoration(
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(100)),
                                    borderSide:  BorderSide(color: Colors.blueGrey, width: 5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(100)),
                                    borderSide:  BorderSide(color: Colors.blueGrey, width: 5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(100)),
                                    borderSide:  BorderSide(color: Colors.blueGrey, width: 5),
                                  ),
                                  contentPadding: EdgeInsets.all(20),
                                  hintText: 'Search ...',
                                  hasFloatingPlaceholder: false,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(10,10,10,0),
                            height: 70,
                            child: Card(
                              elevation: 5,
                              child: Container(
                                margin: EdgeInsets.fromLTRB(0,7,0,7),
                                padding: EdgeInsets.fromLTRB(10,0,10,0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      padding: EdgeInsets.all(0),
                                      onPressed: (){
                                        reversedList = !reversedList;
                                        setState(() {});
                                      },
                                      icon: !reversedList ? Stack(
                                            children: <Widget>[
                                              Positioned(
                                                  top: 0,
                                                  left: 5,
                                                  right: 5,
                                                  child: Icon(
                                                    Icons.keyboard_arrow_up,
                                                    color: Color(0xff00c8f0),
                                                  )
                                              ),
                                              Positioned(
                                                  bottom: 0,
                                                  left: 5,
                                                  right: 5,
                                                  child: Icon(
                                                    Icons.keyboard_arrow_down,
                                                    color: Colors.blueGrey,
                                                  )
                                              )
                                            ],
                                          ) : Stack(
                                        children: <Widget>[
                                          Positioned(
                                              top: 0,
                                              left: 5,
                                              right: 5,
                                              child: Icon(
                                                Icons.keyboard_arrow_up,
                                                color: Colors.blueGrey,
                                              )
                                          ),
                                          Positioned(
                                              bottom: 0,
                                              left: 5,
                                              right: 5,
                                              child: Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Color(0xff00c8f0),
                                              )
                                          )
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showRead = !showRead;
                                        setState(() {});
                                        listController.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeOutCubic);
                                      },
                                      icon: showRead ? Icon(Icons.album, color: Color(0xff00c8f0),) : Icon(Icons.adjust, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading ? Center(
                        child: CircularProgressIndicator(color: Color(0xffff99df),),
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
                            controller: listController,
                            children: buildLibraryItems(),
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
  SharedPreferences prefs;

  Map<String, List<String>> searchItems = <String, List<String>>{};
  List<Widget> searchResults = <Widget>[];
  Map<String, bool> searchItemsSaved = <String, bool>{};

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

    prefs = await SharedPreferences.getInstance();

    var uri = Uri.parse("https://readcomiconline.li/Search/Comic");
    var formData = new Map<String, dynamic>();
    formData['keyword'] = searchString;

    final response = await http.post(uri, headers: HEADERS, body: formData);
    if (response.statusCode == 200 && html.parse(response.body).getElementsByClassName("listing").length > 0) {
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

        searchItems[comicName] = <String>[
          imageUrl,
          description,
          comicHref,
          latestIssue,
        ];

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

  void buildListPart(Map<String, dynamic> map, bool saved) {
    for (MapEntry<String, dynamic> searchItem in map.entries) {
      String comicName = searchItem.key;
      String comicHref = searchItem.value[2];
      String latestIssue = searchItem.value[3];
      String description = searchItem.value[1];
      String imageUrl = searchItem.value[0];
      print(comicName);
      print(comicHref);
      searchItemsSaved[comicName] = saved;
      searchResults.add(
        Container(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
          height: 150,
          width: double.maxFinite,
          child: Card(
              elevation: 5,
              child: Stack(
                children: <Widget>[
                  InkWell(
                    splashFactory: InkRipple.splashFactory,
                    onTap: () {
                      singleComicHref = comicHref;
                      Navigator.of(context).push(
                          animatePage(SingleComicPage()));
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
                              child: Stack(
                                children: <Widget>[
                                  FadeInImage.assetNetwork(
                                      placeholder: 'assets/loading.png',
                                      image: imageUrl
                                  ),
                                  Container(
                                    width: 50,
                                    padding: EdgeInsets.fromLTRB(1, 1, 4, 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                    ),
                                    child: Text(
                                      latestIssue,
                                      overflow: TextOverflow.ellipsis,
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
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                        onPressed: () async {
                          List<dynamic> comicData = [
                            imageUrl,
                            description,
                            comicHref,
                          ];

                          final prefs = await SharedPreferences.getInstance();
                          String savedComics = prefs.getString("saved");
                          Map<String, dynamic> savedComicsData;
                          try {
                            savedComicsData = json.decode(savedComics);
                          } catch (e) {
                            print(e);
                          }

                          if (savedComicsData == null) {
                            savedComicsData = <String, List<dynamic>>{};
                          }
                          if (searchItemsSaved[comicName]) {
                            savedComicsData.remove(comicName);
                          } else {
                            savedComicsData[comicName] = comicData;
                          }
                          prefs.setString('saved', json.encode(savedComicsData));
                          searchItemsSaved[comicName] = !searchItemsSaved[comicName];
                          setState(() {});
                        },
                        icon: searchItemsSaved[comicName] ? Icon(
                          Icons.favorite,
                          color: Colors.red,
                        ) : Icon(
                          Icons.favorite_border,
                          color: Colors.red,
                        )
                    ),
                  )
                ],
              )
          ),
        ),
      );
    }
  }

  List<Widget> buildSearchResultsList() {
    String savedComics = prefs.getString("saved");
    Map<String, dynamic> savedComicsData;
    try {
      savedComicsData = json.decode(savedComics);
    } catch (e) {
      print(e);
    }

    if (savedComicsData == null) {
      savedComicsData = <String, List<dynamic>>{};
    }
    searchResults = <Widget>[];
    Map<String, dynamic> savedComicsDataCopy = Map.from(savedComicsData);
    Map<String, dynamic> searchItemsCopy = Map.from(searchItems);
    savedComicsData.removeWhere((key, value) {
      if (searchItems.containsKey(key)) {
        if (savedComicsData[key].length < 4) {
          savedComicsData[key].add(searchItems[key][3]);
        } else {
          savedComicsData[key][3] = searchItems[key][3];
        }
        return false;
      }
      return true;
    });
    searchItemsCopy.removeWhere((key, value) {
      if (savedComicsDataCopy.containsKey(key)){
        return true;
      }
      return false;
    });
    buildListPart(savedComicsData, true);
    buildListPart(searchItemsCopy, false);
    return searchResults;
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
                    child: CircularProgressIndicator(color: Color(0xffff99df),),
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
                      children: buildSearchResultsList(),
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
  SharedPreferences prefs;

  List<bool> issuesRead = <bool>[];
  List<bool> issuesDownloading = <bool>[];
  List<bool> issuesDownloaded = <bool>[];
  List<Icon> issuesDownloadIcon = <Icon>[];
  List<dom.Element> issues;

  String publisher;
  String writer;
  String artist;
  String pubDate;
  String imageUrl;
  String summary;

  String resumeHref;

  bool loading = true;
  bool error = false;

  bool singleComicSaved = false;
  bool reversedList = false;
  bool showRead = false;
  bool showDownloaded = false;

  RefreshController refreshController = RefreshController(initialRefresh: false);
  ScrollController listController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadComic();
  }

  void loadComic() async {
    prefs = await SharedPreferences.getInstance();

    final response = await http.get(Uri.parse(singleComicHref), headers: HEADERS);
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
      issuesDownloading = List<bool>.filled(issues.length, false);
      issuesDownloadIcon = List<Icon>.filled(issues.length, Icon(Icons.download, color: Colors.blueGrey,));
      issuesDownloaded = List<bool>.filled(issues.length, false);

      String savedComics;
      savedComics = prefs.getString("saved");
      singleComicSaved = false;
      if (savedComics != null) {
        Map<String, List<dynamic>> savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
        if (savedComicsData.containsKey(singleComicName)) {
          singleComicSaved = true;
          if (savedComicsData[singleComicName].length < 4) {
            savedComicsData[singleComicName].add(Map<String, int>());
            for (int i = 0; i < issues.length; i++){
              savedComicsData[singleComicName][3][i.toString()] = 0;
            }
          }
          Map<String, dynamic> issuesProgress = savedComicsData[singleComicName][3];

          for (MapEntry<String, dynamic> issueProgress in issuesProgress.entries) {
            int issueNumber = int.parse(issueProgress.key);
            if (issueProgress.value == -1) {
              issuesRead[issueNumber] = true;
            }
          }
          prefs.setString("saved", json.encode(savedComicsData));

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

  /*void delete(issueHref) async {
    final issueNumber = issueHrefs.indexOf(issueHref);
    final directoryPath = directory.path;
    final dir = Directory('$directoryPath/$singleComicName/$issueNumber');
    dir.deleteSync(recursive: true);
    issuesDownloading[issueHrefs.indexOf(issueHref)] = true;
    setState(() {});
    await Future.delayed(Duration(seconds: 1));
    issuesDownloading[issueHrefs.indexOf(issueHref)] = false;
    issuesDownloaded[issueHrefs.indexOf(issueHref)] = false;
    setState(() {});
  }*/

  /*void download(String issueHref) async {
    final response = await http.get(Uri.parse("https://readcomiconline.li/" + issueHref + "&quality=hq"), headers: HEADERS);
    if (response.statusCode == 200){
      try {
        String html = response.body;
        String pagesJS = html.split("var lstImages = new Array();")[1].split("var currImage = 0;")[0];
        List<String> pageSplit = pagesJS.split('lstImages.push("');
        for (int i = 0; i < pageSplit.length; i++) {
          String pageUrl = pageSplit[i].split('"')[0];
          if (Uri.parse(pageUrl).isAbsolute) {
            print(pageUrl);
            final response = await http.get(Uri.parse(pageUrl));
            if (response.contentLength == 0){
              return;
            }
            String directoryPath = directory.path;
            int issueNumber = issueHrefs.indexOf(issueHref);
            File file = await new File('$directoryPath/$singleComicName/$issueNumber/$i.png').create(recursive: true);
            await file.writeAsBytes(response.bodyBytes);
          }
        }

        print(directory.listSync());
        issuesDownloaded[issueHrefs.indexOf(issueHref)] = true;
        issuesDownloading[issueHrefs.indexOf(issueHref)] = false;
        setState(() {});
        return;
      } catch(e) {print(e);}
    }
    print("fail");
    issuesDownloading[issueHrefs.indexOf(issueHref)] = false;
    issuesDownloadIcon[issueHrefs.indexOf(issueHref)] = Icon(Icons.error_outline, color: Colors.red,);
    if (mounted){setState(() {});}
    await Future.delayed(Duration(seconds: 2));
    issuesDownloadIcon[issueHrefs.indexOf(issueHref)] = Icon(Icons.download, color: Colors.blueGrey);
    if (mounted){setState(() {});}

    /*final response = await http.get(Uri.parse("https://2.bp.blogspot.com/ZvwGl14n1bI-tB3OzSi034N6gLlIp5nJKegIlceVY-txW6-4wStSowGB-7bl4qetLD2wHT9h0z6ClzyoXMANSNLGgVHjMo_dKIEPUl0cjMgf-0X84tTMQseJhnEO6VxLTFw7e4yhmQ=s1600"));

    if (response.contentLength == 0){
      return;
    }
    String directoryPath = directory.path;
    File file = new File('$directoryPath/01.png');
    await file.writeAsBytes(response.bodyBytes);*/
  }*/

  List<Widget> buildIssuesList() {
    String savedComics;
    savedComics = prefs.getString("saved");
    singleComicSaved = false;
    if (savedComics != null) {
      Map<String, List<dynamic>> savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
      if (savedComicsData.containsKey(singleComicName)) {
        singleComicSaved = true;
        Map<String, dynamic> issuesProgress = savedComicsData[singleComicName][3];

        for (MapEntry<String, dynamic> issueProgress in issuesProgress.entries) {
          int issueNumber = int.parse(issueProgress.key);
          if (issueProgress.value == -1) {
            issuesRead[issueNumber] = true;
          }
        }
      }
    }
    List<Widget> singleComicResults = <Widget>[];
    bool first = true;
    for (dom.Element issue in reversedList ? issues.reversed.toList() : issues) {
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
        if (first) {
          resumeHref = issue.getElementsByTagName("td")[0].getElementsByTagName("a")[0].attributes["href"];
          first = false;
        }
        singleComicResults.add(
          Container(
            padding: EdgeInsets.fromLTRB(10, 2, 10, 0),
            height: 70,
            width: double.maxFinite,
            child: Card(
                elevation: 5,
                child: InkWell(
                  onTap: () async {
                    singleIssue = issueHrefs.indexOf(issueHref);
                    await Navigator.of(context).push(animatePage(Reader()));
                    setState(() {});
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
                            issuesDownloading[issueHrefs.indexOf(issueHref)] ?
                            Container(
                              padding: EdgeInsets.only(left: 13, right:13),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Color(0xff00c8f0),),
                              )
                            ) :
                            issuesDownloaded[issueHrefs.indexOf(issueHref)] ? IconButton(
                                onPressed: () {
                                  //delete(issueHref);
                                },
                                icon: Icon(Icons.delete_forever, color: Color(0xffFF99DF),)
                            ) : IconButton(
                                onPressed: () {
                                  //issuesDownloading[issueHrefs.indexOf(issueHref)] = true;
                                  //setState(() {});
                                  //download(issueHref);
                                },
                                icon: issuesDownloadIcon[issueHrefs.indexOf(issueHref)]
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
                                    if (savedComicsData.containsKey(singleComicName)) {
                                      singleComicSaved = true;

                                      Map<String,dynamic> issuesProgress = savedComicsData[singleComicName][3];
                                      int issueNumber = issueHrefs.indexOf(issueHref);
                                      if (issuesRead[issueNumber]) {
                                        issuesProgress[issueNumber.toString()] = -1;
                                      } else {
                                        issuesProgress[issueNumber.toString()] = 0;
                                      }
                                      savedComicsData[singleComicName][3] = issuesProgress;
                                    }
                                    prefs.setString("saved", jsonEncode(savedComicsData));
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
                  Navigator.pop(context);
                }
              },
              child: Container(
                height: double.maxFinite,
                child:loading ? Center(
                  child: CircularProgressIndicator(color: Color(0xffff99df),),
                ) : error ? Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.pink,
                      size: 50.0,
                      semanticLabel: 'Error loading search results',
                    )
                ) : Column (
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.fromLTRB(10,10,10,5),
                      width: double.maxFinite,
                      child: Card(
                        elevation: 5,
                        child: InkWell(
                          onTap: () async {
                            singleIssue = issueHrefs.indexOf(resumeHref);
                            await Navigator.of(context).push(animatePage(Reader()));
                            setState(() {});
                          },
                          splashFactory: InkRipple.splashFactory,
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
                        )
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
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  IconButton(
                                    padding: EdgeInsets.all(0),
                                    onPressed: (){
                                      reversedList = !reversedList;
                                      setState(() {});
                                    },
                                    icon: !reversedList ? Stack(
                                      children: <Widget>[
                                        Positioned(
                                            top: 0,
                                            left: 5,
                                            right: 5,
                                            child: Icon(
                                              Icons.keyboard_arrow_up,
                                              color: Color(0xff00c8f0),
                                            )
                                        ),
                                        Positioned(
                                            bottom: 0,
                                            left: 5,
                                            right: 5,
                                            child: Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Colors.blueGrey,
                                            )
                                        )
                                      ],
                                    ) : Stack(
                                      children: <Widget>[
                                        Positioned(
                                            top: 0,
                                            left: 5,
                                            right: 5,
                                            child: Icon(
                                              Icons.keyboard_arrow_up,
                                              color: Colors.blueGrey,
                                            )
                                        ),
                                        Positioned(
                                            bottom: 0,
                                            left: 5,
                                            right: 5,
                                            child: Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Color(0xff00c8f0),
                                            )
                                        )
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showDownloaded = !showDownloaded;
                                      setState(() {});
                                      listController.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeOutCubic);
                                    },
                                    icon: showDownloaded ? Icon(Icons.download, color: Color(0xff00c8f0),) : Icon(Icons.download, color: Colors.blueGrey),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showRead = !showRead;
                                      setState(() {});
                                      listController.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeOutCubic);
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
                    Expanded(
                      child: SmartRefresher(
                        enablePullDown: true,
                        header: MaterialClassicHeader(),
                        controller: refreshController,
                        onRefresh: () async {
                          setState(() {});
                          refreshController.refreshCompleted();
                        },
                        child: ListView(
                          controller: listController,
                          children: buildIssuesList(),
                        )
                      )
                    )
                  ],
                ),
              ),
            ),
          ),
        )
    );
  }
}

class _ReaderState extends State<Reader> with SingleTickerProviderStateMixin {
  PageController controller = PageController(initialPage: 0);
  RefreshController swipeController = RefreshController(initialRefresh: false);
  int _currentPage = 0;
  int t;
  double p;
  int pointerCount = 0;
  AnimationController _controller;

  List<Widget> pages = <Widget>[];

  bool loading = false;
  bool error = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat();
    reader();
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  void reader() async {
    final prefs = await SharedPreferences.getInstance();
    String savedComics;
    savedComics = prefs.getString("saved");
    if (savedComics != null) {
      Map<String, List<dynamic>> savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
      int initPage = (savedComicsData[singleComicName][3][singleIssue.toString()]);
      if (initPage != null){
        controller = PageController(initialPage: initPage);
      } else {
        controller = PageController(initialPage: 0);
      }
    }

    setState(() {
      loading = true;
      error = false;
    });

    final response = await http.get(Uri.parse("https://readcomiconline.li/" + issueHrefs[singleIssue] + "&quality=hq"), headers: HEADERS);
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
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text(
                      (pageSplit.indexOf(page)).toString() + "/" + (pageSplit.length - 1).toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    InteractiveViewer(
                      clipBehavior: Clip.none,
                      child: FadeInImage.assetNetwork(
                        image: pageUrl,
                        placeholder: 'assets/loading.png',
                      ),
                    ),
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
      savedComicsData[singleComicName][3][singleIssue.toString()] = pageNum;
      prefs.setString("saved", json.encode(savedComicsData));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return loading ? Center(
      child: CircularProgressIndicator(color: Color(0xffff99df),),
    ) : error ? Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.pink,
          size: 50.0,
          semanticLabel: 'Error loading search results',
        )
    ) : Listener(
      onPointerDown: (pos) {
        pointerCount += 1;
      },
      onPointerUp: (pos) {
        pointerCount -= 1;
      },
      onPointerMove: (pos) async {
        if (t == null || DateTime.now().millisecondsSinceEpoch - t > 100) {
          t = DateTime.now().millisecondsSinceEpoch;
          p = pos.position.dy; //x position
        } else if (pointerCount == 1) {
          //Calculate velocity
          double v = (p - pos.position.dy) / (DateTime.now().millisecondsSinceEpoch - t);
          if (v < -1 || v > 1) {
            _currentPage = controller.page.toInt();
            await controller.animateToPage(_currentPage + (v * 0.5).round(),duration: Duration(milliseconds: 800), curve: Curves.easeOutCubic);
          }
        }
        if(controller.page.toInt() == pages.length - 1) {
          await savePage(-1);
        } else {
          await savePage(controller.page.toInt());
        }
      },
      child: NotificationListener(
        onNotification: (overscroll) {
          try{overscroll.disallowGlow();} catch (e) {}
          return true;
        },
        child: SmartRefresher(
          controller: swipeController,
          enablePullDown: true,
          enablePullUp: true,
          header: CustomHeader(
            height: 120,
            builder: (BuildContext context,RefreshStatus mode){
              Widget body ;
              if(mode==RefreshStatus.idle){
                body = Card(
                    shape: CircleBorder(
                      side: new BorderSide(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_downward, color:Colors.white),
                    )
                );
              }
              else if(mode==RefreshStatus.refreshing){
                body = Card(
                    shape: CircleBorder(
                      side: new BorderSide(
                        color: Color(0xffff99df),
                        width: 3,
                      ),
                    ),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, child) {
                          return Transform.rotate(
                            angle: _controller.value * 2 * math.pi,
                            child: Icon(Icons.refresh, color:Colors.white),
                          );
                        },
                      ),
                    )
                );
              }
              else if(mode == RefreshStatus.failed){
                body = Card(
                    shape: CircleBorder(),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: Icon(Icons.error_outline, color:Colors.white),
                    )
                );
              }
              else if(mode == RefreshStatus.canRefresh){
                body = Card(
                    shape: CircleBorder(
                      side: new BorderSide(
                        color: Color(0xffff99df),
                        width: 3,
                      ),
                    ),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_downward, color:Colors.white),
                    )
                );
              }
              else{
                body = Card(
                    shape: CircleBorder(
                      side: new BorderSide(
                        color: Color(0xffff99df),
                        width: 3,
                      ),
                    ),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: Icon(Icons.done, color:Colors.white),
                    )
                );
              }
              return Container(
                height: 55.0,
                child: Center(child:body),
              );
            },
          ),
          footer: CustomFooter(
            height: 120,
            builder: (BuildContext context, LoadStatus mode){
              Widget body ;
              if(mode==LoadStatus.idle){
                body = Card(
                    shape: CircleBorder(
                      side: new BorderSide(
                        color: Color(0xffff99df),
                        width: 3,
                      ),
                    ),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: Icon(Icons.done, color:Colors.white),
                    )
                );
              }
              else if(mode==LoadStatus.loading){
                body = Card(
                    shape: CircleBorder(
                      side: new BorderSide(
                        color: Color(0xffff99df),
                        width: 3,
                      ),
                    ),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, child) {
                          return Transform.rotate(
                            angle: _controller.value * 2 * math.pi,
                            child: Icon(Icons.refresh, color:Colors.white),
                          );
                        },
                      ),
                    )
                );
              }
              else if(mode == LoadStatus.failed){
                body = Card(
                    shape: CircleBorder(),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: Icon(Icons.error_outline, color:Colors.white),
                    )
                );
              }
              else if(mode == LoadStatus.canLoading){
                body = Card(
                    shape: CircleBorder(
                      side: new BorderSide(
                        color: Color(0xffff99df),
                        width: 3,
                      ),
                    ),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_upward, color:Colors.white),
                    )
                );
              }
              else{
                body = Card(
                    shape: CircleBorder(
                      side: new BorderSide(
                        color: Color(0xffff99df),
                        width: 3,
                      ),
                    ),
                    color: Colors.black,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: Icon(Icons.done, color:Colors.white),
                    )
                );
              }
              return Container(
                height: 55.0,
                child: Center(child:body),
              );
            },
          ),
          onRefresh: () async {
            controller = PageController(initialPage: 0);

            await new Future.delayed(const Duration(milliseconds: 500), () => "1");
            if (singleIssue >= 1 && singleIssue < issueHrefs.length){
              singleIssue -= 1;
              reader();
            }
            swipeController.refreshCompleted();
          },
          onLoading: () async {
            controller = PageController(initialPage: 0);
            
            await new Future.delayed(const Duration(milliseconds: 500), () => "1");
            await savePage(-1);
            if (singleIssue >= 0 && singleIssue < issueHrefs.length - 1){
              singleIssue += 1;
              reader();
            }
            swipeController.loadComplete();
          },
          child: CustomScrollView(
              controller: controller,
              physics: PageScrollPhysics(),
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
      )
    );
  }
}