// ignore_for_file: file_names

import 'dart:io';
import 'package:media_scanner/media_scanner.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_share_downloader/utils/UserSettings.dart';
import 'package:path/path.dart' as p;

import 'package:yt_share_downloader/utils/utils.dart';

class VideoObject {
  late String artist;
  late String song;
  late String title;
  late String fileName;
  late String filePath;
  String url;
  late StreamManifest _streamManifest;
  YoutubeExplode yt = YoutubeExplode();

  VideoObject(this.url);

  Future<AppError?> loadData(UserSettings userSettings) async {
    if (!isUrlValid(url)) {
      return AppError("Invalid url");
    }

    AppError? connectionError =
        await canAccessInternet(userSettings.canDownloadUsingMobileData);

    if (connectionError != null) {
      return connectionError;
    }

    try {
      Video videoData = await yt.videos.get(url);
      _streamManifest = await yt.videos.streamsClient.getManifest(url);

      title = videoData.title;
      artist = devideCamelCase(videoData.author);
      // ex: AlveroSoler

      for (String val in valuesToRemove) {
        title = title.replaceAll(val, "").trim();
        artist = artist.replaceAll(val, "").trim();
        // ex: Alvero Soler VEVO (Company name)
      }
      song = getSongName(title, artist);
    } on ArgumentError catch (e) {
      if (e.message == "Invalid YouTube video ID or URL") {
        return AppError("Invalid url");
      } else {
        return AppError("An error occured while fetching data for the video");
      }
    } catch (e) {
      return AppError("An error occured while fetching data for the video");
    }
  }

  Future<AppError?> download(
    UserSettings userSettings,
    Function(double) updateProgress,
  ) async {
    updateProgress(0);

    AppError? connectionError =
        await canAccessInternet(userSettings.canDownloadUsingMobileData);

    if (connectionError != null) return connectionError;

    var streamInfo = userSettings.audioOnly
        ? _streamManifest.audioOnly.withHighestBitrate()
        : _streamManifest.videoOnly.withHighestBitrate();

    int totalMbs = streamInfo.size.totalBytes;

    Stream<List<int>> stream = yt.videos.streamsClient.get(streamInfo);

    Directory downloadsDirectory = Directory(userSettings.downloadsDirectory);

    if (!downloadsDirectory.existsSync()) {
      return AppError("Couldn't find the folder specified in the settings");
    }

    filePath = p.join(downloadsDirectory.path,
        "$fileName.mp${userSettings.audioOnly ? 3 : 4}");

    File videoFile = File(filePath);
    IOSink fileStream = videoFile.openWrite();

    int downloadedMbs = 0;
    await for (List<int> bytes in stream) {
      downloadedMbs += bytes.length;
      updateProgress(downloadedMbs / totalMbs);
      videoFile.writeAsBytesSync(bytes, mode: FileMode.append);
    }
    await fileStream.flush();
    await fileStream.close();

    if (Platform.isAndroid) {
      await MediaScanner.loadMedia(path: fileName);
    }
    try {} catch (e) {
      print(e);
      return AppError("An error occured while downloading the video");
    }

    return null;
  }

  Future<AppError?> delete(String downloadsDirectory) async {
    File file = File(filePath);

    if (!file.existsSync()) {
      return AppError("Cannot find $fileName in $downloadsDirectory");
    }

    try {
      file.deleteSync();
      if (Platform.isAndroid) {
        await MediaScanner.loadMedia(path: file.path);
      }
    } catch (e) {
      return AppError("An error occured while deleting the file");
    }

    return null;
  }
}
