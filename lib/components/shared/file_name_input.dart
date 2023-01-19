import 'package:flutter/material.dart';
import 'package:yt_share_downloader/utils/video_object.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class FileNameInput extends StatefulWidget {
  final FileNameMode fileNameMode;
  final Function download;
  final Function cancel;
  final VideoObject video;
  const FileNameInput({
    Key? key,
    required this.fileNameMode,
    required this.video,
    required this.download,
    required this.cancel,
  }) : super(key: key);

  @override
  State<FileNameInput> createState() => _FileNameInputState();
}

class _FileNameInputState extends State<FileNameInput> {
  final _fileNameTextController = TextEditingController();
  final _songNameTextController = TextEditingController();
  final _artistTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _download() {
    if (_formKey.currentState!.validate()) {
      widget.video.title = _fileNameTextController.text;
      if (widget.fileNameMode == FileNameMode.artistSong ||
          widget.fileNameMode == FileNameMode.songArtist) {
        widget.video.song = _songNameTextController.text;
        widget.video.artist = _artistTextController.text;
      }
      widget.download();
    }
  }

  _updateFileName() {
    switch (widget.fileNameMode) {
      case FileNameMode.title:
        _fileNameTextController.text = widget.video.title;
        break;
      case FileNameMode.songArtist:
        _fileNameTextController.text =
            "${_songNameTextController.text} - ${_artistTextController.text}";
        break;
      case FileNameMode.artistSong:
        _fileNameTextController.text =
            "${_artistTextController.text} - ${_songNameTextController.text}";
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    _songNameTextController.text = widget.video.song;
    _artistTextController.text = widget.video.artist;

    _updateFileName();
  }

  @override
  Widget build(BuildContext context) {
    List songtitleAndAuthor;
    switch (widget.fileNameMode) {
      case FileNameMode.title:
        songtitleAndAuthor = [
          SelectableText(
            widget.video.song,
            style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
          ),
          if (widget.video.artist.isNotEmpty)
            SelectableText(
              widget.video.artist,
              style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
            ),
        ];
        break;
      case FileNameMode.songArtist:
        songtitleAndAuthor = [
          ListTile(
            leading: const Text("Song name:"),
            title: TextFormField(
              controller: _songNameTextController,
              onChanged: (_) => _updateFileName(),
            ),
          ),
          ListTile(
            leading: const Text("Artist:"),
            title: TextFormField(
              controller: _artistTextController,
              onChanged: (_) => _updateFileName(),
            ),
          ),
        ];
        break;
      case FileNameMode.artistSong:
        songtitleAndAuthor = [
          ListTile(
            leading: const Text("Artist:"),
            title: TextFormField(
              controller: _artistTextController,
              onChanged: (_) => _updateFileName(),
            ),
          ),
          ListTile(
            leading: const Text("Song name:"),
            title: TextFormField(
              controller: _songNameTextController,
              onChanged: (_) => _updateFileName(),
            ),
          ),
        ];
        break;
    }
    var downloadBtn = IconButton(
      icon: const Icon(
        Icons.download,
        color: Colors.lightBlueAccent,
      ),
      onPressed: _download,
    );
    var cancelBtn = IconButton(
        icon: const Icon(
          Icons.cancel,
          color: Colors.red,
        ),
        onPressed: () {
          widget.cancel();
        });

    var textInput = Expanded(
      child: TextFormField(
        controller: _fileNameTextController,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a file name";
          }
          if (!isFileNameValid(value)) {
            return "Please enter a valid file name. Forbidden characters: \\ / ? : \" < > | . *";
          }

          return null;
        },
        onFieldSubmitted: (_) => _download(),
        decoration: const InputDecoration(hintText: "Enter title"),
      ),
    );
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return Form(
        key: _formKey,
        child: Column(
          children: [
            ...songtitleAndAuthor,
            textInput,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [downloadBtn, cancelBtn],
            ),
          ],
        ),
      );
    } else {
      return Form(
        key: _formKey,
        child: Column(
          children: [
            ...songtitleAndAuthor,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                downloadBtn,
                const SizedBox(width: 20),
                textInput,
                const SizedBox(width: 20),
                cancelBtn
              ],
            ),
          ],
        ),
      );
    }
  }
}
