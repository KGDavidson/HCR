import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
//import 'package:flutter/rendering.dart';

const Map<String, String> HEADERS = <String, String>{
  'user-agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
  'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
};
const Duration animationDuration = Duration(milliseconds: 200);

String searchString;
String singleComicHref;
List<String> issueHrefs;
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
      libraryItems = [];
      for (MapEntry<String, List<dynamic>> comic in savedComicsData.entries){
        String comicName = comic.key;
        String imageUrl = comic.value[0];
        String description = comic.value[1];
        String comicHref = comic.value[2];
        libraryItems.add(
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
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.all(20),
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
                  ) : RefreshIndicator(
                    onRefresh: () async {
                      await library();
                      return;
                    },
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column (
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: libraryItems,
                      ),
                    ),
                  ),
                ],
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
  List<Widget> singleComicResults = <Widget>[];

  String comicName;
  String publisher;
  String writer;
  String artist;
  String pubDate;
  String imageUrl;
  String summary;

  bool loading = false;
  bool error = false;

  bool singleComicSaved = false;

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
      List<dom.Element> issues = doc.getElementsByClassName("listing")[0].getElementsByTagName("tr");
      issues.removeAt(0);
      issues.removeAt(0);
      dom.Element infoSection = doc.getElementById("leftside").getElementsByClassName("barContent")[0];
      comicName = infoSection.getElementsByClassName("bigChar")[0].text;
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

      final prefs = await SharedPreferences.getInstance();
      String savedComics;
      savedComics = prefs.getString("saved");
      singleComicSaved = false;
      if (savedComics != null) {
        Map<String, List<dynamic>> savedComicsData = Map<String, List<dynamic>>.from(json.decode(savedComics));
        if (savedComicsData.containsKey(comicName)) {
          singleComicSaved = true;
        }
      }

      issueHrefs = [];
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
        singleComicResults.add(
          Container(
            padding: EdgeInsets.fromLTRB(10,2,10,0),
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
                    margin: EdgeInsets.fromLTRB(10,10,10,10),
                    padding: EdgeInsets.fromLTRB(10,0,10,0),
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
                        )
                      ],
                    ),
                  ),
                )
            ),
          ),
        );
      }

      singleComicResults = singleComicResults.reversed.toList();
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
                                                    comicName,
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

                                      print(savedComicsData.toString());

                                      if (savedComicsData == null){
                                        savedComicsData = <String, List<dynamic>>{};
                                      }
                                      if (singleComicSaved){
                                        savedComicsData.remove(comicName);
                                      } else {
                                        savedComicsData[comicName] = comicData;
                                      }
                                      print(savedComicsData.toString());
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
                            padding: EdgeInsets.fromLTRB(10,0,0,0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                ElevatedButton(
                                  onPressed: () {

                                  },
                                  child: Text("Resume"),
                                  style: ElevatedButton.styleFrom(
                                      primary: Color(0xff00c8f0),
                                      side: BorderSide(
                                          width: 1.5,
                                          color: Colors.black
                                      )
                                  ),
                                ),
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
                                ToggleButtons(
                                  children: <Widget>[
                                    Icon(Icons.keyboard_arrow_up),
                                    Icon(Icons.keyboard_arrow_down),
                                  ],
                                  onPressed: (int index) {
                                    setState(() {
                                      for (int buttonIndex = 0; buttonIndex < sortOrder.length; buttonIndex++) {
                                        if (buttonIndex == index) {
                                          if (sortOrder[buttonIndex] != true) {
                                            singleComicResults = singleComicResults.reversed.toList();
                                          }
                                          sortOrder[buttonIndex] = true;
                                        } else {
                                          sortOrder[buttonIndex] = false;
                                        }
                                      }
                                    });
                                  },
                                  fillColor: Color(0xff00c8f0),
                                  selectedColor: Colors.white,
                                  isSelected: sortOrder,
                                  borderColor: Colors.black,
                                  selectedBorderColor: Colors.black,
                                  borderWidth: 1.5,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: singleComicResults,
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
  List<Widget> pages = <Widget>[];

  bool loading = false;
  bool error = false;

  @override
  void initState() {
    super.initState();
    reader();
  }

  void reader() async {
    setState(() {
      loading = true;
      error = false;
    });

    var formData = new Map<String, dynamic>();
    print("https://readcomiconline.li/" + issueHrefs[singleIssue] + "&quality=lq");
    final response = await http.post(Uri.parse("https://readcomiconline.li/" + issueHrefs[singleIssue] + "&quality=hq"), headers: HEADERS, body: formData);
    if (response.statusCode == 200){
      String html = response.body;
      String pagesJS = html.split("var lstImages = new Array();")[1].split("var currImage = 0;")[0];
      pages = [];
      for (String page in pagesJS.split('lstImages.push("')){
        String pageUrl = page.split('"')[0];
        if (Uri.parse(pageUrl).isAbsolute) {
          pages.add(
            InteractiveViewer(
              child: FadeInImage.assetNetwork(
                image: pageUrl,
                placeholder: 'assets/loading.png',
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

  Widget customCard(){
    //https://2.bp.blogspot.com/os-X0tP2ZnktLie3nALk__eBmqVF0d9yhHJyugBZ1O9KhwoWU5mE6jGkvOvojYDg9TpJ7Ez9olFj=s0
    return Container();
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
    ) : NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (overscroll) {
        if (overscroll.leading) {
          if (singleIssue >= 0 && singleIssue < issueHrefs.length - 1){
            singleIssue += 1;
            reader();
          }
        } else {
          if (singleIssue >= 1 && singleIssue < issueHrefs.length){
            singleIssue -= 1;
            reader();
          }
        }
        return;
      },
      child: PageView (
        controller: PageController(
            viewportFraction: 0.99
        ),
        scrollDirection: Axis.vertical,
        children: pages,
      ),
    );
  }
}