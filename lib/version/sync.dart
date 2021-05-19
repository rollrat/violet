// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:collection';
import 'dart:convert';

// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/database/database.dart';
import 'package:violet/database/query.dart';
import 'package:violet/log/log.dart';
import 'package:violet/network/wrapper.dart' as http;
import 'package:violet/settings/settings.dart';

typedef DoubleIntCallback = Future Function(int, int);

class SyncInfoRecord {
  final String type;
  final int timestamp;
  final String url;
  final int size;

  SyncInfoRecord({this.type, this.timestamp, this.url, this.size = 0});

  String getDBDownloadUrl(String type) =>
      url + SyncManager.createRawdbPostfix(type);
  String getDBDownloadUrliOS(String type) =>
      url + SyncManager.createRawdbPostfixiOS(type);

  DateTime getDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }
}

class SyncManager {
  static const String syncInfoURL = "https://koromo.xyz/version.txt";

  static bool firstSync = false;
  static bool syncRequire = false; // database sync require
  static bool chunkRequire = false;
  static const ignoreUserAcceptThreshold = 1024 * 1024 * 10; // 10MB
  static List<SyncInfoRecord> _rows;
  static int requestSize = 0;

  static Future<void> checkSync() async {
    try {
      var ls = new LineSplitter();
      var infoRaw = (await http.get(syncInfoURL)).body;
      var lines = ls.convert(infoRaw);

      var latest = (await SharedPreferences.getInstance()).getInt('synclatest');
      var lastDB =
          (await SharedPreferences.getInstance()).getString('databasesync');

      if (latest == null) {
        syncRequire = firstSync = true;
        latest = 0;
      } else if (DateTime.parse(lastDB).difference(DateTime.now()).inDays > 7) {
        syncRequire = true;
      }

      // lines: [old ... latest]
      // _rows: [latest ... old]
      _rows = List<SyncInfoRecord>();

      lines.reversed.forEach((element) {
        if (element.startsWith('#')) return;

        var split = element.split(' ');
        var type = split[0];
        var timestamp = int.parse(split[1]);
        var url = split[2];
        var size = 0;
        if (type == 'chunk') size = int.parse(split[3]);

        // We require only json files when synchronize with chunk.
        if (type == 'chunk' && !url.endsWith('.json')) return;
        if (type == 'chunk' && timestamp <= latest) return;

        requestSize += size;
        _rows.add(SyncInfoRecord(
          type: type,
          timestamp: timestamp,
          url: url,
          size: size,
        ));
      });

      if (requestSize > ignoreUserAcceptThreshold) syncRequire = true;
      if (_rows.any((element) => element.type == 'chunk')) chunkRequire = true;
    } catch (e, st) {
      Logger.error('[Sync-check] E: ' + e.toString() + '\n' + st.toString());
    }
  }

  static SyncInfoRecord getLatestDB() {
    if (_rows != null) {
      for (int i = 0; i < _rows.length; i++)
        if (_rows[i].type == 'db') return _rows[i];
    }

    return SyncInfoRecord(
      type: 'db',
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(0).millisecondsSinceEpoch ~/ 1000,
      url: '',
    );
  }

  static int getSyncRequiredChunkCount() {
    if (_rows == null) return 0;
    return _rows.where((element) => element.type == 'chunk').toList().length;
  }

  static Future<void> doChunkSync(DoubleIntCallback progressCallback) async {
    // Only chunk
    var filteredIter =
        _rows.where((element) => element.type == 'chunk').toList();

    // Download Jsons
    var res = await Future.wait(
        filteredIter.map((e) => http.get(e.url).then((value) async {
              await progressCallback(0, filteredIter.length);
              return value;
            })));
    var jsons = res.map((e) => utf8.decode(e.bodyBytes)).toList();

    // Update Database
    try {
      for (int i = 0; i < filteredIter.length; i++) {
        // Larger timestamp, the more recent data is contained.
        // So, we need to update them in old order.
        var row = filteredIter[filteredIter.length - i - 1];
        if (row.type != 'chunk') continue;

        // First, parse json
        var json = jsonDecode(jsons[filteredIter.length - i - 1]);

        // Second, convert json to query
        var qlist = json as List<dynamic>;
        var quries = qlist
            .map((e) => QueryResult(result: e as Map<String, dynamic>))
            .toList();

        // Third, filtering records with language
        var lang = translateToLanguage(Settings.databaseType);
        if (lang != '') {
          quries = quries.where((element) {
            var ll = element.language() as String;
            return (ll == lang) || (ll == 'n/a');
          }).toList();
        }

        // Last, append datas
        var db = await DataBaseManager.getInstance();
        var dbraw = await openDatabase(db.dbPath);
        await dbraw.transaction((txn) async {
          final batch = txn.batch();
          for (var query in quries)
            batch.insert('HitomiColumnModel', query.result,
                conflictAlgorithm: ConflictAlgorithm.replace);
          await batch.commit();
        });
        await dbraw.close();

        await (await SharedPreferences.getInstance())
            .setInt('synclatest', row.timestamp);
      }

      if (filteredIter.length > 0) {
        var sql = HitomiManager.translate2query(Settings.includeTags +
            ' ' +
            Settings.excludeTags
                .where((e) => e.trim() != '')
                .map((e) => '-$e')
                .join(' '));

        await (await DataBaseManager.getInstance()).delete('HitomiColumnModel',
            'NOT (${sql.substring(sql.indexOf('WHERE') + 6)})', []);
      }
    } catch (e, st) {
      // If an error occurs, stops synchronization immediately.
      Logger.error('[Sync-chunk] E: ' + e.toString() + '\n' + st.toString());
      // FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  static String createRawdbPostfix(String lang) {
    switch (lang) {
      case 'global':
        return '.7z';
      case 'ko':
        return '-korean.7z';
      case 'zh':
        return '-chinese.7z';
      case 'ja':
        return '-japanese.7z';
      case 'en':
        return '-english.7z';
    }

    throw Exception('not reachable');
  }

  static String createRawdbPostfixiOS(String lang) {
    switch (lang) {
      case 'global':
        return '.db';
      case 'ko':
        return '-korean.db';
      case 'zh':
        return '-chinese.db';
      case 'ja':
        return '-japanese.db';
      case 'en':
        return '-english.db';
    }

    throw Exception('not reachable');
  }

  static String translateToLanguage(String lang) {
    switch (lang) {
      case 'global':
        return '';
      case 'ko':
        return 'korean';
      case 'zh':
        return 'chinese';
      case 'ja':
        return 'japanese';
      case 'en':
        return 'english';
    }

    throw Exception('not reachable');
  }
}
