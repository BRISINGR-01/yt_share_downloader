import 'package:flutter/material.dart';

class DisplayedError {
  final String text;
  DisplayedError(this.text);

  Widget get widget => Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 20)))
        ],
      );
}
