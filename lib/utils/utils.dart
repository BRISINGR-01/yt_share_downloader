import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> valuesToRemove = ["VEVO"];

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
    "audioOnly": prefs.getBool("audioOnly") ?? true,
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

String getSongName(String title, String author) {
  return title
      .replaceFirst(author, "")
      .replaceAll(RegExp(r'\(.+\)'), "")
      .replaceAll(RegExp(r'\[.+\]'), "")
      .trim()
      .replaceAll(RegExp(r'^-|-$/'), "")
      .trim();
}

Future<AppError?> canAccessInternet(bool canDownloadUsingMobileData) async {
  ConnectivityResult connection = await Connectivity().checkConnectivity();

  if (connection == ConnectivityResult.none) {
    return AppError("You are offline");
  } else if (!canDownloadUsingMobileData &&
      connection == ConnectivityResult.mobile) {
    return AppError("Downloading with mobile data is disabled in the settings");
  }

  return null;
}

bool isUrlValid(String? url) {
  List<String> hosts = ["www.youtube.com", "youtu.be"];
  return url != null &&
      Uri.parse(url).isAbsolute &&
      hosts.contains(Uri.parse(url).host);
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

class AppError {
  final String text;
  AppError(this.text);

  Widget get widget => Flexible(
      child:
          Text(text, style: const TextStyle(color: Colors.red, fontSize: 20)));
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
