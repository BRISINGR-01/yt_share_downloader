import 'dart:async';
// ignore_for_file: file_names

import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_share_downloader/components/SearchBar.dart';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:yt_share_downloader/components/Settings.dart';
import 'package:yt_share_downloader/components/YTWindow.dart';
import 'package:yt_share_downloader/components/shared/Loader.dart';
import 'package:yt_share_downloader/components/shared/VideoDownloader.dart';
import 'package:yt_share_downloader/utils/UserSettings.dart';
import 'package:yt_share_downloader/utils/VideoObject.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final bool _isMobile = Platform.isAndroid || Platform.isIOS;
  late StreamSubscription _intentDataStreamSubscription;

  UserSettings? _userSettings;
  String _url = "";
  VideoObject? _video;

  void _refreshSettings(UserSettings settings) {
    setState(() {
      _userSettings = settings;
    });
  }

  void _prepareDownload(String url) async {
    if (url.isEmpty) return;

    setState(() {
      _url = "";
      _video = VideoObject(url);
    });
  }

  void _finishVideoDownload() {
    setState(() {
      _video = null;
    });
  }

  @override
  void initState() {
    super.initState();
    UserSettings.init().then(_refreshSettings);

    void initDownload(String? url) {
      if (url != null) {
        setState(() {
          _video = VideoObject(url);
        });
      }
    }

    if (_isMobile) {
      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      _intentDataStreamSubscription =
          ReceiveSharingIntent.getTextStream().listen(initDownload);

      // For sharing or opening urls/text coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialText().then(initDownload);
    }
  }

  @override
  void dispose() {
    if (_isMobile) {
      _intentDataStreamSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userSettings == null) {
      return const Loader();
    } else {
      return SafeArea(
          child: Scaffold(
        appBar: AppBar(
          title: const Text("YT downloader"),
          actions: [
            if (Platform.isWindows)
              IconButton(
                  onPressed: () {
                    if (_userSettings != null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => YTWindow(
                              userSettings: _userSettings!,
                            ),
                          ));
                    }
                  },
                  icon: const Image(
                      image:
                          AssetImage('lib/assets/youtube_activity_icon.png'))),
            IconButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Settings(
                          refreshSettings: _refreshSettings,
                          userSettings: _userSettings!),
                    )).then((value) => setState(() {
                      _userSettings = UserSettings.fromMap(value);
                    })),
                icon: const Icon(Icons.settings))
          ],
        ),
        body: _video != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: VideoDownloader(
                  video: _video!,
                  userSettings: _userSettings!,
                  finish: () => _finishVideoDownload(),
                ),
              )
            : SearchBar(
                prepareDownload: _prepareDownload,
                url: _url,
              ),
      ));
    }
  }
}
