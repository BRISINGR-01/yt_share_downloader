import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_share_downloader/utils/UserSettings.dart';

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

  return {
    "audioOnly": prefs.getBool("audioOnly") ?? true,
    "chosenDirectoryForDownload":
        prefs.getString("chosenDirectoryForDownload") ?? "Downloads",
    "customDownloadDirectoryPath":
        prefs.getString("customDownloadDirectoryPath"),
    "canDownloadUsingMobileData":
        prefs.getBool("canDownloadUsingMobileData") ?? false,
  };
}

String getFileName(String title, String author, bool isAudio) {
  String formatString(str) {
    return str
        .replaceAll(RegExp(r'[^\w,\s-]'), "")
        .replaceAll(RegExp(r'\s+'), " ");
  }

  title = formatString(title);
  author = formatString(author);

  return "$title - $author.mp${isAudio ? 3 : 4}";
}

Future<Map<String, dynamic>> getLimitedSettings() async {
  final prefs = await SharedPreferences.getInstance();

  bool isOnMobileData =
      await Connectivity().checkConnectivity() == ConnectivityResult.mobile;
  if (isOnMobileData) {
    bool isAllowed = prefs.getBool("canDownloadUsingMobileData") ?? false;

    if (!isAllowed) return {"isAllowed": false};
  }

  String? customDownloadDirectoryPath =
      prefs.getString("customDownloadDirectoryPath");
  String path = customDownloadDirectoryPath ??
      prefs.getString("chosenDirectoryForDownload") ??
      "Downloads";

  return {
    "isAllowed": true,
    "audioOnly": prefs.getBool("audioOnly") ?? true,
    "directory": path,
  };
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

class AppError {
  final String text;
  const AppError(this.text);
}

enum VideoState { loadingData, waitingForApproval, downloading, done, deleting }
