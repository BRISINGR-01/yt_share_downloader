import 'package:flutter/material.dart';
import 'package:yt_share_downloader/components/Home.dart';

void main() {
  runApp(MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home()));
}
