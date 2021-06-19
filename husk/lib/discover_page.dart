import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';
import 'global_static.dart';
import 'global_widgets.dart';
import 'animate_page.dart';
import 'single_comic_page.dart';

import 'library_page.dart';
import 'new_releases.dart';
import 'most_popular.dart';
import 'latest_updated.dart';
import 'top_today.dart';
import 'top_week.dart';
import 'top_month.dart';

import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class DiscoverPage extends StatefulWidget {
  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  ScrollController listController = ScrollController();
  TextEditingController libraryInputController = TextEditingController(text: currentSearchPageSearchString);
  Map<String, bool> searchItemsSaved = <String, bool>{};
  List<Widget> searchResults = emptyContainer;

  bool loading = false;
  bool error = false;
  bool showLibraryItems = true;

  @override
  void initState() {
    super.initState();
  }

  void search(searchString) async {
    currentSearchPageSearchString = searchString;
    searchItems = <String, List<String>>{};
    setState(() {
      loading = true;
      error = false;
    });

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
                          color: LIKE_COLOUR,
                        ) : Icon(
                          Icons.favorite_border,
                          color: LIKE_COLOUR,
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
    searchResults = <Widget>[];
    if (showLibraryItems) {
      buildListPart(savedComicsData, true);
    }
    buildListPart(searchItemsCopy, false);
    return searchResults;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 6,
        child:  Scaffold(
          backgroundColor: TRANSPARENT,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: Container(
              color: PRIMARY_WHITE,
              child: TabBar(
                isScrollable: true,
                labelColor: PRIMARY_BLACK,
                unselectedLabelColor: SECONDARY_BLACK,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: SECONDARY_BLACK,
                labelStyle: TextStyle(
                  fontSize: 12.0,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 10.0,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.new_releases),
                    text: "New Releases",
                  ),
                  Tab(
                    icon: Icon(Icons.star_border_outlined),
                    text: "Most Popular",
                  ),
                  Tab(
                    icon: Icon(Icons.update),
                    text: "Latest Updated",
                  ),
                  Tab(
                    icon: Icon(Icons.today),
                    text: "Top Today",
                  ),
                  Tab(
                    icon: Icon(Icons.calendar_view_week),
                    text: "Top This Week",
                  ),
                  Tab(
                    icon: Icon(Icons.calendar_view_month),
                    text: "Top This Month",
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              NewReleases(),
              MostPopular(),
              LatestUpdated(),
              TopToday(),
              TopWeek(),
              TopMonth(),
            ],
          ),
        ),
      ),
    );
  }
}