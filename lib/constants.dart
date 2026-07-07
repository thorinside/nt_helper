class Constants {
  static var requiredDistingVersion = "1.14.0";

  // Responsive breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1200.0;

  // Mobile layout constants
  static const double mobileSearchBarPadding = 12.0;
  static const double mobileFilterSpacing = 8.0;
  static const double mobileNavRailWidth = 56.0;

  // Feature flags
  static const bool enablePresetExport = true; // Enable preset export feature

  // --- Algorithm clipboard ---
  // The algorithm clipboard is persisted as a single reserved system template
  // so it survives app restarts. It is excluded from the Template Manager UI
  // and from normal template share/export flows.
  static const String algorithmClipboardPresetName =
      '__algorithm_clipboard__';
  static const String algorithmClipboardCategory =
      '__algorithm_clipboard__';
}
