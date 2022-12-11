// ignore_for_file: file_names

import 'dart:io';
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

    AppError? connectionError =
        await canAccessInternet(userSettings.canDownloadUsingMobileData);

    if (connectionError != null) {
      result["error"] = connectionError;
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
    } on ArgumentError catch (e) {
      if (e.message == "Invalid YouTube video ID or URL") {
        result["error"] = const AppError("Invalid url");
      } else {
        result["error"] = const AppError(
            "An error occured while fetching data for the video");
      }
    } catch (e) {
      result["error"] =
          const AppError("An error occured while fetching data for the video");
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

    AppError? connectionError =
        await canAccessInternet(userSettings.canDownloadUsingMobileData);

    if (connectionError != null) return connectionError;

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
      File file = File(p.join(downloadsDirectory.path, fileName));
      IOSink fileStream = file.openWrite();

      int downloadedMbs = 0;
      await for (List<int> bytes in stream) {
        downloadedMbs += bytes.length;
        updateProgress(downloadedMbs / totalMbs);
        file.writeAsBytesSync(bytes, mode: FileMode.append);
      }
      await fileStream.flush();
      await fileStream.close();
    } catch (e) {
      return const AppError(
          "An error occured when fetching data for the video");
    }

    state = VideoState.done;
    return null;
  }

  Future<AppError?> delete(String fileName, String downloadsDirectory) async {
    File file = File(p.join(downloadsDirectory, fileName));

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
