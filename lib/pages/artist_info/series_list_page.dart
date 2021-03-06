// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:violet/database/query.dart';
import 'package:violet/pages/artist_info/article_list_page.dart';
import 'package:violet/pages/segment/card_panel.dart';
import 'package:violet/pages/segment/three_article_panel.dart';

class SeriesListPage extends StatelessWidget {
  final String prefix;
  final List<List<int>> series;
  final List<QueryResult> cc;

  SeriesListPage({this.prefix, this.series, this.cc});

  @override
  Widget build(BuildContext context) {
    var unescape = HtmlUnescape();

    return CardPanel.build(
      context,
      child: Container(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
          physics: ClampingScrollPhysics(),
          itemCount: series.length,
          itemBuilder: (BuildContext ctxt, int index) {
            var e = series[index];

            return ThreeArticlePanel(
              tappedRoute: () => ArticleListPage(
                  cc: e.map((e) => cc[e]).toList(), name: 'Series'),
              title: ' ${unescape.convert(cc[e[0]].title())}',
              count: '${e.length} ',
              articles: e.map((e) => cc[e]).toList(),
            );
          },
        ),
      ),
    );
  }
}
