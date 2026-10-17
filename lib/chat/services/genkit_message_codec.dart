import 'dart:convert';

import 'package:genkit/genkit.dart' as g;
import 'package:nt_helper/chat/models/llm_types.dart';

/// Provider compatibility boundary. Genkit owns tool-round ordering; the existing
/// transports retain their authentication, caching and endpoint contracts.
List<g.Message> toGenkitMessages(Iterable<LlmMessage> messages) => [
  for (final message in messages) toGenkitMessage(message),
];

g.Message toGenkitMessage(LlmMessage message) => g.Message(
  role: switch (message.role) {
    LlmRole.user => g.Role.user,
    LlmRole.assistant => g.Role.model,
    LlmRole.tool => g.Role.tool,
  },
  metadata: message.providerMetadata.isEmpty
      ? null
      : {'ntProvider': message.providerMetadata},
  content: [
    if (message.role != LlmRole.tool && message.content != null)
      g.TextPart(text: message.content!),
    for (final image in message.imageAttachments)
      g.MediaPart(
        media: g.Media(
          url: 'data:${image.mimeType};base64,${image.data}',
          contentType: image.mimeType,
        ),
      ),
    for (final file in message.fileAttachments)
      if (file.textContent == null)
        g.MediaPart(
          media: g.Media(
            url: 'data:${file.mimeType};base64,${file.data}',
            contentType: file.mimeType,
          ),
          metadata: {'name': file.name, 'sizeBytes': file.sizeBytes},
        ),
    for (final call in message.toolCalls ?? const <LlmToolCall>[])
      g.ToolRequestPart(
        toolRequest: g.ToolRequest(
          name: call.name,
          ref: call.id,
          input: call.arguments,
        ),
        metadata: {
          if (call.namespace != null) 'namespace': call.namespace,
          if (call.providerMetadata.isNotEmpty)
            'ntProvider': call.providerMetadata,
        },
      ),
    if (message.role == LlmRole.tool)
      g.ToolResponsePart(
        toolResponse: g.ToolResponse(
          name: message.toolName!,
          ref: message.toolCallId!,
          output: message.content ?? '',
          content: message.hasImage
              ? [
                  g.MediaPart(
                    media: g.Media(
                      url:
                          'data:${message.imageMimeType};base64,${message.imageBase64}',
                      contentType: message.imageMimeType,
                    ),
                  ).toJson(),
                ]
              : null,
        ),
      ),
  ],
);

List<LlmMessage> fromGenkitMessages(Iterable<g.Message> messages) => [
  for (final message in messages) ..._fromMessage(message),
];

Iterable<LlmMessage> _fromMessage(g.Message message) sync* {
  if (message.role == g.Role.system) return;
  if (message.role == g.Role.tool) {
    for (final part in message.content) {
      final response = part.toolResponsePart?.toolResponse;
      if (response == null) continue;
      String? imageData;
      String? imageType;
      for (final raw in response.content ?? const []) {
        final media = g.Part.fromJson(
          Map<String, dynamic>.from(raw as Map),
        ).mediaPart?.media;
        if (media == null || !media.url.startsWith('data:image/')) continue;
        final data = UriData.fromUri(Uri.parse(media.url));
        imageData = base64Encode(data.contentAsBytes());
        imageType = media.contentType ?? data.mimeType;
        break;
      }
      yield LlmMessage.toolResult(
        toolCallId: response.ref ?? response.name,
        toolName: response.name,
        content: response.output is String
            ? response.output as String
            : jsonEncode(response.output),
        imageBase64: imageData,
        imageMimeType: imageType,
      );
    }
    return;
  }
  final calls = <LlmToolCall>[];
  final images = <LlmImageAttachment>[];
  final files = <LlmFileAttachment>[];
  for (final part in message.content) {
    final request = part.toolRequestPart;
    if (request != null) {
      calls.add(
        LlmToolCall(
          id: request.toolRequest.ref ?? request.toolRequest.name,
          name: request.toolRequest.name,
          namespace: request.metadata?['namespace'] as String?,
          providerMetadata: Map<String, dynamic>.from(
            request.metadata?['ntProvider'] as Map? ?? const {},
          ),
          arguments: Map<String, dynamic>.from(
            request.toolRequest.input as Map? ?? const {},
          ),
        ),
      );
    }
    final media = part.mediaPart?.media;
    if (media == null || !media.url.startsWith('data:')) continue;
    final data = UriData.fromUri(Uri.parse(media.url));
    final mime = media.contentType ?? data.mimeType;
    final encoded = base64Encode(data.contentAsBytes());
    if (mime.startsWith('image/')) {
      images.add(LlmImageAttachment(data: encoded, mimeType: mime));
    } else {
      files.add(
        LlmFileAttachment(
          name: part.metadata?['name'] as String? ?? 'attachment',
          data: encoded,
          mimeType: mime,
          sizeBytes: data.contentAsBytes().length,
        ),
      );
    }
  }
  yield LlmMessage(
    role: message.role == g.Role.user ? LlmRole.user : LlmRole.assistant,
    content: message.text,
    providerMetadata: Map<String, dynamic>.from(
      message.metadata?['ntProvider'] as Map? ?? const {},
    ),
    toolCalls: calls.isEmpty ? null : calls,
    imageAttachments: images,
    fileAttachments: files,
  );
}
