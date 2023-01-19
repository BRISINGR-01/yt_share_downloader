import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_share_downloader/components/shared/displayed_error.dart';
import 'package:yt_share_downloader/utils/user_settings.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

const List<String> valuesToRemove = ["VEVO", "Topic", "feat."];

String getDirectory(String option) {
  return {
        "Music": ExternalPath.DIRECTORY_MUSIC,
        "Downloads": ExternalPath.DIRECTORY_DOWNLOADS,
        "Audio books": ExternalPath.DIRECTORY_AUDIOBOOKS,
        "Documents": ExternalPath.DIRECTORY_DOCUMENTS,
        "Movies": ExternalPath.DIRECTORY_MOVIES,
        "Podcasts": ExternalPath.DIRECTORY_PODCASTS,
        "Ringtones": ExternalPath.DIRECTORY_RINGTONES,
      }[option] ??
      ExternalPath.DIRECTORY_DOWNLOADS;
}

void setSetting({required String key, required dynamic value}) async {
  final prefs = await SharedPreferences.getInstance();

  if (value.runtimeType == bool) {
    prefs.setBool(key, value);
  } else {
    prefs.setString(key, value);
  }
}

Future<Map<String, dynamic>> getAllSettings() async {
  final prefs = await SharedPreferences.getInstance();
  String? fileModeStr = prefs.getString("fileNameMode");

  return {
    "audioOnly": prefs.getBool("downloadAudio") ?? true,
    "chosenDirectoryForDownload":
        prefs.getString("chosenDirectoryForDownload") ?? "Downloads",
    "customDownloadDirectoryPath":
        prefs.getString("customDownloadDirectoryPath"),
    "canDownloadUsingMobileData":
        prefs.getBool("canDownloadUsingMobileData") ?? false,
    "fileNameMode": fileModeStr == "artistSong"
        ? FileNameMode.artistSong
        : fileModeStr == "title"
            ? FileNameMode.title
            : FileNameMode.songArtist,
  };
}

String getFileName({
  required FileNameMode fileNameMode,
  String title = "",
  String song = "",
  String artist = "",
}) {
  String formatString(String str) {
    return str
        .trim()
        .replaceAll(RegExp(r'[\\\/\?\:\"\<\>\|\*\.]'), "")
        .replaceAll(RegExp(r'\s+'), " ");
  }

  title = formatString(title);
  artist = formatString(artist);
  song = formatString(song);

  return fileNameMode == FileNameMode.songArtist
      ? "$song - $artist"
      : fileNameMode == FileNameMode.artistSong
          ? "$artist - $song"
          : title;
}

String parseString(String txt) {
  return txt
      .replaceAll(RegExp(r'\(.+\)'), "")
      .replaceAll(RegExp(r'\[.+\]'), "")
      .trim()
      .replaceAll(RegExp(r'^-|-$'), "")
      .trim();
}

Future<DisplayedError?> canAccessInternet(
    bool canDownloadUsingMobileData) async {
  ConnectivityResult connection = await Connectivity().checkConnectivity();

  if (connection == ConnectivityResult.none) {
    return DisplayedError("You are offline");
  } else if (!canDownloadUsingMobileData &&
      connection == ConnectivityResult.mobile) {
    return DisplayedError(
        "Downloading with mobile data is disabled in the settings");
  }

  return null;
}

bool isUrlValid(String? url) {
  List<String> hosts = ["www.youtube.com", "youtu.be"];
  return url != null &&
      Uri.parse(url).isAbsolute &&
      hosts.contains(Uri.parse(url).host);
}

bool isFileNameValid(String fileName) {
  return !RegExp(r'[\\\/\?\:\"\<\>\|\*\.]').hasMatch(fileName);
}

Future<bool> isOffline() async {
  return await Connectivity().checkConnectivity() == ConnectivityResult.none;
}

String devideCamelCase(String artist) {
  for (var i = 0; i < artist.length - 1; i++) {
    if (artist[i] != " " &&
        artist[i] == artist[i].toLowerCase() &&
        artist[i + 1] != artist[i + 1].toLowerCase()) {
      artist =
          "${artist.substring(0, i + 1)} ${artist.substring(i + 1, artist.length)}";
    }
  }
  return artist;
}

Future<DisplayedError?> downloadFile(
  UserSettings userSettings,
  Function(double) updateProgress,
  StreamManifest streamManifest,
  String filePath,
) async {
  DisplayedError? connectionError =
      await canAccessInternet(userSettings.canDownloadUsingMobileData);

  if (connectionError != null) return connectionError;

  var streamInfo = userSettings.downloadAudio
      ? streamManifest.audioOnly.withHighestBitrate()
      : streamManifest.videoOnly.withHighestBitrate();

  int totalMbs = streamInfo.size.totalBytes;

  Stream<List<int>> stream =
      YoutubeExplode().videos.streamsClient.get(streamInfo);

  try {
    File file = File(filePath);
    if (file.existsSync()) file.deleteSync();

    IOSink fileStream = file.openWrite();

    int downloadedMbs = 0;
    updateProgress(0);
    await for (List<int> bytes in stream) {
      downloadedMbs += bytes.length;
      updateProgress(downloadedMbs / totalMbs);
      file.writeAsBytesSync(bytes, mode: FileMode.append);
    }
    await fileStream.flush();
    await fileStream.close();

    if (Platform.isAndroid) {
      await MediaScanner.loadMedia(path: filePath);
      // tell the OS that a new file is created.
      // this way apps like spotify or other music players will update the available songs
      // otherwise the file is there but can only be accessed by a file explorer and doesn't appear in other apps
    }
  } catch (_) {
    return DisplayedError("An error occured while downloading the video");
  }

  return null;
}

Future<DisplayedError?> deleteFile(String filePath, String fileName) async {
  File file = File(filePath);

  if (!file.existsSync()) {
    return DisplayedError("Cannot find $fileName! File path: $filePath");
  }

  try {
    file.deleteSync();
    if (Platform.isAndroid) {
      await MediaScanner.loadMedia(path: file.path);
    }
  } catch (e) {
    return DisplayedError("An error occured while deleting the file");
  }

  return null;
}

enum VideoState {
  none,
  loadingData,
  waitingForApproval,
  downloading,
  done,
  deleting
}

enum FileNameMode { artistSong, songArtist, title }
