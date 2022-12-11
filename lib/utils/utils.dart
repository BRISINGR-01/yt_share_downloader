import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        .replaceAll(RegExp(r'[\\\/\?\:\"\<\>\|\*\.]'), "")
        .replaceAll(RegExp(r'\s+'), " ");
  }

  title = formatString(title);
  author = formatString(author);

  return "$title - $author.mp${isAudio ? 3 : 4}";
}

Future<AppError?> canAccessInternet(bool canDownloadUsingMobileData) async {
  ConnectivityResult connection = await Connectivity().checkConnectivity();

  if (connection == ConnectivityResult.none) {
    return const AppError("You are offline");
  } else if (!canDownloadUsingMobileData &&
      connection == ConnectivityResult.mobile) {
    return const AppError(
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

Future<bool> isOffline() async {
  return await Connectivity().checkConnectivity() == ConnectivityResult.none;
}

class AppError {
  final String text;
  const AppError(this.text);
}

enum VideoState { loadingData, waitingForApproval, downloading, done, deleting }
