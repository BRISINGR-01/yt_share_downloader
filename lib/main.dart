import 'package:flutter/material.dart';
import 'package:yt_share_downloader/components/home.dart';

void main() async {
  runApp(MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home()));
}
