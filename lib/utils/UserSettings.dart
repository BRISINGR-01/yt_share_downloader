// ignore_for_file: file_names

import 'package:yt_share_downloader/utils/utils.dart';

class UserSettings {
  String? customDownloadDirectoryPath;
  String chosenDirectoryForDownload;
  bool audioOnly;
  bool canDownloadUsingMobileData;
  FileNameMode fileNameMode;

  UserSettings({
    required this.chosenDirectoryForDownload,
    required this.customDownloadDirectoryPath,
    required this.audioOnly,
    required this.canDownloadUsingMobileData,
    required this.fileNameMode,
  });

  static Future<UserSettings> init() async {
    Map<String, dynamic> settings = await getAllSettings();

    return UserSettings(
      chosenDirectoryForDownload: settings["chosenDirectoryForDownload"],
      customDownloadDirectoryPath: settings["customDownloadDirectoryPath"],
      audioOnly: settings["audioOnly"],
      canDownloadUsingMobileData: settings["canDownloadUsingMobileData"],
      fileNameMode: settings["fileNameMode"],
    );
  }

  String get downloadsDirectory {
    return customDownloadDirectoryPath ?? chosenDirectoryForDownload;
  }

  static UserSettings fromMap(Map<String, dynamic> values) {
    return UserSettings(
      chosenDirectoryForDownload: values["chosenDirectoryForDownload"],
      customDownloadDirectoryPath: values["customDownloadDirectoryPath"],
      audioOnly: values["audioOnly"],
      canDownloadUsingMobileData: values["canDownloadUsingMobileData"],
      fileNameMode: values["fileNameMode"],
    );
  }
}
