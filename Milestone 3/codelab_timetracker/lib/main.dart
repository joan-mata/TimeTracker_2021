import 'package:codelab_timetracker/PageActivities.dart';
import 'package:codelab_timetracker/PageIntervals.dart';
import 'package:codelab_timetracker/PageTaskDetail.dart';
import 'package:flutter/material.dart';

import 'PageTaskDetail.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeTracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: TextTheme(
            subtitle1: TextStyle(fontSize: 20.0),
            bodyText2: TextStyle(fontSize: 20.0)),
      ),
      home: PageActivities(0),
      //home: PageIntervals(6),
      //home: PageTaskDetail(6),
    );
  }
}