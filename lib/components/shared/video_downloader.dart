// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:yt_share_downloader/components/shared/displayed_error.dart';
import 'package:yt_share_downloader/components/shared/Loader.dart';
import 'package:yt_share_downloader/components/shared/file_name_input.dart';
import 'package:yt_share_downloader/utils/user_settings.dart';
import 'package:yt_share_downloader/utils/video_object.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class VideoDownloader extends StatefulWidget {
  final VideoObject video;
  final UserSettings userSettings;
  final Function cancel;
  final Function addToQueue;
  final bool mini;
  const VideoDownloader({
    Key? key,
    required this.video,
    required this.userSettings,
    required this.cancel,
    required this.addToQueue,
    this.mini = false,
  }) : super(key: key);

  @override
  VideoDownloaderState createState() => VideoDownloaderState();
}

class VideoDownloaderState extends State<VideoDownloader> {
  DisplayedError? _error;
  late VideoObject _video;
  VideoState _state = VideoState.loadingData;

  @override
  void initState() {
    super.initState();
    _video = widget.video;

    _video.loadData(widget.userSettings).then((error) {
      if (error != null) {
        widget.addToQueue();
      } else {
        setState(() {
          _state = VideoState.waitingForApproval;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: _error != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      _error!.widget,
                      IconButton(
                        onPressed: () => widget.cancel,
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                      )
                    ])
              : _state == VideoState.loadingData
                  ? const Loader()
                  : _state == VideoState.waitingForApproval
                      ? FileNameInput(
                          cancel: widget.cancel,
                          download: widget.addToQueue,
                          fileNameMode: widget.userSettings.fileNameMode,
                          video: _video,
                        )
                      : const Loader()),
    );
  }
}
