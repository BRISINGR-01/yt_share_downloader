import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yt_share_downloader/components/Loader.dart';
import 'package:yt_share_downloader/utils/UserSettings.dart';
import 'package:yt_share_downloader/utils/VideoInstance.dart';
import 'package:yt_share_downloader/utils/utils.dart';
import 'package:percent_indicator/percent_indicator.dart';

class VideoDisplay extends StatefulWidget {
  final VideoInstance video;
  final UserSettings userSettings;
  final Function removeVideoFromQueue;
  const VideoDisplay(
      {Key? key,
      required this.video,
      required this.userSettings,
      required this.removeVideoFromQueue})
      : super(key: key);

  @override
  VideoDisplayState createState() => VideoDisplayState();
}

class VideoDisplayState extends State<VideoDisplay> {
  late String fileName;
  double progress = 0;
  AppError? error;
  final bool isMobile = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();

    widget.video.loadData(widget.userSettings).then((result) => setState(() {
          error = result["error"];
          fileName = result["fileName"];
        }));
  }

  updateProgress(double newProgress) {
    setState(() {
      progress = newProgress;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Row(
        children: [
          Flexible(
            child: Text(
              error!.text,
              style: const TextStyle(color: Colors.red, fontSize: 20),
            ),
          ),
          IconButton(
              onPressed: widget.video.state == VideoState.done
                  ? () => widget.video
                      .delete(fileName, widget.userSettings.downloadsDirectory)
                      .then((deleteError) => setState(() {
                            error = deleteError;
                          }))
                  : widget.video.state == VideoState.loadingData
                      ? () => widget.video
                          .loadData(widget.userSettings)
                          .then((result) => setState(() {
                                error = result["error"];
                                fileName = result["fileName"];
                              }))
                      : () => widget.video
                          .download(
                              fileName, widget.userSettings, updateProgress)
                          .then((downloadError) => setState(() {
                                error = downloadError;
                              })),
              icon: const Icon(
                Icons.replay_rounded,
                color: Colors.red,
              )),
          IconButton(
              icon: const Icon(
                Icons.cancel,
              ),
              color: Colors.blueGrey.shade300,
              onPressed: () => widget.removeVideoFromQueue()),
        ],
      );
    }
    if (widget.video.state == VideoState.loadingData) {
      return const Loader();
    }
    if (widget.video.state == VideoState.downloading ||
        widget.video.state == VideoState.done) {
      return VideoDisplayWrapper(
        title: fileName,
        children: [
          Row(
            children: [
              IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: widget.video.state == VideoState.downloading
                        ? Colors.redAccent.shade100
                        : Colors.red,
                  ),
                  onPressed: widget.video.state == VideoState.downloading
                      ? null
                      : () => widget.video
                              .delete(fileName,
                                  widget.userSettings.downloadsDirectory)
                              .then((deleteError) {
                            if (deleteError == null) {
                              widget.removeVideoFromQueue();
                            } else {
                              setState(() {
                                error = deleteError;
                              });
                            }
                          })),
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
                ),
              ),
              IconButton(
                  icon: Icon(
                    Icons.cancel,
                    color: widget.video.state == VideoState.downloading
                        ? Colors.blueGrey.shade100
                        : Colors.blueGrey.shade300,
                  ),
                  onPressed: widget.video.state == VideoState.downloading
                      ? null
                      : () => widget.removeVideoFromQueue()),
            ],
          )
        ],
      );
    } else {
      return VideoDisplayWrapper(
        title:
            "${widget.video.title}\n${widget.video.artist.isNotEmpty ? "by ${widget.video.artist}" : ""}",
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: isMobile ? 0 : null,
            leading: IconButton(
                onPressed: () => widget.video
                    .download(fileName, widget.userSettings, updateProgress)
                    .then((downloadError) => setState(() {
                          error = downloadError;
                        })),
                iconSize: 30,
                icon: const Icon(
                  Icons.download,
                  color: Colors.blueAccent,
                )),
            title: TextFormField(
              decoration: InputDecoration(
                hintText: 'Enter file name',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: isMobile ? 0 : 4),
              ),
              initialValue: fileName,
              onChanged: (value) => setState(() {
                fileName = value;
              }),
            ),
            trailing: IconButton(
                iconSize: 30,
                onPressed: () => widget.removeVideoFromQueue(),
                icon: const Icon(
                  Icons.cancel,
                  color: Colors.red,
                )),
          )
        ],
      );
    }
  }
}

class VideoDisplayWrapper extends StatelessWidget {
  final List<Widget> children;
  final String title;
  final bool isMobile = Platform.isAndroid || Platform.isIOS;
  VideoDisplayWrapper({Key? key, required this.children, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: isMobile ? 20 : 80),
            child: SelectableText(
              title,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          ...children
        ],
      ),
    );
  }
}
