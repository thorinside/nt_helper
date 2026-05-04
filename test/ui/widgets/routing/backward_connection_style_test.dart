import 'dart:typed_data';
import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';

ConnectionData _connData({
  String id = 'c',
  bool isBackwardEdge = false,
  bool isPartial = false,
  bool isGhost = false,
  bool isSelected = false,
  ConnectionType connectionType = ConnectionType.algorithmToAlgorithm,
}) {
  return ConnectionData(
    connection: Connection(
      id: id,
      sourcePortId: 'src',
      destinationPortId: 'dst',
      connectionType: connectionType,
      isBackwardEdge: isBackwardEdge,
      isPartial: isPartial,
      isGhostConnection: isGhost,
    ),
    sourcePosition: const Offset(0, 0),
    destinationPosition: const Offset(100, 0),
    isSelected: isSelected,
  );
}

void main() {
  group('Backward connection styling', () {
    test('kBackwardEdgeColor is the agreed bright orange (#FF8800)', () {
      expect(kBackwardEdgeColor, const Color(0xFFFF8800));
    });

    group('classifyVisualType precedence', () {
      test('backward edge classifies as invalid', () {
        expect(
          ConnectionPainter.classifyVisualType(
            _connData(isBackwardEdge: true),
          ),
          ConnectionVisualType.invalid,
        );
      });

      test('partial backward edge classifies as partial (not invalid)', () {
        expect(
          ConnectionPainter.classifyVisualType(
            _connData(isBackwardEdge: true, isPartial: true),
          ),
          ConnectionVisualType.partial,
        );
      });

      test('selected backward edge classifies as selected', () {
        expect(
          ConnectionPainter.classifyVisualType(
            _connData(isBackwardEdge: true, isSelected: true),
          ),
          ConnectionVisualType.selected,
        );
      });

      test('ghost connection classifies as ghost', () {
        expect(
          ConnectionPainter.classifyVisualType(_connData(isGhost: true)),
          ConnectionVisualType.ghost,
        );
      });

      test('plain connection classifies as regular', () {
        expect(
          ConnectionPainter.classifyVisualType(_connData()),
          ConnectionVisualType.regular,
        );
      });
    });

    group('resolved style color', () {
      ConnectionPainter painterFor(ConnectionData conn, {ThemeData? theme}) {
        return ConnectionPainter(
          connections: [conn],
          theme: theme ?? ThemeData.light(),
          showLabels: false,
        );
      }

      test('backward edge uses kBackwardEdgeColor in light theme', () {
        final conn = _connData(isBackwardEdge: true);
        final painter = painterFor(conn);
        expect(
          painter.debugResolveStyleColor(conn).toARGB32(),
          kBackwardEdgeColor.toARGB32(),
        );
      });

      test('backward edge uses kBackwardEdgeColor in dark theme', () {
        final conn = _connData(isBackwardEdge: true);
        final painter = painterFor(conn, theme: ThemeData.dark());
        expect(
          painter.debugResolveStyleColor(conn).toARGB32(),
          kBackwardEdgeColor.toARGB32(),
        );
      });
    });

    group('stroke pattern', () {
      const w = 200;
      const h = 100;
      const yScan = 50.0;

      bool isOrangeIsh(int r, int g, int b, int a) {
        // Tolerance band for kBackwardEdgeColor (#FF8800), accounting for
        // anti-aliased / partially-covered pixels at the edges of round dots
        // and dashed segments. Output buffer is premultiplied, so partial-
        // coverage pixels show R≈191/G≈102/A≈191 instead of full intensity;
        // we therefore unpremultiply against alpha to recover the source
        // color and assert that against #FF8800 with a generous tolerance.
        if (a < 0x40) return false;
        final rNorm = (r * 255) ~/ a;
        final gNorm = (g * 255) ~/ a;
        final bNorm = (b * 255) ~/ a;
        return rNorm >= 0xE0 &&
            gNorm >= 0x60 &&
            gNorm <= 0xA8 &&
            bNorm <= 0x20;
      }

      Future<int> maxOrangeRunOnScanlineFor(
        ConnectionData conn,
        WidgetTester tester,
      ) async {
        late ByteData byteData;
        await tester.runAsync(() async {
          final painter = ConnectionPainter(
            connections: [conn],
            theme: ThemeData.light(),
            showLabels: false,
            enableAntiOverlap: false,
          );
          final recorder = dart_ui.PictureRecorder();
          final canvas = Canvas(recorder);
          painter.paint(canvas, const Size(w * 1.0, h * 1.0));
          final picture = recorder.endRecording();
          final image = await picture.toImage(w, h);
          byteData =
              (await image.toByteData(format: dart_ui.ImageByteFormat.rawRgba))!;
        });

        final bytes = byteData.buffer.asUint8List();
        int maxRun = 0;
        // Sample a small vertical band around y=50 so a slight bezier dip
        // (or anti-aliasing crossing) doesn't make us miss the path.
        for (int y = yScan.toInt() - 3; y <= yScan.toInt() + 3; y++) {
          int currentRun = 0;
          for (int x = 0; x < w; x++) {
            final i = (y * w + x) * 4;
            if (isOrangeIsh(
                bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3])) {
              currentRun++;
              if (currentRun > maxRun) maxRun = currentRun;
            } else {
              currentRun = 0;
            }
          }
        }
        return maxRun;
      }

      ConnectionData horizontalBackwardEdge() => ConnectionData(
            connection: Connection(
              id: 'be_h',
              sourcePortId: 'src',
              destinationPortId: 'dst',
              connectionType: ConnectionType.algorithmToAlgorithm,
              isBackwardEdge: true,
            ),
            sourcePosition: const Offset(20, yScan),
            destinationPosition: const Offset(180, yScan),
          );

      testWidgets(
          'backward edge renders as round dots (max horizontal run ≤ 4 px)',
          (tester) async {
        final conn = horizontalBackwardEdge();
        final maxRun = await maxOrangeRunOnScanlineFor(conn, tester);
        expect(
          maxRun,
          greaterThan(0),
          reason:
              'expected to find orange pixels on the rendered backward edge',
        );
        expect(
          maxRun,
          lessThanOrEqualTo(4),
          reason:
              'a dotted stroke should yield short orange runs (~2-3 px), '
              'not 8 px dashes',
        );
      });

      Future<Uint8List> renderToBytes(
        ConnectionData conn,
        WidgetTester tester,
      ) async {
        late ByteData byteData;
        await tester.runAsync(() async {
          final painter = ConnectionPainter(
            connections: [conn],
            theme: ThemeData.light(),
            showLabels: false,
            enableAntiOverlap: false,
          );
          final recorder = dart_ui.PictureRecorder();
          final canvas = Canvas(recorder);
          painter.paint(canvas, const Size(w * 1.0, h * 1.0));
          final picture = recorder.endRecording();
          final image = await picture.toImage(w, h);
          byteData =
              (await image.toByteData(format: dart_ui.ImageByteFormat.rawRgba))!;
        });
        return byteData.buffer.asUint8List();
      }

      bool hasOpaqueNonOrange(
        Uint8List bytes,
        Offset position, {
        int radius = 3,
      }) {
        final px = position.dx.toInt();
        final py = position.dy.toInt();
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final x = px + dx;
            final y = py + dy;
            if (x < 0 || x >= w || y < 0 || y >= h) continue;
            final i = (y * w + x) * 4;
            final r = bytes[i];
            final g = bytes[i + 1];
            final b = bytes[i + 2];
            final a = bytes[i + 3];
            // Pixel is opaque enough that we'd notice it as a drawn shape.
            if (a < 0x80) continue;
            if (isOrangeIsh(r, g, b, a)) continue;
            return true;
          }
        }
        return false;
      }

      testWidgets(
        'backward edge does not draw port-color endpoint circles',
        (tester) async {
          // Use a port id that maps to the audio accessible port color
          // (a blue, non-orange color); a 3px-radius endpoint circle in
          // that color would be the only thing visible at the source/dest
          // endpoint area when endpoints are drawn.
          final conn = ConnectionData(
            connection: Connection(
              id: 'be_audio',
              sourcePortId: 'algA_audio_out_1',
              destinationPortId: 'algB_audio_in_1',
              connectionType: ConnectionType.algorithmToAlgorithm,
              isBackwardEdge: true,
            ),
            sourcePosition: const Offset(20, yScan),
            destinationPosition: const Offset(180, yScan),
          );

          final bytes = await renderToBytes(conn, tester);
          expect(
            hasOpaqueNonOrange(bytes, const Offset(20, yScan)),
            isFalse,
            reason:
                'an opaque non-orange pixel near the source endpoint means '
                'the port-color endpoint circle was drawn — backward edges '
                'must not draw endpoint circles',
          );
          expect(
            hasOpaqueNonOrange(bytes, const Offset(180, yScan)),
            isFalse,
            reason:
                'an opaque non-orange pixel near the destination endpoint '
                'means the port-color endpoint circle was drawn',
          );
        },
      );
    });
  });
}
