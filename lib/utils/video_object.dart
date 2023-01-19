// ignore_for_file: file_names

import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_share_downloader/components/shared/displayed_error.dart';
import 'package:yt_share_downloader/utils/user_settings.dart';
import 'package:path/path.dart' as p;

import 'package:yt_share_downloader/utils/utils.dart';

class VideoObject {
  late String artist;
  late String song;
  late String title;
  late String filePath;
  String url;
  bool _isCancelled = false;
  late StreamManifest _streamManifest;
  DisplayedError? error;

  VideoObject(this.url);

  Future<DisplayedError?> loadData(UserSettings userSettings) async {
    if (!isUrlValid(url)) {
      return error = DisplayedError("Invalid url");
    }

    DisplayedError? connectionError =
        await canAccessInternet(userSettings.canDownloadUsingMobileData);

    if (connectionError != null) return error = connectionError;

    try {
      Video videoData = await YoutubeExplode().videos.get(url);
      _streamManifest =
          await YoutubeExplode().videos.streamsClient.getManifest(url);

      title = videoData.title;
      artist = devideCamelCase(videoData.author);
      // ex: AlveroSoler

      for (String val in valuesToRemove) {
        title = title.replaceAll(val, "").trim();
        artist = artist.replaceAll(val, "").trim();
        // ex: Alvero Soler VEVO (Company name)
      }
      title = parseString(title);
      artist = parseString(artist);
      song = parseString(title.replaceFirst(artist, ""));
    } on ArgumentError catch (e) {
      if (e.message == "Invalid YouTube video ID or URL") {
        return error = DisplayedError("Invalid url: There is no such video!");
      }

      rethrow;
    } catch (_) {
      return error =
          DisplayedError("An error occured while fetching data for the video");
    }

    return null;
  }

  Future<DisplayedError?> download(
    UserSettings userSettings,
    Function(double) updateProgress,
  ) async {
    Directory downloadsDirectory = Directory(userSettings.downloadsDirectory);

    if (!downloadsDirectory.existsSync()) {
      return DisplayedError(
          "Couldn't find the folder specified in the settings");
    }

    filePath = p
        .join(downloadsDirectory.path,
            "$title.mp${userSettings.downloadAudio ? 3 : 4}")
        .replaceAll(r'[\/*<>?"|]', '')
        .trim(); // unallowed characters in windows

    DisplayedError? error = await downloadFile(
      userSettings,
      updateProgress,
      _streamManifest,
      filePath,
    );

    if (_isCancelled) delete();

    return error;
  }

  cancelDownload() {
    _isCancelled = true;
  }

  Future<DisplayedError?> delete() async {
    return deleteFile(filePath, title);
  }
}
