import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/gallery_screen.dart';

void main() {
  group('GalleryViewMode', () {
    test('enum has correct values', () {
      expect(GalleryViewMode.values.length, 2);
      expect(GalleryViewMode.card.index, 0);
      expect(GalleryViewMode.list.index, 1);
    });

    test('card is default (index 0)', () {
      // Verify card view is first so SharedPreferences default works correctly
      expect(GalleryViewMode.values[0], GalleryViewMode.card);
    });
  });
}
