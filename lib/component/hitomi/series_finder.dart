// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:convert';

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/component/hitomi/title_cluster.dart';
import 'package:violet/database/query.dart';

class SeriesFinder {
  static Future<void> doFind1() async {
    final subdir = Platform.isAndroid ? '/data' : '';
    final directory = await getApplicationDocumentsDirectory();
    final path = File('${directory.path}$subdir/index.json');
    final text = path.readAsStringSync();
    final tagmap = jsonDecode(text);
    final artists = tagmap['artist'] as Map<String, dynamic>;
    final groups = tagmap['group'] as Map<String, dynamic>;
    final total = artists.length + groups.length;
    var index = 0;

    var series_list = <List<QueryResult>>[];

    for (var i = 0; i < artists.length; i++) {
      var kv = artists.entries.elementAt(i);
      print('[${++index}/$total] artist:${kv.key} ');

      if (kv.key.toLowerCase() == 'n/a') continue;

      final qm = QueryManager.queryPagination(HitomiManager.translate2query(
          'artist:${kv.key.replaceAll(' ', '_')}'));
      qm.itemsPerPage = 99999;
      final qr = await qm.next();

      if (qr.length == 1) continue;

      HitomiTitleCluster.doClustering(
              qr.map((e) => e.title() as String).toList())
          .toList()
          .where((element) => element.length > 1)
          .toList()
          .forEach((element) {
        series_list.add(element.map((e) => qr[e]).toList());
      });
    }

    for (var i = 0; i < groups.length; i++) {
      var kv = groups.entries.elementAt(i);
      print('[${++index}/$total] group:${kv.key}');

      if (kv.key.toLowerCase() == 'n/a') continue;

      final qm = QueryManager.queryPagination(HitomiManager.translate2query(
          'artist:${kv.key.replaceAll(' ', '_')}'));
      qm.itemsPerPage = 99999;
      final qr = await qm.next();

      if (qr.length == 1) continue;

      HitomiTitleCluster.doClustering(
              qr.map((e) => e.title() as String).toList())
          .toList()
          .where((element) => element.length > 1)
          .toList()
          .forEach((element) {
        series_list.add(element.map((e) => qr[e]).toList());
      });
    }

    series_list.sort((x, y) => x.length.compareTo(y.length));
    series_list.forEach((element) {
      print('[${element.length}] ${element.first.artists()}');
    });
  }

  static Future<void> doFind2() async {
    final qm = QueryManager.queryPagination(
        'SELECT Title, Artists, Groups FROM HitomiColumnModel');
    qm.itemsPerPage = 999999;
    final qr = await qm.next();

    final artists = Map<String, List<int>>();
    final groups = Map<String, List<int>>();

    for (int i = 0; i < qr.length; i++) {
      final element = qr[i];
      if (element.artists() != null && element.artists() != '') {
        (element.artists() as String)
            .split('|')
            .where((element) => element.isNotEmpty)
            .forEach((element) {
          if (!artists.containsKey(element)) artists[element] = <int>[];
          artists[element].add(i);
        });
      }
      if (element.groups() != null && element.groups() != '') {
        (element.groups() as String)
            .split('|')
            .where((element) => element.isNotEmpty)
            .forEach((element) {
          if (!groups.containsKey(element)) groups[element] = <int>[];
          groups[element].add(i);
        });
      }
    }

    var seriesList = <List<QueryResult>>[];

    for (var i = 0; i < artists.length; i++) {
      var kv = artists.entries.elementAt(i);

      if (kv.key.toLowerCase() == 'n/a') continue;

      if (kv.value.length == 1) continue;

      HitomiTitleCluster.doClustering(kv.value
              .map((e) => qr[e])
              .map((e) => e.title() as String)
              .toList())
          .toList()
          .where((element) => element.length > 1)
          .toList()
          .forEach((element) {
        seriesList.add(element.map((e) => qr[kv.value[e]]).toList());
      });
    }

    for (var i = 0; i < groups.length; i++) {
      var kv = groups.entries.elementAt(i);

      if (kv.key.toLowerCase() == 'n/a') continue;

      if (kv.value.length == 1) continue;

      HitomiTitleCluster.doClustering(kv.value
              .map((e) => qr[e])
              .map((e) => e.title() as String)
              .toList())
          .toList()
          .where((element) => element.length > 1)
          .toList()
          .forEach((element) {
        seriesList.add(element.map((e) => qr[kv.value[e]]).toList());
      });
    }

    seriesList.sort((x, y) => x.length.compareTo(y.length));
    seriesList.forEach((element) {
      print('[${element.length}] ${element.first.artists()}');
    });
  }
}
