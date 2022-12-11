import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:yt_share_downloader/components/Loader.dart';
import 'package:yt_share_downloader/utils/UserSettings.dart';
import 'package:yt_share_downloader/utils/utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Settings extends StatefulWidget {
  final Function refreshSettings;
  final UserSettings userSettings;
  const Settings(
      {Key? key, required this.refreshSettings, required this.userSettings})
      : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late String chosenDirectoryForDownload;
  late String? customDownloadDirectoryPath;
  late bool audioOnly;
  ConnectivityResult? connectivityType;
  late bool canDownloadUsingMobileData;
  bool hasLoaded = false;

  void checkConnectivity() {
    Connectivity().checkConnectivity().then((res) => setState(() {
          connectivityType = res;
          hasLoaded = true;
        }));
  }

  @override
  void initState() {
    super.initState();
    audioOnly = widget.userSettings.audioOnly;
    canDownloadUsingMobileData = widget.userSettings.canDownloadUsingMobileData;
    customDownloadDirectoryPath =
        widget.userSettings.customDownloadDirectoryPath;
    chosenDirectoryForDownload = widget.userSettings.chosenDirectoryForDownload;
    checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: !hasLoaded
          ? const Loader()
          : WillPopScope(
              onWillPop: () async {
                Navigator.pop(context, {
                  "audioOnly": audioOnly,
                  "canDownloadUsingMobileData": canDownloadUsingMobileData,
                  "customDownloadDirectoryPath": customDownloadDirectoryPath,
                  "chosenDirectoryForDownload": chosenDirectoryForDownload,
                });
                return false;
              },
              child: ListView(
                children: [
                  ListTile(
                    title: const Text("Audio"),
                    trailing: Switch(
                        value: audioOnly,
                        onChanged: (isOn) {
                          setState(() {
                            audioOnly = isOn;
                          });
                          setSetting(key: "audioOnly", value: isOn);
                        }),
                  ),
                  ListTile(
                    title: const Text("Folder for downloads"),
                    trailing: DropdownButton(
                      value: chosenDirectoryForDownload,
                      items: [
                        const DropdownMenuItem(
                            value: "Music", child: Text("Music")),
                        const DropdownMenuItem(
                            value: "Downloads", child: Text("Downloads")),
                        const DropdownMenuItem(
                            value: "Audio", child: Text("Audio")),
                        const DropdownMenuItem(
                            value: "Documents", child: Text("Documents")),
                        const DropdownMenuItem(
                            value: "Movies", child: Text("Movies")),
                        const DropdownMenuItem(
                            value: "Podcasts", child: Text("Podcasts")),
                        const DropdownMenuItem(
                            value: "Ringtones", child: Text("Ringtones")),
                        DropdownMenuItem(
                            value: "Other",
                            child: Text(customDownloadDirectoryPath ?? "Other"))
                      ],
                      onChanged: (dynamic value) async {
                        if (value == "Other") {
                          customDownloadDirectoryPath =
                              await FilePicker.platform.getDirectoryPath();

                          if (customDownloadDirectoryPath != null) {
                            setSetting(
                                key: "customDownloadDirectoryPath",
                                value: customDownloadDirectoryPath);
                          }
                        } else {}

                        setState(() {
                          chosenDirectoryForDownload = value;
                        });
                        setSetting(
                            key: "chosenDirectoryForDownload", value: value);
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Can download with mobile data"),
                    trailing: Switch(
                        value: canDownloadUsingMobileData,
                        onChanged: (isOn) {
                          setState(() {
                            canDownloadUsingMobileData = isOn;
                          });
                          setSetting(
                              key: "canDownloadUsingMobileData", value: isOn);
                        }),
                  ),
                  ListTile(
                      title: Row(
                    children: [
                      const Text("Internet connection: "),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: connectivityType == null
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator())
                            : Text(
                                connectivityType == ConnectivityResult.mobile
                                    ? "Mobile Data"
                                    : connectivityType ==
                                            ConnectivityResult.ethernet
                                        ? "Ethernet"
                                        : connectivityType ==
                                                ConnectivityResult.wifi
                                            ? "Wifi"
                                            : connectivityType ==
                                                    ConnectivityResult.vpn
                                                ? "VPN"
                                                : connectivityType ==
                                                        ConnectivityResult.none
                                                    ? "None"
                                                    : connectivityType ==
                                                            ConnectivityResult
                                                                .bluetooth
                                                        ? "Bluetooth"
                                                        : "Unknown",
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic),
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() {
                            connectivityType = null;
                          });
                          checkConnectivity();
                        },
                      )
                    ],
                  ))
                ],
              ),
            ),
    ));
  }
}
