import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';
import 'global_static.dart';
import 'global_widgets.dart';
import 'animate_page.dart';
import 'single_comic_page.dart';

import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  ScrollController listController = ScrollController();
  TextEditingController libraryInputController = TextEditingController(text: currentSearchPageSearchString);
  Map<String, bool> searchItemsSaved = <String, bool>{};
  List<Widget> searchResults = emptySearch;

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

    var uri = Uri.parse(URL_BASE + "ajax/search?q=" + searchString);

    final response = await http.get(uri, headers: HEADERS);
    print(response.statusCode);
    if (response.statusCode == 200 && json.decode(response.body)["status"] == "1") {
      List responseJson = json.decode(response.body)["data"];
      for (Map comic in responseJson) {
        String comicName = comic["title"];
        String comicHref = URL_BASE + "comic/" + comic["slug"];
        //String latestIssue = comic.children[1].text.replaceAll("Issue ", "").replaceAll("Completed", "//").trim();
        //String description = title.getElementsByTagName("p")[0].text.replaceAll("...", "").replaceAll("N/a", "...").trim();
        String imageUrl = comic["img_url"];

        searchItems[comicName] = <String>[
          imageUrl,
          comicHref,
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
    if (searchItems.entries.length == 0) {
      return searchResults;
    }
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
      child: Scaffold(
        backgroundColor: TRANSPARENT,
        body: Center(
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
                        child: TextFormField(
                          controller: libraryInputController,
                          textInputAction: TextInputAction.search,
                          onFieldSubmitted: (value) async {
                            search(value);
                          },
                          decoration: InputDecoration(
                            fillColor: PRIMARY_WHITE,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(100)),
                              borderSide:  BorderSide(color: SECONDARY_BUTTON_COLOUR, width: 5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(100)),
                              borderSide:  BorderSide(color: SECONDARY_BUTTON_COLOUR, width: 5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(100)),
                              borderSide:  BorderSide(color: SECONDARY_BUTTON_COLOUR, width: 5),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                libraryInputController.clear();
                              },
                              icon: libraryInputController.text.length > 0 ? Icon(Icons.clear, color: PRIMARY_BUTTON_COLOUR) : Icon(Icons.clear, color: SECONDARY_BUTTON_COLOUR),
                            ),
                            contentPadding: EdgeInsets.all(20),
                            hintText: 'Search ...',
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
                          padding: EdgeInsets.fromLTRB(0,0,0,0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                onPressed: () {
                                  showLibraryItems = !showLibraryItems;
                                  setState(() {});
                                  listController.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeOutCubic);
                                },
                                icon: showLibraryItems ? Icon(Icons.favorite, color: LIKE_COLOUR,) : Icon(Icons.favorite_outline, color: LIKE_COLOUR),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 150,
                  child: loading ? Center(
                    child: CircularProgressIndicator(color: PROGRESS_INDICATOR_COLOUR),
                  ) : error ? Center(
                      child: Icon(
                        Icons.error_outline,
                        color: ERROR_COLOUR,
                        size: 50.0,
                        semanticLabel: 'Error loading search results',
                      )
                  ) : ListView (
                    controller: listController,
                    children: buildSearchResultsList(),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
