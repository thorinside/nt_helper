# Chat File Handling Fixes

Concise changelog for `nymph-next-fix`.

- Added PDF text extraction for workspace `read_file`, so text-based manuals can be read by chat tools instead of returning base64 or size errors.
- Bounded extracted PDF text sent into chat context, so large manuals do not consume the whole model context on follow-up turns.
- Raised workspace file read/search limits for practical manuals and notes: PDFs up to 20 MB, general reads up to 5 MB, search file limits up to 20 MB.
- Raised chat text attachment limit from 100 KB to 2 MB and PDF attachment limit from 5 MB to 20 MB.
- Normalized pasted clipboard images so Windows screenshots copied as bitmap data are converted to supported image attachments.
- Added tests for large text reads and PDF text extraction.
