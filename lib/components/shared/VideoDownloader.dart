// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yt_share_downloader/components/shared/Downloading.dart';
import 'package:yt_share_downloader/components/shared/Loader.dart';
import 'package:yt_share_downloader/components/shared/VideoInputs.dart';
import 'package:yt_share_downloader/utils/UserSettings.dart';
import 'package:yt_share_downloader/utils/VideoObject.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class VideoDownloader extends StatefulWidget {
  final VideoObject video;
  final UserSettings userSettings;
  final Function finish;
  const VideoDownloader({
    Key? key,
    required this.video,
    required this.userSettings,
    required this.finish,
  }) : super(key: key);

  @override
  VideoDownloaderState createState() => VideoDownloaderState();
}

class VideoDownloaderState extends State<VideoDownloader> {
  AppError? _error;
  late VideoObject _video;
  VideoState _state = VideoState.none;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _video = widget.video;

    _loadData();
  }

  updateProgress(double newProgress) {
    setState(() {
      _progress = newProgress;
    });
  }

  void _loadData() {
    if (_state != VideoState.none) return;

    setState(() {
      _state = VideoState.loadingData;
    });

    _video.loadData(widget.userSettings).then((error) {
      setState(() {
        if (error != null) {
          _state = VideoState.none;
          _error = error;
        } else {
          _state = VideoState.waitingForApproval;
        }
      });
    });
  }

  void _download() {
    if (_state != VideoState.waitingForApproval) return;

    setState(() {
      _state = VideoState.downloading;
    });

    _video.download(widget.userSettings, updateProgress).then((error) {
      setState(() {
        if (error != null) {
          _state = VideoState.waitingForApproval;
          _error = error;
        } else {
          _state = VideoState.done;
        }
      });
    });
  }

  void _deleteFile() {
    if (_state != VideoState.done) return;

    setState(() {
      _state = VideoState.deleting;
    });

    _video.delete(widget.userSettings.downloadsDirectory).then((deleteError) {
      if (deleteError == null) {
        widget.finish();

        setState(() {
          _state = VideoState.none;
        });
      } else {
        setState(() {
          _state = VideoState.done;
          _error = deleteError;
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _state == VideoState.none
                                ? _loadData()
                                : _state == VideoState.waitingForApproval
                                    ? _download()
                                    : _state == VideoState.done
                                        ? _deleteFile()
                                        : null,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                          _error!.widget,
                        ],
                      ),
                      IconButton(
                        onPressed: () => widget.finish(),
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                      )
                    ])
              : _state == VideoState.deleting ||
                      _state == VideoState.loadingData
                  ? const Loader()
                  : _state == VideoState.downloading ||
                          _state == VideoState.done
                      ? Downloading(
                          state: _state,
                          progress: _progress,
                          video: _video,
                          deleteFile: _deleteFile,
                          removeVideoFromQueue: widget.finish)
                      : _state == VideoState.waitingForApproval
                          ? VideoInputs(
                              cancel: widget.finish,
                              download: _download,
                              fileNameMode: widget.userSettings.fileNameMode,
                              video: _video,
                            )
                          : const Loader()),
    );
  }
}
