// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:violet/component/hitomi/hitomi_parser.dart';
import 'package:violet/database/query.dart';
import 'package:violet/database/user/bookmark.dart';
import 'package:violet/model/article_list_item.dart';
import 'package:violet/other/dialogs.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/pages/artist_info/search_type2.dart';
import 'package:violet/pages/bookmark/group/bookmark_search_sort.dart';
import 'package:violet/pages/bookmark/group/group_artist_article_list.dart';
import 'package:violet/pages/bookmark/group/group_artist_list.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/widgets/article_item/article_list_item_widget.dart';
import 'package:violet/widgets/floating_button.dart';
import 'package:violet/widgets/search_bar.dart';
import 'package:violet/network/wrapper.dart' as http;

// https://gist.github.com/collinjackson/4fddbfa2830ea3ac033e34622f278824#file-main-dart-L24
class DotsIndicator extends AnimatedWidget {
  DotsIndicator({
    this.controller,
    this.itemCount,
    this.onPageSelected,
    this.color: Colors.white,
  }) : super(listenable: controller);

  /// The PageController that this DotsIndicator is representing.
  final PageController controller;

  /// The number of items managed by the PageController
  final int itemCount;

  /// Called when a dot is tapped
  final ValueChanged<int> onPageSelected;

  /// The color of the dots.
  ///
  /// Defaults to `Colors.white`.
  final Color color;

  // The base size of the dots
  static const double _kDotSize = 6.0;

  // The increase in the size of the selected dot
  static const double _kMaxZoom = 2.0;

  // The distance between the center of each dot
  static const double _kDotSpacing = 20.0;

  Widget _buildDot(int index) {
    double selectedness = Curves.easeOut.transform(
      max(
        0.0,
        1.0 - ((controller.page ?? controller.initialPage) - index).abs(),
      ),
    );
    double zoom = 1.0 + (_kMaxZoom - 1.0) * selectedness;
    return new Container(
      width: _kDotSpacing,
      child: new Center(
        child: new Material(
          color: (Settings.themeWhat ? Colors.grey.shade100 : Color(0xFF353535))
              .withAlpha((max(zoom - 1, 0.5) * 255).toInt()),
          type: MaterialType.circle,
          child: new Container(
            width: _kDotSize * zoom,
            height: _kDotSize * zoom,
            child: new InkWell(
              onTap: () => onPageSelected(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: new List<Widget>.generate(itemCount, _buildDot),
    );
  }
}

class GroupArticleListPage extends StatefulWidget {
  final String name;
  final int groupId;

  GroupArticleListPage({this.name, this.groupId});

  @override
  _GroupArticleListPageState createState() => _GroupArticleListPageState();
}

class _GroupArticleListPageState extends State<GroupArticleListPage> {
  PageController _controller = PageController(
    initialPage: 0,
  );

  static const _kDuration = const Duration(milliseconds: 300);
  static const _kCurve = Curves.ease;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void refresh() {
    Bookmark.getInstance()
        .then((value) => value.getArticle().then((value) async {
              nowType = (await SharedPreferences.getInstance())
                  .getInt('bookmark_${widget.groupId}');
              if (nowType == null) nowType = 3;
              var queryRaw = 'SELECT * FROM HitomiColumnModel WHERE ';
              var cc = value
                  .where((e) => e.group() == widget.groupId)
                  .toList()
                  .reversed
                  .toList();
              if (cc.length == 0) {
                queryResult = List<QueryResult>();
                filterResult = queryResult;
                setState(() {});
                return;
              }
              //queryRaw += cc.map((e) => 'Id=${e.article()}').join(' OR ');
              queryRaw +=
                  'Id IN (' + cc.map((e) => e.article()).join(',') + ')';
              QueryManager.query(queryRaw + ' AND ExistOnHitomi=1')
                  .then((value) async {
                var qr = Map<String, QueryResult>();
                value.results.forEach((element) {
                  qr[element.id().toString()] = element;
                });

                var result = List<QueryResult>();
                cc.forEach((element) async {
                  if (qr[element.article()] == null) {
                    // TODO: Handle qurey not found
                    var hh = await http.get(
                        'https://ltn.hitomi.la/galleryblock/${element.article()}.html');
                    var article = await HitomiParser.parseGalleryBlock(hh.body);
                    var meta = {
                      'Id': int.parse(element.article()),
                      'Title': article['Title'],
                      'Artists': article['Artists'].join('|'),
                    };
                    result.add(QueryResult(result: meta));
                    setState(() {});
                    return;
                  }
                  result.add(qr[element.article()]);
                });

                queryResult = result;
                if (isFilterUsed) {
                  result.clear();
                  queryResult.forEach((element) {
                    var succ = !isOr;
                    tagStates.forEach((key, value) {
                      if (!value) return;
                      if (succ == isOr) return;
                      var split = key.split('|');
                      var kk = prefix2Tag(split[0]);
                      if (element.result[kk] == null && !isOr) {
                        succ = false;
                        return;
                      }
                      if (!isSingleTag(split[0])) {
                        var tt = split[1];
                        if (split[0] == 'female' || split[0] == 'male')
                          tt = split[0] + ':' + split[1];
                        if ((element.result[kk] as String)
                                .contains('|' + tt + '|') ==
                            isOr) succ = isOr;
                      } else if ((element.result[kk] as String == split[1]) ==
                          isOr) succ = isOr;
                    });
                    if (succ) result.add(element);
                  });
                }
                filterResult = result;
                setState(() {});
              });
            }));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height =
        MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: (mediaQuery.padding + mediaQuery.viewInsets).bottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Card(
            elevation: 5,
            color:
                Settings.themeWhat ? Color(0xFF353535) : Colors.grey.shade100,
            child: SizedBox(
              width: width - 16,
              height: height -
                  16 -
                  (mediaQuery.padding + mediaQuery.viewInsets).bottom,
              child: Stack(
                children: [
                  PageView(
                    controller: _controller,
                    children: [
                      Scaffold(
                        resizeToAvoidBottomInset: false,
                        // resizeToAvoidBottomPadding: false,
                        floatingActionButton: Visibility(
                          visible: checkMode,
                          child: AnimatedOpacity(
                            opacity: checkModePre ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 500),
                            child: _floatingButton(),
                          ),
                        ),
                        // floatingActionButton: Container(child: Text('asdf')),
                        body: Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: <Widget>[
                              SliverPersistentHeader(
                                floating: true,
                                delegate: AnimatedOpacitySliver(
                                  minExtent: 64 + 12.0,
                                  maxExtent: 64.0 + 12,
                                  searchBar: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Stack(children: <Widget>[
                                        _filter(),
                                        _title(),
                                      ])),
                                ),
                              ),
                              buildList()
                            ],
                          ),
                        ),
                      ),
                      GroupArtistList(
                          name: widget.name, groupId: widget.groupId),
                      GroupArtistArticleList(
                          name: widget.name, groupId: widget.groupId),
                    ],
                  ),
                  new Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: new Container(
                      color: null,
                      padding: const EdgeInsets.all(20.0),
                      child: new Center(
                        child: new DotsIndicator(
                          controller: _controller,
                          itemCount: 3,
                          onPageSelected: (int page) {
                            _controller.animateToPage(
                              page,
                              duration: _kDuration,
                              curve: _kCurve,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingButton() {
    return AnimatedFloatingActionButton(
      fabButtons: <Widget>[
        Container(
          child: FloatingActionButton(
            onPressed: () {
              filterResult.forEach((element) {
                checked.add(element.id());
              });
              setState(() {});
            },
            elevation: 4,
            heroTag: 'a',
            child: Icon(MdiIcons.checkAll),
          ),
        ),
        Container(
          child: FloatingActionButton(
            onPressed: () async {
              if (await Dialogs.yesnoDialog(
                  context,
                  Translations.of(context)
                      .trans('deletebookmarkmsg')
                      .replaceAll('%s', checked.length.toString()),
                  Translations.of(context).trans('bookmark'))) {
                var bookmark = await Bookmark.getInstance();
                checked.forEach((element) async {
                  bookmark.unbookmark(element);
                });
                checked.clear();
                refresh();
              }
            },
            elevation: 4,
            heroTag: 'b',
            child: Icon(MdiIcons.delete),
          ),
        ),
        Container(
          child: FloatingActionButton(
            onPressed: moveChecked,
            elevation: 4,
            heroTag: 'c',
            child: Icon(MdiIcons.folderMove),
          ),
        ),
      ],
      animatedIconData: AnimatedIcons.menu_close,
      exitCallback: () {
        setState(() {
          checkModePre = false;
          checked.clear();
        });
        Future.delayed(Duration(milliseconds: 500)).then((value) {
          setState(() {
            checkMode = false;
          });
        });
      },
    );
  }

  Widget _filter() {
    return Align(
      alignment: Alignment.centerRight,
      child: Hero(
        tag: "searchtype2",
        child: Card(
          color: Settings.themeWhat ? Color(0xFF353535) : Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          elevation: 100,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: InkWell(
            child: SizedBox(
              height: 48,
              width: 48,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    MdiIcons.formatListText,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            onTap: () async {
              if (checkMode) return;
              Navigator.of(context)
                  .push(PageRouteBuilder(
                opaque: false,
                transitionDuration: Duration(milliseconds: 500),
                transitionsBuilder: (BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                    Widget wi) {
                  return new FadeTransition(opacity: animation, child: wi);
                },
                pageBuilder: (_, __, ___) => SearchType2(
                  nowType: nowType,
                ),
              ))
                  .then((value) async {
                if (value == null) return;
                nowType = value;
                await (await SharedPreferences.getInstance())
                    .setInt('bookmark_${widget.groupId}', value);
                await Future.delayed(Duration(milliseconds: 50), () {
                  setState(() {});
                });
              });
            },
            onLongPress: () {
              if (checkMode) return;
              isFilterUsed = true;
              if (!Platform.isIOS) {
                Navigator.of(context)
                    .push(PageRouteBuilder(
                  // opaque: false,
                  transitionDuration: Duration(milliseconds: 500),
                  transitionsBuilder: (BuildContext context,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                      Widget wi) {
                    return new FadeTransition(opacity: animation, child: wi);
                  },
                  pageBuilder: (_, __, ___) => BookmarkSearchSort(
                    queryResult: queryResult,
                    tagStates: tagStates,
                    groupStates: groupStates,
                    isOr: isOr,
                    isSearch: isSearch,
                  ),
                ))
                    .then((value) async {
                  tagStates = value[0];
                  groupStates = value[1];
                  isOr = value[2];
                  var result = List<QueryResult>();
                  queryResult.forEach((element) {
                    var succ = !isOr;
                    tagStates.forEach((key, value) {
                      if (!value) return;
                      if (succ == isOr) return;
                      var split = key.split('|');
                      var kk = prefix2Tag(split[0]);
                      if (element.result[kk] == null && !isOr) {
                        succ = false;
                        return;
                      }
                      if (!isSingleTag(split[0])) {
                        var tt = split[1];
                        if (split[0] == 'female' || split[0] == 'male')
                          tt = split[0] + ':' + split[1];
                        if ((element.result[kk] as String)
                                .contains('|' + tt + '|') ==
                            isOr) succ = isOr;
                      } else if ((element.result[kk] as String == split[1]) ==
                          isOr) succ = isOr;
                    });
                    if (succ) result.add(element);
                  });
                  filterResult = result;
                  await Future.delayed(Duration(milliseconds: 50), () {
                    setState(() {});
                  });
                });
              } else {
                Navigator.of(context)
                    .push(CupertinoPageRoute(
                  builder: (_) => BookmarkSearchSort(
                    queryResult: queryResult,
                    tagStates: tagStates,
                    groupStates: groupStates,
                    isOr: isOr,
                    isSearch: isSearch,
                  ),
                ))
                    .then((value) async {
                  tagStates = value[0];
                  groupStates = value[1];
                  isOr = value[2];
                  var result = List<QueryResult>();
                  queryResult.forEach((element) {
                    var succ = !isOr;
                    tagStates.forEach((key, value) {
                      if (!value) return;
                      if (succ == isOr) return;
                      var split = key.split('|');
                      var kk = prefix2Tag(split[0]);
                      if (element.result[kk] == null && !isOr) {
                        succ = false;
                        return;
                      }
                      if (!isSingleTag(split[0])) {
                        var tt = split[1];
                        if (split[0] == 'female' || split[0] == 'male')
                          tt = split[0] + ':' + split[1];
                        if ((element.result[kk] as String)
                                .contains('|' + tt + '|') ==
                            isOr) succ = isOr;
                      } else if ((element.result[kk] as String == split[1]) ==
                          isOr) succ = isOr;
                    });
                    if (succ) result.add(element);
                  });
                  filterResult = result;
                  await Future.delayed(Duration(milliseconds: 50), () {
                    setState(() {});
                  });
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: EdgeInsets.only(top: 24, left: 12),
      child: Text(widget.name,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  bool isFilterUsed = false;
  bool isOr = false;
  bool isSearch = false;
  Map<String, bool> tagStates = Map<String, bool>();
  Map<String, bool> groupStates = Map<String, bool>();

  bool scaleOnce = false;
  List<QueryResult> queryResult = List<QueryResult>();
  List<QueryResult> filterResult = List<QueryResult>();

  static String prefix2Tag(String prefix) {
    switch (prefix) {
      case 'artist':
        return 'Artists';
      case 'group':
        return 'Groups';
      case 'language':
        return 'Language';
      case 'character':
        return 'Characters';
      case 'series':
        return 'Series';
      case 'class':
        return 'Class';
      case 'type':
        return 'Type';
      case 'uploader':
        return 'Uploader';
      case 'tag':
      case 'female':
      case 'male':
        return 'Tags';
    }
    return '';
  }

  static bool isSingleTag(String prefix) {
    switch (prefix) {
      case 'language':
      case 'series':
      case 'class':
      case 'type':
      case 'uploader':
        return true;
      case 'artist':
      case 'group':
      case 'character':
      case 'tag':
      case 'female':
      case 'male':
        return false;
    }
    return null;
  }

  List<QueryResult> filter() {
    if (!isFilterUsed) return queryResult;
    return filterResult;
  }

  int nowType = 3;

  Widget buildList() {
    var mm = nowType == 0 ? 3 : 2;
    var windowWidth = MediaQuery.of(context).size.width;
    switch (nowType) {
      case 0:
      case 1:
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: mm,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3 / 4,
            ),
            delegate: SliverChildListDelegate(filterResult.map((e) {
              return Padding(
                key: Key('group' +
                    widget.groupId.toString() +
                    '/' +
                    nowType.toString() +
                    '/' +
                    e.id().toString()),
                padding: EdgeInsets.zero,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    child: Provider<ArticleListItem>.value(
                      value: ArticleListItem.fromArticleListItem(
                        queryResult: e,
                        showDetail: false,
                        addBottomPadding: false,
                        width: (windowWidth - 4.0) / mm,
                        thumbnailTag: Uuid().v4(),
                        bookmarkMode: true,
                        bookmarkCallback: longpress,
                        bookmarkCheckCallback: check,
                        usableTabList: filterResult,
                        // isCheckMode: checkMode,
                        // isChecked: checked.contains(e.id()),
                      ),
                      child: ArticleListItemVerySimpleWidget(
                        isCheckMode: checkMode,
                        isChecked: checked.contains(e.id()),
                      ),
                    ),
                  ),
                ),
              );
            }).toList()),
          ),
        );

      case 2:
      case 3:
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate(filterResult.map((x) {
              return Align(
                key: Key('group' +
                    widget.groupId.toString() +
                    '/' +
                    nowType.toString() +
                    '/' +
                    x.id().toString()),
                alignment: Alignment.center,
                child: Provider<ArticleListItem>.value(
                  value: ArticleListItem.fromArticleListItem(
                    queryResult: x,
                    showDetail: nowType == 3,
                    addBottomPadding: true,
                    width: (windowWidth - 4.0),
                    thumbnailTag: Uuid().v4(),
                    bookmarkMode: true,
                    bookmarkCallback: longpress,
                    bookmarkCheckCallback: check,
                    usableTabList: filterResult,
                    // isCheckMode: checkMode,
                    // isChecked: checked.contains(x.id()),
                  ),
                  child: ArticleListItemVerySimpleWidget(
                    isCheckMode: checkMode,
                    isChecked: checked.contains(x.id()),
                  ),
                ),
              );
            }).toList()),
          ),
        );

      default:
        return Container(
          child: Center(
            child: Text('Error :('),
          ),
        );
    }
  }

  bool checkMode = false;
  bool checkModePre = false;
  List<int> checked = List<int>();

  void longpress(int article) {
    print(article);
    if (!checkMode) {
      checkMode = true;
      checkModePre = true;
      checked.add(article);
      setState(() {});
    }
  }

  void check(int article, bool check) {
    if (check)
      checked.add(article);
    else {
      checked.removeWhere((element) => element == article);
      if (checked.length == 0) {
        setState(() {
          checkModePre = false;
          checked.clear();
        });
        Future.delayed(Duration(milliseconds: 500)).then((value) {
          setState(() {
            checkMode = false;
          });
        });
      }
    }
  }

  Future<void> moveChecked() async {
    var groups = await (await Bookmark.getInstance()).getGroup();
    var currentGroup = widget.groupId;
    groups =
        groups.where((e) => e.id() != currentGroup && e.id() != 1).toList();
    int choose = -9999;
    if (await showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: Text(Translations.of(context).trans('wheretomove')),
                  actions: <Widget>[
                    RaisedButton(
                      color: Settings.majorColor,
                      child: new Text(Translations.of(context).trans('cancel')),
                      onPressed: () {
                        Navigator.pop(context, 0);
                      },
                    ),
                  ],
                  content: SizedBox(
                    width: 200,
                    height: 300,
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(groups[index].name()),
                          subtitle: Text(groups[index].description()),
                          onTap: () {
                            choose = index;
                            Navigator.pop(context, 1);
                          },
                        );
                      },
                    ),
                  ),
                )) ==
        1) {
      if (await Dialogs.yesnoDialog(
          context,
          Translations.of(context)
              .trans('movetoto')
              .replaceAll('%1', groups[choose].name())
              .replaceAll('%2', checked.length.toString()),
          Translations.of(context).trans('movebookmark'))) {
        // There is a way to change only the group, but there is also re-register a new bookmark.
        // I chose the latter to suit the user's intentions.

        // Atomic!!
        // 0. Sort Checked
        var invIdIndex = Map<int, int>();
        for (int i = 0; i < queryResult.length; i++)
          invIdIndex[queryResult[i].id()] = i;
        checked.sort((x, y) => invIdIndex[x].compareTo(invIdIndex[y]));

        // 1. Get bookmark articles on source groupid
        var bm = await Bookmark.getInstance();
        // var article = await bm.getArticle();
        // var src = article
        //     .where((element) => element.group() == currentGroup)
        //     .toList();

        // 2. Save source bookmark for fault torlerance!
        // final cacheDir = await getTemporaryDirectory();
        // final path = File('${cacheDir.path}/bookmark_cache+${Uuid().v4()}');
        // path.writeAsString(jsonEncode(checked));

        for (var e in checked.reversed) {
          // 3. Delete source bookmarks
          await bm.unbookmark(e);
          // 4. Add src bookmarks with new groupid
          await bm.insertArticle(
              e.toString(), DateTime.now(), groups[choose].id());
        }

        // 5. Update UI
        setState(() {
          checkModePre = false;
          checked.clear();
        });
        Future.delayed(Duration(milliseconds: 500)).then((value) {
          setState(() {
            checkMode = false;
          });
        });
        refresh();
      }
    } else {}
  }
}
