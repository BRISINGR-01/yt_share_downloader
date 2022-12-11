import 'dart:async';
// ignore_for_file: file_names

import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_share_downloader/components/Loader.dart';
import 'package:yt_share_downloader/components/SearchBar.dart';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:yt_share_downloader/components/Settings.dart';
import 'package:yt_share_downloader/components/VideoDisplay.dart';
import 'package:yt_share_downloader/utils/UserSettings.dart';
import 'package:yt_share_downloader/utils/VideoInstance.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final bool _isMobile = Platform.isAndroid || Platform.isIOS;
  late StreamSubscription _intentDataStreamSubscription;

  final YoutubeExplode _yt = YoutubeExplode();
  UserSettings? _userSettings;
  String _url = "";
  final List<VideoInstance> _queue = [];

  void _refreshSettings(UserSettings settings) {
    setState(() {
      _userSettings = settings;
    });
  }

  void _prepareDownload(String url) async {
    if (url.isEmpty) return;

    int videoIndex = _queue.indexWhere((video) => video.url == url);
    if (videoIndex != -1) {
      if (_queue[videoIndex].state == VideoState.done) {
        _queue.removeAt(videoIndex);
      } else {
        return;
      }
    }

    VideoInstance newVideo = VideoInstance(url, _yt, _userSettings);

    setState(() {
      _queue.add(newVideo);
    });
  }

  void _removeVideoFromQueue(String url) {
    setState(() {
      _queue.removeWhere((video) => video.url == url);
    });
  }

  void _clearUrl() {
    setState(() {
      _url = "";
    });
  }

  @override
  void initState() {
    super.initState();
    UserSettings.init().then(_refreshSettings);

    void setUrl(String? url) {
      if (url != null) {
        setState(() {
          _url = url;
        });
      }
    }

    if (_isMobile) {
      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      _intentDataStreamSubscription =
          ReceiveSharingIntent.getTextStream().listen(setUrl);

      // For sharing or opening urls/text coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialText().then(setUrl);
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
            IconButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Settings(
                          refreshSettings: _refreshSettings,
                          userSettings: _userSettings!),
                    )).then((value) => setState(() {
                      _userSettings = UserSettings(
                          chosenDirectoryForDownload:
                              value["chosenDirectoryForDownload"],
                          customDownloadDirectoryPath:
                              value["customDownloadDirectoryPath"],
                          audioOnly: value["audioOnly"],
                          canDownloadUsingMobileData:
                              value["canDownloadUsingMobileData"]);
                    })),
                icon: const Icon(Icons.settings))
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBar(
                prepareDownload: _prepareDownload,
                clearUrl: _clearUrl,
                url: _url,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  for (VideoInstance video in _queue)
                    VideoDisplay(
                      video: video,
                      userSettings: _userSettings!,
                      removeVideoFromQueue: () =>
                          _removeVideoFromQueue(video.url),
                    )
                ]),
              )
            ],
          ),
        ),
      ));
    }
  }
}
