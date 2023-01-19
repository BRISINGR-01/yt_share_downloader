// ignore_for_file: file_names

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:yt_share_downloader/components/Toast/toast_container.dart';
import 'package:yt_share_downloader/components/shared/Loader.dart';
import 'package:yt_share_downloader/components/shared/displayed_error.dart';
import 'package:yt_share_downloader/components/shared/video_downloader.dart';
import 'package:yt_share_downloader/utils/user_settings.dart';
import 'package:yt_share_downloader/utils/video_object.dart';

class YTWindow extends StatefulWidget {
  final UserSettings userSettings;
  const YTWindow({Key? key, required this.userSettings}) : super(key: key);

  @override
  YTWindowState createState() => YTWindowState();
}

class YTWindowState extends State<YTWindow> {
  final _controller = WebviewController();
  VideoObject? _video;
  DisplayedError? _error;
  String _url = 'https://www.youtube.com/';
  bool _isLoading = false;
  final List<VideoObject> _queue = [];

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _prepareDownload() async {
    if (_url != "https://www.youtube.com/" &&
        _queue.every((vid) => vid.url != _url)) {
      setState(() => _isLoading = true);

      VideoObject video = VideoObject(_url);
      DisplayedError? error = await video.loadData(widget.userSettings);

      if (error != null) {
        setState(() => _isLoading = false);
        _queue.add(video);
      } else {
        setState(() {
          _video = video;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initPlatformState() async {
    try {
      await _controller.initialize();
      _controller.url.listen((url) {
        _url = url;
      });

      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl('https://www.youtube.com/');

      if (mounted) setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('Error'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${e.code}'),
                      Text('Message: ${e.message}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Continue'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube direct')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isLoading
                      ? const Loader()
                      : _video == null
                          ? IconButton(
                              onPressed: _prepareDownload,
                              icon: const Icon(Icons.youtube_searched_for))
                          : VideoDownloader(
                              video: _video!,
                              userSettings: widget.userSettings,
                              cancel: () => setState(() {
                                _video = null;
                              }),
                              addToQueue: () => setState(() {
                                _queue.add(_video!);
                                _video = null;
                              }),
                            ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Card(
                        color: Colors.transparent,
                        elevation: 0,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: Webview(
                          _controller,
                          permissionRequested: (_, __, ___) async =>
                              WebviewPermissionDecision.allow,
                        )),
                  ),
                ],
              ),
              ToastContainer(
                videos: _queue,
                userSettings: widget.userSettings,
                removeFromQueue: (url) => setState(
                    () => _queue.removeWhere((video) => video.url == url)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
