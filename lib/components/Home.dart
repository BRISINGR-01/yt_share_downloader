// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';
import 'package:yt_share_downloader/components/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:yt_share_downloader/components/Settings.dart';
import 'package:yt_share_downloader/components/Toast/toast_container.dart';
import 'package:yt_share_downloader/components/yt_window.dart';
import 'package:yt_share_downloader/components/shared/Loader.dart';
import 'package:yt_share_downloader/components/shared/video_downloader.dart';
import 'package:yt_share_downloader/utils/user_settings.dart';
import 'package:yt_share_downloader/utils/video_object.dart';

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
  final List<VideoObject> _queue = [];

  void _refreshSettings(UserSettings settings) {
    setState(() {
      _userSettings = settings;
    });
  }

  void _prepareDownload(String url) async {
    if (url.isEmpty) return;

    setState(() {
      _video = VideoObject(url);
      _url = "";
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
                      image: AssetImage('assets/youtube_activity_icon.png'))),
            const SizedBox(width: 12),
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
                icon: const Icon(Icons.settings)),
            const SizedBox(width: 12),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Flex(
              direction: Axis.vertical,
              children: [
                _video != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: VideoDownloader(
                          video: _video!,
                          userSettings: _userSettings!,
                          cancel: () => setState(() {
                            _video = null;
                          }),
                          addToQueue: () => setState(() {
                            _queue.add(_video!);
                            _video = null;
                          }),
                        ),
                      )
                    : SearchBar(
                        prepareDownload: _prepareDownload,
                        url: _url,
                      ),
              ],
            ),
            if (_userSettings != null)
              ToastContainer(
                videos: _queue,
                userSettings: _userSettings!,
                removeFromQueue: (url) => setState(
                    () => _queue.removeWhere((video) => video.url == url)),
              )
          ],
        ),
      ));
    }
  }
}
