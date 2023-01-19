import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yt_share_downloader/components/Toast/done.dart';
import 'package:yt_share_downloader/components/Toast/downloading.dart';
import 'package:yt_share_downloader/components/shared/displayed_error.dart';
import 'package:yt_share_downloader/components/shared/Loader.dart';
import 'package:yt_share_downloader/utils/user_settings.dart';
import 'package:yt_share_downloader/utils/video_object.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class Toast extends StatefulWidget {
  final VideoObject video;
  final UserSettings userSettings;
  final Function({bool skipAnimation}) remove;
  const Toast({
    Key? key,
    required this.video,
    required this.remove,
    required this.userSettings,
  }) : super(key: key);

  @override
  ToastState createState() => ToastState();
}

class ToastState extends State<Toast> {
  VideoState _state = VideoState.downloading;
  DisplayedError? _error;
  Timer? timer;

  _hideIn(int seconds) {
    // timer = Timer(Duration(seconds: seconds), () => widget.remove());
  }

  _setVideoState(VideoState state) {
    if (!mounted) return;

    if (state == VideoState.done) {
      _hideIn(2);
    }

    setState(() {
      _state = state;
    });
  }

  _setError(DisplayedError error) {
    if (!mounted) return;

    _hideIn(4);

    setState(() {
      _error = error;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.video.error != null) {
      _error = widget.video.error;
      _hideIn(2);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Opacity(
        opacity: .93,
        child: Card(
          color: Colors.red,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _error!.widget,
          ),
        ),
      );
    }

    switch (_state) {
      case VideoState.deleting:
        return const Loader();
      case VideoState.downloading:
        return Downloading(
          video: widget.video,
          userSettings: widget.userSettings,
          setVideoState: _setVideoState,
          setError: _setError,
          cancel: () {
            widget.video.cancelDownload();
            widget.remove(skipAnimation: true);
          },
        );
      case VideoState.done:
        return Done(
            title: widget.video.title,
            delete: () {
              timer?.cancel();
              _setVideoState(VideoState.deleting);
              widget.video.delete().then((error) {
                if (error != null) {
                  _setError(error);
                } else {
                  _setVideoState(VideoState.done);
                }
              });
            });
      case VideoState.loadingData:
      case VideoState.waitingForApproval:
      case VideoState.none:
        return Container();
    }
  }
}
