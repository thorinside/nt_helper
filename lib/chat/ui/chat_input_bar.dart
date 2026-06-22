import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/chat/models/chat_message.dart';
import 'package:nt_helper/services/key_binding_service.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as path;

class ChatInputBar extends StatefulWidget {
  final bool isProcessing;
  final void Function(
    String text,
    List<ChatImageAttachment> imageAttachments,
    List<ChatFileAttachment> fileAttachments,
  )
  onSend;
  final VoidCallback onCancel;
  final VoidCallback onSettings;
  final FocusNode? focusNode;

  const ChatInputBar({
    super.key,
    required this.isProcessing,
    required this.onSend,
    required this.onCancel,
    required this.onSettings,
    this.focusNode,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  FocusNode? _ownedFocusNode;
  bool _isExpanded = false;
  bool _hasTyped = false;
  double _availableWidth = 0;
  final List<ChatImageAttachment> _imageAttachments = [];
  final List<ChatFileAttachment> _fileAttachments = [];

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_checkExpansion);
    _controller.addListener(_checkHasTyped);
  }

  void _checkHasTyped() {
    if (!_hasTyped && _controller.text.isNotEmpty) {
      setState(() => _hasTyped = true);
      _controller.removeListener(_checkHasTyped);
    }
  }

  void _checkExpansion() {
    if (_availableWidth <= 0) return;

    // Once expanded, only shrink back when text is cleared (i.e. message sent).
    if (_isExpanded) {
      if (_controller.text.isEmpty) {
        setState(() => _isExpanded = false);
      }
      return;
    }

    final text = _controller.text;
    bool shouldExpand = false;

    if (text.contains('\n')) {
      shouldExpand = true;
    } else {
      const textFieldPadding = 32.0;
      final textWidth = _availableWidth - textFieldPadding;

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: double.infinity);

      shouldExpand = textPainter.width > textWidth;
      textPainter.dispose();
    }

    if (shouldExpand) {
      setState(() => _isExpanded = true);
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _imageAttachments.isEmpty && _fileAttachments.isEmpty) {
      return;
    }
    widget.onSend(
      text,
      List.unmodifiable(_imageAttachments),
      List.unmodifiable(_fileAttachments),
    );
    _controller.clear();
    setState(() {
      _imageAttachments.clear();
      _fileAttachments.clear();
    });
    _focusNode.requestFocus();
  }

  Future<void> _attachImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    for (final file in result.files) {
      final bytes = file.bytes ?? await _readFileBytes(file.path);
      if (bytes == null) continue;
      _addImage(bytes, name: file.name);
    }
  }

  Future<void> _attachFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    for (final file in result.files) {
      final bytes = file.bytes ?? await _readFileBytes(file.path);
      if (bytes == null) continue;
      final mimeType = _mimeTypeForName(file.name);
      if (mimeType.startsWith('image/')) {
        _addImage(bytes, name: file.name);
        continue;
      }
      _addFile(bytes, name: file.name, mimeType: mimeType);
    }
  }

  Future<void> _pasteImage() async {
    final bytes = await Pasteboard.image;
    if (bytes == null || bytes.isEmpty) return;
    _addImage(bytes, name: 'clipboard.png');
  }

  Future<List<int>?> _readFileBytes(String? filePath) async {
    if (filePath == null) return null;
    return File(filePath).readAsBytes();
  }

  void _addImage(List<int> bytes, {String? name}) {
    final fileName = name ?? 'image.png';
    final mimeType = _mimeTypeForName(fileName);
    setState(() {
      _imageAttachments.add(
        ChatImageAttachment(
          data: base64Encode(bytes),
          mimeType: mimeType,
          name: fileName,
        ),
      );
    });
  }

  void _addFile(
    List<int> bytes, {
    required String name,
    required String mimeType,
  }) {
    String? textContent;
    try {
      textContent = utf8.decode(bytes);
    } on FormatException {
      textContent = null;
    }
    setState(() {
      _fileAttachments.add(
        ChatFileAttachment(
          name: name,
          data: base64Encode(bytes),
          mimeType: mimeType,
          sizeBytes: bytes.length,
          textContent: textContent,
        ),
      );
    });
  }

  void _removeImage(int index) {
    setState(() => _imageAttachments.removeAt(index));
  }

  void _removeFile(int index) {
    setState(() => _fileAttachments.removeAt(index));
  }

  String _mimeTypeForName(String fileName) {
    switch (path.extension(fileName).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.json':
      case '.ntpreset':
      case '.preset':
        return 'application/json';
      case '.txt':
      case '.md':
      case '.markdown':
      case '.csv':
      case '.yaml':
      case '.yml':
      case '.toml':
      case '.xml':
      case '.lua':
      case '.dart':
      case '.js':
      case '.ts':
      case '.py':
      case '.sh':
        return 'text/plain';
      case '.syx':
      case '.o':
      case '.wasm':
      case '.bin':
      case '.dat':
        return 'application/octet-stream';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkExpansion);
    _controller.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _availableWidth =
                constraints.maxWidth -
                4 // SizedBox before send button
                -
                48; // send/cancel IconButton width
            _availableWidth -= 120; // attach file/image and paste IconButtons
            if (!_isExpanded) {
              _availableWidth -= 40; // settings IconButton width
            }
            return Row(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? const SizedBox.shrink()
                      : Semantics(
                          label: 'Chat settings',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.settings_outlined, size: 20),
                            tooltip: 'Chat settings',
                            onPressed: widget.onSettings,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                ),
                Semantics(
                  label: 'Attach file',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.attach_file, size: 20),
                    tooltip: 'Attach file',
                    onPressed: widget.isProcessing ? null : _attachFiles,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Semantics(
                  label: 'Attach image',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.image_outlined, size: 20),
                    tooltip: 'Attach image',
                    onPressed: widget.isProcessing ? null : _attachImages,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Semantics(
                  label: 'Paste image',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.content_paste, size: 20),
                    tooltip: 'Paste image',
                    onPressed: widget.isProcessing ? null : _pasteImage,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_imageAttachments.isNotEmpty)
                        _ImageAttachmentStrip(
                          attachments: _imageAttachments,
                          onRemove: _removeImage,
                        ),
                      if (_fileAttachments.isNotEmpty)
                        _FileAttachmentStrip(
                          attachments: _fileAttachments,
                          onRemove: _removeFile,
                        ),
                      Shortcuts(
                        shortcuts: {
                          LogicalKeySet(LogicalKeyboardKey.enter):
                              const _SendIntent(),
                          for (final key
                              in _digitKeys) ...<SingleActivator, Intent>{
                            SingleActivator(key):
                                const DoNothingAndStopPropagationTextIntent(),
                            SingleActivator(key, shift: true):
                                const DoNothingAndStopPropagationTextIntent(),
                          },
                          for (final activator
                              in KeyBindingService().globalShortcuts.keys)
                            activator:
                                const DoNothingAndStopPropagationTextIntent(),
                        },
                        child: Actions(
                          actions: {
                            _SendIntent: CallbackAction<_SendIntent>(
                              onInvoke: (_) {
                                if (!widget.isProcessing) _handleSend();
                                return null;
                              },
                            ),
                          },
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: _hasTyped
                                  ? null
                                  : 'Ask about your preset...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            enabled: !widget.isProcessing,
                            textInputAction: TextInputAction.send,
                            onSubmitted: widget.isProcessing
                                ? null
                                : (_) => _handleSend(),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (widget.isProcessing)
                  Semantics(
                    label: 'Cancel',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        Icons.stop_circle_outlined,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Cancel',
                      onPressed: widget.onCancel,
                    ),
                  )
                else
                  Semantics(
                    label: 'Send message',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: 'Send',
                      onPressed: _handleSend,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SendIntent extends Intent {
  const _SendIntent();
}

class _ImageAttachmentStrip extends StatelessWidget {
  final List<ChatImageAttachment> attachments;
  final ValueChanged<int> onRemove;

  const _ImageAttachmentStrip({
    required this.attachments,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 58,
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  base64Decode(attachment.data),
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Material(
                  color: theme.colorScheme.surface,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onRemove(index),
                    child: Icon(
                      Icons.cancel,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FileAttachmentStrip extends StatelessWidget {
  final List<ChatFileAttachment> attachments;
  final ValueChanged<int> onRemove;

  const _FileAttachmentStrip({
    required this.attachments,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 36,
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return InputChip(
            avatar: Icon(
              attachment.mimeType == 'application/pdf'
                  ? Icons.picture_as_pdf
                  : Icons.description_outlined,
              size: 16,
            ),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                attachment.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ),
            onDeleted: () => onRemove(index),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

const _digitKeys = [
  LogicalKeyboardKey.digit0,
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];
