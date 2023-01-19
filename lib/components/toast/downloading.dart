import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:yt_share_downloader/components/shared/displayed_error.dart';
import 'package:yt_share_downloader/utils/user_settings.dart';
import 'package:yt_share_downloader/utils/video_object.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class Downloading extends StatefulWidget {
  final VideoObject video;
  final UserSettings userSettings;
  final Function cancel;
  final Function(VideoState) setVideoState;
  final Function(DisplayedError) setError;
  const Downloading({
    Key? key,
    required this.video,
    required this.userSettings,
    required this.cancel,
    required this.setVideoState,
    required this.setError,
  }) : super(key: key);

  @override
  State<Downloading> createState() => _DownloadingState();
}

class _DownloadingState extends State<Downloading> {
  double _progress = 0;

  _updateProgress(double progress) {
    if (progress == 100) widget.setVideoState(VideoState.done);

    if (mounted) setState(() => _progress = progress);
  }

  @override
  void initState() {
    super.initState();
    widget.video
        .download(
      widget.userSettings,
      _updateProgress,
    )
        .then((error) {
      if (error != null) {
        widget.setError(error);
      } else {
        widget.setVideoState(VideoState.done);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: Colors.black,
            width: 1,
          ),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                widget.video.title,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
              Row(
                children: [
                  Expanded(
                      child: LinearPercentIndicator(
                    lineHeight: 20,
                    percent: _progress,
                    progressColor: Colors.lightBlueAccent,
                    center: Text(
                      "${(_progress * 100).round()}%",
                    ),
                    barRadius: const Radius.circular(10),
                    clipLinearGradient: true,
                  )),
                  IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        widget.cancel();
                        widget.video.cancelDownload();
                      }),
                ],
              ),
            ],
          ),
        ));
  }
}
