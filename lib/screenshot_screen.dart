import 'dart:typed_data';

import 'package:flutter/material.dart';

class ScreenshotScreen extends StatelessWidget {
  final Uint8List screenshot;

  const ScreenshotScreen({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Screenshot'),
        ),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 256 + 10,
              height: 64 + 10,
              child: Image(
                width: 256 + 10,
                height: 64 + 10,
                image: MemoryImage(screenshot),
              ),
            ),
          ),
        ));
  }
}
