import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/platform/platform_interaction_service.dart';

void main() {
  group('PlatformInteractionService', () {
    late PlatformInteractionService service;

    setUp(() {
      service = PlatformInteractionService();
    });

    group('platform detection', () {
      testWidgets('detects mobile platform on iOS', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        final isMobile = service.isMobilePlatform();

        expect(isMobile, isTrue);

        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('detects mobile platform on Android', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final isMobile = service.isMobilePlatform();

        expect(isMobile, isTrue);

        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('detects desktop platform on macOS', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

        final isMobile = service.isMobilePlatform();

        expect(isMobile, isFalse);

        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('detects desktop platform on Windows', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        final isMobile = service.isMobilePlatform();

        expect(isMobile, isFalse);

        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('detects desktop platform on Linux', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;

        final isMobile = service.isMobilePlatform();

        expect(isMobile, isFalse);

        debugDefaultTargetPlatformOverride = null;
      });
    });

    group('interaction method determination', () {
      testWidgets('returns tap for mobile platforms', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        final interactionType = service.getPreferredInteractionType();

        expect(interactionType, equals(InteractionType.tap));

        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('returns hover for desktop platforms', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

        final interactionType = service.getPreferredInteractionType();

        expect(interactionType, equals(InteractionType.hover));

        debugDefaultTargetPlatformOverride = null;
      });
    });

    group('isDesktopPlatform', () {
      testWidgets('returns true for desktop platforms', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

        final isDesktop = service.isDesktopPlatform();

        expect(isDesktop, isTrue);

        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('returns false for mobile platforms', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final isDesktop = service.isDesktopPlatform();

        expect(isDesktop, isFalse);

        debugDefaultTargetPlatformOverride = null;
      });
    });

    group('usesCommandModifier', () {
      testWidgets('returns true on macOS', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

        final usesCommand = service.usesCommandModifier();

        expect(usesCommand, isTrue);

        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('returns false on Windows', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        final usesCommand = service.usesCommandModifier();

        expect(usesCommand, isFalse);

        debugDefaultTargetPlatformOverride = null;
      });
    });
  });
}
