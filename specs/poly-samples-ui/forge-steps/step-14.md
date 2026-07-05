## STEP 14 of 14 — rewire navigation, delete the old screen

Spec section: "Step 14 — navigation rewire". This step edits
`lib/ui/synchronized_screen.dart`, deletes two files, and edits one test
file — nothing else.

Files: `lib/ui/synchronized_screen.dart`,
`test/ui/synchronized_screen_bottom_bar_test.dart`,
DELETE `lib/ui/poly_multisample/poly_multisample_builder_screen.dart`,
DELETE `test/poly_multisample/poly_multisample_builder_screen_test.dart`.

1. Apply spec items 1–7 to `synchronized_screen.dart` in order (enum,
   imports, build-method cleanup, method deletion, segmented button, new
   IconButton, switch arm).
2. Delete the two files (spec item 8).
3. Update the bottom-bar test per spec item 9.
4. Leftover check — ALL of these must print nothing:

   ```bash
   rg -n "EditMode.samples" lib test
   rg -n "PolyMultisampleBuilderScreen|PolyMultisampleBuilderView" lib test
   rg -n "_buildSamplesWorkspace|showSamplesWorkspace" lib
   ```

Verify per conventions; test files:
`flutter test test/ui/synchronized_screen_bottom_bar_test.dart test/poly_multisample`.

Commit message: `feat(poly)!: move Samples to a standalone screen and drop EditMode.samples`
