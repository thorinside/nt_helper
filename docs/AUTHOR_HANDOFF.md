# Handoff for Thorinside

Hi Thorinside,

I have opened this as a draft because it is an experimental fork change and still needs broader testing before it should be considered merge-ready.

The goal is to improve the chat/Codex workflow by letting users give the assistant richer local context.

## What This Adds

- Image attachments in chat
- Pasted image support
- General file attachments for model-supported inputs such as text, JSON, PDFs, and preset/algo-style files
- A local chat workspace directory setting
- Scoped local workspace/upload tools for chat use only

The file access is intentionally scoped. It does not expose arbitrary filesystem paths; it is limited to the selected workspace/uploads area.

## Test Builds

Desktop test builds from this fork are published here:

https://github.com/nymphnerds/nt_helper/releases/tag/chat-attachments-test-build-v1

Assets included:

- Windows x64
- Linux x64

No macOS build is included yet because that requires macOS and Xcode.

## Tested So Far

- Windows app builds and launches
- Image upload works in chat
- Uploaded image displays correctly
- The model receives and reasons about the image

## Still Needs Testing

- PDF attachments
- Text/JSON attachment handling
- Disting NT preset/algo file workflows
- Local workspace list/read/write tools
- Regression testing existing Disting tools

I am very happy for this to be reviewed as a possible direction rather than a finished merge request.
