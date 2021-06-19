import 'dart:convert';

import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';
import 'global_static.dart';
import 'animate_page.dart';
import 'reader.dart';

import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

import 'package:flutter/material.dart';

class SingleComicPage extends StatefulWidget {
  @override
  _SingleComicPageState createState() => _SingleComicPageState();
}

class _SingleComicPageState extends State<SingleComicPage> {
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
      issuesDownloadIcon = List<Icon>.filled(issues.length, Icon(Icons.download, color: SECONDARY_BUTTON_COLOUR));
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
                                  child: CircularProgressIndicator(color: PROGRESS_INDICATOR_COLOUR,),
                                )
                            ) :
                            issuesDownloaded[issueHrefs.indexOf(issueHref)] ? IconButton(
                                onPressed: () {
                                  //delete(issueHref);
                                },
                                icon: Icon(Icons.delete_forever, color: DELETE_COLOUR,)
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
                                  color: PRIMARY_BUTTON_COLOUR,
                                )
                                    : Icon(
                                  Icons.adjust,
                                  color: SECONDARY_BUTTON_COLOUR,
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
                colors: [MAIN_COLOUR_1, MAIN_COLOUR_2]
            ),
          ),
          child: Scaffold(
            backgroundColor: TRANSPARENT,
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
                  child: CircularProgressIndicator(color: PROGRESS_INDICATOR_COLOUR),
                ) : error ? Center(
                    child: Icon(
                      Icons.error_outline,
                      color: ERROR_COLOUR,
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
                                                  color: PRIMARY_BLACK,
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
                                        color: LIKE_COLOUR,
                                      ) : Icon(
                                        Icons.favorite_border,
                                        color: LIKE_COLOUR,
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
                                  primary: PRIMARY_BUTTON_COLOUR,
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
                                              color: PRIMARY_BUTTON_COLOUR,
                                            )
                                        ),
                                        Positioned(
                                            bottom: 0,
                                            left: 5,
                                            right: 5,
                                            child: Icon(
                                              Icons.keyboard_arrow_down,
                                              color: SECONDARY_BUTTON_COLOUR,
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
                                              color: SECONDARY_BUTTON_COLOUR,
                                            )
                                        ),
                                        Positioned(
                                            bottom: 0,
                                            left: 5,
                                            right: 5,
                                            child: Icon(
                                              Icons.keyboard_arrow_down,
                                              color: PRIMARY_BUTTON_COLOUR,
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
                                    icon: showDownloaded ? Icon(Icons.download, color: PRIMARY_BUTTON_COLOUR) : Icon(Icons.download, color: SECONDARY_BUTTON_COLOUR),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showRead = !showRead;
                                      setState(() {});
                                      listController.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeOutCubic);
                                    },
                                    icon: showRead ? Icon(Icons.album, color: PRIMARY_BUTTON_COLOUR) : Icon(Icons.adjust, color: SECONDARY_BUTTON_COLOUR),
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