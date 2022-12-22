// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:yt_share_downloader/components/shared/VideoDownloader.dart';
import 'package:yt_share_downloader/utils/UserSettings.dart';
import 'package:yt_share_downloader/utils/VideoObject.dart';

class YTWindow extends StatefulWidget {
  final UserSettings userSettings;
  const YTWindow({Key? key, required this.userSettings}) : super(key: key);

  @override
  YTWindowState createState() => YTWindowState();
}

class YTWindowState extends State<YTWindow> {
  final _controller = WebviewController();
  String _url = 'https://www.youtube.com/';
  VideoObject? _video;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _prepareDownload() {
    if (_url != "https://www.youtube.com/") {
      setState(() {
        _video = VideoObject(_url);
        _video!.loadData(widget.userSettings);
      });
    }
  }

  void _finishDownload() {
    setState(() {
      _video = null;
    });
  }

  Future<void> initPlatformState() async {
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
      appBar: AppBar(title: const Text('YT Viewer')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _video == null
                  ? IconButton(
                      onPressed: _prepareDownload,
                      icon: const Icon(Icons.youtube_searched_for))
                  : VideoDownloader(
                      video: _video!,
                      finish: _finishDownload,
                      userSettings: widget.userSettings,
                    ),
              const SizedBox(height: 10),
              Expanded(
                  child: Card(
                      color: Colors.transparent,
                      elevation: 0,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: Stack(
                        children: [
                          Webview(
                            _controller,
                            permissionRequested: (String url,
                                WebviewPermissionKind kind,
                                bool isUserInitiated) async {
                              return WebviewPermissionDecision.allow;
                            },
                          ),
                        ],
                      ))),
            ],
          ),
        ),
      ),
    );
  }
}
