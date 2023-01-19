import 'package:flutter/material.dart';

class Done extends StatelessWidget {
  final String title;
  final Function delete;
  const Done({
    Key? key,
    required this.title,
    required this.delete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: Colors.black,
            width: 1,
          ),
        ),
        color: const Color.fromARGB(248, 127, 224, 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: Text(
                  "$title" "\n" "Downloaded successfully",
                  style: const TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => delete(),
                icon: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              )
            ],
          ),
        ));
  }
}
