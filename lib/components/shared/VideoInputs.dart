import 'package:flutter/material.dart';
import 'package:yt_share_downloader/utils/VideoObject.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class VideoInputs extends StatefulWidget {
  final FileNameMode fileNameMode;
  final Function download;
  final Function cancel;
  final VideoObject video;
  const VideoInputs({
    Key? key,
    required this.fileNameMode,
    required this.video,
    required this.download,
    required this.cancel,
  }) : super(key: key);

  @override
  State<VideoInputs> createState() => _VideoInputsState();
}

class _VideoInputsState extends State<VideoInputs> {
  final _songTextController = TextEditingController();
  final _artistTextController = TextEditingController();
  final _titleTextController = TextEditingController();
  final _fileNameTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _songTextController.text = widget.video.song;
    _artistTextController.text = widget.video.artist;
    _titleTextController.text = widget.video.title;
    _updateFileName();
  }

  void _updateFileName() {
    _fileNameTextController.text = getFileName(
      fileNameMode: widget.fileNameMode,
      artist: _artistTextController.text,
      song: _songTextController.text,
      title: _titleTextController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> inputs = widget.fileNameMode == FileNameMode.songArtist
        ? [
            ListTile(
              leading: const Text("Song: "),
              title: TextField(
                controller: _songTextController,
                onChanged: (value) => _updateFileName(),
              ),
            ),
            ListTile(
              leading: const Text("Artist: "),
              title: TextField(
                controller: _artistTextController,
                onChanged: (value) => _updateFileName(),
              ),
            ),
          ]
        : widget.fileNameMode == FileNameMode.artistSong
            ? [
                ListTile(
                  leading: const Text("Artist: "),
                  title: TextField(
                    controller: _artistTextController,
                    onChanged: (value) => _updateFileName(),
                  ),
                ),
                ListTile(
                  leading: const Text("Song: "),
                  title: TextField(
                    controller: _songTextController,
                    onChanged: (value) => _updateFileName(),
                  ),
                ),
              ]
            : [
                ListTile(
                    leading: const Text("Original: "),
                    title: SelectableText(widget.video.title)),
              ];

    return Column(
      children: [
        ...inputs,
        TextField(
          controller: _fileNameTextController,
          decoration: const InputDecoration(hintText: "Enter title"),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                icon: const Icon(
                  Icons.download,
                ),
                onPressed: () {
                  widget.video.fileName = _fileNameTextController.text;
                  widget.video.artist =
                      widget.fileNameMode == FileNameMode.title
                          ? ""
                          : _artistTextController.text;
                  widget.video.song = widget.fileNameMode == FileNameMode.title
                      ? _titleTextController.text
                      : _songTextController.text;
                  widget.download();
                }),
            IconButton(
                icon: const Icon(
                  Icons.cancel,
                ),
                onPressed: () {
                  widget.cancel();
                }),
          ],
        ),
      ],
    );
  }
}
