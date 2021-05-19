// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/main.dart';
import 'package:violet/pages/bookmark/bookmark_page.dart';
import 'package:violet/pages/download/download_page.dart';
// import 'package:violet/pages/community/community_page.dart';
// import 'package:violet/pages/main/main_page.dart';
import 'package:violet/pages/main/main_page2.dart';
import 'package:violet/pages/search/search_page.dart';
import 'package:violet/pages/settings/settings_page.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/variables.dart';
import 'package:violet/version/update_sync.dart';

class AfterLoadingPage extends StatefulWidget {
  @override
  _AfterLoadingPageState createState() => new _AfterLoadingPageState();
}

class _AfterLoadingPageState extends State<AfterLoadingPage>
    with WidgetsBindingObserver {
  int _page = 0;
  PageController _c;
  bool isBlurred = false;

  @override
  void initState() {
    _c = new PageController(
      initialPage: _page,
    );
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    setState(() {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive)
        isBlurred = true;
      else
        isBlurred = false;
    });
  }

  @override
  void disposed() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Settings.useDrawer)
      return _bottomNav();
    else
      return _drawer();
  }

  _bottomNav() {
    final mediaQuery = MediaQuery.of(context);
    Variables.updatePadding((mediaQuery.padding + mediaQuery.viewInsets).top,
        (mediaQuery.padding + mediaQuery.viewInsets).bottom);
    if (Platform.isAndroid) {
      return new Scaffold(
        key: scaffoldKey,
        bottomNavigationBar: MediaQuery(
          data: mediaQuery.copyWith(
            padding: mediaQuery.padding +
                mediaQuery.viewInsets +
                EdgeInsets.only(bottom: 6),
          ),
          child: BottomNavigationBar(
            elevation: 9,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.shifting,
            fixedColor: Settings.majorColor,
            unselectedItemColor: Settings.themeWhat
                ? Colors.white
                : Colors.black, //Colors.black,
            currentIndex: _page,
            onTap: (index) {
              this._c.animateToPage(index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut);
            },
            items: <BottomNavigationBarItem>[
              new BottomNavigationBarItem(
                  backgroundColor: Settings.themeWhat
                      ? Colors.grey.shade900.withOpacity(0.90)
                      : Colors.grey.shade50,
                  icon: new Icon(MdiIcons.home),
                  title: new Text(Translations.of(context).trans('main'))),
              new BottomNavigationBarItem(
                  backgroundColor: Settings.themeWhat
                      ? Colors.grey.shade900.withOpacity(0.90)
                      : Colors.grey.shade50,
                  icon: new Icon(Icons.search),
                  title: new Text(Translations.of(context).trans('search'))),
              new BottomNavigationBarItem(
                  backgroundColor: Settings.themeWhat
                      ? Colors.grey.shade900.withOpacity(0.90)
                      : Colors.grey.shade50,
                  icon: new Icon(Icons.bookmark),
                  title: new Text(Translations.of(context).trans('bookmark'))),
              new BottomNavigationBarItem(
                  icon: new Icon(Icons.file_download),
                  title: new Text(Translations.of(context).trans('download'))),
              // new BottomNavigationBarItem(
              //     backgroundColor: Settings.themeWhat
              //         ? Colors.grey.shade900.withOpacity(0.90)
              //         : Colors.grey.shade50,
              //     icon: new Icon(MdiIcons.accountGroup),
              //     title: new Text(Translations.of(context).trans('community'))),
              new BottomNavigationBarItem(
                  backgroundColor: Settings.themeWhat
                      ? Colors.grey.shade900.withOpacity(0.90)
                      : Colors.grey.shade50,
                  icon: new Icon(Icons.settings),
                  title: new Text(Translations.of(context).trans('settings'))),
            ],
          ),
        ),
        body: new PageView(
          controller: _c,
          onPageChanged: (newPage) {
            setState(() {
              this._page = newPage;
            });
          },
          children: <Widget>[
            MainPage2(),
            SearchPage(),
            BookmarkPage(),
            DownloadPage(),
            // CommunityPage(),
            SettingsPage(),
          ],
          // ),
        ),
      );
    } else if (Platform.isIOS) {
      return new Scaffold(
        key: scaffoldKey,
        bottomNavigationBar: BottomNavigationBar(
          elevation: 9,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.shifting,
          fixedColor: Settings.majorColor,
          unselectedItemColor:
              Settings.themeWhat ? Colors.white : Colors.black, //Colors.black,
          currentIndex: _page,
          onTap: (index) {
            this._c.animateToPage(index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut);
          },
          items: <BottomNavigationBarItem>[
            new BottomNavigationBarItem(
                backgroundColor: Settings.themeWhat
                    ? Colors.grey.shade900.withOpacity(0.90)
                    : Colors.grey.shade50,
                icon: new Icon(MdiIcons.home),
                title: new Text(Translations.of(context).trans('main'))),
            new BottomNavigationBarItem(
                backgroundColor: Settings.themeWhat
                    ? Colors.grey.shade900.withOpacity(0.90)
                    : Colors.grey.shade50,
                icon: new Icon(Icons.search),
                title: new Text(Translations.of(context).trans('search'))),
            new BottomNavigationBarItem(
                backgroundColor: Settings.themeWhat
                    ? Colors.grey.shade900.withOpacity(0.90)
                    : Colors.grey.shade50,
                icon: new Icon(Icons.bookmark),
                title: new Text(Translations.of(context).trans('bookmark'))),
            // new BottomNavigationBarItem(
            //     backgroundColor: Settings.themeWhat
            //         ? Colors.grey.shade900.withOpacity(0.90)
            //         : Colors.grey.shade50,
            //     icon: new Icon(MdiIcons.accountGroup),
            //     title: new Text(Translations.of(context).trans('community'))),
            new BottomNavigationBarItem(
                backgroundColor: Settings.themeWhat
                    ? Colors.grey.shade900.withOpacity(0.90)
                    : Colors.grey.shade50,
                icon: new Icon(Icons.settings),
                title: new Text(Translations.of(context).trans('settings'))),
          ],
        ),
        body: new PageView(
          controller: _c,
          onPageChanged: (newPage) {
            setState(() {
              this._page = newPage;
            });
          },
          children: <Widget>[
            MainPage2(),
            SearchPage(),
            BookmarkPage(),
            // CommunityPage(),
            SettingsPage(),
          ],
        ),
        // ),
      );
    }
    throw new Exception('not implemented');
  }

  int page = 0;
  _drawer() {
    print(_colorToString(Settings.majorColor));
    final mediaQuery = MediaQuery.of(context);
    Variables.updatePadding((mediaQuery.padding + mediaQuery.viewInsets).top,
        (mediaQuery.padding + mediaQuery.viewInsets).bottom);
    if (Platform.isAndroid) {
      return new Scaffold(
        body: PageView(
          physics: new NeverScrollableScrollPhysics(),
          controller: _c,
          scrollDirection: Axis.vertical,
          children: <Widget>[
            MainPage2(),
            SearchPage(),
            BookmarkPage(),
            DownloadPage(),
            // CommunityPage(),
            SettingsPage(),
          ],
        ),
        drawer: Container(
          width: 220,
          padding: mediaQuery.padding + mediaQuery.viewInsets,
          child: Drawer(
            child: Column(
              children: <Widget>[
                // DrawerHeader(
                //   child: Text('Drawer Header'),
                //   decoration: BoxDecoration(
                //     color: Colors.blue,
                //   ),
                // ),
                Container(
                  margin: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        InkWell(
                          child: Image.asset(
                            'assets/images/logo-' +
                                _colorToString(Settings.majorColor) +
                                '.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 12),
                        ),
                        Text(
                          'Project Violet',
                          style: TextStyle(
                            color: Settings.themeWhat
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 18.0,
                            fontFamily: "Calibre-Semibold",
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                            '${UpdateSyncManager.majorVersion}.${UpdateSyncManager.minorVersion}.${UpdateSyncManager.patchVersion}',
                            style: TextStyle(
                              fontFamily: "Calibre-Semibold",
                              fontSize: 17,
                              letterSpacing: 1.0,
                            ))
                      ],
                    ),
                  ),
                ),
                _drawerButton(
                    MdiIcons.home,
                    0,
                    Translations.of(context).trans('main'),
                    Settings.majorColor),
                _drawerButton(
                    Icons.search,
                    1,
                    Translations.of(context).trans('search'),
                    Settings.majorColor),
                _drawerButton(
                    MdiIcons.bookmark,
                    2,
                    Translations.of(context).trans('bookmark'),
                    Settings.majorColor),
                _drawerButton(
                    MdiIcons.download,
                    3,
                    Translations.of(context).trans('download'),
                    Settings.majorColor),
                // _drawerButton(
                //     MdiIcons.accountGroup,
                //     4,
                //     Translations.of(context).trans('community'),
                //     Settings.majorColor),
                _drawerButton(
                    Icons.settings,
                    4,
                    Translations.of(context).trans('settings'),
                    Settings.majorColor),
                Expanded(
                    child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'Copyright (C) 2020-2021\nby project-violet',
                    style: TextStyle(
                      color: Settings.themeWhat ? Colors.white : Colors.black87,
                      fontSize: 12.0,
                      fontFamily: "Calibre-Semibold",
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )),
                Container(height: 16)
              ],
            ),
          ),
        ),
      );
    } else if (Platform.isIOS) {
      return new Scaffold(
        body: PageView(
          physics: new NeverScrollableScrollPhysics(),
          controller: _c,
          scrollDirection: Axis.vertical,
          children: <Widget>[
            MainPage2(),
            SearchPage(),
            BookmarkPage(),
            // CommunityPage(),
            SettingsPage(),
          ],
        ),
        drawer: Container(
          width: 220,
          padding: mediaQuery.padding + mediaQuery.viewInsets,
          child: Drawer(
            child: Column(
              children: <Widget>[
                // DrawerHeader(
                //   child: Text('Drawer Header'),
                //   decoration: BoxDecoration(
                //     color: Colors.blue,
                //   ),
                // ),
                Container(
                  margin: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        InkWell(
                          child: Image.asset(
                            'assets/images/logo-' +
                                _colorToString(Settings.majorColor) +
                                '.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 12),
                        ),
                        Text(
                          'Project Violet',
                          style: TextStyle(
                            color: Settings.themeWhat
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 18.0,
                            fontFamily: "Calibre-Semibold",
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                            '${UpdateSyncManager.majorVersion}.${UpdateSyncManager.minorVersion}.${UpdateSyncManager.patchVersion}',
                            style: TextStyle(
                              fontFamily: "Calibre-Semibold",
                              fontSize: 17,
                              letterSpacing: 1.0,
                            ))
                      ],
                    ),
                  ),
                ),
                _drawerButton(
                    MdiIcons.home,
                    0,
                    Translations.of(context).trans('main'),
                    Settings.majorColor),
                _drawerButton(
                    Icons.search,
                    1,
                    Translations.of(context).trans('search'),
                    Settings.majorColor),
                _drawerButton(
                    MdiIcons.bookmark,
                    2,
                    Translations.of(context).trans('bookmark'),
                    Settings.majorColor),
                // _drawerButton(
                //     MdiIcons.accountGroup,
                //     3,
                //     Translations.of(context).trans('community'),
                //     Settings.majorColor),
                _drawerButton(
                    Icons.settings,
                    3,
                    Translations.of(context).trans('settings'),
                    Settings.majorColor),
                Expanded(
                    child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'Copyright (C) 2020-2021\nby project-violet',
                    style: TextStyle(
                      color: Settings.themeWhat ? Colors.white : Colors.black87,
                      fontSize: 12.0,
                      fontFamily: "Calibre-Semibold",
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )),
                Container(height: 16)
              ],
            ),
          ),
        ),
      );
    }
  }

  _colorToString(Color color) {
    if (Colors.red.value == color.value) return 'red         '.trim();
    if (Colors.pink.value == color.value) return 'pink        '.trim();
    if (Colors.purple.value == color.value) return 'purple      '.trim();
    if (Colors.deepPurple.value == color.value) return 'deepPurple  '.trim();
    if (Colors.indigo.value == color.value) return 'indigo      '.trim();
    if (Colors.blue.value == color.value) return 'blue        '.trim();
    if (Colors.lightBlue.value == color.value) return 'lightBlue   '.trim();
    if (Colors.cyan.value == color.value) return 'cyan        '.trim();
    if (Colors.teal.value == color.value) return 'teal        '.trim();
    if (Colors.green.value == color.value) return 'green       '.trim();
    if (Colors.lightGreen.value == color.value) return 'lightGreen  '.trim();
    if (Colors.lime.value == color.value) return 'lime        '.trim();
    if (Colors.yellow.value == color.value) return 'yellow      '.trim();
    if (Colors.amber.value == color.value) return 'amber       '.trim();
    if (Colors.orange.value == color.value) return 'orange      '.trim();
    if (Colors.deepOrange.value == color.value) return 'deepOrange  '.trim();
    if (Colors.brown.value == color.value) return 'brown       '.trim();
    if (Colors.grey.value == color.value) return 'grey        '.trim();
    if (Colors.blueGrey.value == color.value) return 'blueGrey    '.trim();
    if (Colors.black.value == color.value) return 'black       '.trim();
  }

  _drawerButton(IconData icon, int page, String name, Color color) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
      height: 54,
      child: Container(
        // color: ,
        decoration: BoxDecoration(
            color: this.page == page ? color.withOpacity(0.4) : null,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          hoverColor: color,
          highlightColor: color.withOpacity(0.2),
          focusColor: color,
          splashColor: color.withOpacity(0.3),
          child: Row(
            children: [
              Container(width: 12),
              Icon(icon),
              Container(width: 12),
              Text(
                name,
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onTap: () {
            this.page = page;
            Navigator.pop(context);
            setState(() {});
            // this._c.animateToPage(page,
            //     duration: const Duration(milliseconds: 250),
            //     curve: Curves.easeInOut);
            this._c.jumpToPage(page);
          },
        ),
      ),
    );
  }
}
