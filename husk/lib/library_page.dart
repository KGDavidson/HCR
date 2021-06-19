import 'global.dart';
import 'global_static.dart';
import 'global_widgets.dart';
import 'animate_page.dart';
import 'single_comic_page.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  ScrollController listController = ScrollController();
  TextEditingController libraryInputController = TextEditingController(text: currentLibraryPageSearchString);
  List<Widget> libraryItems = emptyLibrary;

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

  updateCurrentSearchString(searchString) async {
    currentLibraryPageSearchString = searchString;
  }

  List<Widget> buildLibraryItems() {
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
        bool include = (currentLibraryPageSearchString == "" || comicName.toLowerCase().contains(currentLibraryPageSearchString.toLowerCase().trim()));
        if ((unread | showRead) && include) {
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
    } else {
      libraryItems = emptyLibrary;
    }
    if (!reversedList){
      libraryItems = libraryItems.reversed.toList();
    }
    if (libraryItems.length == 0) {
      return noSearchResults;
    }
    return libraryItems;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: TRANSPARENT,
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
                          child: TextFormField(
                            controller: libraryInputController,
                            textInputAction: TextInputAction.search,
                            onChanged: (value) {
                              updateCurrentSearchString(value);
                              setState(() {});
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
                              contentPadding: EdgeInsets.all(20),
                              hintText: 'Search ...',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  libraryInputController.clear();
                                  updateCurrentSearchString("");
                                  setState(() {});
                                },
                                icon: libraryInputController.text.length > 0 ? Icon(Icons.clear, color: PRIMARY_BUTTON_COLOUR) : Icon(Icons.clear, color: SECONDARY_BUTTON_COLOUR),
                              ),
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
                                    showRead = !showRead;
                                    setState(() {});
                                    listController.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeOutCubic);
                                  },
                                  icon: showRead ? Icon(Icons.album, color: PRIMARY_BUTTON_COLOUR,) : Icon(Icons.adjust, color: SECONDARY_BUTTON_COLOUR),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading ? Center(
                    child: CircularProgressIndicator(color: PROGRESS_INDICATOR_COLOUR),
                  ) : error ? Center(
                      child: Icon(
                        Icons.error_outline,
                        color: ERROR_COLOUR,
                        size: 50.0,
                        semanticLabel: 'Error loading search results',
                      )
                  ) : Container(
                    height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 150,
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
    );
  }
}