import 'package:flutter/material.dart';

List<Widget> noSearchResults = <Widget>[
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
                          "No search results!",
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
                          "Try something else ...",
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
                          "Search and save your comics!",
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

List<Widget> emptyContainer = <Widget>[
  Container(
    padding: EdgeInsets.fromLTRB(10,10,10,0),
    height: 150,
    width: double.maxFinite,
  )
];