import 'package:flutter/material.dart';
import 'package:yt_share_downloader/components/toast/toast.dart';
import 'package:yt_share_downloader/utils/user_settings.dart';
import 'package:yt_share_downloader/utils/video_object.dart';

class ToastContainer extends StatefulWidget {
  final List<VideoObject> videos;
  final UserSettings userSettings;
  final Function(String) removeFromQueue;
  const ToastContainer({
    Key? key,
    required this.videos,
    required this.userSettings,
    required this.removeFromQueue,
  }) : super(key: key);

  @override
  ToastContainerState createState() => ToastContainerState();
}

class ToastContainerState extends State<ToastContainer> {
  List<String> fading = [];

  void _remove(String url, bool skipAnimation) {
    if (skipAnimation) {
      widget.removeFromQueue(url);
    } else {
      setState(() {
        fading.add(url);
      });

      Future.delayed(const Duration(seconds: 2)).then((_) {
        fading.remove(url);
        widget.removeFromQueue(url);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.videos
            .map((video) => AnimatedOpacity(
                  opacity: fading.contains(video.url) ? 0.0 : 1.0,
                  duration: const Duration(seconds: 2),
                  child: SizedBox(
                    width: 300,
                    child: Toast(
                      video: video,
                      remove: ({skipAnimation = false}) {
                        _remove(video.url, skipAnimation == true);
                      },
                      userSettings: widget.userSettings,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
