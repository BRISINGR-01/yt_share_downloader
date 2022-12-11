// ignore_for_file: file_names

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:yt_share_downloader/utils/utils.dart';

class UserSettings {
  String? customDownloadDirectoryPath;
  String chosenDirectoryForDownload;
  bool audioOnly;
  bool canDownloadUsingMobileData;

  UserSettings(
      {required this.chosenDirectoryForDownload,
      required this.customDownloadDirectoryPath,
      required this.audioOnly,
      required this.canDownloadUsingMobileData});

  static Future<UserSettings> init() async {
    Map<String, dynamic> settings = await getAllSettings();

    return UserSettings(
        chosenDirectoryForDownload: settings["chosenDirectoryForDownload"],
        customDownloadDirectoryPath: settings["customDownloadDirectoryPath"],
        audioOnly: settings["audioOnly"],
        canDownloadUsingMobileData: settings["canDownloadUsingMobileData"]);
  }

  String get downloadsDirectory {
    return customDownloadDirectoryPath ?? chosenDirectoryForDownload;
  }
}
