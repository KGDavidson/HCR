import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';
import 'global_static.dart';

import 'package:http/http.dart' as http;

class Reader extends StatefulWidget {
  @override
  _ReaderState createState() => _ReaderState();
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

    final response = await http.get(Uri.parse(URL_BASE + issueHrefs[singleIssue] + "&quality=hq"), headers: HEADERS);
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
                        color: PRIMARY_WHITE,
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
      child: CircularProgressIndicator(color: PROGRESS_INDICATOR_COLOUR),
    ) : error ? Center(
        child: Icon(
          Icons.error_outline,
          color: ERROR_COLOUR,
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
                          color: PRIMARY_WHITE,
                          width: 3,
                        ),
                      ),
                      color: PRIMARY_BLACK,
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
                          color: MAIN_COLOUR_1,
                          width: 3,
                        ),
                      ),
                      color: PRIMARY_BLACK,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (_, child) {
                            return Transform.rotate(
                              angle: _controller.value * 2 * math.pi,
                              child: Icon(Icons.refresh, color: PRIMARY_WHITE),
                            );
                          },
                        ),
                      )
                  );
                }
                else if(mode == RefreshStatus.failed){
                  body = Card(
                      shape: CircleBorder(),
                      color: PRIMARY_BLACK,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Icon(Icons.error_outline, color: PRIMARY_WHITE),
                      )
                  );
                }
                else if(mode == RefreshStatus.canRefresh){
                  body = Card(
                      shape: CircleBorder(
                        side: new BorderSide(
                          color: MAIN_COLOUR_1,
                          width: 3,
                        ),
                      ),
                      color: PRIMARY_BLACK,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_downward, color:PRIMARY_WHITE),
                      )
                  );
                }
                else{
                  body = Card(
                      shape: CircleBorder(
                        side: new BorderSide(
                          color: MAIN_COLOUR_1,
                          width: 3,
                        ),
                      ),
                      color: PRIMARY_BLACK,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Icon(Icons.done, color:PRIMARY_WHITE),
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
                          color: MAIN_COLOUR_1,
                          width: 3,
                        ),
                      ),
                      color: PRIMARY_BLACK,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Icon(Icons.done, color:PRIMARY_WHITE),
                      )
                  );
                }
                else if(mode==LoadStatus.loading){
                  body = Card(
                      shape: CircleBorder(
                        side: new BorderSide(
                          color: MAIN_COLOUR_1,
                          width: 3,
                        ),
                      ),
                      color: PRIMARY_BLACK,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (_, child) {
                            return Transform.rotate(
                              angle: _controller.value * 2 * math.pi,
                              child: Icon(Icons.refresh, color:PRIMARY_WHITE),
                            );
                          },
                        ),
                      )
                  );
                }
                else if(mode == LoadStatus.failed){
                  body = Card(
                      shape: CircleBorder(),
                      color: PRIMARY_BLACK,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Icon(Icons.error_outline, color:PRIMARY_WHITE),
                      )
                  );
                }
                else if(mode == LoadStatus.canLoading){
                  body = Card(
                      shape: CircleBorder(
                        side: new BorderSide(
                          color: MAIN_COLOUR_1,
                          width: 3,
                        ),
                      ),
                      color: PRIMARY_BLACK,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_upward, color:PRIMARY_WHITE),
                      )
                  );
                }
                else{
                  body = Card(
                      shape: CircleBorder(
                        side: new BorderSide(
                          color: MAIN_COLOUR_1,
                          width: 3,
                        ),
                      ),
                      color: PRIMARY_BLACK,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Icon(Icons.done, color:PRIMARY_WHITE),
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