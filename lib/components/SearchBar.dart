// ignore_for_file: file_names

import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final Function prepareDownload;
  final String url;
  const SearchBar({
    Key? key,
    required this.prepareDownload,
    required this.url,
  }) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // controller.text = widget.url;
  }

  // @override
  // void didUpdateWidget(covariant SearchBar oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   controller.text = "";
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListTile(
        minLeadingWidth: 0,
        minVerticalPadding: 0,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.lightBlueAccent, width: 2),
          borderRadius: BorderRadius.circular(5),
        ),
        title: TextField(
          controller: controller,
          onSubmitted: (String val) {
            widget.prepareDownload(val);
            controller.clear();
          },
          decoration: const InputDecoration(
            hintText: 'Search',
            contentPadding: EdgeInsets.only(left: 16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        horizontalTitleGap: 0,
        trailing: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              widget.prepareDownload(controller.text);
              controller.clear();
            },
            icon: const Icon(Icons.search)),
      ),
    );
  }
}
