// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:circular_check_box/circular_check_box.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:violet/component/hitomi/indexs.dart';
import 'package:violet/database/user/bookmark.dart';
import 'package:violet/database/user/record.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/log/log.dart';
import 'package:violet/pages/after_loading/afterloading_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:violet/other/dialogs.dart';
import 'package:violet/pages/database_download/database_download_page.dart';
import 'package:violet/pages/settings/settings_page.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/variables.dart';
import 'package:violet/version/sync.dart';
import 'package:violet/version/update_sync.dart';

class SplashPage extends StatefulWidget {
  final bool switching;

  SplashPage({this.switching = false});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool showFirst = false;
  bool animateBox = false;
  bool languageBox = false;
  bool showIndicator = false;
  int chunkDownloadMax = 0;
  int chunkDownloadProgress = 0;

  final imgSize = {
    'global': '320MB',
    'ko': '76MB',
    'en': '100MB',
    'jp': '165MB',
    'zh': '85MB',
  };

  final dbSuppors = {'global', 'ko', 'en', 'jp', 'zh'};

  final imgZipSize = {
    'global': '32MB',
    'ko': '9MB',
    'en': '10MB',
    'jp': '18MB',
    'zh': '9MB',
  };

  Future<void> checkAuth() async {
    if ((await SharedPreferences.getInstance()).getBool('checkauthalready') ==
        null) {
      await (await SharedPreferences.getInstance())
          .setBool('checkauthalready', true);
      if (await Permission.storage.request() == PermissionStatus.denied) {
        await Dialogs.okDialog(context, "파일 권한을 허용하지 않으면 다운로드 기능을 이용할 수 없습니다.");
      }
    }
  }

  startTime() async {
    var _duration = new Duration(milliseconds: 100);
    return new Timer(_duration, navigationPage);
  }

  Future<void> navigationPage() async {
    await Settings.init();
    await Bookmark.getInstance();
    await User.getInstance();
    await Variables.init();
    await HitomiIndexs.init();
    await Logger.init();

    if ((await SharedPreferences.getInstance()).getInt('db_exists') == 1 &&
        !widget.switching) {
      try {
        await SyncManager.checkSync();
        if (!SyncManager.firstSync && SyncManager.chunkRequire) {
          setState(() {
            showIndicator = true;
          });
          await SyncManager.doChunkSync((_, len) async {
            setState(() {
              chunkDownloadMax = len;
              chunkDownloadProgress++;
            });
          });
        }
      } catch (e, st) {
        // If an error occurs, stops synchronization immediately.
        // FirebaseCrashlytics.instance.recordError(e, st);
        Logger.error(
            '[Splash-Navigation] E: ' + e.toString() + '\n' + st.toString());
      }

      // We must show main page to user anyway
      Navigator.of(context).pushReplacementNamed('/AfterLoading');
    } else {
      if (!widget.switching) await Future.delayed(Duration(milliseconds: 1400));
      setState(() {
        showFirst = true;
      });
      await Future.delayed(Duration(milliseconds: 400));
      setState(() {
        animateBox = true;
      });
      await Future.delayed(Duration(milliseconds: 200));
      setState(() {
        languageBox = true;
      });
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
        scale1 = 1.03;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    startTime();
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          AfterLoadingPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.ease;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  bool userlangCheck = true;
  bool globalCheck = false;
  double scale1 = 1.0;
  double scale2 = 1.0;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return new Scaffold(
      body: Stack(
        children: <Widget>[
          AnimatedPositioned(
            duration: Duration(milliseconds: 1000),
            curve: Curves.ease,
            top: showFirst ? 130 : height / 2 - 50,
            left: width / 2 - 50,
            child: new Image.asset(
              'assets/images/logo-' +
                  _colorToString(Settings.majorColor) +
                  '.png',
              width: 100,
              height: 100,
            ),
          ),
          Visibility(
            visible: showIndicator,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 120),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('<< AutoSync >>',
                        style: TextStyle(color: Colors.white)),
                    Text(
                        chunkDownloadProgress != chunkDownloadMax ||
                                chunkDownloadMax == 0
                            ? 'Chunk downloading...[$chunkDownloadProgress/${SyncManager.getSyncRequiredChunkCount()}]'
                            : 'Extracting...',
                        style: TextStyle(color: Colors.white)),
                    Container(
                      height: 16,
                    ),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: showFirst,
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(top: 140),
                child: Card(
                  elevation: 100,
                  color: widget.switching
                      ? Settings.majorColor.withAlpha(150)
                      : Colors.purple.shade50,
                  child: AnimatedOpacity(
                    opacity: animateBox ? 1.0 : 0,
                    duration: Duration(milliseconds: 500),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.ease,
                      width: animateBox ? 300 : 300,
                      height: animateBox ? 300 : 0,
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 900),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: widget,
                            ),
                          ),
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(
                                  MdiIcons.database,
                                  size: 50,
                                  color: widget.switching
                                      ? Settings.majorAccentColor
                                          .withOpacity(0.8)
                                      : Colors.grey,
                                ),
                                Container(
                                  padding: EdgeInsets.all(4),
                                ),
                                Expanded(
                                    child: Text(
                                  widget.switching
                                      ? '${Translations.of(context).trans('database')} ${Translations.of(context).trans('switching')}'
                                      : Translations.of(context)
                                          .trans('welcome'),
                                  maxLines: 4,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                            ),
                            AnimatedContainer(
                              transform: Matrix4.identity()
                                ..translate(300 / 2, 50 / 2)
                                ..scale(scale1)
                                ..translate(-300 / 2, -50 / 2),
                              duration: Duration(milliseconds: 300),
                              child: Card(
                                elevation: 4,
                                child: InkWell(
                                  customBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(3.0))),
                                  child: ListTile(
                                    leading: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: 44,
                                        minHeight: 44,
                                        maxWidth: 44,
                                        maxHeight: 44,
                                      ),
                                      child: CircularCheckBox(
                                        value: userlangCheck,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.padded,
                                        onChanged: (bool value) {
                                          setState(() {
                                            scale1 = 1.03;
                                            scale2 = 1.0;
                                            if (userlangCheck) return;
                                            userlangCheck = !userlangCheck;
                                            globalCheck = false;
                                          });
                                        },
                                      ),
                                    ),
                                    dense: true,
                                    title: Text(
                                        Translations.of(context)
                                            .trans('dbuser'),
                                        style: TextStyle(fontSize: 14)),
                                    subtitle: Text(
                                        '${imgZipSize['ko']}${Translations.of(context).trans('dbdownloadsize')}',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  onTapDown: (detail) {
                                    setState(() {
                                      scale1 = 0.95;
                                    });
                                  },
                                  onTap: () {
                                    setState(() {
                                      scale1 = 1.03;
                                      scale2 = 1.0;
                                      if (userlangCheck) return;
                                      userlangCheck = !userlangCheck;
                                      globalCheck = false;
                                    });
                                  },
                                  onLongPress: () async {
                                    setState(() {
                                      if (userlangCheck)
                                        scale1 = 1.03;
                                      else
                                        scale1 = 1.0;
                                    });
                                    await Dialogs.okDialog(
                                        context,
                                        Translations.of(context)
                                            .trans('dbusermsg')
                                            .replaceFirst(
                                                '%s',
                                                imgSize[Translations.of(context)
                                                    .dbLanguageCode]));
                                  },
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              transform: Matrix4.identity()
                                ..translate(300 / 2, 50 / 2)
                                ..scale(scale2)
                                ..translate(-300 / 2, -50 / 2),
                              child: Card(
                                elevation: 4,
                                child: InkWell(
                                  customBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(3.0))),
                                  child: ListTile(
                                    leading: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: 44,
                                        minHeight: 44,
                                        maxWidth: 44,
                                        maxHeight: 44,
                                      ),
                                      child: CircularCheckBox(
                                        value: globalCheck,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.padded,
                                        onChanged: (bool value) {
                                          setState(() {
                                            scale2 = 1.03;
                                            scale1 = 1.0;
                                            if (globalCheck) return;
                                            globalCheck = !globalCheck;
                                            userlangCheck = false;
                                          });
                                        },
                                      ),
                                    ),
                                    dense: true,
                                    title: Text(
                                        Translations.of(context)
                                            .trans('dballname'),
                                        style: TextStyle(fontSize: 14)),
                                    subtitle: Text(
                                        '${imgZipSize['global']}${Translations.of(context).trans('dbdownloadsize')}',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  onTapDown: (detail) {
                                    setState(() {
                                      scale2 = 0.95;
                                    });
                                  },
                                  onTap: () {
                                    setState(() {
                                      scale2 = 1.03;
                                      scale1 = 1.0;
                                      if (globalCheck) return;
                                      globalCheck = !globalCheck;
                                      userlangCheck = false;
                                    });
                                  },
                                  onLongPress: () async {
                                    setState(() {
                                      if (globalCheck)
                                        scale2 = 1.03;
                                      else
                                        scale2 = 1.0;
                                    });
                                    await Dialogs.okDialog(
                                        context,
                                        Translations.of(context)
                                            .trans('dballmsg')
                                            .replaceFirst(
                                                '%s', imgSize['global']));
                                  },
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 16, 0),
                                child: RaisedButton(
                                  textColor: Colors.white,
                                  child: SizedBox(
                                    width: 90,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Text(Translations.of(context)
                                            .trans('download')),
                                        Icon(Icons.keyboard_arrow_right),
                                      ],
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (globalCheck) {
                                      if (!await Dialogs.yesnoDialog(
                                          context,
                                          Translations.of(context)
                                              .trans('dbwarn'),
                                          Translations.of(context)
                                              .trans('warning'))) {
                                        return;
                                      }
                                    }
                                    if (widget.switching) {
                                      var dir =
                                          await getApplicationDocumentsDirectory();
                                      try {
                                        await ((await openDatabase(
                                                '${dir.path}/data/data.db'))
                                            .close());
                                        await deleteDatabase(
                                            '${dir.path}/data/data.db');
                                        await Directory('${dir.path}/data')
                                            .delete(recursive: true);
                                      } catch (e) {}
                                    }
                                    print(Translations.of(context)
                                        .dbLanguageCode);
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                DataBaseDownloadPage(
                                                  dbType: globalCheck
                                                      ? 'global'
                                                      : Translations.of(context)
                                                          .dbLanguageCode,
                                                  isExistsDataBase: false,
                                                )));
                                  },
                                  color: widget.switching
                                      ? Settings.majorColor.withAlpha(200)
                                      : Colors.purple.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: languageBox ? 1.0 : 0.0,
            duration: Duration(milliseconds: 700),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 100),
                child: GestureDetector(
                  child: SizedBox(
                    child: Text(Translations.of(context).trans('dbalready'),
                        style: TextStyle(
                            color: widget.switching
                                ? Settings.majorAccentColor
                                : Colors.purpleAccent.shade100,
                            fontSize: 12.0)),
                  ),
                  onTap: () async {
                    var path = await getFile();

                    if (path == '') return;
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => DataBaseDownloadPage(
                              dbType: globalCheck
                                  ? 'global'
                                  : Translations.of(context)
                                      .locale
                                      .languageCode,
                              isExistsDataBase: true,
                              dbPath: path,
                            )));
                  },
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: languageBox ? 1.0 : 0.0,
            duration: Duration(milliseconds: 700),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: InkWell(
                  customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                  child: SizedBox(
                    width: 150,
                    height: 50,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.language,
                          size: 35,
                          color: Colors.white70,
                        ),
                        Text('  Language',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Theme(
                          data: Theme.of(context)
                              .copyWith(primaryColor: Colors.pink),
                          child: CountryPickerDialog(
                              titlePadding: EdgeInsets.symmetric(vertical: 16),
                              // searchCursorColor: Colors.pinkAccent,
                              // searchInputDecoration:
                              //     InputDecoration(hintText: 'Search...'),
                              // isSearchable: true,
                              title: Text('Select Language'),
                              onValuePicked: (Country country) async {
                                var exc = country as ExCountry;
                                await Translations.of(context)
                                    .load(exc.toString());
                                await Settings.setLanguage(exc.toString());
                                setState(() {});
                              },
                              itemFilter: (c) => [].contains(c.isoCode),
                              priorityList: [
                                ExCountry.create('US'),
                                ExCountry.create('KR'),
                                ExCountry.create('JP'),
                                ExCountry.create('CN', script: 'Hant'),
                                ExCountry.create('CN', script: 'Hans'),
                                // ExCountry.create('IT'),
                                // ExCountry.create('ES'),
                                // CountryPickerUtils.getCountryByIsoCode('RU'),
                              ],
                              itemBuilder: (Country country) {
                                return Container(
                                  child: Row(
                                    children: <Widget>[
                                      CountryPickerUtils.getDefaultFlagImage(
                                          country),
                                      SizedBox(
                                        width: 8.0,
                                        height: 30,
                                      ),
                                      Text(
                                          "${(country as ExCountry).getDisplayLanguage()}"),
                                    ],
                                  ),
                                );
                              })),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: showFirst && !widget.switching
          ? Color(0x7FB200ED)
          : Settings.majorColor.withAlpha(200),
    );
  }

  Future<String> getFile() async {
    File file;
    file = await FilePicker.getFile(
      type: FileType.any,
    );

    if (file == null) {
      await Dialogs.okDialog(
          context, Translations.of(context).trans('dbalreadyerr'));
      return '';
    }

    return file.path;
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
}
