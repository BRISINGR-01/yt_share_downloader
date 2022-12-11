import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_share_downloader/utils/UserSettings.dart';
import 'package:path/path.dart' as p;

import 'package:yt_share_downloader/utils/utils.dart';

class VideoInstance {
  String artist = "";
  String title = "";
  String url = "";
  late StreamManifest _streamManifest;
  YoutubeExplode yt;
  Error? error;
  VideoState state = VideoState.loadingData;

  VideoInstance(this.url, this.yt, UserSettings? userSettings) {
    if (!isUrlValid(url)) {
      error = Error();
      return;
    }

    if (userSettings == null) {
      error = Error();
      return;
    }
  }

  Future<Map<String, dynamic>> loadData(UserSettings userSettings) async {
    Map<String, dynamic> result = {"error": null, "fileName": ""};
    ConnectivityResult connection = await Connectivity().checkConnectivity();

    if (connection == ConnectivityResult.none) {
      result["error"] = const AppError("You are offline");
      return result;
    } else if (!userSettings.canDownloadUsingMobileData &&
        connection == ConnectivityResult.mobile) {
      result["error"] = const AppError(
          "Downloading with mobile data is disabled in the settings");
      return result;
    }

    try {
      Video video = await yt.videos.get(url);
      _streamManifest = await yt.videos.streamsClient.getManifest(url);

      title = video.title;
      artist = video.author;
      result["fileName"] =
          getFileName(video.title, video.author, userSettings.audioOnly);
      state = VideoState.waitingForApproval;
    } catch (e) {
      result["error"] =
          const AppError("An error occured when fetching data for the video");
    }

    return result;
  }

  get displayName {
    List<String> name = [];
    if (title.isNotEmpty) name.add(title);
    if (artist.isNotEmpty) name.add("by $artist");
    return name.join("\n");
  }

  Future<AppError?> download(String fileName, UserSettings userSettings,
      Function(double) updateProgress) async {
    state = VideoState.downloading;
    updateProgress(0);

    ConnectivityResult connection = await Connectivity().checkConnectivity();

    if (connection == ConnectivityResult.none) {
      return const AppError("You are offline");
    } else if (!userSettings.canDownloadUsingMobileData &&
        connection == ConnectivityResult.mobile) {
      return const AppError(
          "Downloading with mobile data is disabled in the settings");
    }

    try {
      var streamInfo = userSettings.audioOnly
          ? _streamManifest.audioOnly.withHighestBitrate()
          : _streamManifest.videoOnly.withHighestBitrate();

      int totalMbs = streamInfo.size.totalBytes;

      Stream<List<int>> stream = yt.videos.streamsClient.get(streamInfo);

      Directory downloadsDirectory = Directory(userSettings.downloadsDirectory);

      if (!downloadsDirectory.existsSync()) {
        return const AppError(
            "Couldn't find the folder specified in the settings");
      }

      File file = File(p.join(userSettings.downloadsDirectory, fileName));
      IOSink fileStream = file.openWrite();

      int downloadedMbs = 0;
      await for (List<int> bytes in stream) {
        downloadedMbs += bytes.length;
        updateProgress(downloadedMbs / totalMbs);
        file.writeAsBytesSync(bytes, mode: FileMode.append);
      }
      // await stream.pipe(fileStream);
      state = VideoState.done;
      await fileStream.flush();
      await fileStream.close();
    } catch (e) {
      return const AppError(
          "An error occured when fetching data for the video");
    }

    return null;
  }

  Future<AppError?> delete(String fileName, String downloadsDirectory) async {
    File file = File(fileName);

    if (!file.existsSync()) {
      return AppError("Cannot find $fileName in $downloadsDirectory");
    }

    try {
      file.deleteSync();
    } catch (e) {
      return const AppError("An error occured while deleting the file");
    }

    return null;
  }
}
