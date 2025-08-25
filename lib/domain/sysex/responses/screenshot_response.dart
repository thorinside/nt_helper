import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';

class ScreenshotResponse extends SysexResponse {
  ScreenshotResponse(super.data);

  @override
  Uint8List parse() {
    try {
      // Define screenshot properties (adjust based on actual format)
      const int width = 256; // Example width
      const int height = 64; // Example height
      const int borderWidth = 5; // Border size in pixels

      const int newWidth = width + 2 * borderWidth;
      const int newHeight = height + 2 * borderWidth;

      // Create a new image with the border dimensions
      final img.Image borderedImage = img.Image(
        width: newWidth,
        height: newHeight,
      );

      // Fill the entire image with a border color (e.g., black)
      final img.Color borderColor = img.ColorFloat16.rgb(0, 0, 0); // Black
      for (int y = 0; y < newHeight; y++) {
        for (int x = 0; x < newWidth; x++) {
          borderedImage.setPixel(x, y, borderColor);
        }
      }

      // Create an empty image with specified dimensions
      final img.Image image = img.Image(width: width, height: height);

      // Assuming screenshotData is raw RGB data
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int pixelIndex = y * width + x;
          if (pixelIndex < data.length) {
            double v = data[pixelIndex].toDouble();
            v = pow(
              v * 0.066666666666667,
              0.45,
            ).toDouble(); // Apply gamma correction
            v = pow(v, 0.45).toDouble(); // Apply gamma correction again
            v = v * 255; // Scale to 0–255
            int intensity = v.clamp(0, 255).toInt();
            img.Color color = img.ColorFloat16.rgb(0, intensity, intensity);
            image.setPixel(x, y, color);
          }
        }
      }

      // Copy the original image into the center of the bordered image
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          img.Pixel originalPixel = image.getPixel(x, y);
          borderedImage.setPixel(
            x + borderWidth,
            y + borderWidth,
            originalPixel,
          );
        }
      }

      // Encode the image as PNG
      return Uint8List.fromList(img.encodePng(borderedImage));
    } catch (e) {
      return Uint8List(0); // Return empty on error
    }
  }
}
