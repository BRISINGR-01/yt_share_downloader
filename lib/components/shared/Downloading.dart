import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:yt_share_downloader/utils/VideoObject.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class Downloading extends StatelessWidget {
  final double progress;
  final VideoObject video;
  final VideoState state;
  final Function deleteFile;
  final Function? removeVideoFromQueue;
  const Downloading({
    Key? key,
    required this.progress,
    required this.video,
    required this.deleteFile,
    required this.state,
    required this.removeVideoFromQueue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(video.fileName),
        Row(
          children: [
            IconButton(
                icon: Icon(
                  Icons.delete,
                  color: state == VideoState.downloading
                      ? Colors.redAccent.shade100
                      : Colors.red,
                ),
                onPressed: () => deleteFile()),
            Expanded(
                child: LinearPercentIndicator(
              lineHeight: 20,
              percent: progress,
              progressColor: Colors.lightBlueAccent,
              center: Text(
                "${(progress * 100).round()}%",
              ),
              barRadius: const Radius.circular(10),
              clipLinearGradient: true,
            )),
            IconButton(
                icon: Icon(
                  Icons.cancel,
                  color: state == VideoState.downloading
                      ? Colors.blueGrey.shade100
                      : Colors.blueGrey.shade300,
                ),
                onPressed: state == VideoState.downloading
                    ? null
                    : () {
                        if (removeVideoFromQueue != null) {
                          removeVideoFromQueue!();
                        }
                      }),
          ],
        ),
      ],
    );
  }
}
