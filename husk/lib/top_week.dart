import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';
import 'global_static.dart';
import 'global_widgets.dart';
import 'animate_page.dart';
import 'single_comic_page.dart';

import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class TopWeek extends StatefulWidget {
  @override
  _TopWeekState createState() => _TopWeekState();
}

class _TopWeekState extends State<TopWeek> {
  ScrollController listController = ScrollController();
  TextEditingController libraryInputController = TextEditingController(text: currentSearchPageSearchString);
  Map<String, bool> searchItemsSaved = <String, bool>{};
  List<Widget> searchResults = [];

  bool loading = false;
  bool error = false;
  bool showLibraryItems = true;

  RefreshController refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    topWeekItems = <String, List<String>>{};
    load();
  }

  void load() async{
    setState(() {
      loading = true;
      error = false;
    });
    var uri = Uri.parse(URL_BASE);

    final response = await http.post(uri, headers: HEADERS);
    if (response.statusCode == 200) {
      List<dom.Element> comics = html.parse(response.body).getElementById("tab-top-week").children;

      for (int i = 0; i < comics.length; i++){
        dom.Element comic = comics[i];

        String comicName = comic.getElementsByTagName("span")[0].text.trim();
        String comicHref = URL_BASE + comic.getElementsByTagName("a")[0].attributes["href"];
        String imgSrc = comic.getElementsByTagName("img")[0].attributes['src'];
        String latestIssue = comic.getElementsByTagName("p")[1].text.replaceAll("Latest: Issue ", "").trim();
        String imageUrl;
        if (imgSrc.contains("http")){
          imageUrl = imgSrc;
        } else {
          imageUrl = URL_BASE + imgSrc;
        }

        topWeekItems[comicName] = <String>[
          imageUrl,
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
      String comicHref = searchItem.value[1];
      String latestIssue = searchItem.value[2];
      String imageUrl = searchItem.value[0];
      searchItemsSaved[comicName] = saved;
      searchResults.add(
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
                              color: PRIMARY_BLACK,
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
                                color: PRIMARY_BLACK,
                              ),
                              child: Text(
                                latestIssue,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: PRIMARY_WHITE,
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
                                "",
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

  List<Widget> buildResultsList() {
    String savedComics;
    try {
      savedComics = prefs.getString("saved");
    }
    catch (e) {return searchResults;}
    Map<String, dynamic> savedComicsData = Map<String, dynamic>();
    try {
      savedComicsData = json.decode(savedComics);
    } catch (e) {}

    if (savedComicsData == null) {
      savedComicsData = <String, List<dynamic>>{};
    }
    Map<String, dynamic> searchItemsCopy = Map.from(topWeekItems);
    buildListPart(searchItemsCopy, false);
    return searchResults;
  }

  @override
  Widget build(BuildContext context) {
    return loading ? Center(
      child: CircularProgressIndicator(color: PROGRESS_INDICATOR_COLOUR),
    ) : error ? Center(
        child: Icon(
          Icons.error_outline,
          color: ERROR_COLOUR,
          size: 50.0,
          semanticLabel: 'Error loading results',
        )
    ) : Container(
      height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 150,
      child: SmartRefresher(
        controller: refreshController,
        enablePullDown: true,
        header: MaterialClassicHeader(),
        onRefresh: () async {
          await load();
          refreshController.refreshCompleted();
        },
        child: ListView (
          controller: listController,
          children: buildResultsList(),
        ),
      ),
    );
  }
}